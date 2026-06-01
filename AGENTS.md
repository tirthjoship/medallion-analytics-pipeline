# Coding Standards — Medallion Analytics Pipeline

## Python

- Python 3.12+
- Formatting: `black` (line-length 88)
- Type checking: `mypy` with strict mode enabled
- Linting: `ruff`
- Import sorting: `isort` (profile: black)
- No bare `except` — use specific exception types
- Type hints on all public function signatures
- Prefer `X | None` over `Optional[X]` (Python 3.12 syntax)

## Naming Conventions

- **Variables and functions**: `snake_case` (e.g., `ingest_bronze`, `transform_silver`)
- **Classes**: `PascalCase` (e.g., `BronzeIngestor`, `SilverTransformer`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `BRONZE_PATH`, `QUALITY_RULES`)
- **Modules**: `snake_case` (e.g., `bronze_ingest.py`, `gold_build.py`)
- **Test functions**: `test_<description>` (e.g., `test_null_fare_dropped`)
- **Private methods**: prefix with `_`

## Architecture Rules (NON-NEGOTIABLE)

- Pipeline layout: `pipeline/` (ingest → transform → build)
- Bronze is IMMUTABLE — never edit raw Parquet in place
- Each layer reads from previous layer only (Bronze→Silver→Gold)
- No backward writes (Silver must never modify Bronze)
- SQL views in `sql/gold/` — Gold KPI definitions
- Data quality rules documented in `docs/DATA_QUALITY_RULES.md`

## Data Quality Rules (NON-NEGOTIABLE)

- Every Silver transform must log row-drop counts
- Quality rules have pytest equivalents in `tests/test_data_quality.py`
- KPI definitions in `docs/KPI_DEFINITIONS.md` must match Power BI DAX exactly
- Bronze manifest tracks file checksums — detect re-ingestion
- Invalid datetime rows quarantined, not silently dropped

## Testing Rules (NON-NEGOTIABLE)

- Tests use small fixtures in `tests/fixtures/` — NEVER load full TLC Parquet
- pytest with `-v --tb=short` default
- Test categories: happy path, error path, boundary, edge case
- One logical assertion per test function
- Pin test data to known values — no random generation in quality tests

## Project Layout

```
pipeline/               Transform logic
├── bronze_ingest.py    Raw Parquet loading + manifest
├── silver_transform.py Cleansing, type standardization
├── gold_build.py       Star schema / KPI views
└── run_pipeline.py     CLI entrypoint

sql/gold/               CREATE VIEW statements for KPIs
tests/                  Data quality + pipeline tests
├── fixtures/           Tiny Parquet/CSV samples
├── conftest.py         Shared fixtures
└── test_data_quality.py

notebooks/              EDA only — no production logic
data/bronze/            Raw TLC Parquet (gitignored)
data/silver/            Cleansed (gitignored)
data/gold/              Star schema (gitignored)
docs/                   KPI definitions, quality rules, lineage
reports/                EDA gate, pipeline run summaries
```

## Git (NON-NEGOTIABLE)

- Commit format: `feat:` / `fix:` / `docs:` / `chore:` / `test:` followed by lowercase description, no period
- Keep commits small and focused
- Never commit directly to `main` or `dev` — use feature branches
- Branch naming: `feat/<slug>` or `fix/<slug>`
- PR target: `dev` (confirm with user before targeting `main`)
- Never commit secrets, raw data, or Parquet files
- Prefer new commits over `--amend` on pushed branches

## Commands

```bash
make pipeline    # bronze → silver → gold
make test        # pytest -v --tb=short
make test-cov    # pytest with coverage
make lint        # pre-commit run --all-files
make typecheck   # mypy pipeline/ --strict
make check       # lint + typecheck + test-cov
make setup       # install deps + pre-commit
```

## Strong Preferences

- Use structured logging over `print()` (loguru when added)
- Document row counts at each pipeline layer
- Parquet over CSV for all intermediate artifacts
- DuckDB or Polars for transforms (pick one in EDA, document in ADR)
