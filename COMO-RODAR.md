# Rodar FORJA na sua máquina

O jogo é o FORJA em 3D (Godot 4.4 com o módulo nativo): como compilar, rodar
no Linux, rodar o `.exe` pelo Proton e validar com quatro DualSense está no
[README](README.md). Este arquivo cobre as ferramentas de bancada
(`forja-send`, `forja-speak`, `forja-read`) — o mesmo empacotador USB `0x02`
do jogo, para mandar um efeito a um controle sem abrir o jogo.

Linux x86_64. DualSense no **cabo USB**: as ferramentas de bancada não falam
Bluetooth.

```bash
./run-local.sh bancada     # compila as ferramentas e lista os DualSense no cabo
```

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

Para abrir o jogo direto numa sala (é o que a folha de teste do Hefesto faz):
`tools/Godot_v4.4.1-stable_linux.x86_64 --path godot -- --sala=voz` (ou `galeria`, `impacto`, `viga`, `prova`).

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
