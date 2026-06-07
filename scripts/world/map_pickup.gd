## map_pickup.gd
## Item colecionável no mapa — o player pega ao passar por cima.
## Concede o item ao PlayerInventory (unlocked) e some, com toast + som.
extends Area2D

@export var item_id: String = ""      # ex.: "item_binoculo"
@export var icon:    String = "❓"     # emoji exibido no mapa
@export var label_text: String = ""   # mensagem do toast (ex.: "Binóculos!")
@export var pickup_color: Color = Color(1, 0.9, 0.3)
## "unlock" (item de inventário) | "water" | "food" | "energy" | "bikepart"
@export var effect: String = "unlock"
@export var amount: float = 40.0      # quanto restaura (water/food/energy)

var _taken: bool = false

func _ready() -> void:
	collision_layer = 0
	set_collision_mask_value(2, true)   # detecta o player (layer 2)
	monitoring = true
	add_to_group("map_pickup")

	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 30.0
	shape.shape = circ
	add_child(shape)

	var lbl := Label.new()
	lbl.text = icon
	lbl.position = Vector2(-16, -22)
	lbl.add_theme_font_size_override("font_size", 32)
	add_child(lbl)
	# pulsinho pra chamar atenção
	var t := create_tween().set_loops()
	t.tween_property(lbl, "position:y", -30.0, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "position:y", -22.0, 0.6).set_trans(Tween.TRANS_SINE)

	# Já pegou antes? (persistente por item único)
	if item_id != "" and item_id in PlayerInventory.unlocked:
		queue_free()
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	match effect:
		"water", "food", "energy":
			AutonomyBar.restore(effect, amount)
		"bikepart":
			if item_id != "":
				PlayerInventory.unlock_item(item_id)
			_try_rebuild_bike()
		_:
			if item_id != "":
				PlayerInventory.unlock_item(item_id)
	AudioManager.sfx("coin")
	var msg := label_text if label_text != "" else "Item obtido"
	Juice.float_text(get_tree().current_scene, global_position, "%s %s" % [icon, msg], pickup_color, 34)
	queue_free()

## Com pneu + câmara de ar, o player remonta uma bicicleta (se estiver sem).
func _try_rebuild_bike() -> void:
	if PlayerCustomization.bike_index > 0:
		return
	if "item_pneu" in PlayerInventory.unlocked and "item_camara_ar" in PlayerInventory.unlocked:
		PlayerCustomization.bike_index = 1   # Urbana
		var p := get_tree().get_first_node_in_group("player")
		if is_instance_valid(p):
			PlayerCustomization.apply(p)
		DialogueManager.start(["🚲  Com pneu e câmara de ar, você remontou uma bicicleta!"])
