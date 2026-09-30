# F06 — O registro v2

**Sprint:** F · **Tamanho:** G · **Estimativa:** US$ 3,5

## Por quê

A noite de seis horas só vira inteligência se cada saída tiver número de sequência e tempo de verdade.

## Ler antes

- [O registro v2](../08-a-noite-de-6-horas.md#o-registro-v2)
- [ADR 003](../../adr/003-o-gauntlet.md)

## Arquivos que mudam

- `nativo/nucleo/linha_tempo.c`, `nativo/nucleo/relogio.h`, `nativo/nucleo/forja.c`
- `nativo/nucleo/pads.c` (cada saída)
- `nativo/som/som_controle.c` (cada som)
- `godot/scripts/forja.gd` (os tipos do lado do jogo)
- `docs/adr/003-o-gauntlet.md` (o formato)

## Passos

1. O carimbo `t` passa a ser o relógio monotônico do sistema; o comentário de `relogio.h` passa a dizer a verdade.
2. Toda linha ganha `lugar`; a de conexão ganha `transporte` e `firmware`.
3. Toda `saida` ganha `seq` por controle e o `ok` do SDL.
4. Tipos novos: `som_controle`, `minigame`, `sessao` ampliado (as escalas). `nota`, `toque` e `calibracao` ficam reservados para a Sprint H.
5. O campo `formato` sobe de versão, e o gauntlet e a bancada leem as duas versões.

## Pronto quando

Uma sessão com `--simular=4 --robo` gera uma linha do tempo v2 em que toda saída tem `seq` crescente por controle e o tempo bate com o relógio de parede.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh` e `scripts/compilar.sh testes`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` e `bash tests/prova_da_bancada.sh`
