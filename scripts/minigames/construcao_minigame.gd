## construcao_minigame.gd
## Mini-game: Obra de Construção na Bélgique
## Navegue até os montes de tijolo (🟥), carregue-os (A) até os slots da parede (⬜), coloque-os (A).
## 3 tijolos para posicionar. D-pad + botão A.

extends "res://scripts/minigames/minigame_base.gd"

const COLS        := 7
const ROWS        := 5
const CELL_SIZE   := 132
const BASE_REWARD := 40

# Células: 0=chão, 1=parede/muro, 2=pilha de tijolos, 3=slot vazio, 4=slot preenchido
const MAP_LAYOUT: Array = [
	[1,1,1,1,1,1,1],
	[1,3,0,0,0,3,1],
	[1,0,1,0,1,0,1],
	[1,0,0,0,0,0,1],
	[1,1,2,1,2,1,1],
]
# Terceiro tijolo no mapa (fora do layout fixo)
const EXTRA_PILE   := Vector2i(5, 3)
const PLAYER_START := Vector2i(3, 3)

var _map:        Array = []
var _player_pos: Vector2i = PLAYER_START
var _carrying:   bool = false
var _placed:     int  = 0
var _pile_cells: Array[Vector2i] = []
var _slot_cells: Array[Vector2i] = []

var _cell_rects:  Array = []
var _status_lbl:  Label
var _carry_lbl:   Label

func _ready() -> void:
	super._ready()
	_init_map()
	_build_ui()

func _init_map() -> void:
	_map = []
	for r in range(ROWS):
		var row: Array[int] = []
		for c in range(COLS):
			row.append(MAP_LAYOUT[r][c])
			if MAP_LAYOUT[r][c] == 2:
				_pile_cells.append(Vector2i(c, r))
			elif MAP_LAYOUT[r][c] == 3:
				_slot_cells.append(Vector2i(c, r))
		_map.append(row)
	# Terceira pilha manual
	_map[EXTRA_PILE.y][EXTRA_PILE.x] = 2
	_pile_cells.append(EXTRA_PILE)

func _build_ui() -> void:
	var bg := make_bg()
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	vbox.position = Vector2(30, 60)
	vbox.size     = Vector2(1020, 1800)
	bg.add_child(vbox)

	make_header("🏗️  Obra de Construção — Bélgique", vbox)

	_status_lbl = make_label("Carregue os tijolos (A) e posicione nos slots (⬜).", 28, Color.WHITE, vbox)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_carry_lbl = make_label("", 30, C_ACTIVE, vbox)
	_carry_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 24)
	sp.layout_mode = 2
	vbox.add_child(sp)

	var map_holder := Control.new()
	map_holder.custom_minimum_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	map_holder.layout_mode = 2
	vbox.add_child(map_holder)

	_cell_rects = []
	for r in range(ROWS):
		var row_arr := []
		for c in range(COLS):
			var rect := ColorRect.new()
			rect.size     = Vector2(CELL_SIZE - 3, CELL_SIZE - 3)
			rect.position = Vector2(c * CELL_SIZE + 1, r * CELL_SIZE + 1)
			rect.color    = _cell_color(r, c)
			map_holder.add_child(rect)

			var lbl := Label.new()
			lbl.text = _cell_icon(r, c)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.add_theme_font_size_override("font_size", 52)
			rect.add_child(lbl)
			row_arr.append(rect)
		_cell_rects.append(row_arr)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 20)
	sp2.layout_mode = 2
	vbox.add_child(sp2)

	# D-pad + A button
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 60)
	controls.layout_mode = 2
	vbox.add_child(controls)

	make_dpad(controls, _move_player)

	var a_btn := make_btn("A\n⬆ Pegar/\nPostar", 26, Vector2(160, 160))
	a_btn.add_theme_color_override("font_color", C_SUCCESS)
	a_btn.pressed.connect(_action_press)
	controls.add_child(a_btn)

func _move_player(dir: Vector2) -> void:
	var new_pos := _player_pos + Vector2i(dir)
	if not _in_bounds(new_pos):
		return
	if _map[new_pos.y][new_pos.x] == 1:   # muro
		return
	_player_pos = new_pos
	_refresh_visuals()

func _action_press() -> void:
	var cell: int = _map[_player_pos.y][_player_pos.x] as int

	if not _carrying and cell == 2:
		# Pegar tijolo
		_carrying = true
		_map[_player_pos.y][_player_pos.x] = 0
		_pile_cells.erase(_player_pos)
		_carry_lbl.text = "🧱  Carregando tijolo"
		_status_lbl.text = "Leve ao slot vazio (⬜) e pressione A."
		AudioManager.play_sfx("coin")

	elif _carrying and cell == 3:
		# Colocar tijolo no slot
		_carrying = false
		_map[_player_pos.y][_player_pos.x] = 4
		_placed += 1
		_carry_lbl.text = ""
		_status_lbl.text = "✓  Tijolo colocado! (%d/3)" % _placed
		AudioManager.play_sfx("upgrade")

		if _placed >= 3:
			_finish_game()

	_refresh_visuals()

func _finish_game() -> void:
	_status_lbl.text = "✅  Parede construída! Bom trabalho."
	await get_tree().create_timer(2.0, true).timeout
	_finish(BASE_REWARD)

func _refresh_visuals() -> void:
	for r in range(ROWS):
		for c in range(COLS):
			_cell_rects[r][c].color = _cell_color(r, c)
			(_cell_rects[r][c].get_child(0) as Label).text = _cell_icon(r, c)

func _cell_color(r: int, c: int) -> Color:
	if Vector2i(c, r) == _player_pos:
		return C_PLAYER
	match _map[r][c]:
		1: return C_OBSTACLE
		2: return Color(0.75, 0.25, 0.15)   # pilha de tijolos
		3: return Color(0.20, 0.35, 0.55)   # slot vazio
		4: return C_SUCCESS                  # slot preenchido
		_: return Color(0.22, 0.20, 0.18)

func _cell_icon(r: int, c: int) -> String:
	if Vector2i(c, r) == _player_pos:
		return "🟡" if not _carrying else "🟡🧱"
	match _map[r][c]:
		2: return "🧱"
		3: return "⬜"
		4: return "✅"
		_: return ""

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS
