# M1 — A Galeria: a pesquisa do DualSense

Ficha: [M1](../tarefas/M1-a-galeria.md). Seção: [M — A Galeria](../tarefas/M-a-galeria.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O R2 é a arma:** `Weapon` (início 2, fim 6, força 8), o estalo no meio do curso. Só o R2; o L2 é do item (G03).
- **Seis balas** (`BALAS`). Vazia, o R2 vai a **Off** e o tiro é um clique seco. **□ recarrega.**
- Os limiares da seção: `R2_CLIQUE` 0,62, `R2_APERTA` 0,5, `R2_SOLTA` 0,2.
- O robô da seção lê só `percepcao["gatilho_dir"]`, o byte do modo.
- A diversão pediu **um alvo dourado no fim, de todos** (`DOURADO` vale 2×).
- Sala da prova: `S05_J21`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Ratchet & Clank: Rift Apart (Insomniac, 2021) | cada arma tem o seu gatilho; meio curso e curso inteiro são dois tiros | catálogo (blog da PlayStation; tópicos da Steam sobre o Steam Input) |
| Call of Duty: Black Ops Cold War (Treyarch, 2020) | cada arma afinada uma a uma no DualSense; o gatilho treme | KitGuru, «every weapon in Black Ops Cold War is tuned differently for DualSense» |
| Deathloop (Arkane, 2021) | o gatilho trava quando a arma emperra | KitGuru; catálogo, mágica 5 |
| Returnal (Housemarque, 2021) | o L2 em dois estágios | Android Central, «Returnal for PS5 is a magnificent DualSense showcase»; GamingTrend |
| 1-2-Switch, «Ball Count» (Nintendo, 2017) | contar pelo tato | catálogo, mágica 6 |
| The Legend of Zelda: Twilight Princess, Wii (2006) | a corda do arco soa no alto-falante do controle e o impacto na TV | prévia da E3 2006, Nintendo World Report (prévia 12096); WhatCulture, «9 Times The Wii Remote Speaker Actually Improved Gameplay» |

## O risco no Linux

1. **O `hid-playstation` não tem interface de gatilho.** O efeito sai só pelo relatório 0x02 do módulo (o CONTRATO).
2. **O Steam Input pode comer o meio curso** (catálogo; o caso do Ratchet). Com o Steam Input ligado, o Weapon
   pode ser reescrito.
3. **Dois donos do relatório:** se o SDL do Godot abrir o controle e mandar o 0x02, o bloco do R2 de um apaga o do
   outro. O módulo tem que ser o único a mexer nos bits de validade do gatilho.
4. **O Edge trava antes do fim:** o fim 6 não exige 100% de curso; o `R2_CLIQUE` 0,62 também não.
5. **A bateria:** gatilho e háptica levam de 20% a 40% da carga, nas estimativas sem método medido que achei
   (The Controller People; a calculadora da West Games). É estimativa, não medida.

## As propostas

### 1. O tambor que se conta no dedo (para quem joga)

- **Quem joga:** a força do Weapon cai com as balas: 8, 8, 8, 8, 6 e 4. As duas últimas balas são mais leves. Sem
  olhar, o dedo sabe que está acabando, e o □ vem antes do clique seco.
- **Os outros:** nada.
- **De onde veio:** o «Ball Count» (contar pelo tato); cada arma do Black Ops Cold War com o seu peso.
- **Como se prova sem o controle:** o modo continua 0x25 nas seis; **a força só se prova com o bloco inteiro de 11
  bytes** (pedido ao arquiteto). Até lá, o registro grava a `saida` de gatilho com a força a cada tiro, e a prova lê
  a sequência 8, 8, 8, 8, 6, 4 no registro. **A que morde:** com `--defeitos=gatilho-mudo`, a `percepcao` mostra 0x05
  enquanto o registro diz 0x25, e a prova acusa.

### 2. O clique seco no ouvido de quem atira (para quem joga)

- **Quem joga:** com a arma vazia (R2 em Off), o tiro toca `clique` (20 ms) no alto-falante do dono, volume 0,7. O
  vazio se sente (o R2 frouxo) e se ouve na mão, não na TV.
- **Os outros:** não ouvem; o alto-falante é dele.
- **De onde veio:** o Twilight Princess (o som do arco no controle).
- **Como se prova:** `Forja.som_virtual(l)` traz o `falante` acima de 0 e o último som `clique` só para quem atirou
  vazio. Com `--defeitos=som-vizinho`, o clique sai no lugar errado e a prova acusa; com `sem-alto-falante`, o
  registro diz `no_controle: false` e o clique vai à TV a −10 dB.

### 3. O dourado pesa em todos (para todos, pedida pela diversão)

- **Todos:** quando o alvo dourado sobe no fim, o R2 de todos vira `Weapon` (início 4, fim 7, força 8): o estalo vem
  mais fundo, o tiro especial pede mais curso. Quem acerta primeiro leva os 2×.
- **Os outros:** veem o ouro e sentem a mesma arma mudar; é uma corrida.
- **Como se prova:** no alvo dourado, `percepcao(l)["gatilho_dir"]` é 0x25 em todos; o registro grava início 4 e
  fim 7. O fim 7 fica abaixo de 100% de curso (o Edge).

## O que preciso de outras cabeças

- **Arquiteto:** os 11 bytes do gatilho na `percepcao` (sem eles, a força das propostas 1 e 3 só se confere no
  registro, não no que o controle recebeu).
- **Designer de sistemas:** a curva de força por bala (8, 8, 8, 8, 6, 4) é perfil de arma; é dele.
- **Diretor de som:** o `clique` no alto-falante da Galeria (a seção M hoje não usa o alto-falante).
