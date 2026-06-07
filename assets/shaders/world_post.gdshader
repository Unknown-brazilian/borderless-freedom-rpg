// world_post.gdshader — post-process do gameplay (color grade + vinheta + bloom).
// Lê o framebuffer já desenhado (mundo) e regrada. Aplicar num ColorRect full-rect
// numa CanvasLayer ACIMA do mundo e ABAIXO da HUD.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec3  grade_tint = vec3(1.0, 1.0, 1.0);
uniform float saturation = 1.0;
uniform float contrast   = 1.05;
uniform float brightness = 1.0;
uniform float vignette_strength = 0.4;
uniform float bloom_strength    = 0.5;
uniform float bloom_threshold   = 0.72;

vec3 sample_bloom(vec2 uv) {
	// SCREEN_PIXEL_SIZE não existe no GL Compatibility; derivamos do tamanho da textura.
	vec2 px = (1.0 / vec2(textureSize(screen_tex, 0))) * 2.0;
	vec3 sum = vec3(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec3 c = texture(screen_tex, uv + vec2(float(x), float(y)) * px).rgb;
			float b = max(max(c.r, c.g), c.b);
			sum += c * smoothstep(bloom_threshold, 1.0, b);
		}
	}
	return sum / 25.0;
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	// Bloom (brilho nas áreas claras — destaca o laranja do Bitcoin e sprites).
	col += sample_bloom(SCREEN_UV) * bloom_strength;

	// Brilho / contraste.
	col = (col - 0.5) * contrast + 0.5;
	col *= brightness;

	// Tinta de clima (warm/cold por dungeon).
	col *= grade_tint;

	// Saturação.
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);

	// Vinheta.
	float vig = smoothstep(1.0, 0.4, distance(SCREEN_UV, vec2(0.5)));
	col *= mix(1.0 - vignette_strength, 1.0, vig);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
