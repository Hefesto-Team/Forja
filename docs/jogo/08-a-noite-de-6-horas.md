# 08 — A noite de seis horas

A validação final não é uma prova sem aparelho: é um jogo completo jogado de
verdade. Quatro pessoas, seis horas, dois controles no cabo e dois no rádio.
O jogo manda e registra tudo; depois da noite, um script cruza o que o jogo
mandou com o que a ponte do rádio registrou e com o que os jogadores fizeram.
Dessa noite sai a inteligência para a próxima.

## O protocolo

| | |
| --- | --- |
| quem | quatro pessoas, pelo menos uma que nunca jogou o Forja |
| controles | P1 e P2 no cabo, P3 e P4 no rádio pela ponte; na metade da noite, trocam (P1 e P2 vão para o rádio) |
| o que se joga | partidas sorteadas de 5 e de 9, com o Relâmpago como aquecimento e como desempate; os 45 minigames aparecem pelo menos uma vez cada |
| pausas | a cada hora, dez minutos; o jogo continua de onde parou |
| como começa | `./run-local.sh -- --relatorios=<pasta da noite>`; a ponte grava o registro dela na mesma pasta |
| o que se anota à mão | só o que o registro não vê: quem pediu "mais uma", quem reclamou do quê, a hora em que o cansaço bateu |

O jogo não pergunta nada a ninguém durante a noite. A validação está no
registro.

## O registro v2

A linha do tempo (`linha-do-tempo-<sessão>.jsonl`) muda de formato, e o
campo `formato` sobe de versão, como manda o
[ADR 003](../adr/003-o-gauntlet.md). Toda linha ganha:

| campo | o que é |
| --- | --- |
| `seq` | número de sequência da saída, por controle, que nunca repete na sessão |
| `t` | o tempo de parede, monotônico, em segundos desde o início da sessão (hoje é soma de `delta`, e passa a ser relógio de verdade) |
| `t_musica` | a posição da música no instante, quando há música |
| `lugar` | 0..3 |
| `transporte` | o que o SDL relata: cabo ou rádio |
| `firmware` | a versão do firmware do controle (na linha de conexão) |

E os tipos novos ou ampliados:

| tipo | o que registra |
| --- | --- |
| `saida` | cada coisa mandada ao controle: vibração (motores, duração), gatilho (modo e parâmetros), barra de luz, luzinhas, luz do mudo, áudio HID; com `seq` e se o SDL aceitou |
| `som_controle` | cada som mandado ao alto-falante ou aos atuadores: qual, ganho, placa, se a placa existia |
| `nota` | cada nota pedida a um jogador: o instante esperado na música e o minigame |
| `toque` | cada toque do jogador: o instante, a nota a que respondeu, o desvio em ms, o julgamento |
| `minigame` | início, fim, vencedor, pontos, itens, duração |
| `calibracao` | o desvio medido na construção do cavaleiro |
| `sessao` | a escala de vibração e de volume de cada lugar, o idioma, a versão |

O registro de texto e o relatório continuam como estão. O relatório de fim
de sessão deixa de ser a voz do jogo para o jogador e passa a ser só a do
Modo bancada e a da noite.

## O cruzamento

`scripts/cruzar_noite.py` roda depois da noite, fora do jogo, sobre a pasta
dos registros:

1. lê a linha do tempo do jogo e o registro da ponte;
2. casa cada `saida` do jogo com a saída correspondente da ponte, por
   controle, pela ordem e pela janela de tempo; o jogo nunca fala com a
   ponte — o encontro é só nos arquivos, depois;
3. casa cada `nota` com o `toque` do jogador.

E responde, por controle e por transporte:

| pergunta | a conta |
| --- | --- |
| o jogo mandou quanto? | saídas por tipo |
| o SDL aceitou quanto? | saídas com `ok` |
| a ponte recebeu quanto? | saídas casadas no registro da ponte |
| a ponte traduziu quanto? | saídas que a ponte registra como escritas no rádio |
| o jogador percebeu? | nos minigames em que a pista era só no controle: acertos depois de uma pista contra acertos sem pista |
| o tempo de cada um | o desvio médio e o espalhamento dos toques, por hora |
| o cansaço | o desvio e os erros por hora de noite |
| o item | as vitórias por item |
| a diversão | "mais uma?" e as notas à mão |

A saída é um relatório em texto e uma tabela, na pasta da noite:
"O jogo mandou 41.203 vibrações ao P3; o SDL aceitou 41.203; a ponte
registrou 38.910; P3 respondeu às pistas só de vibração em 71% das vezes, P1
em 94%." É desse tipo de linha que a próxima rodada de trabalho sai.

## Pronto quando

A noite acontece, os quatro jogam seis horas com vontade, e o cruzamento
responde as perguntas acima para os quatro controles nos dois transportes.
