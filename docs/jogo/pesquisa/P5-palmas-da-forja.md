# P5 — Palmas da Forja (S08_J40): a nota de pesquisa

A ficha: [P5 — Palmas da Forja](../tarefas/P5-palmas-da-forja.md). O catálogo: [o DualSense](dualsense.md), recursos 6
(o microfone) e 2 (a háptica), e a mágica 3 (o metrônomo na mão). Pesquisa de 08/10/2026.

## O recurso

O **microfone pela palma**: palmas no 2 e no 4, a 118 bpm (uma batida = 0,51 s), as viradas em chamada e resposta.
`JANELA_CASA` 0,25 s. A palma da turma entra se metade ou mais acertar.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| DK Bongos, Donkey Konga (Nintendo, 2003) | a palma pelo microfone do bongô | dispara com a voz; a palma pura é mais fácil de pegar que a voz | mario.fandom.com/wiki/DK_Bongos |
| Rhythm Heaven (Nintendo, 2006 em diante) | chamada e resposta sem tutorial | ouvir e repetir ensina sozinho | en.wikipedia.org/wiki/Rhythm_Heaven_Fever |
| Konvalinka et al. (2010) | quem bate junto se adapta sem líder | a turma sincroniza se cada um ouve | QJEP 63(11); orbit.dtu.dk |

## O risco no Linux

1. **A palma de um entra em quatro microfones.** Sem vazamento no simulador, a prova sem controle não vê.
2. **O cancelamento de ruído** (bit 3 de `0x0D`) pode cortar a palma, que é um transitório curto. Mesmo experimento
   da [P2](P2-o-sopro-no-fole.md).
3. **A háptica do kit** (o acerto) no tempo da palma suja o microfone.

## As mágicas, em ordem

### 1. A virada do ferreiro na mão

- **Quem joga:** no compasso 2, sente a virada do ferreiro na mão; no 3, silêncio; repete no 4 com palmas.
- **Os outros:** o mesmo, cada um no seu controle.
- **Os números:** a virada como háptica a 0,7 no compasso 2; nada no 3 nem no 4.
- **Como se prova sem o controle:** o robô lê `som_virtual(l)` no compasso 2, guarda o padrão e bate palmas
  (`robo_falar` curto) no 4. Com `--defeitos=haptica-muda`, o robô não repete e a turma falha.
- **O que falta:** nada.

### 2. As quatro barras piscam juntas

- **Quem joga:** a palma da turma entrou: as quatro barras piscam juntas.
- **Os outros:** o mesmo; a festa é coletiva.
- **Os números:** 100 % por 0,1 s nas quatro, na cor de cada lugar.
- **Como se prova sem o controle:** `percepcao(l).luz` das quatro no mesmo quadro.
- **O que falta:** nada.

### 3. O acerto do kit desligado na janela do microfone

- **Quem joga:** a própria palma não é apagada pelo próprio controle.
- **Os outros:** nada.
- **Os números:** háptica e rumble ≤ 0,3 (ou 0) de `t − 0,25` a `t + 0,25` em cada palma.
- **Como se prova sem o controle:** `som_virtual(l)` e `percepcao(l)` abaixo de 0,3 nas janelas.
- **O que falta:** a regra no kit (o diretor de som e háptica).

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o acerto do kit desligado nas janelas do microfone | o diretor de som e háptica |
| o vazamento no simulador e o experimento do bit 3 | o arquiteto |
