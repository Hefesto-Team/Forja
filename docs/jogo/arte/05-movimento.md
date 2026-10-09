# 05 O movimento

Tudo o que se mexe na Forja se mexe na música. O relógio é o de áudio (H01),
nunca o do processo. O jogo roda a 60 quadros por segundo: 1 quadro é 16,7 ms.

Duas medidas mandam:

- **as batidas** medem o que é composição: uma transição, uma pose, um ciclo
  de andar. Elas escalam com o BPM da faixa;
- **os quadros** medem o que é percepção: o squash, o hit-stop, o tremor.
  Eles não escalam. Um impacto de 3 quadros é um impacto de 3 quadros em
  qualquer faixa.

## A grade

| BPM | onde | 1 batida | 1 colcheia | 1 semicolcheia | quadros por batida |
| --- | --- | --- | --- | --- | --- |
| 90 | créditos | 667 ms | 333 ms | 167 ms | 40 |
| 110 | salão | 545 ms | 273 ms | 136 ms | 32,7 |
| 115 | título | 522 ms | 261 ms | 130 ms | 31,3 |
| 120 | construção, referência | 500 ms | 250 ms | 125 ms | 30 |
| 130 | pódio | 462 ms | 231 ms | 115 ms | 27,7 |
| faixa | minigame | 60000/BPM | metade | um quarto | 3600/BPM |

A regra: **o momento forte de todo movimento pousa num tempo ou numa
subdivisão da grade, com tolerância de 1 quadro.** O momento forte é o
contato do golpe, o pouso do pulo, o impacto do carimbo, o corte. O que vem
antes (a antecipação) começa quando for preciso para o forte cair no lugar.

Neste arquivo, "ms a 120" é a duração na faixa de referência. Em outra faixa,
vale a conta em batidas.

## As curvas

Seis curvas, e só elas. Cada uma tem um trabalho.

| token | curva no Godot | trabalho |
| --- | --- | --- |
| `SAI` | `TRANS_CUBIC`, `EASE_OUT` | algo chegando: placa, adesivo, peça nova |
| `ENTRA` | `TRANS_CUBIC`, `EASE_IN` | algo indo embora; a antecipação que acelera até o impacto |
| `ENTRA_SAI` | `TRANS_SINE`, `EASE_IN_OUT` | a câmera ([01](01-cinema.md#as-regras-da-câmera)), a luz que muda |
| `MOLA` | `TRANS_BACK`, `EASE_OUT`, passa 4 % do alvo | o carimbo, a pose que trava, a recuperação do squash |
| `QUICA` | `TRANS_BOUNCE`, `EASE_OUT` | só o humor do corpo: a queda, o quique |
| `RETA` | `TRANS_LINEAR` | só o contador, os carretéis e o confete girando |

`QUICA` nunca entra em texto, placa ou câmera. `RETA` nunca entra em algo que
para.

## O golpe: antecipação, impacto, recuperação

Todo golpe (martelada, soco, chute, carimbo, pulo que pousa) tem as mesmas
quatro fases. O impacto é o tempo.

| fase | quando | duração | o que o corpo faz |
| --- | --- | --- | --- |
| antecipação | antes do tempo | 1 colcheia, entre 6 e 15 quadros (100 a 250 ms) | o braço recua 10°, o corpo abaixa: escala Y 0,96, curva `ENTRA` |
| impacto | no quadro do tempo | 3 quadros (50 ms) | squash: escala Y 0,80, X e Z 1,12, pivô no pé |
| parada | logo depois | 2 quadros na Ressonância!, 1 no Afinado, 0 no Quase | a imagem do cavaleiro congela ([01](01-cinema.md#as-regras-da-câmera), regra 6) |
| recuperação | depois da parada | 2 quadros de stretch (Y 1,06, X e Z 0,97), depois volta a 1,0 em 1 colcheia (no máximo 15 quadros) | curva `MOLA` |

Quando a colcheia passa de 15 quadros (BPM abaixo de 120), a antecipação
começa 15 quadros antes do tempo, não uma colcheia. Uma antecipação longa
demais avisa o golpe e tira a surpresa do impacto.

**O erro não tem squash.** O cavaleiro que erra "desafina": treme de lado
±0,02 m por 3 quadros e a animação dele cai para 0,5× da velocidade por 1
batida. O resto do erro está em [07 O brilho](07-vfx.md#o-desregistro-do-erro).

## O squash e o stretch

| o que | limite | volume |
| --- | --- | --- |
| cavaleiro | Y de 0,80 a 1,06; X e Z de 0,97 a 1,12 | X·Y·Z entre 0,98 e 1,02 |
| objeto do jogo (bigorna, lingote, alvo) | 10 % para cada lado | X·Y·Z entre 0,98 e 1,02 |
| cenário | nunca | |
| carimbo e adesivo | escala uniforme de 1,35 a 1,0 (não é squash) | |
| texto de leitura (corpo, rótulo, cartão) | nunca | |

O pivô do squash é sempre a base (o pé do cavaleiro, o pé da bigorna). Com o
movimento reduzido ([10](10-acessibilidade.md#o-movimento-reduzido)), todo
squash fica em 5 % no máximo e o hit-stop sai.

## As animações da Kenney na batida

As 32 animações do Mini Characters têm durações fixas. Para o contato cair no
tempo, cada uma toca com `speed_scale` = duração nativa × BPM / (60 × n), onde
n é o número de batidas do ciclo.

| animação | duração nativa | n (batidas por ciclo) | a 90 | a 110 | a 120 | a 130 |
| --- | --- | --- | --- | --- | --- | --- |
| `idle` | 1,333 s | 2 | 1,00 | 1,22 | 1,33 | 1,44 |
| `walk` | 0,667 s | 1 (um passo por colcheia) | 1,00 | 1,22 | 1,33 | 1,45 |
| `sprint` | 0,500 s | 1 | 0,75 | 0,92 | 1,00 | 1,08 |
| `jump` | 0,500 s | 1 (pousa no tempo) | 0,75 | 0,92 | 1,00 | 1,08 |
| `emote-yes`, `emote-no` | 0,667 s | 1 | 1,00 | 1,22 | 1,33 | 1,45 |
| `attack-melee-right` | 0,417 s | 1 (contato no tempo) | 1,25 (n = ½) | 0,76 | 0,83 | 0,90 |
| `attack-kick-right` | 0,533 s | 1 | 0,80 | 0,98 | 1,07 | 1,15 |
| `interact-right` | 0,667 s | 1 | 1,00 | 1,22 | 1,33 | 1,45 |
| `wheelchair-move-forward` | 0,500 s | 1 | 0,75 | 0,92 | 1,00 | 1,08 |

O `speed_scale` fica entre 0,75 e 1,5. Se a conta sair disso numa faixa, n
dobra (ou cai pela metade) e a conta se refaz. A 140 BPM, o `idle` passa a 4
batidas (0,78).

A velocidade do corpo no chão vem do stat Passo
([04](04-o-cavaleiro.md#os-stats)), e o ciclo vem da batida. O pé pode
escorregar até 15 % (a diferença entre o Passo 1 e o 5). Acima disso, a
animação ganha um degrau de n.

**O contato de cada animação** (o quadro em que o martelo bate, o pé pousa, o
pulo toca o chão) é medido uma vez, por script, a partir do `glb`, e fica em
`docs/jogo/arte/dados/contatos.csv` ([PRODUÇÃO](PRODUCAO.md)). A animação
começa em `t_tempo − contato / speed_scale`, pelo relógio de áudio.

## As poses de cada momento

| momento | quem | animação | o que pousa no tempo |
| --- | --- | --- | --- |
| montagem, parado | os quatro | `idle` | a cabeça abaixa 2 % no tempo (ver abaixo) |
| trocar uma peça | o dono | a peça nova chega com escala 0,9 a 1,0 em 4 quadros, `MOLA` | a troca cai na próxima colcheia |
| sortear (△) | o dono | 6 trocas, uma por semicolcheia, e a última em `MOLA` | a última troca cai num tempo |
| a forja (8 marteladas) | o dono | `attack-melee-right` | o contato em cada um dos 8 tempos |
| os prontos | cada um, na vez dele | `emote-yes` | o tempo 1 do compasso dele |
| resultado, o vencedor | o primeiro | `jump` duas vezes, depois `emote-yes` | os dois pousos nos tempos 1 e 3 |
| inserto do último | o último | `sit`, cabeça baixa | a animação desacelera de 1,0 a 0,25 em 700 ms, junto com o tom de `fx_derrota` |
| pódio, primeiro | o primeiro | `jump` | um pulo a cada tempo 1 |
| pódio, segundo e terceiro | | `emote-yes` | nos tempos 2 e 4 |
| pódio, o último | o quarto, no canto | `sit`; `emote-no` a cada 2 compassos | o tempo 1 do compasso ímpar |
| queda no jogo | quem caiu | `fall` e o quique | o quique: 0,30 m e depois 0,10 m, uma colcheia cada, `QUICA` |
| Dissonância | os quatro | a animação que estava | a velocidade segue o tom da música (×0,94 no auge) |

## O que anda no tempo da música

| o que | como anda | período |
| --- | --- | --- |
| o cavaleiro parado | o corpo abaixa 2 % (Y 0,98) no tempo e volta em 4 quadros, `MOLA` | toda batida |
| o néon `VIOLETA` da arquitetura | energia ×1,1 no tempo 1, volta em 1 batida, `SAI` | todo compasso |
| a chama da forja no salão | escala 1,0 a 1,08 no tempo, volta em 1 colcheia | toda batida |
| os carretéis do deck | uma volta a cada 2 batidas, `RETA`; param no apito | contínuo |
| o cursor da seleção | a borda de 3 a 5 px no tempo, volta em 1 colcheia | toda batida |
| o portão sob o cursor (salão) | a tarja acende no tempo 1 | todo compasso |
| os VUs do placar | sobem um segmento por colcheia | enquanto os pontos sobem |
| a luz no pico | a chave +20 % em 1 batida ([01](01-cinema.md#o-pico)) | o pico |

## O que nunca anda no tempo

- O texto de leitura: corpo, rótulo, cartão, dica. Ele pousa e fica parado.
- O contador da fita: anda em tempo real, do PLAY ao fim.
- A física: queda, empurrão, voo do confete. A física é do mundo; só o
  enfeite cai na grade.
- O cartão do jogador no HUD: não pulsa, não balança.
- A câmera durante o jogo: nada de zoom pulsando no tempo. A câmera anda
  pelas regras do [01](01-cinema.md#as-regras-da-câmera).

## O mundo que respira

O cenário se mexe pouco, e devagar:

- a câmera do salão deriva 2 % em 16 compassos ([01](01-cinema.md));
- a poeira no foco da bigorna: 0,5 partícula por segundo, sobe 0,2 m/s,
  `TUNGSTENIO` sem brilho (energia 1,0), some em 4 s;
- a fumaça da chama: nenhuma (o Compatibility não dá volume, e plano de
  fumaça fica falso).

## A prova

- A prancha da forja (8 quadros, um por martelada) mostra o squash e a
  antecipação ([PRODUÇÃO](PRODUCAO.md)).
- O registro da sessão grava o instante de cada contato e de cada corte. O
  portão de batida ([12](12-portoes.md#7-na-batida)) mede a distância de cada
  um até a grade e reprova acima de 16,7 ms.
