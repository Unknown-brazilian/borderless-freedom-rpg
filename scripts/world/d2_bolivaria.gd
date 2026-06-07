## d2_bolivária.gd
## Mapa D2 — Bolivária (Fronteira Altiplano).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D2, Bolivária" % PlayerStats.player_name,
		"Fronteira Altiplano.",
		"Chegue ao norte para avançar.",
	])

func _setup_npcs() -> void:
	spawn_npc(Vector2i(6, 42), "Migrante Local",
		["Bem-vindo à Bolivária.",
		 "Os fiscais aqui são mais severos.",
		 "Use sua furtividade ou sats para passar."],
		Color(0.4, 0.65, 0.9)
	)
	spawn_npc(Vector2i(2, 32), "Aliado Local",
		["As alfândegas do Evo estão à frente.",
		 "Cuide dos seus recursos."],
		Color(0.969, 0.576, 0.102)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 30), "Alfândega do Evo",   120,       18,     60, 60, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(5, 22), "Alfândega do Arce",  130, 21, 60, 65, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(3, 14), "Alfândega do Linera", 140, 24, 90, 70, "item_spray", 2)


func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(1, 40), "EVT-007")

func _get_boss_id() -> String:
	return "BOSS-D2-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Evo, o Eterno Candidato",
		"hp": 120 + 60,
		"atk": 18 + 10,
		"reward_sats": 180,
		"bribe_cost": 999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D2-FINAL",
		"intro_lines": [
			"🚨  Evo, o Eterno Candidato bloqueia o caminho!",
			"Este é o boss de Bolivária.",
			"Use o item certo para vencer mais fácil.",
		],
		"victory_lines": [
			"🏆  Evo, o Eterno Candidato derrotado!",
			"O caminho está livre.",
			"🔑  Mostre que a seed é sua...",
		],
	}

func _setup_theme() -> void:
	_ground_tint = Color(0.82, 0.88, 1.0)
	_music_pitch = 0.95
