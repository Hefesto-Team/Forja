# L1 — O Cerco: a pesquisa do DualSense

Ficha: [L1](../tarefas/L1-o-cerco.md). Seção: [L — O Impacto](../tarefas/L-o-impacto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **Vibração por lado**, pela `Forja.sentir(l, nome, ms)`: `golpe_esq` 1,0·0,0 e `golpe_dir` 0,0·1,0 dizem de que
  lado vem o golpe, **uma batida antes**. O jogador defende com L1 (esquerda) ou R1 (direita).
- **O hoqueto:** os lugares se revezam no tempo; cada um só sente a pista dele.
- **O aríete** no pico: `explosao` 1,0·1,0 em todos.
- **A barra de luz é a vida:** brilho de 40% a 100%, sempre na cor do lugar (`BRILHO`, `VIDA_MIN` 1, a luz nunca
  apaga).
- Sala da prova: `S04_J16`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Marvel's Spider-Man: Miles Morales (Insomniac, 2020) | a háptica avisa a direção do ataque (o sentido-aranha); o Venom Punch estala da esquerda para a direita | Push Square, agosto de 2020, `pushsquare.com/news/2020/08/marvels_spider-man_miles_morales_will_use_ps5_to_convey_spider-sense`; Gizmodo |
| Demon's Souls (Bluepoint, 2020) | a háptica confirma o aparo (parry) no instante certo | análises de lançamento |
| Super Mario Party, «Rattle and Hmmm» (Nintendo, 2018) | reconhecer pelo tremor (força, pausa, estilo, duração) qual inimigo fez o barulho; 5, 3, 2 e 1 pontos | `mariowiki.com/Rattle_and_Hmmm` |
| Mario Party 5, «Rumble Fumble» (Nintendo, 2003) | casar o padrão do tremor com o balde certo; o balde errado solta um Bob-omb | `mariowiki.com/Rumble_Fumble` |
| Astro's Playroom (Team Asobi, 2020) | os pés do Astro batem alternando os lados | catálogo, seção 3 |
| SDL, `SDL_hidapi_ps5.c` | o rumble de compatibilidade nos dois motores; metade da força no firmware abaixo de 0x0224 | catálogo, as fontes de fora |

Ninguém achado faz **defesa por lado** pela vibração num jogo de quatro. O Spider-Man é o parente mais próximo,
para um jogador só.

## O risco no Linux

1. **Os dois lados se misturam na mão.** No DualSense os dois "motores" do rumble são atuadores de bobina simulados
   pelo firmware, e a carcaça leva o tremor de um lado ao outro. A Nintendo diz o mesmo do Joy-Con 2 (mais
   silencioso, o «Joy-Con Hide & Seek» ficou mais difícil; Nintendo Life, maio de 2025). **Medir na bancada (F01):**
   20 pistas às cegas por pessoa; o lado tem que acertar em pelo menos 18 (90%).
2. **O firmware antigo corta pela metade.** O SDL divide o rumble por 2 abaixo do firmware 0x0224. A Forja manda o
   relatório 0x02 pelo módulo, mas o firmware de cada controle vai para o registro da bancada.
3. **Dois donos do motor.** O Godot nunca chama `start_joy_vibration`; e o tato vivo do Hefesto não pode falar por
   cima do jogo (o Hefesto já tem a tarefa de o tato vivo só falar onde o jogo cala). Se os dois escrevem o 0x02, o
   último vence a cada 4 ms.
4. **O SDL corta a háptica por áudio enquanto há rumble** (a suspeita (e) do catálogo). O Cerco não usa a háptica
   por áudio; se o diretor de som puser um baque nos canais 3 e 4, ele some durante o golpe.

## As propostas

### 1. O sentido-aranha em dois tempos (para quem joga)

- **Quem joga:** a pista ganha um pré-aviso. Duas batidas antes, `aviso` fraco (0,3) no mesmo lado, 60 ms; uma
  batida antes, o `golpe_esq` ou `golpe_dir` cheio, 120 ms. O par "fraco, forte" no mesmo lado se lê melhor que um
  pulso só, porque o lado é dito duas vezes.
- **Os outros:** nada muda na tela; a pista é só de quem defende.
- **De onde veio:** Spider-Man Miles Morales (a direção do ataque) e o «Rattle and Hmmm» (o padrão diz quem).
- **Como se prova sem o controle:** a prova do jogo com `--simular=4 --robo=bom --semente=7 --sala=S04_J16`.
  O robô lê `Forja.percepcao(l)`: `forte > 0` e `fraco == 0` é esquerda, o contrário é direita, e aperta L1 ou R1.
  O registro tem que cruzar `pista` (o lado mandado) com `toque` (o lado apertado) em pelo menos 95% das notas.
  **A prova que morde:** com `--defeitos=motores-trocados`, o acerto do robô cai abaixo de 10% (ele defende sempre
  do lado errado); com `vibra-vizinho`, a pista aparece no `forte`/`fraco` de outro lugar e o registro acusa.
- **Na bancada:** a medida do risco 1 (18 de 20 às cegas).

### 2. O aríete pesa menos em quem segurou (para quem joga)

- **Quem joga:** no pico, o aríete é `explosao` 1,0·1,0 por 200 ms em todos; quem defendeu certo sente só 60 ms. A
  diferença de 140 ms é o escudo, e se sente sem olhar.
- **Os outros:** veem o escudo de quem segurou acender (é da arte).
- **Como se prova:** o registro grava a `sensacao` com a duração por lugar; no pico, quem tem `toque` certo tem
  60 ms e os outros 200 ms. Com `--robo=ruim`, a maior parte fica com 200 ms.

### 3. A luz pisca no bloqueio perfeito (para os outros)

- **Os outros:** num PERFEITO, a barra de luz do dono vai a 100% por 80 ms e volta ao brilho da vida. Quem está do
  lado vê quem segurou no tempo, como a barra do DualShock 4 piscava junto do detector no Alien: Isolation
  (Gary Napper, Stevivor, 2014; Game Informer, 26/03/2014).
- **Quem joga:** nada a mais na mão.
- **Como se prova:** `percepcao(l)["luz"]` sobe ao brilho 1,0 por 5 quadros a 60 fps e volta ao `BRILHO[vida]`. Com
  `--defeitos=luz-parada`, o pico não aparece e a prova acusa.

## O que preciso de outras cabeças

- **Diretor de jogo:** decidir se o pré-aviso (proposta 1) entra nas três primeiras rodadas só, ou na noite toda.
- **Bancada (F01):** a medida do lado às cegas e o firmware de cada controle.
