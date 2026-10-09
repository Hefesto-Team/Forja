# F09c — O controle que cai quando se joga sozinho

**Sprint:** F · **Tamanho:** P · **Depende de:** F09b

## Por quê

A prova visual da partida de um jogador (o cabo que cai no meio do segundo minigame) mostrou a sala terminando no
quadro em que o único controle cai: «P1 venceu» em A Galeria, aos 01:31, com o aviso «P1 sem controle — reconecte
para voltar» por cima do resultado. Em `godot/scripts/salas/sala_jogo.gd` (o `match fase` de `"jogo"`), quem está sem
controle conta como quem acabou; com um jogador só, `todos` fica verdadeiro e `terminar()` fecha a sala com vitória.

## A decisão dela (09/10/2026)

**Esperar, com uma tela para reconectar.** Sozinho, quando o controle cai, a sala para (o relógio da sala e o
`jogar` param) e a tela de reconectar aparece por cima: o nome do lugar, o controle a religar e o que fazer. Quando o
controle volta, a tela some e a sala segue de onde parou. A sala nunca termina por falta de controle.

## O que estava em aberto

Sozinho, o jogo deve **esperar a volta do controle** (uma pausa: o relógio da sala e o `jogar` param, e o aviso fica)
ou dar a sala por terminada? A F09b não mudou o código: a decisão é do jogo, não da régua.

## O que fazer

- A tela de reconectar, com o texto pelo `traducoes.gd` (pt-BR e en), na letra e na cor da Fita (`Tema`), por cima
  da sala e com a sala visível atrás; ela some no quadro em que o controle volta.

- Em `sala_jogo.gd`, quando todo jogador que ainda joga está sem controle, não contar `t_jogo`, não chamar `jogar` e
  não terminar; ao voltar, seguir.
- O roteiro do cabo em `godot/testes/prova_visual.gd` (`_cabo`) religa o cabo no terceiro minigame; com a pausa a
  sala nunca terminaria. Religar depois de alguns segundos de sala (por tempo, não pelo número de salas feitas).
- Prova: um jogador, o cabo cai no meio da sala, a sala não termina em 10 s sem controle e termina normalmente depois
  que ele volta; ela precisa morder (tirar a pausa e ver reprovar).

## Pronto quando

A partida de um jogador com o cabo que cai passa na `prova_visual` sem «P1 venceu» enquanto não há controle, com a
tela de reconectar à vista enquanto ele está fora e a sala seguindo depois que ele volta.
