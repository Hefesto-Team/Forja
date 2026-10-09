# Q1 — A Prova (S09_J41): a nota de pesquisa

A ficha: [Q1 — A Prova](../tarefas/Q1-a-prova.md). A seção: [Q — A Prova](../tarefas/Q-a-prova.md). O catálogo:
[o DualSense](dualsense.md), recursos 1 (os gatilhos adaptativos), 4 (o alto-falante), 2 (a háptica) e 15 (o
DualSense Edge), e as mágicas 1 (a arma no gatilho) e 5 (o gatilho que trava). Pesquisa de 08/10/2026.

## O recurso

Tudo junto num **cabo de guerra** a 145 bpm (uma batida = 0,41 s): o martelo no ✕ e a besta no R2 em `ARMA` 2,6,8, o
tiro quando o R2 cruza 0,6. A martelada soa no sino privado do alto-falante. O golpe do lado bate em quem espera.

## O que se sabe fora

| quem | o que faz | o que ensina aqui | fonte |
| --- | --- | --- | --- |
| Returnal (Housemarque, 2021) | o L2 em dois estágios; a vibração cresce na recarga | o ponto de quebra do gatilho é uma decisão de jogo | blog da PlayStation, 01/04/2021 |
| Ratchet & Clank: Rift Apart (Insomniac, 2021) | cada arma tem o seu perfil de gatilho | a arma mora no gatilho | já no catálogo, a mágica 1 |
| Deathloop (Arkane, 2021) | a arma emperrada trava o gatilho | o gatilho também diz «não» | já no catálogo, a mágica 5 |

## O risco no Linux

1. **O tiro não sai no clique.** O jogo decide o tiro pelo eixo (0,6), não pelo clique que a mão sente no `ARMA`. Os
   dois podem cair em pontos diferentes do curso. O relatório cru traz a fase do Weapon nos bytes 41 e 42; o módulo
   não a expõe.
2. **A trava do Edge** encurta o curso: com a trava curta, o eixo pode parar abaixo de 0,6 e o tiro nunca sai.
3. **O simulador não escreve a fase do gatilho.** A prova sem controle só vê os 11 bytes pedidos.
4. **O rumble corta a háptica** (a suspeita (e) do 05): o golpe do lado no rumble apaga a háptica do mesmo controle.

## As mágicas, em ordem

### 1. O tiro sai no clique

- **Quem joga:** a besta dispara no instante em que a mão sente o clique, não num número escondido.
- **Os outros:** nada.
- **Os números:** o tiro na borda de subida da fase do Weapon (byte 41) ou, sem ela, no eixo 0,6.
- **Como se prova sem o controle:** pedir ao arquiteto que o simulador escreva a fase quando o eixo passa a zona de
  início do `ARMA` (2/9 do curso). O robô `robo_eixo(l, 0,7)` e a prova confere o tiro no quadro da fase.
- **O que falta:** a fase exposta e no simulador (o arquiteto).

### 2. A besta com o perfil da arma da build

- **Quem joga:** a besta tem o peso da arma que ele montou antes (a mágica 1).
- **Os outros:** nada.
- **Os números:** o `ARMA` da peça; o padrão 2,6,8.
- **Como se prova sem o controle:** `percepcao(l).gatilho_dir` com `[0]` = o modo da peça.
- **O que falta:** os perfis por peça (o designer de sistemas).

### 3. O limiar pelo maior curso alcançado

- **Quem joga:** com a trava do Edge, o tiro ainda sai.
- **Os outros:** nada.
- **Os números:** o limiar = 0,6 × o maior valor do eixo visto desde a conexão (no mínimo 0,3).
- **Como se prova sem o controle:** o robô vai só até `robo_eixo(l, 0,7)` por 10 batidas, depois até 0,7 de novo; a
  prova confere que o tiro sai em 0,42. Com `--defeitos=analogico-curto`, o mesmo.
- **O que falta:** nada no módulo.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a fase do Weapon (bytes 41 e 42) exposta e escrita pelo simulador | o arquiteto |
| os perfis de gatilho por peça | o designer de sistemas |
