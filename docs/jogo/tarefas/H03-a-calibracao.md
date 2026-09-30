# H03 — A calibração

**Sprint:** H · **Tamanho:** P · **Estimativa:** US$ 2,0

## Por quê

Cada controle tem sua latência (cabo, rádio, TV); o desvio de cada um entra no julgamento.

## Ler antes

- [A calibração que ninguém vê](../04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)

## Arquivos que mudam

- `godot/scripts/ui/tela_opcoes.gd` (Tempo, em passos de 10 ms)
- `godot/scripts/opcoes.gd`
- `godot/scripts/ritmo.gd`

## Passos

1. O desvio medido na construção (G02) alimenta `Ritmo.julgar`.
2. Opções do lugar › Tempo: ajuste manual em passos de 10 ms, com um metrônomo para conferir.
3. O desvio e o transporte vão para o registro.

## Pronto quando

Um controle com desvio de +80 ms medido julga como perfeito um toque 80 ms atrasado.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** medir o desvio de um controle no cabo e um no rádio
