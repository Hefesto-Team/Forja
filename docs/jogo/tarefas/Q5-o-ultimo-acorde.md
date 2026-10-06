# Q5 — O Último Acorde

**Sprint:** Q · **Slot:** S09_J45 · **Tamanho:** G · **Depende de:** H04, H08, F09, H07, G03, Q1, Q4, O1 (o `_pista`), P1 (o ouvido), e as seções S5 a S8 prontas

## Por quê

O fim da noite. O dragão — o coração da Dissonância — está de pé, e a turma
o derruba com o que aprendeu na segunda metade do jogo: **atirar** (S5, o
gatilho com o clique), **repetir** (S6, o canto no alto-falante de cada um),
**sentir** (S7, a pedra na mão), **soprar** (S8, a voz). E, no fim, 32 notas
em **chamada e resposta** divididas entre os quatro: o dragão chama um, esse
um responde. Se o acorde falta, o dragão se levanta de novo — mais oito
notas.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](Q-a-prova.md), "Os medleys"
- A [Q4](Q4-ruge-o-reator.md) (a estrutura do roteiro, a linha `estacao`: esta ficha é a mesma forma, com outras estações)
- A [O1](O1-os-caminhos.md) (o `_pista`, o `_respondeu`, a `troca`), a
  [O2](O2-neblina-de-dados.md) (a pedra: sentir e saltar) e a
  [P1](P1-a-voz.md) (o ouvido, igual)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J45",
	"titulo": "O Último Acorde",
	"verbo": "O acorde final!",
	"genero": "coop",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S09_J45",
	"duracao": 0.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao", "aviso"],
	"material": "metal",
	"microjogo": {"verbo": "Acorde!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_MICROFONE,  # a estação 4; o alto-falante e a háptica tocam com a placa aberta (H07)
	"gesto": "holding-right-shoot",
	"treino": false,
}
```

(Entrada-botão: ✕ — responder, repetir, saltar. O R2, eixo, atira; a voz
sopra. Cada **estação** usa no máximo duas.) `duracao` 0: acaba pela música
(de 268 a 300 batidas, 107 a 120 s). Sem treino.

## Como se joga

A faixa é `MUS_S09_J45`, 150 bpm (uma batida = 0,4 s). `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08).

**O roteiro** (em batidas):

| trecho | batidas | o verbo |
| --- | --- | --- |
| a contagem | 0 a 3 | o dragão se ergue |
| **1. Atirar** (S5) | 4 a 51 | o R2 até o clique, no seu tempo |
| **2. Repetir** (S6) | 52 a 99 | o seu controle canta duas notas; repita o ritmo no ✕ |
| **o eclipse** (o pico) | 100 a 107 | os quatro repetem juntos a mesma frase, que a TV canta |
| **3. Sentir** (S7) | 108 a 155 | a pedra na mão meio tempo antes: ✕ no firme, nada na neblina |
| **4. Soprar** (S8) | 156 a 203 | sopre no seu tempo |
| **o acorde final** | 204 a 267 (+ 16 por volta extra, até duas) | chamada e resposta: 32 respostas divididas entre os quatro |

- **O hoqueto (nas estações 1, 3 e 4):** como na Q4 — a batida `k` da
  estação é de `presentes()[k % np]`; cada nota abre uma batida antes.
- **A partitura simples** (`Ritmo.simples[l]`): uma nota sim, uma não, das
  dele.

### As estações

1. **Atirar.** O R2 de todos em `GATILHO_ARMA` (2, 6, 8) durante a estação
   (`usa_gatilho = true`); o disparo é o R2 cruzando 0,6 subindo (a Q1) →
   `julgar_toque`; o clique no alto-falante do dono
   (`Forja.som_falante(l, "clique", 0.6)`). Na troca de estação, `GATILHO_OFF`.
2. **Repetir.** Aqui o dono é **o compasso**: o compasso `c` da estação é de
   `presentes()[c % np]`. Nas batidas 0 e 1 do compasso, o alto-falante
   **dele** canta um ritmo de duas notas (`Forja.som_falante(l, "nota:%d" % l, 0.8)`
   em `c0 + a` e `c0 + b`, com `[a, b]` de `RITMOS := [[0.0, 0.5], [0.0, 1.0], [0.5, 1.0], [0.0, 1.5]]`,
   pelo `rng`) — a `pista` com `canal` `alto_falante`, `o_que` o ritmo; a TV
   fica calada. Nas batidas 2 e 3, ele repete com ✕: duas notas, alvos
   `c0 + 2 + a` e `c0 + 2 + b` (a janela vale sobre o tempo, como toda
   nota). Sem alto-falante no controle dele
   (`not Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)`): o ritmo toca na TV,
   em `Som.tocar("nota", raia, -6.0, TOM_DO_LUGAR[l])`, com a `troca`
   (`de` `alto_falante`, `para` `tv`, `motivo` `sem_placa`).
3. **Sentir.** A pedra da O2, no hoqueto: meia batida antes da batida de
   cada um, se ali há pedra (60%, pelo `rng`), `material:pedra` na mão dele
   (o `_pista`; no rádio, `aviso`); ✕ na pedra → `julgar_toque`; ✕ na
   neblina (a batida dele sem pedra, dentro da janela) → a falha, sem nota; a
   pedra que passou sem ✕ → `nota_perdida`.
4. **Soprar.** O ouvido da P1 (igual): o começo da voz a até 0,35 s da nota
   dele → `julgar_toque(l, t(bn) + LATENCIA_MIC, n)`. Sem microfone ou mudo:
   sopra sozinho — a nota não abre, e ele marca 25 (a `troca` da P1).

- **O eclipse (o pico):** 8 batidas. Nas 4 primeiras, a TV canta uma frase
  de quatro notas (`Som.tocar("nota", null, -4.0, <tom>)` nas batidas 0, 1,
  1.5 e 3); nas 4 seguintes, **todos** repetem com ✕ (notas de todos nos
  mesmos alvos). O dragão escurece o céu (as tochas a 0,3 durante o eclipse).
- **O acorde final** (a meta): 16 compassos. Em cada compasso, duas
  chamadas: na batida 0, o dragão chama o lugar `presentes()[r % np]` (a
  chamada `r` conta de 0): o alto-falante dele toca `nota:<l>` e a TV ruge
  curto (`Som.tocar("grito", dragao, -10.0)`); na batida 1, **ele** responde
  com ✕ (a nota). Na batida 2, a próxima chamada; na 3, a resposta. São 32
  respostas. `_faltas_final` conta as respostas erradas ou perdidas.
  - Depois das 32: `_faltas_final <= 8` → **o dragão cai**. Senão, **o
    dragão se levanta de novo**: mais 8 respostas (4 compassos, a mesma
    regra) e só elas contam agora (`_faltas_final = 0`); com `<= 2` faltas
    nelas, ele cai. No máximo duas voltas extras; depois da segunda sem
    cair, **o dragão foge** para a névoa.
- **Pontos:** `[0, 50, 75, 100][j]` por nota; cada resposta do acorde final
  vale o dobro.

## O cenário

- **O coração da Dissonância:** `Kit.arena(self, 6, 4)`; a luz da casa com
  néon roxo, cheia (é o fim, não terror): `luzes([Vector3(-9, 3, 3), Vector3(9, 3, 3)])`,
  `atmosfera(Color("#b9b0ff"), Tema.ROXO, true, 80, 24.0, -9.0, 0.35)`.
- **O dragão:** o da Q4 (as mesmas peças; copie o `_montar_dragao()` de lá),
  maior (`scale` 1,2), com a cabeça mais alta (de pé). Ele se levanta nas
  voltas extras (a cabeça sobe 1 m em um compasso) e cai no fim (a cabeça
  desce ao chão em dois compassos, os olhos apagam, a chuva de luz:
  `Efeitos.faiscas(self, Vector3(0, 6, -5), Color("#f8f8f2"), 120, 2.0)` e
  `Efeitos.brasas` brancas por 4 s).
- **Os cavaleiros:** `raia(l)` e `posicionar(l)`, de frente para o dragão
  (`rotation.y = PI`); `holding-right-shoot` na estação 1, `interact-right`
  na 2, `jump` na 3, `interact-left` na 4, `attack-melee-right` no final.
- **As peças das estações:** alvos de 8 lados diante do dragão (a estação 1:
  `Kit.cilindro(self, 0.5, 0.1, ...)` de lado, que se partem no acerto — as
  runas de G08); as lajes de pedra da O2 à frente de cada raia (a estação 3:
  aparecem quando ele pousa); o braseiro da P1 à frente de cada raia (a
  estação 4: a chama sobe com a voz dele).
- **A câmera:** `camera_pos = Vector3(0, 8.5, 12.5)`, `camera_olhar = Vector3(0, 2.5, -2.5)`.
- **Checklist de arte (11):** o dragão da Q4; os alvos de 8 lados; o emissivo
  nos olhos, na chuva de luz e na borda da raia; nada nas cores dos lugares.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilho** | a arma com o clique (`ARMA` 2, 6, 8) | a estação 1 |
| **alto-falante do dono** | o canto de duas notas, só dele; a chamada do dragão, só de quem responde; o clique da arma | a 2; o final; a 1 |
| **háptica** | a pedra na mão (`material:pedra`) | a estação 3 |
| **microfone** | o sopro | a estação 4 |
| vibração | o kit; a chamada do final: `Forja.sentir(l, "aviso")` em quem vai responder, junto com o canto (no rádio, é a pista); a queda do dragão: `explosao` em todos | — |
| barra de luz | a cor do lugar, sempre | — |
| luzinhas | o número do jogador, sempre | — |
| TV | o coro heroico; `Som.tocar("transicao")` a cada estação; `Som.tocar("vitoria_noite")` na queda do dragão | — |

**No rádio** (sem placa de áudio): a pedra da estação 3 vai pelo rumble
(`aviso`), com a `troca`; o canto da estação 2 vai para a TV (a regra do
"Repetir"); a chamada do final fica no `aviso` da mão (que já vai junto); o
sopro da estação 4 é "sozinho" (a P1). **Microfone mudo:** sopra sozinho.

## A falha

- **Nas estações:** o alvo não se parte (o virote passa longe), o canto sai
  desafinado (a nota quebrada no alto-falante: o kit), o cavaleiro some na
  neblina e volta (a O2, só o gesto, sem distância aqui), o braseiro cospe
  cinza (a P1). O dragão ri (a mandíbula abre e fecha, pela batida).
- **No final:** a resposta que falta — o dragão ruge por cima, e a nota
  quebrada soa no controle de quem faltou.
- **O acorde que falta** (as 32 com mais de 8 faltas): o dragão se levanta
  de novo (a cabeça sobe), a TV bate `Som.tocar("martelo", dragao, 2.0)`, e
  vêm mais 8 notas.

## O fim e o vencedor

O `coop` vem do gênero da FICHA (H08). O dragão cai → `coop_venceu = true`, a chuva de
luz e o jingle da noite; o medley acaba 8 batidas depois. O dragão foge (duas
voltas extras sem cair) → `coop_venceu = false`; acaba 4 batidas depois. Em
qualquer caso, todos acabam. O registro grava `vencedor` −1 (coop); `destaque()`:
quem errou menos no medley inteiro (`_erros[l]`), depois pontos. A noite segue para o pódio
(`main.gd`).

## Com menos de quatro

- **3, 2, 1:** o hoqueto e as chamadas se repartem por `presentes()`; com
  um, ele responde as 32 sozinho (e o "Repetir" é todo dele).
- **O controle que cai:** as notas dele não abrem nem erram; no final, a
  chamada dele **pula para o próximo** presente conectado (as 32 respostas
  continuam 32). Volta na próxima nota dele.
- **Duplas:** não há (coop de todos).

## O robô

Um ramo por estação, pelo controle simulado e pelo relógio; no "Repetir" e
no final ele **ouve** o próprio alto-falante (a placa virtual) e responde ao
que ouviu; na "Sentir", sente a pedra (o `_robo_sente` da O2).

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	# o alto-falante do controle simulado tocou alguma coisa (o canto, a chamada)?
	if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
		_robo_ouviu_b[l] = b
	# a pedra (a estação 3)
	if _verbo_da_vez == SENTIR:
		var n := ceili(b)
		if b > n - 0.55 and b < n - 0.05 and _robo_sente(l).length() > 0.05:
			_robo_firme[l] = n
	var n: int = _nota[l]
	if n < 0 or _robo_tocou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.25 if _robo_rng.randf() < 0.6 else 99.0)
	var alvo := float(_alvo[l]) + float(_robo_mira[l])
	match _verbo[l]:
		ATIRAR:
			if Ritmo.t_musica() >= alvo:
				Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
				_robo_tocou[l] = n
		REPETIR, FINAL:
			# só responde ao que ouviu: sem o canto (o alto-falante com defeito), não sabe o ritmo
			if not _robo_ouviu_para(l, n):
				return
			if Ritmo.t_musica() >= alvo:
				Forja.robo_apertar(l, Forja.CRUZ, 0.05)
				_robo_tocou[l] = n
		SENTIR:
			if _robo_firme[l] == roundi(_bn[l]) and Ritmo.t_musica() >= alvo:
				Forja.robo_apertar(l, Forja.CRUZ, 0.05)
				_robo_tocou[l] = n
		SOPRAR:
			if Ritmo.t_musica() >= alvo + LATENCIA_MIC:
				Forja.robo_falar(l, 0.8, 0.25)
				_robo_tocou[l] = n
```

`_robo_ouviu_para(l, n)`: o robô só responde se **o som chegou** ao
alto-falante do controle simulado dele — no "Repetir", alguma coisa soou
entre o começo do compasso dele e a primeira nota da resposta
(`_robo_ouviu_b[l] >= c0` do compasso da nota); no final, soou a chamada
(`_robo_ouviu_b[l] >= _bn[l] - 1.2`). O **ritmo** ele lê do minigame
(`_alvo[l]`): o que se prova é que o canto chegou, não o ouvido do robô.
Com o alto-falante com defeito de mentira, ele não responde, e o registro
mostra. (O ruim, com a mira 99,0, também não responde.)

## Os ganchos

`godot/scripts/minigames/s09/o_ultimo_acorde.gd`, `extends Minigame`. A
forma é a da Q4 (o `ROTEIRO`, o `_distribuir`, o `_trocar_trecho` com a linha
`estacao`, o `_entrada` por verbo); o que muda:

```gdscript
extends Minigame
## O Último Acorde (S09_J45). O fim da noite: quatro estações sem pausa —
## atirar (R2 até o clique), repetir (o seu controle canta; repita no ✕),
## sentir (a pedra na mão; ✕ no firme), soprar (a voz no tempo) — e o acorde
## final: 32 notas em chamada e resposta divididas entre os quatro. Se o acorde
## falta, o dragão se levanta de novo: mais oito notas.
##
## A falha: o acorde que falta. O vencedor: coop (o dragão cai numa chuva de
## luz); o destaque é quem errou menos. O alto-falante do dono: o canto e a
## chamada, só dele. O registro mede: cada estação (estacao), o desvio de cada
## recurso, e as pistas do alto-falante e da háptica com a resposta. O robô:
## ouve o próprio alto-falante e sente a pedra. Com menos de quatro: as
## chamadas se repartem. A régua: o verbo e o ícone de cada estação; nada
## pergunta nada.

const FICHA := { ... }

enum { ATIRAR, REPETIR, SENTIR, SOPRAR, ECLIPSE, FINAL }
const ROTEIRO := [
	{"de": 4, "ate": 52, "verbo": ATIRAR},
	{"de": 52, "ate": 100, "verbo": REPETIR},
	{"de": 100, "ate": 108, "verbo": ECLIPSE},
	{"de": 108, "ate": 156, "verbo": SENTIR},
	{"de": 156, "ate": 204, "verbo": SOPRAR},
	{"de": 204, "ate": 268, "verbo": FINAL},     # + 16 por volta extra
]
const RITMOS := [[0.0, 0.5], [0.0, 1.0], [0.5, 1.0], [0.0, 1.5]]
const FRASE_ECLIPSE := [0.0, 1.0, 1.5, 3.0]
const RESPOSTAS := 32
const EXTRA := 8
const FALTAS_MAX := 8
const FALTAS_MAX_EXTRA := 2
const VOLTAS_MAX := 2
const FIRME_CHANCE := 0.6
const PONTOS := [0, 50, 75, 100]
const NOME_ESTACAO := ["atirar", "repetir", "sentir", "soprar", "eclipse", "final"]
# ... e as do ouvido (a P1)

var _verbo_da_vez := ATIRAR
var _fim_final := 268.0          ## o fim do acorde final (anda 16 por volta extra)
var _voltas := 0
var _faltas_final := 0
var _respostas := 0
var _caiu := false
var _fugiu := false
var _fim_batida := 9999.0
var _erros := [0, 0, 0, 0]
var _bn := [0.0, 0.0, 0.0, 0.0]
var _firme := {}                 ## batida -> true (a estação 3, pelo rng)
var _ritmo_do_compasso := {}     ## compasso -> [a, b] (a estação 2)
# ... _nota, _alvo, _verbo, _n, _feita e o que o ouvido da P1 pede
var _robo_ouviu_b := [-9.0, -9.0, -9.0, -9.0]
var _robo_firme := [-1, -1, -1, -1]
var _robo_nota := [-1, -1, -1, -1]
var _robo_tocou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 8.5, 12.5)
	camera_olhar = Vector3(0, 2.5, -2.5)
	# o coração, o dragão (o da Q4, maior), as raias, as peças das estações; gatilhos_off


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)                      # a P1; só casa com nota na estação 4
	_trocar_trecho(b)               # a linha estacao; o R2 em ARMA na 1 e OFF depois; as peças
	_cantar(b)                      # a estação 2: o canto no alto-falante do dono do compasso; o eclipse na TV
	_chamar(b)                      # o final: a chamada no alto-falante de quem responde (e o aviso)
	_distribuir(b)                  # as notas: hoqueto (1, 3, 4), o compasso (2), todos (eclipse), a resposta (final)
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_pedra(l, b)                # a estação 3: a pedra meia batida antes, e o ✕ na neblina
		_entrada(l)                 # pelo verbo; julgar_toque
		_prazo(l)
	_contar_o_acorde(b)             # depois das 32 (ou das 8 extras): cai, levanta ou foge
	if b >= _fim_batida:
		coop_venceu = _caiu
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j] * (2 if _verbo[l] == FINAL else 1))
	if _verbo[l] == FINAL:
		_respostas += 1


func falha(l: int) -> void:
	_erros[l] += 1
	if _verbo[l] == FINAL:
		_respostas += 1
		_faltas_final += 1
	_falha_da_estacao(l)            # o gesto e o efeito do verbo


## Coop: o kit grava vencedor −1 (H08); o destaque é quem errou menos no medley inteiro.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return _erros[a] < _erros[b] or (_erros[a] == _erros[b] and pontos[a] > pontos[b]))
	return int(lista[0]) if not lista.is_empty() else -1
```

`_contar_o_acorde(b)`: quando `_respostas` chega a `RESPOSTAS` (na primeira
vez) ou a `RESPOSTAS + EXTRA * _voltas`: se `_faltas_final <= (FALTAS_MAX if _voltas == 0 else FALTAS_MAX_EXTRA)`
→ `_caiu = true`, a queda do dragão, `_fim_batida = b + 8`; senão, se
`_voltas < VOLTAS_MAX` → `_voltas += 1`, `_faltas_final = 0`,
`_fim_final += 16`, o dragão se levanta (as chamadas continuam); senão →
`_fugiu = true`, o dragão recua na névoa, `_fim_batida = b + 4`.
`_chamar(b)`: no final, nas batidas 0 e 2 de cada compasso, a chamada `r`
para `presentes()[r % np]` (pulando quem está sem controle), o
`Forja.som_falante(l, "nota:%d" % l, 0.8)`, `Forja.sentir(l, "aviso")` e a
`pista` (`canal` `alto_falante`, `o_que` `"chamada"`); a nota de resposta dele
na batida seguinte. `_cantar(b)`: na estação 2, no começo de cada compasso,
sorteia o ritmo com o `rng` e toca as duas notas no alto-falante do dono
(uma vez cada, nas batidas certas), com a `pista`; no eclipse, a frase na TV.

Dica (com `na_raia(l)`): o ícone do verbo da nota aberta, **sempre** —
`["@r2"]`, `["@cross"]` (repetir, sentir, final), `["@mic"]`.
`progresso()`: `"Atire!"`, `"Repita!"`, `"Salte no firme!"`, `"Sopre!"`,
`"O acorde final!"`. `status(l)`: `"%d erros" % _erros[l]` (a da Q4).

Catálogo: `"S09_J45"` em `MINIGAMES` e na seção `S09`. Traduções:
`"O Último Acorde": "The Last Chord"`, `"O acorde final!": "The final chord!"`,
`"Acorde!": "Chord!"`, `"Atire!": "Shoot!"`, `"Repita!": "Repeat!"` (as que
ainda não estiverem lá; `"Salte no firme!"` veio da O2, `"Sopre!"` da P1).

## O que o registro mede

- `estacao` a cada troca (`atirar`, `repetir`, `eclipse`, `sentir`, `soprar`,
  `final`) — a linha da Q4;
- `pista` do canto e da chamada (`canal` `alto_falante`) e da pedra (`canal`
  `haptica`/`rumble`), com a `entrada` `resposta` — no fim da noite, o jogador ainda
  percebe as pistas do controle como no começo?
- `saida` do gatilho de arma, `voz` do sopro, `nota`/`toque` de tudo;
- `troca` (13, H08) `de` `alto_falante` `para` `tv`, `de` `haptica` `para`
  `rumble`, `de` `microfone` `para` `sem_microfone`.

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **O alto-falante não pode tocar dois sons ao mesmo tempo** (05, a agenda):
  o canto (estação 2) e a chamada (final) nunca encostam num som do kit no
  mesmo controle — o kit toca a nota do dono no PERFEITO; as notas do canto
  são nas batidas 0 e 1 do compasso dele, e ele só toca (e acerta) nas 2 e
  3. No final, a chamada é na batida par e a resposta na ímpar: a nota do
  PERFEITO da resposta anterior (batida ímpar) e a chamada seguinte (batida
  par) ficam a uma batida (0,4 s). Não aproxime.
- **O robô só responde se o som chegou** ao alto-falante simulado dele: é o
  que faz o defeito de mentira do alto-falante aparecer no registro (o robô
  erra o "Repetir" e o final). Não tire essa porta.
- **Três papéis de som num minigame só:** o `papel_som` é o microfone (para a
  estação 4 achar o microfone); o alto-falante e a háptica tocam pela placa
  aberta desde a entrada do lugar (H07). O rádio da estação 3 se decide **no
  começo dela**: `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)`
  (com a `troca`); se a háptica não estiver achada com o papel do microfone,
  a pedra vai pelo rumble sozinha, e o registro diz. O do alto-falante, no
  começo da estação 2 (`Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)`).
- **A prova fica mais longa** (até 120 s de relógio): a checagem roda só na
  rodada sem a bancada.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos (o bom derruba o dragão; o ruim faz ele levantar e fugir);
aguenta o cabo que cai e volta; passa pelas quatro estações, o eclipse e o
acorde final sem pausa; fecha com o resultado coop e o destaque, e a noite
segue ao pódio; a prova do jogo passa; e `bash tests/prova_visual.sh` passa
com a prancha olhada (as estações, o dragão caindo na chuva de luz).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_o_ultimo_acorde()`, só na
rodada sem a bancada:

```gdscript
## S09_J45: as estações passam na ordem; o canto da estação 2 sai só no
## alto-falante do dono do compasso; o acorde final tem as 32 respostas; e o
## robô bom derruba o dragão.
func _prova_o_ultimo_acorde() -> void:
	# a espera é a do `_joga_o_minigame` da H08: o aviso em quadros, o jogo pelo
	# relógio de parede (o medley acaba sozinho, com o dragão)
	var canto_privado := [true]
	var viu_canto := [false]
	var olhar := func(s) -> void:
		# só no meio da chamada de cada compasso (0,6 a 1,9): a resposta do
		# dono anterior ainda pode estar soando no começo
		var dentro := fposmod(Ritmo.batida() - 52.0, 4.0)
		if s._verbo_da_vez == s.REPETIR and dentro > 0.6 and dentro < 1.9:
			var tocando := []
			for l in 4:
				if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
					tocando.append(l)
			if tocando.size() == 1:
				viu_canto[0] = true
			elif tocando.size() > 1:
				canto_privado[0] = false
	var sala = await _joga_o_minigame("S09_J45", 160.0, olhar)
	if sala == null:
		return
	_esperar(viu_canto[0] and canto_privado[0], "acorde: o canto sai só no alto-falante do dono")
	_esperar(sala._respostas >= sala.RESPOSTAS, "acorde: as %d respostas (%d)" % [sala.RESPOSTAS, sala._respostas])
	_esperar(sala._caiu, "acorde: o robô bom derrubou o dragão")
```

No `_prova_do_relatorio()`: as linhas `estacao` do
`S09_J45` são seis, e há `pista` com `canal == "alto_falante"` de cada lugar.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --partida=9 --sorteada` até o
fim (O Último Acorde é o fecho): o canto no controle tem de ser
reconhecível e só seu; a pedra na mão ainda tem de ser sentida no fim da
noite; o acorde final tem de soar como a música inteira dividida entre os
quatro; e o dragão caindo tem de parecer o fim de uma noite.

## Ao terminar

- No [quadro](README.md), a linha Q5: **feito**, com o commit.
- Commit sugerido (sem trailer):
  `feat: O Último Acorde — o medley da segunda metade e o acorde dos quatro`
