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
   repassou.
3. **O gauntlet** (`--gauntlet`) roda as salas em sequência, com a semente
   fixa, e fecha com o relatório. Hoje a confirmação é de quem joga; o formato
   já é o que uma automação vai consumir.
4. **O robô do simulador** (`--simular 4 --robo`) joga o gauntlet inteiro sem
   aparelho, sentindo o que o jogo manda pelos callbacks do joystick virtual.
   Ele prova o JOGO no CI; o Hefesto se prova na mesa.

## Consequências

- Nenhuma sala sorteia fora da semente.
- Mudou o formato da linha do tempo, muda a versão no campo `formato` — quem
  automatiza lê a versão antes de comparar.
- "Passou no robô" nunca é "passou no aparelho": o relatório de uma sessão
  simulada diz isso na primeira nota.
