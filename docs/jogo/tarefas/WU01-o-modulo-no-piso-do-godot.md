# WU01 — O módulo Linux no piso do Godot

**Sprint:** W · **Tamanho:** M · **Depende de:** — (mexe no job Linux do CI; não voar junto com a
[WE03](WE03-o-gauntlet-no-ci.md) nem a [V01](V01-a-engine-conferida.md) sem combinar o arquivo)

## Por quê

O módulo Linux pede glibc 2.38; o Godot pede 2.28. Em Ubuntu 22.04 e Mint 21 (2.35), Debian 12 (2.36) e no ambiente
de execução Linux da loja (2.31), o Godot abre e a biblioteca não carrega. Aí o jogo segue «só o teclado, e nenhuma
saída chega a controle», com um aviso que o jogador não vê: a festa de quatro vira um jogador no teclado. É o defeito
mais largo do «qualquer PC»: não depende de controle, de rádio nem de regra, só da idade do sistema.

## Ler antes

- `scripts/compilar.sh` (o alvo `linux`) e o job `linux` de `.github/workflows/forja.yml`
- O passo do CI que já confere a DLL do Windows («A DLL só depende do que o Windows (e o Proton) já têm»,
  `.github/workflows/forja.yml:141`): o portão daqui é o irmão dele

## O estado de hoje

- `objdump -T godot/bin/libforja.linux.x86_64.so | grep -oE 'GLIBC_[0-9.]+' | sort -V | uniq -c`: 14 símbolos em
  `GLIBC_2.38` (`__isoc23_strtol`, `__isoc23_strtoul`, `__isoc23_strtoll`, `__isoc23_strtoull`, `__isoc23_sscanf`,
  `__isoc23_vsscanf`, `__isoc23_fscanf`, `__isoc23_wcstol`, `strlcpy`, `strlcat`, `wcslcpy`, `wcslcat`, `fmod`,
  `fmodf`), 1 em 2.36 (`arc4random`), 2 em 2.35, 32 em 2.34.
- O mesmo no `tools/Godot_v4.7.2-stable_linux.x86_64`: no máximo `GLIBC_2.28`.
- O artefato sai do job `linux` em `runs-on: ubuntu-24.04` (`.github/workflows/forja.yml:24`, glibc 2.39), com
  `scripts/compilar.sh linux` (`:55`), e a exportação baixa esse artefato (`:171`).
- A queda, `godot/scripts/forja.gd:124` e `:141-142`:
  ```gdscript
  if ClassDB.class_exists("ForjaControles") and not _args.has("sem-modulo"):
  ...
  if not modulo:
  	push_warning("FORJA sem o módulo nativo: só o teclado, e nenhuma saída chega a controle")
  ```
- `grep -rni glibc scripts .github docs` dá zero: nada fixa nem confere o piso.

A causa: os cabeçalhos da glibc nova desviam `strtol` e `sscanf` para `__isoc23_*` (C23) e oferecem `strlcpy` e
`arc4random`, que o configure do SDL adota; a libm nova dá o `fmod@2.38`. O piso do módulo vira o da máquina que
compila.

## O alvo

A biblioteca Linux que vai na exportação carrega em qualquer sistema em que o Godot 4.7.2 abre (glibc 2.28), e o CI
reprova se ela subir de piso. O `compilar.sh linux` de quem desenvolve segue igual. Nenhuma linha de jogo muda.

## Passos

1. Escolher o piso: 2.28 (o do Godot; uma imagem `manylinux_2_28`) ou 2.31 (o SDK do ambiente da loja). Anotar a
   escolha aqui.
2. O job `linux` do CI compila o SDL, o godot-cpp e o módulo dentro de um contêiner com esse piso (`container:` no
   job). O SDL reconfigurado lá usa as próprias versões de `strlcpy` e `arc4random`.
3. O portão: um passo depois do `compilar.sh linux` que reprova se o maior `GLIBC_` passar do piso. O mesmo portão
   entra no `tests/prova_da_exportacao.sh`, sobre a `.so` exportada.
4. O `compilar.sh linux` local ganha só um aviso, no fim, com o piso medido («este módulo pede glibc X; o pacote
   pede Y»).

## Armadilhas

- **As provas do job rodam no mesmo contêiner?** As provas que abrem o Godot pedem `bwrap`, `xvfb-run` e as
  bibliotecas de janela: ou o contêiner as tem, ou o job compila no contêiner e prova fora, com o artefato.
- **O cache do SDL** (`deps-linux-…`, `:49`) é por `hashFiles('scripts/compilar.sh')`: a chave precisa do piso,
  senão um cache feito na 24.04 volta.
- **O C++ estático** (`libstdc++`) também puxa símbolos novos: conferir o objdump depois, não supor.
- **O `fmod`** vem da libm; em base antiga ele sai em versão velha sozinho.

## Não fazer

- Não reescrever código para fugir dos símbolos (trocar `sscanf`, `strlcpy`): a base antiga resolve na origem.
- Não mexer no caminho sem módulo nem no aviso: a tela fica como está (a [WU07](WU07-os-controles-sem-o-modulo.md)
  trata do jogo sem módulo).

## Pronto quando

- `objdump -T` na `.so` do artefato dá no máximo o piso escolhido.
- O CI reprova uma `.so` acima do piso.

## Provas

- **Portão no CI e na prova da exportação:** `objdump -T godot/bin/libforja.linux.x86_64.so | grep -oE
  'GLIBC_[0-9.]+' | sort -Vu | tail -1` menor ou igual ao piso. Hoje imprime `GLIBC_2.38`: reprova.
- **De quebra:** a prova da exportação, com `--simular=4`, rodada dentro de um contêiner `debian:12` mostra o módulo
  carregado no registro («FORJA … · SDL 3.4.14»). Hoje cai no teclado.

## Para o André (local)

Num Ubuntu 22.04 ou Debian 12 (máquina ou pendrive vivo), o pacote do CI: o título reconhece o DualSense no cabo e o
relatório traz a linha do módulo.

## Ao terminar

Marcar WU01 como **feito** no [quadro](README.md), com o piso escolhido, o commit e o gasto. Commit sugerido:
`build(ci): o módulo Linux sai no piso de glibc do Godot, com portão`.
