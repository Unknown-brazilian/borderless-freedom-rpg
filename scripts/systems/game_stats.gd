## game_stats.gd — RPG
## Estatísticas globais da jornada — adaptado para o modo RPG.

extends Node

signal stats_updated

var dungeons_completed: int = 0
var bosses_defeated:    int = 0
var fiscais_pagos:      int = 0
var npcs_conversations: int = 0
var steps_walked:       int = 0
var battles_won:        int = 0
var battles_fled:       int = 0

const STEPS_PER_KM := 15   # ~15 tiles = 1 km fictício

func get_kms_pedalados() -> int:
	return steps_walked / STEPS_PER_KM

func get_dias_de_viagem() -> int:
	return maxi(1, get_kms_pedalados() / 75)

func record_dungeon_complete(dungeon: int) -> void:
	dungeons_completed += 1
	emit_signal("stats_updated")

func record_boss_defeated() -> void:
	bosses_defeated += 1
	emit_signal("stats_updated")

func record_fiscal() -> void:
	fiscais_pagos += 1

func record_step() -> void:
	steps_walked += 1

func record_battle_won() -> void:
	battles_won += 1

func record_battle_fled() -> void:
	battles_fled += 1

func record_conversation() -> void:
	npcs_conversations += 1

func reset() -> void:
	dungeons_completed = 0
	bosses_defeated    = 0
	fiscais_pagos      = 0
	npcs_conversations = 0
	steps_walked       = 0
	battles_won        = 0
	battles_fled       = 0

func save() -> Dictionary:
	return {
		"dungeons": dungeons_completed,
		"bosses":   bosses_defeated,
		"fiscais":  fiscais_pagos,
		"convs":    npcs_conversations,
		"steps":    steps_walked,
		"battles_won": battles_won,
		"battles_fled": battles_fled,
	}

func load_from(data: Dictionary) -> void:
	dungeons_completed = data.get("dungeons", 0)
	bosses_defeated    = data.get("bosses", 0)
	fiscais_pagos      = data.get("fiscais", 0)
	npcs_conversations = data.get("convs", 0)
	steps_walked       = data.get("steps", 0)
	battles_won        = data.get("battles_won", 0)
	battles_fled       = data.get("battles_fled", 0)
