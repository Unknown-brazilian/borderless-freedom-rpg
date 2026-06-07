## main_menu_rpg.gd
## Menu principal do RPG — Nova Jornada, Continuar, Créditos.

extends CanvasLayer

@onready var _btn_nova:     Button = $Panel/VBox/BtnNova
@onready var _btn_continuar:Button = $Panel/VBox/BtnContinuar
@onready var _btn_creditos: Button = $Panel/VBox/BtnCreditos
@onready var _lbl_title:    Label  = $Panel/LabelTitle
@onready var _lbl_sub:      Label  = $Panel/LabelSub
@onready var _confirm_panel: Control = $ConfirmPanel
@onready var _btn_confirm_yes: Button = $ConfirmPanel/VBox/BtnYes
@onready var _btn_confirm_no:  Button = $ConfirmPanel/VBox/BtnNo

func _ready() -> void:
	AutonomyBar.set_active(false)
	AudioManager.music("menu")

	_btn_nova.pressed.connect(_on_nova_jornada)
	_btn_continuar.pressed.connect(_on_continuar)
	_btn_creditos.pressed.connect(_on_creditos)
	_btn_confirm_yes.pressed.connect(_confirm_new_game)
	_btn_confirm_no.pressed.connect(func(): _confirm_panel.hide())
	_confirm_panel.hide()

	_btn_continuar.disabled = not SaveSystem.has_save()
	_lbl_title.text = "BORDERLESS FREEDOM"
	_lbl_sub.text   = "A Dissident Adventure — RPG"

	# Feedback de toque (clique + escala + vibração) em todos os botões.
	for b in [_btn_nova, _btn_continuar, _btn_creditos, _btn_confirm_yes, _btn_confirm_no]:
		Juice.button_feedback(b)
	_style_menu()
	_play_intro()

# ─── Tema visual do menu (gradiente + botões + contorno + rodapé) ─────────────
const ORANGE := Color(0.969, 0.576, 0.102)

func _style_menu() -> void:
	# Fundo procedural animado via shader (gradiente + brilho + grão + vinheta).
	var bg2 := ColorRect.new()
	var bg_mat := ShaderMaterial.new()
	bg_mat.shader = load("res://assets/shaders/menu_bg.gdshader")
	bg2.material      = bg_mat
	bg2.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg2.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(bg2)
	move_child(bg2, 1)   # acima do BG sólido, abaixo do Panel

	# Título com contorno + leve sombra (mais "logo").
	_lbl_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_lbl_title.add_theme_constant_override("outline_size", 10)

	# Botões estilizados.
	_style_button(_btn_nova, ORANGE)
	_style_button(_btn_continuar, Color(0.45, 0.55, 0.75))
	_style_button(_btn_creditos, Color(0.45, 0.45, 0.5))
	_style_button(_btn_confirm_yes, Color(0.85, 0.3, 0.25))
	_style_button(_btn_confirm_no, Color(0.45, 0.45, 0.5))

	# Rodapé com versão.
	var ver: String = ProjectSettings.get_setting("application/config/version", "")
	var footer := Label.new()
	footer.text = "v%s   ·   ⚡ bitfood.app" % ver
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 24)
	footer.add_theme_color_override("font_color", Color(0.5, 0.5, 0.56))
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top    = -64
	footer.offset_bottom = -24
	footer.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(footer)

	# Sobreposição CRT (scanlines) por cima de tudo.
	var scan := ColorRect.new()
	var scan_mat := ShaderMaterial.new()
	scan_mat.shader = load("res://assets/shaders/scanlines.gdshader")
	scan.material      = scan_mat
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(scan)   # último filho = topo

func _style_button(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.11, 0.11, 0.14, 0.95)
	normal.set_corner_radius_all(16)
	normal.border_width_left = 7
	normal.border_color = accent
	normal.set_content_margin_all(16)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.17, 0.17, 0.21, 0.98)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.20, 0.14, 0.05, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.07, 0.07, 0.09, 0.9)
	disabled.border_color = Color(0.3, 0.3, 0.34)
	btn.add_theme_stylebox_override("disabled", disabled)

	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.4))

## Entrada animada: título dá pop, subtítulo e botões entram em cascata;
## depois o título ganha um pulso sutil de "respiração".
func _play_intro() -> void:
	var btns := [_btn_nova, _btn_continuar, _btn_creditos]
	_lbl_title.modulate.a = 0.0
	_lbl_sub.modulate.a   = 0.0
	for b in btns:
		b.modulate.a = 0.0
	await get_tree().process_frame   # aguarda o layout para pivôs corretos

	_lbl_title.pivot_offset = _lbl_title.size * 0.5
	_lbl_title.scale = Vector2(1.15, 1.15)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_lbl_title, "modulate:a", 1.0, 0.4)
	t.tween_property(_lbl_title, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_lbl_sub, "modulate:a", 1.0, 0.4).set_delay(0.2)
	for i in btns.size():
		t.tween_property(btns[i], "modulate:a", 1.0, 0.3).set_delay(0.35 + i * 0.1)

	await get_tree().create_timer(1.1).timeout
	var pulse := create_tween().set_loops()
	pulse.tween_property(_lbl_title, "scale", Vector2(1.03, 1.03), 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_lbl_title, "scale", Vector2.ONE, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_nova_jornada() -> void:
	if SaveSystem.has_save():
		_confirm_panel.pivot_offset = _confirm_panel.size * 0.5
		_confirm_panel.show()
		Juice.pop(_confirm_panel, 1.08, 0.25)
	else:
		_start_new_game()

func _confirm_new_game() -> void:
	_confirm_panel.hide()
	_start_new_game()

func _start_new_game() -> void:
	SaveSystem.delete_save()
	SatEconomy.current_sats    = 0
	SatEconomy.lifetime_earned = 0
	SatEconomy.lifetime_lost   = 0
	PlayerStats.reset()
	PlayerInventory.reset()
	AutonomyBar.refill_all()
	GameStats.reset()
	RandomEventsSystem.reset()
	SaveSystem.reset_store()
	WorldManager.current_dungeon   = 1
	WorldManager.sequence_index    = 0
	WorldManager.bosses_defeated_in_dungeon = 0
	WorldManager.dungeon_flags = {}
	SceneTransition.go("res://scenes/ui/PlayerCustomization.tscn")

func _on_continuar() -> void:
	if SaveSystem.load_game():
		var idx: int = WorldManager.sequence_index
		if idx < WorldManager.SCENE_SEQUENCE.size():
			var scene: String = WorldManager.SCENE_SEQUENCE[idx].get("scene", "")
			if not scene.is_empty():
				SceneTransition.go(scene)

func _on_creditos() -> void:
	SceneTransition.go("res://scenes/ui/Credits.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pass
