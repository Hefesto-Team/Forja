# I5 — A Esteira de Escória

**Sprint:** I · **Slot:** S01_J05 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, I1 (o `secao.gd` e o `momento`), G03, G05, G14, G15

## Por quê

Prensar é apertar o botão que o lingote pede, na sua vez — e roubar é
apertar o mesmo botão no lingote do outro, antes dele e mais certeiro: os
três botões de face, pedidos e respondidos por todos ao mesmo tempo, com a
esteira dizendo de quem é a vez.

## Ler antes

- [O kit do minigame, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) (o `minigame.gd`)
- [O índice da seção](I-a-centelha.md) (as convenções da seção)
- [I1, a cena](I1-o-martelo-de-hefesto.md#a-cena) (o `secao.gd` inteiro, que esta ficha só chama)

O resto (a linha n.º 5 em 03, a régua da diversão, a bíblia de arte, o mapa do
áudio, o RPG) está copiado nesta ficha, com os números. Não abra outro
documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s01/esteira_de_escoria.gd` | novo, o arquivo inteiro (abaixo) | só desta |
| `godot/scripts/minigames/s01/secao.gd` | nada: só chama | **da seção**: a I1 cria; nenhuma outra reescreve |
| `godot/scripts/minigames/catalogo.gd` | `"S01_J05"` em `MINIGAMES` e na lista da S01 | **de todos**: I1 a I5 põem a sua linha |
| `godot/scripts/traducoes.gd` | as linhas de «Ao terminar» | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_da_esteira()` e as checagens dos momentos | **de todos** |

O `.uid` novo (`esteira_de_escoria.gd.uid`) sai do import:
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
põe; ela grava `x_tela` e `altura_tela`). Até a I1 entrar, esta ficha espera.

## Como se joga

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J05",
	"titulo": "A Esteira de Escória",
	"verbo": "Prense!",
	"genero": "sabotagem",
	"icone": "botoes",
	"entradas": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO],
	"camera": "fixa",
	"faixa": "MUS_S01_J05",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "metal",
	"microjogo": {"verbo": "Prense!", "segundos": 6.0},
}
```

### As regras

- **A faixa:** `MUS_S01_J05`; até a H05, a sintetizada a 108 bpm; com a
  gerada, 125 bpm («fábrica, bigorna e ar comprimido»). Um compasso ≈ 2,2 s
  (108) ou 1,9 s (125).
- **A esteira e a prensa:** uma esteira só, da esquerda para a direita
  (de x = −11 ao fosso, em 9,6), passa por baixo de uma prensa no meio. Os
  lingotes andam 2 m por tempo e ficam debaixo da prensa exatamente na
  batida deles. Cada lingote tem **a cor do dono** e, em cima, **o glifo do
  botão** do compasso: ✕, ○, □, ✕, ○, □… (`[CRUZ, CIRCULO, QUADRADO][c % 3]`,
  `c = floor(b / 4)`).
- **A pista:** o lingote do dono acende (a emissão na cor dele, 1,2) 1
  tempo + a pista (o Faro, de −40 a +40 ms, e a Lanterna, meio tempo) antes
  da prensa.
- **O hoqueto em colcheias:** o lingote do lugar `l` passa na batida
  `2k + 0,5·l`. Dois por compasso para cada um; um a cada meio tempo na
  esteira. `Ritmo.simples[l]`: um a cada 4 tempos.
- **Prensar o seu:** o botão do lingote, com ele debaixo da prensa →
  `julgar_toque`. Outro botão, na janela do seu → erro. A janela do dono é
  `± (JANELA_BOM + 0,05 s)`; o lingote passou sem prensa → nota perdida, e
  ele cai no fosso.
- **Roubar o do outro:** apertar o botão certo de um lingote que **não é
  seu** a no máximo `JANELA_OTIMO` (90 ms) da batida dele, **antes** do
  dono → o lingote troca de cor, ganha uma listra na cor do dono antigo e
  vai para a pilha do ladrão; para o dono, é nota perdida (roubado). Um
  aperto fora de qualquer janela, ou o botão errado num roubo, **emperra a
  sua alavanca** por 2 tempos × o Fôlego: o seu lingote que passar nesse
  tempo cai no fosso (sem erro no registro: foi a prensa travada).
- **O lingote de ouro:** nas últimas 16 batidas, um por compasso, no tempo 3
  (`b = 4c + 2`), de ninguém, com o glifo △. Qualquer um aperta △ a até
  `JANELA_BOM` (140 ms) da batida; o mais perto leva (no empate, o lugar
  menor), e o ouro salta para a pilha dele, **conta 2** e brilha até o fim.
  Ninguém apertou: cai no fosso. △ fora da janela emperra.
- **Os pontos por julgamento** (ERRO, BOM, ÓTIMO, PERFEITO): `[0, 20, 35, 50]`;
  o roubo +30; o ouro +50. Cada lingote prensado ou roubado conta 1 na
  pilha; o de ouro, 2.
- **A coroa:** em cima da pilha do líder (mais lingotes), uma coroa pequena:
  o alvo fica claro para quem está atrás.
- **A progressão:** `andamento()` do kit (em tempo de música, H08). De 0 a
  1/3, as colcheias. **O pico (1/3 a 2/3), a esteira dobra:** o lingote de
  cada um passa em todo tempo (`k + 0,25·l`), um a cada quarto de tempo na
  esteira, e o ar comprimido sopra faísca na prensa. De 2/3 em diante, as
  colcheias e, nas últimas 16 batidas, o ouro. Lingotes de cada um em 90 s:
  ~70 a 108 bpm, ~85 a 125 bpm.

### A falha

O lingote escapa e cai no fosso: ele segue a esteira até a ponta (x = 9,6)
e despenca (`position.y` até −1,5 em meio tempo, e some); o dono faz
`emote-no`. Roubado: o lingote salta da esteira para a pilha do ladrão, com
a listra do dono antigo, e o dono faz `emote-no` e sente `golpe`.
Emperrado: faíscas `Tema.TUNGSTENIO` na alavanca, o controle bate `erro`, e
ela fica de pé por 2 tempos × o Fôlego.

### O fim e o vencedor

90 s (a F03). `vencedor()`: mais lingotes na pilha; empate pelos pontos,
depois pelo lugar. O ouro conta 2 na pilha.

**O lingote de ouro é o momento** `lingote_de_ouro`: na colcheia seguinte ao
fim da janela, a prensa a 130 % e de volta em meia batida (o degrau golpe),
a faísca mostarda (`Tema.SECAO[3]`, 30) e o sino; o controle de quem levou
bate `explosao` (120 ms) e, 240 ms depois, `perfeito` (120 ms). Os quatro
apertam ao mesmo tempo: a sala grita no resultado.

### Com menos de quatro

A esteira fica mais vazia (só os lingotes de quem está); nada mais muda.
Sozinho, não há de quem roubar: o jogo é prensar os seus. **O controle que
cai:** os lingotes dele já na esteira passam e caem no fosso sem erro, e
nenhum novo nasce enquanto ele está sem controle; ao voltar, o próximo nasce
na próxima batida dele pelo menos 1 tempo adiante. O ouro passa igual (um por compasso); sozinho,
ele é de quem apertar △ na janela.

### O robô

Prensa os seus na batida (ou 200 ms atrasado, quando não acerta). Tenta
roubar um lingote a cada seis que passam (os de índice `(i + l) % 6 == 0`):
consulta `Forja.robo_acerta()` e, se acerta, aperta 30 ms antes da batida
do outro. No lingote de ouro, todos apertam △ (quando acertam) a
`MIRA_OURO[(l + c) % 4]` da batida: 0, 10, 20 ou 30 ms, e quem fica mais
perto roda a cada compasso.

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var agora := Ritmo.t_musica()
	for ing in lingotes:
		if str(ing.estado) != "vindo" or bool(ing.get("robo_" + str(l), false)):
			continue
		var alvo := Ritmo.t_da_batida(float(ing.b))
		if bool(ing.get("ouro", false)):
			# o ouro: todos tentam; quem fica mais perto roda a cada compasso
			var mira: float = MIRA_OURO[(l + int(floor(float(ing.b) / 4.0))) % 4]
			if agora >= alvo + mira:
				if Forja.robo_acerta():
					Forja.robo_apertar(l, Forja.TRIANGULO, 0.05)
				ing["robo_" + str(l)] = true
			continue
		if int(ing.dono) == l:
			if not ing.has("mira"):
				# o temperamento (--robo=bom|medio|ruim): quando não acerta, 200 ms atrasado
				ing["mira"] = 0.0 if Forja.robo_acerta() else 0.20
			if agora >= alvo + float(ing.mira):
				Forja.robo_apertar(l, int(ing.botao), 0.05)
				ing["robo_" + str(l)] = true
		elif (int(ing.i) + l) % 6 == 0 and agora >= alvo - 0.03 and agora < alvo:
			if Forja.robo_acerta():
				Forja.robo_apertar(l, int(ing.botao), 0.05)
			ing["robo_" + str(l)] = true
```

### O código

`godot/scripts/minigames/s01/esteira_de_escoria.gd`:

```gdscript
extends Minigame
## A Esteira de Escória (S01_J05). Uma esteira passa por baixo de uma prensa;
## cada lingote tem a cor do dono e o glifo do botão do compasso, e fica
## debaixo da prensa na batida do dono (o hoqueto em colcheias). O botão
## certo na sua vez prensa o seu; o mesmo botão no lingote do outro, antes
## dele e a menos de 90 ms, rouba. No meio, a esteira dobra. Nas últimas 16
## batidas, o lingote de ouro (△, de ninguém) passa no tempo 3 de cada
## compasso: o mais perto da batida leva, e ele conta 2.
##
## A falha: o lingote escapa e cai no fosso; roubado, salta para a pilha do
## outro; o aperto à toa emperra a alavanca por 2 tempos.
## O vencedor: mais lingotes (o de ouro conta 2); no empate, mais pontos.
## O alto-falante do dono: o carimbo no acerto, a nota no perfeito, a coleta no roubo.
## O registro mede: cada botão pedido e dado (o kit), o botão que chegou no
## lugar do pedido, os roubos, os emperros e a disputa do ouro (a linha
## `entrada`), e os momentos `lingote_de_ouro` e `reta`.
## O robô: prensa os seus na batida; tenta roubar um em seis, 30 ms antes do dono;
## aperta △ no ouro, com quem fica mais perto rodando a cada compasso.
## Com menos de quatro: a esteira fica mais vazia.
## A régua: "Prense!" e o glifo no lingote bastam; sem a tela, a nota do lugar
## na TV marca a vez de cada um; nada pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const BOTOES := [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO]
const GLIFO := {Forja.CRUZ: "cross", Forja.CIRCULO: "circle", Forja.QUADRADO: "square",
	Forja.TRIANGULO: "triangle"}
const VELOCIDADE := 2.0  ## m por tempo
const X_FOSSO := 9.6  ## a ponta da esteira, dentro do quadro da câmera de arena
const ADIANTE := 6.0  ## tempos: o lingote nasce tantos tempos antes da prensa
const PONTOS := [0, 20, 35, 50]
const ROUBO := 30
const EMPERRA := 2.0  ## tempos × o Fôlego
const OURO := 2  ## o lingote de ouro conta 2 na pilha
const OURO_PONTOS := 50
const MIRA_OURO := [0.0, 0.01, 0.02, 0.03]  ## o robô no ouro: quem fica mais perto roda a cada compasso
const FOLGA := 0.05
const Z_ESTEIRA := -1.2

var j := {}
var lingotes: Array = []  ## {i, b, dono, botao, n, estado ("vindo", "prensado", "roubado", "caiu"), no, glifo}
var _i := 0  ## o índice do próximo lingote
var _ing: Dictionary = {}  ## o lingote em julgamento (para toque/falha)
var _roubo := false  ## a falha em curso é um roubo
var _bloco: Node3D
var _travessas: Array = []
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var cena := {}  ## o que o SECAO.montar devolveu
var _adiados: Array = []  ## o que cai na próxima colcheia (SECAO.adiar)
var _ultimo_ouro := -1.0  ## a batida do último lingote de ouro
var _reta_marcada := false
var _coroa: Node3D  ## em cima da pilha do líder


func montar() -> void:
	# a arena: 50°, a 17,5 m de (0, 0.6, −1.4); a esteira de x = −10 a 9,6 cabe inteira
	cena = SECAO.montar(self, Vector3(0, 0.6, -1.4), 17.5, SECAO.CAMERA_ANGULO)
	var ferro := Kit.material(Tema.GRAFITE, 0.0, 0.7)
	# a esteira vai de x = −11 até o fosso (9,6)
	Kit.caixa(self, Vector3(20.6, 0.3, 1.2), Vector3(-0.7, 0.15, Z_ESTEIRA), Kit.material(Tema.TINTA, 0.0, 0.9))
	for k in 21:
		_travessas.append(Kit.caixa(self, Vector3(0.1, 0.05, 1.1), Vector3(-11.0 + k, 0.32, Z_ESTEIRA), ferro))
	for x in [-1.2, 1.2]:
		Kit.peca(self, "column", Vector3(x, 0, Z_ESTEIRA))
	_bloco = Kit.caixa(self, Vector3(1.6, 1.0, 1.4), Vector3(0, 2.2, Z_ESTEIRA), ferro)
	Kit.caixa(self, Vector3(1.6, 0.1, 1.6), Vector3(X_FOSSO, -0.05, Z_ESTEIRA), Kit.material(Tema.TINTA, 0.0, 1.0))
	var brasa := OmniLight3D.new()
	brasa.position = Vector3(X_FOSSO, -0.6, Z_ESTEIRA)
	brasa.light_color = Tema.SECAO[0]
	brasa.light_energy = 1.2
	brasa.omni_range = 3.0
	add_child(brasa)
	# a coroa do líder: um aro e três pontas, em bloco
	_coroa = Node3D.new()
	_coroa.visible = false
	add_child(_coroa)
	var ouro := Tema.neon(Tema.TUNGSTENIO, 1.6, "forja")
	Kit.caixa(_coroa, Vector3(0.36, 0.06, 0.2), Vector3.ZERO, ouro)
	for x in [-0.14, 0.0, 0.14]:
		Kit.caixa(_coroa, Vector3(0.06, 0.12, 0.06), Vector3(x, 0.09, 0), ouro)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var alavanca := Kit.caixa(self, Vector3(0.1, 0.8, 0.1), Vector3(RAIAS[l] + 0.6, 0.4, Z_JOGADOR - 0.6), ferro)
		maos_livres(p)
		p.position = Vector3(RAIAS[l], 0.05, Z_JOGADOR)
		p.olhar_para(Vector3(RAIAS[l], 0, Z_ESTEIRA))
		j[l] = {"prox_b": -1.0, "n": 0, "pilha": 0, "emperrado_ate": -1.0, "fora": false, "alavanca": alavanca}
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)


func _proxima_batida(l: int, b: float) -> float:
	var passo := 2.0
	var desloc := 0.5 * l
	if Ritmo.simples[l]:
		passo = 2.0  # o kit dobra o passo na partitura simples
	elif no_pico():
		passo = 1.0
		desloc = 0.25 * l
	return proxima_batida(l, b, passo, desloc)  # o kit (H08): a próxima depois de b


func iniciar_jogo() -> void:
	for l in presentes():
		j[l].prox_b = _proxima_batida(l, BATIDA_DA_PRIMEIRA_NOTA - 0.01)


## Um lingote novo do lugar na batida b (nasce ADIANTE tempos antes, à esquerda).
func _nascer(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	var botao: int = BOTOES[int(floor(b / 4.0)) % 3]
	var no := Kit.caixa(self, Vector3(0.6, 0.2, 0.3), Vector3(-12.0, 0.4, Z_ESTEIRA),
		Kit.material(Forja.cor_do_lugar(l).darkened(0.3), 0.0, 0.8))
	var glifo := Sprite3D.new()
	glifo.texture = Desenho.glifo(GLIFO[botao])
	glifo.pixel_size = 0.004
	glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glifo.shaded = false
	glifo.position = Vector3(0, 0.5, 0)
	no.add_child(glifo)
	lingotes.append({"i": _i, "b": b, "dono": l, "botao": botao, "n": int(e.n), "estado": "vindo", "no": no, "glifo": glifo})
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))
	e.n = int(e.n) + 1
	_i += 1


func jogar(_dt: float) -> void:
	SECAO.passar(self, cena, no_pico())
	SECAO.rodar_adiados(_adiados)
	var agora_b := Ritmo.batida()
	var agora := Ritmo.t_musica()
	if not _reta_marcada and fase == "jogo" and SECAO.na_reta(self):
		_reta_marcada = true
		var valores := PackedStringArray(presentes().map(func(x): return str(int(j[x].pilha))))
		momento("reta", -1, Vector3(0, 0, -3.2), 1.0, {"objeto": "pilhas", "valores": ",".join(valores)})
	# o ouro: nas últimas 16 batidas, um por compasso, no tempo 3 (b = 4c + 2), ADIANTE tempos antes
	var b_fim := agora_b + (duracao - tempo_jogado()) * Ritmo.bpm / 60.0
	var desde := maxf(_ultimo_ouro + 1.0, b_fim - SECAO.BATIDAS_DA_RETA)
	var b_ouro := 4.0 * ceilf((desde - 2.0) / 4.0) + 2.0
	if b_ouro < b_fim and b_ouro <= agora_b + ADIANTE:
		_nascer_ouro(b_ouro)
		_ultimo_ouro = b_ouro
	# os lingotes nascem ADIANTE tempos antes da batida deles
	for l in presentes():
		var e: Dictionary = j[l]
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			e.prox_b = _proxima_batida(l, agora_b + 1.0)
		while float(e.prox_b) > 0.0 and float(e.prox_b) <= agora_b + ADIANTE:
			_nascer(l, float(e.prox_b))
			e.prox_b = _proxima_batida(l, float(e.prox_b))
	# os apertos: o seu lingote, um roubo, ou a alavanca emperra
	for l in presentes():
		if not conectado(l):
			continue
		for b in BOTOES:
			if Forja.apertou(l, b):
				_apertou(l, b, agora)
				break
		if Forja.apertou(l, Forja.TRIANGULO):
			_apertou_ouro(l, agora)
	# os que passaram sem prensa
	for ing in lingotes:
		if str(ing.estado) != "vindo" or agora <= Ritmo.t_da_batida(float(ing.b)) + Ritmo.JANELA_BOM + FOLGA:
			continue
		if bool(ing.get("ouro", false)):
			_resolver_ouro(ing)
			continue
		var dono: int = ing.dono
		ing.estado = "caiu"
		if conectado(dono) and not _emperrou_na_hora(dono, ing):
			_ing = ing
			_roubo = false
			nota_perdida(dono, int(ing.n))
	_mostrar()


## A alavanca estava emperrada quando o lingote passou (então não é erro do registro).
func _emperrou_na_hora(dono: int, ing: Dictionary) -> bool:
	return float(ing.b) < float(j[dono].emperrado_ate)


func _apertou(l: int, botao: int, agora: float) -> void:
	# 1. o seu lingote, na janela do dono
	for ing in lingotes:
		if str(ing.estado) != "vindo" or int(ing.dono) != l:
			continue
		var alvo := Ritmo.t_da_batida(float(ing.b))
		if absf(agora - alvo) <= Ritmo.JANELA_BOM + FOLGA:
			if Ritmo.batida() < float(j[l].emperrado_ate):
				return  # a alavanca está emperrada: o aperto não sai
			_ing = ing
			_roubo = false
			ing.estado = "prensado"
			if botao == int(ing.botao):
				julgar_toque(l, alvo, int(ing.n))
			else:
				anotar("entrada", l, {"o": "botao", "pedido": GLIFO[int(ing.botao)], "chegou": GLIFO[botao], "n": int(ing.n)})
				nota_perdida(l, int(ing.n))
			return
	# 2. o lingote de outro, antes do dono e a menos de JANELA_OTIMO
	for ing in lingotes:
		if str(ing.estado) != "vindo" or int(ing.dono) == l:
			continue
		var alvo2 := Ritmo.t_da_batida(float(ing.b))
		if absf(agora - alvo2) <= Ritmo.JANELA_OTIMO and botao == int(ing.botao):
			_roubar(l, ing)
			return
	# 3. à toa: emperra
	_emperrar(l, botao)


func _roubar(l: int, ing: Dictionary) -> void:
	var dono: int = ing.dono
	ing.estado = "roubado"
	anotar("entrada", l, {"o": "botao", "roubou_de": dono, "n": int(ing.n)})
	marcar(l, ROUBO)
	if not treinando:
		j[l].pilha = int(j[l].pilha) + 1
	Forja.sentir(l, "perfeito")
	Forja.som_falante(l, "coleta", 0.8)
	Som.tocar("golpe", Vector3(0, 1.0, Z_ESTEIRA), -4.0)
	_prensar_a_vista()
	(ing.no as MeshInstance3D).material_override = Kit.material(Forja.cor_do_lugar(l).darkened(0.3), 0.0, 0.8)
	# a listra na cor do dono antigo: na pilha do ladrão, todos veem de quem ele roubou
	Kit.caixa(ing.no, Vector3(0.62, 0.06, 0.08), Vector3(0, 0, 0.13), Tema.neon(Forja.cor_do_lugar(dono), 1.2, dono))
	_para_a_pilha(ing, l)
	if conectado(dono):
		_ing = ing
		_roubo = true
		nota_perdida(dono, int(ing.n))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	marcar(l, PONTOS[julgamento])
	if not treinando:
		j[l].pilha = int(j[l].pilha) + 1
	if julgamento != Ritmo.PERFEITO:
		Som.no_controle(l, "carimbo", 0.5)
	Som.tocar("martelo", Vector3(0, 1.0, Z_ESTEIRA), -4.0)
	_prensar_a_vista()
	if not _ing.is_empty():
		_para_a_pilha(_ing, l)
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.35 / SECAO.gancho(l, "velocidade"))  # o Passo (G03): só o gesto


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
	if _roubo:
		Forja.sentir(l, "golpe")
	elif not _ing.is_empty():
		_ing.estado = "caiu"  # segue até o fosso (o _mostrar derruba)


## A prensa desce e sobe (0,15 s).
func _prensar_a_vista() -> void:
	var tw := _bloco.create_tween()
	tw.tween_property(_bloco, "position:y", 1.0, 0.06)
	tw.tween_property(_bloco, "position:y", 2.2, 0.09)
	if no_pico():
		Efeitos.faiscas(self, Vector3(0, 0.6, Z_ESTEIRA), Tema.TUNGSTENIO, 10, 0.5)


## O lingote salta da prensa para a pilha do lugar.
func _para_a_pilha(ing: Dictionary, l: int) -> void:
	var no: MeshInstance3D = ing.no
	(ing.glifo as Node3D).visible = false
	var k := int(j[l].pilha)
	var ate := Vector3(RAIAS[l] + 0.55 * (k % 5) - 1.1, 0.1 + 0.2 * int(k / 5.0), -3.2)
	var de := no.position
	var voo := func(q: float) -> void:
		var pos := de.lerp(ate, q)
		pos.y += sin(q * PI) * 1.2
		no.position = pos
	var tw := no.create_tween()
	tw.tween_method(voo, 0.0, 1.0, 0.35)
	no.scale = Vector3(0.85, 0.9, 0.85)


func _mostrar() -> void:
	var agora_b := Ritmo.batida()
	for ing in lingotes.duplicate():
		var no: MeshInstance3D = ing.no
		var x := (agora_b - float(ing.b)) * VELOCIDADE
		match str(ing.estado):
			"vindo":
				no.position = Vector3(x, 0.4, Z_ESTEIRA)
				no.visible = x > -10.0
				# a pista: o lingote do dono acende 1 tempo + a pista (o Faro e a Lanterna) antes da prensa
				var dono := int(ing.dono)
				if dono >= 0 and not bool(ing.get("aceso", false)) \
						and agora_b >= float(ing.b) - 1.0 - SECAO.antecedencia(dono) * Ritmo.bpm / 60.0:
					ing["aceso"] = true
					Tema.emissivo(no.material_override, 1.2, dono)
			"caiu":
				no.position.x = minf(x, X_FOSSO)
				if x >= X_FOSSO:
					no.position.y = 0.4 - clampf((x - X_FOSSO) / VELOCIDADE * 2.0, 0.0, 1.0) * 1.9
				if x >= X_FOSSO + VELOCIDADE:
					no.queue_free()
					lingotes.erase(ing)
			"prensado", "roubado":
				if x > VELOCIDADE * 2.0:
					lingotes.erase(ing)  # o nó fica na pilha
	for k in _travessas.size():
		(_travessas[k] as Node3D).position.x = -11.0 + fposmod(k + agora_b * VELOCIDADE, 20.6)
	for l in presentes():
		var alav: Node3D = j[l].alavanca
		alav.rotation.z = 0.0 if agora_b < float(j[l].emperrado_ate) else 0.5
	# a coroa vai sobre a pilha do líder (ninguém lidera com a pilha vazia)
	var ordem := vencedor()
	var lider: int = int(ordem[0]) if not ordem.is_empty() else -1
	_coroa.visible = lider >= 0 and int(j[lider].pilha) > 0
	if _coroa.visible:
		_coroa.position = Vector3(RAIAS[lider], 0.15 + 0.2 * (int(int(j[lider].pilha) / 5.0) + 1), -3.2)


func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(_antes)
	return lista


func _antes(a: int, b: int) -> bool:
	if int(j[a].pilha) != int(j[b].pilha):
		return int(j[a].pilha) > int(j[b].pilha)
	if int(pontos[a]) != int(pontos[b]):
		return int(pontos[a]) > int(pontos[b])
	return a < b


func status(lugar: int) -> String:
	if na_raia(lugar) and j.has(lugar):
		return "Lingotes: %d" % int(j[lugar].pilha)
	return super(lugar)



## O lingote de ouro (△, de ninguém) na batida b: nasce ADIANTE tempos antes,
## à esquerda, como os outros; qualquer um prensa.
func _nascer_ouro(b: float) -> void:
	var no := Kit.caixa(self, Vector3(0.6, 0.2, 0.3), Vector3(-12.0, 0.4, Z_ESTEIRA),
		Kit.material(Tema.SECAO[3], 1.2, 0.4, "forja"))
	var glifo := Sprite3D.new()
	glifo.texture = Desenho.glifo(GLIFO[Forja.TRIANGULO])
	glifo.pixel_size = 0.004
	glifo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glifo.shaded = false
	glifo.position = Vector3(0, 0.5, 0)
	no.add_child(glifo)
	lingotes.append({"i": _i, "b": b, "dono": -1, "botao": Forja.TRIANGULO, "n": -1, "estado": "vindo",
		"no": no, "glifo": glifo, "ouro": true, "candidatos": {}})
	_i += 1


## △: o lingote de ouro. Dentro de ±JANELA_BOM da batida dele, o aperto entra
## na disputa (vale o primeiro de cada um); fora, emperra a alavanca.
func _apertou_ouro(l: int, agora: float) -> void:
	if Ritmo.batida() < float(j[l].emperrado_ate):
		return  # a alavanca está emperrada: o aperto não sai
	for ing in lingotes:
		if str(ing.estado) != "vindo" or not bool(ing.get("ouro", false)):
			continue
		var d := absf(agora - Ritmo.t_da_batida(float(ing.b)))
		if d <= Ritmo.JANELA_BOM:
			var cand: Dictionary = ing.candidatos
			if not cand.has(l):
				cand[l] = d
				anotar("entrada", l, {"o": "botao", "ouro": snappedf(d, 0.001)})
			return
	_emperrar(l, Forja.TRIANGULO)


## A janela do ouro fechou: o mais perto da batida leva (no empate, o lugar
## menor) e ele conta 2 na pilha; ninguém apertou, ele cai no fosso.
func _resolver_ouro(ing: Dictionary) -> void:
	var cand: Dictionary = ing.candidatos
	if cand.is_empty():
		ing.estado = "caiu"
		return
	var l := -1
	for k in cand:
		if l < 0 or float(cand[k]) < float(cand[l]) or (float(cand[k]) == float(cand[l]) and int(k) < l):
			l = int(k)
	ing.estado = "prensado"
	ing.dono = l
	marcar(l, OURO_PONTOS)
	if not treinando:
		j[l].pilha = int(j[l].pilha) + OURO
	Som.tocar("martelo", Vector3(0, 1.0, Z_ESTEIRA), -4.0)
	_prensar_a_vista()
	# o ouro brilha na pilha do dono até o fim (o rastro)
	(ing.no as MeshInstance3D).material_override = Kit.material(Tema.SECAO[3], 2.4, 0.4, "forja")
	_para_a_pilha(ing, l)
	SECAO.adiar(_adiados, _ouro.bind(l))


## O momento `lingote_de_ouro`, na colcheia seguinte à janela: a prensa a
## 130 % (o degrau golpe), a faísca mostarda, o sino; o controle de quem levou
## bate `explosao` 120 ms e, 240 ms depois, `perfeito` 120 ms.
func _ouro(l: int) -> void:
	SECAO.exagero(self, cena, "golpe", jogador(l), _bloco)
	Efeitos.faiscas(self, Vector3(0, 0.8, Z_ESTEIRA), Tema.SECAO[3], 30, 1.0)
	Som.tocar("sino", Vector3(0, 1.0, Z_ESTEIRA), -4.0)
	Forja.som_falante(l, "coleta", 0.8)
	Forja.sentir(l, "explosao", 120)
	var depois := create_tween()  # morre com a sala; nunca um create_timer com função da sala
	depois.tween_interval(0.24)
	depois.tween_callback(Forja.sentir.bind(l, "perfeito", 120))
	momento("lingote_de_ouro", l, Vector3(0, 0.4, Z_ESTEIRA), 1.6, {"pilha": int(j[l].pilha)})


## O aperto à toa emperra a alavanca do lugar por 2 tempos × o Fôlego.
func _emperrar(l: int, botao: int) -> void:
	j[l].emperrado_ate = Ritmo.batida() + SECAO.queda_s(l, EMPERRA) * Ritmo.bpm / 60.0
	anotar("entrada", l, {"o": "botao", "emperrou": true, "chegou": GLIFO[botao]})
	Forja.sentir(l, "erro")
	Efeitos.faiscas(self, Vector3(RAIAS[l] + 0.6, 0.9, Z_JOGADOR - 0.6), Tema.TUNGSTENIO, 14, 0.6)
```

### O que o registro mede

- O kit: uma `nota` por lingote de cada um (nasce 6 tempos antes: o
  `t_alvo` é a batida da prensa) e um `toque` por prensada (ou `perdida`).
- A linha `entrada`: o botão que chegou no lugar do pedido, os roubos (de
  quem) e os emperros (o botão à toa). Com os três botões de face apertados
  por quatro pessoas ao mesmo tempo, um botão que troca com outro, ou que
  chega no controle vizinho, aparece aqui. A disputa do ouro: `ouro` com a
  distância à batida, de cada um que apertou △ na janela.
- A linha `momento`: `lingote_de_ouro` (o lugar de quem levou, a `pilha`, o
  `x_tela` e a `altura_tela`) e `reta` (uma vez, de todos, com `objeto`
  `pilhas` e `valores`, a pilha de cada lugar).

### Armadilhas

- **`_ing` e `_roubo` antes de `julgar_toque`/`nota_perdida`:** o kit chama
  `toque`/`falha` sem dizer qual lingote; eles leem daqui.
- **O lingote que passou com a alavanca emperrada** cai sem `nota_perdida`
  (não é erro de ritmo); o registro fica com a `nota` sem `toque` — o
  cruzamento lê a `entrada` do emperro logo antes.
- **Apagar da lista, não do mundo:** o lingote prensado vira peça da pilha;
  só o que caiu no fosso some (`queue_free`).
- **Iterar numa cópia** (`lingotes.duplicate()`) quando apaga no laço.
- **O dono ainda aperta depois do roubo:** o lingote não está mais `vindo`,
  então o aperto vai para o roubo/emperro — está certo: ele perdeu a vez.
- **Material por lingote:** `Kit.material` cria um material novo a cada
  lingote (uns 300 no minigame). Se a prancha mostrar menos de 55 fps, guarde
  um material por lugar num dicionário.
- **O ouro não tem dono nem nota:** `dono` −1 e `n` −1, sem `nova_nota`;
  o kit não julga. A disputa é do minigame: a janela é ±`JANELA_BOM`, o
  primeiro aperto de cada um vale, e o resultado sai depois de
  `JANELA_BOM + FOLGA`. O momento cai na colcheia seguinte (`SECAO.adiar`).
- **O ouro é △, só dele:** ✕, ○ e □ nunca o pegam; o △ fora da janela
  emperra. Quem tem um lingote na mesma batida (o P1, no tempo 3) aperta
  os dois botões.
- **O brilho do ouro é da forja:** `Kit.material(Tema.SECAO[3], 2.4, 0.4,
  "forja")` (o mostarda com a emissão `Tema.TUNGSTENIO`). O `Tema.neon`
  com dono lugar ignora a cor e acusa erro (G15).
- **A coroa lê o `vencedor()`** a cada quadro: quatro lugares, barato.
- **Nenhum `Color("#…")` nem `Tema.LARANJA`, `Tema.AMARELO`:** o ferro
  `Tema.GRAFITE`, a esteira e o fosso `Tema.TINTA`, a brasa
  `Tema.SECAO[0]`, as faíscas `Tema.TUNGSTENIO` (G14, G15).

## A cena

### A câmera

A câmera de arena do cinema, fixa: lente de 35 mm (FOV vertical 37,8°),
50° abaixo da horizontal. `SECAO.montar(self, Vector3(0, 0.6, -1.4), 17.5,
SECAO.CAMERA_ANGULO)` a põe em `(0, 14,01, 9,85)` olhando `(0, 0,6, −1,4)`.
A esteira de x = −10 ao fosso (9,6) cabe inteira: x_tela de 0,06 a 0,92
(com os 40° de hoje, até a G05) ou de 0,03 a 0,95 (com os 35 mm); o
prensador de x = ±6 fica em 0,20 e 0,80, e as quatro pilhas cabem. O `lerp`
do main faz o caminho.

- **O pico:** a câmera recua 10 % (a 19,3 m) e volta ao sair.
- **O tremor é do evento:** só o do ouro (`SECAO.exagero`, golpe: 0,02 m por
  1 batida, o cavaleiro parado 2 quadros). Roll zero.

### A luz da seção

S1 é o vermelhão (`Tema.SECAO[0]`, `#c8432f`), lado A.
`Tema.luz_da_secao(1)` (G15; S1, lado A: `lado_b` false) devolve a névoa `#210502`, o preenchimento
`#602016` e a chave `#ffc99c`. O `SECAO.montar` da I1 põe o preenchimento (o
`atmosfera`, com as brasas), a chave (`OmniLight3D` em `(0, 8, 3)`, energia
0,9, alcance 26) e a fornalha do fundo (`Tema.TUNGSTENIO`, 1,4, alcance 8, em
`(0, 1,2, −6)`). No pico, o `SECAO.passar` sobe a chave e a fornalha 20 % em
1 batida e as devolve em 2 (com `Opcoes.flashes` desligado: +10 % em 2
batidas).

- **A brasa do fosso:** uma `OmniLight3D` `Tema.SECAO[0]`, energia 1,2,
  alcance 3, em `(9,6, −0,6, −1,2)`, embaixo do fosso.

### As peças e o papel de cada uma

`cena = SECAO.montar(self, Vector3(0, 0.6, -1.4), 17.5, SECAO.CAMERA_ANGULO)`
e, no meio da forja, a fábrica:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a esteira | `Kit.caixa(20.6, 0.3, 1.2)`, `Tema.TINTA`; 21 travessas `Kit.caixa(0.1, 0.05, 1.1)`, `Tema.GRAFITE`, a cada 1 m, que andam pela batida | centro `(−0.7, 0.15, −1.2)`: de x = −11 a 9,6 |
| a prensa | dois `column` em `x = ±1.2`; o bloco `Kit.caixa(1.6, 1.0, 1.4)`, `Tema.GRAFITE`, que desce a cada prensa (0,15 s) | `(0, 2.2, −1.2)` |
| o fosso | `Kit.caixa(1.6, 0.1, 1.6)`, `Tema.TINTA`, e a brasa embaixo | `(9.6, −0.05, −1.2)` |
| o lingote | `Kit.caixa(0.6, 0.2, 0.3)`, a cor do dono `darkened(0.3)` (o do ladrão, quando roubado), que acende 1 tempo + a pista antes; o glifo do botão num `Sprite3D` 0,5 m acima | `x = (batida − b) × 2`, `(x, 0.4, −1.2)`; visível de `x = −10` a `x = 9.6` |
| a listra do roubo | `Kit.caixa(0.62, 0.06, 0.08)`, `Tema.neon(cor do dono antigo, 1.2, dono)` | no lingote roubado, `(0, 0, 0.13)` |
| o lingote de ouro | o mesmo lingote, `Kit.material(Tema.SECAO[3], 1.2, 0.4, "forja")`, o glifo △; na pilha, 2,4 | na esteira como os outros; depois, na pilha do dono |
| a raia | `raia(l)` | `(RAIAS[l], 0, Z_JOGADOR)` |
| a alavanca | `Kit.caixa(0.1, 0.8, 0.1)`, `Tema.GRAFITE`, inclinada; de pé e com faíscas `Tema.TUNGSTENIO` quando emperra | `(RAIAS[l] + 0.6, 0.4, Z_JOGADOR − 0.6)` |
| a pilha | os lingotes do lugar, a 85 %, empilhados de 5 em 5 | `(RAIAS[l] + 0.55·(k % 5) − 1.1, 0.1 + 0.2·(k / 5), −3.2)` |
| a coroa | um aro `Kit.caixa(0.36, 0.06, 0.2)` e três pontas `Kit.caixa(0.06, 0.12, 0.06)`, `Tema.neon(Tema.TUNGSTENIO, 1.6, "forja")` | em cima da pilha do líder, `(RAIAS[l], 0.15 + 0.2·(pilha / 5 + 1), −3.2)` |
| o prensador | o boneco, de frente para a esteira | `(RAIAS[l], 0.05, Z_JOGADOR)`, olhando `(RAIAS[l], 0, −1.2)` |

A cor dos lugares só nos lingotes deles, nas listras e nas raias. Tudo em
caixa.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08, arte/04) |
| o lingote que vem (a pista) | o lugar | `Tema.emissivo(m, 1.2, dono)` de 1 tempo + a pista antes da prensa |
| a listra do roubo | o dono antigo | `Tema.neon(cor, 1.2, dono)` |
| o lingote de ouro | a forja | 1,2 na esteira; 2,4 na pilha, até o fim |
| a coroa | a forja | `Tema.neon(Tema.TUNGSTENIO, 1.6, "forja")` |
| as faíscas do ouro | a forja | `Tema.SECAO[3]`, 30 partículas |
| as faíscas da prensa no pico e da alavanca | a forja | `Tema.TUNGSTENIO`, 10 e 14 |
| a brasa do fosso | a forja | luz, não material |

Nenhuma cor fora dos tokens: o ferro `#4a4e5e`, a esteira `#2a2233`, o fosso
`#140f1a`, a brasa `#ff6a2a`, o `Tema.LARANJA` e o `Tema.AMARELO` de hoje
somem desta sala.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| prensar o seu | a nota do lugar (o kit) e `Som.tocar("martelo", prensa, -4.0)` | perfeito: a nota (o kit); ótimo e bom: `Som.no_controle(l, "carimbo", 0.5)` | `martelo_0..4`; `mod_nota_p1..p4`, `carimbo_0..4` |
| o roubo | `Som.tocar("golpe", prensa, -4.0)` | o ladrão: `Forja.som_falante(l, "coleta", 0.8)`; o roubado: a nota quebrada (o kit) | `golpe_0..4`; `mod_coleta`, `mod_nota_quebrada_p1..p4` |
| o lingote no fosso | — | a nota quebrada (o kit) | `mod_nota_quebrada_p1..p4` |
| o lingote de ouro | `Som.tocar("martelo", prensa, -4.0)` e, na colcheia, `Som.tocar("sino", prensa, -4.0)` | `Forja.som_falante(l, "coleta", 0.8)` | `martelo_0..4`, `sint_sino`; `mod_coleta` |
| a faixa | `MUS_S01_J05`: 125 BPM; até ela existir, a sintetizada da H05 a 108 | — | `mus_s01_j05` |

- **O alto-falante toca um som por vez** e o julgamento tem a vez.
- **Nenhum bipe de falha:** o lingote cai em silêncio; o roubo soa como
  metal (`golpe`).
- **O mapa diverge:** o `sint_sino` lista N1 e O4, não a I5; o diretor de
  som acrescenta (o som existe e está no jogo).

## O controle

Evento por evento. O piso é o da F05.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| começar | todos | — | R2 `GATILHO_OFF`; o L2 nunca (é do item, G03) | a cor do lugar | — |
| prensar o seu | o dono | `acerto`/`perfeito` (o kit); a háptica `metal` (o kit) | — | o kit: branco 0,15 s no perfeito | a nota ou o `carimbo` 0,5 |
| roubar | o ladrão | `Forja.sentir(l, "perfeito")` | — | — | `coleta` 0,8 |
| ser roubado | o dono | `erro` (o kit) e `golpe` (1,0 / 0,6, 250 ms) | — | o kit: a cor escurecida 0,5 s | a nota quebrada |
| o lingote no fosso | o dono | `erro` (o kit) | — | o kit: a cor escurecida 0,5 s | a nota quebrada |
| emperrar | quem apertou à toa | `Forja.sentir(l, "erro")` | — | — | — |
| levar o ouro | quem levou | `Forja.sentir(l, "explosao", 120)` e, 240 ms depois, `Forja.sentir(l, "perfeito", 120)` | — | — | `coleta` 0,8 |

- A barra de luz é **sempre a cor do lugar**. O microfone não se usa. **Os
  outros não sentem nada** do que é de um: o roubo bate no ladrão e no
  roubado, e só neles.
- **Sem o controle na mão:** o robô aperta pelo relógio da música; a prova
  confere que cada `lingote_de_ouro` tem a sua `sensacao` `explosao` no
  mesmo quadro.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo
que a pessoa escolheu aparecem como estão, de costas para a câmera, de
frente para a esteira. Cada parte tem a sua faixa de valor e um acento de néon só, na cor do
lugar (arte/04, «A peça se distingue»): a cabeça humana sem acento (a de
raça, o visor ou a rachadura, até 6 %), o friso do superior (até 8 % da
parte, energia 1,6), a costura do inferior (até 5 %, 1,6); somados, no
máximo 8 % da frente do corpo. O contorno é de 0,012, energia 2,4 no jogo. `maos_livres(p)`: a arma ou o amuleto não
aparece na Esteira, mas o efeito do item vale. O cavaleiro pode ser de outra raça (o Orc, o Autômato de latão, o Golem de
escória, a Raposa ferreira; a raça é só aparência): esta ficha não supõe
corpo humano; usa o esqueleto comum de 7 ossos e as animações
`attack-melee-right` (a prensa), `emote-no` (o fosso e o roubo) e `idle`;
vale para qualquer raça.

| stat | gancho | o que muda na Esteira | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: ninguém empurra | — | — | — |
| Passo | `velocidade` | só o gesto da prensa (0,35 s / velocidade); a nota não muda | 0,372 s | 0,35 s | 0,330 s |
| Fôlego | `levantar` | quanto tempo a alavanca fica emperrada | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | o lingote acende antes; ele passa na prensa no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); a Lanterna acende
o lingote meio tempo antes (`Itens.antecipacao_s`); a Âncora não age (só
mexe na corrida); o Martelo dobra o perfeito no tempo forte (o kit); o Fole
e o Diapasão agem no combo pelo kit. Os números da régua: nenhum stat muda a
janela de julgamento nem a do roubo ou do ouro; o stat 5 nunca tira o
emperro.

## As reações

- **Carimbos que a Esteira pode disparar** (todos são do kit e do HUD, G04;
  a Esteira não chama nenhum): `car_em_chamas` (5 Ressonâncias seguidas do
  mesmo lugar), `car_por_um_fio` (o vencedor por 2 % dos pontos ou menos).
  `car_acorde` não acontece: no hoqueto, cada meio tempo tem um dono (o
  ouro é disputa, não acorde). O `car_virada` é do placar.
- **Adesivos:** ninguém está fora da rodada na Esteira, então ninguém manda adesivo
  durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

Nota de hoje 4; com o lingote de ouro, o alvo é 5.

**O momento: o lingote de ouro** (`lingote_de_ouro`). Nas últimas 16
batidas, um lingote de ouro, de ninguém, passa pela prensa a cada compasso
(no tempo 3). Qualquer um pode prensar com △; o mais perto da batida leva, e
o lingote salta para a pilha dele com faísca dourada. Os quatro apertam ao
mesmo tempo: a sala grita no resultado. Degrau golpe: a prensa a 130 %.
O grito do resto do minigame é o roubo (o lingote do outro salta para a
pilha do ladrão); o robô já rouba 1 a cada 6.

- **Rastro:** o lingote de ouro fica na pilha do dono, brilhando (2,4), até
  o fim; o roubado guarda a listra do dono antigo.
- **A curva:** de 0 a 30 s, as colcheias, e o primeiro roubo do robô; de 30
  a 60 s, a esteira dobra (um lingote por tempo para cada um) e o ar
  comprimido sopra faísca; de 60 s ao fim, as colcheias e, nas últimas 16
  batidas, o ouro.
- **Ensina sem falar:** o lingote tem a cor do dono e o glifo do botão em
  cima, e acende antes da prensa. O roubo se aprende vendo: o robô rouba no
  primeiro terço, o lingote troca de cor no ar, e a sala entende que pode.
- **Quem está perdendo:** a listra mostra quem roubou de quem; a coroa em
  cima da pilha do líder diz a todos quem é o alvo; o ouro vale 2 e é de
  quem estiver mais perto da batida, não de quem lidera.
- **O que se corta:** nada.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3
`medio`, P4 `ruim`, semente 7, sem a bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | os quadros de 2 a 10 s mostram os lingotes coloridos na esteira |
| 3. ensina sem falar | a coleta de texto da F02 na fase de jogo só acha o verbo, os nomes, os P#, o placar e o julgamento | um quadro do primeiro terço mostra um lingote roubado no ar, com a listra |
| 4. o momento | 4 linhas `momento` `lingote_de_ouro` nas últimas 16 batidas (`t_musica` ≥ 80), pelo menos 2 com lugares diferentes | o último quadro tem lingotes de ouro em 2 ou mais pilhas |
| 5. a curva | notas por segundo entre 30 e 60 s ≥ 1,8 × as de 0 a 30 s; a linha `momento` `reta` existe uma vez | o quadro de 45 s mostra a esteira cheia e a câmera mais longe |
| 6. a falha | o P4 tem pelo menos 8 linhas `toque` com `erro` | o quadro seguinte a um roubo mostra o lingote listrado na pilha do ladrão |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `lingote_de_ouro` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | o fosso e as quatro pilhas cabem no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `lingote_de_ouro`, uma linha `sensacao` `explosao` do mesmo lugar a até 16,7 ms, a até 1 quadro de uma colcheia | — |
| 10. o placar no mundo | o primeiro de `vencedor()` tem a maior `pilha` no fim, e a coroa está sobre ele | no último quadro, quem olha diz o vencedor pela altura das pilhas e pela coroa |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na
régua) existir, a prova roda com `--robo=medio` nos quatro e confere os itens 1, 3, 5, 8, 9 e 10;
os itens 4 (a mesa padrão), 6 e 7 (que pedem o P4 `ruim`) esperam o robô por lugar.

## Pronto quando

A Esteira joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos (o bom rouba, o ruim emperra); o cabo que cai e volta
não gera erro para quem saiu; o fim tem sempre vencedor;
`bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh` passa
com a prancha **olhada** nas partidas em que a Esteira aparece. Além disso: cada ouro grava `lingote_de_ouro` a até 1
quadro de uma colcheia, com a sua `sensacao` `explosao`, só nas últimas 16
batidas; a linha `momento` `reta` aparece uma vez; e nenhuma cor fora dos
tokens sobra no `esteira_de_escoria.gd`
(`grep -nE 'Color\("#|Tema\.(ROSA|AMARELO|TRILHO|CIANO|ROXO|LARANJA|FG)\b'`
não acha nada).

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S01_J05 (I5): a Esteira abre pelo catálogo; cada lugar prensa lingotes
## pelo botão simulado; o fim tem vencedor pela pilha.
func _prova_da_esteira() -> void:
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (90 s de música e o treino)
	var mg = await _joga_o_minigame("S01_J05", 130.0)
	if mg == null:
		return
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "S01_J05 P%d: prensou o seu %s" % [l + 1, c])
	var v: Array = mg.vencedor()
	_esperar(int(mg.j[v[0]].pilha) >= int(mg.j[v[v.size() - 1]].pilha), "S01_J05: o vencedor tem a maior pilha")
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J05: de volta ao salão")
```

Ainda na `_prova_da_esteira()`, antes de esperar o salão, os momentos (a
régua):

```gdscript
	var todas := _linha_do_tempo()
	var linhas := todas.filter(func(e): return e.get("slot") == "S01_J05")
	var momentos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "lingote_de_ouro")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "S01_J05: a linha momento reta aparece uma vez")
	for r in momentos:
		_esperar(float(r.get("x_tela", 0.0)) >= 0.2 and float(r.get("x_tela", 0.0)) <= 0.8 \
			and float(r.get("altura_tela", 0.0)) >= 0.08, "S01_J05: o momento no meio da tela (%s)" % [r])
		var t := float(r.get("t_musica", 0.0))
		# a sensacao (F05) não leva slot: procura em todas, perto no relógio da sessão (t)
		var sente := todas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "explosao" \
			and int(e.get("lugar", -9)) == int(r.get("lugar", -1)) \
			and absf(float(e.get("t_musica", -9.0)) - t) <= 0.0167 \
			and absf(float(e.get("t", -9.0)) - float(r.get("t", 0.0))) <= 1.0)
		_esperar(not sente.is_empty(), "S01_J05: o momento tem a sensação explosao no mesmo quadro (%s)" % [r])
	for r in momentos:
		_esperar(float(r.get("t_musica", 0.0)) >= 80.0, "S01_J05: o ouro só nas últimas 16 batidas (%s)" % [r])
```

(`_linha_do_tempo` é da F01; já está na prova. Os 4 ouros com 2 donos
diferentes pedem a mesa padrão: esperam o robô por lugar.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### O que o André joga e sente

**O André (local):** `./run-local.sh -- --sala=S01_J05` com quatro pessoas:
a esteira na cor de cada um se lê de longe, o roubo dá grito, o emperro
segura quem aperta à toa, e a esteira dobrada do meio é o caos.

- o lingote de cada um acende antes da prensa;
- o roubo deixa a listra do dono antigo na pilha do ladrão;
- nas últimas 16 batidas, o ouro: os quatro apertam △ e o controle de quem
  levou bate `explosao` e `perfeito` junto com a faísca;
- a coroa troca de pilha quando o líder muda.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a
cada 2 s): os de 2 a 10 s (os lingotes coloridos), um do primeiro terço com
um roubo no ar, o de 45 s (a esteira cheia e a câmera mais longe) e o último
(o ouro em 2 ou mais pilhas e a coroa, anotado aqui na ficha).

### Ao terminar

- Catálogo: `"S01_J05": preload("res://scripts/minigames/s01/esteira_de_escoria.gd")`
  em `MINIGAMES` e na lista da S01.
- `traducoes.gd`: `"A Esteira de Escória": "The Slag Conveyor"`, `"Prense!": "Press!"`;
  em `EN_PADROES`, `["^Lingotes: (\\d+)$", "Ingots: $1"]`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a I5 **feito**, com o commit.
- Commit (sem trailer): `feat: A Esteira de Escória — prensar na sua vez, roubar antes do dono`
