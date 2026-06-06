## battle_manager.gd
## AutoLoad — gerencia o estado da batalha turn-based estilo Pokémon.
## A cena BattleScene.tscn conecta a este manager via sinais.

extends Node

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal battle_started(enemy_data: Dictionary)
signal battle_ended(result: String)   # "victory" | "defeat" | "escaped"
signal player_turn_started
signal enemy_turn_started
signal action_resolved(log_text: String)
signal hp_changed(who: String, new_hp: int, max_hp: int)

# ─── Enums ────────────────────────────────────────────────────────────────────
enum State { IDLE, PLAYER_TURN, ENEMY_TURN, RESOLVING, ENDED }
enum Action { ATTACK, ITEM, STEALTH, PERSUADE, RUN }

# ─── Estado da batalha ────────────────────────────────────────────────────────
var state:   State = State.IDLE
var locked:  bool  = false               # true durante mini-games — bloqueia novas batalhas
var enemy_data: Dictionary = {}          # nome, hp, max_hp, atk, reward_sats, boss_id
var enemy_hp: int = 0
var player_hp: int = 100
var player_max_hp: int = 100
var _battle_log: Array[String] = []
var _is_boss: bool = false
var _escape_attempts: int = 0

# ─── API pública ──────────────────────────────────────────────────────────────

func start_battle(data: Dictionary) -> void:
	if state != State.IDLE or locked:
		return
	enemy_data      = data
	enemy_hp        = data.get("hp", 50)
	_is_boss        = data.get("is_boss", false)
	_escape_attempts = 0

	# HP do player baseado em stats
	var vitality: int = PlayerStats.get_stat("furtividade") + PlayerStats.get_stat("persuasao")
	player_max_hp = 80 + vitality * 10
	player_hp     = player_max_hp

	_battle_log.clear()
	state = State.PLAYER_TURN
	AutonomyBar.set_active(false)
	AudioManager.music("boss" if _is_boss else "battle")
	emit_signal("battle_started", enemy_data)
	emit_signal("hp_changed", "player", player_hp, player_max_hp)
	emit_signal("hp_changed", "enemy", enemy_hp, enemy_data.get("hp", 50))
	await get_tree().create_timer(0.3).timeout
	emit_signal("player_turn_started")

func player_action(action: Action, item_id: String = "") -> void:
	if state != State.PLAYER_TURN:
		return
	state = State.RESOLVING
	match action:
		Action.ATTACK:   await _resolve_attack()
		Action.ITEM:     await _resolve_item(item_id)
		Action.STEALTH:  await _resolve_stealth()
		Action.PERSUADE: await _resolve_persuade()
		Action.RUN:      await _resolve_run()

func get_log() -> Array[String]:
	return _battle_log.duplicate()

# ─── Resoluções ───────────────────────────────────────────────────────────────

func _resolve_attack() -> void:
	var base_dmg: int = 15 + randi() % 10
	# Fraqueza: item certo causa +50% de dano
	var weakness: String = enemy_data.get("weakness_item", "")
	if not weakness.is_empty() and PlayerInventory.active_item == weakness:
		base_dmg = int(base_dmg * 1.5)
		_log("🎯  Fraqueza explorada! Dano aumentado.")
	enemy_hp -= base_dmg
	_log("⚔️  Você atacou! -%d HP do %s." % [base_dmg, enemy_data.get("name", "Inimigo")])
	emit_signal("hp_changed", "enemy", maxi(enemy_hp, 0), enemy_data.get("hp", 50))
	emit_signal("action_resolved", _battle_log[-1])
	await get_tree().create_timer(0.6).timeout
	if enemy_hp <= 0:
		await _resolve_victory()
	else:
		await _enemy_turn()

func _resolve_item(item_id: String) -> void:
	if item_id.is_empty() or not PlayerInventory.can_use_item():
		_log("❌  Item não disponível agora.")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.4).timeout
		state = State.PLAYER_TURN
		emit_signal("player_turn_started")
		return
	PlayerInventory.use_active_item()
	var effect := _apply_item_effect(item_id)
	_log(effect)
	emit_signal("action_resolved", _battle_log[-1])
	await get_tree().create_timer(0.6).timeout
	if enemy_hp <= 0:
		await _resolve_victory()
	else:
		await _enemy_turn()

func _apply_item_effect(item_id: String) -> String:
	match item_id:
		"item_spray":
			var dmg := 30
			enemy_hp -= dmg
			emit_signal("hp_changed", "enemy", maxi(enemy_hp, 0), enemy_data.get("hp", 50))
			return "🧴  Spray repelente! -%d HP!" % dmg
		"item_camera":
			var dmg := 25
			enemy_hp -= dmg
			emit_signal("hp_changed", "enemy", maxi(enemy_hp, 0), enemy_data.get("hp", 50))
			return "📷  Câmera expõe o inimigo! -%d HP!" % dmg
		"item_panfleto":
			player_hp = mini(player_hp + 20, player_max_hp)
			emit_signal("hp_changed", "player", player_hp, player_max_hp)
			return "📄  Panfleto educativo! +20 HP recuperado."
		"item_chave":
			_escape_attempts = 99   # força fuga
			return "🔑  Chave secreta — rota de fuga aberta!"
		"item_radio":
			var dmg := 20
			enemy_hp -= dmg
			emit_signal("hp_changed", "enemy", maxi(enemy_hp, 0), enemy_data.get("hp", 50))
			return "📻  Sinal de rádio confunde o inimigo! -%d HP!" % dmg
		_:
			return "❓  Item sem efeito aqui."

func _resolve_stealth() -> void:
	var stealth: int = PlayerStats.get_stat("furtividade")
	var chance := 30 + stealth * 15   # 30% base + 15% por nível
	if _is_boss:
		chance = int(chance * 0.4)    # muito difícil furtividade em boss
	if randi() % 100 < chance:
		_log("👁️  Furtividade! Você passou sem ser visto.")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.8).timeout
		await _resolve_escaped()
	else:
		_log("👁️  Furtividade falhou — detectado!")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.5).timeout
		await _enemy_turn()

func _resolve_persuade() -> void:
	var persuasao: int = PlayerStats.get_stat("persuasao")
	var cost_sats: int = enemy_data.get("bribe_cost", 30)
	if persuasao >= 2 and SatEconomy.current_sats >= cost_sats:
		SatEconomy.remove_sats(cost_sats, "persuasao_battle")
		_log("🗣️  Persuasão! -%d sats — inimigo convencido." % cost_sats)
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.8).timeout
		await _resolve_escaped()
	elif persuasao >= 1:
		var dmg_reduction := 5
		var enemy_atk := maxi(1, enemy_data.get("atk", 15) - dmg_reduction)
		_log("🗣️  Persuasão parcial — dano reduzido.")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.5).timeout
		await _enemy_turn()
	else:
		_log("🗣️  Sem persuasão suficiente!")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.4).timeout
		await _enemy_turn()

func _resolve_run() -> void:
	if _is_boss:
		_log("🚫  Não pode fugir de um chefe!")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.4).timeout
		state = State.PLAYER_TURN
		emit_signal("player_turn_started")
		return
	_escape_attempts += 1
	var chance := 40 + _escape_attempts * 15
	if randi() % 100 < chance:
		_log("🏃  Fugiu com sucesso!")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.6).timeout
		await _resolve_escaped()
	else:
		_log("🏃  Fuga falhou!")
		emit_signal("action_resolved", _battle_log[-1])
		await get_tree().create_timer(0.5).timeout
		await _enemy_turn()

# ─── Turno do inimigo ─────────────────────────────────────────────────────────

func _enemy_turn() -> void:
	if state == State.ENDED:
		return
	state = State.ENEMY_TURN
	emit_signal("enemy_turn_started")
	await get_tree().create_timer(0.8).timeout

	var atk: int = enemy_data.get("atk", 15) + randi() % 8
	# Redução por furtividade passiva
	var stealth_mitigation := PlayerStats.get_stat("furtividade") * 2
	atk = maxi(1, atk - stealth_mitigation)

	player_hp -= atk
	AutonomyBar.consume("energy", 8.0)
	_log("⚠️  %s ataca! -%d HP." % [enemy_data.get("name", "Inimigo"), atk])
	emit_signal("hp_changed", "player", maxi(player_hp, 0), player_max_hp)
	emit_signal("action_resolved", _battle_log[-1])

	await get_tree().create_timer(0.6).timeout
	if player_hp <= 0:
		await _resolve_defeat()
	else:
		state = State.PLAYER_TURN
		emit_signal("player_turn_started")

# ─── Resultados ───────────────────────────────────────────────────────────────

func _resolve_victory() -> void:
	state = State.ENDED
	var reward: int = enemy_data.get("reward_sats", 20)
	SatEconomy.add_sats(reward, "battle_victory")
	if _is_boss:
		WorldManager.record_boss_defeated()
	AutonomyBar.set_active(true)
	AudioManager.music("dungeon")
	_log("🏆  Vitória! +%d sats." % reward)
	emit_signal("action_resolved", _battle_log[-1])
	await get_tree().create_timer(0.5).timeout
	emit_signal("battle_ended", "victory")

func _resolve_defeat() -> void:
	state = State.ENDED
	AutonomyBar.set_active(true)
	AudioManager.music("game_over")
	_log("💀  Derrotado...")
	emit_signal("action_resolved", _battle_log[-1])
	await get_tree().create_timer(0.5).timeout
	emit_signal("battle_ended", "defeat")

func _resolve_escaped() -> void:
	state = State.ENDED
	AutonomyBar.set_active(true)
	AudioManager.music("dungeon")
	emit_signal("battle_ended", "escaped")

func reset() -> void:
	state = State.IDLE
	enemy_data = {}
	enemy_hp = 0
	_battle_log.clear()
	_escape_attempts = 0

# ─── Utilitário ───────────────────────────────────────────────────────────────
func _log(text: String) -> void:
	_battle_log.append(text)
	if OS.is_debug_build():
		print("[Battle] ", text)
