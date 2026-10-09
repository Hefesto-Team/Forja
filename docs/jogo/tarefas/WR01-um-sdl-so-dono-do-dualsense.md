# WR01 — Um SDL só, dono do DualSense

**Sprint:** W · **Tamanho:** M · **Depende de:** — (vai antes da [WR02](WR02-o-radio-com-tudo-que-o-sdl-sabe.md),
que liga o rádio, e corrige a isenção da [WE01](WE01-a-caixa-unica.md))

## Por quê

Desde a 4.5, o Godot lê os controles com um SDL3 próprio, estático dentro do executável. A Forja traz outro SDL3
estático dentro do módulo. São dois SDL no mesmo processo, cada um com o seu driver do DualSense, abrindo o mesmo
hidraw e escrevendo no mesmo controle. O do Godot abre todo controle que aparece, com as dicas no padrão: no cabo,
manda um relatório com a barra de luz e as luzinhas na cor e no padrão **do índice dele**; no rádio, liga o modo
completo (o `0x31` com CRC) que o contrato proíbe no processo. A cor do lugar (F04) e a sombra do módulo ficam com
quem escreveu por último. O jogo não usa nada do `Input` de controle do Godot, então o segundo dono só atrapalha.

As duas referências que emulam a plataforma fazem o contrário: um SDL só no processo, dono de todos os controles.

## Ler antes

- [ADR 005 — O rádio nativo só entrada](../../adr/005-o-radio-nativo-so-entrada.md) e
  [ADR 007 — O jogo e o 3D em Godot](../../adr/007-o-jogo-e-o-3d-em-godot.md) (a frase «o Godot 4.4 não usa SDL»)
- [F04 — O P1 e o LED](F04-p1-e-o-led.md) (a cor e as luzinhas de cada lugar)
- [05 — Háptica e controle](../05-haptica-e-controle.md) (a suspeita (d), fechada como «o Godot não vibra»)

## O estado de hoje

- `docs/adr/007-o-jogo-e-o-3d-em-godot.md:42-43`: «O Godot 4.4 não usa SDL, então não há dois SDL no processo». O
  projeto é 4.7 (`godot/project.godot:17`). `strings tools/Godot_v4.7.2-stable_linux.x86_64 | grep -c
  SDL_JOYSTICK_HIDAPI_PS5` dá 2; no 4.4.1 dá 0.
- O Godot 4.7.2 (godotengine/godot, MIT, tag `4.7.2-stable`; o SDL dele é o 3.2.28, `thirdparty/README.md`):
  - `drivers/sdl/joypad_sdl.cpp:64-66` só define duas dicas e inicia o joystick:
    ```cpp
    SDL_SetHint(SDL_HINT_JOYSTICK_THREAD, "1");
    SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
    ERR_FAIL_COND_V_MSG(!SDL_Init(SDL_INIT_JOYSTICK | SDL_INIT_GAMEPAD), FAILED, SDL_GetError());
    ```
  - `:139`: `gamepad = SDL_OpenGamepad(sdl_event.jdevice.which);` para todo controle que chega.
  - `main/main.cpp:2282` carrega as extensões (`register_core_extensions()`), e `:3238` chama
    `OS::get_singleton()->initialize_joypads()`, sem condição de `--headless`, também no `--import` e no `-s`.
- No SDL (libsdl-org/SDL, zlib; o 3.2.28 do Godot e o 3.4.14 do módulo fazem igual): abrir registra o callback do
  `SDL_JOYSTICK_ENHANCED_REPORTS`, que roda na hora (`src/SDL_hints.c:365-367`); sem dica, no rádio,
  `SDL_GetStringBoolean(hint, true)` dá ON (`src/joystick/hidapi/SDL_hidapi_ps5.c:925-934` no 3.4.14); o modo
  completo escreve a cor da tabela por índice (`:328-341`: azul, vermelho, verde, rosa a `0x40`) e as luzinhas
  (`:876-887`); no rádio, embrulha em `0x31` com CRC (`:1100-1122`).
- A Forja só mexe nas dicas do SDL dela, com prioridade normal (`nativo/nucleo/forja.c:168-171`):
  ```c
  SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
  SDL_SetHint(SDL_HINT_JOYSTICK_ENHANCED_REPORTS, "0");
  SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
  SDL_SetHint(SDL_HINT_JOYSTICK_HIDAPI_PS5_PLAYER_LED, "1");
  ```
  Prioridade normal perde para a variável de ambiente de mesmo nome (`src/SDL_hints.c:111-113`).
- A entrada da biblioteca, `nativo/godot/registro_tipos.cpp:21-29` (`forja_iniciar_biblioteca`), roda quando o Godot
  carrega a extensão, em `main.cpp:2282`, antes do `initialize_joypads`. Hoje ela só registra o nó no nível SCENE.
- `grep -rn 'get_connected_joypads\|is_joy_button_pressed\|get_joy_axis\|InputEventJoypad\|start_joy_vibration'
  godot/scripts` fora dos testes dá zero: o jogo não usa o `Input` de controle do Godot.
- `docs/jogo/pesquisa/M3-metralhadora-de-feiticos.md:36` diz «o SDL do Godot nunca manda o 0x02», e
  `docs/jogo/pesquisa/M1-a-galeria.md:31` deixa «dois donos do relatório» como hipótese.

**O que não foi medido:** a corrida no aparelho (a regra proíbe abrir o Godot com o DualSense dela fora da caixa).
Fica para a bancada.

## O alvo

O SDL do Godot nunca abre o DualSense pelo driver HIDAPI (cai no evdev no Linux e no RawInput no Windows, que não
escrevem luz nem efeito); o SDL do módulo sempre abre. O contrato do módulo não depende do ambiente de quem lança.
Nada muda na tela.

## Passos

1. **Medir a ordem.** Em `forja_iniciar_biblioteca`, escrever uma linha em `stderr` («forja: biblioteca carregada»)
   e conferir, com `--verbose` na caixa, que ela sai antes de «SDL: Init OK!» do Godot. Se não sair antes, parar e
   anotar: a cura vai para o lançador (o `AppRun`, o `run-local.sh`), não para a biblioteca.
2. **O ambiente.** Na entrada da biblioteca, antes de tudo: se `SDL_JOYSTICK_HIDAPI_PS5` não estiver no ambiente,
   pô-la em `0` (`setenv` no Linux; `SetEnvironmentVariableW` no Windows, que é onde o SDL lê o ambiente lá).
3. **O módulo blindado.** Em `nativo/nucleo/forja.c`, antes do `SDL_Init`, as dicas do módulo passam a
   `SDL_SetHintWithPriority(..., SDL_HINT_OVERRIDE)`: `SDL_HINT_JOYSTICK_HIDAPI_PS5` em `"1"`, mais as quatro de hoje.
   O ambiente não desmancha mais o contrato.
4. **O registro.** Uma linha na abertura da sessão: o valor de `SDL_JOYSTICK_HIDAPI_PS5` no ambiente e a dica
   efetiva no SDL do módulo («SDL do motor sem o DualSense · SDL do jogo com o DualSense»).
5. **Os textos.** ADR-007 (a frase dos dois SDL), M3:36, M1:31 e a suspeita (d) do 05 ganham a linha certa. A
   isenção da WE01 (`--import`, `--export-*`, `-s` «não abrem o módulo») cai: o Godot abre o controle sem o módulo.

## Armadilhas

- **O nível da extensão não importa para o ambiente.** O que roda cedo é a função de entrada, chamada ao carregar a
  biblioteca; o nível mínimo SCENE pode ficar. Não trocar para CORE sem necessidade.
- **No Windows, `_putenv_s` mexe no ambiente do CRT**, que pode não ser o mesmo que o SDL do Godot lê. Usar a API do
  sistema.
- **A variável vaza para os filhos** (o `pactl` do som, o Godot de uma prova lançada pelo jogo). Não faz mal; não
  tentar limpá-la depois, que o SDL do Godot pode reler.
- **O Edge (`054c:0df2`)** usa o mesmo driver: a dica cobre os dois.
- **Sem o módulo** (glibc baixa, macOS) a variável não é posta, e o Godot fica com o controle: é o que a
  [WU07](WU07-os-controles-sem-o-modulo.md) usa.

## Não fazer

- Não desligar o SDL do Godot inteiro (`SDL_JOYSTICK_HIDAPI=0` ou parar o driver): basta tirar o DualSense dele.
- Não mexer em `pads.c` nem na cor do lugar: a F04 está certa; só perde a corrida.
- Não pôr a variável no `project.godot` nem pedir ao jogador: tem de valer em qualquer PC, sozinha.

## Pronto quando

- Num processo do jogo, só o SDL do módulo abre o DualSense pelo hidraw.
- O registro diz o estado das duas dicas.
- Os textos de ADR-007, M1, M3, 05 e WE01 dizem o que o código faz.

## Provas

- **Do jogo, na caixa** (`tests/*.sh`, bwrap, `--headless`, `--simular=1`, `--audio-driver Dummy`): exige no
  registro `SDL_JOYSTICK_HIDAPI_PS5` = `0` no ambiente e `1` no SDL do módulo, e com `SDL_JOYSTICK_ENHANCED_REPORTS=1`
  exportado o módulo ainda lê `0`. Hoje o registro não traz a linha, e a dica do módulo perde para o ambiente:
  reprova.
- **Ordem**, na mesma caixa com `--verbose`: «forja: biblioteca carregada» antes de «SDL: Init OK!».
- A mordida: tirar o passo 2 e ver a prova reprovar.

## Para o André (local)

Um DualSense no cabo entra como P3; desligar e religar o cabo dez vezes no salão. A barra fica sempre no verde do
lugar (0,255,64), nunca no verde fraco do índice do motor (0,64,0), e as luzinhas sempre no padrão do P3.

## Ao terminar

Marcar WR01 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(nativo): o SDL do motor deixa o DualSense para o SDL do jogo`.
