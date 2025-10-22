BEGIN;

DROP TABLE IF EXISTS imdb.title_basics_new CASCADE;
DROP TABLE IF EXISTS imdb.title_ratings_new;
DROP TABLE IF EXISTS imdb.title_crew_new;
DROP TABLE IF EXISTS imdb.title_principals_new;
DROP TABLE IF EXISTS imdb.name_basics_new;

-- 1) basics
CREATE TABLE imdb.title_basics_new AS
SELECT
  tconst,
  titleType,
  primaryTitle,
  originalTitle,

  -- isAdult: chỉ nhận '0' hoặc '1' → boolean; còn lại NULL
  CASE WHEN isAdult ~ '^[01]$' THEN (isAdult = '1') ELSE NULL END AS isAdult,

  -- năm / runtime: chỉ cast nếu là số
  CASE WHEN startYear      ~ '^-?[0-9]+$' THEN startYear::INT      ELSE NULL END AS startYear,
  CASE WHEN endYear        ~ '^-?[0-9]+$' THEN endYear::INT        ELSE NULL END AS endYear,
  CASE WHEN runtimeMinutes ~ '^-?[0-9]+$' THEN runtimeMinutes::INT ELSE NULL END AS runtimeMinutes,

  -- genres: rỗng, NULL, '\N' → NULL; còn lại tách mảng
  CASE
    WHEN genres IS NULL OR genres IN ('', '\N') THEN NULL
    ELSE string_to_array(genres, ',')
  END AS genres
FROM imdb_staging.title_basics;

ALTER TABLE imdb.title_basics_new
  ADD PRIMARY KEY (tconst);

-- 2) ratings
CREATE TABLE imdb.title_ratings_new AS
SELECT
  tconst,
  CASE WHEN averageRating ~ '^-?[0-9]+(\.[0-9]+)?$' THEN averageRating::NUMERIC(3,1) ELSE NULL END AS averageRating,
  CASE WHEN numVotes      ~ '^-?[0-9]+$'            THEN numVotes::INT               ELSE NULL END AS numVotes
FROM imdb_staging.title_ratings;

ALTER TABLE imdb.title_ratings_new
  ADD PRIMARY KEY (tconst);

ALTER TABLE imdb.title_ratings_new
  ADD CONSTRAINT fk_tr_tb FOREIGN KEY (tconst)
  REFERENCES imdb.title_basics_new(tconst) ON DELETE CASCADE;

-- 3) crew
CREATE TABLE imdb.title_crew_new AS
SELECT
  tconst,
  CASE WHEN directors IS NULL OR directors IN ('', '\N') THEN NULL ELSE string_to_array(directors, ',') END AS directors,
  CASE WHEN writers   IS NULL OR writers   IN ('', '\N') THEN NULL ELSE string_to_array(writers,   ',') END AS writers
FROM imdb_staging.title_crew;

ALTER TABLE imdb.title_crew_new
  ADD PRIMARY KEY (tconst);

ALTER TABLE imdb.title_crew_new
  ADD CONSTRAINT fk_tc_tb FOREIGN KEY (tconst)
  REFERENCES imdb.title_basics_new(tconst) ON DELETE CASCADE;

-- 4) principals
CREATE TABLE imdb.title_principals_new AS
SELECT
  tconst,
  CASE WHEN ordering  ~ '^-?[0-9]+$' THEN ordering::INT ELSE NULL END AS ordering,
  nconst,
  NULLIF(category,  '') AS category,
  NULLIF(job,       '') AS job,
  NULLIF(characters,'') AS characters
FROM imdb_staging.title_principals;

ALTER TABLE imdb.title_principals_new
  ADD PRIMARY KEY (tconst, ordering);

-- 5) names
CREATE TABLE imdb.name_basics_new AS
SELECT
  nconst,
  primaryName,
  CASE WHEN birthYear ~ '^-?[0-9]+$' THEN birthYear::INT ELSE NULL END AS birthYear,
  CASE WHEN deathYear ~ '^-?[0-9]+$' THEN deathYear::INT ELSE NULL END AS deathYear,
  CASE WHEN primaryProfession IS NULL OR primaryProfession IN ('', '\N') THEN NULL ELSE string_to_array(primaryProfession, ',') END AS primaryProfession,
  CASE WHEN knownForTitles    IS NULL OR knownForTitles    IN ('', '\N') THEN NULL ELSE string_to_array(knownForTitles,    ',') END AS knownForTitles
FROM imdb_staging.name_basics;

ALTER TABLE imdb.name_basics_new
  ADD PRIMARY KEY (nconst);

-- Index
CREATE INDEX idx_new_tb_type   ON imdb.title_basics_new(titleType);
CREATE INDEX idx_new_tr_votes  ON imdb.title_ratings_new(numVotes DESC);
CREATE INDEX idx_new_tr_rate   ON imdb.title_ratings_new(averageRating DESC);
CREATE INDEX idx_new_tp_nconst ON imdb.title_principals_new(nconst);

COMMIT;