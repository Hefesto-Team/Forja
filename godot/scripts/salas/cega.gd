class_name Cega
extends RefCounted
## As respostas de uma prova às cegas: as certas, as erradas (e o que a pessoa
## disse em cada uma) e as perdidas (não respondeu a tempo). A sala só guarda;
## o veredito sai da régua do núcleo (Forja.cega_veredito, cegas.c).


static func nova() -> Dictionary:
	return {"certos": 0, "errados": 0, "perdidos": 0, "como": [0, 0, 0, 0, 0, 0, 0, 0]}


static func certo(c: Dictionary) -> void:
	c.certos = int(c.certos) + 1


static func errado(c: Dictionary, disse: int) -> void:
	c.errados = int(c.errados) + 1
	if disse >= 0 and disse < 8:
		c.como[disse] = int(c.como[disse]) + 1


static func perdido(c: Dictionary) -> void:
	c.perdidos = int(c.perdidos) + 1


static func total(c: Dictionary) -> int:
	return int(c.certos) + int(c.errados) + int(c.perdidos)


## Duas provas somadas (os golpes da esquerda e da direita, por exemplo).
static func somar(a: Dictionary, b: Dictionary) -> Dictionary:
	var s := nova()
	for k in ["certos", "errados", "perdidos"]:
		s[k] = int(a[k]) + int(b[k])
	for i in 8:
		s.como[i] = int(a.como[i]) + int(b.como[i])
	return s
