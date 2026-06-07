## d9_obra.gd
## D9-C — Obra de Construção na Bélgique.
## Player trabalha 2 semanas para pagar o advogado Thierry.
## Mini-game de construção (pick-and-carry tijolos).

extends "res://scripts/world/world_map_base.gd"

const ADVOGADO_COST := 80   # sats para contratar Thierry

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 0
	super._ready()

func _intro_dialogue() -> void:
	var sats := SatEconomy.current_sats
	DialogueManager.start([
		"🏗️  Canteiro de obras — Bélgique",
		"O advogado Thierry cobra %d sats." % ADVOGADO_COST,
		"Você tem %d sats agora." % sats,
		"Trabalho temporário. Duas semanas. Paga bem.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 8.0)

func _setup_npcs() -> void:
	spawn_npc(Vector2i(6, 42), "Engenheiro Jean",
		["Bom. Você apareceu.",
		 "Obra não espera por ninguém aqui.",
		 "Dois dias de serviço — tijolos e mais tijolos.",
		 "Fale com o Karel para começar."],
		Color(0.6, 0.65, 0.45)
	)

	var karel := spawn_npc(Vector2i(2, 36), "Karel (Mestre de Obras)",
		["Simples: pega tijolo, coloca na parede.",
		 "Sem filosofia.",
		 "[Trabalhar]"],
		Color(0.5, 0.55, 0.4)
	)
	karel.first_interact.connect(func(_n):
		await DialogueManager.dialogue_finished
		# Verificar se é o diálogo do Karel que terminou (não outro NPC)
		if not _map_complete:
			_launch_obra()
	)

	spawn_npc(Vector2i(7, 28), "Colega Turco",
		["Você faz isso há quanto tempo?",
		 "Eu trabalho em obra desde os 16.",
		 "Dinheiro vai para casa. Família primeiro.",
		 "Bitcoin? Já ouvi falar. Me explica depois."],
		Color(0.65, 0.55, 0.35)
	)
	spawn_npc(Vector2i(2, 18), "Thierry",
		["Bom que está trabalhando.",
		 "Preciso de %d sats para representar você." % ADVOGADO_COST,
		 "Com o testemunho da Mia, as chances sobem.",
		 "Apareça no tribunal em 2 dias."],
		Color(0.55, 0.75, 0.95)
	)
	spawn_npc(Vector2i(7, 10), "Trabalhador Sírio",
		["Você sabe o que é exílio real?",
		 "É quando você assina papéis em 3 idiomas",
		 "e ainda assim ninguém sabe quem você é.",
		 "Pelo menos aqui pagam em dia."],
		Color(0.6, 0.6, 0.5)
	)

func _setup_fiscais() -> void:
	# Inspetor trabalhista pode aparecer
	spawn_patrol_enemy(Vector2i(5, 22), "Inspetor do Charles Michel", 80, 22, 30, 65, "item_panfleto", 2)

func _launch_obra() -> void:
	if is_instance_valid(_player):
		_player.set_can_move(false)

	DialogueManager.start([
		"🧱  Karel: \"Hora de trabalhar.\"",
		"\"Pega os tijolos, coloca nos slots. Simples.\"",
	])
	await DialogueManager.dialogue_finished

	var mg: MinigameBase = preload("res://scenes/minigames/ConstrucaoMinigame.tscn").instantiate() as MinigameBase
	add_child(mg)
	var sats: int = await mg.minigame_completed

	SatEconomy.add_sats(sats, "obra_belgique")
	var total_sats := SatEconomy.current_sats

	DialogueManager.start([
		"✅  Semana 1 — trabalho completo!",
		"+%d sats." % sats,
	])
	await DialogueManager.dialogue_finished

	# Segunda semana
	var mg2: MinigameBase = preload("res://scenes/minigames/ConstrucaoMinigame.tscn").instantiate() as MinigameBase
	add_child(mg2)
	var sats2: int = await mg2.minigame_completed

	SatEconomy.add_sats(sats2, "obra_belgique_2")
	total_sats = SatEconomy.current_sats

	DialogueManager.start([
		"✅  Semana 2 concluída! +%d sats." % sats2,
		"Total: %d sats." % total_sats,
	])
	await DialogueManager.dialogue_finished

	# Pagar Thierry automaticamente se tiver sats
	if total_sats >= ADVOGADO_COST:
		SatEconomy.remove_sats(ADVOGADO_COST, "advogado_thierry")
		WorldManager.set_flag("thierry_paid", true)
		DialogueManager.start([
			"👨‍⚖️  Thierry: \"Pago. Estarei no tribunal.\"",
			"\"Com Thierry + Mia (se resultado bom): vantagem máxima.\"",
			"-%d sats." % ADVOGADO_COST,
		])
	else:
		DialogueManager.start([
			"😔  Não há sats suficientes para Thierry.",
			"\"Faço de graça desta vez. Mas só desta vez.\"",
			"\"Não conte com isso no futuro.\"",
		])
		WorldManager.set_flag("thierry_paid", false)

	await DialogueManager.dialogue_finished
	if is_instance_valid(_player):
		_player.set_can_move(true)
	_map_complete = true

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}

func _setup_theme() -> void:
	_ground_key = "floor"
	_no_path = true
	_ground_tint = Color(0.85, 0.8, 0.7)
