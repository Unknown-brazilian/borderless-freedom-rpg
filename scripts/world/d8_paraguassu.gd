## d8_paraguassu.gd
## Mapa D8 — Paraguassu (mineradores e Cartes, o Padrinho).

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	_stretch = 1.6
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D8, Paraguassu" % PlayerStats.player_name,
		"Terra de mineradores de Bitcoin.",
		"O Cartes, o Padrinho sequestra ASICs.",
		"Recupere os equipamentos e passe para frente.",
	])
	await DialogueManager.dialogue_finished
	SatEconomy.add_sats(20, "aliado_minero")
	AutonomyBar.restore("energy", 15.0)

func _setup_npcs() -> void:
	spawn_building(Vector2i(9, 38), "res://scenes/world/loja_interior.tscn", "Loja & Empregos")
	spawn_campsite(Vector2i(3, 26))
	spawn_npc(Vector2i(6, 42), "Minerador Aliado I",
		["Bem-vindo ao Paraguassu.",
		 "Aqui mineramos Bitcoin livremente — ou tentamos.",
		 "O Cartes, o Padrinho confiscou nossos ASICs!",
		 "+20 sats de ajuda para você."],
		Color(0.969, 0.576, 0.102)
	)
	spawn_npc(Vector2i(2, 32), "Minerador Aliado II",
		["Minha ASIC foi confiscada há 3 semanas.",
		 "Não tenho como pagar para recuperar.",
		 "O rádio pode interferir nos equipamentos dele."],
		Color(0.5, 0.8, 0.5)
	)
	spawn_npc(Vector2i(8, 20), "Técnico Consertador",
		["O Delegado guarda os ASICs no posto norte.",
		 "Se você os recuperar, a comunidade te agradece.",
		 "Precisamos de furtividade — câmeras por todo lado."],
		Color(0.8, 0.6, 0.3)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 34), "Guarda do Peña",   175, 29, 88, 87, "item_radio", 2)
	spawn_patrol_enemy(Vector2i(5, 24), "Guarda do Cartes",  185, 32, 88, 92, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(3, 14), "Agente do Mario Abdo",      195, 35, 115, 100, "item_spray", 2)


func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(1, 38), "EVT-010")

func _get_boss_id() -> String:
	return "BOSS-D8-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Cartes, o Padrinho",
		"hp": 250,
		"atk": 40,
		"reward_sats": 280,
		"bribe_cost": 999,
		"weakness_item": "item_radio",
		"is_boss": true,
		"boss_id": "BOSS-D8-FINAL",
		"intro_lines": [
			"⚡  DELEGADO FAÍSCA aparece!",
			"\"Esses ASICs são propriedade do Estado!\"",
			"Ele usa frequências para bloquear.",
			"Seu rádio é a única defesa.",
		],
		"victory_lines": [
			"🏆  Cartes, o Padrinho derrotado!",
			"Os ASICs foram recuperados!",
			"A comunidade mineradora está salva.",
			"🔑  Prove que a seed é sua...",
		],
	}

func _setup_theme() -> void:
	_ground_tint = Color(0.9, 0.86, 0.68)
