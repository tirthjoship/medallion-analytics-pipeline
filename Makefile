.PHONY: test test-cov lint typecheck setup check pipeline

test:
	pytest tests/ -v --tb=short

test-cov:
	pytest tests/ -v --cov=pipeline --cov-fail-under=90 --tb=short

lint:
	pre-commit run --all-files

typecheck:
	mypy pipeline/ --strict

setup:
	pip install -e ".[dev]"
	pre-commit install

check: lint typecheck test-cov

pipeline:
	python -m pipeline.run_pipeline
