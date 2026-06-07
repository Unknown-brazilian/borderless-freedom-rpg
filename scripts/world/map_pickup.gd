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
	# Cor por tipo (água=azul, comida=laranja, peça=cinza, item=dourado).
	match effect:
		"water":    pickup_color = Color(0.35, 0.65, 1.0)
		"food":     pickup_color = Color(1.0, 0.65, 0.2)
		"bikepart": pickup_color = Color(0.72, 0.72, 0.78)
	collision_layer = 0
	set_collision_mask_value(2, true)   # detecta o player (layer 2)
	monitoring = true
	add_to_group("map_pickup")

	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 30.0
	shape.shape = circ
	add_child(shape)

	# Visual: marcador colorido (robusto, sem depender de glifo de emoji) + brilho.
	var halo := ColorRect.new()
	halo.size = Vector2(34, 34)
	halo.position = Vector2(-17, -34)
	halo.color = Color(pickup_color.r, pickup_color.g, pickup_color.b, 0.35)
	add_child(halo)
	var dot := ColorRect.new()
	dot.size = Vector2(20, 20)
	dot.position = Vector2(-10, -27)
	dot.color = pickup_color
	add_child(dot)
	# pulsinho pra chamar atenção
	var t := create_tween().set_loops()
	t.tween_property(dot, "position:y", -35.0, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(dot, "position:y", -27.0, 0.6).set_trans(Tween.TRANS_SINE)

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
	Juice.float_text(get_tree().current_scene, global_position, msg, pickup_color, 34)
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
