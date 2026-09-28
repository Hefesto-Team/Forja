class_name SalaVoz
extends Sala
## A Voz: falar no microfone ergue a coluna de brasa do meio. O botão do mudo
## de cada controle acende e apaga o LED dele (o laranja do mudo).
##
## Neste marco o microfone é o padrão do sistema; o microfone de cada controle,
## achado pelo aparelho, chega no marco do áudio.

var microfone: MicrofoneDoControle
var coluna: MeshInstance3D
var mudo := [false, false, false, false]
var nivel := 0.0


func _init() -> void:
	id = "voz"
	nome = "A Voz"
	acao = "Fale no controle. O botão do mudo acende o LED."
	camera_pos = Vector3(0, 9.0, 11.0)
	camera_olhar = Vector3(0, 1.2, 0)


func montar() -> void:
	Kit.arena(self, 4, 3)
	luzes([Vector3(-7, 2.5, -4), Vector3(7, 2.5, -4)])
	microfone = MicrofoneDoControle.new()
	add_child(microfone)
	microfone.ligar()
	coluna = MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.45
	c.bottom_radius = 0.6
	c.height = 1.0
	coluna.mesh = c
	coluna.material_override = Kit.material(Tema.LARANJA, 2.0)
	coluna.position = Vector3(0, 0.5, -1.5)
	add_child(coluna)
	var i := 0
	for p in jogadores:
		p.position = Vector3(-3.0 + i * 2.0, 0.05, 2.5)
		p.rotation.y = PI
		p.controlavel = false
		Forja.led_mic(p.lugar, 0)
		i += 1


func sair() -> void:
	if microfone:
		microfone.desligar()
	super()


func status(lugar: int) -> String:
	return "mudo" if mudo[lugar] else "microfone aberto"


func _process(dt: float) -> void:
	super(dt)
	if microfone and microfone.ligado:
		var alvo := clampf((microfone.ultimo_db + 60.0) / 50.0, 0.0, 1.0)
		nivel = lerpf(nivel, alvo, minf(1.0, dt * 10.0))
	var altura := 0.3 + nivel * 4.0
	coluna.scale = Vector3(1, altura, 1)
	coluna.position.y = altura * 0.5
	for p in jogadores:
		if Forja.apertou(p.lugar, Forja.MICROFONE):
			mudo[p.lugar] = not mudo[p.lugar]
			Forja.led_mic(p.lugar, 1 if mudo[p.lugar] else 0)
