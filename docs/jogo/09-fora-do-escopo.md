# 09 — Fora do escopo

O que a pesquisa de mercado sugere para jogos de ritmo em geral, e o Forja
recusa. Cada linha tem o porquê, para a próxima pessoa não precisar
redescobrir.

| o que se sugere | por que não |
| --- | --- |
| jogo online, sincronização por servidor, predição e rollback | o Forja é um jogo local de quatro pessoas no mesmo sofá ([CONTRATO](../../CONTRATO.md)); não há rede |
| middleware de áudio (FMOD, Wwise) | o Godot e o mixer do módulo fazem o que o jogo precisa: relógio de áudio, barramentos, filtros, rampas; um middleware traria licença, peso e mais um relógio para sincronizar |
| trocar de motor (Unity, Unreal) | o jogo é o 3D em Godot ([ADR 007](../adr/007-o-jogo-e-o-3d-em-godot.md)) |
| falar o relatório Bluetooth `0x31`, com o CRC sobre `0xA2` | proibido pelo contrato; o jogo fala USB `0x02`, e o rádio é da ponte |
| usar o SDK da Sony | sob NDA: não se usa, não se procura, não se reproduz |
| DSX, UDP 6969, `controllerIndex`, o socket do Hefesto | proibidos pelo contrato; transformariam o jogo num teste circular |
| identificar o jogador por MAC ou `uniq` | a identidade é o lugar 0..3, e ponto |
| dublagem, cutscenes longas, árvore de habilidades | contra o princípio de pouco texto e contra o tempo de uma noite de festa |
| loja, moeda, microtransação | a coleção cresce jogando; o Forja não vende nada dentro do jogo |
| MP3 em qualquer lugar | o preenchimento de silêncio quebra o laço e o tempo |
| ajuste escondido que pune quem joga bem | a recuperação ajuda quem está atrás sem tirar nada de quem está na frente ([02](02-principios.md#8-ninguém-fica-para-trás-ninguém-é-punido-por-ser-bom)) |
