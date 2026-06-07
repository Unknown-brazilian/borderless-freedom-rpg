## bike_sprite.gd — desenha uma bicicleta simples sob o player (sem asset de arte).
extends Node2D

@export var color: Color = Color(0.20, 0.20, 0.25)
@export var electric: bool = false   # bike elétrica: detalhe amarelo + raio

func _draw() -> void:
	var w := 3.0
	var lw := Vector2(-13, 4)   # centro roda esquerda
	var rw := Vector2(13, 4)    # centro roda direita
	var r := 11.0
	# Rodas
	draw_arc(lw, r, 0.0, TAU, 24, color, w)
	draw_arc(rw, r, 0.0, TAU, 24, color, w)
	# Quadro (triângulo) + selim + guidão
	var bb := Vector2(0, 4)        # movimento central
	var seat := Vector2(-6, -12)
	var head := Vector2(10, -12)
	draw_line(lw, bb, color, w)
	draw_line(rw, head, color, w)
	draw_line(bb, seat, color, w)
	draw_line(bb, head, color, w)
	draw_line(seat, head, color, w)
	draw_line(seat, Vector2(-10, -12), color, w)        # selim
	draw_line(head, Vector2(14, -16), color, w)         # guidão
	if electric:
		draw_circle(bb, 4.0, Color(0.95, 0.85, 0.2))    # bateria/motor
