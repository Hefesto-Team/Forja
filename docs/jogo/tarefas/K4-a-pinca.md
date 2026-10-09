# K4 — A Pinça

**Sprint:** K · **Slot:** S03_J14 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, H07, G10, G14, G15, K1 (o `secao.gd`)

## Por quê

A pinça são dois dedos no touchpad: pegar o ferro quente na nota, esticar enquanto a nota longa dura e soltar no fim
dela. Hoje passar de 0,45 é a regra, e ninguém vê o 0,45. Com a troca (o puxa-ferro), quanto mais esticado na
soltura, mais vale, mas o ferro tem um ponto de estalo escondido: passou dele, o ferro estala e o ferreiro cai
sentado. Cada peça vira um "solta, solta!" da sala.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [O índice da seção](K-o-molde.md) (as convenções do toque)
- [K1 — O Molde](K1-o-molde.md) (o `secao.gd` inteiro, a função `momento` e o kit que a seção usa)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão e o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s03/a_pinca.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `"S03_J14"` em `MINIGAMES` e na lista `minigames` da S03, depois do `"S03_J13"` | **da seção** |
| `godot/scripts/traducoes.gd` | `"A Pinça"`, `"Estique!"` e o placar `Ferro:` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_pinca()` e a linha `"S03_J14"` no `match` de `_prova_da_ficha` | **de todos** |

O `secao.gd` é da K1: esta ficha só chama. Se a K1 ainda não entrou, esta espera. O `a_pinca.gd.uid` sai do import
(`"$GODOT" --headless --path godot --import --quit`) e entra no commit.

Commit (sem trailer): `feat(pinca): o puxa-ferro, o estalo escondido e o ferreiro que cai sentado`.

### O que muda de hoje (a ficha velha)

| antes | depois |
| --- | --- |
| o verbo "Segure e solte!" | "Estique!" |
| soltar abaixo de 0,45 é erro, mesmo no tempo | acima de 0,30 vale 1; a partir de 0,65, 2; a partir de 0,80, 3; abaixo de 0,30, a peça cai |
| sem risco | o ponto de estalo, sorteado entre 0,72 e 0,90 a cada peça e escondido; passou, o ferro estala e vale zero |
| a peça quente `#ff7a2a`, a estante `#5b6275`, as faíscas em laranja e amarelo | o ferro em `OXIDO_BRILHO`, `TUNGSTENIO` a partir de 0,60 e `ETIQUETA` a 0,04 do estalo; a estante em `OXIDO`; as faíscas de falha em `TUNGSTENIO` |
| a câmera `(0; 8,6; 12,7)` | a da seção, `(0,2; 11,2; 8,4)` |
| a linha de montagem no pico do kit | de 27 a 53 s, decidida pela batida de pegar |
| o vencedor por peças encaixadas | o vencedor pelo ferro (a soma dos valores) |
| sem momento | o `estalo`, com linha `momento` |

### `godot/scripts/minigames/s03/a_pinca.gd` (novo, o arquivo inteiro)

```gdscript
extends Minigame
## A Pinça (S03_J14). O ferro quente aparece na placa (o touchpad). Dois dedos
## pegam na nota do lugar (o hoqueto), esticam enquanto a nota longa dura e
## soltam no fim dela. Quanto mais esticado na soltura, mais vale (0,30 vale 1,
## 0,65 vale 2, 0,80 vale 3). O ferro tem um ponto de estalo escondido, sorteado
## a cada peça: passou dele, o ferro estala, uma metade bate no rosto do
## ferreiro e ele cai sentado.
##
## A falha: a peça cai e espirra faísca (pegar ou soltar fora do tempo, ou
## soltar abaixo de 0,30); o estalo é a falha que a sala vê.
## O vencedor: mais ferro (a soma dos valores das peças encaixadas).
## O alto-falante do dono: o clique no pegar, a coleta no encaixe, o tique no
## branco, a martelada no estalo, a nota no perfeito.
## O registro mede: a abertura na soltura, a máxima, quanto tempo os dois dedos
## seguraram e se um dedo se perdeu antes (a linha `entrada`); o tempo (o kit);
## o `momento` `estalo` e o `reta`.
## O robô: pega com os dois, estica até o alvo dele e solta os dois juntos.
## Com menos de quatro: nada muda.
## A régua: "Estique!" e o touchpad bastam; sem a tela, a nota de pegar e a de
## soltar se ouvem e a vibração sobe com o ferro; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

const FICHA := {
	"slot": "S03_J14",
	"titulo": "A Pinça",
	"verbo": "Estique!",
	"genero": "tct",
	"icone": "touchpad",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S03_J14",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "toque"],
	"material": "metal",
	"microjogo": {"verbo": "Estique!", "segundos": 6.0},
	"gesto": "interact-right",
}

const CAMERA_POS := Vector3(0.2, 11.2, 8.4)
const CAMERA_OLHAR := Vector3(0.2, 0.9, -0.3)
## O valor pela abertura na soltura (em larguras do touchpad): [a partir de, vale].
const VALE := [[0.80, 3], [0.65, 2], [0.30, 1]]
## O ponto de estalo, sorteado a cada peça; de 53 s ao fim, mais baixo; a primeira peça, 0,72.
const ESTALO_DE := 0.72
const ESTALO_ATE := 0.90
const ESTALO_APERTA_DE := 0.68
const ESTALO_APERTA_ATE := 0.85
const ESTALO_TREINO := 0.72
const QUENTE := 0.60  ## a partir daqui, o ferro em TUNGSTENIO
const BRANCO := 0.04  ## a esta distância do estalo, o ferro em ETIQUETA (o branco)
const SOPRO := 0.30  ## a partir daqui, a vibração sobe e o fole sopra
## A linha de montagem, em s de música (pela batida de pegar): duas peças por compasso.
const LINHA_DE := 27.0
const LINHA_ATE := 53.0
const APERTA_DE := 53.0
const PONTOS := [0, 20, 35, 50]
const POR_VALOR := 40
const RASTRO_S := 4.0
const ESTANTE_Z := -1.6

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var _morno: StandardMaterial3D
var _quente: StandardMaterial3D
var _branco: Material
var _frio: StandardMaterial3D


func montar() -> void:
	SECAO.montar(self, CAMERA_POS, CAMERA_OLHAR)
	_morno = Kit.material(Tema.OXIDO_BRILHO, 0.8, 0.6, "forja")
	_quente = Kit.material(Tema.TUNGSTENIO, 1.8, 0.5, "forja")
	_branco = Kit.chapado(Tema.ETIQUETA)
	_frio = Kit.material(Tema.OXIDO, 0.0, 0.55)
	if ResourceLoader.exists(Kit.caminho("factory-kit/crane-magnet")):
		Kit.peca(self, "factory-kit/crane-magnet", Vector3(0, 4.8, -3.4), 0.0, 2.0)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l, false)
		var placa: Node3D = nos.placa
		var peca := Kit.caixa(placa, Vector3(1.0, 0.08, 0.12), Vector3(0, 0.14, 0), _morno)
		peca.visible = false
		nos["peca"] = peca
		var regua := Kit.caixa(placa, Vector3(2.4, 0.02, 0.05), Vector3(0, 0.1, 0.66), Tema.neon(Tema.JOGADOR[l], 1.5, l))
		regua.visible = false
		nos["regua"] = regua
		Kit.peca(self, "wood-structure", Vector3(float(nos.cx), 0, ESTANTE_Z), 0.0, 1.2)
		var braco := SECAO.peca(self, "factory-kit/robot-arm-a", "wood-support", Vector3(float(nos.cx) + 1.1, 0, -1.0), -PI * 0.5, 1.5)
		nos["braco"] = braco
		nos["braco_y"] = braco.rotation.y
		maos_livres(p)
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		j[l] = {"n": 0, "b": -1.0, "len": 2.0, "estado": "pegar", "antes": false, "aberta": false,
			"abertura": 0.0, "maxima": 0.0, "estalo": ESTALO_TREINO, "primeira": true, "estalou": false,
			"pegou_t": 0.0, "soprou": false, "tiquei": false, "vib_b": -99.0, "pecas": 0, "ferro": 0,
			"estalos": 0, "fora": false, "nos": nos, "robo_n": -1, "robo_mira": 0.0, "robo_alvo": 0.8}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A próxima peça do lugar depois de `desde`: a batida de pegar, o tamanho da nota
## longa e o ponto de estalo. De 27 a 53 s (pela batida de pegar), a linha de
## montagem: duas por compasso, nota longa de 1 tempo.
func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	e.len = 2.0
	var b := proxima_batida(l, desde, 4.0, float(l))  # o kit dobra o passo na partitura simples
	var t := Ritmo.t_da_batida(b)
	if t >= LINHA_DE and t < LINHA_ATE and not Ritmo.simples[l]:
		b = proxima_batida(l, desde, 2.0, 0.5 * l)
		e.len = 1.0
	e.b = b
	if bool(e.primeira):
		e.estalo = ESTALO_TREINO
	elif Ritmo.t_da_batida(b) >= APERTA_DE:
		e.estalo = rng.randf_range(ESTALO_APERTA_DE, ESTALO_APERTA_ATE)
	else:
		e.estalo = rng.randf_range(ESTALO_DE, ESTALO_ATE)
	e.estado = "pegar"
	e.aberta = false
	e.antes = false
	e.abertura = 0.0
	e.maxima = 0.0
	e.soprou = false
	e.tiquei = false
	e.estalou = false
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			anotar("entrada", l, {"o": "sensores", "toque": false})
			acabou[l] = true
			continue
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
	SECAO.pico(self)
	var agora := Ritmo.t_musica()
	for l in presentes():
		var e: Dictionary = j[l]
		SECAO.mostrar_dedos(self, l, e.nos)
		_mostrar(l)
		if acabou[l] or float(e.b) < 0.0:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			e.n = int(e.n) + 1
			_proxima(l, Ritmo.batida() + 1.0)
		if str(e.estado) == "pegar":
			_pegar(l, e, agora)
		else:
			_segurar(l, e, agora)


func _dois(l: int) -> bool:
	return Forja.dedo(l, 0).z > 0.5 and Forja.dedo(l, 1).z > 0.5


func _abertura(l: int) -> float:
	var a := Forja.dedo(l, 0)
	var b := Forja.dedo(l, 1)
	return SECAO.distancia(Vector2(a.x, a.y), Vector2(b.x, b.y))


static func _valor(abertura: float) -> int:
	for v in VALE:
		if abertura >= float(v[0]):
			return int(v[1])
	return 0


func _pegar(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var sim := _dois(l)
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.antes = sim
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		e.pegou_t = agora
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		_perder(l, e)


func _segurar(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b) + float(e.len))
	if _dois(l):
		e.abertura = _abertura(l)
		e.maxima = maxf(float(e.maxima), float(e.abertura))
		_sentir_o_ferro(l, e)
		if float(e.abertura) > float(e.estalo):
			_estalar(l, e)
		elif agora > alvo + FOLGA_PERDIDA:
			_perder(l, e)  # segurou demais: a peça cai
		return
	# soltou (os dois, ou perdeu um): o instante é a soltura; vale a abertura do último quadro com os dois
	var dedos := int(Forja.dedo(l, 0).z > 0.5) + int(Forja.dedo(l, 1).z > 0.5)
	var valor := _valor(float(e.abertura))
	anotar("entrada", l, {"o": "dois_dedos", "abertura": snappedf(float(e.abertura), 0.01),
		"abertura_max": snappedf(float(e.maxima), 0.01), "estalo": snappedf(float(e.estalo), 0.01),
		"valor": valor, "segurou_ms": int((agora - float(e.pegou_t)) * 1000.0), "dedos_no_fim": dedos, "n": int(e.n)})
	if valor == 0:
		_perder(l, e)  # não esticou: a peça cai
	else:
		julgar_toque(l, alvo, int(e.n))


## O ferro na mão: até 0,30, a textura metal; daí até o estalo, o motor fraco
## sobe de 0,1 a 0,45 a cada quarto de tempo; no branco, um tique no alto-falante.
func _sentir_o_ferro(l: int, e: Dictionary) -> void:
	var a := float(e.abertura)
	if a < SOPRO:
		SECAO.textura(l, "metal")
	else:
		if not bool(e.soprou):
			e.soprou = true
			Som.tocar("sopro", (e.nos.placa as Node3D).global_position, -10.0)
		var b := Ritmo.batida()
		if b - float(e.vib_b) >= 0.25:
			e.vib_b = b
			var u := clampf((a - SOPRO) / (ESTALO_ATE - SOPRO), 0.0, 1.0)
			Forja.vibrar(l, 0.0, lerpf(0.1, 0.45, u), int(15000.0 / Ritmo.bpm))
	if not bool(e.tiquei) and a >= float(e.estalo) - BRANCO:
		e.tiquei = true
		Som.no_controle(l, "tique", 0.5)


## A nota perdida pelo kit (falha, ou o Escudo); se o Escudo absorveu, fecha a peça sem o erro.
func _perder(l: int, e: Dictionary) -> void:
	var n_antes := int(e.n)
	nota_perdida(l, n_antes)  # chama falha(), que fecha a peça
	if int(e.n) == n_antes:
		_fechar_peca(l)


func _estalar(l: int, e: Dictionary) -> void:
	e.estalou = true
	_estalo(l)
	_perder(l, e)  # o ferro estala com ou sem o Escudo; o Escudo só tira o erro


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if str(e.estado) == "pegar":
		if julgamento != Ritmo.PERFEITO:
			Forja.som_falante(l, "clique", 0.4)
		Forja.sentir(l, "toque")  # a pinça fecha no ferro
		e.estado = "segurar"
		e.n = int(e.n) + 1
		nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b) + float(e.len)))
		var p := jogador(l)
		if p:
			p.gesto("interact-right", 0.3)
		return
	_encaixar(l, _valor(float(e.abertura)))
	_fechar_peca(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	if not bool(e.estalou):
		# a peça cai e espirra faísca
		var peca: MeshInstance3D = e.nos.peca
		var onde := peca.global_position
		peca.visible = false
		var caindo := Kit.caixa(self, Vector3(0.4, 0.08, 0.12), onde, _morno)
		var tw := caindo.create_tween()
		tw.tween_property(caindo, "global_position:y", onde.y - 0.6, 0.3).set_ease(Tween.EASE_IN)
		tw.tween_callback(caindo.queue_free)
		Efeitos.faiscas(self, onde, Tema.TUNGSTENIO, 24, 0.8)
		Som.tocar("falha", onde, -6.0)
		var p := jogador(l)
		if p:
			p.gesto("emote-no", 0.5)
	_fechar_peca(l)


## A peça acabou (encaixada, caída ou estalada): o `n` sobe e a próxima vem. Depois
## do estalo, a peça volta à pinça só `SECAO.queda(l, 1)` tempos depois (o Fôlego).
func _fechar_peca(l: int) -> void:
	var e: Dictionary = j[l]
	var segurando := str(e.estado) == "segurar"
	var fim := float(e.b) + (float(e.len) if segurando else 0.0)
	if segurando and not treinando:
		e.primeira = false
	if bool(e.estalou):
		fim += SECAO.queda(l, 1.0)
	e.n = int(e.n) + 1
	_proxima(l, fim)


## A peça encaixa na estante: o comprimento diz o valor (0,25, 0,35 ou 0,45 m);
## nas últimas 16 batidas vale o dobro e sai em mostarda. O braço do robô gira.
func _encaixar(l: int, base: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	Forja.som_falante(l, "coleta", 0.7)
	if treinando:
		return
	var dobro := SECAO.na_reta(self)
	var valor := base * (2 if dobro else 1)
	e.pecas = int(e.pecas) + 1
	e.ferro = int(e.ferro) + valor
	marcar(l, POR_VALOR * valor)
	var k := int(e.pecas) - 1
	var pos := Vector3(float(nos.cx) - 0.6 + 0.4 * (k % 4), 0.9 + 0.25 * int(k / 4.0), ESTANTE_Z)
	Kit.caixa(self, Vector3(0.15 + 0.1 * base, 0.06, 0.1), pos, nos.pronta if dobro else _frio)
	Som.tocar("martelo", pos, -6.0)
	Efeitos.faiscas(self, pos, Tema.JOGADOR[l], 6 + 6 * base, 0.6)
	var braco: Node3D = nos.braco
	var y0 := float(nos.braco_y)
	var meia := 0.5 * 60.0 / Ritmo.bpm
	var tw := braco.create_tween()
	tw.tween_property(braco, "rotation:y", y0 + 0.6, meia)
	tw.tween_property(braco, "rotation:y", y0, meia)
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.4)


## O estalo: as duas metades chicoteiam, a do lado do ferreiro bate no rosto
## dele, ele cai sentado por 4 s e as metades ficam no chão 4 s. Degrau estrondo,
## as outras bancadas a 70 % por 1 batida.
func _estalo(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var peca: MeshInstance3D = nos.peca
	var onde := peca.global_position
	peca.visible = false
	e.estalos = int(e.estalos) + 1
	SECAO.degrau(self, l, "estrondo", onde, Tema.TUNGSTENIO)
	SECAO.so_um(self, l)
	Som.tocar("martelo", onde, 2.0, 0.8)
	Som.tocar("falha", onde, -4.0)
	Forja.vibrar(l, 0.8, 0.0, 80)
	Som.no_controle(l, "martelo", 0.8)
	var rosto := onde + Vector3(-1.4, 1.0, 0.0)
	var p := jogador(l)
	if p:
		rosto = p.global_position + Vector3(0, 1.5, 0)
		p.gesto("fall", RASTRO_S)
	for lado in [-1.0, 1.0]:
		var metade := Kit.caixa(self, Vector3(0.45, 0.08, 0.12), onde + Vector3(lado * 0.25, 0, 0), _quente)
		var chao := rosto + Vector3(lado * 0.5, -1.45, 0.4)
		var tw := metade.create_tween()
		if lado < 0.0:
			tw.tween_property(metade, "global_position", rosto, 0.15)  # a do lado do ferreiro bate no rosto
		tw.tween_property(metade, "global_position", chao, 0.25)
		tw.parallel().tween_property(metade, "rotation:y", lado * 1.2, 0.25)
		tw.tween_interval(RASTRO_S)
		tw.tween_callback(metade.queue_free)
	if not treinando:
		momento("estalo", l, onde, 1.2, {"abertura": snappedf(float(e.abertura), 0.01),
			"ponto": snappedf(float(e.estalo), 0.01), "treino": bool(e.primeira)})


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var peca: MeshInstance3D = nos.peca
	var regua: MeshInstance3D = nos.regua
	regua.visible = false
	if fase != "jogo" or acabou[l] or float(e.b) < 0.0:
		peca.visible = false
		return
	var agora := Ritmo.t_musica()
	if str(e.estado) == "pegar":
		peca.visible = agora >= Ritmo.t_da_batida(float(e.b)) - SECAO.aviso_s(l)
		peca.position = SECAO.no_molde(0.5, 0.5, 0.14)
		peca.rotation.y = 0.0
		peca.scale = Vector3(0.3, 1, 1)
		peca.material_override = _morno
		return
	regua.visible = agora >= Ritmo.t_da_batida(float(e.b) + float(e.len)) - SECAO.aviso_s(l)
	var a := Forja.dedo(l, 0)
	var b := Forja.dedo(l, 1)
	if a.z < 0.5 or b.z < 0.5:
		return  # entre a soltura e a próxima peça, o ferro fica onde estava
	var pa := SECAO.no_molde(a.x, a.y, 0.14)
	var pb := SECAO.no_molde(b.x, b.y, 0.14)
	peca.visible = true
	peca.position = (pa + pb) * 0.5
	peca.rotation.y = -atan2(pb.z - pa.z, pb.x - pa.x)
	peca.scale = Vector3(maxf(0.1, pa.distance_to(pb)), 1, 1)
	var ab := float(e.abertura)
	if ab >= float(e.estalo) - BRANCO:
		peca.material_override = _branco
	elif ab >= QUENTE:
		peca.material_override = _quente
	else:
		peca.material_override = _morno


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].ferro) != int(j[b].ferro):
		return int(j[a].ferro) > int(j[b].ferro)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Ferro: %d" % int(j[lugar].ferro)
	return super(lugar)
```

### `godot/scripts/minigames/catalogo.gd`

Em `MINIGAMES`: `"S03_J14": preload("res://scripts/minigames/s03/a_pinca.gd"),`. Na S03 de `SECOES`, acrescente
`"S03_J14"` à lista `minigames`, depois do `"S03_J13"`.

### `godot/scripts/traducoes.gd`

`"A Pinça": "The Tongs"` e `"Estique!": "Stretch!"`. Em `EN_PADROES`: `["^Ferro: (\\d+)$", "Iron: $1"]`.

## Como se joga

- **A faixa:** `mus_s03_j14`, 118 BPM, Si menor ("grave sujo, subterrâneo"). Até a H05, a sintetizada da seção a 100
  bpm.
- **A peça, duas notas:** **pegar** na batida `b`, o instante em que o segundo dedo encosta (os dois ficam
  encostados); e **soltar** na batida `b + L`, o primeiro quadro em que os dois já não estão encostados (perder um
  dedo no meio é soltar). Entre as duas, a nota longa: **esticar**, afastando os dedos.
- **O valor da peça** é a abertura (em larguras do touchpad, `SECAO.distancia`) no último quadro com os dois dedos:
  abaixo de 0,30, a peça cai (erro); de 0,30, vale 1; de 0,65, vale 2; de 0,80, vale 3.
- **O ponto de estalo:** sorteado a cada peça (`rng`), entre 0,72 e 0,90, e escondido. De 53 s ao fim (pela batida
  de pegar), entre 0,68 e 0,85. A primeira peça de cada um que chega a ser segurada estala sempre em 0,72 (a peça de
  treino: todo mundo vê o estalo antes de 10 s). Os dedos passaram do ponto: **o ferro estala**, a peça vale zero e
  conta como erro.
- **O aviso, visto e sentido:** o ferro vai de `OXIDO_BRILHO` a `TUNGSTENIO` a partir de 0,60 e fica `ETIQUETA` (o
  branco) a 0,04 do ponto de estalo. A vibração do motor fraco sobe de 0,1 (a 0,30) a 0,45 (a 0,90). No branco, um
  tique no alto-falante do dono.
- **O hoqueto em semínimas:** o lugar `l` pega em `4c + l` e solta `L = 2` tempos depois; as quatro notas longas se
  cruzam no compasso. Na partitura simples (`Ritmo.simples[l]`), uma peça a cada 2 compassos (o kit dobra o passo).
- **A linha de montagem, de 27 a 53 s** (pela batida de pegar): duas peças por compasso, pegar em `2k + 0,5·l`, e
  `L = 1`. Não há tempo de esticar muito: a tentação de passar é maior. Quem está na partitura simples fica fora
  dela.
- **O julgamento, no cruzamento** (as convenções da seção), com a janela que abre meio tempo antes. Pegar cedo (os
  dois dedos já encostados quando a janela abre) é julgado ali; soltar cedo é soltar. Não pegou até `FOLGA_PERDIDA`
  (140 ms) depois: nota perdida, e a soltura dessa peça nem existe. Segurou além da janela de soltar: nota perdida.
- **Os pontos:** por julgamento (erro, bom, ótimo, Ressonância) `[0, 20, 35, 50]`, em cada nota; a peça encaixada,
  `40 × valor`.
- **A reta (as últimas 16 batidas):** cada peça vale o dobro e sai em mostarda na estante.
- **Depois do estalo,** a próxima peça só vem `SECAO.queda(l, 1)` tempos depois do fim da nota longa (o Fôlego).
- **O fim** é do kit, em tempo de música: 80 s.
- **O vencedor:** mais ferro (a soma dos valores); no empate, os pontos; depois, o lugar.
- **Com menos de quatro:** nada muda. **O controle que cai:** a peça dele some, sem erro; ao voltar, a próxima é o
  próximo tempo dele pelo menos 1 tempo adiante. **Sem touchpad:** o lugar acaba no `iniciar_jogo()`, sem erro, e
  grava `entrada` `sensores` `toque: false`.

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if float(e.b) < 0.0:
		return
	if int(e.robo_n) != int(e.n) and str(e.estado) == "pegar":
		e.robo_n = int(e.n)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		# quanto esticar: na primeira peça, 0,80 (ele ainda não viu o branco); depois, quando
		# acerta, até o branco (o ponto menos 0,02); quando não, metade para em 0,75 e metade passa
		if bool(e.primeira):
			e.robo_alvo = 0.80
		elif Forja.robo_acerta():
			e.robo_alvo = float(e.estalo) - 0.02
		elif Forja.robo_acerta():
			e.robo_alvo = 0.75
		else:
			e.robo_alvo = float(e.estalo) + 0.03
	var agora := Ritmo.t_musica()
	var pega := Ritmo.t_da_batida(float(e.b))
	if str(e.estado) == "pegar":
		if agora >= pega + float(e.robo_mira):
			# os dois dedos encostam juntos, 0,10 um do outro
			Forja.robo_tocar(l, 0, 0.45, 0.5, 0.06)
			Forja.robo_tocar(l, 1, 0.55, 0.5, 0.06)
		return
	# segurando: afasta até o alvo em 3/4 da nota longa; na soltura (com a mira), não toca: os dois sobem
	var solta := Ritmo.t_da_batida(float(e.b) + float(e.len)) + float(e.robo_mira)
	if agora < solta:
		var u := clampf((agora - pega) / maxf(0.75 * (solta - pega), 0.01), 0.0, 1.0)
		var s := lerpf(0.05, float(e.robo_alvo) * 0.5, u)
		Forja.robo_tocar(l, 0, 0.5 - s, 0.5, 0.06)
		Forja.robo_tocar(l, 1, 0.5 + s, 0.5, 0.06)
```

O robô não usa o `rng` do minigame: o ponto de estalo de cada peça não depende de como o robô joga.

## A cena

- **A câmera:** a da seção, fixa, lente da arena (35 mm, 37,8°), plongée de 50°: `camera_pos = Vector3(0.2, 11.2,
  8.4)`, `camera_olhar = Vector3(0.2, 0.9, -0.3)`. Não corta. Na linha de montagem (o pico do kit), recua 10 % pelo
  `SECAO.pico`.
- **A luz:** a da seção (petróleo, `SECAO.montar`), com a chave a ×1,2 no pico. No estalo, as outras bancadas a 70 %
  por 1 batida (`SECAO.so_um`) e o tremor do estrondo (0,05 m por 2 batidas).
- **O fundo:** a oficina da K1 (`SECAO.montar`), mais, por lugar, a bancada sem molde (`SECAO.bancada(self, l,
  false)`).
- **As peças Kenney:**
  - `factory-kit/crane-magnet`, escala 2,0, em `(0; 4,8; −3,4)`: o ímã no alto, cenário (sem reserva: sem o pacote,
    não aparece);
  - `factory-kit/robot-arm-a`, escala 1,5, em `(cx + 1,1; 0; −1,0)`, girado −90°, atrás de cada bancada: gira 0,6 rad
    e volta em 1 batida a cada peça encaixada (reserva: `wood-support`);
  - `wood-structure`, escala 1,2, em `(cx; 0; −1,6)`: a estante de cada um.
- **O ferro:** `Kit.caixa(1,0 × 0,08 × 0,12)` na placa, a `y = 0,14`. Antes de pegar, curto (0,3 m) no meio da placa,
  visível desde 1 aviso (`SECAO.aviso_s(l)`) antes da nota. Segurando, esticado entre os dois dedos (o comprimento é
  a distância entre eles no mundo, a placa tem 2,4 m). A cor: `OXIDO_BRILHO` com emissão 0,8 (dono `"forja"`) até
  0,60; `TUNGSTENIO` com emissão 1,8 de 0,60 até o branco; `Kit.chapado(ETIQUETA)` a 0,04 do estalo.
- **A régua da soltura:** `Kit.caixa(2,4 × 0,02 × 0,05)` na borda da frente da placa (`z = 0,66`), no neon do
  jogador a 1,5; acende 1 aviso antes da batida de soltar.
- **A estante:** cada peça encaixada é uma `Kit.caixa(0,15 + 0,1 × valor; 0,06; 0,1)` (0,25, 0,35 ou 0,45 m) em
  `(cx − 0,6 + 0,4·(k % 4); 0,9 + 0,25·⌊k/4⌋; −1,6)`, em `OXIDO` (o ferro frio); na reta, na mostarda da seção
  (`nos.pronta`, `SECAO[3]`).
- **O estalo:** duas metades `Kit.caixa(0,45 × 0,08 × 0,12)` em `TUNGSTENIO` 1,8: a do lado do ferreiro vai ao rosto
  dele em 0,15 s e cai; as duas param no chão ao lado dele em 0,25 s, giradas ±1,2 rad, e ficam 4 s.
- **A falha:** uma `Kit.caixa(0,4 × 0,08 × 0,12)` em `OXIDO_BRILHO` despenca 0,6 m em 0,3 s; 24 faíscas
  `TUNGSTENIO`.
- **O ferreiro:** o cavaleiro em `(RAIAS[l] − 1,45; 0,05; 0,35)`, de perfil, de mãos livres.
- **O que brilha e de quem é:** o ferro e as metades, no tungstênio da forja; os dois dedos e a régua da soltura, no
  neon do jogador; as faíscas do encaixe (12, 18 ou 24, pelo valor), na cor do jogador.
- **Nenhuma cor fora do tema:** nenhuma cor escrita em hexadecimal no arquivo.

## O som

Os ids são os do [mapa do áudio](../o-time/o-mapa-do-audio.md).

| evento | na TV | no controle do dono |
| --- | --- | --- |
| pegar | a nota (o kit) | Ressonância: a nota (o kit); bom e ótimo: `Forja.som_falante(l, "clique", 0.4)` (`mod_clique`) |
| o ferro passa de 0,30 | `sopro` (`sint_sopro`), −10 dB, uma vez por peça | — |
| o ferro chega ao branco | — | `Som.no_controle(l, "tique", 0.5)` (`tique_0..2`), uma vez por peça |
| soltar e encaixar | a nota (o kit) e `martelo` (`martelo_0..4`), −6 dB, na estante | `Forja.som_falante(l, "coleta", 0.7)` (`mod_coleta`) |
| o estalo | `martelo`, +2 dB, tom 0,8 (grave), e `falha` (`falha_0..2`), −4 dB | `Som.no_controle(l, "martelo", 0.8)` |
| a peça cai | a nota quebrada (o kit) e `falha`, −6 dB | a nota quebrada (o kit) |

**A faixa:** `mus_s03_j14` (118 BPM, Si menor, a fazer). Até a H05, a sintetizada da seção a 100 bpm.

## O controle

| evento | vibração | háptica e alto-falante | luz | gatilho | para os outros |
| --- | --- | --- | --- | --- | --- |
| pegar | o kit, e `Forja.sentir(l, "toque")` (a pinça fecha no ferro) | o clique a 0,4, ou a nota no perfeito | o kit: branco no perfeito | R2 Off | nada |
| esticando até 0,30 | — | a textura `metal` nos atuadores, a cada quarto de tempo (`SECAO.textura(l, "metal")`) | — | — | nada |
| esticando de 0,30 em diante | o motor fraco a cada quarto de tempo, por 1/4 de tempo: `Forja.vibrar(l, 0.0, f, 15000 / bpm)`, `f` de 0,1 (a 0,30) a 0,45 (a 0,90) | — | — | — | nada |
| o branco | — | o tique a 0,5 no alto-falante | — | — | nada |
| encaixar | o kit | a coleta a 0,7 | o kit | — | nada |
| o estalo | `Forja.vibrar(l, 0.8, 0.0, 80)`: forte 0,8 por 80 ms | a martelada a 0,8 no alto-falante | o kit, no erro | — | as bancadas dos outros a 70 % por 1 batida |
| a peça cai | o kit: 0,7/0,3/160 ms | a nota quebrada | o kit | — | nada |

**Sem o controle na mão:** o robô pega e estica pelo `Forja.robo_tocar`; a prova lê as linhas `saida` de vibração
(F06) do estalo e da subida, e as `sensacao` do `toque` (F05). O `som_haptica` da textura devolve −1 quando o motor
do lugar está vibrando (F05): de 0,30 em diante a textura cala e a vibração fala, e isso é o certo.

**O que espera ela** (o ESPERA-ELA do quadro): no Linux, o touchpad também vira mouse; a regra udev
`LIBINPUT_IGNORE_DEVICE=1` pede o sudo dela. Esta ficha não depende da regra (o jogo lê os dois dedos pelo SDL), e
nada muda aqui quando ela entrar.

## O cavaleiro

O cavaleiro é o da montagem (G13), inteiro, de mãos livres. Pode ser de outra raça: esta ficha usa só o esqueleto
comum e as animações `interact-right` (pegar), `attack-melee-right` (encaixar), `emote-no` (a peça cai) e `fall` (o
estalo, sentado por 4 s).

| stat | gancho | o que muda na Pinça | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: ninguém é empurrado | — | — | — |
| Passo | `velocidade` | não age: o ferreiro não anda | — | — | — |
| Fôlego | `levantar` | a peça volta à pinça depois do estalo: a próxima procura a partir do fim da nota longa mais `SECAO.queda(l, 1)` tempos | 1,25 tempo | 1 tempo | 0,75 tempo |
| Faro | `pista` | o fim da nota longa avisa antes: a régua da soltura (e o ferro antes de pegar) acende 1 aviso (`SECAO.aviso_s(l)`) antes | −40 ms | 0 | +40 ms |

Os itens: o Martelo e o Escudo são do kit. O Escudo absorve o erro do estalo, mas o ferro estala do mesmo jeito
(vale zero, o ferreiro cai). A Âncora não age. A Lanterna entra pelo `SECAO.aviso_s`.

## As reações

- **Carimbos que a Pinça pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar), `car_virada` (do placar: quem passa a ser o líder), `car_por_um_fio` (no resultado) e `car_emburrado` (no
  inserto do resultado). O `car_acorde` não acontece: no hoqueto, ninguém pega no mesmo tempo 1.
- **Adesivos:** na seção 3, ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: o estalo** (`estalo`). O ferro passa do ponto, estala, as duas metades chicoteiam de volta, uma bate no
rosto do ferreiro e ele cai sentado. A sala gritava "solta!" um segundo antes. Degrau estrondo: tremor de 0,05 m por
2 batidas, 50 faíscas, parada de 3 quadros; as outras bancadas a 70 % por 1 batida.

- **O rastro:** o ferreiro sentado e as duas metades do ferro no chão, 4 s.
- **A curva:** de 0 a 27 s, uma peça por compasso, nota longa de 2 tempos (tempo de esticar devagar); de 27 a 53 s, a
  linha de montagem, duas por compasso, 1 tempo; de 53 s ao fim, uma por compasso e o estalo entre 0,68 e 0,85; nas
  últimas 16 batidas, cada peça vale o dobro.
- **Ensina sem falar:** a primeira peça de cada um estala em 0,72; todo mundo vê o estalo antes de 10 s. O ferro da
  TV estica do mesmo tanto que os dedos abrem, e muda de cor antes do ponto.
- **Quem está perdendo:** tem a razão para arriscar: 0,80 vale 3. O líder vê os outros arriscando e decide.
- **O que saiu:** a regra do "abaixo de 0,45 é erro mesmo no tempo"; agora vale 1 acima de 0,30.
- **A nota de hoje:** 2; com a troca, 4.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | pelo menos 1 linha `momento` `estalo` com `t_musica` ≤ 10,0 | um quadro antes de 10 s mostra um ferreiro sentado |
| 4. o momento | pelo menos 4 linhas `momento` `estalo` em 80 s; pelo menos 1 com `abertura` > 0,80 | 1 quadro em cada 4 mostra um ferreiro sentado |
| 5. a curva | notas por segundo de 27 a 53 s ≥ 1,8 × as de 0 a 27 s; a linha `momento` `reta` existe | o quadro de 40 s tem a câmera mais longe que o de 15 s |
| 6. a falha | o P4 tem pelo menos 6 linhas `toque` com `erro` | 1 quadro em 5 mostra faíscas de tungstênio na placa do P4 |
| 7. quem perde joga | a maior distância entre duas `nota` seguidas de cada lugar é de até 8 batidas | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `estalo` tem 0,1 ≤ `x_tela` ≤ 0,9 e `altura_tela` ≥ 0,05 | o ferreiro sentado e as metades se veem no quadro de 480 × 270 |
| 9. o impacto | para cada `estalo`, uma linha `saida` de vibração (0,8 forte) do mesmo lugar a até 16,7 ms | o quadro seguinte mostra as metades no ar |
| 10. o placar no mundo | a ordem do `vencedor()` bate com `ferro` no `momento` `reta` e no fim | a estante mais cheia é a do líder |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova roda com o `--robo` da
`prova_do_jogo.sh` (o `bom` nos quatro) e confere os itens 1, 4 (as 4 peças de treino, sem o "acima de 0,80"), 5 e 8;
os itens 6 e 7 esperam a mesa padrão; o 9 e o 10, a prancha.

## Pronto quando

A Pinça joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos. O cabo que cai e volta
não derruba peça com erro. Cada lugar vê a peça de treino estalar em 0,72, e o registro tem pelo menos 4 `estalo`. O
fim tem sempre vencedor. `SALA=S03_J14 bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, com a
prancha olhada. O catálogo e as traduções têm as linhas desta ficha, o `.uid` está no commit, e o commit, sem
trailer, é `feat(pinca): o puxa-ferro, o estalo escondido e o ferreiro que cai sentado`.

## Provas

Na sessão: `SALA=S03_J14 bash tests/prova_do_jogo.sh`, `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### `godot/testes/prova_do_jogo.gd`

No `match` de `_prova_da_ficha`: `"S03_J14": await _prova_da_pinca()`.

```gdscript
## A Pinça (S03_J14): os dois dedos de cada lugar pegam no tempo e encaixam; a
## peça de treino estala nos quatro antes de 10 s; a linha de montagem dobra as notas.
func _prova_da_pinca() -> void:
	var mg = await _joga_o_minigame("S03_J14", 120.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[2]) + int(c[3]) >= 1, "Pinça P%d: pegou no tempo %s" % [l + 1, c])
		_esperar(int(mg.j[l].pecas) >= 3, "Pinça P%d: encaixou %d peças" % [l + 1, int(mg.j[l].pecas)])
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S03_J14")
	var estalos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "estalo")
	_esperar(estalos.size() >= 4, "Pinça: %d estalos em 80 s (o mínimo é 4)" % estalos.size())
	var treino := estalos.filter(func(e): return bool(e.get("treino", false)))
	_esperar(treino.size() == 4, "Pinça: a peça de treino estalou nos quatro (%d)" % treino.size())
	var cedo := estalos.filter(func(e): return float(e.t_musica) <= 10.0)
	_esperar(cedo.size() >= 1, "Pinça: o primeiro estalo antes de 10 s (%d)" % cedo.size())
	for a in estalos:
		var x := float(a.get("x_tela", 0.0))
		_esperar(x >= 0.1 and x <= 0.9 and float(a.get("altura_tela", 0.0)) >= 0.05, "Pinça: o estalo na tela (%s)" % [a])
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "Pinça: a linha momento reta aparece uma vez")
	var notas := linhas.filter(func(e): return e.get("tipo") == "nota")
	var antes := notas.filter(func(e): return float(e.get("t_musica", 0.0)) < 27.0).size() / 27.0
	var linha := notas.filter(func(e): var t := float(e.get("t_musica", 0.0)); return t >= 27.0 and t < 53.0).size() / 26.0
	_esperar(linha >= 1.8 * antes, "Pinça: a linha de montagem (%.2f notas/s contra %.2f)" % [linha, antes])
```

A peça de treino estala nos quatro porque o robô mira 0,80 na primeira peça e o ponto dela é 0,72; se o robô errar o
pegar dela (200 ms atrasado), a peça de treino passa para a seguinte. Se a semente 7 der menos de 4, mostre o
registro e não mude a semente.

### O que o registro mede

- O kit: `nota` e `toque` para pegar e para soltar (o segurar e soltar no tempo).
- A linha `entrada` em cada soltura: **a abertura na soltura e a máxima**, o ponto de estalo, o valor, quanto tempo
  os dois dedos seguraram e **quantos dedos ficaram** no instante da soltura (1 = um dedo se perdeu antes: a perda
  de toque). Um touchpad que larga o segundo dedo no meio da nota longa aparece aqui, noite toda.
- A `momento` `estalo` (`abertura`, `ponto`, `treino`, `x_tela`, `altura_tela`) e a `reta` (`ordem`).

### As pranchas que o jogador do time olha

- antes de 10 s: os quatro ferreiros sentados, um depois do outro, com as metades no chão;
- de 27 a 53 s: duas peças por compasso, o ferro mudando de cor;
- um quadro com o ferro branco (a 0,04 do estalo);
- o fim: as estantes, com as peças longas (valor 3) e as mostarda da reta.

### O que o André joga e sente

`./run-local.sh -- --sala=S03_J14`: pegar com dois dedos na nota é natural; esticar com a vibração subindo dá
aflição; o tique do branco faz soltar na hora; o estalo faz rir; e a linha de montagem do meio aperta.

### Armadilhas

- **Soltar é o primeiro quadro sem os dois dedos**: perder um dedo no meio é soltar (cedo). O valor é a abertura do
  último quadro com os dois, nunca a do quadro da soltura.
- **O estalo é conferido antes da janela de soltar:** passar do ponto a qualquer momento da nota longa estala.
- **A soltura só existe depois de pegar:** a `nota` dela entra no registro no `toque` do pegar.
- **O `n` sobe uma vez por nota:** no `toque` do pegar e no `_fechar_peca` (encaixe, queda ou estalo).
- **O ferro esticado gira no plano da placa:** `rotation.y` local da placa (inclinada), e o comprimento é a
  distância entre os dois dedos no mundo.
- **Os materiais do ferro** se criam uma vez no `montar` e só se trocam no `_mostrar`.
