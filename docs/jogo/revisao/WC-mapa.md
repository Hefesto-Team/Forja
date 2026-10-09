# O núcleo em GDScript — o mapa

Para quem chega: os autoloads e o `main`, o que cada um faz e por onde se conversam. Medido na árvore de
09/10/2026 (`voo/auditoria`).

## Os autoloads, na ordem em que rodam a cada quadro

| autoload | arquivo | prioridade | o que faz |
| --- | --- | --- | --- |
| `Forja` | `godot/scripts/forja.gd` | −101 (o filho `ForjaControles`, o módulo nativo, em −100) | os argumentos, os lugares, a entrada, as saídas, as sensações, o relatório, as medidas, as cegas, o som de cada controle, a bancada e o robô. Quase tudo é envelope `ctl.x() if modulo`. O `_ready` chama `Opcoes.carregar(robo)` e `aplicar_opcoes`, que mexe em `Tema.escala_texto`, em `Traducoes.idioma` e no volume do `AudioServer`. |
| `Som` | `godot/scripts/som.gd` | — | os efeitos da TV e do controle (as tabelas `RECEITAS` e `GRAVADOS`, que a V05 leva para o mapa do áudio). |
| `Musica` | `godot/scripts/musica.gd` | — | as faixas e os jingles. |
| `Ritmo` | `godot/scripts/ritmo.gd` | −90, `PROCESS_MODE_ALWAYS` | o relógio da música (`t_musica`): a placa de som quando há faixa, o `Time.get_ticks_usec` quando não há; a batida, as janelas e o `julgar`. Quem chama: `minigames/minigame.gd` e `ui/tela_opcoes.gd` (`definir_desvio`). |

O módulo lê o controle no `_process` dele (−100): o `forja_quadro` (`nativo/nucleo/forja.c:211`) bombeia os eventos
do SDL, e só então o `Ritmo` mede o tempo do quadro (−90) e as salas leem o aperto (0).

## As classes estáticas e puras

- `Partida` (`godot/scripts/partida.gd`): `RefCounted`, sem nó. `roteiro`, `registrar`, `podio` e o desempate
  `_acima`.
- `Opcoes` (`godot/scripts/opcoes.gd`): grava em `user://opcoes.cfg`.
- `Tema` (`godot/scripts/tema.gd`): as cores, a `fonte`, o `tom_para_a_borda` e um `tema()` que monta um `Theme`
  que nenhum nó usa (toda letra sai pelo `Desenho`).
- `Traducoes` (`godot/scripts/traducoes.gd`): o `EN` (por volta de 256 entradas) e o `EN_PADROES` (69 expressões).
  O `Desenho.t` e o `Glifo` traduzem a cada desenho.
- `AltoFalanteDoControle` (`godot/scripts/alto_falante_do_controle.gd`): só a prova usa (é da V07).

## O `main`

`godot/scripts/main.gd` é o `Node3D` de `scenes/main.tscn`. A máquina de estados `estado` (título, lobby, salão,
sala, pódio) com um `overlay` por cima (diagnóstico, livro, pausa, partida, placar, opções, créditos). Toda troca
passa por `_trocar`, que cuida da cortina e do `_trocando`. Usa o `Catalogo` (`criar`, `existe`), a `Partida`, a
`SalaJogo` (o sinal `terminou` leva a `_ao_terminar_a_sala`), as telas de `ui/` e os quatro `ForjaPlayer`. Os
atalhos de abertura (`--sala=`, `--tela=`, `--partida=`, `--prova-de-fogo`) moram em `_abrir_pelos_args`.

## As fichas desta área

| ficha | o quê | gravidade |
| --- | --- | --- |
| [WC01](../tarefas/WC01-o-toque-no-instante-do-aperto.md) | o toque julgado no instante do aperto, não no do quadro | média |
| [WC02](../tarefas/WC02-o-podio-sem-ciclo.md) | o pódio com ausências não depende da ordem dos presentes | baixa |
| [WC03](../tarefas/WC03-a-traducao-que-lembra.md) | a tradução guarda o que já traduziu | baixa |
| [WC04](../tarefas/WC04-o-argumento-errado-avisa.md) | o argumento de abertura errado avisa e sai | baixa |
| [WC05](../tarefas/WC05-o-resto-do-codigo-sem-uso.md) | o resto do código sem uso do núcleo | baixa |

## O que outras fichas já cobrem nesta área

- WE02 (desta leva): a prova do kit no relógio do quadro e a régua de 70 % de volta (a WC01 parte dela e cura o
  jogo).
- V07: o código sem uso do alto-falante e do `quem_apertou` (a WC05 completa a lista).
- V03: a tabela de traduções em partes e o portão do texto de tela.
- V04: as seções num lugar só (`SALAS`, `ORDEM_DO_FOGO`, `NOMES`).
- X02, X03, X04, X06: a partida, o ritmo, o `forja.gd` e o `main.gd` viram pacote, sem mudar comportamento. As
  fichas WC que mudam comportamento nesses arquivos vão antes da extração deles.

## Conferido e sem defeito

- Sair da sala repõe o `preso` do cavaleiro.
- O minigame pausa e para o `Ritmo`.
- O `Forja` carrega antes do `Ritmo`: o `ler_das_opcoes` já lê as opções carregadas.
- O `_seguir_a_partida` com o `_trocando` não registra a sala duas vezes, e o `terminou` é ligado uma vez por sala.
- O `sala_da_bancada` é limpo no resultado.
- A pasta padrão do relatório é conferida antes de abrir (`forja.gd:209`) e cai para `user://relatorios`.
