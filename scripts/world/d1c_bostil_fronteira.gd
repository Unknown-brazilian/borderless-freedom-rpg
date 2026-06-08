## d1c_bostil_fronteira.gd — Bostil, 3ª fase (Fronteira; chefe final de Bostil).
extends "res://scripts/world/world_map_base.gd"

func _ready() -> void:
	_player_start      = Vector2i(4, 44)
	_exit_tile         = Vector2i(4, 2)
	_boss_trigger_dist = 3
	_stretch           = 1.5
	super._ready()

func _setup_theme() -> void:
	_ground_tint = Color(1.0, 0.95, 0.78)

func _intro_dialogue() -> void:
	DialogueManager.start([
		"📍  %s — Bostil, Fronteira" % PlayerStats.player_name,
		"A saída do país está logo ali.",
		"Mas o bloqueio final do regime aguarda...",
	])

func _setup_npcs() -> void:
	spawn_campsite(Vector2i(3, 30))
	spawn_npc(Vector2i(7, 38), "Coiote",
		["Posso te passar pela fronteira... por uns sats.",
		 "Ou encare o bloqueio você mesmo.",
		 "Cada um escolhe seu risco."],
		Color(0.7, 0.5, 0.3))

func _setup_fiscais() -> void:
	spawn_patrol_enemy(Vector2i(5, 28), "Fiscal do Xandão", 45, 16, 20, 30, "item_camera", 3)

func _get_boss_id() -> String:
	return "BOSS-D1-FINAL"

func _get_boss_data() -> Dictionary:
	return {
		"name": "Lula, o Molusco",
		"hp": 120, "atk": 20, "reward_sats": 250, "bribe_cost": 999,
		"weakness_item": "item_camera", "is_boss": true, "boss_id": "BOSS-D1-FINAL",
		"speed": 52,
		"intro_lines": [
			"🚨  LULA, O MOLUSCO!",
			"\"Cobra em 3 moedas. Nenhuma delas válida.\"",
			"O bloqueio final de Bostil fecha a fronteira!",
			"Use a câmera para expô-lo.",
		],
		"victory_lines": [
			"🎉  BLOQUEIO DERRUBADO!",
			"A fronteira está aberta. Rumo à Bolivária.",
			"🔑  Desafio da seed antes de avançar...",
		],
	}
