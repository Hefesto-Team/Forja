# WS07 — A reserva pronta antes do jogo

**Sprint:** W · **Tamanho:** P · **Depende de:** H05

## Por quê

Sem a faixa gerada, o minigame toca a trilha sintetizada da seção, e ela é feita na hora em que o jogo começa: no
quadro do apito, o fio principal para uns 80 ms sintetizando a trilha. São 4 a 5 quadros perdidos exatamente no
instante em que o relógio de ritmo parte, uma vez por seção. O relógio parte do áudio, então a nota não sai do tempo,
mas a tela engasga na largada, que é o momento mais olhado da partida, e a contagem de quadros da F09 conta esse
engasgo como desempenho do minigame.

A causa: a síntese mora no `_stream`, que só roda quando alguém pede para tocar, e o primeiro pedido da trilha da seção
é o `tocar_do_zero` do `comecar`. Na fase de aviso, a sala toca a faixa do salão (o id da sala do minigame não está em
`FAIXAS` nem em `TELAS`), então nada prepara a da seção antes.

## Ler antes

- [H05 — O pipeline das faixas](H05-o-pipeline-das-faixas.md) (o `tocar_do_zero` e o `mapa`).
- `godot/scripts/salas/sala_jogo.gd:3` (as três fases: aviso, jogo, fim).

## O estado de hoje

- `godot/scripts/musica.gd:52-70`, o `_stream`: sem cache, chama `Forja.ctl.sintetizar_pcm16("trilha", …)` no fio de
  quem pediu e guarda em `_streams`.
- Quem pede pela primeira vez: `godot/scripts/minigames/minigame.gd:89-92` (`comecar` → `Ritmo.tocar`) →
  `godot/scripts/ritmo.gd:75` (`Musica.tocar_do_zero(slot)`) → `musica.gd:104-110` → `_stream(id)`.
- Na fase de aviso: `godot/scripts/main.gd:210` (`Musica.tocar(sala_id)`), e `musica.gd:75-79` troca o id
  desconhecido pelo `"salao"`.
- Medido fora da árvore (`sint_trilha` compilado com `-O2`, máquina carregada): 75 a 89 ms para 16 a 21 s de trilha, o
  tamanho das nove seções.
- `nativo/som/sintese.c:10-13`: o ruído usa um estado global (`static uint32_t g_lcg`), semeado a cada síntese
  (`:68`).

## O alvo

`Musica.preparar(slot)` faz o `_stream` (ou o `_ogg`) do slot sem tocar, e o minigame chama na entrada da sala
(`minigame.gd:65`, o `entrar`), quando a cena já está trocando. O `tocar_do_zero` acha a trilha no cache. A fase de
aviso dura no mínimo 0,9 s (`sala_jogo.gd:291`), então mesmo uma síntese num fio de trabalho estaria pronta antes do
apito; esta ficha fica no fio principal, na troca de cena, que é o que basta.

## Passos

1. `func preparar(slot: String) -> void` na `musica.gd`, que só aquece o cache.
2. A chamada no `entrar` do `minigame.gd`, com o `ficha.faixa`.
3. Um contador de sínteses na `Musica` (só leitura, para a prova).
4. A prova nova.

## Armadilhas

- Fio de trabalho, se um dia for preciso: o `g_lcg` de `sintese.c` é global, e uma trilha sintetizada fora do fio
  principal enquanto ele sintetiza outro som muda o ruído das duas (a mesma semente deixa de dar a mesma trilha). Antes
  do fio, o estado do ruído vira argumento.
- O `_streams` guarda até o `null` (a faixa silenciosa): o `preparar` de uma seção sem reserva não pode sintetizar de
  novo a cada sala.
- A faixa gerada (`_ogg`) também carrega do disco na primeira vez: o `preparar` aquece as duas.

## Não fazer

- Não sintetizar as nove trilhas na abertura do jogo (uns 0,7 s a mais na largada e uns 18 MB parados).
- Não mexer no `Ritmo` nem no `tocar_do_zero` além de ler o cache.

## Pronto quando

Com o módulo, numa sala de minigame de seção ainda não tocada: o contador de sínteses não muda entre o começo da fase
`jogo` e o primeiro quadro dela (hoje sobe 1, no `comecar`).

## Provas

- `bash tests/prova_do_jogo.sh`, com o caso acima.
- A coleta de quadros da F09: o primeiro segundo da fase `jogo` sem o quadro longo do apito.

## Para o André (local)

Começar dois minigames de seções diferentes e olhar a largada: o apito sem engasgo na tela.

## Ao terminar

Pôr a linha no [quadro](README.md) como **feito**, com o gasto.
