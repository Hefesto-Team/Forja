# ADR-003: o gauntlet — o jogo como bateria de regressão do Hefesto

**Status:** aceito · **Data:** 2026-09-27
**Decisão:** de quem mantém o projeto, em 27/09/2026

## Contexto

> *"A ideia é depois automatizarmos os testes através dele. Como gauntlet de
> teste, pra vermos se tal sprint ou correção funciona ou não."*

Para um jogo virar régua de sprint, a mesma partida tem de poder ser refeita, e
o que ela mandou tem de poder ser comparado com o que chegou.

## Decisão

1. **Sorteio com semente.** Todo acaso das salas (de onde vem o tiro, quando é o
   susto) sai de uma semente que vai para o relatório. `--semente N` refaz a
   mesma partida.
2. **Linha do tempo legível por máquina.** Além do registro em texto, cada
   sessão grava `linha-do-tempo-<sessão>.jsonl`: uma linha por saída (o que foi
   mandado, a quem, e se o SDL aceitou), por marco de entrada e por
   confirmação. É o que um verificador externo compara com o que o Hefesto
   repassou. Na versão 2, toda linha tem `lugar`, o `t` é o relógio de parede
   (o do jogo só com `--acelerado`), toda `saida` tem `seq` por lugar e a
   `conexao` tem `transporte` e `firmware`.
3. **O gauntlet** (`--gauntlet`) roda as salas em sequência, com a semente
   fixa, e fecha com o relatório. Hoje a confirmação é de quem joga; o formato
   já é o que uma automação vai consumir.
4. **O robô do simulador** (`--simular 4 --robo`) joga o gauntlet inteiro sem
   aparelho, sentindo o que o jogo manda pelos callbacks do joystick virtual.
   Ele prova o JOGO no CI; o Hefesto se prova na mesa.
5. **A prova da prova.** Uma régua que nunca reprova não mede nada. O
   simulador aceita `--defeito`, que põe entre a mão do robô e o jogo os
   defeitos que um intermediário quebrado produziria: ✕ e ○ trocados, curso do
   analógico cortado, gatilho que chega digital, eixo do giroscópio invertido,
   acelerômetro em escala errada, segundo dedo perdido, clique do touchpad que
   não chega. `scripts/gauntlet.sh` roda o gauntlet limpo (todo veredito tem
   de ser PASSOU) e cada defeito (a feature dele tem de ser FALHOU). Com
   `--acelerado`, o tempo do jogo anda sem esperar o relógio e a bateria
   inteira cabe em poucos minutos.
6. **FALHOU só com evidência.** O que a sala não chegou a pedir (o jogador não
   alcançou a pedra, a runa do botão não acendeu antes do fim) fica NÃO MEDIDO,
   com o porquê — um defeito numa parte da sala não reprova, em cascata, a
   feature da parte seguinte.

## Consequências

- Nenhuma sala sorteia fora da semente.
- Mudou o formato da linha do tempo, muda a versão no campo `formato` — quem
  automatiza lê a versão antes de comparar.
- "Passou no robô" nunca é "passou no aparelho": o relatório de uma sessão
  simulada diz isso na primeira nota.
- Toda sala nova entra com o defeito que ela tem de pegar, na lista do
  `scripts/gauntlet.sh`.
