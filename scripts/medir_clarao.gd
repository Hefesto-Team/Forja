extends SceneTree
## O clarão d'A Voz contra a regra do estudo 02 (item 29, a do WCAG 2.3.1):
## quanto da tela muda de luz entre o quadro de antes do susto e o do clarão.
## Um pixel conta quando a luminância relativa sobe ou desce 10% ou mais e o
## mais escuro dos dois está abaixo de 0,8 — a definição de "flash" do WCAG.
##
##   godot --headless -s scripts/medir_clarao.gd -- <antes.png> <clarão.png> [limite %]
##
## Diz a área em % da tela; com o limite (o estudo pede 20), sai com 1 se passa.


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 2:
		printerr("uso: godot --headless -s scripts/medir_clarao.gd -- <antes.png> <clarão.png> [limite %]")
		quit(2)
		return
	var antes := Image.load_from_file(a[0])
	var depois := Image.load_from_file(a[1])
	if antes == null or depois == null or antes.get_size() != depois.get_size():
		printerr("as duas fotos têm de existir e ter o mesmo tamanho")
		quit(2)
		return
	# meia resolução basta para a área, e anda quatro vezes mais depressa
	var tam := antes.get_size() / 2
	antes.resize(tam.x, tam.y, Image.INTERPOLATE_BILINEAR)
	depois.resize(tam.x, tam.y, Image.INTERPOLATE_BILINEAR)
	var n := 0
	for y in tam.y:
		for x in tam.x:
			var l1 := _luminancia(antes.get_pixel(x, y))
			var l2 := _luminancia(depois.get_pixel(x, y))
			if absf(l2 - l1) >= 0.1 and minf(l1, l2) < 0.8:
				n += 1
	var area := 100.0 * n / float(tam.x * tam.y)
	print("clarão: %.1f%% da tela muda de luz" % area)
	var limite := float(a[2]) if a.size() > 2 else -1.0
	quit(1 if limite >= 0.0 and area > limite else 0)


## A luminância relativa do WCAG (sRGB linearizado).
func _luminancia(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
