## d6_saltillo.gd
## D6-E — Saltillo: A Distribuidora de Carnes (4 meses de trabalho).
## O mapa mais importante narrativamente. 4 minijogos representam o trabalho real.
## Ao completar os 4 meses, o player acumula sats para tentar a fronteira.

extends "res://scripts/world/world_map_base.gd"

const MONTHS_TOTAL    := 4
const SAT_PER_WEEK    := 40      # sats por semana (4 semanas × 4 meses = 16 semanas)
const WEEKS_PER_MONTH := 4

var _month_current:   int  = 0
var _week_current:    int  = 0
var _tasks_this_week: int  = 0
var _tasks_needed:    int  = 3    # tarefas por semana para receber pagamento
var _total_earned:    int  = 0

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 0   # sem boss — completar os 4 meses é o objetivo
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"🏭  Saltillo — Distribuidora de Carnes Don Rogelio",
		"Você conseguiu emprego.",
		"O serviço não é glamouroso.",
		"Mas paga. E você precisa de sats.",
		"4 meses. 16 semanas. Depois: a fronteira.",
		"Don Rogelio é justo — mas exigente.",
	])
	await DialogueManager.dialogue_finished
	_start_work_month()

func _start_work_month() -> void:
	_month_current += 1
	_week_current   = 0
	if _month_current > MONTHS_TOTAL:
		_finish_4_months()
		return

	DialogueManager.start([
		"📅  Mês %d de %d — Distribuidora de Carnes" % [_month_current, MONTHS_TOTAL],
		"Mais uma semana começa.",
		"Complete as tarefas para receber seu pagamento semanal.",
	])
	await DialogueManager.dialogue_finished
	_start_work_week()

func _start_work_week() -> void:
	_week_current  += 1
	_tasks_this_week = 0
	if _week_current > WEEKS_PER_MONTH:
		_start_work_month()
		return

	var week_total := (_month_current - 1) * WEEKS_PER_MONTH + _week_current
	DialogueManager.start([
		"📋  Semana %d — Escolha uma tarefa:" % week_total,
		"Faça pelo menos %d tarefas para receber o pagamento." % _tasks_needed,
		"Ou fale com Don Rogelio para encerrar a semana parcialmente.",
	])
	await DialogueManager.dialogue_finished

func _on_task_complete(task_name: String, sats_earned: int) -> void:
	_tasks_this_week += 1
	_total_earned    += sats_earned
	SatEconomy.add_sats(sats_earned, "trabalho_" + task_name)
	GameStats.add_to_stat("dias_trabalhados", 1)

	var week_total := (_month_current - 1) * WEEKS_PER_MONTH + _week_current
	DialogueManager.start([
		"✅  %s concluído! +%d sats." % [task_name, sats_earned],
		"Semana %d: %d/%d tarefas." % [week_total, _tasks_this_week, _tasks_needed],
	])
	await DialogueManager.dialogue_finished

	if _tasks_this_week >= _tasks_needed:
		SatEconomy.add_sats(SAT_PER_WEEK, "pagamento_semanal")
		_total_earned += SAT_PER_WEEK
		DialogueManager.start([
			"💵  Don Rogelio: \"Bom trabalho. Pagamento da semana: %d sats.\"" % SAT_PER_WEEK,
			"Total acumulado até agora: %d sats." % _total_earned,
		])
		await DialogueManager.dialogue_finished
		_start_work_week()

func _finish_4_months() -> void:
	DialogueManager.start([
		"🎉  4 MESES CONCLUÍDOS!",
		"Don Rogelio: \"Você foi o melhor funcionário que já tive.\"",
		"\"Leva esse bônus.\"",
		"Freddie: \"É hora, mano. Vai atrás do seu sonho.\"",
		"Total acumulado: %d sats." % _total_earned,
		"Agora você tem o suficiente para tentar a fronteira.",
		"Saltillo → fronteira norte do Mexistão.",
	])
	await DialogueManager.dialogue_finished

	# Bônus de despedida
	SatEconomy.add_sats(80, "bonus_despedida")
	_map_complete = true

func _setup_npcs() -> void:
	# Don Rogelio — chefe
	var don := spawn_npc(Vector2i(5, 42), "Don Rogelio",
		["Bem-vindo, filho.",
		 "Aqui não perguntamos de onde você vem.",
		 "Só se você trabalha.",
		 "E você vai trabalhar. Encerre a semana quando quiser."],
		Color(0.75, 0.55, 0.3)
	)
	don.first_interact.connect(func(_n):
		await DialogueManager.dialogue_finished
		if _tasks_this_week < _tasks_needed and _tasks_this_week > 0:
			# Pagamento parcial e avança semana — evita softlock
			var partial := int(SAT_PER_WEEK * float(_tasks_this_week) / float(_tasks_needed))
			SatEconomy.add_sats(partial, "pagamento_parcial")
			DialogueManager.start(["Don Rogelio: "Semana encerrada. %d sats parciais."" % partial])
			await DialogueManager.dialogue_finished
			_start_work_week()
	)

	# Freddie — colega que dá carona (referência real)
	spawn_npc(Vector2i(7, 40), "Freddie",
		["Cara, essa distribuidora é pesada.",
		 "Mas é honesta. Don Rogelio paga direto.",
		 "Eu to juntando sats pra voltar pra família.",
		 "E você?"],
		Color(0.4, 0.7, 0.9)
	)

	# NPCs de trabalho — cada um representa uma tarefa
	_spawn_task_npc(Vector2i(2, 36), "Açougueiro Héctor",
		"Desossa de Porco",
		["Hoje tem porco pra desossar.",
		 "Vinte carcaças. Dois minutos cada.",
		 "Me fala quando terminar."],
		30
	)
	_spawn_task_npc(Vector2i(8, 34), "Operador Carlos",
		"Empilhadeira",
		["Os paletes do depósito precisam ser movidos.",
		 "Cuidado pra não derrubar as caixas.",
		 "Cada erro custa tempo."],
		25
	)
	_spawn_task_npc(Vector2i(3, 26), "Motorista Luiz",
		"Entrega de Caminhão",
		["Tem 5 pontos pra entregar hoje.",
		 "O mapa da cidade você já conhece.",
		 "Não se perde."],
		35
	)
	_spawn_task_npc(Vector2i(6, 18), "Faxineiro Marcos",
		"Limpeza do Frigorífico",
		["O chão do frigorífico precisa ser lavado.",
		 "É monótono. Mas paga.",
		 "E pelo menos é quente aqui dentro."],
		20
	)

	# Colegas imigrantes com histórias
	spawn_npc(Vector2i(1, 32), "Jorge (Venezuela)",
		["Vim da Venezualária.",
		 "O que aconteceu lá você não vai acreditar.",
		 "Hiperinflação. 100% ao mês.",
		 "Bitcoin me salvou."],
		Color(0.7, 0.7, 0.3)
	)
	spawn_npc(Vector2i(8, 26), "Amara (Centrolândia)",
		["Passei pelo Darién a pé.",
		 "5 dias na selva.",
		 "Nunca mais.",
		 "Mas valeu. Tô aqui."],
		Color(0.55, 0.8, 0.6)
	)
	spawn_npc(Vector2i(3, 14), "Viktor (Bolivária)",
		["Na fronteira norte, tem coiotes.",
		 "Cobra caro e às vezes abandona.",
		 "Com sats, você passa por conta própria.",
		 "Sem depender de ninguém."],
		Color(0.7, 0.5, 0.7)
	)

func _setup_fiscais() -> void:
	# Ocasionalmente fiscais trabalhistas aparecem
	spawn_patrol_enemy(Vector2i(5, 22), "Fiscal Trabalhista", 65, 18, 20, 55, "item_panfleto", 3)
	spawn_patrol_enemy(Vector2i(4, 10), "Inspetor Fiscal",    70, 20, 22, 60, "item_camera",   2)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(9, 42), "EVT-010")   # NanoSats Protocol

func _get_boss_id() -> String:
	return ""

func _get_boss_data() -> Dictionary:
	return {}

# ─── Helpers ─────────────────────────────────────────────────────────────────

func _spawn_task_npc(tile: Vector2i, name_str: String, task_name: String,
		intro: Array, sats: int) -> void:
	var npc_node: Node = spawn_npc(tile, name_str, intro, Color(0.5, 0.65, 0.5))
	npc_node.set_meta("task_name", task_name)
	npc_node.set_meta("task_sats", sats)
	# Conecta sinal first_interact para lançar o minijogo após o diálogo de intro
	npc_node.first_interact.connect(func(_n: Node):
		await DialogueManager.dialogue_finished
		_launch_minigame(task_name, sats)
	)

func _launch_minigame(task_name: String, _base_reward: int) -> void:
	var scene_map: Dictionary = {
		"Desossa de Porco":      "res://scenes/minigames/DesossaMinigame.tscn",
		"Empilhadeira":          "res://scenes/minigames/EmpilhadeiraMinigame.tscn",
		"Entrega de Caminhão":   "res://scenes/minigames/CaminhaoMinigame.tscn",
		"Limpeza do Frigorífico":"res://scenes/minigames/LimpezaMinigame.tscn",
	}

	if task_name not in scene_map:
		_on_task_complete(task_name, _base_reward)
		return

	var mg: MinigameBase = load(scene_map[task_name]).instantiate() as MinigameBase
	add_child(mg)
	var sats_earned: int = await mg.minigame_completed
	_on_task_complete(task_name, sats_earned)
