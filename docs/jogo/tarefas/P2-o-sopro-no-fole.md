# P2 — O Sopro no Fole

**Sprint:** P · **Slot:** S08_J37 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, P1

## Por quê

A voz como segurar e soltar: cada um tem o seu fole, e a nota longa pede
sopro do começo ao fim — e parar em seco quando ela acaba. O difícil não é
soprar, é **parar**. Todos contra todos, em hoqueto: cada nota longa é de um,
e a frase inteira é o fole dos quatro, um depois do outro.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](P-a-voz.md) e a [P1](P1-a-voz.md): **o ouvido** (`_ouvir`, as constantes, o "sem microfone", o mudo fora da hora) — copie igual

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S08_J37",
	"titulo": "O Sopro no Fole",
	"verbo": "Sopre e pare!",
	"genero": "tct",
	"icone": "mic",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S08_J37",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "madeira",
	"microjogo": {"verbo": "Sopre!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "interact-right",
}
```

## Como se joga

A faixa é `MUS_S08_J37`, 112 bpm (uma batida ≈ 0,54 s), com notas longas que
param em seco. `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08).

- **O ciclo (o hoqueto):** com `np` lugares em `presentes()`, o ciclo tem
  `CICLO = 2 * np` batidas. O lugar na posição `i` tem **uma nota longa** por
  ciclo: começa em `bi = BATIDA_DA_PRIMEIRA_NOTA + CICLO * c + 2 * i` e acaba em
  `bi + DUR`, com `DUR := 1.5` batidas. Entre uma nota e a do próximo sobra
  meia batida: a voz de um nunca encosta na do outro (a regra do ar agradece).
- **Duas notas por nota longa:** a **entrada** (`n = 2k`, alvo `t(bi)`) e a
  **saída** (`n = 2k + 1`, alvo `t(bi + DUR)`). A saída só é aberta
  (`nova_nota`) quando a entrada foi julgada sem erro.
- **A entrada:** o começo da voz do lugar a até 0,35 s do alvo →
  `julgar_toque(l, t(bi) + LATENCIA_MIC, 2k)`. Um começo de voz fora de toda
  nota dele é **ignorado** (pode ser o vizinho; a regra do ar já filtra, e o
  fole não pune ruído).
- **A saída:** o fim da voz (`_parou(l)`, com `VOZ_FICA` da P1) com a saída
  aberta → `julgar_toque(l, t(bi + DUR) + LATENCIA_FIM, 2k + 1)`, com
  `LATENCIA_FIM := 0.12` (o nível do microfone desce mais devagar do que
  sobe). Parou cedo demais (mais de `JANELA_BOM` antes) é erro: o fole murcha
  no meio.
- **Soprou demais:** ainda soprando em `t(bi + DUR) + LATENCIA_FIM + JANELA_BOM`
  → `_motivo[l] = "fuligem"`, `nota_perdida(l, 2k + 1)` — **a falha** —, e
  o resto daquela voz é ignorado até o silêncio.
- **Sem entrada:** nenhuma voz até `t(bi) + LATENCIA_MIC + JANELA_BOM` →
  `_motivo[l] = "murchou"`, `nota_perdida(l, 2k)` (a saída nem abre).
- **Pontos:** entrada e saída, cada uma `[0, 25, 40, 50][j]`; a **nota
  inteira** (as duas sem erro) vale mais 50 e `_inteiras[l] += 1`, e a forja
  do lugar solta a labareda.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar sopra um ciclo sim,
  um não (o ciclo dele fica sem nota nos `c` ímpares).
- **O pico — o fole grande:** os dois ciclos a partir de
  `_pico_c := floor(ciclos_previstos / 2)` têm `CICLO = 4 * np` e
  `DUR := 3.5` (o fôlego inteiro); o fole cresce o dobro na tela, e a TV
  toca `Som.tocar("vento", null, -6.0)` na entrada.

`ciclos_previstos = floor((duracao / _t_batida() - BATIDA_DA_PRIMEIRA_NOTA) / (2 * np))`.
`t(x)` é `Ritmo.t_da_batida(x)`.

## O cenário

- **A oficina:** `Kit.arena(self, 5, 3)`, a luz da casa inteira:
  `luzes([Vector3(-9, 3, -3), Vector3(9, 3, -3)])` e
  `atmosfera(Color("#ffb070"), Tema.LARANJA, true, 40, 22.0, -7.8, 0.35)`.
- **Cada raia:** `raia(l)` e `posicionar(l)` (de frente para a câmera);
  à frente do boneco, **o fole**: duas tábuas `Kit.caixa(fole, Vector3(0.9, 0.08, 0.6), ...)`
  de madeira `#8a5a33` e, entre elas, o couro `Kit.caixa(fole, Vector3(0.8, 0.4, 0.5), ..., couro)`
  (`#5a3a2a`); o bico, `Kit.caixa(fole, Vector3(0.12, 0.12, 0.5), ...)` de
  ferro `#5b6275`, apontado para **a forja do lugar**: uma
  `Kit.bigorna(self, Vector3(RAIAS[l], 0, Z_JOGADOR - 1.6), 0.45)` com uma
  chama `Kit.cilindro` de 8 lados emissiva `#ff7a1a` em cima (altura 0,1
  apagada, 1,0 na labareda) e uma `OmniLight3D` `#ff9a40`.
- **O fole, pela batida:** enquanto a nota longa corre e o lugar sopra, o
  couro cresce `scale.y = 1.0 + 1.2 * clampf((b - bi) / DUR, 0.0, 1.0)` (no
  pico, 2,4); a tábua de cima sobe com ele; parou, murcha em meia batida.
- **O que se vê da nota** (todos veem a de todos): sobre cada fole, uma barra
  de ferro `Kit.caixa` que se enche da esquerda para a direita durante a nota
  longa dele (o comprimento é a nota; o fim da barra é o "pare"), em ferro
  `#8c98aa` — acesa (a borda da raia do kit, `acender_raia(l, 1.0)`) durante a
  nota dele.
- **A câmera:** `camera_pos = Vector3(0, 6.0, 11.0)`, `camera_olhar = Vector3(0, 0.8, -0.6)`.
- **Checklist de arte (11):** madeira e couro em caixas; a bigorna do kit; o
  emissivo só na chama e na borda da raia; nada nas cores dos lugares.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **microfone (protagonista)** | o sopro: entrada e saída de cada nota longa | a nota do lugar |
| luz do mudo | o mudo fora da hora (P1): acesa enquanto mudo; ele sopra sozinho | se apertar o botão |
| vibração | cresce com a voz: durante o sopro dentro da nota, `Forja.sentir(l, "toque")` a cada meia batida (o couro enchendo); a fuligem: `Forja.sentir(l, "golpe")` | no sopro; na falha |
| barra de luz | a cor do lugar | — |
| alto-falante do dono | a nota dele na nota inteira: `Forja.som_falante(l, "nota:%d" % l, 0.8)`; a quebrada na fuligem (o kit) | no fim da nota |
| háptica por material | o kit (`material:madeira`, no cabo) | no toque |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a música; `Som.tocar("sopro", fole, -8.0)` durante o sopro de cada um (o som do fole dele, posicional); `Som.tocar("fogo", forja, -10.0)` na labareda; `Som.tocar("falha", pos, -6.0)` na fuligem | — |

**No rádio:** sem placa de áudio não há microfone nem alto-falante: o lugar
entra no "sozinho" abaixo desde o começo (a `troca` `de` `microfone` `para` `sem_microfone`), os
sons do alto-falante não soam, e a háptica do kit vai pelo rumble. A luz do
mudo é saída HID e passa pela ponte.

**Sem microfone / mudo:** sopra sozinho, mais fraco (a P1): em cada nota
longa dele, `marcar(l, 30)` e o fole enche sozinho pela metade (sem nota,
sem `_inteiras`); a `troca` uma vez.

## A falha

- **A fuligem** (soprou demais): o fole estoura — `Efeitos.poeira(self, pos_do_bico, Vector3(0.8, 0.8, 0.8), Color("#2a2433"), 30)`
  no rosto do boneco, que tosse (`emote-no`, 0,8 s); a mão sente o golpe; a
  forja dele apaga até a próxima nota.
- **Murchou** (não entrou): o fole fica vazio; o boneco olha para ele
  (`emote-no`, 0,4 s).
- **Parou cedo** (a saída ERRO antes do fim): o fole murcha na metade, sem
  labareda.

## O fim e o vencedor

O kit fecha no `duracao` (80 s). `vencedor()`: mais notas inteiras
(`_inteiras`), depois mais pontos, depois o lugar menor.

## Com menos de quatro

- **3, 2, 1:** o ciclo encolhe (`2 * np` batidas): com um, ele sopra a cada
  2 batidas — mais notas, e ele vence ao fim.
- **O controle que cai:** as notas dele não abrem; as abertas fecham sem
  registro; quando volta, entra na nota longa seguinte dele.
- **Duplas:** não há.

## O robô

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var k: int = _longa[l]           # a nota longa da vez (-1: nenhuma)
	if k < 0 or _robo_soprou[l] == k:
		return
	if _robo_longa[l] != k:
		_robo_longa[l] = k
		var certo := Forja.robo_acerta()
		# quando não acerta: sopra demais (fuligem) ou entra atrasado
		_robo_mira[l] = 0.0 if certo else (0.3 if _robo_rng.randf() < 0.5 else 0.0)
		_robo_sobra[l] = 0.0 if certo else (0.5 if float(_robo_mira[l]) == 0.0 else 0.0)
	var ini := Ritmo.t_da_batida(_bi[l]) + LATENCIA_MIC + float(_robo_mira[l])
	if Ritmo.t_musica() >= ini:
		var dur := Ritmo.t_da_batida(_bi[l] + _dur[l]) - Ritmo.t_da_batida(_bi[l])
		Forja.robo_falar(l, 0.8, dur - float(_robo_mira[l]) + LATENCIA_FIM - LATENCIA_MIC + float(_robo_sobra[l]))
		_robo_soprou[l] = k
```

(O robô fala uma vez, pelo tempo da nota: o `robo_falar` segura o nível
pelos segundos pedidos. `_bi[l]` e `_dur[l]` são o começo e a duração da nota
longa da vez.)

## Os ganchos

`godot/scripts/minigames/s08/o_sopro_no_fole.gd`, `extends Minigame`.

```gdscript
extends Minigame
## O Sopro no Fole (S08_J37). Cada um tem o seu fole e uma nota longa por vez,
## em hoqueto: sopre do começo ao fim da nota e pare em seco quando ela acaba.
##
## A falha: soprou demais e o fole estoura fuligem no rosto; não entrou e o
## fole murcha. O vencedor: mais notas inteiras. O alto-falante do dono: a nota
## dele na nota inteira. O registro mede: a voz de cada controle (voz), a
## entrada e a saída de cada nota (toque, com o desvio). O robô: fala pelo
## tempo da nota no controle simulado. Com menos de quatro: o ciclo encolhe.
## A régua: o verbo é o que se faz; sem microfone, o fole sopra sozinho.

const FICHA := { ... }

const DUR := 1.5
const DUR_PICO := 3.5
const LATENCIA_FIM := 0.12
const JANELA_CASA := 0.35
const PONTOS := [0, 25, 40, 50]
# ... e as do ouvido (a P1)

var _ordem := {}
var _longa := [-1, -1, -1, -1]     ## a nota longa da vez (k), ou -1
var _bi := [0.0, 0.0, 0.0, 0.0]
var _dur := [DUR, DUR, DUR, DUR]
var _entrou := [false, false, false, false]   ## a entrada da nota da vez foi julgada sem erro
var _nota := [-1, -1, -1, -1]      ## a nota aberta (2k ou 2k + 1)
var _ignorar_ate_calar := [false, false, false, false]
var _inteiras := [0, 0, 0, 0]
var _motivo := ["", "", "", ""]
var _pico_c := 999
var _nos := {}
# o ouvido (a P1)
var _robo_longa := [-1, -1, -1, -1]
var _robo_soprou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_sobra := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 6.0, 11.0)
	camera_olhar = Vector3(0, 0.8, -0.6)
	# a oficina, os foles, as forjas; gatilhos_off


func iniciar_jogo() -> void:
	# a ordem, o _pico_c, sem microfone (a P1), led_mic(l, 0)
	pass


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)
	for l in presentes():
		if not conectado(l):
			_longa[l] = -1
			_nota[l] = -1
			continue
		_proxima_longa(l, b)       # abre a entrada da próxima nota longa dele (1 batida antes)
		_prazos(l)                 # murchou, soprou demais, a saída que passou
		_mudo_fora_de_hora(l)      # a P1
	_mostrar(b)


func _comecou(l: int) -> void:
	if _ignorar_ate_calar[l] or _nota[l] != 2 * _longa[l]:
		return
	if absf(Ritmo.t_musica() - Ritmo.t_da_batida(_bi[l]) - LATENCIA_MIC) <= JANELA_CASA:
		var n: int = _nota[l]
		_nota[l] = -1
		_motivo[l] = "murchou"
		if julgar_toque(l, Ritmo.t_da_batida(_bi[l]) + LATENCIA_MIC, n) != Ritmo.ERRO:
			_entrou[l] = true
			_nota[l] = n + 1
			nova_nota(l, n + 1, Ritmo.t_da_batida(_bi[l] + _dur[l]))


func _parou(l: int) -> void:
	_ignorar_ate_calar[l] = false
	if _nota[l] == 2 * _longa[l] + 1:
		var n: int = _nota[l]
		_nota[l] = -1
		_motivo[l] = "cedo"
		var j := julgar_toque(l, Ritmo.t_da_batida(_bi[l] + _dur[l]) + LATENCIA_FIM, n)
		if j != Ritmo.ERRO and _entrou[l]:
			_inteira(l)            # +50, _inteiras, a labareda, a nota no alto-falante


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])


func falha(l: int) -> void:
	match _motivo[l]:
		"fuligem":
			_fuligem(l)
			_ignorar_ate_calar[l] = true
		"cedo":
			_murchar(l, 0.5)
		_:
			_murchar(l, 1.0)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		return _inteiras[a] > _inteiras[b] or (_inteiras[a] == _inteiras[b] and (pontos[a] > pontos[b] or (pontos[a] == pontos[b] and a < b))))
	return lista
```

`_proxima_longa(l, b)`: calcula o ciclo `c` e a batida `bi` da próxima nota
longa do lugar (com o `CICLO` e o `DUR` do pico quando `c` está no pico, e
pulando os `c` ímpares com `Ritmo.simples[l]`); na batida `bi - 1`, se não há
nota aberta: `_longa[l] = k`, `_bi[l] = bi`, `_dur[l]`, `_entrou[l] = false`,
`_nota[l] = 2k`, `nova_nota(l, 2k, Ritmo.t_da_batida(bi))`. `_prazos(l)`: a
entrada aberta passou de `t(bi) + LATENCIA_MIC + JANELA_BOM` → `_motivo = "murchou"`,
`nota_perdida`; a saída aberta com o lugar ainda falando depois de
`t(bi + dur) + LATENCIA_FIM + JANELA_BOM` → `_motivo = "fuligem"`,
`nota_perdida`. Sem microfone ou mudo: na batida `bi`, o sopro sozinho.

Dica: nenhuma palavra; o fole e a barra de ferro são a instrução (a barra
cheia é o "pare"). Enquanto `not aprendeu(l)`, `["@mic"]` sob a raia na nota
dele. `status(l)`: `"%d inteiras" % _inteiras[l]`.

Catálogo: `"S08_J37"` em `MINIGAMES` e na seção `S08`. Traduções:
`"O Sopro no Fole": "Breath in the Bellows"`, `"Sopre e pare!": "Blow and stop!"`,
`"%d inteiras": "%d whole"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O que o registro mede

- `voz` (`comecou`/`parou`, o nível e o piso) de cada nota longa: a noite vê
  quanto cada microfone sobe e **quanto demora para descer** — o
  `LATENCIA_FIM` real sai do `desvio_ms` das saídas;
- `nota`/`toque` da entrada e da saída;
- `troca` `de` `microfone` `para` `sem_microfone`.

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **A saída depende do fim da voz**, e o nível desce devagar: não use o
  `VOZ_ACIMA` para o fim, use o `VOZ_FICA` (a histerese da P1), senão a voz
  "para" e "volta" no meio do sopro.
- **Uma voz, uma nota.** Depois da fuligem, ignore o resto da voz até o
  silêncio (`_ignorar_ate_calar`), senão o fim dela julga a nota seguinte.
- **O hoqueto sem encostar.** Meia batida entre uma nota e a do próximo; não
  encurte, é o que impede o vizinho de "parar" a sua nota.
- **Na prova o pico não chega** (o fim é pelo `duracao`, em tempo de jogo).

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos (o ruim estoura fuligem); aguenta o cabo que cai e volta;
fecha com vencedor; sem microfone, o fole sopra sozinho e a `troca` aparece;
a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha
olhada (os foles enchendo, a barra, a fuligem).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_sopro_no_fole()`:

```gdscript
## S08_J37: o robô sopra as notas longas; a entrada e a saída são julgadas, e
## ao menos uma nota inteira sai.
func _prova_sopro_no_fole() -> void:
	# a espera é a do `_joga_o_minigame` da H08: o aviso em quadros, o jogo pelo relógio de parede (80 s de música e o treino)
	var sala = await _joga_o_minigame("S08_J37", 120.0)
	if sala == null:
		return
	_esperar(sala._inteiras.max() >= 1, "fole: uma nota inteira (%s)" % [sala._inteiras])
	_esperar(sala.colocacao().size() == 4, "fole: a colocação tem os quatro")
```

No `_prova_do_relatorio()`: os `toque` do `S08_J37` têm `n` par (entradas) e
ímpar (saídas).

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S08_J37`, com quatro. Parar
em seco no fim da nota tem de ser o momento engraçado (a fuligem); o vizinho
soprando não pode estragar a nota de ninguém — se estragar, anote os `voz`
e ajuste `MARGEM_AR`.

## Ao terminar

- No [quadro](README.md), a linha P2: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: O Sopro no Fole — sopre a nota inteira e pare em seco`
