# N2 — Eco do Abismo: a pesquisa do DualSense

Ficha: [N2](../tarefas/N2-eco-do-abismo.md). Seção: [N — O Canto](../tarefas/N-o-canto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O eco no alto-falante diz o lado:** grave (`nota`, 784 Hz) = esquerda; agudo (`nota_alta`, 1175 Hz) = direita.
  Passo com o LX. O lado errado despenca 4 degraus (`ANDAR`); são 24 degraus (`DEGRAUS`).
- A pista só no alto-falante, 0,9; sem alto-falante, a TV a −10 dB.
- O robô vira o LX para o lado que ouviu (`ECO.find(som)`).
- Sala da prova: `S06_J27`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Wii Party, «Hide 'n' Hunt» (Nintendo, 2010) | controles escondidos fazem sons de bicho pelo alto-falante; acha-se pelo ouvido | Wikipedia, `Wii_Party`; Nintendo UK, 2010 |
| Super Mario Galaxy 2, Beat Block (2010) | o controle bipa e o chão muda | WhatCulture |
| Ghost of Tsushima Director's Cut (2021) | o vento aponta o caminho (na háptica) | catálogo, mágica 9 |
| Rhythm Heaven (2006) | jogar só pelo som, chamada e resposta | Wikipedia; Nintendo Life, 2009 |

## O risco no Linux

1. **O alto-falante é mono.** O lado não vem da caixa de som, vem da altura (grave e agudo). Não há como apontar o
   lado por estéreo no controle. Se o kernel 6.18+ manda só o canal direito ao alto-falante (a série de Cristian
   Ciocaltea, `lwn.net/Articles/1026850`), o som tem que estar nesse canal.
2. **Dois donos do volume e da rota** (bytes 5 e 7): o kernel e o módulo. Detalhe no [N1](N1-o-canto.md).
3. **A latência do quantum** (até 42 ms a 2048 amostras); o passo com o LX é julgado na batida.
4. **O alto-falante pequeno perde o grave?** Não achei a resposta em frequência publicada. **Medir na bancada:** o
   nível de 784 e de 1175 Hz a 0,9, com o microfone da bancada a 30 cm; a diferença tem que ficar abaixo de 6 dB, ou
   o grave some e todos vão à direita.

## As propostas

### 1. A queda se ouve (para quem cai e para os outros)

- **Quem cai:** o lado errado toca, no alto-falante dele, as duas notas descendo (`nota_alta` e depois `nota`, 120 ms
  cada): o corpo caindo no abismo.
- **Os outros:** a TV toca o mesmo, a 0,3: a sala sabe que alguém caiu, não qual lado era o certo (a queda já
  aconteceu; não entrega pista).
- **Como se prova sem o controle:** `--simular=4 --robo=ruim --semente=7 --sala=S06_J27`. O registro tem, a cada
  queda, os dois sons no alto-falante do dono (`som_virtual(l)` mostra `nota` por último) e o evento `caiu` na TV
  depois do passo. **A que morde:** `--defeitos=som-vizinho` toca a queda em outro lugar e a prova acusa.

### 2. O eco repete mais baixo (para quem joga)

- **Quem joga:** a pista toca duas vezes: 0,9 e, meia batida depois, 0,4. A segunda vez confirma o lado para quem
  perdeu a primeira, e soa como eco de caverna.
- **Como se prova:** o registro tem dois `pista` por degrau, mesmo `o_que`, volumes 0,9 e 0,4, a meia batida um do
  outro. O robô responde ao primeiro que ouvir; com `--defeitos=engasga`, ele ainda acerta pelo segundo.

### 3. O passo certo pisa firme (para quem joga)

- **Quem joga:** o passo certo toca `coleta` a 0,3 no alto-falante dele, 1 por degrau. O degrau 24 toca `pronto`
  (1568 Hz, 0,5 s): o topo.
- **Como se prova:** o registro tem um `coleta` por passo certo e um `pronto` no degrau 24, só no dono.

## O que preciso de outras cabeças

- **Bancada (F01):** o nível do grave contra o agudo no alto-falante (risco 4).
- **Diretor de som:** a queda em duas notas e o eco a 0,4.
- **Arquiteto:** o canal que o kernel manda ao alto-falante (risco 1).
