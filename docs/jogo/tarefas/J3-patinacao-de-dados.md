# J3 — Patinação de Dados

**Sprint:** J · **Slot:** S02_J08 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, F03, H07, J1 (o `secao.gd`)

## Por quê

Deslizar é dirigir com o corpo: a inclinação do controle leva o patinador
de um lado a outro da pista, e o jogo pede que ele **chegue** ao dado que
brilha na batida — a inclinação contínua (não um golpe), o ângulo pedido
contra o feito, nota a nota.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 8 em 03](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)
- [O índice da seção](J-a-viga.md) e a [J1](J1-a-viga.md#o-cenário) (o `secao.gd`)

## A ficha de dados

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
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "gelo",
	"microjogo": {"verbo": "Deslize!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S02_J08` — até a H05, a sintetizada a 96 bpm; com a
  gerada, 128 bpm ("deslize contínuo, portamento").
- **A pista:** cada um patina numa laje de gelo sobre a lava, com três
  trilhas: esquerda, meio e direita (`−1,1`, `0`, `+1,1` m do meio da raia).
  **A inclinação dirige:** o patinador vai para `x = clamp(rolagem / 0,35, −1, 1) × 1,1`
  e desliza até lá (a aproximação é `1 − exp(−12 · Δt)` em tempo de música,
  para ser a mesma na prova e no sofá).
- **Os dados:** cubos que brilham vêm pela pista, 2 m por tempo, e chegam à
  linha do patinador na batida deles, cada um numa trilha — **nunca na mesma
  do anterior**, sorteada pela semente.
- **O hoqueto em colcheias:** o dado do lugar `l` chega em `2k + 0,5·l`.
  `Ritmo.simples[l]`: um a cada 4 tempos.
- **A nota:** o patinador **entra** na trilha do dado (fica a menos de
  0,35 m dela) dentro da janela que abre meio tempo antes → `julgar_toque`.
  Já estava lá quando a janela abriu: julga ali (adiantado — chegar cedo é
  passar da nota). Não chegou até `FOLGA_PERDIDA`, o do kit depois → nota perdida.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`.
  Cada dado com julgamento BOM ou melhor é **coletado**.
- **A progressão:** `andamento()` do kit (em tempo de música, H08). De 0 a 1/3, um dado a cada 2
  tempos. **O pico (1/3 a 2/3), a descida:** um dado por tempo (`k + 0,25·l`)
  e os dados vêm 3 m por tempo. De 2/3 em diante, a cada 2 tempos.
  Dados de cada um em 90 s: ~55 a 96 bpm, ~72 a 128 bpm.

## O cenário

`SECAO.montar(self)` (a caverna) e as pistas sobre a lava:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a laje de gelo | `Kit.caixa(3.4, 0.15, 10.0)`, `Kit.material(Color("#bfe6ff"), 0.0, 0.9)` | centro `(RAIAS[l], 0.0, 0.5)` |
| as trilhas | duas linhas `Kit.caixa(0.04, 0.02, 10.0)`, `Kit.chapado(Color("#8fb8d8"))`, entre as trilhas | `x = RAIAS[l] ± 0.55`, `y = 0.09` |
| os pilares | `SECAO.pilar` em cada ponta da laje | `(RAIAS[l], −0.8, −4.0)` e `(RAIAS[l], −0.8, 5.0)` |
| o dado | `Kit.caixa(0.5, 0.5, 0.5)`, `Kit.material(Tema.CIANO, 1.6)`, girando em `y` pela batida; seis por lugar, reciclados | `x = RAIAS[l] + trilha`, `z = Z_JOGADOR − (b − batida) × velocidade`, `y = 0.35` |
| o patinador | o boneco, de costas, `preso`, `walk` lento | `(RAIAS[l] + x, 0.08, Z_JOGADOR)`; `p.modelo.rotation.z = −rolagem · 0.6` |

Câmera: `camera_pos = Vector3(0, 7.0, 11.5)`, `camera_olhar = Vector3(0, 0.3, -0.5)`.
O dado brilha (é a nota, tem trabalho); o gelo é fosco. A cor do lugar só
no aro.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **giroscópio e acelerômetro (a feature)** | a inclinação contínua dirige |
| vibração | o kit por nota (a textura `gelo` no cabo: fina, de um atuador só) |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "coleta", 0.5)`; erro: a nota quebrada (o kit) |
| gatilho | livre (o R2 Off) |
| háptica por material | `gelo`, pelo kit |
| som na TV | a nota (o kit); `tique` agudo (tom 1.4) no dado coletado, na trilha; `vento` baixo no giro do erro |

## A falha

Passou da nota: o patinador gira no gelo — uma volta inteira em
`p.modelo.rotation.y` em 1 tempo (pela batida) — e durante esse tempo a
inclinação não o dirige. O dado segue, apaga e some.

## O fim e o vencedor

90 s (a F03). `vencedor()`: mais dados coletados; empate pelos pontos,
depois pelo lugar.

## Com menos de quatro

Nada muda. **O controle que cai:** a pista dele para de mandar dados (os
que estavam vindo apagam sem erro); ao voltar, o próximo dado chega na
próxima batida dele pelo menos 2 tempos adiante.

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var alvo_x := float(e.x_robo)
	if not e.dados.is_empty():
		var d: Dictionary = e.dados[0]
		if int(e.robo_n) != int(d.n):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			e.robo_n = int(d.n)
			e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		# começa a inclinar 120 ms antes da mira: o patinador entra na trilha na batida
		if Ritmo.t_musica() >= Ritmo.t_da_batida(float(d.b)) + float(e.robo_mira) - 0.12:
			alvo_x = float(d.x)
			e.x_robo = alvo_x
	Forja.robo_girar(l, SECAO.giro_para(l, alvo_x / 1.1 * 0.35, 0.0), 0.06)
```

## Os ganchos

`godot/scripts/minigames/s02/patinacao_de_dados.gd`:

```gdscript
extends Minigame
## Patinação de Dados (S02_J08). Cada um patina numa laje de gelo sobre a
## lava, com três trilhas; a inclinação do controle dirige. Os dados vêm pela
## pista e chegam na batida do lugar (o hoqueto em colcheias), cada um numa
## trilha: entrar na trilha do dado no tempo o coleta. No meio, a descida: um
## dado por tempo, mais rápidos.
##
## A falha: passou da nota — gira no gelo por um tempo.
## O vencedor: mais dados coletados.
## O alto-falante do dono: a coleta no acerto, a nota no perfeito.
## O registro mede: a trilha pedida contra a posição e a inclinação feitas em
## cada dado (a linha `entrada`), e o atraso (o kit).
## O robô: inclina até a trilha do dado 120 ms antes da batida (ou 200 ms atrasado).
## Com menos de quatro: nada muda.
## A régua: "Deslize!" e o giroscópio bastam; sem a tela, não (a trilha é
## visual) — a seção tem outros quatro que dão; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const TRILHAS := [-1.1, 0.0, 1.1]
const ROLAGEM_CHEIA := 0.35
const NA_TRILHA := 0.35
const VELOCIDADE := 2.0
const VELOCIDADE_PICO := 3.0
const DESLIZE := 12.0  ## por segundo de música
const N_DADOS := 6
const PONTOS := [0, 20, 35, 50]

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.0, 11.5)
	camera_olhar = Vector3(0, 0.3, -0.5)
	SECAO.montar(self)
	var gelo := Kit.material(Color("#bfe6ff"), 0.0, 0.9)
	var linha := Kit.chapado(Color("#8fb8d8"))
	for p in jogadores:
		var l: int = p.lugar
		var x: float = RAIAS[l]
		Kit.caixa(self, Vector3(3.4, 0.15, 10.0), Vector3(x, 0.0, 0.5), gelo)
		for lado in [-0.55, 0.55]:
			Kit.caixa(self, Vector3(0.04, 0.02, 10.0), Vector3(x + lado, 0.09, 0.5), linha)
		SECAO.pilar(self, x, -4.0)
		SECAO.pilar(self, x, 5.0)
		var nos: Array = []
		for i in N_DADOS:
			var d := Kit.caixa(self, Vector3(0.5, 0.5, 0.5), Vector3(x, 0.35, -8.0), Kit.material(Tema.CIANO, 1.6))
			d.visible = false
			nos.append(d)
		maos_livres(p)
		p.preso = true
		p.position = Vector3(x, 0.08, Z_JOGADOR)
		p.rotation.y = PI
		j[l] = {"dados": [], "nos": nos, "n_prox": 0, "b_prox": -1.0, "trilha": 1, "x": 0.0, "t_antes": 0.0,
			"aberta": false, "dentro": false, "gira_b": -99.0, "coletados": 0, "fora": false,
			"x_robo": 0.0, "robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _proxima_batida(l: int, b: float) -> float:
	var passo := 2.0
	var desloc := 0.5 * l
	if Ritmo.simples[l]:
		passo = 2.0  # o kit dobra o passo na partitura simples
	elif no_pico():
		passo = 1.0
		desloc = 0.25 * l
	return proxima_batida(l, b, passo, desloc)  # o kit (H08): a próxima depois de b


## Os dados nascem 6 tempos antes da batida deles; a trilha nunca repete a anterior.
func _nascer(l: int) -> void:
	var e: Dictionary = j[l]
	while float(e.b_prox) > 0.0 and float(e.b_prox) <= Ritmo.batida() + 6.0 and e.dados.size() < N_DADOS:
		var t := int(e.trilha)
		var nova := (t + 1 + rng.randi_range(0, 1)) % 3
		e.trilha = nova
		var d := {"n": int(e.n_prox), "b": float(e.b_prox), "x": TRILHAS[nova], "vel": VELOCIDADE_PICO if no_pico() else VELOCIDADE}
		e.dados.append(d)
		nova_nota(l, int(d.n), Ritmo.t_da_batida(float(d.b)))
		e.n_prox = int(e.n_prox) + 1
		e.b_prox = _proxima_batida(l, float(e.b_prox))


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)  # sem giroscópio ou acelerômetro: a linha `troca` (H08)
		j[l].t_antes = Ritmo.t_musica()
		j[l].b_prox = _proxima_batida(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
	var agora := Ritmo.t_musica()
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


## O patinador desliza até onde a inclinação manda (no giro do erro, não).
func _deslizar(l: int, e: Dictionary, agora: float) -> void:
	var passou := agora - float(e.t_antes)
	e.t_antes = agora
	if Ritmo.batida() - float(e.gira_b) < 1.0 or not conectado(l):
		return
	var quer := clampf(SECAO.rolagem(l) / ROLAGEM_CHEIA, -1.0, 1.0) * 1.1
	e.x = float(e.x) + (quer - float(e.x)) * (1.0 - exp(-DESLIZE * passou))


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
			"rolagem": snappedf(SECAO.rolagem(l), 0.01), "n": int(d.n)})
		julgar_toque(l, alvo, int(d.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(d.n))


func _seguinte(l: int) -> void:
	var e: Dictionary = j[l]
	e.dados.pop_front()
	e.aberta = false
	e.dentro = false


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if not treinando:
		e.coletados = int(e.coletados) + 1
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "coleta", 0.5)
	var p := jogador(l)
	if p:
		Som.tocar("tique", p.global_position + Vector3(0, 0.5, 0), -4.0, 1.4)
		Efeitos.faiscas(self, p.global_position + Vector3(0, 0.5, 0), Tema.CIANO, 16, 0.7)
	_seguinte(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	e.gira_b = Ritmo.batida()
	var p := jogador(l)
	if p:
		Som.tocar("vento", p.global_position, -12.0)
	_seguinte(l)


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
		no.position = Vector3(RAIAS[l] + float(d.x), 0.35, z)
		no.rotation.y = agora_b * PI * 0.5
	var p := jogador(l)
	if p == null:
		return
	p.position = Vector3(RAIAS[l] + float(e.x), 0.08, Z_JOGADOR)
	if p.modelo:
		var giro := clampf(agora_b - float(e.gira_b), 0.0, 1.0)
		p.modelo.rotation.y = TAU * giro if giro < 1.0 else 0.0
		p.modelo.rotation.z = -float(e.x) / 1.1 * 0.35 * 0.6
	p.animar("walk" if fase == "jogo" else "idle", 0.4)


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

## O que o registro mede

- O kit: `nota` e `toque` (o atraso entre a batida e a chegada à trilha).
- A linha `entrada` em cada chegada: **a trilha pedida** (`pedido_x`),
  **a posição feita** (`feito_x`) e a inclinação do controle naquele quadro
  (rad) — o ângulo pedido contra o feito; no começo, os sensores do controle.

## Armadilhas

- **Dirigir é contínuo:** o patinador segue a inclinação a cada quadro; a
  nota é **entrar** na trilha. A trilha nunca repete a anterior (senão não
  haveria entrada).
- **O deslize em tempo de música** (`1 − exp(−12 · Δt)`), nunca por quadro:
  com `--fixed-fps 60` sem janela, por quadro seria instantâneo.
- **A velocidade do dado nasce com ele** (`vel`), para o pico não teleportar
  os dados que já estão na pista.
- **O giro do erro mexe no `modelo`**, não no boneco: o `ao_terminar()`
  devolve a rotação.

## Pronto quando

A patinação joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; o cabo que cai e volta não gera erro; o fim tem
sempre vencedor; `bash tests/prova_do_jogo.sh` passa; e
`bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S02_J08 (J3): a patinação abre pelo catálogo; o patinador de cada um chega
## às trilhas pela inclinação simulada; o fim tem vencedor.
func _prova_da_patinacao() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S02_J08", 130.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[2]) + int(c[3]) >= 1, "S02_J08 P%d: chegou ao dado no tempo %s" % [l + 1, c])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S02_J08: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S02_J08`: inclinar para
dirigir é imediato, chegar na batida (e não antes) se aprende, o giro no gelo
faz rir, a descida do meio aperta.

## Ao terminar

- Catálogo: `"S02_J08": preload("res://scripts/minigames/s02/patinacao_de_dados.gd")`
  em `MINIGAMES` e na lista da S02.
- `traducoes.gd`: `"Patinação de Dados": "Data Skating"`, `"Deslize!": "Glide!"`;
  em `EN_PADROES`, `["^Dados: (\\d+)$", "Dice: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a J3 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: a Patinação de Dados — dirigir com o corpo até o dado na batida`
