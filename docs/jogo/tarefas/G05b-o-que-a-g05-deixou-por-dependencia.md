# G05b — O que a G05 deixou por dependência

**Sprint:** G · **Tamanho:** P · **Depende de:** G01 (`Lente` no merge, a pose do título), G06 (a pose do salão), G13 (a
montagem), F09 (a prova visual), as fichas de minigame que pedem `tremer` e `camera_foco`

## Por quê

A [G05](G05-a-camera-dos-quatro.md) entrou na leva 1 com o que se prova sem a máquina dela: a lente em milímetros, os
quatro modos, as contas do enquadramento, o tremor em degraus e A Prova no modo grupo. Ficaram de fora as coisas que
dependem de uma ficha vizinha ou de olho humano na prancha.

## O estado de hoje

- `godot/scripts/mundo/lente.gd` foi criado pela G05 (a G01 não chegou antes) com `fov`, `PADRAO` e `recuo`. A G01 vai
  criar o mesmo arquivo: no merge, vale um só, com os três membros e o que a G01 acrescentar (a lente do título,
  85 mm).
- O salão passou a 35 mm (37,8°) sem mexer na pose (`main.gd`, o ramo de baixo de `_pose_da_camera`): a câmera ficou
  uns 5 % mais fechada do que a de 40°. A pose é da G06; a lente entrou aqui, como manda a tabela da G05.
- O título e a montagem seguem em `Lente.PADRAO` (40°): `_lente()` só conhece `"sala"`, `"salao"` e `"podio"`.
- `camera_foco` e o modo `"dupla"` estão prontos e provados nas contas, mas nenhuma sala os usa; `camera_lente` também
  não é lido por nenhuma ficha de sala ainda.
- A Prova e A Voz continuam no `tremor` antigo (`prova.gd`, `voz.gd`): o main o converte em amplitude com o teto de
  0,08 m. Nenhuma sala chama `tremer(...)` hoje.
- A prova visual (`tests/prova_visual.sh`) filmou A Prova com o modo grupo só nas partidas que o robô joga; as partidas
  de 2 e de 1 jogador não têm quadro próprio.
- `puxar_os_de_tras()` só tem a conta provada com nós de verdade: nenhuma sala de corrida existe para ele rodar no jogo.

## O que fazer

1. Quando a G01 chegar, juntar os dois `lente.gd` num só e pôr `"titulo": 85.0` em `_lente()`; quando a G13 chegar,
   `"lobby"`.
2. Quando a G06 decidir a pose do salão, conferir se a distância de 11,5 a 18 m ainda enquadra os quatro a 35 mm; se
   não, subir a mínima por `Lente.recuo(35.0)`.
3. Em cada sala que hoje balança pelo `tremor`, trocar por `tremer(Sala.TREMOR_GOLPE | TREMOR_ESTRONDO |
   TREMOR_CATASTROFE)` no evento certo e apagar o número solto (A Prova em `_martelada`, A Voz no flash).
4. Pôr no `prova_visual.sh` A Prova nas partidas de 4, 2 e 1 jogador, com o grupo inteiro na tela e sem salto, e o
   quadro de um tremor de cada degrau.
5. Rodar `bash tests/telas.sh comparar` e anotar que A Prova mudou de foto de propósito (a câmera segue o grupo); as
   outras salas fixas só mudam pela lente de 35 mm.

## Pronto quando

- Um só `Lente`, com a lente do título e da montagem decididas por quem as fez.
- Nenhuma sala escreve `tremor = ...` direto: todas pedem `tremer(...)`.
- A prancha da prova visual mostra A Prova com o grupo inteiro nas partidas de 4, 2 e 1.

## Provas

- `bash tests/prova_do_jogo.sh` (as checagens da G05 seguem verdes) e `bash tests/prova_visual.sh`.
- `bash scripts/portoes/rodar.sh`.
