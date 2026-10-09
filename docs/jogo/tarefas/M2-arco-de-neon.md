# M2 — Arco de Néon

**Sprint:** M · **Slot:** S05_J22 · **Tamanho:** M · **Depende de:** H04, H08, F09, M1

## Por quê

O arco é o gatilho que resiste. Puxar custa, segurar custa mais, e o peso conta a nota longa: 4 na puxada, 6 na
metade, 8 na última semicolcheia. Quem solta no fim acerta o alvo; quem solta cedo derruba a flecha aos pés. É o
verbo **sustentar e soltar**, o contrário da pistola da M1, em que o tempo é o do clique.

No pico, o arco vira Weapon: quem puxa até passar do clique do fundo solta uma flecha de fogo, que atravessa o
próprio alvo e queima o alvo do vizinho. É o instante em que a mesa inteira olha para o mesmo muro.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o kit, a ficha de dados, o catálogo, a régua)
- [A M1, A Galeria](M1-a-galeria.md) (o cenário comum `CenarioDaGaleria`, a câmera, a luz, o impacto, o coice e o
  `_joga_o_minigame` da prova)

Tudo o que esta ficha tira da bíblia de arte, do mapa do áudio, da régua da diversão e do RPG está escrito aqui ou
na M1, com o número. O cenário comum da M1 não muda nesta ficha: ela só o usa.

## Arquivos que mudam

- `godot/scripts/minigames/s05/arco_de_neon.gd` (novo, com o `.uid` que o Godot gera)
- `godot/scripts/minigames/catalogo.gd`: o slot `S05_J22` em `MINIGAMES` e na seção `S05`. **De todos:** as M1 a
  M5 mudam este arquivo
- `godot/scripts/traducoes.gd`: as frases novas. **De todos:** as M1 a M5 mudam este arquivo
- `godot/testes/prova_do_jogo.gd`: a prova do Arco. **De todos:** as M1 a M5 mudam este arquivo

## Como se joga

A faixa é `mus_s05_j22`, a 135 bpm (1 batida = 0,444 s). São 80 s, ou 180 batidas.

**O dono da batida.** As flechas são de um lugar por batida: `presentes()` em ordem, `lista[b % k]`. Com um
jogador, todas as batidas são dele. O compasso 0 é a contagem, e a primeira nota vem em `BATIDA_DA_PRIMEIRA_NOTA`
(4). O compasso `c` (batidas `4c` a `4c + 3`) é gerado quando `Ritmo.batida() >= 4c − 4`.

**A curva** (os terços pelo tempo de música da nota, `CenarioDaGaleria.andamento_em(self, t)`):

| parte | segundos (de 80) | chance de flecha na batida do dono | comprimento `L` da nota |
| --- | --- | --- | --- |
| entrada | 0 a 26,7 | 0,5 | 2 batidas |
| **pico** | 26,7 a 53,3 | 1,0 (densidade ×2 da entrada) | 2 batidas, com o fundo e o fogo |
| saída | 53,3 a 80 | 0,8 | 1 ou 2 batidas, metade de cada (o `rng` do kit) |
| **a reta** | as últimas 16 batidas (72,9 a 80 s) | 0,8 | 1 ou 2; a flecha que acerta vale o dobro |

- **O descanso.** Uma flecha nova só nasce se `b >= _livre_em[l]`. Na geração, `_livre_em[l] = b + L + DESCANSO_B`
  (2 batidas). Uma batida bloqueada não conta como vez vazia.
- **Ninguém para.** Se a vez anterior do dono foi sorteada sem flecha, esta tem (chance 1). Com 4 jogadores, a maior
  distância entre duas puxadas do mesmo lugar é de 8 batidas.
- **A nota cabe na faixa:** se `b + L` passa da última batida, a flecha não nasce.
- **A partitura simples.** Quem está com `Ritmo.simples[l]` fica sempre com `L = 2` e sem o fundo do pico.
- O sorteio usa o `rng` do kit (a semente da partida).

**As duas notas de cada flecha**, pela fila do kit:

- a **puxada**, na geração: `nova_nota(l, n, Ritmo.t_da_batida(b))`, com `n = int(round(b * 2))` (par). Os dados
  ficam em `_info[l][n] = {"b": b, "tipo": "puxa", "L": L}`;
- a **soltura**, só quando a puxada foi BOM ou melhor: `nova_nota(l, n2, Ritmo.t_da_batida(b + L))`, com
  `n2 = int(round((b + L) * 2)) + 1` (ímpar, nunca bate com uma puxada). Os dados ficam em
  `_info[l][n2] = {"b": b + L, "tipo": "solta", "de": b, "L": L, "fundo": <no pico e sem a partitura simples>}`.

**O alvo acende.** O alvo do lugar fica apagado (o aro com emissivo 0). Ele acende o aro a 2,0 em
`t_da_batida(b − A) − pista`, com `A = CenarioDaGaleria.aviso_b()` (2 batidas a 135 bpm, 0,89 s) e
`pista = CenarioDaGaleria.pista_s(l)` (o Faro e a Lanterna). O aro apaga quando a flecha chega ou cai.

**O ponteiro.** No alvo aceso, um ponteiro na cor do lugar fica parado às 12 h durante o aviso. Na batida da puxada
boa, ele dá uma volta inteira no sentido horário, de `t_da_batida(b)` a `t_da_batida(b + L)`, pelo relógio da
música (sem a pista). Quando ele volta às 12 h, é a hora de soltar.

**Puxar.** É o R2 subindo até `CenarioDaGaleria.R2_APERTA` (0,5). A puxada casa com `casar_toque(l)` (o alcance do
kit é 0,5 s):
- a nota casada é de `puxa`: guarde `_nota_em_curso[l] = n` e chame `julgar_nota(l, n)`. O kit chama `toque`
  (a corda estica e a soltura nasce) ou `falha` (a corda escapa);
- sem nota perto: é a puxada à toa. O arco se inclina com o dedo, sem flecha, sem ponto e sem erro.

**Segurar.** Enquanto a nota de soltura está em aberto, o arco endurece em três degraus pela fração da nota
`f = (Ritmo.batida() − de) / L`:

| degrau | quando | força (`b` do Feedback, `c` da Weapon) |
| --- | --- | --- |
| a puxada | `f` de 0 a 0,5 | `FORCA_PUXADA` 4 |
| a metade | `f` de 0,5 até a última semicolcheia | 6 |
| o fim | a última semicolcheia (`Ritmo.batida() >= de + L − 0,25`) | 8 |

Fora do pico, é `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, forca)`. No pico, com `fundo`, é
`Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 8, forca)`: a parede vai da posição 2 à 8, e passar da 8 (o clique,
0,89 do curso) é chegar ao `FUNDO` (0,9). Mande só quando o degrau muda (`_arco`).

**Soltar.** É o R2 caindo até `R2_SOLTA` (0,2), ou até `SEGURA` (0,35) enquanto a nota de soltura está em aberto.
Com a nota de soltura em aberto, guarde `_nota_em_curso[l] = n2` e chame `julgar_nota(l, n2)` direto, sem o
`casar_toque`: soltar cedo demais é ERRO pelo próprio julgamento. Depois de toda soltura, o arco volta a
`Feedback (2, FORCA_PARADO)` (2).

**Segurar além do fim.** A soltura que passa de `FOLGA_PERDIDA` (0,14 s) com o R2 ainda acima de 0,2 vira
`nota_perdida` pelo kit: é a falha do braço cansado. O R2 recebe `Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, 2, 3, 8)`
(posição 2, amplitude 3, 8 Hz) até o dedo cair abaixo de 0,2. Aí volta o `Feedback (2, 2)`.

**A flecha que acerta** voa em 1/4 de batida até o alvo do dono e crava nele. Os pontos e os alvos:

| flecha | pontos | alvos |
| --- | --- | --- |
| comum | `PONTOS[j_puxa] + PONTOS[j_solta]` | +1 |
| na reta | `(PONTOS[j_puxa] + PONTOS[j_solta]) × 2` | +2 |
| de fogo (pico) | a comum mais `FOGO` (50) | +1 |
| no alvo queimado (abaixo) | a metade da conta acima, arredondada para baixo | +1 (ou +2 na reta) |

Sempre por `marcar`, que passa pelo item do julgamento da soltura.

**A flecha de fogo.** No pico, a soltura boa de uma nota com `fundo` cujo `curso_max` passou de `FUNDO` (0,9) sai
em chamas:
- ela atravessa o próprio alvo em `b_solta + 0,25` (o acerto comum, com o `FOGO`) e segue para o alvo do vizinho,
  o próximo lugar de `presentes()` na roda (`lista[(i + 1) % k]`);
- ela pousa no alvo do vizinho **exatamente** em `Ritmo.t_da_batida(b_solta + 0,5)`, uma colcheia depois da batida
  da soltura. Guarde `{"de": l, "para": viz, "t": <esse tempo>}` em `_fogos`, e `jogar` pousa no primeiro quadro
  com `Ritmo.t_musica() >= t`;
- no quadro em que pousa:
  - `CenarioDaGaleria.momento(self, "flecha_de_fogo", l)`, com o lugar de quem atirou;
  - `Forja.sentir(l, lado_de_quem_atira)` e `Forja.sentir(viz, lado_do_vizinho)`. Se o vizinho está à direita
    (`RAIAS[viz] > RAIAS[l]`), quem atira sente `"golpe_dir"` e o vizinho `"golpe_esq"`; senão, o contrário;
  - `CenarioDaGaleria.impacto(self, "estrondo", <o alvo do vizinho>, viz)`: 50 faíscas, tremor de 2 batidas e o
    hit-stop de 50 ms no cavaleiro do vizinho;
  - o alvo do vizinho queima: `_queimado_ate[viz] = Ritmo.t_musica() + QUEIMA_S` (2 s).
- **Um alvo queimado não queima de novo** até apagar: a flecha de fogo que chega nele faz o momento, o golpe e o
  estrondo, mas não estende a queima.

**O pico.** No primeiro quadro com `no_pico()`, chame `CenarioDaGaleria.pico(self)` uma vez e acenda os dois
braseiros (A cena). No primeiro quadro fora do pico depois dele, os braseiros apagam.

**A reta.** No primeiro quadro com `CenarioDaGaleria.na_reta(self)`, chame
`CenarioDaGaleria.momento(self, "reta", -1)`. Daí até o fim, a flecha que acerta vale o dobro.

Toda puxada e toda soltura julgadas gravam
`anotar("entrada", l, {"o": "disparo", "n": n, "modo": <"resistencia" ou "arma">, "curso": r2, "curso_max": <o maior R2 desde a puxada>})`.
Na puxada, o `curso_max` é o próprio `curso`.

### A ficha de dados

O cabeçalho do script `godot/scripts/minigames/s05/arco_de_neon.gd` é um comentário `#` com estas linhas:
- **o jogo:** cada flecha é uma nota longa. Na batida do dono, puxe o R2; o arco resiste (Feedback) e endurece em
  4, 6 e 8 pela nota; solte quando o ponteiro do alvo volta às 12 h. No pico, o arco vira Weapon: passar do
  clique do fundo solta a flecha de fogo, que queima o alvo do vizinho por 2 s;
- **a falha:** a corda escapa (a puxada fora do tempo) ou a flecha cai aos pés (a soltura fora do tempo); o coice
  joga o cavaleiro 0,5 m para trás e a flecha fica cravada no chão 4 s. Segurar além do fim faz o arco tremer
  (Vibration) até soltar;
- **o vencedor:** mais alvos; no empate, mais pontos;
- **o alto-falante do dono:** o clique da puxada e a coleta da flecha no alvo;
- **o registro:** cada `saida` de gatilho (Feedback com a força, Weapon no pico, Vibration no braço cansado) e o
  curso do R2 na puxada e na soltura;
- **o robô:** puxa na batida, segura (até o fundo no pico) e solta no fim; quando não acerta, solta 250 ms tarde;
- **com menos de quatro:** as batidas se dividem, com 2 batidas de descanso depois de cada flecha;
- **a régua:** (1) «Puxe e solte!» com o arco na mão e o ponteiro no alvo; (2) não se joga sem tela; (3) não
  pergunta nada.

```gdscript
extends Minigame

const FICHA := {
	"slot": "S05_J22",
	"titulo": "Arco de Néon",
	"verbo": "Puxe e solte!",
	"genero": "tct",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J22",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "toque", "golpe_esq", "golpe_dir"],
	"material": "madeira",
	"microjogo": {"verbo": "Solte!", "segundos": 6.0},
	"gesto": "holding-right",
}
```

### As constantes

```gdscript
const PONTOS := [0, 20, 35, 50]  # ERRO, BOM, OTIMO, PERFEITO; a flecha soma a puxada e a soltura
const FOGO := 50  # a flecha de fogo
const FUNDO := 0.9  # o clique da Weapon (2, 8, c) no pico
const SEGURA := 0.35  # no meio da nota, abaixo disto a corda afrouxa e vale como soltura
const FORCA_PARADO := 2
const FORCA_PUXADA := 4
const FORCA_METADE := 6
const FORCA_FIM := 8
const DENSIDADE := [0.5, 1.0, 0.8]  # entrada, pico, saída
const COMPRIMENTO := [[2.0], [2.0], [1.0, 2.0]]  # em batidas, por parte
const DESCANSO_B := 2.0  # batidas livres depois do fim de cada nota
const QUEIMA_S := 2.0
const COICE_M := 0.5
const CRAVADA_S := 4.0  # a flecha caída no chão
const CRAVADAS_MAX := 6  # as flechas que ficam no alvo; a sétima tira a mais velha
const POS_DO_ALVO := Vector2(0.5, 0.45)  # no muro, pela mira de 0 a 1
```

### A falha

Toda falha muda a silhueta e deixa rastro (a régua: 0,5 m ou mais por pelo menos 1 batida, e rastro de 2 s ou
mais).

- **O coice:** `CenarioDaGaleria.coice(jogador(l), COICE_M)`, o da M1 (0,5 m para trás, 1 colcheia, 1 batida
  parado, 1 batida de volta). Peso não muda o coice.
- **A corda escapa** (puxada ERRO ou perdida):
  - o arco dá um estalo para a frente: `rotation.z` a +0,3 e de volta em 1/2 batida;
  - a flecha da corda cai aos pés: tween em 1/2 batida para o chão, 0,6 m à frente do cavaleiro, com
    `rotation.x` a −1,2. Ela fica cravada `CRAVADA_S` (4 s) e some em 0,5 s;
  - o aro do alvo apaga e o ponteiro volta às 12 h.
- **A flecha cai aos pés** (soltura ERRO): a flecha sai fraca, faz um arco de 0,4 m de altura e crava no chão a
  1,2 m à frente do cavaleiro, por 4 s. O aro apaga.
- **O braço cansado** (soltura perdida):
  - o mesmo coice, e a flecha fica na corda;
  - o arco treme em `rotation.z` ±0,05 rad a 8 Hz, junto com a Vibration (2, 3, 8) no dedo, até o R2 cair abaixo
    de 0,2;
  - ao soltar, a flecha cai aos pés como acima.
- **O gesto:** 1 batida depois do coice, `gesto("emote-no", 0.3)`.
- **A queda.** Depois da falha, o R2 fica sem efeito por `CenarioDaGaleria.queda_s(l, 1.0)` (1 batida × o Fôlego,
  à semicolcheia). O `DESCANSO_B` de 2 batidas garante que a próxima puxada vem depois da queda, mesmo com
  Fôlego 1 (1,25 batida).
- **A volta.** A próxima flecha do lugar é a próxima já gerada para ele.

### O fim e o vencedor

São 80 s de música, pelo kit (H08). O `vencedor()` é o da M1: por `alvos` e, no empate, por `pontos`.

### Com menos de quatro

- **Com três ou dois,** a roda do dono vale como está, com o descanso. Com dois, cada um puxa no máximo uma flecha a
  cada 4 batidas.
- **Com dois, a flecha de fogo** vai sempre para o outro.
- **Com um,** todas as batidas são dele, com o mesmo descanso. A flecha de fogo atravessa o alvo e crava no muro,
  1,5 m à direita dele, com a marca, o estrondo, o momento com o lugar dele e `"golpe_dir"` nele. Não queima alvo
  nenhum.
- **O controle que cai:** as notas dele saem caladas (`notas_perdidas` do kit). Se caiu no meio de uma nota longa,
  ela sai calada, e o arco dele volta a `Feedback (2, 2)` quando ele voltar.

### O robô

```gdscript
# O robô vê a nota da vez (a fila do kit e o _info). Na puxada, aperta o R2 na
# batida, pelo relógio da música: 1,0 na nota com fundo (passa do clique e
# solta o fogo) e 0,8 nas outras. Segura até a hora da soltura. Quando não
# acerta (Forja.robo_acerta() falso), solta 250 ms tarde: a soltura vira
# perdida, o braço cansa e a Vibration chega ao dedo.
var _robo_nota := [-1, -1, -1, -1]
var _robo_solta_em := [-1.0, -1.0, -1.0, -1.0]  # t_musica em que o robô solta
var _robo_forca := [0.8, 0.8, 0.8, 0.8]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var agora := Ritmo.t_musica()
	var abertas := notas_em_aberto(l)
	if not abertas.is_empty():
		var nn: int = abertas[0]
		var info: Dictionary = _info[l][nn]
		if nn != _robo_nota[l]:
			_robo_nota[l] = nn
			if info.tipo == "solta":
				var atraso := 0.0 if Forja.robo_acerta() else 0.25
				_robo_solta_em[l] = alvo_da(l, nn) + atraso
				_robo_forca[l] = 1.0 if bool(info.fundo) else 0.8
			elif agora >= float(_robo_solta_em[l]):
				_robo_solta_em[l] = -1.0
		if info.tipo == "puxa" and agora >= alvo_da(l, nn):
			_robo_solta_em[l] = INF
			_robo_forca[l] = 1.0 if no_pico() and not Ritmo.simples[l] else 0.8
	var r2 := float(_robo_forca[l]) if agora < float(_robo_solta_em[l]) else 0.0
	Forja.robo_eixo(l, Forja.R2, r2, 0.06)
```

- Antes da primeira puxada, `_robo_solta_em` é −1: o R2 fica em 0.
- Na batida da puxada, `_robo_solta_em` vai a `INF` até a nota de soltura entrar na fila. Ela entra no mesmo
  quadro do `toque`.
- O robô atrasado continua segurando depois que a soltura saiu da fila (perdida), até o `_robo_solta_em` dela:
  só uma puxada nova vista depois dessa hora zera o relógio dele.

### Os ganchos

```gdscript
var _info := [{}, {}, {}, {}]  # lugar -> n -> {b, tipo, L, de, fundo}
var _nota_em_curso := [-1, -1, -1, -1]
var _vez_vazia := [false, false, false, false]
var _livre_em := [0.0, 0.0, 0.0, 0.0]  # em batidas, reservado na geração
var _travado_ate := [0.0, 0.0, 0.0, 0.0]  # a queda da falha, em t_musica
var _gerado := 1
var _puxado := [false, false, false, false]
var _cansado := [false, false, false, false]  # a soltura passou com o R2 puxado
var _j_puxa := [0, 0, 0, 0]
var _gat := [[], [], [], []]  # o último [modo, a, b, c] mandado ao R2
var _disparo := [{}, {}, {}, {}]
var _queimado_ate := [0.0, 0.0, 0.0, 0.0]
var _fogos := []  # [{de, para, t}] as flechas de fogo no ar
var _pico_feito := false
var _pico_apagado := false
var _reta_feita := false
var alvos := [0, 0, 0, 0]
var n := {}  # lugar -> os nós da raia (alvo, aro, ponteiro, arco, flecha, cravadas)


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.2, -2.2)
	CenarioDaGaleria.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		n[l] = _montar_raia(l, p)  # a faixa, o arco na mão, o alvo, o ponteiro, a flecha (A cena)
		_arco(l, [Forja.GATILHO_RESISTENCIA, 2, FORCA_PARADO, 0])


func sair() -> void:
	for p in jogadores:
		CenarioDaGaleria.guardar_arma(p)
	CenarioDaGaleria.sair(self)
	super()


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	_o_mundo()  # o pico, os braseiros, a reta e as flechas de fogo que pousam
	for l in presentes():
		notas_perdidas(l)
		if not conectado(l):
			_puxado[l] = false
			continue
		var r2 := Forja.eixo(l, Forja.R2)
		if _cansado[l]:
			if r2 <= CenarioDaGaleria.R2_SOLTA:
				_cansado[l] = false
				_puxado[l] = false
				_flecha_cai(l)
				_arco(l, [Forja.GATILHO_RESISTENCIA, 2, FORCA_PARADO, 0])
			_mostrar(l, r2)
			continue
		if Ritmo.t_musica() < float(_travado_ate[l]):
			_mostrar(l, 0.0)
			continue
		if _puxado[l]:
			_disparo[l]["curso_max"] = maxf(float(_disparo[l].get("curso_max", 0.0)), r2)
		if not _puxado[l] and r2 >= CenarioDaGaleria.R2_APERTA:
			_puxado[l] = true
			_puxar(l, r2)
		elif _puxado[l] and (r2 <= CenarioDaGaleria.R2_SOLTA or (r2 <= SEGURA and _segurando(l) >= 0)):
			_puxado[l] = false
			_soltar(l, r2)
		_endurecer(l)
		_mostrar(l, r2)


func toque(l: int, julgamento: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	if str(info.get("tipo", "")) == "puxa":
		_j_puxa[l] = julgamento
		var fim := float(info.b) + float(info.L)
		var n2 := int(round(fim * 2.0)) + 1
		nova_nota(l, n2, Ritmo.t_da_batida(fim))
		_info[l][n2] = {"b": fim, "tipo": "solta", "de": float(info.b), "L": float(info.L),
			"fundo": no_pico() and not Ritmo.simples[l]}
		_endurecer(l)
		if julgamento != Ritmo.PERFEITO:
			Forja.som_falante(l, "clique", 0.5)
		return
	var vale := 2 if CenarioDaGaleria.na_reta(self) else 1
	var fogo := bool(info.get("fundo", false)) and float(_disparo[l].get("curso_max", 0.0)) >= FUNDO
	var conta := (PONTOS[_j_puxa[l]] + PONTOS[julgamento]) * vale + (FOGO if fogo else 0)
	if Ritmo.t_musica() < float(_queimado_ate[l]):
		conta = conta / 2
	marcar(l, conta)
	alvos[l] += vale
	_arco(l, [Forja.GATILHO_RESISTENCIA, 2, FORCA_PARADO, 0])
	_voar(l, info, fogo)  # a flecha, o alvo, a coleta; no fogo, entra em _fogos


func nota_perdida(l: int, nn: int) -> void:
	_nota_em_curso[l] = nn
	super(l, nn)


func falha(l: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	if str(info.get("tipo", "")) == "puxa":
		_corda_escapa(l)
		_arco(l, [Forja.GATILHO_RESISTENCIA, 2, FORCA_PARADO, 0])
	elif _puxado[l] and Forja.eixo(l, Forja.R2) > CenarioDaGaleria.R2_SOLTA:
		_cansado[l] = true
		_arco(l, [Forja.GATILHO_VIBRACAO, 2, 3, 8])
	else:
		_flecha_cai(l)
		_arco(l, [Forja.GATILHO_RESISTENCIA, 2, FORCA_PARADO, 0])
	CenarioDaGaleria.coice(jogador(l), COICE_M)
	_travado_ate[l] = Ritmo.t_musica() + CenarioDaGaleria.queda_s(l, 1.0)


# O arco: manda ao R2 só quando o [modo, a, b, c] muda.
func _arco(l: int, g: Array) -> void:
	if _gat[l] == g:
		return
	_gat[l] = g
	match int(g[0]):
		Forja.GATILHO_RESISTENCIA:
			Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, int(g[1]), int(g[2]))
		_:
			Forja.gatilho(l, 1, int(g[0]), int(g[1]), int(g[2]), int(g[3]))
```

- `_gerar_compasso(c)` aplica «A curva» e as regras do descanso e da vez vazia, e reserva `_livre_em`.
- `_segurando(l) -> int` devolve o `n` da nota de soltura em aberto do lugar, ou −1.
- `_puxar(l, r2)` casa com `casar_toque(l)` e só julga nota de `puxa`. Ele abre `_disparo[l]` e grava a `entrada`.
- `_soltar(l, r2)` põe o `curso` em `_disparo[l]`, julga `_segurando(l)` direto com `julgar_nota` (o `toque` lê o
  `curso_max`) e só depois grava a `entrada` e esvazia `_disparo[l]`. Sem nota de soltura, só devolve o arco a
  `Feedback (2, 2)`.
- `_endurecer(l)`: com `_segurando(l) >= 0`, calcula o degrau pela fração da nota e manda pelo `_arco`:
  `[GATILHO_ARMA, 2, 8, forca]` com `fundo`, ou `[GATILHO_RESISTENCIA, 2, forca, 0]` sem.
- `_voar(l, info, fogo)`: a flecha sai da corda e crava no alvo em 1/4 de batida (tween pela batida). Ao cravar:
  - o aro vai a 2,6 por 4 quadros e apaga;
  - `CenarioDaGaleria.impacto(self, "toque", <o alvo>, l)`;
  - `Som.tocar("alvo", <o alvo>)`, `Forja.som_falante(l, "coleta", 0.7)` e `Forja.sentir(l, "toque")`;
  - com `fogo`, guarda a flecha em `_fogos` e a deixa seguir até o vizinho (A cena).
- `_o_mundo()`: o pico, os braseiros, a reta, e o pouso de cada flecha de fogo cujo `t` chegou, na ordem do
  «A flecha de fogo».
- `_mostrar(l, r2)`: o arco se inclina com o R2 (`rotation.z` de 0 a −0,4), a flecha aparece na corda enquanto há
  nota de soltura, o aro e o ponteiro seguem a batida, e o alvo queimado fica GRAFITE.
- `status(l)`: `"%d alvos" % alvos[l]` quando `na_raia(l)`.
- `dica(l)`: `{"partes": ["@r2", "Puxe e solte"]}`, só com `na_raia(l)` e `not aprendeu(l)`.

### O catálogo e as traduções

- No `catalogo.gd`: `Catalogo.MINIGAMES["S05_J22"] = preload("res://scripts/minigames/s05/arco_de_neon.gd")`, e
  `"S05_J22"` na lista `"minigames"` da seção `S05`, depois do `S05_J21`.
- O `.uid` novo: `arco_de_neon.gd.uid`, gerado com `"$GODOT" --headless --path godot --import --quit`.
- As traduções que ainda não existirem: `"Arco de Néon": "Neon Bow"`, `"Puxe e solte!": "Draw and release!"`,
  `"Solte!": "Release!"`, `"Puxe e solte": "Draw and release"`. O `"%d alvos"` vem da M1.

### O registro

- **A `saida` de gatilho**, gravada pelo `Forja` (F06): `lado` `"R2"`, com `modo` `"resistencia"` e `params`
  `[2, f, 0]` (f em 2, 4, 6 e 8), `"arma"` com `[2, 8, f]` (f em 4, 6 e 8, só no pico) e `"vibracao"` com
  `[2, 3, 8]` (o braço cansado).
- **`entrada` `disparo`** na puxada e na soltura julgadas (`n`, `modo`, `curso`, `curso_max`), e o `toque` do kit.
- **A linha `momento`** por `CenarioDaGaleria.momento`: `flecha_de_fogo` (o lugar de quem atirou) e `reta`
  (lugar −1).
- **O cruzamento:** com o Feedback mandado e `ok`, as solturas no tempo dizem que o peso chegou. O mesmo lugar
  soltando cedo sempre, com o `curso_max` baixo, é o arco que não resistiu naquele controle.

### Armadilhas

- **A soltura só nasce com a puxada boa.** Senão uma puxada ERRO viraria duas notas erradas no registro.
- **Soltar cedo é o julgamento que diz.** Não trate a soltura antecipada à parte: o `julgar_nota` na nota de
  soltura já dá ERRO.
- **O `n` da soltura é ímpar.** Uma soltura em `b + L` nunca bate com a puxada de outra flecha na mesma batida.
- **A força só sobe, e só durante a nota.** Mande pelo `_arco`, que compara o último envio; senão a `saida`
  inunda o registro.
- **A flecha de fogo pousa pelo relógio da música**, em `b_solta + 0,5`, nunca por um tween que acaba. A prova
  confere o quadro.
- **O L2 é do item.** O arco é só o R2.
- **Não declare `_notas`.** A fila é do kit (H08). O que é do Arco fica em `_info`.

## A cena

### A câmera

A da M1, sem mudança: `"camera": "fixa"`, em `Vector3(0, 7.5, 11.0)` olhando para `Vector3(0, 0.2, -2.2)`, lente de
35 mm (FOV vertical 37,8°), plongée de 29°. O tremor vem de `CenarioDaGaleria.impacto`.

### A luz

A da M1, por `CenarioDaGaleria.montar(self)`: a névoa NEVOA `#18081c`, o preenchimento PREENCHIMENTO `#4a2854`
(energia 0,35), a chave CHAVE `#f8ccba` (energia 1,0) e o néon do mundo VIOLETA `#4a3aa8`.

- **O pico** (26,7 a 53,3 s): `CenarioDaGaleria.pico(self)` (a chave a ×1,2 e a névoa a ×0,8, de volta em 2
  batidas), e os dois braseiros acesos ao pé do muro. São a luz +20 % e a densidade ×2 da régua.
- **Nenhuma cor nova.** O Ciano, o Rosa e o Laranja do Tema que a ficha antiga usava saem.

### As peças

| peça | de onde | o papel | escala pedida |
| --- | --- | --- | --- |
| o arco | `mini-forest/weapon-bow`, por `peca_ou` dentro do nó da mão de `CenarioDaGaleria.arma_na_mao(p, NENHUMA)`; o substituto é `CenarioDaGaleria.arma(pai, ARCO)` | na mão direita | 1,0 (o boneco já está a `Kit.K`) |
| a flecha na corda | `mini-forest/weapon-arrow`, por `peca_ou` filha do arco; o substituto é `Kit.caixa` 0,6 × 0,04 × 0,04 m OXIDO_BRILHO `#7a5640` com a ponta `Kit.caixa` 0,08 m na cor do lugar | aparece enquanto há nota de soltura | 1,0 |
| a flecha no voo e cravada | a mesma peça, filha da sala | do arco ao alvo; cravada no alvo, até `CRAVADAS_MAX` (6) | 2,0 (`Kit.K`) |
| o alvo | `CenarioDaGaleria.alvo(self, false, l)`, sempre | um por lugar, Ø 0,92 m, em `CenarioDaGaleria.no_muro(l, POS_DO_ALVO)` + (0, 0, 0,12) | 1,0 |
| o ponteiro | `Kit.caixa` 0,04 × 0,40 × 0,02 m na cor do lugar, filho de um pivô no centro do alvo, em z +0,05 | o relógio da nota | — |
| os alvos de palha | `mini-forest/target`, por `peca_ou`; sem o pacote, nada | dois, de enfeite, em (±10, 0, −5,5), virados para o centro | 2,0 (`Kit.K`, 1,1 m de largura) |
| a flecha caída | a flecha no chão, `rotation.x` −1,2 | a falha, por 4 s | 2,0 |
| a marca de fogo | `Kit.cilindro` Ø 0,5 m, 0,01 m de espessura, OXIDO `#3b2a22`, fosco | no muro, 0,6 m do centro do alvo queimado, do lado de onde a flecha veio; fica até o fim | — |

- **Os pacotes.** A série Mini (Mini Forest) é 1× do pacote, na escala dos bonecos. Sem o pacote importado, o
  `peca_ou` põe o substituto.
- **O alvo queimado:** os três discos vão a GRAFITE `#3a3346` por `QUEIMA_S` (2 s), e voltam a ETIQUETA,
  VERMELHÃO e ETIQUETA num corte. Sobe fumaça: `Efeitos.poeira(self, <o alvo>, Vector3(0.6, 0.8, 0.2), GRAFITE, 20)`,
  apagada aos 2 s.
- **Os braseiros do pico:** `Efeitos.brasas(self, Vector3(x, 0.4, CenarioDaGaleria.Z_ALVOS + 0.8), Vector3(1.0, 0.6, 1.0), CenarioDaGaleria.TUNGSTENIO, 40)`,
  com x = −8 e 8. Saem no fim do pico.

### O que brilha, e de quem é o brilho

| o quê | cor | emissivo | dono |
| --- | --- | --- | --- |
| a borda da raia | a cor do lugar | a do kit | o jogador |
| o aro do alvo | a cor do lugar | 0 apagado; 2,0 do aviso até a flecha; 2,6 por 4 quadros quando ela crava | o jogador |
| o ponteiro | a cor do lugar | 2,0, só com o aro aceso | o jogador |
| a ponta da flecha na corda e no voo | a cor do lugar | 2,0; cravada, 0 | o jogador |
| a ponta da flecha de fogo e o rastro dela | TUNGSTENIO `#ffd9a8` | 2,4 | a forja |
| o rastro da flecha comum | a cor do lugar, alfa 0,9 | chapado, some em 0,12 s | o jogador |
| as faíscas e as brasas | TUNGSTENIO | chapadas | a forja |
| o néon do mundo | VIOLETA `#4a3aa8` | 3,0 hoje, 1,2 com a G15 | o mundo |

Nada mais brilha. Os discos, o grafite, a fumaça, a marca e as flechas cravadas são foscos.

### O impacto

Por `CenarioDaGaleria.impacto` (a tabela da M1):
- a flecha que crava no próprio alvo: `toque` (10 faíscas);
- a flecha de fogo no alvo do vizinho: `estrondo` (50 faíscas, tremor 0,417 por 2 batidas, hit-stop de 50 ms no
  cavaleiro do vizinho).

## O som

| evento | id do mapa | onde | como |
| --- | --- | --- | --- |
| a música | `mus_s05_j22` (135 bpm, Si menor, 150 s; seca, sem cauda de reverberação) | TV | `"faixa": "MUS_S05_J22"`; sem a faixa (H05), a trilha sintetizada `"galeria"` a 104 bpm |
| a puxada boa, menos o perfeito | `mod_clique` | alto-falante do dono | `Forja.som_falante(l, "clique", 0.5)`; no perfeito, o kit toca a nota |
| a puxada e a soltura julgadas | `jul_ressonancia_p{n}`, `jul_afinado_p{n}`, `jul_quase_p{n}`, `jul_erro_p{n}` | TV e alto-falante | o kit (`_reagir`); a ficha não toca nada |
| a flecha crava no alvo | `alvo_0` a `alvo_4` e `mod_coleta` | TV e alto-falante do dono | `Som.tocar("alvo", <o alvo>)` e `Forja.som_falante(l, "coleta", 0.7)` |
| a flecha de fogo pousa | `alvo_*` e `sint_fogo` | TV | `Som.tocar("alvo", <o alvo do vizinho>)` e `Som.tocar("fogo", <o alvo do vizinho>, -6.0)` |
| a falha | `fx_tropeco_*` | TV | o kit (H11); a ficha não toca nada |
| os carimbos | `car_em_chamas`, `car_acorde`, `car_virada`, `car_por_um_fio` | TV | o kit e o HUD |

- **O alto-falante toca um som por vez**, na prioridade do kit: vitória e derrota, o julgamento, a coleta e o
  clique.
- **O `tique`** que a ficha antiga tocava na flecha caída sai: a falha tem o `fx_tropeco` do kit.

## O controle

| recurso | evento | quem joga | os outros |
| --- | --- | --- | --- |
| **gatilho R2 (protagonista)** | fora da nota | `GATILHO_RESISTENCIA` (2, 2): o arco parado | nada |
| gatilho R2 | a nota longa, fora do pico | `GATILHO_RESISTENCIA` (2, f): f = 4 na puxada, 6 na metade, 8 na última semicolcheia | nada |
| gatilho R2 | a nota longa do pico, com fundo | `GATILHO_ARMA` (2, 8, f), com o mesmo f; o clique na posição 8 é o fundo | nada |
| gatilho R2 | a soltura passou com o dedo puxado | `GATILHO_VIBRACAO` (2, 3, 8): posição 2, amplitude 3, 8 Hz, até o R2 cair abaixo de 0,2 | nada |
| vibração | a puxada e a soltura julgadas | `acerto` (0,3/0,6, 80 ms), `perfeito` (0,5/0,8, 100 ms) ou `erro` (0,7/0,3, 160 ms), pelo kit | nada |
| vibração | a flecha crava no alvo | `Forja.sentir(l, "toque")` (0/0,45, 60 ms) | nada |
| vibração | a flecha de fogo pousa | `"golpe_dir"` ou `"golpe_esq"` (250 ms) em quem atirou, pelo lado do vizinho | o vizinho sente o lado contrário, no mesmo quadro |
| háptica | o toque julgado | a textura `"madeira"`, pelo kit | nada |
| barra de luz | sempre | a cor do lugar, 100 %; o kit pisca branco no perfeito e escurece no erro | a cor de cada um |
| luzinhas | sempre | o número do lugar | o número de cada um |
| alto-falante | O som | o clique da puxada e a coleta | nada |
| microfone | — | Não se aplica: o Arco não ouve | — |

**A prova sem o controle na mão:**
- o robô sente o modo pelo primeiro byte (`Forja.percepcao(l)["gatilho_dir"]`: `0x21` Feedback, `0x25` Weapon,
  `0x26` Vibration), e a prova junta os três;
- a força se confere pelos `params` da `saida` no registro: 2, 4, 6 e 8 no Feedback, `[2, 8, f]` na Weapon e
  `[2, 3, 8]` na Vibration.

## O cavaleiro

| stat | gancho | o que muda aqui |
| --- | --- | --- |
| Fôlego | `levantar` | o R2 sem efeito depois da falha: 1 batida × (1 − 0,125 × (Fôlego − 3)); Fôlego 1 dá 1,25 batida, e 5 dá 0,75 (`CenarioDaGaleria.queda_s(l, 1.0)`) |
| Faro | `pista` | o aro do alvo acende 20 ms × (Faro − 3) antes; Faro 5 dá +40 ms, e 1 dá −40 ms (`pista_s`). O ponteiro não muda: ele é o relógio da nota |
| Peso | — | não muda nada |
| Passo | — | não muda nada |

- **Os itens são do kit:** o Martelo (pelo `marcar`), o Escudo (o primeiro erro), o Fole, o Diapasão e a
  Lanterna (somada pela `pista_s`).
- **A peça.** O cavaleiro fica de costas (`rotation.y = PI`). O item da mão direita (Martelo, Âncora) some
  enquanto o arco está na mão e volta no `sair()` (`CenarioDaGaleria.guardar_arma`). O Escudo e os amuletos ficam à
  vista. As cores da montagem não mudam nesta ficha.

## As reações

- **Nenhum adesivo.** Todos jogam todas as vezes, e ninguém fica fora da rodada para mandar um.
- **Os carimbos são do kit e do HUD**, e esta ficha não chama nenhum: `car_em_chamas` (5 Ressonância! seguidas),
  `car_acorde`, `car_virada` e `car_por_um_fio`.
- **A flecha de fogo é a reação entre jogadores.** Quem queima o alvo do vizinho é visto por todos: o estrondo no
  muro dele, a fumaça e a marca que fica até o fim.

## A diversão

**O momento: `flecha_de_fogo`**
- **Quando:** a janela é de 26,7 a 54,0 s (o pico, mais a colcheia do pouso), na mesa padrão. Quem puxa até
  passar do clique do fundo e solta no fim vê a flecha atravessar o próprio alvo e cravar no alvo do vizinho, uma
  colcheia depois.
- **O que se vê:** a câmera treme 2 batidas, o cavaleiro do vizinho para 50 ms, o alvo dele fica GRAFITE e solta
  fumaça por 2 s, e a marca de fogo fica no muro dele até o fim. No último quadro, os muros contam a história do
  pico.

**Como o jogador do time confere:**
- **No registro,** pelo robô na mesa padrão, semente 7:
  - pelo menos **3 linhas `momento` `flecha_de_fogo`**, com `t_musica` entre 26,7 e 54,0 s;
  - para cada uma, uma linha `sensacao` `golpe_dir` ou `golpe_esq` do mesmo lugar a até 16,7 ms;
  - o `t_musica` de cada uma cai a até 1 quadro (16,7 ms) de uma colcheia.
- **Na prancha (F09):**
  - há fumaça num alvo em pelo menos 1 de cada 4 quadros do pico;
  - no último quadro, há marca de fogo em 2 ou mais muros.
- **A falha à vista:** o P4 (`ruim`) tem pelo menos 10 linhas `toque` com `erro` em 80 s. Em pelo menos 1 quadro
  de cada 5 da prancha, há uma flecha cravada no chão aos pés de alguém.
- **Ninguém para:** a maior distância entre duas puxadas seguidas do mesmo lugar é de até 8 batidas. O P4 tem pelo
  menos um toque BOM ou melhor em cada terço.

## Pronto quando

O Arco de Néon joga do aviso ao resultado:
- com 4, 3, 2 e 1 jogador, e com o robô nos três temperamentos;
- aguenta o cabo que cai no meio de uma nota longa;
- fecha com vencedor;
- abre o `S05_J22` com `--sala=S05_J22`;
- dá as flechas de fogo do pico e grava as linhas `momento`.

A prova do jogo passa, e a prova visual passa com a prancha olhada.

### Ao terminar

- No [quadro](README.md), quem coordena marca a linha **M2** com o commit.
- Commit sugerido (sem trailer): `feat: Arco de Néon, a nota longa no peso do gatilho e a flecha de fogo do pico`.

## Provas

Os comandos: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, depois da prova da Galeria, acrescente a função abaixo. O
`_joga_o_minigame(slot, limite_s, a_cada_quadro)` é da H08.

```gdscript
# O Arco de Néon (S05_J22): o dedo sentiu o Feedback, a Weapon do pico e a
# Vibration do braço cansado; o arco endureceu em 4, 6 e 8; as puxadas têm o
# curso; o pico dá as flechas de fogo, com o golpe no mesmo quadro.
func _prova_do_arco() -> void:
	var modos := {}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			modos[int(Forja.percepcao(l).get("gatilho_dir", 0))] = true
	var mg = await _joga_o_minigame("S05_J22", 120.0, olhar)
	if mg == null:
		return
	_esperar(modos.has(0x21) and modos.has(0x25) and modos.has(0x26),
		"Arco: o dedo sentiu Feedback, Weapon e Vibration (bytes vistos: %s)" % [modos.keys()])
	var linhas := _linha_do_tempo()
	var gat := linhas.filter(func(e): return e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("lado") == "R2")
	var forcas := {}
	var weapon := [false]
	var vibra := [false]
	for e in gat:
		var p: Array = e.get("params", [0, 0, 0])
		if e.get("modo") == "resistencia":
			forcas[int(p[1])] = true
		elif e.get("modo") == "arma" and int(p[0]) == 2 and int(p[1]) == 8:
			weapon[0] = true
		elif e.get("modo") == "vibracao" and int(p[0]) == 2 and int(p[1]) == 3 and int(p[2]) == 8:
			vibra[0] = true
	_esperar(forcas.has(2) and forcas.has(4) and forcas.has(6) and forcas.has(8),
		"Arco: o Feedback foi a 2, 4, 6 e 8 (%s)" % [forcas.keys()])
	_esperar(weapon[0], "Arco: no pico, a Weapon (2, 8, f)")
	_esperar(vibra[0], "Arco: o braço cansado recebeu a Vibration (2, 3, 8)")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.alvos[v[0]]) == v.map(func(l): return int(mg.alvos[l])).max(),
		"Arco: vence quem cravou mais alvos")
	var disparos := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("slot") == "S05_J22" and e.get("o") == "disparo")
	_esperar(disparos.size() >= 2 and disparos.any(func(e): return float(e.get("curso_max", 0.0)) >= 0.9),
		"Arco: %d puxadas e solturas, e alguma passou do fundo" % disparos.size())
	var fogos := linhas.filter(func(e): return e.get("slot") == "S05_J22" and e.get("nome") == "flecha_de_fogo"
		and (e.get("tipo") == "momento" or e.get("o") == "momento"))
	var no_pico := fogos.filter(func(e): return float(e.get("t_musica", 0.0)) >= 26.7 and float(e.get("t_musica", 0.0)) <= 54.0)
	_esperar(no_pico.size() >= 3, "Arco: %d flechas de fogo no pico" % no_pico.size())
	var com_golpe := fogos.filter(func(o): return linhas.any(func(e): return e.get("tipo") == "sensacao"
		and str(e.get("nome", "")) in ["golpe_dir", "golpe_esq"] and int(e.get("lugar", -1)) == int(o.get("lugar", -2))
		and absf(float(e.get("t", 0.0)) - float(o.get("t", 0.0))) <= 0.0167))
	_esperar(com_golpe.size() == fogos.size(), "Arco: o golpe sai no quadro de cada flecha de fogo (%d de %d)" % [com_golpe.size(), fogos.size()])
	var reta := linhas.filter(func(e): return e.get("slot") == "S05_J22" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "Arco: uma linha momento reta")
```

E chame `_prova_do_arco()` junto das outras provas de minigame.

**Na prova visual** (`bash tests/prova_visual.sh`, F09), o Arco entra pela semente que o `Catalogo.sortear` da H08
põe na noite (`--semente=N`). O jogador do time olha a prancha:
- um quadro do pico, com os braseiros acesos e a fumaça num alvo;
- um quadro com a flecha cravada no chão e o cavaleiro recuado;
- o último quadro, com as marcas de fogo nos muros e as flechas cravadas nos alvos.

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J22`):
- o arco endurece em três degraus, e o 8 no dedo diz «solte agora» junto com o ponteiro às 12 h;
- soltar cedo derruba a flecha aos pés, e segurar demais faz o arco tremer na mão;
- no pico, o clique do fundo e a flecha de fogo no alvo do vizinho, com o tremor;
- na saída, notas de 1 e de 2 batidas misturadas pedem o ponteiro e o peso juntos.
