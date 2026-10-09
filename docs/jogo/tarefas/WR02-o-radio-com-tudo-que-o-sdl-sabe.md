# WR02 — O rádio com tudo o que o SDL sabe

**Sprint:** W · **Tamanho:** M · **Depende de:** [WR01](WR01-um-sdl-so-dono-do-dualsense.md) (um SDL só) e da
**palavra dela** para o passo 2 (a emenda do `CONTRATO.md` e do ADR-005); o passo 1 não depende de ninguém

## Por quê

Num PC qualquer, sem a ponte, quatro DualSense no rádio entram só com botões e analógicos. A dica que o módulo liga
(`SDL_JOYSTICK_ENHANCED_REPORTS = "0"`) não impede só o jogo de montar o `0x31`: impede o próprio SDL. Sem o modo
completo, o SDL não cria giro, acelerômetro, touchpad nem bateria, e recusa vibração, barra de luz, luzinhas e
gatilho. Até o plano B que o 05 e a pesquisa prometem para o rádio («no rádio, o rumble fraco a 0,3 por 40 ms»,
`docs/jogo/pesquisa/dualsense.md:431`; `godot/scripts/forja.gd:913-914`) é recusado. A Viga e o Molde perdem o
verbo, e as salas de saída ficam mudas.

E cada pedido recusado custa caro: o SDL dorme 10 ms antes de recusar, na linha do jogo. Quatro controles no rádio
acertando a mesma nota param o quadro de 40 a 80 ms.

O jogo nunca montou o `0x31`: quem monta, com o CRC, é o SDL, a partir do mesmo bloco de 47 bytes que o jogo já
monta para o cabo. A ordem nova (qualquer PC, sem a ponte) cai no caso que o ADR-005 deixou de fora.

## Ler antes

- [ADR 005](../../adr/005-o-radio-nativo-so-entrada.md) e o `CONTRATO.md:44-56` (a lista do que o código não faz)
- [05 — Háptica e controle](../05-haptica-e-controle.md) («O rádio») e `docs/jogo/pesquisa/dualsense.md` §16
- [WR01](WR01-um-sdl-so-dono-do-dualsense.md): sem ela, o SDL do motor já liga o rádio por conta própria

## O estado de hoje

- `nativo/nucleo/forja.c:169`: `SDL_SetHint(SDL_HINT_JOYSTICK_ENHANCED_REPORTS, "0");`, e
  `nativo/nucleo/pads.c:59-60` deriva dela o `contrato_estrito`.
- No SDL 3.4.14 do módulo (libsdl-org/SDL, zlib, `.cache/src/SDL3-3.4.14/src/joystick/hidapi/SDL_hidapi_ps5.c`):
  - `:894-896`: com a dica desligada, «Nothing to do, enhanced mode is a one-way ticket»: o
    `SetEnhancedModeAvailable`, que cria sensores, touchpad e bateria (`:838-871`), nunca roda;
  - `:1039-1049`: `GetJoystickCapabilities` só dá RGB, luzinhas e rumble com `enhanced_mode_available`;
  - `:1083-1093`, o portão de todo efeito:
    ```c
    if (!ctx->enhanced_mode) {
        if (application_usage) {
            HIDAPI_DriverPS5_UpdateEnhancedModeOnApplicationUsage(ctx);
            // Wait briefly before sending additional effects
            SDL_Delay(10);
        }
        if (!ctx->enhanced_mode) {
            return SDL_Unsupported();
    ```
  - `:1015-1027`: a vibração passa por ali uma ou duas vezes (`RumbleStart` e `Rumble`); `:1054-1067`, a luz, uma;
  - `:1099-1122`: quando pode, o próprio SDL põe `0x31`, a etiqueta `0x10` e o CRC32 sobre `0xA2` em volta do bloco.
- Na Forja, `pad_rumble` (`nativo/nucleo/pads.c:730-742`) e `pad_luz` (`:762-765`) chamam o SDL sem olhar a conexão;
  só os efeitos passam por `enviar`, que olha `cap_efeitos` (`:799-803`). As capacidades saem do SDL
  (`:323-341`: `cap_efeitos = ps5 && (p->cap_rgb || p->simulado)`), e o aviso «no rádio, só entrada» sai em
  `:368-371`.
- A referência boykopovar/AnyPS5 (GPL-2.0, só leitura), `core/libs/prx/libSceVideoOut/src/PadInput.cpp:27-28`, liga
  o modo completo e manda o mesmo bloco pelo SDL (`:96-104`), que embrulha para o rádio.
- Nesta máquina não dá para medir: o único hidraw da Sony visível é o virtual (barramento USB).

## O alvo

No produto, um DualSense no rádio tem giro, toque, bateria, vibração, luz, luzinhas e gatilho, pelo SDL. O código da
Forja continua sem `0x31`, sem CRC e sem MAC. Alto-falante, microfone e háptica por áudio seguem só no cabo (no rádio
não há placa de som), e a háptica cai no rumble como o 05 já prevê. Na mesa (bancada, experimento, prova de fogo),
o contrato estrito continua, para «passou no rádio» seguir querendo dizer «a ponte entregou». Nada muda na tela.

## Passos

1. **Já, dentro do contrato de hoje.** Em `pad_rumble`, `pad_luz` e `pad_leds_jogador` (`nativo/nucleo/pads.c:863`), sair cedo e devolver falso (com a
   mesma anotação de hoje) quando o pad é só de entrada: a mesma condição de `nativo/godot/forja_controles.cpp:91`
   (`contrato_estrito`, `CONEXAO_BT`, `origem_eh_dualsense`). Acaba com os 10 a 20 ms por pedido.
2. **Com a palavra dela.** O modo vira escolha da sessão: o GDScript diz ao módulo, antes do `abrir`, se é mesa
   (`--bancada`, `--experimento`, `--prova-de-fogo`) ou produto (um método novo, `estrito(bool)`, ou um argumento
   do `abrir`). `forja.c` põe a dica em `"0"` na mesa e em `"1"` no produto, com `SDL_HINT_OVERRIDE` (a WR01).
3. O `CONTRATO.md` ganha a frase: «o embrulho para o rádio é do SDL, como o `0x02` no cabo»; o ADR-005 ganha a
   emenda (estrito só na mesa). O aviso de `pads.c:368-371` já só sai com o estrito.
4. `abrir_cru` continua recusando o rádio (`pads.c:245`): o `0x31` tem outros offsets.

## Armadilhas

- **A luz no rádio chega atrasada.** O SDL só escreve a cor depois que a animação de conexão do controle termina (o
  carimbo do sensor passa de 10,2 s, `SDL_hidapi_ps5.c:706-717` e `:786-800`). Não é defeito; a conferência não pode
  tomá-lo por um.
- **A sequência do relatório** vai sempre em 0 no SDL (`:1101`), e o driver do kernel a gira de 0 a 15
  (torvalds/linux, `drivers/hid/hid-playstation.c:1261-1270`, GPL-2.0, só leitura). O firmware aceita; não «corrigir».
- **Com a ponte e um controle físico visível** (a máquina de outro dev, sem a trava da dela), o físico no rádio passa
  a entrar com tudo no produto: o detector de espelho (`pads.c:593-606`) é que separa os dois. Na mesa, estrito.
- **Sem a WR01**, o SDL do motor e o do jogo escrevem `0x31` no mesmo controle.

## Não fazer

- Não montar `0x31` nem CRC no código da Forja.
- Não ligar alto-falante, microfone ou háptica por áudio no rádio.
- Não trocar texto de tela: o cartão já mostra efeitos e giro por capacidade.

## Pronto quando

- Passo 1: um pad só de entrada não chama o SDL para vibrar, acender ou piscar.
- Passo 2: no produto, a linha «conectou» de um DualSense no rádio diz «efeitos sim · giro sim · toque sim», e a
  saída volta `ok=true` para vibração, luz e gatilho; na mesa, segue «só entrada».

## Provas

- **Nativa** (`nativo/testes`): um pad marcado como rádio estrito, com o SDL trocado por um contador; `pad_rumble` e
  `pad_luz` devolvem falso sem chamar, e cem chamadas cabem em menos de 1 ms. Hoje chamam: reprova.
- **Nativa, depois da palavra dela:** `forja_abrir` no modo produto deixa `SDL_GetHint(ENHANCED_REPORTS)` em `"1"` e
  `contrato_estrito` falso; no modo mesa, `"0"` e verdadeiro. Hoje dá `"0"` nos dois.
- `bash tests/prova_do_jogo.sh` verde, pelo semáforo.

## Para o André (local)

Um DualSense no rádio, sem a ponte, no modo de jogo: a Viga mira pelo giro, a bateria aparece no cartão, a barra
toma a cor do lugar uns 10 s depois de ligar, e um golpe no Impacto vibra. Com `--bancada`, o mesmo controle volta a
«só entrada».

## Ao terminar

Marcar WR02 como **feito** no [quadro](README.md), com a decisão dela anotada no ADR-005, o commit e o gasto.
Commits sugeridos: `fix(nativo): o pad só de entrada não espera o SDL recusar` e
`feat(nativo): no rádio, o SDL embrulha o mesmo bloco; o estrito fica na mesa`.
