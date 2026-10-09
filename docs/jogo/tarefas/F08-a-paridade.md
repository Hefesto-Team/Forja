# F08 — A paridade entre a prova e o jogo

**Sprint:** F · **Tamanho:** M · **Depende de:** F00, F01, F03

## Por quê

Durante os testes queremos validar tudo. Isso só vale se o que a prova
percorre é exatamente o que o jogador percorre. Hoje o robô pula etapas por
atalhos no código do jogo, e a prova passa por caminhos que ninguém joga.

## Ler antes

- [A arquitetura — a paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)

## O estado de hoje

Os atalhos do robô no código do jogo (fora da função `_robo` de cada sala):

| onde | o atalho |
| --- | --- |
| `godot/scripts/salas/sala_jogo.gd:237` | `if Forja.apertou(l, Forja.CRUZ) or (Forja.robo and t_fase > 1.4 + 0.2 * l):` — o robô fica pronto sem apertar ✕ |
| `godot/scripts/salas/sala_jogo.gd:385` | `if Forja.robo and t_fase > 3.0: terminou.emit()` — o fim da sala avança sozinho |
| `godot/scripts/main.gd:493` | `if Forja.robo and "--sair-no-fim" in ... and placar._t > 3.0:` — o pódio sai sozinho |
| `godot/scripts/main.gd:873` | `if Forja.robo and placar._t > Placar.T_PRONTO + 0.6:` — o placar avança sozinho |
| `godot/scripts/main.gd:791` | `Opcoes.gravar(Forja.robo)` — com robô, as opções não são gravadas (este fica: é para não sujar o `opcoes.cfg` da máquina) |

Dentro das salas, o robô já joga pelo controle simulado:
`Forja.robo_apertar`, `robo_eixo`, `robo_girar`, `robo_tocar`, `robo_falar`,
`robo_sacudir` (`godot/scripts/forja.gd`, a partir da linha 875). Há
`if Forja.robo:` em cada sala que chama o `_robo` dela
(`centelha.gd:245`, `galeria.gd:244`, `viga.gd:287`…), e isso fica.

## O alvo

As regras da [arquitetura](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08).
Em resumo: o robô aperta ✕ no controle simulado como uma pessoa; `Forja.robo`
só aparece no gancho do robô; a prova do jogo roda sem `--bancada`; e uma
checagem estática impede a volta dos atalhos.

## Passos

1. Um robô de fluxo em `godot/scripts/forja.gd`: `robo_confirmar(l, depois_s)`
   aperta ✕ no controle simulado do lugar depois de um atraso (usa
   `robo_apertar`).
2. `sala_jogo.gd:237`: tirar o `or (Forja.robo and …)`; no lugar, a sala
   chama `Forja.robo_confirmar(l, 1.4 + 0.2 * l)` uma vez, quando o aviso
   começa, se `Forja.robo`.
3. `sala_jogo.gd:385`: tirar o avanço automático do robô. Com a tela de
   resultado da F03, o fim já avança sozinho em 6 s para todo mundo; o robô,
   se quiser pular, aperta ✕ pelo controle.
4. `main.gd:873` e `main.gd:493`: mesma troca — o placar e o pódio avançam
   pelo ✕ simulado (ou pelo avanço automático que vale para todo mundo).
5. Juntar em `godot/scripts/forja.gd` um comentário na seção do robô: "o robô
   só age pelo controle simulado; ver docs/jogo/13".
6. A checagem estática, em `godot/testes/prova_do_jogo.gd`: ler cada `.gd` de
   `res://scripts/` e reprovar `Forja.robo` fora de `forja.gd`, de
   `main.gd:791` (as opções) e das funções `_robo`/`robo`.
7. Conferir que a F01 deixou as duas rodadas em `tests/prova_do_jogo.sh` (a
   "forma-a" sem `--bancada`, a "antes" com `--bancada`), e que
   `scripts/gauntlet.sh` e `tests/prova_de_poucos.sh` passam `--bancada`
   (eles conferem os vereditos das perguntas).
8. A prova do aviso de 8 s da F03 desliga o `Forja.robo` só dentro da prova,
   porque até aqui era o único jeito de ter "ninguém apertou". Com o ✕ pelo
   simulador, trocar isso por um robô que simplesmente não aperta.
9. `tests/prova_da_exportacao.sh`: rodar o mesmo roteiro de robô no pacote
   exportado.

## Armadilhas

- Os tempos das provas mudam: o robô agora espera o ✕ chegar pelo simulador
  (dois quadros para apertar, dois para soltar). O `timeout 1200` do
  `tests/prova_do_jogo.sh` sobra, mas as esperas em quadros dentro de
  `prova_do_jogo.gd` podem precisar crescer.
- O `grep` da checagem precisa ignorar comentários e a própria função do
  robô; teste a checagem pondo um atalho de propósito e vendo reprovar.
- `--sair-no-fim` é um argumento de prova que encurta o fim: ele passa a
  apertar ✕ pelo simulador, não a sair por atalho.

## Não fazer

- Não reescrever o `_robo` de cada sala (isso vai com as seções).
- Não mudar regra de jogo para "facilitar a prova".

## Pronto quando

Nenhum `Forja.robo` fora do gancho do robô, das opções e do `forja.gd`; a
prova do jogo passa sem `--bancada` pelo fluxo inteiro e passa de novo com
`--bancada`; a prova da exportação roda o mesmo roteiro no pacote.

## Provas

- Na sessão: `bash tests/prova_do_jogo.sh` (as duas rodadas) e a checagem
  estática reprovando um atalho plantado de propósito (e depois tirado).
- Com o André, local: `scripts/gauntlet.sh`, `bash tests/prova_de_poucos.sh`
  e `scripts/exportar.sh linux && bash tests/prova_da_exportacao.sh`.

## Para o André (local)

Rodar o gauntlet e a exportação, e conferir que uma partida jogada à mão
passa pelas mesmas telas que a prova percorreu.

## Ao terminar

Marcar F08 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `fix: o robô só joga pelo controle, e a prova percorre o jogo que se joga`.

## O que foi feito (leva 1, as-provas)

- Medido antes: a prova rápida passava verde (as duas rodadas) com os atalhos no
  lugar. Dos quatro atalhos da tabela, o de `sala_jogo.gd:385` já tinha saído
  com a F03 (o fim avança em 6 s para todo mundo); restavam o do aviso e o do
  placar, mais o `--sair-no-fim` do pódio.
- `Forja.robo_confirmar(l, depois_s, dono)` (em `forja.gd`): o robô aperta ✕ no
  controle simulado do lugar depois de um atraso; `Forja.robo_confirma` (padrão
  ligado) deixa a prova ter «um robô que não aperta».
- O aviso: `sala_jogo.gd` perdeu o `or (Forja.robo and …)`; o gancho
  `if Forja.robo: _robo_do_aviso()` pede o ✕ de cada lugar uma vez.
- O placar: `main.gd` perdeu o avanço direto; `_robo_do_placar()` aperta ✕ no
  primeiro lugar ocupado, uma vez por placar. O pódio com `--sair-no-fim` virou
  `_robo_do_podio()`: é o fim do processo da prova, não um passo do jogo (o
  pódio não tem botão que feche o jogo).
- A régua: `_prova_da_paridade` em `prova_do_jogo.gd` lê os 44 `.gd` de
  `res://scripts/` e reprova `Forja.robo` fora de `forja.gd`, de `if Forja.robo:`
  sozinho na linha (o gancho), de funções `_robo*`/`robo*` e de
  `Opcoes.gravar(Forja.robo)`. Em `bancada.gd` três condições misturadas viraram
  gancho (`if Forja.robo:` com o resto dentro), sem mudar o comportamento.
- Na conferência: a régua aceitava a linha `if Forja.robo:` sem olhar o corpo, e
  a bancada escondia ali um atalho (com o robô, fechava sozinha em 2 s: somava o
  relógio, gravava e saía). Agora o robô da bancada aperta ○ no controle simulado
  (`_robo_do_fim`, o mesmo ○ que grava e fecha para a pessoa), e a régua lê o
  corpo do gancho: ali só cabe percorrer os lugares, decidir, ler numa variável
  local e chamar o robô; o resto reprova («dentro do gancho do robô»). A régua
  morde a bancada antiga (três linhas) e o atalho plantado dentro do gancho.
- A prova do aviso de 8 s usa `Forja.robo_confirma = false` em vez de desligar
  `Forja.robo`; e cada sala confere que o aviso passou pelo ✕ do controle
  (antes dos 8 s), não pelo relógio.
- `tests/prova_da_exportacao.sh`: além da Prova de Fogo, o binário Linux joga uma
  partida de 3 pelo robô (✕ do aviso e do placar, fim em 6 s) até o pódio, e a
  linha do tempo confere as 3 salas, os 3 placares e a partida terminada.
- O passo 7 (as duas rodadas; `--bancada` no gauntlet e na prova de poucos) já
  estava pronto pela F01: conferido, não refeito.

**As provas.** `bash tests/prova_do_jogo.sh` verde nas duas rodadas. A régua
morde: com um atalho plantado em `viga.gd` ela reprovou
(`viga.gd:283 … (Forja.robo and t_fase > 1.4)`), e com `robo_confirmar` sem
apertar as nove salas reprovaram («o ✕ veio do controle, não do relógio»);
devolvidos, voltou o verde. A partida de 3 pelo robô, na fonte, deu 3 salas, 3
placares e o fim em 43 s.

**Fica para a mão dela ou do André.** Rodar `scripts/exportar.sh linux && bash
tests/prova_da_exportacao.sh` (precisa dos modelos de exportação e, para o
`.exe`, do Wine do GE-Proton), `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
com o aparelho; e jogar uma partida à mão conferindo que passa pelas mesmas
telas que a prova percorreu. A escolha a validar por ela: o fechamento do
processo no pódio com `--sair-no-fim` ficou como fim da prova, e não como ✕.
