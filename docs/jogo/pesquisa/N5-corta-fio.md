# N5 — Corta-Fio: a pesquisa do DualSense

Ficha: [N5](../tarefas/N5-corta-fio.md). Seção: [N — O Canto](../tarefas/N-o-canto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O bipe no alto-falante diz o fio:** `pronto` (1568 Hz, 0,5 s) = o fio certo; `clique` (20 ms) = o errado;
  `nota_alta` (1175 Hz) = o bipe falso, mandado ao líder.
- 3 fios por bomba (`FIOS_POR_BOMBA`). O robô corta pelo bipe que ouviu (`BIPE.find(som) == CERTO`).
- Sala da prova: `S06_J30`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Keep Talking and Nobody Explodes (Steel Crate, 2015) | informação assimétrica: um vê a bomba, outro lê o manual; bombas sorteadas; 2 erros permitidos | GDC Vault 1023113, «Designing Asymmetric Gameplay»; Destructoid |
| Big Brain Academy: Wii Degree (2007) | o controle diz só a você se está certo | WhatCulture |
| Mario Party, «Hot Bob-omb» (1998) | a bomba que passa e estoura | `mario.fandom.com/wiki/Hot_Bob-omb` |
| Death Stranding (Kojima Productions) | o som privado do controle | catálogo |

## O risco no Linux

1. **O `clique` de 20 ms pode não chegar.** 20 ms a 48 kHz são 960 amostras: menos da metade de um quantum de 2048.
   Se o PipeWire juntar o clique num pedaço com silêncio ou o alto-falante demorar a ligar, o clique some e o fio
   errado fica mudo. **Medir na bancada:** 20 cliques, microfone a 30 cm; meta de 20 ouvidos.
2. **O bipe falso e o certo são próximos.** 1568 ÷ 1175 = 1,334, uma quarta justa. Num alto-falante pequeno, só a
   altura pode não bastar.
3. **Dois donos da rota e do volume** (kernel 6.18+ e módulo; detalhe no [N1](N1-o-canto.md)).
4. **A latência do quantum** (até 42 ms).

## As propostas

### 1. O falso é curto, o certo é longo (para o líder)

- **O líder:** o bipe certo (`pronto`) dura 0,5 s; o falso (`nota_alta`) dura 0,15 s. Altura e duração diferentes: o
  líder pode aprender a desconfiar do bipe curto, e o falso continua enganando quem não presta atenção.
- **Os outros:** não ouvem o bipe do líder.
- **De onde veio:** a assimetria do Keep Talking (cada um com uma parte da verdade).
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S06_J30`. O registro grava o `tipo`
  (certo, errado, falso) e a duração de cada bipe; a prova confere 0,5 s no certo e 0,15 s no falso. Um robô que
  separa pela duração corta certo em pelo menos 90% das bombas do líder; o robô de hoje (que separa pelo nome) não
  muda.

### 2. O clique nunca menor que 40 ms (para quem joga)

- **Quem joga:** o `clique` do fio errado passa a ter 40 ms no alto-falante (o dobro), para caber no caminho do
  áudio sem sumir. O `clique` de 20 ms continua onde já está (a contagem e a interface).
- **Como se prova:** o registro tem o `clique` do fio errado com 40 ms. **A que morde:** `--defeitos=sem-alto-falante`
  leva o clique à TV a −10 dB; o registro marca `no_controle: false`.
- **Na bancada:** a medida do risco 1, com 20 e com 40 ms.

### 3. O fio cortado se revela depois (para os outros)

- **Os outros:** depois do corte, a TV mostra o fio que era o certo (verde) por 1 s, e a sala ri de quem caiu no
  falso. Nunca antes do corte.
- **Como se prova:** o evento `revelou` vem no registro depois do `toque` do corte, nunca antes; a prova confere a
  ordem em todas as bombas.

## O que preciso de outras cabeças

- **Diretor de som:** o `pronto` de 0,5 s contra o falso de 0,15 s, e o clique de 40 ms.
- **Bancada (F01):** o clique de 20 e de 40 ms (risco 1).
- **Diretor de jogo:** a revelação depois do corte.
