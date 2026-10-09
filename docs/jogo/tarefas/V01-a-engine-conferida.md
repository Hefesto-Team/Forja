# V01 — A engine conferida, num passo só

**Sprint:** V · **Tamanho:** P · **Depende de:** —

## Por quê

O Godot entra no CI e na máquina sem soma conferida, e o mesmo download está escrito à mão em três jobs: um zip
trocado no caminho vira o jogo de todo mundo, e subir de versão exige mexer em quatro lugares.

## Ler antes

- [scripts/engine.sh](../../../scripts/engine.sh) (a versão num lugar só, e o `forja_baixar_engine`)
- [scripts/compilar.sh](../../../scripts/compilar.sh) (o SDL já entra por versão e sha256: é o molde)
- [.github/workflows/forja.yml](../../../.github/workflows/forja.yml)

## O estado de hoje

- `scripts/engine.sh:21` baixa `Godot_v${FORJA_GODOT_VER}_linux.x86_64.zip` com `curl -fsSL` e descompacta sem
  conferir nada. O SDL, em `scripts/compilar.sh:50-57`, confere `sha256sum` contra `SDL_SHA256` e para se não bate.
- `.github/workflows/forja.yml` repete o bloco «A versão do Godot é a do engine.sh» + «O Godot em cache» + «Baixar
  o Godot» três vezes (`:60-78` no job `linux`, `:177-195` no `exportar`, `:273-291` no `telas`), cada um com o
  próprio `curl` e o próprio `unzip`, sem soma.
- As ações vêm por etiqueta móvel (`actions/checkout@v4`, `actions/cache@v4`, `actions/upload-artifact@v4`,
  `actions/download-artifact@v4`, `actions/cache/restore@v4`, `actions/cache/save@v4`): quem move a etiqueta muda o
  CI sem commit nosso.

## Arquivos que mudam

- `scripts/engine.sh` (a soma ao lado da versão)
- `scripts/baixar_engine.sh` (sem mudança de interface; só passa a falhar quando a soma não bate)
- `.github/workflows/forja.yml` (os três blocos viram um passo que chama `bash scripts/baixar_engine.sh`; as ações
  por sha do commit, com a etiqueta num comentário ao lado). É de todos: as fichas que mexem no CI esperam esta.

## Passos

1. Pegar o `SHA512-SUMS.txt` da página da versão 4.7.2-stable do Godot e copiar a soma do
   `Godot_v4.7.2-stable_linux.x86_64.zip` para `FORJA_GODOT_SHA512` em `scripts/engine.sh`, logo abaixo de
   `FORJA_GODOT_VER`. Quem troca a versão por variável de ambiente troca a soma junto (`FORJA_GODOT_SHA512`).
2. Em `forja_baixar_engine`, depois do `curl`: `sha512sum` do zip; se não bate, apaga, diz as duas somas e devolve 1.
3. No CI, cada job troca o «Baixar o Godot» por `bash scripts/baixar_engine.sh` (o cache de `tools/` fica). O passo
   «A versão do Godot é a do engine.sh» fica, porque a chave do cache usa `GODOT_VERSAO`.
4. Trocar cada `uses: x@v4` pelo sha do commit da etiqueta, com `# v4.x.y` no fim da linha.
5. Rodar o CI local dos jobs rápidos.

## Pronto quando

Um zip com um byte trocado faz `bash scripts/baixar_engine.sh` sair com 1 e não deixar binário em `tools/`, e
`grep -c 'godotengine/godot/releases' .github/workflows/forja.yml` dá 0 (o download do GE-Proton, no `exportar`,
fica como está).

## Provas

- `FORJA_GODOT_SHA512=0000 GODOT=/nao/existe bash scripts/baixar_engine.sh; echo $?` sai 1 sem binário novo.
- `bash scripts/baixar_engine.sh` com a soma certa baixa e mostra `4.7.2.stable`.
- `bash scripts/ci-local.sh --rapido` verde.

## O que foi feito (leva 1, a-varredura)

- Medido antes: um zip com um byte trocado, servido por `file://` a uma cópia dos scripts, fazia o `unzip` sair 1
  com «bad CRC», mas o binário corrompido ficava executável em `tools/`; a segunda chamada via o `-x`, saía 0 e
  ainda mostrava `4.7.2.stable.official`.
- `scripts/engine.sh`: `FORJA_GODOT_SHA512` logo abaixo da versão (a soma do `SHA512-SUMS.txt` da 4.7.2-stable,
  conferida contra o zip baixado), e `forja_baixar_engine` confere o `sha512sum` antes do `unzip`: se não bate,
  apaga a pasta temporária, diz as duas somas e devolve 1, sem tocar em `tools/`.
- O CI: os três «Baixar o Godot» viraram «O Godot (baixado pelo scripts/baixar_engine.sh…)», que roda sempre (com o
  cache, não baixa e só mostra a versão); o cache de `tools/` e o passo «A versão do Godot é a do engine.sh» ficam.
  `grep -c 'godotengine/godot/releases' .github/workflows/forja.yml` dá 0. Cada `uses:` está preso ao sha do commit
  para onde a etiqueta `v4` apontava em 09/10/2026, com a versão exata no comentário (checkout v4.4.0, cache,
  cache/restore e cache/save v4.3.0, upload-artifact v4.6.2, download-artifact v4.3.0).
- A cura cobre os outros chamadores: o `garantir_godot` do `scripts/exportar.sh` e o `run-local.sh` baixavam por
  conta própria, sem soma; os dois passam pelo `forja_baixar_engine`. O `run-local.sh` usava uma `GODOT_URL` que
  não existia mais (com `set -u`, caía na primeira vez sem engine).
- Provas: com o zip trocado, `baixar_engine.sh` sai 1 e `tools/` não existe; com o zip certo, sai 0 e mostra
  `4.7.2.stable.official.ed1daf0bf`; `FORJA_GODOT_SHA512=0000 GODOT=/nao/existe bash scripts/baixar_engine.sh` sai
  1 com `tools/` igual ao de antes. Os portões verdes. `bash scripts/ci-local.sh --rapido` verde nos três jobs; no
  `linux`, o passo novo achou o Godot no cache e mostrou `4.7.2.stable.official.ed1daf0bf`.
- Fica para a mão: nada de aparelho.
