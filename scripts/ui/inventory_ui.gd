## inventory_ui.gd — mochila + pausa. Lista os itens, permite acampar (descansar
## e salvar com a barraca) e voltar ao menu. Abre pelo botão 🎒. time_scale=0.
extends CanvasLayer

const GOLD := Color(0.96, 0.69, 0.13)
const CARD := Color(0.13, 0.13, 0.17)

func _ready() -> void:
	add_to_group("pauses_game")
	layer = 68
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 0.0
	_build()

func _sb(c: Color, r := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(14)
	return sb

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 50; vb.offset_right = -50; vb.offset_top = 60; vb.offset_bottom = -60
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)

	var head := HBoxContainer.new()
	vb.add_child(head)
	var title := Label.new()
	title.text = "🎒 Mochila"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var x := Button.new()
	x.text = "✕"; x.add_theme_font_size_override("font_size", 34)
	x.pressed.connect(_close); Juice.button_feedback(x)
	head.add_child(x)

	# Lista de itens
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	if PlayerInventory.unlocked.is_empty():
		var e := Label.new(); e.text = "Mochila vazia."
		e.add_theme_color_override("font_color", Color(0.6,0.6,0.6)); list.add_child(e)
	for item_id in PlayerInventory.unlocked:
		var d: Dictionary = PlayerInventory.ITEM_DEFS.get(item_id, {})
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _sb(CARD))
		var hb := HBoxContainer.new(); row.add_child(hb)
		var nm := Label.new()
		nm.text = "%s  %s" % [d.get("icon", "•"), d.get("name", item_id)]
		nm.add_theme_font_size_override("font_size", 28)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nm)
		var ds := Label.new()
		ds.text = d.get("desc", "")
		ds.add_theme_font_size_override("font_size", 20)
		ds.add_theme_color_override("font_color", Color(0.65,0.65,0.65))
		hb.add_child(ds)
		list.add_child(row)

	# Acampar (barraca)
	if "item_barraca" in PlayerInventory.unlocked:
		var camp := Button.new()
		camp.text = "⛺  Acampar (descansar e salvar)"
		camp.custom_minimum_size = Vector2(0, 84)
		camp.add_theme_font_size_override("font_size", 28)
		camp.add_theme_stylebox_override("normal", _sb(Color(0.18,0.32,0.2)))
		camp.pressed.connect(_camp); Juice.button_feedback(camp)
		vb.add_child(camp)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 20)
	vb.add_child(btns)
	var resume := Button.new()
	resume.text = "Continuar"; resume.custom_minimum_size = Vector2(0, 84)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.add_theme_font_size_override("font_size", 28)
	resume.pressed.connect(_close); Juice.button_feedback(resume)
	btns.add_child(resume)
	var menu := Button.new()
	menu.text = "Menu principal"; menu.custom_minimum_size = Vector2(0, 84)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_theme_font_size_override("font_size", 28)
	menu.pressed.connect(_to_menu); Juice.button_feedback(menu)
	btns.add_child(menu)

func _camp() -> void:
	AutonomyBar.refill_all()
	SaveSystem.save_game()
	AudioManager.sfx("upgrade")
	DialogueManager.start(["⛺  Você acampou. Recursos restaurados e jogo salvo."])
	_close()

func _to_menu() -> void:
	SaveSystem.save_game()
	Engine.time_scale = 1.0
	SceneTransition.go("res://scenes/ui/main_menu.tscn")

func _close() -> void:
	Engine.time_scale = 1.0
	queue_free()
