## player_customization.gd
## Gerencia skins, capacete, mochila e bike do jogador.
## Salva seleções via SaveSystem. Aplica bônus ao player/AutonomyBar no início de cada fase.
## Uso: PlayerCustomization.apply(player_node)

extends Node

const SAVE_KEY := "player_customization"

# ── Opções ──────────────────────────────────────────────────────────────────

const SKINS := [
	{"nome": "Padrão",    "cor": Color(0.75, 0.60, 0.45)},
	{"nome": "Sombra",    "cor": Color(0.25, 0.22, 0.20)},
	{"nome": "Deserto",   "cor": Color(0.85, 0.72, 0.45)},
	{"nome": "Floresta",  "cor": Color(0.35, 0.55, 0.30)},
]

const CAPACETES := [
	{"nome": "Nenhum",      "energy_bonus": 0.0,  "cor": Color(0, 0, 0, 0)},
	{"nome": "Básico",      "energy_bonus": 8.0,  "cor": Color(0.80, 0.80, 0.80)},
	{"nome": "Tático",      "energy_bonus": 15.0, "cor": Color(0.20, 0.25, 0.35)},
	{"nome": "Solar",       "energy_bonus": 20.0, "cor": Color(0.95, 0.85, 0.20)},
]

const MOCHILAS := [
	{"nome": "Nenhuma",     "water_bonus": 0.0,  "food_bonus": 0.0},
	{"nome": "Pequena",     "water_bonus": 10.0, "food_bonus": 5.0},
	{"nome": "Trekking",    "water_bonus": 20.0, "food_bonus": 15.0},
	{"nome": "Expedição",   "water_bonus": 30.0, "food_bonus": 25.0},
]

const BIKES := [
	{"nome": "Nenhuma",     "speed_bonus": 0.0,  "label": "🚶"},
	{"nome": "Urbana",      "speed_bonus": 0.5,  "label": "🚲"},
	{"nome": "Mountain",    "speed_bonus": 1.0,  "label": "🚵"},
	{"nome": "Elétrica",    "speed_bonus": 1.5,  "label": "⚡🚲"},
]

# ── Estado atual ─────────────────────────────────────────────────────────────

var skin_index:     int = 0
var capacete_index: int = 0
var mochila_index:  int = 0
var bike_index:     int = 0

# ── Ciclo de vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	load_customization()

# ── Salvar / Carregar ──────────────────────────────────────────────────────

func save_customization() -> void:
	var data := {
		"skin":     skin_index,
		"capacete": capacete_index,
		"mochila":  mochila_index,
		"bike":     bike_index,
	}
	SaveSystem.set_value(SAVE_KEY, data)

func load_customization() -> void:
	var data = SaveSystem.get_value(SAVE_KEY, null)
	if data == null: return
	skin_index     = int(data.get("skin",     0))
	capacete_index = int(data.get("capacete", 0))
	mochila_index  = int(data.get("mochila",  0))
	bike_index     = int(data.get("bike",     0))
	_clamp_indices()

func _clamp_indices() -> void:
	skin_index     = clampi(skin_index,     0, SKINS.size()    - 1)
	capacete_index = clampi(capacete_index, 0, CAPACETES.size()- 1)
	mochila_index  = clampi(mochila_index,  0, MOCHILAS.size() - 1)
	bike_index     = clampi(bike_index,     0, BIKES.size()    - 1)

# ── Aplicar ao player ─────────────────────────────────────────────────────

func apply(player: Node) -> void:
	_apply_skin(player)
	_apply_speed(player)
	_apply_resources()

func _apply_skin(player: Node) -> void:
	var skin_color: Color = SKINS[skin_index]["cor"]
	var mesh_i: MeshInstance3D = player.get_node_or_null("MeshInstance3D")
	if mesh_i == null: return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = skin_color
	mesh_i.material_override = mat

	var cap: Dictionary = CAPACETES[capacete_index]
	var cap_node: MeshInstance3D = player.get_node_or_null("Capacete")
	if cap_node:
		cap_node.visible = capacete_index > 0
		if capacete_index > 0:
			var cap_mat := StandardMaterial3D.new()
			cap_mat.albedo_color = cap["cor"]
			cap_node.material_override = cap_mat

func _apply_speed(player: Node) -> void:
	var stored = player.get("_base_run_speed")
	var base_speed: float = stored if (stored != null and stored > 0.0) else 8.0
	var bonus: float = BIKES[bike_index]["speed_bonus"]
	if player.has_method("set_base_speed"):
		player.set_base_speed(base_speed + bonus)
	else:
		player.set("run_speed", base_speed + bonus)

func _apply_resources() -> void:
	var mochila: Dictionary = MOCHILAS[mochila_index]
	var cap:     Dictionary = CAPACETES[capacete_index]
	# Reduce drain rates proportionally to equipment bonus (max bonus = 50% less drain)
	AutonomyBar.water_drain_rate  = 0.5 * (1.0 - mochila["water_bonus"]  / 60.0)
	AutonomyBar.food_drain_rate   = 0.3 * (1.0 - mochila["food_bonus"]   / 50.0)
	AutonomyBar.energy_drain_rate = 0.4 * (1.0 - cap["energy_bonus"]     / 40.0)

# ── Getters para UI ────────────────────────────────────────────────────────

func get_skin_name()     -> String: return SKINS[skin_index]["nome"]
func get_capacete_name() -> String: return CAPACETES[capacete_index]["nome"]
func get_mochila_name()  -> String: return MOCHILAS[mochila_index]["nome"]
func get_bike_name()     -> String: return BIKES[bike_index]["label"] + " " + BIKES[bike_index]["nome"]

func cycle_skin(dir: int)     -> void: skin_index     = posmod(skin_index     + dir, SKINS.size())
func cycle_capacete(dir: int) -> void: capacete_index = posmod(capacete_index + dir, CAPACETES.size())
func cycle_mochila(dir: int)  -> void: mochila_index  = posmod(mochila_index  + dir, MOCHILAS.size())
func cycle_bike(dir: int)     -> void: bike_index     = posmod(bike_index     + dir, BIKES.size())

func get_summary() -> String:
	return "%s | %s | %s | %s" % [
		get_skin_name(), get_capacete_name(), get_mochila_name(), get_bike_name()
	]
