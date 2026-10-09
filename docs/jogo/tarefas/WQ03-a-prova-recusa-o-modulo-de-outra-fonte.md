# WQ03 — A prova recusa o módulo de outra fonte

**Sprint:** W · **Tamanho:** P · **Depende de:** [WE01](WE01-a-caixa-unica.md) (o `tests/caixa.sh`, por onde toda
prova passa)

## Por quê

As provas carregam o módulo que estiver em `godot/bin/`, sem conferir de que fonte ele saiu. Quem mexe no `nativo/` e
esquece de compilar prova o módulo velho, e a prova sai verde ou vermelha pelo código de ontem. Na árvore de
auditoria de 09/10, o `.so` é de 02/10 («862e198-dirty»), com 10 commits em `nativo/` depois dele: uma prova rodada
ali mede um módulo que não é o do código lido, e nada no registro diz isso. Com três pessoas e a esteira rodando
provas em árvores diferentes, é um verde falso esperando acontecer.

## Ler antes

- [WE01 — A caixa única das provas](WE01-a-caixa-unica.md)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `scripts/gauntlet.sh:22`, a única conferência:
  ```bash
  [[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]] || { echo "sem o módulo: scripts/compilar.sh linux" >&2; exit 2; }
  ```
  `tests/prova_do_jogo.sh` e `tests/prova_de_poucos.sh` não conferem nem isso.
- A versão gravada no módulo, `nativo/CMakeLists.txt:34-44`: `git describe --always --dirty`, que diz o commit e
  se havia mudança em qualquer lugar da árvore, não de que fonte do `nativo/` o `.so` saiu.
- `scripts/compilar.sh:137-139` compila e não deixa nada ao lado do `.so`.
- `ls -la godot/bin/` na auditoria: `libforja.linux.x86_64.so` de `out 2 23:21`; o último commit em `nativo/` é de
  09/10 (`2ce88e5`).

## O alvo

O `compilar.sh` grava, ao lado de cada módulo, a soma da fonte de que ele saiu. A caixa confere a soma antes de abrir
o Godot e, se divergir da fonte atual, sai com 2 e diz o que rodar. Nada muda no jogo.

## Arquivos que mudam

- `scripts/compilar.sh` (a soma e o arquivo ao lado do módulo)
- `tests/caixa.sh` (da WE01): a conferência
- `.github/workflows/forja.yml` (o arquivo da soma vai junto no artefato do módulo)
- `tests/prova_dos_portoes.sh` (a mordida)

## Passos

1. Uma função só, no `scripts/compilar.sh` (e chamada pela caixa): a soma do conteúdo dos arquivos versionados de
   `nativo/`, `src/`, `include/` e `cmake/`, mais o próprio `scripts/compilar.sh` (que fixa o SDL e o godot-cpp),
   lidos da árvore de trabalho (`git ls-files -z … | xargs -0 sha256sum | sha256sum`).
2. Depois de compilar o alvo `linux` ou `windows`, gravar `godot/bin/<módulo>.fonte` com a soma.
3. Na caixa, antes de abrir o Godot: sem o `.fonte`, ou com soma diferente, sai 2 com «o módulo é de outra fonte:
   scripts/compilar.sh linux».
4. No CI, o `.fonte` sobe no mesmo artefato do módulo.
5. A mordida: numa árvore de mentira, mudar um comentário de um `.c` faz a caixa sair 2; compilar (ou regravar a
   soma) volta a deixar passar.

## Armadilhas

- **O módulo do Windows** tem a sua própria soma; a prova da exportação confere a do alvo que ela exporta.
- **O `godot/bin/` pode não ser versionado**: o `.fonte` segue a mesma regra do `.so` (o `.gitignore` decide igual
  para os dois).
- **A exportação** não pode levar o `.fonte` para dentro do pacote: conferir o filtro do `export_presets.cfg`.
- **Uma soma por arquivos versionados** ignora arquivo novo ainda sem `git add`: somar também os não ignorados
  (`--others --exclude-standard`).

## Não fazer

- Não compilar sozinho dentro da prova: a prova diz o que falta, e quem roda decide.
- Não liberar por variável de escape.

## Pronto quando

Com um comentário novo num `.c` do `nativo/`, `bash tests/prova_de_poucos.sh` sai com 2 e a mensagem (hoje roda com o
módulo velho e sai verde); depois do `scripts/compilar.sh linux`, roda.

## Provas

- `bash tests/prova_dos_portoes.sh` (a mordida).
- `scripts/compilar.sh linux` e `bash tests/prova_de_poucos.sh`, pelo semáforo da máquina.

## Para o André (local)

Mexer num comentário do `nativo/`, rodar uma prova e ler a mensagem; compilar e rodar de novo.

## Ao terminar

Pôr a linha da WQ03 no [quadro](README.md) como **feito**, com o commit, e citar o `.fonte` no
`docs/DESENVOLVER.md` (onde se ensina a compilar).
