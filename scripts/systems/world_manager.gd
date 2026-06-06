## world_manager.gd
## AutoLoad — gerencia a progressão do mundo RPG.
## Suporta sub-mapas especiais além das 9 dungeons principais.

extends Node

signal region_changed(dungeon: int, region_name: String)
signal game_completed

# ─── Sequência completa de cenas (ordenada) ───────────────────────────────────
# "dungeon" indica o número lógico do dungeon (1-9) para salvar/exibir
const SCENE_SEQUENCE: Array = [
	{"dungeon": 1, "name": "Bostil",                   "scene": "res://scenes/world/d1_bostil.tscn",               "unlock_item": "item_spray"},
	{"dungeon": 2, "name": "Bolivária",                 "scene": "res://scenes/world/d2_bolivaria.tscn",            "unlock_item": "item_panfleto"},
	{"dungeon": 3, "name": "Perulândia",                "scene": "res://scenes/world/d3_perulandia.tscn",           "unlock_item": ""},
	{"dungeon": 4, "name": "Panamia",                   "scene": "res://scenes/world/d4_panamia.tscn",              "unlock_item": "item_chave"},
	{"dungeon": 5, "name": "Centrolândia",              "scene": "res://scenes/world/d5_centrolandia.tscn",         "unlock_item": "item_radio"},
	{"dungeon": 5, "name": "Tecun Uman — Rio Suchiate", "scene": "res://scenes/world/d5_tecun_uman.tscn",           "unlock_item": ""},
	{"dungeon": 6, "name": "Mexistão — Tapachula",      "scene": "res://scenes/world/d6_tapachula_detencao.tscn",   "unlock_item": ""},
	{"dungeon": 6, "name": "Mexistão — Rota",           "scene": "res://scenes/world/d6_mexistao.tscn",             "unlock_item": "item_camera"},
	{"dungeon": 6, "name": "Mexistão — Torreón",        "scene": "res://scenes/world/d6_torreon_detencao.tscn",     "unlock_item": ""},
	{"dungeon": 6, "name": "Saltillo — Distribuidora",  "scene": "res://scenes/world/d6_saltillo.tscn",             "unlock_item": ""},
	{"dungeon": 7, "name": "Bostil (retorno)",          "scene": "res://scenes/world/d7_bostil2.tscn",              "unlock_item": ""},
	{"dungeon": 8, "name": "Paraguassu",                "scene": "res://scenes/world/d8_paraguassu.tscn",           "unlock_item": ""},
	{"dungeon": 9, "name": "Bélgique — Chegada",          "scene": "res://scenes/world/d9_chegada.tscn",             "unlock_item": ""},
	{"dungeon": 9, "name": "Bélgique — Encontro com Mia", "scene": "res://scenes/world/d9_mia.tscn",                 "unlock_item": ""},
	{"dungeon": 9, "name": "Bélgique — Obra",             "scene": "res://scenes/world/d9_obra.tscn",                "unlock_item": ""},
	{"dungeon": 9, "name": "Bélgique — Tribunal",         "scene": "res://scenes/world/d9_tribunal.tscn",            "unlock_item": ""},
	{"dungeon": 9, "name": "Bélgique — Canais Finais",    "scene": "res://scenes/world/d9_belgique.tscn",            "unlock_item": ""},
]

const BOSSES_PER_DUNGEON: Array[int] = [0, 3, 1, 2, 1, 3, 3, 1, 3, 1]

# ─── Estado ───────────────────────────────────────────────────────────────────
var current_dungeon:   int = 1
var sequence_index:    int = 0
var bosses_defeated_in_dungeon: int = 0
var _advancing: bool = false
var dungeon_flags: Dictionary = {}

# ─── API pública ──────────────────────────────────────────────────────────────

func start_game() -> void:
	current_dungeon   = 1
	sequence_index    = 0
	bosses_defeated_in_dungeon = 0
	dungeon_flags = {}
	SeedPhraseSystem.generate_seed()
	_go_to_current_region()

func get_region_name(dungeon: int = -1) -> String:
	if dungeon > 0:
		for entry in SCENE_SEQUENCE:
			if entry["dungeon"] == dungeon:
				return entry["name"]
		return "???"
	return SCENE_SEQUENCE[sequence_index]["name"] if sequence_index < SCENE_SEQUENCE.size() else "???"

func advance_to_next_dungeon() -> void:
	if _advancing:
		return
	_advancing = true
	var next_index := sequence_index + 1
	if next_index >= SCENE_SEQUENCE.size():
		_trigger_ending()
		_advancing = false
		return

	sequence_index = next_index
	var entry: Dictionary = SCENE_SEQUENCE[sequence_index]
	var new_dungeon: int  = entry.get("dungeon", current_dungeon)

	if new_dungeon != current_dungeon:
		bosses_defeated_in_dungeon = 0
		current_dungeon = new_dungeon
		GameStats.record_dungeon_complete(current_dungeon - 1)

	var item: String = entry.get("unlock_item", "")
	if not item.is_empty():
		PlayerInventory.unlock_item(item)

	emit_signal("region_changed", current_dungeon, get_region_name())
	SaveSystem.save_game()
	await get_tree().create_timer(0.5).timeout
	_go_to_current_region()
	_advancing = false

func record_boss_defeated() -> void:
	bosses_defeated_in_dungeon += 1
	GameStats.record_boss_defeated()

func set_flag(key: String, value) -> void:
	dungeon_flags[key] = value

func get_flag(key: String, default = null):
	return dungeon_flags.get(key, default)

# ─── Persistência ─────────────────────────────────────────────────────────────
func save() -> Dictionary:
	return {
		"current_dungeon":   current_dungeon,
		"sequence_index":    sequence_index,
		"bosses_in_dungeon": bosses_defeated_in_dungeon,
		"flags":             dungeon_flags,
	}

func load_from(data: Dictionary) -> void:
	current_dungeon            = data.get("current_dungeon", 1)
	sequence_index             = data.get("sequence_index",  0)
	bosses_defeated_in_dungeon = data.get("bosses_in_dungeon", 0)
	dungeon_flags              = data.get("flags", {})
	# Validar bounds para compatibilidade entre versões
	sequence_index = clampi(sequence_index, 0, SCENE_SEQUENCE.size() - 1)
	# Se dungeon no save não bate com a sequência, resetar para início do dungeon
	var saved_scene_dungeon: int = SCENE_SEQUENCE[sequence_index].get("dungeon", 1)
	if saved_scene_dungeon != current_dungeon:
		sequence_index = 0
		for i in range(SCENE_SEQUENCE.size()):
			if SCENE_SEQUENCE[i].get("dungeon", 1) == current_dungeon:
				sequence_index = i
				break

# ─── Internas ─────────────────────────────────────────────────────────────────
func _go_to_current_region() -> void:
	if sequence_index >= SCENE_SEQUENCE.size():
		_trigger_ending()
		return
	var scene_path: String = SCENE_SEQUENCE[sequence_index].get("scene", "")
	if scene_path.is_empty():
		push_error("[WorldManager] Cena vazia no índice %d" % sequence_index)
		return
	SceneTransition.go(scene_path)

func _trigger_ending() -> void:
	emit_signal("game_completed")
	var is_sovereign := RandomEventsSystem.check_sovereign_individual()
	if is_sovereign:
		RandomEventsSystem.grant_sovereign_ending_bonus()
	var path := "res://scenes/endings/ending_sovereign.tscn" if is_sovereign \
		else "res://scenes/endings/ending_free.tscn"
	SceneTransition.go(path)
