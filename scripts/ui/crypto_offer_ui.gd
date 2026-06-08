## crypto_offer_ui.gd
## UI de oferta cripto — design intencional de armadilha sem timeout.

extends CanvasLayer

signal offer_accepted(event_id: String)
signal offer_refused(event_id: String)

var _event_data: Dictionary = {}
var _event_name_lbl: Label
var _tagline_lbl:    Label
var _actor_lbl:      Label
var _pitch_lbl:      RichTextLabel
var _accept_btn:     Button
var _refuse_btn:     Button

func _ready() -> void:
	add_to_group("pauses_game")
	layer = 10
	_build_ui()
	hide()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -420.0
	panel.offset_top    = -500.0
	panel.offset_right  =  420.0
	panel.offset_bottom =  500.0
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	panel.add_child(vbox)

	_event_name_lbl = Label.new()
	_event_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_name_lbl.add_theme_font_size_override("font_size", 36)
	_event_name_lbl.add_theme_color_override("font_color", Color(0.969, 0.776, 0.102))
	vbox.add_child(_event_name_lbl)

	_tagline_lbl = Label.new()
	_tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_lbl.add_theme_font_size_override("font_size", 24)
	_tagline_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_tagline_lbl)

	_actor_lbl = Label.new()
	_actor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_actor_lbl.add_theme_font_size_override("font_size", 20)
	_actor_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_actor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_actor_lbl)

	_pitch_lbl = RichTextLabel.new()
	_pitch_lbl.custom_minimum_size = Vector2(0, 200)
	_pitch_lbl.add_theme_font_size_override("normal_font_size", 26)
	_pitch_lbl.bbcode_enabled = true
	_pitch_lbl.fit_content = true
	vbox.add_child(_pitch_lbl)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 20)
	vbox.add_child(btns)

	_accept_btn = Button.new()
	_accept_btn.custom_minimum_size = Vector2(260, 72)
	_accept_btn.add_theme_font_size_override("font_size", 28)
	_accept_btn.pressed.connect(_on_accept)
	btns.add_child(_accept_btn)

	_refuse_btn = Button.new()
	_refuse_btn.custom_minimum_size = Vector2(220, 72)
	_refuse_btn.add_theme_font_size_override("font_size", 22)
	_refuse_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_refuse_btn.pressed.connect(_on_refuse)
	btns.add_child(_refuse_btn)

func show_offer(event_data: Dictionary) -> void:
	_event_data = event_data
	Engine.time_scale = 0.0
	AutonomyBar.set_active(false)
	_event_name_lbl.text = event_data.get("name", "Oportunidade")
	_tagline_lbl.text    = event_data.get("tagline", "")
	_actor_lbl.text      = "[ " + event_data.get("actor_description", "") + " ]"
	_pitch_lbl.text      = event_data.get("pitch", "")
	_accept_btn.text     = event_data.get("accept_button", "ACEITAR")
	_refuse_btn.text     = event_data.get("ignore_button", "Não, obrigado")
	show()

func _on_accept() -> void:
	hide()
	Engine.time_scale = 1.0
	AutonomyBar.set_active(true)
	emit_signal("offer_accepted", _event_data.get("id", ""))
	queue_free()

func _on_refuse() -> void:
	hide()
	Engine.time_scale = 1.0
	AutonomyBar.set_active(true)
	emit_signal("offer_refused", _event_data.get("id", ""))
	queue_free()

func _exit_tree() -> void:
	# Garantia: restaura estado mesmo se cena mudar com oferta aberta
	Engine.time_scale = 1.0
	AutonomyBar.set_active(true)
