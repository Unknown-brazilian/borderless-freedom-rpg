## enemy_patrol.gd
## Inimigo visível no mapa que patrulha waypoints e persegue o player ao vê-lo.
## Ao tocar o player, inicia batalha turn-based automaticamente.

extends CharacterBody2D

const PATROL_SPEED  := 70.0
const CHASE_SPEED   := 160.0
const VISION_RADIUS := 192.0   # ~3 tiles de 64px
const LOST_RADIUS   := 384.0   # distância para desistir da perseguição
const CONTACT_DIST  := 18.0    # distância para iniciar batalha

enum State { PATROL, CHASE, BATTLE, DEFEATED }

@export var enemy_data: Dictionary = {
	"name": "Fiscal Patrulheiro",
	"hp": 50,
	"atk": 14,
	"reward_sats": 18,
	"bribe_cost": 25,
	"weakness_item": "item_spray",
	"is_boss": false,
}
@export var patrol_waypoints: Array[Vector2] = []
@export var patrol_wait_sec: float = 1.2
@export var sprite_color: Color = Color(0.72, 0.18, 0.18)
@export var defeated_on_load: bool = false   # carregado do WorldManager

var state: State = State.PATROL

var _wp_index:       int   = 0
var _wait_timer:     float = 0.0
var _battle_started: bool  = false
var _player:         Node  = null
var _sprite:         ColorRect = null
var _exclamation:    Label = null
var _defeat_key:     String = ""

# Bounds do mapa — override via spawn_patrol_enemy(patrol_spread, map_min, map_max)
@export var map_min: Vector2 = Vector2(64.0, 128.0)
@export var map_max: Vector2 = Vector2(576.0, 2944.0)

func _ready() -> void:
	add_to_group("enemy")
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)

	_create_visuals()
	_player = get_tree().get_first_node_in_group("player")

	_defeat_key = "patrol_defeated_%d" % get_instance_id()
	if defeated_on_load or WorldManager.get_flag(_defeat_key, false):
		_set_defeated()
		return

	# Waypoints em torno da posição inicial, respeitando bounds
	if patrol_waypoints.is_empty():
		var left  := _clamp_pos(position + Vector2(-96, 0))
		var right := _clamp_pos(position + Vector2( 96, 0))
		patrol_waypoints.append(right)
		patrol_waypoints.append(left)
	# Clampar waypoints existentes
	for i in range(patrol_waypoints.size()):
		patrol_waypoints[i] = _clamp_pos(patrol_waypoints[i])

func _clamp_pos(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, map_min.x, map_max.x), clampf(p.y, map_min.y, map_max.y))

func _create_visuals() -> void:
	# Carrega o sprite via ResourceLoader (funciona no editor E no APK exportado;
	# Image.load_from_file lê do filesystem e falha dentro do .pck).
	var sprite_path := "res://assets/sprites/fiscal_enemy.png"
	var tex: Texture2D = load(sprite_path) if ResourceLoader.exists(sprite_path) else null
	if tex:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale   = Vector2(2.0, 2.0)
		spr.position = Vector2(0, -20)
		add_child(spr)
	else:
		_sprite = ColorRect.new()
		_sprite.size = Vector2(44, 44)
		_sprite.position = Vector2(-22, -38)
		_sprite.color = sprite_color
		add_child(_sprite)

	var name_lbl := Label.new()
	name_lbl.text = enemy_data.get("name", "Fiscal")
	name_lbl.position = Vector2(-44, -68)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	add_child(name_lbl)

	_exclamation = Label.new()
	_exclamation.text = "❗"
	_exclamation.position = Vector2(-10, -90)
	_exclamation.add_theme_font_size_override("font_size", 22)
	_exclamation.visible = false
	add_child(_exclamation)

func _physics_process(delta: float) -> void:
	match state:
		State.PATROL:  _process_patrol(delta)
		State.CHASE:   _process_chase(delta)
		_:             velocity = Vector2.ZERO; move_and_slide()

# ─── PATROL ──────────────────────────────────────────────────────────────────

func _process_patrol(delta: float) -> void:
	_check_vision()

	if _wait_timer > 0.0:
		_wait_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if patrol_waypoints.is_empty():
		return

	var target: Vector2 = patrol_waypoints[_wp_index]
	var diff:   Vector2 = target - position

	if diff.length() < 8.0:
		_wp_index   = (_wp_index + 1) % patrol_waypoints.size()
		_wait_timer = patrol_wait_sec
		velocity    = Vector2.ZERO
	else:
		velocity = diff.normalized() * PATROL_SPEED

	move_and_slide()
	# Manter dentro dos bounds
	position = _clamp_pos(position)

func _check_vision() -> void:
	if not is_instance_valid(_player):
		return
	if BattleManager.state != BattleManager.State.IDLE:
		return
	var dist: float = position.distance_to(_player.position)
	if dist <= VISION_RADIUS:
		_exclamation.visible = true
		state = State.CHASE

# ─── CHASE ───────────────────────────────────────────────────────────────────

func _process_chase(delta: float) -> void:
	if not is_instance_valid(_player):
		state = State.PATROL
		return
	if BattleManager.state != BattleManager.State.IDLE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist: float = position.distance_to(_player.position)

	if dist > LOST_RADIUS:
		_exclamation.visible = false
		state = State.PATROL
		return

	if dist < CONTACT_DIST:
		_initiate_battle()
		return

	velocity = (_player.position - position).normalized() * CHASE_SPEED
	move_and_slide()
	position = _clamp_pos(position)

# ─── BATALHA ─────────────────────────────────────────────────────────────────

func _initiate_battle() -> void:
	if _battle_started:
		return
	_battle_started = true
	state = State.BATTLE
	velocity = Vector2.ZERO
	_exclamation.visible = false

	if _player.has_method("set_can_move"):
		_player.set_can_move(false)

	var data: Dictionary = enemy_data.duplicate()
	var intro_line := "👮  %s: \"Para aí! Documentação!\"" % data.get("name", "Fiscal")
	DialogueManager.start([intro_line])
	await DialogueManager.dialogue_finished

	BattleManager.battle_ended.connect(_on_battle_result, CONNECT_ONE_SHOT)
	BattleManager.start_battle(data)

func _on_battle_result(result: String) -> void:
	_battle_started = false
	match result:
		"victory":
			_set_defeated()
		"defeat":
			await get_tree().create_timer(1.5).timeout
			SceneTransition.go("res://scenes/ui/main_menu.tscn")
		"escaped":
			state = State.PATROL
			if is_instance_valid(_player) and _player.has_method("set_can_move"):
				_player.set_can_move(true)

func _set_defeated() -> void:
	state = State.DEFEATED
	WorldManager.set_flag(_defeat_key, true)
	modulate = Color(0.3, 0.3, 0.3, 0.4)
	set_physics_process(false)
	set_collision_layer_value(4, false)
	_exclamation.visible = false
	if is_instance_valid(_player) and _player.has_method("set_can_move"):
		_player.set_can_move(true)
