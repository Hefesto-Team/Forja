extends RefCounted
## A prancha: uma folha 2D do tamanho que o item pede (maior que a tela, se
## for preciso), com células 3D pregadas nela. Cada célula é um mundo próprio
## (a câmera, a luz, a névoa e o pós dela), renderizado numa SubViewport; a
## folha junta tudo e o estudo fotografa a folha, não a janela.

const Fita := preload("res://estudos/direcao/fita.gd")
const Hud := preload("res://estudos/direcao/hud.gd")


## A folha: o fundo, as células por baixo e o texto por cima.
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


## Uma célula 3D de `tamanho` px na folha. O 2D dela (o HUD, o pós) desenha
## em px da tela lógica de 1920×1080, encolhido para a célula, como o jogo
## faz com a janela.
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


## A câmera de uma célula pela lente (mm, em 35 mm: a altura do quadro é 24 mm).
static func lente(cam: Camera3D, mm: float) -> void:
	cam.fov = rad_to_deg(2.0 * atan(12.0 / mm))


## Prega a imagem de uma célula na folha, em `r` (encolhe se o tamanho difere).
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


## O texto e as marcas por cima de tudo, em px da folha.
static func por_cima(folha_: SubViewport, f: Callable) -> Control:
	var t := Hud.Tela.new(f)
	t.position = Vector2.ZERO
	t.size = Vector2(folha_.size)
	folha_.add_child(t)
	return t


## A foto da folha, depois de a folha ter sido desenhada.
static func foto(folha_: SubViewport) -> Image:
	await RenderingServer.frame_post_draw
	return folha_.get_texture().get_image()
