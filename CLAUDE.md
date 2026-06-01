# CLAUDE.md — Medallion Analytics Pipeline

Read **`CONTEXT.md`** first — locked decisions, TLC dataset, medallion layers, Power BI deliverables.

## Quick reference

| Item | Value |
|------|-------|
| Dataset | NYC TLC Yellow Taxi Parquet (2024, 1–3 month slice) |
| Phase | **0 = EDA gate** — pipeline after `reports/eda_gate.md` GO |
| Portfolio docs | `../PORTFOLIO_LOCKED_DECISIONS.md`, `../PORTFOLIO_EDA_SPRINT.md` |

## Commands (after scaffold exists)

```bash
make setup         # pip install -e ".[dev]" + pre-commit install
make test          # data quality pytest (no coverage)
make test-cov      # pytest with --cov=pipeline --cov-fail-under=90
make lint          # pre-commit run --all-files
make typecheck     # mypy pipeline/ --strict
make check         # lint + typecheck + test-cov (full gate)
make pipeline      # bronze → silver → gold
```

> **Note:** `make test-cov`, `make typecheck`, and `make pipeline` require the `pipeline/` directory (created in Phase 1).

## Rules

1. **Bronze is immutable** — never edit raw Parquet in place.
2. **KPI definitions** in `docs/KPI_DEFINITIONS.md` must match Power BI measures.
3. **Do not use DataCo** supply chain data.
4. Commit **dashboard PDF/png** if `.pbix` is too large for git.
5. Document row-drop counts at each layer.

## First session default

Execute **Phase 0 EDA only** per `CONTEXT.md` §15 Session 1.
