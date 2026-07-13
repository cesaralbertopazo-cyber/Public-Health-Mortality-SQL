# Australian Public Health Mortality Analysis

**SQL · SQLite · DBeaver · Public Health Analytics**

A structured SQL analysis of mortality trends across Australian states and territories, using official data from the Australian Institute of Health and Welfare (AIHW). This project simulates a data analytics engagement for a public health department, identifying regional disparities in mortality rates, premature deaths, and leading causes of death to support resource allocation decisions.

> **Data Source:** AIHW MORT Books (Mortality Over Regions and Time), 2019–2023. Available at [data.gov.au](https://data.gov.au/data/dataset/mort-books). Data covers State and Territory level only (scope decision made at project outset to maintain analytical focus).

---

## Business Context

A public health department needs to understand where mortality burden is highest across Australia — not just in absolute numbers, but relative to population size. Absolute death counts are misleading when comparing regions as different as New South Wales (8M people) and the Northern Territory (250K people).

This project was built to answer:
- Where are people dying youngest, and why?
- Which regions carry the highest premature mortality burden when controlling for population?
- What is the leading cause of death in each state, and does it vary by region?

---

## Database Schema

Two tables, joined on `state`:

```
mortality_summary                    leading_causes
─────────────────                    ──────────────
id (PK)                              id (PK)
state          ◄──── JOIN ────►      state
year                                 year_range
sex                                  sex
deaths                               rank
population                           cause_of_death
crude_rate_per_100000                deaths
age_standardised_rate_per_100000     deaths_percent
premature_deaths                     crude_rate_per_100000
potentially_avoidable_deaths         age_standardised_rate_per_100000
median_age
```

**mortality_summary** — 150 rows: one row per state/year/sex combination, containing overall mortality statistics (2019–2023).

**leading_causes** — 600 rows: top 20 causes of death per state/sex, aggregated for the full 2019–2023 period.

---

## Analysis & Key Findings

### Query 1 — Mortality Trend in Victoria (2019–2023)

```sql
SELECT year, deaths
FROM mortality_summary
WHERE state = 'Victoria' AND sex = 'Persons'
ORDER BY year ASC;
```

| Year | Deaths |
|------|--------|
| 2019 | 41,227 |
| 2020 | 41,093 |
| 2021 | 42,486 |
| 2022 | 47,978 |
| 2023 | 45,326 |

**Finding:** Deaths remained relatively stable in 2020–2021 despite the pandemic, likely due to Victoria's strict lockdowns reducing other causes of death (accidents, flu). The sharp spike in 2022 (+5,492 deaths vs 2021) reflects the COVID-19 rebound after restrictions lifted, combined with deferred healthcare during the pandemic years.

---

### Query 2 — Mortality Rate by State (2023)

```sql
SELECT state, crude_rate_per_100000
FROM mortality_summary
WHERE year = 2023 AND sex = 'Persons'
ORDER BY crude_rate_per_100000 DESC;
```

**Finding:** Tasmania leads with 885.1 deaths per 100,000 — the highest in the country — driven by its older population structure. The Northern Territory, despite having the worst health outcomes by other measures, ranks last (496.2) because it has a younger overall population. This illustrates why crude rates alone are insufficient: they reflect population age structure, not just health system performance.

---

### Query 3 — Average Median Age at Death by State (2019–2023)

```sql
SELECT state, AVG(median_age) AS avg_median_age_at_death
FROM mortality_summary
WHERE sex = 'Persons'
GROUP BY state
ORDER BY avg_median_age_at_death ASC;
```

**Finding:** The Northern Territory has the lowest median age at death (67.2 years) — a full 15 years below South Australia (82.8). This is the starkest indicator of health inequity in the dataset, reflecting limited healthcare access and higher rates of chronic disease in Indigenous communities across remote NT regions.

---

### Query 4 — Total Premature Deaths by State (2019–2023)

Premature death = death before age 75, as defined by Australian health authorities.

```sql
SELECT state, SUM(premature_deaths) AS total_premature_deaths
FROM mortality_summary
WHERE sex = 'Persons'
GROUP BY state
ORDER BY total_premature_deaths DESC;
```

**Finding:** NSW (90,745) and Victoria (68,135) lead in absolute premature deaths — but this largely reflects their larger populations. Absolute numbers alone do not identify where health intervention is most needed. See Query 5.

---

### Query 5 — Premature Death Rate by State (Population-Adjusted)

```sql
SELECT state,
       AVG((premature_deaths * 1.0 / population) * 100000) AS premature_death_rate_per_100k
FROM mortality_summary
WHERE sex = 'Persons'
GROUP BY state
ORDER BY premature_death_rate_per_100k DESC;
```

**Finding:** When controlling for population size, the Northern Territory (329 per 100,000) carries nearly **double** the premature mortality burden of the Australian Capital Territory (166). This rate-based view is the most meaningful for resource allocation decisions — it identifies where people are dying young relative to the population, not just where there are more people overall.

---

### Query 6 — Premature Death Rate + Leading Cause of Death (JOIN)

```sql
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
```

**Finding:** Coronary heart disease is the leading cause of premature death in 8 out of 10 states and territories — a consistent national pattern. The two exceptions are South Australia and the ACT, where Dementia/Alzheimer's disease ranks first, reflecting older population profiles where people survive long enough to develop degenerative conditions before dying.

---

## Summary of Insights

| Finding | Implication |
|---|---|
| NT median age at death is 67 — 15 years below SA | Severe health inequity; strongest case for targeted intervention |
| NT premature death rate is double the ACT | Population-adjusted metrics reveal what absolute counts hide |
| 2022 mortality spike in Victoria | Post-pandemic rebound effect; deferred care has measurable consequences |
| Coronary heart disease leads in 8/10 states | Cardiovascular prevention programs have national relevance |
| Tasmania has highest crude rate but good median age | High crude rate reflects aging population, not poor health outcomes |

---

## SQL Concepts Demonstrated

| Concept | Used in |
|---|---|
| `SELECT`, `WHERE`, `ORDER BY` | All queries |
| `AND` (multiple conditions) | Queries 1–6 |
| Aggregate functions (`SUM`, `AVG`, `COUNT`) | Queries 3–6 |
| `GROUP BY` | Queries 3–6 |
| Calculated columns with `AS` alias | Query 5–6 |
| `JOIN` across two tables | Query 6 |

## Repository Structure

```
├── analysis.sql              # All 6 queries with business context and findings
├── mortality_summary.csv     # Cleaned dataset: mortality statistics by state/year/sex
├── leading_causes.csv        # Cleaned dataset: top 20 causes of death by state/sex
└── README.md
```

---

**Cesar Pazo** — Data Analyst, Melbourne, Australia
📧 cesaralberto.pazo@gmail.com
