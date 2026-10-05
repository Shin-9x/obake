# Obake!

A 2D pixel-art Peggle-like roguelike set in Japanese folklore, built with Godot 4 and fully typed GDScript.

## Requirements

- Godot 4.7 (the `godot` binary on `PATH`, or pass `GODOT=/path/to/godot` to `make`)
- Python 3 for the gdtoolkit formatter and linter
- GNU Make

## Development

```bash
make setup    # create .venv and install gdtoolkit
make format   # format GDScript in src/, tests/ and data/
make lint     # check formatting and run gdlint
make test     # run the gdUnit4 test suite headless
make check    # lint, then test
make bench    # measure simulation cost per tick
make placeholder-art  # regenerate the placeholder sprites, app icons and boot splash
make placeholder-audio  # regenerate the placeholder sounds and music loops
make layouts  # export every layout source scene to data/layouts
```

## Board layouts

Layouts are authored in the Godot editor. Each source scene in
`src/tools/layout_editor/layouts/` has a `LayoutDocument` root whose children describe the
board: `PegMarker` nodes, pattern generators (`ArcPattern`, `CirclePattern`, `SpiralPattern`,
`GridPattern`, `WavePattern`) and `MovingGroupMarker` nodes for rotating or sliding groups.
Move, rotate and duplicate them as usual; the scene dock warns about overlaps or pegs outside
the board. Use **Bake into pegs** on a pattern to hand-tune its pegs, and **Export JSON** on the
document (or `make layouts`) to write `data/layouts/<id>.json`, which the game loads. The test
suite fails if a source scene and its JSON disagree.

Boss layouts set **Kind** to boss on the document; `ZoneMarker` nodes add circular zones, such
as Jorōgumo's webs.

## Playing

Press **F5** to start at the title screen, where the settings (volumes, language, scaling, screen
shake, fast-forward speed) also live. **New run** asks for a character, then you pick your way
through four floors of
boards, shops, shrines and yōkai events, each ending with a boss. Numbers such as targets,
prices and odds live in `data/balance.tres`; what a run can offer lives in
`data/run_content.tres`.

The run is saved after every action, so closing the game and pressing **Continue run** picks it
up exactly where it was. Feats unlock locked items for later runs (`data/feats/`), beating
Shuten-dōji opens Hard mode for that character, and the compendium and statistics are reached
from the character screen. A typed seed replays a run but earns no feats or marks. Saves live in
Godot's user data folder (`profile.json` and `run.json`).

To try items on a single board, open `src/presentation/board/board_screen.tscn` and press
**F6**: it plays random layouts with `data/debug/dev_loadout.tres` (character, bag, omamori in
slot order and purchased pegs), which you can edit in the Inspector. Item, character and boss
definitions live in `data/`, with their behaviour in `src/sim/effects/`; events live in
`data/events/` and `src/run/events/`.

## Controls

| Action | Mouse and keyboard | Gamepad | Touch |
| --- | --- | --- | --- |
| Aim | Move the mouse | Left stick | Drag anywhere |
| Fine aim | Mouse wheel, A/D or arrow keys | Triggers | `<` `>` buttons |
| Shoot | Left click or Enter | A | Shoot button |
| Fast-forward | Hold Space or the right mouse button | Hold RB | Keep a finger on the screen |
| Pause | Esc | Start | Pause button |
| Menus | Mouse, or arrows and Enter | D-pad, A, B | Tap |

## Builds

`make templates` downloads the official Godot 4.7.2 export templates once (about 1.3 GB, checked
against their SHA-512) and installs the Linux, Windows and Android ones. Then:

```bash
make export-linux          # build/linux/obake.x86_64
make export-windows        # build/windows/obake.exe, unsigned: SmartScreen warns on first launch
make export-android-debug  # build/android/obake-debug.apk, signed with Godot's debug key
make export-android        # build/android/obake.apk, signed with your release key
make exports               # the three release builds
```

The version lives in `application/config/version` in `project.godot`. Raise `version/code` in
the Android preset with every build meant to install over an older one.

**Android release key.** Create the keystore once, outside the repository; `keytool` asks for
its password:

```bash
keytool -genkeypair -v -keystore ~/keys/obake-release.keystore -alias obake -keyalg RSA -keysize 2048 -validity 10000
```

Then pass its path, alias and password to the export through the environment, for example in
fish, where `read -s` keeps the password off the screen and out of the history:

```fish
set -x GODOT_ANDROID_KEYSTORE_RELEASE_PATH ~/keys/obake-release.keystore
set -x GODOT_ANDROID_KEYSTORE_RELEASE_USER obake
read -s -x -P "Keystore password: " GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Keep the keystore and its password safe: Android only installs updates signed with the same key.
Debug and release builds carry different signatures, so uninstall one before installing the
other, which deletes the saves on the phone. Install on a phone connected over USB with
`adb install -r build/android/obake.apk`.

Pushing a `v*` tag, or starting the **Release builds** workflow by hand on GitHub, exports Linux,
Windows and an Android build signed with a throwaway debug key, and keeps them as artifacts of
the workflow run. Release-signed Android builds are only made locally.

macOS and iOS builds come later.

**Performance.** **Show performance** in the settings puts frame rate, frame times, simulation
tick cost and draw calls in a corner of the screen. Debug builds also offer **Benchmark** in the
settings opened from the title: it plays busy development boards on its own for 20 shots and
reports frame time percentiles and dropped frames, also to the log (`adb logcat -s godot` on a
phone). The tick cost appears in the editor's Monitors tab as `obake/tick_usec`.

## Run logs

Every settled board and the end of every run add a line of JSON to `run_logs/runs.jsonl` in
Godot's user data folder, for balancing: score against target, shots, mon and the loadout, and
for each finished run its whole action log. The log never leaves the device; past 1 MB it moves
to `runs.old.jsonl`. On Linux the folder is `~/.local/share/godot/app_userdata/Obake!/`, on
Windows `%APPDATA%\Godot\app_userdata\Obake!\`. From a phone running a debug build, connected
over USB:

```bash
make pull-logs ADB=~/Android/Sdk/platform-tools/adb  # writes reports/logs/phone.jsonl
```

The balance bot plays whole runs headless and writes the same lines. For each shot it tries
`SKILL` aims spread across the launcher's range on copies of the run and keeps the one that
scores most, so a skill of 1 shoots at random; in shops and rewards it favours rare items and
keeps some mon for interest. The characters take turns.

```bash
make balance-sim RUNS=60 SKILL=8 JOBS=10 HARD=0 FRESH=0  # bot runs into reports/balance, then a report
make balance-report LOGS=reports/logs                    # sums up any folder of run logs
```

`FRESH=1` limits the items to those a new profile has unlocked, and `SET` tries other balance
numbers without editing them, for example `SET=first_board_target:700,board_target_growth:1250`. The report gives, for Normal and
Hard apart, how many runs were won and on which floor the others ended, wins by character, and
for each board of a run how often it was reached, won and turned into a Matsuri, the median
score against the target, the shots left when won and the mon held afterwards.

## Layout

| Folder | Content |
| --- | --- |
| `src/sim/` | Deterministic simulation: fixed-point physics, scoring, effects, RNG |
| `src/run/` | Run logic: map, shop, economy, bag, progression |
| `src/presentation/` | Scenes, rendering, UI, VFX, audio |
| `data/` | Resource definitions and JSON board layouts |
| `locale/` | Translations (English and Italian) |
| `tests/` | gdUnit4 tests, mirroring `src/` |
| `addons/gdUnit4/` | Vendored gdUnit4 test framework |
