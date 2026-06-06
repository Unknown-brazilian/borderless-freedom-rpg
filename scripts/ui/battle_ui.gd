## battle_ui.gd
## UI da batalha turn-based estilo Pokémon.
## Conecta ao BattleManager e exibe HP, log de ações, botões de ação.

extends CanvasLayer

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

	hide()

# ─── Sinais do BattleManager ─────────────────────────────────────────────────

func _on_battle_started(enemy_data: Dictionary) -> void:
	show()
	_lbl_enemy_name.text = enemy_data.get("name", "???")
	var is_boss: bool = enemy_data.get("is_boss", false)
	_rect_enemy.color = Color(0.85, 0.15, 0.15) if is_boss else Color(0.72, 0.18, 0.18)
	_lbl_log.text = "Um %s apareceu!" % enemy_data.get("name", "inimigo")
	_set_buttons_enabled(false)
	_btn_run.disabled = is_boss

func _on_player_turn() -> void:
	_set_buttons_enabled(true)
	_lbl_log.text = "O que você vai fazer?"

func _on_enemy_turn() -> void:
	_set_buttons_enabled(false)

func _on_action_resolved(log_text: String) -> void:
	_lbl_log.text = log_text

func _on_hp_changed(who: String, new_hp: int, max_hp: int) -> void:
	if who == "player":
		_bar_player_hp.max_value = max_hp
		_bar_player_hp.value     = new_hp
		_lbl_player_hp.text      = "HP: %d/%d" % [new_hp, max_hp]
		_bar_player_hp.modulate  = _hp_color(float(new_hp) / float(max_hp))
	else:
		_bar_enemy_hp.max_value = max_hp
		_bar_enemy_hp.value     = new_hp
		_lbl_enemy_hp.text      = "HP: %d" % new_hp
		_bar_enemy_hp.modulate  = _hp_color(float(new_hp) / float(max_hp))

func _on_battle_ended(result: String) -> void:
	_set_buttons_enabled(false)
	match result:
		"victory":
			_lbl_log.text = "🏆  Vitória!"
			await get_tree().create_timer(2.0).timeout
		"defeat":
			_lbl_log.text = "💀  Derrota..."
			await get_tree().create_timer(2.0).timeout
		"escaped":
			_lbl_log.text = "🏃  Fugiu!"
			await get_tree().create_timer(1.0).timeout
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
