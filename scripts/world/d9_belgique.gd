## d9_belgique.gd
## D9-E — Fuga pelos Canais + Boss: Von der Leyen, a Rastreadora-Mor.
## Mia reaparece 2x para reabastecer recursos.
## Boss tem HP reduzido se tribunal_won = true.
## Fim da campanha.

extends "res://scripts/world/world_map_base.gd"

var _mia_assist_count: int = 0

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 4
	super._ready()

func _intro_dialogue() -> void:
	var tribunal_won: bool = WorldManager.get_flag("tribunal_won", false) as bool
	DialogueManager.start([
		"🌊  Canais da Bélgique — Noite",
		"O Agente Rastreador foi ativado.",
		"Seus algoritmos de vigilância cobrem a cidade.",
		"Mia conhece uma rota pelos canais.",
		"É agora ou nunca.",
		"⚖️  O tribunal favorável te deu tempo extra." if tribunal_won else "⚠️  O veredicto desfavorável acelerou o rastreamento.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 15.0)

func _setup_npcs() -> void:
	# Mia — reaparece 2x para reabastecer
	var mia1 := spawn_npc(Vector2i(7, 36), "Mia",
		["Rápido. Esse canal leva para o lado leste.",
		 "Você vai precisar de energia."],
		Color(0.8, 0.5, 0.8)
	)
	mia1.first_interact.connect(func(_n):
		await DialogueManager.dialogue_finished
		_mia_resupply()
	)

	var mia2 := spawn_npc(Vector2i(2, 20), "Mia",
		["Ainda me segue. Bom.",
		 "Um pouco mais de água e comida."],
		Color(0.8, 0.5, 0.8)
	)
	mia2.first_interact.connect(func(_n):
		await DialogueManager.dialogue_finished
		_mia_resupply()
	)

	spawn_npc(Vector2i(6, 12), "Barqueiro",
		["Não me pergunte nada.",
		 "Só sigo as correntes.",
		 "Há uma saída ao norte.",
		 "Mas algo me diz que você sabe disso."],
		Color(0.45, 0.5, 0.55)
	)

func _setup_fiscais() -> void:
	# Patrulhas dos canais — mais fortes que checkpoints normais
	spawn_patrol_enemy(Vector2i(4, 38), "Drone da Von der Leyen",    200, 38, 110, 999, "item_camera", 3)
	spawn_patrol_enemy(Vector2i(6, 28), "Agente do Macron",  210, 40, 115, 999, "item_spray",  2)
	spawn_patrol_enemy(Vector2i(2, 18), "Rastreador do De Croo", 220, 42, 120, 999, "item_camera", 3)

func _mia_resupply() -> void:
	_mia_assist_count += 1
	AutonomyBar.refill_all()
	DialogueManager.start([
		"💜  Mia reabastece tudo.",
		"Energia, água e comida restaurados.",
		"\"Vai em frente. Eu seguro aqui.\"",
	])

func _get_boss_id() -> String:
	return "BOSS-D9-FINAL"

func _get_boss_data() -> Dictionary:
	var tribunal_won: bool = WorldManager.get_flag("tribunal_won", false) as bool
	var mia_bom: bool = (WorldManager.get_flag("mia_result", "neutro") as String) == "bom"

	# HP base: 450. Reduções cumulativas por conquistas anteriores
	var hp := 450
	if tribunal_won: hp -= 80      # veredicto favorável enfraqueceu o rastreamento
	if mia_bom:      hp -= 50      # Mia forneceu dados sobre algoritmos

	return {
		"name": "Von der Leyen, a Rastreadora-Mor",
		"hp":   hp,
		"atk":  55,
		"reward_sats": 350,
		"bribe_cost":  999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D9-FINAL",
		"intro_lines": [
			"🤖  AGENTE RASTREADOR FINAL — ATIVADO",
			"\"Identidade rastreada. Localização confirmada.\"",
			"\"%d tentativas de fuga registradas. Captura iminente.\"" % (9 - _mia_assist_count),
			"HP: %d  |  ATK: 55" % hp,
			"Use a câmera para expor seus algoritmos.",
		],
		"victory_lines": [
			"🏆  AGENTE RASTREADOR — DESTRUÍDO!",
			"Os sistemas de vigilância entram em colapso.",
			"💜  Mia: \"Você conseguiu.\"",
			"💜  Mia: \"Você é livre.\"",
			"🔑  Uma última prova de soberania...",
		],
	}

func _setup_theme() -> void:
	_ground_tint = Color(0.78, 0.84, 0.95)
	_music_pitch = 0.96
