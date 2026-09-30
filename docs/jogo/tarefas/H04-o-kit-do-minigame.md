# H04 — O kit do minigame

**Sprint:** H · **Tamanho:** G · **Modelo:** Opus · **Estimativa:** US$ 4,5

## Por quê

As salas repetem de 80 a 150 linhas cada; com um kit, cada minigame novo é uma ficha de dados mais o que é só dele — é o que cabe os 45 no orçamento.

## Ler antes

- [Os 45 minigames](../03-os-45-minigames.md)
- [Como trabalhar — o kit](../12-como-trabalhar.md#o-kit-do-minigame)

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd`
- um `godot/scripts/salas/kit_minigame.gd` novo (ou dentro de `sala_jogo.gd`)
- `godot/scripts/salas/{caminhos,canto,impacto,prova,voz}.gd` (o `_conectado` repetido)
- as salas que redeclaram `RAIAS` e montam a raia

## Passos

1. Subir para `SalaJogo`: `_conectado`, `RAIAS`, `Z_JOGADOR`, a montagem da raia (laje, borda, luz da vez, posição do jogador), as guardas de `dica` e `status`.
2. Uma ficha de dados por minigame (`godot/minigames/Sxx_Jyy.tres` ou dicionário): título, verbo, gênero, ícone, modo de câmera, faixa, duração, modo de fim, entradas usadas, eventos hápticos.
3. Ganchos que o minigame implementa: `montar`, `nota(l, n)`, `toque(l, julgamento)`, `falha(l)`, `vencedor()`.
4. O kit cuida do resto: relógio, julgamento, item, falas, fechamento, registro.
5. Reescrever uma sala atual no kit como prova (a Centelha, a mais curta).
6. Conferir e completar o [molde de minigame](molde-de-minigame.md) com o que o kit ficou sendo.

## Pronto quando

A Centelha reescrita no kit joga igual, com menos da metade das linhas, e um minigame de exemplo novo sai com menos de 200 linhas.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
