## world_map_base.gd
## Classe base para todos os mapas do RPG.
## Cada dungeon estende esta classe e sobrescreve _setup_npcs() e _setup_fiscais().

extends Node2D

const TILE_SIZE := 64

@onready var _tilemap:   TileMap          = $TileMap
@onready var _player:    CharacterBody2D  = $Player
@onready var _camera:    Camera2D         = $Camera2D

var _boss_triggered:  bool = false
var _boss_defeated:   bool = false
var _map_complete:    bool = false
var _exit_tile:       Vector2i = Vector2i(4, 2)
var _player_start:    Vector2i = Vector2i(4, 44)
var _boss_trigger_dist: int = 3   # tiles de distância para triggar boss

# ─── Terreno (preenchido em runtime a partir dos PNGs de tile) ────────────────
## Dimensões do mapa em tiles. Subclasses podem sobrescrever em _ready antes de super().
var _map_w: int = 23
var _map_h: int = 47
## Tema de chão: "grass" (default), "floor" (interior), "water" (margem).
var _ground_key: String = "grass"
## Tinta aplicada à TileMap inteira — dá clima/paleta própria a cada dungeon.
var _ground_tint: Color = Color.WHITE
## Se true, sem faixa de caminho (mapas internos/detenção).
var _no_path: bool = false
var _tile_ids: Dictionary = {}
var _last_step_msec: int = 0   # throttle do SFX de passo
## Ambiência sonora da dungeon. Faixa base única ("dungeon"); o pitch dá o clima
## de cada região (override em _setup_theme).
var _music_track: String = "dungeon"
var _music_pitch: float  = 1.0
var _post_mat: ShaderMaterial = null   # material do post-process (noite/visão noturna)
var _thieves_enabled: bool = false     # ladrões aleatórios (só Mexistão)
var _thief_last_ms: int = 0

func _ready() -> void:
	AutonomyBar.refill_all()
	AutonomyBar.set_active(true)

	_setup_theme()
	_paint_ground()
	_setup_post_fx()
	AudioManager.set_overworld_music(_music_track, _music_pitch)

	_player.position = Vector2(
		_player_start.x * TILE_SIZE + TILE_SIZE / 2,
		_player_start.y * TILE_SIZE + TILE_SIZE / 2
	)
	_camera.position = _player.position
	_player.player_moved.connect(_on_player_moved)

	_setup_npcs()
	_setup_fiscais()
	_setup_events()

	# Instancia EventPopupUI para eventos crypto desta região
	if get_tree().get_nodes_in_group("event_popup_ui").is_empty():
		var popup := preload("res://scenes/ui/EventPopupUI.tscn").instantiate()
		add_child(popup)

	await get_tree().create_timer(0.5).timeout
	_intro_dialogue()

func _process(delta: float) -> void:
	if is_instance_valid(_player):
		_camera.position = _camera.position.lerp(_player.position, delta * 6.0)
	_check_exit()

# ─── Post-process (color grade + vinheta + bloom por dungeon) ─────────────────
func _setup_post_fx() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1   # acima do mundo (layer 0), abaixo da HUD (layer 2)
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/world_post.gdshader")
	# Grade derivado do tema da dungeon: tom da região (suavizado),
	# interiores/detenções mais dessaturados e com vinheta mais forte.
	var tint := _ground_tint.lerp(Color.WHITE, 0.5)
	mat.set_shader_parameter("grade_tint", Vector3(tint.r, tint.g, tint.b))
	mat.set_shader_parameter("saturation", 0.75 if _no_path else 1.12)
	mat.set_shader_parameter("contrast", 1.06)
	mat.set_shader_parameter("brightness", 1.0)
	mat.set_shader_parameter("vignette_strength", 0.5 if _no_path else 0.38)
	mat.set_shader_parameter("bloom_strength", 0.45)
	rect.material = mat
	layer.add_child(rect)

	# Noite após 18h (hora do dispositivo) + óculos de visão noturna ativados.
	_post_mat = mat
	var h: int = Time.get_time_dict_from_system().get("hour", 12)
	mat.set_shader_parameter("night", 1.0 if (h >= 18 or h < 6) else 0.0)
	_update_night_vision()
	if not PlayerInventory.active_item_changed.is_connected(_on_active_item_changed):
		PlayerInventory.active_item_changed.connect(_on_active_item_changed)

func _on_active_item_changed(_id: String) -> void:
	_update_night_vision()

func _update_night_vision() -> void:
	if is_instance_valid(_post_mat):
		var on := PlayerInventory.active_item == "item_oculos_noturno"
		_post_mat.set_shader_parameter("night_vision", 1.0 if on else 0.0)

# ─── Terreno ──────────────────────────────────────────────────────────────────

## Constrói uma TileSet em runtime com uma fonte (atlas) por textura de tile.
## As texturas são 32×32; a TileMap é escalada 2× para casar com o grid de 64px.
func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	_tile_ids.clear()
	var defs := {
		"grass": "res://assets/tiles/grass.png",
		"path":  "res://assets/tiles/path.png",
		"wall":  "res://assets/tiles/wall.png",
		"water": "res://assets/tiles/water.png",
		"floor": "res://assets/tiles/floor_indoor.png",
	}
	for key in defs:
		var tex: Texture2D = load(defs[key])
		if tex == null:
			continue
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(32, 32)
		src.create_tile(Vector2i(0, 0))
		_tile_ids[key] = ts.add_source(src)
	return ts

## Pinta chão + caminho central + borda de parede em toda a área do mapa.
func _paint_ground() -> void:
	if not is_instance_valid(_tilemap):
		return
	_tilemap.tile_set = _build_tileset()
	_tilemap.scale = Vector2(2, 2)
	_tilemap.z_index = -10
	_tilemap.modulate = _ground_tint
	_tilemap.clear()

	var ground: String = _ground_key if _tile_ids.has(_ground_key) else "grass"
	var path_min: int = maxi(1, _player_start.x - 1)
	var path_max: int = mini(_map_w - 2, _player_start.x + 1)

	for y in range(_map_h):
		for x in range(_map_w):
			var key := ground
			if x == 0 or y == 0 or x == _map_w - 1 or y == _map_h - 1:
				key = "wall"
			elif not _no_path and x >= path_min and x <= path_max:
				key = "path"
			if not _tile_ids.has(key):
				key = ground
			_tilemap.set_cell(0, Vector2i(x, y), _tile_ids[key], Vector2i(0, 0))

	# Trava a câmera nos limites do mapa para não exibir o vazio fora dele.
	if is_instance_valid(_camera):
		_camera.limit_left   = 0
		_camera.limit_top    = 0
		_camera.limit_right  = _map_w * TILE_SIZE
		_camera.limit_bottom = _map_h * TILE_SIZE

# ─── Overrides nos filhos ─────────────────────────────────────────────────────
## Override para definir paleta/clima do mapa (_ground_tint/_ground_key/_no_path
## /_map_w/_map_h). Chamado no início de _ready, antes de pintar o terreno.
func _setup_theme() -> void:  pass
func _setup_npcs() -> void:   pass
func _setup_fiscais() -> void: pass
func _setup_events() -> void:  pass
func _intro_dialogue() -> void: pass
func _get_boss_data() -> Dictionary: return {}
func _get_boss_id() -> String: return ""

# ─── Player moved ────────────────────────────────────────────────────────────
func _on_player_moved(tile_pos: Vector2i) -> void:
	AutonomyBar.consume("energy", 0.12)
	GameStats.record_step()
	# SFX de passo com throttle para não sobrepor em movimento contínuo.
	var now := Time.get_ticks_msec()
	if now - _last_step_msec >= 170:
		_last_step_msec = now
		AudioManager.sfx("step")
	if not _boss_triggered and not _get_boss_id().is_empty():
		if tile_pos.distance_to(_exit_tile) < _boss_trigger_dist + 2:
			_trigger_boss()
	if _thieves_enabled:
		_maybe_spawn_thief()

# ─── Ladrões (encontro aleatório — habilitado só no Mexistão) ──────────────────
func _maybe_spawn_thief() -> void:
	if BattleManager.state != BattleManager.State.IDLE:
		return
	var now := Time.get_ticks_msec()
	if now - _thief_last_ms < 15000:   # cooldown 15s
		return
	if randf() > 0.08:                  # 8% por passo após o cooldown
		return
	_thief_last_ms = now
	if not is_instance_valid(_player):
		return
	var e = preload("res://scenes/world/EnemyPatrol.tscn").instantiate()
	e.enemy_data = {
		"name": "Ladrão", "hp": 28, "atk": 13, "reward_sats": 12,
		"bribe_cost": 0, "weakness_item": "item_spray", "is_boss": false,
	}
	e.always_visible = true   # ladrão aparece mesmo sem binóculos
	var ppos: Vector2 = _player.position + Vector2(randf_range(-60, 60), -150)
	e.position = ppos
	var wps: Array[Vector2] = [ppos + Vector2(48, 0), ppos + Vector2(-48, 0)]
	e.patrol_waypoints = wps
	e.map_min = Vector2(TILE_SIZE, TILE_SIZE)
	e.map_max = Vector2(_map_w * TILE_SIZE, _map_h * TILE_SIZE)
	add_child(e)
	AudioManager.sfx("event")

func _trigger_boss() -> void:
	if _boss_triggered:
		return
	_boss_triggered = true
	_player.set_can_move(false)
	var bd := _get_boss_data()
	var intro: Array = bd.get("intro_lines", ["🚨  Um chefe bloqueia o caminho!"])
	DialogueManager.start(intro)
	await DialogueManager.dialogue_finished
	BattleManager.battle_ended.connect(_on_boss_result, CONNECT_ONE_SHOT)
	BattleManager.start_battle(bd)

func _on_boss_result(result: String) -> void:
	if result == "victory":
		_boss_defeated = true
		_player.set_can_move(false)
		var bd := _get_boss_data()
		var victory_lines: Array[String] = []
		victory_lines.assign(bd.get("victory_lines", ["🏆  Chefe derrotado! Avance."]))
		DialogueManager.start(victory_lines)
		await DialogueManager.dialogue_finished
		var boss_id := _get_boss_id()
		if not boss_id.is_empty():
			var challenge := preload("res://scenes/ui/BossWordChallenge.tscn").instantiate()
			add_child(challenge)
			challenge.setup(boss_id, bd.get("reward_sats", 100))
			challenge.show()
			challenge.challenge_result.connect(func(_p: bool, _b: int):
				_map_complete = true
				_player.set_can_move(true)
			)
		else:
			_map_complete = true
			_player.set_can_move(true)
	elif result == "defeat":
		await get_tree().create_timer(1.5).timeout
		SceneTransition.go("res://scenes/ui/main_menu.tscn")

func _check_exit() -> void:
	if not _map_complete:
		return
	if not is_instance_valid(_player):
		return
	var pt: Vector2i = _player.get_tile_position()
	if pt.distance_to(_exit_tile) < 2:
		_map_complete = false
		WorldManager.advance_to_next_dungeon()

# ─── Spawn helpers ───────────────────────────────────────────────────────────
func spawn_npc(tile: Vector2i, name_str: String, dialogue: Array, color: Color = Color(0.6, 0.6, 0.8)) -> Node:
	var npc := preload("res://scenes/world/NPC.tscn").instantiate()
	npc.npc_name     = name_str
	npc.sprite_color = color
	npc.lines.assign(dialogue)
	npc.position = _tile_to_world(tile)
	add_child(npc)
	return npc

func spawn_fiscal(tile: Vector2i, name_str: String, hp: int, atk: int, reward: int, bribe: int, weakness: String = "item_spray") -> Node:
	var f := preload("res://scenes/world/FiscalNPC.tscn").instantiate()
	f.npc_name   = name_str
	f.bribe_cost = bribe
	f.enemy_data = {
		"name": name_str, "hp": hp, "atk": atk,
		"reward_sats": reward, "bribe_cost": bribe,
		"weakness_item": weakness, "is_boss": false,
	}
	f.position = _tile_to_world(tile)
	add_child(f)
	return f

## Spawn inimigo patrulheiro com rota de dois pontos em torno do tile.
func spawn_patrol_enemy(tile: Vector2i, name_str: String, hp: int, atk: int,
		reward: int, bribe: int, weakness: String = "item_spray",
		patrol_spread: int = 2) -> void:
	var e := preload("res://scenes/world/EnemyPatrol.tscn").instantiate()
	e.enemy_data = {
		"name": name_str, "hp": hp, "atk": atk,
		"reward_sats": reward, "bribe_cost": bribe,
		"weakness_item": weakness, "is_boss": false,
	}
	var world_pos := _tile_to_world(tile)
	e.position = world_pos
	var spread := patrol_spread * TILE_SIZE
	var wps: Array[Vector2] = [
		world_pos + Vector2(spread, 0),
		world_pos + Vector2(-spread, 0),
	]
	e.patrol_waypoints = wps
	add_child(e)

## Spawn NPC de scam cripto (sem timeout, pitch convincente).
func spawn_crypto_npc(tile: Vector2i, event_id: String) -> void:
	var c := preload("res://scenes/world/CryptoNPC.tscn").instantiate()
	c.event_id = event_id
	c.position = _tile_to_world(tile)
	add_child(c)

## Item colecionável no chão (binóculos, água, peças da bike, etc.).
func spawn_pickup(tile: Vector2i, item_id: String, icon: String, label_text: String,
		effect: String = "unlock", amount: float = 40.0) -> void:
	var pk = preload("res://scripts/world/map_pickup.gd").new()
	pk.item_id = item_id
	pk.icon = icon
	pk.label_text = label_text
	pk.effect = effect
	pk.amount = amount
	pk.position = _tile_to_world(tile)
	add_child(pk)

## Ponto de acampamento (descansar + salvar).
func spawn_campsite(tile: Vector2i) -> void:
	var c = preload("res://scripts/world/campsite.gd").new()
	c.position = _tile_to_world(tile)
	add_child(c)

## Obstáculo sólido (bloqueia o player) — pedra/entulho (bloco colorido robusto).
func spawn_obstacle(tile: Vector2i, _icon: String = "") -> void:
	var o := StaticBody2D.new()
	o.set_collision_layer_value(1, true)   # camada world
	o.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(58, 58)
	shape.shape = rect
	o.add_child(shape)
	var rock := ColorRect.new()
	rock.size = Vector2(54, 50)
	rock.position = Vector2(-27, -34)
	rock.color = Color(0.32, 0.28, 0.24)   # pedra/entulho marrom
	o.add_child(rock)
	var top := ColorRect.new()
	top.size = Vector2(54, 8)
	top.position = Vector2(-27, -34)
	top.color = Color(0.42, 0.37, 0.32)    # topo mais claro
	o.add_child(top)
	o.position = _tile_to_world(tile)
	add_child(o)

func _tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2, tile.y * TILE_SIZE + TILE_SIZE / 2)
