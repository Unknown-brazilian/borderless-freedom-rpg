## hud_rpg.gd
## HUD do mapa do mundo — sats, recursos, região atual.

extends CanvasLayer

@onready var _lbl_sats:    Label       = $TopBar/LabelSats
@onready var _lbl_region:  Label       = $TopBar/LabelRegion
@onready var _bar_water:   ProgressBar = $ResourceBars/BarWater
@onready var _bar_food:    ProgressBar = $ResourceBars/BarFood
@onready var _bar_energy:  ProgressBar = $ResourceBars/BarEnergy
@onready var _lbl_item:    Label       = $TopBar/LabelItem

const COLOR_NORMAL   := Color(1.0, 0.85, 0.0)
const COLOR_RECOVERY := Color(1.0, 0.22, 0.22)
const COLOR_LOW      := Color(1.0, 0.55, 0.0)

func _ready() -> void:
	SatEconomy.sats_changed.connect(func(total, _d): _update_sats(total))
	AutonomyBar.resource_changed.connect(func(_r, _v, _m): _update_bars())
	WorldManager.region_changed.connect(func(_d, name): _lbl_region.text = name)
	PlayerInventory.active_item_changed.connect(func(_id): _refresh_item())

	if RandomEventsSystem:
		RandomEventsSystem.recovery_mode_started.connect(func(_l):
			_lbl_sats.add_theme_color_override("font_color", COLOR_RECOVERY)
		)
		RandomEventsSystem.recovery_mode_ended.connect(func():
			_lbl_sats.add_theme_color_override("font_color", COLOR_NORMAL)
		)

	_update_sats(SatEconomy.current_sats)
	_update_bars()
	_lbl_region.text = WorldManager.get_region_name()
	_refresh_item()

func _update_sats(total: int) -> void:
	var s := str(total)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0: result = "," + result
		result = s[i] + result
		count += 1
	_lbl_sats.text = "₿ %s sats" % result

func _update_bars() -> void:
	_set_bar(_bar_water,  AutonomyBar.water  / AutonomyBar.MAX_WATER)
	_set_bar(_bar_food,   AutonomyBar.food   / AutonomyBar.MAX_FOOD)
	_set_bar(_bar_energy, AutonomyBar.energy / AutonomyBar.MAX_ENERGY)

func _set_bar(bar: ProgressBar, ratio: float) -> void:
	bar.value = clampf(ratio * 100.0, 0.0, 100.0)
	if ratio < 0.25:
		bar.modulate = COLOR_RECOVERY
	elif ratio < 0.5:
		bar.modulate = COLOR_LOW
	else:
		bar.modulate = Color.WHITE

func _refresh_item() -> void:
	if PlayerInventory.active_item.is_empty():
		_lbl_item.text = ""
	else:
		_lbl_item.text = "%s  A" % PlayerInventory.get_active_icon()
