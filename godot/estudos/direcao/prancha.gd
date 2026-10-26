extends RefCounted

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")


static func folha(pai: Node, tamanho: Vector2i, fundo: Color = Fita.CASCO) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tamanho
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	pai.add_child(vp)
	var r := ColorRect.new()
	r.color = fundo
	r.position = Vector2.ZERO
	r.size = Vector2(tamanho)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(r)
	return vp


static func celula(pai: Node, tamanho: Vector2i, escala_2d := true) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tamanho
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if escala_2d:
		vp.size_2d_override = Vector2i(1920, 1080)
		vp.size_2d_override_stretch = true
	pai.add_child(vp)
	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	vp.add_child(cam)
	cam.current = true
	vp.set_meta("camera", cam)
	return vp


static func camera(vp: SubViewport) -> Camera3D:
	return vp.get_meta("camera")


static func lente(cam: Camera3D, mm: float) -> void:
	cam.fov = rad_to_deg(2.0 * atan(12.0 / mm))


static func pregar(folha_: SubViewport, vp: SubViewport, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = vp.get_texture()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folha_.add_child(t)
	return t


static func por_cima(folha_: SubViewport, f: Callable) -> Control:
	var t := Hud.Tela.new(f)
	t.position = Vector2.ZERO
	t.size = Vector2(folha_.size)
	folha_.add_child(t)
	return t


static func foto(folha_: SubViewport) -> Image:
	await RenderingServer.frame_post_draw
	return folha_.get_texture().get_image()
