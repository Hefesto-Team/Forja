# Q1 — A Prova

**Sprint:** Q · **Slot:** S09_J41 · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 2,0 · **Depende de:** H04, F09, F01, F04, H07, G03, O1

## Por quê

A sala de hoje (`godot/scripts/salas/prova.gd`) é um tiroteio livre de 90 s
com a munição nas luzinhas, a barra de luz na cor da equipe e, no fim, duas
perguntas às cegas. No kit ela vira **cabo de guerra no ritmo**: Brasa contra
Maré numa faixa de chão; cada nota certa empurra a frente para o lado de lá,
cada erro cede terreno. As armas se revezam — o martelo (✕), a besta (R2 com
a parede e o clique do gatilho), a martelada especial (o touchpad, quando o
sino toca **só no seu controle**) —, e o golpe do outro lado chega na mão pelo
lado de onde veio. A identidade não se apaga: a barra de luz e as luzinhas são
do lugar; a cor da equipe está no chão.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](Q-a-prova.md) ("As equipes", as cores) e a [O1](O1-os-caminhos.md) (o `_pista`/`_respondeu`, as linhas `pista`/`troca`)
- `godot/scripts/salas/prova.gd` inteiro (é o que sai), em especial
  `_saida` (`:215-218`), a prova final (`:544-676`), `dar_vereditos`
  (`:679-686`), `pergunta` (`:775-805`) e o `_robo` (`:826-889`)
- A F04 (o que ela já mudou na Prova: a luz do lugar, a munição só na
  bancada)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J41",
	"titulo": "A Prova",
	"verbo": "Vença a outra equipe!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [Forja.CRUZ, Forja.TOUCHPAD],
	"camera": "fixa",
	"faixa": "MUS_S09_J41",
	"duracao": 0.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe_esq", "golpe_dir", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Vença!", "segundos": 6.0},
	# a bancada: a carga de tudo junto, e as perguntas das luzinhas e da cor
	"features": ["tudo_junto"],
	"botoes_medidos": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.TOUCHPAD],
	"gesto": "holding-right-shoot",
	"treino": false,
}
```

(As entradas são três: ✕, o R2 — eixo, fora da lista — e o touchpad.)
`duracao` 0: a partida acaba pela música (`PARTIDA := 216` batidas, ≈ 89 s),
porque, na bancada, as perguntas vêm **depois** da carga, também na prova.
Sem treino: é o fim da noite.

## Como se joga

A faixa é `MUS_S09_J41`, 145 bpm (uma batida ≈ 0,41 s). `ENTRADA := 4`.

- **As equipes:** a regra da ficha-mãe. Em cada equipe, o primeiro é **A**,
  o segundo **B**.
- **A frente:** `_frente` (em lajes, −6 a +6; começa em 0). A Brasa empurra
  para `+` (para o lado da Maré, à direita), a Maré para `−`.
- **O compasso** `m` (a partir de `c0 = ENTRADA + 4m`): A toca nas batidas
  `+0` e `+2`, B nas `+1` e `+3` — o hoqueto dentro da equipe; as duas
  equipes tocam ao mesmo tempo. Cada nota é aberta uma batida antes.
- **As armas se revezam de dois em dois compassos:** `(m / 2) % 2 == 0` é o
  **martelo** (✕ no tempo); senão, a **besta** (o R2 passando da parede para
  o clique no tempo: o aperto é o quadro em que `Forja.eixo(l, Forja.R2)`
  cruza 0,6 subindo). No começo de cada bloco de besta, o R2 de cada lugar vai
  para `GATILHO_ARMA` (2, 6, 8); no de martelo, `GATILHO_OFF`.
- **O julgamento:** `julgar_toque(l, t(bn), n)`. Acerto empurra a frente
  `EMPURRA[j]` (`[0.0, 0.10, 0.15, 0.22]`) para o lado de lá e marca
  `[0, 50, 75, 100][j]`; erro ou nota que passou **cede** `CEDE := 0.12` para
  o próprio lado.
- **A martelada (a pista privada):** a cada 4 compassos (`m % 4 == 3`), na
  batida `c0` desse compasso, em cada equipe, o **lugar** com mais PERFEITOs
  nos últimos 16 tempos (no empate, o primeiro) ouve o sino **no próprio
  alto-falante** — `_pista(l, ...)` com `via` `alto_falante`
  (`Forja.som_falante(l, "pronto", 0.8)`), `o_que` `"martelada"`. A nota dele
  na batida `+0` do compasso seguinte é **a martelada**: o touchpad (clique)
  no tempo, no lugar do ✕/R2 dele. Julgada, empurra `ESPECIAL[j]`
  (`[0.0, 0.8, 1.2, 1.5]`), a TV bate o martelo e a outra equipe sente a
  explosão. Só quem ouviu sabe; a TV não diz quem tem.
- **O golpe que vem de um lado:** em cada PERFEITO de uma equipe, o membro
  da **outra** que **não** está tocando naquela batida sente de onde veio:
  a Maré sente `golpe_esq` (a Brasa está à esquerda), a Brasa sente
  `golpe_dir`. (Quem está tocando naquela batida já tem a sensação do próprio
  toque; rumble e háptica nunca juntos.)
- **O nocaute:** `_frente` chega a ±6 → aquela equipe venceu; a partida
  acaba um compasso depois.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar toca só a primeira
  das duas notas dele em cada compasso.
- **O pico — tudo junto:** os 4 compassos do meio (`m` de 26 a 29): os dois
  membros tocam **todas** as batidas, e a arma troca **a cada batida**
  (martelo nas pares, besta nas ímpares; o R2 fica em `ARMA` o pico todo). A
  TV: `Som.tocar("especial")` na entrada; `pulso_de_luz(Tema.AMARELO)`.

## O cenário

- **A arena:** `Kit.arena(self, 6, 4)`; a luz da casa cheia:
  `luzes([Vector3(-10, 3, -6), Vector3(10, 3, -6), Vector3(-10, 3, 6), Vector3(10, 3, 6)])`,
  `atmosfera(Color("#ffb86c"), Tema.LARANJA, true, 40, 24.0, -9.8)`,
  `Efeitos.poeira(self, Vector3(0, 1.8, 0), Vector3(24, 3.5, 9), Tema.CIANO, 30)`
  (os de hoje).
- **A faixa de chão:** 12 lajes `Kit.caixa(self, Vector3(1.8, 0.04, 6.0), Vector3(-11.0 + 0.917 + 1.833 * i, 0.02, 0), ...)`
  (`LAJE := 1.833`), pintadas pelo dono: à esquerda da frente, âmbar
  `#e8a33c`; à direita, turquesa `#2fb3b3` (`Kit.material(cor.darkened(0.25), 0.0, 0.9)`,
  fosco); a laje da frente, meio a meio.
- **A frente:** uma runa `Kit.caixa(self, Vector3(0.12, 0.06, 6.2), ...)` com
  emissivo `#f8f8f2` (energia 1,5) em `x = _frente * LAJE`; anda por `lerpf`
  na meia batida depois de cada empurrão (pela batida).
- **As bases:** as bandeiras `Kit.peca(self, "banner", Vector3(±11.0, 0, ±2.5), ...)`
  e um disco da equipe sob cada base.
- **Os cavaleiros:** `martelo_na_mao(p)`, `p.preso = true`,
  `p.controlavel = false`; a Brasa em `x = fx - 1.6`, a Maré em `x = fx + 1.6`
  (`fx` = o x da frente), A em `z = -1.2`, B em `z = 1.2`, de frente para a
  frente. Sob cada um, um disco `Kit.cilindro(self, 0.7, 0.02, ..., cor_da_equipe)`
  (8 lados). Martelo: `attack-melee-right`; besta: `holding-right-shoot` e um
  virote (`Kit.caixa` 0,5 × 0,08 × 0,08, emissivo da cor da equipe — é efeito
  de acerto) que voa até a frente em meia batida.
- **O Aprendiz:** o boneco da ficha-mãe no lugar do membro que falta.
- **A câmera:** `camera_pos = Vector3(0, 13.5, 12.5)`, `camera_olhar = Vector3(0, 0, 0.5)`.
- **Checklist de arte (11):** a runa da frente e os virotes são os únicos
  emissivos novos (têm trabalho); lajes foscas; as cores das equipes longe
  das dos lugares; os pilares e a bala esférica de hoje saem (a bala era
  `Kit.esfera`); a prancha com os quatro e a frente.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho (tudo junto)** | o R2 com a parede e o clique (`GATILHO_ARMA` 2, 6, 8) nos blocos de besta; solto no martelo | a cada dois compassos |
| **vibração** | o golpe do lado de lá (`golpe_esq`/`golpe_dir`) em quem espera; a martelada inimiga: `Forja.sentir(l, "explosao")` na equipe atingida | no PERFEITO do outro; na martelada |
| **alto-falante do dono** | o sino da martelada, só dele (`pronto`); o clique da besta (`Forja.som_falante(l, "clique", 0.6)` quando o R2 passa do 0,6); a nota dele (kit) | a martelada; cada disparo |
| **háptica por material** | o kit (`material:metal`) em cada acerto, no cabo | no toque |
| barra de luz | **a cor do lugar, sempre** (o minigame não chama `Forja.luz`) | — |
| luzinhas | **o número do jogador, sempre** (só a bancada as usa, na pergunta do fim) | — |
| microfone | fica de fora (a voz de um é ouvida por todos numa sala) | — |
| TV | o estádio; `Som.tocar("martelo", pos, -6.0)` em cada martelo; `Som.tocar("tiro", pos, -10.0)` em cada virote; `Som.tocar("martelo", frente, 2.0)` e `tremor = 0.7` na martelada | — |

**No rádio:** o gatilho e a vibração vão pela ponte; o `material` do kit vira
rumble (o kit, sem placa). Nada muda na regra.

## A falha

**Cede terreno:** o erro (ou a nota que passou) empurra a frente 0,12 laje
para o próprio lado; o cavaleiro que errou recua junto com a frente e faz
`emote-no` (0,3 s); no martelo, o martelo quica (`attack-melee-left`, meio
gesto); na besta, o virote cai aos pés (`Efeitos.faiscas(self, pos, Color("#8c98aa"), 8, 0.4)`).

## O fim e o vencedor

A partida acaba na batida `ENTRADA + PARTIDA` (ou um compasso depois do
nocaute): o apito da partida (`Som.tocar("sucesso", null, -4.0)`), a frente
para, o R2 de todos volta a `GATILHO_OFF`. Sem a bancada, todos acabam ali.
**O vencedor:** a equipe do lado para onde a frente andou (`_frente > 0`:
Brasa; `< 0`: Maré; `== 0`: a de mais pontos somados; empate: a Brasa).
`vencedor()` devolve os lugares da equipe vencedora (pelos pontos) e depois
os da outra.

## A bancada (só com `Forja.bancada`)

Depois do apito, a prova final às cegas de hoje, **sem mudar a regra**:
`_perguntar_leds()`, `_perguntar_cor()`, `_rodada_final()`, `_sem_revelar()`
e `pergunta(l)` (`prova.gd:544-610`, `:672-676`, `:775-805`), com o tempo
delas pelo `dt` (é a camada da bancada). Duas trocas: a luzinha sorteada
nunca é a do próprio lugar (`while k == l + 1`: é o padrão que já está
aceso), e a cor sorteada nunca é a parecida com a **do lugar**
(`COR_PARECIDA_DO_LUGAR := [1, 0, -1, 2]`: o P1 azul lembra o ciano, o P2
vermelho o âmbar, o P4 magenta o violeta). Depois da cor, a luz e as
luzinhas do lugar voltam (`Forja.luz_do_lugar(l)`, `Forja.leds_do_lugar(l)`)
e todos acabam. `pergunta(l)` devolve `{}` sem a bancada.

`dar_vereditos(l)`: `Forja.carga_parar(l)`, `Forja.carga_placar(l, tocadas, acertadas, marteladas)`
e `Forja.carga_veredito(l, leds, cor, tocadas > 0 or Cega.total(leds) > 0)`
(o de hoje, `prova.gd:679-686`, com os números do minigame).

## Com menos de quatro

- **3, 2, 1:** a regra da ficha-mãe, com o Aprendiz. O Aprendiz toca as
  notas do papel dele (acerta 80%, sempre BOM): empurra ou cede como
  qualquer um; nunca ouve o sino (a martelada é de lugar). Uma equipe só de
  Aprendizes não tem martelada. `com_poucos()`: `"Com o Aprendiz"` (3, 2) ou
  `"Você e o Aprendiz contra 2"` (1).
- **O controle que cai:** as notas dele não abrem (a equipe não empurra nem
  cede por ele); o sino não vai para ele; o `_saida` não conta a saída de
  quem está sem controle (como hoje). Volta no compasso seguinte.

## O robô

Toca pelo relógio da música pelo controle simulado; **ouve** o sino no
alto-falante da placa virtual (um defeito de mentira no alto-falante faz ele
perder a martelada); na bancada, olha as luzinhas e a luz dele (a `percepcao`,
como hoje).

```gdscript
func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	if _acabou_a_partida:
		if Forja.bancada:
			_robo_prova_final(l, dt)       # o ramo LEDS/COR do _robo de hoje (prova.gd:829-851)
		return
	# o sino: ouvido no alto-falante do controle simulado
	if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
		_robo_ouviu_sino[l] = _m
	var n: int = _nota[l]
	if n < 0 or _robo_tocou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.25 if rng.randf() < 0.6 else 99.0)
	if Ritmo.t_musica() < float(_alvo[l]) + float(_robo_mira[l]):
		return
	if _arma_da_nota[l] == MARTELADA:
		if _robo_ouviu_sino[l] == _m - 1:
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
	elif _arma_da_nota[l] == BESTA:
		Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
	else:
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
	_robo_tocou[l] = n
```

## Os ganchos

`godot/scripts/minigames/s09/a_prova.gd`, `extends Minigame`. O que muda do
`prova.gd` de hoje:

| sai | por quê |
| --- | --- |
| `class_name SalaProva`, `_init()`, `_conectado`, `objetivo`, `CONTAGEM`, `PARTIDA_S` | o kit; a partida é pela batida |
| o tiroteio livre: `_jogador`, `_boneco`, `_mover_tiros`, `_empurrar`, os pilares, `VEL`, a mira, a recarga | a partida é o cabo de guerra no ritmo |
| a munição nas luzinhas (`_mostrar_municao`) e a luz da equipe (`_atualizar_luz`, `LUZ_EQUIPE` na barra) | a identidade (F04): as luzinhas e a barra são do lugar |
| o `L2` em resistência | o L2 é do item (G03); `usa_gatilho = true` |
| `Forja.vibrar(...)` direto | `Forja.sentir(l, "golpe_esq" / "golpe_dir" / "explosao")` |
| o `_process` | o `_mostrar(b)` no fim do `jogar` |
| **fica:** a prova final (só na bancada), `_saida`, `dar_vereditos`, `_tingir`, `_cor_mais_perto` | a bancada |

```gdscript
extends Minigame
## A Prova (S09_J41). Brasa contra Maré, no ritmo: cada nota certa empurra a
## frente para o lado de lá, cada erro cede terreno. As armas se revezam — o
## martelo (✕), a besta (R2 até o clique) — e, quando o sino toca só no seu
## controle, a martelada (o clique do touchpad) no começo do compasso.
##
## A falha: cede terreno (o martelo quica, o virote cai). O vencedor: a
## equipe com mais terreno (ou o nocaute). O alto-falante do dono: o sino da
## martelada, o clique da besta. O registro mede: a carga de saídas dos quatro
## ao mesmo tempo (carga_*), o sino (pista) e a resposta; na bancada, as
## luzinhas e a cor depois da carga. O robô: toca pelo relógio e ouve o sino
## na placa virtual. Com menos de quatro: o Aprendiz completa. A régua: a
## cor da equipe está no chão; a barra e as luzinhas nunca deixam de ser do
## jogador.

const FICHA := { ... }

enum { MARTELO, BESTA, MARTELADA }
const ENTRADA := 4
const PARTIDA := 216
const PICO_DE := 26
const PICO_ATE := 30
const LAJE := 1.833
const EMPURRA := [0.0, 0.10, 0.15, 0.22]
const ESPECIAL := [0.0, 0.8, 1.2, 1.5]
const CEDE := 0.12
const PONTOS := [0, 50, 75, 100]
const ACERTO_APRENDIZ := 0.8
const COR_EQUIPE := [Color("#e8a33c"), Color("#2fb3b3")]
const COR_PARECIDA_DO_LUGAR := [1, 0, -1, 2]
# ... e as da prova final de hoje (CORES, BOTAO, GLIFO, PERGUNTA_ESPERA, PERGUNTA_S)

var _equipe := {}              ## lugar -> 0 (Brasa) / 1 (Maré)
var _papel := {}               ## lugar -> 0 (A) / 1 (B)
var _aprendizes := []          ## {equipe, papel, no, anim}
var _frente := 0.0
var _f_de := 0.0
var _f_ate := 0.0
var _f_b0 := -9.0
var _m := -1                   ## o compasso da vez
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _arma_da_nota := [MARTELO, MARTELO, MARTELO, MARTELO]
var _n := [0, 0, 0, 0]
var _feita := [-1.0, -1.0, -1.0, -1.0]
var _r2_antes := [0.0, 0.0, 0.0, 0.0]
var _perfeitos := [[], [], [], []]   ## as batidas dos PERFEITOs de cada um (a martelada)
var _sino := [-1, -1]           ## equipe -> o lugar que ouviu o sino neste ciclo
var _tocadas := [0, 0, 0, 0]
var _acertadas := [0, 0, 0, 0]
var _marteladas := [0, 0, 0, 0]
var _fim_batida := -1.0
var _acabou_a_partida := false
var fin := {}                  ## a prova final (a de hoje)
var etapa := 0                 ## a prova final: LEDS, COR (a de hoje)
var _nos := {}
var _robo_nota := [-1, -1, -1, -1]
var _robo_tocou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_ouviu_sino := [-9, -9, -9, -9]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 13.5, 12.5)
	camera_olhar = Vector3(0, 0, 0.5)
	_formar_equipes()             # a regra da ficha-mãe; os Aprendizes
	# a arena, a faixa de chão, a runa, as bandeiras, os cavaleiros e os discos


func iniciar_jogo() -> void:
	_fim_batida = float(ENTRADA + PARTIDA)
	for l in presentes():
		fin[l] = {"leds": Cega.nova(), "cor": Cega.nova(), "leds_pedido": -1, "cor_pedida": -1, "resp": -1,
			"t": 0.0, "robo_espera": -1.0}
		Forja.carga_comecar(l)
		_saida(l, Forja.gatilho(l, 1, Forja.GATILHO_OFF))


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	if not _acabou_a_partida:
		var proximo := _m + 1
		if b >= ENTRADA + 4.0 * proximo - 1.0:
			_novo_compasso(proximo)   # uma batida antes: a arma do bloco (o gatilho), o sino (m % 4 == 3)
		for l in presentes():
			if not conectado(l):
				_nota[l] = -1
				continue
			_abrir_nota(l, b)         # a próxima nota do papel dele, uma batida antes
			_entrada(l)               # ✕, R2 cruzando 0,6 (e o clique no alto-falante), touchpad: julgar_toque
			_prazo(l)                 # a nota que passou: CEDE, nota_perdida
		_aprendizes_tocam(b)
		if b >= _fim_batida:
			_apito()                  # _acabou_a_partida = true; R2 solto; sem a bancada, acabou de todos
	elif Forja.bancada:
		_prova_final(dt)              # LEDS → COR → a luz e as luzinhas do lugar → acabou de todos
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_acertadas[l] += 1
	var e: int = _equipe[l]
	if _arma_da_nota[l] == MARTELADA:
		_marteladas[l] += 1
		_respondeu(l, _n[l] - 1, "certo")
		_empurrar(e, ESPECIAL[j])
		_martelada_na_tv(e)          # o martelo, o tremor, a explosão na outra equipe
	else:
		_empurrar(e, EMPURRA[j])
	if j == Ritmo.PERFEITO:
		_perfeitos[l].append(Ritmo.batida())
		_golpe_do_lado(e)            # o membro da outra equipe que não toca agora


func falha(l: int) -> void:
	_ceder(_equipe[l])
	jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var e := 0 if _frente > 0.0 else (1 if _frente < 0.0 else _mais_pontos())
	var ganhou := presentes().filter(func(l): return _equipe[l] == e)
	var perdeu := presentes().filter(func(l): return _equipe[l] != e)
	ganhou.sort_custom(func(a, b): return pontos[a] > pontos[b])
	perdeu.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return ganhou + perdeu


func pergunta(l: int) -> Dictionary:
	if not Forja.bancada or not _acabou_a_partida:
		return {}
	return _pergunta_da_prova_final(l)   # a de hoje


func dar_vereditos(l: int) -> Array:
	if not fin.has(l):
		return []
	Forja.carga_parar(l)
	Forja.carga_placar(l, _tocadas[l], _acertadas[l], _marteladas[l])
	var v := Forja.carga_veredito(l, fin[l].leds, fin[l].cor, _tocadas[l] > 0 or Cega.total(fin[l].leds) > 0)
	return [] if v.is_empty() else [v]
```

`_saida(l, ok)` é a de hoje (`Forja.carga_saida` só com controle). **Toda
saída do minigame passa por ela:** `_saida(l, Forja.gatilho(...))`,
`_saida(l, Forja.sentir(l, ...))`. `_empurrar(e, d)`: `_frente` anda `d` para
o lado de lá da equipe `e` (`+` para a Brasa), com o `lerpf` da runa;
`_ceder(e)`: `CEDE` para o próprio lado; os dois conferem o nocaute
(`absf(_frente) >= 6.0` → `_fim_batida = min(_fim_batida, b + 4)`).
`_novo_compasso(m)`: `_m = m`; a arma (`MARTELO`/`BESTA`, ou a de cada batida
no pico); na troca de bloco, o R2 de todos (`ARMA` ou `OFF`); se
`m % 4 == 3`, o sino de cada equipe: `_sino(l, n)`, que faz
`Forja.som_falante(l, "pronto", 0.8)` e grava
`Forja.evento("pista", l + 1, {"slot": id, "n": n, "evento": "mandou", "via": "alto_falante", "o_que": "martelada"})`
(o `_respondeu` é o do O1); a nota de quem ouviu o sino na batida `+0` do
compasso seguinte é `MARTELADA`.
`_entrada(l)`: `MARTELO` → `Forja.apertou(l, Forja.CRUZ)`; `BESTA` → o R2
cruzou 0,6 subindo (e `Forja.som_falante(l, "clique", 0.6)`); `MARTELADA` →
`Forja.apertou(l, Forja.TOUCHPAD)`; qualquer um deles com nota aberta →
`_tocadas[l] += 1`, `julgar_toque`. A martelada que passou sem toque:
`_respondeu(l, n, "nenhuma")`.

Dica (com `na_raia(l)`): o glifo da arma da nota aberta (`["@cross"]` ou
`["@r2"]`) enquanto `not aprendeu(l)`. A martelada **não** tem dica: a dica
aparece na TV de todos, e o sino é segredo de quem o ouviu.
`status(l)`: `"Brasa"` / `"Maré"`; `progresso()`: nada (a frente é o placar).

**A casa nova e o catálogo:** `godot/scripts/minigames/s09/a_prova.gd` e o
`.uid`; `"S09_J41"` em `MINIGAMES` e `"minigames": ["S09_J41"]` na seção
`S09`; tire `"prova"` de `SALAS_ANTIGAS`; `git rm godot/scripts/salas/prova.gd godot/scripts/salas/prova.gd.uid`
(e `grep -rn "SalaProva" godot/` vazio — a prova do jogo usa `SalaProva.PARTIDA`,
`LUZ_EQUIPE` e `NOME_EQUIPE`: saem com as checagens novas). Traduções:
`"A Prova": "The Trial"`, `"Vença a outra equipe!": "Beat the other team!"`,
`"Vença!": "Win!"`, `"Brasa": "Ember"`, `"Maré": "Tide"`, `"Com o Aprendiz": "With the Apprentice"`
(se a O5 já não pôs), `"Você e o Aprendiz contra 2": "You and the Apprentice against 2"`;
tire as frases do tiroteio (`"recarregue"`, `"martelada!"`, `"%s · vida %d · %d balas"`...)
que ninguém mais usa.

## O que o registro mede

- **a carga:** cada `saida` (gatilho a cada bloco, vibração a cada golpe do
  lado, a explosão da martelada) com `seq` e `ok`, dos quatro ao mesmo
  tempo; `Forja.carga_*` soma as recusas sob carga (o veredito `tudo_junto`,
  na bancada, e a linha no relatório nos dois modos);
- `pista` do sino (`via` `alto_falante`) e a martelada depois dele — a noite
  vê se o alto-falante de cada controle chegou;
- `sensacao` `golpe_esq`/`golpe_dir` (o lado, no controle de quem esperava);
- `nota`/`toque` de todas as armas.

## Armadilhas

- **A barra de luz e as luzinhas não são da equipe.** Nenhum `Forja.luz` e
  nenhum `Forja.leds_jogador` fora da prova final da bancada. A prova confere.
- **Rumble e háptica nunca juntos:** o golpe do lado vai só para quem **não**
  está tocando naquela batida.
- **O R2 cruzando 0,6** é o disparo (como `prova.gd:406` hoje); o clique do
  gatilho físico fica perto disso com `ARMA` 2, 6, 8. Não julgue pelo
  `Forja.apertou` — o R2 não é botão.
- **A partida acaba pela música**: a prova fica mais longa (uns 90 s de
  relógio por rodada, mais a prova final na bancada). Não encurte (a regra
  7); se o `timeout 1200` apertar, anote e avise.
- **`Forja.robo` só no `robo()`**; o `_robo_prova_final` é chamado de dentro
  dele e não tem a palavra.
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

`--sala=prova` abre A Prova no kit; joga do aviso ao resultado com 4, 3, 2 e
1 jogador (com o Aprendiz) e com o robô nos três temperamentos; aguenta o
cabo que cai e volta; fecha com uma equipe vencedora; a barra de luz e as
luzinhas ficam do lugar a partida inteira; com `--bancada`, as duas perguntas
do fim e o `tudo_junto` saem como hoje; `salas/prova.gd` saiu;
`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, e a
prancha foi olhada (a faixa em duas cores, a runa andando, os virotes).

## Provas

Em `godot/testes/prova_do_jogo.gd`, no lugar do bloco "A Prova" de hoje:

```gdscript
## S09_J41: a partida inteira com a luz e as luzinhas de cada controle nas do
## lugar; o R2 em arma nos blocos de besta; a frente anda; e, na bancada, o
## tudo_junto.
func _prova_a_prova() -> void:
	var sala = await _comeca_a_sala("prova")
	if sala == null:
		return
	_esperar(sala.id == "S09_J41", "prova: o apelido abre o S09_J41")
	var identidade_ok := true
	var viu_besta := false
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(sala) and not sala._acabou_a_partida and Time.get_ticks_usec() - inicio < 150000000:
		for l in 4:
			var p := _perc(l)
			var luz: Color = p.get("luz", Color.BLACK)
			var cor := Forja.cor_do_lugar(l)
			if Vector3(luz.r - cor.r, luz.g - cor.g, luz.b - cor.b).length() > 0.05:
				identidade_ok = false
			if int(p.get("leds_jogador", 0)) != Forja.LEDS_DO_LUGAR[l]:
				identidade_ok = false
			if sala._m >= 0 and (sala._m / 2) % 2 == 1 and int(p.get("gatilho_dir", 0)) == 0x25:
				viu_besta = true
		await _quadros(5)
	_esperar(identidade_ok, "prova: a luz e as luzinhas de cada um ficaram as do lugar a partida inteira")
	_esperar(viu_besta, "prova: o R2 em arma (0x25) num bloco de besta")
	if is_instance_valid(sala):
		_esperar(absf(sala._frente) > 0.0, "prova: a frente andou (%.2f)" % sala._frente)
	await _termina_a_sala(sala, ["tudo_junto"])
```

(O `_termina_a_sala` espera pelo relógio de parede desde a O1. A lista de
vereditos por modo é a da F01: sem a bancada, o `tudo_junto` sai "não
medido" e a checagem é a que ela deixou.) No `_prova_do_relatorio()`: há
`pista` do `S09_J41` com `via == "alto_falante"`, e nenhuma `saida` com
`o == "lightbar"` desse minigame fora da bancada.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`;
`./run-local.sh -- --sala=prova`. Com dois no cabo e dois no rádio: o clique
da besta tem de estar no dedo; o sino tem de ser segredo (ninguém mais
ouve); o golpe do lado tem de chegar na mão de quem esperava, do lado certo;
e a barra de luz nunca pode trocar de cor.

## Ao terminar

- No [quadro](README.md), a linha Q1: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: A Prova no kit — cabo de guerra no ritmo, a identidade intacta`
