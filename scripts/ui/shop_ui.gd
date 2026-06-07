## shop_ui.gd — loja simples: compre itens com sats.
extends CanvasLayer

const ORANGE := Color(0.969, 0.576, 0.102)
const STOCK := [
	{"id": "item_binoculo",      "name": "Binóculos",       "price": 120},
	{"id": "item_oculos_noturno","name": "Óculos Noturnos", "price": 200},
	{"id": "item_spray",         "name": "Spray Repelente", "price": 60},
	{"id": "item_camera",        "name": "Câmera",          "price": 90},
]

var _list: VBoxContainer
var _sats_lbl: Label

func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 0.0
	_build()

func _sb(c: Color, r: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(12)
	return sb

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _sb(Color(0.09, 0.09, 0.12), 20))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(820, 0)
	panel.offset_left = -410; panel.offset_right = 410
	panel.offset_top = -520
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var header := HBoxContainer.new()
	vb.add_child(header)
	var title := Label.new()
	title.text = "🛒  Loja"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ORANGE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.add_theme_font_size_override("font_size", 34)
	close.pressed.connect(_close)
	Juice.button_feedback(close)
	header.add_child(close)

	_sats_lbl = Label.new()
	_sats_lbl.add_theme_font_size_override("font_size", 28)
	_sats_lbl.add_theme_color_override("font_color", ORANGE)
	vb.add_child(_sats_lbl)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	vb.add_child(_list)
	_refresh()

func _refresh() -> void:
	_sats_lbl.text = "Seu saldo: ₿ %d sats" % SatEconomy.current_sats
	for c in _list.get_children():
		c.queue_free()
	for item in STOCK:
		var row := Button.new()
		row.custom_minimum_size = Vector2(0, 72)
		row.add_theme_font_size_override("font_size", 26)
		var owned: bool = item["id"] in PlayerInventory.unlocked
		if owned:
			row.text = "%s — comprado ✔" % item["name"]
			row.disabled = true
		else:
			row.text = "%s — %d sats" % [item["name"], item["price"]]
			row.disabled = SatEconomy.current_sats < item["price"]
			row.pressed.connect(_buy.bind(item))
		row.add_theme_stylebox_override("normal", _sb(Color(0.14, 0.14, 0.18)))
		Juice.button_feedback(row)
		_list.add_child(row)

func _buy(item: Dictionary) -> void:
	if SatEconomy.current_sats < item["price"] or item["id"] in PlayerInventory.unlocked:
		return
	SatEconomy.remove_sats(item["price"], "compra_loja")
	PlayerInventory.unlock_item(item["id"])
	AudioManager.sfx("coin")
	_refresh()

func _close() -> void:
	Engine.time_scale = 1.0
	queue_free()
