# I3 — Portões de Néon

**Sprint:** I · **Slot:** S01_J03 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, I1 (o `secao.gd` e o `momento`), G03, G05, G14, G15

## Por quê

Passar é um toque só de ✕ no instante em que o portão bate: não há o que
escolher, só o quando — o botão mais usado do controle, julgado no
milissegundo, com a queda do portão como pista.

## Ler antes

- [H04 — O kit do minigame](H04-o-kit-do-minigame.md) (o `minigame.gd`)
- [O índice da seção](I-a-centelha.md) (as convenções da seção)
- [I1, a cena](I1-o-martelo-de-hefesto.md#a-cena) (o `secao.gd` inteiro, que esta ficha só chama)

O resto (a linha n.º 3 em 03, a régua da diversão, a bíblia de arte, o mapa do
áudio, o RPG) está copiado nesta ficha, com os números. Não abra outro
documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s01/portoes_de_neon.gd` | novo, o arquivo inteiro (abaixo) | só desta |
| `godot/scripts/minigames/s01/secao.gd` | nada: só chama | **da seção**: a I1 cria; nenhuma outra reescreve |
| `godot/scripts/minigames/catalogo.gd` | `"S01_J03"` em `MINIGAMES` e na lista da S01 | **de todos**: I1 a I5 põem a sua linha |
| `godot/scripts/traducoes.gd` | as linhas de «Ao terminar» | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_dos_portoes()` e as checagens dos momentos | **de todos** |

O `.uid` novo (`portoes_de_neon.gd.uid`) sai do import:
`"$GODOT" --headless --path godot --import --quit`, e entra no commit.

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; raia(l) -> Node3D
acender_raia(l, forca); posicionar(l)          # posicionar põe o boneco na raia, de mãos livres
julgar_toque(l, t_alvo, n := -1, perigo := false) -> int   # chama toque() ou falha()
nota_perdida(l, n); nova_nota(l, n, t_alvo); anotar(tipo, l, campos := {})
andamento() -> float (0..1); no_pico() -> bool; tempo_jogado() -> float; marcar(l, pontos)
proxima_batida(l, depois_de, passo, desloc) -> float
var duracao; var _raias  ## lugar -> {raiz, mat_borda, luz}
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const BATIDA_DA_PRIMEIRA_NOTA := 4
```

Do `Forja` e do `Ritmo`: `Forja.sentir(l, nome, ms := -1)` (F05: `toque`,
`acerto`, `perfeito`, `erro`, `golpe`, `explosao`, `aviso`, `golpe_esq`,
`golpe_dir`), `Forja.som_falante(l, som, ganho)`, `Forja.som_haptica(l, esq,
dir, ganho)`, `Forja.gatilho(l, lado, modo, a, b, c)` (lado 0 = L2, 1 = R2),
`Forja.cor_do_lugar(l)`, `Forja.eixo`, `Forja.apertou`, `Forja.robo_apertar`,
`Forja.robo_eixo`, `Forja.robo_acerta()` (F09), `Ritmo.t_musica()`,
`Ritmo.batida()`, `Ritmo.t_da_batida(b)`, `Ritmo.bpm`, `Ritmo.simples[l]`.
Do G03: `Itens.antecipacao_s(l, bpm)` (a Lanterna). Da G15: `Tema.neon(cor,
energia, dono)`, `Tema.emissivo(material, energia, dono)` e
`Tema.luz_da_secao(numero, lado_b := false)` (o número da seção: S1 = 1, o pódio 0); o dono é um lugar (teto 3,0), `"mundo"` (1,2)
ou `"forja"` (2,4). `Forja.vibrar` não é para a sala (F05): só `Forja.sentir`.

Do `secao.gd` da I1 (`const SECAO := preload("res://scripts/minigames/s01/secao.gd")`;
esta ficha só chama, não reescreve): `SECAO.montar(sala, olhar, distancia,
angulo) -> Dictionary`, `SECAO.passar(sala, cena, no_pico())`,
`SECAO.exagero(sala, cena, degrau, boneco, objeto)` (degraus `golpe`,
`estrondo`, `catastrofe`), `SECAO.so_o_dono(sala, dono, luzes := {})`,
`SECAO.na_reta(sala, fim_b := -1.0)` (as últimas 16 batidas),
`SECAO.adiar(fila, f)` e `SECAO.rodar_adiados(fila)` (o momento cai na
próxima colcheia), `SECAO.pose_da_camera(recuo, olhar, distancia, angulo)`,
`SECAO.gancho(l, nome)`, `SECAO.antecedencia(l)` e `SECAO.queda_s(l, tempos)`;
as constantes `SECAO.CAMERA_OLHAR`, `SECAO.CAMERA_ANGULO` (50),
`SECAO.CORRIDA_ANGULO` (30), `SECAO.CORRIDA_DISTANCIA` (17,0). A função
`momento(nome, lugar, pos, altura, campos := {})` do `minigame.gd` (a I1 a
põe; ela grava `x_tela` e `altura_tela`). Até a I1 entrar, esta ficha espera.

## Como se joga

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J03",
	"titulo": "Portões de Néon",
	"verbo": "Passe!",
	"genero": "corrida",
	"icone": "botoes",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S01_J03",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Passe!", "segundos": 6.0},
}
```

### As regras

- **A faixa:** `MUS_S01_J03`; até a H05, a sintetizada a 108 bpm; com a
  gerada, 135 bpm. Um compasso ≈ 2,2 s (108) ou 1,8 s (135).
- **A contagem:** batidas 0 a 3. Na frente de cada cavaleiro, a 1,2 m, um
  portão vazio desce entre as batidas 2 e 3 e bate no tempo 3, com o som do
  portão, e o cavaleiro faz o gesto de passar: o corpo entende que é passar
  por baixo.
- **O hoqueto em semínimas:** o portão do lugar `l` bate na batida
  `4c + l` (P1 no 1, P2 no 2, P3 no 3, P4 no 4): os quatro portões caem em
  cascata, um por tempo. `Ritmo.simples[l]`: um portão a cada 2 compassos.
- **O portão:** vem pelo túnel na direção do cavaleiro, 2 m por tempo, e
  desce no último tempo antes de bater (de 2,6 m a 0). **Botão ✕ na batida
  do portão** → `julgar_toque`: PERFEITO, ÓTIMO e BOM passam por baixo (o
  BOM raspa o elmo: faísca na cor do lugar); ERRO é o portão em cima dele. ✕
  mais de um tempo antes do portão não conta (ele está correndo); a nota
  passou sem ✕ (`FOLGA_PERDIDA`, 0,14 s) → nota perdida.
- **A pista:** fora do pico, o controle avisa (`aviso`, meio tempo de
  duração) meio tempo antes da batida do portão, mais a pista (o Faro, de
  −40 a +40 ms, e a Lanterna, meio tempo).
- **Os portões passados** são a distância; a meta: **40 portões**.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o primeiro a chegar +300, o segundo +200, o terceiro +100.
- **A progressão:** `andamento()` do kit (0..1 dos 90 s de música). De 0 a
  1/3, um portão por compasso. **O pico (1/3 a 2/3), a perseguição:** dois
  portões por compasso, nas colcheias do hoqueto (`4c + 0,5·l` e
  `4c + 2 + 0,5·l`), e o néon do túnel pulsa no tempo (de 1,2 a 0,6). **De
  2/3 em diante, a reta:** um por compasso, e o fim do túnel (a
  `wall-opening` grande e a luz branca) aparece no fundo; nas últimas 16
  batidas, **cada portão vale 2**. Quantos portões cabem em 90 s: ~52 a 108
  bpm, ~65 a 135 bpm; quem acerta tudo chega entre 70 e 80 s.
- **A reta final:** o primeiro que chega abre 16 tempos para os outros;
  depois todos acabam. Sem ninguém na meta, o fim é o dos 90 s.

### A falha

O portão desce em cima: o cavaleiro fica achatado (`p.modelo.scale.y` de
30% voltando a 100% da `ForjaPlayer.ESCALA` em 2 tempos × o Fôlego, pela batida), faíscas `Tema.TUNGSTENIO` no chão,
`Som.tocar("golpe")`, e **volta ao último portão** (−1 portão, nunca abaixo
de 0). O próximo portão vem no tempo de sempre.

**A panqueca é o momento** `achatado`, em todo erro: na colcheia seguinte, a
marca do portão no chão (uma caixa de 0,6 × 0,02 × 1,0 m no néon do lugar,
energia 2,4, que apaga até 0 em 4 s), o tremor do degrau estrondo e a luz dos
outros 30 % mais baixa por 1 batida.

### O fim e o vencedor

Quem chega a 40 acaba, corre pela saída (`jump`) e faz `emote-yes`.
`vencedor()`: a ordem de chegada; depois os que não chegaram, por portões;
empate pelos pontos, depois pelo lugar.

### Com menos de quatro

Nada muda: cada um tem o seu tempo do compasso. **O controle que cai:** os
portões dele param no ar (sem erro); ao voltar, o portão da vez é o próximo
tempo dele que ainda não passou.

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if e.fila.is_empty() or int(e.robo_feito) == int(e.n):
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado (esmagado)
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	if Ritmo.t_musica() >= Ritmo.t_da_batida(float(e.fila[0])) + float(e.robo_mira):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		e.robo_feito = int(e.n)
```

### O código

`godot/scripts/minigames/s01/portoes_de_neon.gd`:

```gdscript
extends Minigame
## Portões de Néon (S01_J03). Cada cavaleiro corre num túnel; os portões vêm
## na direção dele e batem no tempo dele (o hoqueto: um portão por compasso,
## os quatro em cascata). Botão ✕ na batida passa por baixo. A meta: 40
## portões. No meio, a perseguição: dois por compasso. De 2/3 em diante, o fim
## do túnel; nas últimas 16 batidas, cada portão vale 2.
##
## A falha: o portão desce em cima; achatado (a panqueca), volta um portão.
## O vencedor: o primeiro a chegar; senão, mais portões.
## O alto-falante do dono: o clique no acerto, a nota no perfeito, a coleta na chegada.
## O registro mede: cada ✕ pedido e dado, com o desvio (o kit), e os
## momentos `achatado` e `reta`.
## O robô: ✕ na batida; quando não acerta, 200 ms atrasado.
## Com menos de quatro: nada muda.
## A régua: "Passe!" e o ✕ bastam; sem a tela, a nota do lugar e o aviso no
## controle meio tempo antes dizem o tempo; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const META := 40
const PONTOS := [0, 20, 35, 50]
const DA_CHEGADA := [300, 200, 100, 0]
const VELOCIDADE := 2.0  ## m por tempo
const ALTURA := 2.6
const RETA_FINAL := 16.0  ## o primeiro que chega abre 16 tempos
const QUEDA_TEMPOS := 2.0  ## achatado: volta à altura em 2 tempos × o Fôlego
const MARCA_S := 4.0  ## a marca do portão no chão apaga em 4 s
const N_PORTOES := 4  ## os portões visíveis por lugar (reciclados)

var j := {}
var chegada: Array = []
var _fim_da_reta := -1.0
var _neon: Array = []  ## as barras do túnel (piscam no pico)
var _mat_tunel: StandardMaterial3D  ## o material das cinco barras do túnel, um só
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var cena := {}  ## o que o SECAO.montar devolveu
var _adiados: Array = []  ## o que cai na próxima colcheia (SECAO.adiar)
var _fim_do_tunel: Node3D  ## a wall-opening grande e a luz branca, a 2/3
var _reta_marcada := false


func montar() -> void:
	# a corrida, fixa: 30°, a 18 m de (0, 1, −1); a raia de x = ±6 fica em x_tela 0,22 e 0,78
	cena = SECAO.montar(self, Vector3(0, 1.0, -1.0), 18.0, SECAO.CORRIDA_ANGULO)
	_fim_do_tunel = Node3D.new()
	_fim_do_tunel.visible = false
	add_child(_fim_do_tunel)
	Kit.peca(_fim_do_tunel, "wall-opening", Vector3(0, 0, -9.5), 0.0, 4.0)
	var branca := OmniLight3D.new()
	branca.position = Vector3(0, 3.0, -9.0)
	branca.light_color = Tema.ETIQUETA
	branca.light_energy = 1.2
	branca.omni_range = 10.0
	_fim_do_tunel.add_child(branca)
	# um material só para as cinco barras: o pulso do pico muda as cinco de uma vez
	_mat_tunel = Kit.material(Tema.VIOLETA, 1.2, 0.8, "mundo")
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		for z in [-6.0, -3.0, 0.0]:
			Kit.peca(self, "column", Vector3(x, 0, z))
		_neon.append(Kit.caixa(self, Vector3(0.08, 0.08, 9.0), Vector3(x, 3.0, -3.0), _mat_tunel))
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var barra := Tema.neon(Forja.cor_do_lugar(l), 2.4, l)  # a barra do portão: de quem ele é
		var portoes: Array = []
		for i in N_PORTOES:
			var g := Node3D.new()
			g.visible = false
			add_child(g)
			Kit.peca(g, "gate", Vector3.ZERO)
			Kit.caixa(g, Vector3(1.8, 0.08, 0.08), Vector3(0, 2.4, 0), barra)
			portoes.append(g)
		# o portão vazio da contagem, 1,2 m à frente do cavaleiro
		var vazio := Node3D.new()
		vazio.visible = false
		vazio.position = Vector3(RAIAS[l], ALTURA, Z_JOGADOR - 1.2)
		add_child(vazio)
		Kit.peca(vazio, "gate", Vector3.ZERO)
		Kit.caixa(vazio, Vector3(1.8, 0.08, 0.08), Vector3(0, 2.4, 0), barra)
		var saida := Kit.peca(self, "wall-opening", Vector3(RAIAS[l], 0, -9.0))
		saida.visible = false
		maos_livres(p)
		p.preso = true
		p.position = Vector3(RAIAS[l], 0.1, Z_JOGADOR)
		p.rotation.y = PI
		j[l] = {"fila": [], "n": 0, "passados": 0, "esmagado_b": -99.0, "avisou": -1, "fora": false,
			"portoes": portoes, "saida": saida, "robo_n": -1, "robo_mira": 0.0, "robo_feito": -1,
			"vazio": vazio, "vazio_bateu": false}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A batida do próximo portão do lugar depois de `b`.
func _proxima_batida(l: int, b: float) -> float:
	var passo := 4.0
	var desloc := float(l)
	if Ritmo.simples[l]:
		passo = 4.0  # o kit dobra o passo na partitura simples
	elif no_pico():
		passo = 2.0
		desloc = 0.5 * l
	return proxima_batida(l, b, passo, desloc)  # o kit (H08): a próxima depois de b


## Enche a fila do lugar até N_PORTOES batidas, a partir de `desde`; a
## primeira é a nota da vez (vai para o registro).
func _encher(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var ultimo := desde
	if not e.fila.is_empty():
		ultimo = float(e.fila[e.fila.size() - 1])
	var novo := e.fila.is_empty()
	while e.fila.size() < N_PORTOES:
		ultimo = _proxima_batida(l, ultimo)
		e.fila.append(ultimo)
	if novo:
		nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.fila[0])))


func iniciar_jogo() -> void:
	for l in presentes():
		_encher(l, BATIDA_DA_PRIMEIRA_NOTA - 1.0)


func jogar(_dt: float) -> void:
	SECAO.passar(self, cena, no_pico())
	SECAO.rodar_adiados(_adiados)
	_contagem()
	if not _fim_do_tunel.visible and (andamento() >= 2.0 / 3.0 or _fim_da_reta >= 0.0):
		_fim_do_tunel.visible = true
	if not _reta_marcada and fase == "jogo" and SECAO.na_reta(self, _fim_da_reta):
		_reta_marcada = true
		var valores := PackedStringArray(presentes().map(func(x): return str(int(j[x].passados))))
		momento("reta", -1, Vector3(0, 0, -6.0), 2.6, {"objeto": "tunel", "valores": ",".join(valores)})
	for l in presentes():
		var e: Dictionary = j[l]
		_mostrar(l)
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			e.fila.clear()
			_encher(l, Ritmo.batida())
		var b := float(e.fila[0])
		var alvo := Ritmo.t_da_batida(b)
		var agora := Ritmo.t_musica()
		# o aviso no controle, meio tempo antes mais a pista (o Faro e a Lanterna), fora do pico
		var antes := 0.5 + SECAO.antecedencia(l) * Ritmo.bpm / 60.0
		if not no_pico() and int(e.avisou) != int(e.n) and Ritmo.batida() >= b - antes:
			e.avisou = int(e.n)
			Forja.sentir(l, "aviso", int(30000.0 / Ritmo.bpm))
		if Forja.apertou(l, Forja.CRUZ) and Ritmo.batida() >= b - 1.0:
			julgar_toque(l, alvo, int(e.n))
		elif agora > alvo + FOLGA_PERDIDA:
			nota_perdida(l, int(e.n))
	if _fim_da_reta >= 0.0 and Ritmo.batida() >= _fim_da_reta:
		for l in presentes():
			acabou[l] = true
	# o néon do túnel: 1,2 parado; no pico, pulsa de 1,2 (na batida) a 0,6 (as cinco barras dividem o _mat_tunel)
	Tema.emissivo(_mat_tunel, 0.6 + 0.6 * (1.0 - fmod(Ritmo.batida(), 1.0)) if no_pico() else 1.2, "mundo")


## A nota da vez foi julgada: o portão sai da fila e o próximo vira a nota.
func _seguinte(l: int) -> void:
	var e: Dictionary = j[l]
	var b := float(e.fila.pop_front())
	e.n = int(e.n) + 1
	_encher(l, b)
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.fila[0])))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	var p := jogador(l)
	if not treinando:
		# nas últimas 16 batidas (ou depois do primeiro na meta), cada portão vale 2
		e.passados = int(e.passados) + (2 if SECAO.na_reta(self, _fim_da_reta) else 1)
	if p:
		# o Passo e a Âncora (G03) mudam só o gesto: o pulo dura 0,35 s / velocidade
		p.gesto("jump", 0.35 / (SECAO.gancho(l, "velocidade") * Itens.velocidade(l, "corrida")))
		if julgamento == Ritmo.BOM:
			Efeitos.faiscas(self, p.global_position + Vector3(0, 1.6, 0), Forja.cor_do_lugar(l), 12, 0.6)  # raspou o elmo
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.5)
	# o portão passa por cima: o clique na mão esquerda e, 60 ms depois, na direita
	Forja.som_haptica(l, "clique", "", 0.5)
	get_tree().create_timer(0.06).timeout.connect(func(): Forja.som_haptica(l, "", "clique", 0.5))
	Som.tocar("portao", Vector3(RAIAS[l], 1.0, Z_JOGADOR), -12.0)
	if int(e.passados) >= META:
		_chegou(l)
		return
	_seguinte(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	e.esmagado_b = float(e.fila[0])
	if not treinando:
		e.passados = maxi(0, int(e.passados) - 1)  # volta ao último portão
	Som.tocar("golpe", Vector3(RAIAS[l], 0.5, Z_JOGADOR), -4.0)
	Efeitos.faiscas(self, Vector3(RAIAS[l], 0.2, Z_JOGADOR), Tema.TUNGSTENIO, 20, 0.8)
	# a panqueca: a marca, o tremor, a luz e a vibração caem juntos na próxima colcheia
	SECAO.adiar(_adiados, _achatado.bind(l))
	_seguinte(l)


func _chegou(l: int) -> void:
	chegada.append(l)
	acabou[l] = true
	marcar(l, DA_CHEGADA[mini(chegada.size() - 1, 3)])
	Forja.sentir(l, "explosao")
	Forja.som_falante(l, "coleta", 0.8)
	var p := jogador(l)
	if p:
		p.gesto("emote-yes", 1.6)
		Som.tocar("sucesso", p.global_position + Vector3(0, 1.5, 0), -4.0)
		Efeitos.faiscas(self, p.global_position + Vector3(0, 2.0, 0), Forja.cor_do_lugar(l), 40, 1.3)
	for g in j[l].portoes:
		(g as Node3D).visible = false
	if _fim_da_reta < 0.0:
		_fim_da_reta = Ritmo.batida() + RETA_FINAL


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var p := jogador(l)
	var agora := Ritmo.batida()
	if p:
		# volta à altura em 2 tempos × o Fôlego (arredondados à semicolcheia)
		var volta := SECAO.queda_s(l, QUEDA_TEMPOS) * Ritmo.bpm / 60.0
		var s := clampf((agora - float(e.esmagado_b)) / volta, 0.0, 1.0)
		if p.modelo:
			p.modelo.scale.y = ForjaPlayer.ESCALA * lerpf(0.3, 1.0, s)  # o modelo tem a escala 2 do boneco
		p.animar("sprint" if fase == "jogo" and not acabou[l] else "idle", 1.0)
	for i in N_PORTOES:
		var g: Node3D = e.portoes[i]
		if acabou[l] or i >= e.fila.size() or fase != "jogo":
			g.visible = false
			continue
		var b := float(e.fila[i])
		var z: float = Z_JOGADOR - (b - agora) * VELOCIDADE
		g.visible = z > -7.5
		g.position = Vector3(RAIAS[l], ALTURA * clampf(b - agora, 0.0, 1.0), z)
	var faltam := META - int(e.passados)
	var saida: Node3D = e.saida
	saida.visible = fase == "jogo" and faltam <= 6
	saida.position.z = Z_JOGADOR - 1.6 * maxi(faltam, 0) - 1.0


## O fim (o gancho da SalaJogo): ninguém sai achatado.
func ao_terminar() -> void:
	for p in jogadores:
		if p.modelo:
			p.modelo.scale.y = ForjaPlayer.ESCALA


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	var ca := chegada.find(a)
	var cb := chegada.find(b)
	if ca >= 0 or cb >= 0:
		if ca < 0:
			return false
		if cb < 0:
			return true
		return ca < cb
	if int(j[a].passados) != int(j[b].passados):
		return int(j[a].passados) > int(j[b].passados)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Portões: %d" % int(j[lugar].passados)
	return super(lugar)


## A contagem (batidas 0 a 3): na frente de cada cavaleiro, um portão vazio
## desce no tempo 3 (de 2,6 m a 0, entre as batidas 2 e 3), bate com o som
## do portão e o cavaleiro faz o gesto de passar. Some na batida 4.
func _contagem() -> void:
	var b := Ritmo.batida()
	for l in presentes():
		var g: Node3D = j[l].vazio
		g.visible = b >= 0.0 and b < float(BATIDA_DA_PRIMEIRA_NOTA)
		if not g.visible:
			continue
		g.position.y = ALTURA * clampf(3.0 - b, 0.0, 1.0)
		if b >= 3.0 and not bool(j[l].vazio_bateu):
			j[l].vazio_bateu = true
			Som.tocar("portao", Vector3(RAIAS[l], 1.0, Z_JOGADOR), -12.0)
			var p := jogador(l)
			if p:
				p.gesto("jump", 0.35)


## A panqueca (o momento `achatado`): a marca do portão no chão, na cor do
## dono, que apaga em 4 s; o tremor do degrau estrondo; a luz dos outros cai
## 30 % por 1 batida; a vibração `golpe`. Roda na colcheia seguinte ao erro
## (SECAO.adiar), com tudo junto.
func _achatado(l: int) -> void:
	var pos := Vector3(RAIAS[l], 0.11, Z_JOGADOR)
	var mat := Kit.material(Forja.cor_do_lugar(l), 2.4, 0.8, l)  # um material novo por marca: apagar não toca as barras
	var marca := Kit.caixa(self, Vector3(0.6, 0.02, 1.0), pos, mat)
	var apagar := func(v: float) -> void:
		Tema.emissivo(mat, v, l)
	var tw := marca.create_tween()
	tw.tween_method(apagar, 2.4, 0.0, MARCA_S)
	tw.tween_callback(marca.queue_free)
	SECAO.exagero(self, cena, "estrondo", jogador(l))
	SECAO.so_o_dono(self, l)
	Forja.sentir(l, "golpe")
	momento("achatado", l, pos, 2.6, {"passados": int(j[l].passados)})
```

### O que o registro mede

Só o kit: uma `nota` por portão (o instante em que ele bate, em tempo de
música) e um `toque` por ✕ (o desvio e o julgamento, ou `perdida`). É o
botão mais julgado da noite: um ✕ que chega sempre 30 ms atrasado num
controle e não no vizinho aparece aqui, no cruzamento. E a linha `momento`:
`achatado` (o lugar, `passados`, `x_tela`, `altura_tela`) e `reta` (uma vez,
de todos, com `objeto` `tunel` e `valores`, os portões de cada lugar).

### Armadilhas

- **A fila de portões é de batidas**, não de nós: os quatro nós só mostram
  as quatro primeiras batidas. Nunca crie um nó por portão.
- **A nota do registro é o primeiro da fila:** `_encher` registra só quando
  a fila estava vazia; `_seguinte` registra o novo primeiro.
- **✕ cedo demais não conta** (mais de um tempo antes): senão o jogador que
  aperta para "correr" seria esmagado por um portão ainda longe.
- **`Forja.sentir(l, "aviso", ms)`**: a duração é meio tempo da faixa
  (`30000 / bpm` ms), como o 05 manda; no pico, sem aviso.
- **O `modelo.scale.y`** é relativo à escala do boneco (`ForjaPlayer.ESCALA`,
  2,0), nunca 1. Ele volta sozinho pela batida, mas o `_mostrar` só roda na
  fase `jogo`: o `ao_terminar()` (o gancho da `SalaJogo` no fim) devolve a
  escala de todos, senão quem foi esmagado no último tempo sai achatado.
- **A panqueca cai na colcheia** seguinte ao erro (`SECAO.adiar`): a marca,
  o tremor, a vibração `golpe` e o momento juntos. O achatar do boneco segue
  a batida do portão (`esmagado_b`), como hoje.
- **A marca tem material próprio** (`Kit.material(cor do lugar, 2.4, 0.8, l)`,
  um `StandardMaterial3D` novo por marca): o `Tema.emissivo` só age num
  `StandardMaterial3D`, nunca no `ShaderMaterial` do `Tema.neon`, e apagar a
  marca não apaga as barras dos portões do lugar.
- **As cinco barras do túnel dividem um material** (`_mat_tunel`, um
  `Kit.material(Tema.VIOLETA, 1.2, 0.8, "mundo")` criado antes do laço): o
  pulso muda esse material e as cinco seguem. Um `Tema.neon` por barra daria
  cinco materiais, e o `Tema.emissivo` não age no `ShaderMaterial` dele.
- **O portão vale 2 na reta** e a meta segue 40: quem está a 1 portão e
  passa na reta vai a 41 e chega.
- **Nenhum `Color("#…")` nem `Tema.ROXO`, `Tema.CIANO`, `Tema.AMARELO`**:
  o túnel `Tema.VIOLETA` (mundo), a barra na cor do lugar (G14, G15).

## A cena

### A câmera

A câmera de corrida do cinema, fixa: lente de 28 mm (FOV vertical 46,4°),
30° abaixo da horizontal, atrás e acima. `SECAO.montar(self,
Vector3(0, 1.0, -1.0), 18.0, 30.0)` a põe em `(0, 10,0, 14,59)` olhando
`(0, 1, −1)`. Os quatro túneis, os portões que vêm e o fim do túnel (z =
−9,5) cabem inteiros; o cavaleiro de x = ±6 fica em x_tela 0,22 e 0,78
(com os 40° de hoje, até a G05) ou 0,26 e 0,74 (com os 28 mm). O `lerp` do
main faz o caminho.

- **O pico:** a câmera recua 10 % (a 19,8 m) e volta ao sair.
- **O tremor é do evento:** só o de `SECAO.exagero` (a panqueca, estrondo:
  0,05 m por 2 batidas, o cavaleiro parado 3 quadros). Roll zero.

### A luz da seção

S1 é o vermelhão (`Tema.SECAO[0]`, `#c8432f`), lado A.
`Tema.luz_da_secao(1)` (G15; S1, lado A: `lado_b` false) devolve a névoa `#210502`, o preenchimento
`#602016` e a chave `#ffc99c`. O `SECAO.montar` da I1 põe o preenchimento (o
`atmosfera`, com as brasas), a chave (`OmniLight3D` em `(0, 8, 3)`, energia
0,9, alcance 26) e a fornalha do fundo (`Tema.TUNGSTENIO`, 1,4, alcance 8, em
`(0, 1,2, −6)`). No pico, o `SECAO.passar` sobe a chave e a fornalha 20 % em
1 batida e as devolve em 2 (com `Opcoes.flashes` desligado: +10 % em 2
batidas).

- **O fim do túnel:** de 2/3 em diante, uma `OmniLight3D` `Tema.ETIQUETA`
  (a luz branca), energia 1,2, alcance 10, em `(0, 3, −9)`, dentro da
  `wall-opening` grande.
- **A panqueca:** a luz da raia dos outros cai 30 % por 1 batida
  (`SECAO.so_o_dono`).

### As peças e o papel de cada uma

`cena = SECAO.montar(self, Vector3(0, 1.0, -1.0), 18.0, 30.0)` e o túnel de
cada lugar:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a raia | `raia(l)` | `(RAIAS[l], 0, Z_JOGADOR)` |
| os pilares do túnel | `column` | `x ∈ {−8, −4, 0, 4, 8}`, `z ∈ {−6, −3, 0}` |
| o néon do túnel | `Kit.caixa(0.08, 0.08, 9.0)`, as cinco com o mesmo `Kit.material(Tema.VIOLETA, 1.2, 0.8, "mundo")` | em cima de cada fila de pilares, `y = 3.0`, `z = −3` |
| os portões | quatro por lugar, reciclados: um `Node3D` com `gate` (escala 2) e a barra `Kit.caixa(1.8, 0.08, 0.08)`, `Tema.neon(cor do lugar, 2.4, l)`, a 2,4 m | `x = RAIAS[l]`; `z = Z_JOGADOR − (b − batida) × 2`; `y = 2.6 × clamp(b − batida, 0, 1)` |
| o portão vazio | o mesmo portão, um por lugar | `(RAIAS[l], 2.6 → 0, Z_JOGADOR − 1.2)`, só nas batidas 0 a 3 |
| a saída | `wall-opening` | `x = RAIAS[l]`; aparece quando faltam 6 portões, em `z = Z_JOGADOR − 1.6 × faltam − 1` |
| o fim do túnel | `wall-opening`, escala 4, e a luz branca | `(0, 0, −9.5)`; aparece a 2/3 |
| a marca do portão | `Kit.caixa(0.6, 0.02, 1.0)`, `Kit.material(cor do lugar, 2.4, 0.8, l)` (um por marca), 2,4 → 0 em 4 s | no chão, sob o cavaleiro achatado |
| o cavaleiro | o boneco, de costas, `sprint` no lugar | `(RAIAS[l], 0.1, Z_JOGADOR)` |

Portões com `z < −7.5` ficam escondidos (ainda estão longe).

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08, arte/04) |
| a barra do portão | o lugar | `Tema.neon(cor, 2.4, l)` |
| a marca do portão no chão | o lugar | 2,4 → 0 em 4 s |
| as faíscas do BOM (o elmo raspado) | o lugar | `Forja.cor_do_lugar(l)`, 12 partículas |
| as faíscas da panqueca | a forja | `Tema.TUNGSTENIO`, 20 partículas |
| o néon do túnel | o mundo | `Kit.material(Tema.VIOLETA, 1.2, 0.8, "mundo")`; no pico, `Tema.emissivo` de 1,2 → 0,6 a cada batida |
| a luz do fim do túnel | o mundo | luz, não material |

Nenhuma cor fora dos tokens: o `Tema.ROXO`, o `Tema.CIANO` e o `Tema.AMARELO`
de hoje somem desta sala.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o portão vazio da contagem | `Som.tocar("portao", raia, -12.0)` no tempo 3 | — | `portao_0` |
| o portão que passa (acerto) | a nota do lugar (o kit) e `Som.tocar("portao", raia, -12.0)` | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "clique", 0.5)` | `portao_0`; `mod_nota_p1..p4`, `mod_clique` |
| a panqueca | `Som.tocar("golpe", raia, -4.0)` | a nota quebrada (o kit) | `golpe_0..4`; `mod_nota_quebrada_p1..p4` |
| a chegada | `Som.tocar("sucesso", pos, -4.0)` | `Forja.som_falante(l, "coleta", 0.8)` | `vitoria_sala_*` (`sint_sucesso`); `mod_coleta` |
| a faixa | `MUS_S01_J03`: 135 BPM; até ela existir, a sintetizada da H05 a 108 | — | `mus_s01_j03` |

- **O alto-falante toca um som por vez** e o julgamento tem a vez.
- **Nenhum bipe de falha:** a panqueca soa como metal (`golpe`).
- A cascata dos quatro `portao` (um por tempo) é a frase do minigame.

## O controle

Evento por evento. O piso é o da F05.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| o portão que vem (fora do pico) | o dono | `Forja.sentir(l, "aviso", int(30000 / bpm))`, meio tempo + a pista antes | — | — | — |
| o portão que passa | o dono | `acerto`/`perfeito` (o kit); `Forja.som_haptica(l, "clique", "", 0.5)` e, 60 ms depois, `("", "clique", 0.5)` | — | o kit: branco 0,15 s no perfeito | a nota ou o `clique` 0,5 |
| a panqueca | o dono | `erro` (o kit) e `golpe` (1,0 / 0,6, 250 ms), na colcheia seguinte | — | o kit: a cor escurecida 0,5 s | a nota quebrada |
| a chegada | o dono | `explosao` (1 / 1, 400 ms) | — | — | `coleta` 0,8 |
| começar | todos | — | R2 `GATILHO_OFF`; o L2 nunca (é do item, G03) | a cor do lugar | — |

- No pico, sem aviso: os portões vêm em colcheias e o aviso viraria zumbido.
- O portão passa por cima do cavaleiro: o clique anda da mão esquerda para
  a direita em 60 ms.
- A barra de luz é **sempre a cor do lugar**. O microfone não se usa. **Os
  outros não sentem nada** do que é de um.
- **Sem o controle na mão:** o robô aperta ✕ pelo relógio da música; a prova
  confere que cada `achatado` tem a sua `sensacao` `golpe` no mesmo quadro.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo
que a pessoa escolheu aparecem como estão, de costas para a câmera, no
túnel. Cada parte tem a sua faixa de valor e um acento de néon só, na cor do
lugar (arte/04, «A peça se distingue»): a cabeça humana sem acento (a de
raça, o visor ou a rachadura, até 6 %), o friso do superior (até 8 % da
parte, energia 1,6), a costura do inferior (até 5 %, 1,6); somados, no
máximo 8 % da frente do corpo. O contorno é de 0,012, energia 2,4 no jogo. `maos_livres(p)`: a arma ou o amuleto não aparece nos
Portões, mas o efeito do item vale. O cavaleiro pode ser de outra raça (o Orc, o Autômato de latão, o Golem de
escória, a Raposa ferreira; a raça é só aparência): esta ficha não supõe
corpo humano; usa o esqueleto comum de 7 ossos e as animações `sprint`, `jump`, `emote-yes` e
`idle`; a panqueca escala o `modelo` em y (30 % → 100 %), sem animação
própria, e vale para qualquer raça.

| stat | gancho | o que muda nos Portões | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: a panqueca não empurra | — | — | — |
| Passo | `velocidade` | só o gesto do pulo (0,35 s / velocidade); a nota não muda | 0,372 s | 0,35 s | 0,330 s |
| Fôlego | `levantar` | quanto tempo achatado (a volta a 100 %) | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | o aviso no controle chega antes; o portão bate no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Lanterna adianta
o aviso meio tempo (`Itens.antecipacao_s`); a Âncora deixa o pulo 10 % mais
lento (só o gesto); o Martelo dobra o perfeito no tempo forte (o kit); o
Fole e o Diapasão agem no combo pelo kit. Os números da régua: nenhum stat
muda a janela de julgamento; o stat 5 nunca tira a panqueca.

## As reações

- **Carimbos que os Portões podem disparar** (todos são do kit e do HUD,
  G04; os Portões não chamam nenhum): `car_em_chamas` (5 Ressonâncias
  seguidas do mesmo lugar), `car_por_um_fio` (o vencedor por 2 % dos pontos
  ou menos). `car_acorde` não acontece: no hoqueto, cada tempo tem um dono.
  O `car_virada` é do placar.
- **Adesivos:** ninguém está fora da rodada nos Portões, então ninguém manda adesivo
  durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

Nota de hoje 4; com a panqueca marcada no chão e a reta, o alvo é 5.

**O momento: a panqueca** (`achatado`). O portão desce em cima de quem errou:
o cavaleiro fica achatado a 30 % da altura e volta em 2 tempos, como uma
mola. Os quatro portões caem em cascata, um por tempo; quando dois erram no
mesmo compasso, a sala vê duas panquecas seguidas. Degrau estrondo: tremor
de 0,05 m por 2 batidas, o cavaleiro parado 3 quadros.

- **Rastro:** a marca do portão no chão (0,6 × 1,0 m, no néon do dono) fica
  4 s, apagando; o cavaleiro anda achatado os 2 tempos da volta.
- **A curva:** de 0 a 30 s, um portão por compasso; de 30 a 60 s, a
  perseguição (dois por compasso, o néon pulsa); de 60 s ao fim, o fim do
  túnel aparece e, nas últimas 16 batidas, cada portão vale 2.
- **Ensina sem falar:** o portão vazio da contagem desce e bate na frente de
  cada cavaleiro, e ele passa sozinho.
- **Quem está perdendo:** a panqueca custa um portão só; 5 portões se
  recuperam em 5 compassos; o portão dobrado da reta vale para todos.
- **O que se corta:** nada.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3
`medio`, P4 `ruim`, semente 7, sem a bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | os quadros de 2 a 10 s mostram os portões descendo nos quatro túneis |
| 3. ensina sem falar | a coleta de texto da F02 na fase de jogo só acha o verbo, os nomes, os P#, o placar e o julgamento | o quadro da contagem mostra o portão vazio na frente de cada cavaleiro |
| 4. o momento | pelo menos 8 linhas `momento` `achatado` no minigame e pelo menos 3 entre 30 e 60 s | 1 quadro em cada 5 mostra uma marca de portão no chão |
| 5. a curva | notas por segundo entre 30 e 60 s ≥ 1,8 × as de 0 a 30 s; a linha `momento` `reta` existe uma vez | o quadro de 62 s mostra o fim do túnel com a luz branca |
| 6. a falha | o P4 tem pelo menos 8 linhas `toque` com `erro` | o quadro seguinte a uma panqueca mostra o cavaleiro achatado e a marca |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `achatado` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | a marca se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `achatado`, uma linha `sensacao` `golpe` do mesmo lugar a até 16,7 ms, a até 1 quadro de uma colcheia | — |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem dos portões no `momento` `reta` | no quadro de 60 s, quem olha diz a ordem pelas saídas que já apareceram |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na
régua) existir, a prova roda com `--robo=medio` nos quatro e confere os itens 1, 3, 5, 8, 9 e 10;
os itens 4, 6 e 7 (que pedem o P4 `ruim`) esperam o robô por lugar.

## Pronto quando

Os portões jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; o cabo que cai e volta não esmaga ninguém; a reta
final fecha; o fim tem sempre vencedor; `bash tests/prova_do_jogo.sh`
passa; e `bash tests/prova_visual.sh` passa com a prancha **olhada** nas
partidas em que os Portões aparecem. Além disso: cada erro grava `achatado` a até 1 quadro
de uma colcheia, com a sua `sensacao` `golpe`; a linha `momento` `reta`
aparece uma vez; e nenhuma cor fora dos tokens sobra no `portoes_de_neon.gd`
(`grep -nE 'Color\("#|Tema\.(ROSA|AMARELO|TRILHO|CIANO|ROXO|LARANJA|FG)\b'`
não acha nada).

## Provas

Em `godot/testes/prova_do_jogo.gd`, chamada logo depois das provas das
outras fichas da seção (ou de `await _prova_do_kit()`):

```gdscript
## S01_J03 (I3): os portões abrem pelo catálogo, o ✕ do robô chega julgado a
## cada lugar, e a corrida fecha com vencedor.
func _prova_dos_portoes() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S01_J03", 130.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[3]) >= 1, "S01_J03 P%d: o robô bom passou um portão no perfeito %s" % [l + 1, c])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J03: de volta ao salão")
```

Ainda na `_prova_dos_portoes()`, antes de esperar o salão, os momentos (a
régua):

```gdscript
	var todas := _linha_do_tempo()
	var linhas := todas.filter(func(e): return e.get("slot") == "S01_J03")
	var momentos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "achatado")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "S01_J03: a linha momento reta aparece uma vez")
	for r in momentos:
		_esperar(float(r.get("x_tela", 0.0)) >= 0.2 and float(r.get("x_tela", 0.0)) <= 0.8 \
			and float(r.get("altura_tela", 0.0)) >= 0.08, "S01_J03: o momento no meio da tela (%s)" % [r])
		var t := float(r.get("t_musica", 0.0))
		# a sensacao (F05) não leva slot: procura em todas, perto no relógio da sessão (t)
		var sente := todas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "golpe" \
			and int(e.get("lugar", -9)) == int(r.get("lugar", -1)) \
			and absf(float(e.get("t_musica", -9.0)) - t) <= 0.0167 \
			and absf(float(e.get("t", -9.0)) - float(r.get("t", 0.0))) <= 1.0)
		_esperar(not sente.is_empty(), "S01_J03: o momento tem a sensação golpe no mesmo quadro (%s)" % [r])
```

(`_linha_do_tempo` é da F01; já está na prova. A contagem mínima de
`achatado` (8 no minigame, 3 entre 30 e 60 s) espera o robô por lugar.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### O que o André joga e sente

**O André (local):** `./run-local.sh -- --sala=S01_J03`: a cascata dos
quatro portões se ouve como frase, o aviso no controle chega meio tempo
antes, o achatado faz rir, e a perseguição do meio aperta.

- na contagem, o portão vazio bate na frente de cada um no tempo 3;
- o clique do portão anda da mão esquerda para a direita;
- a panqueca: a marca na cor do lugar fica no chão e o controle bate
  `golpe` junto com a imagem;
- nas últimas 16 batidas, o placar sobe de 2 em 2.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a
cada 2 s): o da contagem (o portão vazio), 1 quadro em cada 5 com uma marca
no chão, o de 45 s (o néon pulsando e a câmera mais longe), o de 62 s (o fim
do túnel) e o de 60 s (a ordem pelas saídas, anotada aqui na ficha).

### Ao terminar

- Catálogo: `"S01_J03": preload("res://scripts/minigames/s01/portoes_de_neon.gd")`
  em `MINIGAMES` e na lista da S01.
- `traducoes.gd`: `"Portões de Néon": "Neon Gates"`, `"Passe!": "Go under!"`;
  em `EN_PADROES`, `["^Portões: (\\d+)$", "Gates: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a I3 **feito**, com o commit.
- Commit (sem trailer): `feat: os Portões de Néon — o ✕ na batida do portão`
