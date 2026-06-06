## player_stats.gd
## Borderless Freedom: A Dissident Adventure
## AutoLoad — stats base do player e upgrades comprados com sats.
##
## Stats do GDD:
##   velocidade   base 3  max 10
##   resistencia  base 5  max 10
##   carga        base 3  max 10
##   furtividade  base 2  max 10
##   persuasao    base 3  max 10
##
## Custo de upgrade: 50 * nivel_alvo sats (ex: 3→4 custa 200 sats).
## Desbloqueios por fase (sem custo) usam unlock_stat().

extends Node

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal stat_upgraded(stat_name: String, new_value: int)
signal stat_unlocked(stat_name: String, new_value: int)
signal upgrade_failed(stat_name: String, reason: String)

# ─── Definição dos stats ──────────────────────────────────────────────────────
const STAT_DEFS: Dictionary = {
	"velocidade":  {"base": 3, "max": 10},
	"resistencia": {"base": 5, "max": 10},
	"carga":       {"base": 3, "max": 10},
	"furtividade": {"base": 2, "max": 10},
	"persuasao":   {"base": 3, "max": 10},
}

# Custo em sats: 50 × nivel_alvo
const UPGRADE_COST_MULTIPLIER: int = 50

# ─── Estado ───────────────────────────────────────────────────────────────────
var player_name: String = "Dissidente"   # definido na tela inicial; nunca hardcoded
var _stats: Dictionary = {}

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	_reset_to_base()

# ─── API pública — leitura ────────────────────────────────────────────────────

## Retorna o valor atual de um stat. Retorna -1 se o nome for inválido.
func get_stat(stat_name: String) -> int:
	return _stats.get(stat_name, -1)

## Verifica se o stat atinge o mínimo exigido (usado pelo sistema de diálogo).
## Exemplo: stat_check("persuasao", 3)
func stat_check(stat_name: String, min_value: int) -> bool:
	return get_stat(stat_name) >= min_value

## Retorna o custo em sats para o próximo nível do stat.
## Retorna -1 se o stat já estiver no máximo ou não existir.
func get_upgrade_cost(stat_name: String) -> int:
	if not STAT_DEFS.has(stat_name):
		return -1
	var current: int = _stats.get(stat_name, 0)
	if current >= STAT_DEFS[stat_name]["max"]:
		return -1
	return UPGRADE_COST_MULTIPLIER * (current + 1)

## Retorna um dicionário com todos os stats atuais (para o HUD/menu de upgrades).
func get_all_stats() -> Dictionary:
	return _stats.duplicate()

# ─── API pública — escrita ────────────────────────────────────────────────────

## Tenta comprar um upgrade com sats. Retorna true se bem-sucedido.
func upgrade_stat(stat_name: String) -> bool:
	if not STAT_DEFS.has(stat_name):
		emit_signal("upgrade_failed", stat_name, "stat_invalido")
		return false

	var current: int = _stats.get(stat_name, 0)
	var max_val: int = STAT_DEFS[stat_name]["max"]

	if current >= max_val:
		emit_signal("upgrade_failed", stat_name, "ja_no_maximo")
		return false

	var cost: int = UPGRADE_COST_MULTIPLIER * (current + 1)
	if SatEconomy.current_sats < cost:
		emit_signal("upgrade_failed", stat_name, "sats_insuficientes")
		return false

	SatEconomy.remove_sats(cost, "upgrade_%s" % stat_name)
	_stats[stat_name] = current + 1
	emit_signal("stat_upgraded", stat_name, _stats[stat_name])
	return true

## Define um stat diretamente — para desbloqueios via fase, sem custo.
## Nunca reduz abaixo do valor atual nem acima do máximo.
func unlock_stat(stat_name: String, value: int) -> void:
	if not STAT_DEFS.has(stat_name):
		return
	var clamped: int = clampi(value, _stats.get(stat_name, 0), STAT_DEFS[stat_name]["max"])
	if clamped > _stats.get(stat_name, 0):
		_stats[stat_name] = clamped
		emit_signal("stat_unlocked", stat_name, clamped)

## Reseta todos os stats para os valores base (usado em deportação — D7).
## Chame com partial=true para o reset parcial do GDD (perde metade dos ganhos).
func reset(partial: bool = false) -> void:
	if partial:
		for stat in STAT_DEFS:
			var base: int  = STAT_DEFS[stat]["base"]
			var current: int = _stats.get(stat, base)
			# Mantém metade dos ganhos acima da base, arredondado para baixo
			_stats[stat] = base + (current - base) / 2
	else:
		_reset_to_base()

# ─── Persistência ─────────────────────────────────────────────────────────────
func save() -> Dictionary:
	return {"player_name": player_name, "stats": _stats.duplicate()}

func load_from(data: Dictionary) -> void:
	player_name = data.get("player_name", "Dissidente")
	var saved: Dictionary = data.get("stats", {})
	_reset_to_base()
	for stat in saved:
		if STAT_DEFS.has(stat):
			_stats[stat] = clampi(
				saved[stat],
				STAT_DEFS[stat]["base"],
				STAT_DEFS[stat]["max"]
			)

# ─── Interno ──────────────────────────────────────────────────────────────────
func _reset_to_base() -> void:
	for stat in STAT_DEFS:
		_stats[stat] = STAT_DEFS[stat]["base"]
