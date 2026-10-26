# V09 — O código sem comentário

**Sprint:** V · **Tamanho:** G · **Depende de:** —

## Por quê

Cada linha lida custa token. O comentário repete o código ou envelhece longe dele; o porquê que vale guardar mora num
documento. A regra é o [ADR-010](../../adr/010-o-codigo-nao-tem-comentario.md).

## Ler antes

- [ADR-010](../../adr/010-o-codigo-nao-tem-comentario.md)
- [scripts/portoes/LEIA-ME.md](../../../scripts/portoes/LEIA-ME.md)

## O que se mediu (26/10/2026, em `c2644c4`)

Os versionados, lidos pelo analisador de cada linguagem, fora `third_party/`:

| tipo | arquivos | comentários |
| --- | --- | --- |
| `.gd` | 107 | 3815 (2743 `##`) |
| `.h` | 32 | 443 |
| `.c` | 48 | 364 |
| `.cpp` | 6 | 61 |
| `.gdshader` | 9 | 61 |
| `.sh` | 32 | 874 |
| `.py` | 26 | 163 |
| `.js` | 1 | 32 |
| `.html` | 1 | 11 |

- 5824 comentários, 6461 linhas.
- As diretivas que ficam: 57 `#!`, 13 `# noqa` (E402 e E731), 3 `# shellcheck disable=SC2086`.
- As docstrings do Python: 121, com 586 linhas; 22 passam de 10 linhas e somam 421.
- Sete scripts de shell imprimem o próprio comentário como ajuda (`ace_step.sh`, `ci-local.sh`, `costura.sh`,
  `instalar.sh`, `portoes/rodar.sh`, `trilha_ambiente.sh`, `trilha_fila.sh`).
- 949 citações `arquivo:linha` em 128 arquivos, mais 467 linhas com `:N` solto.

## A cura

1. O portão `scripts/portoes/codigo_sem_comentario.py` lê os comentários pelo analisador de cada linguagem e só deixa a
   diretiva nua (`--diretivas`).
2. O removedor `scripts/tirar_os_comentarios.py` corta o que o portão acusa e só grava quando prova que o programa não
   mudou:
   - `.py`: o `ast.dump` igual;
   - `.sh`: o `bash -n` verde e o `declare -f` igual;
   - `.gd`: o fluxo de tokens do `tokenize` do Python igual (outro leitor, não o do portão);
   - `.c`, `.h`, `.cpp`, `.gdshader`: o `gcc -fpreprocessed -E` igual;
   - `.js`: o que o TypeScript imprime sem comentário igual; `.html`: os eventos do `html.parser` iguais.
3. A ajuda dos sete scripts passa a ser texto no código.
4. O porquê que vale guardar vai a [o-porque-dos-modulos.md](../../o-porque-dos-modulos.md) antes de sair.
5. As citações `arquivo:linha` se reapontam para a linha nova, ou para o código que o comentário explicava.
6. Os portões `código sem comentário` (catraca por arquivo: só desce) e `texto enxuto` (o mudado não tem comentário
   nem docstring longa) entram no `scripts/portoes/rodar.sh`, que o CI e o pre-commit chamam.

## Arquivos que mudam

- `scripts/portoes/codigo_sem_comentario.py`, `codigo_sem_comentario.json`, `texto_enxuto.py`, `texto_enxuto.json`
  (novos)
- `scripts/tirar_os_comentarios.py`, `scripts/hooks/pre-commit` (novos)
- `scripts/portoes/rodar.sh`, `scripts/portoes/LEIA-ME.md`, `tests/prova_dos_portoes.sh`
- todo arquivo de código com comentário
- os documentos com citação `arquivo:linha`

## Pronto quando

`python3 scripts/portoes/codigo_sem_comentario.py` diz 0 achados, ou só os arquivos que o removedor recusou, com o
motivo no «O que foi feito».

## Provas

- `bash scripts/portoes/rodar.sh` e `bash tests/prova_dos_portoes.sh` verdes.
- A mordida: um comentário devolvido a um `.gd` e o portão reprova pelo nome; tirado, passa.
- As provas do jogo, do som e da bancada verdes depois da remoção.

## O que foi feito (26/10/2026)

- O corte: 5824 comentários saíram de 258 arquivos (6321 linhas a menos no código), cada arquivo provado pelo leitor
  da sua linguagem; nenhum recusado. A catraca agora tem piso 0.
- O porquê caro de redescobrir foi para `docs/o-porque-dos-modulos.md` (279 linhas). As ajudas que vinham do
  cabeçalho viraram `uso()` nos seis scripts de shell, e o que só vivia em comentário foi para o `DESENVOLVER.md`,
  o `COMO-RODAR.md` e a `a-esteira.md`.
- 998 citações `arquivo:linha` reapontadas em 122 arquivos. Ficaram como estavam as que já apontavam fora do arquivo
  antes do corte (5) e as de `hud.gd` sem pasta nas fichas F07 e G04 (3).
- O pre-commit (`scripts/hooks/ligar.sh`) e o CI rodam o grupo `texto`; a prova dos portões tem 102 casos.
- O gancho do editor (`texto-enxuto`, nível `forja`) aponta o comentário no mesmo turno, na mesa e em `forja-voo/`;
  promovido em 26/10/2026, mordida ao vivo feita.
- As provas: compilar linux e testes, `make all`, as ferramentas, o jogo, poucos, a bancada, o som, os portões e a
  esteira, todas verdes, nos mesmos tempos de antes.
