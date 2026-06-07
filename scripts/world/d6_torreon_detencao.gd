## d6_torreon_detencao.gd
## D6-C especial — Segunda Prisão em Torreón / Gómez Palacio (Mexistão).
## Detenção mais longa e tensa que a primeira. Liberado em San Luís Potosí.

extends "res://scripts/world/world_map_base.gd"

const DETENTION_DAYS := 12

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 3
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"🚨  SEGUNDA DETENÇÃO — Torreón / Gómez Palacio",
		"Dessa vez foi diferente.",
		"Você foi detido numa blitz aleatória na saída da CDMX.",
		"%d dias no centro de detenção do norte." % DETENTION_DAYS,
		"Mais tempo. Mais interrogatórios.",
		"Eles querem saber de onde você veio.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 30.0)
	AutonomyBar.consume("food", 25.0)
	AutonomyBar.consume("water", 20.0)
	_start_interrogation()

func _start_interrogation() -> void:
	var persuasao: int = PlayerStats.get_stat("persuasao")
	var sats:      int = SatEconomy.current_sats

	DialogueManager.start([
		"🕵️  Agente Cruz: \"Dessa vez preciso de mais respostas.\"",
		"Agente Cruz: \"Por onde entrou no Mexistão?\"",
		"Agente Cruz: \"Quem te ajudou? Tem rede de apoio?\"",
	])
	await DialogueManager.dialogue_finished

	if persuasao >= 3:
		DialogueManager.start([
			"🗣️  Você responde com calma e transparência.",
			"Agente Cruz: \"...Interessante. Você é diferente.\"",
			"Cruz: \"Vai ser liberado em San Luís Potosí.\"",
			"\"Não apareça mais por aqui.\"",
			"✅  Saída por persuasão alta.",
		])
	elif persuasao >= 1 and sats >= 200:
		SatEconomy.remove_sats(200, "torreon_bribe")
		DialogueManager.start([
			"💰  Você negocia discretamente.",
			"A quantia some. A porta se abre.",
			"📉  -200 sats.",
			"Ônibus para San Luís Potosí. De graça, desta vez.",
		])
	else:
		var penalty: int = min(sats, 120)
		SatEconomy.remove_sats(penalty, "torreon_penalty")
		DialogueManager.start([
			"😔  Sem argumentos e sem sats suficientes.",
			"Passam 12 dias.",
			"Você vai perder peso aqui.",
			"Finalmente liberado. Ônibus para San Luís Potosí.",
			"📉  -%d sats." % penalty,
		])

	await DialogueManager.dialogue_finished

	DialogueManager.start([
		"😮‍💨  San Luís Potosí. Alívio.",
		"Você respira ar livre pela primeira vez em semanas.",
		"Ainda falta Saltillo. E depois...",
		"A fronteira.",
	])
	await DialogueManager.dialogue_finished
	_map_complete = true

func _setup_npcs() -> void:
	spawn_npc(Vector2i(2, 40), "Colega Sírio",
		["Terceira vez que me prendem.",
		 "Nunca mais volto pro meu país.",
		 "É isso ou é isso."],
		Color(0.6, 0.55, 0.45)
	)
	spawn_npc(Vector2i(7, 36), "Advogado Mexistão",
		["Sua situação tem saída.",
		 "Mas vai custar sats.",
		 "Ou muita persuasão.",
		 "Preferencialmente os dois."],
		Color(0.65, 0.75, 0.95)
	)
	spawn_npc(Vector2i(4, 24), "Agente Cruz",
		["Você de novo?",
		 "Mexistão não gosta de imigrantes sem documentação.",
		 "Prove que pode se sustentar ou pague a multa."],
		Color(0.8, 0.3, 0.3)
	)
	spawn_npc(Vector2i(6, 14), "Detento Bolivariano",
		["Eu ouvi que tem trabalho em Saltillo.",
		 "Fábrica. Distribuidora de carnes.",
		 "Paga bem, dizem. Dá para juntar sats."],
		Color(0.55, 0.65, 0.55)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(3, 30), "Guarda do Bartlett",     70, 20, 0, 75, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(6, 22), "Guarda do Cuauhtémoc Blanco",     75, 22, 0, 80, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(4, 16), "Inspetor da Layda Sansores", 80, 24, 0, 90, "item_panfleto", 3)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(1, 38), "EVT-009")   # Carteira Hardware Pré-Configurada

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}

func _setup_theme() -> void:
	_ground_key = "floor"
	_no_path = true
	_ground_tint = Color(0.66, 0.64, 0.68)
	_music_pitch = 0.92
