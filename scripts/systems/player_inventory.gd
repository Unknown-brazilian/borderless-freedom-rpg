## player_inventory.gd
## Borderless Freedom: A Dissident Adventure
## AutoLoad: PlayerInventory
## Gerencia itens desbloqueados e item ativo (usado com double-tap).
##
## Desbloqueios (do GDD):
##   item_spray       — INICIAL
##   item_panfleto    — D1 completo
##   item_camera      — D1-F6 completo
##   item_chave       — D2 completo
##   item_radar_solar — D4-F3 completo
##   item_radio       — D4 completo
##   item_bomba_pneu  — D5-F3 completo

extends Node

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal item_unlocked(item_id: String)
signal active_item_changed(item_id: String)
signal item_activated(item_id: String)
signal item_ready  # fires when cooldown expires and item can be used again

# ─── Definições ───────────────────────────────────────────────────────────────
const ITEM_DEFS: Dictionary = {
	"item_spray":       {"name": "Spray Repelente",  "icon": "🧴", "desc": "Repele fiscais +25 água"},
	"item_panfleto":    {"name": "Panfleto",         "icon": "📄", "desc": "Confunde inimigos +8 sats"},
	"item_camera":      {"name": "Câmera",           "icon": "📸", "desc": "Denuncia corrupção +15 sats"},
	"item_chave":       {"name": "Chave de Bike",    "icon": "🔧", "desc": "Reparo rápido +20 energia"},
	"item_radio":       {"name": "Rádio Cripto",     "icon": "📻", "desc": "Chama aliado +20 sats"},
	"item_bomba_pneu":  {"name": "Bomba de Pneu",   "icon": "💣", "desc": "Burst de velocidade +30 energia +15 comida"},
	"item_radar_solar": {"name": "Radar Solar",      "icon": "🛰️", "desc": "Rota ótima detectada +20 comida"},
	"item_binoculo":    {"name": "Binóculos",        "icon": "🔭", "desc": "Revela os guardas no mapa"},
	"item_oculos_noturno": {"name": "Óculos Noturnos", "icon": "🕶️", "desc": "Ative para enxergar à noite"},
	"item_pneu":        {"name": "Pneu",             "icon": "🛞", "desc": "Peça pra remontar a bike"},
	"item_camara_ar":   {"name": "Câmara de Ar",     "icon": "⭕", "desc": "Peça pra remontar a bike"},
}

# ─── Estado ───────────────────────────────────────────────────────────────────
var unlocked:    Array[String] = []
var active_item: String        = ""

const ITEM_USE_COOLDOWN := 8.0
var _use_cooldown: float = 0.0

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	unlock_item("item_spray")

func _process(delta: float) -> void:
	if _use_cooldown > 0.0:
		_use_cooldown -= delta
		if _use_cooldown <= 0.0:
			_use_cooldown = 0.0
			emit_signal("item_ready")

# ─── API pública ──────────────────────────────────────────────────────────────

func unlock_item(item_id: String) -> void:
	if item_id not in ITEM_DEFS or item_id in unlocked:
		return
	unlocked.append(item_id)
	if active_item.is_empty():
		active_item = item_id
		emit_signal("active_item_changed", active_item)
	emit_signal("item_unlocked", item_id)

func cycle_next() -> void:
	if unlocked.size() <= 1:
		return
	var idx := unlocked.find(active_item)
	active_item = unlocked[(idx + 1) % unlocked.size()]
	emit_signal("active_item_changed", active_item)

func can_use_item() -> bool:
	return not active_item.is_empty() and _use_cooldown <= 0.0

func use_active_item() -> void:
	if not can_use_item():
		return
	_use_cooldown = ITEM_USE_COOLDOWN
	emit_signal("item_activated", active_item)
	_apply_passive_effect(active_item)

func get_active_icon() -> String:
	if active_item.is_empty():
		return "—"
	return ITEM_DEFS.get(active_item, {}).get("icon", "?")

func get_active_name() -> String:
	if active_item.is_empty():
		return "Sem item"
	return ITEM_DEFS.get(active_item, {}).get("name", active_item)

func reset() -> void:
	unlocked.clear()
	active_item = ""
	_use_cooldown = 0.0

## Reset para deportação — mantém apenas o spray (D7 começa sem equipamento).
func reset_for_deportation() -> void:
	unlocked.clear()
	active_item = ""
	_use_cooldown = 0.0
	unlock_item("item_spray")

# ─── Efeitos passivos imediatos ───────────────────────────────────────────────
func _apply_passive_effect(item_id: String) -> void:
	match item_id:
		"item_spray":
			# Repele fiscais — recupera água (esforço físico do spray)
			if AutonomyBar:
				AutonomyBar.restore("water", 25.0)
		"item_panfleto":
			# Confunde inimigos ideológicos — pequeno ganho de sats
			if SatEconomy:
				SatEconomy.add_sats(8, "item_panfleto_confusao")
		"item_camera":
			# Documenta corrupção — inimigos recuam, +sats de exposição
			if SatEconomy:
				SatEconomy.add_sats(15, "item_camera_denuncia")
		"item_chave":
			if AutonomyBar:
				AutonomyBar.restore("energy", 20.0)
		"item_radio":
			if SatEconomy:
				SatEconomy.add_sats(20, "item_radio_aliado")
		"item_bomba_pneu":
			# Destroi obstáculos — burst de energia
			if AutonomyBar:
				AutonomyBar.restore("energy", 30.0)
				AutonomyBar.restore("food", 15.0)
		"item_radar_solar":
			# Rota ótima detectada — economiza esforço físico
			if AutonomyBar:
				AutonomyBar.restore("food", 20.0)

# ─── Persistência ─────────────────────────────────────────────────────────────
func save() -> Dictionary:
	return {"unlocked": unlocked.duplicate(), "active": active_item}

func load_from(data: Dictionary) -> void:
	unlocked.clear()
	active_item = ""
	_use_cooldown = 0.0
	for raw in data.get("unlocked", []):
		var item_id := str(raw)
		if item_id in ITEM_DEFS and item_id not in unlocked:
			unlocked.append(item_id)
	var saved_active: String = data.get("active", "")
	if saved_active in unlocked:
		active_item = saved_active
	elif not unlocked.is_empty():
		active_item = unlocked[0]
	# Garante que o spray inicial sempre existe
	if "item_spray" not in unlocked:
		unlock_item("item_spray")
