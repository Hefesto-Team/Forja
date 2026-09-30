# Q2 — Roubo de Bateria

**Sprint:** Q · **Slot:** S09_J42 · **Tamanho:** M · **Estimativa:** US$ 1,5 · **Depende de:** H04, H08, F09, H07, G03, Q1

## Por quê

Pega-bandeira com o controle inteiro. Quem carrega a bateria tem de
**segurar o pulso dela** — L2 e R2 alternados, no tempo, e a mão diz qual
(o pulso bate no atuador do lado do gatilho da vez); a outra equipe manda
interferência para o alto-falante do carregador e apaga a pista. Andar é o
analógico, carregar é o gatilho com peso, atrapalhar e proteger é o ✕ no
tempo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](Q-a-prova.md) (as equipes, as cores) e a [Q1](Q1-a-prova.md) (o `_saida`, a carga)
- A [O1](O1-os-caminhos.md) (o `_pista`, o `_respondeu`, a troca) e a G03 (`usa_gatilho`)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J42",
	"titulo": "Roubo de Bateria",
	"verbo": "Roube!",
	"genero": "2v2",
	"icone": "gatilhos",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S09_J42",
	"duracao": 100.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Roube!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "pick-up",
}
```

(As entradas: o analógico esquerdo, os dois gatilhos — eixos — e o ✕.)

## Como se joga

A faixa é `MUS_S09_J42`, 138 bpm (uma batida ≈ 0,43 s). `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08).

- **As equipes:** a regra da ficha-mãe, **sem Aprendiz** (ver "Com menos de
  quatro"). A base da Brasa em `x = -9`, a da Maré em `x = 9` (raio
  `BASE_R := 1.5`).
- **Andar:** o analógico esquerdo, `VEL := 4.0` m/s (entrada: anda com o
  `dt`); quem carrega anda a `0.7` disso. Os cavaleiros se empurram (raio
  0,45 cada, a separação de `prova.gd:387-397`, sem os pilares).
- **Pegar:** a bateria livre a menos de 0,8 m de um cavaleiro é dele (o
  primeiro a chegar). No mesmo quadro, o R2 e o L2 dele ganham peso
  (`GATILHO_RESISTENCIA` 2, 5 nos dois: é a bateria na mão) e começa o pulso.
- **O pulso (a nota do carregador):** a partir da primeira batida inteira
  depois de pegar, **toda** batida `bn` é uma nota: nas pares **L2**, nas
  ímpares **R2** (`Ritmo.simples[l]`: só as pares, L2 e R2 alternando de
  duas em duas). A pista de cada pulso vem **meia batida antes**, no
  atuador do lado do gatilho: `_pista(l, "pulso", "", "golpe_esq", n, "L2")`
  ou `_pista(l, "", "pulso", "golpe_dir", n, "R2")`. O aperto é o gatilho
  cruzando 0,6 subindo; o gatilho certo → `julgar_toque(l, t(bn), n, true)`;
  o errado → `nota_perdida(l, n)` com `_motivo[l] = "trocou"`; nada até a
  nota passar → `nota_perdida(l, n)`.
- **Entregar:** o carregador dentro da própria base → a equipe marca uma
  bateria (`_baterias[e] += 1`), `marcar_equipe(e, 200)`, o peso sai dos gatilhos
  (`GATILHO_OFF`), e uma bateria nova nasce no centro duas batidas depois.
- **O ✕ no tempo** de quem não carrega (a nota nasce do toque: no aperto,
  `bn = roundi(Ritmo.batida())`, `nova_nota(l, n, t(bn))` e
  `julgar_toque(l, t(bn), n)`), sem erro:
  - a **outra** equipe carrega → **interferência** no carregador (recarga de
    8 batidas por quem manda): as pistas dos próximos dois pulsos dele **não
    vêm**, e no lugar delas o alto-falante dele estala
    `Forja.som_falante(c, "clique", 0.7)` nos contratempos (`bn + 0.25`,
    `+ 0.75`, `+ 1.25`, `+ 1.75`) — a estática; marca 50;
  - a **própria** equipe carrega → **escolta**: a próxima interferência
    contra o seu carregador se perde (um anel `Efeitos.anel` na cor da
    equipe em volta dele); marca 25;
  - ninguém carrega → **arrancada**: 1,2 m na direção do analógico em meia
    batida (pela batida).
  O ✕ julgado ERRO: o cavaleiro tropeça (meia batida parado).
- **O hoqueto:** o carregador segura o baixo (o pulso em toda batida); os
  outros entram com o ✕ por cima; a nota de cada lugar soa na TV (kit).
- **O pico — a sobrecarga:** os 16 tempos do meio
  (`_pico_b := BATIDA_DA_PRIMEIRA_NOTA + floor((duracao / _t_batida() - BATIDA_DA_PRIMEIRA_NOTA) / 2)`): as
  duas baterias no campo (a segunda nasce no centro), e a interferência não
  tem recarga.

## O cenário

- **A arena:** `Kit.arena(self, 6, 4)`; a luz da casa cheia:
  `luzes([Vector3(-10, 3, -6), Vector3(10, 3, -6), Vector3(-10, 3, 6), Vector3(10, 3, 6)])`,
  `atmosfera(Color("#ffb86c"), Tema.CIANO, true, 40, 24.0, -9.8)`.
- **As bases:** `Kit.caixa(self, Vector3(3.0, 0.03, 3.0), Vector3(±9, 0.02, 0), cor_equipe)`
  (fosco) e uma bandeira `Kit.peca(self, "banner", Vector3(±10.5, 0, 0))` em
  cada.
- **A bateria:** `Kit.peca(self, "barrel", pos, 0.0, 1.2)` com uma runa em
  cima — `Kit.caixa(no, Vector3(0.3, 0.06, 0.3), Vector3(0, 1.3, 0), runa)`,
  emissiva `#f1fa8c`, que pulsa na batida (`emission_energy_multiplier = 0.5 + 2.5 * maxf(0.0, 1.0 - fposmod(b, 1.0) * 3.0)`).
  Carregada, fica acima da cabeça do carregador (`pos + Vector3(0, 2.4, 0)`);
  caída, no chão onde caiu.
- **Os cavaleiros:** posições livres (sem as raias do kit), `p.preso = true`,
  o disco da equipe sob cada um; `sprint`/`walk`/`idle` pela velocidade;
  carregando, `holding-both`.
- **A câmera:** `camera_pos = Vector3(0, 14.0, 12.0)`, `camera_olhar = Vector3(0, 0, 0.5)`.
- **Checklist de arte (11):** o barril do kit e a runa; bases foscas nas
  cores das equipes; o emissivo só na runa e no anel da escolta; a prancha
  com um carregador e a bateria no alto.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **gatilhos (tudo junto)** | o peso da bateria nos dois (`RESISTENCIA` 2, 5); o pulso é o aperto no tempo | enquanto carrega |
| **háptica** | a pista do pulso no atuador do lado do gatilho da vez (`pulso`) | meia batida antes de cada pulso |
| **alto-falante do dono** | a estática da interferência (`clique` nos contratempos), só no controle do carregador | quando atrapalham |
| vibração | a bateria cai: `Forja.sentir(l, "golpe")`; o resto é o kit | na falha |
| barra de luz | a cor do lugar, sempre | — |
| luzinhas | o número do jogador, sempre | — |
| TV | a música de espionagem; `Som.tocar("ponto", base, -2.0)` na entrega; `Som.tocar("vazio", pos, -4.0)` na bateria que cai; `Som.tocar("tique", pos, -12.0)` em cada ✕ | — |

**No rádio:** a pista do pulso vai pelo rumble do lado (`golpe_esq` para L2,
`golpe_dir` para R2), com a `troca` uma vez; o peso dos gatilhos vai pela
ponte. Sem alto-falante, a estática não soa — mas a interferência continua
valendo, porque o que ela faz de verdade é **apagar a pista** dos próximos
dois pulsos (e isso vale no rumble também). O microfone fica de fora.

## A falha

**A bateria cai** (o pulso errado, trocado ou perdido): ela cai no chão onde
está, livre (`Som.tocar("vazio")`, faíscas `#f1fa8c`), o peso sai dos
gatilhos dele, a mão sente o golpe, e ele fica meia batida parado
(`emote-no`). Qualquer um pode pegá-la, até ele mesmo.

## O fim e o vencedor

O kit fecha no `duracao` (100 s). **O vencedor:** a equipe com mais baterias
entregues; no empate, a de mais pontos somados. `vencedor()` devolve os da
equipe vencedora (pelos pontos) e depois os da outra.

## Com menos de quatro

Um boneco não carrega bateria (não há Aprendiz aqui):

- **3:** dois contra um. O sozinho anda carregando a `0.85` (não `0.7`), e a
  interferência contra ele tem recarga de 16 batidas.
- **2:** um contra um.
- **1:** ele contra **a sentinela** — uma torre (`Kit.peca(self, "column", Vector3(0, 0, -3.5), 0.0, 1.4)`
  com um olho emissivo `#ff3a1a`) que manda interferência a cada 8 batidas
  enquanto ele carrega. O vencedor é ele (a colocação tem um); a tela mostra
  as baterias.
- **O controle que cai:** se carregava, a bateria cai (sem falha, sem
  registro de erro); as notas dele não abrem; volta andando de onde parou.
- `com_poucos()`: `"Dois contra um"` (3), `""` (2), `"Contra a sentinela"` (1).

## O robô

Anda pelo analógico, sente o lado do pulso na placa virtual e aperta o
gatilho certo no tempo; atrapalha e escolta com o ✕.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var p := jogador(l)
	if p == null:
		return
	var alvo := _robo_destino(l)            # a bateria livre; a própria base se carrega; o carregador inimigo
	var d := Vector2(alvo.x - p.position.x, alvo.z - p.position.z)
	var mv := d.normalized() if d.length() > 0.3 else Vector2.ZERO
	Forja.robo_eixo(l, Forja.LX, mv.x, 0.1)
	Forja.robo_eixo(l, Forja.LY, mv.y, 0.1)
	var b := Ritmo.batida()
	if _carrega == l:
		var n := ceili(b)
		if b > n - 0.55 and b < n - 0.1:
			var s := _robo_sente(l)          # o do O2: (esquerda, direita)
			if s.x + s.y > 0.05:
				_robo_lado[l] = 0 if s.x > s.y else 1
				_robo_pulso[l] = n
		if _robo_pulso[l] == n and _robo_apertou[l] != n:
			if _robo_decidiu[l] != n:
				_robo_decidiu[l] = n
				_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.25
			if Ritmo.t_musica() >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
				Forja.robo_eixo(l, Forja.L2 if _robo_lado[l] == 0 else Forja.R2, 1.0, 0.08)
				_robo_apertou[l] = n
	elif _carrega >= 0:
		# atrapalha ou escolta: ✕ nas batidas pares
		var bx := floori(b / 2.0) * 2
		if _robo_x[l] != bx:
			if _robo_x_decidiu[l] != bx:
				_robo_x_decidiu[l] = bx
				_robo_x_mira[l] = 0.0 if Forja.robo_acerta() else 0.25
			if Ritmo.t_musica() >= Ritmo.t_da_batida(bx) + float(_robo_x_mira[l]):
				Forja.robo_apertar(l, Forja.CRUZ, 0.05)
				_robo_x[l] = bx
```

(Sem pista sentida — a interferência apagou —, o robô não aperta: perde a
bateria, como gente.)

## Os ganchos

`godot/scripts/minigames/s09/roubo_de_bateria.gd`, `extends Minigame`.

```gdscript
extends Minigame
## Roubo de Bateria (S09_J42). Pega-bandeira: leve a bateria do centro até a
## sua base. Quem carrega segura o pulso dela — L2 e R2 alternados, no tempo;
## a mão diz o lado —, e a outra equipe manda interferência (✕ no tempo) para
## o alto-falante do carregador. O analógico esquerdo anda.
##
## A falha: o pulso falha e a bateria cai, livre. O vencedor: a equipe com
## mais baterias. O alto-falante do dono: a estática da interferência. O
## registro mede: o pulso (pista, pelo canal da háptica ou do rumble) e a resposta, o peso nos
## gatilhos (saida), a estática no alto-falante. O robô: sente o lado do pulso
## na placa virtual. Com menos de quatro: dois contra um, um contra um, contra
## a sentinela. A régua: a cor da equipe está no chão.

const FICHA := { ... }

const VEL := 4.0
const LENTO := 0.7
const LENTO_SOZINHO := 0.85
const BASE_X := [-9.0, 9.0]
const BASE_R := 1.5
const PEGA_R := 0.8
const RECARGA := 8
const RECARGA_SOZINHO := 16
const PONTOS := [0, 50, 75, 100]

var _pos := {}                 ## lugar -> Vector3
var _arrancada := {}           ## lugar -> {de, ate, b0}
var _baterias := [0, 0]
var _bateria_pos: Array = []   ## as baterias no campo: [{pos, carregador (-1 livre), nasce_em}]
var _carrega := -1             ## quem carrega a primeira (o robô olha)
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _gatilho_da_nota := [0, 0, 0, 0]   ## 0 = L2, 1 = R2
var _n := [0, 0, 0, 0]
var _eixo_antes := [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
var _sem_pista := [0, 0, 0, 0]         ## quantos pulsos ainda sem pista (a interferência)
var _escoltado := [false, false, false, false]
var _recarga_ate := [-99.0, -99.0, -99.0, -99.0]
var _parado_ate := [-1.0, -1.0, -1.0, -1.0]
var _motivo := ["", "", "", ""]
var _pico_b := 9999.0
var _rumble := [false, false, false, false]
var _sentinela: Node3D = null
var _nos := {}
var _robo_lado := [0, 0, 0, 0]
var _robo_pulso := [-1, -1, -1, -1]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_decidiu := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_x := [-1, -1, -1, -1]
var _robo_x_decidiu := [-1, -1, -1, -1]
var _robo_x_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 14.0, 12.0)
	camera_olhar = Vector3(0, 0, 0.5)
	# as equipes (sem Aprendiz), as bases, a bateria no centro, os cavaleiros nas bases, a sentinela (com um)


func iniciar_jogo() -> void:
	# o _pico_b; o rádio (_rumble e a troca); os gatilhos soltos
	pass


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	for l in presentes():
		if not conectado(l):
			_largar_sem_culpa(l)       # se carregava, a bateria cai sem falha
			continue
		_andar(l, b, dt)               # o analógico, a arrancada pela batida, parado depois do tropeço
		_pegar(l)                      # a bateria livre perto: pega, o peso nos gatilhos
		if _carrega_alguma(l):
			_pulso(l, b)               # a pista meia batida antes; o gatilho cruzando 0,6; a nota que passou
			_entregar(l, b)
		elif Forja.apertou(l, Forja.CRUZ):
			_cruz(l, b)                # a nota nasce do toque: interferência, escolta ou arrancada
	_nascer_baterias(b)                # a do centro depois da entrega; a segunda no pico
	_sentinela_age(b)
	_mostrar(b)


func toque(l: int, j: int) -> void:
	if _carrega_alguma(l):
		marcar_equipe(equipe[l], PONTOS[j])  # os dois da dupla (o kit, H08)
		_respondeu(l, _n[l] - 1, "certo")
	else:
		_efeito_da_cruz(l)             # interferência (+50), escolta (+25) ou arrancada


func falha(l: int) -> void:
	if _carrega_alguma(l):
		_largar(l)                     # a bateria cai: "A falha"
	else:
		_parado_ate[l] = Ritmo.batida() + 0.5
		jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var e := 0 if _baterias[0] > _baterias[1] else (1 if _baterias[1] > _baterias[0] else _mais_pontos())
	var ganhou := presentes().filter(func(l): return equipe[l] == e)
	var perdeu := presentes().filter(func(l): return equipe[l] != e)
	ganhou.sort_custom(func(a, b): return pontos[a] > pontos[b])
	perdeu.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return ganhou + perdeu
```

`_pulso(l, b)`: a próxima batida inteira `bn` depois de pegar: meia batida
antes, a pista do lado (ou nada, se `_sem_pista[l] > 0`: aí `_sem_pista[l] -= 1`
e o `_respondeu` desse pulso diz `nenhuma` se ele errar), `nova_nota`;
detecta o L2 e o R2 cruzando 0,6 (os `_eixo_antes`); o certo → `julgar_toque`,
o outro → `_motivo = "trocou"`, `nota_perdida`; a que passou →
`nota_perdida`. `_cruz(l, b)`: `n = _n[l]`, `_n[l] += 1`,
`bn = roundi(b)`, `nova_nota(l, n, t(bn))`, `julgar_toque(l, t(bn), n)`.
`_efeito_da_cruz(l)`: a outra equipe carrega e `b >= _recarga_ate[l]` → se o
carregador estava escoltado, só gasta a escolta; senão `_sem_pista[c] = 2` e
agenda os quatro cliques no alto-falante dele (uma fila por batida, mandada
no `_mostrar` ou no `jogar`, uma vez cada); `_recarga_ate[l] = b + RECARGA`
(ou `RECARGA_SOZINHO` contra o sozinho; sem recarga no pico).
`_saida(l, ok)` é o da Q1 (a carga); todo `Forja.gatilho` e `Forja.sentir`
passa por ele.

Dica (com `na_raia(l)`): carregando, `["@l2", "@r2"]` enquanto
`not aprendeu(l)`; sem carregar, `["@cross"]` enquanto `not aprendeu(l)`.
`status(l)`: `"Brasa %d" % _baterias[0]` / `"Maré %d" % _baterias[1]` (as da
O5).

Catálogo: `"S09_J42"` em `MINIGAMES` e na seção `S09`. Traduções:
`"Roubo de Bateria": "Battery Heist"`, `"Roube!": "Steal!"`,
`"Dois contra um": "Two against one"`, `"Contra a sentinela": "Against the sentry"`.

`_t_batida()` (a duração de uma batida, em s, para o pico):
`return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)`.

`_mais_pontos()`: `maxi(equipe_vencedora(), BRASA)` — a equipe com mais pontos pelo kit (`pontos_da_equipe`, H08; a Brasa no empate).

## O que o registro mede

- `pista` de cada pulso (`o_que` `L2`/`R2`, `canal`) e a resposta — a noite
  vê, por controle, se o lado da háptica (ou do rumble) chegou;
- `saida` do gatilho (o peso, a cada pega e entrega) com `seq` e `ok`, e
  `som_controle` da estática — a carga das saídas nos quatro;
- `troca` no rádio; `nota`/`toque` do pulso e dos ✕.

## Armadilhas

- **O L2 é do minigame aqui**: `usa_gatilho = true` no `montar()`, senão o
  item (G03) mexe no L2 e o peso da bateria some.
- **Uma pista, um lado:** `Forja.som_haptica(l, "pulso", "")` ou
  `(l, "", "pulso")`, nunca os dois; o `pulso` já existe
  (`nativo/som/sons_salas.c`).
- **A pista meia batida antes, e o acerto do kit na batida:** no rádio, o
  rumble da pista e o do acerto não se encostam (meia batida, ≈ 0,22 s; a
  sensação `golpe_*` dura 0,25 s — encurte a pista para `Forja.sentir(l, "golpe_esq", 180)`).
- **A arrancada anda pela batida** (o `lerpf` em meia batida); o andar do
  analógico usa o `dt` (é entrada).
- **Na prova o pico chega:** o fim conta em tempo de música (H08), e a
  `duracao` inteira roda na prova, pelo relógio de parede.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com a sentinela) e com o
robô nos três temperamentos; aguenta o cabo que cai e volta (a bateria cai
sem culpa); fecha com uma equipe vencedora; os dois gatilhos pesam só em
quem carrega; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com
a prancha olhada (a bateria no alto, as bases, alguém entregando).

## Provas

Em `godot/testes/prova_do_jogo.gd`, uma `_prova_roubo()`:

```gdscript
## S09_J42: alguém pega a bateria, os dois gatilhos dele pesam (0x21) e os
## dos outros ficam soltos; o pulso bate num atuador só.
func _prova_roubo() -> void:
	# a espera é a do `_joga_o_minigame` da H08: o aviso em quadros, o jogo pelo relógio de parede (100 s de música e o treino)
	var viu_peso := [false]
	var viu_lado := [false]
	var olhar := func(s) -> void:
		var c: int = s._carrega
		if c >= 0:
			var p := _perc(c)
			if int(p.get("gatilho_dir", 0)) == 0x21 and int(p.get("gatilho_esq", 0)) == 0x21:
				viu_peso[0] = true
			var v := Forja.som_virtual(c)
			var esq := float(v.get("esq", 0.0))
			var dir := float(v.get("dir", 0.0))
			if (esq > 0.05 and dir < 0.02) or (dir > 0.05 and esq < 0.02):
				viu_lado[0] = true
	var sala = await _joga_o_minigame("S09_J42", 140.0, olhar)
	if sala == null:
		return
	_esperar(viu_peso[0], "roubo: o carregador sente o peso nos dois gatilhos")
	_esperar(viu_lado[0], "roubo: o pulso bate num atuador só")
```

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `./run-local.sh -- --sala=S09_J42`, dois no cabo e
dois no rádio. O pulso L2/R2 tem de dar para seguir pela mão enquanto se
corre; a estática no alto-falante tem de ser perceptível e irritante (é a
sabotagem); o peso da bateria tem de ser sentido. Com três, o sozinho não
pode ser presa fácil.

## Ao terminar

- No [quadro](README.md), a linha Q2: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: Roubo de Bateria — o pulso nos gatilhos, a estática no alto-falante`
