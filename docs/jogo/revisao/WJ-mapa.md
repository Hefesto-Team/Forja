# WJ — O mapa das salas, do kit e das telas

Para quem chega à área. Os caminhos são de `godot/scripts/`, na integração de 09/10/2026.

## As peças

- **`salas/sala.gd` (`Sala`)**: entrar, sair, montar, o status de cada lugar e as luzes. O sinal `terminou` volta
  ao `main`.
- **`salas/sala_jogo.gd` (`SalaJogo`)**: as três fases (`aviso`, `jogo`, `fim`); o treino e o «Valendo!»
  (`marcar` não soma no treino); `vencedor()` (a ordem pelos pontos, o lugar menor no empate); `terminar()`, dono
  dos eventos `minigame` e `desempenho`; `_celebrar()` e o quadro do fim. Quem está sem controle não segura a sala
  (`_process`, `:242-247`).
- **`minigames/minigame.gd` (`Minigame`, H04)**: a FICHA, as raias, `conectado()`, `presentes()`, `na_raia()`,
  `julgar_toque`, `nota_perdida`, e o `robo(l, dt)` chamado só para quem está em jogo e com controle. A guarda de
  quem caiu no meio é de cada minigame (o [molde](../tarefas/molde-de-minigame.md), «Um controle que cai no meio»).
- **`minigames/s01/martelo_de_hefesto.gd` (S01_J01)**: a Centelha antiga posta no kit como estava; a
  [I1](../tarefas/I1-o-martelo-de-hefesto.md) reescreve o arquivo inteiro.
- **`minigames/catalogo.gd` (`Catalogo`)**: as `SECOES`, os `MINIGAMES` e as `SALAS_ANTIGAS` (viga, molde, impacto,
  galeria, canto, caminhos, voz, prova, bancada), que as seções I a Q substituem.

## Quem chama quem

- `main.gd` cria a sala por `Catalogo.criar` em `_entrar_na_sala`; no fim, `_quadro_sala` abre a `TelaResultado`
  (`ui/resultado.gd`) com `colocacao` e `pontos`.
- O HUD (`ui/hud.gd`) lê `sala.status(l)`; `ui/painel_sala.gd` desenha o aviso, as dicas presas à raia, as perguntas,
  o tempo, o treino e o «Valendo!».
- Todo texto passa por `ui/desenho.gd` e `ui/glifo.gd`: a tradução (`Traducoes.traduzir`), a escala do texto grande
  (`Tema.t`) e a anotação que a prova visual mede. `Desenho.bateria` e `Desenho.cabecalho` são as exceções de hoje
  (desenham direto), e os chamadores delas saem com a G02 e a G04.
- As peças 3D: `mundo/kit.gd`, `mundo/efeitos.gd`, `mundo/salao.gd`.
- Quem venceu é decidido em quatro lugares: `SalaJogo.vencedor()`/`terminar()`, `TelaResultado._frase()`,
  `Partida.colocacoes` e `Som.jingle_do_resultado` (a [WJ01](../tarefas/WJ01-quem-venceu-no-empate.md) junta).

## As provas da área

- `godot/testes/prova_de_poucos.gd`: de 1 a 3 controles; `CABO=1` tira o cabo do P2 por 3 s.
- `godot/testes/prova_do_jogo.gd`: o percurso, o kit, o registro e as provas puras.
- `godot/testes/prova_visual.gd` e `checagens_visuais.gd`: letra, margem, contraste, colisão, tela parada, relógio,
  fim sem vencedor.
- `godot/testes/minigame_de_prova.gd`: o minigame de mentira do kit (a nota por tempo, o cabo que cai).

## As fichas da área

- Já no quadro: F09b (letra, margem, contraste, texto encavalado, o jogador sozinho que perde o cabo), V03 (texto
  sem tradução), V08 (os portões, o emoji), G04, G11, G12 e G14 (HUD, interface, aviso, fonte), G07 (o fim filmado),
  H08 (os ganchos do fim), I1 (o Martelo novo), Q1 (o vencedor por equipe), X06 e X07 (os pacotes).
- Novas: [WJ01](../tarefas/WJ01-quem-venceu-no-empate.md) (o empate no registro e na festa) e
  [WJ02](../tarefas/WJ02-os-simbolos-fora-da-fonte.md) (os símbolos que a fonte não tem).
