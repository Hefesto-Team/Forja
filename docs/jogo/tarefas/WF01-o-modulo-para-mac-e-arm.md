# WF01 — O módulo também para macOS e para ARM

**Sprint:** W · **Tamanho:** G · **Depende de:** [WU01](WU01-o-modulo-no-piso-do-godot.md) e
[WU02](WU02-o-windows-provado-num-windows.md) (os jobs do CI que esta ficha copia), [WE01](WE01-a-caixa-unica.md) (a
caixa no CI); e da **palavra dela** sobre o macOS entrar no pacote (assinar para o macOS custa uma conta paga de desenvolvedor)

## Por quê

O módulo só sai para Linux e Windows em x86_64. Num Mac, ou num Linux ou Windows em ARM, o motor não acha a
biblioteca, o autoload `Forja` fica sem o nativo, e o jogo vira um jogador no teclado. A [WU07](WU07-os-controles-sem-o-modulo.md)
dá a esses PCs os controles pelo motor (botões, analógicos, vibração e luz), mas sem o módulo não há gatilho com
peso, háptica por áudio, alto-falante, microfone, touchpad nem giro do jeito que as salas usam: a Viga, o Molde, o
Canto e a Voz ficam pela metade. O código do módulo já foi escrito para isso: a leitura crua passa pelo SDL
(`SDL_hid_*`, que existe no macOS), a coleta da origem só liga no Linux (`#if defined(__linux__)`), e há um achador de
som para «outra plataforma». O que falta é compilar, exportar e provar.

## Ler antes

- [WU07 — Os controles sem o módulo](WU07-os-controles-sem-o-modulo.md) (o caminho de quem fica sem módulo)
- [WF — a matriz das features](../revisao/WF-matriz.md) (a linha «macOS, Linux ARM, Windows ARM»)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `godot/forja.gdextension:9-10`:
  ```
  linux.x86_64 = "res://bin/libforja.linux.x86_64.so"
  windows.x86_64 = "res://bin/libforja.windows.x86_64.dll"
  ```
- `godot/export_presets.cfg`: dois presets, «Linux» (`:10`) e «Windows» (`:41`).
- `scripts/compilar.sh:148-163`: os alvos `linux`, `windows`, `testes`, `tudo` e `deps`; o Windows por
  `cmake/mingw64-x86_64.cmake`.
- `nativo/CMakeLists.txt:110-112` compila `som_controle_linux.c`, `som_controle_outro.c` e
  `som_controle_windows.c` sempre; o `outro` só tem corpo fora do Linux e do Windows
  (`#if !defined(__linux__) && !defined(_WIN32)`): devolve «só pelo nome nesta plataforma».
- `nativo/nucleo/pads.c:248-250`: a leitura crua por `SDL_hid_open_path` (portável).
- `.github/workflows/forja.yml`: todos os jobs em `ubuntu-24.04` (`:24`, `:97`, `:121`, `:160`, `:260`).
- `COMO-RODAR.md:82`: «O macOS não tem módulo nem exportação.»

## O alvo

O módulo sai para `linux.x86_64`, `linux.arm64`, `windows.x86_64`, `windows.arm64` e `macos` (universal, arm64 e
x86_64), cada um com o seu preset de exportação e um job no CI que exporta e joga as nove salas com quatro controles
simulados. No macOS e no ARM, o DualSense fala pelo SDL como no Linux; o som do controle se acha pelo nome. Nenhuma
tela muda. A prova da bancada e as ferramentas de hidraw seguem só no Linux.

## Arquivos que mudam

- `godot/forja.gdextension`, `godot/export_presets.cfg`
- `scripts/compilar.sh` (os alvos novos), `cmake/` (os arquivos de alvo cruzado que faltarem)
- `nativo/CMakeLists.txt` (o que o macOS pede para ligar: os frameworks do SDL estático)
- `.github/workflows/forja.yml` (os jobs)
- `tests/prova_da_exportacao.sh` (o alvo vira argumento)
- `COMO-RODAR.md` (a linha 82 e a seção «Windows e macOS»)

## Passos

1. `scripts/compilar.sh linux-arm64` e `windows-arm64`, por compilação cruzada como o Windows de hoje (o SDL e o
   godot-cpp na mesma versão fixa).
2. `scripts/compilar.sh macos`, num macOS (o job do CI), com `CMAKE_OSX_ARCHITECTURES="arm64;x86_64"`; a biblioteca
   vai como `libforja.macos.framework` ou `.dylib`, do jeito que o motor 4.7 pede no `.gdextension`.
3. As linhas no `.gdextension` e os presets de exportação (o macOS com assinatura ad hoc por padrão).
4. Um job por alvo no CI: compilar, exportar e rodar a `prova_da_exportacao` com `--simular=4 --robo` no runner da
   própria arquitetura (ARM em runner ARM, macOS em runner macOS).
5. Uma checagem no CI: para cada preset de exportação há uma biblioteca no `.gdextension`, e vice-versa.
6. O `COMO-RODAR.md` diz o que cada plataforma tem e o que só o Linux tem (a bancada).

## Armadilhas

- **A assinatura no macOS.** Sem assinatura e notarização, o sistema bloqueia a biblioteca na primeira abertura. A
  assinatura ad hoc deixa rodar com um clique direito em «Abrir»; a notarização é decisão dela (conta paga).
- **A permissão de entrada no macOS.** O sistema pode pedir permissão para ler o controle. Medir no primeiro Mac e
  escrever no `COMO-RODAR.md` o que a pessoa vê.
- **O som pelo nome** ([WU06](WU06-o-som-pelo-nome-nunca-vai-para-outro.md)): com quatro controles iguais, o nome
  não basta. No macOS, vale o que a WU06 decidir.
- **A caixa no CI** (WE01) só libera com a variável `CI`; no runner do macOS não há `bwrap`, e está certo.
- **O tamanho do pacote**: o universal do macOS dobra a biblioteca; conferir com a régua do pacote, se houver.

## Não fazer

- Não portar a bancada, o hidraw nem as ferramentas de medida.
- Não mudar a escolha de som do Linux e do Windows.
- Não prometer o macOS no README antes de o job do CI ficar verde e de ela decidir sobre a assinatura.

## Pronto quando

O CI tem um job verde por alvo, cada um exportando e jogando as nove salas com quatro simulados, e a checagem do
passo 5 passa. Hoje, nenhum desses alvos existe.

## Provas

- `scripts/compilar.sh linux-arm64` e `windows-arm64` nesta máquina (só compilar; não rodar).
- Os jobs novos do CI e `bash tests/prova_da_exportacao.sh <alvo>` em cada runner.

## Para o André (local)

Se alguém da casa tiver um Mac: abrir o pacote, ligar um DualSense no cabo e jogar a Centelha e a Viga; anotar o que
o sistema pediu (permissão, assinatura) e se o alto-falante do controle tocou.

## Ao terminar

Pôr a linha da WF01 no [quadro](README.md) como **feito**, com o commit, e atualizar a linha da matriz das features.
