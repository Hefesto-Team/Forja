# L5 — A Prensa

**Sprint:** L · **Slot:** S04_J20 · **Tamanho:** M · **Depende de:** H04, H08, F09, L1, G08, G14, G15

## Por quê

O terror da seção: luz baixa, prensas de ferro no escuro em cima de cada raia, e a mão que avisa um tempo antes
que a prensa vai descer em você (no pico, também para que lado fugir); quem é esmagado três vezes vira fantasma e
passa a acender a luz no caminho dos outros, menos no do líder, que fica no escuro só com a mão.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [L1 — O Cerco, «A cena»](L1-o-cerco.md#a-cena): o cenário comum inteiro (o `escuro`, a lanterna da vida, o exagero) está em
  «A cena», no código de `cenario_do_impacto.gd`; o modelo (o hoqueto, a pista de um lado, o robô, o `momento`, o `_piscar`) está em «Como se joga»,
  «O controle» e «O robô». Se a L1 já entrou, valem `cenario_do_impacto.gd` e `o_cerco.gd` em
  `godot/scripts/minigames/s04/`.

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG, os princípios) está copiado nesta ficha, com
os números. Onde o índice da seção (`L-o-impacto.md`) dá uma cor em hex ou outra câmera, vale a L1
(o `cenario_do_impacto.gd`).

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s04/a_prensa.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S04_J20` em `MINIGAMES` e na lista da seção `S04` de `SECOES` | **de todos** |
| `godot/scripts/traducoes.gd` | `"A Prensa": "The Press"`, `"Fuja!": "Run!"`, `"Fuja": "Run"`, `"Luz": "Light"` (as que ainda não existirem) | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_prensa()` e a chamada depois das outras da seção | **de todos** |
| `godot/scripts/minigames/s04/cenario_do_impacto.gd` | **não muda**: só chama | da seção (a L1 criou) |
| `godot/scripts/minigames/minigame.gd` | **não muda**: usa `momento()` (a L1 pôs) | de todos |

O `.uid` novo (`a_prensa.gd.uid`) sai de `"$GODOT" --headless --path godot --import --quit` e entra no commit.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## A Prensa (S04_J20) — cada raia tem três lugares (esquerda, meio, direita)
## e uma prensa no escuro em cima de cada um. Na batida do dono, a prensa
## desce onde ele está; a mão avisa uma batida antes. Fuja com o analógico
## esquerdo (um toque para um lado) na batida. No pico, descem duas e a pista
## diz o lado seguro: só o motor da esquerda, fuja para a esquerda; só o da
## direita, para a direita.
##
## A falha: esmagado — o cavaleiro fica achatado a 30 % por 1 batida e perde
## uma brasa, que voa da lanterna; na terceira, vira fantasma (achatado e
## caído até o fim, com uma lanterna flutuando) e acende com ✕ a luz das
## raias dos outros vivos, menos a do líder.
## O vencedor: o último em pé; depois, quem tem mais vida; os fantasmas pela
## ordem em que caíram (quem caiu depois, na frente).
## O alto-falante do dono: o julgamento do kit; sem vibração, a pista em tiques.
## O registro mede: cada pista (qualquer lado, ou o lado seguro), para onde o
## cavaleiro foi, no tempo, a luz do fantasma e o momento `esmagado`.
## O robô: sente a pista (o golpe: qualquer lado; um motor só: aquele lado)
## e foge na batida seguinte; quando não acerta, 250 ms tarde. O fantasma
## aperta ✕ nas batidas dele.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares, até os 90 s.
## A régua: (1) "Fuja!" com as prensas descendo no aviso; (2) sim: no escuro,
## a mão avisa antes do olho; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J20",
	"titulo": "A Prensa",
	"verbo": "Fuja!",
	"genero": "sobrevivencia",
	"icone": "vibracao",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S04_J20",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["golpe", "golpe_esq", "golpe_dir", "explosao", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Fuja!", "segundos": 6.0},
	"gesto": "lados",
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const LUGARES_X := [-1.3, 0.0, 1.3]  ## os três lugares da raia, somados a RAIAS[l]
const VIDA_MAX := 3
const BRILHO := [0.4, 0.45, 0.7, 1.0]  ## a barra de luz por vida (0 = fantasma: o piso)
const FANTASMA_LUZ := 20  ## o fantasma que acende a luz no tempo
const ESCURO := 0.35  ## o cenário comum escurecido (o terror)
const ESCURO_SAIDA := 0.25  ## aos 60 s, a luz cai
const LX_VAI := 0.6
const LX_VOLTA := 0.3
const PISTA_MS := 250
## A chance de prensa na batida do dono: entrada (0-30 s), pico (30-60 s), saída (60-90 s).
const DENSIDADE := [0.6, 1.0, 1.0]
const MAX_SEM_NOTA := 8  ## ninguém fica mais de 8 batidas sem prensa (a régua, item 7)
const BATIDAS_DA_RETA := 16
const PULO_S := 0.12  ## o pulo de um lugar ao vizinho, dividido pelo Passo
const PRENSA_Y := 3.2  ## a cabeça da prensa parada
const PRENSA_BATE_Y := 0.25  ## a cabeça no chão
## O momento (o degrau estrondo): o cavaleiro achatado a 30 % e a brasa
## perdida, que voa 2,5 m da lanterna até o ápice puxado para o meio da tela
## (a régua, item 2): x = RAIAS[l] * 0.4.
const ACHATADO := 0.3
const VOO_M := 2.5
const PUXA_PARA_O_MEIO := 0.4
const FAISCAS_DO_ESMAGADO := 48
const MARCA_BATIDAS := 8  ## a marca no chão: 4 s a 120 BPM
## A lanterna-fantasma: a luz que o fantasma acende nas raias dos outros.
const LUZ_FANTASMA := 1.6
const LUZ_FANTASMA_ALCANCE := 3.0  ## vezes o raio (Faro) do fantasma
const LUZ_FANTASMA_BATIDAS := 2.0
```

### Os donos da batida (o hoqueto)

As batidas contam de `Ritmo.batida()`; o compasso `c` tem as batidas `4c` a `4c+3`; a contagem é o compasso 0
(H06), e a primeira prensa possível é a batida `BATIDA_DA_PRIMEIRA_NOTA` (4). O compasso `c` é gerado quando
`Ritmo.batida() >= 4c − 4`, com o `rng` (a semente da partida). A lista é `presentes()` em ordem crescente, vivos e
fantasmas: o fantasma continua dono das batidas dele (é nelas que ele acende a luz).

```gdscript
## Os donos da batida b: o hoqueto do Cerco; na reta (as últimas 16 batidas),
## com três ou mais, cada um tem a batida da paridade da posição dele na
## lista: com quatro, descem duas prensas por batida.
func _donos(b: int) -> Array:
	var lista := presentes()
	if lista.size() == 1:
		return lista if b % 2 == 0 else []
	if b >= B_FIM - BATIDAS_DA_RETA and lista.size() >= 3:
		return lista.filter(func(l): return lista.find(l) % 2 == b % 2)
	return [lista[b % lista.size()]]
```

`B_FIM = floor(90.0 * Ritmo.bpm / 60.0)`: 180 a 120 BPM; a reta são as batidas 164 a 180 (82 s ao fim). A 120 BPM a
batida dura 0,5 s: a entrada vai da batida 4 à 59, o pico da 60 à 119, a saída da 120 à 180.

**A nota do vivo:** `{"n": b, "b": b, "t": Ritmo.t_da_batida(b), "avisada": false, "caem": [], "seguro": -1}`, com
`nova_nota(l, b, t)`.

- A chance de prensa é `DENSIDADE[terco]` (o terço pelo tempo da batida: abaixo de 30 s, 0; abaixo de 60 s, 1;
  senão 2).
- **Ninguém espera mais de 8 batidas:** se pular a batida deixaria a próxima chance do vivo a mais de
  `MAX_SEM_NOTA` da última prensa dele (`b − _ultima_b[l] + passo > 8`, `passo` = `lista.size()`, ou 2 sozinho), a
  chance é 1,0. `_ultima_b[l]` começa em 0.
- O fantasma não tem nota: tem as batidas dele (abaixo, «O fantasma»).

### A pista

`t_pista = Ritmo.t_da_batida(b - 1) - CenarioDoImpacto.antecedencia(l)`, nunca antes de
`Ritmo.t_da_batida(b - 2) + FOLGA_PERDIDA + 0.02` (a esquiva anterior do mesmo lugar já fechou). **Na pista**, a nota
decide onde caem as prensas pelo lugar em que o cavaleiro está **agora** (`pos[l]` 0, 1 ou 2):

| terço | caem | a pista (`Forja.sentir(l, nome, PISTA_MS)`) |
| --- | --- | --- |
| entrada (0–30 s) | só `pos[l]` | `"golpe"` (1,0 / 0,6): fuja para qualquer lado |
| **pico** (30–60 s) | no meio: o meio e um lado sorteado pelo `rng`; num canto: só o canto | no meio: `"golpe_esq"` (1,0 / 0) se o seguro é a esquerda, `"golpe_dir"` (0 / 1,0) se é a direita; num canto: `"golpe"` |
| saída (60–90 s) e reta | como no pico | como no pico |

- O `seguro` é o lugar para onde a pista manda (no `"golpe"`, qualquer lugar fora de `caem`). Quem está com
  `Ritmo.simples[l]` recebe só a regra da entrada.
- **Sem vibração** (`sentir` devolveu `false`): `Som.no_controle(l, "tique", 0.7)` uma vez (`golpe_esq`), duas
  (`golpe_dir`) ou três (`golpe`), uma semicolcheia entre elas; a pista vai ao registro com `canal` `alto_falante`.
- Os outros presentes com controle ganham uma `chance` (o isolamento).
- `anotar("pista", l, {"n": b, "evento": "mandou", "canal": "rumble", "o_que": "ambos"/"esq"/"dir", "ok": ok})`.

### A esquiva

O analógico esquerdo passando de `LX_VAI` (±0,6) para um lado; rearma abaixo de `LX_VOLTA` (0,3). O cavaleiro pula
para o lugar vizinho daquele lado na hora: `gesto("jump", 0.5)` e o tween de x em
`PULO_S / CenarioDoImpacto.gancho(l, "velocidade")` s. Para fora da raia (do canto para a parede), ele bate e não
sai.

- **Com uma nota avisada e não resolvida:** a esquiva a até `FOLGA_PERDIDA` (0,14 s) do tempo é julgada. O lugar
  novo fora de `caem` → `julgar_toque(l, t, n, true)` (é perigo físico: a folga de quem está em último vale);
  dentro de `caem` (o lado errado, ou a parede) → `nota_perdida(l, n)`. Fora da janela, depois da pista → cedo
  demais: `nota_perdida(l, n)` (a prensa corrige o rumo e desce onde ele foi).
- Antes de julgar, ponha a nota em `_ultima[l]` e tire-a da lista. Grave
  `anotar("entrada", l, {"o": "resposta", "n": b, "lado_pedido": "ambos"/"esq"/"dir", "lado_feito": "esq"/"dir"})`.
- **Sem nota avisada:** o cavaleiro só muda de lugar, sem julgamento (reposicionar entre as prensas vale).
- A nota que passa de `t + FOLGA_PERDIDA` sem esquiva é `nota_perdida(l, n)`.
- Um julgamento ERRO (o lugar certo, mas fora do tempo) também esmaga: é o `falha()` do kit.
- **Os pontos** (no `toque`): `marcar(l, PONTOS[julgamento])` cru; o item (`Itens.pontos_do_acerto`) o kit aplica.

### As prensas descem pela batida

A cabeça da prensa de cada lugar fica em `y = PRENSA_Y` (3,2). Para cada nota que a tem em `caem`, com
`x = Ritmo.batida() − b`: de −0,25 a 0 desce até `PRENSA_BATE_Y` (0,25, curva `SAI`); de 0 a 0,5 fica; de 0,5 a 1,5
sobe a 3,2. Duas notas no mesmo lugar: vale o `y` mais baixo. A prensa que bate no chão vazio toca
`Som.tocar("pedra", pos, -6.0)`.

**Ensina sem falar:** as prensas ficam escondidas (`visible = false`) até a batida 2 da contagem; aí aparecem
descendo de y 6,0 a 3,2 em 1 batida. Na batida 3, a prensa do lugar 0 (a esquerda do cavaleiro) de cada raia desce
vazia (de 2,75 a 3) e bate no chão: `Som.tocar("pedra", Vector3(0, 0, Z_JOGADOR), -4.0)`, uma vez, e cada cavaleiro
`gesto("jump", 0.5)`. Sobe de 3,5 a 4,5. Sem vibração e sem julgamento.

### O esmagado

`_esmagar(l)`, chamada pelo `falha()`:

- `Forja.sentir(l, "explosao", 400)` (1,0 / 1,0);
- `Som.tocar("golpe", pos, 0.0)` e `Som.tocar("pedra", pos, -4.0)`;
- o cavaleiro achata: `scale.y = ACHATADO` (0,3) por 1 batida, pela batida, e volta com um tween de 0,15 s;
  `gesto("fall", 0.5)`;
- `CenarioDoImpacto.exagero(self, _cenario, "estrondo", jogador(l))` (0,05 m por 2 batidas, hit-stop de 3 quadros);
- `CenarioDoImpacto.so_o_dono(self, l)` (a luz das outras raias cai 30 % por 1 batida);
- a marca no chão: `Kit.caixa(self, Vector3(1.1, 0.01, 1.1), Vector3(x_do_lugar, 0.02, Z_JOGADOR), Kit.material(Tema.JANELA, 0.0, 1.0))`,
  `queue_free` depois de `MARCA_BATIDAS` (8 batidas, 4 s);
- **fora do treino:** `vida[l] -= 1`, `CenarioDoImpacto.acender_lanterna(_lanternas[l], vida[l], l)`, `_pisca[l] = CenarioDoImpacto.PISCA_MAX`
  (depois do piscar do kit, a barra vai a `BRILHO[vida[l]]`), a brasa perdida voa (`_voo_da_brasa(l)`, em «A cena»)
  e `momento("esmagado", l, Vector3(RAIAS[l] * PUXA_PARA_O_MEIO, 0.0, Z_JOGADOR - 1.0), VOO_M, {"vida": vida[l], "fantasma": vida[l] == 0})`;
- **no treino:** só achata; nada se perde e não há `momento`.

**A terceira:** o cavaleiro vira fantasma: `animar("die")`, fica achatado (0,3) e caído até o fim, e uma lanterna
pequena flutua em cima dele (em «A cena»); `caiu_em[l] = Ritmo.t_musica()`. A falha é física e ninguém sai do jogo:
o fantasma continua jogando (os princípios, regra 6).

### O fantasma

Nas batidas dele (as de `_donos(b)`), ✕ a até `Ritmo.JANELA_BOM` (0,14 s) da batida acende **a lanterna-fantasma**:

- `_lider()` é o vivo com controle com mais vida; no empate, mais pontos; no empate, o lugar menor (−1 se não há
  vivo);
- em cada raia de vivo menos a do líder, a `OmniLight3D` `_luz_fantasma[r]` toma a cor `Forja.cor_do_lugar(f)` e o
  alcance `LUZ_FANTASMA_ALCANCE * CenarioDoImpacto.gancho(f, "raio")`, e acende a `LUZ_FANTASMA` (1,6) por
  `LUZ_FANTASMA_BATIDAS` (2 batidas), apagando num tween de 0,15 s;
- `marcar(f, FANTASMA_LUZ)`; `Forja.sentir(f, "acerto", 80)`; `Som.tocar("confirma", Vector3(0, 2.6, Z_JOGADOR), -8.0)`;
- `anotar("entrada", f, {"o": "fantasma_luz", "n": b, "lider": "P%d" % (lider + 1), "acesas": "P1,P3"})` (as raias
  acesas, em ordem).

Uma vez por batida. Sem julgamento do kit (não é nota) e sem erro. Os pontos do fantasma não mudam a colocação. A
pista do líder vibra igual e a janela dele não muda: ele só fica no escuro.

### Os 90 segundos, em três terços

| terço | música | prensa na batida do dono | o que acontece |
| --- | --- | --- | --- |
| 1. entrada | 0–30 s | 0,6 | desce uma prensa, só em você; fuja para qualquer lado |
| 2. **o pico** | 30–60 s | 1,0 | no meio, descem duas e a mão diz o lado |
| 3. saída | 60–90 s | 1,0 | a luz cai de `ESCURO` (0,35) a `ESCURO_SAIDA` (0,25) em 4 batidas; **na reta**, com quatro, descem duas prensas por batida |

`CenarioDoImpacto.passar(self, _cenario, terco == 1)` liga o pico da luz e da câmera no 2.º terço. **A luz que cai**
aos 60 s: logo depois do `montar`, guarde `_luzes_da_casa = get_children().filter(func(n): return n is OmniLight3D)`
(a chave e as duas tochas do cenário, antes de qualquer outra luz); aos 60 s, cada uma vai a
`light_energy * ESCURO_SAIDA / ESCURO` em 4 batidas, e `_cenario.chave_energia` é multiplicada pelo mesmo
`ESCURO_SAIDA / ESCURO` (o `passar` respeita).

### O fim e o vencedor

`fim` `ultimo_em_pe`: com dois ou mais no começo (`_comecaram`), quando só um presente com controle tem `vida > 0`,
todos `acabou`. Sozinho, os 90 s (ou a terceira esmagada: aí `acabou`).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(vida[a]) != int(vida[b]):
			return int(vida[a]) > int(vida[b])
		if int(vida[a]) == 0:
			return float(caiu_em[a]) > float(caiu_em[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

### Com menos de quatro

- **Três:** a roda do dono (`b % 3`); na reta, a paridade (P da posição 0 e 2 nas pares, o da 1 nas ímpares).
- **Dois:** um as pares, outro as ímpares (a reta não muda a roda); o último vivo acaba.
- **Um:** só as pares; não há fantasma que acenda nada (o minigame acaba na terceira). `com_poucos()` devolve
  `"Só você na arena"` com um jogador (o texto da F02, que a L1 já traduziu) e `""` com mais.
- **O controle que cai:** as prensas dele não descem enquanto está fora (as notas somem sem erro); a vida fica.
  Quem está sem controle não conta como vivo para o último em pé nem para o líder até voltar.

### Os ganchos

```gdscript
var _notas := [[], [], [], []]
var _ultima := [{}, {}, {}, {}]
var _ultima_b := [0, 0, 0, 0]
var _gerado := 1
var _fora := [false, false, false, false]
var pos := [1, 1, 1, 1]  ## o lugar do cavaleiro na raia: 0 esquerda, 1 meio, 2 direita
var vida := [VIDA_MAX, VIDA_MAX, VIDA_MAX, VIDA_MAX]
var caiu_em := [0.0, 0.0, 0.0, 0.0]
var _armado := [true, true, true, true]  ## o analógico voltou ao meio
var _prensas := {}  ## lugar -> [três Node3D]
var _lanternas := {}  ## lugar -> os materiais das brasas
var _luz_fantasma := {}  ## lugar -> OmniLight3D
var _ultima_luz_b := [-1, -1, -1, -1]  ## a batida em que o fantasma acendeu
var _luzes_da_casa: Array = []
var _comecaram := 0
var _pisca := [0.0, 0.0, 0.0, 0.0]
var _cenario := {}
var B_FIM := 180


func montar() -> void:
	var pose := CenarioDoImpacto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoImpacto.montar(self, ESCURO)
	_luzes_da_casa = get_children().filter(func(n): return n is OmniLight3D)
	B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		acender_raia(l, 0.35)  # a única luz perto do cavaleiro
		var r: Dictionary = _raias.get(l, {})
		if not r.is_empty():
			(r.luz as OmniLight3D).omni_range *= CenarioDoImpacto.gancho(l, "raio")
		posicionar(l)
		p.rotation.y = 0.0  # de frente para a câmera
		p.preso = true
		_prensas[l] = _montar_as_prensas(l)  # escondidas até a batida 2
		_lanternas[l] = CenarioDoImpacto.lanterna(self, Vector3(RAIAS[l] + 1.9, 0, Z_JOGADOR + 0.6), l, VIDA_MAX)
		_luz_fantasma[l] = _montar_a_luz_fantasma(l)
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	_comecaram = presentes().size()
	for l in presentes():
		CenarioDoImpacto.luz_com_brilho(l, BRILHO[vida[l]])


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	var agora := Ritmo.t_musica()
	CenarioDoImpacto.passar(self, _cenario, _terco(agora) == 1)
	_contagem()  # «Ensina sem falar»: as prensas aparecem e a vazia desce
	for l in presentes():
		_piscar(l, dt)
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_notas[l] = _notas[l].filter(func(nt): return float(nt.t) > agora)
		if int(vida[l]) == 0:
			_fantasma_joga(l)  # «O fantasma»
			continue
		for nt in _notas[l]:
			if not nt.avisada and agora >= _t_pista(l, nt):
				_avisar(l, nt)  # decide caem e seguro pelo pos[l] de agora; manda a pista
		var lx := Forja.eixo(l, Forja.LX)
		if _armado[l] and absf(lx) >= LX_VAI:
			_armado[l] = false
			_esquivar(l, 1 if lx > 0.0 else -1)
		elif absf(lx) <= LX_VOLTA:
			_armado[l] = true
		while not _notas[l].is_empty() and agora > float(_notas[l][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[l].pop_front()
			_ultima[l] = nt
			nota_perdida(l, int(nt.n))
	_mover_as_prensas()  # pela batida, de todas as notas avisadas
	_mover_as_lanternas_fantasma()  # sobem e descem com sin(PI * Ritmo.batida())
	_escurecer_na_saida(agora)
	_conferir_o_ultimo_em_pe()


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	Som.tocar("pedra", _pos_da_prensa(l, int(nt.caem[0])), -6.0)


func falha(l: int) -> void:
	_esmagar(l)  # «O esmagado»; na terceira, o fantasma


## A roda de adesivos (G04) lê isto: só quem está fora da rodada manda adesivo.
func fora_da_rodada(l: int) -> bool:
	return int(vida[l]) == 0
```

As outras fazem o que as partes desta ficha dizem:

- `_gerar_compasso(c)`: «Os donos da batida»; `_terco(t)`; `_t_pista(l, nt)` e `_avisar(l, nt)`: «A pista».
- `_esquivar(l, dir)`: «A esquiva»; `pos[l]` fica entre 0 e 2.
- `_esmagar(l)`, `_voo_da_brasa(l)`: «O esmagado» e «A cena».
- `_fantasma_joga(l)`, `_lider()`: «O fantasma».
- `_contagem()`, `_mover_as_prensas()`, `_pos_da_prensa(l, k)`, `_montar_as_prensas(l)`, `_montar_a_luz_fantasma(l)`:
  «As prensas descem pela batida» e «A cena».
- `_escurecer_na_saida(agora)`: «Os 90 segundos»; `_conferir_o_ultimo_em_pe()`: «O fim».
- `_piscar(l, dt)`: o do Cerco; depois do piscar do kit (H08: no máximo 0,5 s), a barra volta a `BRILHO[vida[l]]`.
- `dica(l)`: `{"partes": ["@stick_l", "Fuja"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}` para o vivo e
  `{"partes": ["@cross", "Luz"], ...}` para o fantasma, com `na_raia(l)` e `not aprendeu(l)`; senão `{}`.
- `combo(l)` (G04): as esquivas seguidas do lugar sem esmagado.

O catálogo: `Catalogo.MINIGAMES["S04_J20"] = preload("res://scripts/minigames/s04/a_prensa.gd")`.

## A cena

### A câmera

A arena da seção: `CenarioDoImpacto.pose_da_camera()` (35 mm, plongée de 50°, a 13,5 m, olhando `(0, 0,8, −1,0)`),
modo `fixa`, **sem corte**, roll zero. Na profundidade do cavaleiro (z 1,4), o quadro vê até y 7,35: as prensas
paradas (cabeça a 3,2, pistão até 6,45) e a viga (6,6) cabem. Do ponto da câmera, a cabeça da prensa fica acima do
cavaleiro na tela, sem cobri-lo. A brasa perdida sobe a 2,5 m puxada para x = `RAIAS[l] * 0.4`: o ápice de P1 e de
P4 cai em `x_tela` 0,33 e 0,67.

- **O pico** (30–60 s): `CenarioDoImpacto.passar` recua a câmera 10 % e sobe a chave 20 % em 1 batida.
- **O tremor é do evento:** só o de `CenarioDoImpacto.exagero` (estrondo no esmagado).

### A luz

A da seção (mostarda, lado A), escurecida: `CenarioDoImpacto.montar(self, ESCURO)` põe a névoa `#170e00`, o
preenchimento `#493400` a 0,35 × 0,35, a chave `#f8d096` com energia 0,9 × 0,35 e as duas tochas `Tema.TUNGSTENIO`
com 0,8 × 0,35. O terror escurece a luz da casa, não troca de cor. Aos 60 s, a casa cai a 0,25 («Os 90 segundos»).

- A luz de cada raia é a do kit (`acender_raia(l, 0.35)`, a cor do lugar), com o alcance vezes o raio (Faro) do
  cavaleiro.
- **A lanterna-fantasma:** por raia, uma `OmniLight3D` em `(RAIAS[l], 2.6, Z_JOGADOR)`, energia 0 até o fantasma
  acender (1,6, a cor do fantasma, por 2 batidas).
- No esmagado, `CenarioDoImpacto.so_o_dono` baixa 30 % a luz das outras raias por 1 batida.

### As peças e o papel de cada uma

| peça ou forma | onde | papel | material |
| --- | --- | --- | --- |
| `floor`, `floor-detail`, `wall`, `wall-half` | `Kit.arena(sala, 5, 3)` (o `montar` do cenário) | o chão e as paredes | as peças |
| a viga: `Kit.caixa(self, Vector3(3.6, 0.3, 0.3), Vector3(RAIAS[l], 6.6, Z_JOGADOR), mat)` | uma por raia | segura as três prensas | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| o pistão: `Kit.caixa(p, Vector3(0.22, 3.0, 0.22), Vector3(0, 1.75, 0), mat)` | num `Node3D` por lugar, em `(RAIAS[l] + LUGARES_X[k], PRENSA_Y, Z_JOGADOR)` | a haste da prensa | `Kit.material(Tema.OXIDO, 0.0, 0.6)` |
| a cabeça: `Kit.caixa(p, Vector3(1.1, 0.5, 1.1), Vector3.ZERO, mat)` | no mesmo `Node3D` | o que esmaga | `Kit.material(Tema.GRAFITE, 0.0, 0.7)` |
| a marca: `Kit.caixa(self, Vector3(1.1, 0.01, 1.1), pos, mat)` | no chão do lugar esmagado, y 0,02 | o rastro (4 s) | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| a lanterna da vida: `CenarioDoImpacto.lanterna(self, Vector3(RAIAS[l] + 1.9, 0, Z_JOGADOR + 0.6), l, VIDA_MAX)` | ao lado de cada raia | o placar no mundo (3 brasas) | o do cenário: o poste `GRAFITE`, as brasas `Tema.emissivo(m, 1.8, l)` |
| a brasa perdida: `Kit.caixa(self, Vector3(0.3, 0.3, 0.3), pos, mat)` | sai da brasa que apagou | o objeto do momento | `Kit.material(Tema.JOGADOR[l].darkened(0.6), 0.0, 0.7)` com `Tema.emissivo(m, 1.8, l)` |
| a lanterna do fantasma: `Kit.caixa(self, Vector3(0.2, 0.2, 0.2), pos, mat)` | `jogador(l).global_position + Vector3(0, 1.8 + 0.1 * sin(PI * Ritmo.batida()), 0)` | o fantasma | o mesmo material da brasa |

**O voo da brasa** (`_voo_da_brasa(l)`): a brasa nasce na brasa da lanterna que apagou, sobe ao ápice
`(RAIAS[l] * 0.4, VOO_M, Z_JOGADOR - 1.0)` em meia batida (`TRANS_QUAD`, `EASE_OUT`), solta
`Efeitos.faiscas(self, apice, Forja.cor_do_lugar(l), FAISCAS_DO_ESMAGADO, 1.4)` no ápice, cai ao chão em
`(RAIAS[l] * 0.4, 0.15, Z_JOGADOR - 1.0)` em meia batida (`TRANS_BOUNCE`, `EASE_OUT`), apaga (`Tema.emissivo(m, 0.0, l)` e o
albedo `Tema.GRAFITE`) e some junto com a marca, depois de `MARCA_BATIDAS`.

Quem foge usa `gesto("jump", 0.5)`; o resto do tempo, `idle`; o esmagado, `gesto("fall", 0.5)`; o fantasma,
`animar("die")`.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a luz da raia (`acender_raia`) | o lugar | o kit, a 0,35 |
| as brasas acesas da lanterna, a brasa perdida, a lanterna do fantasma | o lugar | 1,8 (as lâmpadas) |
| as faíscas do esmagado | o lugar | `Efeitos.faiscas(self, apice, Forja.cor_do_lugar(l), 48, 1.4)` |
| a lanterna-fantasma nas raias dos outros | o fantasma que acendeu | luz 1,6, a cor dele, por 2 batidas |
| as tochas | a forja | `Tema.TUNGSTENIO`, luz 0,8 × 0,35 (0,25 na saída) |

Nenhum hex fora dos tokens: o `#3a3a44`, o `#4a4e5e` e o `#b9b0ff` de antes somem, e o `wood-structure` também (a
viga é uma caixa). Nada é metálico. O pior quadro tem 48 faíscas por esmagado: com dois esmagados na mesma batida da
reta, 96, abaixo de 300.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a pista | — (só a mão) | — (sem vibração: `tique` 1×, 2× ou 3×) | `tique_*` |
| a prensa no chão vazio (a esquiva certa, a vazia da contagem) | `Som.tocar("pedra", pos, -6.0)` (a da contagem, uma vez, −4 dB, no meio) | o julgamento do kit (`jul_*`) | `pedra_*` |
| o esmagado | `Som.tocar("golpe", pos, 0.0)` e `Som.tocar("pedra", pos, -4.0)` | `jul_erro_p{n}` (o kit) | `golpe_*`, `pedra_*` |
| a lanterna-fantasma acende | `Som.tocar("confirma", Vector3(0, 2.6, Z_JOGADOR), -8.0)` | — | `confirma_*` |
| a faixa | `MUS_S04_J20`: 120 BPM, Mi♭ menor, 150 s («impacto no tempo 1, ameaça»); até existir, a reserva `sint_trilha` da H05 | — | `mus_s04_j20` |

- **Nenhum `"falha"`** e nada de `golpe` ou `coleta` no alto-falante: o alto-falante do dono é do julgamento do kit,
  um som por vez; a única exceção são os tiques da pista sem vibração. O `mod_coleta` do mapa não se usa aqui.
- O material `"metal"` da FICHA: o kit toca `mod_material_metal` nos atuadores na esquiva certa.
- A mixagem é da H11 (o Ambiente +3 dB no último terço, como a faixa pede).

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a pista «qualquer lado» | só o dono vivo | `golpe` (1,0 / 0,6), 250 ms | — | — | — |
| a pista do lado seguro | só o dono vivo | `golpe_esq` (1,0 / 0) ou `golpe_dir` (0 / 1,0), 250 ms | — | — | — |
| a pista sem vibração | só o dono vivo | — | — | — | `tique` 3× (qualquer lado), 1× (esquerda) ou 2× (direita) |
| a esquiva julgada | o dono | `acerto`, `perfeito` ou `erro` (o kit) | — | o kit: branco 0,15 s no perfeito; a cor escurecida 0,5 s no erro | `jul_*` (o kit) |
| o esmagado | o dono | `explosao` (1,0 / 1,0), 400 ms | Off | um degrau abaixo (`BRILHO[vida]`), depois do piscar do kit | — |
| a lanterna-fantasma acende | o fantasma | `acerto` (0,3 / 0,6), 80 ms | — | — | — |
| começar | todos | — | R2 Off; o L2 é do item (G03) | `BRILHO[3]` = 100 % | — |

- A barra de luz é sempre a cor do lugar, com o brilho da vida (40 % a 100 %, nunca abaixo do piso de 30 % da
  F04); o fantasma fica em 40 %. Ela nunca mostra o lado.
- As luzinhas de jogador mostram o número, sempre (também o fantasma). O microfone não se usa.
- **Os outros não sentem nada** da pista de um: o isolamento se mede (as `chance`).

### O robô

```gdscript
# O robô sente a pista no controle simulado: o golpe (forte acima de 0,9 e
# fraco entre 0,4 e 0,8) é "fuja", para o lado com espaço; um motor só é o
# lado seguro. A explosão do esmagado (os dois cheios) e as sensações do kit
# (o forte abaixo de 0,9) não são pista. Foge na batida seguinte, pelo
# relógio da música. O fantasma aperta ✕ nas batidas dele.
var _robo_ligado := [false, false, false, false]
var _robo_alvo := [-1.0, -1.0, -1.0, -1.0]
var _robo_para := [0, 0, 0, 0]  ## -1 esquerda, +1 direita
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if int(vida[l]) == 0:
		_robo_fantasma(l)
		return
	var pc := Forja.percepcao(l)
	if pc.is_empty():
		return
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var para := 0
	if forte > 0.9 and fraco > 0.4 and fraco < 0.8:
		# qualquer lado: do canto, para o meio; do meio, pela paridade da batida
		para = 1 if int(pos[l]) == 0 else (-1 if int(pos[l]) == 2 else (1 if int(Ritmo.batida()) % 2 == 0 else -1))
	elif forte > 0.3 and fraco < 0.05:
		para = -1
	elif fraco > 0.3 and forte < 0.05:
		para = 1
	var pista := para != 0
	if pista and not _robo_ligado[l] and _robo_alvo[l] < 0.0:
		_robo_alvo[l] = roundf(Ritmo.batida() + CenarioDoImpacto.antecedencia(l) * Ritmo.bpm / 60.0) + 1.0
		_robo_para[l] = para
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	_robo_ligado[l] = pista
	if _robo_alvo[l] >= 0.0 and Ritmo.t_musica() >= Ritmo.t_da_batida(_robo_alvo[l]) + float(_robo_atraso[l]):
		Forja.robo_eixo(l, Forja.LX, float(_robo_para[l]), 0.1)
		_robo_alvo[l] = -1.0


## O fantasma: ✕ em toda batida dele, pelo relógio da música.
func _robo_fantasma(l: int) -> void:
	var b := int(ceilf(Ritmo.batida()))
	if l in _donos(b) and float(_robo_alvo[l]) != float(b) and Ritmo.t_musica() >= Ritmo.t_da_batida(b) - 0.02:
		_robo_alvo[l] = float(b)
		if Forja.robo_acerta():
			Forja.robo_apertar(l, Forja.CRUZ, 0.06)
```

O robô não lê a partitura: se a vibração não chegou ao controle simulado, ele não foge. A mesma conta roda no
controle simulado da prova do jogo e no da prova visual.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como
estão, de frente para a câmera. `posicionar(l)` deixa as mãos livres: a arma ou o amuleto não aparece, mas o efeito
do item vale. O cavaleiro pode ser de outra raça (G13, o ajuste dela de 09/10): esta ficha não supõe corpo humano;
usa só o esqueleto comum de 7 ossos, a escala do nó raiz (o achatado é `scale.y` do boneco inteiro) e as animações
`jump`, `fall`, `die` e `idle`.

| stat | gancho | o que muda na Prensa | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | — | não age: ninguém é empurrado | — | — | — |
| Passo | `velocidade` | sair de baixo da prensa: o pulo de um lugar ao vizinho | 0,128 s | 0,120 s | 0,113 s |
| Fôlego | — | não age: o esmagado volta em 1 batida, e o fantasma não levanta | — | — | — |
| Faro | `pista` | a vibração forte avisa antes; a prensa cai no mesmo tempo | −40 ms | 0 | +40 ms |
| Faro | `raio` | a luz da raia mostra mais chão; a lanterna-fantasma dele acende mais larga nas raias dos outros | ×0,8 | ×1,0 | ×1,2 |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Âncora não age (nada empurra); a Lanterna adianta a pista
meio tempo (`Itens.antecipacao_s`, dentro do `antecedencia`), até o piso depois da esquiva anterior; o Martelo dobra
o perfeito no tempo forte (o kit). Nenhum stat muda a janela, os pontos, onde a prensa cai ou o esmagado: o pulo
mais rápido é só do corpo (o julgamento é pelo instante do analógico).

## As reações

- **Carimbos que A Prensa pode disparar** (do kit e do HUD, G04; o minigame não chama nenhum): `car_em_chamas`
  (5 esquivas Ressonância seguidas do mesmo lugar); `car_por_um_fio` (no resultado, quando o vencedor ganha por 2 %
  dos pontos ou menos). O `car_acorde` não acontece: no máximo dois donos por batida.
- **Adesivos:** só quem está fora da rodada manda: o fantasma (`fora_da_rodada(l)` devolve `true` com vida 0). A
  roda de adesivos (G04) lê esse gancho; até ela o ler, ninguém manda.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: o esmagado** (`esmagado`). A prensa desce em quem não fugiu e o cavaleiro fica achatado a 30 % da
altura; a brasa da vida dele voa 2,5 m da lanterna em direção ao meio da tela, solta 48 faíscas na cor do lugar e
cai apagada. A câmera treme 0,05 m por 2 batidas e a luz das outras raias cai 30 % por 1 batida: o grito de alívio
dos outros e o de dor de quem levou. Degrau estrondo.

- **Rastro:** a marca da prensa no chão (o quadrado escuro) e a brasa apagada ficam 4 s; a lanterna fica com uma
  brasa a menos até o fim; o fantasma fica achatado e caído até o fim.
- **A curva:** de 0 a 30 s desce uma prensa, só em você (fuja para qualquer lado); de 30 a 60 s, no meio, descem
  duas e a mão diz o lado; de 60 s ao fim a luz cai, e nas últimas 16 batidas, com quatro, descem duas prensas por
  batida.
- **Ensina sem falar:** as prensas aparecem no escuro 2 batidas antes da primeira, e a da esquerda desce vazia na
  contagem, batendo no chão do lado do cavaleiro, que pula.
- **Quem está perdendo:** o fantasma acende a luz com ✕ em todas as raias **menos a do líder**: o líder fica no
  escuro, só com a mão. A pista dele vibra igual e a janela não muda.
- **A nota de hoje:** 4.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, pela
prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | o quadro de 10 s mostra uma prensa no chão ou um cavaleiro no meio do pulo |
| 4. o momento | pelo menos 6 linhas `momento` `esmagado` em 90 s, pelo menos 1 com `t_musica` < 15 | 1 quadro em 4 mostra um cavaleiro achatado |
| 5. a curva | nenhuma `pista` `esq` ou `dir` antes de 30 s; notas por segundo no pico ≥ 1,3 × as da entrada | o quadro do meio da saída é mais escuro que o do meio do pico |
| 6. a falha | o P4 tem pelo menos 3 linhas `toque` com `erro` | 1 quadro em 5 mostra o P4 achatado ou fantasma |
| 7. quem perde joga | a maior distância entre duas `nota` seguidas de cada vivo é de até 8 batidas; o fantasma do P4 tem pelo menos 1 `entrada` `fantasma_luz` | o P4 aparece em 100 % dos quadros (vivo ou fantasma) |
| 8. a câmera | cada `esmagado` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | o voo da brasa se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `esmagado`, uma `sensacao` `explosao` a até 16,7 ms | a marca no chão se vê no quadro seguinte |
| 10. o placar no mundo | a ordem do `vencedor()` bate com as brasas acesas das lanternas | no último quadro, quem olha diz a ordem pelas lanternas |

E a lanterna-fantasma: em toda `entrada` `fantasma_luz`, o `lider` não está em `acesas`.

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova do jogo confere os itens
1, 5, 8, 9 e 10 e a lanterna-fantasma com o `--robo` dela; os itens 4, 6 e 7 (que pedem o P4 `ruim`) esperam o robô
por lugar.

## Pronto quando

A Prensa joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o ruim vira
fantasma e acende a luz); aguenta o cabo que cai e volta; fecha com vencedor (o último em pé, ou os 90 s); a
lanterna-fantasma nunca acende a raia do líder; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a
prancha olhada.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` (com `--semente=N` que sorteie o
`S04_J20` na noite, pelo `Catalogo.sortear` da H08).

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## A Prensa (S04_J20): a pista chega (o golpe ou um lado), o cavaleiro fica
## num dos três lugares, o esmagado no meio da tela, a lanterna-fantasma
## nunca na raia do líder, e a colocação respeita vida e queda.
func _prova_da_prensa() -> void:
	var pista := [false]
	var fora_da_raia := [0]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			var forte := float(pc.get("forte", 0.0))
			var fraco := float(pc.get("fraco", 0.0))
			if (forte > 0.9 and fraco > 0.4 and fraco < 0.8) or (forte > 0.3 and fraco < 0.05) or (fraco > 0.3 and forte < 0.05):
				pista[0] = true
			if int(mg.pos[l]) < 0 or int(mg.pos[l]) > 2:
				fora_da_raia[0] += 1
	var mg = await _joga_o_minigame("S04_J20", 130.0, olhar)
	if mg == null:
		return
	_esperar(pista[0], "Prensa: a pista chegou a um controle simulado")
	_esperar(fora_da_raia[0] == 0, "Prensa: o cavaleiro sempre num dos três lugares (%d quadros fora)" % fora_da_raia[0])
	var v := mg.vencedor()
	for i in range(1, v.size()):
		_esperar(int(mg.vida[v[i - 1]]) >= int(mg.vida[v[i]]), "Prensa: a colocação pela vida (%s)" % [v])
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S04_J20")
	var cedo := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("o_que") in ["esq", "dir"] \
		and float(e.get("t_musica", 0.0)) < 30.0)
	_esperar(cedo.is_empty(), "Prensa: nenhum lado seguro na entrada (%d)" % cedo.size())
	for e in linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "esmagado"):
		_esperar(float(e.get("x_tela", 0.0)) >= 0.2 and float(e.get("x_tela", 0.0)) <= 0.8 \
			and float(e.get("altura_tela", 0.0)) >= 0.08, "Prensa: o esmagado no meio da tela (%s)" % [e])
	for e in linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("o") == "fantasma_luz"):
		_esperar(not (str(e.get("lider", "")) in str(e.get("acesas", "")).split(",")), "Prensa: o líder no escuro (%s)" % [e])
```

(`_joga_o_minigame` é da H08; `_linha_do_tempo` da F01. Os 90 s e o treino cabem em 130 s.)

### O que o registro mede

- Cada pista (`sensacao` `golpe`, `golpe_esq` ou `golpe_dir`, com `seq` e `ok` na `saida`, e a `pista` com `canal`
  `rumble` ou `alto_falante`).
- A `entrada` `resposta` (o lado pedido e para onde foi); o `toque` do kit. A pista de um lado com `ok` e a esquiva
  para o outro lado, repetida num controle, é o motor daquele lado que não chegou (ou chegou trocado).
- A `entrada` `fantasma_luz` (com o `lider` e as raias `acesas`) e o `momento` `esmagado`.

### As pranchas que o jogador do time olha

O quadro de 10 s (uma prensa no chão ou um pulo), o primeiro depois de cada esmagado (o achatado, a brasa no ar, a
marca), o do meio do pico e o do meio da saída (a luz que cai), um em que a lanterna-fantasma está acesa (a raia do
líder no escuro) e o último (as lanternas: o placar).

### O que o André joga e sente

`./run-local.sh -- --sala=S04_J20`, com quatro DualSense e a luz da sala apagada:

- no escuro, a mão avisa antes de a prensa aparecer; dá para jogar sem olhar;
- no meio, «só a esquerda» e «só a direita» se distinguem do «qualquer lado»;
- o esmagado é forte e engraçado; a brasa que voa diz a todos quem levou;
- o fantasma acendendo a luz ajuda quem está atrás, e o líder sente que está sozinho no escuro;
- a barra de luz escurece com a vida, na cor do lugar, e nunca apaga.

### Armadilhas

- **A pista decide onde a prensa cai pelo lugar de agora:** reposicionar entre a pista e a batida, fora da
  janela, é cedo demais (esmagado).
- **O canto e a parede:** do canto, fugir para a parede não sai do lugar (e esmaga). A pista de um lado só nunca
  manda para a parede (no canto, a pista é sempre `golpe`).
- **`golpe` × `explosao`:** a pista é o `golpe` (fraco 0,6); o esmagado é a `explosao` (fraco 1,0). O robô e o
  registro contam com a diferença.
- **O fantasma não é nota:** não chame `nova_nota`, `julgar_toque` nem `nota_perdida` para ele.
- **`preso = true`:** o analógico é entrada do minigame; sem ele, o boneco anda sozinho pela física.
- **O terror escurece a luz da casa:** nenhuma luz de outra cor; a única cor saturada é a dos lugares.
- **As luzes da casa** se guardam logo depois do `montar`, antes de qualquer `OmniLight3D` do minigame.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_toque` (H08); marque cru.

### Ao terminar

- No [quadro](README.md): a linha **L5**, com o commit (`feito (<commit>)`). Com as cinco feitas, a linha **L** da
  seção também vira **feito**.
- Commit sugerido (sem trailer): `feat: A Prensa, o terror d'O Impacto, a mão que avisa antes do olho`
