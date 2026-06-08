## touch_dpad.gd
## D-Pad virtual para controles touch no Android.
## Envia direção para o PlayerController2D.

extends CanvasLayer

const BTN_SIZE := Vector2(120, 120)

@onready var _btn_up:    Button = $DPad/BtnUp
@onready var _btn_down:  Button = $DPad/BtnDown
@onready var _btn_left:  Button = $DPad/BtnLeft
@onready var _btn_right: Button = $DPad/BtnRight
@onready var _btn_a:     Button = $ActionButtons/BtnA
@onready var _btn_b:     Button = $ActionButtons/BtnB
@onready var _btn_start: Button = $ActionButtons/BtnStart

var _held_dirs: Dictionary = {
	"up": false, "down": false, "left": false, "right": false
}
var _player: CharacterBody2D = null

func _ready() -> void:
	# Conecta pressed/released para cada direção
	_connect_dir_button(_btn_up,    "up",    Vector2.UP)
	_connect_dir_button(_btn_down,  "down",  Vector2.DOWN)
	_connect_dir_button(_btn_left,  "left",  Vector2.LEFT)
	_connect_dir_button(_btn_right, "right", Vector2.RIGHT)

	_btn_a.pressed.connect(_on_a_pressed)
	_btn_b.pressed.connect(_on_b_pressed)
	_btn_start.pressed.connect(_on_start_pressed)

	# Tamanhos mínimos touch-friendly
	for btn in [_btn_up, _btn_down, _btn_left, _btn_right]:
		btn.custom_minimum_size = BTN_SIZE
	_btn_a.custom_minimum_size     = Vector2(140, 140)
	_btn_b.custom_minimum_size     = Vector2(110, 110)
	_btn_start.custom_minimum_size = Vector2(90, 90)

	# Feedback tátil/visual. Direcionais sem clique (o passo já dá o áudio);
	# botões de ação com clique.
	for btn in [_btn_up, _btn_down, _btn_left, _btn_right]:
		Juice.button_feedback(btn, false)
	for btn in [_btn_a, _btn_b, _btn_start]:
		Juice.button_feedback(btn, true)

	_add_phone_button()
	_add_tap_catcher()
	# Relabel: A = bicicleta, START = mochila/inventário (pausa).
	_btn_a.text = "🚲"
	_btn_start.text = "🎒"
	# Visual mais polido nos botões.
	for btn in [_btn_up, _btn_down, _btn_left, _btn_right]:
		_style_button(btn, Color(0.85, 0.85, 0.9), 16)
	_style_button(_btn_a, Color(0.45, 0.9, 0.55), 999)   # círculo verde (bike)
	_style_button(_btn_b, Color(0.95, 0.5, 0.5), 999)    # círculo vermelho
	_style_button(_btn_start, Color(0.96, 0.78, 0.3), 20)
	call_deferred("_find_player")

## Estiliza um botão de controle (fundo translúcido arredondado + borda do acento).
func _style_button(btn: Button, accent: Color, radius: int) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.10, 0.14, 0.78)
	normal.set_corner_radius_all(radius)
	normal.set_border_width_all(3)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 6
	var pressed := normal.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.35)
	pressed.border_color = accent
	for s in ["normal", "hover", "focus"]:
		btn.add_theme_stylebox_override(s, normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

## Toca na área do mapa = interagir (NPC/loja/porta) ou avançar diálogo.
func _add_tap_catcher() -> void:
	var tap := Control.new()
	tap.name = "TapCatch"
	tap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tap.offset_top = 130
	tap.offset_bottom = 1180
	tap.mouse_filter = Control.MOUSE_FILTER_STOP
	tap.gui_input.connect(_on_tap_input)
	add_child(tap)
	move_child(tap, 0)   # atrás dos botões (não rouba o toque deles)

func _on_tap_input(ev: InputEvent) -> void:
	if (ev is InputEventScreenTouch or ev is InputEventMouseButton) and not ev.pressed:
		_do_interact()

## Interage com o interagível mais próximo do player (ou avança diálogo).
func _do_interact() -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	if not is_instance_valid(_player):
		_find_player()
		if not is_instance_valid(_player):
			return
	var best: Node = null
	var best_d := 130.0
	for grp in ["npc", "building", "campsite", "exit_door"]:
		for n in get_tree().get_nodes_in_group(grp):
			if n.has_method("on_interact"):
				var d: float = n.global_position.distance_to(_player.global_position)
				if d < best_d:
					best_d = d
					best = n
	if best:
		best.on_interact(_player)
	else:
		_player.press_action()

## Botão 📱 (canto superior direito) — abre o celular (notificações + mapa).
func _add_phone_button() -> void:
	var phone := Button.new()
	phone.text = "📱"
	phone.add_theme_font_size_override("font_size", 44)
	phone.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	phone.offset_left = -116
	phone.offset_top = 12
	phone.offset_right = -16
	phone.offset_bottom = 104
	phone.pressed.connect(_on_phone)
	add_child(phone)
	_style_button(phone, Color(0.55, 0.8, 1.0), 18)
	Juice.button_feedback(phone, true)

func _on_phone() -> void:
	if Phone.is_available():
		Phone.open()
	else:
		DialogueManager.start(["📱❌  Seu celular foi roubado. Recupere-o mais à frente."])

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0]

func _connect_dir_button(btn: Button, key: String, dir: Vector2) -> void:
	btn.button_down.connect(func():
		_held_dirs[key] = true
		_update_player_dir()
	)
	btn.button_up.connect(func():
		_held_dirs[key] = false
		_update_player_dir()
	)

func _update_player_dir() -> void:
	if not is_instance_valid(_player):
		_find_player()
		if not is_instance_valid(_player):
			return
	var dir := Vector2.ZERO
	if _held_dirs["up"]:    dir += Vector2.UP
	if _held_dirs["down"]:  dir += Vector2.DOWN
	if _held_dirs["left"]:  dir += Vector2.LEFT
	if _held_dirs["right"]: dir += Vector2.RIGHT
	if dir.length() > 0:
		dir = dir.normalized()
	_player.set_move_direction(dir)

func _on_a_pressed() -> void:
	# A = 🚲 monta/desmonta a bicicleta (ou avança diálogo se ativo).
	if DialogueManager.is_active():
		DialogueManager.advance()
		return
	if is_instance_valid(_player) and _player.has_method("toggle_bike"):
		_player.toggle_bike()

func _on_b_pressed() -> void:
	# B = interagir/confirmar (NPC/loja/porta) ou fechar UI aberta.
	var scene := get_tree().current_scene
	if scene:
		for n in ["PhoneUI", "ShopUI", "InventoryUI"]:
			var ui := scene.get_node_or_null(n)
			if ui and ui.has_method("_close"):
				ui._close()
				return
	_do_interact()

func _on_start_pressed() -> void:
	# 🎒 abre a mochila/inventário (também serve de menu de pausa).
	if DialogueManager.is_active():
		return
	var scene := get_tree().current_scene
	if scene and scene.get_node_or_null("InventoryUI") == null:
		var ui := CanvasLayer.new()
		ui.name = "InventoryUI"
		ui.set_script(load("res://scripts/ui/inventory_ui.gd"))
		scene.add_child(ui)
