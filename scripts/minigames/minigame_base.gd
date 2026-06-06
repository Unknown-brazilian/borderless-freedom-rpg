## minigame_base.gd
## Base para todos os mini-games do Saltillo.
## Pausa a cena de mundo enquanto roda. Emite minigame_completed ao terminar.

class_name MinigameBase
extends CanvasLayer

signal minigame_completed(sats_earned: int)

var _player_ref: Node = null

# ─── Paleta de cores padrão ──────────────────────────────────────────────────
const C_BG        := Color(0.06, 0.06, 0.10, 0.95)
const C_PANEL     := Color(0.12, 0.12, 0.18)
const C_HEADER    := Color(0.969, 0.776, 0.102)
const C_ACTIVE    := Color(1.0,  0.75, 0.1)
const C_SUCCESS   := Color(0.2,  0.8,  0.3)
const C_FAIL      := Color(0.9,  0.2,  0.2)
const C_NEUTRAL   := Color(0.30, 0.30, 0.40)
const C_PLAYER    := Color(0.969, 0.576, 0.102)
const C_TARGET    := Color(0.2,  0.7,  0.3,  0.8)
const C_OBSTACLE  := Color(0.35, 0.28, 0.22)
const C_DIRTY     := Color(0.25, 0.20, 0.15)
const C_CLEAN     := Color(0.55, 0.50, 0.45)
const C_DELIVERY  := Color(0.85, 0.25, 0.25)

func _ready() -> void:
	layer = 20
	BattleManager.locked = true
	AutonomyBar.set_active(false)
	_player_ref = get_tree().get_first_node_in_group("player")
	if is_instance_valid(_player_ref):
		_player_ref.set_can_move(false)

func _finish(sats: int) -> void:
	BattleManager.locked = false
	AutonomyBar.set_active(true)
	if is_instance_valid(_player_ref):
		_player_ref.set_can_move(true)
	emit_signal("minigame_completed", sats)
	queue_free()

# ─── UI helpers ──────────────────────────────────────────────────────────────

func make_bg() -> ColorRect:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	return bg

func make_header(title: String, parent: Control) -> Label:
	var lbl := Label.new()
	lbl.text = title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", C_HEADER)
	lbl.layout_mode = 2
	parent.add_child(lbl)
	return lbl

func make_label(text_str: String, size: int, color: Color, parent: Control) -> Label:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.layout_mode = 2
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(lbl)
	return lbl

func make_btn(text_str: String, size: int, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text_str
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", size)
	return btn

func make_dpad(parent: Control, on_dir: Callable) -> void:
	var dpad_size := Vector2(400, 400)
	var container := Control.new()
	container.custom_minimum_size = dpad_size
	container.layout_mode = 2
	parent.add_child(container)

	var dirs := [
		["▲", Vector2(140, 0),   Vector2.UP],
		["▼", Vector2(140, 260), Vector2.DOWN],
		["◀", Vector2(0,   130), Vector2.LEFT],
		["▶", Vector2(280, 130), Vector2.RIGHT],
	]
	for d in dirs:
		var btn := Button.new()
		btn.text    = d[0]
		btn.position = d[1]
		btn.size    = Vector2(120, 120)
		btn.add_theme_font_size_override("font_size", 52)
		var dir_val: Vector2 = d[2]
		btn.pressed.connect(func(): on_dir.call(dir_val))
		container.add_child(btn)

func _exit_tree() -> void:
	# Garante restauração de estado mesmo se a cena mudar enquanto mini-game roda
	if BattleManager.locked:
		BattleManager.locked = false
	AutonomyBar.set_active(true)
	if is_instance_valid(_player_ref) and _player_ref.has_method("set_can_move"):
		_player_ref.set_can_move(true)
