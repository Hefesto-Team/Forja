// Um néon que trabalha: chapado, a energia acima de 1 para o glow pegar.
shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

uniform vec4 cor : source_color = vec4(1.0);
uniform float energia = 2.0;

void fragment() {
	// o matiz não pode estourar: o canal mais forte para em 1 (acima disso o
	// tonemap leva o âmbar e o limão para o mesmo amarelo); o resto da energia
	// clareia por igual, só no que é quase branco
	vec3 c = cor.rgb * energia;
	float m = max(c.r, max(c.g, c.b));
	ALBEDO = m > 1.0 ? c / m : c;
}
