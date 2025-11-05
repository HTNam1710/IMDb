# scripts/enrich_tmdb.py
import os, time, csv, requests, pandas as pd
from pathlib import Path
from dotenv import load_dotenv
load_dotenv()

ROOT = Path(__file__).resolve().parents[1]
TMDB_KEY = os.getenv("TMDB_API_KEY")
if not TMDB_KEY:
    raise RuntimeError("Missing TMDB_API_KEY in environment/.env")

# ---- paths
seed_path = ROOT / "data" / "tmdb" / "seed_tconst.csv"   # <-- đọc seed top 10k
out_path  = ROOT / "data" / "tmdb" / "tmdb_movies.csv"
err_path  = ROOT / "data" / "tmdb" / "tmdb_errors.csv"
out_path.parent.mkdir(parents=True, exist_ok=True)

# ---- load seed (unique, giữ thứ tự)
if not seed_path.exists():
    raise FileNotFoundError(f"Seed file not found: {seed_path}")

seed_df = pd.read_csv(seed_path)  # cột tconst
seed_list = [str(x) for x in seed_df["tconst"].tolist()]

# ---- resume: skip những cái đã làm
done = set()
if out_path.exists():
    try:
        done_df = pd.read_csv(out_path, usecols=["tconst"])
        done = set(done_df["tconst"].astype(str).tolist())
    except Exception:
        pass

# ---- http session
session = requests.Session()
BASE = "https://api.themoviedb.org/3"

def tmdb_get(path, params=None):
    if params is None: params = {}
    p = {"api_key": TMDB_KEY, **params}
    for attempt in range(3):
        r = session.get(f"{BASE}{path}", params=p, timeout=20)
        if r.status_code == 429:
            wait = int(r.headers.get("Retry-After", "2"))
            print(f"[429] Rate-limited. Sleep {wait}s…")
            time.sleep(wait); continue
        try:
            r.raise_for_status()
            return r.json()
        except requests.HTTPError as e:
            # 404/400 -> trả về None để ghi vào file lỗi
            if r.status_code in (400, 404):
                return None
            # còn lại: chờ 1s rồi thử lại
            time.sleep(1)
    return None

def tmdb_find_by_imdb(ttid):
    j = tmdb_get(f"/find/{ttid}", params={"external_source":"imdb_id"})
    if not j: return None
    lst = j.get("movie_results", []) or j.get("tv_results", [])
    return lst[0]["id"] if lst else None

def tmdb_movie_full(tmdb_id):
    return tmdb_get(f"/movie/{tmdb_id}", params={"append_to_response":"images,videos,keywords"})

# ---- open files (append-friendly, header if not exists)
write_header = not out_path.exists()
f_out = open(out_path, "a", encoding="utf-8", newline="")
w_out = csv.writer(f_out)
if write_header:
    w_out.writerow([
        "tconst","tmdb_id","poster_path","budget_tmdb","revenue_tmdb",
        "popularity","countries","keywords","genres_tmdb"
    ])

err_header = not err_path.exists()
f_err = open(err_path, "a", encoding="utf-8", newline="")
w_err = csv.writer(f_err)
if err_header:
    w_err.writerow(["tconst","stage","message"])

processed = 0
total = len(seed_list)
start = time.time()

for ttid in seed_list:
    if ttid in done:
        continue
    try:
        tmdb_id = tmdb_find_by_imdb(ttid)
        if not tmdb_id:
            w_out.writerow([ttid, None, None, None, None, None, None, None, None])
            f_out.flush()
            processed += 1
            continue

        info = tmdb_movie_full(tmdb_id)
        if not info:
            w_err.writerow([ttid, "movie_full", "None/HTTP error"])
            f_err.flush()
            processed += 1
            continue

        poster = info.get("poster_path")
        revenue = info.get("revenue")
        budget  = info.get("budget")
        popularity = info.get("popularity")
        countries = ";".join([c.get("iso_3166_1","") for c in info.get("production_countries", [])]) or None
        kws = ";".join([k.get("name","") for k in (info.get("keywords", {}) or {}).get("keywords", [])]) or None
        genres = ";".join([g.get("name","") for g in info.get("genres", [])]) or None

        w_out.writerow([ttid, tmdb_id, poster, budget, revenue, popularity, countries, kws, genres])
        f_out.flush()
        processed += 1

        if processed % 200 == 0:
            elapsed = time.time() - start
            print(f"{processed}/{total} processed in {elapsed:.1f}s")

        time.sleep(0.15)  # giữ quota ~6-7 req/s

    except Exception as e:
        w_err.writerow([ttid, "exception", str(e)])
        f_err.flush()
        time.sleep(1)

f_out.close()
f_err.close()
print(f"✅ Done. Wrote {processed} rows → {out_path}")