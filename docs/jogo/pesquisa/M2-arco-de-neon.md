# M2 — Arco de Neon: a pesquisa do DualSense

Ficha: [M2](../tarefas/M2-arco-de-neon.md). Seção: [M — A Galeria](../tarefas/M-a-galeria.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O R2 é a corda:** `Feedback` na posição 2, e a força sobe a cada batida da nota (parado: força 2,
  `FORCA_PARADO`). Solta-se no fim da nota.
- **A flecha de fogo:** no pico, R2 acima de 0,9 (`FUNDO`) vale +50 (`FOGO`). Abaixo de 0,35 (`SEGURA`), no meio da
  nota, a corda afrouxa e conta como soltura.
- A diversão pediu: **a flecha de fogo queima o alvo do vizinho da direita**.
- Sala da prova: `S05_J22`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Kena: Bridge of Spirits (Ember Lab, 2021) | a resistência do arco aperta até a puxada inteira; no fundo, mais força e mais precisão | GamingBolt, «Kena developer talks combat with DualSense features»; PlayStation LifeStyle, 22/12/2020 |
| Horizon Forbidden West (Guerrilla, 2022) | o gatilho dá a tensão da corda do arco e o peso das armas grandes | página da PlayStation Store; GamingBolt, «Horizon Forbidden West Weapons Feel More Unique» |
| Astro's Playroom (2020) | a mola no gatilho guarda a força e a solta no pulo; a Digital Foundry fala em «sentir a energia potencial» | Wikipedia, `Astro's_Playroom`; blog da PlayStation, `?p=343436` |
| The Legend of Zelda: Twilight Princess, Wii (2006) | a corda soa no controle e o impacto na TV | prévia da E3 2006, Nintendo World Report |
| `isteamdualsense.h` e o gerador do Nielk1 | o MULTIPLE_POSITION_FEEDBACK (força por zona); é `emenda` hoje | catálogo, mágica 7 |

## O risco no Linux

1. **A força por zona é `emenda`.** O "degrau" no fundo (força baixa no meio, parede no fim) pede o
   MULTIPLE_POSITION_FEEDBACK, que o CONTRATO não deixa hoje. Com o Feedback simples, a força vale de uma zona em
   diante, igual até o fim.
2. **O fundo 0,9 e o Edge:** 0,9 do curso é seguro; nunca exigir 1,0.
3. **O Steam Input** pode reescrever o gatilho (catálogo).
4. **A troca de modo a cada batida** (a força sobe) são 4 a 6 relatórios por nota; no cabo, a 4 ms cada, sem risco
   medido de atraso. Pelo rádio é fora do CONTRATO.

## As propostas

### 1. O braço cansa se segurar demais (para quem joga)

- **Quem joga:** passou do fim da nota com o R2 acima de 0,35, o gatilho sai do Feedback e vira `Vibration`
  (posição 2, amplitude 3, frequência 8 Hz): o braço treme. A mão sabe que passou da hora, sem olhar.
- **Os outros:** nada.
- **De onde veio:** a tensão da corda do Kena e do Horizon; o tremor é nosso.
- **Como se prova sem o controle:** `--simular=4 --robo=ruim --semente=7 --sala=S05_J22` (o robô ruim solta tarde).
  O robô da seção lê o byte do modo: 0x21 durante a nota, 0x26 depois do fim enquanto segura, 0x05 quando solta. A
  prova conta que 0x26 só aparece depois do fim de uma nota. Com `--robo=bom`, 0x26 quase não aparece. **A que
  morde:** `--defeitos=gatilho-digital` faz o R2 pular de 0 a 1; a soltura no meio some e o registro acusa.

### 2. O estalo no fundo, só no pico (para quem joga)

- **Quem joga:** no pico, a corda deixa de ser Feedback e vira `Weapon` (início 2, fim 8, força 8): a resistência
  cresce até o estalo em 0,9. O estalo é a flecha de fogo pronta. Fora do pico, Feedback como está.
- **Os outros:** veem a flecha acender.
- **Por que não a força por zona:** o Weapon dá o "degrau" hoje, dentro do CONTRATO. O MULTIPLE_POSITION_FEEDBACK
  seria melhor (puxada macia e parede no fundo), mas é `emenda` e depende da Vitória.
- **Como se prova:** no pico, `percepcao(l)["gatilho_dir"]` é 0x25; fora, 0x21. A prova conta a troca nas batidas
  do pico, por lugar.

### 3. A flecha de fogo chega pelo lado (para quem leva, pedida pela diversão)

- **Quem leva:** a flecha vem do vizinho da esquerda e queima o alvo dele: ele sente `golpe_esq` 120 ms. O lado diz
  de onde veio, como o Spider-Man aponta o ataque (Push Square, agosto de 2020).
- **Quem atira:** nada a mais; o estalo da proposta 2 já é dele.
- **Como se prova:** o registro tem, na flecha de fogo de `l`, a `sensacao` `golpe_esq` no vizinho da direita de
  `l`. Com `--defeitos=vibra-vizinho`, a sensação cai noutro lugar e a prova acusa.

## O que preciso de outras cabeças

- **A Vitória:** a emenda do CONTRATO para o MULTIPLE_POSITION_FEEDBACK (a corda macia com parede no fundo). Sem ela,
  fica a proposta 2.
- **Arquiteto:** os 11 bytes do gatilho na `percepcao` (a força que sobe a cada batida só se prova com eles).
- **Diretor de jogo:** a flecha que queima o vizinho.
