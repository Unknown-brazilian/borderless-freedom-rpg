## shop_npc.gd — lojista; interaja (A) para abrir a loja (comprar itens com sats).
extends StaticBody2D

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
		spr.modulate = Color(0.5, 0.85, 0.6)
		add_child(spr)
	var lbl := Label.new()
	lbl.text = "🛒 Lojista"
	lbl.position = Vector2(-40, -56)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.6, 1, 0.7))
	add_child(lbl)

func on_interact(_player: Node) -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	if get_tree().current_scene.get_node_or_null("ShopUI") != null:
		return
	var ui := CanvasLayer.new()
	ui.name = "ShopUI"
	ui.set_script(load("res://scripts/ui/shop_ui.gd"))
	get_tree().current_scene.add_child(ui)
