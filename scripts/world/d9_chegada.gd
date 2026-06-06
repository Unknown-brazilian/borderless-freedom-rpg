## d9_chegada.gd
## D9-A — Chegada à Bélgique: 3 checkpoints EU.
## Cada checkpoint custa sats para passar (35/45/55).
## Persuasão >= 1 = 25% de desconto. Advogado aliado presente.

extends "res://scripts/world/world_map_base.gd"

const CHECKPOINT_COSTS := [35, 45, 55]

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 0
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"✈️  %s aterrissa na Bélgique." % PlayerStats.player_name,
		"União Europeia. Burocracias empilhadas até o teto.",
		"Três checkpoints antes de entrar na cidade.",
		"Cada um tem um preço.",
		"Advogado Thierry está esperando do outro lado.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 12.0)

func _setup_npcs() -> void:
	spawn_npc(Vector2i(7, 42), "Thierry (Advogado)",
		["Eu já passei por isso centenas de vezes.",
		 "Pague ou lute — são as únicas opções na entrada.",
		 "Com persuasão >= 2, posso interceder no tribunal.",
		 "Mas primeiro — chegue até mim."],
		Color(0.55, 0.75, 0.95)
	)
	spawn_npc(Vector2i(1, 30), "Migrante Nigeriano",
		["Terceira tentativa de entrar na EU.",
		 "Nas duas primeiras não tinha sats suficientes.",
		 "Agora juntei. Mas tem inflação nos checkpoints.",
		 "Cada ano eles cobram mais."],
		Color(0.65, 0.55, 0.45)
	)
	spawn_npc(Vector2i(7, 18), "Funcionária da Imigração",
		["Bem-vindo ao processo de entrada da UE.",
		 "Prepare seus documentos e sats.",
		 "Qualquer irregularidade será anotada.",
		 "Isso pode impactar seu processo de asilo."],
		Color(0.6, 0.6, 0.8)
	)
	spawn_npc(Vector2i(2, 8), "Mia",
		["Você chegou! Não acreditei quando vi seu nome.",
		 "Cruzamos o mesmo oceano em direções opostas.",
		 "Há um tribunal marcado para você.",
		 "Mas primeiro — o Agente Rastreador te segue."],
		Color(0.8, 0.5, 0.8)
	)

func _setup_fiscais() -> void:
	# Os 3 checkpoints EU: stationary (spawn_fiscal) — player paga ou luta
	var persuasao: int = PlayerStats.get_stat("persuasao")
	for i in range(3):
		var base_cost: int  = CHECKPOINT_COSTS[i]
		var cost:      int  = int(base_cost * (0.75 if persuasao >= 1 else 1.0))
		var tile := Vector2i(4, 36 - i * 10)
		spawn_fiscal(tile,
			"Checkpoint EU %d" % (i + 1),
			160 + i * 20, 28 + i * 5,
			80 + i * 15,
			cost, "item_panfleto"
		)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(8, 38), "EVT-001")   # FTXpress

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}
