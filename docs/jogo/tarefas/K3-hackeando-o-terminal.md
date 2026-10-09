# K3 — Hackeando o Terminal

**Sprint:** K · **Slot:** S03_J13 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, H07, G10, G14, G15, K1 (o `secao.gd`)

## Por quê

Responder é encostar no quadrante certo do touchpad na sua vez. O terminal toca a senha; cada nota é de um jogador e
de um canto do touchpad; e a porta só abre se a turma inteira responde em ordem. O jogo de hoje já é bom (nota 4).
Esta ficha o passa para o kit e a oficina da seção, tira o vermelho do erro e faz a senha longa abrir com estrondo, à
vista da sala.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o `coop` e o `coop_venceu`)
- [O índice da seção](K-o-molde.md) (as convenções do toque)
- [K1 — O Molde, o `secao.gd`](K1-o-molde.md#godotscriptsminigamess03secaogd-novo-o-arquivo-inteiro) (o `secao.gd` inteiro, a função `momento` e o kit que a seção usa)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão e o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s03/hackeando_o_terminal.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `"S03_J13"` em `MINIGAMES` e na lista `minigames` da S03 | **da seção** |
| `godot/scripts/traducoes.gd` | `"Hackeando o Terminal"`, `"Responda!"` e o placar `Travas:` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_terminal()` e a linha `"S03_J13"` no `match` de `_prova_da_ficha` | **de todos** |

O `secao.gd` é da K1: esta ficha só chama. O `hackeando_o_terminal.gd.uid` sai do import
(`"$GODOT" --headless --path godot --import --quit`) e entra no commit.

Commit (sem trailer): `feat(terminal): a senha em chamada e resposta, o erro sem vermelho e a senha longa que abre a porta`.

### O que muda de hoje (a ficha velha)

| antes | depois |
| --- | --- |
| o verbo "Siga a senha!" | "Responda!" |
| o chão acende em vermelho no apito; o quadrante errado pisca em vermelho | a tela do quadrante errado pisca para `JANELA` 3 vezes em 1 batida, e a luz da seção cai 30 % por 1 batida (`SECAO.apagao`) |
| o terminal de 4,4 × 2,8 m, `#2a2233`; as travas verdes | o terminal de 6,0 × 3,6 m em `CASCO_ALTO`; as travas em `TUNGSTENIO`, 1,8, dono `"forja"` |
| o `gate` do mini-dungeon | `space-station-kit/door-double-closed`, que sobe 0,5 m a cada senha longa |
| a senha longa decidida pelo pico | a senha longa de 30 a 60 s, decidida pela batida em que a senha começa |
| a câmera `(0; 8,0; 13,0)` | `(0,2; 13,1; 7,2)`, olhando `(0,2; 1,6; −2,4)`: o terminal grande na tela |
| o passo para trás igual para todos | 0,4 m × `empurrao` × a Âncora; a volta em 0,5 s ÷ `velocidade` |
| sem momento | a `senha_longa`, com linha `momento` |

### `godot/scripts/minigames/s03/hackeando_o_terminal.gd` (novo, o arquivo inteiro)

```gdscript
extends Minigame
## Hackeando o Terminal (S03_J13). O terminal toca uma senha de quatro notas:
## cada uma de um dono e de um quadrante do touchpad. Na resposta, cada dono
## encosta no quadrante da nota dele, na vez dela. Senha certa acende uma trava;
## oito travas abrem a porta (todos vencem). De 30 a 60 s, a senha longa: oito
## notas, duas travas, e a porta sobe meio metro.
##
## A falha: o terminal apita, a tela do quadrante errado pisca, a luz cai, todos
## dão um passo para trás e uma trava apaga.
## O vencedor: coop. A porta abre (todos) ou não; o destaque é quem errou menos.
## O alto-falante do dono: a nota dele na chamada (só ele ouve), o clique no
## acerto, a nota no perfeito.
## O registro mede: o quadrante pedido contra o tocado, e onde o dedo encostou
## (a linha `entrada`); o tempo (o kit); o `momento` `senha_longa` e o `reta`.
## O robô: encosta no centro do quadrante na nota dele (ou 200 ms atrasado).
## Com menos de quatro: a senha tem sempre quatro (ou oito) notas; os donos se repetem.
## A régua: "Responda!" e o touchpad bastam; sem a tela, a nota no alto-falante
## e o lado na mão dizem de quem é a vez; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

const FICHA := {
	"slot": "S03_J13",
	"titulo": "Hackeando o Terminal",
	"verbo": "Responda!",
	"genero": "coop",
	"icone": "touchpad",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S03_J13",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Responda!", "segundos": 6.0},
	"gesto": "interact-right",
}

const CAMERA_POS := Vector3(0.2, 13.1, 7.2)
const CAMERA_OLHAR := Vector3(0.2, 1.6, -2.4)
const META := 8
const QUADRANTES := [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]
const PONTOS := [0, 20, 35, 50]
## A senha longa, em s de música (pela batida em que a senha começa).
const LONGA_DE := 30.0
const LONGA_ATE := 60.0
## As batidas de cada nota a partir do começo da chamada (a resposta é a mesma, um compasso depois).
const CURTA := [0.0, 1.0, 2.0, 3.0]
const LONGA := [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
const RAPIDA := [0.0, 1.0, 2.0, 2.25]  ## de 60 s ao fim: as duas últimas em semicolcheia
const PORTA_SOBE := 0.5  ## m por senha longa aberta
const PORTA_ABERTA := 3.0
const PASSO_ATRAS := 0.4
const VOLTA_S := 0.5

var j := {}
var senha: Array = []  ## {dono, q, bc (a chamada), b (a resposta), n, estado: "chamando", "esperando", "feito", "errou", "fora"}
var _fim_da_senha := -1.0
var _vale := 1
var _longa := false
var abertas := 0
var erros := [0, 0, 0, 0]
var _nota: Dictionary = {}  ## a nota em julgamento (para toque/falha)
var _telas: Array = []
var _tela_apagada: StandardMaterial3D
var _tela_erro := [-99.0, -99.0, -99.0, -99.0]  ## a batida do erro em cada quadrante
var _neon: Array = []  ## o neon de cada lugar, a 1,8
var _travas: Array = []
var _trava_fechada: StandardMaterial3D
var _trava_aberta: StandardMaterial3D
var _porta: Node3D
var _porta_y := 0.0
var _numero: Node3D
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	SECAO.montar(self, CAMERA_POS, CAMERA_OLHAR)
	Kit.caixa(self, Vector3(6.0, 3.6, 0.3), Vector3(0, 2.6, -5.2), Kit.material(Tema.CASCO_ALTO, 0.0, 0.9))
	_tela_apagada = Kit.material(Tema.JANELA, 0.0, 0.4)
	for l in 4:
		_neon.append(Tema.neon(Tema.JOGADOR[l], 1.8, l))
	for q in 4:
		var x := -1.45 if q % 2 == 0 else 1.45
		var y := 3.45 if q < 2 else 1.75
		_telas.append(Kit.caixa(self, Vector3(2.8, 1.6, 0.05), Vector3(x, y, -5.03), _tela_apagada))
	_porta = SECAO.peca(self, "space-station-kit/door-double-closed", "gate", Vector3(0, 0, -7.2), 0.0, 2.5)
	_trava_fechada = Kit.material(Tema.GRAFITE, 0.0, 0.8)
	_trava_aberta = Kit.material(Tema.TUNGSTENIO, 0.0, 0.5)
	Tema.emissivo(_trava_aberta, 1.8, "forja")
	for k in META:
		var trava := SECAO.disco8(self, 0.16, 0.06, Vector3(-2.45 + 0.7 * k, 4.75, -5.0), _trava_fechada)
		trava.rotation.x = PI * 0.5
		_travas.append(trava)
	_mostrar_o_numero()
	var linha := Kit.chapado(Tema.GRAFITE)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l, false)
		var placa: Node3D = nos.placa
		Kit.caixa(placa, Vector3(2.4, 0.02, 0.03), Vector3(0, 0.1, 0), linha)
		Kit.caixa(placa, Vector3(0.03, 0.02, 1.2), Vector3(0, 0.1, 0), linha)
		# o neon é um ShaderMaterial (G15): a vez forte é outro material, nunca o Tema.emissivo
		var vez_mat := Tema.neon(Tema.JOGADOR[l], 1.5, l)
		var vez := Kit.caixa(placa, Vector3(1.15, 0.02, 0.55), Vector3.ZERO, vez_mat)
		vez.visible = false
		nos["vez"] = vez
		nos["vez_mat"] = vez_mat
		nos["vez_perto"] = Tema.neon(Tema.JOGADOR[l], 2.4, l)
		maos_livres(p)
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		j[l] = {"n": 0, "z_antes": [false, false], "nos": nos, "z0": p.position.z}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## O número de travas abertas em cima do terminal, à direita: o `prototype-kit/number-N`
## (escala 1,5); sem o pacote, um Label3D em Archivo 700, 96 px, `ETIQUETA`.
func _mostrar_o_numero() -> void:
	if _numero:
		_numero.queue_free()
	var pos := Vector3(3.35, 4.45, -5.0)
	var nome := "prototype-kit/number-%d" % abertas
	if ResourceLoader.exists(Kit.caminho(nome)):
		_numero = Kit.peca(self, nome, pos, 0.0, 1.5)
		return
	var rotulo := Label3D.new()
	rotulo.text = str(abertas)
	rotulo.font = Tema.archivo(700)
	rotulo.font_size = 96
	rotulo.pixel_size = 0.006
	rotulo.modulate = Tema.ETIQUETA
	rotulo.outline_size = 16
	rotulo.outline_modulate = Tema.FITA
	rotulo.position = pos
	add_child(rotulo)
	_numero = rotulo


## Uma senha nova começando no compasso da batida `c`: a longa de 30 a 60 s, a
## rápida de 60 s ao fim, a curta antes. A senha vale 2 travas na longa e nas
## últimas 16 batidas.
func _nova_senha(c: float) -> void:
	senha.clear()
	var t := Ritmo.t_da_batida(c)
	var batidas: Array = CURTA
	if t >= LONGA_DE and t < LONGA_ATE:
		batidas = LONGA
	elif t >= LONGA_ATE:
		batidas = RAPIDA
	var n_notas := batidas.size()
	_longa = n_notas == 8
	var resposta := 8.0 if _longa else 4.0
	_vale = 2 if _longa or SECAO.na_reta(self) else 1
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
		var nota := {"dono": dono, "q": rng.randi_range(0, 3), "bc": c + float(batidas[i]),
			"b": c + resposta + float(batidas[i]), "n": int(j[dono].n), "estado": "chamando"}
		j[dono].n = int(j[dono].n) + 1
		nova_nota(dono, int(nota.n), Ritmo.t_da_batida(float(nota.b)))
		senha.append(nota)
	_fim_da_senha = c + 2.0 * resposta


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			anotar("entrada", l, {"o": "sensores", "toque": false})
			acabou[l] = true
	_nova_senha(BATIDA_DA_PRIMEIRA_NOTA)


func jogar(_dt: float) -> void:
	SECAO.pico(self)
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
		if str(nota.estado) == "esperando" and agora > Ritmo.t_da_batida(float(nota.b)) + FOLGA_PERDIDA:
			_nota = nota
			nota_perdida(int(nota.dono), int(nota.n))
			if str(nota.estado) == "esperando":
				nota.estado = "fora"  # o Escudo absorveu: nem erro, nem acerto
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
		anotar("entrada", l, {"o": "touchpad", "quadrante_pedido": int(nota.q), "quadrante": q,
			"x": snappedf(pos.x, 0.01), "y": snappedf(pos.y, 0.01), "n": int(nota.n)})
		_nota = nota
		if q == int(nota.q):
			julgar_toque(l, alvo, int(nota.n))
		else:
			nota_perdida(l, int(nota.n))
		return


## A chamada de uma nota: a tela do quadrante acende no neon do dono, a TV toca a
## nota com o tom dele, e só ele ouve a nota no alto-falante e sente o lado na mão.
func _chamar(nota: Dictionary) -> void:
	var dono: int = nota.dono
	var tela: MeshInstance3D = _telas[int(nota.q)]
	Som.tocar("nota", tela.global_position, -4.0, TOM_DO_LUGAR[dono])
	Forja.som_falante(dono, "nota:%d" % dono, 0.6)
	if int(nota.q) % 2 == 0:
		Forja.som_haptica(dono, "pulso", "", 0.35)
	else:
		Forja.som_haptica(dono, "", "pulso", 0.35)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	marcar(l, PONTOS[julgamento])
	_nota.estado = "feito"
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.4)
	var p := jogador(l)
	if p:
		p.gesto("interact-right", 0.3)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	if not treinando:
		erros[l] += 1
	_nota.estado = "errou"
	_tela_erro[int(_nota.q)] = Ritmo.batida()


## A resposta acabou: a senha abre uma trava (duas na longa e na reta), ou o terminal apita.
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
		_apito()
		return
	abertas = mini(META, abertas + _vale)
	_mostrar_o_numero()
	Som.tocar("confirma", _porta.global_position, 0.0)
	for l in presentes():
		if conectado(l):
			Forja.sentir(l, "acerto")
	if _longa:
		_senha_longa()
	if abertas >= META:
		_abrir_a_porta()


## O apito: uma trava apaga, a luz cai 30 % por 1 batida, e cada hacker dá um
## passo para trás (0,4 m × Peso × Âncora) e volta em 0,5 s ÷ Passo.
func _apito() -> void:
	abertas = maxi(0, abertas - 1)
	_mostrar_o_numero()
	SECAO.apagao(self)
	Som.tocar("falha", _porta.global_position, 0.0)  # o tropeço, nunca um bipe: o 03 proíbe o «buzz» de erro
	for l in presentes():
		if conectado(l):
			Forja.sentir(l, "golpe")
		var p := jogador(l)
		if p == null:
			continue
		p.gesto("emote-no", 0.5)
		var z0 := float(j[l].z0)
		var recuo := PASSO_ATRAS * SECAO.gancho(l, "empurrao") * (1.0 - Itens.resiste_a_empurrao(l))
		var tw := p.create_tween()
		tw.tween_property(p, "position:z", z0 + recuo, 0.15)
		tw.tween_property(p, "position:z", z0, VOLTA_S / SECAO.gancho(l, "velocidade"))


## A senha longa abriu: a porta sobe meio metro e solta vapor, os quatro erguem
## o braço, o pulso corre a roda dos controles. Degrau estrondo.
func _senha_longa() -> void:
	_porta_y = minf(PORTA_ABERTA, _porta_y + PORTA_SOBE)
	var tw := _porta.create_tween()
	tw.tween_property(_porta, "position:y", _porta_y, 60.0 / Ritmo.bpm)
	var base := _porta.global_position
	SECAO.degrau(self, -1, "estrondo", base + Vector3(0, 0.3, 0.6), Tema.ETIQUETA)
	Som.tocar("portao", base, 0.0)
	momento("senha_longa", -1, base, 3.0 + _porta_y, {"travas": abertas, "porta_y": snappedf(_porta_y, 0.01)})
	var roda := presentes().filter(func(x): return conectado(x))
	for x in roda:
		var p := jogador(x)
		if p:
			p.gesto("interact-right", 0.6)
	for x in roda:
		Forja.som_haptica(x, "pulso", "pulso", 0.35)
		await get_tree().create_timer(0.25 * 60.0 / Ritmo.bpm).timeout


func _abrir_a_porta() -> void:
	coop_venceu = true
	Som.tocar("portao", _porta.global_position, 3.0)
	Som.tocar("sucesso", _porta.global_position, 0.0)
	var tw := _porta.create_tween()
	tw.tween_property(_porta, "position:y", PORTA_ABERTA, 1.0)
	for l in presentes():
		Forja.sentir(l, "explosao")
		acabou[l] = true


func _mostrar(agora_b: float) -> void:
	for k in _travas.size():
		(_travas[k] as MeshInstance3D).material_override = _trava_aberta if k < abertas else _trava_fechada
	# as telas: acesas no neon do dono por 0,9 batida na chamada; o erro pisca para JANELA 3 vezes em 1 batida
	for q in 4:
		var tela: MeshInstance3D = _telas[q]
		var mat: Material = _tela_apagada
		for nota in senha:
			if int(nota.q) == q and agora_b >= float(nota.bc) and agora_b < float(nota.bc) + 0.9:
				mat = _neon[int(nota.dono)]
		var desde := agora_b - float(_tela_erro[q])
		if desde >= 0.0 and desde < 1.0:
			var dono := -1
			for nota in senha:
				if int(nota.q) == q and str(nota.estado) == "errou":
					dono = int(nota.dono)
			if dono >= 0:
				mat = _neon[dono] if int(desde * 6.0) % 2 == 0 else _tela_apagada
		tela.material_override = mat
	# a vez na placa: do momento da chamada até a resposta; mais forte 1 aviso antes (o Faro)
	for l in presentes():
		var nos: Dictionary = j[l].nos
		var vez: MeshInstance3D = nos.vez
		vez.visible = false
		for nota in senha:
			if int(nota.dono) == l and str(nota.estado) == "esperando":
				var c: Vector2 = QUADRANTES[int(nota.q)]
				vez.position = SECAO.no_molde(c.x, c.y, 0.11)
				vez.visible = true
				var perto := Ritmo.t_musica() >= Ritmo.t_da_batida(float(nota.b)) - SECAO.aviso_s(l)
				vez.material_override = nos.vez_perto if perto else nos.vez_mat
				break


## Coop: o kit grava vencedor −1 (H08); o destaque é quem errou menos.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(_antes)
	return int(lista[0]) if not lista.is_empty() else -1


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

### `godot/scripts/minigames/catalogo.gd`

Em `MINIGAMES`: `"S03_J13": preload("res://scripts/minigames/s03/hackeando_o_terminal.gd"),`. Na S03 de `SECOES`,
acrescente `"S03_J13"` à lista `minigames`, depois do `"S03_J12"`.

### `godot/scripts/traducoes.gd`

`"Hackeando o Terminal": "Hacking the Terminal"` e `"Responda!": "Answer!"`. Em `EN_PADROES`:
`["^Travas: (\\d+) de (\\d+)$", "Locks: $1 of $2"]`.

## Como se joga

- **A faixa:** `mus_s03_j13`, 140 BPM, Sol menor ("arpejos em fusas, urgência"). Até a H05, a sintetizada da seção a
  100 bpm.
- **A senha:** quatro notas. Cada nota tem **um dono** (um dos presentes) e **um quadrante** do touchpad (em cima à
  esquerda, em cima à direita, embaixo à esquerda, embaixo à direita). Os donos: a lista dos presentes com controle,
  repetida até quatro e embaralhada pela semente (com quatro, cada um tem uma nota; com dois, duas; com um, as
  quatro). Os quadrantes são sorteados.
- **A chamada** (o compasso da senha, a partir da batida `C`): na batida da nota `k`, a tela do quadrante dela acende
  no neon do dono, a TV toca a nota com o tom do dono, e **o alto-falante do controle dele toca a nota dele** (o
  segredo: só ele ouve que é com ele). A mão dele sente um pulso no lado do quadrante (o esquerdo ou o direito).
- **A resposta** (o compasso seguinte): na mesma batida da chamada, mais 4 (8 na longa), o dono da nota `k`
  **encosta** o dedo no quadrante dela. O instante em que um dedo encosta (não estava encostado) é o toque. O
  quadrante certo vai a `julgar_toque`; o errado é erro. Encostar sem nota dele na janela não conta. A nota passou:
  nota perdida.
- **A senha abre** se nenhuma nota saiu erro: uma trava acende. **A porta tem 8 travas.** Com um erro, no fim da
  resposta, **o terminal apita** e uma trava apaga. A senha seguinte começa no compasso depois da resposta.
- **A curva, pela batida em que a senha começa:**
  - de 0 a 30 s, a curta: notas em `C + 0, 1, 2, 3`, resposta em `C + 4 + …`;
  - de 30 a 60 s, a **longa**: 8 notas, chamada em 2 compassos (`C + 0 … 7`) e resposta em 2 (`C + 8 + …`); vale 2
    travas e sobe a porta 0,5 m;
  - de 60 s ao fim, a rápida: `C + 0, 1, 2 e 2,25` (as duas últimas em semicolcheia), resposta em `C + 4 + …`;
  - nas últimas 16 batidas, cada senha aberta vale 2 travas.
- **Quem está errando** (`Ritmo.simples[l]`) não recebe as notas 5 a 8 da senha longa (os donos delas saem dos
  outros). A senha não muda para ele: é coop.
- **Os pontos por julgamento** (os do hacker, para o destaque): `[0, 20, 35, 50]`.
- **O fim:** a oitava trava faz `coop_venceu = true`, a porta sobe 3 m e todos acabam. Os 90 s de música sem a porta:
  não venceram. O registro grava `vencedor` −1 (coop); `destaque()` é quem errou menos; no empate, os pontos; depois,
  o lugar.
- **Com menos de quatro:** a senha tem sempre 4 (ou 8) notas, e os donos se repetem. Sozinho, as quatro são dele: é a
  mesma senha, mais corrida. **O controle que cai:** as notas dele na senha em curso não contam (nem erro, nem
  acerto; a senha abre com as outras); ele sai da lista de donos até voltar. **Sem touchpad:** o lugar acaba no
  `iniciar_jogo()`, sem erro, e grava `entrada` `sensores` `toque: false`.

### O robô

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

## A cena

- **A câmera:** fixa, lente da arena (35 mm, 37,8°), mais alta e mais perto do terminal que a da seção:
  `camera_pos = Vector3(0.2, 13.1, 7.2)`, `camera_olhar = Vector3(0.2, 1.6, -2.4)`. As bancadas embaixo e o terminal
  grande no terço de cima da tela. Não corta. No pico, recua 10 % pelo `SECAO.pico`.
- **A luz:** a da seção (petróleo, `SECAO.montar`). No apito, a luz cai 30 % por 1 batida (`SECAO.apagao`). Na senha
  longa, o degrau estrondo (tremor de 0,05 m por 2 batidas).
- **O terminal:** `Kit.caixa(6,0 × 3,6 × 0,3)` em `(0; 2,6; −5,2)`, `CASCO_ALTO`. As quatro telas, `Kit.caixa(2,8 ×
  1,6 × 0,05)` em `(±1,45; 3,45 ou 1,75; −5,03)`: apagadas em `JANELA`; acesas no neon do dono a 1,8 por 0,9
  batida. A tela do erro pisca entre o neon do dono e `JANELA` 3 vezes em 1 batida.
- **As travas:** oito `SECAO.disco8(0,16; 0,06)` de frente (`rotation.x = PI/2`) em `(−2,45 + 0,7k; 4,75; −5,0)`.
  Fechadas: `GRAFITE`; abertas: `TUNGSTENIO` com emissão 1,8 (dono `"forja"`).
- **O número:** `prototype-kit/number-N` (N de 0 a 8, as travas abertas), escala 1,5, em `(3,35; 4,45; −5,0)`. Sem o
  pacote, um `Label3D` com o número, em Archivo 700, 96 px, `ETIQUETA`, contorno `FITA`.
- **A porta:** `space-station-kit/door-double-closed`, escala 2,5, em `(0; 0; −7,2)` (reserva: `gate`). Sobe 0,5 m a
  cada senha longa aberta, em 1 batida; na oitava trava, 3 m, em 1 s.
- **Na placa:** a cruz dos quadrantes (`Kit.caixa(2,4 × 0,02 × 0,03)` e `(0,03 × 0,02 × 1,2)`) em `GRAFITE`; o
  quadrante da vez, `Kit.caixa(1,15 × 0,02 × 0,55)`, no neon do jogador a 1,5, e a 2,4 a partir de 1 aviso antes da
  resposta.
- **O hacker:** o cavaleiro em `(RAIAS[l] − 1,45; 0,05; 0,35)`, de perfil, de mãos livres (`maos_livres`).
- **O que brilha e de quem é:** as telas e o quadrante da vez, no neon de quem é a nota; as travas, no tungstênio da
  forja; os dois dedos, no neon do jogador. A cor de cada lugar aparece só nas notas dele.
- **Nada liso, e nenhuma cor fora do tema:** nenhuma cor escrita em hexadecimal no arquivo; o erro não tem vermelho.

## O som

Os ids são os do [mapa do áudio](../o-time/o-mapa-do-audio.md).

| evento | na TV | no controle do dono |
| --- | --- | --- |
| a chamada de uma nota | `nota` (`sint_nota`, a nota na TV), −4 dB, com o tom do dono (`TOM_DO_LUGAR`) | **a nota dele**: `Forja.som_falante(dono, "nota:%d" % dono, 0.6)` (o segredo) |
| a resposta certa | a nota (o kit) | Ressonância: a nota (o kit); bom e ótimo: `Forja.som_falante(l, "clique", 0.4)` (`mod_clique`) |
| a resposta errada | a nota quebrada (o kit) | a nota quebrada (o kit) |
| a senha abre | `confirma` (`confirma_0..2`, `sint_confirma`), 0 dB | — |
| a senha longa abre | `confirma` e `portao` (`portao_0`), 0 dB | — |
| o apito | só `falha` (`falha_0..2`, que a `fx_tropeco_0..2` substitui), 0 dB: o tropeço da sala. Nenhum bipe e nunca o `jin_apito`, que é o fim de todo minigame (o 03 proíbe o «buzz» de erro) | — |
| a porta abre (a vitória) | `portao`, +3 dB, e `sucesso` (`vitoria_sala_0..1`), 0 dB | — |

**A faixa:** `mus_s03_j13` (140 BPM, Sol menor, a fazer). Até a H05, a sintetizada da seção a 100 bpm.

## O controle

| evento | vibração | háptica e alto-falante | luz | gatilho | para os outros |
| --- | --- | --- | --- | --- | --- |
| a chamada da nota dele | — | a nota dele no alto-falante a 0,6; `"pulso"` a 0,35 no atuador do lado do quadrante (o esquerdo para os quadrantes 0 e 2, o direito para 1 e 3) | — | R2 Off | ninguém mais ouve nem sente |
| a resposta | o kit | o clique a 0,4, ou a nota no perfeito | o kit: branco no perfeito | — | nada |
| a senha abre | `Forja.sentir(l, "acerto")` em todos | — | — | — | é para todos |
| a senha longa abre | — | o pulso em roda: `Forja.som_haptica(x, "pulso", "pulso", 0.35)` em cada um, na ordem dos lugares, 1/4 de batida um do outro | — | — | é para todos |
| o apito | `Forja.sentir(l, "golpe")` em todos (1,0/0,6/250 ms) | — | o kit, no erro de quem errou | — | é para todos |
| a porta abre | `Forja.sentir(l, "explosao")` em todos | — | — | — | é para todos |

**Sem o controle na mão:** o robô encosta pelo `Forja.robo_tocar`; a prova lê as linhas `sensacao` (F05) do apito, da
trava e da porta.

**O que espera ela** (o ESPERA-ELA do quadro): no Linux, o touchpad também vira mouse; a regra udev
`LIBINPUT_IGNORE_DEVICE=1` pede o sudo dela. Esta ficha não depende da regra (o jogo lê o touchpad pelo SDL), e nada
muda aqui quando ela entrar.

## O cavaleiro

O cavaleiro é o da montagem (G13), inteiro, de mãos livres. Pode ser de outra raça: esta ficha usa só o esqueleto
comum e as animações `interact-right` (a resposta e o braço erguido da senha longa) e `emote-no` (o apito).

| stat | gancho | o que muda no Terminal | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o passo para trás do apito: 0,4 m × `empurrao` (× 0,5 com a Âncora) | 0,46 m | 0,40 m | 0,34 m |
| Passo | `velocidade` | a volta do passo para trás: 0,5 s ÷ `velocidade` | 0,53 s | 0,50 s | 0,47 s |
| Fôlego | `levantar` | não age: ninguém cai | — | — | — |
| Faro | `pista` | o quadrante da vez na placa sobe de 1,5 a 2,4 antes da resposta | −40 ms | 0 | +40 ms |

Os itens: o Martelo e o Escudo são do kit (a nota que o Escudo absorve sai como "fora": nem erro, nem acerto). A
Âncora reduz o passo para trás à metade (`Itens.resiste_a_empurrao(l)`: 0,5 com ela, 0 sem). A Lanterna entra pelo
`SECAO.aviso_s`.

## As reações

- **Carimbos que o Terminal pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar) e `car_acorde` (os quatro na Ressonância no mesmo tempo 1: não acontece, porque cada nota tem um dono só).
  O `car_por_um_fio` e o `car_virada` não se aplicam ao coop; o `car_emburrado` também não (não há último).
- **Adesivos:** na seção 3, ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: a senha longa abre** (`senha_longa`). De 30 a 60 s, a senha de 8 notas é chamada em 2 compassos e
respondida em 2. Quando as 8 saem, duas travas acendem juntas, a porta sobe meio metro e solta vapor (as 50 faíscas
em `ETIQUETA` do estrondo), e os quatro hackers erguem o braço. Degrau estrondo: tremor de 0,05 m por 2 batidas.

- **O rastro:** as travas acesas ficam acesas; a porta fica meio metro mais alta a cada senha longa.
- **A curva:** de 0 a 30 s, a senha de 4; de 30 a 60 s, a longa; de 60 s ao fim, a de 4 com as duas últimas em
  semicolcheia; nas últimas 16 batidas, cada senha vale 2 travas.
- **Ensina sem falar:** a nota de cada um soa no alto-falante do controle dele, e o pulso vem do lado certo: a mão
  sente que é com ela. O quadrante aceso no terminal é o quadrante no touchpad, na mesma posição.
- **Quem está perdendo:** é coop. Quem erra vê o quadrante dele piscar; o apito empurra os quatro: todo mundo paga o
  erro, e ninguém é apontado no placar. Quem está errando deixa de receber as notas 5 a 8 da longa.
- **O que saiu:** o chão vermelho do apito (o vermelho não é cor de erro de jogo na bíblia).
- **A nota de hoje:** 4; com a porta à vista e a senha longa com estrondo, 5.

**Como o jogador do time confere** (a mesa boa: os quatro `bom`, semente 7; o `--robo` sem valor da
`prova_do_jogo.sh` já é `bom`):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | a primeira senha abre antes de 10 s (`abertas` ≥ 1 aos 10 s) | o quadro de 6 s mostra uma tela acesa no neon de um dono |
| 4. o momento | pelo menos 2 linhas `momento` `senha_longa` com `t_musica` entre 30 e 60 (contando a resposta, até 64) | a porta mais alta no quadro de 60 s que no de 30 s |
| 5. a curva | notas por segundo de 30 a 60 s ≥ 1,0 × as de 0 a 30 s, e a linha `momento` `reta` existe | o quadro de 45 s mostra a câmera mais longe que o de 15 s |
| 6. a falha | (mesa fraca) pelo menos 1 senha longa termina no apito | um quadro mostra a tela piscando em `JANELA` e a luz mais baixa |
| 7. quem perde joga | (mesa fraca) cada lugar tem nota em cada senha curta | todos os hackers aparecem em 100 % dos quadros |
| 8. a câmera | cada `senha_longa` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,15 | a porta inteira e as 8 travas se veem no quadro de 480 × 270 |
| 9. o impacto | para cada `senha_longa`, uma linha `sensacao` `acerto` de cada presente a até 16,7 ms | o quadro seguinte mostra a porta mais alta |
| 10. o placar no mundo | `abertas` bate com o número em cima do terminal e com as travas acesas no fim | o número e as travas se leem no quadro de 480 × 270 |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova roda com a mesa boa e
confere os itens 1, 4, 5, 8, 9 e 10; os itens 6 e 7 (a mesa fraca) esperam.

## Pronto quando

O Terminal joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o bom abre a porta;
o ruim faz apitar). O cabo que cai e volta não quebra a senha. O fim tem sempre o destaque, e `vencedor` −1 no
registro. A senha longa aparece entre 30 e 60 s, e a `senha_longa` está no registro com os mínimos da diversão.
Nenhum vermelho na tela. `SALA=S03_J13 bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, com a
prancha olhada. O catálogo e as traduções têm as linhas desta ficha, o `.uid` está no commit, e o commit, sem
trailer, é `feat(terminal): a senha em chamada e resposta, o erro sem vermelho e a senha longa que abre a porta`.

## Provas

Na sessão: `SALA=S03_J13 bash tests/prova_do_jogo.sh`, `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### `godot/testes/prova_do_jogo.gd`

No `match` de `_prova_da_ficha`: `"S03_J13": await _prova_do_terminal()`.

```gdscript
## O Terminal (S03_J13): a senha chama cada dono; a resposta do robô chega pelo
## toque simulado; a senha longa abre pelo menos 2 vezes; o fim é coop, com destaque.
func _prova_do_terminal() -> void:
	var donos := {}
	var abertas_10 := [-1]
	var olhar := func(m) -> void:
		if donos.is_empty():  # o primeiro quadro da fase jogo: a primeira senha
			for nota in m.senha:
				donos[int(nota.dono)] = true
		if abertas_10[0] < 0 and Ritmo.t_musica() >= 10.0:
			abertas_10[0] = int(m.abertas)
	var mg = await _joga_o_minigame("S03_J13", 130.0, olhar)
	if mg == null:
		return
	_esperar(donos.size() == 4, "Terminal: a primeira senha tem uma nota de cada um (%s)" % [donos.keys()])
	_esperar(mg.coop, "Terminal: fechou como coop")
	_esperar(abertas_10[0] >= 1, "Terminal: a primeira trava antes de 10 s (%d)" % abertas_10[0])
	var respostas := 0
	for l in 4:
		respostas += int(mg.contagem[l][1]) + int(mg.contagem[l][2]) + int(mg.contagem[l][3])
	_esperar(respostas >= 8, "Terminal: o robô respondeu a senha (%d respostas)" % respostas)
	_esperar(mg.destaque() >= 0, "Terminal: o fim tem o destaque")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S03_J13")
	var longas := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "senha_longa")
	var no_meio := longas.filter(func(e): return float(e.t_musica) >= 30.0 and float(e.t_musica) <= 64.0)
	_esperar(no_meio.size() >= 2, "Terminal: %d senhas longas abertas entre 30 e 64 s (o mínimo é 2)" % no_meio.size())
	for a in longas:
		var x := float(a.get("x_tela", 0.0))
		_esperar(x >= 0.2 and x <= 0.8 and float(a.get("altura_tela", 0.0)) >= 0.15, "Terminal: a porta na tela (%s)" % [a])
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1 or mg.coop_venceu, "Terminal: a linha momento reta (ou a porta abriu antes)")
```

A checagem pede a senha longa porque a mesa boa a abre; com a semente 7 e os quatro `bom` (95 % por nota), a chance
de uma senha de 8 abrir é de 66 %, e há 4 senhas longas entre 30 e 60 s a 140 BPM (3 a 100 bpm). Se a semente 7 der
menos de 2, o problema é de desenho, não da prova: mostre o registro e não mude a semente.

### O que o registro mede

- O kit: uma `nota` por nota da senha (no dono, com o `t_alvo` da resposta) e um `toque` por resposta (ou perdida).
- A linha `entrada` em cada encostar na vez: **o quadrante pedido contra o tocado** e o ponto exato. Um touchpad com
  um canto morto (um quadrante que nunca chega certo) ou com os eixos trocados (o quadrante espelhado) aparece aqui.
- A `momento` `senha_longa` (`travas`, `porta_y`, `x_tela`, `altura_tela`) e a `reta` (`ordem` vazia: coop).

### As pranchas que o jogador do time olha

- de 4 a 10 s: as telas acendendo, uma por dono, e a primeira trava;
- de 30 a 64 s: a porta subindo a cada senha longa, os braços erguidos;
- um quadro de apito: a tela piscando em `JANELA`, a luz mais baixa, os hackers um passo atrás;
- o fim: as travas e o número batendo.

### O que o André joga e sente

`./run-local.sh -- --sala=S03_J13` com quatro: a nota no controle diz "é você" sem ninguém olhar; o pulso vem do lado
certo; a resposta em ordem vira uma frase; o apito e o passo para trás fazem a turma se cobrar; e a porta subindo na
senha longa faz a sala comemorar.

### Armadilhas

- **`_nota` antes de `julgar_toque` e `nota_perdida`:** o kit não diz qual nota; o `toque` e a `falha` leem daqui.
- **Encostar, não estar:** o toque é o dedo que **encosta** (não estava encostado no quadro anterior); arrastar o
  dedo de um quadrante a outro não conta.
- **A nota fora** (o dono sem controle, ou o erro que o Escudo absorveu) não é erro nem acerto; a senha abre com as
  outras.
- **Os materiais das travas e das telas** se criam uma vez no `montar` e só se trocam no `_mostrar`.
- **A senha rápida** (de 60 s ao fim) tem duas notas a 1/4 de batida: com dois jogadores, o mesmo dono pode ter as
  duas; o `_resposta` pega sempre a mais cedo dele.
- **O passo para trás** volta para o `z0` guardado no `montar`, nunca para a posição do quadro.
- **O treino** julga e não mexe nas travas.
