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

Press **F5** to play a run: choose a character, then pick your way through four floors of
boards, shops, shrines and yōkai events, each ending with a boss. Numbers such as targets,
prices and odds live in `data/balance.tres`; what a run can offer lives in
`data/run_content.tres`.

To try items on a single board, open `src/presentation/board/board_screen.tscn` and press
**F6**: it plays random layouts with `data/debug/dev_loadout.tres` (character, bag, omamori in
slot order and purchased pegs), which you can edit in the Inspector. Item, character and boss
definitions live in `data/`, with their behaviour in `src/sim/effects/`; events live in
`data/events/` and `src/run/events/`.

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
