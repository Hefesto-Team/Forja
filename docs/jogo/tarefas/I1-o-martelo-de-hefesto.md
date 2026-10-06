# I1 — O Martelo de Hefesto

**Sprint:** I · **Slot:** S01_J01 · **Tamanho:** G · **Depende de:** H04, H08, F09, F03, F05, H07, G05

## Por quê

Bater no tempo da própria nota com o botão que a runa pede: o verbo mais
simples do jogo, e por baixo ele passa por todos os botões, pelos dois
analógicos até a borda e pelos dois gatilhos no meio e no fundo — os
vereditos da bancada de hoje continuam saindo daqui.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md) (o `minigame.gd`, o minigame de prova, e o `martelo_de_hefesto.gd` que ela deixou)
- [A linha n.º 1 em 03](../03-os-45-minigames.md#s1--a-centelha--botões-analógicos-gatilhos-analógicos)
- [O índice da seção](I-a-centelha.md) (as convenções)
- [A régua](../10-a-regua-astro-bot.md#a-pergunta-de-aprovação) e [o checklist de arte](../11-arte-e-personagens.md#o-checklist-de-aprovação)

## O estado de hoje

Depois da H04, `godot/scripts/minigames/s01/martelo_de_hefesto.gd` é A
Centelha de antes morando no kit: a mesma regra (runa por botão com anel que
fecha em segundos de jogo, `JANELA_INICIAL` 2,8 s encolhendo, o círculo em
7 s, o fole em 8 s), `"duracao": 100.0`, o robô que reage com
`rng.randf()`, e o anel de `TorusMesh` liso. Nada ali está no tempo da
música. Esta ficha **reescreve o arquivo inteiro** e cria o
`godot/scripts/minigames/s01/secao.gd`.

O que muda, em resumo:

| hoje (H04) | depois (I1) |
| --- | --- |
| a runa fecha em `e.t` (soma de `dt`) | a runa acende 2 tempos antes da nota do lugar e o anel fecha na batida da nota (`Ritmo.batida()`) |
| `_acertou`/`_perdeu` com pontos por rapidez | `julgar_toque` do kit; `toque()` e `falha()` |
| uma fila e acabou | a fila se repete; a primeira volta é a da bancada; o fim é aos 90 s de música (o kit, H08) |
| pontos | espadas: seis golpes forjam uma espada, pendurada na estante |
| — | o pico: no meio, a espada em brasa (cada runa pede dois golpes) |
| `Forja.gatilhos_off` | só o R2 (o L2 é do item) |
| anel liso, marcas em esfera | anel facetado (8 lados), marcas em caixa |
| o robô por `rng` | o robô pelo relógio da música, com `Forja.robo_acerta()` |

**O fim em tempo de música** ([13, H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)):
a FICHA diz `"duracao": 90.0` e o kit conta os 90 s em `Ritmo.t_musica()`,
não em tempo de jogo — com `--fixed-fps 60` o jogo anda ~16 vezes mais
depressa que a música, e um fim por `t_fase` acabaria antes de a fila pedir
os treze botões. A primeira volta da fila (17 notas por lugar, uns 20 a 35 s
de música) cabe folgada nos 90 s: os vereditos da bancada saem dela. Na
prova, o Martelo leva 90 s de relógio.

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J01",
	"titulo": "O Martelo de Hefesto",
	"verbo": "Bata!",
	"genero": "tct",
	"icone": "botoes",
	"entradas": BOTOES,
	"camera": "fixa",
	"faixa": "MUS_S01_J01",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Bata!", "segundos": 6.0},
	# o que a bancada mede (o veredito é das medidas do núcleo)
	"features": ["botoes", "analogicos", "gatilhos_analogicos"],
	"botoes_medidos": BOTOES,
	"gesto": "attack-melee-right",
}
```

`"entradas": BOTOES` passa das três do molde: é a exceção da bancada (os
treze botões que um jogo usa), como a H04 deixou.

## Como se joga

- **A faixa:** `MUS_S01_J01`; até a H05, a trilha sintetizada da seção a
  108 bpm (um tempo = 0,556 s); com a faixa gerada, 122 bpm (0,492 s).
- **A contagem:** batidas 0 a 3; a primeira nota de cada lugar é a batida
  `4 + 0,5·l`.
- **O hoqueto em colcheias:** a nota do lugar `l` cai nas batidas
  `2k + 0,5·l` (a `proxima_batida` do kit; P1 no 1 e no 3 do compasso, P2 no "e" do 1 e do 3, P3 no 2 e
  no 4, P4 no "e" do 2 e do 4). Uma nota a cada 2 tempos por lugar; os
  quatro juntos fazem colcheias seguidas. `Ritmo.simples[l]`: uma a cada 4
  tempos.
- **A runa de botão:** acende 2 tempos antes da nota, com o glifo do botão e
  o anel na cor do lugar; o anel fecha até a batida da nota. O botão certo
  → `julgar_toque`. Outro botão da lista, com a runa acesa → erro (a linha
  `entrada` diz qual chegou). Nada até `FOLGA_PERDIDA` (o kit, 0,14 s)
  depois da nota → nota perdida.
- **A runa do círculo** (um analógico): acende já; o lugar gira o analógico
  até a borda (0,85) pelas oito direções — as marcas acendem uma a uma. Com
  as oito, a runa troca para o glifo do analógico e marca a nota na próxima
  batida do lugar pelo menos 1 tempo adiante: **crave** com L3 (ou R3) na
  nota. 8 tempos sem fechar o círculo → nota perdida.
- **A runa do fole** (um gatilho): acende já; segure o gatilho na faixa
  dourada (35% a 62%) por um tempo inteiro de música (`60 / Ritmo.bpm` s).
  Cheio, o fole sopra e marca a nota como no círculo: **afunde até o fundo**
  (92%) na nota — o instante em que o gatilho cruza 92% é o toque. No R2, a
  resistência (Feedback, posição 3, força 4) começa na faixa: o dedo acha o
  meio sem olhar.
- **A fila:** os treze botões embaralhados pela semente (`rng`), com o
  círculo e o fole de um lado depois do 3.º e do 6.º botão e os do outro
  lado depois do 9.º e do 12.º (o lado que vem primeiro também pela
  semente). Runa errada ou perdida volta para o fim da fila, até três
  tentativas. A fila acabou: uma fila nova, embaralhada de novo. A primeira
  volta tem 17 notas por lugar (13 + 2 cravadas + 2 fundos).
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 60, 80, 100]`;
  a nota do círculo e a do fole valem 2,5 vezes; o combo soma
  `10 × (combo − 1)`, no máximo +100.
- **As espadas:** cada acerto é um golpe (a nota especial, dois); seis
  golpes forjam uma espada, que aparece na estante atrás da bigorna. O erro
  racha a espada em curso: menos dois golpes.
- **A progressão:** `andamento()` do kit (0..1 dos 90 s de música). De 0 a 1/3, uma runa
  a cada 2 tempos. **O pico (1/3 a 2/3), a espada em brasa:** toda runa de
  botão acertada pede um segundo golpe um tempo depois, com o mesmo botão —
  cada lugar bate em todo tempo, e os quatro fazem semicolcheias; a luz da
  forja sobe (`no_pico()` do kit). De 2/3 em diante, de novo uma a cada 2 tempos. Quantas notas
  por lugar em 90 s: ~75 a 108 bpm, ~85 a 122 bpm.

## O cenário

`SECAO.montar(self)` e, por lugar:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a bigorna | `Kit.bigorna(self, pos, 0.62)` | `(RAIAS[l] + 0.45, 0, 0.3)` |
| o ferreiro | o boneco, `martelo_na_mao(p)`, olhando a bigorna | `(RAIAS[l] − 1.05, 0.05, 1.15)` |
| a luz da forja | `OmniLight3D`, cor do lugar misturada a `#ffb070`, 0,9, alcance 4 | bigorna + `(0, 1.4, 0.8)` |
| a estante | `wood-structure`, escala 1.2 | bigorna + `(0, 0, −1.9)` |
| as espadas | `weapon-sword`, escala 1.6, de pé | bigorna + `(−0.9 + 0.24·(k−1), 0.15, −1.75)`, até 8 |
| a runa | glifo em `Sprite3D`, anel facetado, 8 marcas em caixa, o fole (trilho, faixa, topo, nível) | bigorna + `(0, 2.55, 0)` |

Câmera: `camera_pos = Vector3(0, 7.2, 12.4)`, `camera_olhar = Vector3(0, 1.2, -0.2)`.
O emissivo só na runa (tem trabalho) e nas faíscas. Nada usa a cor de outro
lugar.

`godot/scripts/minigames/s01/secao.gd` (novo, o arquivo inteiro):

```gdscript
extends RefCounted
## A seção A Centelha (S01): o que os cinco minigames têm em comum — a forja
## (o cenário). A barra de luz que pisca no julgamento é do kit (H08).
## Sem class_name: quem usa carrega pelo caminho,
## const SECAO := preload("res://scripts/minigames/s01/secao.gd").

## A forja: o chão e as paredes do kit, as brasas subindo, o neon rosa, as
## tochas, e o fundo (colunas, estandartes, a lenha, barris). O minigame põe
## por cima o que é só dele.
static func montar(sala: SalaJogo) -> void:
	Kit.arena(sala, 5, 3)
	sala.atmosfera(Color("#ff9a52"), Tema.ROSA, true, 60)
	sala.luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])
	for x in [-10.0, 10.0]:
		Kit.peca(sala, "column", Vector3(x, 0, -6.0))
		Kit.peca(sala, "column", Vector3(x, 0, 5.0))
	for x in [-6.0, 0.0, 6.0]:
		Kit.peca(sala, "banner", Vector3(x, 0, -7.0))
	for x in [-3.0, 3.0]:
		Kit.peca(sala, "wood-support", Vector3(x, 0, -7.0))
	Kit.peca(sala, "barrel", Vector3(-10.6, 0, 1.0), 0.4)
	Kit.peca(sala, "barrel", Vector3(-10.6, 0, 2.3), 1.1)
	Kit.peca(sala, "pot", Vector3(10.6, 0, 1.6))
	var fornalha := OmniLight3D.new()
	fornalha.position = Vector3(0, 1.2, -6.0)
	fornalha.light_color = Color("#ff7a2a")
	fornalha.light_energy = 1.4
	fornalha.omni_range = 8.0
	sala.add_child(fornalha)
```

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **botões, analógicos, gatilhos (a feature)** | a runa pede; a mão responde na nota |
| vibração | o kit: `acerto`/`perfeito` (ou a textura `metal` no cabo, H07) em todo acerto, `erro` no erro; a espada forjada: `Forja.sentir(l, "golpe")` |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro; a ficha não mexe |
| alto-falante do dono | perfeito: a nota do lugar (o kit); ótimo e bom: `Som.no_controle(l, "martelo", 0.55)`; erro: a nota quebrada (o kit); a espada forjada: `Forja.som_falante(l, "coleta", 0.7)` |
| gatilho | R2: Feedback (3, 4) enquanto a runa do fole do R2 está acesa; `GATILHO_OFF` no R2 quando ela acaba; o L2 nunca (é do item) |
| háptica por material | `metal`, pelo kit |
| som na TV | a nota do lugar (o kit), `bigorna_aguda` + `martelo` no acerto de botão, `bigorna` + `martelo` na nota especial, `tique` subindo a cada direção do círculo, `sopro` no fole cheio, `sucesso` baixo na espada |

## A falha

O martelo quica: faísca apagada (`Efeitos.faiscas(self, topo, Tema.TRILHO, 10, 0.5)`),
a runa treme (`e.tremor = 1.0`), a espada em curso racha (−2 golpes), o
combo zera e o boneco faz `emote-no` (0,6 s). A runa volta para o fim da
fila. Recuperação: a próxima runa acende no tempo de sempre.

## O fim e o vencedor

O kit fecha aos 90 s de música (`"fim": "tempo"`, F03 e H08); a runa some
com a fase. `vencedor()`: mais espadas; no empate, mais pontos; depois, o
lugar menor.

## Com menos de quatro

Nada muda: cada lugar tem a sua fração do compasso, e quem falta deixa o
buraco na música. **O controle que cai:** a runa dele para (sem erro, sem
`med_pedido`); quando volta, a runa da vez reacende a partir da batida de
agora (`_acender(l, Ritmo.batida())`). O fim não espera quem está sem
controle (a `SalaJogo` já não espera).

## O robô

Só pelo controle simulado; mira pelo relógio da música; consulta
`Forja.robo_acerta()` uma vez por nota. Botão: aperta na nota (ou 200 ms
atrasado: erro). Círculo: uma volta a cada 3 tempos, na borda; crava na nota.
Fole: sobe ao meio (0,48) em meio segundo de música, segura, e afunda até o
fim nos 60 ms antes da nota. Tudo por tempo de música: vale igual na prova e
no sofá.

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var r = _runa(l)
	if r == null or Ritmo.batida() < float(e.b_luz):
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado (erro)
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		e.robo_feito = false
	var agora := Ritmo.t_musica()
	var alvo_t := INF
	if float(e.b_nota) >= 0.0:
		alvo_t = Ritmo.t_da_batida(float(e.b_nota)) + float(e.robo_mira)
	match str(r.tipo):
		"botao":
			if not bool(e.robo_feito) and agora >= alvo_t:
				Forja.robo_apertar(l, int(r.alvo), 0.05)
				e.robo_feito = true
		"analogico":
			var direito := int(r.alvo) == 1
			if float(e.b_nota) < 0.0:
				var ang := TAU * (Ritmo.batida() - float(e.b_luz)) / 3.0
				Forja.robo_eixo(l, Forja.RX if direito else Forja.LX, cos(ang), 0.06)
				Forja.robo_eixo(l, Forja.RY if direito else Forja.LY, sin(ang), 0.06)
			elif not bool(e.robo_feito) and agora >= alvo_t:
				Forja.robo_apertar(l, Forja.R3 if direito else Forja.L3, 0.05)
				e.robo_feito = true
		"gatilho":
			var segundos := (Ritmo.batida() - float(e.b_luz)) * 60.0 / Ritmo.bpm
			var v := clampf(segundos / 0.5, 0.0, 1.0) * 0.48
			if float(e.b_nota) >= 0.0:
				v = lerpf(0.48, 1.0, clampf((agora - (alvo_t - 0.06)) / 0.06, 0.0, 1.0))
			Forja.robo_eixo(l, Forja.R2 if int(r.alvo) == 1 else Forja.L2, v, 0.06)
```

(Quando o robô para de mandar o eixo, o controle simulado volta a zero
sozinho: o gatilho desce ao repouso e o analógico ao centro.)

## Os ganchos

O arquivo `godot/scripts/minigames/s01/martelo_de_hefesto.gd`, inteiro, na
ordem: o cabeçalho, as constantes, a FICHA (acima), o estado, os ganchos, o
que se vê, o robô (acima).

```gdscript
extends Minigame
## O Martelo de Hefesto (S01_J01), o primeiro d'A Centelha. Cada um tem a sua
## bigorna; em cima dela acende uma runa com o botão da vez e um anel que fecha
## na nota do lugar (o hoqueto em colcheias). Bater no tempo forja: seis golpes
## fazem uma espada. A fila de cada um passa por todos os botões (✕ ○ □ △, L1,
## R1, L3, R3, as setas e o Create), pelo círculo de cada analógico (gire até a
## borda e crave com L3/R3 na nota) e pelo fole de cada gatilho (segure onde
## pesa e afunde na nota). No meio, a espada em brasa: cada runa pede dois golpes.
##
## A falha: o martelo quica, a espada racha (dois golpes a menos) e o boneco
## balança a cabeça; a runa volta para o fim da fila (até três vezes).
## O vencedor: mais espadas; no empate, mais pontos.
## O alto-falante do dono: a nota dele no perfeito (o kit), o martelo nos
## outros acertos, a coleta na espada.
## O registro mede: cada botão, analógico e gatilho pedido e respondido (as
## medidas do núcleo, que servem à bancada), e cada nota e toque (o kit).
## O robô: aperta na nota; quando não acerta, 200 ms atrasado; gira uma volta
## a cada três tempos; segura o fole no meio e afunda na nota.
## Com menos de quatro: nada muda.
## A régua: título, verbo e ✕ no aviso bastam; sem a tela, a nota do lugar na
## TV e a resistência do R2 dizem o tempo e o meio; nada pergunta pelo controle.
##
## O Options é a pausa, o PS fica de fora (o sistema toma), o botão do
## microfone é d'A Voz e o clique do touchpad é d'O Molde.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")
const BOTOES := [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.L1, Forja.R1, Forja.L3,
	Forja.R3, Forja.CIMA, Forja.BAIXO, Forja.ESQUERDA, Forja.DIREITA, Forja.CREATE]

# (a FICHA de "A ficha de dados" vem aqui)

const GLIFO := {
	Forja.CRUZ: "cross", Forja.CIRCULO: "circle", Forja.QUADRADO: "square", Forja.TRIANGULO: "triangle",
	Forja.L1: "l1", Forja.R1: "r1", Forja.L3: "stick_l", Forja.R3: "stick_r", Forja.CIMA: "dpad_up",
	Forja.BAIXO: "dpad_down", Forja.ESQUERDA: "dpad_left", Forja.DIREITA: "dpad_right", Forja.CREATE: "share",
}
const ANTES := 2.0  ## a runa de botão acende tantos tempos antes da nota
const JANELA_ESPECIAL := 8.0  ## tempos para fechar o círculo ou encher o fole
const BORDA := 0.85
const FAIXA := Vector2(0.35, 0.62)  ## o meio do fole
const FUNDO := 0.92
const MAX_TENTATIVAS := 3
const GOLPES_POR_ESPADA := 6
const PONTOS := [0, 60, 80, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const ESPECIAL := 2.5  ## a nota do círculo e a do fole valem mais
# BATIDA_DA_PRIMEIRA_NOTA, FOLGA_PERDIDA, proxima_batida, no_pico e progresso: do kit (H08)

var j := {}  ## lugar -> o estado do jogador
var runas := {}  ## lugar -> os nós da runa
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]  ## [lugar][julgamento], para a prova


func montar() -> void:
	camera_pos = Vector3(0, 7.2, 12.4)
	camera_olhar = Vector3(0, 1.2, -0.2)
	SECAO.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		Kit.bigorna(self, _bigorna(l), 0.62)
		p.position = Vector3(RAIAS[l] - 1.05, 0.05, 1.15)
		p.olhar_para(_bigorna(l))
		martelo_na_mao(p)
		var fogo := OmniLight3D.new()
		fogo.position = _bigorna(l) + Vector3(0, 1.4, 0.8)
		fogo.light_color = Forja.cor_do_lugar(l).lerp(Color("#ffb070"), 0.5)
		fogo.light_energy = 0.9
		fogo.omni_range = 4.0
		add_child(fogo)
		Kit.peca(self, "wood-structure", _bigorna(l) + Vector3(0, 0, -1.9), 0.0, 1.2)
		runas[l] = _montar_runa(l)
		j[l] = _novo_jogador()
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A bigorna de cada um, à frente e à direita do ferreiro.
static func _bigorna(l: int) -> Vector3:
	return Vector3(RAIAS[l] + 0.45, 0.0, 0.3)


func _nova_fila() -> Array:
	var ordem := BOTOES.duplicate()
	for i in range(ordem.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = ordem[i]
		ordem[i] = ordem[k]
		ordem[k] = tmp
	var lado := rng.randi_range(0, 1)
	var extras := [
		{"tipo": "analogico", "alvo": lado}, {"tipo": "gatilho", "alvo": lado},
		{"tipo": "analogico", "alvo": 1 - lado}, {"tipo": "gatilho", "alvo": 1 - lado},
	]
	var fila: Array = []
	for i in ordem.size():
		fila.append({"tipo": "botao", "alvo": ordem[i], "tentativas": 0})
		var depois := [2, 5, 8, 11].find(i)
		if depois >= 0:
			var x: Dictionary = extras[depois].duplicate()
			x["tentativas"] = 0
			fila.append(x)
	return fila


func _novo_jogador() -> Dictionary:
	return {"fila": _nova_fila(), "atual": 0, "voltas": 0, "n": 0, "b_luz": -1.0, "b_nota": -1.0,
		"segundo": false, "setores": 0, "segurou": 0.0, "t_ant": 0.0, "v_antes": 0.0,
		"golpes": 0, "espadas": 0, "combo": 0, "tremor": 0.0, "pop": 0.0, "fora": false,
		"robo_n": -1, "robo_mira": 0.0, "robo_feito": false}


func _runa(l: int) -> Variant:
	var e: Dictionary = j[l]
	return e.fila[e.atual] if int(e.atual) < e.fila.size() else null


## A próxima batida do lugar a partir de `desde`, inclusive (o hoqueto em
## colcheias, pela proxima_batida do kit, que dobra o passo na partitura simples).
func _proxima_batida(l: int, desde: float) -> float:
	return proxima_batida(l, desde - 0.001, 2.0, 0.5 * l)


func iniciar_jogo() -> void:
	for l in presentes():
		_acender(l, BATIDA_DA_PRIMEIRA_NOTA - ANTES)


## Acende a runa da vez a partir da batida `desde`. A de botão marca a nota
## ANTES tempos adiante; a do círculo e a do fole acendem já e só marcam a nota
## quando a mão fecha o círculo ou enche o fole.
func _acender(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var r = _runa(l)
	e.setores = 0
	e.segurou = 0.0
	e.t_ant = Ritmo.t_musica()
	e.segundo = false
	if r == null:
		return
	if str(r.tipo) == "botao":
		e.b_nota = _proxima_batida(l, desde + ANTES)
		e.b_luz = float(e.b_nota) - ANTES
		nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_nota)))
		return
	e.b_luz = maxf(desde, BATIDA_DA_PRIMEIRA_NOTA - ANTES)
	e.b_nota = -1.0
	if str(r.tipo) == "gatilho" and int(r.alvo) == 1:
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 3, 4)


func jogar(dt: float) -> void:
	for p in jogadores:
		var l: int = p.lugar
		var e: Dictionary = j[l]
		e.pop = move_toward(float(e.pop), 0.0, dt * 5.0)
		e.tremor = move_toward(float(e.tremor), 0.0, dt * 4.0)
		_mostrar_runa(l)
		if acabou[l] or not jogando[l]:
			continue
		if not conectado(l):
			e.fora = true
			Forja.med_pedido(l, -1)
			continue
		if bool(e.fora):
			# voltou: a runa da vez reacende a partir de agora
			e.fora = false
			_acender(l, Ritmo.batida())
		_jogar(l)


func _jogar(l: int) -> void:
	var e: Dictionary = j[l]
	var r = _runa(l)
	if r == null:
		return
	var acesa := Ritmo.batida() >= float(e.b_luz)
	match str(r.tipo):
		"botao":
			Forja.med_pedido(l, int(r.alvo) if acesa else -1)
			if not acesa:
				return
			for b in BOTOES:
				if not Forja.apertou(l, b):
					continue
				if b == int(r.alvo):
					julgar_toque(l, Ritmo.t_da_batida(float(e.b_nota)), int(e.n))
				else:
					anotar("entrada", l, {"o": "botao", "pedido": GLIFO[int(r.alvo)], "chegou": GLIFO[b],
						"n": int(e.n)})
					nota_perdida(l, int(e.n))
				return
			if Ritmo.t_musica() > Ritmo.t_da_batida(float(e.b_nota)) + FOLGA_PERDIDA:
				nota_perdida(l, int(e.n))
		"analogico":
			_circulo(l, e, r)
		"gatilho":
			_fole(l, e, r)


func _circulo(l: int, e: Dictionary, r: Dictionary) -> void:
	var direito := int(r.alvo) == 1
	Forja.med_pedir(l, "analogico_r" if direito else "analogico_l")
	if float(e.b_nota) < 0.0:
		Forja.med_pedido(l, -1)
		var x := Forja.eixo(l, Forja.RX if direito else Forja.LX)
		var y := Forja.eixo(l, Forja.RY if direito else Forja.LY)
		if Vector2(x, y).length() >= BORDA:
			var antes: int = e.setores
			e.setores = int(e.setores) | (1 << _setor(x, y))
			if int(e.setores) != antes:
				Som.tocar("tique", runas[l].raiz.global_position, -6.0, 1.0 + 0.06 * _contar(int(e.setores)))
		if int(e.setores) == 0xFF:
			anotar("entrada", l, {"o": "analogico", "detalhe": ("direito" if direito else "esquerdo") + ": as oito direções"})
			e.b_nota = _proxima_batida(l, Ritmo.batida() + 1.0)
			nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_nota)))
		elif Ritmo.batida() > float(e.b_luz) + JANELA_ESPECIAL:
			nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_luz) + JANELA_ESPECIAL))
			nota_perdida(l, int(e.n))
		return
	var crave := Forja.R3 if direito else Forja.L3
	Forja.med_pedido(l, crave)
	if Forja.apertou(l, crave):
		julgar_toque(l, Ritmo.t_da_batida(float(e.b_nota)), int(e.n))
	elif Ritmo.t_musica() > Ritmo.t_da_batida(float(e.b_nota)) + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func _fole(l: int, e: Dictionary, r: Dictionary) -> void:
	var direito := int(r.alvo) == 1
	Forja.med_pedido(l, -1)
	Forja.med_pedir(l, "gatilho_r2" if direito else "gatilho_l2")
	var v := Forja.eixo(l, Forja.R2 if direito else Forja.L2)
	var agora := Ritmo.t_musica()
	if float(e.b_nota) < 0.0:
		var passou := agora - float(e.t_ant)
		var na_faixa := v >= FAIXA.x and v <= FAIXA.y
		e.segurou = float(e.segurou) + passou if na_faixa else maxf(0.0, float(e.segurou) - passou * 2.0)
		e.t_ant = agora
		if float(e.segurou) >= 60.0 / Ritmo.bpm:
			Forja.med_faixa(l, int(r.alvo))
			Som.tocar("sopro", runas[l].raiz.global_position)
			e.b_nota = _proxima_batida(l, Ritmo.batida() + 1.0)
			nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_nota)))
			e.v_antes = v
		elif Ritmo.batida() > float(e.b_luz) + JANELA_ESPECIAL:
			nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_luz) + JANELA_ESPECIAL))
			nota_perdida(l, int(e.n))
		return
	var cruzou := float(e.v_antes) < FUNDO and v >= FUNDO
	e.v_antes = v
	if cruzou:
		anotar("entrada", l, {"o": "gatilho", "detalhe": ("R2" if direito else "L2") + ": meio e fundo"})
		julgar_toque(l, Ritmo.t_da_batida(float(e.b_nota)), int(e.n))
	elif agora > Ritmo.t_da_batida(float(e.b_nota)) + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


## O setor do analógico (0 = direita, sentido horário na tela), como o núcleo.
static func _setor(x: float, y: float) -> int:
	var a := atan2(y, x)
	if a < 0.0:
		a += TAU
	return int(round(a / (PI / 4.0))) % 8


static func _contar(m: int) -> int:
	var n := 0
	while m:
		n += m & 1
		m >>= 1
	return n


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var r = _runa(l)
	var especial := r != null and str(r.tipo) != "botao"
	e.combo = int(e.combo) + 1
	var base := float(PONTOS[julgamento]) * (ESPECIAL if especial else 1.0)
	marcar(l, int(base) + mini(10 * (int(e.combo) - 1), 100))
	if not treinando:
		e.golpes = int(e.golpes) + (2 if especial else 1)
		if int(e.golpes) >= GOLPES_POR_ESPADA:
			e.golpes = int(e.golpes) - GOLPES_POR_ESPADA
			e.espadas = int(e.espadas) + 1
			_pendurar_espada(l, int(e.espadas))
	e.pop = 1.0
	var topo := _bigorna(l) + Vector3(0, 0.8, 0)
	Efeitos.faiscas(self, topo, Tema.AMARELO, 26 if julgamento == Ritmo.PERFEITO else 12, 1.0)
	Efeitos.anel(self, runas[l].raiz.global_position, Forja.cor_do_lugar(l), 0.7)
	Som.tocar("bigorna" if especial else "bigorna_aguda", topo, -2.0)
	Som.tocar("martelo", topo, -6.0)
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "martelo", 0.55)  # no perfeito, o kit toca a nota do lugar
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.45)
	_avancar(l, true)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	e.combo = 0
	e.tremor = 1.0
	if not treinando:
		e.golpes = maxi(0, int(e.golpes) - 2)  # a espada racha
	Efeitos.faiscas(self, _bigorna(l) + Vector3(0, 0.8, 0), Tema.TRILHO, 10, 0.5)  # o martelo quica
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.6)
	var r = _runa(l)
	if r != null:
		r.tentativas = int(r.tentativas) + 1
		if int(r.tentativas) < MAX_TENTATIVAS:
			e.fila.append(r.duplicate())
	_avancar(l, false)


## A nota foi julgada: o segundo golpe da espada em brasa, ou a runa seguinte
## (e a fila nova, quando esta acabou).
func _avancar(l: int, acertou: bool) -> void:
	var e: Dictionary = j[l]
	var r = _runa(l)
	var anterior := float(e.b_nota)
	if bool(e.segundo):
		anterior -= 1.0  # a runa conta do primeiro golpe
	e.n = int(e.n) + 1
	if r != null and str(r.tipo) == "gatilho" and int(r.alvo) == 1:
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	if acertou and r != null and str(r.tipo) == "botao" and no_pico() and not bool(e.segundo) and not Ritmo.simples[l]:
		e.segundo = true
		e.b_nota = anterior + 1.0
		nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_nota)))
		return
	e.atual = int(e.atual) + 1
	if int(e.atual) >= e.fila.size():
		e.voltas = int(e.voltas) + 1
		e.fila = _nova_fila()
		e.atual = 0
	_acender(l, anterior if anterior >= 0.0 else Ritmo.batida())


func _pendurar_espada(l: int, k: int) -> void:
	Forja.sentir(l, "golpe")
	Forja.som_falante(l, "coleta", 0.7)
	var pos := _bigorna(l) + Vector3(-0.9 + 0.24 * (k - 1), 0.15, -1.75)
	Efeitos.faiscas(self, pos + Vector3(0, 0.8, 0), Forja.cor_do_lugar(l), 20, 0.8)
	Som.tocar("sucesso", pos, -10.0)
	if k <= 8:  # a estante tem oito ganchos; as outras contam e não aparecem
		Kit.peca(self, "weapon-sword", pos, 0.0, 1.6)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].espadas) != int(j[b].espadas):
		return int(j[a].espadas) > int(j[b].espadas)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func combo(l: int) -> int:
	return int(j[l].combo) if j.has(l) else 0


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Espadas: %d" % int(j[lugar].espadas)
	return super(lugar)
```

**O que se vê** (no fim do arquivo, antes do robô): `_montar_runa(l)` é o
de `godot/scripts/salas/centelha.gd:115-181` com três trocas — o `TorusMesh`
do anel com `rings = 8` e `ring_segments = 4` (facetado, 11); as oito marcas
com `BoxMesh` de `Vector3(0.12, 0.12, 0.12)` no lugar da `SphereMesh`; e a
posição da raiz em `_bigorna(l) + Vector3(0, 2.55, 0)`. O `_mostrar_runa(l)`:

```gdscript
func _mostrar_runa(l: int) -> void:
	var n: Dictionary = runas[l]
	var e: Dictionary = j[l]
	var r = _runa(l)
	var raiz: Node3D = n.raiz
	raiz.visible = r != null and fase == "jogo" and not acabou[l] and Ritmo.batida() >= float(e.b_luz)
	if not raiz.visible:
		return
	var nome_glifo := ""
	match str(r.tipo):
		"botao":
			nome_glifo = GLIFO.get(int(r.alvo), "cross")
		"analogico":
			nome_glifo = "stick_r" if int(r.alvo) == 1 else "stick_l"
		"gatilho":
			nome_glifo = "r2" if int(r.alvo) == 1 else "l2"
	var glifo: Sprite3D = n.glifo
	glifo.texture = Desenho.glifo(nome_glifo)
	glifo.modulate = Tema.FG.lerp(Tema.ROSA, float(e.pop))
	glifo.scale = Vector3.ONE * (1.0 + 0.6 * float(e.pop))
	glifo.position.x = sin(t * 60.0) * 0.08 * float(e.tremor)
	# o anel fecha na batida da nota; sem nota ainda (círculo, fole), com a janela
	var resto := 1.0
	if float(e.b_nota) >= 0.0:
		resto = clampf((float(e.b_nota) - Ritmo.batida()) / ANTES, 0.0, 1.0)
	else:
		resto = clampf(1.0 - (Ritmo.batida() - float(e.b_luz)) / JANELA_ESPECIAL, 0.0, 1.0)
	(n.anel as MeshInstance3D).scale = Vector3.ONE * lerpf(0.35, 1.0, resto)
	for s in 8:
		var m: MeshInstance3D = n.marcas[s]
		m.visible = str(r.tipo) == "analogico" and float(e.b_nota) < 0.0
		var aceso := (int(e.setores) >> s) & 1
		m.material_override = Kit.material(Tema.AMARELO if aceso else Tema.TRILHO, 2.0 if aceso else 0.0)
	var fole: Node3D = n.fole
	fole.visible = str(r.tipo) == "gatilho"
	if fole.visible:
		var v := Forja.eixo(l, Forja.R2 if int(r.alvo) == 1 else Forja.L2)
		var nivel: MeshInstance3D = n.nivel
		nivel.scale = Vector3(1, maxf(0.02, v * 1.4), 1)
		nivel.position.y = v * 1.4 * 0.5
		(n.faixa as Node3D).visible = float(e.b_nota) < 0.0
		(n.topo as Node3D).visible = float(e.b_nota) >= 0.0
```

(Cria os dois `Kit.material` das marcas uma vez só, como `_mat_aceso` e
`_mat_apagado`, se a prova visual mostrar travada; o de hoje recria a cada
quadro.)

## O que o registro mede

- As medidas do núcleo, como hoje: `med_pedido` (o botão da runa acesa),
  `med_pedir` (o círculo e o fole pedidos), `med_faixa` (o meio do fole) —
  dão os vereditos `botoes`, `analogicos` e `gatilhos_analogicos` da bancada.
- O kit: uma linha `nota` por nota (o instante do pedido em tempo de música)
  e uma `toque` por resposta (o desvio e o julgamento, ou `perdida`).
- A linha `entrada`: o botão que chegou no lugar do pedido (uma troca no
  caminho aparece aqui, noite toda), o círculo fechado e o fole cheio.

## Armadilhas

- **Nada de `dt` no ritmo.** O anel, as notas e o robô andam por
  `Ritmo.batida()`/`Ritmo.t_musica()`. O `dt` só no `pop` e no `tremor` (efeito).
- **`julgar_toque` chama `toque`/`falha` na hora**, e eles avançam a runa:
  depois dele, `return` (não leia a runa velha).
- **A nota do círculo e a do fole** não existem até a mão fechar/encher:
  `nova_nota` só aí; se a janela passar, `nova_nota` com o fim da janela e
  depois `nota_perdida` — toda `toque` tem a sua `nota`.
- **O L2 é do item** (G03): nunca `gatilhos_off` nem Feedback no L2.
- **O treino** julga e não soma: as espadas só com `not treinando`.
- **`class_name`, `_init()` e `RAIAS`**: nenhum (o kit); o `class_name
  SalaCentelha` já saiu na H04.
- **O fim é do kit, em tempo de música** (H08): nada de duração zerada como remendo,
  de `t_jogo` ou de `t_fase` na ficha. O Martelo leva 90 s de relógio na
  prova; a espera é a do `_joga_o_minigame` da H08, pelo relógio de parede
  (veja Provas).
- **A resistência do R2 pelas opções:** `Forja.gatilho` já passa pelas
  opções do lugar (gatilho desligado vira Off); não confira de novo.
- **Kit.material a cada quadro** nas marcas: se a prancha mostrar menos de
  55 fps, guarde os dois materiais.

## Pronto quando

O Martelo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; o cabo que cai e volta não trava ninguém; a primeira
volta pede os treze botões, os dois círculos e os dois foles; os vereditos
`botoes`, `analogicos` e `gatilhos_analogicos` passam na prova limpa e cada
defeito do gauntlet que eles pegavam (`troca-cruz-circulo`,
`analogico-curto`, `gatilho-digital`) continua pego; o fim tem sempre
vencedor; `bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh`
passa com a prancha **olhada** nas partidas com quatro, dois e um jogador e
com o cabo que cai.

## Provas

**`godot/testes/prova_do_jogo.gd`:**

1. O Martelo joga pelo `_joga_o_minigame("S01_J01", 150.0, ...)` da H08,
   que espera a fase `fim` pelo relógio de parede (90 s de música, mais o
   aviso e o fechamento). As esperas de `_termina_a_sala()` e da prova de
   poucos já são as da H08: esta ficha não mexe nelas.

2. Em `_prova_do_relatorio()`, no laço da linha do tempo que a H04 pôs,
   conte as notas julgadas do Martelo por lugar:

   ```gdscript
   	var martelo := [0, 0, 0, 0]
   	# (dentro do laço, ao lado das checagens da H04)
   			if ev.get("tipo", "") == "toque" and ev.get("slot", "") == "S01_J01":
   				martelo[int(ev.get("lugar", 0))] += 1
   	# (depois do laço)
   	for l in 4:
   		_esperar(martelo[l] >= 17, "S01_J01 P%d: a primeira volta inteira julgada (%d notas)" % [l + 1, martelo[l]])
   ```

**`godot/testes/captura_jogo.gd`** (as fotos): os momentos de `"centelha"`
leem o estado de antes. Troque os dois últimos por:

```gdscript
			["centelha_analogico", p1.call(func(sala, e) -> bool:
				var r = sala._runa(0)
				return r != null and r.tipo == "analogico" and sala._contar(int(e.setores)) >= 4)],
			["centelha_fole", p1.call(func(sala, e) -> bool:
				var r = sala._runa(0)
				return r != null and r.tipo == "gatilho" and float(e.b_nota) >= 0.0)],
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
(com o fim em tempo de música, cada Martelo leva 90 s de relógio); depois
`./run-local.sh -- --sala=centelha` com quatro controles: a runa acende no
tempo de cada um, a bigorna soa a nota de cada um, o R2 pesa no meio do fole,
o pico no meio se sente, e as espadas aparecem na estante. As três perguntas
da régua, respondidas no cabeçalho, conferidas jogando.

## Ao terminar

- `godot/scripts/traducoes.gd`: em `EN_PADROES`,
  `["^Espadas: (\\d+)$", "Swords: $1"]` (o título e o verbo a H04 já pôs).
- `"$GODOT" --headless --path godot --import --quit` e o `secao.gd.uid` no commit.
- No [quadro](README.md): se ainda não há as linhas dos minigames da seção,
  ponha I1 a I5 logo abaixo da linha **I** (com o link, M ou G, a
  estimativa, "a fazer"); marque a I1 **feito**, com o commit.
- Commit (sem trailer): `feat: O Martelo de Hefesto no tempo da música, com as espadas e a forja da seção`
