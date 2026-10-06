# H03 — A calibração

**Sprint:** H · **Tamanho:** P · **Estimativa:** US$ 2,0 · **Depende de:** F00, H02 (e G02 para a medida automática — ver "Sem a G02")

## Por quê

Cada controle tem a sua latência (o cabo, o rádio, a TV, o fone). O desvio
de cada lugar entra no julgamento (`Ritmo.desvio[l]`, H02), fica guardado
nas opções do lugar e vai para o registro — é o primeiro número que a noite
de seis horas compara.

## Ler antes

- [A calibração que ninguém vê](../04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)
- [A arquitetura: o relógio de áudio e o julgamento](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03)
- [A voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto) (a linha nova das opções)

## O estado de hoje

- `godot/scripts/ritmo.gd` (H01 + H02): `var desvio := [0.0, 0.0, 0.0, 0.0]`,
  e `julgar()` já tira o desvio do toque. Ninguém escreve no `desvio`.
- `godot/scripts/opcoes.gd:29-30`: as opções por lugar são `gatilho` e
  `vibracao`, guardadas em `user://opcoes.cfg` na seção `P1`..`P4`
  (`opcoes.gd:63-65`, `opcoes.gd:79-81`). Com o robô, nada se lê nem se grava
  (`opcoes.gd:58-59`, `opcoes.gd:76-77`).
- `godot/scripts/ui/tela_opcoes.gd:20-33`: a lista de linhas
  (`["gatilho", "Gatilhos", "P%d"]`, `["vibracao", "Vibração", "P%d"]`, e as da
  sessão); `trocar(dx)` (linha 40), `valor(chave)` (linha 66),
  `_fracao(chave)` (linha 81), `_draw()` (linha 95).
- `godot/scripts/main.gd:851-860`: na tela de opções, ▲▼ navega, ◀▶ troca e
  ◯/Options fecha. O ✕ não faz nada ali. As opções gravam ao fechar
  (`main.gd:791`, `Opcoes.gravar(Forja.robo)`).
- O transporte do controle já está no módulo: `Forja.pad(Forja.pad_do_lugar(l))`
  tem `conexao_curta` = `"USB"`, `"BT"`, `"declara USB"`, `"virtual"` ou
  `"simulado"` (`nativo/godot/forja_controles.cpp:42-55`).
- A construção do cavaleiro (G02) ainda pode não existir: é ela que mede o
  desvio com as oito marteladas.
- **Provado nesta preparação**, numa cópia do projeto com a H01 e a H02: o
  código de "O alvo" (menos o desenho da régua) e as checagens de "Provas"
  passam na prova do jogo, com a linha `calibracao` de +80 ms e o
  transporte `"simulado"` no registro.

## O alvo

(**novo**: entra no 13 no mesmo commit, na seção do relógio e do julgamento.)

`godot/scripts/opcoes.gd`:

```gdscript
## O tempo de cada lugar (a calibração), em ms: o quanto o toque daquele
## controle chega atrasado (negativo: adiantado). A construção do cavaleiro
## mede (G02); as opções ajustam à mão, de 10 em 10.
const TEMPO_PASSO := 10
const TEMPO_MIN := -150
const TEMPO_MAX := 250
static var tempo_ms := [0, 0, 0, 0]
```

(em `de_fabrica()`: `tempo_ms = [0, 0, 0, 0]`; em `carregar()`:
`tempo_ms[l] = clampi(int(cfg.get_value("P%d" % (l + 1), "tempo_ms", 0)), TEMPO_MIN, TEMPO_MAX)`;
em `gravar()`: `cfg.set_value("P%d" % (l + 1), "tempo_ms", tempo_ms[l])`.)

`godot/scripts/ritmo.gd`:

```gdscript
## A calibração de um lugar: vale no julgamento, fica nas opções (sem gravar:
## quem grava é quem chama — as opções gravam ao fechar) e vai para o
## registro, com o transporte do controle. `origem`: "opcoes" (à mão) ou
## "construcao" (as oito marteladas da G02); `amostras`: quantos golpes mediram.
func definir_desvio(l: int, segundos: float, origem: String, amostras := 0) -> void:
	l = clampi(l, 0, 3)
	var ms := clampi(roundi(segundos * 1000.0), Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX)
	desvio[l] = ms / 1000.0
	Opcoes.tempo_ms[l] = ms
	var p := Forja.pad_do_lugar(l)
	var transporte := str(Forja.pad(p).get("conexao_curta", "")) if p >= 0 else ""
	Forja.evento("calibracao", l + 1, {"lugar": l, "desvio_ms": ms, "amostras": amostras, "origem": origem,
		"transporte": transporte})
```

e, no `_ready()` do `Ritmo` (as opções já foram carregadas pelo `Forja`,
que é o primeiro autoload):

```gdscript
	for l in 4:
		desvio[l] = int(Opcoes.tempo_ms[l]) / 1000.0
```

`godot/scripts/ui/tela_opcoes.gd` — a linha "Tempo" do lugar, e o metrônomo
que confere o ajuste sem número nenhum na tela além do valor da linha:

```gdscript
## O metrônomo da linha Tempo: um tique na TV a cada batida; ✕ no tique deixa
## um ponto na régua embaixo da linha — no centro, o tempo do lugar está certo.
const METRONOMO_BPM := 100.0
const REGUA_MS := 200.0  ## a régua vai de −REGUA_MS a +REGUA_MS
var _metronomo_us := 0
var _batida_tocada := -1
var _toques: Array = []  ## os últimos 8 desvios, em ms, já corrigidos pelo tempo do lugar


func _periodo_us() -> int:
	return int(60.0 / METRONOMO_BPM * 1000000.0)


## ✕ na linha Tempo: onde o toque caiu em relação à batida mais perto.
func tocou() -> void:
	if _linhas.is_empty() or _linhas[linha][0] != "tempo":
		return
	var desde := Time.get_ticks_usec() - _metronomo_us
	var fase := desde % _periodo_us()
	var ms := fase / 1000.0
	if ms > _periodo_us() / 2000.0:
		ms -= _periodo_us() / 1000.0
	_toques.append(ms - float(Opcoes.tempo_ms[quem]))
	if _toques.size() > 8:
		_toques.pop_front()
```

(`abrir()` zera `_toques`, `_metronomo_us = Time.get_ticks_usec()` e
`_batida_tocada = -1`; `_process()` toca o tique quando a linha selecionada é
`"tempo"` e a batida `(Time.get_ticks_usec() - _metronomo_us) / _periodo_us()`
passou de `_batida_tocada`: `Som.tocar("tique", null, -4.0)`.)

## Passos

1. **Prova verde antes** (`bash tests/prova_do_jogo.sh`).
2. **`godot/scripts/opcoes.gd`**: acrescente `TEMPO_PASSO`, `TEMPO_MIN`,
   `TEMPO_MAX` e `tempo_ms` de "O alvo", e as três linhas em `de_fabrica()`,
   `carregar()` e `gravar()`, na seção `P%d` de cada lugar, ao lado de
   `gatilho` e `vibracao`.
3. **`godot/scripts/ritmo.gd`**: acrescente `definir_desvio()` e as duas
   linhas do `_ready()`.
4. **`godot/scripts/ui/tela_opcoes.gd`**:
   - em `abrir()`, a linha nova logo depois da vibração:
     `["tempo", "Tempo", "P%d" % (lugar + 1)]`; e zere o metrônomo (ver o alvo);
   - em `trocar(dx)`, o caso:

     ```gdscript
     		"tempo":
     			var ms := clampi(int(Opcoes.tempo_ms[quem]) + dx * Opcoes.TEMPO_PASSO, Opcoes.TEMPO_MIN, Opcoes.TEMPO_MAX)
     			Ritmo.definir_desvio(quem, ms / 1000.0, "opcoes")
     ```

   - em `valor(chave)`: `"tempo": return "%+d ms" % int(Opcoes.tempo_ms[quem])`
     (o zero sai "+0 ms");
   - em `_fracao(chave)`: nada (a linha Tempo não tem barra);
   - `tocou()`, `_periodo_us()` e o tique no `_process()`, do alvo;
   - em `_draw()`, quando a linha `i` é `"tempo"` e está selecionada: uma
     régua de 440 × 8 px, centrada na largura do quadro, 18 px abaixo da
     linha (`Tema.TRILHO`); um traço vertical de 4 × 28 px no centro, que
     pisca em `Tema.AMARELO` nos primeiros 80 ms de cada batida e fica
     `Tema.LINHA` no resto; e um círculo de raio 7 por toque em
     `_toques`, em `x = centro + clampf(ms / REGUA_MS, -1, 1) * 220`, na cor
     do lugar, o mais velho com alfa 0,25 e o mais novo com alfa 1. Nada de
     número;
   - com a linha Tempo selecionada, as dicas de baixo ganham
     `["cruz", "tocar no tempo"]` antes de `["circulo", "voltar"]`.
5. **`godot/scripts/main.gd:851-860`** (o `"opcoes"` do `_quadro_overlay`):
   acrescente `if Forja.apertou(qo, Forja.CRUZ): tela_opcoes.tocou()`.
6. **`godot/scripts/traducoes.gd`**: `"Tempo": "Timing"` e
   `"tocar no tempo": "tap on the beat"`. Siga a caixa das dicas que já
   existem ("trocar", "voltar"); se a F07 já passou as dicas para
   "Botão ✕ (…)", siga a F07.
7. **`godot/testes/prova_do_jogo.gd`**: `_prova_da_calibracao()` (em
   "Provas"), chamada dentro de `_prova_do_percurso()` logo depois da
   checagem "os quatro entraram" — antes disso nenhum lugar tem controle, e o
   `transporte` sairia vazio. Rode a prova.
8. **O 13**: acrescente `Opcoes.tempo_ms` e `Ritmo.definir_desvio(l,
   segundos, origem, amostras)`; na tabela do registro v2, o tipo
   `calibracao` passa a ter `desvio_ms`, `amostras`, `origem` e
   `transporte`, escrito pela H03 (à mão) e pela G02 (a construção).

### Sem a G02

Esta ficha não depende da G02 para fechar: sem ela, o desvio vem só das
opções (passos 2 a 8) e começa em 0. Quando a G02 chegar, ela chama
`Ritmo.definir_desvio(l, mediana_s, "construcao", 8)` com a mediana das oito
marteladas e grava as opções (`Opcoes.gravar(...)`, como faz o `main.gd:791`).
Se a G02 já estiver feita quando esta ficha começar, troque o que ela
escreve no desvio por essa chamada, no mesmo commit.

## Armadilhas

- **A ordem dos autoloads**: o `Ritmo` lê `Opcoes.tempo_ms` no `_ready()`,
  e quem carrega as opções é o `_ready()` do `Forja`, o primeiro autoload
  (`godot/scripts/forja.gd:120`). O `Ritmo` é o último (H01). Não mude a ordem.
- **O robô joga com as opções de fábrica** (`opcoes.gd:58-59`): o desvio da
  prova é sempre 0 no começo. A prova que mexe no `tempo_ms` **devolve o
  valor** no fim; se não devolver, o julgamento das provas seguintes muda.
- **Nenhum caminho de prova**: `definir_desvio` não sabe de robô. O que a
  prova faz é chamar as mesmas funções que a tela chama (`trocar`).
- **A pausa**: a tela de opções abre por cima da sala congelada; o `Ritmo`
  está pausado (H04). Por isso o metrônomo das opções usa o relógio do
  sistema, não o `Ritmo`.
- **O metrônomo mede com a resolução do quadro** (o ✕ vem do módulo uma vez
  por quadro); a régua é para o olho, não para o registro.
- **O texto**: "Tempo" e o valor "+80 ms" são a única coisa nova com número
  na tela, e ficam nas opções (o 04 pede "Tempo, em passos de 10 ms"). Nada
  de "calibração", "latência" ou "desvio" na tela.
- **O lugar desconectado**: a opção é do lugar, não do controle; um controle
  que volta ao mesmo lugar herda o tempo do lugar. Não guarde nada pelo
  aparelho (regra do [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md)).
- **O treino**: nada muda; o desvio vale desde o primeiro toque.

## Não fazer

- Não criar tela de calibração nem pergunta ao jogador: a calibração que se
  vê é a das marteladas (G02) e o ajuste fino das opções.
- Não gravar as opções dentro do `definir_desvio` (quem grava é quem chama).
- Não guardar o desvio por controle, por nome do controle ou por endereço.

## Pronto quando

Um lugar com desvio de +80 ms julga como perfeito um toque 80 ms atrasado;
◀▶ na linha Tempo das opções muda o desvio de 10 em 10 ms (de −150 a
+250), o valor sobrevive a fechar e abrir o jogo, cada mudança escreve uma
linha `calibracao` no registro com o transporte do controle, e o metrônomo
das opções toca e marca os toques na régua.

## Provas

**Na sessão:**

```bash
bash tests/prova_do_jogo.sh
```

A checagem nova em `godot/testes/prova_do_jogo.gd`:

```gdscript
## A calibração (H03): o desvio do lugar vale no julgamento, a linha Tempo
## das opções anda de 10 em 10 e para nas bordas. Devolve tudo como achou.
func _prova_da_calibracao() -> void:
	var guardado: Array = Opcoes.tempo_ms.duplicate()
	Ritmo.definir_desvio(2, 0.080, "opcoes")
	_esperar(Opcoes.tempo_ms[2] == 80 and is_equal_approx(Ritmo.desvio[2], 0.080), "calibração: +80 ms nas opções e no Ritmo")
	_esperar(Ritmo.julgar(2, 10.080, 10.0) == Ritmo.PERFEITO, "calibração: com +80 ms, 80 ms atrasado é perfeito")
	var tela := TelaOpcoes.new()
	tela.abrir(1)
	var i := -1
	for k in tela._linhas.size():
		if tela._linhas[k][0] == "tempo":
			i = k
	_esperar(i >= 0 and tela._linhas[i][2] == "P2", "calibração: a linha Tempo é do lugar que abriu")
	if i >= 0:
		tela.linha = i
		Ritmo.definir_desvio(1, 0.0, "opcoes")
		tela.trocar(1)
		_esperar(Opcoes.tempo_ms[1] == 10 and is_equal_approx(Ritmo.desvio[1], 0.010), "calibração: ▶ soma 10 ms")
		tela.trocar(-1)
		tela.trocar(-1)
		_esperar(Opcoes.tempo_ms[1] == -10 and tela.valor("tempo") == "-10 ms", "calibração: ◀ tira 10 ms, e a linha mostra")
		Ritmo.definir_desvio(1, 0.250, "opcoes")
		tela.trocar(1)
		_esperar(Opcoes.tempo_ms[1] == Opcoes.TEMPO_MAX, "calibração: para em +%d ms" % Opcoes.TEMPO_MAX)
	tela.free()
	for l in 4:
		Ritmo.definir_desvio(l, int(guardado[l]) / 1000.0, "opcoes")
```

Em `_prova_do_relatorio()`, no laço que já lê a linha do tempo (H02),
guarde as linhas de tipo `calibracao` (`var calibracoes: Array = []` antes do
laço; `elif ev.get("tipo", "") == "calibracao": calibracoes.append(ev)`
dentro) e confira depois dele:

```gdscript
	_esperar(calibracoes.any(func(ev): return int(ev.get("desvio_ms", 0)) == 80 and ev.get("transporte", "") == "simulado"),
		"registro: a calibração de +80 ms, com o transporte do controle")
```

**Com o André, local:** ver abaixo.

## Para o André (local)

Com um controle no cabo e outro no rádio: abra Botão △ (Opções) › Tempo em
cada um, toque ✕ junto com o tique uns dez segundos e ajuste com ◀▶ até os
pontos ficarem no centro da régua. Anote o valor de cada um ("cabo +X ms,
rádio +Y ms"). Feche e abra o jogo: os valores ficaram.

## Ao terminar

- Marque a H03 como **feito** no [quadro](README.md), com o commit e o gasto
  real.
- Commit sugerido (sem trailer):
  `feat: a calibração de cada lugar — o Tempo nas opções, no julgamento e no registro`
