# G11 — A interface da fita e os ícones que faltam

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F05 (`Forja.sentir`), F07, F09, G14 (os tokens e as fontes),
G15 (o pós da fita, para o `desbota` da pausa)

## Por quê

As telas de hoje são molduras do Drácula desenhadas à mão, e os menus não fazem som. O [06](../arte/06-interface-e-texto.md)
diz o que cada objeto é na fita (a placa de casco, a etiqueta, o J-card, o chip, as lâmpadas, a dica de botão); esta
ficha põe esses objetos em `Desenho`, faz a pausa da fita, dá som e toque aos menus e traz do Input Prompts os ícones
de botão que faltam. As molduras do UI Pack saem: o [06](../arte/06-interface-e-texto.md#os-objetos) ganha da versão
antiga desta ficha, porque a moldura de jogo genérica quebra o pilar 1 (tudo é objeto da fita).

## Ler antes

- [06 — a interface e o texto](../arte/06-interface-e-texto.md) (os objetos, a etiqueta, o J-card, a pausa)
- [02, a margem e a forma](../arte/02-cor-e-letra.md#a-margem-e-a-forma) (os raios, as bordas, as sombras, a escala)
- [14, os ícones de botão](../14-os-assets-kenney.md#os-ícones-de-botão)

## O estado de hoje

- Tudo é desenhado em `_draw()` com `godot/scripts/ui/desenho.gd`: `Desenho.moldura(ci, r, fundo, borda, largura := 2,
  raio := Tema.RAIO_QUADRO)` (linha 41), `Desenho.selo` (136), `Desenho.leds` (147), `Desenho.dicas_a_direita` e
  `dicas_a_esquerda` (186, 196), `Desenho.glifo(nome)` (24), que carrega `res://assets/glifos/<nome>.png`.
- `Desenho.moldura` é chamada em 12 arquivos de `godot/scripts/ui/` (hud 5, painel_sala 9, cartao_jogador 4,
  diagnostico 4, livro, resultado, placar e pausa 3 cada, painel_bancada, escolha_partida e tela_opcoes 2 cada,
  tela_lobby 1). Meça de novo antes de mudar.
- `godot/scripts/ui/pausa.gd` desenha uma caixa de 620 px no meio, sobre `Tema.APP` a 82 %, com as opções Continuar,
  Diagnóstico e O livro da sessão (só na bancada), Opções, Voltar ao salão (na sala), Voltar ao lobby e Sair do jogo.
  `main.gd:763` congela a sala ao abrir (`SalaJogo.congelar(true)`); `_quadro_overlay` (linha 828) navega.
- Os menus quase não soam: só `tela_opcoes.gd` toca `"tique"`. Os ids `ui_tique`, `ui_confirma`, `ui_volta` e
  `fx_stop` estão no [mapa do áudio](../audio/mapa.csv), com o WAV em `godot/estudos/direcao/som/<id>.wav`.
- Os 26 glifos de `godot/assets/glifos/` (PNG de 128 px, brancos) não têm o mudo nem os gestos do touchpad.
- O All-in-1 está em `oficina/kenney/3.7.0/`; os SVG do Input Prompts em
  `oficina/kenney/3.7.0/Icons/Input Prompts/PlayStation Series/Vector/playstation5_*.svg`. `rsvg-convert` está em
  `/usr/bin`.

## Arquivos que mudam

- `godot/scripts/ui/desenho.gd`: `placa`, `etiqueta`, `jcard`, `chip`, `lampadas`, `dica`; `moldura` passa a desenhar
  a placa. **De todos:** G12 (usa `jcard` e `etiqueta`), G14 (troca as cores de dentro)
- `godot/scripts/tema.gd`: `RAIO_PLACA 14`, `RAIO_ETIQUETA 8`, `BORDA_PLACA 3`, `SOMBRA_PLACA (4, 6)`,
  `SOMBRA_ETIQUETA (5, 7)`. **De todos:** G14, G15
- `godot/scripts/ui/pausa.gd`: a pausa da fita
- `godot/scripts/main.gd`: o som e o toque em `_quadro_overlay`; `fx_stop` e o pós ao abrir a pausa. **De todos:**
  G09, G13, G14, G15, G16
- `godot/scripts/musica.gd`: `abafar(sim: bool)`. **De todos:** G16
- `godot/scripts/som.gd`: tocar pelo id do mapa (o encanamento abaixo) e `Som.ui`. **De todos:** G09, G12, G16
- `docs/jogo/audio/mapa.csv`: as linhas `ui_tique`, `ui_confirma`, `ui_volta`, `fx_stop`. **De todos:** G09, G12, G16
- `godot/assets/sons/ui_tique.wav`, `ui_confirma.wav`, `ui_volta.wav`, `fx_stop.wav` (cópias; quem chega primeiro
  copia, os outros usam)
- `godot/scripts/traducoes.gd`: «Voltar ao salão», «Voltar ao lobby», «Sair», «Pausa · P%d». **De todos:** G09, G12,
  G16
- `godot/assets/glifos/`: seis PNG novos e os `.import`
- `scripts/glifos_do_kenney.py` (novo): o export dos seis
- `godot/assets/LEIA-ME.md` e `LICENCAS-DE-TERCEIROS.md`: a linha do Input Prompts (Kenney, CC0). **De todos:** G10,
  G14
- `godot/testes/prova_do_jogo.gd`. **De todos**
- `docs/jogo/14-os-assets-kenney.md`, «A interface»: o UI Pack fica de fora, pelo 06

## Como se joga

A pausa: Options abre; quem pausou navega com ▲ ▼, ✕ escolhe, ◯ ou Options fecha (como hoje). As linhas, nesta ordem:

| linha | quando aparece |
| --- | --- |
| Continuar | sempre |
| Diagnóstico | só no Modo bancada, fora da prova às cegas (como hoje) |
| O livro da sessão | só no Modo bancada |
| Opções | sempre |
| Voltar ao salão | só numa sala |
| Voltar ao lobby | só fora de uma sala |
| Sair | sempre |

Fora da bancada são quatro linhas, as do [06](../arte/06-interface-e-texto.md#a-pausa). «Voltar ao lobby» some na sala
porque o salão já leva ao lobby; «Sair do jogo» vira «Sair».

## A cena

**Os objetos em `Desenho`** (as medidas do [06](../arte/06-interface-e-texto.md#os-objetos) e do
[02](../arte/02-cor-e-letra.md#a-margem-e-a-forma), na tela de 1920×1080):

| função | o que desenha |
| --- | --- |
| `placa(ci, r, foco := Color(0,0,0,0))` | `SOMBRA` deslocada (4, 6); `CASCO` com raio 14; borda de 3 px em `CASCO_ALTO`; com `foco` de alfa > 0, o fundo vira `CASCO_ALTO` e a borda, 3 px na cor `foco` |
| `etiqueta(ci, r, tinta: Color, inclinacao := 0.0, lado_b := false)` | `SOMBRA` deslocada (5, 7); papel `ETIQUETA` com raio 8; a tarja de 12 px a 14 px do topo na `tinta` (lado B: duas de 7 px com 4 px de vão); duas linhas pautadas em `ETIQUETA_SOMBRA`, 2 px, a 22 px das bordas; tudo girado por `inclinacao` (graus, de −1,5 a +1,5) em volta do centro |
| `jcard(ci, r, tinta: Color, lombada: String)` | `SOMBRA` (5, 7); o papel `ETIQUETA`; a lombada de 104 px em `ETIQUETA_SOMBRA` à esquerda, com tarja de 22 px no topo na `tinta` e o texto em VT323 46, `TINTA_SUAVE`, a −90°; a tarja da frente de 16 px a 22 px do topo; a inclinação parada de 0,5°. O conteúdo é de quem chama (a pausa aqui, o «como jogar» na G12) |
| `chip(ci, r, lugar: int, pronto: bool)` | 400×64: pronto, fundo `JOGADOR[lugar]` e texto em `FITA`; treinando, `CASCO` com borda de 3 px na cor do dono e texto `ETIQUETA` a 75 %; o P# em Bungee 30 |
| `lampadas(ci, pos, lugar: int)` | 5 posições de 15×8 px com vão de 5 px; acesas na cor do dono pelo padrão do LED do lugar, apagadas em `GRAFITE` |
| `dica(ci, pos, glifo: String, frase: String, sobre_etiqueta := false) -> float` | o glifo de 52 px e a frase em Archivo Narrow 600 de 34 px, 12 px depois; `ETIQUETA` sobre o casco, `TINTA` sobre a etiqueta; devolve a largura |

- **`Desenho.moldura` vira a placa:** a assinatura fica (os 12 arquivos não mudam); o `raio` pedido é ignorado e vale
  14; a `largura` de 4 (o foco de hoje) vira `foco` = a cor da `borda`; as outras, borda de 3 px em `CASCO_ALTO`. A
  sombra entra em toda placa. As cores que os 12 arquivos passam são trocadas pela G14.
- `dicas_a_direita` e `dicas_a_esquerda` passam a chamar `dica`, com glifo de 52 px e letra de 34 px (hoje
  `T_SELO`).
- `Desenho.leds` fica: ele é a bateria e o diagnóstico da bancada.

**A pausa da fita** (o [06](../arte/06-interface-e-texto.md#a-pausa)):

1. Ao abrir: `fx_stop`; a sala congela (como hoje); o pós vai a `desbota` 0,6 em 67 ms (4 quadros), pela função da
   G15 (`PosFita.ajustar("desbota", 0.6, 67)`). Ao fechar, `PosFita.soltar("desbota", 67)` (volta ao valor do desgaste da faixa em 67 ms), com `PosFita.rasgo_curto()` (o rasgo da volta da pausa,
   [06](../arte/06-interface-e-texto.md#o-rasgo-de-vhs)).
2. A barra de pausa: uma faixa de 24 px de ruído (`GRAFITE` e `MUDO` em listras de 2 px que trocam a cada quadro) sobe
   a tela inteira, de y 1080 a −24, a cada 2 s, `RETA`. Com Flashes desligado, ela não aparece.
3. O J-card da pausa: `Desenho.jcard` de 1064×830 em (760, 90), entra da direita (x de +1100 a 0) em 500 ms (`SAI`).
   A lombada diz «PAUSA · P2» (o lugar de quem pausou), a tarja na tinta da seção da sala (fora da sala, `GRAFITE`).
   As linhas: 84 px de altura, a partir de y 160 dentro do cartão, Archivo Narrow 600 de 44 px em `TINTA`; a linha em
   foco tem a caixa de 3 px na cor de quem pausou e o glifo `cross` de 52 px à esquerda; «Sair» em `TINTA` também
   (vermelhão não passa a 44 px sobre a etiqueta). Embaixo, `dica("cross", "Escolher")` e `dica("circle", "Voltar")`
   sobre a etiqueta.
4. O fundo: a tela parada e desbotada, sem o véu de `APP` a 82 % de hoje.

**Os ícones novos**, exportados por `scripts/glifos_do_kenney.py` com `rsvg-convert -w 128 -h 128`, em branco sobre
transparente (o jogo tinge), com o `.import` de filtro linear e sem compressão:

| arquivo | de |
| --- | --- |
| `mudo.png` | `playstation5_button_mute.svg` |
| `touchpad_esquerda.png` | `playstation5_touchpad_press_left.svg` |
| `touchpad_direita.png` | `playstation5_touchpad_press_right.svg` |
| `touchpad_deslizar.png` | `playstation5_touchpad_swipe_horizontal.svg` |
| `touchpad_cima.png` | `playstation5_touchpad_swipe_up.svg` |
| `touchpad_baixo.png` | `playstation5_touchpad_swipe_down.svg` |

O script lê do All-in-1 por `pasta_do_pacote()` de `scripts/kenney.py`, confere que cada PNG saiu com 128×128 e
pinta de branco todo pixel com alfa > 0 (o SVG da Kenney pode vir em outro tom). Nenhum botão PS e nenhum logo.

## O som

O encanamento, igual nas fichas G09, G11, G12 e G16: copiar cada `<id>.wav` usado de `godot/estudos/direcao/som/`
para `godot/assets/sons/<id>.wav`; `Som.tocar(nome, ...)` e `Som.no_controle(lugar, nome, ...)` tocam primeiro
`res://assets/sons/<nome>.wav` quando ele existe, sem o tom sorteado de ±5 % dos gravados; a linha do mapa ganha
`arquivo` = `godot/assets/sons/<id>.wav` e `estado` = `no jogo`. Se outra ficha já fez a mudança em `som.gd`, use-a
sem mudar. A V05 depois troca as tabelas do `Som` pelo mapa.

`Som.ui(lugar: int, id: String)` (novo em `som.gd`, se a G09 não o fez): `Som.tocar(id, null, -12.0)` na TV e
`Som.no_controle(lugar, id)` no alto-falante do dono.

| evento | id | onde |
| --- | --- | --- |
| ▲ ▼ ◀ ▶ andam numa lista (pausa, escolha da partida, opções, livro) | `ui_tique` (35 ms) | `Som.ui` de quem navega |
| ✕ escolhe (pausa, escolha da partida, opções) | `ui_confirma` (90 ms) | `Som.ui` |
| ◯ ou Options fecham um overlay | `ui_volta` (90 ms) | `Som.ui` |
| a pausa abre | `fx_stop` (250 ms) | na TV a −6 dB, como o mapa |
| a música, com a pausa aberta | `Musica.abafar(true)` (novo em `musica.gd`): o tocador ativo cai 18 dB abaixo de `VOLUME_DB` em 67 ms; `abafar(false)` volta em 67 ms | |

O `Som.tocar("tique")` de `tela_opcoes.gd` sai: o som da navegação fica em `main.gd`, num lugar só. O `"tique"` das
salas não muda.

## O controle

| evento | vibração | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- |
| navegar, escolher, voltar | `Forja.sentir(l, "toque")` (0 / 0,45 / 60 ms), só em quem apertou | não muda | não muda | o id da tabela do som | não se usa |
| a pausa abre | nada | `Forja.gatilhos_off(l)` nos quatro (o `fx_stop` do mapa: gatilho Off em todos) | as lâmpadas seguem; a lightbar não muda | nada | não se usa |
| a pausa fecha | nada | a sala devolve o gatilho dela ao descongelar (`congelar(false)` já reaplica) | não muda | nada | não se usa |

Prova sem o controle na mão: o robô aperta pelo controle simulado, e a prova conta no registro as linhas
`{"tipo": "sensacao", "nome": "toque"}` de quem navegou.

## O cavaleiro

Não se aplica: nenhuma peça nem stat aparece nesta interface.

## As reações

Não se aplica: a pausa não dispara reação; com a pausa aberta, as reações que chegam esperam (a regra do
[09](../arte/09-reacoes.md#com-o-conforto) que a ficha das reações aplica).

## A diversão

Não se aplica como momento: a interface não faz o grupo gritar. O que ela tem de garantir é não roubar tempo da
noite, e isso se confere:

- **A mesa:** a padrão (P1 `bom`, P2 e P3 `medio`, P4 `ruim`), semente 7, com o robô abrindo a pausa uma vez por sala
  (P4, 2 s depois do início) e escolhendo Continuar.
- **A janela:** da abertura ao Continuar, no máximo 2 s no robô; a sala volta no mesmo quadro do fechamento.
- **O rastro na prancha:** a prancha da noite (480×270 a cada 2 s, 6 colunas) mostra o J-card da pausa e a barra num
  quadro de cada sala, e nenhum quadro com o véu `APP` de hoje.

## Pronto quando

A pausa é o J-card da fita com `fx_stop`, o desbota e a barra; toda placa das 12 telas tem raio 14, borda de 3 px e a
sombra; os menus soam e vibram em quem aperta; os seis ícones novos existem em `godot/assets/glifos/`; e nenhum
arquivo do UI Pack entrou no jogo.

## Provas

- `bash tests/prova_do_jogo.sh`, com estas checagens novas em `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  for nome in ["mudo", "touchpad_esquerda", "touchpad_direita", "touchpad_deslizar", "touchpad_cima", "touchpad_baixo"]:
  	var g := Desenho.glifo(nome)
  	_esperar(g != null and g.get_width() == 128, "glifo novo: %s" % nome)
  _esperar(not DirAccess.dir_exists_absolute("res://assets/kenney/ui-pack"), "ui: o UI Pack não entrou")
  # a pausa fora da bancada: quatro linhas
  main.pausa.abrir(1, true, false, false)
  _esperar(main.pausa.opcoes.map(func(o): return o[0]) == ["continuar", "opcoes", "salao", "sair"], "pausa: as quatro do 06")
  # o som e o toque da navegação
  var antes := _contar_registro("sensacao", 1, "toque")
  Forja.robo_apertar(1, Forja.CIMA)
  await get_tree().process_frame
  _esperar(_contar_registro("sensacao", 1, "toque") == antes + 1, "pausa: navegar vibra em quem apertou")
  _esperar(Som.ultimo == "ui_tique", "pausa: navegar soa ui_tique")
  ```

  (`Som.ultimo`: o id do último `tocar`, uma variável nova só para a prova; `_contar_registro` já existe na prova da
  F05; se não existir, conta as linhas do registro do dia com aquele `tipo`, `jogador` e `nome`.)
- `python3 scripts/glifos_do_kenney.py --conferir`: os seis PNG têm 128×128 e nenhum pixel de alfa > 0 fora do branco.
- `bash tests/prova_visual.sh`: as pranchas da pausa (na sala e no salão) e de três telas com placa (HUD, resultado,
  opções). Na pausa: o J-card na posição do 06, a tarja na tinta da sala, a barra de 24 px num dos quadros.
- `bash scripts/portoes/rodar.sh --so arte`: nenhum achado novo em `desenho.gd`, `pausa.gd` e `tema.gd`.

## Passos

1. **Os objetos** em `desenho.gd` e as constantes em `tema.gd`; `moldura` passa a desenhar a placa.
2. **Os ícones:** `scripts/glifos_do_kenney.py`, os seis PNG e os `.import`
   (`"$GODOT" --headless --path godot --import --quit`).
3. **O som:** o encanamento em `som.gd` (ou o da G09), `Som.ui`, as quatro cópias e as linhas do mapa.
4. **A navegação soa e vibra** em `_quadro_overlay` de `main.gd`: cada `navegar` e `trocar` com `ui_tique`, cada ✕ com
   `ui_confirma`, cada fechar com `ui_volta`, e `Forja.sentir` de quem apertou.
5. **A pausa da fita** em `pausa.gd` e na abertura em `main.gd` (o `fx_stop`, os gatilhos, o pós, `Musica.abafar`).
6. **O 14:** a seção «A interface» diz que o UI Pack fica de fora e aponta o 06.

## Armadilhas

- **A área útil encolhe 1 px** com a borda de 3 px: a coleta de texto da prova visual acusa texto saindo da placa.
- **O vermelhão sobre a etiqueta** só passa a 48 px ou mais; «Sair» vai em `TINTA`.
- **A barra de pausa é piscar:** obedece a Flashes, como o 10 manda.
- **`congelar(false)`** reaplica o gatilho da sala: não chame `gatilhos_off` ao fechar.
- **Os ícones da Sony:** só o desenho do gesto e do botão de mudo; nada de logo.

## Não fazer

- Não importar o UI Pack nem o UI Pack Sci-Fi.
- Não usar as versões Pixel nem 1-Bit do Input Prompts.
- Não mexer no `reacao_pop`: ele é da ficha das reações.
- Não trocar fonte nem cor de token aqui: é da G14.

## Ao terminar

Marcar G11 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(interface): a placa, a etiqueta e o J-card da fita, a pausa que desbota, o som dos menus e os ícones do touchpad`.
