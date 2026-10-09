# N2 — Eco do Abismo

**Sprint:** N · **Slot:** S06_J27 · **Tamanho:** M · **Depende de:** N1, G03, H04, H06, H07, H08, F02, F04, F05, F09, G05, G08, G10, G14, G15

## Por quê

A corrida no escuro da seção. Cada cavaleiro sobe a sua escada para o breu; em cada degrau há duas pedras iguais,
uma firme e uma oca. Uma batida antes do passo, o eco no alto-falante da mão diz o lado firme: grave é a esquerda,
agudo é a direita. Quem ouve sobe; quem pisa no lado errado despenca. O verbo do alto-falante aqui é **seguir**: a
pista vem já, e a resposta é o próximo passo. A altura na escada é o placar, e a sala vê quem cai.

## Ler antes

- [A N1, «A cena»](N1-o-canto.md#a-cena) (o `CenarioDoCanto` inteiro: a capela, o `falante`, o `ouvir`, os ganchos, a `momento`)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04)
- [O molde de minigame](molde-de-minigame.md)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s06/eco_do_abismo.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S06_J27` em `MINIGAMES` e na lista da seção `S06` | **da seção** |
| `godot/scripts/traducoes.gd` | `"Eco do Abismo": "Echo of the Abyss"`, `"Ouça e pise!": "Listen and step!"`, `"Pise!": "Step!"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_eco()` e a linha `"S06_J27": await _prova_do_eco()` no `match` do `_prova_da_ficha(slot)` (H08) | **de todos** |
| `scripts/importar_kenney.py` | a linha `modular-cave-kit` em `APROVADOS` (papel `cenario`, filtro tudo) | **de todos** |
| `godot/assets/kenney/modular-cave-kit/`, `godot/assets/LEIA-ME.md`, `LICENCAS-DE-TERCEIROS.md` | o que o import escreve | **de todos** |

Antes de tudo: `python3 scripts/importar_kenney.py modular-cave-kit`. O `graveyard-kit` a G10 já trouxe. O `.uid` de
`eco_do_abismo.gd` sai de `"$GODOT" --headless --path godot --import --quit` e entra no commit.

O `cenario_do_canto.gd` é da N1: esta ficha **só chama**. Se a N1 ainda não entrou, ela vem antes.

### O que muda de hoje

O Eco não existe hoje. Esta ficha o escreve inteiro no kit, sobre o cenário comum da N1. O que muda da ficha antiga:
`_notas` era declarada no minigame (agora é do kit, e o dado do passo mora em `_info`), o robô contava o nível do
alto-falante à mão (agora usa `CenarioDoCanto.ouvir`), a câmera era uma pose solta (agora é a da capela, mais alta),
as cores eram hex (agora são tokens) e a queda não tinha momento (agora é o `despenca`).

### O kit que esta ficha usa

As funções do `Minigame` (H04, H08) e do `CenarioDoCanto` (N1). Não reimplemente:

```gdscript
presentes(); conectado(l); na_raia(l); raia(l); jogador(l); posicionar(l); marcar(l, pontos); anotar(tipo, l, campos)
nova_nota(l, n, t_alvo); notas_em_aberto(l); alvo_da(l, n); casar_toque(l); julgar_nota(l, n); nota_perdida(l, n); notas_perdidas(l)
andamento(); no_pico(); momento(nome, l, pos, altura_m, campos)   # o momento é da N1 (ou da L1)
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
var _notas := [{}, {}, {}, {}]  # do kit: não declare
CenarioDoCanto.montar(sala, escuro, com_portico); pose_da_camera(recuo, olhar); passar; exagero; so_o_dono
CenarioDoCanto.gancho(l, nome); antecedencia(l); queda(l, tempos); proxima_colcheia(folga_s)
CenarioDoCanto.falante(sala, l, som, ganho); tempo_forte(); soltar_a_musica(sala); ouvir(l, o); luz_da_nota(l, forca)
Itens.velocidade(l, "corrida"); Itens.resiste_a_empurrao(l)    # a Âncora: 0,9 e 0,5; os outros: 1,0 e 0,0
Forja.eixo(l, Forja.LX); Forja.robo_eixo(l, Forja.LX, v, s); Forja.gatilho(l, 1, modo, a, b); Forja.sentir(l, nome)
```

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Eco do Abismo (S06_J27) — cada um numa escada que sobe para o escuro. Na
## vez do dono, ele sobe um degrau; uma batida antes, o eco no alto-falante do
## controle dele diz o lado firme: grave, a esquerda; agudo, a direita. Pise
## com o analógico esquerdo (um toque para o lado) na batida. No pico, o eco
## vem em colcheias: dois passos por vez.
##
## A falha: o lado errado — a pedra oca afunda e ele despenca 4 degraus (o
## Peso e a Âncora mudam); fora do tempo, ou sem pisar — tropeça e fica.
## O vencedor: o primeiro no topo (60 degraus); senão, o mais alto aos 100 s.
## O alto-falante do dono: o eco (a pista) e o tombo.
## O registro mede: cada eco (o som, se foi ao controle), o lado pisado e o
## momento `despenca`.
## O robô: ouve o eco no alto-falante simulado e pisa no tempo do lado que
## ouviu; quando não acerta, pisa 250 ms tarde (tropeça) ou do outro lado.
## Com menos de quatro: a vez roda mais depressa; sozinho, só as batidas pares.
## A régua: (1) «Ouça e pise!» com as escadas no escuro; (2) sim: as duas
## pedras são iguais, só o eco diz; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J27",
	"titulo": "Eco do Abismo",
	"verbo": "Ouça e pise!",
	"genero": "corrida",
	"icone": "alto_falante",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S06_J27",
	"duracao": 100.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Pise!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca nada nele (H08)
	"papel_som": Forja.PAPEL_ALTO_FALANTE,
	"gesto": "lados",
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const DEGRAUS := 60  ## o número do diretor de jogo (09/10): o topo só na reta; veja «A diversão»
const ANDAR := 4  ## quanto despenca no lado errado, no neutro
const ANDAR_MIN := 2
const ESQ := 0
const DIR := 1
const ECO := ["nota", "nota_alta"]  ## ESQ grave, DIR agudo
const LX_VAI := 0.6
const LX_VOLTA := 0.3
const ESCURO := 0.4  ## a capela escurecida (o terror): a luz da casa cai, não troca
const BRILHO := 0.5  ## a barra de luz no escuro (F04: nunca abaixo de 0,3)
const PULSO_S := 0.12
## A chance de passo na vez do dono, por terço; no pico, dois passos por vez.
const CHANCE := [0.5, 0.75, 0.75]
## A escada tem o mesmo tamanho da de 24 degraus (5,28 m de alto, 6,72 m de fundo): a pedra é que afina.
const DEGRAU_ALTURA := 0.088
const DEGRAU_FUNDO := 0.112
const ALTURA_DO_CAVALEIRO := 1.1  ## o cavaleiro em pé (o mesmo da N4 e da N5): a medida do tombo na tela
const PEDRA_X := 0.45  ## as duas pedras em ESCADA_X[l] ± isto
## As escadas puxadas 0,6 m para o centro: o P4 cabe em x_tela ≤ 0,8.
const ESCADA_X := [-5.4, -1.4, 1.4, 5.4]
const RETA_BATIDAS := 16  ## nelas, cada passo certo sobe 2 degraus
const SENTADO_TEMPOS := 1.0  ## depois do tombo, sentado 1 tempo (o Fôlego muda)
const OLHAR := Vector3(0, 2.6, -2.2)  ## o meio das escadas
```

### O tempo

A faixa `MUS_S06_J27` tem 135 BPM: 1 batida = 0,444 s. Em 100 s, `_b_fim` = 225. O pico (`no_pico()`, o terço do
meio) vai de 33,3 a 66,7 s (batidas 75 a 150). A reta são as batidas 209 a 224.

**A vez do dono:** `lista = presentes()` em ordem; o dono da batida `b` é `lista[b % k]`; sozinho, só as batidas
pares. O compasso `c` (batidas `4c` a `4c+3`) se gera quando `Ritmo.batida() >= 4c − 4`; o compasso 0 é a contagem.

**O passo** na vez do dono, na batida `b`, com a chance `CHANCE[parte]` (a parte pelo `Ritmo.t_da_batida(b)` contra
os terços de `duracao`). **Nunca duas vezes seguidas sem passo**: se a vez anterior do lugar não teve passo, esta tem.
No pico, um segundo passo em `b + 0,5` (quem está com `Ritmo.simples[l]` fica só com o de `b`). Cada passo:
`n = int(round(b * 2))`, `_info[l][n] = {"b": b, "lado": ESQ ou DIR, "ecoou": false}` e
`nova_nota(l, n, Ritmo.t_da_batida(b))`.

As contas da régua 5, com quatro jogadores (a vez de cada um a cada 4 batidas, 1,78 s). Com «nunca duas vezes seguidas
sem passo», a vez tem passo em 1 / (2 − chance) das vezes: 0,67 no 1.º terço, 0,8 no pico e no 3.º. Então: 1.º terço
0,375 passo/s por jogador; pico 0,90 (2,4×); 3.º terço 0,45 (1,2×; o robô mede 1,18× pela borda dos terços). A maior
distância entre dois passos do mesmo lugar: 8 batidas.

| terço | música | o passo | o que acontece |
| --- | --- | --- | --- |
| 1. ensina | 0–33 s | um por vez, chance 0,5 | as pedras acendem na contagem; o eco uma batida antes |
| 2. **o pico** | 33–67 s | dois por vez, em colcheia | aos 33 s, o trovão; a luz +20 %, a câmera recua |
| 3. a reta | 67–100 s | um por vez, chance 0,75 | as velas do topo acendem; nas últimas 16 batidas, 2 degraus por passo |

### O eco

Quando `Ritmo.t_musica() >= Ritmo.t_da_batida(b - 1) - CenarioDoCanto.antecedencia(l)` (o Faro e a Lanterna adiantam
o eco; o passo fica no tempo): `var foi := CenarioDoCanto.falante(self, l, ECO[lado], 0.9)` e
`anotar("pista", l, {"n": n, "evento": "mandou", "canal": "alto_falante", "o_que": ECO[lado], "no_controle": foi})`;
`_info[l][n].ecoou = true`. Na tela, nada muda: as duas pedras do degrau seguinte são iguais. Se `_eco_na_tv[l]` (o
tombo, abaixo), o eco toca também na TV, uma vez: `Som.tocar(ECO[lado], jogador(l).global_position, -8.0)`, e
`_eco_na_tv[l] = false`.

### Pisar

O analógico esquerdo passando de `LX_VAI` para um lado (esquerda negativa), rearmando abaixo de `LX_VOLTA`:

```gdscript
func _pisar(l: int, lado: int) -> void:
	var nn := casar_toque(l)
	if nn < 0:
		jogador(l).gesto("emote-no", 0.2)  # nenhum passo perto: ele olha para o lado
		return
	_ultima[l] = _info[l].get(nn, {}).duplicate()
	_ultima[l]["feito"] = lado
	anotar("entrada", l, {"o": "resposta", "n": nn, "lado_pedido": int(_ultima[l].lado), "lado_feito": lado})
	if lado == int(_ultima[l].lado):
		julgar_nota(l, nn)  # BOM ou melhor sobe; ERRO tropeça
	else:
		nota_perdida(l, nn)  # a pedra oca: despenca
```

O passo que passa de `FOLGA_PERDIDA` (0,14 s) sem pisada é `nota_perdida` pelo `_passaram(l)` (o da N1): tropeça e
fica (o `_ultima[l]` sem `feito`).

**Subir** (no `toque`): `marcar(l, PONTOS[julgamento])`; `subida[l] += CenarioDoCanto.gancho(l, "velocidade") *
Itens.velocidade(l, "corrida") * (2.0 if _reta else 1.0)`; `degrau[l] = mini(DEGRAUS, floori(subida[l]))`. O
cavaleiro vai ao degrau novo em 0,15 s (curva `QUAD` `EASE_OUT`, `gesto("walk", 0.3)`), sobre a pedra do lado pisado;
a pedra firme acende na cor do lugar (`Tema.emissivo(mat, 0.8, l)`) e fica acesa: o caminho. Na TV:
`Som.tocar("pedra", pos, -14.0)`.

**O topo:** quando alguém chega a `DEGRAUS`, todos `acabou` no mesmo quadro e o kit fecha (`primeiro_a_chegar`).
Senão, os 100 s.

### O tombo (a pedra oca)

Na `falha` com `feito` diferente de `lado`:

1. `cai = maxi(ANDAR_MIN, roundi(ANDAR * CenarioDoCanto.gancho(l, "empurrao") * (1.0 - Itens.resiste_a_empurrao(l))))`;
   `subida[l] = maxf(0.0, subida[l] - cai)`; `degrau[l] = floori(subida[l])`.
2. A pedra oca afunda: tween de `y` −3 em 0,5 s, e some. No lugar fica o buraco:
   `Kit.caixa(self, Vector3(0.8, 0.02, 0.26), topo_da_pedra, Kit.material(Tema.JANELA, 0.0, 1.0))`, até o fim.
3. As pedras acesas acima do degrau novo apagam (`Tema.emissivo(mat, 0.0, l)`).
4. `_cai_em[l] = CenarioDoCanto.proxima_colcheia(0.15)`; o cavaleiro despenca até o degrau novo (curva `QUAD`
   `EASE_IN`, chegando nessa colcheia), com `gesto("fall", 0.6)`; no alto-falante dele,
   `CenarioDoCanto.falante(self, l, "nota_alta", 0.9)`.
5. **Quando `Ritmo.batida() >= _cai_em[l]`** (`_bater(l)`): `Som.tocar("golpe", pos, -6.0)` e
   `Som.tocar("pedra", pos, -4.0)` na TV; `CenarioDoCanto.falante(self, l, "nota", 0.9)` (o fim do tombo, grave);
   `Forja.sentir(l, "golpe")`; o R2 em Resistência (`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)`) por
   0,25 s, depois Off; `CenarioDoCanto.exagero(self, _cenario, "estrondo", jogador(l))`;
   `CenarioDoCanto.so_o_dono(self, l)`; 48 faíscas `Tema.GRAFITE` (`Efeitos.faiscas(self, pos, Tema.GRAFITE, 48, 1.0)`);
   `jogador(l).gesto("sit", sentado_s)`; e
   `momento("despenca", l, Vector3(ESCADA_X[l], DEGRAU_ALTURA * degrau[l], Z_JOGADOR - DEGRAU_FUNDO * degrau[l]), _altura_do_tombo(l), {"degraus": cai})`
   (o `_altura_do_tombo` está no fim de «O cavaleiro»).
6. **Sentado** por `CenarioDoCanto.queda(l, SENTADO_TEMPOS)` batidas (0,75 a 1,25): os passos dele com alvo nesse
   tempo saem da fila sem julgar (`_notas[l].erase(nn)` e `_info[l].erase(nn)`: o kit não tem função para isso) e
   não ecoam.
7. `_eco_na_tv[l] = true`: o próximo eco dele toca também na TV, e a sala ouve com ele.

**Tropeçou** (ERRO no tempo, ou o passo passou): `gesto("emote-no", 0.3)`, e fica.

### O pico

Na primeira batida com `no_pico()`: `Som.tocar("golpe", Vector3(0, 4.0, -6.0), -4.0)` (o trovão no fundo da caverna),
`Forja.sentir(l, "golpe")` em todos com controle (sem gatilho), e o `CenarioDoCanto.passar` sobe a chave 20 % e recua
a câmera 10 %.

### A reta

Na batida `_b_fim - RETA_BATIDAS` (209), uma vez: as velas do topo acendem (A cena) e
`momento("reta", -1, Vector3(0, 0, Z_JOGADOR), 1.8, {"objeto": "escadas", "valores": "51,15,14,1"})`, com o degrau de
P1 a P4 (`-` para quem não está). Daí até o fim, cada passo certo sobe 2 degraus.

### O ensina

Na contagem (compasso 0), as pedras do primeiro degrau de cada escada falam: na batida 1, as da esquerda acendem
(`Tema.emissivo(mat, 0.8, l)`) e a TV toca `Som.tocar("nota", Vector3(0, 1.0, Z_JOGADOR), -8.0)`; na batida 2, as da
direita acendem e a TV toca `"nota_alta"` a −8 dB; na batida 3, as duas apagam. Depois, o som só vem do controle.

### O fim e o vencedor

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if float(subida[a]) != float(subida[b]):
			return float(subida[a]) > float(subida[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

Quem chegou ao topo tem `subida >= DEGRAUS` e vem primeiro. Com dois no topo no mesmo quadro, quem passou mais
desempata; depois, os pontos.

### Com menos de quatro

- **Três e dois:** a roda do dono anda mais depressa (a vez a cada 3 ou 2 batidas): mais passos para cada um.
- **Um:** só as batidas pares; a corrida é contra os 100 s. `com_poucos()` devolve `""`.
- **O controle que cai:** os ecos dele não tocam e os passos saem calados (`notas_perdidas(l)`); ele fica no degrau, e
  volta a subir no próximo passo que ainda não chegou.

### Os ganchos

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

```gdscript
var _info := [{}, {}, {}, {}]  ## lugar -> {n: {b, lado, ecoou}}
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _b_fim := 0
var _sem_passo := [false, false, false, false]  ## a vez anterior não teve passo
var _armado := [true, true, true, true]
var subida := [0.0, 0.0, 0.0, 0.0]
var degrau := [0, 0, 0, 0]
var _lado := [ESQ, ESQ, ESQ, ESQ]  ## a pedra em que ele está
var _pedras := {}  ## lugar -> [[{no, mat}, {no, mat}] por degrau, do 1 ao 60]
var _cai_em := [-1.0, -1.0, -1.0, -1.0]
var _ultimo_tombo := [0, 0, 0, 0]
var _sentado_ate := [-1.0, -1.0, -1.0, -1.0]
var _gatilho_ate := [-1.0, -1.0, -1.0, -1.0]
var _eco_na_tv := [false, false, false, false]
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _pico_tocou := false
var _reta := false
var _velas := []
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoCanto.pose_da_camera(1.0, OLHAR)
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoCanto.montar(self, ESCURO, false)
	_b_fim = int(floor(duracao * Ritmo.bpm / 60.0))
	_montar_a_caverna()  # as rochas, a plataforma do topo e as velas
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.position = Vector3(ESCADA_X[l], 0.0, Z_JOGADOR)
		p.rotation.y = PI  # de costas: ele sobe para o fundo
		p.preso = true
		_pedras[l] = _montar_a_escada(l)
		_luz_do_cavaleiro(l)
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	for l in presentes():
		CenarioDoCanto.luz_da_nota(l, BRILHO)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()  # o sino da capela, longe, no tempo 1
	while _gerado <= c + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	_ensinar()  # só no compasso 0
	_pico_no_tempo()
	_reta_no_tempo()
	CenarioDoCanto.passar(self, _cenario, no_pico())
	for l in presentes():
		_apagar_o_pulso(l, dt)  # volta a luz_da_nota(l, BRILHO)
		_tombo_no_tempo(l)  # o _bater, o gatilho que volta, o fim do sentado
		if not conectado(l):
			notas_perdidas(l)
			continue
		_ecoar(l)
		var lx := Forja.eixo(l, Forja.LX)
		if _armado[l] and absf(lx) >= LX_VAI:
			_armado[l] = false
			_pisar(l, ESQ if lx < 0.0 else DIR)
		elif absf(lx) <= LX_VOLTA:
			_armado[l] = true
		_passaram(l)
	if presentes().any(func(l): return int(degrau[l]) >= DEGRAUS):
		for l in presentes():
			acabou[l] = true


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])
	subida[l] = float(subida[l]) + CenarioDoCanto.gancho(l, "velocidade") * Itens.velocidade(l, "corrida") * (2.0 if _reta else 1.0)
	degrau[l] = mini(DEGRAUS, floori(subida[l]))
	_lado[l] = int(nt.lado)
	_subir(l)  # o tween, a pedra firme acesa, "pedra" −14 na TV
	CenarioDoCanto.luz_da_nota(l, 1.0)
	_pulso[l] = PULSO_S


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	_ultima[l] = {}
	if int(nt.get("feito", -1)) >= 0 and int(nt.feito) != int(nt.lado):
		_tombar(l, int(nt.feito))
	else:
		jogador(l).gesto("emote-no", 0.3)


func status(l: int) -> String:
	return "" if na_raia(l) else super(l)


func dica(_l: int) -> Dictionary:
	return {}


func com_poucos() -> String:
	return ""


func _exit_tree() -> void:
	CenarioDoCanto.soltar_a_musica(self)
```

`_passaram(l)` é o da N1 (copie). `_gerar_compasso(c)`, `_ecoar(l)`, `_subir(l)`, `_tombo_no_tempo(l)`, `_bater(l)`,
`_ensinar()`, `_pico_no_tempo()`, `_reta_no_tempo()`, `_apagar_o_pulso(l, dt)`, `_montar_a_caverna()`,
`_montar_a_escada(l)`, `_luz_do_cavaleiro(l)`, `_afundar(pedra)`, `_apagar_acima(l)` e `_pos_no_degrau(l)` fazem o que
as partes desta ficha dizem.

O catálogo: `Catalogo.MINIGAMES["S06_J27"] = preload("res://scripts/minigames/s06/eco_do_abismo.gd")` e `"S06_J27"`
na lista `"minigames"` da seção `S06`. As traduções da tabela de cima.

## A cena

### A câmera

A da capela (N1), mais alta: `CenarioDoCanto.pose_da_camera(1.0, OLHAR)`, com `OLHAR = (0, 2,6, −2,2)`: a câmera em
`(0, 16,39, 9,37)`, 35 mm, plongée de 50°, modo `fixa`. O quadro vê as quatro escadas inteiras, do pé (z = 1,4, y = 0)
ao topo (z = −5,3, y = 5,5): o raio de cima passa 31° abaixo da horizontal, e o cavaleiro em pé no topo está a 33°.
Nenhum corte, do apito ao apito. No pico, `pose_da_camera(1.1, OLHAR)`. O tremor é só o do `exagero`. O modo é `fixa`,
não `corrida`: a escada segura cada um no degrau, e a câmera de corrida da G05 puxaria os de trás.

### A luz da seção

A da N1, escurecida: `CenarioDoCanto.montar(self, 0.4, false)`: a névoa `#050d26` do lado B (o main), o
preenchimento `#1f346a` a 0,08, a chave `#e5d3c6` com energia 0,19 (0,47 × 0,4), as tochas `Tema.TUNGSTENIO` a 0,36.
Sem pórtico. O que se vê no escuro é a luz de cada cavaleiro e o caminho aceso.

- **A luz do cavaleiro:** uma `OmniLight3D` filha do boneco, em `(0, 1.2, 0)`, cor `Tema.JOGADOR[l]`, energia 0,8,
  alcance `2.2 * CenarioDoCanto.gancho(l, "raio")` (o Faro: 1,76 m a 2,64 m).
- **As velas do topo:** apagadas até a reta; nela, uma `OmniLight3D` `Tema.TUNGSTENIO` por vela, energia 0,6, alcance 4.
- **O pico:** a chave +20 % em 1 batida (com `Opcoes.flashes` desligado, +10 % em 2).

### As peças Kenney e o papel de cada uma

O fator do `modular-cave-kit` é 0,25: a escala 4 dá o tamanho cru.

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `wall` | `Kit.arena(sala, 5, 3)` (o cenário comum) | o chão e as paredes |
| `castle-kit/tower-hexagon-base` e `roof` | as torres do cenário comum, em `(±7,6, 0, −5,4)` | os lados do fundo |
| `modular-cave-kit/gate-rock` (escala 4: 4 × 2,46 m, 4,05 m de alto) | `(0, 0, −6.4)` | a boca da caverna atrás do topo |
| `modular-cave-kit/template-wall` (escala 4: 4,05 m) | `(±3.4, 0, −6.4)` | a rocha do fundo, dos dois lados da boca |
| `graveyard-kit/lantern-candle` (escala 2) | `(ESCADA_X[l], 5.5, −5.75)`, uma por escada | as velas do topo |

O que não é peça Kenney (caixas do `Kit`; `metallic` 0):

| objeto | forma | material |
| --- | --- | --- |
| a pedra (duas por degrau, 60 degraus, 4 escadas) | caixa 0,8 × 0,05 × 0,10 em `(ESCADA_X[l] ± 0.45, 0.088k − 0.025, Z_JOGADOR − 0.112k)` | `Kit.material(Tema.GRAFITE, 0.0, 0.95)`, uma por pedra |
| a pedra acesa (o caminho) | a mesma | `Tema.emissivo(mat, 0.8, l)` |
| o buraco da pedra oca | caixa 0,8 × 0,02 × 0,10 no topo da pedra que caiu | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| a plataforma do topo | caixa 12,4 × 0,3 × 0,5 em `(0, 5.35, −5.75)` | `Kit.material(Tema.GRAFITE, 0.0, 0.95)` |

As duas pedras de um degrau são **iguais**: o mesmo tamanho, a mesma cor, nenhum brilho antes de pisada. A firme é a
do `lado` do passo; ela só existe na partitura.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a pedra pisada (o caminho) | o lugar | 0,8, até o tombo apagar |
| as pedras do ensina | o lugar | 0,8, por 1 batida |
| a luz do cavaleiro | o lugar | luz 0,8, alcance 2,2 × `raio` |
| as velas do topo | a forja | luz `Tema.TUNGSTENIO` 0,6, na reta |
| as faíscas do tombo | ninguém (cinza) | `Efeitos.faiscas(self, pos, Tema.GRAFITE, 48, 1.0)` |

Nenhuma cor fora dos tokens: o `#2a2233`, o `#ffb070` e o `#b9b0ff` da ficha antiga somem.

### A montagem

- Por lugar: `raia(l)` (o chão de partida), `posicionar(l)`, depois `position = (ESCADA_X[l], 0, Z_JOGADOR)`,
  `rotation.y = PI`, `preso = true`; as 120 pedras; a luz do cavaleiro.
- A posição do cavaleiro no degrau `d`, sobre o lado `s` (ESQ −1, DIR +1):
  `Vector3(ESCADA_X[l] + s * PEDRA_X, DEGRAU_ALTURA * d, Z_JOGADOR - DEGRAU_FUNDO * d)`; no degrau 0, `x = ESCADA_X[l]`.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o eco | — (sem alto-falante: `nota`/`nota_alta` −10 dB na raia) | `"nota"` (esquerda) ou `"nota_alta"` (direita), 0,9 | `mod_nota`, `mod_nota_alta`; `sint_nota`, `sint_nota_alta` |
| o eco depois do tombo (uma vez) | `nota`/`nota_alta` −8 dB, no cavaleiro | o mesmo eco | `sint_nota`, `sint_nota_alta` |
| o passo certo | `Som.tocar("pedra", pos, -14.0)` | — | `pedra_0..4` |
| o tropeço | a falha do kit (−6) | — | `falha_0..2` |
| o tombo, ao pisar | — | `"nota_alta"`, 0,9 | `mod_nota_alta` |
| o tombo, ao bater | `Som.tocar("golpe", pos, -6.0)` e `Som.tocar("pedra", pos, -4.0)` | `"nota"`, 0,9 | `golpe_0..4`, `pedra_0..4`; `mod_nota` |
| o trovão do pico | `Som.tocar("golpe", Vector3(0, 4, -6), -4.0)` | — | `golpe_0..4` |
| o ensina | `nota` e `nota_alta` −8 dB | — | `sint_nota`, `sint_nota_alta` |
| o tempo forte | `Som.tocar("sino", SINO_TV, -16)` | — | `sint_sino` |
| a faixa | `MUS_S06_J27`: 135 BPM, Mi♭ menor, 150 s (toca 100); até ela existir, `sint_trilha` | — | `mus_s06_j27` |

- **A música abaixa na pista:** todo `falante` chama `abaixar_a_musica` (−12 dB por 1 batida, volta em 300 ms).
- `nota_no_falante` false: o kit não toca nada no alto-falante. O `jul_*` da H11 também não vai a ele.
- O material `"pedra"`: a textura do acerto na háptica (o kit).

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| o eco | só o dono | — | — | — | `nota` / `nota_alta`, 0,9 |
| o passo BOM ou ÓTIMO | o dono | `acerto` (0,3 / 0,6, 80 ms; o kit) | — | 100 % por 0,12 s, volta a 50 % | — |
| o passo PERFEITO | o dono | `perfeito` (0,5 / 0,8, 100 ms; o kit) | — | o kit: branco 0,15 s | — |
| o tropeço | o dono | `erro` (0,7 / 0,3, 160 ms; o kit) | — | o kit: escurecida 0,5 s | — |
| o tombo, ao bater | o dono | `golpe` (1,0 / 0,6, 250 ms) | R2 em Resistência (2, 4) por 250 ms, depois Off | — | `nota_alta` e `nota` |
| o trovão do pico | todos | `golpe` | — | — | — |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar a 50 % | — |

A barra de luz fica a 50 % no escuro (o piso da F04 é 30 %) e nunca diz o lado. Fora da bancada, nunca pergunta.

### O robô

```gdscript
# O robô ouve o eco no alto-falante simulado (CenarioDoCanto.ouvir) e guarda o
# instante e o som. No tempo de cada passo, procura o eco ouvido uma batida
# antes (menos a antecedência dele). Se ouviu, pisa do lado que ouviu; quando
# não acerta, sorteia de novo: 250 ms tarde (tropeça) ou do outro lado (cai).
var _ouvido := [{}, {}, {}, {}]
var _robo_ouviu := [[], [], [], []]  ## lugar -> [[t, som], ...], os últimos 8
var _robo_feita := [-1, -1, -1, -1]
var _robo_tarde := [[-1.0, 0], [-1.0, 0], [-1.0, 0], [-1.0, 0]]  ## [quando, lado]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var a := CenarioDoCanto.ouvir(l, _ouvido[l])
	if not a.is_empty():
		_robo_ouviu[l].append([float(a.t), str(a.som)])
		if _robo_ouviu[l].size() > 8:
			_robo_ouviu[l].pop_front()
	var agora := Ritmo.t_musica()
	if float(_robo_tarde[l][0]) >= 0.0 and agora >= float(_robo_tarde[l][0]):
		Forja.robo_eixo(l, Forja.LX, -1.0 if int(_robo_tarde[l][1]) == ESQ else 1.0, 0.1)
		_robo_tarde[l][0] = -1.0
	var batida := 60.0 / Ritmo.bpm
	for nn in notas_em_aberto(l):
		if nn <= int(_robo_feita[l]):
			continue
		var t := alvo_da(l, nn)
		if agora < t:
			return
		_robo_feita[l] = nn
		var quando := t - batida - CenarioDoCanto.antecedencia(l)
		for o in _robo_ouviu[l]:
			if absf(float(o[0]) - quando) <= 0.12 and ECO.has(str(o[1])):
				var lado := ECO.find(str(o[1]))
				if Forja.robo_acerta():
					Forja.robo_eixo(l, Forja.LX, -1.0 if lado == ESQ else 1.0, 0.1)
				elif Forja.robo_acerta():
					_robo_tarde[l] = [agora + 0.25, lado]
				else:
					Forja.robo_eixo(l, Forja.LX, 1.0 if lado == ESQ else -1.0, 0.1)
		return
```

O `robo_eixo` dura 0,1 s e volta ao meio: isso rearma a pisada. O robô não lê `_info`: se o eco não saiu do
alto-falante simulado, ele não pisa (e tropeça). No médio (66 % de acerto), ele cai em 12 % dos passos e tropeça em
22 %. A mesma conta roda no controle simulado da prova do jogo e no da prova visual.

## O cavaleiro

O cavaleiro da montagem (G13), de costas, subindo. A cabeça, a parte de cima e a de baixo aparecem como estão; as
mãos ficam livres (`posicionar`), e o efeito do item vale. Ele pode ser de outra raça (G08, parte B; a montagem é da G13):
esta ficha não supõe corpo humano; usa o esqueleto comum de 7 ossos e as animações `walk`, `fall`, `sit` e `emote-no`.
O conferidor da G08 não exige o `sit`: num corpo sem ele, o `gesto("sit", ...)` não faz nada (`player.gd:185`) e o
cavaleiro fica de pé o tempo do sentado. Isso é aceito; o passo segue tirado pelo `_sentado_ate`.

| stat | gancho | o que muda no Eco | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | quantos degraus o tombo tira (`round(4 × empurrao)`, mínimo 2) | 5 | 4 | 3 |
| Passo | `velocidade` | quanto cada passo certo sobe | 0,94 degrau | 1 | 1,06 |
| Fôlego | `levantar` | quanto tempo fica sentado depois do tombo | 1,25 batida | 1 | 0,75 |
| Faro | `pista` | o eco sai antes; o passo fica no tempo | 40 ms depois | no tempo | 40 ms antes |
| Faro | `raio` | o alcance da luz do cavaleiro | 1,76 m | 2,2 m | 2,64 m |

Os itens: o Escudo absorve o primeiro erro (o kit: o primeiro lado errado não derruba); a Âncora resiste ao tombo
(`resiste_a_empurrao` 0,5: 2 degraus em vez de 4) e sobe 0,9 por passo (`Itens.velocidade(l, "corrida")`); a Lanterna
adianta o eco meio tempo (0,22 s a 135 BPM); o Martelo dobra o perfeito no tempo forte (o kit); o Diapasão aumenta o
ganho da nota do acerto (1,3, o kit, fora do `tct`). Nenhum stat muda a janela de julgamento.

```gdscript
## O tombo: a pedra oca afunda, o cavaleiro cai `cai` degraus e bate no chão na
## próxima colcheia (o _bater faz o resto).
func _tombar(l: int, lado_feito: int) -> void:
	var cai := maxi(ANDAR_MIN, roundi(ANDAR * CenarioDoCanto.gancho(l, "empurrao") * (1.0 - Itens.resiste_a_empurrao(l))))
	var oca: Dictionary = _pedras[l][mini(DEGRAUS, int(degrau[l]) + 1) - 1][lado_feito]
	_afundar(oca)  # o tween de y −3 em 0,5 s, e o buraco JANELA no lugar
	subida[l] = maxf(0.0, float(subida[l]) - cai)
	degrau[l] = floori(subida[l])
	_apagar_acima(l)
	_cai_em[l] = CenarioDoCanto.proxima_colcheia(0.15)
	var dur := Ritmo.t_da_batida(_cai_em[l]) - Ritmo.t_musica()
	var p := jogador(l)
	p.gesto("fall", 0.6)
	p.create_tween().tween_property(p, "position", _pos_no_degrau(l), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	CenarioDoCanto.falante(self, l, "nota_alta", 0.9)
	_ultimo_tombo[l] = cai


## A altura do tombo na tela (o item 8), em metros na vertical do degrau novo:
## do pé no degrau novo à cabeça de quem estava `ANDAR` degraus acima. Na
## plongée, o recuo da escada (0,112 m por degrau) sobe na tela, e a conta só
## na vertical (DEGRAU_ALTURA * ANDAR + 1,1) não o vê. A câmera não gira em y:
## a altura na tela só depende de y e z, e o raio pela cabeça corta o plano z
## do degrau novo na altura que se vê.
func _altura_do_tombo(l: int) -> float:
	var d := int(degrau[l])
	var pe := Vector3(ESCADA_X[l], DEGRAU_ALTURA * d, Z_JOGADOR - DEGRAU_FUNDO * d)
	var cabeca := Vector3(ESCADA_X[l], DEGRAU_ALTURA * (d + ANDAR) + ALTURA_DO_CAVALEIRO, Z_JOGADOR - DEGRAU_FUNDO * (d + ANDAR))
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return cabeca.y - pe.y
	var na_tela := cam.unproject_position(cabeca)
	var corte = Plane(Vector3.BACK, pe.z).intersects_ray(cam.project_ray_origin(na_tela), cam.project_ray_normal(na_tela))
	return cabeca.y - pe.y if corte == null else float(corte.y) - pe.y
```

O erro não tem squash. O desregistro do erro é do kit e da G08; o Eco soma o tombo e o tropeço.

## As reações

- **Carimbos que o Eco pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar) e `car_por_um_fio` (no resultado). O `car_acorde` não acontece: os passos nunca caem no mesmo tempo para os
  quatro. O `car_virada` é do placar.
- **Adesivos:** ninguém está fora da rodada; ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: despenca** (`despenca`). A pedra oca afunda, o cavaleiro cai 4 degraus no escuro e bate na colcheia, as
pedras acesas acima dele apagam, e na escada do lado o vizinho passa por ele subindo. Degrau estrondo (tremor de
0,05 m por 2 batidas, hit-stop de 3 quadros, 48 faíscas).

- **Rastro:** o buraco escuro no degrau, até o fim; o cavaleiro sentado 1 tempo no degrau de baixo; a escada apagada
  acima dele.
- **A curva:** de 0 a 33 s, um passo por vez; de 33 a 67 s, o trovão e dois passos por vez em colcheia; de 67 s ao
  fim, um passo por vez, as velas do topo acendem, e nas últimas 16 batidas cada passo certo sobe 2.
- **A mudança: quem caiu ouve o próximo eco também na TV**, uma vez, e a sala ouve com ele.
- **Ensina sem falar:** na contagem, as pedras da esquerda acendem com o grave na TV, as da direita com o agudo.
- **Quem está perdendo:** o caminho aceso até onde ele está continua; cair custa 4 degraus, não a corrida; a reta
  dobra o passo, e quem está embaixo ainda alcança.
- **A nota de hoje:** 3.

**O número: 60 degraus** (o diretor de jogo, 09/10/2026). Com 24, o fim `primeiro_a_chegar` acabava a corrida no
pico: o robô `bom` chegava ao topo aos 47,8 s em média (p10 44,4 s), a reta (batida 209, 92,9 s) não acontecia em
nenhuma partida, e o item 5 caía com a mesa padrão. Das três saídas, fica a escada mais alta: o topo continua sendo a
linha de chegada, e chegar nele vira o grito da reta. Subir menos por passo foi descartado (o passo certo que não
muda o degrau não se vê); o mais alto aos 100 s, sem topo, também (a reta perde a chegada).

- **A escada não cresce na tela.** Os 60 degraus ocupam os mesmos 5,28 m de alto e 6,72 m de fundo dos 24: o degrau
  passa de 0,22 × 0,28 m a 0,088 × 0,112 m, e a pedra de 0,12 × 0,26 a 0,05 × 0,10. A câmera, a plataforma do topo e
  as velas ficam onde estão.
- **O tombo fica em 4 degraus** (`ANDAR`), como a reta e o Peso: o tombo é contado em passos, não em metros. Ele
  desloca o cavaleiro 0,57 m (0,35 m para baixo e 0,45 m para trás), acima dos 0,5 m da régua (item 6).
- **O tombo na tela** (o item 8). Com o degrau fino, a conta só na vertical (`DEGRAU_ALTURA * ANDAR + 1,1` = 1,45 m)
  dava `altura_tela` de 0,054 no alto da escada, no pico, abaixo do 0,08. O momento mede o que se vê, pelo
  `_altura_do_tombo`: do pé no degrau novo à cabeça 4 degraus acima, com o recuo que a plongée sobe na tela. Dá de
  0,085 (no pico, no alto) a 0,123, e o pé desce de 11 a 13 px no quadro de 480 × 270. A medida é a do tombo cheio de
  `ANDAR`, como era com 24: no pé da escada (o tombo para no 0) e com a Âncora (2 degraus), o que se vê é menor (de
  0,04, no degrau 0, a 0,10).
- **A conta pelo robô** (as regras desta ficha, 4 000 partidas, semente 7; o `bom` acerta 95 %, o `medio` 66 %, o
  `ruim` 30 %; quando não acerta, o segundo sorteio decide entre o tropeço e o lado errado):

| medida | 24 degraus (antes) | 60 degraus (agora) |
| --- | --- | --- |
| mesa padrão: a reta acontece (ninguém no topo antes da batida 209) | 0 % | 99,3 % |
| mesa padrão: alguém chega ao topo | 100 %, aos 47,8 s (p10 44,4 s) | 29,0 %, todas na reta, aos 97,8 s em média |
| mesa padrão: o degrau do P1 `bom` na batida 209 | (já no topo) | 51,1 em média, p99 59 |
| mesa padrão: o `medio` chega ao topo | 29 % | 0 % (fecha em 17,4 em média, p90 30) |
| os quatro `bom` (a prova do jogo sem o erro da mesa): a reta acontece | 0 % | 98,4 % |
| a mesa da prova (o `bom` com `ERRO_DA_MESA`): a reta acontece | 0 % | 99,3 % |
| P1 que nunca erra (o jogador perfeito): a reta acontece | 0 % | 94,6 % (chega ao topo em 64 %) |
| mesa padrão: tombos em 100 s; ao menos 1 entre 33 e 67 s | 16,1; 100 % | 36,7; 100 % |
| a curva (passos por segundo por lugar): 2.º terço ÷ 1.º; 3.º ÷ 1.º | 2,4 ×; 1,18 × | 2,4 ×; 1,18 × (a escada não muda o passo) |

A curva sai 2,4 × e 1,18 ×, como as contas de «O tempo»: a regra «nunca duas vezes seguidas sem passo» sobe a chance
do 1.º terço de 0,5 a 0,67 (sem ela, a conta dava 3,0 × e 1,5 ×). Os dois passam a régua (≥ 1,5 × e ≥ 1,0 ×).

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 (o primeiro passo cai até 4,9 s) | o quadro de 10 s mostra um cavaleiro num degrau acima do 0 |
| 4. o momento | pelo menos 3 linhas `momento` `despenca` entre 0 e 100 s, pelo menos 1 entre 33 e 67 s | em 2 quadros seguidos, um cavaleiro 4 degraus abaixo de onde estava |
| 5. a curva | passos por segundo no 2.º terço ≥ 1,5 × os do 1.º (dá 2,4 ×); no 3.º ≥ 1,0 × (dá 1,18 ×); a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a luz 20 % acima do quadro do meio do 1.º |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | o P4 é o mais baixo em metade dos quadros |
| 7. quem perde joga | a maior distância entre dois passos seguidos de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `despenca` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 (`x_tela` de 0,25 a 0,75; `altura_tela` de 0,085 a 0,123) | a queda se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `despenca`, uma linha `sensacao` `golpe` a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte mostra o buraco escuro |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem dos degraus no `momento` `reta` e no fim | no quadro de 94 s, quem olha diz a ordem pela altura nas escadas, e ela bate com o registro |

A prova do jogo faz a mesa padrão com a mesa da prova da N1 (`_mesa`, `ERRO_DA_MESA`: o robô `bom` e, por cima, o pé
do lado errado sorteado por lugar) e confere os itens 1, 4, 5, 8, 9 e 10. Os itens 6 e 7 esperam o robô por lugar
(`--robo=bom,medio,medio,ruim`), que a F09 não faz.

## Pronto quando

O Eco do Abismo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo
que cai e volta; fecha com vencedor (o primeiro no topo, ou o mais alto aos 100 s); o tombo acontece pelo menos 3 vezes
com a mesa padrão; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `SALA=S06_J27 bash tests/prova_do_jogo.sh` (a prova do Eco, sem e com `--bancada`), `bash tests/prova_do_jogo.sh`
e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a função abaixo, chamada pela linha `"S06_J27": await _prova_do_eco()` no
`match` do `_prova_da_ficha(slot)` da H08. A mesa da prova (`_mesa_comeca`, `_mesa`, `ERRO_DA_MESA`) é da N1. O erro
do Eco é o pé do lado errado, 50 ms antes do alvo: o robô pisa no alvo, mas o passo já caiu no tombo.

```gdscript
## Eco do Abismo (S06_J27): o eco sai do alto-falante simulado; o degrau fica
## entre 0 e o topo; o vencedor é o mais alto; o tombo é o momento e põe o
## R2 em Resistência.
func _prova_do_eco() -> void:
	var fora := [0]
	var tocou := [false]
	var resistencia := [false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if int(mg.degrau[l]) < 0 or int(mg.degrau[l]) > mg.DEGRAUS:
				fora[0] += 1
			if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.3:
				tocou[0] = true
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				resistencia[0] = true
		_mesa(mg, ERRO_DA_MESA, func(l: int, nn: int) -> void:
			var lado := int(mg._info[l].get(nn, {}).get("lado", 0))
			Forja.robo_eixo(l, Forja.LX, 1.0 if lado == mg.ESQ else -1.0, 0.1))
	_mesa_comeca()
	var mg = await _joga_o_minigame("S06_J27", 140.0, olhar)
	if mg == null:
		return
	_esperar(fora[0] == 0, "Eco: o degrau sempre entre 0 e o topo")
	_esperar(tocou[0], "Eco: o eco saiu de um alto-falante simulado")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and float(mg.subida[v[0]]) == v.map(func(l): return float(mg.subida[l])).max(), "Eco: vence o mais alto")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S06_J27")
	var ecos := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("evento") == "mandou")
	var resp := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("o") == "resposta")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	var tombos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "despenca")
	_esperar(ecos.size() >= 1 and resp.size() >= 1, "Eco: %d ecos e %d pisadas no registro" % [ecos.size(), resp.size()])
	for l in mg.presentes():
		_esperar(toques.any(func(e): return int(e.get("jogador", 0)) == l + 1 and float(e.get("t_musica", 99.0)) <= 10.0), "Eco: o P%d pisou até 10 s" % (l + 1))
	_esperar(tombos.size() >= 3, "Eco: %d tombos (o mínimo é 3)" % tombos.size())
	_esperar(resistencia[0], "Eco: o tombo põe o R2 em Resistência (0x21)")
	_esperar(tombos.any(func(e): return float(e.get("t_musica", 0.0)) >= 33.0 and float(e.get("t_musica", 0.0)) <= 67.0), "Eco: um tombo no pico")
	for a in tombos:
		_esperar(float(a.get("x_tela", 0.0)) >= 0.2 and float(a.get("x_tela", 0.0)) <= 0.8 \
			and float(a.get("altura_tela", 0.0)) >= 0.08, "Eco: o tombo no meio da tela (%s)" % [a])
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("slot", "") == "S06_J27").is_empty(), "Eco: fora da bancada, nenhuma pergunta")
```

### O que o registro mede

- `som_controle` (H07) de cada eco; a `troca` `alto_falante` → `tv` de quem não tem alto-falante.
- `pista` (`canal` `alto_falante`: n, som, `no_controle`), a `entrada` `resposta` (lado pedido, lado feito) e o `toque`
  do kit com o mesmo `n`: o eco no controle com o lado errado é o alto-falante que não cantou ou o jogador que chutou.
- `sensacao` `golpe` e `momento` `despenca` em cada tombo; o `momento` `reta`.

### As pranchas que o jogador do time olha

A prancha da prova visual (480 × 270, um quadro a cada 2 s): o quadro de 10 s (os quatro nos primeiros degraus, o
caminho aceso), os pares seguidos com um cavaleiro mais baixo (o tombo), o do meio do pico (a luz mais forte), o de
94 s (a ordem pela altura; o quadro é a cada 2 s, e com os quatro `bom` só 5 % das partidas chegam ao topo antes) e os da reta (as velas acesas no topo).

### O que o André joga e sente

`./run-local.sh -- --sala=S06_J27`, com quatro DualSense, dois no cabo e dois no rádio, e a luz da sala apagada:

- o eco grave e o agudo se distinguem na mão, no meio da música, e a música abaixa no eco;
- dá para subir olhando só para o próprio cavaleiro (a tela não ajuda);
- o tombo bate no tempo, o R2 endurece por um instante, e a sala ouve o próximo eco de quem caiu;
- a barra de luz fica a meia-luz e pulsa a cada degrau.

### Armadilhas

- **As duas pedras são iguais na tela:** nenhum brilho, cor ou tamanho diferente antes de pisada.
- **`_notas` é do kit.** O dado do passo mora em `_info`; o sentado tira o passo das duas.
- **O `_ultima[l]`** vai antes de `julgar_nota`/`nota_perdida`, e a `falha` o limpa: o tropeço por passo perdido não
  tem `feito`, e não derruba.
- **O tombo não passa de 0** e apaga as pedras acesas acima do degrau novo.
- **`primeiro_a_chegar`:** ao chegar, todos `acabou` no mesmo quadro.
- **O tombo no alto-falante** (`nota_alta`, `nota`) cai fora da janela do robô: no tempo sentado não há passo.
- **A música:** o `_exit_tree` chama `soltar_a_musica`.

### Ao terminar

- No [quadro](README.md): a linha **N2**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer): `feat: Eco do Abismo no kit, a escada no escuro que só o alto-falante mostra`
