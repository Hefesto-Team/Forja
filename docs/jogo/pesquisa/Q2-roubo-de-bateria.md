# Q2 — Roubo de Bateria (S09_J42): a nota de pesquisa

A ficha: [Q2 — Roubo de Bateria](../tarefas/Q2-roubo-de-bateria.md). O catálogo: [o DualSense](dualsense.md),
recursos 1 (os gatilhos adaptativos), 2 (a háptica) e 4 (o alto-falante), e a mágica 5 (o gatilho que trava).
Pesquisa de 08/10/2026.

## O recurso

O **peso no gatilho**: a 138 bpm (uma batida = 0,43 s), o carregador sente o pulso L2 e R2 alternado, com a pista no
atuador do lado. O peso é `RESISTENCIA` 2,5 nos dois gatilhos. A interferência apaga as duas próximas pistas e estala
no alto-falante.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Splatoon, Rainmaker (Nintendo, 2015) | quem carrega o objetivo anda 20 % mais lento e não tem arma | o carregador é lento, visível e sem defesa | splatoonwiki.org/wiki/Rainmaker |
| Returnal (Housemarque, 2021) | a vibração cresce na recarga | o peso pode crescer com o tempo | blog da PlayStation, 01/04/2021 |
| Death Stranding (Kojima Productions, 2019) | o peso da carga na háptica e nos gatilhos | o corpo sente a carga | já no catálogo |

## O risco no Linux

1. **O rádio e os gatilhos.** No rádio, o relatório de saída é outro (0x31); o efeito precisa sair igual. O defeito
   `gatilho-mudo` imita a perda.
2. **A resistência constante cansa.** `RESISTENCIA` em toda a partida não diz nada depois de 10 s: a mão se acostuma.
3. **O estalo no alto-falante** não pode sair no vizinho (o defeito `som-vizinho`).

## As mágicas, em ordem

### 1. O peso cresce

- **Quem joga:** quanto mais tempo carrega, mais pesado o gatilho.
- **Os outros:** veem o carregador desacelerar.
- **Os números:** força 3 no início, mais 1 a cada 4 batidas (1,7 s), até 8.
- **Como se prova sem o controle:** `percepcao(l).gatilho_dir` a cada 4 batidas: a força sobe 1. Com
  `--defeitos=gatilho-mudo`, reprova.
- **O que falta:** nada no módulo.

### 2. A estática também no gatilho

- **Quem joga:** na interferência, o gatilho treme além do estalo. Vale no rádio, onde a háptica por áudio não existe.
- **Os outros:** ouvem o estalo no colo do roubado.
- **Os números:** `VIBRATION` (0x26), amplitude 3, 30 Hz, por 2 batidas (0,87 s).
- **Como se prova sem o controle:** `percepcao(l).gatilho_dir[0]` = 0x26 nas 2 batidas. Com `gatilho-mudo`, reprova.
- **O que falta:** nada no módulo.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a curva do peso (3 a 8) contra o cansaço da mão, com gente | o designer de sistemas |
