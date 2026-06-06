## d9_tribunal.gd
## D9-D — Tribunal Final da Bélgique.
## 4 acusações: antes de cada batalha, escolha como responder.
## Resposta com evidência/persuasão = inimigo enfraquecido.
## Win 3/4 = veredicto favorável + 30 sats bônus.
## Mia aparece se mia_result = "bom".

extends "res://scripts/world/world_map_base.gd"

const ACCUSATIONS := [
	{
		"name": "Promotor Fiscal",
		"charge": "\"Entrada irregular na Bélgique via rota não autorizada.\"",
		"hp_full": 100, "hp_weak": 50, "atk": 30,
		"defense_options": [
			"Apresentar rota documentada (câmera)",
			"Invocar direito de asilo (persuasão)",
			"Aceitar parcialmente (-20 sats)",
		],
		"defense_item": "item_camera",
	},
	{
		"name": "Promotor Trabalhista",
		"charge": "\"Trabalho informal durante período de regularização.\"",
		"hp_full": 110, "hp_weak": 55, "atk": 32,
		"defense_options": [
			"Apresentar recibo de obra (panfleto)",
			"Persuadir com contexto econômico",
			"Reconhecer erro e pagar multa (-30 sats)",
		],
		"defense_item": "item_panfleto",
	},
	{
		"name": "Promotor de Identidade",
		"charge": "\"Identidade digital não verificável nos sistemas EU.\"",
		"hp_full": 120, "hp_weak": 60, "atk": 34,
		"defense_options": [
			"Apresentar seed phrase como prova de identidade",
			"Testemunho de Thierry (requer thierry_paid)",
			"Permanecer em silêncio",
		],
		"defense_item": "item_chave",
	},
	{
		"name": "Promotor de Ordem Pública",
		"charge": "\"Perturbação de fronteiras soberanas em múltiplos países.\"",
		"hp_full": 130, "hp_weak": 65, "atk": 36,
		"defense_options": [
			"Invocar princípio da livre circulação",
			"Testemunho de Mia (requer mia_result bom)",
			"Apelar para julgamento por mérito próprio",
		],
		"defense_item": "item_camera",
	},
]

var _victories:      int = 0
var _accusation_idx: int = 0
var _trial_active:   bool = false

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 0
	super._ready()

func _intro_dialogue() -> void:
	var mia_result: String = WorldManager.get_flag("mia_result", "neutro") as String
	var thierry_paid: bool = WorldManager.get_flag("thierry_paid", false) as bool

	DialogueManager.start([
		"⚖️  Sala do Tribunal — Bélgique",
		"Quatro acusações. Cada uma é uma batalha.",
		"Antes de cada batalha, você pode preparar sua defesa.",
		"Uma boa defesa enfraquece o promotor.",
		"3 de 4 vitórias = veredicto favorável.",
	])
	await DialogueManager.dialogue_finished

	if mia_result == "bom":
		DialogueManager.start([
			"💜  Mia chega na última hora.",
			"\"Estou aqui para testemunhar.\"",
			"\"Não vamos deixar que isso seja injusto.\"",
		])
		await DialogueManager.dialogue_finished

	if thierry_paid:
		DialogueManager.start([
			"👨‍⚖️  Thierry: \"Recebi seu caso. Estou pronto.\"",
			"\"O promotor de identidade vai ser difícil.\"",
			"\"Mas juntos podemos vencer.\"",
		])
		await DialogueManager.dialogue_finished

	await get_tree().create_timer(0.5).timeout
	_start_next_accusation()

func _start_next_accusation() -> void:
	if _accusation_idx >= ACCUSATIONS.size():
		_conclude_trial()
		return

	var acc: Dictionary = ACCUSATIONS[_accusation_idx]
	_trial_active = true

	if is_instance_valid(_player):
		_player.set_can_move(false)

	# Acusação
	DialogueManager.start([
		"⚖️  Acusação %d de 4:" % (_accusation_idx + 1),
		acc.get("charge", ""),
		"%s se levanta." % acc.get("name", "Promotor"),
	])
	await DialogueManager.dialogue_finished

	# Escolha de defesa
	var opts: Array[String] = []
	opts.assign(acc.get("defense_options", ["Sem defesa"]))
	var choice := await ChoiceUI.ask(self, "Como você se defende?", opts)

	# Avaliar defesa
	var weakened := _evaluate_defense(acc, choice)
	var hp: int = acc.get("hp_weak" if weakened else "hp_full", 100) as int

	if weakened:
		DialogueManager.start(["⚡  Boa defesa! Promotor enfraquecido. (HP: %d)" % hp])
	else:
		DialogueManager.start(["😬  Defesa fraca. Promotor em força total. (HP: %d)" % hp])
	await DialogueManager.dialogue_finished

	# Batalha
	var data := {
		"name": acc.get("name"),
		"hp": hp,
		"atk": acc.get("atk", 30),
		"reward_sats": 20,
		"bribe_cost": 999,
		"weakness_item": acc.get("defense_item", "item_camera"),
		"is_boss": false,
	}

	BattleManager.battle_ended.connect(_on_accusation_result, CONNECT_ONE_SHOT)
	BattleManager.start_battle(data)

func _has_item(item_id: String) -> bool:
	return item_id in PlayerInventory.unlocked

func _evaluate_defense(acc: Dictionary, choice: int) -> bool:
	var persuasao := PlayerStats.get_stat("persuasao")
	var mia_result: String = WorldManager.get_flag("mia_result", "neutro") as String
	var thierry_paid: bool = WorldManager.get_flag("thierry_paid", false) as bool
	var has_item := _has_item(acc.get("defense_item", ""))

	match _accusation_idx:
		0:   # Entrada irregular
			match choice:
				0: return has_item                     # câmera
				1: return persuasao >= 2
				2:
					SatEconomy.remove_sats(20, "tribunal_partial")
					return false
		1:   # Trabalho informal
			match choice:
				0: return _has_item("item_panfleto")
				1: return persuasao >= 1
				2:
					SatEconomy.remove_sats(30, "tribunal_fine")
					return false
		2:   # Identidade digital
			match choice:
				0: return true                         # seed = sempre válida
				1: return thierry_paid
				2: return false                        # silêncio = sem defesa
		3:   # Ordem pública
			match choice:
				0: return persuasao >= 2
				1: return mia_result == "bom"
				2: return persuasao >= 1
	return false

func _on_accusation_result(result: String) -> void:
	match result:
		"victory":
			_victories += 1
			DialogueManager.start([
				"✅  Acusação %d — VITÓRIA!" % (_accusation_idx + 1),
				"Promotor recua.",
			])
		"defeat":
			DialogueManager.start([
				"❌  Acusação %d — DERROTA." % (_accusation_idx + 1),
				"O promotor marca um ponto.",
			])
		"escaped":
			DialogueManager.start(["⚖️  Você recusou a batalha. Promotor avança."])

	await DialogueManager.dialogue_finished
	_accusation_idx += 1
	if is_instance_valid(_player):
		_player.set_can_move(false)
	await get_tree().create_timer(0.5).timeout
	_start_next_accusation()

func _conclude_trial() -> void:
	_trial_active = false
	var won := _victories >= 3

	if won:
		SatEconomy.add_sats(30, "tribunal_bonus")
		WorldManager.set_flag("tribunal_won", true)
		DialogueManager.start([
			"⚖️  VEREDICTO: FAVORÁVEL",
			"%d de 4 acusações rejeitadas." % _victories,
			"+30 sats — bônus de veredicto.",
			"Thierry: \"Excelente. Mas o Agente Rastreador ainda te busca.\"",
			"Mia: \"Os canais são sua única saída agora.\"",
		])
	else:
		WorldManager.set_flag("tribunal_won", false)
		DialogueManager.start([
			"⚖️  VEREDICTO: DESFAVORÁVEL",
			"%d de 4 acusações rejeitadas. Insuficiente." % _victories,
			"Thierry: \"Ainda podemos apelar.\"",
			"Thierry: \"Mas o tempo está acabando.\"",
			"Mia: \"Vá pelos canais. É sua única saída.\"",
		])

	await DialogueManager.dialogue_finished
	if is_instance_valid(_player):
		_player.set_can_move(true)
	_map_complete = true

func _setup_npcs() -> void:
	spawn_npc(Vector2i(1, 40), "Escrivão",
		["Silêncio no tribunal.",
		 "Os promotores estão prontos.",
		 "Boa sorte."],
		Color(0.5, 0.5, 0.6)
	)
	spawn_npc(Vector2i(7, 38), "Jornalista",
		["Cubro casos de dissidentes há 10 anos.",
		 "O seu é um dos mais interessantes.",
		 "Posso publicar a história — se você vencer."],
		Color(0.6, 0.75, 0.5)
	)

func _setup_fiscais() -> void:
	pass   # Os promotores são instanciados via código, não spawn

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}
