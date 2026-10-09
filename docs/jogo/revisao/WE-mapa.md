# A esteira, as provas e a entrega: o mapa

Para quem chega nesta área. Medido na integração de 09/10/2026.

## O CI (`.github/workflows/forja.yml`)

| job | o que roda | depende de |
| --- | --- | --- |
| `linux` | a prova sem rastro, as provas da lógica do nativo, o `make all` (o selftest, o do som e o `tests/prova_do_som.sh`), o Godot, a prova do jogo, a de poucos e a da bancada | — |
| `portoes` | `scripts/portoes/rodar.sh`, a prova dos portões e a da esteira (só python3 e git) | — |
| `windows` | o módulo pelo mingw e a conferência das DLLs | — |
| `exportar` | os três pacotes e a prova da exportação, pelo Wine do GE-Proton | `linux`, `windows` |
| `telas` | fotografa e compara; só relata | `linux` |
| `release` | publica os pacotes, só em tag | `exportar` |

O `rotulos.yml` cuida dos rótulos e do quadro. Fora do CI: o `scripts/gauntlet.sh` (a [WE03](../tarefas/WE03-o-gauntlet-no-ci.md))
e o `tests/prova_visual.sh`.

## A casa de cada dev

- `scripts/engine.sh` é a versão do Godot e o download dele (`forja_baixar_engine`); `baixar_engine.sh`,
  `instalar.sh` e `preparar_sessao.sh` o usam. O `run-local.sh` e o `exportar.sh` ainda baixam cada um do seu jeito
  (a [WE05](../tarefas/WE05-o-godot-baixado-num-lugar-so.md); a soma é da [V01](../tarefas/V01-a-engine-conferida.md)).
- `scripts/compilar.sh` baixa o SDL por sha256 e o godot-cpp por commit. `scripts/exportar.sh` baixa os modelos e o
  `appimagetool` por sha256.
- `run.sh` é o menu; `scripts/instalar.sh` confere, instala e desinstala.

## A esteira de quem coordena

- `scripts/esteira.py` lê o quadro e o ESPERA-ELA e devolve um JSON.
- `scripts/costura.sh` faz o cherry-pick de um ramo de conjunto, roda os portões e as provas rápidas e, com
  `--pesadas`, o `scripts/ci-local.sh --rapido` pelo semáforo da máquina.
- `scripts/ci-local.sh` roda o próprio YAML num contêiner, sobre a árvore do índice. Ainda mora na casa do Hefesto
  (a [WE04](../tarefas/WE04-o-ci-local-com-casa-propria.md)).

## As provas que abrem o Godot

`tests/prova_do_jogo.sh`, `prova_de_poucos.sh`, `prova_da_bancada.sh`, `prova_da_exportacao.sh`, `prova_visual.sh`,
`telas.sh`, `scripts/gauntlet.sh` e `scripts/trailer.sh`. Cada uma monta o próprio isolamento, e quase todas o deixam
opcional (a [WE01](../tarefas/WE01-a-caixa-unica.md)). A regra: nenhuma delas pode enxergar o DualSense ligado na máquina.

- A régua do jogo mora em `godot/testes/prova_do_jogo.gd` (a [V02](../tarefas/V02-a-prova-do-jogo-em-partes.md) a divide).
- O robô e os 20 defeitos de mentira moram em `nativo/nucleo/simulador.c`.
- O relógio do ritmo corre no tempo de parede, e a prova do kit sente a máquina carregada
  (a [WE02](../tarefas/WE02-o-kit-no-relogio-do-quadro.md)).

## Os portões

Reprovam: o texto de tela, o sem rastro, as mensagens de commit, a ficha pronta e o teste mudo (o Godot pela tela de
mentira só com `--audio-driver Dummy`). A arte e o som ficam em aviso até a [V08](../tarefas/V08-os-portoes-de-arte-e-som-reprovam.md).
A WE01 acrescenta o portão da caixa.

## As fichas desta área

| ficha | título | tamanho | depende de |
| --- | --- | --- | --- |
| [WE01](../tarefas/WE01-a-caixa-unica.md) | A caixa única das provas | M | — |
| [WE02](../tarefas/WE02-o-kit-no-relogio-do-quadro.md) | A prova do kit no relógio do quadro | M | — (antes da V02 e da X03) |
| [WE03](../tarefas/WE03-o-gauntlet-no-ci.md) | O gauntlet no CI | M | WE01, V01 |
| [WE04](../tarefas/WE04-o-ci-local-com-casa-propria.md) | O CI local com casa própria | M | — |
| [WE05](../tarefas/WE05-o-godot-baixado-num-lugar-so.md) | O Godot baixado num lugar só, também em casa | P | V01 |
