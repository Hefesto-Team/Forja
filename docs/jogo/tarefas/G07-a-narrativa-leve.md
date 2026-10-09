# G07 — A narrativa leve

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F07 (a maiúscula), F09 (a prova visual), G01 (`play_ms`, `Lente`, o cassete do título), G02 (`ForjaPlayer.nome`), G03 (`errou`, `Itens`), G04 (`Visor`, `julgar`, `falou`, `carimbou`), G05 (`_lente()`), G06 (o aviso do recorde), G14 (os tokens e as fontes) · **Usado por:** H04 (o kit passa o desvio a `julgar`)

## Por quê

A noite não tem história. O vencedor de cada faixa aparece numa tabela e
some; o último não tem cara; a virada do placar é uma palavra rosa; a noite
acaba num pódio com «Outra partida» e ninguém guarda nada. A bíblia pede o
contrário: falas curtas e raras ligadas ao que acabou de acontecer, o
resultado filmado (o vencedor de baixo, o último emburrado num close), e o
fim da fita: o encarte com cada faixa e quem venceu, na caneta, e o
contador parado no tempo real da noite. É o que faz o grupo lembrar da
noite no dia seguinte.

## Ler antes

- [07 — as falas e o vocabulário do visor](../07-narrativa-e-voz.md#as-falas)
- [01 — os créditos são o encarte e o fim da fita](../arte/01-cinema.md#os-créditos-são-o-encarte)
- [09 — os carimbos do jogo](../arte/09-reacoes.md#os-carimbos-do-jogo)

Os números do 01 (o resultado, o inserto), do 03 (os sons e a háptica de
cada evento), do 05 (as poses) e do 06 (as transições) estão copiados nas
partes abaixo.

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/falas.gd` e `.uid` (novo, `class_name Falas`) | — |
| `godot/scripts/ui/encarte_da_noite.gd` e `.uid` (novo, `class_name EncarteDaNoite`) | — |
| `godot/scripts/salas/sala_jogo.gd` (as falas no `julgar`, o fim filmado, `_celebrar`) | **G03** (`errou`), **G04** (`julgar`), **G06** (`erros_do_grupo`), **H04** |
| `godot/scripts/main.gd` (a pose e a lente do fim, o pódio, os créditos, o fim da fita) | **G01, G02, G03, G04, G05, G06, G08** |
| `godot/scripts/ui/placar.gd` (`virou`, as dicas do pódio) | **G14** |
| `godot/scripts/ui/visor.gd` (o desenho do `car_emburrado`) | **G04**, **G13** |
| `godot/scripts/ui/desenho.gd` (`cara_emburrada`) | **G01, G04, G06, G11, G12, G13, G14, G16** |
| `godot/scripts/ui/tela_titulo.gd` (`desenhar_cassete`, estática) | **G01**, **G14** |
| `godot/scripts/musica.gd` (a faixa sintetizada dos créditos) | **G06**, **H05** |
| `godot/scripts/traducoes.gd` | **G04, G06, G09, G11, G16** |
| `godot/assets/sons/` (6 WAV) e `docs/jogo/audio/mapa.csv` | **G01, G03, G04, G06, G11, G12, G16** |
| `docs/jogo/13-arquitetura.md` (o kit: `julgar` com o desvio; o registro `fala`) | **G04**, **H04** |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |

## Como se joga

Ninguém aperta nada a mais. A narrativa acontece em quatro lugares:

| onde | o que acontece | quanto dura |
| --- | --- | --- |
| durante a faixa | uma fala curta acima do cavaleiro, ligada a um evento | 2 s; no máximo 1 a cada 20 s por lugar e 1 na tela |
| o fim da faixa | o plano do vencedor, o inserto do último, depois a tabela de hoje | 4 batidas + 1 batida, e a tabela |
| o placar | «VIRADA!» carimbado quando o líder muda | 2 batidas |
| o fim da noite | ✕ no pódio fecha a fita: o encarte da noite, depois o fim da fita | uma faixa por compasso a 90 BPM, e até ✕ ou ◯ |

No fim da fita: ✕ «Gravar outra noite» começa outra partida do mesmo
tamanho e zera o contador; ◯ «Ejetar» volta ao título. O ◯ no pódio continua
voltando ao salão (a noite segue).

## A cena

### O fim da faixa (01: o resultado e o inserto)

`b = 60 / Ritmo.bpm` (com `Ritmo.bpm` 0, 120). A partir do apito
(`fase == "fim"`, `t_fase = 0`):

| tempo | plano | lente | o que se vê |
| --- | --- | --- | --- |
| 0 a 4 b | o resultado | 50 mm | o vencedor de baixo (contra-plongée de 8°), a câmera girando 15° em volta dele, `ENTRA_SAI` |
| 4 b a 5 b | o inserto (só se há último) | 85 mm | o rosto do último, à altura dos olhos, parado; ele senta (`sit`) |
| 5 b em diante (4 b sem inserto) | a câmera da sala, corte seco | a da sala | a tabela de hoje (`TelaResultado`), como hoje |

**Quem é quem** (`SalaJogo`, puras, a prova chama):

- **o vencedor** (`vencedor_do_fim()`): fora do coop, `colocacao[0]` se
  `pontos > 0` e o segundo tem menos pontos; senão `-1` (empate em cima ou
  ninguém pontuou).
- **o último** (`ultimo_do_inserto()`): fora do coop, com 2 ou mais em
  `jogando`, o último de `colocacao` se ele tem menos pontos que o penúltimo
  e não é o vencedor; senão `-1` (sem inserto).
- **por um fio** (`por_um_fio()`): há vencedor, o segundo tem pontos > 0 e
  `pontos[1º] − pontos[2º] <= 0.02 * pontos[1º]`.

**A pose do resultado** (`main.gd`, `_pose_do_fim`): o alvo é o vencedor
`+ (0, 1,1, 0)` (o peito: o cavaleiro tem 1,51 m com `ESCALA` 2). `dir` é a
horizontal do alvo para a `sala.camera_pos`, girada em volta do eixo y por
`lerpf(-7.5, 7.5, k)` graus, com `k = (1 − cos(PI · clampf(t_fase / (4 b), 0, 1))) / 2`
(`ENTRA_SAI`). A distância `d` = 5,2 m (a 50 mm, 27° de vertical, 2,5 m de
altura no quadro: o cavaleiro ocupa 60 %). A câmera fica em
`alvo + dir · d · cos(8°) − (0, d · sin(8°), 0)` e olha o alvo. Sem
vencedor (coop, empate, zero), o alvo é o centro dos que jogam
`+ (0, 1,1, 0)` e `d = maxf(5.2, 2.4 · r + 1.2)`, com `r` a maior distância
de um deles ao centro (a 50 mm, meia largura de 0,42 · d: todos cabem).
Com o movimento reduzido (`not Opcoes.tremor` até a G16;
`Opcoes.movimento == 1` depois), `k` fica em 0,5: sem giro.

**A pose do inserto:** o alvo é o último `+ (0, 1,3, 0)` (a cabeça); a
câmera em `alvo + dir · 3,2` (a 85 mm, 16,1° de vertical, 0,9 m no quadro:
rosto e ombros), à altura do alvo. No começo do inserto,
`jogadores[ultimo].olhar_para(posição da câmera)` e
`gesto("sit", b + 0.7)` (05: o último senta, 700 ms).

**O corte:** quando `plano_do_fim()` muda, o main copia a pose direto em
`_cam_pos` e `_cam_olhar` (corte seco, como o `_trocar` já faz); nunca
desliza de um plano a outro.

O contra-luz do vencedor (07: 0,8 por 4 batidas) é da G15: esta ficha não
põe luz.

### O placar

Quando `_virada` (o código de hoje decide) e `_t >= T_LIDER`: sai o
«Virada!» em `Tema.ROSA`; o placar emite `virou(l, ponto_da_virada())` e o
main chama `visor.bater(l, "car_virada", ponto)`. `ponto_da_virada()` é o
centro do canto direito do cabeçalho: `Vector2(r.end.x − 48 − 170, r.position.y + 70)`,
com `r` o retângulo do placar (`_retangulo()`, extraído do `_draw`).

### O encarte da noite (os créditos)

`EncarteDaNoite extends Control`, a tela inteira (1920×1080 lógicos):

- **A entrada:** do pódio, um fade para `FITA` de 1 compasso do pódio
  (130 BPM: 1846 ms), `Color(Tema.FITA, a)` com `a` de 0 a 1, `RETA` (06).
- **O papel:** uma tira `ETIQUETA` de y 200 a 880 (680 px), com a sombra
  `SOMBRA` deslocada (5, 7), que entra pela direita (x 1920) e anda para a
  esquerda a 560 px por compasso de 90 BPM (2667 ms: 210 px/s), `RETA`, sem
  parar: o travelling lateral do 01 em 2D (o 06 manda o fundo `FITA`).
- **Uma faixa a cada 560 px**, na ordem de `partida.historico`:

| peça | posição no painel (a partir do canto de cima à esquerda) | como |
| --- | --- | --- |
| a tarja | (0, 14), 560 × 12 | `Tema.tinta_da_secao(n)`, `n = Musica.SALA_DA_SECAO.find(e.sala)` |
| o número | (40, 120), linha de base | VT323 64, `TINTA_SUAVE`, `"%02d" % (i + 1)` |
| o nome do minigame | (40, 250) | Archivo Narrow 600 de 56, `TINTA`, `Desenho.caber` até 480 px (`e.nome`) |
| quem venceu | (40, 420) | Permanent Marker 74 em `Tema.JOGADOR[l]`, o `nome` do cavaleiro (`jogadores[l].nome`; vazio: «P%d»), `Desenho.caber` até 480 px |
| o P# | (40, 500) | VT323 40, `TINTA_SUAVE`, «P%d» (a cor nunca sozinha, 10) |

  Quem venceu a faixa: o lugar com `e.colocacao == 1` e pontos > 0. Dois ou
  mais com `colocacao == 1`: «Empate» em `TINTA`, sem P#. Ninguém com
  pontos: «Ninguém» em `TINTA_SUAVE`, sem P#.
- **A caneta:** quando o painel tem a borda esquerda em x ≤ 1200, o nome de
  quem venceu se escreve da esquerda para a direita em 400 ms, por recorte
  (06: nunca letra por letra), com `fx_caneta`.
- **O lado B:** com 2 ou mais faixas, antes da faixa de índice
  `ceili(n / 2.0)`, um painel de 360 px: duas tarjas de 7 px com 4 px de vão
  em (0, 14), em `TINTA`, e «Lado B» em Permanent Marker 74, `TINTA`, em
  (40, 380). (A mesma regra da `partida.lado()` da G12.)
- **O fim:** quando a borda direita do papel passa de x 96, ou com ✕ de
  qualquer lugar ocupado, começa o cross-fade de 1 compasso de 90 BPM
  (2667 ms) para o fim da fita: o encarte de 1 a 0, o deck de 0 a 1 (06).

### O fim da fita

O deck parado, frontal, no fundo `FITA`, com o mesmo cassete do título
(G01: `Rect2(400, 170, 1120, 690)`, a etiqueta, o logo, «A FORJA», a janela,
o pé). `TelaTitulo.desenhar_cassete(ci, giro, esquerda, direita, linha, recorte)`
sai do `_draw` do título (os números da G01, sem mudar nenhum) para os
dois usarem:

| o quê | no fim da fita |
| --- | --- |
| o mostrador | um quadrado de 40 × 40 em (100, 72) e «STOP» em (156, 62); à direita, «SP  H:MM:SS» alinhado em x 1820, y 62; VT323 60, `Color(Tema.ETIQUETA, 0.9)` |
| o contador | o tempo real da noite, parado: `(fim_ms − play_ms) / 1000`, `"%d:%02d:%02d"`; `fim_ms` é o `Time.get_ticks_msec()` do auto-stop; com `play_ms < 0`, conta do `_ready` do main |
| os carretéis | parados (`giro` 0); a fita toda no da direita: `esquerda` 0,0, `direita` 0,95 |
| a linha da etiqueta | a data no lugar de «Nove salas, quatro cavaleiros», Permanent Marker 40, `TINTA`, escrita por recorte em 400 ms: `"%d %s %d" % [dia, Traducoes.traduzir(MES[mes − 1]), ano]`, `MES := ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]` |
| as saídas | duas caixas `Desenho.caixa` `ETIQUETA` raio 14: `Rect2(520, 920, 520, 82)` com `dica("cruz", "Gravar outra noite", true)` e `Rect2(1100, 920, 300, 82)` com `dica("circulo", "Ejetar", true)`, Archivo 700 44, `TINTA` |

A ordem, a partir do começo do cross-fade (t = 0):

| t | o que acontece |
| --- | --- |
| 0 | `Musica.calar()` (o fade de 0,8 s de hoje) |
| 1 compasso (2667 ms) | `fx_autostop`, o toque em todos, o contador para (`fim_ms`) |
| + 1 batida de 90 (667 ms) | `fx_caneta`; a data se escreve em 400 ms |
| + 400 ms | as duas saídas aparecem, em corte (nada pisca, nada sobe: 01) |

✕ e ◯ só valem depois que as saídas aparecem.

## O som

O encanamento, igual nas fichas G01, G03, G04, G06, G09, G11, G12 e G16 (se
outra ficha já fez, usar o dela): copiar `<id>.wav` de
`godot/estudos/direcao/som/` para `godot/assets/sons/<id>.wav`;
`"$GODOT" --headless --path godot --import --quit` e conferir
`compress/mode=0` no `.import`; `Som.tocar` e `Som.no_controle` tocam
primeiro `res://assets/sons/<nome>.wav` quando ele existe. A linha do mapa
ganha `arquivo` = `godot/assets/sons/<id>.wav` e `estado` = `no jogo`.

| quando | id | onde | volume |
| --- | --- | --- | --- |
| 1 batida depois do apito, com vencedor | `fx_vitoria_p{n}` (1000 ms, o arpejo do lugar) | TV na posição do vencedor e o alto-falante dele | −9 dB; ganho 0,85 |
| o começo do inserto | `fx_derrota` (1400 ms, a fita que desacelera) | TV e o alto-falante do último | −6 dB; ganho 0,85 |
| o coop perdido, 1 batida depois do apito | `fx_derrota` | TV | −6 dB |
| `car_por_um_fio`, `car_virada` | `car_por_um_fio`, `jin_virada` | TV, pelo `Visor.bater` (G04) | −9 dB |
| `car_emburrado` | nada: o `fx_derrota` já toca (03) | — | — |
| a caneta no encarte e no fim da fita | `fx_caneta` (400 ms) | TV | −6 dB |
| o auto-stop | `fx_autostop` (200 ms) | TV | −6 dB |
| o encarte | `mus_creditos` (90 BPM, Lá menor): `Musica.tocar("creditos")` | TV | `Musica.VOLUME_DB` |

- Copiar 6 arquivos: `fx_vitoria_p1.wav` a `fx_vitoria_p4.wav`,
  `fx_derrota.wav`, `fx_autostop.wav`; e `fx_caneta.wav` se a G04 ainda não
  o trouxe.
- `mus_creditos` é OGG «a fazer» (H05). Até lá, `Musica.FAIXAS` ganha
  `"creditos": [57, 90, 0]` (Lá, 90 BPM, energia 0): a trilha sintetizada
  no andamento certo. Hoje `tocar("creditos")` cai no salão.
- O `fx_virar` é da G16 (o virar da fita). Os `jul_*`, `car_em_chamas` e
  `car_acorde` são da G04.
- O `Som.tocar("sucesso")` do `_celebrar()` (`sala_jogo.gd:383`) fica só no
  coop vencido e no empate.

## O controle

| evento | para quem | vibração (forte/fraco/ms) | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- | --- |
| a vitória da faixa | o vencedor | batimento duplo: 1,0/0,6/120, pausa de 120, 0,7/0,4/120 | não muda | não muda | `fx_vitoria_p{n}` | não se usa |
| o coop vencido | os que jogam | o mesmo batimento duplo | não muda | não muda | nada | não se usa |
| o inserto | o último | rumble 0,6/0,6 caindo a 0 em 700 ms (7 degraus de 100 ms: `0.6 · (7 − k) / 7`) | não muda | não muda | `fx_derrota` | não se usa |
| o coop perdido | os que jogam | o mesmo rumble | não muda | não muda | nada | não se usa |
| `car_por_um_fio`, `car_virada` | o dono | acerto 0,3/0,6/80 (o `Visor.bater` da G04) | não muda | não muda | nada | não se usa |
| o auto-stop | todos os ocupados | toque 0/0,45/60 | não muda | não muda | nada | não se usa |
| uma fala | ninguém | nada | nada | nada | nada | não se usa |

Sem o controle na mão: `_perc(l)` (`Forja.ctl.percepcao(Forja.pad_do_lugar(l))`)
traz `forte` e `fraco`; `Forja.som_virtual(l).falante` mede o alto-falante.

## O cavaleiro

- **Os stats:** nada daqui lê nem muda stat.
- **O nome** (`ForjaPlayer.nome`, G02) vai ao encarte; nome próprio, não
  traduz.
- **As poses** (05): o vencedor faz o `emote-yes` de hoje (`_celebrar`); o
  último senta no inserto (`sit`). As outras poses do 05 (o `jump` × 2 do
  vencedor) são da ficha do movimento, não desta.
- **O item:** o Diapasão puxa a fala «Deixa comigo o refrão!» (abaixo).

## As reações

Esta ficha dispara três carimbos da G04 (`Visor.bater`):

| id | quando | onde |
| --- | --- | --- |
| `car_por_um_fio` | 1 batida depois do apito, se `por_um_fio()` | vaga 1 do vencedor |
| `car_emburrado` | o começo do inserto | vaga 1 do último; some no corte do fim do inserto (`visor.vivos` sem ele) |
| `car_virada` | `_t >= T_LIDER` no placar, com `_virada` | `ponto_da_virada()` |

**A cara emburrada** (09: «a cara de fita de 160 px, em tinta, carretéis
meio fechados e a janela virada para baixo»), `Desenho.cara_emburrada(ci, centro, cor)`,
que o `Visor` chama para o `car_emburrado` no lugar da palavra, com as
fases do carimbo (bate 1,35 a 1,0 em 80 ms `MOLA`, −4°; sem respingos):

| peça | medida (px, a partir do centro) | cor |
| --- | --- | --- |
| a chapa | caixa de 160 × 104, raio 14, deslocada (9, 9) | `FITA` |
| o corpo | caixa de 160 × 104, raio 14, borda de 6 | fundo `FITA`, borda `cor` (a do dono) |
| os olhos | dois círculos de raio 18 em (−40, −10) e (40, −10), borda de 6; a metade de cima coberta por `FITA` e uma linha de 6 px em y −10 (a pálpebra) | `cor` |
| a boca | a janela: um arco de 64 px de largura, 6 px, centro em (0, 44), aberto para baixo (de 200° a 340°) | `cor` |

**A fala e o carimbo** dividem a vaga 1 (09: um dos dois): com
`car_por_um_fio`, o vencedor não fala.

**O recorde:** a G06 já avisa «Recorde da noite: P#» com o `jin_recorde`.
Esta ficha não põe «Recorde!» acima do cavaleiro: dois avisos do mesmo
evento, não.

O adesivo (a roda de reações) não tem ficha ainda: o encarte e o fim da
fita não o desenham.

## A diversão

**O momento:** o apito. A câmera desce e gira devagar em volta do P2, que
venceu por 1 ponto: «POR UM FIO» bate acima dele e o controle dele bate
duas vezes. Corte: o rosto do P1, que ficou em último, senta, a cara de fita
emburrada aparece e o controle dele desmaia na mão. Todo mundo ri, o P1
inclusive. No fim da noite, o encarte passa com os nomes de cada um na
caneta e o contador para em `1:47:12`. **Como se confere:**

1. A prova (sem o controle na mão): `plano_do_fim()` é «resultado» no apito
   e «inserto» em 4 batidas; `camera.fov` é `Lente.fov(50)` e depois
   `Lente.fov(85)`; `visor.do_lugar(último)` tem o `car_emburrado`;
   `_perc(vencedor).forte` chega a 1,0 e `_perc(último).forte` a 0,6.
2. A prova: `por_um_fio()` com `[100, 99, 0, 0]` e não com `[100, 97, 0, 0]`.
3. A prova: o encarte tem uma linha por faixa e o «Lado B»; o fim da fita
   mostra o contador e as duas saídas; o auto-stop dá 0,45 de fraco em
   todos.
4. A prancha (F09): o plano do resultado e o do inserto ao lado do
   `docs/imagens/direcao/` do resultado; o encarte; o fim da fita.

## O estado de hoje

- Não há falas nem vocabulário de julgamento
  (`grep -rn "Ressonância\|Afinado" godot/scripts` não acha nada antes da
  G04).
- `godot/scripts/salas/sala_jogo.gd`:
  - `terminar()` (336-362): `fase = "fim"`, `colocacao = vencedor()`, o
    apito, `Musica.calar()`;
  - `vencedor()` (366-374): os lugares de `jogando`, do maior ponto ao
    menor, empate pelo menor lugar;
  - `_celebrar()` (378-383): `emote-yes`, as faíscas e `Som.tocar("sucesso")`;
  - `_quadro_fim()` (407-419): celebra em `TelaResultado.APITO_S` (0,5 s),
    avança sozinho em `AVANCA_S` (6 s), ✕ depois de 0,8 s.
- `godot/scripts/main.gd`:
  - `_quadro_sala()` (713-719): abre o `resultado` assim que a fase é «fim»;
  - `_pose_da_camera()` (925-957): `"sala"` devolve a pose da sala;
  - `_quadro_podio()` (483-512): ✕ começa outra partida, ◯ volta ao salão;
  - `_quadro_titulo()` (575-589): △ abre `creditos` (a `TelaCreditos` de
    quem fez o jogo; fica como está).
- `godot/scripts/ui/placar.gd`: `_virada` (abrir, 36-47); `_sons()` (89-100)
  toca «placar» na virada; `_draw()` (118-214) escreve «Virada!» em
  `Tema.ROSA` no cabeçalho; as dicas do pódio «Outra partida» e «Voltar ao
  salão» (208-210).
- `godot/scripts/ui/tela_creditos.gd` (42 linhas): o logo e «Hefesto Team».
  Não há encarte nem fim da fita.
- `godot/scripts/musica.gd:11-23`, `FAIXAS`: sem `"creditos"`;
  `TELAS.creditos` (179) aponta para `MUS_TELA_CREDITOS`.
- `godot/scripts/partida.gd:100-112`: `historico` guarda `sala`, `nome`,
  `pontos`, `colocacao`, `ganhos` de cada faixa.
- Ninguém toca `fx_vitoria_p*`, `fx_derrota` nem `fx_autostop`
  (`grep -rn "fx_vitoria\|fx_derrota\|autostop" godot/scripts`); no mapa,
  `gerado`.

## O alvo

### As frases (`godot/scripts/falas.gd`, `class_name Falas extends RefCounted`, estático)

```gdscript
## A numeração do julgamento do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const ERRO := 0
const BOM := 1
const OTIMO := 2
const PERFEITO := 3
const INTERVALO_S := 20.0   ## uma fala a cada 20 s por lugar (07)
const DURACAO_S := 2.0      ## quanto a fala fica na tela; nunca duas ao mesmo tempo
const ARRASTA_S := 0.060    ## três toques seguidos acima de +60 ms: «arrastando»
const CORRE_S := -0.040     ## três abaixo de −40 ms: «correndo»
const TODOS_S := 1.5        ## todos erraram dentro de 1,5 s
const DO_EVENTO := {
	"combo_equipe": ["Frequência travada!", "Ninguém nos apaga!"],
	"arrastando": ["Segura menos!", "Vai com o baixo!"],
	"correndo": ["Calma, espera o bumbo!"],
	"todos_erraram": ["Tá tudo desafinado!"],
	"voltou": ["De novo, do começo."],
	"ajudou": ["Deixa comigo o refrão!"],
	"vencedor": ["Faltou ginga pra eles.", "A forja canta de novo."],
}
## A palavra do visor. No treino, o que não é perfeito diz o lado:
## «Cedo» (desvio < 0) ou «Tarde» (desvio > 0); desvio 0 fica com a palavra do julgamento.
static func do_julgamento(j: int, no_treino := false, desvio_s := 0.0) -> String:
	if j == ERRO:
		return ""
	if no_treino and j != PERFEITO and desvio_s != 0.0:
		return "Cedo" if desvio_s < 0.0 else "Tarde"
	return ["", "Quase", "Afinado", "Ressonância!"][j]
```

O «Acorde maior!» do 07 é o `car_acorde` da G04: o evento tem carimbo,
então não tem fala (09).

### Quem fala (`SalaJogo`)

```gdscript
var _ultima_fala := [-INF, -INF, -INF, -INF]   ## o t da última fala de cada lugar
var _fala_ate := 0.0                            ## até quando há uma fala na tela
var _acertos_da_equipe := 0                     ## acertos seguidos da equipe (fora do treino)
var _erros_seguidos := [0, 0, 0, 0]
var _ultimo_erro := [-INF, -INF, -INF, -INF]
var _lado_seguido := [0, 0, 0, 0]               ## +n: n toques tarde seguidos; −n: n cedo

## Uma fala do cavaleiro do lugar por um evento do 07. Devolve false (e não
## fala) se o lugar falou há menos de 20 s ou se outra fala está na tela.
func falar(l: int, evento: String) -> bool:
	if not Falas.DO_EVENTO.has(evento) or t < _fala_ate or t - _ultima_fala[l] < Falas.INTERVALO_S:
		return false
	var frases: Array = Falas.DO_EVENTO[evento]
	var texto: String = frases[rng.randi() % frases.size()]
	_ultima_fala[l] = t
	_fala_ate = t + Falas.DURACAO_S
	falou.emit(l, texto, Falas.DURACAO_S)
	Forja.evento("fala", l + 1, {"evento": evento})
	return true
```

O `julgar` da G04 ganha o desvio no fim da assinatura (quem não passa,
desvio 0) e, depois dos passos dela, as falas:

```gdscript
func julgar(l: int, j: int, palavra := "", no_tempo_1 := false, desvio_s := 0.0) -> void:
	if palavra == "" and treinando:
		palavra = Falas.do_julgamento(j, true, desvio_s)
	# … os passos 1 a 4 da G04, sem mudar …
	if not treinando:
		_falas_do_julgamento(l, j, desvio_s)
```

`_falas_do_julgamento(l, j, desvio_s)`:

| caso | o que faz |
| --- | --- |
| `j > 0` | `_acertos_da_equipe += 1`; em 15, `falar(l, "combo_equipe")` e volta a 0. Se `_erros_seguidos[l] >= 5`, `falar(l, "voltou")`. Depois, `_erros_seguidos[l] = 0` |
| `j == 0` | `_ultimo_erro[l] = t`, `_erros_seguidos[l] += 1`, `_acertos_da_equipe = 0`; se todo `k` com `jogando[k]` e `Forja.ocupado(k)` tem `t − _ultimo_erro[k] <= 1.5`, `falar(l, "todos_erraram")` (com 1 jogador, o erro dele basta) |
| o lado | `desvio_s > 0.060`: `_lado_seguido[l] = maxi(_lado_seguido[l], 0) + 1`; `desvio_s < −0.040`: `mini(_lado_seguido[l], 0) − 1`; senão 0. Em +3, `falar(l, "arrastando")`; em −3, `falar(l, "correndo")`; os dois voltam a 0 depois |

O erro chega aqui só quando `errou(l)` (G03) devolveu `false`: o Escudo que
absorve não conta erro. O «ajudou» é do kit (H04), com a regra escrita no
13: no acerto em que `Itens.puxa_o_combo_da_equipe(l, genero)` (G03) é
`true`, `falar(l, "ajudou")`.

### O fim filmado (`SalaJogo`)

```gdscript
const BATIDAS_DO_RESULTADO := 4
const BATIDAS_DO_INSERTO := 1
const POR_UM_FIO := 0.02
var _emburrou := false

func batida_do_fim() -> float:
	return 60.0 / (Ritmo.bpm if Ritmo.bpm > 0.0 else 120.0)
func vencedor_do_fim() -> int       ## a regra de A cena; -1 sem vencedor
func ultimo_do_inserto() -> int     ## a regra de A cena; -1 sem inserto
func por_um_fio() -> bool
## Quando a câmera volta à sala e a tabela abre: 5 batidas com inserto, 4 sem.
func fim_da_cena() -> float:
	var n := BATIDAS_DO_RESULTADO + (BATIDAS_DO_INSERTO if ultimo_do_inserto() >= 0 else 0)
	return n * batida_do_fim()
## "resultado", "inserto" ou "" (a câmera da sala, a tabela). Fora do fim, "".
func plano_do_fim() -> String
```

`_quadro_fim()` passa a:

1. Em `t_fase >= batida_do_fim()`, uma vez: `_celebrar()`.
2. Em `t_fase >= 4 · batida_do_fim()`, com inserto, uma vez (`_emburrou`):
   `_no_inserto()`.
3. Avança sozinho em `fim_da_cena() + TelaResultado.AVANCA_S`; o ✕ vale
   depois de `fim_da_cena() + 0.8`. Antes disso, o ✕ não faz nada (a cena
   inteira dura no máximo 5 batidas: 3,3 s a 90 BPM).

`_celebrar()`:

- com vencedor `w`: o `emote-yes` e as faíscas de hoje;
  `Som.tocar("fx_vitoria_p%d" % (w + 1), jogador(w).global_position, -9.0)`,
  `Som.no_controle(w, …, 0.85)`, o batimento duplo
  (`Forja.vibrar(w, 1.0, 0.6, 120)` e, 240 ms depois, `Forja.vibrar(w, 0.7, 0.4, 120)`);
  depois, `carimbou.emit(w, "car_por_um_fio")` se `por_um_fio()`, senão
  `falar(w, "vencedor")`;
- coop vencido: `Som.tocar("sucesso")` e o batimento duplo em cada `jogando`;
- coop perdido: `Som.tocar("fx_derrota", null, -6.0)` e o rumble que cai em
  cada `jogando`;
- empate em cima: `Som.tocar("sucesso")`; ninguém pontuou: nada.

`_no_inserto()`, com `u = ultimo_do_inserto()`: `carimbou.emit(u, "car_emburrado")`;
`jogador(u).gesto("sit", batida_do_fim() + 0.7)`;
`Som.tocar("fx_derrota", null, -6.0)`, `Som.no_controle(u, "fx_derrota", 0.85)`;
o rumble que cai (7 timers de 100 ms: `Forja.vibrar(u, f, f, 100)` com
`f = 0.6 * (7 - k) / 7.0`).

### O main (`main.gd`)

```gdscript
var visor: Visor                 ## (G04)
var encarte: EncarteDaNoite
var _plano_antes := ""           ## o plano do fim no quadro anterior (o corte)

## A pose do resultado e a do inserto (A cena).
func _pose_do_fim(sj: SalaJogo, plano: String) -> Array
func _ir_para_os_creditos() -> void
func _ir_para_o_titulo() -> void  ## se a G01 ainda não fez: sai da sala e do pódio, partida null, play_ms −1, _mostrar("titulo"), Musica.tocar("titulo")
```

- `_lente()` (G05), no ramo `"sala"`, antes do `sala.lente()`: com
  `sala is SalaJogo`, `"resultado"` → 50,0 e `"inserto"` → 85,0.
- `_pose_da_camera()`, `"sala"`: com `plano_do_fim() != ""`,
  `return _pose_do_fim(sala, plano)`.
- `_process`: se `plano_do_fim()` mudou desde `_plano_antes`, copia a pose
  em `_cam_pos`/`_cam_olhar` (o corte) e, no começo do resultado,
  `jogadores[w].olhar_para(pose[0])`; no começo do inserto, o mesmo com o
  último; na saída do inserto, tira o `car_emburrado` de `visor.vivos`.
- `_quadro_sala()`: abre o `resultado` só quando `plano_do_fim() == ""`.
- `placar.virou.connect(func(l, onde): visor.bater(l, "car_virada", onde))`
  em `_interface()`.
- `_quadro_podio()`: ✕ → `_sair_do_podio()` e `_ir_para_os_creditos()`; ◯
  como hoje. A dica do pódio vira `[["cruz", "Fechar a fita"], ["circulo", "Voltar ao salão"]]`.
- `_ir_para_os_creditos()`: `estado = "fita"`, `encarte.abrir(partida, jogadores, play_ms)`,
  `Musica.tocar("creditos")`, `hud.visible = false`. No quadro do estado
  `"fita"`: o encarte cuida do tempo; `encarte.saida()` devolve `"gravar"`
  com ✕ ou `"ejetar"` com ◯ (só depois das saídas). «gravar»:
  `play_ms = Time.get_ticks_msec()`, `_comecar_a_partida(n, sorteada)`
  (os dois da partida que acabou), `encarte.visible = false`. «ejetar»:
  `_trocar(_ir_para_o_titulo)`.
- `--sair-no-fim` com o robô continua saindo no pódio (`placar._t > 3.0`),
  antes de qualquer ✕.

### O encarte (`godot/scripts/ui/encarte_da_noite.gd`)

```gdscript
class_name EncarteDaNoite
extends Control
const PAINEL := 560.0
const PAINEL_B := 360.0
const BPM := 90.0
const MES := ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
var fase := ""          ## "fade", "encarte", "cruzando", "fim"
var linhas: Array = []  ## [{numero, nome, quem: lugar ou -1, texto, lado_b: bool}] (a prova lê)
var contador := ""      ## «1:47:12» depois do auto-stop
var data := ""          ## «9 OUT 2026»
var saidas := false     ## as duas saídas na tela
func abrir(p: Partida, jogadores: Array, play_ms: int) -> void
func pular() -> void    ## ✕ no encarte: começa o cross-fade
func saida() -> String  ## "", "gravar" ou "ejetar" (lê os botões dos lugares ocupados)
```

### O placar (`placar.gd`)

`signal virou(l: int, onde: Vector2)`; `_retangulo() -> Rect2` (a conta que
o `_draw` faz hoje); `ponto_da_virada() -> Vector2`. Em `_sons()`, na
virada, `virou.emit(int(_depois[0].lugar), ponto_da_virada())` no lugar de
`Som.tocar("placar")`; sem virada, «confirma» como hoje.

### As traduções (`traducoes.gd`, as que faltarem)

| português | inglês |
| --- | --- |
| Frequência travada! | Frequency locked! |
| Ninguém nos apaga! | Nobody puts us out! |
| Segura menos! | Ease off! |
| Vai com o baixo! | Ride the bass! |
| Calma, espera o bumbo! | Easy, wait for the kick! |
| Tá tudo desafinado! | Everything's out of tune! |
| De novo, do começo. | Again, from the top. |
| Deixa comigo o refrão! | I've got the chorus! |
| Faltou ginga pra eles. | They lacked the groove. |
| A forja canta de novo. | The forge sings again. |
| Cedo / Tarde | Early / Late |
| Fechar a fita | Close the tape |
| Gravar outra noite | Record another night |
| Ejetar | Eject |
| Lado B | Side B |
| Empate / Ninguém | Tie / Nobody |
| FEV / ABR / MAI / AGO / SET / OUT / DEZ | FEB / APR / MAY / AUG / SEP / OCT / DEC |

«STOP» e «SP» são palavras do deck: iguais nas duas línguas.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 5 e 7.

1. **O 13 primeiro:** no [kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04),
   a linha «as falas» passa a: «`julgar(l, j, palavra, no_tempo_1, desvio_s)`
   (G04, G07): o kit passa o desvio do toque em segundos (negativo: cedo);
   as falas `combo_equipe`, `voltou`, `todos_erraram`, `arrastando` e
   `correndo` saem dele; o kit chama `falar(l, "ajudou")` no acerto em que
   `Itens.puxa_o_combo_da_equipe(l, genero)`»; e, na tabela do registro v2,
   a linha `fala` (`evento`, G07).
2. **O som:** o encanamento (se ainda não há), os 6 WAV, o import, as
   linhas do mapa; `"creditos": [57, 90, 0]` em `Musica.FAIXAS`.
3. **`falas.gd`** (novo; importar e commitar o `.uid`) e **`sala_jogo.gd`:**
   `falar`, `_falas_do_julgamento`, o desvio no `julgar`, o fim filmado,
   `_celebrar`, `_no_inserto`.
4. **`desenho.gd`** (`cara_emburrada`) e **`visor.gd`** (o
   `car_emburrado` desenha a cara).
5. **`main.gd`:** a pose e a lente do fim, o corte, o resultado depois da
   cena; **`placar.gd`:** `virou`.
6. **`tela_titulo.gd`:** `desenhar_cassete` (o título passa a chamá-la, sem
   mudar nenhum número).
7. **`encarte_da_noite.gd`** (novo, com o `.uid`) e o main: o pódio, os
   créditos, o fim da fita, `_ir_para_o_titulo`.
8. **`traducoes.gd`** e **as provas**.

## Armadilhas

- **Os `.uid`** do `falas.gd` e do `encarte_da_noite.gd`.
- **A frase é a chave da tradução** e começa com maiúscula: o portão da
  F07 reprova frase com minúscula.
- **O limite vale por sala:** `t` zera a cada sala; uma fala no fim de uma
  sala e outra no começo da seguinte podem sair com menos de 20 s. Está
  certo (a tela mudou).
- **Sorteio pela semente:** o `rng` da sala (semeado em `entrar()`), nunca
  `randi()`: as provas repetem.
- **O erro não tem palavra** (07): `do_julgamento(ERRO)` é `""`.
- **`errou()` continua só n'A Centelha** (G03).
- **A Centelha não tem desvio:** ela julga pela rapidez (G04), passa 0 e
  nunca diz «Cedo»/«Tarde» nem «arrastando». As salas do kit (H04) dizem.
- **O ✕ do robô:** ele aperta ✕ a cada quadro. Antes de `fim_da_cena() + 0.8`
  o ✕ não faz nada; no encarte, o ✕ pula para o fim da fita (o robô chega
  ao fim em 1 compasso de cross-fade); no fim da fita, o ✕ vale «Gravar
  outra noite». A prova do percurso tem de esperar a cena (Provas).
- **A câmera do fim pode encostar num pilar** da sala: a prancha olha os
  dois planos em cada sala; se um encostar, a sala põe `camera_distancia`
  menor (5,2 m é o padrão, a sala não precisa mexer).
- **A cor do lugar é sagrada** (portão 3): o nome no encarte e a cara
  emburrada na cor do dono, por `Tema.JOGADOR[l]`; o resto em `TINTA`,
  `TINTA_SUAVE`, `ETIQUETA`, `FITA`.
- **Nada de `Forja.robo`** fora do `forja.gd`: o robô passa pelas falas, pelo
  fim filmado e pelo encarte como uma pessoa.
- **Os casos que quebram:** `--robo=bom|medio|ruim` (com o ruim, uma faixa
  sem pontos: sem vencedor, sem inserto, «Ninguém» no encarte), partidas de
  1 jogador (sem inserto: não há último) e de 2 (o inserto do outro, se
  perdeu por pontos), o empate em cima (sem vencedor: o plano no grupo) e o
  controle que cai no meio do fim (o rumble e o `fx_vitoria` no controle
  que não está lá não fazem nada; o plano segue).

## Não fazer

- Cutscene, diálogo, texto longo, legenda.
- PERFECT/MISS, nota, porcentagem na tela.
- Fala que manda olhar o controle ou que fala do hardware.
- Mudar o desenho do visor e as regras da vez dos carimbos (G04).
- Créditos de quem fez o jogo no fim da noite (11): a `TelaCreditos` do
  título fica como está.
- O virar da fita (`fx_virar`, a fita que gira): G16.
- A luz do vencedor e o contra-luz: G15.
- O `jump` do vencedor e outras poses do 05.
- O adesivo de reação.

## Pronto quando

Numa partida de cinco: as falas aparecem acima do cavaleiro, nunca duas ao
mesmo tempo e nunca duas do mesmo cavaleiro em menos de 20 s; o fim de cada
faixa filma o vencedor e, quando há, o último emburrado, antes da tabela; a
virada carimba «VIRADA!» no placar; o ✕ no pódio leva ao encarte, que
passa as cinco faixas com quem venceu, e ao fim da fita, com o contador
parado no tempo real e as duas saídas, que funcionam.

E só fecha com `bash tests/prova_visual.sh` passando e a prancha olhada; a
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

**A prova do percurso muda** (`prova_do_jogo.gd`, depois de `sala.terminar()`
no percurso, hoje 377-391): esperar `sala.plano_do_fim() == ""` antes de ler
o `resultado`, e o avanço sozinho passa a
`fim[0] ≈ sala.fim_da_cena() + TelaResultado.AVANCA_S` (−0,05 a +0,1 s).

**As falas**, numa `SalaJogo` solta, no `_ready()` depois de
`_prova_do_percurso()`:

```gdscript
## As falas: as regras do 07, sem cena e sem robô.
func _prova_das_falas() -> void:
	var s := SalaJogo.new()
	var ditas: Array = []
	s.falou.connect(func(l, texto, seg): ditas.append([l, texto, seg]))
	s.t = 100.0
	_esperar(s.falar(0, "vencedor") and ditas.size() == 1 and ditas[0][2] == 2.0, "a primeira fala sai, por 2 s")
	s.t = 101.0
	_esperar(not s.falar(1, "combo_equipe"), "duas falas ao mesmo tempo, não")
	s.t = 102.1
	_esperar(s.falar(1, "combo_equipe"), "passados 2 s, a fala do P2 sai")
	s.t = 110.0
	_esperar(not s.falar(0, "voltou"), "o P1 não fala de novo antes de 20 s")
	s.t = 120.5
	_esperar(s.falar(0, "voltou"), "passados 20 s, o P1 fala de novo")
	_esperar(not s.falar(2, "nao_existe"), "evento sem frase não fala")
	s.free()
	_esperar(Falas.do_julgamento(Falas.PERFEITO) == "Ressonância!" and Falas.do_julgamento(Falas.OTIMO) == "Afinado"
		and Falas.do_julgamento(Falas.BOM) == "Quase" and Falas.do_julgamento(Falas.ERRO) == "", "o vocabulário do visor")
	_esperar(Falas.do_julgamento(Falas.BOM, true, -0.08) == "Cedo" and Falas.do_julgamento(Falas.OTIMO, true, 0.07) == "Tarde"
		and Falas.do_julgamento(Falas.PERFEITO, true, 0.01) == "Ressonância!", "no treino, cedo e tarde; o perfeito é perfeito")
	var sem := []
	for evento in Falas.DO_EVENTO:
		for frase in Falas.DO_EVENTO[evento]:
			if frase.substr(0, 1) != frase.substr(0, 1).to_upper() or not Traducoes.EN.has(frase):
				sem.append(frase)
	_esperar(sem.is_empty(), "toda fala começa com maiúscula e tem inglês %s" % [sem])
	# por um fio: 2 % ou menos
	var f := SalaJogo.new()
	f.jogando = [true, true, false, false]
	f.pontos = [100, 99, 0, 0]
	_esperar(f.por_um_fio() and f.vencedor_do_fim() == 0 and f.ultimo_do_inserto() == 1, "por um fio com 1 %")
	f.pontos = [100, 97, 0, 0]
	_esperar(not f.por_um_fio(), "3 % não é por um fio")
	f.pontos = [50, 50, 0, 0]
	_esperar(f.vencedor_do_fim() == -1 and f.ultimo_do_inserto() == -1, "o empate não tem vencedor nem inserto")
	f.free()
```

**O fim filmado**, no `_prova_da_partida()`, na primeira faixa (pontos
`[10, 40, 30, 20]`: o P2 vence, o P1 é o último), logo depois de
`sala.terminar()`:

```gdscript
		if i == 0:
			await _quadros(2)
			_esperar(sala.plano_do_fim() == "resultado" and is_equal_approx(jogo.camera.fov, Lente.fov(50.0)), "o fim: o plano do vencedor a 50 mm")
			var b: float = sala.batida_do_fim()
			var pico := 0.0
			var falou := false
			var ate := Time.get_ticks_msec() + int(b * 4500.0)
			while sala.plano_do_fim() == "resultado" and Time.get_ticks_msec() < ate:
				pico = maxf(pico, float(_perc(1).get("forte", 0.0)))
				falou = falou or Forja.som_virtual(1).falante > 0
				await _quadros(1)
			_esperar(pico >= 0.99 and falou, "a vitória bate duas vezes na mão do P2 e toca no alto-falante dele")
			_esperar(sala.plano_do_fim() == "inserto" and is_equal_approx(jogo.camera.fov, Lente.fov(85.0)), "o inserto do último a 85 mm")
			await _quadros(2)
			_esperar(jogo.visor.do_lugar(0).any(func(v): return v.id == "car_emburrado"), "a cara emburrada acima do P1")
			_esperar(float(_perc(0).get("forte", 0.0)) > 0.3, "o controle do P1 desmaia")
```

**O placar e o fim da noite**, uma função depois de `_prova_da_partida()`:

```gdscript
## A virada no placar, o encarte e o fim da fita.
func _prova_do_fim_da_noite() -> void:
	var p := Partida.nova(2, false, 7, ["centelha", "galeria"])
	p.registrar("centelha", [40, 10, 0, 0], [0, 1, 2])
	p.registrar("galeria", [0, 40, 30, 0], [0, 1, 2])
	var virou: Array = []
	jogo.placar.virou.connect(func(l, onde): virou.append(l), CONNECT_ONE_SHOT)
	jogo.placar.abrir(p, false)
	jogo.placar.visible = true
	await _quadros(int(60 * (Placar.T_LIDER + 0.2)))
	_esperar(virou == [1], "a virada carimba o P2 no placar (%s)" % [virou])
	jogo.placar.visible = false
	jogo.partida = p
	jogo._ir_para_os_creditos()
	await _quadros(2)
	var e: EncarteDaNoite = jogo.encarte
	_esperar(e.linhas.size() == 3 and e.linhas[1].lado_b and int(e.linhas[0].quem) == 0 and int(e.linhas[2].quem) == 1,
		"o encarte: a faixa 1 do P1, o Lado B, a faixa 2 do P2")
	await _aperta(0, Forja.CRUZ)
	var q := 0
	while not e.saidas and q < 600:
		await _quadros(2)
		q += 2
	_esperar(e.saidas and e.contador.count(":") == 2 and e.data != "", "o fim da fita: o contador (%s), a data, as saídas" % e.contador)
	_esperar(jogo.retangulos_na_tela().all(func(r): return Rect2(Vector2.ZERO, jogo.hud.size).encloses(r)), "o fim da fita cabe na tela")
	await _aperta(0, Forja.CIRCULO)
	q = 0
	while (jogo.estado != "titulo" or jogo._trocando) and q < 600:
		await _quadros(2)
		q += 2
	_esperar(jogo.estado == "titulo", "◯ ejeta: de volta ao título")
```

O auto-stop no controle: no laço que espera `e.saidas`, guardar o maior
`_perc(l).fraco` de cada lugar ocupado; cada um chega a 0,45.
(`jogo.retangulos_na_tela()` é o da G04; se ela ainda não o tem, o
`e.get_rect()` das duas caixas.)

**A prova visual (F09):** `bash tests/prova_visual.sh`; na prancha, o plano
do resultado e o inserto em cada partida, o placar com «VIRADA!», o encarte
e o fim da fita.

## Para o André (local)

1. `./run-local.sh -- --partida=5`: jogar e contar as falas. Nenhuma
   encavalada, nenhuma repetida pelo mesmo cavaleiro em seguida.
2. N'A Centelha, errar de propósito com os quatro ao mesmo tempo: «Tá tudo
   desafinado!».
3. No fim de cada faixa: o vencedor de baixo e girando; o último senta e a
   cara emburrada aparece; o controle de cada um sente o seu.
4. ✕ no pódio: o encarte com os nomes na caneta, o «Lado B» no meio, e o
   contador parado. ✕ grava outra noite; ◯ ejeta.
5. Em inglês (Opções › Idioma): as falas, o encarte e o fim da fita.

## Ao terminar

No [quadro](README.md), G07 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: as falas curtas, o fim de cada faixa filmado e o encarte da noite até o fim da fita
```
