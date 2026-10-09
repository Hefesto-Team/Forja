# N3 — Coral dos Quatro

**Sprint:** N · **Slot:** S06_J28 · **Tamanho:** M · **Depende de:** N1, H04, H06, H07, H08, F02, F03, F04, F05, F09, G05, G08, G10, G14, G15

## Por quê

O coop da seção, e o hoqueto no sentido literal: o acorde é dividido, cada controle tem a sua nota (dó, ré, fá, sol:
a nota do lugar da H07), e o acorde só fecha se cada um cantar a sua **na vez dela**. Quem conta a vez é o próprio
controle: no compasso da chamada, o alto-falante de cada um canta na batida em que ele vai responder. N'O Canto (N1) a
vez é fixa e muda a altura; aqui a nota é sempre a sua e muda o quando. A resposta toca na TV, e o vitral do fundo é o
placar de todos.

## Ler antes

- [A N1](N1-o-canto.md) (o `CenarioDoCanto` inteiro: a capela, o `falante`, o `ouvir`, os ganchos, a `momento`)
- [O molde de minigame](molde-de-minigame.md) (o `coop`, o `coop_venceu` e o `destaque`)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s06/coral_dos_quatro.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S06_J28` em `MINIGAMES` e na lista da seção `S06` | **da seção** |
| `godot/scripts/traducoes.gd` | `"Coral dos Quatro": "Choir of Four"`, `"Cante na sua vez!": "Sing on your turn!"`, `"Cante!": "Sing!"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_coral()` e a linha `"S06_J28": await _prova_do_coral()` no `match` do `_prova_da_ficha(slot)` (H08) | **de todos** |
| `scripts/importar_kenney.py` | a linha `fantasy-town-kit` em `APROVADOS`, se a N1 ainda não a pôs | **de todos** |

O `fantasy-town-kit` a N1 importa. Se a N3 vier antes, rode `python3 scripts/importar_kenney.py fantasy-town-kit`
(ele escreve `godot/assets/kenney/fantasy-town-kit/`, o `LEIA-ME.md` e a `LICENCAS-DE-TERCEIROS.md`). O `.uid` de
`coral_dos_quatro.gd` sai de `"$GODOT" --headless --path godot --import --quit` e entra no commit.

O `cenario_do_canto.gd` é da N1: esta ficha **só chama**.

### O que muda de hoje

O Coral não existe hoje. O que muda da ficha antiga: `_notas` era declarada no minigame (agora é do kit, e o dado da
nota mora em `_info`); o robô contava o nível à mão (agora `CenarioDoCanto.ouvir`); a câmera era uma pose solta (agora
a da capela); as cores do vitral eram hex (agora as tintas das seções, pelo `Tema.neon`); o coro era `column` do
mini-dungeon (agora `pillar-stone` da Fantasy Town); o compasso tinha o `toque` na mão (sai: colidia com o acerto); o
acorde não tinha momento (agora é o `acorde`).

### O kit que esta ficha usa

```gdscript
presentes(); conectado(l); na_raia(l); raia(l); jogador(l); posicionar(l); marcar(l, pontos); anotar(tipo, l, campos)
nova_nota(l, n, t_alvo); notas_em_aberto(l); alvo_da(l, n); casar_toque(l); julgar_nota(l, n); nota_perdida(l, n); notas_perdidas(l)
andamento(); no_pico(); momento(nome, l, pos, altura_m, campos); var coop_venceu; func destaque() -> int
const RAIAS; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140; const TOM_DO_LUGAR := [1.0, 1.1225, 1.3348, 1.4983]
var _notas := [{}, {}, {}, {}]  # do kit: não declare
CenarioDoCanto.montar(sala, 1.0, false); pose_da_camera(); passar; exagero; suporte(sala, l); balancar(s, forca)
CenarioDoCanto.gancho(l, nome); antecedencia(l); queda(l, tempos); proxima_colcheia(folga_s)
CenarioDoCanto.falante(sala, l, som, ganho); tempo_forte(); soltar_a_musica(sala); ouvir(l, o); luz_da_nota(l, forca)
Tema.neon(cor, energia, "mundo") -> ShaderMaterial; Tema.SECAO  # as cinco tintas: vermelhão, cobalto, petróleo, mostarda, ameixa
```

No acerto, o kit toca na TV `Som.tocar("nota", pos, -4 ou -9, TOM_DO_LUGAR[l])` (o `nota_na_tv` fica no padrão,
`true`): é o arpejo que volta na TV. O `nota_no_falante` vai a `false`: o alto-falante é só da chamada.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Coral dos Quatro (S06_J28) — o acorde dividido. Nos compassos ímpares (a
## chamada), o alto-falante de cada controle canta a nota do lugar dele na
## batida da vez dele. No compasso seguinte (a resposta), cada um aperta ✕ na
## mesma batida: a nota dele toca na TV, e o arpejo volta inteiro. No pico, a
## vez se embaralha, cada um canta duas vezes em colcheia, e a cada duas
## chamadas os quatro cantam juntos: o acorde.
##
## A falha: a voz falta quando uma nota dela falta ou sai fora da vez; com
## menos da metade do coro, o vitral trinca e perde um painel (no máximo um por
## compasso); com metade ou mais, acende.
## O vencedor: coop — o vitral inteiro aceso (28 painéis), ou não; o destaque
## é quem cantou mais no tempo.
## O alto-falante do dono: o respiro e a nota dele na chamada.
## O registro mede: cada chamada (a nota do lugar, se foi ao controle), o
## toque do kit na resposta e o momento `acorde`.
## O robô: ouve em que tempo o próprio alto-falante cantou e aperta um
## compasso depois; quando não acerta, 250 ms tarde.
## Com menos de quatro: as vezes são tantas quantos jogadores.
## A régua: (1) «Cante na sua vez!» com o vitral e o coro; (2) sim: a vez só o
## próprio controle diz; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J28",
	"titulo": "Coral dos Quatro",
	"verbo": "Cante na sua vez!",
	"genero": "coop",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S06_J28",
	"duracao": 90.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "madeira",
	"microjogo": {"verbo": "Cante!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca nada nele (H08)
	"papel_som": Forja.PAPEL_ALTO_FALANTE,
}

const PONTOS := [0, 40, 70, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const PAINEIS := 28  ## o vitral: 4 colunas × 7 fileiras (o número do diretor de jogo, 09/10)
## A tinta de cada coluna: vermelhão, petróleo, mostarda, ameixa (o cobalto é a capela).
const COR_DA_COLUNA := [0, 2, 3, 4]  ## índices de Tema.SECAO
const PAINEL := Vector3(1.1, 0.42, 0.06)
const VITRAL_Z := -6.0
const VITRAL_BASE := 0.6
const RESPIRO_GANHO := 0.4  ## o clique da vez, meia batida antes da nota
const PULSO_S := 0.12
const RETA_BATIDAS := 16  ## nelas, toda chamada é o acorde
## O compasso acende (+1; o acorde, +2) quando canta pelo menos a metade das vozes dele
## (2 de 4, 2 de 3, 1 de 2, 1 de 1); com menos, trinca. A falta conta por voz, não por nota.
```

### O tempo

A faixa `MUS_S06_J28` tem 138 BPM: 1 batida = 0,435 s, 1 compasso = 1,74 s. Em 90 s, `_b_fim` = 207. O pico (`no_pico()`)
vai de 30 a 60 s (batidas 69 a 138). A reta são as batidas 191 a 206.

Os compassos ímpares (1, 3 … 49) são a **chamada**; o par seguinte é a **resposta**. A chamada `c` só existe se
`4 * (c + 1) + 3 < _b_fim`. O compasso se gera quando `Ritmo.batida() >= 4c − 4`.

### As vezes

`lista = presentes()` em ordem, `k = lista.size()`. As batidas da vez: com 4, `[0, 1, 2, 3]`; com 3, `[0, 1, 2]`; com
2, `[0, 2]`; com 1, `[0]`. A parte pelo tempo da chamada (`Ritmo.t_da_batida(4c)`):

| terço | música | as vezes | as notas por vez |
| --- | --- | --- | --- |
| 1. ensina | 0–30 s | a roda: `lista[i]` na batida `i` (P1, P2, P3, P4) | uma |
| 2. **o pico** | 30–60 s | embaralhadas pelo `rng` (Fisher-Yates com `rng.randi_range`; nunca `Array.shuffle`); a chamada com `(c / 2) % 2 == 1` é **o acorde**: todos na batida 0 | duas, em `v` e `v + 0,5` |
| 3. a reta | 60–90 s | embaralhadas; a chamada cuja resposta cai nas últimas 16 batidas (`4 * (c + 1) >= _b_fim - RETA_BATIDAS`: as 47 e 49) é o acorde | uma; duas no acorde |

Quem está com `Ritmo.simples[l]` tem uma nota só e a mesma vez da chamada anterior.

As contas da régua 5 (por jogador, com quatro): 1.º terço, 1 nota a cada 8 batidas (0,29 nota/s); pico, 2 notas a cada
8 (0,58: 2,0×); 3.º terço, 1 nota a cada 8 e 2 nos acordes (0,33: 1,1×). A maior distância entre duas notas do mesmo
lugar é de **11 batidas**: o ciclo de 8 mais a vez que muda de 0 para 3 no embaralho. Esta ficha fixa o item 7 em 11
para o Coral (o embaralho é a regra do pico).

### A chamada

Para cada nota da vez `v` (a batida `b = 4c + v`, ou `b + 0,5`): a nota de resposta
`n = int(round((b + 4) * 2))`, `_info[l][n] = {"b": b + 4, "c": c + 1, "acorde": e_acorde}`,
`nova_nota(l, n, Ritmo.t_da_batida(b + 4))`; e a chamada vai a `_chamadas`.

**O respiro:** em `Ritmo.t_da_batida(b - 0.5) - CenarioDoCanto.antecedencia(l)`, só antes da primeira nota da vez,
`CenarioDoCanto.falante(self, l, "clique", RESPIRO_GANHO)`: o regente respira. **A nota:** em
`Ritmo.t_da_batida(b) - CenarioDoCanto.antecedencia(l)`, `var foi := CenarioDoCanto.falante(self, l, "nota:%d" % l, 0.9)`
e `anotar("pista", l, {"n": n, "evento": "mandou", "canal": "alto_falante", "o_que": "nota:%d" % l, "no_controle": foi})`.
A TV fica calada na chamada: nenhum sino balança, nenhuma luz muda. O sino da capela dá o tempo forte.

### A resposta

✕ → `var nn := casar_toque(l)`; com `nn >= 0`, `_ultima[l] = _info[l][nn]` e `julgar_nota(l, nn)`. A nota que passa é
`nota_perdida` pelo `_passaram(l)` (o da N1). No acerto, o kit toca a nota do lugar na TV e o sino pequeno do lugar
balança 1 batida (`CenarioDoCanto.balancar`), com a barra de luz a 60 % por `PULSO_S`.

**O compasso de resposta fecha** quando todas as notas dele estão resolvidas (`_respostas[c]`, sem nenhuma em aberto).
A falta conta **por voz**: as vozes do compasso são os lugares com nota nele, e a voz falta quando pelo menos uma nota
dela sai ERRO ou passa (no pico, qualquer das duas). `cantaram = vozes − faltam`; a metade é `(vozes + 1) / 2`
(divisão inteira: 2 de 4, 2 de 3, 1 de 2, 1 de 1).

| o compasso | quem cantou | o vitral |
| --- | --- | --- |
| comum | a metade das vozes ou mais | +1 painel; `Som.tocar("sucesso", Vector3(0, 2, VITRAL_Z), -10.0)` |
| comum | menos da metade | −1 painel (trinca) |
| **o acorde** | a metade das vozes ou mais | **+2 painéis** e o momento `acorde` (abaixo) |
| o acorde | menos da metade | −1 painel (trinca), o acorde range |

O vitral perde no máximo 1 painel por compasso. `acesos >= PAINEIS` → `coop_venceu = true` e todos `acabou`.

### O acorde fecha (o momento)

Quando o compasso do acorde fecha com a metade das vozes ou mais: `_acorde_em = CenarioDoCanto.proxima_colcheia(0.15)`. Na colcheia:

- `Som.tocar("sucesso", Vector3(0, 2, VITRAL_Z), -4.0)`;
- os dois painéis seguintes acendem;
- a boca do coro abre (a escala `y` de 1 a 2,5 em 1 colcheia) e fica aberta 2 batidas;
- todos os presentes com controle: `Forja.sentir(l, "golpe")` e o R2 em Resistência (2, 4) por 0,25 s, depois Off;
- `CenarioDoCanto.exagero(self, _cenario, "estrondo")` (sem boneco: o acorde é de todos);
- 48 faíscas `Tema.TUNGSTENIO` no vitral (`Efeitos.faiscas(self, Vector3(0, 2.2, VITRAL_Z + 0.3), Tema.TUNGSTENIO, 48, 1.2)`);
- `momento("acorde", -1, Vector3(0, VITRAL_BASE, VITRAL_Z), 3.15, {"acesos": acesos, "faltas": f})` (`f`: as vozes que faltaram).

**O acorde que range** (menos da metade cantou): `Som.tocar("falha", Vector3(0, 2, VITRAL_Z), -8.0)`, e a trinca.

**A trinca:** o último painel aceso apaga (volta ao material apagado) e ganha uma caixa `Tema.JANELA` de
0,04 × 1,1 × 0,02 na diagonal da frente dele (21° da horizontal); 10 faíscas `Tema.GRAFITE`. **A risca fica até o
fim**, também depois que o painel reacende: o vitral guarda as rachaduras da noite (o rastro da régua, item 6). Se o
mesmo painel trinca de novo, a segunda risca cruza a primeira (−21°); da terceira em diante, nada se soma.

### O pico

Na primeira batida com `no_pico()`: `Som.tocar("sucesso", Vector3(0, 2, VITRAL_Z), -6.0)`, a boca do coro abre por 2
batidas e o `CenarioDoCanto.passar` sobe a chave 20 % e recua a câmera 10 %.

### A reta

Na batida 191, uma vez: `momento("reta", -1, Vector3(0, 0, Z_JOGADOR), 1.8, {"objeto": "vitral", "valores": str(acesos)})`.
As duas últimas chamadas são o acorde.

### O ensina

A roda da entrada: a vez anda P1, P2, P3, P4, sempre igual, e a nota de cada um é sempre a mesma. É contar. Na
primeira resposta de cada lugar, o glifo `Desenho.glifo("cross")` (`Sprite3D` de 0,35 m, billboard, `shaded` false,
`modulate` `Tema.ETIQUETA`) aparece sobre o sino dele de 1 batida antes até a nota, como n'O Canto.

### O fim e o vencedor

`fim` `meta_coletiva`: o vitral inteiro (`coop_venceu = true`, todos `acabou`) ou os 90 s (o kit fecha com
`coop_venceu = false`). O kit grava `vencedor` −1 e o destaque:

```gdscript
## Coop: o kit grava vencedor −1 (H08); o destaque é quem cantou mais no tempo.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return int(pontos[a]) > int(pontos[b]) or (int(pontos[a]) == int(pontos[b]) and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

### Com menos de quatro

- **Três:** três vezes por chamada; a quarta batida fica vazia.
- **Dois:** as vezes 0 e 2; o vitral pede os mesmos 28, e a metade do coro é 1 de 2.
- **Um:** a vez 0 na roda; no pico e na reta, a batida dele sorteada entre as quatro. `com_poucos()` devolve `""`.
- **O controle que cai:** as notas dele saem caladas (`notas_perdidas(l)`) e não contam como falta: o compasso fecha
  com quem está, e a voz dele sai das vozes do compasso (a metade se conta sem ela). Ele volta na próxima chamada.

### Os ganchos

```gdscript
var _info := [{}, {}, {}, {}]  ## lugar -> {n: {b, c, acorde}}
var _chamadas: Array = []  ## {l, b, n, primeira, respirou, tocou}
var _respostas := {}  ## c -> {"abertas": int, "vozes": {lugar: true}, "faltam": {lugar: true}, "acorde": bool}
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _b_fim := 0
var acesos := 0
var _paineis: Array = []  ## [{no, apagado, trinca}]
var _vez_anterior := [0, 0, 0, 0]
var _acorde_em := -1.0
var _boca_ate := -1.0
var _gatilho_ate := -1.0
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _balanca_ate := [-1.0, -1.0, -1.0, -1.0]
var _ensinou := [false, false, false, false]
var _pico_tocou := false
var _reta_anotada := false
var _sinos := {}
var _boca: Node3D
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoCanto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoCanto.montar(self, 1.0, false)
	_b_fim = int(floor(duracao * Ritmo.bpm / 60.0))
	_montar_a_praca()  # o vitral, a fonte e o coro de pedra
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = 0.0
		p.preso = true
		_sinos[l] = CenarioDoCanto.suporte(self, l)
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	for l in presentes():
		CenarioDoCanto.luz_da_nota(l, 1.0)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
	while _gerado <= c + 1:
		_gerar_compasso(_gerado)
		_gerado += 1
	CenarioDoCanto.passar(self, _cenario, no_pico())
	_tocar_as_chamadas()  # o respiro e a nota de cada um, no alto-falante
	_pico_no_tempo()
	_reta_no_tempo()
	_acorde_no_tempo()  # a colcheia do acorde, a boca que fecha, o gatilho que volta
	for l in presentes():
		_apagar_o_pulso(l, dt)
		CenarioDoCanto.balancar(_sinos[l], 1.0 if Ritmo.batida() < float(_balanca_ate[l]) else 0.0)
		if not conectado(l):
			for nn in notas_em_aberto(l):
				_tirar_da_resposta(l, nn)  # sem falta
			notas_perdidas(l)
			continue
		if Forja.apertou(l, Forja.CRUZ):
			var nn := casar_toque(l)
			if nn >= 0:
				_ultima[l] = _info[l].get(nn, {})
				julgar_nota(l, nn)
		_passaram(l)
		_mostrar(l)  # o glifo do ensina
	_fechar_os_compassos()
	if acesos >= PAINEIS:
		coop_venceu = true
		for l in presentes():
			acabou[l] = true


func toque(l: int, julgamento: int) -> void:
	var nt: Dictionary = _ultima[l]
	marcar(l, PONTOS[julgamento])
	_resolver(int(nt.get("c", -1)), l, false)
	_balanca_ate[l] = Ritmo.batida() + 1.0
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	_ultima[l] = {}
	if nt.is_empty():
		return
	_resolver(int(nt.c), l, true)
	jogador(l).gesto("emote-no", 0.4)
	_torto(l)  # o sino pequeno dá um tranco e volta em queda(l, 1) batidas


func status(l: int) -> String:
	return "" if na_raia(l) else super(l)


func dica(_l: int) -> Dictionary:
	return {}


func com_poucos() -> String:
	return ""


func _exit_tree() -> void:
	CenarioDoCanto.soltar_a_musica(self)
```

`_resolver(c, l, falta)` desconta uma nota aberta do compasso `c` e, com falta, marca a voz `l` em `faltam`.
`_tirar_da_resposta(l, n)` desconta a nota sem falta e, se a voz `l` não tem outra nota no compasso, a tira de
`vozes` e de `faltam`. `_fechar_os_compassos()` olha os compassos com `abertas == 0`, aplica a tabela de «A resposta»
(`vozes.size() − faltam.size()` contra `(vozes.size() + 1) / 2`; sem voz nenhuma, o compasso só se apaga) e os
apaga de `_respostas`. `_gerar_compasso(c)`,
`_tocar_as_chamadas()`, `_pico_no_tempo()`, `_reta_no_tempo()`, `_acorde_no_tempo()`, `_tirar_da_resposta(l, n)`,
`_torto(l)`, `_apagar_o_pulso(l, dt)`, `_mostrar(l)` e `_montar_a_praca()` fazem o que as partes desta ficha dizem.
`_passaram(l)` é o da N1.

O catálogo: `Catalogo.MINIGAMES["S06_J28"] = preload("res://scripts/minigames/s06/coral_dos_quatro.gd")` e
`"S06_J28"` na lista da seção `S06`.

## A cena

### A câmera

A da capela (N1): `CenarioDoCanto.pose_da_camera()`, a câmera em `(0, 14,99, 10,07)` olhando `(0, 1,2, −1,5)`, 35 mm,
plongée de 50°, modo `fixa`, sem corte. O vitral (de y 0,6 a 3,75 em z −6) cabe inteiro: o raio de cima passa em
y = 5,3 na parede do fundo. No pico, `pose_da_camera(1.1)`. O tremor é só o do `exagero`.

### A luz da seção

A da N1, sem pórtico: `CenarioDoCanto.montar(self, 1.0, false)`: a névoa `#050d26` (o main), o preenchimento
`#1f346a` a 0,2, a chave `#e5d3c6` a 0,47, as tochas `Tema.TUNGSTENIO` a 0,9. O vitral aceso é néon do mundo
(`Tema.neon`, teto 1,2): ele não ilumina, ele brilha.

- **O pico:** a chave +20 % em 1 batida (sem flashes, +10 % em 2).

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `wall` | `Kit.arena(sala, 5, 3)` | o chão e as paredes |
| `castle-kit/tower-hexagon-base` e `roof` | `(±7,6, 0, −5,4)`, do cenário comum | os lados do fundo |
| `fantasy-town-kit/fountain-round` (escala 1,5: 3 × 3 m, 0,42 m de alto) | `(0, 0, -2.6)` | a praça na frente do vitral |
| `fantasy-town-kit/pillar-stone` (escala 2,4: 2,4 m) | `(±3.4, 0, -5.6)` e `(±4.6, 0, -5.4)` | o coro de pedra, quatro figuras |

O que não é peça Kenney (caixas do `Kit`; `metallic` 0):

| objeto | forma | material |
| --- | --- | --- |
| a moldura do vitral | caixa 4,9 × 3,35 × 0,16 em `(0, 2.175, VITRAL_Z - 0.08)` | `Kit.material(Tema.OXIDO, 0.0, 0.85)` |
| o painel `i` (coluna `i % 4`, fileira `i / 4`, de 0 a 6) | caixa 1,1 × 0,42 × 0,06 em `(-1.8 + 1.2 * col, 0.81 + 0.45 * fil, VITRAL_Z + 0.04)` | apagado: `Kit.material(Tema.SECAO[COR_DA_COLUNA[col]].darkened(0.7), 0.0, 0.8)`; aceso: `Tema.neon(Tema.SECAO[COR_DA_COLUNA[col]], 1.0, "mundo")` |
| a trinca | caixa 0,04 × 1,1 × 0,02 na diagonal da frente do painel (21°; a segunda, −21°), até o fim | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| a boca do coro | caixa 0,2 × 0,08 × 0,04 em cada figura, a 2,0 m, na face da frente | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| o sino pequeno e o suporte | `CenarioDoCanto.suporte(self, l)` (N1) | o da N1 |
| o glifo do ensina | `Sprite3D` de 0,35 m | `modulate` `Tema.ETIQUETA` |

Os painéis acendem em ordem (`i` de 0 a 27: a fileira de baixo primeiro) e apagam do último aceso para trás.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| o painel aceso | o mundo (é de todos) | `Tema.neon(..., 1.0, "mundo")` |
| as faíscas do acorde | a forja | `Tema.TUNGSTENIO`, 48 |
| as faíscas da trinca | ninguém (cinza) | `Tema.GRAFITE`, 10 |
| as tochas | a forja | luz `Tema.TUNGSTENIO` 0,9 |

Nenhuma cor fora dos tokens: os `#e8b44c`, `#6fd3c8`, `#c28bff`, `#e9e7f2`, `#3a2a24` e `#c08a42` da ficha antiga
somem. As tintas das seções ficam longe das cores dos lugares (o cobalto, a da capela, não entra no vitral).

### A montagem

- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = 0.0` (de frente), `preso = true`, o sino com o suporte.
- `_montar_a_praca()`: a fonte, as quatro figuras com a boca, a moldura e os 28 painéis apagados; `_boca` é um
  `Node3D` pai das quatro bocas (a escala `y` delas muda junto).

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o respiro | — (sem alto-falante: `tique` −10 dB na raia) | `"clique"`, 0,4 | `mod_clique`; `tique_0..2` |
| a chamada | — (sem alto-falante: `nota` −10 dB com o tom do lugar) | `"nota:<l>"` (dó, ré, fá, sol), 0,9 | `mod_nota_p1..p4`; `sint_nota` |
| a resposta certa | a nota do lugar, −4 ou −9 dB, `TOM_DO_LUGAR[l]` (o kit) | — | `sint_nota` |
| a resposta errada | a falha do kit (−6) | — | `falha_0..2` |
| o compasso inteiro | `Som.tocar("sucesso", vitral, -10.0)` | — | `vitoria_sala_0..1` (reserva `sint_sucesso`) |
| o acorde fecha | `Som.tocar("sucesso", vitral, -4.0)` | — | `vitoria_sala_0..1` (reserva `sint_sucesso`) |
| o acorde range, a trinca | `Som.tocar("falha", vitral, -8.0)` | — | `falha_0..2` |
| o pico | `Som.tocar("sucesso", vitral, -6.0)` | — | `vitoria_sala_0..1` (reserva `sint_sucesso`) |
| o tempo forte | `Som.tocar("sino", SINO_TV, -16)` | — | `sint_sino` |
| a faixa | `MUS_S06_J28`: 138 BPM, Fá menor, 150 s (toca 90); até ela existir, `sint_trilha` | — | `mus_s06_j28` |

- **A música abaixa na pista** (−12 dB por 1 batida, volta em 300 ms): o respiro e a nota a abaixam.
- O alto-falante só toca a chamada: `nota_no_falante` false.
- O material `"madeira"`: a textura do acerto na háptica (o kit).

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| o respiro e a chamada | só o dono | — | — | — (nunca: entregaria a vez) | `clique` 0,4; `nota:<l>` 0,9 |
| a resposta BOM ou ÓTIMO | o dono | `acerto` (0,3 / 0,6, 80 ms; o kit) | — | 60 % por 0,12 s, volta a 100 % | — |
| a resposta PERFEITA | o dono | `perfeito` (0,5 / 0,8, 100 ms; o kit) | — | o kit: branco 0,15 s | — |
| a falta | o dono | `erro` (0,7 / 0,3, 160 ms; o kit) | — | o kit: escurecida 0,5 s | — |
| o acorde fecha | todos | `golpe` (1,0 / 0,6, 250 ms) | R2 em Resistência (2, 4) por 250 ms, depois Off | — | — |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar | — |

Fora da bancada, nunca pergunta.

### O robô

```gdscript
# O robô ouve a própria nota no alto-falante simulado (CenarioDoCanto.ouvir) e
# guarda o instante. No tempo de cada nota de resposta, procura a nota ouvida
# um compasso antes (menos a antecedência dele) e aperta ✕; quando não acerta,
# 250 ms tarde. O respiro (clique) ele ignora.
var _ouvido := [{}, {}, {}, {}]
var _robo_ouviu := [[], [], [], []]  ## lugar -> [t, ...], os últimos 8
var _robo_feita := [-1, -1, -1, -1]
var _robo_tarde := [-1.0, -1.0, -1.0, -1.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var a := CenarioDoCanto.ouvir(l, _ouvido[l])
	if not a.is_empty() and str(a.som) == "nota:%d" % l:
		_robo_ouviu[l].append(float(a.t))
		if _robo_ouviu[l].size() > 8:
			_robo_ouviu[l].pop_front()
	var agora := Ritmo.t_musica()
	if _robo_tarde[l] >= 0.0 and agora >= _robo_tarde[l]:
		Forja.robo_apertar(l, Forja.CRUZ, 0.06)
		_robo_tarde[l] = -1.0
	var batida := 60.0 / Ritmo.bpm
	for nn in notas_em_aberto(l):
		if nn <= int(_robo_feita[l]):
			continue
		var t := alvo_da(l, nn)
		if agora < t:
			return
		_robo_feita[l] = nn
		var quando := t - 4.0 * batida - CenarioDoCanto.antecedencia(l)
		if _robo_ouviu[l].any(func(o): return absf(float(o) - quando) <= 0.12):
			if Forja.robo_acerta():
				Forja.robo_apertar(l, Forja.CRUZ, 0.06)
			else:
				_robo_tarde[l] = agora + 0.25
		return
```

As duas notas da vez no pico ficam a 0,22 s uma da outra: a janela de 0,12 s do robô não as confunde. O robô não lê
`_info`: se a nota não saiu do alto-falante simulado, ele não responde.

## O cavaleiro

O cavaleiro da montagem (G13), de frente, ao lado do sino. A cabeça, a parte de cima e a de baixo aparecem como estão;
as mãos ficam livres. Ele pode ser de outra raça (G08, parte B; a montagem é da G13): esta ficha usa o esqueleto comum de 7 ossos e as animações
`idle` e `emote-no`.

| stat | gancho | o que muda no Coral | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: nada empurra | — | — | — |
| Passo | `velocidade` | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | quanto o sino pequeno torto da falta leva para voltar | 1,25 batida | 1 | 0,75 |
| Faro | `pista` | a chamada sai antes; a resposta fica no tempo | 40 ms depois | no tempo | 40 ms antes |
| Faro | `raio` | não age | — | — | — |

Os itens: o Escudo absorve o primeiro erro (o kit: a primeira falta não conta); a Âncora não age; a Lanterna adianta a
chamada meio tempo (0,22 s a 138 BPM); o Martelo dobra o perfeito no tempo forte (o kit); o Diapasão aumenta o ganho
da nota do acerto (1,3) e puxa o combo da equipe no coop (o kit). Nenhum stat muda a janela de julgamento.

```gdscript
## A falta: o sino pequeno dá um tranco torto e volta no tempo do Fôlego.
func _torto(l: int) -> void:
	var s: Dictionary = _sinos[l]
	var pivo: Node3D = s.pivo
	pivo.rotation.z = 0.35 * float(s.s)
	var dur := CenarioDoCanto.queda(l, 1.0) * 60.0 / Ritmo.bpm
	create_tween().tween_property(pivo, "rotation:z", 0.0, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
```

O erro não tem squash. O desregistro do erro é do kit e da G08.

## As reações

- **Carimbos que o Coral pode disparar** (do kit e do HUD, G04): `car_acorde` (os quatro na Ressonância no mesmo tempo
  1: no acorde, cuja primeira nota cai no tempo 1 do compasso para os quatro), `car_em_chamas` (5 Ressonâncias seguidas
  do mesmo lugar). O `car_por_um_fio` e o `car_virada` são do placar (G07): o Coral não os chama.
- **Adesivos:** ninguém está fora da rodada; ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: o acorde dos quatro** (`acorde`). No pico e na reta, os quatro cantam na mesma batida; o acorde inteiro
(dó, ré, fá, sol) volta na TV, o vitral acende dois painéis de uma vez, o coro de pedra abre a boca, e os quatro
controles batem juntos. Degrau estrondo (tremor de 0,05 m por 2 batidas, 48 faíscas). O acorde que falha range e
trinca.

- **Rastro:** os painéis acesos ficam; o vitral é o placar de todos.
- **A curva:** de 0 a 30 s, a roda (cada um aprende a própria nota); de 30 a 60 s, a vez embaralha, duas notas por vez,
  e o acorde a cada duas chamadas; de 60 s ao fim, a vez embaralhada, e nas duas últimas chamadas o acorde.
- **Ensina sem falar:** a roda da entrada anda P1, P2, P3, P4; o glifo ✕ na primeira resposta.
- **Quem está perdendo:** é coop. O vitral perde no máximo um painel por compasso, e a metade do coro basta para
  acender: duas vozes seguram as outras duas.
- **A nota de hoje:** 3. O acorde a cada duas chamadas do pico responde ao «o acorde precisa vir mais vezes».

**O número: 28 painéis, e a metade do coro acende** (o diretor de jogo, 09/10/2026). Com 12 painéis e a falta contada
por nota, a mesa boa fechava o vitral no pico (aos 43,5 s pela medida do revisor; 45,7 s nesta conta, que fecha o
compasso na última nota), a reta nunca chegava, e a mesa fraca só chegava à metade em 2 % das partidas. Nenhum número
de painéis resolve sozinho: o `bom` erra 5 % das notas e o `medio` 34 %, e a regra por nota pune o `medio` quase toda
vez no pico, onde cada um canta duas. As duas mudanças:

- **28 painéis, 4 colunas × 7 fileiras**, no mesmo quadro de 4,9 × 3,35 m (o painel passa de 1,1 × 0,95 a
  1,1 × 0,42 m). Somando tudo o que as 23 chamadas antes da reta podem dar (9 da roda, 4 comuns e 4 acordes do pico,
  6 do 3.º terço), o vitral chega a 27 no máximo: **com 28, ele não fecha antes da reta, por construção, em qualquer
  mesa**. A mesa boa fecha no primeiro acorde da reta (83,8 s), e o grito do fim é o vitral que se completa.
- **A falta conta por voz, e a metade do coro acende**: o compasso (e o acorde) acende com pelo menos 2 das 4 vozes
  e trinca com menos. Uma regra só, para o comum e o acorde, que cabe numa frase: «metade do coro segura a noite».
- **A risca da trinca fica até o fim** (o rastro), também no painel que reacende: com a regra nova a trinca fica mais
  rara na mesa padrão, e a risca que some ao reacender ficava à vista em só 18 % do tempo, abaixo de 1 quadro em 5.

A conta pelo robô (as regras desta ficha, 4 000 partidas, semente 7; o `bom` acerta 95 %, o `medio` 66 %; o fecho de
cada compasso na última nota dele, mais 140 ms):

| medida | 12 painéis, falta por nota (antes) | 28 painéis, metade do coro (agora) |
| --- | --- | --- |
| mesa boa: fecha o vitral | 100 %, aos 45,7 s (p10 42,1 s) | 99,9 %, aos 84,0 s (p10 83,8 s) |
| mesa boa: a reta acontece (a batida 191, 83,0 s) | 0 % | 100 % |
| mesa boa: pelo menos 2 acordes fechados entre 30 e 60 s | 90,1 % | 100 % |
| mesa boa: painéis aos 30 s e aos 60 s | 6,4 e 12,0 | 8,0 e 19,9 |
| mesa fraca: chega à metade dos painéis | 1,7 % (6 de 12) | 81,2 % (14 de 28; o máximo fica em 17,6 em média) |
| mesa fraca: fecha o vitral | 0 % | 0,7 % |
| mesa fraca: trincas por partida | 4,4 | 5,7 |
| mesa padrão: chega à metade; fecha | 0,4 %; 0 % | 92,1 %; 2,6 % |
| mesa padrão: tempo com uma risca à vista | 51,5 % (o vitral quase sempre vazio) | 67,0 % (a risca fica) |

**Como o jogador do time confere.** O momento pede a **mesa boa** (os quatro `bom`, semente 7: `--robo=bom --semente=7`);
o resto, a mesa padrão (P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a bancada, pela F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 (a primeira resposta cai até 5,2 s) | o quadro de 10 s mostra um sino balançando ou um painel aceso |
| 4. o momento | mesa boa: pelo menos 2 linhas `momento` `acorde` entre 30 e 60 s | o vitral com mais painéis no quadro de 60 s que no de 30 s |
| 5. a curva | notas por segundo no 2.º terço ≥ 1,5 × as do 1.º (dá 2,0 ×); no 3.º ≥ 1,0 × (dá 1,1 ×); a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a luz 20 % acima do do 1.º |
| 6. a falha | o P4 tem pelo menos 10 linhas `toque` com `erro` | 1 quadro em 5 mostra uma trinca no vitral |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 11 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `acorde` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 (0,5 e 0,15) | o vitral se vê inteiro no quadro de 480 × 270 |
| 9. o impacto | para cada `acorde`, uma linha `sensacao` `golpe` a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte mostra a boca do coro aberta |
| 10. o placar no mundo | o número de painéis do `momento` `reta` bate com o `acesos` do registro naquele tempo | no quadro de 82 s, quem olha conta os painéis, e a conta bate com o registro |

A `prova_do_jogo.sh` roda com `--robo` sem valor, que é o `bom` da F09, nos quatro: é a mesa boa, e a prova confere os
itens 1, 4, 8, 9 e 10 com ela. O item 5 e a mesa padrão esperam o robô por lugar (`--robo=bom,medio,medio,ruim`), que a
F09 não faz; os itens 6 e 7 também.

## Pronto quando

O Coral dos Quatro joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o `bom`
acende o vitral, o `ruim` não); aguenta o cabo que cai e volta; fecha com o resultado coop e o destaque; o acorde
fecha pelo menos 2 vezes no pico com a mesa boa; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a
prancha olhada.

## Provas

Na sessão: `SALA=S06_J28 bash tests/prova_do_jogo.sh` (a prova do Coral, sem e com `--bancada`), `bash tests/prova_do_jogo.sh`
e `bash tests/prova_visual.sh`. A sh fixa `--robo --semente=7` (o `bom` nos quatro, a mesa boa) e não repassa argumentos.

Em `godot/testes/prova_do_jogo.gd`, a função abaixo, chamada pela linha `"S06_J28": await _prova_do_coral()`
no `match` do `_prova_da_ficha(slot)` da H08:

```gdscript
## Coral dos Quatro (S06_J28): é coop; cada um canta a sua nota no alto-falante
## simulado; o vitral fica entre 0 e 28; o acorde é o momento e põe o R2 em
## Resistência.
func _prova_do_coral() -> void:
	var fora := [0]
	var tocou := [false]
	var resistencia := [false]
	var olhar := func(mg: Minigame) -> void:
		if int(mg.acesos) < 0 or int(mg.acesos) > mg.PAINEIS:
			fora[0] += 1
		for l in mg.presentes():
			if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.3:
				tocou[0] = true
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				resistencia[0] = true
	var mg = await _joga_o_minigame("S06_J28", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.coop and mg.destaque() >= 0, "Coral: é coop, com o destaque")
	_esperar(fora[0] == 0, "Coral: o vitral entre 0 e %d" % mg.PAINEIS)
	_esperar(tocou[0], "Coral: a chamada saiu de um alto-falante simulado")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S06_J28")
	var chamadas := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("evento") == "mandou")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	var acordes := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "acorde")
	var sons := {}
	for e in chamadas:
		sons[str(e.get("o_que", ""))] = true
	_esperar(sons.size() == mg.presentes().size(), "Coral: cada um cantou a sua nota (%s)" % [sons.keys()])
	for l in mg.presentes():
		_esperar(toques.any(func(e): return int(e.get("jogador", 0)) == l + 1 and float(e.get("t_musica", 99.0)) <= 10.0), "Coral: o P%d cantou até 10 s" % (l + 1))
	if mg.presentes().size() == 4:  # o bom nos quatro: a mesa boa
		var no_pico := acordes.filter(func(e): return float(e.get("t_musica", 0.0)) >= 30.0 and float(e.get("t_musica", 0.0)) <= 60.0)
		_esperar(no_pico.size() >= 2, "Coral: %d acordes no pico com a mesa boa (o mínimo é 2)" % no_pico.size())
		_esperar(resistencia[0], "Coral: o acorde põe o R2 em Resistência (0x21)")
	for a in acordes:
		_esperar(float(a.get("x_tela", 0.0)) >= 0.2 and float(a.get("x_tela", 0.0)) <= 0.8 \
			and float(a.get("altura_tela", 0.0)) >= 0.08, "Coral: o acorde no meio da tela (%s)" % [a])
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("slot", "") == "S06_J28").is_empty(), "Coral: fora da bancada, nenhuma pergunta")
```

### O que o registro mede

- `som_controle` (H07) de cada respiro e chamada (`nota:<l>`, `placa`); a `troca` de quem não tem alto-falante.
- `pista` (n da resposta, `no_controle`) e o `toque` do kit com o mesmo `n`: a chamada no controle e a resposta
  perdida, sempre no mesmo controle, é o alto-falante que não cantou.
- `sensacao` `golpe` e `momento` `acorde` em cada acorde fechado; o `momento` `reta`.

### As pranchas que o jogador do time olha

A prancha da prova visual (480 × 270, um quadro a cada 2 s): o quadro de 10 s (um sino balançando), os de 30 e 60 s
(o vitral cresce), os quadros com a boca do coro aberta (o acorde), os com uma trinca, e o de 82 s (os painéis
contados, antes da reta das 83,0 s: a mesa boa fecha o vitral aos 84 s).

### O que o André joga e sente

`./run-local.sh -- --sala=S06_J28`, com quatro DualSense, dois no cabo e dois no rádio:

- cada um reconhece a própria nota no próprio controle, e o respiro avisa que ela vem;
- a roda da entrada ensina; no pico, a vez pula e só o ouvido acha;
- o acorde dos quatro na TV é bonito, e os quatro controles batem juntos;
- o vitral acendendo é o placar de todos; a trinca dói em todos.

### Armadilhas

- **Nenhum sinal da vez na tela durante a chamada:** o sino pequeno só balança na resposta boa; a barra de luz também.
- **Nunca `Array.shuffle()`:** o embaralhar é pelo `rng` da semente.
- **O compasso fecha com quem está:** quem caiu não conta falta e não segura os outros.
- **`_notas` é do kit.** O dado da nota mora em `_info`.
- **O vitral perde no máximo 1 painel por compasso**, e nunca fica abaixo de 0.
- **A música:** o `_exit_tree` chama `soltar_a_musica`.

### Ao terminar

- No [quadro](README.md): a linha **N3**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer): `feat: Coral dos Quatro no kit, o acorde dividido entre os alto-falantes e o vitral`
