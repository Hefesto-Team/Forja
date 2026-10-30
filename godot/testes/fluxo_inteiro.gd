extends "res://testes/captura_jogo.gd"


func _ready() -> void:
	super._ready()
	roteiro = _roteiro_inteiro()


func _roteiro_inteiro() -> Array:
	var quem := clampi(int(OS.get_environment("JOGADORES")), 1, Forja.simular) if OS.get_environment("JOGADORES") != "" else Forja.simular
	var id := OS.get_environment("SALA") if OS.get_environment("SALA") != "" else "centelha"
	var no_salao := func() -> bool:
		return jogo.estado == "salao" and not jogo._trocando
	var na_sala := func(f: String, t: float) -> Callable:
		return func() -> bool:
			return jogo.estado == "sala" and jogo.sala is SalaJogo and jogo.sala.fase == f and jogo.sala.t_fase >= t
	var r: Array = [
		["espera", 70], ["foto", "1_titulo"], ["aperta", 0, Forja.CRUZ],
		["exige", func() -> bool: return jogo.estado == "intro" and jogo.intro.t > 1.0, "a intro", 3000],
		["aperta", 0, Forja.CRUZ],
		["exige", func() -> bool: return jogo.estado == "lobby" and not jogo._trocando, "a montagem", 3000],
		["espera", 40],
	]
	for l in range(1, quem):
		r.append_array([["aperta", l, Forja.CRUZ], ["espera", 12]])
	r.append(["foto", "2_montagem"])
	for l in quem:
		r.append(["ate_pronto", l])
	r.append_array([
		["exige", no_salao, "o salão", 6000], ["espera", 90], ["foto", "3_salao"],
		["ao_portao", 0, id], ["espera", 30],
		["exige", func() -> bool: return jogo._portao_perto == id, "o portão de " + id, 300], ["foto", "4_portao"],
		["aperta", 0, Forja.CRUZ],
		["exige", na_sala.call("aviso", 0.3), "a sala", 1500], ["foto", "5_sala"],
		["exige", na_sala.call("jogo", 3.0), "o jogo", 3000], ["foto", "6_jogo"],
		["exige", func() -> bool: return na_sala.call("fim", 0.0).call() and jogo.resultado.visible and jogo.resultado._t > 1.0,
			"o resultado", 30000],
		["foto", "7_resultado"],
		["exige", func() -> bool: return jogo.estado != "sala" or jogo.sala.t_fase >= jogo.sala.fim_da_cena() + 0.9, "o ✕ do resultado", 3000],
		["aperta", 0, Forja.CRUZ],
		["exige", no_salao, "a volta ao salão", 1500], ["espera", 60], ["foto", "8_salao_de_volta"],
		["exige", func() -> bool: return true, "o fim com %d jogador(es)" % quem, 1],
		["fim"],
	])
	return r
