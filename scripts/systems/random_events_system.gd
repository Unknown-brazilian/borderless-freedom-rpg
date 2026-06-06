## random_events_system.gd
## Borderless Freedom: A Dissident Adventure
## Sistema de eventos aleatórios crypto — rugpulls, quebras de corretoras, shitcoins
##
## Como usar:
##   1. Adicione este script como AutoLoad em Project > Project Settings > AutoLoad
##      Nome: RandomEventsSystem
##   2. Conecte o sinal event_triggered à sua cena de HUD/UI
##   3. Chame RandomEventsSystem.check_for_event(current_dungeon) a cada fase

extends Node

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal event_triggered(event_data: Dictionary)
signal event_resolved(event_id: String, player_chose_accept: bool, sats_impact: int)
signal recovery_mode_started(sats_lost: int)
signal recovery_mode_ended()
signal recovery_progress_changed(recovered: int, needed: int)
signal streak_reward_earned(reward_data: Dictionary)
signal glossary_entry_unlocked(entry_id: String)

# ─── Constantes ───────────────────────────────────────────────────────────────
const DATA_PATH := "res://data/crypto_events.json"
const WINDOW_SECONDS := 8.0
const DEFAULT_ACTION := "ignore"  # se o timer acabar sem escolha → ignora

# ─── Estado interno ───────────────────────────────────────────────────────────
var _events: Array = []
var _recovery_config: Dictionary = {}
var _streak_config: Dictionary = {}
var _glossary: Dictionary = {}
var _unlocked_glossary: Array[String] = []

var _current_dungeon: int = 1
var _avoid_streak: int = 0          # quantos eventos seguidos o player evitou
var _total_avoided: int = 0         # total de eventos evitados no jogo inteiro
var _total_accepted: int = 0        # total de eventos aceitos (perdeu dinheiro)
var _pending_delayed_events: Array = []  # eventos com delay (ex: FTXpress D+2)

var is_in_recovery_mode: bool = false
var _sats_lost_in_recovery: int = 0
var _sats_recovered: int = 0

# Referência ao sistema de sats (SatEconomy AutoLoad)
# Definido em sat_economy.gd — certifique-se de que está no AutoLoad
@onready var _sat_economy = get_node_or_null("/root/SatEconomy")

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_event_data()
	if OS.is_debug_build():
		print("[RandomEvents] Sistema inicializado. %d eventos carregados." % _events.size())

func _load_event_data() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if not file:
		push_error("[RandomEvents] Não foi possível abrir %s" % DATA_PATH)
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[RandomEvents] Erro ao parsear JSON: %s" % json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	_events            = data.get("random_events", [])
	_recovery_config   = data.get("recovery_mode", {})
	_streak_config     = data.get("streak_rewards", {})
	_glossary          = data.get("glossary", {})

# ─── API pública ──────────────────────────────────────────────────────────────

## Chame isso ao entrar em cada nova fase.
## current_dungeon: número da dungeon atual (1–9)
func check_for_event(current_dungeon: int) -> void:
	_current_dungeon = current_dungeon
	_process_delayed_events()

	var eligible := _get_eligible_events(current_dungeon)
	if eligible.is_empty():
		return

	for event in eligible:
		var probability := _calculate_probability(event, current_dungeon)
		if randf() <= probability:
			_trigger_event(event)
			return  # apenas 1 evento por fase

## Chame isso quando o player toma uma decisão na janela do evento.
## event_id: ID do evento (ex: "EVT-001")
## accepted: true se o player clicou em aceitar, false se ignorou ou o timer acabou
func resolve_event(event_id: String, accepted: bool) -> void:
	var event := _find_event_by_id(event_id)
	if event.is_empty():
		push_error("[RandomEvents] Evento não encontrado: %s" % event_id)
		return

	if accepted:
		_handle_accept(event)
	else:
		_handle_ignore(event)

## Chame isso quando o player recuperar sats (entregas, consertos de ASIC, etc.)
## amount: quantidade de sats recuperados nessa ação
func notify_sats_earned(amount: int) -> void:
	if not is_in_recovery_mode:
		return

	_sats_recovered += amount
	var needed := maxi(int(_sats_lost_in_recovery * 0.5), 1)

	emit_signal("recovery_progress_changed", _sats_recovered, needed)

	if _sats_recovered >= needed:
		_exit_recovery_mode()

## Retorna uma mensagem motivacional aleatória do modo de recuperação
func get_recovery_message() -> String:
	var messages: Array = _recovery_config.get("messages", [])
	if messages.is_empty():
		return "Trabalha. Recupera. Hodl."
	return messages[randi() % messages.size()]

## Retorna o texto completo de um verbete do glossário
func get_glossary_entry(entry_id: String) -> Dictionary:
	return _glossary.get(entry_id, {})

## Retorna o multiplicador de sats durante recovery mode (1.0 se não está em recovery).
func get_recovery_sat_multiplier() -> float:
	if not is_in_recovery_mode:
		return 1.0
	return _recovery_config.get("sat_boost_multiplier", 1.5)

# ─── Lógica interna ───────────────────────────────────────────────────────────

func _get_eligible_events(dungeon: int) -> Array:
	var eligible := []
	for event in _events:
		var min_d: int = event.get("trigger_dungeon_min", 1)
		var max_d: int = event.get("trigger_dungeon_max", 9)
		if dungeon >= min_d and dungeon <= max_d:
			eligible.append(event)
	return eligible

func _calculate_probability(event: Dictionary, dungeon: int) -> float:
	var base: float = event.get("base_probability", 0.08)

	# Aplica boost em dungeons específicas
	var boost_dungeons: Array = event.get("trigger_dungeon_boost", [])
	if dungeon in boost_dungeons:
		base *= float(event.get("boost_multiplier", 1.5))

	# Se player está em recovery_mode, eventos ficam mais frequentes
	if is_in_recovery_mode:
		base *= 2.0

	# Stack alto = alvo mais atraente (sharks smell blood)
	if _sat_economy and _sat_economy.current_sats > 5000:
		base *= 1.3

	return clampf(base, 0.0, 0.95)

func _trigger_event(event: Dictionary) -> void:
	if OS.is_debug_build():
		print("[RandomEvents] Evento disparado: %s" % event.get("id", "?"))
	emit_signal("event_triggered", event)
	# A UI (EventPopupUI) vai lidar com o timer e chamar resolve_event()

func _handle_accept(event: Dictionary) -> void:
	_total_accepted += 1
	_avoid_streak = 0  # quebra a sequência de evitados

	var outcome: Dictionary = event.get("accept_outcome", {})
	var delay_phases: int = outcome.get("delay_phases", 0)

	if delay_phases > 0:
		# Evento com delay — registra para ser processado depois
		_pending_delayed_events.append({
			"event": event,
			"trigger_at_phase_offset": delay_phases,
			"phases_remaining": delay_phases
		})
		if OS.is_debug_build():
			print("[RandomEvents] Evento %s aceito — prejuízo em %d fases." % [event.get("id"), delay_phases])
	else:
		# Prejuízo imediato
		_apply_loss(event, outcome)

func _handle_ignore(event: Dictionary) -> void:
	_total_avoided += 1
	_avoid_streak += 1

	var outcome: Dictionary = event.get("ignore_outcome", {})

	# Bônus de sats por ter evitado
	var bonus_pct: float = outcome.get("sat_bonus_percent", 5) / 100.0
	if _sat_economy:
		var bonus := int(_sat_economy.current_sats * bonus_pct)
		bonus = max(bonus, 10)  # mínimo 10 sats de bônus
		_sat_economy.add_sats(bonus)

	# Calcula quanto o player teria perdido (para exibir na mensagem)
	var accept_outcome: Dictionary = event.get("accept_outcome", {})
	var loss_pct: float = accept_outcome.get("loss_percent", 80) / 100.0
	var cap_pct: float  = accept_outcome.get("loss_cap_percent", 50) / 100.0
	var current_sats: int = _sat_economy.current_sats if _sat_economy else 1000
	var would_lose: int = int(minf(current_sats * loss_pct, current_sats * cap_pct))

	# Monta a mensagem final com os valores calculados
	var message: String = outcome.get("message", "Você evitou uma armadilha.")
	message = message.replace("{lost_sats}", str(would_lose))
	message = message.replace("{lost_pct}", "%.1f" % (float(would_lose) / float(current_sats) * 100.0))

	# Desbloqueia verbete do glossário
	var glossary_key: String = outcome.get("glossary_unlock", "")
	if not glossary_key.is_empty():
		if glossary_key not in _unlocked_glossary:
			_unlocked_glossary.append(glossary_key)
		emit_signal("glossary_entry_unlocked", glossary_key)

	emit_signal("event_resolved", event.get("id", ""), false, -would_lose)

	# Verifica recompensas de sequência
	_check_streak_rewards()

	if OS.is_debug_build():
		print("[RandomEvents] Evento %s evitado. Teria perdido %d sats." % [event.get("id"), would_lose])

func _apply_loss(event: Dictionary, outcome: Dictionary) -> void:
	if not _sat_economy:
		push_warning("[RandomEvents] SatEconomy não encontrado — perda não aplicada.")
		return

	var current_sats: int = _sat_economy.current_sats
	var loss_pct: float = outcome.get("loss_percent", 80) / 100.0
	var cap_pct: float  = outcome.get("loss_cap_percent", 50) / 100.0

	var loss_amount: int = maxi(int(minf(current_sats * loss_pct, current_sats * cap_pct)), 1)

	_sat_economy.remove_sats(loss_amount)
	_enter_recovery_mode(loss_amount)

	emit_signal("event_resolved", event.get("id", ""), true, loss_amount)
	if OS.is_debug_build():
		print("[RandomEvents] Perda aplicada: %d sats. Stack restante: %d" % [loss_amount, _sat_economy.current_sats])

func _process_delayed_events() -> void:
	var still_pending := []
	for entry in _pending_delayed_events:
		entry["phases_remaining"] -= 1
		if entry["phases_remaining"] <= 0:
			var event: Dictionary = entry["event"]
			var outcome: Dictionary = event.get("accept_outcome", {})
			_apply_loss(event, outcome)
			# Exibe notícia do colapso na UI
			var headline: String = outcome.get("news_headline", "A exchange faliu.")
			emit_signal("event_triggered", {
				"id": event.get("id") + "_COLLAPSE",
				"name": event.get("name"),
				"is_collapse_news": true,
				"headline": headline
			})
		else:
			still_pending.append(entry)
	_pending_delayed_events = still_pending

func _enter_recovery_mode(sats_lost: int) -> void:
	is_in_recovery_mode = true
	_sats_lost_in_recovery = sats_lost
	_sats_recovered = 0
	emit_signal("recovery_mode_started", sats_lost)
	if OS.is_debug_build():
		print("[RandomEvents] Modo de recuperação iniciado. Precisa recuperar %d sats." % int(sats_lost * 0.5))

func _exit_recovery_mode() -> void:
	is_in_recovery_mode = false
	_sats_lost_in_recovery = 0
	_sats_recovered = 0
	emit_signal("recovery_mode_ended")
	if OS.is_debug_build():
		print("[RandomEvents] Modo de recuperação encerrado. Stack estabilizado.")

func _check_streak_rewards() -> void:
	var rewards: Dictionary = _streak_config

	# Verifica evitar todos do jogo (precisa checar depois de terminar)
	# Isso é verificado em save_game() ou na tela de fim de jogo

	if _avoid_streak == 3:
		var reward: Dictionary = rewards.get("avoid_3_in_row", {})
		_grant_streak_reward(reward, "Olhos Abertos")

	elif _avoid_streak == 5:
		var reward: Dictionary = rewards.get("avoid_5_in_row", {})
		_grant_streak_reward(reward, "Dissidente Financeiro")

func _grant_streak_reward(reward: Dictionary, title: String) -> void:
	if reward.is_empty() or not _sat_economy:
		return

	var bonus_pct: float = reward.get("reward_sats_percent", 10) / 100.0
	var bonus := int(_sat_economy.current_sats * bonus_pct)
	bonus = max(bonus, 50)
	_sat_economy.add_sats(bonus)

	var message: String = reward.get("message", "Bônus desbloqueado!")
	message = message.replace("{sats}", str(bonus))

	emit_signal("streak_reward_earned", {
		"title": title,
		"message": message,
		"sats_bonus": bonus
	})

func _find_event_by_id(event_id: String) -> Dictionary:
	for event in _events:
		if event.get("id", "") == event_id:
			return event
	return {}

# ─── Checagem de sovereign individual (chamar no save/fim de jogo) ─────────────
func check_sovereign_individual() -> bool:
	return _total_accepted == 0 and _total_avoided > 0

## Chamado por DungeonManager._trigger_ending() quando sovereign = true.
## Concede o bônus de +50% sats silenciosamente — a tela de ending exibe o total.
func grant_sovereign_ending_bonus() -> void:
	if not _sat_economy:
		return
	var reward: Dictionary = _streak_config.get("avoid_all_game", {})
	var bonus_pct: float = reward.get("reward_sats_percent", 50) / 100.0
	var bonus := int(_sat_economy.current_sats * bonus_pct)
	bonus = max(bonus, 100)
	_sat_economy.add_sats(bonus, "sovereign_individual_bonus")

func get_stats() -> Dictionary:
	return {
		"total_avoided":       _total_avoided,
		"total_accepted":      _total_accepted,
		"current_streak":      _avoid_streak,
		"is_in_recovery":      is_in_recovery_mode,
		"sats_lost_recovery":  _sats_lost_in_recovery,
		"sats_recovered":      _sats_recovered,
		"sovereign_individual": check_sovereign_individual(),
		"unlocked_glossary":   _unlocked_glossary.duplicate(),
		"pending_delayed":     _pending_delayed_events.duplicate(true),
	}

func get_unlocked_glossary() -> Array[String]:
	return _unlocked_glossary.duplicate()

func unlock_glossary_entry(entry_id: String) -> void:
	if entry_id not in _unlocked_glossary:
		_unlocked_glossary.append(entry_id)
		emit_signal("glossary_entry_unlocked", entry_id)

func reset() -> void:
	_total_avoided         = 0
	_total_accepted        = 0
	_avoid_streak          = 0
	is_in_recovery_mode    = false
	_sats_lost_in_recovery = 0
	_sats_recovered        = 0
	_unlocked_glossary.clear()
	_pending_delayed_events.clear()

func load_from(data: Dictionary) -> void:
	_total_avoided         = int(data.get("total_avoided",      0))
	_total_accepted        = int(data.get("total_accepted",     0))
	_avoid_streak          = int(data.get("current_streak",     0))
	is_in_recovery_mode    = bool(data.get("is_in_recovery",    false))
	_sats_lost_in_recovery = int(data.get("sats_lost_recovery", 0))
	_sats_recovered        = int(data.get("sats_recovered",     0))
	_unlocked_glossary.clear()
	for entry in data.get("unlocked_glossary", []):
		_unlocked_glossary.append(str(entry))
	_pending_delayed_events = data.get("pending_delayed", [])
