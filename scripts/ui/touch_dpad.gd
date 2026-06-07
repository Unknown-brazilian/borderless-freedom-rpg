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

	# Feedback tátil/visual em todos os botões.
	for btn in [_btn_up, _btn_down, _btn_left, _btn_right, _btn_a, _btn_b, _btn_start]:
		Juice.button_feedback(btn)

	call_deferred("_find_player")

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
	if not is_instance_valid(_player):
		return
	_player.press_action()

func _on_b_pressed() -> void:
	if DialogueManager.is_active():
		DialogueManager.advance()

func _on_start_pressed() -> void:
	# Abre menu de pausa
	var menus := get_tree().get_nodes_in_group("pause_menu")
	if not menus.is_empty():
		menus[0].toggle()
