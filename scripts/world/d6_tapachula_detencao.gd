## d6_tapachula_detencao.gd
## D6-A especial — Prisão pela Migração em Tapachula (Mexistão).
## O player é detido, colocado num centro de detenção e precisa negociar a saída.
## Mecânica: tribunal/negociação. Persuasão define o resultado.

extends "res://scripts/world/world_map_base.gd"

const DETENTION_DAYS := 3
var _negotiation_done: bool = false

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 3
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"🚨  DETENÇÃO — Centro de Imigração de Tapachula",
		"Você foi interceptado perto de Huixtla.",
		"Agentes da Migra te detiveram sem aviso.",
		"Você está num centro de detenção há %d dias." % DETENTION_DAYS,
		"Para sair, você precisa provar que tem meios próprios.",
		"Ou negociar. Persuasão ajuda.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 20.0)
	AutonomyBar.consume("food", 15.0)
	_start_negotiation()

func _start_negotiation() -> void:
	if _negotiation_done:
		return
	_negotiation_done = true

	var persuasao: int = PlayerStats.get_stat("persuasao")
	var sats: int      = SatEconomy.current_sats
	var doc_item: bool = "item_camera" in PlayerInventory.unlocked

	if persuasao >= 2:
		DialogueManager.start([
			"🗣️  Você argumenta sua situação com calma e confiança.",
			"Juiz: \"Hm. Seus argumentos são sólidos.\"",
			"Juiz: \"Liberado. Cuidado da próxima vez.\"",
			"✅  Saída pela persuasão.",
		])
	elif sats >= 150:
		SatEconomy.remove_sats(150, "tapachula_bribe")
		DialogueManager.start([
			"💰  Você paga a 'multa administrativa'.",
			"Oficial: \"Tudo certo. Pode ir.\"",
			"📉  -150 sats.",
		])
	elif doc_item:
		DialogueManager.start([
			"📷  Você mostra sua documentação fotográfica da viagem.",
			"Oficial: \"Isso é... muita documentação.\"",
			"Oficial: \"Está bem. Pode ir.\"",
		])
	else:
		SatEconomy.remove_sats(min(sats, 80), "tapachula_penalty")
		DialogueManager.start([
			"😔  Você não tem argumentos suficientes.",
			"Passam mais 5 dias.",
			"Eventualmente te liberam com uma advertência.",
			"📉  -80 sats (o que tiver).",
		])

	await DialogueManager.dialogue_finished
	DialogueManager.start([
		"🍽️  Você comemora com uma refeição em Tapachula.",
		"Pequena vitória. Mas ainda faltam 3.000 km.",
	])
	await DialogueManager.dialogue_finished
	_map_complete = true   # após último diálogo — evita transição mid-sentence

func _setup_npcs() -> void:
	spawn_npc(Vector2i(2, 40), "Detento Hondurenho",
		["Você também?",
		 "Faz 2 semanas que estou aqui.",
		 "Persuasão é tudo nesse lugar.",
		 "Se tiver dinheiro, sai mais rápido."],
		Color(0.5, 0.6, 0.5)
	)
	spawn_npc(Vector2i(6, 38), "Advogada Aliada",
		["Eu posso te ajudar.",
		 "Mas vou precisar de provas da sua rota.",
		 "Fotos ajudam muito — câmera?"],
		Color(0.7, 0.7, 1.0)
	)
	spawn_npc(Vector2i(4, 30), "Oficial Ramírez",
		["Você está aqui por violação de entrada.",
		 "A 'multa' é 150 sats.",
		 "Ou prove que tem capacidade de se sustentar."],
		Color(0.8, 0.35, 0.35)
	)

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 20), "Guarda do Garduño", 55, 16, 0, 60, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(7, 32), "Inspetor do Encinas", 60, 18, 0, 70, "item_camera", 2)

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}

func _setup_theme() -> void:
	_ground_key = "floor"
	_no_path = true
	_ground_tint = Color(0.68, 0.68, 0.74)
