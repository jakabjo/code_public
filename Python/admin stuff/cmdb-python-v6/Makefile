
# CMDB Python Toolkit - Makefile

VENV ?= .venv
PY ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip

.PHONY: help venv install dev lint test run dry-run html clean package

help:
	@echo "Targets:"
	@echo "  venv       - create virtual environment"
	@echo "  install    - install runtime dependencies"
	@echo "  dev        - install dev tools (ruff, flake8, pytest)"
	@echo "  lint       - run linters"
	@echo "  test       - run tests (if present)"
	@echo "  run        - run full inventory"
	@echo "  dry-run    - discovery only"
	@echo "  html       - open HTML report"
	@echo "  package    - build zip of project"
	@echo "  clean      - remove caches and build artifacts"

venv:
	python -m venv $(VENV)

install: venv
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

dev: install
	$(PIP) install ruff flake8 pytest

lint:
	@if [ -x "$(VENV)/bin/ruff" ]; then $(VENV)/bin/ruff . ; fi
	@if [ -x "$(VENV)/bin/flake8" ]; then $(VENV)/bin/flake8 . ; fi

test:
	@if [ -d "tests" ]; then $(VENV)/bin/pytest -q ; else echo "No tests/ directory."; fi

run:
	$(PY) cmdb_inventory.py -c config.yaml -o out --autotune --tui

dry-run:
	$(PY) cmdb_inventory.py -c config.yaml -o out --dry-run --tui

html:
	@if [ -f "out/inventory.html" ]; then 		python -c "import webbrowser; webbrowser.open('out/inventory.html')" ; 	else echo "Run 'make run' first to generate out/inventory.html"; fi

package:
	zip -r cmdb-python-bundle.zip . -x "$(VENV)/*" -x "out/*" -x "__pycache__/*" -x ".git/*"

clean:
	rm -rf __pycache__ .pytest_cache .ruff_cache build dist out
