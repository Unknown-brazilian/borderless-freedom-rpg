## npc.gd
## Classe base para todos os NPCs do mapa.
## Responde a on_interact() e exibe diálogos.

extends CharacterBody2D

signal first_interact(npc: Node)

@export var npc_name:    String = "NPC"
@export var sprite_color: Color = Color(0.6, 0.6, 0.8)
@export var lines:       Array[String] = ["..."]
@export var face_direction: Vector2 = Vector2.DOWN   # direção inicial do NPC

var _sprite: ColorRect = null
var _interacted_once: bool = false

func _ready() -> void:
	add_to_group("npc")
	set_collision_layer_value(3, true)
	set_collision_mask_value(0, false)
	_create_sprite()

@export var sprite_texture_path: String = ""   # path para PNG, ex: "res://assets/sprites/npc_ally.png"

func _create_sprite() -> void:
	# Tenta PNG custom; fallback para ColorRect colorido
	if not sprite_texture_path.is_empty():
		var img := Image.load_from_file(sprite_texture_path)
		if img:
			var spr := Sprite2D.new()
			spr.texture = ImageTexture.create_from_image(img)
			spr.scale   = Vector2(2.0, 2.0)
			spr.position = Vector2(0, -20)
			add_child(spr)
			_sprite = null   # sem ColorRect
			var lbl := Label.new()
			lbl.text = npc_name
			lbl.position = Vector2(-40, -52)
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			add_child(lbl)
			return
	# Fallback
	_sprite = ColorRect.new()
	_sprite.size = Vector2(48, 48)
	_sprite.position = Vector2(-24, -40)
	_sprite.color = sprite_color
	add_child(_sprite)
	var lbl := Label.new()
	lbl.text = npc_name
	lbl.position = Vector2(-40, -70)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)

func on_interact(_player: Node) -> void:
	if DialogueManager.is_active() or _interacted_once:
		if DialogueManager.is_active():
			DialogueManager.advance()
		return
	_face_player(_player)
	var dialogue_lines := _get_dialogue_lines()
	DialogueManager.start_with_speakers(dialogue_lines, _get_speakers())
	if not _interacted_once:
		_interacted_once = true
		emit_signal("first_interact", self)
		_on_first_interact()

func _get_dialogue_lines() -> Array[String]:
	var result: Array[String] = []
	result.assign(lines)
	return result

func _get_speakers() -> Array[String]:
	var result: Array[String] = []
	for _l in lines:
		result.append(npc_name)
	return result

func _on_first_interact() -> void:
	pass   # override em subclasses

func _face_player(player: Node) -> void:
	if not player:
		return
	var diff: Vector2 = player.position - position
	if abs(diff.x) > abs(diff.y):
		face_direction = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	else:
		face_direction = Vector2.DOWN if diff.y > 0 else Vector2.UP
