## save_system.gd — RPG
## Salva/carrega o estado completo do RPG.

extends Node

const SAVE_PATH := "user://borderless_freedom_rpg.save"

var _store: Dictionary = {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	PlayerCustomization.save_customization()   # populates _store["player_customization"]
	# Posição exata do player (restaura onde salvou, não no início do mapa).
	var ptile := [-1, -1]
	var pl := get_tree().get_first_node_in_group("player") if get_tree() else null
	if pl and pl.has_method("get_tile_position"):
		var t: Vector2i = pl.get_tile_position()
		ptile = [t.x, t.y]
	var data := {
		"version":        1,
		"player_tile":    ptile,
		"player_seq":     WorldManager.sequence_index,
		"sat_economy":    SatEconomy.save(),
		"random_events":  RandomEventsSystem.get_stats(),
		"world_manager":  WorldManager.save(),
		"game_stats":     GameStats.save(),
		"player_stats":   PlayerStats.save(),
		"player_inventory": PlayerInventory.save(),
		"seed_phrase":    SeedPhraseSystem.save(),
		"autonomy_bar":   AutonomyBar.get_save_data(),
		"store":          _store,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return false
	file.close()
	var data: Dictionary = json.get_data()

	SatEconomy.load_from(data.get("sat_economy", {}))
	RandomEventsSystem.load_from(data.get("random_events", {}))
	WorldManager.load_from(data.get("world_manager", {}))
	GameStats.load_from(data.get("game_stats", {}))
	PlayerStats.load_from(data.get("player_stats", {}))
	PlayerInventory.load_from(data.get("player_inventory", {}))
	_store = data.get("store", {})   # restaurar antes de PlayerCustomization.load_customization()
	PlayerCustomization.load_customization()
	SeedPhraseSystem.load_from(data.get("seed_phrase", {}))
	AutonomyBar.load_save_data(data.get("autonomy_bar", {}))
	# Restaura a posição exata salva, se o mapa carregado for o mesmo do save.
	var pt: Array = data.get("player_tile", [-1, -1])
	var pseq: int = int(data.get("player_seq", -1))
	if pt.size() == 2 and int(pt[0]) >= 0 and pseq == WorldManager.sequence_index:
		WorldManager.pending_return_tile = Vector2i(int(pt[0]), int(pt[1]))
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func reset_store() -> void:
	_store = {}

func set_value(key: String, value) -> void:
	_store[key] = value

func get_value(key: String, default = null):
	return _store.get(key, default)
