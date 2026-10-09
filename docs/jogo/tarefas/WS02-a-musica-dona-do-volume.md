# WS02 — A música dona do volume

**Sprint:** W · **Tamanho:** M · **Depende de:** H07

## Por quê

A música reage ao jogo (a H07): o erro abafa, o perfeito abaixa 2 dB, o combo de oito sobe 1,5 dB por 2 s. Com quatro
jogadores tocando, as reações chegam a cada fração de segundo, e hoje cada uma apaga a anterior: o combo de um
jogador some no perfeito seguinte de qualquer outro, e o abafado do erro se abre no próximo acerto. E as fichas que
abaixam a música por motivo próprio (a pista da N1, o microfone da P1, a pausa e o cartão da bíblia) vão escrever no
mesmo barramento, cada uma com o próprio valor final: a primeira reação depois delas devolve a música a 0 dB.

A causa é uma só: o volume do barramento `Musica` não tem dono. Cada chamada escreve o valor final em vez de somar a
sua parte.

## Ler antes

- [H07 — O som em todo evento](H07-o-som-em-todo-evento.md) (o barramento e o `reagir`).
- [03 — O som, «O que abaixa quando»](../arte/03-som.md#o-que-abaixa-quando) (a tabela de cada motivo).
- `docs/jogo/tarefas/N1-o-canto.md:919-945` (o `abaixar_a_musica` e o `soltar_a_musica` da N1) e o trecho do
  `_tw_escuta` da P1 (`docs/jogo/tarefas/P1-a-voz.md`, perto da linha 130).

## O estado de hoje

- `godot/scripts/musica.gd:282-299`, o `reagir`:

  ```gdscript
  func reagir(evento: String) -> void:
  	if _tw_reacao:
  		_tw_reacao.kill()
  	_passa_baixa.cutoff_hz = ABERTO_HZ
  	_volume(0.0)
  	_tw_reacao = create_tween()
  	match evento:
  		…
  		"combo":
  			_volume(1.5)
  			_tw_reacao.tween_interval(2.0)
  			_tw_reacao.tween_method(_volume, 1.5, 0.0, 0.3)
  ```

  e `:302-303`, `_volume(db)` = `AudioServer.set_bus_volume_db(_bus, db)`, uma escrita absoluta.
- Quem chama: `godot/scripts/minigames/minigame.gd:272` (erro), `:283` (combo) e `:285` (perfeito), em todo toque
  julgado de qualquer lugar. Num minigame de ritmo com quatro, um combo a +1,5 dB dura até o próximo perfeito de
  alguém, uns 0,25 s, e não os 2 s.
- A N1 (pronta, não entrou) guarda o volume de base no primeiro abaixamento e escreve no barramento por conta própria
  (`N1-o-canto.md:926-937`): se a primeira pista cai durante um combo, a base fica em +1,5 dB para sempre; e o primeiro
  `reagir` durante a pista leva a música de −12 dB de volta a 0.
- A prova de hoje (`godot/testes/prova_do_jogo.gd:1548-1561`, `_prova_da_musica_que_reage`) dispara um evento de cada
  vez e espera ele acabar: o caso de dois eventos juntos nunca é medido.

## O alvo

A `Musica` é a única que escreve no barramento `Musica`, e o volume aplicado é a soma de camadas:

- a camada da reação (o `reagir`), com um tween dela;
- uma camada por motivo de abaixamento, `abaixar(motivo, db, entra_s, fica_s, volta_s)` e `soltar(motivo)`, cada uma
  com o seu tween;
- o volume aplicado é recalculado a cada quadro (no `_process` da `Musica`, que já roda sempre) como a soma das
  camadas; o passa-baixa segue a mesma regra, com o menor corte vencendo.

O combo de um não apaga o perfeito do outro: o perfeito mexe só na camada da reação, por cima do que estiver nela, sem
zerar o resto (o perfeito sobre um combo dá +1,5 − 2 = −0,5 dB por 80 ms, e volta a +1,5).

## Passos

1. `abaixar`, `soltar` e as camadas na `musica.gd`, com o `_process` que soma e aplica.
2. O `reagir` passa a mexer só na camada dele: o perfeito vira um desconto de 2 dB por 80 ms sobre a camada, o combo
   uma subida de 1,5 dB por 2 s, o erro um corte do passa-baixa em 600 Hz que abre em 300 ms. Um evento novo não mata
   o tween de outro tipo.
3. As fichas que abaixam a música passam a chamar a `Musica`: na N1, `abaixar_a_musica` vira
   `Musica.abaixar("pista", -12.0, 0.017, 60.0 / Ritmo.bpm, 0.3)` e `soltar_a_musica` vira `Musica.soltar("pista")`; na
   P1, o `_tw_escuta` sobre o volume do tocador vira `Musica.abaixar("microfone", -12.0, …)`. Editar as duas fichas
   (elas ainda não entraram).
4. A prova nova, ao lado da `_prova_da_musica_que_reage`.

## Armadilhas

- O `tocar` e o `tocar_do_zero` mexem no `volume_db` dos dois tocadores (o cruzamento), não no barramento: ficam como
  estão. O que é do barramento é só o que é de todos os tocadores ao mesmo tempo.
- O `_process` da `Musica` roda com `PROCESS_MODE_ALWAYS` (`musica.gd:42`): na pausa, as camadas continuam andando,
  e é o que a pausa da bíblia quer (−12 dB enquanto o jogo está parado).
- Os tweens andam no tempo do jogo: a prova espera em quadros, como a de hoje.
- O `parar_seco` do apito é do tocador, não do barramento: o barramento não muda no apito.

## Não fazer

- Não criar barramento novo aqui: os outros barramentos da bíblia são da WS01 (a H11).
- Não mudar os valores da reação (2 dB, 80 ms, 1,5 dB, 2 s, 600 Hz, 300 ms): são da bíblia.

## Pronto quando

`grep -rn 'set_bus_volume_db' godot/scripts` acha só a `musica.gd` e o volume da TV (`forja.gd:164`), e as duas
provas novas passam.

## Provas

- `bash tests/prova_do_jogo.sh`, com os dois casos novos:
  1. `Musica.reagir("combo")`, 15 quadros, `Musica.reagir("perfeito")`, 10 quadros: o barramento perto de +1,5 dB
     (hoje está em 0);
  2. `Musica.abaixar("pista", -12.0, 0.0, 1.0, 0.3)` e logo `Musica.reagir("perfeito")`: o barramento perto de −14 dB
     no quadro seguinte e perto de −12 dB dez quadros depois (hoje volta a 0).
- A `_prova_da_musica_que_reage` de hoje passa sem mudar.

## Para o André (local)

Jogar um minigame de ritmo com quatro e ouvir o combo: a música sobe e fica em cima os 2 s, mesmo com os outros
acertando.

## Ao terminar

Pôr a linha no [quadro](README.md) como **feito**, com o gasto, e dizer na N1 e na P1 que o abaixamento já é da
`Musica`.
