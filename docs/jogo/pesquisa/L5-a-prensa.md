# L5 — A Prensa: a pesquisa do DualSense

Ficha: [L5](../tarefas/L5-a-prensa.md). Seção: [L — O Impacto](../tarefas/L-o-impacto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **`golpe` (os dois motores) quer dizer: fuja para qualquer lado.** Um motor só aponta o lado seguro. O jogador
  desvia com o LX, entre três lugares da raia (`LUGARES_X` −1,3, 0 e 1,3).
- **O escuro:** a tela quase não ajuda; o tato manda.
- 3 vidas, a luz pela vida (`BRILHO` 0,4 a 1,0); quem morre vira fantasma.
- A diversão pediu **a lanterna fantasma**: acender todas as raias menos a do líder.
- Sala da prova: `S04_J20`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Spider-Man: Miles Morales (2020) | a háptica aponta a direção do ataque | Push Square, agosto de 2020 |
| Subnautica: Below Zero (2021) | o tremor pelo lado do alvo, mais rápido perto | blog da PlayStation, 2020, `?p=349044` |
| Alien: Isolation, PS4 (2014) | luz e ritmo do detector crescem com o perigo | Stevivor, 2014; Game Informer, 2014 |
| Ghost of Tsushima Director's Cut (2021) | o vento na háptica corre de uma ponta à outra e aponta o caminho | catálogo, mágica 9 |
| Everybody 1-2-Switch, «Joy-Con Hide & Seek» (2023) | achar só pelo tremor | Nintendo Life, maio de 2025 |

## O risco no Linux

1. **O lado se mistura na mão** (o mesmo do [L1](L1-o-cerco.md) e do [L4](L4-martelos-termicos.md)). Aqui é pior:
   no escuro, o tato é a única pista. Meta da bancada: 18 de 20 às cegas.
2. **O firmware abaixo de 0x0224** divide o rumble por 2.
3. **Dois donos do motor**: o Hefesto e o jogo.
4. **O LX tem zona morta.** O desvio exige o eixo além de um limiar; um controle com o zero torto (o Hefesto calibra o
   zero) pode desviar sozinho. Não é risco do tato, mas pesa no escuro.

## As propostas

### 1. O lado seguro chama em ritmo (para quem joga)

- **Quem joga:** o lado seguro não é só um motor: é um motor em **três toques** (`aviso` 0,6, 50 ms cada, 8 Hz). O
  "fuja para qualquer lado" continua o `golpe` parado de 150 ms. Ritmo diferente = sentido diferente, mesmo se o lado
  vazar para a outra mão.
- **Os outros:** nada.
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S04_J20`. O robô conta os toques em
  `percepcao(l)`: três toques num motor → vai para aquele lado (`robo_eixo` LX ±1,0); `forte` e `fraco` juntos →
  qualquer lado. O registro cruza `pista` com a posição final no LX. **A que morde:** `--defeitos=motores-trocados`
  manda o robô para o lado da prensa; as vidas caem.

### 2. A prensa desce no tato (para quem joga)

- **Quem joga:** nas 2 batidas antes da prensa, o `fraco` sobe de 0,2 a 0,6 em 4 passos (uma colcheia cada): a
  prensa vem descendo. No escuro, a mão sabe **quando**; a proposta 1 diz **para onde**.
- **Como se prova:** o registro guarda os 4 passos com os valores 0,2, 0,33, 0,47 e 0,6 (±0,02); a prova confere que
  o último passo cai uma colcheia antes do golpe.

### 3. A lanterna do fantasma (para os outros, pedida pela diversão)

- **O fantasma:** quem morreu sente a prensa **uma batida antes** dos vivos (`toque` 40 ms) e, se apertar R1 no tempo,
  acende a lanterna: todas as raias se iluminam por 1 batida, menos a do líder. Vale 20 (`FANTASMA_LUZ`). O fantasma
  ganha um papel e o líder perde a vantagem do claro.
- **Os vivos:** veem a luz chegar; o líder fica no escuro.
- **A barra de luz do fantasma** fica no piso (0,4), como a ficha já diz.
- **Como se prova:** com `--simular=4 --robo=ruim`, alguém morre cedo. O registro tem o `toque` do fantasma uma
  batida antes da pista dos vivos, o evento `lanterna` com as raias acesas e a raia do líder fora. Com
  `--defeitos=vibra-vizinho`, o aviso do fantasma vaza para um vivo e a prova acusa.

## O que preciso de outras cabeças

- **Diretor de jogo:** a lanterna (regras, pontos) e se o fantasma pode acender mais de uma vez por rodada.
- **Arte:** a luz da lanterna no escuro.
