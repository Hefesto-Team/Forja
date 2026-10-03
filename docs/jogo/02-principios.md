# 02 — Os princípios

As regras de desenho que todo minigame obedece. Quando uma ideia nova chega,
ela passa por esta página antes de virar código.

## 1. O controle é mundo, não prova

O DualSense entra na ficção como a armadura do cavaleiro: o gatilho é o peso
da arma, a vibração é o golpe que chegou, o alto-falante é a voz do
cavaleiro, a barra de luz é a cor dele. Nenhum recurso é apresentado como
recurso. O jogador nunca lê "vibração", "giroscópio" ou "háptica" durante a
partida — ele lê "Segure a ponte", "Incline a viga", "Sinta o chão".

A consequência direta: **o jogo não pergunta se o controle obedeceu.** Se o
controle não vibrou, quem dependia da vibração errou o tempo — e o registro
mostra isso. A pergunta de múltipla escolha, o veredito e o diagnóstico
moram no *Modo bancada*, que se abre por argumento de linha de comando e não
aparece no menu do jogador.

## 2. A feature protagoniza, o repertório acompanha

Cada seção tem uma feature protagonista (a vibração n'O Impacto, o
microfone n'A Voz…). Mas o controle inteiro trabalha em todo minigame:

| recurso | o que faz em **todo** minigame |
| --- | --- |
| barra de luz | a cor do jogador, sempre; pisca curto no acerto perfeito e escurece por meio segundo no erro |
| luzinhas de jogador | o número do jogador, sempre; nenhuma sala as usa para outra coisa |
| vibração | todo evento físico do seu cavaleiro: acerto, erro, golpe recebido, fim |
| alto-falante | o som pessoal do seu cavaleiro: o "pio" ao entrar, o acerto, a coleta |
| háptica por áudio | a textura do chão e do objeto que você toca (no cabo) |
| gatilho | peso quando há algo para segurar; livre quando não há |
| som na TV | tudo o que todos precisam ouvir: música, golpes, a torcida |

A feature protagonista leva o verbo principal; as outras dão a textura. Um
minigame só está pronto quando ver, ouvir e sentir acontecem no mesmo
quadro.

**A feature protagoniza o verbo, não o repertório** ([ADR-008](../adr/008-a-metodologia-astro-bot.md)): nenhuma sala do Forja
usa uma feature só. A tabela acima é o chão de toda sala, de qualquer
seção; sala que deixa um recurso de fora diz na ficha por quê.

## 3. Uma nota por jogador

O núcleo rítmico do Forja é o hoqueto: a frase musical é dividida entre os
quatro, cada um com a sua nota, o seu timbre e o seu tempo. Ninguém toca a
música inteira; a música só fica inteira se os quatro acertam. Isso tira a
carga de decorar botões e põe o peso onde o jogo quer: no ouvido, na mão e
na turma.

Nas seções de dupla, a dupla divide um acorde (fundamental e quinta). Nas de
todos contra todos, cada nota é um território a defender.

## 4. Cinco jogos, cinco verbos

Uma mecânica que aparece igual pela terceira vez não surpreende mais. Por
isso os cinco minigames de uma seção usam a mesma feature com **verbos
diferentes** — bater, segurar e soltar, esquivar, seguir, sabotar — e a
noite sorteada nunca põe dois da mesma seção em seguida.

## 5. O gênero é livre

A feature da seção é fixa; o gênero não. Dentro das nove seções cabem
corrida, sobrevivência, terror (luz baixa, a háptica como batimento, o
alto-falante sussurrando), dupla cooperativa e sabotagem. Cada seção tem pelo
menos um minigame de dupla e um de todos contra todos.

## 6. A falha é física

Errar nunca produz uma palavra de reprovação. Produz física: o martelo quica,
o bloco nasce torto, a ponte cai, o cavaleiro sai rolando. O erro é
engraçado para quem vê e recuperável para quem errou — a punição é tempo e
posição, quase nunca eliminação imediata. Eliminação fica para os minigames
de sobrevivência, e mesmo neles quem cai continua jogando como fantasma que
atrapalha.

## 7. Todo minigame fecha

Três tempos, sempre: **o apito** (o jingle curto e a música que para em
seco), **o resultado** (quem venceu, com o boneco dele em destaque e a
colocação de todos) e **a volta** (o placar da partida, ou o salão). O
fechamento dura entre quatro e oito segundos, avança sozinho e aceita
Botão ✕ (Continuar) para pular. Nenhum minigame termina num relógio parado.

## 8. Ninguém fica para trás, ninguém é punido por ser bom

A recuperação é escondida e justa:

- **A janela generosa para quem está atrás:** o último colocado ganha até
  +40 ms na janela "bom" dos perigos físicos. Nunca na pontuação, nunca na
  janela "perfeito".
- **A partitura mais simples para quem está errando:** depois de três erros
  seguidos, as notas do jogador passam das semicolcheias para as colcheias,
  sem mudar o andamento. Voltam quando ele acerta quatro.
- **O ambiente pesa na liderança, não a regra:** o líder recebe mais
  obstáculo visual (vento, faísca, fumaça), nunca menos janela.
- **O cínico não lucra:** errar de propósito não dá vantagem que compense —
  a ajuda some antes de valer mais que um acerto.

## 9. Um momento a cada trinta segundos

Cada minigame dura entre 60 e 120 segundos e guarda um pico no meio (o chefe
que aparece, o chão que cai, a música que dobra). Uma partida de nove salas
dura em torno de 25 minutos com os fechamentos. A noite de seis horas é feita
de partidas curtas com pausa natural entre elas, nunca de um bloco contínuo.

## 10. Pouco texto

Quem chega no meio da partida entra sem ler nada. Na tela: o título do
minigame, um verbo de uma a três palavras e um ícone do controle com a parte
que se usa. A explicação longa não existe; se o verbo não bastou, o treino
de dez segundos ensina.
