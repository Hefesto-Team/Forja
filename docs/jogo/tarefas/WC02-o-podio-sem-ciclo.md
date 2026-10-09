# WC02 — O pódio que não depende da ordem dos presentes

**Sprint:** W · **Tamanho:** P · **Depende de:** — (vai antes da X02, que leva a `partida.gd` para o pacote sem
mudar comportamento)

## Por quê

No empate de pontos e de salas vencidas, o desempate compara cada par de jogadores só nas salas em que os dois
estiveram. Quando alguém faltou a uma sala (o controle caiu, entrou depois), isso fecha um ciclo: A acima de B, B
acima de C e C acima de A. O `podio` ordena por essa comparação, e uma comparação sem transitividade dá um pódio que
muda conforme a ordem em que os presentes chegam à lista. O mesmo jogo pode coroar dois vencedores diferentes, e o
sorteio da semente, que existe para o empate de verdade, nunca chega a decidir.

## Ler antes

- `godot/scripts/partida.gd` (o comentário do topo diz a regra do desempate)
- [X02 — O pacote do placar](X02-o-pacote-do-placar.md) (o que vem depois desta)

## O estado de hoje (medido em 09/10/2026)

- `godot/scripts/partida.gd:122` ordena por pares:

  ```gdscript
  lista.sort_custom(func(a, b): return _acima(int(a.lugar), int(b.lugar)))
  ```

- `godot/scripts/partida.gd:135-139`, o desempate pela história, só nas salas em que os dois estavam:

  ```gdscript
  for k in range(historico.size() - 1, -1, -1):
  	var ca := int(historico[k].colocacao[a])
  	var cb := int(historico[k].colocacao[b])
  	if ca != cb and ca > 0 and cb > 0:
  		return ca < cb
  ```

- As ausências acontecem no jogo: o `main` registra como presente só quem estava `jogando` naquela sala
  (`godot/scripts/main.gd:433-437`), e o `jogando` é posto a partir dos jogadores que a sala tinha ao começar
  (`godot/scripts/salas/sala_jogo.gd:335-336`).
- O ciclo, conferido à mão no código: três jogadores e três salas, com os presentes (P1, P3), (P2, P3) e (P1, P2), e
  o vencedor de cada uma P1, P3 e P2. Os totais ficam 7, 7 e 7, as vitórias 1, 1 e 1. P2 fica acima de P1 (a terceira
  sala), P3 acima de P2 (a segunda) e P1 acima de P3 (a primeira). Rodado num rascunho fora da árvore, com a
  `partida.gd` copiada: com os presentes na ordem [0, 1, 2], o pódio sai P3, P1, P2; na ordem [2, 1, 0], sai P1, P2,
  P3.
- A prova de hoje (`godot/testes/prova_do_jogo.gd:793`, a `_prova_das_contas_da_partida`) só tem partidas com todos
  presentes em toda sala.

## O alvo

O pódio ordena por uma chave total, nunca por uma comparação de pares solta:

1. os pontos da noite;
2. as salas vencidas;
3. dentro de cada grupo ainda empatado, as colocações nas salas em que **todos** os do grupo estiveram, da última
   para a primeira (a mesma lista de salas para o grupo inteiro);
4. o sorteio da semente.

O `_criterio` diz o mesmo que a ordenação usou. Com todos presentes em toda sala, o resultado é idêntico ao de hoje.

## Arquivos que mudam

- `godot/scripts/partida.gd`
- `godot/testes/prova_do_jogo.gd` (a `_prova_das_contas_da_partida`; ou `checagens/sistema_partida.gd`, se a V02
  já entrou)

## Passos

1. Escrever o teste antes: o cenário acima dá o mesmo pódio nas seis ordens dos presentes, e o critério do primeiro é
   «o sorteio» (os três nunca estiveram juntos numa sala).
2. Trocar o `sort_custom` por pares por uma ordenação em grupos: agrupa por pontos e vitórias, e cada grupo com mais
   de um se ordena pelas salas comuns ao grupo, depois pelo sorteio.
3. O `_criterio` lê a mesma conta.
4. As provas de hoje da partida seguem verdes sem mudar uma linha delas.

## Armadilhas

- Um grupo de quatro empatados pode se partir em dois na primeira sala comum e continuar empatado dentro de cada
  metade: a lista de salas comuns é a do grupo de antes da partição, não se recalcula a cada passo (senão o ciclo
  volta por outro caminho).
- O [Relâmpago](R-o-relampago.md) pode virar desempate de partida (o 03 diz «de desempate no fim»): deixe o
  critério 3 num lugar só, para a R trocar sem reescrever o pódio.
- A frase do pódio (`Placar.frase_do_vencedor`) mostra o critério: o texto de cada critério não muda.

## Não fazer

- Não mudar a regra quando todos estiveram em toda sala: as provas de hoje são a régua disso.
- Não mexer na conta da colocação por sala (`colocacoes`) nem nos pontos da noite.

## Pronto quando

O teste do ciclo dá o mesmo pódio nas seis ordens, e a `_prova_das_contas_da_partida` e a `_prova_da_partida`
passam como antes.

## Provas

- `bash tests/prova_do_jogo.sh` (a `_prova_das_contas_da_partida`, com o caso novo, e a `_prova_da_partida`).

## Para o André (local)

Nada: a conta é pura e a prova a cobre.

## Ao terminar

Marcar WC02 como **feito** no [quadro](README.md), com o gasto. A X02 leva a regra nova para o pacote.
