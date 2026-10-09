# G05 — A câmera dos quatro

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F09 (a prova visual), G01 (`Lente`; quem chegar primeiro cria) · **Usado por:** H04 (a chave `"camera"` da ficha do minigame vira `camera_modo`), G06 (a lente do salão), G16 (o movimento reduzido), as fichas I a R (`tremer`)

## Por quê

Numa sala, a câmera é uma pose fixa a 40° (`camera_pos`, `camera_olhar`).
Nos minigames em que os cavaleiros andam, ela precisa enquadrar quem está em
jogo, sem tela dividida e sem salto. O tremor hoje é um número solto de cada
sala, com roll de até 0,7°; o 01 pede o tremor do evento, em três degraus,
sem roll. E cada momento tem a sua lente em milímetros, não os 40° de todos.

## Ler antes

- [01 — as regras da câmera e a tabela de lente](../arte/01-cinema.md#as-regras-da-câmera) (o plano de cada momento está logo abaixo, na mesma página)
- [diversão — o exagero do impacto](../diversao/README.md#o-exagero-do-impacto) (os quatro degraus, o tremor de cada um)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04) (a chave `"camera": "fixa", "grupo", "corrida"` da ficha)

Os números do movimento reduzido do 10 (a seção «O movimento reduzido»)
estão copiados em O alvo.

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/enquadramento.gd` e `.uid` (novo, `class_name Enquadramento`) | — |
| `godot/scripts/mundo/lente.gd` e `.uid` (novo, `class_name Lente`) | **G01** (o mesmo conteúdo: o primeiro que chegar cria) |
| `godot/scripts/salas/sala.gd` (os modos, `tremer`, `abalo`) | **G04** (os sinais), **G07** |
| `godot/scripts/salas/prova.gd` (o modo `"grupo"`) | — |
| `godot/scripts/main.gd` (`_pose_da_camera`, `_lente`, `_enquadrar`, `_mover_camera`, `_tangentes`) | **G01, G02, G03, G04, G06, G07, G08** |
| `docs/jogo/13-arquitetura.md` (o kit: a câmera e o tremor) | **H04** |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |

## Como se joga

Não se aplica: a câmera não tem regra de jogo. Ela não muda julgamento,
janela nem ponto.

## A cena

### A lente de cada momento (01)

`Lente.fov(mm) = rad_to_deg(2 · atan(12 / mm))`: o FOV vertical de um sensor
de 24 mm, em `KEEP_HEIGHT`. Numa tela mais estreita que 16:9, o
`KEEP_WIDTH` converte o mesmo FOV como hoje (`main.gd:968-972`).

| momento | estado do main | lente | FOV vertical | de quem |
| --- | --- | --- | --- | --- |
| arena (jogo), modo `"fixa"` ou `"grupo"` | `"sala"` | 35 mm | 37,8° | esta ficha |
| corrida (jogo), modo `"corrida"` | `"sala"` | 28 mm | 46,4° | esta ficha |
| dupla (jogo), modo `"dupla"` | `"sala"` | 50 mm | 27,0° | esta ficha |
| pódio | `"podio"` | 35 mm | 37,8° | esta ficha |
| salão | `"salao"` | 35 mm | 37,8° | a pose é da G06; a lente entra aqui |
| título | `"titulo"` | 85 mm | 16,1° | G01 |
| montagem | `"lobby"` | `Lente.PADRAO` (40°) até a G13 | 40,0° | G13 |

A sala pode trocar a lente pela ficha dela (`camera_lente`); sem ela, vale a
do modo. A lente fica entre 24 e 100 mm (`clampf`): 18 mm é só da
Dissonância (G16), e acima de 100 mm a cena de sofá achata.

**A pose fixa não muda de enquadramento.** As salas de hoje foram
desenhadas para 40°. Com outra lente, a câmera recua (ou chega perto) na
mesma direção, pelo fator `Lente.recuo(mm) = mm / Lente.PADRAO`: a 35 mm,
1,0616; a 50 mm, 1,5165; a 28 mm, 0,8493. A raia que cabia continua
cabendo, e só a perspectiva muda (`tan(fov/2) = 12/mm`, logo a altura vista
a uma distância d é `2 · d · 12 / mm`).

### Os quatro modos (01, o plano de cada momento)

| modo | a pose | quando |
| --- | --- | --- |
| `"fixa"` | `[olhar + (pos − olhar) · recuo, olhar]`, com `camera_pos` e `camera_olhar` da sala | a arena parada (as salas de hoje) |
| `"dupla"` | a fixa, com o empurrão: `puxa = (camera_foco − camera_olhar) · 0,15`, `puxa.y = 0`, `puxa.limit_length(1.5)`, somado às duas | dois frente a frente (01: «empurra 15 % na direção da ação») |
| `"grupo"` | `Enquadramento.grupo(alvos_da_camera(), dir, camera_distancia, tg.x, tg.y)` | a arena onde os quatro andam |
| `"corrida"` | `Enquadramento.corrida(alvos_da_camera(), camera_frente, dir, camera_distancia, tg.x, tg.y)`; o main chama `sala.puxar_os_de_tras()` a cada quadro | quem corre e o caminho à frente |

- `dir = (camera_pos − camera_olhar).normalized()`: a direção é a que a sala
  desenhou; só o centro e a distância mudam.
- A margem é de 15 % (06) e está dentro de `_caber`.
- O amortecimento é o `lerp` de hoje (`k = minf(1, dt · 4)`): a câmera anda,
  nunca salta. Na entrada da sala, a cortina põe a pose na hora (`_trocar`).
- A câmera não corta do apito ao apito (01, regra 1): nenhum modo troca
  durante a fase `"jogo"`.

### O tremor do evento (01, regra 5; diversão, o exagero)

| degrau | constante | amplitude | dura |
| --- | --- | --- | --- |
| toque | — | nenhum | — |
| golpe | `Sala.TREMOR_GOLPE` | 0,02 m | 1 batida |
| estrondo | `Sala.TREMOR_ESTRONDO` (e o nome antigo `TREMOR_EXPLOSAO`, igual) | 0,05 m | 2 batidas |
| catástrofe | `Sala.TREMOR_CATASTROFE` | 0,08 m | 4 batidas |

- A batida é `60.0 / Ritmo.bpm` (120 BPM sem música: 500 ms).
- O balanço anda no plano da câmera, sem roll:
  `camera.global_position += (r · sin(_t · 71) + u · sin(_t · 53 + 1,3)) · abalo`,
  com `r` e `u` o eixo direito e o de cima da câmera. O
  `rotate_object_local(Vector3.BACK, …)` de hoje sai (01, regra 4: o roll é 0).
- `abalo` cai em linha reta da amplitude a 0 na duração do degrau. Um tremor
  novo só substitui o vivo se a amplitude dele é maior ou igual ao `abalo` de
  agora.
- O `tremor` antigo das salas (A Prova, A Voz) continua: o main usa
  `maxf(sala.abalo, minf(0.08, 0.12 · sala.tremor))`. Nada passa de 0,08 m.
- O tremor nunca tira ninguém do quadro: 0,08 m é menos que a margem de 15 %
  na menor distância (a 9 m e 35 mm, a meia altura vista é 9 · 12/35 = 3,09 m,
  e 15 % disso é 0,46 m).

**O movimento reduzido** (10): nenhum tremor. Até a G16, `not Opcoes.tremor`;
depois, `Opcoes.movimento == 1`. A lente e os modos não mudam (não são
movimento de câmera, são enquadramento).

## O som

Não se aplica: a câmera não toca nada. O som de cada evento que treme é da
ficha do evento.

## O controle

Não se aplica: a câmera não vibra nem acende. O 01 casa a amplitude do
tremor com a da vibração, mas quem vibra é a ficha do evento (03, o casamento
evento por evento).

## O cavaleiro

- **Os alvos:** `alvos_da_camera()` devolve o `global_position` dos
  `jogadores` visíveis. A Prova devolve só quem ainda está na partida.
- **A altura:** `Enquadramento.ALTURA_DO_BONECO := 1.6` m. Ela cobre o
  cavaleiro mais alto das quatro raças da G08: o Mini Characters tem 0,67 de
  altura, ×2,0 de `ESCALA` = 1,34 m, e a antena do Autômato soma 0,105 × 2 =
  0,21 m, 1,55 m ao todo. A raça não muda a cápsula (raio 0,42, altura 1,5).
- **Os stats:** esta ficha não lê stat.

## As reações

Não se aplica: a câmera não reage. Os carimbos e os adesivos são 2D, por
cima (G04, G16).

## A diversão

**O momento:** n'A Prova, os quatro correm para os quatro cantos da arena; a
câmera abre sem salto e ninguém sai da tela; quando um volta ao meio, ela
fecha de novo. **Como se confere:** a prova, em 300 quadros de robô, conta
zero quadros com um cavaleiro (pé e cabeça) fora do frustum; a prancha da
Prova (F09) mostra o grupo inteiro nas partidas de 4, 2 e 1.

## O estado de hoje

- `godot/scripts/salas/sala.gd:12-16`: `camera_pos := Vector3(0, 13, 13)`,
  `camera_olhar := Vector3.ZERO`, `tremor := 0.0`. Cada sala põe a sua pose
  (`prova.gd:89-90`: `Vector3(0, 17.5, 13.2)`, `Vector3(0, 0, 0.9)`).
- `godot/scripts/main.gd:925-958`, `_pose_da_camera()`: título, lobby, pódio
  (`[Vector3(-4.6, 4.0, 19.5), Vector3(-4.6, 0.9, 4.4)]`), a sala
  (`[sala.camera_pos, sala.camera_olhar]`) e o salão (a caixa de quem
  está visível, distância de 11,5 a 18).
- `main.gd:963-975`: `FOV_16_9 := 40.0` e `_enquadrar()` (o `KEEP_WIDTH` em
  tela estreita).
- `main.gd:978-989`, `_mover_camera(dt)`: o `lerp` com `k = dt · 4,0` (1,2 no
  título); o tremor soma `Vector3(sin(_t·71), sin(_t·53+1,3), 0) · 0,12 · tremor`
  em coordenadas do mundo, e um roll de `sin(_t·47) · 0,012 · tremor` rad, só
  com `Opcoes.tremor`.
- O tremor é escrito e apagado por cada sala: `prova.gd:370` (`tremor = 0.7`)
  e `prova.gd:624` (desconta 1,5 por segundo); `voz.gd:505`
  (`tremor = flash * 1.4` a cada quadro).
- A Prova é a única sala em que os quatro andam numa arena
  (`ARENA_X := 11.3`, `ARENA_Z := 6.9`, 22,6 × 13,8 m); a câmera fixa a vê
  de longe, a 21,4 m.
- Nove fichas de minigame já chamam `tremer(Sala.TREMOR_GOLPE)` ou
  `tremer(Sala.TREMOR_EXPLOSAO)`; a K1 chama `tremer(float(m.tremor))`; a M1
  usa a amplitude em metros (0,02 m, 0,05 m, 0,08 m).

## O alvo

### `Lente` (`godot/scripts/mundo/lente.gd`)

```gdscript
class_name Lente
## A lente em mm vira FOV vertical (arte/01): sensor de 24 mm de altura.
static func fov(mm: float) -> float:
	return rad_to_deg(2.0 * atan(12.0 / mm))
## O FOV de hoje (40°) em mm, para quem ainda não tem lente decidida.
const PADRAO := 32.97
## Quanto a pose fixa recua para a lente `mm` ver o mesmo que os 40° viam.
static func recuo(mm: float) -> float:
	return mm / PADRAO
```

(Se a G01 já criou o arquivo, só acrescentar `recuo`.)

### `Sala` (`sala.gd`)

```gdscript
var camera_modo := "fixa"                    ## "fixa", "dupla", "grupo", "corrida" (a ficha do minigame, 13)
var camera_lente := 0.0                      ## mm; 0: a do modo (LENTE_DO_MODO)
var camera_distancia := Vector2(9.0, 18.0)   ## a distância mínima e a máxima, em m (grupo e corrida)
var camera_frente := Vector3(0, 0, -1)       ## corrida: para onde se corre
var camera_alcance := 14.0                   ## corrida: quem fica mais que isto atrás do líder volta para a borda
var camera_foco := Vector3.ZERO              ## dupla: onde está a ação agora (ZERO: nenhuma)
var abalo := 0.0                             ## a amplitude do tremor agora, em m
const LENTE_DO_MODO := {"fixa": 35.0, "dupla": 50.0, "grupo": 35.0, "corrida": 28.0}
const TREMOR_GOLPE := 0.02
const TREMOR_ESTRONDO := 0.05
const TREMOR_EXPLOSAO := 0.05                ## o nome que as fichas de minigame já usam: o estrondo
const TREMOR_CATASTROFE := 0.08

## A lente desta sala agora, em mm (24 a 100).
func lente() -> float:
	return clampf(camera_lente if camera_lente > 0.0 else float(LENTE_DO_MODO.get(camera_modo, 35.0)), 24.0, 100.0)
## As posições que a câmera enquadra: os bonecos visíveis (a sala troca por «só os vivos»).
func alvos_da_camera() -> Array
## O tremor do evento: amplitude em m; o degrau sai dela (≤ 0,02 golpe, ≤ 0,05 estrondo, senão catástrofe).
func tremer(amplitude: float) -> void
## Corrida: a borda empurra, não mata.
func puxar_os_de_tras() -> void
```

`tremer(amplitude)`:

```gdscript
var _abalo_ini := 0.0
var _abalo_dura := 0.0   ## s
func tremer(amplitude: float) -> void:
	var a := clampf(amplitude, 0.0, TREMOR_CATASTROFE)
	if a <= 0.0 or a < abalo:
		return
	var batidas := 1.0 if a <= TREMOR_GOLPE else (2.0 if a <= TREMOR_ESTRONDO else 4.0)
	_abalo_ini = a
	_abalo_dura = batidas * 60.0 / maxf(1.0, Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
	abalo = a
```

`Sala._process(dt)` desconta: `if abalo > 0.0: abalo = maxf(0.0, abalo - _abalo_ini * dt / _abalo_dura)`.

### As contas (`godot/scripts/enquadramento.gd`, `class_name Enquadramento extends RefCounted`, estático, sem nó)

```gdscript
const MARGEM := 0.15
const ALTURA_DO_BONECO := 1.6

## [posição, olhar] que põe todos os alvos (os pés e a cabeça) na tela.
static func grupo(alvos: Array, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var pontos := _com_cabeca(alvos)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for p in pontos:
		mn = mn.min(p)
		mx = mx.max(p)
	return _caber(pontos, (mn + mx) * 0.5, dir, dist, tan_v, tan_h)

## O líder e o último sempre na tela; o centro puxado para o líder (65 %).
static func corrida(alvos: Array, frente: Vector3, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var lider: Vector3 = alvos[0]
	var ultimo: Vector3 = alvos[0]
	for a in alvos:
		if a.dot(frente) > lider.dot(frente):
			lider = a
		if a.dot(frente) < ultimo.dot(frente):
			ultimo = a
	var centro := ultimo.lerp(lider, 0.65) + Vector3(0, ALTURA_DO_BONECO * 0.5, 0)
	return _caber(_com_cabeca([lider, ultimo]), centro, dir, dist, tan_v, tan_h)

## As posições com quem ficou mais de `alcance` atrás do líder trazido para a borda.
static func puxar(posicoes: Array, frente: Vector3, alcance: float) -> Array:
	var topo := -INF
	for p in posicoes:
		topo = maxf(topo, p.dot(frente))
	var saida: Array = []
	for p in posicoes:
		var atras: float = topo - p.dot(frente)
		saida.append(p + frente * (atras - alcance) if atras > alcance else p)
	return saida

static func _com_cabeca(alvos: Array) -> Array:
	var pontos: Array = []
	for a in alvos:
		pontos.append(a)
		pontos.append(a + Vector3(0, ALTURA_DO_BONECO, 0))
	return pontos

## A menor distância (entre dist.x e dist.y) em que todos os pontos cabem com a margem.
## Câmera em C = centro + dir · d, olhando para o centro: o ponto p tem profundidade
## (p − centro)·f + d, com f = −dir; cabe se |x| e |y| ≤ profundidade × tan / (1 + MARGEM).
static func _caber(pontos: Array, centro: Vector3, dir: Vector3, dist: Vector2, tan_v: float, tan_h: float) -> Array:
	var f := -dir
	var r := f.cross(Vector3.UP).normalized()
	var u := r.cross(f)
	var k := 1.0 + MARGEM
	var d := dist.x
	for p in pontos:
		var v: Vector3 = p - centro
		var z0 := v.dot(f)
		d = maxf(d, absf(v.dot(r)) * k / tan_h - z0)
		d = maxf(d, absf(v.dot(u)) * k / tan_v - z0)
	d = minf(d, dist.y)
	return [centro + dir * d, centro]
```

### O main (`main.gd`)

```gdscript
## A lente de agora, em mm (01). A G01 põe "titulo"; a G13, "lobby".
func _lente() -> float:
	match estado:
		"sala":
			return sala.lente() if sala else 35.0
		"salao", "podio":
			return 35.0
	return Lente.PADRAO

## A tangente de meio campo de visão: (vertical, horizontal).
func _tangentes() -> Vector2:
	var tam := get_viewport().get_visible_rect().size
	var aspecto := tam.x / maxf(tam.y, 1.0)
	var t := tan(deg_to_rad(camera.fov) * 0.5)
	if camera.keep_aspect == Camera3D.KEEP_HEIGHT:
		return Vector2(t, t * aspecto)
	return Vector2(t / aspecto, t)
```

- `_enquadrar()`: `Lente.fov(_lente())` no lugar de `FOV_16_9`, nos dois ramos.
- `_pose_da_camera()`, `"sala"`: `return _pose_da_sala()`, com a tabela dos
  modos. `"podio"`: a pose de hoje com o recuo de 35 mm (o olhar fica, a
  posição vai a `olhar + (pos − olhar) · 1,0616`).
- `_mover_camera(dt)`: o tremor da tabela, com
  `var a := maxf(sala.abalo, minf(0.08, 0.12 * sala.tremor))`, sem roll.
- `_process`, antes de `_mover_camera(dt)`:
  `if estado == "sala" and sala and sala.camera_modo == "corrida": sala.puxar_os_de_tras()`.

### A Prova passa a `"grupo"`

Em `prova.gd`, junto da pose: `camera_modo = "grupo"` e
`camera_distancia = Vector2(17.0, 25.5)`. A arena de 22,6 × 13,8 m cabia
inteira a 24 m com 40°; com 35 mm, 24 × 1,0616 = 25,5 m. A pose fixa de hoje
continua sendo a direção.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3 e 5.

1. **O 13 primeiro:** no [kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04),
   a linha da câmera passa a dizer: «o kit põe `camera_modo` pela chave
   `"camera"` da ficha (`fixa`, `dupla`, `grupo`, `corrida`); a ficha pode
   trazer `"camera_lente"` (mm), `"camera_distancia": Vector2(min, max)` e, na
   corrida, `"camera_frente"`; os eventos tremem com
   `tremer(Sala.TREMOR_GOLPE)`, `TREMOR_ESTRONDO` ou `TREMOR_CATASTROFE`
   (`TREMOR_EXPLOSAO` é o estrondo)». Na tabela da linha 386, acrescentar
   `camera_lente`, `lente()`, `TREMOR_ESTRONDO` e `TREMOR_CATASTROFE`.
2. **`lente.gd`** (ou só o `recuo`, se a G01 já o criou) e
   **`enquadramento.gd`**; `"$GODOT" --headless --path godot --import --quit`
   e commitar os dois `.uid`.
3. **`sala.gd`:** as variáveis, `lente()`, `alvos_da_camera()`, `tremer()`,
   `puxar_os_de_tras()` (aplica `Enquadramento.puxar` às posições dos
   visíveis e devolve cada boneco à sua posição nova) e o desconto do `abalo`
   em `_process`.
4. **`main.gd`:** `_lente()`, `_tangentes()`, `_enquadrar()`, `_pose_da_sala()`,
   o pódio, o tremor sem roll e o `puxar_os_de_tras`.
5. **`prova.gd`:** o modo `"grupo"` e a distância.
6. **As provas** (ver Provas).

## Armadilhas

- **`.uid`** de `enquadramento.gd` e `lente.gd`.
- **As contas ficam puras** (sem nó, sem `get_viewport`): a prova as confere
  com uma `Camera3D` de verdade.
- **A direção vem da sala:** nada de ângulo novo; `dir` sai da pose que a
  sala já tinha.
- **O recuo só na fixa e na dupla:** no grupo e na corrida, `_caber` já usa as
  tangentes da lente de verdade; recuar de novo afasta duas vezes.
- **Distância máxima:** no máximo, a câmera para; na corrida, quem não cabe é
  puxado (`puxar_os_de_tras`); no grupo, a arena tem de caber no máximo.
- **O tremor e o conforto:** com o movimento reduzido, nem o `abalo` nem o
  `tremor` antigo tremem.
- **O tempo do tremor é de relógio:** o `dt` somado, para o `--fixed-fps` da
  prova visual não encolher nem esticar o degrau.
- **Lugar vazio:** `alvos_da_camera()` só conta os visíveis; sem ninguém, a
  pose fixa.
- **O robô:** nada de `Forja.robo` aqui.
- **A foto d'A Prova muda:** a câmera passa a seguir o grupo; a comparação
  das fotos (`tests/telas.sh comparar`) acusa diferença nela, e é esperado.
- **Os casos que quebram:** `--robo=bom|medio|ruim` (o ruim anda menos e se
  espalha menos), partidas de 1 e 2 jogadores (com 1 alvo, a distância
  mínima) e o controle que cai e volta (`simulador_cabo`): o boneco dele
  continua visível e continua alvo.

## Não fazer

- Não criar tela dividida nem câmera por jogador.
- Não trocar as salas fixas de hoje para `"grupo"` além d'A Prova (as fichas
  H e I a R trocam as delas).
- Não mexer na pose do título (G01), do salão (G06), da montagem (G13) nem
  no plano do resultado, do inserto, do virar da fita e dos créditos.
- Não fazer o hit-stop nem o congelar de 3 quadros do apito: são do
  `secao.gd` de cada seção (G16, a parada; K1, `_parar`).
- Não cortar no tempo 1 nem mexer em `_trocar`: o corte na batida é da G01 e
  da G07.
- Não fazer o tremor pela câmera no lugar do evento: a sala pede `tremer()`,
  a câmera só obedece.
- Não fazer a Dissonância (o roll de 6° e os 18 mm): é da G16.

## Pronto quando

Com quatro robôs espalhados n'A Prova, nenhum cavaleiro sai da tela no modo
grupo; as contas da corrida põem o líder e o último na tela e trazem para a
borda quem fica para trás; a sala está a 35 mm (37,8°) com o mesmo
enquadramento de hoje; o golpe treme 1 batida, o estrondo 2 e a catástrofe
4, sem roll; com o movimento reduzido, nada treme.

E só fecha com `bash tests/prova_visual.sh` passando (a passada com
`--fixed-fps 60`, na sessão) e a prancha olhada; foto de `tests/telas.sh` não
é prova ([a prova visual](../13-arquitetura.md#a-prova-visual--f09)). A
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, duas funções novas. No `_ready()`,
`_prova_das_contas_da_camera()` vai antes de `jogo = load(...)` (linha 59; não
precisa do jogo), e `await _prova_da_camera_na_prova()` depois de
`await _prova_de_fogo()` (linha 64).

```gdscript
## As contas da câmera e da lente, com uma câmera de verdade (35 mm, 16:9).
func _prova_das_contas_da_camera() -> void:
	_esperar(absf(Lente.fov(35.0) - 37.85) < 0.01, "a lente de 35 mm é 37,8° (%.2f)" % Lente.fov(35.0))
	_esperar(absf(Lente.fov(Lente.PADRAO) - 40.0) < 0.01, "o padrão continua 40°")
	_esperar(absf(Lente.recuo(35.0) - 1.0616) < 0.001, "a fixa recua 6,16 % a 35 mm")
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = Lente.fov(35.0)
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	var tv := tan(deg_to_rad(cam.fov) * 0.5)
	var tam := get_viewport().get_visible_rect().size
	var th := tv * tam.x / maxf(tam.y, 1.0)
	var dir := Vector3(0, 17.5, 12.3).normalized()
	var cantos := [Vector3(-10, 0, -6), Vector3(10, 0, -6), Vector3(-10, 0, 6), Vector3(10, 0, 6)]
	var pose := Enquadramento.grupo(cantos, dir, Vector2(8.0, 40.0), tv, th)
	cam.global_position = pose[0]
	cam.look_at(pose[1])
	var dentro := 0
	for c in cantos:
		if cam.is_position_in_frustum(c) and cam.is_position_in_frustum(c + Vector3(0, 1.6, 0)):
			dentro += 1
	_esperar(dentro == 4, "câmera grupo: os quatro cantos da arena na tela (%d)" % dentro)
	var perto := Enquadramento.grupo([Vector3.ZERO, Vector3(0.5, 0, 0)], dir, Vector2(12.0, 40.0), tv, th)
	_esperar(is_equal_approx((perto[0] - perto[1]).length(), 12.0), "câmera grupo: dois juntos, a distância mínima")
	var corrida := [Vector3(0, 0, -20), Vector3(1, 0, -12), Vector3(-1, 0, -6), Vector3(0, 0, -2)]
	var pc := Enquadramento.corrida(corrida, Vector3(0, 0, -1), dir, Vector2(8.0, 40.0), tv, th)
	cam.global_position = pc[0]
	cam.look_at(pc[1])
	_esperar(cam.is_position_in_frustum(corrida[0]) and cam.is_position_in_frustum(corrida[3]), "câmera corrida: o líder e o último na tela")
	var puxadas := Enquadramento.puxar(corrida, Vector3(0, 0, -1), 10.0)
	_esperar(is_equal_approx(puxadas[3].z, -10.0) and puxadas[0] == corrida[0], "câmera corrida: quem ficou 18 m atrás volta para 10 m do líder")
	cam.queue_free()


## A Prova no modo grupo, com o robô jogando: ninguém sai da tela; o tremor por degrau, sem roll.
func _prova_da_camera_na_prova() -> void:
	var sala = await _comeca_a_sala("prova")
	if sala == null:
		return
	_esperar(sala.camera_modo == "grupo", "A Prova enquadra o grupo")
	_esperar(absf(jogo.camera.fov - Lente.fov(35.0)) < 0.05 or jogo.camera.keep_aspect == Camera3D.KEEP_WIDTH,
		"a sala filma a 35 mm (%.2f°)" % jogo.camera.fov)
	await _quadros(60)
	var fora := 0
	for i in 300:
		await _quadros(1)
		for p in jogo.jogadores:
			if not p.visible:
				continue
			for h in [0.0, Enquadramento.ALTURA_DO_BONECO]:
				if not jogo.camera.is_position_in_frustum(p.global_position + Vector3(0, h, 0)):
					fora += 1
	_esperar(fora == 0, "A Prova: em 300 quadros, nenhum pé nem cabeça fora da tela (%d)" % fora)
	# os três degraus: a duração em batidas, sem roll
	var batida := 60.0 / (Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
	for caso in [[Sala.TREMOR_GOLPE, 1.0], [Sala.TREMOR_ESTRONDO, 2.0], [Sala.TREMOR_CATASTROFE, 4.0]]:
		sala.abalo = 0.0
		sala.tremer(caso[0])
		_esperar(is_equal_approx(sala.abalo, caso[0]), "o degrau %.2f m começa inteiro" % caso[0])
		var t0 := Time.get_ticks_msec()
		var roll := 0.0
		while sala.abalo > 0.0 and Time.get_ticks_msec() - t0 < 4000:
			await _quadros(1)
			roll = maxf(roll, absf(jogo.camera.global_basis.x.y))
		var durou := (Time.get_ticks_msec() - t0) / 1000.0
		_esperar(absf(durou - caso[1] * batida) < 0.1, "o degrau %.2f m dura %d batida(s) (%.2f s)" % [caso[0], int(caso[1]), durou])
		_esperar(roll < 0.001, "o tremor não gira o quadro (%.4f)" % roll)
	sala.tremer(1.0)
	_esperar(sala.abalo <= Sala.TREMOR_CATASTROFE, "nada treme mais que 0,08 m")
	# o movimento reduzido
	var antes = Opcoes.tremor
	Opcoes.tremor = false
	sala.abalo = 0.0
	sala.tremer(Sala.TREMOR_CATASTROFE)
	await _quadros(2)
	var p0: Vector3 = jogo.camera.global_position
	await _quadros(1)
	var anda := (jogo.camera.global_position - p0).length()
	_esperar(anda < 0.02, "com o movimento reduzido, a câmera não treme (%.3f m)" % anda)
	Opcoes.tremor = antes
	sala.terminar()
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(2)
		q += 2
```

(Se a F03/F08 fizeram o fim avançar sozinho em 6 s, o laço final espera por
isso; se não, aperte ✕ no simulado 0 com `_aperta(0, Forja.CRUZ)` depois de
`terminar()`. Se a G16 já trocou `Opcoes.tremor` por `Opcoes.movimento`, a
prova troca `Opcoes.tremor = false` por `Opcoes.movimento = 1`.)

**A prova visual (F09):** `bash tests/prova_visual.sh`; na prancha d'A Prova,
o grupo inteiro na tela nas partidas de 4, 2 e 1, sem salto entre quadros; as
outras salas com o mesmo enquadramento de antes (o recuo da lente).

## Para o André (local)

1. `./run-local.sh -- --sala=prova`: correr com os quatro para os cantos; a
   câmera abre e fecha sem salto, ninguém some.
2. Na mesma sala, o susto (o `tremor = 0.7` d'A Prova): o quadro balança e
   não gira.
3. Opções › Tremor desligado (ou Movimento › Reduzido, depois da G16): nada
   treme.
4. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo:
   comparar as pranchas das salas fixas com as de antes; as raias continuam
   inteiras.

## Ao terminar

No [quadro](README.md), G05 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: a câmera filma em milímetros, enquadra o grupo e a corrida, e o tremor vem do evento em três degraus
```

## O que foi feito (leva 1, a-fita)

- **Entrou:** `Lente` (`fov`, `PADRAO`, `recuo`) e `Enquadramento` (`grupo`, `corrida`, `puxar`, a margem de 15 %, a altura de
  1,6 m), cada um com o `.uid`; em `Sala`, os modos, `camera_lente`, `lente()`, `alvos_da_camera()`, `tremer()`, `abalo`,
  `puxar_os_de_tras()` e os degraus `TREMOR_GOLPE`, `TREMOR_ESTRONDO`, `TREMOR_EXPLOSAO` (o estrondo), `TREMOR_CATASTROFE`;
  no `main.gd`, `_lente()`, `_tangentes()`, `_pose_da_sala()`, o `_enquadrar()` pela lente, o pódio recuado e o tremor sem
  roll; A Prova no modo `"grupo"` de 17 a 25,5 m, com o `alvos_da_camera()` só de quem está na partida. A linha da câmera e a
  tabela do kit no [13](../13-arquitetura.md) foram escritas antes.
- **Medida:** o FOV da arena, do pódio e do salão foi de 40,0° para 37,8° (35 mm), e a pose fixa recua 6,16 % sobre o olhar
  (o enquadramento de hoje); o tremor foi de roll de até 0,7° mais 0,12 m para três degraus de 0,02, 0,05 e 0,08 m, de 1, 2
  e 4 batidas, sem roll e nunca acima de 0,08 m; A Prova tem 0 quadros com pé ou cabeça fora da tela em 300 de robô.
- **Provas** (`prova_do_jogo.gd`: `_prova_das_contas_da_camera` e `_prova_da_camera_na_prova`): a lente de 28, 35 e 50 mm, o
  recuo, o piso e o teto de 24 a 100 mm, a lente de cada modo, os quatro cantos da arena na tela com a margem justa (6,5 % da
  borda), a distância mínima e a máxima, o líder e o último na corrida, `puxar` com nós de verdade, a duração de cada degrau
  em batidas (e a 60 BPM), o teto, o tremor menor que não substitui o maior, o desconto em linha reta, o balanço conta a conta
  (no plano da câmera, sem girar), o Reduzido, a fixa, a dupla, o pódio, os alvos de A Prova e de uma sala de base, e a pose do
  main igual à da conta no grupo e na corrida. Mordeu, uma a uma: a lente do grupo e a da corrida; a margem em 0 e em 0,4; o
  `puxar` sem o alcance; o centro da corrida em 50 %; a altura do cavaleiro; a batida do golpe; o menor substituindo o maior; o
  teto de 0,1; o desconto dobrado; um roll plantado; o balanço sem o Reduzido; o tremor antigo sem o teto; o pódio sem o recuo;
  a fixa sem o recuo; o empurrão da dupla em 3 m, em 30 % e com altura; a lente do salão em 40°; as tangentes trocadas no
  grupo e na corrida; o FOV de 40° no `_enquadrar`; a corrida sem o `puxar_os_de_tras`; a distância e o modo d'A Prova; o filtro
  de quem está na partida; o filtro de quem está visível.
- **Fica para a G05b** ([G05b](G05b-o-que-a-g05-deixou-por-dependencia.md)): o `Lente` do G01 no merge, a lente do título e da
  montagem, a pose do salão a 35 mm (G06), as salas que ainda balançam pelo `tremor` antigo e a prova visual d'A Prova nas
  partidas de 4, 2 e 1.

### Escolhas minhas, para ela validar

- O salão passou a 35 mm (37,8°) sem mexer na pose: a câmera ficou uns 5 % mais fechada; o título, o lobby e a montagem
  seguem a 40°.
- Sem alvo nenhum, o modo grupo e o da corrida caem na pose fixa da sala.
- Sem ninguém na partida, A Prova enquadra todos os visíveis (não a pose fixa).
- O tremor antigo das salas (`tremor`) continua e vira `min(0,08, 0,12 × tremor)` m; vale o maior entre ele e o `abalo`.
- A batida do degrau é a do `Ritmo.bpm` na hora do pedido (120 BPM sem música).
- `_tangentes()` chama `_enquadrar()` antes, porque a cortina (`_trocar`) pede a pose na hora, quando o estado já mudou e o
  FOV da câmera ainda é o da sala velha.
- `_pose_da_sala` aceita as tangentes por parâmetro só para a prova fixar uma tela de 16:9 (a janela desta passada é quase
  quadrada).
- `Sala.TREMOR_EXPLOSAO` ficou igual ao estrondo (0,05), como a ficha manda, para as fichas de minigame que já o chamam.

### Para o André (local)

1. `./run-local.sh -- --sala=prova`: correr com os quatro para os cantos; a câmera abre e fecha sem salto e ninguém some.
2. Na mesma sala, o susto (o `tremor` d'A Prova): o quadro balança e não gira.
3. Opções › Movimento › Reduzido: nada treme.
4. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo: comparar as pranchas das salas fixas com as de antes;
   as raias continuam inteiras (a lente de 35 mm vê uns 5 % menos que a de 40°) e o salão não corta nenhum boneco.

### Na conferência (leva 1, a-fita)

- A prova visual já filma A Prova nas partidas de 4, 2 e 1 jogador (partidas 1, 3 e 4 do `prova_visual.sh`). Nas
  pranchas da passada `visual-g05/fixa` (`prancha-1-3`, `prancha-3-2`, `prancha-4-2`), o grupo está inteiro na tela em
  todo quadro de A Prova. O que falta para fechar é a passada inteira, que reprova pela «tela parada» de Impacto,
  Centelha e Galeria (o defeito da F09b, que já reprovava na base), e um quadro de cada degrau do tremor; a G05b foi
  corrigida para dizer isso.
