# K — S3 — O Molde: os cinco minigames

**Sprint:** K · **Seção:** S03 · **Fichas:** K1 a K5 · **Modelo:** Sonnet · **Soma:** US$ 8,0 (K1 G, 2,0; K2 a K5 M, 1,5 cada)

O índice da seção. Cada minigame tem a sua ficha, que se executa sozinha
numa sessão; esta página diz o que os cinco têm em comum.

## A feature protagonista

**O touchpad** — o dedo desenha, racha, toca, estica e carimba, sempre no
tempo. Coadjuvantes: a textura sob o dedo (a háptica por material, no
cabo), o clique do touchpad com som no alto-falante do dono, a vibração
quando o molde fecha, a barra de luz na cor do lugar.

## O cenário comum: a oficina do molde

Um arquivo só, criado pela K1 e usado pelos cinco:
`godot/scripts/minigames/s03/secao.gd` (sem `class_name`;
`const SECAO := preload("res://scripts/minigames/s03/secao.gd")`).

| função | o que faz |
| --- | --- |
| `SECAO.montar(sala)` | `Kit.arena(sala, 5, 3)`; `atmosfera(Color("#f1c86a"), Tema.ROXO, false, 50)` (a poeira dourada, o neon roxo); as três tochas; no fundo, `table` e `chair` do kit, `barrel`, `banner` |
| `SECAO.bancada(sala, l, com_molde := true) -> Dictionary` | a bancada do lugar em `x = RAIAS[l] + 0.45` e **a placa na proporção do touchpad** (2,4 × 1,2 m, 2:1), inclinada 32° para a câmera — o touchpad **é** a placa: o dedo aparece onde o jogo o vê. Com o molde: as duas metades de pedra e o metal no fundo. Devolve `{placa, metades, metal, dedos, ligacao, ouro}` |
| `SECAO.no_molde(x, y, altura := 0.12) -> Vector3` | um ponto do touchpad (0 a 1, y para baixo) na placa |
| `SECAO.distancia(a, b) -> float` | a distância entre dois toques em larguras do touchpad (como o núcleo mede) |
| `SECAO.mostrar_dedos(sala, l, nos)` | os dois dedos na placa (discos de 8 lados na cor do lugar) e a ligação entre eles |
| `SECAO.disco8(pai, raio, altura, pos, mat)`, `SECAO.anel8(pai, raio, pos, mat)` | disco e anel facetados (8 lados), no lugar das esferas e dos toros lisos (11) |
| `SECAO.textura(l, material)` | a textura sob o dedo, só na háptica: `Forja.textura(l, material)` (H08) no máximo a cada quarto de tempo; no rádio, nada |

O código inteiro está na [K1](K1-o-molde.md#o-cenário).

## As convenções da seção

- **As notas moram em batidas**; até a H05, a trilha sintetizada da seção a
  **100 bpm**; com as faixas geradas, 118 a 140
  ([04](../04-ritmo-e-audio.md#as-45-faixas)).
- **O toque é o cruzamento** (o dedo **entra** no ponto, o segundo dedo
  **chega**, a distância **passa** do limiar, o dedo **sai**), dentro da
  janela que abre meio tempo antes; já verdadeiro ao abrir: julga ali.
- **`Forja.dedo(l, i)`**: `x` e `y` de 0 a 1 (y para baixo), `z = 1` com o
  dedo encostado. O clique é o botão `Forja.TOUCHPAD`.
- **Sem touchpad** (`Forja.capacidade(l, "toque")` falso): o lugar não tem o
  que pedir. O minigame o põe como acabado no `iniciar_jogo()` (sem erro) e
  grava a troca de canal (13, H08): `Forja.evento("troca", l + 1, {"slot": id,
  "de": "touchpad", "para": "sem_touchpad"})`. A linha `entrada` fica só para
  o que o jogador fez.
- **A contagem, o pico, a barra de luz, o alto-falante, a `contagem` para a
  prova e o R2 (livre; o L2 é do item):** como na
  [seção A Centelha](I-a-centelha.md#as-convenções-da-seção).

## A ordem

1. **[K1](K1-o-molde.md)** primeiro: reescreve O Molde de hoje no ritmo,
   muda a sala para `minigames/s03/` e cria o `secao.gd`.
2. **K2 a K5** em qualquer ordem, uma por sessão.

## Os cinco

| ficha | slot | gênero | verbo | o que o dedo faz | tamanho | modelo | estimativa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [K1 — O Molde](K1-o-molde.md) | S03_J11 | TcT | "Trace!" | **traça** a letra ponto a ponto, carimba com o clique, abre e fecha com dois dedos | G | Sonnet | 2,0 |
| [K2 — Quebra-Gelo](K2-quebra-gelo.md) | S03_J12 | TcT | "Rache!" | **risca** o touchpad de um lado ao outro, no contratempo | M | Sonnet | 1,5 |
| [K3 — Hackeando o Terminal](K3-hackeando-o-terminal.md) | S03_J13 | coop | "Siga a senha!" | **toca** o quadrante da senha, na sua vez | M | Sonnet | 1,5 |
| [K4 — A Pinça](K4-a-pinca.md) | S03_J14 | TcT | "Segure e solte!" | **pinça** com dois dedos, estica na nota longa e solta no fim | M | Sonnet | 1,5 |
| [K5 — O Carimbo](K5-o-carimbo.md) | S03_J15 | sabotagem | "Carimbe!" | **clica** o touchpad na síncope, por cima do selo do outro | M | Sonnet | 1,5 |

## O que o registro mede

Por baixo ([03](../03-os-45-minigames.md#s3--o-molde--touchpad)): os dois
dedos (posição, pressão de clique, perda de toque), a taxa de amostras do
touchpad, o clique pedido contra o feito. As medidas do núcleo e os
vereditos `touchpad_dois_dedos` e `touchpad_clique` da bancada ficam **só**
na K1, como hoje; os outros quatro gravam na linha `entrada` o que o dedo fez
(onde tocou, quanto andou, quantos dedos, se um se perdeu) e o kit grava o
tempo (o `toque`).

## Antes de começar: o que vem da base

O mesmo do [índice da seção A Centelha](I-a-centelha.md#antes-de-começar-o-que-vem-da-base):
o sorteio dentro da seção e o ícone são da H08.
