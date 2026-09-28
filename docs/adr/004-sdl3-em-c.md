# ADR-004: SDL3 em C, um binário Linux e um .exe pelo Proton

**Status:** substituído em parte pelo [ADR-007](007-o-jogo-e-o-3d-em-godot.md) · **Data:** 2026-09-27

## Contexto

Quase todo jogo que chega ao Hefesto é Windows rodando pelo Proton. Um jogo
Linux nativo prova só metade do caminho. O Godot da Forja tem um só dispositivo
de áudio por processo — o alto-falante de cada controle, separado, não cabe
nele (por isso o `forja-speak` existe).

## Decisão

- A Tech Demo é **C11 sobre SDL3**, a mesma biblioteca que os jogos e a Steam
  usam para controle. Versão fixada: **3.4.14**, a série que o runtime da
  Steam distribui e que o Hefesto usa como régua.
- O build (`scripts/compilar.sh`) gera um **binário Linux** e um **.exe
  Windows** (mingw-w64), os dois com o SDL3 estático, a partir do tarball
  conferido por sha256. O CI gera os dois.
- O .exe acha o som do controle como os ports de PC: WASAPI e o `ContainerId`
  do mesmo aparelho do HID. O binário Linux, pelo PipeWire.
- Arte, som e fontes nascem no código ou vão embutidos: o .exe é um arquivo só.

## Consequências

- O Godot continua no repositório como o jogo antigo da Forja
  (`./run-local.sh godot`); a Tech Demo é o `./run-local.sh`.
- Nenhuma dependência de sistema no binário além da libc: o SDL carrega X11,
  Wayland, PipeWire e ALSA em tempo de execução.
