# K2 — Quebra-Gelo

**Sprint:** K · **Slot:** S03_J12 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, H07, G10, G14, G15, K1 (o `secao.gd`)

## Por quê

Rachar é riscar o touchpad de um lado ao outro num golpe só, no contratempo. Hoje cada um quebra a própria pilha, e
ninguém olha a raia do vizinho. Com a troca, cada bloco que você quebra sobe como bloco duro na placa de quem está na
frente: o gelo vai para o líder, e a pilha dele pode desabar.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [O índice da seção](K-o-molde.md) (as convenções do toque)
- [K1 — O Molde, o `secao.gd`](K1-o-molde.md#godotscriptsminigamess03secaogd-novo-o-arquivo-inteiro) (o `secao.gd` inteiro, a função `momento` e o kit que a seção usa)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão e o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s03/quebra_gelo.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `"S03_J12"` em `MINIGAMES` e na lista `minigames` da S03, depois do `"S03_J11"` | **da seção** |
| `godot/scripts/traducoes.gd` | `"Quebra-Gelo"`, `"Rache!"` e o placar `Blocos:` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_quebra_gelo()` e a linha `"S03_J12"` no `match` de `_prova_da_ficha` | **de todos** |

O `secao.gd` é da K1: esta ficha só chama. Se a K1 ainda não entrou, esta espera. O `quebra_gelo.gd.uid` sai do import
(`"$GODOT" --headless --path godot --import --quit`) e entra no commit.

Commit (sem trailer): `feat(quebra-gelo): o risco no contratempo, o gelo que vai para o líder e a avalanche`.

### O que muda de hoje (a ficha velha)

| antes | depois |
| --- | --- |
| TcT: cada um quebra a própria pilha | sabotagem: cada bloco quebrado sobe como bloco duro na placa do líder |
| a falha congela o boneco por 4 tempos | a falha é a lâmina que escorrega: o bloco não racha, e nada mais |
| o gelo `#bfe6ff`, as rachaduras `#4a6a86`, a seta `#8fb8d8` | o bloco `GRAFITE`, o duro `JANELA`, as rachaduras `FITA` e `MUDO`, a seta `ETIQUETA` |
| a câmera `(0, 8,6; 12,7)` | a da seção, `(0,2; 11,2; 8,4)` |
| a rajada no pico do kit | a rajada de 25 a 50 s, decidida pela batida da nota |
| sem momento | a `avalanche`, com linha `momento` |

### `godot/scripts/minigames/s03/quebra_gelo.gd` (novo, o arquivo inteiro)

```gdscript arquivo=godot/scripts/minigames/s03/quebra_gelo.gd
extends Minigame
## Quebra-Gelo (S03_J12). Um bloco de gelo em cima da placa de cada um (a placa
## é o touchpad). O risco: o dedo encosta e anda 0,35 da largura para o lado
## pedido, no contratempo do lugar (o "e" depois do tempo dele); o lado se
## alterna. Três rachaduras quebram o bloco, e ele sobe como bloco duro (5
## rachaduras, com a coroa) na placa do líder, atrás do bloco dele. Três ou mais
## chegando ao líder no mesmo compasso: a avalanche.
##
## A falha: a lâmina escorrega e o bloco não racha.
## O vencedor: mais blocos quebrados (nas últimas 16 batidas, cada um conta 2).
## O alto-falante do dono: o gelo no acerto, a nota no perfeito, a coleta no bloco.
## O registro mede: quanto o dedo andou, de onde a onde, e em quanto tempo (a
## linha `entrada`); o tempo (o kit); o `momento` `avalanche` e o `reta`.
## O robô: risca 0,6 da largura em 150 ms, na nota (ou 200 ms atrasado).
## Com menos de quatro: nada muda; com um só, não há líder e ninguém manda.
## A régua: "Rache!" e o touchpad bastam; sem a tela, o lado alternado e a nota
## no contratempo dão para jogar; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

const FICHA := {
	"slot": "S03_J12",
	"titulo": "Quebra-Gelo",
	"verbo": "Rache!",
	"genero": "sabotagem",
	"icone": "touchpad",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S03_J12",
	"duracao": 75.0,
	"fim": "tempo",
	"sensacoes": ["toque", "acerto", "perfeito", "aviso", "erro", "golpe"],
	"material": "gelo",
	"textura_no_acerto": false,  # a racha que corre na mão (_racha_na_mao) é o sentir do acerto
	"microjogo": {"verbo": "Rache!", "segundos": 6.0},
	"gesto": "attack-melee-right",
}

const CAMERA_POS := Vector3(0.2, 11.2, 8.4)
const CAMERA_OLHAR := Vector3(0.2, 0.9, -0.3)
const RISCO := 0.35
const RACHAS := 3
const RACHAS_DURO := 5
const PONTOS := [0, 20, 35, 50]
const QUEBRA := 60
## A rajada, em s de música: duas notas por compasso.
const RAJADA_DE := 25.0
const RAJADA_ATE := 50.0
## Três ou mais blocos chegando ao líder no mesmo compasso.
const AVALANCHE := 3
## O líder soterrado fica sem nota por 2 tempos × levantar (o Fôlego).
const SOTERRADO_TEMPOS := 2.0
## O bloco duro na fila: 0,9 m de altura; três empilhados são 1,5 vez o cavaleiro (1,8 m).
const BLOCO_FILA := Vector3(1.4, 0.9, 0.8)
const PILHA_Z := -0.9
const NEVE_S := 4.0
## A racha corre na mão: o atuador do lado de onde o dedo saiu, e 40 ms depois o outro.
const RACHA_MS := 40

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
## "lugar:compasso" -> quantos blocos chegaram àquele lugar naquele compasso.
var chegadas := {}


func montar() -> void:
	SECAO.montar(self, CAMERA_POS, CAMERA_OLHAR)
	var gelo := Kit.material(Tema.GRAFITE, 0.0, 0.9)
	var duro := Kit.material(Tema.JANELA, 0.0, 0.85)
	var risco := Kit.chapado(Tema.FITA)
	var risco_duro := Kit.chapado(Tema.MUDO)
	var seta_mat := Kit.chapado(Tema.ETIQUETA)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l, false)
		var placa: Node3D = nos.placa
		var bloco := Kit.caixa(placa, Vector3(2.2, 0.5, 1.0), Vector3(0, 0.33, 0), gelo)
		var rachaduras: Array = []
		for k in RACHAS_DURO:
			var r := Kit.caixa(placa, Vector3(0.03, 0.02, 0.8), Vector3(-0.8 + 0.4 * k, 0.59, 0), risco)
			r.rotation.y = rng.randf_range(-0.8, 0.8)
			r.visible = false
			rachaduras.append(r)
		var coroa := Node3D.new()
		coroa.position = Vector3(0, 0.59, 0.32)
		placa.add_child(coroa)
		Kit.caixa(coroa, Vector3(0.36, 0.02, 0.05), Vector3.ZERO, risco_duro)
		for k in 3:
			Kit.caixa(coroa, Vector3(0.05, 0.02, 0.12), Vector3(-0.15 + 0.15 * k, 0, -0.08), risco_duro)
		coroa.visible = false
		var seta := Node3D.new()
		seta.position = Vector3(0, 0.62, 0)
		placa.add_child(seta)
		Kit.caixa(seta, Vector3(0.5, 0.03, 0.08), Vector3.ZERO, seta_mat)
		for lado in [-1.0, 1.0]:
			var ponta := Kit.caixa(seta, Vector3(0.2, 0.03, 0.06), Vector3(0.2, 0, lado * 0.06), seta_mat)
			ponta.rotation.y = lado * PI * 0.25
		var pilha := Node3D.new()
		pilha.position = Vector3(float(nos.cx), 0.85, PILHA_Z)
		add_child(pilha)
		var neve := SECAO.peca(self, "holiday-kit/snow-pile", "stones", Vector3.ZERO, 0.0, 0.5)
		neve.visible = false
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		martelo_na_mao(p)
		nos["bloco"] = bloco
		nos["rachaduras"] = rachaduras
		nos["coroa"] = coroa
		nos["seta"] = seta
		nos["pilha"] = pilha
		nos["neve"] = neve
		nos["gelo"] = gelo
		nos["duro"] = duro
		nos["risco"] = risco
		nos["risco_duro"] = risco_duro
		j[l] = {"n": 0, "b": -1.0, "dir": -1, "x0": -1.0, "t0": 0.0, "antes": false, "aberta": false,
			"rachas": 0, "precisa": RACHAS, "fila": 0, "quebrados": 0, "enviados": 0, "recebidos": 0,
			"soterrado_ate": -99.0, "sumido_ate": -99.0, "neve_ate": -99.0, "frio_ate": -99.0,
			"avalanche_c": -1, "ultimo_de": -1, "seta_dir": 1, "fora": false, "nos": nos, "robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A próxima nota do lugar depois de `desde`: o contratempo dele (uma por compasso)
## ou, na rajada (de 25 a 50 s), duas por compasso; nunca dentro do soterrado.
func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var inicio := maxf(desde, float(e.soterrado_ate))
	var t := Ritmo.t_da_batida(inicio)
	var passo := 4.0
	var desloc := l + 0.5
	if t >= RAJADA_DE and t < RAJADA_ATE:
		passo = 2.0
		desloc = (l % 2) + 0.5
	e.b = proxima_batida(l, inicio, passo, desloc)
	e.dir = -int(e.dir)
	e.aberta = false
	e.antes = false
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b)))


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			anotar("entrada", l, {"o": "sensores", "toque": false})
			acabou[l] = true
			continue
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
	SECAO.pico(self)
	var agora := Ritmo.t_musica()
	for l in presentes():
		var e: Dictionary = j[l]
		SECAO.mostrar_dedos(self, l, e.nos)
		_mostrar(l)
		if Ritmo.batida() < float(e.frio_ate):
			SECAO.textura(l, "gelo")
		if acabou[l] or float(e.b) < 0.0:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			_proxima(l, Ritmo.batida())
		_nota(l, e, agora)


## O risco: o dedo encostado andou RISCO da largura para o lado pedido desde que encostou.
func _riscou(l: int, e: Dictionary) -> bool:
	var d := Forja.dedo(l, 0)
	if d.z <= 0.5:
		e.x0 = -1.0
		return false
	SECAO.textura(l, "gelo")
	if float(e.x0) < 0.0:
		e.x0 = d.x
		e.t0 = Ritmo.t_musica()
		return false
	return (d.x - float(e.x0)) * float(e.dir) >= RISCO


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var sim := _riscou(l, e)
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.antes = sim
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		var d := Forja.dedo(l, 0)
		anotar("entrada", l, {"o": "touchpad", "de_x": snappedf(float(e.x0), 0.01), "ate_x": snappedf(d.x, 0.01),
			"ms": int((agora - float(e.t0)) * 1000.0), "lado": int(e.dir), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		var n_antes := int(e.n)
		nota_perdida(l, n_antes)  # chama falha(), que avança
		if int(e.n) == n_antes:  # o Escudo absorveu o erro e falha() não veio: avança calado
			e.n = n_antes + 1
			_proxima(l, float(e.b))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	marcar(l, PONTOS[julgamento])
	var bloco: Node3D = nos.bloco
	Som.tocar("tique", bloco.global_position, -4.0, 1.6)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.5)  # a textura do gelo é dos atuadores (H08), nunca do alto-falante
	_racha_na_mao(l, int(e.dir))
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.35)
	if not treinando:
		e.rachas = int(e.rachas) + (2 if julgamento == Ritmo.PERFEITO else 1)
		if int(e.rachas) >= int(e.precisa):
			_quebrar(l)
	e.n = int(e.n) + 1
	_proxima(l, float(e.b))


## A racha corre na mão: o atuador do lado de onde o dedo saiu e, 40 ms depois, o outro.
## Sem a háptica (o motor do lugar vibrando, ou sem o módulo: `som_haptica` devolve −1),
## o acerto se sente pelo `Forja.sentir(l, "acerto")` e a racha não corre.
func _racha_na_mao(l: int, dir: int) -> void:
	var primeiro := "pulso"
	var tocou: int
	if dir > 0:
		tocou = Forja.som_haptica(l, primeiro, "", 0.6)
	else:
		tocou = Forja.som_haptica(l, "", primeiro, 0.6)
	if tocou < 0:
		Forja.sentir(l, "acerto")
		return
	await get_tree().create_timer(RACHA_MS / 1000.0).timeout
	if dir > 0:
		Forja.som_haptica(l, "", primeiro, 0.6)
	else:
		Forja.som_haptica(l, primeiro, "", 0.6)


## O bloco quebra: conta (2 na reta), sobe o próximo (um duro da fila, se houver)
## e manda o bloco (2 na reta) para o líder, se o líder não é você.
func _quebrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var bloco: Node3D = nos.bloco
	var vale := 2 if SECAO.na_reta(self) else 1
	e.rachas = 0
	e.quebrados = int(e.quebrados) + vale
	marcar(l, QUEBRA * vale)
	Forja.som_falante(l, "coleta", 0.8)
	Som.tocar("pedra", bloco.global_position, 0.0)
	Efeitos.faiscas(self, bloco.global_position, Tema.JOGADOR[l], 40, 1.2)
	if int(e.fila) > 0:
		e.fila = int(e.fila) - 1
		e.precisa = RACHAS_DURO
	else:
		e.precisa = RACHAS
	bloco.scale = Vector3.ONE * 0.1
	var tw := bloco.create_tween()
	tw.tween_property(bloco, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lider := _lider()
	if lider >= 0 and lider != l:
		for k in vale:
			_mandar(l, lider, k * 0.25)


## O líder: quem tem mais blocos quebrados, sozinho. Empate: ninguém. Com um só jogador: ninguém.
func _lider() -> int:
	var vivos := presentes().filter(func(x): return not acabou[x])
	if vivos.size() < 2:
		return -1
	var melhor := -1
	var empate := false
	for x in vivos:
		if melhor < 0 or int(j[x].quebrados) > int(j[melhor].quebrados):
			melhor = x
			empate = false
		elif int(j[x].quebrados) == int(j[melhor].quebrados):
			empate = true
	return -1 if empate else melhor


## O bloco voa em arco, 1 batida, da placa de quem quebrou até o topo da pilha do
## líder, com faíscas da cor de quem mandou; chega com som de pedra.
func _mandar(de: int, para: int, atraso_batidas: float) -> void:
	j[de].enviados = int(j[de].enviados) + 1
	var nos_de: Dictionary = j[de].nos
	var nos_para: Dictionary = j[para].nos
	var voando := Kit.caixa(self, BLOCO_FILA * 0.6, (nos_de.placa as Node3D).global_position + Vector3(0, 0.6, 0), nos_para.duro)
	var de_pos := voando.global_position
	var batida := 60.0 / Ritmo.bpm
	var marcos := [0.25, 0.5, 0.75]
	var arco := func(u: float) -> void:
		var ate: Vector3 = (nos_para.pilha as Node3D).global_position + Vector3(0, BLOCO_FILA.y * (int(j[para].fila) + 0.5), 0)
		voando.global_position = de_pos.lerp(ate, u) + Vector3.UP * 2.5 * sin(PI * u)
		if not marcos.is_empty() and u >= float(marcos[0]):
			marcos.pop_front()
			Efeitos.faiscas(self, voando.global_position, Tema.JOGADOR[de], 4, 0.4)
	var chegar := func() -> void:
		voando.queue_free()
		_chegou(de, para)
	var tw := voando.create_tween()
	tw.tween_interval(atraso_batidas * batida)
	tw.tween_method(arco, 0.0, 1.0, batida)
	tw.tween_callback(chegar)


## O bloco chegou: entra na fila do líder, ele sente o gelo por 1 compasso, e
## o terceiro do mesmo compasso derruba a pilha.
func _chegou(de: int, para: int) -> void:
	var e: Dictionary = j[para]
	e.fila = int(e.fila) + 1
	e.recebidos = int(e.recebidos) + 1
	e.ultimo_de = de
	e.frio_ate = Ritmo.batida() + 4.0
	var topo := (e.nos.pilha as Node3D).global_position + Vector3(0, BLOCO_FILA.y * int(e.fila), 0)
	Som.tocar("pedra", topo, -2.0)
	Efeitos.faiscas(self, topo, Tema.JOGADOR[de], 24, 0.8)  # o gelo na mão do líder vem do frio_ate, pela textura
	var c := int(floorf(Ritmo.batida() / 4.0))
	var chave := "%d:%d" % [para, c]
	chegadas[chave] = int(chegadas.get(chave, 0)) + 1
	if int(chegadas[chave]) >= AVALANCHE and int(e.avalanche_c) != c:
		e.avalanche_c = c
		_avalanche(para, de)


## A avalanche: a pilha desaba para a frente, o líder some atrás do gelo por 1
## batida, a cabeça reaparece com neve por 4 s, e ele fica soterrado (sem nota)
## por 2 tempos × levantar. Degrau catástrofe.
func _avalanche(l: int, quem_soltou: int) -> void:
	var e: Dictionary = j[l]
	var pilha: Node3D = e.nos.pilha
	var altura := BLOCO_FILA.y * int(e.fila)
	var batida := 60.0 / Ritmo.bpm
	SECAO.degrau(self, l, "catastrofe", pilha.global_position + Vector3(0, altura * 0.5, 0), Tema.JOGADOR[quem_soltou])
	Som.tocar("pedra", pilha.global_position, 3.0, 0.7)
	var tw := pilha.create_tween()
	tw.tween_property(pilha, "rotation:x", deg_to_rad(70.0), batida * 0.5).set_ease(Tween.EASE_IN)
	tw.tween_interval(batida)
	tw.tween_property(pilha, "rotation:x", 0.0, batida)
	e.sumido_ate = Ritmo.batida() + 1.0
	e.neve_ate = Ritmo.t_musica() + NEVE_S
	e.soterrado_ate = Ritmo.batida() + SECAO.queda(l, SOTERRADO_TEMPOS)
	momento("avalanche", l, pilha.global_position, maxf(altura, 0.9), {"blocos": int(e.fila), "de": quem_soltou})
	# no controle: quem soltou ouve a pedra; o líder sente o golpe; os outros, o forte que sobe em 600 ms
	Som.no_controle(quem_soltou, "pedra", 0.9)
	Forja.sentir(l, "golpe")
	for x in presentes():
		if x != l and x != quem_soltou and conectado(x):
			_rampa(x)


## O forte de 0 a 1,0 em 600 ms: seis pulsos de 100 ms que sobem pela tabela de
## sensações (F05: o forte de cada uma é 0; 0,3; 0,5; 0,6; 0,7; 1,0). Nunca o
## Forja.vibrar, que só o forja.gd chama.
const RAMPA := ["toque", "acerto", "perfeito", "aviso", "erro", "golpe"]


func _rampa(x: int) -> void:
	for nome in RAMPA:
		Forja.sentir(x, nome, 100)
		await get_tree().create_timer(0.1).timeout


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	var bloco: Node3D = e.nos.bloco
	# a lâmina escorrega: faíscas de tungstênio na borda, o bloco não racha
	Efeitos.faiscas(self, bloco.global_position + Vector3(float(e.dir) * 1.0, 0.2, 0), Tema.TUNGSTENIO, 16, 0.6)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	e.n = int(e.n) + 1
	_proxima(l, float(e.b))


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var duro_agora := int(e.precisa) == RACHAS_DURO
	(nos.bloco as MeshInstance3D).material_override = nos.duro if duro_agora else nos.gelo
	(nos.coroa as Node3D).visible = duro_agora
	for k in RACHAS_DURO:
		var r: MeshInstance3D = nos.rachaduras[k]
		r.visible = k < int(e.rachas) and k < int(e.precisa)
		r.material_override = nos.risco_duro if duro_agora else nos.risco
	var seta: Node3D = nos.seta
	seta.visible = fase == "jogo" and not acabou[l] and float(e.b) >= 0.0
	# o Faro: a seta gira para o lado da nota armada 1 aviso antes dela
	if float(e.b) >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(float(e.b)) - SECAO.aviso_s(l):
		e.seta_dir = int(e.dir)
	seta.rotation.y = 0.0 if int(e.seta_dir) > 0 else PI
	# a pilha atrás da placa: um bloco duro de 1,4 × 0,9 × 0,8 por bloco na fila
	var pilha: Node3D = nos.pilha
	while pilha.get_child_count() < int(e.fila):
		var k := pilha.get_child_count()
		var b := Kit.caixa(pilha, BLOCO_FILA, Vector3(0, BLOCO_FILA.y * (k + 0.5), 0), nos.duro)
		Kit.caixa(b, Vector3(0.36, 0.02, 0.05), Vector3(0, 0, BLOCO_FILA.z * 0.5 + 0.01), nos.risco_duro).rotation.x = PI * 0.5
	while pilha.get_child_count() > int(e.fila):
		var ultimo := pilha.get_child(pilha.get_child_count() - 1)
		pilha.remove_child(ultimo)
		ultimo.queue_free()
	var p := jogador(l)
	if p:
		p.visible = Ritmo.batida() >= float(e.sumido_ate) or fase != "jogo"
		var neve: Node3D = nos.neve
		neve.visible = Ritmo.t_musica() < float(e.neve_ate) and p.visible
		neve.global_position = p.global_position + Vector3(0, 1.95, 0)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].quebrados) != int(j[b].quebrados):
		return int(j[a].quebrados) > int(j[b].quebrados)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Blocos: %d" % int(j[lugar].quebrados)
	return super(lugar)
```

### `godot/scripts/minigames/catalogo.gd`

Em `MINIGAMES`: `"S03_J12": preload("res://scripts/minigames/s03/quebra_gelo.gd"),`. Na S03 de `SECOES`:
`"minigames": ["S03_J11", "S03_J12"]` (só acrescente o `"S03_J12"` ao que estiver lá).

### `godot/scripts/traducoes.gd`

`"Quebra-Gelo": "Icebreaker"` e `"Rache!": "Crack it!"`. Em `EN_PADROES`: `["^Blocos: (\\d+)$", "Blocks: $1"]`.

## Como se joga

- **A faixa:** `mus_s03_j12`, 130 BPM, Fá# menor ("vidro no contratempo"). Até a H05, a sintetizada da seção a 100
  bpm.
- **O bloco:** um bloco de gelo de 2,2 × 0,5 × 1,0 m em cima da placa de cada um (a placa é o touchpad).
- **O risco:** o dedo encosta e anda **0,35 da largura** do touchpad para o lado pedido, sem levantar. O instante
  em que ele completa os 0,35 é o toque. O lado se alterna a cada nota (→, ←); a seta em cima do bloco mostra qual.
  Para o próximo risco, o dedo levanta.
- **O hoqueto no contratempo:** a nota do lugar `l` cai no "e" depois do tempo dele: `4c + l + 0,5` (P1 no "e" do
  1, P2 no "e" do 2…), uma por compasso. Na partitura simples (`Ritmo.simples[l]`), uma a cada 2 compassos (o
  `proxima_batida` do kit dobra o passo).
- **A rajada, de 25 a 50 s** (decidida pela batida da nota): duas por compasso, em `4c + 0,5 + (l % 2)` e mais 2
  tempos. P1 e P3 juntos no "e" do 1 e do 3; P2 e P4 no "e" do 2 e do 4.
- **O julgamento, no cruzamento** (as convenções da seção), dentro da janela que abre meio tempo antes. Nada até
  `FOLGA_PERDIDA` (140 ms) depois: nota perdida.
- **O bloco racha:** cada acerto é uma rachadura (a Ressonância, duas). Com **3 rachaduras**, o bloco quebra e outro
  sobe da bancada.
- **O gelo vai para o líder.** O líder é quem tem mais blocos quebrados, sozinho; no empate, ninguém. Cada bloco que
  você quebra voa em arco (1 batida) até a placa do líder e entra na fila dele como **bloco duro**: 5 rachaduras,
  `JANELA`, com a coroa gravada. A fila se vê empilhada atrás da placa dele. Quando o bloco atual do líder quebra, o
  próximo é um duro da fila, se houver. Ninguém manda bloco para si mesmo. O último nunca recebe, porque nunca é o
  líder.
- **A avalanche:** 3 ou mais blocos chegam ao mesmo líder no mesmo compasso. A pilha desaba para a frente, ele some
  atrás do gelo por 1 batida e fica **soterrado**: sem nota por `SECAO.queda(l, 2)` tempos (o Fôlego). Uma vez por
  compasso.
- **A falha:** a lâmina escorrega e o bloco não racha. Nada mais.
- **Os pontos** por julgamento (erro, bom, ótimo, Ressonância): `[0, 20, 35, 50]`; o bloco quebrado, +60.
- **A reta (as últimas 16 batidas):** cada bloco quebrado conta 2, vale +120 e manda 2.
- **O fim** é do kit, em tempo de música: 75 s.
- **O vencedor:** mais blocos quebrados; no empate, os pontos; depois, o lugar.
- **Com menos de quatro:** nada muda; com um jogador, não há líder e ninguém manda. **O controle que cai:** as notas
  dele param, sem erro; ao voltar, a próxima é o próximo contratempo dele que ainda não passou. Os blocos que
  chegam continuam entrando na fila dele. **Sem touchpad:** o lugar acaba no `iniciar_jogo()`, sem erro, e grava
  `entrada` `sensores` `toque: false`.

### O robô

```gdscript arquivo=godot/scripts/minigames/s03/quebra_gelo.gd parte=2
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if float(e.b) < 0.0:
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	var quando := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
	var agora := Ritmo.t_musica()
	if agora >= quando - 0.1 and agora <= quando + 0.1:
		# encosta 100 ms antes e risca 0,6 da largura em 150 ms: os 0,35 caem na nota
		var u := clampf((agora - (quando - 0.1)) / 0.15, 0.0, 1.0)
		Forja.robo_tocar(l, 0, 0.5 + float(e.dir) * lerpf(-0.3, 0.3, u), 0.5, 0.06)
```

## A cena

- **A câmera:** a da seção, fixa, lente da arena (35 mm, 37,8°), plongée de 50°: `camera_pos = Vector3(0.2, 11.2,
  8.4)`, `camera_olhar = Vector3(0.2, 0.9, -0.3)`. Não corta. No pico (o terço do meio), recua 10 % pelo
  `SECAO.pico`.
- **A luz:** a da seção (petróleo, `SECAO.montar`), com a chave a ×1,2 no pico. Na avalanche, o clarão da
  catástrofe: a chave a ×1,4 por 1 batida (`SECAO.degrau`).
- **O fundo:** a oficina da K1 (`SECAO.montar`), mais, por lugar, a bancada sem molde (`SECAO.bancada(self, l,
  false)`).
- **As peças Kenney:** `holiday-kit/snow-pile`, escala 0,5, na cabeça do líder soterrado por 4 s, em
  `p.global_position + (0; 1,95; 0)` (reserva: `stones`). Mais nada novo: o gelo é de caixas.
- **O bloco:** `Kit.caixa(2,2 × 0,5 × 1,0)` na placa, em `(0; 0,33; 0)`, `GRAFITE` fosco. O bloco duro: o mesmo
  em `JANELA`, com a coroa gravada em `MUDO` (uma barra de 0,36 × 0,05 e três dentes de 0,05 × 0,12, na borda da
  frente).
- **As rachaduras:** até cinco `Kit.caixa(0,03 × 0,02 × 0,8)`, em ângulos sorteados (±0,8 rad), na face de cima
  (`y = 0,59`); `FITA` no bloco comum, `MUDO` no duro. Uma aparece por racha.
- **A seta do lado:** `Kit.caixa(0,5 × 0,03 × 0,08)` e a ponta (duas de 0,2 × 0,03 × 0,06 a ±45°), em `ETIQUETA`,
  virada para o lado pedido, em `(0; 0,62; 0)` da placa.
- **A pilha do líder:** um bloco duro de 1,4 × 0,9 × 0,8 m por bloco na fila, empilhado em `(cx; 0,85; −0,9)`.
  Três blocos são 2,7 m, 1,5 vez o cavaleiro.
- **O bloco que voa:** 0,84 × 0,54 × 0,48 m em `JANELA`, em arco de 2,5 m de altura por 1 batida, com 4 faíscas da
  cor de quem mandou em 1/4, 1/2 e 3/4 do caminho.
- **O que brilha e de quem é:** os dois dedos (neon do jogador a 1,8 e 1,2); as faíscas do bloco quebrado (40, cor
  do jogador) e as do bloco que chega (24, cor de quem mandou). O gelo não brilha. A falha: 16 faíscas
  `TUNGSTENIO` na borda.
- **O quebrador:** o cavaleiro em `(RAIAS[l] − 1,45; 0,05; 0,35)`, de perfil, com o martelo na mão direita.
- **Nenhuma cor fora do tema:** nenhuma cor escrita em hexadecimal no arquivo.

## O som

Os ids são os do [mapa do áudio](../o-time/o-mapa-do-audio.md).

| evento | na TV | no controle do dono |
| --- | --- | --- |
| a rachadura | `tique` (`tique_0..2`, `sint_tique`), −4 dB, tom 1,6 (agudo, vidro) | Ressonância: a nota (o kit); bom e ótimo: `Forja.som_falante(l, "clique", 0.5)` (`mod_clique`) |
| o bloco quebra | `pedra` (`pedra_0..4`, só na TV), 0 dB | `Forja.som_falante(l, "coleta", 0.8)` (`mod_coleta`) |
| o bloco chega ao líder | `pedra`, −2 dB | nada no alto-falante: o gelo do líder é a textura nos atuadores (`mod_material_gelo`, H08) |
| a avalanche | `pedra`, +3 dB, tom 0,7 (grave) | em quem soltou o terceiro bloco: `Som.no_controle(l, "pedra", 0.9)` |
| a falha | a nota quebrada (o kit) | a nota quebrada (o kit) |

**A faixa:** `mus_s03_j12` (130 BPM, Fá# menor, a fazer). Até a H05, a sintetizada da seção a 100 bpm.

## O controle

| evento | vibração | háptica e alto-falante | luz | gatilho | para os outros |
| --- | --- | --- | --- | --- | --- |
| o dedo riscando | — | a textura `gelo` nos atuadores, a cada quarto de tempo (`SECAO.textura(l, "gelo")`) | — | R2 Off | nada |
| a rachadura | nenhuma do kit: a FICHA desliga a textura do acerto (`"textura_no_acerto": false`) | a racha corre na mão: `Forja.som_haptica` com `"pulso"` a 0,6 no atuador do lado de onde o dedo saiu e, 40 ms depois, no outro; se o `som_haptica` devolver −1, `Forja.sentir(l, "acerto")` no lugar dela | o kit | — | nada |
| o bloco quebra | o kit | `coleta` a 0,8 no alto-falante | o kit | — | o líder recebe o bloco 1 batida depois |
| o bloco chega | — | no líder: a textura `gelo` nos atuadores por 1 compasso (`frio_ate`, `SECAO.textura(l, "gelo")`, um atuador só, nunca junto do motor) | — | — | — |
| a avalanche | no líder: `Forja.sentir(l, "golpe")` (1,0/0,6/250 ms); nos outros (nem o líder, nem quem soltou): o forte de 0 a 1,0 em 600 ms, seis pulsos de 100 ms pela tabela: `toque`, `acerto`, `perfeito`, `aviso`, `erro`, `golpe` (`_rampa`) | em quem soltou: `pedra` a 0,9 no alto-falante | — | — | é para todos |
| a falha | o kit: 0,7/0,3/160 ms | a nota quebrada | o kit | — | nada |

**Sem o controle na mão:** o robô risca pelo `Forja.robo_tocar`; a prova lê a linha `sensacao` do golpe (F05) e as
`saida` de vibração da rampa (F06). O `som_haptica` devolve −1 quando o motor do lugar está vibrando (F05): a racha
não toca por cima do golpe, e o acerto cai para o `Forja.sentir(l, "acerto")`, que a prova lê como linha `sensacao`.

**O que espera ela:** nada. O touchpad lido pelo SDL basta; a regra udev do touchpad-mouse não muda esta ficha.

## O cavaleiro

O cavaleiro é o da montagem (G13), inteiro; o `martelo_na_mao` troca só a mão direita. Pode ser de outra raça: esta
ficha usa só o esqueleto comum e as animações `attack-melee-right` e `emote-no`. Na avalanche, o cavaleiro todo
some por 1 batida (`visible = false`) e volta com a neve na cabeça.

| stat | gancho | o que muda no Quebra-Gelo | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: ninguém é empurrado | — | — | — |
| Passo | `velocidade` | não age: o quebrador não anda | — | — | — |
| Fôlego | `levantar` | o soterrado da avalanche: sem nota por `2 tempos × levantar` | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | a seta do lado aparece antes: ela gira para o lado novo 1 aviso (`SECAO.aviso_s(l)`) antes da nota | −40 ms | 0 | +40 ms |

O Faro está no `_mostrar`: a seta mostra o lado da nota armada só a partir de 1 aviso (`SECAO.aviso_s(l)`) antes
dela; antes disso, o lado da nota anterior. Os itens: o Martelo e o Escudo são do kit; a Lanterna entra pelo
`SECAO.aviso_s`.

## As reações

- **Carimbos que o Quebra-Gelo pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do
  mesmo lugar), `car_virada` (do placar: quem passa a ser o líder), `car_por_um_fio` (no resultado) e
  `car_emburrado` (no inserto do resultado). O `car_acorde` não acontece: no hoqueto, ninguém toca no mesmo tempo 1.
- **Adesivos:** na seção 3, ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: a avalanche** (`avalanche`). Quando 3 ou mais blocos chegam ao líder no mesmo compasso (dois quebrando
juntos, na rajada, é comum), a pilha atrás dele desaba para a frente, ele some atrás do gelo por 1 batida e a cabeça
reaparece com neve. O "para, para!" de quem recebe é o grito. Degrau catástrofe: tremor de 0,08 m por 4 batidas,
chave +40 % por 1 batida, e o gelo empilhado tem 1,5 vez a altura do cavaleiro.

- **O rastro:** a pilha atrás do líder fica visível enquanto houver bloco na fila; a neve na cabeça dele, 4 s.
- **A curva:** de 0 a 25 s, uma por compasso, e os primeiros blocos duros chegam ao líder; de 25 a 50 s, a rajada,
  duas por compasso, e a avalanche aparece; de 50 s ao fim, uma por compasso, e nas últimas 16 batidas cada bloco
  conta 2 e manda 2.
- **Ensina sem falar:** o primeiro bloco que você quebra voa em arco, com faíscas da sua cor, até a placa do líder,
  e cai lá com som de pedra. A sala vê o primeiro voo antes de 10 s.
- **Quem está perdendo:** é o desenho inteiro. Quem está atrás joga contra quem está na frente, e a liderança custa.
  O último nunca recebe.
- **O que saiu:** o congelamento de 4 tempos na falha (4 tempos sem jogar é muito em 75 s).
- **A nota de hoje:** 2; com a troca, 4.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0; algum `enviados` > 0 antes de 10 s | um quadro antes de 10 s mostra um bloco no ar |
| 4. o momento | pelo menos 1 linha `momento` `avalanche` com `t_musica` entre 25 e 75 | um quadro do pico mostra 3 ou mais blocos atrás do P1 |
| 5. a curva | notas por segundo de 25 a 50 s ≥ 1,8 × as de 0 a 25 s; a linha `momento` `reta` existe | o quadro de 40 s tem a câmera mais longe que o de 15 s |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | 1 quadro em 5 mostra as faíscas de tungstênio na placa do P4 |
| 7. quem perde joga | o P4 nunca tem `recebidos` > 0 enquanto é o último; a maior distância entre duas `nota` seguidas de cada lugar é de até 8 batidas (o soterrado incluso) | o P4 aparece em 100 % dos quadros de jogo, menos a batida em que some, se for líder |
| 8. a câmera | cada `avalanche` tem 0,1 ≤ `x_tela` ≤ 0,9 e `altura_tela` ≥ 0,1 | a pilha se vê inteira no quadro de 480 × 270 |
| 9. o impacto | para cada `avalanche`, uma linha `sensacao` `golpe` do mesmo lugar a até 16,7 ms | o quadro seguinte mostra a pilha caída ou a neve |
| 10. o placar no mundo | a ordem do `vencedor()` bate com `quebrados` no `momento` `reta` e no fim | a pilha atrás do líder diz quem lidera |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova roda com o `--robo` da
`prova_do_jogo.sh` (sem valor: o `bom` nos quatro) e confere os itens 1, 4, 5, 8, 9 e 10; os itens 6 e 7 esperam. Se a
semente 7 der menos de 1 avalanche entre 25 e 75 s, mostre o registro e não mude a semente nem o mínimo.

## Pronto quando

O Quebra-Gelo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos. O cabo que cai
e volta não perde blocos. Cada bloco quebrado vai ao líder (nunca a si, nunca no empate), e a avalanche acontece no
registro entre 25 e 75 s. O fim tem sempre vencedor. `SALA=S03_J12 bash tests/prova_do_jogo.sh` e
`bash tests/prova_visual.sh` passam, com a prancha olhada. O catálogo e as traduções têm as linhas desta ficha, o
`.uid` está no commit, e o commit, sem trailer, é
`feat(quebra-gelo): o risco no contratempo, o gelo que vai para o líder e a avalanche`.

## Provas

Na sessão: `SALA=S03_J12 bash tests/prova_do_jogo.sh`, `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### `godot/testes/prova_do_jogo.gd`

No `match` de `_prova_da_ficha`: `"S03_J12": await _prova_do_quebra_gelo()`.

```gdscript
## O Quebra-Gelo (S03_J12): o risco de cada lugar chega julgado; os blocos vão ao
## líder e nunca a si; a avalanche aparece entre 25 e 75 s; a rajada dobra as notas.
func _prova_do_quebra_gelo() -> void:
	var a_si := [false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.j:
			if int(mg.j[l].ultimo_de) == int(l):
				a_si[0] = true
	var mg = await _joga_o_minigame("S03_J12", 115.0, olhar)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[2]) + int(c[3]) >= 1, "Quebra-Gelo P%d: riscou no contratempo %s" % [l + 1, c])
	var env := 0
	var rec := 0
	for l in 4:
		env += int(mg.j[l].enviados)
		rec += int(mg.j[l].recebidos)
	_esperar(env >= 5 and rec >= env - 2, "Quebra-Gelo: %d blocos mandados, %d chegaram" % [env, rec])
	_esperar(not a_si[0], "Quebra-Gelo: ninguém recebeu o próprio bloco")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S03_J12")
	var aval := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "avalanche")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	var no_meio := aval.filter(func(e): return float(e.t_musica) >= 25.0 and float(e.t_musica) <= 75.0)
	_esperar(no_meio.size() >= 1, "Quebra-Gelo: %d avalanches entre 25 e 75 s (o mínimo é 1)" % no_meio.size())
	_esperar(reta.size() == 1, "Quebra-Gelo: a linha momento reta aparece uma vez")
	for a in aval:
		var x := float(a.get("x_tela", 0.0))
		_esperar(x >= 0.1 and x <= 0.9 and float(a.get("altura_tela", 0.0)) >= 0.1, "Quebra-Gelo: a avalanche na tela (%s)" % [a])
	var notas := linhas.filter(func(e): return e.get("tipo") == "nota")
	var cedo := notas.filter(func(e): return float(e.get("t_musica", 0.0)) < 25.0).size() / 25.0
	var rajada := notas.filter(func(e): var t := float(e.get("t_musica", 0.0)); return t >= 25.0 and t < 50.0).size() / 25.0
	_esperar(rajada >= 1.8 * cedo, "Quebra-Gelo: a rajada (%.2f notas/s contra %.2f)" % [rajada, cedo])
```

O "nunca a si" se garante no código (`lider != l`), e a prova o confere a cada quadro pelo `ultimo_de` de cada lugar.
A soma de `recebidos` acompanha a de `enviados`, com até 2 ainda no ar no fim.

### O que o registro mede

- O kit: `nota` e `toque` (o risco completo contra o contratempo).
- A linha `entrada` em cada risco: de onde a onde o dedo andou (`de_x`, `ate_x`) e em quantos ms. Um touchpad que
  perde amostras (o risco pula de uma ponta à outra em 0 ms) ou que corta uma borda (o `ate_x` nunca passa de 0,8)
  aparece aqui.
- A `momento` `avalanche` (`blocos`, `de`, `x_tela`, `altura_tela`) e a `reta` (`ordem`).

### As pranchas que o jogador do time olha

- antes de 10 s: o primeiro bloco no ar, com as faíscas da cor de quem mandou;
- de 25 a 50 s: a pilha atrás do líder com 3 ou mais blocos, e o quadro da avalanche (a pilha caída, o líder sumido);
- os 4 s seguintes: a neve na cabeça do líder;
- nas últimas 16 batidas: dois blocos voando por quebra.

### O que o André joga e sente

`./run-local.sh -- --sala=S03_J12`: o risco no "e" se sente como vidro; alternar o lado é natural; a racha corre na
mão do lado certo; o líder sente cada bloco que chega; e a avalanche faz a sala gritar.

### Armadilhas

- **O risco começa no encostar:** `x0` é onde o dedo encostou; levantar zera. Riscar de volta sem levantar não conta
  como o lado novo.
- **O `n` sobe uma vez por nota** (no `toque`, na `falha` e na perdida): nunca no `_proxima`.
- **O soterrado só empurra as notas seguintes** (`_proxima` começa depois dele); a nota já armada continua.
- **A seta gira em `y` local da placa** (inclinada): `rotation.y` do nó dentro da placa, nunca global.
- **A chegada conta por "lugar:compasso"**: o líder pode mudar no meio do voo; o bloco vai para quem era o líder
  quando quebrou.
- **O `_mandar` na reta manda 2**, com 1/4 de batida entre eles: os dois chegam no mesmo compasso.
