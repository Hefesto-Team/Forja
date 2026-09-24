class_name AltoFalanteDoControle
extends Node
## Acha o alto-falante do DualSense como um JOGO acha, e diz o nome na HUD.
##
## Um jogo sob Proton lista as saídas pelo NOME que o sistema publica (a
## descrição do nó) e procura a palavra da Sony nele — «DualSense», «Wireless
## Controller». Um port de PS5 casa pelo APARELHO. Quem percorre a lista e
## aplica as duas regras é o forja-speak --list: UM dono para a regra. Aqui se
## lê a resposta.
##
## O motor não serve para isto sozinho: o AudioServer do Godot lista os nós
## pelo nome de DENTRO, e o alto-falante de um controle no rádio não tem a
## palavra da Sony ali — só no nome que o jogo mostra.
##
## CONTRATO.md: este arquivo não conhece nenhum daemon. Nunca por MAC, nunca
## por socket, nunca por índice de hidraw.

signal alto_falante_achado(nome: String)
signal sem_alto_falante(motivo: String)

## Cada alto-falante que um jogo reconheceria, na ordem do servidor:
## {nome, mostra, canais, sozinho}. `nome` é o de dentro (o que o motor abre);
## `mostra` é o que o jogo mostra; `sozinho` é o que um port de PS5 acharia
## sem a pessoa apontar.
var achados: Array[Dictionary] = []
var nome_do_no: String = ""
var nome_que_o_jogo_mostra: String = ""
var motivo: String = ""
var _procurando := false


## Pergunta ao forja-speak AGORA, bloqueando. Para a HUD, use procurar_em_fundo().
func procurar() -> String:
	return ler_a_lista(_listar())


## A mesma pergunta num fio de trabalho: o pactl custa milissegundos, e a HUD
## não pode engasgar a cada volta. O resultado chega pelos dois sinais.
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
	var bin := DualSensePad.bin_irmao("forja-speak")
	if bin == "":
		return "# forja-speak ausente — rode make"
	var saida: Array = []
	var rc := OS.execute(bin, PackedStringArray(["--list"]), saida, false)
	if rc != 0 or saida.is_empty():
		return "# forja-speak --list falhou (rc %d)" % rc
	return str(saida[0])


## Lê a saída do `forja-speak --list`. Função pura: a prova headless a chama
## com um texto de mentira.
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
		## A RECUSA É ENTREGA: um jogo que fica em silêncio sobre "não há
		## alto-falante de controle" se lê como "o alto-falante não funciona".
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


## O motor inteiro passa a sair no controle — é o modo "Couro"/"Voz" do
## SPRINTS.md, com TODO o som no plástico. Para som POR JOGADOR, ver
## DualSensePad.tocar_sfx (forja-speak).
func tomar_a_saida() -> bool:
	if nome_do_no == "":
		return false
	AudioServer.output_device = nome_do_no
	## Pós-condição RELIDA: o servidor pode recusar e o Godot cai em "Default"
	## sem dizer nada — ler de volta é a diferença entre aplicar e achar que
	## aplicou.
	return AudioServer.output_device == nome_do_no


func devolver_a_saida() -> void:
	AudioServer.output_device = "Default"


## A linha da HUD: o nome que o jogo mostra, e quantos outros há.
func linha_da_hud() -> String:
	if achados.is_empty():
		return motivo if motivo != "" else "procurando o alto-falante do controle…"
	var outros := achados.size() - 1
	var mais := " (+%d)" % outros if outros > 0 else ""
	return "alto-falante: %s%s" % [nome_que_o_jogo_mostra, mais]
