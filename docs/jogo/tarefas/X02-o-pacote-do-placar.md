# X02 — O pacote do placar

**Sprint:** X · **Tamanho:** P · **Depende de:** X01, V04

## Por quê

As contas da partida já são puras; falta a tela do placar parar de chamar o controle e o som do Forja para o placar servir a outro jogo de festa.

## Ler antes

- [15 — O placar](../15-os-modulos.md#2-o-placar--forja_placar)

## O estado de hoje

- `godot/scripts/partida.gd` é pura, mas guarda `NA_ORDEM` e `NOMES` com as salas do Forja (`:22-28`).
- `godot/scripts/ui/placar.gd` chama `Forja.cor_do_lugar`, `Som.tocar` e `Tema.fonte/mono/tom_para_a_borda`.

## Arquivos que mudam

- `godot/addons/forja_placar/` (novo): `partida.gd` (`ForjaPartida`), `placar.gd` (`ForjaPlacar`), o resto do pacote
- `godot/scripts/partida.gd`, `godot/scripts/ui/placar.gd` (saem)
- `godot/scripts/main.gd` (só as linhas que criam e abrem o placar: liga `pediu_som` ao `Som.tocar` e entrega `cores` e `nomes`)
- `godot/project.godot`

## Passos

1. `git mv` dos dois arquivos para o pacote, com o prefixo no `class_name`.
2. `NA_ORDEM` e `NOMES` saem do pacote: o `main` entrega o `percurso` e o `nomes` (do `Catalogo`, pela V04).
3. O placar emite `pediu_som(id)` em vez de tocar; recebe `cores` em vez de perguntar ao `Forja`.
4. A prova do pacote: uma partida de três salas com pontos inventados dá o pódio certo, e o placar abre e fecha sem o Forja.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_placar` passa, e `git grep -n 'Forja\.\|Som\.' godot/addons/forja_placar` não acha nada.

## Provas

- `bash tests/prova_do_importavel.sh forja_placar`
- `bash tests/prova_do_jogo.sh` (a `_prova_das_contas_da_partida` e a `_prova_da_partida`)
- `bash tests/prova_visual.sh` (o placar e o pódio)
