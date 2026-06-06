## scene_transition.gd
## Borderless Freedom: A Dissident Adventure
## AutoLoad — fade preto entre cenas (evita cortes bruscos no Android).
## Use SceneTransition.go(path) em vez de get_tree().change_scene_to_file(path).

extends CanvasLayer

var _fade:          ColorRect
var _transitioning: bool   = false
var _next:          String = ""

func _ready() -> void:
	layer = 99
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color        = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

func go(path: String) -> void:
	if _transitioning:
		return
	_transitioning      = true
	_next               = path
	_fade.mouse_filter  = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_fade, "color:a", 1.0, 0.22)
	tw.tween_callback(_swap)

func _swap() -> void:
	get_tree().change_scene_to_file(_next)
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_fade, "color:a", 0.0, 0.28)
	tw.tween_callback(func():
		_transitioning     = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
