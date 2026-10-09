# L3 — Curto-Circuito

**Sprint:** L · **Slot:** S04_J18 · **Tamanho:** M · **Depende de:** H04, H08, F09, L1, G14, G15

## Por quê

A batata quente da seção: uma bomba passa de mão em mão no tempo, e o pavio dela só quem segura sente (o coração
bate na mão, acelera quando falta pouco); com quatro no sofá, quem está com a bomba sabe uma coisa que os outros
não sabem e escolhe para quem passar. Quatro rodadas; vence quem estourou menos e ninguém sai do jogo.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [L1 — O Cerco, «A cena»](L1-o-cerco.md#a-cena): o cenário comum inteiro (o `escuro`, a lanterna da vida, o exagero) está em
  «A cena», no código de `cenario_do_impacto.gd`; o modelo (a pista, o robô, o `momento`, o empurrão) está em «Como se joga»,
  «O controle» e «O robô». Se a L1 já entrou, valem `cenario_do_impacto.gd` e `o_cerco.gd` em
  `godot/scripts/minigames/s04/`.

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) está copiado nesta ficha, com os números.
Onde o índice da seção (`L-o-impacto.md`) dá uma cor em hex ou outra câmera, vale a L1 (o `cenario_do_impacto.gd`).

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s04/curto_circuito.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S04_J18` em `MINIGAMES` e na lista da seção `S04` de `SECOES` | **de todos** |
| `godot/scripts/traducoes.gd` | `"Curto-Circuito": "Short Circuit"`, `"Passe!": "Pass!"`, `"Rodada %d de %d": "Round %d of %d"`, `"Você e o boneco de palha": "You and the scarecrow"`, `"Esquerda": "Left"`, `"Direita": "Right"` (as que ainda não existirem) | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_curto_circuito()` e a chamada depois das outras da seção | **de todos** |
| `godot/scripts/minigames/s04/cenario_do_impacto.gd` | **não muda**: só chama | da seção (a L1 criou) |
| `godot/scripts/minigames/minigame.gd` | **não muda**: usa `momento()` (a L1 pôs) | de todos |
| `docs/jogo/13-arquitetura.md` | **não muda**: a linha `momento` é da L1 | de todos |

O `.uid` novo (`curto_circuito.gd.uid`) sai de `"$GODOT" --headless --path godot --import --quit` e entra no
commit.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Curto-Circuito (S04_J18) — a bomba passa de mão em mão. Quem segura joga
## para o vizinho da esquerda (L1) ou da direita (R1), na batida seguinte à
## que recebeu (no pico, na colcheia seguinte). O pavio é secreto: o coração
## da bomba bate na mão de quem segura e acelera quando falta pouco; o R2
## dele pesa cada vez mais. Quem está com ela quando o pavio acaba estoura.
## Quatro rodadas.
##
## A falha: jogar fora do tempo — a bomba escorrega e fica na mão mais uma
## chance; quatro chances perdidas seguidas — ela estoura. Estourar: o
## cavaleiro voa 2,5 m e fica caído, com fumaça, até a rodada seguinte.
## O vencedor: quem estourou menos; no empate, mais pontos.
## O alto-falante do dono: o julgamento do kit; sem vibração, o coração em tiques.
## O registro mede: cada pulso do coração (sensação, ok) a quem segura, o
## passe no tempo, o fantasma (quem aperta sem segurar) e o momento `estouro`.
## O robô: sente a bomba pelo peso do R2 no controle simulado e joga na
## primeira chance, para o vizinho com mais pontos; quando não acerta, 250 ms
## tarde (escorrega).
## Com menos de quatro: dois jogam um para o outro; sozinho, o boneco de palha devolve.
## A régua: (1) "Passe!" com a bomba acesa na cabeça de alguém; (2) sim: o
## pavio é só da mão; (3) não pergunta nada.

const FICHA := {
	"slot": "S04_J18",
	"titulo": "Curto-Circuito",
	"verbo": "Passe!",
	"genero": "sabotagem",
	"icone": "vibracao",
	"entradas": [Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_S04_J18",
	"duracao": 100.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["toque", "aviso", "golpe", "explosao", "acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Passe!", "segundos": 6.0},
}

const PONTOS := [0, 10, 20, 30]  ## o passe: ERRO, BOM, OTIMO, PERFEITO
const SOBREVIVEU := 100  ## a cada rodada, quem não estourou
const RODADAS := 4
## O pavio de cada rodada, em batidas (sorteado entre os dois): 1 e 4 longos, 2 e 3 (o pico) curtos.
const PAVIO := [[16, 24], [10, 16], [10, 16], [16, 24]]
## O passo da grade de cada rodada: 1 batida, ou meia no pico.
const PASSO := [1.0, 0.5, 0.5, 1.0]
const SEGURA_MAX := 4  ## quatro chances perdidas seguidas e ela estoura
const PAUSA_COMPASSOS := 2  ## entre uma rodada e a outra
const BONECO := 9  ## o "lugar" do boneco de palha (um jogador só)
## O estouro (o degrau estrondo): o voo sobe 2,5 m (vezes o Peso), puxado para
## o meio da tela (a régua, item 2): o ápice em x = RAIAS[l] * 0.4.
const VOO_M := 2.5
const VOO_MIN_M := 2.0
const PUXA_PARA_O_MEIO := 0.4
const QUEDA_TEMPOS := 3.0  ## minigames.csv: 3
const FAISCAS_DO_ESTOURO := 60
```

### A rodada

- A primeira começa no compasso 1 (batida 4); cada uma das seguintes começa `PAUSA_COMPASSOS` compassos depois
  do estouro, no começo de um compasso.
- **Quem começa com a bomba:** o presente com controle que estourou menos; no empate, o `rng` sorteia entre eles.
- **O pavio:** `_estouro_b = inicio + rng.randi_range(PAVIO[r][0], PAVIO[r][1])` (em batidas inteiras), secreto.
- A 160 BPM a batida dura 0,375 s: o 1.º estouro cai entre 7,5 s e 10,5 s (batidas 20 a 28).

### Quem segura

Quem segura (`_com`) tem sempre **uma** nota, a próxima chance de passar.

- Ao receber na batida `r`, a nota é `r + PASSO[rodada]`.
- Cada chance perdida (sem passe, ou passe fora do tempo) põe a próxima `PASSO[rodada]` depois.
- A nota: `{"n": int(round(b * 2)), "b": b, "t": Ritmo.t_da_batida(b)}`, com `nova_nota(l, n, t)`.
- Na `SEGURA_MAX`-ésima chance perdida seguida, ela estoura.

### O passe

L1 joga para o vizinho da esquerda, R1 para o da direita. Os vizinhos são os presentes com controle, em ordem de
lugar, em roda (a esquerda de P1 é o último; a direita do último é P1). Se o aperto está a até `Ritmo.JANELA_BOM`
da nota: ponha a nota em `_ultima[l]`, guarde `_lado_do_passe[l]` e chame `julgar_toque(l, t, n)`.

- **BOM, ÓTIMO ou PERFEITO** → `toque()`: a bomba voa (tween de 0,3 batida, enfeite) e o vizinho a **recebe na
  batida da nota** (`r = b`); a vez dele é `b + PASSO`. Em roda e no tempo, a bomba anda uma batida por jogador:
  o hoqueto.
- **ERRO** → `falha()`: escorrega (abaixo); a próxima chance é `b + PASSO`.
- **Aperto longe de qualquer nota:** nada acontece com a bomba; quem não segura e aperta grava
  `anotar("entrada", l, {"o": "fantasma", "golpe_de": "P%d" % (_com + 1)})`.
- A chance que passa de `t + FOLGA_PERDIDA` (0,14 s) sem aperto: `_ultima[l] = nota` e `nota_perdida(l, n)`.
- **Os pontos do passe:** `marcar(l, PONTOS[julgamento])` cru; o item (`Itens.pontos_do_acerto`) o kit aplica.

### O coração (a pista, só em quem segura)

`faltam = _estouro_b − Ritmo.batida() − CenarioDoImpacto.antecedencia(l) * Ritmo.bpm / 60.0` (o Faro e a Lanterna
fazem o coração acelerar antes; o estouro cai na mesma batida).

| faltam | o pulso | quando |
| --- | --- | --- |
| mais de 8 batidas | `Forja.sentir(l, "toque", 60)` (0 / 0,45) | em cada batida |
| de 8 a 4 | `Forja.sentir(l, "aviso", 60)` (0,6 / 0) | em cada colcheia |
| menos de 4 | `Forja.sentir(l, "golpe", 60)` (1,0 / 0,6) | em cada colcheia |

- Controle pelo índice da grade: `var g := int(floor(Ritmo.batida() * div))` (`div` 1 ou 2); pulse quando
  `g > _ultimo_pulso` e guarde.
- **Sem vibração** (`sentir` devolveu `false`): `Som.no_controle(l, "tique", 0.7)` no lugar de cada pulso.
- Na mudança de faixa: `anotar("pista", l, {"n": -1, "evento": "mandou", "canal": "rumble" (ou "alto_falante"), "o_que": "ambos", "ok": ok, "faltam": int(faltam)})`.

### O peso (o gatilho de quem segura)

R2 em `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 0, forca)`, com `forca` 3 (mais de 8), 6 (de 8 a 4) e 8
(menos de 4). Ao passar, o R2 de quem passou volta a `Forja.GATILHO_OFF`. Mande só quando muda (`_forca[l]`).

### O estouro

Quando `Ritmo.batida() >= _estouro_b` (ou na quarta chance perdida seguida), quem segura estoura.

- **Nunca duas rodadas seguidas no mesmo lugar pelo pavio:** se o pavio acaba na mão de quem estourou a rodada
  anterior (`_ultimo_estourado`), `_adiado = true` e a bomba estoura na mão do próximo que a receber. Se ele
  perde as quatro chances, estoura ele mesmo (é escolha dele).
- Os que não estouraram ganham `SOBREVIVEU`.
- `momento("estouro", l, apice, 1.8, {"rodada": _rodada + 1, "faltavam": 0})`, com
  `apice = Vector3(RAIAS[l] * PUXA_PARA_O_MEIO, altura_do_voo, Z_JOGADOR - 1.5)` (o objeto do momento é o
  cavaleiro no alto do voo; o boneco de palha grava `l` −1 e `{"boneco": true}`).
- `CenarioDoImpacto.so_o_dono(self, l)`: a luz das outras raias cai 30 % por 1 batida.
- Na quarta rodada, depois do estouro, todos `acabou`.

### A curva, por rodada

| rodada | pavio | o passe | o que é |
| --- | --- | --- | --- |
| 1 | 16–24 batidas | na batida | ensina: o coração devagar, depois acelerando |
| 2 e 3 (**o pico**) | 10–16 batidas | na colcheia | a bomba roda o dobro de depressa, o pavio é curto |
| 4 | 16–24 batidas | na batida | o fim tenso: longo de novo, com o placar de estouros na tela do mundo (as marcas pretas) |

As quatro rodadas acabam antes dos 100 s (a 160 BPM, entre 27 s e 42 s com as pausas); os 100 s de `duracao` são
o teto, contados em tempo de música (H08). `CenarioDoImpacto.passar(self, _cenario, _rodada in [1, 2])` liga o
pico da luz e da câmera nas rodadas 2 e 3.

### O fim e o vencedor

`fim` `ultimo_em_pe`: depois da quarta rodada, todos `acabou` e o kit fecha.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(explosoes[a]) != int(explosoes[b]):
			return int(explosoes[a]) < int(explosoes[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

### Com menos de quatro

- **Três:** a roda de três; a esquerda e a direita são os outros dois.
- **Dois:** a esquerda e a direita são o mesmo vizinho; a bomba vai e volta.
- **Um:** o vizinho dos dois lados é o boneco de palha (`BONECO`): ele segura uma chance (`PASSO`) e devolve
  sozinho, sempre no tempo; se o pavio acaba com ele, ele estoura em faíscas (sem ponto para ninguém).
  `com_poucos()` devolve `"Você e o boneco de palha"` com um jogador e `""` com mais.
- **O controle que cai:** se quem segura perde o controle, a bomba passa sozinha para o vizinho da direita na
  próxima chance, sem julgamento; quem está sem controle sai da roda até voltar (e volta na rodada seguinte, com o
  placar dele como estava).

### Os ganchos

```gdscript
var _notas := [[], [], [], []]  ## só quem segura tem uma: a próxima chance
var _ultima := [{}, {}, {}, {}]
var _com := -1  ## quem segura (0..3, BONECO, ou -1 entre as rodadas)
var _estouro_b := 0.0
var _rodada := 0  ## 0..3; RODADAS = acabou
var _perdidas := 0  ## chances perdidas seguidas de quem segura
var _proxima_rodada_b := 4.0
var _ultimo_pulso := -1
var _forca := [-1, -1, -1, -1]  ## a força do R2 mandada (-1: Off)
var _lado_do_passe := [0, 0, 0, 0]
var _ultima_do_boneco := 0.0
var _ultimo_estourado := -1
var _adiado := false
var _caido := [false, false, false, false]  ## fora da rodada até a seguinte
var _fumaca := [null, null, null, null]  ## o GPUParticles3D de cada caído
var explosoes := [0, 0, 0, 0]
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoImpacto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoImpacto.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = 0.0  # de frente para a câmera
		p.preso = true
		Forja.gatilho(l, 1, Forja.GATILHO_OFF)
	_montar_a_bomba()
	_montar_os_fios()
	if jogadores.size() == 1:
		_montar_o_boneco()


func iniciar_jogo() -> void:
	_proxima_rodada_b = 4.0
	for l in presentes():
		CenarioDoImpacto.luz_com_brilho(l, 1.0)


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	CenarioDoImpacto.passar(self, _cenario, _rodada in [1, 2])
	if _com == -1 and _rodada < RODADAS and b >= _proxima_rodada_b:
		_comecar_rodada(int(_proxima_rodada_b))  # levanta os caídos, apaga a fumaça
	for l in presentes():
		if not conectado(l):
			continue
		if Forja.apertou(l, Forja.L1):
			_passar(l, 0)
		elif Forja.apertou(l, Forja.R1):
			_passar(l, 1)
	if _com >= 0:
		_coracao()
		_gatilho_do_pavio()
		if _com < 4 and not conectado(_com):
			_passa_sozinha()
		elif _com < 4 and not _notas[_com].is_empty() and Ritmo.t_musica() > float(_notas[_com][0].t) + FOLGA_PERDIDA:
			var nt: Dictionary = _notas[_com].pop_front()
			_ultima[_com] = nt
			nota_perdida(_com, int(nt.n))  # chama falha(): escorrega, ou estoura na quarta
		elif _com == BONECO and b >= _ultima_do_boneco + PASSO[_rodada]:
			_boneco_devolve()
		if _com >= 0 and b >= _estouro_b:
			if _com == _ultimo_estourado:
				_adiado = true
			else:
				_estourar(_com)
	_mostrar_a_bomba()


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])
	jogador(l).gesto("interact-left" if _lado_do_passe[l] == 0 else "interact-right", 0.3)
	Som.tocar("tique", jogador(l).global_position + Vector3(0, 2.1, 0), -8.0)
	_entregar(_vizinho(l, _lado_do_passe[l]), float(nt.b))


func falha(l: int) -> void:
	_perdidas += 1
	if _perdidas >= SEGURA_MAX:
		_estourar(l)
		return
	var nt: Dictionary = _ultima[l]
	_nova_chance(l, float(nt.b) + PASSO[_rodada])
	_escorregar(l)


## A roda de adesivos (G04) lê isto: só quem está fora da rodada manda adesivo.
func fora_da_rodada(l: int) -> bool:
	return bool(_caido[l])
```

As outras fazem o que as partes desta ficha dizem:

- `_comecar_rodada(b)`: quem começa, o pavio, `_adiado = false`, os caídos de pé (`animar("idle")`), a fumaça
  apagada (`queue_free`).
- `_passar(l, lado)`: guarda `_lado_do_passe[l]`, põe a nota em `_ultima[l]` e chama `julgar_toque`, ou grava o
  fantasma.
- `_entregar(para, b)`: o R2 de quem passou vai a Off, `_com = para`, `_perdidas = 0`,
  `_nova_chance(para, b + PASSO[_rodada])`; se `_adiado`, `_estourar(para)` na hora.
- `_nova_chance(l, b)`: limpa `_notas[l]`, põe a nova, `nova_nota`.
- `_vizinho(l, lado)`: a roda; `BONECO` com um jogador.
- `_estourar(l)`: «O estouro» e «O cavaleiro»; `_ultimo_estourado = l`; `_com = -1`; `_rodada += 1`;
  `_proxima_rodada_b = (floor(b / 4.0) + 1 + PAUSA_COMPASSOS) * 4`.
- `_escorregar(l)`, `_coracao()`, `_gatilho_do_pavio()`, `_passa_sozinha()`, `_boneco_devolve()`.
- `progresso()`: `"Rodada %d de %d" % [mini(_rodada + 1, RODADAS), RODADAS]` na fase jogo.
- `dica(l)`: `{"partes": ["@l1", "Esquerda", "@r1", "Direita"], "pos": Vector3(RAIAS[l], 0.0, 4.6)}` quando
  `na_raia(l)`, `_com == l` e `not aprendeu(l)`; senão `{}`.
- `combo(l)` (G04): os passes perfeitos seguidos do lugar.

O catálogo: `Catalogo.MINIGAMES["S04_J18"] = preload("res://scripts/minigames/s04/curto_circuito.gd")`.

## A cena

### A câmera

A arena da seção: `CenarioDoImpacto.pose_da_camera()` (35 mm, plongée de 50°, a 13,5 m, olhando
`(0, 0,8, −1,0)`), modo `fixa`, **sem corte**, roll zero. A bomba acima da cabeça (y 2,1) e o voo do estouro
(até y 2,5, puxado para x = `RAIAS[l] * 0.4`) cabem: o ápice do voo de P1 e de P4 cai em `x_tela` 0,33 e 0,67.

- **O pico** (as rodadas 2 e 3): `CenarioDoImpacto.passar` recua a câmera 10 % e sobe a chave 20 % em 1 batida.
- **O tremor é do evento:** só o de `CenarioDoImpacto.exagero`.

### A luz

A da seção (mostarda, lado A), posta pelo `CenarioDoImpacto.montar(self)`: a névoa `#170e00`, o preenchimento
`#493400`, a chave `#f8d096`, as duas tochas `Tema.TUNGSTENIO`. No estouro, `CenarioDoImpacto.so_o_dono` baixa
30 % a luz das outras raias por 1 batida.

### As peças e o papel de cada uma

| peça ou forma | onde | papel | material |
| --- | --- | --- | --- |
| `barrel` (escala 0,7), num `Node3D` `bomba` | `jogador(_com).global_position + Vector3(0, 2.1, 0)` | a bomba | a peça |
| o pavio: `Kit.caixa(0.05 × 0.3 × 0.05)` | `(0, 0.75, 0)` na bomba | o pavio | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| a faísca do pavio: `Kit.caixa(0.09 × 0.09 × 0.09)` | `(0, 0.95, 0)` na bomba; escala `1.0 + 0.3 * absf(sin(PI * Ritmo.batida()))` (igual para todos: não conta o pavio) | a faísca | `Tema.neon(Tema.TUNGSTENIO, 1.2, "forja")` |
| seis fios: `Kit.caixa(0.06 × 0.06 × 3.0)` | `(-7.5 + 3.0 * k, 0.05, -2.5)` | o fosso de fios atrás das raias | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| a marca do estouro: `Kit.caixa(1.4 × 0.01 × 1.4)` | `(RAIAS[l], 0.02, Z_JOGADOR - 0.3)`; a segunda na mesma raia 0,2 m para trás | o rastro (até o fim) | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| a fumaça do caído | `Efeitos.poeira(self, jogador(l).global_position + Vector3(0, 0.6, 0), Vector3(0.8, 1.2, 0.8), Tema.GRAFITE, 16)` | o rastro (até a rodada seguinte) | — |
| o boneco de palha (só com um jogador) | `barrel` (escala 1,2) em `(RAIAS[l] + 4.0, 0, Z_JOGADOR)` e `pot` (1,4) em cima, a y 1,5 | o vizinho | as peças |

Quem segura usa `animar("holding-right")`; os outros, `idle`.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a borda da raia (`acender_raia`) | o lugar | o kit: 2,0, e 2,6 no acerto por 4 quadros |
| a faísca do pavio | a forja | 1,2, `Tema.TUNGSTENIO` |
| as faíscas dos fios | a forja | `Efeitos.faiscas(self, fio_sorteado, Tema.TUNGSTENIO, 10, 0.5)` a cada compasso |
| as faíscas do estouro | a forja | `Efeitos.faiscas(self, pos, Tema.TUNGSTENIO, 60, 1.6)` |
| as faíscas do passe certo | o lugar | `Efeitos.faiscas(self, pos_da_bomba, Forja.cor_do_lugar(l), 12, 0.6)`, 2,4 por 12 quadros |

Nenhum hex fora dos tokens: o `LARANJA`, o `#ffb000`, o `#3a3a44` e o `#6fa8ff` de antes somem. Nada é metálico e
nada passa de 300 partículas (o pior quadro: 60 do estouro, 16 de cada fumaça, 12 do passe).

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o passe certo | `Som.tocar("tique", pos_da_bomba, -8.0)` | o julgamento do kit (`jul_*`) | `tique_*` |
| o coração | — (só a mão) | — (sem vibração: `tique` a cada pulso) | `tique_*` |
| o escorregão | — | `jul_erro_p{n}` (o kit) | — |
| o estouro | `Som.tocar("golpe", pos, 0.0)` | — | `golpe_*` |
| a faixa | `MUS_S04_J18`: 160 BPM, Dó menor, 150 s («sirenes no tempo, pânico»); até existir, a reserva `sint_trilha` da H05 | — | `mus_s04_j18` |

- **Nenhum `"falha"`** e nenhum `"clique"` ou `"golpe"` no alto-falante: o alto-falante do dono é do julgamento
  do kit, um som por vez; a única exceção é a reserva do coração sem vibração. A troca da falha na TV por
  `fx_tropeco_*` é da H11.
- O material `"metal"` da FICHA: o kit toca `mod_material_metal` nos atuadores no passe.
- A mixagem é da H11.

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| o coração, mais de 8 | só quem segura | `toque` (0 / 0,45), 60 ms, a cada batida | R2 Resistência (0, 3) | — | sem vibração: `tique` |
| o coração, de 8 a 4 | só quem segura | `aviso` (0,6 / 0), 60 ms, a cada colcheia | R2 Resistência (0, 6) | — | sem vibração: `tique` |
| o coração, menos de 4 | só quem segura | `golpe` (1,0 / 0,6), 60 ms, a cada colcheia | R2 Resistência (0, 8) | — | sem vibração: `tique` |
| o passe julgado | quem passou | `acerto`, `perfeito` ou `erro` (o kit) | R2 Off | o kit: branco 0,15 s no perfeito; a cor escurecida 0,5 s no erro | `jul_*` (o kit) |
| o estouro | quem estourou | `explosao` (1,0 / 1,0, 400 ms) | R2 Off | — | — |
| começar | todos | — | R2 Off; o L2 é do item (G03) | a cor do lugar, 100 % | — |

- Nada na barra de luz nem nas luzinhas diz quem está com a bomba: ela está no mundo e no R2.
- As luzinhas de jogador mostram o número, sempre. O microfone não se usa.
- **Os outros não sentem nada** do coração: o fantasma (quem aperta sem segurar) mede o vazamento.

### O robô

```gdscript
# O robô sabe que está com a bomba pelo peso do R2 no controle simulado (o
# modo Feedback, 0x21), e joga na primeira chance, pelo relógio da música,
# para o lado do vizinho com mais pontos (a sabotagem).
var _robo_nota := [-1.0, -1.0, -1.0, -1.0]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var com_ela := int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21
	if not com_ela or _notas[l].is_empty():
		_robo_nota[l] = -1.0
		return
	var nt: Dictionary = _notas[l][0]
	if float(nt.b) != _robo_nota[l]:
		_robo_nota[l] = float(nt.b)
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, 250 ms tarde (escorrega)
		_robo_atraso[l] = 0.0 if Forja.robo_acerta() else 0.25
	if Ritmo.t_musica() >= float(nt.t) + float(_robo_atraso[l]):
		var esq := _vizinho(l, 0)
		var dir := _vizinho(l, 1)
		var lado := 0 if int(pontos[esq] if esq < 4 else 0) >= int(pontos[dir] if dir < 4 else 0) else 1
		Forja.robo_apertar(l, Forja.L1 if lado == 0 else Forja.R1, 0.06)
		_robo_nota[l] = 99999.0  # já jogou nesta chance
```

`_notas[l]` tem no máximo uma nota: a chance de agora. O robô lê a hora dela, mas só sabe que está com a bomba
pelo R2 do controle simulado; sem o gatilho, ele não joga. A mesma conta roda no controle simulado da prova do
jogo e no da prova visual.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como
estão, de frente para a câmera. `posicionar(l)` deixa as mãos livres: a arma ou o amuleto não aparece (a bomba é a
única coisa na mão), mas o efeito do item vale. O cavaleiro pode ser de outra raça (G13, o ajuste dela de 09/10):
esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos e as animações `holding-right`,
`interact-left`, `interact-right`, `emote-no`, `fall`, `die` e `idle`.

| stat | gancho | o que muda no Curto-Circuito | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | a altura do voo do estouro | 2,90 m | 2,50 m | 2,10 m |
| Passo | — | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | quanto tempo fica estirado (`die`) antes de sentar, com a fumaça | 3,75 tempos | 3 tempos | 2,25 tempos |
| Faro | `pista` | o coração acelera antes; o estouro cai na mesma batida | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro escorregão (o kit); a Âncora divide a altura do voo por 2, até o piso de
`VOO_MIN_M` (2,0 m); a Lanterna adianta o coração meio tempo (`Itens.antecipacao_s`, dentro do `antecedencia`); o
Martelo dobra o passe perfeito no tempo forte (o kit). Nenhum stat muda a janela, os pontos, o pavio ou o estouro.

```gdscript
## O estouro no corpo: o voo sobe até o ápice puxado para o meio (meia batida,
## `SAI`), cai de volta na raia (meia batida, `QUICA`), fica estirado a queda
## do Fôlego e senta com a fumaça até a rodada seguinte.
func _voar(l: int) -> void:
	var p := jogador(l)
	var alto := maxf(VOO_MIN_M, VOO_M * CenarioDoImpacto.gancho(l, "empurrao") * Itens.resiste_a_empurrao(l))
	var meia := 30.0 / Ritmo.bpm
	var tw := p.create_tween()
	tw.tween_property(p, "position", Vector3(RAIAS[l] * PUXA_PARA_O_MEIO, alto, Z_JOGADOR - 1.5), meia) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "position", Vector3(RAIAS[l], 0.0, Z_JOGADOR), meia) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	p.gesto("fall", meia * 2.0)
	_caido[l] = true
	get_tree().create_timer(meia * 2.0).timeout.connect(func(): p.animar("die"))
	get_tree().create_timer(meia * 2.0 + CenarioDoImpacto.queda_s(l, QUEDA_TEMPOS)).timeout.connect(func():
		if _caido[l]:
			p.animar("idle"))
	_fumaca[l] = Efeitos.poeira(self, Vector3(RAIAS[l], 0.6, Z_JOGADOR), Vector3(0.8, 1.2, 0.8), Tema.GRAFITE, 16)
```

`_estourar(l)` chama, nesta ordem: `explosoes[l] += 1`, `Forja.sentir(l, "explosao")`,
`Forja.gatilho(l, 1, Forja.GATILHO_OFF)`, `Som.tocar("golpe", pos, 0.0)`,
`Efeitos.faiscas(self, pos, Tema.TUNGSTENIO, FAISCAS_DO_ESTOURO, 1.6)`,
`CenarioDoImpacto.exagero(self, _cenario, "estrondo", jogador(l))` (tremor 0,05 m por 2 batidas, hit-stop de 3
quadros), `CenarioDoImpacto.so_o_dono(self, l)`, a marca preta, `_voar(l)` e o `momento`.

**O escorregão:** a bomba cai da cabeça para o chão da raia e volta para a mão em meia batida (tween);
`jogador(l).gesto("emote-no", 0.4)`; o kit já sentiu o `erro`. É a falha pequena (degrau golpe, sem tremor
próprio); a grande é o estouro.

## As reações

- **Carimbos que o Curto-Circuito pode disparar** (do kit e do HUD, G04; o minigame não chama nenhum):
  `car_em_chamas` (5 passes Ressonância seguidos do mesmo lugar); `car_por_um_fio` (no resultado, quando o
  vencedor ganha por 2 % dos pontos ou menos). O `car_acorde` não acontece: só um segura a bomba.
- **Adesivos:** só quem está fora da rodada manda: o caído, do estouro até a rodada seguinte
  (`fora_da_rodada(l)` devolve `true`). A roda de adesivos (G04) lê esse gancho; até ela o ler, ninguém manda.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: o estouro** (`estouro`). A bomba estoura na mão de alguém: 60 faíscas, o cavaleiro voa 2,5 m em
direção ao meio da tela e cai de volta, a câmera treme 0,05 m por 2 batidas, a luz das outras raias cai 30 % por 1
batida: a sala olha para o dono. Degrau estrondo. Um por rodada: quatro por partida.

- **Rastro:** a marca preta no chão da raia fica até o fim (o placar de estouros no mundo); o caído fica
  estirado e depois sentado com fumaça até a rodada seguinte.
- **A curva:** a rodada 1 ensina (pavio longo, na batida); as rodadas 2 e 3 são o pico (pavio curto, na colcheia:
  a bomba roda o dobro); a rodada 4 volta à batida com pavio longo: o fim tenso.
- **Ensina sem falar:** o coração começa devagar e acelera; na primeira rodada, alguém estoura com o golpe
  batendo na mão, e a sala aprende o que o golpe quer dizer.
- **Quem está perdendo:** quem estourou menos começa com a bomba; o pavio nunca acaba duas rodadas seguidas no
  mesmo lugar (só se ele segurar as quatro chances).
- **A nota de hoje:** 5. Não mexer na regra.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, pela
prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | a primeira linha `toque` sai até 3 s; o 1.º `estouro` até 10,5 s | o quadro de 10 s mostra a bomba na cabeça de alguém ou o voo |
| 4. o momento | exatamente 4 linhas `momento` `estouro`, uma por rodada, de pelo menos 2 lugares | o último quadro tem marcas pretas em pelo menos 2 raias |
| 5. a curva | a bomba troca de mão por segundo nas rodadas 2 e 3 ≥ 1,5 × na rodada 1 | o quadro do meio da rodada 2 tem a luz 20 % acima do da rodada 1 |
| 6. a falha | o P4 tem pelo menos 1 escorregão (`toque` com `erro`) por rodada em que segurou | 1 quadro em 5 mostra um caído com fumaça ou a bomba no chão |
| 7. quem perde joga | não se aplica a regra das 8 batidas (só quem segura tem nota); o P4 segura a bomba em pelo menos 3 das 4 rodadas | o P4 aparece em 100 % dos quadros |
| 8. a câmera | cada `estouro` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | o voo se vê no quadro de 480 × 270 sem ampliar |
| 9. o impacto | para cada `estouro`, uma `sensacao` `explosao` a até 16,7 ms | a marca preta se vê no quadro seguinte |
| 10. o placar no mundo | a ordem do `vencedor()` bate com o número de marcas pretas por raia | no último quadro, quem olha diz quem estourou menos pelas marcas |

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto) existir, a prova do jogo confere os
itens 1, 4, 8, 9 e 10 com o `--robo` dela; os itens 6 e 7 esperam o robô por lugar.

## Pronto quando

O Curto-Circuito joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o boneco de palha) e com o robô nos três
temperamentos; aguenta o cabo que cai com a bomba na mão; fecha com vencedor; grava 4 estouros de pelo menos 2
lugares; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` (com `--semente=N` que sorteie o
`S04_J18` na noite, pelo `Catalogo.sortear` da H08).

Em `godot/testes/prova_do_jogo.gd`, depois das outras da seção:

```gdscript
## Curto-Circuito (S04_J18): uma bomba só (o R2 pesado em um controle por
## vez), a roda dos vizinhos, os quatro estouros e o vencedor por estouros.
func _prova_do_curto_circuito() -> void:
	var dois_com_ela := [0]
	var alguem_com_ela := [false]
	var olhar := func(mg: Minigame) -> void:
		var com := 0
		for l in mg.presentes():
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				com += 1
		if com >= 2:
			dois_com_ela[0] += 1
		if com == 1:
			alguem_com_ela[0] = true
	var mg = await _joga_o_minigame("S04_J18", 140.0, olhar)
	if mg == null:
		return
	_esperar(alguem_com_ela[0], "Curto-Circuito: a bomba pesou no R2 de quem segurava")
	_esperar(dois_com_ela[0] <= 2, "Curto-Circuito: nunca dois com a bomba (%d quadros)" % dois_com_ela[0])
	if mg.presentes().size() == 4:
		_esperar(mg._vizinho(0, 0) == 3 and mg._vizinho(0, 1) == 1 and mg._vizinho(3, 1) == 0, "Curto-Circuito: a roda dos vizinhos")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.explosoes[v[0]]) == v.map(func(l): return int(mg.explosoes[l])).min(), "Curto-Circuito: vence quem estourou menos")
	var estouros := _linha_do_tempo().filter(func(e): return e.get("slot") == "S04_J18" \
		and e.get("tipo") == "momento" and e.get("nome") == "estouro")
	_esperar(estouros.size() == 4, "Curto-Circuito: %d estouros (um por rodada)" % estouros.size())
	if mg.presentes().size() >= 2:
		var donos := {}
		for e in estouros:
			donos[int(e.get("lugar", -1))] = true
		_esperar(donos.size() >= 2, "Curto-Circuito: os estouros de pelo menos 2 lugares (%s)" % [donos.keys()])
	for e in estouros:
		_esperar(float(e.get("x_tela", 0.0)) >= 0.2 and float(e.get("x_tela", 0.0)) <= 0.8 \
			and float(e.get("altura_tela", 0.0)) >= 0.08, "Curto-Circuito: o voo no meio da tela (%s)" % [e])
```

(`_joga_o_minigame` é da H08; `_linha_do_tempo` da F01.)

### O que o registro mede

- Cada pulso do coração (`sensacao`, com `seq` e `ok` na `saida`) só no controle de quem segura, e a `pista`
  (`"ambos"`, `faltam`) a cada mudança de faixa do pavio.
- O passe (`toque` do kit) e a chance perdida; o fantasma (quem aperta sem segurar, com quem segurava).
- A `saida` de gatilho (Resistência 3, 6, 8, e Off) de cada troca de dono; o `momento` `estouro`.

### As pranchas que o jogador do time olha

O quadro de 10 s (a bomba na cabeça ou o voo), o primeiro depois de cada estouro (a marca preta, o caído com
fumaça), o do meio da rodada 2 (a luz mais alta e a câmera mais longe) e o último (as marcas pretas: o placar).

### O que o André joga e sente

`./run-local.sh -- --sala=S04_J18`, com quatro DualSense:

- o coração na mão é claro e acelera; dá medo segurar quando ele dispara;
- o passe no tempo faz a bomba rodar em hoqueto; no pico, gira o dobro;
- o R2 pesa com a bomba e solta ao passar;
- o estouro é engraçado (o voo, a fumaça) e ninguém sai do jogo;
- a barra de luz nunca entrega quem está com a bomba.

### Armadilhas

- **Uma bomba, uma nota:** só quem segura tem nota; ao entregar, limpe a nota de quem passou.
- **O vizinho pula quem está sem controle** e nunca é o próprio lugar (com um jogador, é o `BONECO`, que não é
  índice de `pontos`).
- **O pavio é em batidas**, secreto; a faísca da bomba pulsa igual para todos (2,7 vezes por s, abaixo das 3
  piscadas por segundo).
- **O coração não repete na mesma grade:** `_ultimo_pulso` guarda o índice.
- **O R2 de quem não segura fica Off**; o L2 é do item (G03): nunca `gatilhos_off` no meio do jogo.
- **Os 100 s são o teto**, não o fim normal: as quatro rodadas acabam antes.
- **O `_adiado`** só vale para o pavio; a quarta chance perdida estoura sempre.

### Ao terminar

- No [quadro](README.md): a linha **L3**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer): `feat: Curto-Circuito, a bomba de mão em mão, com o pavio que só a mão sente`
