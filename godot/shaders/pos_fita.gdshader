// O pós da fita, por cima do 3D (e, no erro, por cima de tudo): a varredura
// leve de tubo, a vinheta, o grão; e, só na Dissonância, a cor que desliza
// (aberração), as faixas que rasgam (a fita enroscada) e o desbotar.
shader_type canvas_item;

uniform sampler2D tela : hint_screen_texture, filter_linear;
uniform vec2 tamanho = vec2(1920.0, 1080.0);
uniform float varredura = 0.07;
uniform float passo_varredura = 3.0;
uniform float vinheta = 0.38;
uniform float grao = 0.018;
uniform float aberracao = 0.0;
uniform float rasgo = 0.0;
uniform float desbota = 0.0;
uniform float semente = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	// a fita enroscada: faixas horizontais que escorregam, e uma onda lenta
	float banda = floor(uv.y * 36.0);
	float h = hash(vec2(banda, semente));
	float desl = (h > 0.78 ? (h - 0.78) * 0.55 * sign(hash(vec2(semente, banda)) - 0.5) : 0.0);
	float fina = floor(uv.y * 180.0);
	desl += (hash(vec2(fina, semente + 3.0)) > 0.93 ? 0.012 : 0.0);
	desl += sin(uv.y * 19.0 + semente * 5.0) * 0.003;
	uv.x += desl * rasgo;
	vec2 ab = vec2(aberracao / tamanho.x, aberracao * 0.25 / tamanho.y);
	vec3 c;
	c.r = texture(tela, uv + ab).r;
	c.g = texture(tela, uv).g;
	c.b = texture(tela, uv - ab).b;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l) * vec3(0.92, 0.9, 1.05), desbota);
	float linha = 0.5 + 0.5 * cos(SCREEN_UV.y * tamanho.y * 6.2831853 / passo_varredura);
	c *= 1.0 - varredura * linha;
	vec2 v = (SCREEN_UV - 0.5) * vec2(1.0, 0.82);
	c *= 1.0 - vinheta * smoothstep(0.22, 0.78, length(v) * 1.3);
	c += (hash(SCREEN_UV * tamanho + semente) - 0.5) * grao;
	COLOR = vec4(c, 1.0);
}
