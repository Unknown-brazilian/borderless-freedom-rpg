## building.gd — casinha na overworld (estilo Pokémon). Interaja (A) na porta
## para ENTRAR no interior. Guarda o ponto de retorno.
extends StaticBody2D

@export var interior_scene: String = ""
@export var building_name: String = "Loja"
@export var body_color: Color = Color(0.55, 0.42, 0.30)
@export var roof_color: Color = Color(0.45, 0.20, 0.18)

func _ready() -> void:
	add_to_group("building")
	set_collision_layer_value(3, true)   # player bate pra interagir
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(168, 150)
	shape.shape = rect
	shape.position = Vector2(0, -56)
	add_child(shape)

	# Corpo (casa maior)
	var body := ColorRect.new()
	body.size = Vector2(168, 120)
	body.position = Vector2(-84, -120)
	body.color = body_color
	add_child(body)
	# Telhado
	var roof := ColorRect.new()
	roof.size = Vector2(192, 44)
	roof.position = Vector2(-96, -156)
	roof.color = roof_color
	add_child(roof)
	# Porta
	var door := ColorRect.new()
	door.size = Vector2(56, 72)
	door.position = Vector2(-28, -72)
	door.color = Color(0.18, 0.12, 0.08)
	add_child(door)
	# Placa
	var lbl := Label.new()
	lbl.text = building_name
	lbl.position = Vector2(-96, -188)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	add_child(lbl)

func on_interact(player: Node) -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	if interior_scene == "" or not ResourceLoader.exists(interior_scene):
		return
	WorldManager.pending_return_scene = get_tree().current_scene.scene_file_path
	if player and player.has_method("get_tile_position"):
		WorldManager.pending_return_tile = player.get_tile_position()
	AudioManager.sfx("door")
	SceneTransition.go(interior_scene)
