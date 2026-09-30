# O quadro

Uma ficha por linha, na ordem de trabalho. É o único arquivo que se
atualiza a cada entrega: o estado da ficha e o gasto real da sessão. O
método está em [Como trabalhar](../12-como-trabalhar.md); a base comum, na
[arquitetura](../13-arquitetura.md).

Estados: **a fazer**, **fazendo** (com o nome de quem pegou), **feito**
(com o commit). O gasto real é o que a sessão custou, em US$. A coluna
"depende de" diz o que precisa estar **feito** antes.


## F — A fundação

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [F00](F00-o-ambiente-da-sessao.md) | O ambiente da sessão | P | Sonnet | 1,5 | — | a fazer | — |
| [F01](F01-o-modo-bancada.md) | O Modo bancada | G | Opus | 3,5 | F00 | a fazer | — |
| [F02](F02-sem-metalinguagem.md) | Nenhuma frase metalinguística | M | Sonnet | 2,0 | F00, F01 | a fazer | — |
| [F03](F03-todo-minigame-fecha.md) | Todo minigame fecha | M | Opus | 3,0 | F00, F01 | a fazer | — |
| [F04](F04-p1-e-o-led.md) | O P1 da tela é o controle P1 | M | Opus | 3,0 | F00, F01 | a fazer | — |
| [F05](F05-o-haptico-forte.md) | O háptico forte | G | Opus | 3,5 | F00, F01 | a fazer | — |
| [F06](F06-o-registro-v2.md) | O registro v2 | G | Opus | 3,5 | F00, F01, F03, F04, F05 | a fazer | — |
| [F07](F07-a-voz-do-texto.md) | A voz nova do texto | M | Sonnet | 2,5 | F00, F02, F03 | a fazer | — |
| [F08](F08-a-paridade.md) | A paridade entre a prova e o jogo | M | Opus | 3,0 | F00, F01, F03 | a fazer | — |
| [F09](F09-a-prova-visual.md) | A prova visual | G | Opus | 4,0 | F00, F02 (a coleta de texto), F03 (o fim), F08 (o robô só pelo controle) | a fazer | — |

## G — As telas

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [G01](G01-titulo-e-introducao.md) | O título e a introdução | M | Sonnet | 2,5 | F00, F04, F07, F08, F09 | a fazer | — |
| [G02](G02-a-construcao-do-cavaleiro.md) | A construção do cavaleiro | G | Opus | 4,0 | F00, F04, F05, F06, F07, F08, G01, F09 | a fazer | — |
| [G03](G03-o-item-com-mecanica.md) | O item com mecânica | M | Opus | 3,0 | F00, F05, F06, G02, F09 | a fazer | — |
| [G04](G04-o-hud-de-cada-jogador.md) | O HUD de cada jogador | G | Sonnet | 3,5 | F00, F02, F07, F09, G02, G03 | a fazer | — |
| [G05](G05-a-camera-dos-quatro.md) | A câmera dos quatro | M | Sonnet | 2,5 | F00, F09 | a fazer | — |
| [G06](G06-o-salao-e-a-colecao.md) | O salão e a coleção | M | Sonnet | 2,5 | F00, G02, F09 | a fazer | — |
| [G07](G07-a-narrativa-leve.md) | A narrativa leve | P | Sonnet | 1,5 | F00, F07, G03, G04, G06, F09 | a fazer | — |
| [G08](G08-a-arte-bonecos-e-coerencia.md) | A arte: bonecos e coerência | G | Sonnet | 3,5 | F00, G01, G02, F09 | a fazer | — |

## H — O ritmo, o som e o kit

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [H01](H01-o-relogio-de-audio.md) | O relógio de áudio | M | Opus | 3,0 | F00 | a fazer | — |
| [H02](H02-as-janelas.md) | As janelas de julgamento | M | Opus | 3,0 | F00, H01 | a fazer | — |
| [H03](H03-a-calibracao.md) | A calibração | P | Sonnet | 2,0 | F00, H02 (e G02 para a medida automática — ver "Sem a G02") | a fazer | — |
| [H04](H04-o-kit-do-minigame.md) | O kit do minigame | G | Opus | 4,5 | F00, F03, F05, F08, F09, H01, H02 | a fazer | — |
| [H05](H05-o-pipeline-das-faixas.md) | O pipeline das faixas | M | Sonnet | 2,5 | F00, H01 | a fazer | — |
| [H06](H06-os-jingles.md) | Os jingles | P | Sonnet | 1,5 | F00, F03, H01, H04 | a fazer | — |
| [H07](H07-o-som-em-todo-evento.md) | O som em todo evento | G | Sonnet | 3,5 | F00, F05, F06, H04 | a fazer | — |
| [H08](H08-os-acrescimos-do-kit.md) | Os acréscimos do kit | G | Opus | 4,0 | H04, H01, H02, F03, F05, G03 | a fazer | — |

## I — [S1 — A Centelha: os cinco minigames](I-a-centelha.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [I1](I1-o-martelo-de-hefesto.md) | O Martelo de Hefesto | G | Sonnet | 2,0 | H04, H08, F09, F03, F05, H07, G05 | a fazer | — |
| [I2](I2-marcha-dos-escudeiros.md) | Marcha dos Escudeiros | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, I1 (o `secao.gd`) | a fazer | — |
| [I3](I3-portoes-de-neon.md) | Portões de Néon | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, I1 (o `secao.gd`) | a fazer | — |
| [I4](I4-o-fole.md) | O Fole | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, G03 (o L2 é do item), I1 (o `secao.gd`) | a fazer | — |
| [I5](I5-a-esteira-de-escoria.md) | A Esteira de Escória | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, I1 (o `secao.gd`) | a fazer | — |

## J — [S2 — A Viga: os cinco minigames](J-a-viga.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [J1](J1-a-viga.md) | A Viga | G | Sonnet | 2,0 | H04, H08, F09, F03, F05, H07, G05 | a fazer | — |
| [J2](J2-pendulos-do-caos.md) | Pêndulos do Caos | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, J1 (o `secao.gd`) | a fazer | — |
| [J3](J3-patinacao-de-dados.md) | Patinação de Dados | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, J1 (o `secao.gd`) | a fazer | — |
| [J4](J4-o-balao-dos-foles.md) | O Balão dos Foles | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, J1 (o `secao.gd`) | a fazer | — |
| [J5](J5-mira-optica.md) | Mira Óptica | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, G03 (o L2 é do item), J1 (o `secao.gd`) | a fazer | — |

## K — [S3 — O Molde: os cinco minigames](K-o-molde.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [K1](K1-o-molde.md) | O Molde | G | Sonnet | 2,0 | H04, H08, F09, F03, F05, H07, G05 | a fazer | — |
| [K2](K2-quebra-gelo.md) | Quebra-Gelo | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | a fazer | — |
| [K3](K3-hackeando-o-terminal.md) | Hackeando o Terminal | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | a fazer | — |
| [K4](K4-a-pinca.md) | A Pinça | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | a fazer | — |
| [K5](K5-o-carimbo.md) | O Carimbo | M | Sonnet | 1,5 | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | a fazer | — |

## L — [S4 — O Impacto: os cinco minigames](L-o-impacto.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [L1](L1-o-cerco.md) | O Cerco | G | Sonnet | 2,0 | H04, H08, F09, F01, F04, F05, F06, H06, H07, G04, G05, G08 | a fazer | — |
| [L2](L2-fuga-do-tita.md) | Fuga do Titã | M | Sonnet | 1,5 | H04, H08, F09, L1 | a fazer | — |
| [L3](L3-curto-circuito.md) | Curto-Circuito | M | Sonnet | 1,5 | H04, H08, F09, L1 | a fazer | — |
| [L4](L4-martelos-termicos.md) | Martelos Térmicos | M | Sonnet | 1,5 | H04, H08, F09, L1, G08 | a fazer | — |
| [L5](L5-a-prensa.md) | A Prensa | M | Sonnet | 1,5 | H04, H08, F09, L1 | a fazer | — |

## M — [S5 — A Galeria: os cinco minigames](M-a-galeria.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [M1](M1-a-galeria.md) | A Galeria | G | Sonnet | 2,0 | H04, H08, F09, F01, F04, F05, F06, H06, H07, G03, G08 | a fazer | — |
| [M2](M2-arco-de-neon.md) | Arco de Néon | M | Sonnet | 1,5 | H04, H08, F09, M1 | a fazer | — |
| [M3](M3-metralhadora-de-feiticos.md) | Metralhadora de Feitiços | M | Sonnet | 1,5 | H04, H08, F09, M1 | a fazer | — |
| [M4](M4-espada-de-fita.md) | Espada de Fita | M | Sonnet | 1,5 | H04, H08, F09, M1 | a fazer | — |
| [M5](M5-a-catapulta.md) | A Catapulta | M | Sonnet | 1,5 | H04, H08, F09, M1 | a fazer | — |

## N — [S6 — O Canto: os cinco minigames](N-o-canto.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [N1](N1-o-canto.md) | O Canto | G | Sonnet | 2,0 | H04, H08, F09, F01, F02, F05, H06, H07, G08 | a fazer | — |
| [N2](N2-eco-do-abismo.md) | Eco do Abismo | M | Sonnet | 1,5 | H04, H08, F09, N1 | a fazer | — |
| [N3](N3-coral-dos-quatro.md) | Coral dos Quatro | M | Sonnet | 1,5 | H04, H08, F09, N1, H07 | a fazer | — |
| [N4](N4-codigo-do-dragao.md) | Código do Dragão | M | Sonnet | 1,5 | H04, H08, F09, N1, H07 | a fazer | — |
| [N5](N5-corta-fio.md) | Corta-Fio | M | Sonnet | 1,5 | H04, H08, F09, N1, H07 | a fazer | — |

## O — [S7 — Os Caminhos: os cinco minigames](O-os-caminhos.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [O1](O1-os-caminhos.md) | Os Caminhos | G | Sonnet | 2,0 | H04, H08, F09, F01, H07, G08 | a fazer | — |
| [O2](O2-neblina-de-dados.md) | Neblina de Dados | M | Sonnet | 1,5 | H04, H08, F09, H07, O1 | a fazer | — |
| [O3](O3-passo-no-fosso.md) | Passo no Fosso | M | Sonnet | 1,5 | H04, H08, F09, H07, O1 | a fazer | — |
| [O4](O4-fuga-do-mecha-cego.md) | Fuga do Mecha Cego | M | Sonnet | 1,5 | H04, H08, F09, H07, O1 | a fazer | — |
| [O5](O5-engrenagens-sincopadas.md) | Engrenagens Sincopadas | M | Sonnet | 1,5 | H04, H08, F09, H07, G03, G05, O1 | a fazer | — |

## P — [S8 — A Voz: os cinco minigames](P-a-voz.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [P1](P1-a-voz.md) | A Voz | G | Sonnet | 2,0 | H04, H08, F09, F01, H07, G08 | a fazer | — |
| [P2](P2-o-sopro-no-fole.md) | O Sopro no Fole | M | Sonnet | 1,5 | H04, H08, F09, H07, P1 | a fazer | — |
| [P3](P3-zero-absoluto.md) | Zero Absoluto | M | Sonnet | 1,5 | H04, H08, F09, H07, G08, P1 | a fazer | — |
| [P4](P4-grito-de-guerra.md) | Grito de Guerra | M | Sonnet | 1,5 | H04, H08, F09, H07, P1 | a fazer | — |
| [P5](P5-palmas-da-forja.md) | Palmas da Forja | M | Sonnet | 1,5 | H04, H08, F09, H07, P1 | a fazer | — |

## Q — [S9 — A Prova: os cinco minigames](Q-a-prova.md)

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [Q1](Q1-a-prova.md) | A Prova | G | Sonnet | 2,0 | H04, H08, F09, F01, F04, H07, G03, O1 | a fazer | — |
| [Q2](Q2-roubo-de-bateria.md) | Roubo de Bateria | M | Sonnet | 1,5 | H04, H08, F09, H07, G03, Q1 | a fazer | — |
| [Q3](Q3-mecha-de-dois-pilotos.md) | Mecha de Dois Pilotos | M | Sonnet | 1,5 | H04, H08, F09, H07, G03, Q1 | a fazer | — |
| [Q4](Q4-ruge-o-reator.md) | Ruge o Reator | G | Sonnet | 2,0 | H04, H08, F09, H07, G03, Q1, O1 (o `_pista`), e as seções S1 a S4 prontas (as mecânicas que as estações resumem) | a fazer | — |
| [Q5](Q5-o-ultimo-acorde.md) | O Último Acorde | G | Sonnet | 2,0 | H04, H08, F09, H07, G03, Q1, Q4, O1 (o `_pista`), P1 (o ouvido), e as seções S5 a S8 prontas | a fazer | — |

## R — O Relâmpago

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [R](R-o-relampago.md) | O Relâmpago | G | Sonnet | 3,5 | H04, F09, H07, G03, as seções I a Q prontas (os 45 no catálogo), Q4 e Q5 (as estações que se copiam), O2 (a pedra), P1 (o ouvido) | a fazer | — |

## S — A noite de seis horas

| ficha | título | tamanho | modelo | estimativa (US$) | depende de | estado | gasto real |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [S](S-a-noite-de-seis-horas.md) | A noite de seis horas | M | Sonnet | 3,0 | F06 (o registro v2), F09, H07, as seções I a Q e a R prontas; a O1 e a P1 (as linhas `pista`, `troca`, `voz` no 13); e, com o André, a noite em si | a fazer | — |

## A soma

**Estimativa total:** US$ 156,0 — F 29,5 · G 23,0 · H 24,0 · I–Q (os 45 minigames) 73,0 · R 3,5 · S 3,0.
Com o retrabalho, a faixa está em [Como trabalhar](../12-como-trabalhar.md#o-orçamento).

## A ordem

F primeiro, na ordem da tabela: a F00 prepara a sessão, a F01 abre o Modo
bancada que as outras usam. G e H podem andar juntas, respeitando a coluna
"depende de". Os minigames vêm depois da H08, uma seção por vez, de I a Q;
dentro de cada seção, o n.º 1 primeiro (ele cria o cenário comum). R depois
das seções, S por último.

## Criar uma ficha nova

Copie uma ficha pronta (a [F01](F01-o-modo-bancada.md) é um bom modelo) e
mantenha as seções: por quê, ler antes, o estado de hoje (com
`caminho:linha` e o trecho do código), o alvo (pela
[arquitetura](../13-arquitetura.md)), passos, armadilhas, não fazer, pronto
quando, provas, para o André, ao terminar. A primeira linha depois do título
diz sprint, tamanho, modelo, estimativa e dependências. Ponha uma linha neste
quadro. Para minigame, use o [molde de minigame](molde-de-minigame.md).
