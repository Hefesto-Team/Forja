# WO02 — O boneco liso numa tela acima de 60 Hz

**Sprint:** W · **Tamanho:** M · **Depende de:** — (mexe em `main.gd` e `player.gd`: não voar junto com uma ficha G
que esteja nesses arquivos)

## Por quê

O boneco anda no `_physics_process`, a 60 passos por segundo, e a tela desenha na taxa do monitor. Numa TV ou monitor
de 60 Hz as duas batem e ninguém vê nada, que é o caso desta casa. Num monitor de 144 Hz, cada passo fica na tela por
dois ou três quadros, e o andar sai em degraus: medido na caixa, a posição desenhada repete em 168 de 288 quadros
(58 %). A 75 Hz, uns 20 %. É defeito de quem joga em outro PC, e o motor já tem a cura pronta, a interpolação de
física, que está desligada.

## Ler antes

- A documentação do motor sobre a interpolação de física (`physics/common/physics_interpolation`,
  `Node.physics_interpolation_mode`, `Node.reset_physics_interpolation()`,
  `Node3D.get_global_transform_interpolated()`).
- [WJ — o mapa das salas](../revisao/WJ-mapa.md) (quem move o boneco em cada estado)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `godot/project.godot`: nenhuma chave de física; a interpolação fica no padrão (desligada).
- O andar livre, `godot/scripts/player.gd:211-225`:
  ```gdscript
  func _physics_process(dt: float) -> void:
  	...
  	if preso:
  		velocity = Vector3.ZERO
  		return
  	var mv := Forja.mover(lugar) if controlavel else Vector2.ZERO
  	...
  	move_and_slide()
  ```
- Dentro das salas, o boneco é posto pela sala a cada quadro, no `_process`: `godot/scripts/salas/viga.gd:552`
  (`p.position = pos`, chamado do `_process` de `:535`); as outras salas o posicionam na entrada
  (`molde.gd:122`, `voz.gd:219`, `canto.gd:234`, `impacto.gd:172`, `caminhos.gd:205`,
  `minigames/s01/martelo_de_hefesto.gd:75`).
- Os saltos: `godot/scripts/main.gd:316` (a volta ao salão, `p.global_position = volta`), `:219` e `:231` (os
  pedestais) e o pódio por tween, `:494`
  (`tw.tween_property(jogadores[l], "global_position", ...)`, no `_process` do tween).
- A câmera anda no `_process`, `godot/scripts/main.gd:1055-1062`, e no salão enquadra quem joga lendo a posição
  dos bonecos (`_pose_da_camera`, `:1017` em diante).

## O alvo

No salão e no lobby, o boneco que anda pela física é desenhado interpolado, em qualquer taxa de tela. Tudo o que se
move no `_process` (a câmera, as salas, os tweens) continua como hoje, sem um quadro de atraso. Nada muda na tela de
60 Hz.

## Arquivos que mudam

- `godot/project.godot` (`physics/common/physics_interpolation=true`)
- `godot/scripts/main.gd` (o modo da raiz, os saltos, a câmera)
- `godot/scripts/player.gd` (o modo do boneco segue o `preso`)
- `godot/testes/prova_do_jogo.gd` ou um bench novo em `godot/testes/` (a prova)

## Passos

1. Ligar a interpolação no projeto e, no `main.gd`, pôr `physics_interpolation_mode = OFF` na raiz da cena: tudo
   herda desligado, e nada que se move no `_process` muda de comportamento.
2. No `player.gd`, o boneco liga o modo `ON` só quando anda pela física (não `preso`) e volta a `OFF` quando a sala
   o prende; a cada troca, `reset_physics_interpolation()`.
3. Nos saltos (`main.gd:219`, `:231`, `:316`) e no fim do tween do pódio, `reset_physics_interpolation()` no boneco,
   para ele não deslizar da origem ao destino.
4. A câmera do salão enquadra pela posição interpolada (`get_global_transform_interpolated().origin`), e não pela
   `global_position`, que é a do passo de física.
5. A prova: um bench headless na caixa com `--max-fps 144`, o boneco andando 2 s; conta os quadros em que a posição
   desenhada (a interpolada) é igual à do quadro anterior.

## Armadilhas

- **Ligar no projeto sem a raiz em `OFF`** faz tudo o que as salas movem no `_process` chegar um quadro atrasado e
  tremido. A ordem do passo 1 é a cura, não um detalhe.
- **A câmera que lê `global_position`** de um boneco interpolado treme: ela enxerga o passo, não o desenho.
- **O teleporte sem reset** desenha o boneco no meio do caminho por um quadro.
- **O headless** não tem monitor: a prova mede pelo `--max-fps`, com o `--fixed-fps` desligado nessa rodada.

## Não fazer

- Não subir a taxa da física para a do monitor: muda o andar e o pulo de todo mundo.
- Não mover o boneco das salas para o `_physics_process`.
- Não ligar a interpolação nas salas: elas já desenham por quadro.

## Pronto quando

No bench a 144 quadros, a posição desenhada repete em no máximo 5 % dos quadros (hoje, 58 %), e depois do salto de
`main.gd:316` nenhum quadro desenha o boneco entre a origem e o destino. A 60 quadros, as provas seguem iguais.

## Provas

- O bench novo (pela caixa da WE01, pelo semáforo da máquina).
- `bash tests/prova_do_jogo.sh` e `bash tests/prova_de_poucos.sh` verdes.
- `bash tests/prova_visual.sh` sem achado novo de disposição.

## Para o André (local)

Num monitor acima de 60 Hz, se tiver: andar com o boneco no salão antes e depois. O passo em degraus some. Num de
60 Hz, nada muda; conferir que o salto para a sala e a volta ao salão não deixam rastro.

## Ao terminar

Pôr a linha da WO02 no [quadro](README.md) como **feito**, com o commit, e anotar no 13 a regra «quem anda pela
física liga a interpolação; quem anda por quadro, não».
