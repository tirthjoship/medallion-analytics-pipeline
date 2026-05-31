# Medallion Analytics Pipeline

**Status:** Phase 0 — EDA gate  
**Portfolio:** Project 5 of 5 · Balanced DA/DS strategy

Bronze → Silver → Gold data pipeline with quality tests, KPI definitions, lineage documentation, and **Power BI** executive dashboard on **NYC TLC Yellow Taxi** data.

## Start here (Claude Code / developers)

1. [`CONTEXT.md`](./CONTEXT.md) — mission, locked decisions, layer specs, session playbook  
2. [`../PORTFOLIO_EDA_SPRINT.md`](../PORTFOLIO_EDA_SPRINT.md) — EDA checklist  
3. [`CLAUDE.md`](./CLAUDE.md) — rules and commands  

## Dataset

Download [NYC TLC Yellow Trip Records](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) (Parquet, 2024) into `data/bronze/yellow/` (not committed).

Start with **one month** for EDA; expand to three months for Gold KPIs if feasible.

## Phase 0 deliverables

- [ ] `notebooks/00_eda_gate.ipynb`
- [ ] `reports/eda_gate.md` (GO/NO-GO)
- [ ] `docs/DATA_DICTIONARY.md`
- [ ] `docs/KPI_DEFINITIONS.md` (draft)

Pipeline implementation begins only after EDA gate passes.
