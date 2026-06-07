## d6_mexistao.gd
## Mapa D6 — Mexistão (Tapachula ao Norte).
## O mapa mais longo — múltiplos fiscais, La Bestia, cartéis.

extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start = Vector2i(4, 44)
	_exit_tile    = Vector2i(4, 2)
	_boss_trigger_dist = 4
	_thieves_enabled = true   # ladrões aleatórios só no Mexistão
	super._ready()

var _stolen_phone_sats: int = 0

func _on_player_moved(tile_pos: Vector2i) -> void:
	super._on_player_moved(tile_pos)
	# Eventos da jornada (na ordem em que o player sobe o mapa).
	if not WorldManager.get_flag("huixtla_robbery", false) and tile_pos.y <= 28:
		_huixtla_robbery()
	elif not WorldManager.get_flag("phone_robbery", false) and tile_pos.y <= 20:
		_phone_robbery()
	elif not WorldManager.get_flag("phone_recovered", false) \
			and WorldManager.get_flag("phone_robbery", false) and tile_pos.y <= 12:
		_coatzacoalcos_recovery()

## Entre Piedras Negras e Orizaba — roubam o celular (acesso à carteira).
func _phone_robbery() -> void:
	WorldManager.set_flag("phone_robbery", true)
	_player.set_can_move(false)
	_stolen_phone_sats = int(SatEconomy.current_sats * 0.5)
	if _stolen_phone_sats > 0:
		SatEconomy.remove_sats(_stolen_phone_sats, "phone_robbery")
	AudioManager.sfx("hit")
	DialogueManager.start([
		"📱🦹  Entre Piedras Negras e Orizaba, levaram seu celular.",
		"Com ele, o acesso à sua Wallet of Satoshi.",
		"Metade do seu saldo ficou preso no aparelho roubado.",
	])
	await DialogueManager.dialogue_finished
	_player.set_can_move(true)

## Coatzacoalcos — suporte da Wallet of Satoshi recupera o saldo + Hugo Ramos.
func _coatzacoalcos_recovery() -> void:
	WorldManager.set_flag("phone_recovered", true)
	_player.set_can_move(false)
	if _stolen_phone_sats > 0:
		SatEconomy.add_sats(_stolen_phone_sats, "wos_support_recovery")
	Phone.notify("Suporte Wallet of Satoshi",
		"Saldo recuperado com sucesso. Valeu, Hugo Ramos — hash da tx recuperada! ⚡",
		_stolen_phone_sats)
	AudioManager.sfx("coin")
	DialogueManager.start([
		"📩  Em Coatzacoalcos, você mandou mensagem pro suporte da Wallet of Satoshi.",
		"Eles ajudaram a recuperar seu saldo. ⚡",
		"🙏  E valeu, Hugo Ramos — ele recuperou a hash de uma tx que fizemos juntos.",
		"Saldo de volta: +%d sats." % _stolen_phone_sats,
	])
	await DialogueManager.dialogue_finished
	_player.set_can_move(true)

## Assalto depois de Huixtla: perde a bicicleta e os binóculos.
func _huixtla_robbery() -> void:
	WorldManager.set_flag("huixtla_robbery", true)
	_player.set_can_move(false)
	PlayerCustomization.bike_index = 0
	var bike = _player.get_node_or_null("BikeIcon")
	if bike:
		bike.queue_free()
	PlayerInventory.unlocked.erase("item_binoculo")
	if PlayerInventory.active_item == "item_binoculo":
		PlayerInventory.active_item = ""
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("_apply_binoculars_gate"):
			e._apply_binoculars_gate()
	AudioManager.sfx("hit")
	DialogueManager.start([
		"🦹💥  Depois de Huixtla, você foi assaltado na estrada.",
		"Levaram sua bicicleta e seus binóculos.",
		"Agora é a pé — e os guardas somem até você achar outro binóculo.",
	])
	await DialogueManager.dialogue_finished
	_player.set_can_move(true)

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — D6, Mexistão" % PlayerStats.player_name,
		"Tapachula. A cidade que nunca larga.",
		"São 3.000 km até a fronteira norte.",
		"Fiscais, cartéis e La Bestia te aguardam.",
		"Guarde seus sats — vai precisar de muitos.",
	])
	await DialogueManager.dialogue_finished
	AutonomyBar.consume("energy", 10.0)
	_maybe_show_ulrich_video()

## CDMX — "vídeo recomendado" do Fernando Ulrich (Tesouro Direto vs Bitcoin).
## Aparece uma vez, como uma janelinha de YouTube.
func _maybe_show_ulrich_video() -> void:
	if WorldManager.get_flag("ulrich_video_seen", false):
		return
	WorldManager.set_flag("ulrich_video_seen", true)
	await get_tree().create_timer(1.4, true, false, true).timeout
	DialogueManager.start(["📱  Um vídeo apareceu nos recomendados..."])
	await DialogueManager.dialogue_finished
	var vid := CanvasLayer.new()
	vid.set_script(load("res://scripts/ui/ulrich_video_ui.gd"))
	get_tree().current_scene.add_child(vid)

func _setup_npcs() -> void:
	# México: comida (miojo) e peças pra remontar a bike (depois do assalto).
	spawn_pickup(Vector2i(8, 24), "", "🍜", "Miojo! +45 comida", "food", 45.0)
	spawn_pickup(Vector2i(18, 18), "item_pneu", "🛞", "Pneu! (peça da bike)", "bikepart")
	spawn_pickup(Vector2i(3, 12), "item_camara_ar", "⭕", "Câmara de ar! (peça da bike)", "bikepart")
	spawn_npc(Vector2i(6, 42), "Migrante Veterano",
		["Mexistão é o país mais difícil da rota.",
		 "Fiscal te para no sul. Cartel te cobra no norte.",
		 "Furtividade aqui vale ouro.",
		 "Ou sats — que é a mesma coisa."],
		Color(0.75, 0.55, 0.25)
	)
	spawn_npc(Vector2i(2, 34), "Padre Solidário",
		["Aqui ninguém te pergunta de onde vem.",
		 "Descanse. A jornada ainda é longa.",
		 "El Señor Transformação controla o norte.",
		 "Ninguém sabe sua forma real."],
		Color(0.7, 0.7, 0.9)
	)
	spawn_npc(Vector2i(8, 24), "Jornaleiro",
		["AMLO, o Tlatoani está lá no fim.",
		 "Dizem que tem 7 formas.",
		 "Nunca vi ninguém que passou sem a seed.",
		],
		Color(0.969, 0.576, 0.102)
	)
	spawn_npc(Vector2i(3, 14), "Ex-Policial",
		["Trabalhei para o sistema por 10 anos.",
		 "Saí quando vi o que eles fazem com os sats.",
		 "O spray repelente funciona bem aqui."],
		Color(0.4, 0.8, 0.5)
	)

func _setup_fiscais() -> void:
	# Patrulheiros visíveis — perseguem o player ao vê-lo
	spawn_patrol_enemy(Vector2i(4, 36), "Agente do AMLO",    155, 25, 78, 75, "item_spray", 3)
	spawn_patrol_enemy(Vector2i(5, 28), "Inspetor da Sheinbaum",      165, 28, 83, 82, "item_camera", 2)
	spawn_patrol_enemy(Vector2i(3, 20), "Guarda do Adán Augusto",        175, 31, 88, 90, "item_spray", 4)
	spawn_patrol_enemy(Vector2i(6, 12), "Agente do Monreal", 185, 34, 93, 95, "item_panfleto", 2)

func _setup_events() -> void:
	spawn_crypto_npc(Vector2i(7, 40), "EVT-004")   # TERRAFORMA (D3-D6)
	spawn_crypto_npc(Vector2i(1, 16), "EVT-007")   # Quadrix Exchange (D2-D5)

func _get_boss_id() -> String:
	return "BOSS-D6-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "AMLO, o Tlatoani",
		"hp": 350,
		"atk": 45,
		"reward_sats": 300,
		"bribe_cost": 999,
		"weakness_item": "item_camera",
		"is_boss": true,
		"boss_id": "BOSS-D6-FINAL",
		"intro_lines": [
			"🏭  O COMPLEXO se manifesta!",
			"\"Forma 1: Burocracia Infinita...\"",
			"Um chefe com 7 formas. O mais difícil até agora.",
			"A câmera expõe cada forma — use-a.",
		],
		"victory_lines": [
			"🏆  O COMPLEXO DESTRUÍDO!",
			"Todas as 7 formas derrotadas.",
			"A fronteira norte do Mexistão está livre.",
			"🔑  Prove que a seed é sua...",
		],
	}

func _setup_theme() -> void:
	_ground_key = "path"
	_no_path = true
	_ground_tint = Color(1.0, 0.93, 0.74)
	_music_pitch = 0.98
