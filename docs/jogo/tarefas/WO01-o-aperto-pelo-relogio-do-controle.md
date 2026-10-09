# WO01 — O aperto do DualSense pelo relógio do controle

**Sprint:** W · **Tamanho:** M · **Depende de:** [WC01](WC01-o-toque-no-instante-do-aperto.md) (o
`idade_do_aperto_us` e o `Ritmo.t_do_aperto`); para o rádio, [WR02](WR02-o-radio-com-tudo-que-o-sdl-sabe.md) (sem o
modo completo não há sensor no rádio)

## Por quê

A WC01 cura o julgamento pela idade do aperto e diz que, «no controle de verdade, a idade sai do carimbo do evento do
SDL». Para o DualSense, essa premissa não vale. O SDL lê o controle pelo HIDAPI dentro do próprio bombeamento de
eventos, e carimba cada relatório com a hora em que o leu, não com a hora em que ele chegou. Como o bombeamento roda
no `forja_quadro`, no mesmo quadro em que o jogo julga, a idade sai perto de zero. A WC01 cura o robô e o caminho
evdev, mas o DualSense de verdade continua julgado pelo quadro: erro uniforme de 0 a 16,7 ms a 60 quadros, e acima
da janela PERFEITO inteira num quadro de 50 ms.

O controle já manda o instante certo. Todo relatório traz o carimbo do sensor, no relógio do próprio controle, e o
SDL o entrega no evento do sensor, que o módulo já recebe (o giro e o acelerômetro estão ligados). A pesquisa pediu
isso ([dualsense.md:321](../pesquisa/dualsense.md), «usar o carimbo do sensor… 4 ms a 250 Hz e não do quadro
16,7 ms»), e a H02 adiou ([H02:195](H02-as-janelas.md)).

## Ler antes

- [WC01 — O toque julgado no instante do aperto](WC01-o-toque-no-instante-do-aperto.md) (o alvo e as armadilhas dos
  dois relógios)
- [A pesquisa do DualSense, a latência](../pesquisa/dualsense.md) (a linha 321)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- O módulo guarda o carimbo do evento do botão, `nativo/nucleo/pads.c:449-452`:
  ```c
  p->b[e->gbutton.button] = e->gbutton.down;
  if (e->gbutton.down) {
    g_apertou[i][e->gbutton.button] = true;
    p->b_quando[e->gbutton.button] = e->gbutton.timestamp;
  ```
- O sensor já chega, `nativo/nucleo/pads.c:330-338` (`SDL_SetGamepadSensorEnabled(gp, SDL_SENSOR_GYRO, true)` e o
  mesmo para o acelerômetro) e `:479-485` (o `SDL_EVENT_GAMEPAD_SENSOR_UPDATE`, que hoje usa só o
  `e->gsensor.timestamp`, o carimbo da leitura, e joga fora o `sensor_timestamp`).
- No SDL 3.4.14 que o módulo compila (libsdl-org/SDL, licença zlib; `src/joystick/hidapi/SDL_hidapi_ps5.c`):
  - `:1600-1601`, o laço de leitura, sem fio próprio:
    ```c
    while ((size = SDL_hid_read_timeout(device->dev, data, sizeof(data), 0)) > 0) {
        Uint64 timestamp = SDL_GetTicksNS();
    ```
  - `:1382-1397`, o carimbo do sensor do relatório (os 4 bytes do `rgucSensorTimestamp`, posição 27 do estado,
    em unidades de 1/3 µs), convertido para ns e acumulado sem volta;
  - `:1404-1410`, o mesmo `timestamp` da leitura vai no botão (`:1182-1185`) e no sensor, e o sensor leva também o
    `sensor_timestamp`.
  - `src/joystick/SDL_joystick.c:3830-3866`: um evento de sensor por relatório, com `event.gsensor.sensor_timestamp`.
- O minigame julga pelo quadro, `godot/scripts/minigames/minigame.gd:227-230` (`var t_toque := Ritmo.t_musica()`).

## O alvo

A idade do aperto de um DualSense (cabo, e rádio depois da WR02) sai do relógio do controle: a diferença entre o
carimbo do sensor do relatório em que o botão desceu e o do último relatório lido no quadro, mais o que passou desde a
leitura do último. A API da WC01 não muda: `idade_do_aperto_us(lugar, botao)` devolve esse número. Sem sensor
(controle de outra marca, rádio sem a WR02, o caminho evdev), vale o que a WC01 já faz.

## Arquivos que mudam

- `nativo/nucleo/pads.c`, `nativo/nucleo/pads.h`
- um par novo na parte sem SDL: `nativo/nucleo/idade.c` e `nativo/nucleo/idade.h` (a conta pura), e
  `nativo/CMakeLists.txt` (a fonte nova e o caso de prova)
- `nativo/testes/prova_idade.c` (novo), ou um caso na prova do nativo que já cobre o simulador
- `docs/jogo/13-arquitetura.md` (a linha do relógio do toque)
- `docs/jogo/tarefas/WC01-o-toque-no-instante-do-aperto.md`, só a frase do alvo sobre o controle de verdade

## Passos

1. Na parte sem SDL, a conta pura: dada a lista do quadro (cada item com o carimbo da leitura `T`, o tipo «botão
   desceu» ou «sensor», e o `sensor_timestamp` `S` quando é sensor) e o agora, devolve a idade de cada botão que
   desceu. O botão de leitura `T` casa com o sensor de mesmo `T` (o mesmo relatório), em qualquer ordem.
2. Em `pads.c`, no `pads_evento`: guardar, por pad, o `T` do botão que desceu (como hoje) e, para cada evento de
   sensor, o par `(T, S)` do quadro, num anel pequeno (64 relatórios bastam: o mesmo teto da leitura crua).
3. No fim do bombeamento (o `pads_atualizar`), chamar a conta: idade = `S_último − S_da_borda` +
   (`SDL_GetTicksNS()` − `T_último`). Sem par para a borda, cair na idade da WC01.
4. Simulado não entra: o simulador já carimba no relógio dele (a WC01).
5. A prova nativa da conta pura (passo 1), sem aparelho.
6. Corrigir o 13 e a frase da WC01.

## Armadilhas

- **Não converter relógios.** O `S` é do controle e não tem relação com o `SDL_GetTicksNS`. Use só diferenças
  dentro de cada relógio, como a WC01 manda.
- **A ordem dos eventos** no mesmo relatório (botão antes do sensor) vem da fonte de hoje; case pelo `T` igual e não
  pela ordem, para não depender dela.
- **O controle parado sem sensor ligado.** Se um dia o giro for desligado fora das salas que o usam, o par some e a
  idade volta à da WC01, sem erro. A prova cobre o caso sem sensor.
- **O espelho** (`pads.c:595-606`) compara `b_quando` entre dois caminhos: não troque o que ele guarda; a idade nova
  é um campo à parte.
- **O rádio antes da WR02** não tem sensor: a idade segue a da WC01 ali, e isso é esperado.

## Não fazer

- Não abrir o hidraw no rádio nem montar o `0x31` para ler o carimbo: o SDL já entrega o `sensor_timestamp`.
- Não somar meio quadro fixo no julgamento.
- Não mudar a assinatura do `idade_do_aperto_us` nem o `julgar_toque`.

## Pronto quando

Na prova nativa, uma fila de oito relatórios sintéticos a 4 ms, com o botão descendo no terceiro e o último lido
2 ms antes do agora, dá idade de 22 ms ± 1 ms (hoje, pela premissa da WC01, daria perto de 0). Sem sensor, a idade é a
do bombeamento.

## Provas

- `scripts/compilar.sh testes` (a prova nova) e `scripts/compilar.sh linux`.
- `bash tests/prova_do_jogo.sh` segue verde (o simulado não muda).
- Rodada pesada pelo semáforo da máquina.

## Para o André (local)

Com o DualSense no cabo, o minigame de prova preso a 30 quadros (`--max-fps 30` antes do `--`): apertar no tempo da
música por um minuto, antes e depois. O desvio padrão dos `toque` no registro cai (de cerca de 9 ms, o quadro de
33 ms, para perto de 1 ms, a resolução de 4 ms do relatório). O mesmo no rádio só depois da WR02.

## Ao terminar

Pôr a linha da WO01 no [quadro](README.md) como **feito**, com o commit, e avisar na X03 e na X04 que a idade do
aperto vem do relógio do controle quando há sensor.
