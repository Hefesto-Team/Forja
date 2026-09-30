# H01 — O relógio de áudio

**Sprint:** H · **Tamanho:** M · **Estimativa:** US$ 3,0

## Por quê

Todo tempo do jogo é soma de `delta`, e escorrega da música; o relógio passa a ser a placa de som.

## Ler antes

- [O relógio de áudio](../04-ritmo-e-audio.md#o-relógio-de-áudio)

## Arquivos que mudam

- `godot/scripts/musica.gd`
- um nó novo `godot/scripts/ritmo.gd` (autoload)
- `godot/project.godot` (o autoload e `use_accumulated_input`)

## Passos

1. `Ritmo.t_musica()` pelo guia do Godot, com a latência em cache e sem andar para trás.
2. A faixa começa agendada, e `Ritmo.batida()` devolve a batida atual.
3. Sinais `batida` e `compasso` para o que se move no ritmo.
4. `Input.use_accumulated_input = false`.
5. Os tipos `nota` e `toque` do registro v2 com `t_musica`.

## Pronto quando

Com a faixa tocando e o jogo forçado a 20 quadros por segundo, a batida calculada não se afasta da música mais que 5 ms em três minutos.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** ouvir e ver um metrônomo de teste a 20 e a 60 quadros
