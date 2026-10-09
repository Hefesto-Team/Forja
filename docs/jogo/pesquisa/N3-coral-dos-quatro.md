# N3 — Coral dos Quatro: a pesquisa do DualSense

Ficha: [N3](../tarefas/N3-coral-dos-quatro.md). Seção: [N — O Canto](../tarefas/N-o-canto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **Cada controle canta a sua nota** (`nota:<lugar>`) na sua vez; a ordem é sorteada. As notas do
  [som](../arte/03-som.md) por lugar: Dó, Ré, Fá, Sol, o acorde da Forja.
- **O acorde:** no pico, a cada 4 chamadas (`ACORDE_A_CADA`), os quatro cantam juntos.
- **O vitral:** 12 painéis (4 × 3). A luz pulsa 0,12 s na resposta (`PULSO_S`).
- Sala da prova: `S06_J28`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Wii Party, «Hide 'n' Hunt» (2010) | o som sai do controle escondido e se acha pelo lugar dele na sala | Wikipedia, `Wii_Party`; Nintendo UK, 2010 |
| Simon (Milton Bradley, 1978) | uma nota por cor, a sequência cresce 1 por rodada | Wikipedia, `Simon_(game)`; IEEE Spectrum; Smithsonian |
| Wii Music, «Handbell Harmony» (Nintendo, 2008) | o controle e o Nunchuk como sinos, cada jogador com as suas notas | Wikipedia, `Wii_Music`. **Não confirmei** se o som sai do alto-falante do controle; não afirmo |
| Death Stranding (Kojima Productions) | a voz sai do controle, não da TV | catálogo |

## O risco no Linux

1. **Quatro placas de som, quatro atrasos.** Cada DualSense no cabo é um dispositivo de áudio USB próprio, com nó
   próprio no PipeWire. O acorde dos quatro "juntos" pode sair com até um quantum de diferença entre eles (42 ms a 2048
   amostras, 5,3 ms a 256). 42 ms soa como arpejo, não acorde. **Medir na bancada:** os quatro tocando a mesma batida,
   o microfone no meio da mesa; a meta é menos de 20 ms entre o primeiro e o último.
2. **O kernel 6.18+ também mexe na rota e no volume** de cada controle (a série de Cristian Ciocaltea,
   `lwn.net/Articles/1026850`). Quatro controles, quatro vezes o risco de dois donos. Detalhe no [N1](N1-o-canto.md).
3. **O mapa de canais** (issue 2486 do PipeWire): a nota pode vazar para a háptica.
4. **Os controles têm volume diferente.** Mesmo valor de volume, alto-falantes de lotes diferentes; medir os quatro
   na bancada, meta de até 3 dB de diferença.

## As propostas

### 1. O acorde que sai da sala (para todos)

- **Todos:** no acorde, cada nota sai do controle de quem a canta, e a TV fica calada. O acorde acontece **no ar da
  sala**, entre as mãos, como o «Hide 'n' Hunt» acha o controle pelo som. Ninguém tem o acorde inteiro na mão.
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S06_J28`. No acorde, o registro tem
  quatro `pista` com `nota:0` a `nota:3`, cada uma no lugar dela, todas na mesma batida, e a TV sem som. A diferença
  de tempo entre as quatro no registro é zero; o atraso real só a bancada mede (risco 1). **A que morde:**
  `--defeitos=som-vizinho` troca as notas de lugar e a prova acusa.

### 2. O atraso de cada controle se desconta (para todos)

- **Todos:** a bancada mede o atraso de cada alto-falante (risco 1) e grava por controle; o jogo manda a nota de cada
  um adiantada desse tanto. O acorde fica junto mesmo com atrasos diferentes.
- **Como se prova:** com atrasos falsos por lugar no simulador (por exemplo 0, 10, 20 e 40 ms), a prova confere que o
  envio de cada um sai adiantado do seu atraso e que a soma chega na mesma batida.
- **Fica com quem:** o arquiteto (o atraso por controle no simulador e na bancada).

### 3. Quem é a próxima voz (para quem canta)

- **Quem canta a seguir:** meia batida antes da vez dele, um `clique` (20 ms, 0,4) no alto-falante dele. A vez é
  sorteada; o clique diz "é você" sem a tela entregar.
- **Os outros:** não ouvem.
- **Como se prova:** o registro tem o `clique` no lugar certo meia batida antes de cada chamada dele, e só nele.

## O que preciso de outras cabeças

- **Bancada (F01):** o atraso e o volume dos quatro alto-falantes (riscos 1 e 4).
- **Arquiteto:** o atraso por controle (proposta 2), e um jeito de simular atrasos diferentes por lugar.
- **Diretor de som:** o `clique` da vez.
