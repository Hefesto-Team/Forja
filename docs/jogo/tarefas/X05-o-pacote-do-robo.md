# X05 — O pacote do robô de prova

**Sprint:** X · **Tamanho:** P · **Depende de:** X04, V02, F08

## Por quê

O robô que joga pelo simulador e a régua das checagens são o que deixa provar um jogo de controle sem a mão de ninguém; hoje moram dentro do autoload do jogo e da prova.

## Ler antes

- [15 — O robô de prova](../15-os-modulos.md#5-o-robô-de-prova--forja_robo)
- [F08 — A paridade](F08-a-paridade.md)

## O estado de hoje

- `godot/scripts/forja.gd:881-919`: `robo_apertar`, `robo_eixo`, `robo_girar`, `robo_sacudir`, `robo_tocar`, `robo_falar`,
  sobre o `ctl.simulador_*`; dez salas chamam (`git grep -l 'Forja.robo_' godot`).
- A régua (`esperar`, `quadros`, `aperta`) vira `ForjaChecagem` na V02.

## Arquivos que mudam

- `godot/addons/forja_robo/` (novo): `robo.gd` (`ForjaRobo`), `checagem.gd` (`ForjaChecagem`, movida da V02)
- `godot/scripts/forja.gd` (as seis funções saem)
- as dez salas em `godot/scripts/salas/` e os minigames em `godot/scripts/minigames/` (a troca `Forja.robo_` →
  `ForjaRobo.`, por script)
- `godot/testes/checagens/*.gd` (o `extends` aponta para o pacote)

## Passos

1. Mover as seis funções para `ForjaRobo`, sobre o `ForjaControle` (X04).
2. Mover `ForjaChecagem` para o pacote.
3. Trocar as chamadas por script.
4. A prova do pacote: o robô aperta ✕ no lugar 2 e o `ForjaControle.apertou(1, CRUZ)` vê.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_robo` passa e `git grep -n 'func robo_' godot/scripts` não acha nada.

## Provas

- `bash tests/prova_do_importavel.sh forja_robo`
- `bash tests/prova_do_jogo.sh`
- `bash tests/prova_de_poucos.sh`
