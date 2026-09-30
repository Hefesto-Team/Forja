# 12 — Como trabalhar

O jeito de tocar o Forja daqui para a frente: sem data, uma tarefa por vez,
de um jeito que qualquer pessoa — ou qualquer sessão do Claude Code — pegue
uma ficha, faça e entregue sem precisar entender o projeto inteiro. É também
o jeito mais barato: o que mais custa numa sessão é o contexto que ela carrega.

## O quadro e as fichas

Todo o trabalho está em [tarefas/](tarefas/README.md): um quadro com uma
linha por ficha, na ordem de trabalho, e uma ficha por arquivo. Toda ficha
tem o mesmo molde:

- **Por quê:** uma frase.
- **Ler antes:** de um a três links, e só eles.
- **Arquivos que mudam:** com o caminho.
- **Passos:** de três a oito.
- **Pronto quando:** uma frase que se confere.
- **Provas:** o que roda na sessão e o que o André roda na máquina dele.
- **Sprint, tamanho, modelo e estimativa.**

## O ciclo de uma ficha

1. Pegar a primeira ficha **a fazer** do quadro e marcar **fazendo**.
2. Abrir uma sessão **nova** do Claude Code. Uma ficha, uma sessão.
3. Pedir: "Faça a ficha `docs/jogo/tarefas/<ficha>.md`". A sessão lê a ficha
   e os arquivos que ela cita — nada mais.
4. Fazer, rodar a prova rápida (`bash tests/prova_do_jogo.sh`) e commitar
   (`feat:`/`fix:`/`docs:`, sem trailer).
5. No mesmo commit: marcar a ficha **feito** no quadro e anotar o gasto real
   da sessão.
6. A sessão termina dizendo ao André, em uma lista curta, o que ele precisa
   rodar e jogar na máquina dele.
7. O André roda, joga, e cola só o resumo (ou o trecho que falhou) na próxima
   sessão, ou na própria ficha.

Uma ficha que cresceu demais vira duas: a sessão para, escreve a segunda
ficha e põe no quadro.

## O que roda onde

| onde | o quê |
| --- | --- |
| **na sessão** (nuvem) | a prova rápida (`bash tests/prova_do_jogo.sh`); `scripts/compilar.sh testes` quando mexeu no módulo |
| **com o André** (local, de graça) | o gauntlet e a prova de poucos (`scripts/gauntlet.sh`, `bash tests/prova_de_poucos.sh`), a bancada com aparelho, a exportação, as fotos das telas, e jogar para sentir |

O que a nuvem não vê — a vibração na mão, o som no controle, a graça — só o
André confere.

## A economia de contexto

- Uma ficha por sessão; sessão nova é mais barata que uma sessão longa ou
  compactada.
- A ficha já diz os arquivos: nada de exploração com subagentes.
- Não reler `docs/jogo/` inteiro; só os links da ficha.
- Log grande não se cola: só o trecho que falhou.
- Resultado do André em resumo: "gauntlet 20/20, a prova de poucos falhou na
  Viga com 2 jogadores: <3 linhas>".

## Qual modelo

| modelo | para quê |
| --- | --- |
| Opus 5.5 | o kit do minigame, a primeira ficha de cada sprint, a primeira sessão de cada seção, tudo que mexe no módulo em C, decisão de contrato |
| Sonnet 5.5 | as fichas repetitivas: a varredura de texto, os minigames 3 a 5 de cada seção, as telas, a importação de bonecos |

Cada ficha diz o modelo sugerido. Na dúvida, Sonnet primeiro; se travar,
Opus.

## O kit do minigame

A ficha [H04](tarefas/H04-o-kit-do-minigame.md) é a que mais economiza. As
salas de hoje repetem de 80 a 150 linhas cada (a raia, `_conectado`, `RAIAS`,
as guardas de `dica` e `status`). Com o kit, um minigame novo é a
[ficha de dados](tarefas/molde-de-minigame.md) mais os ganchos que são só
dele. É isso que põe cinco minigames em duas sessões por seção sem perder
qualidade.

## O orçamento

Preços de 30/09/2026, por milhão de tokens:

| modelo | entrada | saída | leitura do cache |
| --- | --- | --- | --- |
| Opus 5.5 | US$ 4 | US$ 20 | US$ 0,20 |
| Sonnet 5.5 | US$ 2 | US$ 10 | US$ 0,20 |

Numa sessão do Claude Code, a maior parte do custo é o contexto relido a cada
turno — e ler do cache custa o mesmo nos dois modelos. Por isso **o que
economiza é a sessão curta**, mais do que trocar de modelo. Uma sessão
enxuta (uma ficha, uns 40 turnos, contexto abaixo de 80 mil tokens) sai por
volta de US$ 1,5 a 2,5; as de seção, que fazem mais código, por volta do
dobro.

| sprint | fichas | estimativa (US$) |
| --- | --- | --- |
| F — a fundação | 7 | 21 |
| G — as telas | 8 | 23 |
| H — o ritmo, o som e o kit | 7 | 20 |
| I–Q — as nove seções | 9 (18 sessões) | 40,5 |
| R — o Relâmpago | 1 | 2,5 |
| S — a noite de seis horas | 1 | 3 |
| **total** | **33** | **110** |

Com 30% de retrabalho, a faixa realista é **US$ 110 a 140**. US$ 80 pagam F,
G, H e as três primeiras seções.

São estimativas. O número real sai do gasto anotado no quadro: depois das
duas primeiras fichas, a tabela é recalibrada.

A regra: **qualidade não se corta.** Quando a verba acaba, o trabalho pausa
numa ficha fechada — commitada, com o quadro atualizado — nunca no meio de
uma. Quem retomar pega a próxima linha do quadro.

## Para quem chega agora

1. Leia o [README desta pasta](README.md) e as regras de ouro.
2. Leia o [CONTRATO](../../CONTRATO.md) e o [AGENTS](../../AGENTS.md).
3. Abra o [quadro](tarefas/README.md), pegue a primeira ficha **a fazer**.
