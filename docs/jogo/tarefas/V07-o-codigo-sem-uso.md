# V07 — O código sem uso

**Sprint:** V · **Tamanho:** P · **Depende de:** F05, F10

## Por quê

Quatro funções do jogo não têm quem chame (duas só a prova chama): quem lê acha que o caminho existe, e uma delas
(`devolver_a_saida`) é a metade que falta de uma troca de saída de som que, se ligada, nunca volta.

## Ler antes

- [godot/scripts/alto_falante_do_controle.gd](../../../godot/scripts/alto_falante_do_controle.gd)
- [F05 — O háptico forte](F05-o-haptico-forte.md) e [F10 — O rumble seco](F10-o-rumble-seco.md) (as que podem
  passar a usar o alto-falante)

## O estado de hoje

- `godot/scripts/forja.gd:376` `quem_apertou(botao)`: nenhuma chamada em `godot/`.
- `godot/scripts/alto_falante_do_controle.gd:121` `devolver_a_saida()`: nenhuma chamada.
- `godot/scripts/alto_falante_do_controle.gd:111` `tomar_a_saida()` e `:126` `linha_da_hud()`: só
  `godot/testes/prova_do_jogo.gd:512` e `:524` chamam. A `linha_da_hud` devolve frase com minúscula
  («procurando o alto-falante do controle…», «alto-falante: %s»), fora da tabela de traduções.
- `godot/scripts/player.gd:127` `descricao_do_visual()` também não tem chamada, mas a
  [G02](G02-a-construcao-do-cavaleiro.md) a usa: fica.

## Arquivos que mudam

- `godot/scripts/forja.gd` (só a função)
- `godot/scripts/alto_falante_do_controle.gd`
- `godot/testes/prova_do_jogo.gd` (as linhas da `_prova_o_alto_falante_do_sistema` que chamam as duas)

## Passos

1. Depois da F05 e da F10, `git grep -n 'quem_apertou\|tomar_a_saida\|devolver_a_saida\|linha_da_hud' godot`.
2. A que só tem a própria definição (e a prova) sai, com as linhas da prova que a conferem.
3. A que ganhou chamada fica, e a ficha diz qual e onde no «O que foi feito».

## Pronto quando

O `git grep` do passo 1 acha só as funções que têm chamada fora da prova.

## Provas

- `bash tests/prova_do_jogo.sh`
- `bash tests/prova_de_poucos.sh`
