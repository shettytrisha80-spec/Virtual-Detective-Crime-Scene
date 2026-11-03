extends SceneTree
## Rebuild the editable apartment from the original deterministic geometry.
func _initialize() -> void:
 var generator = load("res://scripts/main.gd").new()
 generator.build_world()
 var apartment = Node3D.new()
 apartment.name = "Apartment"
 for child in generator.get_children():
  generator.remove_child(child)
  apartment.add_child(child, true)
  own_nodes(child, apartment)
 var packed = PackedScene.new()
 assert(packed.pack(apartment) == OK)
 assert(ResourceSaver.save(packed, "res://scenes/apartment.tscn") == OK)
 print("BAKE PASS: editable apartment saved with ", apartment.get_child_count(), " world objects")
 apartment.free()
 generator.free()
 quit()

func own_nodes(node: Node, scene_root: Node) -> void:
 node.owner = scene_root
 for child in node.get_children(): own_nodes(child, scene_root)
