## d4_panamia.gd
## Mapa D4 — Panamia com a escolha do Darién.
## O player pode pagar 200 sats para voar ou atravessar a selva.

extends "res://scripts/world/world_map_base.gd"

const FLIGHT_COST := 200

var _choice_made: bool = false
var _chose_jungle: bool = false
var _choice_panel: CanvasLayer = null

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	_stretch = 1.5
	super._ready()

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D4, Panamia" % PlayerStats.player_name,
		"Você chegou à fronteira do Darién.",
		"Atravessar a selva é perigoso.",
		"Mas pagar pelo vôo custa %d sats." % FLIGHT_COST,
	])
	await DialogueManager.dialogue_finished
	_show_darien_choice()

func _show_darien_choice() -> void:
	if _choice_made:
		return

	_choice_panel = CanvasLayer.new()
	_choice_panel.layer = 15
	add_child(_choice_panel)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.03, 0.05, 0.88)
	_choice_panel.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.set_anchor(SIDE_LEFT, 0.05)
	vbox.set_anchor(SIDE_RIGHT, 0.95)
	vbox.set_anchor(SIDE_TOP, 0.2)
	vbox.set_anchor(SIDE_BOTTOM, 0.8)
	vbox.add_theme_constant_override("separation", 32)
	_choice_panel.add_child(vbox)

	var lbl_title := Label.new()
	lbl_title.text = "O CRUZAMENTO DO DARIÉN"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 40)
	lbl_title.add_theme_color_override("font_color", Color(0.969, 0.576, 0.102))
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_title)

	var lbl_desc := Label.new()
	lbl_desc.text = "A selva é brutal — drena energia e água rapidamente.\nUm vôo custa %d sats mas garante passagem segura." % FLIGHT_COST
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_font_size_override("font_size", 30)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)

	var lbl_sats := Label.new()
	lbl_sats.text = "Seus sats: %d" % SatEconomy.current_sats
	lbl_sats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sats.add_theme_font_size_override("font_size", 32)
	lbl_sats.add_theme_color_override("font_color", Color(0.969, 0.576, 0.102))
	vbox.add_child(lbl_sats)

	var btn_fly := Button.new()
	btn_fly.text = "✈  Pagar %d sats pelo vôo" % FLIGHT_COST
	btn_fly.custom_minimum_size = Vector2(0, 96)
	btn_fly.add_theme_font_size_override("font_size", 34)
	btn_fly.disabled = SatEconomy.current_sats < FLIGHT_COST
	btn_fly.pressed.connect(_on_chose_flight)
	vbox.add_child(btn_fly)

	var btn_jungle := Button.new()
	btn_jungle.text = "🌿  Atravessar a selva (perigoso)"
	btn_jungle.custom_minimum_size = Vector2(0, 96)
	btn_jungle.add_theme_font_size_override("font_size", 34)
	btn_jungle.add_theme_color_override("font_color", Color(0.9, 0.4, 0.2))
	btn_jungle.pressed.connect(_on_chose_jungle)
	vbox.add_child(btn_jungle)

func _on_chose_flight() -> void:
	_choice_made = true
	_chose_jungle = false
	SatEconomy.remove_sats(FLIGHT_COST, "darien_flight")
	if is_instance_valid(_choice_panel):
		_choice_panel.queue_free()
	DialogueManager.start([
		"✈  Você comprou uma passagem aérea!",
		"-%d sats gastos." % FLIGHT_COST,
		"Pulando o Darién com segurança...",
	])
	await DialogueManager.dialogue_finished
	_map_complete = true
	_player.set_can_move(true)

func _on_chose_jungle() -> void:
	_choice_made = true
	_chose_jungle = true
	if is_instance_valid(_choice_panel):
		_choice_panel.queue_free()
	DialogueManager.start([
		"🌿  Você escolheu atravessar a selva.",
		"A energia e a água serão drenadas.",
		"Cuidado com os fiscais da fronteira...",
	])
	await DialogueManager.dialogue_finished
	_player.set_can_move(true)
	_spawn_jungle_fiscais()
	_apply_jungle_drain()

func _apply_jungle_drain() -> void:
	AutonomyBar.consume("energy", 25.0)
	AutonomyBar.consume("water",  20.0)
	AutonomyBar.consume("food",   15.0)

func _setup_npcs() -> void:
	spawn_building(Vector2i(9, 36), "res://scenes/world/loja_interior.tscn", "Loja & Empregos")
	spawn_campsite(Vector2i(3, 24))
	spawn_npc(Vector2i(6, 42), "Migrante Experiente",
		["Bem-vindo à Panamia.",
		 "Se tiver sats, pague pelo vôo.",
		 "A selva do Darién não perdoa.",
		],
		Color(0.4, 0.65, 0.9)
	)
	spawn_npc(Vector2i(2, 30), "Guia Local",
		["Posso te guiar pela selva por nada.",
		 "Mas fiscais da fronteira patrulham.",
		 "Use furtividade se puder.",
		],
		Color(0.3, 0.75, 0.4)
	)

func _setup_fiscais() -> void:
	pass  # Fiscais aparecem apenas se o player escolher a selva — veja _on_chose_jungle()

func _spawn_jungle_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(4, 30), "Patrulha do Martinelli",  140, 22, 73, 70, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(5, 20), "Patrulha do Mulino", 155, 25, 80, 80, "item_spray", 2)
	spawn_patrol_enemy(Vector2i(3, 12), "Agente do Cortizo",  170, 28, 110, 90, "item_spray", 2)


func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(8, 38), "EVT-004")

func _get_boss_id() -> String:
	return "BOSS-D4-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Martinelli, o Foragido",
		"hp": 200,
		"atk": 32,
		"reward_sats": 220,
		"bribe_cost": 999,
		"weakness_item": "item_radio",
		"is_boss": true,
		"boss_id": "BOSS-D4-FINAL",
		"intro_lines": [
			"🚨  Martinelli, o Foragido bloqueia a saída!",
			"\"Nenhum indocumentado passa aqui.\"",
			"Use o rádio para confundi-la.",
		],
		"victory_lines": [
			"🏆  Martinelli, o Foragido, derrotado!",
			"A passagem para o norte está livre.",
			"🔑  Prove sua identidade soberana...",
		],
	}

func _setup_theme() -> void:
	_ground_tint = Color(0.62, 0.8, 0.6)
	_music_pitch = 1.04
