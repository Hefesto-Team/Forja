# K5 — O Carimbo

**Sprint:** K · **Slot:** S03_J15 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, H07, G10, G14, G15, K1 (o `secao.gd`)

## Por quê

Carimbar é o clique do touchpad na síncope. O lingote do centro é da vez de um, mas qualquer um pode carimbar por
cima, e o selo mais firme (o mais perto do tempo) fica. Quando o ladrão fica por cima, o lingote pula para a pilha
dele com os dois selos à mostra. O jogo de hoje já é bom (nota 4); esta ficha o passa para o kit e a oficina da
seção, dá o grito ao roubo e põe a síncope de ouro na reta.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [O índice da seção](K-o-molde.md) (as convenções do toque)
- [K1 — O Molde](K1-o-molde.md) (o `secao.gd` inteiro, a função `momento` e o kit que a seção usa)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão e o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s03/o_carimbo.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `"S03_J15"` em `MINIGAMES` e na lista `minigames` da S03, depois do `"S03_J14"` | **da seção** |
| `godot/scripts/traducoes.gd` | `"O Carimbo"`, `"Carimbe!"` e o placar `Lingotes:` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_carimbo()` e a linha `"S03_J15"` no `match` de `_prova_da_ficha` | **de todos** |

O `secao.gd` é da K1: esta ficha só chama. Se a K1 ainda não entrou, esta espera. O `o_carimbo.gd.uid` sai do import
(`"$GODOT" --headless --path godot --import --quit`) e entra no commit.

Commit (sem trailer): `feat(carimbo): o selo mais perto do tempo fica, o roubo com estrondo e a síncope de ouro`.

### O que muda de hoje (a ficha velha)

| antes | depois |
| --- | --- |
| o selo mais firme é o julgamento estritamente melhor (dois perfeitos empatam) | o selo mais perto do tempo, em ms, fica |
| o borrão só tira a próxima vez | tira a próxima vez e seca o carimbo por `SECAO.queda(l, 1)` tempos: os cliques somem em silêncio |
| o roubo sem momento | o `selo_por_cima`: o lingote pula para a pilha do ladrão, a prensa bate 2 vezes, degrau golpe |
| a mesa `#8a5a33`, o lingote `#8a8f9e`, o borrão `#3a3346`, a moldura `Color.WHITE` | a mesa em `OXIDO_BRILHO`, o lingote em `GRAFITE`, o borrão em `SOMBRA`, a moldura no neon do dono |
| a câmera `(0; 7,0; 10,5)` | `(0; 11,5; 8,1)`, olhando `(0; 0,8; −0,9)` |
| a prensa corre no pico do kit | de 30 a 60 s, decidida pela batida da síncope |
| nada na reta | a síncope de ouro: a cada compasso das últimas 16 batidas, uma sem dono que vale 3 |
| o robô rouba 30 ms depois e quase sempre borra | o robô rouba 10 ms antes, em uma de sete síncopes dos outros, e fica por cima mais ou menos metade das vezes |

### `godot/scripts/minigames/s03/o_carimbo.gd` (novo, o arquivo inteiro)

```gdscript
extends Minigame
## O Carimbo (S03_J15). Na mesa do centro, o lingote troca na síncope (o "e" do
## 2 e do 4). Cada síncope é da vez de um (o rodízio): o clique do touchpad do
## dono põe o selo dele. Os outros podem carimbar por cima: o selo mais perto do
## tempo fica e leva o lingote; o que não é mais perto borra, a próxima vez de
## quem borrou fica sem dono e o carimbo dele seca. De 30 a 60 s, a prensa
## corre: toda colcheia fraca é síncope. Nas últimas 16 batidas, a síncope de
## ouro, sem dono, vale 3.
##
## A falha: o carimbo borra.
## O vencedor: mais lingotes na pilha.
## O alto-falante do dono: o carimbo em todo clique que carimba, o tropeço no
## lingote roubado, a nota no perfeito.
## O registro mede: o clique do dono na síncope (o kit) e os cliques de todos por
## cima (a linha `entrada`: de quem, a quantos ms, se ficou); o `momento`
## `selo_por_cima` e o `reta`.
## O robô: carimba na vez dele; tenta por cima em uma de sete síncopes dos outros.
## Com menos de quatro: o rodízio é dos presentes.
## A régua: "Carimbe!" e o touchpad bastam; sem a tela, a nota do dono na TV e
## o pulso na mão dele (na primeira frase) dizem de quem é a vez; nada pergunta
## pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

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
	"sensacoes": ["toque", "acerto", "perfeito", "erro", "golpe"],
	"material": "madeira",
	"microjogo": {"verbo": "Carimbe!", "segundos": 6.0},
	"gesto": "attack-melee-right",
}

const CAMERA_POS := Vector3(0, 11.5, 8.1)
const CAMERA_OLHAR := Vector3(0, 0.8, -0.9)
const PONTOS := [0, 20, 35, 50]
const POR_CIMA := 30
const OURO_VALE := 3
const FOLGA := 0.05
const LINGOTE := Vector3(0, 1.0, -1.2)
const PRENSA_Y := 3.2
const ESCORIA := Vector3(3.4, 1.2, -1.4)
## A prensa corre, em s de música (pela batida da síncope): toda colcheia fraca.
const PRENSA_DE := 30.0
const PRENSA_ATE := 60.0
## A primeira frase: as 32 batidas depois da primeira nota (o pulso na mão do dono).
const FRASE := 32.0

var j := {}
var _sinc: Dictionary = {}  ## a síncope em curso
var _k := 0
var _escoria := 0
var _lingote: MeshInstance3D
var _moldura: Array = []
var _coroa: Node3D
var _prensa: MeshInstance3D
var _selos: Array = []  ## os selos e borrões da síncope em curso
var _selo: Array = []  ## o material do selo de cada lugar
var _moldura_acesa: Array = []
var _apagada: StandardMaterial3D
var _borrao: StandardMaterial3D
var _metal: StandardMaterial3D
var _ouro: StandardMaterial3D
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
# o robô guarda o que decidiu nos arrays dele: nunca mexe no estado do minigame
var _robo_k := [-1, -1, -1, -1]
var _robo_mira_k := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	SECAO.montar(self, CAMERA_POS, CAMERA_OLHAR)
	var madeira := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)
	_metal = Kit.material(Tema.GRAFITE, 0.0, 0.6)
	_ouro = Kit.material(Tema.SECAO[3], 0.0, 0.6)
	_apagada = Kit.material(Tema.GRAFITE, 0.0, 0.8)
	_borrao = Kit.material(Tema.SOMBRA, 0.0, 0.9)
	for l in 4:
		_selo.append(Kit.material(Tema.JOGADOR[l], 0.6, 0.8, l))
		_moldura_acesa.append(Tema.neon(Tema.JOGADOR[l], 1.2, l))
	SECAO.peca(self, "factory-kit/machine", "column", Vector3(0, 0, -2.5), 0.0, 2.0)
	SECAO.peca(self, "factory-kit/conveyor-long", "table", Vector3(-3.4, 0, -1.2), PI * 0.5, 2.0)
	SECAO.peca(self, "factory-kit/box-large", "chest", Vector3(3.4, 0, -1.4), 0.0, 2.0)
	Kit.caixa(self, Vector3(3.0, 0.9, 1.6), Vector3(0, 0.45, -1.2), madeira)
	_prensa = Kit.caixa(self, Vector3(2.6, 0.25, 0.6), Vector3(0, PRENSA_Y, -1.2), _metal)
	_lingote = Kit.caixa(self, Vector3(0.9, 0.2, 0.45), LINGOTE, _metal)
	for lado in [Vector3(0, 0, 0.25), Vector3(0, 0, -0.25), Vector3(0.47, 0, 0), Vector3(-0.47, 0, 0)]:
		var tam := Vector3(0.98, 0.06, 0.04) if lado.x == 0.0 else Vector3(0.04, 0.06, 0.54)
		_moldura.append(Kit.caixa(_lingote, tam, lado, _apagada))
	_coroa = Node3D.new()
	_coroa.position = Vector3(0, 0.13, 0.2)
	_lingote.add_child(_coroa)
	var etiqueta := Kit.chapado(Tema.ETIQUETA)
	Kit.caixa(_coroa, Vector3(0.36, 0.05, 0.04), Vector3.ZERO, etiqueta)
	for x in [-0.15, 0.0, 0.15]:
		Kit.caixa(_coroa, Vector3(0.05, 0.12, 0.04), Vector3(x, 0.08, 0), etiqueta)
	_coroa.visible = false
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var carimbo := Node3D.new()
		carimbo.position = Vector3(-0.9 + 0.6 * l, 2.2, -1.2)
		add_child(carimbo)
		Kit.caixa(carimbo, Vector3(0.08, 0.8, 0.08), Vector3(0, 0.4, 0), madeira)
		Kit.caixa(carimbo, Vector3(0.35, 0.2, 0.35), Vector3.ZERO, madeira)
		Kit.caixa(carimbo, Vector3(0.3, 0.03, 0.3), Vector3(0, -0.11, 0), _selo[l])
		maos_livres(p)
		p.position = Vector3(RAIAS[l], 0.05, Z_JOGADOR)
		p.olhar_para(Vector3(0, 0, -1.2))
		j[l] = {"n": 0, "lingotes": 0, "pilha": 0, "duplos": 0, "borrado": false, "seca_ate": -99.0, "carimbo": carimbo}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A primeira batida `fase + k·passo` estritamente depois de `desde`.
static func _depois(desde: float, passo: float, fase: float) -> float:
	return (floorf((desde - fase) / passo) + 1.0) * passo + fase


## A próxima síncope depois da batida `desde`: o "e" do 2 e do 4; de 30 a 60 s
## (pela batida da síncope), toda colcheia fraca.
func _proxima_sincope(desde: float) -> float:
	var b := _depois(desde, 2.0, 1.5)
	var t := Ritmo.t_da_batida(b)
	if t >= PRENSA_DE and t < PRENSA_ATE:
		b = _depois(desde, 1.0, 0.5)
	return maxf(b, BATIDA_DA_PRIMEIRA_NOTA + 1.5)


## O líder: quem tem mais lingotes, sozinho. Empate: ninguém.
func _lider() -> int:
	var melhor := -1
	var n := -1
	var empate := false
	for l in presentes():
		var v := int(j[l].lingotes)
		if v > n:
			n = v
			melhor = l
			empate = false
		elif v == n:
			empate = true
	return -1 if empate or n <= 0 else melhor


## A síncope nova, com o dono do rodízio (sem dono se ele borrou, se está na
## partitura simples, ou se é a síncope de ouro).
func _nova_sincope(desde: float) -> void:
	var b := _proxima_sincope(desde)
	var ouro := SECAO.na_reta(self) and is_equal_approx(fmod(b, 4.0), 3.5)
	var roda: Array = []
	for l in presentes():
		if conectado(l):
			roda.append(l)
	var dono := -1
	if not roda.is_empty() and not ouro:
		dono = roda[_k % roda.size()]
		if bool(j[dono].borrado) or Ritmo.simples[dono]:
			if bool(j[dono].borrado):
				anotar("entrada", dono, {"o": "clique", "perdeu_a_vez": true})
			j[dono].borrado = false
			dono = -1
	_sinc = {"k": _k, "b": b, "dono": dono, "ouro": ouro, "n": -1, "topo": -1, "melhor_ms": 99.0,
		"delta_dono": 99.0, "selo_do_dono": false, "pulsou": false, "clicou": {}}
	_k += 1
	if dono >= 0:
		_sinc.n = int(j[dono].n)
		j[dono].n = int(j[dono].n) + 1
		nova_nota(dono, int(_sinc.n), Ritmo.t_da_batida(b))
	for s in _selos:
		(s as Node).queue_free()
	_selos.clear()
	_lingote.material_override = _ouro if ouro else _metal
	_coroa.visible = dono >= 0 and dono == _lider()


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			anotar("entrada", l, {"o": "sensores", "toque": false})
			acabou[l] = true
	_nova_sincope(BATIDA_DA_PRIMEIRA_NOTA)


func jogar(_dt: float) -> void:
	SECAO.pico(self)
	if _sinc.is_empty():
		return
	var agora := Ritmo.t_musica()
	var alvo := Ritmo.t_da_batida(float(_sinc.b))
	var janela := Ritmo.JANELA_BOM + FOLGA
	_mostrar(agora, alvo)
	var dono: int = _sinc.dono
	if not bool(_sinc.pulsou) and agora >= alvo and dono >= 0 and float(_sinc.b) < BATIDA_DA_PRIMEIRA_NOTA + FRASE:
		_sinc.pulsou = true
		# a síncope na mão, só na primeira frase, só no dono; sem a háptica (o motor do dono
		# vibrando, ou sem o módulo: −1), o `toque` no motor fraco no lugar dela
		if Forja.som_haptica(dono, "pulso", "pulso", 0.35) < 0:
			Forja.sentir(dono, "toque", 40)
	for l in presentes():
		if acabou[l] or not conectado(l) or not Forja.apertou(l, Forja.TOUCHPAD):
			continue
		if Ritmo.batida() < float(j[l].seca_ate):
			continue  # o carimbo ainda seca: o clique some, em silêncio
		if absf(agora - alvo) > janela or _sinc.clicou.has(l):
			_borrar(l, "fora da janela")
			continue
		_sinc.clicou[l] = true
		_carimbo_desce(l)
		var delta := absf(agora - alvo)
		if l == dono:
			_sinc.delta_dono = delta
			julgar_toque(l, alvo, int(_sinc.n))
		else:
			_por_cima(l, Ritmo.julgar(l, agora, alvo), delta)
	if agora > alvo + janela:
		if dono >= 0 and not _sinc.clicou.has(dono) and conectado(dono):
			nota_perdida(dono, int(_sinc.n))
		_fechar()
		_nova_sincope(float(_sinc.b))


## A moldura acende no neon do dono 1 aviso antes da síncope (o Faro), com a raia dele.
func _mostrar(agora: float, alvo: float) -> void:
	var dono: int = _sinc.dono
	var mat: Material = _apagada
	if bool(_sinc.ouro):
		mat = _ouro
	elif dono >= 0 and agora >= alvo - SECAO.aviso_s(dono):
		mat = _moldura_acesa[dono]
	for m in _moldura:
		(m as MeshInstance3D).material_override = mat
	for l in presentes():
		acender_raia(l, 1.0 if l == dono and mat != _apagada else 0.0)


## Um selo por cima: fica se for bom ou melhor e estritamente mais perto do tempo
## que o de cima. Na síncope de ouro, quem não fica não borra.
func _por_cima(l: int, julgamento: int, delta: float) -> void:
	var ouro := bool(_sinc.ouro)
	var ficou := julgamento >= Ritmo.BOM and delta < float(_sinc.melhor_ms)
	anotar("entrada", l, {"o": "clique", "por_cima_de": int(_sinc.topo), "dono": int(_sinc.dono), "ouro": ouro,
		"julgamento": Ritmo.NOMES_DO_JULGAMENTO[julgamento], "ms": int(delta * 1000.0), "ficou": ficou})
	if not ficou:
		if not ouro:
			_borrar(l, "não foi mais perto")
		return
	_selar(l, delta, true)
	marcar(l, POR_CIMA)
	Forja.sentir(l, "perfeito")
	Som.no_controle(l, "carimbo", 0.6)
	Som.tocar("golpe", LINGOTE, -4.0)
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.3)


## O carimbo borra: a mancha na mesa, o selo rachado na mão, a próxima vez sem
## dono e o carimbo que seca por `SECAO.queda(l, 1)` tempos (o Fôlego).
func _borrar(l: int, porque: String) -> void:
	j[l].borrado = true
	j[l].seca_ate = Ritmo.batida() + SECAO.queda(l, 1.0)
	anotar("entrada", l, {"o": "clique", "borrou": porque})
	var mancha := Kit.caixa(self, Vector3(0.3, 0.02, 0.3), Vector3(-0.9 + 0.6 * l, 0.91, -0.75), _borrao)
	mancha.rotation.y = 0.5
	_selos.append(mancha)
	Som.tocar("falha", LINGOTE, -12.0)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.4)
	_rachado(l)


## O selo rachado: dois `erro` de 30 ms (0,7/0,3, a tabela da F05), o segundo 60 ms
## depois do primeiro. O `Forja.vibrar` só o forja.gd chama.
func _rachado(l: int) -> void:
	Forja.sentir(l, "erro", 30)
	await get_tree().create_timer(0.06).timeout
	Forja.sentir(l, "erro", 30)


## O selo do lugar no lingote. Por cima: o lingote é dele, por enquanto. Por
## baixo (o dono que chegou depois e mais longe): aparece pela borda.
func _selar(l: int, delta: float, por_cima: bool) -> void:
	var i := _selos.size()
	var pos := Vector3(0.06 * (i % 3) - 0.06, 0.11 + 0.02 * i, 0)
	if por_cima:
		_sinc.topo = l
		_sinc.melhor_ms = delta
	else:
		pos = Vector3(-0.1, 0.105, 0.06)
	_selos.append(Kit.caixa(_lingote, Vector3(0.3, 0.02, 0.3), pos, _selo[l]))
	Som.tocar("carimbo", LINGOTE, 0.0)


func _carimbo_desce(l: int) -> void:
	var c: Node3D = j[l].carimbo
	var tw := c.create_tween()
	tw.tween_property(c, "position:y", LINGOTE.y + 0.25, 0.06)
	tw.tween_property(c, "position:y", 2.2, 0.12)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	marcar(l, PONTOS[julgamento])
	var delta := float(_sinc.delta_dono)
	_sinc.selo_do_dono = true
	_selar(l, delta, delta < float(_sinc.melhor_ms))
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "carimbo", 0.6)
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.3)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	# o carimbo do dono borra no lingote: um selo escuro e torto; o lingote fica para quem vier por cima
	var borrao := Kit.caixa(_lingote, Vector3(0.3, 0.02, 0.3), Vector3(-0.1, 0.11 + 0.02 * _selos.size(), 0.05), _borrao)
	borrao.rotation.y = 0.5
	_selos.append(borrao)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)


## A janela fechou: o lingote vai para a pilha de quem está por cima, ou para a
## caixa da escória. Roubado (o topo não é o dono): o selo por cima.
func _fechar() -> void:
	var topo: int = _sinc.topo
	var dono: int = _sinc.dono
	var ouro := bool(_sinc.ouro)
	var roubado := topo >= 0 and dono >= 0 and topo != dono
	var duplo := roubado and bool(_sinc.selo_do_dono)
	var pilha := Kit.caixa(self, Vector3(0.5, 0.18, 0.25), LINGOTE, _ouro if ouro else _metal)
	var ate := ESCORIA
	if topo >= 0 and not treinando:
		var e: Dictionary = j[topo]
		e.lingotes = int(e.lingotes) + (OURO_VALE if ouro else 1)
		var k := int(e.pilha)
		e.pilha = k + 1
		if duplo:
			e.duplos = int(e.duplos) + 1
			Kit.caixa(pilha, Vector3(0.2, 0.02, 0.15), Vector3(-0.06, 0.1, 0.03), _selo[dono])
		Kit.caixa(pilha, Vector3(0.2, 0.02, 0.15), Vector3(0, 0.105, 0), _selo[topo])
		ate = Vector3(RAIAS[topo] + 0.55 * (k % 5) - 1.1, 0.1 + 0.2 * int(k / 5.0), -3.2)
	else:
		_escoria += 1
	var meio := (LINGOTE + ate) * 0.5 + Vector3(0, 1.2 if roubado else 0.4, 0)
	var batida := 60.0 / Ritmo.bpm
	var dur := batida if roubado else 0.3
	var tw := pilha.create_tween()
	tw.tween_property(pilha, "position", meio, dur * 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(pilha, "position", ate, dur * 0.5).set_ease(Tween.EASE_IN)
	if topo < 0 or treinando:
		tw.tween_callback(pilha.queue_free)  # a escória cai na caixa e some
	Som.tocar("tique", ate, -8.0)
	if ouro and topo >= 0:
		Som.tocar("confirma", LINGOTE, 0.0)
	if roubado and not treinando:
		_selo_por_cima(topo, dono, duplo)


## O selo por cima: o lingote pulou para a pilha do ladrão, a prensa bate 2
## vezes, o dono sente o golpe e ouve o tropeço. Degrau golpe.
func _selo_por_cima(ladrao: int, dono: int, duplo: bool) -> void:
	SECAO.degrau(self, ladrao, "golpe", LINGOTE, Tema.JOGADOR[ladrao])
	Som.tocar("golpe", LINGOTE, -2.0)
	Forja.sentir(dono, "golpe")
	Forja.som_falante(dono, "tropeco", 0.7)
	var pd := jogador(dono)
	if pd:
		pd.gesto("emote-no", 0.5)
	var pl := jogador(ladrao)
	if pl:
		pl.gesto("interact-right", 0.4)
	momento("selo_por_cima", ladrao, LINGOTE, 1.2, {"ladrao": ladrao, "de": dono, "duplo": duplo})
	var quarto := 0.25 * 60.0 / Ritmo.bpm
	var tw := _prensa.create_tween()
	for i in 2:
		tw.tween_property(_prensa, "position:y", PRENSA_Y - 0.4, quarto)
		tw.tween_callback(func() -> void: Som.tocar("carimbo", _prensa.global_position, -2.0, 0.7))
		tw.tween_property(_prensa, "position:y", PRENSA_Y, quarto)


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

### `godot/scripts/minigames/catalogo.gd`

Em `MINIGAMES`: `"S03_J15": preload("res://scripts/minigames/s03/o_carimbo.gd"),`. Na S03 de `SECOES`, acrescente
`"S03_J15"` à lista `minigames`, depois do `"S03_J14"`.

### `godot/scripts/traducoes.gd`

`"O Carimbo": "The Stamp"` e `"Carimbe!": "Stamp!"`. Em `EN_PADROES`: `["^Lingotes: (\\d+)$", "Ingots: $1"]`; se a
linha já estiver lá (a I5 a põe), não a duplique.

## Como se joga

- **A faixa:** `mus_s03_j15`, 128 BPM, Dó# menor ("tempos 1 e 3 pesados"). Até a H05, a sintetizada da seção a 100
  bpm.
- **A síncope:** o lingote do centro troca na síncope, as batidas `4c + 1,5` e `4c + 3,5` (o "e" do 2 e do 4, contra
  o peso do 1 e do 3).
- **A vez (o rodízio):** a síncope `k` é **do dono**: os presentes com controle, em rodízio (`k % n`). A moldura do
  lingote acende no neon do dono e a raia dele acende, 1 aviso (`SECAO.aviso_s`) antes da síncope. Na partitura
  simples (`Ritmo.simples[dono]`), a síncope dele fica **sem dono** (qualquer um pode carimbar).
- **O clique:** `Forja.TOUCHPAD`, dentro de `Ritmo.JANELA_BOM + 0,05 s` da síncope; um clique por jogador por
  síncope.
  - **O dono** → `julgar_toque`: o selo dele no lingote. Fica por cima se for o mais perto do tempo até ali; se um
    ladrão chegou antes e mais perto, o selo do dono fica por baixo, aparecendo pela borda.
  - **Os outros:** o julgamento do clique (`Ritmo.julgar`, sem folga). Bom ou melhor e **estritamente mais perto do
    tempo** (em ms) que o selo de cima (sem selo, qualquer bom): o selo dele vai por cima e **o lingote é dele**. Se
    não, **o carimbo borra**.
  - **O segundo clique na mesma síncope,** e o clique fora de qualquer janela, também borram.
- **O borrão:** uma mancha na mesa; a próxima síncope de quem borrou fica sem dono; e o carimbo dele seca por
  `SECAO.queda(l, 1)` tempos: os cliques nesse tempo somem, sem som e sem borrão.
- **O lingote** vai, no fim da janela, para a pilha de quem está por cima; sem selo, para a caixa da escória (de
  ninguém). O dono que não clicou: nota perdida.
- **O selo por cima:** o lingote de um dono que vai para a pilha de outro. Se o dono carimbou, a pilha mostra os dois
  selos (o selo duplo).
- **Os pontos:** do dono, por julgamento (erro, bom, ótimo, Ressonância), `[0, 20, 35, 50]`; o selo por cima de
  outro, +30. Cada lingote na pilha conta 1.
- **A prensa corre, de 30 a 60 s** (pela batida da síncope): toda colcheia fraca é síncope (`4c + 0,5`, `1,5`, `2,5`,
  `3,5`), e o rodízio anda duas vezes mais depressa.
- **A síncope de ouro, nas últimas 16 batidas:** a síncope `4c + 3,5` de cada compasso é de ouro: sem dono, o lingote
  e a moldura em mostarda (`SECAO[3]`), e vale 3 lingotes. Os quatro clicam juntos; fica o mais perto do tempo; quem
  não fica, não borra.
- **A coroa:** o lingote cujo dono é o líder (mais lingotes, sozinho) leva a coroa gravada em `ETIQUETA`.
- **O fim** é do kit, em tempo de música: 90 s.
- **O vencedor:** mais lingotes; no empate, os pontos; depois, o lugar.
- **Com menos de quatro:** o rodízio é dos presentes; com dois, cada um tem uma síncope sim, outra não. Sozinho,
  todas são dele, e não há de quem roubar. **O controle que cai:** ele sai do rodízio; a síncope dele em curso fica
  sem nota perdida. **Sem touchpad:** o lugar acaba no `iniciar_jogo()`, sem erro, e grava `entrada` `sensores`
  `toque: false`.

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if _sinc.is_empty() or int(_sinc.k) == int(_robo_k[l]) or Ritmo.batida() < float(j[l].seca_ate):
		return
	var alvo := Ritmo.t_da_batida(float(_sinc.b))
	var agora := Ritmo.t_musica()
	if int(_robo_mira_k[l]) != int(_sinc.k):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		_robo_mira_k[l] = int(_sinc.k)
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.20
	if int(_sinc.dono) == l or bool(_sinc.ouro):
		if agora >= alvo + float(_robo_mira[l]):
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
			_robo_k[l] = int(_sinc.k)
	elif (int(_sinc.k) + l) % 7 == 0 and agora >= alvo - 0.01 + float(_robo_mira[l]):
		# o roubo: 10 ms antes da síncope, em uma de cada sete dos outros
		Forja.robo_apertar(l, Forja.TOUCHPAD, 0.05)
		_robo_k[l] = int(_sinc.k)
```

O roubo do robô cai no quadro de 16,7 ms em que a síncope chega ou no anterior; o dono, no quadro em que ela chega.
Mais ou menos metade dos roubos fica por cima e metade borra: o robô mostra antes de 20 s que dá para carimbar por
cima, e o preço.

## A cena

- **A câmera:** fixa, lente da arena (35 mm, 37,8°), mais alta e mais perto da mesa que a da seção:
  `camera_pos = Vector3(0, 11.5, 8.1)`, `camera_olhar = Vector3(0, 0.8, -0.9)`. A mesa, as pilhas e os quatro
  carimbadores na tela. Não corta. Na prensa que corre (o pico do kit), recua 10 % pelo `SECAO.pico`.
- **A luz:** a da seção (petróleo, `SECAO.montar`), com a chave a ×1,2 no pico. No selo por cima, o tremor do golpe
  (0,02 m por 1 batida).
- **As peças Kenney:**
  - `factory-kit/machine`, escala 2,0, em `(0; 0; −2,5)`: o corpo da prensa, atrás da mesa (reserva: `column`);
  - `factory-kit/conveyor-long`, escala 2,0, girada 90°, em `(−3,4; 0; −1,2)`: a esteira que traz os lingotes (reserva:
    `table`);
  - `factory-kit/box-large`, escala 2,0, em `(3,4; 0; −1,4)`: a caixa da escória (reserva: `chest`).
- **A mesa:** `Kit.caixa(3,0 × 0,9 × 1,6)` em `(0; 0,45; −1,2)`, `OXIDO_BRILHO` fosco (a madeira).
- **A cabeça da prensa:** `Kit.caixa(2,6 × 0,25 × 0,6)` em `(0; 3,2; −1,2)`, `GRAFITE`: no selo por cima, desce 0,4 m
  e volta, duas vezes, cada ida e volta em 1/2 batida.
- **O lingote:** `Kit.caixa(0,9 × 0,2 × 0,45)` em `(0; 1,0; −1,2)`, `GRAFITE`; na síncope de ouro, mostarda. A
  moldura (quatro caixas de 0,06 m de altura): `GRAFITE` apagada; acesa no neon do dono a 1,2; mostarda no ouro. A
  coroa (uma barra de 0,36 × 0,05 e três dentes de 0,05 × 0,12, em `ETIQUETA`) na borda da frente, quando o dono é o
  líder.
- **Os selos:** `Kit.caixa(0,3 × 0,02 × 0,3)` em cima do lingote, na cor de quem carimbou (emissão 0,6, dono o
  lugar), empilhados 0,02 m cada; o selo do dono por baixo, deslocado (−0,1; ; 0,06). O borrão do dono, `SOMBRA`,
  girado 0,5 rad em cima do lingote; a mancha do ladrão, `SOMBRA`, na mesa, na frente do carimbo dele.
- **Os carimbos:** um por lugar, haste `Kit.caixa(0,08 × 0,8 × 0,08)` e cabeça `(0,35 × 0,2 × 0,35)` em `OXIDO_BRILHO`,
  com a face `(0,3 × 0,03 × 0,3)` na cor do lugar, em `(−0,9 + 0,6·l; 2,2; −1,2)`; descem até o lingote em 0,06 s e
  sobem em 0,12 s no clique.
- **As pilhas:** os lingotes de cada um, `Kit.caixa(0,5 × 0,18 × 0,25)`, `GRAFITE` (o de ouro em mostarda), com o selo
  dele em cima (e o do dono roubado, deslocado, por baixo), em `(RAIAS[l] + 0,55·(k % 5) − 1,1; 0,1 + 0,2·⌊k/5⌋;
  −3,2)`. O lingote vai em arco de 0,4 m em 0,3 s; o roubado pula 1,2 m em 1 batida.
- **O carimbador:** o cavaleiro em `(RAIAS[l]; 0,05; Z_JOGADOR)`, olhando a mesa, de mãos livres; a raia do kit
  (`raia(l)`) acende na vez dele.
- **O que brilha e de quem é:** a moldura, no neon do dono; os selos e as faces dos carimbos, na cor de cada lugar. O
  ouro é a mostarda da seção, de ninguém.
- **Nenhuma cor fora do tema:** nenhuma cor escrita em hexadecimal no arquivo.

## O som

Os ids são os do [mapa do áudio](../o-time/o-mapa-do-audio.md).

| evento | na TV | no controle de quem |
| --- | --- | --- |
| o clique do dono | a nota (o kit) e `carimbo` (`carimbo_0..4`), 0 dB | dono: Ressonância, a nota (o kit); bom e ótimo, `Som.no_controle(l, "carimbo", 0.6)` |
| o selo por cima fica | `carimbo`, 0 dB, e `golpe` (`golpe_*`), −4 dB | ladrão: `Som.no_controle(l, "carimbo", 0.6)` |
| o borrão | `falha` (`falha_0..2`, que a `fx_tropeco_0..2` substitui), −12 dB | — |
| o lingote vai à pilha | `tique` (`tique_0..2`), −8 dB | — |
| o lingote de ouro tem dono | `confirma` (`confirma_0..2`), 0 dB | — |
| o selo por cima (o lingote pula) | `golpe`, −2 dB, e `carimbo` duas vezes na prensa, −2 dB, tom 0,7 | dono roubado: `Forja.som_falante(dono, "tropeco", 0.7)` (`mod_tropeco`) |
| o dono erra | a nota quebrada (o kit) | a nota quebrada (o kit) |

**A faixa:** `mus_s03_j15` (128 BPM, Dó# menor, a fazer). Até a H05, a sintetizada da seção a 100 bpm.

## O controle

| evento | vibração | háptica e alto-falante | luz | gatilho | para os outros |
| --- | --- | --- | --- | --- | --- |
| a síncope do dono, nas 32 batidas depois da primeira nota | — | `Forja.som_haptica(dono, "pulso", "pulso", 0.35)` na batida da síncope, só no dono; se devolver −1, `Forja.sentir(dono, "toque", 40)` no lugar dela | — | R2 Off | nada |
| o clique do dono | o kit | o carimbo a 0,6, ou a nota no perfeito | o kit: branco no perfeito | — | nada |
| o selo por cima fica | `Forja.sentir(l, "perfeito")` no ladrão | o carimbo a 0,6 | — | — | — |
| o borrão (o selo rachado) | dois `Forja.sentir(l, "erro", 30)` (0,7/0,3), o segundo 60 ms depois do primeiro | — | — | — | nada |
| o lingote roubado | `Forja.sentir(dono, "golpe")` no dono (1,0/0,6/250 ms) | o tropeço a 0,7 no dono | — | — | o ladrão já sentiu o perfeito |
| o dono erra | o kit: 0,7/0,3/160 ms | a nota quebrada | o kit | — | nada |

**Sem o controle na mão:** o robô clica pelo `Forja.robo_apertar`; a prova lê as linhas `sensacao` do golpe e do
perfeito e os dois `erro` de 30 ms do borrão (F05), e as `saida` de vibração delas (F06). O pulso da primeira frase
se confere pelo simulador: o `som_haptica` do dono na batida da síncope, ou, quando ele devolve −1, a linha
`sensacao` `toque` de 40 ms.

**O que espera ela:** nada. O clique do touchpad é um botão; a regra udev do touchpad-mouse não muda esta ficha.

## O cavaleiro

O cavaleiro é o da montagem (G13), inteiro, de mãos livres. Pode ser de outra raça: esta ficha usa só o esqueleto
comum e as animações `attack-melee-right` (carimbar), `interact-right` (o ladrão leva o lingote) e `emote-no` (o
borrão e o lingote roubado).

| stat | gancho | o que muda no Carimbo | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: ninguém é empurrado | — | — | — |
| Passo | `velocidade` | não age: o carimbador não anda, e o borrão não seca mais depressa | — | — | — |
| Fôlego | `levantar` | o carimbo seca depois do borrão: `SECAO.queda(l, 1)` tempos sem clique | 1,25 tempo | 1 tempo | 0,75 tempo |
| Faro | `pista` | a moldura e a raia do dono acendem 1 aviso (`SECAO.aviso_s(l)`) antes da síncope | −40 ms | 0 | +40 ms |

Os itens: o Martelo e o Escudo são do kit (o Escudo absorve o erro do dono: sem borrão no lingote, e o lingote fica
para quem vier por cima). A Âncora não age. A Lanterna entra pelo `SECAO.aviso_s`.

## As reações

- **Carimbos que o Carimbo pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar), `car_virada` (do placar: quem passa a ser o líder), `car_por_um_fio` (no resultado) e `car_emburrado` (no
  inserto do resultado). O `car_acorde` não acontece: a síncope de ouro cai no "e" do 4, nunca no tempo 1.
- **Adesivos:** na seção 3, ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: o selo por cima** (`selo_por_cima`). O lingote é da vez de um, mas qualquer um carimba por cima; o selo
mais perto do tempo fica. Quando o ladrão fica por cima do dono, o lingote dá um pulo de 1,2 m para a pilha do ladrão
com o selo dele em cima do selo do dono, e a prensa bate duas vezes. Degrau golpe: tremor de 0,02 m por 1 batida, 24
faíscas na cor do ladrão, parada de 2 quadros.

O segundo grito, que já existe: **o carimbo que borra** (o ladrão perde a próxima vez e o carimbo seca).

- **O rastro:** o lingote roubado mostra os dois selos (o do dono aparece pela borda) na pilha do ladrão até o fim.
- **A curva:** de 0 a 30 s, duas síncopes por compasso, e cada um sabe a sua; de 30 a 60 s, a prensa corre, toda
  colcheia fraca; de 60 s ao fim, duas por compasso, e nas últimas 16 batidas a síncope de ouro, sem dono, que vale 3
  e faz os quatro clicarem juntos.
- **Ensina sem falar:** a moldura na cor do dono e a raia dele acendem antes da síncope; na primeira frase, o pulso
  na mão dele cai na síncope. O robô (ou o primeiro ladrão) mostra antes de 20 s que dá para carimbar por cima.
- **Quem está perdendo:** a síncope sem dono da partitura simples; os lingotes do líder levam a coroa, e todo mundo
  sabe de quem roubar.
- **O que saiu:** nada.
- **A nota de hoje:** 4; com o pulo do lingote roubado e a síncope de ouro, 5.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | um quadro antes de 10 s mostra a moldura acesa na cor de um dono |
| 4. o momento | pelo menos 5 linhas `momento` `selo_por_cima` em 90 s, de pelo menos 2 `ladrao` diferentes | o quadro final mostra lingotes com selo duplo em 2 ou mais pilhas |
| 5. a curva | notas por segundo de 30 a 60 s ≥ 1,8 × as de 0 a 30 s; a linha `momento` `reta` existe | o quadro de 45 s tem a câmera mais longe que o de 15 s |
| 6. a falha | o P4 tem pelo menos 5 linhas `entrada` com `borrou` | 1 quadro em 5 mostra uma mancha `SOMBRA` na mesa |
| 7. quem perde joga | a maior distância entre duas `nota` seguidas de cada lugar é de até 16 batidas | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `selo_por_cima` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,05 | o lingote no ar e a pilha do ladrão se veem no quadro de 480 × 270 |
| 9. o impacto | para cada `selo_por_cima`, uma linha `sensacao` `golpe` do dono a até 16,7 ms | o quadro seguinte mostra a prensa abaixada |
| 10. o placar no mundo | a ordem do `vencedor()` bate com `lingotes` no `momento` `reta` e no fim | a pilha mais alta é a do líder, e o lingote dele tem a coroa |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova roda com o `--robo` da
`prova_do_jogo.sh` (o `bom` nos quatro) e confere os itens 1, 4, 5 e 8; os itens 6 e 7 esperam a mesa padrão; o 9 e o
10, a prancha.

## Pronto quando

O Carimbo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos. O cabo que cai e
volta tira o lugar do rodízio e o devolve. O selo por cima aparece no registro pelo menos 5 vezes, de pelo menos 2
ladrões, e o selo duplo fica em 2 ou mais pilhas. O fim tem sempre vencedor. `SALA=S03_J15 bash
tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, com a prancha olhada. O catálogo e as traduções têm as
linhas desta ficha, o `.uid` está no commit, e o commit, sem trailer, é
`feat(carimbo): o selo mais perto do tempo fica, o roubo com estrondo e a síncope de ouro`.

## Provas

Na sessão: `SALA=S03_J15 bash tests/prova_do_jogo.sh`, `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### `godot/testes/prova_do_jogo.gd`

No `match` de `_prova_da_ficha`: `"S03_J15": await _prova_do_carimbo()`.

```gdscript
## O Carimbo (S03_J15): o rodízio dá a vez a cada um; o clique simulado do dono
## chega julgado; o selo por cima aparece de 2 ladrões e deixa selo duplo em 2 pilhas.
func _prova_do_carimbo() -> void:
	var primeira := [-9]
	var olhar := func(m) -> void:
		if primeira[0] == -9:  # o primeiro quadro da fase jogo
			primeira[0] = int(m._sinc.get("dono", -9))
	var mg = await _joga_o_minigame("S03_J15", 130.0, olhar)
	if mg == null:
		return
	_esperar(primeira[0] == 0, "Carimbo: a primeira síncope é do P1")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S03_J15")
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "Carimbo P%d: carimbou na vez %s" % [l + 1, c])
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque" and float(e.get("t_musica", 99.0)) <= 10.0)
	_esperar(toques.size() >= 4, "Carimbo: %d cliques do dono antes de 10 s (o mínimo é 4)" % toques.size())
	var roubos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "selo_por_cima")
	_esperar(roubos.size() >= 5, "Carimbo: %d selos por cima em 90 s (o mínimo é 5)" % roubos.size())
	var ladroes := {}
	for r in roubos:
		ladroes[int(r.get("ladrao", -1))] = true
		var x := float(r.get("x_tela", 0.0))
		_esperar(x >= 0.2 and x <= 0.8 and float(r.get("altura_tela", 0.0)) >= 0.05, "Carimbo: o roubo na tela (%s)" % [r])
	_esperar(ladroes.size() >= 2, "Carimbo: %d ladrões diferentes (o mínimo é 2)" % ladroes.size())
	var duplas := 0
	for l in 4:
		if int(mg.j[l].duplos) >= 1:
			duplas += 1
	_esperar(duplas >= 2, "Carimbo: selo duplo em %d pilhas (o mínimo é 2)" % duplas)
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "Carimbo: a linha momento reta aparece uma vez")
	var notas := linhas.filter(func(e): return e.get("tipo") == "nota")
	var antes := notas.filter(func(e): return float(e.get("t_musica", 0.0)) < 30.0).size() / 30.0
	var prensa := notas.filter(func(e): var t := float(e.get("t_musica", 0.0)); return t >= 30.0 and t < 60.0).size() / 30.0
	_esperar(prensa >= 1.8 * antes, "Carimbo: a prensa corre (%.2f notas/s contra %.2f)" % [prensa, antes])
```

Com quatro robôs `bom`, cerca de 4 em cada 7 síncopes têm uma tentativa de roubo e mais ou menos metade fica por
cima: o registro tem dezenas de `selo_por_cima`. Se a semente 7 der menos de 5, o problema é de desenho, não da
prova: mostre o registro e não mude a semente.

### O que o registro mede

- O kit: a `nota` e o `toque` do dono em cada síncope (o clique pedido contra o feito, no tempo).
- A linha `entrada`: cada clique por cima (por cima de quem, o julgamento, a quantos ms, se ficou, se era de ouro),
  cada borrão (por quê) e cada vez perdida por borrão. Com quatro cliques de touchpad no mesmo instante, um clique
  que não chega, ou que chega no controle vizinho, aparece aqui.
- A `momento` `selo_por_cima` (`ladrao`, `de`, `duplo`, `x_tela`, `altura_tela`) e a `reta` (`ordem`).

### As pranchas que o jogador do time olha

- antes de 10 s: a moldura acesa na cor de cada dono, um por vez;
- de 0 a 20 s: o primeiro lingote pulando para a pilha de um ladrão;
- de 30 a 60 s: a prensa correndo, uma síncope por tempo;
- nas últimas 16 batidas: o lingote de ouro e os quatro carimbos descendo juntos;
- o fim: as pilhas, com os selos duplos à mostra.

### O que o André joga e sente

`./run-local.sh -- --sala=S03_J15` com quatro: a síncope se sente contra o peso do 1 e do 3; o clique do touchpad
carimba no controle; o roubo faz o lingote pular e a sala gritar; o borrão pune o afobado; e a síncope de ouro faz os
quatro clicarem juntos.

### Armadilhas

- **O selo por cima é estritamente mais perto do tempo:** no empate em ms, fica quem carimbou antes. O dono também só
  fica por cima se for mais perto que um selo que já estava lá.
- **O clique do ladrão não passa pelo kit** (não é nota dele): nada de `julgar_toque` para ele; `Ritmo.julgar` direto
  e a linha `entrada`.
- **O borrão tira a próxima vez uma vez só** (o `_nova_sincope` confere) e seca o carimbo; o clique no carimbo seco
  não borra de novo.
- **A pilha é da janela fechada**, não do clique: quem está por cima no fim leva, e é ali que o `selo_por_cima` é
  gravado.
- **Os materiais** (os selos, as molduras, o metal, o ouro, o borrão) se criam uma vez no `montar`; cada selo e cada
  pilha só escolhem um deles.
- **`acender_raia`** marca a vez do dono (a raia do kit); as luzinhas e a barra de luz não mudam.
