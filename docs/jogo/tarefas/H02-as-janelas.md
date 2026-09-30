# H02 — As janelas de julgamento

**Sprint:** H · **Tamanho:** M · **Estimativa:** US$ 3,0

## Por quê

Sem janelas, não há perfeito, ótimo, bom e erro; é o coração do jogo de ritmo.

## Ler antes

- [As janelas](../04-ritmo-e-audio.md#as-janelas)
- [Princípio 8](../02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom)

## Arquivos que mudam

- `godot/scripts/ritmo.gd` (`julgar`)
- `godot/scripts/salas/sala_jogo.gd`

## Passos

1. `Ritmo.julgar(lugar, t_toque, t_nota)` com perfeito −40/+60, ótimo ±90, bom ±140, e o desvio de calibração do lugar.
2. A ajuda escondida: +40 ms na janela bom dos perigos para o último colocado; a partitura mais simples depois de três erros seguidos.
3. Cada julgamento vai para o registro (`toque`).
4. Testes de unidade para as bordas das janelas.

## Pronto quando

Os testes das bordas passam, e o registro de uma rodada de robôs mostra os quatro julgamentos.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** —
