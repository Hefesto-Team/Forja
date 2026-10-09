# L3 — Curto-Circuito: a pesquisa do DualSense

Ficha: [L3](../tarefas/L3-curto-circuito.md). Seção: [L — O Impacto](../tarefas/L-o-impacto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O coração da bomba** pulsa só no controle de quem segura, e acelera com o pavio secreto: `toque` com mais de 8
  batidas, `aviso` de 8 a 4, `golpe` de 60 ms com menos de 4.
- **O R2 de quem segura** endurece: Feedback força 3, 6 e 8, uma por faixa. Quem não segura: R2 em Off. O L2 é do
  item.
- **O passe** é L1 (vizinho da esquerda) ou R1 (da direita).
- 4 rodadas, pavio de 16–24 ou 10–16 batidas (`PAVIO`). A diversão deu nota 5: é o melhor jogo da noite.
- Sala da prova: `S04_J18`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Mario Party, «Hot Bob-omb» (Hudson, 1998) | a bomba passa de mão em mão até estourar; sem vibração | `mario.fandom.com/wiki/Hot_Bob-omb` |
| Super Mario Party, «Lit Potato» (Nintendo, 2018) | a batata acesa passa até explodir; sem vibração | `mariowiki.com/Lit_Potato` |
| Alien: Isolation, PS4 (2014) | a barra de luz pisca mais rápido com o perigo perto | Stevivor, 2014; Game Informer, 26/03/2014 |
| Spider-Man: Miles Morales (2020) | o Venom Punch estala da esquerda para a direita | Push Square, agosto de 2020 |
| Gran Turismo 7 (2022) | o gatilho pulsa (o ABS) | GTPlanet, agosto de 2020 |

**Não achei** jogo com o batimento de um coração na háptica como relógio escondido. A bomba de batata quente com
coração que acelera é nossa.

## O risco no Linux

1. **O rumble e o gatilho no mesmo relatório.** O pulso (bytes do motor) e o Feedback (bloco do R2) vão no mesmo 0x02,
   com bits de validade diferentes. Se o pulso for mandado sem o bit do gatilho, o gatilho fica como estava (certo);
   se alguém mandar o bloco do R2 zerado junto, o Feedback cai. A prova abaixo pega isso.
2. **O firmware abaixo de 0x0224** divide o rumble por 2: o `toque` pode sumir. Registrar o firmware na bancada.
3. **Dois donos do motor** (o Hefesto e o jogo): o pulso de 60 ms é curto; se outro dono escrever no meio, ele vira
   30 ms. Mesmo risco do [L1](L1-o-cerco.md).
4. **A troca do gatilho é rápida:** a cada passe, um R2 vai de Feedback a Off e outro de Off a Feedback. No cabo, o
   relatório sai a cada 4 ms; não há risco de atraso medido, mas o Steam Input ligado pode reescrever o gatilho.

## As propostas

### 1. O coração em dois tempos (para quem joga)

- **Quem joga:** cada batimento é "tum-tum": 60 ms no forte (1,0), 120 ms de silêncio, 40 ms no fraco (0,6). O
  ritmo segue as faixas que a ficha já tem: uma batida do coração a cada 2 batidas da música (mais de 8), uma por
  batida (de 8 a 4), duas por batida (menos de 4). O par lento-rápido é um coração; um pulso só é um despertador.
- **Os outros:** não sentem nada; o pavio continua secreto.
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S04_J18`. O registro já grava cada
  pulso (`sensacao` com `seq` e `ok`); a prova confere, por faixa, o intervalo entre pulsos (2, 1 e 0,5 batida) e que
  só o dono tem `forte`/`fraco` acima de zero. **A que morde:** `--defeitos=vibra-vizinho` faz o pulso aparecer em
  quem não segura, e o registro acusa o vazamento (a ficha já mede o "fantasma").

### 2. A bomba zumbe no dedo na última faixa (para quem joga)

- **Quem joga:** com menos de 4 batidas, o R2 sai do Feedback 8 e vira `Vibration` (posição 2, amplitude 8,
  frequência 12 Hz): a bomba chia debaixo do dedo. Feedback e Vibration não convivem no mesmo gatilho; a troca de
  modo é o próprio sinal.
- **Os outros:** nada; o pavio continua secreto.
- **Como se prova:** o robô lê o byte do modo. Na faixa de menos de 4: 0x26 só no dono; nas outras: 0x21 no dono e
  0x05 em todos os outros. Com `--defeitos=gatilho-mudo`, o 0x26 não aparece e a prova acusa.

### 3. O passe se sente nas duas mãos (para quem passa e quem recebe)

- **Quem passa** com L1 sente `golpe_esq` 40 ms; com R1, `golpe_dir` 40 ms: a bomba sai pelo lado.
- **Quem recebe** sente a chegada pelo lado de onde veio (do vizinho da direita, `golpe_dir`), 40 ms, e só então o
  coração dele começa. É o estalo de um lado ao outro do Venom Punch, passado entre duas pessoas.
- **Como se prova:** o registro tem, no mesmo passe, a `sensacao` do lado certo nos dois lugares, a menos de 20 ms
  uma da outra. Com `--defeitos=motores-trocados`, os lados saem invertidos e a prova acusa.

## O que preciso de outras cabeças

- **Arquiteto:** o bloco do gatilho inteiro na `percepcao` (a força 3, 6 e 8 só se prova com os 11 bytes).
- **Diretor de jogo:** a proposta 2 troca o Feedback 8 pela Vibration na última faixa; é dele.
