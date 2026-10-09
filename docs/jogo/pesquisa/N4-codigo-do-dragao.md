# N4 — Código do Dragão: a pesquisa do DualSense

Ficha: [N4](../tarefas/N4-codigo-do-dragao.md). Seção: [N — O Canto](../tarefas/N-o-canto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **Uma senha por jogador**, de 3 a 12 notas (`INICIO` 3, `MAXIMO` 12), tocada só no alto-falante dele: `nota:0`
  (Dó5, 523 Hz), `nota` (784 Hz) e `nota_alta` (1175 Hz), uma por botão: ✕, ○, △.
- **Como o Simon:** ouve a senha, repete; a senha cresce.
- Pontos: 0, 10, 20, 30 por nota da resposta; a senha inteira vale 20 × o comprimento.
- Sala da prova: `S06_J29`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Simon (Ralph Baer e Howard Morrison, Milton Bradley, 1978) | quatro notas de corneta; a sequência cresce 1 por rodada; veio do Touch Me da Atari (1976) | Wikipedia, `Simon_(game)`; IEEE Spectrum; Smithsonian, `nmah_1302005` |
| Big Brain Academy: Wii Degree (2007) | o controle avisa só a você se a resposta está certa | WhatCulture, «9 Times The Wii Remote Speaker Actually Improved Gameplay» |
| Rhythm Heaven (2006) | chamada e resposta sem pista visual | Wikipedia; Nintendo Life, 2009 |
| Death Stranding (Kojima Productions) | o som privado do controle | catálogo |

## O risco no Linux

1. **As três notas no alto-falante pequeno.** Dó5 (523 Hz) é a mais grave; se o alto-falante perde o grave, o ✕ some.
   **Medir na bancada:** o nível das três a 0,9, microfone a 30 cm; diferença máxima de 6 dB.
2. **Dois donos da rota e do volume** (o kernel 6.18+ e o módulo; detalhe no [N1](N1-o-canto.md)).
3. **A latência do quantum** (até 42 ms) em cada nota da senha: numa senha de 12 notas a 1 por batida, o atraso não
   soma (cada nota sai na batida dela), mas a primeira nota pode vir 42 ms tarde.
4. **O fone tampa o alto-falante:** com fone, a senha vai ao fone; continua privada.

## As propostas

### 1. A senha é segredo de verdade (para quem joga)

- **Quem joga:** a senha toca só no alto-falante dele. A tela mostra o tamanho (os pontinhos), nunca as notas. Os
  outros não têm como ajudar nem atrapalhar.
- **Os outros:** veem os pontinhos crescerem e o dragão reagir.
- **De onde veio:** o Big Brain Academy (o aviso só seu); a mágica 2 do catálogo.
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S06_J29`. O robô repete o que ouviu
  pelo `som_virtual(l)`; o registro cruza a `pista` (`o_que`) de cada lugar com os `toque` dele. **A que morde:**
  `--defeitos=som-vizinho` faz o robô repetir a senha do vizinho; o acerto cai. Com `sem-alto-falante`, o registro
  marca `no_controle: false` e a senha vai à TV a −10 dB (aí a senha deixa de ser segredo: anotar no registro).

### 2. O tempo encurta depois de 6 notas (para quem joga)

- **Quem joga:** até 6 notas, uma nota por batida; de 7 a 12, uma por meia batida. A senha longa vira uma frase
  rápida, e o ouvido trabalha mais no fim. Os números são nossos; não achei fonte com os limiares do Simon original.
- **Como se prova:** o registro tem as `pista` de uma senha de 7 ou mais a meia batida uma da outra; até 6, a uma
  batida.

### 3. O erro ruge na TV (para os outros)

- **Os outros:** a nota errada faz o dragão rugir na TV (o `tropeco`, 0,6). A sala sabe quem errou, não qual era a
  nota.
- **Quem joga:** no alto-falante dele, nada a mais; o erro já se sente pelo rugido.
- **Como se prova:** o registro tem o `tropeco` na TV logo depois do `toque` errado, e nenhum som da senha na TV.

## O que preciso de outras cabeças

- **Bancada (F01):** o nível das três notas no alto-falante (risco 1).
- **Diretor de jogo:** o ritmo de meia batida a partir de 7 notas (proposta 2).
- **Diretor de som:** o rugido na TV.
