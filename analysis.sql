-- ============================================================
-- Australian Public Health Mortality Analysis
-- Data Source: AIHW MORT Books (2019-2023)
-- Analyst: Cesar Pazo | Melbourne, Australia
-- ============================================================
-- Scope: State and Territory level analysis only
-- Population: 'Persons' (combined sex) unless otherwise noted
-- ============================================================


-- ------------------------------------------------------------
-- SECTION 1: DATABASE SETUP
-- ------------------------------------------------------------

CREATE TABLE mortality_summary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state TEXT NOT NULL,
    year INTEGER NOT NULL,
    sex TEXT NOT NULL,
    deaths INTEGER,
    population INTEGER,
    crude_rate_per_100000 REAL,
    age_standardised_rate_per_100000 REAL,
    premature_deaths INTEGER,
    potentially_avoidable_deaths INTEGER,
    median_age REAL
);

CREATE TABLE leading_causes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state TEXT NOT NULL,
    year_range TEXT NOT NULL,
    sex TEXT NOT NULL,
    rank INTEGER,
    cause_of_death TEXT,
    deaths INTEGER,
    deaths_percent REAL,
    crude_rate_per_100000 REAL,
    age_standardised_rate_per_100000 REAL
);


-- ------------------------------------------------------------
-- SECTION 2: DATA VALIDATION
-- Row counts to confirm successful data import
-- ------------------------------------------------------------

SELECT COUNT(*) AS total_rows FROM mortality_summary;
-- Expected: 150

SELECT COUNT(*) AS total_rows FROM leading_causes;
-- Expected: 600


-- ------------------------------------------------------------
-- QUERY 1: Mortality trend in Victoria (2019-2023)
-- Business question: How did total deaths evolve year by year
-- in Victoria? Are there any anomalies worth investigating?
-- ------------------------------------------------------------

SELECT year, deaths
FROM mortality_summary
WHERE state = 'Victoria' AND sex = 'Persons'
ORDER BY year ASC;

-- Finding: Sharp spike in 2022 (+5,492 deaths vs 2021),
-- linked to COVID-19 rebound after lockdown restrictions lifted
-- and deferred healthcare during the pandemic.


-- ------------------------------------------------------------
-- QUERY 2: Mortality rate by state (2023)
-- Business question: Which states had the highest mortality
-- rate per 100,000 inhabitants in 2023?
-- Note: Rate is more meaningful than absolute deaths for
-- comparing regions of different population sizes.
-- ------------------------------------------------------------

SELECT state, crude_rate_per_100000
FROM mortality_summary
WHERE year = 2023 AND sex = 'Persons'
ORDER BY crude_rate_per_100000 DESC;

-- Finding: Tasmania leads with 885.1 per 100,000 due to its
-- older population structure. ACT has the lowest rate (515.7),
-- reflecting a younger, more educated demographic.


-- ------------------------------------------------------------
-- QUERY 3: Average median age at death by state (2019-2023)
-- Business question: Where are people dying youngest?
-- This identifies regions with the greatest health inequity.
-- ------------------------------------------------------------

SELECT state, AVG(median_age) AS avg_median_age_at_death
FROM mortality_summary
WHERE sex = 'Persons'
GROUP BY state
ORDER BY avg_median_age_at_death ASC;

-- Finding: Northern Territory has the lowest median age at
-- death (67.2 years) — 15 years below South Australia (82.8).
-- This reflects significant health inequity, particularly
-- impacting Indigenous communities in remote areas.


-- ------------------------------------------------------------
-- QUERY 4: Total premature deaths by state (2019-2023)
-- Business question: Which states carry the highest burden
-- of premature mortality (deaths before age 75)?
-- ------------------------------------------------------------

SELECT state, SUM(premature_deaths) AS total_premature_deaths
FROM mortality_summary
WHERE sex = 'Persons'
GROUP BY state
ORDER BY total_premature_deaths DESC;

-- Finding: NSW and Victoria lead in absolute numbers due to
-- population size. However, absolute numbers alone are
-- misleading — see Query 5 for rate-based comparison.


-- ------------------------------------------------------------
-- QUERY 5: Premature death rate by state (calculated)
-- Business question: When controlling for population size,
-- which state has the highest premature mortality burden?
-- Formula: (premature_deaths / population) * 100,000
-- ------------------------------------------------------------

SELECT state,
       AVG((premature_deaths * 1.0 / population) * 100000) AS premature_death_rate_per_100k
FROM mortality_summary
WHERE sex = 'Persons'
GROUP BY state
ORDER BY premature_death_rate_per_100k DESC;

-- Finding: Northern Territory has the highest rate (329 per
-- 100,000) — nearly double the ACT (166). This confirms NT
-- as the highest-priority region for public health intervention,
-- despite having low absolute death counts due to small population.


-- ------------------------------------------------------------
-- QUERY 6: Premature death rate + leading cause (JOIN)
-- Business question: What is the leading cause of premature
-- death in each state, and how does it relate to the overall
-- premature mortality rate?
-- Tables joined: mortality_summary + leading_causes
-- Join key: state
-- ------------------------------------------------------------

SELECT m.state,
       AVG((m.premature_deaths * 1.0 / m.population) * 100000) AS premature_death_rate_per_100k,
       l.cause_of_death AS leading_cause_of_death
FROM mortality_summary m
JOIN leading_causes l ON m.state = l.state
WHERE m.sex = 'Persons'
AND l.sex = 'Persons'
AND l.rank = 1
GROUP BY m.state, l.cause_of_death
ORDER BY premature_death_rate_per_100k DESC;

-- Finding: Coronary heart disease is the leading cause of
-- premature death in 8 out of 10 states/territories.
-- South Australia and ACT show Dementia/Alzheimer's as their
-- top cause, reflecting older population profiles where people
-- survive long enough to develop degenerative conditions.
