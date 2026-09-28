class_name SalaViga
extends Sala
## A Viga: cada jogador numa viga, virando o corpo com o giroscópio do próprio
## controle — girar o controle 90° gira o boneco 90°. Sem giroscópio, o
## analógico direito vira; empurrado até o fim, dá meia-volta.

const RAIAS := [-4.5, -1.5, 1.5, 4.5]

var yaw := [0.0, 0.0, 0.0, 0.0]
var usou_giro := [false, false, false, false]
var _flick := [false, false, false, false]


func _init() -> void:
	id = "viga"
	nome = "A Viga"
	acao = "Gire o controle: o boneco gira junto."
	camera_pos = Vector3(0, 9.5, 9.5)
	camera_olhar = Vector3(0, 0.5, 0)


func montar() -> void:
	Kit.arena(self, 5, 3)
	luzes([Vector3(-8, 2.5, -4), Vector3(8, 2.5, -4), Vector3(0, 2.5, 5)])
	for p in jogadores:
		var l: int = p.lugar
		var viga := CSGBox3D.new()
		viga.size = Vector3(1.2, 0.35, 5.0)
		viga.position = Vector3(RAIAS[l], 0.175, 0)
		viga.material = Kit.material(Color("#8a4b2a"), 0.0, 0.9)
		add_child(viga)
		p.position = Vector3(RAIAS[l], 0.4, 0)
		p.controlavel = false
		yaw[l] = PI
		p.rotation.y = PI
		Forja.gatilhos_off(l)


func status(lugar: int) -> String:
	var hz := Forja.giro_hz(lugar)
	if hz > 1.0:
		return "giroscópio %.0f Hz" % hz
	return "analógico direito"


func _process(dt: float) -> void:
	super(dt)
	for p in jogadores:
		var l: int = p.lugar
		var g := Forja.giro(l)
		if g.length() > 0.02:
			usou_giro[l] = true
		# o giro em torno do eixo vertical do controle (rad/s) vira o corpo
		yaw[l] += g.y * dt
		var rx := Forja.eixo(l, Forja.RX)
		if absf(rx) > 0.92 and not _flick[l]:
			_flick[l] = true
			yaw[l] += PI
			Forja.vibrar(l, 0.0, 0.7, 120)
		elif absf(rx) < 0.5:
			_flick[l] = false
		if absf(rx) > 0.2 and absf(rx) <= 0.92:
			yaw[l] -= rx * 2.4 * dt
		p.rotation.y = yaw[l]
