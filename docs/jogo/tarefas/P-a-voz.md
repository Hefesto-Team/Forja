# P — S8 — A Voz: os cinco minigames

**Sprint:** P · **Tamanho:** G (cinco fichas) · **Estimativa:** US$ 8,0 (a soma das cinco) · **Depende de:** H04, H08, H07, F01, F09, G08

Esta é a ficha-mãe: o índice. O trabalho anda pelas cinco fichas abaixo, uma
por sessão, na ordem.

## A feature protagonista

O **microfone** de cada controle e a **luz do mudo**. O cavaleiro fala com a
forja: sopra, chama, grita, bate palmas, cala. O botão do mudo é o escudo, e
a luz laranja dele é o estado do escudo — nunca uma pergunta. Coadjuvantes: a
vibração que cresce com a voz, o eco curto no alto-falante do dono, a barra
de luz na cor do lugar.

**O microfone mudo nunca trava ninguém** (a régua, lição 16): sem microfone,
mudo no sistema ou mudo pelo botão fora da hora, o lugar "sopra sozinho, mais
fraco" — as notas dele valem um pouco, sozinhas —, e o registro anota a
`troca`.

## O cenário comum

- A cripta da forja: `Kit.arena`, as raias do kit (x = −6, −2, 2, 6), velas e
  o guardião de pedra em blocos (G08: nenhuma esfera, nenhum bronze). A luz
  da casa (tocha `#ffb070`, lilás `#b9b0ff`, névoa `#241f33`); o terror (P3) é
  a mesma luz escurecida.
- `"papel_som": Forja.PAPEL_MICROFONE` na FICHA (a chave da H08).
- **O ouvido** (o mesmo nas cinco fichas, escrito na [P1](P1-a-voz.md)): o
  piso de cada microfone anda devagar quando ninguém fala; uma voz conta
  quando o nível passa o piso em `VOZ_ACIMA` (0,30) **e** está a menos de
  `MARGEM_AR` (0,12) do microfone mais alto da sala — **a regra do ar**: no
  sofá, a voz de um chega aos quatro microfones, mas mais alto no dele. A voz
  é julgada no começo (`julgar_toque` contra o alvo mais `LATENCIA_MIC`,
  0,08 s) e, quando importa, no fim.
- As linhas `voz`, `troca` e `pista` do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
  (H08). E `Ritmo.calar(batidas)`, também da H08: a música cala por N batidas
  e o relógio segue (o Zero Absoluto).

## A ordem

P1 primeiro (tira a sala de hoje, põe a seção no catálogo e escreve o
ouvido). Depois P2, P3, P4, P5.

## Os cinco

| ficha | gênero | verbo | estimativa |
| --- | --- | --- | --- |
| [P1 — A Voz](P1-a-voz.md) | coop | "Chame a forja!" | US$ 2,0 |
| [P2 — O Sopro no Fole](P2-o-sopro-no-fole.md) | TcT | "Sopre e pare!" | US$ 1,5 |
| [P3 — Zero Absoluto](P3-zero-absoluto.md) | terror | "Silêncio!" | US$ 1,5 |
| [P4 — Grito de Guerra](P4-grito-de-guerra.md) | TcT | "Grite!" | US$ 1,5 |
| [P5 — Palmas da Forja](P5-palmas-da-forja.md) | coop | "Bata palmas!" | US$ 1,5 |

Os cinco verbos: chamar, soprar e parar, calar, gritar, bater palmas.

## O que o registro mede

- o nível do microfone de cada controle a cada voz (`voz`: `comecou`/`parou`,
  o pico, o limiar) e a resposta dela ao tempo pedido (`nota`, `toque`);
- o botão de mudo (as medidas do núcleo, `botoes_medidos`) e a luz do mudo
  mandada (`saida`, `o` = `led_microfone`, com `seq` e `ok`);
- a `troca` `de` `microfone` `para` `sem_microfone` (motivo `sem_microfone`,
  `mudo_no_sistema` ou `mudo_no_jogo`);
- na bancada (P1): os vereditos `microfone`, `microfone_mudo` e
  `led_microfone`, com a pergunta da luz só lá.

## Ao começar a seção

No [quadro](README.md), troque a linha **P** pelas cinco linhas (P1 a P5),
com o tamanho e a estimativa da tabela acima, e a soma no fim do
quadro.
