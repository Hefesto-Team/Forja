# I2 — Marcha dos Escudeiros

**Sprint:** I · **Slot:** S01_J02 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, I1 (o `secao.gd` e o `momento`), G03, G05, G14, G15

## Por quê

Marchar é empurrar os dois analógicos para a frente, um de cada vez, no
bumbo: o passo só sai com o analógico até o fim do curso e no tempo — e por
baixo cada passo diz quanto curso cada analógico entrega.

## Ler antes

- [O kit do minigame, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) (o `minigame.gd` e o minigame de prova, o exemplo pequeno)
- [O índice da seção](I-a-centelha.md) (as convenções da seção)
- [I1, a cena](I1-o-martelo-de-hefesto.md#a-cena) (o `secao.gd` inteiro, que esta ficha só chama)

O resto (a linha n.º 2 em 03, a régua da diversão, a bíblia de arte, o mapa do
áudio, o RPG) está copiado nesta ficha, com os números. Não abra outro
documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s01/marcha_dos_escudeiros.gd` | novo, o arquivo inteiro (abaixo) | só desta |
| `godot/scripts/minigames/s01/secao.gd` | nada: só chama | **da seção**: a I1 cria; nenhuma outra reescreve |
| `godot/scripts/minigames/catalogo.gd` | `"S01_J02"` em `MINIGAMES` e na lista da S01 | **de todos**: I1 a I5 põem a sua linha |
| `godot/scripts/traducoes.gd` | as linhas de «Ao terminar» | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_marcha()` e as checagens dos momentos | **de todos** |

O `.uid` novo (`marcha_dos_escudeiros.gd.uid`) sai do import:
`"$GODOT" --headless --path godot --import --quit`, e entra no commit.

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; raia(l) -> Node3D
acender_raia(l, forca); posicionar(l)          # posicionar põe o boneco na raia, de mãos livres
julgar_toque(l, t_alvo, n := -1, perigo := false) -> int   # chama toque() ou falha()
nota_perdida(l, n); nova_nota(l, n, t_alvo); anotar(tipo, l, campos := {})
andamento() -> float (0..1); no_pico() -> bool; tempo_jogado() -> float; marcar(l, pontos)
proxima_batida(l, depois_de, passo, desloc) -> float
var duracao; var _raias  ## lugar -> {raiz, mat_borda, luz}
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const BATIDA_DA_PRIMEIRA_NOTA := 4
```

Do `Forja` e do `Ritmo`: `Forja.sentir(l, nome, ms := -1)` (F05: `toque`,
`acerto`, `perfeito`, `erro`, `golpe`, `explosao`, `aviso`, `golpe_esq`,
`golpe_dir`), `Forja.som_falante(l, som, ganho)`, `Forja.som_haptica(l, esq,
dir, ganho)`, `Forja.gatilho(l, lado, modo, a, b, c)` (lado 0 = L2, 1 = R2),
`Forja.cor_do_lugar(l)`, `Forja.eixo`, `Forja.apertou`, `Forja.robo_apertar`,
`Forja.robo_eixo`, `Forja.robo_acerta()` (F09), `Ritmo.t_musica()`,
`Ritmo.batida()`, `Ritmo.t_da_batida(b)`, `Ritmo.bpm`, `Ritmo.simples[l]`.
Do G03: `Itens.antecipacao_s(l, bpm)` (a Lanterna). Da G15: `Tema.neon(cor,
energia, dono)`, `Tema.emissivo(material, energia, dono)` e
`Tema.luz_da_secao(numero, lado_b := false)` (o número da seção: S1 = 1, o pódio 0); o dono é um lugar (teto 3,0), `"mundo"` (1,2)
ou `"forja"` (2,4). `Forja.vibrar` não é para a sala (F05): só `Forja.sentir`.

Do `secao.gd` da I1 (`const SECAO := preload("res://scripts/minigames/s01/secao.gd")`;
esta ficha só chama, não reescreve): `SECAO.montar(sala, olhar, distancia,
angulo) -> Dictionary`, `SECAO.passar(sala, cena, no_pico())`,
`SECAO.exagero(sala, cena, degrau, boneco, objeto)` (degraus `golpe`,
`estrondo`, `catastrofe`), `SECAO.so_o_dono(sala, dono, luzes := {})`,
`SECAO.na_reta(sala, fim_b := -1.0)` (as últimas 16 batidas),
`SECAO.adiar(fila, f)` e `SECAO.rodar_adiados(fila)` (o momento cai na
próxima colcheia), `SECAO.pose_da_camera(recuo, olhar, distancia, angulo)`,
`SECAO.gancho(l, nome)`, `SECAO.antecedencia(l)` e `SECAO.queda_s(l, tempos)`;
as constantes `SECAO.CAMERA_OLHAR`, `SECAO.CAMERA_ANGULO` (50),
`SECAO.CORRIDA_ANGULO` (30), `SECAO.CORRIDA_DISTANCIA` (17,0). A função
`momento(nome, lugar, pos, altura, campos := {})` do `minigame.gd` (a I1 a
põe; ela grava `x_tela` e `altura_tela`). Até a I1 entrar, esta ficha espera. Do `Desenho` (UI): `Desenho.glifo(nome) -> Texture2D` (`"stick_l"`,
`"stick_r"`).

## Como se joga

### A ficha de dados

```gdscript arquivo=godot/scripts/minigames/s01/marcha_dos_escudeiros.gd parte=2
const FICHA := {
	"slot": "S01_J02",
	"titulo": "Marcha dos Escudeiros",
	"verbo": "Marche!",
	"genero": "corrida",
	"icone": "analogicos",
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

### As regras

- **A faixa:** `MUS_S01_J02`; até a H05, a trilha sintetizada da seção a
  108 bpm; com a faixa gerada, 110 bpm. Um tempo ≈ 0,55 s.
- **A contagem:** batidas 0 a 3. Sobre cada escudeiro, o glifo do analógico
  esquerdo nas batidas 0 e 2 e o do direito nas 1 e 3, com o pulso no
  atuador do mesmo lado (`pulso`, 0,35): o pé que pisca é o analógico que se
  empurra.
- **A marcha, sem hoqueto:** é a exceção da seção: os quatro pisam juntos no
  bumbo, cada um com a sua nota (o kit toca a nota do lugar a cada passo), e
  o passo dos quatro soa como um acorde.
- **As notas:** o passo `k` do lugar cai na batida `4 + k` (um por tempo).
  Passo par: **analógico esquerdo** para a frente; passo ímpar: **direito**.
  `Ritmo.simples[l]`: um passo a cada 2 tempos (`4 + 2k`), alternando igual.
- **O passo:** o analógico pedido cruza −0,8 no eixo Y (para a frente) vindo
  de acima de −0,5; o instante do cruzamento é o toque (`julgar_toque`). O
  outro analógico cruzar −0,8 a menos de `JANELA_BOM` da nota é **trocar o
  pé**: erro. A nota passou sem passo (`FOLGA_PERDIDA`, 0,14 s): nota perdida.
- **O avanço** (metros, na distância `d` do lugar): PERFEITO +0,55, ÓTIMO
  +0,45, BOM +0,25, vezes o Passo (de 0,94 a 1,06) e a Âncora (0,9). A
  esteira puxa para trás a cada tempo inteiro: −0,10 m (−0,25 m no pico). A
  meta: 48 m.
- **O tropeço** (o erro): −1,5 m × o Peso (de 1,16 a 0,84) × a Âncora (0,5),
  no mínimo 0,5 m; as notas dos 2 tempos × o Fôlego seguintes não contam.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o primeiro a chegar +300, o segundo +200, o terceiro +100.
- **A progressão:** `andamento()` do kit (0..1 dos 90 s de música). De 0 a
  1/3, a esteira normal. **O pico (1/3 a 2/3), a ladeira:** a esteira puxa 2,5
  vezes mais, as engrenagens do chão giram, o motor da esquerda pesa a cada
  tempo (`aviso`), e a cada 4 batidas uma engrenagem solta cai 2 m à frente do
  líder, no meio da raia dele; a esteira a traz e quem a alcança perde 0,5 m
  (sem cair, sem tirar janela). O tropeço na ladeira é o momento. **De 2/3 em
  diante, a reta:** a linha de chegada em xadrez aparece; nas últimas 16
  batidas, o passo PERFEITO vale o dobro de metros. Quem acerta tudo chega
  perto do tempo 120 (~67 s a 108 bpm); quem erra um terço não chega e o mais
  longe decide.
- **A reta final:** o primeiro que passa da meta abre 16 tempos para os
  outros; acabados os 16, todos acabam (o fim da F03). Sem ninguém na meta,
  o fim é o dos 90 s. As últimas 16 batidas contam do que vier antes.

### A falha

Ele tropeça nas engrenagens e cai para trás: `p.gesto("fall", 0.6)`, uma
engrenagem salta do chão (duas `Kit.caixa` cruzadas de 0,4 m,
`Tema.OXIDO_BRILHO`, 1 m para cima em meia batida, de volta ao chão em meia
batida, e caída na raia 4 s), faíscas `Tema.TUNGSTENIO` nos pés, −1,5 m × o
Peso (piso 0,5 m), e as notas dos 2 tempos × o Fôlego seguintes não contam
(nem erro, nem acerto). Recupera na nota depois.

**Na ladeira (o pico), o tombo é o momento** `arrastado_na_ladeira`: em vez
do `fall`, o escudeiro deita de costas (`rotation.x` −90° em ¼ de batida) e
a esteira o leva 1,5 m para trás na tela em 1 batida, passando pelos outros
que marcham; levanta em meia batida e volta ao lugar em 2 batidas.

### O fim e o vencedor

Quem passa da meta acaba (`acabou[l] = true`), faz `emote-yes` e entra na
lista `chegada`. `vencedor()`: primeiro os da `chegada`, na ordem; depois os
outros pela distância; empate pela ordem do lugar.

### Com menos de quatro

Nada muda na regra. Com um só, é contra a esteira: chegar é vencer; não
chegar, também fecha com ele em primeiro (o único). **O controle que cai:**
o escudeiro fica parado (a esteira não o puxa enquanto ele está sem
controle), e ao voltar o próximo passo é a próxima batida que ainda não
passou. A câmera segue o segundo e o último de quem
está presente; com um só, segue ele.

### O robô

```gdscript arquivo=godot/scripts/minigames/s01/marcha_dos_escudeiros.gd parte=3
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

O robô não desvia da engrenagem solta: ela não tira janela.

### O código

`godot/scripts/minigames/s01/marcha_dos_escudeiros.gd`:

```gdscript arquivo=godot/scripts/minigames/s01/marcha_dos_escudeiros.gd
extends Minigame
## Marcha dos Escudeiros (S01_J02). Cada escudeiro marcha numa esteira que
## puxa para trás; o passo é empurrar o analógico para a frente, o esquerdo e
## o direito alternados, no bumbo. Passo no tempo avança; a meta é a 48 m.
## No meio, a ladeira: a esteira puxa mais, e uma engrenagem solta cai na
## raia do líder a cada 4 batidas. De 2/3 em diante, a linha de chegada; nas
## últimas 16 batidas, o passo PERFEITO vale o dobro de metros.
##
## A falha: tropeça nas engrenagens, cai para trás (−1,5 m × o Peso) e perde
## os passos da queda (2 tempos × o Fôlego). Na ladeira, a esteira o arrasta.
## O vencedor: quem passa da meta primeiro; senão, o mais longe.
## O alto-falante do dono: a nota no perfeito, a coleta na meta. O passo no
## metal vai aos atuadores, do lado do pé.
## O registro mede: cada analógico pedido, o instante e o curso do passo (a
## linha `entrada`), cada nota e toque (o kit) e os momentos
## `arrastado_na_ladeira` e `reta`.
## O robô: empurra o analógico da vez na nota; quando não acerta, 200 ms atrasado.
## Com menos de quatro: nada muda.
## A régua: "Marche!" e o glifo do analógico bastam; sem a tela, o bumbo e a
## nota de cada passo dizem o tempo; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

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
const QUEDA_TEMPOS := 2.0  ## no chão depois do tropeço: 2 tempos × o Fôlego
const TROPECO_MIN := 0.5  ## o piso do tropeço, em m, com o Peso 5 e a Âncora
const ARRASTO := 1.5  ## na ladeira, o tombo desliza 1,5 m para trás na tela, em 1 batida
const CAIDA_S := 4.0  ## a engrenagem que saltou fica caída na raia 4 s
const CAI_NO_LIDER := 4  ## na ladeira, uma engrenagem solta a cada 4 batidas na raia do líder
const PISOU := 0.5  ## quem alcança a engrenagem solta perde 0,5 m

var j := {}  ## lugar -> o estado
var n_nos := {}  ## lugar -> os nós (engrenagens)
var chegada: Array = []  ## os lugares na ordem em que passaram da meta
var _fim_da_reta := -1.0  ## a batida em que a reta final acaba (-1: ninguém chegou)
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var cena := {}  ## o que o SECAO.montar devolveu
var _adiados: Array = []  ## o que cai na próxima colcheia (SECAO.adiar)
var _glifos := {}  ## lugar -> o Sprite3D da contagem
var _xadrez: Node3D
var _contagem_vista := -1
var _ladeira_vista := -1
var _reta_marcada := false


func montar() -> void:
	cena = SECAO.montar(self, Vector3(0, 0.5, -0.5), SECAO.CORRIDA_DISTANCIA, SECAO.CORRIDA_ANGULO)
	cena.camera = false  # a corrida segue o pelotão (_camera)
	_xadrez = _montar_xadrez()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var x: float = RAIAS[l]
		Kit.caixa(self, Vector3(1.6, 0.12, 11.0), Vector3(x, 0.06, -0.5), Kit.material(Tema.TINTA, 0.0, 0.9))
		var ferro := Kit.material(Tema.GRAFITE, 0.0, 0.7)
		for z in [5.0, -6.0]:
			Kit.caixa(self, Vector3(1.8, 0.3, 0.3), Vector3(x, 0.15, z), ferro)
		Kit.peca(self, "gate", Vector3(x, 0, -6.4))
		for lado in [-1.1, 1.1]:
			Kit.peca(self, "banner", Vector3(x + lado, 0, -6.2))
		var dentes: Array = []
		for i in 10:
			dentes.append(Kit.caixa(self, Vector3(1.4, 0.05, 0.14), Vector3(x, 0.14, 0), Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.7)))
		n_nos[l] = dentes
		maos_livres(p)
		p.preso = true
		p.position = Vector3(x, 0.12, Z_LARGADA)
		p.rotation.y = PI
		var glifo := Sprite3D.new()
		glifo.pixel_size = 0.006
		glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glifo.shaded = false
		glifo.modulate = Tema.ETIQUETA
		glifo.position = Vector3(x, 2.6, Z_LARGADA)
		glifo.visible = false
		add_child(glifo)
		_glifos[l] = glifo
		j[l] = {"d": 0.0, "k": 0, "n": 0, "b": -1.0, "caido_b": -1.0, "batida_puxada": -1,
			"antes_l": 0.0, "antes_r": 0.0, "curso": 0.0, "fora": false, "robo_n": -1, "robo_mira": 0.0,
			"arrasto": 0.0, "solta": null, "solta_d": 0.0, "solta_b": 0.0}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


## A próxima batida de passo do lugar que ainda não passou (a `proxima_batida` do kit).
func _passo_da_vez(l: int) -> float:
	return proxima_batida(l, Ritmo.batida() - 0.001, 1.0)  # o kit dobra o passo na partitura simples


func _marcar_nota(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	e.b = b
	e.curso = 0.0
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))


func iniciar_jogo() -> void:
	for l in presentes():
		j[l].batida_puxada = int(BATIDA_DA_PRIMEIRA_NOTA)
		_marcar_nota(l, BATIDA_DA_PRIMEIRA_NOTA)


func jogar(_dt: float) -> void:
	SECAO.passar(self, cena, no_pico())
	SECAO.rodar_adiados(_adiados)
	_camera()
	_contagem()
	_ladeira()
	if _xadrez and not _xadrez.visible and (andamento() >= 2.0 / 3.0 or _fim_da_reta >= 0.0):
		_xadrez.visible = true
	if not _reta_marcada and fase == "jogo" and SECAO.na_reta(self, _fim_da_reta):
		_reta_marcada = true
		var valores := PackedStringArray(presentes().map(func(x): return str(int(j[x].d))))
		momento("reta", -1, Vector3(0, 0, Z_CHEGADA), 2.0, {"objeto": "chegada", "valores": ",".join(valores)})
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
				e.d = maxf(0.0, float(e.d) - (PUXA_LADEIRA if no_pico() else PUXA))
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
	if float(e.b) < float(e.caido_b):
		# no chão: o passo desta nota não conta
		if agora > alvo + FOLGA_PERDIDA:
			_seguinte(l)
		return
	var perto := absf(agora - alvo) <= Ritmo.JANELA_BOM
	if perto and antes_outro > SOLTO and y_outro <= FRENTE:
		anotar("entrada", l, {"o": "analogico", "lado": "direito" if esquerdo else "esquerdo",
			"trocou_o_pe": true, "n": int(e.n)})
		nota_perdida(l, int(e.n))
		return
	if antes_pedido > SOLTO and y_pedido <= FRENTE and agora >= alvo - 0.5 * 60.0 / Ritmo.bpm:
		anotar("entrada", l, {"o": "analogico", "lado": "esquerdo" if esquerdo else "direito",
			"curso": snappedf(float(e.curso), 0.01), "n": int(e.n)})
		julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
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
		# o Passo e a Âncora (G03) mudam o metro; nas últimas 16 batidas, o PERFEITO vale o dobro
		var dobro := 2.0 if julgamento == Ritmo.PERFEITO and SECAO.na_reta(self, _fim_da_reta) else 1.0
		e.d = float(e.d) + AVANCO[julgamento] * SECAO.gancho(l, "velocidade") \
			* Itens.velocidade(l, "corrida") * dobro
	if julgamento != Ritmo.PERFEITO:
		# o passo no metal (chão 2), no atuador do lado do pé
		var som := "passo:2:%d" % (int(e.k) % 3)
		var esquerdo := int(e.k) % 2 == 0
		Forja.som_haptica(l, som if esquerdo else "", "" if esquerdo else som, 0.5)
	if float(e.d) >= META and not (l in chegada):
		_chegou(l)
		return
	_seguinte(l)


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var e: Dictionary = j[l]
	if not treinando:
		# o Peso e a Âncora (G03) mudam o tranco, até o piso de 0,5 m
		var m := maxf(TROPECO_MIN, TROPECO * SECAO.gancho(l, "empurrao") * (1.0 - Itens.resiste_a_empurrao(l)))
		e.d = maxf(0.0, float(e.d) - m)
	# no chão: as notas antes desta batida não contam (2 tempos × o Fôlego)
	e.caido_b = Ritmo.batida() + SECAO.queda_s(l, QUEDA_TEMPOS) * Ritmo.bpm / 60.0
	var p := jogador(l)
	if p:
		Efeitos.faiscas(self, p.global_position + Vector3(0, 0.2, 0), Tema.TUNGSTENIO, 18, 0.8)
		_engrenagem_salta(p.global_position)
		Som.tocar("golpe", p.global_position, -6.0)
		if no_pico():
			# o momento: o tombo, o tremor e a vibração caem juntos na próxima colcheia
			SECAO.adiar(_adiados, _tombo_na_ladeira.bind(l))
		else:
			p.gesto("fall", 0.6)
			Forja.sentir(l, "golpe")
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


## Uma engrenagem (duas caixas cruzadas) salta 1 m do chão em meia batida,
## cai de lado em meia batida e fica caída na raia 4 s (o rastro).
func _engrenagem_salta(pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos + Vector3(0, 0.2, -0.3)
	add_child(g)
	var mat := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.7)
	Kit.caixa(g, Vector3(0.4, 0.1, 0.1), Vector3.ZERO, mat)
	var b := Kit.caixa(g, Vector3(0.4, 0.1, 0.1), Vector3.ZERO, mat)
	b.rotation.z = PI * 0.5
	var meia := 30.0 / Ritmo.bpm
	var tw := g.create_tween()
	tw.tween_property(g, "position:y", g.position.y + 1.0, meia).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(g, "rotation:z", TAU, meia)
	tw.tween_property(g, "position:y", 0.14, meia).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(g, "rotation:x", PI * 0.5, meia)
	tw.tween_interval(CAIDA_S)
	tw.tween_callback(g.queue_free)


func _mostrar(l: int) -> void:
	var e: Dictionary = j[l]
	var p := jogador(l)
	if p == null:
		return
	var alvo_z := lerpf(Z_LARGADA, Z_CHEGADA, clampf(float(e.d) / META, 0.0, 1.0))
	# o arrasto (o tombo na ladeira) é só da tela: o `d` já perdeu o tropeço
	p.position = Vector3(RAIAS[l], 0.12, lerpf(p.position.z, alvo_z + float(e.arrasto), 0.2))
	if fase == "jogo" and not acabou[l] and conectado(l) and Ritmo.batida() >= float(e.caido_b):
		p.animar("walk", 1.0)
	else:
		p.animar("idle")
	var puxa := PUXA_LADEIRA if no_pico() else PUXA
	var dentes: Array = n_nos[l]
	for i in dentes.size():
		var d: MeshInstance3D = dentes[i]
		d.position.z = 5.0 - fposmod(Ritmo.batida() * puxa * 4.0 + 1.1 * i, 11.0)
		d.rotation.x = fmod(Ritmo.batida(), 1.0) * TAU if no_pico() else 0.0


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


## A câmera de corrida (28 mm, 30°, a 17 m) segue o pelotão: olha o meio
## entre o segundo e o último; o líder pode sair pela borda de cima, o último
## nunca. No pico, recua 10 %.
func _camera() -> void:
	var zs: Array = []
	for l in vencedor():  # do primeiro ao último
		var p := jogador(l)
		if p:
			zs.append(p.position.z)
	if zs.is_empty():
		return
	var z := (float(zs[mini(1, zs.size() - 1)]) + float(zs[-1])) * 0.5
	var pose := SECAO.pose_da_camera(1.1 if no_pico() else 1.0, Vector3(0, 0.5, z),
		SECAO.CORRIDA_DISTANCIA, SECAO.CORRIDA_ANGULO)
	camera_pos = pose[0]
	camera_olhar = pose[1]


## A contagem (batidas 0 a 3): sobre cada escudeiro, o glifo do analógico do
## pé da vez (o esquerdo nas batidas pares, o direito nas ímpares), e o pulso
## no atuador do mesmo lado. O pé que pisca é o analógico que se empurra.
func _contagem() -> void:
	var b := Ritmo.batida()
	var mostrar := b >= 0.0 and b < float(BATIDA_DA_PRIMEIRA_NOTA)
	for l in _glifos:
		(_glifos[l] as Sprite3D).visible = mostrar
	if not mostrar:
		return
	var k := int(floor(b))
	if k == _contagem_vista:
		return
	_contagem_vista = k
	var esquerdo := k % 2 == 0
	for l in _glifos:
		(_glifos[l] as Sprite3D).texture = Desenho.glifo("stick_l" if esquerdo else "stick_r")
		if na_raia(l):
			Forja.som_haptica(l, "pulso" if esquerdo else "", "" if esquerdo else "pulso", 0.35)


## A ladeira (o pico): a cada tempo, o peso no motor da esquerda de quem
## marcha (`aviso`, renovado antes de acabar); a cada 4 batidas, uma engrenagem
## solta cai 2 m à frente do líder, no meio da raia dele, e a esteira a traz.
## Quem a alcança perde 0,5 m (sem tirar janela, sem cair).
func _ladeira() -> void:
	var b := int(floor(Ritmo.batida()))
	if no_pico() and fase == "jogo" and b != _ladeira_vista:
		_ladeira_vista = b
		for l in presentes():
			if not acabou[l] and conectado(l):
				Forja.sentir(l, "aviso", int(60000.0 / Ritmo.bpm) + 20)
		if b % CAI_NO_LIDER == 0:
			for l in vencedor():
				if not acabou[l]:
					if j[l].solta == null:
						_soltar_engrenagem(l)
					break
	for l in presentes():
		var e: Dictionary = j[l]
		if e.solta == null:
			continue
		var g: Node3D = e.solta
		if not no_pico() or acabou[l]:
			g.queue_free()
			e.solta = null
			continue
		var gd := float(e.solta_d) - (Ritmo.batida() - float(e.solta_b)) * PUXA_LADEIRA
		g.position.z = lerpf(Z_LARGADA, Z_CHEGADA, clampf(gd / META, 0.0, 1.0))
		if float(e.d) >= gd:
			if not treinando:
				e.d = maxf(0.0, float(e.d) - PISOU)
			Forja.sentir(l, "toque")
			var p := jogador(l)
			if p:
				p.gesto("emote-no", 0.4)
			g.queue_free()
			e.solta = null


## A engrenagem solta da ladeira: duas caixas cruzadas, deitadas, que caem de
## 3 m em meia batida.
func _soltar_engrenagem(l: int) -> void:
	var e: Dictionary = j[l]
	var g := Node3D.new()
	g.position = Vector3(RAIAS[l], 3.0, 0.0)
	add_child(g)
	var mat := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.7)
	Kit.caixa(g, Vector3(0.5, 0.12, 0.12), Vector3.ZERO, mat)
	var c := Kit.caixa(g, Vector3(0.5, 0.12, 0.12), Vector3.ZERO, mat)
	c.rotation.y = PI * 0.5
	e.solta = g
	e.solta_d = float(e.d) + 2.0
	e.solta_b = Ritmo.batida()
	g.create_tween().tween_property(g, "position:y", 0.2, 30.0 / Ritmo.bpm) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## O tombo na ladeira (o momento `arrastado_na_ladeira`): o escudeiro deita de
## costas e a esteira o leva 1,5 m para trás na tela em 1 batida, passando
## pelos outros; levanta em meia batida e volta à marcha em 2. Roda na
## colcheia seguinte ao erro (SECAO.adiar).
func _tombo_na_ladeira(l: int) -> void:
	var p := jogador(l)
	if p == null:
		return
	var e: Dictionary = j[l]
	var batida := 60.0 / Ritmo.bpm
	var arrastar := func(v: float) -> void:
		e.arrasto = v
	var tw := create_tween()
	tw.tween_property(p, "rotation:x", -PI * 0.5, 0.25 * batida)
	tw.parallel().tween_method(arrastar, 0.0, ARRASTO, batida).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "rotation:x", 0.0, 0.5 * batida)
	tw.tween_method(arrastar, ARRASTO, 0.0, 2.0 * batida).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	SECAO.exagero(self, cena, "estrondo", p)
	Forja.sentir(l, "golpe")
	momento("arrastado_na_ladeira", l, p.global_position, 1.8, {"d": snappedf(float(e.d), 0.1)})


## A linha de chegada em xadrez: duas fileiras de 8 caixas de 0,2 m por raia,
## `Tema.ETIQUETA` e `Tema.TINTA` alternadas, em `Z_CHEGADA`. Aparece a 2/3.
func _montar_xadrez() -> Node3D:
	var x := Node3D.new()
	x.visible = false
	add_child(x)
	var claro := Kit.material(Tema.ETIQUETA, 0.0, 0.8)
	var escuro := Kit.material(Tema.TINTA, 0.0, 0.8)
	for p in jogadores:
		for i in 8:
			for fila in 2:
				Kit.caixa(x, Vector3(0.2, 0.02, 0.2),
					Vector3(RAIAS[p.lugar] - 0.7 + 0.2 * i, 0.13, Z_CHEGADA - 0.1 + 0.2 * fila),
					claro if (i + fila) % 2 == 0 else escuro)
	return x
```

(As engrenagens andam `puxa × 4` por batida só para se verem andando; a
distância de verdade é `d`.)

### O que o registro mede

- O kit: `nota` por passo pedido e `toque` por passo dado (o desvio), com
  o `n`; passo par é o esquerdo, ímpar o direito.
- A linha `entrada` em todo passo: o lado, o **curso** (o máximo que o
  analógico chegou para a frente, 0 a 1) e o `n`; e `trocou_o_pe` quando o
  outro analógico cruzou. Cruzado depois da noite: um analógico que nunca
  passa de 0,9 de curso, ou que chega sempre atrasado, aparece aqui.
- A linha `momento`: `arrastado_na_ladeira` (o lugar, `d`, `x_tela`,
  `altura_tela`) e `reta` (uma vez, de todos, com `objeto` `chegada` e
  `valores`, os metros de cada lugar presente).

### Armadilhas

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
- **O tombo na ladeira cai na colcheia** seguinte ao erro (`SECAO.adiar`),
  com o tremor, a vibração `golpe` e o momento juntos: a `nota_perdida` chega
  140 ms depois da nota, fora da grade.
- **O arrasto é só da tela** (`e.arrasto` soma ao z do boneco); o `d` já
  perdeu o tropeço. A engrenagem solta vive em metros (`solta_d`), não em z.
- **A queda compara a batida da nota** (`e.b < e.caido_b`), não a de agora.
- **A câmera é da Marcha** (`_camera`): `cena.camera` false, senão o
  `SECAO.passar` a põe de volta no meio.
- **Nenhum `Color("#…")`**: a esteira `Tema.TINTA`, o ferro `Tema.GRAFITE`,
  as engrenagens `Tema.OXIDO_BRILHO` (G14); nada brilha fora de `Tema.neon`,
  `Tema.contorno` e `Tema.emissivo` (G15).

## A cena

### A câmera

A câmera de corrida do cinema: lente de 28 mm (FOV vertical 46,4°), 30°
abaixo da horizontal, atrás e acima, a 17 m, o modo `fixa` da G05 com a
posição que a Marcha manda a cada quadro (`_camera`). Ela olha
`(0, 0,5, z)`, com `z` o meio entre o segundo colocado e o último: o líder
pode sair pela borda de cima, o último nunca. Com o pelotão no meio da
esteira (z = −0,5), a câmera fica em `(0, 9,0, 14,22)`. O `lerp` do main faz
o caminho (nunca salta).

- **O pico:** a câmera recua 10 % (a 18,7 m).
- **O tremor é do evento:** só o de `SECAO.exagero` (o tombo na ladeira,
  estrondo: 0,05 m por 2 batidas). Nenhum tremor de ambiente, roll zero.
- A lente é a da G05; até ela entrar, os 40° de hoje fecham 15 % do quadro, e
  as raias de x = ±6 ficam dentro (x_tela 0,23 e 0,77).

### A luz da seção

S1 é o vermelhão (`Tema.SECAO[0]`, `#c8432f`), lado A.
`Tema.luz_da_secao(1)` (G15; S1, lado A: `lado_b` false) devolve a névoa `#210502`, o preenchimento
`#602016` e a chave `#ffc99c`. O `SECAO.montar` da I1 põe o preenchimento (o
`atmosfera`, com as brasas), a chave (`OmniLight3D` em `(0, 8, 3)`, energia
0,9, alcance 26) e a fornalha do fundo (`Tema.TUNGSTENIO`, 1,4, alcance 8, em
`(0, 1,2, −6)`). No pico, o `SECAO.passar` sobe a chave e a fornalha 20 % em
1 batida e as devolve em 2 (com `Opcoes.flashes` desligado: +10 % em 2
batidas).

- **O tombo na ladeira:** o `SECAO.exagero` do degrau estrondo (sem mudança de
  luz; o tremor e o boneco parado 3 quadros).

### As peças e o papel de cada uma

`cena = SECAO.montar(self, Vector3(0, 0.5, -0.5), 17.0, 30.0)` (a forja da I1) e,
por lugar, a esteira na raia:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a raia | `raia(l)` do kit (a laje, a borda na cor, a luz da vez) | `(RAIAS[l], 0, Z_JOGADOR)` |
| a esteira | `Kit.caixa(self, Vector3(1.6, 0.12, 11.0), ..., Kit.material(Tema.TINTA, 0.0, 0.9))` | centro `(RAIAS[l], 0.06, −0.5)` |
| as polias | duas `Kit.caixa` de `Vector3(1.8, 0.3, 0.3)`, `Tema.GRAFITE` | `z = 5.0` e `z = −6.0`, `y = 0.15` |
| as engrenagens | 10 `Kit.caixa` de `Vector3(1.4, 0.05, 0.14)`, `Tema.OXIDO_BRILHO`, que andam com a esteira | sobre a esteira, `y = 0.14` |
| a chegada | `gate` (escala 2) e dois `banner` | `(RAIAS[l], 0, −6.4)`; `banner` em `x ± 1.1` |
| a linha de chegada | 2 × 8 caixas de 0,2 × 0,02 × 0,2, `Tema.ETIQUETA` e `Tema.TINTA` em xadrez | `z = Z_CHEGADA` (−5,8); aparece a 2/3 |
| o escudeiro | o boneco, de costas (`rotation.y = PI`), mãos livres | `z = lerp(4.5, −5.8, d / META) + arrasto`, `y = 0.12` |
| o glifo da contagem | `Sprite3D`, `Desenho.glifo("stick_l"/"stick_r")`, 0,006 m por pixel, `Tema.ETIQUETA` | `(RAIAS[l], 2.6, 4.5)`, só nas batidas 0 a 3 |
| a engrenagem que salta | 2 caixas cruzadas de 0,4 m, `Tema.OXIDO_BRILHO` | nos pés de quem tropeça; caída 4 s |
| a engrenagem solta | 2 caixas cruzadas de 0,5 m, `Tema.OXIDO_BRILHO` | na raia do líder, 2 m à frente dele; só no pico |

A raia do kit fica em `Z_JOGADOR` (1,4): a esteira passa por cima dela.
As engrenagens andam pela batida: `z = 5.0 − fposmod(Ritmo.batida() * puxa * 4.0 + 1.1 * i, 11.0)`
(`puxa` 0,10 ou 0,25). Na ladeira, cada uma gira em `rotation.x` pela
batida. Nada liso: tudo caixa.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08, arte/04) |
| a borda da raia | o lugar | a do kit (H04) |
| as faíscas da chegada | o lugar | `Forja.cor_do_lugar(l)`, 40 partículas |
| as faíscas do tropeço | a forja | `Tema.TUNGSTENIO`, 18 partículas |
| a esteira, as polias, as engrenagens, a linha de chegada | ninguém | sem brilho (`Kit.material(..., 0.0, ...)`) |

Nenhuma cor fora dos tokens: os `#2a2233`, `#4a4e5e` e `#5b6275` e o
`Tema.LARANJA` de hoje somem desta sala.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o passo | a nota do lugar (o kit): os quatro juntos, um acorde por passo | perfeito: a nota do lugar (o kit); fora dele, o passo no metal nos atuadores | `mod_nota_p1..p4`, `mod_passo_metal_0..2` |
| o tropeço | `Som.tocar("golpe", pos, -6.0)` | a nota quebrada (o kit) | `golpe_0..4`; `mod_nota_quebrada_p1..p4` |
| cruzar a meta | `Som.tocar("portao", pos + (0, 1.5, 0))` | `Forja.som_falante(l, "coleta", 0.8)` | `portao_0`; `mod_coleta` |
| a faixa | `MUS_S01_J02`: 110 BPM; até ela existir, a sintetizada da H05 a 108 | — | `mus_s01_j02` |

- **O alto-falante toca um som por vez** e o julgamento tem a vez.
- **Nenhum bipe de falha:** o tropeço soa como metal (`golpe`); o `falha` de
  hoje sai.
- **O mapa do áudio** ainda não lista a I2 em `golpe_*` (hoje I3 e I5) nem
  em `mod_pulso` (hoje J4 e P4): a coluna «quem usa» é do diretor de som;
  esta ficha não edita o mapa.
- O passo no metal vai aos atuadores (`passo:2:<0..2>`, o chão 2 é o metal da
  H07), do lado do pé, fora do perfeito.

## O controle

Evento por evento, para quem joga e para os outros. O piso é o da F05.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a contagem | todos | `Forja.som_haptica(l, "pulso", "", 0.35)` nas batidas 0 e 2; `("", "pulso")` nas 1 e 3 | — | — | — |
| o passo (bom, ótimo) | o dono | `acerto` (o kit) e `passo:2:<k % 3>` a 0,5 no atuador do pé (`som_haptica`) | — | o kit | — |
| o passo perfeito | o dono | `perfeito` (o kit) | — | o kit: branco 0,15 s (sem flashes: parada) | a nota do lugar |
| o tropeço fora do pico | o dono | `erro` (o kit) e `golpe` (1,0 / 0,6, 250 ms) | — | o kit: a cor escurecida 0,5 s | a nota quebrada |
| o tombo na ladeira | o dono | `erro` (o kit) e `golpe`, na colcheia seguinte | — | o kit | a nota quebrada |
| a ladeira (o pico) | quem marcha | `Forja.sentir(l, "aviso", int(60000 / bpm) + 20)` a cada tempo | — | — | — |
| pisar na engrenagem solta | o dono | `toque` (0 / 0,45, 60 ms) | — | — | — |
| cruzar a meta | o dono | `explosao` (1 / 1, 400 ms) | — | — | `coleta` 0,8 |
| começar | todos | — | R2 `GATILHO_OFF`; o L2 nunca (é do item, G03) | a cor do lugar | — |

- A barra de luz é **sempre a cor do lugar**; o piscar do julgamento é do kit.
- O microfone não se usa.
- **Os outros não sentem nada** do que é de um: cada linha acima vai só ao
  controle do dono.
- **Sem o controle na mão:** o robô (acima) marcha pelos eixos simulados; a
  prova confere que cada `arrastado_na_ladeira` tem a sua `sensacao` `golpe`
  no mesmo quadro.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo
que a pessoa escolheu aparecem como estão, de costas para a câmera, na
esteira. Cada parte tem a sua faixa de valor e um acento de néon só, na cor do
lugar (arte/04, «A peça se distingue»): a cabeça humana sem acento (a de
raça, o visor ou a rachadura, até 6 %), o friso do superior (até 8 % da
parte, energia 1,6), a costura do inferior (até 5 %, 1,6); somados, no
máximo 8 % da frente do corpo. O contorno é de 0,012, energia 2,4 no jogo. `maos_livres(p)`: a arma ou o amuleto não aparece na
Marcha, mas o efeito do item vale. O cavaleiro pode ser de outra raça (o Orc, o Autômato de latão, o Golem de
escória, a Raposa ferreira; a raça é só aparência): esta ficha não supõe
corpo humano; usa o esqueleto comum de 7 ossos e as animações `walk`, `fall`, `emote-yes`,
`emote-no` e `idle`; o tombo na ladeira gira o boneco inteiro (`rotation.x`),
sem animação própria.

| stat | gancho | o que muda na Marcha | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o tropeço, em metros | 1,74 m | 1,5 m | 1,26 m |
| Passo | `velocidade` | o metro de cada passo (o PERFEITO) | 0,517 m | 0,55 m | 0,583 m |
| Fôlego | `levantar` | quanto tempo no chão (as notas que não contam) | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | não age: a Marcha não acende pista; o bumbo é a pista | — | — | — |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Âncora divide o
tropeço por 2 (até o piso de 0,5 m) e deixa o passo 10 % mais curto
(`Itens.velocidade(l, "corrida")`); o Martelo dobra o perfeito no tempo forte
(o kit); o Fole e o Diapasão agem no combo pelo kit. Os números da régua:
nenhum stat muda a janela de julgamento; o stat 5 nunca tira o tropeço (o
piso de 0,5 m).

## As reações

- **Carimbos que a Marcha pode disparar** (todos são do kit e do HUD, G04;
  a Marcha não chama nenhum): `car_acorde` (os quatro na Ressonância no mesmo
  tempo 1: a Marcha é o único minigame da seção sem hoqueto, então é aqui que
  ele aparece), `car_em_chamas` (5 Ressonâncias seguidas do mesmo lugar),
  `car_por_um_fio` (o vencedor por 2 % dos pontos ou menos, no resultado). O
  `car_virada` é do placar.
- **Adesivos:** ninguém está fora da rodada na Marcha, então ninguém manda adesivo
  durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

Nota de hoje 4; com o tombo na ladeira e a reta, o alvo é 5.

**O momento: arrastado pela ladeira** (`arrastado_na_ladeira`). No pico, quem
tropeça cai de costas e a esteira o leva 1,5 m para trás em 1 batida,
deitado, passando pelos outros que marcham. Degrau estrondo: tremor de
0,05 m por 2 batidas, o escudeiro parado 3 quadros; a engrenagem salta 1 m
do chão, faíscas nos pés.

- **Rastro:** a engrenagem que saltou fica caída na raia 4 s; o escudeiro
  fica deitado 1 batida e levanta na outra (a silhueta deitada é 90° da de
  pé).
- **A curva:** de 0 a 30 s, a esteira normal e um acorde por passo; de 30 a
  60 s, a ladeira (a esteira 2,5 vezes, o motor pesa, as engrenagens soltas
  no líder); de 60 s ao fim, a linha de chegada aparece e, nas últimas 16
  batidas, o PERFEITO vale o dobro de metros.
- **Ensina sem falar:** na contagem, o glifo do analógico do pé da vez pisca
  sobre cada escudeiro, com o pulso do mesmo lado.
- **Quem está perdendo:** a câmera enquadra do segundo ao último; na ladeira,
  as engrenagens soltas caem no caminho do líder (0,5 m cada, uma a cada 4
  batidas), sem tirar janela; o PERFEITO dobrado da reta vale para todos.
- **O que se corta:** nada da regra. A esteira que puxa −0,10 m a cada tempo
  fica: é ela que faz o tombo andar.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3
`medio`, P4 `ruim`, semente 7, sem a bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | os quadros de 2 a 10 s mostram os quatro escudeiros andando |
| 3. ensina sem falar | a coleta de texto da F02 na fase de jogo só acha o verbo, os nomes, os P#, o placar e o julgamento | o quadro da contagem mostra o glifo do analógico sobre cada escudeiro |
| 4. o momento | pelo menos 4 linhas `momento` `arrastado_na_ladeira` entre 30 e 60 s | um quadro entre 32 e 58 s mostra um escudeiro deitado atrás da linha dos outros |
| 5. a curva | a esteira puxa 0,25 m por tempo entre 30 e 60 s (a `d` do líder anda menos); a linha `momento` `reta` existe uma vez | o quadro de 62 s mostra a linha de chegada em xadrez |
| 6. a falha | o P4 tem pelo menos 6 linhas `toque` com `erro` | 1 quadro em 5 mostra uma engrenagem caída numa raia |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 2 batidas (a nota segue marcada no chão); o P4 tem um `toque` BOM ou melhor em cada terço | o último colocado aparece em 100 % dos quadros de jogo (a câmera segue o último) |
| 8. a câmera | cada `arrastado_na_ladeira` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | o escudeiro deitado se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `arrastado_na_ladeira`, uma linha `sensacao` `golpe` do mesmo lugar a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte ainda mostra a engrenagem caída |
| 10. o placar no mundo | a ordem do `vencedor()` bate com a ordem dos metros no `momento` `reta` | no quadro de 60 s, quem olha diz a ordem pelo lugar dos escudeiros na esteira |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na
régua) existir, a prova roda com `--robo=medio` nos quatro e confere os itens 1, 3, 5, 8, 9 e 10;
os itens 4, 6 e 7 (que pedem o P4 `ruim`) esperam o robô por lugar.

## Pronto quando

A marcha joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; o cabo que cai e volta não derruba ninguém; a reta final
fecha a corrida; o fim tem sempre vencedor; `bash tests/prova_do_jogo.sh`
passa; e `bash tests/prova_visual.sh` passa com a prancha **olhada** nas
partidas em que a Marcha aparece (com quatro, dois, um e o cabo que cai). Além disso: o tombo na ladeira grava
`arrastado_na_ladeira` a até 1 quadro de uma colcheia, com a sua `sensacao`
`golpe`; a linha `momento` `reta` aparece uma vez; e nenhuma cor fora dos
tokens sobra no `marcha_dos_escudeiros.gd`
(`grep -nE 'Color\("#|Tema\.(ROSA|AMARELO|TRILHO|LARANJA|FG)\b'` não acha nada).

## Provas

Em `godot/testes/prova_do_jogo.gd`, chamada no `_prova_do_percurso()` logo
depois de `await _prova_do_kit()`:

```gdscript
## S01_J02 (I2): a Marcha abre pelo catálogo, o robô marcha pelo analógico
## simulado, cada lugar tem passo julgado e a corrida fecha com vencedor.
func _prova_da_marcha() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S01_J02", 130.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "S01_J02 P%d: passos julgados %s" % [l + 1, c])
	_esperar(mg.vencedor().size() == 4, "S01_J02: a colocação tem os quatro")
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J02: de volta ao salão")
```

Ainda na `_prova_da_marcha()`, antes de esperar o salão, os momentos (a
régua):

```gdscript
	var todas := _linha_do_tempo()
	var linhas := todas.filter(func(e): return e.get("slot") == "S01_J02")
	var momentos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "arrastado_na_ladeira" \
		and float(e.get("t_musica", 0.0)) >= 30.0 and float(e.get("t_musica", 0.0)) <= 60.0)
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "S01_J02: a linha momento reta aparece uma vez")
	for r in momentos:
		_esperar(float(r.get("x_tela", 0.0)) >= 0.2 and float(r.get("x_tela", 0.0)) <= 0.8 \
			and float(r.get("altura_tela", 0.0)) >= 0.08, "S01_J02: o momento no meio da tela (%s)" % [r])
		var t := float(r.get("t_musica", 0.0))
		# a sensacao (F05) não leva slot: procura em todas, perto no relógio da sessão (t)
		var sente := todas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "golpe" \
			and int(e.get("lugar", -9)) == int(r.get("lugar", -1)) \
			and absf(float(e.get("t_musica", -9.0)) - t) <= 0.0167 \
			and absf(float(e.get("t", -9.0)) - float(r.get("t", 0.0))) <= 1.0)
		_esperar(not sente.is_empty(), "S01_J02: o momento tem a sensação golpe no mesmo quadro (%s)" % [r])
```

(`_linha_do_tempo` é da F01; já está na prova. A contagem mínima de
`arrastado_na_ladeira` (4 entre 30 e 60 s) espera o robô por lugar.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### O que o André joga e sente

**O André (local):** `./run-local.sh -- --sala=S01_J02` com quatro
controles: o passo sai no bumbo, alternar os polegares é natural, o tropeço
faz rir, a ladeira pesa no meio, e o passo no metal soa em cada controle.

- na contagem, o glifo pisca esquerdo, direito, esquerdo, direito, e o pulso
  chega à mão do mesmo lado;
- o passo no metal se sente na mão do pé que pisou;
- o tombo na ladeira: o escudeiro desliza deitado para trás e o controle bate
  `golpe` junto com a imagem;
- na ladeira, o motor da esquerda pesa a cada tempo, e quem lidera pisa em
  engrenagens soltas.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a
cada 2 s): os quadros da contagem (o glifo), os de 32 a 58 s (um escudeiro
deitado atrás da linha dos outros; as engrenagens caídas), o de 62 s (a linha
de chegada) e o de 60 s (a ordem na esteira, anotada aqui na ficha).

### Ao terminar

- `godot/scripts/minigames/catalogo.gd`: `"S01_J02": preload("res://scripts/minigames/s01/marcha_dos_escudeiros.gd")`
  em `MINIGAMES` e `"S01_J02"` na lista `minigames` da S01, depois do `"S01_J01"`.
- `godot/scripts/traducoes.gd`: `"Marcha dos Escudeiros": "March of the Squires"`,
  `"Marche!": "March!"` em `EN`; `["^(\\d+) m$", "$1 m"]` em `EN_PADROES`.
- `"$GODOT" --headless --path godot --import --quit`; o `.uid` no commit.
- No [quadro](README.md), a linha I2 **feito**, com o commit
  (se as linhas dos minigames ainda não existem, a I1 diz como pôr).
- Commit (sem trailer): `feat: a Marcha dos Escudeiros — os analógicos alternados no bumbo`
