# J3 — Patinação de Dados

**Sprint:** J · **Slot:** S02_J08 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, G05, G14, J1 (o `secao.gd`)

## Por quê

Deslizar é dirigir com o corpo numa pista de todos: a inclinação contínua
do controle leva o patinador pelo gelo até o dado dele, na batida, e os
outros três estão no caminho. O ângulo pedido contra o feito, nota a nota,
e a trombada como grito.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H08 — Os acréscimos do kit](H08-os-acrescimos-do-kit.md) (a fila de notas, `anotar`, `andamento`, `tempo_que_resta`)
- [J1 — O secao.gd](J1-a-viga.md#o-secaogd) (a caverna, `agendar`, `momento`, `gancho`, `levantar`, `pista_s`)

## Arquivos que mudam

| arquivo | o que muda | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s02/patinacao_de_dados.gd` | **novo**: o minigame | não |
| `godot/scripts/minigames/catalogo.gd` | o slot `S02_J08` | sim: as cinco |
| `godot/scripts/traducoes.gd` | o título, o verbo e o status | sim: as cinco |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_patinacao()` e a linha no `_prova_da_ficha` | sim: as cinco |
| `godot/testes/captura_jogo.gd` | os momentos de `"S02_J08"` | sim: as cinco |

O `secao.gd`, `"momento"` em `TIPOS_DO_JOGO`, a linha `momento` no 13 e o
`_linhas_do_minigame()` da prova são da J1: esta ficha só os usa.

### O estado de hoje

Não existe `patinacao_de_dados.gd`. A ficha anterior era a versão de quatro
lajes com três trilhas cada, o dado em `Tema.CIANO` e o gelo `#bfe6ff`:
nenhum segundo de contato entre os jogadores. **A troca (a diversão, J3):
a pista de todos.** Uma laje só, cinco trilhas, os quatro patinando nela;
a inclinação passa a dirigir a velocidade (não a posição), e a trombada
entra.

| antes | depois |
| --- | --- |
| quatro lajes, três trilhas | uma laje 6 × 10 m, cinco trilhas |
| a inclinação é a posição | a inclinação é a velocidade (até 7 m/s), com zona morta |
| o dado `CIANO` | o dado na cor do dono; o dado branco de ninguém no pico |
| ninguém se encosta | a trombada: os dois giram, e a nota de quem ia para lá se perde |

### Ao terminar

1. `godot/scripts/minigames/catalogo.gd`: em `MINIGAMES`,
   `"S02_J08": preload("res://scripts/minigames/s02/patinacao_de_dados.gd")`;
   na lista `minigames` da S02, `"S02_J08"` logo depois de `"S02_J07"`.
2. `godot/scripts/traducoes.gd`: `"Patinação de Dados": "Data Skating"`,
   `"Deslize!": "Glide!"`; em `EN_PADROES`, `["^Dados: (\\d+)$", "Dice: $1"]`.
3. `godot/testes/prova_do_jogo.gd` e `godot/testes/captura_jogo.gd`: o que
   está em **Provas**.
4. `"$GODOT" --headless --path godot --import --quit`; o
   `patinacao_de_dados.gd.uid` entra no commit.
5. O quadro sai do cabeçalho desta ficha: nada a editar nele.
6. Commit (sem trailer): `feat(patinacao): a Patinação de Dados na pista de todos, com a trombada e o dado branco`.

## Como se joga

- **A faixa:** `MUS_S02_J08`. Até a H05, a sintetizada da seção a 96 BPM;
  com a gerada, `mus_s02_j08` a 128 BPM (deslize contínuo, portamento).
- **A pista de todos:** uma laje de gelo de 6 × 10 m sobre a lava, com cinco
  trilhas em `x = −2,2; −1,1; 0; 1,1; 2,2`. Os quatro patinam na mesma linha
  (`z = Z_JOGADOR`, 1,4) e começam entre as trilhas, em `x = −1,65; −0,55;
  0,55; 1,65` (P1 a P4).
- **A inclinação dirige a velocidade:** `v = 7,0 m/s × velocidade × clamp(r / 0,35; −1; 1)`,
  com `r` a rolagem menos o zero, e 0,02 rad de zona morta. O gelo desliza:
  a velocidade chega à pedida por `1 − exp(−12 · Δt)` em tempo de música. A
  parede da laje segura em `|x| = 2,6`.
- **O zero:** na batida `4 + 16f` (o começo de cada frase), se a rolagem
  está a menos de 0,1 rad do zero, ela vira o zero novo (a mão em repouso
  recentra o giroscópio que deriva).
- **Os dados:** cubos de 0,4 m na cor do dono vêm pela laje, 2 m por tempo
  (3 no pico), e chegam à linha dos patinadores na batida deles. O hoqueto em
  colcheias: o dado do lugar `l` chega em `2k + 0,5·l`. `Ritmo.simples[l]`:
  um a cada 4 tempos. A trilha do dado brilha na cor do dono 1 tempo antes
  (mais o Faro).
- **A nota:** o patinador **entra** na trilha do dado (fica a menos de 0,35 m
  dela) dentro da janela que abre meio tempo antes: `julgar_toque`. Já
  estava lá quando a janela abriu: julga ali (adiantado). Não chegou até
  `FOLGA_PERDIDA` (0,140 s) depois: nota perdida.
- **A falha:** passou da nota, gira no gelo: uma volta inteira em 1 tempo ×
  `levantar`, e enquanto gira a inclinação não dirige.
- **A trombada:** dois patinadores a menos de 0,4 m um do outro se agarram
  até a colcheia seguinte; ali, os dois giram uma volta em 1 tempo ×
  `levantar` e deslizam 0,6 m cada para longe do outro. A nota de quem
  estava indo na direção do outro, com a batida a 1 tempo ou menos, é
  perdida. O par não volta a trombar enquanto algum dos dois gira.
- **O dado branco**, no pico: um dado de ninguém no tempo 1 de cada
  compasso, numa trilha onde nenhum dado chega a menos de meio tempo dele.
  Quem estiver na trilha dele (0,35 m) primeiro, de `FOLGA_PERDIDA` antes a
  `FOLGA_PERDIDA` depois da batida, leva: vale 2 dados e 70 pontos. Não é
  nota de ninguém: não tem erro.
- **Os pontos** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`. Cada dado
  BOM ou melhor é **coletado**.

### A curva

Os terços de 90 s: 30 s e 60 s (`andamento()` 1/3 e 2/3).

| trecho | os dados | a trilha | o mundo |
| --- | --- | --- | --- |
| 0 a 30 s | um a cada 2 tempos, 2 m por tempo | `l + (m % 2)` (`m` o número do dado do lugar): o P1 nas trilhas 0 e 1, o P2 em 1 e 2…; dois vizinhos nunca querem a trilha comum no mesmo dado | ninguém tromba sem querer |
| 30 a 60 s, a descida | um por tempo (`k + 0,25·l`), 3 m por tempo | sorteada, a 1 ou 2 trilhas da anterior do lugar | o dado branco a cada compasso; a lava sobe a 1,0 e a câmera recua 10 % em 2 batidas |
| 60 s ao fim, a reta | um a cada 2 tempos, 2 m por tempo | sorteada, a 1 ou 2 trilhas da anterior | — |
| as últimas 16 batidas | igual à reta | igual | o dado branco a cada 2 batidas; cada dado vale 2; a linha `momento` `reta` |

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J08",
	"titulo": "Patinação de Dados",
	"verbo": "Deslize!",
	"genero": "corrida",
	"icone": "giroscopio",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J08",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe_esq", "golpe_dir"],
	"material": "gelo",
	"microjogo": {"verbo": "Deslize!", "segundos": 6.0},
}
```

### O fim e o vencedor

90 s de música. `vencedor()`: mais dados coletados; empate pelos pontos,
depois pelo lugar.

### Com menos de quatro

As mesmas cinco trilhas; com menos gente, menos trombada. **O controle que
cai:** o patinador dele para onde está (a velocidade vai a 0), os dados que
vinham apagam sem erro, e ele ainda tromba (é um corpo no gelo); ao voltar,
o próximo dado chega na batida dele pelo menos 2 tempos adiante. **Sem
giroscópio:** a rolagem pela gravidade; sem nada, o analógico esquerdo
(`SECAO.rolagem`); a linha `troca` diz qual.

### Os ganchos

`godot/scripts/minigames/s02/patinacao_de_dados.gd`:

```gdscript
extends Minigame
## Patinação de Dados (S02_J08). Os quatro patinam numa laje de gelo só, com
## cinco trilhas; a inclinação do controle dirige a velocidade. Os dados de
## cada um vêm pela laje e chegam na batida do lugar (o hoqueto em
## colcheias), cada um numa trilha: entrar na trilha no tempo o coleta. Dois
## patinadores que se encostam trombam e giram. No meio, a descida: um dado
## por tempo e o dado branco de ninguém a cada compasso.
##
## A falha: passou da nota, gira no gelo por um tempo.
## O vencedor: mais dados coletados.
## O alto-falante do dono: a coleta no acerto, a nota no perfeito.
## O registro mede: a trilha pedida contra a posição e a inclinação feitas em
## cada dado (a linha `entrada`), o atraso (o kit), a trombada e a reta (a
## linha `momento`).
## O robô: inclina para a trilha do próprio dado (ou do branco, se vem antes)
## 1 tempo antes (ou 200 ms atrasado); não desvia de ninguém.
## Com menos de quatro: as mesmas cinco trilhas.
## A régua: "Deslize!" e o giroscópio bastam; sem a tela, o gelo chia na mão
## e a borda arranha; a trilha é visual; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const TRILHAS := [-2.2, -1.1, 0.0, 1.1, 2.2]
const INICIO := [-1.65, -0.55, 0.55, 1.65]
const PAREDE := 2.6
const BORDA := 2.34  ## 90 % da parede: o cascalho
const V_MAX := 7.0  ## m/s com a inclinação cheia
const ROLAGEM_CHEIA := 0.35
const ZONA_MORTA := 0.02
const DESLIZE := 12.0  ## por segundo de música
const NA_TRILHA := 0.35
const ENCOSTA := 0.4  ## m: a trombada
const EMPURRA := 0.6  ## m que cada um desliza na trombada
const VELOCIDADE := 2.0  ## m por tempo
const VELOCIDADE_PICO := 3.0
const N_DADOS := 6
const PONTOS := [0, 20, 35, 50]
const BRANCO := 70
const Z_PILHA := -5.4
const CAMERA := Vector3(0, 6.3, 10.9)
const OLHAR := Vector3(0, 0.3, 0.5)

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var brancos := []  ## [{b, x, no}]
var _b_branco := -1.0
var _primeiro_branco := true
var _b_ant := 0.0
var _reta := false
var _coroa: Node3D
var _espirais := []


func montar() -> void:
	SECAO.limpar()
	camera_pos = CAMERA
	camera_olhar = OLHAR
	SECAO.montar(self)
	var gelo := Kit.material(Tema.SECAO[1], 0.0, 0.15)
	Kit.caixa(self, Vector3(6.0, 0.15, 10.0), Vector3(0, 0.0, 0.5), gelo)
	var linha := Kit.chapado(Tema.ETIQUETA_SOMBRA)
	for x in [-1.65, -0.55, 0.55, 1.65]:
		Kit.caixa(self, Vector3(0.04, 0.02, 10.0), Vector3(x, 0.09, 0.5), linha)
	for x in [-PAREDE - 0.1, PAREDE + 0.1]:
		Kit.caixa(self, Vector3(0.2, 0.3, 10.0), Vector3(x, 0.15, 0.5), Kit.material(Tema.GRAFITE, 0.0, 0.9))
		SECAO.pilar(self, x, -4.0)
		SECAO.pilar(self, x, 5.0)
	_coroa = Node3D.new()
	add_child(_coroa)
	Kit.cilindro(_coroa, 0.16, 0.14, Vector3.ZERO, Kit.material(Tema.TUNGSTENIO, 1.0, 0.4), 0.22)
	_coroa.visible = false
	for p in jogadores:
		var l: int = p.lugar
		var nos: Array = []
		for i in N_DADOS:
			var d := Kit.caixa(self, Vector3(0.4, 0.4, 0.4), Vector3(0, 0.3, -8.0), Kit.material(Tema.JOGADOR[l], 1.6))
			d.visible = false
			nos.append(d)
		var faixa := Kit.caixa(self, Vector3(0.3, 0.01, 4.0), Vector3(0, 0.085 + 0.003 * l, Z_JOGADOR - 2.0), Kit.material(Tema.JOGADOR[l], 0.8))
		faixa.visible = false
		var pilha := Node3D.new()
		pilha.position = Vector3(-2.4 + 1.6 * l, 0.0, Z_PILHA)
		add_child(pilha)
		maos_livres(p)
		p.preso = true
		p.position = Vector3(INICIO[l], 0.08, Z_JOGADOR)
		p.rotation.y = PI
		j[l] = {"dados": [], "nos": nos, "faixa": faixa, "pilha": pilha, "n_prox": 0, "b_prox": -1.0,
			"trilha": 1 + l, "x": INICIO[l], "v": 0.0, "zero": 0.0, "t_antes": 0.0, "aberta": false,
			"dentro": false, "gira_b": -99.0, "gira_t": 1.0, "agarrado": false, "trombou_t": -1.0,
			"coletados": 0, "fora": false, "robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _ultimas_16() -> bool:
	return tempo_que_resta() <= 16.0 * 60.0 / Ritmo.bpm


func _proxima_batida(l: int, b: float) -> float:
	var passo := 2.0
	var desloc := 0.5 * l
	if no_pico() and not Ritmo.simples[l]:
		passo = 1.0
		desloc = 0.25 * l
	return proxima_batida(l, b, passo, desloc)  # o kit dobra o passo na partitura simples


## A trilha do dado `m` do lugar: no primeiro terço, as duas dele; depois,
## sorteada a 1 ou 2 trilhas da anterior.
func _trilha(l: int, m: int) -> int:
	var e: Dictionary = j[l]
	if andamento() < 1.0 / 3.0:
		return l + (m % 2)
	var t := int(e.trilha)
	var opcoes := []
	for d in [-2, -1, 1, 2]:
		if t + d >= 0 and t + d < TRILHAS.size():
			opcoes.append(t + d)
	return int(opcoes[rng.randi_range(0, opcoes.size() - 1)])


## Os dados nascem 6 tempos antes da batida deles.
func _nascer(l: int) -> void:
	var e: Dictionary = j[l]
	while float(e.b_prox) > 0.0 and float(e.b_prox) <= Ritmo.batida() + 6.0 and e.dados.size() < N_DADOS:
		var t := _trilha(l, int(e.n_prox))
		e.trilha = t
		var d := {"n": int(e.n_prox), "b": float(e.b_prox), "x": TRILHAS[t], "vel": VELOCIDADE_PICO if no_pico() else VELOCIDADE}
		e.dados.append(d)
		nova_nota(l, int(d.n), Ritmo.t_da_batida(float(d.b)))
		e.n_prox = int(e.n_prox) + 1
		e.b_prox = _proxima_batida(l, float(e.b_prox))


## O dado branco: no pico, no tempo 1 de cada compasso; nas últimas 16
## batidas, a cada 2 batidas. Nasce 6 tempos antes, numa trilha de ninguém.
func _nascer_branco() -> void:
	var passo := 0.0
	if no_pico():
		passo = 4.0
	elif _ultimas_16():
		passo = 2.0
	if passo == 0.0:
		_b_branco = -1.0
		return
	if _b_branco < 0.0:
		_b_branco = BATIDA_DA_PRIMEIRA_NOTA + passo * ceilf((Ritmo.batida() + 6.0 - BATIDA_DA_PRIMEIRA_NOTA) / passo)
	while _b_branco <= Ritmo.batida() + 6.0:
		var livres := []
		for t in TRILHAS.size():
			var ocupada := false
			for l in j:
				for d in j[l].dados:
					if absf(float(d.b) - _b_branco) < 0.5 and is_equal_approx(float(d.x), TRILHAS[t]):
						ocupada = true
			if not ocupada:
				livres.append(t)
		if not livres.is_empty():
			var t := int(livres[rng.randi_range(0, livres.size() - 1)])
			var no := Kit.caixa(self, Vector3(0.4, 0.4, 0.4), Vector3(TRILHAS[t], 0.3, -8.0), Kit.material(Tema.ETIQUETA, 1.2))
			brancos.append({"b": _b_branco, "x": TRILHAS[t], "no": no, "primeiro": _primeiro_branco})
			_primeiro_branco = false
		_b_branco += passo


func iniciar_jogo() -> void:
	_b_ant = Ritmo.batida()
	for l in presentes():
		SECAO.anotar_troca(self, l)
		j[l].t_antes = Ritmo.t_musica()
		j[l].zero = SECAO.rolagem(l)
		j[l].b_prox = _proxima_batida(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
	SECAO.pulsos()
	var agora := Ritmo.t_musica()
	var b := Ritmo.batida()
	var pico := SECAO.pico_suave(self)
	camera_pos = OLHAR + (CAMERA - OLHAR) * (1.0 + 0.1 * pico)
	SECAO.lava(self, 0.6 + 0.4 * pico)
	if floor(b * 2.0) > floor(_b_ant * 2.0):
		for l in presentes():
			_colcheia(l, floor(b * 2.0) / 2.0)
	_b_ant = b
	if not _reta and _ultimas_16():
		_reta = true
		SECAO.momento(self, "reta", -1, Vector3(0, 0, Z_PILHA), 1.6, {"ordem": vencedor(), "objeto": "pilhas"})
	_nascer_branco()
	for l in presentes():
		var e: Dictionary = j[l]
		_deslizar(l, e, agora)
		_mostrar(l)
		if acabou[l]:
			continue
		if not conectado(l):
			if not bool(e.fora):
				e.fora = true
				e.dados.clear()  # apagam sem erro
			continue
		if bool(e.fora):
			e.fora = false
			e.b_prox = _proxima_batida(l, Ritmo.batida() + 2.0)
		_nascer(l)
		_nota(l, e, agora)
	_trombadas()
	_brancos(agora)
	_mostrar_mundo()


## A cada colcheia: o zero no começo da frase, o gelo que chia e a borda.
func _colcheia(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	if fmod(b - BATIDA_DA_PRIMEIRA_NOTA, 16.0) == 0.0 and absf(SECAO.rolagem(l) - float(e.zero)) < 0.1:
		e.zero = SECAO.rolagem(l)
		anotar("entrada", l, {"o": "zero", "zero": snappedf(float(e.zero), 0.01)})
	var rapido := absf(float(e.v)) / V_MAX
	if rapido > 0.07 and not _borda(l):
		Forja.textura(l, "gelo", 0.15 + 0.35 * clampf(rapido, 0.0, 1.0))


## A borda (90 % da parede): o cascalho no atuador do lado dela.
func _borda(l: int) -> bool:
	var e: Dictionary = j[l]
	if absf(float(e.x)) < BORDA:
		return false
	var som := "passo:1:%d" % (int(Ritmo.batida() * 2.0) % 3)
	var esq := float(e.x) < 0.0
	Forja.som_haptica(l, som if esq else "", "" if esq else som, 0.5)
	anotar("pista", l, {"canal": "haptica", "o": "borda", "lado": -1 if esq else 1})
	return true


## O patinador desliza pela inclinação (girando ou agarrado, não).
func _deslizar(l: int, e: Dictionary, agora: float) -> void:
	var passou := agora - float(e.t_antes)
	e.t_antes = agora
	var quer := 0.0
	var girando := Ritmo.batida() - float(e.gira_b) < float(e.gira_t)
	if conectado(l) and not girando and not bool(e.agarrado):
		var r := SECAO.rolagem(l) - float(e.zero)
		r = signf(r) * maxf(absf(r) - ZONA_MORTA, 0.0)
		quer = V_MAX * SECAO.gancho(l, "velocidade") * clampf(r / ROLAGEM_CHEIA, -1.0, 1.0)
	e.v = float(e.v) + (quer - float(e.v)) * (1.0 - exp(-DESLIZE * passou))
	if bool(e.agarrado):
		e.v = 0.0
	e.x = clampf(float(e.x) + float(e.v) * passou, -PAREDE, PAREDE)


func _nota(l: int, e: Dictionary, agora: float) -> void:
	if e.dados.is_empty():
		return
	var d: Dictionary = e.dados[0]
	var alvo := Ritmo.t_da_batida(float(d.b))
	var dentro := absf(float(e.x) - float(d.x)) < NA_TRILHA
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.dentro = dentro
		return
	var entrou := dentro and (not bool(e.dentro) or not bool(e.aberta))
	e.aberta = true
	e.dentro = dentro
	if entrou:
		anotar("entrada", l, {"o": "rolagem", "pedido_x": d.x, "feito_x": snappedf(float(e.x), 0.01),
			"rolagem": snappedf(SECAO.rolagem(l) - float(e.zero), 0.01), "n": int(d.n)})
		julgar_toque(l, alvo, int(d.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(d.n))


func _seguinte(l: int) -> void:
	var e: Dictionary = j[l]
	if not e.dados.is_empty():
		e.dados.pop_front()
	e.aberta = false
	e.dentro = false


func _coletar(l: int, quantos: int) -> void:
	var e: Dictionary = j[l]
	var antes := int(e.coletados) / 4
	e.coletados = int(e.coletados) + quantos
	for i in range(antes, int(e.coletados) / 4):  # a pilha: um bloco a cada 4 dados
		Kit.caixa(e.pilha, Vector3(0.3, 0.1, 0.3), Vector3(0, 0.05 + 0.1 * i, 0), Kit.material(Tema.JOGADOR[l], 0.6))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var dobro := 2 if _ultimas_16() else 1
	marcar(l, int(PONTOS[julgamento]) * dobro)
	if not treinando:
		_coletar(l, dobro)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "coleta", 0.5)
	var p := jogador(l)
	if p:
		Som.tocar("tique", p.global_position + Vector3(0, 0.5, 0), -4.0, 1.4)
		Efeitos.faiscas(self, p.global_position + Vector3(0, 0.5, 0), Tema.JOGADOR[l], 16, 0.7)
	_seguinte(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	_girar(l)
	var p := jogador(l)
	if p:
		Som.tocar("vento", p.global_position, -12.0)
	_seguinte(l)


func _girar(l: int) -> void:
	j[l].gira_b = Ritmo.batida()
	j[l].gira_t = SECAO.levantar(l, 1.0)


## Quem se encosta se agarra até a colcheia seguinte; ali, a trombada.
func _trombadas() -> void:
	var ls := presentes()
	for i in ls.size():
		for k in range(i + 1, ls.size()):
			var a: int = ls[i]
			var b: int = ls[k]
			var ea: Dictionary = j[a]
			var eb: Dictionary = j[b]
			if bool(ea.agarrado) or bool(eb.agarrado):
				continue
			if Ritmo.batida() - float(ea.gira_b) < float(ea.gira_t) or Ritmo.batida() - float(eb.gira_b) < float(eb.gira_t):
				continue
			if absf(float(ea.x) - float(eb.x)) < ENCOSTA:
				ea.agarrado = true
				eb.agarrado = true
				var colcheia := ceilf(Ritmo.batida() * 2.0 + 0.001) / 2.0
				SECAO.agendar(Ritmo.t_da_batida(colcheia), _trombada.bind(a, b))


## O grito: os dois giram, deslizam para lados opostos, e a espiral fica no gelo.
func _trombada(a: int, b: int) -> void:
	var ea: Dictionary = j[a]
	var eb: Dictionary = j[b]
	ea.agarrado = false
	eb.agarrado = false
	var esq := a if float(ea.x) <= float(eb.x) else b  # o da esquerda leva o golpe pela direita
	var dir := b if esq == a else a
	var meio := (float(ea.x) + float(eb.x)) * 0.5
	for par in [[esq, -1.0, "golpe_dir"], [dir, 1.0, "golpe_esq"]]:
		var l: int = par[0]
		var e: Dictionary = j[l]
		var outro := dir if l == esq else esq
		# a nota de quem ia na direção do outro, a 1 tempo ou menos, se perde
		if not e.dados.is_empty():
			var d: Dictionary = e.dados[0]
			var falta := float(d.b) - Ritmo.batida()
			if falta <= 1.0 and signf(float(d.x) - float(e.x)) == signf(float(j[outro].x) - float(e.x)):
				nota_perdida(l, int(d.n))
		_girar(l)
		e.x = clampf(float(e.x) + float(par[1]) * EMPURRA, -PAREDE, PAREDE)
		e.v = 0.0
		e.trombou_t = Ritmo.t_musica()
		Forja.sentir(l, str(par[2]), 60)
	var onde := Vector3(meio, 0.1, Z_JOGADOR)
	Som.tocar("golpe", onde, -2.0)
	tremer(Sala.TREMOR_EXPLOSAO)
	var nos := []
	for l in [a, b]:
		if jogador(l):
			nos.append(jogador(l))
	SECAO.parar(nos, 3)
	_espiral(onde)
	SECAO.momento(self, "trombada", a, onde, 1.6, {"a": a, "b": b})


## O rastro: dois arcos de patim em espiral, 12 traços, por 4 s.
func _espiral(onde: Vector3) -> void:
	var n := Node3D.new()
	n.position = onde + Vector3(0, -0.015, 0)
	add_child(n)
	var mat := Kit.chapado(Tema.ETIQUETA_SOMBRA)
	for lado in [-1.0, 1.0]:
		for i in 6:
			var ang := lado * (0.6 * i)
			var r := 0.15 + 0.12 * i
			var traco := Kit.caixa(n, Vector3(0.05, 0.005, 0.22), Vector3(lado * r * cos(ang), 0, r * sin(ang)), mat)
			traco.rotation.y = -ang
	_espirais.append(n)
	SECAO.agendar(Ritmo.t_musica() + 4.0, func() -> void:
		_espirais.erase(n)
		if is_instance_valid(n):
			n.queue_free())


## O dado branco: quem estiver na trilha dele primeiro, na janela, leva 2.
func _brancos(agora: float) -> void:
	for i in range(brancos.size() - 1, -1, -1):
		var br: Dictionary = brancos[i]
		var alvo := Ritmo.t_da_batida(float(br.b))
		if agora > alvo + FOLGA_PERDIDA:
			(br.no as Node3D).queue_free()
			brancos.remove_at(i)
			continue
		if agora < alvo - FOLGA_PERDIDA:
			continue
		for l in presentes():
			if not conectado(l) or acabou[l] or absf(float(j[l].x) - float(br.x)) >= NA_TRILHA:
				continue
			marcar(l, BRANCO)
			if not treinando:
				_coletar(l, 2)
			Forja.som_falante(l, "coleta", 0.6)
			Efeitos.faiscas(self, (br.no as Node3D).global_position, Tema.ETIQUETA, 16, 0.7)
			anotar("entrada", l, {"o": "branco", "x": br.x, "t": snappedf(agora - alvo, 0.001)})
			(br.no as Node3D).queue_free()
			brancos.remove_at(i)
			break


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var agora_b := Ritmo.batida()
	var nos: Array = e.nos
	for i in N_DADOS:
		var no: MeshInstance3D = nos[i]
		if i >= e.dados.size() or fase != "jogo":
			no.visible = false
			continue
		var d: Dictionary = e.dados[i]
		var z: float = Z_JOGADOR - (float(d.b) - agora_b) * float(d.vel)
		no.visible = z > -4.5
		no.position = Vector3(float(d.x), 0.3, z)
		no.rotation.y = agora_b * PI * 0.5
	var faixa: Node3D = e.faixa
	faixa.visible = false
	if not e.dados.is_empty() and fase == "jogo":
		var d: Dictionary = e.dados[0]
		var antes := 1.0 + SECAO.pista_s(l) * Ritmo.bpm / 60.0
		faixa.visible = float(d.b) - agora_b <= antes
		faixa.position.x = float(d.x)
	var p := jogador(l)
	if p == null or p.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	p.position = Vector3(float(e.x), 0.08, Z_JOGADOR)
	if p.modelo:
		var giro := clampf((agora_b - float(e.gira_b)) / float(e.gira_t), 0.0, 1.0)
		p.modelo.rotation.y = TAU * giro if giro < 1.0 else 0.0
		p.modelo.rotation.z = -float(e.v) / V_MAX * 0.35 * 0.6
	p.animar("walk" if fase == "jogo" else "idle", 0.4)


## Os brancos que vêm, e a coroa no líder.
func _mostrar_mundo() -> void:
	var agora_b := Ritmo.batida()
	for br in brancos:
		var no: Node3D = br.no
		var z: float = Z_JOGADOR - (float(br.b) - agora_b) * VELOCIDADE_PICO
		no.visible = fase == "jogo" and (z > -4.5 or (bool(br.primeiro) and z > -4.5 - 2.0 * VELOCIDADE_PICO))
		# o primeiro aparece parado no alto 2 batidas antes de entrar na laje
		no.position = Vector3(float(br.x), 0.3 if z > -4.5 else 1.5, maxf(z, -4.5))
		no.rotation.y = agora_b * PI * 0.5
	var ordem := vencedor()
	var lider := int(ordem[0]) if not ordem.is_empty() else -1
	_coroa.visible = lider >= 0 and int(j[lider].coletados) > 0 and fase == "jogo"
	if _coroa.visible:
		_coroa.position = Vector3(float(j[lider].x), 2.1, Z_JOGADOR)


## Quem está girando está fora da rodada (arte/09).
func fora_da_rodada(l: int) -> bool:
	return j.has(l) and Ritmo.batida() - float(j[l].gira_b) < float(j[l].gira_t)


func ao_terminar() -> void:
	for p in jogadores:
		if p.modelo:
			p.modelo.rotation = Vector3.ZERO


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].coletados) != int(j[b].coletados):
		return int(j[a].coletados) > int(j[b].coletados)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Dados: %d" % int(j[lugar].coletados)
	return super(lugar)
```

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var alvo_x := float(e.x)
	var alvo_b := INF
	if not e.dados.is_empty():
		var d: Dictionary = e.dados[0]
		if int(e.robo_n) != int(d.n):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			e.robo_n = int(d.n)
			e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		alvo_b = float(d.b)
		alvo_x = float(d.x)
	for br in brancos:  # o branco, se chega antes do próprio dado
		if float(br.b) < alvo_b and float(br.b) >= Ritmo.batida():
			alvo_b = float(br.b)
			alvo_x = float(br.x)
	var tempo := 60.0 / Ritmo.bpm
	var rol := 0.0
	if alvo_b < INF and Ritmo.t_musica() >= Ritmo.t_da_batida(alvo_b) + float(e.robo_mira) - tempo:
		# inclina proporcional à distância: chega e para (não desvia de ninguém)
		var quer_v := clampf((alvo_x - float(e.x)) * 6.0, -V_MAX, V_MAX)
		rol = quer_v / V_MAX * ROLAGEM_CHEIA + signf(quer_v) * ZONA_MORTA
	Forja.robo_girar(l, SECAO.giro_para(l, rol + float(e.zero), 0.0), 0.06)
```

### O registro

- O kit: `nota` e `toque` (o atraso entre a batida e a chegada à trilha).
- `entrada`: `sensores` no começo; em cada chegada, `o` `rolagem`,
  `pedido_x` (a trilha), `feito_x` (a posição) e `rolagem` (rad, menos o
  zero): o ângulo pedido contra o feito; `o` `zero` a cada frase que
  recentra; `o` `branco` quando leva o dado branco (`t`, o atraso).
- `pista`: `haptica` `borda` (com o `lado`).
- `momento`: `trombada` (`lugar` o menor dos dois, `a`, `b`) e `reta`
  (`ordem`, `objeto` `pilhas`).

### Armadilhas

- **A inclinação é a velocidade:** a mão parada no zero deixa o patinador
  parado; a zona morta de 0,02 rad e o zero da frase seguram a deriva do
  giroscópio.
- **O deslize em tempo de música** (`1 − exp(−12 · Δt)`), nunca por quadro:
  com `--fixed-fps 60` sem janela, por quadro seria instantâneo.
- **A velocidade do dado nasce com ele** (`vel`), para o pico não teleportar
  os dados que já estão na laje. O branco anda sempre a 3 m por tempo.
- **A trombada espera a colcheia:** os dois ficam agarrados (velocidade 0)
  até ela, e só então giram; a linha `momento` e o `sentir` saem no mesmo
  quadro (`_trombada`, pela fila do `secao.gd`).
- **A vibração cala a háptica:** enquanto `sentir` vibra, `som_haptica` e a
  textura do gelo não tocam (F05); a prova da borda chama `_borda` direto.
- **O giro do erro mexe no `modelo`**, não no boneco: o `ao_terminar()`
  devolve a rotação.

## A cena

### O secao.gd

O da [J1](J1-a-viga.md#o-secaogd), sem mudança.

### Por lugar

| o quê | peça | onde (m) | cor |
| --- | --- | --- | --- |
| a laje de todos | `Kit.caixa(6,0; 0,15; 10,0)` | centro `(0; 0; 0,5)` | `Tema.SECAO[1]` (o cobalto), rugosidade 0,15 |
| as linhas entre trilhas | 4 × `Kit.caixa(0,04; 0,02; 10,0)`, chapadas | x −1,65; −0,55; 0,55; 1,65, y 0,09 | `ETIQUETA_SOMBRA` |
| as paredes | 2 × `Kit.caixa(0,2; 0,3; 10,0)` e os `SECAO.pilar` nas pontas | x ±2,7; os pilares em z −4,0 e 5,0 | `GRAFITE` |
| o dado do lugar | `Kit.caixa(0,4; 0,4; 0,4)`, girando em y pela batida; seis por lugar, reciclados | `x` da trilha, `z = 1,4 − (b − batida) × vel`, y 0,3 | `JOGADOR[l]` a 1,6 |
| a trilha que brilha | `Kit.caixa(0,3; 0,01; 4,0)` | `x` da trilha, y `0,085 + 0,003·l`, z −0,6 | `JOGADOR[l]` a 0,8 |
| o dado branco | `Kit.caixa(0,4; 0,4; 0,4)` | igual ao dado; o primeiro, parado em y 1,5 por 2 batidas | `ETIQUETA` a 1,2 |
| a coroa | `Kit.cilindro` r 0,16 → 0,22, altura 0,14 | sobre a cabeça do líder, y 2,1 | `TUNGSTENIO` a 1,0 |
| a pilha | `Kit.caixa(0,3; 0,1; 0,3)` a cada 4 dados | `(−2,4 + 1,6·l; …; −5,4)` | `JOGADOR[l]` a 0,6 |
| a espiral | 2 × 6 traços `Kit.caixa(0,05; 0,005; 0,22)`, chapados | no gelo, onde trombaram, por 4 s | `ETIQUETA_SOMBRA` |
| o patinador | o boneco de costas, `preso`, mãos livres, `walk` a 0,4 | `(x; 0,08; 1,4)`; `modelo.rotation.z = −v / 7 · 0,21` | o da montagem |

Sem peça Kenney nova: o gelo é caixa (a G10 traz `block-snow-*`, e a troca
fica para a G10 por `SECAO.peca_no_tamanho`).

### A câmera

`"camera": "fixa"`, o plano de corrida do cinema: 28 mm, 30° de cima, sem
corte. `camera_pos = (0; 6,3; 10,9)`, `camera_olhar = (0; 0,3; 0,5)` (12 m:
a laje inteira e as pilhas no fundo). O fov é o global de hoje (40). **No
pico**, recua 10 % em 2 batidas e volta em 2 (`SECAO.pico_suave`). O
tremor: `tremer(Sala.TREMOR_EXPLOSAO)` na trombada.

### A luz e o brilho

A luz é a da seção (`SECAO.montar`). O que brilha:

| o quê | energia | dono |
| --- | --- | --- |
| o dado | 1,6 | o lugar |
| a trilha que brilha | 0,8 | o lugar |
| a pilha | 0,6 | o lugar |
| as faíscas da coleta (16) | as de `Efeitos.faiscas` | o lugar |
| o dado branco e as faíscas dele | 1,2 | ninguém, `ETIQUETA` |
| a coroa | 1,0 | o líder, `TUNGSTENIO` |
| a lava, as brasas, o néon | os da J1 | o mundo |

## O som

| evento | id do mapa | onde | volume |
| --- | --- | --- | --- |
| a faixa | `mus_s02_j08` (128 BPM); até a H05, a sintetizada a 96 | TV | o da faixa |
| o dado coletado | `Som.tocar("tique")` = `tique_0..2`, tom 1,4 | TV, no patinador | −4 dB |
| a trombada | `Som.tocar("golpe")` = `golpe_0..4` | TV, entre os dois | −2 dB |
| o giro do erro | `Som.tocar("vento")` = `sint_vento` | TV, no patinador | −12 dB |
| BOM e ÓTIMO | `mod_coleta` (`som_falante(l, "coleta", 0.5)`) | alto-falante do dono | 0,5 |
| o dado branco | `mod_coleta` a 0,6 | alto-falante de quem leva | 0,6 |
| PERFEITO e ERRO | o kit | alto-falante do dono | o do kit |
| o gelo, a cada colcheia em movimento | `mod_material_gelo` (`Forja.textura(l, "gelo", 0.15..0.5)`) | um atuador | 0,15 a 0,5 |
| a borda | `mod_passo_cascalho_0..2` (`som_haptica(l, "passo:1:N", ...)`) | o atuador do lado da borda | 0,5 |

O mapa não tem J3 no `golpe_*` nem no `mod_passo_cascalho_*`.

## O controle

| recurso | o evento | para quem | o quê | a prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| giroscópio e acelerômetro | sempre | o dono | a rolagem dirige a velocidade | o robô (`robo_girar`) e a linha `entrada` |
| vibração | o acerto e o erro | o dono | o kit | o kit (H08) |
| vibração | a trombada | os dois | `sentir(l, "golpe_dir", 60)` no da esquerda, `"golpe_esq"` no da direita: o lado da batida | `percepcao(l).fraco` ou `.forte` ≥ 0,95 de +0 a +0,05 s do `trombou_t` |
| háptica | cada colcheia em movimento | o dono | a textura do gelo, de 0,15 (parado) a 0,5 (7 m/s), um atuador | `som_virtual(l)` com `esq` ou `dir` > 0 e `|v|` > 1 m/s |
| háptica | na borda | o dono | o cascalho a 0,5 no atuador do lado | `_borda(0)` com `x` 2,5 devolve `true` e grava a linha `pista` `borda` |
| gatilho R2 | — | — | `GATILHO_OFF` | o kit |
| barra de luz | o julgamento | o dono | o kit | o kit |
| alto-falante | a coleta | o dono | `coleta` 0,5; o branco 0,6 | `som_virtual(l).falante` |
| microfone | — | — | Não se aplica: a seção é do corpo | — |

## O cavaleiro

- **A peça aparece inteira e na cor dela.** O minigame não tinge o boneco:
  a cabeça (humana, orc, autômato, golem ou raposa), o superior e o
  inferior vêm da montagem com os tons próprios (G13). A cor do lugar fica
  no dado, na trilha que brilha e na pilha. As animações (`walk`, `idle`)
  e o giro (`modelo.rotation.y`) servem às cinco raças.
- **As mãos livres** (`maos_livres(p)`).
- **Os stats** (`SECAO.gancho`; sem a classe `Cavaleiro`, o neutro). Nenhum
  mexe na janela, nos pontos nem na distância da trombada.

| gancho | o que muda aqui | stat 1 | stat 5 |
| --- | --- | --- | --- |
| `velocidade` | a velocidade máxima na laje (7 m/s): chega antes à trilha | ×0,94 | ×1,06 |
| `levantar` | o giro no gelo (do erro e da trombada), 1 tempo à semicolcheia | 1,25 tempo | 0,75 tempo |
| `pista` | a trilha brilha antes (a nota não muda) | −40 ms | +40 ms |

A coluna `queda_tempos` do minigames.csv propõe 2 tempos; esta ficha usa 1
(o dado seguinte chega 2 tempos depois, e no pico 1: dois tempos girando
perderiam a nota seguinte sempre).

## As reações

- **`car_em_chamas`** e **`car_por_um_fio`**: os do kit. O `car_acorde` não
  se aplica.
- **Os adesivos `rea_*`:** quem está girando (`fora_da_rodada(l)`).
- Nenhum carimbo próprio deste minigame.

## A diversão

**O grito: a trombada** (`trombada`), degrau estrondo. Dois patinadores se
encostam, se agarram meio tempo, giram uma volta e deslizam para lados
opostos; a câmera treme (`TREMOR_EXPLOSAO`) e os dois param 3 quadros. O
dado branco do pico junta os quatro na mesma trilha: é a trombada garantida.

- **O rastro:** a espiral de patim no gelo, 4 s; a pilha de cada um no
  fundo cresce até o fim.
- **Confere pelo robô (mesa padrão):** pelo menos 4 linhas `momento`
  `trombada` entre 30 e 60 s; fora do pico, pelo menos 1; uma linha
  `momento` `reta`; nos `momento` com `x_tela` ≥ 0, 0,2 ≤ `x_tela` ≤ 0,8 e
  `altura_tela` ≥ 0,08.
- **Confere pela prancha:** 1 quadro de cada 3 do pico com uma espiral no
  gelo.

**A curva:** a tabela de **Como se joga**. Pelo robô: as notas por segundo
do 2.º terço ≥ 1,5 × as do 1.º; pelo menos 1 linha `entrada` `branco`.

**Quem está perdendo:** o dado branco é de quem chega, e quem está atrás tem
menos a perder numa trombada; a coroa mostra em quem esbarrar. Pelo robô: o
P4 (`ruim`) tem pelo menos uma linha `toque` BOM ou melhor em cada terço.

**O que se cortou:** as três trilhas por pista e as quatro lajes.

## Pronto quando

A patinação joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; o cabo que cai e volta não gera erro; a trombada
sai no tempo e gira os dois; o fim tem sempre vencedor;
`_prova_da_patinacao()` passa; e a prancha do pico mostra a espiral.

## Provas

**`godot/testes/prova_do_jogo.gd`**, no `match` de `_prova_da_ficha`:
`"S02_J08": await _prova_da_patinacao()`.

```gdscript
## Patinação de Dados (S02_J08): a trombada no tempo (o golpe do lado), o gelo
## na mão, a borda, o dado branco e a régua da diversão.
func _prova_da_patinacao() -> void:
	var visto := {"golpe": {}, "gelo": 0}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var e: Dictionary = mg.j[l]
			var t0 := float(e.trombou_t)
			if t0 >= 0.0 and Ritmo.t_musica() - t0 <= 0.05:
				var per := Forja.percepcao(l)
				if float(per.get("forte", 0.0)) >= 0.95 or float(per.get("fraco", 0.0)) >= 0.95:
					visto.golpe[l] = true
			var sv := Forja.som_virtual(l)
			if absf(float(e.v)) > 1.0 and (float(sv.get("esq", 0.0)) > 0.0 or float(sv.get("dir", 0.0)) > 0.0):
				visto.gelo += 1
	var mg := await _joga_o_minigame("S02_J08", 130.0, olhar)
	if mg == null:
		return
	_esperar(visto.gelo > 0, "S02_J08: o gelo chia na mão em movimento")
	mg.j[0].x = 2.5
	_esperar(mg._borda(0), "S02_J08: a borda arranha do lado dela")
	var no_pico := 0
	var fora := 0
	var reta := 0
	var brancos := 0
	for ev in _linhas_do_minigame("S02_J08"):
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "trombada":
			var t := float(ev.get("t_musica", 0.0))
			if t >= 30.0 and t <= 60.0:
				no_pico += 1
			else:
				fora += 1
			for l in [int(ev.get("a", 0)), int(ev.get("b", 0))]:
				_esperar(visto.golpe.has(l), "S02_J08 P%d: o golpe da trombada na mão" % [l + 1])
			if float(ev.get("x_tela", -1.0)) >= 0.0:
				_esperar(float(ev.x_tela) >= 0.2 and float(ev.x_tela) <= 0.8 and float(ev.altura_tela) >= 0.08,
					"S02_J08: a trombada no meio da tela (%s)" % [ev])
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "reta":
			reta += 1
		if ev.get("tipo", "") == "entrada" and ev.get("o", "") == "branco":
			brancos += 1
	_esperar(no_pico >= 4, "S02_J08: 4 ou mais trombadas no pico (%d)" % no_pico)
	_esperar(fora >= 1, "S02_J08: 1 ou mais trombadas fora do pico (%d)" % fora)
	_esperar(reta == 1, "S02_J08: a linha momento reta (%d)" % reta)
	_esperar(brancos >= 1, "S02_J08: alguém levou o dado branco (%d)" % brancos)
	_esperar(mg.vencedor().size() == 4, "S02_J08: a colocação tem os quatro")
```

**`godot/testes/captura_jogo.gd`**, no dicionário `momentos`:

```gdscript
		"S02_J08": [
			["patinacao_pista", fase.call("jogo", 6.0)],
			["patinacao_trombada", na_sala.call(func(sala) -> bool:
				return not sala._espirais.is_empty() and sala.no_pico())],
		],
```

**Os comandos:** `SALA=S02_J08 bash tests/prova_do_jogo.sh` e
`SALAS=S02_J08 bash tests/prova_visual.sh`.

**As pranchas que o jogador do time olha:**

- `patinacao_trombada`: dois patinadores girando e a espiral no gelo;
- `S02_J08_fim`: as pilhas no fundo em alturas diferentes, a coroa no
  líder;
- o boneco de cada lugar: a cabeça, o superior e o inferior em tons
  diferentes, sem a cor do lugar no corpo.

**O André (local):** `./run-local.sh -- --sala=S02_J08`: inclinar para
dirigir é imediato, parar no zero se aprende em uma frase, a trombada faz a
sala gritar, o dado branco junta os quatro.
