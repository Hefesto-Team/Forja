# P5 — Palmas da Forja

**Sprint:** P · **Slot:** S08_J40 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, P1

## Por quê

Festa na forja. O ferreiro bate na bigorna e a turma inteira segura o ritmo
com **palmas** — o microfone de cada controle ouve as mãos de quem o segura.
No fim de cada frase ele faz uma virada, e a turma responde. Coop puro: a
espada lendária só sai se a sala bate junto. É o minigame em que ninguém
precisa de controle na mão para jogar (o controle fica no colo, ouvindo).

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](P-a-voz.md) e a [P1](P1-a-voz.md): **o ouvido** (`_ouvir`, as constantes, o "sem microfone", o mudo fora da hora) — copie igual
- [04 — chamada e resposta](../04-ritmo-e-audio.md#as-janelas) (a janela vale sobre o tempo, como nas outras)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S08_J40",
	"titulo": "Palmas da Forja",
	"verbo": "Bata palmas!",
	"genero": "coop",
	"icone": "microfone",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S08_J40",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Palmas!", "segundos": 6.0},
	"gesto": "interact-left",
}
```

## Como se joga

A faixa é `MUS_S08_J40`, 118 bpm (uma batida ≈ 0,51 s), com palmas no dois e
no quatro. `ENTRADA := 4`.

- **A frase** tem 4 compassos (16 batidas), a partir de `f0 = ENTRADA + 16 * k`:

  | compasso | o que acontece |
  | --- | --- |
  | 0 e 1 | **a base:** palmas no dois e no quatro — as batidas `+1` e `+3` do compasso |
  | 2 | **a chamada:** o ferreiro bate a virada na bigorna (TV); ninguém bate |
  | 3 | **a resposta:** a turma bate a mesma virada |

- **As viradas** (as batidas da virada dentro do compasso), na ordem das
  frases, voltando ao começo:
  `VIRADAS := [[0.0, 1.0, 2.0, 3.0], [0.0, 0.5, 1.0, 2.0], [0.0, 1.5, 2.0, 3.0], [0.0, 0.5, 1.5, 2.0, 3.0], [1.0, 1.5, 2.0, 2.5, 3.0]]`.
- **As notas:** cada palma pedida é uma nota de **cada** lugar (todos batem
  tudo), aberta meia batida antes. A palma de um lugar é um começo de voz no
  ouvido da P1 (a palma é curta e alta: o mesmo começo). A até 0,25 s do
  alvo → `julgar_toque(l, t(bn) + LATENCIA_MIC, n)`. Uma palma longe de toda
  nota é ignorada.
- **A palma da turma:** quando a janela de uma palma pedida fecha, conta-se
  quem acertou entre os lugares com microfone e conectados; se acertaram
  **metade ou mais** (`ceil(m / 2)`), a palma **entrou**: a espada ganha um
  golpe (`_espada += 1`); se não, **desafinou** (a falha coletiva).
- **A meta:** a espada lendária pede `_meta = ceil(0.7 * palmas_previstas)`
  golpes, com `palmas_previstas` = as palmas pedidas até o `duracao` (conte
  no `iniciar_jogo()` pelas frases).
- **Pontos:** cada palma julgada marca `[0, 50, 75, 100][j]` para quem bateu
  (é o destaque: "quem cravou mais palmas").
- **O hoqueto:** aqui é o contrário — todos juntos, é o coro de palmas; a
  nota de cada lugar soa na TV (kit) na palma certa dele.
- **A partitura simples** (`Ritmo.simples[l]`): na base, o lugar bate só o
  quatro (`+3`); as viradas continuam dele.
- **O pico — a festa dobra:** os 4 compassos a partir de
  `_pico_f0 := ENTRADA + 16 * floor(frases_previstas / 2)` são todos base, com
  palmas em **toda** batida; a ferraria acende (as tochas a 2,4).

`frases_previstas = floor((duracao / _t_batida() - ENTRADA) / 16)`.

## O cenário

- **A ferraria em festa:** `Kit.arena(self, 5, 3)`; a luz da casa cheia:
  `luzes([Vector3(-8, 3, -3), Vector3(8, 3, -3)])` e
  `atmosfera(Color("#ffb070"), Tema.ROSA, true, 60, 22.0, -7.8, 0.4)`
  (brasas subindo); bandeiras `Kit.peca(self, "banner", Vector3(x, 0, -5.6))`
  em `x = -7, -3, 3, 7`.
- **O ferreiro** (não é lugar): `character-orc.glb` tingido de `#6b4a32`
  (o `_tingir` de `prova.gd:199-209`), em `(0, 0, -3.4)`, de frente, com
  `Kit.martelo` preso ao osso `arm-right` (o jeito do `martelo_na_mao` da
  `SalaJogo`, copiado para o nó dele); bate `attack-melee-right` em cada
  batida da chamada.
- **A bigorna e a espada:** `Kit.bigorna(self, Vector3(0, 0, -2.4), 1.2)`; em
  cima, a espada: lâmina `Kit.caixa(self, Vector3(0.14, 0.05, 1.6), ...)`
  `#9aa3b5` e o punho `Kit.caixa(...)` `#6b4a32`; a lâmina ganha brilho com a
  meta (`emission_energy_multiplier = 3.0 * _espada / _meta`: é efeito de
  acerto) e entorta um pouco a cada palma que desafina
  (`rotation.z += 0.04`, e endireita 0,02 a cada palma que entra).
- **Cada raia:** `raia(l)` e `posicionar(l)` (de frente para a câmera); o
  boneco faz `interact-left` e `interact-right` alternados a cada palma dele.
- **A câmera:** `camera_pos = Vector3(0, 5.8, 10.6)`, `camera_olhar = Vector3(0, 1.2, -1.8)`.
- **Checklist de arte (11):** o ferreiro é boneco do kit tingido; a espada em
  caixas; o emissivo só na lâmina (acerto), nas brasas e na borda da raia;
  nenhuma cor de lugar no cenário.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **microfone (protagonista)** | a palma de cada um | cada palma pedida |
| luz do mudo | o mudo fora da hora (P1): acesa enquanto mudo; ele bate sozinho, mais fraco | se apertar |
| vibração | a chamada: na batida do ferreiro, `Forja.sentir(l, "toque")` em todos (a virada também na mão, para quem não ouve bem a TV); a palma que entra: o kit | a chamada; o toque |
| barra de luz | a cor do lugar | — |
| alto-falante do dono | a nota dele na palma perfeita (o kit); `Forja.som_falante(l, "coleta", 0.7)` a cada 10 golpes da espada (todos) | — |
| háptica por material | o kit (`material:metal`, no cabo) | no toque |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a música com palmas no 2 e no 4; `Som.tocar("bigorna_aguda", bigorna, -4.0)` em cada batida da chamada; `Som.tocar("bigorna", bigorna, -8.0)` em cada palma que entra; `Som.tocar("falha", bigorna, -6.0)` na que desafina; `Som.tocar("sucesso")` na espada lendária | — |

**No rádio:** sem placa de áudio não há microfone nem alto-falante: o lugar
entra no "sozinho" abaixo desde o começo (a `troca` com `sem_microfone`), os
sons do alto-falante não soam, e a háptica do kit vai pelo rumble. A luz do
mudo é saída HID e passa pela ponte.

**Sem microfone / mudo** (a P1): o lugar "bate sozinho, mais fraco" — em
cada palma pedida, ele conta como acerto na palma da turma **uma vez sim,
uma vez não**, sem nota e sem pontos; a `troca` uma vez. Se ninguém tem
microfone, a palma da turma vale pelos que batem sozinhos (a espada anda
devagar, mas anda).

## A falha

**A palma que desafina** (a turma não chegou à metade): a bigorna solta um
som torto, a espada entorta, o ferreiro faz `emote-no` (0,5 s). O lugar que
bateu fora do tempo (julgado ERRO) faz `emote-no` curto; o que não bateu,
nada (é coletivo).

## O fim e o vencedor

O kit fecha no `duracao` (90 s). `coop = true` no `montar()`;
`coop_venceu = _espada >= _meta` (posto a cada golpe, e ele fica). Na
primeira vez em que a meta chega, a espada lendária acende (faíscas
`Color("#ffb070")`, `Som.tocar("sucesso")`, o ferreiro `emote-yes`) e a festa
continua até o fim. `vencedor()`: o destaque — mais palmas julgadas sem erro
(`_palmas[l]`), depois pontos.

## Com menos de quatro

- **3, 2, 1:** a metade da turma é `ceil(m / 2)` dos que têm microfone e
  controle: com um, a palma dele é a da turma.
- **O controle que cai:** sai da conta da turma enquanto estiver fora; volta
  na próxima palma.
- **Duplas:** não há.

## O robô

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if n < 0 or _robo_bateu[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.3 if _robo_rng.randf() < 0.5 else 99.0)
	if Ritmo.t_musica() >= float(_alvo[l]) + LATENCIA_MIC + float(_robo_mira[l]):
		Forja.robo_falar(l, 0.9, 0.08)   # a palma: curta e alta
		_robo_bateu[l] = n
```

(Duas palmas pedidas a meia batida — nas viradas — dão 0,25 s entre as
falas do robô: o `robo_falar` de 0,08 s cabe, e o ouvido vê dois começos.)

## Os ganchos

`godot/scripts/minigames/s08/palmas_da_forja.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Palmas da Forja (S08_J40). O ferreiro pede o ritmo na bigorna e a turma
## segura com palmas — o microfone de cada controle ouve as mãos de quem o
## segura. Palmas no dois e no quatro; no fim de cada frase, a virada dele, e a
## turma responde.
##
## A falha: a palma que desafina entorta a espada. O vencedor: coop (a espada
## lendária); o destaque é quem cravou mais palmas. O alto-falante do dono: a
## nota dele na palma perfeita. O registro mede: cada palma de cada controle
## (voz, toque) e a palma da turma. O robô: bate pelo controle simulado. Com
## menos de quatro: a metade da turma é a de quem joga. A régua: "Bata
## palmas!" basta.

const FICHA := { ... }

const ENTRADA := 4
const VIRADAS := [[0.0, 1.0, 2.0, 3.0], [0.0, 0.5, 1.0, 2.0], [0.0, 1.5, 2.0, 3.0], [0.0, 0.5, 1.5, 2.0, 3.0], [1.0, 1.5, 2.0, 2.5, 3.0]]
const JANELA_CASA := 0.25
const PONTOS := [0, 50, 75, 100]
# ... e as do ouvido (a P1)

var _pedidas: Array = []        ## as palmas pedidas: [{bn, fechada, acertos, contados}] em ordem
var _i_proxima := 0             ## a próxima palma a abrir
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _n := [0, 0, 0, 0]
var _nota_da_palma := [-1, -1, -1, -1]   ## o índice em _pedidas da nota aberta de cada um
var _palmas := [0, 0, 0, 0]
var _espada := 0
var _meta := 1
var _chamada_feita := -1.0
var _pico_f0 := 9999.0
var _nos := {}
var _ferreiro: Node3D
var _lamina: MeshInstance3D
# o ouvido (a P1)
var _robo_nota := [-1, -1, -1, -1]
var _robo_bateu := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	papel_som = Forja.PAPEL_MICROFONE
	coop = true
	camera_pos = Vector3(0, 5.8, 10.6)
	camera_olhar = Vector3(0, 1.2, -1.8)
	# a ferraria, o ferreiro, a bigorna e a espada; cada raia; gatilhos_off


func iniciar_jogo() -> void:
	_pedidas = _planejar()          # todas as palmas pedidas até o duracao (a base, as respostas, o pico)
	_meta = int(ceil(0.7 * _pedidas.size()))
	# sem microfone (a P1); led_mic(l, 0)


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)
	_chamada(b)                     # no compasso 2 da frase: o ferreiro bate a virada; a mão de todos sente
	_abrir_palmas(b)                # meia batida antes: uma nota por lugar conectado com microfone
	_fechar_palmas()                # a janela fechou: nota_perdida de quem não bateu; a palma da turma
	_mostrar(b)


func _comecou(l: int) -> void:
	var n: int = _nota[l]
	if n < 0 or absf(Ritmo.t_musica() - float(_alvo[l]) - LATENCIA_MIC) > JANELA_CASA:
		return
	_nota[l] = -1
	var i: int = _nota_da_palma[l]
	var j := julgar_toque(l, float(_alvo[l]) + LATENCIA_MIC, n)
	if j != Ritmo.ERRO:
		_pedidas[i].acertos += 1


func _parou(_l: int) -> void:
	pass


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_palmas[l] += 1
	jogador(l).gesto("interact-left" if _palmas[l] % 2 == 0 else "interact-right", 0.2)


func falha(l: int) -> void:
	jogador(l).gesto("emote-no", 0.2)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b): return _palmas[a] > _palmas[b] or (_palmas[a] == _palmas[b] and pontos[a] > pontos[b]))
	return lista
```

`_planejar()`: para cada frase `k` até o `duracao`, as batidas `f0 + 4c + 1`
e `f0 + 4c + 3` dos compassos 0 e 1 (no pico, as quatro batidas dos quatro
compassos), e as `f0 + 12 + v` da resposta, com `v` em
`VIRADAS[k % VIRADAS.size()]`; devolve `[{"bn": x, "fechada": false, "acertos": 0, "contados": 0}, ...]`
em ordem. `_abrir_palmas(b)`: a palma `_i_proxima` abre em `bn - 0.5` — para
cada lugar conectado, com microfone e sem nota aberta (e respeitando o
`Ritmo.simples[l]`), `nova_nota`, `_nota[l]`, `_alvo[l]`,
`_nota_da_palma[l] = _i_proxima`; `contados += 1`; quem está sem microfone
ou mudo soma `acertos` uma vez sim uma não (e `contados`). `_fechar_palmas()`:
a palma aberta cuja janela passou (`t(bn) + LATENCIA_MIC + JANELA_BOM`) fecha:
as notas ainda abertas dela → `nota_perdida`; se `acertos >= ceili(contados / 2.0)`,
`_espada += 1` e a bigorna soa, senão a falha coletiva. `_chamada(b)`: nas
batidas `f0 + 8 + v` da virada da frase, uma vez cada (`_chamada_feita`):
o ferreiro martela, a bigorna aguda na TV, `Forja.sentir(l, "toque")` em
todos.

Dica: nenhuma palavra; enquanto `not aprendeu(l)`, `["@mic"]` sob a raia na
base. `status(l)`: `"%d palmas" % _palmas[l]`; `progresso()`:
`"Espada %d de %d" % [_espada, _meta]`.

Catálogo: `"S08_J40"` em `MINIGAMES` e na seção `S08`. Traduções:
`"Palmas da Forja": "Forge Clapping"`, `"Bata palmas!": "Clap!"`,
`"Palmas!": "Clap!"`, `"%d palmas": "%d claps"`, `"Espada %d de %d": "Sword %d of %d"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O que o registro mede

- `voz` de cada palma (o nível: a palma é o pico mais curto da seção — a
  noite vê a resposta do microfone a um transiente, por controle e por
  transporte);
- `toque` de cada palma, com o desvio; a chamada (`sensacao` `toque`) e a
  resposta — a noite compara o desvio na resposta com o da base;
- `troca` para "sozinho".

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **A palma de um chega aos quatro microfones.** A regra do ar dá a palma a
  quem está perto do mais alto; se todos batem, todos recebem. É o
  esperado; ajuste só `MARGEM_AR` (na P1), nunca aqui.
- **Palmas a meia batida** (as viradas): 0,25 s entre duas. A `JANELA_CASA`
  é 0,25 s (menor que nas outras) para uma palma não casar com a nota
  vizinha.
- **O nível desce rápido** depois da palma: o ouvido vê o fim logo; não use
  o fim para nada.
- **Na prova o pico não chega** (o fim é pelo `duracao`).
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos; aguenta o cabo que cai e volta; fecha com o resultado coop e
o destaque; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a
prancha olhada (o ferreiro martelando, os bonecos batendo palmas, a espada
brilhando).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_palmas()`:

```gdscript
## S08_J40: o robô bate as palmas no microfone simulado; a espada ganha
## golpes; o resultado é coop.
func _prova_palmas() -> void:
	var sala = await _comeca_a_sala("S08_J40")
	if sala == null:
		return
	var q := 0
	while is_instance_valid(sala) and sala.fase == "jogo" and q < 12000:
		await _quadros(1)
		q += 1
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "palmas: fechou")
	if is_instance_valid(sala):
		_esperar(sala._espada >= 1, "palmas: a espada ganhou golpes (%d)" % sala._espada)
		_esperar(sala.coop, "palmas: o resultado é coop")
		_esperar(sala._palmas.max() >= 1, "palmas: alguém cravou palmas (%s)" % [sala._palmas])
```

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S08_J40`, com quatro, os
controles no colo. Bater palmas tem de funcionar com o controle parado no
colo; a virada tem de ser aprendida de ouvido na primeira frase; a espada
lendária tem de parecer uma conquista da sala.

## Ao terminar

- No [quadro](README.md), a linha P5: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Palmas da Forja — a turma segura o ritmo com as mãos`
