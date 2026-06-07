// menu_bg.gdshader — fundo procedural animado para o menu.
// Gradiente quente + brilho suave subindo + grão sutil + vinheta.
// Canvas shader 2D (funciona no renderizador GL Compatibility).
shader_type canvas_item;

uniform vec4 col_top    : source_color = vec4(0.03, 0.03, 0.06, 1.0);
uniform vec4 col_bottom : source_color = vec4(0.15, 0.09, 0.03, 1.0);
uniform vec4 glow_col   : source_color = vec4(0.97, 0.58, 0.10, 1.0);
uniform float glow_strength = 0.45;
uniform float grain_strength = 0.04;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV;
	// Gradiente base (escuro topo -> quente embaixo).
	vec3 col = mix(col_top.rgb, col_bottom.rgb, pow(uv.y, 1.3));

	// Brilho suave animado, irradiando do meio-inferior.
	float t = TIME * 0.06;
	float n = noise(uv * 3.0 + vec2(t, t * 0.5));
	float d = distance(uv, vec2(0.5, 0.78));
	float glow = smoothstep(0.85, 0.15, d) * (0.55 + 0.45 * n);
	col += glow_col.rgb * glow * glow_strength;

	// Grão sutil animado.
	float g = noise(uv * vec2(640.0, 360.0) + vec2(TIME * 13.0, TIME * 7.0));
	col += (g - 0.5) * grain_strength;

	// Vinheta.
	float vig = smoothstep(1.0, 0.45, distance(uv, vec2(0.5, 0.5)));
	col *= mix(0.65, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
