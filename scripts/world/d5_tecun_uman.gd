## d5_tecun_uman.gd
## Mapa especial D5 — Tecun Uman / Cruzamento do Rio Suchiate.
## Jangada improvisada, bike atravessando. Cena cinemática + desvio de fiscais.
## Jogabilidade: player se move em 4 direções pelo "rio" (TileMap de água),
## fiscais patrulham barcos no rio, desviar deles para chegar à margem oposta.

extends "res://scripts/world/world_map_base.gd"

const RIVER_WIDTH := 10   # largura do rio em tiles
const RAFT_COST   := 25   # sats para pagar o atravessador

func _ready() -> void:
	_player_start      = Vector2i(2, 44)    # margem guatemalteca (sul)
	_exit_tile         = Vector2i(8, 2)     # margem mexicana (norte)
	_boss_trigger_dist = 0                  # sem boss — cruzar é o objetivo
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"🌊  Rio Suchiate — Fronteira Guatemalo-Mexistão",
		"Aqui não há ponte oficial para imigrantes.",
		"Uma jangada de câmaras de borracha vai te levar.",
		"Custa %d sats." % RAFT_COST,
		"Os fiscais patrulham de barco — fique abaixado.",
	])
	await DialogueManager.dialogue_finished

	# Custo da travessia
	if SatEconomy.current_sats >= RAFT_COST:
		SatEconomy.remove_sats(RAFT_COST, "tecun_uman_raft")
		DialogueManager.start([
			"🚣  Atravessador: \"Tá pago. Sobe aí com a bike.\"",
			"A jangada começa a se mover.",
			"Chegue ao outro lado sem ser visto.",
		])
	else:
		DialogueManager.start([
			"😓  Você não tem sats suficientes para a jangada.",
			"Vai ter que nadar... ou esperar uma oportunidade.",
		])
	await DialogueManager.dialogue_finished

func _setup_npcs() -> void:
	spawn_npc(Vector2i(0, 44), "Atravessador",
		["Cinquenta sats ou não passa.",
		 "Essa é a taxa de travessia.",
		 "Não negocio — próximo!"],
		Color(0.5, 0.45, 0.35)
	)
	spawn_npc(Vector2i(9, 4), "Migrante Hondurenho",
		["Conseguiu? Que alívio!",
		 "Mexistão não é fácil, mas é o que temos.",
		 "O norte ainda está longe."],
		Color(0.6, 0.7, 0.5)
	)
	spawn_npc(Vector2i(0, 22), "Pescador Local",
		["Esse rio tem memória.",
		 "Viu muita gente passar.",
		 "A maioria não volta."],
		Color(0.45, 0.55, 0.65)
	)

func _setup_fiscais() -> void:
	# Fiscais patrulham no meio do rio — 3 barcos patrulheiros
	spawn_patrol_enemy(Vector2i(3, 24), "Fiscal Fluvial A", 60, 18, 30, 40, "item_spray", 3)
	spawn_patrol_enemy(Vector2i(6, 18), "Fiscal Fluvial B", 65, 20, 32, 42, "item_spray", 3)
	spawn_patrol_enemy(Vector2i(4, 12), "Fiscal Fluvial C", 70, 22, 35, 45, "item_camera", 2)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(9, 36), "EVT-005")   # ELONDOG COIN

func _get_boss_id() -> String:
	return ""   # Sem boss — objetivo é atravessar

func _get_boss_data() -> Dictionary:
	return {}
