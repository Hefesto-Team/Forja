# F09d — A espera que vive

**Sprint:** F · **Tamanho:** M · **Depende de:** F09b, F09c

## Por quê

A prova visual reprova a tela que fica mais de 5 s quase sem mexer, e depois da F09b é o único defeito que sobra
nas partidas: A Centelha entre duas runas, O Impacto esperando o próximo golpe, A Prova entre as perguntas e A
Galeria no cabo que cai. Do sofá, uma tela parada parece jogo travado.

**A decisão dela (09/10/2026): sempre algo vivo.** Nenhuma espera fica mais de 5 s parada. A régua da prova visual
continua como está (não ganha tolerância por sala); quem muda é a sala.

## Ler antes

- [F09b — os achados da prova visual](F09b-os-achados-da-prova-visual.md#o-que-foi-feito-leva-1-a-fita), o «O que não curei».
- [A arquitetura — a prova visual](../13-arquitetura.md#a-prova-visual--f09)

## O estado de hoje

Medido pela F09b (semente 7, `PASSADAS=fixa`): a tela parada aparece nas partidas 1 a 4, nas quatro esperas acima.
As pranchas estão na pasta `visual-f09b-todas/fixa/` da rodada da a-fita.

## O alvo

Toda espera mostra que o jogo está vivo e o que vem a seguir, com o que a sala já tem e sem texto novo de
metalinguagem:

- **A Centelha, entre as runas:** a próxima runa se anuncia (o anel cresce ou pulsa na batida até ela chegar).
- **O Impacto, antes do golpe:** a ameaça se prepara à vista (o golpe carrega na batida).
- **A Prova, entre as perguntas:** a contagem até a próxima pergunta, na batida.
- **A espera do controle que cai:** a tela de reconectar da [F09c](F09c-o-controle-que-cai-sozinho.md) respira (a
  luz do lugar pulsa).

Com o movimento reduzido ligado (G16), o movimento fica menor, mas não some: a prova roda também nesse modo.

## Passos

1. Rodar a prova visual na base e anotar, por partida, cada tela parada (sala, segundo, duração).
2. Em cada sala, o movimento da espera vem da batida (`Ritmo`) e das cores do `Tema`, nunca de um laço próprio.
3. Refazer as quatro partidas (`PASSADAS=fixa`) e a passada com o movimento reduzido.

## Não fazer

- Não mexer no limite de 5 s nem abrir exceção por sala na régua.
- Não pôr texto novo de espera («Aguarde...»): a espera se mostra pelo mundo.

## Pronto quando

A prova visual passa nas quatro partidas, com e sem o movimento reduzido, sem nenhuma tela parada.

## Provas

- `bash tests/prova_visual.sh` nas quatro partidas (`PASSADAS=fixa`) e com o movimento reduzido.
- `bash tests/prova_do_jogo.sh` segue verde.
- A mordida: tirar o movimento de uma das esperas e ver a prova visual reprovar a tela parada naquela sala.

## Para o André (local)

Jogar as quatro salas na TV e dizer se a espera parece viva sem cansar a vista.
