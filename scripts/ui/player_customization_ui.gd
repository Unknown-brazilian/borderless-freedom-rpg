## player_customization_ui.gd
## Tela de customização com campo de nome. UI construída em código.

extends CanvasLayer

var _name_input: LineEdit
var _lbl_skin:   Label
var _lbl_cap:    Label
var _lbl_moc:    Label
var _lbl_bike:   Label
var _lbl_bonus:  Label
var _preview:    TextureRect
var _btn_confirmar: Button

func _ready() -> void:
	AutonomyBar.set_active(false)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left   = 40.0
	scroll.offset_right  = -40.0
	scroll.offset_top    = 40.0
	scroll.offset_bottom = -40.0
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Título
	var title := Label.new()
	title.text = "Nova Jornada"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.969, 0.576, 0.102))
	vbox.add_child(title)

	# ── Campo de nome ─────────────────────────────────────────────────────────
	var name_section := _make_section("Seu nome de dissidente:", vbox)
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Digite seu nome..."
	_name_input.text = PlayerStats.player_name if PlayerStats.player_name != "Dissidente" else ""
	_name_input.custom_minimum_size = Vector2(0, 80)
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # ocupa a largura toda
	_name_input.add_theme_font_size_override("font_size", 36)
	_name_input.text_changed.connect(func(t: String):
		var nome := t.strip_edges()
		PlayerStats.player_name = nome if nome != "" else "Dissidente"
		_validate_name()
	)
	name_section.add_child(_name_input)

	# ── Preview do player ─────────────────────────────────────────────────────
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(192, 192)
	_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.layout_mode = 2
	var _center := CenterContainer.new()
	_center.layout_mode = 2
	_center.add_child(_preview)
	vbox.add_child(_center)
	_load_preview_sprite()

	# ── Skin ──────────────────────────────────────────────────────────────────
	var skin_row := _make_section("Aparência:", vbox)
	_lbl_skin = _make_hrow(skin_row,
		func(): PlayerCustomization.cycle_skin(-1); _refresh(),
		func(): PlayerCustomization.cycle_skin(1);  _refresh()
	)

	# ── Capacete ──────────────────────────────────────────────────────────────
	var cap_row := _make_section("Capacete:", vbox)
	_lbl_cap = _make_hrow(cap_row,
		func(): PlayerCustomization.cycle_capacete(-1); _refresh(),
		func(): PlayerCustomization.cycle_capacete(1);  _refresh()
	)

	# ── Mochila ───────────────────────────────────────────────────────────────
	var moc_row := _make_section("Mochila:", vbox)
	_lbl_moc = _make_hrow(moc_row,
		func(): PlayerCustomization.cycle_mochila(-1); _refresh(),
		func(): PlayerCustomization.cycle_mochila(1);  _refresh()
	)

	# ── Bike ──────────────────────────────────────────────────────────────────
	var bike_row := _make_section("Bike:", vbox)
	_lbl_bike = _make_hrow(bike_row,
		func(): PlayerCustomization.cycle_bike(-1); _refresh(),
		func(): PlayerCustomization.cycle_bike(1);  _refresh()
	)

	# ── Bônus ─────────────────────────────────────────────────────────────────
	_lbl_bonus = Label.new()
	_lbl_bonus.add_theme_font_size_override("font_size", 28)
	_lbl_bonus.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	_lbl_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD
	_lbl_bonus.layout_mode = 2
	vbox.add_child(_lbl_bonus)

	# ── Botões ────────────────────────────────────────────────────────────────
	_btn_confirmar = Button.new()
	_btn_confirmar.text = "Confirmar →"
	_btn_confirmar.custom_minimum_size = Vector2(0, 88)
	_btn_confirmar.add_theme_font_size_override("font_size", 36)
	_btn_confirmar.add_theme_color_override("font_color", Color(0.969, 0.576, 0.102))
	_btn_confirmar.pressed.connect(_on_confirmar)
	_btn_confirmar.layout_mode = 2
	vbox.add_child(_btn_confirmar)
	_validate_name()   # estado inicial (desabilitado se sem nome)

	var btn_voltar := Button.new()
	btn_voltar.text = "← Voltar"
	btn_voltar.custom_minimum_size = Vector2(0, 72)
	btn_voltar.add_theme_font_size_override("font_size", 28)
	btn_voltar.pressed.connect(_on_voltar)
	btn_voltar.layout_mode = 2
	vbox.add_child(btn_voltar)

func _make_section(label_text: String, parent: Control) -> HBoxContainer:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	lbl.layout_mode = 2
	parent.add_child(lbl)
	var row := HBoxContainer.new()
	row.layout_mode = 2
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	return row

func _make_hrow(row: HBoxContainer, on_left: Callable, on_right: Callable) -> Label:
	var btn_l := Button.new()
	btn_l.text = "◀"
	btn_l.custom_minimum_size = Vector2(80, 72)
	btn_l.add_theme_font_size_override("font_size", 32)
	btn_l.pressed.connect(on_left)
	row.add_child(btn_l)

	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.layout_mode = 2
	row.add_child(lbl)

	var btn_r := Button.new()
	btn_r.text = "▶"
	btn_r.custom_minimum_size = Vector2(80, 72)
	btn_r.add_theme_font_size_override("font_size", 32)
	btn_r.pressed.connect(on_right)
	row.add_child(btn_r)
	return lbl

func _load_preview_sprite() -> void:
	var p := "res://assets/sprites/player.png"
	if ResourceLoader.exists(p):
		_preview.texture = load(p)
		_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel-art nítido

func _refresh() -> void:
	# Reflete a skin escolhida no preview (tinta).
	if _preview:
		_preview.modulate = PlayerCustomization.SKINS[PlayerCustomization.skin_index]["cor"]
	if _lbl_skin:  _lbl_skin.text  = PlayerCustomization.get_skin_name()
	if _lbl_cap:   _lbl_cap.text   = PlayerCustomization.get_capacete_name()
	if _lbl_moc:   _lbl_moc.text   = PlayerCustomization.get_mochila_name()
	if _lbl_bike:  _lbl_bike.text  = PlayerCustomization.get_bike_name()

	var cap: Dictionary     = PlayerCustomization.CAPACETES[PlayerCustomization.capacete_index]
	var mochila: Dictionary = PlayerCustomization.MOCHILAS[PlayerCustomization.mochila_index]
	var bike: Dictionary    = PlayerCustomization.BIKES[PlayerCustomization.bike_index]

	var parts: Array[String] = []
	if cap.get("energy_bonus", 0.0) > 0.0:
		parts.append("-%d%% energia" % int(cap["energy_bonus"] / 40.0 * 100.0))
	if mochila.get("water_bonus", 0.0) > 0.0:
		parts.append("-%d%% água" % int(mochila["water_bonus"] / 60.0 * 100.0))
	if bike.get("speed_bonus", 0.0) > 0.0:
		parts.append("+%.1f vel" % bike["speed_bonus"])
	if _lbl_bonus:
		_lbl_bonus.text = "Bônus: " + (", ".join(parts) if parts.size() > 0 else "nenhum")

## Exige um nome antes de começar: desabilita o Confirmar se estiver vazio.
func _validate_name() -> void:
	if not is_instance_valid(_btn_confirmar):
		return
	var ok := _name_input.text.strip_edges() != ""
	_btn_confirmar.disabled = not ok
	_btn_confirmar.text = "Confirmar →" if ok else "Digite um nome para começar"

func _on_confirmar() -> void:
	if _name_input.text.strip_edges() == "":
		return   # trava: não dá pra começar sem nome
	PlayerCustomization.save_customization()
	# Gerar seed ANTES de mostrar a tela de seed
	SeedPhraseSystem.generate_seed()
	SceneTransition.go("res://scenes/ui/SeedPhraseScreen.tscn")

func _on_voltar() -> void:
	SceneTransition.go("res://scenes/ui/main_menu.tscn")
