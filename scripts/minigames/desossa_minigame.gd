## desossa_minigame.gd
## Mini-game: Desossa de Porco
## 6 zonas de corte se iluminam uma por vez. Toque na zona iluminada a tempo.
## Timer de 2.5s por corte. Acertos = sats completos; erros = penalidade.

extends "res://scripts/minigames/minigame_base.gd"

const TOTAL_ZONES   := 6
const CUT_TIMER_SEC := 2.5
const BASE_REWARD   := 30

const ZONE_NAMES := ["Paleta", "Pernil", "Costela", "Lombo", "Barriga", "Pescoço"]

var _cuts_hit:     int   = 0
var _current_zone: int   = -1
var _cut_timer:    float = 0.0
var _running:      bool  = false
var _zones_done:   Array[bool] = [false, false, false, false, false, false]
var _zone_btns:    Array[Button] = []
var _timer_bar:    ProgressBar
var _status_lbl:   Label
var _progress_lbl: Label

func _ready() -> void:
	super._ready()
	_build_ui()
	await get_tree().create_timer(0.4, true).timeout
	_next_zone()
	_running = true

func _build_ui() -> void:
	var bg := make_bg()
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	vbox.position = Vector2(40, 60)
	vbox.size     = Vector2(1000, 1800)
	bg.add_child(vbox)

	make_header("🔪  Desossa de Porco", vbox)

	_progress_lbl = make_label("Cortes: 0 / %d" % TOTAL_ZONES, 32, Color.WHITE, vbox)
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 36)
	_timer_bar.max_value = CUT_TIMER_SEC
	_timer_bar.value     = CUT_TIMER_SEC
	_timer_bar.layout_mode = 2
	vbox.add_child(_timer_bar)

	_status_lbl = make_label("Toque na zona iluminada!", 30, Color(0.8, 0.8, 0.8), vbox)
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 40)
	sp.layout_mode = 2
	vbox.add_child(sp)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.layout_mode = 2
	vbox.add_child(grid)

	for i in range(TOTAL_ZONES):
		var btn := make_btn(ZONE_NAMES[i], 32, Vector2(310, 220))
		btn.pressed.connect(_on_zone_tapped.bind(i))
		btn.disabled = true
		btn.modulate = C_NEUTRAL
		_zone_btns.append(btn)
		grid.add_child(btn)

func _process(delta: float) -> void:
	if not _running:
		return
	_cut_timer -= delta
	_timer_bar.value = max(0.0, _cut_timer)
	if _cut_timer <= 0.0:
		_on_miss()

func _next_zone() -> void:
	# Disable all
	for i in range(TOTAL_ZONES):
		_zone_btns[i].disabled = true
		if not _zones_done[i]:
			_zone_btns[i].modulate = C_NEUTRAL

	# Pick undone zone
	var available: Array[int] = []
	for i in range(TOTAL_ZONES):
		if not _zones_done[i]:
			available.append(i)
	if available.is_empty():
		_finish_game()
		return

	_current_zone = available[randi() % available.size()]
	_zone_btns[_current_zone].modulate = C_ACTIVE
	_zone_btns[_current_zone].disabled = false
	_cut_timer = CUT_TIMER_SEC
	_status_lbl.text = "Corte em: %s" % ZONE_NAMES[_current_zone]

func _on_zone_tapped(idx: int) -> void:
	if not _running or idx != _current_zone:
		return
	_cuts_hit += 1
	_zones_done[idx] = true
	_zone_btns[idx].modulate = C_SUCCESS
	_zone_btns[idx].disabled = true
	_update_progress()
	_status_lbl.text = "✓  Corte certeiro!"
	await get_tree().create_timer(0.4, true).timeout
	_next_zone()

func _on_miss() -> void:
	_zones_done[_current_zone] = true
	_zone_btns[_current_zone].modulate = C_FAIL
	_zone_btns[_current_zone].disabled = true
	_status_lbl.text = "⏱  Demorou demais!"
	_update_progress()
	await get_tree().create_timer(0.5, true).timeout
	_next_zone()

func _update_progress() -> void:
	var done := _zones_done.count(true)
	_progress_lbl.text = "Cortes: %d / %d" % [done, TOTAL_ZONES]

func _finish_game() -> void:
	_running = false
	var reward := int(BASE_REWARD * (float(_cuts_hit) / float(TOTAL_ZONES)))
	reward = max(reward, 5)
	_status_lbl.text = "✅  Desossa completa!\n%d/%d certeiros — +%d sats" % [_cuts_hit, TOTAL_ZONES, reward]
	await get_tree().create_timer(1.8, true).timeout
	_finish(reward)
