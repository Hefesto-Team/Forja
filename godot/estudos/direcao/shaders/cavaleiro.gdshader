shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D textura : source_color, filter_nearest;
uniform vec4 tinta : source_color = vec4(1.0);
uniform float tingir = 0.0;
uniform vec4 aro_cor : source_color = vec4(1.0);
uniform float aro = 0.0;
uniform float aro_pot = 2.5;
uniform float brilho_proprio = 0.0;
uniform float rugosidade = 0.9;
uniform float metalico = 0.0;
uniform vec4 pele : source_color = vec4(1.0);
uniform float pele_ativa = 0.0;
uniform vec4 pele_uv = vec4(0.6445, 0.7422, 1.0, 1.0);

void fragment() {
	vec3 c = texture(textura, UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	if (pele_ativa > 0.5 && UV.x >= pele_uv.x && UV.y >= pele_uv.y) {
		vec3 topo = texture(textura, vec2(UV.x, 0.7754)).rgb;
		float k = clamp(lum / max(dot(topo, vec3(0.299, 0.587, 0.114)), 0.05), 0.6, 1.0);
		c = pele.rgb * k;
	}
	vec3 tingido = tinta.rgb * (0.42 + 0.85 * lum);
	vec3 base = mix(c, tingido, tingir);
	ALBEDO = base;
	ROUGHNESS = rugosidade;
	METALLIC = metalico;
	SPECULAR = 0.3;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), aro_pot);
	EMISSION = aro_cor.rgb * f * aro + base * brilho_proprio;
}
