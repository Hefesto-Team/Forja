# FORJA nativo

Jogo local de 4 DualSense que fala o controle **como a Sony e a Steam documentam**. Não fala Hefesto.

Leia [CONTRATO.md](CONTRATO.md) antes de qualquer patch. Para executar: [COMO-RODAR.md](COMO-RODAR.md). Backlog: [SPRINTS.md](SPRINTS.md).

```bash
./run-local.sh
```

Isso compila o empacotador USB `0x02`, baixa Godot 4.4.1 se faltar, e abre o jogo.

## O que tem aqui

| caminho | o que é |
| --- | --- |
| `include/forja_dualsense.h` | payload USB `0x02` + Off / Feedback / Weapon / Vibration |
| `src/forja_dualsense.c` | empacotador compartilhado |
| `src/forja_selftest.c` | prova: nunca emite `0x31`, isola player index no byte |
| `src/forja_send.c` | escreve em `/dev/hidraw*` USB; **recusa Bluetooth** |
| `godot/` | jogo Godot 4.4 — Hub, Galeria, Impacto, Viga, A Prova |
| `run-local.sh` | um comando para jogar no Linux |
| `udev/` | regra para escrever hidraw sem root |

A build web no preview Grok é apresentação. Isolamento de verdade: este binário + quatro DualSense no cabo.

## Mesa de teste

```
make test
make send
./bin/forja-send --list
./bin/forja-send --player 2 --left 240 --r2 vibration
```

`--player 2` é o DualSense de índice 2 (P3). Se o motor esquerdo do P1 tremer, o isolamento na frente do hidraw falhou. O jogo não tem como saber.

No jogo: tecla `3` manda o mesmo pacote. Só o P3 deve tremer o motor L.

## Godot

`godot/project.godot` no Godot 4.4+. Rumble via `Input.start_joy_vibration` (SDL) + `forja-send` para o relatório USB completo (gatilho, lightbar, LED de jogador).

Com [GodotSteam](https://godotsteam.com/) depois:

- `Steam.setLEDColor(handle, r, g, b, 0)`
- `Steam.triggerVibration(handle, left, right)`
- `Steam.setDualSenseTriggerEffect(handle, scePadParam)`

Plugue isso em `scripts/dualsense_pad.gd` no ramo Steam. Não adicione um cliente IPC.

## Steam

Appid de teste (ainda não publicado). Action set local-coop com 4 controllers. PlayStation controller support = ligado. Steam Input fala DualSense USB; FORJA nunca menciona o transporte físico.

## Assets

Kenney Mini Dungeon (CC0) em `godot/assets/kenney/`.
