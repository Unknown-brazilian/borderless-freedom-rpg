## ulrich_video_ui.gd
## "Vídeo recomendado" estilo YouTube — Fernando Ulrich recomendando Tesouro
## Direto em vez de Bitcoin (aparece em D6/Mexistão). Sátira de recomendação
## pública real. Thumbnail é PARÓDIA estilizada (sem foto/imagem real, por direitos).
## Aceitar (Tesouro Direto) = perde sats; Recusar (Bitcoin) = recompensa fixa.

extends CanvasLayer

signal closed

const EVENT_ID := "EVT-011"
const RED := Color(0.80, 0.12, 0.12)

var _event: Dictionary = {}
var _resolved: bool = false

func _ready() -> void:
	add_to_group("pauses_game")
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_event = _load_event()
	_build_ui()
	Engine.time_scale = 0.0   # pausa enquanto o "vídeo" está aberto

func _load_event() -> Dictionary:
	var path := "res://data/crypto_events.json"
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		for ev in parsed.get("random_events", []):
			if ev.get("id", "") == EVENT_ID:
				return ev
	return {}

func _sb(c: Color, radius: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(14)
	return sb

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(960, 0)
	card.offset_left = -480
	card.offset_right = 480
	card.offset_top = -760
	card.add_theme_constant_override("separation", 14)
	add_child(card)

	# ── "Player" do vídeo (thumbnail paródia 16:9) ──
	var thumb := Control.new()
	thumb.custom_minimum_size = Vector2(960, 540)
	card.add_child(thumb)

	var tbg := ColorRect.new()
	tbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	tbg.color = Color(0.10, 0.02, 0.02)
	thumb.add_child(tbg)

	# Se o usuário colocar uma foto/thumb real em assets/sprites/ulrich_thumb.*,
	# ela é usada. Senão, cai numa thumbnail-paródia (sem imagem de terceiros).
	var real_thumb := ""
	for ext in ["png", "jpg", "jpeg", "webp"]:
		var p := "res://assets/sprites/ulrich_thumb.%s" % ext
		if ResourceLoader.exists(p):
			real_thumb = p
			break
	if real_thumb != "":
		var tex := TextureRect.new()
		tex.texture = load(real_thumb)
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.add_child(tex)
	else:
		var tband := ColorRect.new()
		tband.set_anchors_preset(Control.PRESET_FULL_RECT)
		tband.color = Color(0.55, 0.06, 0.06, 0.55)
		thumb.add_child(tband)
		var clickbait := Label.new()
		clickbait.text = "📉 BITCOIN VAI\nDESPENCAR! 😱"
		clickbait.set_anchors_preset(Control.PRESET_FULL_RECT)
		clickbait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		clickbait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		clickbait.add_theme_font_size_override("font_size", 78)
		clickbait.add_theme_color_override("font_color", Color(1, 0.95, 0.2))
		clickbait.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		clickbait.add_theme_constant_override("outline_size", 12)
		thumb.add_child(clickbait)

	var dur := Label.new()
	dur.text = " 14:32 "
	dur.add_theme_font_size_override("font_size", 26)
	dur.add_theme_color_override("font_color", Color.WHITE)
	dur.add_theme_stylebox_override("normal", _sb(Color(0, 0, 0, 0.8), 4))
	dur.position = Vector2(820, 470)
	thumb.add_child(dur)

	var play := Label.new()
	play.text = "▶"
	play.set_anchors_preset(Control.PRESET_CENTER)
	play.offset_left = -60; play.offset_top = -60
	play.offset_right = 60; play.offset_bottom = 60
	play.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	play.add_theme_font_size_override("font_size", 70)
	play.add_theme_color_override("font_color", Color.WHITE)
	play.add_theme_stylebox_override("normal", _sb(Color(0.8, 0, 0, 0.85), 60))
	thumb.add_child(play)

	# ── Título ──
	var title := Label.new()
	title.text = "POR QUE TESOURO DIRETO É MELHOR QUE BITCOIN | análise"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(title)

	var meta := Label.new()
	meta.text = "847 mil visualizações · há 2 anos"
	meta.add_theme_font_size_override("font_size", 24)
	meta.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	card.add_child(meta)

	# ── Linha do canal ──
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 16)
	card.add_child(ch)
	var avatar := Label.new()
	avatar.text = "FU"
	avatar.custom_minimum_size = Vector2(72, 72)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_theme_font_size_override("font_size", 30)
	avatar.add_theme_color_override("font_color", Color.WHITE)
	avatar.add_theme_stylebox_override("normal", _sb(Color(0.2, 0.35, 0.6), 36))
	ch.add_child(avatar)
	var chname := Label.new()
	chname.text = "Fernando Ulrich  ✔\n1,2 mi de inscritos"
	chname.add_theme_font_size_override("font_size", 26)
	chname.add_theme_color_override("font_color", Color.WHITE)
	chname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(chname)
	var sub := Button.new()
	sub.text = "INSCREVER-SE"
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_stylebox_override("normal", _sb(RED, 8))
	sub.add_theme_color_override("font_color", Color.WHITE)
	ch.add_child(sub)

	# ── Descrição (pitch) ──
	var desc := Label.new()
	desc.text = _event.get("pitch", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 26)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	card.add_child(desc)

	# ── Ações ──
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	card.add_child(actions)

	var accept := Button.new()
	accept.text = _event.get("accept_button", "COMPRAR TESOURO DIRETO")
	accept.custom_minimum_size = Vector2(0, 80)
	accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accept.add_theme_font_size_override("font_size", 26)
	accept.add_theme_stylebox_override("normal", _sb(Color(0.13, 0.62, 0.20)))  # atraente (a armadilha)
	accept.add_theme_color_override("font_color", Color.WHITE)
	accept.pressed.connect(_on_accept)
	actions.add_child(accept)

	var refuse := Button.new()
	refuse.text = _event.get("ignore_button", "Prefiro Bitcoin")
	refuse.custom_minimum_size = Vector2(0, 80)
	refuse.add_theme_font_size_override("font_size", 22)
	refuse.add_theme_stylebox_override("normal", _sb(Color(0.22, 0.22, 0.26)))
	refuse.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	refuse.pressed.connect(_on_refuse)
	actions.add_child(refuse)

	Juice.button_feedback(accept)
	Juice.button_feedback(refuse)

# ── Resultados ────────────────────────────────────────────────────────────────
func _on_accept() -> void:
	if _resolved: return
	_resolved = true
	var acc: Dictionary = _event.get("accept_outcome", {})
	var loss_pct := float(acc.get("loss_percent", 60)) / 100.0
	var cap_pct := float(acc.get("loss_cap_percent", 40)) / 100.0
	var cur := SatEconomy.current_sats
	var loss := int(min(cur * loss_pct, cur * cap_pct))
	if loss > 0:
		SatEconomy.remove_sats(loss, "ulrich_tesouro_direto")
	_show_dialog([
		"📰  %s" % acc.get("news_headline", "Inflação corrói o Tesouro Direto."),
		"📰  %s" % acc.get("news_headline_2", ""),
		"💸  Você seguiu o conselho e ficou para trás do Bitcoin.",
		"📖  %s" % _event.get("ignore_outcome", {}).get("lesson", ""),
	])

func _on_refuse() -> void:
	if _resolved: return
	_resolved = true
	var ig: Dictionary = _event.get("ignore_outcome", {})
	var flat := int(ig.get("sat_bonus_flat", 0))
	if flat > 0:
		SatEconomy.add_sats(flat, "ulrich_refused_bitcoin")
	RandomEventsSystem.resolve_event(EVENT_ID, false)   # registra como evitado (glossário/streak)
	_show_dialog([
		ig.get("message", "Você preferiu Bitcoin."),
		"₿  Recompensa: +%d sats." % flat,
		"📖  %s" % ig.get("lesson", ""),
	])

func _show_dialog(lines: Array) -> void:
	var clean: Array[String] = []
	for l in lines:
		if l != null and str(l).strip_edges() != "" and str(l) != "📰  " and str(l) != "📖  ":
			clean.append(str(l))
	Engine.time_scale = 1.0
	queue_free()
	emit_signal("closed")
	DialogueManager.start(clean)
