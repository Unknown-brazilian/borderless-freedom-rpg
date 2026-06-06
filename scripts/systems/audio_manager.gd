## audio_manager.gd
## Borderless Freedom: A Dissident Adventure
## AutoLoad — música e SFX. Falha silenciosamente se os arquivos não existirem.
##
## Assets esperados em res://audio/:
##   music/menu.ogg, music/dungeon.ogg, music/boss.ogg,
##   music/transition.ogg, music/game_over.ogg,
##   music/ending.ogg, music/ending_sovereign.ogg
##   sfx/coin.ogg, sfx/hit.ogg, sfx/jump.ogg, sfx/checkpoint.ogg,
##   sfx/boss_phase.ogg, sfx/milestone.ogg, sfx/event.ogg,
##   sfx/menu_click.ogg, sfx/upgrade.ogg, sfx/victory.ogg

extends Node

const MUSIC_DIR := "res://audio/music/"
const SFX_DIR   := "res://audio/sfx/"

const SFX_POOL_SIZE := 5

var _bgm:         AudioStreamPlayer
var _sfx_pool:    Array[AudioStreamPlayer] = []
var _cache:       Dictionary = {}   # path → AudioStream
var _current_bgm: String = ""

var music_volume_db: float = 0.0  :
	set(v):
		music_volume_db = v
		if _bgm: _bgm.volume_db = v

var sfx_volume_db: float = 0.0 :
	set(v):
		sfx_volume_db = v
		for p in _sfx_pool: p.volume_db = v

func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	for _i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

	_wire_signals()

func _wire_signals() -> void:
	if SatEconomy:
		SatEconomy.sats_changed.connect(func(_t, d):
			if d > 0: sfx("coin")
		)
		SatEconomy.sats_milestone_reached.connect(func(_m): sfx("milestone"))

	if AutonomyBar:
		AutonomyBar.resource_depleted.connect(func(_r): sfx("hit"))

	if RandomEventsSystem:
		RandomEventsSystem.event_triggered.connect(func(_e): sfx("event"))

	if WorldManager:
		WorldManager.region_changed.connect(func(_d, _n): sfx("victory"))

# ── API pública ──────────────────────────────────────────────────────────────

func music(track: String) -> void:
	if _current_bgm == track:
		return
	var path := MUSIC_DIR + track + ".ogg"
	var stream := _load(path)
	if stream == null:
		return
	_current_bgm = track
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_bgm.stream  = stream
	_bgm.play()

func stop_music() -> void:
	_current_bgm = ""
	_bgm.stop()

func sfx(name: String) -> void:
	var path  := SFX_DIR + name + ".ogg"
	var stream := _load(path)
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return

# ── Interno ──────────────────────────────────────────────────────────────────

func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_cache[path] = null
		return null
	var s: AudioStream = load(path)
	_cache[path] = s
	return s
