## player_controller_2d.gd
## Player top-down para o RPG estilo Game Boy.
## Movimento em grid (64px por passo) ou contínuo (com interpolação).
## Controles: D-Pad virtual (TouchDPad) ou emulação mouse no editor.

extends CharacterBody2D

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal interacted(direction: Vector2)
signal player_moved(tile_pos: Vector2i)

# ─── Constantes ───────────────────────────────────────────────────────────────
const TILE_SIZE     := 64
const MOVE_SPEED    := 180.0   # px/s contínuo
const GRID_STEP_SEC := 0.15    # segundos por passo em modo grid

# ─── Configuração ─────────────────────────────────────────────────────────────
@export var use_grid_movement: bool = true   # true = Pokémon-style; false = contínuo

# ─── Nós ──────────────────────────────────────────────────────────────────────
@onready var _sprite: ColorRect = $Sprite
@onready var _shadow: ColorRect = $Shadow

# ─── Estado ───────────────────────────────────────────────────────────────────
var _move_dir: Vector2 = Vector2.ZERO
var _is_moving: bool   = false
var _move_progress: float = 0.0
var _move_from: Vector2 = Vector2.ZERO
var _move_to:   Vector2 = Vector2.ZERO
var _face_dir:  Vector2 = Vector2.DOWN
var _can_move:  bool    = true

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)   # world
	set_collision_mask_value(3, true)   # npc
	set_collision_mask_value(4, true)   # enemy

	if not _sprite:
		_create_placeholder_sprite()

func _create_placeholder_sprite() -> void:
	var s := ColorRect.new()
	s.name = "Sprite"
	s.size = Vector2(48, 48)
	s.position = Vector2(-24, -40)
	s.color = Color(0.969, 0.576, 0.102)   # amarelo Bitcoin
	add_child(s)
	_sprite = s

# ─── Input do D-Pad (chamado pelo TouchDPad) ──────────────────────────────────
func set_move_direction(dir: Vector2) -> void:
	_move_dir = dir

func press_action() -> void:
	if not _can_move or DialogueManager.is_active():
		DialogueManager.advance()
		return
	emit_signal("interacted", _face_dir)
	_try_interact()

# ─── Loop de física ───────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not _can_move or DialogueManager.is_active() or BattleManager.state != BattleManager.State.IDLE:
		velocity = Vector2.ZERO
		return

	if use_grid_movement:
		_process_grid_movement(delta)
	else:
		_process_free_movement(delta)

# ─── Movimento em grid (Pokémon-style) ────────────────────────────────────────
func _process_grid_movement(delta: float) -> void:
	if _is_moving:
		_move_progress += delta / GRID_STEP_SEC
		if _move_progress >= 1.0:
			_move_progress = 1.0
			position = _move_to
			_is_moving = false
			velocity = Vector2.ZERO
			emit_signal("player_moved", get_tile_position())
		else:
			position = _move_from.lerp(_move_to, _move_progress)
		return

	if _move_dir == Vector2.ZERO:
		return

	_face_dir = _move_dir
	var target := position + _move_dir * TILE_SIZE
	# Verifica colisão antes de mover
	var motion := _move_dir * TILE_SIZE
	var col := move_and_collide(motion, true)   # test-only
	if col:
		_try_interact_collision(col)
		return

	_move_from    = position
	_move_to      = target
	_move_progress = 0.0
	_is_moving    = true

# ─── Movimento livre ──────────────────────────────────────────────────────────
func _process_free_movement(delta: float) -> void:
	if _move_dir != Vector2.ZERO:
		_face_dir = _move_dir
	velocity = _move_dir * MOVE_SPEED
	move_and_slide()
	if velocity != Vector2.ZERO:
		emit_signal("player_moved", get_tile_position())

# ─── Interação ────────────────────────────────────────────────────────────────
func _try_interact() -> void:
	var check_pos := position + _face_dir * TILE_SIZE
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = check_pos
	params.collision_mask = 0b1100   # layer 3 (npc) + 4 (enemy)
	var results := space.intersect_point(params)
	for r in results:
		var body = r["collider"]
		if body.has_method("on_interact"):
			body.on_interact(self)
			return

func _try_interact_collision(col: KinematicCollision2D) -> void:
	var body = col.get_collider()
	if body and body.has_method("on_interact"):
		body.on_interact(self)

# ─── Utilitários ─────────────────────────────────────────────────────────────
func get_tile_position() -> Vector2i:
	return Vector2i(int(position.x / TILE_SIZE), int(position.y / TILE_SIZE))

func set_can_move(value: bool) -> void:
	_can_move = value
	if not value:
		velocity = Vector2.ZERO
