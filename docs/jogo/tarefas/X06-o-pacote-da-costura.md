# X06 — O pacote da costura das telas

**Sprint:** X · **Tamanho:** G · **Depende de:** X01, as fichas G que mexem no `main.gd` (G01 a G12) feitas

## Por quê

O `main.gd` decide quem está na tela, a cortina e as camadas, e também tudo o mais do Forja: 25 fichas o editam, e o mecanismo de telas não serve a nenhum outro jogo.

## Ler antes

- [15 — A costura das telas](../15-os-modulos.md#6-a-costura-das-telas--forja_costura)
- [06 — Telas e fluxo](../06-telas-e-fluxo.md)

## O estado de hoje

- `godot/scripts/main.gd` (989 linhas): `estado` (`:29`), `overlay` (`:58`), as treze telas (`:44-57`), `_mostrar`
  (`:215`), `_trocar` com a cortina (`:246`), os `_ir_para_*` (`:264-527`) e a vez de cada tela em `_process` (`:542`).

## Arquivos que mudam

- `godot/addons/forja_costura/` (novo): `costura.gd` (autoload `ForjaCostura`), o resto do pacote
- `godot/scripts/main.gd` (de todos: esta ficha vai sozinha)
- as telas em `godot/scripts/ui/` ganham `entrar(dados)`, `sair()`, `quadro(dt)`

## Passos

1. Escrever `ForjaCostura` com o estado, a cortina e a pilha de camadas, copiando o comportamento de `_trocar` e `_mostrar`.
2. Cada tela registra-se no `_ready` do `main`; o `estado` e o `overlay` do `main` viram `ForjaCostura.atual()` e `.camada()`.
3. Os `_ir_para_*` viram `ForjaCostura.ir(...)` com as regras do Forja ficando no `main`.
4. A prova do pacote: três telas de mentira, a ida e a volta com cortina, a camada por cima e o foco devolvido.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_costura` passa, `main.gd` tem menos de 600 linhas e o percurso da prova do jogo passa igual.

## Provas

- `bash tests/prova_do_importavel.sh forja_costura`
- `bash tests/prova_do_jogo.sh`
- `bash tests/prova_visual.sh` (todas as telas; as pranchas olhadas)
