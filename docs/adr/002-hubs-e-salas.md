# ADR-002: hubs e salas — os padrões dos jogos comerciais, reproduzidos em casa

**Status:** aceito · **Data:** 2026-09-27
**Decisão:** de quem mantém o projeto, em 27/09/2026

## Contexto

Para saber se o Hefesto entrega uma feature, é preciso um jogo que a use.
Ninguém tem todos os jogos da Steam, e os que existem mudam de versão, de
Proton e de comportamento sem aviso:

> *"não tenho todos os jogos do mundo na steam e preciso ter uma forma caseira
> via jogo real pra permitir o fácil teste de todas elas."*

## Decisão

O jogo é um **hub** — o Salão da Forja, onde os quatro jogadores andam — com
**salas**. Cada sala reproduz um padrão que os jogos comerciais usam, e valida
uma família de features:

| sala | o padrão de jogo | o que valida |
| --- | --- | --- |
| A Centelha | runas que acendem ao apertar | botões, analógicos, gatilhos analógicos |
| A Viga | equilíbrio e mira por movimento | giroscópio, acelerômetro, taxa declarada × medida |
| O Molde | desenhar e moldar no touchpad | dois dedos, clique |
| O Cerco | dano direcional: tiro da esquerda vibra só a esquerda; a luz pisca vermelho e apaga com a vida | motor forte e fraco, isolamento, lightbar |
| A Galeria | armas com gatilho: clique da pistola, metralhadora, arco; munição nos LEDs | gatilhos adaptativos, LEDs de jogador |
| A Cripta | terror: silêncio no microfone, susto com vibração e grito no alto-falante do controle | microfone, mudo, LED do microfone, alto-falante |
| Os Caminhos | o chão que se sente: grama, cascalho, metal | háptica por áudio (canais 3 e 4) |
| O Canto | o ritmo da bigorna sai do SEU controle, e você o repete | alto-falante, isolamento do som |
| A Prova | 2 contra 2, noventa segundos, tudo ligado | tudo junto |

O hub também tem a **bancada** (o diagnóstico ao vivo, que serve para
apresentar o Hefesto) e o **livro** (o relatório da sessão).

**A lightbar do DualSense é uma cor só** para as duas fendas: o lado de um
golpe vem do motor, e a luz inteira pisca. Não há como acender só a fenda da
esquerda pelo HID.

## Consequências

- Uma sala nova é um padrão de jogo novo — quando um jogo comercial mostrar um
  uso que o Hefesto precisa cobrir, ele vira sala.
- Cada sala isola a sua família: o que ela usa "de enfeite" não entra no
  veredito dela. A Prova é a única que liga tudo, e vem por último.
- Mais hubs cabem no mesmo desenho (um de apresentação, por exemplo) sem mexer
  nas salas.
