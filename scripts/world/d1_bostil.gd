## d1_bostil.gd
## Mapa D1 — Bostil (tutorial, fronteira sul).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 3
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D1, Bostil" % PlayerStats.player_name,
		"A jornada começa aqui.",
		"Cuidado com os Fiscais mais à frente.",
		"Se tiver sats, pode tentar suborno.",
		"Se tiver furtividade, passe despercebido.",
	])

func _setup_npcs() -> void:
	spawn_npc(Vector2i(6, 42), "Migrante Beto",
		["Ei! Você está começando sua jornada?",
		 "Cuidado com os Fiscais mais à frente.",
		 "Use furtividade ou sats para passar.",
		 "Boa sorte, dissidente."],
		Color(0.4, 0.6, 0.9)
	)
	spawn_npc(Vector2i(2, 38), "Alfredo",
		["Bitcoin é a saída.",
		 "Guarde suas chaves. Sua seed = seu dinheiro.",
		 "Nunca dê a seed para ninguém.",
		 "Eu sei — parece papo de louco. Mas você vai entender."],
		Color(0.969, 0.576, 0.102)
	)
	spawn_npc(Vector2i(8, 30), "Moradora",
		["Os fiscais ficam no meio da estrada.",
		 "Se correr pelo lado, às vezes passam batido.",
		 "Mas se te pegarem sem sats — cuidado."],
		Color(0.7, 0.5, 0.8)
	)

func _setup_fiscais() -> void:
	# Fiscais patrulheiros — visíveis e móveis como especificado no GDD
	spawn_patrol_enemy(Vector2i(4, 28), "Fiscal Estadual",  30, 10, 12, 18, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(5, 20), "Fiscal Federal",   40, 14, 15, 25, "item_spray", 3)
	spawn_patrol_enemy(Vector2i(3, 14), "Fiscal Sanitário", 35, 12, 15, 22, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(5, 10), "Fiscal IBAMA",     45, 16, 20, 30, "item_panfleto", 3)

func _setup_events() -> void:
	# 2 NPCs de scam cripto — aparecem convincentes, sem timeout
	spawn_crypto_npc(Vector2i(7, 36), "EVT-002")   # LULACOIN (D1 é no range 1-2)
	spawn_crypto_npc(Vector2i(1, 22), "EVT-003")   # segundo evento disponível

func _get_boss_id() -> String:
	return "BOSS-D1-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Coronel Corumbão",
		"hp": 120,
		"atk": 20,
		"reward_sats": 250,
		"bribe_cost": 999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D1-FINAL",
		"intro_lines": [
			"🚨  CORONEL CORUMBÃO!",
			"\"Cobra em 3 moedas. Nenhuma delas válida.\"",
			"O boss final de Bostil bloqueia a fronteira!",
			"Use a câmera para expô-lo.",
		],
		"victory_lines": [
			"🎉  CORONEL DERROTADO!",
			"A fronteira está aberta.",
			"🔑  Desafio da seed antes de avançar...",
		],
	}
