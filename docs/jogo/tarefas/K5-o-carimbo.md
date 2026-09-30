# K5 — O Carimbo

**Sprint:** K · **Slot:** S03_J15 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, F03, H07, K1 (o `secao.gd`), e o sorteio dentro da seção ([o índice](I-a-centelha.md#antes-de-começar-o-que-ainda-falta-na-base))

## Por quê

Carimbar é o clique do touchpad na síncope: o lingote do centro é da vez de
um, mas qualquer um pode carimbar por cima — e o selo mais firme (o mais
perto do tempo) fica. O clique pedido contra o clique feito, por quatro
pessoas no mesmo instante.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 15 em 03](../03-os-45-minigames.md#s3--o-molde--touchpad)
- [O índice da seção](K-o-molde.md) e a [K1](K1-o-molde.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S03_J15",
	"titulo": "O Carimbo",
	"verbo": "Carimbe!",
	"genero": "sabotagem",
	"icone": "touchpad",
	"entradas": [Forja.TOUCHPAD],
	"camera": "fixa",
	"faixa": "MUS_S03_J15",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "madeira",
	"microjogo": {"verbo": "Carimbe!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S03_J15` — até a H05, a sintetizada da seção a 100 bpm;
  com a gerada, 128 bpm ("tempos 1 e 3 pesados").
- **A síncope:** o lingote do centro troca na síncope — as batidas
  `4c + 1,5` e `4c + 3,5` (o "e" do 2 e do 4, contra o peso do 1 e do 3).
- **A vez (o hoqueto):** a síncope `k` é **do dono**: os presentes com
  controle, em rodízio (`k % n`). O lingote tem a moldura na cor do dono e a
  raia dele acende. `Ritmo.simples[dono]`: a síncope dele fica **sem dono**
  (qualquer um pode carimbar).
- **O clique:** `Forja.TOUCHPAD`, a no máximo `JANELA_BOM + 0,05 s` da
  síncope; um clique por jogador por síncope.
  - **O dono** → `julgar_toque`: o selo dele no lingote, com o julgamento.
  - **Os outros:** o julgamento do clique (`Ritmo.julgar`, sem folga) — se
    for BOM ou melhor e **mais firme** que o selo de cima (estritamente
    melhor; sem selo, qualquer BOM), o selo dele vai por cima e **o lingote
    é dele**. Se não, **o carimbo borra**: a próxima síncope dele fica sem
    dono.
  - **Clique fora de qualquer janela** também borra.
- **O lingote** vai, no fim da janela, para a pilha de quem está por cima;
  sem selo, para a escória (de ninguém). O dono que não clicou → nota perdida.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO), do dono:
  `[0, 20, 35, 50]`; o selo por cima de outro: +30. Cada lingote na pilha
  conta 1.
- **A progressão:** `p = t_jogo / duracao`. De 0 a 1/3, duas síncopes por
  compasso. **O pico (1/3 a 2/3), a prensa corre:** toda colcheia fraca é
  síncope (`4c + 0,5`, `1,5`, `2,5`, `3,5`) — o rodízio anda duas vezes mais
  depressa. De 2/3 em diante, duas por compasso. Síncopes de cada um em 90 s:
  ~20 a 100 bpm, ~25 a 128 bpm (e todas as outras para roubar).

## O cenário

`SECAO.montar(self)` (a oficina) e, no meio, a mesa do carimbo:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a mesa | `Kit.caixa(3.0, 0.9, 1.6)`, `#8a5a33` | `(0, 0.45, −1.2)` |
| o lingote | `Kit.caixa(0.9, 0.2, 0.45)`, `#8a8f9e`; a moldura na cor do dono (quatro `Kit.caixa` finas, `Kit.material(cor, 1.2)`) | `(0, 1.0, −1.2)` |
| os selos | `Kit.caixa(0.3, 0.02, 0.3)` na cor de quem carimbou, empilhados (+0,02 m cada); o borrado, `#3a3346` | em cima do lingote, um pouco deslocados |
| os carimbos | um por lugar: haste `Kit.caixa(0.08, 0.8, 0.08)` e cabeça `Kit.caixa(0.35, 0.2, 0.35)` de madeira com a face na cor do lugar | `(−0.9 + 0.6·l, 2.2, −1.2)`; descem até o lingote no clique |
| as pilhas | os lingotes de cada um, `Kit.caixa(0.5, 0.18, 0.25)`, `#8a8f9e`, com o selo dele | `(RAIAS[l] + 0.55·(k % 5) − 1.1, 0.1 + 0.2·(k / 5), −3.2)`; a escória em `x = 0` |
| a raia | `raia(l)` do kit; acende quando a vez é dele | `(RAIAS[l], 0, Z_JOGADOR)` |
| o carimbador | o boneco, olhando a mesa | `(RAIAS[l], 0.05, Z_JOGADOR)` |

Câmera: `camera_pos = Vector3(0, 7.0, 10.5)`, `camera_olhar = Vector3(0, 1.0, -1.4)`.
A cor de cada lugar só nas coisas dele (o selo, a cabeça do carimbo, a
moldura na vez dele, a raia).

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **touchpad (o clique, a feature)** | o carimbo, na síncope |
| vibração | o kit nas notas do dono; o selo por cima: `Forja.sentir(l, "perfeito")` no ladrão e `Forja.sentir(dono, "golpe")` no roubado; o borrão: `Forja.sentir(l, "erro")` |
| barra de luz | `SECAO.piscar` no `toque` e na `falha` do dono |
| alto-falante do dono | **o clique carimba**: `Som.no_controle(l, "carimbo", 0.6)` em todo clique que carimba (o do dono no ótimo e no bom; o do ladrão sempre); perfeito do dono: a nota (o kit); erro: a nota quebrada (o kit) |
| háptica por material | `madeira`, pelo kit |
| gatilho | livre (o R2 Off) |
| som na TV | a nota do dono (o kit); `carimbo` a cada selo; `golpe` no selo por cima; `falha` baixo no borrão; `tique` quando o lingote vai para a pilha |

## A falha

O carimbo borra e o lingote fica sem dono: um selo escuro, torto, no lugar
do selo; o lingote vai para a escória se ninguém carimbar por cima; o dono
faz `emote-no`. O ladrão que borrou vê a próxima síncope dele passar sem
dono.

## O fim e o vencedor

90 s (a F03). `vencedor()`: mais lingotes na pilha; empate pelos pontos,
depois pelo lugar.

## Com menos de quatro

O rodízio é dos presentes: com dois, cada um tem uma síncope sim, outra não.
Sozinho, todas são dele e não há de quem roubar. **O controle que cai:** ele
sai do rodízio; a síncope dele em curso fica sem dono (sem erro).

## O robô

Carimba na síncope dele (ou 200 ms atrasado). Tenta pôr o selo por cima em
uma de cada sete síncopes dos outros (as de `(k + l) % 7 == 0`), 30 ms
depois da batida — e, como o dono quase sempre carimbou no perfeito, quase
sempre borra: o robô aprende o preço do roubo.

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo or _sinc.is_empty() or bool(_sinc.get("robo_%d" % l, false)):
		return
	var alvo := Ritmo.t_da_batida(float(_sinc.b))
	var agora := Ritmo.t_musica()
	if int(_sinc.dono) == l:
		if not _sinc.has("mira"):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			_sinc["mira"] = 0.0 if Forja.robo_acerta() else 0.20
		if agora >= alvo + float(_sinc.mira):
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
			_sinc["robo_%d" % l] = true
	elif (int(_sinc.k) + l) % 7 == 0 and agora >= alvo + 0.03:
		if Forja.robo_acerta():
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
		_sinc["robo_%d" % l] = true
```

## Os ganchos

`godot/scripts/minigames/s03/o_carimbo.gd`:

```gdscript
extends Minigame
## O Carimbo (S03_J15). Na mesa do centro, o lingote troca na síncope (o "e"
## do 2 e do 4). Cada síncope é da vez de um (o rodízio): o clique do touchpad
## do dono põe o selo dele. Os outros podem carimbar por cima — o selo mais
## firme (o julgamento estritamente melhor) fica e leva o lingote; o que não é
## mais firme borra, e a próxima vez de quem borrou fica sem dono. No meio, a
## prensa corre: toda colcheia fraca é síncope.
##
## A falha: o carimbo borra e o lingote fica sem dono.
## O vencedor: mais lingotes com o seu selo.
## O alto-falante do dono: o carimbo em todo clique que carimba, a nota no perfeito.
## O registro mede: o clique do dono na síncope (o kit) e os cliques de
## todos por cima (a linha `entrada`: de quem, com que julgamento, se ficou).
## O robô: carimba na vez dele; tenta por cima em uma de sete, e quase sempre borra.
## Com menos de quatro: o rodízio é dos presentes.
## A régua: "Carimbe!" e o touchpad bastam; sem a tela, a nota do dono na TV
## diz de quem é a vez; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

# (a FICHA vem aqui)

const BATIDA_DA_PRIMEIRA_NOTA := 4.0
const PONTOS := [0, 20, 35, 50]
const POR_CIMA := 30
const FOLGA := 0.05
const LINGOTE := Vector3(0, 1.0, -1.2)

var j := {}
var _sinc: Dictionary = {}  ## a síncope em curso: {k, b, dono, n, topo, melhor, clicou: {}, selos}
var _k := 0
var _escoria := 0
var _lingote: Node3D
var _moldura: Array = []
var _selos: Array = []  ## os nós dos selos em cima do lingote em curso
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 7.0, 10.5)
	camera_olhar = Vector3(0, 1.0, -1.4)
	SECAO.montar(self)
	var madeira := Kit.material(Color("#8a5a33"), 0.0, 0.85)
	Kit.caixa(self, Vector3(3.0, 0.9, 1.6), Vector3(0, 0.45, -1.2), madeira)
	_lingote = Kit.caixa(self, Vector3(0.9, 0.2, 0.45), LINGOTE, Kit.material(Color("#8a8f9e"), 0.0, 0.7))
	for lado in [Vector3(0, 0, 0.25), Vector3(0, 0, -0.25), Vector3(0.47, 0, 0), Vector3(-0.47, 0, 0)]:
		var tam := Vector3(0.98, 0.06, 0.04) if lado.x == 0.0 else Vector3(0.04, 0.06, 0.54)
		_moldura.append(Kit.caixa(_lingote, tam, lado, Kit.material(Color.WHITE, 1.2)))
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var carimbo := Node3D.new()
		carimbo.position = Vector3(-0.9 + 0.6 * l, 2.2, -1.2)
		add_child(carimbo)
		Kit.caixa(carimbo, Vector3(0.08, 0.8, 0.08), Vector3(0, 0.4, 0), madeira)
		Kit.caixa(carimbo, Vector3(0.35, 0.2, 0.35), Vector3.ZERO, madeira)
		Kit.caixa(carimbo, Vector3(0.3, 0.03, 0.3), Vector3(0, -0.11, 0), Kit.material(Forja.cor_do_lugar(l), 0.0, 0.8))
		maos_livres(p)
		p.position = Vector3(RAIAS[l], 0.05, Z_JOGADOR)
		p.olhar_para(Vector3(0, 0, -1.2))
		j[l] = {"n": 0, "lingotes": 0, "borrado": false, "carimbo": carimbo}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _no_pico() -> bool:
	var p := t_jogo / maxf(duracao, 1.0)
	return p >= 1.0 / 3.0 and p < 2.0 / 3.0


## A próxima síncope depois da batida `desde`.
func _proxima_sincope(desde: float) -> float:
	var passo := 1.0 if _no_pico() else 2.0
	var k := floorf((desde - 1.5) / passo) + 1.0
	return maxf(k * passo + 1.5, BATIDA_DA_PRIMEIRA_NOTA + 1.5)


## A síncope nova, com o dono do rodízio (sem dono se ele borrou ou está na partitura simples).
func _nova_sincope(desde: float) -> void:
	var b := _proxima_sincope(desde)
	var roda: Array = []
	for l in presentes():
		if conectado(l):
			roda.append(l)
	var dono := -1
	if not roda.is_empty():
		dono = roda[_k % roda.size()]
		if bool(j[dono].borrado) or Ritmo.simples[dono]:
			if bool(j[dono].borrado):
				Forja.evento("entrada", dono + 1, {"o": "clique", "perdeu_a_vez": true})
			j[dono].borrado = false
			dono = -1
	_sinc = {"k": _k, "b": b, "dono": dono, "n": -1, "topo": -1, "melhor": -1, "clicou": {}}
	_k += 1
	if dono >= 0:
		_sinc.n = int(j[dono].n)
		j[dono].n = int(j[dono].n) + 1
		nova_nota(dono, int(_sinc.n), Ritmo.t_da_batida(b))
	for s in _selos:
		(s as Node).queue_free()
	_selos.clear()
	var cor := Forja.cor_do_lugar(dono) if dono >= 0 else Color("#8a8f9e")
	for m in _moldura:
		var mat: StandardMaterial3D = (m as MeshInstance3D).material_override
		mat.albedo_color = cor
		mat.emission = cor
	for l in presentes():
		acender_raia(l, 1.0 if l == dono else 0.0)


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			Forja.evento("entrada", l + 1, {"o": "sensores", "toque": false})
			acabou[l] = true
	_nova_sincope(BATIDA_DA_PRIMEIRA_NOTA)


func jogar(_dt: float) -> void:
	SECAO.voltar_a_luz(self)
	if _sinc.is_empty():
		return
	var agora := Ritmo.t_musica()
	var alvo := Ritmo.t_da_batida(float(_sinc.b))
	var janela := Ritmo.JANELA_BOM + FOLGA
	for l in presentes():
		if acabou[l] or not conectado(l) or not Forja.apertou(l, Forja.TOUCHPAD):
			continue
		if absf(agora - alvo) > janela or _sinc.clicou.has(l):
			_borrar(l, "fora da janela")
			continue
		_sinc.clicou[l] = true
		_carimbo_desce(l)
		if l == int(_sinc.dono):
			julgar_toque(l, alvo, int(_sinc.n))
		else:
			_por_cima(l, Ritmo.julgar(l, agora, alvo))
	if agora > alvo + janela:
		var dono: int = _sinc.dono
		if dono >= 0 and not _sinc.clicou.has(dono) and conectado(dono):
			nota_perdida(dono, int(_sinc.n))
		_fechar()
		_nova_sincope(float(_sinc.b))


## Um selo por cima: fica se for BOM ou melhor e estritamente mais firme que o de cima.
func _por_cima(l: int, julgamento: int) -> void:
	var ficou := julgamento >= Ritmo.BOM and julgamento > int(_sinc.melhor)
	Forja.evento("entrada", l + 1, {"o": "clique", "por_cima_de": int(_sinc.topo), "dono": int(_sinc.dono),
		"julgamento": Ritmo.NOMES_DO_JULGAMENTO[julgamento], "ficou": ficou})
	if not ficou:
		_borrar(l, "não foi mais firme")
		return
	var antes: int = _sinc.topo
	_selar(l, julgamento)
	marcar(l, POR_CIMA)
	Forja.sentir(l, "perfeito")
	Som.no_controle(l, "carimbo", 0.6)
	Som.tocar("golpe", LINGOTE, -4.0)
	if antes >= 0 and antes != l:
		Forja.sentir(antes, "golpe")


func _borrar(l: int, porque: String) -> void:
	j[l].borrado = true
	Forja.evento("entrada", l + 1, {"o": "clique", "borrou": porque})
	Forja.sentir(l, "erro")
	Som.tocar("falha", LINGOTE, -12.0)


## O selo do lugar vai para cima do lingote (e o lingote é dele, por enquanto).
func _selar(l: int, julgamento: int) -> void:
	_sinc.topo = l
	_sinc.melhor = julgamento
	var selo := Kit.caixa(_lingote, Vector3(0.3, 0.02, 0.3), Vector3(0.06 * (_selos.size() - 1), 0.11 + 0.02 * _selos.size(), 0),
		Kit.material(Forja.cor_do_lugar(l), 0.0, 0.8))
	_selos.append(selo)
	Som.tocar("carimbo", LINGOTE, 0.0)


func _carimbo_desce(l: int) -> void:
	var c: Node3D = j[l].carimbo
	var tw := c.create_tween()
	tw.tween_property(c, "position:y", LINGOTE.y + 0.25, 0.06)
	tw.tween_property(c, "position:y", 2.2, 0.12)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	marcar(l, PONTOS[julgamento])
	if julgamento > int(_sinc.melhor):
		_selar(l, julgamento)
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "carimbo", 0.6)
	SECAO.piscar(self, l, julgamento)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	# o carimbo do dono borra: um selo escuro e torto, e o lingote fica sem dono
	var borrao := Kit.caixa(_lingote, Vector3(0.3, 0.02, 0.3), Vector3(-0.1, 0.11 + 0.02 * _selos.size(), 0.05),
		Kit.material(Color("#3a3346"), 0.0, 0.9))
	borrao.rotation.y = 0.5
	_selos.append(borrao)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	SECAO.piscar(self, l, Ritmo.ERRO)


## A janela fechou: o lingote vai para a pilha de quem está por cima (ou para a escória).
func _fechar() -> void:
	var topo: int = _sinc.topo
	var k := 0
	var x := 0.0
	if topo >= 0 and not treinando:
		j[topo].lingotes = int(j[topo].lingotes) + 1
		k = int(j[topo].lingotes) - 1
		x = RAIAS[topo]
	else:
		_escoria += 1
		k = _escoria - 1
	var cor := Forja.cor_do_lugar(topo) if topo >= 0 else Color("#3a3346")
	var pilha := Kit.caixa(self, Vector3(0.5, 0.18, 0.25), LINGOTE, Kit.material(Color("#8a8f9e"), 0.0, 0.7))
	Kit.caixa(pilha, Vector3(0.2, 0.02, 0.15), Vector3(0, 0.1, 0), Kit.material(cor, 0.0, 0.8))
	var ate := Vector3(x + 0.55 * (k % 5) - 1.1, 0.1 + 0.2 * int(k / 5.0), -3.2)
	var tw := pilha.create_tween()
	tw.tween_property(pilha, "position", ate, 0.3).set_trans(Tween.TRANS_QUAD)
	Som.tocar("tique", ate, -8.0)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].lingotes) != int(j[b].lingotes):
		return int(j[a].lingotes) > int(j[b].lingotes)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Lingotes: %d" % int(j[lugar].lingotes)
	return super(lugar)
```

## O que o registro mede

- O kit: a `nota` e o `toque` do dono em cada síncope (o clique pedido
  contra o feito, no tempo).
- A linha `entrada`: cada clique por cima (por cima de quem, o julgamento,
  se ficou), cada borrão (por quê) e cada vez perdida por borrão. Com quatro
  cliques de touchpad no mesmo instante, um clique que não chega, ou que
  chega no controle vizinho, aparece aqui.

## Armadilhas

- **O selo por cima é estritamente mais firme:** empate fica com quem
  carimbou primeiro. O dono também só fica por cima se for mais firme que um
  selo que já estava lá (o ladrão que chegou antes, no perfeito, ganha dele).
- **O clique do ladrão não passa pelo kit** (não é nota dele): nada de
  `julgar_toque` para ele; `Ritmo.julgar` direto e a linha `entrada`.
- **O borrão tira a próxima vez** (o `_nova_sincope` confere): uma vez só.
- **A pilha é da janela fechada**, não do clique: quem estava por cima no
  fim leva.
- **`acender_raia`** marca a vez do dono (a raia do kit): as luzinhas e a
  barra de luz não mudam.
- **Material novo a cada selo e pilha:** uns 200 no minigame; se a prancha
  mostrar menos de 55 fps, guarde um material por lugar.

## Pronto quando

O Carimbo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o bom quase não rouba, o ruim borra); o cabo que cai
e volta tira o lugar do rodízio e o devolve; o fim tem sempre vencedor;
`bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh` passa
com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S03_J15 (K5): o Carimbo abre pelo catálogo; o rodízio dá a vez a cada um;
## o clique simulado do dono chega julgado; os lingotes vão para as pilhas.
func _prova_do_carimbo() -> void:
	jogo._entrar_na_sala("S03_J15", false)
	await _quadros(2)
	var mg = jogo.sala
	_esperar(mg is Minigame and mg.id == "S03_J15", "S03_J15: abriu pelo catálogo")
	if not mg is Minigame:
		return
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	_esperar(int(mg._sinc.get("dono", -9)) == 0, "S03_J15: a primeira síncope é do P1")
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 40000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "S03_J15: fechou")
	if not is_instance_valid(mg):
		return
	var donos := 0
	var pilhas := 0
	for l in 4:
		donos += int(mg.contagem[l][2]) + int(mg.contagem[l][3])
		pilhas += int(mg.j[l].lingotes)
	_esperar(donos >= 2 and pilhas >= 1, "S03_J15: os donos carimbaram (%d) e os lingotes foram às pilhas (%d)" % [donos, pilhas])
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S03_J15: de volta ao salão")
```

(Na prova sem janela, o tempo de jogo anda ~16 vezes mais depressa que a
música: cabem umas quatro síncopes. Por isso a checagem pede dois donos,
não os quatro.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S03_J15` com quatro: a
síncope se sente contra o peso do 1 e do 3, o clique do touchpad carimba no
controle, o selo por cima dá grito, o borrão pune o afobado, e a prensa do
meio é o caos.

## Ao terminar

- Catálogo: `"S03_J15": preload("res://scripts/minigames/s03/o_carimbo.gd")`
  em `MINIGAMES` e na lista da S03.
- `traducoes.gd`: `"O Carimbo": "The Stamp"`, `"Carimbe!": "Stamp!"`; em
  `EN_PADROES`, `["^Lingotes: (\\d+)$", "Ingots: $1"]` se ainda não estiver lá
  (a I5 põe).
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a K5 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: O Carimbo — o clique na síncope, e o selo mais firme por cima`
