# R — O Relâmpago

**Sprint:** R · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5

## Por quê

Um modo de microjogos de 5 a 8 segundos, para aquecer e desempatar.

## Ler antes

- [O Relâmpago](../03-os-45-minigames.md#o-relâmpago)

## Arquivos que mudam

- um `godot/scripts/relampago.gd` novo
- as fichas de dados dos 45 (o recorte de cada microjogo)
- `godot/scripts/mundo/salao.gd` (a entrada)

## Passos

1. Cada minigame declara, na ficha de dados, um recorte de microjogo (verbo de uma palavra, 5 a 8 s).
2. Sequência que acelera a cada cinco, na faixa `MUS_RELAMPAGO`.
3. Uma vida por jogador; quem erra perde uma; o último vence.
4. Entra como aquecimento e como desempate do placar.

## Pronto quando

Três minutos de Relâmpago passam por microjogos das nove seções sem tela de carregamento.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** jogar três rodadas
