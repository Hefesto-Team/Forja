# 10 — A régua Astro Bot

ASTRO BOT (Team Asobi, 2024) e o Astro's Playroom que veio antes são o
melhor exemplo público de um jogo inteiro construído em cima do DualSense
sem nunca parecer teste. Esta página é a régua: todo minigame novo do Forja
passa por ela.

## O que o Astro Bot faz, e o que o Forja faz com isso

| # | a lição | no Forja |
| --- | --- | --- |
| 1 | **O controle está dentro do mundo.** No Playroom o jogo se passa dentro do console; o primeiro som é o Astro piando de dentro do alto-falante do controle; a nave tem o formato do DualSense | o controle é a armadura do cavaleiro ([07](07-narrativa-e-voz.md#o-mundo)); o primeiro som de cada jogador é o pio dele no próprio controle |
| 2 | **Cada recurso tem um verbo físico que já faz sentido.** Voar pede giroscópio, soprar pede microfone, espremer pede gatilho | o verbo da tela é o verbo do mundo ("Incline!", "Sopre!", "Puxe e solte!") |
| 3 | **Recurso sem motivo fica na gaveta.** A demo da motosserra esperou anos por uma razão natural | um minigame que só existe para mostrar um recurso não entra nos 45 |
| 4 | **Uma fase, um verbo protagonista; o resto acompanha** | a seção protagoniza o verbo, nunca o repertório: toda sala usa o controle inteiro ([ADR-008](../adr/008-a-metodologia-astro-bot.md), [02](02-principios.md#2-a-feature-protagoniza-o-repertório-acompanha)) |
| 5 | **Mecânica repetida precisa de outro uso.** No Astro Bot, cada poder aparece em geral duas vezes, cada uma de um jeito | cinco minigames por seção, cinco verbos diferentes ([02](02-principios.md#4-cinco-jogos-cinco-verbos)) |
| 6 | **Controles base mínimos**: um analógico e dois botões, o gatilho guardado para o poder | cada minigame usa no máximo três entradas; o resto do controle é saída |
| 7 | **Prototipar e cortar muito**: uma fração pequena das ideias virou fase | cada seção prototipa mais de cinco ideias e fica com as cinco melhores; os 45 de [03](03-os-45-minigames.md) são o ponto de partida, não um contrato |
| 8 | **A háptica é desenhada como som**, pela mesma pessoa que cuida do movimento | a háptica sai da mesma tabela de materiais que o som ([05](05-haptica-e-controle.md#a-háptica-por-material)) |
| 9 | **A trindade: ver, ouvir e sentir no mesmo instante** | um evento só está pronto quando os três batem no mesmo quadro |
| 10 | **Materiais definem a háptica**: metal é clique seco, areia é granulado, gelo é fino | a tabela de materiais em [05](05-haptica-e-controle.md#a-háptica-por-material) |
| 11 | **Háptica de ambiente em rampa diz o que está por vir**: a chuva que vira granizo | o fim do minigame se sente: a textura do ambiente engrossa no último terço |
| 12 | **Háptica como informação privada**: a parede com textura secreta, o pássaro que guia pela vibração | com quatro no sofá, a pista que só você sente é ouro — Fuga do Mecha Cego, Corta-Fio, Curto-Circuito |
| 13 | **O gatilho simula o estado do objeto**: a pedra frágil quebra se apertar demais, a esponja fica leve ao espremer | o arco endurece ao puxar, a espada de fita pesa até o pico, o Escudo firma o gatilho enquanto está inteiro |
| 14 | **A vibração acompanha a animação**: o propulsor chacoalha no dedo em sincronia | todo golpe, queda e disparo tem a vibração no mesmo quadro da animação |
| 15 | **Poupar as mãos**: trechos longos de gatilho cansam; tudo se ajusta e se desliga | a noite sorteada alterna gatilho pesado com minigames leves; as opções do lugar ajustam vibração e gatilho por recurso |
| 16 | **Todo recurso exótico tem saída silenciosa**: com o microfone mudo, o ventilador gira sozinho | microfone mudo, giroscópio sem sinal, controle sem placa de áudio: o minigame segue, mais fraco, e o registro anota |
| 17 | **O alto-falante toca sons pequenos e pessoais**: o passo, a coleta, o pio; nunca música | a agenda do alto-falante em [05](05-haptica-e-controle.md#a-agenda-do-alto-falante) |
| 18 | **Um momento marcante a cada trinta segundos**, uma experiência nova a cada dez minutos | todo minigame guarda um pico no meio; nenhuma seção se repete em seguida |
| 19 | **O ritmo do jogo soa como melodia**: pula, pula, soca, moeda | o Forja é literalmente isso: cada toque é uma nota da faixa |
| 20 | **Quase nenhum texto**: menos de cinco mil palavras no jogo inteiro, sem dublagem | título, verbo e ícone; quem chega no meio entra sem ler |
| 21 | **Se parece interativo, é interativo**; visual limpo para ler rápido | quatro pessoas leem a mesma tela: nada decorativo que pareça alvo |
| 22 | **O hub cresce com a coleção**: os bots resgatados vivem no hub | o salão guarda a coleção da noite ([06b](06b-a-construcao-do-cavaleiro.md#a-coleção)) |
| 23 | **Identidade por silhueta simples e fantasia colecionável** | silhueta, cor, item e pio — sem precisar de modelos novos |
| 24 | **Poderes com cara de personagem**, não de ferramenta | cada item tem nome de objeto da forja e um jeito de se sentir no controle |

## A pergunta de aprovação

Antes de um minigame entrar, três perguntas:

1. Alguém que nunca jogou entende o que fazer só com o título, o verbo e o
   ícone?
2. Se tirarmos a tela, dá para jogar só com o controle? (Não precisa dar
   em todos; precisa dar nos da seção dele.)
3. Em algum momento o jogo pergunta ao jogador se o controle funcionou? Se
   sim, o minigame volta para a mesa.

## O método, e não só a régua

As 24 lições acima são o **resultado**. O **método** que a Team Asobi usa
para chegar nele — a sensação nasce na bancada antes de virar minigame,
ideia sem protótipo não entra, quem faz o movimento faz o háptico, poucos
materiais de contraste alto, prioridade com reserva de intensidade — está
no [ADR-008](../adr/008-a-metodologia-astro-bot.md), com a pesquisa em
[estudo 05](../estudos/05-o-dualsense-do-astro-bot.md).

## Para ir mais fundo

- Nicolas Doucet sobre a háptica como som:
  <https://onemoregame.ph/2024/09/astro-bot-director-nicolas-doucet-interview/>
- A integração dos poderes e o ritmo de fases:
  <https://gamesbeat.com/how-astro-bot-went-from-tech-demo-to-playstation-superstar/>
- Pouco texto, jogo curto e denso:
  <https://www.gamedeveloper.com/design/-it-s-okay-to-make-a-small-game-astro-bot-director-nicolas-doucet-says-tiny-ideas-contain-huge-potential>
- *Feel the World*, a palestra de háptica no GDC 2025:
  <https://gdcvault.com/play/1035347/Feel-the-World-The-DualSense>
