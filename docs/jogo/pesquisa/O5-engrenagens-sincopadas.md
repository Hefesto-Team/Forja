# O5 — Engrenagens Sincopadas (S07_J35): a nota de pesquisa

A ficha: [O5 — Engrenagens Sincopadas](../tarefas/O5-engrenagens-sincopadas.md). O catálogo:
[o DualSense](dualsense.md), recursos 2 (a háptica) e 1 (os gatilhos adaptativos), e as mágicas 3 (o metrônomo na mão) e
7 (o degrau da nota). Pesquisa de 08/10/2026.

## O recurso

A **háptica rítmica e o gatilho**: três cliques e o salto no «e», a 130 bpm (uma batida = 0,46 s, meia = 0,23 s). O R2
em `GATILHO_RESISTENCIA` 2,3. As duplas Brasa e Maré, com o Aprendiz.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Konvalinka et al. (2010), «Follow you, follow me» | dois que batem juntos se adaptam um ao outro, sem líder, quando cada um ouve o outro | a dupla sincroniza melhor se cada um **sente** o parceiro | Quarterly Journal of Experimental Psychology 63(11); orbit.dtu.dk |
| Returnal (Housemarque, 2021) | o L2 tem dois estágios: meio curso mira, fundo atira | o curso do gatilho tem degraus que a mão conta | blog da PlayStation, 01/04/2021 («Returnal hands-on preview») |
| Hi-Fi Rush de PS5 (Tango, 2024) | a batida na mão | o metrônomo tátil serve a um jogo inteiro | já no catálogo |

## O risco no Linux

1. **A latência da placa** (≥ 42,7 ms, ver a [O3](O3-passo-no-fosso.md)) atrasa os cliques contra a meia batida de
   230 ms: sobra 187 ms.
2. **O degrau no gatilho depende da emenda.** O `MULTIPLE_POSITION_FEEDBACK` (0x21 com zonas) não está no contrato
   hoje (a mágica 7 do catálogo). Sem emenda, só a resistência contínua.
3. **A trava do Edge** encurta o curso: uma zona 7 pode nunca chegar.
4. **O simulador não imita a fase do gatilho.** `percepcao(l).gatilho_dir` traz os 11 bytes do efeito, não o que a
   mão sente.

## As mágicas, em ordem

### 1. Sentir o salto do parceiro

- **Quem joga:** quando o parceiro da dupla salta, um baque leve bate do lado dele (Brasa à esquerda, Maré à direita).
  Os dois se ajustam sem olhar, como no Konvalinka.
- **Os outros:** nada; o Aprendiz sente os dois.
- **Os números:** 90 Hz, 40 ms, ganho 0,4, no atuador do lado do parceiro, no instante do salto dele.
- **Como se prova sem o controle:** a prova faz o robô do parceiro saltar e lê o `som_virtual` do outro: o lado certo
  acima de 0,3 em até um quadro. Com `--defeitos=haptica-trocada`, o lado vira e o registro mostra.
- **O que falta:** o som de 90 Hz no `sons_salas.c`.

### 2. A catraca no R2

- **Quem joga:** o R2 tem dentes: a mão conta três degraus no curso, um por clique. O salto é o fundo.
- **Os outros:** nada.
- **Os números:** `MULTIPLE_POSITION_FEEDBACK`, dentes nas zonas 3, 5 e 7, força 6; o resto a 0.
- **Como se prova sem o controle:** a prova lê `percepcao(l).gatilho_dir` e confere `[0]` = `0x21` e o bitmap das
  zonas. Com `--defeitos=gatilho-mudo`, reprova.
- **O que falta:** a emenda do contrato. Sem ela, fica a `GATILHO_RESISTENCIA` 2,3 da ficha.

### 3. Os cliques saem adiantados

- **Quem joga:** os cliques caem no tempo, sem os 43 ms da placa.
- **Os outros:** nada.
- **Os números:** o mesmo `LATENCIA_PLACA` da O3.
- **Como se prova sem o controle:** o registro mostra o pedido 43 ms antes da batida.
- **O que falta:** a medida da O3.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a emenda `MULTIPLE_POSITION_FEEDBACK` no contrato (a mágica 2 e a 7 do catálogo) | a Vitória decide |
| `LATENCIA_PLACA` | o arquiteto |
| o baque de 90 Hz | o diretor de som e háptica |
