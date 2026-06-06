## caminhao_minigame.gd
## Mini-game: Dirigir Caminhão de Entrega em Saltillo
## Mapa 10×8. 5 pontos de entrega. Timer 90s. D-pad move o caminhão (1 cell/press).
## Chegar num ponto de entrega = entrega automática.

extends "res://scripts/minigames/minigame_base.gd"

const COLS         := 10
const ROWS         := 8
const CELL_SIZE    := 100
const TIMER_TOTAL  := 90.0
const BASE_REWARD  := 35
const SAT_PER_DEL  := 7

# Mapa: 0=rua, 1=quadra (muro), 2=entrega
# Quadras em posições fixas formam um cruzamento estilo cidade
const MAP_LAYOUT: Array = [
	[1,1,0,1,1,0,1,1,0,1],
	[1,1,0,1,1,0,1,1,0,1],
	[0,0,0,0,0,0,0,0,0,0],
	[1,1,0,1,1,0,1,1,0,1],
	[1,1,0,1,1,0,1,1,0,1],
	[0,0,0,0,0,0,0,0,0,0],
	[1,1,0,1,1,0,1,1,0,1],
	[1,1,0,1,1,0,1,1,0,1],
]
const DELIVERY_SPOTS: Array = [
	Vector2i(0,2), Vector2i(6,2), Vector2i(3,5),
	Vector2i(9,5), Vector2i(0,5),
]
const PLAYER_START := Vector2i(5, 2)

var _map:            Array = []
var _deliveries:     Array = []    # Array[bool] delivered status
var _player_pos:     Vector2i = PLAYER_START
var _delivered:      int = 0
var _timer:          float = TIMER_TOTAL
var _running:        bool = true

var _cell_rects:     Array = []
var _timer_bar:      ProgressBar
var _status_lbl:     Label
var _timer_lbl:      Label
var _progress_lbl:   Label

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
		_map.append(row)

	_deliveries = []
	for d in DELIVERY_SPOTS:
		_deliveries.append(false)
		if _map[d.y][d.x] == 0:   # só marca em rua
			_map[d.y][d.x] = 2

func _build_ui() -> void:
	var bg := make_bg()
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 14)
	vbox.position = Vector2(30, 50)
	vbox.size     = Vector2(1020, 1820)
	bg.add_child(vbox)

	make_header("🚚  Rota de Entrega — Saltillo", vbox)

	var top_row := HBoxContainer.new()
	top_row.layout_mode = 2
	top_row.add_theme_constant_override("separation", 40)
	vbox.add_child(top_row)

	_progress_lbl = make_label("Entregas: 0/5", 30, C_HEADER, top_row)
	_timer_lbl    = make_label("⏱ 90s", 30, Color.WHITE, top_row)

	_status_lbl = make_label("Dirija até os pontos vermelhos para entregar.", 28, Color(0.8,0.8,0.8), vbox)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 28)
	_timer_bar.max_value = TIMER_TOTAL
	_timer_bar.value     = TIMER_TOTAL
	_timer_bar.layout_mode = 2
	vbox.add_child(_timer_bar)

	# Map grid
	var map_holder := Control.new()
	map_holder.custom_minimum_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	map_holder.layout_mode = 2
	vbox.add_child(map_holder)

	_cell_rects = []
	for r in range(ROWS):
		var row_arr := []
		for c in range(COLS):
			var rect := ColorRect.new()
			rect.size     = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			rect.position = Vector2(c * CELL_SIZE + 1, r * CELL_SIZE + 1)
			rect.color    = _cell_color(r, c)
			map_holder.add_child(rect)

			var lbl := Label.new()
			lbl.text = _cell_icon(r, c)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.add_theme_font_size_override("font_size", 40)
			rect.add_child(lbl)
			row_arr.append(rect)
		_cell_rects.append(row_arr)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 16)
	sp.layout_mode = 2
	vbox.add_child(sp)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.layout_mode = 2
	vbox.add_child(hbox)
	make_dpad(hbox, _move_player)

func _process(delta: float) -> void:
	if not _running:
		return
	_timer -= delta
	_timer_bar.value  = max(0.0, _timer)
	_timer_lbl.text   = "⏱ %ds" % int(ceil(_timer))
	if _timer <= 0.0:
		_time_up()

func _move_player(dir: Vector2) -> void:
	if not _running:
		return
	var new_pos := _player_pos + Vector2i(dir)
	if not _in_bounds(new_pos):
		return
	if _map[new_pos.y][new_pos.x] == 1:   # quadra/muro
		return
	_player_pos = new_pos
	_check_delivery()
	_refresh_visuals()

func _check_delivery() -> void:
	for i in range(DELIVERY_SPOTS.size()):
		if _deliveries[i]:
			continue
		if _player_pos == DELIVERY_SPOTS[i]:
			_deliveries[i] = true
			_delivered += 1
			_map[_player_pos.y][_player_pos.x] = 0   # clear marker
			_status_lbl.text = "📦  Entregue! (%d/5)" % _delivered
			AudioManager.play_sfx("coin")
			_progress_lbl.text = "Entregas: %d/5" % _delivered
			if _delivered >= DELIVERY_SPOTS.size():
				_finish_success()
			return

func _finish_success() -> void:
	_running = false
	var time_bonus := int(_timer / 10.0) * 5
	var reward := _delivered * SAT_PER_DEL + time_bonus
	_status_lbl.text = "✅  Todas as entregas feitas!\n+%d sats (bônus de tempo: +%d)" % [reward, time_bonus]
	await get_tree().create_timer(2.0, true).timeout
	if is_instance_valid(self) and not is_queued_for_deletion():
		_finish(reward)

func _time_up() -> void:
	_running = false
	var reward := _delivered * SAT_PER_DEL
	_status_lbl.text = "⏱  Tempo esgotado! %d/5 entregas — +%d sats" % [_delivered, reward]
	await get_tree().create_timer(2.0, true).timeout
	if is_instance_valid(self) and not is_queued_for_deletion():
		_finish(max(reward, 5))

func _refresh_visuals() -> void:
	for r in range(ROWS):
		for c in range(COLS):
			var rect: ColorRect = _cell_rects[r][c]
			rect.color = _cell_color(r, c)
			var lbl: Label = rect.get_child(0)
			lbl.text = _cell_icon(r, c)

func _cell_color(r: int, c: int) -> Color:
	if Vector2i(c, r) == _player_pos:
		return C_PLAYER
	match _map[r][c]:
		1: return C_OBSTACLE
		2: return C_DELIVERY
		_: return Color(0.18, 0.20, 0.15)

func _cell_icon(r: int, c: int) -> String:
	if Vector2i(c, r) == _player_pos:
		return "🚚"
	match _map[r][c]:
		2: return "📦"
		_: return ""

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS
