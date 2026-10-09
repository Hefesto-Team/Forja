# O jogo completo — de bancada a jogo

O Forja cumpriu o que prometeu: as nove salas funcionam e cada uma prova um
recurso do DualSense. Mas hoje ele ainda é uma bateria de testes com cara de
party game — a sala acaba num veredito, pergunta "que chão é esse?", manda
olhar o LED. Esta pasta é a direção do que vem agora: **um jogo que quatro
pessoas jogam por quatro a seis horas sem cansar**, em que o controle é
mundo e não prova. A validação do hardware continua — por baixo, no registro,
nunca na cara do jogador.

Cada arquivo daqui é uma decisão: o que se faz, por quê e como. O
[CONTRATO](../../CONTRATO.md) continua sendo a lei; nada aqui passa por cima
dele.

## O mapa

| documento | o que decide |
| --- | --- |
| [01 — O diagnóstico](01-diagnostico.md) | o que está errado hoje, com o arquivo e a linha, e a sprint que resolve |
| [02 — Os princípios](02-principios.md) | as regras de desenho que todo minigame obedece |
| [03 — Os 45 minigames](03-os-45-minigames.md) | as nove seções, cinco jogos cada, com premissa, verbo, falha, fim e vencedor |
| [04 — O ritmo e o áudio](04-ritmo-e-audio.md) | o relógio de áudio, as janelas, a calibração, as 45 faixas, os jingles e os efeitos |
| [05 — A háptica e o controle](05-haptica-e-controle.md) | háptico forte e legítimo, o alto-falante, a identidade P1..P4, o rádio |
| [06 — As telas e o fluxo](06-telas-e-fluxo.md) | do título ao pódio, o HUD de cada jogador, a câmera, a voz do texto |
| [06b — A construção do cavaleiro](06b-a-construcao-do-cavaleiro.md) | a tela de criação do jogador e o item que muda a mecânica |
| [07 — A narrativa e a voz](07-narrativa-e-voz.md) | o mundo, a Dissonância, as falas curtas e o vocabulário do visor |
| [08 — A noite de seis horas](08-a-noite-de-6-horas.md) | o protocolo do teste final, o registro v2 e o cruzamento offline |
| [09 — Fora do escopo](09-fora-do-escopo.md) | o que o Forja recusa, e por quê |
| [10 — A régua Astro Bot](10-a-regua-astro-bot.md) | o estudo de caso: como usar o DualSense sem parecer teste |
| [11 — A arte e os personagens](11-arte-e-personagens.md) | as regras de coerência, o que destoa e os doze bonecos |
| [12 — Como trabalhar](12-como-trabalhar.md) | o método: uma ficha por sessão, o que roda onde, o orçamento |
| [13 — A arquitetura](13-arquitetura.md) | a base comum que toda ficha usa: APIs, registro, kit, paridade, prova visual |
| [14 — Os assets da Kenney](14-os-assets-kenney.md) | o pacote All-in-1: o que entra, como entra, recolorir |
| [15 — Os módulos importáveis](15-os-modulos.md) | as sete peças que outro jogo pode importar: a interface, o que soltar, o pacote e a ordem |
| [O quadro](tarefas/README.md) | as fichas, na ordem de trabalho, com o estado de cada uma |

As sprints que executam isto estão no topo do [SPRINTS](../../SPRINTS.md),
da F em diante; o trabalho em si anda pelo [quadro de fichas](tarefas/README.md),
uma ficha por sessão ([12](12-como-trabalhar.md)).

## As regras de ouro

Invioláveis. Um patch que quebra uma delas está errado, como um patch que
quebra o contrato.

1. **Nenhuma instrução metalinguística no jogo.** Nada de "olhe o LED agora",
   "o som saiu do seu controle?", "aperte ✕ se sentiu". O jogo pede um verbo
   do mundo ("Bata!", "Segure a ponte") e o desempenho do jogador é a prova.
   Quiz e veredito vivem no *Modo bancada*, fora do menu do jogador.
2. **A feature da seção protagoniza; o resto do controle nunca some.** Em
   todo minigame há vibração nos eventos, a barra de luz na cor do jogador,
   o som pessoal no alto-falante e o gatilho com peso quando houver o que
   segurar.
3. **Todo minigame acaba com fechamento na tela:** quem venceu, os pontos,
   uma celebração curta e o jingle. Nunca um relógio parado, nunca uma tela
   vazia.
4. **O jogador é o número do controle.** O P1 da tela é o controle com o LED
   de P1, desde que ele conecta. Nenhuma sala usa as luzinhas de jogador ou a
   barra de luz de um jeito que apague quem é quem.
5. **Tudo que o jogo manda ao controle vai para o registro** com número de
   sequência, para ser cruzado depois da noite. O jogo nunca pergunta ao
   jogador se o controle obedeceu.
6. **Texto de tela sempre começa com maiúscula.** Botão se escreve
   "Botão ✕ (Iniciar)". Pouco texto: quem chega no meio da partida entra sem
   ler nada.
7. **A falha é física e engraçada, nunca uma palavra.** O martelo quica, a
   ponte cai, o cavaleiro sai rolando — e todo mundo ri.
8. **Todo objeto novo passa pelo checklist de arte** de
   [11](11-arte-e-personagens.md#o-checklist-de-aprovação): fosco, em blocos,
   na proporção dos bonecos, e monstro feito de peças do kit.
9. **A prova percorre o jogo que se joga.** O robô só age pelo controle
   simulado, a prova roda o modo do jogador, e a noite roda o pacote
   exportado ([13](13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)).
10. **Foto escolhida não prova nada.** A prova visual grava a partida
    inteira, com o robô errando, e confere todos os quadros; a aparência só
    se aprova na máquina do André ([13](13-arquitetura.md#a-prova-visual--f09)).
