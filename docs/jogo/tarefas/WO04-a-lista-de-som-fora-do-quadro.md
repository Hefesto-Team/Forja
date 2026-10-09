# WO04 — A lista de som fora do quadro

**Sprint:** W · **Tamanho:** M · **Depende de:** [WS03](WS03-a-placa-do-controle-nao-fecha-a-toa.md) (reconciliar
em vez de fechar tudo) e [WN02](WN02-o-som-que-chega-depois-do-controle.md) (relistar uma vez por quadro); mexe em
`nativo/som/som_controle.c`, como a WO03 e a WU04: não voar junto com elas

## Por quê

Cada entrada no lobby e cada cabo que volta no meio de uma sala chama o `som_preparar`, que roda inteiro no quadro do
jogo: fecha as saídas, chama o `pactl` por `popen`, pede a lista ao SDL e reabre. Medido na caixa, cada ✕ de entrada
de P2, P3 e P4 deu um quadro de 155 a 253 ms. No lobby, é um tranco. No meio de um minigame de ritmo, quando um cabo
volta, é um engasgo dentro da música.

A WS03 tira a maior parte (deixa de fechar e reabrir quem não mudou) e a WN02 junta as listas num quadro só. O que
sobra (o `popen` do `pactl`, a lista do SDL e a abertura da saída nova, que no servidor de som real espera o fluxo
ficar pronto) continua no quadro. Esta ficha mede o que sobra depois delas e, se passar de dois quadros, tira esse
trabalho do quadro.

## Ler antes

- [WS03](WS03-a-placa-do-controle-nao-fecha-a-toa.md) e [WN02](WN02-o-som-que-chega-depois-do-controle.md) (o que
  elas já mudam no mesmo caminho)
- [WS — o mapa do som](../revisao/WS-mapa.md)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `nativo/som/som_controle.c:298-305`:
  ```c
  void somc_preparar(Forja *a) {
    somc_encerrar(a);
    zerar();
    abrir_audio();
    listar();
    escolher(a);
  ```
- O `pactl` por `popen`, `nativo/som/som_controle_linux.c:23-24` (`ler_comando`), chamado na lista (`pactl list
  sinks` e `pactl list sources`: de 10 a 30 ms nesta máquina, sem carga).
- Quem chama: `godot/scripts/main.gd:260-275` (`_abrir_o_som`, no fim do `_sincronizar_jogadores` de `:224`), com o
  pio de quem entrou logo depois, em `:275`:
  ```gdscript
  Forja.som_preparar(papel)
  ...
  		Forja.som_falante(l, "pio:%d" % jogadores[l].modelo_i, 0.8)
  ```
  e `main.gd:253` (`_abrir_o_som(true)`, o cabo que volta, no meio de qualquer sala).
- A medida: um bench na caixa (SDL de som falso, `pactl` de mentira) percorrendo o lobby: quadros de 155 a 253 ms a
  cada ✕; o `som_preparar` sozinho, com a síntese em cache, de 101 a 111 ms.

## O alvo

Entrar no lobby e religar um cabo nunca fazem um quadro passar de 33 ms (dois quadros a 60). O `som_preparar` segue
com a mesma assinatura e os chamadores não mudam. O pio de quem entrou toca, mesmo que a saída dele fique pronta um
pouco depois.

## Arquivos que mudam

- `nativo/som/som_controle.c`, `nativo/som/som_controle.h`, `nativo/som/som_controle_linux.c`
- `nativo/godot/forja_som.cpp` (só se o pio precisar esperar a saída: a fila curta do passo 4)
- `godot/testes/` (o bench do lobby como prova)

## Passos

1. **Medir antes de mexer.** Com a WS03 e a WN02 feitas, rodar o bench do lobby e o do cabo que volta. Se o maior
   quadro já fica abaixo de 33 ms, fechar a ficha com a medida no «O que foi feito» e não mudar nada.
2. Se não fica: a lista (o `pactl` e a lista do SDL) passa a rodar num fio de trabalho, disparado pelo
   `somc_preparar`. O resultado volta por uma troca atômica, que o `somc_atualizar` (que já roda a cada quadro) aplica.
   Enquanto isso, as saídas que a WS03 manteve seguem tocando.
3. A abertura da saída nova vai no mesmo fio, e entra no conjunto pela mesma troca.
4. O pio pedido antes de a saída ficar pronta entra numa fila curta, de um som por lugar, que a troca descarrega.
   Passou de meio segundo, o pio é descartado, com uma linha no registro.
5. O bench do lobby e o do cabo viram prova, com a régua de 33 ms.

## Armadilhas

- **O `alimentar` roda no fio do som** (`som_controle.c:55-65`) com o ponteiro da saída: a troca não pode liberar
  uma saída que o fio do som ainda lê. Siga a ordem que o `fechar_saida` já usa.
- **Dois `preparar` seguidos** (dois ✕ no mesmo quadro): o segundo pedido substitui o que está em voo, e só o último
  resultado vale.
- **O fim do jogo** (`som_encerrar`) espera o fio de trabalho terminar antes de fechar.
- **O Windows** acha o som pelo aparelho (`som_controle_windows.c`), não pelo `pactl`: o fio vale para os dois, e a
  prova do Windows ([WU02](WU02-o-windows-provado-num-windows.md)) tem de seguir verde.

## Não fazer

- Não mudar quem chama em `main.gd` e `sala_jogo.gd`.
- Não esconder o tranco atrás da cortina: o cabo que volta acontece em jogo.
- Não refazer o que a WS03 e a WN02 entregam.

## Pronto quando

No bench do lobby (P1 entra, e P2, P3 e P4 apertam ✕) e no do cabo que volta no meio de uma sala, o maior quadro fica
abaixo de 33 ms (hoje, de 155 a 253 ms), e o pio de quem entrou aparece no registro do som.

## Provas

- O bench do lobby e o do cabo, pela caixa da WE01 e pelo semáforo da máquina.
- `bash tests/prova_do_jogo.sh` e `bash tests/prova_de_poucos.sh` (o cabo que sai e volta) verdes.
- `scripts/compilar.sh linux` e `scripts/compilar.sh windows`.

## Para o André (local)

Com quatro DualSense no cabo: entrar um por um no lobby e ver que a tela não tranca; no meio de uma sala, tirar e pôr
um cabo e ver que a música não engasga e que o som do controle volta.

## Ao terminar

Pôr a linha da WO04 no [quadro](README.md) como **feito**, com o commit e a medida do passo 1 (com ou sem o fio).
