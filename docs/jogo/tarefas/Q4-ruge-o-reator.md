# Q4 — Ruge o Reator

**Sprint:** Q · **Slot:** S09_J44 · **Tamanho:** G · **Depende de:** Q1 (a seção no catálogo, o tipo `momento`), H04, H08, H07, F05 (`Forja.sentir`), F09 (`Forja.robo_acerta`), G03, G05, G13, G14, G15

## Por quê

O medley da primeira metade da noite: quatro estações de 24 s na mesma música (bater, equilibrar, traçar, defender),
o rugido do meio e um final em que os quatro verbos se revezam. Cada erro tira um pedaço da plataforma comum. A ficha
existe para que o rugido das batidas 100 a 107 derrube pelo menos 1 laje na mesa fraca e a mesa boa ainda chegue ao
fim com a plataforma em pé.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (onde mora, a FICHA, o robô, o registro, a prova)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) e, no mesmo arquivo, a seção «As decisões comuns dos
  minigames — H08» (a linha `estacao`, a `troca`)
- [A Q1, «Os ganchos»](Q1-a-prova.md#os-ganchos) (o `_gancho`, o `_respondeu`)

Tudo o mais que esta ficha usa (as cores, o brilho, a câmera, o movimento, o som, os stats, a régua da diversão)
está escrito aqui dentro, com o número. As mecânicas das estações estão escritas aqui no menor tamanho; o medley não
abre o minigame de origem.

As duas curvas do movimento (do 05): `ENTRA_SAI` é um `Tween` com `TRANS_SINE` e `EASE_IN_OUT`; `MOLA` é
`TRANS_BACK` com `EASE_OUT` (passa 4 % do alvo e volta).

## Arquivos que mudam

- `godot/scripts/minigames/s09/ruge_o_reator.gd` (novo, `extends Minigame`, sem `class_name`) e o `.uid`.
- `godot/scripts/minigames/catalogo.gd`: `"S09_J44"` em `MINIGAMES` e na lista da seção `S09`, depois do `S09_J43`.
  **De todos:** Q1, Q2, Q3 e Q5.
- `godot/scripts/traducoes.gd`: as frases da tabela «As frases». **De todos:** Q1, Q2, Q3 e Q5.
- `godot/testes/prova_do_jogo.gd`: `_prova_ruge_o_reator()` e a linha `"S09_J44": await _prova_ruge_o_reator()` no
  `match` de `_prova_da_ficha`. **De todos:** Q1, Q2, Q3 e Q5.

## Como se joga

**Aguente!** O dragão do reator acorda, e a plataforma dos quatro só aguenta se a turma aguentar. Uma batida de cada
vez, em roda: quem tem a batida faz o verbo da estação. Bater é ✕; equilibrar é inclinar o controle contra o balanço;
traçar é deslizar no touchpad para o lado da seta; defender é L1 ou R1 do lado que a mão sentiu.

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J44",
	"titulo": "Ruge o Reator",
	"verbo": "Aguente!",
	"genero": "coop",
	"icone": "botoes",
	"entradas": [Forja.CRUZ, Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S09_J44",
	"duracao": 0.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir", "explosao"],
	"material": "pedra",
	"microjogo": {"verbo": "Aguente!", "segundos": 7.0},
	"gesto": "attack-melee-right",
	"treino": false,
}
```

As entradas-botão são três (✕, L1, R1); o giroscópio e o touchpad entram fora da lista, uma estação cada. `duracao` é
0: o medley acaba pela batida 236 (118 s), para as quatro estações rodarem inteiras na prova. Sem treino: são
mecânicas que a noite já ensinou.

### O tempo

A faixa `MUS_S09_J44` tem 120 BPM: uma batida dura 0,5 s, a colcheia 0,25 s, a semicolcheia 0,125 s.

| trecho | batidas | segundos | o verbo |
| --- | --- | --- | --- |
| a contagem | 0 a 3 | 0 a 2 | o dragão abre um olho |
| 1. Bater (a bigorna da I1) | 4 a 51 | 2 a 26 | ✕ no tempo |
| 2. Equilibrar (a viga da J1) | 52 a 99 | 26 a 50 | incline contra o balanço |
| o rugido do meio | 100 a 107 | 50 a 54 | a 100 é o rugido; de 101 a 107, todos, um verbo por batida |
| 3. Traçar (o molde da K1) | 108 a 155 | 54 a 78 | deslize para o lado da seta |
| 4. Defender (as sentinelas da L1) | 156 a 203 | 78 a 102 | L1 ou R1 do lado que a mão sentiu |
| o final, «Aguentem!» | 204 a 235 | 102 a 118 | um verbo por compasso (bater, equilibrar, traçar, defender, duas voltas); a 235 é ✕ de todos |

| constante | valor | o que é |
| --- | --- | --- |
| `FIM` | 236 | a batida do fim |
| `INCLINA` | 0,35 rad | a rolagem que vale como inclinação |
| `TRACO` | 0,25 | o quanto o dedo anda no touchpad |
| `PONTOS` | `[0, 50, 75, 100]` | por nota; a 235 vale o dobro |
| `CUSTO_DE` | 0,35 | a plataforma cai se a turma errar 35 % das notas |
| `DOBRO_DE` | batida 220 (110 s) | as últimas 16 batidas: o erro tira o dobro |
| `ZERO_EM` | batidas 50 e 51 | o zero da rolagem de cada um |
| `LAJES` | 12 | a grade 4 × 3 |

### As regras

- **O hoqueto (nas estações):** a batida `x` de uma estação (contada do começo dela) é de `presentes()[(x - de) % np]`:
  com quatro, cada um toca uma vez por compasso; com dois, duas; com um, todas. Cada nota abre uma batida antes. Com
  `Ritmo.simples[l]`: uma nota dele sim, uma não.
- **O rugido do meio:** a batida 100 não tem nota (é o rugido, ver «O rugido (o momento)»). De 101 a 107, todos tocam
  todas, com o verbo `[BATER, EQUILIBRAR, TRACAR, DEFENDER][(x - 101) % 4]`.
- **O final:** o hoqueto volta, com o verbo `[BATER, EQUILIBRAR, TRACAR, DEFENDER][int((x - 204) / 4) % 4]`; a batida
  235 é de todos, ✕.
- **Bater:** ✕ no tempo → `julgar_toque(l, t(x), n)`. O cavaleiro bate na bigorna dele (`attack-melee-right`).
- **Equilibrar:** no começo de cada compasso da estação (e de cada compasso de equilibrar no final), o reator empurra
  a plataforma para um lado (`_lado_balanco` pelo `rng` do kit: 0 esquerda, 1 direita): a plataforma inclina 8° em
  1 batida, e todos sentem o empurrão em `t(x) - 0.25 - _gancho(l, "pista") / 1000.0`:
  `Forja.sentir(l, "golpe_esq" if lado == 0 else "golpe_dir", 150)`, com a linha `pista` (`canal` `rumble`, `o_que`
  o lado). Na nota dele, o jogador inclina o controle contra: o balanço para a esquerda pede a rolagem abaixo de
  `-INCLINA`, para a direita acima de `+INCLINA`. A rolagem é `Forja.postura(l).x - _zero[l]`. O aperto é o quadro em
  que ela cruza o limite do lado certo; cruzar o do lado errado, dentro da janela, é `nota_perdida`.
- **O zero da rolagem:** `_zero[l]` é a média da `Forja.postura(l).x` no primeiro quadro da batida 50 e no da batida
  51 (o fim da estação de bater, com o controle na mão parado). Quem entra depois da batida 51 usa 0.
- **Sem giroscópio** (`not Forja.capacidade(l, "giro")`): a gravidade,
  `-atan2(a.x, sqrt(a.y * a.y + a.z * a.z))` com `a = Forja.acel(l)`, com o zero do mesmo jeito; sem acelerômetro
  (`not Forja.capacidade(l, "acel")`), o analógico esquerdo além de ±0,6, sem zero. Uma `troca` por lugar, no
  `iniciar_jogo()`: `de` `giroscopio`, `para` `acelerometro` ou `analogico`, `motivo` `sem_giroscopio`.
- **Traçar:** na nota dele, a runa à frente do cavaleiro mostra uma seta (`_seta[l]` pelo `rng`: 0 esquerda, 1
  direita), acesa em `t(x) - 0.5 - _gancho(l, "pista") / 1000.0`. O aperto é o quadro em que o dedo 0, encostado
  (`Forja.dedo(l, 0).z > 0.5`), já andou `TRACO` na direção da seta desde onde tocou (`_dedo_de[l]`, guardado quando
  o `z` passa a 1); andar `TRACO` para o outro lado é `nota_perdida`.
- **Defender:** em `t(x) - 0.25 - _gancho(l, "pista") / 1000.0`, a sentinela anuncia o lado só na mão dele:
  `Forja.sentir(l, "golpe_esq" if lado == 0 else "golpe_dir", 150)` e a linha `pista` (`canal` `rumble`, `o_que` o
  lado). Na nota, L1 (esquerda) ou R1 (direita); o botão do lado errado é `nota_perdida`.
- **Uma estação, um gesto:** cada nota só olha a entrada do verbo dela; um aperto de outra coisa não é erro nem acerto.
- **A plataforma comum:** `_integridade` começa em 100. Cada erro (ERRO ou nota que passou) tira `_custo_erro`
  (2 × isso da batida 220 em diante); cada PERFEITO devolve `_custo_erro / 4`, até 100.
  `_custo_erro = 100.0 / (CUSTO_DE * _notas_previstas)`, com `_notas_previstas` contadas do roteiro no
  `iniciar_jogo()` com os presentes de então (com quatro, 255). A laje `i` cai quando
  `_integridade < 100 - 100 * (i + 1) / 13`; em 0, a plataforma cai (ver «A falha»).
- **A luz da plataforma:** a `light_energy` das `_tochas` (a chave, ver «A cena») vai a `energia_chave × (0.4 + 0.6 ×
  _integridade / 100)` em 1 batida a cada mudança: a sala vê a plataforma morrendo.
- **Pontos:** `PONTOS[j]` por nota com `marcar(l, ...)`; a batida 235 vale o dobro.
- **A curva:** as estações são a curva (24 s cada, o pico no meio, o final que gira os quatro). No primeiro quadro da
  batida 220 sai `anotar("momento", -1, {"nome": "reta", "lugar": -1, "t_musica": Ritmo.t_musica(), "objeto":
  {"integridade": _integridade}})`.
- **Ensina sem falar:** cada estação usa o objeto do minigame de origem (a bigorna, a viga, o molde, as sentinelas). O
  objeto da estação seguinte sobe da plataforma (y −0,5 → 0 com `ENTRA_SAI`) nas 4 batidas antes dela, e o da que
  acabou desce nas 2 batidas depois. No rugido, o objeto do verbo da batida aparece só naquela batida. A dica do kit
  mostra o glifo do verbo sempre (ver «Os ganchos»).

### O rugido (o momento)

No primeiro quadro da batida 100:

1. `anotar("momento", -1, {"nome": "rugido_do_meio", "lugar": -1, "t_musica": Ritmo.t_musica()})`;
2. `Forja.sentir(l, "explosao")` em todos os presentes, no mesmo quadro (ninguém tem nota na 100);
3. o degrau **catástrofe**: o dragão abre a mandíbula 30° em 1 batida e ergue a cabeça 0,6 m; os olhos vão de 1,0 a
   1,2; `tremer(TREMOR_CATASTROFE)` (0,08 m, 4 batidas, decai sozinho na câmera da G05); a `light_energy` das `_tochas`
   sobe 40 % por 1 batida; sem parada; a plataforma
   treme ±2° em `rotation.z` nas 4 batidas;
4. o rastro: as lajes que caírem de 100 a 107 ficam como buracos até o fim (toda laje caída fica, aliás).

Na batida 96 (um compasso antes), o prenúncio: `Som.tocar("grito", pos_da_cabeca, -12.0)` e os olhos a 1,1 por
1 batida.

Com `Opcoes.movimento == 1`: a câmera da G05 já não treme (a ficha chama `tremer` igual), e a ficha tira o balanço de
±2°.

### A falha

- **Um erro:** o cavaleiro faz `emote-no` em 0,3 s; a integridade desce; a plataforma treme (`tremer(TREMOR_GOLPE)`:
  0,02 m, 1 batida).
- **A laje cai** (quando a integridade passa do limite dela), na colcheia seguinte ao erro: anda `y` para −6 em 1
  batida com `ENTRA_SAI` e some; `Som.tocar("pedra", pos_da_laje, -4.0)`; `Forja.sentir(l, "golpe", 200)` em todos;
  `anotar("jogo", -1, {"o": "laje", "i": i, "batida": floor(b)})`. A ordem: a fileira da frente (z = 3) e a de trás
  (z = −1) primeiro, de fora para dentro (x −5,85, 5,85, −1,95, 1,95); a do meio (z = 1, sob as raias) por último.
- **A queda do cavaleiro:** a nota do lugar que cairia antes de `t_erro + _queda_s(l, verbo)` não abre (nem acerta nem
  erra), com `_queda_s = maxf(0.125, snappedf(tempos × 0.5 × _gancho(l, "levantar"), 0.125))` e `tempos` = 2 em
  bater e defender, 1 em equilibrar e traçar (os da I1, J1, K1 e L1).
- **A plataforma cai** (integridade 0): as lajes restantes caem juntas, os quatro fazem `fall` e descem 2 m, os olhos
  vão a 1,2 e o dragão ruge (`Som.tocar("grito", pos_da_cabeca, 0.0)`); `Forja.sentir(l, "explosao")` em todos;
  `_fim_batida = ceilf(Ritmo.batida() / 4.0) * 4.0 + 4.0` (um compasso depois).

### O fim e o vencedor

O `coop` vem do gênero da FICHA (H08). Na batida 236 com a plataforma em pé: `coop_venceu = true`, o dragão fecha os
olhos (energia 0 em 2 batidas) e cai para trás 70° em 2 batidas, com 48 faíscas
`Efeitos.faiscas(self, pos_da_cabeca, Tema.TUNGSTENIO, 48, 1.0)`. Se a plataforma caiu antes: `coop_venceu = false`.
Nos dois casos, todos acabam. O registro grava `vencedor` −1 (coop); `destaque()`: quem errou menos (`_erros[l]`),
depois mais pontos.

### Com menos de quatro

| jogadores | o que muda | `com_poucos()` |
| --- | --- | --- |
| 3 | o hoqueto reparte por três | `""` |
| 2 | cada um toca duas batidas por compasso | `""` |
| 1 | ele toca todas | `""` |

`_notas_previstas` usa os presentes do começo, e o `_custo_erro` fica justo para qualquer número. Sem Aprendiz: o
coop é de quem joga.

**O controle que cai:** as notas dele não abrem (nem erram); a batida dele fica vazia, e a plataforma não sofre por
ela. Volta na próxima nota dele.

### O robô

Um ramo por verbo, sempre pelo controle simulado, mirando pelo relógio; no defender ele sente o lado nos motores (a
`percepcao`); no equilibrar, também sente o empurrão do balanço.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	_robo_sentir(l)                         # o lado do balanço e da sentinela, pela percepcao
	var n: int = _nota[l]
	if n < 0:
		_robo_voltar(l)                     # a rolagem volta ao meio, o dedo solta
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_certo[l] = Forja.robo_acerta()
		_robo_mira[l] = 0.0 if _robo_certo[l] else 0.25
		_robo_feito[l] = false
	var quando := float(_alvo[l]) + float(_robo_mira[l])
	if _robo_feito[l] or Ritmo.t_musica() < quando - _antecipa(_verbo[l]):
		return
	match _verbo[l]:
		BATER:
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
			_robo_feito[l] = true
		EQUILIBRAR:
			var sinal := (1.0 if _robo_balanco[l] == 0 else -1.0) * (1.0 if _robo_certo[l] else -1.0)
			Forja.robo_girar(l, Vector3(0, 0, -6.0 * sinal), 0.06)
			if absf(Forja.postura(l).x - _zero[l]) > INCLINA + 0.05:
				_robo_feito[l] = true
		TRACAR:
			var dx := (1.0 if _seta[l] == 1 else -1.0) * (1.0 if _robo_certo[l] else -1.0)
			_robo_x[l] = clampf(float(_robo_x[l]) + dx * 0.05, 0.1, 0.9)
			Forja.robo_tocar(l, 0, float(_robo_x[l]), 0.5, 0.06)
			if absf(float(_robo_x[l]) - 0.5) > TRACO + 0.05:
				_robo_feito[l] = true
		DEFENDER:
			var lado: int = _robo_lado[l] if _robo_certo[l] else 1 - int(_robo_lado[l])
			Forja.robo_apertar(l, Forja.L1 if lado == 0 else Forja.R1, 0.05)
			_robo_feito[l] = true


func _robo_sentir(l: int) -> void:
	var pc := Forja.percepcao(l)
	var forte := float(pc.get("forte", 0.0))
	var fraco := float(pc.get("fraco", 0.0))
	var lado := 0 if forte > 0.5 and fraco < 0.1 else (1 if fraco > 0.5 and forte < 0.1 else -1)
	if lado < 0:
		return
	if _verbo_aberto_ou_proximo(l) == DEFENDER:
		_robo_lado[l] = lado
	else:
		_robo_balanco[l] = lado
```

`_antecipa(verbo)`: 0 para bater e defender; 0,06 s para equilibrar e traçar (o gesto leva uns quadros para cruzar o
limite). `_robo_voltar(l)`: `Forja.robo_girar(l, Vector3(0, 0, -2.5 * (Forja.postura(l).x - _zero[l])), 0.06)` e
`_robo_x[l] = 0.5`, sem `robo_tocar`. O robô sem pista sentida aposta no lado 0 e erra metade, como gente.

### Os ganchos

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

`godot/scripts/minigames/s09/ruge_o_reator.gd`:

```gdscript
extends Minigame
## Ruge o Reator (S09_J44). O dragão acorda. Quatro estações de 24 s sem
## pausa: bater (✕), equilibrar (incline contra o balanço), traçar (deslize
## no touchpad para a seta), defender (L1/R1 do lado que a mão sentiu); o
## rugido do meio; o final, um verbo por compasso. Cada erro tira um pedaço
## da plataforma comum.
##
## A falha: a laje cai; em zero, a plataforma inteira. O vencedor: coop (a
## plataforma aguenta); o destaque é quem errou menos. O alto-falante do dono:
## a coleta a cada estação. O registro mede: cada estação (estacao), o desvio
## de cada recurso nela (toque), o rugido (momento), as lajes (jogo laje).
## O robô: um ramo por verbo, pelo controle simulado.
## Com menos de quatro: o hoqueto reparte. A régua: o objeto de cada estação
## é o do minigame de origem; nada pergunta nada.

const FICHA := { ... }   # a de «A ficha de dados»
enum { BATER, EQUILIBRAR, TRACAR, DEFENDER }
const ROTEIRO := [
	{"de": 4, "ate": 52, "verbo": BATER, "nome": "bater"},
	{"de": 52, "ate": 100, "verbo": EQUILIBRAR, "nome": "equilibrar"},
	{"de": 100, "ate": 108, "verbo": -1, "nome": "rugido"},   # a 100 sem nota; 101 a 107 todos, o verbo por batida
	{"de": 108, "ate": 156, "verbo": TRACAR, "nome": "tracar"},
	{"de": 156, "ate": 204, "verbo": DEFENDER, "nome": "defender"},
	{"de": 204, "ate": 236, "verbo": -2, "nome": "final"},    # o verbo por compasso; a 235 de todos
]
const QUEDA_TEMPOS := [2, 1, 1, 2]    # bater (I1), equilibrar (J1), traçar (K1), defender (L1)
# as constantes de «O tempo»
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}

var _trecho := -1
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _verbo := [BATER, BATER, BATER, BATER]
var _n := [0, 0, 0, 0]
var _feita := -1.0                    ## a última batida já distribuída
var _lado_balanco := 0
var _lado_garra := [0, 0, 0, 0]
var _seta := [0, 0, 0, 0]
var _dedo_de := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _zero := [0.0, 0.0, 0.0, 0.0]
var _zero_amostras := [[], [], [], []]
var _modo_inclina := ["giro", "giro", "giro", "giro"]   ## giro, acel ou analogico
var _integridade := 100.0
var _custo_erro := 1.0
var _lajes_caidas := 0
var _erros := [0, 0, 0, 0]
var _sem_nota_ate := [-1.0, -1.0, -1.0, -1.0]
var _caiu := false
var _fim_batida := 236.0
var _nos := {}
var _robo_nota := [-1, -1, -1, -1]
var _robo_certo := [true, true, true, true]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_feito := [false, false, false, false]
var _robo_lado := [0, 0, 0, 0]
var _robo_balanco := [0, 0, 0, 0]
var _robo_x := [0.5, 0.5, 0.5, 0.5]


func montar() -> void:
	camera_pos = Vector3(0, 17.10, 13.07)   # a G05 recua ×1,0616 a 35 mm: a câmera fica em (0, 18, 14)
	camera_olhar = Vector3(0, 2.5, -2.0)
	_montar_cena()                     # «A cena»
	for l in presentes():
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	_custo_erro = 100.0 / (CUSTO_DE * maxf(1.0, float(_contar_notas())))
	for l in presentes():
		if not Forja.capacidade(l, "giro"):
			_modo_inclina[l] = "acel" if Forja.capacidade(l, "acel") else "analogico"
			anotar("troca", l, {"de": "giroscopio", "para": "acelerometro" if _modo_inclina[l] == "acel" else "analogico", "motivo": "sem_giroscopio"})


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	_trocar_trecho(b)                  # a estação nova: os objetos, a coleta, a TV, a linha estacao
	_rugido(b)                         # o prenúncio na 96; o momento na 100
	_zero_da_rolagem(b)                # as amostras das batidas 50 e 51
	_distribuir(b)                     # uma batida antes de cada batida: quem toca, com que verbo; nova_nota
	_pistas(b)                         # o empurrão do balanço (todos) e a sentinela (só o dono), na hora
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_entrada(l)                    # o gesto do verbo da nota aberta; julgar_toque ou nota_perdida
		_prazo(l)                      # a nota que passou
	_reta(b)                           # o momento reta na 220
	_luz_da_plataforma()
	if b >= _fim_batida:
		coop_venceu = not _caiu
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j] * (2 if _alvo_batida(l) == 235 else 1))
	if j == Ritmo.PERFEITO:
		_integridade = minf(100.0, _integridade + _custo_erro / 4.0)
	_gesto_do_verbo(l)                 # a bigorna, a inclinação, o traço, o escudo


func falha(l: int) -> void:
	_erros[l] += 1
	jogador(l).gesto("emote-no", 0.3)
	_sem_nota_ate[l] = Ritmo.t_musica() + _queda_s(l, _verbo[l])
	_integridade -= _custo_erro * (2.0 if Ritmo.batida() >= DOBRO_DE else 1.0)
	_derrubar_lajes()                  # as que passaram do limite, na colcheia seguinte
	if _integridade <= 0.0 and not _caiu:
		_caiu = true
		_fim_batida = ceilf(Ritmo.batida() / 4.0) * 4.0 + 4.0
		_a_plataforma_cai()


func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return _erros[a] < _erros[b] or (_erros[a] == _erros[b] and pontos[a] > pontos[b]))
	return int(lista[0]) if not lista.is_empty() else -1


func _queda_s(l: int, verbo: int) -> float:
	return maxf(0.125, snappedf(QUEDA_TEMPOS[verbo] * 0.5 * _gancho(l, "levantar"), 0.125))


func _gancho(l: int, nome: String) -> float:
	return float(NEUTRO[nome])   # troque por Cavaleiro.gancho(l, nome) quando `grep -rn "static func gancho" godot/scripts/` achar
```

As outras funções, uma frase cada:

- `_distribuir(b)`: para a batida `x = floor(b) + 1` (uma vez cada, `_feita`), o dono e o verbo pelas regras do
  hoqueto, do rugido e do final; nenhuma nota na 100 nem antes de `_sem_nota_ate[l]`; `_nota[l] = _n[l]`, `_n[l] += 1`,
  `_verbo[l]`, `_alvo[l] = t(x)`, `nova_nota`; no traçar, `_seta[l]` pelo `rng`; no defender, `_lado_garra[l]` pelo
  `rng`.
- `_pistas(b)`: na hora certa de cada pista (as de «As regras»), uma vez; no equilibrar, `_lado_balanco` pelo `rng` a
  cada compasso.
- `_entrada(l)`: pelo verbo: `BATER`, `Forja.apertou(l, Forja.CRUZ)`; `EQUILIBRAR`, a inclinação (pelo
  `_modo_inclina[l]`) cruzou o limite; `TRACAR`, o dedo andou `TRACO`; `DEFENDER`, L1 ou R1. O certo julga; o errado
  é `nota_perdida`.
- `_trocar_trecho(b)`: no primeiro quadro de cada trecho, `anotar("estacao", -1, {"nome": nome, "evento": "comecou",
  "batida": de})`, `Som.tocar("transicao")`, `Forja.som_falante(l, "coleta", 0.7)` em todos.
- `_contar_notas()`: percorre o roteiro com os `presentes()` de agora e conta.
- A dica, com `na_raia(l)`, sempre (é um medley): `["@cross"]`, `["@giroscopio"]` (ou `["@acelerometro"]`,
  `["@stick_l"]` pelo `_modo_inclina`), `["@touchpad"]`, `["@l1", "@r1"]`, pelo verbo da nota aberta.
- `progresso()`: `"Bata!"`, `"Incline!"`, `"Trace!"`, `"Defenda!"`, `"Aguentem!"` no final. `status(l)`:
  `"%d erros" % _erros[l]`.

### A casa nova e o catálogo

1. Criar o script; `"$GODOT" --headless --path godot --import --quit`; commitar o `.uid`.
2. `catalogo.gd`: `"S09_J44": preload("res://scripts/minigames/s09/ruge_o_reator.gd")` em `MINIGAMES`; `"S09_J44"`
   na lista da seção `S09`, depois do `S09_J43`.

### As frases

| português | inglês |
| --- | --- |
| Ruge o Reator | The Reactor Roars |
| Aguente! | Hold on! |
| Aguentem! | Hold on, all of you! |
| Incline! | Tilt! |
| Trace! | Swipe! |
| Defenda! | Defend! |
| %d erros | %d misses |

`"Bata!"` já veio da H04.

### O registro

- `estacao` a cada trecho (`bater`, `equilibrar`, `rugido`, `tracar`, `defender`, `final`): a noite separa o desvio
  de cada recurso por controle no fim da noite e compara com as seções de origem;
- `pista` do balanço (todos) e da sentinela (só o dono), `canal` `rumble`, `o_que` `esquerda` ou `direita`; a
  `entrada` `resposta`;
- `troca` de quem não tem giroscópio;
- `momento` `rugido_do_meio` e `reta`; `jogo` `laje`; `sensacao` `explosao`, `golpe`, `golpe_esq`, `golpe_dir`;
- `nota` e `toque` de cada verbo (o kit).

### Armadilhas

- **O giroscópio do robô** é o simulado: `robo_girar` muda a velocidade, e a `postura` integra. Espere a rolagem
  voltar ao meio entre as notas (`_robo_voltar`), senão a nota seguinte já nasce cruzada.
- **O traço mede do ponto em que o dedo tocou**, não do centro.
- **Rumble e háptica nunca juntos:** o empurrão e a sentinela saem uma colcheia antes da nota (150 ms, acabam 100 ms
  antes do acerto); a laje cai na colcheia seguinte ao erro com 200 ms; o rugido cai na 100, sem nota.
- **A prova fica mais longa** (118 s de relógio): a checagem do medley roda só na rodada sem a bancada.

## A cena

- **A câmera:** a arena (35 mm, plongée de 44,1°, nunca corta). `camera_pos = Vector3(0, 17.10, 13.07)`,
  `camera_olhar = Vector3(0, 2.5, -2.0)`. No modo `"fixa"`, a G05 recua a câmera por `Lente.recuo(35)` = 1,0616 a
  partir do olhar: `olhar + (camera_pos − olhar) × 1,0616` = (0, 18,0, 14,0), que é onde se mediu. Medido por projeção com 37,8° vertical e 16:9: a cabeça do dragão
  (0, 4,6 a 6,2, −5) cai em x 0,50 e y de 0,27 a 0,18 (`altura_tela` 0,088); o pé do dragão em y 0,45; as quinas da
  frente da plataforma (±7,8, 0,3, 4) em x 0,17 e 0,83, y 0,93; as de trás (±7,8, 0,3, −2) em x 0,23 e 0,77, y 0,60.
  Sem `camera_foco` (a plataforma é de todos).
- **A luz** (S9): a ficha não chama `Tema.luz_da_secao`. A entrada da sala chama `acender(9, partida.lado() == "B")` (G15 e
  G16): no lado A, densidade 0,012 e energia da chave 1,8; no lado B, 0,0156 e 1,53. A chave são as tochas de `luzes()`:
  o `Sala.acender(luz)` as pinta. Logo depois do `luzes(...)`, a ficha guarda em `_tochas` os `OmniLight3D` filhos da
  sala, menos o enchimento de cima, em (0, 9, 2). Quando a ficha mexe na chave, multiplica a `light_energy` das `_tochas`
  sobre a `energia_chave` que a G15 pôs. O preenchimento é `environment.ambient_light_energy` (0,42 pela G15) e a névoa
  é `environment.fog_density`, com `var environment := get_viewport().find_world_3d().environment`; os dois voltam ao
  valor de antes. As tochas: `luzes([Vector3(-9, 3, 3), Vector3(9, 3, 3)])`. A chave segue a integridade
  (ver «As regras»); no rugido, +40 % por 1 batida.
- **O dragão do reator** (peças do kit mais um brilho), no fundo, em `(0, 0, -6.0)`:
  - o corpo: três `Kit.peca(self, "wall", Vector3(0, 1.6 * k, -7.0), 0.0, 1.6)` empilhadas (k de 0 a 2);
  - o pescoço: duas `Kit.peca(self, "column", Vector3(±0.6, 3.2, -5.6), 0.0, 1.2)`;
  - a cabeça: `Kit.caixa(self, Vector3(3.0, 1.6, 2.0), Vector3(0, 5.4, -5.0), Kit.material(Tema.OXIDO, 0.0, 0.9))`;
  - a mandíbula: `Kit.caixa(cabeca, Vector3(2.6, 0.5, 1.8), Vector3(0, -1.0, 0.1), Kit.material(Tema.OXIDO, 0.0, 0.9))`,
    que abre 30° no rugido e fecha em 4 batidas;
  - os olhos: `Kit.caixa(cabeca, Vector3(0.4, 0.2, 0.1), Vector3(±0.7, 0.2, 1.02), mat)` com
    `Tema.neon(Tema.VIOLETA, 1.0, "mundo")`; 1,1 no prenúncio, 1,2 no rugido e na plataforma que cai, 0 no fim
    aguentado;
  - os espinhos: três `Kit.peca(self, "stairs", Vector3(0, 4.8, -7.2 - 0.8 * k), 0.0, 0.8)`;
  - a respiração: a cabeça sobe e desce 0,1 m por compasso, pela batida.
- **A plataforma:** um `Node3D` `_plataforma` que inclina (`rotation.z`, 8° no balanço, pela batida); 12 lajes
  `Kit.caixa(_plataforma, Vector3(3.8, 0.3, 1.9), Vector3(x, 0.15, z), Kit.material(Tema.GRAFITE, 0.0, 0.9))` com
  x em −5,85, −1,95, 1,95, 5,85 e z em −1, 1, 3. As raias do kit (`raia(l)`) vão para dentro de `_plataforma`
  (`reparent`) a y 0,3, e `posicionar(l)` põe cada cavaleiro em `(RAIAS[l], 0.3, Z_JOGADOR)`, de frente para o dragão
  (`rotation.y = PI`).
- **Os objetos das estações** (de cada raia, visíveis na estação deles):
  - bater: `Kit.bigorna(self, Vector3(RAIAS[l], 0.3, Z_JOGADOR - 1.2))`, com a runa do dono
    `Kit.caixa(bigorna, Vector3(0.5, 0.04, 0.3), Vector3(0, 0.62, 0), mat)` que acende em
    `t(x) - 0.5 - pista / 1000` com `Tema.neon(Tema.JOGADOR[l], 2.0, l)` e apaga depois da nota;
  - equilibrar: a viga sob os pés, `Kit.caixa(_plataforma, Vector3(3.2, 0.2, 0.4), Vector3(RAIAS[l], 0.4, Z_JOGADOR), Kit.material(Tema.GRAFITE, 0.0, 0.9))`;
  - traçar: o molde, `Kit.caixa(self, Vector3(0.8, 0.05, 0.5), Vector3(RAIAS[l], 0.35, Z_JOGADOR - 1.2), Kit.material(Tema.GRAFITE, 0.0, 0.9))`,
    com a seta (duas `Kit.caixa` de 0,3 × 0,05 × 0,1 a ±45°) que acende na cor do dono a 2,0;
  - defender: as sentinelas da L1, `Kit.peca(self, "column", Vector3(RAIAS[l] ± 1.35, 0.3, Z_JOGADOR - 1.45), 0.0, 1.35)`;
    na nota, a do lado anunciado tomba 25° para o cavaleiro em meia batida e volta com `MOLA`.
- **O equilibrar no cavaleiro:** no empurrão, o cavaleiro escorrega `0.4 × _gancho(l, "empurrao")` m para o lado do
  balanço em 1 batida e volta à raia em `0.5 / _gancho(l, "velocidade")` s.
- **O defender no cavaleiro:** no erro, ele cambaleia `0.6 × _gancho(l, "empurrao")` m para trás em 1 colcheia e
  volta com `MOLA`.
- **Os brilhos e os donos:**

  | o quê | dono | energia |
  | --- | --- | --- |
  | o contorno de cada cavaleiro | o lugar | 2,4 |
  | o acento da peça (friso, costura, runa do item) | o lugar | 1,6 (o da G13) |
  | a runa da bigorna, a seta do molde | o lugar | 2,0 na nota dele; 0 fora |
  | os olhos do dragão | `"mundo"` | 1,0; 1,1 no prenúncio; 1,2 no rugido |
  | as faíscas do fim | `"forja"` | 1,0 por 12 quadros |
  | as lajes, a viga, o molde, as sentinelas, o dragão | ninguém | 0 (impressos) |

- **O que sai:** o `Kit.arena`, a `atmosfera` com `Tema.VERMELHO`, e as cores escritas à mão da ficha antiga (a pedra
  escura, a pedra da plataforma, os olhos, a runa da seta, as faíscas do fim): nenhum `Color("#...")` no script.

## O som

| quando | onde | id do mapa | como |
| --- | --- | --- | --- |
| a partida | TV | `mus_s09_j44` (120 BPM, Ré menor; reserva `sint_trilha`) | a FICHA, `"faixa": "MUS_S09_J44"` |
| a troca de estação | TV; controle de todos | `transicao_0`/`1`; `mod_coleta` | `Som.tocar("transicao")`; `Forja.som_falante(l, "coleta", 0.7)` |
| o acerto do bater | TV | `martelo_0` a `martelo_4` | `Som.tocar("martelo", pos_da_bigorna, -6.0)` |
| o empurrão do balanço | TV | `sint_vento` | `Som.tocar("vento", Vector3.ZERO, -8.0)` |
| o acerto do defender | TV | `escudo_0` a `escudo_4` | `Som.tocar("escudo", pos_da_sentinela, -4.0)` |
| o prenúncio (batida 96) | TV | `sint_grito` | `Som.tocar("grito", pos_da_cabeca, -12.0)` |
| o rugido (batida 100), a plataforma que cai | TV | `sint_grito` | `Som.tocar("grito", pos_da_cabeca, 0.0)` |
| a laje cai | TV | `pedra_0` a `pedra_4` | `Som.tocar("pedra", pos_da_laje, -4.0)` |
| a textura do acerto | atuadores do dono | `mod_material_pedra` | o kit (`"material": "pedra"`) |
| a nota do perfeito, a quebrada do erro | controle do dono | `mod_nota_p1..p4`, `mod_nota_quebrada_p1..p4` | o kit |
| o apito, a vitória coop | TV | `jin_apito`; `jin_coop_vitoria` (reserva `vitoria_noite_0`) | o kit |

O alto-falante toca um som por vez: vitória > julgamento > segredo > pio > coleta > clique. A coleta da troca cai no
primeiro quadro do trecho, uma batida antes da primeira nota dele.

## O controle

| evento | quem tem a nota | os outros | prova sem a mão |
| --- | --- | --- | --- |
| bater | ✕; a textura `pedra` no acerto | nada | linha `toque` com verbo bater julgada |
| equilibrar | o giroscópio (ou a gravidade, ou o analógico); o empurrão `golpe_esq`/`golpe_dir` de 150 ms uma colcheia antes | o mesmo empurrão | o robô gira pelo `robo_girar` e tem toque julgado; `percepcao(l).forte > 0.5` com o balanço à esquerda |
| traçar | o touchpad, dedo 0 | nada | o robô desliza pelo `robo_tocar` e tem toque julgado |
| defender | L1 ou R1; o lado no motor uma colcheia antes, só nele | nada | `percepcao(dono)` com um motor > 0,5 e o outro < 0,1; nos outros, os dois < 0,1 no mesmo quadro |
| a troca de estação | `mod_coleta` 0,7 no alto-falante | o mesmo | `som_virtual(l).falante > 0.05` no quadro da troca, em todos |
| o rugido | `explosao` (1,0/1,0/400) em todos | — | linha `sensacao` `explosao` de cada lugar a até 16,7 ms do `momento` |
| a laje cai | `golpe` de 200 ms em todos | — | linha `sensacao` `golpe` depois de cada linha `jogo` `laje` |
| os gatilhos | soltos a partida inteira | o mesmo | `percepcao(l).gatilho_esq == 0x05` e `gatilho_dir == 0x05` |
| a barra de luz | a cor do lugar, sempre | o mesmo | `percepcao(l).luz` na cor do lugar em ≥ 75 % das amostras |
| as luzinhas | o número do jogador, sempre | o mesmo | `leds_jogador == Forja.LEDS_DO_LUGAR[l]` |
| o microfone | Não se aplica: o medley junta as estações da primeira metade, e nenhuma delas usa a voz | — | — |

**No rádio:** nada muda; as pistas desta ficha já são rumble, e a textura vira rumble pelo kit. **Sem giroscópio:** a
troca de «As regras».

## O cavaleiro

- **Os stats** (`minigames.csv`, linha 44: «como no minigame de origem de cada trecho»). Cada verbo usa os ganchos do
  minigame de origem, também no rugido e no final:

  | verbo (origem) | ganchos | o que muda aqui |
  | --- | --- | --- |
  | bater (I1) | levantar, pista | a queda de 2 tempos × `levantar` (1,25 s a 0,75 s); a runa da bigorna acende `pista` antes (−40 a +40 ms) |
  | equilibrar (J1) | empurrao, velocidade, levantar, pista | o escorregão de 0,4 m × `empurrao` (0,46 m a 0,34 m); a volta em 0,5 s / `velocidade` (0,53 s a 0,47 s); a queda de 1 tempo × `levantar` (0,625 s a 0,375 s); o empurrão chega `pista` antes |
  | traçar (K1) | levantar, pista | a queda de 1 tempo × `levantar`; a seta acende `pista` antes |
  | defender (L1) | empurrao, levantar, pista | o cambaleio de 0,6 m × `empurrao` (0,70 m a 0,50 m); a queda de 2 tempos × `levantar`; a sentinela avisa `pista` antes |

  Os fatores: `empurrao` ×1,16 a ×0,84, `velocidade` ×0,94 a ×1,06, `levantar` ×1,25 a ×0,75, `pista` −40 a +40 ms,
  do stat 1 ao 5. Nenhum stat mexe na janela de julgamento, na integridade nem nos pontos.
- **A conta:** `_gancho(l, nome)` devolve o neutro até existir `Cavaleiro.gancho`.
- **Como aparece:** o cavaleiro entra como a G13 o montou (a raça, a cabeça, o superior em tecido L 0,46 a 0,58, o
  inferior em couro L 0,22 a 0,36), sem tinta do minigame. O néon do dono é o friso e a costura a 1,6 e o contorno a
  2,4. A raça não muda a cápsula, a velocidade nem a janela.
- **O item:** fica onde a G13 o pôs; no bater, quem não tem martelo recebe `martelo_na_mao(p)` só na estação de bater e
  nos compassos de bater do final; o Escudo no braço esquerdo levanta no acerto do defender.

## As reações

- **Adesivo:** nenhum durante o jogo; todos jogam a partida inteira.
- **Os carimbos que este minigame pode disparar** (o jogo detecta pelo registro):

  | carimbo | o evento aqui | onde |
  | --- | --- | --- |
  | `car_acorde` | os quatro com PERFEITO na mesma batida de tempo 1 (`b % 4 == 0`): só a 104 tem nota de todos no tempo 1 (o defender do rugido); a 235 é tempo 4 | centro da tela, y 300 |
  | `car_em_chamas` | 5 PERFEITOs seguidos do mesmo lugar | acima da cabeça dele |

  Quando dois disputam a vez: `car_acorde` > `car_em_chamas`. O `car_por_um_fio` não sai: é coop.

## A diversão

**O grito: o rugido do meio** (`rugido_do_meio`). Na batida 100, o dragão ruge; de 101 a 107, os quatro verbos vêm um
por batida para todos, e a sala grita o nome do verbo. Degrau catástrofe.

- **O grito acontece no meio da tela:** a cabeça do dragão cai em `x_tela` 0,50, com `altura_tela` 0,088.
- **Rastro:** as lajes que caem ficam como buracos até o fim.
- **Quem está perdendo:** é coop; a plataforma é de todos, e a luz conta quanto falta.
- **Como o jogador do time confere:**
  1. mesa boa (os quatro `bom`, semente 7): 1 linha `momento` `rugido_do_meio` com `t_musica` 50,0 s (a até 1
     quadro), e `coop_venceu` no fim;
  2. mesa fraca (os quatro `medio`, semente 7): pelo menos 1 linha `jogo` `laje` com `batida` de 100 a 107;
  3. cada `momento` `rugido_do_meio` tem uma `sensacao` `explosao` de cada lugar a até 16,7 ms;
  4. na prancha da mesa fraca, buracos na plataforma no quadro seguinte ao rugido.

## Pronto quando

O `S09_J44` joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o `ruim` derruba a
plataforma, o `bom` a segura), aguenta o cabo que cai e volta, passa pelas quatro estações, o rugido e o final sem
pausa na música, fecha com o resultado coop e o destaque, faz o rugido na batida 100, e não tem nenhuma cor escrita à
mão; as provas abaixo passam e a prancha foi olhada.

## Provas

Em `godot/testes/prova_do_jogo.gd`, com a linha `"S09_J44": await _prova_ruge_o_reator()` no `match` de
`_prova_da_ficha(slot)`, chamada só na rodada sem a bancada (`if not Forja.bancada:`):

```gdscript
## S09_J44: acertos nas quatro estações pelo controle simulado; o lado da
## sentinela só no motor do dono; os gatilhos soltos; o fim coop.
func _prova_ruge_o_reator() -> void:
	var conta := {"verbos": {}, "antes": [0, 0, 0, 0], "lado_so_no_dono": false, "gatilho_preso": false}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if mg.pontos[l] != conta.antes[l]:
				conta.antes[l] = mg.pontos[l]
				conta.verbos[mg._verbo[l]] = true
			var p := Forja.percepcao(l)
			if int(p.get("gatilho_dir", 0x05)) != 0x05 or int(p.get("gatilho_esq", 0x05)) != 0x05:
				conta.gatilho_preso = true
			if mg._verbo[l] == mg.DEFENDER and mg._nota[l] >= 0:
				var um := maxf(float(p.get("forte", 0.0)), float(p.get("fraco", 0.0))) > 0.5
				var outros_quietos := true
				for o in mg.presentes():
					if o != l and mg._nota[o] < 0:
						var q := Forja.percepcao(o)
						outros_quietos = outros_quietos and float(q.get("forte", 0.0)) < 0.1 and float(q.get("fraco", 0.0)) < 0.1
				conta.lado_so_no_dono = conta.lado_so_no_dono or (um and outros_quietos)
	var mg := await _joga_o_minigame("S09_J44", 150.0, olhar)
	if mg == null:
		return
	_esperar(conta.verbos.size() == 4, "S09_J44: acertos nas quatro estações (%s)" % [conta.verbos.keys()])
	_esperar(conta.lado_so_no_dono, "S09_J44: o lado da sentinela só no motor do dono")
	_esperar(not conta.gatilho_preso, "S09_J44: os gatilhos soltos a partida inteira")
	_esperar(mg.coop and mg.destaque() >= 0, "S09_J44: o resultado é coop, com o destaque")
```

No `_prova_do_relatorio()`, com as linhas do `S09_J44`:

- as linhas `estacao` são seis, na ordem do roteiro;
- há 1 `momento` `rugido_do_meio`, com `t_musica` a até 16,7 ms de 50,0 s, e cada lugar tem `sensacao` `explosao` a
  até 16,7 ms dele;
- há `pista` com `o_que` `esquerda` e com `direita`;
- nenhuma `sensacao` e nenhum `som_controle` de háptica no mesmo controle e no mesmo quadro.

Os comandos:

```bash
SALA=S09_J44 bash tests/prova_do_jogo.sh
bash tests/prova_visual.sh
bash tests/prova_sem_rastro.sh
```

A mesa boa e a mesa fraca rodam hoje, porque o temperamento é um só para os quatro: `--robo=bom --semente=7` e
`--robo=medio --semente=7`.

**As pranchas que se olham** (`SAIDA/prancha-<n>.png`):

- a de quatro com `bom`: as estações trocando, os objetos de origem, a plataforma inteira no fim, o dragão caído;
- a de quatro com `medio`: os buracos na plataforma depois do rugido, a luz mais baixa;
- a de um: o cavaleiro sozinho tocando todas as batidas;
- a do cabo que cai: a batida dele vazia, sem laje caída por ela;
- nas quatro: as roupas de cima e de baixo de cada cavaleiro em valores diferentes, e o néon só no friso e na costura.

**Com o André (local):** `./run-local.sh -- --sala=S09_J44`, com quatro, no fim de uma noite. A troca de estação tem de
ser entendida em meio segundo (o objeto e o glifo); o rugido tem de ser caótico e divertido; a plataforma caindo tem
de dar vontade de «mais uma».
