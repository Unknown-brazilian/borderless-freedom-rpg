## job_npc.gd — balcão de empregos; interaja (A) para fazer um bico (minigame)
## e ganhar sats. Reaproveita os minigames existentes.
extends StaticBody2D

@export var minigame_scene: String = "res://scenes/minigames/LimpezaMinigame.tscn"
@export var job_name: String = "Emprego: Limpeza de Hostel"

func _ready() -> void:
	add_to_group("npc")
	set_collision_layer_value(3, true)
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 44)
	shape.shape = rect
	add_child(shape)
	var p := "res://assets/sprites/npc_neutral.png"
	if ResourceLoader.exists(p):
		var spr := Sprite2D.new()
		spr.texture = load(p)
		spr.scale = Vector2(2, 2)
		spr.position = Vector2(0, -22)
		spr.modulate = Color(0.8, 0.7, 0.4)
		add_child(spr)
	var lbl := Label.new()
	lbl.text = "💼 Empregos"
	lbl.position = Vector2(-44, -56)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	add_child(lbl)

func on_interact(_player: Node) -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	if not ResourceLoader.exists(minigame_scene):
		return
	var mg = load(minigame_scene).instantiate()
	if mg.has_signal("minigame_completed"):
		mg.minigame_completed.connect(func(sats: int):
			if sats > 0:
				SatEconomy.add_sats(sats, "emprego")
		)
	get_tree().current_scene.add_child(mg)
