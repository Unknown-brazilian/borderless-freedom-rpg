## d1b_bostil_estrada.gd — Bostil, 2ª fase (Estrada rumo à fronteira).
extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	_stretch      = 1.6
	super._ready()

func _setup_theme() -> void:
	_ground_tint = Color(1.0, 0.97, 0.82)

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — Bostil, Estrada" % PlayerStats.player_name,
		"A estrada corta o interior rumo à fronteira.",
		"Os fiscais aqui são mais atentos.",
	])

func _setup_npcs() -> void:
	spawn_building(Vector2i(9, 38), "res://scenes/world/loja_interior.tscn", "Loja & Empregos")
	spawn_campsite(Vector2i(3, 30))
	spawn_pickup(Vector2i(8, 20), "", "💧", "Água! +50", "water", 50.0)
	spawn_npc(Vector2i(6, 40), "Caminhoneiro",
		["Vai pra fronteira a pé? Corajoso.",
		 "Tem fiscal demais nessa estrada.",
		 "Se tiver câmera, eles recuam — não gostam de flagra."],
		Color(0.5, 0.6, 0.9))

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 34), "Fiscal do Haddad", 35, 12, 15, 22, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(5, 18), "Fiscal da Receita", 42, 14, 18, 26, "item_spray", 3)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(2, 26), "EVT-012")   # Augusto Backes (cripto)
