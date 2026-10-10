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

## O que foi feito (leva 1, o-kit-2)

**A medida antes.** A partida 4 da prova visual (um jogador, o cabo que cai) terminava A Galeria no quadro da
queda, com «P1 venceu» e o aviso de reconectar por cima do resultado. Na `sala_jogo.gd`, quem está sem controle
contava como quem acabou e, com um jogador só, o `todos` fechava a sala.

**A cura, na `sala_jogo.gd`.** Uma guarda no `_process`, logo depois da pausa: na fase `jogo`, quando todo lugar
que ainda joga está sem controle (`lugares_sem_controle`), a sala espera.

- Na espera não andam o `t_fase`, o `t_jogo`, o `jogar` nem o fim.
- A medida da bancada de cada lugar para (`med_parar`) e volta junto com a sala (`med_retomar`).
- O minigame também pausa o `Ritmo`, porque o tempo jogado dele é o relógio da faixa (`minigame.gd`).
- Quando ainda há alguém com controle, nada muda: a sala segue, e quem caiu conta como quem acabou (o `CABO=1` com
  quatro).

**A tela de reconectar** (`godot/scripts/ui/tela_reconectar.gd`) fica numa `CanvasLayer` 11, por cima da
interface, com a sala visível atrás de um véu da `Tema.FITA`. A placa traz:

- o lugar («P1»), na Bungee e na cor do lugar;
- as lâmpadas do lugar, o controle a religar;
- «O controle saiu.» e «Religue o mesmo para voltar.», no `T_CORPO`, com as duas frases já no `traducoes.gd`.

A luz do lugar respira em volta da placa, e com o movimento reduzido o respiro fica menor. A tela some no quadro em
que o controle volta. Com a pausa aberta, a tela dá a vez à pausa.

**O roteiro do cabo** (`prova_visual.gd`) religa o cabo 12 s de jogo depois da queda, na mesma sala, e não mais
no terceiro minigame. Enquanto o cabo está fora, ele reprova três coisas: a sala que termina, o relógio dela que
anda e a tela de reconectar fora da vista. Essas falhas entram no veredito mesmo com o roteiro inteiro.

**A prova nova** (`CABO_SOZINHO=1` na `tests/prova_de_poucos.sh`, n'A Galeria e n'A Centelha, com um jogador):

1. O cabo do P1 sai no meio da sala.
2. Por 10 s sem controle, a sala não termina, o `t_jogo` e o `tempo_jogado` não andam, e a tela está à vista.
3. O cabo volta, a tela some, o `t_jogo` anda, e a sala acaba sozinha com veredito.

**A medida depois.**

- **A prova visual, partida 4 (passada fixa).** O cabo caiu aos 01:57 n'A Galeria. A placa do P1 ficou à vista
  até 02:07, o cabo voltou aos 02:09 com «P1 voltou ao lugar», e a sala seguiu até o «P1 venceu» dos 02:29. Nenhum
  «P1 venceu» apareceu com o cabo fora, e o roteiro do cabo não reprovou nada. Rodei essa partida na árvore com a
  F09d por cima, e a F09d não mexe no cabo.
- **A prova de poucos inteira.** Ficou verde, com o cabo sozinho n'A Galeria e n'A Centelha. Sem controle, o
  relógio da sala ficou parado nos 10 s, e depois andou.
- **A prova do jogo.** Só reprovou o «kit P2 ótimo em 2 de 12» no «forma-a», a família da carga que a H08 já
  registrou (a base reprovou 1 de 12 na mesma hora). O servidor «antes» ficou verde inteiro.

**O que a prova nova achou nela mesma.** A primeira versão conferia o relógio pelo `tempo_jogado`. No minigame,
esse relógio é o da música e, sem janela, fica em 0, então «a sala seguiu» reprovava n'A Centelha mesmo com a sala
andando. As duas checagens agora leem o `t_jogo`, o relógio da sala em quadros de jogo. A checagem da parada
confere os dois relógios.

**A mordida.** Numa cópia, tirei a guarda do `_process`. A prova do cabo sozinho reprovou: <MORDIDA>

**Escolhas a validar por ela:**

- A tela fica na camada 11: a pausa (o Options) abre por cima e a esconde.
- O respiro da tela usa o andamento da faixa da sala (`Ritmo.bpm`), contado pelo relógio dos quadros, porque a
  música está parada.
- Na espera, a música para só nos minigames. As salas que não são minigame não têm a faixa no `Ritmo`.
- O cabo fica fora por 12 s na prova visual.
- O aviso antigo do HUD («P1 sem controle — reconecte para voltar») continua no topo, junto com a placa nova.

**Para o André (local):** sozinho, com um DualSense só, tirar o cabo (ou desligar o Bluetooth) no meio d'A
Galeria. A sala tem de parar com a placa do P1. Ao religar o **mesmo** controle, a placa some e a sala segue de onde
parou, sem «P1 venceu» enquanto ele está fora.
