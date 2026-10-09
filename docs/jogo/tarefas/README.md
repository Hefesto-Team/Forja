# O quadro

Uma ficha por linha, na ordem de trabalho. É o único arquivo que se
atualiza a cada entrega: o estado da ficha. O
método está em [Como trabalhar](../12-como-trabalhar.md); a base comum, na
[arquitetura](../13-arquitetura.md).

Estados: **a fazer**, **fazendo** (com o nome de quem pegou), **feito**
(com o commit). A coluna
"depende de" diz o que precisa estar **feito** antes.



## F — A fundação

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [F00](F00-o-ambiente-da-sessao.md) | O ambiente da sessão | P | — | feito |
| [F01](F01-o-modo-bancada.md) | O Modo bancada | G | F00 | feito |
| [F02](F02-sem-metalinguagem.md) | Nenhuma frase metalinguística | M | F00, F01 | feito |
| [F03](F03-todo-minigame-fecha.md) | Todo minigame fecha | M | F00, F01 | feito |
| [F04](F04-p1-e-o-led.md) | O P1 da tela é o controle P1 | M | F00, F01 | feito |
| [F05](F05-o-haptico-forte.md) | O háptico forte | G | F00, F01 | feito |
| [F06](F06-o-registro-v2.md) | O registro v2 | G | F00, F01, F03, F04, F05 | feito |
| [F07](F07-a-voz-do-texto.md) | A voz nova do texto | M | F00, F02, F03 | feito |
| [F08](F08-a-paridade.md) | A paridade entre a prova e o jogo | M | F00, F01, F03 | feito |
| [F09](F09-a-prova-visual.md) | A prova visual | G | F00, F02 (a coleta de texto), F03 (o fim), F08 (o robô só pelo controle) | feito |
| [F09b](F09b-os-achados-da-prova-visual.md) | Os achados da primeira prova visual | M | F09 | a fazer |
| [F10](F10-o-rumble-seco.md) | O rumble seco | G | F05 (a medição do háptico), F06 (o registro) | espera o André (a parte A feita: o roteiro às cegas) |

## G — As telas

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [G01](G01-titulo-e-introducao.md) | O título e a introdução | M | F00, F04, F07, F08, F09 | pronta |
| [G02](G02-a-construcao-do-cavaleiro.md) | A construção do cavaleiro | G | F00, F04, F05, F06, F07, F08, G01, F09 | pronta |
| [G03](G03-o-item-com-mecanica.md) | O item com mecânica | M | F00, F05, F06, G02, F09 | pronta |
| [G04](G04-o-hud-de-cada-jogador.md) | O HUD de cada jogador | G | F00, F02, F07, F09, G02, G03 | pronta |
| [G05](G05-a-camera-dos-quatro.md) | A câmera dos quatro | M | F00, F09 | pronta |
| [G06](G06-o-salao-e-a-colecao.md) | O salão e a coleção | M | F00, G02, F09 | pronta |
| [G07](G07-a-narrativa-leve.md) | A narrativa leve | P | F00, F07, G03, G04, G06, F09 | pronta |
| [G08](G08-a-arte-bonecos-e-coerencia.md) | A arte: bonecos e coerência | G | F00, G01, G02, F09 | pronta |
| [G09](G09-o-teclado-do-nome.md) | O teclado de tela para o nome | M | F00, F07, F08, F09, G02 | pronta |
| [G10](G10-a-biblioteca-kenney.md) | A biblioteca Kenney | G | F00, G08 (a parte A e o `scripts/conferir_bonecos.py`) | pronta |
| [G11](G11-a-interface-com-o-ui-pack.md) | A interface com o UI Pack e os prompts | M | F00, F07, F09, G04, G10 | pronta |
| [G12](G12-a-apresentacao-do-minigame.md) | A apresentação do minigame | M | H04, H06, G08, G11, F07, F09 | pronta |
| [G13](G13-o-cavaleiro-montavel.md) | O cavaleiro montável | G | F00, F07, F09, G02, G10, G14 | pronta |
| [G14](G14-a-cor-e-a-letra-da-fita.md) | A cor e a letra da Fita | M | F00, F09 | pronta |
| [G15](G15-a-luz-o-pos-e-o-brilho-com-dono.md) | A luz, o pós e o brilho com dono | G | F00, F09, G14 | pronta |
| [G16](G16-o-virar-da-fita-e-o-conforto.md) | O virar da fita, o movimento e as reações nas Opções | M | F00, F07, F09, G14 | pronta |

## H — O ritmo, o som e o kit

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [H01](H01-o-relogio-de-audio.md) | O relógio de áudio | M | F00 | feito |
| [H02](H02-as-janelas.md) | As janelas de julgamento | M | F00, H01 | feito |
| [H03](H03-a-calibracao.md) | A calibração | P | F00, H02 (e G02 para a medida automática — ver "Sem a G02") | feito, sem a medida automática da G02 |
| [H04](H04-o-kit-do-minigame.md) | O kit do minigame | G | F00, F03, F05, F08, F09, H01, H02 | a fazer |
| [H05](H05-o-pipeline-das-faixas.md) | O pipeline das faixas | M | F00, H01 | feito |
| [H06](H06-os-jingles.md) | Os jingles | P | F00, F03, H01, H04, H05 | a fazer |
| [H07](H07-o-som-em-todo-evento.md) | O som em todo evento | G | F00, F05, F06, H04 | a fazer |
| [H08](H08-os-acrescimos-do-kit.md) | Os acréscimos do kit | G | H04, H01, H02, F03, F05, G03 | a fazer |
| [H09](H09-o-gerador-da-trilha.md) | O gerador da trilha | M | F00, H05 | feito |
| [H10](H10-a-bancada-da-trilha.md) | A bancada da trilha | M | H05, H09 | feito |

## I — [S1 — A Centelha: os cinco minigames](I-a-centelha.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [I1](I1-o-martelo-de-hefesto.md) | O Martelo de Hefesto | G | H04, H08, F09, F03, F05, H07, G05, G12 | pronta |
| [I2](I2-marcha-dos-escudeiros.md) | Marcha dos Escudeiros | M | H04, H08, F09, F03, H07, I1 (o `secao.gd`) | pronta |
| [I3](I3-portoes-de-neon.md) | Portões de Néon | M | H04, H08, F09, F03, H07, I1 (o `secao.gd`) | pronta |
| [I4](I4-o-fole.md) | O Fole | M | H04, H08, F09, F03, H07, G03 (o L2 é do item), I1 (o `secao.gd`) | pronta |
| [I5](I5-a-esteira-de-escoria.md) | A Esteira de Escória | M | H04, H08, F09, F03, H07, I1 (o `secao.gd`) | pronta |

## J — [S2 — A Viga: os cinco minigames](J-a-viga.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [J1](J1-a-viga.md) | A Viga | G | H04, H08, F09, F03, F05, H07, G05, G12 | pronta |
| [J2](J2-pendulos-do-caos.md) | Pêndulos do Caos | M | H04, H08, F09, F03, H07, J1 (o `secao.gd`) | pronta |
| [J3](J3-patinacao-de-dados.md) | Patinação de Dados | M | H04, H08, F09, F03, H07, J1 (o `secao.gd`) | pronta |
| [J4](J4-o-balao-dos-foles.md) | O Balão dos Foles | M | H04, H08, F09, F03, H07, J1 (o `secao.gd`) | pronta |
| [J5](J5-mira-optica.md) | Mira Óptica | M | H04, H08, F09, F03, H07, G03 (o L2 é do item), J1 (o `secao.gd`) | pronta |

## K — [S3 — O Molde: os cinco minigames](K-o-molde.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [K1](K1-o-molde.md) | O Molde | G | H04, H08, F09, F03, F05, H07, G05, G12 | pronta |
| [K2](K2-quebra-gelo.md) | Quebra-Gelo | M | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | pronta |
| [K3](K3-hackeando-o-terminal.md) | Hackeando o Terminal | M | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | pronta |
| [K4](K4-a-pinca.md) | A Pinça | M | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | pronta |
| [K5](K5-o-carimbo.md) | O Carimbo | M | H04, H08, F09, F03, H07, K1 (o `secao.gd`) | pronta |

## L — [S4 — O Impacto: os cinco minigames](L-o-impacto.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [L1](L1-o-cerco.md) | O Cerco | G | H04, H08, F09, F01, F04, F05, F06, H06, H07, G04, G05, G08, G12 | pronta |
| [L2](L2-fuga-do-tita.md) | Fuga do Titã | M | H04, H08, F09, L1 | pronta |
| [L3](L3-curto-circuito.md) | Curto-Circuito | M | H04, H08, F09, L1 | pronta |
| [L4](L4-martelos-termicos.md) | Martelos Térmicos | M | H04, H08, F09, L1, G08 | pronta |
| [L5](L5-a-prensa.md) | A Prensa | M | H04, H08, F09, L1 | pronta |

## M — [S5 — A Galeria: os cinco minigames](M-a-galeria.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [M1](M1-a-galeria.md) | A Galeria | G | H04, H08, F09, F01, F04, F05, F06, H06, H07, G03, G08, G12 | pronta |
| [M2](M2-arco-de-neon.md) | Arco de Néon | M | H04, H08, F09, M1 | pronta |
| [M3](M3-metralhadora-de-feiticos.md) | Metralhadora de Feitiços | M | H04, H08, F09, M1 | pronta |
| [M4](M4-espada-de-fita.md) | Espada de Fita | M | H04, H08, F09, M1 | pronta |
| [M5](M5-a-catapulta.md) | A Catapulta | M | H04, H08, F09, M1 | pronta |

## N — [S6 — O Canto: os cinco minigames](N-o-canto.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [N1](N1-o-canto.md) | O Canto | G | H04, H08, F09, F01, F02, F05, H06, H07, G08, G12 | pronta |
| [N2](N2-eco-do-abismo.md) | Eco do Abismo | M | H04, H08, F09, N1 | pronta |
| [N3](N3-coral-dos-quatro.md) | Coral dos Quatro | M | H04, H08, F09, N1, H07 | pronta |
| [N4](N4-codigo-do-dragao.md) | Código do Dragão | M | H04, H08, F09, N1, H07 | pronta |
| [N5](N5-corta-fio.md) | Corta-Fio | M | H04, H08, F09, N1, H07 | pronta |

## O — [S7 — Os Caminhos: os cinco minigames](O-os-caminhos.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [O1](O1-os-caminhos.md) | Os Caminhos | G | H04, H08, F09, F01, H07, G08, G12 | pronta |
| [O2](O2-neblina-de-dados.md) | Neblina de Dados | M | H04, H08, F09, H07, O1 | pronta |
| [O3](O3-passo-no-fosso.md) | Passo no Fosso | M | H04, H08, F09, H07, O1 | pronta |
| [O4](O4-fuga-do-mecha-cego.md) | Fuga do Mecha Cego | M | H04, H08, F09, H07, O1 | pronta |
| [O5](O5-engrenagens-sincopadas.md) | Engrenagens Sincopadas | M | H04, H08, F09, H07, G03, G05, O1 | pronta |

## P — [S8 — A Voz: os cinco minigames](P-a-voz.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [P1](P1-a-voz.md) | A Voz | G | H04, H08, F09, F01, H07, G08, G12 | pronta |
| [P2](P2-o-sopro-no-fole.md) | O Sopro no Fole | M | H04, H08, F09, H07, P1 | pronta |
| [P3](P3-zero-absoluto.md) | Zero Absoluto | M | H04, H08, F09, H07, G08, P1 | pronta |
| [P4](P4-grito-de-guerra.md) | Grito de Guerra | M | H04, H08, F09, H07, P1 | pronta |
| [P5](P5-palmas-da-forja.md) | Palmas da Forja | M | H04, H08, F09, H07, P1 | pronta |

## Q — [S9 — A Prova: os cinco minigames](Q-a-prova.md)

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [Q1](Q1-a-prova.md) | A Prova | G | H04, H08, F09, F01, F04, H07, G03, O1, G12 | pronta |
| [Q2](Q2-roubo-de-bateria.md) | Roubo de Bateria | M | H04, H08, F09, H07, G03, Q1 | pronta |
| [Q3](Q3-mecha-de-dois-pilotos.md) | Mecha de Dois Pilotos | M | H04, H08, F09, H07, G03, Q1 | pronta |
| [Q4](Q4-ruge-o-reator.md) | Ruge o Reator | G | H04, H08, F09, H07, G03, Q1, O1 (o `_pista`), e as seções S1 a S4 prontas (as mecânicas que as estações resumem) | pronta |
| [Q5](Q5-o-ultimo-acorde.md) | O Último Acorde | G | H04, H08, F09, H07, G03, Q1, Q4, O1 (o `_pista`), P1 (o ouvido), e as seções S5 a S8 prontas | pronta |

## R — O Relâmpago

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [R](R-o-relampago.md) | O Relâmpago | G | H04, F09, H07, G03, as seções I a Q prontas (os 45 no catálogo), Q4 e Q5 (as estações que se copiam), O2 (a pedra), P1 (o ouvido) | pronta |

## S — A noite de seis horas

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [S](S-a-noite-de-seis-horas.md) | A noite de seis horas | M | F06 (o registro v2), F09, H07, as seções I a Q e a R prontas; a O1 e a P1 (as linhas `pista`, `troca`, `voz` no 13); e, com o André, a noite em si | pronta |

## V — A varredura

Achados da varredura do arquiteto e DevOps (08/10/2026): o que trava a esteira, o que passa verde sem estar certo, o
que está escrito em dois lugares. São base: vão de **a fazer** direto para **em voo**.

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [V01](V01-a-engine-conferida.md) | A engine conferida, num passo só | P | — | a fazer |
| [V02](V02-a-prova-do-jogo-em-partes.md) | A prova do jogo em partes | G | F08, F09 | a fazer |
| [V03](V03-o-texto-de-tela-inteiro.md) | O texto de tela inteiro, e a tabela em partes | G | F07, F08 | a fazer |
| [V04](V04-as-secoes-num-lugar-so.md) | As seções num lugar só | M | H04, H08, F09 | a fazer |
| [V05](V05-o-som-pelo-mapa.md) | O Som pelo mapa do áudio | M | H06, H07, o mapa do áudio publicado | a fazer |
| [V06](V06-as-provas-que-ninguem-roda.md) | As provas que ninguém roda | P | — | a fazer |
| [V07](V07-o-codigo-sem-uso.md) | O código sem uso | P | F05, F10 | a fazer |
| [V08](V08-os-portoes-de-arte-e-som-reprovam.md) | Os portões de arte e som reprovam | M | a bíblia aprovada (o ESPERA-ELA), a G14, V05, o mapa do áudio com os arquivos | a fazer |

## X — Os módulos

As extrações do [15 — Os módulos importáveis](../15-os-modulos.md), na ordem de lá. Cada uma muda código de lugar e
corta dependência, sem mudar comportamento. São base: vão de **a fazer** direto para **em voo**.

| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |
| [X01](X01-o-pacote-do-texto.md) | O pacote do texto de tela | M | V03 | a fazer |
| [X02](X02-o-pacote-do-placar.md) | O pacote do placar | P | X01, V04 | a fazer |
| [X03](X03-o-pacote-do-ritmo.md) | O pacote do relógio de ritmo | M | H01, H02, H03 | a fazer |
| [X04](X04-o-pacote-do-dualsense.md) | O pacote do DualSense | G | F04, F05, F06, F10, X01 | a fazer |
| [X05](X05-o-pacote-do-robo.md) | O pacote do robô de prova | P | X04, V02, F08 | a fazer |
| [X06](X06-o-pacote-da-costura.md) | O pacote da costura das telas | G | X01, as fichas G que mexem no `main.gd` | a fazer |
| [X07](X07-o-pacote-do-minigame.md) | O pacote do kit de minigame | G | X03, X04, X06, H04, H08, a seção I | a fazer |

## A soma

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
diz sprint, tamanho, estimativa e dependências. Ponha uma linha neste
quadro. Para minigame, use o [molde de minigame](molde-de-minigame.md).
