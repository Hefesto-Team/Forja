# 03 O som

A Forja soa como uma fita gravada em casa, tocada num deck que já viu muita
noite. Tudo o que soa é metal, fita, a voz de um cavaleiro ou o mundo. Este
arquivo decide os efeitos, o tratamento, a mixagem, o que toca onde e o
casamento de cada som com a vibração e o gatilho. A música é do doc
[04 Ritmo e áudio](../04-ritmo-e-audio.md); aqui fica só o que cada seção pede
dela.

Todo som tem uma linha no [mapa do áudio](../audio/mapa.csv), com o id, a
receita e o estado ([as colunas](../o-time/o-mapa-do-audio.md)). Nenhuma ficha
toca um som que não está no mapa.

## De onde vem cada som

Nenhum som de IA. Quatro origens, e só quatro:

1. **Síntese procedural por arquivo.** As receitas de `nativo/som/sintese.c`
   (bigorna, martelada, blip, acorde, sopro, passo, grito, pulso), portadas
   para um gerador em Python que só usa a biblioteca padrão:
   `godot/estudos/direcao/som/gerar_sons.py`. Todo som novo desta bíblia sai
   dele, já com o tratamento de fita.
2. **Gravações CC0 da Kenney** (Impact Sounds, Interface Sounds, RPG Audio,
   Digital Audio, Music Jingles, do pacote 3.7.0 em `oficina/kenney/`),
   convertidas de OGG para WAV 48 kHz mono 16 bits, sem normalizar. São os
   sons de sabor de hoje (`som.gd`, `GRAVADOS`). O mapa diz o arquivo de
   origem de cada um, e o gerador refaz a conversão (`gerar_sons.py kenney`).
3. **A síntese em tempo real.** Na TV, as receitas de `som.gd` (`RECEITAS`);
   no controle, as de `nativo/som/sons_salas.c` e as da H07. No mapa, os da TV
   têm o prefixo `sint_` e os do controle o prefixo `mod_`, com o arquivo
   «(módulo)».
4. **A trilha.** As faixas e os jingles de música saem do gerador da trilha
   (`scripts/gerar_trilha.py`, H09). A reserva é a trilha sintetizada
   (`sint_trilha`, `godot/scripts/musica.gd`): o jogo funciona inteiro sem
   nenhuma faixa.

## As famílias

Cada som pertence a uma família. A família decide o timbre, o tratamento e o
barramento. No mapa, a coluna `familia` usa o nome da primeira coluna.

| família | do que é feito | exemplos | barramento |
| --- | --- | --- | --- |
| `metal` | as parciais da bigorna: razões 1; 2,76; 5,40; 8,93; 13,34; 18,64, amplitudes 1; 0,62; 0,45; 0,30; 0,18; 0,10, mais 4 ms de ruído no ataque | martelada, carimbo, escudo, sino | Efeitos |
| `fita` | motor, plástico, mola, cabeça magnética | PLAY, stop, rebobinar, auto-stop, virar, caneta | Interface |
| `voz` | a nota do lugar, no timbre do lugar | assinatura, pio, julgamentos, vitória, carimbos | Voz |
| `interface` | blips curtos de fita | navegar, confirmar, voltar, travar, sortear | Interface |
| `mundo` | a tabela de materiais do doc 05 | passo, pedra, portão, tiro, materiais | Efeitos |
| `corpo` | molas e baques: o humor | o boing, o tropeço, o grito | Efeitos |
| `dissonancia` | a fita enroscando | a nota quebrada, a derrota, os dropouts | Efeitos |
| `ambiente` | laços longos e baixos | fogo, vento, o salão | Ambiente |
| `musica` | as faixas e os jingles de música | `mus_*`, `jin_vitoria` | Musica |

## O tratamento de fita

Todo som do gerador passa pelo tratamento antes de virar WAV. É ele que faz o
synthwave virar fita. Na ordem:

| passo | o que faz | número |
| --- | --- | --- |
| wow | o tom ondula devagar | 0,5 Hz, ±0,12 % (linha de atraso de ±0,38 ms) |
| flutter | o tom treme rápido | 9 Hz, ±0,05 % (±8,8 µs) |
| saturação | a fita comprime o pico | `tanh(1,8·x) / tanh(1,8)` |
| corpo | o grave da cabeça | +2 dB numa prateleira em 90 Hz |
| teto | a fita não guarda o agudo | passa-baixa em 12 kHz, 12 dB por oitava |
| chiado | o ruído da fita | rosa a −62 dBFS, com passa-alta em 2 kHz |
| dropouts | a fita falha | quedas de 30 ms a −18 dB, uma a cada 400 ms em média; **só na Dissonância** |

Três intensidades, escritas na receita como `--fita`:

| `--fita` | o que leva | quem usa |
| --- | --- | --- |
| `cheia` | todos os passos acima, menos os dropouts | metal, voz, mundo, corpo, fita, ambiente |
| `leve` | sem wow, flutter pela metade (±0,025 %), sem chiado | interface, reações, carimbos |
| `quebrada` | a cheia mais os dropouts | dissonância |

Quem navega num menu não quer ouvir a fita ondular a cada tique. As gravações
da Kenney de hoje entram cruas (`--cru`), como estão no jogo.

## A voz de cada cavaleiro

Cada lugar tem uma nota e um timbre. A nota é a mesma que o kit já mede (a
H04, `TOM_DO_LUGAR`, e a H07, `nota:<l>`). O timbre é o que muda de cor.

| lugar | cor | nota | Hz | grau | timbre | como se faz |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | ciano `#29e6ff` | Dó5 | 523,25 | tônica | o cristal | sino FM (portadora 1:1, moduladora 3,5:1, índice de 2,5 caindo a 0 em 400 ms) |
| P2 | magenta `#ff3ea5` | Ré5 | 587,33 | segunda | o pulso | onda de pulso a 25 %, passa-baixa em 3 kHz |
| P3 | limão `#d4ff4a` | Fá5 | 698,46 | quarta | a faísca | quadrada com salto de tom (começa 2 semitons acima e cai em 30 ms) |
| P4 | âmbar `#ee9a1e` | Sol5 | 783,99 | quinta | o bronze | duas serras desafinadas ±7 cents, passa-baixa em 2,2 kHz |

As razões são 1; 1,1225; 1,3348; 1,4983: as da H04.

**Por que tônica, segunda, quarta e quinta.** As 45 faixas são em tom menor.
A segunda, a quarta e a quinta cabem no menor natural sem choque; a terça e a
sétima maiores (Mi e Si sobre Dó menor) brigariam com a faixa em todo acerto.
Os quatro juntos fazem o **acorde da Forja**: Dó, Ré, Fá, Sol, um acorde
suspenso, que não é maior nem menor e por isso soa bem sobre qualquer faixa.

A assinatura (`ass_p{n}`, 400 ms) é a nota sozinha, com ataque de 5 ms e
queda exponencial (−60 dB em 400 ms). É a base de todo som da família voz.

### No tom da faixa

As notas são de Dó. Quando a faixa está noutro tom, a nota sobe ou desce pelo
`pitch_scale`, de −6 a +5 semitons: `pitch_scale = 2^(s/12)`. É a velocidade
da fita, e a fita ouve assim. Assim a nota do lugar é sempre a tônica, a
segunda, a quarta ou a quinta da faixa.

| tom da faixa | semitons | tom da faixa | semitons |
| --- | --- | --- | --- |
| Dó menor | 0 | Fá# menor | −6 |
| Dó# menor | +1 | Sol menor | −5 |
| Ré menor | +2 | Lá menor | −3 |
| Mi♭ menor | +3 | Si♭ menor | −2 |
| Mi menor | +4 | Si menor | −1 |
| Fá menor | +5 | | |

A ficha do minigame diz o tom da faixa (doc 04); sem tom, Dó. O alto-falante
do controle recebe a nota já transposta: o módulo sintetiza na frequência
pedida.

### O pio

Quando o controle entra no jogo, o cavaleiro pia: a nota do lugar e uma
segunda nota. O intervalo vem da cabeça escolhida, então dois cavaleiros do
mesmo lugar podem piar diferente. A tabela das cabeças, com o intervalo de
cada uma, está em [04 O cavaleiro](04-o-cavaleiro.md#as-peças).

| intervalo | id | o pio | semitons |
| --- | --- | --- | --- |
| a segunda | `segunda` | sobe uma segunda maior | +2 |
| a terça | `terca` | desce uma terça maior | −4 |
| a quarta | `quarta` | sobe uma quarta | +5 |
| a quinta | `quinta` | sobe uma quinta | +7 |
| a quinta de baixo | `quinta_baixo` | desce uma quinta | −7 |
| a oitava | `oitava` | sobe uma oitava | +12 |

O pio é um arquivo só (`pio_p{n}_{intervalo}`, 24 arquivos), porque o
alto-falante toca um som por vez: a nota do lugar de 0 a 120 ms, a segunda
nota de 100 a 300 ms, as duas no timbre do lugar. 300 ms ao todo. O pio
substitui o `PIO_DO_MODELO` da G01 e o `pio:<boneco>` da H07 (a H11 troca).

## O carimbo de cada julgamento

As palavras são as do doc [07](../07-narrativa-e-voz.md#o-vocabulário-do-visor):
«Ressonância!», «Afinado», «Quase». O erro não tem palavra. O carimbo visual
é do [07 VFX](07-vfx.md) e do HUD (G04).

O som de cada julgamento, por lugar (`jul_<julgamento>_p<n>`, 16 arquivos):

| julgamento | id | o som | duração |
| --- | --- | --- | --- |
| Ressonância! (perfeito) | `ressonancia` | a nota do lugar, limpa, com o transiente de metal da bigorna no ataque | 180 ms |
| Afinado (ótimo) | `afinado` | a nota com o brilho pela metade (as parciais altas a 0,5) | 150 ms |
| Quase (bom) | `quase` | a nota com passa-baixa em 1,2 kHz | 120 ms |
| erro | `erro` | a nota 60 cents abaixo, reduzida a 6 bits, com wow de 4 Hz, `--fita quebrada` | 220 ms |

O erro soa quebrado, não reprovado: é a nota do próprio cavaleiro saindo
desafinada. Ninguém ouve um «buzz» de erro.

No julgamento, os `jul_*` substituem a `nota:<l>` e a `nota_quebrada:<l>` da
H07 no alto-falante, e a `nota` e a `falha` da H04 na TV. Onde a nota é
instrumento e não julgamento (o coral do N3, a vida perdida do O2, do P3 e do
Relâmpago), a nota do módulo continua (`mod_nota_p{n}`,
`mod_nota_quebrada_p{n}`).

## Os carimbos do jogo

Os carimbos de [09 As reações](09-reacoes.md#os-carimbos-do-jogo), um som cada.
Tocam na TV no instante em que o carimbo bate, no barramento Voz.

| carimbo | id | o som | duração |
| --- | --- | --- | --- |
| `car_virada` | `jin_virada` | a fita acelerando (o tom sobe uma quarta em 300 ms), a martelada de 98 Hz e o acorde da Forja subindo em colcheias a 120 BPM (Dó, Ré, Fá, Sol, 250 ms cada) | 2000 ms |
| `car_em_chamas` | `car_em_chamas` | um sopro de fogo que sobe (ruído em passa-banda de 300 Hz a 3 kHz em 400 ms) e a `jul_ressonancia` do dono no fim | 600 ms |
| `car_por_um_fio` | `car_por_um_fio` | a fita esticando: um tom de 1 kHz que cai 50 cents e volta, com wow de 6 Hz | 700 ms |
| `car_liga` | `car_liga` | duas marteladas de metal em quinta (Dó5 e Sol5), 60 ms entre elas | 400 ms |
| `car_acorde` | `car_acorde` | as quatro `ass` juntas (o acorde da Forja) sobre a martelada de 98 Hz, cada nota a −12 dBFS | 1200 ms |
| `car_emburrado` | (nenhum) | o `fx_derrota` já toca no inserto; o carimbo não soma som | — |

Os oito adesivos tocam o `reacao_pop`.

## A vitória e a derrota

### A vitória: `fx_vitoria_p{n}`

- o arpejo maior 1-3-5-8 a partir da nota do lugar, uma oitava abaixo, em
  semicolcheias a 120 BPM (125 ms cada, 500 ms);
- depois o acorde maior do lugar, 500 ms, com a martelada de metal no ataque;
- 1000 ms no total, no timbre do cavaleiro;
- toca na TV e no alto-falante do vencedor, com o batimento duplo na vibração
  dele;
- entra 1 batida depois do `jin_apito`, e o `jin_vitoria` entra quando ele
  acaba.

O arpejo é maior porque a faixa já parou no apito: nada mais soa por baixo.
Cada lugar ganha com a própria voz. Quem ganhou ouve a si mesmo.

### A derrota: `fx_derrota`

- a parada da fita: o tom cai a 0,25× em 700 ms (curva exponencial) e o filtro
  fecha de 8 kHz a 400 Hz junto;
- aos 900 ms, o «plic» do carretel parando (um blip de 2 kHz, 15 ms);
- 1400 ms no máximo;
- toca no alto-falante do último colocado e na TV a −6 dB, durante o inserto
  dele ([01 O cinema](01-cinema.md#o-plano-de-cada-momento)), com a animação
  desacelerando junto ([05 O movimento](05-movimento.md)).

A derrota não tem a voz de ninguém: é a fita que desacelera. Quem perdeu ouve
uma piada de deck, não um «perdeu». É a regra do épico no peito e do riso no
corpo.

## Os jingles

Os jingles da H06. Todo jingle termina em parada seca, sem fade.

| slot | id | de onde sai | duração | quando |
| --- | --- | --- | --- | --- |
| `JIN_APITO` | `jin_apito` | `gerar_sons.py`: o clunk do STOP e um apito de 2093 Hz, 450 ms | 1000 ms | o fim de todo minigame; a música para em seco no clunk |
| `JIN_VITORIA` | `jin_vitoria` | `gerar_trilha.py`, 130 BPM, Mi menor, corte em 7 s | 7000 ms | o resultado com um vencedor, depois do `fx_vitoria_p{n}` |
| `JIN_COOP_VITORIA` | `jin_coop_vitoria` | `gerar_trilha.py`, prompt a escrever; até lá, o `vitoria_noite_0` | 5000 a 8000 ms | o coop em que todos vencem |
| `JIN_DERROTA` | `jin_derrota` | `gerar_trilha.py`, 90 BPM, Dó menor, corte em 5 s | 5000 ms | o coop em que ninguém venceu |
| `JIN_EMPATE` | `jin_empate` | `gerar_trilha.py`, 110 BPM, Lá menor, corte em 5 s | 5000 ms | o empate |
| `JIN_RECORDE` | `jin_recorde` | `gerar_trilha.py`, 140 BPM, Sol maior, corte em 3 s | 3000 ms | um recorde da noite |
| `JIN_ENTRADA` | `jin_entrada_tique` e `jin_entrada_vai` | `gerar_sons.py` | 2 compassos | a contagem |
| `JIN_VIRADA` | `jin_virada` | `gerar_sons.py` (o som do `car_virada`) | 2000 ms | a virada no placar |

**A entrada não é um arquivo de 2 compassos.** O relógio de áudio (H01) agenda
cada peça no tempo da faixa: no compasso de contagem, o `jin_entrada_tique`
(a martelada aguda de 1568 Hz, 120 ms) nos tempos 2, 3 e 4; no tempo 1 da
faixa, o `jin_entrada_vai` (a martelada de 98 Hz com o acorde da Forja, 400 ms)
junto com o impacto do `fx_entrada`. Um arquivo fixo escorregaria em toda
faixa que não fosse de 120 BPM.

O `jin_apito`, a entrada e a virada são WAV de `godot/assets/sons/`, não OGG
de `ost/jingles/`: precisam de corte exato na amostra. A síntese de apito,
derrota e empate que a H06 propõe fica como reserva enquanto o arquivo não
existe.

## A fita como som

| id | quando | o som | duração |
| --- | --- | --- | --- |
| `fx_play` | o PLAY no título | o clunk da tecla e o motor ganhando velocidade | 400 ms |
| `fx_stop` | a pausa, sair de uma faixa no meio | o clunk da tecla, o motor que para | 250 ms |
| `fx_entrada` | a entrada do minigame | o rasgo: ruído que sobe de 300 Hz a 6 kHz, e o impacto (martelada grave em 98 Hz) cravado em 600 ±5 ms | 900 ms |
| `fx_rebobinar` | repetir a faixa, recomeçar o treino | o guincho da fita voltando (banda de ruído de 400 a 2400 Hz subindo) e o clunk no fim | 900 ms |
| `fx_virar` | virar a fita, do lado A (S1 a S5) para o B (S6 a S9) | o eject, o plástico na mão, o clunk de entrar | 1600 ms |
| `fx_autostop` | o fim da fita | o clique seco do auto-stop | 200 ms |
| `fx_caneta` | a caneta escreve na etiqueta | o chiado do marcador no papel, três traços | 400 ms |

A entrada é agendada para que o impacto caia no tempo 1: o som começa 600 ms
antes do tempo 1, pelo relógio de áudio. O `fx_virar` dura 1600 ms dentro dos
2 compassos da transição ([06](06-interface-e-texto.md)).

## A interface

Curta, seca, de plástico. No alto-falante de quem fez e a −12 dB na TV.

| id | quando | duração |
| --- | --- | --- |
| `ui_tique` | navegar | 35 ms |
| `ui_confirma` | ✕ | 90 ms |
| `ui_volta` | ◯ | 90 ms |
| `ui_peca` | trocar uma peça do cavaleiro (o encaixe de metal) | 120 ms |
| `ui_trava` | travar uma parte (□) | 80 ms |
| `ui_sorteio` | sortear (△): uma roleta de 6 tiques que freia | 480 ms |
| `ui_tecla` | uma tecla do teclado do nome (G09) | 30 ms |
| `reacao_pop` | uma reação (o adesivo cola) | 120 ms |

`ui_peca` muda de altura conforme a parte: cabeça +7 semitons, superior +4,
inferior 0, arma ou amuleto −5, pelo `pitch_scale`.

Os `ui_*` substituem o `tique`, o `confirma`, o `volta` e o `seleciona` da
Kenney nas telas fora do minigame (G06, G09, G11). Dentro do minigame, os de
hoje ficam até a H11.

## O mundo e o corpo

**Os materiais.** A tabela do doc
[05](../05-haptica-e-controle.md#a-háptica-por-material) já vive no módulo
(`material:<nome>`, H07): metal, pedra, areia, gelo, grama, lama e madeira,
cada um com o som e a vibração da mesma onda, mandados aos atuadores. Os
passos (`passo:<chão>:<v>`, grama, cascalho, metal e água, três variações)
também. Na TV, o mundo é das gravações da Kenney de hoje.

**A falha na TV.** O `falha_0..2` de hoje são bipes de erro de interface: um
«buzz», que esta página proíbe. A falha física na TV vira som de corpo:

- `fx_tropeco_0..2`: um baque surdo de 90 Hz (60 ms) seguido de um boing
  curto de 300 a 120 Hz em 250 ms, com vibrato de 12 Hz; três variações de
  semente; 350 ms;
- `fx_boing`: o boing inteiro do cavaleiro que quica, 250 ms.

A troca do `falha` pelo `fx_tropeco` no jogo é da H11.

**O ambiente.** O `amb_salao` é o laço do salão (G06): o fogo da forja
(`sint_fogo`), o chiado de fita a −62 dBFS e um estalo de brasa a cada 1,7 s
em média, 8 s, fechado sem clique no laço. O fogo e o vento de hoje
(`sint_fogo`, `sint_vento`) ficam como estão.

## A música: o que cada seção pede

As faixas, o andamento e o tom são do doc 04. O que o som pede delas, além do
sufixo comum (os médios de 800 Hz a 4 kHz livres para o jogador, os
contratempos com espaço, começo e fim secos):

| seção | lado | o que a música deixa para o jogo |
| --- | --- | --- |
| S01 A Centelha | A | a bigorna é do jogador: a faixa marca o contratempo e deixa o tempo forte para a martelada |
| S02 A Viga | A | pouca percussão aguda: o gelo e o vidro do jogo ficam por cima; graves longos |
| S03 O Molde | A | metódica: os tempos 1 e 3 pesados são o carimbo do jogador, sem caixa por cima |
| S04 O Impacto | A | arena pesada: os golpes vêm por cima; o Ambiente sobe 3 dB no último terço |
| S05 A Galeria | A | seca, sem cauda de reverberação: o tiro é a percussão |
| S06 O Canto | B | o som é a pergunta: na pista, a música abaixa 12 dB por 1 tempo e volta em 300 ms; a sala O Canto toca sem música |
| S07 Os Caminhos | B | meio-tempo: os passos do jogador caem nas colcheias, o bumbo não pisa neles |
| S08 A Voz | B | o microfone ouve a sala: enquanto ele escuta, a música fica a −12 dB; a sala A Voz toca sem música |
| S09 A Prova | B | estádio: tudo junto, a torcida no Ambiente, o perfeito ainda abaixa 2 dB |

As telas: o título, a construção, o salão, o pódio, os créditos e o Relâmpago,
cada uma com o seu slot (doc 04, «As telas e os jingles»). O salão é a
harmonia do título sem bateria, para o `amb_salao` respirar; o pódio é o tema
do título em maior.

## O que toca onde

Três destinos (doc 04, «Os efeitos»):

| destino | o que vai | o que nunca vai |
| --- | --- | --- |
| **a TV** | tudo o que a sala inteira precisa ouvir: golpes, quedas, carimbos, jingles, a música, o ambiente | o som que é segredo de um jogador |
| **o alto-falante do controle** | o som pessoal do dono: o pio, o julgamento, a coleta, o clique de navegar, o segredo, a vitória do vencedor, a derrota do último | música, ambiente, laço contínuo |
| **os atuadores** | a textura: o chão, o material, o peso; WAV PCM de 60 a 180 Hz | o mesmo instante de um rumble no mesmo controle (doc 05, suspeita e) |

O alto-falante toca um som por vez. O novo corta o velho com rampa de 20 ms,
pela prioridade: vitória e derrota, depois julgamento, depois o segredo,
depois o pio, depois a coleta, depois o clique. Um de prioridade menor espera
o maior acabar ou é descartado.

## A mixagem

Hoje tudo toca no Master: não existe `godot/default_bus_layout.tres`. A H11
cria os barramentos.

| barramento | o que leva | pico de cada som | efeito no barramento |
| --- | --- | --- | --- |
| Musica | a trilha, os jingles de música | −6 dBFS | os abaixamentos abaixo |
| Efeitos | metal, mundo, corpo, dissonância, a fita grande | −6 dBFS | nenhum |
| Interface | `ui_*`, a fita pequena | −12 dBFS | nenhum |
| Voz | assinaturas, pios, julgamentos, vitória, carimbos | −9 dBFS (cada nota −12) | limitador em −3 dBFS |
| Ambiente | fogo, vento, salão, torcida | −18 dBFS | nenhum |
| Master | tudo | — | limitador em −1 dBFS |

Os quatro cavaleiros podem soar juntos: o limitador da Voz impede que quatro
perfeitos no mesmo quadro estourem.

### O que abaixa quando

| quando | o que muda | quanto | entra em | volta em |
| --- | --- | --- | --- | --- |
| um perfeito | Musica | −2 dB | 0 ms | 80 ms |
| um erro | Musica | passa-baixa em 600 Hz | 0 ms | abre em 300 ms |
| um combo de 8 | Musica | +1,5 dB | 0 ms | 2 s |
| o cartão do minigame | Musica | −6 dB e passa-baixa em 800 Hz | 67 ms | no tempo 1 |
| a pausa | Musica | −12 dB e passa-baixa em 500 Hz | 67 ms | 167 ms |
| a entrada | a música do salão | a zero | 600 ms, sob o rasgo | — |
| o apito | Musica | corte seco | 0 ms | — |
| o minigame | Ambiente | −6 dB | 1 s | 1 s depois do apito |
| o último terço | Ambiente | +3 dB | 2 s | no apito |
| a pista de S06 | Musica | −12 dB | 17 ms | 300 ms |
| o microfone ouvindo (S08) | Musica | −12 dB | 17 ms | 300 ms |
| o inserto da derrota | `fx_derrota` na TV | −6 dB | — | — |
| uma reação | `reacao_pop` | −18 dB | — | — |
| a interface na TV | `ui_*` | −12 dB | — | — |

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
| `ass_`, `pio_` | 400 ms |
| `car_` | 1200 ms |
| `fx_` | 1600 ms |
| `jin_` (os do `gerar_sons.py`) | 2000 ms |
| `amb_` | 8000 ms |

Os jingles de música (`jin_vitoria`, `jin_derrota`, `jin_empate`,
`jin_recorde`, `jin_coop_vitoria`) seguem o formato da trilha (OGG, 48 kHz,
estéreo, doc 04), com o corte do `trilha_prompts.json`. As gravações da Kenney
ficam com o pico medido, escrito no mapa.

O portão da [12](12-portoes.md) roda `gerar_sons.py --conferir`, que confere
tudo isso e cada linha do mapa.

## O gerador

`godot/estudos/direcao/som/gerar_sons.py`, só com a biblioteca padrão do
Python (`wave`, `math`, `random`, `struct`, `argparse`, `csv`, `subprocess`).

- `python3 gerar_sons.py` escreve todos os WAV desta página em
  `godot/assets/sons/`;
- `--so fx_vitoria_p1` escreve um só; `--so 'jul_*'` escreve uma família;
- `--lista` imprime o id, a família e a duração de cada um, sem escrever;
- `--conferir` lê os WAV de `godot/assets/sons/` e as linhas do mapa e
  confere o formato, o teto, a duração (±5 %) e o pico; sai com código 1 se
  algum falhar;
- `kenney "<pacote>/Audio/<arquivo>.ogg" <id> [--cru]` converte uma gravação
  da Kenney de `oficina/kenney/3.7.0/Audio/` para WAV 48 kHz mono 16 bits pelo
  ffmpeg; sem `--cru`, aplica o tratamento `leve`;
- tudo com semente fixa: rodar duas vezes dá os mesmos bytes.

Só o subcomando `kenney` precisa do ffmpeg. O gerador nunca toca som.

As receitas no mapa usam estes parâmetros: `--fita cheia|leve|quebrada`,
`--lugar 1..4`, `--intervalo <id>`, `--semente <n>`.

## O casamento evento por evento

Som, vibração e gatilho saem no mesmo quadro (16,7 ms). A vibração usa o piso
do [doc 05](../05-haptica-e-controle.md#o-piso-de-força) (forte / fraco /
duração). O gatilho usa os quatro modos de `forja.gd` (Off, Resistência, Arma,
Vibração); «—» é nenhuma mudança.

| evento | na TV | no alto-falante do dono | a vibração do dono | o gatilho |
| --- | --- | --- | --- | --- |
| navegar | `ui_tique` a −12 dB | `ui_tique` | toque: 0 / 0,45 / 60 ms | — |
| confirmar (✕) | `ui_confirma` a −12 dB | `ui_confirma` | toque: 0 / 0,45 / 60 ms | — |
| voltar (◯) | `ui_volta` a −12 dB | `ui_volta` | toque: 0 / 0,45 / 60 ms | — |
| trocar uma peça | `ui_peca` | `ui_peca` | metal: pulso de 150 Hz nos atuadores, 40 ms | — |
| trocar a arma ou o amuleto | `ui_peca` a −5 semitons | `ui_peca` a −5 semitons | o pulso do item na mão: acerto, 0,3 / 0,6 / 80 ms | o do item, para sentir o peso na hora ([06b](../06b-a-construcao-do-cavaleiro.md)) |
| travar uma parte | `ui_trava` | `ui_trava` | toque: 0 / 0,45 / 60 ms | — |
| uma das 8 marteladas da forja | `martelo_*` | — | acerto: 0,3 / 0,6 / 80 ms | — |
| sortear | `ui_sorteio` | — | 6 toques que freiam: 0 / 0,45 / 30 ms cada | — |
| o controle entra | `pio_p{n}_{intervalo}` | o mesmo pio | toque: 0 / 0,45 / 60 ms | Off |
| Ressonância! | `jul_ressonancia_p{n}`, a música −2 dB | `jul_ressonancia_p{n}` | perfeito: 0,5 / 0,8 / 100 ms | — |
| Afinado | `jul_afinado_p{n}` | `jul_afinado_p{n}` | acerto: 0,3 / 0,6 / 80 ms | — |
| Quase | `jul_quase_p{n}` | `jul_quase_p{n}` | acerto: 0,3 / 0,6 / 80 ms | — |
| erro | `jul_erro_p{n}` e `fx_tropeco_*`, a música abafa | `jul_erro_p{n}` | erro: 0,7 / 0,3 / 160 ms | — |
| coleta | o som do minigame | `mod_coleta` | acerto: 0,3 / 0,6 / 80 ms | — |
| golpe recebido, queda | `golpe_*` | `golpe_*` | golpe: 1,0 / 0,6 / 250 ms, do lado do golpe | Resistência 2, 4 por 250 ms |
| explosão, fim de rodada | `pedra_*` ou `sino_*` | — | explosão: 1,0 / 1,0 / 400 ms | Off |
| aviso de perigo | — | o segredo do minigame | aviso: 0,6 / 0 / meio tempo | Vibração 0, 4, 8 por meio tempo |
| tiro | `tiro_*` | `tiro_*` | acerto: 0,3 / 0,6 / 80 ms | Arma 2, 6, 8 |
| sem munição | `vazio_0` | — | toque: 0 / 0,45 / 60 ms | Resistência 1, 8 |
| recarga | `recarga_0` | `recarga_0` | metal: pulso de 150 Hz, 40 ms | Off |
| um passo | — | — | `mod_passo_<chão>_<v>` nos atuadores | — |
| um material | o som do minigame | — | `mod_material_<nome>` nos atuadores | — |
| PLAY | `fx_play` | — | fita: 0 / 0,3 / 400 ms | — |
| a entrada | `fx_entrada`, o impacto no tempo 1 | `jin_entrada_vai` no tempo 1 | golpe: 1,0 / 0,6 / 250 ms, no tempo 1, em todos | Off |
| a contagem | `jin_entrada_tique` nos tempos 2, 3, 4 | — | toque: 0 / 0,45 / 60 ms, em todos | — |
| o apito | `jin_apito`, a música corta | — | um pulso forte em todos: 1,0 / 0 / 120 ms | Off em todos |
| a vitória | `fx_vitoria_p{n}`, depois `jin_vitoria` | `fx_vitoria_p{n}` | batimento duplo: 1,0 / 0,6 / 120 ms, pausa de 120, 0,7 / 0,4 / 120 ms | — |
| a derrota (o último) | `fx_derrota` a −6 dB | `fx_derrota` | rumble: 0,6 / 0,6 caindo a 0 em 700 ms | — |
| um carimbo do jogo | `car_*` ou `jin_virada` | — | acerto: 0,3 / 0,6 / 80 ms, no dono | — |
| uma reação | `reacao_pop` a −18 dB | `reacao_pop` | toque: 0 / 0,45 / 60 ms | — |
| a pausa | `fx_stop`, a música −12 dB | — | — | Off em todos |
| rebobinar | `fx_rebobinar` | — | fita: 0 / 0,3 / 900 ms | — |
| virar a fita | `fx_virar` | — | fita: 0 / 0,3 / 1600 ms, em todos | — |
| o auto-stop | `fx_autostop` | — | toque: 0 / 0,45 / 60 ms, em todos | — |
| a caneta | `fx_caneta` | — | — | — |

A vibração de fita (rumble fraco a 0,3) não está no piso do doc 05: é nova
desta página. O F05 (o háptico forte) e o F10 (o rumble seco) medem se ela se
sente; se não, sobe para 0,45, o piso do toque.

## O som das fichas G

A G05 (a câmera), a G10 (a biblioteca Kenney de modelos), a G14 (a cor e a
letra) e a G15 (a luz) não tocam som. As outras fichas G que hoje não tocam
nada ganham estes:

| ficha | os sons |
| --- | --- |
| G04 O HUD | os `jul_*` (o carimbo), os `car_*`, o `reacao_pop`, o `jin_virada` |
| G06 O salão | o `amb_salao`, os `ui_*`, o `jin_recorde` |
| G07 A narrativa | o `fx_caneta`, o `fx_virar`, o `fx_autostop`, os `car_*` |
| G08 Os bonecos | os `pio_*`, o `fx_boing` |
| G11 A interface | os `ui_*`, o `reacao_pop` |
| G13 O cavaleiro montável | os `ui_*` da montagem, os `pio_*` (a cabeça escolhe o intervalo), o `car_liga`, as 8 marteladas, o `fx_caneta` do nome |
| G16 O virar da fita | o `fx_virar`; a opção Reações cala o `reacao_pop` (Só do jogo) e os `car_*` (Nenhuma) |

## O que esta página pede a outras cabeças

- **O diretor de arte:** o [README da arte](README.md) e a página ainda dizem
  «Dó, Mi, Sol e Si» e «Dó com sétima maior»; passam para Dó, Ré, Fá e Sol, o
  acorde da Forja suspenso. O `08-haptica.md` que o README (linhas 101 e 131)
  e o 07 VFX (linha 155) citam não existe: o casamento do som com a vibração e
  o gatilho mora aqui, e os três links passam para
  [o casamento evento por evento](#o-casamento-evento-por-evento).
- **O produtor:** escrever o `gerar_sons.py` (com o `kenney` e o
  `--conferir` que lê o mapa) e o prompt do `JIN_COOP_VITORIA` no
  `trilha_prompts.json`; o LEIA-ME de `ost/` passa a dizer que `JIN_APITO`,
  `JIN_ENTRADA` e `JIN_VIRADA` são WAV de `assets/sons/`.
- **O roteirista:** a ficha H11, «o som da bíblia no jogo»: os barramentos
  (`default_bus_layout.tres`), os abaixamentos, o tom da faixa no
  `pitch_scale`, os pios da G01 e da H07 trocados pelos `pio_p{n}_*`, a nota e
  o erro da H04 e da H07 pelos `jul_*`, a falha da TV pelo `fx_tropeco_*`, os
  jingles e a agenda da entrada.
- **O arquiteto:** o portão do mapa (toda linha com receita, todo arquivo
  presente nas linhas «gerado» e «no jogo») entra na [12](12-portoes.md).
