# I — S1 — A Centelha: os cinco minigames

**Sprint:** I · **Seção:** S01 · **Fichas:** I1 a I5 · **Modelo:** Sonnet · **Soma:** US$ 8,0 (I1 G, 2,0; I2 a I5 M, 1,5 cada)

O índice da seção. Cada minigame tem a sua ficha, que se executa sozinha
numa sessão; esta página diz o que os cinco têm em comum.

## A feature protagonista

**Botões, analógicos e gatilhos analógicos** — a entrada do controle. É a
seção de abertura da noite: o tempo forte é explícito, o andamento moderado,
o erro custa pouco. Coadjuvantes em todos os cinco: vibração em todo golpe
(o kit), a nota de cada um no alto-falante do controle (o kit, H07), a barra
de luz na cor do lugar, que pisca no perfeito e escurece no erro.

## O cenário comum: a forja

Um arquivo só, criado pela I1 e usado pelos cinco:
`godot/scripts/minigames/s01/secao.gd` (sem `class_name`; quem usa escreve
`const SECAO := preload("res://scripts/minigames/s01/secao.gd")`).

| função | o que faz |
| --- | --- |
| `SECAO.montar(sala)` | `Kit.arena(sala, 5, 3)`; `atmosfera(Color("#ff9a52"), Tema.ROSA, true, 60)` (brasas subindo, o neon rosa); as três tochas; no fundo, `column` nos quatro cantos, três `banner`, dois `wood-support`, `barrel` e `pot` nas laterais, e o brilho laranja da fornalha em `(0, 1.2, -6)` |
| `SECAO.piscar(sala, l, julgamento)` | a barra de luz do lugar: branco por 0,12 s no perfeito; a cor do lugar a 40% por 0,5 s no erro (F04: nunca abaixo de 30%, nunca mais de 0,5 s fora da cor) |
| `SECAO.voltar_a_luz(sala)` | a cor do lugar volta; a primeira linha de todo `jogar()` |

O código inteiro está na [I1](I1-o-martelo-de-hefesto.md#o-cenário).

## As convenções da seção

Valem para os cinco; cada ficha já as traz escritas no código dela.

- **As notas moram em batidas.** Nenhuma ficha escreve segundos:
  `Ritmo.t_da_batida(b)`. O andamento vem do mapa da faixa
  (`Musica.mapa(faixa).bpm`): até a H05 trazer as faixas geradas, as cinco
  tocam a trilha sintetizada da seção, a 108 bpm; com as faixas, 110 a 135
  (o [04](../04-ritmo-e-audio.md#as-45-faixas)). As contas de "quantas notas"
  de cada ficha dão os dois.
- **O hoqueto em colcheias:** a nota do lugar `l` cai na batida
  `2k + 0,5·l` (P1 no 1 e no 3, P2 meio tempo depois, P3 no 2 e no 4, P4 no
  "e" do 2 e do 4). A partitura simples (`Ritmo.simples[l]`) passa para uma
  nota a cada 4 tempos, na mesma fração.
- **A contagem:** as batidas 0 a 3 são a entrada (H06); a primeira nota é a
  batida 4 (`BATIDA_DA_PRIMEIRA_NOTA`).
- **O pico no meio:** pela fração do jogo que vale, `t_jogo / duracao`
  (F03): de 1/3 a 2/3.
- **A barra de luz:** `SECAO.piscar` no `toque` e na `falha`,
  `SECAO.voltar_a_luz` no `jogar`. As luzinhas de jogador nunca mudam.
- **O alto-falante do dono:** no perfeito, a nota do lugar (o kit); nos
  outros acertos, o som pequeno do minigame (`Som.no_controle`); no erro, a
  nota quebrada (o kit). Nunca dois ao mesmo tempo.
- **A contagem para a prova:** todo minigame guarda
  `contagem[lugar][julgamento]` (como o minigame de prova da H04); a prova
  lê.
- **O gatilho:** o R2 é do minigame, o L2 é do item (G03). Quem mexe no R2
  solta só o R2 (`Forja.gatilho(l, 1, Forja.GATILHO_OFF)`), nunca
  `gatilhos_off`.

## A ordem

1. **[I1](I1-o-martelo-de-hefesto.md)** primeiro: reescreve a sala de hoje
   no ritmo e cria o `secao.gd`. As outras dependem dela.
2. **I2 a I5** em qualquer ordem, uma por sessão.

## Os cinco

| ficha | slot | gênero | verbo | o que a mão faz | tamanho | modelo | estimativa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [I1 — O Martelo de Hefesto](I1-o-martelo-de-hefesto.md) | S01_J01 | TcT | "Bata!" | aperta o botão da runa na nota (e gira o analógico, e enche o fole) | G | Sonnet | 2,0 |
| [I2 — Marcha dos Escudeiros](I2-marcha-dos-escudeiros.md) | S01_J02 | corrida | "Marche!" | empurra o analógico esquerdo e o direito para a frente, alternados, no bumbo | M | Sonnet | 1,5 |
| [I3 — Portões de Néon](I3-portoes-de-neon.md) | S01_J03 | corrida | "Passe!" | um toque de ✕ no instante em que o portão bate | M | Sonnet | 1,5 |
| [I4 — O Fole](I4-o-fole.md) | S01_J04 | coop | "Sopre a forja!" | afunda o R2 até a altura da sua nota e segura | M | Sonnet | 1,5 |
| [I5 — A Esteira de Escória](I5-a-esteira-de-escoria.md) | S01_J05 | sabotagem | "Prense!" | aperta o botão do lingote na sua vez, ou antes do dono para roubar | M | Sonnet | 1,5 |

## O que o registro mede

Por baixo, sem perguntar nada ao jogador ([03](../03-os-45-minigames.md#s1--a-centelha--botões-analógicos-gatilhos-analógicos)):
cada botão, analógico e gatilho pedido, com o instante do pedido (a linha
`nota`) e o da resposta (a linha `toque`, com o desvio); o curso do gatilho
analógico; o botão que ficou sem resposta a noite toda. As medidas do
núcleo (`Forja.med_*`) e os vereditos da bancada ficam **só** na I1, como
hoje; os outros quatro gravam o que é deles na linha `entrada` (o tipo que
A Centelha de hoje já grava, `godot/scripts/salas/centelha.gd:286`).

## Antes de começar: o que ainda falta na base

- **O sorteio dentro da seção.** A partida e o salão abrem a seção pelo
  apelido (`centelha`), que o catálogo resolve para o primeiro minigame.
  Nenhuma ficha da base faz a partida sortear **qual** dos cinco; sem isso,
  I2 a I5 só abrem por `--sala=S01_J0n` e não aparecem na prova visual da
  partida. As fichas I2 a I5 dependem dessa peça: se ela não existir, a
  sessão faz tudo, deixa a prancha pendente e diz isso no fim.
- **O ícone.** A `FICHA.icone` é o nome de um glifo de `godot/assets/glifos/`
  (a F02 confere). Se o kit ainda não copia a `FICHA.icone` para
  `SalaJogo.icone`, a primeira linha do `montar()` é `icone = str(ficha.icone)`.
