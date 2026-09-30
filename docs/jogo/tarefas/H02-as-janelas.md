# H02 — As janelas de julgamento

**Sprint:** H · **Tamanho:** M · **Modelo:** Opus · **Estimativa:** US$ 3,0 · **Depende de:** F00, H01

## Por quê

Sem janelas, não há perfeito, ótimo, bom e erro — é o coração do jogo de
ritmo. Esta ficha dá ao `Ritmo` o julgamento puro (o toque contra a nota),
a ajuda escondida de quem está atrás e o registro de cada toque. Quem usa é
o kit (H04).

## Ler antes

- [A arquitetura: o relógio de áudio e o julgamento](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03)
- [As janelas](../04-ritmo-e-audio.md#as-janelas)
- [Princípio 8](../02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom)

## O estado de hoje

- `godot/scripts/ritmo.gd` existe (H01): `tocar`, `t_musica`, `batida`,
  `t_da_batida`, `pausar`, `parar`, `registrar_nota`. Não julga nada.
- Nenhuma sala julga por janela: A Centelha mede a "rapidez" pelo anel que
  fecha (`godot/scripts/salas/centelha.gd:327`,
  `var rapidez := clampf(1.0 - e.t / e.janela, 0.0, 1.0)`); O Canto compara
  intervalos. Nada disso muda aqui.
- **Duas armadilhas medidas nesta preparação** (as contas em double do
  GDScript e o `Vector2` de 32 bits):
  - `(10.06 - 10.0) * 1000` dá `60.0000000000005` — um toque na borda
    exata de +60 ms cairia fora do perfeito;
  - `Vector2(-0.040, 0.060).x * 1000` dá `-39.99999910593033` — o `Vector2`
    guarda `float` de 32 bits, e a borda de −40 ms sai errada.
  Por isso o desvio e as bordas se arredondam a 0,1 ms antes de comparar, e
  **a borda vale dentro** da janela.
- O código de "O alvo" e as checagens de "Provas" foram rodados numa cópia
  do projeto, com a prova do jogo inteira: verde.

## O alvo

A API do [13](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03),
e o que ela precisa (marcado **novo**: entra no 13 no mesmo commit).

Acrescente ao fim de `godot/scripts/ritmo.gd`:

```gdscript
# ------------------------------------------------------------ o julgamento --
# As janelas (docs/jogo/04-ritmo-e-audio.md#as-janelas), iguais nos 45
# minigames, medidas a partir do toque corrigido pela calibração do lugar.

enum { ERRO, BOM, OTIMO, PERFEITO }
const JANELA_PERFEITO := Vector2(-0.040, 0.060)  ## (adiantado, atrasado), em s
const JANELA_OTIMO := 0.090
const JANELA_BOM := 0.140
## Os nomes do registro (o tipo `toque`), na ordem do enum.
const NOMES_DO_JULGAMENTO := ["erro", "bom", "otimo", "perfeito"]
## A ajuda escondida (docs/jogo/02#8): o último colocado ganha isto na janela
## BOM dos perigos físicos; nunca no perfeito, nunca nos pontos.
const FOLGA_DO_ULTIMO := 0.040
## A partitura mais simples: depois de tantos erros seguidos, até tantos acertos seguidos.
const ERROS_PARA_SIMPLIFICAR := 3
const ACERTOS_PARA_VOLTAR := 4

var desvio := [0.0, 0.0, 0.0, 0.0]  ## a calibração de cada lugar, em s (H03, G02)
## true: as notas do lugar passam das semicolcheias para as colcheias (o minigame lê).
var simples := [false, false, false, false]
var _erros_seguidos := [0, 0, 0, 0]
var _acertos_seguidos := [0, 0, 0, 0]


## O julgamento de um toque em t_toque contra a nota em t_alvo (os dois em
## tempo de música). O desvio do lugar sai do toque antes de comparar; a
## folga só alarga o BOM. A borda vale dentro.
func julgar(l: int, t_toque: float, t_alvo: float, folga_bom := 0.0) -> int:
	var d := desvio_ms(l, t_toque, t_alvo)
	if d >= _ms(JANELA_PERFEITO.x) and d <= _ms(JANELA_PERFEITO.y):
		return PERFEITO
	if absf(d) <= _ms(JANELA_OTIMO):
		return OTIMO
	if absf(d) <= _ms(JANELA_BOM + maxf(folga_bom, 0.0)):
		return BOM
	return ERRO


## O desvio do toque já corrigido pela calibração do lugar, em ms, com uma
## casa (negativo: adiantado).
func desvio_ms(l: int, t_toque: float, t_alvo: float) -> float:
	return _ms(t_toque - float(desvio[clampi(l, 0, 3)]) - t_alvo)


## A folga do lugar agora: FOLGA_DO_ULTIMO se ele está sozinho em último
## entre os presentes; 0 se não (empate em último não é estar atrás).
static func folga_para(l: int, pontos: Array, presentes: Array) -> float:
	if presentes.size() < 2 or not l in presentes:
		return 0.0
	for o in presentes:
		if o != l and int(pontos[o]) <= int(pontos[l]):
			return 0.0
	return FOLGA_DO_ULTIMO


## Conta o julgamento para a partitura mais simples (docs/jogo/02#8).
func contar_para_ajuda(l: int, j: int) -> void:
	if j == ERRO:
		_erros_seguidos[l] += 1
		_acertos_seguidos[l] = 0
		if _erros_seguidos[l] >= ERROS_PARA_SIMPLIFICAR:
			simples[l] = true
	else:
		_acertos_seguidos[l] += 1
		_erros_seguidos[l] = 0
		if simples[l] and _acertos_seguidos[l] >= ACERTOS_PARA_VOLTAR:
			simples[l] = false


## Todo minigame começa sem ajuda.
func zerar_ajuda() -> void:
	simples = [false, false, false, false]
	_erros_seguidos = [0, 0, 0, 0]
	_acertos_seguidos = [0, 0, 0, 0]


## Um toque julgado, no registro (o tipo `toque` do registro v2). Sem
## `desvio_em_ms` (a nota passou sem toque), a linha diz "perdida".
func registrar_toque(l: int, n: int, j: int, desvio_em_ms := NAN) -> void:
	var campos := {"slot": dono, "faixa": slot, "lugar": l, "n": n, "julgamento": NOMES_DO_JULGAMENTO[j],
		"t_musica": snappedf(_t, 0.001)}
	if is_nan(desvio_em_ms):
		campos["perdida"] = true
	else:
		campos["desvio_ms"] = desvio_em_ms
	Forja.evento("toque", l + 1, campos)


## Segundos para ms com uma casa: tira o ruído do float (e o do Vector2 de 32 bits).
static func _ms(s: float) -> float:
	return roundf(s * 10000.0) / 10.0
```

Os valores do enum ficam `ERRO = 0`, `BOM = 1`, `OTIMO = 2`, `PERFEITO = 3`:
a ordem é a da qualidade, e o kit pode comparar (`j >= Ritmo.OTIMO`).

## Passos

1. **Prova verde antes** (`bash tests/prova_do_jogo.sh`).
2. **`godot/scripts/ritmo.gd`**: acrescente o bloco de "O alvo" ao fim do
   arquivo, sem mudar nada do relógio.
3. **`godot/testes/prova_do_jogo.gd`**: acrescente `_prova_das_janelas()`
   (em "Provas") e chame-a em `_ready()` logo depois de
   `await _prova_do_relogio()`. Ela é pura: não abre sala nem espera quadro.
   Rode a prova.
4. **O registro na prova**: em `_prova_do_relatorio()`, depois de achar os
   arquivos, acrescente a checagem da linha do tempo de "Provas" (lê cada
   linha como JSON; confere que a linha `toque` que `_prova_das_janelas()`
   escreveu está lá, com `julgamento` e `desvio_ms`, e que a `perdida` não
   tem `desvio_ms`). Rode a prova.
5. **O 13**: na seção do relógio e do julgamento, acrescente
   `NOMES_DO_JULGAMENTO`, `FOLGA_DO_ULTIMO`, `desvio_ms`, `folga_para`,
   `simples`, `contar_para_ajuda`, `zerar_ajuda`, `registrar_toque`, e a
   frase "a borda vale dentro; desvio e bordas arredondados a 0,1 ms". Na
   tabela do registro v2, no tipo `toque`, acrescente `perdida` (quando a
   nota passou sem toque, no lugar de `desvio_ms`).
6. **O registro v2 da F06**: confira se a F06 já grava `lugar` e
   `t_musica` sozinha em toda linha
   (`grep -n "t_musica\|lugar" nativo/nucleo/linha_tempo.c`). Se grava, tire
   esses dois campos de `registrar_toque` (chave repetida quebra o JSON).

## Armadilhas

- **O float nas bordas** (medido, ver "O estado de hoje"): nunca compare
  `t_toque - t_alvo` cru com `0.060`. Use `desvio_ms` e `_ms`.
- **`NAN` e `INF` não entram no registro**: o C escreveria `nan` e a linha
  deixa de ser JSON. Por isso `registrar_toque` testa `is_nan` e não
  manda `desvio_ms`.
- **Nenhum caminho de prova**: o julgamento não sabe de robô, de
  `--headless` nem de `--fixed-fps`. A prova testa `julgar` com números,
  como qualquer toque (regra 2 da [paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)).
- **O toque tem a resolução do quadro.** A entrada vem do módulo uma vez por
  quadro; quem chama `julgar` passa `Ritmo.t_musica()` do quadro em que
  `Forja.apertou()` deu true. A 60 quadros, o toque chega de 0 a 16,7 ms
  depois de verdade; a parte constante disso sai na calibração (H03). Não
  tente corrigir aqui (ver "Não fazer").
- **A ajuda é do minigame, não do lugar para sempre**: `zerar_ajuda()` no
  começo de cada minigame (o kit chama). E `simples` só vale para quem lê:
  o minigame decide o que é "a partitura mais simples".
- **A folga é só para perigo físico** (a pedra que cai, o portão): quem
  decide que a nota é perigo é quem chama (`folga_para` só diz quanto).
- **O lugar desconectado e o treino**: `folga_para` só olha os `presentes`
  que o chamador passa; o kit (H04) passa quem está jogando. O treino julga
  igual (o toque do treino também é um toque honesto) — quem não soma ponto
  é o `marcar()` da `SalaJogo`.
- **A pausa**: não afeta o julgamento; o `Ritmo` já para o tempo (H01).

## Não fazer

- Não mudar as janelas nem a ordem do enum (valem para os 45 minigames).
- Não usar o carimbo de tempo do SDL para o toque: seria uma função nova no
  módulo (proposta no 13, fora desta ficha).
- Não mexer em sala nenhuma; o julgamento entra nos minigames pelo kit (H04).
- Não somar pontos aqui.

## Pronto quando

As bordas das janelas (−40/+60, ±90, ±140, com e sem folga, com e sem
desvio) julgam como a tabela do 04, a ajuda liga em três erros e desliga em
quatro acertos, e o registro tem a linha `toque` com o julgamento — tudo na
prova do jogo verde. (Os quatro julgamentos de uma rodada de robôs saem na
H04, com o minigame de prova do kit.)

## Provas

**Na sessão:**

```bash
bash tests/prova_do_jogo.sh
```

As checagens novas em `godot/testes/prova_do_jogo.gd`:

```gdscript
## As janelas (H02): as bordas de cada julgamento, a folga de quem está
## atrás, o desvio do lugar e a partitura mais simples. Pura: sem sala.
func _prova_das_janelas() -> void:
	var guardado: Array = Ritmo.desvio.duplicate()
	Ritmo.desvio = [0.0, 0.0, 0.0, 0.0]
	var P := Ritmo.PERFEITO
	var O := Ritmo.OTIMO
	var B := Ritmo.BOM
	var E := Ritmo.ERRO
	# [desvio do toque em s, folga, julgamento esperado]; o alvo em 10 s (o float de verdade)
	var casos := [
		[0.0, 0.0, P], [-0.040, 0.0, P], [0.060, 0.0, P],
		[-0.041, 0.0, O], [0.061, 0.0, O], [-0.090, 0.0, O], [0.090, 0.0, O],
		[-0.091, 0.0, B], [0.091, 0.0, B], [-0.140, 0.0, B], [0.140, 0.0, B],
		[-0.141, 0.0, E], [0.141, 0.0, E], [0.500, 0.0, E],
		[0.170, 0.040, B], [-0.180, 0.040, B], [0.181, 0.040, E],
		[0.061, 0.040, O], [0.041, 0.040, P],
	]
	for c in casos:
		var j := Ritmo.julgar(0, 10.0 + float(c[0]), 10.0, float(c[1]))
		_esperar(j == int(c[2]), "janela: %+.0f ms (folga %.0f) → %s (deu %s)" % [
			float(c[0]) * 1000.0, float(c[1]) * 1000.0, Ritmo.NOMES_DO_JULGAMENTO[int(c[2])], Ritmo.NOMES_DO_JULGAMENTO[j]])
	# o desvio do lugar sai do toque: +80 ms de calibração, 80 ms atrasado é perfeito
	Ritmo.desvio[2] = 0.080
	_esperar(Ritmo.julgar(2, 10.080, 10.0) == P, "janela: com +80 ms de desvio, 80 ms atrasado é perfeito")
	_esperar(Ritmo.julgar(2, 10.0, 10.0) == O, "janela: com +80 ms de desvio, o toque em cima é −80 ms (ótimo)")
	_esperar(Ritmo.julgar(1, 10.080, 10.0) == O, "janela: o desvio de um lugar não mexe no outro")
	_esperar(is_equal_approx(Ritmo.desvio_ms(2, 10.1, 10.0), 20.0), "janela: o desvio_ms já vem corrigido")
	# a folga de quem está atrás: só o último, sozinho
	_esperar(Ritmo.folga_para(3, [30, 20, 10, 0], [0, 1, 2, 3]) == Ritmo.FOLGA_DO_ULTIMO, "ajuda: o último sozinho ganha a folga")
	_esperar(Ritmo.folga_para(2, [30, 20, 10, 0], [0, 1, 2, 3]) == 0.0, "ajuda: o penúltimo não")
	_esperar(Ritmo.folga_para(3, [30, 0, 10, 0], [0, 1, 2, 3]) == 0.0, "ajuda: empate em último não")
	_esperar(Ritmo.folga_para(2, [30, 20, 10, 0], [0, 1, 2]) == Ritmo.FOLGA_DO_ULTIMO, "ajuda: só conta quem está presente")
	_esperar(Ritmo.folga_para(0, [0, 0, 0, 0], [0]) == 0.0, "ajuda: sozinho na sala, ninguém está atrás")
	# a partitura mais simples: três erros ligam, quatro acertos desligam
	Ritmo.zerar_ajuda()
	for k in 2:
		Ritmo.contar_para_ajuda(1, E)
	_esperar(not Ritmo.simples[1], "ajuda: dois erros ainda não simplificam")
	Ritmo.contar_para_ajuda(1, E)
	_esperar(Ritmo.simples[1] and not Ritmo.simples[0], "ajuda: o terceiro erro seguido simplifica só aquele lugar")
	for k in 3:
		Ritmo.contar_para_ajuda(1, B)
	_esperar(Ritmo.simples[1], "ajuda: três acertos ainda não devolvem")
	Ritmo.contar_para_ajuda(1, P)
	_esperar(not Ritmo.simples[1], "ajuda: o quarto acerto seguido devolve a partitura")
	Ritmo.zerar_ajuda()
	# o registro: um toque julgado e um perdido (a prova do relatório os procura)
	Ritmo.registrar_toque(0, 900, P, Ritmo.desvio_ms(0, 10.012, 10.0))
	Ritmo.registrar_toque(0, 901, E)
	Ritmo.desvio = guardado
```

Em `_prova_do_relatorio()`, depois de `var arquivos := ...`:

```gdscript
	# o registro v2 do ritmo: os toques da prova das janelas (n 900 e 901)
	var julgado := {}
	var perdido := {}
	var ruins: Array = []
	for f in arquivos:
		if not (f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl")):
			continue
		for linha in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
			var ev = JSON.parse_string(linha)
			if not ev is Dictionary:
				ruins.append(linha.left(80))
			elif ev.get("tipo", "") == "toque":
				if int(ev.get("n", -1)) == 900:
					julgado = ev
				elif int(ev.get("n", -1)) == 901:
					perdido = ev
	_esperar(ruins.is_empty(), "linha do tempo: toda linha é JSON (%d não: %s)" % [ruins.size(), ruins.slice(0, 2)])
	_esperar(julgado.get("julgamento", "") == "perfeito" and absf(float(julgado.get("desvio_ms", 0.0)) - 12.0) < 0.01,
		"registro: o toque julgado, com o desvio (%s)" % [julgado])
	_esperar(perdido.get("julgamento", "") == "erro" and perdido.get("perdida", false) and not perdido.has("desvio_ms"),
		"registro: a nota perdida, sem desvio (%s)" % [perdido])
```

Se a checagem "toda linha é JSON" reprovar numa linha que não é desta ficha,
**não** a desligue: anote a linha na ficha e avise (é um defeito do
registro, provavelmente da F06).

**Com o André, local:** nada nesta ficha (o julgamento se sente na H04).

## Para o André (local)

Nada a rodar. Na H04 ele joga o minigame de prova e diz se o "perfeito" cai
onde a mão acha que acertou.

## Ao terminar

- Marque a H02 como **feito** no [quadro](README.md), com o commit e o gasto
  real.
- Commit sugerido (sem trailer):
  `feat: as janelas de julgamento — perfeito, ótimo, bom e erro no Ritmo, com a ajuda escondida`
