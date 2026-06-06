## ending_free.gd
## Borderless Freedom: A Dissident Adventure
## Final padrão — campanha completa, liberdade conquistada.

extends Control

@onready var _btn_menu:  Button = $VBox/BtnMenu
@onready var _lbl_sats:  Label  = $VBox/LabelSats
@onready var _lbl_name:  Label  = $VBox/LabelName
@onready var _lbl_stats: Label  = $VBox/LabelStats

func _ready() -> void:
	AutonomyBar.set_active(false)
	AudioManager.music("ending")
	_btn_menu.pressed.connect(_on_menu)

	var nome := PlayerStats.player_name if PlayerStats.player_name != "" else "Dissidente"
	_lbl_name.text = nome + " — DISSIDENT. FREE."
	_lbl_sats.text = "%s sats conquistados" % _fmt(SatEconomy.lifetime_earned)

	var gs   := GameStats.get_stats()
	var evts := RandomEventsSystem.get_stats()
	var kms: int = gs.get("kms_pedalados", 0)
	var dias: int = gs.get("dias_de_viagem", 0)
	var bosses: int = gs.get("bosses_defeated", 0)
	var fiscais: int = gs.get("fiscais_subornados", 0)
	var evitados: int = evts.get("total_avoided", 0)

	if _lbl_stats:
		_lbl_stats.text = (
			"9 países atravessados\n"
			+ "%d chefes derrotados\n"
			+ "%s km pedalados\n"
			+ "%d dias de viagem\n"
			+ "%d fiscais pagos\n"
			+ "%d eventos cripto ignorados"
		) % [bosses, _fmt(kms), dias, fiscais, evitados]

	SaveSystem.delete_save()

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

func _on_menu() -> void:
	SceneTransition.go("res://scenes/ui/main_menu.tscn")
