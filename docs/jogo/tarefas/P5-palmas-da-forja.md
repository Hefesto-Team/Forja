# P5 — Palmas da Forja

**Sprint:** P · **Slot:** S08_J40 · **Tamanho:** M · **Depende de:** P1, H04, H06, H07, H08, F09, G03, G04, G05, G08, G10, G13, G14, G15

## Por quê

Festa na forja. O ferreiro bate na bigorna e a turma inteira segura o ritmo com **palmas**: o microfone de cada
controle ouve as mãos de quem o segura. No fim de cada frase, ele faz uma virada, e a turma responde. É coop puro: a
espada lendária só sai se a sala bate junto. É o minigame em que ninguém precisa do controle na mão (o controle fica
no colo, ouvindo).

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- A P1, as partes [«O ouvido inteiro (`ouvido.gd`)»](P1-a-voz.md#o-ouvido-inteiro-godotscriptsminigamess08ouvidogd) (a voz, os 6 dB, o mudo, a escuta) e [«O
  cenário comum (`cenario_da_voz.gd`)»](P1-a-voz.md#o-cenário-comum-godotscriptsminigamess08cenario_da_vozgd) (a cripta, a câmera, o exagero, os ganchos do cavaleiro). A P1 cria os dois em
  `godot/scripts/minigames/s08/`; se ela já entrou, valem os arquivos, e esta ficha só os chama.

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s08/palmas_da_forja.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S08_J40` em `MINIGAMES` e na seção `S08` | **da seção**: uma linha |
| `godot/scripts/traducoes.gd` | `"Palmas da Forja"`, `"Bata palma!"`, `"%d palmas"`, `"Espada %d de %d"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_palmas_da_forja()` e a linha `"S08_J40": await _prova_palmas_da_forja()` no `match slot` de `_prova_da_ficha(slot)` (H08) | **de todos** |

O `.uid` novo (`palmas_da_forja.gd.uid`) sai do import `"$GODOT" --headless --path godot --import --quit` e entra no
commit. Esta ficha não mexe em `ouvido.gd`, `cenario_da_voz.gd`, `musica.gd` nem `minigame.gd`.

### O que muda de hoje

As Palmas da Forja não existem hoje. Elas nascem no kit. Da ficha antiga mudam:

- o verbo: «Bata palmas!» vira «Bata palma!»;
- a ferraria: vira a cripta da seção, sem as bandeiras nem a luz laranja `#ffb070` com o `Tema.ROSA`;
- o andamento: virada em toda frase no começo, só a base no meio, e chamada e resposta a cada 2 compassos na reta;
- as cores: o ferreiro em `Tema.OXIDO_BRILHO` (era `#6b4a32`) e a espada em `Tema.GRAFITE` com a runa em
  `Tema.TUNGSTENIO` (era `#9aa3b5`);
- o som da palma que desafina: `pedra`, no lugar do `falha` (o bipe é proibido);
- a mão: as 4 barras de luz piscam juntas quando a palma da turma entra.

### O kit que esta ficha usa

As do kit (H04, H08): `presentes()`, `conectado(l)`, `raia(l)`, `jogador(l)`, `posicionar(l)`, `acender_raia(l, f)`,
`nova_nota(l, n, t)`, `notas_em_aberto(l)`, `alvo_da(l, n)`, `julgar_nota(l, n)`, `notas_perdidas(l)`,
`nota_perdida(l, n)`, `anotar`, `marcar`, `aprendeu(l)`, `momento(nome, l, pos, altura_m, campos)`, `coop_venceu`,
`RAIAS`, `Z_JOGADOR` (1,4), `BATIDA_DA_PRIMEIRA_NOTA` (4).

Do ouvido (P1): `Ouvido.new(self)`, `comecar()`, `ouvir(dt)`, `nova_voz(l, n, bn)`, `casar_voz(l)`, `escuta[l]`,
`sozinho(l)`, `falante(l, som, ganho, ms)`, `sentir(l, nome)`, `depois(l, f)`, `fechar()`, `janela_casa` (0,25). O
ouvido chama `_comecou(l)`, `_parou(l)` e `_mudou(l, mudo)`.

Do cenário comum (P1): `CenarioDaVoz.pose_da_camera()`, `montar(sala)`, `passar`, `exagero`, `gancho(l, nome)`,
`queda_s(l, tempos)`, `antecedencia(l)`.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Palmas da Forja (S08_J40). O ferreiro pede o ritmo na bigorna e a turma
## segura com palmas: o microfone de cada controle ouve as mãos de quem o
## segura. Palmas no 2 e no 4; no fim da frase, a virada dele, e a turma responde.
##
## A falha: a palma que desafina entorta a espada (coletiva).
## O vencedor: coop (a espada lendária); o destaque é quem cravou mais palmas.
## O alto-falante do dono: a nota dele na palma perfeita; a coleta a cada 10 golpes.
## O registro mede: cada palma de cada controle (`voz`, `toque`), a palma da
## turma (`entrada`), o momento `lendaria`.
## O robô: bate pelo controle simulado (uma fala curta e alta).
## Com menos de quatro: a metade da turma é a de quem joga.
## A régua: (1) "Bata palma!" e o ícone do microfone; (2) sim: os quatro
## cavaleiros batem palma na contagem; (3) não pergunta nada.

const FICHA := {
	"slot": "S08_J40",
	"titulo": "Palmas da Forja",
	"verbo": "Bata palma!",
	"genero": "coop",
	"icone": "microfone",
	"entradas": [],  # a palma, que não é botão
	"camera": "fixa",
	"faixa": "MUS_S08_J40",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["toque", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Bata palma!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,
	"textura_no_acerto": false,  # a textura vai pelo ouvido.depois, fora da escuta
	"nota_no_falante": false,
	"gesto": "interact-left",
}

const Ouvido := preload("res://scripts/minigames/s08/ouvido.gd")
const VIRADAS := [[0.0, 1.0, 2.0, 3.0], [0.0, 0.5, 1.0, 2.0], [0.0, 1.5, 2.0, 3.0], [0.0, 0.5, 1.5, 2.0, 3.0], [1.0, 1.5, 2.0, 2.5, 3.0]]
const JANELA_CASA := 0.25  ## o padrão do ouvido: palmas a meia batida (0,254 s) não casam com a vizinha
const FRASES_COM_VIRADA := 4  ## as frases 0 a 3: base, chamada e resposta
const RETA_DE := 7  ## da frase 7 em diante: chamada e resposta a cada 2 compassos
const PICO := 5  ## a frase 5: palma em toda batida
const META := 0.7  ## a espada lendária pede ceil(0,7 × as palmas pedidas)
const PONTOS := [0, 50, 75, 100]
const QUEDA_TEMPOS := 1.0  ## quem bate fora do tempo se encolhe 1 tempo (a queda da P5)
const LENDARIA_ANTES_S := 75.0
const ESPADA := Vector3(0.1, 1.56, -2.4)  ## o centro da lâmina, em cima do tampo da bigorna
const BIGORNA := Vector3(0.0, 0.0, -2.4)
const FERREIRO := Vector3(0.0, 0.0, -3.4)
const LAMINA := 1.6
const LAMINA_FIM := 2.2  ## nas últimas 16 batidas, a lâmina cresce até 2,2 m
const LUZ_BASE := 0.3  ## a barra de luz fica a 30 % da cor; a palma da turma pisca as 4 a 100 % por 0,1 s
const LUZ_TURMA_S := 0.1
```

### Os números de 118 bpm

Uma batida dura 0,508 s. `B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))` = 177 (90 s). A frase tem 16
batidas, a partir de `f0 = BATIDA_DA_PRIMEIRA_NOTA + 16k`. Até a H05, a reserva `"sopro"` toca a 105 bpm, e `B_FIM` =
157: tudo conta por batida e por `B_FIM`.

| frases | batidas | segundos | o que acontece |
| --- | --- | --- | --- |
| — | 0–3 | 0–1,5 | a contagem (H06): os quatro cavaleiros batem palma nas batidas 1 e 3 (só o gesto) |
| 0 a 3 | 4–67 | 2,0–34,6 | **a frase inteira**: a base nos compassos 0 e 1, a chamada no 2, a resposta no 3 |
| 4 e 6 | 68–83, 100–115 | 34,6–42,7, 50,8–58,5 | **só a base**, nos 4 compassos: o meio da partida |
| 5 (**o pico**) | 84–99 | 42,7–50,8 | palma em **toda** batida (16 seguidas) |
| 7 em diante (**a reta**) | 116–176 | 59,0–89,5 | chamada e resposta a cada 2 compassos, sem base |
| — | 161–176 | 81,9–89,5 | as últimas 16 batidas: a lâmina cresce |

### A frase

| compasso | batidas | o que acontece |
| --- | --- | --- |
| 0 e 1 | `f0` a `f0 + 7` | **a base:** palma no 2 e no 4, as batidas `+1` e `+3` do compasso |
| 2 | `f0 + 8` a `f0 + 11` | **a chamada:** o ferreiro bate a virada na bigorna (TV); ninguém bate |
| 3 | `f0 + 12` a `f0 + 15` | **a resposta:** a turma bate a mesma virada |

As viradas são as batidas dentro do compasso, na ordem, voltando ao começo: `VIRADAS[v % 5]`, com `v` contando cada
chamada da partida (as 4 frases inteiras e as da reta). A primeira tem 4 palmas no tempo; a segunda e a quarta já
pedem a meia batida.

### O plano

```gdscript
## Todas as palmas pedidas e as batidas da chamada, uma vez, no iniciar_jogo().
func _planejar() -> void:
	var v := 0
	var k := 0
	while BATIDA_DA_PRIMEIRA_NOTA + 16 * k < _b_fim:
		var f0 := float(BATIDA_DA_PRIMEIRA_NOTA + 16 * k)
		if k < FRASES_COM_VIRADA:
			_base(f0, 2)
			_virada(f0 + 8.0, v)
			v += 1
		elif k < RETA_DE:
			if k == PICO:
				for i in 16:
					_pedir(f0 + i)
			else:
				_base(f0, 4)
		else:
			_virada(f0, v)
			_virada(f0 + 8.0, v + 1)
			v += 2
		k += 1
	_pedidas = _pedidas.filter(func(p): return float(p.bn) < _b_fim)
	_chamadas = _chamadas.filter(func(c): return float(c) < _b_fim)


func _base(f0: float, compassos: int) -> void:
	for c in compassos:
		_pedir(f0 + 4 * c + 1, true)
		_pedir(f0 + 4 * c + 3)


## A chamada no compasso c0 (o ferreiro) e a resposta no seguinte (a turma).
func _virada(c0: float, v: int) -> void:
	for x in VIRADAS[v % VIRADAS.size()]:
		_chamadas.append(c0 + x)
		_pedir(c0 + 4.0 + x)


func _pedir(bn: float, so_no_dois := false) -> void:
	_pedidas.append({"bn": bn, "dois": so_no_dois, "aberta": false, "fechada": false, "acertos": 0, "contados": 0})
```

A 118 bpm: 33 palmas nas frases 0 a 3, 32 nas frases 4 a 6 e 33 na reta. São 98 palmas pedidas, e a meta é
`ceil(0.7 × 98)` = 69. O `"dois"` marca a palma do 2 na base: com `Ritmo.simples[l]`, o lugar não bate essa (só o 4);
as viradas continuam dele.

### A palma

- **As notas:** cada palma pedida é uma nota de **cada** lugar conectado e fora do `sozinho`, aberta meia batida
  antes: `ouvido.nova_voz(l, n, bn)` em `bn − 0,5` (o alvo é `t(bn) + 0,08`). Todos batem tudo.
- **O `_comecou(l)`:** a palma é um começo de voz (curta e alta: o mesmo começo). Casa com `ouvido.casar_voz(l)`
  (até 0,25 s) e julga com `julgar_nota`. A palma longe de toda nota é ignorada.
- **Pontos:** cada palma julgada marca `PONTOS[j]` para quem bateu, e `_palmas[l] += 1` sem erro.
- **Quem bate fora do tempo** (ERRO) se encolhe: `emote-no` por `CenarioDaVoz.queda_s(l, QUEDA_TEMPOS)`.

### A palma da turma

Quando a janela de uma palma pedida fecha (`t(bn) + 0,08 + FOLGA_PERDIDA`, já sem nota aberta dela), conta-se:

- `m` = os lugares conectados que tinham a nota (com microfone) e os que batem sozinhos;
- `acertos` = os lugares com toque BOM ou melhor nessa palma, mais os sozinhos na vez deles;
- `acertos >= ceili(m / 2.0)` → **a palma entrou**: `_espada += 1`; senão, **desafinou**.

`anotar("entrada", -1, {"o": "palma_da_turma", "bn": bn, "entrou": entrou, "acertos": acertos, "contados": m})`.
Com `m == 0` (todos sem controle), a palma não conta.

- **Entrou:** a runa da espada brilha 2,6 por 1 batida; as 4 barras de luz piscam juntas a 100 % por 0,1 s
  (`Forja.luz(l, Tema.JOGADOR[l])` e de volta a 30 %); a lâmina endireita 0,02 rad; a cada 10 golpes, a coleta no
  alto-falante de todos.
- **Desafinou:** a lâmina entorta (`rotation.z += 0.04`); o ferreiro faz `emote-no` 0,5 s; `Som.tocar("pedra",
  ESPADA, -6.0)` (o som torto). Quem não bateu não faz nada: a falha é coletiva.

### A espada lendária (o momento)

Na primeira vez em que `_espada >= _meta`: `coop_venceu = true` (e fica), `_lendaria_em = Ritmo.t_musica()`,
`momento("lendaria", -1, ESPADA, 2.0, {"espada": _espada, "meta": _meta, "valores": "%s" % [_palmas]})` e
`CenarioDaVoz.exagero(self, _cenario, "catastrofe")`: o tremor de 0,08 m por 4 batidas e a chave a +40 % por 1
batida (+20 % sem flashes). A runa fica a 2,6 até o fim (o rastro), o ferreiro faz `emote-yes`, e a festa continua
até o fim. Com a mesa padrão, a palma da turma entra em 90 % das vezes, e a lendária sai perto da palma 77, na batida 137
(70 s): antes de 75 s (a batida 147).

### O fim e o vencedor

O kit fecha no `duracao` (90 s de música, H08). O `coop` vem do gênero da FICHA. O registro grava `vencedor` −1
(coop). Em `B_FIM`, `ouvido.fechar()`.

```gdscript
## Coop: o kit grava vencedor −1 (H08); o destaque é quem cravou mais palmas.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return _palmas[a] > _palmas[b] or (_palmas[a] == _palmas[b] and pontos[a] > pontos[b]))
	return int(lista[0]) if not lista.is_empty() else -1
```

### Com menos de quatro

- **Três, dois, um:** a metade da turma é `ceil(m / 2)` dos que jogam: com um, a palma dele é a da turma.
  `com_poucos()` devolve `""`.
- **O controle que cai:** sai da conta da turma enquanto estiver fora; volta na próxima palma.
- **Sem microfone ou mudo fora do escudo** (`ouvido.sozinho(l)`): o lugar «bate sozinho, mais fraco». Em cada palma
  pedida, conta como acerto na palma da turma **uma vez sim, uma vez não**, sem nota e sem pontos. A `troca` sai do
  ouvido, uma vez. Se ninguém tem microfone, a turma bate sozinha: a espada anda devagar, mas anda.

### Os ganchos

| gancho | o que faz |
| --- | --- |
| `montar()` | a câmera, `CenarioDaVoz.montar(self)`, o ferreiro com o martelo, a bigorna, a espada; por lugar `raia(l)`, `posicionar(l)`, de frente para a câmera; `gatilhos_off` |
| `iniciar_jogo()` | o ouvido, `_b_fim`, `_planejar()`, `_meta`, `_robo_rng.seed = rng.seed + 99`, a barra de luz a 30 % |
| `jogar(dt)` | `ouvido.ouvir(dt)`, `passar`, as palmas da contagem, a chamada, abrir e fechar as palmas, `notas_perdidas`, `_mostrar` |
| `_comecou(l)` | casa a palma e julga |
| `_parou(l)`, `_mudou(l, mudo)` | nada: a palma desce rápido, e o fim da voz não serve para nada |
| `toque(l, j)` | os pontos, `_palmas`, o gesto; `ouvido.depois(l, ...)`: `Forja.textura(l, "metal", 0.5)` e o falante `nota:%d` no perfeito |
| `falha(l)` | o `emote-no` do encolhido |
| `destaque()` | acima |
| `combo(l)` | as palmas certas seguidas (G04) |
| `status(l)` | `"%d palmas" % _palmas[l]` |
| `progresso()` | `"Espada %d de %d" % [_espada, _meta]` |
| `dica(l)` | `["@mic"]` sob a raia na base, enquanto `not aprendeu(l)`; senão `{}` |

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

O esqueleto:

```gdscript
var ouvido: Ouvido
var _cenario := {}
var _b_fim := 177
var _pedidas := []  ## [{bn, dois, aberta, fechada, acertos, contados}], em ordem
var _chamadas := []  ## as batidas em que o ferreiro bate
var _i_abrir := 0
var _i_fechar := 0
var _i_chamada := 0
var _da_nota := {}  ## "l:n" -> o índice em _pedidas
var _n := [0, 0, 0, 0]
var _vez_sozinho := [0, 0, 0, 0]
var _palmas := [0, 0, 0, 0]
var _ultima_nota := [-1, -1, -1, -1]
var _espada := 0
var _meta := 1
var _lendaria_em := -1.0
var _runa_ate := -1.0
var _fez := {}
var _ferreiro: Node3D
var _lamina: MeshInstance3D
var _runa: MeshInstance3D
var _mat_runa: StandardMaterial3D


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	ouvido.ouvir(dt)
	CenarioDaVoz.passar(self, _cenario, b >= 84.0 and b < 100.0)
	_contagem(b)  # batidas 1 e 3: os quatro batem palma (o gesto)
	_chamada(b)  # o ferreiro martela, a bigorna aguda, a mão de todos sente
	_abrir_palmas(b)  # meia batida antes: uma nota por lugar; o sozinho conta na vez dele
	for l in presentes():
		notas_perdidas(l)
	_fechar_palmas()  # a janela passou: a palma da turma
	if b >= _b_fim and not _fez.has("fim"):
		_fez["fim"] = true
		ouvido.fechar()
	_mostrar(b)  # a lâmina, a runa, o gesto do ferreiro


func _comecou(l: int) -> void:
	var n := ouvido.casar_voz(l)
	if n >= 0:
		julgar_nota(l, n)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_palmas[l] += 1
	var i: int = _da_nota.get("%d:%d" % [l, _ultima_nota[l]], -1)
	if i >= 0:
		_pedidas[i].acertos += 1
	jogador(l).gesto("interact-left" if _palmas[l] % 2 == 0 else "interact-right", 0.2)
	ouvido.depois(l, func():
		Forja.textura(l, "metal", 0.5)
		if j == Ritmo.PERFEITO:
			ouvido.falante(l, "nota:%d" % l, 0.8, 300))


func falha(l: int) -> void:
	jogador(l).gesto("emote-no", CenarioDaVoz.queda_s(l, QUEDA_TEMPOS))
```

`_ultima_nota[l]`: como na P2, troque `julgar_nota(l, n)` por `_julgar(l, n)`, que guarda `_ultima_nota[l] = n`; e no
`nota_perdida`, guarde `_ultima_nota[l] = n` antes do `super`.

`_abrir_palmas(b)`: enquanto `_pedidas[_i_abrir].bn − 0,5 <= b`, abre a palma: para cada lugar presente e conectado,
com `ouvido.sozinho(l)`, `contados += 1` e, se `_vez_sozinho[l] % 2 == 0`, `acertos += 1`
(`_vez_sozinho[l] += 1`); senão, se não for `"dois"` com `Ritmo.simples[l]`, `ouvido.nova_voz(l, _n[l], bn)`,
`_da_nota["%d:%d" % [l, _n[l]]] = _i_abrir`, `contados += 1`, `_n[l] += 1`. A borda da raia acende
(`acender_raia(l, 1.0)`) em `t(bn − 0,5) − CenarioDaVoz.antecedencia(l)` e apaga no julgamento (a pista).

`_fechar_palmas()`: a palma `_i_fechar` aberta, com `Ritmo.t_musica() > t(bn) + 0,08 + FOLGA_PERDIDA` e nenhuma nota
dela ainda aberta, fecha: a palma da turma, acima.

`_chamada(b)`: em cada batida de `_chamadas`, uma vez (`_i_chamada`): o ferreiro faz `attack-melee-right` 0,3 s,
`Som.tocar("bigorna_aguda", BIGORNA + Vector3(0, 1.5, 0), -4.0)` e `ouvido.sentir(l, "toque")` em todos (a virada
também na mão, para quem não ouve bem a TV). Na chamada ninguém escuta: as palmas da base acabam antes.

O catálogo: `Catalogo.MINIGAMES["S08_J40"] = preload("res://scripts/minigames/s08/palmas_da_forja.gd")` e
`"S08_J40"` na seção `S08`. As traduções: `"Palmas da Forja": "Forge Clapping"`, `"Bata palma!": "Clap!"`,
`"%d palmas": "%d claps"`, `"Espada %d de %d": "Sword %d of %d"`.

## A cena

### A câmera

A da P1: `CenarioDaVoz.pose_da_camera()`, 35 mm, plongée de 50°, a 13,5 m de `(0; 1,2; −1,6)`, o modo `fixa`. A
borda de baixo, no chão, cai em z 2,63; a meia largura na altura dos cavaleiros é de 7,1 m. O ferreiro em z −3,4 e a
espada em z −2,4 ficam no terço de cima. No pico, a câmera recua 10 % (`pose_da_camera(1.1)`). Roll zero; o tremor é
só o do `exagero`.

### A luz da seção

A da P1, pelo `CenarioDaVoz.montar(self)`: `Tema.luz_da_secao(8, true)`, a chave a 0,77. No pico, a chave sobe 20 % em
1 batida (10 % sem flashes). A lendária é catástrofe: a chave a +40 % por 1 batida.

A barra de luz de cada um fica a 30 % da cor do lugar (`Tema.JOGADOR[l].darkened(0.7)`). Quando a palma da turma
entra, as 4 piscam juntas a 100 % por 0,1 s: a sala vê que bateu junto.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| a cripta, as tochas, as velas, as colunas | `CenarioDaVoz.montar(self)` | o fundo comum da seção |
| `mini-dungeon-personagens/character-orc` | `FERREIRO = (0, 0, −3.4)`, de frente para a câmera | **o ferreiro**: não é lugar; tingido de `Tema.OXIDO_BRILHO` |

O ferreiro: o modelo vem de `Kit.caminho("mini-dungeon-personagens/character-orc")`, tingido pelo `_tingir` copiado
de `prova.gd:200-210` (um `StandardMaterial3D` por superfície, `albedo_color` `Tema.OXIDO_BRILHO` e `roughness` 0,9).
O martelo vai no osso `arm-right`, como o `martelo_na_mao` da `SalaJogo`, copiado para o nó dele:

```gdscript
var esq: Skeleton3D = _ferreiro.find_child("Skeleton3D", true, false)
var presa := BoneAttachment3D.new()
presa.bone_name = "arm-right"
esq.add_child(presa)
var m := Kit.martelo(presa, 0.5)
m.position = Vector3(-0.035, -0.12, 0.05)
m.rotation_degrees = Vector3(0, 0, 14)
```

O que não é peça Kenney (`metallic` 0):

| objeto | forma | onde | material |
| --- | --- | --- | --- |
| a bigorna | `Kit.bigorna(self, BIGORNA, 1.2)` | `(0, 0, −2.4)`; o tampo fica em y 1,54 | a do `Kit` |
| a lâmina | caixa `LAMINA` × 0,05 × 0,14 (1,6 m ao longo de x) | `ESPADA = (0.1, 1.56, −2.4)`, deitada no tampo | `Kit.material(Tema.GRAFITE, 0.0, 0.35)` |
| a runa | caixa `LAMINA − 0.2` × 0,01 × 0,04 | em cima da lâmina, y 1,59 | `Tema.neon(Tema.TUNGSTENIO, e, "forja")`, `e = 2.0 × _espada / _meta`; 2,6 por 1 batida na palma que entra; 2,6 fixo depois da lendária |
| a guarda | caixa 0,06 × 0,08 × 0,4 | `(−0.73, 1.57, −2.4)` | `Kit.material(Tema.OXIDO, 0.0, 0.9)` |
| o punho | caixa 0,36 × 0,07 × 0,07 | `(−0.94, 1.57, −2.4)` | `Kit.material(Tema.OXIDO, 0.0, 0.9)` |

**A espada, pela batida.** A lâmina entorta 0,04 rad a cada palma que desafina e endireita 0,02 a cada uma que
entra, de 0 a 0,3. Nas últimas 16 batidas, a lâmina e a runa crescem de `LAMINA` a `LAMINA_FIM` (`scale.x`, `lerpf`
pela batida), a partir da guarda.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a borda da raia | o lugar | o kit (`acender_raia`), meia batida antes de cada palma |
| a runa da espada | a forja (é da turma) | de 0 a 2,0 pela meta; 2,6 na palma que entra e depois da lendária |
| as tochas | a forja | 1,8 (o cenário comum) |

O ferreiro é `Tema.OXIDO_BRILHO`, a lâmina é `Tema.GRAFITE`, o punho é `Tema.OXIDO`: sem brilho. Somem os `#6b4a32`,
`#9aa3b5`, `#ffb070`, o `Tema.ROSA` e as bandeiras da ficha antiga. Nenhuma cor de lugar no cenário.

### A montagem

- Por lugar: `raia(l)`, `posicionar(l)`, de frente para a câmera (`rotation.y = 0`), `preso = true`. O boneco faz
  `interact-left` e `interact-right` alternados a cada palma dele.
- O ferreiro, a bigorna e a espada, nesta ordem, atrás das raias.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a chamada | `Som.tocar("bigorna_aguda", ..., -4.0)` em cada batida do ferreiro | — | `bigorna_*` |
| a palma certa | a nota do kit (`Som.tocar("nota", ...)`, H08) | `nota:%d`, 0,8 (300 ms) no perfeito, depois da escuta | `nota_*` |
| a palma da turma entrou | `Som.tocar("bigorna", ESPADA, -8.0)`, só se ninguém escuta | a cada 10 golpes, `coleta` 0,7 (300 ms) em todos, depois da escuta | `bigorna_*`, `mod_coleta` |
| desafinou | `Som.tocar("pedra", ESPADA, -6.0)`, só se ninguém escuta | — | `pedra_*` |
| a lendária | `Som.tocar("sucesso", null, -4.0)` e `Som.tocar("fogo", ESPADA, -6.0)` | — | `sucesso_*`, `fogo_*` |
| a faixa | `MUS_S08_J40`: 118 BPM, Lá menor; até ela existir, a reserva `"sopro"` (105 bpm) | — | `mus_s08_j40` |

- **A música desce 12 dB enquanto um microfone escuta.** No pico, com palma em toda batida, a escuta abre 0,25 s
  antes de cada uma e fecha no julgamento: a música fica abaixada quase o tempo todo. É o que o mapa do áudio pede
  (a palma da sala é a música).
- **O som da palma da turma não entra em microfone que escuta.** Com palmas a meia batida, a próxima já escuta
  quando a anterior fecha: o `bigorna` e o `pedra` só tocam se `not ouvido.escuta.has(true)`; senão, a runa e a
  lâmina mostram.
- **O `falha` não existe aqui.** O material `"metal"` toca pelo minigame, na palma certa, depois da escuta.

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar a 30 % | — |
| a chamada | todos | `toque` em cada batida do ferreiro | — | — | — |
| a palma certa | o dono | a textura `metal` 0,5 depois da escuta; sem háptica, `toque` | — | — | `nota:%d` no perfeito |
| a palma ERRO | o dono | o kit: `erro` | — | o kit | — |
| a palma da turma entrou | todos | — | — | **as 4 juntas a 100 % por 0,1 s** | `coleta` a cada 10 golpes |
| a lendária | todos | `golpe` (fora da escuta; dentro, o ouvido troca por `toque`) | — | — | — |

- **A mão quieta na escuta:** o `ouvido.sentir` troca o forte por `toque`; a textura do acerto espera o fim da
  escuta.
- **No rádio:** sem microfone nem alto-falante. O lugar bate sozinho desde o começo, com a `troca` gravada pelo
  ouvido. A háptica do kit vai pelo rumble. A luz do mudo passa pela ponte.

### O robô

```gdscript
# O robô bate pelo controle simulado: uma fala curta e alta (a palma).
# Quando erra: metade das vezes bate 0,2 s tarde (ERRO), metade não bate.
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_feita := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	for n in notas_em_aberto(l):
		if int(n) <= int(_robo_feita[l]):
			continue
		if int(_robo_nota[l]) != int(n):
			_robo_nota[l] = n
			var certo := Forja.robo_acerta()
			_robo_mira[l] = 0.0 if certo else (0.2 if _robo_rng.randf() < 0.5 else 99.0)
		if Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]):
			Forja.robo_falar(l, 0.9, 0.08)
			_robo_feita[l] = n
		break
```

Duas palmas a meia batida (as viradas) dão 0,254 s entre as falas do robô: o `robo_falar` de 0,08 s cabe, e o ouvido
vê dois começos. A palma 0,2 s tarde casa (até 0,25 s) e é ERRO; o `99.0` nunca chega.

## O cavaleiro

O cavaleiro é o da montagem (G13), de frente para a câmera, de mãos livres. O cavaleiro pode ser de outra raça (G13,
o ajuste dela de 09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos e as animações
`interact-left`, `interact-right`, `emote-no` e `idle`.

| stat | gancho | o que muda nas Palmas | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | — | não age (ninguém empurra) | — | — | — |
| Passo | — | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | o encolhido do ERRO (1 tempo) | 1,25 tempo | 1 tempo | 0,75 tempo |
| Faro | `pista` | a borda da raia acende antes da palma; a palma cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); o Fole devolve metade do combo; a Lanterna adianta a borda
da raia meio tempo; o Martelo dobra o perfeito no tempo forte (o kit); o Diapasão é do kit (a nota 1,3× e o perfeito
puxa o combo da equipe); a Âncora não age. Nenhum stat muda a janela de julgamento nem a conta da palma da turma.

## As reações

- **Carimbos** (do kit e do HUD, G04; as Palmas não chamam nenhum): `car_acorde` (os quatro batem certo na mesma
  palma: é o carimbo destas Palmas), `car_em_chamas` (5 Ressonâncias seguidas do mesmo lugar). O `car_por_um_fio`
  não acontece: é coop.
- **Adesivos:** ninguém sai da rodada; nenhum adesivo durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: a espada lendária** (`lendaria`). A turma segura o ritmo, a runa enche, e numa palma a espada acende
inteira: a cripta treme e clareia. É a conquista da sala. Degrau catástrofe.

- **Rastro:** a runa fica acesa a 2,6 até o fim; a lâmina mostra cada desafinada pela torção. A mesa ruim chega perto
  da metade da meta (34 de 69) e não acende: a espada morna mostra quanto faltou.
- **A curva:** de 2 a 34,6 s, as frases inteiras (a base, a chamada, a resposta); de 34,6 a 59 s, só a base, com o
  pico de 42,7 a 50,8 s (palma em toda batida); de 59 s ao fim, a reta: chamada e resposta a cada 2 compassos; nas
  últimas 16 batidas, a lâmina cresce.
- **Ensina sem falar:** na contagem, os quatro cavaleiros batem palma no 2 e no 4; a chamada vem na TV e na mão antes
  da resposta.
- **Quem está perdendo:** é coop. Quem erra não tira a palma da turma se a metade acertou.
- **A nota de hoje:** 4. Gênero `coop`.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | a primeira palma pedida é a batida 5 (2,5 s); cada lugar tem um `toque` com `t_musica` ≤ 10,0 | o quadro de 1 s mostra os quatro batendo palma |
| 4. o momento | a linha `momento` `lendaria` antes de 75 s com a mesa padrão; antes de 80 s com `ROBO=medio` | o quadro seguinte à lendária mostra a runa acesa e a cripta mais clara |
| 5. a curva | há `nota` em toda batida de 84 a 99; não há chamada de 68 a 115; na reta, as chamadas vêm a cada 8 batidas | o quadro de 46 s mostra a câmera mais longe |
| 6. a falha | o P4 tem pelo menos 3 `toque` com `erro` ou `nota` perdida; pelo menos 1 `entrada` `palma_da_turma` com `entrou` falso | a lâmina aparece torta em 1 quadro em 10 |
| 7. quem perde joga | o P4 tem nota em toda palma pedida (ou o sozinho, uma sim uma não); o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | a `lendaria` tem 0,05 ≤ `x_tela` ≤ 0,95 e `altura_tela` ≥ 0,06 | o ferreiro e a espada inteiros no quadro de 480 × 270 |
| 9. o impacto | toda `entrada` `palma_da_turma` que entrou tem a `saida` de luz dos quatro lugares no mesmo `seq` | o quadro seguinte à palma que entra mostra a runa a 2,6 |
| 10. o placar no mundo | o `valores` da `lendaria` bate com `_palmas`; a `espada` dela é ≥ a `meta` | no quadro de 60 s, a runa brilha mais que no de 20 s |

A mesa padrão roda em duas rodadas até o robô por lugar existir: `ROBO=medio SALA=S08_J40 bash
tests/prova_do_jogo.sh` (os itens 1, 4, 5, 8, 9 e 10) e `ROBO=ruim SALA=S08_J40 bash tests/prova_do_jogo.sh` (os itens 6 e 7). A variável `ROBO` é da
P1 (em `tests/prova_do_jogo.sh`); `--robo=medio` depois do comando não chega ao Godot. Com `ROBO=ruim`, a espada não acende.

## Pronto quando

As Palmas da Forja jogam do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos. Aguentam
o cabo que cai e volta, e fecham com o resultado coop e o destaque. A espada lendária acende com a mesa padrão antes
de 75 s e não acende com a mesa ruim. Nada forte vibra na escuta. `SALA=S08_J40 bash tests/prova_do_jogo.sh` passa (sem e com `--bancada`), e
`bash tests/prova_visual.sh` passa com a prancha olhada (o ferreiro martelando, os bonecos batendo palma, a espada
brilhando).

## Provas

Na sessão, nesta ordem:

```bash
bash tests/prova_do_jogo.sh                              # o percurso: nada que já passava quebrou
SALA=S08_J40 bash tests/prova_do_jogo.sh                 # o minigame inteiro, sem e com --bancada
ROBO=medio SALA=S08_J40 bash tests/prova_do_jogo.sh      # a régua, a rodada do medio
ROBO=ruim SALA=S08_J40 bash tests/prova_do_jogo.sh       # a régua, a rodada do ruim
bash tests/prova_visual.sh                               # as pranchas
```

Em `godot/testes/prova_do_jogo.gd`, a função entra no `match slot` de `_prova_da_ficha(slot)` da H08, ao lado da
linha da P1 (o percurso não joga 90 s de cada minigame):

```gdscript
		"S08_J40":
			await _prova_palmas_da_forja()
```

A função:

```gdscript
## S08_J40: o robô bate as palmas no microfone simulado; a espada ganha golpes;
## a palma da turma segue a metade; nada forte vibra na escuta; o resultado é coop.
func _prova_palmas_da_forja() -> void:
	var forte := [0]
	var olhar := func(mg) -> void:
		if mg.ouvido == null:
			return
		for l in mg.presentes():
			if not mg.ouvido.escuta[l]:
				continue
			var pc := Forja.percepcao(l)
			if maxf(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0))) > 0.75:
				forte[0] += 1
	var mg = await _joga_o_minigame("S08_J40", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg._espada >= 1, "Palmas: a espada ganhou golpes (%d)" % mg._espada)
	_esperar(mg.coop and mg.destaque() >= 0, "Palmas: o resultado é coop, com o destaque")
	_esperar(mg._palmas.max() >= 1, "Palmas: alguém cravou palmas (%s)" % [mg._palmas])
	_esperar(forte[0] == 0, "Palmas: nada forte vibrou na escuta (%d)" % forte[0])
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S08_J40")
	var turma := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("o") == "palma_da_turma")
	_esperar(turma.size() >= 10, "Palmas: a palma da turma contou (%d)" % turma.size())
	for e in turma:
		var metade := ceili(int(e.get("contados", 0)) / 2.0)
		_esperar(bool(e.get("entrou")) == (int(e.get("acertos", 0)) >= metade), "Palmas: a metade da turma (%s)" % [e])
	var lendaria := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "lendaria")
	if Forja.robo_temperamento == "ruim":
		_esperar(lendaria.is_empty(), "Palmas: a mesa ruim não acende a espada")
	elif Forja.robo_temperamento == "medio":
		_esperar(lendaria.size() == 1 and float(lendaria[0].get("t_musica", 99.0)) < 80.0, "Palmas: a lendária antes de 80 s (%s)" % [lendaria])
```

`Forja.robo_temperamento` é o temperamento da F09 (`var robo_temperamento := ""` em `forja.gd`). Com `ROBO=medio`, cada
robô acerta 66 %: a palma da turma entra em 88 % das vezes, e a meta (69) chega perto da palma 78, entre as batidas
138 e 144 (70 a 73 s). A prova aceita até 80 s (a batida 157) pela variação do sorteio; os 75 s são da mesa padrão.
Com `ROBO=ruim`, a turma entra em 35 % das vezes: a espada para perto de 34.

### O que o registro mede

- `voz` de cada palma (o nível: a palma é o pico mais curto da seção, e a noite vê a resposta do microfone a um
  transiente, por controle e por transporte).
- `nota` e `toque` de cada palma, com o desvio; a noite compara o desvio da resposta com o da base.
- `sensacao` `toque` da chamada.
- `entrada` `palma_da_turma`, com os acertos e os contados; `momento` `lendaria`.
- `troca` de `microfone` para `sem_microfone`.

### As pranchas que o jogador do time olha

- o quadro de 1 s: os quatro batendo palma na contagem;
- o de 20 s: o ferreiro martelando a chamada;
- o de 46 s: o pico, a câmera mais longe;
- o quadro da lendária: a runa acesa e a cripta mais clara;
- o último: a lâmina crescida.

### O que o André joga e sente

`./run-local.sh -- --sala=S08_J40`, com quatro, os controles no colo:

- bater palma funciona com o controle parado no colo;
- a virada se aprende de ouvido na primeira frase;
- a palma de um não conta para o vizinho que não bateu. Se contar, anote os `voz` dos dois;
- a espada lendária parece uma conquista da sala.

### Armadilhas

- **O robô sorteia no dele:** `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`.
- **A palma de um chega aos quatro microfones.** A regra dos 6 dB dá a palma a quem está perto do mais alto; se
  todos batem, todos recebem. É o esperado. Não mexa no ouvido aqui.
- **A nota do kit na TV** toca a −4 dB (perfeito) ou −9 dB no julgamento de cada um. Se o registro mostrar palma de
  quem não bateu logo depois da nota da TV, anote o `voz` dele: é o vazamento, e a correção é do ouvido (a P1).
- **Palmas a meia batida** (as viradas): 0,254 s entre duas. A `JANELA_CASA` é a do ouvido, 0,25 s, para uma palma
  não casar com a vizinha.
- **O nível desce rápido** depois da palma: o ouvido vê o fim logo. Não use o fim para nada.
- **O ferreiro não tem raça:** é o orc tingido, sempre. A raça é só do cavaleiro.

### Ao terminar

- No [quadro](README.md): a linha **P5**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: Palmas da Forja no kit — a turma segura o ritmo com as mãos`
