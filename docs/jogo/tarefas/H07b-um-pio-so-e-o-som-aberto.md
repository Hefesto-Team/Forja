# H07b — Um pio só, e o alto-falante do controle aberto

**Sprint:** H · **Tamanho:** P · **Depende de:** H07, G01, G02

## Por quê

A costura do o-cavaleiro com o o-kit (09/10/2026) juntou dois desenhos de som de entrada que não conversam:

- **Dois pios na entrada.** O H07 toca o pio sintetizado `pio:%d` no alto-falante de quem entrou
  (`godot/scripts/main.gd`, `_abrir_o_som`); a G01 e a G02 tocam o pio gravado `Som.pio` (`main.gd` no título e
  `godot/scripts/ui/tela_lobby.gd`). O alto-falante toca um som por vez, então o gravado substitui o sintetizado no
  mesmo quadro: funciona por acaso, e cada um dos dois desenhos acha que é o dono.
- **O alto-falante fecha ao sair da construção.** O `main.gd` chama `Forja.som_encerrar()` ao sair do título e da
  construção («o alto-falante dos controles era só do pio») e o reabre a cada volta ao salão. O H07 quer o
  alto-falante aberto do lobby até o fim da noite, porque todo evento toca no controle.

## Ler antes

- [H07 — o som em todo evento](H07-o-som-em-todo-evento.md#o-que-foi-feito-leva-1-o-kit)

## O alvo

1. **Um pio só:** o gravado (`Som.pio`, o arquivo do mapa do áudio), tocado por um caminho só, o do H07
   (`_abrir_o_som` e o `Forja.som_falante`). O pio sintetizado sai, ou fica só como reserva quando o arquivo falta.
2. **Um dono só do alto-falante:** o `_abrir_o_som` abre uma vez quando o primeiro controle senta e fecha só no fim da
   noite ou quando o controle sai. Nenhuma tela fecha o alto-falante por conta própria.

## Pronto quando

- A prova do jogo confere, para cada lugar que entra, **um** pio no alto-falante do dono, o gravado, e nenhum
  outro som no mesmo quadro.
- A prova confere que o alto-falante de cada lugar continua aberto do título até o pódio (o `som_encerrar` não é
  chamado entre as telas).
- A mordida: devolver o pio sintetizado ou o `som_encerrar` na saída da construção, e ver a prova reprovar.

## Provas

- `bash tests/prova_do_jogo.sh` (pelo semáforo).

## Para o André (local)

Com os quatro DualSense: cada um entra e ouve **um** pio no próprio controle; depois, sem nenhum silêncio de troca de
tela, o tique da construção e o primeiro som da sala saem no controle.
