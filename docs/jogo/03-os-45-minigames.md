# 03 — Os 45 minigames

Nove seções, uma por feature do controle — as nove salas de hoje. Cada seção
ganha cinco minigames. O primeiro de cada seção é a sala atual, reescrita sem
quiz nem veredito; os outros quatro são novos.

Para cada minigame:

- **Gênero:** todos contra todos (TcT), dupla (2v2), cooperativo (coop),
  corrida, sobrevivência, terror, sabotagem.
- **Verbo:** o que a tela pede, em uma a três palavras. É a única instrução.
- **Como se joga:** o núcleo rítmico e o que cada nota faz.
- **A falha:** o que acontece fisicamente quando o jogador erra.
- **Fim e vencedor:** como acaba, e quem ganha. Todo minigame acaba em no
  máximo 120 s, e fecha como manda o [princípio 7](02-principios.md#7-todo-minigame-fecha).
- **Faixa:** o slot musical ([04](04-ritmo-e-audio.md#as-45-faixas)).

E para cada seção, **o que o registro mede por baixo** — a validação do
recurso que antes era quiz e agora é desempenho.

As janelas de julgamento de todos os 45 são as mesmas
([04](04-ritmo-e-audio.md#as-janelas)): perfeito, ótimo, bom e erro.

---

## S1 — A Centelha · botões, analógicos, gatilhos analógicos

A forja acende. A seção de entrada: o tempo forte é explícito, o andamento é
moderado, e o erro custa pouco. Coadjuvantes: vibração em todo golpe, a nota
de cada um no alto-falante, barra de luz na cor.

**O registro mede:** cada botão, analógico e gatilho pedido, com o instante
do pedido e o da resposta; o curso do gatilho analógico; o botão que ficou
sem resposta a noite toda.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **O Martelo de Hefesto** (a Centelha atual) | TcT | "Bata!" | Quatro bigornas, quatro notas; a runa de cada um acende no tempo dela e o botão pedido muda a cada compasso | o martelo quica e a espada racha; o boneco balança | 90 s; mais espadas forjadas vence | `MUS_S01_J01` |
| 2 | **Marcha dos Escudeiros** | corrida | "Marche!" | Alternar o analógico esquerdo e direito no pulso do bumbo; cada passo no tempo empurra o cavaleiro para a frente na esteira | tropeça nas engrenagens e cai para trás | quem cruzar a linha primeiro, ou o mais longe em 90 s | `MUS_S01_J02` |
| 3 | **Portões de Néon** | corrida | "Passe!" | Os portões descem no compasso; ✕ no tempo dá o impulso que passa por baixo | esmagado e achatado, volta ao último portão | primeiro no fim do túnel | `MUS_S01_J03` |
| 4 | **O Fole** | coop | "Sopre a forja!" | A profundidade do gatilho é a altura da nota: cada um aperta até o ponto da sua nota no tempo dela, e a chama cresce se o acorde fecha | a chama engasga e cospe fumaça no rosto do boneco | 80 s; a forja chega ao branco (todos vencem) ou apaga; o melhor soprador leva o destaque | `MUS_S01_J04` |
| 5 | **A Esteira de Escória** | sabotagem | "Prense!" | Lingotes na esteira, cada um com a cor de um jogador; prense o seu no tempo e o seu botão; prensar o do outro fora do tempo rouba o ponto dele | o lingote escapa e cai no fosso | 90 s; mais lingotes vence | `MUS_S01_J05` |

## S2 — A Viga · giroscópio e acelerômetro

O corpo inteiro entra no jogo. Inclinar e chacoalhar no tempo. Coadjuvantes:
vibração no desequilíbrio, gatilho endurecendo quando a viga pesa, som de
metal rangendo no alto-falante.

**O registro mede:** a taxa e o ruído do giroscópio e do acelerômetro de
cada controle, o ângulo pedido contra o ângulo feito, o atraso entre o pulso
e o movimento.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 6 | **A Viga** (a Viga atual) | sobrevivência | "Equilibre!" | A viga balança no compasso; incline contra o balanço na cabeça do tempo | escorrega até a ponta e cai no fosso | 80 s; quem ficar mais tempo em pé vence | `MUS_S02_J06` |
| 7 | **Pêndulos do Caos** | sobrevivência | "Vire no alto!" | Cada um sobre o disco do seu pêndulo; inclinar no ápice do arco inverte o balanço suave | o pêndulo trava e arremessa o cavaleiro; quem cai vira fantasma que sopra vento nos outros | último em pé, ou quem caiu menos em 90 s | `MUS_S02_J07` |
| 8 | **Patinação de Dados** | corrida | "Deslize!" | Pista de gelo em quatro raias; inclinar leva o patinador às notas que brilham no tempo | passa da nota e gira no gelo | 90 s; mais notas coletadas | `MUS_S02_J08` |
| 9 | **O Balão dos Foles** | 2v2 | "Chacoalhe!" | Dois balões; cada dupla chacoalha o controle no tempo, um no tempo e o outro no contratempo; o sopro combinado sobe o balão | o fole estoura vapor no cesto e o balão desce | primeiro balão a chegar às nuvens, ou o mais alto em 90 s | `MUS_S02_J09` |
| 10 | **Mira Óptica** | TcT | "Mire!" | Mira pelo giroscópio; alvos acendem no tempo e somem no próximo; R2 dispara | o disparo fora do tempo ricocheteia e embaça a mira | 75 s; mais alvos | `MUS_S02_J10` |

## S3 — O Molde · touchpad

O dedo desenha e molda. Coadjuvantes: háptica de textura sob o dedo (no
cabo), clique do touchpad com som no alto-falante, vibração quando o molde
fecha.

**O registro mede:** os dois dedos (posição, pressão de clique, perda de
toque), a taxa de amostras do touchpad, o clique pedido contra o feito.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 11 | **O Molde** (o Molde atual) | TcT | "Trace!" | A forma aparece no molde; trace no compasso, um trecho por tempo, e carimbe no último | o metal escorre e a peça sai torta | 90 s; mais peças inteiras | `MUS_S03_J11` |
| 12 | **Quebra-Gelo** | TcT | "Rache!" | Blocos de gelo na sua raia; deslize no contratempo para rachar | a lâmina escorrega e o bloco congela o boneco por um tempo | 75 s; mais blocos | `MUS_S03_J12` |
| 13 | **Hackeando o Terminal** | coop | "Siga a senha!" | O terminal toca uma senha de quatro notas; cada nota é um quadrante do touchpad e um jogador; a senha só abre se cada um toca o seu quadrante na sua vez | o terminal apita, o chão acende em vermelho e empurra todos um passo para trás | 90 s; a porta abre (todos vencem) e quem errou menos leva o destaque | `MUS_S03_J13` |
| 14 | **A Pinça** | TcT | "Segure e solte!" | Dois dedos seguram a peça quente; afaste-os para esticar durante a nota longa e solte no fim dela | a peça cai e espirra faísca | 80 s; mais peças encaixadas | `MUS_S03_J14` |
| 15 | **O Carimbo** | sabotagem | "Carimbe!" | Clique do touchpad na síncope carimba o seu selo nos lingotes do centro; o selo por cima do selo de outro rouba o lingote | o carimbo borra e o lingote fica sem dono | 90 s; mais lingotes com o seu selo | `MUS_S03_J15` |

## S4 — O Impacto · vibração e barra de luz

A mão sente o golpe antes do olho. Coadjuvantes: gatilho firme para
defender, som do impacto no alto-falante, barra de luz que vira vida.

**O registro mede:** cada vibração mandada (motor, força, duração, `seq`),
se o SDL aceitou, e se o jogador reagiu do lado certo e no tempo certo — a
prova do isolamento esquerda e direita sem perguntar nada.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 16 | **O Cerco** (o Impacto atual) | sobrevivência | "Defenda!" | Golpes chegam da esquerda ou da direita; a mão sente o lado um tempo antes; L1 ou R1 no lado certo e no tempo | o golpe passa, a barra de luz perde um degrau e o cavaleiro cambaleia | 90 s; quem terminar com mais luz | `MUS_S04_J16` |
| 17 | **Fuga do Titã** | coop | "Corra!" | Um vagão desgovernado; os passos do titã chegam na mão cada vez mais fortes; cada um alimenta a caldeira no seu tempo | o titã encosta, sacode o vagão e arranca uma grade | 100 s; o vagão cruza a ponte (todos vencem) ou o titã alcança | `MUS_S04_J17` |
| 18 | **Curto-Circuito** | sabotagem | "Passe!" | A bomba passa de mão em mão; na mão dela a vibração acelera como um coração; passe no tempo para o vizinho | segurou demais: a bomba estoura e o cavaleiro sai voando | quatro rodadas; o último que não estourou | `MUS_S04_J18` |
| 19 | **Martelos Térmicos** | TcT | "Acerte o lado!" | Toupeiras de metal quente sobem dos dois lados; o tremor diz o lado; L1 ou R1 no tempo | martela o vazio e queima a mão (tremor longo) | 75 s; mais toupeiras | `MUS_S04_J19` |
| 20 | **A Prensa** | sobrevivência / terror | "Esquive!" | Luz baixa; as prensas descem no compasso; a vibração forte avisa um tempo antes; o analógico tira o cavaleiro de baixo | esmagado, vira fantasma que acende luz no caminho dos outros | 90 s; último sem ser esmagado | `MUS_S04_J20` |

## S5 — A Galeria · gatilho adaptativo e luzinhas de jogador

A arma tem peso. Coadjuvantes: vibração de recuo, som do disparo no
alto-falante, barra de luz que pisca no acerto. As luzinhas de jogador
seguem mostrando o número do jogador — a munição, quando existe, aparece na
tela e no peso do gatilho, não nas luzinhas.

**O registro mede:** cada efeito de gatilho mandado (modo, posição, força,
`seq`), o curso do gatilho no disparo, o clique da arma no ponto certo.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 21 | **A Galeria** (a Galeria atual) | TcT | "Atire!" | Alvos no tempo; a arma (Weapon) tem o clique no ponto certo do curso | o tiro sai antes do clique e espirra longe | 90 s; mais alvos | `MUS_S05_J21` |
| 22 | **Arco de Néon** | TcT | "Puxe e solte!" | O arco (Feedback) endurece ao puxar; segure durante a nota longa e solte no fim dela | a flecha cai aos pés | 80 s; mais alvos | `MUS_S05_J22` |
| 23 | **Metralhadora de Feitiços** | coop | "Segure a rajada!" | A metralhadora (Vibration) treme no dedo em semicolcheias; os quatro dividem as frases do ataque, cada um na sua | a arma superaquece e trava por um compasso | 90 s; a frota cai (todos vencem) e o artilheiro com mais acertos leva o destaque | `MUS_S05_J23` |
| 24 | **Espada de Fita** | duelo 2v2 | "Solte no pico!" | A fita K7 da espada estica e o gatilho pesa cada vez mais; solte no pico da nota para o corte | a fita afrouxa e a espada balança mole | melhor de três rodadas por dupla | `MUS_S05_J24` |
| 25 | **A Catapulta** | 2v2 | "Carregue e lance!" | Cada dupla carrega a catapulta: um puxa a corda (Feedback), o outro trava no contratempo (Weapon); a pedra voa no castelo rival | a corda escapa e a pedra cai no próprio muro | primeiro castelo derrubado, ou mais dano em 90 s | `MUS_S05_J25` |

## S6 — O Canto · alto-falante

O controle canta, e cada controle canta diferente. Coadjuvantes: vibração
no tempo forte, barra de luz que pulsa com a própria nota, háptica suave
acompanhando a melodia (no cabo).

**O registro mede:** cada som mandado ao alto-falante de cada controle
(qual, quando, por qual placa), a resposta do jogador depois dele — se o som
não chegou, quem dependia dele erra a resposta, e o cruzamento mostra.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 26 | **O Canto** (o Canto atual) | TcT | "Repita!" | O seu controle canta uma frase; no compasso seguinte você a repete nos botões | a nota sai desafinada e o sino racha | 90 s; mais frases inteiras | `MUS_S06_J26` |
| 27 | **Eco do Abismo** | corrida / terror | "Responda o eco!" | Escuridão; o eco no seu controle diz o degrau seguinte; a resposta certa acende o degrau | o degrau é oco e o cavaleiro despenca um andar | primeiro no topo | `MUS_S06_J27` |
| 28 | **Coral dos Quatro** | coop | "Cante a sua!" | O acorde é dividido: cada controle canta uma nota; toque a sua na sua vez e o coral fecha | a nota falta e o coral desafina, o vitral trinca | 90 s; o vitral inteiro (todos vencem) e quem fechou mais acordes | `MUS_S06_J28` |
| 29 | **Código do Dragão** | TcT | "Decore!" | O dragão canta uma senha no seu controle, de três notas até doze; repita inteira | o dragão cospe fumaça e a senha recomeça em três | 100 s; a senha mais longa | `MUS_S06_J29` |
| 30 | **Corta-Fio** | sabotagem | "Corte!" | A bomba no peito bipa no seu alto-falante; corte o fio no bipe certo; quem está na frente pode mandar um bipe falso para o controle de outro | cortou no bipe errado: a bomba estoura em confete | três bombas; quem desarmou mais | `MUS_S06_J30` |

## S7 — Os Caminhos · háptica por áudio

O chão fala com a mão. Só no cabo o atuador canta a textura; no rádio, o
minigame entrega a mesma pista pelo rumble, mais grosseira, e o registro
anota a diferença. Coadjuvantes: o som dos passos no alto-falante, a barra
de luz que escurece no terror.

**O registro mede:** cada textura mandada aos atuadores (forma de onda,
ganho, placa), se a placa de quatro canais existia, e se o jogador pisou no
chão certo — a antiga pergunta "que chão é esse?" agora é o caminho que ele
escolhe.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 31 | **Os Caminhos** (os Caminhos atuais) | corrida | "Sinta o chão!" | Três trilhas na bifurcação; a textura do chão certo (metal, areia, gelo) é a da senha do seu portão | a trilha errada cai num lamaçal lento | primeiro no fim | `MUS_S07_J31` |
| 32 | **Neblina de Dados** | terror | "Salte no firme!" | Neblina total; só a mão sabe onde há chão; salte no pulso quando a textura firme chegar | o chão era neblina e o cavaleiro some no escuro, volta ao ponto anterior | primeiro do outro lado | `MUS_S07_J32` |
| 33 | **Passo no Fosso** | corrida | "Pise no contratempo!" | Placas afundam no tempo; a mão pulsa no contratempo, que é quando elas sobem | pisa na placa afundada e escorrega no plasma | primeiro na margem | `MUS_S07_J33` |
| 34 | **Fuga do Mecha Cego** | terror / sobrevivência | "Esconda-se!" | O mecha caça pelo som; os passos dele chegam no atuador esquerdo ou direito; ande para o lado oposto no tempo e pare quando ele para | o holofote acha, o cavaleiro é pego e vira fantasma que faz barulho | 100 s; quem sobreviveu mais tempo | `MUS_S07_J34` |
| 35 | **Engrenagens Sincopadas** | 2v2 | "Encaixe!" | Escalada por engrenagens; a textura dos dentes na mão diz o encaixe; a dupla sobe alternando saltos na síncope | salta fora do encaixe e escorrega uma engrenagem | primeira dupla no topo | `MUS_S07_J35` |

## S8 — A Voz · microfone e luz do mudo

O cavaleiro fala com a forja. Coadjuvantes: vibração que cresce com a voz,
o eco no alto-falante, a luz do mudo como estado do escudo. Microfone mudo
nunca trava ninguém: o fole sopra sozinho mais fraco, e o registro anota.

**O registro mede:** o nível do microfone de cada controle, o botão de
mudo e a luz do mudo mandada, a resposta da voz ao tempo pedido.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 36 | **A Voz** (a Voz atual) | coop | "Chame a forja!" | O guardião dorme; soprem juntos nos tempos dele para acender a chama | sopro fora do tempo espalha cinza | 80 s; a chama acende (todos vencem) e o pulmão mais afinado leva o destaque | `MUS_S08_J36` |
| 37 | **O Sopro no Fole** | TcT | "Sopre e pare!" | Nota longa: sopre durante ela e pare quando ela acaba; a voz é o segurar e soltar | soprou demais: o fole explode fuligem | 80 s; mais notas inteiras | `MUS_S08_J37` |
| 38 | **Zero Absoluto** | terror / sobrevivência | "Silêncio!" | Batatinha frita: a música para e o guardião escuta; quem faz barulho congela. O botão de mudo é o escudo — mas ele tem só três cargas | o guardião ouve e congela o cavaleiro no gelo | 90 s; quem chegou mais longe sem congelar | `MUS_S08_J38` |
| 39 | **Grito de Guerra** | TcT | "Grite!" | Arena de sumô; o grito no tempo forte solta a onda que empurra quem está perto | grito fora do tempo dá o coice no próprio cavaleiro | último na arena | `MUS_S08_J39` |
| 40 | **Palmas da Forja** | coop | "Bata palmas!" | O microfone capta palmas; a turma inteira segura o ritmo que o ferreiro pede, com viradas no fim de cada frase | a bigorna desafina e a espada sai torta | 90 s; a espada lendária (todos vencem) e quem cravou mais palmas | `MUS_S08_J40` |

## S9 — A Prova · tudo junto

O fim de cada noite. Tudo ligado, em equipe. Os dois medleys usam as
mecânicas das seções anteriores em sequência.

**O registro mede:** tudo junto — a carga de saídas por segundo, as recusas
sob carga, os quatro controles ao mesmo tempo.

| # | minigame | gênero | verbo | como se joga | a falha | fim e vencedor | faixa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 41 | **A Prova** (a Prova atual, sem as perguntas) | 2v2 | "Vença a outra equipe!" | Duas equipes, cada recurso do controle é uma arma da equipe; a cor da equipe aparece no chão e no cavaleiro, não na barra de luz | cada erro cede terreno à outra equipe | 90 s; a equipe com mais território | `MUS_S09_J41` |
| 42 | **Roubo de Bateria** | 2v2 | "Roube!" | Pega-bandeira: quem carrega a bateria segura o pulso dela em L2 e R2 alternados; a outra equipe manda interferência para o alto-falante do carregador | o pulso falha, a bateria cai no chão e fica livre | 100 s; mais baterias levadas para a base | `MUS_S09_J42` |
| 43 | **Mecha de Dois Pilotos** | 2v2 | "Pilote juntos!" | Cada dupla pilota um mecha: um é a perna esquerda, o outro a direita; soco só sai com os dois no mesmo tempo | fora de sincronia, o mecha soca a própria cabeça | melhor de três quedas | `MUS_S09_J43` |
| 44 | **Ruge o Reator** | coop / medley | "Aguentem!" | O dragão acorda. Trechos de 20 s das seções 1 a 4 em sequência, sem pausa: bater, equilibrar, traçar, defender | cada erro tira um pedaço da plataforma comum | 120 s; a plataforma aguenta (todos vencem) e quem errou menos leva o destaque | `MUS_S09_J44` |
| 45 | **O Último Acorde** | coop / medley | "O acorde final!" | O fim da noite. Trechos das seções 5 a 8 e, no fim, 32 notas em chamada e resposta divididas entre os quatro | o acorde falta e o dragão se levanta de novo — mais oito notas | o dragão cai numa chuva de luz; a noite termina no pódio | `MUS_S09_J45` |

---

## A noite sorteada

A partida de 3, 5 ou 9 continua ([SALAS](../SALAS.md#a-partida--o-placar-e-o-pódio)).
Com 45 minigames, o sorteio obedece a três regras: nunca dois da mesma seção
em seguida, pelo menos um de dupla a cada cinco, e a Prova (S9) só aparece
como fecho de partida. A partida de 9 é uma de cada seção.

## O Relâmpago

Um modo à parte, no estilo WarioWare: microjogos de 5 a 8 segundos tirados
dos 45, um atrás do outro, cada vez mais rápidos. Cada microjogo tem um
verbo de uma palavra — "Bata!", "Incline!", "Sopre!", "Corte!" — que é a
instrução do mundo, não a do teste. Serve de aquecimento no começo da noite e
de desempate no fim. Sprint R.
