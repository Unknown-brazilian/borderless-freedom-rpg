## player_customization.gd
## Gerencia skins, capacete, mochila e bike do jogador.
## Salva seleções via SaveSystem. Aplica bônus ao player/AutonomyBar no início de cada fase.
## Uso: PlayerCustomization.apply(player_node)

extends Node

const SAVE_KEY := "player_customization"

# ── Opções ──────────────────────────────────────────────────────────────────

const SKINS := [
	{"nome": "Padrão",    "cor": Color(1.00, 1.00, 1.00)},  # branco = sprite natural
	{"nome": "Sombra",    "cor": Color(0.55, 0.55, 0.70)},
	{"nome": "Deserto",   "cor": Color(1.00, 0.85, 0.55)},
	{"nome": "Floresta",  "cor": Color(0.60, 0.95, 0.60)},
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
	_apply_equipment(player)
	_apply_speed(player)
	_apply_resources()

## Mostra capacete e bike no player 2D (antes não apareciam nenhum dos dois).
func _apply_equipment(player: Node) -> void:
	if not (player is Node2D):
		return
	for n in ["Helmet", "BikeIcon"]:
		var old = player.get_node_or_null(n)
		if old:
			old.free()
	# Capacete: faixa colorida sobre a cabeça.
	if capacete_index > 0:
		var cap := ColorRect.new()
		cap.name = "Helmet"
		cap.size = Vector2(34, 14)
		cap.position = Vector2(-17, -52)
		cap.color = CAPACETES[capacete_index]["cor"]
		cap.z_index = 1
		player.add_child(cap)
	# Bike: desenho real aos pés do player (atrás dele).
	if bike_index > 0:
		var bike = preload("res://scripts/player/bike_sprite.gd").new()
		bike.name = "BikeIcon"
		bike.position = Vector2(0, 2)
		bike.z_index = -1   # player fica "em cima" da bike
		var bike_colors := [Color(0.2,0.2,0.25), Color(0.25,0.3,0.5), Color(0.3,0.5,0.3), Color(0.5,0.45,0.15)]
		bike.color = bike_colors[clampi(bike_index, 0, bike_colors.size()-1)]
		bike.electric = bike_index >= 3   # "Elétrica"
		player.add_child(bike)

func _apply_skin(player: Node) -> void:
	var skin_color: Color = SKINS[skin_index]["cor"]
	# Player 2D: tinta o Sprite2D pela cor da skin.
	var spr := player.get_node_or_null("Sprite")
	if spr and spr is CanvasItem:
		spr.modulate = skin_color
		return
	# Fallback player 3D (legado).
	var mesh_i: MeshInstance3D = player.get_node_or_null("MeshInstance3D")
	if mesh_i == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = skin_color
	mesh_i.material_override = mat

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
