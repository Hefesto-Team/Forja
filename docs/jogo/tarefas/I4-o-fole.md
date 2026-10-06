# I4 — O Fole

**Sprint:** I · **Slot:** S01_J04 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, H07, G03 (o L2 é do item), I1 (o `secao.gd`)

## Por quê

A profundidade do R2 é a altura da nota: cada um afunda o gatilho até o
ponto da sua nota, no tempo dela, e a forja só pega fogo se os quatro
fecham o acorde — o curso analógico do gatilho, medido nota a nota, com a
resistência dizendo ao dedo onde fica o seu ponto.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 4 em 03](../03-os-45-minigames.md#s1--a-centelha--botões-analógicos-gatilhos-analógicos)
- [O índice da seção](I-a-centelha.md) e a [I1](I1-o-martelo-de-hefesto.md#o-cenário)
- [F03 — Todo minigame fecha](F03-todo-minigame-fecha.md) (o `coop` e o `coop_venceu`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J04",
	"titulo": "O Fole",
	"verbo": "Sopre a forja!",
	"genero": "coop",
	"icone": "gatilhos",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S01_J04",
	"duracao": 80.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Sopre!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S01_J04` — até a H05, a sintetizada a 108 bpm; com a
  gerada, 115 bpm ("notas longas, filtro abrindo").
- **A altura de cada um:** a faixa do R2 onde mora a nota do lugar —
  P1 0,30, P2 0,48, P3 0,66, P4 0,84, cada uma com ±0,07 (a nota mais funda
  é a mais aguda, como o dó-ré-fá-sol do kit). O R2 de cada um tem a
  **resistência (Feedback) começando na sua faixa**: posição `[2, 4, 5, 7]`
  e força 4. Sem olhar, o dedo sente onde é.
- **O hoqueto em semínimas:** a nota do lugar `l` é a batida `4c + l`; os
  quatro, um por tempo, são o acorde do compasso. `Ritmo.simples[l]`: uma
  nota a cada 2 compassos.
- **A nota:** o R2 **entra** na faixa (vindo de baixo) — o instante é o
  toque (`julgar_toque`). Entrar mais de meio tempo antes não conta. Passar
  da faixa no mesmo quadro (afundou demais) é erro. A nota longa:
  **segurar dentro da faixa** até 1 tempo depois da batida (±0,02 de folga);
  soltar antes quebra o acorde, sem erro. Nada entrou até
  `FOLGA_PERDIDA`, o do kit depois → nota perdida.
- **A chama** (0 a 1, de todos): cada acerto soma, em partes por nota,
  `[0, 0,005, 0,009, 0,012]` (ERRO, BOM, ÓTIMO, PERFEITO) vezes `4 / presentes`;
  o erro tira 0,01; **o acorde fecha** (todos os presentes com controle
  acertaram e seguraram a nota no compasso que acabou) → +0,02; a cada
  compasso a chama perde 0,004. Chegou a 1: **a forja chega ao branco**.
- **Os pontos por julgamento** (os do soprador, para o destaque):
  `[0, 20, 35, 50]`, mais 15 por nota segurada até o fim.
- **A progressão:** `andamento()` do kit (em tempo de música, H08). De 0 a 1/3, uma nota por
  compasso. **O pico (1/3 a 2/3), o fole duplo:** duas por compasso
  (`4c + 0,5·l` e `4c + 2 + 0,5·l`), segurando meio tempo; a chama cresce
  mais depressa e a música abre. De 2/3 em diante, uma por compasso. Um
  grupo que acerta dois terços chega ao branco entre 55 e 70 s.

## O cenário

`SECAO.montar(self)` e, no meio, a fornalha comum; em cada raia, o fole:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a fornalha | `Kit.caixa(3.0, 0.8, 2.0)`, `#5a5270`; `rocks` em volta (escala 1.2) | `(0, 0.4, −2.5)` |
| a chama | cinco `Kit.caixa` empilhadas, de 1,2 a 0,4 m de lado, `Kit.material(cor, 2.0)`; a cor vai de `#ff6a2a` a `#fff4e0` com a chama; a altura da pilha e o brilho sobem com ela | `(0, 0.8, −2.5)` para cima |
| a luz da chama | `OmniLight3D`, a cor da chama, energia `0.8 + 2.4·chama` | `(0, 2.0, −2.0)` |
| a raia | `raia(l)` | `(RAIAS[l], 0, Z_JOGADOR)` |
| o fole | duas tábuas `Kit.caixa(1.0, 0.08, 0.6)`, `#8a5a33`; o couro `Kit.caixa(0.9, 1.0, 0.5)`, `#4a3a44`, com a altura do vão; o bico `Kit.caixa(0.12, 0.12, 0.8)`, ferro | `(RAIAS[l], 0.3, 0.2)`; a tábua de cima gira `rotation.x = −0.45 × (1 − R2)` |
| o cano | `Kit.caixa(0.1, 0.1, comprimento)`, ferro, do bico à fornalha | do fole a `(0, 0.2, −1.6)` |
| a régua da nota | trilho `Kit.caixa(0.16, 1.4, 0.04)` com `Kit.chapado(Tema.TRILHO)`; a faixa da nota `Kit.chapado(Tema.AMARELO)` na altura dela; o nível na cor do lugar | ao lado do fole, `(RAIAS[l] + 0.9, 0.2, 0.6)` |
| o soprador | o boneco, olhando a fornalha, mãos livres | `(RAIAS[l], 0.05, Z_JOGADOR + 0.4)` |

Câmera: `camera_pos = Vector3(0, 7.0, 12.0)`, `camera_olhar = Vector3(0, 1.0, -1.0)`.
A chama é emissiva (tem trabalho), em blocos; nada liso.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **gatilho analógico (a feature)** | a profundidade é a nota; o Feedback no R2 marca onde ela começa |
| vibração | o kit por nota; o acorde fecha: `Forja.sentir(l, "acerto")` em todos; o branco: `Forja.sentir(l, "explosao")` em todos |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "tom", 0.5)`; erro: a nota quebrada (o kit) |
| gatilho | R2: Feedback na faixa do lugar do começo ao fim; o L2 nunca (item) |
| háptica por material | `madeira`, pelo kit |
| som na TV | a nota (o kit); `sopro` a cada nota segurada até o fim (na raia); `fogo` em laço na fornalha (`Som.laco("fogo", self, Vector3(0, 1, -2.5), -10.0)`), mais alto com a chama; `sucesso` no branco |

## A falha

A chama engasga e cospe fumaça no rosto do soprador: faíscas cinza
(`Efeitos.faiscas(self, rosto, Color("#5a5560"), 30, 0.6)`, na cabeça do
boneco), `p.gesto("emote-no", 0.5)`, a chama perde 0,01 e o acorde daquele
compasso não fecha. A próxima nota vem no tempo de sempre.

## O fim e o vencedor

O `coop` vem do gênero da FICHA (o kit, H08). A chama em 1 → `coop_venceu =
true` e todos acabam (o fim da F03, com o jingle de vitória coop). Os 80 s de
música sem o branco → `coop_venceu` fica `false`: no `ao_terminar()`, a
chama encolhe a uma brasa. O registro grava `vencedor` −1 (coop: todos
venceram ou todos perderam); `destaque()` é o melhor soprador, pelos pontos,
empate pelo lugar.

## Com menos de quatro

O acorde é o de quem está: com três, três notas por compasso (o tempo do
ausente fica mudo). O ganho de cada nota é `× 4 / presentes`, então o
branco chega no mesmo tempo com um, dois, três ou quatro. **O controle que
cai:** ele sai do acorde enquanto está sem controle (o acorde fecha com os
outros); ao voltar, o Feedback do R2 é mandado de novo e a nota da vez é o
próximo tempo dele.

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if float(e.b) < 0.0:
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, entra 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	var alvo := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
	var fim := Ritmo.t_da_batida(float(e.b) + _sustenta(l)) + 0.05
	var agora := Ritmo.t_musica()
	if agora < alvo - 0.03 or agora > fim:
		return  # solto: o gatilho volta sozinho ao repouso
	# afunda até o meio da faixa nos 30 ms antes da mira, e segura
	var v := lerpf(0.1, ALTURA[l], clampf((agora - (alvo - 0.03)) / 0.03, 0.0, 1.0))
	Forja.robo_eixo(l, Forja.R2, v, 0.06)
```

## Os ganchos

`godot/scripts/minigames/s01/o_fole.gd`:

```gdscript
extends Minigame
## O Fole (S01_J04). Os quatro sopram a mesma forja. A profundidade do R2 é a
## altura da nota: cada um afunda até a sua faixa, no seu tempo do compasso, e
## segura a nota longa; se os quatro fecham o acorde, a chama cresce. No meio,
## o fole duplo. A chama no branco: todos vencem.
##
## A falha: a chama engasga e cospe fumaça no rosto do soprador.
## O vencedor: coop — a forja no branco (todos) ou apagada; o destaque é o
## melhor soprador (os pontos).
## O alto-falante do dono: o tom no acerto, a nota no perfeito.
## O registro mede: a profundidade de cada nota (a linha `entrada`, com o
## valor do R2 na entrada e o menor e o maior durante a nota), e cada nota e
## toque (o kit).
## O robô: afunda até o meio da faixa na nota e segura; quando não acerta,
## 200 ms atrasado.
## Com menos de quatro: o acorde é de quem está; o ganho compensa.
## A régua: "Sopre a forja!" e o R2 no aviso bastam; sem a tela, a
## resistência do R2 diz a altura e a nota de cada um na TV diz o tempo; nada
## pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const ALTURA := [0.30, 0.48, 0.66, 0.84]  ## o meio da faixa de cada lugar no R2
const MEIA_FAIXA := 0.07
const POS_FEEDBACK := [2, 4, 5, 7]  ## onde a resistência começa (0..9), na faixa de cada um
const FOLGA_SEGURAR := 0.02
const GANHO := [0.0, 0.005, 0.009, 0.012]  ## ERRO, BOM, OTIMO, PERFEITO
const PERDA_ERRO := 0.01
const ACORDE := 0.02
const ESFRIA := 0.004  ## por compasso
const PONTOS := [0, 20, 35, 50]
const SEGUROU := 15

var j := {}
var chama := 0.0
var _compasso_visto := -1
var _chama: Array = []  ## as cinco caixas da chama
var _luz_chama: OmniLight3D
var _fogo: AudioStreamPlayer3D
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.0, 12.0)
	camera_olhar = Vector3(0, 1.0, -1.0)
	SECAO.montar(self)
	Kit.caixa(self, Vector3(3.0, 0.8, 2.0), Vector3(0, 0.4, -2.5), Kit.material(Color("#5a5270"), 0.0, 0.95))
	for x in [-1.8, 1.8]:
		Kit.peca(self, "rocks", Vector3(x, 0, -2.5), 0.0, 1.2)
	for k in 5:
		var lado := 1.2 - 0.2 * k
		_chama.append(Kit.caixa(self, Vector3(lado, 0.4, lado), Vector3(0, 1.0 + 0.4 * k, -2.5), Kit.material(Color("#ff6a2a"), 2.0)))
	_luz_chama = OmniLight3D.new()
	_luz_chama.position = Vector3(0, 2.0, -2.0)
	_luz_chama.omni_range = 9.0
	add_child(_luz_chama)
	_fogo = Som.laco("fogo", self, Vector3(0, 1.0, -2.5), -10.0)
	var ferro := Kit.material(Color("#4a4e5e"), 0.0, 0.7)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var x: float = RAIAS[l]
		var fole := Node3D.new()
		fole.position = Vector3(x, 0.3, 0.2)
		add_child(fole)
		var madeira := Kit.material(Color("#8a5a33"), 0.0, 0.85)
		Kit.caixa(fole, Vector3(1.0, 0.08, 0.6), Vector3.ZERO, madeira)
		var tampa := Node3D.new()
		tampa.position = Vector3(0, 0.05, 0.3)  # a dobradiça atrás
		fole.add_child(tampa)
		Kit.caixa(tampa, Vector3(1.0, 0.08, 0.6), Vector3(0, 0, -0.3), madeira)
		var couro := Kit.caixa(fole, Vector3(0.9, 1.0, 0.5), Vector3(0, 0.1, 0), Kit.material(Color("#4a3a44"), 0.0, 0.9))
		Kit.caixa(fole, Vector3(0.12, 0.12, 0.8), Vector3(0, 0.05, -0.7), ferro)
		var ate := Vector3(0, 0.2, -1.6)
		var de := Vector3(x, 0.2, -0.5)
		var cano := Kit.caixa(self, Vector3(0.1, 0.1, de.distance_to(ate)), (de + ate) * 0.5, ferro)
		cano.rotation.y = atan2(ate.x - de.x, ate.z - de.z)
		var regua := Node3D.new()
		regua.position = Vector3(x + 0.9, 0.2, 0.6)
		add_child(regua)
		Kit.caixa(regua, Vector3(0.16, 1.4, 0.04), Vector3(0, 0.7, 0), Kit.chapado(Tema.TRILHO))
		Kit.caixa(regua, Vector3(0.22, 1.4 * 2.0 * MEIA_FAIXA, 0.05), Vector3(0, 1.4 * ALTURA[l], 0), Kit.chapado(Tema.AMARELO))
		var nivel := Kit.caixa(regua, Vector3(0.1, 1.0, 0.07), Vector3.ZERO, Kit.chapado(Forja.cor_do_lugar(l)))
		maos_livres(p)
		p.position = Vector3(x, 0.05, Z_JOGADOR + 0.4)
		p.olhar_para(Vector3(0, 0, -2.5))
		j[l] = {"b": -1.0, "n": 0, "v_antes": 0.0, "dentro": false, "segurando": false, "min": 1.0, "max": 0.0,
			"entrou": 0.0, "ok_c": -1, "fora": false, "tampa": tampa, "couro": couro, "nivel": nivel,
			"robo_n": -1, "robo_mira": 0.0}


## Quantos tempos a nota longa dura.
func _sustenta(_l: int) -> float:
	return 0.5 if no_pico() else 1.0


func _proxima_batida(l: int, b: float) -> float:
	var passo := 4.0
	var desloc := float(l)
	if Ritmo.simples[l]:
		passo = 4.0  # o kit dobra o passo na partitura simples
	elif no_pico():
		passo = 2.0
		desloc = 0.5 * l
	return proxima_batida(l, b, passo, desloc)  # o kit (H08): a próxima depois de b


func _marcar_nota(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	e.b = b
	e.segurando = false
	e.min = 1.0
	e.max = 0.0
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))


func iniciar_jogo() -> void:
	for l in presentes():
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, POS_FEEDBACK[l], 4)
		_marcar_nota(l, _proxima_batida(l, BATIDA_DA_PRIMEIRA_NOTA - 1.0))


func jogar(_dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso_visto:
		if _compasso_visto >= 1:
			_fechar_o_compasso(_compasso_visto)
		_compasso_visto = c
	for l in presentes():
		var e: Dictionary = j[l]
		var v := Forja.eixo(l, Forja.R2)
		_mostrar(l, v)
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, POS_FEEDBACK[l], 4)
			_marcar_nota(l, _proxima_batida(l, Ritmo.batida()))
		_nota(l, e, v)
	if chama >= 1.0 and not coop_venceu:
		_branco()
	_mostrar_a_chama()


func _nota(l: int, e: Dictionary, v: float) -> void:
	var lo: float = ALTURA[l] - MEIA_FAIXA
	var hi: float = ALTURA[l] + MEIA_FAIXA
	var alvo := Ritmo.t_da_batida(float(e.b))
	var agora := Ritmo.t_musica()
	var antes := float(e.v_antes)
	e.v_antes = v
	if bool(e.segurando):
		# a nota longa: segurar na faixa até o fim dela
		e.min = minf(float(e.min), v)
		e.max = maxf(float(e.max), v)
		if v < lo - FOLGA_SEGURAR or v > hi + FOLGA_SEGURAR:
			_fim_da_nota(l, false)
		elif Ritmo.batida() >= float(e.b) + _sustenta(l):
			_fim_da_nota(l, true)
		return
	if antes < lo and v >= lo and agora >= alvo - 0.5 * 60.0 / Ritmo.bpm:
		anotar("entrada", l, {"o": "gatilho", "lado": "R2", "entrou": snappedf(v, 0.01), "faixa": ALTURA[l], "n": int(e.n)})
		e.entrou = v
		if v > hi:
			nota_perdida(l, int(e.n))  # afundou demais de uma vez: a chama engasga
		else:
			julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


## A nota longa acabou: segurada até o fim (o acorde conta com ela) ou solta antes.
func _fim_da_nota(l: int, segurou: bool) -> void:
	var e: Dictionary = j[l]
	anotar("entrada", l, {"o": "gatilho", "lado": "R2", "min": snappedf(float(e.min), 0.01),
		"max": snappedf(float(e.max), 0.01), "segurou": segurou, "n": int(e.n)})
	if segurou:
		e.ok_c = int(floor(float(e.b) / 4.0))
		marcar(l, SEGUROU)
		Som.tocar("sopro", Vector3(RAIAS[l], 0.8, 0.0), -6.0)
	_seguinte(l)


func _seguinte(l: int) -> void:
	var e: Dictionary = j[l]
	e.n = int(e.n) + 1
	_marcar_nota(l, _proxima_batida(l, float(e.b)))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if not treinando:
		chama = clampf(chama + GANHO[julgamento] * 4.0 / maxf(presentes().size(), 1.0), 0.0, 1.0)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "tom", 0.5)
	var p := jogador(l)
	if p:
		p.gesto("interact-right", 0.4)
	e.segurando = true  # agora a nota longa


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	if not treinando:
		chama = maxf(0.0, chama - PERDA_ERRO)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
		Efeitos.faiscas(self, p.global_position + Vector3(0, 1.7, 0), Color("#5a5560"), 30, 0.6)
	_seguinte(l)


## O compasso `c` acabou: o acorde fecha se todos os presentes com controle
## seguraram uma nota nele; e a chama esfria um pouco.
func _fechar_o_compasso(c: int) -> void:
	if treinando:
		return
	var todos := true
	var algum := false
	for l in presentes():
		if not conectado(l) or acabou[l]:
			continue
		algum = true
		if int(j[l].ok_c) != c:
			todos = false
	if algum and todos:
		chama = minf(1.0, chama + ACORDE)
		Efeitos.faiscas(self, Vector3(0, 2.4, -2.5), Tema.AMARELO, 40, 1.2)
		for l in presentes():
			if conectado(l):
				Forja.sentir(l, "acerto")
	chama = maxf(0.0, chama - ESFRIA)


## A forja chegou ao branco: todos vencem.
func _branco() -> void:
	coop_venceu = true
	Som.tocar("sucesso", Vector3(0, 2.0, -2.5))
	Efeitos.faiscas(self, Vector3(0, 3.0, -2.5), Color("#fff4e0"), 80, 1.6)
	for l in presentes():
		Forja.sentir(l, "explosao")
		acabou[l] = true


func ao_terminar() -> void:
	if not coop_venceu:
		chama = 0.05  # a forja apagou: fica a brasa
		_mostrar_a_chama()


func _mostrar_a_chama() -> void:
	var cor := Color("#ff6a2a").lerp(Color("#fff4e0"), chama)
	for k in _chama.size():
		var caixa: MeshInstance3D = _chama[k]
		caixa.visible = k <= int(chama * 4.99)
		var m: StandardMaterial3D = caixa.material_override
		m.albedo_color = cor
		m.emission = cor
		m.emission_energy_multiplier = 1.2 + 2.0 * chama
		caixa.position.y = 1.0 + 0.4 * k + 0.05 * sin(Ritmo.batida() * TAU + k)
	_luz_chama.light_color = cor
	_luz_chama.light_energy = 0.8 + 2.4 * chama
	if is_instance_valid(_fogo):
		_fogo.volume_db = -14.0 + 8.0 * chama


func _mostrar(l: int, v: float) -> void:
	var e: Dictionary = j[l]
	(e.tampa as Node3D).rotation.x = -0.45 * (1.0 - v)
	(e.couro as Node3D).scale.y = maxf(0.1, 1.0 - v)
	var nivel: MeshInstance3D = e.nivel
	nivel.scale.y = maxf(0.02, v * 1.4)
	nivel.position.y = v * 1.4 * 0.5


## Coop: o kit grava vencedor −1 (H08); o destaque é o melhor soprador.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

## O que o registro mede

- O kit: `nota` e `toque` (o instante em que o R2 entrou na faixa).
- A linha `entrada` duas vezes por nota: na entrada, o valor do R2 e a
  faixa pedida; no fim da nota, o menor e o maior valor durante a nota e se
  segurou. Cruzado depois da noite: um gatilho que nunca chega aos 0,84 do
  P4, que só dá solto e fundo (sem meio), ou que treme na nota longa.

## Armadilhas

- **O R2 é do minigame, o L2 é do item:** só `Forja.gatilho(l, 1, ...)`;
  nunca `gatilhos_off` (apagaria o Escudo do L2). O fim do kit
  (`Forja.silencio`) solta os dois — está certo.
- **Entrar, não estar:** a nota é o R2 **cruzar** a borda de baixo da faixa.
  Quem já está dentro antes da nota tem de soltar e entrar de novo.
- **O acorde fecha pelo compasso da nota** (`floor(b / 4)`), não pelo de
  agora: a nota do P4 no tempo 4 termina no compasso seguinte.
- **A chama não cresce no treino.** O `marcar` já não soma no treino.
- **Coop no fechamento** (H08): o registro grava `vencedor` −1 e a tela diz
  "Todos venceram!" ou "A forja apagou."; o destaque sai de `destaque()`.
  Ninguém liga o `coop` à mão: o kit tira do gênero.
- **O `Som.laco`** é um nó filho da sala: sai com ela; não o pare à mão.

## Pronto quando

O Fole joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; a forja chega ao branco com o robô bom e apaga com o
ruim; o cabo que cai e volta recebe o Feedback de novo; o fim tem sempre o
destaque (e `vencedor` −1 no registro); `bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh`
passa com a prancha **olhada** nas partidas em que O Fole aparece.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S01_J04 (I4): O Fole abre pelo catálogo; o Feedback chega ao R2 de cada
## controle simulado (e só ao R2); o robô entra na faixa de cada um; o fim é coop.
func _prova_do_fole() -> void:
	var r2 := [false, false, false, false]
	var olhar := func(_mg: Minigame) -> void:
		for l in 4:
			if int(_perc(l).get("gatilho_dir", 0)) == 0x21:
				r2[l] = true
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (80 s de música e o treino)
	var mg = await _joga_o_minigame("S01_J04", 120.0, olhar)
	if mg == null:
		return
	for l in 4:
		_esperar(r2[l], "S01_J04 P%d: o R2 com a resistência do fole" % (l + 1))
	_esperar(mg.coop and mg.destaque() >= 0, "S01_J04: fechou como coop, com o destaque")
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "S01_J04 P%d: entrou na faixa dele %s" % [l + 1, c])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J04: de volta ao salão")
	for l in 4:
		_esperar(int(_perc(l).get("gatilho_dir", 0)) == 0x05, "S01_J04 P%d: o R2 solto no salão" % (l + 1))
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S01_J04`: de olhos fechados,
cada um acha a sua faixa pela resistência; o acorde dos quatro se ouve; a
chama cresce; a fumaça no rosto faz rir; o fole duplo do meio aperta.

## Ao terminar

- Catálogo: `"S01_J04": preload("res://scripts/minigames/s01/o_fole.gd")` em
  `MINIGAMES` e na lista da S01.
- `traducoes.gd`: `"O Fole": "The Bellows"`, `"Sopre a forja!": "Blow the forge!"`,
  `"Sopre!": "Blow!"`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a I4 **feito**, com o commit.
- Commit (sem trailer): `feat: O Fole — a profundidade do R2 é a altura da nota`
