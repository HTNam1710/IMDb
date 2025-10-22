BEGIN;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['title_principals','title_crew','title_ratings','title_basics','name_basics']
  LOOP
    IF to_regclass('imdb.'||t) IS NOT NULL THEN
      EXECUTE format('ALTER TABLE imdb.%I RENAME TO %I;', t, t||'_old');
    END IF;
    IF to_regclass('imdb.'||t||'_new') IS NOT NULL THEN
      EXECUTE format('ALTER TABLE imdb.%I RENAME TO %I;', t||'_new', t);
    END IF;
  END LOOP;
END $$;

DROP TABLE IF EXISTS imdb.title_principals_old;
DROP TABLE IF EXISTS imdb.title_crew_old;
DROP TABLE IF EXISTS imdb.title_ratings_old;
DROP TABLE IF EXISTS imdb.title_basics_old;
DROP TABLE IF EXISTS imdb.name_basics_old;

COMMIT;