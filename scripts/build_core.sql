BEGIN;

DROP TABLE IF EXISTS imdb.title_basics_new CASCADE;
DROP TABLE IF EXISTS imdb.title_ratings_new;
DROP TABLE IF EXISTS imdb.title_crew_new;

-- 1) basics
CREATE TABLE imdb.title_basics_new AS
SELECT
  tconst,
  titleType,
  primaryTitle,
  originalTitle,
  CASE WHEN isAdult ~ '^[01]$' THEN (isAdult = '1') ELSE NULL END AS isAdult,
  CASE WHEN startYear      ~ '^-?[0-9]+$' THEN startYear::INT      ELSE NULL END AS startYear,
  CASE WHEN endYear        ~ '^-?[0-9]+$' THEN endYear::INT        ELSE NULL END AS endYear,
  CASE WHEN runtimeMinutes ~ '^-?[0-9]+$' THEN runtimeMinutes::INT ELSE NULL END AS runtimeMinutes,
  CASE WHEN genres IS NULL OR genres IN ('', '\N') THEN NULL ELSE string_to_array(genres, ',') END AS genres
FROM imdb_staging.title_basics;

ALTER TABLE imdb.title_basics_new ADD PRIMARY KEY (tconst);

-- 2) ratings
CREATE TABLE imdb.title_ratings_new AS
SELECT
  tconst,
  CASE WHEN averageRating ~ '^-?[0-9]+(\.[0-9]+)?$' THEN averageRating::NUMERIC(3,1) ELSE NULL END AS averageRating,
  CASE WHEN numVotes      ~ '^-?[0-9]+$'            THEN numVotes::INT               ELSE NULL END AS numVotes
FROM imdb_staging.title_ratings;

ALTER TABLE imdb.title_ratings_new ADD PRIMARY KEY (tconst);
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

ALTER TABLE imdb.title_crew_new ADD PRIMARY KEY (tconst);
ALTER TABLE imdb.title_crew_new
  ADD CONSTRAINT fk_tc_tb FOREIGN KEY (tconst)
  REFERENCES imdb.title_basics_new(tconst) ON DELETE CASCADE;

-- Index
CREATE INDEX idx_new_tb_type ON imdb.title_basics_new(titleType);
CREATE INDEX idx_new_tr_votes ON imdb.title_ratings_new(numVotes DESC);
CREATE INDEX idx_new_tr_rate  ON imdb.title_ratings_new(averageRating DESC);

COMMIT;