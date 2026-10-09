# J2 — Pêndulos do Caos

**Sprint:** J · **Slot:** S02_J07 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, G05, G14, J1 (o `secao.gd`)

## Por quê

Virar no alto é um golpe de pulso: o controle gira rápido para o centro no
instante em que o pêndulo chega ao topo do arco. Conta a velocidade do giro,
no tempo, e o giroscópio é medido pelo pico; o arremesso do pêndulo travado
é o melhor tombo da seção.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o exemplo da FICHA dele é este minigame)
- [As decisões comuns dos minigames, no 13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08) (a fila de notas, `anotar`, `andamento`, `tempo_que_resta`)
- [J1 — O secao.gd](J1-a-viga.md#o-secaogd) (a caverna, `agendar`, `vento`, `momento`, `gancho`, `levantar`)

## Arquivos que mudam

| arquivo | o que muda | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s02/pendulos_do_caos.gd` | **novo**: o minigame | não |
| `godot/scripts/minigames/catalogo.gd` | o slot `S02_J07` | sim: as cinco |
| `godot/scripts/traducoes.gd` | o título, o verbo, o microjogo e o status | sim: as cinco |
| `godot/testes/prova_do_jogo.gd` | `_prova_dos_pendulos()` e a linha no `_prova_da_ficha` | sim: as cinco |
| `godot/testes/captura_jogo.gd` | os momentos de `"S02_J07"` | sim: as cinco |

O `secao.gd`, `"momento"` em `TIPOS_DO_JOGO`, a linha `momento` no 13 e o
`_linhas_do_minigame()` e o `_notas_por_terco()` da prova são da J1: esta
ficha só os usa.

### O estado de hoje

Não existe `pendulos_do_caos.gd`. A ficha anterior trazia o código com
`Tema.AMARELO` nas faíscas, `#8a5a33`, `#4a4e5e`, `#5b6275` e `#b9b0ff`
soltos, o rangido pelo alto-falante, o aviso do vento pela vibração e a
câmera a 13 m (os discos das pontas saíam do quadro). Esta ficha troca tudo
isso pelos tokens do Tema e pelo `secao.gd`, e acrescenta o arremesso como
momento, a mancha de lava, as vidas na trave e a reta.

### Ao terminar

1. `godot/scripts/minigames/catalogo.gd`: em `MINIGAMES`,
   `"S02_J07": preload("res://scripts/minigames/s02/pendulos_do_caos.gd")`;
   na lista `minigames` da S02, `"S02_J07"` logo depois de `"S02_J06"`.
2. `godot/scripts/traducoes.gd`: `"Pêndulos do Caos": "Pendulums of Chaos"`,
   `"Vire no alto!": "Flip at the top!"`, `"Vire!": "Flip!"`; em
   `EN_PADROES`, `["^Quedas: (\\d+) de (\\d+)$", "Falls: $1 of $2"]`.
3. `godot/testes/prova_do_jogo.gd` e `godot/testes/captura_jogo.gd`: o que
   está em **Provas**.
4. `"$GODOT" --headless --path godot --import --quit`; o
   `pendulos_do_caos.gd.uid` entra no commit.
5. O quadro sai do cabeçalho desta ficha: nada a editar nele.
6. Commit (sem trailer): `feat(pendulos): os Pêndulos do Caos, a virada no alto do arco, o arremesso e o vento dos fantasmas`.

## Como se joga

- **A faixa:** `MUS_S02_J07`. Até a H05, a sintetizada da seção a 96 BPM;
  com a gerada, `mus_s02_j07` a 130 BPM (o bolero que cresce em camadas).
- **O pêndulo:** cada um de pé no disco do seu pêndulo, que balança pela
  batida: `φ = A · cos(π · (batida − 0,5·l) / 2)`. O alto do arco (o ápice)
  cai em `2m + 0,5·l`: à direita com `m` par, à esquerda com `m` ímpar. É o
  hoqueto em colcheias: os quatro pêndulos em onda.
- **A nota é o ápice:** no alto à direita, vire para a esquerda (para o
  centro); no alto à esquerda, para a direita. O toque é o quadro em que a
  velocidade de rolagem passa de **2,5 rad/s** para o lado pedido
  (`-Forja.giro(l).z` é a velocidade para a direita), dentro da janela que
  abre meio tempo antes. Nada até `FOLGA_PERDIDA` (0,140 s) depois: nota
  perdida. A nota é perigo físico: `julgar_toque(l, alvo, n, true)`.
- **O perigo:** o erro soma 1; PERFEITO e ÓTIMO tiram 1; BOM não mexe. **No
  1, o pêndulo trava meio tempo** (faíscas no pivô). **No 2, trava e
  arremessa o cavaleiro:** o lançamento sai na colcheia seguinte, ele voa 2
  tempos num arco de 2,5 m de altura até a lava, girando uma volta, e volta
  ao disco 8 tempos depois do lançamento (5 tempos fixos mais 3 tempos ×
  `levantar`), com o perigo zerado. A mancha de lava fica no disco vazio até
  ele voltar.
- **A terceira queda o faz fantasma:** ele fica na plataforma da frente
  (`z = 4,2`), com a luz `VIOLETA` em cima, e continua virando no tempo do
  pêndulo dele (vazio). Cada ÓTIMO ou PERFEITO do fantasma **sopra vento**
  no líder (o vivo com menos quedas; empate, mais pontos; nunca ele mesmo):
  por 4 tempos × o `tranco` do fantasma, o líder precisa virar com **3,5
  rad/s**. O vento não muda janela nenhuma.
- **Os pontos** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`; o fantasma
  ganha 10 por sopro (o desempate entre fantasmas).

### A curva

Os terços de 90 s: 30 s e 60 s (`andamento()` 1/3 e 2/3).

| trecho | o balanço | o mundo |
| --- | --- | --- |
| 0 a 30 s | 4 tempos, `A = 0,6 rad`; um ápice a cada 2 tempos por lugar | o tique do ápice na primeira frase (batidas 4 a 19) |
| 30 a 60 s, o bolero cresce | 2 tempos, `φ = 0,75 · cos(π · (batida − 0,25·l))`; um ápice por tempo, em `k + 0,25·l` | a lava sobe de 0,6 a 1,0 em 2 batidas; a câmera recua 10 % em 2 batidas |
| 60 s ao fim, a reta | 4 tempos, `A = 0,75` (o arco do pico fica grande) | — |
| as últimas 16 batidas | igual à reta | o sopro de cada fantasma vai em todos os vivos, não só no líder; a linha `momento` `reta` |

`Ritmo.simples[l]`: o pêndulo balança igual, mas só um ápice a cada dois é
nota. A troca de fórmula na entrada e na saída do pico dá um salto no
ângulo: o tranco das faíscas no pivô (12, `GRAFITE`) cobre os dois
instantes.

### A ficha de dados

```gdscript arquivo=godot/scripts/minigames/s02/pendulos_do_caos.gd parte=2
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
	"sensacoes": ["acerto", "perfeito", "erro", "golpe_dir", "golpe_esq", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Vire!", "segundos": 6.0},
}
```

### O fim e o vencedor

`"fim": "ultimo_em_pe"`: com dois ou mais presentes, quando sobra um vivo
(ou nenhum), todos acabam; senão, os 90 s. `vencedor()`: os vivos antes dos
fantasmas; depois menos quedas; depois pontos; depois o lugar.

### Com menos de quatro

Com dois ou três, igual. Sozinho: joga os 90 s, ou até virar fantasma (a
terceira queda acaba o minigame dele). **O controle que cai:** o pêndulo
balança vazio de nota (não há erro), e o vento não o escolhe; ao voltar, a
nota é o próximo ápice dele. **Sem giroscópio:** a velocidade vem da
diferença da rolagem pela gravidade entre dois quadros; sem nada, do
analógico esquerdo (`SECAO.rolagem`); a linha `troca` diz qual.

### Os ganchos

`godot/scripts/minigames/s02/pendulos_do_caos.gd`:

```gdscript arquivo=godot/scripts/minigames/s02/pendulos_do_caos.gd
extends Minigame
## Pêndulos do Caos (S02_J07). Cada um no disco do seu pêndulo, que balança
## pela batida (os quatro em onda, o hoqueto em colcheias). No alto do arco,
## virar o controle num golpe para o centro inverte o balanço. Dois erros
## seguidos: o pêndulo trava e arremessa; três quedas: fantasma, que sopra
## vento no líder. No meio, o bolero cresce: um ápice por tempo.
##
## A falha: o pêndulo trava; no segundo erro, arremessa o cavaleiro na lava.
## O vencedor: o último em pé; senão, quem caiu menos.
## O alto-falante do dono: o clique no acerto, a nota no perfeito (o kit).
## O registro mede: o pico da velocidade de giro em cada virada, pedida e
## feita (a linha `entrada`), o atraso (o kit), o arremesso e a reta (a
## linha `momento`), o vento (a linha `pista`).
## O robô: um golpe de 4,5 rad/s no ápice (ou 200 ms atrasado); volta devagar.
## Com menos de quatro: sozinho, joga até o tempo ou até virar fantasma.
## A régua: "Vire no alto!" e o giroscópio bastam; sem a tela, o ápice bate
## no lado certo da mão na primeira frase e o metal range no perigo; nada
## pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s02/secao.gd")

# (a FICHA vem aqui)

const AMPLITUDE := 0.6
const AMPLITUDE_PICO := 0.75
const CORDA := 4.2
const Y_PIVO := 5.3
const Z_PENDULO := 0.8
const Z_FANTASMA := 4.2
const VIRADA := 2.5  ## rad/s
const VIRADA_COM_VENTO := 3.5
const VENTO := 4.0  ## tempos
const ARREMESSA := 2  ## perigo
const VIDAS := 3
const VOO := 2.5  ## m: a altura do arco do arremesso
const VOO_TEMPOS := 2.0
const FORA_FIXO := 5.0  ## tempos; mais 3 × levantar = 8 no neutro
const QUEDA := 3.0  ## tempos: a parte da volta que o Fôlego encurta
const PONTOS := [0, 20, 35, 50]
const SOPRO := 10
const CAMERA := Vector3(0, 7.0, 18.0)
const OLHAR := Vector3(0, 2.2, 0.8)

var j := {}
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var _no_pico := false
var _reta := false


func montar() -> void:
	SECAO.limpar()
	camera_pos = CAMERA
	camera_olhar = OLHAR
	SECAO.montar(self)
	var madeira := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)
	var ferro := Kit.material(Tema.GRAFITE, 0.0, 0.5)
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
		c.radial_segments = 8  # octogonal: nada liso
		disco.mesh = c
		disco.position = Vector3(0, -CORDA, 0)
		disco.material_override = ferro
		pivo.add_child(disco)
		# a mancha de lava no disco vazio (o rastro do arremesso)
		var mancha := Kit.cilindro(pivo, 0.4, 0.02, Vector3(0.12, -CORDA + 0.09, 0.05), Kit.material(Tema.TUNGSTENIO, 0.8, 0.6))
		mancha.visible = false
		# as vidas na trave: três caixas na cor do dono; cada queda apaga uma
		var vidas := []
		for v in VIDAS:
			vidas.append(Kit.caixa(self, Vector3(0.2, 0.2, 0.2), Vector3(RAIAS[l] - 0.3 + 0.3 * v, Y_PIVO + 0.4, Z_PENDULO), Kit.material(Tema.JOGADOR[l], 1.0, 0.5)))
		var fantasma := OmniLight3D.new()  # a luz do fantasma, acesa na terceira queda
		fantasma.light_color = Tema.VIOLETA
		fantasma.light_energy = 0.0
		fantasma.omni_range = 3.0
		fantasma.position = Vector3(RAIAS[l], 2.2, Z_FANTASMA)
		add_child(fantasma)
		maos_livres(p)
		p.preso = true
		p.rotation.y = PI
		j[l] = {"n": 0, "b": -1.0, "pedido": 0, "aberta": false, "antes": false, "pico": 0.0, "perigo": 0,
			"quedas": 0, "fantasma": false, "caiu_b": -1.0, "lancou_t": -1.0, "trava_b": -99.0,
			"vento_ate": -1.0, "rangeu": -1, "tiquei": -1, "rol_antes": 0.0, "t_antes": 0.0, "fora": false,
			"pivo": pivo, "mancha": mancha, "vidas": vidas, "luz_fantasma": fantasma,
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
	var a := AMPLITUDE if andamento() < 1.0 / 3.0 else AMPLITUDE_PICO
	return a * cos(PI * (b - 0.5 * l) / 2.0)


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
		SECAO.anotar_troca(self, l)
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


func _ultimas_16() -> bool:
	return tempo_que_resta() <= 16.0 * 60.0 / Ritmo.bpm


func jogar(_dt: float) -> void:
	SECAO.pulsos()
	var agora := Ritmo.t_musica()
	var pico := SECAO.pico_suave(self)
	camera_pos = OLHAR + (CAMERA - OLHAR) * (1.0 + 0.1 * pico)
	SECAO.lava(self, 0.6 + 0.4 * pico)
	if no_pico() != _no_pico:
		_no_pico = no_pico()
		for l in presentes():  # o salto da fórmula: o tranco no pivô
			Efeitos.faiscas(self, (j[l].pivo as Node3D).global_position, Tema.GRAFITE, 12, 0.5)
	if not _reta and _ultimas_16():
		_reta = true
		SECAO.momento(self, "reta", -1, Vector3(0, Y_PIVO - CORDA, Z_PENDULO), 1.6,
			{"ordem": vencedor(), "objeto": "vidas_na_trave"})
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
			var volta := float(e.caiu_b) + FORA_FIXO + SECAO.levantar(l, QUEDA)
			if Ritmo.batida() >= volta and not bool(e.fantasma):
				_voltar(l)
			if not bool(e.fantasma):
				continue
		_nota(l, e, agora)
	if presentes().size() >= 2 and vivos <= 1:
		for l in presentes():
			acabou[l] = true


func _nota(l: int, e: Dictionary, agora: float) -> void:
	var alvo := Ritmo.t_da_batida(float(e.b))
	var tempo := 60.0 / Ritmo.bpm
	var meio_tempo := 0.5 * tempo
	var velocidade := _virando(l)
	var limiar := VIRADA_COM_VENTO if Ritmo.batida() < float(e.vento_ate) else VIRADA
	var sim := velocidade * float(e.pedido) >= limiar
	if agora < alvo - meio_tempo:
		e.antes = sim
		var aviso := alvo - tempo - SECAO.pista_s(l)
		# o tique do ápice, no lado do alto do arco, só na primeira frase
		if int(e.tiquei) != int(e.n) and agora >= aviso and float(e.b) < BATIDA_DA_PRIMEIRA_NOTA + 16.0 and not bool(e.fantasma):
			e.tiquei = int(e.n)
			var lado_alto := -int(e.pedido)  # vira para a esquerda: o alto é à direita
			Forja.som_haptica(l, "clique" if lado_alto < 0 else "", "clique" if lado_alto > 0 else "", 0.4)
			anotar("pista", l, {"canal": "haptica", "o": "apice", "lado": lado_alto})
		# o metal range com o pêndulo pesado
		if int(e.rangeu) != int(e.n) and agora >= aviso + meio_tempo and int(e.perigo) >= 1 and not bool(e.fantasma):
			e.rangeu = int(e.n)
			Forja.textura(l, "metal", 0.6)
			anotar("pista", l, {"canal": "haptica", "o": "rangido", "perigo": int(e.perigo)})
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
	Efeitos.faiscas(self, (e.pivo as Node3D).global_position, Tema.JOGADOR[l], 16, 0.6)
	SECAO.parar([e.pivo], 2)
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


## O segundo erro: o lançamento sai na colcheia seguinte (o momento cai no tempo).
func _arremessar(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = ceilf(Ritmo.batida() * 2.0) / 2.0
	e.quedas = int(e.quedas) + 1
	_perigo(l, 0)
	SECAO.agendar(Ritmo.t_da_batida(float(e.caiu_b)), _lanca.bind(l))
	SECAO.agendar(Ritmo.t_da_batida(float(e.caiu_b) + VOO_TEMPOS), _na_lava.bind(l))


## O grito: o pêndulo lança, o boneco voa, a mancha fica no disco.
func _lanca(l: int) -> void:
	var e: Dictionary = j[l]
	e.lancou_t = Ritmo.t_musica()
	var p := jogador(l)
	(e.mancha as Node3D).visible = true
	var vidas: Array = e.vidas
	var apaga := VIDAS - int(e.quedas)
	if apaga >= 0 and apaga < vidas.size():
		(vidas[apaga] as MeshInstance3D).material_override = Kit.material(Tema.GRAFITE, 0.0, 0.5)
	Forja.sentir(l, "golpe_dir", 60)  # o fraco 1,0 por 60 ms: o tranco da corrente
	tremer(Sala.TREMOR_EXPLOSAO)
	if p:
		p.gesto("fall", VOO_TEMPOS * 60.0 / Ritmo.bpm)
		Som.tocar("falha", p.global_position, -4.0)
		SECAO.parar([p, e.pivo], 3)
	SECAO.momento(self, "arremesso", l, _pouso(l), VOO * SECAO.gancho(l, "empurrao"),
		{"queda": int(e.quedas), "fantasma": int(e.quedas) >= VIDAS})
	if int(e.quedas) >= VIDAS:
		e.fantasma = true
		if presentes().size() == 1:
			acabou[l] = true  # sozinho, virar fantasma acaba o minigame


## O pouso na lava, 2 tempos depois: o forte 1,0 por 120 ms e o respingo.
func _na_lava(l: int) -> void:
	var e: Dictionary = j[l]
	Forja.sentir(l, "golpe_esq", 120)
	Efeitos.faiscas(self, _pouso(l), Tema.TUNGSTENIO, 30, 0.9)
	if bool(e.fantasma):
		(e.luz_fantasma as OmniLight3D).light_energy = 1.2


## Onde o arremessado cai: na lava, para o centro e para a frente (no quadro).
func _pouso(l: int) -> Vector3:
	return Vector3(RAIAS[l] * 0.6, -1.45, 2.4)


func _voltar(l: int) -> void:
	var e: Dictionary = j[l]
	e.caiu_b = -1.0
	e.lancou_t = -1.0
	(e.mancha as Node3D).visible = false
	var p := jogador(l)
	if p:
		p.gesto("jump", 0.5)
		Efeitos.anel(self, (e.pivo as Node3D).global_position + Vector3(0, -CORDA + 1.0, 0), Tema.JOGADOR[l], 0.6)
	_proxima(l, Ritmo.batida())


## O fantasma sopra vento no líder (nas últimas 16 batidas, em todos os vivos).
func _soprar(l: int) -> void:
	var alvos := []
	var lider := -1
	for o in presentes():
		if o == l or bool(j[o].fantasma) or not conectado(o) or float(j[o].caiu_b) >= 0.0:
			continue
		alvos.append(o)
		if lider < 0 or int(j[o].quedas) < int(j[lider].quedas) or \
				(int(j[o].quedas) == int(j[lider].quedas) and int(pontos[o]) > int(pontos[lider])):
			lider = o
	if lider < 0:
		return
	if not _ultimas_16():
		alvos = [lider]
	marcar(l, SOPRO)
	var dura := maxf(0.25, roundf(VENTO * SECAO.gancho(l, "tranco") * 4.0) / 4.0)
	var de := Vector3(RAIAS[l], 1.2, Z_FANTASMA)
	for o in alvos:
		j[o].vento_ate = Ritmo.batida() + dura
		var disco := (j[o].pivo as Node3D).global_position + Vector3(0, -CORDA, 0)
		SECAO.vento(o, 0.5, RAIAS[l] < RAIAS[o])
		anotar("pista", o, {"canal": "haptica", "o": "vento", "de": l, "tempos": dura, "alvos": alvos.size()})
		# o fio lilás de ponta a ponta: 5 sopros de faísca em 400 ms
		for i in 5:
			var ponto := de.lerp(disco, i / 4.0)
			SECAO.agendar(Ritmo.t_musica() + 0.1 * i, func() -> void: Efeitos.faiscas(self, ponto, Tema.VIOLETA, 6, 0.4))
		Som.tocar("vento", disco, -8.0)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var fi := _fi(l) if fase == "jogo" else 0.0
	var pivo: Node3D = e.pivo
	var p := jogador(l)
	if pivo.process_mode != Node.PROCESS_MODE_DISABLED:
		pivo.rotation.z = fi
	if p == null or p.process_mode == Node.PROCESS_MODE_DISABLED:
		return  # o hit-stop congela o boneco também
	var no_disco := pivo.global_position + Vector3(CORDA * sin(fi), -CORDA * cos(fi) + 0.1, 0)
	var s := 0.0
	if float(e.caiu_b) >= 0.0:
		s = clampf((Ritmo.batida() - float(e.caiu_b)) / VOO_TEMPOS, 0.0, 1.0)
	if bool(e.fantasma) and s >= 1.0:
		p.position = Vector3(RAIAS[l], 0.1, Z_FANTASMA)
		if p.modelo:
			p.modelo.rotation = Vector3.ZERO
		p.animar("idle")
		return
	if float(e.caiu_b) >= 0.0:
		var alto := VOO * SECAO.gancho(l, "empurrao")
		p.position = no_disco.lerp(_pouso(l), s) + Vector3(0, sin(s * PI) * alto, 0)
		if p.modelo:
			p.modelo.rotation.x = TAU * s  # uma volta no ar
		return
	p.position = no_disco
	if p.modelo:
		p.modelo.rotation = Vector3(0, 0, fi * 0.5)
	p.animar("idle")


## Quem caiu e ainda não voltou, e o fantasma, estão fora da rodada (arte/09).
func fora_da_rodada(l: int) -> bool:
	return j.has(l) and (float(j[l].caiu_b) >= 0.0 or bool(j[l].fantasma))


func ao_terminar() -> void:
	for p in jogadores:
		if p.modelo:
			p.modelo.rotation = Vector3.ZERO


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

### O robô

```gdscript arquivo=godot/scripts/minigames/s02/pendulos_do_caos.gd parte=3
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	# volta devagar ao nível (abaixo da velocidade que conta como virada)
	var giro := SECAO.giro_para(l, 0.0, 0.0)
	giro.z = clampf(giro.z, -1.5, 1.5)
	if (float(e.caiu_b) < 0.0 or bool(e.fantasma)) and float(e.b) >= 0.0:
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

O robô `bom` passa de 3,5 rad/s: o vento não o derruba. O `--robo` da
prova é o `bom` nos quatro (a F09 não tem robô por lugar), e o `bom` quase
nunca junta dois erros: a prova faz o P4 de `ruim` (o `robo_mira` de 0,20 s
em 2 de cada 3 notas, `robo_n % 3 != 0`). Ele junta dois erros, voa três
vezes e vira fantasma antes dos 60 s.

### O registro

- O kit: `nota` por ápice e `toque` (o atraso entre o alto do arco e o
  golpe).
- `entrada`: `sensores` no começo; em cada virada, `o` `giro`, `pedido`,
  `pico` (a velocidade máxima na janela, rad/s), `limiar` (2,5 ou 3,5 com
  vento), `n`. Um giroscópio que nunca passa de 3 rad/s, ou que dá picos só
  num sentido, aparece aqui.
- `pista`: `haptica` `apice` (com o `lado`), `rangido` e `vento` (`de`,
  `tempos`, `alvos`: quantos vivos o sopro pegou).
- `momento`: `arremesso` (`lugar`, `queda`, `fantasma`) e `reta` (`ordem`,
  `objeto` `vidas_na_trave`).

### Armadilhas

- **Velocidade, não ângulo:** a condição é `-Forja.giro(l).z` (para a
  direita positivo) contra o `pedido`; a postura não entra.
- **O robô volta devagar** (no máximo 1,5 rad/s): voltar rápido seria uma
  virada para o outro lado, e no pico a janela seguinte já está aberta.
- **O fantasma continua com notas** (o `toque` dele sopra); ele não pontua
  pelo julgamento, só pelo sopro, e não tem perigo nem queda.
- **O arremesso espera a colcheia:** `caiu_b` é a colcheia seguinte; até
  ela, o boneco fica no disco (`s` = 0). A linha `momento` e o `golpe_dir`
  saem no mesmo quadro (`_lanca`, pela fila do `secao.gd`).
- **A vibração cala a háptica:** enquanto `sentir` vibra, `som_haptica` do
  lugar devolve −1 (F05). O vento e o tique tocam fora das vibrações; a
  prova não conta o vento pelo `som_virtual`, conta a linha `pista`.
- **O fim por último em pé** só com dois ou mais presentes; sozinho, quem
  acaba o minigame é o `_lanca` (a terceira queda) ou os 90 s.

## A cena

### O secao.gd

O da [J1](J1-a-viga.md#o-secaogd), sem mudança: `SECAO.montar` (a caverna
cobalto), `lava`, `pico_suave`, `agendar`, `pulsos`, `parar`, `vento`,
`momento`, `gancho`, `levantar`, `pista_s`.

### Por lugar

| o quê | peça | onde (m) | cor |
| --- | --- | --- | --- |
| a trave | `Kit.caixa(20; 0,3; 0,3)` e duas `column` do Mini Dungeon | `(0; 5,4; 0,8)`; as `column` em x ±10,5 | `OXIDO_BRILHO` (a madeira) |
| as vidas | 3 × `Kit.caixa(0,2; 0,2; 0,2)` | `(RAIAS[l] − 0,3 + 0,3·v; 5,7; 0,8)` | `JOGADOR[l]` a 1,0; a apagada, `GRAFITE` |
| a corrente | 7 × `Kit.caixa(0,08; 0,55; 0,08)` | do pivô `(RAIAS[l]; 5,3; 0,8)` para baixo | `GRAFITE` |
| o disco | `CylinderMesh` r 0,7, altura 0,15, 8 lados | 4,2 m abaixo do pivô | `GRAFITE` |
| a mancha | `Kit.cilindro` r 0,4 × 0,02 | no disco, visível do lançamento à volta | `TUNGSTENIO` a 0,8 |
| o cavaleiro | o boneco de costas, `preso`, mãos livres | no disco: `pivô + (4,2·sin φ; −4,2·cos φ + 0,1; 0)`; `modelo.rotation.z = φ · 0,5` | o da montagem |
| o fantasma | o mesmo boneco na plataforma da frente e a `OmniLight3D` 1,2, alcance 3 | `(RAIAS[l]; 0,1; 4,2)`; a luz em y 2,2 | `VIOLETA` (só a luz) |
| o pouso | — | `(RAIAS[l] · 0,6; −1,45; 2,4)` | as 30 faíscas `TUNGSTENIO` |

### A câmera

`"camera": "fixa"`, o plano de arena: 35 mm, 15° de cima, sem corte.
`camera_pos = (0; 7,0; 18,0)`, `camera_olhar = (0; 2,2; 0,8)` (17,9 m: os
discos no alto do arco, x ±8,9, ficam no quadro). O fov é o global de hoje
(40). **No pico**, recua 10 % em 2 batidas e volta em 2
(`SECAO.pico_suave`). O tremor: `tremer(Sala.TREMOR_EXPLOSAO)` no
lançamento.

### A luz e o brilho

A luz é a da seção (`SECAO.montar`: o cobalto até a G15). O que brilha:

| o quê | energia | dono |
| --- | --- | --- |
| as vidas na trave | 1,0 | o lugar, `JOGADOR[l]` |
| as faíscas do tranco no pivô (16) | as de `Efeitos.faiscas` | o lugar |
| a mancha no disco | 0,8 | o mundo, `TUNGSTENIO` |
| a luz do fantasma | 1,2 | o fantasma, `VIOLETA` |
| o fio do vento (5 × 6 faíscas) | as de `Efeitos.faiscas` | o fantasma, `VIOLETA` |
| a lava, as brasas, o néon | os da J1 | o mundo |

## O som

| evento | id do mapa | onde | volume |
| --- | --- | --- | --- |
| a faixa | `mus_s02_j07` (130 BPM); até a H05, a sintetizada a 96 | TV | o da faixa |
| o arremesso | `Som.tocar("falha")` = `fx_tropeco_0..2` | TV, no boneco | −4 dB |
| o sopro do fantasma | `Som.tocar("vento")` = `sint_vento` | TV, no disco do alvo | −8 dB |
| BOM e ÓTIMO | `mod_clique` (`som_falante(l, "clique", 0.4)`) | alto-falante do dono | 0,4 |
| PERFEITO e ERRO | `mod_nota_pN`, `mod_nota_quebrada_pN` (o kit) | alto-falante do dono | o do kit |
| o tique do ápice (primeira frase) | `mod_clique` nos atuadores (`som_haptica(l, "clique", "", 0.4)`) | o atuador do lado do alto | 0,4 |
| o rangido, com o perigo 1 | `mod_material_metal` (`Forja.textura(l, "metal", 0.6)`) | atuadores do dono | 0,6 |
| a textura do acerto | `mod_material_metal` (o kit, `"material": "metal"`) | atuadores do dono | o do kit |

A lava não tem id próprio: o pouso é só faísca e vibração. O mapa não tem J2
no `mod_clique` nos atuadores.

## O controle

| recurso | o evento | para quem | o quê | a prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| giroscópio | cada ápice | o dono | a velocidade de rolagem contra o limiar | o robô (`robo_girar`) e a linha `entrada` com o `pico` |
| vibração | o acerto e o erro | o dono | o kit | o kit (H08) |
| vibração | o lançamento | o arremessado | `sentir(l, "golpe_dir", 60)`: o fraco 1,0 por 60 ms | `percepcao(l).fraco` ≥ 0,95 de +0 a +0,05 s do `lancou_t` |
| vibração | o pouso na lava, 2 tempos depois | o arremessado | `sentir(l, "golpe_esq", 120)`: o forte 1,0 por 120 ms | `percepcao(l).forte` ≥ 0,95 de +2 tempos a +2 tempos + 0,1 s |
| háptica | o sopro do fantasma | o alvo | `SECAO.vento(alvo, 0.5, ...)`: um lado, e 400 ms depois o outro | a linha `pista` `vento` |
| háptica | o ápice, na primeira frase | o dono | `"clique"` a 0,4 no atuador do lado do alto, 1 tempo antes (mais o Faro) | a linha `pista` `apice` |
| háptica | o perigo 1 | o dono | o rangido `textura(l, "metal", 0.6)` meio tempo antes da janela | a linha `pista` `rangido` |
| gatilho R2 | o perigo muda | o dono | perigo 1: `GATILHO_RESISTENCIA` de 0 com força 6; senão `GATILHO_OFF` | `percepcao(l).gatilho_dir == 0x21` com perigo 1 |
| barra de luz | o julgamento | o dono | o kit | o kit |
| alto-falante | o acerto | o dono | `clique` 0,4; a nota do kit | `som_virtual(l).falante` |
| microfone | — | — | Não se aplica: a seção é do corpo | — |

## O cavaleiro

- **A peça aparece inteira e na cor dela.** O minigame não tinge o boneco:
  a cabeça (humana, orc, autômato, golem ou raposa), o superior e o
  inferior vêm da montagem com os tons próprios (G13). A cor do lugar fica
  nas vidas da trave, nas faíscas do tranco e no anel da volta. O fantasma
  é o mesmo boneco sob a luz `VIOLETA`: nada se pinta. As animações (`idle`,
  `fall`, `jump`) e a volta no ar (`modelo.rotation.x`) servem às cinco
  raças.
- **As mãos livres** (`maos_livres(p)`): o pêndulo não usa o item.
- **Os stats** (`SECAO.gancho`; sem a classe `Cavaleiro`, o neutro). Nenhum
  mexe na janela, nos pontos, nos limiares (2,5 e 3,5 rad/s) nem nas 3
  vidas.

| gancho | o que muda aqui | stat 1 | stat 5 |
| --- | --- | --- | --- |
| `empurrao` | a altura do arco do arremesso (2,5 m) | ×1,16 | ×0,84 |
| `tranco` | como fantasma, os tempos do vento que ele sopra (4, à semicolcheia) | ×0,84 | ×1,16 |
| `levantar` | os 3 tempos da volta ao disco que o Fôlego encurta (mais 5 fixos) | 3,75 | 2,25 |
| `pista` | o tique do ápice e o rangido chegam antes | −40 ms | +40 ms |

## As reações

- **`car_em_chamas`** e **`car_por_um_fio`**: os do kit. O `car_acorde` não
  se aplica (não há nota de todos).
- **Os adesivos `rea_*`:** quem voou e ainda não voltou, e o fantasma
  (`fora_da_rodada(l)`).
- Nenhum carimbo próprio deste minigame.

## A diversão

**O grito: o arremesso** (`arremesso`), degrau estrondo. O segundo erro
trava o pêndulo e lança o cavaleiro: ele voa 2 tempos num arco de 2,5 m,
dá uma volta no ar e cai na lava com 30 faíscas; a câmera treme
(`TREMOR_EXPLOSAO`) e o pêndulo para 3 quadros.

- **O rastro:** a mancha de lava no disco vazio até ele voltar (8 tempos);
  a vida apagada na trave até o fim; na terceira queda, o fantasma lilás na
  frente.
- **Confere pelo robô (o da prova: o `bom` nos quatro, o P4 de `ruim`
  pela prova, semente 7):** pelo menos 3 linhas `momento`
  `arremesso` em 90 s, a primeira antes de 30 s; uma linha `momento` `reta`;
  nos `momento` com `x_tela` ≥ 0, 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥
  0,08.
- **Confere pela foto:** `pendulos_arremesso` (1 tempo depois da queda) com
  um disco vazio e a mancha `TUNGSTENIO` nele.

**A curva:** a tabela de **Como se joga**. Pelo robô: as notas por segundo
do 2.º terço ≥ 1,5 × as do 1.º (`_notas_por_terco`). Nas últimas 16
batidas, o sopro do fantasma pega todos os vivos: com o P4 fantasma, 2 ou
mais linhas `pista` `vento` com `alvos` ≥ 2.

**Quem está perdendo:** o fantasma continua jogando, e o sopro dele pesa no
líder; o fio lilás de ponta a ponta mostra de quem veio. Pelo robô: com o
P4 fantasma, pelo menos 1 linha `pista` `vento` com `de` = 3.

**O que se cortou:** nada.

## Pronto quando

Os pêndulos jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o `ruim` vira fantasma e sopra vento); o cabo que
cai e volta não derruba ninguém; o último em pé fecha o minigame; o fim tem
sempre vencedor; `_prova_dos_pendulos()` passa; e a foto
`pendulos_arremesso` mostra a mancha `TUNGSTENIO` num disco vazio.

## Provas

**`godot/testes/prova_do_jogo.gd`**, no `match` de `_prova_da_ficha`:
`"S02_J07": await _prova_dos_pendulos()`.

```gdscript
## Pêndulos do Caos (S02_J07): o arremesso no tempo (o fraco, depois o forte),
## o R2 do perigo, o vento do fantasma e a régua da diversão.
func _prova_dos_pendulos() -> void:
	var visto := {"r2": 0, "fraco": {}, "forte": {}}
	var olhar := func(mg: Minigame) -> void:
		var tempo := 60.0 / Ritmo.bpm
		# o P4 de `ruim` (a F09 não tem robô por lugar): 0,20 s atrasado em 2 de cada 3 notas
		var p4: Dictionary = mg.j.get(3, {})
		if not p4.is_empty() and int(p4.robo_n) >= 0 and int(p4.robo_n) % 3 != 0:
			p4.robo_mira = 0.20
		for l in mg.presentes():
			var e: Dictionary = mg.j[l]
			var per := Forja.percepcao(l)
			if int(e.perigo) == 1 and int(per.get("gatilho_dir", 0)) == 0x21:
				visto.r2 += 1
			var t0 := float(e.lancou_t)
			if t0 >= 0.0:
				var d := Ritmo.t_musica() - t0
				if d >= 0.0 and d <= 0.05 and float(per.get("fraco", 0.0)) >= 0.95:
					visto.fraco[l] = true
				if d >= 2.0 * tempo and d <= 2.0 * tempo + 0.1 and float(per.get("forte", 0.0)) >= 0.95:
					visto.forte[l] = true
	var mg := await _joga_o_minigame("S02_J07", 130.0, olhar)
	if mg == null:
		return
	_esperar(visto.r2 > 0, "S02_J07: o R2 pesa com o perigo 1 (0x21)")
	var arremessos := []
	var reta := 0
	var vento_do_p4 := 0
	var vento_em_todos := 0
	for ev in _linhas_do_minigame("S02_J07"):
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "arremesso":
			arremessos.append(float(ev.get("t_musica", 0.0)))
			var l := int(ev.get("lugar", 0))
			_esperar(visto.fraco.has(l) and visto.forte.has(l), "S02_J07 P%d: o fraco no lançamento e o forte no pouso" % [l + 1])
			if float(ev.get("x_tela", -1.0)) >= 0.0:
				_esperar(float(ev.x_tela) >= 0.2 and float(ev.x_tela) <= 0.8 and float(ev.altura_tela) >= 0.08,
					"S02_J07: o arremesso no meio da tela (%s)" % [ev])
		if ev.get("tipo", "") == "momento" and ev.get("nome", "") == "reta":
			reta += 1
		if ev.get("tipo", "") == "pista" and ev.get("o", "") == "vento" and int(ev.get("de", -1)) == 3:
			vento_do_p4 += 1
			if int(ev.get("alvos", 1)) >= 2:
				vento_em_todos += 1
	_esperar(arremessos.size() >= 3 and arremessos.min() < 30.0,
		"S02_J07: 3 ou mais arremessos, o primeiro antes de 30 s (%s)" % [arremessos])
	_esperar(reta <= 1, "S02_J07: no máximo uma linha momento reta (%d)" % reta)
	_esperar(bool(mg.j[3].fantasma), "S02_J07: o P4 `ruim` virou fantasma")
	if bool(mg.j[3].fantasma):
		_esperar(vento_do_p4 >= 1, "S02_J07: o P4 fantasma soprou vento")
		_esperar(vento_em_todos >= 2, "S02_J07: nas últimas 16 batidas, o sopro pega todos os vivos (%d)" % vento_em_todos)
	var terco := _notas_por_terco("S02_J07", mg.duracao)
	_esperar(terco[1] >= 1.5 * terco[0], "S02_J07: o bolero pede 1,5 × as notas do 1.º terço (%s)" % [terco])
	_esperar(mg.vencedor().size() == 4, "S02_J07: a colocação tem os quatro")
```

A `reta` pode faltar quando o último em pé fecha antes das últimas 16
batidas: a prova pede no máximo uma.

**`godot/testes/captura_jogo.gd`**, no dicionário `momentos`:

```gdscript
		"S02_J07": [
			["pendulos_apice", fase.call("jogo", 6.0)],
			["pendulos_arremesso", na_sala.call(func(sala) -> bool:
				for l in sala.j:
					var e: Dictionary = sala.j[l]
					if float(e.caiu_b) >= 0.0 and Ritmo.batida() - float(e.caiu_b) >= 0.9 and Ritmo.batida() - float(e.caiu_b) <= 1.1:
						return true
				return false)],
		],
```

**Os comandos:** `SALA=S02_J07 bash tests/prova_do_jogo.sh`;
`bash tests/prova_visual.sh`; e as fotos da ficha, o `roteiro` do
`tests/telas.sh` com a sala dela, com o robô `ruim` nos quatro (o `bom`
quase nunca é arremessado, e a foto `pendulos_arremesso` esperaria até o
fim); cada foto num PNG em `SAIDA`: `S02_J07_aviso`, os momentos acima e
`S02_J07_fim`:

```bash
source scripts/engine.sh
SAIDA=/tmp/fotos-S02_J07 ROTEIRO=salas SALAS=S02_J07 RAPIDO=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
  "$FORJA_GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path godot \
  --resolution 1920x1080 res://testes/captura_jogo.tscn -- --simular=4 --semente=7 --robo=ruim \
  --relatorios="$(mktemp -d)"
```

**As pranchas que o jogador do time olha:**

- `pendulos_arremesso`: o boneco no alto do arco, de cabeça para baixo, e a
  mancha `TUNGSTENIO` no disco vazio;
- `S02_J07_fim`: as vidas apagadas na trave de quem caiu;
- o boneco de cada lugar, na `pendulos_apice`: a cabeça, o superior e o inferior em tons
  diferentes, sem a cor do lugar no corpo.

**O André (local):** `./run-local.sh -- --sala=S02_J07`: o golpe de pulso no
alto é natural, a onda dos quatro pêndulos se vê e se ouve, o arremesso faz
rir, o fantasma quer soprar, e o bolero do meio aperta.
