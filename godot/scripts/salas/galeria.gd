class_name SalaGaleria
extends Sala
## A Galeria: cada jogador na sua raia, um alvo no fundo. O R2 atira e treme
## no dedo (Vibration, um dos quatro modos oficiais); o tiro sai no motor fraco
## de quem atirou, e só nele.

const RAIAS := [-4.5, -1.5, 1.5, 4.5]

var alvos := {}      ## lugar -> Node3D
var acertos := [0, 0, 0, 0]
var tiros: Array = []  ## {no, vel, dono, vida}


func _init() -> void:
	id = "galeria"
	nome = "A Galeria"
	acao = "R2 atira. Acerte o escudo da sua raia."
	camera_pos = Vector3(0, 11.5, 12.5)
	camera_olhar = Vector3(0, 0, -1.5)


func montar() -> void:
	Kit.arena(self, 5, 4)
	luzes([Vector3(-8, 2.5, -6), Vector3(8, 2.5, -6), Vector3(0, 2.5, 6)])
	for p in jogadores:
		var l: int = p.lugar
		p.position = Vector3(RAIAS[l], 0.05, 5.0)
		p.rotation.y = PI
		p.controlavel = false
		# a raia: uma faixa no chão na cor do lugar
		var faixa := CSGBox3D.new()
		faixa.size = Vector3(1.4, 0.02, 11.0)
		faixa.position = Vector3(RAIAS[l], 0.03, -0.3)
		faixa.material = Kit.material(Color(Forja.cor_do_lugar(l), 1.0).darkened(0.55), 0.35)
		add_child(faixa)
		# o alvo: um escudo num suporte de madeira
		var suporte := Kit.peca(self, "wood-support", Vector3(RAIAS[l], 0, -6.0), 0.0, 1.6)
		var escudo := Kit.peca(self, "shield-round", Vector3(RAIAS[l], 1.0, -5.85), 0.0, 3.0)
		alvos[l] = escudo
		suporte.name = "Suporte%d" % l
		Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, 0, 7, 32)
		Forja.gatilho(l, 0, Forja.GATILHO_OFF)


func status(lugar: int) -> String:
	return "acertos %d" % acertos[lugar]


func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		var l: int = p.lugar
		# o analógico mexe um pouco dentro da raia
		var mv := Forja.mover(l)
		p.position.x = clampf(p.position.x + mv.x * 3.0 * dt, RAIAS[l] - 0.5, RAIAS[l] + 0.5)
		if Forja.eixo(l, Forja.R2) > 0.55 and p.cooldown <= 0.0:
			_atirar(p)
	_mover_tiros(dt)
	for l in alvos:
		var a: Node3D = alvos[l]
		a.rotation.x = lerpf(a.rotation.x, 0.0, dt * 6.0)


func _atirar(p: ForjaPlayer) -> void:
	p.cooldown = 0.25
	p.gesto("holding-right-shoot", 0.25)
	Forja.vibrar(p.lugar, 0.0, 0.66, 90)
	var bala := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.12
	esfera.height = 0.24
	bala.mesh = esfera
	bala.material_override = Kit.material(Forja.cor_do_lugar(p.lugar), 3.0)
	bala.position = p.position + Vector3(0, 1.0, -0.6)
	add_child(bala)
	tiros.append({"no": bala, "vel": Vector3(0, 0, -18), "dono": p.lugar, "vida": 1.2})


func _mover_tiros(dt: float) -> void:
	var ficam: Array = []
	for b in tiros:
		b.no.position += b.vel * dt
		b.vida -= dt
		var alvo: Node3D = alvos.get(b.dono)
		if alvo and b.no.position.z <= alvo.position.z + 0.2:
			acertos[b.dono] += 1
			alvo.rotation.x = -0.6
			b.no.queue_free()
			continue
		if b.vida > 0.0:
			ficam.append(b)
		else:
			b.no.queue_free()
	tiros = ficam
