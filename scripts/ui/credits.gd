## credits.gd
## Borderless Freedom: A Dissident Adventure
## Tela de créditos — acessível pelo menu principal.

extends Control

@onready var _btn_voltar: Button = $ScrollContainer/VBox/BtnVoltar

func _ready() -> void:
	AutonomyBar.set_active(false)
	AudioManager.music("menu")
	_btn_voltar.pressed.connect(_on_voltar)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_voltar()

func _on_voltar() -> void:
	SceneTransition.go("res://scenes/ui/main_menu.tscn")
