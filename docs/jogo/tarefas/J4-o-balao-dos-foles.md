# J4 — O Balão dos Foles

**Sprint:** J · **Slot:** S02_J09 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, G05, G14, J1 (o `secao.gd`)

## Por quê

Chacoalhar o controle é o fole do balão: um da dupla sacode no tempo, o
parceiro no contratempo, e o sopro dos dois sobe o balão. O acelerômetro
medido pelo pico, em dupla, com o tempo dividido; os dois balões sobem lado
a lado, e a ultrapassagem é o grito.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o 2v2 com menos de quatro)
- [H08 — Os acréscimos do kit](H08-os-acrescimos-do-kit.md) (as equipes: `montar_equipes`, `da_equipe`, `marcar_equipe`, `aprendizes`, `CORES_DAS_EQUIPES`)
- [J1 — O secao.gd](J1-a-viga.md#o-secaogd) (a caverna, `agendar`, `vento`, `momento`, `gancho`, `levantar`, `pista_s`, `forca_g`)

## Arquivos que mudam

| arquivo | o que muda | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s02/balao_dos_foles.gd` | **novo**: o minigame | não |
| `godot/scripts/minigames/catalogo.gd` | o slot `S02_J09` | sim: as cinco |
| `godot/scripts/traducoes.gd` | o título, o verbo, as frases do `com_poucos` e o status | sim: as cinco |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_balao()` e a linha no `_prova_da_ficha` | sim: as cinco |
| `godot/testes/captura_jogo.gd` | os momentos de `"S02_J09"` | sim: as cinco |

O `secao.gd`, `"momento"` em `TIPOS_DO_JOGO`, a linha `momento` no 13 e o
`_linhas_do_minigame()` da prova são da J1: esta ficha só os usa.

### O estado de hoje

Não existe `balao_dos_foles.gd`. A ficha anterior trazia o verbo
"Chacoalhe!", o cesto `#8a5a33`, as cordas `#c8b89a`, o fole `#4a3a44` e as
nuvens `#cfc8e8` soltos, a armadura dos tripulantes tingida na cor da
equipe, o cesto fundo que escondia as pernas, o Aprendiz `#b9a98a`, a
câmera que cortava o balão a 40 m e nenhum grito. Esta ficha troca tudo
pelos tokens do Tema e pelo `secao.gd`, e acrescenta a ultrapassagem como
momento, o rastro de vapor, a faixa de vento da reta, o pulso da vez e o
sopro que sobe de tom.

### Ao terminar

1. `godot/scripts/minigames/catalogo.gd`: em `MINIGAMES`,
   `"S02_J09": preload("res://scripts/minigames/s02/balao_dos_foles.gd")`;
   na lista `minigames` da S02, `"S02_J09"` logo depois de `"S02_J08"`.
2. `godot/scripts/traducoes.gd`: `"O Balão dos Foles": "The Bellows Balloon"`,
   `"Encha!": "Fill!"`, `"Com o Aprendiz": "With the Apprentice"`,
   `"Você e o Aprendiz contra 2": "You and the Apprentice against 2"` (as que
   já estiverem lá ficam como estão); em `EN_PADROES`, `["^(\\d+) m$", "$1 m"]`
   quando `grep -n '(\\\\d+) m\$' godot/scripts/traducoes.gd` não achar nada.
3. `godot/testes/prova_do_jogo.gd` e `godot/testes/captura_jogo.gd`: o que
   está em **Provas**.
4. `"$GODOT" --headless --path godot --import --quit`; o
   `balao_dos_foles.gd.uid` entra no commit.
5. O quadro sai do cabeçalho desta ficha: nada a editar nele.
6. Commit (sem trailer): `feat(balao): O Balão dos Foles, a dupla no tempo e no contratempo, a ultrapassagem e a faixa de vento`.

## Como se joga

- **A faixa:** `MUS_S02_J09`. Até a H05, a sintetizada da seção a 96 BPM;
  com a gerada, `mus_s02_j09` a 128 BPM (nu-disco, baixo slap).
- **As duplas** são as equipes do kit (H08): a **Brasa** (`CORES_DAS_EQUIPES[0]`,
  à esquerda, `x = −4,0`) e a **Maré** (`CORES_DAS_EQUIPES[1]`, à direita,
  `x = 4,0`). A cor da equipe vai no balão, no disco sob o cesto, nas
  faíscas e no rastro; nunca no boneco nem na barra de luz (a do lugar).
  Com quatro, os dois primeiros lugares são a Brasa e os dois seguintes a
  Maré; falta gente, o **Aprendiz** completa (`aprendizes[d]`).
- **O tempo e o contratempo:** na dupla, o de lugar menor sopra nas batidas
  `4c` e `4c + 2` (o tempo); o outro, em `4c + 1` e `4c + 3` (o
  contratempo). `Ritmo.simples[l]`: só a primeira das duas notas dele no
  compasso.
- **O pulso da vez:** meio tempo antes de cada nota do lugar (mais o Faro),
  o alto-falante dele dá o pulso de 120 Hz (`mod_pulso`): é o parceiro que
  acabou de soprar passando a vez.
- **A nota:** uma sacudida. O acelerômetro passa de **1,8 g** vindo de
  menos de **1,3 g** (o rearme; `SECAO.forca_g(l)`; sem acelerômetro, o ✕)
  dentro da janela que abre meio tempo antes: `julgar_toque`. Nada até
  `FOLGA_PERDIDA` (0,140 s) depois: nota perdida.
- **O balão sobe** (a altura da dupla, em m): PERFEITO +0,25, ÓTIMO +0,18,
  BOM +0,10; o erro −0,4. **O sopro duplo:** o compasso em que todas as
  notas da dupla saíram ÓTIMO ou PERFEITO soma +0,2 m e 30 pontos. As
  nuvens estão a **40 m**.
- **O Aprendiz** sopra a parte que falta (o contratempo; com dois
  Aprendizes, as quatro batidas) e acerta 0,8 das vezes (`rng` do kit),
  sempre como BOM: não é lugar, não pontua, não tem nota no registro, não é
  robô. O compasso dele nunca tem sopro duplo.
- **Os pontos são da dupla** (`marcar_equipe`): `[0, 20, 35, 50]` por
  julgamento, nos dois.
- **A ultrapassagem:** quando a dupla de trás passa a da frente por 0,1 m
  ou mais, na colcheia seguinte: faíscas da cor dela no balão, o rastro de
  vapor, o golpe na mão de quem passou e o vento na mão de quem foi
  passado.

### A curva

Os terços de 90 s: 30 s e 60 s (`andamento()` 1/3 e 2/3).

| trecho | o que vale | o mundo |
| --- | --- | --- |
| 0 a 30 s | o tempo e o contratempo, cada acerto ×1,0 | os dois balões sobem devagar, lado a lado |
| 30 a 60 s, a corrente de ar | cada acerto ×1,5 na altura e nos pontos | as nuvens se abrem (o `x` de cada uma ×1,25); a lava sobe a 1,0 e a câmera recua 10 % em 2 batidas |
| 60 s ao fim, a reta | a **faixa de vento a 30 m**: a dupla com 30 m ou mais sobe 0,85 de cada acerto (os pontos não mudam); a de trás sobe inteira | oito traços de vento correm na altura de 30 m |
| as últimas 16 batidas | o sopro duplo vale o dobro (+0,4 m, 60 pontos) | a linha `momento` `reta` |

Uma dupla que acerta tudo chega às nuvens perto dos 60 s a 128 BPM; a
faixa de vento segura quem abriu vantagem no pico.

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J09",
	"titulo": "O Balão dos Foles",
	"verbo": "Encha!",
	"genero": "2v2",
	"icone": "acelerometro",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J09",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Encha!", "segundos": 6.0},
}
```

### O fim e o vencedor

A primeira dupla a 40 m: todos acabam (a F03 fecha). Sem nuvem até os 90 s
de música, a dupla mais alta vence. `vencedor()`: os da dupla vencedora
primeiro (pelo lugar), depois os outros; com as alturas iguais, pelos
pontos, depois pelo lugar. A tela diz "A Brasa venceu!" ou "A Maré venceu!"
(o kit).

### Com menos de quatro

O kit monta as equipes (`montar_equipes`). `com_poucos()`: com três ou
dois, `"Com o Aprendiz"`; com um, `"Você e o Aprendiz contra 2"`.

| jogadores | Brasa | Maré |
| --- | --- | --- |
| 4 | 1.º e 2.º | 3.º e 4.º |
| 3 | 1.º e 2.º | 3.º e o Aprendiz |
| 2 | 1.º e o Aprendiz | 2.º e o Aprendiz |
| 1 | 1.º e o Aprendiz | dois Aprendizes |

O boneco do Aprendiz: `character-orc.glb`, escala `ForjaPlayer.ESCALA`,
tingido de `ETIQUETA_SOMBRA` (`SalaProva._tingir`), no lado do cesto de
quem falta. **O controle que cai:** as notas dele param (sem erro), o
parceiro segue, o sopro duplo não conta naquele compasso; ao voltar, a nota
é o próximo tempo dele. **Sem acelerômetro:** o ✕ vale 2,0 g
(`SECAO.forca_g`); a linha `troca` diz qual.

### Os ganchos

`godot/scripts/minigames/s02/balao_dos_foles.gd`:

```gdscript
extends Minigame
## O Balão dos Foles (S02_J09). Duas duplas, dois balões: a Brasa e a Maré.
## Chacoalhar o controle é o fole: um da dupla no tempo, o outro no
## contratempo; cada sopro no tempo sobe o balão, e o compasso inteiro bem
## soprado soma o sopro duplo. A dupla de trás que passa a da frente é o
## grito. No meio, a corrente de ar; na reta, a faixa de vento a 30 m.
##
## A falha: o fole estoura vapor no cesto e o balão desce 0,4 m.
## O vencedor: a primeira dupla nas nuvens; senão, a mais alta.
## O alto-falante do dono: o pulso da vez meio tempo antes da nota; a nota
## no perfeito (o kit).
## O registro mede: o pico em g de cada sacudida (a linha `entrada`), o
## atraso (o kit), o pulso e o vento (a linha `pista`), a ultrapassagem e a
## reta (a linha `momento`).
## O robô: sacode a 2,6 g na nota (ou 200 ms atrasado).
## Com menos de quatro: o Aprendiz completa a dupla.
## A régua: "Encha!" e o acelerômetro bastam; sem a tela, o pulso no
## alto-falante diz a vez e o vento na mão diz que a outra dupla passou;
## nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const ACERTO_APRENDIZ := 0.8
const X_DA_DUPLA := [-4.0, 4.0]
const Z_BALAO := -3.0
const POR_METRO := 0.13  ## m de cena por m de altura
const META := 40.0
const FAIXA := 30.0  ## a faixa de vento da reta
const NA_FAIXA := 0.85
const SOBE := [-0.4, 0.10, 0.18, 0.25]  ## ERRO, BOM, OTIMO, PERFEITO
const SOPRO_DUPLO := 0.2
const PONTOS := [0, 20, 35, 50]
const PONTOS_DUPLO := 30
const PASSA := 0.1  ## m de vantagem para a ordem trocar
const PANCADA := 1.8
const SOLTA := 1.3
const CAMERA := Vector3(0, 3.0, 12.3)
const OLHAR := Vector3(0, 5.0, -3.0)
const NUVENS_X := [-9.0, -5.4, -1.8, 1.8, 5.4, 9.0]

var j := {}
var dupla := [[], []]
var altura := [0.0, 0.0]
var chegou := -1
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var _cesto: Array = []
var _fole: Array = []
var _bola: Array = []
var _nuvens: Array = []
var _vento: Array = []
var _aprendiz_no: Array = []  ## [{d, no, anim}]
var _aprendiz_b := -1.0
var _ok_no_compasso := {}
var _compasso_visto := -1
var _frente := -1
var _ultima_passada_b := -99.0
var ultrapassou_t := -1.0
var _rastros := []
var _reta := false
var _ensinou_b := -1.0


func montar() -> void:
	SECAO.limpar()
	camera_pos = CAMERA
	camera_olhar = OLHAR
	SECAO.montar(self)
	dupla = [da_equipe(BRASA), da_equipe(MARE)]
	var madeira := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)
	var corda := Kit.material(Tema.ETIQUETA_SOMBRA, 0.0, 0.9)
	for d in 2:
		var x: float = X_DA_DUPLA[d]
		Kit.cilindro(self, 1.0, 0.03, Vector3(x, 0.015, Z_BALAO), Kit.material(CORES_DAS_EQUIPES[d].darkened(0.25), 0.0, 0.9))
		var cesto := Node3D.new()
		cesto.position = Vector3(x, 0.15, Z_BALAO)
		add_child(cesto)
		Kit.caixa(cesto, Vector3(1.8, 0.3, 1.2), Vector3.ZERO, madeira)
		for c in [Vector2(-0.85, -0.55), Vector2(0.85, -0.55), Vector2(-0.85, 0.55), Vector2(0.85, 0.55)]:
			Kit.caixa(cesto, Vector3(0.04, 1.85, 0.04), Vector3(c.x, 1.075, c.y), corda)
		var bola := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 1.3
		esfera.height = 2.6
		esfera.radial_segments = 8
		esfera.rings = 6
		bola.mesh = esfera
		bola.position = Vector3(0, 3.3, 0)
		bola.material_override = Kit.material(CORES_DAS_EQUIPES[d], 0.0, 0.85)
		cesto.add_child(bola)
		_bola.append(bola)
		_fole.append(Kit.caixa(cesto, Vector3(0.6, 0.3, 0.4), Vector3(0, 0.3, -0.5), Kit.material(Tema.OXIDO, 0.0, 0.9)))
		_cesto.append(cesto)
	var vapor := Kit.material(Tema.ETIQUETA_SOMBRA, 0.0, 1.0)
	for k in NUVENS_X.size():
		_nuvens.append(Kit.caixa(self, Vector3(3.0, 0.4, 2.0), Vector3(NUVENS_X[k], 10.1 + 0.1 * (k % 3), Z_BALAO - 0.5 - 0.8 * (k % 2)), vapor))
	var traco := Kit.chapado(Tema.ETIQUETA_SOMBRA)
	for k in 8:
		var t := Kit.caixa(self, Vector3(1.2, 0.04, 0.04), Vector3(-10.0 + 2.5 * k, _y_da_bola(FAIXA), Z_BALAO - 1.5), traco)
		t.visible = false
		_vento.append(t)
	for p in jogadores:
		var l: int = p.lugar
		var d: int = equipe[l]
		maos_livres(p)
		p.preso = true
		p.rotation.y = 0.0
		j[l] = {"dupla": d, "n": 0, "b": -1.0, "aberta": false, "antes": false, "armado": true, "pico": 0.0,
			"fora": false, "lado": -0.45 if dupla[d].find(l) == 0 else 0.45, "pulsou": false, "pulso_t": -1.0,
			"robo_n": -1, "robo_mira": 0.0, "robo_feito": -1}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	for d in 2:
		for k in aprendizes[d]:
			var modelo: Node3D = load("res://assets/kenney/character-orc.glb").instantiate()
			modelo.scale = Vector3.ONE * ForjaPlayer.ESCALA
			add_child(modelo)
			SalaProva._tingir(modelo, Tema.ETIQUETA_SOMBRA)
			var lado := 0.45 if dupla[d].size() + k >= 1 else -0.45
			_aprendiz_no.append({"d": d, "no": modelo, "lado": lado,
				"anim": modelo.find_child("AnimationPlayer", true, false)})
	_mostrar()


func com_poucos() -> String:
	match jogadores.size():
		3, 2:
			return "Com o Aprendiz"
		1:
			return "Você e o Aprendiz contra 2"
	return ""


func _y_da_bola(metros: float) -> float:
	return 0.15 + POR_METRO * metros + 3.3


func _ultimas_16() -> bool:
	return tempo_que_resta() <= 16.0 * 60.0 / Ritmo.bpm


## Quanto vale um acerto da dupla na altura: o pico ×1,5; na reta, a faixa
## de vento ×0,85 para quem já passou dos 30 m.
func _vale(d: int) -> float:
	var v := 1.5 if no_pico() else 1.0
	if andamento() >= 2.0 / 3.0 and altura[d] >= FAIXA:
		v *= NA_FAIXA
	return v


## As batidas do lugar no compasso: o tempo (0 e 2) ou o contratempo (1 e 3).
func _batidas(l: int) -> Array:
	var d: int = j[l].dupla
	var r := [1.0, 3.0] if dupla[d].find(l) == 1 else [0.0, 2.0]
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
	e.n = int(e.n) + (1 if float(e.b) >= 0.0 else 0)
	e.b = s
	e.aberta = false
	e.antes = false
	e.pico = 0.0
	e.pulsou = false
	nova_nota(l, int(e.n), Ritmo.t_da_batida(s))


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
	SECAO.pulsos()
	var agora := Ritmo.t_musica()
	var pico := SECAO.pico_suave(self)
	camera_pos = OLHAR + (CAMERA - OLHAR) * (1.0 + 0.1 * pico)
	SECAO.lava(self, 0.6 + 0.4 * pico)
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso_visto:
		if _compasso_visto >= 1:
			_sopro_duplo(_compasso_visto)
		_compasso_visto = c
	if not _reta and _ultimas_16() and chegou < 0:
		_reta = true
		var d_lider := 0 if altura[0] >= altura[1] else 1
		SECAO.momento(self, "reta", -1, (_cesto[d_lider] as Node3D).global_position, 4.6,
			{"ordem": vencedor(), "objeto": "altura", "alturas": [snappedf(altura[0], 0.01), snappedf(altura[1], 0.01)]})
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
		_pulso(l, e, agora)
		_nota(l, e, agora)
	_ensinar()
	_aprendizes_sopram()
	_ordem()
	for d in 2:
		if chegou < 0 and altura[d] >= META:
			_nas_nuvens(d)
	_mostrar()


## O pulso da vez: meio tempo antes da nota (mais o Faro), no alto-falante.
func _pulso(l: int, e: Dictionary, agora: float) -> void:
	if bool(e.pulsou):
		return
	var alvo := Ritmo.t_da_batida(float(e.b))
	if agora >= alvo - 0.5 * 60.0 / Ritmo.bpm - SECAO.pista_s(l):
		e.pulsou = true
		e.pulso_t = agora
		Forja.som_falante(l, "pulso", 0.4)
		anotar("pista", l, {"canal": "alto_falante", "o": "pulso", "n": int(e.n)})


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
		anotar("entrada", l, {"o": "acelerometro", "pico_g": snappedf(float(e.pico), 0.01), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


## O sopro: o «fuu» do mapa (sopro), um semitom acima a cada 4 m.
func _fuu(d: int, volume_db: float) -> void:
	var tom := pow(2.0, floorf(altura[d] / 4.0) / 12.0)
	Som.tocar("sopro", (_cesto[d] as Node3D).global_position + Vector3(0, 0.3, 0), volume_db, tom)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var d: int = e.dupla
	var pico := 1.5 if no_pico() else 1.0
	marcar_equipe(d, int(PONTOS[julgamento] * pico))
	if not treinando:
		altura[d] = maxf(0.0, altura[d] + SOBE[julgamento] * _vale(d))
	if julgamento < Ritmo.OTIMO:
		_ok_no_compasso["%d:%d" % [d, int(floor(float(e.b) / 4.0))]] = false
	_fuu(d, -8.0)
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
	Efeitos.faiscas(self, cesto.global_position + Vector3(0, 0.45, -0.5), Tema.ETIQUETA_SOMBRA, 30, 0.8)
	Som.tocar("sopro", cesto.global_position, 0.0, 0.8)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", SECAO.levantar(l, 1.0) * 60.0 / Ritmo.bpm)
	_proxima(l, float(e.b))


## O compasso `c` acabou: a dupla com todas as notas ÓTIMO ou PERFEITO ganha
## o sopro duplo (o dobro nas últimas 16 batidas).
func _sopro_duplo(c: int) -> void:
	if treinando:
		return
	var vezes := 2 if _ultimas_16() else 1
	for d in 2:
		if dupla[d].is_empty() or not _ok_no_compasso.get("%d:%d" % [d, c], true):
			continue
		altura[d] += SOPRO_DUPLO * vezes * _vale(d)
		marcar_equipe(d, PONTOS_DUPLO * vezes)
		for o in dupla[d]:
			Forja.sentir(o, "acerto")
		Efeitos.faiscas(self, (_bola[d] as Node3D).global_position, CORES_DAS_EQUIPES[d], 20, 0.8)


## Ensina sem falar: nas 4 batidas antes da primeira nota, cada tripulante
## (e o Aprendiz) chacoalha o fole na batida dele: o tempo e o contratempo.
func _ensinar() -> void:
	var b := floorf(Ritmo.batida())
	if b >= BATIDA_DA_PRIMEIRA_NOTA or b <= _ensinou_b or b < 0.0:
		return
	_ensinou_b = b
	for l in presentes():
		var p := jogador(l)
		if p and fmod(b, 2.0) == fmod(float(_batidas(l)[0]), 2.0):
			p.gesto("attack-melee-right", 0.3)
	for a in _aprendiz_no:
		if a.anim and (aprendizes[int(a.d)] == 2 or int(b) % 2 == 1):
			(a.anim as AnimationPlayer).play("attack-melee-right", 0.1)
			(a.anim as AnimationPlayer).queue("idle")


## O Aprendiz: a parte que falta à dupla, 0,8 das vezes, sempre BOM.
func _aprendizes_sopram() -> void:
	var b := floorf(Ritmo.batida())
	if b <= _aprendiz_b or b < BATIDA_DA_PRIMEIRA_NOTA:
		return
	_aprendiz_b = b
	var contra := int(b) % 2 == 1
	for d in 2:
		if aprendizes[d] == 0 or (aprendizes[d] == 1 and not contra):
			continue
		_ok_no_compasso["%d:%d" % [d, int(b / 4.0)]] = false
		if not treinando and chegou < 0 and rng.randf() < ACERTO_APRENDIZ:
			altura[d] += SOBE[Ritmo.BOM] * _vale(d)
			_fuu(d, -10.0)
			for a in _aprendiz_no:
				if int(a.d) == d and a.anim:
					(a.anim as AnimationPlayer).play("attack-melee-right", 0.1)
					(a.anim as AnimationPlayer).queue("idle")


## A ordem das alturas: a de trás que passa por PASSA ou mais é a ultrapassagem,
## na colcheia seguinte (uma a cada 4 batidas, no máximo).
func _ordem() -> void:
	if chegou >= 0 or treinando:
		return
	var dif: float = altura[0] - altura[1]
	if absf(dif) < PASSA:
		return
	var nova := 0 if dif > 0.0 else 1
	if _frente >= 0 and nova != _frente and Ritmo.batida() - _ultima_passada_b >= 4.0:
		_ultima_passada_b = Ritmo.batida()
		var colcheia := ceilf(Ritmo.batida() * 2.0 + 0.001) / 2.0
		SECAO.agendar(Ritmo.t_da_batida(colcheia), _ultrapassa.bind(nova))
	_frente = nova


## O grito: faíscas da cor de quem passou, o rastro de vapor por 4 s, o golpe
## na mão de quem passou e o vento na de quem foi passado.
func _ultrapassa(d: int) -> void:
	ultrapassou_t = Ritmo.t_musica()
	var bola: Node3D = _bola[d]
	Efeitos.faiscas(self, bola.global_position, CORES_DAS_EQUIPES[d], 30, 1.0)
	tremer(Sala.TREMOR_GOLPE)
	var nos := [_cesto[0], _cesto[1]]
	SECAO.parar(nos, 2)
	for o in dupla[d]:
		Forja.sentir(o, "golpe", 120)
	for o in dupla[1 - d]:
		SECAO.vento(o, 0.6, d == 0)
		anotar("pista", o, {"canal": "haptica", "o": "vento", "de": d})
	var rastro := Node3D.new()
	add_child(rastro)
	var mat := Kit.material(CORES_DAS_EQUIPES[d], 0.6)
	for i in 6:
		Kit.esfera(rastro, 0.25 - 0.025 * i, bola.global_position + Vector3(0, -1.6 - 0.35 * i, 0.2), mat)
	_rastros.append(rastro)
	SECAO.agendar(Ritmo.t_musica() + 4.0, func() -> void:
		_rastros.erase(rastro)
		if is_instance_valid(rastro):
			rastro.queue_free())
	var lugar := int(dupla[d][0]) if not dupla[d].is_empty() else -1
	SECAO.momento(self, "ultrapassa", lugar, bola.global_position + Vector3(0, -1.3, 0), 2.6,
		{"dupla": d, "alturas": [snappedf(altura[0], 0.01), snappedf(altura[1], 0.01)]})


func _nas_nuvens(d: int) -> void:
	chegou = d
	Som.tocar("sucesso", (_cesto[d] as Node3D).global_position)
	Efeitos.faiscas(self, (_bola[d] as Node3D).global_position, CORES_DAS_EQUIPES[d], 60, 1.4)
	for o in dupla[d]:
		Forja.sentir(o, "explosao")
		var p := jogador(o)
		if p:
			p.gesto("emote-yes", 1.6)
	for l in presentes():
		acabou[l] = true


func _mostrar() -> void:
	var pico := SECAO.pico_suave(self)
	for d in 2:
		var cesto: Node3D = _cesto[d]
		if cesto.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		var y := 0.15 + POR_METRO * minf(altura[d], META)
		cesto.position.y = lerpf(cesto.position.y, y, 0.15)
		var fole: Node3D = _fole[d]
		fole.scale.y = move_toward(fole.scale.y, 1.0, 0.05)
	for k in _nuvens.size():
		(_nuvens[k] as Node3D).position.x = float(NUVENS_X[k]) * (1.0 + 0.25 * pico)
	var na_reta := fase == "jogo" and andamento() >= 2.0 / 3.0
	for k in _vento.size():
		var t: Node3D = _vento[k]
		t.visible = na_reta
		t.position.x = fposmod(-10.0 + 2.5 * k + Ritmo.batida() * 3.0 + 10.0, 20.0) - 10.0
	for p in jogadores:
		var l: int = p.lugar
		if not j.has(l) or p.process_mode == Node.PROCESS_MODE_DISABLED:
			continue
		var cesto: Node3D = _cesto[int(j[l].dupla)]
		p.position = cesto.position + Vector3(float(j[l].lado), -0.15, 0)
		p.animar("idle")
	for a in _aprendiz_no:
		var cesto: Node3D = _cesto[int(a.d)]
		(a.no as Node3D).position = cesto.position + Vector3(float(a.lado), -0.15, 0)


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
		if int(pontos[a]) != int(pontos[b]):
			return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "%d m" % int(altura[int(j[lugar].dupla)])
	return super(lugar)
```

O lado do Aprendiz: com um humano na dupla, ele fica em `x = +0,45` (o
contratempo); com dois Aprendizes, o primeiro em −0,45 e o segundo em
+0,45 (`dupla[d].size() + k >= 1`).

### O robô

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
		Forja.robo_sacudir(l, 1.6, 0.15)  # 1,6 g além da gravidade: 2,6 g, e volta a 1 g (rearma)
		e.robo_feito = int(e.n)
```

A mesa das duplas pede o robô por lugar (`--robo=bom,ruim,medio,medio
--semente=7`), que a F09 ainda não tem: até existir, a prova roda com
`--robo=medio --semente=7`, e os mínimos valem igual.

### O registro

- O kit: `nota` e `toque` (o atraso entre a batida e a sacudida).
- `entrada`: `sensores` no começo; em cada sacudida, `o` `acelerometro`,
  `pico_g` (o máximo na janela) e `n`. Um acelerômetro que satura cedo, ou
  que chega dez vezes menor, aparece aqui (o pico nunca passa de 1,8).
- `pista`: `alto_falante` `pulso` (com o `n`) e `haptica` `vento` (com o
  `de`, a dupla que passou).
- `momento`: `ultrapassa` (`lugar` o primeiro da dupla que passou, `dupla`,
  `alturas`) e `reta` (`ordem`, `objeto` `altura`, `alturas`).

### Armadilhas

- **A dupla é do kit** (`montar_equipes`, antes do `montar()`), e não muda
  se alguém cai no meio.
- **O pico, não o valor:** a sacudida cruza 1,8 g vindo de menos de 1,3 g
  (`armado`); chacoalhar sem parar não conta duas vezes.
- **A faixa de vento pesa só na altura:** os pontos do acerto são os mesmos
  dentro e fora dela; o `_vale` não entra no `marcar_equipe`.
- **A ultrapassagem espera a colcheia** (`_ultrapassa` pela fila do
  `secao.gd`): a linha `momento`, o `sentir` e o vento saem no mesmo quadro.
  Uma a cada 4 batidas, no máximo, para o grito não virar ruído.
- **A vibração cala a háptica:** enquanto `sentir` vibra, o vento
  (`som_haptica`) não toca (F05); a prova conta o vento pela linha `pista`,
  não pelo `som_virtual`.
- **O hit-stop dos cestos:** `_mostrar()` pula o cesto e o boneco com
  `process_mode` DISABLED.
- **`_mostrar()` roda também no `montar()`**, para o aviso já mostrar os
  bonecos nos cestos.

## A cena

### O secao.gd

O da [J1](J1-a-viga.md#o-secaogd), sem mudança: `SECAO.montar` (a caverna
cobalto), `lava`, `pico_suave`, `agendar`, `pulsos`, `parar`, `vento`,
`momento`, `gancho`, `levantar`, `pista_s`, `forca_g`.

### Por lugar

| o quê | peça | onde (m) | cor |
| --- | --- | --- | --- |
| o disco da equipe | `Kit.cilindro` r 1,0 × 0,03 | `(±4,0; 0,015; −3,0)`, no chão do fundo da caverna | `CORES_DAS_EQUIPES[d]` escurecida 25 %, fosco |
| a gôndola | `Kit.caixa(1,8; 0,3; 1,2)`: a borda de 0,3 m só cobre os pés | `(±4,0; 0,15 + 0,13 × altura; −3,0)` | `OXIDO_BRILHO` (a madeira) |
| as cordas | 4 × `Kit.caixa(0,04; 1,85; 0,04)` | dos cantos da gôndola ao balão | `ETIQUETA_SOMBRA` |
| o balão | `SphereMesh` r 1,3, 8 lados e 6 anéis | gôndola + `(0; 3,3; 0)` | `CORES_DAS_EQUIPES[d]`, fosco (rugosidade 0,85) |
| o fole | `Kit.caixa(0,6; 0,3; 0,4)`, encolhe a 0,4 em cada sopro | gôndola + `(0; 0,3; −0,5)` | `OXIDO` (o couro) |
| os tripulantes | os bonecos da dupla, `preso`, mãos livres, de frente | gôndola + `(±0,45; −0,15; 0)` | o da montagem |
| o Aprendiz | `character-orc.glb` tingido | no lado de quem falta | `ETIQUETA_SOMBRA` |
| as nuvens | 6 × `Kit.caixa(3,0; 0,4; 2,0)` | x −9,0 a 9,0 (×1,25 no pico), y 10,1 a 10,3 | `ETIQUETA_SOMBRA`, rugosidade 1,0 |
| a faixa de vento (a reta) | 8 × `Kit.caixa(1,2; 0,04; 0,04)`, chapados, correndo 3 m por tempo | y 7,35 (o centro do balão a 30 m), z −4,5 | `ETIQUETA_SOMBRA` |
| o rastro de vapor | 6 × `Kit.esfera` r 0,25 a 0,125 | abaixo do balão que passou, por 4 s | `CORES_DAS_EQUIPES[d]` a 0,6 |

A 40 m, o topo do balão fica em y 9,95, encostado nas nuvens.

### A câmera

`"camera": "fixa"`, o plano de lado da corrida: 50 mm, os dois balões no
quadro, sem corte. `camera_pos = (0; 3,0; 12,3)`, `camera_olhar = (0; 5,0;
−3,0)` (15,4 m: o quadro vai de y −0,6 a 10,5 e de x −9,9 a 9,9 no plano dos
balões; o chão e as nuvens entram). O fov é o global de hoje (40). **No
pico**, recua 10 % em 2 batidas e volta em 2 (`SECAO.pico_suave`). O
tremor: `tremer(Sala.TREMOR_GOLPE)` na ultrapassagem.

### A luz e o brilho

A luz é a da seção (`SECAO.montar`). O que brilha:

| o quê | energia | dono |
| --- | --- | --- |
| as faíscas do sopro duplo (20) e da ultrapassagem (30) | as de `Efeitos.faiscas` | a equipe, `CORES_DAS_EQUIPES[d]` |
| o rastro de vapor | 0,6 | a equipe |
| as faíscas de vapor do erro (30) | as de `Efeitos.faiscas` | o mundo, `ETIQUETA_SOMBRA` |
| as nuvens nas nuvens (60 faíscas) | as de `Efeitos.faiscas` | a equipe que chegou |
| a lava, as brasas, o néon | os da J1 | o mundo |

O balão é fosco: a cor da equipe não brilha, para as faíscas e o rastro
lerem como acento.

## O som

| evento | id do mapa | onde | volume |
| --- | --- | --- | --- |
| a faixa | `mus_s02_j09` (128 BPM); até a H05, a sintetizada a 96 | TV | o da faixa |
| o sopro do acerto | `Som.tocar("sopro")` = `sint_sopro`, tom `2^(⌊altura/4⌋/12)` | TV, no cesto | −8 dB (o Aprendiz −10) |
| o vapor do erro | `sint_sopro`, tom 0,8 | TV, no cesto | 0 dB |
| as nuvens | `Som.tocar("sucesso")` = `vitoria_sala_0..1` (sem ele, `sint_sucesso`) | TV, no cesto | 0 dB |
| o pulso da vez | `mod_pulso` (`som_falante(l, "pulso", 0.4)`) | alto-falante do dono | 0,4 |
| PERFEITO e ERRO | o kit | alto-falante do dono | o do kit |
| a textura do acerto | `mod_material_madeira` (o kit, `"material": "madeira"`) | atuadores do dono | o do kit |
| o vento da ultrapassagem | `mod_pulso` nos atuadores (`SECAO.vento(l, 0.6, ...)`) | um lado, 400 ms depois o outro | 0,6 |

A ultrapassagem não tem som próprio no mapa: é faísca, tremor e vibração.

## O controle

| recurso | o evento | para quem | o quê | a prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| acelerômetro | cada nota | o dono | o pico em g contra 1,8 (o rearme abaixo de 1,3) | o robô (`robo_sacudir`) e a linha `entrada` com o `pico_g` |
| vibração | o acerto e o erro | o dono | o kit | o kit (H08) |
| vibração | o sopro duplo | os dois da dupla | `sentir(o, "acerto")` | a prova do kit |
| vibração | a ultrapassagem | a dupla que passou | `sentir(o, "golpe", 120)`: forte 1,0 e fraco 0,6 | `percepcao(l).forte` ≥ 0,95 de +0 a +0,05 s do `ultrapassou_t` |
| vibração | as nuvens | a dupla que chegou | `sentir(o, "explosao")` | — |
| háptica | a ultrapassagem | a dupla passada | `SECAO.vento(o, 0.6, d == 0)`: o lado de quem passou, e 400 ms depois o outro | a linha `pista` `vento` |
| alto-falante | meio tempo antes de cada nota | o dono | `pulso` 0,4 | `som_virtual(l).falante` > 0 de +0 a +0,1 s do `pulso_t` |
| gatilho R2 | — | — | `GATILHO_OFF` | o kit |
| barra de luz | o julgamento | o dono | o kit (a cor do lugar, nunca a da equipe) | o kit |
| microfone | — | — | Não se aplica: a seção é do corpo | — |

## O cavaleiro

- **A peça aparece inteira e na cor dela.** O minigame não tinge o boneco:
  a cabeça (humana, orc, autômato, golem ou raposa), o superior e o
  inferior vêm da montagem com os tons próprios (G13). A gôndola rasa
  (0,3 m) deixa a calça à vista. A cor da equipe fica no balão, no disco,
  nas faíscas e no rastro; a do lugar, na barra de luz. As animações
  (`idle`, `attack-melee-right`, `emote-no`, `emote-yes`) servem às cinco
  raças.
- **As mãos livres** (`maos_livres(p)`).
- **Os stats** (`SECAO.gancho`; sem a classe `Cavaleiro`, o neutro). Nenhum
  mexe na janela, nos pontos, na altura nem nos limiares (1,8 e 1,3 g).

| gancho | o que muda aqui | stat 1 | stat 5 |
| --- | --- | --- | --- |
| `levantar` | o `emote-no` do erro (1 tempo) | 1,25 tempo | 0,75 tempo |
| `pista` | o pulso da vez chega antes | −40 ms | +40 ms |

## As reações

- **`car_em_chamas`** e **`car_por_um_fio`**: os do kit. O `car_acorde` não
  se aplica.
- **Os adesivos `rea_*`:** ninguém sai da rodada (o fole não derruba).
- Nenhum carimbo próprio deste minigame.

## A diversão

**O grito: a ultrapassagem** (`ultrapassa`), degrau golpe. A dupla de trás
passa a da frente: faíscas da cor dela no balão, o rastro de vapor, a
câmera treme (`TREMOR_GOLPE`), os dois cestos param 2 quadros, a mão de
quem passou leva o golpe e a de quem foi passado sente o vento correr.

- **O rastro:** o vapor na cor da equipe sob o balão que passou, 4 s.
- **Confere pelo robô (a mesa das duplas):** pelo menos 2 linhas `momento`
  `ultrapassa` em 90 s, pelo menos 1 depois dos 30 s; nos `momento` com
  `x_tela` ≥ 0, 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08.
- **Confere pela prancha:** em 2 quadros seguidos, a ordem das alturas
  troca (`balao_ultrapassa` e o quadro seguinte da sequência).

**A curva:** a tabela de **Como se joga**. Pelo robô (sem dupla nas
nuvens): `_vale(d)` dá 0,85 para a dupla a 30 m ou mais depois dos 60 s e
1,0 para a de trás.

**Ensina sem falar:** nas 4 batidas antes da primeira nota, os dois
tripulantes de cada dupla chacoalham em alternância (`attack-melee-right`
no tempo e no contratempo, `_ensinar`); o Aprendiz, quando completa, igual.

**Quem está perdendo:** a faixa de vento pesa na dupla da frente; a de
trás vê o balão do outro ficar lento. Pelo robô: pelo menos 1 linha
`momento` `ultrapassa` depois dos 60 s, ou a diferença final menor que a
diferença aos 60 s.

**O que se cortou:** nada.

## Pronto quando

O balão joga do aviso ao resultado com 4, 3, 2 e 1 jogador (o selo de
`com_poucos()` certo em cada um, o Aprendiz no cesto) e com o robô nos três
temperamentos; o cabo que cai e volta mantém a dupla; o fim tem sempre
vencedor; `_prova_do_balao()` passa; e a prancha mostra a troca da ordem.

## Provas

**`godot/testes/prova_do_jogo.gd`**, no `match` de `_prova_da_ficha`:
`"S02_J09": await _prova_do_balao()`.

```gdscript
## O Balão dos Foles (S02_J09): as duplas do kit, o pulso da vez, a
## ultrapassagem no tempo (o golpe e o vento), a faixa de vento e a régua da
## diversão.
func _prova_do_balao() -> void:
	var visto := {"golpe": {}, "pulso": {}, "maior": [0.0, 0.0], "aos_60": -1.0}
	var olhar := func(mg: Minigame) -> void:
		var agora := Ritmo.t_musica()
		for d in 2:
			visto.maior[d] = maxf(float(visto.maior[d]), float(mg.altura[d]))
		if agora >= 60.0 and float(visto.aos_60) < 0.0:
			visto.aos_60 = absf(float(mg.altura[0]) - float(mg.altura[1]))
		for l in mg.presentes():
			var e: Dictionary = mg.j[l]
			if float(e.pulso_t) >= 0.0 and agora - float(e.pulso_t) <= 0.1 and float(Forja.som_virtual(l).get("falante", 0.0)) > 0.0:
				visto.pulso[l] = true
			if mg.ultrapassou_t >= 0.0 and agora - mg.ultrapassou_t <= 0.05 and float(Forja.percepcao(l).get("forte", 0.0)) >= 0.95:
				visto.golpe[l] = true
	var mg := await _joga_o_minigame("S02_J09", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.dupla == [[0, 1], [2, 3]] and mg.aprendizes == [0, 0], "S02_J09: as duplas pela ordem dos lugares (%s)" % [mg.dupla])
	_esperar(visto.maior[0] > 0.0 and visto.maior[1] > 0.0, "S02_J09: os dois balões subiram (%s)" % [visto.maior])
	_esperar(visto.pulso.size() == 4, "S02_J09: o pulso da vez no alto-falante dos quatro (%s)" % [visto.pulso.keys()])
	var v: Array = mg.vencedor()
	_esperar(int(mg.j[v[0]].dupla) == int(mg.j[v[1]].dupla), "S02_J09: a dupla vencedora vem junta (%s)" % [v])
	var passadas := []
	var reta := 0
	var vento := 0
	for ev in _linhas_do_minigame("S02_J09"):
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "ultrapassa":
			passadas.append(float(ev.get("t_musica", 0.0)))
			for o in mg.dupla[int(ev.get("dupla", 0))]:
				_esperar(visto.golpe.has(o), "S02_J09 P%d: o golpe da ultrapassagem na mão" % [int(o) + 1])
			if float(ev.get("x_tela", -1.0)) >= 0.0:
				_esperar(float(ev.x_tela) >= 0.2 and float(ev.x_tela) <= 0.8 and float(ev.altura_tela) >= 0.08,
					"S02_J09: a ultrapassagem no quadro (%s)" % [ev])
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "reta":
			reta += 1
		if ev.get("tipo", "") == "pista" and ev.get("o", "") == "vento":
			vento += 1
	_esperar(passadas.size() >= 2 and passadas.max() > 30.0,
		"S02_J09: 2 ou mais ultrapassagens, 1 depois de 30 s (%s)" % [passadas])
	_esperar(vento >= 2 * passadas.size(), "S02_J09: o vento na dupla passada (%d)" % vento)
	_esperar(reta <= 1, "S02_J09: no máximo uma linha momento reta (%d)" % reta)
	if mg.chegou < 0:
		var dif_final := absf(float(mg.altura[0]) - float(mg.altura[1]))
		_esperar((not passadas.is_empty() and passadas.max() > 60.0) or dif_final < float(visto.aos_60),
			"S02_J09: depois dos 60 s, a de trás passa ou encosta (%.2f contra %.2f)" % [dif_final, float(visto.aos_60)])
		mg.altura = [31.0, 10.0]
		_esperar(is_equal_approx(mg._vale(0), 0.85) and is_equal_approx(mg._vale(1), 1.0),
			"S02_J09: a faixa de vento pesa só na dupla acima de 30 m")
```

A `reta` pode faltar quando uma dupla chega às nuvens antes das últimas 16
batidas: a prova pede no máximo uma.

**`godot/testes/captura_jogo.gd`**, no dicionário `momentos`:

```gdscript
		"S02_J09": [
			["balao_fole", fase.call("jogo", 6.0)],
			["balao_ultrapassa", na_sala.call(func(sala) -> bool:
				return sala.ultrapassou_t >= 0.0 and Ritmo.t_musica() - sala.ultrapassou_t <= 0.3)],
		],
```

**Os comandos:** `SALA=S02_J09 bash tests/prova_do_jogo.sh` e
`SALAS=S02_J09 bash tests/prova_visual.sh`.

**As pranchas que o jogador do time olha:**

- `balao_ultrapassa`: os dois balões no quadro, o que passou com o rastro
  de vapor da cor dele;
- `S02_J09_fim`: o balão vencedor nas nuvens;
- o boneco de cada lugar na gôndola: a cabeça, o superior e o inferior em
  tons diferentes, a calça à vista.

**O André (local):** `./run-local.sh -- --sala=S02_J09` com quatro: o tempo
e o contratempo se ouvem como um fole só; o pulso diz a vez sem olhar; o
sopro sobe de tom com o balão; a ultrapassagem faz a sala de uma dupla
gritar; a faixa de vento dá chance a quem está atrás.
