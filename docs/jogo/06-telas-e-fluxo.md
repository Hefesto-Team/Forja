# 06 — As telas e o fluxo

Do título ao pódio, cada tela tem um trabalho só e leva ao próximo passo sem
ninguém precisar ler.

## O fluxo

```
título ─► introdução ─► construção do cavaleiro ─► salão ─┬─► partida (3, 5 ou 9) ─► minigame ─► resultado ─► placar ─┐
  (primeira vez)          (e o lobby, na mesma tela)       │                                     ▲                      │
                                                          │                                     └──────────────────────┘
                                                          ├─► minigame avulso (portão de cada seção) ─► resultado ─► salão
                                                          ├─► o Relâmpago
                                                          └─► pódio (no fim da partida) ─► outra partida | salão
```

Fora do fluxo, e fora do menu: o **Modo bancada** (`--bancada`), com a
bancada dos experimentos, o diagnóstico ao vivo, o livro da sessão e as
salas às cegas com as perguntas de hoje. Nada disso aparece para o jogador.

## As telas

| tela | o que tem | o que sai |
| --- | --- | --- |
| **título** | o logo, a forja acendendo no ritmo da faixa, "Botão ✕ (Começar)" | sai o rodapé "relatórios ao lado do jogo", sai o aviso de módulo nativo (vai para o registro; na tela, só "Nenhum controle encontrado" quando for verdade) |
| **introdução** | na primeira vez da noite: 20 a 30 segundos sem texto, a Dissonância apagando a forja e quatro armaduras vazias acendendo; qualquer botão pula | — |
| **construção do cavaleiro** | a tela nova ([06b](06b-a-construcao-do-cavaleiro.md)): boneco, cor, peça, item e nome, com os quatro lugares lado a lado; é também o lobby | sai o cartão com VID:PID e "o que foi mandado" |
| **salão** | o hub: um portão por seção, a bigorna da partida, a vitrine da coleção da noite | o subtítulo com o nome do hardware vira o nome da seção ("A Centelha") |
| **aviso do minigame** | título, o verbo, o ícone do controle com a parte usada, o gênero ("Dupla", "Todos contra todos"); dez segundos de treino que não vale ponto | a lista de features; o aviso deixa de esperar ✕ de todos: começa sozinho em oito segundos, ou antes se todos apertarem |
| **minigame** | o mundo, a música, o HUD de cada jogador | a tabela de veredito |
| **resultado** | o apito, o vencedor em destaque com o boneco dele pulando, a colocação dos quatro, pontos da rodada, o jingle; avança sozinho em seis segundos | — |
| **placar** | a partida inteira, a virada, o líder | — |
| **pódio** | os três primeiros nos blocos, a faixa do pódio, "Botão ✕ (Outra partida)" e "Botão ◯ (Salão)" | — |
| **pausa** | Continuar, Opções, Voltar ao salão, Sair | o livro da sessão e o diagnóstico |

## O HUD de cada jogador

Hoje o HUD é desenhado em pixels fixos de uma tela de 1920×1080. A decisão:

- **Âncoras, não pixels.** Cada jogador tem um canto (P1 no alto à esquerda,
  P2 no alto à direita, P3 embaixo à esquerda, P4 embaixo à direita). O
  cartão dele fica ancorado ao canto, com margem de área segura de 5% da
  tela, e cresce para dentro.
- **O que o cartão mostra:** a cor e o número, o nome do cavaleiro, os
  pontos da rodada, o combo e o item (com a carga, quando tem). Nada mais.
- **A dica fica presa ao cavaleiro.** A dica e o julgamento do toque
  (perfeito, ótimo…) aparecem acima do boneco, na cor dele, e somem em meio
  segundo.
- **Nunca abaixo de 30 px** na tela lógica, e a escala de texto (1,0 ou
  1,15) é conferida contra a colisão entre cartões e título nas duas línguas.
  A prova das telas (`tests/telas.sh`) fotografa cada tela nas duas escalas.
- **Jogador ausente:** o cartão mostra "Botão ✕ (Entrar)" e fica
  translúcido. Um lugar vazio nunca segura o minigame.

## A câmera

Uma câmera só, compartilhada, sem tela dividida:

- **Enquadra todo mundo que está vivo**, pela caixa que contém os quatro
  cavaleiros, com margem de 15% e distância entre um mínimo e um máximo por
  minigame. A câmera anda suave (amortecida), nunca salta.
- **Nas corridas**, segue o líder com o último sempre na tela; se alguém
  fica para trás demais, ele é puxado de volta para a borda (a borda
  empurra, não mata).
- **Nas arenas**, a pose fixa de hoje continua, mas com um leve empurrão na
  direção da ação.
- **O tremor** é do evento, não da câmera: golpe forte treme pouco,
  explosão treme mais, e as opções de conforto desligam.

## A voz do texto

A regra nova, que substitui a do estudo 03:

- **Todo texto de tela começa com maiúscula.** O resto da frase segue a
  escrita normal: "Começar", "Jogar no teclado", "Salas vencidas", "Virada!".
- **Botão se escreve com o símbolo e a ação entre parênteses:**
  "Botão ✕ (Iniciar)", "Botão ◯ (Voltar)", "Botão △ (Opções)". Quando há
  várias dicas lado a lado, a palavra "Botão" pode ficar só na primeira.
- **Sigla em caixa alta** (USB, BT, L2); nunca caixa alta decorativa.
- **Nunca na tela:** "mesa", "uinput", "hidraw", "MAC", "relatório",
  "veredito", "módulo nativo", nome de recurso do controle como instrução.
- **O vocabulário do visor** para julgamento e fim está em
  [07](07-narrativa-e-voz.md#o-vocabulário-do-visor).

A virada toca as 233 frases de `godot/scripts/traducoes.gd` e os textos
montados com `%`. Um portão de checagem (`scripts/check_texto_de_tela.py`)
lê a tabela de traduções e reprova toda frase de tela que começa com
minúscula, e roda antes de todo push, junto com a prova do jogo.
