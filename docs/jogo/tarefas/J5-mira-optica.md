# J5 — Mira Óptica

**Sprint:** J · **Slot:** S02_J10 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, F03, H07, G03 (o L2 é do item), J1 (o `secao.gd`)

## Por quê

Mirar é girar o controle como uma luneta — guinada e arfagem levam a mira —
e disparar com o R2 na batida em que o alvo acende: o giroscópio como
ponteiro, com a parede e o clique do gatilho no dedo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 10 em 03](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)
- [O índice da seção](J-a-viga.md) e a [J1](J1-a-viga.md#o-cenário) (o `secao.gd`)
- Os sinos d'A Viga de antes (`godot/scripts/salas/viga.gd:365-431`, no
  histórico do git depois da J1): a mira por giroscópio que já foi medida

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J10",
	"titulo": "Mira Óptica",
	"verbo": "Mire!",
	"genero": "tct",
	"icone": "giroscopio",
	"entradas": [Forja.L1],
	"camera": "fixa",
	"faixa": "MUS_S02_J10",
	"duracao": 75.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Mire!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S02_J10` — até a H05, a sintetizada a 96 bpm; com a
  gerada, 115 bpm ("trap espaçado, foco").
- **O painel:** na parede do fundo, na frente de cada raia, seis escudos
  (`shield-round`) numa grade de 3 × 2: `x ∈ {−1,0; 0; +1,0}` do meio da raia,
  `y ∈ {1,5; 2,3}`.
- **A mira:** um retículo na cor do lugar, no painel dele. **Girar o
  controle** leva a mira: guinada para a esquerda leva para a esquerda,
  erguer a borda de longe leva para cima (`m.x −= giro.y × 2,2 × dt`,
  `m.y += giro.x × 2,2 × dt`, como os sinos de antes). Sem giroscópio, o
  analógico direito (× 2,6). **L1** traz a mira ao centro.
- **O hoqueto em colcheias:** o alvo do lugar `l` acende na batida
  `2k + 0,5·l`: fraco um tempo antes (a prévia), cheio na batida, e some um
  tempo depois. Sorteado pela semente, nunca o mesmo escudo duas vezes
  seguidas. `Ritmo.simples[l]`: um a cada 4 tempos.
- **O tiro:** o R2 cruza 75% vindo de baixo de 50% (com a arma do gatilho,
  o clique fica ali). Com a janela da nota aberta (meio tempo antes):
  a mira a menos de 0,35 m do escudo aceso → `julgar_toque`; longe dele →
  erro (ricochete). Tiro antes da janela: ricochete sem nota (a mira
  embaça). A nota passou sem tiro (`FOLGA_PERDIDA`, o do kit) → perdida.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`.
  Cada acerto derruba o escudo (ele gira e volta no próximo acender).
- **A progressão:** `progresso()` do kit (em tempo de música, H08). De 0 a 1/3, um alvo a cada 2
  tempos. **O pico (1/3 a 2/3), o tiroteio:** um alvo por tempo
  (`k + 0,25·l`) e os escudos balançam ±0,3 m na batida. De 2/3 em diante,
  a cada 2 tempos. Alvos de cada um em 75 s: ~45 a 96 bpm, ~55 a 115 bpm.

## O cenário

`SECAO.montar(self)` (a caverna); os atiradores na plataforma da frente, os
painéis na parede do fundo, a lava entre eles:

| o quê | peça | onde (m) |
| --- | --- | --- |
| o painel | `Kit.caixa(3.2, 1.8, 0.1)`, `#3a3346` | `(RAIAS[l], 1.9, −5.75)` |
| os escudos | `shield-round` (escala 2), de frente para a câmera | `(RAIAS[l] + x, y, −5.6)` |
| a moldura acesa | `Kit.caixa(0.9, 0.9, 0.04)`, `Kit.material(Tema.AMARELO, 2.0)`, atrás do escudo da vez; na prévia, energia 0,5 | `z = −5.68` |
| a mira | quatro traços `Kit.caixa(0.2, 0.04, 0.02)`/`(0.04, 0.2, 0.02)` e o ponto `Kit.caixa(0.06, 0.06, 0.02)`, `Kit.chapado(Tema.tom_para_a_borda(cor do lugar), true)` | `(RAIAS[l] + m.x, m.y, −5.3)` |
| o atirador | o boneco, de costas, mãos livres | `(RAIAS[l], 0.05, 4.2)` |
| o disparo | `Kit.caixa(0.06, 0.06, 0.5)`, `Kit.material(Tema.AMARELO, 2.0)`, que voa do boneco à mira em 0,15 s | — |

Câmera: `camera_pos = Vector3(0, 5.0, 13.5)`, `camera_olhar = Vector3(0, 1.8, -3.0)`.
A mira é interface no mundo (chapada, na cor do lugar: marca aquele
jogador). O brilho só na moldura do alvo e no disparo.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **giroscópio (a feature)** | a guinada e a arfagem levam a mira |
| vibração | o kit por nota |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Som.no_controle(l, "alvo", 0.6)`; erro: a nota quebrada (o kit) |
| gatilho | R2 com a arma (Weapon `2, 6, 8`: a parede e o clique) do começo ao fim — o disparo se sente |
| háptica por material | `metal`, pelo kit |
| som na TV | a nota (o kit); `tiro` a cada disparo; `alvo` no escudo derrubado; `tique` grave (tom 0,7) no ricochete |

## A falha

O disparo fora do alvo ricocheteia: faísca no painel longe do escudo,
`tique` grave, e **a mira embaça** por 1 tempo — o retículo cresce 1,6 vez e
anda com metade da sensibilidade. O próximo alvo acende no tempo de sempre.

## O fim e o vencedor

75 s (a F03). `vencedor()`: mais escudos derrubados; empate pelos pontos,
depois pelo lugar.

## Com menos de quatro

Nada muda. **O controle que cai:** os alvos dele param (sem erro); ao
voltar, a mira volta ao centro, o R2 recebe a arma de novo e o próximo alvo
é a próxima batida dele pelo menos 1 tempo adiante.

## O robô

Mira pelo giroscópio simulado até o escudo da vez (a conta dos sinos de
antes), a partir da prévia; dispara com o R2 na batida (ou 200 ms atrasado).

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	var gx := 0.0
	var gy := 0.0
	var gz := -2.5 * Forja.postura(l).x  # sem rolar
	if float(e.b) >= 0.0 and Ritmo.batida() >= float(e.b) - 1.0:
		if int(e.robo_n) != int(e.n):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			e.robo_n = int(e.n)
			e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		var alvo: Vector2 = _pos_do_alvo(int(e.alvo))  # onde o escudo está agora (no pico, balança)
		var m: Vector2 = e.mira
		gy = clampf(-6.0 * (alvo.x - m.x) / SENSIBILIDADE, -4.5, 4.5)
		gx = clampf(6.0 * (alvo.y - m.y) / SENSIBILIDADE, -4.5, 4.5)
		var quando := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
		var agora := Ritmo.t_musica()
		if agora >= quando - 0.01 and agora <= quando + 0.08:
			Forja.robo_eixo(l, Forja.R2, 1.0, 0.06)
	Forja.robo_girar(l, Vector3(gx, gy, gz), 0.06)
```

## Os ganchos

`godot/scripts/minigames/s02/mira_optica.gd`:

```gdscript
extends Minigame
## Mira Óptica (S02_J10). Cada um tem um painel de seis escudos na parede do
## fundo; girar o controle leva a mira (guinada e arfagem), L1 centraliza.
## O escudo do lugar acende na batida dele (o hoqueto em colcheias) e some no
## tempo seguinte: o R2 dispara, com a parede e o clique da arma. No meio,
## o tiroteio: um alvo por tempo, e os escudos balançam.
##
## A falha: o disparo fora do alvo ricocheteia e embaça a mira por um tempo.
## O vencedor: mais escudos derrubados.
## O alto-falante do dono: o alvo no acerto, a nota no perfeito.
## O registro mede: a distância da mira ao alvo em cada disparo (o ângulo
## pedido contra o feito, na linha `entrada`) e o atraso (o kit).
## O robô: gira até o escudo a partir da prévia e dispara na batida.
## Com menos de quatro: nada muda.
## A régua: "Mire!" e o giroscópio bastam; sem a tela, não (o alvo é
## visual); nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const POSICOES := [Vector2(-1.0, 1.5), Vector2(0.0, 1.5), Vector2(1.0, 1.5),
	Vector2(-1.0, 2.3), Vector2(0.0, 2.3), Vector2(1.0, 2.3)]
const MIRA_X := 1.45
const MIRA_Y0 := 1.2
const MIRA_Y1 := 2.45
const SENSIBILIDADE := 2.2  ## m de mira por rad girado
const RAIO := 0.35
const Z_PAINEL := -5.6
const DISPARA := 0.75
const SOLTO := 0.5
const PONTOS := [0, 20, 35, 50]

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 5.0, 13.5)
	camera_olhar = Vector3(0, 1.8, -3.0)
	SECAO.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		var x: float = RAIAS[l]
		Kit.caixa(self, Vector3(3.2, 1.8, 0.1), Vector3(x, 1.9, -5.75), Kit.material(Color("#3a3346"), 0.0, 0.9))
		var escudos: Array = []
		for pos in POSICOES:
			escudos.append(Kit.peca(self, "shield-round", Vector3(x + pos.x, pos.y, Z_PAINEL)))
		var moldura := Kit.caixa(self, Vector3(0.9, 0.9, 0.04), Vector3(x, 1.5, Z_PAINEL - 0.08), Kit.material(Tema.AMARELO, 2.0))
		moldura.visible = false
		var mira := Node3D.new()
		add_child(mira)
		var tinta := Kit.chapado(Tema.tom_para_a_borda(Forja.cor_do_lugar(l)), true)
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var tam := Vector3(0.2, 0.04, 0.02) if d.y == 0 else Vector3(0.04, 0.2, 0.02)
			Kit.caixa(mira, tam, Vector3(d.x * 0.3, d.y * 0.3, 0), tinta)
		Kit.caixa(mira, Vector3(0.06, 0.06, 0.02), Vector3.ZERO, tinta)
		maos_livres(p)
		p.preso = true
		p.position = Vector3(x, 0.05, 4.2)
		p.rotation.y = PI
		j[l] = {"n": 0, "b": -1.0, "alvo": -1, "mira": _centro(), "r2_antes": 0.0, "embaca_b": -99.0,
			"derrubados": 0, "fora": false, "escudos": escudos, "moldura": moldura, "no_mira": mira,
			"robo_n": -1, "robo_mira": 0.0}


static func _centro() -> Vector2:
	return Vector2(0.0, (MIRA_Y0 + MIRA_Y1) * 0.5)


func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var passo := 2.0
	var desloc := 0.5 * l
	if Ritmo.simples[l]:
		passo = 4.0
	elif no_pico():
		passo = 1.0
		desloc = 0.25 * l
	e.b = proxima_batida(l, desde + 0.001, passo, desloc)  # o kit; estritamente depois de desde
	var novo := rng.randi_range(0, POSICOES.size() - 2)
	if novo >= int(e.alvo) and int(e.alvo) >= 0:
		novo += 1
	e.alvo = novo
	nova_nota(l, int(e.n), Ritmo.t_da_batida(float(e.b)))


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)  # sem giroscópio ou acelerômetro: a linha `troca` (H08)
		Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


## A posição do escudo agora (no pico, eles balançam na batida).
func _pos_do_alvo(i: int) -> Vector2:
	var pos: Vector2 = POSICOES[i]
	if no_pico():
		pos.x += 0.3 * sin(Ritmo.batida() * PI)
	return pos


func jogar(dt: float) -> void:
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
			e.mira = _centro()
			Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)
			_proxima(l, Ritmo.batida() + 1.0)
		_mirar(l, e, dt)
		_atirar(l, e)


## A mira anda com o giro do controle (a taxa do próprio controle vezes dt:
## aqui o dt é o certo — é a integração do sensor, não o ritmo).
func _mirar(l: int, e: Dictionary, dt: float) -> void:
	var m: Vector2 = e.mira
	var k := 0.5 if Ritmo.batida() - float(e.embaca_b) < 1.0 else 1.0
	if Forja.capacidade(l, "giro"):
		var g := Forja.giro(l)
		m.x -= g.y * SENSIBILIDADE * dt * k
		m.y += g.x * SENSIBILIDADE * dt * k
	else:
		m.x += Forja.eixo(l, Forja.RX) * 2.6 * dt * k
		m.y -= Forja.eixo(l, Forja.RY) * 2.6 * dt * k
	if Forja.apertou(l, Forja.L1):
		m = _centro()
	e.mira = Vector2(clampf(m.x, -MIRA_X, MIRA_X), clampf(m.y, MIRA_Y0, MIRA_Y1))


func _atirar(l: int, e: Dictionary) -> void:
	var r2 := Forja.eixo(l, Forja.R2)
	var disparou := float(e.r2_antes) < SOLTO and r2 >= DISPARA
	if r2 < SOLTO or disparou:
		e.r2_antes = r2
	var alvo := Ritmo.t_da_batida(float(e.b))
	var agora := Ritmo.t_musica()
	var aberta := agora >= alvo - 0.5 * 60.0 / Ritmo.bpm
	if disparou:
		var m: Vector2 = e.mira
		var dist := m.distance_to(_pos_do_alvo(int(e.alvo)))
		_disparo(l, m)
		if not aberta:
			_ricochete(l, m)  # cedo demais: embaça, sem nota
			return
		Forja.evento("entrada", l + 1, {"o": "mira", "erro_m": snappedf(dist, 0.01), "n": int(e.n)})
		if dist <= RAIO:
			julgar_toque(l, alvo, int(e.n))
		else:
			_ricochete(l, m)
			nota_perdida(l, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func _disparo(l: int, m: Vector2) -> void:
	var p := jogador(l)
	var de := p.global_position + Vector3(0.3, 1.3, -0.3) if p else Vector3(RAIAS[l], 1.3, 4.0)
	var ate := Vector3(RAIAS[l] + m.x, m.y, Z_PAINEL + 0.1)
	var bala := Kit.caixa(self, Vector3(0.06, 0.06, 0.5), de, Kit.material(Tema.AMARELO, 2.0))
	bala.look_at_from_position(de, ate, Vector3.UP)
	var tw := bala.create_tween()
	tw.tween_property(bala, "global_position", ate, 0.15)
	tw.tween_callback(bala.queue_free)
	Som.tocar("tiro", de, -6.0)
	if p:
		p.gesto("attack-melee-right", 0.3)


func _ricochete(l: int, m: Vector2) -> void:
	j[l].embaca_b = Ritmo.batida()
	var onde := Vector3(RAIAS[l] + m.x, m.y, Z_PAINEL + 0.1)
	Efeitos.faiscas(self, onde, Tema.LARANJA, 12, 0.5)
	Som.tocar("tique", onde, -6.0, 0.7)


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if not treinando:
		e.derrubados = int(e.derrubados) + 1
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "alvo", 0.6)
	var escudo: Node3D = e.escudos[int(e.alvo)]
	Som.tocar("alvo", escudo.global_position, -2.0)
	Efeitos.faiscas(self, escudo.global_position, Tema.AMARELO, 20, 0.8)
	var tw := escudo.create_tween()
	tw.tween_property(escudo, "rotation:x", -PI * 0.5, 0.12)
	tw.tween_property(escudo, "rotation:x", 0.0, 0.3).set_delay(0.3)
	_proxima(l, float(e.b))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	_proxima(l, float(j[l].b))


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var m: Vector2 = e.mira
	var no_mira: Node3D = e.no_mira
	no_mira.position = Vector3(RAIAS[l] + m.x, m.y, Z_PAINEL + 0.3)
	no_mira.visible = fase == "jogo" and not acabou[l]
	no_mira.scale = Vector3.ONE * (1.6 if Ritmo.batida() - float(e.embaca_b) < 1.0 else 1.0)
	var moldura: MeshInstance3D = e.moldura
	var falta := float(e.b) - Ritmo.batida()
	moldura.visible = fase == "jogo" and int(e.alvo) >= 0 and falta <= 1.0 and falta > -1.0
	if moldura.visible:
		var pos := _pos_do_alvo(int(e.alvo))
		moldura.position = Vector3(RAIAS[l] + pos.x, pos.y, Z_PAINEL - 0.08)
		(moldura.material_override as StandardMaterial3D).emission_energy_multiplier = 0.5 if falta > 0.0 else 2.0
		(e.escudos[int(e.alvo)] as Node3D).position.x = RAIAS[l] + pos.x


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].derrubados) != int(j[b].derrubados):
		return int(j[a].derrubados) > int(j[b].derrubados)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Alvos: %d" % int(j[lugar].derrubados)
	return super(lugar)
```

## O que o registro mede

- O kit: `nota` (o instante em que o alvo acende) e `toque` (o disparo).
- A linha `entrada` em cada disparo na janela: **a distância da mira ao
  escudo** (m; o ângulo pedido contra o feito, pela sensibilidade de 2,2 m
  por rad) e o `n`; no começo, os sensores. Cruzado: um giroscópio com a
  taxa errada (a mira que passa do alvo) ou com um eixo invertido (a mira que
  foge) aparece aqui.

## Armadilhas

- **O `dt` na mira está certo:** é a integração da taxa do próprio controle
  (rad/s), como nos sinos de antes. O ritmo (o alvo, a janela) é pela batida.
- **O R2 com a arma** manda o Weapon; o L2 é do item (nunca `gatilhos_off`).
  O fim do kit solta os dois.
- **O disparo é o cruzamento** de 75% vindo de menos de 50%; segurar o R2 no
  fundo não dispara de novo.
- **O escudo que balança no pico** volta ao lugar sozinho quando o pico
  acaba (o `_pos_do_alvo`); a moldura e o escudo andam juntos.
- **`look_at_from_position`** com o alvo quase na vertical avisa no console;
  o disparo sai de 1,3 m e vai a 1,5–2,3 m, nunca vertical.

## Pronto quando

A mira joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta recebe a arma de novo; o fim tem
sempre vencedor; `bash tests/prova_do_jogo.sh` passa; e
`bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S02_J10 (J5): a mira abre pelo catálogo; o R2 de cada controle recebe a
## arma; o robô derruba escudos mirando pelo giroscópio simulado.
func _prova_da_mira() -> void:
	var arma := [false, false, false, false]
	var olhar := func(_mg: Minigame) -> void:
		for l in 4:
			if int(_perc(l).get("gatilho_dir", 0)) == 0x25:
				arma[l] = true
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (75 s de música e o treino)
	var mg = await _joga_o_minigame("S02_J10", 115.0, olhar)
	if mg == null:
		return
	for l in 4:
		_esperar(arma[l], "S02_J10 P%d: o R2 com a arma" % (l + 1))
	for l in 4:
		_esperar(int(mg.j[l].derrubados) >= 1, "S02_J10 P%d: derrubou um escudo %s" % [l + 1, mg.contagem[l]])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S02_J10: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S02_J10`: girar o controle
leva a mira sem susto, o L1 salva, a parede e o clique do R2 se sentem, a
prévia de um tempo dá para mirar, e o tiroteio do meio aperta.

## Ao terminar

- Catálogo: `"S02_J10": preload("res://scripts/minigames/s02/mira_optica.gd")`
  em `MINIGAMES` e na lista da S02.
- `traducoes.gd`: `"Mira Óptica": "Optical Aim"`, `"Mire!": "Aim!"`; em
  `EN_PADROES`, `["^Alvos: (\\d+)$", "Targets: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a J5 **feito**, com o commit e o gasto real.
- Commit (sem trailer): `feat: a Mira Óptica — girar o controle para mirar, o R2 na batida`
