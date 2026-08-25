-- ============================================================
-- Phase 1: Data Cleaning — EXPLORATION LOG
-- Spotify Track Dataset — SQL Portfolio Project
-- ============================================================
-- This file preserves the trial-and-error process behind the
-- final cleaning script (phase1_cleaning_final.sql). Not every
-- query here made the final cut — some were dead ends, checks,
-- or superseded by a better version further down.
-- ============================================================


-- table setup

CREATE TABLE spotify_tracks (
    track_id VARCHAR(50),
    track_name VARCHAR(255),
    track_number INT,
    track_popularity INT,
    explicit BOOLEAN,
    artist_name VARCHAR(255),
    artist_popularity INT,
    artist_followers BIGINT,
    artist_genres TEXT,
    album_id VARCHAR(50),
    album_name VARCHAR(255),
    album_release_date DATE,
    album_total_tracks INT,
    album_type VARCHAR(50),
    track_duration_min NUMERIC(6,2)
);



-- spot-check actual values
SELECT * FROM spotify_tracks LIMIT 5;

-- confirm known null counts survived import
SELECT COUNT(*) FROM spotify_tracks WHERE artist_genres IS NULL;   -- expect ~3,361
SELECT COUNT(*) FROM spotify_tracks WHERE artist_name IS NULL;     -- expect 3

-- confirm album_release_date actually became a real DATE type
SELECT album_release_date, EXTRACT(YEAR FROM album_release_date) AS yr
FROM spotify_tracks LIMIT 5;

-- confirm duplicate finding survived the import
SELECT track_name, artist_name, COUNT(*)
FROM spotify_tracks
GROUP BY track_name, artist_name
HAVING COUNT(*) > 1;

-- scanning duplicates

-- early exploratory query — checking compilation-type albums
-- (syntax error left as-is: semicolon placed before WHERE)
SELECT *
FROM spotify_tracks;
WHERE album_type = 'compilation';

-- viewing all duplicate-prone tracks together, sorted for review
SELECT track_name, artist_name, album_name, album_release_date, track_popularity
FROM spotify_tracks
ORDER BY track_name, artist_name, album_release_date;

-- checking how common the Jan-1 placeholder date pattern is
SELECT *
FROM spotify_tracks
WHERE album_release_date::text LIKE '%-01-01';
-- result: 667 rows — confirmed as a systematic placeholder, not coincidence


-- testing dedup ranking logic on known sample groups


-- v1: popularity + release date tiebreaker only
-- (this version picked the Spanish Version over the English
--  Expanded Edition for "Can't Remember to Forget You" — flagged
--  as a real limitation, informed later versions of the rule)
SELECT track_name, artist_name, album_name, album_release_date, track_popularity,
    ROW_NUMBER() OVER (
        PARTITION BY track_name, artist_name 
        ORDER BY track_popularity DESC, album_release_date DESC
    ) AS rn
FROM spotify_tracks
WHERE track_name IN ('Wildest Dreams', 'Clean', 'Can''t Remember to Forget You (feat. Rihanna)')
ORDER BY track_name, rn;

-- v2: pure popularity only, tested against all duplicate groups

SELECT track_name, artist_name, album_name, album_type, track_popularity,
    ROW_NUMBER() OVER (
        PARTITION BY track_name, artist_name 
        ORDER BY track_popularity DESC
    ) AS rn
FROM spotify_tracks
WHERE (track_name, artist_name) IN (
    SELECT track_name, artist_name
    FROM spotify_tracks
    GROUP BY track_name, artist_name
    HAVING COUNT(*) > 1
)
ORDER BY artist_name, track_name, rn;

-- v3 (FINAL RULE): popularity first, keyword/compilation tiebreaker only when popularity ties 
-- building the cleaned table

CREATE TABLE spotify_tracks_clean AS
SELECT
    track_id,
    track_name,
    track_number,
    track_popularity,
    explicit,
    artist_name,
    artist_popularity,
    artist_followers,
    artist_genres,
    album_id,
    album_name,
    album_release_date,
    album_total_tracks,
    album_type,
    track_duration_min
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY track_name, artist_name
            ORDER BY
                track_popularity DESC,
                CASE 
                    WHEN album_type = 'compilation' THEN 1 
                    ELSE 0 
                END ASC,
                CASE 
                    WHEN album_name ILIKE '%live%'
                      OR album_name ILIKE '%version%'
                      OR album_name ILIKE '%deluxe%'
                      OR album_name ILIKE '%edition%'
                      OR album_name ILIKE '%remix%'
                      OR album_name ILIKE '%extended%'
                      OR album_name ILIKE '%anthology%'
                    THEN 1 
                    ELSE 0 
                END ASC
        ) AS rn
    FROM spotify_tracks
) ranked
WHERE rn = 1;

-- spot-check the cleaned table, sorted by genre
SELECT * FROM spotify_tracks_clean
ORDER BY artist_genres;



-- fixing missing artist_name manually

UPDATE spotify_tracks_clean
SET artist_name = 'Labrinth'
WHERE track_name = 'Never Felt So Alone' AND artist_name IS NULL;

UPDATE spotify_tracks_clean
SET artist_name = 'Lana Del Rey'
WHERE track_name = 'Radio' AND artist_name IS NULL;

UPDATE spotify_tracks_clean
SET artist_name = 'Grimes'
WHERE track_name = 'Urban Twilight' AND artist_name IS NULL;


-- Standardizing missing genre values

UPDATE spotify_tracks_clean
SET artist_genres = 'Unknown'
WHERE artist_genres IS NULL OR TRIM(artist_genres) = 'N/A';

--  Final verification

SELECT COUNT(*) FROM spotify_tracks_clean WHERE artist_name IS NULL;      -- expect 0
SELECT COUNT(*) FROM spotify_tracks_clean WHERE artist_genres = 'Unknown';
SELECT * FROM spotify_tracks_clean