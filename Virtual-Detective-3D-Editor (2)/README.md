# Virtual Detective – Crime Scene VR

**The Silent Audit** — an original, complete desktop investigation with an OpenXR-ready rig. Built and checked with **Godot 4.5.2 Standard** (GDScript, no .NET needed). No add-ons, downloads, external models, textures, or sampled audio are required. The environment is a stylized primitive apartment, not photorealistic. The supplied prompt had no accessible reference image; its dark blue forensic art direction is used.

## Import and run

1. Extract the entire ZIP to a writable folder. Do not open it inside the ZIP viewer.
2. Open Godot 4.5.2 or a compatible newer Godot 4 Standard editor.
3. In Project Manager choose **Import**, browse to `Virtual Detective - Crime Scene VR/project.godot`, and choose **Import & Edit**.
4. Let Godot finish importing the nine WAV files. Press **F6** for the open main scene or **F5** to run the project. If no scene is open, use F5.
5. Choose **START / ENTER CRIME SCENE**, read the briefing, then choose **BEGIN INVESTIGATION**.

No export templates are needed to play in the editor. Use a desktop with OpenGL 3.3 support. The project uses the Compatibility renderer. The ZIP is an editable project, not a standalone executable.

## Controls

| Input | Action |
|---|---|
| W A S D | Walk |
| Mouse | Look |
| Shift | Move faster |
| E | Inspect/use the object at the crosshair, within 3.4 metres |
| F | Toggle flashlight |
| Tab | Case file, exhibit review, interviews, final accusation |
| B | Evidence board |
| Right mouse drag | Rotate the object preview during inspection |
| Escape | Pause/resume or close a panel |
| Left click / mouse wheel | Panel controls / scroll long panels |

The cursor is released while reading panels. Closing a panel recaptures it. There is no jump requirement. Pause includes a master volume slider. **Restart/New Investigation resets everything; this short case has no disk save.**

## Investigation

Search the living room and desk. Clues are filed only when you press **COLLECT** after examining them. Physical evidence remains at the scene for review; the key is picked up and removed. Use the brass key on the locked drawer. Its original ledger authorizes the service alcove and gives the CCTV override. Interact with the alcove door to open the new area; the terminal is inside.

The phone contains five original messages. CCTV is a deliberately stylized, animated reconstruction with scanlines and original static; its transcript contains all relevant observations. It cannot identify a face. The secure radio near the entrance and the case file both provide the same interviews.

On the board, select two collected exhibits. Supported links are recorded as lines and explanations; an unsupported link gives feedback. Link evidence to unlock suspect challenges. Suspicion percentages are normalized narrative weights, not probabilities or a substitute for evidence. Collect all eight exhibits, establish at least three supported links, and challenge all three suspects before submitting an accusation. Choose a suspect and exactly three exhibits. An incorrect answer preserves progress so you can reconsider; a correct answer resolves the case.

The optional `WALKTHROUGH_SPOILERS.md` gives the complete route and solution.

## OpenXR architecture and limits

Desktop is enabled by default to avoid requiring a headset. The main script constructs a separate `XROrigin3D`, `XRCamera3D`, left/right `XRController3D` nodes, and a visible right-hand `RayCast3D`. Both desktop and XR rays call the same interaction dispatcher. The rig follows the collision-aware desktop body for movement.

To experiment with PC VR:

1. Connect a PC OpenXR headset and start its vendor runtime. Set that runtime as the active OpenXR runtime.
2. In Godot **Project > Project Settings**, enable **Advanced Settings**, then **XR > OpenXR > Enabled**. Restart the running project after changing it.
3. On the main menu choose **OPENXR STATUS / SETUP**, then **ACTIVATE OPENXR**. Return to the menu and start the investigation.
4. Godot's default OpenXR action map supplies `trigger_click`; the right trigger interacts with the pointed-at world object.

**This is VR-ready architecture, not a headset-only game.** Menus, inspection and case-file UI are 2D desktop mirror panels operated with a mouse. Movement currently uses WASD. There is no controller locomotion, teleport, hand-grab physics, or in-headset panel input. No headset was available for hardware validation. Standalone Quest/Android packaging and controller-specific bindings are not supplied. For desktop again, restart with OpenXR disabled. These boundaries are also stated in the in-game setup panel.

## Project layout

- `project.godot` — entry point, viewport, renderer, default XR settings.
- `scenes/main.tscn` — game root with an editable apartment instance.
- `scripts/main.gd` — generated world, collision, desktop/XR rig, UI, interaction, progression, audio and test entry points.
- `scripts/case_data.gd` — original clue text, suspect accounts and supported connections.
- `audio/*.wav` — nine deterministic original synthesized mono PCM sounds, 22,050 Hz / 16 bit.
- `tests/VALIDATION.md` — checks performed and limitations.
- `tests/check_paths.mjs` — optional Node.js source/audio integrity checker.

Apartment meshes, materials, lights and collisions are saved in `scenes/apartment.tscn` and can be edited in the 3D editor. Evidence previews, CCTV graphics and interface elements are generated by code. Nothing is fetched at runtime. Audio comprises room tone, distant police siren ambience, CCTV hum/static, UI click, evidence discovery, drawer/key, phone notification, wrong-answer and solved cues. There is no copyrighted external asset content. Narrative, silhouettes, geometry and sounds were made for this project. Godot itself is obtained separately under its own license.

## Reproduce the checks

From a terminal, replace `godot` with your Godot executable path, and the project argument with the extracted project directory:

```text
godot --headless --path "Virtual Detective - Crime Scene VR" --editor --import --quit
godot --headless --path "Virtual Detective - Crime Scene VR" -- --smoke-test
node "Virtual Detective - Crime Scene VR/tests/check_paths.mjs"
```

The smoke test exercises the real state and panel functions: locked drawer/alcove, eight clues, all four links, interview challenge prerequisites, accusation gate, accepted/rejected evidence and both ending panels. It exits after printing `SMOKE PASS`. These checks are not a substitute for manual controls or headset testing.

Optional render check (opens a window):

```text
godot --path "Virtual Detective - Crime Scene VR" -- --visual-test
```

It captures menu, apartment, inspection and board PNGs into `tests/` then exits. Generated screenshots are not runtime dependencies.

If imports fail, make sure you extracted every file and the destination is writable. Godot generates its `.godot` import cache locally. If movement seems unresponsive, close the active panel or press Escape. Open `scenes/apartment.tscn` to edit the complete apartment in the 3D editor. See `OPEN-3D-EDITOR.md` for simple steps.

