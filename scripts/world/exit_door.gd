## exit_door.gd — porta de saída do interior; volta para a overworld (na porta).
extends StaticBody2D

func _ready() -> void:
	add_to_group("exit_door")
	set_collision_layer_value(3, true)
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	shape.shape = rect
	add_child(shape)
	var door := ColorRect.new()
	door.size = Vector2(40, 44)
	door.position = Vector2(-20, -34)
	door.color = Color(0.18, 0.12, 0.08)
	add_child(door)
	var lbl := Label.new()
	lbl.text = "Sair"
	lbl.position = Vector2(-20, -56)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	add_child(lbl)

func on_interact(_player: Node) -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	AudioManager.sfx("door")
	var dest: String = WorldManager.pending_return_scene
	if dest == "" or not ResourceLoader.exists(dest):
		dest = "res://scenes/ui/main_menu.tscn"
	SceneTransition.go(dest)
