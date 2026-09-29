extends SceneTree
## As telas contra as da versão anterior: para cada foto com o mesmo nome nas
## duas pastas, a diferença média por pixel (0 a 100%) e uma prancha — antes,
## depois e a diferença realçada em rosa. Grava diferencas.md com a tabela.
##
##   godot --headless -s scripts/comparar_telas.gd -- <antes> <depois> <saída> [limite %]
##
## Com o limite, sai com 1 se alguma tela mudou mais que ele (sem limite, só
## relata: o 3D por software varia um pouco de máquina para máquina).


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 3:
		printerr("uso: godot --headless -s scripts/comparar_telas.gd -- <antes> <depois> <saída> [limite %]")
		quit(2)
		return
	var antes: String = a[0]
	var depois: String = a[1]
	var saida: String = a[2]
	var limite := float(a[3]) if a.size() > 3 else -1.0
	DirAccess.make_dir_recursive_absolute(saida)
	var linhas: PackedStringArray = ["| tela | diferença |", "| --- | --- |"]
	var passou := true
	var velhas := DirAccess.get_files_at(antes) if DirAccess.dir_exists_absolute(antes) else PackedStringArray()
	for f in DirAccess.get_files_at(depois):
		if not f.ends_with(".png"):
			continue
		if not f in velhas:
			linhas.append("| %s | nova |" % f.get_basename())
			continue
		var i1 := Image.load_from_file(antes.path_join(f))
		var i2 := Image.load_from_file(depois.path_join(f))
		for img in [i1, i2]:
			img.convert(Image.FORMAT_RGB8)
			img.resize(480, 270, Image.INTERPOLATE_BILINEAR)
		var d1 := i1.get_data()
		var d2 := i2.get_data()
		var mapa := PackedByteArray()
		mapa.resize(d1.size())
		var soma := 0.0
		for p in range(0, d1.size(), 3):
			var dif := (absi(d1[p] - d2[p]) + absi(d1[p + 1] - d2[p + 1]) + absi(d1[p + 2] - d2[p + 2])) / 3.0
			soma += dif
			var cinza := int((d2[p] + d2[p + 1] + d2[p + 2]) / 9.0)
			var k := clampf(dif / 40.0, 0.0, 1.0)
			mapa[p] = int(lerpf(cinza, 255, k))
			mapa[p + 1] = int(lerpf(cinza, 121, k))
			mapa[p + 2] = int(lerpf(cinza, 198, k))
		var pct := 100.0 * soma / (d1.size() / 3.0) / 255.0
		var dimg := Image.create_from_data(480, 270, false, Image.FORMAT_RGB8, mapa)
		var prancha := Image.create(1440, 270, false, Image.FORMAT_RGB8)
		prancha.blit_rect(i1, Rect2i(0, 0, 480, 270), Vector2i(0, 0))
		prancha.blit_rect(i2, Rect2i(0, 0, 480, 270), Vector2i(480, 0))
		prancha.blit_rect(dimg, Rect2i(0, 0, 480, 270), Vector2i(960, 0))
		prancha.save_png(saida.path_join(f.get_basename() + "-diferenca.png"))
		linhas.append("| %s | %.2f%% |" % [f.get_basename(), pct])
		if limite >= 0.0 and pct > limite:
			passou = false
	var t := "# As telas contra a versão anterior\n\n" + "\n".join(linhas) + "\n"
	var arq := FileAccess.open(saida.path_join("diferencas.md"), FileAccess.WRITE)
	arq.store_string(t)
	arq.close()
	print(t)
	quit(0 if passou else 1)
