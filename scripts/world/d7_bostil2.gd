## d7_bostil_retorno.gd
## Mapa D7 — Bostil (retorno) — Deportação e Xandão, o Tirano do Algoritmo.
## Boss victory → DeportationChallenge (reordena 24 palavras da seed).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D7, Bostil (retorno)" % PlayerStats.player_name,
		"O algoritmo do Estado rastreou você até aqui.",
		"Ordem de deportação emitida.",
		"Prove sua soberania ou seja expulso.",
	])

func _setup_npcs() -> void:
	# Binóculos novos (os antigos foram roubados no Mexistão) — escondido.
	spawn_pickup(Vector2i(18, 8), "item_binoculo", "🔭", "Binóculos novos! Os guardas voltam a aparecer.")
	spawn_npc(Vector2i(6, 42), "Ex-Dissidente",
		["Fui deportado três vezes.",
		 "Cada vez aprendi mais sobre liberdade.",
		 "O algoritmo odeia quem sabe a seed.",
		],
		Color(0.55, 0.55, 0.75)
	)
	spawn_npc(Vector2i(2, 30), "Advogado Soberano",
		["O Xandão, o Tirano do Algoritmo é o chefe aqui.",
		 "Persuasão >= 2 pode negociar saída.",
		 "Mas provar sua seed é a única certeza.",
		],
		Color(0.969, 0.576, 0.102)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 30), "Agente do Dino",   170, 28, 86, 85, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(5, 22), "Agente do Lewandowski",  180, 31, 86, 90, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(3, 14), "Agente do Gilmar", 190, 34, 130, 95, "item_spray", 2)


func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(7, 38), "EVT-008")

func _get_boss_id() -> String:
	return ""   # Não usa BossWordChallenge — usa DeportationChallenge

func _get_boss_data() -> Dictionary:
	return {
		"name": "Xandão, o Tirano do Algoritmo",
		"hp": 230,
		"atk": 38,
		"reward_sats": 260,
		"bribe_cost": 999,
		"weakness_item": "item_radio",
		"is_boss": true,
		"intro_lines": [
			"🤖  ALGORITMO TIRANO ativado!",
			"\"Identidade não reconhecida.\"",
			"\"Ordem de deportação: IMEDIATA.\"",
		],
		"victory_lines": [
			"⚡  Algoritmo desativado temporariamente!",
			"Mas o sistema ainda tem seus dados.",
			"🔑  Prove sua seed para anular a deportação...",
		],
	}

# ─── Após derrota do boss: DeportationChallenge em vez de BossWordChallenge ──
func _on_boss_result(result: String) -> void:
	if result == "victory":
		_boss_defeated = true
		_player.set_can_move(false)
		var bd := _get_boss_data()
		var victory_lines: Array[String] = []
		victory_lines.assign(bd.get("victory_lines", []))
		DialogueManager.start(victory_lines)
		await DialogueManager.dialogue_finished

		var challenge := preload("res://scenes/ui/DeportationChallenge.tscn").instantiate()
		add_child(challenge)
		challenge.show()
		challenge.challenge_result.connect(func(passed: bool, bonus: int):
			if passed:
				SatEconomy.add_sats(bonus, "deportation_challenge")
				_map_complete = true
				_player.set_can_move(true)
			else:
				await get_tree().create_timer(1.5).timeout
				SceneTransition.go("res://scenes/ui/main_menu.tscn")
		)
	elif result == "defeat":
		await get_tree().create_timer(1.5).timeout
		SceneTransition.go("res://scenes/ui/main_menu.tscn")

func _setup_theme() -> void:
	_ground_tint = Color(0.8, 0.8, 0.86)
	_music_pitch = 0.94
