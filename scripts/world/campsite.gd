## campsite.gd — ponto de acampamento. Interaja (botão A) para descansar:
## restaura água/comida/energia e SALVA o jogo. Estilo "save point".
extends StaticBody2D

var _busy: bool = false

func _ready() -> void:
	add_to_group("campsite")
	set_collision_layer_value(3, true)   # camada npc (player bate pra interagir)
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(52, 52)
	shape.shape = rect
	add_child(shape)

	var tent := Label.new()
	tent.text = "⛺"
	tent.position = Vector2(-22, -34)
	tent.add_theme_font_size_override("font_size", 44)
	add_child(tent)

	var name_lbl := Label.new()
	name_lbl.text = "Acampamento"
	name_lbl.position = Vector2(-50, -60)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	add_child(name_lbl)

func on_interact(_player: Node) -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	if _busy:
		return
	_busy = true
	AutonomyBar.refill_all()
	SaveSystem.save_game()
	AudioManager.sfx("upgrade")
	DialogueManager.start([
		"⛺  Você montou acampamento e descansou.",
		"Água, comida e energia restauradas.",
		"💾  Jogo salvo.",
	])
	await DialogueManager.dialogue_finished
	_busy = false
