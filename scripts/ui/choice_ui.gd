## choice_ui.gd
## ChoiceUI — overlay de escolha de diálogo (até 4 opções).
## Usado em visual novels e situações de escolha do jogador.
## Emite choice_made(index) ao selecionar.

class_name ChoiceUI
extends CanvasLayer

signal choice_made(index: int)

@export var question: String = ""
@export var choices:  Array[String] = []

func _ready() -> void:
	layer = 15
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left   = -480.0
	panel.offset_top    = -600.0
	panel.offset_right  =  480.0
	panel.offset_bottom = -40.0
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	if not question.is_empty():
		var q_lbl := Label.new()
		q_lbl.text = question
		q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		q_lbl.add_theme_font_size_override("font_size", 32)
		q_lbl.add_theme_color_override("font_color", Color(0.969, 0.776, 0.102))
		q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(q_lbl)

	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(0, 80)
		btn.add_theme_font_size_override("font_size", 28)
		var idx := i
		btn.pressed.connect(func(): _on_choice(idx))
		vbox.add_child(btn)

func _on_choice(index: int) -> void:
	emit_signal("choice_made", index)
	queue_free()

## Mostra a ChoiceUI como filho da cena actual e aguarda a escolha.
## Retorna o índice seleccionado (0-based).
static func ask(parent: Node, q: String, opts: Array[String]) -> int:
	var ui := preload("res://scenes/ui/ChoiceUI.tscn").instantiate()
	ui.question = q
	ui.choices.assign(opts)
	parent.add_child(ui)
	var result: int = await ui.choice_made
	return result
