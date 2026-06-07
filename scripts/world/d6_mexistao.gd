## d6_mexistao.gd
## Mapa D6 — Mexistão (Tapachula ao Norte).
## O mapa mais longo — múltiplos fiscais, La Bestia, cartéis.

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	_boss_trigger_dist = 4
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D6, Mexistão" % PlayerStats.player_name,
		"Tapachula. A cidade que nunca larga.",
		"São 3.000 km até a fronteira norte.",
		"Fiscais, cartéis e La Bestia te aguardam.",
		"Guarde seus sats — vai precisar de muitos.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 10.0)

func _setup_npcs() -> void:
	spawn_npc(Vector2i(6, 42), "Migrante Veterano",
		["Mexistão é o país mais difícil da rota.",
		 "Fiscal te para no sul. Cartel te cobra no norte.",
		 "Furtividade aqui vale ouro.",
		 "Ou sats — que é a mesma coisa."],
		Color(0.75, 0.55, 0.25)
	)
	spawn_npc(Vector2i(2, 34), "Padre Solidário",
		["Aqui ninguém te pergunta de onde vem.",
		 "Descanse. A jornada ainda é longa.",
		 "El Señor Transformação controla o norte.",
		 "Ninguém sabe sua forma real."],
		Color(0.7, 0.7, 0.9)
	)
	spawn_npc(Vector2i(8, 24), "Jornaleiro",
		["O Complexo está lá no fim.",
		 "Dizem que tem 7 formas.",
		 "Nunca vi ninguém que passou sem a seed.",
		],
		Color(0.969, 0.576, 0.102)
	)
	spawn_npc(Vector2i(3, 14), "Ex-Policial",
		["Trabalhei para o sistema por 10 anos.",
		 "Saí quando vi o que eles fazem com os sats.",
		 "O spray repelente funciona bem aqui."],
		Color(0.4, 0.8, 0.5)
	)

func _setup_fiscais() -> void:
	# Patrulheiros visíveis — perseguem o player ao vê-lo
	spawn_patrol_enemy(Vector2i(4, 36), "Agente do AMLO",    155, 25, 78, 75, "item_spray", 3)
	spawn_patrol_enemy(Vector2i(5, 28), "Inspetor da Sheinbaum",      165, 28, 83, 82, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(3, 20), "Guarda do Adán Augusto",        175, 31, 88, 90, "item_spray", 4)
	spawn_patrol_enemy(Vector2i(6, 12), "Agente do Monreal", 185, 34, 93, 95, "item_panfleto", 2)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(7, 40), "EVT-004")   # TERRAFORMA (D3-D6)
	spawn_crypto_npc(Vector2i(1, 16), "EVT-007")   # Quadrix Exchange (D2-D5)

func _get_boss_id() -> String:
	return "BOSS-D6-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "O Complexo",
		"hp": 350,
		"atk": 45,
		"reward_sats": 300,
		"bribe_cost": 999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D6-FINAL",
		"intro_lines": [
			"🏭  O COMPLEXO se manifesta!",
			"\"Forma 1: Burocracia Infinita...\"",
			"Um chefe com 7 formas. O mais difícil até agora.",
			"A câmera expõe cada forma — use-a.",
		],
		"victory_lines": [
			"🏆  O COMPLEXO DESTRUÍDO!",
			"Todas as 7 formas derrotadas.",
			"A fronteira norte do Mexistão está livre.",
			"🔑  Prove que a seed é sua...",
		],
	}
