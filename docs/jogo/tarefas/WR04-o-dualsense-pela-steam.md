# WR04 — O DualSense pela Steam

**Sprint:** W · **Tamanho:** M · **Depende de:** — (a configuração da loja é da dona; o código não depende dela)

## Por quê

Quem compra pela Steam abre o jogo com o Steam Input ligado, que é o padrão da loja para controle PlayStation. Aí
a Steam esconde o DualSense de verdade do SDL e entrega um espelho genérico: some gatilho, luz, luzinhas,
alto-falante e háptica, e o registro não diz por quê. No Windows é pior: o SDL devolve o VID e o PID do controle real
para o espelho, e o módulo o chama de «DualSense nativo». A ETAPAS deixa isto como lacuna 2 («ficha no Bloco 6»), e
a pesquisa como «em aberto» (`docs/jogo/pesquisa/dualsense.md:516`), sem mecanismo nem cura.

## Ler antes

- `CONTRATO.md` (a Steam converte, a Forja não empacota) e `docs/VALIDAR.md:68-89` (o Steam Input desligado à mão)
- `nativo/nucleo/origem.c` (os rótulos de origem; o espelho já existe como `ORIGEM_ESPELHO_STEAM`)

## O estado de hoje

- No SDL 3.4.14 (libsdl-org/SDL, zlib, `.cache/src/SDL3-3.4.14`): a Steam lança o jogo com
  `SteamVirtualGamepadInfo` (lido em `src/joystick/SDL_steam_virtual_gamepad.c:136`),
  `SDL_GAMECONTROLLER_IGNORE_DEVICES` (o controle físico fica de fora) e
  `SDL_GAMECONTROLLER_ALLOW_STEAM_VIRTUAL_GAMEPAD` (o espelho entra, `src/joystick/SDL_gamepad.c:3289-3303`).
  `SDL_GetJoystickVendor` e `SDL_GetJoystickProduct` devolvem os do controle real para o espelho
  (`src/joystick/SDL_joystick.c:3579-3600`). O SDL dá o sinal certo: `SDL_GetGamepadSteamHandle`
  (`include/SDL3/SDL_gamepad.h:1017`) é diferente de zero no espelho.
- O módulo lê o VID e o PID pelo SDL (`nativo/nucleo/pads.c:289-290`). No Linux o sysfs mostra o `28de:11ff` do
  espelho e a origem sai certa (`origem.c:202-206`). No Windows, sem sysfs, `classificar_windows`
  (`origem.c:113-133`) só olha o VID e o PID:
  ```c
  if (f->vid == VID_SONY && f->pid == PID_DUALSENSE)
    o->tipo = ORIGEM_DUALSENSE_NATIVO;
  ```
- Em todo sistema o espelho não tem luz, e `cap_efeitos = ps5 && (p->cap_rgb || p->simulado)` sai falso
  (`pads.c:329`): «efeitos não», sem causa.
- `grep -rn 'SteamHandle\|IGNORE_DEVICES\|SteamVirtualGamepadInfo' nativo` dá zero.

## O alvo

1. A loja não liga o Steam Input no DualSense para este jogo (a configuração do cadastro: suporte nativo ao controle
   PlayStation). É o que faz o «a Steam converte, a Forja não empacota» valer para quem compra.
2. Quando o espelho chega mesmo assim (o jogador forçou, ou adicionou o jogo à mão), o relatório diz a origem certa
   em todo sistema e a causa: «o Steam Input tomou o controle». Nada muda na tela: o rótulo «espelho do Steam» já
   existe no cartão.

## Passos

1. `OrigemFatos` ganha `steam_handle`; `pads.c`, na conexão, o preenche com `SDL_GetGamepadSteamHandle(gp)`.
2. Em `origem.c`, antes do VID e do PID, nos dois classificadores: `steam_handle != 0` vira `ORIGEM_ESPELHO_STEAM`,
   com a evidência «handle do Steam Input».
3. Na abertura da sessão (`forja.c`), se `SDL_GAMECONTROLLER_IGNORE_DEVICES` traz `0x054c/0x0ce6` ou
   `0x054c/0x0df2`, o registro e o relatório escrevem que o Steam Input tomou o DualSense.
4. O passo da loja vai para a lista da dona (ETAPAS, Bloco 7, a loja), com o nome exato da opção do cadastro;
   anotar aqui quando ela marcar.

## Armadilhas

- **Sob o Proton**, o SDL não distingue o espelho por VID (`SDL_gamepad.c:3293-3299`); o handle é o sinal que serve.
- **O espelho segue sendo controle**: ele joga com botões e analógicos. Não recusar, só dizer.
- **O detector de espelho** (`pads.c:593-606`) continua: o handle só melhora o rótulo.

## Não fazer

- Não apagar os IDs da Sony da `SDL_GAMECONTROLLER_IGNORE_DEVICES` para abrir o físico por baixo da Steam: com o
  Steam Input ligado, a Steam continua escrevendo luz e vibração no mesmo controle, e isso não foi medido. Fica
  anotado para a bancada, não para esta ficha.
- Não implementar o caminho do Steam Input pela API da loja: é outra frente (lacuna 2 da ETAPAS).
- Não mudar texto de tela.

## Pronto quando

- No Windows, o espelho com o VID e o PID da Sony sai «espelho do Steam», com a evidência do handle.
- O registro diz quando o Steam Input tomou o DualSense.
- A opção do cadastro está na lista da loja.

## Provas

- **Nativa** (`nativo/testes/prova_origem.c`): `origem_classificar` com Windows, `054c:0ce6` e `steam_handle = 1`
  espera `ORIGEM_ESPELHO_STEAM`. Hoje o campo não existe e sai DualSense nativo: reprova.
- **Nativa**: a abertura com `SDL_GAMECONTROLLER_IGNORE_DEVICES=0x054c/0x0ce6` no ambiente escreve a linha do
  Steam Input no registro.

## Para o André (local)

O `.exe` adicionado à Steam com o Steam Input no padrão: o relatório diz «espelho do Steam» e a causa. Com o Steam
Input desligado no jogo: «DualSense nativo» e «efeitos sim».

## Ao terminar

Marcar WR04 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`feat(nativo): o espelho do Steam Input se reconhece em todo sistema e diz a causa`.
