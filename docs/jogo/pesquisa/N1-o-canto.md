# N1 — O Canto: a pesquisa do DualSense

Ficha: [N1](../tarefas/N1-o-canto.md). Seção: [N — O Canto](../tarefas/N-o-canto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O alto-falante do controle canta a chamada**; o jogador responde. Grave (`nota`, 784 Hz) = ✕; aguda
  (`nota_alta`, 1175 Hz) = ○. A distância é uma quinta justa (1175 ÷ 784 = 1,499).
- **A pista mora só no alto-falante.** A tela diz quando, nunca o quê. A barra de luz pulsa só na resposta.
- **Sem alto-falante:** a pista vai à TV a −10 dB (`no_controle: false` no registro).
- **O robô ouve** `Forja.som_virtual(l)` (o nível do falante e o nome do último som) e responde só o que ouviu.
- Frase inteira certa: +50 (`FRASE_INTEIRA`). A ficha diz `"nota_no_falante": false`: o kit não toca a resposta dele.
- Sala da prova: `S06_J26`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Rhythm Heaven (Nintendo, 2006) | a proposta do Tsunku, em 2004: ritmo sem pista visual, chamada e resposta; o mesmo time do WarioWare. O Rhythm Heaven Groove sai em 2026 | Wikipedia, `Rhythm_Heaven`; Nintendo Life, abril de 2009 |
| Simon (Ralph Baer e Howard Morrison, Milton Bradley, 1978) | quatro notas de corneta, a sequência cresce 1 por rodada; veio do Touch Me da Atari (1976) | Wikipedia, `Simon_(game)`; IEEE Spectrum; Smithsonian, `nmah_1302005` |
| Super Mario Galaxy 2, Beat Block (Nintendo, 2010) | o controle bipa na batida e as plataformas trocam | WhatCulture, «9 Times The Wii Remote Speaker Actually Improved Gameplay» |
| Big Brain Academy: Wii Degree (Nintendo, 2007) | o controle avisa só a você se a resposta está certa | WhatCulture (a mesma lista) |
| Death Stranding (Kojima Productions) | o bebê chora no alto-falante do controle | catálogo; análise da Empire do Director's Cut |

A queixa comum do alto-falante do Wii Remote era a qualidade fraca (WhatCulture). O do DualSense também é pequeno e
mono.

## O risco no Linux

1. **Dois donos do alto-falante.** A série «HID: playstation: Add support for audio jack handling on DualSense» (v2,
   Cristian Ciocaltea, Collabora, 25/06/2025, 11 patches; `lwn.net/Articles/1026850`; Phoronix) entrou no Linux 6.18.
   Ela põe o fone como saída padrão, troca para o alto-falante mandando o **canal direito** a ele quando o fone sai, e
   sobe o volume do alto-falante. Esta máquina roda o 7.1.5: o kernel escreve a rota e o volume (bytes 5 e 7 do
   relatório) junto com o módulo. Se o módulo mandar o som no canal esquerdo, o alto-falante cala.
2. **A latência do PipeWire.** O quantum de 2048 amostras a 48 kHz atrasa 42 ms; o de 256, 5,3 ms. A chamada sai
   atrasada do tamanho do quantum; o julgamento da resposta tem que descontar. **Medir** com `pw-top` na bancada e
   gravar o quantum no registro.
3. **O mapa de canais.** O issue 2486 do PipeWire: som que não é háptica vaza para os canais 3 e 4 (a háptica). Uma
   nota no canal errado vira tremor.
4. **O fone tampa o alto-falante** (`hid-playstation`, byte 53, rota 0). Com fone plugado, a pista vai ao fone; é
   ainda privada, então serve.
5. **Pelo rádio** o controle não tem placa de som; o SAxense manda háptica a 3000 Hz (cerca de 1,5 kHz de teto, a
   metade). Não achei fonte pública que toque o alto-falante pelo rádio. É fora do CONTRATO (só cabo).

## As propostas

### 1. O segredo no ouvido: cada um com a sua chamada (para quem joga)

- **Quem joga:** a frase de cada lugar é sorteada por lugar, não uma para todos. O vizinho ouve a dele e não pode
  copiar a sua. A pista é privada de verdade.
- **Os outros:** ouvem só um murmúrio do lado; ninguém cola.
- **De onde veio:** a mágica 2 do catálogo (o segredo no ouvido); o Big Brain Academy (o aviso só seu).
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S06_J26`. Cada robô responde pelo
  `som_virtual(l)`; o registro cruza a `pista` (`o_que`) de cada lugar com o `toque` dele em pelo menos 95%, e as
  frases dos quatro lugares diferem. **A que morde:** `--defeitos=som-vizinho` faz o robô ouvir a frase do vizinho e
  o acerto cai abaixo de 60%; `--defeitos=sem-alto-falante` leva a pista à TV com `no_controle: false` e o registro
  marca o caminho de reserva.

### 2. A contagem no controle antes da chamada (para quem joga)

- **Quem joga:** uma batida antes da chamada, um `clique` (20 ms, 0,5) no alto-falante dele. É o "um, dois" do Beat
  Block do Mario Galaxy 2: o ouvido se prepara e a latência do quantum fica antes, não em cima da nota.
- **Os outros:** não ouvem.
- **Como se prova:** o registro tem o `clique` mandado uma batida antes de cada `pista` do mesmo lugar; o
  `som_virtual(l)` mostra `clique` e depois `nota` ou `nota_alta`.

### 3. O coro sai na TV depois da resposta (para os outros)

- **Os outros:** depois da resposta da frase, a TV toca as respostas certas de todos juntas, a 0,4. A sala ouve o coro
  que se formou; a pista continua só no controle.
- **Como se prova:** o registro tem o evento `coro` na TV só depois do último `toque` da frase; nenhum som da TV antes
  da resposta (a prova confere a ordem).

## O que preciso de outras cabeças

- **Arquiteto:** conferir que o módulo e o kernel 6.18+ não brigam pela rota e pelo volume (bytes 5 e 7), e o mapa de
  canais (o som no canal que o kernel manda ao alto-falante).
- **Diretor de som:** o `clique` de contagem e o coro na TV.
- **Bancada (F01):** o quantum do PipeWire e o atraso medido do alto-falante.
