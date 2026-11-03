# Open the apartment in Godot's 3D editor

1. Import this folder's `project.godot` into Godot 4.5.2 or newer.
2. In the FileSystem panel, open **scenes/apartment.tscn** by double-clicking it.
3. Click **3D** at the top of Godot.
4. Expand **Apartment** in the Scene tree. Select **Desk**, **CouchBase**, **Notebook**, or another object, then press **F** to focus it.
5. Use the move, rotate and scale tools to edit the selected object. Meshes, materials, lights and collisions are included in the saved scene.
6. Press **Ctrl+S** to save, then **F5** to play the complete game.

There are 208 saved world objects, including furniture, window, curtains, city silhouettes, evidence, service door, terminal and lighting. Expand an object's node to select its mesh or collision shape. The main scene instances this apartment, so saved changes appear in the game automatically. The Apartment instance in the main scene also has editable children enabled.

Keep clue metadata intact and preserve the drawer and service-door bodies when editing: the game uses these to bind interactions. Moving clues changes their locations; the existing automated ray probes assume the delivered locations. The player, interface and OpenXR rig still initialize when you run the game. This update makes the environment editable; it does not add headset-only UI or character models.

Optional: `tests/bake_apartment.gd` regenerates the apartment from the original geometry code and will overwrite scene edits. It is not needed for normal editing.
