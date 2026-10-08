// O cavaleiro: a textura do colormap da Kenney (já recolorida) com o corpo
// tingido na cor do lugar pela luminância (o degradê do bloco fica, a cor é a
// do jogador), e um aro de luz (fresnel) na mesma cor nas faces de lado.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D textura : source_color, filter_nearest;
uniform vec4 tinta : source_color = vec4(1.0);
uniform float tingir = 0.0;
uniform vec4 aro_cor : source_color = vec4(1.0);
uniform float aro = 0.0;
uniform float aro_pot = 2.5;
uniform float brilho_proprio = 0.0;  // o corpo acende um pouco (a armadura é o instrumento)

void fragment() {
	vec3 c = texture(textura, UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 tingido = tinta.rgb * (0.42 + 0.85 * lum);
	vec3 base = mix(c, tingido, tingir);
	ALBEDO = base;
	ROUGHNESS = 0.92;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), aro_pot);
	EMISSION = aro_cor.rgb * f * aro + base * brilho_proprio;
}
