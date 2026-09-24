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
| `F5` | Voz: o microfone padrão do sistema | A barra sobe com a voz; o botão de mudo zera a barra |
| `Esc` | Hub | |

Na Galeria, o tiro de quem joga sai **no alto-falante do próprio controle** (forja-speak). Na Viga, girar o controle gira o boneco (forja-read); sem IMU, a HUD diz «stick». Embaixo, a linha do som diz o alto-falante que o jogo achou — ou que não achou.

Se o motor do vizinho tremer, o isolamento na frente do hidraw falhou. O jogo não percebe — a mesa é o oráculo.

## Empacotador sozinho (sem Godot)

```bash
make test
make send
./bin/forja-send --list
./bin/forja-send --player 2 --left 240 --r2 vibration
```

`--player 2` é o terceiro DualSense USB. Se o primeiro tremer, falhou.

## O alto-falante e o movimento (sem Godot)

```bash
make speak read
./bin/forja-speak --list                        # todo alto-falante que um jogo reconheceria
./bin/forja-speak --player 0                    # bip no alto-falante do 1º DualSense, pelo APARELHO
./bin/forja-speak --nome "Controle 2"           # pelo NOME que o jogo mostra (a pessoa aponta)
./bin/forja-speak --player 0 --hz 60 --vcm      # tremor nos dois atuadores, sem bip
./bin/forja-speak --player 0 --canal 0          # a mordida: o fone, não o plástico — silêncio
./bin/forja-read --player 0                     # giro e acelerômetro (report 0x01)
```

Os dois jeitos de um jogo achar o alto-falante: **pelo aparelho** (o port de PS5 casa o endpoint com o controle pelo USB — só no cabo) e **pelo nome** (o jogo lista as saídas e a pessoa aponta; sob Proton o nome é a descrição do nó). `--list` mostra os dois: `acha sozinho` é o que o primeiro acharia sem ninguém apontar.

`forja-speak` sai com `rc=2` quando não acha, e `rc=4` quando o alto-falante achado não tem o canal pedido — "não achei" nunca se lê como "toquei e nada saiu". `forja-read` recusa o rádio com a mesma frase do `forja-send`.

## As provas

```bash
make test         # o empacotador, o alto-falante e o movimento — sem som e sem aparelho
make test-jogo    # o jogo headless: a HUD acha o alto-falante pelo nome (precisa do Godot em tools/)
```

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
