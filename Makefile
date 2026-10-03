GODOT ?= godot
PYTHON ?= python3
VENV ?= .venv
GD_SOURCES := src tests data

.PHONY: setup format lint test check bench

setup:
	$(PYTHON) -m venv $(VENV)
	touch $(VENV)/.gdignore
	$(VENV)/bin/pip install --requirement requirements-dev.txt

format:
	$(VENV)/bin/gdformat $(GD_SOURCES)

lint:
	$(VENV)/bin/gdformat --check $(GD_SOURCES)
	$(VENV)/bin/gdlint $(GD_SOURCES)

# The import pass builds the class cache that a fresh checkout lacks.
# -c keeps running a suite after its first failure so every failing test is reported.
test:
	$(GODOT) --headless --path . --import
	GODOT_BIN="$$(command -v $(GODOT))" addons/gdUnit4/runtest.sh \
		--headless --ignoreHeadlessMode -c -a res://tests

check:
	$(MAKE) lint
	$(MAKE) test

bench:
	$(GODOT) --headless --path . -s res://src/tools/sim_benchmark.gd
