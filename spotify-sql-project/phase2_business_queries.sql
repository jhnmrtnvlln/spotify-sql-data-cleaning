-- ============================================ 
-- Phase 2: Business Question Queries -- Spotify Track Dataset — SQL Portfolio Project 
-- ============================================

-- Top artists by average popularity

SELECT 
    artist_name,
    ROUND(AVG(track_popularity), 1) AS avg_popularity,
    COUNT(*) AS track_count
FROM spotify_tracks_clean
GROUP BY artist_name
HAVING COUNT(*) >= 3
ORDER BY avg_popularity DESC
LIMIT 10;

-- Average popularity by album type

SELECT 
    album_type,
    ROUND(AVG(track_popularity), 1) AS avg_popularity,
    COUNT(*) AS track_count
FROM spotify_tracks_clean
GROUP BY album_type
ORDER BY avg_popularity DESC;

--  Explicit vs non-explicit track popularity

SELECT 
    explicit,
    ROUND(AVG(track_popularity), 1) AS avg_popularity,
    COUNT(*) AS track_count
FROM spotify_tracks_clean
GROUP BY explicit
ORDER BY avg_popularity DESC;

-- Average track duration by release year

SELECT 
    EXTRACT(YEAR FROM album_release_date) AS release_year,
    ROUND(AVG(track_duration_min), 2) AS avg_duration_min,
    COUNT(*) AS track_count
FROM spotify_tracks_clean
GROUP BY EXTRACT(YEAR FROM album_release_date)
ORDER BY release_year;

-- Rank each artist's tracks by popularity (their "greatest hits" list)

SELECT artist_name, track_name, track_popularity, popularity_rank
FROM (
    SELECT 
        artist_name,
        track_name,
        track_popularity,
        RANK() OVER (
            PARTITION BY artist_name 
            ORDER BY track_popularity DESC
        ) AS popularity_rank
    FROM spotify_tracks_clean
) ranked
WHERE popularity_rank <= 3
ORDER BY artist_name, popularity_rank;

--  Artists whose popularity outperforms (or underperforms) their follower count

WITH artist_summary AS (
    SELECT 
        artist_name,
        MAX(artist_followers) AS followers,
        ROUND(AVG(track_popularity), 1) AS avg_popularity
    FROM spotify_tracks_clean
    GROUP BY artist_name
    HAVING MAX(artist_followers) >= 10000
)
SELECT 
    artist_name,
    followers,
    avg_popularity,
    ROUND(avg_popularity / NULLIF(followers, 0) * 1000000, 4) AS popularity_per_million_followers
FROM artist_summary
ORDER BY popularity_per_million_followers DESC
LIMIT 15;

