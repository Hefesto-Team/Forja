# WC04 — O argumento de abertura errado avisa e sai

**Sprint:** W · **Tamanho:** P · **Depende de:** — (mexe em `main.gd`: não vai junto com uma ficha G que esteja no
`_abrir_pelos_args`; vai antes da X06)

## Por quê

Os atalhos de abertura nasceram para a prova e para quem testa à mão, e caem num padrão em vez de recusar a entrada
errada. Um `--sala=S04_J61` com o número trocado deixa o jogo no título, com todo mundo já dentro, sem uma linha no
log; um `--partida=4` vira o percurso de nove salas. As fichas dos 45 minigames mandam provar com
`--sala=<slot>` (por exemplo `--sala=S04_J16`, na pesquisa da L1): o primeiro erro de digitação vira meia hora
procurando por que a sala não abriu. O `--robo=` já faz o certo (`godot/scripts/forja.gd:198`, o `push_warning` com
os temperamentos que valem); os outros não.

## Ler antes

- `godot/scripts/main.gd`, o `_abrir_pelos_args`
- [DESENVOLVER](../../DESENVOLVER.md) (a lista dos argumentos)
- [13 — A prova visual](../13-arquitetura.md#a-prova-visual--f09) (a tabela que cita o `--tela=`)

## O estado de hoje (medido em 09/10/2026)

- `godot/scripts/main.gd:152-196`, o `_abrir_pelos_args`:
  - `:156-157` aceita `--tela=` (lobby, salão, diagnóstico, livro). Nenhuma prova, script ou CI usa
    (`git grep -n -e '--tela=' -- tests scripts .github` não acha nada).
  - `:161-162` troca o apelido velho `giro` por `viga`. Ninguém pede `giro`.
  - `:182` só entra na sala se `Catalogo.existe(sala_pedida)`; senão segue para o `match tela`, que não casa, e o
    jogo fica no título com o `_todos_entram()` já feito (`:165-168`).
  - `:158-159` lê `--partida=N` sem conferir; `godot/scripts/partida.gd:47-50` devolve o percurso inteiro quando
    `N` não está no `NA_ORDEM`.
- `godot/scripts/main.gd:334-335`, o `_entrar_na_sala`, volta calado quando o id não está no catálogo:

  ```gdscript
  if pronta == null and not Catalogo.existe(id):
  	return
  ```

  Na Prova de Fogo, o `fogo` já subiu (`:385-387`): a sala some e a prova fica parada até o tempo dela acabar.
- `godot/scripts/main.gd:814-815`, `--tela=diagnostico` sem `--bancada`: o `_abrir_overlay` volta calado (o
  diagnóstico é da bancada).

## O alvo

Um argumento de abertura que o jogo não sabe cumprir faz `push_error` com o valor e o que vale, e o jogo sai com 2.
Valem: `--sala=` com id, slot ou apelido do catálogo; `--partida=` com 3, 5 ou 9. O `--tela=` e o apelido `giro`
saem. O `_entrar_na_sala` com id desconhecido faz `push_error` em vez de voltar calado.

## Arquivos que mudam

- `godot/scripts/main.gd` (o `_abrir_pelos_args` e o `_entrar_na_sala`)
- `tests/prova_do_jogo.sh` (as duas rodadas curtas)
- `docs/jogo/13-arquitetura.md` (a tabela da prova visual), `docs/DESENVOLVER.md`

## Passos

1. Conferir os argumentos no começo do `_abrir_pelos_args`, antes do `_todos_entram()`: a sala pelo
   `Catalogo.existe`, a partida pelo `Partida.TAMANHOS`.
2. Recusa: `push_error("--sala=%s: não há sala com esse id (ids: ...)" % ...)` e `get_tree().quit(2)`.
3. Tirar o `--tela=` (o `match` inteiro e a condição dele em `:165`) e o `giro`. O comentário de `:148-151` perde o
   `--tela=`.
4. `_entrar_na_sala` com id desconhecido: `push_error` com o id.
5. Duas rodadas curtas em `tests/prova_do_jogo.sh`: `--sala=nao-existe` e `--partida=4`, cada uma saindo com 2 e
   com o valor no log.
6. O 13 (a tabela da prova visual) e o DESENVOLVER deixam de citar o `--tela=`.

## Armadilhas

- O `--sala=` aceita três formas (o apelido da seção, o slot `S01_J01` e o id de hoje): a conferência é a do
  `Catalogo.existe`, que já resolve as três (`godot/scripts/minigames/catalogo.gd:50-52`). Não escreva outra lista.
- O `--experimento=` e o `--prova-de-fogo` não mudam aqui.
- A recusa tem de sair antes do `_todos_entram()`: senão o relatório da sessão registra quatro entradas de uma
  sessão que não aconteceu.
- `get_tree().quit(2)` dentro de um `await` sai no fim do quadro: confira que nada abre a sala antes.

## Não fazer

- Não validar no `Partida.roteiro`: a conta pura continua aceitando qualquer `n` (a prova das contas usa o
  percurso). A recusa é do argumento.
- Não mexer no `_todos_entram()`: a F09 já tirou a prova visual dele; ele segue servindo à prova do jogo.

## Pronto quando

`--simular --headless -- --sala=nao-existe` e `--partida=4` saem com 2 e o log traz o valor recusado;
`git grep -n -e '--tela=' -- godot docs/DESENVOLVER.md` não acha nada.

## Provas

- `bash tests/prova_do_jogo.sh` (as duas rodadas novas, e a prova de sempre igual).
- `bash tests/prova_de_poucos.sh`.

## Para o André (local)

Nada além de abrir uma sala por `--sala=` com o id certo e ver que ela abre como antes.

## Ao terminar

Marcar WC04 como **feito** no [quadro](README.md), com o gasto.
