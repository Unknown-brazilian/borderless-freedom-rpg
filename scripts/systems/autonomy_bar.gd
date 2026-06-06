## autonomy_bar.gd
## Borderless Freedom: A Dissident Adventure
## AutoLoad — gerencia os 3 recursos de sobrevivência do player.
##
## Cada recurso zerado aplica -20% de velocidade (até -60% com os 3).
## Quando os 3 recursos atingem 0 simultaneamente → all_resources_depleted
## (player "capturado" — aciona game over via player_controller).

extends Node

signal resource_changed(resource_name: String, value: float, max_value: float)
signal resource_depleted(resource_name: String)
signal resource_restored(resource_name: String)
signal all_resources_depleted

# ─── Configuração base ────────────────────────────────────────────────────────
const MAX_WATER:  float = 100.0
const MAX_FOOD:   float = 100.0
const MAX_ENERGY: float = 100.0

# Taxa de dreno passivo por segundo
@export var water_drain_rate:  float = 0.5
@export var food_drain_rate:   float = 0.3
@export var energy_drain_rate: float = 0.4

# Multiplicador aplicado em fases de deserto (D2, partes do D6)
var desert_multiplier: float = 1.0

# ─── Estado atual ─────────────────────────────────────────────────────────────
var water:  float = MAX_WATER
var food:   float = MAX_FOOD
var energy: float = MAX_ENERGY

# Rastreia quais recursos já estavam zerados (evita spam de sinal)
var _was_depleted: Dictionary = {
	"water": false,
	"food": false,
	"energy": false
}

var _active: bool = true   # falso durante menus / cutscenes

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	_active = true

# ─── Loop principal ───────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _active:
		return

	_drain("water",  water_drain_rate  * desert_multiplier * delta)
	_drain("food",   food_drain_rate   * desert_multiplier * delta)
	_drain("energy", energy_drain_rate * desert_multiplier * delta)

# ─── API pública ─────────────────────────────────────────────────────────────

## Retorna o multiplicador de velocidade para o player_controller.
## Cada recurso zerado reduz 20% (mínimo 0.40 com os 3 zerados).
func get_speed_multiplier() -> float:
	var penalty := 0.0
	if water  <= 0.0: penalty += 0.20
	if food   <= 0.0: penalty += 0.20
	if energy <= 0.0: penalty += 0.20
	return 1.0 - penalty

## Consome uma quantidade de um recurso (ações físicas, subidas, etc.).
func consume(resource_name: String, amount: float) -> void:
	_drain(resource_name, amount)

## Restaura um recurso (coletar item, descanso, descida de rampa).
func restore(resource_name: String, amount: float) -> void:
	match resource_name:
		"water":
			water  = minf(water  + amount, MAX_WATER)
			_check_restore("water")
			emit_signal("resource_changed", "water", water, MAX_WATER)
		"food":
			food   = minf(food   + amount, MAX_FOOD)
			_check_restore("food")
			emit_signal("resource_changed", "food", food, MAX_FOOD)
		"energy":
			energy = minf(energy + amount, MAX_ENERGY)
			_check_restore("energy")
			emit_signal("resource_changed", "energy", energy, MAX_ENERGY)

## Recarrega todos os recursos ao máximo (início de fase, checkpoint).
func refill_all() -> void:
	water  = MAX_WATER
	food   = MAX_FOOD
	energy = MAX_ENERGY
	_was_depleted["water"]  = false
	_was_depleted["food"]   = false
	_was_depleted["energy"] = false
	desert_multiplier = 1.0
	emit_signal("resource_changed", "water",  water,  MAX_WATER)
	emit_signal("resource_changed", "food",   food,   MAX_FOOD)
	emit_signal("resource_changed", "energy", energy, MAX_ENERGY)

## Pausa / retoma o dreno (menus, popups de evento, cutscenes).
func set_active(value: bool) -> void:
	_active = value

func is_active() -> bool:
	return _active

## Ativa o modificador de deserto (D2 altiplano, fases de sertão).
func set_desert_mode(enabled: bool) -> void:
	desert_multiplier = 2.0 if enabled else 1.0

## Snapshot para SaveSystem.
func get_save_data() -> Dictionary:
	return {"water": water, "food": food, "energy": energy}

## Restaura a partir de save.
func load_save_data(data: Dictionary) -> void:
	water  = data.get("water",  MAX_WATER)
	food   = data.get("food",   MAX_FOOD)
	energy = data.get("energy", MAX_ENERGY)
	_was_depleted["water"]  = water  <= 0.0
	_was_depleted["food"]   = food   <= 0.0
	_was_depleted["energy"] = energy <= 0.0
	desert_multiplier = 1.0
	emit_signal("resource_changed", "water",  water,  MAX_WATER)
	emit_signal("resource_changed", "food",   food,   MAX_FOOD)
	emit_signal("resource_changed", "energy", energy, MAX_ENERGY)

# ─── Interno ──────────────────────────────────────────────────────────────────
func _drain(resource_name: String, amount: float) -> void:
	match resource_name:
		"water":
			water  = maxf(water  - amount, 0.0)
			_check_depleted("water",  water)
			emit_signal("resource_changed", "water",  water,  MAX_WATER)
		"food":
			food   = maxf(food   - amount, 0.0)
			_check_depleted("food",   food)
			emit_signal("resource_changed", "food",   food,   MAX_FOOD)
		"energy":
			energy = maxf(energy - amount, 0.0)
			_check_depleted("energy", energy)
			emit_signal("resource_changed", "energy", energy, MAX_ENERGY)

func _check_depleted(resource_name: String, value: float) -> void:
	if value <= 0.0 and not _was_depleted[resource_name]:
		_was_depleted[resource_name] = true
		emit_signal("resource_depleted", resource_name)
		if _was_depleted["water"] and _was_depleted["food"] and _was_depleted["energy"]:
			emit_signal("all_resources_depleted")

func _check_restore(resource_name: String) -> void:
	if _was_depleted[resource_name]:
		_was_depleted[resource_name] = false
		emit_signal("resource_restored", resource_name)
