## empilhadeira_minigame.gd
## Mini-game: Manobras de Empilhadeira (Sokoban simplificado)
## Conduza a empilhadeira até os 3 paletes (azul) e leve-os aos alvos (verde).
## D-pad move o player. Mover em direção a um palete = empurrá-lo.

extends "res://scripts/minigames/minigame_base.gd"

const COLS       := 7
const ROWS       := 5
const CELL_SIZE  := 132
const BASE_REWARD := 25

# Tipos de célula
enum Cell { FLOOR, WALL, PALLET, TARGET, PALLET_ON_TARGET }

# Layout inicial (ROWS × COLS)
# W=wall, .=floor, P=pallet, T=target
const LEVEL: Array = [
	[1,1,1,1,1,1,1],  # row 0
	[1,0,0,0,0,0,1],  # row 1
	[1,0,1,0,1,0,1],  # row 2
	[1,0,0,0,0,0,1],  # row 3
	[1,1,1,1,1,1,1],  # row 4
]
# Posições iniciais dos paletes (col, row)
const PALLET_STARTS: Array = [Vector2i(1,1), Vector2i(3,1), Vector2i(5,1)]
# Posições dos alvos
const TARGETS:       Array = [Vector2i(1,3), Vector2i(3,3), Vector2i(5,3)]
# Posição inicial do player
const PLAYER_START := Vector2i(3, 2)

var _grid:         Array = []    # Array[Array[int]] ROWS×COLS cell type
var _pallet_pos:   Array = []    # Array[Vector2i]
var _target_set:   Dictionary = {}
var _player_pos:   Vector2i = PLAYER_START
var _solved:       int = 0
var _status_lbl:   Label
var _cell_rects:   Array = []    # Array[Array[ColorRect]] for visual update

func _ready() -> void:
	super._ready()
	_init_grid()
	_build_ui()

func _init_grid() -> void:
	_grid = []
	for r in range(ROWS):
		var row: Array[int] = []
		for c in range(COLS):
			row.append(LEVEL[r][c])
		_grid.append(row)

	_pallet_pos = []
	for p in PALLET_STARTS:
		_pallet_pos.append(Vector2i(p))
		_grid[p.y][p.x] = Cell.PALLET

	for t in TARGETS:
		_target_set[t] = true

func _build_ui() -> void:
	var bg := make_bg()
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.position = Vector2(40, 60)
	vbox.size     = Vector2(1000, 1800)
	bg.add_child(vbox)

	make_header("🏗️  Empilhadeira", vbox)
	_status_lbl = make_label("Empurre os paletes (🟦) para os alvos (🟩).", 28, Color.WHITE, vbox)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	sp.layout_mode = 2
	vbox.add_child(sp)

	# Grid visual
	var grid_holder := Control.new()
	var total_w := COLS * CELL_SIZE
	var total_h := ROWS * CELL_SIZE
	grid_holder.custom_minimum_size = Vector2(total_w, total_h)
	grid_holder.layout_mode = 2
	vbox.add_child(grid_holder)

	_cell_rects = []
	for r in range(ROWS):
		var row_arr := []
		for c in range(COLS):
			var rect := ColorRect.new()
			rect.size     = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
			rect.position = Vector2(c * CELL_SIZE + 2, r * CELL_SIZE + 2)
			rect.color    = _cell_color(r, c)
			grid_holder.add_child(rect)
			row_arr.append(rect)

			# Label inside cell
			var lbl := Label.new()
			lbl.text = _cell_icon(r, c)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.add_theme_font_size_override("font_size", 52)
			rect.add_child(lbl)
		_cell_rects.append(row_arr)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 20)
	sp2.layout_mode = 2
	vbox.add_child(sp2)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.layout_mode = 2
	vbox.add_child(hbox)
	make_dpad(hbox, _move_player)

func _cell_color(r: int, c: int) -> Color:
	match _grid[r][c]:
		Cell.WALL:            return C_OBSTACLE
		Cell.PALLET:          return Color(0.2, 0.3, 0.8)
		Cell.TARGET:          return C_TARGET
		Cell.PALLET_ON_TARGET: return C_SUCCESS
		_:
			if Vector2i(c, r) in _target_set:
				return Color(C_TARGET, 0.4)
			return C_PANEL

func _cell_icon(r: int, c: int) -> String:
	if Vector2i(c, r) == _player_pos:
		return "🟡"
	match _grid[r][c]:
		Cell.WALL:             return ""
		Cell.PALLET:           return "🟦"
		Cell.TARGET:           return "✗"
		Cell.PALLET_ON_TARGET: return "✅"
		_:
			if Vector2i(c, r) in _target_set:
				return "✗"
			return ""

func _move_player(dir: Vector2) -> void:
	var new_pos := _player_pos + Vector2i(dir)
	if not _in_bounds(new_pos):
		return
	match _grid[new_pos.y][new_pos.x]:
		Cell.WALL:
			return
		Cell.PALLET, Cell.PALLET_ON_TARGET:
			_try_push_pallet(new_pos, Vector2i(dir))
		_:
			_player_pos = new_pos
	_refresh_visuals()

func _try_push_pallet(pallet_pos: Vector2i, dir: Vector2i) -> void:
	var behind := pallet_pos + dir
	if not _in_bounds(behind):
		return
	if _grid[behind.y][behind.x] == Cell.WALL or _grid[behind.y][behind.x] == Cell.PALLET \
			or _grid[behind.y][behind.x] == Cell.PALLET_ON_TARGET:
		return

	# Move pallet
	var old_type: int = _grid[pallet_pos.y][pallet_pos.x]
	_grid[pallet_pos.y][pallet_pos.x] = Cell.TARGET if Vector2i(pallet_pos) in _target_set else Cell.FLOOR

	var on_target: bool = Vector2i(behind) in _target_set
	_grid[behind.y][behind.x] = Cell.PALLET_ON_TARGET if on_target else Cell.PALLET

	# Update pallet_pos array
	for i in range(_pallet_pos.size()):
		if _pallet_pos[i] == pallet_pos:
			_pallet_pos[i] = behind
			break

	# Ajustar contador de paletes nos alvos
	if on_target and old_type == Cell.PALLET:
		_solved += 1
		AudioManager.play_sfx("coin")
	elif not on_target and old_type == Cell.PALLET_ON_TARGET:
		_solved -= 1   # pallet saiu do alvo

	_player_pos = pallet_pos
	_check_win()

func _check_win() -> void:
	if _solved >= PALLET_STARTS.size():
		_status_lbl.text = "✅  Todos os paletes no lugar!"
		await get_tree().create_timer(1.5, true).timeout
		_finish(BASE_REWARD)

func _refresh_visuals() -> void:
	for r in range(ROWS):
		for c in range(COLS):
			var rect: ColorRect = _cell_rects[r][c]
			rect.color = _cell_color(r, c)
			var lbl: Label = rect.get_child(0)
			lbl.text = _cell_icon(r, c)

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS
