import os
import psycopg2
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
UNPACK = ROOT / "data" / "unpacked"

conn = psycopg2.connect(
    host="localhost",
    port=int(os.getenv("PG_PORT_ON_HOST", "5433")),
    dbname=os.getenv("DB_NAME", "imdb"),
    user=os.getenv("DB_USER", "imdb_user"),
    password=os.getenv("DB_PASSWORD", "imdb_pass"),
)
conn.autocommit = True

files_map = {
    "title.basics.tsv": ("imdb_staging.title_basics",
                         "(tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres)"),
    "title.ratings.tsv": ("imdb_staging.title_ratings",
                          "(tconst, averageRating, numVotes)"),
    "title.crew.tsv": ("imdb_staging.title_crew",
                       "(tconst, directors, writers)"),
    "title.principals.tsv": ("imdb_staging.title_principals",
                             "(tconst, ordering, nconst, category, job, characters)"),
    "name.basics.tsv": ("imdb_staging.name_basics",
                        "(nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles)"),
}

def write_noheader(src_path, dst_path):
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    with open(src_path, "r", encoding="utf-8", newline="") as fin, \
         open(dst_path, "w", encoding="utf-8", newline="") as fout:
        next(fin)  # bỏ dòng header
        for line in fin:
            fout.write(line)

with conn.cursor() as cur:
    cur.execute("""
      TRUNCATE imdb_staging.title_basics,
               imdb_staging.title_ratings,
               imdb_staging.title_crew,
               imdb_staging.title_principals,
               imdb_staging.name_basics;
    """)

    for fname, (table, cols) in files_map.items():
        local_src = UNPACK / fname
        if not local_src.exists():
            raise FileNotFoundError(f"Missing file: {local_src}. Hãy chạy scripts/download_imdb.py trước.")

        # Tạo file KHÔNG header để server-side COPY (TEXT mode)
        local_noheader = UNPACK / (fname + ".noheader")
        write_noheader(local_src, local_noheader)

        # Đường dẫn TRONG container (../data đã mount thành /data)
        container_path = PurePosixPath("/data") / "unpacked" / (fname + ".noheader")

        print(f"COPY {container_path} -> {table}")
        cur.execute(f"""
            COPY {table} {cols}
            FROM %s
            WITH (
              FORMAT text,
              DELIMITER E'\t',
              NULL '\\\\N'
            );
        """, (str(container_path),))

print("✓ staging loaded")