# 01 — O diagnóstico

O que uma noite de jogo real mostrou, e o que a leitura do código confirmou.
Cada linha diz o sintoma que o jogador vê, onde ele nasce e a sprint que
resolve. As sprints estão no [SPRINTS](../../SPRINTS.md).

## O jogo parece um teste

| sintoma | onde nasce | sprint |
| --- | --- | --- |
| Toda sala acaba numa tabela ✓ PASSOU / ✗ FALHOU / — NÃO MEDIDO por recurso do controle | `godot/scripts/ui/painel_sala.gd:356-415` | F |
| Seis salas perguntam ao jogador se o controle obedeceu: "Que chão é esse?", "O canto saiu do seu controle?", "Quantas luzinhas acesas?", "Que cor está a sua luz?" | `salas/caminhos.gd:511`, `salas/canto.gd:555`, `salas/galeria.gd:651`, `salas/prova.gd:804` | F |
| O jogo manda olhar o controle: "olhe o controle…", "Chame o guardião, fique mudo, olhe a luz." | `salas/prova.gd:802`, `salas/voz.gd:59`, `salas/voz.gd:617` | F |
| O aviso de cada sala lista as features que ela prova; o portão do salão tem o nome do hardware ("vibração e barra de luz") | `salas/sala_jogo.gd` (aviso), `mundo/salao.gd:16-23` | F |
| A tela de título fala em "relatórios" e em "módulo nativo"; o lobby mostra VID:PID e "o que foi mandado" | `ui/tela_titulo.gd:39-40,71`, `ui/cartao_jogador.gd:71-87` | F, G |
| O diagnóstico ao vivo e o livro da sessão estão a um botão de distância do jogador | `ui/hud.gd:87`, `ui/pausa.gd` | F |

## Falta ser um jogo

| sintoma | onde nasce | sprint |
| --- | --- | --- |
| Não há introdução nem mundo: o título leva direto ao lobby | `ui/tela_titulo.gd` | G |
| Não há criação de personagem: o lobby troca boneco (◀▶) e item (▲▼), e o item não faz nada | `main.gd:605-613`, `ui/tela_lobby.gd` | G |
| O HUD é desenhado em pixels fixos de uma tela de 1920×1080; os cartões de P1..P4 podem encostar na frase da sala com o texto a 1,15× ou em inglês; o seletor do lobby usa 24 e 26 px, abaixo do piso de 30 | `ui/hud.gd:51-60,108-142`, `ui/tela_lobby.gd:334-343`, `tema.gd:42` | G |
| A câmera é uma pose fixa por sala; ninguém é seguido | `camera_pos`/`camera_olhar` em cada sala, `main.gd:924-959` | G |
| Fora de uma partida, a sala não diz quem venceu: só a tabela de veredito | `ui/painel_sala.gd:356-415` | F |
| O relógio da sala "volta" para cheio quando o treino acaba, e parece um timer quebrado | `salas/sala_jogo.gd:427` | F |
| O aviso de cada sala espera ✕ de todos e não tem relógio; se um lugar ficou preso, a sala não começa | `salas/sala_jogo.gd:226-246` | F |
| A bancada nunca emite `terminou` | `salas/bancada.gd` | F (vira o Modo bancada) |
| O quiz e o teste estão misturados: metade das salas é pergunta de múltipla escolha | as seis salas às cegas | F, I–Q |

## O controle fala baixo

| sintoma | onde nasce | sprint |
| --- | --- | --- |
| O háptico é ultra fraco: o jogo pede 0,2 a 0,35 só no motor fraco, por 40 a 70 ms, na maioria dos eventos | `salas/centelha.gd:338`, `main.gd:613`, `salas/sala_jogo.gd:239`, `salas/prova.gd:445`, `salas/viga.gd:421` | F |
| O rumble passa por mais três redutores: o corte pela metade do SDL em firmware antigo, a escala salva nas opções e a disputa com o kernel no Linux | ver [05](05-haptica-e-controle.md) | F |
| O som no controle só existe dentro das salas de som; nos menus, no salão e na maioria das salas o alto-falante fica mudo | `som_preparar` só em `sala_jogo.gd:94`, `prova.gd:109`, `bancada.gd:108`, `main.gd:436` | H |
| A música não reage a nada: oito compassos sintetizados em laço, sem camadas, e calada n'A Voz, n'O Canto e na bancada | `scripts/musica.gd` | H |
| Faltam efeitos no jogo: evento sem som na TV, sem som no controle, sem jingle de fim | `scripts/som.gd` | H |

## O rádio e a identidade

| sintoma | onde nasce | sprint |
| --- | --- | --- |
| No BT, o controle não repete os sons nem vibra | por contrato o jogo só fala USB `0x02`; no rádio, quem traduz é a ponte na frente do hidraw — e hoje não há registro que prove onde a cadeia perde | F, S |
| O P1 da tela não bate com o LED do controle até o ✕ no lobby | `conectou()` não fixa o índice (`nativo/nucleo/pads.c:~200-325`); `pads_entrar()` escolhe o lugar pela ordem do ✕ (`pads.c:506-570`) | F |
| Um controle estranho herda o lugar de quem caiu | a terceira regra de `pads_entrar()` (`pads.c:537-540`) | F |
| Dentro da Galeria e da Prova as luzinhas de jogador viram munição e pergunta, e a barra de luz vira cor de equipe; ninguém mais sabe quem é quem | `salas/galeria.gd:201`, `salas/prova.gd:227,264,557,574` | F, M, Q |

## O ritmo não é medido

| sintoma | onde nasce | sprint |
| --- | --- | --- |
| Não há relógio de áudio: todo tempo é soma de `delta` do quadro | nenhum uso de `get_time_since_last_mix`/`get_output_latency`; o carimbo do registro também é soma de `delta` (`nativo/nucleo/relogio.h`) | H |
| Não há janelas de julgamento (perfeito, ótimo, bom, erro) nem calibração de latência | `salas/canto.gd` (`FOLGA_RITMO := 0.12`), `salas/centelha.gd` (janelas de segundos) | H |

## A voz das telas

| sintoma | onde nasce | sprint |
| --- | --- | --- |
| Botões e rótulos começam com minúscula: "começar", "créditos", "pronto", "sair", "fechar", "salas vencidas", "lidera", "virada!" | 143 das 233 chaves de `godot/scripts/traducoes.gd`, mais os textos montados com `%` | F |
| "fechar" nem tem tradução | `ui/diagnostico.gd:57`, `ui/livro.gd:150` | F |
