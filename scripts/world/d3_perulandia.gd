## d3_perulandia.gd
## Mapa D3 — Perulândia (altiplano andino).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D3, Perulândia" % PlayerStats.player_name,
		"Você cruzou para o altiplano andino.",
		"A altitude dificulta o movimento.",
		"Seus recursos drenam mais rápido aqui.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 15.0)
	AutonomyBar.consume("water",  10.0)

func _setup_npcs() -> void:
	spawn_npc(Vector2i(6, 42), "Comerciante Quechua",
		["Bem-vindo ao altiplano.",
		 "Os fiscais aqui confiscam tudo.",
		 "Sua furtividade vale mais que sats."],
		Color(0.75, 0.55, 0.25)
	)
	spawn_npc(Vector2i(2, 28), "Minerador",
		["Bitcoin minerado em energia solar aqui.",
		 "O governo não sabe — por enquanto.",
		 "Furtividade é a nossa armadura."],
		Color(0.4, 0.65, 0.9)
	)
	spawn_npc(Vector2i(7, 16), "Guia de Montanha",
		["A fronteira norte tem um general corrupto.",
		 "Suborno funciona — mas é caríssimo.",
		 "Ele odeia câmeras. Use isso contra ele."],
		Color(0.3, 0.75, 0.4)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 32), "Guarda da Dina",  130, 20, 65, 65, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(5, 22), "Inspetor do Castillo", 145, 23, 70, 75, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(3, 12), "Patrulha da Keiko",      155, 26, 95, 80, "item_spray", 2)


func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(7, 38), "EVT-001")

func _get_boss_id() -> String:
	return "BOSS-D3-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Castillo, o Autogolpista",
		"hp": 185,
		"atk": 30,
		"reward_sats": 195,
		"bribe_cost": 999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D3-FINAL",
		"intro_lines": [
			"🚨  Castillo, o Autogolpista bloqueia a passagem!",
			"\"Nenhum dissidente cruza minha fronteira.\"",
			"Ele odeia câmeras — use isso.",
		],
		"victory_lines": [
			"🏆  General Fraudo derrotado!",
			"As fotos foram expostas. Ele fugiu envergonhado.",
			"🔑  Prove que a seed é sua para avançar...",
		],
	}

func _setup_theme() -> void:
	_ground_key = "path"
	_no_path = true
	_ground_tint = Color(0.92, 0.85, 0.72)
	_music_pitch = 0.97
