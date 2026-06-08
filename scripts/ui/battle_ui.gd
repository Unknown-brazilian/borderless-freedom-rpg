## battle_ui.gd
## UI da batalha turn-based estilo Pokémon.
## Conecta ao BattleManager e exibe HP, log de ações, botões de ação.

extends CanvasLayer

@onready var _battle_area:     Node        = $BattleArea
@onready var _lbl_enemy_name:  Label       = $BattleArea/EnemyPanel/LabelEnemyName
@onready var _lbl_enemy_hp:    Label       = $BattleArea/EnemyPanel/LabelEnemyHP
@onready var _bar_enemy_hp:    ProgressBar = $BattleArea/EnemyPanel/BarEnemyHP
@onready var _rect_enemy:      ColorRect   = $BattleArea/EnemySprite
@onready var _lbl_player_hp:   Label       = $BattleArea/PlayerPanel/LabelPlayerHP
@onready var _bar_player_hp:   ProgressBar = $BattleArea/PlayerPanel/BarPlayerHP
@onready var _rect_player:     ColorRect   = $BattleArea/PlayerSprite
@onready var _lbl_log:         Label       = $ActionArea/LabelLog
@onready var _btn_attack:      Button      = $ActionArea/Grid/BtnAttack
@onready var _btn_item:        Button      = $ActionArea/Grid/BtnItem
@onready var _btn_stealth:     Button      = $ActionArea/Grid/BtnStealth
@onready var _btn_persuade:    Button      = $ActionArea/Grid/BtnPersuade
@onready var _btn_run:         Button      = $ActionArea/Grid/BtnRun

var _buttons_enabled: bool = false
var _prev_enemy_hp:   int  = -1
var _prev_player_hp:  int  = -1
var _enemy_tex:  TextureRect = null
var _player_tex: TextureRect = null
# Barra ATB (ordem de turno, estilo tático).
var _atb_panel: PanelContainer = null
var _atb_gauge: ProgressBar = null
var _atb_p: Label = null
var _atb_e: Label = null
var _atb_label: Label = null

func _ready() -> void:
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.player_turn_started.connect(_on_player_turn)
	BattleManager.enemy_turn_started.connect(_on_enemy_turn)
	BattleManager.action_resolved.connect(_on_action_resolved)
	BattleManager.hp_changed.connect(_on_hp_changed)

	_btn_attack.pressed.connect(func(): _player_act(BattleManager.Action.ATTACK))
	_btn_item.pressed.connect(func(): _player_act(BattleManager.Action.ITEM))
	_btn_stealth.pressed.connect(func(): _player_act(BattleManager.Action.STEALTH))
	_btn_persuade.pressed.connect(func(): _player_act(BattleManager.Action.PERSUADE))
	_btn_run.pressed.connect(func(): _player_act(BattleManager.Action.RUN))

	for btn in [_btn_attack, _btn_item, _btn_stealth, _btn_persuade, _btn_run]:
		btn.custom_minimum_size = Vector2(0, 88)
		Juice.button_feedback(btn)

	_build_atb()

	# Sprites reais sobre os ColorRects (que viram fundo translúcido).
	_enemy_tex  = _make_battler(_rect_enemy)
	_player_tex = _make_battler(_rect_player)
	# Player na batalha: personagem LPC virado pra direita (encara o inimigo).
	var pf := _lpc_frame(3)
	if pf != null:
		_player_tex.texture = pf
	else:
		_set_texture(_player_tex, "res://assets/sprites/player.png")
	_rect_player.color = Color(0.969, 0.576, 0.102, 0.16)

	hide()

## Retorna um frame (idle) do sheet LPC para a batalha (row: 0=cima,1=esq,2=baixo,3=dir).
func _lpc_frame(row: int) -> Texture2D:
	var sheet := "res://assets/lpc/player_walk.png"
	if not ResourceLoader.exists(sheet):
		return null
	var at := AtlasTexture.new()
	at.atlas = load(sheet)
	at.region = Rect2(0, row * 64, 64, 64)
	return at

# ─── Barra ATB (ordem de turno) ──────────────────────────────────────────────
func _build_atb() -> void:
	_atb_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.11, 0.88)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.12)
	_atb_panel.add_theme_stylebox_override("panel", sb)
	_atb_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_atb_panel.offset_left = 36
	_atb_panel.offset_right = -36
	_atb_panel.offset_top = 14
	_battle_area.add_child(_atb_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_atb_panel.add_child(v)
	_atb_label = Label.new()
	_atb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_atb_label.add_theme_font_size_override("font_size", 24)
	v.add_child(_atb_label)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	_atb_p = Label.new()
	_atb_p.text = "🧍 Você"
	_atb_p.add_theme_font_size_override("font_size", 22)
	h.add_child(_atb_p)
	_atb_gauge = ProgressBar.new()
	_atb_gauge.show_percentage = false
	_atb_gauge.custom_minimum_size = Vector2(0, 16)
	_atb_gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_atb_gauge.max_value = 100
	_atb_gauge.value = 0
	h.add_child(_atb_gauge)
	_atb_e = Label.new()
	_atb_e.text = "Fiscal 👮"
	_atb_e.add_theme_font_size_override("font_size", 22)
	h.add_child(_atb_e)
	_atb_panel.visible = false

func _atb_set_turn(who: String) -> void:
	if not is_instance_valid(_atb_panel):
		return
	var active := Color(1, 0.85, 0.3)
	var idle := Color(0.55, 0.55, 0.62)
	_atb_p.add_theme_color_override("font_color", active if who == "player" else idle)
	_atb_e.add_theme_color_override("font_color", active if who == "enemy" else idle)
	if who == "player":
		_atb_label.text = "▶  SUA VEZ"
		_atb_label.add_theme_color_override("font_color", active)
		_atb_gauge.modulate = active
		_atb_gauge.value = 100
	else:
		_atb_label.text = "TURNO INIMIGO…"
		_atb_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
		_atb_gauge.modulate = Color(0.95, 0.5, 0.5)
		_atb_gauge.value = 0
		var tw := _atb_gauge.create_tween()
		tw.tween_property(_atb_gauge, "value", 100.0, 0.7).set_trans(Tween.TRANS_SINE)

## Cria um TextureRect pixel-art centralizado dentro do ColorRect host.
func _make_battler(host: ColorRect) -> TextureRect:
	var tr := TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode      = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter   = CanvasItem.TEXTURE_FILTER_NEAREST   # mantém pixel-art nítido
	tr.mouse_filter     = Control.MOUSE_FILTER_IGNORE
	host.add_child(tr)
	return tr

func _set_texture(tr: TextureRect, path: String) -> void:
	if tr and ResourceLoader.exists(path):
		tr.texture = load(path)

# ─── Sinais do BattleManager ─────────────────────────────────────────────────

func _on_battle_started(enemy_data: Dictionary) -> void:
	show()
	_lbl_enemy_name.text = enemy_data.get("name", "???")
	if is_instance_valid(_atb_panel):
		_atb_e.text = "%s 👮" % enemy_data.get("name", "Inimigo")
		_atb_panel.visible = true
	var is_boss: bool = enemy_data.get("is_boss", false)
	# Sprite do inimigo: explícito > boss.png (chefe) > personagem LPC (fiscais).
	var spr_path: String = enemy_data.get("sprite", "")
	var lpc_enemy := _lpc_frame(1)   # virado pra esquerda (encara o player)
	if not spr_path.is_empty():
		_set_texture(_enemy_tex, spr_path)
	elif is_boss:
		_set_texture(_enemy_tex, "res://assets/sprites/boss.png")
	elif lpc_enemy != null:
		_enemy_tex.texture = lpc_enemy   # halo vermelho do host já o distingue
	else:
		_set_texture(_enemy_tex, "res://assets/sprites/fiscal_enemy.png")
	# ColorRect vira um halo translúcido atrás do sprite.
	var glow := Color(0.85, 0.15, 0.15, 0.20) if is_boss else Color(0.72, 0.18, 0.18, 0.16)
	_rect_enemy.color = glow
	_lbl_log.text = "Um %s apareceu!" % enemy_data.get("name", "inimigo")
	_set_buttons_enabled(false)
	_btn_run.disabled = is_boss
	_prev_enemy_hp  = -1
	_prev_player_hp = -1
	# Reseta transform dos sprites (reusados entre batalhas: morte/lunge anteriores).
	_reset_battler(_enemy_tex)
	_reset_battler(_player_tex)
	# Entrada do inimigo com um pop.
	if is_instance_valid(_enemy_tex):
		_enemy_tex.pivot_offset = _enemy_tex.size * 0.5
	Juice.pop(_enemy_tex, 1.3, 0.35)

func _reset_battler(b: TextureRect) -> void:
	if is_instance_valid(b):
		b.position = Vector2.ZERO
		b.scale    = Vector2.ONE
		b.rotation = 0.0
		b.modulate = Color.WHITE

func _on_player_turn() -> void:
	_set_buttons_enabled(true)
	_lbl_log.text = "O que você vai fazer?"
	_atb_set_turn("player")

func _on_enemy_turn() -> void:
	_set_buttons_enabled(false)
	_atb_set_turn("enemy")
	_telegraph(_enemy_tex)

## Anticipação antes do golpe inimigo: incha + tinge de vermelho, depois relaxa.
## Roda dentro da janela de ~0.8s antes do dano (BattleManager._enemy_turn).
func _telegraph(battler: TextureRect) -> void:
	if not is_instance_valid(battler):
		return
	battler.pivot_offset = battler.size * 0.5
	var t := battler.create_tween()
	t.tween_property(battler, "scale", Vector2(1.18, 1.18), 0.35) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(battler, "modulate", Color(1.5, 0.6, 0.6), 0.35)
	t.tween_property(battler, "scale", Vector2.ONE, 0.16)
	t.parallel().tween_property(battler, "modulate", Color.WHITE, 0.16)

func _on_action_resolved(log_text: String) -> void:
	_lbl_log.text = log_text

func _on_hp_changed(who: String, new_hp: int, max_hp: int) -> void:
	if who == "player":
		_bar_player_hp.max_value = max_hp
		_bar_player_hp.value     = new_hp
		_lbl_player_hp.text      = "HP: %d/%d" % [new_hp, max_hp]
		_bar_player_hp.modulate  = _hp_color(float(new_hp) / float(max_hp))
		# player levou dano -> o inimigo é o atacante
		_react(_enemy_tex, _rect_player, _player_tex, _prev_player_hp, new_hp)
		_prev_player_hp = new_hp
	else:
		_bar_enemy_hp.max_value = max_hp
		_bar_enemy_hp.value     = new_hp
		_lbl_enemy_hp.text      = "HP: %d" % new_hp
		_bar_enemy_hp.modulate  = _hp_color(float(new_hp) / float(max_hp))
		# inimigo levou dano -> o player é o atacante
		_react(_player_tex, _rect_enemy, _enemy_tex, _prev_enemy_hp, new_hp)
		_prev_enemy_hp = new_hp

## Coordena a reação a uma mudança de HP: lunge do atacante + impacto no alvo.
func _react(attacker: TextureRect, host: ColorRect, battler: TextureRect,
		prev_hp: int, new_hp: int) -> void:
	if prev_hp < 0:
		return   # primeira atualização (inicialização) — sem feedback
	var delta := new_hp - prev_hp
	if delta == 0:
		return
	if delta < 0:
		_lunge_and_hit(attacker, host, battler, delta)
	else:        # cura — sem lunge
		var center := host.global_position + host.size * 0.5
		if is_instance_valid(battler):
			Juice.flash(battler, Color(0.4, 1, 0.4), 0.2)
		Juice.float_text(self, center, "+%d" % delta, Color(0.4, 1, 0.4))

## O atacante avança rumo ao alvo; no contato dispara o impacto; depois recua.
func _lunge_and_hit(attacker: TextureRect, host: ColorRect, battler: TextureRect,
		delta: int) -> void:
	const CONTACT := 0.10
	if is_instance_valid(attacker):
		attacker.pivot_offset = attacker.size * 0.5
		var dir := (host.global_position - attacker.global_position).normalized()
		var t := attacker.create_tween()
		t.tween_property(attacker, "position", dir * 150.0, CONTACT) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(attacker, "position", Vector2.ZERO, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(CONTACT, true, false, true).timeout
	_impact(host, battler, delta)

## Feedback de impacto no alvo: flash, pop, shake, número e partículas.
func _impact(host: ColorRect, battler: TextureRect, delta: int) -> void:
	var center := host.global_position + host.size * 0.5
	if is_instance_valid(battler):
		battler.pivot_offset = battler.size * 0.5
		Juice.flash(battler, Color(1, 1, 1), 0.18)
		Juice.pop(battler, 0.82, 0.2)
	Juice.shake_node(_battle_area, minf(8.0 + absf(delta) * 0.6, 24.0), 0.3)
	Juice.float_text(self, center, "-%d" % absf(delta), Color(1, 0.85, 0.3))
	Juice.burst(self, center, Color(1, 0.8, 0.2), 12)
	Juice.hit_stop(clampf(0.06 + absf(delta) * 0.003, 0.06, 0.16))   # golpe maior congela mais
	AudioManager.sfx("hit")

## Morte do inimigo: tomba (rotação) + cai + some, com poeira e shake.
func _play_death(battler: TextureRect, host: ColorRect) -> void:
	if not is_instance_valid(battler):
		return
	battler.pivot_offset = battler.size * 0.5
	var center := host.global_position + host.size * 0.5
	Juice.flash(battler, Color(2, 2, 2), 0.12)   # clarão branco no golpe fatal
	Juice.burst(self, center, Color(0.8, 0.8, 0.8), 18, 260.0)
	Juice.shake_node(_battle_area, 18.0, 0.4)
	Juice.hit_stop(0.12)
	var t := battler.create_tween()
	t.set_parallel(true)
	t.tween_property(battler, "rotation", deg_to_rad(85.0), 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(battler, "position:y", battler.position.y + 70.0, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(battler, "modulate:a", 0.0, 0.7).set_delay(0.1)

func _on_battle_ended(result: String) -> void:
	_set_buttons_enabled(false)
	if is_instance_valid(_atb_panel):
		_atb_panel.visible = false
	match result:
		"victory":
			_lbl_log.text = "🏆  Vitória!"
			_play_death(_enemy_tex, _rect_enemy)
			AudioManager.sfx("victory")
			await get_tree().create_timer(2.0, true, false, true).timeout
		"defeat":
			_lbl_log.text = "💀  Derrota..."
			AudioManager.sfx("defeat")
			await get_tree().create_timer(2.0, true, false, true).timeout
		"escaped":
			_lbl_log.text = "🏃  Fugiu!"
			AudioManager.sfx("door")
			await get_tree().create_timer(1.0, true, false, true).timeout
	BattleManager.reset()
	hide()

# ─── Ação do player ───────────────────────────────────────────────────────────
func _player_act(action: BattleManager.Action) -> void:
	if not _buttons_enabled:
		return
	var item_id := PlayerInventory.active_item if action == BattleManager.Action.ITEM else ""
	BattleManager.player_action(action, item_id)

func _set_buttons_enabled(value: bool) -> void:
	_buttons_enabled = value
	for btn in [_btn_attack, _btn_item, _btn_stealth, _btn_persuade]:
		btn.disabled = not value
	_btn_run.disabled = not value or BattleManager.enemy_data.get("is_boss", false)

func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:   return Color(0.2, 0.8, 0.2)
	elif ratio > 0.25: return Color(0.9, 0.7, 0.1)
	else:              return Color(0.9, 0.2, 0.2)
