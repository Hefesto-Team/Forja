class_name Efeitos
extends RefCounted
## Os efeitos que dizem "acertou" sem uma palavra: faíscas da forja e um anel
## que se abre. Cada um se desfaz sozinho.


static func _material_brilho(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = cor
	return m


## Faíscas: um estouro de `n` fagulhas em `pos`.
static func faiscas(pai: Node, pos: Vector3, cor: Color, n := 24, forca := 1.0) -> void:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = n
	p.lifetime = 0.75
	p.explosiveness = 1.0
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, 1, 0)
	m.spread = 75.0
	m.initial_velocity_min = 2.2 * forca
	m.initial_velocity_max = 5.0 * forca
	m.gravity = Vector3(0, -9.0, 0)
	m.scale_min = 0.6
	m.scale_max = 1.2
	var grad := Gradient.new()
	grad.set_color(0, Color(Tema.ETIQUETA.lerp(cor, 0.35), 1.0))
	grad.set_color(1, Color(cor, 0.0))
	var tg := GradientTexture1D.new()
	tg.gradient = grad
	m.color_ramp = tg
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	q.material = _material_brilho(Color.WHITE)
	p.draw_pass_1 = q
	pai.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


## Brasas que sobem devagar de uma área (a lava, o fogo da forja), sem parar.
static func brasas(pai: Node, centro: Vector3, tamanho: Vector3, cor: Color, n := 48) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = n
	p.lifetime = 3.2
	p.preprocess = 3.2
	p.visibility_aabb = AABB(-tamanho * 0.5 - Vector3(1, 1, 1), tamanho + Vector3(2, 7, 2))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = tamanho * 0.5
	m.direction = Vector3(0, 1, 0)
	m.spread = 18.0
	m.initial_velocity_min = 0.5
	m.initial_velocity_max = 1.3
	m.gravity = Vector3(0.12, 0.1, 0)
	m.scale_min = 0.4
	m.scale_max = 1.0
	var grad := Gradient.new()
	var clara := Tema.ETIQUETA.lerp(cor, 0.4)
	grad.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	grad.colors = PackedColorArray([Color(clara, 0.0), Color(clara, 1.0), Color(cor, 0.0)])
	var tg := GradientTexture1D.new()
	tg.gradient = grad
	m.color_ramp = tg
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	q.material = _material_brilho(Color.WHITE)
	p.draw_pass_1 = q
	p.position = centro
	pai.add_child(p)
	return p


## Um anel que se abre e some: o "pegou" de uma runa, de um sino, de um carimbo.
static func anel(pai: Node, pos: Vector3, cor: Color, raio := 0.6, virado_para := Vector3.BACK) -> void:
	var a := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.rings = 8
	t.ring_segments = 6
	t.inner_radius = raio * 0.86
	t.outer_radius = raio
	a.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = 2.0
	a.material_override = m
	pai.add_child(a)
	a.global_position = pos
	# o toro nasce deitado (no plano XZ): de pé, virado para a câmera
	if virado_para != Vector3.UP:
		a.rotation.x = PI * 0.5
	var tw := a.create_tween().set_parallel(true)
	tw.tween_property(a, "scale", Vector3.ONE * 2.2, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(a.queue_free)


## A poeira no ar: pontos de luz que flutuam devagar, sem cair (o clima da sala).
static func poeira(pai: Node, centro: Vector3, tamanho: Vector3, cor: Color, n := 40) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = n
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.visibility_aabb = AABB(-tamanho * 0.5 - Vector3(1, 1, 1), tamanho + Vector3(2, 2, 2))
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = tamanho * 0.5
	m.direction = Vector3(0.3, 0.2, 0)
	m.spread = 180.0
	m.initial_velocity_min = 0.05
	m.initial_velocity_max = 0.25
	m.gravity = Vector3.ZERO
	m.scale_min = 0.5
	m.scale_max = 1.2
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	grad.colors = PackedColorArray([Color(cor, 0.0), Color(cor, 0.8), Color(cor, 0.8), Color(cor, 0.0)])
	var tg := GradientTexture1D.new()
	tg.gradient = grad
	m.color_ramp = tg
	p.process_material = m
	var q := QuadMesh.new()
	q.size = Vector2(0.04, 0.04)
	q.material = _material_brilho(Color.WHITE)
	p.draw_pass_1 = q
	p.position = centro
	pai.add_child(p)
	return p
