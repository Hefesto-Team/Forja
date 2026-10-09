# M3 — Metralhadora de Feitiços

**Sprint:** M · **Slot:** S05_J23 · **Tamanho:** M · **Depende de:** H04, H08, F09, M1

## Por quê

O coop da seção. Uma frota pirata no céu, e os quatro dividem a rajada: cada um segura o R2 **só na sua batida**,
e a metralhadora treme no dedo em semicolcheias (Vibration) enquanto ele segura. Começar e soltar no tempo derruba
madeira da frota; atirar fora da vez superaquece a arma, e o R2 fica duro como pedra. O verbo é **segurar só a sua
parte**: a frase do ataque só fica inteira se cada um toca a dele.

No pico, a nau capitânia sobe do fundo, três vezes maior, com o canhão. Os quatro juntos a derrubam: ela quebra,
as velas pegam fogo e ela cai atrás do muro. É o único momento grande do jogo, e cai no tempo da faixa.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o kit, a ficha de dados, o catálogo, a régua, o coop)
- [A M1, A Galeria](M1-a-galeria.md) (o cenário comum `CenarioDaGaleria`, a luz, o impacto, o coice e o
  `_joga_o_minigame` da prova)

Tudo o que esta ficha tira da bíblia de arte, do mapa do áudio, da régua da diversão e do RPG está escrito aqui ou
na M1, com o número. O cenário comum da M1 não muda nesta ficha: ela só o usa.

## Arquivos que mudam

- `godot/scripts/minigames/s05/metralhadora_de_feiticos.gd` (novo, com o `.uid` que o Godot gera)
- `godot/scripts/minigames/catalogo.gd`: o slot `S05_J23` em `MINIGAMES` e na seção `S05`. **De todos:** as M1 a
  M5 mudam este arquivo
- `godot/scripts/traducoes.gd`: as frases novas. **De todos:** as M1 a M5 mudam este arquivo
- `godot/testes/prova_do_jogo.gd`: a prova da Metralhadora. **De todos:** as M1 a M5 mudam este arquivo

## Como se joga

A faixa é `mus_s05_j23`, a 155 bpm (1 batida = 0,387 s). São 90 s, ou 232 batidas. Sem a faixa, a trilha
`"galeria"` toca a 104 bpm, e tudo abaixo está em batidas.

**O dono da batida.** As rajadas são de um lugar por batida: `presentes()` em ordem, `lista[b % k]`. A primeira
nota vem em `BATIDA_DA_PRIMEIRA_NOTA` (4). O compasso `c` (batidas `4c` a `4c + 3`) é gerado quando
`Ritmo.batida() >= 4c − 4`.

**A curva** (os terços pelo tempo de música da nota, `CenarioDaGaleria.andamento_em(self, t)`):

| parte | segundos (de 90) | chance de rajada na batida do dono | o alvo |
| --- | --- | --- | --- |
| entrada | 0 a 30 | 0,5 | o navio da raia do dono |
| **pico** | 30 a 60 | 1,0 (densidade ×2 da entrada); com 3 ou mais, a rajada longa | a nau capitânia, enquanto ela está no céu |
| saída | 60 a 90 | 0,75; a frota desce 1 m | o navio da raia do dono |
| **a reta** | as últimas 16 batidas (83,8 a 90 s a 155 bpm) | 0,75; o dano vale 2 e a trava dura o dobro | o navio da raia do dono |

- **Ninguém para.** Se a vez anterior do dono foi sorteada sem rajada, esta tem (chance 1). Com 4 jogadores, a
  maior distância entre duas rajadas do mesmo lugar é de 8 batidas.
- **Com um jogador**, só as batidas pares são dele: entre duas rajadas há uma batida de descanso.
- **A batida do canhão não tem dono** (abaixo).
- O sorteio usa o `rng` do kit (a semente da partida).

**A rajada** do dono na batida `b` é um par de notas, as duas com `nova_nota` na geração:

- o **começo**: `n = int(round(b * 2))`, em `Ritmo.t_da_batida(b)`, com
  `_info[l][n] = {"b": b, "tipo": "aperta", "L": L}`;
- o **fim**: `n2 = int(round((b + L) * 2)) + 1`, em `Ritmo.t_da_batida(b + L)`, com
  `_info[l][n2] = {"b": b + L, "tipo": "solta", "de": b}`.

`L` é 1. No pico, com 3 ou mais presentes, a rajada na primeira batida de todo compasso `c` com
`c % LONGA_A_CADA == 1` (a cada 4 compassos) tem `L = 2`. Ela invade a batida do próximo dono, que segura a dele
ao mesmo tempo: dois dedos tremendo juntos. Quem está com `Ritmo.simples[l]` fica sem rajada longa.

**O aviso.** A raia do dono acende (`acender_raia(l, 1.0)`) em `t_da_batida(b − A) − pista` e apaga no fim da
rajada (`acender_raia(l, 0.15)`). `A = CenarioDaGaleria.aviso_b()`: 2 batidas a 155 bpm (0,77 s), 1 batida a 104.
`pista = CenarioDaGaleria.pista_s(l)` (o Faro e a Lanterna). O alvo da rajada acende a lanterna da proa na cor do
dono no mesmo instante.

**O gatilho de todos.** Do `iniciar_jogo` ao fim, o R2 é a metralhadora:
`Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, POSICAO, AMPLITUDE, _hz())`, com `POSICAO` 1, `AMPLITUDE` 6 e
`_hz() = clampi(int(round(Ritmo.bpm / 60.0 * 4.0)), 1, 255)`: as semicolcheias da faixa (10 Hz a 155 bpm, 7 Hz a
104). O tremor só existe com o dedo além da posição 1, então a arma treme quando ele aperta. **É um envio só:** a
Vibration volta a ser mandada apenas depois da trava e do canhão. O reenvio a cada batida, para casar a fase do
tremor com a música, espera a medida da fase na bancada.

**Apertar.** É o R2 subindo até `CenarioDaGaleria.R2_APERTA` (0,5). O aperto casa com `casar_toque(l)`:
- a nota casada é um `aperta`: guarde `_nota_em_curso[l] = n` e chame `julgar_nota(l, n)`;
- sem `aperta` perto (−1, ou a nota casada é outra): é o **tiro fora da vez**, e a arma superaquece.

**Soltar.** É o R2 caindo até `R2_SOLTA` (0,2). Com a nota `solta` da rajada em aberto, guarde
`_nota_em_curso[l] = n2` e chame `julgar_nota(l, n2)` direto: soltar cedo demais é ERRO pelo julgamento.

**Segurar além do fim.** O `solta` que passa de `FOLGA_PERDIDA` (0,14 s) com o R2 acima de 0,2 é a `nota_perdida`
do kit (a falha) **e** o superaquecimento.

**O superaquecimento** (`_superaquecer(l)`):
- a trava dura `CenarioDaGaleria.queda_s(l, TRAVA_TEMPOS)`: 4 batidas × o Fôlego, à semicolcheia. Na reta, 8
  batidas × o Fôlego;
- o R2 vai a `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, 8)` e, no último tempo da trava, a
  `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, 4)`: a arma esfria. Quando a trava acaba, a Vibration volta;
- as notas do lugar com `b` dentro da trava ficam caladas: `_info[l][n].calada = true`. O `nota_perdida` do
  minigame sai sem chamar o `super` para elas: sem erro e sem falha. A trava já é a falha;
- `Forja.sentir(l, "erro")` e `anotar("jogo", l, {"o": "superaqueceu", "b": Ritmo.batida(), "batidas": <a trava>})`.

**O dano.** Cada nota julgada tira `DANO[j]` do alvo da rajada: da nau, se ela está no céu, ou da frota. Na reta,
`DANO[j] × 2`. Os pontos vão para quem atirou: `marcar(l, DANO[j] * PONTOS_POR_DANO)` (sempre por `marcar`, que
passa pelo item).

| nota | dano | pontos |
| --- | --- | --- |
| começo ou fim, ERRO | 0 | 0 |
| BOM, ÓTIMO, PERFEITO | 1, 2, 3 | 10, 20, 30 |
| o mesmo na reta | 2, 4, 6 | 20, 40, 60 |

**A rajada inteira boa** (começo e fim ÓTIMO ou melhor) arranca um caixote do alvo: ele cai atrás do muro (A cena),
e o dono ouve a coleta.

**As vidas.** São contas pela faixa, para que a mesa boa vença e a mesa fraca quase:
- `vida_da_nau = int(round(NAU_POR_BATIDA * 30.0 * Ritmo.bpm / 60.0 * fator))`: 4,2 por batida do pico (325 a
  155 bpm, 218 a 104);
- `vida_da_frota = int(round(FROTA_POR_BATIDA * 90.0 * Ritmo.bpm / 60.0 * fator))`: 2,4 por batida da faixa (558 a
  155 bpm, 374 a 104);
- `fator` é 1,0 com 2 ou mais presentes (uma rajada por batida) e 0,5 com um (uma a cada duas batidas).

As duas contas saem no `iniciar_jogo`. Com a mesa boa (os quatro `bom`, perto de 5,6 de dano por batida), a nau cai
perto dos 52 s e a frota perto dos 83 s. Com a mesa fraca (os quatro `medio`, perto de 3,7), a nau perde perto de
80 % e a frota perto de 63 %: a quase vitória.

**A nau capitânia** (o pico):
- aos 30 s, no primeiro quadro com `no_pico()`, ela sobe do fundo em 2 batidas, e a frota pequena recua para trás
  dela. Chame `CenarioDaGaleria.pico(self)` uma vez;
- **o canhão.** Enquanto ela está no céu, na batida `4c` de todo compasso com `c % CANHAO_A_CADA == 0` (a cada 4
  compassos), o canhão dela atira. Essa batida não tem dono. Uma batida antes, a boca do canhão acende TUNGSTENIO
  2,4. Na batida:
  - todo lugar presente que não está na trava recebe `Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 3, 6, 8)` por 1
    batida, e depois a Vibration de novo;
  - `Forja.sentir(l, "golpe")` em todos;
  - a bala cai no chão entre as raias, em (0, 0, −1,5): `CenarioDaGaleria.impacto(self, "golpe", <ali>, -1)`, e o
    buraco fica 4 s. É só o susto: sem dano;
- **a nau cai** quando `vida_da_nau` chega a 0:
  - `CenarioDaGaleria.momento(self, "nau_cai", l)`, com o lugar da rajada que deu o último dano;
  - `CenarioDaGaleria.impacto(self, "catastrofe", <a nau>, -1)` (60 faíscas, tremor de 4 batidas e a chave a
    ×1,4) e `Forja.sentir(l, "explosao")` em todos, no mesmo quadro;
  - ela quebra, o mastro gira e ela cai atrás do muro em 4 batidas (A cena). A fumaça dela sobe do fundo até o fim;
  - o dano que sobra da rajada vai para a frota, e a frota volta para a frente.
- **a nau foge** se aos 60 s ainda voa: ela sobe e some em 4 batidas, e a frota volta para a frente. A vida que ela
  tinha não passa para a frota.

**A frota cai** quando `vida_da_frota` chega a 0: os quatro navios viram destroços e caem em 2 batidas,
`Forja.sentir(l, "explosao")` em todos, `coop_venceu = true` e `acabou[l] = true` para todos. Aos 90 s com a frota
no céu, o kit fecha com `coop_venceu = false`: a frota sobe e foge.

**A reta.** No primeiro quadro com `CenarioDaGaleria.na_reta(self)`, chame
`CenarioDaGaleria.momento(self, "reta", -1)`. O que pesa contra a turma dobra (a trava), e o dano também.

Todo começo e todo fim julgados gravam
`anotar("entrada", l, {"o": "disparo", "n": n, "modo": "vibracao", "curso": r2, "curso_max": <o maior R2 da rajada>})`.

### A ficha de dados

O cabeçalho do script `godot/scripts/minigames/s05/metralhadora_de_feiticos.gd` é um comentário `#` com estas
linhas:
- **o jogo:** a frota pirata no céu, os quatro no chão. Cada batida tem um dono; na batida dele, aperte o R2 e
  segure até a batida seguinte, e a metralhadora treme no dedo (Vibration) em semicolcheias. Começo e fim no tempo
  tiram madeira da frota. No pico, a nau capitânia e o canhão;
- **a falha:** a rajada torta (começo ou fim fora do tempo) passa por cima do navio e queima o muro, e o coice joga
  o cavaleiro 0,5 m para trás; atirar fora da vez superaquece a arma: fumaça e o R2 duro por 4 batidas;
- **o vencedor:** coop. A frota cai (todos vencem) ou foge aos 90 s; o destaque é quem deu mais dano;
- **o alto-falante do dono:** cada tiro da rajada, a coleta da rajada inteira boa e o tropeço do superaquecimento;
- **o registro:** cada `saida` de gatilho (Vibration, a trava em Feedback, a Weapon do canhão) e o curso do R2 no
  começo e no fim da rajada; o `superaqueceu`;
- **o robô:** segura o R2 da batida dele até a seguinte; quando não acerta, solta 250 ms tarde e superaquece;
- **com menos de quatro:** as batidas se dividem; com um, só as pares, e as vidas pela metade;
- **a régua:** (1) «Segure a rajada!» com a arma e a frota; (2) não se joga sem tela; (3) não pergunta nada.

```gdscript
extends Minigame

const FICHA := {
	"slot": "S05_J23",
	"titulo": "Metralhadora de Feitiços",
	"verbo": "Segure a rajada!",
	"genero": "coop",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J23",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Segure!", "segundos": 6.0},
	"gesto": "holding-right-shoot",
}
```

### As constantes

```gdscript
const DANO := [0, 1, 2, 3]  # ERRO, BOM, OTIMO, PERFEITO, no começo e no fim
const PONTOS_POR_DANO := 10
const POSICAO := 1
const AMPLITUDE := 6
const DENSIDADE := [0.5, 1.0, 0.75]  # entrada, pico, saída
const LONGA_A_CADA := 4  # compassos, no pico, com 3 ou mais
const CANHAO_A_CADA := 4  # compassos, enquanto a nau está no céu
const TRAVA_TEMPOS := 4.0  # a trava do superaquecimento, × o Fôlego; na reta, × 2
const TRAVA := [0, 8]  # Feedback: posição 0, força 8
const ESFRIA := [0, 4]  # o último tempo da trava
const CANHAO := [3, 6, 8]  # Weapon: começo 3, fim 6, força 8, por 1 batida
const NAU_POR_BATIDA := 4.2
const FROTA_POR_BATIDA := 2.4
const COICE_M := 0.5
const QUEIMA_S := 4.0  # a mancha da rajada torta no muro
```

### A falha

Toda falha muda a silhueta e deixa rastro (a régua: 0,5 m ou mais por pelo menos 1 batida, e rastro de 2 s ou
mais).

- **A rajada torta** (começo ou fim ERRO, ou o fim perdido):
  - os feitiços daquela rajada sobem 1,2 m acima do alvo e batem no muro do fundo;
  - fica no muro uma mancha OXIDO `#3b2a22`, Ø 0,4 m, fosca, por `QUEIMA_S` (4 s), que some em 0,5 s;
  - o navio balança: `rotation.z` ±0,2 rad em 1 batida, e a lanterna da proa pisca 2 vezes;
  - `CenarioDaGaleria.coice(jogador(l), COICE_M)`, o da M1;
  - 1 batida depois, `gesto("emote-no", 0.3)`.
- **O superaquecimento:**
  - a arma solta fumaça: `Efeitos.poeira(self, <a boca da arma>, Vector3(0.3, 0.6, 0.3), CenarioDaGaleria.GRAFITE, 20)`,
    pela trava inteira e no mínimo 2 s;
  - o cano fica VERMELHÃO `#c8432f` fosco pela trava (a cor da tinta, sem emissivo);
  - o coice, e `gesto("emote-no", 0.5)` no mesmo quadro;
  - o R2 duro (Feedback 0, 8) e o esfriar (0, 4) no último tempo.
- **A volta.** Depois da trava, a Vibration volta e a próxima rajada dele é a próxima não calada.

### O fim e o vencedor

`fim` `meta_coletiva`. A frota que cai fecha com `coop_venceu = true` e todos `acabou`. Aos 90 s de música, com a
frota no céu, o kit fecha com `coop_venceu = false`. O registro grava `vencedor` −1 (coop), e o destaque é quem deu
mais dano:

```gdscript
# Coop: o kit grava vencedor -1 (H08); o destaque é o artilheiro com mais dano.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

### Com menos de quatro

- **Com três,** a roda do dono e as rajadas longas valem.
- **Com dois,** as batidas se alternam, sem rajada longa.
- **Com um,** só as batidas pares, sem rajada longa, e as duas vidas pela metade (`fator` 0,5).
- **O controle que cai:** as notas dele saem caladas (`notas_perdidas` do kit). Se caiu no meio de uma rajada, ela
  sai sem superaquecer. As vidas não mudam: quem ficou derruba o resto.

### O robô

```gdscript
# O robô aperta o R2 na batida da rajada e segura até a batida seguinte, pelo
# relógio da música. Quando não acerta (Forja.robo_acerta() falso), solta 250
# ms tarde: a nota de fim se perde e a arma superaquece. Com a arma travada
# (Feedback, 0x21) ou com o canhão na mão (Weapon, 0x25), não aperta.
var _robo_nota := [-1, -1, -1, -1]
var _robo_solta_em := [-1.0, -1.0, -1.0, -1.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var modo := int(Forja.percepcao(l).get("gatilho_dir", 0))
	var agora := Ritmo.t_musica()
	var abertas := notas_em_aberto(l).filter(func(nn): return not bool(_info[l][nn].get("calada", false)))
	if not abertas.is_empty():
		var nn: int = abertas[0]
		var info: Dictionary = _info[l][nn]
		if nn != _robo_nota[l]:
			_robo_nota[l] = nn
			if info.tipo == "solta":
				_robo_solta_em[l] = alvo_da(l, nn) + (0.0 if Forja.robo_acerta() else 0.25)
		if info.tipo == "aperta" and agora >= alvo_da(l, nn) and modo == 0x26:
			_robo_solta_em[l] = INF
	var r2 := 1.0 if agora < float(_robo_solta_em[l]) and modo != 0x21 else 0.0
	Forja.robo_eixo(l, Forja.R2, r2, 0.06)
```

O robô só começa a rajada com a Vibration no dedo (`0x26`). Na trava, ele solta, e o `_robo_solta_em` já passou
quando a trava acaba.

### Os ganchos

```gdscript
var _info := [{}, {}, {}, {}]  # lugar -> n -> {b, tipo, L, de, calada}
var _nota_em_curso := [-1, -1, -1, -1]
var _vez_vazia := [false, false, false, false]
var _gerado := 1
var _atirando := [false, false, false, false]
var _rajada := [-1, -1, -1, -1]  # o n do fim da rajada em curso
var _j_aperta := [0, 0, 0, 0]
var _disparo := [{}, {}, {}, {}]
var _travada_ate := [-1.0, -1.0, -1.0, -1.0]  # em batidas
var _canhao_ate := -1.0  # em batidas
var _gat := [[], [], [], []]  # o último [modo, a, b, c] mandado ao R2
var vida_da_nau := 0
var vida_da_frota := 0
var _nau := 0  # 0 ainda não subiu, 1 no céu, 2 caiu, 3 fugiu
var _ultimo_dano := -1  # o lugar da rajada que tirou vida por último
var _reta_feita := false
var n := {}  # os nós: "frota" (4 navios), "nau", "canhao", lugar -> {arma, mancha}


func montar() -> void:
	camera_pos = Vector3(0, 6.8, 11.5)
	camera_olhar = Vector3(0, 2.2, -3.0)
	CenarioDaGaleria.montar(self)
	_montar_a_frota()  # A cena
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		CenarioDaGaleria.faixa(self, l)
		n[l] = {"arma": CenarioDaGaleria.arma_na_mao(p, CenarioDaGaleria.METRALHADORA)}


func sair() -> void:
	for p in jogadores:
		CenarioDaGaleria.guardar_arma(p)
	CenarioDaGaleria.sair(self)
	super()


func iniciar_jogo() -> void:
	var fator := 1.0 if presentes().size() >= 2 else 0.5
	vida_da_nau = int(round(NAU_POR_BATIDA * 30.0 * Ritmo.bpm / 60.0 * fator))
	vida_da_frota = int(round(FROTA_POR_BATIDA * 90.0 * Ritmo.bpm / 60.0 * fator))
	coop_venceu = false
	for l in presentes():
		_armar(l)


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # a curva, a batida do canhão sem dono, as notas caladas na trava
		_gerado += 1
	_o_ceu()  # a nau sobe, o canhão, a nau cai ou foge, a frota desce aos 60 s, a reta
	for l in presentes():
		notas_perdidas(l)
		if not conectado(l):
			_atirando[l] = false
			continue
		_a_trava(l)  # o esfriar no último tempo e a volta da Vibration
		var r2 := Forja.eixo(l, Forja.R2)
		if _atirando[l]:
			_disparo[l]["curso_max"] = maxf(float(_disparo[l].get("curso_max", 0.0)), r2)
		if not _atirando[l] and r2 >= CenarioDaGaleria.R2_APERTA:
			_atirando[l] = true
			_apertou(l, r2)  # julga o começo, ou superaquece
		elif _atirando[l] and r2 <= CenarioDaGaleria.R2_SOLTA:
			_atirando[l] = false
			_soltou(l, r2)  # julga o fim
		_feiticos(l)  # um feitiço por semicolcheia enquanto atira na vez
	if vida_da_frota <= 0 and not coop_venceu:
		_a_frota_cai()


func toque(l: int, julgamento: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	_dano(l, DANO[julgamento] * (2 if CenarioDaGaleria.na_reta(self) else 1))
	if str(info.get("tipo", "")) == "aperta":
		_j_aperta[l] = julgamento
		return
	if _j_aperta[l] >= Ritmo.OTIMO and julgamento >= Ritmo.OTIMO:
		Forja.som_falante(l, "coleta", 0.7)
		_arrancar_um_caixote(l)


func nota_perdida(l: int, nn: int) -> void:
	_nota_em_curso[l] = nn
	if bool(_info[l].get(nn, {}).get("calada", false)):
		return
	super(l, nn)
	if str(_info[l][nn].tipo) == "solta" and _atirando[l]:
		_superaquecer(l)


func falha(l: int) -> void:
	_rajada_torta(l)
	CenarioDaGaleria.coice(jogador(l), COICE_M)


# O R2: manda só quando o [modo, a, b, c] muda.
func _r2(l: int, g: Array) -> void:
	if _gat[l] == g:
		return
	_gat[l] = g
	Forja.gatilho(l, 1, int(g[0]), int(g[1]), int(g[2]), int(g[3]))


func _armar(l: int) -> void:
	_r2(l, [Forja.GATILHO_VIBRACAO, POSICAO, AMPLITUDE, clampi(int(round(Ritmo.bpm / 60.0 * 4.0)), 1, 255)])
```

- `_dano(l, d)` tira `d` da nau (se `_nau == 1`) ou da frota, marca `d * PONTOS_POR_DANO` pelo `marcar`, guarda
  `_ultimo_dano = l`, e chama a queda da nau no quadro em que ela chega a 0.
- `_apertou(l, r2)`: com a trava ou o canhão, nada. Sem `aperta` casado, `_superaquecer(l)`. Com ele, abre
  `_disparo[l]`, julga e grava a `entrada`.
- `_soltou(l, r2)`: com o `solta` da rajada em aberto, julga direto e grava a `entrada`, e só então esvazia
  `_disparo[l]`.
- `_superaquecer(l)` faz o que «O superaquecimento» diz: `_travada_ate[l]` em batidas, o `_r2` com a `TRAVA`, as
  notas caladas, o `superaqueceu` e a fumaça.
- `_a_trava(l)`: no último tempo (`Ritmo.batida() >= _travada_ate[l] − 1`), `_r2` com o `ESFRIA`; no fim, `_armar`.
  O fim do canhão também chama `_armar` para quem não está na trava.
- `_feiticos(l)`: com `_atirando[l]` e a rajada dele em curso, um feitiço a cada semicolcheia da música
  (`floor(Ritmo.batida() * 4)` mudou), com o tiro no alto-falante (O som).
- `status(l)`: `"%d de dano" % (pontos[l] / PONTOS_POR_DANO)` quando `na_raia(l)`.
- `dica(l)`: `{"partes": ["@r2", "Segure a sua vez"]}`, só com `na_raia(l)` e `not aprendeu(l)`.

### O catálogo e as traduções

- No `catalogo.gd`: `Catalogo.MINIGAMES["S05_J23"] = preload("res://scripts/minigames/s05/metralhadora_de_feiticos.gd")`,
  e `"S05_J23"` na lista `"minigames"` da seção `S05`, depois do `S05_J22`.
- O `.uid` novo: `metralhadora_de_feiticos.gd.uid`, gerado com `"$GODOT" --headless --path godot --import --quit`.
- As traduções que ainda não existirem: `"Metralhadora de Feitiços": "Spell Gatling"`,
  `"Segure a rajada!": "Hold the burst!"`, `"Segure!": "Hold!"`, `"Segure a sua vez": "Hold your beat"`,
  `"%d de dano": "%d damage"`.

### O registro

- **A `saida` de gatilho**, gravada pelo `Forja` (F06): `lado` `"R2"`, com `modo` `"vibracao"` e `params`
  `[1, 6, hz]` (10 a 155 bpm, 7 a 104), `"resistencia"` com `[0, 8, 0]` e `[0, 4, 0]` (a trava e o esfriar) e
  `"arma"` com `[3, 6, 8]` (o canhão).
- **`entrada` `disparo`** no começo e no fim julgados, o `toque` do kit, e `jogo` `superaqueceu`.
- **A linha `momento`** por `CenarioDaGaleria.momento`: `nau_cai` (o lugar do último dano) e `reta` (lugar −1).
- **O cruzamento:** a rajada solta no tempo com a Vibration `ok` é o tremor que chegou: o dedo conta as quatro
  semicolcheias. O mesmo lugar segurando demais sempre, num controle só, é o tremor que não chegou.

### Armadilhas

- **A Vibration é um envio só.** Mande pelo `_r2`, que compara o último envio: no começo, na volta da trava e na
  volta do canhão.
- **A rajada longa só com três ou mais.** Com dois, ela bateria na próxima vez do mesmo dono.
- **A trava cala as notas.** Ela é a falha; as notas da trava não viram mais erros.
- **A batida do canhão não tem dono.** Senão a Weapon do canhão chegaria no meio de uma rajada.
- **O L2 é do item.** A metralhadora é só o R2.
- **Não declare `_notas`.** A fila é do kit (H08). O que é da Metralhadora fica em `_info`.
- **Poupar as mãos** ([10](../10-a-regua-astro-bot.md), lição 15): 90 s de rajada cansam. A chance 0,5 da entrada e
  as batidas dos outros são o descanso.

## A cena

### A câmera

Plano fixo, `"camera": "fixa"`, sem corte do apito ao apito:
- posição `Vector3(0, 6.8, 11.5)`, olhando para `Vector3(0, 2.2, -3.0)`. A plongée é de 18°;
- lente de 35 mm (FOV vertical 37,8°).

A câmera sobe o olhar em relação à M1 (de 0,2 para 2,2 m) para caber o céu: a quilha da frota, a 3,2 m em
z = −7, fica 6° acima do centro do quadro, e os pés dos cavaleiros, 16° abaixo (o meio quadro tem 18,9°). O tremor
vem de `CenarioDaGaleria.impacto`.

### A luz

A da M1, por `CenarioDaGaleria.montar(self)`: a névoa NEVOA `#18081c`, o preenchimento PREENCHIMENTO `#4a2854`
(energia 0,35), a chave CHAVE `#f8ccba` (energia 1,0) e o néon do mundo VIOLETA `#4a3aa8`.

- **O pico:** `CenarioDaGaleria.pico(self)` quando a nau sobe (a chave a ×1,2, a névoa a ×0,8).
- **A catástrofe** (a nau cai): a chave a ×1,4 por 1 batida, pelo `impacto`.
- **Nenhuma cor nova.** O olho `#ff4a2a` e o laranja da barra de luz da ficha antiga saem.

### As peças

| peça | de onde | o papel | escala pedida |
| --- | --- | --- | --- |
| os quatro navios | `pirate-kit/ship-small` (x ±6) e `pirate-kit/ship-medium` (x ±2), por `peca_ou`; o substituto é `Kit.peca(pai, "wood-structure", Vector3.ZERO, 0.0, 1.6)` com a vela `Kit.peca(pai, "banner", Vector3(0, 1.2, 0), 0.0, 1.4)` | em (`RAIAS[i]`, 3,2, −7,0), de lado (`rot_y` = PI/2), um sobre cada raia | 0,6 (×0,4 do pacote: 2,1 m de comprido, 2,4 m de altura) |
| a nau capitânia | `pirate-kit/ship-large`, por `peca_ou`; o substituto é o dos navios a 3,2 | em (0, 2,6, −8,5), de lado; sobe de y −3 | 1,2 (6,3 m de comprido, 3 vezes um navio pequeno) |
| o canhão da nau | `pirate-kit/cannon`, por `peca_ou`, filho da nau; o substituto é `Kit.cilindro` Ø 0,3 × 1,0 m GRAFITE | no costado, virado para a câmera | 1,2 |
| a bala do canhão | `pirate-kit/cannon-ball`; o substituto é uma esfera Ø 0,3 m GRAFITE | da boca a (0, 0, −1,5) em 1 batida | 1,2 |
| o buraco | `pirate-kit/hole`, por `peca_ou`; sem o pacote, `Kit.cilindro` Ø 0,8 × 0,02 m OXIDO | onde a bala cai, por 4 s | 1,2 |
| os destroços | `pirate-kit/ship-wreck` no lugar de cada navio (e da nau) que cai | caem atrás do muro | a do navio |
| o mastro solto | `pirate-kit/mast`, por `peca_ou`; sem o pacote, nada | gira 2 voltas em `z` enquanto a nau cai | 1,2 |
| o caixote | `pirate-kit/crate`, por `peca_ou`; o substituto é `Kit.caixa` 0,3 m OXIDO_BRILHO `#7a5640` | cai do navio atingido na rajada inteira boa, até sumir atrás do muro | 0,6 |
| a lanterna da proa | `Kit.caixa` 0,16 m, filha de cada navio e da nau | acende na cor do dono no aviso da rajada | — |
| o feitiço | `Kit.caixa` 0,12 × 0,12 × 0,3 m na cor do dono | da boca da arma ao alvo em 1/4 de batida | — |
| a metralhadora | `CenarioDaGaleria.arma_na_mao(p, METRALHADORA)` | na mão direita | a da M1 |

- **O Pirate Kit no lugar do enemy-ufo.** O 14 lista `enemy-ufo-*` do Tower Defense para a frota. A ficha usa o
  Pirate Kit, porque a seção é «a frota pirata» e o Pirate Kit traz os destroços, o mastro e o canhão da queda.
- **O balanço:** os navios em `y` com 0,15 × `sin(PI * Ritmo.batida() * 0.5)`, cada um meia batida depois do
  anterior. A nau, com 0,1.
- **O dano à vista na frota:** com 50 % da vida, os quatro navios inclinam 0,26 rad (15°) em `z`; com 25 %, a
  fumaça GRAFITE sobe de cada um (`Efeitos.poeira`, n 12). Aos 60 s, a frota desce 1 m em 2 batidas.
- **A nau que cai:** troca por `ship-wreck`, desce de y 2,6 a −6 em 4 batidas (`TRANS_QUAD`, `EASE_IN`), com
  `Efeitos.brasas(self, <a nau>, Vector3(3.0, 1.5, 1.0), CenarioDaGaleria.TUNGSTENIO, 40)` nas velas. Depois, a
  fumaça `Efeitos.poeira(self, Vector3(0, 0.5, -9.5), Vector3(4.0, 3.0, 1.0), CenarioDaGaleria.GRAFITE, 40)` fica
  até o fim.

### O que brilha, e de quem é o brilho

| o quê | cor | emissivo | dono |
| --- | --- | --- | --- |
| a borda da raia | a cor do lugar | a do kit; 1,0 na vez do dono | o jogador |
| a lanterna da proa | a cor do dono da rajada | 2,0 do aviso ao fim da rajada; 0 fora | o jogador |
| o feitiço | a cor do dono | 2,0 | o jogador |
| a boca do canhão | TUNGSTENIO `#ffd9a8` | 2,4, 1 batida antes do tiro | a forja |
| as faíscas e as brasas | TUNGSTENIO | chapadas | a forja |
| o néon do mundo | VIOLETA `#4a3aa8` | 3,0 hoje, 1,2 com a G15 | o mundo |

Nada mais brilha. Os navios, os destroços, a fumaça, a mancha e o cano vermelhão são foscos.

### O impacto

Por `CenarioDaGaleria.impacto` (a tabela da M1):
- o caixote arrancado: `toque` (10 faíscas) no navio;
- a bala do canhão no chão: `golpe` (tremor 0,167 por 1 batida, sem hit-stop: `l` −1);
- a nau que cai: `catastrofe` (tremor 0,667 por 4 batidas, a chave a ×1,4);
- a frota que cai: `estrondo` em cada navio, com `l` −1.

## O som

| evento | id do mapa | onde | como |
| --- | --- | --- | --- |
| a música | `mus_s05_j23` (155 bpm, Fá menor, 150 s; seca, sem cauda de reverberação, rajadas) | TV | `"faixa": "MUS_S05_J23"`; sem a faixa (H05), a trilha sintetizada `"galeria"` a 104 bpm |
| cada feitiço da rajada | `tiro_0` a `tiro_4` | alto-falante do dono | `Som.no_controle(l, "tiro", 0.35)`, um por semicolcheia |
| o começo da rajada | `tiro_*` | TV | `Som.tocar("tiro", <a boca da arma>, -14.0)`, um por rajada |
| o começo e o fim julgados | `jul_ressonancia_p{n}`, `jul_afinado_p{n}`, `jul_quase_p{n}`, `jul_erro_p{n}` | TV e alto-falante | o kit (`_reagir`); a ficha não toca nada |
| a rajada inteira boa | `mod_coleta` | alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` |
| o superaquecimento | `mod_tropeco` | alto-falante do dono | `Forja.som_falante(l, "tropeco", 0.7)` |
| o canhão | `golpe_*` | TV | `Som.tocar("golpe", <o canhão>)` |
| a nau e a frota caem | `pedra_*` e `sint_fogo` | TV | `Som.tocar("pedra", <a nau>)` e `Som.tocar("fogo", <a nau>, -6.0)` |
| a falha | `fx_tropeco_*` | TV | o kit (H11); a ficha não toca nada |
| os carimbos | `car_em_chamas`, `car_acorde`, `jin_virada` (o carimbo `car_virada`), `car_por_um_fio` | TV | o kit e o HUD |

- **O alto-falante toca um som por vez**, na prioridade do kit: o julgamento, a coleta, o tropeço e o tiro. O tiro
  de cada semicolcheia é o último da fila: some quando outro toca.

## O controle

| recurso | evento | quem joga | os outros |
| --- | --- | --- | --- |
| **gatilho R2 (protagonista)** | do começo ao fim | `GATILHO_VIBRACAO` (1, 6, hz): hz = semicolcheias da faixa (10 a 155 bpm); um envio só | o mesmo, cada um no seu |
| gatilho R2 | o superaquecimento | `GATILHO_RESISTENCIA` (0, 8) pela trava; (0, 4) no último tempo; depois a Vibration | nada |
| gatilho R2 | o canhão da nau, no pico | `GATILHO_ARMA` (3, 6, 8) por 1 batida, em todos fora da trava | o mesmo |
| vibração | o começo e o fim julgados | `acerto` (0,3/0,6, 80 ms), `perfeito` (0,5/0,8, 100 ms) ou `erro` (0,7/0,3, 160 ms), pelo kit | nada |
| vibração | o superaquecimento | `Forja.sentir(l, "erro")` (0,7/0,3, 160 ms) | nada |
| vibração | o canhão | `Forja.sentir(l, "golpe")` (1,0/0,6, 250 ms) | todos |
| vibração | a nau e a frota caem | `Forja.sentir(l, "explosao")` (1/1, 400 ms) | todos |
| háptica | o toque julgado | a textura `"metal"`, pelo kit | nada |
| barra de luz | sempre | a cor do lugar, 100 %; o kit pisca branco no perfeito e escurece no erro | a cor de cada um |
| luzinhas | sempre | o número do lugar | o número de cada um |
| alto-falante | O som | o tiro de cada semicolcheia, a coleta e o tropeço | nada |
| microfone | — | Não se aplica: a Metralhadora não ouve | — |

O que espera uma medida, e o caminho sem ela:
- **A fase do tremor.** O tremor da Vibration corre no relógio do controle, não no da música. Casar a fase com a
  semicolcheia pede reenviar a cada batida, e isso espera a medida da fase na bancada. Hoje é um envio só, na
  frequência da faixa.

**A prova sem o controle na mão:**
- o robô sente o modo pelo primeiro byte (`Forja.percepcao(l)["gatilho_dir"]`: `0x26` Vibration, `0x21` a trava,
  `0x25` o canhão), e só começa a rajada com `0x26`;
- os `params` da `saida` no registro dizem a frequência, a trava e o esfriar.

## O cavaleiro

| stat | gancho | o que muda aqui |
| --- | --- | --- |
| Fôlego | `levantar` | a trava do superaquecimento: 4 batidas × (1 − 0,125 × (Fôlego − 3)); Fôlego 1 dá 5 batidas, e 5 dá 3. Arredonda à semicolcheia (`CenarioDaGaleria.queda_s(l, 4.0)`); na reta, `queda_s(l, 8.0)` |
| Faro | `pista` | a raia e a lanterna da proa acendem 20 ms × (Faro − 3) antes; Faro 5 dá +40 ms, e 1 dá −40 ms (`pista_s`) |
| Peso | — | não muda nada |
| Passo | — | não muda nada |

- **Os itens são do kit:** o Martelo (pelo `marcar`), o Escudo (o primeiro erro), o Fole, o Diapasão (no coop, o
  combo da turma) e a Lanterna (somada pela `pista_s`).
- **A peça.** O cavaleiro fica de costas (`rotation.y = PI`). O item da mão direita some enquanto a metralhadora
  está na mão e volta no `sair()` (`CenarioDaGaleria.guardar_arma`). O Escudo e os amuletos ficam à vista. As cores
  da montagem não mudam nesta ficha.

## As reações

- **Nenhum adesivo.** Todos jogam o tempo todo (a vez muda a cada batida), e ninguém fica fora da rodada para mandar
  um.
- **Os carimbos são do kit e do HUD**, e esta ficha não chama nenhum: `car_em_chamas`, `car_acorde`, `car_virada` e
  `car_por_um_fio`.
- **A rajada longa é o encontro.** Dois dedos tremendo juntos, nas duas raias acesas, uma vez a cada 4 compassos do
  pico.

## A diversão

**O momento: `nau_cai`**
- **Quando:** a janela é de 40 a 60 s, na mesa boa. As rajadas dos quatro derrubam a nau do meio: ela quebra, as
  velas pegam fogo, o mastro gira e ela cai atrás do muro. Degrau catástrofe.
- **O que se vê:** a câmera treme 4 batidas, a chave sobe a ×1,4, e a fumaça da nau sobe do fundo até o fim. A
  frota pequena volta para a frente, menor diante do que acabou de cair.

**Como o jogador do time confere:**
- **No registro,** pelo robô, semente 7:
  - na mesa boa: pelo menos **1 linha `momento` `nau_cai`**, com `t_musica` entre 40 e 60 s, e uma linha `sensacao`
    `explosao` de cada lugar a até 16,7 ms dela;
  - na mesa fraca: a nau perde pelo menos 50 % da vida (o `vida_da_nau` aos 60 s é no máximo a metade do inicial);
    e a frota fica no céu aos 90 s (`coop_venceu` falso), com pelo menos 50 % da vida tirada.
- **Na prancha (F09):** no quadro de 60 s da mesa boa, a fumaça da nau no fundo.
- **A falha à vista:** na mesa padrão, o P4 (`ruim`) tem pelo menos 10 linhas `toque` com `erro` em 90 s, e pelo
  menos 1 linha `superaqueceu`. Em pelo menos 1 quadro de cada 5 da prancha, há uma mancha no muro ou uma arma
  soltando fumaça.
- **Ninguém para:** a maior distância entre duas rajadas não caladas do mesmo lugar é de até 8 batidas, fora da
  trava.

A mesa boa (`--robo=bom`) e a mesa fraca (`--robo=medio`) rodam hoje, porque têm um temperamento só. A falha
à vista pede a mesa padrão (`--robo=bom,medio,medio,ruim`, o robô por lugar, pedido ao arquiteto na régua) e
espera ele existir.

## Pronto quando

A Metralhadora de Feitiços joga do aviso ao resultado:
- com 4, 3, 2 e 1 jogador, e com o robô nos três temperamentos (o bom derruba a nau e a frota; o ruim superaquece e a
  frota foge);
- aguenta o cabo que cai no meio de uma rajada;
- fecha com o resultado coop e o destaque;
- abre o `S05_J23` com `--sala=S05_J23`;
- grava as linhas `momento` da nau e da reta.

A prova do jogo passa, e a prova visual passa com a prancha olhada.

### Ao terminar

- No [quadro](README.md), quem coordena marca a linha **M3** com o commit.
- Commit sugerido (sem trailer): `feat: Metralhadora de Feitiços, a rajada dividida no tremor do gatilho e a nau
  capitânia do pico`.

## Provas

Os comandos: `SALA=S05_J23 bash tests/prova_do_jogo.sh` (o sh roda duas rodadas, sem bancada e com
`--bancada`), `bash tests/prova_do_jogo.sh` (o jogo inteiro) e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a prova entra como uma linha no `match` de `_prova_da_ficha` (o modelo
da H08):

```gdscript
		"S05_J23": await _prova_da_metralhadora()
```

E acrescente a função abaixo, depois da prova do Arco. O `_joga_o_minigame(slot, limite_s, a_cada_quadro)` é da H08.

```gdscript
# A Metralhadora (S05_J23): é coop com o destaque; a Vibration chegou ao R2
# na frequência das semicolcheias; a trava e o esfriar saíram; as vidas só
# descem; a nau, se cai, cai no pico com a explosão em todos.
func _prova_da_metralhadora() -> void:
	var modos := {}
	var vidas: Array = []
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			modos[int(Forja.percepcao(l).get("gatilho_dir", 0))] = true
		vidas.append([int(mg.vida_da_nau), int(mg.vida_da_frota)])
	var mg = await _joga_o_minigame("S05_J23", 135.0, olhar)
	if mg == null:
		return
	_esperar(mg.coop and mg.destaque() >= 0, "Metralhadora: é coop, com o destaque")
	_esperar(modos.has(0x26), "Metralhadora: a Vibration chegou ao R2 (bytes vistos: %s)" % [modos.keys()])
	var subiu := false
	for i in range(1, vidas.size()):
		if vidas[i][0] > vidas[i - 1][0] and vidas[i - 1][0] > 0 or vidas[i][1] > vidas[i - 1][1] and vidas[i - 1][1] > 0:
			subiu = true
	_esperar(not subiu, "Metralhadora: as vidas da nau e da frota nunca sobem")
	var linhas := _linha_do_tempo()
	var gat := linhas.filter(func(e): return e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("lado") == "R2")
	var hz := clampi(int(round(Ritmo.bpm / 60.0 * 4.0)), 1, 255)
	var vib := gat.filter(func(e): return e.get("modo") == "vibracao")
	_esperar(not vib.is_empty() and vib.all(func(e): return e.get("params", []) == [1, 6, hz]),
		"Metralhadora: a Vibration é (1, 6, %d)" % hz)
	var travas := linhas.filter(func(e): return e.get("slot") == "S05_J23" and e.get("o") == "superaqueceu")
	if not travas.is_empty():
		var forcas := gat.filter(func(e): return e.get("modo") == "resistencia").map(func(e): return int(e.get("params", [0, 0])[1]))
		_esperar(8 in forcas and 4 in forcas, "Metralhadora: a trava (0, 8) e o esfriar (0, 4) saíram")
	var naus := linhas.filter(func(e): return e.get("slot") == "S05_J23" and e.get("nome") == "nau_cai"
		and (e.get("tipo") == "momento" or e.get("o") == "momento"))
	_esperar(naus.size() <= 1, "Metralhadora: a nau cai no máximo uma vez")
	for o in naus:
		_esperar(float(o.get("t_musica", 0.0)) >= 30.0 and float(o.get("t_musica", 0.0)) <= 60.0,
			"Metralhadora: a nau caiu no pico (%.1f s)" % float(o.get("t_musica", 0.0)))
		var expl := linhas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "explosao"
			and absf(float(e.get("t", 0.0)) - float(o.get("t", 0.0))) <= 0.0167)
		_esperar(expl.size() >= mg.presentes().size(), "Metralhadora: a explosão em todos no quadro da nau")
	var reta := linhas.filter(func(e): return e.get("slot") == "S05_J23" and e.get("nome") == "reta")
	_esperar(reta.size() <= 1, "Metralhadora: no máximo uma linha momento reta (a frota pode cair antes)")
```

**Na prova visual** (`bash tests/prova_visual.sh`, F09), a Metralhadora entra pela semente que o
`Catalogo.sortear` da H08 põe na noite (`--semente=N`), uma vez com `--robo=bom` (a mesa boa) e uma com
`--robo=medio` (a mesa fraca). O jogador do time olha a prancha:
- o quadro de 60 s da mesa boa, com a fumaça da nau no fundo;
- um quadro com uma arma soltando fumaça e o cavaleiro recuado;
- o último quadro da mesa fraca, com a frota inclinada e fumegando no céu.

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J23`):
- o tremor do R2 é uma rajada em semicolcheias, no andamento da faixa;
- a frase do ataque passa de mão em mão e fica inteira quando todos acertam;
- a trava é dura de verdade, e o esfriar no último tempo avisa que ela vai soltar;
- a nau, o canhão que bate no dedo de todos, e a nau caindo é festa.
