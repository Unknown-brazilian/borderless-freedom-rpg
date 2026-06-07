## juice.gd
## Sistema reutilizável de "game feel" (inspirado nas boas práticas da GDQuest).
## Centraliza: screen shake, shake de nós de UI, flash de dano, scale-pop,
## números de dano flutuantes, burst de partículas e hit-stop.
##
## Tudo é tolerante a nós inválidos e funciona mesmo com a árvore pausada.
## Autoload registrado como "Juice".

extends Node

# ─── Screen shake (trauma-based) ──────────────────────────────────────────────
var _trauma:       float    = 0.0
const TRAUMA_POWER  := 2.0
const MAX_OFFSET    := 26.0
const TRAUMA_DECAY  := 1.8
var _shake_cam:    Camera2D = null
var _base_offset:  Vector2  = Vector2.ZERO

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	# Continua animando shakes/tweens mesmo se o jogo estiver pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

# ─── Screen shake do mundo (Camera2D ativa) ──────────────────────────────────
## amount: 0.0–1.0. Some por decaimento. Use ~0.35 para hit leve, ~0.7 para boss.
func shake(amount: float = 0.4) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	if _trauma <= 0.0 or cam != _shake_cam:
		_shake_cam   = cam
		_base_offset = cam.offset
	_trauma = minf(_trauma + amount, 1.0)

func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - TRAUMA_DECAY * delta, 0.0)
	if not is_instance_valid(_shake_cam):
		_trauma = 0.0
		return
	if _trauma <= 0.0:
		_shake_cam.offset = _base_offset
		return
	var amt: float = pow(_trauma, TRAUMA_POWER)
	_shake_cam.offset = _base_offset + Vector2(
		MAX_OFFSET * amt * _rng.randf_range(-1.0, 1.0),
		MAX_OFFSET * amt * _rng.randf_range(-1.0, 1.0)
	)

# ─── Shake posicional de um nó (UI em CanvasLayer, que ignora a câmera) ───────
func shake_node(node: CanvasItem, amount: float = 14.0, duration: float = 0.28) -> void:
	if not is_instance_valid(node) or not ("position" in node):
		return
	var orig: Vector2 = node.position
	var steps := 6
	var t := node.create_tween()
	for i in steps:
		var fade := 1.0 - float(i) / float(steps)
		var off := Vector2(
			_rng.randf_range(-amount, amount),
			_rng.randf_range(-amount, amount)
		) * fade
		t.tween_property(node, "position", orig + off, duration / float(steps))
	t.tween_property(node, "position", orig, duration / float(steps))

# ─── Flash de cor (dano = branco; cura = verde) ──────────────────────────────
func flash(item: CanvasItem, color: Color = Color(1, 1, 1, 1), duration: float = 0.18) -> void:
	if not is_instance_valid(item):
		return
	var orig: Color = item.modulate
	var t := item.create_tween()
	t.tween_property(item, "modulate", color, duration * 0.35)
	t.tween_property(item, "modulate", orig, duration * 0.65)

# ─── Scale-pop (squash/punch) ────────────────────────────────────────────────
func pop(node: Node, intensity: float = 1.25, duration: float = 0.22) -> void:
	if not is_instance_valid(node) or not ("scale" in node):
		return
	var base: Vector2 = node.scale
	if base == Vector2.ZERO:
		base = Vector2.ONE
	var t := node.create_tween()
	t.tween_property(node, "scale", base * intensity, duration * 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", base, duration * 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

# ─── Número de dano/cura flutuante ───────────────────────────────────────────
## Adiciona um Label em `parent` na posição `at` (no espaço de `parent`).
func float_text(parent: Node, at: Vector2, text: String,
		color: Color = Color(1, 1, 1), size: int = 40) -> void:
	if not is_instance_valid(parent):
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.position = at
	lbl.z_index = 100
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 6)
	parent.add_child(lbl)
	var t := lbl.create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "position", at + Vector2(0, -64), 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.7).set_delay(0.25)
	t.chain().tween_callback(lbl.queue_free)

# ─── Burst de partículas one-shot ────────────────────────────────────────────
func burst(parent: Node, at: Vector2, color: Color = Color(1, 0.9, 0.3),
		count: int = 14, speed: float = 220.0) -> void:
	if not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.position = at
	p.z_index = 90
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = 0.5
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 320)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	parent.add_child(p)
	# Auto-remoção após a vida das partículas.
	var t := p.create_tween()
	t.tween_interval(p.lifetime + 0.2)
	t.tween_callback(p.queue_free)

# ─── Hit-stop (congelamento breve para dar peso ao impacto) ───────────────────
func hit_stop(duration: float = 0.07, scale: float = 0.05) -> void:
	Engine.time_scale = scale
	# 4º arg = ignore_time_scale, para o timer contar em tempo real mesmo congelado.
	var timer := get_tree().create_timer(duration, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0
