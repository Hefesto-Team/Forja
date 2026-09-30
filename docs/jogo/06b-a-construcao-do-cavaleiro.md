# 06b — A construção do cavaleiro

A tela de criação do jogador. Ela substitui o lobby de hoje (◀▶ boneco,
▲▼ item) e faz três trabalhos de uma vez: dá identidade a cada um, calibra o
tempo de cada controle sem ninguém perceber, e entrega um item que muda o
jeito de jogar.

## A tela

Os quatro lugares lado a lado, cada um numa bigorna com a cor do lugar. Quem
aperta ✕ acende a sua bigorna e ouve o pio do seu cavaleiro sair do próprio
controle.

A construção é feita a marteladas, uma peça por vez, no tempo da faixa:

| passo | o que se escolhe | como |
| --- | --- | --- |
| 1 | **o boneco** | ◀▶ troca a silhueta; cada boneco tem o seu pio no alto-falante |
| 2 | **a armadura** | a cor é sempre a do lugar (é a da barra de luz); o que se escolhe é o acabamento: fosco, polido, riscado, dourado quando desbloqueado |
| 3 | **a peça** | elmo, capa ou ombreira — o que diferencia de longe dois cavaleiros parecidos |
| 4 | **o item** | ◀▶ entre os itens; o controle deixa sentir o item na hora (o peso no gatilho, o pulso na mão) |
| 5 | **o nome** | um sorteado da lista da forja, ou o teclado de tela; Botão △ (Sortear) troca |
| 6 | **pronto** | oito marteladas no tempo da bigorna forjam a armadura — e calibram o controle |

As oito marteladas do fim são a calibração
([04](04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)): a mediana do atraso
vira o desvio do controle. Para o jogador, é só a armadura ficando pronta,
peça por peça, a cada golpe no tempo.

Quando os presentes estão prontos, a contagem de sempre leva ao salão. Quem
volta na mesma noite pula a construção: o cavaleiro fica guardado, com o
controle dele.

## O item tem mecânica

Cada item é um poder passivo pequeno, que vale nos 45 minigames, se vê na
tela e se sente no controle. Nenhum item ganha sozinho; cada um muda o jeito
de jogar.

| item | o que faz | como se sente | a troca |
| --- | --- | --- | --- |
| **Martelo** | o acerto perfeito no tempo forte (o 1 do compasso) vale em dobro | o golpe perfeito no 1 vibra mais pesado | o acerto no contratempo vale um pouco menos |
| **Escudo** | absorve o primeiro erro de cada minigame | o gatilho fica firme enquanto o escudo está inteiro; afrouxa quando ele quebra | começa cada minigame com o combo em zero, sem o bônus de entrada |
| **Fole** | depois de um erro, o combo volta na metade dos acertos | um sopro curto no alto-falante quando o combo volta | o combo máximo é menor |
| **Lanterna** | a pista (a vibração, a textura, o bipe) chega meio tempo antes | a pista antecipada é mais fraca | a janela "perfeito" encolhe 10 ms |
| **Diapasão** | a sua nota soa mais alta no alto-falante e na TV, e o seu acerto perfeito puxa o combo da equipe nos minigames de dupla | a nota tem um brilho a mais | nos minigames de todos contra todos, não dá bônus nenhum |
| **Âncora** | resiste a empurrão, sabotagem e ao coice do próprio erro | o gatilho pesa um pouco sempre | o cavaleiro anda um pouco mais devagar nas corridas |

O item aparece no cartão do HUD, com a carga quando tem (o Escudo inteiro ou
quebrado). O registro anota o item de cada lugar, para a noite de seis horas
medir se algum item vence demais.

## Poucos assets, muita identidade

Hoje há poucos modelos de personagem. A identidade não depende de modelos
novos; ela vem de quatro camadas que o jogo já sabe fazer:

1. **a silhueta** — o boneco e a peça (elmo, capa, ombreira);
2. **a cor** — a do lugar, na armadura e na barra de luz;
3. **o item** — nas costas do boneco e no cartão;
4. **o som** — o pio próprio no alto-falante, que diz "sou eu" sem olhar.

## A coleção

A cada noite, o salão guarda o que o grupo conquistou: acabamentos novos
(dourado, cromado, néon), peças novas e troféus de minigame na vitrine. Não
há loja nem moeda; a coleção cresce jogando — vencer um minigame pela
primeira vez, fechar um coop sem erro, bater um recorde. O salão cheio é a
história da noite.
