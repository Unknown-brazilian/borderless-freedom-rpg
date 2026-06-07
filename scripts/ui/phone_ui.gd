## phone_ui.gd — tela do celular: Notificações (Wallet of Satoshi) + Jornada (mapa).
extends CanvasLayer

const ORANGE := Color(0.969, 0.576, 0.102)

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 0.0
	_build()

func _sb(c: Color, r: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(14)
	return sb

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(func(e):
		if e is InputEventScreenTouch and e.pressed: _close())
	add_child(bg)

	var phone := PanelContainer.new()
	phone.add_theme_stylebox_override("panel", _sb(Color(0.07, 0.07, 0.09), 28))
	phone.set_anchors_preset(Control.PRESET_CENTER)
	phone.custom_minimum_size = Vector2(760, 1280)
	phone.offset_left = -380; phone.offset_right = 380
	phone.offset_top = -640; phone.offset_bottom = 640
	add_child(phone)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	phone.add_child(vb)

	# Cabeçalho
	var header := HBoxContainer.new()
	vb.add_child(header)
	var title := Label.new()
	title.text = "📱  Celular"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ORANGE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.add_theme_font_size_override("font_size", 36)
	close.pressed.connect(_close)
	header.add_child(close)
	Juice.button_feedback(close)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 28)
	vb.add_child(tabs)

	tabs.add_child(_build_notifications())
	tabs.add_child(_build_journey())

func _build_notifications() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "⚡ Wallet of Satoshi"
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if Phone.notifications.is_empty():
		var empty := Label.new()
		empty.text = "Sem notificações ainda."
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list.add_child(empty)
	for n in Phone.notifications:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _sb(Color(0.12, 0.12, 0.15)))
		var cv := VBoxContainer.new()
		card.add_child(cv)
		var top := Label.new()
		var sats: int = n.get("sats", 0)
		top.text = "⚡ %s%s" % [n.get("from", "?"), ("   +%d sats" % sats) if sats > 0 else ""]
		top.add_theme_font_size_override("font_size", 26)
		top.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5) if sats > 0 else Color.WHITE)
		cv.add_child(top)
		var body := Label.new()
		body.text = n.get("msg", "")
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		body.add_theme_font_size_override("font_size", 24)
		body.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
		cv.add_child(body)
		list.add_child(card)
	return scroll

func _build_journey() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "🗺️ Jornada"
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var seq: Array = WorldManager.SCENE_SEQUENCE
	var cur: int = WorldManager.sequence_index
	for i in seq.size():
		var entry: Dictionary = seq[i]
		var status := "✅" if i < cur else ("▶" if i == cur else "🔒")
		var row := Label.new()
		var nome: String = entry.get("name", "???")
		row.text = "%s  %s" % [status, nome]
		row.add_theme_font_size_override("font_size", 28)
		var col := Color(0.55, 0.55, 0.55)
		if i == cur: col = ORANGE
		elif i < cur: col = Color(0.5, 0.85, 0.55)
		row.add_theme_color_override("font_color", col)
		list.add_child(row)
	return scroll

func _close() -> void:
	Engine.time_scale = 1.0
	queue_free()
