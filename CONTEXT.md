# CONTEXT.md — Medallion Analytics Pipeline (Bronze → Gold → Power BI)

**Repo:** `medallion-analytics-pipeline`  
**Owner:** Tirth Joshi  
**Created:** 2026-05-30  
**Phase:** 0 — EDA gate → then pipeline implementation  
**Portfolio slot:** Project 5 of 5 (balanced DA/DS strategy)

**Read first:** [`../PORTFOLIO_LOCKED_DECISIONS.md`](../PORTFOLIO_LOCKED_DECISIONS.md) · [`../PORTFOLIO_EDA_SPRINT.md`](../PORTFOLIO_EDA_SPRINT.md)  
**Future enhancements:** [`docs/FUTURE_ENHANCEMENTS.md`](docs/FUTURE_ENHANCEMENTS.md)

---

## 1. Mission

Build a **production-style medallion analytics pipeline** that transforms messy raw trip data into **trusted Gold KPIs** and an **executive Power BI dashboard** with lineage and data quality gates.

Answers the question hiring managers in **Vancouver** ask:

> *Can you own Bronze/Silver/Gold, write the SQL, document KPIs, and deliver a dashboard executives trust?*

This project is **pipeline-first, ML-optional**. Do not force predictive modeling to salvage weak signal (lesson from DataCo).

---

## 2. Locked decisions (do not revisit without user approval)

| Decision | Choice |
|----------|--------|
| **Dataset** | [NYC TLC Yellow Taxi Trip Records](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) |
| **Scope** | **3-month slice** (Jan–Mar 2024) or **1 month minimum** for sprint (document which) |
| **Medallion layers** | Bronze (raw Parquet) → Silver (cleansed) → Gold (star schema SQL views) |
| **Transform engine** | Polars or DuckDB (pick one in EDA; prefer Polars for large CSV ingest) |
| **Quality** | pytest data tests + `docs/DATA_QUALITY_RULES.md` (Great Expectations optional) |
| **BI** | **Power BI** `.pbix` + exported PDF/screenshots in `docs/dashboard/` |
| **Orchestration** | GitHub Actions on sample/subset (document schedule) |
| **Do NOT use** | DataCo supply chain CSV (weak narrative; already project 1) |
| **Cloud (locked)** | **Databricks Delta** — same platform as UBC Sesapan capstone; see [`../PORTFOLIO_TOOLS_PLAYBOOK.md`](../PORTFOLIO_TOOLS_PLAYBOOK.md) |
| **AWS** | Optional S3 bronze backup + report PDFs (`boto3`, private bucket) |
| **Azure mapping** | Document ADF/Synapse equivalence in `docs/AZURE_EQUIVALENT.md` (AZ-900 story) |
| **Local first** | Git-tracked pipeline must run without cloud; Databricks chapter is additive |

---

## 3. Why NYC TLC

| Criterion | TLC |
|-----------|-----|
| Volume | Millions of rows/month — credible scale |
| Messiness | Nulls, bad fares, invalid timestamps — real pipeline work |
| Dimensionality | Natural star schema: trips fact + date + zone + vendor |
| KPI clarity | Trips/day, revenue, avg fare, peak hour, payment type mix |
| Public & free | No API keys; Parquet preferred over CSV |

**Reference:** [TLC Yellow Trip Data Dictionary (PDF)](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf)

---

## 4. Dataset download & layout

**Download:** Parquet preferred from TLC site → `data/bronze/yellow/yellow_tripdata_2024-01.parquet` (etc.)

**Gitignore:** All of `data/bronze/`, `data/silver/`, `data/gold/` except `.gitkeep` and `tests/fixtures/`

**Bronze rule:** Immutable — never overwrite raw files; re-ingest adds new partition.

### Key columns (Yellow 2024 schema — verify in EDA)

| Column | Silver use |
|--------|------------|
| `VendorID` | dim_vendor |
| `tpep_pickup_datetime` | dim_date, fact time key |
| `tpep_dropoff_datetime` | trip duration validation |
| `passenger_count` | fact |
| `trip_distance` | fact |
| `RatecodeID` | dim_rate |
| `PULocationID`, `DOLocationID` | dim_zone (join taxi zone lookup if used) |
| `payment_type` | dim_payment |
| `fare_amount`, `extra`, `mta_tax`, `tip_amount`, `total_amount` | fact revenue |
| `congestion_surcharge`, `cbd_congestion_fee` | fact (2024+) |

---

## 5. Medallion layer specs

### Bronze
- Raw Parquet as downloaded
- Metadata sidecar: `bronze_manifest.json` (file, row_count, ingest_ts, checksum)

### Silver (`data/silver/yellow/` or DuckDB table)
- Parse datetimes; drop invalid (pickup after dropoff, negative distance)
- Drop or cap extreme fares (document thresholds in `DATA_QUALITY_RULES.md`)
- Standardize types; dedup if needed
- Add `ingest_date` partition column

### Gold (SQL views or Parquet star schema)

**Fact:** `fact_trips`
- Grain: one row per trip
- Measures: `trip_distance`, `fare_amount`, `total_amount`, `tip_amount`, `duration_minutes`

**Dimensions:**
- `dim_date` — date key from pickup datetime
- `dim_vendor` — VendorID
- `dim_zone` — pickup/dropoff zone (optional v1: borough rollup only)
- `dim_payment` — payment_type

**Gold KPI views (examples):**
- `gold_kpi_daily` — trips, total_revenue, avg_fare by date
- `gold_kpi_hourly` — peak hour analysis
- `gold_kpi_vendor` — vendor mix

Lock exact definitions in `docs/KPI_DEFINITIONS.md` (BRD style — enterprise language).

---

## 6. Data quality rules (draft — confirm in EDA)

| Rule | Silver action |
|------|---------------|
| `total_amount` null | Drop row; log count |
| `total_amount` < 0 | Drop or flag |
| `trip_distance` <= 0 | Drop |
| `passenger_count` == 0 | Keep but flag (still valid trip) |
| Pickup year != file partition | Quarantine |
| Duplicate `pickup`+`dropoff`+`fare` | Investigate; dedup if exact dup |

Each rule → pytest in `tests/test_data_quality.py` on fixtures.

---

## 7. Phase 0 — EDA gate (START HERE)

**Claude Code first task:** Phase 0 only.

```
notebooks/00_eda_gate.ipynb
reports/eda_gate.md
docs/DATA_DICTIONARY.md
```

### EDA checklist

- Load 1 month Parquet; row count and memory estimate for 3 months
- Null % per critical column
- Distribution of `total_amount`, `trip_distance` — outlier thresholds
- Trips per day time series — sanity (COVID-era comparisons not needed)
- Invalid datetime rows count
- Can we compute 5 KPIs without ambiguity?
- Draft star schema diagram (Mermaid) in `docs/lineage.md`

### Go criteria

- ≥500k rows (1 month) or ≥1M (3 months)
- <10% row loss silver with documented rules
- KPI definitions pass user review in `KPI_DEFINITIONS.md`

---

## 8. Target repository layout (post-EDA)

```
medallion-analytics-pipeline/
├── pipeline/
│   ├── bronze_ingest.py
│   ├── silver_transform.py
│   ├── gold_build.py          # SQL views or parquet writes
│   └── run_pipeline.py        # CLI entrypoint
├── sql/gold/                  # CREATE VIEW statements
├── tests/
│   ├── fixtures/              # tiny parquet/csv
│   └── test_data_quality.py
├── powerbi/
│   └── medallion_dashboard.pbix   # user may need Desktop to edit
├── docs/
│   ├── KPI_DEFINITIONS.md
│   ├── DATA_QUALITY_RULES.md
│   ├── lineage.md
│   └── dashboard/             # PDF/png exports for GitHub
├── notebooks/00_eda_gate.ipynb
├── reports/eda_gate.md
├── data/
│   ├── bronze/.gitkeep
│   ├── silver/.gitkeep
│   └── gold/.gitkeep
├── .github/workflows/refresh.yml
├── Makefile
├── pyproject.toml
└── README.md
```

---

## 9. Power BI deliverable

**Minimum for portfolio:**
- `.pbix` committed OR documented why binary omitted (LFS) + **PDF export required**
- Screenshots: daily trips, revenue trend, avg fare, top pickup zones
- Semantic model notes: which Gold tables feed which visuals
- Tie to **PL-900** cert mention in README (user has Microsoft Power Platform PL-900)

**DAX measures** should mirror `KPI_DEFINITIONS.md` exactly — no drift between SQL Gold and PBI.

---

## 10. Optional ML (only if pipeline done early)

- Isolation Forest on daily trip count anomalies in Gold
- **Do not** block v1 on ML — one notebook max

---

## 11. Success criteria (v1 complete)

| Criterion | Evidence |
|-----------|----------|
| EDA gate GO | `reports/eda_gate.md` |
| Bronze→Silver→Gold runnable | `make pipeline` or documented CLI |
| Quality tests pass | pytest green |
| KPI_DEFINITIONS + lineage | `docs/` complete |
| Power BI | pbix and/or PDF in `docs/dashboard/` |
| README | Architecture diagram, KPI table, refresh instructions |
| GitHub Action | Runs pipeline on fixture or 1-day sample |

---

## 12. Out of scope (v1)

- Databricks / Azure deployment (document mapping only)
- Green taxi + FHV union (Yellow only v1)
- Real-time streaming
- DataCo reuse

---

## 13. Sibling repos

| Pattern | Source |
|---------|--------|
| Makefile, pre-commit | `supply-chain-optimization-ml/` |
| ADR-style docs | `multi-modal-stock-recommender/docs/adr/` |
| Raw data gitignore + cache | stock recommender ADR-017 pattern |

---

## 14. Resume bullet (fill after v1)

> Built medallion pipeline (Bronze/Silver/Gold) on N NYC taxi trips with automated quality tests; authored KPI definitions and Power BI executive dashboard with documented lineage.

---

## 15. Claude Code — session playbook

### Session 1 (EDA only)
```text
Read CONTEXT.md and ../PORTFOLIO_EDA_SPRINT.md.
Phase 0: download instructions in README if data absent.
Create notebooks/00_eda_gate.ipynb, reports/eda_gate.md, docs/DATA_DICTIONARY.md.
Propose outlier thresholds and KPI list for user review in KPI_DEFINITIONS.md draft.
Do not build full pipeline yet.
```

### Session 2 (after GO)
```text
Implement bronze_ingest, silver_transform, gold_build, tests/test_data_quality.py.
Add Makefile targets: make pipeline, make test.
```

### Session 3
```text
Build Power BI connection docs; user adds pbix locally.
Export dashboard PDF to docs/dashboard/.
Add GitHub Actions workflow on fixture data.
Finalize README with Mermaid lineage diagram.
```

---

## 16. User background

See project 4 CONTEXT.md — regulated-sector analytics + UBC MDS; Vancouver BI roles priority.

Do **not** claim TLC work as employer project.
