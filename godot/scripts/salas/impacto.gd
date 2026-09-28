class_name SalaImpacto
extends Sala
## O Impacto: dardos cruzam a sala pelas laterais. O dardo que vem da esquerda
## e acerta vibra só o motor esquerdo (o forte) daquele controle; o da direita,
## só o direito. A barra de luz é a vida: apaga conforme ela cai.

const RAIAS := [-4.5, -1.5, 1.5, 4.5]

var vida := [100.0, 100.0, 100.0, 100.0]
var dardos: Array = []  ## {no, vel, lugar, da_esquerda, vida}
var _proximo := 1.2
var _sorteio := RandomNumberGenerator.new()


func _init() -> void:
	id = "impacto"
	nome = "O Impacto"
	acao = "Desvie com o analógico. O lado do golpe treme."
	camera_pos = Vector3(0, 12.0, 11.0)
	camera_olhar = Vector3(0, 0, 0)


func montar() -> void:
	_sorteio.seed = Forja.semente + 17
	Kit.arena(self, 6, 3)
	luzes([Vector3(-10, 2.5, 0), Vector3(10, 2.5, 0), Vector3(0, 2.5, -6)])
	for p in jogadores:
		p.position = Vector3(RAIAS[p.lugar], 0.05, 0)
		p.rotation.y = PI
		p.controlavel = false
		Forja.gatilhos_off(p.lugar)


func status(lugar: int) -> String:
	return "vida %d" % int(vida[lugar])


func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		var mv := Forja.mover(p.lugar)
		p.position.z = clampf(p.position.z + mv.y * 5.0 * dt, -3.5, 3.5)
	_proximo -= dt
	if _proximo <= 0.0 and not jogadores.is_empty():
		_proximo = 1.35
		var alvo: ForjaPlayer = jogadores[_sorteio.randi() % jogadores.size()]
		_lancar(alvo, _sorteio.randf() < 0.5)
	var ficam: Array = []
	for d in dardos:
		d.no.position += d.vel * dt
		d.vida -= dt
		var alvo2: ForjaPlayer = jogador(d.lugar)
		if alvo2 and Vector2(alvo2.position.x - d.no.position.x, alvo2.position.z - d.no.position.z).length() < 0.6:
			_golpe(alvo2, d.da_esquerda)
			d.no.queue_free()
			continue
		if d.vida > 0.0:
			ficam.append(d)
		else:
			d.no.queue_free()
	dardos = ficam


func _lancar(alvo: ForjaPlayer, da_esquerda: bool) -> void:
	var n := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.6, 0.14, 0.14)
	n.mesh = caixa
	n.material_override = Kit.material(Tema.AMARELO, 2.5)
	n.position = Vector3(-13.0 if da_esquerda else 13.0, 1.0, alvo.position.z)
	add_child(n)
	dardos.append({"no": n, "vel": Vector3(11.0 if da_esquerda else -11.0, 0, 0), "lugar": alvo.lugar,
		"da_esquerda": da_esquerda, "vida": 2.6})


func _golpe(p: ForjaPlayer, da_esquerda: bool) -> void:
	var l := p.lugar
	vida[l] = maxf(0.0, vida[l] - 18.0)
	if da_esquerda:
		Forja.vibrar(l, 0.94, 0.0, 180)
	else:
		Forja.vibrar(l, 0.0, 0.94, 180)
	var k := clampf(vida[l] / 100.0, 0.08, 1.0)
	Forja.luz(l, Forja.cor_do_lugar(l) * k)
	p.gesto("die" if vida[l] <= 0.0 else "emote-no", 0.5)
	if vida[l] <= 0.0:
		vida[l] = 100.0
		Forja.luz_do_lugar(l)
