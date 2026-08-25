# Spotify SQL Data Cleaning & Analysis Project

A standalone SQL portfolio project: cleaning and analyzing an 8,500+ row Spotify track dataset using PostgreSQL. Built as a dedicated proof point for SQL specifically — kept separate from the [Billboard Hot 100 Chart Tracker](https://github.com/jhnmrtnvlln/billboard-hot100-tracker), which is Excel/Power BI-driven.

---

## Overview

Real-world exported datasets are rarely clean, and this one was no exception. Rather than working with tidy sample data, this project starts from a raw Spotify export with genuine data-quality problems — duplicate tracks, missing values, and inconsistent metadata — and works through a documented, defensible cleaning process before answering business questions with the result.

The project is split into two phases:

1. **Phase 1 — Data Cleaning** (`phase1_cleaning.sql`): deduplicating tracks, fixing missing values, and standardizing inconsistent fields.
2. **Phase 2 — Business Questions** (`phase2_business_queries.sql`): six queries answering real questions about the cleaned dataset, using aggregates, window functions, and a CTE.

---

## Dataset

Source: [Spotify Global Music Dataset (2009–2025)](https://www.kaggle.com/datasets/wardabilal/spotify-global-music-dataset-20092025/data) via Kaggle, by Warda Bilal.

- **8,582 rows** on import
- 15 columns: track metadata (name, popularity, duration, explicit flag), artist metadata (name, popularity, followers, genres), and album metadata (name, release date, type, total tracks)

---

## Phase 1: Data Cleaning

### Problems found

| Issue | Scope |
|---|---|
| Duplicate track+artist combinations (re-releases, deluxe editions, live versions, compilations, translated versions) | 578 groups with 2+ rows |
| Missing `artist_genres` | ~3,361 rows |
| Missing `artist_name` | 3 rows |
| Placeholder `01-01` release dates (not real release dates — a default value from the source data) | 667 rows (~7.8%) |
| Embedded, improperly escaped quotes in `album_name` (e.g. `12" Singles`) | Caused CSV import to fail until re-escaped |

### Deduplication rule

Each track+artist group is reduced to a single row using `ROW_NUMBER()`, ranked in this order:

1. **Highest `track_popularity`** — the primary signal.
2. **Non-compilation albums win ties** — a compilation entry loses to a standalone release.
3. **Plain releases win ties over reissue-type packaging** — album names containing keywords like *live, version, deluxe, edition, remix, extended, anthology* are demoted.

Tracks featuring a different credited artist (e.g. `Song (feat. X)`) are treated as distinct tracks and intentionally excluded from deduplication, since they represent a different recording rather than duplicate metadata.

### Other cleaning decisions

- **3 missing `artist_name` values** were manually identified and corrected via cross-reference (`Never Felt So Alone` → Labrinth, `Radio` → Lana Del Rey, `Urban Twilight` → Grimes).
- **`artist_genres`** was kept rather than dropped, despite inconsistent source tagging conventions. Missing and `'N/A'` values were standardized to `'Unknown'`.
- **Placeholder `01-01` dates** were left in place rather than removed, and are documented here as a known limitation (see below).

---

## Phase 2: Business Questions

Six queries, each demonstrating a different SQL technique:

| # | Question | Technique |
|---|---|---|
| 1 | Which artists have the highest average track popularity (min. 3 tracks)? | `GROUP BY`, `AVG()`, `HAVING` |
| 2 | Does popularity differ by album type (single / album / compilation)? | `GROUP BY`, `AVG()` |
| 3 | Do explicit tracks score higher or lower than non-explicit tracks? | `GROUP BY` on a boolean column |
| 4 | Has average track duration changed by release year? | `EXTRACT(YEAR FROM ...)`, `GROUP BY` |
| 5 | What are each artist's top 3 tracks by popularity? | `RANK() OVER (PARTITION BY ...)` |
| 6 | Which artists' popularity outperforms their follower count? | CTE + calculated ratio |

### Selected findings

- **Albums average higher popularity (56.4) than singles (47.1) or compilations (40.0)**, despite singles making up a large share of the dataset.
- **Explicit tracks average higher popularity (58.8) than non-explicit tracks (51.2)**, despite being the smaller category by track count (1,989 vs. 5,934).
- **Average track duration has declined from ~3.6 minutes (2016) to ~3.1 minutes (2025)** — consistent with the well-documented "songs are getting shorter" trend in the streaming era.
- The dataset spans **1952–2025**, meaning duration trends are most meaningful from roughly 2010 onward, once yearly track volume increases.

---

## Files in This Repository

| File | Description |
|---|---|
| `phase1_cleaning.sql` | Table setup, deduplication logic, and missing-value fixes |
| `phase2_business_queries.sql` | The six business-question queries |
| `spotify_data_for_import.csv` | Source dataset (re-escaped for clean CSV import — see note below) |
| `spotify_tracks_clean.csv` | Final deduplicated, cleaned table, exported for reference |

---

## A Note on the Data

The original Kaggle CSV contained embedded double-quote characters inside `album_name` (e.g. `12" Singles`) that weren't escaped per CSV convention, which broke PostgreSQL's `COPY` import partway through. `spotify_data_for_import.csv` is a re-exported version of the same data (via pandas) with quoting corrected — no values were changed, only how embedded quotes are escaped.

The ~7.8% of rows carrying a placeholder `01-01` release date were left as-is rather than corrected or removed, since the real dates aren't recoverable from the source. This is factored into the deduplication rule (a non-placeholder date wins a tie over a placeholder one) but otherwise remains a caveat for any year/date-based analysis using this dataset.

`artist_genres` retains the source data's inconsistent, overlapping multi-tag conventions (e.g. `pop, dance pop, electropop`) rather than being normalized into a fixed taxonomy.

---

## Tools Used

- **PostgreSQL 18** — table design, cleaning, and all analysis queries
- **pgAdmin 4** — query execution and CSV import/export
- **Python (pandas)** — one-time CSV re-export to fix a CSV-quoting import error

---

## About

Built by **John Martin S. Villena**, BS Information Technology graduate (Business Analytics) from Bulacan State University.

🔗 [LinkedIn](https://www.linkedin.com/in/jhnmrtnvlln/)
