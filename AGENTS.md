# FORJA — lei do repo

Leia [CONTRATO.md](CONTRATO.md) antes de qualquer patch. Se o patch quebra uma linha de lá, o patch está errado.

- Jogo de 4 jogadores **local**. Sem online.
- DualSense como a Sony e a Steam documentam: USB relatório `0x02`.
- Gatilho só: Off, Feedback, Weapon, Vibration.
- Proibido: socket Hefesto, uniq/MAC, relatório Bluetooth `0x31`, CRC `0xA2`, DSX.
- `forja-send` recusa DualSense no rádio.
- Player index 0..3, nunca endereço físico.
- Rodar local: `./run-local.sh`.
