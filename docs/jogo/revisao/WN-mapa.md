# O mapa do módulo nativo

Para quem chega ao `nativo/` pela primeira vez. Medido em 09/10/2026 na integração `voo/auditoria` (topo `85f24c3`).

## As camadas

| camada | onde | o que faz | quem prova |
| --- | --- | --- | --- |
| o legado | `src/`, `include/forja_dualsense.h` | as ferramentas de mesa do `Makefile` (`forja-send`, `speak`, `read`, `selftest`); só `src/forja_dualsense.c` entra no jogo, como `forja_ds5`: a sombra e o payload de 47 bytes | `selftest` |
| o núcleo, sem SDL | `forja_nucleo` (`nativo/CMakeLists.txt:51-68`) | lógica pura: `achar_som`, `aleatorio`, `analise`, `catalogo`, `cegas`, `chao`, `mascara`, `medidas`, `origem` e `origem_linux`, `postura`, `relatorio`, `taxa`, `texto_buf`, `utf8`, `som/rampa`, `som/sintese` | `nativo/testes/forja-testes` (por `ctest`; com ASan e UBSan, 4578 verificações, nenhuma falha) |
| a camada com aparelho | `forja_sdl` (`nativo/CMakeLists.txt:101-114`) | a sessão, os controles, o registro, o relógio, o simulador, o mixer e o som de cada controle | só a prova do jogo, com o simulador |
| a extensão do Godot | `nativo/godot/` | registra `ForjaControles`; o `_process` chama `forja_quadro` e depois `med_quadro` | a prova do jogo |

## A camada com aparelho, arquivo por arquivo

- `nucleo/forja.c` — a sessão. `forja_quadro` (`:210`): zera os apertos, o simulador anda, `SDL_PollEvent` →
  `pads_evento`, `pads_atualizar`, `somc_atualizar`.
- `nucleo/pads.c` — os controles e os quatro lugares: a conexão (`conectou`, `:254`), a volta pela assinatura
  (`:373`), a reserva, o espelho e a entrada no lobby (`pads_entrar`, `:587`), as saídas anotadas e a sombra dos
  motores. A assinatura de um controle é modelo, origem e nome (`:162`).
- `nucleo/registro.c`, `nucleo/linha_tempo.c` — o registro de texto e o `jsonl`, com flush por evento.
- `nucleo/relogio.c`, `nucleo/simulador.c` — o relógio; os quatro controles virtuais, o robô e o cabo que cai
  (`simulador_cabo`). O simulado tem nome próprio («DualSense simulado N») e placa de som virtual de 4 canais.
- `som/mixer.c` — mistura as vozes sob `SDL_Mutex`.
- `som/som_controle.c` — um fluxo por nó de som, alimentado na linha de áudio. Casa o nó com o controle pelo
  `usb_pai` do sysfs (pelo aparelho), depois pelo número, depois pelo nome. A lista é lida em `somc_preparar`.
  O pedaço de cada sistema fica em `som_controle_linux.c` (o `pactl`), `_windows.c` e `_outro.c`.
- `som/sons_salas.c` — os sons de cada sala.

## A extensão (`nativo/godot/`)

`forja_controles.cpp` (a sessão, a entrada, as saídas, o relatório, o simulador, os binds), `forja_medidas.cpp`,
`forja_cegas.cpp`, `forja_som.cpp` (os PCM registrados ficam num `std::map` até o fim) e `forja_bancada.cpp`.
Quem chama é o autoload `godot/scripts/forja.gd` (`ctl.*`). Em `main.gd`, `_ao_mudar_os_controles` refaz a placa
quando um controle volta, e `Forja.entrar` só acontece no lobby (`:670`) e nos argumentos de prova (`:202`).

## O build

`scripts/compilar.sh` roda o CMake com Ninja. A prova nativa vai por `ctest`, com `FORJA_TESTES=ON` e sem a extensão
(`compilar.sh:135-144`); por isso o `forja_sdl` nunca entra nela. O SDL 3.4.14 sai compilado estático de `.cache/src`.

## O que foi conferido e está são

O mixer trava todas as operações; `fechar_saida` destrói o fluxo antes de soltar o mixer; os ponteiros de som ficam
estáveis no `std::map`; `sons_salas_liberar` roda depois de `somc_encerrar`; os limites de botão em `medidas.c`; os
buffers da síntese pelo tamanho da onda; `somc_trocar` só abre nós candidatos e `abrir_no` reaproveita a saída do
mesmo nó (o teto de 12 saídas não se esgota); as cores que o GDScript manda para `luz()` ficam em 0..1.

## O que esta leva achou

- [WN01](../tarefas/WN01-os-controles-iguais-voltam-ao-lugar.md) — quatro DualSense no cabo têm a mesma assinatura: dois que
  caem juntos não voltam, e no lobby um herda o lugar do outro.
- [WN02](../tarefas/WN02-o-som-que-chega-depois-do-controle.md) — a placa do controle que volta é lida no quadro em que ele
  volta; se o nó de som chega depois, ninguém relê.

A raiz comum das duas: a regra de decisão mora dentro da função que fala com o SDL, e a prova nativa não a alcança.
Cada ficha tira a sua regra para o núcleo e a prova lá; o resto do `forja_sdl` fica como está.

## As fichas que já tocam a área

V01 a V08 (a esteira) e X04 (o pacote do DualSense, que muda a extensão de pasta sem mudar comportamento).
