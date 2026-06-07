## d1_bostil.gd
## Mapa D1 — Bostil (tutorial, fronteira sul).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_map_h             = 80        # mapa longo estilo Pokémon
	_player_start      = Vector2i(4, 76)
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
	# Binóculos escondidos num canto — sem eles os guardas ficam invisíveis.
	spawn_pickup(Vector2i(20, 68), "item_binoculo", "🔭", "Binóculos! Agora você enxerga os guardas.")
	spawn_pickup(Vector2i(3, 56), "", "💧", "Água! +50 hidratação", "water", 50.0)
	# Acampamento (descansar + salvar) e obstáculos no caminho.
	spawn_campsite(Vector2i(6, 52))
	spawn_obstacle(Vector2i(5, 60))
	spawn_obstacle(Vector2i(3, 46))
	spawn_obstacle(Vector2i(5, 34))
	spawn_npc(Vector2i(6, 70), "Migrante Beto",
		["Ei! Você está começando sua jornada?",
		 "Cuidado com os Fiscais mais à frente.",
		 "Use furtividade ou sats para passar.",
		 "Boa sorte, dissidente."],
		Color(0.4, 0.6, 0.9)
	)
	spawn_npc(Vector2i(2, 62), "Alfredo",
		["Bitcoin é a saída.",
		 "Guarde suas chaves. Sua seed = seu dinheiro.",
		 "Nunca dê a seed para ninguém.",
		 "Eu sei — parece papo de louco. Mas você vai entender."],
		Color(0.969, 0.576, 0.102)
	)
	spawn_npc(Vector2i(8, 44), "Moradora",
		["Os fiscais ficam no meio da estrada.",
		 "Se correr pelo lado, às vezes passam batido.",
		 "Mas se te pegarem sem sats — cuidado."],
		Color(0.7, 0.5, 0.8)
	)

func _setup_fiscais() -> void:
	# Fiscais patrulheiros — visíveis e móveis como especificado no GDD
	spawn_patrol_enemy(Vector2i(4, 58), "Fiscal do Lula",   30, 10, 12, 18, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(5, 44), "Fiscal do Xandão", 40, 14, 15, 25, "item_spray", 3)
	spawn_patrol_enemy(Vector2i(3, 28), "Fiscal do Haddad", 35, 12, 15, 22, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(5, 14), "Fiscal da Marina", 45, 16, 20, 30, "item_panfleto", 3)

func _setup_events() -> void:
	# 2 NPCs de scam cripto — aparecem convincentes, sem timeout
	# Figurões financeiros BR (Bostil = Brasil), espalhados pela estrada.
	# (Fernando Ulrich aparece só em D6/Mexistão, como "vídeo do YouTube".)
	spawn_crypto_npc(Vector2i(2, 50), "EVT-012")   # Augusto Backes — "essa small cap vai 10x"
	spawn_crypto_npc(Vector2i(8, 22), "EVT-013")   # Empiricus — "seja a próxima Bettina"

func _get_boss_id() -> String:
	return "BOSS-D1-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Lula, o Molusco",
		"hp": 120,
		"atk": 20,
		"reward_sats": 250,
		"bribe_cost": 999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D1-FINAL",
		"intro_lines": [
			"🚨  LULA, O MOLUSCO!",
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

func _setup_theme() -> void:
	_ground_tint = Color(1.0, 0.97, 0.82)
