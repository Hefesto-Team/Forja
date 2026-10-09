# Q3 — Mecha de Dois Pilotos

**Sprint:** Q · **Slot:** S09_J43 · **Tamanho:** M · **Depende de:** Q1 (a seção no catálogo, o tipo `momento`, o `_peca`, o `_tingir`, o Aprendiz), H04, H08, H07, F05 (`Forja.sentir`), F09 (`Forja.robo_acerta`), G03, G05, G13, G14, G15 · **Usa se existir:** G10 (o Factory Kit; sem ele, a peça de reserva)

## Por quê

Cada dupla pilota um mecha: um é a perna esquerda, o outro a direita. Andar é alternar os passos no tempo; o soco só
sai com os dois apertando o R2 até o clique a menos de 90 ms um do outro. Fora disso, o braço dá a volta e o mecha
soca a própria cabeça. A ficha existe para que essa cabeçada aconteça pelo menos 2 vezes em 100 s na mesa das duplas,
com o clang nos dois controles da dupla no mesmo quadro, e a sala ria.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (onde mora, a FICHA, o robô, o registro, a prova)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) e [as decisões comuns da H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
- [A Q1](Q1-a-prova.md), «Os ganchos» e «Com menos de quatro» (o `_gancho`, o `_saida`, o `_peca`, o `_tingir`, o
  Aprendiz, a forma do `vencedor()` de equipe)

Tudo o mais que esta ficha usa (as cores, o brilho, a câmera, o movimento, o som, os stats, a régua da diversão)
está escrito aqui dentro, com o número.

## Arquivos que mudam

- `godot/scripts/minigames/s09/mecha_de_dois_pilotos.gd` (novo, `extends Minigame`, sem `class_name`) e o `.uid`.
- `godot/scripts/minigames/catalogo.gd`: `"S09_J43"` em `MINIGAMES` e na lista da seção `S09`, depois do `S09_J42`.
  **De todos:** Q1, Q2, Q4 e Q5.
- `godot/scripts/traducoes.gd`: as frases da tabela «As frases». **De todos:** Q1, Q2, Q4 e Q5.
- `godot/testes/prova_do_jogo.gd`: `_prova_mecha()` e a linha `"S09_J43": await _prova_mecha()` no `match` de
  `_prova_da_ficha`. **De todos:** Q1, Q2, Q4 e Q5.

A linha 43 do `docs/jogo/sistemas/minigames.csv` já diz os ganchos desta ficha; ela não muda.

## Como se joga

**Ande junto, soque junto!** Brasa contra Maré, um mecha por dupla. Cada piloto é uma perna: o ✕ no tempo é o passo
dele, e a perna dele treme na mão meia batida antes. No gongo, os dois apertam o R2 até o clique: juntos, o soco;
separados, o mecha soca a própria cabeça. Melhor de três quedas.

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J43",
	"titulo": "Mecha de Dois Pilotos",
	"verbo": "Ande junto, soque junto!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S09_J43",
	"duracao": 100.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir", "explosao", "toque"],
	"material": "metal",
	"microjogo": {"verbo": "Soquem juntos!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_HAPTICA,
	"textura_no_acerto": true,
	"gesto": "attack-melee-right",
}
```

As entradas são duas: o ✕ (o passo) e o R2 (eixo, fora da lista, o soco). O `fim` é `tempo`: a melhor de três acaba
antes pondo `acabou` em todos (ver «O fim e o vencedor»). `textura_no_acerto` fica `true`: a perna na mão vem meia
batida antes do acerto e não encosta nele.

### O tempo

A faixa `MUS_S09_J43` tem 145 BPM: uma batida dura 0,4138 s, a colcheia 0,2069 s, a semicolcheia 0,1034 s. 100 s são
241 batidas inteiras (a última em 99,7 s).

| constante | valor | o que é |
| --- | --- | --- |
| `CICLO` | 8 batidas | o ciclo começa em `g0 = 4 + 8k` (k de 0 a 29) |
| `DIST_INICIAL` | 8,0 m | a distância entre os mechas no começo e depois de uma queda, antes do ringue |
| `DIST_MIN`, `DIST_MAX` | 2,2 m, 8,0 m | a distância nunca sai disso |
| `RINGUE_X` | 1,6 m | do ringue em diante, o x de cada mecha fica em \|x\| ≤ 1,6 (a distância vai a no máximo 3,2) |
| `ALCANCE` | 3,2 m | o soco só entra com a distância até isso |
| `PASSO` | `[0.0, 0.25, 0.30, 0.35]` m | o avanço do mecha por julgamento do passo, antes do gancho |
| `RECUO` | 0,2 m | o passo errado leva o mecha para trás |
| `SINC` | 0,09 s | a diferença máxima entre os dois apertos do soco |
| `ABALO`, `AUTOSSOCO`, `QUEDA` | 1,0, 0,5, 3,0 | o soco que entra, a cabeçada própria, o abalo que derruba |
| `EMPURRAO` | 1,5 m | o mecha atingido vai para trás, antes dos ganchos |
| `PONTOS` | `[0, 50, 75, 100]` | pontos da equipe por passo julgado |
| `PONTOS_SOCO` | 300 | pontos da equipe por soco que entra |
| `PARCEIRO_PRONTO`, `MEU_LIVRE` | 0,3, 0,15 | os eixos do R2 de «O parceiro pronto» |
| `ACERTO_APRENDIZ_PASSO`, `ACERTO_APRENDIZ_SOCO` | 0,85, 0,7 | o Aprendiz |
| `RINGUE_DE` | batida 84 (34,8 s) | o ringue fecha |
| `RETA_DE` | batida 164 (67,9 s) | dois socos por ciclo |
| `DERRUBA_DE` | batida 226 (93,5 s) | as últimas 16 batidas: o soco que entra derruba |
| `TORTA` | 30° | a cabeça depois da cabeçada |

### As regras

- **As equipes e as pernas:** `presentes()` na ordem, completados pelo Aprendiz como na Q1 («Com menos de quatro»). Em
  cada equipe, o primeiro é a perna esquerda (E, `_perna[l] = 0`), o segundo a direita (D, `_perna[l] = 1`).
- **Os mechas:** a Brasa em `x = -4.0`, a Maré em `x = 4.0`, os dois em z = 0; `_dist = _x[1] - _x[0]`.
- **O ciclo** (de `g0` a `g0 + 7`). A perna que começa troca a cada ciclo: com `k` par começa E, com `k` ímpar começa D.

  | batida | antes da reta (batidas 4 a 163) | na reta (164 em diante) |
  | --- | --- | --- |
  | `g0` | o soco (R2), os dois | o soco (R2), os dois |
  | `g0 + 1` | ninguém (o impacto cai na colcheia `g0 + 0,5`) | ninguém |
  | `g0 + 2` | o passo (✕) da perna que começa | o passo da perna que começa |
  | `g0 + 3` | o passo da outra | o gongo, ninguém pisa |
  | `g0 + 4` | o passo da que começa | o segundo soco, os dois |
  | `g0 + 5` | o passo da outra | ninguém (o impacto em `g0 + 4,5`) |
  | `g0 + 6` | o passo da que começa | o passo da outra |
  | `g0 + 7` | o gongo, ninguém pisa | o gongo, ninguém pisa |

  Com `Ritmo.simples[l]`: o lugar pisa só no primeiro passo dele no ciclo; o soco continua dele.
- **O gongo:** em `t(g0 - 1) - _gancho(l, "pista") / 1000.0` (e em `t(g0 + 3) - ...` na reta), nos dois pilotos do
  mecha: `Forja.som_falante(l, "pronto", 0.8)` com `anotar("pista", l, {"n": n, "evento": "mandou", "canal":
  "alto_falante", "o_que": "gongo"})`. Sem alto-falante (`not Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)`):
  `Forja.sentir(l, "toque")`, `canal` `rumble`.
- **O passo:** ✕ no tempo → `julgar_toque(l, t(bn), n)`. O mecha anda `PASSO[j] × média(velocidade)` metros na
  direção do outro, dentro de `DIST_MIN` e `DIST_MAX` (e de `RINGUE_X` do ringue em diante). A perna do piloto pisa: a
  perna gira 20° para a frente e volta em meia batida, pela batida.
- **A perna na mão:** meia batida antes de cada passo do piloto, `Forja.som_haptica(l, "material:metal", "", 0.6)` (E)
  ou `Forja.som_haptica(l, "", "material:metal", 0.6)` (D), com `anotar("pista", l, {"n": n, "evento": "mandou",
  "canal": "haptica", "o_que": "E"})` (ou `"D"`). No rádio (`_rumble[l]`): `Forja.sentir(l, "golpe_esq", 120)` (E) ou
  `Forja.sentir(l, "golpe_dir", 120)` (D), `canal` `rumble`.
- **O soco:** o R2 cruzando 0,6 subindo na nota do soco → `julgar_toque(l, t(g0), n)`, e
  `_aperto_t[l] = Ritmo.t_musica()` (o instante do quadro). Quando os pilotos com controle do mecha foram julgados, ou
  quando a janela fecha (`t(g0) + 0.140`), o `_resolver_soco(e)` decide:

  | os dois pilotos | resultado |
  | --- | --- |
  | os dois sem erro e `sincronizados(_aperto_t[E], _aperto_t[D])`, com `_dist <= ALCANCE` | **o soco entra** |
  | os dois sem erro e sincronizados, com `_dist > ALCANCE` | **o ar**: nada, e ninguém é punido |
  | um só sem erro, ou os dois sem erro com mais de `SINC` entre eles | **a cabeçada** (ver «A cabeçada») |
  | nenhum sem erro | nada (os dois já perderam a nota pelo kit) |

  `static func sincronizados(a: float, b: float) -> bool: return absf(a - b) <= SINC`. O instante é o do aperto, não o
  julgamento: dois BONS em lados opostos da janela podem estar a 200 ms um do outro, e isso é fora de sincronia.
- **O soco entra** (o impacto na colcheia `g0 + 0,5`): `_abalo[outra] += ABALO` (da batida 226 em diante,
  `_abalo[outra] = QUEDA`); o outro mecha vai `EMPURRAO × média(tranco da dupla que soca) × média(empurrao da dupla
  atingida)` metros para trás, em 1 colcheia com `ENTRA_SAI`, dentro dos limites; `marcar_equipe(e, PONTOS_SOCO)`;
  os que socam sentem `Forja.sentir(l, "acerto")`, os atingidos `Forja.sentir(l, "golpe")`.
- **O parceiro pronto:** da hora do gongo até a janela do soco fechar, quando o R2 do parceiro passa
  `PARCEIRO_PRONTO` (0,3) e o meu está abaixo de `MEU_LIVRE` (0,15), o meu R2 treme leve:
  `Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, 0, 1, 40)` (amplitude 1, 40 Hz). Quando o meu passa 0,15, ou o do
  parceiro cai abaixo de 0,3, ou a janela fecha, o R2 volta a `Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)`. O
  0,15 fica antes da parede da Arma (posição 2), então o dedo sempre encontra a parede e o clique. Com o Aprendiz de
  parceiro, nada treme (o Aprendiz não tem eixo).
- **O R2** fica em `GATILHO_ARMA` (2, 6, 8) a partida inteira, fora do tremor acima; o L2 é do item (G03).
- **A queda:** um mecha com `_abalo >= QUEDA` cai: `_quedas[outra] += 1`, os dois mechas voltam à distância do trecho
  (8,0 m antes do ringue; x = ∓1,5 do ringue em diante), os abalos zeram, as cabeças desentortam, e o ciclo seguinte
  não abre notas (`_pausa_ate = floor(b) + CICLO`; a música segue, e a TV mostra o mecha levantando).
- **A curva:**

  | trecho | batidas | o que acontece |
  | --- | --- | --- |
  | 0 a 34,8 s, andar | 4 a 83 | a distância começa em 8 m; os passos aproximam; um soco por ciclo |
  | 34,8 a 67,9 s, o ringue fecha | 84 a 163 | na batida 84 os mechas são puxados para x = ∓1,5 em 2 batidas (`ENTRA_SAI`) e ficam em \|x\| ≤ 1,6: todo soco sincronizado entra |
  | 67,9 s ao fim, a reta | 164 a 241 | o ringue segue; dois socos por ciclo (`g0` e `g0 + 4`); da batida 226 em diante, o soco que entra derruba |

  Na batida 84 e na 164, a luz faz o pico (ver «A cena»). No primeiro quadro da batida 226 sai
  `anotar("momento", -1, {"nome": "reta", "lugar": -1, "t_musica": Ritmo.t_musica(), "objeto": {"derruba": true}})`.
- **Ensina sem falar:** na contagem do kit (batidas 0 a 3), a perna de E de cada mecha levanta e acende a 2,6 na
  batida 0, a de D na batida 1; na batida 2, os dois braços de cada mecha saem juntos no ar e voltam, com
  `Som.tocar("martelo", pos_do_mecha, -10.0)`, sem julgamento. O gongo de verdade toca na batida 3, e o primeiro soco é
  na 4.

### A cabeçada (o momento)

A falha da dupla: o soco fora de sincronia. No impacto (a colcheia `g0 + 0,5`):

1. `c` = o culpado: o piloto sem acerto, ou, com os dois sem erro, o de aperto mais longe de `t(g0)`. Se o culpado é
   o Aprendiz, `c` é o parceiro humano dele.
2. `anotar("momento", c, {"nome": "autossoco", "lugar": c, "t_musica": Ritmo.t_musica()})`;
3. o clang nos dois alto-falantes da dupla, no mesmo quadro: `Forja.som_falante(l, "sino", 0.7)` em cada piloto com
   alto-falante; `Forja.sentir(l, "golpe")` nos dois pilotos (o Aprendiz não tem controle);
4. `_abalo[e] += AUTOSSOCO`; o braço da frente dá a volta em 1 colcheia e bate na cabeça; a cabeça fica torta
   `TORTA` (`rotation.z`) e amassada (`scale.y = 0.85`) até a próxima queda de qualquer mecha; uma segunda cabeçada não
   entorta mais;
5. o degrau **estrondo**: `tremor = 0.42` por 2 batidas (0,05 m); parada de 3 quadros (`p.anim.speed_scale = 0` nos
   quatro); 48 faíscas `Efeitos.faiscas(self, pos_da_cabeca, Tema.TUNGSTENIO, 48, 1.0)`; a luz de preenchimento a
   ×0,7 por 1 batida, volta em 1 batida; o contorno dos dois pilotos da dupla vai de 2,4 a 3,0 no mesmo tempo;
   `camera_foco = pos_da_cabeca` por 2 batidas;
6. **a queda dos pilotos:** a nota de passo de cada um dos dois que cairia antes de
   `t_impacto + _queda_s(e)` não abre, com
   `_queda_s(e) = maxf(0.1034, snappedf(2 * 0.4138 * média(levantar), 0.1034))` (2 tempos × `levantar` médio da
   dupla, arredondado à semicolcheia). Os dois fazem `emote-no` em 0,3 s.

Com `Opcoes.movimento == 1`: sem tremor, sem parada e sem `camera_foco`.

O passo errado (ou que passou) não é cabeçada: a perna tropeça (gira 15° para trás e volta em meia batida), o mecha
recua `RECUO`, e o piloto faz `emote-no` em 0,3 s.

### O fim e o vencedor

A primeira equipe com 2 quedas vence: `_fim_batida = floor(b) + 4`, e nessa batida `acabou[l] = true` em todos. Sem
isso, o kit fecha nos 100 s de música. O vencedor: a equipe com mais quedas; no empate, a de menos abalo agora; depois,
`equipe_vencedora()` (a de mais pontos; no empate, a Brasa). `vencedor()` devolve os da equipe vencedora (por pontos)
e depois os da outra, na forma da Q1.

### Com menos de quatro

| jogadores | Brasa | Maré | `com_poucos()` |
| --- | --- | --- | --- |
| 4 | 1º (E) e 2º (D) | 3º (E) e 4º (D) | — |
| 3 | 1º e 2º | 3º (E) e o Aprendiz (D) | `"Com o Aprendiz"` |
| 2 | 1º (E) e o Aprendiz | 2º (E) e o Aprendiz | `"Com o Aprendiz"` |
| 1 | 1º (E) e o Aprendiz | dois Aprendizes | `"Você e o Aprendiz contra 2"` |

O Aprendiz pisa acertando `ACERTO_APRENDIZ_PASSO` das vezes (sempre BOM) e, no soco, aperta exatamente em `t(g0)`
com `ACERTO_APRENDIZ_SOCO` (senão, não aperta), sorteados com o `rng` do kit: é o humano que sincroniza com ele. Um
mecha de dois Aprendizes sorteia uma vez por soco: com 0,7 o soco sai sincronizado, senão nada (nunca cabeçada, que
precisa de um lugar). O Aprendiz não é lugar, não pontua, não entra no registro de notas e não é robô.

**O controle que cai:** o piloto sem controle não pisa nem soca; o soco do parceiro vale sozinho enquanto ele estiver
fora (a sincronia é dispensada: ninguém é punido pelo cabo); o R2 dele não treme por ninguém. Volta no ciclo seguinte.

### O robô

Pisa pelo relógio da música. No soco, só aperta se ouviu o gongo: no alto-falante da placa virtual
(`Forja.som_virtual(l).falante > 0.05`) ou, no rádio, no motor fraco (`Forja.percepcao(l).fraco > 0.2`), sempre
entre `t(g0 - 1) - 0.1` e `t(g0) - 0.1`, onde nenhuma perna toca. Quando `Forja.robo_acerta()` diz não, atrasa
0,12 s: no passo, perde o PERFEITO; no soco, sai fora de sincronia com o parceiro.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	_robo_ouvir(l)                       # guarda em _robo_ouviu[l] o g0 do gongo que ouviu
	var n: int = _nota[l]
	if n < 0 or _robo_tocou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.12
	if Ritmo.t_musica() < float(_alvo[l]) + float(_robo_mira[l]):
		return
	if _e_soco[l]:
		if _robo_ouviu[l] == _g0[l]:
			Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
	else:
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
	_robo_tocou[l] = n


func _robo_ouvir(l: int) -> void:
	var g := _proximo_g0()
	var t := Ritmo.t_musica()
	if t < Ritmo.t_da_batida(g - 1) - 0.1 or t > Ritmo.t_da_batida(g) - 0.1:
		return
	var ouviu := float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05
	if _rumble_falante[l]:
		ouviu = float(Forja.percepcao(l).get("fraco", 0.0)) > 0.2
	if ouviu:
		_robo_ouviu[l] = g
```

### Os ganchos

`godot/scripts/minigames/s09/mecha_de_dois_pilotos.gd`:

```gdscript
extends Minigame
## Mecha de Dois Pilotos (S09_J43). Cada dupla pilota um mecha: um é a perna
## esquerda, o outro a direita; o mecha anda com os passos alternados no tempo
## (✕). No gongo, os dois apertam o R2 até o clique, a menos de 90 ms: o soco.
##
## A falha: fora de sincronia, o mecha soca a própria cabeça (autossoco).
## O vencedor: melhor de três quedas. O alto-falante do dono: o gongo e o clang.
## O registro mede: o gongo e a perna (pista), o R2 em arma e o tremor do
## parceiro pronto (saida), a diferença dos dois apertos (jogo soco), o momento
## autossoco. O robô: pisa pelo relógio e só soca se ouviu o gongo.
## Com menos de quatro: o Aprendiz pilota a outra perna.
## A régua: a cor da equipe está no chão e no peito; a perna é do piloto.

const FICHA := { ... }   # a de «A ficha de dados»
# as constantes de «O tempo»
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}

var _perna := [0, 1, 0, 1]             ## lugar -> 0 (E) ou 1 (D)
var _piloto := [[-1, -1], [-1, -1]]    ## equipe -> [lugar E, lugar D]; -1 é o Aprendiz
var _aprendizes := []                  ## {equipe, perna, no}
var _x := [-4.0, 4.0]
var _abalo := [0.0, 0.0]
var _quedas := [0, 0]
var _torta := [false, false]
var _pausa_ate := -1.0
var _fim_batida := -1.0
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _e_soco := [false, false, false, false]
var _g0 := [-1, -1, -1, -1]            ## o g0 do soco da nota aberta
var _n := [0, 0, 0, 0]
var _r2_antes := [0.0, 0.0, 0.0, 0.0]
var _aperto_t := [-1.0, -1.0, -1.0, -1.0]
var _julgado := [-1, -1, -1, -1]       ## o julgamento do soco (Ritmo.ERRO = sem acerto)
var _soco := [{}, {}]                  ## equipe -> {g0, resolvido, resultado, impacto_t}
var _tremendo := [false, false, false, false]
var _sem_passo_ate := [-1.0, -1.0, -1.0, -1.0]
var _rumble := [false, false, false, false]          ## sem háptica: a perna pelo rumble
var _rumble_falante := [false, false, false, false]  ## sem alto-falante: o gongo pelo rumble
var _nos := {}                         ## os nós dos mechas: pernas, runas, braços, cabeça, visor
var _robo_nota := [-1, -1, -1, -1]
var _robo_tocou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_ouviu := [-1, -1, -1, -1]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 5.0, 17.0)
	camera_olhar = Vector3(0, 2.8, 0)
	_montar_cena()                   # «A cena»
	_formar_pilotos()                # as equipes, as pernas, os Aprendizes nos ombros


func iniciar_jogo() -> void:
	for l in presentes():
		_saida(l, Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8))
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)
		_rumble_falante[l] = not Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)
		if _rumble[l]:
			anotar("troca", l, {"de": "haptica", "para": "rumble"})


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	_trecho(b)                       # o ringue na 84, a reta na 164, o momento reta na 226, o pico de luz
	_gongo(b)                        # o pronto (ou o toque) nos dois pilotos de cada mecha
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_abrir_nota(l, b)            # o passo da perna dele ou o soco; nada na pausa nem na queda
		_perna_na_mao(l, b)          # meia batida antes do passo
		_entrada(l)                  # ✕ no passo; R2 cruzando 0,6 no soco (guarda _aperto_t); julgar_toque
		_parceiro_pronto(l, b)       # o tremor do R2
		_prazo(l)                    # a nota que passou: nota_perdida
	_aprendizes_pilotam(b)
	for e in 2:
		_resolver_soco(e, b)         # quando os dois foram julgados ou a janela fechou
		_impacto(e, b)               # na colcheia g0 + 0,5: o soco, o ar ou a cabeçada
	_cair_se_preciso(b)
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	if _e_soco[l]:
		_julgado[l] = j
		return
	marcar_equipe(equipe[l], PONTOS[j])
	_andar(equipe[l], PASSO[j] * _media(equipe[l], "velocidade"), _perna[l], j)


func falha(l: int) -> void:
	if _e_soco[l]:
		_julgado[l] = Ritmo.ERRO
		return
	_andar(equipe[l], -RECUO, _perna[l], Ritmo.ERRO)
	jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var e := BRASA
	if _quedas[0] != _quedas[1]:
		e = BRASA if _quedas[0] > _quedas[1] else MARE
	elif _abalo[0] != _abalo[1]:
		e = BRASA if _abalo[0] < _abalo[1] else MARE
	else:
		e = maxi(equipe_vencedora(), BRASA)
	var ganhou := presentes().filter(func(l): return equipe[l] == e)
	var perdeu := presentes().filter(func(l): return equipe[l] != e)
	ganhou.sort_custom(func(a, b): return pontos[a] > pontos[b])
	perdeu.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return ganhou + perdeu


static func sincronizados(a: float, b: float) -> bool:
	return absf(a - b) <= SINC


func _gancho(l: int, nome: String) -> float:
	return float(NEUTRO[nome])   # troque por Cavaleiro.gancho(l, nome) quando `grep -rn "static func gancho" godot/scripts/` achar


func _media(e: int, nome: String) -> float:
	var a: int = _piloto[e][0]
	var d: int = _piloto[e][1]
	var ga := _gancho(a, nome) if a >= 0 else float(NEUTRO[nome])
	var gd := _gancho(d, nome) if d >= 0 else float(NEUTRO[nome])
	return (ga + gd) / 2.0
```

As outras funções, uma frase cada:

- `_saida(l, ok)`, `_peca(nome, reserva, pos)`, `_tingir(modelo, cor)`: os da Q1, copiados (o minigame não tem
  `class_name` e não herda da Q1).
- `_abrir_nota(l, b)`: a próxima nota do lugar pela tabela do ciclo, uma batida antes; `_e_soco[l]` e `_g0[l]`; nenhuma
  nota antes de `_pausa_ate`, e nenhum passo antes de `_sem_passo_ate[l]`; `nova_nota`.
- `_proximo_g0()`: a batida do próximo soco a partir de agora (`4 + 8k`, e `g0 + 4` na reta).
- `_perna_na_mao(l, b)`: quando `b >= n - 0.5` do passo aberto, a pista do lado, uma vez por nota.
- `_entrada(l)`: o ✕ por `Forja.apertou`; o R2 cruzando 0,6 subindo pelo `_r2_antes`, nunca por `apertou`.
- `_parceiro_pronto(l, b)`: a regra de «O parceiro pronto», com `_tremendo[l]` para mandar a troca uma vez por mudança,
  sempre por `_saida`.
- `_resolver_soco(e, b)`: a tabela de «O soco»; anota `anotar("jogo", -1, {"o": "soco", "equipe": e, "resultado": r,
  "dif_ms": roundi(absf(_aperto_t[E] - _aperto_t[D]) * 1000.0)})` com `r` em `entrou`, `ar`, `autossoco` ou `nada`.
- `_impacto(e, b)`: na colcheia `g0 + 0,5`, o efeito do resultado (o soco entra, o ar, a cabeçada); o soco que entra
  põe `camera_foco` no ponto de impacto por 1 batida.
- `_andar(e, d, perna, j)`: o mecha `e` anda `d` na direção do outro, dentro dos limites do trecho; a perna gira; a
  runa da perna vai a 2,6 por 4 quadros quando `j` não é erro.
- `_cair_se_preciso(b)`: a queda de «As regras»; `Forja.sentir(l, "explosao")` nos pilotos do que caiu;
  `Som.tocar("especial")`; com 2 quedas, o `_fim_batida`.
- `status(l)`: `"Brasa %d" % _quedas[0]` ou `"Maré %d" % _quedas[1]`.
- A dica, com `na_raia(l)` e a `pos` no pé do mecha: `["@cross"]` no passo e `["@r2"]` no soco, enquanto
  `not aprendeu(l)`.

### A casa nova e o catálogo

1. Criar o script; `"$GODOT" --headless --path godot --import --quit`; commitar o `.uid`.
2. `catalogo.gd`: `"S09_J43": preload("res://scripts/minigames/s09/mecha_de_dois_pilotos.gd")` em `MINIGAMES`;
   `"S09_J43"` na lista da seção `S09`, depois do `S09_J42`.

### As frases

| português | inglês |
| --- | --- |
| Mecha de Dois Pilotos | Two-Pilot Mech |
| Ande junto, soque junto! | Step together, punch together! |
| Soquem juntos! | Punch together! |

`"Brasa"`, `"Maré"`, `"Com o Aprendiz"` e `"Você e o Aprendiz contra 2"` já entraram pela Q1.

### O registro

- `pista` do gongo (`o_que` `gongo`, `canal` `alto_falante` ou `rumble`) e da perna (`o_que` `E` ou `D`, `canal`
  `haptica` ou `rumble`);
- `saida` do R2 em arma (uma vez por lugar) e de cada troca do tremor do parceiro pronto, com `seq` e `ok`;
- `troca` `haptica` → `rumble` no rádio, uma vez;
- `jogo` `soco` com o `resultado` e o `dif_ms` (a sincronia da dupla; a noite compara cabo e rádio);
- `momento` `autossoco` e `reta`; `sensacao` `acerto`, `golpe`, `explosao`, `toque`, `golpe_esq`, `golpe_dir`;
- `nota` e `toque` dos passos e dos socos (o kit).

### Armadilhas

- **O R2 é o soco, o ✕ é o passo:** a tabela do ciclo nunca põe os dois na mesma batida para o mesmo piloto.
- **A sincronia usa o instante do aperto**, não o julgamento.
- **O tremor do parceiro troca o modo do R2:** ele só liga com o meu eixo abaixo de 0,15 e desliga quando passa, para o
  dedo achar a parede da Arma. Nunca deixe o R2 em Vibração depois da janela.
- **Rumble e háptica nunca no mesmo instante no mesmo controle:** o impacto cai na colcheia `g0 + 0,5`; o golpe dura
  250 ms e acaba antes da primeira perna do ciclo (`g0 + 1,5`); o gongo cai numa batida sem passo.
- **O Aprendiz não é robô** (é regra do jogo, com o `rng` do kit).
- **A partida acaba pela música:** a prova leva uns 100 s de relógio por rodada; não encurte.

## A cena

- **A câmera:** a dupla de lado (50 mm, 27° vertical, plongée de 7,4°, à altura do peito, nunca corta).
  `camera_pos = Vector3(0, 5.0, 17.0)`, `camera_olhar = Vector3(0, 2.8, 0)`. Medido por projeção com 27° vertical e
  16:9: com os mechas a 8 m (x = ±4), o pé cai em y 0,83, a cabeça (±4, 4,6) em x 0,22 e 0,78 e y 0,28; a borda de
  fora do mecha (\|x\| = 5,65) em x 0,11 e 0,89; o alto dos pilotos (6,0 m) em y 0,11. O ponto de impacto no meio
  cai em (0,50; 0,43). `camera_foco` é o empurrão leve da G05 (15 % na direção da ação, no máximo 1,5 m): no ponto de
  impacto por 1 batida no soco que entra, na cabeça por 2 batidas na cabeçada; `Vector3.ZERO` no resto.
- **A luz:** a da seção pela G15, `Tema.luz_da_secao(9, "B")`; as tochas
  `luzes([Vector3(-10, 3, -6), Vector3(10, 3, -6), Vector3(0, 4, 6)])`. Na batida 84 e na 164, a chave sobe 20 % em
  1 batida e a névoa vai a ×0,8; voltam em 2 batidas.
- **O chão:** de cada lado, na cor da equipe:
  `Kit.caixa(self, Vector3(8.0, 0.03, 6.0), Vector3(∓4.0, 0.015, 0), Kit.material(CORES_DAS_EQUIPES[e], 0.0, 0.9))`.
- **O ringue:** dois guindastes ao fundo, `_peca("factory-kit/crane", "column", Vector3(±7.5, 0, -3.5))`. Da batida 84
  em diante, duas linhas no chão em x = ±1,9:
  `Kit.caixa(self, Vector3(0.12, 0.06, 6.0), Vector3(±1.9, 0.05, 0), mat)` com `Tema.neon(Tema.TUNGSTENIO, 1.0, "mundo")`,
  que entram subindo de y −0,1 em 2 batidas.
- **O mecha** (peças do kit mais um brilho), um `Node3D` por equipe em `(_x[e], 0, 0)`, com
  `rotation.y = deg_to_rad(-125.0)` na Brasa e `deg_to_rad(125.0)` na Maré (os dois se olham e viram 35° para a câmera,
  para as duas pernas e os dois pilotos aparecerem separados):
  - as pernas: `_peca("factory-kit/piston-round", "column", Vector3(±0.8, 0, 0))` (E em −0,8, D em +0,8, locais),
    escaladas por igual até 2,6 m de altura pela AABB;
  - a runa de cada perna: `Kit.caixa(perna, Vector3(0.16, 1.8, 0.16), Vector3(0, 1.3, -0.45), mat)` com
    `Tema.neon(Tema.JOGADOR[l], 2.0, l)`; com o Aprendiz na perna, `Kit.material(Tema.ETIQUETA_SOMBRA, 0.0, 0.9)`; sem
    controle, energia 0 até voltar;
  - o tronco: `Kit.caixa(mecha, Vector3(2.2, 1.6, 1.4), Vector3(0, 3.4, 0), Kit.material(Tema.GRAFITE, 0.0, 0.9))`;
  - o peito: `Kit.caixa(mecha, Vector3(1.2, 0.8, 0.1), Vector3(0, 3.5, -0.72), Kit.material(CORES_DAS_EQUIPES[e], 0.0, 0.9))`;
  - a cabeça: `Kit.caixa(mecha, Vector3(1.0, 0.7, 0.9), Vector3(0, 4.6, 0), Kit.material(Tema.OXIDO, 0.0, 0.9))`, e o
    visor `Kit.caixa(cabeca, Vector3(0.7, 0.14, 0.06), Vector3(0, 0.05, -0.46), mat)` com
    `Tema.neon(Tema.VIOLETA, 1.0, "mundo")`;
  - os braços: `Kit.caixa(mecha, Vector3(0.5, 1.4, 0.5), Vector3(±1.4, 3.2, 0), Kit.material(Tema.GRAFITE, 0.0, 0.9))`.
    O soco: o braço do lado do outro mecha aponta para o peito dele e estica 1,2 m em meia batida, com antecipação de
    1 colcheia (recua 0,2 m) e volta com `MOLA`. A cabeçada: o mesmo braço sobe e dá a volta até a cabeça em 1 colcheia.
  - `_peca(nome, reserva, pos)` é o da Q1: usa `nome` se `FileAccess.file_exists("res://assets/kenney/%s.glb" % nome)`,
    senão a reserva.
- **O impacto:** o soco que entra solta 24 faíscas `Efeitos.faiscas(self, ponto, Tema.TUNGSTENIO, 24, 0.8)`, o
  `tremor = 0.17` por 1 batida (0,02 m) e uma parada de 2 quadros; o mecha atingido inclina 12° para trás e volta com
  `MOLA` em 1 batida. A cabeçada está em «A cabeçada».
- **Os pilotos:** em pé nos ombros, E em `(-0.85, 4.2, 0)` e D em `(0.85, 4.2, 0)`, locais ao mecha, `p.preso = true`,
  `p.controlavel = false`; `attack-melee-right` no soco, `idle` no resto. O Aprendiz no ombro dele.
- **A queda:** o mecha tomba 80° para trás em 1 batida, com 48 faíscas `TUNGSTENIO`, fica 4 batidas no chão e levanta
  em 2 batidas com `ENTRA_SAI`, enquanto a pausa corre.
- **Os brilhos e os donos:**

  | o quê | dono | energia |
  | --- | --- | --- |
  | o contorno de cada cavaleiro | o lugar | 2,4; 3,0 por 1 batida nos dois da cabeçada |
  | o acento da peça (friso, costura, runa do item) | o lugar | 1,6 (o da G13) |
  | a runa da perna | o lugar | 2,0; 2,6 por 4 quadros a cada passo certo |
  | o visor | `"mundo"` | 1,0; 0 por 3 quadros na cabeçada |
  | as linhas do ringue | `"mundo"` | 1,0 |
  | as faíscas do impacto e da queda | `"mundo"` | 1,0 por 12 quadros |
  | o chão, o peito, o tronco, os guindastes | ninguém | 0 (impressos) |

- **O que sai:** o `aco` e o visor de cor escrita à mão da ficha antiga (nenhum `Color("#...")` no script), a
  `atmosfera` com `Tema.ROXO`, o `Kit.arena(self, 6, 4)` e o chão `cor_equipe.darkened(0.3)`.

## O som

| quando | onde | id do mapa | como |
| --- | --- | --- | --- |
| a partida | TV | `mus_s09_j43` (145 BPM, Sol menor; reserva `sint_trilha`) | a FICHA, `"faixa": "MUS_S09_J43"` |
| o gongo | alto-falante dos dois pilotos do mecha | `mod_pronto` | `Forja.som_falante(l, "pronto", 0.8)` em `t(g0 - 1)` − pista |
| a perna levanta | atuador do lado da perna, no controle do piloto | `mod_material_metal` | `Forja.som_haptica(l, "material:metal", "", 0.6)` ou `(l, "", "material:metal", 0.6)` |
| o soco entra | TV | `martelo_0` a `martelo_4` | `Som.tocar("martelo", ponto, 2.0)`, na colcheia `g0 + 0,5` |
| o soco no ar | TV | `vazio_0` | `Som.tocar("vazio", ponto, -8.0)` |
| a cabeçada | TV | `golpe_0` a `golpe_4` | `Som.tocar("golpe", pos_da_cabeca, 0.0)` |
| o clang da cabeçada | alto-falante dos dois pilotos, no mesmo quadro | `mod_sino` | `Forja.som_falante(l, "sino", 0.7)` |
| a queda | TV | `especial_0` | `Som.tocar("especial")` |
| a nota do perfeito, a quebrada do erro | controle do dono | `mod_nota_p1..p4`, `mod_nota_quebrada_p1..p4` | o kit |
| o apito, a vitória | TV | `jin_apito`; `vitoria_sala_0`/`1` | o kit |

O alto-falante toca um som por vez: vitória > julgamento > segredo > pio > coleta > clique. O gongo cai na batida
`g0 − 1`, onde ninguém tem nota; o clang cai na colcheia `g0 + 0,5`, depois do julgamento do soco.

## O controle

| evento | os pilotos do mecha | os outros | prova sem a mão |
| --- | --- | --- | --- |
| a partida inteira | R2 em Arma (2, 6, 8) | o mesmo | `percepcao(l).gatilho_dir == 0x25` em todos os lugares em alguma amostra |
| o parceiro pronto | R2 em Vibração (0, 1, 40 Hz) enquanto o eixo do parceiro ≥ 0,3 e o meu < 0,15, na janela do gongo | nada | `gatilho_dir == 0x26` em alguma amostra (o robô atrasado deixa o parceiro esperando); linha `saida` da troca |
| a perna | `mod_material_metal` 0,6 no atuador do lado, meia batida antes do passo; no rádio, `golpe_esq`/`golpe_dir` de 120 ms | nada | `som_virtual(l)`: o lado da perna > 0,05 e o outro < 0,02 no quadro da pista |
| o gongo | `mod_pronto` 0,8 nos dois; sem alto-falante, `toque` (0/0,45/60) | nada | `som_virtual(l).falante > 0.05` nos dois pilotos na batida `g0 − 1`; o robô só soca se ouviu |
| o soco entra | quem soca: `acerto` (0,3/0,6/80) | os atingidos: `golpe` (1,0/0,6/250) | linha `sensacao` `golpe` nos dois da outra equipe; linha `jogo` `soco` `entrou` |
| a cabeçada | `mod_sino` 0,7 nos dois alto-falantes no mesmo quadro; `golpe` nos dois | nada | `som_virtual` com `falante > 0.05` nos dois pilotos no mesmo quadro; `sensacao` a até 16,7 ms do `momento` |
| a queda | `explosao` (1,0/1,0/400) nos dois pilotos do que caiu | nada | linha `sensacao` `explosao` |
| a barra de luz | a cor do lugar, sempre | o mesmo | `percepcao(l).luz` na cor do lugar em ≥ 75 % das amostras |
| as luzinhas | o número do jogador, sempre | o mesmo | `leds_jogador == Forja.LEDS_DO_LUGAR[l]` |
| o microfone | Não se aplica: a sincronia é do dedo, e a voz de uma dupla seria ouvida pela outra no sofá | — | — |

**No rádio** (sem háptica): a perna vai pelo rumble do lado, com a `troca` uma vez. Sem alto-falante: o gongo vira
`toque`, e o clang da cabeçada não vai (o `golpe` já está na mão). O R2 e o tremor do parceiro vão pela ponte.

## O cavaleiro

- **Os stats** (`minigames.csv`, linha 43), todos pela média da dupla (o Aprendiz conta como neutro):
  - Peso: `tranco` no soco que a dupla dá (×0,84 a ×1,16 do stat 1 ao 5) e `empurrao` no que ela leva (×1,16 a
    ×0,84). Uma dupla leve atingida por uma pesada vai 1,5 × 1,16 × 1,16 = 2,02 m para trás; uma pesada atingida por
    uma leve, 1,5 × 0,84 × 0,84 = 1,06 m. Do ringue em diante, o limite de \|x\| ≤ 1,6 corta o empurrão.
  - Passo: `velocidade` no passo do mecha (×0,94 a ×1,06): o passo BOM vai de 0,28 m a 0,32 m.
  - Fôlego: `levantar` na queda dos pilotos depois da cabeçada, 2 tempos × 1,25 a × 0,75 (1,03 s a 0,62 s,
    arredondados à semicolcheia). Com 1,25, a dupla perde o passo de `g0 + 2`; com 0,75, não perde nenhum.
  - Faro: `pista` adianta o gongo de cada piloto, −40 a +40 ms (por piloto, não pela média); o soco cai no mesmo tempo.
  - Nenhum stat mexe na janela de julgamento, no `SINC` nem nos pontos.
- **A conta:** `_gancho(l, nome)` devolve o neutro até existir `Cavaleiro.gancho`; com ele, a conta é
  `neutro + por_ponto × (stat − 3)`.
- **Como aparece:** o cavaleiro entra como a G13 o montou (a raça, a cabeça, o superior em tecido L 0,46 a 0,58, o
  inferior em couro L 0,22 a 0,36), sem tinta do minigame. O néon do dono é o friso e a costura a 1,6 e o contorno a
  2,4; a runa da perna do mecha acende na cor dele a 2,0. A raça não muda a posição no ombro, a velocidade nem a janela.
- **O item:** fica onde a G13 o pôs (a arma na mão direita, o Escudo no braço esquerdo, o amuleto no peito);
  `attack-melee-right` usa a arma da mão.
- **O Aprendiz:** `character-human.glb` com `_tingir(modelo, Tema.ETIQUETA_SOMBRA)`, sem contorno e sem acento, como na
  Q1.

## As reações

- **Adesivo:** nenhum durante o jogo; todos jogam a partida inteira.
- **Os carimbos que este minigame pode disparar** (o jogo detecta pelo registro):

  | carimbo | o evento aqui | onde |
  | --- | --- | --- |
  | `car_acorde` | os quatro com PERFEITO na mesma batida de tempo 1: o soco cai em `g0 = 4 + 8k` (e `g0 + 4` na reta), sempre com `floor(b) % 4 == 0`, quando os quatro apertam no PERFEITO | centro da tela, y 300 |
  | `car_em_chamas` | 5 PERFEITOs seguidos do mesmo lugar | acima da cabeça dele |
  | `car_por_um_fio` | a equipe vence com 2 % dos pontos ou menos de diferença | acima da cabeça do vencedor, no resultado |

  Quando dois disputam a vez: `car_acorde` > `car_em_chamas` > `car_por_um_fio`.

## A diversão

**O grito: o soco na própria cabeça** (`autossoco`). Fora de sincronia, o braço do mecha dá a volta e acerta a própria
cabeça, com o clang nos dois controles da dupla. É a piada da seção. Degrau estrondo.

- **O grito acontece no meio da tela:** a cabeça do mecha a 8 m cai em `x_tela` 0,22 e 0,78, e no ringue entre 0,40
  e 0,60; a cabeça (0,7 m a 17 m, 27°) tem `altura_tela` 0,086 ≥ 0,08 na prancha de 480 × 270.
- **Rastro:** a cabeça fica torta 30° e amassada até a próxima queda; o mecha fica com meio abalo.
- **Quem perde ainda bate:** a queda não acaba o duelo; a primeira equipe com 2 quedas vence, e nas últimas 16 batidas
  um soco sincronizado derruba quem estiver na frente.
- **Como o jogador do time confere:**
  1. mesa das duplas (P1 `bom` e P2 `ruim` na Brasa contra P3 `medio` e P4 `medio`, semente 7): pelo menos 2 linhas
     `momento` `autossoco` em 100 s, pelo menos 1 com `lugar` 0 ou 1 (a dupla com o P2 `ruim`);
  2. cada `momento` `autossoco` tem uma `sensacao` do mesmo lugar a até 16,7 ms, e o `t_musica` cai a até 1 quadro de
     uma colcheia;
  3. na prancha da mesa das duplas, um mecha com a cabeça torta em pelo menos 1 quadro de cada 4.

## Pronto quando

O `S09_J43` joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o Aprendiz) e com o robô nos três temperamentos
(o ruim se esmurra), aguenta o cabo que cai e volta, fecha com uma equipe vencedora, deixa o R2 em Arma (0x25) fora do
tremor do parceiro, faz pelo menos 2 `autossoco` na mesa das duplas, e o mecha não tem nenhum hex; as provas abaixo
passam e a prancha foi olhada.

## Provas

Em `godot/testes/prova_do_jogo.gd`, com a linha `"S09_J43": await _prova_mecha()` no `match` de
`_prova_da_ficha(slot)`:

```gdscript
## S09_J43: o R2 de cada um em arma; a perna treme só o atuador do lado
## dela; o R2 treme com o parceiro pronto; a sincronia corta entre 80 e 100 ms.
func _prova_mecha() -> void:
	var conta := {"arma": [false, false, false, false], "perna": false, "parceiro": false, "torta": 0, "amostras": 0}
	var olhar := func(mg: Minigame) -> void:
		conta.amostras += 1
		if mg._torta[0] or mg._torta[1]:
			conta.torta += 1
		for l in mg.presentes():
			var g := int(Forja.percepcao(l).get("gatilho_dir", 0))
			if g == 0x25:
				conta.arma[l] = true
			elif g == 0x26:
				conta.parceiro = true
			var v := Forja.som_virtual(l)
			var meu := float(v.get("esq" if mg._perna[l] == 0 else "dir", 0.0))
			var outro := float(v.get("dir" if mg._perna[l] == 0 else "esq", 1.0))
			if meu > 0.05 and outro < 0.02:
				conta.perna = true
	var mg := await _joga_o_minigame("S09_J43", 150.0, olhar)
	if mg == null:
		return
	for l in mg.presentes():
		_esperar(conta.arma[l], "S09_J43: o R2 de P%d em arma (0x25)" % (l + 1))
	_esperar(conta.perna, "S09_J43: a perna treme só o atuador do lado dela")
	_esperar(conta.parceiro, "S09_J43: o R2 tremeu com o parceiro pronto (0x26)")
	_esperar(mg.sincronizados(0.0, 0.08) and not mg.sincronizados(0.0, 0.10), "S09_J43: a sincronia corta entre 80 e 100 ms")
```

No `_prova_do_relatorio()`, com as linhas do `S09_J43`:

- há `pista` com `o_que` `gongo` e com `o_que` `E` e `D`;
- cada `momento` `autossoco` tem `sensacao` `golpe` do mesmo lugar a até 16,7 ms;
- cada linha `jogo` `soco` com `resultado` `entrou` tem `dif_ms` ≤ 90, e cada `autossoco` com os dois apertos tem
  `dif_ms` > 90;
- nenhuma `sensacao` e nenhum `som_controle` de háptica no mesmo controle e no mesmo quadro.

Os comandos:

```bash
SALA=S09_J43 bash tests/prova_do_jogo.sh
bash tests/prova_visual.sh
bash tests/prova_sem_rastro.sh
```

A mesa das duplas pede o robô por lugar (`--robo=bom,ruim,medio,medio --semente=7`), que a F09 ainda não tem: até
existir, a checagem da diversão roda com `--robo=medio --semente=7`, e o mínimo de 2 `autossoco`, com pelo menos 1 de
lugar 0 ou 1, vale igual. O `conta.torta * 4 >= conta.amostras` da prova é a mesma conta da prancha.

**As pranchas que se olham** (`SAIDA/prancha-<n>.png`):

- a de quatro com `bom`: os dois mechas de três quartos, as duas pernas de cada um na cor do piloto, um braço esticado;
- a de quatro com `ruim`: um mecha com a cabeça torta e amassada, o visor violeta;
- a de dois e a de um: o Aprendiz em `ETIQUETA_SOMBRA` no ombro, a perna dele sem brilho;
- a do cabo que cai: a runa da perna do caído apagada;
- nas quatro: as roupas de cima e de baixo de cada cavaleiro em valores diferentes, e o néon só no friso e na costura.

**Com o André (local):** `./run-local.sh -- --sala=S09_J43`, duas duplas, uma no cabo e uma no rádio. O pingue-pongue
das pernas tem de virar dança; o tremor do parceiro tem de dizer «ele está pronto» sem roubar o clique; a cabeçada tem
de fazer a sala rir. No registro, compare o `dif_ms` dos socos do cabo e do rádio.
