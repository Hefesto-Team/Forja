# Os papéis

Cada papel tem o que lê, o que entrega e quando está pronto. Nenhum papel inventa trabalho fora do seu: o que ele vê
e não é dele vira uma linha em [ESPERA-ELA](ESPERA-ELA.md) (se é decisão dela) ou uma ficha nova no
[quadro](../tarefas/README.md) (se é trabalho).

## A direção

Seis cabeças. Escrevem uma vez e mantêm: quando uma ficha esbarra numa regra que não existe, a cabeça
dona escreve a regra, e não a ficha.

### O diretor de arte e cinema

- **Lê:** a página da direção, os quadros em `docs/imagens/direcao/`, o estudo em `godot/estudos/direcao/`, o
  [11](../11-arte-e-personagens.md) e o [14](../14-os-assets-kenney.md).
- **Entrega:** a bíblia em `docs/jogo/arte/`: a alma e os pilares, a paleta e os tokens, as quatro fontes, a luz por
  seção, a câmera por momento, o storyboard da noite, o movimento na batida, a UI e as transições, os VFX, os emojis,
  a arte do cavaleiro montável, a acessibilidade e «o que nunca». E os quadros de conceito que provam cada regra.
- **Pronto quando:** cada regra tem um número, um token ou uma duração que se confere, e um quadro que a mostra.

### O diretor de som e háptica

- **Lê:** a bíblia de arte, o [04](../04-ritmo-e-audio.md), o [05](../05-haptica-e-controle.md), os sons em
  `godot/assets/sons/` e o gerador deles.
- **Entrega:** a parte de som da bíblia (as famílias de efeito, o tratamento de fita, a mixagem, o casamento com a
  vibração e o gatilho, a assinatura de cada lugar) e o [mapa do áudio](o-mapa-do-audio.md) inteiro: cada som e cada
  faixa com o id, o uso, a ficha que o usa, a receita e o estado.
- **Pronto quando:** toda ficha aberta cita os ids de som de que precisa, e todo id do mapa tem uma receita que um
  script executa.

### O designer de sistemas

- **Lê:** o [06b](../06b-a-construcao-do-cavaleiro.md), o [03](../03-os-45-minigames.md), a bíblia de arte.
- **Entrega:** o RPG em `docs/jogo/sistemas/`: as peças do cavaleiro (cabeça, tronco superior, tronco inferior, arma
  ou amuleto), os stats, as escolhas que impedem outras, o pré-montado aleatório, o nome livre, os itens e como cada
  stat mexe em cada gênero de minigame. A tabela de equilíbrio é dado (um arquivo que o jogo lê), não texto.
- **Pronto quando:** dá para montar um cavaleiro no papel, ver os stats dele e saber o efeito em cada um dos 45.

### O pesquisador do DualSense

- **Lê:** o [05](../05-haptica-e-controle.md), o módulo nativo (`godot/modulo/`), e fora, com busca na web: o anyps5, o kyty, os forks
  de bibliotecas do DualSense no GitHub, e os jogos de PS5 que usam bem o controle.
- **Entrega:** `docs/jogo/pesquisa/dualsense.md` (o catálogo: cada recurso, o que o nosso módulo já faz, o que falta,
  a fonte) e `docs/jogo/pesquisa/<ficha>.md` para cada um dos 45 minigames (a mágica possível naquele jogo, para quem
  joga e para os outros, com a fonte).
- **Pronto quando:** cada recurso do catálogo diz se o jogo usa, onde e como se prova; cada nota de minigame termina
  com no máximo três propostas, ordenadas.
- **Nunca:** copia código de projeto sem licença compatível; cita a fonte de toda ideia de fora.

### O diretor de jogo

- **Lê:** o [02](../02-principios.md), o [03](../03-os-45-minigames.md), o [10](../10-a-regua-astro-bot.md), a bíblia
  de arte e o RPG.
- **Pensa como** um diretor de jogo da Nintendo: a diversão e a estética andam juntas, o jogo ensina sem texto, cada
  minigame tem uma ideia só, e a graça aparece nos primeiros dez segundos.
- **Entrega:** `docs/jogo/diversao/`: a régua da diversão (o que faz um minigame ser bom, com o teste de cada item),
  e para cada um dos 45 o momento que faz o grupo gritar, a curva de tensão dos 90 segundos, como o jogo ensina sem
  falar, o que acontece com quem está perdendo para ele seguir no jogo, e o que se corta porque não diverte.
- **Pronto quando:** cada minigame tem o momento de grito descrito de um jeito que o jogador do time confere numa
  partida pelo robô e nas pranchas.
- **Tem a palavra final** quando a diversão e outra regra brigam; a estética, ele decide junto com o diretor de arte.

### O arquiteto e DevOps

- **Lê:** o [13](../13-arquitetura.md), `scripts/`, `tests/`, o CI.
- **Entrega:** a varredura das coisinhas que faltam (cada achado vira ficha), o plano dos módulos importáveis (cada
  parte do jogo que pode virar uma lib, com a interface), os portões por script (os de arte e de som inclusive) e a
  [esteira](a-esteira.md) funcionando.
- **Pronto quando:** os portões rodam no CI e reprovam o defeito que dizem pegar, e a esteira despacha uma seção sem
  ninguém mexer.

## O enriquecimento

Por seção, depois que a Vitória aprova a direção.

### O roteirista

- **Lê:** a ficha, a bíblia, o mapa do áudio, o RPG, a nota de pesquisa da ficha.
- **Entrega:** a ficha reescrita no molde de [A ficha pronta](ficha-pronta.md).

### O revisor de prontidão

- **Faz uma pergunta:** uma sessão nova faz esta ficha sem perguntar nada e sem abrir arquivo que ela não cita?
- **Entrega:** a ficha marcada **pronta** no quadro, ou devolvida ao roteirista com a lista do que falta.

## A execução

Por seção, sozinha, quando todas as fichas da seção estão **prontas**.

| ordem | papel | faz |
| --- | --- | --- |
| 1 | o implementador | faz as fichas da seção, uma por vez, na worktree da seção |
| 2 | o conferente | confere contra a ficha e a bíblia, e **corrige** |
| 3 | o jogador | joga pelo robô e pela prova visual, olha as pranchas e mede a diversão contra o critério da ficha; corrige o que tira a graça |
| 4 | a costura | cherry-pick na integração, portões, provas, push só com tudo verde |

Mecânico vai por script, nunca por uma sessão: a costura, os portões, a geração de som e de música, a captura de
pranchas.
