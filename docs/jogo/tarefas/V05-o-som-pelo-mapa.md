# V05 — O Som pelo mapa do áudio

**Sprint:** V · **Tamanho:** M · **Depende de:** H06, H07, e o `docs/jogo/audio/mapa.csv` publicado pelo diretor de som

## Por quê

O mapa do áudio vai ser a régua de todo som, mas o `Som` tem as próprias duas tabelas escritas à mão e os ids estão
em três grafias: o mapa diz uma coisa, o código toca outra, e o portão de som não tem como casar os dois.

## Ler antes

- [O mapa do áudio](../o-time/o-mapa-do-audio.md) (as colunas e a grafia do id: minúsculas)
- [H06 — Os jingles](H06-os-jingles.md)
- [04 — Ritmo e áudio](../04-ritmo-e-audio.md)

## O estado de hoje

- `godot/scripts/som.gd:17-36` `RECEITAS` (id → receita sintetizada e parâmetros) e `:39-46` `GRAVADOS` (id →
  arquivo em `assets/sons/`), escritas à mão.
- As grafias: o mapa pede minúsculas (`vitoria_p2`, `mus_s01_j02`); a H06 escreve `JIN_APITO`, `JIN_VITORIA`
  (`H06-os-jingles.md:77-78`); a ficha de trilha usa `MUS_S01_J01` (`scripts/trilha_fichas.py`).
- As chamadas: `Som.tocar("<id>", …)` (`som.gd:109`), `Som.no_controle(lugar, "<id>", ganho)` (`som.gd:153`) e
  `Forja.som_falante(lugar, "<id>", ganho)` (`forja.gd:783`); a do Canto é por variável
  (`godot/scripts/salas/canto.gd:295-299`, `qual` é `"nota"` ou `"nota_alta"`) e uma é ternário
  (`godot/scripts/salas/viga.gd:458`).
- O portão de som (`scripts/portoes/som.py`) já confere, em modo aviso, que todo id tocado existe no mapa.

## O alvo

- Um id, uma grafia: minúsculas com `_`, como o mapa. `JIN_APITO` vira `jin_apito`; `MUS_S01_J01` vira `mus_s01_j01`
  no mapa e no código, e o nome do arquivo de faixa segue o que o `conferir_ost.py` pede.
- `RECEITAS` e `GRAVADOS` saem do código: `Som` lê, na partida, as linhas do mapa com `tipo` sintetizado (coluna
  `receita`) e gravado (coluna `arquivo`). O mapa é a fonte; o código não repete.
- Id tocado que o mapa não tem: `Som` avisa uma vez no log (`som sem mapa: <id>`) e não toca.
- A chamada dinâmica do Canto passa por uma tabela constante de ids, para o portão enxergar.

## Arquivos que mudam

- `godot/scripts/som.gd`
- `godot/scripts/salas/canto.gd`, `godot/scripts/salas/viga.gd` (só as duas chamadas)
- os ids nas chamadas de `godot/scripts/**/*.gd` que mudarem de grafia
- `scripts/portoes/som.json` (a lista de chamadas, se o nome de alguma função mudar)

## Passos

1. Conferir que cada id de `RECEITAS` e `GRAVADOS` tem linha no mapa; o que falta vai para o diretor de som, não
   se inventa linha.
2. Trocar as grafias com um script de uma vez (`git grep -l` + `sed`), não à mão.
3. `Som` carrega o mapa e monta as duas tabelas.
4. Rodar o portão de som: zero aviso de id fora do mapa.

## Pronto quando

`python3 scripts/portoes/som.py` diz `0 ids fora do mapa` e `git grep -n 'const RECEITAS\|const GRAVADOS' godot`
não acha nada.

## Provas

- `python3 scripts/portoes/som.py`
- `bash tests/prova_do_som.sh`
- `bash tests/prova_do_jogo.sh`
