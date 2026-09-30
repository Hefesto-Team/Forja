# I3 — Portões de Néon

**Sprint:** I · **Slot:** S01_J03 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, F03, H07, I1 (o `secao.gd`), e o sorteio dentro da seção ([o índice](I-a-centelha.md#antes-de-começar-o-que-ainda-falta-na-base))

## Por quê

Passar é um toque só de ✕ no instante em que o portão bate: não há o que
escolher, só o quando — o botão mais usado do controle, julgado no
milissegundo, com a queda do portão como pista.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 3 em 03](../03-os-45-minigames.md#s1--a-centelha--botões-analógicos-gatilhos-analógicos)
- [O índice da seção](I-a-centelha.md) e a [I1](I1-o-martelo-de-hefesto.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J03",
	"titulo": "Portões de Néon",
	"verbo": "Passe!",
	"genero": "corrida",
	"icone": "cross",
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

## Como se joga

- **A faixa:** `MUS_S01_J03` — até a H05, a sintetizada a 108 bpm; com a
  gerada, 135 bpm ("esteira em semicolcheias, perseguição"). Um compasso
  ≈ 2,2 s (108) ou 1,8 s (135).
- **O hoqueto em semínimas:** o portão do lugar `l` bate na batida
  `4c + l` (P1 no 1, P2 no 2, P3 no 3, P4 no 4): os quatro portões caem em
  cascata, um por tempo. `Ritmo.simples[l]`: um portão a cada 2 compassos.
- **O portão:** vem pelo túnel na direção do cavaleiro, 2 m por tempo, e
  desce no último tempo antes de bater (de 2,6 m a 0). **Botão ✕ na batida
  do portão** → `julgar_toque`: PERFEITO, ÓTIMO e BOM passam por baixo (o
  BOM raspa o elmo: faísca); ERRO é o portão em cima dele. ✕ mais de um
  tempo antes do portão não conta (ele está correndo); a nota passou sem ✕
  (`JANELA_BOM + 0,05 s`) → nota perdida.
- **Os portões passados** são a distância; a meta: **40 portões**.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o primeiro a chegar +300, o segundo +200, o terceiro +100.
- **A progressão:** `p = t_jogo / duracao`. De 0 a 1/3, um portão por
  compasso. **O pico (1/3 a 2/3), a perseguição:** dois portões por
  compasso, nas colcheias do hoqueto (`4c + 0,5·l` e `4c + 2 + 0,5·l`), e o
  néon do túnel pisca no tempo. De 2/3 em diante, um por compasso. Quantos
  portões cabem em 90 s: ~52 a 108 bpm, ~65 a 135 bpm — quem acerta tudo
  chega entre 70 e 80 s.
- **A reta final:** o primeiro que chega abre 8 tempos para os outros; depois
  todos acabam. Sem ninguém na meta, o fim é o dos 90 s.

## O cenário

`SECAO.montar(self)` e o túnel de cada lugar:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a raia | `raia(l)` | `(RAIAS[l], 0, Z_JOGADOR)` |
| os pilares do túnel | `column` | `x ∈ {−8, −4, 0, 4, 8}`, `z ∈ {−6, −3, 0}` |
| o néon do túnel | `Kit.caixa(0.08, 0.08, 9.0)`, `Kit.material(Tema.ROXO, 2.4)` | em cima de cada fila de pilares, `y = 3.0`, `z = −3` |
| os portões | quatro por lugar, reciclados: um `Node3D` com `gate` (escala 2) e a barra de néon `Kit.caixa(1.8, 0.08, 0.08)`, `Kit.material(Tema.CIANO, 2.4)`, a 2,4 m | `x = RAIAS[l]`; `z = Z_JOGADOR − (b − batida) × 2`; `y = 2.6 × clamp(b − batida, 0, 1)` |
| a saída | `wall-opening` | `x = RAIAS[l]`; aparece quando faltam 6 portões, em `z = Z_JOGADOR − 1.6 × faltam` |
| o cavaleiro | o boneco, de costas, `sprint` no lugar | `(RAIAS[l], 0.1, Z_JOGADOR)` |

Portões com `z < −7.5` ficam escondidos (ainda estão longe). Câmera:
`camera_pos = Vector3(0, 6.5, 12.5)`, `camera_olhar = Vector3(0, 1.0, -2.0)`.
Néon é emissivo com trabalho (é o portão); a cor do lugar só na borda da raia.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **o ✕ (a feature)** | o impulso, na batida do portão |
| vibração | o kit no acerto e no erro; esmagado: `Forja.sentir(l, "golpe")`; o portão que vem: `Forja.sentir(l, "aviso", int(30000.0 / Ritmo.bpm))` meio tempo antes da batida (só fora do pico, para não virar zumbido); a chegada: `explosao` |
| barra de luz | `SECAO.piscar` no `toque` e na `falha` |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "clique", 0.5)`; erro: a nota quebrada (o kit); a chegada: `Forja.som_falante(l, "coleta", 0.8)` |
| gatilho | livre (o R2 Off) |
| háptica por material | `metal`, pelo kit |
| som na TV | a nota do lugar (o kit); `portao` baixo (−12 dB) a cada portão que bate, na raia; `golpe` no esmagado; `sucesso` na chegada |

## A falha

O portão desce em cima: o cavaleiro fica achatado (`p.modelo.scale.y` de
30% voltando a 100% da `ForjaPlayer.ESCALA` em 2 tempos, pela batida), faíscas `Tema.CIANO` no chão,
`Som.tocar("golpe")`, e **volta ao último portão** (−1 portão, nunca abaixo
de 0). O próximo portão vem no tempo de sempre.

## O fim e o vencedor

Quem chega a 40 acaba, corre pela saída (`jump`) e faz `emote-yes`.
`vencedor()`: a ordem de chegada; depois os que não chegaram, por portões;
empate pelos pontos, depois pelo lugar.

## Com menos de quatro

Nada muda: cada um tem o seu tempo do compasso. **O controle que cai:** os
portões dele param no ar (sem erro); ao voltar, o portão da vez é o próximo
tempo dele que ainda não passou.

## O robô

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

## Os ganchos

`godot/scripts/minigames/s01/portoes_de_neon.gd`:

```gdscript
extends Minigame
## Portões de Néon (S01_J03). Cada cavaleiro corre num túnel; os portões vêm
## na direção dele e batem no tempo dele (o hoqueto: um portão por compasso,
## os quatro em cascata). Botão ✕ na batida passa por baixo. A meta: 40
## portões. No meio, a perseguição: dois por compasso.
##
## A falha: o portão desce em cima; achatado, volta um portão.
## O vencedor: o primeiro a chegar; senão, mais portões.
## O alto-falante do dono: o clique no acerto, a nota no perfeito, a coleta na chegada.
## O registro mede: cada ✕ pedido e dado, com o desvio (o kit).
## O robô: ✕ na batida; quando não acerta, 200 ms atrasado.
## Com menos de quatro: nada muda.
## A régua: "Passe!" e o ✕ bastam; sem a tela, a nota do lugar e o aviso no
## controle meio tempo antes dizem o tempo; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const BATIDA_DA_PRIMEIRA_NOTA := 4.0
const META := 40
const PONTOS := [0, 20, 35, 50]
const DA_CHEGADA := [300, 200, 100, 0]
const VELOCIDADE := 2.0  ## m por tempo
const ALTURA := 2.6
const RETA_FINAL := 8.0
const FOLGA_PERDIDA := 0.05
const N_PORTOES := 4  ## os portões visíveis por lugar (reciclados)

var j := {}
var chegada: Array = []
var _fim_da_reta := -1.0
var _neon: Array = []  ## as barras do túnel (piscam no pico)
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 6.5, 12.5)
	camera_olhar = Vector3(0, 1.0, -2.0)
	SECAO.montar(self)
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		for z in [-6.0, -3.0, 0.0]:
			Kit.peca(self, "column", Vector3(x, 0, z))
		_neon.append(Kit.caixa(self, Vector3(0.08, 0.08, 9.0), Vector3(x, 3.0, -3.0), Kit.material(Tema.ROXO, 2.4)))
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var portoes: Array = []
		for i in N_PORTOES:
			var g := Node3D.new()
			g.visible = false
			add_child(g)
			Kit.peca(g, "gate", Vector3.ZERO)
			Kit.caixa(g, Vector3(1.8, 0.08, 0.08), Vector3(0, 2.4, 0), Kit.material(Tema.CIANO, 2.4))
			portoes.append(g)
		var saida := Kit.peca(self, "wall-opening", Vector3(RAIAS[l], 0, -9.0))
		saida.visible = false
		maos_livres(p)
		p.preso = true
		p.position = Vector3(RAIAS[l], 0.1, Z_JOGADOR)
		p.rotation.y = PI
		j[l] = {"fila": [], "n": 0, "passados": 0, "esmagado_b": -99.0, "avisou": -1, "fora": false,
			"portoes": portoes, "saida": saida, "robo_n": -1, "robo_mira": 0.0, "robo_feito": -1}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _no_pico() -> bool:
	var p := t_jogo / maxf(duracao, 1.0)
	return p >= 1.0 / 3.0 and p < 2.0 / 3.0


## A batida do próximo portão do lugar depois de `b`.
func _proxima_batida(l: int, b: float) -> float:
	var passo := 4.0
	var desloc := float(l)
	if Ritmo.simples[l]:
		passo = 8.0
	elif _no_pico():
		passo = 2.0
		desloc = 0.5 * l
	var k := floorf((b - desloc) / passo) + 1.0
	return maxf(k * passo + desloc, BATIDA_DA_PRIMEIRA_NOTA + desloc)


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
	SECAO.voltar_a_luz(self)
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
		# o aviso no controle, meio tempo antes (fora do pico)
		if not _no_pico() and int(e.avisou) != int(e.n) and Ritmo.batida() >= b - 0.5:
			e.avisou = int(e.n)
			Forja.sentir(l, "aviso", int(30000.0 / Ritmo.bpm))
		if Forja.apertou(l, Forja.CRUZ) and Ritmo.batida() >= b - 1.0:
			julgar_toque(l, alvo, int(e.n))
		elif agora > alvo + Ritmo.JANELA_BOM + FOLGA_PERDIDA:
			nota_perdida(l, int(e.n))
	if _fim_da_reta >= 0.0 and Ritmo.batida() >= _fim_da_reta:
		for l in presentes():
			acabou[l] = true
	for k in _neon.size():
		var m: StandardMaterial3D = (_neon[k] as MeshInstance3D).material_override
		m.emission_energy_multiplier = 2.4 + (1.6 * (1.0 - fmod(Ritmo.batida(), 1.0)) if _no_pico() else 0.0)


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
		e.passados = int(e.passados) + 1
	if p:
		p.gesto("jump", 0.35)
		if julgamento == Ritmo.BOM:
			Efeitos.faiscas(self, p.global_position + Vector3(0, 1.6, 0), Tema.AMARELO, 12, 0.6)  # raspou o elmo
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.5)
	Som.tocar("portao", Vector3(RAIAS[l], 1.0, Z_JOGADOR), -12.0)
	SECAO.piscar(self, l, julgamento)
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
	Forja.sentir(l, "golpe")
	Som.tocar("golpe", Vector3(RAIAS[l], 0.5, Z_JOGADOR), -4.0)
	Efeitos.faiscas(self, Vector3(RAIAS[l], 0.2, Z_JOGADOR), Tema.CIANO, 20, 0.8)
	SECAO.piscar(self, l, Ritmo.ERRO)
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
		var s := clampf((agora - float(e.esmagado_b)) / 2.0, 0.0, 1.0)
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
```

## O que o registro mede

Só o kit: uma `nota` por portão (o instante em que ele bate, em tempo de
música) e um `toque` por ✕ (o desvio e o julgamento, ou `perdida`). É o
botão mais julgado da noite: um ✕ que chega sempre 30 ms atrasado num
controle e não no vizinho aparece aqui, no cruzamento.

## Armadilhas

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

## Pronto quando

Os portões jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; o cabo que cai e volta não esmaga ninguém; a reta
final fecha; o fim tem sempre vencedor; `bash tests/prova_do_jogo.sh`
passa; e `bash tests/prova_visual.sh` passa com a prancha **olhada** nas
partidas em que os Portões aparecem.

## Provas

Em `godot/testes/prova_do_jogo.gd`, chamada logo depois das provas das
outras fichas da seção (ou de `await _prova_do_kit()`):

```gdscript
## S01_J03 (I3): os portões abrem pelo catálogo, o ✕ do robô chega julgado a
## cada lugar, e a corrida fecha com vencedor.
func _prova_dos_portoes() -> void:
	jogo._entrar_na_sala("S01_J03", false)
	await _quadros(2)
	var mg = jogo.sala
	_esperar(mg is Minigame and mg.id == "S01_J03", "S01_J03: abriu pelo catálogo")
	if not mg is Minigame:
		return
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 40000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "S01_J03: fechou (%.1f s)" % ((Time.get_ticks_usec() - inicio) / 1e6))
	if not is_instance_valid(mg):
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[3]) >= 1, "S01_J03 P%d: o robô bom passou um portão no perfeito %s" % [l + 1, c])
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J03: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S01_J03`: a cascata dos
quatro portões se ouve como frase, o aviso no controle chega meio tempo
antes, o achatado faz rir, e a perseguição do meio aperta.

## Ao terminar

- Catálogo: `"S01_J03": preload("res://scripts/minigames/s01/portoes_de_neon.gd")`
  em `MINIGAMES` e na lista da S01.
- `traducoes.gd`: `"Portões de Néon": "Neon Gates"`, `"Passe!": "Go under!"`;
  em `EN_PADROES`, `["^Portões: (\\d+)$", "Gates: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a I3 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: os Portões de Néon — o ✕ na batida do portão`
