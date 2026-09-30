# G06 — O salão e a coleção

**Sprint:** G · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5

## Por quê

O salão precisa contar a história da noite: as seções vencidas e o que o grupo conquistou.

## Ler antes

- [A coleção](../06b-a-construcao-do-cavaleiro.md#a-coleção)
- [As telas](../06-telas-e-fluxo.md#as-telas)

## Arquivos que mudam

- `godot/scripts/mundo/salao.gd` (os portões, 16-23)
- `godot/scripts/opcoes.gd` (guardar a coleção)

## Passos

1. Cada portão mostra o nome da seção e acende quando os cinco minigames dela foram vencidos na noite.
2. A vitrine mostra os troféus da noite; acabamentos e peças novas se desbloqueiam jogando (primeira vitória, coop sem erro, recorde).
3. O que se desbloqueia aparece na construção do cavaleiro.

## Pronto quando

Depois de uma partida de nove, o salão mostra pelo menos um troféu e um portão aceso, e a construção oferece o que foi desbloqueado.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** jogar uma partida e voltar ao salão
