# H06 — Os jingles

**Sprint:** H · **Tamanho:** P · **Modelo:** Sonnet · **Estimativa:** US$ 1,5

## Por quê

Todo fim precisa de som de fim; hoje não há jingle.

## Ler antes

- [As telas e os jingles](../04-ritmo-e-audio.md#as-telas-e-os-jingles)

## Arquivos que mudam

- `godot/scripts/som.gd`
- `godot/assets/sons/` (os jingles Kenney CC0 de hoje, *Music Jingles*)
- `godot/scripts/salas/sala_jogo.gd` (o fechamento)

## Passos

1. Os oito jingles nos seus momentos, com parada seca.
2. Enquanto os jingles próprios não chegam, usar os *Music Jingles* da Kenney que já estão no repositório.
3. A contagem de entrada no tempo da faixa.

## Pronto quando

Toda sala toca apito, o jingle do resultado e a contagem de entrada.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** ouvir uma partida de três
