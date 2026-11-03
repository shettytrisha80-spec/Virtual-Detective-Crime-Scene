# Validation report

Engine: Godot 4.5.2 stable, Windows x64, Standard GDScript build.

Completed checks:

- Editor import and GDScript parsing.
- Static scene/script resource paths and all nine dynamically loaded WAV paths.
- WAV RIFF/WAVE headers, PCM mono/16-bit format and payload lengths.
- Nine physics ray probes: notebook, phone, key, footprint, window, blood trace, drawer, service door and terminal.
- Drawer blocks entry without key; service alcove blocks entry without ledger.
- All eight clues collect; drawer and service door unlock.
- CCTV and other panels instantiate successfully.
- All four supported evidence pairs connect.
- All three interview challenges unlock from their required links.
- Accusation completeness gate and correct/incorrect evidence selection.
- Both ending panels and return/review panels instantiate.
- Rendered menu, apartment, rotating-inspection panel and evidence board inspected at 1280 × 800.
- Fresh ZIP extraction, editor import and smoke test.

Expected test output:

```text
PATH/AUDIO PASS: 12 static references and dynamic audio resources valid.
RAY PASS: nine world interaction targets are reachable
SMOKE PASS: progression locks, eight clues, four links, interviews, accusation and both endings
```

Limitations: no headset was available; controller tracking and OpenXR runtime behavior have not been hardware tested. The smoke test calls the actual interaction/state functions and probes physical scene rays, but does not replace a complete manual FPS playthrough. Headless mode loads sound resources but skips playback to avoid dummy-audio shutdown leaks. Visible rendering ran on the Compatibility renderer with AMD Radeon graphics. Original WAV structure was checked; no subjective audio listening review was performed.

An initial sandboxed run encountered host certificate/cache access errors; the engine was subsequently run with appropriate host access. These were environment restrictions, not missing project resources or GDScript errors.

3D editor update: apartment baked as 208 owned world objects in scenes/apartment.tscn. Main scene instances it with editable children. Editor import, nine interaction-ray probes and the full gameplay smoke test passed after baking. Path checker now reports 13 static/dynamic resources. No GUI editor inspection was performed for this update.
