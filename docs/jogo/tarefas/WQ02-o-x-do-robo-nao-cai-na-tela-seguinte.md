# WQ02 — O ✕ do robô não cai na tela seguinte

**Sprint:** W · **Tamanho:** P · **Depende de:** — (vai antes da [WQ01](WQ01-os-erros-do-motor-reprovam.md); mexe no
`forja.gd`, que a X04 e a X05 levam para os pacotes: vai antes delas)

## Por quê

O robô de fluxo aperta ✕ um pouco depois de uma sala pedir, «como uma pessoa que leu a tela». A função promete que,
se a sala que pediu já saiu, o robô desiste e o ✕ não cai na tela seguinte. Ela faz o contrário. Quando a sala é
liberada antes do temporizador, o GDScript entrega `null` no lugar do nó capturado, e o teste `dono == null`, que
existe para quem não passou dono, fica verdadeiro: o robô aperta ✕ justamente na tela seguinte (o placar, um aviso
ou outra sala). O fluxo da partida pode andar sozinho e mudar o que a prova mede depois. O motor avisa a cada vez,
com 14 «Lambda capture at index 0 was freed» nos registros da prova do jogo de 09/10.

## Ler antes

- [X05 — O pacote do robô de prova](X05-o-pacote-do-robo.md) (para onde o robô vai depois)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `godot/scripts/forja.gd:1068-1083`:
  ```gdscript
  ## ... Se vier um `dono` (a
  ## tela que pediu o ✕) e ele já saiu da árvore na hora de apertar, o robô
  ## desiste: o ✕ não cai na tela seguinte.
  func robo_confirmar(l: int, depois_s: float, dono: Node = null) -> void:
  	...
  	get_tree().create_timer(depois_s).timeout.connect(func() -> void:
  		if dono == null or (is_instance_valid(dono) and dono.is_inside_tree()):
  			_robo_apertar_cru(l, CRUZ, 0.09))
  ```
- O único chamador com dono, `godot/scripts/salas/sala_jogo.gd:259`:
  `Forja.robo_confirmar(p.lugar, 1.4 + 0.2 * p.lugar, self)`; nos temperamentos que erram, mais 1,5 a 3 s
  (`forja.gd:1076-1077`).
- Os registros (prova do jogo, semente 7): 7 «Lambda capture» em cada rodada, um por jogador da sala que acabou,
  logo depois de «o motor parou: a háptica volta» e entre «partida: centelha é a sala 1 de 3» e «partida: o placar
  depois d'O Martelo de Hefesto».

## O alvo

Quem passou dono e viu o dono sair não aperta nada. Quem não passou dono aperta como hoje. A assinatura de
`robo_confirmar` não muda.

## Arquivos que mudam

- `godot/scripts/forja.gd` (o `robo_confirmar`)
- `godot/testes/prova_de_poucos.gd` (o caso novo)

## Passos

1. Antes do temporizador, guardar se houve dono (`var tem_dono := dono != null`) e o id dele
   (`dono.get_instance_id()`), e não capturar o nó.
2. Na função do temporizador: sem dono, aperta; com dono, aperta só se `is_instance_id_valid(id)` e o nó de
   `instance_from_id(id)` está na árvore.
3. O caso de prova: abrir uma sala de jogo com o robô, liberá-la antes de 1,4 s e conferir que o pad simulado do
   lugar não recebe ✕ nos quadros seguintes.

## Armadilhas

- **Não trocar o `dono == null` por `is_instance_valid(dono)` apenas:** o chamador sem dono (`main.gd:574`) tem de
  continuar apertando.
- **O caso de prova precisa liberar a sala de verdade** (`queue_free` e um quadro), não só tirá-la da árvore, para
  reproduzir o `null` da captura.

## Não fazer

- Não mudar os atrasos do robô nem os temperamentos.
- Não mexer no `_robo_apertar_cru`.

## Pronto quando

Na prova de poucos, a sala liberada antes do ✕ não deixa ✕ chegar ao pad, e nenhum registro de prova tem «Lambda
capture» (hoje, 14 na prova do jogo).

## Provas

- `bash tests/prova_de_poucos.sh` e `bash tests/prova_do_jogo.sh`, pela caixa e pelo semáforo da máquina;
  `grep -c 'Lambda capture'` no registro dá 0.

## Para o André (local)

`./run-local.sh -- --simular=4 --robo` e assistir a uma partida: depois de cada sala, o placar fica na tela o tempo
dele, sem pular sozinho.

## Ao terminar

Pôr a linha da WQ02 no [quadro](README.md) como **feito**, com o commit.
