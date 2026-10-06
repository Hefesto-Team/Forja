# G05 — A câmera dos quatro

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F09 · **Usado por:** H04 (a chave `"camera"` da ficha do minigame vira `camera_modo`)

## Por quê

Numa sala, a câmera é uma pose fixa (`camera_pos`, `camera_olhar`); nos
minigames em que os cavaleiros andam, ela precisa enquadrar quem está em
jogo — sem tela dividida, sem salto — e o tremor precisa vir do evento.

## Ler antes

- [A câmera](../06-telas-e-fluxo.md#a-câmera)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04) (a chave `"camera": "fixa", "grupo", "corrida"` da ficha)

## O estado de hoje

- `godot/scripts/salas/sala.gd:13-16`: `camera_pos := Vector3(0, 13, 13)`,
  `camera_olhar := Vector3.ZERO`, `tremor := 0.0`. Cada sala põe a sua pose no
  `_init`/`montar` (ex.: `prova.gd:88-89`,
  `camera_pos = Vector3(0, 17.5, 13.2)`, `camera_olhar = Vector3(0, 0, 0.9)`).
- `godot/scripts/main.gd:909-941`, `_pose_da_camera()`: numa sala devolve
  `[sala.camera_pos, sala.camera_olhar]`; no salão, uma conta própria que
  enquadra quem está visível (a caixa dos bonecos, distância de 11,5 a 18).
- `godot/scripts/main.gd:947-959`, `_enquadrar()`: `FOV_16_9 := 40.0`; em
  tela mais estreita que 16:9, `KEEP_WIDTH` com o fov recalculado.
- `godot/scripts/main.gd:962-973`, `_mover_camera(dt)`: `lerp` com
  `k = dt * 4.0` (1,2 no título); o tremor soma um balanço com
  `sala.tremor`, só com `Opcoes.tremor` ligado.
- O tremor é escrito pelas salas e cada uma o apaga do seu jeito:
  `prova.gd:369` (`tremor = 0.7`) e `prova.gd:619` (desconta),
  `voz.gd:494` (`tremor = flash * 1.4` a cada quadro).
- A Prova (`prova.gd`) é a única sala de hoje em que os quatro andam numa
  arena (`ARENA_X := 11.3`, `ARENA_Z := 6.9`); a câmera fixa a vê inteira de
  longe.

## O alvo

### Os três modos (06)

`Sala` ganha:

```gdscript
var camera_modo := "fixa"                    ## "fixa", "grupo", "corrida" (a ficha do minigame, 13)
var camera_distancia := Vector2(9.0, 18.0)   ## a distância mínima e a máxima, em m (grupo e corrida)
var camera_frente := Vector3(0, 0, -1)       ## corrida: para onde se corre
var camera_alcance := 14.0                   ## corrida: quem fica mais que isto atrás do líder volta para a borda
var camera_foco := Vector3.ZERO              ## fixa: onde está a ação agora (ZERO: nenhuma)
var abalo := 0.0                             ## o tremor do evento (tremer), que se apaga sozinho
const TREMOR_GOLPE := 0.35                   ## golpe forte treme pouco
const TREMOR_EXPLOSAO := 1.0                 ## explosão treme mais
func alvos_da_camera() -> Array              ## as posições que a câmera enquadra: os bonecos visíveis (a sala troca por "só os vivos")
func tremer(forca: float) -> void            ## abalo = maxf(abalo, forca)
func puxar_os_de_tras() -> void              ## corrida: a borda empurra, não mata
```

`Sala._process(dt)` desconta: `abalo = maxf(0.0, abalo - dt * 2.0)`. O
`tremor` de hoje continua (as salas que o usam não mudam); o main treme por
`maxf(sala.tremor, sala.abalo)`.

| modo | a pose |
| --- | --- |
| fixa | `[camera_pos, camera_olhar]`; com `camera_foco != Vector3.ZERO`, as duas somadas de `puxa = (camera_foco - camera_olhar) * 0.15`, com `puxa.y = 0` e `puxa.limit_length(1.5)` (o empurrão leve para a ação) |
| grupo | `Enquadramento.grupo(alvos_da_camera(), dir, camera_distancia, tg.x, tg.y)` |
| corrida | `Enquadramento.corrida(alvos_da_camera(), camera_frente, dir, camera_distancia, tg.x, tg.y)`, e o main chama `sala.puxar_os_de_tras()` a cada quadro |

`dir = (sala.camera_pos - sala.camera_olhar).normalized()`: a direção de
onde a sala olha continua a que ela desenhou; só a distância e o centro
mudam. A margem de 15% (06) está dentro das contas. O amortecimento é o
`lerp` de hoje (`k = dt * 4.0`): a câmera nunca salta; na entrada da sala, a
cortina já põe a pose na hora (`_trocar`).

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

## O líder e o último sempre na tela; o centro puxado para o líder.
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
## Câmera em C = centro + dir * d, olhando para o centro: o ponto p tem profundidade
## (p - centro)·f + d, com f = -dir; cabe se |x| e |y| ≤ profundidade × tan / (1 + MARGEM).
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

No main, as tangentes da câmera de verdade:

```gdscript
## A tangente de meio campo de visão: (vertical, horizontal).
func _tangentes() -> Vector2:
	var tam := get_viewport().get_visible_rect().size
	var aspecto := tam.x / maxf(tam.y, 1.0)
	var t := tan(deg_to_rad(camera.fov) * 0.5)
	if camera.keep_aspect == Camera3D.KEEP_HEIGHT:
		return Vector2(t, t * aspecto)
	return Vector2(t / aspecto, t)
```

### A Prova passa a "grupo"

Em `godot/scripts/salas/prova.gd`, junto da pose (88-89):
`camera_modo = "grupo"` e `camera_distancia = Vector2(16.0, 24.0)`. A pose
fixa de hoje continua sendo a direção. `alvos_da_camera()` d'A Prova devolve
só os bonecos de quem ainda está na partida (se a sala tira alguém, ela
sabe quem; senão, todos os visíveis).

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 2 e 4.

1. **O 13 primeiro:** no [kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04),
   a linha "a câmera | pelo modo da ficha (G05)" passa a dizer: "o kit põe
   `camera_modo` pela chave `"camera"` da ficha, e a ficha pode trazer
   `"camera_distancia": Vector2(min, max)` e, na corrida, `"camera_frente"`;
   os eventos tremem com `tremer(Sala.TREMOR_GOLPE)` ou
   `tremer(Sala.TREMOR_EXPLOSAO)`".
2. **`godot/scripts/enquadramento.gd` (novo):** as contas acima; importar
   (`"$GODOT" --headless --path godot --import --quit`) e commitar o
   `enquadramento.gd.uid`.
3. **`godot/scripts/salas/sala.gd`:** as variáveis, `alvos_da_camera()`
   (os `global_position` dos `jogadores` visíveis), `tremer()`,
   `puxar_os_de_tras()` (aplica `Enquadramento.puxar` nas posições dos
   visíveis e devolve cada boneco à sua posição nova) e o desconto do
   `abalo` em `_process`.
4. **`godot/scripts/main.gd`:** `_tangentes()`; no `"sala"` de
   `_pose_da_camera()`, `return _pose_da_sala()` com a tabela dos modos;
   em `_mover_camera`, o tremor por `maxf(sala.tremor, sala.abalo)`; em
   `_process`, antes de `_mover_camera(dt)`:
   `if estado == "sala" and sala and sala.camera_modo == "corrida": sala.puxar_os_de_tras()`.
5. **`godot/scripts/salas/prova.gd`:** o modo `"grupo"` e a distância.
6. **As provas** (ver Provas).

## Armadilhas

- **`.uid`** do `enquadramento.gd`.
- **As contas ficam puras** (sem nó, sem `get_viewport`): a prova as confere
  com uma `Camera3D` de verdade.
- **A direção vem da sala:** não invente ângulo novo; `dir` sai da pose que
  a sala já tinha.
- **Distância máxima:** no máximo, a câmera para; quem não cabe na corrida é
  puxado (`puxar_os_de_tras`); no grupo, a arena tem de caber no máximo
  (A Prova: 24 m cobre a arena de 22,6 × 13,8).
- **O tremor e o conforto:** `Opcoes.tremor` desligado não treme nada — nem o
  `abalo`.
- **Lugar vazio:** `alvos_da_camera()` só conta os visíveis; sem ninguém,
  a pose fixa.
- **O robô:** nada de `Forja.robo` aqui.
- **A foto d'A Prova muda:** a câmera passa a seguir o grupo; a comparação
  das fotos (`tests/telas.sh comparar`) vai acusar diferença nela — é esperado.
- **Os temperamentos e os casos que quebram:** o fluxo tem de aguentar `--robo=bom|medio|ruim` (o ruim demora e às vezes não aperta), partidas com 1 e 2 jogadores e um controle que desconecta e volta (`simulador_cabo`). A câmera com 1 alvo fica na distância mínima; com um controle fora, o boneco dele continua visível e continua sendo alvo (ele volta no mesmo lugar); o `--robo=ruim` anda menos e se espalha menos — o grupo tem de enquadrar os dois casos.

## Não fazer

- Não criar tela dividida nem câmera por jogador.
- Não trocar as salas fixas de hoje para "grupo" além d'A Prova.
- Não mexer na câmera do título, da introdução, do lobby nem do pódio.
- Não fazer o tremor pela câmera em lugar do evento: a sala pede
  `tremer()`, a câmera só obedece.

## Pronto quando

Com quatro robôs espalhados n'A Prova, nenhum cavaleiro sai da tela no modo
grupo; as contas do modo corrida põem o líder e o último na tela e trazem
para a borda quem fica para trás; nada salta nem treme com o conforto ligado.

E só fecha com `bash tests/prova_visual.sh` passando (a passada com `--fixed-fps 60`, na sessão) e a prancha olhada; foto de `tests/telas.sh` não é prova ([a prova visual](../13-arquitetura.md#a-prova-visual--f09)). A aparência (luz, cor, brilho, névoa, arte) só se aprova na máquina do André, com placa de vídeo, sem `--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

**A prova visual (F09):** `bash tests/prova_visual.sh` — as quatro partidas (4 jogadores bom e ruim, 2 jogadores, 1 jogador com o controle caindo) passando pelas telas desta ficha; na prancha: A Prova com o grupo sempre inteiro na tela nas partidas de 4, 2 e 1, sem salto de câmera entre quadros.

Em `godot/testes/prova_do_jogo.gd`, duas funções novas, chamadas no
`_ready()` depois de `_prova_de_fogo()`:

```gdscript
## As contas da câmera, com uma câmera de verdade (fov 40, 16:9).
func _prova_das_contas_da_camera() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40.0
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	var tv := tan(deg_to_rad(40.0) * 0.5)
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


## A Prova no modo grupo, com o robô jogando: ninguém sai da tela.
func _prova_da_camera_na_prova() -> void:
	var sala = await _comeca_a_sala("prova")
	if sala == null:
		return
	_esperar(sala.camera_modo == "grupo", "A Prova enquadra o grupo")
	await _quadros(60)
	var fora := 0
	for i in 300:
		await _quadros(1)
		for p in jogo.jogadores:
			if p.visible and not jogo.camera.is_position_in_frustum(p.global_position + Vector3(0, 0.8, 0)):
				fora += 1
	_esperar(fora == 0, "A Prova: em 300 quadros, nenhum cavaleiro fora da tela (%d)" % fora)
	sala.tremer(Sala.TREMOR_EXPLOSAO)
	_esperar(sala.abalo > 0.9, "o evento treme a câmera")
	await _quadros(60)
	_esperar(sala.abalo < 0.1, "e o tremor se apaga sozinho")
	sala.terminar()
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(2)
		q += 2
```

(Se a F03/F08 fizeram o fim avançar sozinho em 6 s, o laço final espera por
isso; se não, aperte ✕ no simulado 0 com `_aperta(0, Forja.CRUZ)` depois de
`terminar()`.)

## Para o André (local)

1. `./run-local.sh -- --sala=prova`: correr com os quatro para os cantos —
   a câmera abre e fecha sem salto, ninguém some.
2. Opções › Movimento da câmera desligado: nada treme.
3. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo:
   olhar A Prova nas pranchas (ninguém fora da tela, nada saltando).

## Ao terminar

No [quadro](README.md), G05 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: a câmera enquadra o grupo e a corrida, e o tremor vem do evento
```
