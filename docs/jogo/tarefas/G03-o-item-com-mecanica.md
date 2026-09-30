# G03 — O item com mecânica

**Sprint:** G · **Tamanho:** M · **Estimativa:** US$ 3,0

## Por quê

O item do lobby hoje não faz nada; cada item passa a ser um poder pequeno que se vê e se sente.

## Ler antes

- [O item tem mecânica](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica)

## Arquivos que mudam

- `godot/scripts/player.gd` (`ITENS`)
- `godot/scripts/salas/sala_jogo.gd` (os ganchos do item no julgamento e no erro)
- `godot/scripts/ui/hud.gd` (o item no cartão)

## Passos

1. Os seis itens (Martelo, Escudo, Fole, Lanterna, Diapasão, Âncora) com o efeito e a troca de 06b.
2. Cada efeito é um gancho de `SalaJogo` (no acerto, no erro, na pista, no empurrão), para valer nos 45 sem código por sala.
3. O item aparece no cartão do HUD com a carga; o Escudo firma o gatilho enquanto inteiro.
4. O registro anota o item de cada lugar e cada vez que o item agiu.

## Pronto quando

Em cada sala atual, os seis itens agem e o registro mostra quando; nenhum item vence sozinho numa rodada de robôs com a mesma semente.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
