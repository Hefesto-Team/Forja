class_name SalaProva
extends Sala
## A Prova: duas equipes (P1 e P3 contra P2 e P4) na arena da bigorna. O R2 é
## arma (o gatilho cede no ponto do disparo), o L2 resiste; quem leva o tiro
## treme, e a barra de luz de cada um cai com a vida.

var vida := [100.0, 100.0, 100.0, 100.0]
var tiros: Array = []  ## {no, vel, dono, vida}
var placar := [0, 0]
var _volta := [0.0, 0.0, 0.0, 0.0]


func _init() -> void:
	id = "prova"
	nome = "A Prova"
	acao = "P1 e P3 contra P2 e P4. R2 atira."
	camera_pos = Vector3(0, 15.0, 12.5)
	camera_olhar = Vector3(0, 0, 0.5)


func equipe(lugar: int) -> int:
	return lugar % 2


func montar() -> void:
	Kit.arena(self, 6, 4)
	luzes([Vector3(-10, 2.5, -6), Vector3(10, 2.5, -6), Vector3(-10, 2.5, 6), Vector3(10, 2.5, 6)])
	for c in [Vector3(-3, 0, -2), Vector3(3, 0, 2), Vector3(0, 0, -4.5), Vector3(0, 0, 4.5)]:
		Kit.peca(self, "column", c, 0.0, 2.2)
		Kit.solido(self, c + Vector3(0, 1.2, 0), Vector3(1.0, 2.4, 1.0))
	for p in jogadores:
		var l: int = p.lugar
		p.position = Vector3(-9.0 if equipe(l) == 0 else 9.0, 0.05, -2.5 if l < 2 else 2.5)
		p.controlavel = true
		p.olhar_para(Vector3.ZERO)
		Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
		Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 6)


func status(lugar: int) -> String:
	return "vida %d  ·  %d × %d" % [int(vida[lugar]), placar[0], placar[1]]


func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		var l: int = p.lugar
		if _volta[l] > 0.0:
			_volta[l] -= dt
			if _volta[l] <= 0.0:
				vida[l] = 100.0
				p.visible = true
				p.controlavel = true
				Forja.luz_do_lugar(l)
			continue
		# mira: o analógico direito, ou para onde anda
		var mira := Vector2(Forja.eixo(l, Forja.RX), Forja.eixo(l, Forja.RY))
		if mira.length() > 0.3:
			p.rotation.y = atan2(mira.x, mira.y)
		if Forja.eixo(l, Forja.R2) > 0.6 and p.cooldown <= 0.0:
			_atirar(p)
	_mover_tiros(dt)


func _atirar(p: ForjaPlayer) -> void:
	p.cooldown = 0.3
	var frente := Vector3(sin(p.rotation.y), 0, cos(p.rotation.y))
	var bala := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.13
	esfera.height = 0.26
	bala.mesh = esfera
	bala.material_override = Kit.material(Forja.cor_do_lugar(p.lugar), 3.0)
	bala.position = p.position + Vector3(0, 1.0, 0) + frente * 0.7
	add_child(bala)
	tiros.append({"no": bala, "vel": frente * 15.0, "dono": p.lugar, "vida": 1.4})
	Forja.vibrar(p.lugar, 0.12, 0.5, 70)


func _mover_tiros(dt: float) -> void:
	var ficam: Array = []
	for b in tiros:
		b.no.position += b.vel * dt
		b.vida -= dt
		var acertou := false
		for p in jogadores:
			var l: int = p.lugar
			if l == b.dono or equipe(l) == equipe(b.dono) or _volta[l] > 0.0:
				continue
			if Vector2(p.position.x - b.no.position.x, p.position.z - b.no.position.z).length() < 0.6:
				_ferir(p, b.dono)
				acertou = true
				break
		if acertou or b.vida <= 0.0:
			b.no.queue_free()
		else:
			ficam.append(b)
	tiros = ficam


func _ferir(p: ForjaPlayer, atirador: int) -> void:
	var l := p.lugar
	vida[l] = maxf(0.0, vida[l] - 22.0)
	Forja.vibrar(l, 0.63, 0.16, 160)
	Forja.luz(l, Forja.cor_do_lugar(l) * clampf(vida[l] / 100.0, 0.08, 1.0))
	if vida[l] <= 0.0:
		placar[equipe(atirador)] += 1
		p.gesto("die", 3.0)
		p.controlavel = false
		_volta[l] = 3.0
