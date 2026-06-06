## boss_word_challenge.gd
## Borderless Freedom: A Dissident Adventure
## Desafio de palavras da seed após cada chefe — mecânica tap-to-select.
## Exibe 6 botões por rodada; o player toca a palavra correta da sua seed.
##
## ⚠️  ESTA É UMA SEED DO JOGO, NÃO UMA SEED REAL DE BITCOIN.
##     NUNCA TOQUE SEEDS REAIS COM SALDO EM APLICATIVOS.

extends CanvasLayer

# ─── Sinal ────────────────────────────────────────────────────────────────────
signal challenge_result(passed: bool, bonus_sats: int)

# ─── Nós ──────────────────────────────────────────────────────────────────────
@onready var _lbl_prompt:   Label         = $Panel/VBox/LabelPrompt
@onready var _lbl_progress: Label         = $Panel/VBox/LabelProgress
@onready var _lbl_word_pos: Label         = $Panel/VBox/LabelWordPos
@onready var _word_grid:    GridContainer = $Panel/VBox/WordGrid
@onready var _lbl_result:   Label         = $Panel/VBox/LabelResult
@onready var _btn_skip:     Button        = $Panel/VBox/ButtonSkip

# ─── Constantes ───────────────────────────────────────────────────────────────
const CHOICES_PER_STEP := 6

# ─── Estado ───────────────────────────────────────────────────────────────────
var _boss_id:      String    = ""
var _base_loot:    int       = 0
var _positions:    Array[int] = []
var _step:         int       = 0
var _errors:       int       = 0
var _choosing:     bool      = false
var _word_buttons: Array     = []

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	_btn_skip.pressed.connect(_on_skip)
	_lbl_result.hide()
	hide()
	var cover := ColorRect.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.color = Color(0, 0, 0, 1)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.hide()
	add_child(cover)
	get_viewport().focus_exited.connect(func(): if is_instance_valid(cover): cover.show())
	get_viewport().focus_entered.connect(func(): if is_instance_valid(cover): cover.hide())

# ─── API pública ──────────────────────────────────────────────────────────────
func setup(boss_id: String, base_loot: int) -> void:
	_boss_id   = boss_id
	_base_loot = base_loot
	_step      = 0
	_errors    = 0
	_positions = SeedPhraseSystem.get_boss_challenge_positions(boss_id)
	var bonus_amt := int(base_loot * SeedPhraseSystem.BONUS_MULTIPLIER)
	_lbl_prompt.text = (
		"🔑  Chefe derrotado! Toque as 4 palavras corretas\n" +
		"da sua seed e ganhe +%d sats de bônus." % bonus_amt
	)
	_show_step()

# ─── Fluxo interno ────────────────────────────────────────────────────────────
func _show_step() -> void:
	if _step >= _positions.size():
		_finish()
		return
	_choosing = false
	var pos := _positions[_step]
	_lbl_word_pos.text  = "🔢  Palavra #%d da sua seed:" % pos
	_lbl_progress.text  = "Rodada %d de %d" % [_step + 1, _positions.size()]
	_lbl_result.hide()
	_build_buttons(pos)

func _build_buttons(pos: int) -> void:
	for b in _word_buttons:
		if is_instance_valid(b): b.queue_free()
	_word_buttons.clear()

	var correct_word := SeedPhraseSystem.words[pos - 1]
	var decoys := SeedPhraseSystem.get_random_decoys(CHOICES_PER_STEP - 1, correct_word)
	var choices: Array = decoys + [correct_word]
	choices.shuffle()

	for word in choices:
		var btn := Button.new()
		btn.text = str(word)
		btn.custom_minimum_size = Vector2(0, 76)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_word_pressed.bind(btn, str(word), correct_word))
		_word_grid.add_child(btn)
		_word_buttons.append(btn)

func _on_word_pressed(btn: Button, chosen: String, correct: String) -> void:
	if _choosing: return
	_choosing = true
	_set_all_disabled(true)

	if chosen == correct:
		btn.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
		_lbl_result.text = "✅  Correto!"
		_lbl_result.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
		_lbl_result.show()
		await get_tree().create_timer(0.7).timeout
		_step += 1
		_show_step()
	else:
		_errors += 1
		btn.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
		_lbl_result.text = "❌  Errado! Era: %s" % correct
		_lbl_result.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
		_lbl_result.show()
		await get_tree().create_timer(1.2).timeout
		_step += 1
		_show_step()

func _set_all_disabled(state: bool) -> void:
	for b in _word_buttons:
		if is_instance_valid(b): (b as Button).disabled = state

func _finish() -> void:
	var passed    := _errors == 0
	var bonus_sats := 0
	for b in _word_buttons:
		if is_instance_valid(b): b.queue_free()
	_word_buttons.clear()
	_lbl_word_pos.text  = ""
	_lbl_progress.text  = ""
	_btn_skip.hide()

	if passed:
		bonus_sats = SeedPhraseSystem.award_boss_bonus(_boss_id, _base_loot)
		_lbl_result.text = "🏆  PERFEITO! +%d sats de bônus!" % bonus_sats
		_lbl_result.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
	else:
		_lbl_result.text = "❌  %d erro(s). Sem bônus desta vez." % _errors
		_lbl_result.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15))
	_lbl_result.show()

	await get_tree().create_timer(2.5).timeout
	emit_signal("challenge_result", passed, bonus_sats)
	queue_free()

func _on_skip() -> void:
	emit_signal("challenge_result", false, 0)
	queue_free()
