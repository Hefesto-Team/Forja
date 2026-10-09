# I1, O Martelo de Hefesto: a pesquisa do DualSense

Slot S01_J01 · ritmo em hoqueto · o verbo é **bater no tempo da própria nota**. A
[ficha](../tarefas/I1-o-martelo-de-hefesto.md), a [diversão](../diversao/I-a-centelha.md) e o
[catálogo](dualsense.md#1-os-gatilhos-adaptativos).

## O recurso

- **Os botões da runa**, em hoqueto de colcheias: o lugar `l` bate em `2k + 0,5·l` tempos.
- **O círculo do analógico** até a borda 0,85, cravado com L3 ou R3.
- **O fole no R2.** A faixa vai de 35 a 62 % do curso, com `FEEDBACK` zona 3 e força 4
  (`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 3, 4)`); afundar vai até 92 %.
- 6 golpes fazem uma espada. O grito: a espada racha no quinto golpe.

## O que se sabe fora

| jogo ou projeto | a técnica | a fonte |
| --- | --- | --- |
| Kingdom Come: Deliverance II (2025) | a forja com marteladas no ritmo, faísca no acerto e o metal branco de quente | [Destructoid](https://www.destructoid.com/kingdom-come-deliverance-2-blacksmithing-guide-and-tips/), [Loot Level Chill](https://lootlevelchill.com/guides/kingdom-come-deliverance-2-how-to-blacksmith/) |
| Hi-Fi Rush, versão de PS5 (2024) | a háptica refeita como parte da música; uma resenha achou a versão de PC melhor | [TechRadar](https://www.techradar.com/gaming/hi-fi-rush-review), [SI.com](https://videogames.si.com/reviews/hi-fi-rush-ps5-review) |
| Astro Bot (2024) | a esponja que se espreme pelo gatilho adaptativo, um protótipo citado pelo diretor | [TechRadar](https://www.techradar.com/gaming/consoles-pc/team-asobi-says-astro-bot-will-push-the-dualsense-controller-to-a-new-level) |
| o gerador do Nielk1 (rev. 6) | o `FEEDBACK` tem zona de 0 a 9 e força de 0 a 8, ativo da zona até a 9 | [gist](https://gist.github.com/Nielk1/6d54cc2c00d2201ccb8c2720ad7538db), MIT |

O gist não diz a que valor do eixo cada zona corresponde. A ficha supõe a zona 3 em 35 %. Não há medida.

## O risco no Linux

1. **A zona contra o eixo.** Se a zona 3 começa em 30 % e não em 35 %, a parede chega 5 pontos antes da faixa. Medir na
   bancada F01: para cada zona de 0 a 9, o valor do eixo em que a parede começa, em 3 controles.
2. **A trava do Edge** corta o fim do curso. Com a trava no meio, os 92 % não chegam e o golpe nunca afunda. O PID
   `0x0DF2` já é reconhecido; o aviso da trava falta (o catálogo).
3. **O clique do analógico na borda.** Cravar L3 a 0,85 faz o polegar escorregar: o eixo pode cair para 0,7 no quadro
   do clique. Julgar a borda pelo maior valor dos últimos 50 ms, não pelo quadro do clique. Medir: o eixo nos 3 quadros
   antes do clique, em 50 cliques.
4. **A latência da háptica por áudio.** O quantum padrão do PipeWire é 1024 a 48 kHz, cerca de 21 ms
   ([pipewire.conf](https://docs.pipewire.org/page_man_pipewire_conf_5.html)), mais que o quadro de 16,7 ms do pilar 5.
   O rumble por HID chega antes. Medir: o atraso entre `som_haptica` e `vibrar` no mesmo quadro.

## As mágicas

### 1. O metal responde na mão (`usa`)

- **Quem joga:** cada golpe certo é um pulso de 150 Hz (o metal da [bíblia de som](../arte/03-som.md)) por 30 ms, no
  atuador do lado do botão: ✕ e □ à esquerda, ○ e △ à direita. O tinido sai do alto-falante do dono no mesmo quadro.
- **Os outros:** ouvem o tinido vir da mão de quem bateu. Em hoqueto, o som corre a roda.
- **Como se prova:** o robô faz `Forja.robo_apertar(l, Forja.CRUZ)` em `2k + 0,5·l`; `Forja.som_virtual(l).esq`
  tem energia e `.dir` não; `.falante` passa de 0,3. Reprovam: `haptica-trocada`, `som-vizinho` e `troca-cruz-circulo`.

### 2. A espada racha no quinto golpe (`usa`)

- **Quem joga:** no quinto golpe, o R2 cede. A resistência sai (`GATILHO_OFF`) por 1 tempo e volta. O dedo afunda no
  vazio, e um estalo duplo de 150 Hz, 12 ms, pausa de 30 ms, 12 ms, marca a rachadura.
- **Os outros:** veem a espada rachar no mesmo quadro e ouvem o estalo no controle do dono.
- **Como se prova:** `Forja.percepcao(l).gatilho_dir` passa de `0x21` (o byte do `FEEDBACK`) para `0x05` (o `OFF`) e
  volta em 1 tempo. Reprovam: `gatilho-mudo` e `gatilho-digital`. Hoje a prova só vê o byte do modo, não a zona.

### 3. O metrônomo do hoqueto (`usa`)

- **Quem joga:** a mágica 3 do catálogo, só nas colcheias do dono: 80 Hz por 30 ms em `2k + 0,5·l`, ganho 0,35. A mão
  sabe a vez sem olhar a tela.
- **Os outros:** os quatro controles pulsam em roda.
- **Como se prova:** o robô não aperta nada; `Forja.som_virtual(l)` tem picos só nos tempos `2k + 0,5·l`, nunca
  nos dos outros. Reprovam: `haptica-muda` e `som-vizinho`.

## O que fica em aberto, e de quem

| o quê | de quem |
| --- | --- |
| a tabela zona → eixo (0 a 9) nos dois gatilhos | a bancada F01 |
| expor os 11 bytes do gatilho em `percepcao` (o simulador já guarda em `perc.gatilho_dir`), para a prova ver zona e força | o arquiteto |
| o aviso da trava do Edge antes do minigame | o arquiteto |
| o pulso de 150 Hz por 30 ms e o estalo duplo na bíblia de háptica | o diretor de som e háptica |
</content>
</invoke>
