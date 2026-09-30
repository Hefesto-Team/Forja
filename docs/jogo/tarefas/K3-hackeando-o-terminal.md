# K3 — Hackeando o Terminal

**Sprint:** K · **Slot:** S03_J13 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, F03, H07, K1 (o `secao.gd`), e o sorteio dentro da seção ([o índice](I-a-centelha.md#antes-de-começar-o-que-ainda-falta-na-base))

## Por quê

Seguir a senha é tocar o quadrante certo do touchpad na sua vez: o terminal
toca a senha, cada nota é de um jogador e de um canto do touchpad, e a porta
só abre se a turma inteira responde em ordem — onde o dedo encosta, medido
nota a nota, em chamada e resposta.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 13 em 03](../03-os-45-minigames.md#s3--o-molde--touchpad)
- [O índice da seção](K-o-molde.md) e a [K1](K1-o-molde.md#o-cenário) (o `secao.gd`)
- [F03 — Todo minigame fecha](F03-todo-minigame-fecha.md) (o `coop` e o `coop_venceu`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S03_J13",
	"titulo": "Hackeando o Terminal",
	"verbo": "Siga a senha!",
	"genero": "coop",
	"icone": "touchpad",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S03_J13",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Siga!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S03_J13` — até a H05, a sintetizada da seção a 100 bpm;
  com a gerada, 140 bpm ("arpejos em fusas, urgência").
- **A senha:** quatro notas. Cada nota tem **um dono** (um dos presentes) e
  **um quadrante** do touchpad (em cima à esquerda, em cima à direita,
  embaixo à esquerda, embaixo à direita). Os donos: a lista dos presentes
  com controle repetida até quatro e embaralhada pela semente (com quatro,
  cada um tem uma nota; com dois, duas; com um, as quatro). Os quadrantes
  sorteados.
- **A chamada** (o primeiro compasso da senha, `C`): na batida `C + k`, o
  terminal acende o quadrante da nota `k` na cor do dono, toca a nota do dono
  na TV e **a nota dele no alto-falante do controle dele** (o segredo: só ele
  ouve que é com ele); a placa dele acende o mesmo quadrante.
- **A resposta** (o compasso seguinte, `C + 4`): na batida `C + 4 + k`, o dono
  da nota `k` **encosta** o dedo no quadrante dela. O instante em que um dedo
  encosta (ele não estava encostado) é o toque: quadrante certo →
  `julgar_toque`; quadrante errado → erro. Encostar sem nota dele na janela
  não conta. A nota passou → nota perdida.
- **A senha abre** se as quatro notas saíram BOM ou melhor: uma trava da porta
  acende. **A porta tem 8 travas.** Com um erro, no fim da resposta **o
  terminal apita**: o chão acende em vermelho, todos são empurrados um passo
  para trás, e uma trava apaga. A senha seguinte começa no compasso depois da
  resposta.
- **Os pontos por julgamento** (os do hacker, para o destaque):
  `[0, 20, 35, 50]`.
- **A progressão:** `p = t_jogo / duracao`, decidida no começo de cada senha.
  De 0 a 1/3, a senha de 4 notas. **O pico (1/3 a 2/3), a senha longa:** 8
  notas (chamada em 2 compassos, resposta em 2), e vale 2 travas. De 2/3 em
  diante, 4 notas. `Ritmo.simples[l]` não muda a senha (é coop): quem está
  errando só não recebe as notas 5 a 8 da senha longa (os donos delas saem
  dos outros). Senhas em 90 s: ~17 a 100 bpm, ~23 a 140 bpm; uma turma que
  acerta metade abre a porta.

## O cenário

`SECAO.montar(self)` (a oficina); o terminal no fundo; `SECAO.bancada(self, l, false)` por lugar:

| o quê | peça | onde (m) |
| --- | --- | --- |
| o terminal | `Kit.caixa(4.4, 2.8, 0.3)`, `#2a2233`; quatro telas `Kit.caixa(2.0, 1.2, 0.05)`, `Kit.material(Color("#1c1622"), 0.3)`, que acendem na cor do dono | `(0, 2.3, −5.2)`; telas em `(±1.05, 2.3 ± 0.65, −5.03)` |
| a porta | `gate` (escala 2,5), que sobe 3 m quando abre | `(0, 0, −7.2)` |
| as travas | oito `SECAO.disco8(0.12, 0.05)` de frente (`rotation.x = PI/2`), `Kit.material(Color("#2a2433"))`; abertas: `Kit.material(Tema.VERDE, 2.0)` | `(−2.1 + 0.6k, 4.2, −5.0)` |
| as linhas dos quadrantes | na placa, uma cruz: `Kit.caixa(2.4, 0.02, 0.03)` e `Kit.caixa(0.03, 0.02, 1.2)`, `Kit.chapado(Tema.TRILHO)` | placa + `(0, 0.1, 0)` |
| o quadrante da vez | na placa, `Kit.caixa(1.15, 0.02, 0.55)`, a cor do lugar com brilho 1,5, visível da chamada à resposta da nota dele | no centro do quadrante |
| o chão vermelho | `Kit.caixa(24, 0.02, 12)`, `Kit.material(Tema.VERMELHO, 1.2)`, visível 0,5 s no apito | `(0, 0.03, 0)` |
| o hacker | o boneco, de perfil, mãos livres | `(RAIAS[l] − 1.45, 0.05, 0.35)` |

Câmera: `camera_pos = Vector3(0, 8.0, 13.0)`, `camera_olhar = Vector3(0, 1.4, -2.0)`.
A cor de cada lugar aparece só nas notas dele. Nada liso.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **touchpad (a feature)** | encostar no quadrante certo, na sua vez |
| vibração | o kit por nota; o apito: `Forja.sentir(l, "golpe")` em todos; a trava que abre: `acerto` em todos; a porta: `explosao` em todos |
| barra de luz | `SECAO.piscar` no `toque` e na `falha` |
| alto-falante do dono | **na chamada, a nota dele** (`Forja.som_falante(l, "nota:%d" % l, 0.6)`: o segredo); perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "clique", 0.4)`; erro: a nota quebrada (o kit) |
| háptica por material | `metal`, pelo kit |
| gatilho | livre (o R2 Off) |
| som na TV | na chamada, `nota` com o tom do dono (`TOM_DO_LUGAR[dono]`); a resposta (o kit); o apito (`"apito"`, da F03) e `falha`; `confirma` na trava; `portao` e `sucesso` na porta |

## A falha

O terminal apita: o chão acende em vermelho por 0,5 s, os quatro hackers
dão um passo para trás (0,4 m em `z` e voltam em 0,5 s) com `emote-no`, e
uma trava apaga. Quem errou a nota vê o quadrante dela piscar em vermelho no
terminal na hora do erro.

## O fim e o vencedor

`coop = true` no `montar()`. A oitava trava → `coop_venceu = true`, a porta
sobe e todos acabam. Os 90 s sem a porta → não venceram. `vencedor()` é o
destaque: menos erros; empate pelos pontos, depois pelo lugar (nunca vazio).

## Com menos de quatro

A senha tem sempre 4 (ou 8) notas; os donos se repetem. Sozinho, as quatro
são dele — é a mesma senha, mais corrida. **O controle que cai:** as notas
dele na senha em curso não contam (nem erro, nem acerto; a senha abre com as
outras); ele sai da lista de donos até voltar.

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var agora := Ritmo.t_musica()
	for nota in senha:
		if int(nota.dono) != l or str(nota.estado) != "esperando":
			continue
		if not nota.has("mira"):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			nota["mira"] = 0.0 if Forja.robo_acerta() else 0.20
		var quando := Ritmo.t_da_batida(float(nota.b)) + float(nota.mira)
		if agora >= quando and agora <= quando + 0.06:
			var q: Vector2 = QUADRANTES[int(nota.q)]
			Forja.robo_tocar(l, 0, q.x, q.y, 0.05)
		break  # uma nota por vez: a mais cedo dele
```

## Os ganchos

`godot/scripts/minigames/s03/hackeando_o_terminal.gd`:

```gdscript
extends Minigame
## Hackeando o Terminal (S03_J13). O terminal toca uma senha de quatro notas:
## cada uma de um dono e de um quadrante do touchpad. Na resposta, cada dono
## encosta no quadrante da nota dele, na vez dela. Senha certa acende uma trava;
## oito travas abrem a porta (todos vencem). No meio, a senha longa: oito notas.
##
## A falha: o terminal apita, o chão acende em vermelho, todos dão um passo
## para trás e uma trava apaga.
## O vencedor: coop — a porta abre (todos) ou não; o destaque é quem errou menos.
## O alto-falante do dono: a nota dele na chamada (só ele ouve), o clique no
## acerto, a nota no perfeito.
## O registro mede: o quadrante pedido contra o tocado, e onde o dedo encostou
## (a linha `entrada`), e o tempo (o kit).
## O robô: encosta no centro do quadrante na nota dele (ou 200 ms atrasado).
## Com menos de quatro: a senha tem sempre quatro notas; os donos se repetem.
## A régua: "Siga a senha!" e o touchpad bastam; sem a tela, a nota no
## alto-falante diz de quem é a vez (o quadrante, não); nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

# (a FICHA vem aqui)

const BATIDA_DA_PRIMEIRA_NOTA := 4.0
const META := 8
const QUADRANTES := [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]
const PONTOS := [0, 20, 35, 50]
const FOLGA_PERDIDA := 0.05

var j := {}
var senha: Array = []  ## {dono, q, bc (a chamada), b (a resposta), n, estado: "chamando", "esperando", "feito", "errou", "fora"}
var _fim_da_senha := -1.0
var _vale := 1
var abertas := 0
var erros := [0, 0, 0, 0]
var _nota: Dictionary = {}  ## a nota em julgamento (para toque/falha)
var _telas: Array = []
var _travas: Array = []
var _porta: Node3D
var _chao: MeshInstance3D
var _chao_ate := -1.0
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	coop = true
	camera_pos = Vector3(0, 8.0, 13.0)
	camera_olhar = Vector3(0, 1.4, -2.0)
	SECAO.montar(self)
	Kit.caixa(self, Vector3(4.4, 2.8, 0.3), Vector3(0, 2.3, -5.2), Kit.material(Color("#2a2233"), 0.0, 0.9))
	for q in 4:
		var x := -1.05 if q % 2 == 0 else 1.05
		var y := 2.95 if q < 2 else 1.65
		_telas.append(Kit.caixa(self, Vector3(2.0, 1.2, 0.05), Vector3(x, y, -5.03), Kit.material(Color("#1c1622"), 0.3)))
	_porta = Kit.peca(self, "gate", Vector3(0, 0, -7.2), 0.0, 2.5)
	for k in META:
		var trava := SECAO.disco8(self, 0.12, 0.05, Vector3(-2.1 + 0.6 * k, 4.2, -5.0), Kit.material(Color("#2a2433")))
		trava.rotation.x = PI * 0.5
		_travas.append(trava)
	_chao = Kit.caixa(self, Vector3(24, 0.02, 12), Vector3(0, 0.03, 0), Kit.material(Tema.VERMELHO, 1.2))
	_chao.visible = false
	var linha := Kit.chapado(Tema.TRILHO)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l, false)
		var placa: Node3D = nos.placa
		Kit.caixa(placa, Vector3(2.4, 0.02, 0.03), Vector3(0, 0.1, 0), linha)
		Kit.caixa(placa, Vector3(0.03, 0.02, 1.2), Vector3(0, 0.1, 0), linha)
		var vez := Kit.caixa(placa, Vector3(1.15, 0.02, 0.55), Vector3.ZERO, Kit.material(Forja.cor_do_lugar(l), 1.5))
		vez.visible = false
		nos["vez"] = vez
		maos_livres(p)
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		j[l] = {"n": 0, "z_antes": [false, false], "nos": nos}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _no_pico() -> bool:
	var p := t_jogo / maxf(duracao, 1.0)
	return p >= 1.0 / 3.0 and p < 2.0 / 3.0


## Uma senha nova começando no compasso da batida `c`.
func _nova_senha(c: float) -> void:
	senha.clear()
	var longa := _no_pico()
	var n_notas := 8 if longa else 4
	_vale = 2 if longa else 1
	var donos: Array = []
	for l in presentes():
		if conectado(l) and not acabou[l]:
			donos.append(l)
	if donos.is_empty():
		_fim_da_senha = c + 4.0
		return
	var lista: Array = []
	for i in n_notas:
		var d: int = donos[i % donos.size()]
		if i >= 4 and Ritmo.simples[d] and donos.size() > 1:
			d = donos[(i + 1) % donos.size()]  # quem está errando fica fora das notas 5 a 8
		lista.append(d)
	for i in range(lista.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = lista[i]
		lista[i] = lista[k]
		lista[k] = tmp
	for i in n_notas:
		var dono: int = lista[i]
		var nota := {"dono": dono, "q": rng.randi_range(0, 3), "bc": c + i, "b": c + n_notas + i,
			"n": int(j[dono].n), "estado": "chamando"}
		j[dono].n = int(j[dono].n) + 1
		nova_nota(dono, int(nota.n), Ritmo.t_da_batida(float(nota.b)))
		senha.append(nota)
	_fim_da_senha = c + 2.0 * n_notas


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			Forja.evento("entrada", l + 1, {"o": "sensores", "toque": false})
			acabou[l] = true
	_nova_senha(BATIDA_DA_PRIMEIRA_NOTA)


func jogar(_dt: float) -> void:
	SECAO.voltar_a_luz(self)
	var agora := Ritmo.t_musica()
	var agora_b := Ritmo.batida()
	for l in presentes():
		SECAO.mostrar_dedos(self, l, j[l].nos)
		if not conectado(l):
			for nota in senha:
				if int(nota.dono) == l and str(nota.estado) in ["chamando", "esperando"]:
					nota.estado = "fora"
	# a chamada: o terminal acende e toca cada nota na batida dela
	for nota in senha:
		if str(nota.estado) == "chamando" and agora_b >= float(nota.bc):
			nota.estado = "esperando"
			_chamar(nota)
	# a resposta: o dedo que encosta
	for l in presentes():
		if acabou[l] or not conectado(l):
			continue
		var tocou := _encostou(l)
		if tocou.x >= 0.0:
			_resposta(l, tocou, agora)
	# as notas que passaram
	for nota in senha:
		if str(nota.estado) == "esperando" and agora > Ritmo.t_da_batida(float(nota.b)) + Ritmo.JANELA_BOM + FOLGA_PERDIDA:
			_nota = nota
			nota_perdida(int(nota.dono), int(nota.n))
	if _fim_da_senha >= 0.0 and agora_b >= _fim_da_senha:
		_fechar_a_senha()
		if not coop_venceu:
			_nova_senha(4.0 * ceilf(agora_b / 4.0))
	_mostrar(agora_b)


## O ponto (x, y) em que um dedo acabou de encostar; (-1, -1) se nenhum.
func _encostou(l: int) -> Vector2:
	var antes: Array = j[l].z_antes
	var r := Vector2(-1, -1)
	for k in 2:
		var d := Forja.dedo(l, k)
		var baixo := d.z > 0.5
		if baixo and not bool(antes[k]):
			r = Vector2(d.x, d.y)
		antes[k] = baixo
	return r


static func _quadrante(pos: Vector2) -> int:
	return (1 if pos.x >= 0.5 else 0) + (2 if pos.y >= 0.5 else 0)


func _resposta(l: int, pos: Vector2, agora: float) -> void:
	for nota in senha:
		if int(nota.dono) != l or str(nota.estado) != "esperando":
			continue
		var alvo := Ritmo.t_da_batida(float(nota.b))
		if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
			return  # a vez dele ainda não chegou: encostar à toa não conta
		var q := _quadrante(pos)
		Forja.evento("entrada", l + 1, {"o": "touchpad", "quadrante_pedido": int(nota.q), "quadrante": q,
			"x": snappedf(pos.x, 0.01), "y": snappedf(pos.y, 0.01), "n": int(nota.n)})
		_nota = nota
		if q == int(nota.q):
			julgar_toque(l, alvo, int(nota.n))
		else:
			nota_perdida(l, int(nota.n))
		return


func _chamar(nota: Dictionary) -> void:
	var dono: int = nota.dono
	var tela: MeshInstance3D = _telas[int(nota.q)]
	var m: StandardMaterial3D = tela.material_override
	m.albedo_color = Forja.cor_do_lugar(dono).darkened(0.3)
	m.emission = Forja.cor_do_lugar(dono)
	m.emission_energy_multiplier = 1.8
	Som.tocar("nota", tela.global_position, -4.0, TOM_DO_LUGAR[dono])
	Forja.som_falante(dono, "nota:%d" % dono, 0.6)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	marcar(l, PONTOS[julgamento])
	_nota.estado = "feito"
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.4)
	var p := jogador(l)
	if p:
		p.gesto("interact-right", 0.3)
	SECAO.piscar(self, l, julgamento)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	if not treinando:
		erros[l] += 1
	_nota.estado = "errou"
	var m: StandardMaterial3D = (_telas[int(_nota.q)] as MeshInstance3D).material_override
	m.emission = Tema.VERMELHO
	m.emission_energy_multiplier = 2.0
	SECAO.piscar(self, l, Ritmo.ERRO)


## A resposta acabou: a senha abre uma trava (ou duas, a longa), ou o terminal apita.
func _fechar_a_senha() -> void:
	_fim_da_senha = -1.0
	var errou := false
	var alguma := false
	for nota in senha:
		if str(nota.estado) == "errou":
			errou = true
		if str(nota.estado) == "feito":
			alguma = true
	if treinando or not (errou or alguma):
		return
	if errou:
		abertas = maxi(0, abertas - 1)
		_chao.visible = true
		_chao_ate = t + 0.5
		Som.tocar("apito")
		Som.tocar("falha")
		for l in presentes():
			if conectado(l):
				Forja.sentir(l, "golpe")
			var p := jogador(l)
			if p:
				p.gesto("emote-no", 0.5)
				var tw := p.create_tween()
				tw.tween_property(p, "position:z", p.position.z + 0.4, 0.15)
				tw.tween_property(p, "position:z", p.position.z, 0.35)
		return
	abertas = mini(META, abertas + _vale)
	Som.tocar("confirma")
	for l in presentes():
		if conectado(l):
			Forja.sentir(l, "acerto")
	if abertas >= META:
		_abrir_a_porta()


func _abrir_a_porta() -> void:
	coop_venceu = true
	Som.tocar("portao", _porta.global_position)
	Som.tocar("sucesso")
	var tw := _porta.create_tween()
	tw.tween_property(_porta, "position:y", 3.0, 1.0)
	for l in presentes():
		Forja.sentir(l, "explosao")
		acabou[l] = true


func _mostrar(agora_b: float) -> void:
	if _chao.visible and t >= _chao_ate:
		_chao.visible = false
	for k in _travas.size():
		(_travas[k] as MeshInstance3D).material_override = Kit.material(Tema.VERDE, 2.0) if k < abertas else Kit.material(Color("#2a2433"))
	# as telas apagam um tempo depois de acender (a chamada) ou ficam na resposta
	for q in 4:
		var m: StandardMaterial3D = (_telas[q] as MeshInstance3D).material_override
		var acesa := false
		for nota in senha:
			if int(nota.q) == q and agora_b >= float(nota.bc) and agora_b < float(nota.bc) + 0.9:
				acesa = true
		if not acesa and m.emission != Tema.VERMELHO:
			m.emission_energy_multiplier = 0.3
	for l in presentes():
		var vez: MeshInstance3D = j[l].nos.vez
		vez.visible = false
		for nota in senha:
			if int(nota.dono) == l and str(nota.estado) == "esperando":
				var c: Vector2 = QUADRANTES[int(nota.q)]
				vez.position = SECAO.no_molde(c.x, c.y, 0.11)
				vez.visible = true
				break


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(erros[a]) != int(erros[b]):
		return int(erros[a]) < int(erros[b])
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar):
		return "Travas: %d de %d" % [abertas, META]
	return super(lugar)
```

## O que o registro mede

- O kit: uma `nota` por nota da senha (no dono, com o `t_alvo` da resposta)
  e um `toque` por resposta (ou `perdida`).
- A linha `entrada` em cada encostar na vez: **o quadrante pedido contra o
  tocado** e o ponto exato. Cruzado: um touchpad com um canto morto (um
  quadrante que nunca chega certo) ou com os eixos trocados (o quadrante
  espelhado) aparece aqui.

## Armadilhas

- **`_nota` antes de `julgar_toque`/`nota_perdida`:** o kit não diz qual
  nota; o `toque` e a `falha` leem daqui.
- **Encostar, não estar:** o toque é o dedo que **encosta** (não estava
  encostado no quadro anterior); arrastar o dedo de um quadrante a outro não
  conta.
- **A nota fora** (o dono sem controle) não é erro nem acerto; a senha abre
  com as outras.
- **O material das travas** se cria a cada quadro no `_mostrar`: guarde os
  dois (`_trava_aberta`, `_trava_fechada`) se a prancha mostrar menos de
  55 fps.
- **`Som.tocar("apito")`** é o som da F03; se ele não existir, fica só o `falha`.
- **O treino** julga e não mexe nas travas.

## Pronto quando

O terminal joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o bom abre a porta, o ruim faz apitar); o cabo que
cai e volta não quebra a senha; o fim tem sempre o destaque;
`bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh` passa
com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S03_J13 (K3): o terminal abre pelo catálogo; a senha chama cada dono; a
## resposta do robô chega pelo toque simulado; o fim é coop, com destaque.
func _prova_do_terminal() -> void:
	jogo._entrar_na_sala("S03_J13", false)
	await _quadros(2)
	var mg = jogo.sala
	_esperar(mg is Minigame and mg.id == "S03_J13", "S03_J13: abriu pelo catálogo")
	if not mg is Minigame:
		return
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	var donos := {}
	for nota in mg.senha:
		donos[int(nota.dono)] = true
	_esperar(donos.size() == 4, "S03_J13: a primeira senha tem uma nota de cada um (%s)" % [donos.keys()])
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 40000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "fim" and mg.coop, "S03_J13: fechou como coop")
	if not is_instance_valid(mg):
		return
	var respostas := 0
	for l in 4:
		respostas += int(mg.contagem[l][1]) + int(mg.contagem[l][2]) + int(mg.contagem[l][3])
	_esperar(respostas >= 2, "S03_J13: o robô respondeu a senha (%d respostas)" % respostas)
	_esperar(mg.vencedor().size() == 4, "S03_J13: o destaque ordena os quatro")
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S03_J13: de volta ao salão")
```

(Na prova sem janela, o tempo de jogo anda ~16 vezes mais depressa que a
música: o minigame fecha logo depois da primeira resposta. Por isso a
checagem pede duas respostas, não a porta.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S03_J13` com quatro: a nota
no controle diz "é você" sem ninguém olhar, a resposta em ordem vira uma
frase, o apito e o empurrão fazem a turma se cobrar, e a senha longa do
meio é o desafio.

## Ao terminar

- Catálogo: `"S03_J13": preload("res://scripts/minigames/s03/hackeando_o_terminal.gd")`
  em `MINIGAMES` e na lista da S03.
- `traducoes.gd`: `"Hackeando o Terminal": "Hacking the Terminal"`,
  `"Siga a senha!": "Follow the code!"`, `"Siga!": "Follow!"`; em `EN_PADROES`,
  `["^Travas: (\\d+) de (\\d+)$", "Locks: $1 of $2"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a K3 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: Hackeando o Terminal — a senha em chamada e resposta, um quadrante por jogador`
