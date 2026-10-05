GODOT ?= godot
PYTHON ?= python3
VENV ?= .venv
GD_SOURCES := src tests data

.PHONY: setup format lint test check bench placeholder-art placeholder-audio layouts replays

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

placeholder-art:
	$(GODOT) --headless --path . -s res://src/tools/generate_placeholder_art.gd
	$(GODOT) --headless --path . --import

# Music files loop forward; the importer's default already compresses everything with QOA.
placeholder-audio:
	$(GODOT) --headless --path . --import
	$(GODOT) --headless --path . -s res://src/tools/generate_placeholder_audio.gd
	$(GODOT) --headless --path . --import
	sed -i 's|^edit/loop_mode=.*|edit/loop_mode=2|' assets/music/*.wav.import
	$(GODOT) --headless --path . --import

layouts:
	$(GODOT) --headless --path . --import
	$(GODOT) --headless --path . -s res://src/tools/export_layouts.gd

replays:
	$(GODOT) --headless --path . --import
	$(GODOT) --headless --path . -s res://src/tools/update_replays.gd
