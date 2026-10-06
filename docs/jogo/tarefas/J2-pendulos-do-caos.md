# J2 — Pêndulos do Caos

**Sprint:** J · **Slot:** S02_J07 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, H07, J1 (o `secao.gd`)

## Por quê

Virar no alto é um golpe de pulso — o controle gira rápido para o centro no
instante em que o pêndulo chega ao topo do arco: não é a inclinação que
conta, é a velocidade do giro, no tempo; o giroscópio medido pelo pico.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o exemplo da FICHA dele é este minigame)
- [H04 — O kit do minigame](H04-o-kit-do-minigame.md)
- [A linha n.º 7 em 03](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)
- [O índice da seção](J-a-viga.md) e a [J1](J1-a-viga.md#o-cenário) (o `secao.gd`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S02_J07",
	"titulo": "Pêndulos do Caos",
	"verbo": "Vire no alto!",
	"genero": "sobrevivencia",
	"icone": "giroscopio",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J07",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "aviso", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Vire!", "segundos": 6.0},
}
```

## Como se joga

- **A faixa:** `MUS_S02_J07` — até a H05, a sintetizada a 96 bpm; com a
  gerada, 130 bpm ("bolero que cresce em camadas").
- **O pêndulo:** cada um de pé no disco do seu pêndulo, que balança pela
  batida: `φ = A · cos(π · (batida − 0,5·l) / 2)`, `A = 0,6 rad`. O alto do
  arco (o ápice) cai em `2m + 0,5·l`: à direita com `m` par, à esquerda com
  `m` ímpar — o hoqueto em colcheias, os quatro pêndulos em onda.
- **A nota é o ápice:** no alto à direita, **vire para a esquerda** (para o
  centro); no alto à esquerda, para a direita. O toque é o quadro em que a
  velocidade de rolagem passa de **2,5 rad/s** para o lado pedido
  (`-Forja.giro(l).z` é a velocidade para a direita), dentro da janela que
  abre meio tempo antes. Nada até `FOLGA_PERDIDA`, o do kit → nota perdida.
  Perigo físico: `julgar_toque(l, alvo, n, true)`.
- **O perigo:** o erro soma 1; PERFEITO e ÓTIMO tiram 1. **No 2, o pêndulo
  trava e arremessa o cavaleiro:** ele voa para a lava, e volta ao disco 8
  tempos depois, com o perigo zerado. **A terceira queda o faz fantasma.**
- **O fantasma** fica na plataforma da frente (`z = 4.2`) e continua virando
  no tempo do pêndulo dele (vazio). Cada acerto ÓTIMO ou PERFEITO dele sopra
  **vento** no líder (o vivo com menos quedas; empate, mais pontos; nunca
  ele mesmo): por 4 tempos, o líder precisa virar com **3,5 rad/s**. O vento
  se vê (faíscas lilás do fantasma ao disco do líder) e se sente
  (`Forja.sentir(lider, "aviso", ms)`); não muda janela nenhuma.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o fantasma ganha 10 por sopro (desempate entre fantasmas).
- **A progressão:** `andamento()` do kit (em tempo de música, H08). De 0 a 1/3, o balanço de 4
  tempos. **O pico (1/3 a 2/3), o bolero cresce:** o balanço de 2 tempos
  (`φ = A · cos(π · (batida − 0,25·l))`, um ápice por tempo, em `k + 0,25·l`)
  e `A = 0,75`. De 2/3 em diante, 4 tempos de novo. `Ritmo.simples[l]`: o
  pêndulo balança igual, mas só um ápice a cada dois é nota.

## O cenário

`SECAO.montar(self)` (a caverna) e, em cima da lava:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a trave | `Kit.caixa(20.0, 0.3, 0.3)`, `#8a5a33`, e dois `column` nas pontas | `(0, 5.4, 0.8)`; `column` em `x = ±10.5, z = 0.8` |
| o pêndulo | um `Node3D` no pivô, girando em `rotation.z = φ`; a corrente: 7 `Kit.caixa(0.08, 0.55, 0.08)`, ferro; o disco: `CylinderMesh` de raio 0,7, altura 0,15, **8 lados** (`radial_segments = 8`), `#5b6275` | pivô em `(RAIAS[l], 5.3, 0.8)`; o disco a 4,2 m abaixo |
| o cavaleiro | o boneco, `preso`, de costas | no disco: `pivô + (4.2·sin φ, −4.2·cos φ + 0.1, 0)`; `p.modelo.rotation.z = φ · 0.5` |
| o fantasma | o mesmo boneco na plataforma da frente, com uma `OmniLight3D` `#b9b0ff` (0,6) em cima | `(RAIAS[l], 0.1, 4.2)` |

Câmera: `camera_pos = Vector3(0, 6.0, 13.0)`, `camera_olhar = Vector3(0, 2.4, 0.0)`.
Nada liso: o disco é octogonal, a corrente em caixas. A cor do lugar só no
aro do boneco.

## O repertório

| recurso | o que acontece, e quando |
| --- | --- |
| **giroscópio (a feature)** | a velocidade do giro, no ápice |
| vibração | o kit por nota; o arremesso: `golpe`; virar fantasma: `explosao`; o vento chegando no líder: `aviso` |
| barra de luz | o kit (`_reagir`, H08): branco no perfeito, a cor do lugar escurecida no erro |
| alto-falante do dono | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "clique", 0.4)`; erro: a nota quebrada (o kit); **o metal rangendo** (`"material:metal"`, 0,6) meio tempo antes de cada ápice com `perigo == 1` |
| gatilho | R2: `GATILHO_RESISTENCIA (0, 6)` com `perigo == 1`, Off com 0 — a mão sente que o pêndulo pesa |
| háptica por material | `metal`, pelo kit |
| som na TV | a nota (o kit); `vento` no sopro do fantasma; `falha` no arremesso |

## A falha

O pêndulo trava (um tranco: `φ` para por meio tempo, faíscas no pivô) e,
no segundo erro, arremessa: o cavaleiro sai do disco num arco para a frente
e para baixo, até a lava, em 2 tempos (pela batida), com `fall`. Volta ao
disco 8 tempos depois com `jump`. Na terceira queda, vira fantasma.

## O fim e o vencedor

`fim: ultimo_em_pe`: com dois ou mais presentes, quando sobra um vivo (ou
nenhum), todos acabam. Senão, os 90 s. `vencedor()`: os vivos antes dos
fantasmas; depois menos quedas; depois pontos; depois o lugar.

## Com menos de quatro

Com dois ou três, igual. Sozinho: joga os 90 s, ou até virar fantasma (a
terceira queda acaba o minigame dele). **O controle que cai:** o pêndulo
balança vazio de nota (não há erro), e o vento não o escolhe como líder;
ao voltar, a nota é o próximo ápice dele.

## O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	# volta devagar ao nível (abaixo da velocidade que conta como virada)
	var giro := SECAO.giro_para(l, 0.0, 0.0)
	giro.z = clampf(giro.z, -1.5, 1.5)
	if float(e.caiu_b) < 0.0 and float(e.b) >= 0.0:
		if int(e.robo_n) != int(e.n):
			# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
			e.robo_n = int(e.n)
			e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
		var alvo := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
		var agora := Ritmo.t_musica()
		if agora >= alvo - 0.01 and agora <= alvo + 0.08:
			# o golpe de pulso: 4,5 rad/s para o lado pedido (o z do giro é o contrário da rolagem)
			giro.z = -4.5 * float(e.pedido)
	Forja.robo_girar(l, giro, 0.06)
```

## Os ganchos

`godot/scripts/minigames/s02/pendulos_do_caos.gd`:

```gdscript
extends Minigame
## Pêndulos do Caos (S02_J07). Cada um no disco do seu pêndulo, que balança
## pela batida (os quatro em onda, o hoqueto em colcheias). No alto do arco,
## virar o controle num golpe para o centro inverte o balanço. Dois erros
## seguidos: o pêndulo trava e arremessa; três quedas: fantasma, que sopra
## vento no líder. No meio, o bolero cresce: um ápice por tempo.
##
## A falha: o pêndulo trava; no segundo erro, arremessa o cavaleiro na lava.
## O vencedor: o último em pé; senão, quem caiu menos.
## O alto-falante do dono: o clique no acerto, a nota no perfeito, o metal
## rangendo com o pêndulo pesado.
## O registro mede: o pico da velocidade de giro em cada virada, pedida e
## feita (a linha `entrada`), e o atraso (o kit).
## O robô: um golpe de 4,5 rad/s no ápice (ou 200 ms atrasado); volta devagar.
## Com menos de quatro: sozinho, joga até o tempo ou até virar fantasma.
## A régua: "Vire no alto!" e o giroscópio bastam; sem a tela, o ápice se ouve
## na nota de cada um e o rangido avisa; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const AMPLITUDE := 0.6
const AMPLITUDE_PICO := 0.75
const CORDA := 4.2
const Y_PIVO := 5.3
const Z_PENDULO := 0.8
const VIRADA := 2.5  ## rad/s
const VIRADA_COM_VENTO := 3.5
const VENTO := 4.0  ## tempos
const ARREMESSA := 2  ## perigo
const VIDAS := 3
const FORA := 8.0
const PONTOS := [0, 20, 35, 50]
const SOPRO := 10

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 6.0, 13.0)
	camera_olhar = Vector3(0, 2.4, 0.0)
	SECAO.montar(self)
	var madeira := Kit.material(Color("#8a5a33"), 0.0, 0.85)
	var ferro := Kit.material(Color("#4a4e5e"), 0.0, 0.5)
	Kit.caixa(self, Vector3(20.0, 0.3, 0.3), Vector3(0, Y_PIVO + 0.1, Z_PENDULO), madeira)
	for x in [-10.5, 10.5]:
		Kit.peca(self, "column", Vector3(x, 0, Z_PENDULO))
	for p in jogadores:
		var l: int = p.lugar
		var pivo := Node3D.new()
		pivo.position = Vector3(RAIAS[l], Y_PIVO, Z_PENDULO)
		add_child(pivo)
		for k in 7:
			Kit.caixa(pivo, Vector3(0.08, 0.55, 0.08), Vector3(0, -0.3 - 0.6 * k, 0), ferro)
		var disco := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.7
		c.bottom_radius = 0.7
		c.height = 0.15
		c.radial_segments = 8
		disco.mesh = c
		disco.position = Vector3(0, -CORDA, 0)
		disco.material_override = Kit.material(Color("#5b6275"), 0.0, 0.6)
		pivo.add_child(disco)
		var brilho := OmniLight3D.new()
		brilho.light_color = Color("#b9b0ff")
		brilho.light_energy = 0.0
		brilho.omni_range = 3.0
		brilho.position = Vector3(RAIAS[l], 2.2, 4.2)
		add_child(brilho)
		maos_livres(p)
		p.preso = true
		p.rotation.y = PI
		j[l] = {"n": 0, "b": -1.0, "pedido": 0, "aberta": false, "antes": false, "pico": 0.0, "perigo": 0,
			"quedas": 0, "fantasma": false, "caiu_b": -1.0, "trava_b": -99.0, "vento_ate": -1.0, "rangeu": -1,
			"rol_antes": 0.0, "t_antes": 0.0, "fora": false, "pivo": pivo, "brilho": brilho,
			"robo_n": -1, "robo_mira": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
		_mostrar(l)


## O ângulo do pêndulo do lugar agora (a batida manda; o tranco segura meio tempo).
func _fi(l: int) -> float:
	var b := Ritmo.batida()
	var e: Dictionary = j[l]
	if b - float(e.trava_b) < 0.5:
		b = float(e.trava_b)
	if no_pico():
		return AMPLITUDE_PICO * cos(PI * (b - 0.25 * l))
	return AMPLITUDE * cos(PI * (b - 0.5 * l) / 2.0)


## O próximo ápice do lugar depois de `desde`, e para que lado ele vira.
func _proxima(l: int, desde: float) -> void:
	var e: Dictionary = j[l]
	var passo := 1.0 if no_pico() else 2.0
	var desloc := 0.25 * l if no_pico() else 0.5 * l
	var k := floorf((desde - desloc) / passo) + 1.0
	if Ritmo.simples[l] and int(k) % 2 == 1:
		k += 1.0
	var s := maxf(k * passo + desloc, BATIDA_DA_PRIMEIRA_NOTA + desloc)
	var m := int(round((s - desloc) / passo))
	e.b = s
	e.pedido = -1 if m % 2 == 0 else 1  # no alto à direita (m par), vire para a esquerda
	e.aberta = false
	e.antes = false
	e.pico = 0.0
	nova_nota(l, int(e.n), Ritmo.t_da_batida(s))


func iniciar_jogo() -> void:
	for l in presentes():
		SECAO.anotar_troca(self, l)  # sem giroscópio ou acelerômetro: a linha `troca` (H08)
		_proxima(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


## A velocidade de rolagem para a direita, em rad/s (sem giroscópio: pela inclinação).
func _virando(l: int) -> float:
	if Forja.capacidade(l, "giro"):
		return -Forja.giro(l).z
	var e: Dictionary = j[l]
	var agora := Ritmo.t_musica()
	var rol := SECAO.rolagem(l)
	var v := (rol - float(e.rol_antes)) / maxf(agora - float(e.t_antes), 0.001)
	e.rol_antes = rol
	e.t_antes = agora
	return v


func jogar(_dt: float) -> void:
	var agora := Ritmo.t_musica()
	var vivos := 0
	for l in presentes():
		var e: Dictionary = j[l]
		_mostrar(l)
		if not bool(e.fantasma):
			vivos += 1
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			_proxima(l, Ritmo.batida())
		if float(e.caiu_b) >= 0.0:
			if Ritmo.batida() >= float(e.caiu_b) + FORA and not bool(e.fantasma):
				_voltar(l)
			if not bool(e.fantasma):
				continue
		_nota(l, e, agora)
	if presentes().size() >= 2 and vivos <= 1:
		for l in presentes():
			acabou[l] = true


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var meio_tempo := 0.5 * 60.0 / Ritmo.bpm
	var velocidade := _virando(l)
	var limiar := VIRADA_COM_VENTO if Ritmo.batida() < float(e.vento_ate) else VIRADA
	var sim := velocidade * float(e.pedido) >= limiar
	if agora < alvo - meio_tempo:
		e.antes = sim
		if int(e.rangeu) != int(e.n) and agora >= alvo - 2.0 * meio_tempo and int(e.perigo) >= 1 and not bool(e.fantasma):
			e.rangeu = int(e.n)
			Forja.som_falante(l, "material:metal", 0.6)
		return
	e.pico = maxf(float(e.pico), absf(velocidade))
	var cruzou := sim and (not bool(e.antes) or not bool(e.aberta))
	e.aberta = true
	e.antes = sim
	if cruzou:
		anotar("entrada", l, {"o": "giro", "pedido": int(e.pedido), "pico": snappedf(float(e.pico), 0.1),
			"limiar": limiar, "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n), true)
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	if bool(e.fantasma):
		if julgamento >= Ritmo.OTIMO:
			_soprar(l)
		_proxima(l, float(e.b))
		return
	marcar(l, PONTOS[julgamento])
	if julgamento >= Ritmo.OTIMO and not treinando:
		_perigo(l, int(e.perigo) - 1)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "clique", 0.4)
	_proxima(l, float(e.b))


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	if bool(e.fantasma):
		_proxima(l, float(e.b))
		return
	e.trava_b = Ritmo.batida()
	Efeitos.faiscas(self, (e.pivo as Node3D).global_position, Tema.AMARELO, 16, 0.6)
	if not treinando:
		_perigo(l, int(e.perigo) + 1)
	if int(e.perigo) >= ARREMESSA:
		_arremessar(l)
	_proxima(l, float(e.b))


func _perigo(l: int, novo: int) -> void:
	var e: Dictionary = j[l]
	e.perigo = clampi(novo, 0, ARREMESSA)
	if int(e.perigo) == 1:
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, 6)
	else:
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _arremessar(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = Ritmo.batida()
	e.quedas = int(e.quedas) + 1
	_perigo(l, 0)
	Forja.sentir(l, "golpe")
	var p := jogador(l)
	if p:
		p.gesto("fall", 1.3)
		Som.tocar("falha", p.global_position, -4.0)
	if int(e.quedas) >= VIDAS:
		e.fantasma = true
		Forja.sentir(l, "explosao")
		(e.brilho as OmniLight3D).light_energy = 0.6
		if presentes().size() == 1:
			acabou[l] = true  # sozinho, virar fantasma acaba o minigame


func _voltar(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = -1.0
	var p := jogador(l)
	if p:
		p.gesto("jump", 0.5)
	_proxima(l, Ritmo.batida())


## O fantasma sopra vento no líder: o vivo com menos quedas (empate: mais pontos).
func _soprar(l: int) -> void:
	var lider := -1
	for o in presentes():
		if o == l or bool(j[o].fantasma) or not conectado(o):
			continue
		if lider < 0 or int(j[o].quedas) < int(j[lider].quedas) or \
				(int(j[o].quedas) == int(j[lider].quedas) and int(pontos[o]) > int(pontos[lider])):
			lider = o
	if lider < 0:
		return
	marcar(l, SOPRO)
	j[lider].vento_ate = Ritmo.batida() + VENTO
	Forja.sentir(lider, "aviso", int(30000.0 / Ritmo.bpm))
	var disco := (j[lider].pivo as Node3D).global_position + Vector3(0, -CORDA, 0)
	Efeitos.faiscas(self, disco, Color("#b9b0ff"), 24, 0.8)
	Som.tocar("vento", disco, -8.0)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var fi := _fi(l) if fase == "jogo" else 0.0
	var pivo: Node3D = e.pivo
	pivo.rotation.z = fi
	var p := jogador(l)
	if p == null:
		return
	if bool(e.fantasma) and (float(e.caiu_b) < 0.0 or Ritmo.batida() - float(e.caiu_b) >= 2.0):
		p.position = Vector3(RAIAS[l], 0.1, 4.2)
		if p.modelo:
			p.modelo.rotation.z = 0.0
		p.animar("idle")
		return
	var no_disco := pivo.global_position + Vector3(CORDA * sin(fi), -CORDA * cos(fi) + 0.1, 0)
	if float(e.caiu_b) >= 0.0:
		var s := clampf((Ritmo.batida() - float(e.caiu_b)) / 2.0, 0.0, 1.0)
		var lava := Vector3(no_disco.x, -1.6, 2.4)
		p.position = no_disco.lerp(lava, s) + Vector3(0, sin(s * PI) * 1.5, 0)
	else:
		p.position = no_disco
	if p.modelo:
		p.modelo.rotation.z = fi * 0.5
	p.animar("idle")


func ao_terminar() -> void:
	for p in jogadores:
		if p.modelo:
			p.modelo.rotation.z = 0.0


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if bool(j[a].fantasma) != bool(j[b].fantasma):
		return not bool(j[a].fantasma)
	if int(j[a].quedas) != int(j[b].quedas):
		return int(j[a].quedas) < int(j[b].quedas)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Quedas: %d de %d" % [int(j[lugar].quedas), VIDAS]
	return super(lugar)
```

## O que o registro mede

- O kit: `nota` por ápice e `toque` (o atraso entre o alto do arco e o golpe).
- A linha `entrada` em cada virada: o lado pedido, **o pico da velocidade**
  de giro na janela (rad/s) e o limiar que valia (2,5 ou 3,5 com vento); no
  começo, quais sensores o controle tem. Cruzado: um giroscópio que nunca
  passa de 3 rad/s, ou que dá picos só num sentido, aparece aqui.

## Armadilhas

- **Velocidade, não ângulo:** a condição é `-Forja.giro(l).z` (para a
  direita positivo) contra o `pedido`; a postura não entra.
- **O robô volta devagar** (no máximo 1,5 rad/s): voltar rápido seria uma
  virada para o outro lado, e no pico a janela seguinte já está aberta.
- **O fantasma continua com notas** (o `toque` dele sopra); ele não pontua
  pelo julgamento, só pelo sopro, e não tem perigo nem queda.
- **O salto do pêndulo** na entrada e na saída do pico (a fórmula muda):
  o tranco das faíscas no pivô disfarça; não tente emendar a fase.
- **O fim por último em pé** só com dois ou mais presentes; sozinho, quem
  acaba o minigame é o `_arremessar` (a terceira queda) ou os 90 s.

## Pronto quando

Os pêndulos jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o ruim vira fantasma e sopra vento); o cabo que cai
e volta não derruba ninguém; o último em pé fecha o minigame; o fim tem
sempre vencedor; `bash tests/prova_do_jogo.sh` passa; e
`bash tests/prova_visual.sh` passa com a prancha **olhada**.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S02_J07 (J2): os pêndulos abrem pelo catálogo; a virada do robô chega pelo
## giroscópio simulado de cada um; o fim tem vencedor.
func _prova_dos_pendulos() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S02_J07", 130.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[2]) + int(c[3]) >= 1, "S02_J07 P%d: virou no alto %s" % [l + 1, c])
	_esperar(mg.vencedor().size() == 4, "S02_J07: a colocação tem os quatro")
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S02_J07: de volta ao salão")
```

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**O André (local):** `./run-local.sh -- --sala=S02_J07`: o golpe de pulso no
alto é natural, a onda dos quatro pêndulos se vê e se ouve, o arremesso faz
rir, o fantasma quer soprar, e o bolero do meio aperta.

## Ao terminar

- Catálogo: `"S02_J07": preload("res://scripts/minigames/s02/pendulos_do_caos.gd")`
  em `MINIGAMES` e na lista da S02.
- `traducoes.gd`: `"Pêndulos do Caos": "Pendulums of Chaos"`, `"Vire no alto!": "Flip at the top!"`,
  `"Vire!": "Flip!"`; em `EN_PADROES`, `["^Quedas: (\\d+) de (\\d+)$", "Falls: $1 of $2"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a J2 **feito**, com o commit.
- Commit (sem trailer): `feat: os Pêndulos do Caos — virar num golpe no alto do arco`
