# Resultados da bancada

O caderno de bancada dos experimentos (ver [README.md](README.md)). Entra tudo
o que foi rodado — o que mediu, o que falhou e o que não deu para medir —,
com a data, o lugar e os controles. Linha nova no fim de cada tabela; nada se
apaga.

- **simulador:** `--simular=N --robo`, controles de mentira; prova que a
  bancada anda. O que precisa de aparelho sai "não medido".
- **mesa:** DualSense de verdade, com a origem de cada um (nativo, Edge
  virtual, Xbox virtual) e a conexão (cabo, rádio).

## Situação

| experimento | simulador | mesa (cabo) | mesa (rádio) |
| --- | --- | --- | --- |
| `laco` | não medido (sem microfone de verdade) | ainda não rodado | ainda não rodado |
| `quatro-mics` | medido: 4 de 4 | ainda não rodado | ainda não rodado |
| `eco` | não medido (sem microfone de verdade) | ainda não rodado | ainda não rodado |
| `gatilho-cru` | não medido (sem report cru) | ainda não rodado | não se aplica (o jogo só lê o report USB) |
| `haptica-nomeada` | medido: 4 de 4; com `haptica-trocada`, falhou 0 de 4 | ainda não rodado | ainda não rodado |

## `laco`

| data | onde | controles | resultado | notas |
| --- | --- | --- | --- | --- |
| 2026-09-27 | simulador, 4 controles | 4 simulados | não medido, nos 4 | sem microfone de verdade: a placa virtual não tem entrada |
| 2026-09-28 | jogo 3D, simulador, 4 controles | 4 simulados | não medido, nos 4 | o mesmo no jogo 3D: sem microfone de verdade |

## `quatro-mics`

| data | onde | controles | resultado | notas |
| --- | --- | --- | --- | --- |
| 2026-09-27 | simulador, 4 controles | 4 simulados | medido: som em 100% dos quadros nos 4; 4 de 4 microfones mais altos com o próprio jogador (margem 42 dB) | o robô fala na vez dele; os microfones de mentira só ouvem o próprio robô, por isso a margem é grande |
| 2026-09-28 | jogo 3D, simulador, 4 controles | 4 simulados | medido: som em 100% dos quadros nos 4, a -12 dB com a própria voz; 4 de 4 microfones mais altos com o próprio jogador (margem 42 dB) | o mesmo no jogo 3D |

## `eco`

| data | onde | controles | resultado | notas |
| --- | --- | --- | --- | --- |
| 2026-09-27 | simulador, 4 controles | 4 simulados | não medido, nos 4 | sem microfone de verdade |
| 2026-09-28 | jogo 3D, simulador, 4 controles | 4 simulados | não medido, nos 4 | o mesmo no jogo 3D |

## `gatilho-cru`

| data | onde | controles | resultado | notas |
| --- | --- | --- | --- | --- |
| 2026-09-27 | simulador, 4 controles | 4 simulados | não medido, nos 4 | controle simulado não tem report cru USB `0x01` |
| 2026-09-28 | jogo 3D, simulador, 4 controles | 4 simulados | não medido, nos 4 | o mesmo no jogo 3D |

## `haptica-nomeada`

| data | onde | controles | resultado | notas |
| --- | --- | --- | --- | --- |
| 2026-09-27 | simulador, 4 controles | 4 simulados | medido: lado certo 4 de 4, nos 4 | a placa virtual, achada pelo aparelho; o robô sente os canais 3 e 4 |
| 2026-09-27 | simulador, 2 controles, `--defeito haptica-trocada` | 2 simulados | falhou: lado certo 0 de 4, nos 2 | a prova da prova: com os canais 3 e 4 trocados, a bancada acusa |
| 2026-09-28 | jogo 3D, simulador, 4 controles | 4 simulados | medido: lado certo 4 de 4, nos 4 | o mesmo no jogo 3D |
| 2026-09-28 | jogo 3D, simulador, 4 controles, `--defeitos=haptica-trocada` | 4 simulados | falhou: lado certo 0 de 4, nos 4 | a prova da prova no jogo 3D (`tests/prova_da_bancada.sh`) |
