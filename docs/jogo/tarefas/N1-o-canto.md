# N1 — O Canto

**Sprint:** N · **Slot:** S06_J26 · **Tamanho:** G · **Depende de:** H04, H06, H07, H08, F01, F02, F04, F05, F09, G03, G05, G08, G10, G14, G15

## Por quê

O Canto de hoje (`godot/scripts/salas/canto.gd`) pergunta «o canto saiu do seu controle?», a pergunta que a regra
de ouro 1 proíbe fora da bancada. O Canto novo é chamada e resposta em hoqueto, no tempo da faixa: a frase sai só do
alto-falante da sua mão, e a sua resposta toca na TV, no timbre do seu sino, para a sala ouvir quem desafinou. É o
primeiro minigame da seção: muda a sala para o kit e cria o cenário comum que N2 a N5 usam.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`godot/scripts/salas/canto.gd`](../../../godot/scripts/salas/canto.gd) (inteiro: esta ficha o desmonta)
- [O Modo bancada, no 13](../13-arquitetura.md#o-modo-bancada--f01) (o canto às cegas fica só nele)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s06/o_canto.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/s06/cenario_do_canto.gd` | novo: o cenário comum da seção | **da seção**: a N1 cria; N2 a N5 só chamam (nenhuma o reescreve) |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO`, a função `momento()` e a chave `nota_na_tv` | **de todos**: o que outra ficha já pôs, não escreva de novo |
| `godot/scripts/minigames/catalogo.gd` | `S06_J26` em `MINIGAMES` e em `SECOES`; sai `"canto"` de `SALAS_ANTIGAS` | **da seção**: N2 a N5 acrescentam uma linha cada |
| `godot/scripts/traducoes.gd` | `"O Canto": "The Chant"`, `"Repita!": "Repeat!"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_canto()`, a linha `"S06_J26", "canto": await _prova_do_canto()` no `match` do `_prova_da_ficha` (H08) e a mesa da prova (`ERRO_DA_MESA`, `_mesa_comeca`, `_mesa`), que N2 a N5 usam | **de todos**: N2 a N5 acrescentam uma linha cada no `match` |
| `docs/jogo/13-arquitetura.md` | a linha `momento` em «Os eventos do jogo»; a linha `nota_na_tv` em «As chaves opcionais novas da FICHA» | **de todos**: a linha que já existe, não escreva de novo |
| `docs/jogo/tarefas/molde-de-minigame.md` | a linha `nota_na_tv` na tabela das chaves opcionais | **de todos** |
| `scripts/importar_kenney.py` | a linha `fantasy-town-kit` em `APROVADOS` (papel `cenario`, filtro tudo) | **de todos**: N3 usa a mesma linha |
| `godot/assets/kenney/fantasy-town-kit/`, `godot/assets/LEIA-ME.md`, `LICENCAS-DE-TERCEIROS.md` | o que o import escreve | **de todos** |
| `godot/scripts/salas/canto.gd` e `.uid` | `git rm` | só desta |

Antes de tudo: `python3 scripts/importar_kenney.py fantasy-town-kit` (do All-in-1 em `oficina/kenney/`, a versão
mais nova). O `castle-kit` a G10 já trouxe. Os dois `.uid` novos (`o_canto.gd.uid`, `cenario_do_canto.gd.uid`) saem
do import: `"$GODOT" --headless --path godot --import --quit`, e entram no commit.

### O que muda de hoje

Hoje o Canto é uma prova às cegas: a bigorna canta um ritmo num controle ou na TV, todos respondem «foi no meu?», e o
dono repete. O Canto novo tem a chamada na vez de cada um (o hoqueto) só no alto-falante do controle dele, a resposta
no compasso seguinte com ✕ (grave) e ○ (agudo), a resposta tocando na TV, o sino que racha e cai, e o uníssono na
reta. A pergunta de hoje fica só no Modo bancada, onde ela mede o veredito `alto_falante`.

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; raia(l) -> Node3D; jogador(l)
posicionar(l)                                   # põe o boneco na raia, de mãos livres
nova_nota(l, n, t_alvo, perigo := false); notas_em_aberto(l) -> Array; alvo_da(l, n) -> float
casar_toque(l) -> int                           # a nota em aberto mais perto do toque (ALCANCE_DO_TOQUE 0,5 s), -1: nenhuma
julgar_nota(l, n) -> int                        # julga o toque de agora contra a nota n; chama toque() ou falha()
nota_perdida(l, n); notas_perdidas(l) -> Array  # sem controle, as notas que passaram saem caladas
anotar(tipo, l, campos := {}); andamento() -> float (0..1); no_pico() -> bool; marcar(l, pontos)
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]; const BATIDA_DA_PRIMEIRA_NOTA := 4
var j := {}; var n := {}; var rng; var treinando; var jogadores; var pontos; var _raias  # lugar -> {raiz, mat_borda, luz}
```

**A fila de notas é do kit.** O kit já declara `var _notas := [{}, {}, {}, {}]` (`lugar -> {n: [t_alvo, perigo]}`):
esta ficha **não** declara `_notas`. O dado próprio de cada nota (a altura, a frase) mora em
`_info := [{}, {}, {}, {}]` (`lugar -> {n: {...}}`), e antes de `julgar_nota` ou `nota_perdida` a nota vai para
`_ultima[l]` (o `toque` e a `falha` a leem, porque o kit os chama de dentro).

Do `Forja` e do `Ritmo`: `Forja.sentir(l, nome, ms := -1)` (F05: `acerto`, `perfeito`, `erro`, `golpe`),
`Forja.gatilho(l, lado, modo, a, b)` (lado 1 = R2), `Forja.gatilhos_off(l)`, `Forja.luz(l, cor)`,
`Forja.cor_do_lugar(l)`, `Forja.som_tem(l, papel)`, `Forja.som_falante(l, som, ganho) -> int`,
`Forja.som_virtual(l)` (`falante`, `som`, `som_seq`), `Forja.robo_apertar(l, botao, s)`, `Forja.robo_acerta()`,
`Forja.apertou(l, botao)`, `Ritmo.t_musica()`, `Ritmo.batida()`, `Ritmo.t_da_batida(b)`, `Ritmo.bpm`,
`Ritmo.simples[l]`, `Ritmo.desvio[l]`, `Ritmo.PERFEITO`. Do G03: `Itens.antecipacao_s(l, bpm)` (a Lanterna).

### A função `momento` (em `minigame.gd`, de todos)

O tipo `momento` é o da [régua da diversão](../diversao/README.md#4-um-momento-de-grito-com-nome). Se a L1 já o
acrescentou, pule esta parte. Senão: em `TIPOS_DO_JOGO`, acrescente `"momento"` ao fim da lista e, ao fim do arquivo:

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
`| \`momento\` | o momento de grito do minigame: \`nome\`, \`t_musica\`, \`x_tela\` e \`altura_tela\` (0 a 1); \`jogador\` 0, sem \`lugar\`, quando é de todos (docs/jogo/diversao/README.md) |`.

### A chave `nota_na_tv` (em `minigame.gd`, de todos)

O kit toca, em todo acerto, `Som.tocar("nota", pos, -4 ou -9, TOM_DO_LUGAR[l])` na TV. O Canto toca a sua própria nota
na TV (com a altura), então desliga a do kit:

- ao lado de `var _textura_no_acerto := true`: `var _nota_na_tv := true`;
- no `_init`, ao lado das outras chaves: `_nota_na_tv = bool(ficha.get("nota_na_tv", true))`;
- no `_reagir`, a linha `Som.tocar("nota", pos, -4.0 if perfeito else -9.0, TOM_DO_LUGAR[l])` passa a
  `if _nota_na_tv:` com ela dentro.

No 13, na tabela «As chaves opcionais novas da FICHA», depois de `textura_no_acerto`, e na mesma tabela do
molde: `| \`nota_na_tv\` | \`false\`: o kit não toca a nota do acerto na TV (quando o minigame toca a sua) | toca |`.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## O Canto (S06_J26) — chamada e resposta em hoqueto, no tempo da faixa. Os
## compassos ímpares são a chamada: na vez de cada um, o alto-falante do
## controle dele canta a frase (uma nota, ou duas no pico), cada nota grave ou
## aguda. O compasso seguinte é a resposta: na mesma vez, ✕ na grave, ○ na
## aguda, no tempo de cada nota. A resposta toca na TV no timbre do sino dele.
##
## A falha: a nota sai desafinada na TV e o sino racha (uma trinca por erro);
## a terceira trinca derruba o sino, que rola no chão até a próxima frase inteira.
## O vencedor: mais frases inteiras; no empate, mais pontos.
## O alto-falante do dono: a chamada (o segredo). Nada mais toca nele.
## O registro mede: cada chamada (o som, se saiu do controle), a resposta (o
## toque do kit com o mesmo n) e os momentos `sino_torto` e `reta`.
## O robô: ouve o alto-falante simulado dele e responde só as notas que ouviu,
## com a altura que ouviu; quando não acerta, aperta a outra altura.
## Com menos de quatro: dois têm as vezes 0 e 2; sozinho, as vezes 0 e 2 são dele.
## A régua: (1) «Repita!» com o sino que balança na vez; (2) sim: a frase está
## só no controle; (3) não pergunta nada (a pergunta de hoje, só na bancada).

const FICHA := {
	"slot": "S06_J26",
	"titulo": "O Canto",
	"verbo": "Repita!",
	"genero": "tct",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ, Forja.CIRCULO],
	"camera": "fixa",
	"faixa": "MUS_S06_J26",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Repita!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca nada nele (H08)
	"nota_na_tv": false,  # o Canto toca a nota da resposta na TV, com a altura
	"papel_som": Forja.PAPEL_ALTO_FALANTE,  # a bancada afina o alto-falante no aviso (F02)
	# o que a bancada mede (o veredito é do núcleo, como hoje)
	"features": ["alto_falante"],
	"botoes_medidos": [Forja.CRUZ, Forja.CIRCULO],
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const FRASE_INTEIRA := 50
const GRAVE := 0
const AGUDA := 1
const SOM := ["nota", "nota_alta"]  ## GRAVE, AGUDA: o som da chamada no alto-falante
const BOTAO := [Forja.CRUZ, Forja.CIRCULO]  ## GRAVE, AGUDA
## A resposta na TV: o tom do lugar vezes a altura (a aguda, uma quinta acima).
const ALTURA_TOM := [1.0, 1.4983]
const DESAFINADO := 0.9659  ## um semitom abaixo: a nota errada e o sino caído
const TRINCAS_MAX := 3
const PULSO_S := 0.12  ## a barra de luz a 60 % no acerto BOM e ÓTIMO
## A chance de a frase ter duas notas (a segunda meia batida depois), por terço.
const DUAS_NOTAS := [0.0, 1.0, 1.0]
const RETA_BATIDAS := 16  ## a chamada cuja resposta cai nelas é o uníssono
const AROS_MAX := 30
const SINO_ALTURA_M := 1.9  ## o momento mede do chão ao braço do suporte
## A bancada: o canto às cegas na chamada c com c % 6 == 3 (3, 9, 15, 21, 27, 33).
const BANCADA_A_CADA := 6
const BANCADA_DESLOC := 3
```

Do `canto.gd` de hoje continuam, **iguais**, para a bancada: `TV`, `NOTAS`, `INTERVALOS`, `PERGUNTA_MAX`,
`REVELA_S` (linhas 24-29). Saem: `F` (use `Forja`), `RAIAS` e `Z_JOGADOR` (são do kit), `REPETE_MAX`,
`FOLGA_RITMO`, `SINO_TV` e `PERFIL` (vão para o cenário comum), e os estados `PREPARO`, `REPETE` e `ACABOU`.

### O tempo

A faixa `MUS_S06_J26` tem 110 BPM: 1 batida = 0,545 s, 1 compasso = 2,18 s. Em 90 s, `_b_fim =
floor(duracao * Ritmo.bpm / 60.0)` = 165 batidas. O compasso `c` tem as batidas `4c` a `4c+3`; o compasso 0 é a
contagem de entrada (H06). O pico (`no_pico()`, de 30 a 60 s) começa no compasso 14 (batida 56). A reta são as
últimas 16 batidas: da 149 à 164.

### As vezes (o hoqueto)

`lista = presentes()` em ordem crescente, `k = lista.size()`. A vez de `lista[i]` no compasso é a batida (desde `4c`):

| quantos | as vezes |
| --- | --- |
| 4 ou 3 | `i` (P1 na 0, P2 na 1, P3 na 2, P4 na 3) |
| 2 | `2i` (0 e 2) |
| 1 | 0 **e** 2: duas frases por chamada, as duas dele |

### A chamada e a resposta

Os compassos ímpares (1, 3, 5 … 39) são a **chamada**; o par seguinte é a **resposta** dela. A chamada `c` só existe
se a resposta cabe na faixa (`4 * (c + 1) + 3 < _b_fim`): a última é a 39. O compasso se gera quando
`Ritmo.batida() >= 4c − 4` (`_gerar_compasso`); a chamada gera também as notas da resposta.

**A frase** de cada vez `v`: a primeira nota em `b = 4c + v`, a altura sorteada pelo `rng` (`GRAVE` ou `AGUDA`). A
parte é a do tempo da chamada (`Ritmo.t_da_batida(4c)`: menos de 30 s, a 0; menos de 60 s, a 1; senão, a 2); com a
chance `DUAS_NOTAS[parte]`, uma segunda nota em `b + 0,5`, com altura sorteada. Quem está com `Ritmo.simples[l]`
tem sempre uma nota. Cada nota da chamada gera a nota da resposta **um compasso depois**, em `b + 4`:
`n = int(round((b + 4) * 2))`, `_info[l][n] = {"b": b + 4, "altura": a, "frase": id}` e
`nova_nota(l, n, Ritmo.t_da_batida(b + 4))`.

| terço | música | a frase | o que acontece |
| --- | --- | --- | --- |
| 1. ensina | 0–30 s | uma nota | aprende-se a altura; o botão aceso sobre o sino na primeira resposta |
| 2. **o pico** | 30–60 s | duas notas, em colcheia | altura e ritmo; o sino grande toca três vezes no compasso 14 |
| 3. a reta | 60–90 s | duas notas, em colcheia | nas últimas 16 batidas, **o uníssono** |

**A chamada toca** quando `Ritmo.t_musica() >= Ritmo.t_da_batida(b) - CenarioDoCanto.antecedencia(l)` (o Faro e a
Lanterna adiantam a chamada; a resposta fica no tempo): `var foi := CenarioDoCanto.falante(self, l, SOM[a], 0.9)` e
`anotar("pista", l, {"n": n_da_resposta, "evento": "mandou", "canal": "alto_falante", "o_que": SOM[a], "no_controle": foi})`.
O sino pequeno do lugar balança por 1 batida (`CenarioDoCanto.balancar(sino, 1.0)`), igual para as duas alturas: a
tela diz de quem é a vez, nunca a altura. Quem está sem controle não tem a chamada tocada.

**A resposta:** ✕ é a grave, ○ a aguda. `var n := casar_toque(l)`; com `n < 0`, nada. Senão,
`_ultima[l] = _info[l][n]` e: o botão da altura certa → `julgar_nota(l, n)`; o botão da outra altura →
`nota_perdida(l, n)` (desafinou). A nota que passa de `FOLGA_PERDIDA` (0,14 s, já sem a calibração) sem toque vira
`nota_perdida(l, n)` pelo `_passaram(l)`:

```gdscript
func _passaram(l: int) -> void:
	var agora := Ritmo.t_musica() - float(Ritmo.desvio[l])
	for nn in notas_em_aberto(l):
		if agora > alvo_da(l, nn) + FOLGA_PERDIDA:
			_ultima[l] = _info[l].get(nn, {})
			nota_perdida(l, nn)
```

**A frase inteira:** todas as notas da frase BOM ou melhor → `frases[l] += 1`, `marcar(l, FRASE_INTEIRA)` (dentro do
`toque` da última nota: o kit passa pelo item), o sino pequeno acende na cor do dono (`Tema.emissivo(mat, 1.4, l)`)
por 1 batida, `Som.tocar("sino", pos_do_sino, -12.0, TOM_DO_LUGAR[l])`, um aro novo no poste (abaixo), as trincas
somem e o sino caído se conserta.

**Os pontos** (no `toque`): `marcar(l, PONTOS[julgamento])`; o item (`Itens.pontos_do_acerto`) o kit já aplica.

### O coro na TV

A resposta de cada um toca na TV, no sino dele (`pos_do_sino`), no timbre do lugar:

- **o acerto** (no `toque`): `Som.tocar("nota", pos_do_sino, -4.0 if perfeito else -9.0, TOM_DO_LUGAR[l] * ALTURA_TOM[altura])`;
  com o sino caído, o tom vezes `DESAFINADO` (o sino rachado canta torto até o conserto);
- **o erro** (na `falha`): `Som.tocar("nota", pos_do_sino, -12.0, TOM_DO_LUGAR[l] * ALTURA_TOM[altura] * DESAFINADO)`,
  além da falha do kit (`Som.tocar("falha", pos, -6.0)`).

Os quatro em hoqueto formam, na TV, uma frase de quatro sinos; a sala ouve quem desafinou.

### O sino que racha e cai

- **A trinca** (na `falha`): `trincas[l] += 1` até 3, e a trinca seguinte aparece no sino; o sino dá um tranco
  (`rotation.x` a 0,25 em 30 % de meia batida, e volta em 70 % dela, curva `BACK`); 10 faíscas `Tema.GRAFITE` na saia
  (`Efeitos.faiscas(self, pos, Tema.GRAFITE, 10, 0.6)`); o cavaleiro faz `gesto("emote-no", 0.4)`.
- **A terceira trinca** derruba o sino: `_cair_em[l] = CenarioDoCanto.proxima_colcheia(0.15)` (a colcheia que vem,
  a pelo menos 0,15 s), e o sino solta do braço já: o pivô vai a `chao = Vector3(RAIAS[l] - s * 1.6, 0.3, Z_JOGADOR + 0.6)`
  (`s = signf(RAIAS[l])`: ele rola para o lado do vizinho) com `rotation.z = s * PI / 2`, curva `QUAD` `EASE_IN`,
  chegando no tempo exato de `_cair_em[l]`.
- **O sino bate no chão** (`_bater_no_chao(l)`, no quadro em que `Ritmo.batida() >= _cair_em[l]`):
  `Som.tocar("sino", chao, -6.0, TOM_DO_LUGAR[l] * DESAFINADO)`; `Forja.sentir(l, "golpe")`; o R2 em Resistência
  (`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)`) por 0,25 s, depois Off; `CenarioDoCanto.exagero(self, _cenario, "estrondo", jogador(l))`;
  `CenarioDoCanto.so_o_dono(self, l)`; 48 faíscas `Tema.TUNGSTENIO`; e
  `momento("sino_torto", l, Vector3(chao.x, 0.0, chao.z), SINO_ALTURA_M, {"trincas": 3})`.
- **No chão**, o sino toca torto a cada batida (o diretor: «toca torto no chão a cada batida»):
  `Som.tocar("sino", chao, -18.0, TOM_DO_LUGAR[l] * DESAFINADO)` na virada de cada batida inteira. A −18 dB, ele fica
  14 dB abaixo da resposta do kit (−4) e não cobre o coro.
- **O conserto** (na frase inteira): o pivô volta ao braço e `rotation.z` a 0 em `CenarioDoCanto.queda(l, 1.0)`
  batidas (o Fôlego), curva `BACK` `EASE_OUT`, com 24 faíscas `Tema.TUNGSTENIO`; `trincas[l] = 0`.

A recuperação é em 2 compassos: a próxima chamada e a resposta dela. Nada se perde além do ponto.

### O pico

No primeiro compasso que começa com `no_pico()` (o 14): `Som.tocar("sino", CenarioDoCanto.SINO_TV, -4.0)` nas
batidas 0, 1 e 2 dele, e o sino grande balança com força 1,0 nessas três batidas. A chave da luz sobe e a câmera
recua pelo `CenarioDoCanto.passar` (A cena).

### A reta: o uníssono

A chamada `c` com `4 * (c + 1) >= _b_fim - RETA_BATIDAS` (as chamadas 37 e 39) é o uníssono: **todos** na vez 0, a
mesma frase de duas notas em colcheia (as duas alturas sorteadas uma vez para todos); cada um tem a sua frase e o seu
`n`. A chamada sai nos quatro alto-falantes ao mesmo tempo, e as quatro respostas tocam juntas na TV: um acorde de
quatro sinos, ou um que racha.

Na batida `_b_fim - RETA_BATIDAS` (149), uma vez:
`momento("reta", -1, Vector3(0, 0, Z_JOGADOR), 1.8, {"objeto": "aros", "valores": "5,3,4,2"})`, com as frases
inteiras de P1 a P4 (`-` para quem não está).

### O ensina

Na primeira resposta de cada lugar (`_ensinou[l]` falso), cada nota mostra o botão certo sobre o sino, de 1 batida
antes até a nota: um `Sprite3D` com `Desenho.glifo("cross")` (grave) ou `Desenho.glifo("circle")` (aguda),
`pixel_size` para 0,35 m, billboard, `shaded` false, `modulate` `Tema.ETIQUETA`, em `pos_do_sino + (0, 0.5, 0)` para
a grave e `+ (0, 0.9, 0)` para a aguda: o grave embaixo, o agudo em cima, como a mão. Depois da última nota dessa
frase, `_ensinou[l] = true` e o glifo nunca mais aparece.

### A bancada

Só com `Forja.bancada`. Na chamada `c` com `c % BANCADA_A_CADA == BANCADA_DESLOC` (3, 9, 15, 21, 27, 33), o gerador
não dá frase, e em `Ritmo.batida() >= 4c` o `_bancada(dt)` começa **o canto às cegas** de hoje:

- o plano das fontes de hoje (`canto.gd:244-265`, `Forja.cega_plano_fontes`), com `cada` = 1 por controle e 1 na TV
  (sozinho: 3 e 3, como hoje), montado no `iniciar_jogo`: com quatro, 5 cantos; cabem os 6 compassos;
- `_comecar_canto()` e `_tocar_nota(k)` de hoje (`canto.gd:273-312`), sem o `Label3D` da nota (o `♪` sai: a tela não
  aponta); a TV canta no `SINO_TV` a −2 dB;
- `PERGUNTA` (o laço de `canto.gd:420-439`, com o evento `pergunta` da F01, `qual` = `"canto"`), `_fechar_pergunta()`
  (`canto.gd:315-349`) e `REVELA` por `REVELA_S`; o `_revelar()` toca `Som.tocar("sino", SINO_TV, -8.0)` no lugar de
  `bigorna_aguda` e solta 20 faíscas `Tema.TUNGSTENIO` no dono; `REPETE` e `_fechar_repeticao` saem;
- enquanto `estado_bancada != JOGO`, `_gerar_compasso` não gera chamada nenhuma;
- `pergunta()` (`canto.gd:546-574`) e `dar_vereditos()` (`canto.gd:456-462`) ficam iguais; o veredito
  `alto_falante` é calculado nos dois modos (fora da bancada, sai «não medido», como a F01 manda).

### O fim e o vencedor

Acaba pelo tempo (90 s de música, contados pelo kit). O vencedor tem mais frases inteiras; no empate, mais pontos:

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(frases[a]) != int(frases[b]):
			return int(frases[a]) > int(frases[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

### Com menos de quatro

- **Três:** as vezes 0, 1 e 2; a batida 3 fica vazia.
- **Dois:** as vezes 0 e 2.
- **Um:** as vezes 0 e 2 são dele (duas frases por chamada). `com_poucos()` devolve `""`: nada muda na regra.
- **O controle que cai:** a chamada dele não toca; as notas de resposta dele que passam saem caladas
  (`notas_perdidas(l)`, sem erro). Quando volta, responde a próxima nota que ainda não chegou. As trincas ficam.

### Os ganchos

O que muda do `canto.gd` de hoje, na ordem do arquivo:

| hoje | n'O Canto |
| --- | --- |
| `class_name SalaCanto`, `extends SalaJogo`, o cabeçalho | `extends Minigame`, sem `class_name`, o cabeçalho de «A ficha de dados» |
| `const F`, `RAIAS`, `Z_JOGADOR`, `REPETE_MAX`, `FOLGA_RITMO`, `SINO_TV`, `PERFIL` | saem (os dois últimos vão para `CenarioDoCanto`) |
| `enum { PREPARO, CANTO, PERGUNTA, REVELA, REPETE, ACABOU }` | `enum { JOGO, CANTO, PERGUNTA, REVELA }` em `estado_bancada` (só a bancada sai de `JOGO`) |
| `estado`, `t_estado`, `relogio`, `plano`, `rodada`, `fonte`, `ritmo`, `notas_tocadas` | ficam, só para a bancada |
| `j`, `n` | são do kit: não declare |
| `sino_tv`, `brilho_tv`, `_mat_tv`, `_notas_no_ar` | saem (o sino grande é do cenário; o `♪` sai) |
| `_init()` | sai: a FICHA (o `papel_som` vira a chave; a câmera vai para o `montar`); o `cega = true` vai para o `montar` (a pergunta às cegas da bancada: o diagnóstico fica fechado em jogo, `sala_jogo.gd:470-471`) |
| `montar()`, `sino()`, `_montar_torre()`, `_montar_raia()` | o de «A cena»; a partitura sai |
| `_novo_jogador()` | fica igual (a bancada), em `j[l]` |
| `iniciar_jogo()` | o plano das fontes só com `Forja.bancada` |
| `_conectado` | `conectado` (kit) |
| `_comecar_canto`, `_tocar_nota`, `_fechar_pergunta`, `_revelar`, `pergunta()`, `dar_vereditos()` | ficam (a bancada), com as trocas de «A bancada» |
| `_fechar_repeticao`, `_proxima_rodada`, `_acabar` | saem (`_proxima_rodada` volta a `JOGO`) |
| o `match estado` do `jogar` | o `jogar` de baixo; a bancada em `_bancada(dt)` |
| `_process`, `_mostrar` (465-521) | `_mostrar(l)` no fim do `jogar`: o sino da vez, as trincas, o brilho, o glifo |
| `status()` | `""` quando `na_raia(l)` (o placar mora nos aros); senão `super` |
| `progresso()` | sai (a barra de tempo do kit) |
| `dica()` | `{}`: durante o jogo, zero frase (o ensina é o glifo no mundo) |
| `_robo` | `robo(l, dt)` de «O controle» |
| `com_poucos()` | `""` |

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

O esqueleto:

```gdscript
enum { JOGO, CANTO, PERGUNTA, REVELA }

var estado_bancada := JOGO
var _info := [{}, {}, {}, {}]  ## lugar -> {n: {b, altura, frase}}
var _chamadas: Array = []  ## {l, b, altura, n, tocou}: as notas da chamada a tocar
var _frase := {}  ## id -> {notas, boas, fechadas}
var _id_frase := 0
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _batida := 0  ## a última batida inteira: o sino caído toca nela
var _b_fim := 0
var _pico_tocou := false
var _reta_anotada := false
var frases := [0, 0, 0, 0]
var trincas := [0, 0, 0, 0]
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _caido := [false, false, false, false]
var _cair_em := [-1.0, -1.0, -1.0, -1.0]  ## a batida em que o sino bate no chão (-1: não cai)
var _gatilho_ate := [-1.0, -1.0, -1.0, -1.0]
var _ensinou := [false, false, false, false]
var _sinos := {}  ## lugar -> CenarioDoCanto.suporte(...)
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoCanto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoCanto.montar(self)
	_b_fim = int(floor(duracao * Ritmo.bpm / 60.0))
	cega = true  # como o canto.gd de hoje: na bancada, o diagnóstico não abre em jogo
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		raia(l)
		posicionar(l)
		p.rotation.y = 0.0
		p.preso = true
		_sinos[l] = CenarioDoCanto.suporte(self, l)
		_trincas_escondidas(l)  # as três caixas JANELA na saia do sino pequeno
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	for l in presentes():
		CenarioDoCanto.luz_da_nota(l, 1.0)
	if Forja.bancada:
		_planejar_a_bancada()  # canto.gd:244-265, com cada = 1


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
		_pico_no_tempo(c)  # o sino grande três vezes no primeiro compasso do pico
	var b := int(floor(Ritmo.batida()))
	if b > _batida:
		_batida = b
		_chao_no_tempo()  # o sino caído toca torto a cada batida
	while _gerado <= c + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	if Forja.bancada:
		_bancada(dt)
	CenarioDoCanto.passar(self, _cenario, no_pico())
	_tocar_as_chamadas()
	_reta_no_tempo()
	for l in presentes():
		_apagar_o_pulso(l, dt)
		_sino_no_tempo(l)  # bater no chão, o gatilho que volta, o brilho que apaga, o glifo
		if not conectado(l):
			notas_perdidas(l)  # sem controle, saem caladas
			continue
		if Forja.apertou(l, Forja.CRUZ):
			_responder(l, GRAVE)
		elif Forja.apertou(l, Forja.CIRCULO):
			_responder(l, AGUDA)
		_passaram(l)
		_mostrar(l)
	CenarioDoCanto.balancar(_cenario.sino, 0.4 if fmod(Ritmo.batida(), 4.0) < 0.5 else 0.0)


func _gerar_compasso(c: int) -> void:
	if c < 1 or c % 2 == 0 or 4 * (c + 1) + 3 >= _b_fim:
		return
	if Forja.bancada and (estado_bancada != JOGO or c % BANCADA_A_CADA == BANCADA_DESLOC):
		return
	var lista := presentes()
	lista.sort()
	if lista.is_empty():
		return
	if 4 * (c + 1) >= _b_fim - RETA_BATIDAS:
		var alturas := [rng.randi_range(0, 1), rng.randi_range(0, 1)]
		for l in lista:
			_nova_frase(l, 4.0 * c, alturas)
		return
	var t := Ritmo.t_da_batida(4.0 * c)
	var parte := 0 if t < duracao / 3.0 else (1 if t < duracao * 2.0 / 3.0 else 2)
	var k := lista.size()
	for i in k:
		var l: int = lista[i]
		var vezes: Array = [0, 2] if k == 1 else ([2 * i] if k == 2 else [i])
		for v in vezes:
			var alturas := [rng.randi_range(0, 1)]
			if not Ritmo.simples[l] and rng.randf() < DUAS_NOTAS[parte]:
				alturas.append(rng.randi_range(0, 1))
			_nova_frase(l, 4.0 * c + v, alturas)


func _nova_frase(l: int, b: float, alturas: Array) -> void:
	_id_frase += 1
	_frase[_id_frase] = {"notas": alturas.size(), "boas": 0, "fechadas": 0}
	for k in alturas.size():
		var bc := b + 0.5 * k
		var nn := int(round((bc + 4.0) * 2.0))
		_info[l][nn] = {"b": bc + 4.0, "altura": int(alturas[k]), "frase": _id_frase}
		nova_nota(l, nn, Ritmo.t_da_batida(bc + 4.0))
		_chamadas.append({"l": l, "b": bc, "altura": int(alturas[k]), "n": nn, "tocou": false})


func _responder(l: int, altura: int) -> void:
	var nn := casar_toque(l)
	if nn < 0:
		return
	_ultima[l] = _info[l].get(nn, {})
	if int(_ultima[l].get("altura", -1)) == altura:
		julgar_nota(l, nn)
	else:
		nota_perdida(l, nn)


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	var s: Dictionary = _sinos[l]
	marcar(l, PONTOS[julgamento])
	var tom: float = TOM_DO_LUGAR[l] * ALTURA_TOM[int(nt.altura)] * (DESAFINADO if _caido[l] else 1.0)
	Som.tocar("nota", (s.pivo as Node3D).global_position, -4.0 if julgamento == Ritmo.PERFEITO else -9.0, tom)
	if julgamento == Ritmo.PERFEITO:
		_crescer(s.pivo)  # 130 % e volta em meia batida (o kit já pisca a barra de luz de branco)
		CenarioDoCanto.exagero(self, _cenario, "golpe", jogador(l))
	else:
		CenarioDoCanto.luz_da_nota(l, 0.6)
		_pulso[l] = PULSO_S
	_contar_na_frase(l, nt, true)


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if nt.is_empty():
		return
	var s: Dictionary = _sinos[l]
	Som.tocar("nota", (s.pivo as Node3D).global_position, -12.0, TOM_DO_LUGAR[l] * ALTURA_TOM[int(nt.altura)] * DESAFINADO)
	_contar_na_frase(l, nt, false)
	_rachar(l)


func _contar_na_frase(l: int, nt: Dictionary, boa: bool) -> void:
	var f: Dictionary = _frase.get(int(nt.get("frase", -1)), {})
	if f.is_empty():
		return
	f.fechadas = int(f.fechadas) + 1
	if boa:
		f.boas = int(f.boas) + 1
	if int(f.fechadas) < int(f.notas):
		return
	_frase.erase(int(nt.frase))
	if not _ensinou[l]:
		_ensinou[l] = true
	if int(f.boas) == int(f.notas):
		_frase_inteira(l)  # frases, FRASE_INTEIRA, o brilho, o sino, o aro, o conserto


func _exit_tree() -> void:
	CenarioDoCanto.soltar_a_musica(self)
```

`_tocar_as_chamadas()`, `_pico_no_tempo(c)`, `_chao_no_tempo()`, `_reta_no_tempo()`, `_sino_no_tempo(l)`,
`_apagar_o_pulso(l, dt)` (volta `luz_da_nota(l, 1.0)` quando `_pulso` chega a 0), `_crescer(pivo)`, `_rachar(l)`,
`_frase_inteira(l)`, `_trincas_escondidas(l)`, `_planejar_a_bancada()`, `_bancada(dt)` e `_mostrar(l)` fazem o que
as partes desta ficha dizem.

O catálogo: `Catalogo.MINIGAMES["S06_J26"] = preload("res://scripts/minigames/s06/o_canto.gd")`; na seção `S06` de
`SECOES`, `"minigames": ["S06_J26"]`; e sai `"canto"` de `SALAS_ANTIGAS`.
`git rm godot/scripts/salas/canto.gd godot/scripts/salas/canto.gd.uid`.
Em `godot/scripts/traducoes.gd`: `"O Canto": "The Chant"`, `"Repita!": "Repeat!"` (as que ainda não existirem). Os
textos da pergunta da bancada (`canto.gd:546-574`) já estão lá.

## A cena

### A câmera

A capela do [cinema](../arte/01-cinema.md): lente de 35 mm (FOV vertical 37,8°), plongée de 50°, o modo `fixa` da
G05, e **não corta** do apito ao apito. `CenarioDoCanto.pose_da_camera()` devolve
`[Vector3(0, 14.99, 10.07), Vector3(0, 1.2, -1.5)]`: o centro `(0, 1,2, −1,5)` visto a 18 m, 50° abaixo da
horizontal. Com 35 mm em 16:9, o quadro cobre de x = −11 a 11 na altura dos cavaleiros e vê o chão de z = 4,3 (a
borda de baixo) para o fundo; o raio de cima passa em y = 6,3 no pórtico (z = −4,3) e em y = 5,3 na parede do fundo
(z = −6): os quatro sinos pequenos, o sino grande, a viga e as torres cabem inteiros. A lente é a da G05; até ela
entrar, os 40° de hoje mostram 6 % a mais em volta e nada sai do quadro.

- **O pico** (`no_pico()`): a câmera recua 10 % (`pose_da_camera(1.1)`: a 19,8 m) e volta ao sair; o `lerp` do main
  faz o caminho (nunca salta).
- **O tremor é do evento**: só o de `CenarioDoCanto.exagero`. Nenhum tremor de ambiente, roll zero.

### A luz da seção

S6 é a tinta cobalto (`Tema.SECAO[1]`, `#2f55c4`), **lado B**. `Tema.luz_da_secao(6, true)` (G15: o número da seção
e `lado_b`) devolve a névoa `#050d26` com densidade 0,0156 (o lado B adensa 30 %), o preenchimento `#1f346a` e a
chave `#e5d3c6` com `energia_chave` 1,53 (o lado B tira 15 %). A névoa é do main (a G15 a põe pela seção do slot). O
cenário comum põe o preenchimento (o `atmosfera` da sala) e a chave (uma `OmniLight3D` em `(0, 8, 4)`, energia
0,47 = 0,55 × 0,85, alcance 26). As duas tochas, em `(±7,6, 2,9, −4,4)`, na frente das torres, são `Tema.TUNGSTENIO`,
energia 0,9, alcance 8. O foco do sino grande é uma `SpotLight3D` `Tema.TUNGSTENIO` em `SINO_TV + (0, 2,5, 3,5)`,
mirando `SINO_TV + (0, −0,8, 0)`, energia 2,2, alcance 9, ângulo 26°.

- **O pico:** a chave sobe 20 % em 1 batida (curva `SINE`) e volta em 2 batidas quando o pico acaba. Com
  `Opcoes.flashes` desligado: +10 % em 2 batidas.
- **O estrondo (o sino que cai):** a luz das outras três raias cai 30 % por 1 batida (`so_o_dono`).

### As peças Kenney e o papel de cada uma

`Kit.peca(pai, "<pacote>/<peça>", pos, rot_y, escala)`; sem barra, é do `mini-dungeon`. A altura final é a medida
crua × a escala × o fator do pacote (`castle-kit` 1,4; `fantasy-town-kit` 1).

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `floor-detail`, `wall`, `wall-half` | `Kit.arena(sala, 5, 3)` | o chão e as paredes da capela (de x −10 a 10, z −6 a 6) |
| `castle-kit/tower-hexagon-base` (escala 1,5: 2,75 m de alto, 1,89 m de largo) | `(±7,6, 0, −5,4)` | as duas torres do fundo |
| `castle-kit/tower-hexagon-roof` (escala 1,5: 1,74 m) | `(±7,6, 2,75, −5,4)` | o telhado das torres (o topo em 4,49 m) |
| `fantasy-town-kit/pillar-stone` (escala 5,2: 5,2 m) | `(±2,1, 0, −4,3)` | os pilares do pórtico do sino grande |

O que não é peça Kenney (caixas e cilindros do `Kit`, nenhuma esfera; `metallic` 0, salvo o sino):

| objeto | forma | material |
| --- | --- | --- |
| a viga do pórtico | caixa 5,0 × 0,4 × 0,46 em `(0, 5,4, −4,3)` | `Kit.material(Tema.OXIDO, 0.0, 0.85)` |
| a corrente | `Kit.cilindro(sala, 0.035, 1.3, SINO_TV + (0, 0.65, 0), …)` | `Kit.material(Tema.GRAFITE, 0.0, 0.5)` |
| o sino grande | o `PERFIL` girado, 8 lados, escala 1,35 (1,35 m de diâmetro, 2,55 m de alto) | `Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.45)`, `metallic` 0,15 |
| a argola | caixa 0,26 × 0,08 × 0,08 × escala, no topo | o material do sino |
| o badalo | caixa 0,2 × 0,2 × 0,2 × escala | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| o poste do sino pequeno | caixa 0,12 × 1,9 × 0,12 em `(RAIAS[l] − s·1,05, 0,95, Z_JOGADOR − 0,35)` | `Kit.material(Tema.OXIDO, 0.0, 0.85)` |
| o braço | caixa 0,62 × 0,1 × 0,12, no poste + `(s·0,25, 1,88, 0)` | o mesmo |
| o sino pequeno | o `PERFIL`, 8 lados, escala 0,34, em `(RAIAS[l] − s·0,6, 1,8, Z_JOGADOR − 0,35)` | o material do sino grande (um por raia) |
| as trincas | três caixas 0,02 × 0,18 × 0,02 no pivô, em `(cos a · 0,27, −0,53, sin a · 0,27)`, `a` = 60°, 90°, 120°, escondidas | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| o aro da frase | caixa 0,18 × 0,04 × 0,18 no poste, em y = 0,3 + 0,05 k (k = 0 … 29) | `Kit.material(Tema.JOGADOR[l].darkened(0.6), 0.0, 0.7)` com `Tema.emissivo(m, 1.0, l)` |
| o glifo do ensina | `Sprite3D` de 0,35 m, billboard, `shaded` false | `modulate` `Tema.ETIQUETA` |

`s = signf(RAIAS[l])`: o sino pequeno fica do lado do centro (P1 e P2 à direita do cavaleiro, P3 e P4 à esquerda),
para o sino caído de P4 caber em `x_tela` ≤ 0,8. O tablado e a borda da raia são do kit (`raia(l)`).

**O rastro:** os aros sobem no poste a cada frase inteira (até 30, 1,8 m: a altura do braço) e ficam até o fim; o
sino caído fica no chão até a próxima frase inteira.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| o sino pequeno na frase inteira | o lugar | `Tema.emissivo(mat, 1.4, l)` por 1 batida, depois 0 |
| o aro da frase | o lugar | 1,0 |
| a luz da raia (`_raias[l].luz`, do kit) | o lugar | a do kit; ×0,7 por 1 batida no `so_o_dono` |
| as faíscas do sino que cai e do conserto | a forja | `Efeitos.faiscas(self, pos, Tema.TUNGSTENIO, 48 ou 24, 1.2)` |
| as faíscas da trinca | ninguém (cinza, não acende) | `Efeitos.faiscas(self, pos, Tema.GRAFITE, 10, 0.6)` |
| as tochas e o foco do sino grande | a forja | `Tema.TUNGSTENIO`, luz 0,9 e 2,2 |

Nenhuma cor fora dos tokens: os `#b88cff`, `#8a80c8`, `#ffa060`, `#6b4526`, `#b07838`, `#3c3c44`, `#ffd9a0`,
`#3a2a24`, `#7a5230`, `#c08a42`, `#5a3c1c`, `#8a6a3a` e o `Tema.AMARELO`/`Tema.ROXO` de hoje somem. O sino é fosco e
facetado (8 lados, `metallic` 0,15; hoje é liso, 28 lados, 0,75).

### O cenário comum (`godot/scripts/minigames/s06/cenario_do_canto.gd`)

O arquivo inteiro:

```gdscript arquivo=godot/scripts/minigames/s06/cenario_do_canto.gd
class_name CenarioDoCanto
extends RefCounted
## O cenário comum d'O Canto (S06, docs/jogo/tarefas/N-o-canto.md): a capela
## cobalto do lado B, as torres, o pórtico com o sino grande da TV, o sino
## facetado de cada raia, a câmera da capela, o exagero do impacto, o
## alto-falante de cada um com a saída para a TV, a música que abaixa na pista,
## o ouvido do robô e os ganchos do cavaleiro. Os cinco minigames da seção
## montam com isto; o que é só de um fica no script dele.

const SECAO := 6  ## Tema.tinta_da_secao(6) == Tema.SECAO[1], o cobalto
const LADO_B := true
## A capela (docs/jogo/arte/01-cinema.md): 35 mm, plongée de 50°, a 18 m.
const CAMERA_OLHAR := Vector3(0, 1.2, -1.5)
const CAMERA_ANGULO := 50.0
const CAMERA_DISTANCIA := 18.0
## O exagero do impacto (docs/jogo/diversao/README.md#o-exagero-do-impacto).
const DEGRAUS := {
	"golpe": {"tremor_m": 0.02, "batidas": 1.0, "hit_stop": 2, "luz": 0.0},
	"estrondo": {"tremor_m": 0.05, "batidas": 2.0, "hit_stop": 3, "luz": 0.0},
	"catastrofe": {"tremor_m": 0.08, "batidas": 4.0, "hit_stop": 0, "luz": 0.4},
}
## Os ganchos dos stats no neutro (stat 3), enquanto a classe Cavaleiro (G13)
## não existe (docs/jogo/sistemas/stats.csv).
const NEUTRO := {"empurrao": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}
const SINO_TV := Vector3(0.0, 3.9, -4.3)
## O perfil do sino (raio, altura), da coroa à boca (o de canto.gd, igual).
const PERFIL := [
	Vector2(0.0, 1.0), Vector2(0.18, 0.98), Vector2(0.34, 0.89), Vector2(0.43, 0.73), Vector2(0.48, 0.5),
	Vector2(0.5, 0.23), Vector2(0.55, -0.05), Vector2(0.64, -0.32), Vector2(0.77, -0.55), Vector2(0.93, -0.7),
	Vector2(1.0, -0.8), Vector2(0.68, -0.85), Vector2(0.34, -0.875), Vector2(0.0, -0.886),
]
const LADOS := 8  ## facetado (docs/jogo/11, regra 2)
## O som da TV no lugar do alto-falante, quando o controle não tem um: [som, tom].
## A "nota:<l>" do controle é o Dó5 (523,25 Hz) vezes o tom do lugar; a "nota" da TV
## é 784 Hz: na TV, ela desce por 523,25 / 784, e fica na mesma altura.
const DO5_NA_TV := 0.6674
const NA_TV := {"nota": ["nota", 1.0], "nota_alta": ["nota_alta", 1.0], "clique": ["tique", 1.0],
	"pronto": ["nota_alta", 1.3348], "coleta": ["tique", 1.0]}
## A seção pede (o mapa do áudio, mus_s06_*): na pista, a música −12 dB por 1
## tempo, e volta em 300 ms.
const MUSICA_DB := -12.0
const MUSICA_VOLTA_S := 0.3


## A pose da câmera da capela: [posição, alvo]. `recuo` 1,1 no pico.
static func pose_da_camera(recuo := 1.0, olhar := CAMERA_OLHAR) -> Array:
	var a := deg_to_rad(CAMERA_ANGULO)
	return [olhar + Vector3(0, sin(a), cos(a)) * CAMERA_DISTANCIA * recuo, olhar]


## A capela cobalto. `escuro` 1,0 é O Canto; 0,4 é o abismo do Eco (a luz da
## casa escurece, não troca). `com_portico` false tira os pilares, a viga e o
## sino grande (o Coral e o Código têm o fundo deles). Devolve {chave,
## chave_energia, pico, luz_ate, pose, sino}: o que `passar` e
## `exagero` mexem, e o sino grande ({} sem pórtico).
static func montar(sala: SalaJogo, escuro := 1.0, com_portico := true) -> Dictionary:
	Kit.arena(sala, 5, 3)
	var luz: Dictionary = Tema.luz_da_secao(SECAO, LADO_B)
	sala.atmosfera(luz.preenchimento, Tema.VIOLETA, false, 36, 22.0, -7.8, 0.2 * escuro)
	var chave := OmniLight3D.new()
	chave.position = Vector3(0, 8.0, 4.0)
	chave.light_color = luz.chave
	chave.light_energy = 0.55 * 0.85 * escuro
	chave.omni_range = 26.0
	sala.add_child(chave)
	for x in [-7.6, 7.6]:
		Kit.peca(sala, "castle-kit/tower-hexagon-base", Vector3(x, 0, -5.4), 0.0, 1.5)
		Kit.peca(sala, "castle-kit/tower-hexagon-roof", Vector3(x, 2.75, -5.4), 0.0, 1.5)
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.9, -4.4)
		tocha.light_color = Tema.TUNGSTENIO
		tocha.light_energy = 0.9 * escuro
		tocha.omni_range = 8.0
		sala.add_child(tocha)
	var s := {}
	if com_portico:
		for x in [-2.1, 2.1]:
			Kit.peca(sala, "fantasy-town-kit/pillar-stone", Vector3(x, 0, SINO_TV.z), 0.0, 5.2)
		Kit.caixa(sala, Vector3(5.0, 0.4, 0.46), Vector3(0, 5.4, SINO_TV.z), Kit.material(Tema.OXIDO, 0.0, 0.85))
		Kit.cilindro(sala, 0.035, 1.3, SINO_TV + Vector3(0, 0.65, 0), Kit.material(Tema.GRAFITE, 0.0, 0.5))
		s = sino(sala, SINO_TV, 1.35)
		var foco := SpotLight3D.new()
		sala.add_child(foco)
		foco.look_at_from_position(SINO_TV + Vector3(0, 2.5, 3.5), SINO_TV + Vector3(0, -0.8, 0))
		foco.light_color = Tema.TUNGSTENIO
		foco.light_energy = 2.2 * escuro
		foco.spot_range = 9.0
		foco.spot_angle = 26.0
	return {"chave": chave, "chave_energia": chave.light_energy, "pico": false,
		"luz_ate": -1.0, "pose": pose_da_camera(), "sino": s}


## A cada quadro: o pico (a chave +20 % em 1 batida, a câmera recua 10 %) e a
## luz da catástrofe que volta. O tremor acaba sozinho (o `tremer` da G05).
static func passar(sala: SalaJogo, c: Dictionary, no_pico: bool) -> void:
	var agora := Ritmo.t_musica()
	var batida := 60.0 / Ritmo.bpm
	if no_pico != bool(c.pico):
		c.pico = no_pico
		# o olhar da sala, não o CAMERA_OLHAR: o Eco (N2) e o Código (N4) montam com o deles, e o pico e a volta ficam nele
		var pose := pose_da_camera(1.1 if no_pico else 1.0, sala.camera_olhar)
		if sala.camera_modo != "corrida":
			sala.camera_pos = pose[0]
			sala.camera_olhar = pose[1]
		var sobe := (0.2 if Opcoes.flashes else 0.1) if no_pico else 0.0
		var em := (1.0 if Opcoes.flashes else 2.0) if no_pico else 2.0
		var tw := sala.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(c.chave, "light_energy", float(c.chave_energia) * (1.0 + sobe), em * batida)
	if float(c.luz_ate) >= 0.0 and agora >= float(c.luz_ate):
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.2 if c.pico and Opcoes.flashes else 1.0)
		c.luz_ate = -1.0


## O exagero do impacto, pelo degrau: o tremor (o `tremer` da G05: 0,02, 0,05
## ou 0,08 m, que ele mesmo faz durar 1, 2 ou 4 batidas e decair), o hit-stop
## do boneco (em quadros) e a luz da catástrofe (por 1 compasso).
static func exagero(sala: SalaJogo, c: Dictionary, degrau: String, boneco: Node3D = null) -> void:
	var d: Dictionary = DEGRAUS[degrau]
	var batida := 60.0 / Ritmo.bpm
	sala.tremer(float(d.tremor_m))  # Sala.TREMOR_GOLPE, _ESTRONDO ou _CATASTROFE (G05)
	if int(d.hit_stop) > 0 and boneco and Opcoes.tremor:
		congelar(boneco, int(d.hit_stop))
	if float(d.luz) > 0.0:
		var k := float(d.luz) if Opcoes.flashes else float(d.luz) * 0.5
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.0 + k)
		c.luz_ate = Ritmo.t_musica() + 4.0 * batida


## O hit-stop visual: a animação do boneco para `quadros` quadros (60 por s).
## O relógio, o julgamento e a física nunca param.
static func congelar(boneco: Node3D, quadros: int) -> void:
	var anim: AnimationPlayer = boneco.get("anim")
	if anim == null:
		return
	var antes := anim.speed_scale
	anim.speed_scale = 0.0
	boneco.get_tree().create_timer(quadros / 60.0).timeout.connect(func(): anim.speed_scale = antes)


## A luz das outras raias cai 30 % por 1 batida (o momento de um só).
static func so_o_dono(sala: Minigame, dono: int) -> void:
	var batida := 60.0 / Ritmo.bpm
	for l in sala.presentes():
		if l == dono:
			continue
		var r: Dictionary = sala._raias.get(l, {})
		if r.is_empty():
			continue
		var luz: OmniLight3D = r.luz
		var antes := luz.light_energy
		luz.light_energy = antes * 0.7
		sala.get_tree().create_timer(batida).timeout.connect(func(): luz.light_energy = antes)


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


## A queda do lugar, em batidas: `tempos` × o Fôlego, arredondada à
## semicolcheia, no mínimo uma (docs/jogo/sistemas/README.md, o levantar).
static func queda(l: int, tempos: float) -> float:
	return maxf(0.25, snappedf(tempos * gancho(l, "levantar"), 0.25))


## A próxima colcheia da música (em batidas) a pelo menos `folga_s` de agora:
## o momento cai nela (a régua, item 9).
static func proxima_colcheia(folga_s := 0.0) -> float:
	var b := Ritmo.batida() + folga_s * Ritmo.bpm / 60.0
	return ceilf(b * 2.0) / 2.0


## O sino: o PERFIL girado com LADOS lados (fosco, facetado), pendurado pela
## coroa num pivô (o pivô balança). A argola e o badalo são caixas. Devolve
## {pivo, mat, badalo}.
static func sino(pai: Node3D, pos: Vector3, escala: float) -> Dictionary:
	var pivo := Node3D.new()
	pivo.position = pos
	pai.add_child(pivo)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in PERFIL.size() - 1:
		var a: Vector2 = PERFIL[i]
		var b: Vector2 = PERFIL[i + 1]
		for k in LADOS:
			var t0 := TAU * k / LADOS
			var t1 := TAU * (k + 1) / LADOS
			var p00 := Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x)
			var p01 := Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x)
			var p10 := Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)
			var p11 := Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)
			for q in [p00, p10, p11, p00, p11, p01]:
				st.add_vertex(q)
	st.generate_normals()
	var malha := MeshInstance3D.new()
	malha.mesh = st.commit()
	var mat := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.45)
	mat.metallic = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	malha.material_override = mat
	malha.position = Vector3(0, -1.0, 0) * escala
	malha.scale = Vector3.ONE * escala
	pivo.add_child(malha)
	Kit.caixa(pivo, Vector3(0.26, 0.08, 0.08) * escala, Vector3(0, 0.08, 0) * escala, mat)
	var badalo := Node3D.new()
	badalo.position = Vector3(0, -0.4, 0) * escala
	pivo.add_child(badalo)
	Kit.caixa(badalo, Vector3(0.2, 0.2, 0.2) * escala, Vector3(0, -1.35, 0) * escala, Kit.material(Tema.GRAFITE, 0.0, 0.6))
	return {"pivo": pivo, "mat": mat, "badalo": badalo}


## O suporte do sino pequeno do lugar, do lado do centro: o poste, o braço e o
## sino. Devolve o sino ({pivo, mat, badalo}) com `base` (a posição do pivô),
## `poste` (a base do poste) e `s` (o lado: -1 à esquerda do centro, 1 à direita).
static func suporte(sala: Minigame, l: int) -> Dictionary:
	var x: float = Minigame.RAIAS[l]
	var s := signf(x)
	var poste := Vector3(x - s * 1.05, 0.0, Minigame.Z_JOGADOR - 0.35)
	var oxido := Kit.material(Tema.OXIDO, 0.0, 0.85)
	Kit.caixa(sala, Vector3(0.12, 1.9, 0.12), poste + Vector3(0, 0.95, 0), oxido)
	Kit.caixa(sala, Vector3(0.62, 0.1, 0.12), poste + Vector3(s * 0.25, 1.88, 0), oxido)
	var base := Vector3(x - s * 0.6, 1.8, Minigame.Z_JOGADOR - 0.35)
	var r := sino(sala, base, 0.34)
	r["base"] = base
	r["poste"] = poste
	r["s"] = s
	return r


## O sino balança pela batida (0: parado).
static func balancar(s: Dictionary, forca: float) -> void:
	if s.is_empty():
		return
	(s.pivo as Node3D).rotation.z = sin(TAU * Ritmo.batida()) * 0.3 * forca
	(s.badalo as Node3D).rotation.z = sin(TAU * Ritmo.batida() - 0.6) * 0.45 * forca


## O sino grande dá o tempo forte na TV, baixo: o compasso se ouve mesmo sem faixa.
static func tempo_forte() -> void:
	Som.tocar("sino", SINO_TV, -16.0)


## O som no alto-falante do lugar; sem alto-falante achado, na TV a −10 dB, na
## raia dele (a saída silenciosa), e a troca vai ao registro uma vez por lugar.
## A música abaixa nos dois casos (a pista). Devolve se foi ao controle.
static func falante(sala: Minigame, l: int, som: String, ganho := 0.9) -> bool:
	abaixar_a_musica(sala)
	if Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE) and Forja.som_falante(l, som, ganho) >= 0:
		return true
	var pos := Vector3(Minigame.RAIAS[l], 1.5, Minigame.Z_JOGADOR)
	if som.begins_with("nota:"):
		Som.tocar("nota", pos, -10.0, DO5_NA_TV * Minigame.TOM_DO_LUGAR[int(som.substr(5))])
	elif NA_TV.has(som):
		Som.tocar(NA_TV[som][0], pos, -10.0, NA_TV[som][1])
	var chave := "canto_troca_%d" % l
	if not sala.has_meta(chave):
		sala.set_meta(chave, true)
		sala.anotar("troca", l, {"de": "alto_falante", "para": "tv"})
	return false


## A música −12 dB em 17 ms, por 1 batida, e volta em 300 ms. A pista seguinte
## mata a volta e começa de novo. Sem o barramento "Musica" (H11), nada.
static func abaixar_a_musica(sala: Node) -> void:
	var i := AudioServer.get_bus_index("Musica")
	if i < 0:
		return
	if not sala.has_meta("canto_musica_db"):
		sala.set_meta("canto_musica_db", AudioServer.get_bus_volume_db(i))
	var base: float = sala.get_meta("canto_musica_db")
	var velho = sala.get_meta("canto_musica_tw", null)
	if velho is Tween and (velho as Tween).is_valid():
		(velho as Tween).kill()
	var por := func(v: float) -> void: AudioServer.set_bus_volume_db(i, v)
	var tw := sala.create_tween()
	tw.tween_method(por, AudioServer.get_bus_volume_db(i), base + MUSICA_DB, 0.017)
	tw.tween_interval(60.0 / Ritmo.bpm)
	tw.tween_method(por, base + MUSICA_DB, base, MUSICA_VOLTA_S)
	sala.set_meta("canto_musica_tw", tw)


## A música volta ao volume de antes (o minigame que sai no meio da pista).
static func soltar_a_musica(sala: Node) -> void:
	var i := AudioServer.get_bus_index("Musica")
	if i >= 0 and sala.has_meta("canto_musica_db"):
		AudioServer.set_bus_volume_db(i, float(sala.get_meta("canto_musica_db")))


## O ouvido do robô: o som que acabou de sair do alto-falante simulado do
## lugar ({t, som}: t é quando o jogo o mandou), ou {} (nada novo). Um som
## conta quando o som_seq muda e o nível passa de 0,12 em até 0,1 s: o que
## não saiu do alto-falante, o robô não ouviu. `o` é o estado do lugar ({}).
static func ouvir(l: int, o: Dictionary) -> Dictionary:
	var sv := Forja.som_virtual(l)
	var agora := Ritmo.t_musica()
	var seq := int(sv.get("som_seq", 0))
	if seq != int(o.get("seq", 0)):
		o["seq"] = seq
		o["espera"] = {"t": agora, "som": str(sv.get("som", ""))}
	var e: Dictionary = o.get("espera", {})
	if e.is_empty():
		return {}
	if float(sv.get("falante", 0.0)) > 0.12:
		o["espera"] = {}
		return e
	if agora - float(e.t) > 0.1:
		o["espera"] = {}
	return {}


## A barra de luz na cor do lugar, com o brilho `forca` (nunca abaixo de 0,3: F04).
static func luz_da_nota(l: int, forca: float) -> bool:
	var c := Forja.cor_do_lugar(l)
	var k := clampf(forca, 0.3, 1.0)
	return Forja.luz(l, Color(c.r * k, c.g * k, c.b * k))
```

O `so_o_dono` lê `_raias` do kit (H04: `lugar -> {raiz, mat_borda, luz}`). O néon da `atmosfera` é da G15, que passa
os materiais pelo `Tema.neon`: esta ficha não mexe nele. O `passar` não mexe na câmera quando o modo é `corrida` (o
Eco do Abismo): lá quem anda é a G05.

### A montagem do Canto

- Por lugar presente: `raia(l)`; `posicionar(l)`; `jogador(l).rotation.y = 0.0` (de frente para a câmera, o sino ao
  lado) e `jogador(l).preso = true`.
- `_sinos[l] = CenarioDoCanto.suporte(self, l)`, mais `"trincas"` (as três caixas escondidas), `"aros"` (`[]`),
  `"brilho_ate"` (−1) e `"balanca_ate"` (−1).
- O sino grande e o resto: `CenarioDoCanto.montar(self)`.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos já existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a chamada | — (sem alto-falante: `nota` ou `nota_alta` a −10 dB na raia) | `"nota"` (grave) ou `"nota_alta"` (aguda), 0,9 | `mod_nota`, `mod_nota_alta`; `sint_nota`, `sint_nota_alta` |
| a resposta certa | `Som.tocar("nota", pos_do_sino, -4 ou -9, tom × altura)` | — | `sint_nota` |
| a resposta errada | `Som.tocar("nota", pos_do_sino, -12, tom × altura × 0,9659)` e a falha do kit (−6) | — | `sint_nota`, `falha_0..2` |
| a frase inteira | `Som.tocar("sino", pos_do_sino, -12, tom)` | — | `sint_sino` |
| o sino bate no chão | `Som.tocar("sino", chao, -6, tom × 0,9659)` | — | `sint_sino` |
| o sino no chão, a cada batida | `Som.tocar("sino", chao, -18, tom × 0,9659)` | — | `sint_sino` |
| o tempo forte | `Som.tocar("sino", SINO_TV, -16)`, em todo compasso | — | `sint_sino` |
| o pico | `Som.tocar("sino", SINO_TV, -4)`, três vezes | — | `sint_sino` |
| a bancada: o canto da TV e a revelação | `Som.tocar("nota"/"nota_alta", SINO_TV, -2)`; `Som.tocar("sino", SINO_TV, -8)` | o canto às cegas, 0,9 | `sint_nota`, `sint_nota_alta`, `sint_sino`; `mod_nota`, `mod_nota_alta` |
| a faixa | `MUS_S06_J26`: 110 BPM, Dó menor, 150 s; até ela existir, a reserva `sint_trilha` da H05 | — | `mus_s06_j26` |

- **A música abaixa na pista.** A seção pede «na pista, −12 dB por 1 tempo, volta em 300 ms»: o
  `CenarioDoCanto.falante` chama `abaixar_a_musica` em toda chamada. Na chamada inteira (até 8 notas em 4 batidas),
  a música fica baixa; na resposta, volta.
- **O alto-falante só toca a chamada.** `nota_no_falante` false: o kit não põe `nota:<l>` nem `nota_quebrada:<l>`
  nele, e o Canto não põe nada na resposta. Por isso o julgamento `jul_*` (H11) também não vai ao alto-falante deste
  minigame: a H11 lê `nota_no_falante` (o canal é a pista).
- **A `bigorna_aguda` sai** do Canto: a revelação da bancada toca o `sino`.
- **A mixagem do resto é da H11**: o Ambiente −6 dB no minigame. O Canto só mexe no barramento «Musica», pela pista.
- O material `"metal"` da FICHA: o kit toca `mod_material_metal` nos atuadores no acerto (H07/H08).

## O controle

Evento por evento, para quem joga e para os outros. O piso é o da F05; o gatilho usa os modos de `forja.gd`.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a chamada | só o dono | — | — | — (nunca: entregaria a vez sem o som) | `nota` / `nota_alta`, 0,9 |
| a resposta BOM ou ÓTIMO | o dono | `acerto` (0,3 / 0,6, 80 ms; o kit, ou a textura `metal` na háptica) | — | 60 % da cor por 0,12 s, e volta a 100 % | — |
| a resposta PERFEITA | o dono | `perfeito` (0,5 / 0,8, 100 ms; o kit) | — | o kit: branco 0,15 s (sem flashes: parada) | — |
| a resposta errada ou perdida | o dono | `erro` (0,7 / 0,3, 160 ms; o kit) | — | o kit: a cor escurecida 0,5 s | — |
| o sino bate no chão | o dono | `golpe` (1,0 / 0,6, 250 ms) | R2 em Resistência (2, 4) por 250 ms, depois Off | — | — |
| começar | todos | — | `gatilhos_off(l)`: o L2 é do item (G03) | a cor do lugar, 100 % | — |

- A barra de luz é **sempre a cor do lugar** (30 % a 100 %, o piso da F04). Fora da bancada, nunca pergunta.
- As luzinhas de jogador mostram o número do lugar, sempre.
- O microfone não se usa.
- **Os outros não ouvem a chamada de um** no controle deles: só a TV (a resposta) é de todos.

### O robô

```gdscript
# O robô ouve o alto-falante simulado dele (CenarioDoCanto.ouvir: o som que
# saiu de verdade) e guarda o instante e o som de cada ataque. Na resposta,
# toca só as notas cuja chamada ele ouviu (um compasso antes, menos a
# antecedência dele), com a altura que ouviu, no tempo. Quando não acerta,
# aperta a outra altura (desafina).
var _ouvido := [{}, {}, {}, {}]
var _robo_ouviu := [[], [], [], []]  ## lugar -> [[t, som], ...], os últimos 8
var _robo_feita := [-1, -1, -1, -1]  ## o n da última nota respondida
var _robo_bancada := [false, false, false, false]  ## ouviu o canto às cegas


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var a := CenarioDoCanto.ouvir(l, _ouvido[l])
	if not a.is_empty():
		_robo_ouviu[l].append([float(a.t), str(a.som)])
		if _robo_ouviu[l].size() > 8:
			_robo_ouviu[l].pop_front()
		if Forja.bancada and estado_bancada == CANTO:
			_robo_bancada[l] = true
	if Forja.bancada and estado_bancada != JOGO:
		_robo_da_bancada(l)  # a pergunta de hoje: ✕ se ouviu o canto às cegas, ○ se não (canto.gd:592-598)
		return
	var batida := 60.0 / Ritmo.bpm
	for nn in notas_em_aberto(l):
		if nn <= int(_robo_feita[l]):
			continue
		var t := alvo_da(l, nn)
		if Ritmo.t_musica() < t:
			return
		_robo_feita[l] = nn
		var quando := t - 4.0 * batida - CenarioDoCanto.antecedencia(l)
		for o in _robo_ouviu[l]:
			if absf(float(o[0]) - quando) <= 0.12 and SOM.has(str(o[1])):
				var altura := SOM.find(str(o[1]))
				if not Forja.robo_acerta():
					altura = 1 - altura
				Forja.robo_apertar(l, BOTAO[altura], 0.06)
		return
```

O `_robo_da_bancada(l)` é o trecho da pergunta do `_robo` de hoje (`canto.gd:592-598`), com `_robo_bancada[l]` no
lugar de `e.robo_ouviu`; ele volta a `false` no `_comecar_canto`. O robô **não** lê a partitura: se a chamada não
saiu do alto-falante simulado, ele não responde. É a prova do caminho inteiro, e a do simulador: a mesma conta roda no
controle simulado da prova do jogo e no da prova visual.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como estão,
de frente para a câmera, ao lado do sino. `posicionar(l)` deixa as mãos livres: a arma ou o amuleto não aparece, mas
o efeito do item vale. O cavaleiro pode ser de outra raça (G08, parte B; a montagem é da G13): esta ficha não supõe corpo
humano; usa só o esqueleto comum de 7 ossos e as animações `idle` e `emote-no`.

| stat | gancho | o que muda no Canto | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: nada empurra | — | — | — |
| Passo | `velocidade` | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | quanto o sino caído leva para voltar ao braço | 1,25 batida | 1 batida | 0,75 batida |
| Faro | `pista` | a chamada sai antes; a resposta fica no tempo | 40 ms depois | no tempo | 40 ms antes |
| Faro | `raio` | não age: nada se procura no escuro | — | — | — |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Lanterna adianta a chamada meio tempo (0,27 s a 110 BPM,
`Itens.antecipacao_s`); o Martelo dobra o perfeito no tempo forte (o kit); a Âncora não age (nada empurra); o
Diapasão não age (o Canto é `tct`, e o Diapasão nunca age no `tct`). Nenhum stat muda a janela de julgamento.

```gdscript
## O conserto: o sino volta ao braço na queda do Fôlego (1 tempo), curva BACK.
func _consertar(l: int) -> void:
	var s: Dictionary = _sinos[l]
	_caido[l] = false
	var dur := CenarioDoCanto.queda(l, 1.0) * 60.0 / Ritmo.bpm
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(s.pivo, "position", s.base, dur)
	tw.tween_property(s.pivo, "rotation:z", 0.0, dur)
	Efeitos.faiscas(self, s.base, Tema.TUNGSTENIO, 24, 1.2)
```

O erro não tem squash. O desregistro do erro (o contorno de 2,4 a 0,6, o tremor de ±0,02 m por 3 quadros, a
animação a 0,5×) é do kit e da G08; o Canto só soma a trinca, o tranco e o `emote-no`.

## As reações

- **Carimbos que o Canto pode disparar** (todos são do kit e do HUD, G04; o Canto não chama nenhum): `car_em_chamas`
  (5 Ressonâncias seguidas do mesmo lugar), `car_acorde` (os quatro na Ressonância no mesmo tempo 1: só no
  uníssono da reta, cuja primeira nota cai no tempo 1 do compasso para os quatro), `car_por_um_fio` (o vencedor por
  2 % dos pontos ou menos, no resultado). O `car_virada` é do placar, não do minigame.
- **Adesivos:** ninguém está fora da rodada no Canto, então ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: o sino torto** (`sino_torto`). A terceira trinca derruba o sino do cavaleiro: ele solta do braço, rola
para o lado do vizinho e bate no chão na colcheia, desafinado; a luz das outras raias cai. Degrau estrondo (tremor de
0,05 m por 2 batidas, hit-stop de 3 quadros, 48 faíscas). No chão, toca torto a cada batida até a próxima
frase inteira.

- **Rastro:** o sino no chão até o conserto; os aros no poste, um por frase inteira, até o fim.
- **A curva:** de 0 a 30 s, frases de uma nota; de 30 a 60 s, o pico (duas notas em colcheia, o sino grande três
  vezes, a luz +20 %); de 60 s ao fim, duas notas, e nas últimas 16 batidas o uníssono (os quatro respondem a
  mesma frase no mesmo tempo, e a TV faz um acorde ou racha). Não é regra nova: é a frase de todos.
- **A mudança: o coro na TV.** A chamada é o segredo da mão; a resposta de cada um toca na TV no timbre do sino dele.
  Os quatro em hoqueto formam uma frase na TV, e a sala ouve quem desafinou.
- **Ensina sem falar:** a primeira resposta de cada um mostra o botão sobre o sino (o grave embaixo, o agudo em
  cima), e os botões na mão seguem a mesma altura (✕ embaixo, ○ em cima).
- **Quem está perdendo:** o sino caído volta inteiro na próxima frase certa (2 compassos); a partitura simples dá
  uma nota só a quem está errando.
- **A nota de hoje:** 2 (o índice da seção). Com o coro na TV e o sino que rola, sobe para 3.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 (a primeira resposta cai em 4,4 s) | o quadro de 10 s mostra um sino balançando ou um aro no poste |
| 4. o momento | pelo menos 2 linhas `momento` `sino_torto` entre 0 e 90 s, pelo menos 1 do P4 | um sino no chão em 1 quadro de cada 5 |
| 5. a curva | notas por segundo no 2.º terço ≥ 1,5 × as do 1.º (a conta dá 2,5 ×); no 3.º ≥ 1,0 × (dá 2,0 ×); a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a luz 20 % acima do quadro do meio do 1.º |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | 1 quadro em 5 mostra o sino do P4 rachado ou no chão |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `sino_torto` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 (P1: 0,29; P4: 0,71; altura 0,09) | o sino caído se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `sino_torto`, uma linha `sensacao` `golpe` a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte ainda mostra o sino no chão |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem das frases no `momento` `reta` e no fim | no quadro de 85 s, quem olha diz a ordem pelos aros, e ela bate com o registro |

A prova do jogo faz a mesa padrão com a mesa da prova (em «Provas»: o robô `bom` e o erro sorteado por cima dele,
lugar a lugar) e confere os itens 1, 4 (com o «do P4»), 5, 8, 9 e 10. Os itens 6 e 7 esperam o robô por lugar
(`--robo=bom,medio,medio,ruim`), que a F09 não faz.

## Pronto quando

O Canto joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo que cai
e volta; fecha sempre com vencedor; `--sala=canto` abre o `S06_J26`; o sino cai pelo menos 2 vezes em 90 s e o
uníssono acontece nas últimas 16 batidas; com `--bancada`, o canto às cegas aparece nas chamadas 3, 9, 15, 21, 27 e 33
e o veredito `alto_falante` sai como antes; a prova do jogo passa (sem e com `--bancada`); e
`bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `SALA=canto bash tests/prova_do_jogo.sh` (a prova rápida e o Canto inteiro, nas duas rodadas do sh: sem e
com `--bancada`), `bash tests/prova_do_jogo.sh` (o jogo inteiro) e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a checagem do Canto usa o `_joga_o_minigame(apelido, limite_s, a_cada_quadro)`
da H08 (abre pelo catálogo, deixa o aviso passar em quadros e espera o fim pelo relógio de parede: 90 s de música e
o treino cabem em 130 s). Ela entra no `match` do `_prova_da_ficha(slot)` da H08, numa linha, como o molde pede (não
no percurso): `"S06_J26", "canto": await _prova_do_canto()`.

**A mesa da prova.** A `prova_do_jogo.sh` roda o jogo com `--robo` sem valor, que é o `bom` da F09 (95 % de acerto),
e não repassa argumento nenhum. Com o `bom` nos quatro, o sino quase nunca cai. A prova então erra por cima do robô,
lugar a lugar, com a chance de `ERRO_DA_MESA` (0, 30 %, 30 % e 68 %: o acerto fica perto de 95 %, 66 %, 66 % e 30 %,
a mesa padrão), pela semente 7. O erro padrão é a nota que passa sem toque, o mesmo caminho do `_passaram`. As três
peças abaixo são da N1 e ficam na prova; N2 a N5 as chamam (com o erro delas, quando é outro):

```gdscript
## A mesa padrão na prova (bom, medio, medio, ruim): o robô da
## prova_do_jogo.sh é o `bom`, e a prova erra por cima dele, por lugar.
const ERRO_DA_MESA := [0.0, 0.3, 0.3, 0.68]
var _mesa_rng := RandomNumberGenerator.new()
var _mesa_vistas := [{}, {}, {}, {}]


## Antes de cada minigame: a mesma semente, nenhuma nota vista.
func _mesa_comeca() -> void:
	_mesa_rng.seed = 7
	_mesa_vistas = [{}, {}, {}, {}]


## A cada quadro: 50 ms antes do alvo de cada nota em aberto (antes do robô,
## que aperta no alvo), sorteia uma vez; se cair, erra a nota. Sem `errar`, a
## nota passa sem toque (o _passaram da N1); `errar.call(l, nn)` faz outro erro.
## O `mg` vem sem tipo: `_ultima` e `_info` são do minigame, não do kit.
func _mesa(mg, chances: Array, errar := Callable()) -> void:
	var agora := Ritmo.t_musica()
	for l in mg.presentes():
		if not mg.conectado(l):
			continue
		for nn in mg.notas_em_aberto(l):
			if _mesa_vistas[l].has(nn) or agora < mg.alvo_da(l, nn) - 0.05:
				continue
			_mesa_vistas[l][nn] = true
			if _mesa_rng.randf() >= float(chances[l]):
				continue
			if errar.is_valid():
				errar.call(l, nn)
			else:
				mg._ultima[l] = mg._info[l].get(nn, {})
				mg.nota_perdida(l, nn)
```

A checagem do Canto:

```gdscript
## O Canto (S06_J26): o apelido abre o minigame; a chamada sai do alto-falante
## simulado; o sino que cai põe o R2 em Resistência; o registro tem a chamada,
## a resposta e os momentos.
func _prova_do_canto() -> void:
	var tocou := [false]
	var resistencia := [false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.3:
				tocou[0] = true
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				resistencia[0] = true
		_mesa(mg, ERRO_DA_MESA)
	_mesa_comeca()
	var mg = await _joga_o_minigame("canto", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S06_J26", "Canto: --sala=canto abre o S06_J26")
	_esperar(tocou[0], "Canto: a chamada saiu de um alto-falante simulado")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.frases[v[0]]) == v.map(func(l): return int(mg.frases[l])).max(), "Canto: o vencedor tem mais frases inteiras")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S06_J26")
	var pistas := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("evento") == "mandou")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	var tortos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "sino_torto")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(pistas.any(func(e): return bool(e.get("no_controle", false))), "Canto: %d chamadas, alguma no controle" % pistas.size())
	for l in mg.presentes():
		_esperar(toques.any(func(e): return int(e.get("jogador", 0)) == l + 1 and float(e.get("t_musica", 99.0)) <= 10.0), "Canto: o P%d tocou até 10 s" % (l + 1))
	_esperar(tortos.size() >= 2, "Canto: %d sinos tortos (o mínimo é 2)" % tortos.size())
	_esperar(tortos.any(func(e): return int(e.get("jogador", 0)) == 4), "Canto: o sino do P4 caiu (o da mesa que mais erra)")
	_esperar(tortos.is_empty() or resistencia[0], "Canto: o sino que cai põe o R2 em Resistência (0x21)")
	_esperar(reta.size() == 1, "Canto: a linha momento reta aparece uma vez")
	for a in tortos:
		_esperar(float(a.get("x_tela", 0.0)) >= 0.2 and float(a.get("x_tela", 0.0)) <= 0.8 \
			and float(a.get("altura_tela", 0.0)) >= 0.08, "Canto: o sino torto no meio da tela (%s)" % [a])
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("sala", e.get("slot", "")) == "S06_J26").is_empty(), "Canto: fora da bancada, nenhuma pergunta")
```

(`_linha_do_tempo` é da F01 e já está na prova. No registro, `jogador` é o número do controle (1 a 4) e `lugar`, o
índice (0 a 3): a checagem compara `jogador` com `l + 1`. As checagens que hoje olham `"canto"` pelo id, como as de
`SO_COM_PERGUNTA`, passam a olhar pelo apelido com `_e_a_sala` da H04.)

### O que o registro mede

- `som_controle` (H07) de cada chamada: `seq`, `som`, `placa`; a `troca` `alto_falante` → `tv` de quem não tem
  alto-falante (uma por lugar).
- `pista` (`canal` `alto_falante`: n da resposta, som, `no_controle`) e o `toque` do kit com o mesmo `n`: a chamada que
  não chegou vira resposta errada ou nenhuma.
- `sensacao` `golpe` (F05) no sino que cai; `momento` `sino_torto` e `reta`.
- Na bancada, além disso, a `pergunta` (`"canto"`), a `resposta` de hoje e o veredito `alto_falante`.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a cada 2 s): o quadro de 10 s (um sino
balançando), o de 45 s (a luz do pico e a câmera mais longe), os quadros com um sino no chão (1 em cada 5), o de 85 s
(a ordem dos aros, anotada aqui na ficha) e os das últimas 16 batidas (os quatro sinos balançando juntos).

### O que o André joga e sente

`./run-local.sh -- --sala=canto`, com quatro DualSense, dois no cabo e dois no rádio:

- a frase sai da própria mão e dá para repetir sem olhar a tela; o grave e o agudo se distinguem no alto-falante;
- a música abaixa na chamada e volta na resposta;
- a resposta de cada um toca na TV, e a roda (P1, P2, P3, P4) soa como uma frase inteira; quem erra, racha;
- o sino que cai bate no chão no tempo, o R2 endurece por um instante, e o sino toca torto até a frase certa;
- no uníssono da reta, os quatro sinos tocam juntos;
- com `--bancada`, o canto às cegas seis vezes, e só nela.

### Armadilhas

- **A barra de luz nunca muda na chamada:** ela entregaria a vez e o ritmo sem o som. Só na resposta.
- **Um som por vez no controle** (H07): a chamada é o único som do alto-falante no Canto. Se outra ficha ligar
  `nota_no_falante` ou o `jul_*` no alto-falante, a frase seguinte corta.
- **A saída silenciosa:** sem alto-falante, a chamada vai para a TV, o `pista` diz `no_controle: false` e a `troca`
  vai ao registro; o jogo não trava nem pula o lugar.
- **O `_ultima[l]`** tem de estar posto antes de `julgar_nota`/`nota_perdida`: o kit chama `toque`/`falha` de
  dentro deles, na mesma linha.
- **`_notas` é do kit.** Declarar outra `_notas` no minigame esconde a do kit e quebra `casar_toque`.
- **O mundo se mexe pela batida:** a chamada, o sino que cai e o uníssono tomam o tempo de `Ritmo.t_musica()`; o
  pulso da barra de luz pode usar `dt` (é enfeite).
- **O treino** julga igual e não soma (`marcar`); o sino racha no treino também.
- **A música:** sem o `_exit_tree` com `soltar_a_musica`, o minigame que acaba no meio da pista deixa a faixa
  seguinte a −12 dB.
- **O `CenarioDoCanto.gancho`** procura a classe `Cavaleiro` na lista de classes globais; sem a G13, devolve o neutro
  e o Canto joga como o stat 3.

### Ao terminar

- No [quadro](README.md): a linha **N1**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: O Canto no kit, chamada e resposta no alto-falante, o coro na TV e o cenário comum da seção`
