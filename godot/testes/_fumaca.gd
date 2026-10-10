extends Node
func _ready() -> void:
	var src := FileAccess.get_file_as_string("res://testes/prova_do_jogo.gd")
	var s := GDScript.new()
	s.source_code = src.replace("func _ready() -> void:", "func _ready_off() -> void:")
	var err := s.reload()
	if err != OK:
		printerr("reload ", err)
		get_tree().quit(1)
		return
	var n := Node.new()
	n.set_script(s)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--relatorios="):
			n.pasta = a.substr(13)
	Desenho._coletar = "memoria"
	add_child(n)
	var jogo = load("res://scenes/main.tscn").instantiate()
	n.add_child(jogo)
	n.jogo = jogo
	await n._quadros(240)
	for sim in 4:
		Forja.entrar(n._pad_do_sim(sim))
	await n._quadros(20)
	print("ocupados ", [Forja.ocupado(0), Forja.ocupado(1), Forja.ocupado(2), Forja.ocupado(3)])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--roda="):
			for f in a.substr(7).split(","):
				await n.call(f)
	print("FALHAS ", n.falhas)
	get_tree().quit()
