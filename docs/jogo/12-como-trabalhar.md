# 12 — Como trabalhar

O jeito de tocar o Forja daqui para a frente: sem data, uma tarefa por vez,
de um jeito que qualquer pessoa, em qualquer sessão de trabalho, pegue uma
ficha, faça e entregue sem precisar entender o projeto inteiro. É também
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
- **Sprint, tamanho e estimativa.**

## O ciclo de uma ficha

1. Pegar a primeira ficha **a fazer** do quadro e marcar **fazendo**.
2. Abrir uma sessão **nova**. Uma ficha, uma sessão.
3. Pedir: "Faça a ficha `docs/jogo/tarefas/<ficha>.md`". A sessão lê a ficha,
   os arquivos que ela cita e as [regras de execução](o-time/regras.md) — nada mais.
   O «Ler antes» se lê por `python3 scripts/ler_antes.py <ficha>`, que imprime só a seção de cada link.
4. Fazer, rodar a prova rápida (`bash tests/prova_do_jogo.sh`) e commitar
   (`feat:`/`fix:`/`docs:`, sem trailer). O código de arquivo inteiro (o bloco com `arquivo=` na cerca) sai por
   `python3 scripts/ficha_codigo.py <ficha> --escrever`; depois, leia o diff e conserte só o que diverge da API
   de hoje (`--conferir` mostra a diferença entre a ficha e o arquivo).
5. No mesmo commit: marcar a ficha **feito** no quadro.
6. A sessão termina dizendo ao André, em uma lista curta, o que ele precisa
   rodar e jogar na máquina dele.
7. O André roda, joga, e cola só o resumo (ou o trecho que falhou) na próxima
   sessão, ou na própria ficha.

Uma ficha que cresceu demais vira duas: a sessão para, escreve a segunda
ficha e põe no quadro.

**Ficha visual** (tela, arte, câmera, HUD, minigame) só vira **feito** depois
da prova visual (`bash tests/prova_visual.sh`, da [F09](tarefas/F09-a-prova-visual.md))
e da prancha olhada. Foto escolhida não fecha ficha: na primeira noite, as
fotos estavam certas e o jogo não.

## O diário do André

Quando o André joga ou olha uma prancha, ele anota numa linha por coisa
vista, no fim da ficha (ou num `docs/jogo/tarefas/diario.md`, se não for de
uma ficha só):

```
21:14 · S03_J12 Quebra-Gelo · P2 · o bloco nasceu atrás da câmera
21:20 · resultado · — · o nome do vencedor cortado na borda
```

A hora casa com a linha do tempo e com a prancha. A próxima sessão lê o
diário e resolve linha por linha; o que não couber na ficha vira ficha nova.

## O que roda onde

| onde | o quê |
| --- | --- |
| **na sessão** (nuvem) | a prova rápida (`bash tests/prova_do_jogo.sh`); `scripts/compilar.sh testes` quando mexeu no módulo |
| **na sessão**, depois da F09 | a prova visual com `--fixed-fps 60` (`bash tests/prova_visual.sh`): a disposição, a tela parada, o texto, o relógio, o fim |
| **com o André** (local, de graça) | o gauntlet e a prova de poucos (`scripts/gauntlet.sh`, `bash tests/prova_de_poucos.sh`), a bancada com aparelho, a exportação, a prova visual sem `--fixed-fps` na placa de vídeo (a aparência só se aprova aqui), e jogar para sentir |

O que a nuvem não vê — a vibração na mão, o som no controle, a graça — só o
André confere.

## A economia de contexto

- Uma ficha por sessão; sessão nova é mais barata que uma sessão longa.
- A ficha já diz os arquivos: nada de exploração fora deles.
- Não reler `docs/jogo/` inteiro; só os links da ficha.
- Log grande não se cola: só o trecho que falhou.
- Resultado do André em resumo: "gauntlet 20/20, a prova de poucos falhou na
  Viga com 2 jogadores: <3 linhas>".

## O kit do minigame

A ficha [H04](tarefas/H04-o-kit-do-minigame.md) é a que mais economiza. As
salas de hoje repetem de 30 a 60 linhas cada (medido na H04: a raia,
`_conectado`, `RAIAS`, as guardas de `dica` e `status`). Mais do que as
linhas, o kit tira as **decisões** da sessão: relógio, julgamento, item,
falas, fechamento e registro já estão resolvidos. Com ele, um minigame é a
[ficha de dados](tarefas/molde-de-minigame.md) mais os ganchos que são só
dele — **uma ficha por minigame, uma sessão por ficha**.

## O orçamento

**O que economiza é a sessão curta.** As fichas já trazem o código de hoje, a API alvo e as
checagens prontas, então a sessão executa sem explorar. O planejamento (a arquitetura e estas fichas)
foi feito à parte, de propósito: planejar bem é o que deixa a execução barata e fácil.

## Para quem chega agora

1. Leia o [README desta pasta](README.md) e as regras de ouro.
2. Leia o [CONTRATO](../../CONTRATO.md) e o [COMO-CONTRIBUIR](../COMO-CONTRIBUIR.md).
3. Abra o [quadro](tarefas/README.md), pegue a primeira ficha **a fazer**.
