class_name SalaBancada
extends Sala
## A bancada dos experimentos (experimental/README.md), no lugar do salão.
##
## Cada experimento é uma pergunta que o jogo ainda não sabe responder com
## certeza — sobre o alto-falante, os microfones, a háptica e o gatilho do
## DualSense — medida no aparelho e gravada inteira: o que funcionou, o que
## falhou e o que não deu para medir, com o porquê. Nada daqui decide veredito
## das salas; cada resultado vai para a linha do tempo da sessão
## (`"tipo": "experimento"`) e para o registro.
##
## Abre com `--experimento=CHAVE`, com todos os controles na mesa. No fim, ✕
## repete e ○ fecha a sessão; com o robô, ela fecha sozinha: é uma rodada de
## teste.

const F := preload("res://scripts/forja.gd")
const EXPERIMENTOS := {
	"laco": ["O laço do alto-falante",
		"Quanto tempo o som leva do jogo ao alto-falante do controle e de volta pelo microfone dele — e se o microfone ouve os atuadores."],
	"quatro-mics": ["Quatro microfones",
		"Os quatro microfones abrem juntos, chega som de todos, e cada um é o do controle certo?"],
	"eco": ["O eco do alto-falante",
		"Quanto do alto-falante chega ao microfone do próprio controle, com a rota no alto-falante e no fone."],
	"gatilho-cru": ["Os bytes do gatilho",
		"Que bytes do report USB 0x01 mudam com o modo do gatilho, e quais com o aperto."],
	"haptica-nomeada": ["A háptica pelo nó do Hefesto",
		"A háptica chega pelo nó «Háptica do Controle N» (o caminho do rádio), dos dois lados?"],
}
const TENTATIVAS := 5
const TAXA := 48000
const BYTE_INI := 32
const BYTE_N := 32
const VOL_PADRAO := 0x64
const ROTA_FONE := 0
const ROTA_FALANTE := 3
const PREAMP_PADRAO := 2
## os quatro modos de gatilho do contrato: Off, Feedback, Weapon, Vibration
const MODOS := [[F.GATILHO_OFF, 0, 0, 0], [F.GATILHO_RESISTENCIA, 2, 4, 0], [F.GATILHO_ARMA, 2, 6, 8],
	[F.GATILHO_VIBRACAO, 0, 7, 30]]
const NOME_MODO := ["Off", "Feedback", "Weapon", "Vibration"]
const NOME_RES := ["medido", "falhou", "não medido"]

var chave := ""
var linhas: Array = []  ## [lugar (-1 a mesa), resultado, texto]
var agora := ""
var acabou := false
var ordem: Array = []  ## os lugares com controle, na ordem
var painel: PainelBancada
var _etapa := 0
var _vez := 0
var _k := 0
var _te := 0.0
var _rng := RandomNumberGenerator.new()
# o laço
var _lat: Array = []
var _pico_db := -90.0
# quatro microfones
var _nivel: Array = []  ## 16: [mic * 4 + quem fala]
var _soma := [0.0, 0.0, 0.0, 0.0]
var _amostras := 0
var _quadros_ini := [0, 0, 0, 0]
var _quadros := 0
# o eco
var _eco_db := [-90.0, -90.0, -90.0]
# o gatilho cru
var _min: Array = []
var _max: Array = []
var _solto_min: Array = []
var _solto_max: Array = []
var _viu_solto := [false, false, false, false]
# a háptica nomeada
var _plano := {}
var _perg := {}
var _resp := {}
var _tj := {}
var _robo := {}
var _lado := {}


func _init() -> void:
	id = "bancada"
	nome = "A bancada"
	acao = "experimental/ · a bancada dos experimentos"
	com_hud = false  # o painel da bancada tem o cabeçalho, os lugares e as dicas dele
	camera_pos = Vector3(0, 6.5, 9.5)
	camera_olhar = Vector3(0, 1.0, 0.0)


func montar() -> void:
	chave = Forja.experimento if EXPERIMENTOS.has(Forja.experimento) else "laco"
	nome = EXPERIMENTOS[chave][0]
	_rng.seed = int(Forja.semente) * 977 + hash(chave)
	Kit.arena(self, 4, 3)
	luzes([Vector3(-6, 2.5, -3), Vector3(6, 2.5, -3)])
	# a bancada: a mesa no meio, a bigorna em cima, os quatro em volta
	Kit.peca(self, "table", Vector3(0, 0, 0), 0.0, 2.6)
	Kit.bigorna(self, Vector3(0, 1.6, 0), 0.35)
	var lugares_em_volta := [Vector3(-2.6, 0.05, 1.2), Vector3(-0.9, 0.05, 2.3), Vector3(0.9, 0.05, 2.3), Vector3(2.6, 0.05, 1.2)]
	for p in jogadores:
		p.position = lugares_em_volta[p.lugar]
		p.controlavel = false
		p.olhar_para(Vector3(0, 0, 0))
	var camada := CanvasLayer.new()
	add_child(camada)
	painel = PainelBancada.new()
	painel.bancada = self
	camada.add_child(painel)
	Forja.som_preparar(F.PAPEL_ALTO_FALANTE)
	_comecar()


func sair() -> void:
	for l in 4:
		Forja.som_parar(l)
		Forja.som_escuta_parar(l)
	Forja.som_encerrar()
	super()


func _comecar() -> void:
	linhas.clear()
	acabou = false
	agora = ""
	_etapa = 0
	_vez = 0
	_k = 0
	_te = 0.0
	ordem.clear()
	for p in jogadores:
		if Forja.lugar(p.lugar).get("conectado", false):
			ordem.append(p.lugar)
	Forja.registrar("experimento: %s" % nome)
	Forja.evento("experimento", 0, {"experimento": chave, "o": "comecou", "controles": ordem.size()})


func _resultado(l: int, o: String, res: int, texto: String) -> void:
	Forja.resultado_experimento(l, chave, o, res, texto)
	linhas.append([l, res, texto])


func _process(dt: float) -> void:
	super(dt)
	for l in ordem:
		if acabou and Forja.apertou(l, F.CRUZ):
			_comecar()
			return
		if acabou and Forja.apertou(l, F.CIRCULO):
			# a bancada é a sessão inteira: ○ grava e fecha (o rodar.sh segue)
			Forja.gravar_relatorio()
			get_tree().quit()
			return
	if acabou:
		# com o robô, a bancada fecha sozinha: é uma rodada de teste
		if Forja.robo:
			_te += dt
			if _te > 2.0:
				Forja.gravar_relatorio()
				get_tree().quit()
		return
	var fim := false
	match chave:
		"laco":
			fim = _laco(dt)
		"quatro-mics":
			fim = _quatro_mics(dt)
		"eco":
			fim = _eco(dt)
		"gatilho-cru":
			fim = _gatilho_cru(dt)
		"haptica-nomeada":
			fim = _haptica_nomeada(dt)
		_:
			fim = true
	if fim:
		acabou = true
		_te = 0.0
		agora = "pronto: %d resultado%s gravado%s na linha do tempo da sessão" % [linhas.size(),
			"" if linhas.size() == 1 else "s", "" if linhas.size() == 1 else "s"]
		Som.tocar("sucesso", null, -6.0)


# ------------------------------------------------------------ 1. o laço --
# alto-falante → microfone do mesmo controle: cinco cliques, a mediana da
# latência; depois três pulsos nos atuadores — o microfone os ouve?

func _laco(dt: float) -> bool:
	_te += dt
	if _vez >= ordem.size():
		return true
	var l: int = ordem[_vez]
	if _etapa == 0:
		var tem := Forja.som_tem(l, F.PAPEL_ALTO_FALANTE)
		if not tem or not Forja.som_escutar(l, 0.1):
			_resultado(l, "latencia", 2, "sem alto-falante achado" if not tem
				else "sem microfone de verdade (controle simulado, ou não achado)")
			_proximo()
			return false
		Forja.som_escuta_parar(l)
		_etapa = 1
		_te = 0.0
	var haptica := _k >= TENTATIVAS
	var total := TENTATIVAS + 3
	if _etapa == 1 and _te >= 0.35:
		# dispara: o microfone limpo, e o som sai agora
		Forja.som_escutar(l, 0.8)
		if haptica:
			Forja.som_haptica(l, "pulso", "pulso", 1.0)
		else:
			Forja.som_falante(l, "clique", 1.0)
		_etapa = 2
		_te = 0.0
		agora = "P%d: %s %d de %d" % [l + 1, "pulso nos atuadores" if haptica else "clique no alto-falante",
			_k - TENTATIVAS + 1 if haptica else _k + 1, 3 if haptica else TENTATIVAS]
	if _etapa == 2 and _te >= 0.85:
		var am := Forja.som_escuta(l)
		var ta := Forja.exp_ataque(am, 6.0, 0.01) if am.size() > 0 else -1
		if ta >= 0:
			_lat.append(1000.0 * ta / TAXA)
			_pico_db = maxf(_pico_db, Forja.exp_rms_db(am, ta, mini(am.size() - ta, TAXA / 50)))
		Forja.som_escuta_parar(l)
		_k += 1
		_etapa = 1
		_te = 0.0
		if _k == TENTATIVAS:
			if _lat.size() > 0:
				_resultado(l, "latencia", 0, "o clique voltou pelo microfone em %.0f ms (mediana de %d de %d), a %.0f dBFS" % [
					Forja.exp_mediana(_lat), _lat.size(), TENTATIVAS, _pico_db])
			else:
				_resultado(l, "latencia", 1, "o microfone do controle não ouviu nenhum dos %d cliques do alto-falante dele" % TENTATIVAS)
			_lat.clear()
			_pico_db = -90.0
		elif _k == total:
			if not Forja.som_tem(l, F.PAPEL_HAPTICA):
				_resultado(l, "atuadores_no_microfone", 2, "sem háptica achada")
			elif _lat.size() > 0:
				_resultado(l, "atuadores_no_microfone", 0, "o microfone ouviu o pulso dos atuadores em %.0f ms (%d de 3), a %.0f dBFS" % [
					Forja.exp_mediana(_lat), _lat.size(), _pico_db])
			else:
				_resultado(l, "atuadores_no_microfone", 0, "o microfone não ouviu o pulso dos atuadores (0 de 3): o zumbido não chega a ele")
			_proximo()
	return false


func _proximo() -> void:
	_vez += 1
	_etapa = 0
	_k = 0
	_lat.clear()
	_pico_db = -90.0
	_te = 0.0


# ------------------------------------------------------------ 2. quatro microfones --
# todos abertos; dois segundos de silêncio; depois cada um fala, na sua vez.
# A matriz (microfone × quem fala) diz se cada microfone é o do controle certo.

static func _linear(nivel: float) -> float:
	return pow(10.0, (nivel * 54.0 - 54.0) / 20.0)


func _quatro_mics(dt: float) -> bool:
	_te += dt
	var n := ordem.size()
	if _etapa == 0:
		var com := 0
		for l in ordem:
			if Forja.som_tem(l, F.PAPEL_MICROFONE):
				com += 1
		if com == 0:
			_resultado(-1, "microfones", 2, "nenhum microfone achado")
			return true
		for i in n:
			_quadros_ini[i] = int(Forja.som_mic(ordem[i]).get("quadros", 0))
		_quadros = 0
		_nivel.clear()
		_nivel.resize(16)
		_nivel.fill(0.0)
		_etapa = 1
		_te = 0.0
		_vez = -1  # -1: o silêncio de todos
		_amostras = 0
		_soma = [0.0, 0.0, 0.0, 0.0]
	_quadros += 1
	var dur := 2.0 if _vez < 0 else 2.5
	if _te >= 0.5:
		for i in n:
			_soma[i] = float(_soma[i]) + _linear(float(Forja.som_mic(ordem[i]).get("nivel", 0.0)))
		_amostras += 1
	agora = "todos em silêncio" if _vez < 0 else "P%d: fale agora, perto do seu controle" % (int(ordem[_vez]) + 1)
	if _te >= dur:
		if _vez >= 0:
			for i in n:
				_nivel[i * 4 + _vez] = float(_soma[i]) / _amostras if _amostras > 0 else 0.0
		_vez += 1
		_te = 0.0
		_amostras = 0
		_soma = [0.0, 0.0, 0.0, 0.0]
		if _vez < n and Forja.robo:
			Forja.robo_falar(ordem[_vez], 0.8, 2.2)
		if _vez >= n:
			for i in n:
				var l: int = ordem[i]
				if not Forja.som_tem(l, F.PAPEL_MICROFONE):
					_resultado(l, "microfone", 2, "sem microfone achado")
					continue
				var q := int(Forja.som_mic(l).get("quadros", 0)) - int(_quadros_ini[i])
				var pct := int(round(100.0 * q / _quadros)) if _quadros > 0 else 0
				var db := 20.0 * log(maxf(float(_nivel[i * 4 + i]), 1e-5)) / log(10.0)
				_resultado(l, "microfone", 0 if pct >= 90 else 1, "chegou som em %d%% dos quadros; com a própria voz, %.0f dB" % [pct, db])
			if n >= 2:
				var d := Forja.exp_diagonal(_nivel, n)
				var certos := int(d.get("certos", 0))
				_resultado(-1, "microfone_certo", 0 if certos == n else 1,
					"%d de %d microfones foram os mais altos com a voz do próprio jogador (a menor margem: %.0f dB)" % [
						certos, n, float(d.get("margem_db", 0.0))])
			return true
	return false


# ------------------------------------------------------------ 3. o eco --
# o silêncio; um tom de 1 kHz no alto-falante; o mesmo tom com a rota no fone.

func _eco(dt: float) -> bool:
	_te += dt
	if _vez >= ordem.size():
		return true
	var l: int = ordem[_vez]
	if _etapa == 0:
		var tem := Forja.som_tem(l, F.PAPEL_ALTO_FALANTE)
		if not tem or not Forja.som_escutar(l, 0.1):
			_resultado(l, "eco", 2, "sem alto-falante achado" if not tem else "sem microfone de verdade (controle simulado, ou não achado)")
			_proximo()
			return false
		Forja.som_escuta_parar(l)
		_etapa = 1
		_k = 0
		_te = 0.0
	var o_que := ["silêncio", "tom de 1 kHz no alto-falante", "o mesmo tom, com a rota no fone"]
	if _etapa == 1 and _te >= 0.3:
		if _k == 2:
			Forja.alto_falante(l, VOL_PADRAO, ROTA_FONE, PREAMP_PADRAO)
		Forja.som_escutar(l, 1.3)
		if _k > 0:
			Forja.som_falante(l, "tom", 0.8)
		_etapa = 2
		_te = 0.0
		agora = "P%d: %s" % [l + 1, o_que[_k]]
	if _etapa == 2 and _te >= 1.35:
		var am := Forja.som_escuta(l)
		var ini := TAXA * 3 / 10
		var fim := mini(am.size(), TAXA * 11 / 10)
		_eco_db[_k] = Forja.exp_rms_db(am, ini, fim - ini) if fim > ini else -90.0
		Forja.som_escuta_parar(l)
		_k += 1
		_etapa = 1
		_te = 0.0
		if _k == 3:
			Forja.alto_falante(l, VOL_PADRAO, ROTA_FALANTE, PREAMP_PADRAO)
			_resultado(l, "eco", 0, "silêncio a %.0f dBFS; com o alto-falante tocando, %+.0f dB; com a rota no fone, %+.0f dB" % [
				_eco_db[0], float(_eco_db[1]) - float(_eco_db[0]), float(_eco_db[2]) - float(_eco_db[0])])
			_proximo()
	return false


# ------------------------------------------------------------ 4. os bytes do gatilho --
# só no cabo, com o report cru: quatro segundos em cada modo, com a pessoa
# apertando o R2 devagar até o fundo e soltando.

func _gatilho_cru(dt: float) -> bool:
	_te += dt
	if _vez >= ordem.size():
		return true
	var l: int = ordem[_vez]
	if _etapa == 0:
		if Forja.relatorio_cru(l).is_empty():
			_resultado(l, "gatilho_cru", 2, "sem o report cru USB 0x01 (controle simulado, virtual ou pelo rádio)")
			_proximo()
			return false
		_min.clear()
		_max.clear()
		_solto_min.clear()
		_solto_max.clear()
		for m in 4:
			var a := PackedInt32Array()
			a.resize(BYTE_N)
			a.fill(255)
			var b := PackedInt32Array()
			b.resize(BYTE_N)
			b.fill(0)
			_min.append(a.duplicate())
			_solto_min.append(a.duplicate())
			_max.append(b.duplicate())
			_solto_max.append(b.duplicate())
		_viu_solto = [false, false, false, false]
		_k = 0
		_etapa = 1
		_te = 0.0
		_modo(l, 0)
	agora = "P%d: R2 em %s — aperte devagar até o fundo e solte" % [l + 1, NOME_MODO[_k]]
	if _te >= 0.4:
		var cru := Forja.relatorio_cru(l)
		if cru.size() >= BYTE_INI + BYTE_N:
			var solto := Forja.eixo(l, F.R2) < 0.04
			for b in BYTE_N:
				var v := int(cru[BYTE_INI + b])
				_min[_k][b] = mini(int(_min[_k][b]), v)
				_max[_k][b] = maxi(int(_max[_k][b]), v)
				if solto:
					_solto_min[_k][b] = mini(int(_solto_min[_k][b]), v)
					_solto_max[_k][b] = maxi(int(_solto_max[_k][b]), v)
			_viu_solto[_k] = _viu_solto[_k] or solto
	if _te >= 4.0:
		_k += 1
		_te = 0.0
		if _k < 4:
			_modo(l, _k)
		else:
			_modo(l, 0)
			var do_modo: Array = []
			var do_aperto: Array = []
			for b in BYTE_N:
				var estavel := true
				var difere := false
				var varia := false
				for m in 4:
					if not _viu_solto[m]:
						continue
					estavel = estavel and _solto_min[m][b] == _solto_max[m][b]
					difere = difere or _solto_min[m][b] != _solto_min[0][b]
					varia = varia or _max[m][b] != _min[m][b]
				if estavel and difere:
					do_modo.append(str(BYTE_INI + b))
				elif varia and estavel:
					do_aperto.append(str(BYTE_INI + b))
			_resultado(l, "gatilho_cru", 0, "bytes que mudam com o modo (solto): %s; bytes que mudam só com o aperto: %s" % [
				", ".join(do_modo) if do_modo.size() > 0 else "nenhum", ", ".join(do_aperto) if do_aperto.size() > 0 else "nenhum"])
			_proximo()
	return false


func _modo(l: int, m: int) -> void:
	var md: Array = MODOS[m]
	Forja.gatilho(l, 1, md[0], md[1], md[2], md[3])


# ------------------------------------------------------------ 5. a háptica nomeada --
# todos ao mesmo tempo: quatro pulsos, dois de cada lado em ordem sorteada; a
# pessoa diz o lado (L1, R1, o touchpad é "não senti").

func _haptica_nomeada(dt: float) -> bool:
	if _etapa == 0:
		for l in ordem:
			_plano[l] = Array(Forja.cega_plano_fontes([0, 1], [2, 2], _rng.randi()))
			_lado[l] = Cega.nova()
			_perg[l] = 0
			_resp[l] = -1
			_tj[l] = 0.0
			_robo[l] = -1
			if not Forja.som_tem(l, F.PAPEL_HAPTICA):
				_resultado(l, "haptica", 2, "nenhuma háptica achada (sem a placa no cabo, sem o nó do Hefesto)")
				_perg[l] = 4
		_etapa = 1
	agora = "de que lado tremeu? L1 esquerda · R1 direita · touchpad: não senti"
	var todos := true
	for l in ordem:
		if int(_perg[l]) >= 4 or not Forja.lugar(l).get("conectado", false):
			continue
		todos = false
		var plano: Array = _plano[l]
		var lado: int = plano[int(_perg[l])] if int(_perg[l]) < plano.size() else 0
		var t0 := float(_tj[l])
		_tj[l] = t0 + dt
		var tj := float(_tj[l])
		if t0 < 0.6 and tj >= 0.6:
			# o pulso, num lado só (num nó mono, nos dois)
			var estereo := Forja.som_estereo(l, F.PAPEL_HAPTICA)
			Forja.som_haptica(l, "tropeco" if lado == 0 or not estereo else "", "tropeco" if lado == 1 and estereo else "")
		if tj >= 0.9 and int(_resp[l]) < 0:
			if Forja.apertou(l, F.L1):
				_resp[l] = 0
			elif Forja.apertou(l, F.R1):
				_resp[l] = 1
			elif Forja.apertou(l, F.TOUCHPAD):
				_resp[l] = 2
		# o robô sente os atuadores do controle dele na hora do pulso
		if Forja.robo and tj >= 0.62 and tj < 0.9:
			var v := Forja.som_virtual(l)
			var e := float(v.get("esq", 0.0))
			var d := float(v.get("dir", 0.0))
			if maxf(e, d) > 0.05:
				_robo[l] = 10 if e > d else 11
		if Forja.robo and t0 < 1.3 and tj >= 1.3 and int(_resp[l]) < 0:
			Forja.robo_apertar(l, F.L1 if int(_robo[l]) == 10 else (F.R1 if int(_robo[l]) == 11 else F.TOUCHPAD), 0.08)
		if int(_resp[l]) >= 0 or tj >= 6.0:
			var c: Dictionary = _lado[l]
			if int(_resp[l]) == lado:
				Cega.certo(c)
			elif int(_resp[l]) >= 0:
				Cega.errado(c, int(_resp[l]))
			else:
				Cega.perdido(c)
			_perg[l] = int(_perg[l]) + 1
			_resp[l] = -1
			_tj[l] = 0.0
			_robo[l] = -1
			if int(_perg[l]) >= 4:
				_resultado(l, "haptica", 0 if int(c.certos) >= 3 else 1, "«%s», %s: lado certo %d de 4, \"não senti\" %d, sem resposta %d" % [
					Forja.som_nome(l, F.PAPEL_HAPTICA), Forja.som_como(l, F.PAPEL_HAPTICA), int(c.certos), int(c.como[2]), int(c.perdidos)])
	return todos
