# F01 — O Modo bancada

**Sprint:** F · **Tamanho:** G · **Estimativa:** US$ 3,5 · **Depende de:** F00

## Por quê

A pergunta às cegas, a tabela de veredito, o diagnóstico e o livro da sessão
são ferramentas de validação e hoje aparecem na cara do jogador. Elas passam a
existir só no Modo bancada (`--bancada`). O jogo de base fica sem nenhuma
dessas camadas.

## Ler antes

- [13 — O Modo bancada](../13-arquitetura.md#o-modo-bancada--f01)
- [13 — A paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08) (regras 1, 3 e 5)
- [As regras de ouro](../README.md#as-regras-de-ouro) (1 e 5)

## O estado de hoje

**Os argumentos.** `godot/scripts/forja.gd:144-160` (`_ler_args`) lê
`--experimento` e `--sala`, mas não conhece `--bancada`. `--prova-de-fogo` é
lido em `main.gd:167`, e `main.gd:168` tem uma variável local com o nome que
vai confundir:

```gdscript
var pede_o_fogo := "--prova-de-fogo" in OS.get_cmdline_user_args()
var bancada := Forja.experimento != ""
```

**O diagnóstico e o livro** abrem sempre:
- `main.gd:715-726` `_atalhos_de_overlay()`: Create abre `"diagnostico"`.
- `main.gd:729-763` `_abrir_overlay(qual, lugar)`: abre qualquer overlay.
- `main.gd:361-363`: no fim da Prova de Fogo, abre o `"livro"` sozinho.
- `ui/pausa.gd:17-28` `abrir()` sempre põe `["livro", "O livro da sessão"]` e,
  com `com_diagnostico`, `["diagnostico", "Diagnóstico"]`.
- `ui/hud.gd:87`: `var pares := [["create", "diagnóstico"], ["options", "pausa"]] if create_livre else [["options", "pausa"]]`.

**A tabela de veredito:** `ui/painel_sala.gd:356-415` (`_fim()`) desenha
✓ PASSOU / ✗ FALHOU / — NÃO MEDIDO por feature e por lugar.

**As perguntas às cegas** são estados da própria sala, e o painel as desenha
por `sala.pergunta(l)` (`painel_sala.gd:151-168`, `_dicas()`). Onde cada sala
entra na pergunta:

| sala | a entrada na pergunta | o que vem depois |
| --- | --- | --- |
| Galeria | `galeria.gd:222` `_nova_rodada`: `e.passo = IDENTIFICAR` (que arma é?); `galeria.gd:266` e `:327` chamam `_perguntar_municao(l)` (quantas luzinhas?) | `_responder_arma` (`:424`) abre o baú → `REVELANDO` → `ATIRAR`; `MUNICAO_RESP` → `_proxima_rodada` |
| Impacto | `impacto.gd:388-397`, no estado `PAUSA`: `_iniciar_pergunta()` no fim de cada onda e `elif _precisa_mais_cor(): _iniciar_pergunta()` (de que cor está a luz?) | `RESPOSTA` → `PAUSA` |
| Canto | `canto.gd:406-408`: `estado = PERGUNTA` (o canto saiu do seu controle?) | `_fechar_pergunta()` (`:314`) → `REVELA` → `REPETE` |
| Caminhos | `caminhos.gd:360-363`: `e.estado = PERGUNTA` (que chão é esse?) | `_fechar_pergunta(l, e)` (`:283`) veste o ladrilho → `REVELA` |
| Voz | `voz.gd:421-423`: `SUSSURRO` → `_comecar_luz()` (como está a luz do microfone?) | `LUZ` → `ESPERA` → `SUSTO` |
| Prova | `prova.gd:653-654`: fim da `PARTIDA` → `_perguntar_leds()`; `:656-657` → `_perguntar_cor()` | `COR` → `PLACAR` (`:658-664`) |

O escudo do Impacto (L1/R1) e o tropeço dos Caminhos (L1/R1) **não** são
pergunta: são reflexo com consequência no mundo, e ficam nos dois modos.

**Os vereditos sem resposta** já saem "não medido" pelo núcleo: `cegas.c`
devolve `RES_NAO_MEDIDO` quando o `Cega` está vazio
(`cega_arma_veredito`: "nenhuma rodada desta arma respondida";
`cega_tudo_junto_veredito`: "a prova final ficou sem resposta"). Nada muda em C.

**A prova.** `tests/prova_do_jogo.sh:54-66` roda a mesma cena duas vezes
(servidor de som "forma-a" e "antes"), as duas com
`-- --simular=4 --robo --semente=7 --relatorios=...`. `godot/testes/prova_do_jogo.gd`
espera PASSOU em toda feature de toda sala (`_termina_a_sala`, `:305-335`),
abre o diagnóstico com Create (`:107-110`) e o livro (`:272-275`). O
`scripts/gauntlet.sh:35-36` e o `tests/prova_de_poucos.sh:34-35` rodam sem
argumento de modo e dependem dos vereditos das perguntas.

## O alvo

Do [13](../13-arquitetura.md#o-modo-bancada--f01): `Forja.bancada: bool`,
ligado por `--bancada`, `--experimento=` ou `--prova-de-fogo`.

```gdscript
if Forja.bancada:
	# pergunta às cegas, tabela de veredito, diagnóstico (Create), livro (pausa)
```

- Sem a bancada, a sala **pula** o estado de pergunta e segue para o que vem
  depois da resposta; a pergunta não é desenhada nem registrada.
- Com a bancada, tudo como hoje. A bancada **acrescenta** a camada de
  pergunta, e nunca muda regra, tempo ou tela do jogo por baixo (13, paridade,
  regra 3).
- Os vereditos continuam sendo **calculados e gravados** nos dois modos.
  Sem a bancada, as features que só a pergunta mede saem "não medido".
- A linha do tempo diz o modo (`sessao`, `"evento": "modo"`) e marca cada
  pergunta aberta (`"o": "pergunta"`), para a prova conferir pelo registro.

## Passos

1. **`godot/scripts/forja.gd`**, perto de `var experimento` (`:84`):
   `var bancada := false  ## --bancada, --experimento ou --prova-de-fogo: as perguntas, o veredito, o diagnóstico e o livro`.
   No fim de `_ler_args()` (`:160`):
   `bancada = _args.has("bancada") or experimento != "" or _args.has("prova-de-fogo")`.
   Em `_ready()`, logo depois de `semente = ctl.semente()` (`:117`):
   ```gdscript
   evento("sessao", 0, {"evento": "modo", "bancada": bancada})
   registrar("Modo bancada: %s" % ("ligado" if bancada else "desligado"))
   ```
   Acrescentar `--bancada` à lista de argumentos do cabeçalho (`:13-25`).
2. **`godot/scripts/main.gd`**:
   - `:168`: renomear a local `bancada` para `experimento` (e o uso em `:169`
     e `:173`).
   - `_abrir_overlay()` (`:729`), primeira linha:
     `if qual in ["diagnostico", "livro"] and not Forja.bancada: return`.
   - `_atalhos_de_overlay()` (`:716`):
     `var create_livre := Forja.bancada and not (sala is SalaJogo and ...)`.
   - `_abrir_overlay`, a chamada da pausa (`:753`):
     `pausa.abrir(lugar, estado == "sala", _diagnostico_livre(), Forja.bancada)`.
3. **`godot/scripts/ui/pausa.gd:17`**: `abrir(lugar: int, na_sala: bool, com_diagnostico := true, bancada := true)`;
   `["diagnostico", "Diagnóstico"]` entra só com `com_diagnostico and bancada`, e
   `["livro", "O livro da sessão"]` só com `bancada`.
4. **`godot/scripts/ui/hud.gd:87`**: `if create_livre and Forja.bancada` no lugar de `if create_livre`.
5. **`godot/scripts/ui/painel_sala.gd`**:
   - `_dicas()` (`:157-168`): o bloco das perguntas fica dentro de `if Forja.bancada:`.
   - `_fim()` (`:356`): com `Forja.bancada`, a tabela de hoje. Sem a bancada,
     um quadro provisório (a F03 troca pela tela de resultado): o nome da sala,
     uma linha `"P%d  %d" % [l + 1, sala.pontos[l]]` por lugar que jogou, na
     ordem dos pontos, e a dica `[["cruz", str(sala.seguir)]]` depois de 0,8 s.
     Nenhuma palavra de veredito.
6. **As seis salas às cegas.** Em cada entrada da tabela de "O estado de hoje":
   com a bancada, grave `Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "<qual>"})`
   (Canto: `jogador` 0, uma vez por rodada) e siga como hoje; sem a bancada, pule:
   - **Galeria** `_nova_rodada()` (`:219-231`), no fim:
     ```gdscript
     if not Forja.bancada:
     	if e.arma == NENHUMA:
     		_proxima_rodada(l)  # sem pergunta, a rodada sem arma não tem jogo
     		return
     	e.passo = REVELANDO  # o baú abre na hora; REVELANDO leva a ATIRAR
     	e.t = 0.0
     	_abrir_bau(l, e.arma)
     	return
     Forja.evento("jogo", l + 1, {"sala": id, "o": "pergunta", "qual": "arma"})
     ```
     `_perguntar_municao(l)` (`:446`), no começo:
     `if not Forja.bancada: _guardar_arma(l); _gatilho(l, NENHUMA); _proxima_rodada(l); return`.
     O plano das armas não repete a mesma em seguida, então a recursão de
     `_proxima_rodada` → `_nova_rodada` tem fundo.
   - **Impacto** `jogar()`, `PAUSA` (`:388-397`): `onda += 1` fica; o
     `_iniciar_pergunta()` e o `if not _alguem_pergunta()` ficam dentro de
     `if Forja.bancada:`; e `elif Forja.bancada and _precisa_mais_cor():`.
     O evento `pergunta` vai em `_iniciar_pergunta()`, por lugar com `cor_pedida >= 0` (`qual` = `"cor"`).
   - **Canto**: tire de `_fechar_pergunta()` (`:314`) a parte depois do laço
     (`estado = REVELA` até as faíscas) para uma `func _revelar() -> void`, e
     chame-a no fim de `_fechar_pergunta()`. Em `:406-408`:
     `if Forja.bancada: estado = PERGUNTA; t_estado = 0.0 (e o evento, qual "canto") else: _revelar()`.
   - **Caminhos**: tire de `_fechar_pergunta(l, e)` (`:283`) o
     `_vestir_ladrilho(...)`, `e.estado = REVELA` e `e.t = 0.0` para uma
     `func _revelar_trecho(l: int, e: Dictionary) -> void`. Em `:360-363`:
     sem a bancada, `_revelar_trecho(l, e)` no lugar de `e.estado = PERGUNTA` (`qual` = `"chao"`).
   - **Voz** `:421-423`: `if Forja.bancada: _comecar_luz() else: estado = ESPERA; t_estado = 0.0`.
     O evento vai em `_luz_rodada()` (`:258`), quando `e.fase = OLHAR` (`qual` = `"luz_mic"`).
     E no `MUDO` (`:411`), `Forja.led_mic(l, 1)` passa a
     `if Forja.led_mic(l, 1): e.luz_ok = true`: sem a pergunta, é o único LED
     que a sala manda, e sem isso o `led_microfone` diria "o SDL recusou" em vez
     de "nenhuma resposta".
   - **Prova**: tire de `:658-664` (o fim do `COR`) uma
     `func _ir_para_o_placar() -> void` (`etapa = PLACAR`, `t_etapa = 0.0`, a luz
     do lugar de volta). Em `:653-654`:
     `if Forja.bancada: _perguntar_leds() else: _ir_para_o_placar()`.
     O evento vai em `_perguntar_leds()` e `_perguntar_cor()` (`qual` = `"leds"` / `"cor"`).
7. **`tests/prova_do_jogo.sh`**: `rodar()` passa a aceitar argumentos a mais
   (`local nome=$1 esperado=$2; shift 2`, e `"$@"` no fim da linha do Godot).
   A rodada `forma-a` roda **sem** `--bancada` (o jogo); a rodada `antes`
   roda **com** `--bancada` (a camada de validação). Continua em duas rodadas.
8. **`scripts/gauntlet.sh:36`** e **`tests/prova_de_poucos.sh:35`**: acrescentar
   `--bancada` à linha do Godot. Os dois conferem vereditos das perguntas; são
   provas da bancada.
9. **`godot/testes/prova_do_jogo.gd`**: as checagens de "Provas", abaixo.
10. **Documentar** `--bancada` em `docs/DESENVOLVER.md` (a lista "Os argumentos
    do jogo", `:73-80`), no `docs/COMO-CONTRIBUIR.md` (a linha dos argumentos de
    `./run-local.sh`) e no cabeçalho de `forja.gd`.

## Armadilhas

- **Nada de `Forja.robo` novo.** O robô de cada sala continua respondendo às
  perguntas pelo controle simulado (`Forja.robo_apertar`), dentro do `_robo`
  dela. A F01 não mexe nos atalhos do robô (`sala_jogo.gd:237` e `:385`): isso é a F08.
- **A Galeria sem pergunta** tem de andar sozinha: sem a bancada, conferir que
  `REVELANDO` → `ATIRAR` (`:282-297`) e que a sala acaba (`acabou[l]` em
  `_proxima_rodada`). O desempate (`:477-483`) só acrescenta rodada com
  `Cega.total(...) > 0`, então sem pergunta não acrescenta nada.
- **O Canto nas rodadas da TV:** `REVELA` com `fonte == TV` vai para a próxima
  rodada sem `REPETE` (`:410-415`). Isso não muda.
- **Os Caminhos sem a pergunta do chão** ainda medem o tropeço: o
  `haptica_audio` pode sair PASSOU só pelos lados (`cega_haptica_veredito`).
  É o esperado; não afrouxe a checagem para "não medido".
- **A Prova sem pergunta**: o `tudo_junto` sai "não medido" (sem resposta), a
  não ser que a carga falhe (parada da entrada, saída recusada): aí FALHOU,
  nos dois modos. Está certo.
- **A Prova de Fogo pelo salão** (△ na bigorna, `main.gd:699-702`) não liga a
  bancada: só o argumento `--prova-de-fogo` liga. No fim dela, o livro só abre
  com a bancada (o `_abrir_overlay` recusa).
- **As fotos.** `godot/testes/captura_jogo.gd:79-85` (o roteiro das telas)
  fotografa o diagnóstico e o livro. Sem `--bancada` essas duas fotos não
  saem; o `tests/telas.sh` não usa esse roteiro, então nada quebra. Anote no
  cabeçalho do `captura_jogo.gd`: "o diagnóstico e o livro, só com `-- --bancada`".
- **O CONTRATO não muda.** Nada aqui toca em saída ao controle.

## Não fazer

- Não reescrever as salas às cegas como jogo (é das seções I–Q).
- Não desenhar a tela de resultado (é a F03); o quadro do passo 5 é provisório.
- Não mexer no texto das salas (F02) nem na caixa das letras (F07).
- Não tirar os atalhos do robô (F08).

## Pronto quando

- Sem `--bancada`, com `--simular=4 --robo`, as nove salas vão do aviso ao fim
  sem nenhuma pergunta na tela, sem tabela de veredito, sem diagnóstico e sem
  livro, e a linha do tempo não tem nenhum `"o": "pergunta"`.
- Com `--bancada`, tudo como hoje: cada sala às cegas pergunta, e toda feature
  sai PASSOU.
- `bash tests/prova_do_jogo.sh` passa nas duas rodadas.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` (as duas rodadas).

As checagens novas em `godot/testes/prova_do_jogo.gd`:

```gdscript
## As features que só a pergunta às cegas mede: fora do Modo bancada, «não medido».
const SO_COM_PERGUNTA := {
	"galeria": ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao", "leds_jogador"],
	"impacto": ["lightbar"],
	"canto": ["alto_falante"],
	"voz": ["led_microfone"],
	"prova": ["tudo_junto"],
}


## As linhas da linha do tempo desta sessão, na ordem (as fichas seguintes usam também).
func _linha_do_tempo() -> Array:
	var linhas: Array = []
	if pasta == "":
		return linhas
	for f in DirAccess.get_files_at(pasta):
		if f.begins_with("linha-do-tempo-") and f.ends_with(".jsonl"):
			for s in FileAccess.get_file_as_string(pasta.path_join(f)).split("\n", false):
				var e = JSON.parse_string(s)
				if e is Dictionary:
					linhas.append(e)
	return linhas
```

Em `_prova_do_percurso()`, no lugar de `:107-110`:

```gdscript
	await _aperta(0, Forja.CREATE)
	if Forja.bancada:
		_esperar(jogo.overlay == "diagnostico", "bancada: Create abre o diagnóstico")
		await _aperta(0, Forja.CIRCULO)
		_esperar(jogo.overlay == "", "○ fecha o diagnóstico")
	else:
		_esperar(jogo.overlay == "", "jogo: Create não abre o diagnóstico")
	jogo._abrir_overlay("pausa", 0)
	await _quadros(2)
	var acoes: Array = jogo.pausa.opcoes.map(func(o): return o[0])
	_esperar(("livro" in acoes) == Forja.bancada and ("diagnostico" in acoes) == Forja.bancada,
		"a pausa tem o livro e o diagnóstico só na bancada (%s)" % [acoes])
	jogo._fechar_overlay()
```

No Impacto (`:154-167`), a espera pelo `PERGUNTA` e a checagem da cor ficam
dentro de `if Forja.bancada:`. No fim do percurso (`:272-275`):

```gdscript
	jogo._abrir_overlay("livro", 0)
	await _quadros(2)
	_esperar(jogo.overlay == ("livro" if Forja.bancada else ""), "o livro abre só na bancada")
	if jogo.overlay != "":
		jogo._fechar_overlay()
```

Em `_termina_a_sala(sala, features)`: dentro do laço de espera (`:308-310`),
`if not Forja.bancada: for l in 4: if not sala.pergunta(l).is_empty(): viu_pergunta = true`,
e depois do laço `_esperar(not viu_pergunta, "%s: nenhuma pergunta na tela" % id)`.
Na conferência de cada feature (`:321`):

```gdscript
		var so_pergunta: Array = [] if Forja.bancada else SO_COM_PERGUNTA.get(id, [])
		var esperado := Forja.NAO_MEDIDO if f in so_pergunta else Forja.PASSOU
		var ok := int(v.get("resultado", -1)) == esperado
```

E uma função nova, chamada no fim de `_ready()` antes do resumo:

```gdscript
func _prova_do_modo() -> void:
	var linhas := _linha_do_tempo()
	var modo := linhas.filter(func(e): return e.get("tipo") == "sessao" and e.get("evento") == "modo")
	_esperar(modo.size() == 1 and bool(modo[0].get("bancada", false)) == Forja.bancada,
		"a linha do tempo diz o modo (bancada: %s)" % Forja.bancada)
	var perguntas := linhas.filter(func(e): return e.get("o") == "pergunta")
	if Forja.bancada:
		for id in ["galeria", "impacto", "canto", "caminhos", "voz", "prova"]:
			_esperar(perguntas.any(func(e): return e.get("sala") == id), "bancada: %s perguntou às cegas" % id)
	else:
		_esperar(perguntas.is_empty(), "jogo: nenhuma pergunta sobre o controle (%d)" % perguntas.size())
```

## Para o André (local)

- `scripts/gauntlet.sh` (agora com `--bancada`): o limpo passa e cada defeito é pego.
- `bash tests/prova_de_poucos.sh` (agora com `--bancada`).
- `./run-local.sh -- --partida=5`: jogar a partida inteira e conferir que
  nenhuma sala pergunta nada, que o fim não tem tabela e que Create não abre
  nada.
- `./run-local.sh -- --bancada --partida=5`: as perguntas e a tabela de volta.

## Ao terminar

- No [quadro](README.md), a linha da F01: estado **feito** (com o commit) e o gasto real.
- Dizer ao André, no fim da sessão, que as duas rodadas da prova (o passo 7 da
  F08) já ficaram prontas aqui.
- Commit sugerido: `feat: o Modo bancada — perguntas, veredito, diagnóstico e livro só com --bancada`
