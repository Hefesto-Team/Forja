# L4 — Martelos Térmicos

**Sprint:** L · **Slot:** S04_J19 · **Tamanho:** M · **Depende de:** H04, H08, F09, L1, G08, G14, G15

## Por quê

O todos contra todos da seção, e o único em que a tela mostra as duas possibilidades: duas toupeiras de metal
sobem juntas, iguais aos olhos, e só a mão sabe qual é a quente; no pico, às vezes as duas são quentes e a mão
sente os dois lados de uma vez. O Cerco defende o lado que vem; aqui se ataca o lado que queima.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [L1 — O Cerco, «A cena»](L1-o-cerco.md#a-cena): o cenário comum inteiro (o `escuro`, a lanterna da vida, o exagero) está em
  «A cena», no código de `cenario_do_impacto.gd`; o modelo (o hoqueto, a pista de um lado, o robô, o `momento`) está em «Como se joga»,
  «O controle» e «O robô». Se a L1 já entrou, valem `cenario_do_impacto.gd` e `o_cerco.gd` em
  `godot/scripts/minigames/s04/`.

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) está copiado nesta ficha, com os números.
Onde o índice da seção (`L-o-impacto.md`) dá uma cor em hex ou outra câmera, vale a L1 (o `cenario_do_impacto.gd`).

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s04/martelos_termicos.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S04_J19` em `MINIGAMES` e na lista da seção `S04` de `SECOES` | **de todos** |
| `godot/scripts/traducoes.gd` | `"Martelos Térmicos": "Thermal Hammers"`, `"Martele!": "Hammer!"`, `"Esquerda": "Left"`, `"Direita": "Right"` (as que ainda não existirem) | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_dos_martelos()` e a chamada depois das outras da seção | **de todos** |
| `godot/scripts/minigames/s04/cenario_do_impacto.gd` | **não muda**: só chama | da seção (a L1 criou) |
| `godot/scripts/minigames/minigame.gd` | **não muda**: usa `momento()` (a L1 pôs) | de todos |
| `godot/scripts/salas/sala_jogo.gd` | **não muda**: usa `martelo_na_mao(p)`, que já existe | de todos |

O `.uid` novo (`martelos_termicos.gd.uid`) sai de `"$GODOT" --headless --path godot --import --quit` e entra no
commit.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Martelos Térmicos (S04_J19) — duas toupeiras de metal sobem dos dois lados
## de cada raia na batida do dono, iguais aos olhos. Uma é quente: a mão
## sente o lado dela uma batida antes (só o motor daquele lado). Martele o
## lado quente com L1 (esquerda) ou R1 (direita) na batida. No pico, às vezes
## as duas são quentes (os dois motores iguais): L1 e R1 juntos.
##
## A falha: martela a fria (ela afunda oca) ou não martela, e a quente queima
## a mão: um tremor longo, o R2 pesa, o cavaleiro sacode a mão.
## O vencedor: mais toupeiras quentes marteladas (a pilha de chapas); no
## empate, mais pontos.
## O alto-falante do dono: o julgamento do kit; sem vibração, a pista em tiques.
## O registro mede: cada pista (lado, ok), a resposta (lado pedido, lado
## feito), o fantasma (o martelo sem toupeira) e o momento `dupla_quente`.
## O robô: sente qual motor ligou e martela aquele lado (ou os dois) na
## batida seguinte; quando não acerta, 250 ms tarde.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares.
## A régua: (1) "Martele!" com as duas toupeiras na tela; (2) sim: os olhos
## não sabem qual é a quente; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J19",
	"titulo": "Martelos Térmicos",
	"verbo": "Martele!",
	"genero": "tct",
	"icone": "vibracao",
	"entradas": [Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S04_J19",
	"duracao": 75.0,
	"fim": "tempo",
	"sensacoes": ["golpe_esq", "golpe_dir", "explosao", "golpe", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Martele!", "segundos": 6.0},
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const DUPLA := 150  ## as duas quentes marteladas juntas; na reta, o dobro
const FANTASMA := -20
const JUNTOS_S := 0.12  ## L1 e R1 a até isto um do outro valem "juntos"
const QUEIMA_MS := 300  ## o tremor longo da queimadura (vezes o Fôlego)
const QUEDA_TEMPOS := 2.0  ## minigames.csv: 2 (o sacudir da mão)
const PISTA_MS := 250
## Por terço (entrada 0-25 s, pico 25-50 s, saída 50-75 s): a chance de
## toupeira na batida do dono e a chance de as duas serem quentes.
const DENSIDADE := [0.6, 1.0, 0.8]
const DUAS_QUENTES := [0.0, 0.3, 0.15]
const DUAS_QUENTES_NA_RETA := 0.3
const BATIDAS_DA_RETA := 16
const MAX_SEM_NOTA := 8  ## ninguém fica mais de 8 batidas sem toupeira (a régua, item 7)
const X_BURACO := 1.1  ## os buracos em RAIAS[l] ± isto
const Z_BURACO := Z_JOGADOR - 1.2
const Z_PILHA := Z_JOGADOR - 2.6  ## a pilha de chapas: o placar no mundo
const CHAPA_Y := 0.06
## O momento (o degrau estrondo): as duas chapas voam 2,5 m até o ápice
## puxado para o meio da tela (a régua, item 2): x = RAIAS[l] * 0.4.
const VOO_M := 2.5
const PUXA_PARA_O_MEIO := 0.4
const FAISCAS_DA_DUPLA := 48
const FORNALHA_MAX := 2.4
enum { ESQ, DIR, AMBAS }
```

### O dono da batida (o hoqueto)

O do Cerco: as batidas contam de `Ritmo.batida()`; o compasso `c` tem as batidas `4c` a `4c+3`; o dono da batida
`b` é `presentes()` em ordem crescente, `lista[b % lista.size()]`. **Sozinho, só as batidas pares.** O compasso 0
é a contagem (H06): a primeira toupeira possível é a batida `BATIDA_DA_PRIMEIRA_NOTA` (4). O compasso `c` é gerado
quando `Ritmo.batida() >= 4c − 4`, com o `rng` (a semente da partida).

**A nota:** `{"n": b, "b": b, "t": Ritmo.t_da_batida(b), "quente": ESQ | DIR | AMBAS, "avisada": false, "feito": -1, "t_primeiro": -1.0}`,
com `nova_nota(l, b, t)`.

- A chance de toupeira é `DENSIDADE[terco]`; `quente` é `AMBAS` com a chance `DUAS_QUENTES[terco]` (na reta,
  `DUAS_QUENTES_NA_RETA`); senão `ESQ` ou `DIR`, metade cada.
- **O terço** é pelo tempo da batida: `Ritmo.t_da_batida(b)` abaixo de 25 s é 0, abaixo de 50 s é 1, senão 2.
- **A reta:** `B_FIM = floor(75.0 * Ritmo.bpm / 60.0)` (162 a 130 BPM); a reta são as batidas de `B_FIM − 16` em
  diante (146 a 162, de 67,4 s ao fim).
- **Ninguém espera mais de 8 batidas:** se pular a batida do dono deixaria a próxima chance dele a mais de
  `MAX_SEM_NOTA` da última nota (`b − _ultima_b[l] + passo > 8`, `passo` = `lista.size()`, ou 2 sozinho), a chance
  dessa batida é 1,0. `_ultima_b[l]` começa em 0.
- **Quem está errando** (`Ritmo.simples[l]`): chance no máximo 0,5 e nunca `AMBAS`; a regra das 8 batidas vale
  por cima.
- **Depois de uma dupla,** a nota seguinte do mesmo lugar nunca é `AMBAS`.

A 130 BPM a batida dura 0,4615 s: a entrada vai da batida 4 à 54, o pico da 55 à 108, a saída da 109 à 162.

### A pista

Na batida `b − 1`, menos a antecedência do cavaleiro: `t_pista = Ritmo.t_da_batida(b - 1) - CenarioDoImpacto.antecedencia(l)`,
nunca antes de `Ritmo.t_da_batida(b - 2) + 0.42` (a vibração de 400 ms da dupla anterior do mesmo lugar já acabou).

- `ESQ` → `Forja.sentir(l, "golpe_esq", PISTA_MS)` (1,0 / 0); `DIR` → `"golpe_dir"` (0 / 1,0); `AMBAS` →
  `Forja.sentir(l, "explosao", PISTA_MS)` (1,0 / 1,0). Se devolver `true`, `j[l].rumble_ok = true`.
- **Sem vibração** (`sentir` devolveu `false`): `Som.no_controle(l, "tique", 0.7)` uma vez (`ESQ`), duas (`DIR`)
  ou três (`AMBAS`), uma semicolcheia entre elas; a pista vai ao registro com `canal` `alto_falante`.
- Os outros presentes com controle ganham uma `chance` (o isolamento, como no Cerco).
- `anotar("pista", l, {"n": b, "evento": "mandou", "canal": "rumble", "o_que": "esq"/"dir"/"ambos", "ok": ok})`.
- No mesmo quadro, as duas toupeiras do lugar voltam ao normal (`_preparar(l)`: cabeça `OXIDO_BRILHO`, escala 1).

### As toupeiras sobem pela batida

As duas toupeiras de um lugar sobem juntas para a nota mais recente com `Ritmo.batida() >= b − 1`. Com
`x = Ritmo.batida() − b`: abaixo de −1 ou acima de 1, `y = −0,6` (escondidas); de −1 a −0,25, sobem de −0,6 a 0;
de −0,25 a 0,5, `y = 0`; de 0,5 a 1, descem a −0,6. As duas têm o mesmo material: a tela não diz qual é a quente.

### O martelo

L1 martela a esquerda, R1 a direita. O martelo casa com a nota do lugar a até `Ritmo.JANELA_BOM` (0,14 s) do tempo
dela. Antes de chamar `julgar_toque` ou `nota_perdida`, ponha `nt.feito = lado` e a nota em `_ultima[l]`.

- **Nota `ESQ` ou `DIR`, lado certo** → `julgar_toque(l, t, n)`. **Lado errado** → `nota_perdida(l, n)` (a falha).
- **Nota `AMBAS`:** o primeiro martelo chama `julgar_toque(l, t, n)` e guarda `nt.t_primeiro = Ritmo.t_musica()`;
  o outro lado a até `JUNTOS_S` depois é a dupla (`_dupla(l)`). Os dois no mesmo quadro também valem (o primeiro
  é L1). Passados `JUNTOS_S` com um lado só, a toupeira que ficou queima a mão: `_queimar(l)`, sem novo erro no
  registro (o julgamento já foi feito).
- **Sem nota perto** → o fantasma: `marcar(l, FANTASMA)` e
  `anotar("entrada", l, {"o": "fantasma", "golpe_de": "P%d" % (dono + 1)})`, com o dono da nota dos outros mais
  perto no tempo.
- Toda resposta grava `anotar("entrada", l, {"o": "resposta", "n": b, "lado_pedido": "esq"/"dir"/"ambos", "lado_feito": "esq"/"dir"/"ambos"/"nenhum"})`.
- A nota que passa de `t + FOLGA_PERDIDA` (0,14 s) sem martelo é `nota_perdida(l, n)`.

Tire a nota da lista depois de resolvida (na `AMBAS`, depois da dupla ou da queimadura).

### Os pontos e a pilha

- No `toque`: `marcar(l, PONTOS[julgamento])` cru (o item, `Itens.pontos_do_acerto`, o kit aplica no
  `julgar_toque`, H08) e `toupeiras[l] += 1`.
- Na dupla: `marcar(l, DUPLA * (2 if b >= B_FIM - BATIDAS_DA_RETA else 1))` e `toupeiras[l] += 1` (a segunda
  quente).
- **Cada toupeira quente martelada vira uma chapa na pilha** do lugar («A pilha», em «A cena»): a pilha é o placar
  no mundo.

### A falha

- **Martelou a fria** (lado errado): a fria afunda oca (escala y 0,3 em 3 quadros, a cabeça `GRAFITE`,
  `Som.tocar("tique", pos, -6.0)`), e a quente, do outro lado, se revela e queima a mão.
- **Não martelou:** a quente se revela, assobia (`Som.tocar("sopro", pos_da_quente, -4.0)`) e queima a mão; a fria
  fica `GRAFITE`.
- **A revelação da quente:** a cabeça troca para `Tema.neon(Tema.TUNGSTENIO, 2.4, "forja")` por 1 batida e cospe
  vapor: `Efeitos.faiscas(self, pos_da_quente + Vector3(0, 1.0, 0), Tema.TUNGSTENIO, 14, 0.6)`.
- **A queimadura** (`_queimar(l)`): `Forja.sentir(l, "golpe", int(QUEIMA_MS * CenarioDoImpacto.gancho(l, "levantar")))`
  (1,0 / 0,6); `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)` por 250 ms, depois `GATILHO_OFF`;
  `Som.tocar("golpe", jogador(l).global_position + Vector3(0, 1.2, 0), -2.0)`;
  `jogador(l).gesto("emote-no", CenarioDoImpacto.queda_s(l, QUEDA_TEMPOS))`;
  `CenarioDoImpacto.exagero(self, _cenario, "golpe", jogador(l))` (0,02 m por 1 batida, hit-stop de 2 quadros).
  O kit já sentiu o `erro` (0,7 / 0,3) no mesmo quadro; o `golpe` vem depois e manda nos motores (o mais novo vale).
- **A recuperação:** nada se perde além do ponto; o sacudir da mão é só do corpo (o martelo seguinte vale).

### A dupla

Quando as duas quentes de uma nota `AMBAS` são marteladas a até `JUNTOS_S`:

- `Forja.sentir(l, "explosao", 400)` (1,0 / 1,0) e `_robo_surdo[l] = Ritmo.t_musica() + 0.40` (em «O robô»);
- as duas cabeças se revelam (`TUNGSTENIO` 2,4 por 1 batida) e as duas chapas voam juntas (`_voo_da_dupla(l)`,
  em «A pilha»);
- no ápice: `Efeitos.faiscas(self, apice, Tema.TUNGSTENIO, FAISCAS_DA_DUPLA, 1.4)`,
  `Efeitos.anel(self, apice, Forja.cor_do_lugar(l), 0.6, Vector3.BACK)` (depois da G15, que dá ao `anel` o
  parâmetro `dono`, passe `l` no fim),
  `Som.tocar("martelo", apice, 0.0)` e `Som.tocar("golpe", apice, -2.0)`;
- `CenarioDoImpacto.exagero(self, _cenario, "estrondo", jogador(l))` (0,05 m por 2 batidas, hit-stop de 3 quadros);
- `CenarioDoImpacto.so_o_dono(self, l)` (a luz das outras raias cai 30 % por 1 batida);
- `momento("dupla_quente", l, Vector3(RAIAS[l] * PUXA_PARA_O_MEIO, 0.0, Z_BURACO), VOO_M, {"juntos_ms": int(round(d * 1000.0)), "reta": na_reta})`,
  com `d` a distância entre os dois martelos e `na_reta` = `b >= B_FIM - BATIDAS_DA_RETA`.

### Os 75 segundos, em três terços

| terço | música | toupeira na batida do dono | as duas quentes | o que acontece |
| --- | --- | --- | --- | --- |
| 1. entrada | 0–25 s | 0,6 | 0 | aprende-se o lado; a fornalha apagada |
| 2. **o pico** | 25–50 s | 1,0 | 0,3 | a fornalha acende; as duplas: o momento |
| 3. saída | 50–75 s | 0,8 | 0,15 (0,3 na reta) | a fornalha em 1,2; **na reta**, a dupla vale o dobro e a fornalha pisca no tempo |

**A fornalha:** a `OmniLight3D` `_fornalha` (`Tema.TUNGSTENIO`, alcance 9) fica em 0 na entrada. Aos 25 s sobe de 0
a `FORNALHA_MAX` (2,4) em 4 batidas e começa o laço `Som.laco("fogo", self, Vector3(0, 1.0, -6.8), -8.0)`. Aos 50 s
desce a 1,2 em 4 batidas. Na reta, alterna 2,4 na primeira metade de cada batida e 1,2 na segunda (1 piscada por
batida: 2,2 por s, abaixo das 3 por s); com `Opcoes.flashes` desligado, fica em 2,4 parada.
`CenarioDoImpacto.passar(self, _cenario, terco == 1)` liga o pico da luz e da câmera no 2.º terço.

### O fim e o vencedor

75 s de música, contados pelo kit (H08).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(toupeiras[a]) != int(toupeiras[b]):
			return int(toupeiras[a]) > int(toupeiras[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

### Com menos de quatro

- **Três:** a roda do dono gira (`b % 3`).
- **Dois:** um as pares, outro as ímpares.
- **Um:** só as batidas pares; o isolamento e o fantasma não se medem (sem vizinho). `com_poucos()` devolve
  `"Só você na arena"` com um jogador (o texto da F02, que a L1 já traduziu) e `""` com mais.
- **O controle que cai:** a pista não vai para quem está sem controle; as notas dele que passam enquanto está fora
  somem sem erro e as toupeiras dele ficam escondidas. Quando volta, a próxima é a primeira que ainda não chegou;
  a pilha fica como estava.

### Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _ultima_b := [0, 0, 0, 0]
var _dupla_antes := [false, false, false, false]  ## a última nota do lugar foi dupla
var _gerado := 1
var _fora := [false, false, false, false]
var toupeiras := [0, 0, 0, 0]
var _buracos := {}  ## lugar -> [{raiz, cabeca, mat}, {raiz, cabeca, mat}] (ESQ, DIR)
var _pilha := {}  ## lugar -> Array das chapas
var _gatilho_ate := [-1.0, -1.0, -1.0, -1.0]
var _fornalha: OmniLight3D
var _fogo: AudioStreamPlayer3D
var _cenario := {}
var B_FIM := 162


func montar() -> void:
	var pose := CenarioDoImpacto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoImpacto.montar(self)
	B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))
	_montar_a_fornalha()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI  # de costas para a câmera, de frente para os buracos
		p.preso = true
		martelo_na_mao(p)
		_buracos[l] = [_toupeira(l, ESQ), _toupeira(l, DIR)]
		_pilha[l] = []
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	for l in presentes():
		CenarioDoImpacto.luz_com_brilho(l, 1.0)


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	var agora := Ritmo.t_musica()
	CenarioDoImpacto.passar(self, _cenario, _terco(agora) == 1)
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		for nt in _notas[l]:
			if not nt.avisada and agora >= _t_pista(l, nt):
				_avisar(l, nt)  # «A pista»
		if Forja.apertou(l, Forja.L1):
			_martelar(l, ESQ)
		if Forja.apertou(l, Forja.R1):
			_martelar(l, DIR)
		_conferir_a_dupla(l, agora)  # a segunda mão da AMBAS, ou a queimadura passado JUNTOS_S
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA and int(_notas[l][0].feito) < 0:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))  # chama falha(): a revelação e a queimadura
		if _gatilho_ate[l] >= 0.0 and agora >= _gatilho_ate[l]:
			Forja.gatilho(l, 1, Forja.GATILHO_OFF)
			_gatilho_ate[l] = -1.0
		_mover_as_toupeiras(l)  # «As toupeiras sobem pela batida»
	_mover_a_fornalha(agora)


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	toupeiras[l] += 1
	jogador(l).gesto("attack-melee-right", 0.3)
	_esmagar(l, int(nt.feito))  # achata, revela, `martelo` na TV, a chapa cai na pilha


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	if int(nt.get("feito", -1)) >= 0:
		_afundar_a_fria(l, int(nt.feito))
	_revelar_a_quente(l, nt)
	_queimar(l)


## Ninguém está fora da rodada nos Martelos: ninguém manda adesivo (G04).
func fora_da_rodada(_l: int) -> bool:
	return false
```

As outras fazem o que as partes desta ficha dizem:

- `_gerar_compasso(c)`: «O dono da batida»; guarda `_ultima_b[l]` e `_dupla_antes[l]`.
- `_terco(t)`: 0, 1 ou 2 pelos 25 s e 50 s; `_t_pista(l, nt)`: «A pista».
- `_avisar(l, nt)`: a pista, o registro, o isolamento, `_preparar(l)`; `nt.avisada = true`.
- `_martelar(l, lado)` e `_conferir_a_dupla(l, agora)`: «O martelo»; `_dupla(l)`: «A dupla».
- `_toupeira(l, lado)`, `_esmagar(l, lado)`, `_afundar_a_fria(l, lado)`, `_revelar_a_quente(l, nt)`,
  `_preparar(l)`, `_mover_as_toupeiras(l)`, `_voo_da_dupla(l)`: «A cena».
- `_queimar(l)`: «A falha»; põe `_gatilho_ate[l] = Ritmo.t_musica() + 0.25`.
- `_montar_a_fornalha()`, `_mover_a_fornalha(agora)`: «Os 75 segundos».
- `dica(l)`: `{"partes": ["@l1", "Esquerda", "@r1", "Direita"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}` quando
  `na_raia(l)` e `not aprendeu(l)`; senão `{}`.
- `combo(l)` (G04): as toupeiras quentes seguidas do lugar sem queimadura.

O catálogo: `Catalogo.MINIGAMES["S04_J19"] = preload("res://scripts/minigames/s04/martelos_termicos.gd")`.

## A cena

### A câmera

A arena da seção: `CenarioDoImpacto.pose_da_camera()` (35 mm, plongée de 50°, a 13,5 m, olhando `(0, 0,8, −1,0)`),
modo `fixa`, **sem corte**, roll zero. Os buracos (em `RAIAS[l] ± 1,1`, z 0,2), a pilha (z −1,2) e a fornalha do
fundo (z −7,6) cabem. O voo da dupla sobe a 2,5 m puxado para x = `RAIAS[l] * 0.4`: o ápice de P1 e de P4 cai em
`x_tela` 0,33 e 0,67.

- **O pico** (25–50 s): `CenarioDoImpacto.passar` recua a câmera 10 % e sobe a chave 20 % em 1 batida.
- **O tremor é do evento:** só o de `CenarioDoImpacto.exagero` (golpe na queimadura, estrondo na dupla).

### A luz

A da seção (mostarda, lado A), posta pelo `CenarioDoImpacto.montar(self)`: a névoa `#170e00`, o preenchimento
`#493400`, a chave `#f8d096`, as duas tochas `Tema.TUNGSTENIO`. Mais a fornalha do fundo (`Tema.TUNGSTENIO`, de 0 a
2,4, em «Os 75 segundos»), em `(0, 1.5, −6.8)`, dona «forja». Na dupla, `CenarioDoImpacto.so_o_dono` baixa 30 % a
luz das outras raias por 1 batida.

### As peças e o papel de cada uma

| peça ou forma | onde | papel | material |
| --- | --- | --- | --- |
| a borda do buraco: `Kit.cilindro(self, 0.52, 0.03, pos, mat)` | `pos = Vector3(RAIAS[l] ± X_BURACO, 0.015, Z_BURACO)` | a boca do buraco | `Kit.material(Tema.GRAFITE, 0.0, 0.7)` |
| o fundo do buraco: `Kit.cilindro(self, 0.42, 0.04, pos, mat)` | o mesmo x e z, y 0,02 (o topo fica acima da borda: o escuro aparece, a borda é o anel em volta) | o buraco | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| `column` (escala 0,55), num `Node3D` por buraco | `Kit.peca(t, "column", Vector3.ZERO, 0.0, 0.55)`, o `Node3D` no centro do buraco | o corpo da toupeira | a peça |
| a cabeça: `Kit.caixa(t, Vector3(0.5, 0.3, 0.5), Vector3(0, 0.95, 0), mat)` | em cima do corpo | a cabeça (a que se revela) | `Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.8)`, um por toupeira, igual nas duas |
| os olhinhos: dois `Kit.caixa(t, Vector3(0.08, 0.06, 0.04), Vector3(±0.1, 1.0, 0.26), mat)` | na cabeça | os olhos | `Tema.neon(Tema.VIOLETA, 1.2, "mundo")`, um material para todos |
| `wall-opening` (escala 2,0) | `Kit.peca(self, "wall-opening", Vector3(0, 0, -7.6), 0.0, 2.0)` | a fornalha do fundo | a peça |
| a chapa: `Kit.caixa(self, Vector3(0.5, CHAPA_Y, 0.5), pos, mat)` | nasce na cabeça da quente martelada e cai na pilha | o placar no mundo | `Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.8)` |

O cavaleiro fica em `RAIAS[l]`, de costas, com o martelo na mão (`martelo_na_mao`). As toupeiras olham para ele: o
`Node3D` de cada uma fica com `rotation.y = 0` (os olhinhos em z +0,26 viram para o cavaleiro e para a câmera).

**A revelação** (`_esmagar`, `_revelar_a_quente`, `_afundar_a_fria`): a quente martelada achata (escala y 0,3 em 3
quadros) e a cabeça troca para `Tema.neon(Tema.TUNGSTENIO, 2.4, "forja")` por 1 batida; a quente não martelada não
achata, mas acende igual e cospe vapor; a fria vira `Kit.material(Tema.GRAFITE, 0.0, 0.7)`, sem brilho, e afunda
oca quando martelada. `_preparar(l)` (na pista seguinte) volta as duas cabeças ao `OXIDO_BRILHO` e à escala 1, já
escondidas.

**O martelo certo** ainda põe `Efeitos.anel(self, pos_do_buraco + Vector3(0, 0.05, 0), Forja.cor_do_lugar(l), 0.52, Vector3.UP)`
(o anel deitado que abre e some em 0,45 s, na cor do lugar; depois da G15, com o dono `l` no fim) e `Efeitos.faiscas(self, pos_da_cabeca, Forja.cor_do_lugar(l), 12, 0.6)`.

### A pilha

A pilha do lugar fica em `(RAIAS[l], 0, Z_PILHA)`, entre os dois buracos e 1,4 m atrás deles; com a câmera a 50°, o
cavaleiro (z 1,4) não a cobre. A chapa `k` (0, 1, 2…) assenta em `y = CHAPA_Y * 0.5 + CHAPA_Y * k`; 40 chapas dão
2,4 m.

- **Uma quente martelada:** a chapa nasce na cabeça e cai na pilha em 1 batida (`TRANS_QUAD`, `EASE_IN`).
- **A dupla** (`_voo_da_dupla(l)`): as duas chapas nascem nas duas cabeças, sobem juntas ao ápice
  `(RAIAS[l] * 0.4, VOO_M, Z_BURACO)` em meia batida (`TRANS_QUAD`, `EASE_OUT`), batem (as faíscas, o anel e os
  sons de «A dupla») e caem na pilha em meia batida (`TRANS_BOUNCE`, `EASE_OUT`). As duas acendem pelo tema
  (o portão 6 reprova `emission` escrito fora do `tema.gd`): `Tema.emissivo(mat, 1.2, "forja")` e
  `create_tween().tween_method(func(e): Tema.emissivo(mat, e, "forja"), 1.2, 0.0, 8 * 60.0 / Ritmo.bpm)`
  com `TRANS_SINE` (3,7 s). O rastro: a pilha fica até o fim.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a borda da raia (`acender_raia`) | o lugar | o kit: 2,0, e 2,6 no acerto por 4 quadros |
| o anel e as faíscas do martelo certo | o lugar | `Efeitos.anel` e `Efeitos.faiscas` na `Forja.cor_do_lugar(l)` |
| os olhinhos das toupeiras | o mundo | 1,2 (o teto do mundo), `Tema.VIOLETA` |
| a cabeça revelada | a forja | 2,4, `Tema.TUNGSTENIO`, por 1 batida |
| o vapor da quente | a forja | `Efeitos.faiscas(self, pos, Tema.TUNGSTENIO, 14, 0.6)` |
| as chapas da dupla | a forja | `Tema.emissivo(mat, e, "forja")`, `e` de 1,2 a 0 em 8 batidas |
| as faíscas da dupla | a forja | `Efeitos.faiscas(self, apice, Tema.TUNGSTENIO, 48, 1.4)` |
| a fornalha | a forja | luz de 0 a 2,4, `Tema.TUNGSTENIO` |

Nenhum hex fora dos tokens: o `#141018`, o `#4a4e5e`, o `#b0502a`, o `#ffd27a`, o `#e9e7f2` e o `#ff7a2a` de antes
somem, e o `Kit.anel` também. Nada é metálico (`Kit.material` não liga o `metallic`). O pior quadro tem 48 faíscas
da dupla, 14 do vapor e 12 do martelo por lugar: abaixo de 300.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a pista | — (só a mão; o som não entrega o lado) | — (sem vibração: `tique` 1×, 2× ou 3×) | `tique_*` |
| a quente martelada | `Som.tocar("martelo", pos_da_cabeca, -2.0)` | o julgamento do kit (`jul_*`) | `martelo_*` |
| a fria martelada (afunda oca) | `Som.tocar("tique", pos, -6.0)` | `jul_erro_p{n}` (o kit) | `tique_*` |
| a quente que assobia | `Som.tocar("sopro", pos_da_quente, -4.0)` | — | `sint_sopro` |
| a queimadura | `Som.tocar("golpe", pos_do_boneco, -2.0)` | — | `golpe_*` |
| a dupla | `Som.tocar("martelo", apice, 0.0)` e `Som.tocar("golpe", apice, -2.0)` | — | `martelo_*`, `golpe_*` |
| a fornalha (25 s ao fim) | `Som.laco("fogo", self, Vector3(0, 1.0, -6.8), -8.0)` | — | `sint_fogo` |
| a faixa | `MUS_S04_J19`: 130 BPM, Ré menor, 150 s («fornalha, distorção»); até existir, a reserva `sint_trilha` da H05 | — | `mus_s04_j19` |

- **Nenhum `"falha"`**, nenhum `"bigorna_aguda"` (não está no mapa para a L4) e nada de `martelo` ou `golpe` no
  alto-falante: o alto-falante do dono é do julgamento do kit, um som por vez; a única exceção são os tiques da
  pista sem vibração.
- O material `"metal"` da FICHA: o kit toca `mod_material_metal` nos atuadores no acerto.
- A mixagem é da H11 (o Ambiente +3 dB no último terço, como a faixa pede).

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a pista de um lado | só o dono da nota | `golpe_esq` (1,0 / 0) ou `golpe_dir` (0 / 1,0), 250 ms | — | — | — |
| a pista das duas | só o dono | `explosao` (1,0 / 1,0), 250 ms | — | — | — |
| a pista sem vibração | só o dono | — | — | — | `tique` 1×, 2× ou 3×, uma semicolcheia entre eles |
| o martelo julgado | o dono | `acerto`, `perfeito` ou `erro` (o kit) | — | o kit: branco 0,15 s no perfeito; a cor escurecida 0,5 s no erro | `jul_*` (o kit) |
| a dupla | o dono | `explosao` (1,0 / 1,0), 400 ms | — | — | — |
| a queimadura | o dono | `golpe` (1,0 / 0,6), 300 ms × Fôlego | R2 Resistência (2, 4) por 250 ms, depois Off | o kit (a cor escurecida do erro) | — |
| começar | todos | — | R2 Off; o L2 é do item (G03) | a cor do lugar, 100 % (`luz_com_brilho(l, 1.0)`) | — |

- A barra de luz é sempre a cor do lugar; nunca mostra o lado.
- As luzinhas de jogador mostram o número, sempre. O microfone não se usa.
- **Os outros não sentem nada** da pista de um: o isolamento se mede (as `chance` e os fantasmas).

### O robô

```gdscript
# O robô sente a pista no controle simulado: um motor só é um lado; os dois
# acima de 0,3 e iguais (|forte - fraco| < 0,05) são as duas quentes. O golpe
# (1,0/0,6) e as sensações do kit têm os motores diferentes: não são pista. A
# explosão da dupla (400 ms) é igual à pista das duas: depois da dupla, o robô
# fica surdo 0,40 s (a próxima pista do mesmo lugar vem pelo menos 0,42 s depois).
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_quente := [0, 0, 0, 0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_surdo := [-1.0, -1.0, -1.0, -1.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var qual := -1
	if forte > 0.3 and fraco > 0.3 and absf(forte - fraco) < 0.05:
		qual = AMBAS
	elif forte > 0.3 and fraco < 0.05:
		qual = ESQ
	elif fraco > 0.3 and forte < 0.05:
		qual = DIR
	var pista := qual >= 0
	var ouve := Ritmo.t_musica() >= float(_robo_surdo[l])
	if pista and ouve and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = roundf(Ritmo.batida() + CenarioDoImpacto.antecedencia(l) * Ritmo.bpm / 60.0) + 1.0
		_robo_quente[l] = qual
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		if _robo_quente[l] != DIR:
			Forja.robo_apertar(l, Forja.L1, 0.06)
		if _robo_quente[l] != ESQ:
			Forja.robo_apertar(l, Forja.R1, 0.06)
		_robo_alvo[l] = -1.0
```

Nas duas quentes, o robô aperta L1 e R1 no mesmo quadro: chegam juntos. Ele não lê a partitura: se a vibração não
chegou ao controle simulado, ele não martela. A mesma conta roda no controle simulado da prova do jogo e no da
prova visual.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como
estão, de costas para a câmera. A mão direita leva o martelo do minigame (`martelo_na_mao`): a arma ou o amuleto
escolhido não aparece, mas o efeito do item vale. O cavaleiro pode ser de outra raça (G13, o ajuste dela de
09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos, o osso da mão direita que o
`martelo_na_mao` já acha, e as animações `attack-melee-right`, `emote-no` e `idle`.

| stat | gancho | o que muda nos Martelos | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | — | não age: ninguém é empurrado | — | — | — |
| Passo | — | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | a mão queimada: o tremor longo e o sacudir da mão | 375 ms e 2,5 tempos | 300 ms e 2 tempos | 225 ms e 1,5 tempo |
| Faro | `pista` | o tremor do lado chega antes; a toupeira sobe no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Âncora não age (nada empurra); a Lanterna adianta a pista
meio tempo (`Itens.antecipacao_s`, dentro do `antecedencia`), até o piso de 0,42 s depois da nota anterior; o
Martelo dobra o perfeito no tempo forte (o kit). Nenhum stat muda a janela, os pontos, a chance das toupeiras ou a
dupla.

**O corpo no martelo:** `gesto("attack-melee-right", 0.3)` em todo martelo julgado (a toupeira diz o lado); na
queimadura, `gesto("emote-no", CenarioDoImpacto.queda_s(l, QUEDA_TEMPOS))`; o resto do tempo, `idle`.

## As reações

- **Carimbos que os Martelos podem disparar** (do kit e do HUD, G04; o minigame não chama nenhum): `car_em_chamas`
  (5 martelos Ressonância seguidos do mesmo lugar); `car_por_um_fio` (no resultado, quando o vencedor ganha por 2 %
  dos pontos ou menos). O `car_acorde` não acontece: cada batida tem um dono.
- **Adesivos:** ninguém está fora da rodada (`fora_da_rodada(l)` devolve `false`): ninguém manda adesivo durante o
  jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: a dupla quente** (`dupla_quente`). Os dois motores batem juntos, a pessoa martela os dois lados no
mesmo instante, e as duas chapas voam 2,5 m, batem no ar sobre a raia dela com 48 faíscas e caem em brasa na pilha.
A câmera treme 0,05 m por 2 batidas, a luz das outras raias cai 30 % por 1 batida: a sala olha para o dono. Degrau
estrondo.

- **Rastro:** as duas chapas da dupla brilham 3,7 s em cima da pilha; a pilha fica até o fim.
- **A curva:** a entrada ensina o lado (uma quente por vez, chance 0,6); o pico (25–50 s) tem toupeira em toda
  batida do dono, 30 % de duplas e a fornalha acesa; a saída cai para 0,8 e 15 %, e a reta (as últimas 16 batidas)
  volta a 30 % de duplas, com a dupla valendo o dobro e a fornalha piscando no tempo.
- **Ensina sem falar:** a toupeira que não se martela se revela em tungstênio e queima a mão: na segunda vez, a
  pessoa já liga o lado da mão ao lado que acende.
- **Quem está perdendo:** quem está errando (`Ritmo.simples`) tem toupeira no máximo a 0,5 e nunca dupla; ninguém
  espera mais de 8 batidas; a queimadura não tira ponto nem chapa.
- **A nota de hoje:** 4. A regra da seção: a pista é privada e a consequência é pública.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, pela
prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | o quadro de 10 s mostra uma cabeça revelada ou uma chapa no ar |
| 4. o momento | pelo menos 4 linhas `momento` `dupla_quente` com `t_musica` entre 25 e 50, de pelo menos 2 lugares | 1 quadro em 3 do pico mostra uma cabeça revelada ao lado de uma cinza |
| 5. a curva | notas por segundo no pico ≥ 1,3 × as da entrada; nenhuma `pista` `ambos` antes de 25 s | o quadro do meio do pico tem a fornalha acesa e o da entrada não |
| 6. a falha | o P4 tem pelo menos 8 linhas `toque` com `erro` | 1 quadro em 5 mostra o P4 sacudindo a mão |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `dupla_quente` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | o voo das chapas se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `dupla_quente`, uma `sensacao` `explosao` a até 16,7 ms | as chapas acesas se veem no quadro seguinte |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a altura das pilhas (`toupeiras`) | no último quadro, quem olha diz quem martelou mais pela pilha mais alta |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova do jogo confere os itens
1, 4, 5, 8, 9 e 10 com o `--robo` dela; os itens 6 e 7 esperam o robô por lugar.

## Pronto quando

Os Martelos Térmicos jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos;
aguentam o cabo que cai e volta; fecham com vencedor; gravam pelo menos 4 `dupla_quente` entre 25 e 50 s com quatro
jogadores; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` (com `--semente=N` que sorteie o
`S04_J19` na noite, pelo `Catalogo.sortear` da H08).

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Martelos Térmicos (S04_J19): a pista de um lado só e a das duas com os
## dois motores iguais; as duplas no pico, no meio da tela; o vencedor pela pilha.
func _prova_dos_martelos() -> void:
	var viu := {}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			var forte := float(pc.get("forte", 0.0))
			var fraco := float(pc.get("fraco", 0.0))
			if forte > 0.3 and fraco > 0.3 and absf(forte - fraco) < 0.05:
				viu["ambas"] = true
			elif (forte > 0.3 and fraco < 0.05) or (fraco > 0.3 and forte < 0.05):
				viu["um_lado"] = true
	var mg = await _joga_o_minigame("S04_J19", 115.0, olhar)
	if mg == null:
		return
	_esperar(viu.has("um_lado"), "Martelos: a pista de um lado só chegou (%s)" % [viu.keys()])
	_esperar(viu.has("ambas"), "Martelos: a pista das duas chegou (%s)" % [viu.keys()])
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.toupeiras[v[0]]) == v.map(func(l): return int(mg.toupeiras[l])).max(), "Martelos: vence quem martelou mais")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S04_J19")
	var resp := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("o") == "resposta")
	_esperar(resp.size() >= 1, "Martelos: %d respostas com o lado no registro" % resp.size())
	var cedo := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("o_que") == "ambos" \
		and float(e.get("t_musica", 0.0)) < 25.0)
	_esperar(cedo.is_empty(), "Martelos: nenhuma dupla na entrada (%d)" % cedo.size())
	var duplas := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "dupla_quente")
	if mg.presentes().size() == 4:
		var no_pico := duplas.filter(func(e): return float(e.get("t_musica", 0.0)) >= 25.0 and float(e.get("t_musica", 0.0)) <= 50.0)
		_esperar(no_pico.size() >= 4, "Martelos: %d duplas no pico" % no_pico.size())
		var donos := {}
		for e in no_pico:
			donos[int(e.get("lugar", -1))] = true
		_esperar(donos.size() >= 2, "Martelos: as duplas de pelo menos 2 lugares (%s)" % [donos.keys()])
	for e in duplas:
		_esperar(float(e.get("x_tela", 0.0)) >= 0.2 and float(e.get("x_tela", 0.0)) <= 0.8 \
			and float(e.get("altura_tela", 0.0)) >= 0.08, "Martelos: a dupla no meio da tela (%s)" % [e])
```

(`_joga_o_minigame` é da H08; `_linha_do_tempo` da F01. O fim conta em tempo de música: os 75 s e o treino cabem em
115 s.)

### O que o registro mede

- A `sensacao` `golpe_esq`, `golpe_dir` e `explosao` (com `seq` e `ok` na `saida`) e a `pista` (`canal` `rumble`
  ou `alto_falante`) de cada nota.
- A `entrada` `resposta` com o lado pedido e o feito; o `toque` do kit; o fantasma com o dono da nota mais perto.
- A `saida` de gatilho (Resistência 2, 4 e Off) de cada queimadura; o `momento` `dupla_quente` com `juntos_ms`.

### As pranchas que o jogador do time olha

O quadro de 10 s (uma cabeça revelada ou uma chapa no ar), o do meio da entrada e o do meio do pico (a fornalha
apagada e acesa), o primeiro depois de uma dupla (as faíscas sobre a raia) e o último (as quatro pilhas: o placar).

### O que o André joga e sente

`./run-local.sh -- --sala=S04_J19`, com quatro DualSense:

- de olhos na tela, as duas toupeiras são iguais; a mão sabe a quente;
- as duas quentes (os dois motores iguais) se sentem diferentes de um lado só;
- a queimadura é mais longa e mais áspera que o acerto, e o R2 pesa nela;
- a fornalha acende no pico e a sala esquenta; na reta, ela pisca no tempo.

### Armadilhas

- **A pista das duas é a `explosao`** (os dois motores iguais), não o `golpe`: o `golpe` é a queimadura.
- **A explosão da dupla parece pista:** o robô fica surdo 0,40 s depois dela, e a pista seguinte do mesmo lugar
  nunca vem antes de 0,42 s depois da nota anterior.
- **A dupla:** o julgamento é o do primeiro martelo; o segundo só decide a dupla. Não chame `julgar_toque` duas
  vezes na mesma nota.
- **As toupeiras sobem pela batida**, nunca por `dt`.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque` (H08); marque cru.
- **O `Efeitos.anel` some sozinho** em 0,45 s: é o enfeite do martelo certo, nunca a borda do buraco.

### Ao terminar

- No [quadro](README.md): a linha **L4**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer): `feat: Martelos Térmicos, a toupeira quente que só a mão distingue`
