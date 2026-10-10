# G11b — A pausa na prancha da noite

**Sprint:** G · **Tamanho:** P · **Depende de:** G11 (a pausa da fita, `Som.ui`, os objetos do `Desenho`), F09 (a prova
visual)

## Por quê

A [G11](G11-a-interface-com-o-ui-pack.md) entrou com a pausa da fita, a placa e o som dos menus, provados na prova do
jogo. A parte da prova visual ficou de fora: a G11 pede que a pausa não roube tempo da noite e que a prancha mostre o
J-card da pausa e a barra num quadro de cada sala. Isso mexe na prova visual (`godot/testes/prova_visual.gd`), que é
de outra frente na leva 1.

## Ler antes

- [G11, a diversão e as provas](G11-a-interface-com-o-ui-pack.md#a-diversão)
- [06, a pausa](../arte/06-interface-e-texto.md) (o J-card, a barra, o desbota)

## O estado de hoje

- `godot/testes/prova_visual.gd` não abre a pausa: o `_topo()` sabe desenhar a pausa (`"pausa": return jogo.pausa`),
  mas nenhum robô a abre. A prancha não tem nenhum quadro com o J-card da pausa.
- A pausa (`godot/scripts/ui/pausa.gd`) tira o cartão da coleta de texto enquanto ele entra (`dx > 0.5`): a coleta
  mede o cartão parado.
- A barra de pausa só aparece com `Opcoes.flashes` ligado.

## O que fazer

1. Na mesa padrão da prova visual (P1 `bom`, P2 e P3 `medio`, P4 `ruim`, semente 7), o robô do P4 abre a pausa uma
   vez por sala, 2 s depois do início do jogo, e escolhe Continuar.
2. Medir a janela: da abertura ao Continuar, no máximo 2 s; a sala volta no mesmo quadro do fechamento.
3. A prancha guarda um quadro com a pausa aberta em cada sala, e a checagem de texto passa nele (1,0× e 1,15×, em
   português e em inglês).
4. As pranchas de três telas com placa (HUD, resultado, opções) entram na lista que o jogador do time olha.

## Pronto quando

A prancha da noite mostra o J-card da pausa e a barra num quadro de cada sala, sem achado de texto, e a pausa do robô
dura no máximo 2 s.

## Provas

- `bash tests/prova_visual.sh` (com as partidas 5 e 6, as do texto grande).
- `bash tests/prova_do_jogo.sh` (as checagens da G11 seguem verdes).

## Armadilhas

- **A tela parada:** a checagem `tela_parada` já perdoa a pausa (`q.pausa = true`); a barra muda a cada quadro.
- **O ✕ do robô na pausa:** subir da primeira linha dá a volta para «Sair». O robô escolhe Continuar sem navegar.

## Não fazer

- Não mudar a pausa: o desenho é da G11.

## Ao terminar

Commit sugerido: `test(visual): a pausa da fita na prancha da noite`.
