# L2 — Fuga do Titã: a pesquisa do DualSense

Ficha: [L2](../tarefas/L2-fuga-do-tita.md). Seção: [L — O Impacto](../tarefas/L-o-impacto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O passo do titã** só no motor forte (o esquerdo) diz de quem é a vez de cavar.
- **R2 é a pá.** O L2 é do item (G03).
- **A ordem embaralha aos 33 s.**
- A luz é a vida (brilho de 40% a 100%, a cor do lugar). Distância inicial 0,6 (`DISTANCIA_INICIAL`), o titã avança
  0,045 a 0,065 por falha (`AVANCO`), a grade dá 0,02.
- Sala da prova: `S04_J17`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Subnautica: Below Zero (Unknown Worlds, 2021) | o detector de metal vibra pelo lado do alvo, e a barra de luz pulsa mais rápido perto | blog da PlayStation, apanhado de estúdios, 2020, `blog.playstation.com/?p=349044` |
| Alien: Isolation, PS4 (Creative Assembly, 2014) | a barra de luz pisca junto do detector, mais rápido com o alien perto | Gary Napper a Stevivor, 2014; Game Informer, 26/03/2014 |
| Super Mario Party, «Rattle and Hmmm» (Nintendo, 2018) | o tremor tem força, pausa e duração que se reconhecem | `mariowiki.com/Rattle_and_Hmmm` |
| Deathloop (Arkane, 2021) | o gatilho trava quando a arma emperra | KitGuru («the dualsense triggers will lock up when your weapon jams») |
| Gran Turismo 7 (Polyphony, 2022) | o ABS pulsa no gatilho do freio | GTPlanet, `gtplanet.net/gt7-dualsense-feel-abs-20200821` (Kazunori Yamauchi no blog da PlayStation, agosto de 2020) |

## O risco no Linux

1. **Um motor só é menos que um lado.** O passo vai só no forte; no DualSense o forte é o atuador esquerdo, e o
   tremor atravessa a carcaça (o mesmo risco do [L1](L1-o-cerco.md)). Aqui o que importa é "vibrou ou não", não o
   lado, então o risco é menor: medir na bancada se o passo de 0,4 se sente em 20 de 20.
2. **O firmware abaixo de 0x0224** divide o rumble por 2 no SDL; um passo de 0,4 vira 0,2. Registrar o firmware.
3. **O gatilho da pá** passa pelo relatório 0x02 do módulo; o `hid-playstation` não tem interface de gatilho. O
   Steam Input pode comer o meio curso (catálogo). A pá nunca exige 100% de curso (o Edge trava antes).

## As propostas

### 1. O passo que se aproxima (para quem joga)

- **Quem joga:** a força do passo cresce com a proximidade do titã. Distância 0,6 → forte 0,4; distância 0 → forte
  1,0; reta entre os dois (`forte = 1,0 − distância`). O passo dura 90 ms, sempre na batida. Sem olhar, a mão sabe
  se o titã está perto.
- **Os outros:** a barra de luz de quem tem a vez pisca no passo (100% por 80 ms); a sala vê de quem é a vez.
- **De onde veio:** o detector do Subnautica: Below Zero e o do Alien: Isolation (mais perto, mais forte e mais
  rápido).
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S04_J17`. O robô cava quando
  `percepcao(l)["forte"] > 0`. O registro guarda o `forte` mandado e a distância a cada passo; a prova confere
  `forte = 1,0 − distância` com erro de 0,02. **A que morde:** `--defeitos=motores-trocados` põe o passo no `fraco`;
  o robô não cava e o titã alcança.

### 2. A pá que morde (para quem joga)

- **Quem joga:** na vez dele, o R2 vira `Weapon` (início 3, fim 6, força 5): a pá encontra a terra e estala no meio
  do curso. Fora da vez, R2 em Off. Uma pá por estalo, como o tiro do Deathloop trava e solta.
- **Os outros:** veem a terra voar.
- **Os números:** início 3 e fim 6 ficam no meio do curso (nunca 100%, por causa do Edge).
- **Como se prova:** o robô da seção lê `percepcao(l)["gatilho_dir"]`. Na vez: 0x25; fora: 0x05. A prova conta, por
  lugar, que 0x25 só aparece nas batidas em que o registro marca a vez dele. Com `--defeitos=gatilho-mudo`, o byte
  fica 0x05 e a prova acusa. A força 5 só se prova com o bloco inteiro de 11 bytes (pedido ao arquiteto, abaixo).

### 3. A troca da ordem se sente (para todos)

- **Todos:** aos 33 s, quando a ordem embaralha, cada controle recebe dois `aviso` de 80 ms com 80 ms de folga. "Dois
  toques" quer dizer "a ordem mudou", e ninguém precisa olhar a tela para saber.
- **Como se prova:** o registro tem duas `sensacao` `aviso` por lugar, a 160 ms uma da outra, aos 33 s de música.
  Com `--robo=bom`, a primeira vez depois da troca não pode ter mais falhas que a média das outras vezes.

## O que preciso de outras cabeças

- **Arquiteto:** expor o bloco inteiro do gatilho (11 bytes) na `percepcao`; hoje
  `nativo/godot/forja_controles.cpp:569` só dá o byte `[0]`, e o `Percepcao` do `simulador.h` já guarda os 11.
- **Diretor de jogo:** se a pá muda para Weapon (proposta 2), a ficha muda; é decisão dele.
