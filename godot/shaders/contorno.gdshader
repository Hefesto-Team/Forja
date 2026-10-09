// O contorno de néon: o casco invertido. A malha cresce pela normal suavizada
// (gravada no TANGENT por Mundo.suavizar, porque os blocos da Kenney têm a
// normal partida em cada face e o casco abriria nos cantos), desenha só as
// costas e sai chapada, com energia acima de 1 para o glow pegar.
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
	// o matiz não pode estourar: o canal mais forte para em 1 (acima disso o
	// tonemap leva o âmbar e o limão para o mesmo amarelo); o resto da energia
	// clareia por igual, só no que é quase branco
	vec3 c = cor.rgb * energia;
	float m = max(c.r, max(c.g, c.b));
	ALBEDO = m > 1.0 ? c / m : c;
}
