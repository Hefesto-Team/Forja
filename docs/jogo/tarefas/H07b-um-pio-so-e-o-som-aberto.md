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

## O que foi feito (leva 1, o-kit-2)

**A medida antes.** Na base, cada entrada tocava dois sons no alto-falante do dono no mesmo quadro: o sintetizado
`pio:%d` do `_abrir_o_som` e o gravado `pio_p<N>_<intervalo>` do `Som.pio` (o do título e o da `tela_lobby.gd`). O
gravado ganhava porque vinha depois. A placa dos controles fechava duas vezes até o pódio, uma ao sair do título e
outra ao sair da construção, e o `salao` a reabria a cada volta.

**A cura, um caminho só:**

- O `Som.pio` toca o gravado na TV e chama o `pio_no_controle`. Esse método manda o gravado do mapa do áudio
  ao alto-falante do dono e só usa o sintetizado `pio:%d` quando o arquivo falta.
- O `_abrir_o_som` chama o `Som.pio`, e ele é o único pio da entrada. A `tela_lobby.gd` não toca mais o pio no
  `entrou`, e o título não toca outro pio no quadro em que o controle se senta.
- No lobby, o `lobby.entrou(l)` veste o cavaleiro antes do `_sincronizar_jogadores`. Assim o pio do `_abrir_o_som`
  é o da cabeça escolhida, e não o da cabeça de antes.
- O `main.gd` não chama mais o `som_encerrar` ao sair do título nem da construção. O `salao` só prepara a placa
  quando ela não está pronta. O `Forja.som_encerrados` conta os fechamentos, para a prova.

**As checagens novas na `prova_do_jogo.gd`:**

- O P1 se senta no título e recebe um som só no controle, o `pio_p1_`.
- Cada lugar que entra no lobby recebe um som só no controle dele, o `pio_p<N>_`.
- A placa não fecha do título à construção, e o `som_encerrados` é 0 no pódio.
- O registro conta os pios gravados e reprova qualquer `pio:` sintetizado.

**A medida depois.** Rodei a `bash tests/prova_do_jogo.sh` pelo semáforo, numa cópia da árvore. Todas as
checagens da H07b passaram nos dois servidores: um som só ao sentar e a cada entrada, sempre o `pio_p<N>_`, nenhum
`pio:` no registro e nenhum `som_encerrar` até o pódio. No servidor «antes», a prova ficou verde inteira. No
«forma-a», só reprovou o kit («P1 perfeito em 4 de 12» e «P2 ótimo em 2 de 12»). É a família da carga que a H08 já
registrou: a base sem esta ficha, rodada na mesma hora, reprovou «P2 ótimo em 1 de 12».

**A mordida.** Numa cópia, devolvi o pio sintetizado ao `_abrir_o_som` e o `som_encerrar` à saída da construção.
A prova reprovou nos dois servidores:

- «P1 se sentou no título: um pio só… (pio:0, 1 sons no quadro)»;
- «P2 entrou», «P3 entrou» e «P4 entrou: um pio só…», porque chegou o sintetizado;
- «registro: nenhum pio sintetizado… (4)»;
- «do título ao pódio, nenhuma tela fechou a placa dos controles (2 vezes)».

**Escolhas a validar por ela:**

- O sintetizado `pio:%d` ficou como reserva quando o arquivo gravado falta, e não saiu do módulo.
- O pio na TV (o `Som.tocar`, a -12 dB) continua junto do pio no controle.

**Para o André (local):** a lista da ficha continua valendo: com os quatro DualSense, cada um entra e ouve **um** pio
no próprio controle, e o tique da construção e o primeiro som da sala saem sem silêncio de troca de tela.
