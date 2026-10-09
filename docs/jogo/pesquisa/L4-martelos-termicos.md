# L4 — Martelos Térmicos: a pesquisa do DualSense

Ficha: [L4](../tarefas/L4-martelos-termicos.md). Seção: [L — O Impacto](../tarefas/L-o-impacto.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **O lado quente** se diz por um motor só (`golpe_esq` ou `golpe_dir`). **As duas quentes** são `explosao`
  1,0·1,0: martelar L1 e R1 juntos (a até 0,12 s, `JUNTOS_S`) vale 150 (`DUPLA`).
- **A queimadura** (martelar o lado frio) é `golpe` por 300 ms (`QUEIMA_MS`); o fantasma vale −20.
- A diversão pediu **a revelação do quente e do frio depois da martelada**.
- Sala da prova: `S04_J19`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Mario Party 5, «Rumble Fumble» (2003) | o padrão do tremor decide o balde; errar solta uma bomba | `mariowiki.com/Rumble_Fumble` |
| Super Mario Party, «Rattle and Hmmm» (2018) | força, pausa, estilo e duração do tremor como identidade | `mariowiki.com/Rattle_and_Hmmm` |
| Spider-Man: Miles Morales (2020) | o estalo que cruza da esquerda para a direita | Push Square, agosto de 2020 |
| Astro's Playroom (2020) | os pés alternando os lados | catálogo, seção 3 |
| Everybody 1-2-Switch, «Joy-Con Hide & Seek» (2023) | achar pelo tremor; no Joy-Con 2, mais silencioso, ficou mais difícil | Nintendo Life, maio de 2025 |

## O risco no Linux

1. **"Um lado" contra "os dois lados" se confunde.** Com os dois atuadores a 1,0, o tremor atravessa a carcaça e a mão
   não separa "um forte" de "dois fortes" com folga. É o risco central deste jogo. **Medir na bancada:** 20 pistas às
   cegas, misturando um lado e os dois; acerto mínimo de 18.
2. **O firmware abaixo de 0x0224** divide o rumble: a queimadura de 300 ms fica com metade da força.
3. **Dois donos do motor**: igual ao [L1](L1-o-cerco.md).
4. **O SDL corta a háptica por áudio sob rumble**: se a revelação usar som nos canais 3 e 4, ela some durante a
   queimadura.

## As propostas

### 1. As duas quentes vão e voltam (para quem joga)

- **Quem joga:** "as duas quentes" deixam de ser só força e viram **ritmo**: 60 ms na esquerda, 60 ms na direita,
  60 ms na esquerda, 60 ms na direita (240 ms, 8 Hz de troca). "Um lado" continua um pulso de 120 ms parado. O
  vaivém se distingue do pulso parado mesmo quando o lado se mistura na mão.
- **Os outros:** nada a mais.
- **De onde veio:** o estalo que atravessa do Venom Punch; o «Rattle and Hmmm» (o estilo do tremor como nome).
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S04_J19`. O robô lê a sequência de
  `percepcao(l)`: alternância `forte`/`fraco` em 4 quadros de 60 ms é "as duas"; um lado parado é "uma". O registro
  cruza `pista` (uma ou duas) com `toque` (L1, R1 ou os dois juntos) em pelo menos 95%. **A que morde:**
  `--defeitos=engasga` atrasa os relatórios e quebra o vaivém; o acerto cai.
- **Na bancada:** a medida do risco 1, agora com o vaivém; meta de 18 em 20.

### 2. O metal responde depois da martelada (a revelação, para todos)

- **Quem joga:** martelou o quente → `golpe` do lado martelado, 50 ms (o metal soa); martelou o frio → a queimadura
  de 300 ms que a ficha já tem. Errar e acertar ficam com durações diferentes: 50 contra 300 ms.
- **Os outros:** a bigorna do dono fica laranja (quente) ou azul (frio) por 0,5 s depois da martelada; é a revelação
  que a diversão pediu. A cor é da arte; o tempo de 0,5 s é proposta.
- **Como se prova:** o registro tem, depois de cada `toque`, uma `sensacao` de 50 ms (quente) ou 300 ms (frio), e um
  evento `revelou` com o lado e a cor. Com `--robo=ruim`, as de 300 ms são a maioria.

### 3. O lado de cada controle se acerta na bancada (para quem joga)

- **Quem joga:** se a bancada medir que um controle tem os lados trocados (o defeito `motores-trocados` existe no
  simulador porque acontece), a Forja guarda isso por controle e inverte o lado no envio. Ninguém precisa saber.
- **Como se prova:** `--defeitos=motores-trocados` com a inversão ligada: o acerto do robô volta a 95%.
- **Fica com quem:** o arquiteto (onde se guarda a inversão por controle). Não é desta seção.

## O que preciso de outras cabeças

- **Diretor de jogo:** a revelação (proposta 2), as cores e o 0,5 s.
- **Arquiteto:** a inversão de lado por controle (proposta 3), se a bancada achar algum controle trocado.
