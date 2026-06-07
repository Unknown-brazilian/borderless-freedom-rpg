## dialogue_manager.gd
## AutoLoad — gerencia diálogos e caixas de texto globais.
## Use: DialogueManager.start(lines) → conectar dialogue_finished.

extends Node

signal dialogue_finished
signal line_shown(text: String, speaker: String)

var _lines: Array[String] = []
var _speakers: Array[String] = []
var _index: int = 0
var _is_active: bool = false
var _box_node: Node = null   # referência para DialogueBox na cena ativa

# ─── API pública ──────────────────────────────────────────────────────────────

## Inicia um diálogo simples (sem speaker).
func start(lines: Array[String]) -> void:
	start_with_speakers(lines, [])

## Inicia diálogo com speakers opcionais (mesmo índice que lines, ou vazio = sem speaker).
func start_with_speakers(lines: Array[String], speakers: Array[String]) -> void:
	if _is_active:
		return
	_lines   = lines.duplicate()
	_speakers = speakers.duplicate()
	_index   = 0
	_is_active = true
	Engine.time_scale = 0.0
	AutonomyBar.set_active(false)
	_show_current()

## Avança para a próxima linha (chamado pelo DialogueBox ao tocar/apertar A).
func advance() -> void:
	if not _is_active:
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_show_current()

func is_active() -> bool:
	return _is_active

## Registra o nó DialogueBox da cena ativa — chamado pelo _ready() do DialogueBox.
func register_box(box: Node) -> void:
	_box_node = box

func unregister_box() -> void:
	_box_node = null

# ─── Internas ─────────────────────────────────────────────────────────────────

func _show_current() -> void:
	var text    := _lines[_index] if _index < _lines.size() else ""
	var speaker := _speakers[_index] if _index < _speakers.size() else ""
	emit_signal("line_shown", text, speaker)
	if not text.is_empty():
		AudioManager.sfx("dialogue")
	if is_instance_valid(_box_node) and _box_node.has_method("show_line"):
		_box_node.show_line(text, speaker)

func _finish() -> void:
	_is_active = false
	_lines.clear()
	_speakers.clear()
	_index = 0
	Engine.time_scale = 1.0
	AutonomyBar.set_active(true)
	if is_instance_valid(_box_node) and _box_node.has_method("hide_box"):
		_box_node.hide_box()
	emit_signal("dialogue_finished")
