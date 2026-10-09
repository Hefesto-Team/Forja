# I1 — O Martelo de Hefesto

**Sprint:** I · **Slot:** S01_J01 · **Tamanho:** G · **Depende de:** H04, H08, F09, F03, F05, H07, G03, G05, G14, G15

## Por quê

Bater no tempo da própria nota com o botão que a runa pede: o verbo mais
simples do jogo e o primeiro da noite, e por baixo ele passa por todos os
botões, pelos dois analógicos até a borda e pelos dois gatilhos no meio e no
fundo — os vereditos da bancada de hoje continuam saindo daqui.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md) (o `minigame.gd` e o `martelo_de_hefesto.gd` que ela deixou)
- [O índice da seção](I-a-centelha.md) (as convenções da seção)

O resto (a linha n.º 1 em 03, a régua da diversão, a bíblia de arte, o mapa do
áudio, o RPG) está copiado nesta ficha, com os números. Não abra outro
documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s01/martelo_de_hefesto.gd` | reescrito inteiro | só desta |
| `godot/scripts/minigames/s01/secao.gd` | novo: a forja comum, a câmera, o exagero, a luz do dono, os ganchos | **da seção**: a I1 cria; I2 a I5 só chamam (nenhuma reescreve) |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO` e a função `momento()` | **de todos**: se outra ficha já pôs, não escreva de novo |
| `docs/jogo/13-arquitetura.md` | a linha `momento` na tabela «Os eventos do jogo» | **de todos**: se já existe, não escreva de novo |
| `godot/scripts/traducoes.gd` | `["^Espadas: (\\d+)$", "Swords: $1"]` em `EN_PADROES`; sai a linha da frase «Aperte o botão da runa antes do anel fechar.» | **de todos** |
| `godot/testes/prova_do_jogo.gd` | a contagem do Martelo e as checagens dos momentos em `_prova_do_relatorio()` | **de todos** |
| `godot/testes/captura_jogo.gd` | os dois momentos de `"centelha"` | **de todos** |

O `.uid` novo (`secao.gd.uid`) sai do import:
`"$GODOT" --headless --path godot --import --quit`, e entra no commit.

**A frase sai.** A diversão corta «Aperte o botão da runa antes do anel
fechar.» (o quadro 01 de conceito): o `martelo_de_hefesto.gd` novo não tem
`acao` nem `objetivo`. Em `godot/scripts/traducoes.gd`, a linha dela (hoje a
`:60`) sai só se `grep -rn "antes do anel fechar" godot/scripts` mostrar
apenas ela; se mostrar outro arquivo, ela fica e a resposta da sessão diz
qual.

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; raia(l) -> Node3D
acender_raia(l, forca); posicionar(l)          # posicionar põe o boneco na raia, de mãos livres
julgar_toque(l, t_alvo, n := -1, perigo := false) -> int   # chama toque() ou falha()
nota_perdida(l, n); nova_nota(l, n, t_alvo); anotar(tipo, l, campos := {})
andamento() -> float (0..1); no_pico() -> bool; tempo_jogado() -> float; marcar(l, pontos)
proxima_batida(l, depois_de, passo, desloc) -> float
var duracao; var _raias  ## lugar -> {raiz, mat_borda, luz}
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const BATIDA_DA_PRIMEIRA_NOTA := 4
```

Do `Forja` e do `Ritmo`: `Forja.sentir(l, nome, ms := -1)` (F05: `toque`,
`acerto`, `perfeito`, `erro`, `golpe`, `explosao`, `aviso`, `golpe_esq`,
`golpe_dir`), `Forja.som_falante(l, som, ganho)`, `Forja.som_haptica(l, esq,
dir, ganho)`, `Forja.gatilho(l, lado, modo, a, b, c)` (lado 0 = L2, 1 = R2),
`Forja.cor_do_lugar(l)`, `Forja.eixo`, `Forja.apertou`, `Forja.robo_apertar`,
`Forja.robo_eixo`, `Forja.robo_acerta()` (F09), `Ritmo.t_musica()`,
`Ritmo.batida()`, `Ritmo.t_da_batida(b)`, `Ritmo.bpm`, `Ritmo.simples[l]`.
Do G03: `Itens.antecipacao_s(l, bpm)` (a Lanterna). Da G15: `Tema.neon(cor,
energia, dono)`, `Tema.emissivo(material, energia, dono)` e
`Tema.luz_da_secao(secao, lado)`; o dono é um lugar (teto 3,0), `"mundo"` (1,2)
ou `"forja"` (2,4). `Forja.vibrar` não é para a sala (F05): só `Forja.sentir`.

### A função `momento` (em `minigame.gd`, de todos)

O tipo `momento` é o da régua da diversão (itens 4 e 8). A I1 é o primeiro
minigame do jogo e o acrescenta; a L1 traz o mesmo código, igual. Se já
existe, não escreva de novo. Em `TIPOS_DO_JOGO`, acrescente `"momento"` ao fim
da lista. Ao fim do arquivo:

```gdscript
## Um momento de grito (docs/jogo/diversao/README.md, itens 4 e 8): a linha
## `momento` com o nome, o tempo de música e onde o objeto dele está na tela
## (x_tela e altura_tela, de 0 a 1). `l` é -1 quando o momento é de todos.
func momento(nome: String, l: int, pos: Vector3, altura_m: float, campos := {}) -> void:
	var c: Dictionary = campos.duplicate()
	c["nome"] = nome
	c["t_musica"] = snappedf(Ritmo.t_musica(), 0.001)
	var cam := get_viewport().get_camera_3d()
	var tam := get_viewport().get_visible_rect().size
	if cam and tam.y > 0.0:
		var base := cam.unproject_position(pos)
		var topo := cam.unproject_position(pos + Vector3.UP * altura_m)
		c["x_tela"] = snappedf(base.x / tam.x, 0.001)
		c["altura_tela"] = snappedf(absf(base.y - topo.y) / tam.y, 0.001)
	anotar("momento", l, c)
```

No [13](../13-arquitetura.md), na tabela «Os eventos do jogo», depois da linha `estacao`:
`| \`momento\` | o momento de grito do minigame: \`nome\`, \`t_musica\`, \`x_tela\` e \`altura_tela\` (0 a 1); \`lugar\` 0 quando é de todos (docs/jogo/diversao/README.md) |`.

## Como se joga

### A ficha de dados

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

### O estado de hoje

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

### As regras

- **A faixa:** `MUS_S01_J01`; até a H05, a trilha sintetizada da seção a
  108 bpm (um tempo = 0,556 s); com a faixa gerada, 122 bpm (0,492 s).
- **A contagem:** batidas 0 a 3; a primeira nota de cada lugar é a batida
  `4 + 0,5·l`. Na contagem, cada ferreiro bate o martelo no ar na sua
  colcheia do hoqueto (P1 no 1, P2 no «e», P3 no 2, P4 no «e» do 2, duas
  vezes): a sala vê a ordem antes de jogar.
- **O hoqueto em colcheias:** a nota do lugar `l` cai nas batidas
  `2k + 0,5·l` (P1 no 1 e no 3 do compasso, P2 no «e» do 1 e do 3, P3 no 2 e
  no 4, P4 no «e» do 2 e do 4). Uma nota a cada 2 tempos por lugar; os
  quatro juntos fazem colcheias seguidas. `Ritmo.simples[l]`: uma a cada 4
  tempos.
- **A runa de botão:** acende 2 tempos antes da nota (mais a pista do Faro,
  de −40 a +40 ms, e meio tempo com a Lanterna), com o glifo do botão e o anel
  na cor do lugar; o anel fecha até a batida da nota. O botão certo →
  `julgar_toque`. Outro botão da lista, com a runa acesa → erro (a linha
  `entrada` diz qual chegou). Nada até `FOLGA_PERDIDA` (0,14 s) depois da nota
  → nota perdida.
- **A runa do círculo** (um analógico): acende já; o lugar gira o analógico
  até a borda (0,85) pelas oito direções; as marcas acendem uma a uma. Com
  as oito, a runa troca para o glifo do analógico e marca a nota na próxima
  batida do lugar, pelo menos 1 tempo adiante. Na primeira volta: **crave**
  com L3 (ou R3) na nota. Da segunda em diante: **segure na borda e solte na
  nota** (o toque é o instante em que o analógico volta abaixo de 0,3). 8
  tempos sem fechar o círculo → nota perdida.
- **A runa do fole** (um gatilho): acende já; segure o gatilho na faixa do
  meio (35 % a 62 %) por um tempo inteiro de música (`60 / Ritmo.bpm` s).
  Cheio, o fole sopra e marca a nota como no círculo: **afunde até o fundo**
  (92 %) na nota; o instante em que o gatilho cruza 92 % é o toque. No R2, a
  resistência (Feedback, posição 3, força 4) começa na faixa: o dedo acha o
  meio sem olhar.
- **A fila, primeira volta (a da bancada):** os treze botões embaralhados
  pela semente (`rng`), com o círculo e o fole de um lado depois do 3.º e do
  6.º botão e os do outro lado depois do 9.º e do 12.º (o lado que vem
  primeiro também pela semente). 17 notas por lugar (13 + 2 círculos + 2
  foles), uns 20 a 35 s de música.
- **A fila, da segunda volta em diante:** ✕ ○ □ △ L1 R1 embaralhados, com um
  círculo (o lado pela semente) depois do 3.º e o fole do R2 depois do 6.º:
  8 runas por volta. Saem as setas, o Create e o crave: procurar o botão não é
  ritmo. Runa errada ou perdida volta para o fim da fila, até três
  tentativas, nas duas filas.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 60, 80, 100]`;
  a nota do círculo e a do fole valem 2,5 vezes; o combo soma
  `10 × (combo − 1)`, no máximo +100.
- **As espadas:** cada acerto é um golpe (a nota especial, dois); seis golpes
  forjam uma espada, que aparece na estante atrás da bigorna. De 2/3 em
  diante (a reta), **cinco golpes** forjam uma espada. Nas **últimas 16
  batidas**, a espada que fica pronta é **de ouro e conta 2**.
- **A racha:** o erro racha a espada em curso: menos dois golpes, e uma lasca
  cai e fica no chão ao lado da bigorna. Com a espada a um golpe de ficar
  pronta (5 golpes; 4 na reta), a lâmina de cima voa: é o momento
  `racha_no_quinto` (A diversão).
- **A queda:** depois do erro, a runa seguinte só acende depois de 2 tempos ×
  o Fôlego (de 1,5 a 2,5 tempos), arredondados à semicolcheia.
- **A progressão:** `andamento()` do kit (0..1 dos 90 s de música). De 0 a
  1/3, uma runa a cada 2 tempos. **O pico (1/3 a 2/3), a espada em brasa:**
  toda runa de botão acertada pede um segundo golpe um tempo depois, com o
  mesmo botão; cada lugar bate em todo tempo, e os quatro fazem
  semicolcheias; a luz da forja sobe. **De 2/3 em diante, a reta:** uma runa a
  cada 2 tempos, a espada com 5 golpes e, nas últimas 16 batidas, a de ouro.
  Quantas notas por lugar em 90 s: ~75 a 108 bpm, ~85 a 122 bpm.

### A falha

O martelo quica: faísca apagada (`Efeitos.faiscas(self, topo, Tema.GRAFITE, 10, 0.5)`),
a runa treme (`e.tremor = 1.0`), a espada em curso racha (−2 golpes), o
combo zera e o boneco faz `emote-no` (0,6 s). A runa volta para o fim da
fila. Recuperação: a próxima runa só acende depois da queda (2 tempos × o
Fôlego, de 1,5 a 2,5 tempos).

A lasca da racha (uma caixa de grafite de 0,3 × 0,05 × 0,1 m) cai em meia
batida da bigorna até `bigorna + (0,7, 0,05 + 0,06·k, 0,4)` e fica até o fim:
o placar do azar; só cai quando havia golpe na bigorna (`tinha` ≥ 1).

### O fim e o vencedor

O kit fecha aos 90 s de música (`"fim": "tempo"`, F03 e H08); a runa some
com a fase. `vencedor()`: mais espadas (a de ouro conta 2); no empate, mais pontos;
depois, o lugar menor.

### Com menos de quatro

Nada muda: cada lugar tem a sua fração do compasso, e quem falta deixa o
buraco na música. **O controle que cai:** a runa dele para (sem erro, sem
`med_pedido`); quando volta, a runa da vez reacende a partir da batida de
agora (`_acender(l, Ritmo.batida())`). O fim não espera quem está sem
controle (a `SalaJogo` já não espera).

### O robô

Só pelo controle simulado; mira pelo relógio da música; consulta
`Forja.robo_acerta()` uma vez por nota. Botão: aperta na nota (ou 200 ms
atrasado: erro). Círculo: uma volta a cada 3 tempos, na borda; crava na nota (na
primeira volta) ou segura na borda e solta na nota (da segunda em diante).
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
			elif int(e.voltas) >= 1:
				# sem crave: segura na borda até 60 ms antes da mira; o eixo volta sozinho ao centro na mira
				if agora < alvo_t - 0.06:
					Forja.robo_eixo(l, Forja.RX if direito else Forja.LX, 1.0, 0.06)
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

### O código

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
## Da segunda volta em diante, só ✕ ○ □ △, L1, R1, o círculo (solto na nota)
## e o fole do R2. Na reta, a espada sai com 5 golpes; nas últimas 16
## batidas, a espada pronta é de ouro e conta 2.
##
## A falha: o martelo quica, a espada racha (dois golpes a menos, e a lasca
## fica no chão) e o boneco balança a cabeça; a runa volta para o fim da fila
## (até três vezes). Com a espada a um golpe de pronta, a lâmina voa.
## O vencedor: mais espadas (a de ouro conta 2); no empate, mais pontos.
## O alto-falante do dono: a nota dele no perfeito (o kit), o martelo nos
## outros acertos, a coleta na espada.
## O registro mede: cada botão, analógico e gatilho pedido e respondido (as
## medidas do núcleo, que servem à bancada), cada nota e toque (o kit) e os
## momentos `racha_no_quinto` e `reta`.
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
const GOLPES_NA_RETA := 5  ## de 2/3 em diante, a espada sai com 5 golpes
const QUEDA_TEMPOS := 2.0  ## depois do erro, a runa seguinte espera 2 tempos × o Fôlego (minigames.csv)
## Da segunda volta em diante: os botões que a mão acha sem olhar.
const BOTOES_DEPOIS := [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.L1, Forja.R1]
const SOLTO := 0.3  ## o círculo sem crave: o toque é o analógico voltar abaixo disto
# BATIDA_DA_PRIMEIRA_NOTA, FOLGA_PERDIDA, proxima_batida, no_pico e progresso: do kit (H08)

var j := {}  ## lugar -> o estado do jogador
var runas := {}  ## lugar -> os nós da runa
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]  ## [lugar][julgamento], para a prova
var fogos := {}  ## lugar -> a luz da forja dele (o SECAO.so_o_dono baixa a dos outros)
var cena := {}  ## o que o SECAO.montar devolveu: a chave, a fornalha, o pico, o tremor
var _adiados: Array = []  ## o que cai na próxima colcheia (SECAO.adiar)
var _colcheia_vista := -1  ## a contagem
var _reta_marcada := false


func montar() -> void:
	cena = SECAO.montar(self, SECAO.CAMERA_OLHAR, 18.0)  # a arena a 18 m: a bigorna do P4 cabe nos 60 % do meio
	for p in jogadores:
		var l: int = p.lugar
		Kit.bigorna(self, _bigorna(l), 0.62)
		p.position = Vector3(RAIAS[l] - 1.05, 0.05, 1.15)
		p.olhar_para(_bigorna(l))
		martelo_na_mao(p)
		var fogo := OmniLight3D.new()
		fogo.position = _bigorna(l) + Vector3(0, 1.4, 0.8)
		fogo.light_color = Forja.cor_do_lugar(l).lerp(Tema.TUNGSTENIO, 0.5)
		fogo.light_energy = 0.9
		fogo.omni_range = 4.0
		add_child(fogo)
		fogos[l] = fogo
		Kit.peca(self, "wood-structure", _bigorna(l) + Vector3(0, 0, -1.9), 0.0, 1.2)
		runas[l] = _montar_runa(l)
		j[l] = _novo_jogador()
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A bigorna de cada um, à frente e à direita do ferreiro.
static func _bigorna(l: int) -> Vector3:
	return Vector3(RAIAS[l] + 0.45, 0.0, 0.3)


## A fila de uma volta. A primeira (volta 0) é a da bancada: os treze botões,
## os dois círculos e os dois foles. Da segunda em diante, a fila curta.
func _nova_fila(volta := 0) -> Array:
	if volta >= 1:
		return _fila_curta()
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
		"robo_n": -1, "robo_mira": 0.0, "robo_feito": false, "caido_b": -1.0, "lascas": 0,
		"penduradas": 0}


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
	desde = maxf(desde, float(e.caido_b))  # depois do erro, a queda do Fôlego
	if str(r.tipo) == "botao":
		e.b_nota = _proxima_batida(l, desde + ANTES)
		# a pista (o Faro, ±40 ms, e a Lanterna, meio tempo): a runa acende antes; a nota não muda
		e.b_luz = float(e.b_nota) - ANTES - SECAO.antecedencia(l) * Ritmo.bpm / 60.0
		nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b_nota)))
		return
	e.b_luz = maxf(desde, BATIDA_DA_PRIMEIRA_NOTA - ANTES)
	e.b_nota = -1.0
	if str(r.tipo) == "gatilho" and int(r.alvo) == 1:
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 3, 4)


func jogar(dt: float) -> void:
	SECAO.passar(self, cena, no_pico())
	SECAO.rodar_adiados(_adiados)
	_contagem()
	if not _reta_marcada and fase == "jogo" and SECAO.na_reta(self):
		_reta_marcada = true
		var valores := PackedStringArray(presentes().map(func(x): return str(int(j[x].espadas))))
		momento("reta", -1, Vector3(0, 0, -1.6), 2.4, {"objeto": "estante", "valores": ",".join(valores)})
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
	if int(e.voltas) >= 1:
		# da segunda volta em diante, sem crave: segura na borda e solta na nota
		Forja.med_pedido(l, -1)
		var x2 := Forja.eixo(l, Forja.RX if direito else Forja.LX)
		var y2 := Forja.eixo(l, Forja.RY if direito else Forja.LY)
		if Vector2(x2, y2).length() < SOLTO:
			julgar_toque(l, Ritmo.t_da_batida(float(e.b_nota)), int(e.n))
		elif Ritmo.t_musica() > Ritmo.t_da_batida(float(e.b_nota)) + FOLGA_PERDIDA:
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
		if int(e.golpes) >= _golpes_por_espada():
			e.golpes = int(e.golpes) - _golpes_por_espada()
			var ouro := SECAO.na_reta(self)  # nas últimas 16 batidas, a espada é de ouro e conta 2
			e.espadas = int(e.espadas) + (2 if ouro else 1)
			e.penduradas = int(e.penduradas) + 1
			_pendurar_espada(l, int(e.penduradas), ouro)
	e.pop = 1.0
	var topo := _bigorna(l) + Vector3(0, 0.8, 0)
	Efeitos.faiscas(self, topo, Forja.cor_do_lugar(l), 26 if julgamento == Ritmo.PERFEITO else 12, 1.0)
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
	var tinha := int(e.golpes)
	if not treinando:
		e.golpes = maxi(0, tinha - 2)  # a espada racha
		if tinha >= 1:
			# a lasca (e, a um golpe da espada pronta, a lâmina que voa) cai na próxima colcheia
			SECAO.adiar(_adiados, _racha.bind(l, tinha >= _golpes_por_espada() - 1, tinha))
	e.caido_b = Ritmo.batida() + SECAO.queda_s(l, QUEDA_TEMPOS) * Ritmo.bpm / 60.0
	Efeitos.faiscas(self, _bigorna(l) + Vector3(0, 0.8, 0), Tema.GRAFITE, 10, 0.5)  # o martelo quica
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
		e.fila = _nova_fila(int(e.voltas))
		e.atual = 0
	_acender(l, anterior if anterior >= 0.0 else Ritmo.batida())


func _pendurar_espada(l: int, k: int, ouro := false) -> void:
	Forja.sentir(l, "golpe")
	Forja.som_falante(l, "coleta", 0.7)
	var pos := _bigorna(l) + Vector3(-0.9 + 0.24 * (k - 1), 0.15, -1.75)
	Efeitos.faiscas(self, pos + Vector3(0, 0.8, 0), Tema.TUNGSTENIO if ouro else Forja.cor_do_lugar(l),
		48 if ouro else 20, 0.8)
	Som.tocar("sucesso", pos, -6.0 if ouro else -10.0)
	if ouro:
		SECAO.exagero(self, cena, "estrondo", jogador(l))
	if k <= 8:  # a estante tem oito ganchos; as outras contam e não aparecem
		var espada := Kit.peca(self, "weapon-sword", pos, 0.0, 1.6)
		if ouro:
			# a espada de ouro: a malha inteira no tungstênio da forja (o teto da forja, 2,4)
			var mat := Tema.neon(Tema.TUNGSTENIO, 2.4, "forja")
			for m in espada.find_children("*", "MeshInstance3D", true, false):
				(m as MeshInstance3D).material_override = mat


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


## Quantos golpes fazem uma espada agora: 6, e 5 de 2/3 em diante (a reta).
func _golpes_por_espada() -> int:
	return GOLPES_NA_RETA if andamento() >= 2.0 / 3.0 else GOLPES_POR_ESPADA


## Da segunda volta em diante: os seis botões que a mão acha sem olhar,
## embaralhados pela semente, com um círculo (o lado pela semente) depois do
## 3.º e o fole do R2 depois do 6.º. São 8 runas por volta.
func _fila_curta() -> Array:
	var ordem := BOTOES_DEPOIS.duplicate()
	for i in range(ordem.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = ordem[i]
		ordem[i] = ordem[k]
		ordem[k] = tmp
	var fila: Array = []
	for i in ordem.size():
		fila.append({"tipo": "botao", "alvo": ordem[i], "tentativas": 0})
		if i == 2:
			fila.append({"tipo": "analogico", "alvo": rng.randi_range(0, 1), "tentativas": 0})
		elif i == 5:
			fila.append({"tipo": "gatilho", "alvo": 1, "tentativas": 0})
	return fila


## A contagem (batidas 0 a 3): cada ferreiro bate o martelo no ar no seu tempo
## do hoqueto (a colcheia c é do lugar c % 4: P1 no 1, P2 no "e", P3 no 2, P4
## no "e" do 2), com o martelo baixo na TV e o pulso nos atuadores dele.
func _contagem() -> void:
	var b := Ritmo.batida()
	if b < 0.0 or b >= float(BATIDA_DA_PRIMEIRA_NOTA):
		return
	var c := int(floor(b * 2.0))
	if c == _colcheia_vista:
		return
	_colcheia_vista = c
	var l := c % 4
	var p := jogador(l)
	if p == null or not na_raia(l):
		return
	p.gesto("attack-melee-right", 0.3)
	Som.tocar("martelo", _bigorna(l) + Vector3(0, 0.8, 0), -12.0)
	Forja.som_haptica(l, "pulso", "pulso", 0.35)


## A espada em curso racha (toda falha com golpes na bigorna): a lasca cai e
## fica no chão ao lado da bigorna até o fim, uma por racha, empilhadas (até
## 12 à vista). Com a espada a um golpe de ficar pronta, é o momento
## `racha_no_quinto`: a lâmina de cima voa 1 m para o lado num arco de 1 m de
## altura, em 1 batida; o dono fica com o cabo; a bigorna aguda soa desafinada;
## só a forja dele fica acesa. Roda na colcheia seguinte à falha (SECAO.adiar).
func _racha(l: int, voa: bool, tinha: int) -> void:
	var e: Dictionary = j[l]
	var k := int(e.lascas)
	e.lascas = k + 1
	var topo := _bigorna(l) + Vector3(0, 0.8, 0)
	var chao := _bigorna(l) + Vector3(0.7, 0.05 + 0.06 * mini(k, 11), 0.4)
	var tamanho := Vector3(0.55, 0.05, 0.12) if voa else Vector3(0.3, 0.05, 0.1)
	var lasca := Kit.caixa(self, tamanho, topo, Kit.material(Tema.GRAFITE, 0.0, 0.6))
	lasca.rotation.y = 0.35 * k
	var batida := 60.0 / Ritmo.bpm
	if not voa:
		lasca.create_tween().tween_property(lasca, "position", chao, 0.5 * batida) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		return
	var voo := func(q: float) -> void:
		var pos := topo.lerp(chao, q)
		pos.y += sin(q * PI) * 1.0
		lasca.position = pos
		lasca.rotation.z = q * TAU
	lasca.create_tween().tween_method(voo, 0.0, 1.0, batida)
	Som.tocar("bigorna_aguda", topo, 0.0, 0.94)  # desafinada: o estrondo no som
	Som.tocar("golpe", topo, -4.0)
	Forja.sentir(l, "golpe")
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.6)  # o cabo na mão, sem a lâmina
	SECAO.exagero(self, cena, "golpe", p)
	SECAO.so_o_dono(self, l, fogos)
	momento("racha_no_quinto", l, _bigorna(l), 3.3, {"golpes": tinha})
```

O que se vê (no fim do arquivo, antes do robô): o `_montar_runa(l)`, inteiro.
É o da Centelha antiga com quatro trocas: o anel facetado (`rings` 8,
`ring_segments` 4), as marcas em caixa, as cores nos tokens com dono, e os
dois materiais das marcas criados uma vez.

```gdscript
func _montar_runa(l: int) -> Dictionary:
	var raiz := Node3D.new()
	raiz.position = _bigorna(l) + Vector3(0, 2.55, 0)
	raiz.visible = false  # acende quando o jogo começa
	add_child(raiz)
	var glifo := Sprite3D.new()
	glifo.pixel_size = 0.0062
	glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glifo.shaded = false
	glifo.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	raiz.add_child(glifo)
	var cor: Color = Forja.cor_do_lugar(l)
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.66
	t.outer_radius = 0.74
	t.rings = 8  # facetado: oito lados
	t.ring_segments = 4
	anel.mesh = t
	anel.rotation.x = PI * 0.5
	anel.material_override = Tema.neon(cor, 2.2, l)
	raiz.add_child(anel)
	var mat_aceso := Tema.neon(cor, 2.0, l)
	var mat_apagado := Kit.material(Tema.GRAFITE, 0.0)
	var marcas: Array = []
	for s in 8:
		var m := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(0.12, 0.12, 0.12)
		m.mesh = caixa
		var ang := s * PI / 4.0
		# setor 0 = direita, sentido horário na tela (y do analógico para baixo)
		m.position = Vector3(cos(ang) * 0.95, -sin(ang) * 0.95, 0)
		m.material_override = mat_apagado
		raiz.add_child(m)
		marcas.append(m)
	# o fole: o trilho, a faixa do meio (35–62%), o topo (92%) e o nível
	var fole := Node3D.new()
	fole.position = Vector3(1.05, -0.7, 0)
	raiz.add_child(fole)
	var trilho := MeshInstance3D.new()
	var bt := BoxMesh.new()
	bt.size = Vector3(0.16, 1.4, 0.04)
	trilho.mesh = bt
	trilho.position.y = 0.7
	trilho.material_override = Kit.material(Tema.GRAFITE)
	fole.add_child(trilho)
	var faixa := MeshInstance3D.new()
	var bf := BoxMesh.new()
	bf.size = Vector3(0.22, 1.4 * 0.27, 0.05)
	faixa.mesh = bf
	faixa.position.y = 1.4 * (0.35 + 0.62) * 0.5
	faixa.material_override = Tema.neon(Tema.TUNGSTENIO, 0.9, "forja")
	fole.add_child(faixa)
	var topo := MeshInstance3D.new()
	var btp := BoxMesh.new()
	btp.size = Vector3(0.22, 1.4 * 0.08, 0.05)
	topo.mesh = btp
	topo.position.y = 1.4 * 0.96
	topo.material_override = Tema.neon(Tema.TUNGSTENIO, 1.6, "forja")
	fole.add_child(topo)
	var nivel := MeshInstance3D.new()
	var bn := BoxMesh.new()
	bn.size = Vector3(0.1, 1.0, 0.07)
	nivel.mesh = bn
	nivel.material_override = Tema.neon(cor, 1.6, l)
	fole.add_child(nivel)
	return {"raiz": raiz, "glifo": glifo, "anel": anel, "marcas": marcas, "fole": fole, "nivel": nivel,
		"faixa": faixa, "topo": topo, "mat_aceso": mat_aceso, "mat_apagado": mat_apagado}
```

O `_mostrar_runa(l)`:

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
	glifo.modulate = Tema.ETIQUETA.lerp(Forja.cor_do_lugar(l), float(e.pop))
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
		m.material_override = n.mat_aceso if aceso else n.mat_apagado
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

(Os dois materiais das marcas nascem uma vez, no `_montar_runa`; o
`_mostrar_runa` só troca qual.)

### O que o registro mede

- As medidas do núcleo, como hoje: `med_pedido` (o botão da runa acesa),
  `med_pedir` (o círculo e o fole pedidos), `med_faixa` (o meio do fole) —
  dão os vereditos `botoes`, `analogicos` e `gatilhos_analogicos` da bancada.
- O kit: uma linha `nota` por nota (o instante do pedido em tempo de música)
  e uma `toque` por resposta (o desvio e o julgamento, ou `perdida`).
- A linha `entrada`: o botão que chegou no lugar do pedido (uma troca no
  caminho aparece aqui, noite toda), o círculo fechado e o fole cheio.
- A linha `momento`: `racha_no_quinto` (o lugar, `golpes` que havia na
  bigorna, `x_tela`, `altura_tela`) e `reta` (uma vez, de todos, com
  `objeto` `estante` e `valores`, as espadas de cada lugar presente).

### Armadilhas

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
- **A racha e o momento caem na colcheia** seguinte à falha (`SECAO.adiar`),
  nunca no instante do julgamento: a `nota_perdida` chega 140 ms depois da
  nota, fora da grade, e a régua (item 9) quer o momento a até 1 quadro de
  uma colcheia.
- **Os golpes da racha** são os de antes do erro (`tinha`): o `e.golpes` já
  caiu dois quando a colcheia chega.
- **A espada de ouro conta 2 em `espadas`**, e `penduradas` conta os ganchos
  da estante (uma por espada, de ouro ou não). O `vencedor()` e o `status()`
  leem `espadas`.
- **A segunda volta não pede crave nem as setas nem o Create**: os vereditos
  da bancada saem só da primeira (`voltas` 0).
- **A queda** só adia a próxima runa (`caido_b`); a nota da vez, já julgada,
  não volta.
- **Nenhum material brilha fora de `Tema.neon`, `Tema.contorno` e
  `Tema.emissivo`** (G15); `Kit.material(cor, energia)` com energia acima de
  0 sai desta ficha.

## A cena

### A câmera

A arena do cinema: lente de 35 mm (FOV vertical 37,8°), plongée de 50°, o modo
`fixa` da G05, e **não corta** do apito ao apito. `SECAO.montar(self,
SECAO.CAMERA_OLHAR, 18.0)` põe a câmera em `(0, 14,99, 11,37)` olhando
`(0, 1,2, −0,2)`: o centro visto a 18 m, 50° abaixo da horizontal. Com 35 mm
em 16:9, o quadro cobre de x = −10,96 a 10,96 no centro e, no chão, de
z = 5,6 (a borda de baixo) a z = −13,4 (a de cima): as quatro bigornas, as
estantes, as runas e os ferreiros cabem inteiros, e a bigorna do P4
(x = 6,45) fica em x_tela 0,79, dentro dos 60 % do meio. A lente é a da G05;
até a G05 entrar, os 40° de hoje mostram 6 % a mais em volta e nada sai do
quadro.

- **O pico** (`no_pico()`): a câmera recua 10 % (a 19,8 m) e volta ao sair
  do pico; o `lerp` do main faz o caminho (nunca salta).
- **O tremor é do evento**: só o de `SECAO.exagero`. Nenhum tremor de
  ambiente, roll zero.

### A luz da seção

S1 é o vermelhão (`Tema.SECAO[0]`, `#c8432f`), lado A.
`Tema.luz_da_secao(0, "A")` (G15) devolve a névoa `#210502`, o preenchimento
`#602016` e a chave `#ffc99c`. A névoa é do main (a G15 a põe pela seção do
slot). O `secao.gd` põe o preenchimento (o `atmosfera` da sala, com as brasas),
a chave (uma `OmniLight3D` em `(0, 8, 3)`, energia 0,9, alcance 26) e a
fornalha do fundo (`Tema.TUNGSTENIO`, energia 1,4, alcance 8, em
`(0, 1,2, −6)`).

- **A forja de cada um:** uma `OmniLight3D` sobre a bigorna, a cor do lugar
  misturada ao tungstênio (0,5), energia 0,9, alcance 4.
- **O pico:** a chave e a fornalha sobem 20 % em 1 batida (curva
  `ENTRA_SAI`) e voltam em 2 batidas quando o pico acaba. Com
  `Opcoes.flashes` desligado: +10 % em 2 batidas.
- **A racha com lâmina:** a forja dos outros lugares cai 30 % por 1 batida
  (`SECAO.so_o_dono`): a sala olha para quem rachou.

### As peças e o papel de cada uma

`cena = SECAO.montar(self, SECAO.CAMERA_OLHAR, 18.0)` (a forja da seção, abaixo)
e, por lugar:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a bigorna | `Kit.bigorna(self, pos, 0.62)` | `(RAIAS[l] + 0.45, 0, 0.3)` |
| o ferreiro | o boneco, `martelo_na_mao(p)`, olhando a bigorna | `(RAIAS[l] − 1.05, 0.05, 1.15)` |
| a luz da forja | `OmniLight3D`, cor do lugar misturada a `Tema.TUNGSTENIO` (0,5), 0,9, alcance 4; guardada em `fogos[l]` | bigorna + `(0, 1.4, 0.8)` |
| a estante | `wood-structure`, escala 1.2 | bigorna + `(0, 0, −1.9)` |
| as espadas | `weapon-sword`, escala 1.6, de pé | bigorna + `(−0.9 + 0.24·(k−1), 0.15, −1.75)`, até 8 |
| a runa | glifo em `Sprite3D`, anel facetado, 8 marcas em caixa, o fole (trilho, faixa, topo, nível) | bigorna + `(0, 2.55, 0)` |

O brilho só na runa, nas espadas de ouro e nas faíscas. Nada usa a cor de
outro lugar.

O que esta ficha acrescenta:

| objeto | forma | material | papel |
| --- | --- | --- | --- |
| a lasca | caixa 0,3 × 0,05 × 0,1 (a da lâmina que voa, 0,55 × 0,05 × 0,12) | `Kit.material(Tema.GRAFITE, 0.0, 0.6)`, sem brilho | o rastro da racha, no chão até o fim |
| a espada de ouro | a `weapon-sword` da estante | `Tema.neon(Tema.TUNGSTENIO, 2.4, "forja")` em cada malha | conta 2; o placar da reta |
| a runa | o anel facetado (8 lados), 8 marcas em caixa de 0,12 m, o fole | veja «O que brilha» | a pista do tempo |

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08, arte/04) |
| o anel da runa | o lugar | `Tema.neon(cor, 2.2, l)` |
| a marca do círculo acesa | o lugar | `Tema.neon(cor, 2.0, l)`; apagada, `Kit.material(Tema.GRAFITE, 0.0)` |
| o nível do fole | o lugar | `Tema.neon(cor, 1.6, l)` |
| a faixa do meio do fole | a forja | `Tema.neon(Tema.TUNGSTENIO, 0.9, "forja")` |
| o topo do fole (o fundo) | a forja | `Tema.neon(Tema.TUNGSTENIO, 1.6, "forja")` |
| a espada de ouro | a forja | `Tema.neon(Tema.TUNGSTENIO, 2.4, "forja")` (o teto) |
| as faíscas do acerto e da espada | o lugar | `Forja.cor_do_lugar(l)` |
| as faíscas da espada de ouro | a forja | `Tema.TUNGSTENIO`, 48 partículas |
| as faíscas do martelo que quica | ninguém | `Tema.GRAFITE` (a faísca apagada) |
| a fornalha e a forja de cada um | a forja | luz, não material |

Nenhuma cor fora dos tokens: os `#ffb070`, `#ff9a52` e `#ff7a2a`, o
`Tema.ROSA`, o `Tema.AMARELO`, o `Tema.TRILHO`, o `Tema.LARANJA` e o
`Tema.FG` de hoje somem desta sala.

### O cenário da seção (`godot/scripts/minigames/s01/secao.gd`)

O arquivo inteiro:

```gdscript
extends RefCounted
## A seção A Centelha (S01, docs/jogo/tarefas/I-a-centelha.md): a forja do
## vermelhão, a câmera, o exagero do impacto, a luz só do dono, a reta e os
## ganchos do cavaleiro. Os cinco minigames montam com isto; o que é só de um
## fica no script dele. A barra de luz que pisca no julgamento é do kit (H08).
## Sem class_name: quem usa carrega pelo caminho,
## const SECAO := preload("res://scripts/minigames/s01/secao.gd").

const SECAO := 0  ## Tema.SECAO[0], o vermelhão
## A arena (docs/jogo/arte/01-cinema.md): 35 mm, plongée de 50°.
const CAMERA_OLHAR := Vector3(0, 1.2, -0.2)
const CAMERA_ANGULO := 50.0
const CAMERA_DISTANCIA := 14.0
## A corrida (I2, I3): 28 mm, atrás e acima, 30°, a 17 m.
const CORRIDA_ANGULO := 30.0
const CORRIDA_DISTANCIA := 17.0
## O exagero do impacto (docs/jogo/diversao/README.md#o-exagero-do-impacto).
const DEGRAUS := {
	"golpe": {"tremor_m": 0.02, "batidas": 1.0, "hit_stop": 2, "luz": 0.0},
	"estrondo": {"tremor_m": 0.05, "batidas": 2.0, "hit_stop": 3, "luz": 0.0},
	"catastrofe": {"tremor_m": 0.08, "batidas": 4.0, "hit_stop": 0, "luz": 0.4},
}
## O degrau golpe: o objeto a 130 % e de volta em 1/2 batida.
const ESCALA_DO_GOLPE := 1.3
## O main treme a câmera 0,12 m por unidade de `tremor` (main.gd:986-988).
const METROS_POR_TREMOR := 0.12
## As últimas batidas de todo minigame da seção: a reta (a régua, item 5).
const BATIDAS_DA_RETA := 16.0
## Os ganchos dos stats no neutro (stat 3), enquanto a classe Cavaleiro (G13)
## não existe (docs/jogo/sistemas/stats.csv).
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}


## A pose da câmera: [posição, alvo]. `recuo` 1,1 no pico.
static func pose_da_camera(recuo := 1.0, olhar := CAMERA_OLHAR, distancia := CAMERA_DISTANCIA,
		angulo := CAMERA_ANGULO) -> Array:
	var a := deg_to_rad(angulo)
	return [olhar + Vector3(0, sin(a), cos(a)) * distancia * recuo, olhar]


## A forja do vermelhão: o chão e as paredes do kit, as brasas, a chave, as
## tochas, o fundo (colunas, estandartes, a lenha, barris) e a fornalha. Põe
## a câmera. Devolve {chave, chave_energia, fornalha, fornalha_energia, pico,
## tremor_ate, luz_ate, olhar, distancia, angulo, camera}: o que `passar` e
## `exagero` mexem. Quem move a câmera sozinho (a Marcha) põe `camera` false.
static func montar(sala: SalaJogo, olhar := CAMERA_OLHAR, distancia := CAMERA_DISTANCIA,
		angulo := CAMERA_ANGULO) -> Dictionary:
	Kit.arena(sala, 5, 3)
	var luz: Dictionary = Tema.luz_da_secao(SECAO, "A")
	sala.atmosfera(luz.preenchimento, Tema.VIOLETA, true, 60)
	sala.luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])
	var chave := OmniLight3D.new()
	chave.position = Vector3(0, 8.0, 3.0)
	chave.light_color = luz.chave
	chave.light_energy = 0.9
	chave.omni_range = 26.0
	sala.add_child(chave)
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
	fornalha.light_color = Tema.TUNGSTENIO
	fornalha.light_energy = 1.4
	fornalha.omni_range = 8.0
	sala.add_child(fornalha)
	var pose := pose_da_camera(1.0, olhar, distancia, angulo)
	sala.camera_pos = pose[0]
	sala.camera_olhar = pose[1]
	return {"chave": chave, "chave_energia": chave.light_energy, "fornalha": fornalha,
		"fornalha_energia": fornalha.light_energy, "pico": false, "tremor_ate": -1.0, "luz_ate": -1.0,
		"olhar": olhar, "distancia": distancia, "angulo": angulo, "camera": true}


## A cada quadro: o pico (a chave e a fornalha +20 % em 1 batida, a câmera
## recua 10 %), o tremor que acaba e a luz da catástrofe que volta.
static func passar(sala: SalaJogo, c: Dictionary, no_pico: bool) -> void:
	var agora := Ritmo.t_musica()
	var batida := 60.0 / Ritmo.bpm
	if no_pico != bool(c.pico):
		c.pico = no_pico
		if bool(c.camera):
			var pose := pose_da_camera(1.1 if no_pico else 1.0, c.olhar, c.distancia, c.angulo)
			sala.camera_pos = pose[0]
			sala.camera_olhar = pose[1]
		var sobe := (0.2 if Opcoes.flashes else 0.1) if no_pico else 0.0
		var em := (1.0 if Opcoes.flashes else 2.0) if no_pico else 2.0
		var tw := sala.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(c.chave, "light_energy", float(c.chave_energia) * (1.0 + sobe), em * batida)
		tw.tween_property(c.fornalha, "light_energy", float(c.fornalha_energia) * (1.0 + sobe), em * batida)
	if float(c.tremor_ate) >= 0.0 and agora >= float(c.tremor_ate):
		sala.tremor = 0.0
		c.tremor_ate = -1.0
	if float(c.luz_ate) >= 0.0 and agora >= float(c.luz_ate):
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.2 if c.pico and Opcoes.flashes else 1.0)
		c.luz_ate = -1.0


## O exagero do impacto, pelo degrau: o tremor (em m, por batidas), o hit-stop
## do boneco (em quadros), a luz da catástrofe (por 1 batida) e, no golpe, o
## objeto a 130 % que volta em meia batida.
static func exagero(sala: SalaJogo, c: Dictionary, degrau: String, boneco: Node3D = null,
		objeto: Node3D = null) -> void:
	var d: Dictionary = DEGRAUS[degrau]
	var batida := 60.0 / Ritmo.bpm
	sala.tremor = maxf(sala.tremor, float(d.tremor_m) / METROS_POR_TREMOR)
	c.tremor_ate = Ritmo.t_musica() + float(d.batidas) * batida
	if int(d.hit_stop) > 0 and boneco and Opcoes.tremor:
		congelar(boneco, int(d.hit_stop))
	if degrau == "golpe" and objeto:
		var base: Vector3 = objeto.get_meta("escala", objeto.scale)
		objeto.set_meta("escala", base)
		objeto.scale = base * ESCALA_DO_GOLPE
		objeto.create_tween().tween_property(objeto, "scale", base, 0.5 * batida) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if float(d.luz) > 0.0:
		var k := float(d.luz) if Opcoes.flashes else float(d.luz) * 0.5
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.0 + k)
		c.luz_ate = Ritmo.t_musica() + batida


## O hit-stop visual: a animação do boneco para `quadros` quadros (60 por s).
## O relógio, o julgamento e a física nunca param.
static func congelar(boneco: Node3D, quadros: int) -> void:
	var anim: AnimationPlayer = boneco.get("anim")
	if anim == null:
		return
	var antes := anim.speed_scale
	anim.speed_scale = 0.0
	boneco.get_tree().create_timer(quadros / 60.0).timeout.connect(func(): anim.speed_scale = antes)


## A luz dos outros lugares cai 30 % por 1 batida (o momento de um só).
## `luzes` (lugar -> OmniLight3D) é a luz de cada um quando o minigame não usa
## a raia do kit (o Martelo: a forja da bigorna); sem ela, a luz da raia.
static func so_o_dono(sala: Minigame, dono: int, luzes := {}) -> void:
	var batida := 60.0 / Ritmo.bpm
	for l in sala.presentes():
		if l == dono:
			continue
		var luz: OmniLight3D = luzes.get(l, null)
		if luz == null:
			var r: Dictionary = sala._raias.get(l, {})
			if r.is_empty():
				continue
			luz = r.luz
		var base: float = luz.get_meta("energia", luz.light_energy)
		luz.set_meta("energia", base)
		luz.light_energy = base * 0.7
		sala.get_tree().create_timer(batida).timeout.connect(func(): luz.light_energy = base)


## As últimas 16 batidas do minigame (a reta). `fim_b` é a batida do fim
## quando ele chega antes da duração (a corrida, depois do primeiro na meta).
static func na_reta(sala: Minigame, fim_b := -1.0) -> bool:
	var b_fim := Ritmo.batida() + (sala.duracao - sala.tempo_jogado()) * Ritmo.bpm / 60.0
	if fim_b >= 0.0:
		b_fim = minf(b_fim, fim_b)
	return Ritmo.batida() >= b_fim - BATIDAS_DA_RETA


## Guarda `f` para a próxima colcheia: o momento cai a até 1 quadro dela
## (a régua, item 9), nunca no instante torto de um julgamento.
static func adiar(fila: Array, f: Callable) -> void:
	fila.append([ceilf(Ritmo.batida() * 2.0) / 2.0, f])


## A cada quadro: chama o que a colcheia de agora alcançou.
static func rodar_adiados(fila: Array) -> void:
	for item in fila.duplicate():
		if Ritmo.batida() >= float(item[0]):
			fila.erase(item)
			(item[1] as Callable).call()


## O gancho do stat do cavaleiro do lugar (docs/jogo/sistemas/README.md#os-stats):
## o da classe Cavaleiro (G13) quando ela existe; o neutro enquanto não.
static func gancho(l: int, nome: String) -> float:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == "Cavaleiro":
			return float(load(c["path"]).gancho(l, nome))
	return float(NEUTRO[nome])


## A antecedência da pista do lugar, em s: o Faro (±40 ms) e a Lanterna (meio tempo).
static func antecedencia(l: int) -> float:
	return gancho(l, "pista") / 1000.0 + Itens.antecipacao_s(l, Ritmo.bpm)


## A queda do lugar, em s: `tempos` × o Fôlego, arredondada à semicolcheia, no
## mínimo uma (docs/jogo/sistemas/README.md, o levantar).
static func queda_s(l: int, tempos: float) -> float:
	var semi := 60.0 / Ritmo.bpm / 4.0
	return maxf(semi, roundf(tempos * gancho(l, "levantar") * 4.0) * semi)
```

O `so_o_dono` lê `_raias` do kit (H04: `lugar -> {raiz, mat_borda, luz}`) quando
não recebe `luzes`. O néon da `atmosfera` (energia 3,0 hoje) e as tochas de
`sala.luzes` são da G15, que passa os materiais pelo `Tema.neon`: esta ficha
não mexe neles.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a contagem (a colcheia do lugar) | `Som.tocar("martelo", topo, -12.0)` | — (os atuadores: `pulso` 0,35) | `martelo_0..4`; `mod_pulso` |
| o acerto de botão | `Som.tocar("bigorna_aguda", topo, -2.0)` e `Som.tocar("martelo", topo, -6.0)` | perfeito: a nota do lugar (o kit); ótimo e bom: `Som.no_controle(l, "martelo", 0.55)` | `sint_bigorna_aguda`, `martelo_0..4`; `mod_nota_p1..p4` |
| o acerto da nota especial (círculo, fole) | `bigorna` −2 dB e `martelo` −6 dB | como o de botão | `sint_bigorna`, `martelo_0..4` |
| cada direção do círculo | `Som.tocar("tique", raiz, -6.0, 1.0 + 0.06·n)` (sobe) | — | `tique_0..2` |
| o fole cheio | `Som.tocar("sopro", raiz)` | — | `sint_sopro` |
| o erro | — (só a faísca apagada) | a nota quebrada (o kit) | `mod_nota_quebrada_p1..p4` |
| a racha com lâmina | `Som.tocar("bigorna_aguda", topo, 0.0, 0.94)` (desafinada) e `Som.tocar("golpe", topo, -4.0)` | — (a nota quebrada do kit já tocou) | `sint_bigorna_aguda`, `golpe_0..4` |
| a espada pronta | `Som.tocar("sucesso", pos, -10.0)`; a de ouro, −6 dB | `Forja.som_falante(l, "coleta", 0.7)` | `vitoria_sala_*` (`sint_sucesso`); `mod_coleta` |
| a faixa | `MUS_S01_J01`: 122 BPM, Fá menor; até ela existir, a sintetizada da H05 a 108 | — | `mus_s01_j01` |

- **O alto-falante toca um som por vez** e o julgamento tem a vez: o
  `martelo` no controle só toca quando o kit não tocou a nota (fora do
  perfeito).
- **Nenhum bipe de falha:** o erro soa pela nota quebrada do kit no controle
  do dono; na TV, a racha soa como metal (a bigorna desafinada e o golpe).
- **O mapa do áudio** ainda não lista a I1 em `sint_bigorna_aguda` (hoje só
  P5), em `golpe_*` (hoje I3 e I5) nem em `mod_pulso` (a contagem; hoje J4 e
  P4): a coluna «quem usa» é do diretor de som; esta ficha não edita o mapa.
- O material `"metal"` da FICHA: o kit toca `material:metal` nos atuadores no
  acerto (H07/H08).

## O controle

Evento por evento, para quem joga e para os outros. O piso é o da F05.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a contagem | o dono da colcheia | `Forja.som_haptica(l, "pulso", "pulso", 0.35)` | — | — | — |
| a runa do fole do R2 acende | o dono | — | R2 Feedback (posição 3, força 4) até a nota | — | — |
| a nota do fole do R2 julgada | o dono | — | R2 `GATILHO_OFF` | — | — |
| o acerto | o dono | `acerto` ou `perfeito` (o kit) e a textura `metal` | — | o kit: branco 0,15 s no perfeito (sem flashes: parada) | a nota ou o `martelo` 0,55 |
| o erro | o dono | `erro` (o kit) | — | o kit: a cor escurecida 0,5 s | a nota quebrada |
| a racha com lâmina | o dono | `golpe` (1,0 / 0,6, 250 ms), na colcheia | — | — | — |
| a espada pronta (e a de ouro) | o dono | `golpe` | — | — | `coleta` 0,7 |
| começar | todos | — | R2 `GATILHO_OFF`; o L2 nunca (é do item, G03) | a cor do lugar | — |

- A barra de luz é **sempre a cor do lugar**; o piscar do julgamento é do kit.
- O microfone não se usa.
- **Os outros não sentem nada** do que é de um: cada linha acima vai só ao
  controle do dono.
- **Sem o controle na mão:** o robô (abaixo) joga pelo relógio da música e
  pelos eixos simulados; a prova confere que o R2 recebeu o Feedback (0x21)
  na runa do fole e que a linha `sensacao` `golpe` da racha existe.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo
que a pessoa escolheu aparecem como estão, de lado para a câmera, junto da
bigorna. Cada parte tem a sua faixa de valor e um acento de néon só, na cor
do lugar (arte/04, «A peça se distingue»): a cabeça humana sem acento (a de
raça, o visor ou a rachadura, até 6 %), o friso do superior (até 8 % da
parte, energia 1,6), a costura do inferior (até 5 %, 1,6); somados, no
máximo 8 % da frente do corpo. O contorno é de 0,012, energia 2,4 no jogo.
`martelo_na_mao(p)` põe o martelo da forja na mão: a arma ou o amuleto
escolhido não aparece no Martelo, mas o efeito do item vale. O cavaleiro
pode ser de outra raça (o Orc, o Autômato de latão, o Golem de escória, a
Raposa ferreira; a raça é só aparência): esta ficha não supõe corpo
humano; usa o esqueleto comum e as animações `attack-melee-right`,
`emote-no`, `idle`.

| stat | gancho | o que muda no Martelo | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: o ferreiro fica na bigorna | — | — | — |
| Passo | `velocidade` | não age | — | — | — |
| Fôlego | `levantar` | a queda depois do erro: quanto a próxima runa espera | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | a runa acende antes; a nota cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Lanterna acende a
runa meio tempo antes (`Itens.antecipacao_s`); o Martelo dobra o perfeito no
tempo forte (o kit); o Fole e o Diapasão agem no combo pelo kit (o Diapasão
não dá bônus no `tct`). Os números da régua: nenhum stat muda a janela de
julgamento; o stat 5 nunca tira a racha.

## As reações

- **Carimbos que o Martelo pode disparar** (todos são do kit e do HUD, G04;
  o Martelo não chama nenhum): `car_em_chamas` (5 Ressonâncias seguidas do
  mesmo lugar; o pico, com dois golpes por runa, é onde ele aparece),
  `car_por_um_fio` (o vencedor por 2 % dos pontos ou menos, no resultado).
  `car_acorde` (os quatro na Ressonância no mesmo tempo 1) não acontece: no
  hoqueto, cada colcheia tem um dono. O `car_virada` é do placar, não do
  minigame.
- **Adesivos:** ninguém está fora da rodada no Martelo, então ninguém manda
  adesivo durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

O Martelo é a primeira coisa que a sala joga: o prazer do começo mora aqui.
Nota de hoje 3; com a racha, a reta e a espada de ouro, o alvo é 4.

**O momento: a espada racha no quinto golpe** (`racha_no_quinto`). O erro
que chega com a espada a um golpe de ficar pronta (5 golpes; 4 na reta): a
espada parte ao meio, a lâmina de cima voa 1 m e cai no chão ao lado da
bigorna, e o dono fica com o cabo na mão. Degrau golpe na imagem (tremor de
0,02 m por 1 batida, o ferreiro parado 2 quadros), estrondo no som (a bigorna
aguda desafinada a 0,94 e o golpe), e a forja dos outros cai 30 % por 1
batida.

- **Rastro:** a lasca fica no chão ao lado da bigorna até o fim; as lascas se
  empilham, uma por racha (toda falha com golpes na bigorna). A pilha de
  lascas é o placar do azar.
- **A curva:** de 0 a 30 s, uma runa a cada 2 tempos e o anel fecha na
  batida; de 30 a 60 s, o pico, a espada em brasa (dois golpes por runa, os
  quatro em semicolcheias); de 60 s ao fim, a reta: a espada com 5 golpes (a
  estante enche mais depressa) e, nas últimas 16 batidas, a espada pronta é
  de ouro e conta 2.
- **Ensina sem falar:** a runa mostra o glifo do botão; o anel que fecha é o
  tempo; na contagem, os quatro ferreiros batem no ar, cada um na sua
  colcheia; o fole do R2 tem a resistência no meio. A frase do quadro 01 sai.
- **Quem está perdendo:** a janela generosa e a partitura simples já valem; a
  espada de ouro conta 2 para todos, e uma estante com 3 espadas a menos se
  recupera em 16 batidas boas.
- **O que se corta:** a frase «Aperte o botão da runa antes do anel
  fechar.»; da segunda volta em diante, as setas, o Create e o crave.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3
`medio`, P4 `ruim`, semente 7, sem a bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0, e a mesa tem um `toque` com `erro` até 10,0 | os quadros de 2 a 10 s mostram as bigornas com a runa acesa na cor de pelo menos dois donos |
| 3. ensina sem falar | a coleta de texto da F02 na fase de jogo só acha o verbo, os nomes, os P#, o placar e o julgamento | nenhum quadro de jogo tem a frase da runa |
| 4. o momento | pelo menos 3 linhas `momento` `racha_no_quinto` entre 0 e 90 s | no quadro de 60 s (o 31.º), a raia do P4 tem 2 ou mais lascas no chão |
| 5. a curva | notas por segundo no 2.º terço ≥ 1,5 × as do 1.º; no 3.º ≥ 1,0 ×; a linha `momento` `reta` existe uma vez | o quadro do meio do 2.º terço tem a luz 20 % acima do quadro do meio do 1.º; nas últimas 16 batidas, uma espada de ouro na estante |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | 1 quadro em 5 mostra lasca no chão do P4 |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `racha_no_quinto` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | a lasca se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `racha_no_quinto`, uma linha `sensacao` `golpe` do mesmo lugar a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte à racha ainda mostra a lasca |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem das espadas no `momento` `reta` e no fim | no quadro de 60 s, quem olha diz a ordem pelas estantes, e ela bate com o registro |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na
régua) existir, a prova roda com `--robo=medio` nos quatro e confere os itens
1, 3, 5, 8, 9 e 10; os itens 4, 6 e 7 (que pedem o P4 `ruim`) esperam o robô
por lugar.

## Pronto quando

O Martelo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; o cabo que cai e volta não trava ninguém; a primeira
volta pede os treze botões, os dois círculos e os dois foles; os vereditos
`botoes`, `analogicos` e `gatilhos_analogicos` passam na prova limpa e cada
defeito do gauntlet que eles pegavam (`troca-cruz-circulo`,
`analogico-curto`, `gatilho-digital`) continua pego; o fim tem sempre
vencedor; `bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh`
passa com a prancha **olhada** nas partidas com quatro, dois e um jogador e
com o cabo que cai. Além disso: a segunda volta da fila pede só ✕ ○ □ △,
L1, R1, um círculo sem crave e o fole do R2; a linha `momento` `reta` aparece
uma vez e cada `racha_no_quinto` cai a até 1 quadro de uma colcheia, com a
sua `sensacao` `golpe`; e nenhuma cor fora dos tokens sobra no
`martelo_de_hefesto.gd` nem no `secao.gd`
(`grep -nE 'Color\("#|Tema\.(ROSA|AMARELO|TRILHO|LARANJA|FG)\b'` não acha nada).

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

Ainda em `_prova_do_relatorio()`, depois da contagem do Martelo, os momentos
(a régua):

```gdscript
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S01_J01")
	var rachas := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "racha_no_quinto")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "S01_J01: a linha momento reta aparece uma vez")
	for r in rachas:
		_esperar(float(r.get("x_tela", 0.0)) >= 0.2 and float(r.get("x_tela", 0.0)) <= 0.8 \
			and float(r.get("altura_tela", 0.0)) >= 0.08, "S01_J01: a racha no meio da tela (%s)" % [r])
		var t := float(r.get("t_musica", 0.0))
		var golpe := linhas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "golpe" \
			and int(e.get("lugar", -9)) == int(r.get("lugar", -1)) and absf(float(e.get("t_musica", -9.0)) - t) <= 0.0167)
		_esperar(not golpe.is_empty(), "S01_J01: a racha tem a sensação golpe no mesmo quadro (%s)" % [r])
```

(`_linha_do_tempo` é da F01; já está na prova. A contagem mínima de
`racha_no_quinto` (3) espera o robô por lugar: com `--robo=medio` nos
quatro, a racha pode não chegar a 3.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### O que o André joga e sente

**O André (local):** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
(com o fim em tempo de música, cada Martelo leva 90 s de relógio); depois
`./run-local.sh -- --sala=centelha` com quatro controles: a runa acende no
tempo de cada um, a bigorna soa a nota de cada um, o R2 pesa no meio do fole,
o pico no meio se sente, e as espadas aparecem na estante. As três perguntas
da régua, respondidas no cabeçalho, conferidas jogando.

- na contagem, os quatro martelos batem no ar em ordem, P1, P2, P3, P4, e o
  pulso chega ao controle de cada um na sua colcheia;
- da segunda volta em diante, a mão acha ✕ ○ □ △, L1 e R1 sem olhar; o
  círculo solto na nota se sente no tempo;
- a racha com a espada quase pronta dói: a lâmina voa, a forja dos outros
  escurece por uma batida, o controle bate `golpe`;
- nas últimas 16 batidas, a espada de ouro aparece e a estante vira o placar.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a
cada 2 s): os quadros de 2 a 10 s (as runas acesas nas cores), o de 45 s (a
luz do pico e a câmera mais longe), o de 60 s (as lascas no chão do P4; a
ordem das estantes, anotada aqui na ficha), e os das últimas 16 batidas (a
espada de ouro na estante).

### Ao terminar

- `godot/scripts/traducoes.gd`: em `EN_PADROES`,
  `["^Espadas: (\\d+)$", "Swords: $1"]` (o título e o verbo a H04 já pôs).
- `"$GODOT" --headless --path godot --import --quit` e o `secao.gd.uid` no commit.
- No [quadro](README.md): se ainda não há as linhas dos minigames da seção,
  ponha I1 a I5 logo abaixo da linha **I** (com o link, M ou G, a
  estimativa, "a fazer"); marque a I1 **feito**, com o commit.
- Commit (sem trailer): `feat: O Martelo de Hefesto no tempo da música, com as espadas e a forja da seção`
- A frase «Aperte o botão da runa antes do anel fechar.»: veja «Arquivos
  que mudam».
