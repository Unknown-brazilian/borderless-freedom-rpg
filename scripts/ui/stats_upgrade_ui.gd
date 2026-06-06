## stats_upgrade_ui.gd
## Borderless Freedom: A Dissident Adventure
## Tela de upgrade de stats — acessível durante a transição entre dungeons.
## O jogador gasta sats para melhorar Velocidade, Resistência, Carga, Furtividade, Persuasão.

extends Control

const STAT_LABELS := {
	"velocidade":  "⚡ Velocidade",
	"resistencia": "🛡️ Resistência",
	"carga":       "🎒 Carga",
	"furtividade": "👁️ Furtividade",
	"persuasao":   "🗣️ Persuasão",
}

const STAT_ORDER := ["velocidade", "resistencia", "carga", "furtividade", "persuasao"]

@onready var _lbl_sats:  Label          = $VBox/LabelSats
@onready var _grid:      GridContainer  = $VBox/StatsGrid
@onready var _btn_fechar: Button        = $VBox/BtnFechar

var _row_buttons: Dictionary = {}   # stat_name → Button

func _ready() -> void:
	_btn_fechar.pressed.connect(_on_fechar)
	_build_rows()
	_refresh()

	if SatEconomy:
		SatEconomy.sats_changed.connect(func(_t, _d): _refresh())

func _build_rows() -> void:
	for stat in STAT_ORDER:
		var lbl := Label.new()
		lbl.text = STAT_LABELS.get(stat, stat)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.theme_override_font_sizes = {"font_size": 26}
		_grid.add_child(lbl)

		var lbl_val := Label.new()
		lbl_val.name = "Val_" + stat
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_val.custom_minimum_size = Vector2(80, 0)
		lbl_val.theme_override_font_sizes = {"font_size": 26}
		_grid.add_child(lbl_val)

		var btn := Button.new()
		btn.name = "Btn_" + stat
		btn.custom_minimum_size = Vector2(200, 64)
		btn.theme_override_font_sizes = {"font_size": 22}
		btn.pressed.connect(_on_upgrade.bind(stat))
		_grid.add_child(btn)
		_row_buttons[stat] = btn

func _refresh() -> void:
	var sats := SatEconomy.current_sats if SatEconomy else 0
	_lbl_sats.text = "%s sats disponíveis" % _fmt(sats)

	for stat in STAT_ORDER:
		var cur  := PlayerStats.get_stat(stat)
		var cost := PlayerStats.get_upgrade_cost(stat)
		var max_val: int = PlayerStats.STAT_DEFS[stat]["max"]

		var val_lbl: Label = _grid.get_node_or_null("Val_" + stat)
		if val_lbl:
			val_lbl.text = "%d / %d" % [cur, max_val]

		var btn: Button = _row_buttons.get(stat)
		if not btn:
			continue

		if cost < 0:
			btn.text     = "MÁXIMO"
			btn.disabled = true
		else:
			btn.text     = "↑  %s sats" % _fmt(cost)
			btn.disabled = sats < cost

func _on_upgrade(stat: String) -> void:
	if PlayerStats.upgrade_stat(stat):
		_refresh()

func _on_fechar() -> void:
	queue_free()

func _fmt(n: int) -> String:
	var s := str(n)
	var r := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		if c > 0 and c % 3 == 0:
			r = "," + r
		r = s[i] + r
		c += 1
	return r
