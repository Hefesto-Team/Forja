# K4 — A Pinça

**Sprint:** K · **Slot:** S03_J14 · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, F03, H07, K1 (o `secao.gd`)

## Por quê

A pinça são dois dedos: pegar a peça quente na nota (o segundo dedo chega),
esticá-la enquanto a nota longa dura (os dedos se afastam) e soltar no fim
dela (os dois sobem) — os dois dedos do touchpad ao mesmo tempo, a perda de
um deles no meio, e o segurar e soltar no tempo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 14 em 03](../03-os-45-minigames.md#s3--o-molde--touchpad)
- [O índice da seção](K-o-molde.md) e a [K1](K1-o-molde.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S03_J14",
	"titulo": "A Pinça",
	"verbo": "Segure e solte!",
	"genero": "tct",
	"icone": "touchpad",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S03_J14",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Solte!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S03_J14` — até a H05, a sintetizada da seção a 100 bpm;
  com a gerada, 118 bpm ("grave sujo, subterrâneo").
- **A peça, duas notas:** **pegar** na batida `b` — o instante em que o
  segundo dedo encosta (os dois ficam encostados) — e **soltar** na batida
  `b + L` — o instante em que os dois deixam de estar encostados. Entre uma e
  outra, a nota longa: **esticar**, afastando os dedos. Soltar com a
  abertura máxima abaixo de 0,45 da largura (não esticou) é erro, mesmo no
  tempo.
- **O hoqueto em semínimas:** o lugar `l` pega em `4c + l` e solta `L = 2`
  tempos depois — as quatro notas longas se cruzam no compasso. Um tempo
  antes da batida de pegar, a peça quente aparece no meio da placa dele.
  `Ritmo.simples[l]`: uma peça a cada 2 compassos.
- **O julgamento, no cruzamento** (as convenções da seção): pegar cedo (os
  dois dedos já encostados quando a janela abre) é julgado ali; soltar cedo
  é soltar. Não pegou até `FOLGA_PERDIDA`, o do kit depois → nota perdida (e a
  soltura dessa peça nem existe). Segurou além da janela de soltar → nota
  perdida.
- **A peça encaixada** é a que teve pegar e soltar BOM ou melhor, esticada.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`
  em cada nota; a peça encaixada +50.
- **A progressão:** `progresso()` do kit (em tempo de música, H08). De 0 a 1/3, uma peça por
  compasso, 2 tempos de nota longa. **O pico (1/3 a 2/3), a linha de
  montagem:** duas peças por compasso (pegar em `2k + 0,5·l`), `L = 1`. De
  2/3 em diante, uma por compasso. Peças de cada um em 80 s: ~30 a 100 bpm,
  ~37 a 118 bpm.

## O cenário

`SECAO.montar(self)` (a oficina) e, por lugar, `SECAO.bancada(self, l, false)`:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a peça quente | `Kit.caixa(1.0, 0.08, 0.12)` na placa, `Kit.material(Color("#ff7a2a"), 1.6)`; na espera, curta (0,3 m) no meio; na nota longa, esticada entre os dois dedos | placa, `y = 0.14` |
| a estante | `wood-structure` (escala 1,2) e as peças encaixadas, `Kit.caixa(0.5, 0.06, 0.1)`, ferro `#5b6275`, de 4 em 4 | `(cx, 0, −1.6)`; peças em `(cx − 0.6 + 0.4·(k % 4), 0.9 + 0.3·(k / 4), −1.6)` |
| o ferreiro | o boneco, de perfil, mãos livres | `(RAIAS[l] − 1.45, 0.05, 0.35)` |

Câmera: `camera_pos = Vector3(0, 8.6, 12.7)`, `camera_olhar = Vector3(0, 0.8, -0.1)`.
A peça quente brilha (é metal em brasa: tem trabalho). Nada liso.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **touchpad (a feature)** | os dois dedos: pegar, esticar, soltar |
| vibração | o kit por nota |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); pegar no ótimo/bom: `Forja.som_falante(l, "clique", 0.4)`; a peça encaixada: `Forja.som_falante(l, "coleta", 0.7)`; erro: a nota quebrada (o kit) |
| háptica por material | a textura `metal` sob os dedos enquanto seguram (`SECAO.textura(l, "metal")`) |
| gatilho | livre (o R2 Off) |
| som na TV | a nota (o kit); `sopro` baixo enquanto estica (uma vez por peça); `martelo` quando a peça encaixa na estante; `falha` e faíscas quando ela cai |

## A falha

A peça cai e espirra faísca: ela despenca da placa (`position.y` até −0,6 em
0,3 s) com faíscas `Tema.LARANJA`, e o ferreiro faz `emote-no`. A peça
seguinte aparece no tempo de sempre.

## O fim e o vencedor

80 s (a F03). `vencedor()`: mais peças encaixadas; empate pelos pontos,
depois pelo lugar.

## Com menos de quatro

Nada muda. **O controle que cai:** a peça dele some (sem erro); ao voltar,
a próxima peça é o próximo tempo dele pelo menos 1 tempo adiante.

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
	var agora := Ritmo.t_musica()
	var pega := Ritmo.t_da_batida(float(e.b))
	if str(e.estado) == "pegar":
		if agora >= pega + float(e.robo_mira):
			# os dois dedos encostam juntos
			Forja.robo_tocar(l, 0, 0.4, 0.5, 0.06)
			Forja.robo_tocar(l, 1, 0.6, 0.5, 0.06)
		return
	# segurando: afasta os dedos até a mira da soltura; depois dela, não toca (os dois sobem)
	var solta := Ritmo.t_da_batida(float(e.b) + float(e.len)) + float(e.robo_mira)
	if agora < solta:
		var s := lerpf(0.1, 0.35, clampf((agora - pega) / maxf(solta - pega, 0.01), 0.0, 1.0))
		Forja.robo_tocar(l, 0, 0.5 - s, 0.5, 0.06)
		Forja.robo_tocar(l, 1, 0.5 + s, 0.5, 0.06)
```

## Os ganchos

`godot/scripts/minigames/s03/a_pinca.gd`:

```gdscript
extends Minigame
## A Pinça (S03_J14). A peça quente aparece na placa (o touchpad). Dois dedos
## pegam na nota do lugar (o hoqueto em semínimas), esticam enquanto a nota
## longa dura e soltam no fim dela. Pegar e soltar no tempo, esticada: a peça
## encaixa na estante. No meio, a linha de montagem: duas por compasso.
##
## A falha: a peça cai e espirra faísca.
## O vencedor: mais peças encaixadas.
## O alto-falante do dono: o clique no pegar, a coleta na peça, a nota no perfeito.
## O registro mede: os dois dedos juntos, a abertura máxima, quanto tempo
## seguraram e se um dedo se perdeu antes (a linha `entrada`), e o tempo (o kit).
## O robô: encosta os dois na nota, afasta até a soltura e solta os dois juntos.
## Com menos de quatro: nada muda.
## A régua: "Segure e solte!" e o touchpad bastam; sem a tela, a nota de pegar
## e a de soltar se ouvem; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s03/secao.gd")

# (a FICHA vem aqui)

const ESTICADA := 0.45
const PONTOS := [0, 20, 35, 50]
const ENCAIXE := 50

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 8.6, 12.7)
	camera_olhar = Vector3(0, 0.8, -0.1)
	SECAO.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		var nos := SECAO.bancada(self, l, false)
		var placa: Node3D = nos.placa
		var peca := Kit.caixa(placa, Vector3(1.0, 0.08, 0.12), Vector3(0, 0.14, 0), Kit.material(Color("#ff7a2a"), 1.6))
		peca.visible = false
		nos["peca"] = peca
		Kit.peca(self, "wood-structure", Vector3(float(nos.cx), 0, -1.6), 0.0, 1.2)
		maos_livres(p)
		p.position = Vector3(RAIAS[l] - 1.45, 0.05, 0.35)
		p.rotation.y = PI * 0.5
		j[l] = {"n": 0, "b": -1.0, "len": 2.0, "estado": "pegar", "antes": false, "aberta": false, "abertura": 0.0,
			"pegou_t": 0.0, "pegou_j": 0, "soprou": false, "encaixadas": 0, "fora": false, "nos": nos,
			"robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A próxima peça do lugar depois de `desde`: a batida de pegar e o tamanho da nota longa.
func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var passo := 4.0
	var desloc := float(l)
	e.len = 2.0
	if Ritmo.simples[l]:
		passo = 8.0
	elif no_pico():
		passo = 2.0
		desloc = 0.5 * l
		e.len = 1.0
	e.b = proxima_batida(l, desde + 0.001, passo, desloc)  # o kit; estritamente depois de desde
	e.estado = "pegar"
	e.aberta = false
	e.antes = false
	e.abertura = 0.0
	e.soprou = false
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
		nota_perdida(l, int(e.n))


func _segurar(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b) + float(e.len))
	var dois := _dois(l)
	if dois:
		e.abertura = maxf(float(e.abertura), _abertura(l))
		SECAO.textura(l, "metal")
		if not bool(e.soprou) and float(e.abertura) > 0.3:
			e.soprou = true
			Som.tocar("sopro", (e.nos.placa as Node3D).global_position, -10.0)
	if not dois:
		# soltou (os dois, ou perdeu um): o instante é a soltura
		var dedos := int(Forja.dedo(l, 0).z > 0.5) + int(Forja.dedo(l, 1).z > 0.5)
		Forja.evento("entrada", l + 1, {"o": "dois_dedos", "abertura_max": snappedf(float(e.abertura), 0.01),
			"segurou_ms": int((agora - float(e.pegou_t)) * 1000.0), "dedos_no_fim": dedos, "n": int(e.n)})
		if float(e.abertura) < ESTICADA:
			nota_perdida(l, int(e.n))  # não esticou: a peça cai
		else:
			julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if str(e.estado) == "pegar":
		if julgamento != Ritmo.PERFEITO:
			Forja.som_falante(l, "clique", 0.4)
		e.pegou_j = julgamento
		e.estado = "segurar"
		e.n = int(e.n) + 1
		nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b) + float(e.len)))
		return
	# soltou no tempo e esticada: encaixa
	if not treinando:
		e.encaixadas = int(e.encaixadas) + 1
		marcar(l, ENCAIXE)
		_na_estante(l)
	Forja.som_falante(l, "coleta", 0.7)
	e.n = int(e.n) + 1
	_proxima(l, float(e.b) + float(e.len))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var peca: Node3D = nos.peca
	Efeitos.faiscas(self, peca.global_position, Tema.LARANJA, 24, 0.8)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	var fim := float(e.b) + (float(e.len) if str(e.estado) == "segurar" else 0.0)
	e.n = int(e.n) + 1
	_proxima(l, fim)


func _na_estante(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var k := int(e.encaixadas) - 1
	var pos := Vector3(float(nos.cx) - 0.6 + 0.4 * (k % 4), 0.9 + 0.3 * int(k / 4.0), -1.6)
	Kit.caixa(self, Vector3(0.5, 0.06, 0.1), pos, Kit.material(Color("#5b6275"), 0.0, 0.6))
	Som.tocar("martelo", pos, -6.0)
	Efeitos.faiscas(self, pos, Tema.AMARELO, 12, 0.6)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var nos: Dictionary = e.nos
	var peca: MeshInstance3D = nos.peca
	if fase != "jogo" or acabou[l] or float(e.b) < 0.0:
		peca.visible = false
		return
	if str(e.estado) == "pegar":
		peca.visible = Ritmo.batida() >= float(e.b) - 1.0
		peca.position = SECAO.no_molde(0.5, 0.5, 0.14)
		peca.rotation.y = 0.0
		peca.scale = Vector3(0.3, 1, 1)
		return
	var a := Forja.dedo(l, 0)
	var b := Forja.dedo(l, 1)
	var pa := SECAO.no_molde(a.x, a.y, 0.14)
	var pb := SECAO.no_molde(b.x, b.y, 0.14)
	peca.visible = true
	peca.position = (pa + pb) * 0.5
	peca.rotation.y = atan2(pb.z - pa.z, pb.x - pa.x) * -1.0
	peca.scale = Vector3(maxf(0.1, pa.distance_to(pb)), 1, 1)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].encaixadas) != int(j[b].encaixadas):
		return int(j[a].encaixadas) > int(j[b].encaixadas)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Peças: %d" % int(j[lugar].encaixadas)
	return super(lugar)
```

## O que o registro mede

- O kit: `nota` e `toque` para pegar e para soltar (o segurar e soltar no tempo).
- A linha `entrada` em cada soltura: **a abertura máxima**, quanto tempo os
  dois dedos seguraram, e **quantos dedos ficaram** no instante da soltura
  (1 = um dedo se perdeu antes: a perda de toque). Cruzado: um touchpad que
  larga o segundo dedo no meio da nota longa aparece aqui, noite toda.

## Armadilhas

- **Soltar é o primeiro quadro sem os dois dedos**: perder um dedo no meio é
  soltar (cedo). É a medida da perda de toque: o `dedos_no_fim` diz qual foi.
- **A soltura só existe depois de pegar:** a `nota` dela entra no registro no
  `toque` do pegar; peça não pegada não tem soltura (nem `nota`, nem `toque`).
- **O `n` sobe duas vezes por peça** (pegar e soltar) e uma na falha.
- **A peça esticada** gira no plano da placa: `rotation.y` local da placa
  (inclinada), e o comprimento é a distância entre os dois dedos no mundo.

## Pronto quando

A Pinça joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta não derruba peça com erro; o fim
tem sempre vencedor; `bash tests/prova_do_jogo.sh` passa; e
`bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S03_J14 (K4): a Pinça abre pelo catálogo; os dois dedos simulados de cada
## lugar pegam e soltam no tempo; o fim tem vencedor.
func _prova_da_pinca() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (80 s de música e o treino)
	var mg = await _joga_o_minigame("S03_J14", 120.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[2]) + int(c[3]) >= 1, "S03_J14 P%d: pegou no tempo %s" % [l + 1, c])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S03_J14: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S03_J14`: pegar com dois
dedos na nota é natural, esticar durante a nota longa dá gosto, soltar no
fim se ouve, a peça que cai faz rir, e a linha de montagem do meio aperta.

## Ao terminar

- Catálogo: `"S03_J14": preload("res://scripts/minigames/s03/a_pinca.gd")` em
  `MINIGAMES` e na lista da S03.
- `traducoes.gd`: `"A Pinça": "The Tongs"`, `"Segure e solte!": "Hold and release!"`,
  `"Solte!": "Release!"`; em `EN_PADROES`, `["^Peças: (\\d+)$", "Pieces: $1"]`
  se ainda não estiver lá (a K1 põe).
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a K4 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: A Pinça — pegar, esticar e soltar com dois dedos no tempo`
