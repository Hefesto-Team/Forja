# R — O Relâmpago

**Sprint:** R · **Slot:** RELAMPAGO · **Tamanho:** G · **Depende de:** H04, F09, H07, G03, as seções I a Q prontas (os 45 no catálogo), Q4 e Q5 (as estações que se copiam), O2 (a pedra), P1 (o ouvido)

## Por quê

Um modo à parte, no estilo WarioWare: microjogos de 5 a 8 segundos tirados
dos 45, um atrás do outro, sem tela de carregamento, cada vez mais densos.
Cada microjogo é o verbo de uma palavra que a ficha de dados do minigame já
traz (`FICHA.microjogo`). Serve de **aquecimento** no começo da noite (três
vidas) e de **desempate** no fim de uma partida (morte súbita entre os
empatados).

## Ler antes

- [03 — O Relâmpago](../03-os-45-minigames.md#o-relâmpago)
- [O molde de minigame](molde-de-minigame.md) (a chave `microjogo`) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- A [Q4](Q4-ruge-o-reator.md) e a [Q5](Q5-o-ultimo-acorde.md) (as estações —
  bater, equilibrar, traçar, defender, atirar, repetir, sentir, soprar — e os
  robôs delas: esta ficha as copia, cada uma no menor tamanho), a
  [O2](O2-neblina-de-dados.md) (a pedra) e a [P1](P1-a-voz.md) (o ouvido)
- `godot/scripts/partida.gd` (`_acima`, `_criterio`, `podio`) e
  `godot/scripts/ui/escolha_partida.gd`; `godot/scripts/main.gd:380-420`
  (`_comecar_a_partida`, `_placar_da_sala`, `_seguir_a_partida`)

## A ficha de dados

O Relâmpago é um `Minigame` como os outros (o kit dá o relógio, o
julgamento, o registro e o fechamento), fora das seções:

```gdscript
const FICHA := {
	"slot": "RELAMPAGO",
	"titulo": "O Relâmpago",
	"verbo": "Rápido!",
	"genero": "sobrevivencia",
	"icone": "botoes",
	"entradas": [Forja.CRUZ, Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_RELAMPAGO",
	"duracao": 0.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir", "explosao", "aviso"],
	"material": "metal",
	"microjogo": {"verbo": "Rápido!", "segundos": 6.0},
	"gesto": "attack-melee-right",
	"treino": false,
}
```

## Os microjogos, a partir de `FICHA.microjogo`

**O baralho.** No `iniciar_jogo()`, o Relâmpago lê a ficha de cada minigame
do catálogo **sem instanciar** o minigame:

```gdscript
for slot in Catalogo.MINIGAMES:
	if slot == "RELAMPAGO":
		continue
	var f: Dictionary = (Catalogo.MINIGAMES[slot] as Script).get_script_constant_map().get("FICHA", {})
	if f.has("microjogo") and f.has("icone"):
		_baralho.append({"slot": slot, "secao": slot.substr(0, 3), "titulo": f.titulo,
			"verbo": str(f.microjogo.verbo), "segundos": clampf(float(f.microjogo.segundos), 5.0, 8.0),
			"mecanica": MECANICA_DO_ICONE.get(str(f.icone), BATER), "material": str(f.material)})
```

**A ordem:** as cartas de cada seção embaralhadas com o `rng` do kit; as
seções numa ordem embaralhada; e o baralho montado **uma de cada seção por
volta** (a 1ª carta de cada seção, depois a 2ª...), sem duas da mesma seção
em seguida. Três minutos passam pelas nove seções duas vezes.

**A mecânica de cada carta** vem do `icone` da ficha — o recurso do controle
que ela usa —, e o verbo na tela é o do `microjogo` dela:

| `icone` | a mecânica (`MECANICA_DO_ICONE`) | o gesto | de onde se copia |
| --- | --- | --- | --- |
| `botoes` | `BATER` | ✕ em cada nota | a estação 1 da Q4 |
| `analogicos` | `MARCHAR` | o analógico esquerdo para a esquerda (notas pares) e para a direita (ímpares), além de ±0,7 | — (novo: cruzar o limite, como o R2 da Q1) |
| `gatilhos` | `APERTAR` | L2 (pares) e R2 (ímpares) cruzando 0,6 | o pulso da Q2 |
| `giroscopio` | `INCLINAR` | inclinar contra o lado mostrado | a estação 2 da Q4 |
| `touchpad` | `TRACAR` | deslizar para a seta | a estação 3 da Q4 |
| `vibracao` | `DEFENDER` | L1/R1 do lado que a mão sentiu (a pista **meia** batida antes) | a estação 4 da Q4 |
| `gatilho_adaptativo` | `PUXAR` | o R2 em `ARMA` (2, 6, 8) até o clique | a estação 1 da Q5 |
| `alto_falante` | `REPETIR` | o controle canta duas notas; repita no ✕ | a estação 2 da Q5 |
| `haptica` | `SENTIR` | ✕ na pedra, nada na neblina | a estação 3 da Q5 (a O2) |
| `microfone` | `SOPRAR` | a voz no tempo | a estação 4 da Q5 (a P1) |

Todos jogam o mesmo microjogo **ao mesmo tempo** (é individual; não há
hoqueto aqui): cada lugar vivo tem as mesmas notas.

## Como se joga — o fluxo

A faixa é `MUS_RELAMPAGO`, 160 bpm (uma batida = 0,375 s). `ENTRADA := 4`.

**Um microjogo** começa na batida `m0` (o primeiro em `ENTRADA`):

| batidas | o que acontece |
| --- | --- |
| `m0` a `m0 + 1` | **o cartão:** o verbo gigante no meio da tela (o `verbo` do `microjogo`) com o glifo do recurso; as peças da mecânica aparecem (um conjunto por mecânica, já montado no `montar()`: nenhuma carga); `Som.tocar("transicao")` |
| `m0 + 2` a `m0 + 2 + W - 1` | **a janela:** as notas |
| `m0 + 2 + W` | **o resultado:** quem passou faz `emote-yes`, quem não passou `emote-no` e perde uma vida (uma lâmpada da raia apaga) |

- **A janela:** `W = maxi(4, roundi(segundos * 160.0 / 60.0 * fator)) - 3`
  batidas (o cartão e o resultado saem dos segundos da carta), com
  `fator = maxf(0.6, 1.0 - 0.1 * nivel)`.
- **O nível** sobe **a cada cinco microjogos** (`nivel = i / 5`): a janela
  encolhe e as notas se apertam — `ESPACO := [2.0, 1.5, 1.0, 1.0]` batidas
  entre notas pelo nível (o último vale dali em diante). Na subida,
  `Som.tocar("sobe")` e o cartão diz `"Mais rápido!"` antes do verbo.
- **As notas:** `max(2, floor((W - 1) / espaco))` notas, a primeira em
  `m0 + 3`, espaçadas por `espaco`. `REPETIR` é diferente: o canto nas duas
  primeiras batidas da janela, a resposta nas duas seguintes (duas notas;
  as batidas que sobram ficam vazias). `SENTIR`: cada batida de nota tem
  pedra com 60% (o `rng`); as notas são só as de pedra.
- **O julgamento:** o do kit, `julgar_toque(l, t(bn), n)`; o erro de cada
  mecânica é o da estação de origem (o lado errado, a direção errada, o ✕ na
  neblina).
- **Passar:** o lugar passa o microjogo se acertou (sem erro) pelo menos
  `ceil(0.6 * notas)` notas. Não passou: perde uma vida — **a não ser que
  todos os vivos tenham falhado o mesmo microjogo**: aí ninguém perde (é
  justo com o microjogo impossível).
- **As vidas:** `VIDAS := 3` no aquecimento, `1` no desempate. Sem vidas, o
  lugar sai (`acabou[l] = true`), o boneco senta (`sit`) na raia, e assiste.
- **O próximo microjogo** começa na batida seguinte ao resultado: sem pausa,
  sem cortina, a música nunca para.

## O aquecimento e o desempate

Quem abre o Relâmpago diz o modo por **uma** variável estática da `Partida`
(que tem `class_name`: o acesso é certo, sem depender de estática num script
sem nome): `static var relampago_desempate: Array = []` — vazia é o
**aquecimento**; com lugares, é o **desempate** entre eles. O Relâmpago a lê
no `iniciar_jogo()` (copia para `_so` e esvazia a da `Partida`, para o
próximo não herdar).

- **O aquecimento:** na escolha da partida (`ui/escolha_partida.gd`), a linha
  "Salas" ganha a primeira opção `[0, "Relâmpago", "uns 3 min"]` em
  `TAMANHOS`; `confirmar()` com `n == 0` emite `escolheu(0, sorteada)`, e
  `main._comecar_a_partida(0, ...)` faz `partida = null` (senão a volta do
  Relâmpago cairia no placar de uma partida velha),
  `Partida.relampago_desempate = []` e `_entrar_na_sala("RELAMPAGO", com_cortina)`. Também
  por `--sala=relampago` (o catálogo: `NOMES_VELHOS["relampago"] = "RELAMPAGO"`).
  O teto é `FIM_AQUECIMENTO := ENTRADA + 480` batidas (3 min): quem ainda
  está vivo ali, fica — a colocação é pelas vidas.
- **O desempate:** em `main._seguir_a_partida()`, quando `partida.acabou()`:
  se `partida.empate_no_topo()` (novo: os dois primeiros do `podio` com o
  mesmo `total`) e `partida.desempate < 0`,
  `Partida.relampago_desempate = partida.empatados_no_topo()` (novo) e
  `_entrar_na_sala("RELAMPAGO")`. No `iniciar_jogo()`, quem não está em `_so`
  sai de jogo (`jogando[l] = false`: assiste). Na volta
  (`_ao_terminar_a_sala`, com `sala_id == "RELAMPAGO"` e a partida acabada):
  **não** registra na partida (a guarda vai antes do `_placar_da_sala`);
  `partida.desempate = (sala as SalaJogo).colocacao[0]` e vai ao pódio.
- **Na `Partida`** (`godot/scripts/partida.gd`): `static var relampago_desempate: Array = []`,
  `var desempate := -1`; em `_acima(a, b)`, logo depois da comparação de
  `total`: `if desempate >= 0 and (a == desempate or b == desempate): return a == desempate`;
  em `_criterio`, o mesmo lugar devolve `"o Relâmpago"`. As duas funções
  novas, `empate_no_topo()` e `empatados_no_topo()`, pelo `podio` (os lugares
  com o `total` do primeiro). Acrescente ao 13 (a seção do kit): o
  `RELAMPAGO` no catálogo, e o `relampago_desempate` e o `desempate` da
  `Partida`.

## O cenário

- **O palco do relâmpago:** `Kit.arena(self, 5, 3)`; a luz da casa com um
  pulso: `luzes([Vector3(-9, 3, 3), Vector3(9, 3, 3)])`,
  `atmosfera(Color("#f1fa8c"), Tema.CIANO, true, 60, 22.0, -7.8, 0.35)`; a
  cada cartão, `pulso_de_luz(Tema.AMARELO, 1.2)`.
- **As raias:** `raia(l)` e `posicionar(l)` do kit (de frente); três lâmpadas
  de vida por raia (`Kit.caixa(self, Vector3(0.3, 0.3, 0.3), ...)` em fila
  diante do boneco, emissivas `#f1fa8c` acesas, apagadas `#3b3345` — é a
  runa da vida; nunca a barra de luz nem as luzinhas).
- **Os conjuntos de peças**, um por mecânica, montados todos no `montar()` e
  escondidos (`visible = false`); o cartão mostra o da vez: a bigorna de cada
  raia (`BATER`); a trilha de lajes (`MARCHAR`); a bateria da Q2 (`APERTAR`);
  a plataforma que inclina (`INCLINAR`); a runa da seta (`TRACAR`); a garra
  (`DEFENDER`); os alvos de 8 lados (`PUXAR`); nada além do boneco
  (`REPETIR`); a laje de pedra no escuro (`SENTIR`); o braseiro (`SOPRAR`).
- **O cartão:** o verbo é **texto de tela** (passa por `Traducoes`, começa
  com maiúscula, `Tema.fonte(800)`, tamanho de título, no centro, por duas
  batidas), desenhado pelo painel da sala: o minigame o expõe em
  `progresso()` (`"Mais rápido! · Bata!"` no nível novo, só `"Bata!"` no
  resto) — a G04 e o painel já mostram o `progresso()` no alto.
- **A câmera:** `camera_pos = Vector3(0, 6.5, 11.0)`, `camera_olhar = Vector3(0, 1.0, -1.0)`.
- **Checklist de arte (11):** as peças são as das estações da Q4/Q5 (já
  aprovadas); as lâmpadas de vida são runas (emissivo com trabalho); nada nas
  cores dos lugares.

## O repertório

Cada mecânica traz o repertório da estação de onde veio (o gatilho de
`PUXAR`, a pista de `DEFENDER`, o canto de `REPETIR`, a pedra de `SENTIR`, o
microfone de `SOPRAR`), com o mesmo caminho no rádio e com o mesmo "sozinho"
sem microfone (a nota de `SOPRAR` passa sozinha para quem não tem
microfone: é a régua, lição 16). Além disso:

| recurso | o quê | quando |
| --- | --- | --- |
| vibração | perdeu uma vida: `Forja.sentir(l, "golpe")`; saiu: `explosao` | no resultado |
| alto-falante do dono | passou: `Forja.som_falante(l, "coleta", 0.7)`; perdeu vida: `nota_quebrada:<l>` | no resultado |
| barra de luz, luzinhas | do lugar, sempre | — |
| TV | a música a 160; `Som.tocar("transicao")` no cartão; `Som.tocar("sobe")` no nível; `Som.tocar("vitoria_noite")` no fim | — |

`papel_som` é `Forja.PAPEL_MICROFONE` (para `SOPRAR` achar o microfone); a
háptica e o alto-falante tocam pela placa aberta (H07), e o rádio de cada
mecânica se decide **no cartão dela** (`Forja.som_tem(l, ...)`), com a
`troca`. `usa_gatilho = true` (as mecânicas `APERTAR` e `PUXAR` usam o L2 e o
R2); no cartão de toda mecânica que não usa gatilho, `Forja.gatilhos_off(l)`.

## A falha

Errar uma nota não tem falha própria (é rápido demais): o boneco faz o gesto
de erro da estação de origem e segue. **A falha é perder a vida** no
resultado: a lâmpada estoura (faíscas `#f1fa8c`), o boneco cai sentado e
levanta (`fall`, 0,5 s). Sem vidas: o boneco senta e fica (`sit`).

## O fim e o vencedor

- **Com dois ou mais:** quando sobra um vivo, ele vence, e o Relâmpago acaba
  no resultado daquele microjogo (todos `acabou`). No aquecimento, também na
  batida `FIM_AQUECIMENTO`.
- **Com um:** até perder as vidas (ou o teto): o vencedor é ele; a tela diz
  quantos microjogos ele passou (`status`).
- `vencedor()`: os vivos pelas vidas, depois pelos microjogos passados
  (`_passados[l]`), depois pelos pontos; depois os que saíram, do último a
  sair ao primeiro.

## Com menos de quatro

- **3, 2:** nada muda. **1:** ver acima. **O desempate:** só os empatados
  jogam; os outros assistem sentados na raia.
- **O controle que cai:** o lugar sem controle **não perde vida** nos
  microjogos em que esteve fora (não passou, mas não falhou); volta no
  próximo cartão.

## O robô

O robô de cada mecânica é o da estação de origem, copiado (a Q4 para bater,
equilibrar, traçar e defender; a Q5 para puxar, repetir, sentir e soprar),
mais dois pequenos, **sempre** com a primeira linha `if not Forja.robo: return`
e o temperamento por nota (`Forja.robo_acerta()` quando a nota muda):

```gdscript
		MARCHAR:
			var lado := (-1.0 if n % 2 == 0 else 1.0) * (1.0 if _robo_certo[l] else -1.0)
			Forja.robo_eixo(l, Forja.LX, lado, 0.08)
			_robo_feito[l] = true
		APERTAR:
			var eixo := Forja.L2 if n % 2 == 0 else Forja.R2
			if not _robo_certo[l]:
				eixo = Forja.R2 if eixo == Forja.L2 else Forja.L2
			Forja.robo_eixo(l, eixo, 1.0, 0.08)
			_robo_feito[l] = true
```

(Dentro do mesmo `match` do robô da Q4, depois de `if Ritmo.t_musica() < quando - _antecipa(...): return`.)

## Os ganchos

`godot/scripts/minigames/relampago.gd`, `extends Minigame`, sem `class_name`.

```gdscript
extends Minigame
## O Relâmpago (RELAMPAGO). Microjogos de 5 a 8 segundos tirados dos 45, um
## atrás do outro, sem pausa na música: o verbo de cada um é o do `microjogo`
## da ficha dele, e a mecânica é a do recurso que ele usa (o `icone`). A cada
## cinco, mais denso. Três vidas no aquecimento; uma no desempate.
##
## A falha: perder a vida no resultado do microjogo. O vencedor: o último
## vivo. O alto-falante do dono: a coleta ao passar. O registro mede: cada
## microjogo (estacao, com o slot de origem) e o desvio de cada recurso sob
## pressa. O robô: o das estações da Q4 e da Q5. Com menos de quatro: nada
## muda; no desempate, só os empatados. A régua: o cartão é o verbo e o
## glifo; nada pergunta nada.

const FICHA := { ... }

enum { BATER, MARCHAR, APERTAR, INCLINAR, TRACAR, DEFENDER, PUXAR, REPETIR, SENTIR, SOPRAR }
const MECANICA_DO_ICONE := {
	"botoes": BATER, "analogicos": MARCHAR, "gatilhos": APERTAR, "giroscopio": INCLINAR,
	"touchpad": TRACAR, "vibracao": DEFENDER, "gatilho_adaptativo": PUXAR, "alto_falante": REPETIR,
	"haptica": SENTIR, "microfone": SOPRAR,
}
const ENTRADA := 4
const CARTAO := 2
const ESPACO := [2.0, 1.5, 1.0, 1.0]
const PASSA := 0.6
const FIM_AQUECIMENTO := ENTRADA + 480
const PONTOS := [0, 50, 75, 100]

var _desempate := false          ## o modo, lido da Partida no iniciar_jogo
var _so: Array = []               ## no desempate: quem joga

var _baralho: Array = []
var _i := -1                     ## o microjogo da vez
var _carta := {}
var _m0 := float(ENTRADA)
var _janela := 0
var _notas_da_vez: Array = []    ## as batidas das notas do microjogo
var _acertos := [0, 0, 0, 0]     ## no microjogo da vez
var _vidas := [3, 3, 3, 3]
var _passados := [0, 0, 0, 0]
var _saiu_em := [-1.0, -1.0, -1.0, -1.0]
var _esteve_fora := [false, false, false, false]
var _pecas := {}                 ## mecânica -> Node3D (o conjunto)
# ... e o que as estações copiadas pedem (_nota, _alvo, _n, o ouvido, a pedra, a seta, o lado...)


func montar() -> void:
	papel_som = Forja.PAPEL_MICROFONE
	usa_gatilho = true
	camera_pos = Vector3(0, 6.5, 11.0)
	camera_olhar = Vector3(0, 1.0, -1.0)
	# o palco, as raias com as lâmpadas, os dez conjuntos de peças (escondidos)


func iniciar_jogo() -> void:
	_montar_baralho()            # ver "Os microjogos"
	_so = Partida.relampago_desempate.duplicate()
	Partida.relampago_desempate = []
	_desempate = not _so.is_empty()
	for l in presentes():
		_vidas[l] = 1 if _desempate else 3
		if _desempate and not l in _so:
			jogando[l] = false   # assiste
	_proximo_microjogo(float(ENTRADA))


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)                   # a P1 (só casa com nota em SOPRAR)
	_pistas_da_mecanica(b)       # a garra (DEFENDER), a pedra (SENTIR), o canto (REPETIR), na hora
	for l in presentes():
		if acabou[l]:
			continue
		if not conectado(l):
			_esteve_fora[l] = true
			_nota[l] = -1
			continue
		_entrada(l)              # pelo gesto da mecânica; julgar_toque
		_prazo(l)                # a nota que passou
	if b >= _m0 + CARTAO + _janela:
		_resultado(b)            # passou / perdeu vida (a regra "todos falharam"), quem saiu, o fim
		if not _acabou_tudo():
			_proximo_microjogo(_m0 + CARTAO + _janela + 1.0)
	if not _desempate and b >= FIM_AQUECIMENTO:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_acertos[l] += 1


func falha(l: int) -> void:
	_gesto_de_erro(l)            # o da estação de origem, sem mais nada


func vencedor() -> Array:
	var vivos := presentes().filter(func(l): return _vidas[l] > 0)
	vivos.sort_custom(func(a, b):
		if _vidas[a] != _vidas[b]:
			return _vidas[a] > _vidas[b]
		if _passados[a] != _passados[b]:
			return _passados[a] > _passados[b]
		return pontos[a] > pontos[b])
	var fora := presentes().filter(func(l): return _vidas[l] <= 0)
	fora.sort_custom(func(a, b): return _saiu_em[a] > _saiu_em[b])
	return vivos + fora


func progresso() -> String:
	if _carta.is_empty():
		return ""
	var v := str(_carta.verbo)
	# os dois pedaços traduzidos aqui: a frase junta não é chave de Traducoes
	return (Traducoes.traduzir("Mais rápido!") + " · " + Traducoes.traduzir(v)) if _i > 0 and _i % 5 == 0 else v
```

`_proximo_microjogo(m0)`: `_i += 1`; a carta `_baralho[_i % _baralho.size()]`;
`_m0 = m0`; o nível; `_janela`; as notas (`_notas_da_vez`); os `_acertos` a
zero, `_esteve_fora` a falso; o conjunto de peças da mecânica visível (os
outros não); o gatilho da mecânica (`ARMA` no R2 em `PUXAR`, soltos no
resto); o rádio da mecânica (`_rumble[l]`, com a `troca`); a linha
`Forja.evento("estacao", 0, {"slot": id, "estacao": str(_carta.slot), "batida": m0})`;
e abre as notas de cada lugar vivo uma batida antes de cada uma (pelo
`_distribuir` da Q4, sem hoqueto). `_resultado(b)`: para cada vivo
conectado o microjogo todo, passou = `_acertos[l] >= ceili(PASSA * notas)`;
se todos os vivos falharam, ninguém perde; senão, cada um que falhou perde
uma vida (a lâmpada, o golpe, a nota quebrada) e, em zero, sai
(`acabou[l] = true`, `_saiu_em[l] = b`); quem passou, `_passados[l] += 1` e
a coleta. `_acabou_tudo()`: com dois ou mais no começo, sobra um ou nenhum
vivo → todos `acabou`; com um, ele sem vidas. `status(l)`:
`"%d vidas" % _vidas[l]` (a da O4) ou, sem vidas, `"%d passados" % _passados[l]`.

**O catálogo:** `"RELAMPAGO": preload("res://scripts/minigames/relampago.gd")`
em `MINIGAMES` (fora de `SECOES`), `"relampago": "RELAMPAGO"` em
`NOMES_VELHOS`. A prova do catálogo da H04 confere a FICHA dele como a dos
outros. Traduções (o `progresso()` junta dois textos já traduzidos, então
não há frase com `%s`): `"O Relâmpago": "Lightning Round"`, `"Rápido!": "Quick!"`,
`"Mais rápido!": "Faster!"`, `"Relâmpago": "Lightning"`,
`"uns 3 min": "about 3 min"`, `"%d passados": "%d cleared"`, e `"o Relâmpago"`
(o critério do pódio): `"the Lightning Round"`.

## O que o registro mede

- `estacao` a cada microjogo, com o **slot de origem** (`S03_J12`...): a
  noite vê o desvio de cada recurso sob pressa, no aquecimento (o começo da
  noite) e no desempate (o fim) — é a régua do cansaço;
- `nota`/`toque` de cada nota, `pista`/`troca` das mecânicas que as têm;
- o `minigame` `terminou` com o vencedor (o kit).

## Armadilhas

- **A carta não instancia o minigame.** `get_script_constant_map()` no
  `Script` do catálogo lê a `FICHA` sem criar o nó (criar 45 salas travaria
  o quadro e abriria a placa de som de cada uma).
- **O modo mora na `Partida`** (`Partida.relampago_desempate`), não no
  Relâmpago: minigame não tem `class_name`, e a estática de um script sem
  nome não é um caminho que o projeto use. O Relâmpago esvazia a variável ao
  ler, para o próximo não herdar.
- **O desempate não entra na partida:** `_placar_da_sala` não pode registrar
  o Relâmpago (a guarda: `sala_id == "RELAMPAGO"`).
- **Rumble e háptica nunca juntos:** a pista de `DEFENDER` sai **meia**
  batida antes (a 160 bpm, uma batida antes cairia no acerto da nota
  anterior); a pedra de `SENTIR` também (0,19 s).
- **As mecânicas de gatilho:** `usa_gatilho = true`, e o L2 volta a `OFF` no
  cartão de toda mecânica que não o usa.
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Três minutos de Relâmpago passam por microjogos das nove seções sem tela de
carregamento e sem a música parar; o nível sobe a cada cinco; o aquecimento
(3 vidas) e o desempate (1 vida, só os empatados) funcionam; uma partida de 3
com empate no topo termina no Relâmpago e o pódio diz "o Relâmpago" como
critério; joga com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos;
aguenta o cabo que cai; a prova do jogo passa; e `bash tests/prova_visual.sh`
passa com a prancha olhada (os cartões trocando, as lâmpadas apagando).

## Provas

Em `godot/testes/prova_do_jogo.gd`:

1. **`_prova_do_relampago()`** (só na rodada sem a bancada): abre com
   `--sala=relampago` pelo catálogo, espera **dez microjogos** (pelo `_i`,
   com o relógio de parede, limite 120 s), confere que eles vieram de pelo
   menos seis seções diferentes e sem duas iguais em seguida, e que a música
   não parou (`Ritmo.t_musica()` sempre subindo); depois **desiste pela
   pausa** — o mesmo caminho do jogador, o que a `_prova_de_fogo` já usa —
   e confere a volta ao salão.

   ```gdscript
   func _prova_do_relampago() -> void:
   	var sala = await _comeca_a_sala("relampago")
   	if sala == null:
   		return
   	var secoes: Array = []
   	var ultima := ""
   	var repetiu := false
   	var visto := -1
   	var t_antes := -1.0
   	var parou := false
   	var inicio := Time.get_ticks_usec()
   	while is_instance_valid(sala) and sala._i < 10 and sala.fase == "jogo" and Time.get_ticks_usec() - inicio < 120000000:
   		if sala._i != visto and not sala._carta.is_empty():
   			visto = sala._i
   			var s := str(sala._carta.secao)
   			repetiu = repetiu or s == ultima
   			ultima = s
   			if not s in secoes:
   				secoes.append(s)
   		var tm := Ritmo.t_musica()
   		parou = parou or tm < t_antes
   		t_antes = tm
   		await _quadros(1)
   	_esperar(secoes.size() >= 6, "relâmpago: dez microjogos de %d seções (%s)" % [secoes.size(), secoes])
   	_esperar(not repetiu, "relâmpago: nunca dois da mesma seção em seguida")
   	_esperar(not parou, "relâmpago: a música não voltou nem parou")
   	# a desistência pela pausa (o mesmo da _prova_de_fogo)
   	jogo._na_pausa("salao")
   	var q := 0
   	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
   		await _quadros(2)
   		q += 2
   	_esperar(jogo.estado == "salao", "relâmpago: pela pausa, desiste e volta ao salão")
   ```

2. **`_prova_das_contas_da_partida()`** (a que já existe, pura): uma partida
   com dois lugares empatados no `total` tem `empate_no_topo()`; com
   `desempate` posto, o `podio` põe o desempatado em cima e o `_criterio`
   diz `"o Relâmpago"`.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=relampago` (três rodadas
de aquecimento) e uma partida de 3 até empatar (`--partida=3`): o cartão tem
de ser lido em meio segundo; cada mecânica tem de ser reconhecida pelo
glifo; a aceleração tem de ser sentida; o desempate tem de dar frio na
barriga.

## Ao terminar

- No [quadro](README.md), a linha R: **feito**, com o commit
  (e o tamanho G desta ficha, no lugar do de antes).
- Commit sugerido (sem trailer):
  `feat: O Relâmpago — os 45 em microjogos, o aquecimento e o desempate`
