// O teste de 64 px do 04: modo 0, a imagem em cinza pela L do OKLab (a luz
// que o olho vê); modo 1, a silhueta em preto chapado sobre o papel.
shader_type canvas_item;

uniform int modo = 0;
uniform vec4 papel : source_color = vec4(0.937, 0.894, 0.784, 1.0);

float lin(float v) {
	return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (modo == 1) {
		COLOR = c.a > 0.5 ? vec4(0.0, 0.0, 0.0, 1.0) : papel;
	} else {
		vec3 l3 = vec3(lin(c.r), lin(c.g), lin(c.b));
		float l = pow(0.4122214708 * l3.r + 0.5363325363 * l3.g + 0.0514459929 * l3.b, 1.0 / 3.0);
		float m = pow(0.2119034982 * l3.r + 0.6806995451 * l3.g + 0.1073969566 * l3.b, 1.0 / 3.0);
		float s = pow(0.0883024619 * l3.r + 0.2817188376 * l3.g + 0.6299787005 * l3.b, 1.0 / 3.0);
		float L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
		// a L do OKLab mostrada como cinza: o L é a luz percebida, então o
		// cinza de sRGB com a mesma L é L ao cubo, em linear
		float g = pow(L, 3.0);
		g = g <= 0.0031308 ? g * 12.92 : 1.055 * pow(g, 1.0 / 2.4) - 0.055;
		COLOR = vec4(vec3(g), c.a);
	}
}
