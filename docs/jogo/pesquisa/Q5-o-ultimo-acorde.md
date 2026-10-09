# Q5 — O Último Acorde (S09_J45): a nota de pesquisa

A ficha: [Q5 — O Último Acorde](../tarefas/Q5-o-ultimo-acorde.md). O catálogo: [o DualSense](dualsense.md), recursos 4
(o alto-falante), 6 (o microfone), 2 (a háptica) e 8 (a barra de luz), e as mágicas 2 (o segredo no ouvido) e 8 (o
brinde). Pesquisa de 08/10/2026.

## O recurso

O fim a 150 bpm (uma batida = 0,4 s): Atirar, Repetir (o canto de duas notas no alto-falante), Sentir (a pedra) e
Soprar. O acorde final em 32 chamadas e respostas, com voltas extras.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Rhythm Heaven (Nintendo), os remixes | o fim junta tudo | o último jogo é o medley de todos | rhythmheaven.fandom.com/wiki/Remix |
| Konvalinka et al. (2010) | quem toca junto se adapta | o acorde é de todos | QJEP 63(11); orbit.dtu.dk |
| Astro's Playroom (Team Asobi, 2020) | o som sai do próprio controle | o colo é um instrumento | já no catálogo, a mágica 2 |

## O risco no Linux

1. **O microfone escuta o alto-falante do próprio controle.** No Soprar, o canto de Repetir ainda soando suja o nível.
2. **Quatro alto-falantes juntos** exigem quatro fluxos abertos: a placa de cada um, no PipeWire. Se um nó cair, a
   nota some. O defeito `sem-alto-falante` imita.
3. **A latência da placa** (≥ 42,7 ms, ver a [O3](O3-passo-no-fosso.md)) atrasa o canto contra a chamada.

## As mágicas, em ordem

### 1. O acorde dos quatro colos

- **Quem joga:** na queda do dragão, o controle dele toca uma nota do acorde.
- **Os outros:** a sala ouve Dó, Mi, Sol e Si dos quatro colos juntos.
- **Os números:** Dó, Mi, Sol e Si, uma por lugar, 1,6 s, volume 0,8.
- **Como se prova sem o controle:** `som_virtual(l).falante` dos quatro no mesmo quadro. Com `--defeitos=som-vizinho`,
  reprova.
- **O que falta:** as quatro notas no `sons_salas.c`.

### 2. A saída calada no Soprar

- **Quem joga:** o próprio controle não sopra por ele.
- **Os outros:** nada.
- **Os números:** alto-falante e háptica a 0 de `t − 0,4 s` a `t + 0,35 s` no lugar da vez.
- **Como se prova sem o controle:** `som_virtual(l)` abaixo de 0,02 na janela.
- **O que falta:** nada.

### 3. A barra do chamado acende

- **Quem joga:** sabe que é a vez dele pela luz.
- **Os outros:** veem quem é chamado.
- **Os números:** 100 % na batida da chamada, volta a 30 %.
- **Como se prova sem o controle:** `percepcao(l).luz` na batida da chamada.
- **O que falta:** nada.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| as quatro notas do acorde | o diretor de som e háptica |
| a saída calada nas janelas do microfone | o diretor de som e háptica |
