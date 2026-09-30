# K2 — Quebra-Gelo

**Sprint:** K · **Slot:** S03_J12 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, F03, H07, K1 (o `secao.gd`)

## Por quê

Rachar é riscar o touchpad de um lado ao outro num golpe só, no
contratempo: não é onde o dedo está, é quanto ele anda e para que lado —
o deslocamento do dedo e a taxa de amostras do touchpad, julgados no "e"
do tempo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 12 em 03](../03-os-45-minigames.md#s3--o-molde--touchpad)
- [O índice da seção](K-o-molde.md) e a [K1](K1-o-molde.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S03_J12",
	"titulo": "Quebra-Gelo",
	"verbo": "Rache!",
	"genero": "tct",
	"icone": "touchpad",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S03_J12",
	"duracao": 75.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "gelo",
	"microjogo": {"verbo": "Rache!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S03_J12` — até a H05, a sintetizada da seção a 100 bpm;
  com a gerada, 130 bpm ("vidro no contratempo").
- **O bloco:** um bloco de gelo em cima da placa de cada um (a placa é o
  touchpad). **O risco:** o dedo encosta e anda **0,35 da largura** do
  touchpad para o lado pedido sem levantar — o instante em que ele completa
  os 0,35 é o toque. O lado se alterna a cada nota (→, ←), e uma setinha de
  gelo em cima do bloco mostra qual. Para o próximo risco, o dedo levanta.
- **O hoqueto no contratempo:** a nota do lugar `l` cai no "e" depois do
  tempo dele: `4c + l + 0,5` (P1 no "e" do 1, P2 no "e" do 2…), uma por
  compasso. `Ritmo.simples[l]`: uma a cada 2 compassos.
- **O julgamento, no cruzamento** (as convenções da seção). Nada até
  `FOLGA_PERDIDA`, o do kit depois → nota perdida.
- **O bloco racha:** cada acerto é uma rachadura (o PERFEITO, duas); com
  **3 rachaduras** o bloco quebra, e um novo sobe da bancada.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o bloco quebrado +60.
- **A progressão:** `progresso()` do kit (em tempo de música, H08). De 0 a 1/3, uma por compasso.
  **O pico (1/3 a 2/3), a rajada:** duas por compasso, em `4c + 0,5 + (l % 2)`
  e mais 2 tempos (P1 e P3 juntos no "e" do 1 e do 3, P2 e P4 no "e" do 2 e do
  4). De 2/3 em diante, uma por compasso. Riscos de cada um em 75 s: ~40 a
  100 bpm, ~50 a 130 bpm.

## O cenário

`SECAO.montar(self)` (a oficina) e, por lugar, `SECAO.bancada(self, l, false)`
(a bancada com a moldura, sem o molde):

| o quê | peça | onde (m) |
| --- | --- | --- |
| o bloco | `Kit.caixa(2.2, 0.5, 1.0)` na placa, `Kit.material(Color("#bfe6ff"), 0.0, 0.9)` | placa + `(0, 0.33, 0)` |
| as rachaduras | três `Kit.caixa(0.03, 0.02, 0.8)`, `Kit.chapado(Color("#4a6a86"))`, em ângulos sorteados, uma aparece por racha | na face de cima do bloco, `y = 0.59` |
| a seta do lado | `Kit.caixa(0.5, 0.03, 0.08)` e a ponta (duas `Kit.caixa(0.2, 0.03, 0.06)` a ±45°), `Kit.chapado(Color("#8fb8d8"))`, virada para o lado pedido | placa + `(0, 0.62, 0)` |
| a casca de gelo | `Kit.caixa(1.0, 1.9, 1.0)`, `#bfe6ff` com alfa 0,55 (`transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`), visível no congelamento | em volta do boneco |
| o quebrador | o boneco, de perfil, `martelo_na_mao` | `(RAIAS[l] − 1.45, 0.05, 0.35)` |

Câmera: `camera_pos = Vector3(0, 8.6, 12.7)`, `camera_olhar = Vector3(0, 0.8, -0.1)`
(as d'O Molde). O gelo é fosco; a casca é translúcida (é gelo), sem brilho.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **touchpad (a feature)** | o risco: o dedo anda, para o lado pedido, no contratempo |
| vibração | o kit por nota (no cabo, a textura `gelo`: fina, de um atuador) |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "material:gelo", 0.5)`; o bloco quebra: `Forja.som_falante(l, "coleta", 0.8)`; erro: a nota quebrada (o kit) |
| háptica por material | a textura `gelo` sob o dedo enquanto ele encosta (`SECAO.textura(l, "gelo")`) |
| gatilho | livre (o R2 Off) |
| som na TV | a nota (o kit); `tique` agudo (tom 1,6) na rachadura; `pedra` no bloco quebrado |

## A falha

A lâmina escorrega e o bloco congela o boneco: a casca de gelo aparece em
volta dele por **4 tempos** (um compasso), ele faz `emote-no` antes de
congelar, e as notas dele nesse tempo não existem (nem erro, nem acerto).
Ao sair, faíscas `Color("#bfe6ff")` e a casca some.

## O fim e o vencedor

75 s (a F03). `vencedor()`: mais blocos quebrados; empate pelos pontos,
depois pelo lugar.

## Com menos de quatro

Nada muda. **O controle que cai:** as notas dele param (sem erro); ao
voltar, a próxima é o próximo contratempo dele que ainda não passou.

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
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	var quando := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
	var agora := Ritmo.t_musica()
	if agora >= quando - 0.1 and agora <= quando + 0.1:
		# encosta 100 ms antes e risca 0,6 da largura em 150 ms: os 0,35 caem na nota
		var u := clampf((agora - (quando - 0.1)) / 0.15, 0.0, 1.0)
		Forja.robo_tocar(l, 0, 0.5 + float(e.dir) * lerpf(-0.3, 0.3, u), 0.5, 0.06)
```

## Os ganchos

`godot/scripts/minigames/s03/quebra_gelo.gd`:

```gdscript
extends Minigame
## Quebra-Gelo (S03_J12). Um bloco de gelo em cima da placa de cada um (a
## placa é o touchpad). O risco: o dedo encosta e anda 0,35 da largura para o
## lado pedido, no contratempo do lugar (o "e" depois do tempo dele); o lado
## se alterna. Três rachaduras quebram o bloco. No meio, a rajada: duas por compasso.
##
## A falha: a lâmina escorrega e o bloco congela o boneco por um compasso.
## O vencedor: mais blocos quebrados.
## O alto-falante do dono: o gelo no acerto, a nota no perfeito, a coleta no bloco.
## O registro mede: quanto o dedo andou, de onde a onde, e em quanto tempo
## (a linha `entrada`), e o tempo (o kit).
## O robô: risca 0,6 da largura em 150 ms, na nota (ou 200 ms atrasado).
## Com menos de quatro: nada muda.
## A régua: "Rache!" e o touchpad bastam; sem a tela, o lado alternado e a
## nota no contratempo dão para jogar; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

# (a FICHA vem aqui)

const RISCO := 0.35
const RACHAS := 3
const CONGELA := 4.0  ## tempos
const PONTOS := [0, 20, 35, 50]
const QUEBRA := 60

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 8.6, 12.7)
	camera_olhar = Vector3(0, 0.8, -0.1)
	SECAO.montar(self)
	var gelo := Kit.material(Color("#bfe6ff"), 0.0, 0.9)
	var risco := Kit.chapado(Color("#4a6a86"))
	var seta_mat := Kit.chapado(Color("#8fb8d8"))
	var casca_mat := Kit.material(Color(0.75, 0.9, 1.0, 0.55), 0.0, 0.9)
	casca_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l, false)
		var placa: Node3D = nos.placa
		var bloco := Kit.caixa(placa, Vector3(2.2, 0.5, 1.0), Vector3(0, 0.33, 0), gelo)
		var rachaduras: Array = []
		for k in RACHAS:
			var r := Kit.caixa(placa, Vector3(0.03, 0.02, 0.8), Vector3(-0.6 + 0.6 * k, 0.59, 0), risco)
			r.rotation.y = rng.randf_range(-0.8, 0.8)
			r.visible = false
			rachaduras.append(r)
		var seta := Node3D.new()
		seta.position = Vector3(0, 0.62, 0)
		placa.add_child(seta)
		Kit.caixa(seta, Vector3(0.5, 0.03, 0.08), Vector3.ZERO, seta_mat)
		for lado in [-1.0, 1.0]:
			var ponta := Kit.caixa(seta, Vector3(0.2, 0.03, 0.06), Vector3(0.2, 0, lado * 0.06), seta_mat)
			ponta.rotation.y = lado * PI * 0.25
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		martelo_na_mao(p)
		var casca := Kit.caixa(self, Vector3(1.0, 1.9, 1.0), p.position + Vector3(0, 0.95, 0), casca_mat)
		casca.visible = false
		nos["bloco"] = bloco
		nos["rachaduras"] = rachaduras
		nos["seta"] = seta
		nos["casca"] = casca
		j[l] = {"n": 0, "b": -1.0, "dir": -1, "x0": -1.0, "t0": 0.0, "antes": false, "aberta": false, "rachas": 0,
			"quebrados": 0, "gelo_b": -99.0, "fora": false, "nos": nos, "robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A próxima nota do lugar depois de `desde`: o contratempo dele, pulando o congelamento.
func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var passo := 4.0
	var desloc := l + 0.5
	if Ritmo.simples[l]:
		passo = 8.0
	elif no_pico():
		passo = 2.0
		desloc = (l % 2) + 0.5
	var inicio := maxf(desde, float(e.gelo_b) + CONGELA)
	e.b = proxima_batida(l, inicio + 0.001, passo, desloc)  # o kit; estritamente depois de inicio
	e.dir = -int(e.dir)
	e.aberta = false
	e.antes = false
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b)))


func iniciar_jogo() -> void:
	for l in presentes():
		if not Forja.capacidade(l, "toque"):
			Forja.evento("troca", l + 1, {"slot": id, "de": "touchpad", "para": "sem_touchpad"})
			acabou[l] = true
			continue
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


func jogar(_dt: float) -> void:
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
			_proxima(l, Ritmo.batida())
		_nota(l, e, agora)


## O risco: o dedo encostado andou RISCO da largura para o lado pedido desde que encostou.
func _riscou(l: int, e: Dictionary) -> bool:
	var d := Forja.dedo(l, 0)
	if d.z <= 0.5:
		e.x0 = -1.0
		return false
	SECAO.textura(l, "gelo")
	if float(e.x0) < 0.0:
		e.x0 = d.x
		e.t0 = Ritmo.t_musica()
		return false
	return (d.x - float(e.x0)) * float(e.dir) >= RISCO


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var sim := _riscou(l, e)
	if agora < alvo - 0.5 * 60.0 / Ritmo.bpm:
		e.antes = sim
		return
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		var d := Forja.dedo(l, 0)
		Forja.evento("entrada", l + 1, {"o": "touchpad", "de_x": snappedf(float(e.x0), 0.01), "ate_x": snappedf(d.x, 0.01),
			"ms": int((agora - float(e.t0)) * 1000.0), "lado": int(e.dir), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	marcar(l, PONTOS[julgamento])
	var bloco: Node3D = nos.bloco
	Som.tocar("tique", bloco.global_position, -4.0, 1.6)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "material:gelo", 0.5)
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.35)
	if not treinando:
		e.rachas = int(e.rachas) + (2 if julgamento == Ritmo.PERFEITO else 1)
		if int(e.rachas) >= RACHAS:
			_quebrar(l)
	_proxima(l, float(e.b))


func _quebrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var bloco: Node3D = nos.bloco
	e.rachas = 0
	e.quebrados = int(e.quebrados) + 1
	marcar(l, QUEBRA)
	Forja.som_falante(l, "coleta", 0.8)
	Som.tocar("pedra", bloco.global_position, 0.0)
	Efeitos.faiscas(self, bloco.global_position, Color("#bfe6ff"), 40, 1.2)
	bloco.scale = Vector3.ONE * 0.1
	var tw := bloco.create_tween()
	tw.tween_property(bloco, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	if not treinando:
		e.gelo_b = Ritmo.batida()
	_proxima(l, float(e.b))


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	for k in RACHAS:
		(nos.rachaduras[k] as Node3D).visible = k < int(e.rachas)
	var seta: Node3D = nos.seta
	seta.visible = fase == "jogo" and not acabou[l] and float(e.b) >= 0.0
	seta.rotation.y = 0.0 if int(e.dir) > 0 else PI
	var congelado := Ritmo.batida() - float(e.gelo_b) < CONGELA and fase == "jogo"
	var casca: Node3D = nos.casca
	if casca.visible and not congelado:
		Efeitos.faiscas(self, casca.global_position, Color("#bfe6ff"), 20, 0.8)
	casca.visible = congelado


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].quebrados) != int(j[b].quebrados):
		return int(j[a].quebrados) > int(j[b].quebrados)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Blocos: %d" % int(j[lugar].quebrados)
	return super(lugar)
```

## O que o registro mede

- O kit: `nota` e `toque` (o risco completo contra o contratempo).
- A linha `entrada` em cada risco: de onde a onde o dedo andou (`de_x`,
  `ate_x`) e em quantos ms. Cruzado: um touchpad que perde amostras (o risco
  pula de uma ponta à outra em 0 ms) ou que corta uma borda (o `ate_x` nunca
  passa de 0,8) aparece aqui.

## Armadilhas

- **O risco começa no encostar:** `x0` é onde o dedo encostou; levantar zera.
  Riscar de volta sem levantar não conta como o lado novo (o `x0` é o velho) —
  o jogador aprende a levantar entre os riscos.
- **O congelamento pula notas** (o `_proxima` começa depois dele): elas nem
  entram no registro.
- **A seta de gelo** gira em `y` local da placa (inclinada): `rotation.y`
  do nó dentro da placa, nunca global.
- **A casca translúcida** tem `transparency`; o resto é opaco e fosco.

## Pronto quando

O Quebra-Gelo joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o
robô nos três temperamentos; o cabo que cai e volta não congela ninguém; o
fim tem sempre vencedor; `bash tests/prova_do_jogo.sh` passa; e
`bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S03_J12 (K2): o Quebra-Gelo abre pelo catálogo; o risco simulado de cada
## lugar chega julgado; o fim tem vencedor.
func _prova_do_quebra_gelo() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (75 s de música e o treino)
	var mg = await _joga_o_minigame("S03_J12", 115.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[2]) + int(c[3]) >= 1, "S03_J12 P%d: riscou no contratempo %s" % [l + 1, c])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S03_J12: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S03_J12`: o risco no "e" se
sente como vidro, alternar o lado é natural, o congelamento faz rir, e a
rajada do meio pega todo mundo.

## Ao terminar

- Catálogo: `"S03_J12": preload("res://scripts/minigames/s03/quebra_gelo.gd")`
  em `MINIGAMES` e na lista da S03.
- `traducoes.gd`: `"Quebra-Gelo": "Icebreaker"`, `"Rache!": "Crack it!"`; em
  `EN_PADROES`, `["^Blocos: (\\d+)$", "Blocks: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a K2 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: o Quebra-Gelo — riscar o touchpad no contratempo`
