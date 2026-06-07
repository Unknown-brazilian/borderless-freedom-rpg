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
@onready var _sprite: Sprite2D  = $Sprite
@onready var _shadow: ColorRect = $Shadow

const SPRITE_BASE_Y := -22.0
var _anim_time: float = 0.0

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
	set_collision_mask_value(1, true)    # world (obstáculos)
	set_collision_mask_value(3, true)    # npc (bate pra interagir)
	set_collision_mask_value(4, false)   # NÃO bloqueia em inimigos — batalha por proximidade

	# Rede de segurança: ao fim de QUALQUER batalha, libera o movimento
	# (cobre todos os tipos de inimigo; o fluxo de boss reativa o bloqueio depois).
	if not BattleManager.battle_ended.is_connected(_on_any_battle_ended):
		BattleManager.battle_ended.connect(_on_any_battle_ended)

	# Fallback: se a textura não veio da cena, carrega via ResourceLoader
	# (funciona no editor E no APK; Image.load_from_file falha dentro do .pck).
	if _sprite and _sprite.texture == null:
		var p := "res://assets/sprites/player.png"
		if ResourceLoader.exists(p):
			_sprite.texture = load(p)
	# Aplica a skin escolhida (tinta) ao sprite do player.
	PlayerCustomization.apply(self)

	# Corpo LPC (32-bit JRPG) animado por direção, no lugar do sprite estático.
	if get_node_or_null("LPCBody") == null:
		var lpc = preload("res://scripts/world/lpc_character.gd").new()
		lpc.name = "LPCBody"
		lpc.z_index = 1
		add_child(lpc)
	if is_instance_valid(_sprite):
		_sprite.visible = false
	var helm := get_node_or_null("Helmet")
	if helm:
		helm.visible = false

# ─── Animação procedural (bob de idle/caminhada) ──────────────────────────────
func _process(delta: float) -> void:
	if not is_instance_valid(_sprite):
		return
	_anim_time += delta
	var bob := 0.0
	if _is_moving or (not use_grid_movement and _move_dir != Vector2.ZERO):
		bob = absf(sin(_anim_time * 14.0)) * 5.0   # passo: quique vertical
	else:
		bob = sin(_anim_time * 3.0) * 1.5           # idle: respiração sutil
	_sprite.position.y = SPRITE_BASE_Y - bob

## Pequeno squash & stretch ao iniciar um passo, dá peso ao movimento.
func _step_squash() -> void:
	if not is_instance_valid(_sprite):
		return
	var base := Vector2(2, 2)
	var t := _sprite.create_tween()
	t.tween_property(_sprite, "scale", Vector2(2.2, 1.8), 0.06)
	t.tween_property(_sprite, "scale", base, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
		var step := 0.12 if (_on_bike and PlayerCustomization.bike_index > 0) else 0.20
		_move_progress += delta / step
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
	if _move_dir.x != 0 and is_instance_valid(_sprite):
		_sprite.flip_h = _move_dir.x < 0
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
	_step_squash()

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

func _on_any_battle_ended(_result: String) -> void:
	_can_move = true

var _on_bike: bool = true

## Monta/desmonta a bicicleta (botão 🚲). Na bike = mais rápido.
func toggle_bike() -> void:
	if PlayerCustomization.bike_index == 0:
		DialogueManager.start(["🚲  Você não tem uma bicicleta agora."])
		return
	_on_bike = not _on_bike
	var b := get_node_or_null("BikeIcon")
	if b:
		b.visible = _on_bike
	AudioManager.sfx("step")
	Juice.float_text(get_parent(), position + Vector2(0, -90),
		"🚲 Na bike" if _on_bike else "🚶 A pé",
		Color(0.4, 0.9, 0.5) if _on_bike else Color(0.8, 0.8, 0.5), 28)
