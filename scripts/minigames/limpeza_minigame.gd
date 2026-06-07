## limpeza_minigame.gd
## Mini-game: Lavar o Chão do Frigorífico
## 8×6 grid de tiles sujos. Mover sobre eles limpa. Intencionalmentee repetitivo.
## A cada 10 tiles limpos, um imigrante colega conta uma história.
## Completa ao limpar todos os tiles.

extends "res://scripts/minigames/minigame_base.gd"

const COLS       := 8
const ROWS       := 6
const CELL_SIZE  := 115
const BASE_REWARD := 20

# Algumas células são obstáculos (mesas, máquinas) — 0=limpo/piso, 1=sujo, 2=obstáculo
const MAP_TEMPLATE: Array = [
	[1,1,1,1,1,1,1,1],
	[1,1,1,2,2,1,1,1],
	[1,1,1,2,2,1,1,1],
	[1,2,2,1,1,2,2,1],
	[1,2,2,1,1,2,2,1],
	[1,1,1,1,1,1,1,1],
]
const PLAYER_START := Vector2i(0, 5)

# Histórias dos colegas imigrantes (a cada 10 tiles limpos)
const STORIES: Array[String] = [
	"Jorge: \"No meu país havia 100% de inflação ao mês.\nTodo salário valia metade na semana seguinte.\nBitcoin foi o único dinheiro que não encolhia.\"",
	"Amara: \"Passei 5 dias a pé pelo Darién.\nOs guias abandonaram o grupo no terceiro dia.\nSobrevivemos nos ajudando.\"",
	"Viktor: \"Na Bolivária, o governo confiscou a poupança de 10 anos.\nDisseram que era 'necessidade nacional'.\nNunca devolveram.\"",
	"Freddie: \"Minha família acha que estou trabalhando aqui por escolha.\nNão sabem que estou fugindo de uma dívida que não fiz.\nÉ mais fácil assim.\"",
]

var _map:           Array = []    # Array[Array[int]]
var _player_pos:    Vector2i = PLAYER_START
var _dirty_total:   int = 0
var _cleaned:       int = 0
var _story_trigger: int = 0
var _story_idx:     int = 0
var _paused_for_story: bool = false

var _cell_rects:    Array = []
var _status_lbl:    Label
var _progress_lbl:  Label

func _ready() -> void:
	super._ready()
	_init_map()
	_build_ui()

func _init_map() -> void:
	_map = []
	_dirty_total = 0
	for r in range(ROWS):
		var row: Array[int] = []
		for c in range(COLS):
			row.append(MAP_TEMPLATE[r][c])
			if MAP_TEMPLATE[r][c] == 1:
				_dirty_total += 1
		_map.append(row)

	# Mark player start as clean
	_map[PLAYER_START.y][PLAYER_START.x] = 0
	_dirty_total = max(0, _dirty_total - 1)

func _build_ui() -> void:
	var bg := make_bg()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	make_header("Limpeza do Frigorífico", vbox)

	_progress_lbl = make_label("Limpos: 0 / %d" % _dirty_total, 30, Color.WHITE, vbox)
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_status_lbl = make_label("Passe por todos os tiles sujos.", 28, Color(0.7, 0.7, 0.7), vbox)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	# Dica de tédio intencional
	make_label("(Sim, é isso. Esfregão. Passo a passo.)", 22, Color(0.45, 0.45, 0.45), vbox).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 16)
	sp.layout_mode = 2
	vbox.add_child(sp)

	# Map grid (centralizado)
	var grid_center := CenterContainer.new()
	grid_center.layout_mode = 2
	vbox.add_child(grid_center)
	var map_holder := Control.new()
	map_holder.custom_minimum_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	grid_center.add_child(map_holder)

	_cell_rects = []
	for r in range(ROWS):
		var row_arr := []
		for c in range(COLS):
			var rect := ColorRect.new()
			rect.size     = Vector2(CELL_SIZE - 3, CELL_SIZE - 3)
			rect.position = Vector2(c * CELL_SIZE + 1, r * CELL_SIZE + 1)
			rect.color    = _cell_color(r, c)
			map_holder.add_child(rect)
			row_arr.append(rect)
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

func _move_player(dir: Vector2) -> void:
	if _paused_for_story:
		return
	var new_pos := _player_pos + Vector2i(dir)
	if not _in_bounds(new_pos):
		return
	if _map[new_pos.y][new_pos.x] == 2:   # obstáculo
		return

	_player_pos = new_pos
	_try_clean()
	_refresh_visuals()

func _try_clean() -> void:
	var r := _player_pos.y
	var c := _player_pos.x
	if _map[r][c] == 1:
		_map[r][c] = 0
		_cleaned += 1
		_progress_lbl.text = "Limpos: %d / %d" % [_cleaned, _dirty_total]

		# Diálogo a cada 10 tiles
		_story_trigger += 1
		if _story_trigger >= 10 and _story_idx < STORIES.size():
			_story_trigger = 0
			_trigger_story()
		elif _cleaned >= _dirty_total:
			_finish_game()

func _trigger_story() -> void:
	_paused_for_story = true
	var lines: Array[String] = [STORIES[_story_idx]]
	_story_idx += 1
	DialogueManager.start(lines)
	DialogueManager.dialogue_finished.connect(_on_story_done, CONNECT_ONE_SHOT)

func _on_story_done() -> void:
	AutonomyBar.set_active(false)   # DialogueManager re-habilitou, mas ainda estamos no mini-game
	_paused_for_story = false
	if _cleaned >= _dirty_total:
		_finish_game()

func _finish_game() -> void:
	_paused_for_story = true
	_status_lbl.text = "✅  Frigorífico limpo!\nTrabalho mais entediante do mundo.\nMas feito."
	await get_tree().create_timer(2.0, true).timeout
	_finish(BASE_REWARD)

func _refresh_visuals() -> void:
	for r in range(ROWS):
		for c in range(COLS):
			var rect: ColorRect = _cell_rects[r][c]
			rect.color = _cell_color(r, c)

func _cell_color(r: int, c: int) -> Color:
	if Vector2i(c, r) == _player_pos:
		return C_PLAYER
	match _map[r][c]:
		2: return C_OBSTACLE
		1: return C_DIRTY
		_: return C_CLEAN

func _cell_icon(r: int, c: int) -> String:
	if Vector2i(c, r) == _player_pos:
		return "🧹"
	match _map[r][c]:
		2: return "📦"
		1: return "🟫"
		_: return ""

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS
