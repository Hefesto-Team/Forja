# N4 — Código do Dragão

**Sprint:** N · **Slot:** S06_J29 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, N1, H07

## Por quê

A memória da seção. O dragão sussurra uma senha no controle de cada um — a
de cada um é diferente, e ninguém mais ouve a sua. Repetida inteira, ela
cresce uma nota; errada, o dragão cospe fumaça e a senha recomeça em três.
É o "Simon" do alto-falante, com a pista privada da lição 12 de
[10](../10-a-regua-astro-bot.md). O verbo aqui é **decorar**: a resposta não
vem logo depois de cada nota (como no Eco) nem copia uma frase curta (como
n'O Canto) — é a sequência inteira, de cabeça.

## Ler antes

- [O índice da seção](N-o-canto.md) e a [N1](N1-o-canto.md) (o cenário comum, o robô que ouve, o `_joga_o_minigame`)
- [O molde de minigame](molde-de-minigame.md) e o [kit](../13-arquitetura.md#o-kit-do-minigame--h04)

## A ficha de dados

`godot/scripts/minigames/s06/codigo_do_dragao.gd`:

```gdscript
extends Minigame
## Código do Dragão (S06_J29) — o dragão canta uma senha no alto-falante do
## controle de cada um, uma nota por batida: grave (✕), média (○) ou aguda
## (△). Depois de uma batida de silêncio, repita a senha inteira, uma nota
## por batida. Inteira e no tempo, ela cresce uma nota (até doze). Errou, a
## senha recomeça em três, nova. No pico, o dragão canta em colcheias (a
## resposta continua nas batidas).
##
## A falha: o dragão cospe fumaça em quem errou, que tosse e recua, e a
## senha dele volta a três notas.
## O vencedor: a senha mais longa repetida inteira; no empate, mais pontos.
## O alto-falante do dono: a senha (a protagonista).
## O registro mede: cada nota da senha (o som, se foi ao controle) e a
## resposta dela (o toque do kit com o mesmo n).
## O robô: conta os ataques que ouviu no alto-falante simulado; repete, no
## tempo, só as notas que ouviu, com a altura que ouviu (H08); quando não acerta,
## 250 ms tarde.
## Com menos de quatro: nada muda (cada um tem a sua senha e o seu tempo).
## A régua: (1) "Decore!" com o dragão olhando para cada um; (2) sim: a senha
## só existe no controle; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J29",
	"titulo": "Código do Dragão",
	"verbo": "Decore!",
	"genero": "tct",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ, Forja.CIRCULO, Forja.TRIANGULO],
	"camera": "fixa",
	"faixa": "MUS_S06_J29",
	"duracao": 100.0,
	"fim": "tempo",
	"sensacoes": ["toque", "acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Decore!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca a nota do perfeito nele (H08)
}

const PONTOS := [0, 10, 20, 30]  ## por nota da resposta
const POR_NOTA_DA_SENHA := 20  ## a senha inteira vale isto vezes o comprimento
const INICIO := 3
const MAXIMO := 12
## As três notas da senha (docs/jogo/tarefas/N-o-canto.md): grave, média, aguda.
const SOM := ["nota:0", "nota", "nota_alta"]
const BOTAO := [Forja.CRUZ, Forja.CIRCULO, Forja.TRIANGULO]
const PULSO_S := 0.12
```

## Como se joga

**Cada um tem o seu ciclo**, todos no mesmo relógio (batidas da faixa), e
nenhum espera o outro. O ciclo de um lugar começa numa batida de começo de
compasso `S` (a primeira é a batida 4, depois da contagem):

1. **A senha canta:** `L` notas (`L` começa em `INICIO`), na batida
   `S + i * p` para `i` de 0 a `L − 1`, com `p = 1` (entrada e saída) ou
   `p = 0,5` (o **pico**, 33–66 s; quem está com `Ritmo.simples[l]` fica em
   `p = 1`). A nota `i` é `senha[l][i]` (0, 1 ou 2), tocada com
   `var foi := CenarioDoCanto.falante(self, l, SOM[senha[l][i]], 0.9)` e
   `anotar("pista", l, {"n": <n da resposta i>, "evento": "mandou", "canal": "alto_falante", "o_que": SOM[...], "no_controle": foi})`.
2. **Uma batida de silêncio:** a resposta começa em
   `A = ceilf(S + L * p) + 1`.
3. **A resposta:** `L` notas nas batidas `A + i`:
   `{"n": int(round((A + i) * 2)), "b": A + i, "t": Ritmo.t_da_batida(A + i), "i": i, "altura": senha[l][i]}`,
   com `nova_nota` quando o ciclo começa. O botão da altura (✕ grave, ○
   média, △ aguda) a até `Ritmo.JANELA_BOM` → `julgar_toque(l, t, n)`; o
   botão errado → `nota_perdida(l, n)`; a nota que passa → `nota_perdida(l, n)`.
4. **O fim do ciclo:** a resposta inteira BOM ou melhor → `recorde[l] = maxi(recorde[l], L)`,
   `marcar(l, POR_NOTA_DA_SENHA * L)`, e a senha ganha uma nota sorteada
   no fim (`L + 1`, até `MAXIMO`; em `MAXIMO`, recomeça em `INICIO` nova e
   o dragão faz uma reverência). A primeira falha da resposta → as notas
   que faltavam somem sem erro, e a senha recomeça em `INICIO`, nova.
   O próximo ciclo começa no primeiro começo de compasso depois de
   `A + L + 1`.

A senha é sorteada pelo `rng` (da semente), uma por lugar: com quatro, são
quatro senhas diferentes, cada uma no seu controle.

**Os pontos** de cada nota: `marcar(l, PONTOS[julgamento])` (o item, `Itens.pontos_do_acerto`, o kit já aplica no `julgar_toque`: H08).

**O compasso na mão:** `Forja.sentir(l, "toque")` no começo de cada compasso
e `CenarioDoCanto.tempo_forte()`.

**Os 100 segundos:** entrada (0–33 s), a senha em batidas; **pico**
(33–66 s), o dragão acelera — a senha em colcheias — e aos 33 s ele ruge
(`Som.tocar("golpe", Vector3(0, 4, -6), -2.0)`, os olhos dele acendem a 3,0
e `tremer(TREMOR_GOLPE)`); saída (66–100 s), batidas de novo, com as senhas
longas de quem chegou lá.

## O cenário

- `CenarioDoCanto.montar(self)`; a câmera um pouco mais longe, para o dragão:
  `camera_pos = Vector3(0, 6.2, 12.0)`, `camera_olhar = Vector3(0, 2.0, -2.0)`.
- Por lugar: `raia(l)`, `posicionar(l)`, `preso = true`, e o sino pequeno
  com o suporte (N1), que balança na resposta boa dele. **A senha do lugar
  no mundo:** uma fileira de `MAXIMO` pedrinhas `Kit.caixa(self, Vector3(0.14, 0.14, 0.14), Vector3(RAIAS[l] - 0.9 + 0.16 * i, 0.12, Z_JOGADOR + 1.3), pedra)`
  no chão na frente dele; as `recorde[l]` primeiras acesas na cor do lugar
  (emissivo 1,2): o placar, sem dizer as notas.
- **O dragão** (peças do kit mais um brilho, na proporção chibi: cabeça
  grande), no fundo, no meio, atrás do sino grande: o corpo
  `Kit.peca(self, "wall", Vector3(0, 0, -6.6), 0.0, 2.4)`, o pescoço de
  duas `Kit.peca(pescoco, "column", ..., 0.0, 1.2)` num `Node3D` pivô em
  `(0, 2.4, -6.2)`, a cabeça `Kit.caixa(pescoco, Vector3(2.4, 1.6, 1.8), Vector3(0, 2.6, 0.4), Kit.material(Color("#5e5870"), 0.0, 0.95))`,
  o queixo `Kit.caixa(pescoco, Vector3(2.0, 0.5, 1.6), Vector3(0, 1.7, 0.5), escura)`
  (abre com `rotation.x` 0,3 quando canta), dois olhos
  `Kit.caixa(pescoco, Vector3(0.36, 0.2, 0.1), Vector3(±0.6, 2.9, 1.32), Kit.material(Color("#ff4a2a"), 1.6))`
  e dois chifres `Kit.caixa(Vector3(0.18, 0.6, 0.18))` inclinados. A cabeça
  gira para a raia de quem está ouvindo a senha agora (o `pivo.rotation.y`
  para `atan2(RAIAS[l], 6.2)`, com tween de 0,2 s) — com quatro, gira para
  quem começou o ciclo por último.
- O checklist do 11: o dragão é peça do kit e caixa, com o olho de brilho;
  nada liso nem metálico.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **alto-falante (protagonista)** | a senha: `"nota:0"` (grave), `"nota"` (média), `"nota_alta"` (aguda), 0,9 | na fase de canto do ciclo dele |
| vibração | `toque` | no começo de cada compasso |
| vibração | `acerto` / `perfeito` / `erro` (o kit) | em cada nota da resposta |
| vibração | `golpe` | a fumaça do dragão (a falha) |
| barra de luz | `CenarioDoCanto.luz_da_nota(l, 0.6)` por `PULSO_S`, e volta a 1,0 | em cada nota boa da resposta — nunca no canto |
| luzinhas de jogador | o número, sempre | — |
| háptica por material | `"pedra"` (o kit, no cabo) | — |
| gatilho | `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` no `montar` | nada a segurar |
| som na TV | a nota do kit na resposta; `"confirma"` na senha inteira; o sopro da fumaça (`"sopro"`) | — |

## A falha

- **A fumaça:** a cabeça do dragão gira para quem errou, o queixo abre e
  sai fumaça (`Efeitos.faiscas(self, Vector3(RAIAS[l], 1.4, Z_JOGADOR - 0.6), Color("#9a9eb8"), 40, 1.2)`
  e `Som.tocar("sopro", ...)`); o cavaleiro tosse e recua meio passo
  (`gesto("emote-no", 0.6)`, tween de z +0,5 e volta em uma batida);
  `Forja.sentir(l, "golpe")`.
- **A senha recomeça:** as pedrinhas acesas do placar ficam (o recorde é
  dele); a senha nova tem três notas.
- **A recuperação:** o próximo ciclo começa no compasso seguinte.

## O fim e o vencedor

100 s de música, pelo kit (H08).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(recorde[a]) != int(recorde[b]):
			return int(recorde[a]) > int(recorde[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

## Com menos de quatro

- **Três, dois e um:** nada muda — cada um tem a sua senha e o seu ciclo;
  com menos, o dragão olha mais tempo para cada um.
- **O controle que cai:** o ciclo dele para (as notas somem sem erro, a
  senha e o recorde ficam); quando volta, começa um ciclo novo com a mesma
  senha, no compasso seguinte.

## O robô

```gdscript
# O robô conta os ataques que ouve no alto-falante simulado durante o canto
# (a lógica de ataque da N1) e responde só as notas que ouviu, com a altura
# que ouviu (`Forja.som_virtual` dá o nome do último som: H08), no tempo de
# cada uma. Quando não acerta, 250 ms tarde.
var _robo_vale := [1.0, 1.0, 1.0, 1.0]
var _robo_desde := [0.0, 0.0, 0.0, 0.0]
var _robo_ouvidas := [0, 0, 0, 0]  ## os ataques ouvidos no canto do ciclo de agora
var _robo_sons := [[], [], [], []]  ## o som de cada ataque ouvido, na ordem
var _robo_ciclo := [-1.0, -1.0, -1.0, -1.0]
var _robo_nota := [-1, -1, -1, -1]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if _ciclo[l].is_empty():
		return
	if float(_ciclo[l].S) != _robo_ciclo[l]:
		_robo_ciclo[l] = float(_ciclo[l].S)
		_robo_ouvidas[l] = 0
		_robo_sons[l] = []
	var nivel := float(Forja.som_virtual(l).get("falante", 0.0))
	var agora := Ritmo.t_musica()
	if nivel > 0.12 and nivel - float(_robo_vale[l]) > 0.10 and agora - float(_robo_desde[l]) > 0.08:
		_robo_vale[l] = nivel
		_robo_desde[l] = agora
		if Ritmo.batida() < float(_ciclo[l].A):
			_robo_ouvidas[l] += 1
			_robo_sons[l].append(str(Forja.som_virtual(l).get("som", "")))  # o nome do último som (H08)
	else:
		_robo_vale[l] = minf(float(_robo_vale[l]), nivel)
	if _notas[l].is_empty():
		return
	var nt: Dictionary = _notas[l][0]
	if int(nt.n) != _robo_nota[l]:
		_robo_nota[l] = int(nt.n)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	if int(nt.i) < _robo_ouvidas[l] and agora >= float(nt.t) + float(_robo_atraso[l]):
		Forja.robo_apertar(l, BOTAO[maxi(SOM.find(str(_robo_sons[l][int(nt.i)])), 0)], 0.06)  # a altura que ouviu
		_robo_nota[l] = 99999
```

(No pico, as notas do canto vêm em colcheias: o "desde" mínimo é 0,08 s
para o robô não juntar duas. O robô mede pelo tempo de música, como o fim
do minigame: H08.)

## Os ganchos

```gdscript
var _notas := [[], [], [], []]  ## as notas de resposta do ciclo de agora
var _canto: Array = []  ## [lugar, batida, altura, n] a tocar
var _ultima := [{}, {}, {}, {}]
var _ciclo := [{}, {}, {}, {}]  ## lugar -> {S, A, L, p, falhou}
var senha := [[], [], [], []]
var recorde := [0, 0, 0, 0]
var _compasso := 0
var _fora := [false, false, false, false]
var _pulso := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 6.2, 12.0)
	camera_olhar = Vector3(0, 2.0, -2.0)
	CenarioDoCanto.montar(self)
	_montar_o_dragao()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.preso = true
		_montar_o_sino(l)
		_montar_o_placar_de_pedrinhas(l)
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	for l in presentes():
		senha[l] = _senha_nova()
		_comecar_ciclo(l, 4.0)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
		for l in presentes():
			if conectado(l):
				Forja.sentir(l, "toque")
	var agora := Ritmo.t_musica()
	_tocar_o_canto(agora)  # CenarioDoCanto.falante + a chamada; a cabeça do dragão
	for l in presentes():
		_apagar_o_pulso(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_comecar_ciclo(l, ceilf(Ritmo.batida() / 4.0) * 4.0 + 4.0)
		for k in 3:
			if Forja.apertou(l, BOTAO[k]):
				_responder(l, k)
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
		if not _ciclo[l].is_empty() and _notas[l].is_empty() and Ritmo.batida() >= float(_ciclo[l].A) + float(_ciclo[l].L):
			_fechar_o_ciclo(l)  # cresce ou recomeça; o próximo ciclo no compasso seguinte


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S


func falha(l: int) -> void:
	if bool(_ciclo[l].get("falhou", false)):
		return
	_ciclo[l].falhou = true
	_notas[l].clear()  # o resto da resposta some sem erro
	Forja.sentir(l, "golpe")
	_fumaca(l)
```

`_comecar_ciclo(l, S)` monta `_ciclo[l]` (`S`, `p` pela parte, `A`, `L`),
põe as notas do canto em `_canto` e as da resposta em `_notas[l]` (com
`nova_nota`). `_fechar_o_ciclo(l)` decide pelo item 4 de "Como se joga"
(sem falha: cresce; com falha: `senha[l] = _senha_nova()`) e chama
`_comecar_ciclo(l, <o começo de compasso seguinte a A + L + 1>)`.
`_responder(l, k)` acha a primeira nota da resposta a até `JANELA_BOM`, põe
em `_ultima[l]`, tira da lista e chama `julgar_toque` (altura certa) ou
`nota_perdida` (errada).

Catálogo: `"S06_J29"` em `MINIGAMES` e na lista da seção `S06`. O `.uid`.
Traduções: `"Código do Dragão": "Dragon's Code"`, `"Decore!": "Memorize!"`;
`dica(l)`: `{"partes": ["@cross", "Grave", "@circle", "Média", "@triangle", "Aguda"], ...}`
com `na_raia(l)` e `not aprendeu(l)` (`"Média": "Middle"`); `status(l)`:
`"Senha %d" % recorde[l]` (`"Senha %d": "Code %d"`).

## O que o registro mede

- `som_controle` (H07) de cada nota da senha e o `pista` (`canal` `alto_falante`) (n da
  resposta, som, `no_controle`).
- O `toque` do kit em cada nota da resposta. O cruzamento: senha inteira
  cantada com `placa` e resposta que para sempre na mesma posição num
  controle é o alto-falante que cortou; a senha curta repetida bem e a longa
  errada no mesmo ponto é memória, não alto-falante (o registro tem os dois).
- `{"o": "senha", "L": L, "inteira": bool}` no fim de cada ciclo.

## Armadilhas

- **Quatro senhas ao mesmo tempo, cada uma no seu controle:** é a pista
  privada; nunca toque a senha na TV (a não ser na saída silenciosa, sem
  alto-falante — e aí o registro diz `no_controle: false`).
- **A falha só uma vez por ciclo:** a primeira falha limpa a resposta; as
  notas que sobraram não viram erro.
- **O canto do pico em colcheias, a resposta nas batidas:** o `A` é
  arredondado para cima e mais uma batida de silêncio.
- **O dragão olha, a tela não conta a senha:** as pedrinhas mostram o
  recorde, nunca as notas.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque`
  (H08); marque cru.

## Pronto quando

O Código do Dragão joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com
o robô nos três temperamentos (o bom chega a senhas longas); aguenta o cabo
que cai e volta; fecha com vencedor (a senha mais longa); a prova do jogo
passa; e `bash tests/prova_visual.sh` passa com a **prancha olhada** com o
Dragão nela (o `Catalogo.sortear` da H08 põe o `S06_J29` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`).

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Código do Dragão (S06_J29): cada um tem a sua senha, entre 3 e 12 notas;
## o canto chega ao alto-falante; o vencedor tem a senha mais longa.
func _prova_do_dragao() -> void:
	var fora := [0]
	var olhar := func(m: Minigame) -> void:
		for l in m.presentes():
			var n := (m.senha[l] as Array).size()
			if n < m.INICIO or n > m.MAXIMO:
				fora[0] += 1
	var mg = await _joga_o_minigame("S06_J29", 140.0, olhar)
	if mg == null:
		return
	_esperar(fora[0] == 0, "Dragão: a senha sempre entre 3 e 12 notas")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.recorde[v[0]]) == v.map(func(l): return int(mg.recorde[l])).max(), "Dragão: vence a senha mais longa")
	var canto := _linha_do_tempo().filter(func(e): return e.get("tipo") == "pista" and e.get("slot") == "S06_J29" and e.get("evento") == "mandou")
	_esperar(canto.size() >= 3, "Dragão: %d notas de senha cantadas" % canto.size())
```

**O que o André joga e sente** (`./run-local.sh -- --sala=S06_J29`):

- as três alturas se distinguem no alto-falante pequeno, com a música na TV;
- a senha dos outros não atrapalha (cada controle canta na sua mão);
- o pico em colcheias é difícil e engraçado; a fumaça faz rir;
- a senha longa (oito, dez notas) dá orgulho — e as pedrinhas mostram para todos.

## Ao terminar

- No [quadro](README.md): a linha **N4** (se não existir, acrescente
  `| [N4](N4-codigo-do-dragao.md) | N | S6 — Código do Dragão | M | Sonnet | 1,5 | feito (<commit>) | <gasto> |`),
  com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Código do Dragão — a senha que só o seu controle canta`
