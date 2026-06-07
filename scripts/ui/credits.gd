## credits.gd
## Borderless Freedom: A Dissident Adventure
## Tela de créditos — acessível pelo menu principal.

extends Control

@onready var _btn_voltar: Button = $ScrollContainer/VBox/BtnVoltar

func _ready() -> void:
	AutonomyBar.set_active(false)
	AudioManager.music("menu")
	_btn_voltar.pressed.connect(_on_voltar)
	_add_music_attribution()

## Atribuição obrigatória (CC BY-SA 4.0) da trilha sonora.
func _add_music_attribution() -> void:
	var vbox := $ScrollContainer/VBox
	var attr := Label.new()
	attr.text = "♪ Música: \"16-Bit Music Pack 1\" por Retro Indie Josh\n(retroindiejosh.itch.io) — licenciada sob CC BY-SA 4.0"
	attr.autowrap_mode = TextServer.AUTOWRAP_WORD
	attr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attr.add_theme_font_size_override("font_size", 24)
	attr.add_theme_color_override("font_color", Color(0.72, 0.72, 0.78))
	vbox.add_child(attr)
	vbox.move_child(attr, _btn_voltar.get_index())   # antes do botão Voltar

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_voltar()

func _on_voltar() -> void:
	SceneTransition.go("res://scenes/ui/main_menu.tscn")
