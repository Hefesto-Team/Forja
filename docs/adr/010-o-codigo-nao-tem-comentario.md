# ADR-010: o código não tem comentário

**Status:** aceito · **Data:** 2026-10-26 · **Ficha:** [V09](../jogo/tarefas/V09-o-codigo-sem-comentario.md)

## Contexto

A Forja é lida por IA, e cada linha lida custa token. Em 26/10/2026 o código versionado tinha 5824 comentários
(6461 linhas), 3815 deles em GDScript. O Hefesto já tem a mesma regra (a D-2610-O-CODIGO-NAO-TEM-COMENTARIO).

## Decisão

- Nenhum comentário em `.py`, `.sh`, `.gd`, `.c`, `.h`, `.cpp`, `.gdshader`, `.js`, `.html`, nem em arquivo sem
  extensão que abre com `#!`. O `##` do GDScript também sai (escolha dela, 26/10/2026).
- Fica só a diretiva que uma ferramenta lê, na forma nua: `#!`, `coding`, `noqa`, `type: ignore`, `pragma: no cover`,
  `shellcheck`, `eslint-disable`, `@ts-`, `SPDX-`. A lista é a do portão (`--diretivas`).
- A docstring do Python fica, porque não é comentário, mas curta: a catraca da docstring de mais de 10 linhas só desce.
- O porquê que vale guardar vai a [docs/o-porque-dos-modulos.md](../o-porque-dos-modulos.md). Na dúvida, não vai: o
  git guarda a história.
- Fora: `third_party/`, e os arquivos de configuração e de build (`.yml`, `.cfg`, `CMakeLists.txt`, `Makefile`).

## Consequências

- O portão `scripts/portoes/codigo_sem_comentario.py` reprova o comentário novo, no pre-commit e no CI, pelo
  `scripts/portoes/rodar.sh`.
- O ramo antigo que volta com comentário passa pelo `scripts/tirar_os_comentarios.py --aplicar` antes da costura.
- O bloco de código das fichas de minigame (I a Q) ainda tem comentário: quem o grava com o `ficha_codigo.py` roda o
  removedor depois.
