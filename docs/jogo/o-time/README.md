# O time

Como a Forja fica pronta sem ninguém precisar empurrar. Um time de papéis guia o projeto inteiro, enriquece cada
ficha até ela ficar fácil de fazer e executa sozinho, seção por seção. A Vitória aprova a direção uma vez e joga no
fim de cada seção; o que precisar dela vai para [ESPERA-ELA](ESPERA-ELA.md), e o resto não para.

Vale para quem chega: a Vitória, o André e a Amanda usam o mesmo time e as mesmas regras.

## As três etapas

| etapa | o que acontece | quem |
| --- | --- | --- |
| **1. A direção** | a bíblia de arte, cinema e som; a régua da diversão; o RPG; o catálogo do DualSense; os módulos e os portões | as seis cabeças ([papéis](papeis.md#a-direção)) |
| **2. O enriquecimento** | cada ficha aberta ganha arte, som, háptica, a mágica do controle e o critério de diversão, até uma sessão nova fazer sem perguntar | o roteirista e o revisor de prontidão ([papéis](papeis.md#o-enriquecimento)) |
| **3. A execução** | a ficha pronta vira código, conferido e jogado | o implementador, o conferente, o jogador e a costura ([papéis](papeis.md#a-execução)) |

A régua que separa a etapa 2 da 3 está em [A ficha pronta](ficha-pronta.md). O motor que move as fichas está em
[A esteira](a-esteira.md), e o que nunca se faz ao executar, em [As regras de execução](regras.md). Todo som e toda música do jogo estão no [mapa do áudio](o-mapa-do-audio.md).

## A ordem

1. **As bases, desde já** (executam sem esperar enriquecimento, porque são fundação):
   - F: a fundação (F04, F05, F06, F08, F09, F10);
   - H: o kit dos minigames (H04, H06, H07, H08 e a medida automática da H03);
   - o DevOps: a varredura, os módulos importáveis, os portões (os de arte inclusive) e a esteira;
   - a direção de arte, cinema e som (o conjunto a-alma, retomado);
   - a pesquisa: o catálogo do DualSense e uma nota de pesquisa para cada um dos 45 minigames;
   - o designer de sistemas: o RPG;
   - o diretor de jogo: a régua da diversão e o momento de grito de cada um dos 45.
2. **A Vitória aprova a direção.** É a única parada obrigatória antes do enriquecimento.
3. **O enriquecimento, seção por seção:** G (as telas) primeiro, depois I, J, K, L, M, N, O, P, Q e R.
4. **A execução começa sozinha** em cada seção assim que o revisor aprova todas as fichas dela.
5. **A música**, uma faixa por vez, seguindo o [mapa do áudio](o-mapa-do-audio.md#a-música): gerada por script quando a
   placa de vídeo está livre, e ligada à ficha que a usa.
6. **No fim de cada seção executada**, um aviso no celular dela: a seção está pronta para jogar.

## Onde mora o estado

- O [quadro](../tarefas/README.md): o estado de cada ficha. É a fila única da esteira.
- [ESPERA-ELA](ESPERA-ELA.md): o que só a Vitória decide.
- A bíblia: [docs/jogo/arte/](../arte/) e a [página da direção](../direcao-de-arte.html).
- A pesquisa: `docs/jogo/pesquisa/` (o catálogo do DualSense e uma nota por minigame).
- O mapa do áudio: [o-mapa-do-audio.md](o-mapa-do-audio.md) e a tabela `docs/jogo/audio/mapa.csv`.
