import os, csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC  = ROOT / "data" / "unpacked"
DST  = ROOT / "data" / "unpacked_slim"
DST.mkdir(parents=True, exist_ok=True)

MIN_YEAR, MAX_YEAR = 2000, 2025
MIN_VOTES = int(os.getenv("IMDB_MIN_VOTES", "1000"))

def iter_tsv(path):
    with open(path, "r", encoding="utf-8") as f:
        next(f)  # skip header
        for line in f:
            yield line.rstrip("\n").split("\t")

def write_tsv(path, rows):
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerows(rows)

def filter_basics():
    src, dst = SRC/"title.basics.tsv", DST/"title.basics.tsv"
    kept = []
    for tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres in iter_tsv(src):
        if not titleType or titleType in ("\\N", ""):  # chỉ loại type rỗng
            continue
        if isAdult != "0":
            continue
        if not startYear.isdigit():
            continue
        y = int(startYear)
        if y < MIN_YEAR or y > MAX_YEAR:
            continue
        kept.append([tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres])
    write_tsv(dst, kept)
    return {r[0] for r in kept}

def filter_ratings(tconst_set):
    src, dst = SRC/"title.ratings.tsv", DST/"title.ratings.tsv"
    kept = []
    for tconst, avg, votes in iter_tsv(src):
        if tconst not in tconst_set:
            continue
        if not votes.isdigit() or int(votes) < MIN_VOTES:
            continue
        kept.append([tconst, avg, votes])
    write_tsv(dst, kept)
    return {r[0] for r in kept}

def filter_crew(tconst_set):
    src, dst = SRC/"title.crew.tsv", DST/"title.crew.tsv"
    kept = [[tconst, dir_, wri_] for tconst, dir_, wri_ in iter_tsv(src) if tconst in tconst_set]
    write_tsv(dst, kept)

if __name__ == "__main__":
    basics_t = filter_basics()
    ratings_t = filter_ratings(basics_t)
    filter_crew(ratings_t)
    print(f"✅ IMDb slim done: {len(ratings_t):,} titles → data/unpacked_slim/")