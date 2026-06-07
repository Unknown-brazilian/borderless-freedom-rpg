## interior_base.gd — interior de loja/casa (estilo Pokémon). Reusa o world_map_base
## (player, controles, tiles), mas pequeno, sem inimigos/boss, com porta de saída,
## lojista e balcão de empregos.
extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_is_interior = true
	_map_w = 11
	_map_h = 11
	_ground_key = "floor"
	_no_path = true
	_player_start = Vector2i(5, 8)
	super._ready()

func _setup_theme() -> void:
	_ground_tint = Color(0.85, 0.80, 0.72)
	_music_track = "menu"
	_music_pitch = 1.0

func _check_exit() -> void:
	pass   # interiores não avançam de dungeon

func _get_boss_id() -> String:
	return ""

func _intro_dialogue() -> void:
	pass

func _setup_npcs() -> void:
	# Porta de saída (volta para a overworld).
	var door = preload("res://scripts/world/exit_door.gd").new()
	door.position = _tile_to_world(Vector2i(5, 9))
	add_child(door)
	# Lojista.
	var shop = preload("res://scripts/world/shop_npc.gd").new()
	shop.position = _tile_to_world(Vector2i(3, 3))
	add_child(shop)
	# Balcão de empregos.
	var job = preload("res://scripts/world/job_npc.gd").new()
	job.position = _tile_to_world(Vector2i(7, 3))
	add_child(job)
