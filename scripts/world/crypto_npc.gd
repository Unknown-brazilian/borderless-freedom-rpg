## crypto_npc.gd
## NPC de scam cripto — aborda o player, apresenta pitch convincente SEM timeout.
## Filosofia: o jogador DEVE poder cair na armadilha para aprender.
## Após aceitar: perde sats + mostra revelação educacional.
## Após recusar: nota discreta "você teria perdido X sats".

extends CharacterBody2D

const APPROACH_RADIUS := 256.0   # distância para começar a se aproximar
const TALK_RADIUS     := 80.0    # distância para parar e falar
const APPROACH_SPEED  := 90.0
const WANDER_SPEED    := 50.0
const TILE_SIZE       := 64

enum State { WANDER, APPROACH, TALKING, DONE }

@export var event_id: String = "EVT-001"   # id em crypto_events.json

var _event_data:  Dictionary = {}
var _player:      Node       = null
var _state:       State      = State.WANDER
var _wander_dir:  Vector2    = Vector2.RIGHT
var _wander_timer: float     = 2.0
var _sprite:      ColorRect  = null
var _name_lbl:    Label      = null

func _ready() -> void:
	add_to_group("crypto_npc")
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)

	_load_event_data()
	_create_visuals()
	_player = get_tree().get_first_node_in_group("player")

	# Verificar se já foi ativado nesta sessão
	var done_key := "crypto_done_%s" % event_id
	if WorldManager.get_flag(done_key, false):
		_state = State.DONE
		queue_free()

func _load_event_data() -> void:
	var path := "res://data/crypto_events.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return
	var events: Array = parsed.get("random_events", [])
	for ev in events:
		if ev.get("id", "") == event_id:
			_event_data = ev
			return

func _create_visuals() -> void:
	# Aparência deliberadamente profissional — terno, azul corporativo.
	var img := Image.load_from_file("res://assets/sprites/npc_crypto.png")
	if img:
		var sh := ColorRect.new()
		sh.size = Vector2(40, 12)
		sh.position = Vector2(-20, 0)
		sh.color = Color(0, 0, 0, 0.25)
		sh.z_index = -1
		add_child(sh)
		var spr := Sprite2D.new()
		spr.texture  = ImageTexture.create_from_image(img)
		spr.scale    = Vector2(2.0, 2.0)
		spr.position = Vector2(0, -22)
		spr.modulate = Color(0.55, 0.7, 1.0).lerp(Color.WHITE, 0.4)
		add_child(spr)
	else:
		_sprite = ColorRect.new()
		_sprite.size = Vector2(44, 44)
		_sprite.position = Vector2(-22, -38)
		_sprite.color = Color(0.25, 0.45, 0.75)
		add_child(_sprite)

	_name_lbl = Label.new()
	_name_lbl.text = _event_data.get("short_name", "Investidor")
	_name_lbl.position = Vector2(-52, -68)
	_name_lbl.add_theme_font_size_override("font_size", 17)
	_name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	add_child(_name_lbl)

	# Badge verde "✓ Verificado" para parecer legítimo
	var badge := Label.new()
	badge.text = "✓ Verificado"
	badge.position = Vector2(-40, -50)
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3))
	add_child(badge)

func _physics_process(delta: float) -> void:
	match _state:
		State.WANDER:   _process_wander(delta)
		State.APPROACH: _process_approach(delta)
		_:
			velocity = Vector2.ZERO
			move_and_slide()

func _process_wander(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	# Verifica distância para abordar
	var dist: float = position.distance_to(_player.position)
	if dist <= APPROACH_RADIUS:
		_state = State.APPROACH
		return

	# Wander aleatório
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 3.5)
		_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	velocity = _wander_dir * WANDER_SPEED
	move_and_slide()

func _process_approach(delta: float) -> void:
	if not is_instance_valid(_player):
		_state = State.WANDER
		return
	if DialogueManager.is_active() or BattleManager.state != BattleManager.State.IDLE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist: float = position.distance_to(_player.position)
	if dist > APPROACH_RADIUS * 1.5:
		_state = State.WANDER
		return

	if dist < TALK_RADIUS:
		_state = State.TALKING
		velocity = Vector2.ZERO
		move_and_slide()
		_present_offer()
		return

	velocity = (_player.position - position).normalized() * APPROACH_SPEED
	move_and_slide()

func _present_offer() -> void:
	if _event_data.is_empty():
		return
	if _player.has_method("set_can_move"):
		_player.set_can_move(false)

	# Linha de abertura — aparência de networking casual
	var opener := "💼  %s: \"Ei, %s! Tenho uma oportunidade que vai te interessar. Só um minuto.\"\n[Toque para continuar]" % [
		_event_data.get("short_name", "Investidor"),
		PlayerStats.player_name
	]
	DialogueManager.start([opener])
	await DialogueManager.dialogue_finished

	# Mostra a UI de oferta — sem timeout
	var offer_ui := preload("res://scenes/ui/CryptoOfferUI.tscn").instantiate()
	get_tree().current_scene.add_child(offer_ui)
	offer_ui.show_offer(_event_data)
	offer_ui.offer_accepted.connect(_on_accepted, CONNECT_ONE_SHOT)
	offer_ui.offer_refused.connect(_on_refused, CONNECT_ONE_SHOT)

func _on_accepted(_id: String) -> void:
	var loss_pct: float  = float(_event_data.get("accept_outcome", {}).get("loss_percent", 80)) / 100.0
	var cap_pct:  float  = float(_event_data.get("accept_outcome", {}).get("loss_cap_percent", 50)) / 100.0
	var current:  int    = SatEconomy.current_sats
	var loss:     int    = int(min(current * loss_pct, current * cap_pct))
	loss = max(loss, 1)

	SatEconomy.remove_sats(loss, "crypto_scam_%s" % event_id)

	var headline: String = _event_data.get("accept_outcome", {}).get("news_headline", "Seus sats foram perdidos.")
	var headline2: String = _event_data.get("accept_outcome", {}).get("news_headline_2", "")

	var reveal_lines: Array[String] = []
	reveal_lines.append("📰  NOTÍCIA: \"%s\"" % headline)
	if not headline2.is_empty():
		reveal_lines.append("📰  \"%s\"" % headline2)
	reveal_lines.append("💸  Você perdeu %d sats." % loss)
	reveal_lines.append("📖  Lição: Not your keys, not your coins.")

	DialogueManager.start(reveal_lines)
	await DialogueManager.dialogue_finished
	_mark_done()

func _on_refused(_id: String) -> void:
	var loss_pct: float = float(_event_data.get("accept_outcome", {}).get("loss_percent", 80)) / 100.0
	var cap_pct:  float = float(_event_data.get("accept_outcome", {}).get("loss_cap_percent", 50)) / 100.0
	var current:  int   = SatEconomy.current_sats
	var would_lose: int = int(min(current * loss_pct, current * cap_pct))

	var ignore_msg: String = _event_data.get("ignore_outcome", {}).get("message", "")
	ignore_msg = ignore_msg.replace("{lost_sats}", str(would_lose))
	ignore_msg = ignore_msg.replace("{lost_pct}", str(int(cap_pct * 100)))

	# Nota discreta — não é celebração
	var lines: Array[String] = []
	if not ignore_msg.is_empty():
		lines.append(ignore_msg)
	else:
		lines.append("Você recusou. Você teria perdido %d sats." % would_lose)

	var lesson: String = _event_data.get("ignore_outcome", {}).get("lesson", "")
	if not lesson.is_empty():
		lines.append("📖  " + lesson)

	# Bônus discreto por recusar
	var bonus_pct: float = float(_event_data.get("ignore_outcome", {}).get("sat_bonus_percent", 5)) / 100.0
	if bonus_pct > 0.0:
		var bonus: int = max(1, int(current * bonus_pct))
		SatEconomy.add_sats(bonus, "crypto_refused_bonus")

	DialogueManager.start(lines)
	await DialogueManager.dialogue_finished
	_mark_done()

func _mark_done() -> void:
	WorldManager.set_flag("crypto_done_%s" % event_id, true)
	_state = State.DONE
	if is_instance_valid(_player) and _player.has_method("set_can_move"):
		_player.set_can_move(true)
	queue_free()
