## phone_ui.gd — celular no estilo Wallet of Satoshi (carteira FICTÍCIA do jogo).
## Saldo real do player (sats) + History (notificações/doações) + Receive/Send
## (avisam que é fictícia e mandam baixar a WoS de verdade) + Jornada (mapa).
extends CanvasLayer

const GOLD := Color(0.96, 0.69, 0.13)
const BG   := Color(0.05, 0.05, 0.06)
const CARD := Color(0.13, 0.13, 0.15)
const GREEN := Color(0.30, 0.80, 0.45)
const SAT_TO_BRL := 0.001465   # 1 BTC ≈ R$146.500 (referência do jogo)

var _content: Control

func _ready() -> void:
	add_to_group("pauses_game")
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 0.0
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content)
	_show_main()

func _sb(c: Color, r: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(18)
	return sb

func _clear() -> void:
	for c in _content.get_children():
		c.queue_free()

func _brl(sats: int) -> String:
	return "≈ R$ %.2f" % (sats * SAT_TO_BRL)

# ─── Tela principal (carteira) ────────────────────────────────────────────────
func _show_main() -> void:
	_clear()
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 40; vb.offset_right = -40; vb.offset_top = 40; vb.offset_bottom = -40
	vb.add_theme_constant_override("separation", 18)
	_content.add_child(vb)

	# Cabeçalho
	var head := HBoxContainer.new()
	vb.add_child(head)
	var title := Label.new()
	title.text = "⚡ Wallet of Satoshi 🔑"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var x := Button.new()
	x.text = "✕"; x.add_theme_font_size_override("font_size", 34)
	x.pressed.connect(_close); Juice.button_feedback(x)
	head.add_child(x)

	# Espaço grande (WoS deixa o saldo no meio)
	var top_sp := Control.new(); top_sp.custom_minimum_size = Vector2(0, 360); vb.add_child(top_sp)

	# Saldo real
	var bal := Label.new()
	bal.text = "%s sats" % _fmt(SatEconomy.current_sats)
	bal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bal.add_theme_font_size_override("font_size", 92)
	bal.add_theme_color_override("font_color", GOLD)
	vb.add_child(bal)
	var fiat := Label.new()
	fiat.text = _brl(SatEconomy.current_sats)
	fiat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fiat.add_theme_font_size_override("font_size", 32)
	fiat.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vb.add_child(fiat)

	# Última transação
	if not Phone.notifications.is_empty():
		vb.add_child(_tx_card(Phone.notifications[0]))

	# History + Jornada
	var links := HBoxContainer.new()
	links.alignment = BoxContainer.ALIGNMENT_CENTER
	links.add_theme_constant_override("separation", 40)
	vb.add_child(links)
	links.add_child(_link("≣ History", _show_history))
	links.add_child(_link("🗺 Jornada", _show_journey))

	var grow := Control.new(); grow.size_flags_vertical = Control.SIZE_EXPAND_FILL; vb.add_child(grow)

	# Receive / Send
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 24)
	vb.add_child(btns)
	var recv := Button.new()
	recv.text = "Receive"; recv.custom_minimum_size = Vector2(0, 96)
	recv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recv.add_theme_font_size_override("font_size", 32)
	recv.add_theme_color_override("font_color", GOLD)
	recv.add_theme_stylebox_override("normal", _outline(GOLD))
	recv.pressed.connect(_fictional_notice); Juice.button_feedback(recv)
	btns.add_child(recv)
	var send := Button.new()
	send.text = "⛶ Send"; send.custom_minimum_size = Vector2(0, 96)
	send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	send.add_theme_font_size_override("font_size", 32)
	send.add_theme_color_override("font_color", Color.BLACK)
	send.add_theme_stylebox_override("normal", _sb(GOLD, 20))
	send.pressed.connect(_fictional_notice); Juice.button_feedback(send)
	btns.add_child(send)

func _outline(c: Color) -> StyleBoxFlat:
	var sb := _sb(BG, 20)
	sb.border_color = c
	sb.set_border_width_all(3)
	return sb

func _link(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	b.pressed.connect(cb); Juice.button_feedback(b, false)
	return b

func _tx_card(n: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(CARD))
	var h := HBoxContainer.new()
	card.add_child(h)
	var bolt := Label.new()
	bolt.text = "⚡"; bolt.add_theme_font_size_override("font_size", 40)
	bolt.add_theme_color_override("font_color", GOLD)
	h.add_child(bolt)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	var t := Label.new()
	var sats: int = n.get("sats", 0)
	t.text = "Payment Received" if sats > 0 else String(n.get("from", "Wallet of Satoshi"))
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", Color.WHITE)
	left.add_child(t)
	var sub := Label.new()
	sub.text = String(n.get("from", ""))
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	left.add_child(sub)
	var right := VBoxContainer.new()
	var amt := Label.new()
	amt.text = ("+%s sats" % _fmt(sats)) if sats > 0 else "—"
	amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amt.add_theme_font_size_override("font_size", 28)
	amt.add_theme_color_override("font_color", GREEN if sats > 0 else Color(0.8, 0.8, 0.8))
	right.add_child(amt)
	h.add_child(right)
	return card

# ─── History ──────────────────────────────────────────────────────────────────
func _show_history() -> void:
	_clear()
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 30; vb.offset_right = -30; vb.offset_top = 40; vb.offset_bottom = -40
	vb.add_theme_constant_override("separation", 14)
	_content.add_child(vb)
	var head := HBoxContainer.new(); vb.add_child(head)
	var bal := Label.new()
	bal.text = "%s sats   %s" % [_fmt(SatEconomy.current_sats), _brl(SatEconomy.current_sats)]
	bal.add_theme_font_size_override("font_size", 30)
	bal.add_theme_color_override("font_color", GOLD)
	bal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(bal)
	var back := Button.new(); back.text = "✕"; back.add_theme_font_size_override("font_size", 32)
	back.pressed.connect(_show_main); Juice.button_feedback(back); head.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	if Phone.notifications.is_empty():
		var e := Label.new(); e.text = "Sem transações ainda."
		e.add_theme_color_override("font_color", Color(0.6,0.6,0.6)); list.add_child(e)
	for n in Phone.notifications:
		list.add_child(_tx_card(n))

# ─── Maps (interface simplificada estilo Google Maps) ─────────────────────────
const MAPS_BG := Color(0.78, 0.85, 0.78)   # verde-claro tipo mapa
const MAPS_ROUTE := Color(0.20, 0.45, 0.90)

func _show_journey() -> void:
	_clear()
	var seq: Array = WorldManager.SCENE_SEQUENCE
	var cur: int = WorldManager.sequence_index
	var cur_name: String = seq[cur].get("name", "???") if cur < seq.size() else "???"

	# "Mapa" de fundo (gráfico simplificado).
	var mapbg := ColorRect.new()
	mapbg.color = MAPS_BG
	mapbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(mapbg)
	# "ruas" decorativas
	for yy in [300, 700, 1100, 1500]:
		var street := ColorRect.new()
		street.color = Color(1, 1, 1, 0.5)
		street.position = Vector2(0, yy); street.size = Vector2(1080, 10)
		mapbg.add_child(street)

	# Rota (linha azul) + nós das regiões, de baixo (início) pra cima (destino).
	var route := ScrollContainer.new()
	route.set_anchors_preset(Control.PRESET_FULL_RECT)
	route.offset_top = 150; route.offset_bottom = -40
	_content.add_child(route)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	route.add_child(col)
	# percorre de trás pra frente (destino em cima)
	for i in range(seq.size() - 1, -1, -1):
		var done := i < cur
		var here := i == cur
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		col.add_child(row)
		var dot := Label.new()
		dot.text = "📍" if here else ("●" if done else "○")
		dot.custom_minimum_size = Vector2(60, 60)
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.add_theme_font_size_override("font_size", 40 if here else 30)
		dot.add_theme_color_override("font_color", Color(0.85,0.15,0.15) if here else (MAPS_ROUTE if done else Color(0.4,0.4,0.4)))
		row.add_child(dot)
		var name_box := PanelContainer.new()
		name_box.add_theme_stylebox_override("panel", _sb(Color(1,1,1,0.92) if here else Color(1,1,1,0.7), 12))
		var nl := Label.new()
		nl.text = ("Você está aqui — " + str(seq[i].get("name","?"))) if here else str(seq[i].get("name","?"))
		nl.add_theme_font_size_override("font_size", 26 if here else 22)
		nl.add_theme_color_override("font_color", Color(0.1,0.1,0.1))
		name_box.add_child(nl)
		row.add_child(name_box)

	# Barra de busca estilo Maps (em cima) + fechar.
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _sb(Color(1,1,1,0.96), 28))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 30; bar.offset_right = -30; bar.offset_top = 40
	_content.add_child(bar)
	var bh := HBoxContainer.new(); bar.add_child(bh)
	var pin := Label.new(); pin.text = "🔍"; pin.add_theme_font_size_override("font_size", 30)
	bh.add_child(pin)
	var loc := Label.new()
	loc.text = "  " + cur_name
	loc.add_theme_font_size_override("font_size", 28)
	loc.add_theme_color_override("font_color", Color(0.1,0.1,0.1))
	loc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(loc)
	var back := Button.new(); back.text = "✕"; back.flat = true
	back.add_theme_font_size_override("font_size", 30)
	back.add_theme_color_override("font_color", Color(0.1,0.1,0.1))
	back.pressed.connect(_show_main); Juice.button_feedback(back); bh.add_child(back)

func _fictional_notice() -> void:
	DialogueManager.start([
		"⚡  Esta é uma carteira FICTÍCIA, parte do jogo.",
		"Os sats aqui não são reais.",
		"Para uma carteira Lightning de verdade, baixe a\nWallet of Satoshi original na Google Play Store.",
	])

func _close() -> void:
	Engine.time_scale = 1.0
	queue_free()

func _fmt(n: int) -> String:
	var s := str(n); var out := ""; var c := 0
	for i in range(s.length() - 1, -1, -1):
		if c > 0 and c % 3 == 0: out = "," + out
		out = s[i] + out; c += 1
	return out
