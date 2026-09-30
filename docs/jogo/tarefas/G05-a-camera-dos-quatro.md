# G05 — A câmera dos quatro

**Sprint:** G · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5

## Por quê

A câmera é uma pose fixa por sala; nos minigames que se movem, ela precisa enquadrar quem está vivo.

## Ler antes

- [A câmera](../06-telas-e-fluxo.md#a-câmera)

## Arquivos que mudam

- `godot/scripts/main.gd:924-973` (enquadrar, tremor)
- `godot/scripts/salas/sala.gd` (`camera_pos`, `camera_olhar`, e um modo novo)

## Passos

1. Três modos por minigame: fixa (arena, com empurrão leve para a ação), grupo (a caixa dos vivos com margem de 15%) e corrida (o líder, com o último sempre na tela).
2. Distância mínima e máxima por minigame; movimento amortecido.
3. O tremor vem do evento e respeita a opção de conforto.

## Pronto quando

Com quatro robôs espalhados, nenhum cavaleiro sai da tela nos modos grupo e corrida.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** jogar uma sala com os quatro correndo para os cantos
