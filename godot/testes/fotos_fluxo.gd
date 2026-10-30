extends "res://testes/captura_jogo.gd"


func _ready() -> void:
	super._ready()
	roteiro = _roteiro_do_fluxo()


func _roteiro_do_fluxo() -> Array:
	var sala_em := func(f: String, t: float) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == f and jogo.sala.t_fase >= t
	var no_salao := func() -> bool:
		return jogo.estado == "salao" and not jogo._trocando
	var quem := int(OS.get_environment("JOGADORES")) if OS.get_environment("JOGADORES") != "" else 4
	var id := OS.get_environment("SALA") if OS.get_environment("SALA") != "" else "centelha"
	var r: Array = [
		["espera", 70], ["aperta", 0, Forja.CRUZ], ["espera", 60],
		["ate", func() -> bool: return jogo.estado == "intro" and jogo.intro.t > 1.0], ["aperta", 0, Forja.CRUZ], ["espera", 40],
	]
	for l in range(1, quem):
		r.append_array([["aperta", l, Forja.CRUZ], ["espera", 12]])
	var gira: Array = [Forja.DIREITA, Forja.BAIXO, Forja.ESQUERDA]
	for l in range(1, quem):
		r.append(["aperta", l, gira[l - 1]])
	r.append_array([["espera", 30], ["aperta", 0, Forja.CRUZ], ["espera", 30], ["aperta", 0, Forja.CRUZ], ["espera", 30],
		["aperta", 0, Forja.CRUZ], ["espera", 30]])
	for l in quem:
		r.append(["ate_pronto", l])
	r.append_array([["ate", no_salao], ["espera", 150], ["foto", "salao"],
		["posiciona", 0, Vector3(-2.0, 0.05, 3.0), PI], ["posiciona", 1, Vector3(0.6, 0.05, 2.0), PI],
		["posiciona", 2, Vector3(2.6, 0.05, 3.2), PI], ["espera", 40], ["foto", "salao_perto"],
		["posiciona", 0, Vector3(-3.0, 0.05, -4.0), PI], ["posiciona", 1, Vector3(3.0, 0.05, -4.0), PI],
		["posiciona", 2, Vector3(-9.0, 0.05, 3.0), PI], ["posiciona", 3, Vector3(8.0, 0.05, 1.0), PI], ["espera", 60],
		["foto", "salao_largo"],
		["sala_cortina", id], ["ate", sala_em.call("aviso", 0.3)], ["foto", id + "_entrada_0"],
		["ate", sala_em.call("aviso", 1.8)], ["foto", id + "_entrada"],
		["ate", sala_em.call("jogo", 0.8)], ["foto", id + "_jogo_0"],
		["ate", sala_em.call("jogo", 4.0)], ["foto", id + "_jogo"],
		["aperta", 0, Forja.OPTIONS], ["espera", 20], ["foto", id + "_pausa"], ["aperta", 0, Forja.OPTIONS], ["espera", 10],
		["termina"], ["ate", func() -> bool: return jogo.resultado.visible and jogo.resultado._t > 1.0], ["foto", id + "_fim"],
		["fim"]])
	return r
