# M4 — Espada de Fita

**Sprint:** M · **Slot:** S05_J24 · **Tamanho:** M · **Depende de:** H04, H08, F09, M1

## Por quê

O duelo em dupla da seção. A espada é uma fita K7 esticada entre a mão e um carretel. A cada batida a fita estica
mais, e o R2 pesa um degrau a mais: 2, 4, 6, e no topo a fita zune no dedo. **O peso é o relógio.** No topo, solte:
a fita estala e a espada corta. A dupla que puxou e soltou mais no tempo corta a outra, e o corte cruza a tela.

Diferente do arco da M2, em que a nota longa manda e o peso acompanha, aqui é o peso que conta até a soltura. Dá
para jogar de olhos fechados, só pelo dedo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o kit, a ficha de dados, o catálogo, a régua, o `2v2`)
- [A M1, «A cena»](M1-a-galeria.md#a-cena) (o cenário comum `CenarioDaGaleria`, a luz, o impacto, o rastro e o
  `_joga_o_minigame` da prova)

Tudo o que esta ficha tira da bíblia de arte, do mapa do áudio, da régua da diversão, das equipes da H08, do
Aprendiz da Q1 e do RPG está escrito aqui ou na M1, com o número. O cenário comum da M1 não muda nesta ficha: ela
só o usa.

## Arquivos que mudam

- `godot/scripts/minigames/s05/espada_de_fita.gd` (novo, com o `.uid` que o Godot gera)
- `godot/scripts/minigames/catalogo.gd`: o slot `S05_J24` em `MINIGAMES` e na seção `S05`. **De todos:** as M1 a
  M5 mudam este arquivo
- `godot/scripts/traducoes.gd`: as frases novas. **De todos:** as M1 a M5 mudam este arquivo
- `godot/testes/prova_do_jogo.gd`: a prova da Espada. **De todos:** as M1 a M5 mudam este arquivo

## Como se joga

A faixa é `mus_s05_j24`, a 142 bpm (1 batida = 0,423 s). São 90 s, ou 213 batidas. Sem a faixa, a trilha
`"galeria"` toca a 104 bpm, e tudo abaixo está em batidas.

**As duplas** são as equipes do kit (H08), montadas pelo `montar_equipes` antes do `montar`. A dupla 0 é **A
Brasa** (`CORES_DAS_EQUIPES[BRASA]`, âmbar `#e8a33c`) e a 1 é **A Maré** (turquesa `#2fb3b3`). `da_equipe(e)`
dá os lugares; `aprendizes[e]` diz quantos Aprendizes completam cada uma:

| presentes | A Brasa | A Maré |
| --- | --- | --- |
| 4 | 1º e 2º | 3º e 4º |
| 3 | 1º e 2º | 3º e o Aprendiz |
| 2 | 1º e o Aprendiz | 2º e o Aprendiz |
| 1 | 1º e o Aprendiz | dois Aprendizes |

Toda dupla tem sempre dois na arena. O **Aprendiz** é o boneco da Q1: não é lugar, não pontua e não é robô. Ele
acerta cada nota com a chance `ACERTO_APRENDIZ` (0,8), sorteada com o `rng` do kit, sempre como BOM.

**As vagas.** A Brasa fica à esquerda, virada para a direita (`rotation.y = PI * 0.5`); a Maré fica à direita,
virada para a esquerda (`-PI * 0.5`). São duas fileiras de duelo:

| vaga | x | z | quem |
| --- | --- | --- | --- |
| Brasa, fundo | −2,2 | −0,4 | o 1º da Brasa |
| Brasa, frente | −2,2 | 2,4 | o 2º da Brasa, ou o Aprendiz |
| Maré, fundo | 2,2 | −0,4 | o 1º da Maré, ou um Aprendiz |
| Maré, frente | 2,2 | 2,4 | o 2º da Maré, ou um Aprendiz |

O `raia(l)` do kit vai para a vaga (`raia(l).position = VAGA`), e o cavaleiro também, depois do `posicionar(l)`.

**A estocada.** Todos puxam juntos: cada um com a sua nota, a dupla soma. No compasso `c` (batidas `4c` a `4c + 3`,
gerado quando `Ritmo.batida() >= 4c − 4`), cada presente ganha as estocadas da parte (os terços pelo tempo de música
da puxada, `CenarioDaGaleria.andamento_em(self, t)`):

| parte | segundos (de 90) | a puxada | o peso (Feedback, posição 2) | o topo (Vibration) | a soltura |
| --- | --- | --- | --- | --- | --- |
| entrada | 0 a 30 | `4c` | `PESO` 2, 4, 6 em `4c`, `4c + 1`, `4c + 2` | `4c + 2,5` | `4c + 3` |
| **pico** | 30 a 60 | `4c` e `4c + 2` | `PESO_DO_PICO` 4, 6 em `b`, `b + 0,5` | `b + 1` | `b + 1,5` |
| saída | 60 a 90 | `4c` | como na entrada | `4c + 2,5` | `4c + 3` |
| **a reta** | as últimas 16 batidas (83,2 a 90 s a 142 bpm) | como na saída | como na saída | como na saída | como na saída; o primeiro corte leva a rodada |

- **O pico tem duas estocadas curtas** por compasso: o dobro da entrada, e o peso corre o dobro (um degrau a cada
  meia batida).
- **A partitura simples:** quem está com `Ritmo.simples[l]` fica com a estocada da entrada também no pico.
- **A pausa entre rodadas:** o primeiro compasso cuja puxada cai em 30 s ou depois, e o primeiro em 60 s ou depois,
  não têm estocada. É quando as fitas voltam.
- **Ninguém para:** toda estocada é de todos. A maior distância entre duas puxadas do mesmo lugar é de 8 batidas
  (a pausa).

**As notas.** Cada estocada `e` de um lugar é um par:
- a **puxada**, na geração: `nova_nota(l, n, Ritmo.t_da_batida(b))`, com `n = int(round(b * 4))`. Os dados ficam
  em `_info[l][n] = {"b": b, "tipo": "puxa", "e": e, "solta": b_solta}`;
- a **soltura**, só quando a puxada foi BOM ou melhor: `nova_nota(l, n2, Ritmo.t_da_batida(b_solta))`, com
  `n2 = int(round(b_solta * 4)) + 1`, e `_info[l][n2] = {"b": b_solta, "tipo": "solta", "e": e}`.

O `n` da soltura é ímpar e o da puxada é múltiplo de 2. No pico, a soltura em `4c + 1,5` (`16c + 7`) não bate com
a puxada em `4c + 2` (`16c + 8`).

**Puxar.** O R2 subindo até `CenarioDaGaleria.R2_APERTA` (0,5) casa com `casar_toque(l)`. Se a nota casada é uma
`puxa`, guarde `_nota_em_curso[l] = n` e chame `julgar_nota(l, n)`. Na puxada boa, a fita pega: o peso começa em
`(2, PESO[0])`, e a soltura nasce.

**O peso.** De cada degrau ao topo, `_pesar(l)` manda `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, f)` na
batida da tabela, pelo `Ritmo.batida()`. No topo, a fita zune: `Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, 2,
TOPO_AMPLITUDE, TOPO_HZ)`, com amplitude 6 e 20 Hz. O topo é outro modo de propósito: o dedo distingue o zumbido do
último Feedback sem contar.

**Soltar no topo.** O R2 caindo até `R2_SOLTA` (0,2), com a `solta` em aberto: guarde `_nota_em_curso[l] = n2` e
chame `julgar_nota(l, n2)` direto. Soltar cedo é ERRO pelo julgamento. Depois de toda soltura, o R2 volta a
`(2, PESO_PARADO)`: a fita frouxa.

**A fita arrebenta.** A `solta` que passa de `FOLGA_PERDIDA` (0,14 s) com o R2 acima de 0,2 é a `nota_perdida` do
kit. Uma colcheia depois da soltura (0,211 s a 142 bpm), se o dedo ainda segura, a fita arrebenta (A falha).

**A dupla que perdeu a rodada anterior** joga a rodada seguinte com a fita **meio degrau mais leve**: cada força
de Feedback −1 (`PESO` 1, 3, 5; `PESO_DO_PICO` 3, 5) e o topo com amplitude 5. As janelas não mudam.

**O corte.** Na colcheia depois da soltura, em `Ritmo.t_da_batida(b_solta + 0,5)`, a estocada se resolve uma vez
(marque `resolvida`):
- cada dupla soma, de cada um dos dois, `VALOR[j_puxa] + VALOR[j_solta]` (`VALOR` = 0, 1, 2, 3). A soltura que não
  nasceu vale 0;
- o Aprendiz soma `VALOR[BOM]` (1) em cada nota que acerta. A soltura dele só é sorteada se a puxada acertou;
- **o acorde:** os dois da dupla soltaram PERFEITO → `+ACORDE` (2);
- a dupla com a soma maior **corta** a outra. Nas duas somas iguais, as espadas batem no meio e ninguém corta.
  Com as duas em 0, nada acontece.

| o que acontece | onde | o que vale |
| --- | --- | --- |
| o corte | a dupla que cortou | `cortes[d] += 1` na rodada; `marcar_equipe(d, CORTE)` (200) |
| as espadas batem | o meio da arena | nada |
| cada nota boa | a dupla de quem tocou | `marcar_equipe(equipe[l], PONTOS[j])` (40, 70, 100) |

O registro grava `anotar("jogo", -1, {"o": "corte", "dupla": d, "somas": "%d,%d" % [s0, s1]})` em todo corte e em
toda batida de espadas (`d` −1).

**O momento.** Todo corte chama `CenarioDaGaleria.momento(self, "corte", l)`, com `l` o primeiro lugar da dupla
que cortou (`da_equipe(d)[0]`), ou −1 numa dupla só de Aprendizes.

**As rodadas são os terços.** A rodada 1 vai de 0 a 30 s, a 2 de 30 a 60 s, a 3 de 60 a 90 s. A rodada fecha no
compasso da pausa: vai para a dupla com mais cortes nela (`rodadas[d] += 1`); no empate, para ninguém. A dupla
perdedora fica com a fita leve na rodada seguinte. Depois de fechar, `cortes` volta a [0, 0] e os riscos do chão
somem.

- **Duas rodadas ganham.** Com 2 a 0 ao fechar a rodada 2, todos `acabou` aos 60 s.
- **A reta.** No primeiro quadro com `CenarioDaGaleria.na_reta(self)`, chame
  `CenarioDaGaleria.momento(self, "reta", -1)`. **O primeiro corte da reta leva a rodada 3**, qualquer que seja a
  conta dela, e a rodada fecha ali. Os cortes seguintes contam pontos e deixam o risco. Sem corte na reta, a rodada
  3 fecha aos 90 s pela conta.

Toda puxada e toda soltura julgadas gravam
`anotar("entrada", l, {"o": "disparo", "n": n, "modo": <"resistencia" ou "vibracao">, "curso": r2, "curso_max": <o maior R2 desde a puxada>})`.

### A ficha de dados

O cabeçalho do script `godot/scripts/minigames/s05/espada_de_fita.gd` é um comentário `#` com estas linhas:
- **o jogo:** duas duplas frente a frente, cada um com uma espada de fita. A cada compasso, todos puxam o R2 no
  tempo 1; o peso sobe um degrau por batida (Feedback 2, 4, 6) e a fita zune no topo (Vibration). Soltem no
  tempo 4. A dupla que puxou e soltou mais no tempo corta a outra;
- **a falha:** a fita arrebenta (soltar fora do tempo, ou segurar além) e cai no chão; puxar fora do tempo não
  pega a fita. Os dois cambaleiam 0,5 m;
- **o vencedor:** a dupla com mais rodadas (os terços), depois mais cortes, depois mais pontos;
- **o alto-falante do dono:** o tique de cada degrau, a coleta do corte dado e o golpe do corte levado;
- **o registro:** cada degrau do Feedback, o topo em Vibration e o Off da fita arrebentada; o curso do R2 na
  puxada e na soltura; o `corte`;
- **o robô:** puxa no tempo 1 e solta no tempo 4, pelo relógio da música; quando não acerta, solta 250 ms tarde;
- **com menos de quatro:** o Aprendiz completa as duplas (H08);
- **a régua:** (1) «Solte no topo!» com a fita esticando; (2) sim: o peso conta as batidas até o topo; (3) não
  pergunta nada.

```gdscript
extends Minigame

const FICHA := {
	"slot": "S05_J24",
	"titulo": "Espada de Fita",
	"verbo": "Solte no topo!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J24",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "toque", "golpe", "golpe_dir", "golpe_esq"],
	"material": "metal",
	"microjogo": {"verbo": "Solte!", "segundos": 6.0},
	"gesto": "attack-melee-right",
}
```

### As constantes

```gdscript
const PONTOS := [0, 40, 70, 100]  # ERRO, BOM, OTIMO, PERFEITO, por nota, para a dupla
const VALOR := [0, 1, 2, 3]  # o que cada nota soma para a dupla na estocada
const ACORDE := 2  # os dois da dupla soltaram PERFEITO
const CORTE := 200  # os pontos do corte, para a dupla
const ACERTO_APRENDIZ := 0.8
const PESO := [2, 4, 6]  # Feedback, posição 2, um degrau por batida
const PESO_DO_PICO := [4, 6]  # um degrau a cada meia batida
const PESO_PARADO := 1  # a fita frouxa, fora da estocada
const LEVE := 1  # o meio degrau da dupla que perdeu a rodada
const TOPO_AMPLITUDE := 6
const TOPO_HZ := 20
const VAGAS := [[Vector3(-2.2, 0, -0.4), Vector3(-2.2, 0, 2.4)], [Vector3(2.2, 0, -0.4), Vector3(2.2, 0, 2.4)]]
const RECUO_M := 0.5  # a falha e o corte levado
const FITA_NO_CHAO_S := 2.0
```

### A falha

Toda falha muda a silhueta e deixa rastro (a régua: 0,5 m ou mais por pelo menos 1 batida, e rastro de 2 s ou
mais).

- **A fita arrebenta** (soltura ERRO, ou a soltura perdida):
  - a fita parte no meio, e as duas metades caem ao chão em meia batida (`rotation.x` a 1,2, `TRANS_QUAD`);
    ficam no chão `FITA_NO_CHAO_S` (2 s) e somem em 0,5 s. Uma fita nova liga a mão ao carretel na puxada
    seguinte;
  - a espada tomba mole: `rotation.x` a 1,2 e de volta em 1 batida;
  - o cavaleiro cambaleia `RECUO_M` (0,5 m) para trás, para o lado do carretel: `_recuar(l, RECUO_M)`, um tween
    em `position.x` de 1 colcheia (`TRANS_QUAD`, `EASE_OUT`), parado 1 batida, e de volta em 1 batida
    (`TRANS_SPRING`). Um recuo novo mata o velho (`p.get_meta("recuo")`);
  - `gesto("emote-no", 0.4)`;
  - o R2 fica sem peso: `Forja.gatilho(l, 1, Forja.GATILHO_OFF)` por `CenarioDaGaleria.queda_s(l, 1.0)`, e
    depois `(2, PESO_PARADO)`. A puxada seguinte se julga normalmente, mas o peso só pega quando a queda acaba.
- **A fita não pega** (puxada ERRO, ou perdida): a soltura não nasce. O carretel gira em falso (1 volta em meia
  batida), a fita cai solta ao chão por 2 s, o mesmo recuo e o `emote-no`.
- **O corte levado** não é falha de quem levou: é o acerto do outro (A cena, O controle).

### O fim e o vencedor

`fim` `tempo`: aos 90 s de música, ou antes, com 2 a 0 aos 60 s (todos `acabou`). A tela diz «A Brasa venceu!» ou
«A Maré venceu!» pela `equipe_vencedora()` do kit, que esta ficha troca:

```gdscript
# A dupla na frente: mais rodadas, depois mais cortes somados, depois mais pontos. -1 no empate.
func equipe_vencedora() -> int:
	var pts := [pontos_da_equipe(BRASA), pontos_da_equipe(MARE)]
	for par in [rodadas, cortes_somados, pts]:
		if int(par[0]) != int(par[1]):
			return BRASA if int(par[0]) > int(par[1]) else MARE
	return -1


# A dupla na frente primeiro; dentro da dupla, quem somou mais VALOR nas próprias notas.
func vencedor() -> Array:
	var e := maxi(equipe_vencedora(), BRASA)
	var por_valor := func(a, b): return int(_valor[a]) > int(_valor[b]) or (int(_valor[a]) == int(_valor[b]) and a < b)
	var frente := da_equipe(e).filter(func(l): return l in presentes())
	var tras := da_equipe(1 - e).filter(func(l): return l in presentes())
	frente.sort_custom(por_valor)
	tras.sort_custom(por_valor)
	return frente + tras
```

O destaque é o padrão do kit, o `vencedor()[0]`: o melhor da dupla na frente.

### Com menos de quatro

- **Com três, dois e um,** o Aprendiz completa (a tabela de «As duplas»). `com_poucos()` diz `"Com o Aprendiz"`
  com três e dois, e `"Você e o Aprendiz contra 2"` com um.
- **O controle que cai:** enquanto ele está fora, a parte dele é sorteada como a de um Aprendiz (0,8, sempre BOM),
  e a dupla não perde a metade da soma. As notas dele saem caladas pelo kit. Ele volta na puxada seguinte.

### O robô

```gdscript
# O robô puxa o R2 na batida da puxada e segura até a soltura, pelo relógio
# da música. Quando não acerta (Forja.robo_acerta() falso), solta 250 ms
# tarde: a soltura se perde e a fita arrebenta. Sem soltura em aberto (a
# puxada errou), solta na batida da soltura de qualquer jeito.
var _robo_nota := [-1, -1, -1, -1]
var _robo_puxa_em := [INF, INF, INF, INF]
var _robo_solta_em := [-INF, -INF, -INF, -INF]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var abertas := notas_em_aberto(l)
	if not abertas.is_empty() and int(abertas[0]) != _robo_nota[l]:
		var nn: int = abertas[0]
		_robo_nota[l] = nn
		var info: Dictionary = _info[l][nn]
		var atraso := 0.0 if Forja.robo_acerta() else 0.25
		if info.tipo == "puxa":
			_robo_puxa_em[l] = alvo_da(l, nn)
			_robo_solta_em[l] = Ritmo.t_da_batida(float(info.solta)) + atraso
		else:
			_robo_solta_em[l] = alvo_da(l, nn) + atraso
	var agora := Ritmo.t_musica()
	var segura := agora >= float(_robo_puxa_em[l]) and agora < float(_robo_solta_em[l])
	Forja.robo_eixo(l, Forja.R2, 0.85 if segura else 0.0, 0.06)
```

O robô não precisa sentir o modo para jogar. A prova olha o primeiro byte
(`Forja.percepcao(l)["gatilho_dir"]`): `0x21` no peso, `0x26` no topo e `0x05` (Off) na fita arrebentada.

### Os ganchos

```gdscript
var _info := [{}, {}, {}, {}]  # lugar -> n -> {b, tipo, e, solta}
var _nota_em_curso := [-1, -1, -1, -1]
var _gerado := 1
var _puxado := [false, false, false, false]
var _disparo := [{}, {}, {}, {}]
var _gat := [[], [], [], []]  # o último [modo, a, b, c] mandado ao R2
var _sem_peso_ate := [-1.0, -1.0, -1.0, -1.0]  # a queda, em t_musica
var _estocadas := {}  # e -> {b_solta, j: {lugar: [j_puxa, j_solta]}, resolvida}
var _valor := [0, 0, 0, 0]  # o VALOR somado das próprias notas
var _leve := [false, false]  # a dupla que perdeu a rodada anterior
var _apr := []  # os Aprendizes: [{equipe, vaga, no}]
var cortes := [0, 0]  # na rodada
var cortes_somados := [0, 0]
var rodadas := [0, 0]
var _rodada := 1
var _reta_feita := false
var _reta_decidida := false
var n := {}  # lugar -> {espada, fita, carretel, disco}; "riscos" -> []; "bandeiras" -> [2]


func montar() -> void:
	camera_pos = Vector3(0, 6.6, 10.4)
	camera_olhar = Vector3(0, 1.0, 0.6)
	CenarioDaGaleria.montar(self)
	for e in [BRASA, MARE]:
		var lugares := da_equipe(e)
		for i in 2:
			var vaga: Vector3 = VAGAS[e][i]
			if i < lugares.size():
				var l: int = lugares[i]
				var p := jogador(l)
				raia(l).position = vaga
				posicionar(l)
				p.position = vaga + Vector3(0, 0.1, 0)
				p.rotation.y = PI * 0.5 if e == BRASA else -PI * 0.5
				p.preso = true
				n[l] = _montar_a_espada(p, e, vaga)  # a espada, a fita, o carretel e o disco
				_r2(l, [Forja.GATILHO_RESISTENCIA, 2, PESO_PARADO, 0])
			else:
				_apr.append({"equipe": e, "vaga": vaga, "no": _montar_o_aprendiz(e, vaga)})
	_montar_as_bandeiras()


func sair() -> void:
	for p in jogadores:
		CenarioDaGaleria.guardar_arma(p)
	CenarioDaGaleria.sair(self)
	super()


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # as estocadas da parte, a pausa entre rodadas
		_gerado += 1
	_a_rodada()  # fecha a rodada na pausa, a reta, os 2 a 0
	for l in presentes():
		notas_perdidas(l)
		if not conectado(l):
			_puxado[l] = false
			continue
		var r2 := Forja.eixo(l, Forja.R2)
		if _puxado[l]:
			_disparo[l]["curso_max"] = maxf(float(_disparo[l].get("curso_max", 0.0)), r2)
		if not _puxado[l] and r2 >= CenarioDaGaleria.R2_APERTA:
			_puxado[l] = true
			_puxar(l, r2)
		elif _puxado[l] and r2 <= CenarioDaGaleria.R2_SOLTA:
			_puxado[l] = false
			_soltar(l, r2)
		_pesar(l)  # o degrau pela batida, o topo, a fita que arrebenta, a volta da queda
		_esticar_a_fita(l)
	_resolver_as_estocadas()  # o corte de cada estocada em b_solta + 0,5


func toque(l: int, julgamento: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	marcar_equipe(equipe[l], PONTOS[julgamento])
	_valor[l] += VALOR[julgamento]
	_guardar(l, info, julgamento)  # em _estocadas[e].j[l]
	if str(info.get("tipo", "")) == "puxa":
		_nascer_a_soltura(l, info)
		return
	_r2(l, [Forja.GATILHO_RESISTENCIA, 2, PESO_PARADO, 0])
	jogador(l).gesto("attack-melee-right", 0.6)
	if julgamento == Ritmo.PERFEITO:
		for par in da_equipe(equipe[l]):
			if par != l and conectado(par):
				Forja.sentir(par, "toque")  # o parceiro sente o perfeito do outro


func falha(l: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	_guardar(l, info, Ritmo.ERRO)
	if str(info.get("tipo", "")) == "puxa":
		_a_fita_nao_pega(l)
	else:
		_a_fita_arrebenta(l)  # o Off pela queda_s(l, 1.0)
	_recuar(l, RECUO_M)
	jogador(l).gesto("emote-no", 0.4)


func nota_perdida(l: int, nn: int) -> void:
	_nota_em_curso[l] = nn
	super(l, nn)


# O R2: manda só quando o [modo, a, b, c] muda.
func _r2(l: int, g: Array) -> void:
	if _gat[l] == g:
		return
	_gat[l] = g
	Forja.gatilho(l, 1, int(g[0]), int(g[1]), int(g[2]), int(g[3]))
```

- `_pesar(l)`: com a soltura em aberto e sem queda, o degrau da tabela pela batida desde a puxada, menos `LEVE`
  na dupla leve, pelo `_r2`. No topo, `[GATILHO_VIBRACAO, 2, TOPO_AMPLITUDE (− LEVE), TOPO_HZ]`. Uma colcheia
  depois da soltura com o R2 acima de 0,2: `_a_fita_arrebenta(l)`. Cada degrau novo toca o tique (O som).
- `_resolver_as_estocadas()`: no primeiro quadro com `Ritmo.batida() >= b_solta + 0,5`, sorteia os Aprendizes e
  quem está fora, soma, e chama `_cortar(d)` ou `_bater_as_espadas()`. Marca `resolvida`.
- `_cortar(d)`: `cortes[d] += 1`, `cortes_somados[d] += 1`, `marcar_equipe(d, CORTE)`, o momento, o rastro, o
  risco, o impacto, o som e as sensações (A cena, O som, O controle). Na reta, sem `_reta_decidida`, leva a rodada
  3.
- `status(l)`: `"%d × %d" % [cortes[equipe[l]], cortes[1 - equipe[l]]]` quando `na_raia(l)`.
- `dica(l)`: `{"partes": ["@r2", "Solte no topo"]}`, só com `na_raia(l)` e `not aprendeu(l)`.

### O catálogo e as traduções

- No `catalogo.gd`: `Catalogo.MINIGAMES["S05_J24"] = preload("res://scripts/minigames/s05/espada_de_fita.gd")`, e
  `"S05_J24"` na lista `"minigames"` da seção `S05`, depois do `S05_J23`.
- O `.uid` novo: `espada_de_fita.gd.uid`, gerado com `"$GODOT" --headless --path godot --import --quit`.
- As traduções que ainda não existirem: `"Espada de Fita": "Tape Sword"`, `"Solte no topo!": "Release at the top!"`,
  `"Solte!": "Release!"`, `"Solte no topo": "Release at the top"`, `"Com o Aprendiz": "With the Apprentice"` e
  `"Você e o Aprendiz contra 2": "You and the Apprentice against 2"` (as duas da Q1).

### O registro

- **A `saida` de gatilho**, gravada pelo `Forja` (F06): `lado` `"R2"`, com `modo` `"resistencia"` e `params`
  `[2, f, 0]` (f em 1 a 6), `"vibracao"` com `[2, 6, 20]` ou `[2, 5, 20]` (o topo) e `"off"` (a fita
  arrebentada).
- **`entrada` `disparo`** na puxada e na soltura julgadas, o `toque` do kit, e `jogo` `corte` com a `dupla` e as
  `somas`.
- **A linha `momento`** por `CenarioDaGaleria.momento`: `corte` (o primeiro lugar da dupla que cortou) e `reta`
  (lugar −1).
- **O cruzamento:** com os degraus `ok`, a soltura no tempo diz que o peso contou as batidas. O mesmo lugar soltando
  cedo sempre, com o `curso_max` alto, é o Feedback que não pesou naquele controle.

### Armadilhas

- **A dupla é pelo `montar_equipes` do kit.** Quem cai não troca de dupla; a parte dele vira a de um Aprendiz.
- **A cor da dupla nunca vai para a barra de luz** (F04): ela fica no disco, na bandeira e no risco.
- **O peso é o relógio:** cada degrau sai na batida da tabela, pela `Ritmo.batida()`, e só quando muda (`_r2`).
- **A soltura só nasce com a puxada boa.** Senão a puxada errada viraria duas notas erradas.
- **A estocada se resolve uma vez.** O corte é em `b_solta + 0,5`, pelo relógio da música.
- **O L2 é do item.** A espada é só o R2.
- **Não declare `_notas`.** A fila é do kit (H08). O que é da Espada fica em `_info`.

## A cena

### A câmera

Plano fixo, `"camera": "fixa"`, sem corte do apito ao apito:
- posição `Vector3(0, 6.6, 10.4)`, olhando para `Vector3(0, 1.0, 0.6)`. A plongée é de 30°;
- lente de 35 mm (FOV vertical 37,8°).

O duelo cabe com folga: as vagas vão de x −2,2 a 2,2 e os carretéis a ±3,4. A 10 m, o quadro mostra ±6,1 m na
horizontal. O tremor vem de `CenarioDaGaleria.impacto`.

### A luz

A da M1, por `CenarioDaGaleria.montar(self)`: a névoa NEVOA `#18081c`, o preenchimento PREENCHIMENTO `#4a2854`
(energia 0,35), a chave CHAVE `#f8ccba` (energia 1,0) e o néon do mundo VIOLETA `#4a3aa8`.

- **O pico** (30 a 60 s): `CenarioDaGaleria.pico(self)` no primeiro quadro com `no_pico()`.
- **Nenhuma cor nova.** O `#3a2a24` e o `#4a4e5e` da ficha antiga saem: a fita é OXIDO e o carretel é GRAFITE.

### As peças

| peça | de onde | o papel | escala pedida |
| --- | --- | --- | --- |
| a espada | `mini-arena/weapon-sword`, por `peca_ou` dentro do nó da mão de `CenarioDaGaleria.arma_na_mao(p, NENHUMA)`; o substituto é `Kit.peca(pai, "weapon-sword", Vector3.ZERO, 0.0, 1.0)` | na mão direita | 1,0 (o boneco já está a `Kit.K`; 1,0 m no mundo) |
| o carretel | `Kit.cilindro` Ø 0,4 × 0,12 m, GRAFITE `#3a3346`, deitado | 1,2 m atrás da vaga, a 1,0 m do chão | — |
| a fita | `Kit.caixa` 0,04 × 0,12 × 1,0 m, OXIDO `#3b2a22`, fosca | da mão ao carretel, refeita a cada quadro: `scale.z` = a distância, `scale.y` de 1,0 a 0,5 com o degrau | — |
| o disco da dupla | `Kit.cilindro` Ø 1,4 × 0,02 m, `CORES_DAS_EQUIPES[e]`, fosco | sob os pés de cada um, e do Aprendiz | — |
| as bandeiras | `mini-arena/banner`, por `peca_ou`, tingida inteira na cor da dupla (`SalaProva._tingir`); o substituto é `Kit.peca(pai, "banner", Vector3.ZERO, 0.0, 2.0)` tingido igual | em (−5,0, 0, 1,0) a da Brasa e (5,0, 0, 1,0) a da Maré, viradas para a câmera | 2,0 (`Kit.K`; 2,0 m de altura) |
| a rodada ganha | `Kit.peca(pai, "shield-round", ...)` tingido na cor da dupla | em cima da bandeira, um por rodada, lado a lado a 0,5 m | 1,4 |
| o risco no chão | `Kit.caixa` 0,12 × 0,02 × 4,2 m na cor da dupla que cortou, fosca | na metade da dupla cortada, em (±1,1, 0,03, 1,0), girado 0,6 rad em `y`; cada risco novo 0,3 m mais à frente; até o fim da rodada | — |
| o Aprendiz | `Kit.peca(self, "character-human", vaga, rot, Kit.K)`, tingido de ETIQUETA_SOMBRA `#cfc2a0` pelo `SalaProva._tingir`, sem contorno | na vaga vazia da dupla, com espada, fita e carretel | 2,0 |

- **O pacote.** A Mini Arena é 1× do pacote, na escala dos bonecos (`FATOR` 1,0). Sem o pacote importado, o
  `peca_ou` põe o substituto.
- **A fita estica.** A cada degrau, o cavaleiro recua 0,12 m para o carretel em 1/4 de batida. Na soltura boa, ele
  avança 0,6 m em 1 colcheia (a estocada, com o gesto `attack-melee-right`) e volta em 1 batida. No topo, a fita
  treme ±0,02 m em `y`, a 20 Hz.
- **O corte:** o rastro diagonal `CenarioDaGaleria.rastro(self, de, ate, cor)` cruza a arena de (∓4,0, 3,5, 0,8)
  a (±4,0, 0,2, 0,8), da dupla que cortou para a cortada, na cor dela, chapado, e some em 0,12 s. Os dois da
  dupla cortada recuam `RECUO_M` e fazem `gesto("fall", 0.5)`.
- **As espadas batem:** 10 faíscas no meio, em (0, 1,4, 1,0).
- **Na pausa entre rodadas,** as fitas novas descem do carretel em 1 batida, e os riscos somem em 0,5 s.
- **O Aprendiz** toca `attack-melee-right` pelo `AnimationPlayer` dele (`find_child`) na soltura que acerta, e
  `emote-no` na que erra.

### O que brilha, e de quem é o brilho

| o quê | cor | emissivo | dono |
| --- | --- | --- | --- |
| a borda da raia | a cor do lugar | a do kit | o jogador |
| o rastro do corte | a cor da dupla que cortou | chapado, some em 0,12 s | a dupla |
| as faíscas | TUNGSTENIO `#ffd9a8` | chapadas | a forja |
| o néon do mundo | VIOLETA `#4a3aa8` | 3,0 hoje, 1,2 com a G15 | o mundo |

Nada mais brilha. A fita, o carretel, o disco, a bandeira, o escudo, o risco e o Aprendiz são foscos.

### O impacto

Por `CenarioDaGaleria.impacto` (a tabela da M1):
- o corte: `estrondo` no meio da dupla cortada, com `l` o primeiro lugar dela (ou −1): 50 faíscas, tremor 0,417
  por 2 batidas e o hit-stop de 50 ms;
- as espadas batem: `toque` (10 faíscas) no meio.

## O som

| evento | id do mapa | onde | como |
| --- | --- | --- | --- |
| a música | `mus_s05_j24` (142 bpm, Dó# menor, 150 s; arpejos neoclássicos, duelo; seca, sem cauda de reverberação) | TV | `"faixa": "MUS_S05_J24"`; sem a faixa (H05), a trilha sintetizada `"galeria"` a 104 bpm |
| cada degrau do peso | `tique_*` (ou `sint_tique`) | alto-falante do dono | `Som.no_controle(l, "tique", 0.35)` |
| a puxada e a soltura julgadas | `jul_ressonancia_p{n}`, `jul_afinado_p{n}`, `jul_quase_p{n}`, `jul_erro_p{n}` | TV e alto-falante | o kit (`_reagir`); a ficha não toca nada |
| o corte | `golpe_*` | TV | `Som.tocar("golpe", <o meio da dupla cortada>)` |
| o corte dado | `mod_coleta` | alto-falante dos dois da dupla que cortou | `Forja.som_falante(l, "coleta", 0.7)` |
| o corte levado | `golpe_*` | alto-falante dos dois da dupla cortada | `Som.no_controle(l, "golpe", 0.7)` |
| as espadas batem | `golpe_*` | TV | `Som.tocar("golpe", Vector3(0, 1.4, 1.0), -10.0)` |
| a fita não pega | `tique_*` | TV | `Som.tocar("tique", <o carretel>, -6.0)` |
| a falha | `fx_tropeco_*` | TV | o kit (H11); a ficha não toca nada |
| os carimbos | `car_em_chamas`, `car_acorde`, `jin_virada` (o carimbo `car_virada`), `car_por_um_fio` | TV | o kit e o HUD |

- **O alto-falante toca um som por vez**, na prioridade do kit: o julgamento, a coleta e o golpe, e o tique por
  último. O tique de cada degrau some quando outro toca.

## O controle

| recurso | evento | quem joga | os outros |
| --- | --- | --- | --- |
| **gatilho R2 (protagonista)** | da puxada boa ao topo | `GATILHO_RESISTENCIA` (2, f): f = 2, 4, 6 a cada batida; no pico 4, 6 a cada meia batida; a dupla leve com −1 | o mesmo, cada um no seu |
| gatilho R2 | o topo, até a soltura | `GATILHO_VIBRACAO` (2, 6, 20 Hz); a dupla leve com amplitude 5 | o mesmo |
| gatilho R2 | fora da estocada | `GATILHO_RESISTENCIA` (2, 1): a fita frouxa | o mesmo |
| gatilho R2 | a fita arrebenta | `GATILHO_OFF` por `queda_s(l, 1.0)`, e depois (2, 1) | nada |
| vibração | a puxada e a soltura julgadas | `acerto` (0,3/0,6, 80 ms), `perfeito` (0,5/0,8, 100 ms) ou `erro` (0,7/0,3, 160 ms), pelo kit | nada |
| vibração | o parceiro soltou PERFEITO | — | o parceiro sente `toque` (0/0,45, 60 ms) |
| vibração | o corte dado | `"golpe_dir"` na Brasa, `"golpe_esq"` na Maré (250 ms), nos dois da dupla | — |
| vibração | o corte levado | — | `Forja.sentir(l, "golpe")` (1,0/0,6, 250 ms) nos dois da dupla cortada |
| háptica | o toque julgado | a textura `"metal"`, pelo kit | nada |
| barra de luz | sempre | a cor do lugar, 100 %; o kit pisca branco no perfeito e escurece no erro | a cor de cada um |
| luzinhas | sempre | o número do lugar | o número de cada um |
| alto-falante | O som | o tique do degrau, a coleta e o golpe | nada |
| microfone | — | Não se aplica: a Espada não ouve | — |

O corte dado vem do lado para onde a espada corta: a Brasa corta para a direita, a Maré para a esquerda.

**A prova sem o controle na mão:**
- o robô joga pelo relógio da música, e a prova junta os bytes do modo (`Forja.percepcao(l)["gatilho_dir"]`:
  `0x21` o peso, `0x26` o topo);
- os `params` da `saida` no registro dizem os degraus, o topo e o Off.

## O cavaleiro

| stat | gancho | o que muda aqui |
| --- | --- | --- |
| Fôlego | `levantar` | o R2 sem peso depois da fita arrebentada: 1 batida × (1 − 0,125 × (Fôlego − 3)); Fôlego 1 dá 1,25 batida, e 5 dá 0,75 (`CenarioDaGaleria.queda_s(l, 1.0)`) |
| Faro | `pista` | a raia acende para a puxada 20 ms × (Faro − 3) antes; Faro 5 dá +40 ms, e 1 dá −40 ms (`pista_s`). O aviso é `acender_raia(l, 1.0)` em `t_da_batida(b − aviso_b()) − pista_s(l)`, e `0.15` na soltura |
| Peso | — | não muda nada |
| Passo | — | não muda nada |

- **Os itens são do kit:** o Martelo (pelo `marcar_equipe`, uma vez para a dupla), o Escudo (o primeiro erro), o
  Fole, o Diapasão e a Lanterna (somada pela `pista_s`).
- **A peça.** O cavaleiro fica de lado, virado para a outra dupla. O item da mão direita some enquanto a espada
  está na mão e volta no `sair()` (`CenarioDaGaleria.guardar_arma`). O Escudo e os amuletos ficam à vista. As cores
  da montagem não mudam nesta ficha.

## As reações

- **Nenhum adesivo.** Todos jogam todas as estocadas, e ninguém fica fora da rodada para mandar um.
- **Os carimbos são do kit e do HUD**, e esta ficha não chama nenhum: `car_em_chamas`, `car_acorde` (os quatro
  PERFEITO na mesma soltura), `car_virada` e `car_por_um_fio`.
- **O corte é a reação entre as duplas.** O rastro cruza a tela, a dupla cortada cai, e o risco fica no chão dela
  até a rodada acabar.

## A diversão

**O momento: `corte`**
- **Quando:** a janela é a faixa inteira (0 a 90 s), na mesa das duplas. A dupla que soltou mais no tempo corta a
  outra: o rastro cruza a tela em diagonal, os dois cortados recuam e caem, e o risco fica no chão. Degrau
  estrondo.
- **O que se vê:** a câmera treme 2 batidas, o cavaleiro cortado para 50 ms, e o chão da dupla cortada junta os
  riscos da rodada na cor de quem cortou.

**Como o jogador do time confere:**
- **No registro,** pelo robô na mesa das duplas (P1 `bom` e P2 `ruim` na Brasa, P3 e P4 `medio` na Maré), semente
  7:
  - pelo menos **4 linhas `momento` `corte`**, com lugares das duas duplas (a rodada fica aberta);
  - para cada uma, uma linha `sensacao` `golpe` de um lugar da dupla cortada a até 16,7 ms;
  - o `t_musica` de cada uma cai a até 1 quadro (16,7 ms) de uma colcheia.
- **Na prancha (F09):** há um risco no chão em pelo menos 1 quadro de cada 3.
- **A falha à vista:** o P2 (`ruim`) tem pelo menos 10 linhas `toque` com `erro` em 90 s. Em pelo menos 1 quadro de
  cada 5, há uma fita caída no chão.
- **Quem está perdendo:** a dupla que perdeu a rodada 1 tem as forças com −1 na rodada 2 (`params` `[2, 1, 0]`,
  `[2, 3, 0]` e `[2, 5, 0]` no registro).
- **Ninguém para:** a maior distância entre duas puxadas do mesmo lugar é de até 8 batidas.

Até o robô por lugar (`--robo=bom,ruim,medio,medio`, pedido ao arquiteto na régua) existir, a prova roda com o
`--robo` da `prova_do_jogo.sh` num temperamento só e confere o momento, o golpe no quadro e as `saida`; a
falha à vista (que pede o P2 `ruim`) espera o robô por lugar.

## Pronto quando

A Espada de Fita joga do aviso ao resultado:
- com 4, 3, 2 e 1 jogador (o Aprendiz completa), e com o robô nos três temperamentos;
- aguenta o cabo que cai no meio de uma estocada;
- fecha com a dupla na frente e a frase da equipe;
- abre o `S05_J24` com `--sala=S05_J24`;
- grava as linhas `momento` do corte e da reta.

A prova do jogo passa, e a prova visual passa com a prancha olhada.

### Ao terminar

- No [quadro](README.md), quem coordena marca a linha **M4** com o commit.
- Commit sugerido (sem trailer): `feat: Espada de Fita, o duelo em dupla com o peso que conta até o topo`.

## Provas

Os comandos: `SALA=S05_J24 bash tests/prova_do_jogo.sh` (o sh roda duas rodadas, sem bancada e com
`--bancada`), `bash tests/prova_do_jogo.sh` (o jogo inteiro) e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a prova entra como uma linha no `match` de `_prova_da_ficha` (o modelo
da H08):

```gdscript
		"S05_J24": await _prova_da_espada()
```

E acrescente a função abaixo, depois da prova da Metralhadora. O `_joga_o_minigame(slot, limite_s, a_cada_quadro)` é da H08.

```gdscript
# A Espada de Fita (S05_J24): as duplas do kit; o peso subiu em degraus no
# R2 e o topo zuniu; o corte grava o momento com a dupla; as rodadas não
# passam de três; a dupla na frente vem primeiro.
func _prova_da_espada() -> void:
	var modos := {}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			modos[int(Forja.percepcao(l).get("gatilho_dir", 0))] = true
	var mg = await _joga_o_minigame("S05_J24", 135.0, olhar)
	if mg == null:
		return
	var k := mg.presentes().size()
	_esperar(mg.da_equipe(Minigame.BRASA).size() + mg.da_equipe(Minigame.MARE).size() == k,
		"Espada: as duplas do kit têm todos os presentes")
	_esperar(modos.has(0x21) and modos.has(0x26), "Espada: o peso e o topo chegaram ao R2 (bytes: %s)" % [modos.keys()])
	var linhas := _linha_do_tempo()
	var gat := linhas.filter(func(e): return e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("lado") == "R2")
	var forcas := {}
	for e in gat.filter(func(e): return e.get("modo") == "resistencia"):
		forcas[int(e.get("params", [0, 0])[1])] = true
	_esperar(forcas.size() >= 3, "Espada: pelo menos três degraus de peso (%s)" % [forcas.keys()])
	var topos := gat.filter(func(e): return e.get("modo") == "vibracao")
	_esperar(not topos.is_empty() and topos.all(func(e): return e.get("params", []) in [[2, 6, 20], [2, 5, 20]]),
		"Espada: o topo é (2, 6, 20) ou (2, 5, 20)")
	var cortes := linhas.filter(func(e): return e.get("slot") == "S05_J24" and e.get("nome") == "corte"
		and (e.get("tipo") == "momento" or e.get("o") == "momento"))
	_esperar(not cortes.is_empty(), "Espada: houve corte (%d)" % cortes.size())
	_esperar(mg.rodadas[0] + mg.rodadas[1] <= 3, "Espada: no máximo três rodadas (%s)" % [mg.rodadas])
	var e := mg.equipe_vencedora()
	var v: Array = mg.vencedor()
	_esperar(e < 0 or v.is_empty() or mg.da_equipe(e).is_empty() or v[0] in mg.da_equipe(e),
		"Espada: a dupla na frente vem primeiro (%s)" % [v])
	var reta := linhas.filter(func(x): return x.get("slot") == "S05_J24" and x.get("nome") == "reta")
	_esperar(reta.size() <= 1, "Espada: no máximo uma linha momento reta (o 2 a 0 fecha antes)")
```

**Na prova visual** (`bash tests/prova_visual.sh`, F09), a Espada entra pela semente que o `Catalogo.sortear` da
H08 põe na noite (`--semente=N`). O jogador do time olha a prancha:
- um risco no chão na cor da dupla que cortou;
- um quadro com uma fita caída e o cavaleiro recuado;
- as bandeiras na cor das duplas, e a barra de luz de cada um na cor do lugar.

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J24`):
- os três degraus são distintos, e o zumbido do topo diz «agora»;
- dá para soltar no topo de olhos fechados;
- o toque do parceiro no perfeito dele se sente na mão;
- a fita leve da rodada seguinte se nota, sem tirar a janela.
