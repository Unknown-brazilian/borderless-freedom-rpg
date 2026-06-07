## main_menu_rpg.gd
## Menu principal do RPG — Nova Jornada, Continuar, Créditos.

extends CanvasLayer

@onready var _btn_nova:     Button = $Panel/VBox/BtnNova
@onready var _btn_continuar:Button = $Panel/VBox/BtnContinuar
@onready var _btn_creditos: Button = $Panel/VBox/BtnCreditos
@onready var _lbl_title:    Label  = $Panel/LabelTitle
@onready var _lbl_sub:      Label  = $Panel/LabelSub
@onready var _confirm_panel: Control = $ConfirmPanel
@onready var _btn_confirm_yes: Button = $ConfirmPanel/VBox/BtnYes
@onready var _btn_confirm_no:  Button = $ConfirmPanel/VBox/BtnNo

func _ready() -> void:
	AutonomyBar.set_active(false)
	AudioManager.music("menu")

	_btn_nova.pressed.connect(_on_nova_jornada)
	_btn_continuar.pressed.connect(_on_continuar)
	_btn_creditos.pressed.connect(_on_creditos)
	_btn_confirm_yes.pressed.connect(_confirm_new_game)
	_btn_confirm_no.pressed.connect(func(): _confirm_panel.hide())
	_confirm_panel.hide()

	_btn_continuar.disabled = not SaveSystem.has_save()
	_lbl_title.text = "BORDERLESS FREEDOM"
	_lbl_sub.text   = "A Dissident Adventure — RPG"

	# Feedback de toque (clique + escala + vibração) em todos os botões.
	for b in [_btn_nova, _btn_continuar, _btn_creditos, _btn_confirm_yes, _btn_confirm_no]:
		Juice.button_feedback(b)
	_play_intro()

## Entrada animada: título dá pop, subtítulo e botões entram em cascata;
## depois o título ganha um pulso sutil de "respiração".
func _play_intro() -> void:
	var btns := [_btn_nova, _btn_continuar, _btn_creditos]
	_lbl_title.modulate.a = 0.0
	_lbl_sub.modulate.a   = 0.0
	for b in btns:
		b.modulate.a = 0.0
	await get_tree().process_frame   # aguarda o layout para pivôs corretos

	_lbl_title.pivot_offset = _lbl_title.size * 0.5
	_lbl_title.scale = Vector2(1.15, 1.15)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_lbl_title, "modulate:a", 1.0, 0.4)
	t.tween_property(_lbl_title, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_lbl_sub, "modulate:a", 1.0, 0.4).set_delay(0.2)
	for i in btns.size():
		t.tween_property(btns[i], "modulate:a", 1.0, 0.3).set_delay(0.35 + i * 0.1)

	await get_tree().create_timer(1.1).timeout
	var pulse := create_tween().set_loops()
	pulse.tween_property(_lbl_title, "scale", Vector2(1.03, 1.03), 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_lbl_title, "scale", Vector2.ONE, 1.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_nova_jornada() -> void:
	if SaveSystem.has_save():
		_confirm_panel.pivot_offset = _confirm_panel.size * 0.5
		_confirm_panel.show()
		Juice.pop(_confirm_panel, 1.08, 0.25)
	else:
		_start_new_game()

func _confirm_new_game() -> void:
	_confirm_panel.hide()
	_start_new_game()

func _start_new_game() -> void:
	SaveSystem.delete_save()
	SatEconomy.current_sats    = 0
	SatEconomy.lifetime_earned = 0
	SatEconomy.lifetime_lost   = 0
	PlayerStats.reset()
	PlayerInventory.reset()
	AutonomyBar.refill_all()
	GameStats.reset()
	RandomEventsSystem.reset()
	SaveSystem.reset_store()
	WorldManager.current_dungeon   = 1
	WorldManager.sequence_index    = 0
	WorldManager.bosses_defeated_in_dungeon = 0
	WorldManager.dungeon_flags = {}
	SceneTransition.go("res://scenes/ui/PlayerCustomization.tscn")

func _on_continuar() -> void:
	if SaveSystem.load_game():
		var idx: int = WorldManager.sequence_index
		if idx < WorldManager.SCENE_SEQUENCE.size():
			var scene: String = WorldManager.SCENE_SEQUENCE[idx].get("scene", "")
			if not scene.is_empty():
				SceneTransition.go(scene)

func _on_creditos() -> void:
	SceneTransition.go("res://scenes/ui/Credits.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pass
