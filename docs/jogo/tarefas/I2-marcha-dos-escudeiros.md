# I2 — Marcha dos Escudeiros

**Sprint:** I · **Slot:** S01_J02 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, F09, F03, H07, I1 (o `secao.gd`), e o sorteio dentro da seção ([o índice](I-a-centelha.md#antes-de-começar-o-que-ainda-falta-na-base))

## Por quê

Marchar é empurrar os dois analógicos para a frente, um de cada vez, no
bumbo: o passo só sai com o analógico até o fim do curso e no tempo — e por
baixo cada passo diz quanto curso cada analógico entrega.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md) (o minigame de prova é o exemplo pequeno)
- [A linha n.º 2 em 03](../03-os-45-minigames.md#s1--a-centelha--botões-analógicos-gatilhos-analógicos)
- [O índice da seção](I-a-centelha.md) e a [I1](I1-o-martelo-de-hefesto.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J02",
	"titulo": "Marcha dos Escudeiros",
	"verbo": "Marche!",
	"genero": "corrida",
	"icone": "stick_l",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S01_J02",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Marche!", "segundos": 6.0},
	"gesto": "lados",
}
```

## Como se joga

- **A faixa:** `MUS_S01_J02` — até a H05, a trilha sintetizada da seção a
  108 bpm; com a faixa gerada, 110 bpm ("bateria muito clara"). Um tempo
  ≈ 0,55 s.
- **A marcha, sem hoqueto:** é a exceção da seção — os quatro pisam juntos
  no bumbo, cada um com a sua nota (o kit toca a nota do lugar a cada
  passo), e o passo dos quatro soa como um acorde.
- **As notas:** o passo `k` do lugar cai na batida `4 + k` (um por tempo).
  Passo par: **analógico esquerdo** para a frente; passo ímpar: **direito**.
  `Ritmo.simples[l]`: um passo a cada 2 tempos (`4 + 2k`), alternando igual.
- **O passo:** o analógico pedido cruza −0,8 no eixo Y (para a frente) vindo
  de acima de −0,5 — o instante do cruzamento é o toque (`julgar_toque`). O
  outro analógico cruzar −0,8 a menos de `JANELA_BOM` da nota é **trocar o
  pé**: erro. A nota passou sem passo (`JANELA_BOM + 0,05 s`): nota perdida.
- **O avanço** (metros, na distância `d` do lugar): PERFEITO +0,55, ÓTIMO
  +0,45, BOM +0,25. A esteira puxa para trás a cada tempo inteiro que passa:
  −0,10 m (−0,25 m no pico). O erro: −1,5 m, e o passo seguinte não conta
  (ele está no chão). A meta: 48 m.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o primeiro a chegar +300, o segundo +200, o terceiro +100.
- **A progressão:** `p = t_jogo / duracao`. De 0 a 1/3, a esteira normal.
  **O pico (1/3 a 2/3), a ladeira:** a esteira puxa 2,5 vezes mais, as
  engrenagens do chão giram e soltam faísca. De 2/3 em diante, normal.
  Quem acerta tudo chega perto do tempo 120 (~67 s a 108 bpm); quem erra um
  terço não chega e o mais longe decide.
- **A reta final:** o primeiro que passa da meta abre 16 tempos para os
  outros; acabados os 16, todos acabam (o fim da F03). Sem ninguém na meta,
  o fim é o dos 90 s.

## O cenário

`SECAO.montar(self)` (a forja da I1) e, por lugar, a esteira na raia:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a raia | `raia(l)` do kit (a laje, a borda na cor, a luz da vez) | `(RAIAS[l], 0, Z_JOGADOR)` |
| a esteira | `Kit.caixa(self, Vector3(1.6, 0.12, 11.0), ..., Kit.material(Color("#2a2233"), 0.0, 0.9))` | centro `(RAIAS[l], 0.06, −0.5)` |
| as polias | duas `Kit.caixa` de `Vector3(1.8, 0.3, 0.3)`, `Color("#4a4e5e")` | `z = 5.0` e `z = −6.0`, `y = 0.15` |
| as engrenagens | 10 `Kit.caixa` de `Vector3(1.4, 0.05, 0.14)`, `Color("#5b6275")`, que andam com a esteira | sobre a esteira, `y = 0.14` |
| a chegada | `gate` (escala 2) e dois `banner` | `(RAIAS[l], 0, −6.4)`; `banner` em `x ± 1.1` |
| o escudeiro | o boneco, de costas (`rotation.y = PI`), mãos livres | `z = lerp(4.5, −5.8, d / META)`, `y = 0.12` |

A raia do kit fica em `Z_JOGADOR` (1,4): a esteira passa por cima dela.
Câmera: `camera_pos = Vector3(0, 8.5, 11.5)`, `camera_olhar = Vector3(0, 0.5, -1.5)`.
As engrenagens andam pela batida: `z = 5.0 − fposmod(Ritmo.batida() * puxa + 1.1 * i, 11.0)`
(`puxa` 0,10 ou 0,25). Na ladeira, cada uma gira em `rotation.x` pela
batida. Nada liso: tudo caixa. A cor do lugar só na borda da raia do kit.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **analógicos (a feature)** | o passo é o analógico até o fim, alternado, no bumbo |
| vibração | o kit no acerto e no erro; o tropeço: `Forja.sentir(l, "golpe")`; cruzar a meta: `Forja.sentir(l, "explosao")` |
| barra de luz | `SECAO.piscar` no `toque` e na `falha` |
| alto-falante do dono | perfeito: a nota do lugar (o kit); ótimo e bom: `Forja.som_falante(l, "passo:metal:%d" % (k % 3), 0.5)`; erro: a nota quebrada (o kit); cruzar a meta: `Forja.som_falante(l, "coleta", 0.8)` |
| gatilho | livre: não há o que segurar (o R2 fica Off) |
| háptica por material | `metal`, pelo kit |
| som na TV | a nota do lugar a cada passo (o kit), `falha` no tropeço (o kit), `portao` ao cruzar a meta, `sucesso` no fim da reta final |

## A falha

Ele tropeça nas engrenagens e cai para trás: `p.gesto("fall", 0.6)`, uma
engrenagem salta do chão (duas `Kit.caixa` cruzadas de 0,4 m, `#5b6275`,
voando 1 m para cima e sumindo em 0,5 s), faíscas `Tema.LARANJA` nos pés,
−1,5 m, e o passo seguinte não conta (nem erro, nem acerto). Recupera no
passo depois.

## O fim e o vencedor

Quem passa da meta acaba (`acabou[l] = true`), faz `emote-yes` e entra na
lista `chegada`. `vencedor()`: primeiro os da `chegada`, na ordem; depois os
outros pela distância; empate pela ordem do lugar.

## Com menos de quatro

Nada muda na regra. Com um só, é contra a esteira: chegar é vencer; não
chegar, também fecha com ele em primeiro (o único). **O controle que cai:**
o escudeiro fica parado (a esteira não o puxa enquanto ele está sem
controle), e ao voltar o próximo passo é a próxima batida que ainda não
passou.

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
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado (erro)
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	var alvo := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
	var agora := Ritmo.t_musica()
	# empurra por 0,12 s de música a partir da mira, e solta (o eixo volta sozinho a zero)
	if agora >= alvo - 0.02 and agora < alvo + 0.12:
		Forja.robo_eixo(l, Forja.LY if int(e.k) % 2 == 0 else Forja.RY, -1.0, 0.06)
```

## Os ganchos

`godot/scripts/minigames/s01/marcha_dos_escudeiros.gd`:

```gdscript
extends Minigame
## Marcha dos Escudeiros (S01_J02). Cada escudeiro marcha numa esteira que
## puxa para trás; o passo é empurrar o analógico para a frente, o esquerdo e
## o direito alternados, no bumbo. Passo no tempo avança; a meta é a 48 m.
## No meio, a ladeira: a esteira puxa mais.
##
## A falha: tropeça nas engrenagens, cai para trás (−1,5 m) e perde o passo seguinte.
## O vencedor: quem passa da meta primeiro; senão, o mais longe.
## O alto-falante do dono: o passo no metal, a nota no perfeito, a coleta na meta.
## O registro mede: cada analógico pedido, o instante e o curso do passo (a
## linha `entrada`), e cada nota e toque (o kit).
## O robô: empurra o analógico da vez na nota; quando não acerta, 200 ms atrasado.
## Com menos de quatro: nada muda.
## A régua: "Marche!" e o glifo do analógico bastam; sem a tela, o bumbo e a
## nota de cada passo dizem o tempo; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const BATIDA_DA_PRIMEIRA_NOTA := 4.0
const META := 48.0
const AVANCO := [0.0, 0.25, 0.45, 0.55]  ## ERRO, BOM, OTIMO, PERFEITO
const PONTOS := [0, 20, 35, 50]
const DA_CHEGADA := [300, 200, 100, 0]
const PUXA := 0.10
const PUXA_LADEIRA := 0.25
const TROPECO := 1.5
const FRENTE := -0.8  ## o analógico para a frente (Y negativo)
const SOLTO := -0.5
const RETA_FINAL := 16.0
const Z_LARGADA := 4.5
const Z_CHEGADA := -5.8
const FOLGA_PERDIDA := 0.05

var j := {}  ## lugar -> o estado
var n_nos := {}  ## lugar -> os nós (engrenagens)
var chegada: Array = []  ## os lugares na ordem em que passaram da meta
var _fim_da_reta := -1.0  ## a batida em que a reta final acaba (-1: ninguém chegou)
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 8.5, 11.5)
	camera_olhar = Vector3(0, 0.5, -1.5)
	SECAO.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var x: float = RAIAS[l]
		Kit.caixa(self, Vector3(1.6, 0.12, 11.0), Vector3(x, 0.06, -0.5), Kit.material(Color("#2a2233"), 0.0, 0.9))
		var ferro := Kit.material(Color("#4a4e5e"), 0.0, 0.7)
		for z in [5.0, -6.0]:
			Kit.caixa(self, Vector3(1.8, 0.3, 0.3), Vector3(x, 0.15, z), ferro)
		Kit.peca(self, "gate", Vector3(x, 0, -6.4))
		for lado in [-1.1, 1.1]:
			Kit.peca(self, "banner", Vector3(x + lado, 0, -6.2))
		var dentes: Array = []
		for i in 10:
			dentes.append(Kit.caixa(self, Vector3(1.4, 0.05, 0.14), Vector3(x, 0.14, 0), Kit.material(Color("#5b6275"), 0.0, 0.7)))
		n_nos[l] = dentes
		maos_livres(p)
		p.preso = true
		p.position = Vector3(x, 0.12, Z_LARGADA)
		p.rotation.y = PI
		j[l] = {"d": 0.0, "k": 0, "n": 0, "b": -1.0, "caido_ate": -1.0, "batida_puxada": -1,
			"antes_l": 0.0, "antes_r": 0.0, "curso": 0.0, "fora": false, "robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A próxima batida de passo do lugar que ainda não passou.
func _passo_da_vez(l: int) -> float:
	var passo := 2.0 if Ritmo.simples[l] else 1.0
	return BATIDA_DA_PRIMEIRA_NOTA + ceilf(maxf(Ritmo.batida() - BATIDA_DA_PRIMEIRA_NOTA, 0.0) / passo) * passo


func _marcar_nota(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	e.b = b
	e.curso = 0.0
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))


func _no_pico() -> bool:
	var p := t_jogo / maxf(duracao, 1.0)
	return p >= 1.0 / 3.0 and p < 2.0 / 3.0


func iniciar_jogo() -> void:
	for l in presentes():
		j[l].batida_puxada = int(BATIDA_DA_PRIMEIRA_NOTA)
		_marcar_nota(l, BATIDA_DA_PRIMEIRA_NOTA)


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
			e.batida_puxada = int(floor(Ritmo.batida()))
			_marcar_nota(l, _passo_da_vez(l))
		# a esteira puxa a cada tempo inteiro que passa
		while int(e.batida_puxada) < int(floor(Ritmo.batida())):
			e.batida_puxada = int(e.batida_puxada) + 1
			if not treinando:
				e.d = maxf(0.0, float(e.d) - (PUXA_LADEIRA if _no_pico() else PUXA))
		_passo(l, e)
	if _fim_da_reta >= 0.0 and Ritmo.batida() >= _fim_da_reta:
		for l in presentes():
			acabou[l] = true


func _passo(l: int, e: Dictionary) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var agora := Ritmo.t_musica()
	var esquerdo := int(e.k) % 2 == 0
	var y_pedido := Forja.eixo(l, Forja.LY if esquerdo else Forja.RY)
	var y_outro := Forja.eixo(l, Forja.RY if esquerdo else Forja.LY)
	var antes_pedido := float(e.antes_l if esquerdo else e.antes_r)
	var antes_outro := float(e.antes_r if esquerdo else e.antes_l)
	e.antes_l = Forja.eixo(l, Forja.LY)
	e.antes_r = Forja.eixo(l, Forja.RY)
	e.curso = maxf(float(e.curso), -y_pedido)
	if Ritmo.batida() < float(e.caido_ate):
		# no chão: o passo desta nota não conta
		if agora > alvo + Ritmo.JANELA_BOM + FOLGA_PERDIDA:
			_seguinte(l)
		return
	var perto := absf(agora - alvo) <= Ritmo.JANELA_BOM
	if perto and antes_outro > SOLTO and y_outro <= FRENTE:
		Forja.evento("entrada", l + 1, {"o": "analogico", "lado": "direito" if esquerdo else "esquerdo",
			"trocou_o_pe": true, "n": int(e.n)})
		nota_perdida(l, int(e.n))
		return
	if antes_pedido > SOLTO and y_pedido <= FRENTE and agora >= alvo - 0.5 * 60.0 / Ritmo.bpm:
		Forja.evento("entrada", l + 1, {"o": "analogico", "lado": "esquerdo" if esquerdo else "direito",
			"curso": snappedf(float(e.curso), 0.01), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + Ritmo.JANELA_BOM + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func _seguinte(l: int) -> void:
	var e: Dictionary = j[l]
	e.n = int(e.n) + 1
	e.k = int(e.k) + 1
	var passo := 2.0 if Ritmo.simples[l] else 1.0
	_marcar_nota(l, float(e.b) + passo)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if not treinando:
		e.d = float(e.d) + AVANCO[julgamento]
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "passo:metal:%d" % (int(e.k) % 3), 0.5)
	SECAO.piscar(self, l, julgamento)
	if float(e.d) >= META and not (l in chegada):
		_chegou(l)
		return
	_seguinte(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	if not treinando:
		e.d = maxf(0.0, float(e.d) - TROPECO)
	e.caido_ate = float(e.b) + 1.5
	var p := jogador(l)
	if p:
		p.gesto("fall", 0.6)
		Efeitos.faiscas(self, p.global_position + Vector3(0, 0.2, 0), Tema.LARANJA, 18, 0.8)
		_engrenagem_salta(p.global_position)
	Forja.sentir(l, "golpe")
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
		Som.tocar("portao", p.global_position + Vector3(0, 1.5, 0))
		Efeitos.faiscas(self, p.global_position + Vector3(0, 2.0, 0), Forja.cor_do_lugar(l), 40, 1.3)
	if _fim_da_reta < 0.0:
		_fim_da_reta = Ritmo.batida() + RETA_FINAL


## Uma engrenagem (duas caixas cruzadas) salta do chão e some.
func _engrenagem_salta(pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos + Vector3(0, 0.2, -0.3)
	add_child(g)
	var mat := Kit.material(Color("#5b6275"), 0.0, 0.7)
	Kit.caixa(g, Vector3(0.4, 0.1, 0.1), Vector3.ZERO, mat)
	var b := Kit.caixa(g, Vector3(0.4, 0.1, 0.1), Vector3.ZERO, mat)
	b.rotation.z = PI * 0.5
	var tw := g.create_tween().set_parallel(true)
	tw.tween_property(g, "position:y", g.position.y + 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "rotation:z", TAU, 0.5)
	tw.chain().tween_callback(g.queue_free)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var p := jogador(l)
	if p == null:
		return
	var alvo_z := lerpf(Z_LARGADA, Z_CHEGADA, clampf(float(e.d) / META, 0.0, 1.0))
	p.position = Vector3(RAIAS[l], 0.12, lerpf(p.position.z, alvo_z, 0.2))
	if fase == "jogo" and not acabou[l] and conectado(l):
		p.animar("walk", 1.0)
	else:
		p.animar("idle")
	var puxa := PUXA_LADEIRA if _no_pico() else PUXA
	var dentes: Array = n_nos[l]
	for i in dentes.size():
		var d: MeshInstance3D = dentes[i]
		d.position.z = 5.0 - fposmod(Ritmo.batida() * puxa * 4.0 + 1.1 * i, 11.0)
		d.rotation.x = fmod(Ritmo.batida(), 1.0) * TAU if _no_pico() else 0.0


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
	if not is_equal_approx(float(j[a].d), float(j[b].d)):
		return float(j[a].d) > float(j[b].d)
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "%d m" % int(j[lugar].d)
	return super(lugar)
```

(As engrenagens andam `puxa × 4` por batida só para se verem andando; a
distância de verdade é `d`.)

## O que o registro mede

- O kit: `nota` por passo pedido e `toque` por passo dado (o desvio), com
  o `n`; passo par é o esquerdo, ímpar o direito.
- A linha `entrada` em todo passo: o lado, o **curso** (o máximo que o
  analógico chegou para a frente, 0 a 1) e o `n`; e `trocou_o_pe` quando o
  outro analógico cruzou. Cruzado depois da noite: um analógico que nunca
  passa de 0,9 de curso, ou que chega sempre atrasado, aparece aqui.

## Armadilhas

- **A esteira puxa por batida inteira**, contando de onde o lugar estava
  (`batida_puxada`): nunca `dt`. No treino não puxa (nem avança).
- **Cruzamento, não posição:** o passo é o analógico **atravessar** −0,8
  vindo de cima de −0,5; segurar para a frente não dá passo de novo.
- **Antes da janela:** cruzar mais de meio tempo antes da nota não conta
  (nem erro): é o analógico voltando.
- **`julgar_toque` chama `toque`/`falha` na hora**, e eles marcam a próxima
  nota: depois dele, `return`.
- **O fim é da `SalaJogo`** (90 s ou todos acabaram); a reta final só põe
  `acabou` em todos.
- **Quem chegou** não recebe mais nota: `acabou[l]` para o `jogar`.

## Pronto quando

A marcha joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta não derruba ninguém; a reta final
fecha a corrida; o fim tem sempre vencedor; `bash tests/prova_do_jogo.sh`
passa; e `bash tests/prova_visual.sh` passa com a prancha **olhada** nas
partidas em que a Marcha aparece (com quatro, dois, um e o cabo que cai).

## Provas

Em `godot/testes/prova_do_jogo.gd`, chamada no `_prova_do_percurso()` logo
depois de `await _prova_do_kit()`:

```gdscript
## S01_J02 (I2): a Marcha abre pelo catálogo, o robô marcha pelo analógico
## simulado, cada lugar tem passo julgado e a corrida fecha com vencedor.
func _prova_da_marcha() -> void:
	jogo._entrar_na_sala("S01_J02", false)
	await _quadros(2)
	var mg = jogo.sala
	_esperar(mg is Minigame and mg.id == "S01_J02", "S01_J02: abriu pelo catálogo")
	if not mg is Minigame:
		return
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 40000000:
		await _quadros(1)
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "S01_J02: a marcha fechou (%.1f s)" % ((Time.get_ticks_usec() - inicio) / 1e6))
	if not is_instance_valid(mg):
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "S01_J02 P%d: passos julgados %s" % [l + 1, c])
	_esperar(mg.vencedor().size() == 4, "S01_J02: a colocação tem os quatro")
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J02: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S01_J02` com quatro
controles: o passo sai no bumbo, alternar os polegares é natural, o tropeço
faz rir, a ladeira pesa no meio, e o passo no metal soa em cada controle.

## Ao terminar

- `godot/scripts/minigames/catalogo.gd`: `"S01_J02": preload("res://scripts/minigames/s01/marcha_dos_escudeiros.gd")`
  em `MINIGAMES` e `"S01_J02"` na lista `minigames` da S01, depois do `"S01_J01"`.
- `godot/scripts/traducoes.gd`: `"Marcha dos Escudeiros": "March of the Squires"`,
  `"Marche!": "March!"` em `EN`; `["^(\\d+) m$", "$1 m"]` em `EN_PADROES`.
- `"$GODOT" --headless --path godot --import --quit`; o `.uid` no commit.
- No [quadro](README.md), a linha I2 **feito**, com o commit e o gasto real
  (se as linhas dos minigames ainda não existem, a I1 diz como pôr).
- Commit (sem trailer): `feat: a Marcha dos Escudeiros — os analógicos alternados no bumbo`
