# O1 — Os Caminhos (S07_J31): a nota de pesquisa

A ficha: [O1 — Os Caminhos](../tarefas/O1-os-caminhos.md). A seção: [O — Os Caminhos](../tarefas/O-os-caminhos.md). O
catálogo: [o DualSense](dualsense.md), recurso 2 (a háptica por áudio) e 3 (o rumble). Pesquisa de 08/10/2026.

## O recurso

A **háptica por áudio**: os canais 3 e 4 da placa USB de quatro canais do controle, a 48 kHz. A senha é a textura de
um dos quatro chãos (`passo:<chão>:<variação>`), dois passos a 2 batidas um do outro (1 s a 120 bpm). No rádio, o
mesmo chão vai pelo rumble (`Forja.sentir`). A TV fica calada sobre a senha.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Astro's Playroom (Team Asobi, 2020) | metal com passos «clicados» alternando esquerda e direita; areia mais leve e espalhada; gelo mais fino e central | os chãos se distinguem pelo **lugar** na mão (lado, centro) além do envelope | prévias da GameSpot («A DualSense showcase») e da Stevivor |
| The Last of Us Part I (Naughty Dog, 2022) | a fala vira vibração, e quem joga sente a ênfase da frase | a mão lê **ritmo e ênfase** de um envelope, não só a força | blog da PlayStation, 26/08/2022 («full list of accessibility features»); Trusted Reviews |
| 1-2-Switch, Ball Count (Nintendo, 2017) | contar bolinhas pelo tato | a contagem de toques é a pista mais grossa que ainda funciona no motor | já no catálogo, «O que os jogos de PS5 ensinam» |

## O risco no Linux

1. **A ordem dos canais.** A AnyPS5, pelo driver `pulseaudio` do SDL, abriu 6 canais e achou a háptica nas posições 4 e
   5 (o catálogo, recurso 2). Se o nó do PipeWire vier com outro mapa, a senha toca no alto-falante ou num lado só.
   O defeito `haptica-trocada` do simulador já pega o lado; o canal errado inteiro só a bancada pega.
2. **A cauda do metal** (0,55 s) contra o passo seguinte: a ficha já deixa 0,2 s de silêncio. Não muda com o Linux.
3. **O rumble cala a háptica.** O SDL desliga a háptica por áudio enquanto há rumble (`SDL_hidapi_ps5.c`, a suspeita
   (e) do 05). No cabo, o acerto do kit é háptica; não há rumble na bifurcação. No rádio é tudo rumble.
4. **A latência da placa não pesa aqui.** A escolha vem 4 a 6 batidas (2 a 3 s) depois da senha. Os 42,7 ms mínimos do
   caminho (1024 quadros do SDL mais o quantum 1024 do PipeWire, ver a [O3](O3-passo-no-fosso.md)) não mudam nada.

## As mágicas, em ordem

### 1. A senha anda: esquerda, depois direita

- **Quem joga:** o 1º passo da senha sai só no atuador esquerdo, o 2º só no direito, como o pé do Astro. A senha vira
  um cavaleiro andando na palma. No pico (um passo só), os dois lados juntos.
- **Os outros:** nada; a senha continua só dele.
- **Os números:** `som_haptica(l, passo, "")` em `b0`, `som_haptica(l, "", passo)` em `b0 + 2`, ganho 1,0 nos dois.
- **Como se prova sem o controle:** a prova lê `Forja.som_virtual(l)` a cada quadro: em `b0` a `b0 + 0,3`, `esq` acima
  de 0,05 e `dir` abaixo de 0,02; em `b0 + 2`, o contrário. Com `--defeitos=haptica-trocada`, a ordem chega invertida
  e o registro (`pista`, com o `canal`) diz. O robô continua acertando o chão, porque o `chao_do_envelope` não olha o
  lado: a prova separa «o lado chegou» de «o chão chegou».
- **O que falta:** nada no módulo.

### 2. O eco da senha na TV, depois da escolha

- **Quem joga:** confirma o que sentiu: depois de escolher, o passo do chão certo soa na TV na raia dele.
- **Os outros:** ouvem os quatro chãos em hoqueto e aprendem as texturas pelo ouvido, sem ninguém explicar. A mesa
  descobre quem sentiu o quê.
- **Os números:** `Som.tocar("passo:<senha>:0", raia, -8.0)` em `b0 + 6,5`, só para quem escolheu certo.
- **Como se prova sem o controle:** a prova escuta os sons da TV por lugar e reprova qualquer `passo:` na TV entre `b0`
  e `b0 + 6` (a TV não pode vazar a senha). O robô no temperamento ruim escolhe errado e a TV não toca o eco dele.
- **O que falta:** nada no módulo.

### 3. O chão no rádio pela contagem

- **Quem joga:** sem placa, o chão vira um número de toques que a mão conta, porque o rumble não tem textura: grama 3
  toques de 40 ms, cascalho 5 de 25 ms, metal 1 de 140 ms forte, água 1 rampa de 300 ms fraca.
- **Os outros:** nada.
- **Os números:** os toques no motor fraco (o direito) a 0,6, com 60 ms de pausa; metal no forte a 1,0.
- **Como se prova sem o controle:** com a placa virtual fora (o caminho `_rumble`), o robô lê `Forja.percepcao(l)`
  (`forte`, `fraco`) a cada quadro, conta os picos e escolhe. Com `--defeitos=motores-trocados`, o metal chega no
  motor errado e o robô ainda acerta pela contagem; o registro anota o lado.
- **O que falta:** a tabela de padrões nas sensações (F05).

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| conferir o mapa de canais da placa pelo nó do PipeWire, na bancada (F01) | o arquiteto |
| a tabela de padrões de chão no rumble (a mágica 3) | o diretor de som e háptica |
| o eco na TV (a mágica 2) contra a regra de silêncio da seção | o diretor de jogo |
