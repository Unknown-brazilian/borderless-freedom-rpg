## avelino_event.gd
## Borderless Freedom: A Dissident Adventure
## Avelino aparece oferecendo ouro em troca de sats.
## Se o jogador aceitar: ladrão rouba todo o ouro logo depois.
## Lição: ouro físico tem custódia. Bitcoin, não.

extends CanvasLayer

signal event_closed

@onready var _lbl_title:   Label  = $Panel/VBox/LabelTitle
@onready var _lbl_text:    Label  = $Panel/VBox/LabelText
@onready var _lbl_ouro:    Label  = $Panel/VBox/LabelOuro
@onready var _btn_trocar:  Button = $Panel/VBox/BtnTrocar
@onready var _btn_recusar: Button = $Panel/VBox/BtnRecusar

const OURO_PRICE_SATS := 50
const OURO_UNITS      := 10

var _ouro_atual: int  = 0
var _traded:     bool = false

func _ready() -> void:
	_btn_trocar.pressed.connect(_on_trocar)
	_btn_recusar.pressed.connect(_on_recusar)

func setup(ouro: int) -> void:
	_ouro_atual = ouro
	_refresh_ui()

func _refresh_ui() -> void:
	_lbl_title.text = "🪙  Avelino"
	if _ouro_atual > 0:
		_lbl_text.text = (
			"\"Parceiro! Tenho mais barras de ouro!\n\n" +
			"Só %d sats por mais %d barras.\n" % [OURO_PRICE_SATS, OURO_UNITS] +
			"Ouro é REAL — bitcoin é só número em tela!\"\n\n" +
			"Você já tem %d barras." % _ouro_atual
		)
	else:
		_lbl_text.text = (
			"\"Ei amigo! Troque seus bitcoins por ouro!\n\n" +
			"Ouro é sólido, confiável, eterno!\n" +
			"Só %d sats por %d barras de ouro puro!\n\n" % [OURO_PRICE_SATS, OURO_UNITS] +
			"Ouro nunca falha. Bitcoin é virtual!\""
		)
	_lbl_ouro.text = "🏅  Seu ouro: %d barras" % _ouro_atual
	var can_afford := SatEconomy.current_sats >= OURO_PRICE_SATS
	_btn_trocar.disabled = not can_afford or _traded
	if not can_afford:
		_btn_trocar.text = "💰  Trocar (sats insuficientes)"
	else:
		_btn_trocar.text = "💰  Trocar %d sats por %d barras" % [OURO_PRICE_SATS, OURO_UNITS]

func _on_trocar() -> void:
	if _traded or SatEconomy.current_sats < OURO_PRICE_SATS: return
	_traded = true
	SatEconomy.remove_sats(OURO_PRICE_SATS, "avelino_ouro_compra")
	_ouro_atual += OURO_UNITS
	SaveSystem.set_value("avelino_ouro", _ouro_atual)

	_btn_trocar.disabled = true
	_btn_recusar.disabled = true
	_lbl_text.text = (
		"Avelino entrega as barras com um sorriso.\n" +
		"\"Boa compra! Guarde bem!\"\n\n" +
		"Você recebeu %d barras de ouro." % OURO_UNITS
	)
	_lbl_ouro.text = "🏅  Seu ouro: %d barras" % _ouro_atual

	await get_tree().create_timer(2.5).timeout
	_spawn_thief()

func _spawn_thief() -> void:
	if not is_inside_tree(): return
	var gold_stolen := _ouro_atual
	_ouro_atual = 0
	SaveSystem.set_value("avelino_ouro", 0)

	_lbl_title.text = "🥷  LADRÃO!"
	_lbl_text.text  = (
		"Um ladrão emerge das sombras!\n\n" +
		"\"Hehehe — ouro físico é fácil de carregar!\"\n\n" +
		"Todas as suas %d barras foram levadas.\n\n" % gold_stolen +
		"🟠  Seus sats? Permanecem na blockchain.\n" +
		"Não existe ladrão que roube uma chave privada\n" +
		"que só existe na sua mente."
	)
	_lbl_ouro.text        = "🏅  Seu ouro: 0 barras (roubado)"
	_btn_recusar.disabled = false
	_btn_recusar.text     = "Entendido"

func _on_recusar() -> void:
	emit_signal("event_closed")
	queue_free()
