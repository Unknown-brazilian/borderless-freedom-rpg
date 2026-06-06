## fiscal_npc.gd
## Fiscal visível no mapa — ao interagir ou colidir inicia batalha.
## Pode ser subornado se player tiver sats suficientes (exibe opção no diálogo).

extends "res://scripts/world/npc.gd"

@export var enemy_data: Dictionary = {
	"name": "Fiscal",
	"hp": 40,
	"atk": 12,
	"reward_sats": 15,
	"bribe_cost": 20,
	"weakness_item": "item_spray",
	"is_boss": false,
}
@export var bribe_cost: int = 20
@export var defeated:   bool = false   # salvo no WorldManager.flags

var _battle_key: String = ""   # identificador único para não reiniciar batalha

func _ready() -> void:
	sprite_color = Color(0.72, 0.18, 0.18)
	super._ready()

	# Não bloqueia o caminho — o player interage voluntariamente ou colide
	set_collision_layer_value(4, true)    # layer enemy
	set_collision_layer_value(3, false)

	_battle_key = "fiscal_defeated_%s_%d" % [WorldManager.current_dungeon, get_instance_id()]
	if WorldManager.get_flag(_battle_key, false):
		defeated = true
		_hide_defeated()

func on_interact(_player: Node) -> void:
	if defeated or DialogueManager.is_active() or BattleManager.state != BattleManager.State.IDLE:
		return
	_face_player(_player)

	if SatEconomy.current_sats >= bribe_cost:
		# Oferece suborno
		var bribe_line := "👮  %s: \"Documentação! Para aí!\"\n[A: Lutar | B: Subornar (%d sats)]" % [npc_name, bribe_cost]
		DialogueManager.start([bribe_line])
		await DialogueManager.dialogue_finished
		_show_bribe_choice(_player)
	else:
		var attack_line := "👮  %s: \"Documentação! Para aí! Não tem escolha.\"" % npc_name
		DialogueManager.start([attack_line])
		await DialogueManager.dialogue_finished
		_start_battle()

func _show_bribe_choice(_player: Node) -> void:
	# Lança batalha por padrão — BribeUI poderia ser implementada aqui
	# Por ora, se persuasão >= 1, tenta suborno automaticamente
	var persuasao: int = PlayerStats.get_stat("persuasao")
	if persuasao >= 1 and SatEconomy.current_sats >= bribe_cost:
		SatEconomy.remove_sats(bribe_cost, "fiscal_bribe_map")
		DialogueManager.start(["👮  \"Tá bom... pode passar. Mas na próxima...\"\n+%d sats gastos." % bribe_cost])
		await DialogueManager.dialogue_finished
		_mark_defeated()
	else:
		_start_battle()

func _start_battle() -> void:
	var data := enemy_data.duplicate()
	data["name"] = npc_name
	data["bribe_cost"] = bribe_cost
	BattleManager.battle_ended.connect(_on_battle_result, CONNECT_ONE_SHOT)
	BattleManager.start_battle(data)

func _on_battle_result(result: String) -> void:
	match result:
		"victory":
			_mark_defeated()
		"defeat":
			# Volta ao menu — deportação
			await get_tree().create_timer(1.5).timeout
			SceneTransition.go("res://scenes/ui/main_menu.tscn")
		"escaped":
			pass   # fiscal continua no mapa

func _mark_defeated() -> void:
	defeated = true
	WorldManager.set_flag(_battle_key, true)
	_hide_defeated()

func _hide_defeated() -> void:
	modulate = Color(0.3, 0.3, 0.3, 0.5)
	set_collision_layer_value(4, false)
