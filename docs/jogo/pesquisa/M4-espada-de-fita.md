# M4 — Espada de Fita: a pesquisa do DualSense

Ficha: [M4](../tarefas/M4-espada-de-fita.md). Seção: [M — A Galeria](../tarefas/M-a-galeria.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **A puxada:** R2 em `Feedback`, a força sobe um degrau por batida: 3, 5, 7, 8. Solta-se no pico.
- **As duplas:** Brasa contra Maré. Os dois da dupla soltando PERFEITO fecham o acorde (`ACORDE` 2). Dupla de um só
  vale dobrado; com um jogador, o espantalho vale 8 por estocada.
- Sala da prova: `S05_J24`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Astro's Playroom (2020) | a mola guarda a força no gatilho e solta no pulo | Wikipedia, `Astro's_Playroom`; blog da PlayStation, `?p=343436` |
| Kena: Bridge of Spirits (2021) | a resistência aperta até o fundo; no fundo, mais força | GamingBolt; PlayStation LifeStyle, 22/12/2020 |
| Ghostwire: Tokyo (2022) | cada elemento tem um gatilho que se reconhece de olhos fechados | catálogo (blog da PlayStation, maio de 2021) |
| Ghost of Tsushima Director's Cut (2021) | o vento na háptica | catálogo, mágica 9 |
| Spider-Man: Miles Morales (2020) | a háptica aponta o lado | Push Square, agosto de 2020 |

## O risco no Linux

1. **Os degraus 3, 5, 7, 8 são próximos no dedo.** Do 7 ao 8 a diferença é pequena (a escala é 0–8). **Medir na
   bancada:** 10 pares às cegas, "subiu ou não"; meta de 9 em 10 por degrau. Se o 7→8 falhar, trocar por 2, 4, 6, 8.
2. **O Edge** trava antes do fim: nunca pedir 100%.
3. **O Steam Input** pode reescrever o gatilho.
4. **A força só se lê no registro** até o arquiteto expor os 11 bytes.

## As propostas

### 1. Brasa e Maré têm gatilhos diferentes (para quem joga)

- **Brasa:** a puxada que a ficha já tem, Feedback 3, 5, 7, 8: dura, seca.
- **Maré:** os três primeiros degraus iguais (3, 5, 7), e o último vira `Vibration` (posição 4, amplitude 3,
  frequência 20 Hz): a água corre debaixo do dedo no pico. De olhos fechados, cada um sabe de que lado está.
- **De onde veio:** o Ghostwire (cada elemento com o seu gatilho).
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S05_J24`. No 4º degrau,
  `percepcao(l)["gatilho_dir"]` é 0x21 na Brasa e 0x26 na Maré. A prova confere por dupla. **A que morde:**
  `--defeitos=gatilho-mudo` deixa um lugar em 0x05 e o registro acusa.

### 2. A fita arrebenta se passar do pico (para quem joga)

- **Quem joga:** se o R2 continua apertado uma colcheia depois do pico, o gatilho vai a **Off** de repente: a fita
  arrebentou, o dedo afunda. A soltura tarde se sente como queda, não como número.
- **Os outros:** veem a fita cair.
- **Como se prova:** com `--robo=ruim`, o registro mostra 0x05 uma colcheia depois do pico, com o R2 ainda acima de
  `R2_SOLTA` 0,2. Com `--robo=bom`, o 0x05 vem só depois da soltura.

### 3. O parceiro se sente no acorde (para a dupla)

- **A dupla:** quando o parceiro solta PERFEITO, você sente 40 ms só no motor do lado dele, a 0,3 (o forte se ele
  está à esquerda, o fraco se está à direita). Os dois perfeitos juntos: `golpe` 80 ms nos dois, o acorde.
- **Os outros:** veem o acorde fechar.
- **Como se prova:** o registro tem a `sensacao` no parceiro a menos de 20 ms da soltura PERFEITA. Com
  `--defeitos=vibra-vizinho`, ela cai na dupla errada e a prova acusa.

## O que preciso de outras cabeças

- **Bancada (F01):** os degraus às cegas (risco 1).
- **Designer de sistemas:** o perfil da Maré (proposta 1) é perfil de arma.
- **Arquiteto:** os 11 bytes do gatilho na `percepcao`.
