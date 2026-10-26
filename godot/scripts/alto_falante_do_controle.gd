class_name AltoFalanteDoControle
extends Node

signal alto_falante_achado(nome: String)
signal sem_alto_falante(motivo: String)

var achados: Array[Dictionary] = []
var nome_do_no: String = ""
var nome_que_o_jogo_mostra: String = ""
var motivo: String = ""
var _procurando := false


func procurar() -> String:
	return ler_a_lista(_listar())


func procurar_em_fundo() -> void:
	if _procurando:
		return
	_procurando = true
	WorkerThreadPool.add_task(_procurar_no_fio)


func _procurar_no_fio() -> void:
	var texto := _listar()
	call_deferred("_chegou", texto)


func _chegou(texto: String) -> void:
	_procurando = false
	ler_a_lista(texto)


func _listar() -> String:
	var bin := bin_irmao("forja-speak")
	if bin == "":
		return "# forja-speak ausente — rode make"
	var saida: Array = []
	var rc := OS.execute(bin, PackedStringArray(["--list"]), saida, false)
	if rc != 0 or saida.is_empty():
		return "# forja-speak --list falhou (rc %d)" % rc
	return str(saida[0])


func ler_a_lista(texto: String) -> String:
	achados.clear()
	var total := 0
	var aviso := ""
	for linha in texto.split("\n", false):
		if linha.begins_with("# "):
			var primeira := linha.substr(2).get_slice(" ", 0)
			if primeira.is_valid_int():
				total = int(primeira)
			else:
				aviso = linha.substr(2)
			continue
		if not linha.begins_with("alto-falante "):
			continue
		var campos := linha.split("\t")
		if campos.size() < 5:
			continue
		achados.append({
			"nome": campos[1],
			"mostra": campos[2],
			"canais": int(campos[3].get_slice(" ", 0)),
			"sozinho": campos[4] == "acha sozinho",
		})
	if achados.is_empty():
		nome_do_no = ""
		nome_que_o_jogo_mostra = ""
		motivo = aviso if aviso != "" else (
			"nenhum alto-falante de controle na lista (%d dispositivos)" % total
		)
		sem_alto_falante.emit(motivo)
		return ""
	motivo = ""
	nome_do_no = achados[0]["nome"]
	nome_que_o_jogo_mostra = achados[0]["mostra"]
	alto_falante_achado.emit(nome_que_o_jogo_mostra)
	return nome_do_no


func tomar_a_saida() -> bool:
	if nome_do_no == "":
		return false
	AudioServer.output_device = nome_do_no
	return AudioServer.output_device == nome_do_no


func devolver_a_saida() -> void:
	AudioServer.output_device = "Default"


func linha_da_hud() -> String:
	if achados.is_empty():
		return motivo if motivo != "" else "procurando o alto-falante do controle…"
	var outros := achados.size() - 1
	var mais := " (+%d)" % outros if outros > 0 else ""
	return "alto-falante: %s%s" % [nome_que_o_jogo_mostra, mais]


static func bin_irmao(nome: String) -> String:
	var raiz := ProjectSettings.globalize_path("res://")
	var candidatos := [
		raiz.path_join("../bin").path_join(nome).simplify_path(),
		OS.get_executable_path().get_base_dir().path_join(nome),
		OS.get_executable_path().get_base_dir().path_join("../bin").path_join(nome),
	]
	for c in candidatos:
		if FileAccess.file_exists(c):
			return c
	return ""
