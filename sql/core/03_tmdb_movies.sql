CREATE SCHEMA IF NOT EXISTS imdb_ext;

CREATE TABLE IF NOT EXISTS imdb_ext.tmdb_movies (
    imdb_id text PRIMARY KEY,
    tmdb_id text,
    poster_path text,
    budget_tmdb bigint,
    revenue_tmdb bigint,
    popularity numeric,
    countries text,
    keywords text,
    genres_tmdb text
);