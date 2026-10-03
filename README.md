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
make placeholder-art  # regenerate the placeholder sprites
```

## Controls

| Action | Mouse and keyboard | Touch |
| --- | --- | --- |
| Aim | Move the mouse | Drag anywhere |
| Fine aim | Mouse wheel, A/D or arrow keys | `<` `>` buttons |
| Shoot | Left click or Enter | Shoot button |
| Fast-forward | Hold Space or the right mouse button | Keep a finger on the screen |

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
