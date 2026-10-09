# 06 A interface e o texto

A interface da Forja é objeto. Cada placa é uma peça de um cassete, de um
deck ou de um encarte: plástico, papel, caneta, contador. Nada é janela,
botão de sistema ou menu de loja ([pilar 1](README.md#os-pilares)).

As medidas são da tela lógica de 1920×1080. As cores são os tokens do
[02](02-cor-e-letra.md). As durações estão em batidas e em ms a 120 BPM
([05 O movimento](05-movimento.md#a-grade)).

## Os objetos

| objeto | o que é na fita | onde | tamanho | superfície | letra |
| --- | --- | --- | --- | --- | --- |
| o cartão do jogador | a tira do console de mixagem | o canto do lugar (P1 alto à esquerda, P2 alto à direita, P3 baixo à esquerda, P4 baixo à direita) | 420×132 | `CASCO` a 94 %, tarja de 5 px na cor do dono | P# Bungee 40, nome Archivo 600 32, pontos VT323 64 |
| a etiqueta da seção | a etiqueta do cassete | alto, centro: (548, 60) | 430×136 | `ETIQUETA`, tarja na tinta da seção | título Permanent Marker 52 a 56, linha impressa VT323 34 |
| o deck | a janela do cassete e o contador | à direita da etiqueta: (996, 60) | 376×116 | `CASCO`, borda `CASCO_ALTO` 3 px, janela `JANELA` | contador VT323 64 |
| o J-card | o encarte dobrado | à direita da arena parada: (760, 90) | 1064×830 | `ETIQUETA`, lombada `ETIQUETA_SOMBRA` | ver abaixo |
| o chip de prontidão | o selo do lugar no encarte | dentro do J-card, 2×2 | 400×64 | pronto: a cor do dono; treinando: `CASCO` com borda do dono 3 px | P# Bungee 30, palavra Archivo 700 34 em `FITA` (pronto) ou `ETIQUETA` a 75 % |
| o VU | o medidor de nível | no cartão, na montagem, no placar | segmentos com vão de 4 px | apagado `GRAFITE`, aceso a cor do dono, pico `ETIQUETA` | rótulo VT323 30 |
| as lâmpadas | o LED de jogador do controle | junto de todo P# | 5 posições de 15×8 px, vão de 5 px | acesas na cor do dono, apagadas `GRAFITE` | |
| a dica de botão | o adesivo de instrução | presa ao cavaleiro, ou no rodapé | glifo de 52 px | sem placa sobre a cena; `ETIQUETA` sobre o casco | Archivo 600 34 |
| o carimbo do julgamento | o carimbo de tinta | acima do cavaleiro | Bungee 46 | sem placa | [07](07-vfx.md#o-carimbo) |
| o adesivo de reação | o adesivo colado na fita | o cartão ou a cabeça do dono | 112 a 144 px | [09](09-reacoes.md) | |
| o teclado do nome (G09) | as teclas do deck | metade de baixo da coluna | teclas de 52×52, vão de 6 | `CASCO`, a tecla sob o cursor com fundo `CASCO_ALTO` e borda do dono de 3 a 5 px | Archivo 600 36 |

O estudo põe o cartão em y = 54. A área segura começa em 60: o jogo usa 60.

## A etiqueta

A etiqueta é a voz de quem gravou a fita. Tudo o que ela diz é escrito à mão.

- papel `ETIQUETA`, raio de 8 px, sombra `SOMBRA` deslocada (5, 7);
- a tarja da seção: 12 px de altura, a 14 px do topo. No lado B, duas tarjas
  de 7 px com 4 px de vão ([01](01-cinema.md#o-lado-b));
- duas linhas pautadas em `ETIQUETA_SOMBRA`, 2 px, a 22 px das bordas;
- o título em Permanent Marker, `TINTA`, 52 a 56 px, até 18 caracteres;
- a linha impressa em VT323 34, `TINTA_SUAVE`: "LADO A · FAIXA 01";
- a inclinação: entre −1,5° e +1,5°, sorteada uma vez por seção pela semente
  da noite. Ela nunca se anima.

**A troca de etiqueta** (uma seção nova): a velha descola (sobe 40 px, gira
4°, some em 1 batida, `ENTRA`); a nova cola (desce de −40 px em 1 batida,
`MOLA`); a caneta escreve o título da esquerda para a direita em 400 ms
(`fx_caneta`), por recorte, nunca letra por letra.

## O J-card

O J-card é o encarte que se dobra dentro da caixa da fita. Na Forja, é o
cartão "como jogar" e, aberto ao contrário, o encarte dos créditos.

| parte | medida | o que tem |
| --- | --- | --- |
| a lombada | 104 px de largura, `ETIQUETA_SOMBRA`, tarja de 22 px no topo | "S1 · O MARTELO DE HEFESTO · LADO A" em VT323 46, deitado a −90° |
| a tarja da frente | 16 px, na tinta da seção, a 22 px do topo | |
| a seção | VT323 40, `TINTA_SUAVE` | "A CENTELHA" |
| o título | Permanent Marker 74, `TINTA`, até 22 caracteres (acima disso, 60 px) | o nome do minigame |
| o gênero | caixa de 330×54 com borda de 3 px na tinta da seção | "Todos contra todos" em Archivo 700 34, **em `TINTA`** |
| a faixa | "LADO A" em VT323 40 e o número no contador de 64 px | |
| como jogar | o rótulo VT323 40, depois de 1 a 3 linhas | glifo de 64 px em `TINTA` e a frase em Archivo 600 44; linha `ETIQUETA_SOMBRA` de 2 px entre elas |
| o treino | "TREINO · NÃO VALE PONTO" em VT323 40 e "Começa em 6" em Archivo 600 34 | |
| os chips | 2×2, 64 px de altura, vão de 16 | um por lugar |

O estudo (`quadros/04_cartao.gd`) escreve o gênero na tinta da seção. O
vermelhão sobre a etiqueta tem 3,86 de contraste e só vale a partir de 48 px:
a 34 px, reprova. O gênero vai em `TINTA`, e a tinta fica na borda.

**Entra** da direita: x de +1100 a 0 em 1 batida, `SAI`, com a inclinação
de 0,5° parada. **Sai** para a direita em 1 colcheia, `ENTRA`, quando o
treino acaba; o apito de início cai no tempo 1 seguinte.

## As transições

| transição | quando | duração | ms a 120 | o som |
| --- | --- | --- | --- | --- |
| o corte seco | toda troca de plano | 0 | 0 | nenhum |
| a cortina diagonal | a entrada do minigame | 900 ms fixos, mais a espera do tempo 1 | 900 | `fx_entrada` |
| o rasgo curto | dentro da cortina, no rebobinar, na volta da pausa | 10 quadros | 167 | o do evento |
| o rebobinar | repetir a faixa, recomeçar o treino | 900 ms fixos | 900 | `fx_rebobinar` |
| a pausa | Options no jogo | 4 quadros para congelar | 67 | `fx_stop` |
| o virar da fita | o meio da noite | 2 compassos | 4000 | `fx_virar` |
| a troca de etiqueta | a primeira faixa de uma seção | 2 batidas | 1000 | `fx_caneta` |
| as placas entram | o começo de cada tela com HUD | 1 batida, mais 1 colcheia por lugar | 500 + 250 × 3 | nenhum |
| as placas saem | o apito | 1 colcheia, todas juntas | 250 | nenhum |
| o cursor anda | navegar | 4 quadros, `SAI` | 67 | `ui_tique` |
| o fade para `FITA` | do pódio para os créditos | 1 compasso | 2000 | a música |
| o cross-fade | entre faixas nos créditos e no fim da fita | 1 compasso | 2667 (a 90) | a música |

Nenhuma outra transição existe. Dissolve, wipe em estrela, zoom de tela e
página que vira ficam de fora ([11](11-o-que-nunca.md)).

### A cortina diagonal

A entrada de cada minigame. O quadro é o `03_entrada.jpg`.

- **A forma:** o polígono (0, 0), (1240, 0), (930, 1080), (0, 1080). A borda
  inclina 16,0° da vertical (atan(310/1080)).
- **A tinta:** a da seção, chapada. Por cima, a trama da impressão: uma linha
  de 2 px a cada 6 px, na tinta a ×0,88 de luz.
- **A borda:** uma tira `FITA` de 26 px e, a 22 px dela, o fio `ETIQUETA` de
  4 px. É a fita passando.
- **O tempo**, com o impacto no tempo 1:

| ms | o que acontece |
| --- | --- |
| 0 | a borda entra pela esquerda (x = −330); `fx_entrada` começa |
| 0 a 600 | a borda varre até x = 1240, `ENTRA` (acelera até o impacto); `rasgo` de 0 a 0,35 |
| 600 (o tempo 1) | o impacto: o verbo carimba (Bungee 160 a 252, escala 1,35 a 1,0 em 80 ms, `MOLA`); a tela treme 8 px por 4 quadros; o `rasgo` cai a 0,07 em 6 quadros |
| 600 a 900 | o verbo segura com dois ecos atrás (escala 1,07 e 1,14, opacidade 0,16 e 0,08) |
| depois de 900 | no tempo 1 seguinte, a cortina sai pela direita em 1 batida, `ENTRA`, e o J-card entra |

O 900 não escala com o BPM, porque o som tem o impacto cravado em 600 ms
([03](03-som.md#a-fita-como-som)). O que espera o tempo 1 é o começo.

### O rasgo de VHS

O rasgo é a fita perdendo o trilho por um instante: faixas da imagem
escorregam de lado e a cor se separa. Ele vive no pós da fita
(`pos_fita.gdshader`, uniforms `rasgo` e `aberracao`).

| rasgo | `rasgo` | `aberracao` | subida | platô | descida | onde |
| --- | --- | --- | --- | --- | --- | --- |
| curto | 0,35 | 2,2 | 2 quadros | 2 quadros | 6 quadros | a cortina, o rebobinar, a volta da pausa |
| longo | 0,6 | 0,8 (×10 no pós do mundo) | 1 batida | 0 | 2 batidas | a Dissonância ([01](01-cinema.md#a-dissonância)) |

A `semente` muda a cada 2 quadros enquanto o rasgo dura. No máximo 3 rasgos
por segundo, somados todos ([10](10-acessibilidade.md#o-piscar)). O rasgo
pega o mundo inteiro e o HUD só a 1/3 (o pós de cima é mais fraco), para o
HUD seguir legível.

### A pausa

A fita pausada de um videocassete:

1. `fx_stop`; a imagem congela em 4 quadros e desbota (`desbota` 0,6);
2. a barra de pausa: uma faixa de ruído de 24 px sobe a tela inteira a cada
   2 s, `RETA`;
3. o J-card da pausa entra pela direita (Continuar, Opções, Voltar ao salão,
   Sair), como o cartão.

Com o piscar desligado, a barra de pausa não aparece.

### O rebobinar

O último quadro congela e sobe 3 telas em 900 ms, `ENTRA`, com `rasgo` 0,2
contínuo e `varredura` 0,12. O clunk do fim do `fx_rebobinar` é o corte para
o começo.

## A espera do corte

A ação do jogador nunca espera: o clique soa e vibra no quadro do botão. O
corte espera o tempo 1 seguinte (no máximo 1 compasso; acima de 1,5 s, o
próximo tempo forte), como manda o [01](01-cinema.md#a-montagem-na-batida).
Enquanto espera, o botão apertado fica em `CASCO_ALTO` com a borda do dono.

## O texto como voz

As regras de escrita estão no [06 Telas e fluxo](../06-telas-e-fluxo.md#a-voz-do-texto)
e no [07 Narrativa e voz](../07-narrativa-e-voz.md). As fontes e a escala
estão no [02](02-cor-e-letra.md#as-quatro-fontes). Aqui fica o que a letra
faz na tela.

| regra | o número |
| --- | --- |
| a frase do rodapé ou da dica | até 42 caracteres em Archivo 34 (cabe em 760 px) |
| a linha do "como jogar" | até 32 caracteres em Archivo 44 |
| o grito (Bungee) | até 3 palavras e 14 caracteres |
| o nome do cavaleiro | até 12 caracteres |
| o texto que some sozinho | fica max(2 s, 60 ms por caractere) na tela |
| o carimbo do julgamento | 500 ms, porque o som e a vibração dizem o mesmo |
| números | VT323, alinhados à direita |
| frases | alinhadas à esquerda; só o grito vai centrado |

**O texto pousado não se mexe.** Ele entra (com a placa, ou com a caneta) e
fica parado até sair. Só o grito em Bungee entra com escala (1,35 a 1,0).
Texto de leitura nunca pulsa, treme, gira ou quica.

**O desregistro da impressão** é do grito, e só dele: uma chapa em `FITA`
atrás da letra, deslocada para baixo e para a direita em
round(0,08 × tamanho) px, no mínimo 3 px. No Bungee 46, são 4 px; no 160, 13
px. Sobre a cena 3D, o grito ganha um contorno `FITA` de 6 px.

**Os botões** se escrevem "Botão ✕ (Ação)" e se desenham com os glifos de
`godot/assets/glifos/`: em `TINTA` sobre a etiqueta, em `ETIQUETA` sobre o
casco; 64 px no J-card, 52 px nas dicas, nunca abaixo de 40 px. O glifo
nunca ganha a cor de um jogador, a não ser quando é a dica presa ao cavaleiro
dele.

## O que muda nos outros documentos

- O doc [06 Telas e fluxo](../06-telas-e-fluxo.md#as-telas): o "aviso do
  minigame" é o J-card desta página, entrando depois da cortina.
- A G11 (a interface com o UI Pack) segue valendo para os ícones do pacote; a
  forma das placas vem daqui.
- A G12 (a apresentação do minigame) leva a cortina e o J-card ao jogo.
