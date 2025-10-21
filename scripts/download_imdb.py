import gzip, shutil, urllib.request, datetime
from pathlib import Path

FILES = [
  "title.basics.tsv.gz",
  "title.ratings.tsv.gz",
  "title.crew.tsv.gz",
  "title.principals.tsv.gz",
  "name.basics.tsv.gz",
]
BASE_URL = "https://datasets.imdbws.com/"

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
UNPACK = ROOT / "data" / "unpacked"
for p in (RAW, UNPACK):
    p.mkdir(parents=True, exist_ok=True)

stamp = datetime.datetime.utcnow().strftime("%Y%m%d")

for fname in FILES:
    url = BASE_URL + fname
    raw_path = RAW / f"{stamp}_{fname}"
    print(f"↓ {url}")
    urllib.request.urlretrieve(url, raw_path)

    out_path = UNPACK / fname.replace(".gz", "")
    print(f"↳ unpack to {out_path}")
    with gzip.open(raw_path, 'rb') as f_in, open(out_path, 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)

print("✓ downloaded & unpacked")