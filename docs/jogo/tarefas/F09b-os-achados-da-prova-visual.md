# F09b — Os achados da primeira prova visual

**Sprint:** F · **Tamanho:** M · **Depende de:** F09

## Por quê

A primeira rodada da [prova visual](F09-a-prova-visual.md) no jogo de hoje
reprova, e reprova por defeitos de verdade, não da régua: as quatro partidas
(quatro jogadores com o robô bom e com o ruim, dois com o médio, um com o médio
e o cabo que cai) acharam de 29 a 46 defeitos distintos cada uma, quase todos
os mesmos. Esta ficha os agrupa para que a cura vá à origem (o tamanho da
letra e a margem vêm do tema, não de cada sala) e a prova volte a passar.

A prova mede **disposição** (colisão, corte, tamanho, contraste), não a cor do
tema: a direção de arte nova (Fita Magnética) pode trocar a paleta sem tirar
nenhum destes achados, e a cura de cada um tem de valer para ela.

## Ler antes

- [F09 — a prova visual](F09-a-prova-visual.md) e o «O que foi feito» dela.
- [A arquitetura — a prova visual](../13-arquitetura.md#a-prova-visual--f09)

## O estado de hoje (medido, semente 7, `PASSADAS=fixa`)

Os números são da rodada de 08/10/2026; o texto completo de cada partida fica
em `checagens-<n>.txt` da pasta que a prova recebeu.

| grupo | o que a régua acha | onde aparece (exemplos) |
| --- | --- | --- |
| letra abaixo de 30 px | o texto de apoio das salas é menor do que se lê do sofá | `Vida 100% · 0 ✓` (29), `Rodada 1 de 8 · 0 ✓` (22), `Brasa · vida 3 · 2 balas` (20), `✕ Quando pronto` (25), os nomes de classe e arma do lobby (24 a 26), `Terminou · 3494` (27) |
| fora da área segura (5%) | o HUD e as dicas dos cantos passam da margem de 96 px na esquerda, de 54 em cima e de 1026 embaixo | `Incline contra o vento`, `Gire para mirar` e `Esquerda` a 30 e 74 px da borda, `Direita` e `Atira` a 1890 px, a linha de placar do 2 contra 2 a 90 px, `FORJA f5d46c2` em y=1000 |
| contraste abaixo de 3:1 | o texto pequeno do canto e o de efeito | `Botão` e `(Pausa)` (2,4 e 2,6), o chip `P1` (2,4), `Valendo!` (2,0) |
| texto em cima de texto | duas frases desenhadas no mesmo lugar | no 2 contra 2, `Brasa · vida 1 · 1 balas` com `Brasa · derrubado` (a linha de vida e a de derrubado, no mesmo lugar, na hora em que o jogador cai) |
| tela parada por mais de 5 s | a sala espera sem mexer quase nada | A Centelha entre duas runas, O Impacto e A Prova mais de 5 s sem mexer quase nada |

O que a prova **não** achou nas quatro partidas: tela vazia, relógio que sobe,
minigame sem vencedor e frase de tela com minúscula.

## O alvo

Cada grupo some na origem: a escala mínima de letra e a margem segura moram no
tema (`godot/scripts/tema.gd`) e valem para todo `Desenho.texto`; as dicas
dos cantos e o HUD de cada sala partem da margem do tema; o par de textos que
se encavala é uma tela com dois estados desenhados juntos, e a cura é desenhar
um só. A tela parada é decisão de jogo (o que a sala mostra enquanto espera),
não da régua: ver cada caso na prancha antes de mexer.

## Passos

1. Ler as quatro pranchas (`bash tests/prova_visual.sh pasta/`) e separar o que
   é defeito do que é espera de propósito (a tela parada).
2. A letra mínima e a margem segura no tema; as salas deixam de escolher o
   próprio tamanho e a própria margem. Conferir o texto de apoio contra a escala
   da opção de tamanho de letra.
3. O texto que se encavala: achar quem desenha a linha de vida e a de derrubado
   do 2 contra 2 no mesmo lugar, e desenhar só uma.
4. O contraste dos textos esmaecidos: o piso do alfa e da cor do texto de canto.
5. Rodar a prova visual e ver a lista esvaziar; cada grupo curado tira a sua
   linha da lista.

## Armadilhas

- A direção de arte nova pode trocar o tema inteiro: não grave número de cor
  nem de posição que só valha para o tema de hoje; a régua da prova é a medida.
- A prova da nuvem é por software: as réguas de contraste leem o pixel do
  quadro dela, e a cor final de verdade é a da placa de vídeo. O que a régua
  reprova por pouco (2,8 a 3,0) vale conferir na máquina do André.
- `--fixed-fps 60` e o renderizador por software escondem as travadas: a
  passada `livre` é a que mostra os quadros por segundo.

## Não fazer

- Não afrouxar a régua (o mínimo de 30 px, os 5% de margem, o contraste de
  3:1) para a prova passar: a cura é no jogo.
- Não pintar de novo o tema aqui; isso é da direção de arte.

## Pronto quando

`bash tests/prova_visual.sh` passa nas quatro partidas, sem nenhum dos cinco
grupos, e a prancha olhada na máquina do André confirma.

## Provas

- Na sessão: `PASSADAS=fixa bash tests/prova_visual.sh pasta/` verde, e a
  `bash tests/prova_do_jogo.sh`.
- Com o André, local: a passada `livre`, com placa de vídeo, e as pranchas
  olhadas (a aparência é dele).

## Para o André (local)

Olhar as quatro pranchas e dizer qual tela parada é espera de propósito e qual
é travada de verdade.

## Ao terminar

Marcar F09b como **feito** no [quadro](README.md), com o gasto.
