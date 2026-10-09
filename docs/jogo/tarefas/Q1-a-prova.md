# Q1 — A Prova

**Sprint:** Q · **Slot:** S09_J41 · **Tamanho:** G · **Depende de:** H04, H08, H07, F01, F04, F05 (`Forja.sentir`), F09 (`Forja.robo_acerta`), G03, G05, G13, G14, G15 · **Vem pela G13:** G10 (o Castle Kit e `Kit.caminho`; a reserva fica para o `.glb` que faltar)

## Por quê

A sala de hoje (`godot/scripts/salas/prova.gd`, 911 linhas) é um tiroteio livre de 90 s com a munição nas luzinhas;
no kit ela vira um cabo de guerra no ritmo, Brasa contra Maré, em que a frente cruza o meio pelo menos 2 vezes em
90 s e a sala de uma dupla grita a cada virada.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (onde mora, a FICHA, o robô, o registro, a prova)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) e [as decisões comuns da H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
- `godot/scripts/salas/prova.gd`, só as funções que ficam (a tabela «O que sai do prova.gd» diz as linhas)

Tudo o mais que esta ficha usa (as cores, o brilho, a câmera, o movimento, o som, os stats, a régua da diversão)
está escrito aqui dentro, com o número.

As duas curvas do movimento (do 05): `ENTRA_SAI` é um `Tween` com `TRANS_SINE` e `EASE_IN_OUT`; `MOLA` é
`TRANS_BACK` com `EASE_OUT` (passa 4 % do alvo e volta).

## Arquivos que mudam

- `godot/scripts/minigames/s09/a_prova.gd` (novo, `extends Minigame`, sem `class_name`) e o `.uid` que o Godot gera.
- `godot/scripts/minigames/catalogo.gd`: o slot em `MINIGAMES`, a seção `S09`, `"prova"` fora de `SALAS_ANTIGAS`.
  **De todos:** Q2, Q3, Q4 e Q5 também mudam este arquivo.
- `godot/scripts/traducoes.gd`: as frases da tabela «As frases». **De todos:** Q2 a Q5.
- `godot/scripts/minigames/minigame.gd`: `"momento"` em `TIPOS_DO_JOGO`, se ainda não estiver (a J1 e a O1 também
  põem). A Q2 a Q5 dependem da Q1 e conferem que está lá.
- `godot/testes/minigame_de_tempo.gd` e `godot/testes/prova_do_jogo.gd`, só se esta ficha pôs o `"momento"`: o passo 4
  de «A casa nova e o catálogo».
- `docs/jogo/13-arquitetura.md`: a linha `momento` na tabela do registro v2, no mesmo commit da linha acima, se ainda
  não estiver.
- `godot/testes/prova_do_jogo.gd`: `_prova_a_prova()` no lugar do bloco «A Prova» de hoje, a linha no `match` de
  `_prova_da_ficha` e a checagem do relatório. **De todos:** Q2 a Q5.
- `git rm godot/scripts/salas/prova.gd godot/scripts/salas/prova.gd.uid`.

## Como se joga

**Empurre!** Brasa contra Maré numa faixa de 12 lajes. Cada nota certa empurra a frente para o lado de lá, cada erro
cede terreno. O martelo (✕) e a besta (R2 até o clique) se revezam; da reta em diante, quem ouve o sino no próprio
controle tem a martelada (o clique do touchpad).

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J41",
	"titulo": "A Prova",
	"verbo": "Empurre!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [Forja.CRUZ, Forja.TOUCHPAD],
	"camera": "fixa",
	"faixa": "MUS_S09_J41",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir", "explosao", "aviso"],
	"material": "metal",
	"microjogo": {"verbo": "Empurre!", "segundos": 6.0},
	"features": ["tudo_junto"],
	"botoes_medidos": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.TOUCHPAD],
	"gesto": "holding-right-shoot",
	"treino": false,
}
```

As entradas são três: o ✕, o R2 (eixo, fora da lista) e o touchpad. Sem treino: é o fim da noite.

### O tempo

A faixa `MUS_S09_J41` tem 145 BPM: uma batida dura 0,4138 s. `BATIDA_DA_PRIMEIRA_NOTA` é 4 (do kit).
`PARTIDA := 212` batidas: a partida acaba na batida 216, aos 89,4 s de música, dentro dos 90 s da FICHA.

| constante | valor | o que é |
| --- | --- | --- |
| `PARTIDA` | 212 | batidas de jogo depois da primeira nota |
| `LAJE` | 1,833 m | a largura de uma laje (22 m ÷ 12) |
| `EMPURRA` | `[0.0, 0.10, 0.15, 0.22]` | lajes por julgamento (perdida, ok, bom, perfeito) |
| `ESPECIAL` | `[0.0, 0.8, 1.2, 1.5]` | lajes da martelada |
| `CEDE` | 0,12 | lajes que o erro ou a nota perdida devolve |
| `PONTOS` | `[0, 50, 75, 100]` | pontos da equipe por julgamento |
| `TETO_ANTES_DA_RETA` | 2,0 | a frente não passa de ±2 lajes antes do compasso 36 |
| `NOCAUTE` | 6,0 | ±6 lajes da reta em diante: aquela equipe venceu |
| `PICO_DE`, `PICO_ATE` | 26, 30 | os compassos do pico (batidas 108 a 123, 44,7 s a 51,3 s) |
| `RETA_DE` | 36 | o compasso da reta (batida 148, 61,2 s) |
| `DOBRO_DE` | 200 | a batida em que começam as últimas 16 (82,8 s) |
| `HISTERESE` | 0,25 | lajes além do meio para contar a virada |
| `MARCAS` | 48 | o máximo de marcas de pé no chão |
| `ACERTO_APRENDIZ` | 0,8 | a chance de o Aprendiz acertar (sempre como BOM) |

### As regras

- **As equipes:** `presentes()` na ordem; os dois primeiros são a Brasa, os dois seguintes a Maré. O kit as monta
  (`montar_equipes`, `equipe[l]`, `aprendizes[e]`). Em cada equipe, o primeiro é **A**, o segundo **B**.
- **A frente:** `_frente`, em lajes, começa em 0. A Brasa empurra para `+` (para a direita, o lado da Maré), a Maré
  para `−`. Antes do compasso 36, `_frente` fica em `clampf(_frente, -2.0, 2.0)`; dali em diante, em ±6.
- **O compasso** `m` começa na batida `c0 = 4 + 4·m`. A toca nas batidas `c0` e `c0 + 2`, B nas `c0 + 1` e `c0 + 3`
  (o hoqueto dentro da equipe); as duas equipes tocam ao mesmo tempo. Cada nota abre 1 batida antes do alvo.
- **As armas se revezam de dois em dois compassos:** `(m / 2) % 2 == 0` é o **martelo** (✕ no tempo); senão, a
  **besta**: o aperto é o quadro em que `Forja.eixo(l, Forja.R2)` passa de 0,6 subindo (`r2 > 0.6 and r2_ant <= 0.6`,
  como em `prova.gd:407`).
- **O julgamento:** `julgar_toque(l, t_alvo, n)`. O acerto empurra `EMPURRA[j]` para o lado de lá e marca
  `PONTOS[j]` na equipe (`marcar_equipe`). O erro ou a nota que passou (140 ms depois do alvo, `FOLGA_PERDIDA`) cede
  `CEDE` para o próprio lado.
- **A martelada** (só da reta em diante): nos compassos 35, 39, 43, 47 e 51 (`m >= 35 and m % 4 == 3`), em cada
  equipe, o lugar com mais PERFEITOs nas últimas 16 batidas (no empate, o primeiro de `presentes()`) ouve o sino na
  colcheia `c0 + 0,5`, só no próprio controle. A nota dele na batida `c0` do compasso seguinte (36, 40, 44, 48, 52) é a
  martelada: o clique do touchpad no tempo, no lugar do ✕ ou do R2. Julgada, empurra `ESPECIAL[j]`. A TV não diz
  quem tem: a martelada não tem dica.
- **O golpe que vem de um lado:** em cada PERFEITO de uma equipe, o membro da outra que não toca naquela batida sente
  de onde veio: a Maré sente `golpe_esq` (a Brasa está à esquerda), a Brasa sente `golpe_dir`. No pico todos tocam
  todas as batidas: não há golpe do lado no pico.
- **O pico, tudo junto** (compassos 26 a 29): os dois membros tocam as quatro batidas, e a arma troca a cada batida
  (martelo nas pares, besta nas ímpares; o R2 fica em Arma o pico todo).
- **A reta:** da batida 200 à 215, `EMPURRA` e `ESPECIAL` valem o dobro, e no primeiro quadro da batida 200 sai
  `anotar("momento", -1, {"nome": "reta", "lugar": -1, "t_musica": Ritmo.t_musica(), "objeto": {"empurra": 2.0}})`.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar toca só a primeira das suas duas notas em cada compasso.
- **O nocaute:** `absf(_frente) >= 6.0` → aquela equipe venceu; a partida acaba 4 batidas depois.

### A curva

| trecho | batidas | o que acontece |
| --- | --- | --- |
| 0 a 30 s | 0 a 72 | o martelo e a besta se revezam; a frente presa em ±2 |
| 30 a 60 s | 73 a 147 | o pico, tudo junto (compassos 26 a 29); a frente ainda em ±2 |
| 60 s ao fim, a reta | 148 a 215 | o teto vai a ±6 (o nocaute vale); a martelada nos compassos 36, 40, 44, 48 e 52; da batida 200 em diante, o dobro |

**Ensina sem falar:** na contagem do kit (antes da batida 4), a runa da frente anda +0,1 laje na batida 1 e volta
−0,1 na batida 2, num `Tween` de 1 colcheia com `MOLA`. Só imagem: nada soma.

### A virada (o momento)

`_lado` começa em 0. A cada quadro: se `_frente >= 0.25` e `_lado == -1`, a Maré cedeu; se `_frente <= -0.25` e
`_lado == 1`, a Brasa cedeu. Nos dois casos, e só no primeiro quadro de uma batida nova (`floor(b) != floor(b_ant)`),
sai a virada; depois `_lado = signf(_frente)`. O primeiro cruzamento de ±0,25 só acerta o `_lado`, sem virada.

Na virada, no mesmo quadro:

1. `anotar("momento", lugar, {"nome": "virada", "lugar": lugar, "t_musica": Ritmo.t_musica()})`, com `lugar` = o
   A presente da equipe que cedeu; se ela só tem Aprendizes, `lugar` = −1.
2. A sensação: `Forja.sentir(l, "golpe_esq")` nos presentes da Maré quando a Maré cedeu, `golpe_dir` nos da Brasa
   quando a Brasa cedeu; com `lugar` −1, `Forja.sentir(l, "golpe")` em todos os presentes.
3. O degrau: **golpe** fora do pico, **estrondo** no pico (tabela abaixo).
4. As lajes do meio (as de índice 5 e 6) trocam de cor para a da equipe que virou (é o rastro que a prancha confere).
5. A luz: o preenchimento (`environment.ambient_light_energy`, ver «A cena») vai a ×0,7 por 1 batida e volta em 1 batida; o contorno dos
   dois da equipe que virou vai de 2,4 a 3,0 no mesmo tempo.

| degrau | o tremor | a parada | o que se vê | a consequência |
| --- | --- | --- | --- | --- |
| golpe (fora do pico) | `tremer(TREMOR_GOLPE)`: 0,02 m, 1 batida | 2 quadros: `p.anim.speed_scale = 0` nos quatro cavaleiros | a runa da frente a 130 % de escala em x por 1 batida | o chão do meio troca de cor; 2 marcas de pé por cavaleiro que cedeu |
| estrondo (no pico) | `tremer(TREMOR_ESTRONDO)`: 0,05 m, 2 batidas | 3 quadros | 48 faíscas `Efeitos.faiscas(self, Vector3(x_frente, 0.1, 0), CORES_DAS_EQUIPES[e_virou], 48, 1.0)` | 4 batidas com a luz a ×0,7 nas lajes de quem cedeu; as marcas ficam até o fim |

O `tremer` é da câmera (G05): o abalo decai sozinho no tempo do degrau, e com `Opcoes.movimento == 1` a câmera não
treme. A ficha chama `tremer` igual; com `Opcoes.movimento == 1`, ela tira a parada, e a runa vai a 105 % em vez de
130 %.

### A falha

A falha cede terreno: o erro (ou a nota que passou) leva a frente 0,12 laje para o próprio lado. O cavaleiro que errou:

- desliza 0,5 m para trás em 1 batida, com `ENTRA_SAI`, e volta ao lugar na batida seguinte (a frente andou junto);
- treme de lado ±0,02 m por 3 quadros, e a animação vai a 0,5× por 1 batida (sem squash);
- no martelo, faz `attack-melee-left` em 0,5 batida (o martelo quica); na besta, o virote cai aos pés:
  `Efeitos.faiscas(self, pos_do_pe, Tema.GRAFITE, 8, 0.4)`;
- **a queda:** fica caído `_queda_s(l)` (1 batida × `levantar`, arredondada à semicolcheia, no mínimo 1 semicolcheia;
  ver «O cavaleiro»); a nota do papel dele que cairia dentro da queda não abre (não empurra nem cede). Fora do pico, a
  próxima nota dele está 2 batidas depois e a queda não a pega.

### O fim e o vencedor

A partida acaba na batida 216 (ou 4 batidas depois do nocaute): a frente para, o R2 de todos volta a `GATILHO_OFF`, e
o kit toca o apito. Sem a bancada, todos acabam ali.

O vencedor: `_frente > 0` → a Brasa; `_frente < 0` → a Maré; `_frente == 0` → `equipe_vencedora()` (a de mais
pontos; no empate, a Brasa). `vencedor()` devolve os lugares da equipe vencedora (por pontos) e depois os da outra.

### Com menos de quatro

| jogadores | Brasa | Maré | `com_poucos()` |
| --- | --- | --- | --- |
| 4 | 1º e 2º | 3º e 4º | — |
| 3 | 1º e 2º | 3º e o Aprendiz | `"Com o Aprendiz"` |
| 2 | 1º e o Aprendiz | 2º e o Aprendiz | `"Com o Aprendiz"` |
| 1 | 1º e o Aprendiz | dois Aprendizes | `"Você e o Aprendiz contra 2"` |

O Aprendiz faz o papel dele acertando `ACERTO_APRENDIZ` das vezes, sorteado com o `rng` do kit, sempre como BOM:
empurra ou cede como qualquer um, nunca ouve o sino, não é lugar, não pontua, não entra no registro de notas e não é
robô. Uma equipe só de Aprendizes não tem martelada.

**O controle que cai:** as notas dele não abrem (a equipe não empurra nem cede por ele), o sino não vai para ele, o
`_saida` não conta a saída de quem está sem controle. Volta no compasso seguinte.

### A bancada (só com `Forja.bancada`)

Depois do apito, a prova final às cegas de hoje, sem mudar a regra: `_perguntar_leds()` (`prova.gd:545`),
`_perguntar_cor()` (`:565`), `_rodada_final()` (`:585`), `_sem_revelar()` (`:684`) e `pergunta(l)` (`:787-827`), com
o tempo delas pelo `dt`. Duas trocas:

- a luzinha sorteada nunca é a do próprio lugar (`while k == l + 1`);
- a cor sorteada nunca é a parecida com a do lugar: `COR_PARECIDA_DO_LUGAR := [1, 0, -1, 2]`.

Depois da cor, `Forja.luz_do_lugar(l)` e `Forja.leds_do_lugar(l)`, e todos acabam. A bancada passa dos 90 s: o fim
por `tempo` do kit não pode cortá-la (a bancada só acrescenta camadas). Se a H08 cortar, pare e anote no quadro.

`dar_vereditos(l)`: `Forja.carga_parar(l)`, `Forja.carga_placar(l, tocadas, acertadas, marteladas)` e
`Forja.carga_veredito(l, leds, cor, tocadas > 0 or Cega.total(leds) > 0)`, o de hoje (`prova.gd:691-701`).

### O robô

Toca pelo relógio da música, pelo controle simulado. Ouve o sino no alto-falante da placa virtual
(`Forja.som_virtual(l).falante > 0.05`): um defeito de mentira no alto-falante faz ele perder a martelada. Na bancada,
olha as luzinhas e a luz dele (a `percepcao`, como hoje). Sorteia num gerador próprio
(`_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`), para não mudar o que o jogo sorteia.

```gdscript
func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	if _acabou_a_partida:
		if Forja.bancada:
			_robo_prova_final(l, dt)       # o ramo LEDS/COR do _robo de hoje (prova.gd:843-865)
		return
	if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
		_robo_ouviu_sino[l] = _m
	var n: int = _nota[l]
	if n < 0 or _robo_tocou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.25 if _robo_rng.randf() < 0.6 else 99.0)
	if Ritmo.t_musica() < float(_alvo[l]) + float(_robo_mira[l]):
		return
	if _arma_da_nota[l] == MARTELADA:
		if _robo_ouviu_sino[l] == _m - 1:
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
	elif _arma_da_nota[l] == BESTA:
		Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
	else:
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
	_robo_tocou[l] = n
```

### Os ganchos

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

`godot/scripts/minigames/s09/a_prova.gd`:

```gdscript
extends Minigame
## A Prova (S09_J41). Brasa contra Maré, no ritmo: cada nota certa empurra a
## frente para o lado de lá, cada erro cede terreno. O martelo (✕) e a besta
## (R2 até o clique) se revezam; da reta em diante, quem ouve o sino no próprio
## controle tem a martelada (o touchpad).
##
## A falha: cede terreno, recua 0,5 m e cai 1 batida × levantar.
## O vencedor: a equipe com a frente no lado de lá (ou o nocaute).
## O alto-falante do dono: o sino da martelada, o clique da besta.
## O registro mede: a carga dos quatro (carga_*), o sino (pista), a resposta,
## a virada (momento); na bancada, as luzinhas e a cor depois da carga.
## O robô: toca pelo relógio e ouve o sino na placa virtual.
## Com menos de quatro: o Aprendiz completa.
## A régua: a cor da equipe está no chão; a barra e as luzinhas são do lugar.

const FICHA := { ... }   # a de «A ficha de dados»

enum { MARTELO, BESTA, MARTELADA }
# as constantes de «O tempo», e as da prova final de hoje (CORES, BOTAO, GLIFO, PERGUNTA_ESPERA, PERGUNTA_S)
const COR_PARECIDA_DO_LUGAR := [1, 0, -1, 2]
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}

var _frente := 0.0
var _lado := 0
var _m := -1
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _arma_da_nota := [MARTELO, MARTELO, MARTELO, MARTELO]
var _n := [0, 0, 0, 0]
var _r2_antes := [0.0, 0.0, 0.0, 0.0]
var _caido_ate := [-1.0, -1.0, -1.0, -1.0]   ## o t_musica em que o cavaleiro levanta
var _perfeitos := [[], [], [], []]           ## as batidas dos PERFEITOs de cada um
var _sino := [-1, -1]                        ## equipe -> o lugar que ouviu o sino neste ciclo
var _tocadas := [0, 0, 0, 0]
var _acertadas := [0, 0, 0, 0]
var _marteladas := [0, 0, 0, 0]
var _marcas := []                            ## as marcas de pé, no máximo MARCAS
var _fim_batida := 216.0
var _acabou_a_partida := false
var fin := {}                                ## a prova final (a de hoje)
var etapa := 0
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_tocou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_ouviu_sino := [-9, -9, -9, -9]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 15.07, 13.66)   # a G05 recua ×1,0616 a 35 mm: a câmera fica em (0, 16, 14,5)
	camera_olhar = Vector3(0, 0, 0)
	_montar_cena()                # «A cena»
	_formar_aprendizes()          # os bonecos no lugar de quem falta


func iniciar_jogo() -> void:
	_robo_rng.seed = rng.seed + 99
	for l in presentes():
		fin[l] = {"leds": Cega.nova(), "cor": Cega.nova(), "leds_pedido": -1, "cor_pedida": -1, "resp": -1,
			"t": 0.0, "robo_espera": -1.0}
		Forja.carga_comecar(l)
		_saida(l, Forja.gatilho(l, 1, Forja.GATILHO_OFF))


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	if not _acabou_a_partida:
		if b >= 4.0 + 4.0 * (_m + 1) - 1.1:
			_novo_compasso(_m + 1)   # 1,1 batida antes: a arma, o sino agendado
		for l in presentes():
			if not conectado(l):
				_nota[l] = -1
				continue
			_trocar_gatilho(l)        # na hora do lugar: 1 batida + pista antes do bloco
			_abrir_nota(l, b)         # a próxima nota do papel dele, 1 batida antes; nada se está caído
			_entrada(l)               # ✕, R2 cruzando 0,6 (e o clique), touchpad: julgar_toque
			_prazo(l)                 # a nota que passou: CEDE; na martelada, _respondeu(l, n, "nenhuma")
		_aprendizes_tocam(b)
		_virada(b)                    # «A virada»
		if b >= _fim_batida:
			_apito()                  # _acabou_a_partida = true; R2 solto; sem a bancada, acabou de todos
	elif Forja.bancada:
		_prova_final(dt)              # LEDS → COR → a luz e as luzinhas do lugar → acabou de todos
	_mostrar(b)


func toque(l: int, j: int) -> void:
	var dobro := 2.0 if Ritmo.batida() >= DOBRO_DE else 1.0
	marcar_equipe(equipe[l], PONTOS[j])
	_acertadas[l] += 1
	var e: int = equipe[l]
	if _arma_da_nota[l] == MARTELADA:
		_marteladas[l] += 1
		_respondeu(l, _n[l] - 1, "certo")
		_empurrar(e, ESPECIAL[j] * dobro)
		_martelada_na_tv(e)          # o martelo, o tremor, a explosão na outra equipe na colcheia seguinte
	else:
		_empurrar(e, EMPURRA[j] * dobro)
	if j == Ritmo.PERFEITO:
		_perfeitos[l].append(Ritmo.batida())
		_golpe_do_lado(e)            # fora do pico: o membro da outra equipe que não toca agora


func falha(l: int) -> void:
	_ceder(equipe[l])
	_cair(l)                         # «A falha»


func vencedor() -> Array:
	var e := BRASA if _frente > 0.0 else (MARE if _frente < 0.0 else maxi(equipe_vencedora(), BRASA))
	var ganhou := presentes().filter(func(l): return equipe[l] == e)
	var perdeu := presentes().filter(func(l): return equipe[l] != e)
	ganhou.sort_custom(func(a, b): return pontos[a] > pontos[b])
	perdeu.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return ganhou + perdeu


func pergunta(l: int) -> Dictionary:
	if not Forja.bancada or not _acabou_a_partida:
		return {}
	return _pergunta_da_prova_final(l)   # a de hoje


func dar_vereditos(l: int) -> Array:
	if not fin.has(l):
		return []
	Forja.carga_parar(l)
	Forja.carga_placar(l, _tocadas[l], _acertadas[l], _marteladas[l])
	var v := Forja.carga_veredito(l, fin[l].leds, fin[l].cor, _tocadas[l] > 0 or Cega.total(fin[l].leds) > 0)
	return [] if v.is_empty() else [v]


func _gancho(l: int, nome: String) -> float:
	return float(NEUTRO[nome])   # troque por Cavaleiro.gancho(l, nome) quando `grep -rn "static func gancho" godot/scripts/` achar


func _pista(l: int, n: int, o_que: String) -> void:
	if Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE):
		_saida(l, Forja.som_falante(l, "pronto", 0.8))
		anotar("pista", l, {"n": n, "evento": "mandou", "canal": "alto_falante", "o_que": o_que})
	else:
		_saida(l, Forja.sentir(l, "aviso"))
		anotar("pista", l, {"n": n, "evento": "mandou", "canal": "rumble", "o_que": o_que})


func _respondeu(l: int, n: int, resposta: String) -> void:
	anotar("entrada", l, {"o": "resposta", "n": n, "resposta": resposta})
```

As outras funções, uma frase cada:

- `_saida(l, ok)`: a de hoje (`prova.gd:216-220`, `Forja.carga_saida` só com o cabo). Toda saída passa por ela.
- `_empurrar(e, d)`: `_frente` anda `d` para o lado de lá da equipe `e`, com o teto de «As regras»; a runa anda em 1
  colcheia por `lerpf`; confere o nocaute (`_fim_batida = minf(_fim_batida, floor(b) + 4)`).
- `_ceder(e)`: `CEDE` para o próprio lado, com o mesmo teto.
- `_novo_compasso(m)`: `_m = m`; a arma do compasso; se `m >= 35 and m % 4 == 3`, agenda o sino de cada equipe para a
  colcheia `c0 + 0,5`, que chama `_pista(l, n, "martelada")`.
- `_trocar_gatilho(l)`: na troca de bloco, quando `Ritmo.t_musica() >= t(c0) - 0.4138 - _gancho(l, "pista") / 1000.0`,
  `_saida(l, Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8))` (besta) ou `Forja.GATILHO_OFF` (martelo), uma vez
  por bloco.
- `_cair(l)`: `_caido_ate[l] = Ritmo.t_musica() + _queda_s(l)`, com
  `_queda_s(l) = maxf(0.1034, snappedf(0.4138 * _gancho(l, "levantar"), 0.1034))` (0,1034 s é a semicolcheia).
- `status(l)`: `"Brasa"` ou `"Maré"`. `progresso()`: nada (a frente é o placar).
- A dica, com `na_raia(l)`: o glifo da arma da nota aberta (`["@cross"]` ou `["@r2"]`) enquanto `not aprendeu(l)`.

### O que sai do `prova.gd`

| sai | por quê |
| --- | --- |
| `class_name SalaProva`, `_init()`, `_conectado`, `objetivo`, `CONTAGEM`, `PARTIDA_S` | o kit; a partida é pela batida |
| o tiroteio livre: `_jogador`, `_boneco`, `_mover_tiros`, o `_empurrar` de hoje, os pilares, `VEL`, a mira, a recarga | a partida é o cabo de guerra |
| `_mostrar_municao` e `_atualizar_luz` (`LUZ_EQUIPE`) | as luzinhas e a barra são do lugar (F04) |
| o L2 em resistência | o L2 é do item (G03) |
| `Forja.vibrar(...)` direto | `Forja.sentir(l, ...)` |
| o `_process` | o `_mostrar(b)` no fim do `jogar` |
| **fica:** `_saida` (216-220), a prova final (545-684), `dar_vereditos` (691-701), `pergunta` (787-827), `_cor_mais_perto` (828), o ramo LEDS/COR do `_robo` (843-865) | a bancada |
| **fica, com outra cor:** `_tingir` (200-213), só no Aprendiz, com `Tema.ETIQUETA_SOMBRA` | o boneco do jogo |

### A casa nova e o catálogo

1. Criar `godot/scripts/minigames/s09/a_prova.gd`; rodar `"$GODOT" --headless --path godot --import --quit` e commitar
   o `.uid`.
2. `catalogo.gd`: `"S09_J41": preload("res://scripts/minigames/s09/a_prova.gd")` em `MINIGAMES`;
   `"minigames": ["S09_J41"]` na seção `S09` (a Q2 a Q5 acrescentam depois); tirar `"prova"` de `SALAS_ANTIGAS`. O
   apelido `--sala=prova` abre o `S09_J41`.
3. `git rm godot/scripts/salas/prova.gd godot/scripts/salas/prova.gd.uid`; `grep -rn "SalaProva" godot/` vazio (a
   prova do jogo usa `SalaProva.PARTIDA`, `LUZ_EQUIPE` e `NOME_EQUIPE`: saem com as checagens novas).
4. Se `grep -n '"momento"' godot/scripts/minigames/minigame.gd` não achar nada (a J1 e a O1 ainda não entraram):
   `minigame.gd`: `"momento"` no fim de `TIPOS_DO_JOGO`; `13-arquitetura.md`: a linha
   `| momento | o pico de diversão (a régua 9) | nome, lugar (0..3, ou −1 quando é de todos), t_musica e, na reta, objeto |`
   na tabela do registro v2; `godot/testes/minigame_de_tempo.gd`, no `iniciar_jogo()`, depois da linha
   `anotar("entrada", ...)`: `anotar("momento", -1, {"nome": "prova", "lugar": -1, "t_musica": 0.0})`; e em
   `prova_do_jogo.gd` a mensagem `"registro: os seis eventos do jogo"` vira `"registro: os sete eventos do jogo"`. Sem
   a linha do `minigame_de_tempo.gd`, a prova da H08 (o T00_J01 grava todos os tipos de `TIPOS_DO_JOGO`) cai.

### As frases

| português | inglês |
| --- | --- |
| A Prova | The Trial |
| Empurre! | Push! |
| Brasa | Ember |
| Maré | Tide |
| Com o Aprendiz | With the Apprentice |
| Você e o Aprendiz contra 2 | You and the Apprentice against 2 |

Tire as frases do tiroteio que ninguém mais usa (`"recarregue"`, `"martelada!"`, `"%s · vida %d · %d balas"`).

### O registro

- a carga: cada `saida` (o gatilho a cada bloco, a vibração de cada golpe, a explosão) com `seq` e `ok`, dos quatro;
  `Forja.carga_*` soma as recusas (o veredito `tudo_junto` na bancada, a linha no relatório nos dois modos);
- `pista` do sino (`canal` `alto_falante` ou `rumble`) e a `entrada` `resposta` (`certo` ou `nenhuma`);
- `sensacao` `golpe_esq`, `golpe_dir`, `golpe`, `explosao` (do F05);
- `momento` `virada` e `reta`;
- `nota` e `toque` de todas as armas (o kit).

### Armadilhas

- **A barra de luz e as luzinhas não são da equipe.** Nenhum `Forja.luz` nem `Forja.leds_jogador` fora da prova final
  da bancada.
- **Rumble e háptica nunca no mesmo instante no mesmo controle:** o golpe do lado só vai a quem não toca na batida, e a
  explosão da martelada sai na colcheia seguinte ao toque.
- **O R2 não é botão:** não julgue a besta por `Forja.apertou`.
- **A partida acaba pela música:** a prova leva uns 90 s de relógio por rodada. Não encurte; se o `timeout 1200`
  apertar, anote no quadro.
- **`Forja.robo` só em `robo()`**; `_robo_prova_final` é chamado de dentro dele e não tem a palavra.

## A cena

- **A câmera:** a arena (35 mm, plongée de 47,8°, nunca corta). `camera_pos = Vector3(0, 15.07, 13.66)`,
  `camera_olhar = Vector3(0, 0, 0)`. No modo `"fixa"`, a G05 recua a câmera por `Lente.recuo(35)` = 1,0616 a partir do
  olhar: `olhar + (camera_pos − olhar) × 1,0616` = (0, 16, 14,5), que é onde se mediu. Medido por projeção com o campo vertical de 37,8° (o de 35 mm) e 16:9: as quinas
  da faixa (±11, 0, ±3,1) caem em x de 0,04 a 0,96 da tela; a frente no meio cai em (0,50; 0,50). Hoje o `fov` é 40°:
  a 40° a margem só cresce. Sem `camera_foco` (a arena não empurra).
- **A luz** (S9): a ficha não chama `Tema.luz_da_secao`. A entrada da sala chama `acender(9, partida.lado() == "B")` (G15 e
  G16): no lado A, densidade 0,012 e energia da chave 1,8; no lado B, 0,0156 e 1,53. A chave são as tochas de `luzes()`:
  o `Sala.acender(luz)` as pinta. Logo depois do `luzes(...)`, a ficha guarda em `_tochas` os `OmniLight3D` filhos da
  sala, menos o enchimento de cima, em (0, 9, 2). Quando a ficha mexe na chave, multiplica a `light_energy` das `_tochas`
  sobre a `energia_chave` que a G15 pôs. O preenchimento é `environment.ambient_light_energy` (0,42 pela G15) e a névoa
  é `environment.fog_density`, com `var environment := get_viewport().find_world_3d().environment`; os dois voltam ao
  valor de antes. As tochas de hoje: `luzes([Vector3(-10, 3, -6), Vector3(10, 3, -6), Vector3(-10, 3, 6),
  Vector3(10, 3, 6)])`. No pico (compasso 26), a `light_energy` das `_tochas` sobe 20 % em 1 batida e a `fog_density`
  vai a ×0,8; voltam em 2 batidas, num `Tween` sobre as `_tochas` e o `environment`.
- **A faixa de chão:** 12 lajes `Kit.caixa(self, Vector3(1.8, 0.04, 6.0), Vector3(-11.0 + 0.917 + 1.833 * i, 0.02, 0), mat)`.
  À esquerda da frente, `Kit.material(CORES_DAS_EQUIPES[BRASA], 0.0, 0.9)`; à direita, `CORES_DAS_EQUIPES[MARE]`
  (as do kit, impressas, energia 0, sem glow); a laje da frente, meio a meio.
- **A runa da frente:** `Kit.caixa(self, Vector3(0.12, 0.06, 6.2), Vector3(_frente * LAJE, 0.05, 0), mat)` com
  `Tema.neon(Tema.TUNGSTENIO, 1.0, "forja")` (o tungstênio é do dono `"forja"`, teto 2,4; o `"mundo"` é o violeta).
- **As bases:** a bandeira `Kit.peca(self, "banner", Vector3(±10.2, 0, -2.6), 0.0, 1.0)` (Mini Dungeon, em
  `godot/assets/kenney/mini-dungeon/` depois da G10) e, atrás dela, a torre `_peca("castle-kit/tower-base", "column", Vector3(±10.2, 0, -4.4))`
  (Castle Kit, da G10). `_peca(nome, reserva, pos)` usa `nome` se
  `ResourceLoader.exists(Kit.caminho(nome))`, senão a reserva (o `Kit.caminho` é da G10: sem barra, o Mini Dungeon;
  com barra, a pasta do pacote).
- **Os cavaleiros:** `p.preso = true`, `p.controlavel = false`; a Brasa em `x = fx - 1.6`, a Maré em `x = fx + 1.6`
  (`fx` = o x da frente; o x fica em ±10,4), A em `z = -1.2`, B em `z = 1.2`, de frente para a frente (`olhar_para`).
  Sob cada um, o disco `Kit.cilindro(self, 0.7, 0.02, pos, Kit.material(CORES_DAS_EQUIPES[e], 0.0, 0.9))`.
- **As armas na mão:** martelo: `attack-melee-right`; besta: `holding-right-shoot` e um virote
  (`Kit.caixa` 0,5 × 0,08 × 0,08 com `Tema.neon(Tema.JOGADOR[l], 2.0, l)`, 2,6 por 4 quadros no acerto) que voa até a
  frente em meia batida.
- **O golpe:** antecipação de 1 colcheia (escala Y 0,96), impacto de 3 quadros (Y 0,80, X e Z 1,12), recuperação
  `MOLA`. Faíscas do acerto: `Efeitos.faiscas(self, ponta, Tema.JOGADOR[l], 12, 0.6)` a 2,4 por 12 quadros.
- **As marcas de pé:** `Kit.caixa(self, Vector3(0.18, 0.005, 0.30), pos, Kit.material(Tema.GRAFITE, 0.0, 1.0))`, duas
  por cavaleiro que cedeu, onde ele estava; no máximo 48 (a 49ª apaga a mais velha).
- **Os brilhos e os donos:**

  | o quê | dono | energia |
  | --- | --- | --- |
  | o contorno de cada cavaleiro | o lugar | 2,4; 3,0 por 1 batida na virada |
  | o acento da peça (friso, costura, runa do item) | o lugar | 1,6 (o da G13) |
  | o virote | o lugar | 2,0; 2,6 por 4 quadros no acerto |
  | as faíscas do acerto | o lugar | 2,4 por 12 quadros |
  | a runa da frente | `"forja"` | 1,0 |
  | as lajes, os discos, as bandeiras, as marcas | ninguém | 0 (impressos) |

- **O que sai:** os pilares e a bala esférica de hoje, a `atmosfera` com `Tema.LARANJA`, a `poeira` com `Tema.CIANO` e o
  `pulso_de_luz(Tema.AMARELO)`.

## O som

| quando | onde | id do mapa | como |
| --- | --- | --- | --- |
| a partida | TV | `mus_s09_j41` (145 BPM, Mi menor; reserva `sint_trilha`) | a FICHA, `"faixa": "MUS_S09_J41"` |
| o acerto do martelo | TV | `martelo_0` a `martelo_4` (reserva `sint_martelo`) | `Som.tocar("martelo", pos, -6.0)` |
| o virote | TV | `tiro_0` | `Som.tocar("tiro", pos, -10.0)` |
| a entrada do pico | TV | `especial_0` | `Som.tocar("especial")` |
| a virada | TV | `golpe_0` a `golpe_4` | `Som.tocar("golpe", Vector3(x_frente, 0, 0), -4.0)` |
| a martelada | TV | `martelo_0` a `martelo_4` | `Som.tocar("martelo", Vector3(x_frente, 0, 0), 2.0)` |
| o sino da martelada | controle do dono | `mod_pronto` | `Forja.som_falante(l, "pronto", 0.8)`, na colcheia `c0 + 0,5` |
| o clique da besta | controle do dono | `mod_clique` | `Forja.som_falante(l, "clique", 0.6)` |
| a nota do perfeito, a quebrada do erro | controle do dono | `mod_nota_p1..p4`, `mod_nota_quebrada_p1..p4` | o kit |
| o apito, a vitória | TV | `jin_apito`; `vitoria_sala_0`/`1` (reserva `sint_sucesso`) | o kit |

O alto-falante toca um som por vez: vitória > julgamento > segredo > pio > coleta > clique. O sino (segredo) cai numa
colcheia, onde ninguém tem nota; o clique cede ao julgamento no mesmo quadro.

## O controle

| evento | quem joga | os outros | prova sem a mão |
| --- | --- | --- | --- |
| bloco de besta (compassos com `(m / 2) % 2 == 1`, e o pico inteiro) | R2 em Arma (2, 6, 8), 1 batida + `pista` antes do bloco | o mesmo | `percepcao(l).gatilho_dir == 0x25` num bloco de besta |
| bloco de martelo, o apito | R2 em Off | o mesmo | `gatilho_dir == 0x05` depois do apito |
| o PERFEITO de uma equipe (fora do pico) | a textura `metal` do kit (`acerto` 0,3/0,6/80) | o membro da outra que não toca: `golpe_esq` (Maré, 1,0/0/250) ou `golpe_dir` (Brasa, 0/1,0/250) | linha `sensacao` com o nome do lado no lugar certo; `percepcao(l).forte > 0` no golpe da esquerda, `fraco > 0` no da direita |
| a martelada | o toque do touchpad julgado | a outra equipe: `explosao` (1,0/1,0/400) na colcheia seguinte | linha `sensacao` `explosao` nos dois da outra equipe |
| a virada | — | quem cedeu: `golpe_esq` ou `golpe_dir`; com `lugar` −1, `golpe` em todos | linha `sensacao` a até 16,7 ms da linha `momento` do mesmo lugar |
| o sino | `mod_pronto` no alto-falante do dono, 0,8; sem alto-falante, `aviso` (0,6/0/200) no motor | nada | `som_virtual(l).falante > 0.05` só no lugar do sino; o robô toca a martelada só quando ouviu |
| o clique da besta | `mod_clique` 0,6 no alto-falante do dono | nada | `som_virtual(l).falante > 0` no quadro do disparo |
| a barra de luz | a cor do lugar, sempre (o minigame não chama `Forja.luz`) | o mesmo | `percepcao(l).luz` a até 0,05 da `Forja.cor_do_lugar(l)` em ≥75 % das amostras (o piscar do kit dura até 0,5 s) |
| as luzinhas | o número do jogador, sempre | o mesmo | `percepcao(l).leds_jogador == Forja.LEDS_DO_LUGAR[l]` em todas as amostras |
| o microfone | Não se aplica: a voz de um é ouvida por todos numa sala, e a Prova é de equipe | — | — |

**No rádio** (sem placa de áudio, `not Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)`): o gatilho e a vibração vão pela
ponte; o `material` vira rumble (o kit); o sino vira `aviso` no motor com `pista` `canal` `rumble`, e o segredo
continua só dele. O clique da besta fica no dedo (o gatilho).

## O cavaleiro

- **Os stats** (`docs/jogo/sistemas/minigames.csv`, linha 41): o Fôlego (`levantar`) muda a queda do erro, 1 tempo ×
  1,25 / 1,125 / 1 / 0,875 / 0,75 do stat 1 ao 5 (0,52 s a 0,31 s a 145 BPM, arredondada à semicolcheia). O Faro
  (`pista`) adianta a troca do gatilho antes do bloco de besta: −40 / −20 / 0 / +20 / +40 ms. O Peso e o Passo não
  mudam nada aqui. Nenhum stat mexe na janela de julgamento nem nos pontos.
- **A conta:** `_gancho(l, nome)` devolve o neutro (`levantar` 1,0, `pista` 0) até existir `Cavaleiro.gancho`; com
  ele, a conta é `neutro + por_ponto × (stat − 3)` (`levantar` −0,125 por ponto, `pista` +20 ms por ponto).
- **Como aparece:** o cavaleiro entra como a G13 o montou: a raça (humana, orc, autômato, golem ou raposa), a cabeça,
  o superior e o inferior. O minigame não tinge nada (`tingir` 0) e não troca material: o superior fica na faixa de
  valor do tecido (L 0,46 a 0,58), o inferior na do couro (0,22 a 0,36), e o néon do dono é só acento (o friso, a
  costura) a 1,6, mais o contorno a 2,4. A raça não muda a cápsula, a velocidade nem a janela.
- **O item:** quem tem o Martelo bate com o dele; quem tem a Âncora bate com a Âncora (mesma animação); os outros
  recebem `martelo_na_mao(p)` só durante os blocos de martelo. O Escudo fica no braço esquerdo, e os amuletos no peito,
  à vista.
- **O Aprendiz** não é cavaleiro de ninguém: `Kit.caminho("mini-dungeon-personagens/character-human")` (Mini Dungeon,
  a pasta à parte da G10) com
  `_tingir(modelo, Tema.ETIQUETA_SOMBRA)`, sem contorno e sem acento. Não usa o `character-orc`, que agora é raça de
  jogador.

## As reações

- **Adesivo:** nenhum durante o jogo. Na Prova todos jogam a partida inteira, e só quem está fora da rodada manda
  adesivo.
- **Os carimbos que este minigame pode disparar** (o jogo detecta pelo registro; o minigame não chama nada):

  | carimbo | o evento aqui | onde |
  | --- | --- | --- |
  | `car_acorde` | os quatro com PERFEITO na mesma batida de tempo 1 (`floor(b) % 4 == 0`): só no pico (compassos 26 a 29), quando os quatro tocam a batida `c0` | centro da tela, y 300 |
  | `car_em_chamas` | 5 PERFEITOs seguidos do mesmo lugar | acima da cabeça dele |
  | `car_por_um_fio` | a equipe vence com 2 % dos pontos ou menos de diferença | acima da cabeça do vencedor, no resultado |

  Quando dois disputam a vez: `car_acorde` > `car_em_chamas` > `car_por_um_fio`. O `car_virada` é do placar da noite,
  não da virada da frente.

## A diversão

**O grito: a virada da frente** (`virada`). A frente cruza o meio; o chão do meio muda de cor sob os pés de quem cedeu,
a luz cai 30 % por 1 batida e os dois que viraram acendem a 3,0. Degrau golpe; estrondo no pico.

- **O grito acontece no meio da tela:** a frente cruza em x = 0, que a câmera põe em `x_tela` 0,50 (dentro de 0,2 a
  0,8), e a runa tem `altura_tela` ≥ 0,08 com a escala de 130 %.
- **Quem perde ainda vira:** o erro cede só 0,12 laje e a frente não passa de 2 lajes antes da reta.
- **Como o jogador do time confere:**
  1. mesa das duplas (P1 `bom` e P2 `ruim` na Brasa contra P3 `medio` e P4 `medio`, semente 7): pelo menos 2 linhas
     `momento` `virada` em 90 s, pelo menos 1 com `t_musica` ≥ 45 s;
  2. cada linha `momento` tem uma `sensacao` do mesmo lugar a até 16,7 ms, e o `t_musica` cai a até 1 quadro de uma
     batida;
  3. na prancha da mesa das duplas, a cor das lajes do meio é diferente entre o quadro de 30 s e o de 60 s.

## Pronto quando

`--sala=prova` abre o `S09_J41`, que joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o Aprendiz) e com o robô
nos três temperamentos, aguenta o cabo que cai e volta, fecha com uma equipe vencedora, deixa a barra e as luzinhas do
lugar a partida inteira, faz pelo menos 2 viradas na mesa das duplas, e `salas/prova.gd` saiu; as provas abaixo passam
e a prancha foi olhada.

## Provas

Em `godot/testes/prova_do_jogo.gd`, no lugar do bloco «A Prova» de hoje, e a linha
`"S09_J41": await _prova_a_prova()` no `match` de `_prova_da_ficha(slot)`:

```gdscript
## S09_J41: a luz e as luzinhas do lugar a partida inteira; o R2 em arma num
## bloco de besta; a frente anda; o veredito da carga.
func _prova_a_prova() -> void:
	var conta := {"luz_fora": 0, "amostras": 0, "leds_ok": true, "besta": false}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var p := Forja.percepcao(l)
			var luz: Color = p.get("luz", Color.BLACK)
			var cor := Forja.cor_do_lugar(l)
			conta.amostras += 1
			if Vector3(luz.r - cor.r, luz.g - cor.g, luz.b - cor.b).length() > 0.05:
				conta.luz_fora += 1
			if int(p.get("leds_jogador", 0)) != Forja.LEDS_DO_LUGAR[l]:
				conta.leds_ok = false
			if mg._m >= 0 and (mg._m / 2) % 2 == 1 and int(p.get("gatilho_dir", 0)) == 0x25:
				conta.besta = true
	var mg := await _joga_o_minigame("S09_J41", 150.0, olhar)
	if mg == null:
		return
	_esperar(conta.leds_ok, "S09_J41: as luzinhas ficaram as do lugar")
	_esperar(conta.luz_fora * 4 <= conta.amostras, "S09_J41: a barra na cor do lugar (%d de %d fora)" % [conta.luz_fora, conta.amostras])
	_esperar(conta.besta, "S09_J41: o R2 em arma (0x25) num bloco de besta")
	_esperar(absf(mg._frente) > 0.0, "S09_J41: a frente andou (%.2f)" % mg._frente)
	_confere_os_vereditos(mg, ["tudo_junto"])
```

(O dicionário `conta` é porque a lambda do GDScript não reatribui variável de fora.)

No `_prova_do_relatorio()`, com as linhas do `S09_J41`:

- há `pista` com `canal` `alto_falante`, e cada uma é de um lugar só;
- nenhuma `saida` com `o == "lightbar"` fora da bancada;
- cada `momento` tem `sensacao` do mesmo lugar (ou de todos, com `lugar` −1) a até 16,7 ms;
- nenhuma `sensacao` e nenhum `som_controle` de háptica no mesmo controle e no mesmo quadro.

Os comandos:

```bash
SALA=S09_J41 bash tests/prova_do_jogo.sh
bash tests/prova_visual.sh
bash tests/prova_sem_rastro.sh
```

A mesa das duplas pede o robô por lugar (`--robo=bom,ruim,medio,medio --semente=7`), que a F09 ainda não tem: até
existir, a checagem da diversão roda com `--robo=medio --semente=7` e o mínimo de 2 viradas vale igual.

**As pranchas que se olham** (`SAIDA/prancha-<n>.png`):

- a de quatro com `bom`: a faixa em duas cores, a runa andando, os virotes, os contornos nas quatro cores;
- a de quatro com `ruim`: as marcas de pé no chão perdido;
- a de dois e a de um: o Aprendiz em `ETIQUETA_SOMBRA`, sem contorno;
- a do cabo que cai: a equipe sem o caído não empurra nem cede por ele;
- nas quatro: as roupas de cima e de baixo de cada cavaleiro em valores diferentes, e o néon só no friso e na costura.

**Com o André (local):** `./run-local.sh -- --sala=prova`, dois no cabo e dois no rádio. O clique da besta tem de estar
no dedo; o sino tem de ser segredo (ninguém mais ouve); o golpe do lado tem de chegar na mão de quem esperava, do lado
certo; a barra de luz nunca troca de cor.
