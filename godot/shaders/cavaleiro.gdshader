// O cavaleiro (arte/04, a peça se distingue): a cor é a da peça, já
// recolorida pela faixa da parte; o néon do dono é só acento (o friso, a
// costura) e o aro de luz fraco. COLOR.r: 0 superior, 1 inferior. UV2: a
// posição de repouso (x, y) do vértice, para a faixa do acento não andar.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D textura_cima : source_color, filter_nearest;
uniform sampler2D textura_baixo : source_color, filter_nearest;
uniform vec4 dono : source_color = vec4(1.0);
uniform float aro = 0.25;
uniform float aro_pot = 2.5;
uniform float rugoso_cima = 0.85;
uniform float rugoso_baixo = 0.70;
uniform float metal = 0.0;            // 0,2 no autômato e no item; o acabamento (G02, G06) escreve
uniform vec4 pele : source_color = vec4(1.0);
uniform float pele_ativa = 0.0;       // 1 numa raça: a pele do colormap vira a pele dela
uniform vec4 pele_uv = vec4(0.6445, 0.7422, 1.0, 1.0);  // Pintura.PELE_UV: x0, y0, x1, y1
uniform float acento = 1.6;          // 2,6 no encaixe
uniform float friso_y0 = 0.0;        // o y mais baixo do torso, em repouso
uniform float friso_y1 = 0.0;        // a gola: min(y mais alto do torso, 0.343)
uniform float friso_alto = 0.010;
uniform float costura_x = 0.0;       // o |x| mais de fora da perna
uniform float costura_larg = 0.008;
uniform bool tem_acento = true;
uniform vec4 apagado : source_color = vec4(0.227, 0.200, 0.275, 1.0); // Tema.GRAFITE #3a3346 (o _vestir põe o token)
uniform float acesa = 1.0;            // 0: a armadura apagada da introdução (G01)

varying float baixo;
varying vec2 repouso;

void vertex() {
	baixo = COLOR.r;
	repouso = UV2;
}

void fragment() {
	vec3 c = baixo > 0.5 ? texture(textura_baixo, UV).rgb : texture(textura_cima, UV).rgb;
	if (pele_ativa > 0.5 && UV.x >= pele_uv.x && UV.y >= pele_uv.y) {
		// a rampa de pele desce do alto da coluna: o degradê é a razão
		vec2 alto = vec2(UV.x, 0.7754);
		vec3 topo = baixo > 0.5 ? texture(textura_baixo, alto).rgb : texture(textura_cima, alto).rgb;
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		float k = clamp(lum / max(dot(topo, vec3(0.299, 0.587, 0.114)), 0.05), 0.6, 1.0);
		c = pele.rgb * k;
	}
	ALBEDO = c;
	ROUGHNESS = baixo > 0.5 ? rugoso_baixo : rugoso_cima;
	METALLIC = metal;
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), aro_pot);
	EMISSION = dono.rgb * f * aro;
	bool friso = baixo < 0.5 && repouso.y >= friso_y0 - 0.0001
		&& (repouso.y <= friso_y0 + friso_alto || repouso.y >= friso_y1 - friso_alto);
	bool costura = baixo > 0.5 && abs(repouso.x) >= costura_x - costura_larg;
	if (tem_acento && (friso || costura)) {
		vec3 n = dono.rgb * acento;
		float m = max(n.r, max(n.g, n.b));
		ALBEDO = m > 1.0 ? n / m : n;
		EMISSION = dono.rgb * acento;
	}
	// apagada (acesa 0): o corpo em GRAFITE, sem acento e sem aro
	ALBEDO = mix(apagado.rgb, ALBEDO, acesa);
	EMISSION *= acesa;
}
