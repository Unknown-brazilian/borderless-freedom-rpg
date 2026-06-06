## dialogue_box.gd
## Caixa de diálogo estilo Game Boy — texto rolando letra por letra.
## Registra-se no DialogueManager ao entrar na cena.

extends CanvasLayer

const CHAR_DELAY := 0.03   # segundos por caractere

@onready var _panel:      PanelContainer = $Panel
@onready var _lbl_speaker: Label         = $Panel/VBox/LabelSpeaker
@onready var _lbl_text:    Label         = $Panel/VBox/LabelText
@onready var _arrow:       Label         = $Panel/VBox/Arrow

var _full_text:      String = ""
var _shown_chars:    int    = 0
var _typing:         bool   = false
var _typing_timer:   float  = 0.0
var _last_tick_usec: int    = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DialogueManager.register_box(self)
	_panel.hide()
	_arrow.hide()
	_lbl_speaker.hide()

func _exit_tree() -> void:
	DialogueManager.unregister_box()

# ─── API chamada pelo DialogueManager ────────────────────────────────────────
func show_line(text: String, speaker: String = "") -> void:
	_full_text      = text
	_shown_chars    = 0
	_typing         = true
	_typing_timer   = 0.0
	_last_tick_usec = Time.get_ticks_usec()
	_lbl_text.text  = ""
	_arrow.hide()

	if speaker.is_empty():
		_lbl_speaker.hide()
	else:
		_lbl_speaker.text = speaker
		_lbl_speaker.show()

	_panel.show()

func hide_box() -> void:
	_panel.hide()
	_arrow.hide()

# ─── Loop — rolagem de texto ──────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if not _typing:
		return
	var now := Time.get_ticks_usec()
	var real_delta := (now - _last_tick_usec) / 1_000_000.0
	_last_tick_usec = now
	_typing_timer -= real_delta
	if _typing_timer <= 0.0:
		_typing_timer = CHAR_DELAY
		_shown_chars = mini(_shown_chars + 1, _full_text.length())
		_lbl_text.text = _full_text.left(_shown_chars)
		if _shown_chars >= _full_text.length():
			_typing = false
			_arrow.show()

# ─── Tap / Botão A — avança ──────────────────────────────────────────────────
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_tap_advance()

func _tap_advance() -> void:
	if _typing:
		# Mostra tudo imediatamente
		_shown_chars = _full_text.length()
		_lbl_text.text = _full_text
		_typing = false
		_arrow.show()
	else:
		DialogueManager.advance()
