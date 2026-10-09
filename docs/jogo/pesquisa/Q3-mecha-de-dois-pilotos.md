# Q3 — Mecha de Dois Pilotos (S09_J43): a nota de pesquisa

A ficha: [Q3 — Mecha de Dois Pilotos](../tarefas/Q3-mecha-de-dois-pilotos.md). O catálogo:
[o DualSense](dualsense.md), recursos 1 (os gatilhos adaptativos), 14 (o firmware e o carimbo de tempo), 4 (o
alto-falante) e 2 (a háptica). Pesquisa de 08/10/2026.

## O recurso

A **sincronia de dois**: a 145 bpm (uma batida = 0,41 s), E e D pisam alternado. O soco é o R2 em `ARMA` 2,6,8 dos
dois dentro de `SINC` 0,09 s. O gongo é `pronto` no alto-falante. A perna é háptica do lado.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Octodad: Dadliest Catch (Young Horses, 2014) | co-op em que cada um controla um membro; o modo roleta troca os membros | o corpo dividido é a graça, e a falta de sincronia também | Shacknews (artigo 82880) |
| Konvalinka et al. (2010) | quem bate junto se adapta sem líder | sentir o parceiro melhora a sincronia | QJEP 63(11); orbit.dtu.dk |
| 1-2-Switch (Nintendo, 2017) | dois jogadores, olho no olho, no mesmo sinal | o sinal comum é o gongo | já no catálogo |

## O risco no Linux

1. **A janela de 90 ms contra o quadro.** O jogo lê a entrada a cada quadro (16,7 ms a 60 Hz). Dois sensores a 4 ms
   (250 Hz) carimbam melhor: o relatório traz o carimbo de tempo do sensor (o recurso 14). Medir no quadro tira até
   17 ms da janela.
2. **O tiro pelo eixo, não pela fase** (ver a [Q1](Q1-a-prova.md)).
3. **Dois controles, dois rádios:** a latência pelo Bluetooth varia mais que pelo cabo.

## As mágicas, em ordem

### 1. O soco pela fase e pelo carimbo

- **Quem joga:** o soco duplo sai quando os dois sentem o clique a menos de 90 ms, medido no sensor.
- **Os outros:** nada.
- **Os números:** a fase do Weapon (byte 41) e o carimbo do sensor de cada controle; `SINC` 0,09 s.
- **Como se prova sem o controle:** o robô aperta os dois com 80 ms e 100 ms de diferença; a prova confere acerto e
  erro. Pedir ao arquiteto que o simulador carimbe a 4 ms.
- **O que falta:** a fase e o carimbo expostos (o arquiteto).

### 2. Sentir o parceiro pronto

- **Quem joga:** na janela do gongo, quando o eixo do parceiro passa 0,3, o R2 dele treme leve. Ele sabe que o outro
  está pronto.
- **Os outros:** nada.
- **Os números:** `VIBRATION` (0x26), amplitude 1, 40 Hz, enquanto o parceiro está acima de 0,3.
- **Como se prova sem o controle:** `robo_eixo` do parceiro a 0,4 e `percepcao(l).gatilho_dir[0]` = 0x26.
- **O que falta:** nada no módulo.

### 3. A cabeçada em dobro

- **Quem joga:** o clang soa nos dois alto-falantes da dupla ao mesmo tempo.
- **Os outros:** ouvem o estéreo da dupla na sala.
- **Os números:** `clang`, volume 0,7, nos dois controles no mesmo quadro.
- **Como se prova sem o controle:** `som_virtual(l).falante` dos dois. Com `--defeitos=som-vizinho`, reprova.
- **O que falta:** nada.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o carimbo do sensor e a fase do Weapon no simulador | o arquiteto |
