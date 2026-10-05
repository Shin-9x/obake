GODOT ?= godot
PYTHON ?= python3
VENV ?= .venv
GD_SOURCES := src tests data

# The export templates must match the editor version; update the version and checksum together.
GODOT_VERSION := 4.7.2
TEMPLATES_SHA512 := ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079
TEMPLATES_ARCHIVE := build/cache/Godot_v$(GODOT_VERSION)-stable_export_templates.tpz
TEMPLATES_URL := https://github.com/godotengine/godot/releases/download/$(GODOT_VERSION)-stable/$(notdir $(TEMPLATES_ARCHIVE))
TEMPLATES_DIR ?= $(HOME)/.local/share/godot/export_templates/$(GODOT_VERSION).stable

ADB ?= adb
ANDROID_PACKAGE := io.github.shin9x.obake

# Balance bot runs: how many, aims tried per shot, parallel processes, Hard mode (1), items of a
# new profile only (1), the seed of the first run, and where their lines go.
RUNS ?= 60
SKILL ?= 8
JOBS ?= 10
HARD ?= 0
FRESH ?= 0
FIRST_SEED ?= 1
LOGS ?= reports/balance
# Balance numbers to try instead of the shipped ones, as name:value pairs separated by commas.
SET ?=

.PHONY: setup format lint test check bench placeholder-art placeholder-audio layouts replays \
	record-replays \
	templates import exports export-linux export-windows export-android export-android-debug \
	pull-logs balance-sim balance-report

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
	mkdir -p reports && touch reports/.gdignore
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

# Plays the golden replays again with the balance bot when their recorded actions no longer fit.
record-replays: import
	$(GODOT) --headless --path . -s res://src/tools/record_replays.gd

# Downloads the official export templates once, checks them and installs the ones the presets use.
templates:
	mkdir -p $(dir $(TEMPLATES_ARCHIVE)) $(TEMPLATES_DIR)
	test -f $(TEMPLATES_ARCHIVE) || \
		{ curl -fL -o $(TEMPLATES_ARCHIVE).part $(TEMPLATES_URL) && mv $(TEMPLATES_ARCHIVE).part $(TEMPLATES_ARCHIVE); }
	echo "$(TEMPLATES_SHA512)  $(TEMPLATES_ARCHIVE)" | sha512sum --check --strict
	unzip -o -j -q $(TEMPLATES_ARCHIVE) 'templates/version.txt' 'templates/linux_*.x86_64' \
		'templates/windows_*_x86_64*' 'templates/android_*' -d $(TEMPLATES_DIR)

# Build output and test reports stay out of Godot's file system, and so out of every export.
import:
	mkdir -p build reports && touch build/.gdignore reports/.gdignore
	$(GODOT) --headless --path . --import

exports: export-linux export-windows export-android

export-linux: import
	mkdir -p build/linux
	$(GODOT) --headless --path . --export-release "Linux" build/linux/obake.x86_64

export-windows: import
	mkdir -p build/windows
	$(GODOT) --headless --path . --export-release "Windows" build/windows/obake.exe

# Signed with the release keystore named by the environment; see README, Builds.
export-android: import
	@test -n "$$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" \
		-a -n "$$GODOT_ANDROID_KEYSTORE_RELEASE_USER" \
		-a -n "$$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" || \
		{ echo "Set GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER and _PASSWORD (README, Builds)."; exit 1; }
	mkdir -p build/android
	$(GODOT) --headless --path . --export-release "Android" build/android/obake.apk

export-android-debug: import
	mkdir -p build/android
	$(GODOT) --headless --path . --export-debug "Android" build/android/obake-debug.apk

# Copies the run log from a phone over USB; adb may only read the files of a debug build.
pull-logs:
	mkdir -p reports/logs
	$(ADB) exec-out run-as $(ANDROID_PACKAGE) cat files/run_logs/runs.jsonl > reports/logs/phone.jsonl.part
	mv reports/logs/phone.jsonl.part reports/logs/phone.jsonl

# Plays bot runs in parallel processes, each writing its own file, then sums them up.
balance-sim: import
	rm -rf $(LOGS) && mkdir -p $(LOGS)
	seq 0 $$(($(JOBS) - 1)) | xargs -P $(JOBS) -I{} $(GODOT) --headless --path . \
		-s res://src/tools/balance/balance_sim.gd -- --runs=$(RUNS) --jobs=$(JOBS) --job={} \
		--skill=$(SKILL) --hard=$(HARD) --fresh=$(FRESH) --first-seed=$(FIRST_SEED) \
		--set=$(SET) --out=$(LOGS)/job_{}.jsonl
	$(MAKE) --no-print-directory balance-report LOGS=$(LOGS)

balance-report: import
	$(GODOT) --headless --path . -s res://src/tools/balance/balance_report.gd -- --logs=$(LOGS)
