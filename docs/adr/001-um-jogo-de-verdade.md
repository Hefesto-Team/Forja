# ADR-001: a Tech Demo é um jogo de verdade, e o Hefesto se valida jogando

**Status:** aceito · **Data:** 2026-09-27
**Decisão:** de quem mantém o projeto, em 27/09/2026

## Contexto

A Forja nasceu como mesa de prova do Hefesto: o `CONTRATO.md` já proibia o
teste circular (o jogo perguntar ao Hefesto o que o Hefesto fez). Faltava dizer
o que o jogo **é**. Uma bateria de telas de teste, com perguntas e botões de
"sentiu?", não reproduz o que um jogo comercial faz com o controle — e é isso
que precisa funcionar através do Hefesto.

A frase que decide:

> *"a ideia é ser um jogo real que use todas as features do dualsense e não um
> jogo que sirva como teste circular pro hefesto. (…) usar o hefesto pra que
> através do jogo eu possa validar se o hefesto funciona ou não. aí arrumar o
> hefesto em si."*

## Decisão

1. **A Tech Demo é um jogo.** Cada feature do DualSense entra por uma mecânica,
   do jeito que os jogos a usam: o tiro que vem da esquerda vibra o motor
   esquerdo, a vida acaba e a lightbar apaga, o susto grita no alto-falante do
   controle, a arma tem o clique no gatilho.
2. **O jogo não sabe do Hefesto.** Ele fala com o controle pelo SDL3, como um
   jogo de PC fala. Quem estiver na frente (Hefesto, `hid-playstation`, um
   cabo) é invisível — é o que torna a validação honesta.
3. **O oráculo é a mesa.** O jogo registra o que mandou e o que recebeu; quem
   diz se chegou ao plástico é quem segura o controle. A confirmação acontece
   dentro do jogo, curta, no fim de cada sala — nunca no meio da ação.
4. **O relatório continua.** Por controle e por feature: o que foi pedido, o que
   foi medido, e passou, falhou ou não foi medido.

## Consequências

- Uma mecânica que só existiria para testar (e que nenhum jogo faz) não entra.
- Quando algo falha, a pergunta é "o Hefesto entregou?", e o registro da sessão
  mostra o que o jogo mandou, com hora.
- O mesmo jogo serve para apresentar o Hefesto: quem joga sente a diferença sem
  ler documentação.
