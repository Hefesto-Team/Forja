# R — O Relâmpago (RELAMPAGO): a nota de pesquisa

A ficha: [R — O Relâmpago](../tarefas/R-o-relampago.md). O catálogo: [o DualSense](dualsense.md), todos os recursos
que os 45 usam, com peso em 1 (os gatilhos adaptativos), 2 (a háptica), 4 (o alto-falante), 6 (o microfone) e 7 (o
botão e a luz do mudo). Pesquisa de 08/10/2026.

## O recurso

O controle inteiro em **microjogos de 5 a 8 s**, a 160 bpm (uma batida = 0,375 s). O nível sobe a cada 5; `ESPACO`
[2, 1,5, 1, 1]. As mecânicas: BATER, MARCHAR, APERTAR, INCLINAR, TRACAR, DEFENDER, PUXAR, REPETIR, SENTIR e SOPRAR. A
pista de DEFENDER e a pedra de SENTIR vêm meia batida antes (0,19 s). Três vidas no aquecimento, uma no desempate.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| WarioWare (Nintendo, 2003 em diante) | microjogos de poucos segundos, quatro vidas, a pressa cresce | a palavra na tela basta como regra | en.wikipedia.org/wiki/WarioWare |
| WarioWare: Touched!, Lung Capacity e Tread Carefully (Nintendo, 2004) | microjogos de microfone: soprar até o fim; não soprar | o microfone cabe num microjogo se o verbo é longo ou é «não faça» | mariowiki.com/Lung_Capacity; mariowiki.com/Tread_Carefully_(microgame) |
| Rhythm Heaven (Nintendo), os remixes | os jogos voltam juntos, sem treino | o microjogo só funciona se a estação já foi ensinada | rhythmheaven.fandom.com/wiki/Remix |

## O risco no Linux

1. **A latência da placa contra a meia batida.** A pista de SENTIR vem 188 ms antes; menos os ≥ 42,7 ms da placa (ver
   a [O3](O3-passo-no-fosso.md)) sobram ≤ 145 ms.
2. **DEFENDER pelo rumble.** O rumble corta a háptica (a suspeita (e) do 05); no cabo, o aviso de DEFENDER pelo rumble
   apaga a pedra de SENTIR se os dois caírem juntos. Sobram 37 ms entre um e outro no nível mais denso.
3. **SOPRAR a 375 ms.** Um sopro curto de uma batida é frágil: a `LATENCIA_MIC` 0,08 e o `VOZ_FICA` comem metade.
4. **O mudo da P1 e da P3** pode chegar ao Relâmpago com a conta ímpar (ver a [P1](P1-a-voz.md)).

## As mágicas, em ordem

### 1. A assinatura do cartão no controle

- **Quem joga:** antes de ler a palavra, a mão já sabe a mecânica: tique no gatilho para APERTAR e PUXAR, bipe no
  alto-falante para REPETIR, piscar do `led_mic` para SOPRAR, pedra para SENTIR.
- **Os outros:** ouvem e veem os quatro colos mudarem juntos.
- **Os números:** 1 batida antes do microjogo; tique `VIBRATION` 0x26 amplitude 2, 60 ms; bipe 120 ms a 0,5; `led_mic`
  2 por 1 batida.
- **Como se prova sem o controle:** `percepcao(l)` e `som_virtual(l)` na batida anterior a cada microjogo, contra a
  mecânica do registro (`estacao`). Com `--defeitos=gatilho-mudo`, `som-vizinho` ou `led-mic-parado`, reprova.
- **O que falta:** nada no módulo.

### 2. SOPRAR é longo ou é «não sopre»

- **Quem joga:** SOPRAR vira um sopro de 2 batidas (Lung Capacity) ou «Não sopre!» (Tread Carefully).
- **Os outros:** riem de quem sopra quando não podia.
- **Os números:** sopro de 0,75 s com 0,6 s acima de `VOZ_ACIMA`; ou silêncio de 1,5 s abaixo de `MARGEM_AR`.
- **Como se prova sem o controle:** `robo_falar(l, 0,5, 0,75)` acerta; `robo_falar(l, 0,5, 0,3)` erra. Com
  `--defeitos=mic-surdo`, «não sopre» passa e o sopro falha: o registro anota.
- **O que falta:** a decisão do diretor de jogo.

### 3. DEFENDER pela háptica do lado

- **Quem joga:** no cabo, o aviso de DEFENDER é um golpe na háptica do lado, sem rumble; nada apaga a pedra.
- **Os outros:** nada.
- **Os números:** háptica 150 ms, ganho 1,0, no lado do golpe; no rádio, o rumble `golpe_esq` ou `golpe_dir`.
- **Como se prova sem o controle:** `som_virtual(l)` do lado certo e `percepcao(l).forte/fraco` a 0 no cabo. Com
  `haptica-trocada`, reprova.
- **O que falta:** nada no módulo.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| `LATENCIA_PLACA` medida (vale para SENTIR e DEFENDER) | o arquiteto |
| SOPRAR longo ou «não sopre» | o diretor de jogo |
| a paridade do mudo herdada das seções P | o arquiteto |
