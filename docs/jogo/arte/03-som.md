# 03 O som

A Forja soa como uma fita gravada em casa, tocada num deck que já viu muita
noite. Tudo o que soa é metal, fita, a voz de um cavaleiro ou o mundo. A
música é do doc [04 Ritmo e áudio](../04-ritmo-e-audio.md); este arquivo
decide os efeitos, o tratamento, a mixagem e como cada som nasce.

## De onde vem cada som

Nenhum som de IA. Três origens, e só três:

1. **Síntese procedural.** As receitas de `nativo/som/sintese.c` (bigorna,
   martelada, blip, acorde, sopro, passo, grito, trilha), portadas para um
   gerador em Python que só usa a biblioteca padrão:
   `godot/estudos/direcao/som/gerar_sons.py`. Todo som novo desta bíblia sai
   dele.
2. **Gravações CC0 da Kenney** (Impact, Interface, RPG Audio, Digital Audio,
   Music Jingles), convertidas de OGG para WAV 48 kHz mono no commit 8feab15.
   São os sons de sabor de hoje (`som.gd` GRAVADOS). Ficam onde estão.
3. **O módulo nativo em tempo real** (as notas que as salas medem, o
   alto-falante e a háptica do controle). Continua como está.

A origem de cada arquivo fica escrita em `godot/assets/LEIA-ME.md`.

## As famílias

Cada som pertence a uma família. A família decide o timbre, o tratamento e o
barramento.

| família | do que é feito | exemplos | barramento |
| --- | --- | --- | --- |
| metal | as parciais da bigorna: razões 1; 2,76; 5,40; 8,93; 13,34; 18,64, amplitudes 1; 0,62; 0,45; 0,30; 0,18; 0,10, mais 4 ms de ruído no ataque | martelada, carimbo, a forja do cavaleiro | Efeitos |
| fita | motor, plástico, mola, cabeça magnética | PLAY, stop, rebobinar, auto-stop, virar, caneta | Interface |
| voz do cavaleiro | a nota do lugar, no timbre do lugar | assinatura, pio, julgamentos, vitória | Voz |
| interface | blips curtos de fita | navegar, confirmar, voltar, travar, sortear | Interface |
| mundo | a tabela de materiais do doc 05 | passo, toque, impacto | Efeitos |
| corpo e humor | molas e baques | o boing (300 a 120 Hz) do cavaleiro que quica | Efeitos |
| Dissonância | a fita enroscando | os dropouts, o tom que cai | Efeitos |

## O tratamento de fita

Todo som do gerador passa pelo tratamento antes de virar WAV. É ele que faz o
synthwave virar fita. Na ordem:

| passo | o que faz | número |
| --- | --- | --- |
| wow | o tom ondula devagar | 0,5 Hz, ±0,12 % (linha de atraso de ±0,38 ms) |
| flutter | o tom treme rápido | 9 Hz, ±0,05 % (±8,8 µs) |
| saturação | a fita comprime o pico | `tanh(1,8·x) / tanh(1,8)` |
| corpo | o grave da cabeça | +2 dB numa prateleira em 90 Hz |
| teto | a fita não guarda o agudo | passa-baixa em 12 kHz |
| chiado | o ruído da fita | rosa a −62 dBFS, com passa-alta em 2 kHz |
| dropouts | a fita falha | quedas de 30 ms a −18 dB; **só na Dissonância** |

A interface leva o tratamento leve: sem wow, flutter pela metade, sem chiado.
Quem navega num menu não quer ouvir a fita ondular a cada tique.

## A voz de cada cavaleiro

Cada lugar tem uma nota e um timbre. Os quatro juntos fazem o acorde da Forja,
Dó com sétima maior (Dó, Mi, Sol, Si).

| lugar | cor | nota | Hz | timbre | como se faz |
| --- | --- | --- | --- | --- | --- |
| P4 | âmbar | Dó5 | 523,25 | o bronze | duas serras desafinadas ±7 cents, passa-baixa em 2,2 kHz |
| P1 | ciano | Mi5 | 659,25 | o cristal | sino FM (portadora 1:1, moduladora 3,5:1, índice de 2,5 caindo a 0 em 400 ms) |
| P2 | magenta | Sol5 | 783,99 | o pulso | onda de pulso a 25 %, passa-baixa em 3 kHz |
| P3 | limão | Si5 | 987,77 | a faísca | quadrada com salto de tom (começa 2 semitons acima e cai em 30 ms) |

A assinatura (`ass_p{n}.wav`, 400 ms) é essa nota sozinha, com ataque de 5 ms
e queda exponencial. É o que toca no alto-falante do controle no acerto
perfeito (doc 05, a agenda do alto-falante).

### No tom da faixa

As notas são do acorde de Dó. Quando a faixa está noutro tom, a nota sobe ou
desce pelo `pitch_scale`, de −6 a +5 semitons: `pitch_scale = 2^(s/12)`. É a
velocidade da fita, e a fita ouve assim. A ficha do minigame diz o tom da
faixa (doc 04); sem tom, Dó.

### O pio

Quando o controle entra no jogo, o cavaleiro pia: a nota do lugar e uma
segunda nota. O intervalo vem da cabeça escolhida, então dois cavaleiros
do mesmo lugar podem piar diferente.

São seis intervalos, e cada um vale para duas das doze cabeças (a tabela
das cabeças, com o intervalo de cada uma, está em
[04 O cavaleiro](04-o-cavaleiro.md#as-peças)):

| intervalo | o pio | semitons |
| --- | --- | --- |
| a segunda | sobe uma segunda maior | +2 |
| a terça | desce uma terça maior | −4 |
| a quarta | sobe uma quarta | +5 |
| a quinta | sobe uma quinta | +7 |
| a quinta de baixo | desce uma quinta | −7 |
| a oitava | sobe uma oitava | +12 |

O pio não tem arquivo próprio: são duas `ass_p{n}`, a primeira com 120 ms e a
segunda com `pitch_scale` do intervalo, 80 ms depois.

## O carimbo de cada julgamento

As palavras são as do doc [07](../07-narrativa-e-voz.md#o-vocabulário-do-visor):
"Ressonância!", "Afinado", "Quase". O erro não tem palavra. O estudo usou
"PERFEITO" como provisório; o jogo usa as do doc 07.

O carimbo visual: Bungee de 46 px na cor do dono, rotação de −4°, escala de
1,35 a 1,0 em 80 ms, fica 250 ms e some em 170 ms. São 500 ms ao todo.

O som de cada julgamento, por lugar (`jul_<julgamento>_p<n>.wav`, 16 arquivos):

| julgamento | o som | duração |
| --- | --- | --- |
| Ressonância! (perfeito) | a nota do lugar, limpa, com o transiente de metal da bigorna no ataque | 180 ms |
| Afinado (ótimo) | a nota com o brilho pela metade (as parciais altas a 0,5) | 150 ms |
| Quase (bom) | a nota com passa-baixa em 1,2 kHz | 120 ms |
| erro | a nota 60 cents abaixo, reduzida a 6 bits, com wow de 4 Hz | 220 ms |

O erro soa quebrado, não reprovado: é a nota do próprio cavaleiro saindo
desafinada. Ninguém ouve um "buzz" de erro.

No perfeito, a música abaixa 2 dB por 80 ms para a nota passar.

## A vitória e a derrota

Os dois trechinhos que garantem o momento de ganhar e o de perder.

### A vitória: `fx_vitoria_p{n}.wav`

- o arpejo 1-3-5-8 a partir da nota do lugar, uma oitava abaixo, em
  semicolcheias a 120 BPM (125 ms cada, 500 ms);
- depois o acorde maior do lugar, 500 ms, com a martelada de metal no ataque
  (o carimbo);
- 1000 ms no total, no timbre do cavaleiro;
- toca na TV e no alto-falante do vencedor, com o batimento duplo na háptica
  dele ([08 A háptica](08-haptica.md));
- entra 1 batida depois do apito, e o jingle de vitória (`JIN_VITORIA` da
  H06) entra quando ele acaba.

Cada lugar ganha com a própria voz. Quem ganhou ouve a si mesmo.

### A derrota: `fx_derrota.wav`

- a parada da fita: o tom cai a 0,25× em 700 ms (curva exponencial) e o filtro
  fecha de 8 kHz a 400 Hz junto;
- aos 900 ms, o "plic" do carretel parando (um blip de 2 kHz, 15 ms);
- 1400 ms no máximo;
- toca no controle do último colocado e na TV a −6 dB, durante o inserto dele
  ([01 O cinema](01-cinema.md#o-plano-de-cada-momento)).

A derrota não tem a voz de ninguém: é a fita que desacelera. Quem perdeu
ouve uma piada de deck, não um "perdeu". É a regra do épico no peito e do riso
no corpo.

## A fita como som

| arquivo | quando | o som | duração |
| --- | --- | --- | --- |
| `fx_play.wav` | o PLAY no título | o clunk da tecla e o motor ganhando velocidade | 400 ms |
| `fx_stop.wav` | sair de uma faixa no meio | o clunk da tecla, o motor que para | 250 ms |
| `fx_entrada.wav` | a entrada do minigame | o rasgo: ruído que sobe de 300 Hz a 6 kHz, e o impacto (martelada grave em 98 Hz) cravado em 600 ±5 ms | 900 ms |
| `fx_rebobinar.wav` | repetir a faixa, recomeçar o treino | o guincho da fita voltando (banda de ruído de 400 a 2400 Hz subindo) e o clunk no fim | 900 ms |
| `fx_virar.wav` | virar a fita | o eject, o plástico na mão, o clunk de entrar | 1600 ms |
| `fx_autostop.wav` | o fim da fita | o clique seco do auto-stop | 200 ms |
| `fx_caneta.wav` | a caneta escreve na etiqueta | o chiado do marcador no papel, três traços | 400 ms |

A entrada é agendada para que o impacto caia no tempo 1: o som começa 600 ms
antes do tempo 1, pelo relógio de áudio (H01).

## A interface

Curta, seca, de plástico. Só no controle de quem fez e baixinho na TV.

| arquivo | quando | duração |
| --- | --- | --- |
| `ui_tique.wav` | navegar | 35 ms |
| `ui_confirma.wav` | ✕ | 90 ms |
| `ui_volta.wav` | ○ | 90 ms |
| `ui_peca.wav` | trocar uma peça do cavaleiro (o encaixe de metal) | 120 ms |
| `ui_trava.wav` | travar uma parte (□) | 80 ms |
| `ui_sorteio.wav` | sortear (△): uma roleta de 6 tiques que freia | 480 ms |
| `reacao_pop.wav` | uma reação (o adesivo cola) | 120 ms |

`ui_peca` muda de altura conforme a parte: cabeça +7 semitons, superior +4,
inferior 0, arma ou amuleto −5, pelo `pitch_scale`.

## O mundo e o corpo

Os sons de material seguem a tabela do doc
[05](../05-haptica-e-controle.md#a-háptica-por-material): metal, pedra,
areia, gelo, grama, lama e madeira, cada um com o som e a vibração da mesma
onda. O boing do cavaleiro que quica (seno de 300 a 120 Hz em 250 ms, com
vibrato de 12 Hz) é o som do humor do corpo.

Estes ficam para depois desta leva: hoje as gravações da Kenney cobrem o
mundo. Quando entrarem, entram pelo gerador.

## A mixagem

Hoje tudo toca no Master: não existe `godot/default_bus_layout.tres`. A H11
cria os barramentos.

| barramento | o que leva | pico de cada som | efeito no barramento |
| --- | --- | --- | --- |
| Musica | a trilha | −6 dBFS | abaixa 2 dB por 80 ms no perfeito |
| Efeitos | metal, mundo, corpo, Dissonância, fita grande | −6 dBFS | nenhum |
| Interface | ui, fita pequena | −12 dBFS | nenhum |
| Voz | assinaturas, julgamentos, vitória | −9 dBFS (cada nota −12) | limitador em −3 dBFS |
| Ambiente | fogo, vento, salão | −18 dBFS | nenhum |

As reações tocam a −18 dB. Os quatro cavaleiros podem soar juntos, e o
limitador da Voz impede que quatro perfeitos no mesmo quadro estourem.

### O formato

Todo WAV que sai do gerador:

- 48 kHz, mono, 16 bits, PCM;
- pico ≤ −1 dBFS;
- desvio DC abaixo de 0,5 % do pico;
- a primeira e a última amostra abaixo de 0,001 (rampas de 3 ms, como em
  `sintese.c`);
- a duração dentro do teto do prefixo:

| prefixo | teto |
| --- | --- |
| `ui_`, `reacao_` | 120 ms (`ui_sorteio` 480 ms) |
| `jul_` | 250 ms |
| `ass_` | 400 ms |
| `fx_` | 1600 ms |
| `jin_` | 4000 ms |

O portão da [12](12-portoes.md) confere tudo isso por script.

## O gerador

`godot/estudos/direcao/som/gerar_sons.py`, só com a biblioteca padrão do
Python (`wave`, `math`, `random`, `struct`, `argparse`).

- `python3 gerar_sons.py` escreve todos os WAV desta página em
  `godot/assets/sons/`;
- `--so fx_vitoria_p1` escreve um só;
- `--lista` imprime o nome, a família e a duração de cada um, sem escrever;
- `--conferir` lê os WAV de `godot/assets/sons/` e confere o formato e o teto
  acima; sai com código 1 se algum falhar;
- tudo com semente fixa: rodar duas vezes dá os mesmos bytes.

O ffmpeg não é preciso. O gerador nunca toca som.

## O casamento com a háptica

Cada família vibra de um jeito. Os números estão em
[08 A háptica](08-haptica.md); em resumo:

| família | a vibração |
| --- | --- |
| metal | pulso de 150 Hz |
| fita | rumble fraco a 0,3 |
| vitória | batimento duplo: 1,0 por 120 ms, pausa de 120 ms, 0,7 por 120 ms |
| derrota | rumble de 0,6 caindo a 0 em 700 ms |
| julgamentos | o piso do doc 05 |
