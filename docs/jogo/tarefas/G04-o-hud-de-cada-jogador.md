# G04 — O HUD de cada jogador

**Sprint:** G · **Tamanho:** G · **Estimativa:** US$ 3,5

## Por quê

O HUD é desenhado em pixels fixos e pode colidir; cada jogador precisa do seu canto ancorado.

## Ler antes

- [O HUD de cada jogador](../06-telas-e-fluxo.md#o-hud-de-cada-jogador)

## Arquivos que mudam

- `godot/scripts/ui/hud.gd` (51-60, 108-142)
- `godot/scripts/ui/painel_sala.gd` (151-270, a dica presa ao boneco)
- `godot/scripts/tema.gd`
- `tests/telas.sh`

## Passos

1. Um cartão por jogador, ancorado ao canto dele, com área segura de 5%.
2. O cartão mostra cor, número, nome, pontos, combo e item.
3. O julgamento do toque aparece acima do boneco, na cor dele, por meio segundo.
4. Lugar vazio: "Botão ✕ (Entrar)", translúcido.
5. As fotos das telas rodam nas escalas 1,0 e 1,15 e nas duas línguas.

## Pronto quando

As fotos de todas as salas nas duas escalas e nas duas línguas não mostram texto encostando em texto nem abaixo de 30 px.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `tests/telas.sh`
