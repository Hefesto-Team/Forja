# H06 — Os jingles

**Sprint:** H · **Tamanho:** P · **Modelo:** Sonnet · **Estimativa:** US$ 1,5 · **Depende de:** F00, F03, H01, H04, H05

## Por quê

Todo fim precisa de som de fim, e todo começo de uma contagem no tempo. O
apito para a música em seco, o resultado tem o seu jingle (vitória, empate,
coop), a virada do placar tem o dela, e o minigame começa com "três, dois,
um, vai" no tempo da faixa.

## Ler antes

- [As telas e os jingles](../04-ritmo-e-audio.md#as-telas-e-os-jingles)
- [Princípio 7: todo minigame fecha](../02-principios.md#7-todo-minigame-fecha)
- [A arquitetura: a tela de resultado](../13-arquitetura.md#a-tela-de-resultado--f03) e [o kit](../13-arquitetura.md#o-kit-do-minigame--h04)

## O estado de hoje

- Os efeitos gravados estão em `godot/assets/sons/` (WAV 48 kHz mono, CC0 da
  Kenney: Impact, Interface, RPG Audio, Digital Audio e **Music Jingles** —
  `godot/assets/LEIA-ME.md:11`). O LEIA-ME não diz quais arquivos vieram de
  qual pacote. Pela duração (medida), os três que parecem jingles são
  `vitoria_sala_0.wav` (1,76 s), `vitoria_sala_1.wav` (1,55 s) e
  `vitoria_noite_0.wav` (1,74 s); os outros têm menos de 1 s: `especial_0`
  (0,47 s), `placar_0` (0,28 s), `transicao_0/1` (0,47/0,44 s), `sobe_0..2`
  (0,21-0,26 s), `pronto_0` (0,85 s), `confirma_0..2`, `tique_0..2`.
  Nenhum tem os 5 a 8 s que o 04 pede para a vitória: são provisórios até
  os `JIN_*` próprios.
- `godot/scripts/som.gd`: `RECEITAS` (sintetizados pelo módulo,
  `som.gd:17-35`), `GRAVADOS` (o nome da sala → a gravação, `som.gd:38-45`),
  `versoes(gravacao)`, `stream(nome)`, `tocar(nome, pos, volume_db, tom)`.
  O `tocar` sem posição usa quatro tocadores 2D e **desiste** se os quatro
  estiverem ocupados (`som.gd:127-133`): um jingle pode não tocar.
- O fim de hoje: `godot/scripts/salas/sala_jogo.gd:330`,
  `Som.tocar("sucesso")` (a gravação `vitoria_sala`), sem parar a música.
  Com a F03, o fim é a `TelaResultado` (apito, resultado, jingle, volta em
  6 s).
- O começo do jogo: `sala_jogo.gd:292`, `Som.tocar("confirma")` solto, no
  quadro em que todos ficaram prontos.
- A virada: `godot/scripts/ui/placar.gd:98`,
  `Som.tocar("placar" if _virada else "confirma")`.
- O kit (H04): `Minigame.comecar()` chama `Ritmo.tocar(...)` e depois o
  `comecar()` da `SalaJogo`.
- **Provado nesta preparação**, numa cópia do projeto com a H01 a H04 (sem
  a F03: o fim pelo `terminar()` da `SalaJogo`): o código de "O alvo" deixa
  a prova do jogo verde, com o apito parando a música nas nove salas e no
  minigame do kit, e os oito jingles com som.

## O alvo

(**Novo** no 13: `Som.jingle(nome) -> float`, `Som.JINGLES`,
`Som.jingle_do_resultado(pontos, presentes, coop, coop_venceu)`,
`Musica.parar_seco()`, `Minigame.BATIDA_DA_PRIMEIRA_NOTA` e a contagem de
entrada; na seção do resultado, "o apito é `Musica.parar_seco()` +
`Som.jingle("JIN_APITO")`".)

**`godot/scripts/som.gd`** — em `RECEITAS`, os três que faltam:

```gdscript
	# os jingles que ainda não têm arquivo (H06)
	"apito": ["tom", {"freq": 2093.0, "dur": 0.45, "rampa": 0.02}],
	"derrota": ["acorde", {"freqs": [392.0, 311.13, 261.63], "espaco": 0.22, "dur_nota": 0.7}],
	"empate": ["acorde", {"freqs": [523.25, 523.25], "espaco": 0.25, "dur_nota": 0.5}],
```

e, ao fim do arquivo:

```gdscript
# ---------------------------------------------------------------- os jingles (H06) --

## Os jingles (docs/jogo/04-ritmo-e-audio.md#as-telas-e-os-jingles). O arquivo
## próprio em assets/ost/jingles/<nome>.ogg quando existir; enquanto não, uma
## gravação da Kenney de assets/sons/ ou a síntese que faz as vezes.
## nome -> ["gravado", a gravação] ou ["sintese", a receita]
const JINGLES := {
	"JIN_APITO": ["sintese", "apito"],
	"JIN_VITORIA": ["gravado", "vitoria_sala"],
	"JIN_COOP_VITORIA": ["gravado", "vitoria_noite"],
	"JIN_DERROTA": ["sintese", "derrota"],
	"JIN_EMPATE": ["sintese", "empate"],
	"JIN_RECORDE": ["gravado", "especial"],
	"JIN_ENTRADA": ["gravado", "tique"],
	"JIN_VIRADA": ["gravado", "placar"],
}

var ultimo_jingle := ""  ## o último que tocou (a prova olha)
var _jingle: AudioStreamPlayer = null


## Toca o jingle na TV, num tocador só dele (nunca fica sem voz), e devolve a
## duração em s (0: não há som para ele).
func jingle(nome: String) -> float:
	var s: AudioStream = null
	var proprio := Musica.caminho(nome)   # res://assets/ost/jingles/<nome>.ogg (H05)
	if ResourceLoader.exists(proprio):
		s = load(proprio)
	elif JINGLES.has(nome):
		var de: Array = JINGLES[nome]
		if de[0] == "gravado":
			var lista := versoes(str(de[1]))
			s = lista[0] if not lista.is_empty() else null
		else:
			s = stream(str(de[1]))
	if s == null:
		return 0.0
	if _jingle == null:
		_jingle = AudioStreamPlayer.new()
		add_child(_jingle)
	_jingle.stream = s
	_jingle.play()
	ultimo_jingle = nome
	return s.get_length()


## O jingle do resultado: no coop, todos venceram ou ninguém; senão, o empate
## em primeiro ou a vitória. Pura, para a prova.
static func jingle_do_resultado(pontos: Array, presentes: Array, coop: bool, coop_venceu: bool) -> String:
	if coop:
		return "JIN_COOP_VITORIA" if coop_venceu else "JIN_DERROTA"
	var melhor := -1
	var no_topo := 0
	for l in presentes:
		if int(pontos[l]) > melhor:
			melhor = int(pontos[l])
			no_topo = 1
		elif int(pontos[l]) == melhor:
			no_topo += 1
	return "JIN_EMPATE" if presentes.size() >= 2 and no_topo >= 2 else "JIN_VITORIA"
```

**`godot/scripts/musica.gd`** — ao fim:

```gdscript
## A música para em seco (o apito): a zero em 20 ms — nunca de uma vez (as
## rampas do 04) —, e o próximo tocar() começa de novo.
func parar_seco() -> void:
	if _tw:
		_tw.kill()
	var p := _tocadores[_ativo]
	_tocadores[1 - _ativo].stop()
	_tw = create_tween()
	_tw.tween_property(p, "volume_db", -80.0, 0.02)
	_tw.tween_callback(p.stop)
	atual = ""
```

**`godot/scripts/minigames/minigame.gd`** — ao fim (e, no começo do
`sair()`, `if Ritmo.batida_cheia.is_connected(_contar_a_entrada): Ritmo.batida_cheia.disconnect(_contar_a_entrada)`):

```gdscript
## A primeira nota de um minigame vem neste tempo ou depois: os quatro
## primeiros são a contagem de entrada (JIN_ENTRADA, H06).
const BATIDA_DA_PRIMEIRA_NOTA := 4


## A contagem de entrada no tempo da faixa: tique nos tempos 0, 1 e 2 e o
## "vai" no 3 (no lugar do "confirma" solto da SalaJogo).
func _som_do_comeco() -> void:
	if not Ritmo.batida_cheia.is_connected(_contar_a_entrada):
		Ritmo.batida_cheia.connect(_contar_a_entrada)


func _contar_a_entrada(n: int) -> void:
	if n <= 2:
		Som.jingle("JIN_ENTRADA")
	elif n == 3:
		Som.tocar("confirma")
	if n >= 3 and Ritmo.batida_cheia.is_connected(_contar_a_entrada):
		Ritmo.batida_cheia.disconnect(_contar_a_entrada)
```

## Passos

1. **Prova verde antes** (`bash tests/prova_do_jogo.sh`).
2. **`godot/scripts/som.gd`**: as três receitas e o bloco dos jingles.
3. **`godot/scripts/musica.gd`**: `parar_seco()`.
4. **O começo** — `godot/scripts/salas/sala_jogo.gd:292`: troque
   `Som.tocar("confirma")` por `_som_do_comeco()` e crie na `SalaJogo`:

   ```gdscript
   ## O som do começo do jogo (o Minigame troca pela contagem de entrada, H06).
   func _som_do_comeco() -> void:
   	Som.tocar("confirma")
   ```

   No kit (`minigame.gd`), o bloco de "O alvo" (que sobrescreve
   `_som_do_comeco`) e a desconexão no `sair()`. No minigame de prova
   (`godot/testes/minigame_de_prova.gd`), `const PRIMEIRA := BATIDA_DA_PRIMEIRA_NOTA`.
5. **O fim.** Rode `grep -n "sucesso\|apito\|jingle\|TelaResultado" godot/scripts/salas/sala_jogo.gd godot/scripts/ui/resultado.gd`.
   - Se a F03 deixou pontos para o apito e para o jingle do resultado na
     `TelaResultado`, ponha lá: no apito, `Musica.parar_seco()` e
     `Som.jingle("JIN_APITO")`; no resultado,
     `Som.jingle(Som.jingle_do_resultado(pontos, presentes, coop, coop_venceu))`
     com os valores que a F03 já passa à tela.
   - Se ainda está o `Som.tocar("sucesso")` do `terminar()`
     (`sala_jogo.gd:330`), troque por:

     ```gdscript
     	# o apito: a música para em seco; meio segundo depois, o jingle do resultado
     	Musica.parar_seco()
     	Som.jingle("JIN_APITO")
     	var tw := create_tween()
     	tw.tween_interval(0.5)
     	tw.tween_callback(func() -> void: Som.jingle(Som.jingle_do_resultado(pontos, _presentes_do_fim(), false, false)))
     ```

     com `_presentes_do_fim()` na `SalaJogo` (os lugares com `jogando[l]`),
     e o `coop`/`coop_venceu` da F03 no lugar dos dois `false` se ela os
     criou. O tween é da sala: se a sala sai antes de meio segundo, ele
     morre junto.
6. **A virada** — `godot/scripts/ui/placar.gd:98`: `if _virada: Som.jingle("JIN_VIRADA")`,
   senão `Som.tocar("confirma")`.
7. **`godot/testes/prova_do_jogo.gd`**: `_prova_dos_jingles()` (em "Provas"),
   chamada em `_ready()` logo depois de `_prova_das_janelas()`; e, em
   `_termina_a_sala()`, logo depois da checagem "o robô jogou até o fim", a
   checagem do apito. **(prova)**
8. **O 13** e o **04**: o que está marcado **novo**; no 04, na tabela dos
   jingles, uma coluna "hoje" com o provisório de cada um (a tabela
   `JINGLES`).

## Armadilhas

- **Parada seca não é corte seco**: 20 ms de rampa (o 04, "rampas sempre").
  Nada de `stop()` direto no tocador que está soando.
- **O jingle tem tocador próprio**: pelo `Som.tocar` sem posição ele pode
  não tocar (os quatro 2D ocupados). Não troque o `_jingle` pelo `tocar`.
- **O `Ritmo` e a música parada**: `parar_seco()` para o tocador que o
  `Ritmo` segue; o relógio passa sozinho para o do sistema (H01). O kit já
  chamou `Ritmo.parar()` no `terminar()`.
- **A contagem é no tempo da faixa, não em segundos**: ela escuta
  `Ritmo.batida_cheia`. Sala antiga (fora do kit) não tem `Ritmo`: ela fica
  com o "confirma" de sempre.
- **A primeira nota**: todo minigame põe a primeira nota no tempo
  `BATIDA_DA_PRIMEIRA_NOTA` ou depois (o molde já diz). O que tocar antes
  disso atropela a contagem.
- **Nenhum caminho de prova**: o apito e o jingle tocam igual com e sem
  robô; o `ultimo_jingle` só guarda o nome (a prova lê, o jogo não usa).
- **O recorde** (`JIN_RECORDE`) ainda não tem quem o chame: ninguém guarda
  recorde da noite. Fica na tabela, pronto para a ficha que criar o recorde.
- **Headless**: o som toca no driver `Dummy`; a duração que `jingle()`
  devolve é a do arquivo, não a do que se ouviu.

## Não fazer

- Não baixar pacote de som nem converter arquivo na sessão (os `JIN_*`
  próprios são do André; os provisórios já estão no repositório).
- Não pôr jingle no alto-falante do controle (a agenda do 05 não tem).
- Não mudar a duração da tela de resultado (é da F03).

## Pronto quando

Toda sala e todo minigame param a música em seco no apito e tocam o jingle
do resultado certo (vitória, empate, coop); o minigame do kit começa com a
contagem no tempo da faixa; a virada do placar toca o dela; e a prova do
jogo passa com as checagens novas.

## Provas

**Na sessão:**

```bash
bash tests/prova_do_jogo.sh
```

As checagens novas em `godot/testes/prova_do_jogo.gd`:

```gdscript
## Os jingles (H06): qual toca no resultado, e cada um tem som (com o módulo,
## a síntese e as gravações da Kenney). Pura: não abre sala.
func _prova_dos_jingles() -> void:
	var todos := [0, 1, 2, 3]
	_esperar(Som.jingle_do_resultado([10, 5, 3, 0], todos, false, false) == "JIN_VITORIA", "jingle: um vencedor, a vitória")
	_esperar(Som.jingle_do_resultado([10, 10, 3, 0], todos, false, false) == "JIN_EMPATE", "jingle: empate em primeiro, o empate")
	_esperar(Som.jingle_do_resultado([10, 10, 3, 0], [0, 2], false, false) == "JIN_VITORIA", "jingle: só conta quem jogou")
	_esperar(Som.jingle_do_resultado([0, 0, 0, 0], [0], false, false) == "JIN_VITORIA", "jingle: sozinho, a vitória")
	_esperar(Som.jingle_do_resultado([5, 5, 5, 5], todos, true, true) == "JIN_COOP_VITORIA", "jingle: coop, todos venceram")
	_esperar(Som.jingle_do_resultado([5, 5, 5, 5], todos, true, false) == "JIN_DERROTA", "jingle: coop, ninguém venceu")
	if Forja.modulo:
		for nome in Som.JINGLES:
			_esperar(Som.jingle(nome) > 0.0 and Som.ultimo_jingle == nome, "jingle: %s tem som" % nome)
```

e, em `_termina_a_sala()`, depois de `if not is_instance_valid(sala): return`:

```gdscript
	_esperar(Musica.atual == "" and Som.ultimo_jingle.begins_with("JIN_"), "%s: o apito parou a música em seco (%s)" % [id, Som.ultimo_jingle])
```

(Esta preparação rodou tudo isto numa cópia do projeto: as nove salas e o
minigame de prova saem com "o apito parou a música em seco".)

**Com o André, local:** ver abaixo.

## Para o André (local)

Jogue uma partida de três (`./run-local.sh -- --partida=3`) e ouça: a
contagem antes da Centelha cai no tempo da música; no fim de cada sala a
música para de uma vez com o apito, e vem o jingle; a virada no placar tem
som próprio. Diga o que soou fora do lugar ou alto demais.

## Ao terminar

- Marque a H06 como **feito** no [quadro](README.md), com o commit e o gasto
  real.
- Commit sugerido (sem trailer):
  `feat: os jingles — o apito que para a música, o jingle do resultado e a contagem no tempo`
