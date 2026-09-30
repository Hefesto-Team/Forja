# J — S2 — A Viga: os cinco minigames

**Sprint:** J · **Seção:** S02 · **Fichas:** J1 a J5 · **Soma:** US$ 8,0 (J1 G, 2,0; J2 a J5 M, 1,5 cada)

O índice da seção. Cada minigame tem a sua ficha, que se executa sozinha
numa sessão; esta página diz o que os cinco têm em comum.

## A feature protagonista

**Giroscópio e acelerômetro** — o corpo inteiro entra no jogo: inclinar,
virar num golpe, deslizar, chacoalhar e mirar, sempre no tempo.
Coadjuvantes: vibração no desequilíbrio, o R2 endurecendo quando o peso
cresce, o metal rangendo no alto-falante do controle, a barra de luz na cor
do lugar.

## O cenário comum: a caverna da lava

Um arquivo só, criado pela J1 e usado pelos cinco:
`godot/scripts/minigames/s02/secao.gd` (sem `class_name`;
`const SECAO := preload("res://scripts/minigames/s02/secao.gd")`).

| função | o que faz |
| --- | --- |
| `SECAO.montar(sala)` | a caverna d'A Viga de hoje (`godot/scripts/salas/viga.gd:120-180`): as plataformas de pedra em `z = 4, −3, −5`, as paredes, os blocos, **o poço de lava** de `z = −2` a `z = 3` (o shader chapado, que o [11](../11-arte-e-personagens.md#o-que-destoa-hoje) mantém), as três luzes da lava, as brasas, as tochas e `atmosfera(Color("#ff6a3d"), Tema.LARANJA, false, 30, 22.0, -7.8, 0.3)` |
| `SECAO.pilar(sala, x, z)` | um pilar de pedra que sai da lava até `y = 0` (onde cada minigame põe o que o lugar pisa) |
| `SECAO.rolagem(l)`, `SECAO.arfagem(l)` | a inclinação do controle em rad (rolagem: positivo = o lado direito desce; arfagem: positivo = a borda de longe sobe); sem giroscópio, pela gravidade; sem nada, pelo analógico esquerdo × 0,45 |
| `SECAO.guinada(l)` | a velocidade de giro de volante, rad/s (positivo = para a esquerda); sem giroscópio, o analógico direito × 3 |
| `SECAO.forca_g(l)` | o acelerômetro em g; sem acelerômetro, 2,0 no quadro em que ✕ foi apertado, senão 1,0 |
| `SECAO.giro_para(l, rolagem, arfagem, guinada := 0.0) -> Vector3` | a conta do robô: o giro que leva o controle da inclinação de agora até a pedida. Só conta; quem manda é o `robo()` do minigame: `Forja.robo_girar(l, SECAO.giro_para(...), 0.06)` |
| `SECAO.anotar_troca(sala, l)` | sem giroscópio ou sem acelerômetro: a linha `troca` do registro (`de`, `para`), uma vez por minigame, no `iniciar_jogo()` |

O código inteiro está na [J1](J1-a-viga.md#o-cenário).

## As convenções da seção

- **As notas moram em batidas** (`Ritmo.t_da_batida`); o andamento vem do
  mapa da faixa: até a H05, a trilha sintetizada da seção, a **96 bpm**; com
  as faixas geradas, 110 a 130 ([04](../04-ritmo-e-audio.md#as-45-faixas)).
- **O hoqueto em colcheias:** a nota do lugar `l` cai em `2k + 0,5·l`;
  `Ritmo.simples[l]`: uma a cada 4 tempos. Quando a ficha usa outro, ela diz.
- **O movimento é julgado no cruzamento:** o toque é o quadro em que a
  condição (a inclinação passou do limiar, o giro passou da velocidade, o
  pico passou de 1,8 g) **fica verdadeira**, dentro da janela que abre meio
  tempo antes da nota. Já verdadeira ao abrir: julga ali (adiantado).
- **Sem giroscópio, o jogo segue** mais fraco (a gravidade, o analógico), e o
  registro anota a troca de canal (13, H08): `SECAO.anotar_troca(self, l)`
  grava `{"tipo": "troca", "de": "giroscopio", "para": "gravidade"}` (ou
  `"analogico"`; sem acelerômetro, `"acelerometro"` → `"botao"`) uma vez por
  minigame, no `iniciar_jogo()`. A linha `entrada` fica só para o que o
  jogador fez.
- **A contagem, o pico, a barra de luz, o alto-falante, a `contagem` para a
  prova e o R2 (do minigame; o L2 é do item):** como na
  [seção A Centelha](I-a-centelha.md#as-convenções-da-seção).

## A ordem

1. **[J1](J1-a-viga.md)** primeiro: reescreve A Viga de hoje no ritmo, muda
   a sala para `minigames/s02/` e cria o `secao.gd`.
2. **J2 a J5** em qualquer ordem, uma por sessão.

## Os cinco

| ficha | slot | gênero | verbo | o que o corpo faz | tamanho | estimativa |
| --- | --- | --- | --- | --- | --- | --- |
| [J1 — A Viga](J1-a-viga.md) | S02_J06 | sobrevivência | "Equilibre!" | **inclina** contra o empurrão, na nota (rolagem, arfagem, volante), e crava o pino com uma pancada | G | 2,0 |
| [J2 — Pêndulos do Caos](J2-pendulos-do-caos.md) | S02_J07 | sobrevivência | "Vire no alto!" | **vira num golpe** de pulso no alto do arco | M | 1,5 |
| [J3 — Patinação de Dados](J3-patinacao-de-dados.md) | S02_J08 | corrida | "Deslize!" | **dirige** inclinando, e chega na nota no tempo | M | 1,5 |
| [J4 — O Balão dos Foles](J4-o-balao-dos-foles.md) | S02_J09 | 2v2 | "Chacoalhe!" | **chacoalha** o controle, a dupla no tempo e no contratempo | M | 1,5 |
| [J5 — Mira Óptica](J5-mira-optica.md) | S02_J10 | TcT | "Mire!" | **mira** girando o controle e dispara com o R2 na nota | M | 1,5 |

## O que o registro mede

Por baixo ([03](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)):
a taxa e o ruído do giroscópio e do acelerômetro de cada controle, o ângulo
pedido contra o ângulo feito, o atraso entre o pulso e o movimento. As
medidas do núcleo e os vereditos `giroscopio` e `acelerometro` da bancada
ficam **só** na J1, como hoje; os outros quatro gravam na linha `entrada` o
que o movimento fez (o ângulo, a velocidade, o pico em g) e o kit grava o
atraso (o `toque`).

## Antes de começar: o que vem da base

- **O sorteio dentro da seção** e **o ícone**: os mesmos avisos do
  [índice da seção A Centelha](I-a-centelha.md#antes-de-começar-o-que-vem-da-base).
- **O robô fora do gancho:** o `secao.gd` não chama `Forja.robo_*` nem lê
  `Forja.robo` (a checagem da F08 reprovaria); ele só faz a conta
  (`giro_para`), e o `robo()` de cada minigame manda.
