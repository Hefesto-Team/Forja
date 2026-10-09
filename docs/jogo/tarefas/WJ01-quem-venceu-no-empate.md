# WJ01 — Quem venceu, no empate

**Sprint:** W · **Tamanho:** P · **Depende de:** H08 (os ganchos do fim: `campos_do_fim`, `quem_comemora`,
`quem_brilha`)

## Por quê

No empate em primeiro, a tela diz «Empate!» (ou «P1 e P2 empatam!»), o jingle é o do empate e a coluna da colocação
dá «1º» aos dois; o boneco do P1 pula sozinho com as faíscas e o registro grava `"vencedor": 0`. O relatório da noite
(a [S](S-a-noite-de-seis-horas.md)) conta vitória por item e por arquétipo pelo `vencedor`: todo empate vira uma
vitória do lugar menor, e o equilíbrio dos itens sai torto a favor do P1. Cada um decide sozinho o que é empate; a
cura é uma regra só, que todos leem.

## Ler antes

- [13 — o registro v2](../13-arquitetura.md) (a linha `minigame`, `:192`) e o fechamento (`:333`, `:503-508`)
- [H08 — os acréscimos do kit](H08-os-acrescimos-do-kit.md) (os ganchos do fim, `:365-401`, e o coop, `:762-772`)
- [G07 — a narrativa leve](G07-a-narrativa-leve.md) (o `vencedor_do_fim`, `:79-82`, e o `_celebrar`, `:446-455`)

## O estado de hoje

Quatro donos para a mesma pergunta, e só um deles erra:

- `godot/scripts/salas/sala_jogo.gd:400-407`, `vencedor()`: ordena pelos pontos e, no empate, põe o lugar menor
  primeiro. É a ordem da tabela, e está certa como ordem.
- `godot/scripts/salas/sala_jogo.gd:386-388`, o evento lê a primeira posição como se fosse a vitória:

  ```gdscript
  Forja.evento("minigame", 0, {"slot": id, "evento": "terminou",
  	"vencedor": colocacao[0] if not colocacao.is_empty() else -1,
  ```

- `godot/scripts/salas/sala_jogo.gd:412-418`, `_celebrar()`: só `colocacao[0]` faz `emote-yes`, com faíscas na cor
  dele.
- `godot/scripts/ui/resultado.gd:64-87`: `_empatados_no_topo()` conta quem tem os pontos do primeiro e `_frase()`
  escreve «P%d e P%d empatam!» ou «Empate!».
- `godot/scripts/ui/resultado.gd:112`: a coluna da colocação vem de `Partida.colocacoes` (`godot/scripts/partida.gd:75`,
  «1 + quantos fizeram mais: o empate divide a de cima»).
- `godot/scripts/som.gd:220-231`, `jingle_do_resultado`: conta de novo, à mão, quantos estão no topo, e toca
  `JIN_EMPATE`.
- As provas exigem o número errado: `godot/testes/prova_do_jogo.gd:670-673` (todo `terminou` com `vencedor` ≥ 0),
  `:1254`, e `godot/testes/checagens_visuais.gd:201-206` com o caso `godot/testes/prova_visual.gd:490-491`
  («o vencedor -1 (ninguém) reprova»). Uma partida de quatro com o robô ruim, todos em 0, grava o P1 como vencedor e
  passa.
- O que vem: a H08 muda o evento para `campos_do_fim()` e o `_celebrar` para `quem_comemora()`/`quem_brilha()`, os
  três ainda com `colocacao[0]`; a G07 cria um quinto dono, o `vencedor_do_fim()` (−1 no empate, para a câmera).

## O alvo

Uma regra, na `SalaJogo`, sobre a conta que já existe:

```gdscript
## Os lugares que dividem o primeiro posto (Partida.colocacoes == 1), na ordem do vencedor().
## Um só: ele venceu. Dois ou mais: empate. Vazio: ninguém jogou.
func no_topo() -> Array
```

- O `minigame` `terminou` (o `campos_do_fim()` da H08): `vencedor` é o lugar quando `no_topo()` tem um; com dois ou
  mais, `vencedor` −1 e `empatados` com a lista. O coop segue como a H08 o deixa (−1, `coop_venceu`, `destaque`).
- `quem_comemora()`: o de `no_topo()`; no empate, todos os empatados juntos. `quem_brilha()`: só com um vencedor
  (−1 no empate: as faíscas têm dono).
- `TelaResultado._frase()` e `Som.jingle_do_resultado` contam o empate pela mesma `Partida.colocacoes` (a do
  `no_topo()`), sem conta própria.
- A régua «fim sem vencedor» aceita o −1 quando a linha traz `empatados` com dois ou mais, e o 13 diz: «`vencedor`
  (o lugar 0..3; −1 no coop e no empate em cima, com `empatados`)».
- A G07, quando entrar, escreve o `vencedor_do_fim()` sobre o `no_topo()` (o empate é a mesma regra; o «ninguém
  pontuou» é dela).

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd` (`no_topo`, `campos_do_fim`, `quem_comemora`, `quem_brilha`)
- `godot/scripts/minigames/minigame.gd` (só se o `campos_do_fim` do kit, no 2 contra 2, repetir a primeira posição)
- `godot/scripts/ui/resultado.gd` (`_empatados_no_topo` sai)
- `godot/scripts/som.gd` (`jingle_do_resultado`)
- `godot/testes/prova_do_jogo.gd` (ou a `checagens/` dela, se a V02 já entrou), `godot/testes/checagens_visuais.gd`,
  `godot/testes/prova_visual.gd`
- `docs/jogo/13-arquitetura.md` (a linha `minigame`), `docs/jogo/tarefas/G07-a-narrativa-leve.md` (uma linha: o
  `vencedor_do_fim` lê o `no_topo`)

## Passos

1. `no_topo()` na `SalaJogo`, sobre `Partida.colocacoes(pontos, presentes)`, na ordem do `vencedor()`.
2. O `campos_do_fim()`, o `quem_comemora()` e o `quem_brilha()` leem o `no_topo()`.
3. `resultado.gd` e `jingle_do_resultado` trocam a conta própria pela mesma regra; as frases e o jingle não mudam.
4. As três provas aceitam o −1 com `empatados`; o caso «−1 sem `empatados` reprova» fica.
5. O 13 e a linha da G07.

## Armadilhas

- A ordem do `vencedor()` não muda: ela é a tabela do resultado, a do pódio e a do `destaque()` do coop. O que muda é
  quem a lê como «venceu».
- Um jogador só, sem pontos, ainda vence (é o único no topo): o «ninguém pontuou» é decisão da G07, não desta.
- Quem lê o registro escrito antes desta ficha acha `vencedor` ≥ 0 nos empates antigos: o leitor da noite não
  precisa de caso especial (o −1 já não conta vitória), mas a noite medida antes não se compara número a número.
- O 2 contra 2 tem a equipe vencedora (`equipe_vencedora()`, −1 no empate de equipes): o `no_topo()` é por lugar e
  não decide a equipe. Não misturar as duas regras.

## Não fazer

- Não mexer na frase da tela nem no jingle: os dois já estão certos.
- Não desempatar por sorteio ou por tempo para fugir do −1: o empate existe e a tela já o diz.
- Não escrever o `vencedor_do_fim` da G07 aqui.

## Pronto quando

Com pontos `[5, 5, 0, 0]` e quatro jogando, o `minigame` `terminou` traz `vencedor` −1 e `empatados` `[0, 1]`, o
P1 não pula sozinho e as faíscas não saem; com `[5, 3, 0, 0]`, `vencedor` 0 e sem `empatados`; e as três provas
passam aceitando o empate.

## Provas

- Na sessão, pura (uma `SalaJogo` solta, como a G07 faz): `no_topo()` com `[5, 5, 0, 0]`, `[5, 3, 0, 0]`,
  `[0, 0, 0, 0]` e um jogador só; `campos_do_fim()` e `quem_brilha()` nos mesmos casos.
- `checagens_visuais`: o −1 com `empatados` `[0, 1]` passa; o −1 sem `empatados` reprova.
- `bash tests/prova_do_jogo.sh` (os `jingle:` seguem verdes) e `PASSADAS=fixa bash tests/prova_visual.sh` (a régua
  «fim sem vencedor» com o robô ruim).

## Para o André (local)

Dois controles na mesa, ninguém aperta nada no minigame: o fim dá 0 a 0, a tela diz «P1 e P2 empatam!» e nenhum dos
dois bonecos comemora sozinho. Na linha do tempo da noite, o `terminou` desse minigame tem `vencedor` −1 e
`empatados` `[0, 1]`.

## Ao terminar

Marcar WJ01 como **feito** no [quadro](README.md), com o commit e o gasto.
