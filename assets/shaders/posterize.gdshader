// posterize.gdshader — post-process de posterização (reduz profundidade de cor).
// Uso: aplicar num ColorRect full-rect dentro de uma CanvasLayer por cima de tudo
// (mouse_filter = ignore). Funciona no renderizador GL Compatibility.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float levels = 24.0;   // níveis por canal; 24 ≈ sutil, 8 ≈ bem PS1

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	if (levels > 1.0) {
		col = floor(col * levels + 0.5) / levels;
	}
	COLOR = vec4(col, 1.0);
}
