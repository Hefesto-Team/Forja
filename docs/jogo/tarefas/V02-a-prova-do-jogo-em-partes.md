# V02 — A prova do jogo em partes

**Sprint:** V · **Tamanho:** G · **Depende de:** F08, F09

## Por quê

Setenta e seis fichas do quadro editam o mesmo `godot/testes/prova_do_jogo.gd`: quatro conjuntos em voo ao mesmo
tempo brigam por ele na costura, e a esteira não consegue dizer que dois conjuntos têm arquivos disjuntos.

## Ler antes

- [13 — Como uma ficha prova o que fez](../13-arquitetura.md#como-uma-ficha-prova-o-que-fez)
- [F08 — A paridade](F08-a-paridade.md) e [F09 — A prova visual](F09-a-prova-visual.md) (o que elas deixam na prova)

## O estado de hoje

- `godot/testes/prova_do_jogo.gd` tem 989 linhas e 27 funções numa classe só: `_prova_do_percurso` (`:83-308`)
  passa por todas as salas, `_joga_a_sala`/`_comeca_a_sala`/`_termina_a_sala` (`:309-408`) jogam uma sala, e as
  provas de sistema vêm depois (`_prova_do_relogio` `:631`, `_prova_da_calibracao` `:673`, `_prova_das_janelas`
  `:777`, `_prova_das_frases` `:958`, `_prova_das_maiusculas` `:981`…).
- `grep -l prova_do_jogo.gd docs/jogo/tarefas/*.md | wc -l` dá 76: cada minigame novo acrescenta a checagem dele
  ali dentro.

## O alvo

```
godot/testes/prova_do_jogo.gd           o corredor: sobe o jogo, chama cada checagem, soma as falhas
godot/testes/checagens/<slot>.gd        uma por minigame: extends ForjaChecagem, func checar(prova) -> void
godot/testes/checagens/sistema_<x>.gd   uma por sistema: relogio, calibracao, janelas, frases, maiusculas...
godot/testes/checagem.gd                class_name ForjaChecagem: esperar(cond, msg), quadros(n), aperta(sim, botao)
```

O corredor acha as checagens por `DirAccess` em `res://testes/checagens/` (ordem alfabética), sem lista escrita:
minigame novo = arquivo novo, sem tocar no corredor.

## Arquivos que mudam

- `godot/testes/prova_do_jogo.gd` (vira o corredor; de todos, por isso esta ficha vai sozinha)
- `godot/testes/checagem.gd` (novo), `godot/testes/checagens/*.gd` (novos, um `.uid` para cada)
- `docs/jogo/13-arquitetura.md` (a linha das provas diz onde mora a checagem de um minigame)
- `docs/jogo/tarefas/molde-de-minigame.md` (a parte das provas aponta para `checagens/<slot>.gd`)

## Passos

1. Escrever `checagem.gd` com os três ajudantes que hoje são `_esperar`, `_quadros`, `_aperta` (`:30-49`).
2. Mover cada `_prova_*` de sistema para `checagens/sistema_<nome>.gd`, sem mudar o que confere.
3. Mover o trecho de cada sala de `_prova_do_percurso` para `checagens/<slot>.gd`.
4. O corredor conta as checagens e diz `prova do jogo: N checagens, M falhas`.
5. Trocar, no molde de minigame e no 13, «edite a prova do jogo» por «crie `checagens/<slot>.gd`».

## Pronto quando

A saída de `bash tests/prova_do_jogo.sh` traz as mesmas linhas `ok`/`FAIL` de antes (em outra ordem, no máximo) e
`prova_do_jogo.gd` tem menos de 150 linhas.

## Provas

- Antes de mexer: `bash tests/prova_do_jogo.sh > /tmp/antes.log 2>&1` (o `FAIL` sai no stderr); depois, o mesmo para `/tmp/depois.log`; as linhas `ok` e
  `FAIL` ordenadas são iguais (`diff <(grep -E '^(ok|FAIL)' /tmp/antes.log | sort) <(grep -E '^(ok|FAIL)' /tmp/depois.log | sort)`).
- Uma checagem que falha de propósito (`esperar(false, "x")`) faz a prova sair com 1.
