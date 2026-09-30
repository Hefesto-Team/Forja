# J4 — O Balão dos Foles

**Sprint:** J · **Slot:** S02_J09 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, F03, H07, J1 (o `secao.gd`)

## Por quê

Chacoalhar o controle é o fole do balão: um sacode no tempo e o parceiro no
contratempo, e o sopro dos dois sobe o balão — o acelerômetro pelo pico, em
dupla, com o tempo dividido.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o 2v2 com menos de quatro)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 9 em 03](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)
- [O índice da seção](J-a-viga.md) e a [J1](J1-a-viga.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J09",
	"titulo": "O Balão dos Foles",
	"verbo": "Chacoalhe!",
	"genero": "2v2",
	"icone": "acelerometro",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J09",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Chacoalhe!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S02_J09` — até a H05, a sintetizada a 96 bpm; com a
  gerada, 128 bpm ("nu-disco, baixo slap").
- **As duplas** são as equipes do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08):
  a **Brasa** (âmbar `#e8a33c`, à esquerda) e a **Maré** (turquesa
  `#2fb3b3`, à direita). A cor da equipe vai no mundo — o balão, o disco sob
  o cesto e a armadura dos tripulantes —, nunca na barra de luz (que fica
  na cor do lugar). Com quatro, os dois primeiros (pela ordem do lugar) são
  a Brasa e os outros a Maré; falta gente, **o Aprendiz** completa, pela
  regra de [Q](Q-a-prova.md#o-cenário-comum): com três, a Maré é o 3º e o
  Aprendiz; com dois, cada um com um Aprendiz; com um, ele e o Aprendiz
  contra dois Aprendizes.
- **O tempo e o contratempo:** na dupla, o de lugar menor chacoalha nas
  batidas `4c` e `4c + 2` (o tempo); o outro, em `4c + 1` e `4c + 3` (o
  contratempo). O Aprendiz faz a parte que falta: acerta
  `ACERTO_APRENDIZ` (0,8) das vezes, sempre como BOM, sorteado com o `rng`
  do kit; não é lugar, não pontua, não tem nota no registro, e não é robô.
  `Ritmo.simples[l]`: só a primeira das duas notas dele no compasso.
- **A nota:** uma sacudida — o acelerômetro passa de 1,8 g vindo de menos de
  1,3 g (`SECAO.forca_g(l)`; sem acelerômetro, o ✕) — dentro da janela que
  abre meio tempo antes → `julgar_toque`. Nada até `FOLGA_PERDIDA`, o do kit →
  nota perdida.
- **O balão sobe** (em metros, a altura da dupla): PERFEITO +0,25, ÓTIMO
  +0,18, BOM +0,10; o erro −0,4. **O sopro duplo:** o compasso em que todas
  as notas da dupla saíram ÓTIMO ou PERFEITO soma +0,2. As nuvens estão a
  **40 m**.
- **Os pontos são da dupla:** cada acerto marca os pontos nos dois da dupla
  (`[0, 20, 35, 50]` por julgamento; o sopro duplo +30 nos dois). Assim o
  fechamento põe a dupla junta na colocação.
- **A progressão:** `progresso()` do kit (em tempo de música, H08). De 0 a 1/3, normal. **O pico (1/3
  a 2/3), a corrente de ar:** cada acerto vale 1,5 vez, e as nuvens se abrem
  (a luz sobe). De 2/3 em diante, normal. Uma dupla que acerta tudo chega
  às nuvens entre 55 s (128 bpm) e 80 s (96 bpm).

## O cenário

`SECAO.montar(self)` (a caverna; as nuvens são o teto de vapor dela):

| o quê | peça | onde (m) |
| --- | --- | --- |
| o balão | `SphereMesh` de raio 1,3 com **8 lados e 6 anéis** (`radial_segments = 8`, `rings = 6`), `Kit.material(cor, 0.0, 0.85)` — Brasa `#e8a33c`, Maré `#2fb3b3` | cesto + `(0, 3.0, 0)` |
| o chão da equipe | um disco `Kit.cilindro` de raio 1,6, fosco, na cor da equipe escurecida 25% | sob o cesto, `(±4.0, 0.02, 3.8)` |
| o cesto | `Kit.caixa(1.8, 0.8, 1.2)`, `#8a5a33`; quatro cordas `Kit.caixa(0.04, 1.6, 0.04)`, `#c8b89a` | `(±4.0, y, 3.8)`, `y = 0.4 + 0.18 × altura` |
| o fole | em cada cesto, `Kit.caixa(0.6, 0.3, 0.4)`, couro `#4a3a44`, que encolhe (`scale.y`) em cada sacudida | cesto + `(0, 0.6, −0.5)` |
| os tripulantes | os bonecos da dupla, dentro do cesto, de frente para a câmera, com a armadura na cor da equipe; o Aprendiz (o `character-orc.glb` tingido de `#b9a98a`, como em [Q](Q-a-prova.md#o-cenário-comum)) no lugar de quem falta | cesto + `(±0.45, 0.2, 0)` |
| as nuvens | seis `Kit.caixa` achatadas (`3 × 0.4 × 2`), `Kit.material(Color("#cfc8e8"), 0.0, 1.0)` | `y` de 8,8 a 9,3, espalhadas em `x` de −9 a 9 |

Câmera: `camera_pos = Vector3(0, 5.0, 17.0)`, `camera_olhar = Vector3(0, 4.4, 1.0)`.
O balão é facetado e fosco; as cores das duplas não são as dos lugares.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **acelerômetro (a feature)** | a sacudida é o sopro, pelo pico em g |
| vibração | o kit por nota; o sopro duplo: `Forja.sentir(l, "acerto")` nos dois; as nuvens: `explosao` na dupla que chegou |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro (a cor do lugar, nunca a da dupla) |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "pulso", 0.5)`; erro: a nota quebrada (o kit) |
| gatilho | livre (o R2 Off) |
| háptica por material | `madeira`, pelo kit |
| som na TV | a nota (o kit); `sopro` no cesto a cada acerto; `sopro` alto e faíscas cinza no erro; `sucesso` nas nuvens |

## A falha

O fole estoura vapor no cesto: faíscas cinza (`Color("#cfc8e8")`) saindo do
fole, `Som.tocar("sopro")` alto, o tripulante faz `emote-no`, e o balão
desce 0,4 m (a descida se vê: o cesto anda até a altura nova em 0,3 s).

## O fim e o vencedor

A primeira dupla a 40 m: todos acabam (a F03 fecha). Sem nuvem até os 90 s
de música, a dupla mais alta vence. `vencedor()`: os da dupla vencedora
primeiro (pelo lugar), depois os outros; com as alturas iguais, pelos
pontos. Os pontos da equipe vão para os dois da dupla, e a tela diz
"A Brasa venceu!" ou "A Maré venceu!" (H08).

## Com menos de quatro

`com_poucos()` diz no aviso: com três ou dois, `"Com o Aprendiz"`; com um,
`"Você e o Aprendiz contra 2"` (as frases da Q1). **O controle que cai:** as notas dele param (sem
erro); o parceiro segue com as dele; o sopro duplo não conta naquele
compasso; ao voltar, a nota é o próximo tempo dele.

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if float(e.b) < 0.0 or int(e.robo_feito) == int(e.n):
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	if Ritmo.t_musica() >= Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira) - 0.01:
		Forja.robo_sacudir(l, 1.6, 0.15)
		e.robo_feito = int(e.n)
```

## Os ganchos

`godot/scripts/minigames/s02/balao_dos_foles.gd`:

```gdscript
extends Minigame
## O Balão dos Foles (S02_J09). Duas duplas, dois balões: a Brasa e a Maré.
## Chacoalhar o controle é o fole: um da dupla no tempo, o outro no
## contratempo; cada sopro no tempo sobe o balão, e o compasso inteiro bem
## soprado soma o sopro duplo. As nuvens a 40 m. No meio, a corrente de ar.
##
## A falha: o fole estoura vapor no cesto e o balão desce.
## O vencedor: a primeira dupla nas nuvens; senão, a mais alta.
## O alto-falante do dono: o pulso no acerto, a nota no perfeito.
## O registro mede: o pico em g de cada sacudida (a linha `entrada`) e o
## atraso entre o pulso e o movimento (o kit).
## O robô: sacode a 2,6 g na nota (ou 200 ms atrasado).
## Com menos de quatro: o Aprendiz completa a dupla (a regra de Q-a-prova.md).
## A régua: "Chacoalhe!" e o acelerômetro bastam; sem a tela, a nota de cada
## um e o pulso no controle dizem o tempo; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const COR_DA_DUPLA := [Color("#e8a33c"), Color("#2fb3b3")]  ## a Brasa e a Maré (13, H08)
const ACERTO_APRENDIZ := 0.8  ## a regra do Aprendiz (Q-a-prova.md)
const X_DA_DUPLA := [-4.0, 4.0]
const Z_BALAO := 3.8
const META := 40.0
const SOBE := [-0.4, 0.10, 0.18, 0.25]  ## ERRO, BOM, OTIMO, PERFEITO
const SOPRO_DUPLO := 0.2
const PONTOS := [0, 20, 35, 50]
const PONTOS_DUPLO := 30
const PANCADA := 1.8
const SOLTA := 1.3

var j := {}
var dupla := [[], []]  ## os lugares da Brasa e da Maré
var aprendiz := [0, 0]  ## quantas partes da dupla o Aprendiz faz (0, 1 ou 2)
var _aprendiz_b := -1.0  ## a última batida em que os Aprendizes sopraram
var altura := [0.0, 0.0]
var chegou := -1  ## a dupla que chegou às nuvens (-1: nenhuma)
var _cesto: Array = []
var _fole: Array = []
var _ok_no_compasso := {}  ## "dupla:compasso" -> false se alguma nota da dupla saiu abaixo de ÓTIMO
var _compasso_visto := -1
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 5.0, 17.0)
	camera_olhar = Vector3(0, 4.4, 1.0)
	SECAO.montar(self)
	var lugares: Array = []
	for p in jogadores:
		lugares.append(p.lugar)
	lugares.sort()
	for i in lugares.size():
		var d := (0 if i < 2 else 1) if lugares.size() >= 3 else (0 if i == 0 else 1)
		dupla[d].append(lugares[i])
	for d in 2:
		aprendiz[d] = 2 - dupla[d].size()  # o boneco do Aprendiz entra no cesto, no lugar de quem falta
	var madeira := Kit.material(Color("#8a5a33"), 0.0, 0.85)
	var corda := Kit.material(Color("#c8b89a"), 0.0, 0.9)
	for d in 2:
		var cesto := Node3D.new()
		cesto.position = Vector3(X_DA_DUPLA[d], 0.4, Z_BALAO)
		add_child(cesto)
		Kit.caixa(cesto, Vector3(1.8, 0.8, 1.2), Vector3.ZERO, madeira)
		for c in [Vector2(-0.8, -0.5), Vector2(0.8, -0.5), Vector2(-0.8, 0.5), Vector2(0.8, 0.5)]:
			Kit.caixa(cesto, Vector3(0.04, 1.6, 0.04), Vector3(c.x, 1.2, c.y), corda)
		var bola := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 1.3
		esfera.height = 2.6
		esfera.radial_segments = 8
		esfera.rings = 6
		bola.mesh = esfera
		bola.position = Vector3(0, 3.0, 0)
		bola.material_override = Kit.material(COR_DA_DUPLA[d], 0.0, 0.85)
		cesto.add_child(bola)
		Kit.cilindro(self, 1.6, 0.03, Vector3(X_DA_DUPLA[d], 0.02, Z_BALAO), Kit.material(COR_DA_DUPLA[d].darkened(0.25), 0.0, 0.9))
		_fole.append(Kit.caixa(cesto, Vector3(0.6, 0.3, 0.4), Vector3(0, 0.6, -0.5), Kit.material(Color("#4a3a44"), 0.0, 0.9)))
		_cesto.append(cesto)
	var nuvem := Kit.material(Color("#cfc8e8"), 0.0, 1.0)
	for k in 6:
		Kit.caixa(self, Vector3(3.0, 0.4, 2.0), Vector3(-9.0 + 3.6 * k, 8.8 + 0.1 * (k % 3), 1.0 + 0.8 * (k % 2)), nuvem)
	for p in jogadores:
		var l: int = p.lugar
		var d := _dupla_de(l)
		var i: int = dupla[d].find(l)
		maos_livres(p)
		p.preso = true
		p.rotation.y = 0.0
		j[l] = {"dupla": d, "n": 0, "b": -1.0, "aberta": false, "antes": false, "armado": true, "pico": 0.0,
			"fora": false, "lado": -0.45 if i == 0 else 0.45, "robo_n": -1, "robo_mira": 0.0, "robo_feito": -1}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	_mostrar()


func _dupla_de(l: int) -> int:
	return 0 if l in dupla[0] else 1


func com_poucos() -> String:
	match jogadores.size():
		3, 2:
			return "Com o Aprendiz"
		1:
			return "Você e o Aprendiz contra 2"
	return ""


## As batidas do lugar no compasso: o tempo (0 e 2) ou o contratempo (1 e 3).
## Quem está com o Aprendiz faz o tempo; o Aprendiz, o contratempo.
func _batidas(l: int) -> Array:
	var d: int = j[l].dupla
	var contra: bool = dupla[d].find(l) == 1
	var r := [1.0, 3.0] if contra else [0.0, 2.0]
	return r if not Ritmo.simples[l] else [r[0]]


func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var c := floorf(desde / 4.0)
	var s := INF
	while s == INF:
		for off in _batidas(l):
			var b: float = 4.0 * c + float(off)
			if b > desde and b >= BATIDA_DA_PRIMEIRA_NOTA:
				s = minf(s, b)
		c += 1.0
	e.b = s
	e.aberta = false
	e.antes = false
	e.pico = 0.0
	nova_nota(l, int(e.n), Ritmo.t_da_batida(s))


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)  # sem giroscópio ou acelerômetro: a linha `troca` (H08)
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
	var agora := Ritmo.t_musica()
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso_visto:
		if _compasso_visto >= 1:
			_sopro_duplo(_compasso_visto)
		_compasso_visto = c
	for l in presentes():
		var e: Dictionary = j[l]
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			_ok_no_compasso["%d:%d" % [int(e.dupla), c]] = false
			continue
		if bool(e.fora):
			e.fora = false
			_proxima(l, Ritmo.batida())
		_nota(l, e, agora)
	_aprendizes_sopram()
	for d in 2:
		if chegou < 0 and altura[d] >= META:
			_nas_nuvens(d)
	_mostrar()


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var g := SECAO.forca_g(l)
	if g < SOLTA:
		e.armado = true
	var sim := bool(e.armado) and g >= PANCADA
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.antes = sim
		return
	e.pico = maxf(float(e.pico), g)
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		e.armado = false
		Forja.evento("entrada", l + 1, {"o": "acelerometro", "pico_g": snappedf(float(e.pico), 0.01), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


## Os pontos vão para os dois da dupla (o fechamento põe a dupla junta).
func _marcar_dupla(d: int, n: int) -> void:
	for o in dupla[d]:
		marcar(o, n)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var d: int = e.dupla
	var vale := 1.5 if no_pico() else 1.0
	_marcar_dupla(d, int(PONTOS[julgamento] * vale))
	if not treinando:
		altura[d] = maxf(0.0, altura[d] + SOBE[julgamento] * vale)
	if julgamento < Ritmo.OTIMO:
		_ok_no_compasso["%d:%d" % [d, int(floor(float(e.b) / 4.0))]] = false
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "pulso", 0.5)
	var cesto: Node3D = _cesto[d]
	Som.tocar("sopro", cesto.global_position + Vector3(0, 0.6, 0), -8.0)
	(_fole[d] as Node3D).scale.y = 0.4
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.3)
	_proxima(l, float(e.b))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	var d: int = e.dupla
	if not treinando:
		altura[d] = maxf(0.0, altura[d] + SOBE[Ritmo.ERRO])
	_ok_no_compasso["%d:%d" % [d, int(floor(float(e.b) / 4.0))]] = false
	var cesto: Node3D = _cesto[d]
	Efeitos.faiscas(self, cesto.global_position + Vector3(0, 0.8, -0.5), Color("#cfc8e8"), 30, 0.8)
	Som.tocar("sopro", cesto.global_position, 0.0)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	_proxima(l, float(e.b))


## O compasso `c` acabou: a dupla em que todas as notas saíram ÓTIMO ou
## PERFEITO (e todos tinham controle) ganha o sopro duplo.
func _sopro_duplo(c: int) -> void:
	if treinando:
		return
	for d in 2:
		if dupla[d].is_empty() or not _ok_no_compasso.get("%d:%d" % [d, c], true):
			continue
		altura[d] += SOPRO_DUPLO
		_marcar_dupla(d, PONTOS_DUPLO)
		for o in dupla[d]:
			Forja.sentir(o, "acerto")
		Efeitos.faiscas(self, (_cesto[d] as Node3D).global_position + Vector3(0, 3.0, 0), COR_DA_DUPLA[d], 20, 0.8)


## O Aprendiz (Q-a-prova.md): um boneco do jogo, não um lugar nem um robô. Sopra
## a parte que falta à dupla (o contratempo; com dois Aprendizes, as duas) e
## acerta ACERTO_APRENDIZ das vezes, sempre BOM — por isso o compasso dele não
## tem sopro duplo.
func _aprendizes_sopram() -> void:
	var b := floorf(Ritmo.batida())
	if b <= _aprendiz_b or b < BATIDA_DA_PRIMEIRA_NOTA:
		return
	_aprendiz_b = b
	var contra := int(b) % 2 == 1
	for d in 2:
		if aprendiz[d] == 0 or (aprendiz[d] == 1 and not contra):
			continue
		_ok_no_compasso["%d:%d" % [d, int(b / 4.0)]] = false
		if not treinando and chegou < 0 and rng.randf() < ACERTO_APRENDIZ:
			altura[d] += SOBE[Ritmo.BOM]
			Som.tocar("sopro", (_cesto[d] as Node3D).global_position, -10.0)


func _nas_nuvens(d: int) -> void:
	chegou = d
	Som.tocar("sucesso", (_cesto[d] as Node3D).global_position)
	Efeitos.faiscas(self, (_cesto[d] as Node3D).global_position + Vector3(0, 3.0, 0), COR_DA_DUPLA[d], 60, 1.4)
	for o in dupla[d]:
		Forja.sentir(o, "explosao")
		var p := jogador(o)
		if p:
			p.gesto("emote-yes", 1.6)
	for l in presentes():
		acabou[l] = true


func _mostrar() -> void:
	for d in 2:
		var cesto: Node3D = _cesto[d]
		var y := 0.4 + 0.18 * minf(altura[d], META)
		cesto.position.y = lerpf(cesto.position.y, y, 0.15)
		var fole: Node3D = _fole[d]
		fole.scale.y = move_toward(fole.scale.y, 1.0, 0.05)
	for p in jogadores:
		var l: int = p.lugar
		if not j.has(l):
			continue
		var cesto: Node3D = _cesto[int(j[l].dupla)]
		p.position = cesto.position + Vector3(float(j[l].lado), 0.2, 0)
		p.animar("idle")


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	var da: int = j[a].dupla
	var db: int = j[b].dupla
	if da != db:
		if chegou >= 0:
			return da == chegou
		if not is_equal_approx(altura[da], altura[db]):
			return altura[da] > altura[db]
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "%d m" % int(altura[int(j[lugar].dupla)])
	return super(lugar)
```

## O que o registro mede

- O kit: `nota` e `toque` (o atraso entre o pulso da música e a sacudida).
- A linha `entrada`: **o pico em g** de cada sacudida (o máximo na janela) e
  o `n`; no começo, os sensores. Cruzado: um acelerômetro que satura cedo,
  ou que chega dez vezes menor, aparece aqui (o pico nunca passa de 1,8).

## Armadilhas

- **A dupla é do `montar()`**, pela ordem dos lugares presentes, e não muda
  se alguém cai no meio (ele volta para a mesma dupla).
- **O pico, não o valor:** a sacudida é cruzar 1,8 g vindo de menos de 1,3 g
  (`armado`); segurar o controle chacoalhando não conta duas vezes.
- **Os pontos da dupla** vão para os dois (`_marcar_dupla`): é o que faz o
  fechamento (a F03) e a partida porem a dupla junta.
- **O sopro duplo** fecha pelo compasso da nota, como o acorde d'O Fole.
- **`_mostrar()` roda também no `montar()`**, para o aviso já mostrar os
  bonecos nos cestos.
- **A frase de duas duplas no fechamento** é da F03 ("P1 e P2 empatam!"
  quando a dupla vence): não mude a tela de resultado aqui.

## Pronto quando

O balão joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o selo de
`com_poucos()` certo em cada um) e com o robô nos três temperamentos; o cabo
que cai e volta mantém a dupla; o fim tem sempre vencedor; `bash
tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh` passa com a
prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S02_J09 (J4): o balão abre pelo catálogo com a Brasa (P1, P2) e a Maré
## (P3, P4); a sacudida simulada de cada um sobe o balão da dupla; o fim põe
## a dupla junta.
func _prova_do_balao() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S02_J09", 130.0)
	if mg == null:
		return
	_esperar(mg.dupla == [[0, 1], [2, 3]] and mg.aprendiz == [0, 0], "S02_J09: as duplas pela ordem dos lugares, sem Aprendiz com quatro (%s)" % [mg.dupla])
	_esperar(mg.altura[0] > 0.0 and mg.altura[1] > 0.0, "S02_J09: os dois balões subiram (%s)" % [mg.altura])
	var v: Array = mg.vencedor()
	_esperar(int(mg.j[v[0]].dupla) == int(mg.j[v[1]].dupla), "S02_J09: a dupla vencedora vem junta (%s)" % [v])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S02_J09: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S02_J09` com quatro: o tempo
e o contratempo se ouvem como um fole só; o sopro duplo se sente nos dois;
o vapor do erro faz rir; a corrida dos dois balões se lê de longe.

## Ao terminar

- Catálogo: `"S02_J09": preload("res://scripts/minigames/s02/balao_dos_foles.gd")`
  em `MINIGAMES` e na lista da S02.
- `traducoes.gd`: `"O Balão dos Foles": "The Bellows Balloon"`, `"Chacoalhe!": "Shake!"`,
  `"Quem está sozinho faz os dois tempos": "Whoever is alone plays both beats"`,
  `"Um contra um: cada um faz os dois tempos": "One on one: each plays both beats"`,
  `"Sozinho até as nuvens": "Alone to the clouds"`; em `EN_PADROES`,
  `["^(\\d+) m$", "$1 m"]` se ainda não estiver lá (a I2 põe).
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a J4 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: O Balão dos Foles — a dupla chacoalha no tempo e no contratempo`
