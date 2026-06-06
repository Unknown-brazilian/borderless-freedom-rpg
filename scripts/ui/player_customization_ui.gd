## player_customization_ui.gd
## Tela de customização. Cicla entre opções via botões ◀ ▶.
## Confirmar → SeedPhraseScreen. Voltar → main_menu.

extends CanvasLayer

@onready var _lbl_skin:  Label  = $VBox/SkinRow/LabelSkin
@onready var _lbl_cap:   Label  = $VBox/CapaceteRow/LabelCap
@onready var _lbl_moc:   Label  = $VBox/MochilaRow/LabelMoc
@onready var _lbl_bike:  Label  = $VBox/BikeRow/LabelBike
@onready var _lbl_bonus: Label  = $VBox/BonusLabel

func _ready() -> void:
	AutonomyBar.set_active(false)

	$VBox/SkinRow/BtnSkinL.pressed.connect(func(): PlayerCustomization.cycle_skin(-1);   _refresh())
	$VBox/SkinRow/BtnSkinR.pressed.connect(func(): PlayerCustomization.cycle_skin(1);    _refresh())
	$VBox/CapaceteRow/BtnCapL.pressed.connect(func(): PlayerCustomization.cycle_capacete(-1); _refresh())
	$VBox/CapaceteRow/BtnCapR.pressed.connect(func(): PlayerCustomization.cycle_capacete(1);  _refresh())
	$VBox/MochilaRow/BtnMocL.pressed.connect(func(): PlayerCustomization.cycle_mochila(-1);  _refresh())
	$VBox/MochilaRow/BtnMocR.pressed.connect(func(): PlayerCustomization.cycle_mochila(1);   _refresh())
	$VBox/BikeRow/BtnBikeL.pressed.connect(func(): PlayerCustomization.cycle_bike(-1);   _refresh())
	$VBox/BikeRow/BtnBikeR.pressed.connect(func(): PlayerCustomization.cycle_bike(1);    _refresh())
	$VBox/BtnConfirmar.pressed.connect(_on_confirmar)
	$VBox/BtnVoltar.pressed.connect(_on_voltar)
	_refresh()

func _refresh() -> void:
	_lbl_skin.text  = "Skin: %s"      % PlayerCustomization.get_skin_name()
	_lbl_cap.text   = "Capacete: %s"  % PlayerCustomization.get_capacete_name()
	_lbl_moc.text   = "Mochila: %s"   % PlayerCustomization.get_mochila_name()
	_lbl_bike.text  = "Bike: %s"      % PlayerCustomization.get_bike_name()

	var cap: Dictionary     = PlayerCustomization.CAPACETES[PlayerCustomization.capacete_index]
	var mochila: Dictionary = PlayerCustomization.MOCHILAS[PlayerCustomization.mochila_index]
	var bike: Dictionary    = PlayerCustomization.BIKES[PlayerCustomization.bike_index]

	var bonus_parts: Array[String] = []
	if cap["energy_bonus"] > 0.0:
		var pct := int(cap["energy_bonus"] / 40.0 * 100.0)
		bonus_parts.append("-%d%% dreno de energia" % pct)
	if mochila["water_bonus"] > 0.0:
		var pct := int(mochila["water_bonus"] / 60.0 * 100.0)
		bonus_parts.append("-%d%% dreno de água" % pct)
	if mochila["food_bonus"] > 0.0:
		var pct := int(mochila["food_bonus"] / 50.0 * 100.0)
		bonus_parts.append("-%d%% dreno de comida" % pct)
	if bike["speed_bonus"] > 0.0:
		bonus_parts.append("+%.1f velocidade" % bike["speed_bonus"])

	_lbl_bonus.text = "Bonus: " + (", ".join(bonus_parts) if bonus_parts.size() > 0 else "nenhum")

func _on_confirmar() -> void:
	PlayerCustomization.save_customization()
	SceneTransition.go("res://scenes/ui/SeedPhraseScreen.tscn")

func _on_voltar() -> void:
	SceneTransition.go("res://scenes/ui/main_menu.tscn")
