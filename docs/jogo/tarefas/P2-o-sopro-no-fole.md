# P2 — O Sopro no Fole

**Sprint:** P · **Slot:** S08_J37 · **Tamanho:** M · **Depende de:** P1, H04, H07, H08, F09, G03, G04, G05, G08, G10, G13, G14, G15

## Por quê

A voz como segurar e soltar. Cada um tem o seu fole, e a nota longa pede sopro do começo ao fim, e parar em seco
quando ela acaba. O difícil não é soprar, é **parar**. Todos contra todos, em hoqueto: cada nota longa é de um, e a
frase inteira é o fole dos quatro, um depois do outro. Quem sopra demais leva a fuligem na cara.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`godot/scripts/minigames/s08/ouvido.gd`](../../../godot/scripts/minigames/s08/ouvido.gd) (a P1 cria: a voz, os
  6 dB, o mudo, a escuta)
- [`godot/scripts/minigames/s08/cenario_da_voz.gd`](../../../godot/scripts/minigames/s08/cenario_da_voz.gd) (a P1
  cria: a cripta, o braseiro, a câmera, o exagero, os ganchos do cavaleiro)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s08/o_sopro_no_fole.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S08_J37` em `MINIGAMES` e na seção `S08` | **da seção**: uma linha |
| `godot/scripts/traducoes.gd` | `"O Sopro no Fole"`, `"Sopre e pare!"`, `"%d inteiras"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_o_sopro_no_fole()` e a chamada no percurso | **de todos** |

O `.uid` novo (`o_sopro_no_fole.gd.uid`) sai do import `"$GODOT" --headless --path godot --import --quit` e entra
no commit. Esta ficha não mexe em `ouvido.gd`, `cenario_da_voz.gd`, `musica.gd` nem `minigame.gd`: usa o que a P1
deixou (`ouvido.nova_voz` com a `latencia`, `Musica.escuta`, `momento`).

### O que muda de hoje

O Sopro no Fole não existe hoje. Ele nasce no kit, sem sala antiga para tirar.

### O kit que esta ficha usa

As do kit (H04, H08): `presentes()`, `conectado(l)`, `raia(l)`, `jogador(l)`, `posicionar(l)`, `acender_raia(l, f)`,
`nova_nota(l, n, t)`, `notas_em_aberto(l)`, `alvo_da(l, n)`, `julgar_nota(l, n)`, `notas_perdidas(l)`,
`nota_perdida(l, n)`, `anotar`, `marcar`, `aprendeu(l)`, `momento(nome, l, pos, altura_m, campos)`, `RAIAS`,
`Z_JOGADOR` (1,4), `BATIDA_DA_PRIMEIRA_NOTA` (4), `FOLGA_PERDIDA` (0,14).

Do ouvido (P1): `Ouvido.new(self)`, `comecar()`, `ouvir(dt)`, `nova_voz(l, n, bn, latencia)`, `e_voz(l, n)`,
`casar_voz(l)`, `falando[l]`, `nivel[l]`, `piso[l]`, `sozinho(l)`, `surdo_ate[l]`, `falante(l, som, ganho, ms)`,
`sentir(l, nome)`, `depois(l, f)`, `fechar()`, `LATENCIA_MIC` (0,08). O ouvido chama `_comecou(l)`, `_parou(l)` e
`_mudou(l, mudo)`.

Do cenário comum (P1): `CenarioDaVoz.pose_da_camera(recuo)`, `montar(sala)`, `braseiro(sala, l)`,
`chama_em(b, h)`, `passar(sala, c, no_pico)`, `exagero(sala, c, degrau, boneco)`, `queda_s(l, tempos)`,
`antecedencia(l)`.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## O Sopro no Fole (S08_J37). Cada um tem o seu fole e uma nota longa por vez,
## em hoqueto: sopre do começo ao fim da nota e pare em seco quando ela acaba.
##
## A falha: soprou demais e o fole estoura fuligem no rosto (o rosto fica preto
## até a próxima nota inteira); não entrou e o fole murcha.
## O vencedor: mais notas inteiras, depois mais pontos, depois o lugar menor.
## O alto-falante do dono: a nota dele na nota inteira; a nota quebrada na fuligem.
## O registro mede: a voz de cada controle (`voz`), a entrada e a saída de cada
## nota (`toque`, com o desvio), o momento `fuligem`.
## O robô: fala pelo tempo da nota no controle simulado.
## Com menos de quatro: o ciclo encolhe (2 batidas por lugar).
## A régua: (1) "Sopre e pare!" e o ícone do microfone; (2) sim: a barra de ferro
## enche e o fim dela é o "pare"; (3) não pergunta nada.

const FICHA := {
	"slot": "S08_J37",
	"titulo": "O Sopro no Fole",
	"verbo": "Sopre e pare!",
	"genero": "tct",
	"icone": "microfone",
	"entradas": [Forja.MICROFONE],
	"camera": "fixa",
	"faixa": "MUS_S08_J37",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["erro"],
	"material": "madeira",
	"microjogo": {"verbo": "Sopre!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,
	"textura_no_acerto": false,  # a textura toca depois da nota inteira
	"nota_no_falante": false,  # o alto-falante não toca enquanto o microfone escuta
	"gesto": "interact-right",
}

const Ouvido := preload("res://scripts/minigames/s08/ouvido.gd")
const DUR := 1.5  ## a nota longa: 1,5 batida (meia batida de folga até o vizinho)
const DUR_PICO := 3.5  ## o fole grande: 3,5 batidas
const DUR_CURTA := 0.5  ## na reta, as notas alternam 0,5 e 1,5
const LATENCIA_FIM := 0.12  ## o nível desce mais devagar do que sobe
const RETA := 16  ## as últimas 16 batidas
const PONTOS := [0, 25, 40, 50]  ## ERRO, BOM, OTIMO, PERFEITO (a entrada e a saída)
const INTEIRA := 50  ## a nota inteira (as duas sem erro)
const INTEIRA_RETA := 100  ## na reta
const SOZINHO_PONTOS := 30  ## sem microfone (ou mudo esquecido): o fole sopra sozinho
const QUEDA_TEMPOS := 2.0  ## a tosse da fuligem: 2 tempos (a queda da P2)
const METROS_POR_BATIDA := 0.6  ## a barra de ferro: 0,6 m por batida de nota
```

O microfone é a entrada: o `Forja.MICROFONE` em `entradas` é o ícone (o Botão do microfone, que o ouvido conta como
mudo). Sem treino próprio: o kit roda o treino de 6 s do microjogo «Sopre!».

### Os números de 112 bpm

Uma batida dura 60 / 112 = 0,5357 s. `B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))` = 149
(79,8 s). A reta começa em `B_FIM − RETA` = 133 (71,25 s). Até a H05, a faixa de reserva `"sopro"` toca a 105 bpm, e
`B_FIM` = 140: tudo conta por batida e por `B_FIM`, e nada quebra.

### A partitura (o hoqueto)

O `iniciar_jogo()` monta o plano de cada lugar, uma lista de notas longas `{bi, dur, fase, c}`. Com `np` lugares em
`presentes()` (em ordem crescente, `i` a posição do lugar):

```gdscript
func _partitura() -> void:
	var ordem := presentes()
	ordem.sort()
	var np := maxi(ordem.size(), 1)
	var r := _b_fim - RETA
	var b := float(BATIDA_DA_PRIMEIRA_NOTA)
	var c := 0
	var picos := 0
	while true:
		var pico := picos < 2 and b >= floor(r / 2.0)
		var passo := 4.0 if pico else 2.0
		if b + passo * np > r:
			break
		for i in ordem.size():
			_plano[ordem[i]].append({"bi": b + passo * i, "dur": DUR_PICO if pico else DUR,
				"fase": "pico" if pico else "normal", "c": c})
		if pico:
			picos += 1
		b += passo * np
		c += 1
	b = float(r)
	var k := 0
	while b + 2.0 * np <= _b_fim:
		for i in ordem.size():
			_plano[ordem[i]].append({"bi": b + 2.0 * i, "dur": DUR_CURTA if k % 2 == 0 else DUR, "fase": "reta", "c": c})
		b += 2.0 * np
		k += 1
		c += 1
```

Com quatro, a 112 bpm:

| batidas | tempo | ciclos | o que acontece |
| --- | --- | --- | --- |
| 0–3 | 0–2,1 s | — | a contagem (H06); o ouvido mede o piso |
| 4–67 | 2,1–36,4 s | c0 a c7, de 8 batidas | cada lugar sopra 1,5 batida a cada 8, em hoqueto (P1 em +0, P2 em +2, P3 em +4, P4 em +6) |
| 68–99 | 36,4–53,6 s | c8 e c9, de 16 batidas | **o pico, o fole grande**: 3,5 batidas (1,9 s) de fôlego, o fole cresce o dobro |
| 100–131 | 53,6–70,7 s | c10 a c13 | o hoqueto de 8 batidas outra vez |
| 132 | 70,7 s | — | uma batida de ar |
| 133–148 | 71,25–79,3 s | c14 e c15 | **a reta**: as notas alternam 0,5 (c14) e 1,5 batida (c15); a inteira vale +100 |
| 149 | 79,8 s | — | o fim |

Cada lugar tem **16 notas longas** (12 normais, 2 do pico, 2 da reta). A última acaba em 148,5. Com três, o ciclo é
de 6 batidas; com dois, de 4; com um, de 2 (ele sopra 1,5 a cada 2).

**A partitura simples** (`Ritmo.simples[l]`): o lugar sopra um ciclo normal sim, um não (pula os `c` ímpares de
fase `normal`). O pico e a reta ficam.

### Duas notas por nota longa

A nota longa `k` do lugar (a entrada `k` do plano) tem duas notas do kit:

- **a entrada**, `n = 2k`: abre 1 batida antes com `ouvido.nova_voz(l, 2k, bi)` (o alvo é `t(bi) + 0,08`). O
  `_comecou(l)` casa com `ouvido.casar_voz(l)` e julga com `julgar_nota`.
- **a saída**, `n = 2k + 1`: só abre quando a entrada foi julgada sem erro, com
  `ouvido.nova_voz(l, 2k + 1, bi + dur, LATENCIA_FIM)` (o alvo é `t(bi + dur) + 0,12`). O `_parou(l)` julga a saída
  aberta com `julgar_nota(l, 2k + 1)`.

`t(x)` é `Ritmo.t_da_batida(x)`. Um começo de voz fora de toda entrada é **ignorado**: pode ser o vizinho, a regra
dos 6 dB já filtra, e o fole não pune ruído.

| o que aconteceu | como o kit vê | `_motivo[l]` | o que se vê |
| --- | --- | --- | --- |
| entrou no tempo | `toque` da entrada (BOM a PERFEITO); a saída abre | — | o fole começa a encher |
| não entrou | a entrada passa de `alvo + 0,14` → `nota_perdida` | `"murchou"` | o fole fica vazio; `emote-no` 0,4 s |
| entrou fora do tempo | `toque` ERRO da entrada | `"murchou"` | o mesmo; a saída não abre |
| parou no tempo | `toque` da saída sem erro → **a nota inteira** | — | a labareda |
| parou cedo | `toque` ERRO da saída (`_parou` longe do alvo) | `"cedo"` | o fole murcha na metade, sem labareda |
| **soprou demais** | ainda falando em `alvo + 0,14` → `nota_perdida` da saída | `"fuligem"` | **a fuligem** |

O `_motivo` sai da nota: `nota_perdida` é sobrescrita para escolher `"fuligem"` (`n` ímpar) ou `"murchou"` (`n`
par) antes do `super`.

**Os pontos:** a entrada e a saída valem `PONTOS[j]` cada. A nota inteira vale mais `INTEIRA` (50), ou
`INTEIRA_RETA` (100) na reta, e `_inteiras[l] += 1`.

**O sopro sozinho** (`ouvido.sozinho(l)`: sem microfone, mudo no sistema, ou mudo fora de escudo): as notas dele não
abrem. Na batida `bi` de cada nota longa dele, `marcar(l, SOZINHO_PONTOS)` e o fole enche até a metade sozinho, sem
`_inteiras`.

### A fuligem

Na falha com `_motivo[l] == "fuligem"`:

- `momento("fuligem", l, jogador(l).global_position, 1.8, {"valores": "%s" % [_inteiras]})`;
- `CenarioDaVoz.exagero(self, _cenario, "estrondo", jogador(l))`: o tremor de 0,05 m por 2 batidas e o hit-stop de
  3 quadros no boneco;
- `Efeitos.poeira(self, _rosto(l), Vector3(0.8, 0.8, 0.8), Tema.FITA, 30)`;
- **o rosto preto** (o rastro): a máscara de fuligem do lugar fica visível até a próxima nota inteira dele;
- a tosse: `jogador(l).gesto("emote-no", CenarioDaVoz.queda_s(l, QUEDA_TEMPOS))`, e
  `ouvido.surdo_ate[l] = Ritmo.t_musica() + queda` (o resto daquela voz é ignorado);
- o braseiro do lugar apaga (h 0) até a próxima nota longa dele;
- na TV, `Som.tocar("sopro", _bico(l), -2.0)` e `Som.tocar("golpe", _rosto(l), -6.0)`;
- no alto-falante, `ouvido.falante(l, "nota_quebrada:%d" % l, 0.8, 400)`.

`_rosto(l)` é `jogador(l).global_position + Vector3(0, 1.5, 0)`; `_bico(l)` é a ponta do fole.

### A nota inteira

Quando a saída sai sem erro e a entrada também:

- `marcar(l, INTEIRA_RETA if fase == "reta" else INTEIRA)`, `_inteiras[l] += 1`, `_seguidas[l] += 1`;
- a máscara de fuligem some;
- a labareda: `CenarioDaVoz.chama_em(b, 0.9)` e a energia 2,6 por 1 batida;
- `jogador(l).gesto("interact-right", 30.0 / Ritmo.bpm)`;
- `Som.tocar("fogo", b.base, -10.0)` na TV;
- `ouvido.depois(l, ...)`: `Forja.textura(l, "madeira", 0.5)` (sem háptica, `ouvido.sentir(l, "toque")`) e
  `ouvido.falante(l, "nota:%d" % l, 0.8, 300)`.

### O pico, o fole grande

Na primeira nota de cada ciclo do pico, a TV toca `Som.tocar("vento", null, -6.0)`. O `CenarioDaVoz.passar` recebe
`_pico_agora` (verdadeiro de `bi` do 1.º ciclo do pico ao fim do 2.º), não o `no_pico()` do kit: o pico do fole é o
da partitura.

### O fim e o vencedor

O kit fecha no `duracao` (80 s de música). Na batida `B_FIM`, `ouvido.fechar()`.

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		return _inteiras[a] > _inteiras[b] or (_inteiras[a] == _inteiras[b] \
			and (pontos[a] > pontos[b] or (pontos[a] == pontos[b] and a < b))))
	return lista
```

### Com menos de quatro

- **Três, dois, um:** o ciclo encolhe (`2 * np` batidas). Com um, ele sopra 1,5 a cada 2 batidas: mais notas, e ele
  vence ao fim. `com_poucos()` devolve `""`.
- **O controle que cai:** as notas dele não abrem; as abertas fecham caladas. Quando volta, entra na próxima nota
  longa dele.

### Os ganchos

| gancho | o que faz |
| --- | --- |
| `montar()` | a câmera, `CenarioDaVoz.montar(self)`, por lugar o braseiro, o fole, a barra e a máscara; `gatilhos_off` |
| `iniciar_jogo()` | o ouvido, `_b_fim`, `_partitura()`, `_robo_rng.seed = rng.seed + 99` |
| `jogar(dt)` | `ouvido.ouvir(dt)`, `passar`, abre as entradas, o sopro sozinho, `notas_perdidas`, `_mostrar` |
| `_comecou(l)` | casa a entrada e julga |
| `_parou(l)` | julga a saída aberta |
| `_mudou(l, mudo)` | nada (o ouvido acende a luz) |
| `nota_perdida(l, n)` | escolhe o `_motivo` e chama o `super` |
| `toque(l, j)` | os pontos; a entrada certa abre a saída; a saída certa faz a inteira |
| `falha(l)` | pelo `_motivo`: a fuligem, murchou, cedo |
| `vencedor()` | acima |
| `combo(l)` | `_seguidas[l]` (G04) |
| `status(l)` | `"%d inteiras" % _inteiras[l]` (a tradução de `"%d inteiras"`) |
| `dica(l)` | `{"partes": ["@mic"], "pos": Vector3(RAIAS[l], 2.6, Z_JOGADOR)}` durante a nota dele enquanto `not aprendeu(l)`; senão `{}` |

O esqueleto:

```gdscript
var ouvido: Ouvido
var _cenario := {}
var _b_fim := 149
var _plano := [[], [], [], []]  ## por lugar: [{bi, dur, fase, c}]
var _k := [0, 0, 0, 0]  ## a próxima nota longa a abrir
var _soprando := [false, false, false, false]  ## da entrada certa ao julgamento da saída
var _inteiras := [0, 0, 0, 0]
var _seguidas := [0, 0, 0, 0]
var _motivo := ["", "", "", ""]
var _pico_agora := false
var _fechou := false
var _ultima_nota := [-1, -1, -1, -1]  ## a nota que o kit acabou de julgar
var _fole := {}  ## lugar -> {couro, tabua, bico, trilho, barra, pare}
var _mascara := {}  ## lugar -> a caixa de fuligem no osso head
var _braseiro := {}


func montar() -> void:
	var pose := CenarioDaVoz.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDaVoz.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		_braseiro[l] = CenarioDaVoz.braseiro(self, l)
		_fole[l] = _montar_fole(l)  # A cena
		_mascara[l] = _montar_mascara(p)  # O cavaleiro
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	ouvido = Ouvido.new(self)
	ouvido.comecar()
	_b_fim = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))
	_robo_rng.seed = rng.seed + 99
	_partitura()


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	ouvido.ouvir(dt)
	_pico_agora = _no_pico_do_fole(b)
	CenarioDaVoz.passar(self, _cenario, _pico_agora)
	for l in presentes():
		if not conectado(l):
			_soprando[l] = false
			continue
		_abrir(l, b)  # a entrada 1 batida antes; o sopro sozinho na batida
		notas_perdidas(l)
	if b >= _b_fim and not _fechou:
		_fechou = true
		ouvido.fechar()
	_mostrar(b)


func _comecou(l: int) -> void:
	var n := ouvido.casar_voz(l)
	if n >= 0 and n % 2 == 0:
		julgar_nota(l, n)


func _parou(l: int) -> void:
	for n in notas_em_aberto(l):
		if int(n) % 2 == 1:
			julgar_nota(l, n)
			return


func nota_perdida(l: int, n: int) -> void:
	_motivo[l] = "fuligem" if n % 2 == 1 else "murchou"
	super(l, n)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	var n: int = _ultima_nota[l]  # o julgar_nota guarda a nota julgada (abaixo)
	var e: Dictionary = _plano[l][n / 2]
	if n % 2 == 0:
		_soprando[l] = true
		ouvido.nova_voz(l, n + 1, e.bi + e.dur, LATENCIA_FIM)
	else:
		_soprando[l] = false
		_inteira(l, e)


func falha(l: int) -> void:
	_soprando[l] = false
	_seguidas[l] = 0
	match _motivo[l]:
		"fuligem":
			_fuligem(l)
		"cedo":
			_murchar(l, 0.5)
		_:
			_murchar(l, 1.0)
			jogador(l).gesto("emote-no", 0.4)
```

`_ultima_nota[l]`: como na P1, troque as chamadas de `julgar_nota(l, n)` por `_julgar(l, n)`, que guarda
`_ultima_nota[l] = n` e chama `julgar_nota`; e no `nota_perdida`, guarde `_ultima_nota[l] = n` antes do `super`. A
saída julgada ERRO pelo `_parou` põe `_motivo[l] = "cedo"` antes de `_julgar`.

`_abrir(l, b)` abre a nota longa `_k[l]` quando `b >= bi - 1`: com `ouvido.sozinho(l)`, guarda para o sopro sozinho
na batida `bi`; com `Ritmo.simples[l]` e a fase `normal` num `c` ímpar, pula; senão
`ouvido.nova_voz(l, 2 * k, bi)`. Na mesma batida `bi - 1` acende o trilho da barra (a pista, abaixo).

O catálogo: `Catalogo.MINIGAMES["S08_J37"] = preload("res://scripts/minigames/s08/o_sopro_no_fole.gd")` e
`"S08_J37"` na lista `minigames` da seção `S08`. As traduções: `"O Sopro no Fole": "Breath in the Bellows"`,
`"Sopre e pare!": "Blow and stop!"`, `"%d inteiras": "%d whole"`.

## A cena

### A câmera

A mesma cripta da P1: `CenarioDaVoz.pose_da_camera()`, lente de 35 mm, plongée de 50°, a 13,5 m do centro
`(0; 1,2; −1,6)`, o modo `fixa`. A borda de baixo, no chão, cai em z 2,63; a meia largura na altura dos cavaleiros é
de 7,1 m. No pico do fole, a câmera recua 10 % (`pose_da_camera(1.1)`) e volta ao sair. Roll zero. O tremor é só o
do `exagero`.

### A luz da seção

A da P1, pelo `CenarioDaVoz.montar(self)`: S8 ameixa, lado B, `Tema.luz_da_secao(4, "B")` (névoa `#18081c`,
preenchimento `#4a2854`, chave `#f8ccba` a 0,77). No pico, a chave sobe 20 % em 1 batida (10 % sem flashes). A
fuligem é estrondo: sem luz.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| a cripta, as tochas, as velas, as colunas | `CenarioDaVoz.montar(self)` | o fundo comum da seção |
| `fire-basket` (escala 2,0) | `(RAIAS[l], 0, −0.4)` | **a forja do lugar**: o braseiro da P1, para onde o fole aponta |

O que não é peça Kenney (caixas do `Kit`, `metallic` 0):

| objeto | forma | onde | material |
| --- | --- | --- | --- |
| a tábua de baixo do fole | caixa 0,9 × 0,08 × 0,6 | `(RAIAS[l], 0.04, 0.5)` | madeira: `Kit.material(Tema.OXIDO_BRILHO, 0.0, 0.85)` |
| o couro | caixa 0,8 × 0,4 × 0,5 | `(RAIAS[l], 0.28, 0.5)`; cresce de baixo | `Kit.material(Tema.OXIDO, 0.0, 0.95)` |
| a tábua de cima | caixa 0,9 × 0,08 × 0,6 | em cima do couro, sobe com ele | madeira |
| o bico | caixa 0,12 × 0,12 × 0,5 | `(RAIAS[l], 0.2, 0.0)`, apontado para o braseiro | ferro: `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| o trilho da barra | caixa `0.6 × dur` × 0,05 × 0,08 | `(RAIAS[l], 0.03, 2.2)`, a ponta esquerda em `RAIAS[l] − 1.0` | `Kit.material(Tema.GRAFITE, 0.0, 0.6)` |
| a barra que enche | caixa do mesmo tamanho, `scale.x` de 0 a 1 | em cima do trilho, cresce da esquerda | `Kit.material(Tema.ETIQUETA, 0.0, 0.8)` |
| o «pare» | caixa 0,04 × 0,14 × 0,1 | na ponta direita do trilho | `Tema.neon(Tema.JOGADOR[l], 1.6)` |
| a máscara de fuligem | caixa 0,30 × 0,14 × 0,04 | no `BoneAttachment3D` do osso `head`, em `(0, 0.06, 0.14)` | `Kit.material(Tema.FITA, 0.0, 1.0)` |

**O fole, pela batida.** Enquanto `_soprando[l]`: o couro `scale.y = 1.0 + g * clampf((b - bi) / dur, 0.0, 1.0)`,
com `g` 1,2 (2,4 no pico); a tábua de cima sobe com ele. Parou, murcha em meia batida.

**A barra (a pista).** O trilho aparece em `t(bi − 1) − CenarioDaVoz.antecedencia(l)` com o comprimento da nota
(0,6 m por batida: 0,9 m na normal, 2,1 m no pico, 0,3 m na curta). A barra enche de `t(bi)` a `t(bi + dur)`, a
0,6 m por batida, e encosta no «pare» na hora de parar. Todos veem a barra de todos. A borda da raia do kit acende
(`acender_raia(l, 1.0)`) durante a nota dele.

**O placar no mundo.** A chama de repouso do braseiro sobe com as inteiras: `h = minf(0.2 + 0.04 * _inteiras[l], 0.8)`.
A labareda (0,9 m) e o apagão da fuligem valem por cima.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a chama do braseiro | o lugar | 2,0; 2,6 na labareda por 1 batida |
| o «pare» da barra | o lugar | 1,6 |
| a borda da raia | o lugar | o kit (`acender_raia`) |
| as tochas | a forja | 1,8 (o cenário comum) |

A fuligem é `Tema.FITA` e não brilha. A madeira e o couro são `Tema.OXIDO_BRILHO` e `Tema.OXIDO`. Somem os
`#8a5a33`, `#5a3a2a`, `#5b6275`, `#ff7a1a`, `#ff9a40`, `#8c98aa`, `#2a2433` e a luz laranja da casa da ficha
antiga. Nada nas cores dos lugares além do que é do lugar.

### A montagem

- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = PI` e `preso = true` (de costas para a câmera, de frente para
  o fole); o braseiro; `_montar_fole(l)` com as caixas da tabela; a máscara, escondida.
- O fole fica entre o cavaleiro (z 1,4) e o braseiro (z −0,4); a barra fica na frente do cavaleiro (z 2,2), no
  chão, onde a câmera a vê sem o boneco na frente.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a entrada e a saída | a nota do kit (`Som.tocar("nota", ...)`, H08) | — | `nota_*` |
| o sopro do lugar | `Som.tocar("sopro", _bico(l), -8.0)` na entrada certa | — | `sint_sopro` |
| a nota inteira | `Som.tocar("fogo", b.base, -10.0)` | `nota:%d`, 0,8 (300 ms), depois da escuta | `fogo_*`, `nota_*` |
| a fuligem | `Som.tocar("sopro", _bico(l), -2.0)` e `Som.tocar("golpe", _rosto(l), -6.0)` | `nota_quebrada:%d`, 0,8 (400 ms) | `sint_sopro`, `golpe_*` |
| o pico | `Som.tocar("vento", null, -6.0)` no começo de cada ciclo do pico | — | `vento_*` |
| a faixa | `MUS_S08_J37`: 112 BPM, Sol menor; até ela existir, a reserva `"sopro"` (105 bpm) | — | `mus_s08_j37` |

- A música desce 12 dB enquanto um microfone escuta (o ouvido abre a escuta 0,25 s antes da entrada e da saída de
  cada nota, e fecha no julgamento).
- **O `falha` não existe aqui:** a ficha antiga tocava `Som.tocar("falha", ...)` na fuligem; o bipe é proibido.
- O material `"madeira"` toca pelo minigame, na nota inteira, depois da escuta.

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar | — |
| **do começo ao fim do sopro** | o dono | **nada** (a prova exige < 0,02) | — | — | — |
| a entrada ERRO, a nota que murcha | o dono | o kit: `erro` (0,7 / 0,3, 160 ms) | — | o kit: a cor escurecida 0,5 s | — |
| a nota inteira | o dono | a textura `madeira` 0,5 depois da escuta; sem háptica, `toque` | — | o kit: branco 0,15 s no perfeito | `nota:%d` |
| a fuligem | o dono | o kit: `erro` (o sopro já acabou) | — | o kit | `nota_quebrada:%d` |

- **Nada vibra do começo ao fim do sopro.** O motor faz ruído no microfone do mesmo controle e seguraria a voz
  «falando» depois de parar: a fuligem viria de graça. Por isso a ficha antiga, que vibrava `toque` a cada meia
  batida do sopro, muda: o fole e a barra mostram o sopro, a mão fica quieta.
- A barra de luz é sempre a cor do lugar.
- **No rádio:** sem microfone nem alto-falante. O lugar sopra sozinho desde o começo, com a `troca` gravada pelo
  ouvido. A háptica do kit vai pelo rumble. A luz do mudo passa pela ponte.

### O robô

```gdscript
# O robô fala pelo tempo da nota no controle simulado. Quando erra: metade das
# vezes sopra 0,4 s demais (a fuligem), metade entra 0,2 s atrasado.
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_feita := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_sobra := [0.0, 0.0, 0.0, 0.0]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	for n in notas_em_aberto(l):
		if int(n) % 2 == 1 or int(n) <= int(_robo_feita[l]):
			continue  # a saída: o robô já fala pelo tempo da nota
		if int(_robo_nota[l]) != int(n):
			_robo_nota[l] = n
			var certo := Forja.robo_acerta()
			var tarde := not certo and _robo_rng.randf() < 0.5
			_robo_mira[l] = 0.2 if tarde else 0.0
			_robo_sobra[l] = 0.4 if not certo and not tarde else 0.0
		var ini := alvo_da(l, n) + float(_robo_mira[l])
		if Ritmo.t_musica() >= ini:
			var e: Dictionary = _plano[l][int(n) / 2]
			var fim := Ritmo.t_da_batida(e.bi + e.dur) + LATENCIA_FIM
			Forja.robo_falar(l, 0.8, fim - ini + float(_robo_sobra[l]))
			_robo_feita[l] = n
		break
```

O robô fala uma vez, pelo tempo da nota: o `robo_falar` segura o nível pelos segundos pedidos. A entrada 0,2 s
atrasada passa da janela do BOM e vira ERRO (a saída não abre); a sobra de 0,4 s passa dos 0,14 s da folga e vira a
fuligem.

## O cavaleiro

O cavaleiro é o da montagem (G13), de costas para a câmera, de mãos livres. O cavaleiro pode ser de outra raça (G13,
o ajuste dela de 09/10): esta ficha não supõe corpo humano; usa só o esqueleto comum de 7 ossos (o osso `head` para
a máscara de fuligem) e as animações `interact-right`, `emote-no` e `idle`.

| stat | gancho | o que muda no Fole | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | — | não age (ninguém empurra) | — | — | — |
| Passo | — | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | a tosse da fuligem (2 tempos) | 2,5 tempos | 2 tempos | 1,5 tempo |
| Faro | `pista` | o trilho da barra aparece antes; a nota cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens: o Escudo absorve o primeiro erro (o kit, G03); o Fole devolve metade do combo (as inteiras seguidas); a
Lanterna adianta o trilho meio tempo; o Martelo dobra o perfeito no tempo forte (o kit); o Diapasão é do kit (a nota
1,3× e o perfeito puxa o combo da equipe); a Âncora não age. Nenhum stat muda a janela de julgamento.

```gdscript
## A máscara de fuligem: uma caixa presa ao osso `head`, escondida até a fuligem.
func _montar_mascara(p) -> MeshInstance3D:
	var esq: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false) if p.modelo else null
	if esq == null:
		return null
	var presa := BoneAttachment3D.new()
	presa.bone_name = "head"
	esq.add_child(presa)
	var m := Kit.caixa(presa, Vector3(0.30, 0.14, 0.04), Vector3(0, 0.06, 0.14), Kit.material(Tema.FITA, 0.0, 1.0))
	m.visible = false
	return m
```

## As reações

- **Carimbos** (do kit e do HUD, G04; o Fole não chama nenhum): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar), `car_por_um_fio` (o vencedor por até 1 inteira). O `car_acorde` não acontece: em hoqueto, nunca há quatro
  notas no mesmo tempo.
- **Adesivos:** ninguém sai da rodada; nenhum adesivo durante o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: a fuligem** (`fuligem`). O fole estoura, a nuvem preta cobre o rosto do cavaleiro, e ele tosse. A sala
ri de quem não soube parar. Degrau estrondo.

- **Rastro:** o rosto fica preto até a próxima nota inteira dele; o braseiro apaga até a próxima nota longa.
- **A curva:** de 2 a 36 s, o hoqueto de 1,5 batida; de 36 a 54 s, o pico: o fole grande de 3,5 batidas (1,9 s de
  fôlego); de 54 a 71 s, o hoqueto outra vez; de 71 s ao fim, a reta: notas curtas e longas alternadas, e a inteira
  vale o dobro.
- **Ensina sem falar:** a barra de ferro enche no tempo da nota, e o «pare» é a cor do dono; o fole cresce enquanto
  ele sopra.
- **Quem está perdendo:** a reta vale +100 por inteira: duas inteiras na reta viram 2 inteiras de atraso.
- **A nota de hoje:** 3. Gênero `tct`.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem um `toque` de entrada (n par) com `t_musica` ≤ 10,0 (o P4 entra na batida 10, 5,4 s) | o quadro de 6 s mostra um fole cheio |
| 4. o momento | pelo menos 3 linhas `momento` `fuligem` entre 0 e 80 s, pelo menos 1 do P4 | 1 quadro em cada 4 mostra um rosto preto |
| 5. a curva | existem notas com saída − entrada ≥ 3,0 batidas entre 36 e 54 s e ≤ 1,0 batida depois de 71 s | o quadro de 45 s mostra o fole grande (o couro 2 vezes mais alto que no de 20 s) |
| 6. a falha | o P4 tem pelo menos 3 `toque` com `erro` ou `momento` `fuligem` | o braseiro do P4 aparece apagado em 1 quadro em 5 |
| 7. quem perde joga | a maior distância entre duas `nota` seguidas de cada lugar é de até 16 batidas (o ciclo do pico); o P4 tem uma inteira em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | toda `fuligem` tem 0,05 ≤ `x_tela` ≤ 0,95 e `altura_tela` ≥ 0,06 | o cavaleiro de cada raia cabe inteiro no quadro de 480 × 270 |
| 9. o impacto | uma linha `sensacao` `erro` a até 16,7 ms de cada `fuligem` | o quadro seguinte à fuligem mostra a nuvem preta |
| 10. o placar no mundo | o `valores` da `fuligem` bate com `_inteiras` | no quadro de 70 s, a chama de repouso do líder é a mais alta |

A mesa padrão roda em duas rodadas até o robô por lugar existir: `bash tests/prova_do_jogo.sh --robo=medio` (os
itens 1, 5, 8, 9 e 10) e `--robo=ruim` (os itens 4, 6 e 7).

## Pronto quando

O Fole joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o ruim estoura
fuligem). Aguenta o cabo que cai e volta, e fecha com vencedor. Sem microfone, o fole sopra sozinho e a `troca`
aparece. Nada vibra do começo ao fim do sopro. A prova do jogo passa, e `bash tests/prova_visual.sh` passa com a
prancha olhada (os foles enchendo, a barra, a fuligem, o rosto preto).

## Provas

Em `godot/testes/prova_do_jogo.gd`, depois da `_prova_a_voz()`:

```gdscript
## S08_J37: o robô sopra as notas longas; a entrada e a saída são julgadas;
## sai uma nota inteira; nada vibra do começo ao fim do sopro.
func _prova_o_sopro_no_fole() -> void:
	var no_sopro := [0]
	var vibrou := [0]
	var olhar := func(mg) -> void:
		for l in mg.presentes():
			if mg._soprando[l]:
				no_sopro[0] += 1
				var pc := Forja.percepcao(l)
				if maxf(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0))) >= 0.02:
					vibrou[0] += 1
	var mg = await _joga_o_minigame("S08_J37", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg._inteiras.max() >= 1, "Fole: uma nota inteira (%s)" % [mg._inteiras])
	_esperar(no_sopro[0] > 0 and vibrou[0] == 0, "Fole: nada vibrou no sopro (%d de %d)" % [vibrou[0], no_sopro[0]])
	_esperar(mg.colocacao().size() == mg.presentes().size(), "Fole: a colocação tem todos")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S08_J37")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	_esperar(toques.any(func(e): return int(e.get("n", -1)) % 2 == 0) \
		and toques.any(func(e): return int(e.get("n", -1)) % 2 == 1), "Fole: entradas (n par) e saídas (n ímpar)")
	var fuligens := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "fuligem")
	if Forja.robo_temperamento == "ruim":
		_esperar(fuligens.size() >= 3, "Fole: %d fuligens na mesa ruim" % fuligens.size())
	for f in fuligens:
		_esperar(float(f.get("x_tela", 0.0)) >= 0.05 and float(f.get("x_tela", 0.0)) <= 0.95, "Fole: a fuligem na tela (%s)" % [f])
```

`Forja.robo_temperamento` é o temperamento da F09 (se o nome lá for outro, use o da F09).

### O que o registro mede

- `voz` (`comecou` e `parou`, o nível e o limiar) de cada nota longa: a noite vê quanto cada microfone sobe e
  **quanto demora para descer**. O `LATENCIA_FIM` real sai do desvio das saídas.
- `nota` e `toque` da entrada (n par) e da saída (n ímpar).
- `momento` `fuligem`, com as inteiras de todos.
- `troca` de `microfone` para `sem_microfone`.

### As pranchas que o jogador do time olha

- o quadro de 6 s: um fole cheio e a barra encostando no «pare»;
- o de 45 s: o fole grande do pico;
- um quadro com a fuligem: a nuvem preta e o boneco tossindo;
- os quadros seguintes: o rosto preto até a inteira;
- o último: as chamas de repouso, mais altas em quem fez mais inteiras.

### O que o André joga e sente

`./run-local.sh -- --sala=S08_J37`, com quatro:

- parar em seco no fim da nota é o momento engraçado (a fuligem);
- o vizinho soprando não estraga a nota de ninguém. Se estragar, anote os `voz` dos dois;
- a mão fica quieta enquanto ele sopra, e a textura de madeira vem logo depois da inteira;
- o fole grande do pico pede o fôlego inteiro.

### Armadilhas

- **O robô sorteia no dele:** `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`.
- **A saída depende do fim da voz**, e o nível desce devagar: o ouvido usa o `VOZ_FICA` (0,18) para o fim. Não troque
  pelo `VOZ_ACIMA`, senão a voz «para» e «volta» no meio do sopro.
- **Uma voz, uma nota.** Depois da fuligem, o `surdo_ate` da tosse ignora o resto da voz; o `_parou` só julga uma
  saída aberta, e a saída da próxima nota só abre depois da próxima entrada.
- **O hoqueto sem encostar.** Meia batida entre uma nota e a do próximo; não encurte, é o que impede o vizinho de
  «parar» a sua nota.
- **A máscara no osso `head`:** se a prancha mostrar a máscara atrás da cabeça, o osso olha para −z: troque o sinal do
  z (0,14) e anote.

### Ao terminar

- No [quadro](README.md): a linha **P2**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: O Sopro no Fole no kit — sopre a nota inteira e pare em seco`
