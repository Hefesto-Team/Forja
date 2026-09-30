# O molde de minigame

Como se escreve um minigame no kit. Uma sessão que faz um minigame lê esta
página, a linha do minigame em [03](../03-os-45-minigames.md) e o
[kit](../13-arquitetura.md#o-kit-do-minigame--h04) com
[as decisões comuns](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
— e nada mais. O código do kit está em
`godot/scripts/minigames/minigame.gd` (H04, com os acréscimos da
[H08](H08-os-acrescimos-do-kit.md)); os exemplos pequenos e completos são
`godot/testes/minigame_de_prova.gd` (a nota por tempo, o cabo que cai) e
`godot/testes/minigame_de_tempo.gd` (a fila de notas, o coop, o fim em tempo
de música).

**Toda ficha de minigame tem `Depende de: H08`** (a H08 depende do kit, do
relógio, das janelas, do fim, das sensações e do item). Sem a H08 no
[quadro](README.md) como **feito**, a ficha não começa.

## Onde mora

- O script: `godot/scripts/minigames/sNN/<nome_em_minusculas>.gd`
  (`s01/martelo_de_hefesto.gd`, `s02/pendulos_do_caos.gd`…), `extends Minigame`,
  **sem `class_name`** (o catálogo carrega pelo caminho).
- No catálogo (`godot/scripts/minigames/catalogo.gd`): o slot em
  `MINIGAMES` (`"S02_J07": preload("res://scripts/minigames/s02/pendulos_do_caos.gd")`)
  e na lista `minigames` da seção, em `SECOES`. O primeiro da lista é o
  **n.º1**: o que o apelido abre (`--sala=viga`), o da Prova de Fogo e o da
  bancada. A partida e o portão do salão **sorteiam** entre os cinco
  (`Catalogo.sortear`/`Catalogo.proximo`): a ficha não sorteia nada.
- O `.uid`: depois de criar o `.gd`, `"$GODOT" --headless --path godot --import --quit`,
  e o `<nome>.gd.uid` entra no commit.
- As frases novas da tela (título, verbo) em `godot/scripts/traducoes.gd`.

## O cenário: os kits da Kenney

Antes de montar o cenário, a sessão lê a linha do seu minigame em
[os kits nos 45 minigames](../14-os-assets-kenney.md#os-kits-nos-45-minigames)
e usa aquelas peças pelo nome real, com `Kit.peca(pai, "<pacote>/<peça>", ...)`
(a escala do pacote é automática, [G10](G10-a-biblioteca-kenney.md)). Se o kit
ainda não está em `godot/assets/kenney/`, a sessão pede ao André que rode
`python3 scripts/importar_kenney.py <zip> <pacote>` e, enquanto isso, monta com
o Mini Dungeon e anota no quadro que o cenário espera o kit. Onde a tabela diz
"montado" (balão, sino, dragão, mecha), vale a regra 4 do
[11](../11-arte-e-personagens.md#as-regras-de-coerência).

## A ficha de dados: o `const FICHA`

Um dicionário constante no começo do script. É texto: cabe no diff e se
escreve sem o editor. O kit lê no `_init()` e confere no `entrar()` (falta
chave, valor fora da lista, ícone que não é glifo, fim `tempo` sem duração,
duração acima de 120 s: `push_error` com o nome).

```gdscript
extends Minigame
## Pêndulos do Caos (S02_J07). <como se joga, em duas ou três linhas>
##
## A falha: <o que acontece fisicamente no erro — docs/jogo/02#6>.
## O vencedor: <o critério>. (No coop: o que faz todos vencerem, e quem é o destaque.)
## O alto-falante do dono: <o som pessoal — docs/jogo/05#a-agenda-do-alto-falante>.
## O registro mede: <a validação do recurso, por baixo — a linha "O registro
## mede" da seção em docs/jogo/03>.
## O robô: <como joga, e como erra quando não acerta>.
## Com menos de quatro: <o que muda; "nada" se nada muda>.
## A régua: <as três respostas de "A régua, antes do commit", abaixo>.

const FICHA := {
	"slot": "S02_J07",
	"titulo": "Pêndulos do Caos",
	"verbo": "Vire no alto!",
	"genero": "sobrevivencia",
	"icone": "giroscopio",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J07",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Vire!", "segundos": 6.0},
}
```

As chaves obrigatórias (as mesmas de `Minigame.CHAVES`):

| chave | o que é | valores |
| --- | --- | --- |
| `slot` | a seção e o número | `"Sxx_Jyy"` (o `id` da sala) |
| `titulo` | o nome na tela (o `nome`) | o da tabela de [03](../03-os-45-minigames.md) |
| `verbo` | a única instrução, de uma a três palavras (a `acao`) | `"Bata!"` |
| `genero` | o gênero; o `coop` do fim sai daqui (ninguém põe `coop = true`) | `tct`, `2v2`, `coop`, `corrida`, `sobrevivencia`, `terror`, `sabotagem` |
| `icone` | a parte do controle, para o aviso: o nome de um glifo de `godot/assets/glifos/` (o que `Desenho.glifo` carrega). O kit o copia para `SalaJogo.icone` | os glifos: `cross`, `circle`, `square`, `triangle`, `dpad_up`, `dpad_down`, `dpad_left`, `dpad_right`, `l1`, `l2`, `r1`, `r2`, `stick_l`, `stick_r`, `share`, `options`, `touchpad`, `giroscopio`, `acelerometro`, `rumble_esquerdo`, `rumble_direito`, `lightbar`, `led-jogador`, `mic`, `alto-falante`, `bateria`. Aceita também a parte do controle, que o kit traduz (`Minigame.ICONE_DA_PARTE`): `botoes` → `cross`, `analogicos` → `stick_l`, `gatilhos` → `l2`, `gatilho_adaptativo` → `r2`, `vibracao` → `rumble_esquerdo`, `haptica` → `rumble_direito`, `alto_falante` → `alto-falante`, `microfone` → `mic`, `barra_de_luz` → `lightbar`. (Não são os nomes de `ui/glifo.gd` — `cruz`, `circulo`… —, que são os das dicas de botão.) |
| `entradas` | os botões usados (no máximo três), com `Forja.CRUZ`… | `[Forja.CRUZ]`; `[]` quando a entrada é movimento, toque ou voz |
| `camera` | o modo de câmera (G05) | `fixa`, `grupo`, `corrida` |
| `faixa` | o slot musical ([04](../04-ritmo-e-audio.md#as-45-faixas)) | `"MUS_Sxx_Jyy"`; `""` = sem música (o relógio do sistema) |
| `duracao` | em segundos **de música** (com faixa, a placa de som; sem faixa, o relógio do sistema), contados do fim do treino; com o ritmo do nível, nunca passa de 120 | `90.0`; `0.0` **só** quando o fim é do próprio jogo (os medleys, o último em pé sem relógio) — nunca como remendo para "acabar antes" |
| `fim` | como acaba | `tempo` (pede `duracao` > 0), `ultimo_em_pe`, `primeiro_a_chegar`, `meta_coletiva` |
| `sensacoes` | as sensações usadas, pelo nome (F05, H08) | `toque`, `toque_esq`, `toque_dir`, `acerto`, `perfeito`, `erro`, `golpe`, `golpe_esq`, `golpe_dir`, `explosao`, `aviso` |
| `material` | o chão e os objetos ([05](../05-haptica-e-controle.md#a-háptica-por-material)): a textura que o kit toca na mão a cada acerto | `metal`, `pedra`, `areia`, `gelo`, `grama`, `lama`, `plasma`, `madeira` |
| `microjogo` | o recorte para o Relâmpago | `{"verbo": "Bata!", "segundos": 6.0}` (5 a 8 s) |

As chaves opcionais:

| chave | o que é | sem ela |
| --- | --- | --- |
| `features` | as features que a bancada mede (as chaves do catálogo do núcleo) — só no n.º1 da seção | nenhuma: nada de veredito |
| `botoes_medidos` | os botões que as medidas do núcleo acompanham | nenhum |
| `gesto` | o gesto do boneco no aviso (`"attack-melee-right"`, `"lados"`) | o boneco só espera |
| `treino` | `false` desliga o treino de 10 s | com treino |
| `nota_no_falante` | `false`: o kit não toca a nota do perfeito (nem a quebrada do erro) no alto-falante do controle — quando o alto-falante é a pista do minigame | toca |
| `textura_no_acerto` | `false`: o kit não toca a textura do material na háptica (nem o rumble) no acerto — quando a háptica é a pista | toca |
| `papel_som` | o papel de som que o minigame abre: `Forja.PAPEL_ALTO_FALANTE`, `Forja.PAPEL_HAPTICA` ou `Forja.PAPEL_MICROFONE` | o alto-falante |

## Os ganchos

O kit cuida do relógio, do julgamento, do registro, do fechamento, das
raias, de quem está conectado, da barra de luz e do item. O minigame
escreve só estes (todos opcionais, menos `montar`, `jogar` e `robo`):

| gancho | quando | o que faz |
| --- | --- | --- |
| `montar()` | ao entrar | o cenário, com peças do kit ([11](../11-arte-e-personagens.md#as-regras-de-coerência)); a câmera (`camera_pos`, `camera_olhar`); `raia(l)` e `posicionar(l)` de cada lugar. No 2v2, `equipe[l]` já está pronta aqui (a cor no chão e na armadura) |
| `iniciar_jogo()` | a fase jogo começou (a faixa já está tocando do zero) | as primeiras notas (`nova_nota`), a partir de `BATIDA_DA_PRIMEIRA_NOTA` (os quatro primeiros tempos são a contagem de entrada), com `proxima_batida` |
| `jogar(dt)` | a cada quadro da fase jogo | lê a entrada (`Forja.apertou`, `Forja.eixo`…); no toque, `casar_toque(l)` e `julgar_nota(l, n)`; a cada quadro, `notas_perdidas(l)`; mexe o mundo **pela batida** (`Ritmo.batida()`) e pelo andamento (`andamento()`, `no_pico()`), nunca somando `dt` nem lendo `t_fase`/`t_jogo` |
| `toque(l, julgamento)` | um toque julgado BOM, OTIMO ou PERFEITO | a consequência no mundo e os pontos: `marcar(l, PONTOS[julgamento])` (no 2v2, `marcar_equipe(equipe[l], ...)`) |
| `falha(l)` | um toque ERRO ou uma nota perdida (o Escudo já foi descontado) | a falha física |
| `vencedor()` | no fim | os lugares na ordem de colocação (padrão: pelos pontos) |
| `destaque()` | no fim do coop e do 2v2 | quem jogou melhor (padrão: o primeiro do `vencedor()`) |
| `robo(l, dt)` | a cada quadro, antes de `jogar`, para cada lugar em jogo e conectado | o jogo do robô, **só pelo controle simulado** |

No coop, o minigame só põe `coop_venceu = true` quando todos venceram; o kit
grava `vencedor` -1 com o `destaque`, e a tela diz "Todos venceram!" ou "A
forja apagou.". No 2v2, as equipes são **A Brasa** e **A Maré**
(`equipe[l]`, `BRASA`/`MARE`, `CORES_DAS_EQUIPES`, `aprendizes[e]` — a
regra de [Q](Q-a-prova.md#o-cenário-comum)); a cor da equipe vai no chão e
na armadura, **nunca** na barra de luz; os pontos vão para os dois com
`marcar_equipe(e, n)`, e a tela diz "A Brasa venceu!".

## O que o kit dá pronto (não reimplemente)

As fichas escritas antes da H08 trazem cópias destas peças; ao executar uma
delas, **use as do kit e apague a cópia**:

| do kit | para quê | a cópia que sai da ficha |
| --- | --- | --- |
| `RAIAS`, `Z_JOGADOR` | onde fica cada lugar (não redeclare: é erro de análise) | `const RAIAS` |
| `raia(l) -> Node3D`, `acender_raia(l, forca)`, `posicionar(l)` | a laje, a borda na cor do lugar, a luz da vez; o boneco nela | a montagem da raia |
| `conectado(l)`, `presentes()`, `na_raia(l)` | quem tem controle, quem joga, e a guarda da `dica`/`status` | `_conectado` |
| `BATIDA_DA_PRIMEIRA_NOTA`, `proxima_batida(l, desde, passo, desloc := 0.0) -> float` | a próxima batida do lugar **depois** de `desde`, no hoqueto; o passo dobra sozinho na partitura simples (`Ritmo.simples[l]`) | `_proxima_batida` |
| `nova_nota(l, n, t_alvo, perigo := false)` | a nota vai ao registro **e** à fila das notas em aberto | a fila própria |
| `casar_toque(l) -> int`, `julgar_nota(l, n) -> int` | a nota em aberto mais perto do toque (−1: nenhuma), e o julgamento dela | a busca da nota |
| `notas_perdidas(l) -> Array` | as que passaram de `FOLGA_PERDIDA` (140 ms) sem toque: viram erro e falha; as de quem caiu saem caladas | o "passou do alvo + JANELA_BOM" |
| `notas_em_aberto(l)`, `alvo_da(l, n)` | a fila, para desenhar e para o robô mirar | — |
| `julgar_toque(l, t_alvo, n := -1, perigo := false) -> int` | o julgamento de um toque contra um alvo qualquer (o que não é nota da fila) | — |
| `andamento() -> float`, `no_pico() -> bool`, `tempo_jogado()` | 0..1 da duração em tempo de música; o terço do meio | `_no_pico`, `t_jogo / (DURACAO_S * ritmo_nivel)` |
| a reação a cada julgamento (`_reagir`) | a sensação ou a textura na mão, a nota no alto-falante, o som na TV, e a barra de luz: o perfeito pisca branco 0,15 s, o erro escurece a cor do lugar por 0,5 s | `Forja.piscar`/`Forja.luz` no `toque`/`falha` |
| o item (G03) | o Martelo nos pontos do `marcar` dentro do `toque()`; o Escudo antes do `falha()` | `Itens.pontos_do_acerto`, `errou(l)` no minigame |
| `destaque()`, `montar_equipes`, `marcar_equipe(e, n)`, `pontos_da_equipe(e)`, `equipe_vencedora()` | o fim do coop e do 2v2 | `coop = true`, a conta das equipes |
| `anotar(tipo, l, campos)` | um evento do jogo com o `slot` (ver "O registro") | `Forja.evento(...)` sem slot |
| `falar(l, evento) -> bool` | a fala do cavaleiro, uma a cada 20 s por lugar | — |
| `Ritmo.t_da_batida(n)`, `Ritmo.batida()`, `Ritmo.t_musica()`, `Ritmo.simples[l]`, `Ritmo.calar(batidas)` | o tempo das notas; a partitura mais simples; a música que cala e o relógio que segue | — |
| `Forja.sentir(l, nome)`, `Forja.textura(l, material)`, `Forja.piscar(l, cor, s)`, `Forja.luz(l, cor)` (piso de 30%), `Forja.som_virtual(l)["som"]` | a sensação pelo nome; a textura só na háptica; a barra de luz; o último som que o alto-falante tocou (o robô ouve a altura) | `Forja.vibrar` |
| `marcar(l, n)`, `pontos`, `acabou`, `jogando`, `treinando`, `variante`, `rng` | o de sempre da `SalaJogo` | — |

O minigame **não** escreve `_init()` (se escrever, a primeira linha é
`super()`, senão a FICHA não é lida), não redeclara `RAIAS` nem as
constantes do kit, não põe `icone`, `coop` ou `papel_som` à mão (vêm da
FICHA), e não sobrescreve `comecar`, `terminar`, `sair`, `congelar`,
`_process`, `marcar`, `_reagir`, `tempo_jogado`, `campos_do_fim` nem
`frase_do_resultado` (são do kit). `progresso() -> String` continua sendo a
linha de texto opcional do painel ("Rodada 2 de 3"); o `0..1` é
`andamento()`.

## O n.º1 da seção e a bancada

O n.º1 de cada seção é o que mede o recurso do controle para o
[Modo bancada](../13-arquitetura.md#o-modo-bancada--f01). Ele traz, além do
jogo:

- as chaves `features` e `botoes_medidos` na FICHA (o que o núcleo mede);
- `dar_vereditos(l) -> Array`, **só** quando o veredito não sai sozinho das
  medidas do núcleo (a pergunta às cegas, a carga): começa pelo do kit e
  acrescenta o dele. Os vereditos são calculados e gravados nos dois modos:

  ```gdscript
  func dar_vereditos(l: int) -> Array:
  	var lista := super(l)  # as features da FICHA, pelas medidas do núcleo
  	var v := Forja.cega_veredito(l, "alto_falante", {"cega": ..., "tem": Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)})
  	if not v.is_empty():
  		lista.append(v)
  	return lista
  ```

- `pergunta(l) -> Dictionary`, **só com `Forja.bancada`**: fora dela devolve
  `{}` e o jogo segue (nenhuma pergunta ao jogador, regra de ouro 1). A
  pergunta é a de hoje, com o mesmo formato da `SalaJogo`:

  ```gdscript
  func pergunta(l: int) -> Dictionary:
  	if not Forja.bancada or not _perguntando[l]:
  		return {}
  	return {"titulo": "O canto saiu do seu controle?", "opcoes": [["cross", null, "Foi no meu"], ["circle", null, "Não foi"]],
  		"escolhida": _resposta[l], "certa": -1, "rodape": "", "pos": Vector3(RAIAS[l], 0.0, 3.9)}
  ```

  O que abre e fecha a pergunta (o estado de bancada, a resposta pelo ✕/○
  do controle, o robô que responde em `robo()`) fica todo dentro de
  `if Forja.bancada:`. O registro grava a linha `saida` com
  `"o": "pergunta"` (F01).
- Os outros quatro da seção **não** medem nada para a bancada: gravam o que
  é deles com `anotar("entrada", ...)` e `anotar("jogo", ...)`.

## O robô

- **`Forja.robo` só aparece aqui**, na primeira linha do gancho:
  `if not Forja.robo: return`. Fora dele o jogo não sabe que é robô
  ([a paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)).
- **Só pelo controle simulado:** `Forja.robo_apertar`, `robo_eixo`,
  `robo_girar`, `robo_tocar`, `robo_falar`, `robo_sacudir`. Nunca mexe em
  estado do minigame. Pode **ler** o que um jogador veria ou ouviria: a fila
  (`notas_em_aberto`, `alvo_da`) e o `Forja.som_virtual(l)` (o nível e o
  `som` que tocou).
- **O robô erra.** Para cada nota (ou cada decisão), ele consulta
  `Forja.robo_acerta()` (o temperamento `--robo=bom|medio|ruim`, F09) uma
  vez; quando não acerta, aperta atrasado ou não aperta. O
  `godot/testes/minigame_de_tempo.gd` mostra o jeito, com a fila:

  ```gdscript
  var abertas := notas_em_aberto(l)
  if abertas.is_empty():
  	return
  var n: int = abertas[0]
  if _robo_nota[l] != n:
  	_robo_nota[l] = n
  	_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.25   # 250 ms atrasado: a nota passa
  if _robo_apertou[l] != n and Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]):
  	Forja.robo_apertar(l, Forja.CRUZ, 0.05)
  	_robo_apertou[l] = n
  ```

- **O robô mira pelo relógio da música**, não por `dt`: com `--fixed-fps 60`
  sem janela, o jogo anda muito mais depressa que a música.

## Os casos que quebram jogo

Todo minigame aguenta, sem mudar a regra:

- **1, 2, 3 e 4 jogadores.** Tudo passa por `jogadores` e `presentes()`;
  nada supõe quatro. O `2v2` com três ou menos usa `aprendizes[e]` (o kit
  já montou as equipes pela regra de Q) e diz no cabeçalho o que muda (e a
  `com_poucos()` da `SalaJogo` diz em poucas palavras para o aviso).
- **Um controle que cai no meio** (o cabo que sai; na prova,
  `Forja.ctl.simulador_cabo(sim, false)`): a nota de quem está sem controle
  **não** vira erro (`notas_perdidas` a tira calada), o minigame segue sem
  ele, e quando o controle volta a próxima nota é uma que ainda não passou
  (`proxima_batida(l, maxf(ultima, Ritmo.batida()), ...)`).
- **A pausa**: o kit congela o jogo e o relógio juntos; o minigame não faz
  nada.
- **O treino**: julga igual, não soma (é o `marcar()`); o tempo de música
  da duração só começa quando ele acaba.

## O registro

O kit grava sozinho: a `nota` (`nova_nota`), o `toque` (com o julgamento e o
desvio, ou `perdida`), o `minigame` `comecou` e `terminou` — sempre com
`vencedor` (−1 só no coop, com `destaque` e `coop_venceu`; no 2v2, com
`equipe`), e o `genero` — e o `desempenho`. O minigame grava o que "O
registro mede" pede da seção dele com `anotar(tipo, l, campos)` (`l` = −1
para o que é do minigame todo), que acrescenta o `slot`:

| tipo | quando | campos |
| --- | --- | --- |
| `entrada` | o que o jogador fez: o toque cru | `o` (`"botao"`, `"gatilho"`, `"sensores"`…) e os valores |
| `jogo` | o que o minigame fez no mundo | `o` (o nome da coisa) e os valores |
| `pista` | a pista que o minigame deu a um jogador | `canal` (`haptica`, `alto_falante`, `rumble`, `tela`) e o que foi |
| `troca` | o minigame trocou de canal por falta de recurso | `de` → `para`: `giroscopio` → `analogico`, `haptica` → `rumble`, `microfone` → `sem_microfone`, `alto_falante` → `tv` |
| `voz` | o nível do microfone e o limiar (os minigames de voz) | `nivel`, `limiar` |
| `estacao` | o trecho de um medley que começou ou acabou | `nome`, `evento` (`comecou`/`acabou`) |

Tipo fora da lista, canal ou troca que não existe: `push_error` e nada
gravado. As medidas do núcleo (`Forja.med_*`) continuam só no n.º1. Tipo
novo: acrescente na
[tabela do registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07)
e em `Minigame.TIPOS_DO_JOGO`, no mesmo commit.

## A prova

- Uma função nova em `godot/testes/prova_do_jogo.gd`, no padrão
  `_esperar(cond, "mensagem")`, que usa
  `_joga_o_minigame(slot, limite_s := 60.0, a_cada_quadro := Callable()) -> Minigame`
  (da H08): ele abre o minigame pelo catálogo — o mesmo caminho do
  `--sala=<slot>` —, deixa o aviso passar em quadros, espera o jogo pelo
  **relógio de parede** (o limite sobe sozinho para a duração + 45 s), chama
  `a_cada_quadro.call(mg)` a cada quadro, e já confere o que todo minigame
  deve: fechou, com vencedor (−1 só no coop), e, no fim por `tempo`, que os
  90 s de música duraram ~90 s de parede. A função da ficha confere o que só
  este minigame faz (a saída que chegou ao controle certo, o julgamento que
  o robô mirou, o `anotar` no registro):

  ```gdscript
  ## Pêndulos do Caos (S02_J07): <o que se confere>.
  func _prova_dos_pendulos() -> void:
  	var visto := {}
  	var olhar := func(mg: Minigame) -> void:
  		for l in mg.presentes():
  			pass  # o que cada quadro mostra: Forja.percepcao(l), Forja.som_virtual(l)...
  	var mg := await _joga_o_minigame("S02_J07", 60.0, olhar)
  	if mg == null:
  		return
  	_esperar(..., "S02_J07: ...")
  ```

- Ela é chamada pelo `match` de `_prova_da_ficha(slot)`, numa linha:
  `"S02_J07": await _prova_dos_pendulos()` — **não** no percurso (o
  percurso passa por cada minigame pelo caminho curto; jogar 90 s de cada um
  é do gauntlet e da prova visual). O n.º1 da seção confere também os
  vereditos com `_confere_os_vereditos(mg, [...])`.
- Rode `SALA=S02_J07 bash tests/prova_do_jogo.sh` (a prova rápida mais o
  minigame da ficha, inteiro, em tempo de música) e
  `bash tests/prova_visual.sh`, e **olhe** a prancha (o minigame aparece
  nas partidas com quatro, com dois, com um jogador e com o cabo que cai; o
  sorteio da partida põe os cinco da seção, um por noite).

## A régua, antes do commit

1. Alguém que nunca jogou entende o que fazer só com o título, o verbo e o
   ícone?
2. Sem a tela, dá para jogar só com o controle? (Nos minigames em que a
   feature é a pista.)
3. O minigame pergunta ao jogador se o controle funcionou? Se sim, volta para
   o Modo bancada.
4. Todo objeto novo passa no checklist de arte de
   [11](../11-arte-e-personagens.md#o-checklist-de-aprovação)?

## Pronto quando

O minigame joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; dura a `duracao` da FICHA em tempo de música; aguenta
o cabo que cai e volta; fecha sempre com vencedor (ou −1 e destaque no
coop); não reimplementa nada da tabela do kit; `SALA=<slot> bash tests/prova_do_jogo.sh`
passa; e **`bash tests/prova_visual.sh` passa com a prancha olhada** —
nenhum minigame fecha só com fotos.
