# P4 — Grito de Guerra (S08_J39): a nota de pesquisa

A ficha: [P4 — Grito de Guerra](../tarefas/P4-grito-de-guerra.md). O catálogo: [o DualSense](dualsense.md), recursos 6
(o microfone), 3 (o rumble) e 8 (a barra de luz). Pesquisa de 08/10/2026.

## O recurso

O **microfone pelo grito no tempo forte**: um sumô a 135 bpm (uma batida = 0,44 s). `ONDA_R` 3, força
`[0, 1,2, 1,8, 2,4]` por nível do grito, e o coice.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| DK Bongos (Nintendo, 2003) | a palma pelo microfone | sensível demais: a voz no tom certo dispara. O limiar precisa de margem | mario.fandom.com/wiki/DK_Bongos |
| Don't Stop! Eighth Note (YASUHATI, 2017) | mais alto, pulo maior | o volume como força é imediato | App Store (id1215691000) |
| Nintendogs (Nintendo, 2005) | a voz perto do aparelho | a distância da boca muda tudo | manual de início rápido da Nintendo |

## O risco no Linux

1. **O grito satura.** Perto da boca, o microfone do controle passa do teto. O volume do microfone (byte 6, 0x00–0x40)
   baixaria o ganho, mas não chega ao GDScript.
2. **Quem grita mais alto ganha.** Num sumô, a voz mais forte vence; a criança perde para o adulto. O volume só pode
   ser visual.
3. **O vizinho escuta o grito.** O vazamento (ver a [P3](P3-zero-absoluto.md)) dá força ao vizinho.

## As mágicas, em ordem

### 1. O empurrão sentido do lado do gritador

- **Quem joga:** empurrado, sente o golpe do lado de quem gritou.
- **Os outros:** nada.
- **Os números:** rumble a 0,5 no motor do lado do gritador, 200 ms, só depois da janela de escuta.
- **Como se prova sem o controle:** `percepcao(l).forte/fraco` do empurrado. Com `motores-trocados`, o lado vira.
- **O que falta:** nada.

### 2. A barra do gritador acende

- **Quem joga:** gritou com BOM ou melhor, a barra vai a 100 % por ¼ de batida.
- **Os outros:** veem quem gritou no tempo.
- **Os números:** 100 % por 0,11 s, volta a 30 %.
- **Como se prova sem o controle:** `robo_falar(l, 0,8, 0,2)` no tempo forte e `percepcao(l).luz`.
- **O que falta:** nada.

### 3. O volume do microfone por sala

- **Quem joga:** o grito não satura.
- **Os outros:** nada.
- **Os números:** medir 0x40 contra 0x20 no byte 6, grito a 15 cm, 10 vezes; escolher o valor que não passa 0,95.
- **Como se prova sem o controle:** só na bancada, com `som_escutar` e `relatorio_cru`.
- **O que falta:** expor o byte 6 (o arquiteto).

**A regra:** o volume do grito decide só o visual (o tamanho da onda); a força vem do acerto no tempo, nunca do
volume. Assim a criança e o adulto empatam.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o byte 6 exposto e medido | o arquiteto |
| a regra «o volume é só visual» | o diretor de jogo |
