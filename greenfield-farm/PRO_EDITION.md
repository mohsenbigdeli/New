# Greenfield Farm Pro 0.2

This edition continues the current Fresh/Pixel Foundation on main (d607f38), not the retired v2.4 branch.

## Included
- Four-direction farmer sprite with feet aligned between frames; animation follows actual movement.
- Smooth analog controls without per-tick position rounding; collision stops the walking animation.
- Consistent green/gold HUD, title/pause menu, field guide, farm journal, contextual targeting and touch settings.
- Crop growth meters, ready markers, interaction particles and optional generated sound effects.
- Fixed partial tree atlas regions, corrected paddock fence art, solid pond and lower fence sections.
- Autosave every 30 seconds, manual save, save on focus loss/exit, validated saves with backup recovery.
- Persistent camera zoom, touch controls, effects and sound preferences.

## Play
Open project.godot with Godot 4.7.2 or install the Android debug APK from the linked GitHub Actions run.
WASD/arrows move. E/Space interact. J opens the journal, F5 saves, Esc pauses.
Touch controls activate by default on Android and can be changed in Settings.

This is a focused playable farm slice: eight crop beds and Marnie's guidance. It is not the full content of the legacy experimental v4/v5 scenes. Save files for this edition use greenfield_pro.json; legacy scene saves are not migrated.

## Validation
Run `godot --headless --path greenfield-farm --editor --import --quit` and then
`godot --headless --path greenfield-farm --script res://tests/pro_integration.gd`.
The test covers directional movement, collisions, analog input, targeting, the farming cycle, pause/settings, save round-trip and corrupt-save recovery. It uses a separate test save filename.
Visual previews are actual Godot renders. Physical Android device testing is still needed.
