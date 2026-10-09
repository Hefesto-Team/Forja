# I4 — O Fole

**Sprint:** I · **Slot:** S01_J04 · **Tamanho:** M · **Depende de:** H04, H08, F09, F03, F05, H07, I1 (o `secao.gd` e o `momento`), G03 (o L2 é do item), G05, G14, G15

## Por quê

A profundidade do R2 é a altura da nota: cada um afunda o gatilho até o
ponto da sua nota, no tempo dela, e a forja só pega fogo se os quatro
fecham o acorde — o curso analógico do gatilho, medido nota a nota, com a
resistência dizendo ao dedo onde fica o seu ponto.

## Ler antes

- [O kit do minigame, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) (o `minigame.gd`)
- [O índice da seção](I-a-centelha.md) (as convenções da seção)
- [I1, a cena](I1-o-martelo-de-hefesto.md#a-cena) (o `secao.gd` inteiro, que esta ficha só chama)

O resto (a linha n.º 4 em 03, a F03 do `coop`, a régua da diversão, a bíblia
de arte, o mapa do áudio, o RPG) está copiado nesta ficha, com os números.
Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s01/o_fole.gd` | novo, o arquivo inteiro (abaixo) | só desta |
| `godot/scripts/minigames/s01/secao.gd` | nada: só chama | **da seção**: a I1 cria; nenhuma outra reescreve |
| `godot/scripts/minigames/catalogo.gd` | `"S01_J04"` em `MINIGAMES` e na lista da S01 | **de todos**: I1 a I5 põem a sua linha |
| `godot/scripts/traducoes.gd` | as linhas de «Ao terminar» | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_fole()` e as checagens dos momentos | **de todos** |

O `.uid` novo (`o_fole.gd.uid`) sai do import:
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

O `coop` (F03, pelo kit): o gênero `coop` da FICHA liga `coop`; a sala põe
`coop_venceu = true` quando o grupo vence; o kit grava `vencedor` −1 e a tela
diz «Todos venceram!» ou «A forja apagou.»; o destaque sai de `destaque()`.

## Como se joga

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S01_J04",
	"titulo": "O Fole",
	"verbo": "Sopre a forja!",
	"genero": "coop",
	"icone": "gatilhos",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S01_J04",
	"duracao": 80.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "explosao"],
	"material": "madeira",
	"microjogo": {"verbo": "Sopre!", "segundos": 6.0},
}
```

### As regras

- **A faixa:** `MUS_S01_J04`; até a H05, a sintetizada a 108 bpm; com a
  gerada, 115 bpm («notas longas, filtro abrindo»). Um compasso ≈ 2,2 s
  (108) ou 2,1 s (115).
- **A altura de cada um:** a faixa do R2 onde mora a nota do lugar: P1 0,30,
  P2 0,48, P3 0,66, P4 0,84, cada uma com ±0,07 (a nota mais funda é a mais
  aguda, como o dó-ré-fá-sol do kit). O R2 de cada um tem a **resistência
  começando na sua faixa**: `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA,
  POS_FEEDBACK[l], 4)`, com `POS_FEEDBACK = [2, 4, 5, 7]` (de 0 a 9) e força
  4. Sem olhar, o dedo sente onde é.
- **O fole que se vê:** cada cavaleiro tem um fole grande ao lado (escala
  1,6); a abertura do fole é o curso do R2 dele. Na régua do lado, um anel na
  cor do dono marca a altura da nota e **acende 1 tempo + a pista antes
  dela** (0,4 apagado, 1,5 aceso). Todo mundo vê quem está fundo demais.
- **O hoqueto em semínimas:** a nota do lugar `l` é a batida `4c + l`; os
  quatro, um por tempo, são o acorde do compasso. `Ritmo.simples[l]`: uma
  nota a cada 2 compassos.
- **A nota:** o R2 **entra** na faixa (vindo de baixo); o instante é o toque
  (`julgar_toque`). Entrar mais de meio tempo antes não conta. Passar da
  faixa no mesmo quadro (afundou demais) é erro. **A nota longa**, fora do
  pico: segurar dentro da faixa até 1 tempo depois da batida (±0,02 de
  folga); soltar antes quebra o acorde, sem erro. **No pico, basta entrar na
  faixa no tempo** (quem entrou antes da batida fica até ela). Nada entrou
  até `FOLGA_PERDIDA` depois → nota perdida.
- **A chama** (0 a 1, de todos): cada acerto soma `[0, 0,005, 0,009, 0,012]`
  (ERRO, BOM, ÓTIMO, PERFEITO) vezes `4 / presentes`; o erro tira 0,01; **o
  acorde fecha** (todos os presentes com controle acertaram e seguraram a
  nota do compasso que acabou) → +0,02, e **+0,04 nas últimas 16 batidas**;
  a cada compasso a chama perde 0,004, e **0,012 de 2/3 em diante** (o vento
  entra pela porta). Chegou a 1: **a forja chega ao branco**.
- **O acorde que fecha se sente:** o R2 de cada um vibra por 1 compasso a
  partir da faixa dele (`GATILHO_VIBRACAO`, `POS_FEEDBACK[l]`, amplitude 3,
  40 Hz) e volta à resistência.
- **Os pontos por julgamento** (os do soprador, para o destaque):
  `[0, 20, 35, 50]`, mais 15 por nota segurada até o fim.
- **A progressão:** `andamento()` do kit (em tempo de música, H08). De 0 a
  1/3, uma nota por compasso. **O pico (1/3 a 2/3), o fole duplo:** duas por
  compasso (`4c + 0,5·l` e `4c + 2 + 0,5·l`), sem nota longa; a chama cresce
  mais depressa e a música abre. **De 2/3 em diante, a reta:** uma por
  compasso, o vento entra pela porta (som e chama esfriando 3 vezes mais) e,
  nas últimas 16 batidas, o acorde vale o dobro. O fim é uma briga contra o
  vento. Um grupo que acerta dois terços chega ao branco entre 55 e 70 s.

### A falha

A chama engasga e cospe fumaça no rosto do soprador: faíscas `Tema.GRAFITE`
(30, força 0,6) e uma nuvem em bloco (`Kit.caixa(0.45, 0.35, 0.35)`,
`Tema.GRAFITE`) na cabeça do boneco (1,7 m, até a G13 dar o ponto da
cabeça), que cresce a 140 % e some em 2 s; `p.gesto("emote-no", 0.5)`; a
chama perde 0,01 e o acorde daquele compasso não fecha. A próxima nota vem
no tempo de sempre. É coop: o erro é engraçado, não castiga.

### O fim e o vencedor

O `coop` vem do gênero da FICHA (o kit, H08). A chama em 1 → `coop_venceu =
true` e todos acabam (o fim da F03, com o jingle de vitória coop). Os 80 s de
música sem o branco → `coop_venceu` fica `false`: no `ao_terminar()`, a
chama encolhe a uma brasa. O registro grava `vencedor` −1 (coop: todos
venceram ou todos perderam); `destaque()` é o melhor soprador, pelos pontos,
empate pelo lugar.

**O branco é o momento** `branco`: na colcheia seguinte ao quadro em que a
chama chega a 1 (`SECAO.adiar`), a luz da seção sobe 40 % por 1 batida
(20 % sem flashes), os quatro cavaleiros são empurrados meio passo para trás
(0,5 m × o Peso, menos a Âncora, no mínimo 0,2 m, em meia batida), a forja
ruge (`sopro` a 0 dB) e a chama fica `Tema.ETIQUETA` até o fim; o controle de
cada um bate `explosao`. Só então todos acabam.

### Com menos de quatro

O acorde é o de quem está: com três, três notas por compasso (o tempo do
ausente fica mudo). O ganho de cada nota é `× 4 / presentes`, então o
branco chega no mesmo tempo com um, dois, três ou quatro. **O controle que
cai:** ele sai do acorde enquanto está sem controle (o acorde fecha com os
outros); ao voltar, o Feedback do R2 é mandado de novo e a nota da vez é o
próximo tempo dele.

### O robô

```gdscript
# O kit chama robo(l, dt) antes de jogar(dt), a cada quadro, de quem ainda joga.
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var e: Dictionary = j[l]
	if float(e.b) < 0.0:
		return
	if int(e.robo_n) != int(e.n):
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, entra 200 ms atrasado
		e.robo_n = int(e.n)
		e.robo_mira = 0.0 if Forja.robo_acerta() else 0.20
	var alvo := Ritmo.t_da_batida(float(e.b)) + float(e.robo_mira)
	var fim := Ritmo.t_da_batida(float(e.b) + _sustenta(l)) + 0.05
	var agora := Ritmo.t_musica()
	if agora < alvo - 0.03 or agora > fim:
		return  # solto: o gatilho volta sozinho ao repouso
	# afunda até o meio da faixa nos 30 ms antes da mira, e segura
	var v := lerpf(0.1, ALTURA[l], clampf((agora - (alvo - 0.03)) / 0.03, 0.0, 1.0))
	Forja.robo_eixo(l, Forja.R2, v, 0.06)
```

No pico, `_sustenta` é 0: o robô solta 50 ms depois da batida.

### O código

`godot/scripts/minigames/s01/o_fole.gd`:

```gdscript
extends Minigame
## O Fole (S01_J04). Os quatro sopram a mesma forja. A profundidade do R2 é a
## altura da nota: cada um afunda até a sua faixa, no seu tempo do compasso, e
## segura a nota longa; se os quatro fecham o acorde, a chama cresce. No meio,
## o fole duplo (basta entrar na faixa). De 2/3 em diante, o vento entra pela
## porta e a chama esfria 3 vezes mais; nas últimas 16 batidas, o acorde vale
## o dobro. A chama no branco: todos vencem.
##
## A falha: a chama engasga e cospe fumaça no rosto do soprador (2 s).
## O vencedor: coop — a forja no branco (todos) ou apagada; o destaque é o
## melhor soprador (os pontos).
## O alto-falante do dono: o tom no acerto, a nota no perfeito.
## O registro mede: a profundidade de cada nota (a linha `entrada`, com o
## valor do R2 na entrada e o menor e o maior durante a nota), cada nota e
## toque (o kit), a chama a cada compasso e os momentos `branco` e `reta`.
## O robô: afunda até o meio da faixa na nota e segura; quando não acerta,
## 200 ms atrasado.
## Com menos de quatro: o acorde é de quem está; o ganho compensa.
## A régua: "Sopre a forja!" e o R2 no aviso bastam; sem a tela, a
## resistência do R2 diz a altura e a nota de cada um na TV diz o tempo; o
## fole grande e o anel mostram a todos quem está fundo demais; nada
## pergunta pelo controle.

const SECAO := preload("res://scripts/minigames/s01/secao.gd")

# (a FICHA vem aqui)

const ALTURA := [0.30, 0.48, 0.66, 0.84]  ## o meio da faixa de cada lugar no R2
const MEIA_FAIXA := 0.07
const POS_FEEDBACK := [2, 4, 5, 7]  ## onde a resistência começa (0..9), na faixa de cada um
const FOLGA_SEGURAR := 0.02
const GANHO := [0.0, 0.005, 0.009, 0.012]  ## ERRO, BOM, OTIMO, PERFEITO
const PERDA_ERRO := 0.01
const ACORDE := 0.02
const ESFRIA := 0.004  ## por compasso
const ESFRIA_VENTO := 0.012  ## por compasso, de 2/3 em diante (o vento pela porta)
const ACORDE_NA_RETA := 0.04  ## nas últimas 16 batidas, o acorde fechado vale o dobro
const VIBRA_ACORDE := [3, 40]  ## o acorde fechado: o R2 vibra (amplitude 3, 40 Hz) por 1 compasso
const RECUO := 0.5  ## m: o bafo do branco empurra os quatro meio passo para trás
const RECUO_MIN := 0.2  ## o piso do recuo, com o Peso 5 e a Âncora
const FUMACA_S := 2.0  ## a fumaça cinza fica no rosto 2 s
const ESCALA_FOLE := 1.6  ## o fole grande, que a sala inteira lê
const PONTOS := [0, 20, 35, 50]
const SEGUROU := 15

var j := {}
var chama := 0.0
var _compasso_visto := -1
var _chama: Array = []  ## as cinco caixas da chama
var _luz_chama: OmniLight3D
var _fogo: AudioStreamPlayer3D
var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
var cena := {}  ## o que o SECAO.montar devolveu
var _adiados: Array = []  ## o que cai na próxima colcheia (SECAO.adiar)
var _branco_pedido := false  ## a chama chegou a 1: o branco cai na próxima colcheia
var _reta_marcada := false


func montar() -> void:
	# a arena: 50°, a 17 m de (0, 1, −1); o soprador de x = ±6 fica em x_tela 0,20 e 0,80
	cena = SECAO.montar(self, Vector3(0, 1.0, -1.0), 17.0, SECAO.CAMERA_ANGULO)
	Kit.caixa(self, Vector3(3.0, 0.8, 2.0), Vector3(0, 0.4, -2.5), Kit.material(Tema.GRAFITE, 0.0, 0.95))
	for x in [-1.8, 1.8]:
		Kit.peca(self, "rocks", Vector3(x, 0, -2.5), 0.0, 1.2)
	for k in 5:
		var lado := 1.2 - 0.2 * k
		_chama.append(Kit.caixa(self, Vector3(lado, 0.4, lado), Vector3(0, 1.0 + 0.4 * k, -2.5),
			Kit.material(Tema.SECAO[0], 1.2, 0.8, "forja")))
	_luz_chama = OmniLight3D.new()
	_luz_chama.position = Vector3(0, 2.0, -2.0)
	_luz_chama.omni_range = 9.0
	add_child(_luz_chama)
	_fogo = Som.laco("fogo", self, Vector3(0, 1.0, -2.5), -10.0)
	var ferro := Kit.material(Tema.GRAFITE, 0.0, 0.7)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		var x: float = RAIAS[l]
		var fole := Node3D.new()
		fole.position = Vector3(x, 0.3, 0.2)
		fole.scale = Vector3.ONE * ESCALA_FOLE
		add_child(fole)
		var madeira := Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)
		Kit.caixa(fole, Vector3(1.0, 0.08, 0.6), Vector3.ZERO, madeira)
		var tampa := Node3D.new()
		tampa.position = Vector3(0, 0.05, 0.3)  # a dobradiça atrás
		fole.add_child(tampa)
		Kit.caixa(tampa, Vector3(1.0, 0.08, 0.6), Vector3(0, 0, -0.3), madeira)
		var couro := Kit.caixa(fole, Vector3(0.9, 1.0, 0.5), Vector3(0, 0.1, 0), Kit.material(Tema.OXIDO, 0.0, 0.9))
		Kit.caixa(fole, Vector3(0.12, 0.12, 0.8), Vector3(0, 0.05, -0.7), ferro)
		var ate := Vector3(0, 0.2, -1.6)
		var de := Vector3(x, 0.3, 0.2 - 0.7 * ESCALA_FOLE)  # o meio do bico do fole grande
		var cano := Kit.caixa(self, Vector3(0.1, 0.1, de.distance_to(ate)), (de + ate) * 0.5, ferro)
		cano.rotation.y = atan2(ate.x - de.x, ate.z - de.z)
		var regua := Node3D.new()
		regua.position = Vector3(x + 1.1, 0.2, 0.6)  # fora do fole grande (meia largura 0,8)
		add_child(regua)
		Kit.caixa(regua, Vector3(0.16, 1.4, 0.04), Vector3(0, 0.7, 0), ferro)
		Kit.caixa(regua, Vector3(0.22, 1.4 * 2.0 * MEIA_FAIXA, 0.05), Vector3(0, 1.4 * ALTURA[l], 0),
			Tema.neon(Tema.TUNGSTENIO, 0.8, "forja"))
		var nivel := Kit.caixa(regua, Vector3(0.1, 1.0, 0.07), Vector3.ZERO, Tema.neon(Forja.cor_do_lugar(l), 1.6, l))
		# o anel na cor do dono, em volta do trilho, na altura da nota: todo mundo vê a nota de cada um
		var toro := TorusMesh.new()
		toro.inner_radius = 0.16
		toro.outer_radius = 0.2
		toro.rings = 8
		toro.ring_segments = 4
		var anel := MeshInstance3D.new()
		anel.mesh = toro
		anel.position = Vector3(0, 1.4 * ALTURA[l], 0)
		regua.add_child(anel)
		var anel_apagado := Tema.neon(Forja.cor_do_lugar(l), 0.4, l)
		var anel_aceso := Tema.neon(Forja.cor_do_lugar(l), 1.5, l)
		anel.material_override = anel_apagado
		maos_livres(p)
		p.position = Vector3(x, 0.05, Z_JOGADOR + 0.4)
		p.olhar_para(Vector3(0, 0, -2.5))
		j[l] = {"b": -1.0, "n": 0, "v_antes": 0.0, "dentro": false, "segurando": false, "min": 1.0, "max": 0.0,
			"entrou": 0.0, "ok_c": -1, "fora": false, "tampa": tampa, "couro": couro, "nivel": nivel,
			"robo_n": -1, "robo_mira": 0.0, "vibra_ate": -1.0, "anel": anel, "anel_aceso": anel_aceso,
			"anel_apagado": anel_apagado}


## Quantos tempos a nota longa dura. No pico, nenhum: basta entrar na faixa
## no tempo (a régua corta a nota longa de meio tempo).
func _sustenta(_l: int) -> float:
	return 0.0 if no_pico() else 1.0


func _proxima_batida(l: int, b: float) -> float:
	var passo := 4.0
	var desloc := float(l)
	if Ritmo.simples[l]:
		passo = 4.0  # o kit dobra o passo na partitura simples
	elif no_pico():
		passo = 2.0
		desloc = 0.5 * l
	return proxima_batida(l, b, passo, desloc)  # o kit (H08): a próxima depois de b


func _marcar_nota(l: int, b: float) -> void:
	var e: Dictionary = j[l]
	e.b = b
	e.segurando = false
	e.min = 1.0
	e.max = 0.0
	nova_nota(l, int(e.n), Ritmo.t_da_batida(b))


func iniciar_jogo() -> void:
	for l in presentes():
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, POS_FEEDBACK[l], 4)
		_marcar_nota(l, _proxima_batida(l, BATIDA_DA_PRIMEIRA_NOTA - 1.0))


func jogar(_dt: float) -> void:
	SECAO.passar(self, cena, no_pico())
	SECAO.rodar_adiados(_adiados)
	_vento()
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso_visto:
		if _compasso_visto >= 1:
			_fechar_o_compasso(_compasso_visto)
		_compasso_visto = c
	for l in presentes():
		var e: Dictionary = j[l]
		var v := Forja.eixo(l, Forja.R2)
		_mostrar(l, v)
		if acabou[l]:
			continue
		if not conectado(l):
			e.fora = true
			continue
		if bool(e.fora):
			e.fora = false
			Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, POS_FEEDBACK[l], 4)
			_marcar_nota(l, _proxima_batida(l, Ritmo.batida()))
		# o compasso do acorde vibrou: o R2 volta à resistência da faixa
		if float(e.vibra_ate) >= 0.0 and Ritmo.batida() >= float(e.vibra_ate):
			e.vibra_ate = -1.0
			Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, POS_FEEDBACK[l], 4)
		_nota(l, e, v)
	if chama >= 1.0 and not _branco_pedido:
		_branco_pedido = true
		SECAO.adiar(_adiados, _branco)  # o branco cai na próxima colcheia, com tudo junto
	_mostrar_a_chama()


func _nota(l: int, e: Dictionary, v: float) -> void:
	var lo: float = ALTURA[l] - MEIA_FAIXA
	var hi: float = ALTURA[l] + MEIA_FAIXA
	var alvo := Ritmo.t_da_batida(float(e.b))
	var agora := Ritmo.t_musica()
	var antes := float(e.v_antes)
	e.v_antes = v
	if bool(e.segurando):
		# a nota longa: segurar na faixa até o fim dela
		e.min = minf(float(e.min), v)
		e.max = maxf(float(e.max), v)
		if v < lo - FOLGA_SEGURAR or v > hi + FOLGA_SEGURAR:
			_fim_da_nota(l, false)
		elif Ritmo.batida() >= float(e.b) + _sustenta(l):
			_fim_da_nota(l, true)
		return
	if antes < lo and v >= lo and agora >= alvo - 0.5 * 60.0 / Ritmo.bpm:
		anotar("entrada", l, {"o": "gatilho", "lado": "R2", "entrou": snappedf(v, 0.01), "faixa": ALTURA[l], "n": int(e.n)})
		e.entrou = v
		if v > hi:
			nota_perdida(l, int(e.n))  # afundou demais de uma vez: a chama engasga
		else:
			julgar_toque(l, alvo, int(e.n))
	elif agora > alvo + FOLGA_PERDIDA:
		nota_perdida(l, int(e.n))


## A nota longa acabou: segurada até o fim (o acorde conta com ela) ou solta antes.
func _fim_da_nota(l: int, segurou: bool) -> void:
	var e: Dictionary = j[l]
	anotar("entrada", l, {"o": "gatilho", "lado": "R2", "min": snappedf(float(e.min), 0.01),
		"max": snappedf(float(e.max), 0.01), "segurou": segurou, "n": int(e.n)})
	if segurou:
		e.ok_c = int(floor(float(e.b) / 4.0))
		marcar(l, SEGUROU)
		Som.tocar("sopro", Vector3(RAIAS[l], 0.8, 0.0), -6.0)
	_seguinte(l)


func _seguinte(l: int) -> void:
	var e: Dictionary = j[l]
	e.n = int(e.n) + 1
	_marcar_nota(l, _proxima_batida(l, float(e.b)))


func toque(l: int, julgamento: int) -> void:
	contagem[l][julgamento] += 1
	var e: Dictionary = j[l]
	marcar(l, PONTOS[julgamento])
	if not treinando:
		chama = clampf(chama + GANHO[julgamento] * 4.0 / maxf(presentes().size(), 1.0), 0.0, 1.0)
	if julgamento != Ritmo.PERFEITO:
		Forja.som_falante(l, "tom", 0.5)
	var p := jogador(l)
	if p:
		p.gesto("interact-right", 0.4 / SECAO.gancho(l, "velocidade"))  # o Passo (G03): só o gesto
	e.segurando = true  # agora a nota longa


func falha(l: int) -> void:
	contagem[l][Ritmo.ERRO] += 1
	if not treinando:
		chama = maxf(0.0, chama - PERDA_ERRO)
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.5)
		_fumaca(p.global_position + Vector3(0, 1.7, 0))  # o rosto: 1,7 m até o ponto da cabeça da G13
	_seguinte(l)


## O compasso `c` acabou: o acorde fecha se todos os presentes com controle
## seguraram uma nota nele; e a chama esfria um pouco.
func _fechar_o_compasso(c: int) -> void:
	if treinando:
		return
	var todos := true
	var algum := false
	for l in presentes():
		if not conectado(l) or acabou[l]:
			continue
		algum = true
		if int(j[l].ok_c) != c:
			todos = false
	var fechou := algum and todos
	if fechou:
		# nas últimas 16 batidas, o acorde fechado vale o dobro
		chama = minf(1.0, chama + (ACORDE_NA_RETA if SECAO.na_reta(self) else ACORDE))
		Efeitos.faiscas(self, Vector3(0, 2.4, -2.5), Tema.TUNGSTENIO, 40, 1.2)
		for l in presentes():
			if conectado(l):
				Forja.sentir(l, "acerto")
				# o R2 vibra 1 compasso a partir da faixa do lugar e volta à resistência (no jogar)
				Forja.gatilho(l, 1, Forja.GATILHO_VIBRACAO, POS_FEEDBACK[l], VIBRA_ACORDE[0], VIBRA_ACORDE[1])
				j[l].vibra_ate = Ritmo.batida() + 4.0
	# de 2/3 em diante, o vento entra pela porta: a chama esfria 3 vezes mais
	chama = maxf(0.0, chama - (ESFRIA_VENTO if andamento() >= 2.0 / 3.0 else ESFRIA))
	anotar("entrada", -1, {"o": "chama", "valor": snappedf(chama, 0.01), "c": c, "acorde": fechou})


## A forja chegou ao branco (o momento `branco`), na colcheia seguinte ao
## quadro em que a chama chegou a 1: todos vencem. A luz da seção sobe 40 %
## por 1 batida (o degrau catástrofe), o bafo empurra os quatro meio passo
## para trás, a forja ruge e fica branca até o fim.
func _branco() -> void:
	coop_venceu = true
	SECAO.exagero(self, cena, "catastrofe")
	# o jogo acaba neste quadro e o SECAO.passar não roda mais: o tremor e a luz voltam pelo relógio
	var batida := 60.0 / Ritmo.bpm
	var volta := create_tween()
	volta.tween_interval(batida)
	volta.tween_callback(func(): (cena.chave as OmniLight3D).light_energy = float(cena.chave_energia))
	volta.tween_interval(3.0 * batida)
	volta.tween_callback(func(): tremor = 0.0)
	Som.tocar("sucesso", Vector3(0, 2.0, -2.5))
	Som.tocar("sopro", Vector3(0, 1.0, -2.5), 0.0)  # a forja ruge
	Efeitos.faiscas(self, Vector3(0, 3.0, -2.5), Tema.ETIQUETA, 80, 1.6)
	for l in presentes():
		var p := jogador(l)
		if p:
			# o Peso e a Âncora (G03) mudam o recuo, até o piso de 0,2 m
			var m := maxf(RECUO_MIN, RECUO * SECAO.gancho(l, "empurrao") * (1.0 - Itens.resiste_a_empurrao(l)))
			p.create_tween().tween_property(p, "position:z", p.position.z + m, 0.5 * batida) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		Forja.sentir(l, "explosao")
		acabou[l] = true
	momento("branco", -1, Vector3(0, 0, -2.5), 3.0, {"chama": snappedf(chama, 0.01)})


func ao_terminar() -> void:
	if not coop_venceu:
		chama = 0.05  # a forja apagou: fica a brasa
		_mostrar_a_chama()


func _mostrar_a_chama() -> void:
	# do vermelhão ao tungstênio com a chama; no branco, a etiqueta, até o fim
	var cor: Color = Tema.ETIQUETA if coop_venceu else Tema.SECAO[0].lerp(Tema.TUNGSTENIO, chama)
	for k in _chama.size():
		var caixa: MeshInstance3D = _chama[k]
		caixa.visible = k <= int(chama * 4.99)
		var m: StandardMaterial3D = caixa.material_override
		m.albedo_color = cor
		Tema.emissivo(m, 2.4 if coop_venceu else 1.2 + 1.2 * chama, "forja")
		caixa.position.y = 1.0 + 0.4 * k + 0.05 * sin(Ritmo.batida() * TAU + k)
	_luz_chama.light_color = cor
	_luz_chama.light_energy = 0.8 + 2.4 * chama
	if is_instance_valid(_fogo):
		_fogo.volume_db = -14.0 + 8.0 * chama


func _mostrar(l: int, v: float) -> void:
	var e: Dictionary = j[l]
	(e.tampa as Node3D).rotation.x = -0.45 * (1.0 - v)
	(e.couro as Node3D).scale.y = maxf(0.1, 1.0 - v)
	var nivel: MeshInstance3D = e.nivel
	nivel.scale.y = maxf(0.02, v * 1.4)
	nivel.position.y = v * 1.4 * 0.5
	# o anel acende 1 tempo + a pista (o Faro e a Lanterna) antes da nota e apaga quando ela acaba
	var antes := 1.0 + SECAO.antecedencia(l) * Ritmo.bpm / 60.0
	var aceso := not acabou[l] and float(e.b) >= 0.0 and Ritmo.batida() >= float(e.b) - antes
	(e.anel as MeshInstance3D).material_override = e.anel_aceso if aceso else e.anel_apagado


## Coop: o kit grava vencedor −1 (H08); o destaque é o melhor soprador.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1



## A fumaça no rosto do soprador: faíscas grafite e uma nuvem em bloco que
## cresce a 140 % e some em 2 s (o rastro da falha).
func _fumaca(pos: Vector3) -> void:
	Efeitos.faiscas(self, pos, Tema.GRAFITE, 30, 0.6)
	var nuvem := Kit.caixa(self, Vector3(0.45, 0.35, 0.35), pos, Kit.material(Tema.GRAFITE, 0.0, 1.0))
	var tw := nuvem.create_tween()
	tw.tween_property(nuvem, "scale", Vector3.ONE * 1.4, FUMACA_S)
	tw.tween_callback(nuvem.queue_free)


## A reta da forja: de 2/3 em diante o vento entra pela porta (a chama esfria
## 3 vezes mais). Marca o momento `reta` uma vez, com a chama e os pontos.
func _vento() -> void:
	if _reta_marcada or fase != "jogo" or andamento() < 2.0 / 3.0:
		return
	_reta_marcada = true
	Som.tocar("vento", Vector3(0, 1.5, 6.0), -8.0)
	var valores := PackedStringArray(presentes().map(func(x): return str(int(pontos[x]))))
	momento("reta", -1, Vector3(0, 0, -2.5), 3.0,
		{"objeto": "forja", "chama": snappedf(chama, 0.01), "valores": ",".join(valores)})
```

### O que o registro mede

- O kit: `nota` e `toque` (o instante em que o R2 entrou na faixa).
- A linha `entrada` duas vezes por nota: na entrada, o valor do R2 e a
  faixa pedida; no fim da nota, o menor e o maior valor durante a nota e se
  segurou. Cruzado depois da noite: um gatilho que nunca chega aos 0,84 do
  P4, que só dá solto e fundo (sem meio), ou que treme na nota longa.
- A linha `entrada` da chama, uma por compasso, de todos (`lugar` 0): `o`
  `chama`, o `valor` depois do compasso, o compasso `c` e se o acorde fechou.
- A linha `momento`: `branco` (uma vez, de todos, com a `chama`, o
  `x_tela` e a `altura_tela`) e `reta` (uma vez, quando o vento entra a
  2/3, com `objeto` `forja`, a `chama` e `valores`, os pontos de cada lugar).

### Armadilhas

- **O R2 é do minigame, o L2 é do item:** só `Forja.gatilho(l, 1, ...)`;
  nunca `gatilhos_off` (apagaria o Escudo do L2). O fim do kit
  (`Forja.silencio`) solta os dois — está certo.
- **Entrar, não estar:** a nota é o R2 **cruzar** a borda de baixo da faixa.
  Quem já está dentro antes da nota tem de soltar e entrar de novo.
- **O acorde fecha pelo compasso da nota** (`floor(b / 4)`), não pelo de
  agora: a nota do P4 no tempo 4 termina no compasso seguinte.
- **A chama não cresce no treino.** O `marcar` já não soma no treino.
- **Coop no fechamento** (H08): o registro grava `vencedor` −1 e a tela diz
  "Todos venceram!" ou "A forja apagou."; o destaque sai de `destaque()`.
  Ninguém liga o `coop` à mão: o kit tira do gênero.
- **O `Som.laco`** é um nó filho da sala: sai com ela; não o pare à mão.
- **O branco cai na colcheia** (`SECAO.adiar`) e só então todos acabam: o
  kit termina no mesmo quadro em que o último acaba, então o momento, a
  `explosao` e o bafo têm de sair antes. `_branco_pedido` impede que a
  chama em 1 peça o branco duas vezes.
- **Depois do branco o `SECAO.passar` não roda:** a luz e o tremor voltam
  por um tween da sala (`create_tween`), que morre com ela; nunca um
  `create_timer` com função da sala.
- **O acorde muda o R2 para vibração por 1 compasso** e o `jogar` o devolve
  à resistência. Só o R2 (`Forja.gatilho(l, 1, ...)`); o L2 é do item.
- **No pico, `_sustenta` é 0:** entrar na faixa basta; quem entrou antes
  da batida fica na faixa até ela.
- **A reta do Fole é o vento** (a 2/3, `andamento()`): o momento `reta` sai
  ali, porque o branco pode chegar antes das últimas 16 batidas. O
  `SECAO.na_reta` só dobra o acorde.
- **Nenhum `Color("#…")`, `Tema.TRILHO` nem `Tema.AMARELO`:** a madeira
  `Tema.OXIDO_BRILHO`, o couro `Tema.OXIDO`, o ferro `Tema.GRAFITE`, a
  chama do `Tema.SECAO[0]` ao `Tema.TUNGSTENIO` (G14, G15).

## A cena

### A câmera

A câmera de arena do cinema, fixa: lente de 35 mm (FOV vertical 37,8°),
50° abaixo da horizontal. `SECAO.montar(self, Vector3(0, 1.0, -1.0), 17.0,
SECAO.CAMERA_ANGULO)` a põe em `(0, 14,02, 9,93)` olhando `(0, 1, −1)`. A
fornalha, a chama inteira e os quatro foles cabem; o soprador de x = ±6 fica
em x_tela 0,20 e 0,80 (com os 40° de hoje, até a G05) ou 0,18 e 0,82 (com
os 35 mm); a régua do P4 (x = 7,1, z = 0,6) fica em 0,84 (40°) ou 0,86
(35 mm), dentro do quadro. O `lerp` do main faz o caminho.

- **O pico:** a câmera recua 10 % (a 18,7 m) e volta ao sair.
- **O tremor é do evento:** só o do branco (`SECAO.exagero`, catástrofe:
  0,08 m por 4 batidas). Roll zero.

### A luz da seção

S1 é o vermelhão (`Tema.SECAO[0]`, `#c8432f`), lado A.
`Tema.luz_da_secao(1)` (G15; S1, lado A: `lado_b` false) devolve a névoa `#210502`, o preenchimento
`#602016` e a chave `#ffc99c`. O `SECAO.montar` da I1 põe o preenchimento (o
`atmosfera`, com as brasas), a chave (`OmniLight3D` em `(0, 8, 3)`, energia
0,9, alcance 26) e a fornalha do fundo (`Tema.TUNGSTENIO`, 1,4, alcance 8, em
`(0, 1,2, −6)`). No pico, o `SECAO.passar` sobe a chave e a fornalha 20 % em
1 batida e as devolve em 2 (com `Opcoes.flashes` desligado: +10 % em 2
batidas).

- **A luz da chama:** uma `OmniLight3D` na cor da chama, energia
  `0.8 + 2.4·chama`, alcance 9, em `(0, 2, −2)`.
- **O branco:** a chave sobe 40 % por 1 batida (20 % sem flashes), pelo
  `SECAO.exagero(self, cena, "catastrofe")`; um tween da sala a devolve.

### As peças e o papel de cada uma

`cena = SECAO.montar(self, Vector3(0, 1.0, -1.0), 17.0, SECAO.CAMERA_ANGULO)`,
a fornalha comum no meio e, em cada raia, o fole:

| o quê | peça | onde (m) |
| --- | --- | --- |
| a fornalha | `Kit.caixa(3.0, 0.8, 2.0)`, `Tema.GRAFITE`; `rocks` (escala 1,2) dos dois lados | `(0, 0.4, −2.5)`; as pedras em `x = ±1.8` |
| a chama | cinco `Kit.caixa` empilhadas, de 1,2 a 0,4 m de lado e 0,4 de altura, `Kit.material(Tema.SECAO[0], 1.2, 0.8, "forja")`; a cor vai de `Tema.SECAO[0]` a `Tema.TUNGSTENIO` com a chama; a altura da pilha e o brilho sobem com ela | `(0, 1.0 + 0.4·k, −2.5)`, balançando 0,05 m na batida |
| a luz da chama | `OmniLight3D`, a cor da chama | `(0, 2.0, −2.0)` |
| a raia | `raia(l)` | `(RAIAS[l], 0, Z_JOGADOR)` |
| o fole | escala 1,6: duas tábuas `Kit.caixa(1.0, 0.08, 0.6)`, `Tema.OXIDO_BRILHO`; o couro `Kit.caixa(0.9, 1.0, 0.5)`, `Tema.OXIDO`, com a altura do vão; o bico `Kit.caixa(0.12, 0.12, 0.8)`, `Tema.GRAFITE` | `(RAIAS[l], 0.3, 0.2)`; a tampa gira `rotation.x = −0.45 × (1 − R2)` |
| o cano | `Kit.caixa(0.1, 0.1, comprimento)`, `Tema.GRAFITE` | do meio do bico `(RAIAS[l], 0.3, −0.92)` a `(0, 0.2, −1.6)` |
| a régua | o trilho `Kit.caixa(0.16, 1.4, 0.04)`, `Tema.GRAFITE`; a faixa da nota `Kit.caixa(0.22, 0.196, 0.05)`, `Tema.neon(Tema.TUNGSTENIO, 0.8, "forja")`; o nível `Kit.caixa(0.1, 1.0, 0.07)`, `Tema.neon(cor do lugar, 1.6, l)`, da altura do R2 | `(RAIAS[l] + 1.1, 0.2, 0.6)`; a faixa em `y = 1.4 × ALTURA[l]` |
| o anel | `TorusMesh` (raio 0,16 a 0,2, 8 anéis, 4 segmentos: em bloco), `Tema.neon(cor do lugar, 0.4, l)` apagado e `Tema.neon(cor, 1.5, l)` aceso | em volta do trilho, `y = 1.4 × ALTURA[l]` |
| a fumaça | `Kit.caixa(0.45, 0.35, 0.35)`, `Tema.GRAFITE`, a 140 % e some em 2 s | o rosto do soprador, 1,7 m |
| o soprador | o boneco, olhando a fornalha, mãos livres | `(RAIAS[l], 0.05, Z_JOGADOR + 0.4)` |

A chama é emissiva e em blocos; nada liso.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08, arte/04) |
| o nível da régua | o lugar | `Tema.neon(cor, 1.6, l)` |
| o anel da nota | o lugar | 0,4 apagado; 1,5 de 1 tempo + a pista antes da nota até ela acabar |
| a faixa da nota | a forja | `Tema.neon(Tema.TUNGSTENIO, 0.8, "forja")` |
| a chama | a forja | `Tema.emissivo(m, 1.2 + 1.2·chama, "forja")`; no branco, `Tema.ETIQUETA` e 2,4 |
| as faíscas do acorde | a forja | `Tema.TUNGSTENIO`, 40 partículas |
| as faíscas do branco | a forja | `Tema.ETIQUETA`, 80 partículas |
| a fumaça | ninguém | `Tema.GRAFITE`, sem brilho |
| a luz da chama | a forja | luz, não material |

Nenhuma cor fora dos tokens: o `#5a5270` da fornalha, o `#ff6a2a` e o
`#fff4e0` da chama, a madeira, o couro, o ferro, o cinza da fumaça, o
`Tema.TRILHO` e o `Tema.AMARELO` de hoje somem desta sala.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a nota que entra na faixa | a nota do lugar (o kit) | perfeito: a nota (o kit); ótimo e bom: `Forja.som_falante(l, "tom", 0.5)` | `mod_nota_p1..p4`, `mod_tom` |
| a nota segurada até o fim | `Som.tocar("sopro", (RAIAS[l], 0.8, 0), -6.0)` | — | `sint_sopro` |
| a falha (a fumaça) | — | a nota quebrada (o kit) | `mod_nota_quebrada_p1..p4` |
| o fogo | `Som.laco("fogo", self, (0, 1, −2.5), -10.0)`, de −14 a −6 dB com a chama | — | `sint_fogo` |
| o vento (a 2/3) | `Som.tocar("vento", (0, 1.5, 6.0), -8.0)` | — | `sint_vento` |
| o branco | `Som.tocar("sucesso", (0, 2, −2.5))` e `Som.tocar("sopro", (0, 1, −2.5), 0.0)` (a forja ruge) | — | `vitoria_sala_*` (`sint_sucesso`); `sint_sopro` |
| a faixa | `MUS_S01_J04`: 115 BPM; até ela existir, a sintetizada da H05 a 108 | — | `mus_s01_j04` |

- **O alto-falante toca um som por vez** e o julgamento tem a vez.
- **Nenhum bipe de falha:** a fumaça é a nota quebrada do próprio dono.
- **O mapa diverge:** o `sint_vento` não lista a I4 nas `fichas`; o diretor
  de som acrescenta (o som existe e está no jogo).

## O controle

Evento por evento. O piso é o da F05.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| começar e o controle que volta | o dono | — | R2 `GATILHO_RESISTENCIA` (`POS_FEEDBACK[l]`, 4); o L2 nunca (é do item, G03) | a cor do lugar | — |
| a nota que entra na faixa | o dono | `acerto`/`perfeito` (o kit); a háptica `madeira` (o kit) | a resistência diz onde parar | o kit: branco 0,15 s no perfeito | a nota ou o `tom` 0,5 |
| a falha (a fumaça) | o dono | `erro` (o kit) | — | o kit: a cor escurecida 0,5 s | a nota quebrada |
| o acorde fechado | todos os presentes com controle | `Forja.sentir(l, "acerto")` | R2 `GATILHO_VIBRACAO` (`POS_FEEDBACK[l]`, 3, 40) por 1 compasso; depois volta à resistência | — | — |
| o branco | todos | `explosao` (1 / 1, 400 ms) | — (o fim do kit solta os dois) | — | — |

- A barra de luz é **sempre a cor do lugar**. O microfone não se usa. **Os
  outros não sentem nada** do que é de um; o acorde e o branco são de todos.
- **As zonas da resistência** ficam como estão (`[2, 4, 5, 7]`); a F01 mede
  se `[2, 4, 6, 8]` casa melhor com as faixas e, se mudar, muda só a
  constante.
- **Sem o controle na mão:** o robô afunda o R2 pelo relógio da música; a
  prova confere que o `branco` tem a sua `sensacao` `explosao` no mesmo
  quadro.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo
que a pessoa escolheu aparecem como estão, de costas para a câmera, olhando
a fornalha. Cada parte tem a sua faixa de valor e um acento de néon só, na cor do
lugar (arte/04, «A peça se distingue»): a cabeça humana sem acento (a de
raça, o visor ou a rachadura, até 6 %), o friso do superior (até 8 % da
parte, energia 1,6), a costura do inferior (até 5 %, 1,6); somados, no
máximo 8 % da frente do corpo. O contorno é de 0,012, energia 2,4 no jogo. `maos_livres(p)`: a arma ou o amuleto não aparece no
Fole, mas o efeito do item vale. O cavaleiro pode ser de outra raça (o Orc, o Autômato de latão, o Golem de
escória, a Raposa ferreira; a raça é só aparência): esta ficha não supõe
corpo humano; usa o esqueleto comum de 7 ossos e as animações `interact-right` (o sopro),
`emote-no` (a fumaça) e `idle`; o recuo do branco move o boneco inteiro, sem
animação própria, e vale para qualquer raça. A fumaça fica a 1,7 m até a
G13 dar o ponto da cabeça de cada raça; a fuligem no rosto espera esse
ponto.

| stat | gancho | o que muda no Fole | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o recuo do bafo no branco | 0,58 m | 0,5 m | 0,42 m |
| Passo | `velocidade` | só o gesto do sopro (0,4 s / velocidade); a nota não muda | 0,426 s | 0,4 s | 0,377 s |
| Fôlego | `levantar` | não age: é coop e a nota seguinte vem no tempo de sempre; ninguém fica parado | — | — | — |
| Faro | `pista` | o anel acende antes; a nota cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03) e mora no L2, que o
Fole nunca toca; a Lanterna acende o anel meio tempo antes
(`Itens.antecipacao_s`); a Âncora corta o recuo do branco pela metade (até
o piso de 0,2 m); o Martelo dobra o perfeito no tempo forte (o kit); o Fole
e o Diapasão agem no combo pelo kit (o Diapasão puxa o combo da equipe no
coop). Os números da régua: nenhum stat muda a faixa nem a janela de
julgamento.

## As reações

- **Carimbos que o Fole pode disparar** (todos são do kit e do HUD, G04; o
  Fole não chama nenhum): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar). `car_por_um_fio` e `car_virada` não acontecem: é coop, sem
  vencedor por pontos. `car_acorde` não acontece: no hoqueto, cada tempo tem
  um dono (o acorde do Fole é a chama, não o carimbo).
- **Adesivos:** ninguém está fora da rodada no Fole, então ninguém manda adesivo
  durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

Nota de hoje 2; com o fole que se vê e o vento da reta, o alvo é 3: a sala
grita «mais fundo!» para quem está raso.

**O momento: a forja chega ao branco** (`branco`). A chama passa do
vermelhão ao tungstênio e ao branco, a luz da seção sobe 40 % por 1 batida,
os quatro cavaleiros são empurrados meio passo para trás pelo bafo e a forja
ruge. Degrau catástrofe ao contrário: a vitória.

- **Rastro:** a forja fica branca até o fim (a fuligem clara no rosto dos
  quatro espera o ponto da cabeça da G13).
- **A curva:** de 0 a 27 s, uma nota por compasso, um acorde por compasso;
  de 27 a 53 s, o fole duplo, duas notas por compasso e a chama mais rápida;
  de 53 s ao fim, o vento entra pela porta, a chama perde 0,012 por compasso
  e, nas últimas 16 batidas, o acorde vale o dobro.
- **Ensina sem falar:** a abertura do fole grande é o curso do R2, e o anel
  na cor do dono marca a altura da nota: todo mundo vê quem está fundo
  demais. A resistência do gatilho continua dizendo ao dedo onde parar.
- **Quem está perdendo:** é coop; quem erra cospe fumaça no próprio rosto
  (2 s) e o acorde daquele compasso não fecha. O destaque vai para o melhor
  soprador; quem errou mais tem a partitura simples.
- **O que se corta:** no pico, a nota longa de meio tempo com ±0,02 de folga
  no curso; basta entrar na faixa no tempo.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3
`medio`, P4 `ruim`, semente 7, sem a bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 | os quadros de 2 a 10 s mostram os foles abrindo e a chama subindo |
| 3. ensina sem falar | a coleta de texto da F02 na fase de jogo só acha o verbo, os nomes, os P#, o placar e o julgamento | em cada quadro de jogo, o anel de quem toca a seguir está aceso na régua |
| 4. o momento | mesa boa: a linha `momento` `branco` entre 45 e 70 s; mesa fraca: alguma linha `entrada` `chama` com `valor` > 0,7 | o último quadro da mesa boa mostra a forja branca |
| 5. a curva | notas por segundo entre 27 e 53 s ≥ 1,8 × as de 0 a 27 s; as linhas `entrada` `chama` de 2/3 em diante sem acorde caem 0,012 | o quadro de 45 s mostra a câmera mais longe e os foles batendo duas vezes por compasso |
| 6. a falha | o P4 tem pelo menos 8 linhas `toque` com `erro` | o quadro seguinte a uma falha mostra a fumaça no rosto |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | o `branco` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | os quatro foles e a fornalha cabem no quadro de 480 × 270 sem ampliar |
| 9. o impacto | o `branco` tem uma linha `sensacao` `explosao` a até 16,7 ms, a até 1 quadro de uma colcheia | — |
| 10. o placar no mundo | a `chama` do `momento` `reta` bate com a última linha `entrada` `chama` antes dele | no quadro de 54 s, quem olha diz se a forja está perto do branco pela altura da chama |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na
régua) existir, a prova roda com `--robo=medio` nos quatro e confere os itens 1, 3, 5, 8, 9 e 10;
os itens 4 (a mesa boa e a fraca), 6 e 7 (que pedem o P4 `ruim`) esperam o robô por lugar.

## Pronto quando

O Fole joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos
três temperamentos; a forja chega ao branco com o robô bom e apaga com o
ruim; o cabo que cai e volta recebe o Feedback de novo; o fim tem sempre o
destaque (e `vencedor` −1 no registro); `bash tests/prova_do_jogo.sh` passa; e `bash tests/prova_visual.sh`
passa com a prancha **olhada** nas partidas em que O Fole aparece. Além disso: o `branco` grava o momento a até 1 quadro
de uma colcheia, com a `sensacao` `explosao` de cada um; a linha `momento`
`reta` aparece uma vez (salvo se o branco veio antes do vento); e nenhuma cor
fora dos tokens sobra no `o_fole.gd`
(`grep -nE 'Color\("#|Tema\.(ROSA|AMARELO|TRILHO|CIANO|ROXO|LARANJA|FG)\b'`
não acha nada).

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## S01_J04 (I4): O Fole abre pelo catálogo; o Feedback chega ao R2 de cada
## controle simulado (e só ao R2); o robô entra na faixa de cada um; o fim é coop.
func _prova_do_fole() -> void:
	var r2 := [false, false, false, false]
	var olhar := func(_mg: Minigame) -> void:
		for l in 4:
			if int(_perc(l).get("gatilho_dir", 0)) == 0x21:
				r2[l] = true
	# a espera é a da H08: o aviso em quadros, o jogo pelo relógio de parede (80 s de música e o treino)
	var mg = await _joga_o_minigame("S01_J04", 120.0, olhar)
	if mg == null:
		return
	for l in 4:
		_esperar(r2[l], "S01_J04 P%d: o R2 com a resistência do fole" % (l + 1))
	_esperar(mg.coop and mg.destaque() >= 0, "S01_J04: fechou como coop, com o destaque")
	for l in 4:
		var c: Array = mg.contagem[l]
		_esperar(int(c[1]) + int(c[2]) + int(c[3]) >= 1, "S01_J04 P%d: entrou na faixa dele %s" % [l + 1, c])
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "S01_J04: de volta ao salão")
	for l in 4:
		_esperar(int(_perc(l).get("gatilho_dir", 0)) == 0x05, "S01_J04 P%d: o R2 solto no salão" % (l + 1))
```

Ainda na `_prova_do_fole()`, antes de esperar o salão, os momentos (a
régua):

```gdscript
	var todas := _linha_do_tempo()
	var linhas := todas.filter(func(e): return e.get("slot") == "S01_J04")
	var momentos := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "branco")
	var reta := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "reta")
	# o branco pode chegar antes do vento (a 2/3): então não há reta
	_esperar(reta.size() == 1 or (reta.is_empty() and not momentos.is_empty()), \
		"S01_J04: a linha momento reta aparece uma vez (ou o branco veio antes do vento)")
	_esperar(momentos.size() <= 1, "S01_J04: o branco aparece no máximo uma vez")
	for r in momentos:
		_esperar(float(r.get("x_tela", 0.0)) >= 0.2 and float(r.get("x_tela", 0.0)) <= 0.8 \
			and float(r.get("altura_tela", 0.0)) >= 0.08, "S01_J04: o momento no meio da tela (%s)" % [r])
		var t := float(r.get("t_musica", 0.0))
		# a sensacao (F05) não leva slot: procura em todas, perto no relógio da sessão (t)
		var sente := todas.filter(func(e): return e.get("tipo") == "sensacao" and e.get("nome") == "explosao" \
			and absf(float(e.get("t_musica", -9.0)) - t) <= 0.0167 \
			and absf(float(e.get("t", -9.0)) - float(r.get("t", 0.0))) <= 1.0)
		_esperar(not sente.is_empty(), "S01_J04: o momento tem a sensação explosao no mesmo quadro (%s)" % [r])
```

(`_linha_do_tempo` é da F01; já está na prova. O `branco` entre 45 e 70 s
espera a mesa boa, e a chama acima de 0,7 espera a fraca: as duas pedem o
robô por lugar.)

**Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

### O que o André joga e sente

**O André (local):** `./run-local.sh -- --sala=S01_J04`: de olhos fechados,
cada um acha a sua faixa pela resistência; o acorde dos quatro se ouve; a
chama cresce; a fumaça no rosto faz rir; o fole duplo do meio aperta.

- o anel de cada um acende antes da nota, e a sala vê quem está fundo
  demais no fole grande;
- o acorde fechado treme no R2 por um compasso e volta à resistência;
- a 2/3 o vento entra e a chama cai se o acorde não fecha;
- no branco, a luz sobe, os quatro recuam e o controle bate `explosao`
  junto com a imagem.

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a
cada 2 s): os de 2 a 10 s (os foles e a chama subindo), um quadro de jogo
com o anel aceso, um seguinte a uma falha (a fumaça), o de 45 s (a câmera
mais longe), o de 54 s (a altura da chama, anotada aqui na ficha) e o último
da mesa boa (a forja branca).

### Ao terminar

- Catálogo: `"S01_J04": preload("res://scripts/minigames/s01/o_fole.gd")` em
  `MINIGAMES` e na lista da S01.
- `traducoes.gd`: `"O Fole": "The Bellows"`, `"Sopre a forja!": "Blow the forge!"`,
  `"Sopre!": "Blow!"`.
- Importe e ponha o `.uid` no commit.
- No [quadro](README.md), a I4 **feito**, com o commit.
- Commit (sem trailer): `feat: O Fole — a profundidade do R2 é a altura da nota`
