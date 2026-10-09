# J1 — A Viga

**Sprint:** J · **Slot:** S02_J06 · **Tamanho:** G · **Depende de:** H04, H08, F09, F03, F05, H07, G05, G12, G14

## Por quê

Equilibrar é inclinar o controle contra o empurrão que a viga dá na nota e
cravar o pino dos quatro com uma pancada no ar: o giroscópio nos três eixos e
o acelerômetro julgados no tempo, os vereditos da bancada saindo daqui, e o
primeiro grito da seção.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [As decisões comuns dos minigames, no 13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08) (a fila de notas, `anotar`, `andamento`, `tempo_que_resta`)
- [A diversão d'A Viga](../diversao/J-a-viga.md#j1--a-viga) (o grito, o rastro e a régua)

## Arquivos que mudam

| arquivo | o que muda | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s02/secao.gd` | **novo**: a caverna cobalto, a leitura do corpo, a fila de pulsos, o batimento, o vento, a linha `momento`, o gancho do cavaleiro | sim: a J1 cria, J2 a J5 usam |
| `godot/scripts/minigames/s02/a_viga.gd` | **novo**: o minigame | não |
| `godot/scripts/salas/viga.gd` e `viga.gd.uid` | **saem** (`git rm`) | não |
| `godot/scripts/minigames/catalogo.gd` | o slot `S02_J06` | sim: as cinco |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO` | sim: toda ficha que grava `momento` |
| `docs/jogo/13-arquitetura.md` | a linha `momento` na tabela dos eventos do jogo | sim: toda ficha que grava `momento` |
| `godot/testes/minigame_de_tempo.gd` | uma linha `momento` no `iniciar_jogo()` (a prova da H08 conta os tipos) | sim: toda ficha que grava `momento` |
| `godot/scripts/traducoes.gd` | o verbo, o microjogo e o status | sim: as cinco |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_viga()`, `_linhas_do_minigame()`, `_notas_por_terco()`, a Prova de Fogo e o relatório | sim: as cinco |
| `godot/testes/captura_jogo.gd` | os três momentos de `"viga"` | sim: as cinco |

Se `"momento"` já estiver em `TIPOS_DO_JOGO` quando esta ficha começar
(`grep -n '"momento"' godot/scripts/minigames/minigame.gd`), outra ficha já
fez as três linhas de todos: pule-as.

### O estado de hoje

`godot/scripts/salas/viga.gd` (694 linhas, `class_name SalaViga`) é uma sala
antiga (`Catalogo.SALAS_ANTIGAS["viga"]`): três trechos em sequência (a
travessia pela rolagem, os sinos pela mira, a pedra pela martelada), por
`dt`, sem música. A caverna (`_cenario()` e `_shader_lava()`, linhas 121 a
180) vira `SECAO.montar` com a luz cobalto.

| hoje | depois |
| --- | --- |
| travessia, sinos, pedra, um de cada vez | uma plataforma de vigas sobre a lava que balança na nota: a primeira frase pede rolagem, arfagem, rolagem e volante; o pino de todos abre cada frase seguinte |
| vento contínuo, régua em cima do boneco | o empurrão chega na batida; a seta na cor do dono diz para onde inclinar |
| cair e voltar à bandeirola | escorregar um passo a cada erro; no quarto, a lava, e volta em 8 tempos |
| pontos por trecho | o tempo em pé |
| a lava `#ff6a3d` com emissão até 3,3 e o néon laranja | a lava `TUNGSTENIO` sobre `OXIDO` com emissão até 1,0; o preenchimento cobalto `#1f346a`; o néon `VIOLETA` |
| `_robo` por `rng` | o robô pelo relógio da música |

### Ao terminar

1. `godot/scripts/minigames/catalogo.gd`: tire `"viga"` de `SALAS_ANTIGAS`;
   ponha `"S02_J06": preload("res://scripts/minigames/s02/a_viga.gd")` em
   `MINIGAMES` e `"S02_J06"` em primeiro na lista `minigames` da S02 (o
   apelido `viga` e o nome velho `giro` abrem o S02_J06).
2. `git rm godot/scripts/salas/viga.gd godot/scripts/salas/viga.gd.uid`.
3. `godot/scripts/minigames/minigame.gd`:
   `const TIPOS_DO_JOGO := ["entrada", "jogo", "pista", "troca", "voz", "estacao", "momento"]`.
4. `docs/jogo/13-arquitetura.md`, na tabela **Os eventos do jogo**, depois de
   `estacao`: `| `momento` | o momento de grito do minigame (a régua da diversão): `nome`, `lugar` (−1: de todos), `t_musica`, `x_tela`, `altura_tela` (0 a 1; −1 sem câmera) e os campos do momento |`.
5. `godot/testes/minigame_de_tempo.gd`, no `iniciar_jogo()`, depois da linha
   `anotar("entrada", ...)`: `anotar("momento", -1, {"nome": "prova", "lugar": -1, "t_musica": 0.0})`;
   e em `prova_do_jogo.gd` a mensagem `"registro: os seis eventos do jogo"`
   vira `"registro: os sete eventos do jogo"`.
6. `godot/scripts/traducoes.gd`: `"Equilibre!": "Balance!"`,
   `"Incline!": "Tilt!"` (o título `"A Viga"` já existe); em `EN_PADROES`,
   `["^Em pé: (\\d+) s$", "Standing: $1 s"]`.
7. `"$GODOT" --headless --path godot --import --quit`; `a_viga.gd.uid` e
   `secao.gd.uid` entram no commit.
8. O quadro sai do cabeçalho desta ficha: nada a editar nele.
9. Commit (sem trailer): `feat(viga): A Viga no tempo da música, o pino dos quatro e a caverna cobalto da seção`.

## Como se joga

- **A faixa:** `MUS_S02_J06`. Até a H05, a sintetizada da seção a 96 BPM
  (0,625 s por tempo); com a gerada, `mus_s02_j06` a 115 BPM.
- **A plataforma:** cada um de pé no meio de uma plataforma de vigas, num
  pilar sobre a lava. A nota do lugar cai no hoqueto em colcheias
  (`2k + 0,5·l`); na nota, a plataforma leva um empurrão e o jogador inclina
  **contra**. A seta sobre o boneco aparece 1,5 tempo antes e aponta para
  onde inclinar. Os lados se alternam a cada nota.
- **A frase (16 tempos, 4 compassos):** o compasso `c = floor((b − 4) / 4)`
  pede: `c % 4 == 0` rolagem, `1` arfagem, `2` rolagem, `3` volante. **O
  volante só na primeira frase** (batidas 4 a 19, a bancada); da segunda em
  diante, o compasso 3 também é rolagem.
- **O pino dos quatro:** a batida `4 + 16f` (f ≥ 1: 20, 36, 52…) é uma nota
  de todos: uma pancada para baixo no ar (o acelerômetro passa de 1,8 g vindo
  de menos de 1,3 g). O pino aparece parado 2,2 m acima de cada viga 2 batidas
  antes, e o cavaleiro levanta o martelo nessas 2 batidas. A nota do P1 que
  cairia ali não existe.
- **O julgamento, no cruzamento:** a janela abre meio tempo antes da nota; o
  toque é o quadro em que a condição fica verdadeira: rolagem ou arfagem de
  pelo menos 0,25 rad para o lado pedido, volante de pelo menos 1,2 rad/s, a
  pancada. Nada até `FOLGA_PERDIDA` (0,140 s) depois: nota perdida. A nota é
  perigo físico: `julgar_toque(l, alvo, n, true)`.
- **O escorregão:** o erro escorrega o cavaleiro um passo (0,3 m × o gancho
  `empurrao`) para o lado do empurrão; PERFEITO e ÓTIMO o trazem um passo de
  volta; BOM não mexe. No quarto passo ele cai na lava (2 tempos caindo) e
  volta ao meio 8 tempos depois. As notas enquanto ele está fora não contam.
- **O erro no pino** não escorrega: o cavaleiro salta 0,5 m, cai sentado e
  levanta em 1 tempo × o gancho `levantar`.
- **Os pontos** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`; o pino vale
  2×. Nas últimas 16 batidas, a nota vale 2× e o pino 4×.

### A curva

Os terços de 80 s: 27 s e 53 s (`andamento()` 1/3 e 2/3).

| trecho | notas | o mundo |
| --- | --- | --- |
| 0 a 27 s | uma a cada 2 tempos (`2k + 0,5·l`) | o primeiro pino na batida 20 (12,5 s a 96 BPM; 10,4 s a 115) |
| 27 a 53 s, a viga torce | uma por tempo (`k + 0,25·l`) | a lava sobe de 0,6 a 1,0 de emissão em 2 batidas; a câmera recua 10 % em 2 batidas |
| 53 s ao fim, a reta | uma a cada 2 tempos | a viga balança sozinha 0,11 rad (meio passo) no tempo 1 de cada compasso, lado alternado, e volta em 1 batida; o líder (maior tempo em pé) tem a viga a 90 % da largura |
| as últimas 16 batidas | uma a cada 2 tempos | a nota vale 2× e o pino 4×; a linha `momento` `reta` |

`Ritmo.simples[l]`: uma a cada 4 tempos (o kit dobra o passo).

### A ficha de dados

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
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "aviso", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Incline!", "segundos": 6.0},
	# o que a bancada mede (o veredito é das medidas do núcleo)
	"features": ["giroscopio", "acelerometro"],
	"gesto": "lados",
}
```

### O fim e o vencedor

O kit fecha aos 80 s de música (`"fim": "tempo"`). `vencedor()`: o maior
tempo em pé (segundos de música fora da lava, sem o treino); empate pelo
menor número de quedas, depois pelos pontos, depois pelo lugar.

### Com menos de quatro

Nada muda; o batimento do pino pede todos os presentes, de 2 a 4 (com 1, o
pino é só o golpe). **O controle que cai:** a plataforma dele para, o tempo
em pé não conta, e ao voltar a nota é a próxima dele que ainda não passou.
**Sem giroscópio:** a rolagem e a arfagem vêm da gravidade e o volante do
analógico direito; **sem nada**, do analógico esquerdo; a linha `troca` diz
qual (`SECAO.anotar_troca`).

### Os ganchos

`godot/scripts/minigames/s02/a_viga.gd`:

```gdscript
extends Minigame
## A Viga (S02_J06), o primeiro d'A Viga. Cada um de pé numa plataforma de
## vigas sobre a lava. Na nota do lugar (o hoqueto em colcheias) a plataforma
## leva um empurrão e ele inclina contra: a primeira frase pede rolagem,
## arfagem, rolagem e volante; depois, rolagem, arfagem, rolagem, rolagem. O
## pino de todos abre cada frase seguinte (uma pancada no ar). No meio, a viga
## torce: uma nota por tempo.
##
## A falha: escorrega um passo; no quarto, cai na lava e volta em 8 tempos. No
## pino, salta 0,5 m e cai sentado.
## O vencedor: mais tempo em pé.
## O alto-falante do dono: o clique no acerto, a nota no perfeito (o kit).
## O registro mede: o pico de giro nos três eixos, a gravidade parada, a
## inclinação pela gravidade e a martelada (as medidas do núcleo: os
## vereditos da bancada); o ângulo pedido contra o feito (a linha `entrada`);
## o atraso (o kit); o pino de todos e a reta (a linha `momento`).
## O robô: inclina o controle simulado até 0,35 rad na nota (ou 200 ms
## atrasado), gira o volante a 3 rad/s, sacode a 1,8 g no pino.
## Com menos de quatro: nada muda.
## A régua: "Equilibre!" e o giroscópio no aviso bastam; sem a tela, o lado
## que pende vibra e o metal range na mão; nada pergunta pelo controle.

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
const PULO := 0.5  ## m: quem erra o pino sai do chão
const PENDE := 0.22  ## rad: o empurrão
const BALANCO := 0.11  ## rad: a viga que balança sozinha na reta (meio passo)
const ESTREITA := 0.9  ## a largura da viga do líder na reta
const CAMERA := Vector3(0, 10.6, 9.2)
const OLHAR := Vector3(0, 0.6, 0.8)

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var _b_ant := 0.0
var _reta := false
var _lider := -1


func montar() -> void:
	SECAO.limpar()
	camera_pos = CAMERA
	camera_olhar = OLHAR
	SECAO.montar(self)
	var madeira := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)
	var ferro := Kit.material(Tema.GRAFITE, 0.0, 0.5)
	for p in jogadores:
		var l: int = p.lugar
		SECAO.pilar(self, RAIAS[l], Z_VIGA)
		var viga := Node3D.new()
		viga.position = Vector3(RAIAS[l], 0.1, Z_VIGA)
		add_child(viga)
		# o tabuleiro: a ponte do Castle Kit no tamanho das três vigas de hoje
		SECAO.peca_no_tamanho(viga, "castle-kit/bridge-straight", Vector3.ZERO, Vector3(2.4, 0.2, 2.3), madeira)
		for x in [-0.8, 0.8]:
			Kit.caixa(viga, Vector3(0.1, 0.24, 2.3), Vector3(x, 0, 0), ferro)
		var seta := Node3D.new()
		add_child(seta)
		var seta_mat := Kit.chapado(Tema.JOGADOR[l], true)
		Kit.caixa(seta, Vector3(0.08, 0.5, 0.08), Vector3.ZERO, seta_mat)
		for lado in [-1.0, 1.0]:
			var ponta := Kit.caixa(seta, Vector3(0.3, 0.08, 0.08), Vector3(lado * 0.09, 0.2, 0), seta_mat)
			ponta.rotation.z = lado * PI * 0.25
		seta.visible = false
		var pino := SECAO.pino(self, l)
		pino.visible = false
		var dono := OmniLight3D.new()  # a luz de dono (07): 0,9, 3,4 m
		dono.light_color = Tema.JOGADOR[l]
		dono.light_energy = 0.9
		dono.omni_range = 3.4
		dono.position = Vector3(RAIAS[l], 2.2, Z_VIGA)
		add_child(dono)
		martelo_na_mao(p)  # o martelo da forja na mão direita; o item fica guardado
		p.preso = true
		p.position = Vector3(RAIAS[l], 0.2, Z_VIGA)
		p.rotation.y = PI
		j[l] = {"n": 0, "b": -1.0, "tipo": "rolagem", "pedido": 0, "lado": 1, "antes": false, "aberta": false,
			"g_armado": true, "perigo": 0, "dir": Vector2.RIGHT, "caiu_b": -1.0, "quedas": 0, "em_pe": 0.0,
			"t_ant": 0.0, "rangeu": -1, "fora": false, "viga": viga, "seta": seta, "pino": pino,
			"pinos": 0, "cravou_b": -1.0, "t_pino": 0.0, "julg_pino": 0, "sentado_b": -1.0,
			"robo_n": -1, "robo_mira": 0.0, "robo_bateu": false}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func iniciar_jogo() -> void:
	_b_ant = Ritmo.batida()
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
	if no_pico() and not Ritmo.simples[l]:
		passo = 1.0
		desloc = 0.25 * l
	var s := proxima_batida(l, desde, passo, desloc)  # o kit dobra o passo na partitura simples
	var pino := _pino_depois(desde)
	if pino <= s:
		e.b = pino
		e.tipo = "pino"
		e.pedido = 0
		Forja.med_pedir(l, "martelada")
	else:
		e.b = s
		var c := int(floor((s - BATIDA_DA_PRIMEIRA_NOTA) / 4.0))
		e.tipo = TIPOS[c % 4]
		if str(e.tipo) == "guinada" and s >= BATIDA_DA_PRIMEIRA_NOTA + FRASE:
			e.tipo = "rolagem"  # o volante só na primeira frase
		e.lado = -int(e.lado)
		e.pedido = int(e.lado)
		if str(e.tipo) != "rolagem":
			Forja.med_pedir(l, "mira")
	e.aberta = false
	e.antes = false
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b)))


## A batida do próximo pino depois de `desde` (20, 36, 52…).
func _pino_depois(desde: float) -> float:
	var f := maxf(1.0, ceilf((desde + 0.001 - BATIDA_DA_PRIMEIRA_NOTA) / FRASE))
	return BATIDA_DA_PRIMEIRA_NOTA + FRASE * f


func _ultimas_16() -> bool:
	return tempo_que_resta() <= 16.0 * 60.0 / Ritmo.bpm


func jogar(_dt: float) -> void:
	SECAO.pulsos()  # a fila do batimento e o hit-stop
	var agora := Ritmo.t_musica()
	var b := Ritmo.batida()
	var pico := SECAO.pico_suave(self)
	camera_pos = OLHAR + (CAMERA - OLHAR) * (1.0 + 0.1 * pico)
	SECAO.lava(self, 0.6 + 0.4 * pico)
	var pb := _pino_depois(_b_ant)
	if b >= pb - 2.0 and _b_ant < pb - 2.0:
		_pino_aparece()
	if b >= pb and _b_ant < pb:
		_pino_na_batida(pb)
	if floor(b) > floor(_b_ant):
		_tempo(int(floor(b)))
	_b_ant = b
	if not _reta and _ultimas_16():
		_comeca_a_reta()
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


## A cada tempo: a háptica do lado que pende, o "pulso" (`mod_pulso`, 120 Hz), ganho
## de 0 a 0,6 com a rolagem do controle de 0 a 0,25 rad; cala do meio tempo
## antes do pino até o pino (o batimento tem a vez).
func _tempo(b: int) -> void:
	var pb := _pino_depois(float(b) - 1.0)
	for l in presentes():
		if not conectado(l) or float(j[l].caiu_b) >= 0.0 or (str(j[l].tipo) == "pino" and float(b) >= pb - 1.0):
			continue
		var rol := SECAO.rolagem(l)
		var g := 0.6 * clampf(absf(rol) / LIMIAR, 0.0, 1.0)
		if g >= 0.05:
			Forja.som_haptica(l, "pulso" if rol < 0.0 else "", "" if rol < 0.0 else "pulso", g)
			anotar("pista", l, {"canal": "haptica", "o": "pende", "ganho": snappedf(g, 0.01)})


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
	var tempo := 60.0 / Ritmo.bpm
	var meio_tempo := 0.5 * tempo
	var sim := _condicao(l, e)
	if agora < alvo - meio_tempo:
		e.antes = sim
		# o metal range 1 tempo antes (mais o Faro), perto da ponta; e o aviso, a um passo
		var aviso := alvo - tempo - SECAO.pista_s(l)
		if int(e.rangeu) != int(e.n) and agora >= aviso and int(e.perigo) >= 2 and str(e.tipo) != "pino":
			e.rangeu = int(e.n)
			Forja.textura(l, "metal", 0.6)
			anotar("pista", l, {"canal": "haptica", "o": "rangido", "perigo": int(e.perigo)})
			if int(e.perigo) >= QUEDA - 1:
				Forja.sentir(l, "aviso", int(30000.0 / Ritmo.bpm))
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		if str(e.tipo) == "pino":
			e.g_armado = false
			e.t_pino = agora
			if Forja.capacidade(l, "acel"):
				Forja.med_martelada(l)
		anotar("entrada", l, {"o": str(e.tipo), "pedido": int(e.pedido),
			"valor": snappedf(_valor(l, e), 0.01), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n), true)
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var pino := str(e.tipo) == "pino"
	var vezes := 1
	if pino:
		vezes = 4 if _ultimas_16() else 2
	elif _ultimas_16():
		vezes = 2
	marcar(l, int(PONTOS[julgamento]) * vezes)
	if julgamento >= Ritmo.OTIMO and not treinando and not pino:
		_perigo(l, int(e.perigo) - 1)
	if pino:
		e.cravou_b = float(e.b)
		e.julg_pino = julgamento
		if Ritmo.batida() >= float(e.b):
			_cravar(l)  # depois da batida: o impacto agora
			Forja.sentir(l, "golpe")
		# antes da batida: o impacto espera a batida (_pino_na_batida)
	elif str(e.tipo) == "rolagem":
		Som.tocar("vento", (e.viga as Node3D).global_position + Vector3(-3.0 * float(e.pedido), 1.2, 0), -14.0)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.4)
	_proxima(l, float(e.b))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	var p := jogador(l)
	if str(e.tipo) == "pino":
		_pulo(l)  # o pino não escorrega: a viga pula
		_proxima(l, float(e.b))
		return
	if str(e.tipo) == "arfagem":
		e.dir = Vector2(0, -float(e.pedido))
	else:
		e.dir = Vector2(-float(e.pedido), 0)
	if not treinando:
		_perigo(l, int(e.perigo) + 1)
	if int(e.perigo) >= QUEDA:
		_cair(l)
	elif p:
		p.gesto("emote-no", 60.0 / Ritmo.bpm)  # 1 batida
	_proxima(l, float(e.b))


## O perigo (os passos até a ponta) muda: o R2 endurece com ele.
func _perigo(l: int, novo: int) -> void:
	var e: Dictionary = j[l]
	e.perigo = clampi(novo, 0, QUEDA)
	if int(e.perigo) == 0:
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	else:
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, mini(2 + 2 * int(e.perigo), 8))


## 2 batidas antes do pino: o pino aparece parado no alto, e o cavaleiro
## levanta o martelo em 2 batidas (o golpe cai na batida do pino).
func _pino_aparece() -> void:
	for l in presentes():
		var e: Dictionary = j[l]
		if float(e.caiu_b) >= 0.0:
			continue
		(e.pino as Node3D).visible = true
		(e.pino as Node3D).position = (e.viga as Node3D).position + Vector3(0, 2.2, 0)
		var p := jogador(l)
		if p:
			p.gesto("attack-melee-right", 2.0 * 60.0 / Ritmo.bpm)
			p.anim.speed_scale = 0.417 * Ritmo.bpm / (60.0 * 2.0)


## A batida do pino: o impacto de quem já cravou cai aqui. Todos os presentes
## na viga cravaram, numa janela de 400 ms: o batimento e o estrondo. A linha
## `momento` `pino` sai sempre, uma por pino.
func _pino_na_batida(pb: float) -> void:
	var na_viga := []
	var cravaram := []
	var tempos := []
	var perfeitos := 0
	for l in presentes():
		if float(j[l].caiu_b) >= 0.0 or not conectado(l):
			continue
		na_viga.append(l)
		if float(j[l].cravou_b) == pb:
			cravaram.append(l)
			tempos.append(float(j[l].t_pino))
			if int(j[l].julg_pino) == Ritmo.PERFEITO:
				perfeitos += 1
	var juntos := na_viga.size() >= 2 and cravaram.size() == na_viga.size() and SECAO.juntos(tempos)
	var nos := []
	for l in cravaram:
		_cravar(l)
		if juntos:
			SECAO.batimento(l)
		else:
			Forja.sentir(l, "golpe")
		nos.append(j[l].viga)
		if jogador(l):
			nos.append(jogador(l))
	if juntos:
		tremer(Sala.TREMOR_EXPLOSAO)  # estrondo: 2 batidas, 0,05
		SECAO.parar(nos, 3)
	elif not cravaram.is_empty():
		tremer(Sala.TREMOR_GOLPE)
		SECAO.parar(nos, 2)
	SECAO.momento(self, "pino", -1, Vector3(0, 0.1, Z_VIGA), 1.6,
		{"batida": pb, "cravaram": cravaram.size(), "na_viga": na_viga.size(), "juntos": juntos, "perfeitos": perfeitos})


## O pino entra: fica na viga até o fim (o rastro), um a mais por frase.
func _cravar(l: int) -> void:
	var e: Dictionary = j[l]
	var viga: Node3D = e.viga
	(e.pino as Node3D).visible = false
	var i := int(e.pinos)
	e.pinos = i + 1
	var fixo := SECAO.pino(viga, l)
	fixo.position = Vector3(-1.05 + 0.3 * (i % 8), 0.25, 1.0)
	var onde := viga.global_position + Vector3(0, 0.3, 0)
	Som.tocar("martelo", onde, 0.0)
	Efeitos.faiscas(self, onde, Tema.JOGADOR[l], 12, 1.0)


## Errou o pino: sai do chão 0,5 m e cai sentado; levanta em 1 tempo × levantar.
func _pulo(l: int) -> void:
	var e: Dictionary = j[l]
	(e.pino as Node3D).visible = false
	e.sentado_b = Ritmo.batida()
	var p := jogador(l)
	if p:
		var tempo := 60.0 / Ritmo.bpm
		p.gesto("sit", (0.5 + SECAO.levantar(l, 1.0)) * tempo)
		SECAO.parar([p], 2)
	tremer(Sala.TREMOR_GOLPE)


func _cair(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = Ritmo.batida()
	e.quedas = int(e.quedas) + 1
	Forja.sentir(l, "golpe")
	var p := jogador(l)
	if p:
		p.gesto("fall", 2.0 * 60.0 / Ritmo.bpm)
		Som.tocar("falha", p.global_position, -4.0)
		Efeitos.faiscas(self, Vector3(p.global_position.x, -1.3, p.global_position.z), Tema.TUNGSTENIO, 30, 0.9)


func _voltar(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = -1.0
	_perigo(l, 0)
	var p := jogador(l)
	if p:
		p.gesto("jump", 0.5)
		Efeitos.anel(self, (e.viga as Node3D).global_position + Vector3(0, 1.0, 0), Tema.JOGADOR[l], 0.6)
	_proxima(l, Ritmo.batida())


## As últimas 16 batidas: a linha `momento` `reta` com a ordem do mundo (o
## tempo em pé) e o líder de viga estreita.
func _comeca_a_reta() -> void:
	_reta = true
	var ordem := vencedor()
	_lider = int(ordem[0]) if not ordem.is_empty() else -1
	var onde := Vector3(RAIAS[_lider], 0.1, Z_VIGA) if _lider >= 0 else Vector3(0, 0.1, Z_VIGA)
	SECAO.momento(self, "reta", -1, onde, 1.6, {"ordem": ordem, "objeto": "viga_estreita", "lider": _lider})


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var viga: Node3D = e.viga
	var agora_b := Ritmo.batida()
	var falta := float(e.b) - agora_b
	var empurrao := SECAO.gancho(l, "empurrao")
	# o empurrão: a plataforma pende para o lado dele no último tempo antes da nota
	var pende := PENDE * empurrao * clampf(1.0 - absf(falta), 0.0, 1.0) if fase == "jogo" and float(e.caiu_b) < 0.0 else 0.0
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
	if andamento() >= 2.0 / 3.0 and fase == "jogo":
		# a reta: a viga balança sozinha no tempo 1 de cada compasso
		var c := floor((agora_b - BATIDA_DA_PRIMEIRA_NOTA) / 4.0)
		var dentro := agora_b - (BATIDA_DA_PRIMEIRA_NOTA + 4.0 * c)
		viga.rotation.z += BALANCO * (1.0 if int(c) % 2 == 0 else -1.0) * clampf(1.0 - dentro, 0.0, 1.0)
	viga.scale.x = lerpf(viga.scale.x, ESTREITA if (_reta and l == _lider) else 1.0, 0.1)
	var p := jogador(l)
	var seta: Node3D = e.seta
	if p == null:
		return
	var deslize: Vector2 = e.dir * PASSO * empurrao * int(e.perigo)
	var alvo := viga.global_position + Vector3(deslize.x, 0.1, deslize.y)
	if float(e.caiu_b) >= 0.0:
		var s := clampf((agora_b - float(e.caiu_b)) / 2.0, 0.0, 1.0)
		alvo.y -= 3.2 * s * s
	if float(e.sentado_b) >= 0.0:
		var t := agora_b - float(e.sentado_b)
		alvo.y += PULO * sin(PI * clampf(t / 0.5, 0.0, 1.0))  # o pulo dura meio tempo
		if t >= 0.5 + SECAO.levantar(l, 1.0):
			e.sentado_b = -1.0
	var volta := 0.2 * SECAO.gancho(l, "velocidade")
	p.position = p.position.lerp(alvo, volta) if float(e.caiu_b) < 0.0 else alvo
	p.animar("idle", 1.333 * Ritmo.bpm / (60.0 * 2.0))  # o idle em 2 batidas
	var antes := 1.5 + SECAO.pista_s(l) * Ritmo.bpm / 60.0
	seta.visible = fase == "jogo" and not acabou[l] and float(e.caiu_b) < 0.0 and falta <= antes and falta > -0.3 and str(e.tipo) != "pino"
	seta.position = p.position + Vector3(0, 2.4, 0)
	seta.rotation = Vector3.ZERO
	match str(e.tipo):
		"rolagem", "guinada":
			seta.rotation.z = PI * 0.5 * float(e.pedido)
			if str(e.tipo) == "guinada":
				seta.rotation.y = fmod(agora_b, 1.0) * TAU
		"arfagem":
			seta.rotation.x = PI * 0.5 * float(e.pedido)
	var pino: Node3D = e.pino
	if pino.visible and str(e.tipo) == "pino":
		# o pino desce do alto na última batida antes do toque
		pino.position = viga.position + Vector3(0, 0.3 + 1.9 * clampf(falta, 0.0, 1.0), 0)


## Quem está na lava está fora da rodada: pode mandar adesivo (arte/09).
func fora_da_rodada(l: int) -> bool:
	return j.has(l) and float(j[l].caiu_b) >= 0.0


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

### O robô

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
					Forja.robo_sacudir(l, 1.8, 0.1)
					e.robo_bateu = true
	# entre as notas, volta ao nível e fica parado (o acelerômetro mede 1 g parado)
	Forja.robo_girar(l, SECAO.giro_para(l, rol, arf, gui), 0.06)
```

O robô `bom` crava os quatro pinos com 10 ms de folga entre eles: o batimento
sai. Ele não tenta o pulo de propósito; o `ruim` erra 1 em 3 e cai na lava.

### O registro

- As medidas do núcleo, como hoje: o pico de giro em cada eixo, a taxa
  declarada contra a medida, o sinal do giro contra a gravidade, 1 g parado,
  a inclinação pela gravidade e as marteladas (`med_pedir("mira")` no
  volante e na arfagem, `med_pedir("martelada")` e `med_martelada` no pino):
  os vereditos `giroscopio` e `acelerometro` da bancada.
- O kit: `nota` e `toque` (o atraso entre o pulso e o movimento).
- `entrada`: `sensores` no começo; em cada nota, `o` (o tipo), `pedido`,
  `valor` (o ângulo, o giro ou os g no instante do toque), `n`.
- `pista`: `haptica` `pende` a cada tempo (o ganho) e `haptica` `rangido`.
- `momento`: `pino` (uma por pino, `lugar` −1, `batida`, `cravaram`,
  `na_viga`, `juntos`, `perfeitos`) e `reta` (`ordem`, `objeto`, `lider`).

### Armadilhas

- **A seta aponta pelo lado pedido:** `pedido` −1 é «incline para a
  esquerda». Na foto com o robô, a seta e o controle simulado concordam.
- **O cruzamento:** quem já está inclinado para o lado certo quando a janela
  abre é julgado ali (adiantado).
- **O pino é de todos, na mesma batida:** a nota do P1 que cairia ali some.
  O impacto de quem cravou antes da batida espera a batida
  (`_pino_na_batida`); quem crava depois tem o impacto no toque.
- **O batimento cala o resto:** do meio tempo antes do pino até ele, nem a
  háptica do lado que pende nem o rangido tocam (`_tempo` e `_nota`).
- **O `em_pe` em segundos de música:** `t_ant` anda também quando o lugar
  está sem controle.
- **O hit-stop desliga o processamento** do boneco e da viga por 2 ou 3
  quadros; `SECAO.limpar()` no `montar` devolve tudo se o minigame fechar no
  meio.
- **A Prova de Fogo e o id:** `prova_do_jogo.gd` compara `jogo.sala.id` com
  `"viga"` em `_prova_de_fogo()` (hoje nas linhas 423 e 427); o id agora é
  `S02_J06` (Provas).

## A cena

### O secao.gd

```gdscript
extends RefCounted
## A seção A Viga (S02): o que os cinco minigames têm em comum. A caverna da
## lava na luz cobalto, a leitura do corpo com as saídas silenciosas (sem
## giroscópio, a gravidade; sem nada, o analógico) e a linha `troca`, a fila de
## pulsos pelo relógio da música (o batimento, o vento), o hit-stop, a linha
## `momento` com a posição na tela, o gancho do cavaleiro, e a conta do robô.
## Sem class_name: const SECAO := preload("res://scripts/minigames/s02/secao.gd").
## Aqui não se chama Forja.robo_* nem se lê Forja.robo: o robô é dos ganchos.

## A luz cobalto até a G15 (a G15 troca por Tema.luz_da_secao(1, "A")).
const NEVOA := Color("#050d26")
const PREENCHE := Color("#1f346a")
const CHAVE := Color("#e5d3c6")

static var _shader: Shader = null
static var _fila: Array = []  ## [t_musica, Callable], em ordem de tempo
static var _parados: Array = []  ## [nó, quadros que faltam]
static var batimento_em := {}  ## lugar -> t_musica do último batimento (a prova lê)
static var _cavaleiro: Script = null
static var _procurou := false


## Ao montar cada minigame: a fila e o hit-stop do anterior saem.
static func limpar() -> void:
	_fila.clear()
	for par in _parados:
		if is_instance_valid(par[0]):
			(par[0] as Node).process_mode = Node.PROCESS_MODE_INHERIT
	_parados.clear()
	batimento_em.clear()


## A luz da seção: com a G15, a dela; sem, a cobalto.
static func luz() -> Dictionary:
	var tema: Script = load("res://scripts/tema.gd")
	for m in tema.get_script_method_list():
		if str(m["name"]) == "luz_da_secao":
			return tema.call("luz_da_secao", 1, "A")
	return {"nevoa": NEVOA, "preenchimento": PREENCHE, "chave": CHAVE}


## A caverna: as plataformas de pedra nas pontas, o poço de lava no meio (de
## z = −2 a z = 3), as paredes do kit, as brasas subindo, a luz cobalto.
static func montar(sala: SalaJogo) -> void:
	var K := Kit.K
	for i in range(-5, 6):
		var x := i * K
		for z in [4.0, -3.0, -5.0]:
			Kit.peca(sala, "floor-detail" if (i + int(z)) % 5 == 0 else "floor", Vector3(x, 0, z), (absi(i) % 4) * PI * 0.5)
		Kit.peca(sala, "wall", Vector3(x, 0, -7.0))
		Kit.peca(sala, "wall-half", Vector3(x, 0, 6.0))
	for z in [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0]:
		Kit.peca(sala, "wall", Vector3(-12.0, 0, z))
		Kit.peca(sala, "wall", Vector3(12.0, 0, z))
	var pedra := Kit.material(Tema.GRAFITE, 0.0, 0.95)
	Kit.caixa(sala, Vector3(24, 3.0, 2.0), Vector3(0, -1.5, 4.0), pedra)
	Kit.caixa(sala, Vector3(24, 3.0, 4.0), Vector3(0, -1.5, -4.0), pedra)
	for lado in [-1.0, 1.0]:
		Kit.caixa(sala, Vector3(2.0, 3.0, 5.0), Vector3(lado * 12.0, -1.5, 0.5), pedra)
	var lava := MeshInstance3D.new()
	lava.name = "Lava"
	var plano := PlaneMesh.new()
	plano.size = Vector2(24, 5.0)
	lava.mesh = plano
	lava.position = Vector3(0, -1.45, 0.5)
	var sm := ShaderMaterial.new()
	sm.shader = _shader_lava()
	sm.set_shader_parameter("quente", Tema.TUNGSTENIO)
	sm.set_shader_parameter("escuro", Tema.OXIDO)
	sm.set_shader_parameter("brilho", 0.6)
	lava.material_override = sm
	sala.add_child(lava)
	for x in [-8.0, 0.0, 8.0]:
		var brilho := OmniLight3D.new()
		brilho.position = Vector3(x, -0.7, 0.5)
		brilho.light_color = Tema.TUNGSTENIO
		brilho.light_energy = 0.9
		brilho.omni_range = 7.5
		sala.add_child(brilho)
	Efeitos.brasas(sala, Vector3(0, -1.2, 0.5), Vector3(22, 0.2, 4.6), Tema.TUNGSTENIO, 70)
	sala.luzes([Vector3(-10, 2.8, -5.4), Vector3(10, 2.8, -5.4), Vector3(0, 3.4, 4.8)])
	sala.atmosfera(luz()["preenchimento"], Tema.VIOLETA, false, 30, 22.0, -7.8, 0.3)


## O brilho da lava, de 0 a 1,0 (0,6 fora do pico, 1,0 no pico).
static func lava(sala: Node, brilho: float) -> void:
	var l := sala.get_node_or_null("Lava") as MeshInstance3D
	if l:
		(l.material_override as ShaderMaterial).set_shader_parameter("brilho", clampf(brilho, 0.0, 1.0))


## Um pilar de pedra da lava até o chão (y = 0), com o tampo do Platformer.
static func pilar(sala: Node3D, x: float, z: float) -> void:
	var pedra := Kit.material(Tema.GRAFITE, 0.0, 0.95)
	Kit.caixa(sala, Vector3(0.9, 1.45, 0.9), Vector3(x, -0.875, z), pedra)
	peca_no_tamanho(sala, "platformer-kit/platform", Vector3(x, -0.08, z), Vector3(1.2, 0.16, 1.2), pedra)


## O pino de ferro com a cabeça na cor do dono (o acento, 1,6).
static func pino(pai: Node3D, l: int) -> Node3D:
	var n := Node3D.new()
	pai.add_child(n)
	Kit.cilindro(n, 0.05, 0.45, Vector3.ZERO, Kit.material(Tema.GRAFITE, 0.0, 0.5))
	Kit.cilindro(n, 0.09, 0.06, Vector3(0, 0.25, 0), Kit.material(Tema.JOGADOR[l], 1.6, 0.4))
	return n


## A peça Kenney esticada até caber em `tamanho`, centrada em `pos`; sem o
## pacote importado (G10), a caixa no material de reserva.
static func peca_no_tamanho(pai: Node3D, nome: String, pos: Vector3, tamanho: Vector3, reserva: Material) -> Node3D:
	var caminho := "res://assets/kenney/%s.glb" % nome
	if not ResourceLoader.exists(caminho):
		return Kit.caixa(pai, tamanho, pos, reserva)
	var n: Node3D = (load(caminho) as PackedScene).instantiate()
	pai.add_child(n)
	var caixa := AABB()
	var primeira := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = n.global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		caixa = a if primeira else caixa.merge(a)
		primeira = false
	if primeira:
		return n
	var esc := Vector3(tamanho.x / maxf(caixa.size.x, 0.001), tamanho.y / maxf(caixa.size.y, 0.001), tamanho.z / maxf(caixa.size.z, 0.001))
	n.scale = esc
	n.position = pos - caixa.get_center() * esc
	return n


static func _shader_lava() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type spatial;
uniform vec3 quente : source_color = vec3(1.0, 0.85, 0.66);
uniform vec3 escuro : source_color = vec3(0.23, 0.16, 0.13);
uniform float brilho = 0.6;
float onda(vec2 p, float t) {
	return sin(p.x * 1.9 + t * 1.3) * sin(p.y * 2.3 - t * 0.9)
		+ 0.6 * sin((p.x - p.y) * 1.1 + t * 0.7)
		+ 0.35 * sin(p.x * 4.1 - p.y * 3.3 + t * 2.1);
}
void fragment() {
	vec2 p = UV * vec2(24.0, 6.4) * 0.55;
	float n = clamp((onda(p, TIME) * 0.5 + 0.5) / 1.3, 0.0, 1.0);
	vec3 c = mix(escuro, quente, smoothstep(0.25, 0.85, n));
	ALBEDO = c * 0.25;
	ROUGHNESS = 0.55;
	EMISSION = c * brilho * (0.5 + 0.5 * smoothstep(0.62, 1.0, n));
}
"""
	return _shader


## 0 a 1: o pico com 2 batidas de subida e 2 de descida (a lava, a câmera).
static func pico_suave(sala: Minigame) -> float:
	if sala.duracao <= 0.0:
		return 0.0
	var a := sala.andamento()
	var b2 := 2.0 * 60.0 / Ritmo.bpm / sala.duracao
	return minf(clampf((a - 1.0 / 3.0) / b2, 0.0, 1.0), clampf((2.0 / 3.0 + b2 - a) / b2, 0.0, 1.0))


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
## controle da inclinação de agora à pedida. 20 por rad, até 6 rad/s: chega
## ao limiar em uns 40 ms.
static func giro_para(l: int, rol: float, arf: float, gui := 0.0) -> Vector3:
	var p := Forja.postura(l)
	return Vector3(clampf(20.0 * (arf - p.y), -6.0, 6.0), gui, clampf(20.0 * (-rol - p.x), -6.0, 6.0))


## Os sensores do lugar, uma vez por minigame, no iniciar_jogo(): a linha
## `entrada` `sensores`; sem giroscópio, a `troca` `giroscopio` → `analogico`.
static func anotar_troca(sala: Minigame, l: int) -> void:
	var giro := Forja.capacidade(l, "giro")
	var acel := Forja.capacidade(l, "acel")
	sala.anotar("entrada", l, {"o": "sensores", "giro": giro, "acel": acel})
	if not giro:
		sala.anotar("troca", l, {"de": "giroscopio", "para": "analogico", "gravidade": acel})


## Uma chamada para um instante da música (o timer de jogo não serve: com
## --fixed-fps o jogo corre mais que o relógio).
static func agendar(t: float, f: Callable) -> void:
	_fila.append([t, f])
	_fila.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))


## A cada quadro, na primeira linha do jogar(): o que venceu na fila, e os
## nós do hit-stop que voltam.
static func pulsos() -> void:
	var agora := Ritmo.t_musica()
	while not _fila.is_empty() and float(_fila[0][0]) <= agora:
		var f: Callable = _fila.pop_front()[1]
		if f.is_valid():
			f.call()
	for i in range(_parados.size() - 1, -1, -1):
		_parados[i][1] = int(_parados[i][1]) - 1
		if int(_parados[i][1]) <= 0:
			if is_instance_valid(_parados[i][0]):
				(_parados[i][0] as Node).process_mode = Node.PROCESS_MODE_INHERIT
			_parados.remove_at(i)


## O hit-stop: os nós param por `quadros` quadros (golpe 2, estrondo 3).
static func parar(nos: Array, quadros: int) -> void:
	for n in nos:
		if is_instance_valid(n):
			(n as Node).process_mode = Node.PROCESS_MODE_DISABLED
			_parados.append([n, quadros])


## Todos os toques numa janela de 400 ms (o pino dos quatro).
static func juntos(tempos: Array) -> bool:
	if tempos.size() < 2:
		return false
	var s := tempos.duplicate()
	s.sort()
	return float(s[-1]) - float(s[0]) <= 0.4


## O batimento: forte 1,0 por 120 ms, pausa de 120 ms, 0,7 por 120 ms.
static func batimento(l: int) -> void:
	batimento_em[l] = Ritmo.t_musica()
	Forja.sentir(l, "explosao", 120)
	agendar(Ritmo.t_musica() + 0.24, func() -> void: Forja.sentir(l, "erro", 120))


## O vento que corre de um lado ao outro: a háptica de um lado, e 400 ms
## depois do outro, com o mesmo ganho.
static func vento(l: int, ganho: float, da_esquerda := true) -> void:
	var a := "pulso" if da_esquerda else ""
	var b := "" if da_esquerda else "pulso"
	Forja.som_haptica(l, a, b, ganho)
	agendar(Ritmo.t_musica() + 0.4, func() -> void: Forja.som_haptica(l, b, a, ganho))


## A linha `momento` (a régua da diversão, itens 4, 8 e 10), com a posição na
## tela do objeto do grito: x_tela e altura_tela de 0 a 1; sem câmera, −1.
static func momento(sala: Minigame, nome: String, l: int, onde: Vector3, altura_m: float, extra := {}) -> void:
	var c := {"nome": nome, "lugar": l, "t_musica": snappedf(Ritmo.t_musica(), 0.001), "x_tela": -1.0, "altura_tela": -1.0}
	var cam := sala.get_viewport().get_camera_3d()
	if cam:
		var tam := sala.get_viewport().get_visible_rect().size
		var p0 := cam.unproject_position(onde)
		var p1 := cam.unproject_position(onde + Vector3(0, altura_m, 0))
		c.x_tela = snappedf(p0.x / tam.x, 0.001)
		c.altura_tela = snappedf(absf(p0.y - p1.y) / tam.y, 0.001)
	c.merge(extra)
	sala.anotar("momento", l, c)


## O gancho do cavaleiro (H04, sistemas): o fator do stat do lugar. Sem a
## classe Cavaleiro, o neutro: 1,0 (e 0 ms na pista).
static func gancho(l: int, nome: String) -> float:
	if not _procurou:
		_procurou = true
		for c in ProjectSettings.get_global_class_list():
			if str(c["class"]) == "Cavaleiro":
				_cavaleiro = load(str(c["path"]))
	if _cavaleiro == null:
		return 0.0 if nome == "pista" else 1.0
	return float(_cavaleiro.call("gancho", l, nome))


## O Faro em segundos: o aviso chega antes (−40 a +40 ms; a nota não muda).
static func pista_s(l: int) -> float:
	return gancho(l, "pista") / 1000.0


## O Fôlego: a queda de `tempos` tempos × levantar, arredondada à semicolcheia
## e nunca menor que uma.
static func levantar(l: int, tempos: float) -> float:
	return maxf(0.25, roundf(tempos * gancho(l, "levantar") * 4.0) / 4.0)
```

### Por lugar

| o quê | peça | onde (m) | cor |
| --- | --- | --- | --- |
| o pilar | `SECAO.pilar`: caixa 0,9 × 1,45 × 0,9 e o tampo `platformer-kit/platform` em 1,2 × 0,16 × 1,2 | `(RAIAS[l]; −0,875; 0,8)` | `GRAFITE` |
| a plataforma | `castle-kit/bridge-straight` em 2,4 × 0,2 × 2,3 e duas cintas `Kit.caixa(0,1; 0,24; 2,3)` em x ±0,8 | `(RAIAS[l]; 0,1; 0,8)`; gira pelo empurrão | `OXIDO_BRILHO` (a madeira) e `GRAFITE` (o ferro) |
| a seta | `Kit.caixa(0,08; 0,5; 0,08)` e a ponta em duas `Kit.caixa(0,3; 0,08; 0,08)` a ±45°, `Kit.chapado(..., true)` | boneco + (0; 2,4; 0) | `JOGADOR[l]`, chapada |
| o pino que cai | `SECAO.pino`: cilindro 0,05 × 0,45 e a cabeça 0,09 × 0,06 | aparece em plataforma + (0; 2,2; 0) e desce na última batida | `GRAFITE`; a cabeça `JOGADOR[l]` a 1,6 |
| os pinos cravados | `SECAO.pino` filho da plataforma | (−1,05 + 0,3·i; 0,25; 1,0), até 8 | idem |
| a luz de dono | `OmniLight3D` 0,9, alcance 3,4 | `(RAIAS[l]; 2,2; 0,8)` | `JOGADOR[l]` |
| o cavaleiro | o boneco de costas (`rotation.y = PI`), o martelo da forja na mão direita, `preso` | na plataforma, deslocado `passo × empurrao × perigo` | o da montagem |

Sem o Castle Kit e o Platformer Kit importados, `SECAO.peca_no_tamanho`
monta caixas nos mesmos tamanhos e cores: a prancha mostra caixas até a
G10 importar os kits, e a prova passa igual.

### A câmera

`"camera": "fixa"`, o plano de arena do cinema: 35 mm (fov 37,8°), plongée
de 50°, sem corte e sem roll. A sala põe `camera_pos = (0; 10,6; 9,2)` e
`camera_olhar = (0; 0,6; 0,8)` (13,1 m do centro, os quatro pilares de x −7,2
a 7,2 no quadro com 15 % de folga). O main usa hoje fov 40 em toda sala e
esta ficha não o muda. **No pico**, a câmera recua 10 % ao longo do mesmo
eixo em 2 batidas e volta em 2 batidas (`SECAO.pico_suave`). O tremor é o da
G05: `tremer(Sala.TREMOR_GOLPE)` no golpe, `tremer(Sala.TREMOR_EXPLOSAO)` no
estrondo.

### A luz e o brilho

A S02 é **cobalto** (`Tema.SECAO[1]`, `#2f55c4`): névoa `#050d26`,
preenchimento `#1f346a`, chave `#e5d3c6`. Até a G15, `SECAO.luz()` devolve
esses três valores e a sala usa o preenchimento em `atmosfera`; com a G15,
`SECAO.luz()` devolve `Tema.luz_da_secao(1, "A")`, e a névoa, a chave e o
pico da luz (+20 % em 1 batida, névoa ×0,8) são do ambiente da G15. A lava
fica chapada e quente contra o cobalto: `TUNGSTENIO` sobre `OXIDO`, emissão
no máximo 1,0.

| o quê | energia | dono |
| --- | --- | --- |
| a cabeça do pino | 1,6 | o lugar |
| as faíscas do cravar (12) | as de `Efeitos.faiscas` | o lugar, `JOGADOR[l]` |
| a luz sobre a plataforma | 0,9 | o lugar |
| a lava | até 1,0 (0,6 fora do pico) | o mundo, `TUNGSTENIO` |
| as brasas (70) e as três luzes da lava (0,9) | — | o mundo, `TUNGSTENIO` |
| o néon da parede | 3,0 (o de `atmosfera`; a G15 confere) | o mundo, `VIOLETA` |
| a seta | chapada, sem brilho | o lugar |

## O som

| evento | id do mapa | onde | volume |
| --- | --- | --- | --- |
| a faixa | `mus_s02_j06` (115 BPM); até a H05, a sintetizada a 96 BPM | TV | o da faixa |
| o acerto de rolagem | `Som.tocar("vento")` = `sint_vento` | TV, 3 m para o lado do empurrão | −14 dB |
| o pino cravado | `Som.tocar("martelo")` = `martelo_0..4` | TV, na plataforma | 0 dB |
| a queda na lava | `Som.tocar("falha")` = `fx_tropeco_0..2` | TV, no boneco | −4 dB |
| BOM e ÓTIMO | `mod_clique` (`Forja.som_falante(l, "clique", 0.4)`) | alto-falante do dono | ganho 0,4 |
| PERFEITO e ERRO | `mod_nota_pN`, `mod_nota_quebrada_pN` (o kit) | alto-falante do dono | o do kit |
| o lado que pende, a cada tempo | `mod_pulso` (`Forja.som_haptica(l, "pulso", "", g)` ou `("", "pulso", g)`) | o atuador do lado que desce | 0 a 0,6 |
| o rangido, com o perigo ≥ 2 | `mod_material_metal` (`Forja.textura(l, "metal", 0.6)`) | atuadores do dono | 0,6 |
| a textura do acerto | `mod_material_madeira` (o kit, `"material": "madeira"`) | atuadores do dono | o do kit |
| o carimbo dos quatro | `car_acorde` (as reações) | TV e alto-falante | o do carimbo |

A lava não tem id próprio no mapa: a queda usa `fx_tropeco`. O mapa ainda não
tem J1 na coluna das fichas do `car_acorde` e do `mod_pulso`.

## O controle

| recurso | o evento | para quem | o quê | a prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| giroscópio e acelerômetro | toda nota | o dono | a rolagem, a arfagem, o volante e a pancada | o robô (`robo_girar`, `robo_sacudir`) e os vereditos |
| vibração | o acerto e o erro | o dono | o kit (`acerto`, `perfeito`, `erro`) | o kit (H08) |
| vibração | o empurrão a um passo da ponta (`perigo` 3) | o dono | `sentir(l, "aviso", 30000/bpm)` meio tempo antes | `percepcao(l).forte` 0,6 |
| háptica | cada tempo | o dono | o lado que pende: `"pulso"` (`mod_pulso`, 120 Hz) no atuador do lado que desce, ganho 0,6 × \|rolagem\| / 0,25 | `som_virtual(l).esq > .dir` com a rolagem ≤ −0,15 rad |
| háptica | o perigo ≥ 2 | o dono | o rangido `textura(l, "metal", 0.6)` 1 tempo antes da nota (mais o Faro) | a linha `pista` `rangido` |
| vibração | o pino dos quatro (todos em 400 ms) | cada um que cravou | o batimento: forte 1,0 por 120 ms, pausa de 120 ms, 0,7 por 120 ms; nada vibra do meio tempo antes até o pino | `percepcao(l).forte` 1,0, 0, 0,7 |
| vibração | o pino sem os quatro, a queda | o dono | `sentir(l, "golpe")` | `percepcao(l).forte` 1,0 |
| gatilho R2 | o perigo muda | o dono | `GATILHO_RESISTENCIA` de 0 com força `2 + 2·perigo` (até 8); perigo 0: `GATILHO_OFF` | `percepcao(l).gatilho_dir == 0x21` com perigo > 0 |
| gatilho L2 | — | — | do item (o kit) | o kit |
| barra de luz | o julgamento | o dono | o kit: branco 0,15 s no perfeito, a cor do lugar escurecida 0,5 s no erro | o kit |
| alto-falante | o acerto | o dono | `clique` a 0,4; a nota do kit | `som_virtual(l).som` |
| microfone | — | — | Não se aplica: a seção é do corpo | — |

Nada aqui depende da emenda do gatilho (SLOPE_FEEDBACK e
MULTIPLE_POSITION): o R2 usa a resistência simples.

## O cavaleiro

- **A peça aparece inteira e na cor dela.** O minigame não tinge o boneco:
  a cabeça (humana ou de raça: orc, autômato, golem, raposa), o superior e o
  inferior vêm da montagem com os tons próprios de cada parte (G13); a cor
  do lugar está só nos acentos da montagem, na seta, na cabeça do pino e na
  luz de dono. As animações usadas (`idle`, `jump`, `sit`, `fall`,
  `emote-no`, `attack-melee-right`) são do esqueleto comum: servem às cinco
  raças.
- **O martelo:** `martelo_na_mao(p)` põe o martelo da forja na mão direita
  de todos e guarda o item; no pino, o golpe é o `attack-melee-right` (0,417
  s) esticado em 2 batidas, que cai na batida.
- **Os stats** (`SECAO.gancho`; sem a classe `Cavaleiro`, o neutro). Nenhum
  mexe na janela, nos pontos ou nos 4 passos até a lava.

| gancho | o que muda aqui | stat 1 | stat 5 |
| --- | --- | --- | --- |
| `empurrao` | o tamanho do pender da viga e do passo do escorregão na tela (0,3 m) | ×1,16 | ×0,84 |
| `velocidade` | a volta ao centro da viga depois do acerto (o `lerp` 0,2 por quadro) | ×0,94 | ×1,06 |
| `levantar` | o tempo sentado depois de errar o pino (1 tempo, à semicolcheia) | 1,25 tempo | 0,75 tempo |
| `pista` | a seta e o rangido chegam antes (a nota não muda) | −40 ms | +40 ms |

A queda proposta para o Fôlego: 1 tempo (a coluna `queda_tempos` do
minigames.csv).

## As reações

- **`car_acorde`** («ACORDE MAIOR!»): os quatro em PERFEITO no pino (o pino
  cai no tempo 1 do compasso). A linha `momento` `pino` grava `perfeitos`
  para as reações.
- **`car_em_chamas`** e **`car_por_um_fio`**: os do kit.
- **Os adesivos `rea_*`:** só quem está na lava manda (fora da rodada, os 8
  tempos até voltar); o minigame diz quem com `fora_da_rodada(l)`.
- Nenhum carimbo próprio deste minigame.

## A diversão

**O grito: o pino dos quatro** (`pino`), degrau estrondo. A cada 16 batidas,
a partir da 20, os quatro dão a pancada no ar no mesmo tempo, e a sala faz o
mesmo gesto junta. Todos cravaram em 400 ms: o batimento na mão, 12 faíscas
por viga (48), `tremer(Sala.TREMOR_EXPLOSAO)` e 3 quadros de hit-stop. Quem
errou: salta 0,5 m e cai sentado (degrau golpe, 2 quadros).

- **O rastro:** os pinos cravados ficam na viga até o fim, um por frase.
- **Confere pelo robô (o da prova: `--robo`, o `bom` nos quatro, semente 7):**
  pelo menos 3 linhas `momento` `pino`
  com `t_musica` entre 10 e 80 s; a primeira entre 10 e 15 s; uma linha
  `momento` `reta`; nos `momento` com `x_tela` ≥ 0, 0,2 ≤ `x_tela` ≤ 0,8 e
  `altura_tela` ≥ 0,08.
- **Confere pela foto:** `viga_60s` (aos 60 s de jogo) com 2 ou mais pinos
  na viga do P1.

**O segundo grito:** a queda na lava no quarto passo (2 tempos caindo, as
faíscas `TUNGSTENIO` na lava).

**A curva:** a tabela de **Como se joga**. Pelo robô: as notas por segundo
do 2.º terço ≥ 1,5 × as do 1.º (o pico tem o dobro; `_notas_por_terco`).
Pelas fotos: a `viga_40s` tem a lava a 1,0 (`SECAO.lava`, o pico) e a
câmera 10 % mais longe; a `viga_14s`, a lava a 0,6.

**Quem está perdendo:** volta da lava em 8 tempos; o líder tem a viga a 90 %
na reta. Pelo robô (o da prova): cada lugar tem pelo menos uma linha
`toque` BOM ou melhor em cada terço. O P4 `ruim` da mesa padrão espera o
robô por lugar, que a F09 não tem: com ele, o `ruim` erraria os pinos e o
mínimo de 3 cairia.

**O que se cortou:** o volante da segunda frase em diante.

## Pronto quando

A Viga joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta não derruba ninguém na lava; a
primeira frase pede rolagem, arfagem, volante e o pino; os vereditos
`giroscopio` e `acelerometro` passam na prova limpa; `_prova_da_viga()`
passa; `godot/scripts/salas/viga.gd` não existe mais; e a foto `viga_60s`
mostra 2 ou mais pinos na viga do P1.

## Provas

**`godot/testes/prova_do_jogo.gd`:**

1. A leitura do registro de um minigame (nova, de todos: J2 a J5 usam):

   ```gdscript
   ## As linhas da linha do tempo de um slot (grava o relatório antes).
   func _linhas_do_minigame(slot: String) -> Array:
   	Forja.gravar_relatorio()
   	var linhas := []
   	if pasta == "":
   		return linhas
   	for f in DirAccess.get_files_at(pasta):
   		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
   			for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
   				var ev = JSON.parse_string(linha)
   				if ev is Dictionary and ev.get("slot", "") == slot:
   					linhas.append(ev)
   	return linhas


   ## Quantas notas o slot pediu em cada terço da duração (pelo `t_alvo` das
   ## linhas `nota`): a curva de J1 a J5 (o 2.º terço com 1,5 × o 1.º).
   func _notas_por_terco(slot: String, duracao: float) -> Array:
   	var terco := [0, 0, 0]
   	for ev in _linhas_do_minigame(slot):
   		if ev.get("tipo", "") == "nota":
   			terco[clampi(int(float(ev.get("t_alvo", 0.0)) / (duracao / 3.0)), 0, 2)] += 1
   	return terco
   ```

2. A prova da ficha, no `match` de `_prova_da_ficha`:
   `"S02_J06", "viga": await _prova_da_viga()`.

   ```gdscript
   ## A Viga (S02_J06): o pino dos quatro (o batimento e a linha momento), a
   ## háptica do lado que pende, o R2 do perigo e os vereditos.
   func _prova_da_viga() -> void:
   	var S := preload("res://scripts/minigames/s02/secao.gd")
   	_esperar(S.juntos([0.0, 0.03, 0.07, 0.10]), "S02_J06: quatro pancadas em 100 ms batem juntas")
   	_esperar(not S.juntos([0.0, 0.2, 0.4, 0.5]), "S02_J06: em 500 ms não batem")
   	var visto := {"esq": 0, "dir": 0, "r2": 0, "bat": {}}
   	var olhar := func(mg: Minigame) -> void:
   		for l in mg.presentes():
   			var sv := Forja.som_virtual(l)
   			var rol := S.rolagem(l)
   			if float(sv.esq) >= 0.0 and float(sv.dir) >= 0.0:
   				if rol <= -0.15 and float(sv.esq) > float(sv.dir):
   					visto.esq += 1
   				if rol >= 0.15 and float(sv.dir) > float(sv.esq):
   					visto.dir += 1
   			if int(mg.j[l].perigo) > 0 and int(Forja.percepcao(l).gatilho_dir) == 0x21:
   				visto.r2 += 1
   			var t0 := float(S.batimento_em.get(l, -1.0))
   			if t0 >= 0.0:
   				var d := Ritmo.t_musica() - t0
   				var forte := float(Forja.percepcao(l).forte)
   				var b: Dictionary = visto.bat.get(l, {"um": false, "pausa": false, "dois": false})
   				b.um = b.um or (d >= 0.03 and d <= 0.09 and forte >= 0.95)
   				b.pausa = b.pausa or (d >= 0.15 and d <= 0.21 and forte <= 0.05)
   				b.dois = b.dois or (d >= 0.27 and d <= 0.33 and absf(forte - 0.7) <= 0.05)
   				visto.bat[l] = b
   	var mg := await _joga_o_minigame("S02_J06", 130.0, olhar)
   	if mg == null:
   		return
   	_confere_os_vereditos(mg, ["giroscopio", "acelerometro"])
   	_esperar(visto.esq > 0 and visto.dir > 0, "S02_J06: a háptica do lado que pende (esq %d, dir %d)" % [visto.esq, visto.dir])
   	_esperar(visto.r2 > 0, "S02_J06: o R2 endurece com o perigo (0x21)")
   	for l in visto.bat:
   		var b: Dictionary = visto.bat[l]
   		_esperar(b.um and b.pausa and b.dois, "S02_J06 P%d: o batimento 1,0, 0, 0,7 (%s)" % [l + 1, b])
   	var pinos := []
   	var reta := 0
   	var por_lugar := [0, 0, 0, 0]
   	var bom_no_terco := {}  ## "lugar:terço" -> true
   	for ev in _linhas_do_minigame("S02_J06"):
   		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "pino":
   			pinos.append(float(ev.get("t_musica", 0.0)))
   			if float(ev.get("x_tela", -1.0)) >= 0.0:
   				_esperar(float(ev.x_tela) >= 0.2 and float(ev.x_tela) <= 0.8 and float(ev.altura_tela) >= 0.08,
   					"S02_J06: o pino no meio da tela (%s)" % [ev])
   		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "reta":
   			reta += 1
   		if ev.get("tipo", "") == "toque":
   			por_lugar[int(ev.get("lugar", 0))] += 1
   			if ev.get("julgamento", "erro") != "erro":
   				bom_no_terco["%d:%d" % [int(ev.get("lugar", 0)), clampi(int(float(ev.get("t_musica", 0.0)) / (mg.duracao / 3.0)), 0, 2)]] = true
   	_esperar(pinos.size() >= 3 and pinos.min() >= 10.0 and pinos.min() <= 15.0,
   		"S02_J06: 3 ou mais pinos, o primeiro entre 10 e 15 s (%s)" % [pinos])
   	_esperar(reta == 1, "S02_J06: a linha momento reta (%d)" % reta)
   	for l in mg.presentes():
   		_esperar(por_lugar[l] >= 6, "S02_J06 P%d: a primeira frase julgada (%d)" % [l + 1, por_lugar[l]])
   		for k in 3:
   			_esperar(bom_no_terco.has("%d:%d" % [l, k]), "S02_J06 P%d: um BOM ou melhor no %d.º terço" % [l + 1, k + 1])
   	var terco := _notas_por_terco("S02_J06", mg.duracao)
   	_esperar(terco[1] >= 1.5 * terco[0], "S02_J06: o pico pede 1,5 × as notas do 1.º terço (%s)" % [terco])
   ```

3. `_prova_de_fogo()`: as duas comparações com `"viga"` passam a
   `_e_a_sala(jogo.sala, "viga")` e `_e_a_sala(viga, "viga")`.

**`godot/testes/captura_jogo.gd`:** os momentos de `"viga"` passam a:

```gdscript
		"viga": [
			["viga_rolagem", fase.call("jogo", 6.0)],
			["viga_arfagem", p1.call(func(_sala, e) -> bool: return e.tipo == "arfagem" and float(e.b) - Ritmo.batida() < 0.5)],
			["viga_pino", p1.call(func(_sala, e) -> bool: return e.tipo == "pino" and float(e.b) - Ritmo.batida() < 0.3)],
			["viga_14s", fase.call("jogo", 14.0)],
			["viga_40s", fase.call("jogo", 40.0)],
			["viga_60s", fase.call("jogo", 60.0)],
		],
```

A captura tira as fotos na ordem da lista: cada uma espera a anterior.

**Os comandos:** `SALA=S02_J06 bash tests/prova_do_jogo.sh`;
`bash tests/prova_visual.sh`; e as fotos da ficha, o `roteiro` do
`tests/telas.sh` com a sala dela (cada foto num PNG em `SAIDA`: `viga_aviso`,
os momentos acima e `viga_fim`):

```bash
source scripts/engine.sh
SAIDA=/tmp/fotos-viga ROTEIRO=salas SALAS=viga RAPIDO=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
  "$FORJA_GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path godot \
  --resolution 1920x1080 res://testes/captura_jogo.tscn -- --simular=4 --semente=7 --robo \
  --relatorios="$(mktemp -d)"
```

**As pranchas que o jogador do time olha:**

- `viga_60s`: 2 ou mais pinos na viga do P1 (a régua, item 4);
- `viga_pino`: os quatro martelos no alto, o pino parado sobre cada viga;
- `viga_14s` e `viga_40s`: a lava a 0,6 e a 1,0, a câmera 10 % mais longe
  na de 40 s;
- o boneco de cada lugar, na `viga_rolagem`: a cabeça, o superior e o inferior em tons
  diferentes, sem a cor do lugar no corpo.

**O André (local):** `scripts/gauntlet.sh` (o `giro-invertido` e o
`acel-escala` têm de sair pegos) e `bash tests/prova_de_poucos.sh`; depois
`./run-local.sh -- --sala=viga` com controles de verdade: a seta chega antes
do empurrão, o lado que pende vibra do lado certo, o pino dos quatro bate
junto na mão, e a queda na lava faz rir.
