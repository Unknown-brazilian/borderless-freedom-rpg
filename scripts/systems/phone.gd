## phone.gd  (AutoLoad: Phone)
## O celular do jogador — disponível desde o começo.
## Guarda as notificações da Wallet of Satoshi e abre o mapa/jornada (estilo Pokédex).

extends Node

signal notification_added(entry: Dictionary)

# Cada entrada: {"from": String, "msg": String, "sats": int}
var notifications: Array = []

func _ready() -> void:
	# Notificação de boas-vindas.
	notifications.append({
		"from": "Wallet of Satoshi",
		"msg": "Carteira criada. ⚡ Receba sats de qualquer lugar.",
		"sats": 0,
	})

## Registra uma notificação (doações, suporte, etc.).
func notify(from_who: String, msg: String, sats: int = 0) -> void:
	var entry := {"from": from_who, "msg": msg, "sats": sats}
	notifications.push_front(entry)
	emit_signal("notification_added", entry)
	if is_instance_valid(AudioManager):
		AudioManager.sfx("coin" if sats > 0 else "menu_click")

# ─── Doações periódicas da comunidade Bitcoin BR (via Wallet of Satoshi) ───────
# Apoiadores: seguidores de @unknown_btc_usr (nomes fornecidos pelo autor; não
# tenho acesso aos dados reais de interação do Twitter para ranquear).
const SUPPORTERS := [
	"Jeff", "Victor Visão Libertária", "@mk3zeus", "Hugo Ramos",
	"@unknown_btc_usr fam", "Satoshito BR",
]
const DONATION_MSGS := [
	"Vai com tudo, dissidente! Bitcoin fixes this. ⚡",
	"Tamo junto na jornada. Não confia em ninguém, verifica.",
	"Toma uns sats pra estrada. HODL!",
	"Respeito quem corre atrás da liberdade. 🧡",
	"Stay humble, stack sats.",
	"Esse é o caminho. Sovereign individual!",
]
const DONATION_FIRST_SEC := 240.0    # primeira doação ~4 min (pra ser vista)
const DONATION_INTERVAL_SEC := 7200.0  # depois, ~a cada 2h (ajustável)

var _don_accum: float = 0.0
var _don_first_done: bool = false

func _process(delta: float) -> void:
	# Só conta tempo de jogo ativo (não durante batalha/diálogo/menu).
	if BattleManager.state != BattleManager.State.IDLE or DialogueManager.is_active():
		return
	if get_tree().get_first_node_in_group("player") == null:
		return
	_don_accum += delta
	var target := DONATION_FIRST_SEC if not _don_first_done else DONATION_INTERVAL_SEC
	if _don_accum >= target:
		_don_accum = 0.0
		_don_first_done = true
		_send_donation()

func _send_donation() -> void:
	var sup: String = SUPPORTERS[randi() % SUPPORTERS.size()]
	var msg: String = DONATION_MSGS[randi() % DONATION_MSGS.size()]
	var sats: int = [100, 200, 300, 500, 1000][randi() % 5]
	SatEconomy.add_sats(sats, "donation")
	notify(sup, msg, sats)
	var scene := get_tree().current_scene
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and is_instance_valid(scene):
		Juice.float_text(scene, player.position + Vector2(0, -90),
			"⚡ +%d sats — %s" % [sats, sup], Color(0.4, 0.9, 0.5), 30)

## O celular foi roubado (D6) e ainda não recuperado?
func is_available() -> bool:
	return not (WorldManager.get_flag("phone_robbery", false) \
		and not WorldManager.get_flag("phone_recovered", false))

## Abre a UI do celular na cena atual.
func open() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.get_node_or_null("PhoneUI") != null:
		return
	var ui := CanvasLayer.new()
	ui.name = "PhoneUI"
	ui.set_script(load("res://scripts/ui/phone_ui.gd"))
	scene.add_child(ui)
