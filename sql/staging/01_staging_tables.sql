CREATE TABLE IF NOT EXISTS imdb_staging.title_basics (
  tconst TEXT, titleType TEXT, primaryTitle TEXT, originalTitle TEXT,
  isAdult TEXT, startYear TEXT, endYear TEXT, runtimeMinutes TEXT, genres TEXT
);

CREATE TABLE IF NOT EXISTS imdb_staging.title_ratings (
  tconst TEXT, averageRating TEXT, numVotes TEXT
);

CREATE TABLE IF NOT EXISTS imdb_staging.title_crew (
  tconst TEXT, directors TEXT, writers TEXT
);

CREATE TABLE IF NOT EXISTS imdb_staging.title_principals (
  tconst TEXT, ordering TEXT, nconst TEXT, category TEXT, job TEXT, characters TEXT
);

CREATE TABLE IF NOT EXISTS imdb_staging.name_basics (
  nconst TEXT, primaryName TEXT, birthYear TEXT, deathYear TEXT,
  primaryProfession TEXT, knownForTitles TEXT
);