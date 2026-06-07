## d5_centrolandia.gd
## Mapa D5 — Centrolândia (América Central).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D5, Centrolândia" % PlayerStats.player_name,
		"A América Central — múltiplas fronteiras.",
		"Cada país exige documentação diferente.",
		"Sats e furtividade são seu passaporte.",
	])

func _setup_npcs() -> void:
	spawn_npc(Vector2i(6, 42), "Migrante Hondurense",
		["Já cruzo esta fronteira pela terceira vez.",
		 "Cada vez mais fiscais. Cada vez mais caro.",
		 "Bitcoin é a única moeda que aceitam todos."],
		Color(0.4, 0.65, 0.9)
	)
	spawn_npc(Vector2i(2, 32), "Jornalista",
		["Estou documentando a rota migratória.",
		 "Cuidado — os fiscais aqui são bem organizados.",
		 "Panfletos de conscientização ajudam na persuasão."],
		Color(0.8, 0.8, 0.3)
	)
	spawn_npc(Vector2i(7, 20), "Dissidente Local",
		["Bukele, o Ditador Descolado comanda este checkpoint.",
		 "Ele bloqueia qualquer sinal de rádio.",
		 "Mas seu rádio específico pode virar isso contra ele."],
		Color(0.969, 0.576, 0.102)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 34), "Checkpoint do Ortega",    150, 24, 75, 72, "item_panfleto", 2)
	spawn_patrol_enemy(Vector2i(5, 24), "Checkpoint da Xiomara",    165, 27, 80, 82, "item_panfleto", 2)
	spawn_patrol_enemy(Vector2i(3, 16), "Checkpoint do Bukele",175, 30, 105, 90, "item_radio", 2)
	spawn_patrol_enemy(Vector2i(6, 8),  "Patrulha Final",  155, 25, 80, 78, "item_spray", 2)


func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(1, 38), "EVT-006")

func _get_boss_id() -> String:
	return "BOSS-D5-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Bukele, o Ditador Descolado",
		"hp": 210,
		"atk": 34,
		"reward_sats": 230,
		"bribe_cost": 999,
		"weakness_item": "item_radio",
		"is_boss": true,
		"boss_id": "BOSS-D5-FINAL",
		"intro_lines": [
			"📡  Bukele, o Ditador Descolado ativa o bloqueio de sinal!",
			"\"Nenhuma comunicação não autorizada passa aqui.\"",
			"Seu rádio é a chave — use-o contra ele.",
		],
		"victory_lines": [
			"🏆  Bukele, o Ditador Descolado derrotado!",
			"O bloqueio de sinal foi quebrado.",
			"🔑  Prove sua identidade soberana...",
		],
	}
