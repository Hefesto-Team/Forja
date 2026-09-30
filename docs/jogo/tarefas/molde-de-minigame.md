# O molde de minigame

A ficha de dados de um minigame, preenchida antes de escrever código. Uma
sessão que faz um minigame lê esta página, a ficha do minigame em
[03](../03-os-45-minigames.md) e o kit ([H04](H04-o-kit-do-minigame.md)) —
e nada mais.

## A ficha de dados

| campo | o que é | exemplo (O Martelo de Hefesto) |
| --- | --- | --- |
| `slot` | a seção e o número | `S01_J01` |
| `titulo` | o nome na tela | "O Martelo de Hefesto" |
| `verbo` | a instrução, de uma a três palavras | "Bata!" |
| `genero` | TcT, 2v2, coop, corrida, sobrevivência, terror, sabotagem | TcT |
| `icone` | a parte do controle que se usa | botões de face |
| `entradas` | no máximo três | ✕ ◯ ◻ △ |
| `camera` | fixa, grupo ou corrida | fixa |
| `faixa` | o slot musical | `MUS_S01_J01` |
| `duracao` | em segundos, até 120 | 90 |
| `fim` | tempo, último em pé, primeiro a chegar, meta coletiva | tempo |
| `vencedor` | o critério | mais espadas forjadas |
| `hapticos` | os eventos usados, pelo nome | `acerto`, `perfeito`, `erro` |
| `alto_falante` | o que toca no controle do dono | a nota do jogador |
| `falha` | o que acontece fisicamente no erro | o martelo quica, a espada racha |
| `material` | o chão e os objetos (tabela de materiais) | metal |
| `registro` | o que se mede por baixo | cada botão pedido e respondido |
| `microjogo` | o recorte para o Relâmpago (verbo e 5 a 8 s) | "Bata!", uma bigorna, 6 s |
| `robo` | como o robô joga | acerta 80% no perfeito |

## Os ganchos

O kit cuida do relógio, do julgamento, do item, das falas, do fechamento e do
registro. O minigame implementa só:

| gancho | quando | o que faz |
| --- | --- | --- |
| `montar()` | ao entrar | o cenário, com peças do kit ([11](../11-arte-e-personagens.md#as-regras-de-coerência)) |
| `nota(lugar, n)` | quando chega a nota de um jogador | mostra a pista no mundo |
| `toque(lugar, julgamento)` | a cada toque julgado | a consequência no mundo |
| `falha(lugar)` | no erro ou na nota perdida | a falha física |
| `vencedor()` | no fim | a colocação |
| `robo(lugar, dt)` | com `--robo` | o jogo do robô |

## A régua, antes do commit

1. Alguém que nunca jogou entende o que fazer só com o título, o verbo e o
   ícone?
2. Sem a tela, dá para jogar só com o controle? (Nos minigames em que a
   feature é a pista.)
3. O minigame pergunta ao jogador se o controle funcionou? Se sim, volta para
   a mesa.
4. Todo objeto novo passa no checklist de arte de
   [11](../11-arte-e-personagens.md#o-checklist-de-aprovação)?
