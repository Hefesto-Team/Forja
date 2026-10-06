# O1 — Os Caminhos

**Sprint:** O · **Slot:** S07_J31 · **Tamanho:** G · **Depende de:** H04, H08, F09, F01, H07, G08

## Por quê

A sala de hoje (`godot/scripts/salas/caminhos.gd`) é uma prova às cegas: três
passos no escuro e a pergunta "que chão é esse?". No kit ela vira corrida: a
senha do seu portão chega **só na sua mão** (a textura do chão certo), três
trilhas se abrem à sua frente, e você pisa na certa no tempo. A pergunta some:
a trilha que a pessoa escolhe **é** a resposta, e continua alimentando o
veredito `haptica_audio` da bancada.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](O-os-caminhos.md)
- [05 — a háptica por material e o rádio](../05-haptica-e-controle.md#a-háptica-por-material)
- `godot/scripts/salas/caminhos.gd` inteiro (é o que sai), em especial
  `_novo_ladrilho` (`:110-158`), `_montar_raia` (`:161-209`), `_robo_sentir`
  (`:521-556`) e `dar_vereditos` (`:388-399`)
- A H07, "O GDScript" (`Forja.tocar_material`, os sons `material:<nome>`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J31",
	"titulo": "Os Caminhos",
	"verbo": "Sinta o chão!",
	"genero": "corrida",
	"icone": "haptica",
	"entradas": [Forja.ESQUERDA, Forja.CIMA, Forja.DIREITA],
	"camera": "fixa",
	"faixa": "MUS_S07_J31",
	"duracao": 100.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Sinta!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	# a bancada: o veredito da háptica sai das trilhas escolhidas
	"features": ["haptica_audio"],
	"botoes_medidos": [Forja.ESQUERDA, Forja.CIMA, Forja.DIREITA, Forja.TOUCHPAD],
	"gesto": "lados",
}
```

## Como se joga

A faixa é `MUS_S07_J31`, 120 bpm (uma batida = 0,5 s). As quatro primeiras
batidas são a contagem de entrada (`BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08)).

**Uma bifurcação** dura `CICLO := 8` batidas. Para o lugar `l`, a bifurcação
`k` começa na batida `b0`:

| batida | o que acontece |
| --- | --- |
| `b0` | a senha, 1º passo: `passo:<senha>:<k % 3>` nos **dois** atuadores do dono |
| `b0 + 2` | a senha, 2º passo: `passo:<senha>:<(k + 1) % 3>` |
| `b0 + 4` | as três trilhas acendem na frente do boneco (esquerda, meio, direita), cada uma num chão diferente; uma delas é a da senha |
| `b0 + 6` | **a escolha**: ◀, ▲ ou ▶ no tempo (a nota `k`, alvo `Ritmo.t_da_batida(b0 + 6)`) |
| `b0 + 6` a `b0 + 8` | o boneco anda para a trilha escolhida (o mundo desliza pela batida) |

- **O hoqueto:** a primeira bifurcação de cada um começa em
  `BATIDA_DA_PRIMEIRA_NOTA + 2 * i`, onde `i` é a posição do lugar em `presentes()`. Com
  quatro, as escolhas caem nas batidas 2, 4, 6 e 8 de cada ciclo, uma por
  jogador, e a nota de cada um soa na TV (`TOM_DO_LUGAR` do kit) — a frase só
  fica inteira se os quatro escolhem no tempo.
- **A entrada:** a direção só vale de `b0 + 4` (as trilhas acesas) até a nota
  passar (`alvo + Ritmo.JANELA_BOM`); antes de `b0 + 4` o aperto é ignorado.
  A primeira direção apertada é a escolha (não se troca).
- **O julgamento:** trilha certa → `julgar_toque(l, alvo, k, true)` (a trilha
  é perigo físico: quem está em último ganha a folga). Trilha errada →
  `nota_perdida(l, k)` com `_motivo[l] = "lama"`. Nenhuma direção até a nota
  passar → `nota_perdida(l, k)` com `_motivo[l] = "parou"`.
- **Os pontos e o avanço** (`toque`): o boneco avança `AVANCO[j]` trechos
  (BOM 1,0; ÓTIMO 1,25; PERFEITO 1,5) e marca `round(100 * avanço)`.
- **A meta:** `META := 12.0` trechos até o portão.
- **A partitura simples** (`Ritmo.simples[l]`): as bifurcações de `k` ímpar
  (fora do pico) viram corredor reto — sem senha, sem nota; o boneco anda
  0,5 trecho sozinho na batida `b0 + 6`.
- **O relógio da corrida:** a `duracao` da FICHA é 100 s, e o kit os conta
  em tempo de música (H08), não pelo relógio do jogo — a bancada precisa das
  bifurcações todas, também na prova, onde o jogo anda 16 vezes mais
  depressa que a música. `FIM_BATIDA := BATIDA_DA_PRIMEIRA_NOTA + 196` (os
  mesmos 100 s, em batidas a 120 bpm) só serve para prever as bifurcações.
- **O pico no meio — a descida:** `_pico_k` é a metade das bifurcações
  previstas (`floor((FIM_BATIDA - BATIDA_DA_PRIMEIRA_NOTA) / CICLO / 2)` = 12). As
  bifurcações `_pico_k` a `_pico_k + 3` vêm no dobro (`CICLO_PICO := 4`): só o
  1º passo da senha em `b0`, as trilhas em `b0 + 2`, a escolha em `b0 + 2`
  (a nota), e o avanço vale 1,5 vez. A TV marca a descida: `Som.tocar("sobe")`
  na primeira e `pulso_de_luz(Tema.CIANO)`.

## O cenário

- **Chão:** `Kit.arena(self, 5, 3)`.
- **Luz:** a da casa, baixa (é um túnel, não terror):
  `atmosfera(Color("#b9b0ff"), Tema.CIANO, false, 30, 22.0, -7.8, 0.15)` e duas
  tochas (`OmniLight3D`, `#ffb070`, energia 0,9, alcance 9) em
  `(-9, 3, -5)` e `(9, 3, -5)`.
- **Cada raia** (`_montar_raia(l)`): `raia(l)` e `posicionar(l)` do kit; depois
  `p.rotation.y = PI` (de costas, andando para o fundo) e `p.preso = true`.
  - o corredor: um `Node3D` `trilha` em `(RAIAS[l], 0, Z_JOGADOR)`, com
    `META + 3` lajes `Kit.caixa(trilha, Vector3(2.6, 0.08, 1.42), Vector3(0, 0.04, -s * LADRILHO), pedra)`
    (`LADRILHO := 1.5`, `pedra := Kit.material(Color("#3a3542"), 0.0, 0.95)`) e
    as pedras da borda `Kit.peca(trilha, "rocks", Vector3(±1.5, 0, -s * LADRILHO), <giro pela semente>, 0.34)`
    a cada dois trechos;
  - o portão: `Kit.peca(trilha, "gate", Vector3(0, 0, -META * LADRILHO - 0.8))`;
  - as três placas da bifurcação, filhas de `self` (não da trilha: ficam
    sempre à frente do boneco): `Kit.caixa(self, Vector3(0.7, 0.06, 1.2), Vector3(RAIAS[l] + DX_TRILHA[d], 0.1, Z_JOGADOR - 1.4), escuro)`
    com `DX_TRILHA := [-0.8, 0.0, 0.8]`; `escuro := Kit.material(Color("#17141f"), 0.0, 0.95)`;
  - os enfeites de cada placa, um `Node3D` por chão, só o do chão da vez
    visível quando a placa acende: grama = 5 caixas `(0.05, 0.2, 0.05)`
    `#6fcf5a`; cascalho = 6 caixas `(0.1, 0.07, 0.1)` `#b8ab94` em tons;
    metal = 4 rebites `(0.08, 0.04, 0.08)` `#d0d6e0` nos cantos; água =
    `Kit.anel(no, 0.3, 0.34, Vector3.ZERO, Kit.material(Color("#9fd4ff"), 0.0, 0.2))` (G08);
  - a cor de cada placa acesa: `COR_CHAO := [#4f9a45, #9a8a70, #8c98aa, #3a7fd0]`
    com `Kit.material(cor, 0.0, 0.9)` (o metal: `rugoso 0.35`, `metallic 0.2`
    — nunca 0,8 como hoje);
  - a lanterna do boneco: `OmniLight3D` em `(RAIAS[l], 2.6, Z_JOGADOR + 0.6)`,
    `Forja.cor_do_lugar(l).lerp(Color.WHITE, 0.55)`, energia 1,3, alcance 3,2.
- **A câmera:** `camera_pos = Vector3(0, 7.2, 10.6)`,
  `camera_olhar = Vector3(0, 0.4, -1.8)` (as de hoje), no começo do `montar()`.
- **O movimento, pela batida:** o `trilha.position.z` é
  `Z_JOGADOR + LADRILHO * lerpf(_de[l], _ate[l], clampf(b - _passo_b[l], 0.0, 1.0))`,
  onde `b = Ritmo.batida()`, `_de`/`_ate` são a distância antes e depois do
  último avanço e `_passo_b` a batida em que ele começou. O boneco faz `walk`
  enquanto `b - _passo_b < 1`, `sprint` no PERFEITO, `idle` no resto.
- **Checklist de arte (11):** nada de esfera, cilindro liso nem toro liso (as
  de hoje saem: tufos em caixa, cascalho em caixa, água em `Kit.anel`); metal
  `metallic` 0,2; o emissivo só na borda da raia (do kit); nenhuma placa usa
  as cores dos lugares; a foto ao lado de um boneco na prancha.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **háptica (protagonista)** | a senha: `passo:<chão>:<v>` nos dois atuadores, ganho 1,0 | `b0` e `b0 + 2` (no pico, só `b0`) |
| háptica por material | a trilha certa: o kit toca `material:pedra` no acerto (`tocar_material`); o lamaçal: `Forja.tocar_material(l, "lama", "golpe", 1.0)` | no toque; na falha "lama" |
| barra de luz | a cor do lugar, sempre; o minigame não chama `Forja.luz` | — |
| alto-falante do dono | a nota do dono no PERFEITO e a quebrada no erro (o kit); `Forja.som_falante(l, "coleta", 0.7)` ao passar o portão | no toque; na chegada |
| vibração | o kit (`acerto`, `perfeito`, `erro`); a queda na lama `Forja.sentir(l, "golpe")` só no rádio (no cabo vai pela háptica) | no toque e na falha |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` no `montar()` | — |
| TV | a música, a nota de cada um (kit), `Som.tocar("portao", pos)` na chegada, `Som.tocar("sobe")` na descida | — |

**No rádio (sem placa):** `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)`
no `iniciar_jogo()`; a senha vai por `Forja.sentir(l, RUMBLE_CHAO[chao])`, com
`RUMBLE_CHAO := ["toque", "golpe_esq", "golpe", "golpe_dir"]` (grama leve,
cascalho à esquerda, metal forte, água à direita — grosseira, mas se aprende
no treino), e a linha `troca` é gravada uma vez. O microfone não é usado.

## A falha

- **"lama"** (trilha errada): o boneco faz `fall` (0,8 s) e afunda meio
  palmo (`p.position.y = -0.25` até a próxima bifurcação); a placa escolhida
  vira lama (`Kit.material(Color("#4a3a2a"), 0.0, 1.0)`); a mão sente a lama
  (`tocar_material(l, "lama", "golpe")`). **A recuperação:** a bifurcação
  seguinte se perde no lamaçal (`_lama[l] = k + 1`: sem senha, sem nota, o
  boneco anda devagar, `walk` a 0,4, e avança 0,25 trecho).
- **"parou"** (atrasou, adiantou demais ou não escolheu): o boneco faz
  `emote-no` (0,6 s) diante das placas; não avança; a próxima bifurcação vem
  normal.

## O fim e o vencedor

Quem passa do `META` chega: `_chegada.append(l)`, `acabou[l] = true`,
`p.gesto("emote-yes", 1.2)`. Na primeira chegada, `_fim_batida = b + CORTESIA`
(`CORTESIA := 8`): os outros ainda correm dois compassos, e então todos
acabam (`acabou[l] = true`) e o kit fecha. Sem chegada, o kit fecha aos 100 s
de música (H08). `vencedor()`: a ordem de `_chegada`, depois os outros pela
distância (e pelos pontos no empate).

## Com menos de quatro

- **3, 2, 1:** nada muda na regra; o hoqueto espalha as escolhas pelas
  posições em `presentes()` (com dois, batidas 2 e 4 de cada ciclo). Com um,
  ele corre contra o portão e vence ao chegar (ou ao fim, pela distância).
- **O controle que cai:** a nota de quem está sem controle não vira erro
  (`if not conectado(l): _fora[l] = true; continue`). Quando volta, as
  bifurcações que já começaram são puladas sem registro
  (`while _b0[l] + _ciclo(_k[l]) - 2 < b + 0.5: _pular(l)`), e a próxima vem
  normal.
- **Duplas:** não há.

## O robô

Ele **sente** a senha na placa virtual do controle simulado — o mesmo
`_robo_sentir` de hoje, copiado sem mudar (`caminhos.gd:521-556`: o
envelope de cada passo, `Forja.chao_do_envelope`, os votos por chão). Assim,
um defeito de mentira que corta a háptica faz o robô errar, e o `scripts/gauntlet.sh`
continua vendo o veredito cair.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	_robo_sentir(l)
	var k: int = _k[l]
	if _lama[l] == k or _reto[l] or _escolheu[l] >= 0 or _robo_k[l] == k:
		return
	var b := Ritmo.batida()
	if b < _b0[l] + _ciclo(k) / 2:
		return
	if _robo_mira_de[l] != k:
		# o temperamento (--robo=bom|medio|ruim), uma vez por bifurcação
		_robo_mira_de[l] = k
		_robo_certo[l] = Forja.robo_acerta()
		_robo_atraso[l] = 0.0 if _robo_certo[l] or _robo_rng.randf() < 0.5 else 0.25
	var alvo := Ritmo.t_da_batida(_b0[l] + _ciclo(k) - 2)
	if Ritmo.t_musica() < alvo + float(_robo_atraso[l]):
		return
	var sentido := _mais_votado(l)   # o chão que a mão sentiu, ou -1
	var d := -1
	if sentido >= 0:
		d = (_trilhas[l] as Array).find(sentido)
	if d < 0:
		if Forja.bancada:
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.08)   # "não senti"
			_robo_k[l] = k
			return
		d = _robo_rng.randi_range(0, 2)
	if not _robo_certo[l] and float(_robo_atraso[l]) == 0.0:
		d = (d + 1 + _robo_rng.randi_range(0, 1)) % 3   # erra a trilha
	Forja.robo_apertar(l, DIRECAO[d], 0.08)
	_robo_k[l] = k
```

`_robo_sentir(l)` é o de hoje com o estado por lugar em arrays
(`_robo_env[l]`, `_robo_gravando[l]`, `_robo_silencio[l]`, `_robo_somas[l]`,
`_robo_votos[l]`); os votos zeram em `_nova_bifurcacao`. O tropeço de hoje
sai (o lado da háptica é d'O4), então o ramo `robo_lado` também sai.

## Os ganchos

O arquivo `godot/scripts/minigames/s07/os_caminhos.gd`, `extends Minigame`,
sem `class_name`. O que muda do `caminhos.gd` de hoje:

| sai | por quê |
| --- | --- |
| `class_name SalaCaminhos`, `_init()`, `const RAIAS`, `Z_JOGADOR`, `_conectado` | o kit tem |
| `PERGUNTA`, `REVELA`, `pergunta()`, `_fechar_pergunta()`, o `objetivo` | a pergunta às cegas vira a escolha da trilha |
| o tropeço (`trop_*`, `_fechar_tropeco`, `CAMINHO_NADA_LADO`) | o lado da háptica é d'O4 |
| o treino próprio (`TREINO`, `com_treino = false`) | o treino do kit (10 s, julga igual e não soma) ensina as trilhas |
| o `_process` e o `_mostrar` chamado dele | o kit não deixa sobrescrever `_process`; o `_mostrar(b)` é chamado do fim do `jogar` |
| `e.t += dt` | tudo pela batida |

O esqueleto:

```gdscript
extends Minigame
## Os Caminhos (S07_J31). A senha do seu portão chega só na sua mão — o passo
## de um chão (grama, cascalho, metal, água) nos atuadores —, três trilhas
## acendem à sua frente, e ◀ ▲ ▶ no tempo pisa na que tem aquele chão.
##
## A falha: a trilha errada é um lamaçal (o boneco afunda e perde a próxima
## bifurcação); atrasar é parar diante das placas.
## O vencedor: o primeiro no portão (os outros ainda correm dois compassos).
## O alto-falante do dono: a nota dele (kit) e a coleta ao passar o portão.
## O registro mede: cada senha mandada (pista, pelo canal da háptica ou do rumble), a trilha
## escolhida (a entrada resposta) e o veredito haptica_audio da bancada.
## O robô: sente a senha na placa virtual (o envelope, chao_do_envelope).
## Com menos de quatro: nada muda; o hoqueto se espalha por quem joga.
## A régua: título, verbo e ícone bastam; sem a tela não dá para ver as
## trilhas, mas a senha é só do controle; nada pergunta se o controle obedeceu.

const FICHA := { ... }   # a de cima

const FIM_BATIDA := BATIDA_DA_PRIMEIRA_NOTA + 196  ## os 100 s de música em batidas: só para prever as bifurcações (o fim é do kit, H08)
const CICLO := 8
const CICLO_PICO := 4
const PICO_BIFURCACOES := 4
const META := 12.0
const CORTESIA := 8.0
const LADRILHO := 1.5
const AVANCO := [0.0, 1.0, 1.25, 1.5]
const DX_TRILHA := [-0.8, 0.0, 0.8]
const DIRECAO := [Forja.ESQUERDA, Forja.CIMA, Forja.DIREITA]
const NOME_CHAO := ["grama", "cascalho", "metal", "água"]
const COR_CHAO := [Color("#4f9a45"), Color("#9a8a70"), Color("#8c98aa"), Color("#3a7fd0")]
const RUMBLE_CHAO := ["toque", "golpe_esq", "golpe", "golpe_dir"]
const CAMINHO_NADA := 4  ## "não senti" (cegas.h), só na bancada
const ENV_MAX := 64

var _rng := {}  ## lugar -> RandomNumberGenerator (o caminho de cada um, da semente)
var _k := [0, 0, 0, 0]
var _b0 := [0.0, 0.0, 0.0, 0.0]
var _senha := [0, 0, 0, 0]
var _trilhas := [[], [], [], []]
var _escolheu := [-1, -1, -1, -1]
var _reto := [false, false, false, false]
var _lama := [-1, -1, -1, -1]
var _motivo := ["", "", "", ""]
var _dist := [0.0, 0.0, 0.0, 0.0]
var _de := [0.0, 0.0, 0.0, 0.0]
var _ate := [0.0, 0.0, 0.0, 0.0]
var _passo_b := [-9.0, -9.0, -9.0, -9.0]
var _passos_dados := [0, 0, 0, 0]  ## quantos passos da senha já soaram nesta bifurcação
var _chegada: Array = []
var _fim_batida := -1.0
var _pico_k := 999
var _rumble := [false, false, false, false]
var _chao := {}  ## lugar -> Cega (a bancada)
var _fora := [false, false, false, false]
var _nos := {}   ## lugar -> {trilha, placas, enfeites, lanterna}
# o robô (só lido e escrito dentro de robo() e _robo_sentir())
var _robo_k := [-1, -1, -1, -1]
var _robo_mira_de := [-1, -1, -1, -1]
var _robo_certo := [true, true, true, true]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_env := [[], [], [], []]
var _robo_gravando := [false, false, false, false]
var _robo_silencio := [0, 0, 0, 0]
var _robo_somas := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _robo_votos := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.2, 10.6)
	camera_olhar = Vector3(0, 0.4, -1.8)
	Kit.arena(self, 5, 3)
	atmosfera(Color("#b9b0ff"), Tema.CIANO, false, 30, 22.0, -7.8, 0.15)
	for x in [-9.0, 9.0]:
		_tocha(Vector3(x, 3.0, -5.0), 0.9)
	for p in jogadores:
		var l: int = p.lugar
		_nos[l] = _montar_raia(l)
		_chao[l] = Cega.nova()
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	_pico_k = int(floor(float(FIM_BATIDA - BATIDA_DA_PRIMEIRA_NOTA) / CICLO / 2.0))
	var ordem := presentes()
	for i in ordem.size():
		var l: int = ordem[i]
		var r := RandomNumberGenerator.new()
		r.seed = rng.seed + 7919 * (l + 1)
		_rng[l] = r
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)
		if _rumble[l]:
			anotar("troca", l, {"de": "haptica", "para": "rumble", "motivo": "sem_placa"})
		_b0[l] = float(BATIDA_DA_PRIMEIRA_NOTA + 2 * i)
		_nova_bifurcacao(l)


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	for l in presentes():
		if acabou[l]:
			continue
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			while _b0[l] + _ciclo(_k[l]) - 2 < b + 0.5:
				_pular(l)
		_senha_na_mao(l, b)
		var k: int = _k[l]
		var escolha := _b0[l] + _ciclo(k) - 2
		var alvo := Ritmo.t_da_batida(escolha)
		acender_raia(l, clampf(1.0 - absf(Ritmo.t_musica() - alvo) * 4.0, 0.0, 1.0))
		if _lama[l] == k or _reto[l]:
			if b >= escolha and _passo_b[l] < escolha:
				_andar(l, 0.25 if _lama[l] == k else 0.5, escolha)
		elif _escolheu[l] < 0 and b >= _b0[l] + _ciclo(k) / 2:
			var d := _direcao(l)
			if d >= 0:
				_escolher(l, d, alvo)
			elif Forja.bancada and Forja.apertou(l, Forja.TOUCHPAD):
				_escolheu[l] = 3
				Cega.errado(_chao[l], CAMINHO_NADA)
				_respondeu(l, k, "nenhuma")
				_motivo[l] = "parou"
				nota_perdida(l, k)
			elif Ritmo.t_musica() > alvo + FOLGA_PERDIDA:
				_escolheu[l] = 3
				Cega.perdido(_chao[l])
				_respondeu(l, k, "nenhuma")
				_motivo[l] = "parou"
				nota_perdida(l, k)
		if b >= _b0[l] + _ciclo(k):
			_b0[l] += _ciclo(k)
			_k[l] = k + 1
			_nova_bifurcacao(l)
	if _fim_batida > 0.0 and b >= _fim_batida:  # sem chegada, o kit fecha aos 100 s de música (H08)
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	var ganho: float = AVANCO[j] * (1.5 if _no_pico(_k[l]) else 1.0)
	marcar(l, int(round(100.0 * ganho)))
	_andar(l, ganho, _b0[l] + _ciclo(_k[l]) - 2)


func falha(l: int) -> void:
	var p := jogador(l)
	if _motivo[l] == "lama":
		_lama[l] = _k[l] + 1
		p.gesto("fall", 0.8)
		Forja.tocar_material(l, "lama", "golpe", 1.0)
		# a placa escolhida vira lama (o _mostrar a pinta até a próxima bifurcação)
	else:
		p.gesto("emote-no", 0.6)


func vencedor() -> Array:
	var resto := presentes().filter(func(l): return not l in _chegada)
	resto.sort_custom(func(a, b):
		return _dist[a] > _dist[b] or (_dist[a] == _dist[b] and pontos[a] > pontos[b]))
	return _chegada + resto


func dar_vereditos(l: int) -> Array:
	var tem := Forja.som_tem(l, Forja.PAPEL_HAPTICA)
	var v := Forja.cega_veredito(l, "haptica_audio", {"cega": _chao[l], "esq": Cega.nova(), "dir": Cega.nova(), "tem": tem})
	return [] if v.is_empty() else [v]
```

As funções que faltam, pelo que já foi dito: `_ciclo(k)`,
`_no_pico(k)`, `_nova_bifurcacao(l)` (sorteia a senha e os outros dois chãos
com `_rng[l]`, põe a certa numa das três posições, `_escolheu[l] = -1`,
`_passos_dados[l] = 0`, `_reto[l] = Ritmo.simples[l] and k % 2 == 1 and not _no_pico(k)`,
zera `_robo_votos[l]`, e `nova_nota(l, k, Ritmo.t_da_batida(escolha))` se não
for reta nem lama), `_pular(l)` (avança `_b0` e `_k` sem nota),
`_senha_na_mao(l, b)` (os passos em `b0` e `b0 + 2` — no pico só `b0` —
pelo `_pista`, uma vez cada, contados em `_passos_dados`), `_direcao(l)`
(a primeira de `DIRECAO` com `Forja.apertou`), `_escolher(l, d, alvo)`
(`_escolheu[l] = d`; certo: `Cega.certo`, `_respondeu(l, k, "certo")`,
`_motivo[l] = "parou"`, `julgar_toque(l, alvo, k, true)`; errado:
`Cega.errado(_chao[l], chao)`, `_respondeu(l, k, "errado")`,
`_motivo[l] = "lama"`, `nota_perdida(l, k)`), `_andar(l, ganho, b_de)`
(`_de = _dist`, `_dist += ganho`, `_ate = _dist`, `_passo_b = b_de`; se
`_dist >= META` e `not l in _chegada`: a chegada), `_tocha(pos, energia)`,
`_montar_raia(l)` e `_mostrar(b)`. E as duas da pista, iguais nas cinco
fichas da seção:

```gdscript
## A pista na mão do lugar: no cabo, a onda nos atuadores; sem placa (o
## rádio), a mesma pista pelo rumble — nunca os dois (docs/jogo/05, o rádio).
func _pista(l: int, esq: String, dir: String, sensacao: String, n: int, o_que: String) -> void:
	if _rumble[l]:
		Forja.sentir(l, sensacao)
	else:
		Forja.som_haptica(l, esq, dir, 1.0)
	anotar("pista", l, {"n": n, "evento": "mandou",
		"canal": "rumble" if _rumble[l] else "haptica", "o_que": o_que})


func _respondeu(l: int, n: int, resposta: String) -> void:
	anotar("entrada", l, {"o": "resposta", "n": n, "resposta": resposta})  # o que o jogador fez com a pista (13, H08)
```

A senha: `_pista(l, "passo:%d:%d" % [s, v], "passo:%d:%d" % [s, v], RUMBLE_CHAO[s], k, NOME_CHAO[s])`.

**A casa nova e o catálogo** (o molde, "Onde mora"):

1. `godot/scripts/minigames/s07/os_caminhos.gd` criado; importe
   (`"$GODOT" --headless --path godot --import --quit`) e commite o `.uid`.
2. `godot/scripts/minigames/catalogo.gd`: `"S07_J31": preload("res://scripts/minigames/s07/os_caminhos.gd")`
   em `MINIGAMES`; `"minigames": ["S07_J31"]` na seção `S07`; tire
   `"caminhos"` de `SALAS_ANTIGAS`.
3. `git rm godot/scripts/salas/caminhos.gd godot/scripts/salas/caminhos.gd.uid`;
   `grep -rn "SalaCaminhos" godot/` tem de dar vazio.
4. `godot/scripts/traducoes.gd`: `"Os Caminhos": "The Paths"`,
   `"Sinta o chão!": "Feel the ground!"`, `"Sinta!": "Feel!"`,
   `"Chegou": "Made it"`, e tire as frases que só a sala de hoje usava
   (`"Que chão é esse?"`, `"treino: sinta %s"`, `"tropeçou!"`...) se nenhum
   outro script as usa (`grep -rn`).

A dica (`dica(l)`, com a guarda `if not na_raia(l): return {}`): na escolha,
`{"partes": ["@dpad_left", "@dpad_up", "@dpad_right"], "pos": Vector3(RAIAS[l], 0, 4.6)}`
enquanto `not aprendeu(l)`; nada depois. O `status(l)`: `"%d de %d" % [floor(_dist[l]), META]`,
ou `"Chegou"`. Nenhuma frase fala de chão, de háptica ou de controle.

## O que o registro mede

- `pista` `mandou` de cada senha (`o_que` = o chão, `canal`), e
  a `entrada` `resposta` com `certo`/`errado`/`nenhuma` — a pergunta antiga, respondida
  com os pés;
- `troca` quando o lugar não tem placa;
- `som_controle` de cada passo (a H07, com `placa`), `nota` e `toque` (o kit);
- o veredito `haptica_audio` (a bancada), calculado nos dois modos.

As linhas `pista` e `troca` são as do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
(H08): a `pista` com `n`, `evento` `mandou`, `canal` e `o_que` (a resposta é a `entrada` `resposta`);
a `troca` com `de` e `para` (`haptica` → `rumble`) e o `motivo` junto
(`sem_placa`, `sem_estereo`).

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **A cauda do metal.** O passo de metal soa por 0,55 s; os dois passos da
  senha ficam a 2 batidas (1 s) um do outro para o envelope fechar entre eles
  (0,2 s de silêncio). No pico, só um passo. Não aproxime.
- **O acerto do kit também toca na háptica** (`material:pedra`, 60 ms, na
  batida da escolha). Ele cai 2 batidas antes da próxima senha: os votos do
  robô zeram em `_nova_bifurcacao`, depois dele.
- **A placa virtual e o relógio.** Com `--fixed-fps 60` o jogo anda ~16 vezes
  mais depressa que a música. Meça antes de confiar no `_robo_sentir`: ponha
  um `print` do tamanho do envelope por passo numa rodada da prova; se passar
  de `ENV_MAX` (a placa virtual anda pelo relógio de parede), feche o
  envelope por tempo de música (0,2 s de `Ritmo.t_musica()`) em vez de 12
  quadros. Anote na ficha o que mediu.
- **A prova fica mais longa.** Como o fim é pela música (H08), a corrida
  inteira roda na prova (até 100 s de relógio, nas duas rodadas). É o
  preço de o `haptica_audio` sair medido; se o `timeout 1200` do
  `tests/prova_do_jogo.sh` apertar, anote e avise — não encurte a corrida
  (a regra 7 da paridade).
- **`rng` por lugar.** A ordem das chamadas muda com o quadro; cada lugar tem
  o seu `RandomNumberGenerator` (a semente do kit + o lugar), senão o caminho
  muda de uma rodada para outra.
- **Não chame `errou()`** nem `Forja.vibrar`: o Escudo e as sensações são do
  kit.
- **As provas que falam `caminhos`**: `--sala=caminhos` continua abrindo (o
  apelido); `_joga_a_sala("caminhos", ["haptica_audio"])` da prova passa a
  abrir o `S07_J31` (`_e_a_sala`, H04).

## Pronto quando

`--sala=caminhos` abre Os Caminhos no kit; joga do aviso ao resultado com 4, 3,
2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo que cai e
volta; fecha com vencedor; nenhuma pergunta aparece fora da bancada; com
`--bancada` o `haptica_audio` sai PASSOU com o robô bom e cai com o defeito de
mentira da háptica (o gauntlet); `salas/caminhos.gd` e o `.uid` saíram;
`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, e a
prancha foi olhada (Os Caminhos nas partidas com quatro, dois, um e o cabo
que cai: as placas acesas, o boneco andando, o portão).

## Provas

Em `godot/testes/prova_do_jogo.gd`:

1. **A espera pelo relógio de parede** é a da H08 (o `_joga_o_minigame`, e o
   `_termina_a_sala` e a prova de poucos com a mesma espera): Os Caminhos
   acabam pela música (até 100 s). Esta ficha não mexe nelas.

2. **`_prova_os_caminhos()`**, no lugar do bloco "Os Caminhos, às cegas"
   (o tropeço saiu):

   ```gdscript
   ## S07_J31: a senha chega aos dois atuadores de cada um (a placa virtual), o
   ## robô escolhe trilhas, nenhuma pergunta aparece fora da bancada, e o
   ## haptica_audio sai PASSOU pelas trilhas escolhidas.
   func _prova_os_caminhos() -> void:
   	var sala = await _comeca_a_sala("caminhos")
   	if sala == null:
   		return
   	_esperar(sala.id == "S07_J31", "caminhos: o apelido abre o S07_J31")
   	var sentiu := [false, false, false, false]
   	var perguntou := false
   	var inicio := Time.get_ticks_usec()
   	while is_instance_valid(sala) and sala.fase == "jogo" and not sentiu.all(func(s): return s) \
   			and Time.get_ticks_usec() - inicio < 30000000:
   		for l in 4:
   			var v := Forja.som_virtual(l)
   			if float(v.get("esq", 0.0)) > 0.05 and float(v.get("dir", 0.0)) > 0.05:
   				sentiu[l] = true
   			if not Forja.bancada and not sala.pergunta(l).is_empty():
   				perguntou = true
   		await _quadros(1)
   	_esperar(sentiu.all(func(s): return s), "caminhos: a senha chegou aos dois atuadores dos quatro %s" % [sentiu])
   	_esperar(not perguntou, "caminhos: nenhuma pergunta fora da bancada")
   	await _termina_a_sala(sala, ["haptica_audio"])
   ```

   (`_esperar` imprime cada chamada: por isso a pergunta vira uma variável e
   uma checagem só, no fim.)
3. **No `_prova_do_relatorio()`**, no laço da linha do tempo: as `pista` com
   `slot == "S07_J31"` e `evento == "mandou"` são ≥ 8 e todas `canal == "haptica"`
   (a placa virtual existe), as `entrada` `resposta` com `resposta == "certo"` são ≥ 4,
   e não há `troca` desse slot.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
(é sala da seção: os dois); `./run-local.sh -- --sala=caminhos`. Ele joga com
um controle no cabo e um no rádio: no cabo, cada chão tem de ser outro na mão
(grama macia, cascalho em estalos, metal que ressoa, água em duas ondas) e a
escolha tem de dar para fazer de olhos fechados para a senha; no rádio, a
senha pelo rumble tem de ser aprendível no treino. A descida (o pico) tem de
se sentir mais rápida, não mais confusa.

## Ao terminar

- No [quadro](README.md), a linha O1: **feito**, com o commit.
- Commit sugerido (sem trailer):
  `feat: Os Caminhos no kit — a senha na mão escolhe a trilha, sem pergunta`
