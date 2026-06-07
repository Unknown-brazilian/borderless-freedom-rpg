// ps1_vertex_snap.gdshader — efeito PS1 de "wobble" geométrico (snap de vértices).
// Snapa os vértices a uma grade de baixa resolução, como o PS1 (sem subpixel).
// shader_type spatial — aplicar via ShaderMaterial em MeshInstance3D.
//
// NOTA: o jogo atual é 2D top-down (estilo GB/SNES) e NÃO tem malhas 3D, então
// este shader fica como recurso pronto para uso futuro (caso entre conteúdo 3D).
// Roda no renderizador GL Compatibility.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float snap_strength = 64.0;        // quanto maior, mais "preso" à grade
uniform sampler2D albedo : source_color, filter_nearest;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// Snap em espaço de clipe (dividido por w) para reproduzir o jitter do PS1.
	clip.xyz /= clip.w;
	clip.xy = floor(clip.xy * snap_strength) / snap_strength;
	clip.xyz *= clip.w;
	POSITION = clip;
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}
