# I3, Portões de Néon: a pesquisa do DualSense

Slot S01_J03 · ritmo de um botão · o verbo é **passar no instante em que o portão bate**. A
[ficha](../tarefas/I3-portoes-de-neon.md), a [diversão](../diversao/I-a-centelha.md) e o
[catálogo](dualsense.md#3-o-metrônomo-na-mão).

## O recurso

- **O ✕**, em hoqueto de semínimas: o lugar `l` passa em `4c + l` tempos.
- **O aviso tátil** meio tempo antes: `sentir(l, "aviso", 30000/bpm ms)`, do kit H04. A 120 bpm, o aviso vem 250 ms
  antes. No pico, não há aviso.
- A meta são 40 portões. O grito: a panqueca.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Bit.Trip Runner (2010) | os obstáculos são a partitura; cada pulo é uma nota | [Destructoid](https://www.destructoid.com/reviews/review-bit-trip-runner/), [Nintendo World Report](https://www.nintendoworldreport.com/review/23135/bittrip-runner-wii) |
| Rhythm Heaven (DS, 2008) | as batidas de entrada vêm antes de pedir; o jogo ensina pelo ouvido | [devlog no itch.io](https://peaceful-illumination.itch.io/rhythm-cataclysm/devlog/168773/getting-back-into-development-rhythm-heaven-breakdown-rc-devlog-1), [MobyGames](https://www.mobygames.com/game/40335/rhythm-heaven/) |
| Hi-Fi Rush, versão de PS5 (2024) | a háptica refeita como parte da música | [TechRadar](https://www.techradar.com/gaming/hi-fi-rush-review) |

O Rhythm Heaven tira o aviso quando o jogador já aprendeu o padrão. É o mesmo desenho do pico sem aviso.

## O risco no Linux

1. **O aviso atrasa.** A háptica por áudio passa pelo quantum do PipeWire: 1024 a 48 kHz, cerca de 21 ms
   ([pipewire.conf](https://docs.pipewire.org/page_man_pipewire_conf_5.html)). A 120 bpm o aviso tem 250 ms de folga;
   21 ms são 8 % dela. Acima de 180 bpm (166 ms de folga), o atraso passa de 12 %. Medir na bancada: o atraso entre
   o pedido e o pico no atuador, com o quantum 1024 e com 256.
2. **O SDL corta a háptica por áudio sob rumble.** Se a panqueca usa o motor forte, o aviso do portão seguinte some
   enquanto o motor vibra. A panqueca dura 80 ms; o próximo aviso do mesmo lugar vem 4 tempos depois. Não colide se o
   rumble parar a tempo.
3. **O ✕ trocado** pelo Steam Input. O defeito `troca-cruz-circulo` cobre isso.

## As mágicas

### 1. O aviso só na mão do dono (`usa`)

- **Quem joga:** meio tempo antes do portão dele, um pulso de 80 Hz por 30 ms, ganho 0,35, nos dois atuadores. No
  pico, o pulso some e ele bate de memória.
- **Os outros:** não sentem nada no controle deles; veem a mão do dono ir ao ✕ antes do portão acender.
- **Como se prova:** o robô não aperta; `Forja.som_virtual(l)` tem pico em `4c + l − 0,5` tempos e nada nos tempos
  dos outros lugares; no pico, nenhum pico. Reprovam: `haptica-muda` e `som-vizinho`.

### 2. A panqueca (`usa`)

- **Quem joga:** errar o portão achata o cavaleiro. O motor forte vai a 1,0 por 80 ms e um «plof» sai do alto-falante
  do dono.
- **Os outros:** veem a panqueca e ouvem o «plof» vir da mão certa. É o riso da seção.
- **Como se prova:** o robô aperta 200 ms depois do portão; `Forja.percepcao(l).forte` vai a 1,0 por 80 ms e volta a
  0; `Forja.som_virtual(l).falante` passa de 0,3. Reprovam: `motores-trocados` e `sem-alto-falante`.

### 3. O portão passa pela mão (`usa`)

- **Quem joga:** no acerto, a háptica corre da esquerda para a direita em 120 ms: 60 ms no esquerdo, 60 ms no direito.
  O portão atravessa o controle. É a mágica 9 do catálogo, curta.
- **Os outros:** veem o cavaleiro atravessar no mesmo quadro.
- **Como se prova:** o robô acerta; `Forja.som_virtual(l).esq` sobe antes de `.dir`, 60 ms de distância, com
  tolerância de 1 quadro. Reprova: `haptica-trocada`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| o atraso da háptica com o quantum 1024 e 256 | a bancada F01 |
| o pulso «aviso» de 80 Hz por 30 ms e o corrido de 120 ms na bíblia de háptica | o diretor de som e háptica |
| baixar o quantum na sala de jogo, se a medida passar de 16,7 ms | o arquiteto |
</content>
</invoke>
