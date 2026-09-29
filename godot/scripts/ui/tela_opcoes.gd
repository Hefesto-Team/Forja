class_name TelaOpcoes
extends Control
## As opções: as de quem abriu (o gatilho e a vibração do lugar dele) e as da
## sessão (volumes, tremor, flashes, tela, texto). ▲▼ escolhe a linha, ◀▶ troca
## o valor e o controle já sente (a vibração dá um toque na força escolhida);
## ○ volta, e o que mudou fica guardado.

signal mudou(chave: String)

var quem := 0  ## o lugar que abriu
var linha := 0
var _linhas: Array = []  # [chave, rótulo, seção]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func abrir(lugar: int) -> void:
	quem = lugar
	linha = 0
	_linhas = [
		["gatilho", "Gatilhos", "P%d" % (lugar + 1)],
		["vibracao", "Vibração", "P%d" % (lugar + 1)],
		["volume_tv", "Volume da TV", "sessao"],
		["volume_controle", "Volume do controle", "sessao"],
		["tremor", "Movimento da câmera", "sessao"],
		["flashes", "Flashes", "sessao"],
		["tela_cheia", "Tela", "sessao"],
		["texto", "Texto", "sessao"],
		["idioma", "Idioma", "sessao"],
	]


func navegar(dy: int) -> void:
	linha = wrapi(linha + dy, 0, _linhas.size())


func trocar(dx: int) -> void:
	var chave: String = _linhas[linha][0]
	match chave:
		"gatilho":
			Opcoes.gatilho[quem] = wrapi(int(Opcoes.gatilho[quem]) + dx, 0, Opcoes.GATILHO.size())
		"vibracao":
			Opcoes.vibracao[quem] = clampi(int(Opcoes.vibracao[quem]) + dx * Opcoes.PASSO, 0, 100)
			# mostrar, não contar: o controle sente a força nova
			Forja.vibrar(quem, 0.6, 0.6, 160)
		"volume_tv":
			Opcoes.volume_tv = clampi(Opcoes.volume_tv + dx * Opcoes.PASSO, 0, 100)
		"volume_controle":
			Opcoes.volume_controle = clampi(Opcoes.volume_controle + dx * Opcoes.PASSO, 0, 100)
		"tremor":
			Opcoes.tremor = not Opcoes.tremor
		"flashes":
			Opcoes.flashes = not Opcoes.flashes
		"tela_cheia":
			Opcoes.tela_cheia = not Opcoes.tela_cheia
		"texto":
			Opcoes.texto = wrapi(Opcoes.texto + dx, 0, Opcoes.TEXTO.size())
		"idioma":
			Opcoes.idioma = wrapi(Opcoes.idioma + dx, 0, Opcoes.IDIOMAS.size())
	mudou.emit(chave)


func valor(chave: String) -> String:
	match chave:
		"gatilho": return Opcoes.GATILHO[int(Opcoes.gatilho[quem])]
		"vibracao": return "%d%%" % int(Opcoes.vibracao[quem])
		"volume_tv": return "%d%%" % Opcoes.volume_tv
		"volume_controle": return "%d%%" % Opcoes.volume_controle
		"tremor": return "ligado" if Opcoes.tremor else "desligado"
		"flashes": return "ligados" if Opcoes.flashes else "desligados"
		"tela_cheia": return "tela cheia" if Opcoes.tela_cheia else "janela"
		"texto": return Opcoes.TEXTO[Opcoes.texto]
		"idioma": return Opcoes.NOMES_DOS_IDIOMAS[Opcoes.idioma]
	return ""


## A fração do valor, para a barra (os que são porcentagem); -1 sem barra.
func _fracao(chave: String) -> float:
	match chave:
		"vibracao": return Opcoes.vibracao[quem] / 100.0
		"volume_tv": return Opcoes.volume_tv / 100.0
		"volume_controle": return Opcoes.volume_controle / 100.0
		"gatilho": return int(Opcoes.gatilho[quem]) / 2.0
	return -1.0


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(Tema.APP, 0.86))
	var larg := 980.0
	var alto := 76.0  ## a linha com 66 px: focável de 64 ou mais (o estudo 02, item 6)
	var alt := 200.0 + _linhas.size() * alto + 40.0
	var r := Rect2(Vector2((size.x - larg) * 0.5, (size.y - alt) * 0.5), Vector2(larg, alt))
	Desenho.moldura(self, r, Tema.PAINEL, Tema.LINHA, 2, Tema.RAIO_QUADRO)
	Desenho.texto(self, r.position + Vector2(48, 84), "Opções", Tema.fonte(700), Tema.T_TITULO, Tema.FG)
	var y := r.position.y + 124.0
	var secao := ""
	for i in _linhas.size():
		var item: Array = _linhas[i]
		if item[2] != secao:
			secao = item[2]
			var titulo := "Sessão" if secao == "sessao" else secao
			var cor_t := Tema.ROXO if secao == "sessao" else Tema.tom_para_a_borda(Forja.cor_do_lugar(quem))
			Desenho.texto(self, Vector2(r.position.x + 48, y + 30), titulo, Tema.fonte(600), Tema.T_SELO, cor_t)
			y += 40.0
		var b := Rect2(Vector2(r.position.x + 48, y), Vector2(larg - 96, alto - 10))
		var sel := i == linha
		Desenho.moldura(self, b, Tema.SEL if sel else Tema.APP, Tema.ROXO if sel else Tema.LINHA, 4 if sel else 2, Tema.RAIO_BOTAO)
		Desenho.texto(self, b.position + Vector2(24, 42), str(item[1]), Tema.fonte(600 if sel else 500), Tema.T_ROTULO,
			Tema.FG if sel else Tema.SUAVE)
		var v := valor(item[0])
		var fv := Tema.fonte(600)
		var xv := b.end.x - 110 - Desenho.largura(v, fv, Tema.T_ROTULO)
		Desenho.texto(self, Vector2(xv, b.position.y + 42), v, fv, Tema.T_ROTULO, Tema.CIANO)
		var fr := _fracao(item[0])
		if fr >= 0.0:
			var trilho := Rect2(Vector2(b.position.x + 380, b.position.y + b.size.y * 0.5 - 4), Vector2(220, 8))
			draw_rect(trilho, Tema.TRILHO)
			draw_rect(Rect2(trilho.position, Vector2(trilho.size.x * fr, 8)), Tema.ROXO)
		if sel:
			Glifo.desenhar(self, "esquerda", Rect2(Vector2(b.end.x - 92, b.position.y + 15), Vector2(32, 32)), Tema.ROSA)
			Glifo.desenhar(self, "direita", Rect2(Vector2(b.end.x - 50, b.position.y + 15), Vector2(32, 32)), Tema.ROSA)
		y += alto
	Desenho.dicas_a_direita(self, Vector2(r.end.x - 48, r.end.y + 60),
		[["cima", "linha"], ["esquerda", "trocar"], ["circulo", "voltar"]], Tema.T_SELO)
