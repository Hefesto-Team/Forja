# J1 — A Viga

**Sprint:** J · **Slot:** S02_J06 · **Tamanho:** G · **Estimativa:** US$ 2,0 · **Depende de:** H04, H08, F09, F03, F05, H07, G05

## Por quê

Equilibrar é inclinar o controle contra o empurrão que a viga dá na nota —
para os lados, para a frente e para trás, como volante — e cravar o pino com
uma pancada: o giroscópio nos três eixos e o acelerômetro (a gravidade e o
pico), julgados no tempo, e os vereditos da bancada de hoje saindo daqui.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 6 em 03](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)
- [O índice da seção](J-a-viga.md) (as convenções, o `secao.gd`)
- [As decisões comuns dos minigames — H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08) — o fim em tempo de música, a fila de notas do kit, a barra de luz do kit

## O estado de hoje

`godot/scripts/salas/viga.gd` (694 linhas, `class_name SalaViga`) ainda é
uma sala antiga (`Catalogo.SALAS_ANTIGAS["viga"]`): três trechos em sequência
(a travessia pela rolagem, os sinos pela mira, a pedra pela martelada), por
`dt`, sem música. Ela sai: esta ficha cria
`godot/scripts/minigames/s02/a_viga.gd` (a regra nova) e
`godot/scripts/minigames/s02/secao.gd` (a caverna, a leitura do corpo, a
luz), e apaga `godot/scripts/salas/viga.gd` e o `.uid` dele (`git rm`).

| hoje | depois |
| --- | --- |
| travessia, sinos, pedra, um de cada vez | uma plataforma de vigas sobre a lava que balança **na nota**: a frase de 4 compassos pede rolagem, arfagem, rolagem e volante; o pino abre cada frase seguinte |
| vento contínuo, régua em cima do boneco | o empurrão chega na batida; a seta amarela diz para onde inclinar |
| cair e voltar à bandeirola | escorregar um passo a cada erro; quatro passos: cai na lava e volta em 2 compassos |
| pontos por trecho | o tempo em pé |
| `_robo` por `rng` | o robô pelo relógio da música |
| `med_pedir("mira")` nos sinos, `"martelada"` na pedra, `med_martelada` | os mesmos, no volante e na arfagem (a mira) e no pino (a martelada) |

A caverna (`_cenario()` e `_shader_lava()`, `viga.gd:120-180`) vai
**inteira** para o `secao.gd`, como está.

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J06",
	"titulo": "A Viga",
	"verbo": "Equilibre!",
	"genero": "sobrevivencia",
	"icone": "giroscopio",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J06",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "aviso"],
	"material": "madeira",
	"microjogo": {"verbo": "Incline!", "segundos": 6.0},
	# o que a bancada mede (o veredito é das medidas do núcleo)
	"features": ["giroscopio", "acelerometro"],
	"gesto": "lados",
}
```

## Como se joga

- **A faixa:** `MUS_S02_J06` — até a H05, a sintetizada da seção a 96 bpm
  (0,625 s por tempo); com a gerada, 115 bpm ("frio, eco pingue-pongue").
- **A plataforma:** cada um de pé no meio de três vigas amarradas, num pilar
  sobre a lava. **A nota do lugar** cai no hoqueto em colcheias
  (`2k + 0,5·l`); na nota, a plataforma leva um empurrão e o jogador inclina
  **contra**: a seta amarela sobre o boneco, que aparece um tempo e meio
  antes, aponta para onde. Os lados se alternam a cada nota.
- **A frase (16 tempos, quatro compassos):** o compasso pede, pelo número
  `c = floor((b − 4) / 4)`: `c % 4 == 0` **rolagem** (inclinar para a
  esquerda ou para a direita), `1` **arfagem** (inclinar a borda de longe
  para baixo ou para cima), `2` **rolagem**, `3` **volante** (girar o
  controle na horizontal, para a esquerda ou para a direita).
- **O pino:** a batida `4 + 16f` (f ≥ 1: as batidas 20, 36, 52…) é uma nota
  **de todos**: uma pancada para baixo (o acelerômetro passa de 1,8 g vindo
  de menos de 1,3 g) crava o pino da plataforma. A nota do P1 que cairia
  ali não existe.
- **O julgamento, no cruzamento** (as convenções da seção): a janela abre
  meio tempo antes da nota; o toque é o quadro em que a condição fica
  verdadeira — rolagem ou arfagem de pelo menos 0,25 rad (~14°) para o lado
  pedido, volante de pelo menos 1,2 rad/s para o lado pedido, a pancada.
  Nada até `FOLGA_PERDIDA` (o kit) depois → nota perdida. A nota é perigo
  físico: `julgar_toque(l, alvo, n, true)` (a folga de quem está em último).
- **O escorregão:** o erro escorrega o cavaleiro um passo (0,3 m) para o
  lado do empurrão; PERFEITO e ÓTIMO o trazem um passo de volta; BOM não
  mexe. **Quatro passos: ele cai na lava** (2 tempos caindo) e volta ao meio
  da plataforma 8 tempos depois. As notas enquanto ele está fora não contam.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o pino vale o dobro.
- **A progressão:** `progresso()` do kit (0..1 dos 80 s de música). De 0 a 1/3, uma nota
  a cada 2 tempos. **O pico (1/3 a 2/3), a viga torce:** uma nota por tempo
  (`k + 0,25·l`); a lava sobe de brilho. De 2/3 em diante, a cada 2 tempos.
  `Ritmo.simples[l]`: uma a cada 4 tempos.
- **A primeira volta** é a primeira frase inteira, com o pino da batida 20
  julgado: ela pede os três eixos do giroscópio e a martelada, e cabe
  folgada nos 80 s. **O fim é do kit, em tempo de música** (H08): os 80 s da
  FICHA contam em `Ritmo.t_musica()`, não em tempo de jogo.

## O cenário

`godot/scripts/minigames/s02/secao.gd` (novo, o arquivo inteiro):

```gdscript
extends RefCounted
## A seção A Viga (S02): o que os cinco minigames têm em comum — a caverna da
## lava (o cenário), a leitura do corpo com as saídas silenciosas (sem
## giroscópio, a gravidade; sem nada, o analógico) e a linha `troca` que as
## anota, e a conta do robô. A barra de luz que pisca no julgamento é do kit
## (H08). Sem class_name:
## const SECAO := preload("res://scripts/minigames/s02/secao.gd").
## Aqui não se chama Forja.robo_* nem se lê Forja.robo: o robô é dos ganchos.

static var _shader: Shader = null


## A caverna: as plataformas de pedra nas pontas, o poço de lava no meio (de
## z = −2 a z = 3), as paredes do kit, as brasas subindo, o neon laranja.
static func montar(sala: SalaJogo) -> void:
	# o corpo de viga.gd:121-157, trocando `self` por `sala` e
	# `atmosfera(...)`/`luzes(...)` por `sala.atmosfera(...)`/`sala.luzes(...)`;
	# o material da lava usa _shader_lava()


## Um pilar de pedra da lava até o chão (y = 0), onde o lugar pisa.
static func pilar(sala: Node3D, x: float, z: float) -> void:
	Kit.caixa(sala, Vector3(0.9, 1.6, 0.9), Vector3(x, -0.8, z), Kit.material(Color("#5a5270"), 0.0, 0.95))


static func _shader_lava() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = "..."  # o código de viga.gd:162-179, igual
	return _shader


## A inclinação para os lados, em rad (positivo: o lado direito desce).
static func rolagem(l: int) -> float:
	if Forja.capacidade(l, "giro"):
		return -Forja.postura(l).x
	if Forja.capacidade(l, "acel"):
		var a := Forja.acel(l)
		return -atan2(a.x, sqrt(a.y * a.y + a.z * a.z))
	return Forja.eixo(l, Forja.LX) * 0.45


## A inclinação para a frente e para trás, em rad (positivo: a borda de longe sobe).
static func arfagem(l: int) -> float:
	if Forja.capacidade(l, "giro"):
		return Forja.postura(l).y
	if Forja.capacidade(l, "acel"):
		var a := Forja.acel(l)
		return atan2(-a.z, sqrt(a.x * a.x + a.y * a.y))
	return Forja.eixo(l, Forja.LY) * 0.45


## O giro de volante, em rad/s (positivo: para a esquerda).
static func guinada(l: int) -> float:
	if Forja.capacidade(l, "giro"):
		return Forja.giro(l).y
	return -Forja.eixo(l, Forja.RX) * 3.0


## O acelerômetro em g; sem ele, a pancada é o ✕ (2 g no quadro do aperto).
static func forca_g(l: int) -> float:
	if Forja.capacidade(l, "acel"):
		return Forja.acel(l).length() / 9.80665
	return 2.0 if Forja.apertou(l, Forja.CRUZ) else 1.0


## A conta do robô: o giro (rad/s, como Forja.robo_girar pede) que leva o
## controle da inclinação de agora à pedida. Rápido (20 por rad, até 6 rad/s):
## chega ao limiar em uns 40 ms, na prova e no sofá.
static func giro_para(l: int, rol: float, arf: float, gui := 0.0) -> Vector3:
	var p := Forja.postura(l)
	return Vector3(clampf(20.0 * (arf - p.y), -6.0, 6.0), gui, clampf(20.0 * (-rol - p.x), -6.0, 6.0))


## Sem giroscópio ou sem acelerômetro, o jogo segue pelas saídas silenciosas;
## a linha `troca` (13, H08) diz para onde, uma vez por minigame, no iniciar_jogo().
static func anotar_troca(sala: SalaJogo, l: int) -> void:
	var giro := Forja.capacidade(l, "giro")
	var acel := Forja.capacidade(l, "acel")
	if not giro:
		Forja.evento("troca", l + 1, {"slot": sala.id, "de": "giroscopio", "para": "gravidade" if acel else "analogico"})
	if not acel:
		Forja.evento("troca", l + 1, {"slot": sala.id, "de": "acelerometro", "para": "botao"})
```

(Os dois trechos marcados com "o corpo de" e "o código de" são cópia literal
de `viga.gd`, com as trocas ditas.)

Por lugar, em `a_viga.gd`:

| o quê | peça | onde (m) |
| --- | --- | --- |
| o pilar | `SECAO.pilar(self, RAIAS[l], 0.8)` | `(RAIAS[l], −0.8, 0.8)` |
| a plataforma | um `Node3D` com três vigas `Kit.caixa(2.4, 0.2, 0.7)`, `#8a5a33`, em `z = −0.75, 0, 0.75`, e duas cintas `Kit.caixa(0.1, 0.24, 2.3)`, `#4a4e5e`, em `x = ±0.8` | `(RAIAS[l], 0.1, 0.8)`; gira pelo empurrão |
| a seta | `Kit.caixa(0.08, 0.5, 0.08)` e a ponta (duas `Kit.caixa(0.3, 0.08, 0.08)` a ±45°), `Kit.chapado(Tema.AMARELO, true)` | boneco + `(0, 2.4, 0)` |
| o cavaleiro | o boneco, de costas (`rotation.y = PI`), mãos livres, `preso` | em cima da plataforma, deslocado `passo × perigo` na direção do escorregão |

Câmera: `camera_pos = Vector3(0, 7.5, 11.0)`, `camera_olhar = Vector3(0, 0.6, 0.0)`.
A seta é interface dentro do mundo (chapada, como a régua de hoje). A lava
fica (11: é chão e o shader é chapado). A cor do lugar só no aro do boneco.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **giroscópio e acelerômetro (a feature)** | o corpo inclina, vira e bate no tempo |
| vibração | o kit por nota; a queda: `Forja.sentir(l, "golpe")`; o empurrão que vem com o cavaleiro a um passo da ponta (`perigo == 3`): `Forja.sentir(l, "aviso", int(30000.0 / Ritmo.bpm))` meio tempo antes |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "clique", 0.4)`; erro: a nota quebrada (o kit); **o metal rangendo**: `Forja.som_falante(l, "material:metal", 0.6)` meio tempo antes de cada nota enquanto `perigo >= 2` |
| gatilho | R2 endurece com o perigo: `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, 2 + 2 * perigo)` a cada mudança; `perigo == 0` → `GATILHO_OFF` no R2 |
| háptica por material | `madeira`, pelo kit |
| som na TV | a nota (o kit); `vento` baixo do lado do empurrão a cada nota de rolagem; `martelo` no pino; `falha` na queda |

## A falha

O empurrão ganha: a plataforma pende, o cavaleiro escorrega um passo para o
lado do empurrão (a posição anda para lá em 0,2 s) e faz `emote-no`. No
quarto passo ele cai: `p.gesto("fall", 1.3)`, desce 3,2 m em 2 tempos (pela
batida), faíscas `Tema.LARANJA` na lava, e 8 tempos depois volta ao meio da
plataforma com `jump` e um `Efeitos.anel` na cor dele.

## O fim e o vencedor

O kit fecha aos 80 s de música (`"fim": "tempo"`, H08). `vencedor()`: o
maior tempo em pé (segundos de música fora da lava, sem o treino); empate
pelo menor número de quedas, depois pelos pontos, depois pelo lugar.

## Com menos de quatro

Nada muda. **O controle que cai:** a plataforma dele para; o tempo em pé não
conta; ao voltar, a nota da vez é a próxima dele que ainda não passou. **Sem
giroscópio** (o controle não publica): a rolagem e a arfagem vêm da
gravidade e o volante do analógico direito; **sem nada**, do analógico
esquerdo; a linha `troca` diz qual (`SECAO.anotar_troca`).

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var rol := 0.0
	var arf := 0.0
	var gui := 0.0
	if float(e.caiu_b) < 0.0 and float(e.b) >= 0.0:
		if int(e.robo_n) != int(e.n):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			e.robo_n = int(e.n)
			e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
			e.robo_bateu = false
		var alvo := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
		var agora := Ritmo.t_musica()
		var ativo := agora >= alvo - 0.02 and agora <= alvo + 0.2
		match str(e.tipo):
			"rolagem":
				rol = 0.35 * float(e.pedido) if ativo else 0.0
			"arfagem":
				arf = 0.35 * float(e.pedido) if ativo else 0.0
			"guinada":
				gui = 3.0 * float(e.pedido) if ativo else 0.0
			"pino":
				if not bool(e.robo_bateu) and agora >= alvo - 0.01:
					Forja.robo_sacudir(l, 1.6, 0.2)
					e.robo_bateu = true
	# entre as notas, volta ao nível e fica parado (o acelerômetro mede 1 g parado)
	Forja.robo_girar(l, SECAO.giro_para(l, rol, arf, gui), 0.06)
```

## Os ganchos

`godot/scripts/minigames/s02/a_viga.gd`:

```gdscript
extends Minigame
## A Viga (S02_J06), o primeiro d'A Viga. Cada um de pé numa plataforma de
## vigas sobre a lava. Na nota do lugar (o hoqueto em colcheias) a plataforma
## leva um empurrão e ele inclina contra: a frase de quatro compassos pede
## rolagem, arfagem, rolagem e volante, e o pino abre cada frase seguinte
## (uma pancada de todos). No meio, a viga torce: uma nota por tempo.
##
## A falha: escorrega um passo; no quarto, cai na lava e volta em 2 compassos.
## O vencedor: mais tempo em pé.
## O alto-falante do dono: o clique no acerto, a nota no perfeito, o metal
## rangendo quando está perto da ponta.
## O registro mede: o pico de giro nos três eixos, a gravidade parada, a
## inclinação pela gravidade e a martelada (as medidas do núcleo: os
## vereditos da bancada); o ângulo pedido contra o feito e o atraso de cada
## movimento (a linha `entrada` e o kit).
## O robô: inclina o controle simulado até 0,35 rad na nota (ou 200 ms
## atrasado), gira o volante a 3 rad/s, bate a 2,6 g no pino.
## Com menos de quatro: nada muda.
## A régua: "Equilibre!" e o giroscópio no aviso bastam; sem a tela, o
## empurrão chega como aviso no controle e o metal range no alto-falante; nada
## pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const FRASE := 16.0
const TIPOS := ["rolagem", "arfagem", "rolagem", "guinada"]
const LIMIAR := 0.25  ## rad
const GIRO_MIN := 1.2  ## rad/s
const PANCADA := 1.8  ## g
const SOLTA := 1.3  ## g: abaixo disto, a próxima pancada pode vir
const QUEDA := 4  ## passos até a ponta
const PASSO := 0.3  ## m
const FORA := 8.0  ## tempos na lava
const PONTOS := [0, 20, 35, 50]
const Z_VIGA := 0.8

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.6, 0.0)
	SECAO.montar(self)
	var madeira := Kit.material(Color("#8a5a33"), 0.0, 0.85)
	var ferro := Kit.material(Color("#4a4e5e"), 0.0, 0.5)
	var seta_mat := Kit.chapado(Tema.AMARELO, true)
	for p in jogadores:
		var l: int = p.lugar
		SECAO.pilar(self, RAIAS[l], Z_VIGA)
		var viga := Node3D.new()
		viga.position = Vector3(RAIAS[l], 0.1, Z_VIGA)
		add_child(viga)
		for z in [-0.75, 0.0, 0.75]:
			Kit.caixa(viga, Vector3(2.4, 0.2, 0.7), Vector3(0, 0, z), madeira)
		for x in [-0.8, 0.8]:
			Kit.caixa(viga, Vector3(0.1, 0.24, 2.3), Vector3(x, 0, 0), ferro)
		var seta := Node3D.new()
		add_child(seta)
		Kit.caixa(seta, Vector3(0.08, 0.5, 0.08), Vector3.ZERO, seta_mat)
		for lado in [-1.0, 1.0]:
			var ponta := Kit.caixa(seta, Vector3(0.3, 0.08, 0.08), Vector3(lado * 0.09, 0.2, 0), seta_mat)
			ponta.rotation.z = lado * PI * 0.25
		seta.visible = false
		maos_livres(p)
		p.preso = true
		p.position = Vector3(RAIAS[l], 0.2, Z_VIGA)
		p.rotation.y = PI
		j[l] = {"n": 0, "b": -1.0, "tipo": "rolagem", "pedido": 0, "lado": 1, "antes": false, "aberta": false,
			"g_armado": true, "perigo": 0, "dir": Vector2.RIGHT, "caiu_b": -1.0, "quedas": 0, "em_pe": 0.0,
			"t_ant": 0.0, "volta": 0, "rangeu": -1, "fora": false, "viga": viga, "seta": seta,
			"robo_n": -1, "robo_mira": 0.0, "robo_bateu": false}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)  # sem giroscópio ou acelerômetro: a linha `troca` (H08)
		j[l].t_ant = Ritmo.t_musica()
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


## A nota seguinte do lugar depois da batida `desde`: o pino, se a frase
## muda antes; senão, o tempo dele no hoqueto, com o tipo do compasso.
func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var passo := 2.0
	var desloc := 0.5 * l
	if Ritmo.simples[l]:
		passo = 4.0
	elif no_pico():
		passo = 1.0
		desloc = 0.25 * l
	var s := proxima_batida(l, desde + 0.001, passo, desloc)  # o kit; estritamente depois de desde
	var pino := BATIDA_DA_PRIMEIRA_NOTA + FRASE * ceilf((desde + 0.001 - BATIDA_DA_PRIMEIRA_NOTA) / FRASE)
	if pino > BATIDA_DA_PRIMEIRA_NOTA and pino <= s:
		e.b = pino
		e.tipo = "pino"
		e.pedido = 0
		Forja.med_pedir(l, "martelada")
	else:
		e.b = s
		e.tipo = TIPOS[int(floor((s - BATIDA_DA_PRIMEIRA_NOTA) / 4.0)) % 4]
		e.lado = -int(e.lado)
		e.pedido = int(e.lado)
		if str(e.tipo) != "rolagem":
			Forja.med_pedir(l, "mira")
	e.aberta = false
	e.antes = false
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b)))


func jogar(_dt: float) -> void:
	var agora := Ritmo.t_musica()
	for l in presentes():
		var e: Dictionary = j[l]
		_mostrar(l)
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			e.t_ant = agora
			continue
		if bool(e.fora):
			e.fora = false
			_proxima(l, Ritmo.batida())
		if float(e.caiu_b) < 0.0 and not treinando:
			e.em_pe = float(e.em_pe) + (agora - float(e.t_ant))
		e.t_ant = agora
		if float(e.caiu_b) >= 0.0:
			if Ritmo.batida() >= float(e.caiu_b) + FORA:
				_voltar(l)
			continue
		_nota(l, e, agora)


func _condicao(l: int, e: Dictionary) -> bool:
	match str(e.tipo):
		"rolagem":
			return SECAO.rolagem(l) * float(e.pedido) >= LIMIAR
		"arfagem":
			return SECAO.arfagem(l) * float(e.pedido) >= LIMIAR
		"guinada":
			return SECAO.guinada(l) * float(e.pedido) >= GIRO_MIN
		"pino":
			var g := SECAO.forca_g(l)
			if g < SOLTA:
				e.g_armado = true
			return bool(e.g_armado) and g >= PANCADA
	return false


func _valor(l: int, e: Dictionary) -> float:
	match str(e.tipo):
		"rolagem":
			return SECAO.rolagem(l)
		"arfagem":
			return SECAO.arfagem(l)
		"guinada":
			return SECAO.guinada(l)
	return SECAO.forca_g(l)


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var meio_tempo := 0.5 * 60.0 / Ritmo.bpm
	var sim := _condicao(l, e)
	if agora < alvo - meio_tempo:
		e.antes = sim
		# o metal range meio tempo antes, perto da ponta; e o aviso, a um passo
		if int(e.rangeu) != int(e.n) and agora >= alvo - 2.0 * meio_tempo and int(e.perigo) >= 2:
			e.rangeu = int(e.n)
			Forja.som_falante(l, "material:metal", 0.6)
			if int(e.perigo) >= QUEDA - 1:
				Forja.sentir(l, "aviso", int(30000.0 / Ritmo.bpm))
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		if str(e.tipo) == "pino":
			e.g_armado = false
			if Forja.capacidade(l, "acel"):
				Forja.med_martelada(l)
		Forja.evento("entrada", l + 1, {"o": str(e.tipo), "pedido": int(e.pedido),
			"valor": snappedf(_valor(l, e), 0.01), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n), true)
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var pino := str(e.tipo) == "pino"
	marcar(l, int(PONTOS[julgamento]) * (2 if pino else 1))
	if julgamento >= Ritmo.OTIMO and not treinando:
		_perigo(l, int(e.perigo) - 1)
	if pino:
		e.volta = int(e.volta) + 1
		var onde := (e.viga as Node3D).global_position + Vector3(0, 0.3, 0)
		Som.tocar("martelo", onde, 0.0)
		Efeitos.faiscas(self, onde, Tema.LARANJA, 24, 1.0)
	elif str(e.tipo) == "rolagem":
		Som.tocar("vento", (e.viga as Node3D).global_position + Vector3(-3.0 * float(e.pedido), 1.2, 0), -14.0)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.4)
	_proxima(l, float(e.b))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	if str(e.tipo) == "pino":
		e.volta = int(e.volta) + 1  # a frase passou, com ou sem o pino
	elif str(e.tipo) == "arfagem":
		e.dir = Vector2(0, -float(e.pedido))
	else:
		e.dir = Vector2(-float(e.pedido), 0)
	var p := jogador(l)
	if not treinando:
		_perigo(l, int(e.perigo) + 1)
	if int(e.perigo) >= QUEDA:
		_cair(l)
	elif p:
		p.gesto("emote-no", 0.4)
	_proxima(l, float(e.b))


## O perigo (os passos até a ponta) muda: o R2 endurece com ele.
func _perigo(l: int, novo: int) -> void:
	var e: Dictionary = j[l]
	e.perigo = clampi(novo, 0, QUEDA)
	if int(e.perigo) == 0:
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	else:
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, mini(2 + 2 * int(e.perigo), 8))


func _cair(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = Ritmo.batida()
	e.quedas = int(e.quedas) + 1
	Forja.sentir(l, "golpe")
	var p := jogador(l)
	if p:
		p.gesto("fall", 1.3)
		Som.tocar("falha", p.global_position, -4.0)
		Efeitos.faiscas(self, Vector3(p.global_position.x, -1.3, p.global_position.z), Tema.LARANJA, 30, 0.9)


func _voltar(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = -1.0
	_perigo(l, 0)
	var p := jogador(l)
	if p:
		p.gesto("jump", 0.5)
		Efeitos.anel(self, (e.viga as Node3D).global_position + Vector3(0, 1.0, 0), Forja.cor_do_lugar(l), 0.6)
	_proxima(l, Ritmo.batida())


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var viga: Node3D = e.viga
	var agora_b := Ritmo.batida()
	var falta := float(e.b) - agora_b
	# o empurrão: a plataforma pende para o lado dele no último tempo antes da nota
	var pende := 0.22 * clampf(1.0 - absf(falta), 0.0, 1.0) if fase == "jogo" and float(e.caiu_b) < 0.0 else 0.0
	viga.rotation = Vector3.ZERO
	match str(e.tipo):
		"rolagem":
			viga.rotation.z = pende * float(e.pedido)
		"arfagem":
			viga.rotation.x = pende * float(e.pedido)
		"guinada":
			viga.rotation.y = pende * 2.0 * float(e.pedido)
		"pino":
			viga.position.y = 0.1 - pende * 0.3
	var p := jogador(l)
	var seta: Node3D = e.seta
	if p == null:
		return
	var deslize: Vector2 = e.dir * PASSO * int(e.perigo)
	var alvo := viga.global_position + Vector3(deslize.x, 0.1, deslize.y)
	if float(e.caiu_b) >= 0.0:
		var s := clampf((agora_b - float(e.caiu_b)) / 2.0, 0.0, 1.0)
		alvo.y -= 3.2 * s * s
	p.position = p.position.lerp(alvo, 0.2) if float(e.caiu_b) < 0.0 else alvo
	p.animar("idle")
	seta.visible = fase == "jogo" and not acabou[l] and float(e.caiu_b) < 0.0 and falta <= 1.5 and falta > -0.3
	seta.position = p.position + Vector3(0, 2.4, 0)
	seta.rotation = Vector3.ZERO
	match str(e.tipo):
		"rolagem", "guinada":
			seta.rotation.z = PI * 0.5 * float(e.pedido)
			if str(e.tipo) == "guinada":
				seta.rotation.y = fmod(agora_b, 1.0) * TAU
		"arfagem":
			seta.rotation.x = PI * 0.5 * float(e.pedido)
		"pino":
			seta.rotation.z = PI


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if not is_equal_approx(float(j[a].em_pe), float(j[b].em_pe)):
		return float(j[a].em_pe) > float(j[b].em_pe)
	if int(j[a].quedas) != int(j[b].quedas):
		return int(j[a].quedas) < int(j[b].quedas)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Em pé: %d s" % int(j[lugar].em_pe)
	return super(lugar)
```

## O que o registro mede

- As medidas do núcleo, como hoje (o módulo mede a cada quadro): o pico de
  giro em cada eixo, a taxa declarada contra a medida, o sinal do giro
  contra a gravidade, 1 g parado, a inclinação pela gravidade e as
  marteladas (`med_pedir("mira")` no volante e na arfagem,
  `med_pedir("martelada")` e `med_martelada` no pino) — os vereditos
  `giroscopio` e `acelerometro` da bancada.
- O kit: `nota` e `toque` (o atraso entre o pulso e o movimento).
- A linha `entrada`: o que o corpo fez em cada nota (o tipo, o lado pedido,
  o valor no instante do toque) e, no começo, quais sensores o controle tem.

## Armadilhas

- **A seta aponta pelo lado pedido**, e o `pedido` é para onde o jogador
  inclina (não o lado do empurrão): rolagem −1 é "incline para a esquerda".
  Confira na foto com o robô que a seta e o controle simulado concordam.
- **O cruzamento:** o toque é a condição **ficar** verdadeira; quem já está
  inclinado para o lado certo quando a janela abre é julgado ali (adiantado).
- **O pino é de todos, na mesma batida:** a nota do P1 que cairia ali some
  (o `_proxima` escolhe o pino). O registro tem uma `nota` por lugar no pino.
- **Na lava, nada de nota:** o `jogar` pula o `_nota` enquanto `caiu_b >= 0`.
- **O `em_pe` em segundos de música:** `t_ant` anda também quando o lugar
  está sem controle, senão ele ganha o tempo fora de volta.
- **A caverna é cópia literal** de `viga.gd` (o shader inclusive): a lava
  não muda de cara.
- **As fotos:** `godot/testes/captura_jogo.gd` tem os momentos de `"viga"`
  lendo `e.trecho`; troque (Provas).
- **A Prova de Fogo e o id:** `prova_do_jogo.gd:356` e `:360` comparam
  `jogo.sala.id` com `"viga"`; o id agora é `S02_J06` (Provas).

## Pronto quando

A Viga joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta não derruba ninguém na lava; a
primeira volta pede rolagem, arfagem, volante e o pino; os vereditos
`giroscopio` e `acelerometro` passam na prova limpa, e `giro-invertido` e
`acel-escala` continuam pegos no gauntlet; o fim tem sempre vencedor;
`godot/scripts/salas/viga.gd` não existe mais; `bash tests/prova_do_jogo.sh`
passa; e `bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

**`godot/testes/prova_do_jogo.gd`:**

1. A Viga joga pelo `_joga_o_minigame("S02_J06", 130.0, ...)` da H08, que
   espera a fase `fim` pelo relógio de parede (80 s de música, o aviso e o
   fechamento); as esperas de `_termina_a_sala()` e da prova de poucos já
   são as da H08.
2. `_prova_de_fogo()`: as duas comparações com `"viga"` (linhas 356 e 360
   de hoje) passam a `_e_a_sala(jogo.sala, "viga")` e `_e_a_sala(viga, "viga")`.
3. Em `_prova_do_relatorio()`, no laço da linha do tempo:

   ```gdscript
   	var viga := [0, 0, 0, 0]
   	var pinos := [0, 0, 0, 0]
   	# (dentro do laço)
   			if ev.get("tipo", "") == "toque" and ev.get("slot", "") == "S02_J06":
   				viga[int(ev.get("lugar", 0))] += 1
   			if ev.get("tipo", "") == "entrada" and ev.get("o", "") == "pino":
   				pinos[int(ev.get("jogador", 1)) - 1] += 1
   	# (depois do laço)
   	for l in 4:
   		_esperar(viga[l] >= 6, "S02_J06 P%d: a primeira frase julgada (%d notas)" % [l + 1, viga[l]])
   		_esperar(pinos[l] >= 1, "S02_J06 P%d: cravou o pino" % (l + 1))
   ```

**`godot/testes/captura_jogo.gd`:** os momentos de `"viga"` passam a:

```gdscript
		"viga": [
			["viga_rolagem", fase.call("jogo", 6.0)],
			["viga_arfagem", p1.call(func(_sala, e) -> bool: return e.tipo == "arfagem" and float(e.b) - Ritmo.batida() < 0.5)],
			["viga_pino", p1.call(func(_sala, e) -> bool: return e.tipo == "pino" and float(e.b) - Ritmo.batida() < 0.3)],
		],
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `scripts/gauntlet.sh` (o `giro-invertido` e o
`acel-escala` têm de sair pegos) e `bash tests/prova_de_poucos.sh`; depois
`./run-local.sh -- --sala=viga` com controles de verdade: a seta chega
antes do empurrão, o corpo inclina de verdade, o volante e a arfagem são
claros, o pino de todos juntos é um momento, o rangido avisa, e a queda na
lava faz rir.

## Ao terminar

- `godot/scripts/minigames/catalogo.gd`: tire `"viga"` de `SALAS_ANTIGAS`;
  ponha `"S02_J06": preload("res://scripts/minigames/s02/a_viga.gd")` em
  `MINIGAMES` e `"S02_J06"` na lista `minigames` da S02 (o apelido `viga` e o
  nome velho `giro` passam a abrir o S02_J06).
- `git rm godot/scripts/salas/viga.gd godot/scripts/salas/viga.gd.uid`.
- `godot/scripts/traducoes.gd`: `"Equilibre!": "Balance!"`, `"Incline!": "Tilt!"`
  (o título `"A Viga"` já existe); em `EN_PADROES`,
  `["^Em pé: (\\d+) s$", "Standing: $1 s"]`.
- Importe; `a_viga.gd.uid` e `secao.gd.uid` no commit.
- No [quadro](README.md): as linhas J1 a J5 abaixo da linha **J** (se ainda
  não existem), e a J1 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: A Viga no tempo da música — inclinar contra o empurrão, e a caverna da seção`
