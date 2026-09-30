# 05 — A háptica e o controle

O que a noite de teste mostrou: o háptico era ultra fraco, o som no controle
quase não aparecia, no BT nada se repetia, e o P1 da tela não era o P1 do
controle. Esta página decide como o Forja fala com cada DualSense — sempre
dentro do [CONTRATO](../../CONTRATO.md): USB `0x02`, pela documentação
pública da Sony, da Steam e do SDL.

## Por que o háptico está fraco

São sete suspeitas. Cada uma tem um teste, e a Sprint F mede todas antes de
mudar qualquer valor.

| | suspeita | o que se sabe | o teste |
| --- | --- | --- | --- |
| a | **O jogo pede pouco** | a maioria dos eventos pede 0,2 a 0,35 no motor fraco por 40 a 70 ms (`salas/centelha.gd:338`, `main.gd:613`, `salas/sala_jogo.gd:239`) | tabela de piso abaixo; comparar sentido às cegas antes e depois |
| b | **O SDL corta pela metade** | com firmware abaixo de 2.24 (e fora do Edge), o `SDL_hidapi_ps5.c` usa a emulação antiga e divide o motor por dois; o kernel usa outro limiar (2.21) | registrar o firmware de cada controle na conexão (o SDL lê o relatório de recurso `0x20`) |
| c | **O modo suave** | no firmware novo o SDL liga a emulação "melhorada" (bit `0x04` do byte 38), que se sente mais suave que a antiga | medir as duas sensações às cegas no mesmo controle |
| d | **Outro dono do motor** | no Linux o `hid-playstation` segue preso ao controle; se alguém (o kernel, o `Input.start_joy_vibration` do Godot) mandar um relatório com motor em zero, o rumble do SDL some até o reenvio de dois segundos | garantir que o Godot nunca vibra (nenhum `start_joy_vibration` no código) e registrar cada saída do kernel na bancada |
| e | **Rumble e háptica por áudio se anulam** | quando há rumble, o SDL liga "desligar a háptica por áudio"; os dois juntos (como na Prova) brigam | nunca usar os dois no mesmo instante no mesmo controle; a sala escolhe um por evento |
| f | **A escala salva** | a opção de vibração do lugar (0 a 100%) multiplica tudo, e fica salva em `user://opcoes.cfg` | mostrar a escala de cada lugar no registro da sessão |
| g | **A ponte descarta bytes** | no rádio, quem traduz o `0x02` é a ponte na frente do hidraw; se ela descarta o byte 0 ou o 38, o controle recebe rumble sem modo | cruzar o registro do jogo com o da ponte ([08](08-a-noite-de-6-horas.md)) |

## O piso de força

Nenhum evento de jogo vibra abaixo destes valores (antes da escala do
jogador):

| evento | motor forte | motor fraco | duração |
| --- | --- | --- | --- |
| toque de interface (navegar) | 0 | 0,45 | 60 ms |
| acerto comum | 0,3 | 0,6 | 80 ms |
| acerto perfeito | 0,5 | 0,8 | 100 ms |
| erro | 0,7 | 0,3 | 160 ms |
| golpe recebido, queda | 1,0 | 0,6 | 250 ms |
| explosão, fim de rodada | 1,0 | 1,0 | 400 ms |
| aviso de perigo (um tempo antes) | 0,6 | 0 | meio tempo da faixa |

Os valores ficam num lugar só (a tabela de eventos de `godot/scripts/forja.gd`),
e as salas pedem o **evento**, não os números. É isso que impede o piso de
voltar a cair sala a sala.

## A força máxima que é legítima

- **No cabo, a háptica por áudio é a força de verdade.** O controle aparece
  como placa de áudio de quatro canais; os canais traseiros são os
  atuadores. Onda grave (60 a 180 Hz), escala cheia, WAV PCM sem compressão.
  A página de suporte da Sony diz o mesmo com outras palavras: a háptica
  exige conexão USB no PC. Os jogos comerciais da Sony no PC exigem o cabo
  para ela.
- **No rádio, vão o rumble e o gatilho**, montados em `0x31` pela ponte (ou
  pela Steam Input). O jogo nunca monta o `0x31`.
- **Decisão de contrato em aberto (Sprint F).** Existe uma alavanca a mais:
  montar o próprio bloco de 47 bytes com a emulação antiga ("seca") via
  `SDL_SendGamepadEffect`, sem o corte pela metade. Isso fere a regra atual
  da sombra ("`FORJA_FX_RUMBLE` nunca é nosso"). Só entra se a medição da
  suspeita (c) mostrar que a sensação seca é o que falta, e se o contrato
  for emendado por escrito.

## A háptica por material

A háptica é desenhada como som. Cada material do mundo tem a sua onda, e todo
passo, toque e impacto usa a do material:

| material | a sensação | a onda |
| --- | --- | --- |
| metal | clique seco, duro | pulso curto de 150 Hz, ataque instantâneo |
| pedra | batida surda | 80 Hz, 60 ms, decaimento rápido |
| areia | granulado espalhado | ruído filtrado abaixo de 200 Hz, amplitude baixa |
| gelo | fino e localizado | 180 Hz, 20 ms, só um atuador |
| grama | macio | ruído grave, envelope longo |
| lama, plasma | pesado e lento | 60 Hz com vibrato lento |
| madeira | oco | 110 Hz, duas batidas curtas |

A tabela vive no módulo (`nativo/som/sintese.c`), e a mesma onda vai para o
atuador e, mais baixa, para o alto-falante — a trindade ver, ouvir, sentir.

## A agenda do alto-falante

| quando | o que toca no alto-falante do **dono** |
| --- | --- |
| o controle entra no jogo | o pio do cavaleiro (cada boneco tem o seu) |
| acerto perfeito | a nota do jogador, limpa |
| erro | a nota do jogador, quebrada |
| coleta | um tilintar curto |
| a bomba, o alarme, o segredo | o som que só ele deve ouvir |
| navegação de interface | um clique curto, só no controle de quem navegou |

Nunca música, nunca ambiente contínuo, nunca dois sons ao mesmo tempo no
mesmo controle. O volume do alto-falante sai das opções do lugar.

Hoje o som no controle só existe dentro das salas de som. A Sprint H abre a
placa de áudio de cada controle **na entrada do lugar** e a mantém aberta até
ele sair.

## A identidade P1..P4

| regra | como |
| --- | --- |
| o número do controle é o número da tela, desde a conexão | na conexão, o controle recebe o primeiro lugar livre e as luzinhas dele (P1 `00100`, P2 `01010`, P3 `10101`, P4 `11011`); o ✕ no lobby confirma o lugar, não o escolhe |
| a cor do lugar é a cor da barra de luz | sempre; o acerto perfeito pisca branco por um instante e volta |
| nada apaga a identidade | nenhuma sala usa as luzinhas de jogador como munição nem como pergunta; a cor de equipe aparece no mundo (chão, armadura), não na barra de luz |
| quem caiu reencontra o lugar | o controle que volta com a mesma assinatura recupera o lugar; um controle estranho não herda o lugar de ninguém — ele pega um livre, ou espera |
| trocar de lugar é um gesto | na construção do cavaleiro, segurar Botão ◻ (Trocar lugar) por um segundo passa o lugar para o próximo livre |

## O rádio

O Forja fala USB `0x02` e só. No rádio, quem traduz é a ponte na frente do
hidraw — o que o CONTRATO chama de "o que estiver na frente do hidraw". Pela
ponte, o controle aparece ao jogo como um DualSense USB, e o jogo o trata
igual a qualquer outro. O que ele faz:

- registra **cada** saída com número de sequência, para a noite de seis
  horas cruzar com o registro da ponte;
- registra o transporte que o SDL relata (cabo ou rádio) e a placa de áudio
  achada ou não achada;
- no rádio, sem placa de áudio, o minigame entrega pelo rumble a pista que
  no cabo iria pela háptica por áudio — mais grosseira, mas jogável — e o
  registro anota a troca.
