shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

uniform vec4 cor : source_color = vec4(1.0);
uniform float largura = 0.012;
uniform float energia = 2.4;
uniform bool normal_suave = true;

void vertex() {
	vec3 n = normal_suave ? normalize(TANGENT) : NORMAL;
	VERTEX += n * largura;
}

void fragment() {
	vec3 c = cor.rgb * energia;
	float m = max(c.r, max(c.g, c.b));
	ALBEDO = m > 1.0 ? c / m : c;
}
