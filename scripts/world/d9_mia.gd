## d9_mia.gd
## D9-B — Encontro com Mia (Visual Novel).
## 3 momentos de escolha. Persuasão >= 2 = resultado bom.
## O resultado é salvo em WorldManager.flags e afeta o tribunal.

extends "res://scripts/world/world_map_base.gd"

var _mia_result: String = "neutro"   # "bom" | "neutro" | "ruim"
var _encounter_done: bool = false

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 0
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"☕  Café na Rue des Dissidents, Bélgique.",
		"Mia está sentada perto da janela.",
		"Ela sabe que você está aqui.",
		"Esta conversa vai importar no tribunal.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 5.0)

func _setup_npcs() -> void:
	var mia := spawn_npc(Vector2i(4, 30), "Mia",
		["[Toque A para conversar]"],
		Color(0.8, 0.5, 0.8)
	)
	mia.first_interact.connect(func(_n):
		await DialogueManager.dialogue_finished
		_start_mia_encounter()
	)

	spawn_npc(Vector2i(7, 40), "Barista",
		["Dois expressos para a mesa do fundo?",
		 "Aquela moça te espera há uma hora.",
		 "Ela parece... com coisas na cabeça."],
		Color(0.55, 0.45, 0.35)
	)
	spawn_npc(Vector2i(1, 36), "Dissidente Amigo",
		["Conheço a Mia há anos.",
		 "Ela testemunhou em 3 tribunais.",
		 "Se ela estiver do seu lado, são boas chances.",
		 "Não estrague a conversa."],
		Color(0.5, 0.7, 0.5)
	)

func _setup_fiscais() -> void:
	pass   # Sem fiscais — ambiente civil

func _start_mia_encounter() -> void:
	if _encounter_done:
		return
	_encounter_done = true

	if is_instance_valid(_player):
		_player.set_can_move(false)

	DialogueManager.start([
		"💜  Mia: \"Eu sabia que você ia aparecer.\"",
		"\"Ouvi sobre sua viagem. Toda ela.\"",
		"\"O tribunal é em 3 dias.\"",
	])
	await DialogueManager.dialogue_finished

	# Escolha 1 — Como reagir ao reencontro
	var opts1: Array[String] = [
		"\"Eu também pensei muito em você.\"",
		"\"Preciso da sua ajuda para o tribunal.\"",
		"\"Por que você desapareceu?\"",
	]
	var c1: int = await ChoiceUI.ask(self, "Como você responde?", opts1)

	DialogueManager.start([_mia_response_1(c1)])
	await DialogueManager.dialogue_finished

	# Escolha 2 — Sobre o futuro
	var opts2: Array[String] = [
		"\"Quero ficar aqui. Construir algo real.\"",
		"\"Só quero liberdade. O resto a gente descobre.\"",
		"\"Não sei. Cada dia é uma decisão nova.\"",
	]
	var c2: int = await ChoiceUI.ask(self, "Mia: \"E depois do tribunal?\"", opts2)

	DialogueManager.start([_mia_response_2(c2)])
	await DialogueManager.dialogue_finished

	# Escolha 3 — Pedir testemunho
	var opts3: Array[String] = [
		"\"Você testemunharia no tribunal por mim?\"",
		"\"Não quero te envolver nisso.\"",
		"\"Qualquer coisa que você puder fazer...\"",
	]
	var c3: int = await ChoiceUI.ask(self, "Hora de decidir:", opts3)

	DialogueManager.start([_mia_response_3(c3)])
	await DialogueManager.dialogue_finished

	# Calcular resultado
	var persuasao: int = PlayerStats.get_stat("persuasao")
	var bom_choices: int = (1 if c1 == 0 else 0) + (1 if c2 == 0 else 0) + (1 if c3 == 0 else 0)
	if persuasao >= 2 or bom_choices >= 2:
		_mia_result = "bom"
		DialogueManager.start([
			"💜  Mia: \"Sabe o que? Vou testemunhar.\"",
			"\"Você merece uma chance justa.\"",
			"✅  Mia como testemunha — bônus no tribunal.",
		])
	elif bom_choices <= 0 and persuasao < 1:
		_mia_result = "ruim"
		DialogueManager.start([
			"😔  Mia: \"Eu queria te ajudar mais.\"",
			"\"Mas não sei se estarei disponível no tribunal.\"",
			"\"Cuide-se.\"",
		])
	else:
		_mia_result = "neutro"
		DialogueManager.start([
			"💜  Mia: \"Vou ver o que consigo fazer.\"",
			"\"Não prometo o testemunho. Mas talvez apareça.\"",
		])

	await DialogueManager.dialogue_finished

	# Salvar resultado
	WorldManager.set_flag("mia_result", _mia_result)
	if is_instance_valid(_player):
		_player.set_can_move(true)
	_map_complete = true

func _mia_response_1(c: int) -> String:
	match c:
		0: return "💜  Mia [sorri]: \"Eu também. Não sabia como dizer.\""
		1: return "💜  Mia: \"Sempre direto ao ponto. Tudo bem. O que você precisa?\""
		_: return "💜  Mia [pausa longa]: \"Tive que ir embora. Era diferente lá.\""

func _mia_response_2(c: int) -> String:
	match c:
		0: return "💜  Mia: \"Isso é tudo que eu queria ouvir.\""
		1: return "💜  Mia [ri]: \"Liberdade. A resposta mais honesta que já ouvi.\""
		_: return "💜  Mia: \"É assim mesmo. Dia por dia.\""

func _mia_response_3(c: int) -> String:
	match c:
		0: return "💜  Mia: \"Você tem coragem de pedir. Isso conta.\""
		1: return "💜  Mia: \"Respeito isso. Mas talvez eu testemunhe mesmo assim.\""
		_: return "💜  Mia [levanta]: \"Vejo o que posso fazer.\""

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}

func _setup_theme() -> void:
	_ground_key = "floor"
	_no_path = true
	_ground_tint = Color(0.8, 0.82, 0.86)
	_music_pitch = 0.93
