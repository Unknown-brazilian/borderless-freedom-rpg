## fernando_ulrich_event.gd
## Borderless Freedom: A Dissident Adventure
## Fernando Ulrich aparece oferecendo Tesouro Direto com a "herança" de R$ 100.000.
## Após 3 rodadas de investimento, o dinheiro em reais vai a zero.
## Demonstração didática: fiat se desvaloriza. 1 sat = 1 sat.

extends CanvasLayer

signal event_closed

@onready var _lbl_title:    Label  = $Panel/VBox/LabelTitle
@onready var _lbl_text:     Label  = $Panel/VBox/LabelText
@onready var _lbl_reais:    Label  = $Panel/VBox/LabelReais
@onready var _btn_investir: Button = $Panel/VBox/BtnInvestir
@onready var _btn_recusar:  Button = $Panel/VBox/BtnRecusar

const INITIAL_REAIS := 100_000.0

var _reais:  float = INITIAL_REAIS
var _rounds: int   = 0

func _ready() -> void:
	_btn_investir.pressed.connect(_on_investir)
	_btn_recusar.pressed.connect(_on_recusar)

func setup(saved_reais: float, saved_rounds: int) -> void:
	_reais  = saved_reais
	_rounds = saved_rounds
	_refresh_ui()

func _refresh_ui() -> void:
	match _rounds:
		0:
			_lbl_title.text = "💼  Fernando Ulrich"
			_lbl_text.text  = (
				"\"Olá! Você herdou R$ 100.000,00.\n\n" +
				"Tenho uma oportunidade INCRÍVEL:\n" +
				"Tesouro Direto — rendimento garantido!\n" +
				"O governo nunca dá calote...\n\n" +
				"Invista agora e veja seu dinheiro crescer!\"\n\n" +
				"📌  Bitcoin é volatil. Reais são seguros... né?"
			)
		1, 2:
			_lbl_title.text = "💼  Fernando Ulrich retorna"
			_lbl_text.text  = (
				"\"Seu Tesouro está rendendo! Quer reinvestir?\n\n" +
				"A inflação está 'sob controle'.\n" +
				"Só mais uma rodada e seu patrimônio dobra!\n\n" +
				"(rodada %d de 3)\"\n\n" +
				"⚠️  Mais uma vez?" % [_rounds + 1]
			)
		_:
			_lbl_title.text = "💥  TESOURO CALOTEADO!"
			_lbl_text.text  = (
				"Fernando Ulrich some sem deixar rastro.\n\n" +
				"Seus R$ 100.000 viraram cinzas.\n\n" +
				"\"Não existe almoço grátis em reais.\"\n\n" +
				"🟠  Seus sats continuam intactos.\n" +
				"1 sat = 1 sat. Sempre."
			)
			_btn_investir.disabled = true
			_btn_recusar.text = "Entendido"

	_lbl_reais.text = "💵  Saldo em reais: R$ %s" % _fmt(_reais)

func _on_investir() -> void:
	_rounds += 1
	if _rounds >= 3:
		_reais = 0.0
		SaveSystem.set_value("ulrich_reais",  0.0)
		SaveSystem.set_value("ulrich_rounds", 3)
	else:
		# nominal "rendimento" que será anulado
		_reais *= 1.08
		SaveSystem.set_value("ulrich_reais",  _reais)
		SaveSystem.set_value("ulrich_rounds", _rounds)
	_refresh_ui()

func _on_recusar() -> void:
	emit_signal("event_closed")
	queue_free()

func _fmt(v: float) -> String:
	if v <= 0.0: return "0,00"
	return "%.2f" % v
