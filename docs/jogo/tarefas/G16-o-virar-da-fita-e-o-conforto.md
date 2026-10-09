# G16 — O virar da fita, o movimento e as reações nas Opções

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F05 (`Forja.sentir`), F07, F09, G01 (o cassete desenhado, `Desenho.caixa`), G11 (`Desenho.etiqueta`,
`Desenho.dica`), G12 (`partida.lado()`), G14 (os tokens e as fontes), G15 (`luz_da_secao`, `acender`)

## Por quê

A noite não tem intervalo, e o conforto só desliga o tremor. A bíblia propõe três coisas que mudam o jogo e não só a
imagem: a fita vira no meio da noite (o intervalo, com a luz do lado B), a opção «Movimento» no lugar de «Movimento
da câmera», e a opção «Reações». Esta ficha leva as três ao jogo.

## Ler antes

- [01, o virar da fita](../arte/01-cinema.md#o-virar-da-fita) (e «O lado B», logo acima)
- [10, o movimento reduzido](../arte/10-acessibilidade.md#o-movimento-reduzido) (a tabela; «O piscar», logo abaixo)
- [09, com o conforto](../arte/09-reacoes.md#com-o-conforto)

## O estado de hoje

- `godot/scripts/opcoes.gd`: `static var tremor := true` e `flashes := true` (linhas 41 e 42), `de_fabrica()` (55,
  56), `ler()` (83, 84) e `gravar()` (100, 101), na seção `sessao` de `user://opcoes.cfg`.
- `godot/scripts/ui/tela_opcoes.gd`: as linhas em `abrir()` (46 `["tremor", "Movimento da câmera", "sessao"]`, 47
  `flashes`), `trocar()` (79 a 82) e `valor()` (99, 100). São 10 linhas; o quadro mede
  `124 + 80 + 10 × 72 + 48 + 70` = 1042 px de altura.
- Quem lê `Opcoes.tremor`: `main.gd:929` (o giro do título, `_t * 0.08`), `main.gd:986` (o tremor da câmera na sala,
  de `sala.tremor`, que `prova.gd:370`/624 e `voz.gd:505` escrevem) e `godot/testes/captura_jogo.gd:43`.
- `Opcoes.flashes` já se lê em `voz.gd:302` e `sala_jogo.gd:195`; a G15 o lê no `PosFita`.
- O confete do pódio: `main.gd:490` a 497, `Efeitos.faiscas(salao, alto, cor, 22, 0.9)` a cada 0,45 s.
- `main.gd:414` `_seguir_a_partida()`: ✕ no placar entra na sala seguinte ou no pódio. A noite não para no meio.
- `godot/scripts/partida.gd`: `salas` (3, 5 ou 9), `passo`, `rotulo()`; a G12 acrescenta `lado()`.
- `godot/scripts/traducoes.gd:161` `"Movimento da câmera": "Camera motion"`.
- Os sons já gerados: `godot/estudos/direcao/som/fx_virar.wav` (o eject em 0 ms, o plástico de 250 a 1150 ms, o
  clunk de entrar em 1380 ms) e `fx_caneta.wav` (400 ms).

## O alvo

**O virar da fita.** Depois de `ceil(n / 2)` faixas (2 de 3, 3 de 5, 5 de 9), o ✕ no placar não entra na sala
seguinte: abre o virar e depois o intervalo.

- `main.gd` `_seguir_a_partida()`: se `partida.passo == ceil(partida.salas.size() / 2.0)` e
  `not partida.virou`, chama `_virar_a_fita()`; senão, como hoje. `Partida` ganha `var virou := false`.
- `T0` é o próximo tempo 1 da música que toca (`Ritmo.t_da_batida`), ou o quadro do ✕ se não há música.
- O plano dura **4000 ms fixos** (os 2 compassos do [06](../arte/06-interface-e-texto.md#as-transições), a
  120): a música para no eject, e o tempo conta em ms desde `T0`, não em batidas.
- Em 4000 ms, corte seco para o **intervalo**: `estado = "intervalo"`; o salão, com
  `acender(-1, true)` (a luz do salão no lado B, G15); os bonecos nos pedestais, `controlavel = false`; a música do
  salão (`_mostrar("intervalo")` toca `"salao"`). **Sem tempo limite:** o ✕ de qualquer lugar ocupado chama
  `_entrar_na_sala(partida.sala_atual())`, e `partida.virou` fica true.

**O lado B.** Do intervalo até o pódio, `partida.lado() == "B"`. As três mudanças do [01](../arte/01-cinema.md#o-lado-b):

- a luz: a entrada de cada sala chama `acender(numero, partida.lado() == "B")` (a G15 calcula a chave ×0,85 e a névoa
  ×1,3);
- a etiqueta da seção: toda chamada de `Desenho.etiqueta` da noite passa `lado_b = partida.lado() == "B"` (a tarja
  dupla é da G11);
- a lombada do J-card já mostra «LADO B» pela G12.

**Movimento.** `Opcoes.movimento`, 0 Inteiro e 1 Reduzido, no lugar de `Opcoes.tremor`:

- `const MOVIMENTO := ["Inteiro", "Reduzido"]`; `static var movimento := 0`; `static func reduzido() -> bool`.
- A migração: `ler()` usa `cfg.get_value("sessao", "movimento", 0 if bool(cfg.get_value("sessao", "tremor", true))
  else 1)`; `gravar()` escreve `movimento` e não escreve mais `tremor`.
- Três ajudas, para quem faz o item da tabela não reinventar a conta:
  `static func parada(quadros: int) -> int` (0 no Reduzido), `static func esmagar(fator: float) -> float` (limita o
  desvio de 1,0 a ±0,20 no Inteiro e ±0,05 no Reduzido) e `static func confete(n: int) -> int` (`ceili(n / 4.0)` no
  Reduzido).
- `Opcoes.tremor` sai. Nenhum `Opcoes.tremor` fica em `godot/scripts/` nem em `godot/testes/`.

**A tabela do 10, item por item, com quem faz:**

| o que | inteiro | reduzido | onde mora | a G16 |
| --- | --- | --- | --- | --- |
| tremor da câmera | até 4 batidas | nenhum | `main.gd:986` (todo tremor de sala passa aqui) | troca `Opcoes.tremor` por `not Opcoes.reduzido()` |
| o giro do título | `_t * 0.08` | parado | `main.gd:929` | idem |
| push-in, órbita, travelling, grua | os do 01 | corte seco para o plano final | as poses da câmera (G01, G05) | regra abaixo |
| roll da Dissonância e a lente a 18 mm | sim | não | a Dissonância (Q5, G05) | regra abaixo |
| squash e stretch | até 20 % | até 5 % | o boneco e os minigames | `Opcoes.esmagar` |
| hit-stop | 2 quadros | nenhum | o `secao.gd` de cada seção (`_parar` da K1) | `Opcoes.parada` |
| o corpo que abaixa no tempo | 2 % | nenhum | o boneco (G08) | regra abaixo |
| a tela que treme na cortina | 8 px | nenhuma | a entrada (G12) | regra abaixo |
| o confete | 4 por 1 | 1 por 4, sem giro | `main.gd:497` | `Opcoes.confete(22)`, 6 faíscas |
| o adesivo e o carimbo | escala e rotação | 4 quadros de opacidade | as reações (G04 e a ficha das reações) | regra abaixo |
| a fita girando no virar | o giro | corte | esta ficha | faz |

**A regra:** se a ficha dona do item já está feita quando a G16 roda, a G16 acrescenta a leitura de
`Opcoes.reduzido()` no lugar exato e cita o arquivo e a linha no commit; se ainda não está, a dona lê ao fazer (o
quadro diz). Nenhum julgamento, janela ou ponto muda.

**Reações.** `Opcoes.reacoes`, 0 Todas, 1 Só do jogo, 2 Nenhuma; padrão 0.

- `const REACOES := ["Todas", "Só do jogo", "Nenhuma"]`; `static func reacao_do_jogador() -> bool` (`reacoes == 0`) e
  `static func reacao_do_jogo() -> bool` (`reacoes <= 1`).
- Quem desenha o adesivo pergunta `reacao_do_jogador()`; quem carimba `car_*` pergunta `reacao_do_jogo()`; o
  `reacao_pop` cala com «Só do jogo» e os `car_*` com «Nenhuma» ([03](../arte/03-som.md#o-som-das-fichas-g)). O
  carimbo do julgamento não é reação e nunca cala.
- Hoje nenhuma reação existe: a linha grava e as duas funções respondem; a prova confere as funções.

**As Opções:**

- As linhas da sessão, nesta ordem: Volume da TV, Volume do controle, **Movimento** (`movimento`), Flashes,
  **Reações** (`reacoes`), Tela, Texto, Idioma. ◀ ▶ anda em `MOVIMENTO` e em `REACOES` com `wrapi`.
- `valor()`: `Opcoes.MOVIMENTO[Opcoes.movimento]` e `Opcoes.REACOES[Opcoes.reacoes]`.
- São 11 linhas: `124 + 80 + 11 × 72 + 48 + 70` = 1114 px, mais que 1080. O quadro passa a ter no máximo 1000 px
  (40 de margem); quando as linhas não cabem, a lista desliza em `_rolar` (px) para manter a linha escolhida inteira e
  mais uma de folga à vista; um glifo `cima` ou `baixo` de 32 px em `Tema.MUDO`, por `Glifo.desenhar(self, "cima", Rect2(...), Tema.MUDO)`
  (`godot/scripts/ui/glifo.gd:16`), marca o lado cortado.
- `traducoes.gd`: sai `"Movimento da câmera"`; entram `"Movimento": "Motion"`, `"Inteiro": "Full"`,
  `"Reduzido": "Reduced"`, `"Reações": "Reactions"`, `"Todas": "All"`, `"Só do jogo": "Game only"`,
  `"Nenhuma": "None"`, `"Lado B": "Side B"`, `"Seguir": "Continue"` (se a F07 não a pôs).

## Arquivos que mudam

- `godot/scripts/opcoes.gd`: `movimento`, `reacoes`, a migração, as cinco funções. **De todos:** F05 (o registro das
  opções)
- `godot/scripts/ui/tela_opcoes.gd`: as duas linhas, a lista que desliza. **De todos:** G11 (a placa), G14 (as cores)
- `godot/scripts/ui/tela_virar.gd` (novo, `class_name TelaVirar`): o deck e o cassete, o intervalo
- `godot/scripts/main.gd`: `_seguir_a_partida`, `_virar_a_fita`, o estado `intervalo` (em `_mostrar`), as linhas 929,
  986 e 497. **De todos:** G09, G11, G12, G13, G14, G15
- `godot/scripts/partida.gd`: `virou`. **De todos:** G12 (`lado()`)
- `godot/scripts/forja.gd`: a sensação `"fita"` em `SENSACOES`. **De todos:** F05
- `godot/scripts/ui/desenho.gd`: `cassete(ci, r, face, fita_esq, fita_dir)`, se a G01 deixou o cassete dentro do
  título. **De todos:** G01, G11
- `godot/scripts/traducoes.gd`. **De todos**
- `godot/scripts/som.gd` e `docs/jogo/audio/mapa.csv` (o encanamento abaixo). **De todos:** G09, G11, G12
- `godot/assets/sons/fx_virar.wav`, `fx_caneta.wav` (cópias)
- `godot/testes/captura_jogo.gd:43` (`Opcoes.movimento = 1`) e `godot/testes/prova_do_jogo.gd`. **De todos**

## Como se joga

- Numa noite de `n` faixas, depois da faixa `ceil(n / 2)` a fita vira; acontece uma vez por noite, nunca no treino
  nem numa sala avulsa.
- O virar dura 4000 ms e não aceita botão (o Options abre a pausa, como em toda tela).
- O intervalo não tem tempo limite. Qualquer jogador ocupado aperta ✕ e a noite segue; ◯ não faz nada; o Options
  abre a pausa (Voltar ao lobby encerra a noite, como hoje).
- Nenhum ponto, janela ou julgamento muda com Movimento ou Reações. Com a mesma semente, o placar do robô é o mesmo
  nos dois modos.

## A cena

**O virar** (`TelaVirar`, 2D na tela de 1920×1080, sobre o fundo `Tema.FITA`). O plano do 01 é «o deck aberto, 50 mm
de cima»: o cassete é desenhado, como no título da G01, e «de cima» quer dizer que a mão que tira o cassete o traz
para perto (ele cresce), não que a câmera 3D se mova.

| o quê | onde | como |
| --- | --- | --- |
| o deck | `Rect2(300, 110, 1320, 860)`, sombra (10, 16) | `Desenho.caixa` raio 40, `Tema.CASCO`, borda 4 `Tema.CASCO_ALTO` |
| o berço | `Rect2(370, 150, 1180, 750)` | `Tema.JANELA` raio 28 |
| a tampa aberta | `Rect2(370, 900, 1180, 40)` | `Tema.GRAFITE` raio 8 |
| o cassete | `Rect2(400, 170, 1120, 690)` | o desenho da G01 (casco, parafusos, etiqueta, janela, pé), por `Desenho.cassete` |
| a face A | a etiqueta do título (o logo, «A FORJA», a linha) | os carretéis parados: esquerda 0,30, direita 0,95 (o lado A acabou) |
| a face B | `Desenho.etiqueta(Rect2(456, 218, 1008, 360), Tema.SECAO[0], 0.0, true)`, em branco | os carretéis trocados: esquerda 0,95, direita 0,30 |
| «LADO B» | centrado em (960, 420) | Permanent Marker 120 px (`Tema.marcador()`), `Tema.TINTA`, girado −3° |

A linha do tempo, em ms desde `T0`. As curvas são as do [05](../arte/05-movimento.md#as-curvas): `SAI` =
`Tween.TRANS_CUBIC`, `EASE_OUT`; `ENTRA` = `TRANS_CUBIC`, `EASE_IN`; `RETA` = `TRANS_LINEAR`.

| ms | Inteiro | Reduzido |
| --- | --- | --- |
| 0 | corte seco do placar para o deck, face A; o cassete pula 12 px para cima em 60 ms (`SAI`) e volta | corte seco, face A |
| 60 a 360 | o cassete sai na mão: escala 1,00 a 1,08 e y −40 px (`SAI`) | parado |
| 360 a 1080 | o giro: `scale.x = cos(PI * u)`, `u` de 0 a 1 (`RETA`); em `u` = 0,5 a face troca para B | em 690, corte seco para a face B no berço |
| 1080 a 1380 | entra: escala 1,08 a 1,00 e y de −40 a 0 (`ENTRA`) | parado |
| 1380 | o clunk: o cassete afunda 6 px por 2 quadros e volta | nada |
| 2000 | a caneta: «LADO B» aparece por recorte, da esquerda para a direita, em 400 ms, `RETA` (o [06](../arte/06-interface-e-texto.md#as-transições): nunca letra por letra) | o mesmo (não é escala nem rotação) |
| 4000 | corte seco para o intervalo | o mesmo |

**O intervalo** (estado `intervalo`): o salão 3D na luz `luz_da_secao(-1, true)`; a câmera na pose do lobby
(`[Vector3(0, 2.9, 14.2), Vector3(0, 0.55, 4.4)]`, os quatro nos pedestais, a forja atrás), com a lente da G05;
`salao.pedestais_no.visible` true; cada boneco ocupado no pedestal dele, `controlavel = false`, o gesto `emote-yes`
a cada 4 compassos, um lugar por vez. Em `main.gd` `_mostrar()` (linha 214), `"intervalo"` entra na lista de
`salao.pedestais_no.visible = qual in ["lobby", "podio"]` e no bloco `if qual == "lobby":` que põe cada boneco em
`salao.pedestais[l]` (vira `if qual in ["lobby", "intervalo"]:`); e `Musica.tocar(...)` recebe `"salao"` quando
`qual == "intervalo"`. Por cima, 2D:

- a etiqueta: `Desenho.etiqueta(Rect2(660, 60, 600, 150), Tema.SECAO[0], -1.0, true)`; «Lado B» em Permanent Marker
  72 px, `Tema.TINTA`, centrado em (960, 140); embaixo, `partida.rotulo()` em VT323 46, `Tema.TINTA_SUAVE`, centrado
  em (960, 190);
- a dica: `Desenho.dica(self, pos, "cruz", "Seguir")`, centrada em y 1000.

O pós da fita (G15) continua gasto pela faixa em que a noite está; virar não zera.

## O som

O encanamento, igual nas fichas G09, G11, G12 e G16: copiar cada `<id>.wav` usado de `godot/estudos/direcao/som/`
para `godot/assets/sons/<id>.wav`; `Som.tocar(nome, ...)` e `Som.no_controle(lugar, nome, ...)` tocam primeiro
`res://assets/sons/<nome>.wav` quando ele existe, sem o tom sorteado de ±5 % dos gravados; a linha do mapa ganha
`arquivo` = `godot/assets/sons/<id>.wav` e `estado` = `no jogo`. Se outra ficha já fez a mudança em `som.gd`, use-a
sem mudar. A V05 depois troca as tabelas do `Som` pelo mapa.

| evento | id do [mapa](../audio/mapa.csv) | quando | onde |
| --- | --- | --- | --- |
| a fita para | a música: `Musica.calar()` | `T0` | — |
| o virar | `fx_virar` (1600 ms: eject em 0, plástico, clunk em 1380) | `T0` | TV a −6 dB |
| a caneta | `fx_caneta` (400 ms) | `T0` + 2000 ms | TV a −6 dB |
| o intervalo | a música do salão (`Musica.tocar("salao")`, o slot `MUS_TELA_SALAO`) | no corte de 4000 ms | — |
| ✕ no intervalo | `ui_confirma` | no quadro do botão | `Som.ui(l, "ui_confirma")` (G11) |
| ◀ ▶ nas linhas novas | `ui_tique` | como toda linha das Opções | o som dos menus da G11 |

## O controle

A sensação `"fita"` entra na tabela da F05: `"fita": [0.0, 0.3, 400]` (o rumble fraco a 0,3 do
[03](../arte/03-som.md#o-som-das-fichas-g)); o virar pede 1600 ms.

| evento | vibração | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- |
| `T0`, o virar | `Forja.sentir(l, "fita", 1600)` em todos os ocupados | `Forja.gatilhos_off(l)` em todos | a cor do lugar, parada | nada | não se usa |
| o intervalo | nada | Off | a cor do lugar | nada | não se usa |
| ✕ no intervalo | `Forja.sentir(l, "toque")` só em quem apertou | Off; a sala seguinte aplica o dela em `comecar()` | não muda | `ui_confirma` | não se usa |
| ◀ ▶ em Movimento e Reações | `Forja.sentir(quem, "toque")` | não muda | não muda | `ui_tique`, pelo `Som.ui(quem, "ui_tique")` da G11 | não se usa |

Prova sem o controle na mão: o robô aperta ✕ pelo controle simulado; a prova conta no registro, por lugar ocupado,
1 linha `{"tipo": "sensacao", "nome": "fita", "ms": 1600}` no virar e 1 `"toque"` só no lugar que apertou ✕.

## O cavaleiro

Nenhum stat muda o virar nem o intervalo. Cada cavaleiro fica no pedestal dele com a peça que montou, o contorno e o
anel do dono (G15); no Reduzido, sem o corpo que abaixa no tempo.

## As reações

O virar e o intervalo não disparam carimbo. O adesivo pelo touchpad vale no intervalo
([09](../arte/09-reacoes.md#quando-o-jogador-manda)) quando a ficha das reações existir, e obedece a
`Opcoes.reacao_do_jogador()`.

## A diversão

O momento é a fita que entra de volta: o clunk, e o grupo levanta para pegar água.

- **O `nome` do momento:** `fita_virada`. No clunk (`T0` + 1380 ms), o jogo escreve
  `Forja.evento("momento", 0, {"slot": "virar", "nome": "fita_virada", "lugar": -1, "ms_desde_o_corte": 1380})`.
- **A janela:** do corte (`T0`) ao ✕, sem limite; o virar em si, 4000 ms. O robô confere que o momento chega entre
  1380 e 1400 ms depois do corte.
- **A mesa:** a padrão (P1 `bom`, P2 e P3 `medio`, P4 `ruim`), semente 7, numa noite de 5 faixas: o virar depois da
  3ª; o robô aperta ✕ no intervalo depois de 2 s.
- **O rastro na prancha:** a prancha da noite (480×270 a cada 2 s, 6 colunas) mostra um quadro do deck com «LADO B»
  escrito e um do salão na luz do lado B, entre a faixa 3 e a 4.

## Pronto quando

Uma noite de 5 faixas vira a fita depois da 3ª, em 4000 ms, e para no intervalo até um ✕; as faixas 4 e 5 entram na
luz do lado B e com a tarja dupla; «Movimento: Reduzido» troca o giro por corte e cala o tremor, o giro do título e o
confete a um quarto; «Reações» grava as três escolhas; um `opcoes.cfg` antigo com `tremor = false` abre como
Reduzido.

## Provas

- `bash tests/prova_do_jogo.sh`, com estas checagens novas em `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  var cfg := ConfigFile.new()
  cfg.set_value("sessao", "tremor", false)
  cfg.save("user://opcoes_antigo.cfg")
  Opcoes.de_fabrica()
  Opcoes.ler("user://opcoes_antigo.cfg")
  _esperar(Opcoes.movimento == 1, "opções: o tremor desligado antigo vira Reduzido")
  _esperar(Opcoes.parada(2) == 0 and is_equal_approx(Opcoes.esmagar(1.3), 1.05), "movimento: sem parada, squash até 5 %")
  _esperar(Opcoes.confete(22) == 6, "movimento: o confete a um quarto")
  Opcoes.reacoes = 1
  _esperar(not Opcoes.reacao_do_jogador() and Opcoes.reacao_do_jogo(), "reações: só do jogo")
  Opcoes.de_fabrica()
  var p := Partida.new()
  p.salas = ["prova", "a", "b", "c", "d"]
  p.passo = 3
  _esperar(p.lado() == "B", "partida: a 4ª faixa de 5 é lado B")
  ```

  E a noite do robô (5 faixas, semente 7): o estado `intervalo` aparece uma vez, depois do placar da 3ª; o momento
  `fita_virada` entre 1380 e 1400 ms do corte; as sensações acima; o mesmo placar final com `movimento` 0 e 1.
- Leitura dos scripts, na mesma prova: nenhum `Opcoes.tremor` em `godot/scripts/` e `godot/testes/`; todo arquivo
  com `speed_scale = 0.0` também chama `Opcoes.parada(`.
- `bash tests/prova_visual.sh`: as Opções com 11 linhas em 1,0× e 1,15×, em português e em inglês, a linha Idioma
  escolhida inteira à vista; os quadros do virar em 0, 720, 1380 e 2400 ms, no Inteiro e no Reduzido; o intervalo.
- `python3 scripts/check_texto_de_tela.py` e `bash scripts/portoes/rodar.sh`: as frases novas com maiúscula, `fx_virar`
  e `fx_caneta` com `estado` `no jogo` no mapa.

## Passos

1. `Opcoes.movimento`, a migração, as três ajudas; `main.gd:929`, 986, 497 e `captura_jogo.gd:43`.
2. `Opcoes.reacoes` e as duas funções.
3. As duas linhas nas Opções, a lista que desliza, as traduções.
4. A sensação `"fita"`, o encanamento do som, os dois wav.
5. `TelaVirar`, `_virar_a_fita`, o intervalo, `partida.virou`.
6. O lado B nas chamadas de `acender` e de `Desenho.etiqueta`.
7. Os itens da tabela do 10 cujas fichas donas já estão feitas.

## Armadilhas

- **O ✕ do placar e o ✕ do intervalo:** o mesmo botão em dois quadros seguidos pula o intervalo. O intervalo só
  aceita ✕ depois de 500 ms e de o botão ter sido solto.
- **O relógio da música para no eject:** o virar conta em `Time.get_ticks_msec()` desde `T0`, não em `Ritmo`. O
  `Ritmo` volta com a música do salão no intervalo; a calibração (`Opcoes.tempo_ms`) não muda.
- **O robô de prova grava opções nulas:** `gravar(robo)` não grava; a prova usa `user://opcoes_antigo.cfg` e apaga
  no fim.

## Não fazer

- Não desenhar os adesivos (é a ficha das reações, depois da prancha do item 3 da
  [PRODUÇÃO](../arte/PRODUCAO.md)).
- Não pôr tempo limite no intervalo, nem placar parcial nele.
- Não fazer o pico da luz (não há sinal de pico na música; fica com a G15).

## Ao terminar

Marcar G16 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(noite): a fita vira na metade, e as Opções ganham Movimento e Reações`.

## O que foi feito (leva 1, a-fita)

- **O virar da fita** (`ui/tela_virar.gd`, `main.gd`): depois da faixa `ceil(n / 2)` o ✕ do placar espera o próximo
  compasso da música (4 batidas; sem música, nada) e abre o virar de 4000 ms, sem botão: o deck, o cassete que sai,
  gira (face B em 720 ms), entra e afunda no clunk (1380 ms), a caneta escreve «LADO B» (2000 a 2400 ms) e o corte seco
  leva ao intervalo. `fx_virar` e `fx_caneta` tocam a −6 dB; a música cala; cada lugar ocupado sente `fita` por 1600 ms
  e tem os gatilhos desligados; o momento `fita_virada` sai com o `ms_desde_o_corte` medido.
- **O intervalo:** o salão na luz do lado B (`acender(-1, true)`), os bonecos nos pedestais, a etiqueta «Lado B» com
  `partida.rotulo()` e a dica da cruz, sem tempo limite. O ✕ de um lugar ocupado só vale depois de 500 ms; vibra
  `toque` só em quem apertou. Um gesto `emote-yes` por vez, a cada 4 compassos. As faixas seguintes entram no lado B
  (`acender(numero, partida.lado() == "B")`).
- **Movimento e Reações** (`opcoes.gd`): `movimento` (Inteiro, Reduzido) no lugar de `tremor`, com a migração do
  `opcoes.cfg` antigo (`tremor = false` abre como Reduzido); `reacoes` (Todas, Só do jogo, Nenhuma); as funções
  `reduzido`, `parada`, `esmagar`, `confete`, `reacao_do_jogador` e `reacao_do_jogo`. O tremor da câmera, o giro do
  título e o confete (22 vira 6) leem o Reduzido.
- **As Opções** (`tela_opcoes.gd`): 11 linhas, na ordem da ficha; o quadro nunca passa de 1000 px e a lista desliza
  (2400 px por segundo, salta no Reduzido), sempre parando com a linha escolhida inteira à vista; um glifo `cima` ou
  `baixo` marca o lado cortado.
- **O som e o controle:** a sensação `fita` (0,0 / 0,3 / 400 ms) em `forja.gd`; `som.gd` toca `res://assets/sons/<id>.wav`
  quando existe (sem o tom sorteado); os dois wav entraram em `godot/assets/sons/` e o mapa os põe `no jogo`.
- **Medida:** as Opções foram de 10 para 11 linhas, e o quadro de 1042 px para no máximo 1000 (a conta da ficha, 1114
  sem a lista que desliza); o portão de arte ficou em 35 achados, os mesmos da G15.
- **Provas** (`prova_do_jogo.gd`: `_prova_do_conforto`, `_prova_do_virar_pura`, `_prova_da_noite_da_fita`): a
  migração, as ajudas do Movimento, as Reações, a partida (`metade`, `lado`), a leitura dos scripts (nenhum
  `Opcoes.tremor`; todo `speed_scale = 0.0` com `Opcoes.parada`; o confete, o giro e o tremor leem o Reduzido), a lista
  que desliza, a pose do cassete em cada tempo nos dois modos e uma noite de 5 faixas do robô (o virar uma vez, 4000
  ms, o intervalo no lado B, o ✕ cedo demais que não vale, o momento entre 1380 e 1400 ms, a sensação `fita` nos quatro,
  o `toque` só no P1, a 4ª faixa no lado B). Mordeu, uma a uma: a migração; `parada`; o teto do `esmagar`; o confete
  a um quarto; as duas funções das Reações; `lado()` com `>`; `metade()` sem arredondar para cima; `QUADRO_MAX` 1200; a
  lista sem alvo de rolagem; o salto do Reduzido; a face B em 0,6; o clunk sem 6 px; o Reduzido com escala; o corte em
  900 ms; a guarda de 500 ms; a sensação `fita` de 1000 ms; sem `partida.virou`; a faixa 4 no lado A; o
  `ms_desde_o_corte` fixo; o `toque` trocado; o ✕ sem o virar; o confete, o giro e o tremor sem o Reduzido; um
  `Opcoes.tremor` e um `speed_scale = 0.0` plantados.
- **Fica para a G16b** ([G16b](G16b-o-que-a-g16-deixou-por-dependencia.md)): o desenho do `Desenho` (G01, G11), o
  `Som.ui`, a tarja dupla nas chamadas da noite, os itens da tabela do 10 sem dona pronta e a prova visual das telas.

### Escolhas minhas, para ela validar

- `T0` do virar é o próximo compasso (4 batidas) lido do tocador da música; o placar fica na tela até lá.
- `partida.virou` vira true na entrada do intervalo, não no ✕.
- O `ms_desde_o_corte` do momento é o medido (1380 ou pouco mais), não o fixo.
- O pódio não recebe a luz do lado B (só as salas e o intervalo).
- O gesto do intervalo repete a cada 16 batidas do `bpm` da faixa do salão.
- O ✕ do intervalo toca `confirma` (não há `Som.ui`); as linhas novas das Opções trocam sem som e sem `toque`.
- `partida.lado()`, `metade()` e `virou` são os mínimos; podem encontrar a versão da G12 no merge.
- O cassete e a etiqueta são desenhados à mão em `tela_virar.gd`; a coleta de retângulos da prova de tela fica desligada
  só enquanto o cassete está torcido.
- A lista das Opções só mostra linhas inteiras quando parada, e o Reduzido salta em vez de deslizar.
- O Reduzido também não gira o cassete: corta a face em 690 ms.

### Para o André (local)

- Jogar uma noite de 5 faixas com os controles: depois da 3ª, ver o cassete sair, girar, afundar e a caneta escrever
  «LADO B»; sentir o rumble fraco de 1,6 s; conferir que o ✕ rápido demais no intervalo não pula.
- Ver as faixas 4 e 5 na luz do lado B (chave mais fraca, névoa mais densa).
- Abrir as Opções (11 linhas): ▼ até Idioma e ▲ de volta, em 1,0× e 1,15× de texto, em português e em inglês; ver o
  deslize e o glifo; ligar o Reduzido e conferir o salto.
- No Reduzido: título sem giro, câmera sem tremor, confete a um quarto, virar em corte.
- Passar um `opcoes.cfg` antigo com `tremor = false` e ver o Reduzido ligado.

### Na conferência (leva 1, a-fita)

- As setas em Movimento e Reações passaram a dar `Forja.sentir(quem, "toque")`, como pede a tabela do controle (o toque
  não depende da G11); a prova conta os três toques em quem mexeu. O `ui_tique` dessas linhas fica com o `Som.ui` da
  G11 (G16b).
- A cruz do intervalo toca o id do mapa, `ui_confirma` (copiado para `godot/assets/sons/`, a linha do mapa em `no
  jogo`), pelo `Som.tocar`; só a rota pelo `Som.ui` fica para a G11. A escolha «toca `confirma`» acima saiu.
- O encanamento do `Som.no_controle` (tocar primeiro o `<id>.wav` inteiro) não entrou aqui: nenhum som da G16 vai ao
  controle, e o conjunto do cavaleiro já traz essa mudança no `som.gd`; no merge, vale a dele.
- O salto de 12 px do começo do virar não volta a 0 antes de subir: emenda nos −40 px da saída. Para ela validar.
