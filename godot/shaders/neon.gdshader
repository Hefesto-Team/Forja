shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

uniform vec4 cor : source_color = vec4(1.0);
uniform float energia = 2.0;

void fragment() {
	vec3 c = cor.rgb * energia;
	float m = max(c.r, max(c.g, c.b));
	ALBEDO = m > 1.0 ? c / m : c;
}
