# Rodar FORJA na sua máquina

Linux x86_64. DualSense no **cabo USB**. Este jogo não fala Bluetooth.

## Um comando

```bash
chmod +x run-local.sh
./run-local.sh
```

Na primeira vez baixa o Godot 4.4.1 (~60 MB) e abre o jogo. Teclado basta para a demo. DualSense no cabo ativa rumble SDL + relatório USB `0x02` (gatilho, lightbar, LED de jogador).

## O que você deve ver na mesa

| Tecla | O que o jogo manda | Aceite |
| --- | --- | --- |
| `1` | P1 dispara, motor R, R2 Vibration | P2/P3/P4 quietos |
| `3` | P3 toma da esquerda, motor L = 240 | P1 não treme |
| `F1` | Galeria, 4 lanes | R2 de um pad não endurece o vizinho |
| `F2` | Impacto | Tiro esquerdo = motor L daquele pad |
| `F3` | Viga | Flick 180 só naquele player |
| `F4` | A Prova | Lightbar cai com a vida de cada um |
| `Esc` | Hub | |

Se o motor do vizinho tremer, o isolamento na frente do hidraw falhou. O jogo não percebe — a mesa é o oráculo.

## Empacotador sozinho (sem Godot)

```bash
make test
make send
./bin/forja-send --list
./bin/forja-send --player 2 --left 240 --r2 vibration
```

`--player 2` é o terceiro DualSense USB. Se o primeiro tremer, falhou.

## Permissão hidraw

Se `forja-send` imprimir `Permission denied`:

```bash
sudo cp udev/99-forja-dualsense.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Reconecte o DualSense. Sem isso o rumble ainda pode funcionar via SDL (`Input.start_joy_vibration`); gatilho e lightbar precisam do hidraw.

## Godot na mão

Godot 4.4+: abra `godot/project.godot` e aperte Play. O jogo procura `../bin/forja-send` sozinho.

## Windows / macOS

O jogo Godot abre. Rumble SDL funciona. `forja-send` é Linux hidraw — a prova de isolamento USB `0x02` é no Linux, que é a mesa do Hefesto.
