## event_popup_ui.gd  (RPG)
## Popup de evento crypto — conecta ao RandomEventsSystem.
## Instanciado por world_map_base._ready() em cada mapa.

extends CanvasLayer

@onready var _panel:        PanelContainer = $Panel
@onready var _lbl_name:     Label          = $Panel/Margin/VBox/LabelEventName
@onready var _lbl_tagline:  Label          = $Panel/Margin/VBox/LabelTagline
@onready var _txt_pitch:    RichTextLabel  = $Panel/Margin/VBox/TextPitch
@onready var _lbl_urgency:  Label          = $Panel/Margin/VBox/LabelUrgency
@onready var _lbl_fine:     Label          = $Panel/Margin/VBox/LabelFinePrint
@onready var _timer_bar:    ProgressBar    = $Panel/Margin/VBox/TimerBar
@onready var _btn_accept:   Button         = $Panel/Margin/VBox/HBoxButtons/ButtonAccept
@onready var _btn_ignore:   Button         = $Panel/Margin/VBox/HBoxButtons/ButtonIgnore

const WINDOW_SECONDS := 8.0

var _current_event:   Dictionary = {}
var _timer_start_ms:  int        = 0
var _is_result:       bool       = false
var _prev_time_scale: float      = 1.0

func _ready() -> void:
	layer = 60   # bem acima de HUD/batalha/diálogo, p/ receber o toque dos botões
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("event_popup_ui")
	hide()

	_btn_accept.custom_minimum_size = Vector2(0, 64)
	_btn_ignore.custom_minimum_size = Vector2(0, 64)
	_btn_accept.pressed.connect(_on_accept)
	_btn_ignore.pressed.connect(_on_ignore)

	RandomEventsSystem.event_triggered.connect(_on_event_triggered)
	RandomEventsSystem.event_resolved.connect(_on_event_resolved)
	RandomEventsSystem.recovery_mode_started.connect(_on_recovery_started)
	RandomEventsSystem.recovery_mode_ended.connect(_on_recovery_ended)
	RandomEventsSystem.streak_reward_earned.connect(_on_streak_reward)

	call_deferred("_check_entry_event")

func _check_entry_event() -> void:
	RandomEventsSystem.check_for_event(WorldManager.current_dungeon)

func _process(_delta: float) -> void:
	if not visible or _is_result:
		return
	if not _timer_bar.visible:
		return   # ofertas não têm mais timeout
	var elapsed := (Time.get_ticks_msec() - _timer_start_ms) / 1000.0
	var remaining := maxf(WINDOW_SECONDS - elapsed, 0.0)
	_timer_bar.value = (remaining / WINDOW_SECONDS) * 100.0

	if remaining <= 2.0:
		_timer_bar.modulate = Color(1.0, 0.2, 0.2, 1.0)
	elif remaining <= 4.0:
		_timer_bar.modulate = Color(1.0, 0.6, 0.0, 1.0)
	else:
		_timer_bar.modulate = Color(1.0, 0.85, 0.0, 1.0)

	if remaining <= 0.0:
		_on_ignore()

# ─── Evento disparado ─────────────────────────────────────────────────────────
func _on_event_triggered(event_data: Dictionary) -> void:
	_current_event = event_data
	if event_data.get("is_collapse_news", false):
		_show_collapse(event_data)
	else:
		_show_offer(event_data)

func _show_offer(ev: Dictionary) -> void:
	_is_result         = false
	_timer_start_ms    = Time.get_ticks_msec()
	_lbl_name.text     = "⚠️  OPORTUNIDADE"
	_lbl_tagline.text  = ev.get("name", "???") + "\n" + ev.get("tagline", "")
	_txt_pitch.text    = ev.get("pitch", "")
	_lbl_urgency.text  = ev.get("urgency_text", "")
	_lbl_fine.text     = ev.get("fine_print", "")
	_btn_accept.text   = ev.get("accept_button", "ACEITAR")
	_btn_ignore.text   = ev.get("ignore_button", "Não, obrigado")
	# Armadilha educacional: ACEITAR (o golpe) é o botão atraente/verde — induz quem
	# não presta atenção a errar. Recusar é discreto/cinza. SEM timeout/pressão.
	_btn_accept.add_theme_stylebox_override("normal", _sb(Color(0.13, 0.62, 0.20, 1.0)))
	_btn_accept.add_theme_color_override("font_color", Color(1, 1, 1))
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.22, 0.22, 0.26, 1.0)))
	_btn_ignore.add_theme_color_override("font_color", Color(0.62, 0.62, 0.66))
	_btn_accept.visible    = true
	_btn_accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # CTA dominante
	_timer_bar.visible     = false   # sem contagem regressiva
	_lbl_urgency.visible   = not _lbl_urgency.text.is_empty()
	_lbl_fine.visible      = not _lbl_fine.text.is_empty()
	_prev_time_scale       = Engine.time_scale
	Engine.time_scale      = 0.0     # pausa total: o jogador decide sem pressa
	show()

func _show_collapse(ev: Dictionary) -> void:
	_is_result        = true
	_lbl_name.text    = "📰  NOTÍCIA URGENTE"
	_lbl_tagline.text = ev.get("name", "")
	_txt_pitch.text   = ev.get("headline", "A exchange faliu.")
	_lbl_urgency.text = ""
	_lbl_fine.text    = ""
	_btn_accept.visible   = false
	_btn_ignore.text      = "OK"
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.2, 0.2, 0.2, 1.0)))
	_timer_bar.visible    = false
	_prev_time_scale      = Engine.time_scale
	Engine.time_scale     = 0.0
	show()

# ─── Resolvido: evitou ────────────────────────────────────────────────────────
func _on_event_resolved(event_id: String, accepted: bool, sats_impact: int) -> void:
	if accepted:
		return
	var ev := RandomEventsSystem._find_event_by_id(event_id)
	if ev.is_empty():
		_close()
		return
	_show_avoided(ev, sats_impact)

func _show_avoided(ev: Dictionary, _sats: int) -> void:
	_is_result        = true
	var outcome: Dictionary = ev.get("ignore_outcome", {})
	var msg: String   = outcome.get("message", "Você evitou uma armadilha.")
	var lesson: String = outcome.get("lesson", "")
	_lbl_name.text    = "✅  RUGPULL EVITADO"
	_lbl_tagline.text = ev.get("name", "")
	_txt_pitch.text   = msg
	_lbl_urgency.text = '💡 "%s"' % lesson if not lesson.is_empty() else ""
	_lbl_fine.text    = "Entrada desbloqueada no Glossário do Dissidente."
	_btn_accept.visible   = false
	_btn_ignore.text      = "Continuar"
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.1, 0.45, 0.15, 1.0)))
	_timer_bar.visible    = false
	Engine.time_scale     = 0.0
	show()

# ─── Recovery / Streak ───────────────────────────────────────────────────────
func _on_recovery_started(sats_lost: int) -> void:
	_is_result        = true
	_current_event    = {}
	_lbl_name.text    = "📉  STACK COMPROMETIDO"
	_lbl_tagline.text = "Hora de trabalhar."
	_txt_pitch.text   = "Você perdeu %d sats.\nPrecisa recuperar %d sats.\n\n%s" % [
		sats_lost, int(sats_lost * 0.5), RandomEventsSystem.get_recovery_message()
	]
	_lbl_urgency.text = "⚠️  Barra de sats em vermelho até recuperar."
	_lbl_fine.text    = ""
	_btn_accept.visible   = false
	_btn_ignore.text      = "Entendi. Vou trabalhar."
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.15, 0.15, 0.15, 1.0)))
	_timer_bar.visible    = false
	_prev_time_scale      = Engine.time_scale
	Engine.time_scale     = 0.0
	show()

func _on_recovery_ended() -> void:
	_is_result        = true
	_current_event    = {}
	_lbl_name.text    = "✅  STACK ESTABILIZADO"
	_lbl_tagline.text = "Você se recuperou."
	_txt_pitch.text   = RandomEventsSystem.get_recovery_message()
	_lbl_urgency.text = ""
	_lbl_fine.text    = ""
	_btn_accept.visible   = false
	_btn_ignore.text      = "Continuar"
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.1, 0.45, 0.15, 1.0)))
	_timer_bar.visible    = false
	Engine.time_scale     = 0.0
	show()

func _on_streak_reward(reward_data: Dictionary) -> void:
	_is_result        = true
	_current_event    = {}
	_lbl_name.text    = "🏆  %s" % reward_data.get("title", "Conquista")
	_lbl_tagline.text = ""
	_txt_pitch.text   = reward_data.get("message", "Bônus desbloqueado!")
	_lbl_urgency.text = ""
	_lbl_fine.text    = ""
	_btn_accept.visible   = false
	_btn_ignore.text      = "Continuar"
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.1, 0.45, 0.15, 1.0)))
	_timer_bar.visible    = false
	Engine.time_scale     = 0.0
	show()

# ─── Botões ───────────────────────────────────────────────────────────────────
func _on_accept() -> void:
	if _current_event.is_empty(): return
	var delay: int = _current_event.get("accept_outcome", {}).get("delay_phases", 0)
	RandomEventsSystem.resolve_event(_current_event.get("id", ""), true)
	if not _is_result:
		if delay > 0:
			_show_investment_confirmed(_current_event)
		else:
			_close()

func _show_investment_confirmed(ev: Dictionary) -> void:
	_is_result        = true
	_lbl_name.text    = "📈  INVESTIMENTO CONFIRMADO"
	_lbl_tagline.text = ev.get("name", "")
	_txt_pitch.text   = "Seus sats foram depositados.\n\n\"Vai valer muito em breve!\" 🚀"
	_lbl_urgency.text = "⏳  Atualização em breve."
	_lbl_fine.text    = ""
	_btn_accept.visible   = false
	_btn_ignore.text      = "Continuar"
	_btn_ignore.add_theme_stylebox_override("normal", _sb(Color(0.1, 0.40, 0.15, 1.0)))
	_timer_bar.visible    = false
	Engine.time_scale     = 0.0
	show()

func _on_ignore() -> void:
	if _is_result:
		_close()
		return
	if _current_event.is_empty():
		_close()
		return
	RandomEventsSystem.resolve_event(_current_event.get("id", ""), false)

func _close() -> void:
	_current_event = {}
	_is_result     = false
	# Sempre restaura o tempo normal do overworld (1.0). Restaurar _prev_time_scale
	# era frágil: se o evento abrisse durante outro freeze, _prev era 0 e o jogo
	# ficava travado para sempre.
	Engine.time_scale = 1.0
	hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		_on_ignore()

# ─── Utilitário ───────────────────────────────────────────────────────────────
func _sb(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left     = 12
	sb.corner_radius_top_right    = 12
	sb.corner_radius_bottom_left  = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left   = 16
	sb.content_margin_right  = 16
	sb.content_margin_top    = 12
	sb.content_margin_bottom = 12
	return sb
