# P4 — Grito de Guerra

**Sprint:** P · **Slot:** S08_J39 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, H07, P1

## Por quê

Sumô de cavaleiros num octógono de pedra sobre o abismo. O grito no tempo
forte solta uma onda que empurra quem está perto; o grito fora do tempo dá o
coice no próprio cavaleiro. É a voz como arma, todos contra todos — e a
seção que mais faz a sala rir, porque ninguém consegue gritar no tempo
rindo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](P-a-voz.md) e a [P1](P1-a-voz.md): **o ouvido** (`_ouvir`, as constantes, o "sem microfone", o mudo fora da hora) — copie igual

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S08_J39",
	"titulo": "Grito de Guerra",
	"verbo": "Grite!",
	"genero": "tct",
	"icone": "microfone",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S08_J39",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe_esq", "golpe_dir", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Grite!", "segundos": 6.0},
	"gesto": "attack-melee-right",
}
```

(`entradas` vazias: a voz e o analógico esquerdo, que não são botões.)

## Como se joga

A faixa é `MUS_S08_J39`, 135 bpm (uma batida ≈ 0,44 s), com um compasso de
silêncio de vez em quando. `ENTRADA := 4`.

- **O ringue:** um octógono de raio `_raio` (começa em `RAIO := 6.0`),
  centro em `(0, 0, -0.5)`. Cada cavaleiro começa a 3 m do centro, no ângulo
  do lugar (`[PI, PI / 2, 0, -PI / 2][l]` — P1 à esquerda, P2 ao fundo, P3 à
  direita, P4 à frente).
- **Andar:** o analógico esquerdo (`Forja.eixo(l, Forja.LX)`, `LY`), a
  `VEL := 3.0` m/s (o andar é entrada, anda com o `dt`); o boneco olha para
  onde anda.
- **O grito (a nota):** no tempo forte — a batida 0 de cada compasso,
  `bn = ENTRADA + 4k` — cada lugar vivo tem uma nota (`nova_nota` uma batida
  antes). O começo da voz (o ouvido da P1) a até 0,35 s do alvo →
  `julgar_toque(l, t(bn) + LATENCIA_MIC, n)`.
- **A onda** (`toque`): de raio `ONDA_R := 3.0`, empurra todo outro
  cavaleiro vivo dentro dela para longe do gritador, `FORCA[j]` metros
  (`[0.0, 1.2, 1.8, 2.4]`); o empurrão anda por `lerpf` em meia batida (pela
  batida). Cada cavaleiro empurrado marca `50` para o gritador.
- **O coice** (a falha): o começo da voz a mais de `JANELA_BOM` do alvo
  (julgado ERRO) → o próprio cavaleiro é jogado 1,0 m para trás (a direção
  oposta à que olha).
- **Calado** (a nota que passou): o cavaleiro tosse — 0,3 m para trás.
- **A voz fora de toda nota** (longe de qualquer tempo forte): ignorada (o
  ruído do sofá não empurra ninguém).
- **A queda:** quem sai do octógono (`distancia > _raio`) cai no abismo —
  vira **fantasma**: fica na borda, e o grito dele no tempo forte (julgado
  igual) solta um sopro de `0.6` m no vivo mais perto dentro de 3 m. Não
  pontua mais.
- **O hoqueto:** todos gritam no mesmo tempo forte — é o coro de guerra; a
  nota de cada lugar soa na TV (kit): o acorde do grito só fecha se todos
  acertam.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar grita um compasso
  sim, um não.
- **O pico — o ringue encolhe:** nos 4 compassos a partir de
  `_pico_k := floor(compassos_previstos / 2)`, o raio desce de 6,0 a 4,5
  (`lerpf` pela batida) e os gritos valem nas batidas 0 **e** 2 do compasso.
  Depois do pico, o raio fica em 4,5.

`compassos_previstos = floor((duracao / _t_batida() - ENTRADA) / 4)`.

## O cenário

- **O abismo:** `Kit.arena(self, 6, 4)` com o chão escondido por uma laje
  preta `Kit.caixa(self, Vector3(30, 0.02, 20), Vector3(0, -2.0, 0), Kit.material(Color("#0d0b14"), 0.0, 1.0))`
  dois metros abaixo; o ringue fica no alto.
- **O ringue:** `Kit.cilindro(self, RAIO, 0.6, Vector3(0, -0.3, -0.5), pedra)`
  de 8 lados (G08) em `pedra := Kit.material(Color("#4a4452"), 0.0, 0.95)`, e
  a borda: 8 `Kit.peca(self, "rocks", <nos vértices>, <giro>, 0.5)`. A escala
  x/z do cilindro acompanha `_raio / RAIO`.
- **A luz:** a da casa, cheia: `luzes([Vector3(-8, 4, -4), Vector3(8, 4, -4), Vector3(0, 4, 5)])`,
  `atmosfera(Color("#ffb070"), Tema.VERMELHO, true, 50, 24.0, -9.0, 0.35)`.
- **Os cavaleiros:** sem as raias do kit (o ringue é livre): não chame
  `raia(l)` nem `posicionar(l)`; ponha cada um no ângulo dele, `p.preso = true`
  e mova pela posição. Sob cada um, o anel do kit do boneco (o `aro` do
  `ForjaPlayer`) já tem a cor do lugar.
- **A onda:** `Efeitos.anel(self, pos + Vector3(0, 0.2, 0), Forja.cor_do_lugar(l), ONDA_R, Vector3.UP)`
  (é efeito de acerto: pode ter a cor do lugar) e `Efeitos.faiscas` nos
  empurrados.
- **O fantasma:** o boneco que caiu volta na borda, fora do ringue, em
  `(RAIO + 1.2) * (cos a, sin a)`, fazendo `idle`, com a lanterna dele
  apagada; o sopro dele é `Efeitos.poeira` curta na cor `#b9b0ff`.
- **A câmera:** de cima, `camera_pos = Vector3(0, 12.0, 8.5)`,
  `camera_olhar = Vector3(0, 0, -0.5)`.
- **Checklist de arte (11):** o ringue de 8 lados; pedra fosca; o emissivo só
  na onda (efeito) e nas faíscas; nada nas cores dos lugares além da onda de
  cada um; a prancha com os quatro no ringue.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **microfone (protagonista)** | o grito no tempo forte | a nota |
| luz do mudo | o mudo fora da hora (P1): acesa enquanto mudo; ele grita sozinho, mais fraco | se apertar |
| vibração | empurrado: `Forja.sentir(l, "golpe_esq")` se a onda veio da esquerda da tela (o gritador tem x menor), `"golpe_dir"` se da direita; caiu: `Forja.sentir(l, "golpe")` | no empurrão; na queda |
| barra de luz | a cor do lugar | — |
| alto-falante do dono | o eco do próprio grito PERFEITO: `Forja.som_falante(l, "nota:%d" % l, 0.8)` (o kit); empurrado: `Forja.som_falante(l, "pulso", 0.6)` | no toque; no empurrão |
| háptica por material | o kit (`material:pedra` no cabo) | no toque |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a serra da música; `Som.tocar("golpe", pos, -4.0)` em cada empurrão; `Som.tocar("vento", pos, -2.0)` na queda; `tremor = 0.4` no grito perfeito | — |

**Sem microfone / mudo** (a P1): o lugar "grita sozinho, mais fraco": a cada
tempo forte, uma onda com a força BOM (1,2 m) e raio 2,0, sem nota; a
`troca` uma vez.

## A falha

- **O coice:** o boneco é jogado para trás 1,0 m (o `lerpf` em meia batida),
  `fall` curto (0,4 s), e sente o `golpe`; perto da borda, pode cair — é o
  engraçado.
- **Calado:** tosse (`emote-no`, 0,3 s) e recua 0,3 m.
- **A queda:** `fall` (0,8 s), o boneco desce 2 m no abismo por uma batida,
  some, e volta como fantasma na borda.

## O fim e o vencedor

`ultimo_em_pe`: com dois ou mais, quando sobra um no ringue, ele vence e,
um compasso depois, todos acabam. Com um jogador (ver abaixo), quando os
bonecos caem ou no `duracao`. Senão, o kit fecha no `duracao`.
`vencedor()`: os que estão no ringue, pelos pontos; depois os que caíram, do
último a cair ao primeiro (`_caiu_em[l]`).

## Com menos de quatro

- **3, 2:** nada muda (os ângulos são os dos lugares).
- **1:** ele contra dois **bonecos de treino** (o orc tingido de `#b9a98a`,
  como os d'A Prova, `prova.gd:171-180`), que andam devagar para ele e gritam
  no tempo forte com `GRITO_BONECO := 0.7` de chance (sorteado com o `rng`),
  com a força BOM. Os bonecos não são lugar, não pontuam e caem como os
  outros. `com_poucos()`: `"Contra 2 bonecos"`.
- **O controle que cai:** o cavaleiro sem controle fica parado, não grita e
  **não pode ser empurrado para fora** (a onda não o move); volta no próximo
  tempo forte.
- **Duplas:** não há.

## O robô

Anda para o centro e grita no tempo forte pelo controle simulado.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var p := jogador(l)
	if p and not _caiu[l]:
		# anda para perto do centro, sem colar na borda
		var para := Vector2(0.0 - p.position.x, -0.5 - p.position.z)
		var mv := para.normalized() * (0.8 if para.length() > 1.5 else 0.0)
		Forja.robo_eixo(l, Forja.LX, mv.x, 0.1)
		Forja.robo_eixo(l, Forja.LY, mv.y, 0.1)
	var n: int = _nota[l]
	if n < 0 or _robo_gritou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.25 if rng.randf() < 0.5 else 99.0)
	if Ritmo.t_musica() >= float(_alvo[l]) + LATENCIA_MIC + float(_robo_mira[l]):
		Forja.robo_falar(l, 0.9, 0.3)
		_robo_gritou[l] = n
```

## Os ganchos

`godot/scripts/minigames/s08/grito_de_guerra.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Grito de Guerra (S08_J39). Sumô num octógono sobre o abismo: o grito no
## tempo forte solta uma onda que empurra quem está perto; o grito fora do
## tempo é um coice no próprio cavaleiro. O analógico esquerdo anda.
##
## A falha: o coice (para trás), a tosse do calado, a queda no abismo (vira
## fantasma que sopra). O vencedor: o último no ringue. O alto-falante do dono:
## o eco do grito perfeito; o baque de quem é empurrado. O registro mede: a voz
## de cada controle no tempo forte (voz, toque) e o lado do empurrão na
## vibração. O robô: anda ao centro e grita pelo controle simulado. Com menos
## de quatro: sozinho, contra dois bonecos. A régua: "Grite!" e o ícone
## bastam.

const FICHA := { ... }

const ENTRADA := 4
const RAIO := 6.0
const RAIO_PICO := 4.5
const CENTRO := Vector3(0, 0, -0.5)
const VEL := 3.0
const ONDA_R := 3.0
const FORCA := [0.0, 1.2, 1.8, 2.4]
const JANELA_CASA := 0.35
const GRITO_BONECO := 0.7
const ANGULO := [PI, PI / 2, 0.0, -PI / 2]
# ... e as do ouvido (a P1)

var _raio := RAIO
var _pos := {}                      ## lugar (ou "b0", "b1" para os bonecos) -> Vector3
var _empurrao := {}                 ## quem -> {de, ate, b0}
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _n := [0, 0, 0, 0]
var _feita := [-1.0, -1.0, -1.0, -1.0]
var _caiu := [false, false, false, false]
var _caiu_em := [-1.0, -1.0, -1.0, -1.0]
var _motivo := ["", "", "", ""]
var _bonecos := []                  ## com um jogador: os dois bonecos {no, anim, pos, caiu}
var _fim_batida := -1.0
var _pico_k := 999
var _nos := {}
# o ouvido (a P1)
var _robo_nota := [-1, -1, -1, -1]
var _robo_gritou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	papel_som = Forja.PAPEL_MICROFONE
	camera_pos = Vector3(0, 12.0, 8.5)
	camera_olhar = Vector3(0, 0, -0.5)
	# o abismo, o ringue, a luz; os cavaleiros nos ângulos; os bonecos (com um); gatilhos_off


func iniciar_jogo() -> void:
	# o _pico_k; sem microfone (a P1); led_mic(l, 0)
	pass


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)
	_raio = _raio_na(b)                    # 6,0; no pico, lerp até 4,5; depois 4,5
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		if not _caiu[l]:
			_andar(l, dt)                  # o analógico, VEL, empurrado não anda
		_abrir_grito(l, b)                 # a nota do tempo forte (e do 2 no pico), uma batida antes
		_prazo(l)                          # calado: a nota que passou
		_cair_se_saiu(l, b)
	_bonecos_jogam(b)                      # com um jogador
	_ultimo_em_pe(b)                       # sobrou um: _fim_batida = b + 4
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func _comecou(l: int) -> void:
	var n: int = _nota[l]
	if n < 0 or absf(Ritmo.t_musica() - float(_alvo[l]) - LATENCIA_MIC) > JANELA_CASA:
		return
	_nota[l] = -1
	_motivo[l] = "coice"
	julgar_toque(l, float(_alvo[l]) + LATENCIA_MIC, n)


func _parou(_l: int) -> void:
	pass


func toque(l: int, j: int) -> void:
	if _caiu[l]:
		_sopro_de_fantasma(l)              # 0,6 m no vivo mais perto em 3 m
		return
	_onda(l, FORCA[j])                     # empurra, marca 50 por empurrado, o golpe do lado em quem foi empurrado


func falha(l: int) -> void:
	if _caiu[l]:
		return
	if _motivo[l] == "coice":
		_empurrar(l, -_frente(l), 1.0)
		jogador(l).gesto("fall", 0.4)
		Forja.sentir(l, "golpe")
	else:
		_empurrar(l, -_frente(l), 0.3)
		jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var dentro := presentes().filter(func(l): return not _caiu[l])
	dentro.sort_custom(func(a, b): return pontos[a] > pontos[b])
	var fora := presentes().filter(func(l): return _caiu[l])
	fora.sort_custom(func(a, b): return _caiu_em[a] > _caiu_em[b])
	return dentro + fora
```

`_empurrar(quem, direcao, metros)`: `_empurrao[quem] = {"de": pos, "ate": pos + direcao * metros, "b0": Ritmo.batida()}`;
a posição, enquanto houver empurrão, é `lerp(de, ate, clampf((b - b0) / 0.5, 0.0, 1.0))`.
`_onda(l, forca)`: para cada outro vivo e conectado (e os bonecos) a menos de
`ONDA_R`, empurra na direção `(outro - l).normalized()`; no lugar
empurrado, `Forja.sentir(o, "golpe_esq" if pos_l.x < pos_o.x else "golpe_dir")`
e `Forja.som_falante(o, "pulso", 0.6)`; `marcar(l, 50)` por empurrado;
`Efeitos.anel` na cor do lugar. `_frente(l)`: a direção para onde o boneco
olha (`Vector3(sin(rot.y), 0, cos(rot.y))`). `_cair_se_saiu(l, b)`:
`Vector2(pos.x - CENTRO.x, pos.z - CENTRO.z).length() > _raio` → `_caiu[l] = true`,
`_caiu_em[l] = b`, a queda.

Dica: `["@mic"]` sob o cavaleiro na nota enquanto `not aprendeu(l)` (a `pos`
é o pé do boneco). `status(l)`: `"No ringue"` / `"Fantasma"`.

Catálogo: `"S08_J39"` em `MINIGAMES` e na seção `S08`. Traduções:
`"Grito de Guerra": "War Cry"`, `"Grite!": "Shout!"`, `"No ringue": "In the ring"`,
`"Contra 2 bonecos": "Against 2 dummies"` (e `"Fantasma"` já veio da O4).

## O que o registro mede

- `voz` de cada grito (o nível e o piso: o grito é o nível mais alto da
  seção — a noite vê se algum microfone satura ou corta);
- `toque` de cada grito (o desvio da voz no tempo forte);
- `sensacao` `golpe_esq`/`golpe_dir` de cada empurrão (o lado da vibração, no
  controle de quem foi empurrado);
- `troca` para "sozinho".

## Armadilhas

- **Todos gritam juntos**, e a regra do ar dá a voz a todos que estão perto
  do mais alto — é o esperado. Quem **não** gritou fica abaixo da margem e
  não solta onda.
- **O empurrão anda pela batida**, não por velocidade somada com `dt`; o
  andar do analógico é entrada e usa o `dt`.
- **Sem controle não cai**: a onda não move quem está sem controle.
- **Os bonecos não são robô** (é regra do jogo, com o `rng` do kit).
- **Na prova o pico não chega** (o fim é pelo `duracao`).
- **`ENTRADA`**: se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com os bonecos) e com o
robô nos três temperamentos; aguenta o cabo que cai e volta; fecha com
vencedor; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a
prancha olhada (o ringue, as ondas, alguém caindo).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_grito()`:

```gdscript
## S08_J39: o robô grita no tempo forte; alguém é empurrado, e a vibração do
## empurrado é de um lado só (golpe_esq ou golpe_dir, nunca os dois motores).
func _prova_grito() -> void:
	var sala = await _comeca_a_sala("S08_J39")
	if sala == null:
		return
	var lado_ok := true
	var empurrou := false
	var q := 0
	while is_instance_valid(sala) and sala.fase == "jogo" and q < 12000:
		for l in 4:
			var p := _perc(l)
			var forte := float(p.get("forte", 0.0))
			var fraco := float(p.get("fraco", 0.0))
			if forte > 0.9 and fraco > 0.9:
				lado_ok = false
			if (forte > 0.9 and fraco < 0.05) or (fraco > 0.9 and forte < 0.05):
				empurrou = true
		await _quadros(1)
		q += 1
	_esperar(empurrou, "grito: alguém foi empurrado (um motor só)")
	_esperar(lado_ok, "grito: o empurrão nunca treme os dois motores cheios")
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "grito: fechou")
```

(`golpe_esq` é `[1.0, 0.0]` e `golpe_dir` `[0.0, 1.0]`: um motor cheio e o
outro parado. O `golpe` da queda e do coice é `[1.0, 0.6]` e não conta como
empurrão.)

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S08_J39`, com quatro. O
grito no tempo tem de ser **o** momento; o coice perto da borda tem de fazer
rir; o empurrão tem de chegar na mão do lado certo. Se a voz de um soltar a
onda do vizinho calado, anote os `voz` e ajuste `MARGEM_AR`.

## Ao terminar

- No [quadro](README.md), a linha P4: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Grito de Guerra — a voz no tempo forte empurra`
