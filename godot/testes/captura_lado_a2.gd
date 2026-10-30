extends "res://testes/captura_jogo.gd"


func _ready() -> void:
	super()
	roteiro = _roteiro_lado_a2()


func _process(dt: float) -> void:
	super(dt)
	if q % 300 == 0:
		print("estado=%s sala=%s fase=%s passo=%d" % [jogo.estado, jogo.sala.id if jogo.sala else "-", jogo.sala.fase if jogo.sala is SalaJogo else "-", _passo])


func _roteiro_lado_a2() -> Array:
	var fase := func(f: String, t: float) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == f and jogo.sala.t_fase >= t
	var p1 := func(cond: Callable) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == "jogo" and cond.call(jogo.sala, jogo.sala.j[0])
	var na_sala := func(cond: Callable) -> Callable:
		return func() -> bool:
			return jogo.sala is SalaJogo and jogo.sala.fase == "jogo" and cond.call(jogo.sala)
	var r: Array = []
	match OS.get_environment("SALA_ALVO"):
		"molde":
			r = [
				["ate", fase.call("aviso", 1.7)], ["foto", "molde_aviso"],
				["ate", p1.call(func(_s, e) -> bool: return e.passo == 0 and e.ponto >= 2)], ["foto", "molde_tracar"],
				["ate", p1.call(func(_s, e) -> bool: return e.passo == 1 and e.abertura > 0.3)], ["foto", "molde_abrir"],
				["ate", p1.call(func(s, e) -> bool: return e.passo == 2 and s._no_ponto(e))], ["foto", "molde_carimbar"],
				["ate", p1.call(func(_s, e) -> bool: return e.passo == 3)], ["espera", 20], ["foto", "molde_pronto"],
				["ate", fase.call("fim", 1.4)], ["foto", "molde_fim"],
			]
		"impacto":
			r = [
				["ate", fase.call("aviso", 1.7)], ["foto", "impacto_aviso"],
				["ate", na_sala.call(func(s) -> bool: return s.estado == SalaImpacto.GOLPE and s.t_estado > 0.25)], ["foto", "impacto_golpe"],
				["ate", na_sala.call(func(s) -> bool: return s.estado == SalaImpacto.VOANDO and s.t_estado > 0.22 and s.resposta == s.atual.y)],
				["foto", "impacto_escudo"],
				["ate", na_sala.call(func(s) -> bool: return s.i_plano >= 6)], ["foto", "impacto_meio"],
				["ate", fase.call("fim", 1.4)], ["foto", "impacto_fim"],
			]
		"galeria":
			r = [
				["ate", fase.call("aviso", 1.7)], ["foto", "galeria_aviso"],
				["ate", p1.call(func(_s, e) -> bool: return e.passo == SalaGaleria.REVELANDO and e.arma != SalaGaleria.NENHUMA and e.t > 0.5)],
				["foto", "galeria_revela"],
				["ate", p1.call(func(_s, e) -> bool: return e.passo == SalaGaleria.ATIRAR and e.t > 2.0)], ["foto", "galeria_tiro"],
				["ate", fase.call("fim", 1.4)], ["foto", "galeria_fim"],
			]
	r.append(["fim"])
	return r
