# F02 — Nenhuma frase metalinguística

**Sprint:** F · **Tamanho:** M · **Estimativa:** US$ 2,0 · **Depende de:** F00, F01

## Por quê

O jogador deve ler só verbos do mundo. Hoje a tela lista os recursos do
controle, manda olhar a luz, fala de relatório, de módulo nativo e de VID:PID.

## Ler antes

- [As regras de ouro](../README.md#as-regras-de-ouro) (1 e 6)
- [06 — A voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto) (a lista "Nunca na tela")
- [13 — As convenções](../13-arquitetura.md#as-convenções) (todo texto passa por `Traducoes`)

## O estado de hoje

Depois da F01, as perguntas às cegas, a tabela de veredito, o diagnóstico e o
livro só aparecem com `--bancada`. **Não mexa neles**: `voz.gd:617` e
`prova.gd:802` ("olhe o controle…") e os títulos das perguntas só existem no
Modo bancada. O que sobra na tela do jogador:

**O verbo de cada sala** (`acao`, desenhado no aviso e no HUD):

| arquivo:linha | hoje |
| --- | --- |
| `salas/voz.gd:59` | `"Chame o guardião, fique mudo, olhe a luz."` |
| `salas/canto.gd:61` | `"Ouça: o canto saiu da sua mão?"` |
| `salas/galeria.gd:53` | `"Sinta o gatilho, diga a arma, atire."` |
| `salas/caminhos.gd:55` | `"Sinta o chão na mão e diga qual é."` |
| `salas/molde.gd:56` | `"O touchpad é o molde: trace, abra, carimbe."` |
| `salas/viga.gd:58` | `"Equilibre, mire e martele com o controle."` |
| `salas/prova.gd:81` | `"Brasa contra Maré, com tudo ligado."` |

**As dicas e os selos da sala:**
- `salas/canto.gd:531`: `{"partes": ["ouça: de onde vem?"], ...}`
- `salas/canto.gd:598`: `1: return "3 cantos no seu controle"` (o selo de `com_poucos`)
- `salas/impacto.gd:609`: `1: return "sozinho: isolamento não medido"`
- `salas/voz.gd:582`: `["@mic", "mudo no sistema: a sua vez passa"]`

**O aviso da sala** (`ui/painel_sala.gd:35-110`, `_aviso()`): desenha, por
feature de `sala.features`, o glifo e o nome do catálogo
(`_nome_da_feature(f)`, que vem do C: "Vibração forte", "Barra de luz"…):

```gdscript
	for f in sala.features:
		var tex := Desenho.glifo(Desenho.GLIFO_DA_FEATURE.get(f, ""))
		var nome := _nome_da_feature(f)
```

Nas salas de som (`papel >= 0`), cada chip de lugar mostra o dispositivo
achado (`_som_do_lugar`, `:119-139`): "Alto-falante do Controle 1
(DualSense…)", "acha sozinho", e as dicas `trocar`/`testar` (`:105-110`).

**O salão:** `mundo/salao.gd:16-23`, o `"sobre"` de cada portão é o hardware
(`"vibração e barra de luz"`, `"háptica por áudio"`…), mostrado na placa 3D
(`salao.gd:186-187`, por `Traducoes.traduzir`) e no HUD perto do portão
(`main.gd:670`). A bigorna: `main.gd:689`,
`"tudo junto, duas equipes · □ a partida · △ a Prova de Fogo"`.

**O título** (`ui/tela_titulo.gd`):
- `:38-40`: sem o módulo, `"O módulo nativo não carregou: só o teclado joga."` e `"Compile com scripts/compilar.sh linux."`;
- `:42`: `"Nenhum controle."`;
- `:71`: `var rodape := "FORJA %s  ·  relatórios ao lado do jogo" % Forja.versao()`.

**O cartão do lobby** (`ui/cartao_jogador.gd:71-87`): a linha do VID:PID
(`:71`), a origem com "no rádio, só a entrada" (`:72-76`) e a fileira "Luz" e
"LEDs" com o que foi mandado (`:79-87`). O comentário de `ui/tela_lobby.gd:3-6`
diz "o cartão mostra o que foi lido e o que foi mandado".

**A coleta das frases já existe:** `ui/desenho.gd:60-79`, `Desenho.t()` anota
cada texto desenhado quando `FORJA_COLETAR_TEXTOS=<arquivo>`:

```gdscript
static func t(s: String) -> String:
	if _coletar == "":
		_coletar = OS.get_environment("FORJA_COLETAR_TEXTOS")
		if _coletar == "":
			_coletar = "-"
	if _coletar != "-" and not _coletados.has(s):
		_coletados[s] = true
```

As placas 3D (`salao.gd:170`, `:187`; `caminhos.gd:441`) chamam
`Traducoes.traduzir` direto e escapam da coleta.

## O alvo

- Nenhuma frase de tela, fora do Modo bancada, nomeia recurso do controle como
  instrução, manda olhar o controle, ou fala de relatório, módulo, VID:PID,
  veredito ou "não medido" ([06](../06-telas-e-fluxo.md#a-voz-do-texto)).
- O aviso mostra o nome, o verbo e **um** ícone da parte do controle que a sala
  usa. A lista de features some. `SalaJogo.icone: String` (o nome de um glifo
  de `assets/glifos/`) é o que a `FICHA.icone` do kit vai preencher na H04.
- O portão diz a seção ("Seção 4"), não o hardware.
- O dispositivo de som achado (nome, como foi achado, trocar, testar) é
  ferramenta: só no Modo bancada. A H07 leva a escolha para a construção.
- A prova do jogo, na rodada sem `--bancada`, colhe tudo o que foi desenhado e
  reprova as palavras proibidas.

Frase nova = entrada nova em `godot/scripts/traducoes.gd` (13, as convenções).
A frase nova já nasce com maiúscula; a virada das antigas é a F07.

## Passos

1. **`ui/desenho.gd`** `t()`: um modo só de memória, para a prova:
   ```gdscript
   	if _coletar != "-" and not _coletados.has(s):
   		_coletados[s] = true
   		if _coletar == "memoria":
   			return Traducoes.traduzir(s)
   		var f := FileAccess.open(...)  # o resto como hoje
   ```
   E trocar `Traducoes.traduzir(...)` por `Desenho.t(...)` em `mundo/salao.gd:170`,
   `:187` e `salas/caminhos.gd:441`, para as placas 3D entrarem na coleta.
2. **Os verbos** (`acao`), trocando a frase e a chave em `traducoes.gd`:
   - `voz.gd:59` → `"Chame o guardião e fique mudo."`
   - `canto.gd:61` → `"Ouça o canto e repita o ritmo."`
   - `galeria.gd:53` → `"Sinta o gatilho e atire."`
   - `caminhos.gd:55` → `"Ande no escuro e sinta o caminho."`
   - `molde.gd:56` → `"Trace, abra e carimbe o molde."`
   - `viga.gd:58` → `"Equilibre, mire e martele."`
   - `prova.gd:81` → `"Brasa contra Maré."`
3. **As dicas e os selos:** `canto.gd:531` → `"Ouça o canto"`; `canto.gd:598` →
   `"3 cantos seus"`; `impacto.gd:609` → `"Só você na arena"`; `voz.gd:582` →
   `["@mic", "A sua vez passa"]`. Uma entrada em `traducoes.gd` para cada.
4. **O ícone do aviso.** Em `salas/sala_jogo.gd`, perto de `features` (`:23`):
   `var icone := ""  ## o glifo da parte do controle que a sala usa (assets/glifos/); a FICHA.icone do kit, na H04`.
   Cada sala põe o seu no `_init()`: centelha `"cross"`, viga `"giroscopio"`,
   molde `"touchpad"`, impacto `"rumble_esquerdo"`, galeria `"r2"`, canto
   `"alto-falante"`, caminhos `"rumble_direito"`, voz `"mic"`, prova `"stick_l"`.
   Em `painel_sala.gd` `_aviso()`: apagar o cálculo de `filas` (`:43-51`) e o
   laço das features (`:68-81`); no lugar, um glifo só de 96 px em
   `Rect2(Vector2(r.end.x - 48 - 96, r.position.y + 40), Vector2(96, 96))`,
   tingido `Tema.CIANO`. A altura do quadro (`:52`) perde o termo das filas.
   O `features` continua na sala: é o que a medida e o veredito usam.
5. **O som no aviso, só na bancada.** Em `painel_sala.gd` `_aviso()`: o
   `ALTURA_SOM` do chip (`:52`, `:90`), a chamada `_som_do_lugar(...)` (`:101-102`)
   e as dicas `trocar`/`testar` (`:106-109`) passam a valer só com
   `papel >= 0 and Forja.bancada`. Em `sala_jogo.gd:234-235`,
   `if papel_som >= 0 and Forja.bancada: _afinar_som(l, p)`. O `som_preparar`
   de `sala_jogo.gd:92-94` fica nos dois modos (o som tem de tocar).
6. **O salão:** em `mundo/salao.gd:16-23`, `"sobre"` passa a ser a seção, na
   ordem de [03](../03-os-45-minigames.md): centelha `"Seção 1"`, viga
   `"Seção 2"`, molde `"Seção 3"`, impacto `"Seção 4"`, galeria `"Seção 5"`,
   canto `"Seção 6"`, caminhos `"Seção 7"`, voz `"Seção 8"`. A bigorna
   (`main.gd:689`): `"Seção 9 · □ a partida · △ a Prova de Fogo"` (o formato
   dos botões é da F07). Em `traducoes.gd`, apagar as oito chaves antigas de
   hardware (`:50-57`) e a da bigorna (`:58`), e pôr o padrão `["^Seção (\\d)$", "Section $1"]` e a
   frase da bigorna.
7. **O título** (`ui/tela_titulo.gd`): sem o módulo (`:38-40`), não desenhar
   nada nessas duas linhas (o `push_warning` de `forja.gd:119` já registra);
   `:42` → `"Nenhum controle encontrado."`; `:71` →
   `var rodape := "FORJA %s" % Forja.versao()`. Tirar de `traducoes.gd` as
   três chaves que somem (`:20`, `:21` e a de `"Nenhum controle."`) e o padrão `^FORJA (\\S+)  ·  relatórios ao lado do jogo$`.
8. **O cartão do lobby** (`ui/cartao_jogador.gd`): apagar as linhas `:70-76`
   (VID:PID, origem e "no rádio, só a entrada") e `:78-87` (a fileira Luz e
   LEDs). O nome do controle (`:62-69`) e o rodapé ficam. Atualizar o
   comentário de `tela_lobby.gd:3-6` e o do cartão (`:3-8`).
9. **A prova**: a checagem de "Provas", abaixo.

## Armadilhas

- **Não confundir com a F07.** Aqui só se troca o **que** a frase diz. A caixa
  das frases antigas ("pronto", "aguardando") e o formato "Botão ✕ (Iniciar)"
  são da F07.
- **As frases das perguntas e da tabela** só aparecem com `--bancada` (F01):
  ficam como estão.
- **As placas 3D do salão** são montadas no `_ready` do salão; com a troca para
  `Desenho.t` do passo 1, elas entram na coleta mesmo que o robô nunca chegue
  perto de um portão.
- **O `features` da sala não sai.** A medida (`med_comecar`), o veredito
  (`dar_vereditos`) e as provas usam; só o desenho dele sai.
- **`_nome_da_feature`** (`painel_sala.gd:142`) continua sendo usado pela
  tabela de veredito da bancada (`_fim()`): não apague.
- **A prova da exportação** e o gauntlet não olham texto: nada a mudar neles.
- **`.uid`:** nenhum script novo aqui.

## Não fazer

- Não mexer nas perguntas às cegas (bancada) nem no livro e no diagnóstico.
- Não mudar a caixa das frases antigas (F07) nem desenhar o HUD novo (G04).
- Não criar a tela de construção nem mover a escolha do som para ela (G02, H07).

## Pronto quando

Na rodada sem `--bancada` da prova do jogo, nenhuma frase colhida na tela casa
com a lista proibida, e o aviso de cada sala mostra nome, verbo e um ícone.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, no começo de `_ready()`, antes de
instanciar `main.tscn` (`:47`):

```gdscript
	Desenho._coletar = "memoria"  # colhe cada frase desenhada (F02, F07)
```

A constante e a função, chamada no fim de `_ready()` junto das outras:

```gdscript
## O que nunca aparece na tela do jogador (06, a voz do texto; as regras de ouro).
const PROIBIDAS := "(?i)\\b(olhe|relatórios?|veredito|módulo|vid|hidraw|uinput|mac|mesa|vibração|giroscópio|acelerômetro|háptica|barra de luz|luzinhas?|alto-falante|gatilhos? adaptativos?|não medido)\\b|saiu d[oa] s(eu|ua)"


func _prova_das_frases() -> void:
	if Forja.bancada:
		return  # a bancada mostra o que o jogador não vê
	var r := RegEx.create_from_string(PROIBIDAS)
	var achadas: Array = []
	for s in Desenho._coletados:
		if r.search(str(s)) != null:
			achadas.append(s)
	_esperar(Desenho._coletados.size() > 50, "as frases da tela foram colhidas (%d)" % Desenho._coletados.size())
	_esperar(achadas.is_empty(), "jogo: nenhuma frase fala do controle como prova (%s)" % [achadas])
```

E, em
`_comeca_a_sala(id)`, depois de `_esperar(... "a sala abriu")`:

```gdscript
	_esperar(str(sala.icone) != "" and Desenho.glifo(str(sala.icone)) != null, "%s: o aviso tem o ícone da parte do controle" % id)
```

## Para o André (local)

- `./run-local.sh`: o título (sem "relatórios", sem "módulo"), o lobby (o
  cartão sem VID:PID e sem a fileira Luz/LEDs), o salão (as placas dizem
  "Seção N") e duas salas (o aviso com o verbo e um ícone).
- `./run-local.sh -- --bancada --sala=canto`: o chip do alto-falante de volta no aviso.

## Ao terminar

- No [quadro](README.md), a linha da F02: estado **feito** (com o commit) e o gasto real.
- Commit sugerido: `feat: a tela do jogador fala do mundo, não do controle`
