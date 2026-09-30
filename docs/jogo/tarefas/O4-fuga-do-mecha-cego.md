# O4 — Fuga do Mecha Cego

**Sprint:** O · **Slot:** S07_J34 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, O1

## Por quê

O mecha é cego e caça pelo som. Os passos dele chegam **no atuador do lado
em que ele está** — esquerdo ou direito, e cada cavaleiro o sente do seu
lugar. Quem foge para o lado oposto no tempo e congela quando ele para,
sobrevive. É a prova do isolamento esquerda e direita da háptica, sem
perguntar nada: o lado que o jogador escolhe diz se o lado chegou.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](O-os-caminhos.md) e a [O1](O1-os-caminhos.md) (o `_pista`, o `_respondeu`, a troca)
- [11 — monstro é peça do kit mais um brilho](../11-arte-e-personagens.md#as-regras-de-coerência)
- `nativo/nucleo/cegas.c`, `cega_haptica_veredito` (os lados `esq`/`dir`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J34",
	"titulo": "Fuga do Mecha Cego",
	"verbo": "Esconda-se!",
	"genero": "sobrevivencia",
	"icone": "haptica",
	"entradas": [Forja.ESQUERDA, Forja.DIREITA, Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S07_J34",
	"duracao": 100.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir"],
	"material": "pedra",
	"microjogo": {"verbo": "Esconda-se!", "segundos": 6.0},
	# a bancada: os lados da háptica saem das fugas
	"features": ["haptica_audio"],
	"gesto": "lados",
}
```

(`CRUZ` é do fantasma: ver "A falha".)

## Como se joga

A faixa é `MUS_S07_J34`, 140 bpm (uma batida ≈ 0,43 s). `ENTRADA := 4`.

**Uma ronda** do mecha dura `FRASE := 8` batidas; a ronda `f` começa em
`b0 = ENTRADA + 8 * f`. No começo de cada ronda o mecha escolhe onde está:
`_x_mecha = [-8.0, -4.0, 0.0, 4.0, 8.0][_rng.randi_range(0, 4)]` (nunca o x de
uma raia). Para o lugar `l`, o lado é `0` (esquerda) se `_x_mecha < RAIAS[l]`,
senão `1` (direita) — cada cavaleiro o sente de onde está.

| batida da ronda | o que acontece |
| --- | --- |
| 0, 1, 2, 3 | os passos do mecha: `material:metal` **só no atuador do lado** (`esq` ou `dir`), ganho `0.45 + 0.55 * (1.0 - absf(_x_mecha - RAIAS[l]) / 14.0)` (perto = forte); o da batida 0 vai pelo `_pista` (`o_que` = `"esquerda"`/`"direita"`), os outros por `Forja.som_haptica` direto |
| 4 | **a fuga:** ◀ ou ▶ no tempo, para o lado **oposto** (a nota `f`, alvo `Ritmo.t_da_batida(b0 + 4)`) |
| 5, 6, 7 | **o silêncio:** o mecha para; qualquer ◀ ▶ é barulho |
| 6 | o olho do mecha acende e o holofote varre: quem ficou exposto ou fez barulho é pego |

- **A entrada:** ◀ ou ▶ de `b0 + 3` até a nota passar. Lado oposto →
  `julgar_toque(l, alvo, f, true)`; mesmo lado → `_exposto[l] = true`,
  `_respondeu(l, f, "errado")`, `nota_perdida(l, f)`; nada até a nota passar →
  `_exposto[l] = true`, `_respondeu(l, f, "nenhuma")`, `nota_perdida(l, f)`.
  O boneco corre (`sprint`, meia batida) para o lado apertado da coluna.
- **O barulho:** ◀ ou ▶ depois de a nota da fuga fechar e antes de `b0 + 7.5`
  → `_exposto[l] = true` (o mecha ouve).
- **A varredura** (`b0 + 6`): cada lugar vivo com `_exposto[l]` é pego.
- **Pontos:** a fuga julgada marca `[0, 25, 40, 50][j]`; sobreviver à ronda
  marca 100.
- **O hoqueto:** todos fogem na mesma batida, mas cada um para o seu lado;
  a nota de cada um soa na TV (kit) — o acorde da fuga só fecha se todos
  acertam.
- **A partitura simples** (`Ritmo.simples[l]`): os passos chegam também um
  tempo antes (a ronda começa em `b0 - 1` para ele: cinco passos, mais tempo
  para sentir), sem mudar a batida da fuga.
- **O pico — o mecha corre:** as três rondas a partir de
  `_pico_f := floor((duracao / _t_batida() - ENTRADA) / FRASE / 2)`: os passos
  vêm em colcheias (oito, de `b0` a `b0 + 3.5`), o ganho é 1,0, e o holofote
  varre duas vezes (`b0 + 5` e `b0 + 7`).

## O cenário

- **Chão:** `Kit.arena(self, 5, 3)`.
- **A luz (terror = a casa escurecida):**
  `atmosfera(Color("#b9b0ff"), Tema.ROXO, false, 50, 22.0, -7.8, 0.05)`;
  tochas `#ffb070` a 0,35 em `(-9, 3, 2)` e `(9, 3, 2)`; a névoa do fundo,
  onde o mecha anda: `Efeitos.poeira(self, Vector3(0, 1.2, -5.0), Vector3(22, 2.4, 2.5), Color("#b9b0ff"), 80)`.
- **Cada raia:** `raia(l)` e `posicionar(l)`; `p.rotation.y = PI`,
  `p.preso = true`. Uma coluna de esconderijo
  `Kit.peca(self, "column", Vector3(RAIAS[l], 0, Z_JOGADOR - 0.9), 0.0, 1.6)`;
  o boneco fica à esquerda (`RAIAS[l] - 0.8`) ou à direita
  (`RAIAS[l] + 0.8`) dela; a posição anda por `lerpf` na meia batida depois
  da fuga (pela batida). A lanterna do boneco, na cor do lugar clareada,
  energia 0,9, alcance 2,2.
- **O mecha** (peças do kit mais um brilho, doc 11), um `Node3D` `_mecha` em
  `(_x_mecha, 0, -5.4)`: duas pernas `Kit.peca(_mecha, "column", Vector3(±0.7, 0, 0), 0.0, 1.3)`;
  o tronco `Kit.caixa(_mecha, Vector3(2.2, 1.4, 1.2), Vector3(0, 3.2, 0), aco)`
  (`aco := Kit.material(Color("#4a4452"), 0.0, 0.7)`); a cabeça
  `Kit.caixa(_mecha, Vector3(1.1, 0.7, 0.9), Vector3(0, 4.3, 0.1), aco)`; o
  olho `Kit.caixa(_mecha, Vector3(0.36, 0.2, 0.08), Vector3(0, 4.35, 0.58), olho)`
  com `olho` emissivo `#ff3a1a` (energia 0 apagado, 4 na varredura); o
  holofote `SpotLight3D` na cabeça, `#fff0d0`, `spot_angle` 18, alcance 14,
  energia 0 (6 na varredura, apontado para a raia de cada pego). O mecha fica
  **invisível** (`visible = false`) das batidas 0 a 5 da ronda — está na
  névoa, e só a mão sabe onde — e aparece em `b0 + 5.5` no x da ronda.
- **A câmera:** `camera_pos = Vector3(0, 6.8, 10.4)`, `camera_olhar = Vector3(0, 1.0, -2.2)`.
- **Checklist de arte (11):** o mecha é `column` + caixas + um olho; o
  emissivo só no olho e na borda da raia; `metallic` 0; nenhuma cor de lugar
  no mecha; a prancha com um boneco ao lado dele.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **háptica (protagonista)** | os passos do mecha **num atuador só**, mais fortes quanto mais perto | batidas 0 a 3 da ronda |
| háptica por material | a fuga julgada: o kit toca `material:pedra` | no toque |
| barra de luz | a cor do lugar a 30% (`Forja.luz(l, Forja.cor_do_lugar(l).darkened(0.7))` no `iniciar_jogo()`) | o jogo todo |
| alto-falante do dono | a nota dele (kit); `Forja.som_falante(l, "grito", 0.5)` quando é pego (o susto é só dele) | na captura |
| vibração | pego: `Forja.sentir(l, "golpe")` | na captura |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a música; `Som.tocar("martelo", mecha, -2.0)` a cada passo **só na varredura** (a TV não diz o lado antes); `Som.tocar("sino", null, -6.0)` na captura | — |

**Sem os dois lados:** no `iniciar_jogo()`, `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA) or not Forja.som_estereo(l, Forja.PAPEL_HAPTICA)`;
a `troca` tem `motivo` `sem_placa` ou `sem_estereo`. No rumble, o passo é
`Forja.sentir(l, "golpe_esq")` ou `"golpe_dir"` (os motores de cada lado).
O microfone não é usado.

## A falha

**Pego:** o holofote acende sobre ele, o boneco faz `die` e fica no chão; a
lanterna apaga; na mão, o golpe; no alto-falante, o grito (só dele). Com dois
ou mais, ele vira **fantasma**: continua na raia, e a cada ronda pode apertar
✕ uma vez nas batidas 0 a 3 — o barulho dele (`Som.tocar("carimbo", pos, -4.0)`
e faíscas na cor do lugar dele) deixa os passos da **ronda seguinte** mais
fracos (ganho × 0,6) para todos os vivos. Com um jogador só, ele tem três
vidas (`_vidas[l] = 3`): pego, perde uma, levanta (`emote-no`) e segue.

## O fim e o vencedor

`ultimo_em_pe`: com dois ou mais, quando sobra um vivo, ele vence e, no fim
daquela ronda, todos acabam. Todos pegos na mesma varredura: acaba ali, e a
colocação é pelos pontos. Com um, acaba nas três capturas ou no `duracao`.
`vencedor()`: os vivos pelos pontos; depois os pegos, do último pego ao
primeiro (`_pego_em[l]`, a batida da captura).

## Com menos de quatro

- **3, 2:** nada muda. **1:** três vidas (acima).
- **O controle que cai:** quem está sem controle não recebe passos nem nota e
  **não pode ser pego** (o holofote o ignora); quando volta, entra na próxima
  ronda que ainda não começou.
- **Duplas:** não há.

## O robô

Sente o lado nos atuadores (ou nos motores), foge para o outro no tempo, e
erra pelo temperamento.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if _pego[l] and presentes().size() == 1:
		return
	var f: int = _f
	var b0 := float(ENTRADA + FRASE * f)
	var b := Ritmo.batida()
	if _robo_f[l] != f:
		_robo_f[l] = f
		_robo_somas[l] = Vector2.ZERO
		_robo_fugiu[l] = false
		_robo_certo[l] = Forja.robo_acerta()
	if b >= b0 and b < b0 + 3.9:
		var s := _robo_sente(l)          # o mesmo do O2
		_robo_somas[l] += s
	if _pego[l]:
		# o fantasma faz barulho na batida 1 de cada ronda
		if b >= b0 + 1.0 and b < b0 + 1.2 and _robo_barulho[l] != f:
			_robo_barulho[l] = f
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		return
	if _robo_fugiu[l] or Ritmo.t_musica() < Ritmo.t_da_batida(b0 + 4):
		return
	var somas: Vector2 = _robo_somas[l]
	var lado := 0 if somas.x > somas.y else 1
	var para := Forja.DIREITA if lado == 0 else Forja.ESQUERDA
	if not _robo_certo[l]:
		para = Forja.ESQUERDA if para == Forja.DIREITA else Forja.DIREITA   # foge para o lado do mecha
	Forja.robo_apertar(l, para, 0.05)
	_robo_fugiu[l] = true
```

(Sem nada sentido, `somas` fica zero e ele foge para a direita — o defeito
de mentira que corta um atuador aparece como erro de lado no veredito.)

## Os ganchos

`godot/scripts/minigames/s07/fuga_do_mecha_cego.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Fuga do Mecha Cego (S07_J34). O mecha cego caça pelo som; os passos dele
## chegam só no atuador do lado em que ele está. Fuja para o outro lado da
## coluna no tempo (◀ ou ▶) e não se mexa enquanto ele escuta.
##
## A falha: o holofote acha; pego, vira fantasma que faz barulho (✕). O
## vencedor: o último em pé. O alto-falante do dono: o grito quando é pego. O
## registro mede: o lado de cada ronda (pista), a fuga (pista respondeu) e os
## lados da háptica para a bancada. O robô: sente o lado na placa virtual.
## Com menos de quatro: sozinho, três vidas. A régua: a tela não mostra o
## mecha até a varredura; o lado só existe na mão.

const FICHA := { ... }

const ENTRADA := 4
const FRASE := 8
const XS_MECHA := [-8.0, -4.0, 0.0, 4.0, 8.0]
const PONTOS_FUGA := [0, 25, 40, 50]
const PICO_RONDAS := 3

var _rng := RandomNumberGenerator.new()   ## o x do mecha (a semente do kit + 34)
var _f := 0                  ## a ronda da vez
var _x_mecha := 0.0
var _lado := [0, 0, 0, 0]    ## o lado do mecha para cada lugar nesta ronda
var _passos_feitos := -1     ## o último passo já mandado (0..7)
var _nota_aberta := [false, false, false, false]
var _fugiu_para := [-1, -1, -1, -1]
var _exposto := [false, false, false, false]
var _pego := [false, false, false, false]
var _pego_em := [-1.0, -1.0, -1.0, -1.0]
var _vidas := [1, 1, 1, 1]
var _abafado := false        ## um fantasma fez barulho nesta ronda: a próxima vem mais fraca
var _pico_f := 999
var _rumble := [false, false, false, false]
var _le := {}                ## lugar -> Cega (mecha à esquerda)
var _ld := {}                ## lugar -> Cega (mecha à direita)
var _fora := [false, false, false, false]
var _fim_ronda := -1         ## ultimo_em_pe: acaba no fim desta ronda
var _nos := {}
var _robo_f := [-1, -1, -1, -1]
var _robo_somas := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _robo_fugiu := [false, false, false, false]
var _robo_certo := [true, true, true, true]
var _robo_barulho := [-1, -1, -1, -1]


func montar() -> void:
	papel_som = Forja.PAPEL_HAPTICA
	camera_pos = Vector3(0, 6.8, 10.4)
	camera_olhar = Vector3(0, 1.0, -2.2)
	# o cenário, o mecha; para cada jogador: _nos[l], _le[l] = Cega.nova(), _ld[l] = Cega.nova(), gatilhos_off


func iniciar_jogo() -> void:
	_rng.seed = rng.seed + 34
	_pico_f = int(floor((duracao / _t_batida() - ENTRADA) / FRASE / 2.0))
	for l in presentes():
		# o rádio / sem estéreo: _rumble e a troca; a luz a 30%
		_vidas[l] = 3 if presentes().size() == 1 else 1
	_nova_ronda()


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	var b0 := float(ENTRADA + FRASE * _f)
	_passos_do_mecha(b, b0)          # batidas 0-3 (no pico, colcheias); o da batida 0 pelo _pista
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _pego[l]:
			_fantasma(l, b, b0)       # ✕ nas batidas 0-3: _abafado = true (uma vez por ronda por fantasma)
			continue
		_fuga(l, b, b0)               # a nota da fuga e o barulho do silêncio
	if b >= b0 + 6.0 and not _varreu:
		_varrer(b)                    # pega os expostos; no pico, também em b0 + 5 e b0 + 7
	if b >= b0 + FRASE:
		if _fim_ronda == _f:
			for l in presentes():
				acabou[l] = true
			return
		_f += 1
		_nova_ronda()
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS_FUGA[j])
	_respondeu(l, _f, "certo")
	if not _rumble[l]:
		Cega.certo(_le[l] if _lado[l] == 0 else _ld[l])


func falha(l: int) -> void:
	# a fuga errada ou atrasada não derruba na hora: deixa exposto, e a varredura decide
	jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var vivos := presentes().filter(func(l): return not _pego[l])
	vivos.sort_custom(func(a, b): return pontos[a] > pontos[b])
	var pegos := presentes().filter(func(l): return _pego[l])
	pegos.sort_custom(func(a, b): return _pego_em[a] > _pego_em[b])
	return vivos + pegos


func dar_vereditos(l: int) -> Array:
	var tem := Forja.som_tem(l, Forja.PAPEL_HAPTICA)
	var v := Forja.cega_veredito(l, "haptica_audio", {"cega": Cega.nova(), "esq": _le[l], "dir": _ld[l], "tem": tem})
	return [] if v.is_empty() else [v]
```

(Declare também `var _varreu := false`, zerado em `_nova_ronda()`.)

**Os lados para a bancada.** A fuga diz de que lado a mão sentiu o mecha:
fugir para a direita é "o mecha está à esquerda" (`0`); fugir para a
esquerda é "está à direita" (`1`). O `Cega` é `_le[l]` quando o mecha estava
à esquerda e `_ld[l]` quando à direita. Fuga certa: `Cega.certo(c)` (no
`toque`). Fuga para o lado errado: `Cega.errado(c, dito)`, com `dito` = o
lado que a fuga disse. Sem fuga: `Cega.perdido(c)`. Só entra quem tem os dois
atuadores (`not _rumble[l]`): no rumble o lado é dos motores e não é o
veredito da háptica.

`_nova_ronda()`: sorteia `_x_mecha` com `_rng`, calcula `_lado[l]` de cada
um, zera `_exposto`, `_fugiu_para`, `_varreu`, `_passos_feitos`, e abre a
nota de cada vivo conectado: `nova_nota(l, _f, Ritmo.t_da_batida(b0 + 4))`.
`_varrer(b)`: para cada vivo conectado com `_exposto[l]`: `_pego[l]` (ou
`_vidas[l] -= 1` com um jogador), `_pego_em[l] = b`, o golpe, o grito, o
`die`, o holofote nele; depois, com dois ou mais e um só vivo,
`_fim_ronda = _f`; todos pegos: `_fim_ronda = _f`. Quem sobreviveu marca 100.
O `_pista` e o `_respondeu` são os do O1; `_robo_sente` é o do O2.

Dica: `["@dpad_left", "@dpad_right"]` sob a raia enquanto `not aprendeu(l)`;
o fantasma, `["@cross"]`. `status(l)`: `"Vivo"` / `"Fantasma"` (com um
jogador, `"%d vidas" % _vidas[l]`).

Catálogo: `"S07_J34"` em `MINIGAMES` e na seção `S07`. Traduções:
`"Fuga do Mecha Cego": "Escape the Blind Mech"`, `"Esconda-se!": "Hide!"`,
`"Vivo": "Alive"`, `"Fantasma": "Ghost"`, `"%d vidas": "%d lives"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

## O que o registro mede

- `pista` `mandou` de cada ronda com o lado (`o_que`) e a `via`; `respondeu`
  com a fuga (`certo`/`errado`/`nenhuma`);
- a prova do isolamento esquerda e direita dos atuadores: com os lados de
  cada controle, a noite vê "P3 fugiu certo 90% com o mecha à esquerda e 40%
  à direita" — o atuador direito não chega;
- `troca` com `sem_estereo` quando a placa só tem um canal; o veredito
  `haptica_audio` (lados) na bancada.

## Armadilhas

- **Nunca os dois atuadores no passo do mecha.** `Forja.som_haptica(l, som, "")`
  para a esquerda e `Forja.som_haptica(l, "", som)` para a direita. O acerto do
  kit toca nos dois lados na batida 4 (a fuga), depois dos passos: não
  atrapalha o lado.
- **A TV não pode dizer o lado.** Nenhum som na TV durante os passos; o
  mecha invisível até `b0 + 5.5`. Um som posicional do mecha na TV
  entregaria o lado a todos.
- **O barulho do silêncio** só conta depois de a nota da fuga fechar
  (senão a própria fuga seria barulho).
- **Quem está sem controle não é pego** — senão o cabo que cai elimina.
- **Na prova o pico não chega** (o fim é pelo `duracao`).
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos; aguenta o cabo que cai e volta; fecha com vencedor; com
`--bancada` o `haptica_audio` sai medido pelos lados; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com a prancha olhada (o mecha aparece só
na varredura; os pegos caídos; nada de tela vazia no escuro).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_mecha_cego()`:

```gdscript
## S07_J34: o passo do mecha treme só o atuador do lado dele, no controle de
## cada um; o robô foge para o outro lado; fecha com vencedor.
func _prova_mecha_cego() -> void:
	var sala = await _comeca_a_sala("S07_J34")
	if sala == null:
		return
	var viu := false
	var q := 0
	while is_instance_valid(sala) and sala.fase == "jogo" and q < 12000:
		var b := Ritmo.batida()
		var b0 := float(sala.ENTRADA + sala.FRASE * sala._f)
		if not viu and b > b0 + 0.05 and b < b0 + 0.3:
			for l in 4:
				var v := Forja.som_virtual(l)
				var lado: int = sala._lado[l]
				var dele := float(v.get("esq" if lado == 0 else "dir", 0.0))
				var outro := float(v.get("dir" if lado == 0 else "esq", 1.0))
				if dele > 0.05:
					_esperar(outro < 0.02, "mecha P%d: o passo treme só o atuador da %s (%.2f × %.2f)" % [
						l + 1, "esquerda" if lado == 0 else "direita", dele, outro])
					viu = true
		await _quadros(1)
		q += 1
	_esperar(viu, "mecha: o passo chegou a um atuador só")
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "mecha: fechou")
	if is_instance_valid(sala):
		_esperar(sala.colocacao.size() == 4, "mecha: a colocação tem os quatro")
```

No `_prova_do_relatorio()`: `pista` do `S07_J34` com `evento == "respondeu"`
≥ 4.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S07_J34`, com um controle
no cabo. O lado do passo tem de ser óbvio na palma sem olhar a tela; o mecha
correndo (o pico) tem de dar medo; o fantasma que faz barulho tem de fazer os
vivos xingarem. Com `--bancada`, confira no relatório o `haptica_audio` com
os lados.

## Ao terminar

- No [quadro](README.md), a linha O4: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Fuga do Mecha Cego — o lado do passo só na mão`
