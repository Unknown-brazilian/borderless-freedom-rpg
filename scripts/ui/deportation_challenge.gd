## deportation_challenge.gd
## Borderless Freedom: A Dissident Adventure
## Tela de deportação — tap-to-reorder.
## As 24 palavras da seed aparecem embaralhadas.
## O player toca na ordem correta para ser liberado.
##
## ⚠️  ESTA É UMA SEED DO JOGO, NÃO UMA SEED REAL.
##     NUNCA TOQUE SEEDS REAIS COM SALDO EM APLICATIVOS.

extends CanvasLayer

# ─── Sinal ────────────────────────────────────────────────────────────────────
signal challenge_result(passed: bool)

# ─── Nós ──────────────────────────────────────────────────────────────────────
@onready var _lbl_prompt:    Label         = $MainPanel/MainVBox/LabelPrompt
@onready var _lbl_progress:  Label         = $MainPanel/MainVBox/LabelProgress
@onready var _lbl_selected:  Label         = $MainPanel/MainVBox/SelectedPanel/LabelSelected
@onready var _word_grid:     GridContainer = $MainPanel/MainVBox/ScrollContainer/WordGrid
@onready var _lbl_result:    Label         = $MainPanel/MainVBox/LabelResult
@onready var _btn_confirm:   Button        = $MainPanel/MainVBox/HBoxButtons/ButtonConfirm
@onready var _btn_undo:      Button        = $MainPanel/MainVBox/HBoxButtons/ButtonUndo

# ─── Estado ───────────────────────────────────────────────────────────────────
var _selected_words:   Array[String] = []
var _selected_buttons: Array         = []
var _all_buttons:      Array         = []
var _shuffled_words:   Array[String] = []
var _attempts:         int           = 0

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	_btn_confirm.pressed.connect(_on_confirm)
	_btn_undo.pressed.connect(_on_undo)
	_lbl_result.hide()
	_btn_confirm.disabled = true
	_build_word_buttons()
	var cover := ColorRect.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.color = Color(0, 0, 0, 1)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.hide()
	add_child(cover)
	get_viewport().focus_exited.connect(func(): if is_instance_valid(cover): cover.show())
	get_viewport().focus_entered.connect(func(): if is_instance_valid(cover): cover.hide())

	# Aviso de segurança visível no topo
	var main_vbox: VBoxContainer = $MainPanel/MainVBox
	var warn := Label.new()
	warn.text = "⚠️  SEED DO JOGO — NUNCA USE SEEDS REAIS COM SALDO AQUI"
	warn.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22))
	warn.add_theme_font_size_override("font_size", 24)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(warn)
	main_vbox.move_child(warn, 0)

	hide()

func _build_word_buttons() -> void:
	_shuffled_words.assign(SeedPhraseSystem.words.duplicate())
	_shuffled_words.shuffle()
	for i in range(_shuffled_words.size()):
		var word := _shuffled_words[i]
		var btn := Button.new()
		btn.text = word
		btn.custom_minimum_size    = Vector2(0, 68)
		btn.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_word_tapped.bind(btn, word))
		_word_grid.add_child(btn)
		_all_buttons.append(btn)
	_update_progress_ui()

# ─── Handlers ─────────────────────────────────────────────────────────────────
func _on_word_tapped(btn: Button, word: String) -> void:
	if btn.disabled: return
	btn.disabled = true
	_selected_words.append(word)
	_selected_buttons.append(btn)
	_update_progress_ui()
	if _selected_words.size() >= SeedPhraseSystem.WORD_COUNT:
		_btn_confirm.disabled = false

func _on_undo() -> void:
	if _selected_words.is_empty(): return
	_selected_words.pop_back()
	var last_btn: Button = _selected_buttons.pop_back()
	if is_instance_valid(last_btn): last_btn.disabled = false
	_btn_confirm.disabled = true
	_update_progress_ui()

func _update_progress_ui() -> void:
	var count := _selected_words.size()
	_lbl_progress.text = "%d / %d palavras selecionadas" % [count, SeedPhraseSystem.WORD_COUNT]
	if count == 0:
		_lbl_selected.text = "(nenhuma ainda)"
		return
	var parts: Array = []
	# show last 6 selected to keep label readable
	var start := maxi(0, count - 6)
	if start > 0:
		parts.append("…")
	for i in range(start, count):
		parts.append("%d. %s" % [i + 1, _selected_words[i]])
	_lbl_selected.text = "  ".join(parts)

func _on_confirm() -> void:
	_attempts += 1
	var answers: Array[String] = []
	answers.assign(_selected_words)
	var passed := SeedPhraseSystem.check_deportation_words(answers)

	if passed:
		_lbl_result.text = (
			"✅  TODAS AS 24 PALAVRAS NA ORDEM CERTA.\n" +
			"Você provou que a seed é sua.\nVocê está LIVRE!"
		)
		_lbl_result.add_theme_color_override("font_color", Color(0.15, 0.9, 0.25))
		_lbl_result.show()
		_btn_confirm.disabled = true
		_btn_undo.disabled    = true
		SeedPhraseSystem.emit_signal("deportation_passed")
		await get_tree().create_timer(2.5).timeout
		emit_signal("challenge_result", true)
	else:
		_btn_confirm.disabled = true
		_btn_undo.disabled    = true
		var errors := _count_errors()
		_lbl_result.text = (
			"❌  %d posição(ões) errada(s). Tentativa %d.\nDesfaça e tente novamente." % [errors, _attempts]
		)
		_lbl_result.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2))
		_lbl_result.show()
		SeedPhraseSystem.emit_signal("deportation_failed")
		await get_tree().create_timer(1.5).timeout
		_btn_undo.disabled = false
		_reset_selection()

func _reset_selection() -> void:
	for btn in _selected_buttons:
		if is_instance_valid(btn): (btn as Button).disabled = false
	_selected_words.clear()
	_selected_buttons.clear()
	_btn_confirm.disabled = true
	_lbl_result.hide()
	_update_progress_ui()

func _count_errors() -> int:
	var count := 0
	for i in range(SeedPhraseSystem.WORD_COUNT):
		var expected := SeedPhraseSystem.words[i]
		var given    := _selected_words[i] if i < _selected_words.size() else ""
		if expected != given:
			count += 1
	return count
