# WE06 — A linha do tempo de parede volta a ter prova

**Sprint:** W · **Tamanho:** P · **Depende de:** [WE02](WE02-o-kit-no-relogio-do-quadro.md) (o `--acelerado` nas
rodadas da prova do jogo e do gauntlet)

Nasceu da WE02: o que ela deixou sem prova.

## Por quê

A WE02 pôs `--acelerado` nas duas rodadas de `tests/prova_do_jogo.sh` e no `rodar` do `scripts/gauntlet.sh`, porque
as duas jogam o kit e o registro delas confere os julgamentos dele. Com isso, nenhuma prova roda mais a linha do tempo
no relógio de parede, que é a do jogo de verdade. A conferência «o t é o relógio de parede» de
`_prova_do_registro_v2` passou a comparar com o tempo do jogo.

A medida trouxe um segundo achado. Na sessão acelerada, o `t` da linha é o `t` do módulo
(`nativo/nucleo/forja.h:24`), um `float` somado a cada quadro em `forja_quadro` (`nativo/nucleo/forja.c:213`). Depois
de 1465 s de jogo, ele já estava 0,5 s à frente do `_agora` do `Forja`, que é um `double`. Por isso a rodada limpa do
gauntlet reprovou com «o t é o relógio de parede (1465.5 s na linha, 1465.0 s de processo)». A WE02 deu à conferência
0,5% de folga na sessão acelerada.

## Ler antes

- [WE02 — A prova do kit no relógio do quadro](WE02-o-kit-no-relogio-do-quadro.md) («O que foi feito»)
- `godot/testes/prova_do_jogo.gd`, `_prova_do_registro_v2` (o «t nunca anda para trás» e o «t é o relógio de parede»)
- `nativo/godot/forja_controles.cpp`, `ForjaControles::acelerar`

## O alvo

1. Uma rodada curta, sem `--acelerado`, confere a linha do tempo no relógio de parede: o `t` nunca anda para trás e
   não passa do relógio do processo. Essa rodada não joga o kit.
2. O `t` do módulo não deriva do tempo do jogo: um `double`, ou a soma dos quadros contada em inteiros.

## Pronto quando

A linha do tempo de parede tem uma conferência que reprova quando o `t` dela passa do relógio do processo. Na sessão
acelerada, a folga de 0,5% sai da conferência.

## Provas

- A rodada nova reprova com o `relogio_do_jogo` ligado à força, e passa sem ele.
- `bash tests/prova_do_jogo.sh` e `scripts/gauntlet.sh` verdes, pela caixa e pelo semáforo da máquina.

## Para o André (local)

Nada além das provas.

## Ao terminar

Pôr a linha da WE06 no [quadro](README.md) como **feito**, com o commit.
