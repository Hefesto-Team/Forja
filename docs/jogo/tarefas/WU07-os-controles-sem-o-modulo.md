# WU07 — Os controles sem o módulo

**Sprint:** W · **Tamanho:** G · **Depende de:** [WR01](WR01-um-sdl-so-dono-do-dualsense.md) (o ambiente que tira o
DualSense do SDL do motor só vale com o módulo; sem ele, o motor fica com o controle e é isso que esta ficha usa) e
[WU01](WU01-o-modulo-no-piso-do-godot.md) (que tira a causa mais comum de ficar sem módulo)

## Por quê

Quando o módulo não carrega, nenhum controle joga: o jogo vira um jogador no teclado. Fica sem módulo quem tem uma
glibc abaixo do piso (até a WU01), o Linux em ARM e o macOS (não há biblioteca para eles no `.gdextension`; a matriz
anota como WF-02) e qualquer biblioteca que falhe ao abrir. Só que o motor 4.7 já enxerga esses mesmos controles pelo
SDL dele e os entrega ao `Input`, com nome, vibração e luz. O caminho sem módulo foi escrito no 4.4, quando o motor
não tinha isso.

## Ler antes

- `COMO-RODAR.md` («o macOS não tem módulo») e a [WF-matriz](../revisao/WF-matriz.md) (WF-02)
- [05 — Háptica e controle](../05-haptica-e-controle.md) (o que cada lugar sente)

## O estado de hoje

- `godot/forja.gdextension:9-10`: só `linux.x86_64` e `windows.x86_64`.
- `godot/scripts/forja.gd:124-142`: o módulo ou nada; sem ele, só o lugar 0 pelo teclado:
  ```gdscript
  func apertou(l: int, botao: int) -> bool:
  	if modulo:
  		return ctl.apertou(l, botao)
  	return l == 0 and _teclado_apertou(botao)
  ```
  `pad_apertou` e `pad_segura` (`:415-422`) devolvem falso, `eixo` devolve 0 fora do lugar 0 (`:431-445`), e
  `jogar_no_teclado` (`:387`) exige o módulo.
- `grep -rn 'get_connected_joypads\|is_joy_button_pressed\|get_joy_axis\|start_joy_vibration\|set_joy_light'
  godot/scripts` fora dos testes dá zero.
- Godot 4.7.2 (godotengine/godot, MIT), `drivers/sdl/joypad_sdl.cpp:139-206`: todo controle entra no `Input`, com
  vibração, luz e sensores.
- A tela já não diz nada sem o módulo (`godot/scripts/ui/tela_titulo.gd:37-39`).

## O alvo

Sem o módulo, os controles que o motor vê jogam nos lugares 0 a 3: entram no lobby, apertam, mexem os analógicos,
vibram e acendem a cor do lugar. Ficam de fora só gatilho, alto-falante, háptica por áudio e microfone (o que só o
módulo fala). Nenhuma tela nem texto muda; o registro diz «sem o módulo: os controles pelo motor».

## Passos

1. Em `forja.gd`, uma camada para `modulo == false`: a lista de controles do `Input`
   (`Input.get_connected_joypads()`, o sinal `joy_connection_changed`) vira os índices de pad que o lobby já usa
   (`conectados`, `pad_apertou`, `pad_segura`, `entrar`, `pad_do_lugar`).
2. O mapa CRUZ..R1 do jogo para `JOY_BUTTON_*`, e os eixos para `JOY_AXIS_*`, com a mesma zona morta.
   `apertou`, `segura`, `soltou` e `eixo` por lugar leem dali (o aperto travado por quadro, como no módulo).
3. `vibrar` e `sentir` por `Input.start_joy_vibration`; `luz` e `luz_do_lugar` por `Input.set_joy_light`; o resto
   das saídas devolve falso, como hoje.
4. O teclado do lugar 0 continua somado, como agora.

## Armadilhas

- **Com o módulo carregado, nada disto roda**: a WR01 tira o DualSense do motor, e o `Input` não pode virar um
  segundo leitor.
- **O mapa de botões** do motor segue o desenho do controle Xbox (A embaixo): A→✕, B→○, X→□, Y→△, como fazem as
  referências que emulam a plataforma.
- **Sem o módulo não há relatório nativo**: o registro do `forja.gd` é o que fica; a prova confere por ele.
- **Tamanho G**: é uma camada inteira; não misturar com outra ficha.

## Não fazer

- Não reescrever o lobby nem o fluxo: só a fonte dos apertos muda.
- Não tentar gatilho, alto-falante ou microfone pelo motor.
- Não oferecer nada novo na tela.

## Pronto quando

Com `--sem-modulo`, dois controles do motor entram no lobby, jogam uma partida e vibram.

## Provas

- **Do jogo, na caixa**, com `--sem-modulo`: `Input.joy_connection_changed(0, true, "pad", "guid")` e
  `(1, …)` simulam dois controles; `Input.parse_input_event` com um `InputEventJoypadButton` (device 1,
  `JOY_BUTTON_A`) aperta. `Forja.apertou(1, Forja.CRUZ)` verdadeiro e `Forja.conectados()` igual a 2. Hoje falso e 0:
  reprova.
- `bash tests/prova_do_jogo.sh` verde com o módulo, pelo semáforo.

## Para o André (local)

Com `--sem-modulo`, um controle qualquer no cabo: entra no lobby com ✕, joga a Viga pelos analógicos, vibra no
Impacto, e a luz toma a cor do lugar.

## Ao terminar

Marcar WU07 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`feat(controles): sem o módulo, os controles do motor jogam nos quatro lugares`.
