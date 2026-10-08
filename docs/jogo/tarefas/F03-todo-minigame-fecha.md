# F03 — Todo minigame fecha

**Sprint:** F · **Tamanho:** M · **Depende de:** F00, F01

## Por quê

Hoje a sala acaba numa tabela (ou, depois da F01, num quadro provisório de
pontos), o relógio "volta a encher" depois do treino e o aviso pode ficar
preso esperando um ✕. Todo fim precisa de apito, resultado com vencedor e
volta sozinha, para todo mundo.

## Ler antes

- [13 — A tela de resultado](../13-arquitetura.md#a-tela-de-resultado--f03)
- [13 — A paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08) (regras 1, 2 e 7)
- [02 — Princípio 7](../02-principios.md#7-todo-minigame-fecha)

## O estado de hoje

**O fim** (`godot/scripts/salas/sala_jogo.gd`):
- `terminar()` (`:317-333`) põe `fase = "fim"`, calcula os vereditos, grava
  o relatório, toca `"sucesso"` e chama `_reagir_ao_veredito()`.
- `_reagir_ao_veredito()` (`:339-354`) faz o boneco de quem teve FALHOU
  balançar a cabeça (`"emote-no"`): o veredito vaza para o jogador.
- `_quadro_fim()` (`:378-386`) espera ✕ e tem o atalho do robô:
  ```gdscript
  	if Forja.robo and t_fase > 3.0:
  		terminou.emit()
  ```
- `ui/painel_sala.gd` `_fim()` (`:356-415`): com a bancada, a tabela de
  veredito; sem ela, o quadro provisório de pontos que a F01 pôs.
- Não há som de apito: `godot/scripts/som.gd:17-35` (`RECEITAS`) tem `"falha"`
  (`["tom", {"freq": 150.0, "dur": 0.22, "rampa": 0.02}]`), `"sucesso"`,
  `"confirma"`… A música para com `Musica.calar()` (`musica.gd:85-86`).
- A colocação existe como conta pura: `Partida.colocacoes(pontos, presentes)`
  (`partida.gd:75`) devolve 1..4 por lugar, com o empate dividindo a de cima.

**O relógio do treino:** `_quadro_treino()` (`:418-430`) devolve o tempo do
treino ao relógio da sala, e a barra do painel (`painel_sala.gd:342`,
`var resta := maxf(0.0, d - float(sala.t_fase))`) volta a encher:

```gdscript
		if duracao > 0.0:
			duracao += t_fase  # o tempo do treino volta para o relógio
```

O fim por tempo é `sala_jogo.gd:220`: `if todos or (duracao > 0.0 and t_fase >= duracao):`.

**O aviso** (`_quadro_aviso()`, `:226-246`) só começa quando todo lugar
conectado apertou ✕ (`n_prontos == presentes`). Lugar sem controle já não
segura (o `continue` de `:231-232`). Não há tempo máximo.

**A bancada** (`salas/bancada.gd:141-176`): quando o experimento acaba,
`acabou = true`; ✕ repete, ○ grava e fecha, e com o robô ela fecha sozinha em
2 s. Ela nunca emite `terminou`.

**A volta:** `main.gd:340-365` `_ao_terminar_a_sala()` leva ao placar (na
partida), à sala seguinte (na Prova de Fogo) ou ao salão.

**A linha do tempo** já recebe `{"sala": id, "evento": "jogo_comecou"}` e
`"jogo_terminou"` (`sala_jogo.gd:291`, `:328`), mas não o tipo `minigame` do 13.

## O alvo

Do [13](../13-arquitetura.md#a-tela-de-resultado--f03), com a regra 7 da
paridade (nenhum argumento de prova encurta o fechamento):

```gdscript
class_name TelaResultado
extends Control
const APITO_S := 0.5
const AVANCA_S := 6.0
var colocacao: Array = []   ## os lugares, do primeiro ao último
var pontos: Array = [0, 0, 0, 0]
var coop := false
var coop_venceu := false
var titulo := ""            ## o nome da sala (o minigame, na H04)
var sala_da_bancada: SalaJogo = null  ## só no Modo bancada: a tabela de veredito embaixo
func abrir(col: Array, pts: Array, eh_coop := false, venceu := false, nome := "") -> void
func fechar() -> void
```

- A sequência é a mesma para todos, robô ou gente: o apito e a música que
  para (0 s); em `APITO_S`, o resultado, o boneco de quem venceu faz
  `"emote-yes"` com faíscas na cor dele e toca o jingle (hoje `"sucesso"`; a
  H06 troca); "Botão ✕ (Continuar)" depois de 0,8 s; a volta sozinha em
  `AVANCA_S`. **Não existe** avanço mais rápido com `--robo`.
- `SalaJogo.vencedor() -> Array` (o gancho do kit, no 13): os lugares que
  jogaram, do maior ponto ao menor; no empate, o lugar menor primeiro. A Prova
  e as salas futuras podem sobrescrever.
- O treino tem o seu relógio: `SalaJogo.t_jogo` conta só o tempo que vale, e a
  barra do painel usa `t_jogo`. O `duracao` nunca muda depois de `entrar`.
- O aviso começa sozinho em `AVISO_MAX := 8.0` s, ou antes se todos os
  conectados apertarem ✕.
- A bancada emite `terminou` uma vez, quando o experimento acaba.
- A linha do tempo ganha o tipo `minigame` (13, o registro v2):
  `{"slot": id, "evento": "comecou"}` e
  `{"slot": id, "evento": "terminou", "vencedor": <lugar 0..3>, "pontos": [...], "duracao": <s>}`
  (`itens` entra com a G03).

## Passos

1. **`godot/scripts/som.gd`**, em `RECEITAS` (`:17-35`):
   `"apito": ["tom", {"freq": 2400.0, "dur": 0.45, "rampa": 0.01}],`.
2. **`godot/scripts/ui/resultado.gd`** (novo, `class_name TelaResultado`), com
   a API do alvo. `_draw()`: fundo `Color(Tema.CASA, 0.6)`; um quadro central
   de 900 px com `titulo` no alto (`Tema.fonte(700)`, 52); a frase do vencedor
   (`"P%d venceu!" % (colocacao[0] + 1)`, ou `"P%d e P%d empatam!"` quando os
   dois primeiros têm os mesmos pontos) na cor do lugar
   (`Tema.tom_para_a_borda(Forja.cor_do_lugar(l))`); uma linha por lugar de
   `colocacao`, com a colocação de `Partida.colocacoes(pontos, colocacao)`
   (`"%dº"`), `"P%d"` na cor do lugar e os pontos em `Tema.mono(500)`; a
   primeira linha maior. Com `t >= 0.8`,
   `Desenho.dicas_a_direita(self, <canto do quadro>, [["cruz", "continuar"]], Tema.T_ROTULO)`.
   Com `sala_da_bancada != null`, a tabela de veredito **abaixo** do quadro
   (passo 3). Rodar `"$GODOT" --headless --path godot --import --quit` e
   commitar o `resultado.gd.uid`.
3. **A tabela vai junto:** mover o corpo de `painel_sala.gd` `_fim()` (a parte
   da bancada) e `_veredito_de()` (`:418-422`) para `resultado.gd`, como
   `func _tabela(r: Rect2) -> void` desenhada a partir de `sala_da_bancada`.
   `painel_sala.gd` `_fim()` fica vazia (o painel não desenha nada no fim) e
   `_nome_da_feature` vai junto para `resultado.gd`.
4. **`godot/scripts/main.gd`**:
   - `_interface()` (`:117-148`): `var resultado: TelaResultado`, criado e
     posto na lista de `:135`, `resultado.visible = false`.
   - `_quadro_sala()` (`:707-708`), antes do `_atalhos_de_overlay()`:
     ```gdscript
     	if sala is SalaJogo and (sala as SalaJogo).fase == "fim" and not resultado.visible and overlay == "":
     		var sj := sala as SalaJogo
     		resultado.abrir(sj.colocacao, sj.pontos, sj.coop, sj.coop_venceu, sj.nome)
     		resultado.sala_da_bancada = sj if Forja.bancada else null
     ```
   - `_sair_da_sala()` (`:522`) e `_abrir_overlay()` (`:729`): `resultado.fechar()`.
     (Fechando a pausa no meio do fim, o `_quadro_sala` reabre.)
   - `_ao_terminar_a_sala()` (`:340`), depois da guarda:
     `if sala_id == "bancada": return` (a bancada fica no painel dela: ✕ repete, ○ fecha).
5. **`godot/scripts/salas/sala_jogo.gd`**:
   - Variáveis novas: `var colocacao: Array = []`, `var coop := false`,
     `var coop_venceu := false`, `var t_jogo := 0.0  ## o tempo que vale (o treino fora)`,
     `const AVISO_MAX := 8.0`.
   - `func vencedor() -> Array`: os `l` com `jogando[l]`, ordenados por
     `pontos` decrescente e, no empate, pelo lugar.
   - `_process` (`:210-221`): `if not treinando: t_jogo += dt` antes de
     `jogar(dt)`; o fim por tempo passa a ser `duracao > 0.0 and t_jogo >= duracao`.
   - `_quadro_treino()`: apagar as duas linhas de `:426-427` (`duracao += t_fase`).
   - `_quadro_aviso()` (`:245`):
     `if presentes > 0 and (n_prontos == presentes or t_fase >= AVISO_MAX) and t_fase > 0.9:`.
   - `comecar()` (`:282`): `t_jogo = 0.0` e
     `Forja.evento("minigame", 0, {"slot": id, "evento": "comecou"})`.
   - `terminar()` (`:317`): no lugar de `Som.tocar("sucesso")` e
     `_reagir_ao_veredito()`: `colocacao = vencedor()`; `Musica.calar()`;
     `Som.tocar("apito")`; e
     `Forja.evento("minigame", 0, {"slot": id, "evento": "terminou", "vencedor": colocacao[0] if not colocacao.is_empty() else -1, "pontos": pontos, "duracao": snappedf(t_jogo, 0.1)})`.
     O resto (vereditos, `gravar_relatorio`, `pulso_de_luz`, `ao_terminar`) fica.
   - Trocar `_reagir_ao_veredito()` por `func _celebrar() -> void`: o boneco
     de `colocacao[0]` faz `gesto("emote-yes", 1.4)` e ganha
     `Efeitos.faiscas(self, p.global_position + Vector3(0, 2.2, 0), Forja.cor_do_lugar(l), 40, 1.3)`;
     `Som.tocar("sucesso")`. Ninguém balança a cabeça por veredito.
   - `_quadro_fim()` (`:378-386`):
     ```gdscript
     func _quadro_fim() -> void:
     	if t_fase >= TelaResultado.APITO_S and not _celebrou:
     		_celebrou = true
     		_celebrar()
     	if t_fase >= TelaResultado.AVANCA_S:
     		terminou.emit()
     		return
     	if t_fase < 0.8:
     		return
     	for p in jogadores:
     		if Forja.apertou(p.lugar, Forja.CRUZ):
     			terminou.emit()
     			return
     ```
     (`var _celebrou := false`, zerado em `terminar()`.) O atalho do robô de
     `:385-386` sai: o robô, como todo mundo, espera os seis segundos.
6. **`ui/painel_sala.gd`** `_tempo()` (`:342`): `d - float(sala.t_jogo)`; e,
   enquanto `sala.treinando`, não desenhar a barra (o selo do treino já está
   lá, `:426-433`). No `_aviso()`, embaixo dos chips dos lugares, um trilho de
   8 px que esvazia em `SalaJogo.AVISO_MAX` (`draw_rect` com `Tema.TRILHO` e
   `Tema.ROXO`), sem texto.
7. **`salas/bancada.gd`** `_process` (`:173-176`): quando `fim` vira `acabou`,
   `terminou.emit()` (uma vez só, logo depois de `acabou = true`).
8. **A prova**: as checagens de "Provas".

## Armadilhas

- **Nada de atalho do robô** (13, paridade, regras 1, 2 e 7). Não ponha
  `if Forja.robo` em lugar nenhum desta ficha, nem um avanço de 3 s "para a
  prova". O atalho do aviso (`sala_jogo.gd:237`) é da F08: não mexa.
- **Os tempos da prova crescem.** Cada sala agora gasta 6 s de jogo no fim. As
  esperas de `godot/testes/prova_do_jogo.gd` estão em quadros: `_termina_a_sala`
  espera a volta ao salão até 600 quadros (`:328-330`, 10 s) — cabe; a
  partida espera o placar até 600 (`:511-513`) — cabe; não diminua nenhuma.
  O `timeout 1200` do `tests/prova_do_jogo.sh` sobra.
- **A partida:** o placar (`main.gd:395-406`) abre por cima depois do
  `terminou`; o `resultado.fechar()` de `_abrir_overlay` tira a tela de
  resultado da frente.
- **A pausa no fim:** `congelar()` (`sala_jogo.gd:189-199`) para o `t_fase`;
  ao fechar, o `_quadro_sala` reabre o resultado.
- **`vencedor()` com ninguém jogando** (a sala terminou antes do jogo):
  `colocacao` vazia; a `TelaResultado` desenha só o título, e o evento grava
  `"vencedor": -1`.
- **Arrays na linha do tempo:** o `Forja.evento` de hoje grava um `Array`
  como texto (`"[10, 40, 30, 20]"`, `forja_controles.cpp:501-503`). A F06
  faz virar array de verdade; aqui, aceite o texto.
- **`--prova-de-fogo`** liga a bancada (F01): a tabela aparece embaixo do
  resultado nessa rodada. É o esperado.
- **`.uid`** do `resultado.gd`: importe e commite.

## Não fazer

- Não criar o jingle de cada seção (H06) nem o placar novo.
- Não tirar os outros atalhos do robô (F08).
- Não mexer no texto de botão além de `"continuar"` (a F07 vira tudo para "Botão ✕ (Continuar)").

## Pronto quando

Com `--simular=4 --robo` (e também com `--prova-de-fogo`), toda sala termina
sozinha, mostra quem venceu e a colocação dos quatro, volta sozinha em 6 s, o
relógio nunca sobe e a linha do tempo tem um `minigame` `comecou` e um
`terminou` por sala.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` (as duas rodadas: sem e com `--bancada`).

Em `godot/testes/prova_do_jogo.gd`: em `_comeca_a_sala(id)`, depois de pegar
a sala, guardar o relógio e ligar o sinal:

```gdscript
	var fim := [-1.0]  # o t_fase da sala quando ela emitiu terminou
	sala.terminou.connect(func() -> void: fim[0] = float(sala.t_fase))
	sala.set_meta("fim", fim)
	sala.set_meta("duracao_no_inicio", float(sala.duracao))
```

Em `_termina_a_sala(sala, features)`, no laço de espera pelo fim, acompanhar a
barra; e, quando a fase vira `"fim"`, conferir o resultado e contar quanto o
fim dura:

```gdscript
	var resta_antes := INF
	var subiu := false
	# (dentro do laço que espera sala.fase == "fim")
		if sala.duracao > 0.0 and not sala.treinando:
			var resta: float = sala.duracao - sala.t_jogo
			subiu = subiu or resta > resta_antes + 0.01
			resta_antes = resta
	# (depois do laço)
	_esperar(not subiu and is_equal_approx(float(sala.duracao), float(sala.get_meta("duracao_no_inicio"))),
		"%s: o relógio nunca volta a encher" % id)
	await _quadros(40)
	var col: Array = jogo.resultado.colocacao
	var melhor := -1
	for l in 4:
		melhor = maxi(melhor, int(sala.pontos[l]))
	_esperar(jogo.resultado.visible and col.size() == 4 and int(sala.pontos[col[0]]) == melhor,
		"%s: o resultado mostra quem venceu (P%d) e os quatro" % [id, int(col[0]) + 1 if not col.is_empty() else 0])
	var fim: Array = sala.get_meta("fim")
	q = 0
	while fim[0] < 0.0 and q < 900:
		await _quadros(1)
		q += 1
	_esperar(fim[0] >= TelaResultado.AVANCA_S - 0.05 and fim[0] <= TelaResultado.AVANCA_S + 0.1,
		"%s: o fim avança sozinho em 6 s, robô ou não (%.2f s)" % [id, fim[0]])
```

(Pegue `fim` com `sala.get_meta` **antes** de esperar: depois do `terminou`,
a sala sai da árvore e é liberada. O `q` é o contador que a função já tem.)

O aviso que começa sozinho, numa função nova chamada depois de `_prova_do_percurso()`:

```gdscript
## O aviso não espera ninguém para sempre: sem ✕ de ninguém, começa em 8 s.
func _prova_do_aviso_sozinho() -> void:
	jogo._entrar_na_sala("centelha", false)
	await _quadros(2)
	var sala = jogo.sala
	# segura o ✕ do robô: nenhum lugar fica pronto no aviso
	var robo := Forja.robo
	Forja.robo = false
	var q := 0
	while is_instance_valid(sala) and sala.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	Forja.robo = robo
	_esperar(is_instance_valid(sala) and sala.fase == "jogo" and q >= int(SalaJogo.AVISO_MAX * 60) - 2,
		"o aviso começa sozinho em 8 s (%d quadros)" % q)
	sala.terminar()
	q = 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
```

(Desligar o `Forja.robo` aqui é da prova, não do jogo: é o jeito de ter "ninguém
apertou" enquanto a F08 não troca o atalho do aviso por ✕ no controle
simulado. Quando a F08 entrar, troque por não apertar nada.)

A linha do tempo, na função `_prova_do_modo()` da F01 (ou numa nova, no fim):

```gdscript
	var mg := _linha_do_tempo().filter(func(e): return e.get("tipo") == "minigame")
	for id in ["centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]:
		var c := mg.filter(func(e): return e.get("slot") == id and e.get("evento") == "comecou").size()
		var t := mg.filter(func(e): return e.get("slot") == id and e.get("evento") == "terminou" and int(e.get("vencedor", -1)) >= 0).size()
		_esperar(c >= 1 and t >= 1, "linha do tempo: %s começou e terminou com vencedor" % id)
```

## Para o André (local)

- `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` (ficam mais longos: seis segundos por sala).
- `./run-local.sh -- --partida=3`: em cada sala, o apito, a música que para,
  quem venceu pulando com faíscas, e a volta sozinha; Botão ✕ pula.
- `./run-local.sh -- --sala=centelha`: o relógio não volta a encher depois do
  "Valendo!"; deixe um controle parado no aviso e veja a sala começar em 8 s.

## Ao terminar

- No [quadro](README.md), a linha da F03: estado **feito** (com o commit).
- Commit sugerido: `feat: todo minigame fecha — apito, vencedor e a volta sozinha em 6 s`

## O que foi feito (leva 1, a-fundacao)

- Entrou o apito (`som.gd`) e a `TelaResultado` (`ui/resultado.gd`): nome da
  sala, quem venceu numa frase («P4 venceu!», «P1 e P2 empatam!», «Empate!»
  quando três ou mais dividem o topo; coop: «Vocês venceram!» / «Não deu desta
  vez.»), a colocação de quem jogou com os pontos, «Continuar» depois de 0,8 s.
  Com `--bancada`, a tabela de veredito vem embaixo do quadro (o corpo do
  antigo `_fim` do painel, movido). O painel não desenha mais nada no fim.
- `SalaJogo`: `vencedor()`, `colocacao`, `coop`, `coop_venceu`, `t_jogo` (o
  relógio só corre fora do treino; o `duracao` não muda mais depois de
  `entrar`), `AVISO_MAX` de 8 s (o aviso começa sozinho; a barra do painel tem
  um trilho que esvazia sem texto), `_celebrar()` no lugar de
  `_reagir_ao_veredito()` (só quem venceu pula, com faíscas; ninguém balança a
  cabeça), e a volta sozinha em 6 s, igual para robô e para gente. O atalho do
  robô de 3 s no fim saiu; o do aviso (F08) ficou.
- A bancada de experimentos emite `terminou` e o `main.gd` o ignora para ela
  (✕ repete, ○ fecha). A linha do tempo ganhou `minigame` (`comecou` e
  `terminou` com vencedor, pontos e duração; os pontos saem como texto até a F06).
- A prova do jogo ganhou, por sala: o relógio nunca volta a encher, o resultado
  mostra o vencedor e os quatro, o fim avança em 6 s; o aviso sozinho em 8 s
  (480 quadros); e, na linha do tempo, um `comecou` e um `terminou` por sala.
- Mordidas: devolver `duracao += t_fase`, o atalho do robô de 3 s e a espera
  sem `AVISO_MAX` reprovaram 13 linhas (relógio, 3,02 s no lugar de 6, aviso
  sozinho); devolvidos, a prova passa nas duas rodadas (`prova_do_jogo.sh` rc=0).
  O quadro foi visto em foto (`captura_jogo`, sala Centelha), com e sem bancada.
- Dois detalhes: o botão usa a chave que já existia, «Continuar» (a F07
  acerta o formato); `seguir` (o texto do ✕ do veredito) ficou como variável
  sem uso, para a limpeza da F08.
- Para a mão dela ou do André: `./run-local.sh -- --partida=3` (o apito, a
  música que para, o vencedor pulando com faíscas, a volta sozinha em 6 s, o ✕
  que pula), `./run-local.sh -- --sala=centelha` (o relógio não volta a encher
  depois do «Valendo!»; um controle parado no aviso e a sala começa em 8 s),
  `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` (seis segundos a mais
  por sala).
