## sat_economy.gd
## Borderless Freedom: A Dissident Adventure
## Gerencia o stack de Satoshis do player — a moeda do jogo
##
## AutoLoad: adicione como "SatEconomy" em Project > Project Settings > AutoLoad
## Princípio: 1 sat = 1 sat. Sem inflação. Sem degradação de valor.

extends Node

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal sats_changed(new_total: int, delta: int)
signal sats_milestone_reached(milestone: int)

# ─── Estado ───────────────────────────────────────────────────────────────────
var current_sats: int = 0
var lifetime_earned: int = 0   # total ganho em toda a jornada
var lifetime_lost: int = 0     # total perdido (scams, chefes, etc.)

const MILESTONES := [100, 500, 1000, 5000, 10000, 21000, 100000]
var _milestones_reached: Array = []

# ─── API pública ──────────────────────────────────────────────────────────────

func add_sats(amount: int, source: String = "") -> void:
	if amount <= 0:
		return
	var actual_amount := amount
	if RandomEventsSystem:
		actual_amount = int(amount * RandomEventsSystem.get_recovery_sat_multiplier())
	current_sats += actual_amount
	lifetime_earned += actual_amount

	if source and OS.is_debug_build():
		print("[SatEconomy] +%d sats (%s). Total: %d" % [actual_amount, source, current_sats])

	emit_signal("sats_changed", current_sats, actual_amount)
	_check_milestones()

	# Avisa o RandomEventsSystem com o valor base (sem boost) para medir trabalho real
	if RandomEventsSystem:
		RandomEventsSystem.notify_sats_earned(amount)

func remove_sats(amount: int, source: String = "") -> int:
	if amount <= 0:
		return 0
	var actual_loss: int = mini(amount, current_sats)
	current_sats -= actual_loss
	lifetime_lost += actual_loss

	if source:
		if OS.is_debug_build():
			print("[SatEconomy] -%d sats (%s). Total: %d" % [actual_loss, source, current_sats])
		if _is_fiscal_source(source) and GameStats:
			GameStats.record_fiscal()

	emit_signal("sats_changed", current_sats, -actual_loss)
	return actual_loss

## Detecta pagamentos a autoridades fiscais pelo padrão do source.
func _is_fiscal_source(source: String) -> bool:
	const FISCAL_KEYWORDS := [
		"blitz", "checkin", "checkpoint", "cbp", "migracao",
		"pedagio", "patrol", "patrulha", "fiscal", "guarda",
		"voo_controle", "posto_", "toll_", "vistoria", "inspetor",
		"policia", "coca_cheque", "bloqueio", "inm_", "cartel",
		"eu_check", "check_"
	]
	for keyword in FISCAL_KEYWORDS:
		if source.contains(keyword):
			return true
	return false

func get_stats() -> Dictionary:
	return {
		"current": current_sats,
		"lifetime_earned": lifetime_earned,
		"lifetime_lost": lifetime_lost,
		"net": lifetime_earned - lifetime_lost
	}

# ─── Persistência ─────────────────────────────────────────────────────────────
func save() -> Dictionary:
	return {
		"current_sats": current_sats,
		"lifetime_earned": lifetime_earned,
		"lifetime_lost": lifetime_lost,
		"milestones_reached": _milestones_reached
	}

func load_from(data: Dictionary) -> void:
	current_sats       = data.get("current_sats", 0)
	lifetime_earned    = data.get("lifetime_earned", 0)
	lifetime_lost      = data.get("lifetime_lost", 0)
	_milestones_reached = data.get("milestones_reached", [])

# ─── Milestones ───────────────────────────────────────────────────────────────
func _check_milestones() -> void:
	for milestone in MILESTONES:
		if current_sats >= milestone and milestone not in _milestones_reached:
			_milestones_reached.append(milestone)
			emit_signal("sats_milestone_reached", milestone)
			if OS.is_debug_build():
				print("[SatEconomy] Marco alcançado: %d sats!" % milestone)
