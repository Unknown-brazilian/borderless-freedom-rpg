## seed_phrase_screen.gd
## Borderless Freedom: A Dissident Adventure
## Exibe as 24 palavras da seed do jogo após iniciar nova jornada.
##
## ⚠️  AVISO IMPORTANTE (também exibido na tela):
##      ESTA É UMA SEED DO JOGO — NUNCA COMPARTILHE SEEDS REAIS COM SALDO.
##
## Prevenção de screenshot:
##   • Quando o app perde foco (swipe p/ outra app, notificação), a tela é
##     coberta por um overlay preto para não vazar as palavras.
##   • Em produção, aplique FLAG_SECURE via plugin Android para prevenção nativa.

extends Control

# ─── Nós ──────────────────────────────────────────────────────────────────────
@onready var _word_grid:   GridContainer = $MainVBox/ScrollContainer/WordGrid
@onready var _btn_confirm: Button        = $MainVBox/ButtonConfirm
@onready var _cover:       ColorRect     = $CoverOnFocusLost

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	AutonomyBar.set_active(false)

	get_viewport().focus_exited.connect(_on_focus_lost)
	get_viewport().focus_entered.connect(_on_focus_gained)

	_btn_confirm.pressed.connect(_on_confirmed)
	_cover.hide()

	# Aviso de segurança visível no topo
	var main_vbox: VBoxContainer = $MainVBox
	var warn := Label.new()
	warn.text = "⚠️  SEED DO JOGO — NUNCA INSIRA SEEDS REAIS COM SALDO EM APPS"
	warn.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22))
	warn.add_theme_font_size_override("font_size", 26)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(warn)
	main_vbox.move_child(warn, 0)

	_populate_words()

func _populate_words() -> void:
	for child in _word_grid.get_children():
		child.queue_free()

	var words := SeedPhraseSystem.words
	for i in range(words.size()):
		var lbl := Label.new()
		lbl.text = "%d.  %s" % [i + 1, words[i]]
		lbl.theme_override_font_sizes = {}
		lbl.add_theme_font_size_override("font_size", 32)
		lbl.add_theme_color_override("font_color", Color(0.933, 0.933, 0.933))
		_word_grid.add_child(lbl)

# ─── Handlers ─────────────────────────────────────────────────────────────────
func _on_confirmed() -> void:
	WorldManager.start_game()

func _on_focus_lost() -> void:
	_cover.show()

func _on_focus_gained() -> void:
	_cover.hide()

func _exit_tree() -> void:
	if get_viewport().focus_exited.is_connected(_on_focus_lost):
		get_viewport().focus_exited.disconnect(_on_focus_lost)
	if get_viewport().focus_entered.is_connected(_on_focus_gained):
		get_viewport().focus_entered.disconnect(_on_focus_gained)
