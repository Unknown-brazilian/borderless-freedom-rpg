// scanlines.gdshader — sobreposição CRT sutil (linhas escuras horizontais).
// Aplicar num ColorRect full-rect por cima de tudo, mouse_filter = ignore.
shader_type canvas_item;

uniform float strength = 0.07;   // intensidade das linhas
uniform float lines    = 320.0;  // densidade

void fragment() {
	float s = sin(UV.y * lines * 3.14159265) * 0.5 + 0.5;
	float a = strength * (1.0 - s);
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
