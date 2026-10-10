# G04 — O HUD de cada jogador

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F02, F07, F09 (a prova visual), G02 (`ForjaPlayer.nome`), G03 (`Itens`), G11 (`Desenho.placa`, `etiqueta`, `dica`, `lampadas`), G14 (os tokens e as fontes) · **Usado por:** G07 (`falou`, os carimbos do resultado e do placar), G13 (`car_liga`), H04 (o kit chama `julgar`)

## Por quê

O HUD de hoje é uma fileira de chips de 250 × 92 px no alto à direita, com
USB/BT e bateria. Ela colide com o nome da sala e com o relógio, e não diz o
que importa. Cada jogador ganha a sua tira de console no seu canto. O
julgamento vira um carimbo de tinta acima do cavaleiro, na cor dele, com a
nota dele na TV e na mão. A faixa que toca ganha a etiqueta e o deck no alto.

## Ler antes

- [06 — os objetos](../arte/06-interface-e-texto.md#os-objetos) (o cartão, a etiqueta, o deck, o VU, a troca de etiqueta, as placas que entram)
- [07 — o carimbo](../arte/07-vfx.md#o-carimbo) (a letra, a escala, o desregistro, os respingos)
- [09 — os carimbos do jogo](../arte/09-reacoes.md#os-carimbos-do-jogo) (os seis, a vez, quanto duram, o conforto)

Os números de som e vibração do 03 (a seção «O carimbo de cada julgamento») estão copiados em O som e em O controle.

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/ui/hud.gd` (`_lugares` sai; o cartão, a etiqueta, o deck, `retangulos()`) | **G06** (a placa do portão), **G11** (`moldura` vira placa), **G14** (as cores) |
| `godot/scripts/ui/visor.gd` e `.uid` (novos, `class_name Visor`) | **G07** (a fala), **G13** (`car_liga`) |
| `godot/scripts/ui/desenho.gd` (`vu`, `contador`, `carretel`, `deck`, `carimbo`) | **G11**, **G12**, **G13** (o VU da montagem), **G14**, **G16** |
| `godot/scripts/ui/painel_sala.gd` (`_tempo`, `_treino_e_valendo`, `_dicas`, `retangulos()`) | **G11**, **G12**, **G14** |
| `godot/scripts/salas/sala.gd` (os sinais) | **G07** |
| `godot/scripts/salas/sala_jogo.gd` (`julgar`, `combo`) | **G03** (`errou`), **G07**, **H04** |
| `godot/scripts/salas/centelha.gd` e `impacto.gd` (`combo`; a Centelha chama `julgar`) | **G03** (a Centelha) |
| `godot/scripts/main.gd` (`_interface`, `_entrar_na_sala`, `_sair_da_sala`, `_process`) | **G01, G02, G03, G05, G06, G07, G08** |
| `godot/scripts/forja.gd` (`aplicar_opcoes`: `FORJA_TEXTO`) | **G14** (`COR_DO_LUGAR`) |
| `godot/scripts/traducoes.gd` | **G07, G09, G11, G16** |
| `godot/assets/sons/` (22 WAV) e `docs/jogo/audio/mapa.csv` | **G01, G03, G07, G11, G12, G16** |
| `tests/prova_visual.sh` (duas passadas) | **F09** |
| `docs/jogo/13-arquitetura.md` (o kit do minigame: `julgar`) | **H04** |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |

## Como se joga

Não se aplica: o HUD não tem regra. Ele mostra a regra dos outros. A única
conta desta ficha é a do carimbo `car_em_chamas` (5 «Ressonância!» seguidas
do mesmo jogador) e a do `car_acorde` (todos os que jogam acertam
«Ressonância!» no mesmo tempo 1), em As reações.

## A cena

As medidas são da tela lógica de 1920 × 1080. Tudo sai de `size` (âncoras,
não pixels): no Steam Deck (16:10) os cartões de baixo seguem `size.y`.

### O cartão do jogador (a tira do console)

```gdscript
const CARTAO := Vector2(420, 132)
## O retângulo do cartão do lugar: o canto dele, 96 px das laterais e 60 do alto ou de baixo.
## A largura não cresce com o texto grande (senão o P1 encosta na etiqueta); a altura, sim.
static func cartao(l: int, tela: Vector2) -> Rect2:
	var tam := Vector2(CARTAO.x, CARTAO.y * Tema.escala_texto)
	var x := Tema.MARGEM_X if l % 2 == 0 else tela.x - Tema.MARGEM_X - tam.x
	var y := Tema.MARGEM_Y if l < 2 else tela.y - Tema.MARGEM_Y - tam.y
	return Rect2(Vector2(x, y), tam)
```

As posições abaixo são a partir do canto de cima à esquerda do cartão; os y
e os tamanhos de letra multiplicam por `e = Tema.escala_texto` (1,0 ou
1,15), os x não. «Base» é a linha de base do texto.

| o quê | onde | como |
| --- | --- | --- |
| a sombra | o cartão deslocado (0, 6) | `SOMBRA`, raio 10 |
| o casco | o cartão | `Color(Tema.CASCO, 0.94)`, raio 10 |
| a tarja | (10, 0), 400 × 5 | a cor do dono, `Tema.JOGADOR[l]` |
| o P# | (18, base 52) | Bungee `T_PSHARP` (40), a cor do dono |
| as lâmpadas | (20, 66) | `Desenho.lampadas(ci, pos, l)` (G11): 5 de 15 × 8, vão de 5 |
| o nome | (112, base 48), até a largura `402 − largura(pontos) − 16 − 112` | Archivo 600 `T_NOME` (32), `ETIQUETA`, `Desenho.caber` numa linha |
| os pontos | alinhados à direita em x 402, base 54 | VT323 `T_PONTOS` (64), `ETIQUETA`, `"%04d"` (com 5 dígitos acima de 9999) |
| o item | (132, 58), 36 × 36 | `Glifo.desenhar(ci, ForjaPlayer.ITENS[Itens.do_lugar(l)].icone, r, cor)`; `ETIQUETA`; em liga (`Itens.em_liga[l]`), a cor do dono; o Escudo quebrado (`not Itens.escudo_inteiro(l)`), `MUDO` com um traço diagonal de 3 px `MUDO`; Mãos livres, nada |
| o VU | (18, 98), 302 × 18 | `Desenho.vu`: 14 segmentos, vão de 4; acesos `mini(combo, 14)` na cor do dono; o pico (`mini(combo_max, 14) - 1`, só quando `combo_max > combo`) em `ETIQUETA`; apagados `GRAFITE` |
| o combo | alinhado à direita em x 402, base 124 | VT323 40, `ETIQUETA`, `"×%d"`; só com combo ≥ 2 |

Os três estados:

| estado | o que muda |
| --- | --- |
| jogando | a tabela inteira |
| sem controle (`not Forja.lugar(l).conectado`) | a tarja em `GRAFITE`; as cinco lâmpadas em `GRAFITE`; no lugar do nome, «Sem controle» (Archivo 600 32, `ETIQUETA`); os pontos e o VU ficam |
| lugar vazio | o casco a 50 % (`Color(Tema.CASCO, 0.5)`), sem sombra; a tarja em `GRAFITE`; o P# em `MUDO`; `Desenho.dica(ci, canto + (132, 62 × e), "cruz", "Entrar")` (G11: glifo de 52 e Archivo 600 34); sem pontos, VU nem item |

O texto do lugar vazio não usa alfa (só o casco é translúcido). Saem do HUD:
USB/BT, bateria, a linha `status_da_sala` (o [06](../06-telas-e-fluxo.md#o-hud-de-cada-jogador): «Nada mais»).
O que cada sala diz por lugar já está na dica presa à raia (`sala.dica(l)`,
desenhada por `painel_sala._dicas`).

### A etiqueta da faixa e o deck (o alto, no meio)

| o quê | onde | como |
| --- | --- | --- |
| a etiqueta | (548, 60), 430 × 136, sem escala | `Desenho.etiqueta(ci, r, Tema.tinta_da_secao(n), inclinacao, lado_b)` (G11) |
| o título | dentro da etiqueta, (24, base 80) | Permanent Marker 52, `TINTA`; o nome da sala (`sala.nome`), até 18 caracteres (`Desenho.caber`) |
| a linha impressa | dentro da etiqueta, (24, base 124) | VT323 34, `TINTA_SUAVE`: `"LADO %s · FAIXA %02d" % [lado, faixa]` |
| o deck | (996, 60), 376 × 116, sem escala | `Desenho.deck(ci, r, esquerda, direita, digitos, giro)` |

- `n` é a seção: `Musica.SALA_DA_SECAO.find(sala.id)` (1 a 9).
- `lado`: `main.partida.lado()` (G12) com partida, senão `"A"`; `lado_b = lado == "B"`.
- `faixa`: `main.partida.passo + 1` com partida, senão `n`.
- `inclinacao` (graus): `lerpf(-1.5, 1.5, float(hash([semente, n]) % 1000) / 999.0)`, com `semente = main.partida.semente` (0 sem partida). Ela nunca se anima.
- Título e linha impressa giram junto com o papel: `draw_set_transform(centro, deg_to_rad(inclinacao))` e as posições a partir de `-tamanho / 2`.
- **O deck é o relógio da faixa.** Com `sala.duracao > 0`, o contador mostra os segundos que faltam (`"%03d" % ceili(resta)`), `esquerda = resta / duracao`, `direita = 1 − esquerda`. Sem relógio (`duracao <= 0`), conta para cima o tempo jogado (`"%03d" % int(sala.t_jogo)`), `esquerda = 0.5`, `direita = 0.5`. No treino, o contador fica em `"%03d" % ceili(duracao)` e os carretéis param (o treino não gasta o relógio, como hoje).
- Os carretéis giram uma volta a cada 2 batidas, `RETA` (`giro = TAU * Ritmo.batida() / 2.0`), e param no apito (`fase == "fim"`).

`Desenho.contador`, `Desenho.carretel`, `Desenho.deck` e `Desenho.vu` vêm do
estudo (`godot/estudos/direcao/hud.gd`, linhas 74 a 86, 105 a 135 e 146 a
157), com `Fita.*` trocado por `Tema.*`, e `carretel` com o parâmetro `giro`
(os raios do cubo giram por ele). Se a G13 já trouxe o `vu`, usar o dela.

### O salão

Sem cartões. A etiqueta em (96, 60), 520 × 150, título «O Salão» em
Permanent Marker 56, linha impressa `"A FORJA · LADO %s" % lado`, tarja
`Tema.SECAO[0]`, inclinação −0,6°. O cabeçalho do app (`Desenho.cabecalho`,
«Hefesto Tech Demo») sai do HUD. As dicas de baixo (Options «Pausa»; Create
«Diagnóstico» no Modo bancada) ficam no salão, alinhadas à direita em
x `w − 96`, com o topo do glifo em y 150 (abaixo do contador «Salas vencidas»
da G06, de y 58 a 130; embaixo ficam os chips da G06); nas salas, saem (os
cantos de baixo são do P3 e do P4).

### O resto, sem encostar

| o quê | onde |
| --- | --- |
| a placa do portão (salão) | `Desenho.placa`, centrada, y `h − 260`, altura 150, largura de 620 até `w − 2 × (96 + 420 + 24)` (840 em 1920); a G06 a troca pela dica presa ao cavaleiro |
| a linha de progresso (`sala.progresso()`, sala sem relógio) | `Desenho.placa`, centrada, y 214, altura 52; Archivo 500 30, `ETIQUETA` |
| o selo do treino | `Desenho.placa`, centrado, y 282, altura 56 |
| o «Valendo!» | onde está hoje (`size.y × 0.42`), centrado |
| os avisos que somem (`Forja.aviso`) | centrados, a partir de y 352, até 1100 px de largura, 2 linhas; ficam `max(2.0, 0.06 × texto.length())` s (06: o texto que some) |
| as dicas das raias (`painel_sala._dicas`) | a pílula que cruza um cartão sai dele: em cima (P1, P2) vai para `cartao.end.y + 8`; embaixo (P3, P4), para `cartao.position.y − pílula.size.y − 8` |

Durante a fase `"aviso"` (o J-card da G12 em (760, 90), 1064 × 830), o HUD
não desenha cartões, etiqueta nem deck: eles entram quando a fase vira
`"jogo"`.

**As placas entram** (06, as transições) no primeiro quadro da fase
`"jogo"`: cada cartão chega 160 px de fora do seu canto (P1 e P3 da
esquerda, P2 e P4 da direita), de opacidade 0 a 1, em 1 batida, `SAI`; o P1
no quadro 0, o P2 1 colcheia depois, o P3 2, o P4 3. A etiqueta e o deck
entram com o P1, descendo de −40 px. A batida é `60.0 / Ritmo.bpm` s (120
BPM sem música: 500 ms). **As placas saem** no apito: as seis juntas, 160 px
para fora (etiqueta e deck para cima), em 1 colcheia, `ENTRA`.

**A troca de etiqueta** (06), quando a seção da sala nova difere da última
mostrada (`_secao_mostrada`): se uma etiqueta está na tela, ela descola
(sobe 40 px, gira +4°, some em 1 batida, `ENTRA`); a nova cola (desce de
−40 px em 1 batida, `MOLA`); a caneta escreve o título da esquerda para a
direita em 400 ms, `RETA`, por recorte: um `Control` filho com
`clip_contents = true`, a mesma `rotation` e o `size.x` de 0 à largura do
título. Nunca letra por letra.

### O visor acima do cavaleiro (`Visor`, uma camada acima do HUD)

O ponto de cada cavaleiro: `c = cam.unproject_position(p.global_position + Vector3(0, 1.75, 0)) + Vector2(0, -20)`
(pule se `cam.is_position_behind(...)`). Ele se recalcula a cada quadro: o
carimbo acompanha o cavaleiro.

| vaga | o quê | onde | letra |
| --- | --- | --- | --- |
| 0 | o carimbo do julgamento | centrado em `c` | Bungee `T_CARIMBO` (46), a cor do dono |
| 1 | o carimbo do jogo ou a fala (nunca os dois, 09) | centrado em `c − (0, 72)` | o carimbo: a letra da tabela de As reações; a fala: Archivo 600 34 |

**O carimbo** (07), em `Desenho.carimbo(ci, centro, palavra, cor, tam, graus, escala, alfa, sobre_3d := true)`:

- uma chapa `FITA` atrás da letra, deslocada `(d, d)` com `d = maxi(3, roundi(0.08 * tam))` (4 px no 46, 9 no 112);
- sobre a cena 3D, o contorno `FITA` de 6 px (`draw_string_outline`);
- a letra na cor;
- tudo girado por `graus` em volta do centro.

| fase | julgamento | carimbo do jogo |
| --- | --- | --- |
| bate | escala de 1,35 a 1,0 em 80 ms, `MOLA`, −4° | o mesmo |
| espirra | 4 a 6 respingos retangulares de 4 a 10 px, na cor, sorteados até `0.6 × tam` do centro, por 6 quadros | o mesmo |
| fica | 250 ms | 4 batidas, entre 1600 e 2800 ms (`clampf(4 * 60.0 / Ritmo.bpm, 1.6, 2.8)`); o `car_virada`, 2 batidas |
| some | opacidade de 1 a 0 em 170 ms | o mesmo |

Ao todo, o julgamento fica 500 ms (06: «o carimbo do julgamento, 500 ms»).

**A fala** (a G07 manda): uma etiqueta pequena, `Desenho.etiqueta(ci, r, Tema.JOGADOR[l])`,
largura até 420 px, o texto em Archivo 600 34, `TINTA`, até 2 linhas
(`Desenho.caber` e `Desenho.paragrafo`), 24 px de margem; fica o tempo que
a G07 pede.

**Movimento reduzido** (09, com o conforto): sem escala e sem rotação; o
carimbo e a fala aparecem e somem em 4 quadros de opacidade, e não
espirram. Enquanto a G16 não chega, `not Opcoes.tremor`; depois,
`Opcoes.movimento == 1`. O mesmo vale para as placas que entram e saem (só
opacidade, 4 quadros).

**A âncora do adesivo** (o adesivo é de uma ficha própria, a G16 linha 60):
`Visor.ancora_do_adesivo(l) -> Vector2`, o ponto onde o adesivo de 112 px se
cola, metade para fora do cartão: na borda de dentro em y (a de baixo para P1
e P2, a de cima para P3 e P4), em x `cartao.end.x − 56` (P1, P3) ou
`cartao.position.x + 56` (P2, P4). Assim ele não toca a etiqueta (x ≥ 548)
nem outro cartão. Esta ficha não desenha adesivo.

## O som

O encanamento, igual nas fichas G01, G03, G09, G11, G12 e G16 (se outra ficha
já fez, usar o dela): copiar cada `<id>.wav` de
`godot/estudos/direcao/som/` para `godot/assets/sons/<id>.wav`; rodar
`"$GODOT" --headless --path godot --import --quit` e conferir
`compress/mode=0` em cada `.import`. `Som.tocar` e `Som.no_controle` tocam
primeiro `res://assets/sons/<nome>.wav` quando ele existe, sem o tom
sorteado de ±5 %. A linha do mapa ganha `arquivo` =
`godot/assets/sons/<id>.wav` e `estado` = `no jogo`.

Os 22 desta ficha:

| quando | id | onde | volume |
| --- | --- | --- | --- |
| o julgamento «Ressonância!» do lugar `n` | `jul_ressonancia_p{n}` (180 ms) | TV na posição do cavaleiro, e o alto-falante do dono | −12 dB na TV; ganho 0,85 no controle |
| «Afinado» | `jul_afinado_p{n}` (150 ms) | o mesmo | o mesmo |
| «Quase» | `jul_quase_p{n}` (120 ms) | o mesmo | o mesmo |
| o erro (sem palavra) | `jul_erro_p{n}` (220 ms, a nota 60 cents abaixo, 6 bits, wow de 4 Hz) | o mesmo | o mesmo |
| `car_em_chamas` | `car_em_chamas` (600 ms) | TV | −9 dB |
| `car_acorde` | `car_acorde` (1200 ms) | TV | −9 dB |
| `car_por_um_fio`, `car_liga` (quem chama: G07, G13) | o mesmo id (700 e 400 ms) | TV | −9 dB |
| `car_virada` (quem chama: G07, no placar) | `jin_virada` (2000 ms) | TV | −9 dB |
| a troca de etiqueta | `fx_caneta` (400 ms), quando a caneta começa | TV | −6 dB |

O `car_emburrado` não toca nada (o `fx_derrota` do inserto já toca). O
`reacao_pop` é de quem desenha o adesivo, não daqui. No julgamento, o `jul_*`
toma o lugar do som de falha e do martelo no controle (A Centelha, abaixo):
o erro soa como a nota do próprio cavaleiro saindo desafinada, nunca como um
zumbido de reprovação.

## O controle

| evento | para quem | vibração (forte/fraco/ms) | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- | --- |
| «Ressonância!» | o dono | perfeito 0,5/0,8/100 | não muda | não muda | `jul_ressonancia_p{n}` | não se usa |
| «Afinado», «Quase» | o dono | acerto 0,3/0,6/80 | não muda | não muda | `jul_afinado_p{n}`, `jul_quase_p{n}` | não se usa |
| o erro | o dono | erro 0,7/0,3/160 | não muda | não muda | `jul_erro_p{n}` | não se usa |
| um carimbo do jogo | o dono | acerto 0,3/0,6/80 | não muda | não muda | nada (o `car_*` é só da TV) | não se usa |
| `car_acorde` | os quatro que jogam | acerto 0,3/0,6/80 | não muda | não muda | nada | não se usa |
| o cartão, a etiqueta, o deck | ninguém | nada | nada | nada | nada | não se usa |

Sem o controle na mão: `_perc(l)` (`Forja.ctl.percepcao(Forja.pad_do_lugar(l))`)
traz `forte` e `fraco`; `Forja.som_virtual(l).falante` mede o alto-falante.
A prova confere o julgamento e o `car_acorde` assim (Provas).

## O cavaleiro

- **Os stats:** esta ficha não lê stat.
- **O item no cartão:** `Itens.do_lugar(l)`, `Itens.escudo_inteiro(l)` e
  `Itens.em_liga[l]` (G03; a G13 escreve a liga). O ícone é o
  `ForjaPlayer.ITENS[i].icone` da G02.
- **O nome:** `ForjaPlayer.nome` (G02), nome próprio: não traduz, até 12
  caracteres.
- **O carimbo segue o cavaleiro** (1,75 m acima dos pés). A cor é a do dono,
  a mesma do contorno e do aro (G15): quem olha liga a palavra ao boneco.

## As reações

Esta ficha faz a máquina dos carimbos do [09](../arte/09-reacoes.md#os-carimbos-do-jogo)
e dispara dois deles. Os outros chamam `Visor.bater`.

| id | no visor | quem dispara | quando | onde | letra |
| --- | --- | --- | --- | --- | --- |
| `car_em_chamas` | «EM CHAMAS» | esta ficha, em `SalaJogo.julgar` | o 5º «Ressonância!» seguido do mesmo lugar, fora do treino; a conta volta a 0 em qualquer outro julgamento e depois de carimbar | vaga 1 do dono | Bungee 46, a cor do dono |
| `car_acorde` | «ACORDE MAIOR!» | esta ficha, em `SalaJogo.julgar` | com 3 ou 4 lugares em `jogando`, todos com «Ressonância!» no tempo 1 do mesmo compasso (`roundi(Ritmo.batida() / 4.0)`) | centro, y 300 | Bungee 112, `ETIQUETA`; embaixo, 4 tarjas de 12 × 80, uma por lugar (P1 a P4), com o P# em Bungee 30 `TINTA` |
| `car_virada` | «VIRADA!» | G07 (o placar) | — | ao lado da linha no placar | Bungee 64 |
| `car_por_um_fio` | «POR UM FIO» | G07 (o resultado) | — | vaga 1 do vencedor | Bungee 64 |
| `car_liga` | «LIGA!» | G13 (a montagem) | — | a linha «Arma ou amuleto» | Bungee 46 |
| `car_emburrado` | a cara de fita de 160 px | G07 (o inserto) | — | vaga 1 do último | — |

**A vez** (09): no máximo 1 carimbo do jogo vivo por jogador e 2 na tela.
A ordem: `car_acorde`, `car_virada`, `car_em_chamas`, `car_por_um_fio`,
`car_liga`. Quem chega e acha a vaga do dono ocupada substitui o vivo só se
vem antes na ordem; senão, não sai. Com 2 na tela, o novo substitui o de
ordem mais baixa, se vier antes dele; senão, não sai. O `car_acorde` conta
como 1 na tela. O `car_emburrado` só existe sozinho. Um carimbo que sai
toca o som e vibra; um que não sai, não.

**A fala e o carimbo** dividem a vaga 1: com um carimbo vivo no lugar, a fala
não aparece (09: «um dos dois, nunca os dois»).

**As Opções:** se a G16 já entrou, `bater` volta `false` com
`not Opcoes.reacao_do_jogo()` (Reações em «Nenhuma»); se não, a G16 põe essa
linha (ela diz isso). O carimbo do julgamento não é reação: ele sai sempre.

## A diversão

**O momento:** n'A Centelha, o P4 acerta a runa no último instante bom e
«RESSONÂNCIA!» bate em âmbar acima do cavaleiro dele, com a nota dele na TV
e na mão (100 ms de vibração). No quinto acerto seguido, «EM CHAMAS» bate em
cima. Os outros três veem de quem foi sem ler o cartão, porque a cor da
palavra é a do contorno do boneco. **Como se confere:**

1. A prova, sem o controle na mão: `julgar(3, 3)` deixa o carimbo «Ressonância!»
   vivo na vaga 0 do P4; `_perc(3).forte` chega a 0,5 e `fraco` a 0,8;
   `Forja.som_virtual(3).falante > 0`; em 500 ms o carimbo some.
2. Cinco `julgar(3, 3)` seguidos deixam `car_em_chamas` vivo na vaga 1 do P4;
   com os quatro em «Ressonância!» no mesmo tempo 1, sai o `car_acorde`, e
   os quatro sentem 0,3/0,6.
3. A prancha da Centelha (prova visual) mostra os quatro cartões nos cantos
   e um carimbo acima de um cavaleiro, como o quadro
   `docs/imagens/direcao/01_centelha_depois.jpg`. O jogador do time anota no
   diário se acha o dono do carimbo em 1 s.

## O estado de hoje

- `godot/scripts/ui/hud.gd` (142 linhas), `_draw()` (41 a 104): a tarja de
  cima em `Tema.CASA`; no salão, `Desenho.cabecalho(self, Vector2(Tema.MARGEM_X, 40), 60.0)`
  (o logo «Hefesto Tech Demo»); na sala, o quadro do nome e da ação em
  `Rect2(Vector2(Tema.MARGEM_X - 28, 40), Vector2(larg, 118))`; a fileira
  `_lugares(Vector2(w - Tema.MARGEM_X, 40))`; a placa do portão em
  `h - 230`, de 620 a `w - 2 * Tema.MARGEM_X`; as dicas em
  `(w - Tema.MARGEM_X, h - Tema.MARGEM_Y)`; os avisos a partir de y 190,
  3,5 s cada.
- `hud.gd:108-142`, `_lugares()`: quatro chips de 250 × 92 com P#, USB/BT,
  bateria e `status_da_sala[l]`, que encolhe até 20 px (abaixo do piso de 30).
- `godot/scripts/main.gd`: `hud` e `painel` criados em `_interface()` (127,
  128); `hud.sala` e `hud.placa` em `_entrar_na_sala` (331, 332);
  `hud.status_da_sala` zerado em 292 e escrito a cada quadro em 562.
- `godot/scripts/ui/painel_sala.gd`: `_tempo()` (306 a 335) desenha o
  relógio em `(Tema.MARGEM_X - 28, 184)`, em cima do canto do P1, e a linha de
  progresso em y 162; `_treino_e_valendo()` (338 a 355) põe o selo em y 176;
  `_dicas()` (129) prende as pílulas às raias sem fugir dos cantos.
- O combo só existe n'A Centelha (`centelha.gd:110`, `j[l].combo`; zera em
  268 e 353) e n'O Impacto (`impacto.gd:101`, 249, 262).
- A Centelha: o botão errado (`centelha.gd:264-270`) e `_perdeu()` (350)
  tocam `"falha"`; `_acertou()` (326 a 347) toca `bigorna`, `martelo`,
  `Som.no_controle(l, "martelo", 0.55)` e `Forja.vibrar(l, 0.0, 0.2, 50)`.
- Nada mostra um julgamento, um carimbo ou a etiqueta da faixa. Nenhum `jul_*`,
  `car_*`, `jin_virada` ou `fx_caneta` está em `godot/assets/sons/` (os 22
  estão no estudo, `godot/estudos/direcao/som/`, e no mapa com
  `estado` = `gerado`).
- `godot/scripts/ui/desenho.gd:63-80`: a coleta de texto guarda só a frase;
  o retângulo é da F09 (em voo). Não há `tests/prova_visual.sh` ainda (F09).
- `godot/scripts/forja.gd:134-137`, `aplicar_opcoes()`: a escala vem de
  `Opcoes.texto`, o idioma de `FORJA_IDIOMA`; não há variável para a escala.
- `Ritmo.batida()` (`ritmo.gd:110`) e `Ritmo.bpm` (21);
  `Musica.SALA_DA_SECAO` (`musica.gd:31`); `SalaJogo.fase` (`"aviso"`,
  `"jogo"`, `"fim"`), `pontos`, `jogando`, `duracao`, `t_jogo`, `treinando`.

## O alvo

### Os sinais e o julgamento (`sala.gd`, `sala_jogo.gd`)

```gdscript
# sala.gd
signal julgou(l: int, j: int, palavra: String)   ## o carimbo do julgamento (o Visor desenha)
signal carimbou(l: int, id: String)              ## um carimbo do jogo (09)
signal falou(l: int, texto: String, segundos: float)  ## a fala do cavaleiro (G07)

# sala_jogo.gd
## A numeração do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const PALAVRA := ["", "Quase", "Afinado", "Ressonância!"]
const JUL := ["erro", "quase", "afinado", "ressonancia"]
const VIBRA := [[0.7, 0.3, 160], [0.3, 0.6, 80], [0.3, 0.6, 80], [0.5, 0.8, 100]]
var _ressonancias := [0, 0, 0, 0]       ## «Ressonância!» seguidas, por lugar
var _acorde := [-1, -1, -1, -1]         ## o compasso da última «Ressonância!» no tempo 1

## O julgamento de um toque: o som do lugar na TV e na mão, a vibração e o carimbo.
## `palavra` vazia usa PALAVRA[j] (a G07 passa «Cedo»/«Tarde» no treino).
## O kit (H04) chama; o erro chega aqui só se `errou(l)` (G03) devolveu false.
func julgar(l: int, j: int, palavra := "", no_tempo_1 := false) -> void
## O combo do lugar, para o cartão. As salas com combo devolvem o delas.
func combo(_l: int) -> int:
	return 0
```

`julgar(l, j, palavra, no_tempo_1)`:

1. `var id := "jul_%s_p%d" % [JUL[j], l + 1]`;
   `Som.tocar(id, jogador(l).global_position + Vector3(0, 1.2, 0), -12.0)`;
   `Som.no_controle(l, id, 0.85)`; `Forja.vibrar(l, VIBRA[j][0], VIBRA[j][1], VIBRA[j][2])`.
2. `julgou.emit(l, j, palavra if palavra != "" else PALAVRA[j])` (o erro emite
   `""`: o Visor não desenha palavra, 07).
3. Fora do treino: `_ressonancias[l]` soma 1 com `j == 3` e volta a 0 com
   outro `j`; em 5, `carimbou.emit(l, "car_em_chamas")` e volta a 0.
4. Fora do treino, com `j == 3 and no_tempo_1`: `_acorde[l] = roundi(Ritmo.batida() / 4.0)`;
   se há 3 ou 4 lugares com `jogando[k]` e todos têm o mesmo `_acorde[k]`,
   `carimbou.emit(-1, "car_acorde")` e `_acorde` volta a `[-1, -1, -1, -1]`.
   Com `j != 3`, `_acorde[l] = -1`.

`centelha.gd` e `impacto.gd`: `func combo(l: int) -> int: return int(j[l].combo) if j.has(l) else 0`.

**A Centelha** é a primeira a chamar (a H04 leva aos outros):

- `_acertou()`: depois do `marcar`, `julgar(l, 3 if rapidez >= 0.66 else (2 if rapidez >= 0.33 else 1))`
  para runa de botão, e `julgar(l, 2)` para as outras (a rapidez delas é
  0,5 fixa); saem `Som.no_controle(l, "martelo", 0.55)` e
  `Forja.vibrar(l, 0.0, 0.2, 50)`. A bigorna e o martelo na TV ficam: são o
  golpe, não o julgamento.
- O botão errado e `_perdeu()`: quando `errou(l)` (G03) devolve `false`,
  `julgar(l, 0)` no lugar de `Som.tocar("falha", …)`.

### O `Visor` (`godot/scripts/ui/visor.gd`, `class_name Visor extends Control`)

```gdscript
const ORDEM := ["car_acorde", "car_virada", "car_em_chamas", "car_por_um_fio", "car_liga"]
const NO_VISOR := {"car_virada": "VIRADA!", "car_em_chamas": "EM CHAMAS", "car_por_um_fio": "POR UM FIO",
	"car_liga": "LIGA!", "car_acorde": "ACORDE MAIOR!", "car_emburrado": ""}
const LETRA := {"car_virada": 64, "car_em_chamas": 46, "car_por_um_fio": 64, "car_liga": 46, "car_acorde": 112}
const SOM := {"car_virada": "jin_virada", "car_em_chamas": "car_em_chamas", "car_por_um_fio": "car_por_um_fio",
	"car_liga": "car_liga", "car_acorde": "car_acorde"}
var jogadores: Array = []   ## os ForjaPlayer (o main põe)
var vivos: Array = []       ## os carimbos na tela: {l, id, palavra, vaga, t, fica, pos}

## O carimbo do julgamento na vaga 0 do lugar (500 ms). O erro (palavra "") não desenha.
func julgamento(l: int, j: int, palavra: String) -> void
## Um carimbo do jogo. `onde`: o cavaleiro do lugar (vaga 1), um Vector2 na tela
## (o placar, a montagem) ou nada (o acorde, no centro). Devolve false se a vez não deixou.
func bater(l: int, id: String, onde: Variant = null) -> bool
## A fala na vaga 1, se ela está livre.
func fala(l: int, texto: String, segundos: float) -> bool
## Onde o adesivo de 112 px se cola (só a conta; o desenho é de outra ficha).
func ancora_do_adesivo(l: int) -> Vector2
## Os carimbos e a fala vivos do lugar (a prova lê).
func do_lugar(l: int) -> Array
```

`bater` toca `Som.tocar(SOM[id], null, -9.0)` e vibra 0,3/0,6/80 no dono
(no `car_acorde`, nos quatro que jogam) só quando o carimbo sai.

O main cria o `Visor` em `_interface()`, logo depois do `hud` (fica acima
dele), com `visor.jogadores = jogadores`; liga em `_entrar_na_sala`
`sala.julgou.connect(visor.julgamento)`,
`sala.carimbou.connect(func(l, id): visor.bater(l, id))` e
`sala.falou.connect(visor.fala)`; zera `visor.vivos` em `_sair_da_sala`.
O `Visor.visible` segue o `hud.visible`, menos no placar e na montagem, onde
ele fica visível para os carimbos da G07 e da G13.

### O HUD (`hud.gd`)

```gdscript
var combo := [0, 0, 0, 0]          ## o main põe, pela sala
var combo_max := [0, 0, 0, 0]      ## o maior da sala (o pico do VU); zera ao entrar
var pontos := [-1, -1, -1, -1]     ## -1: não mostra
## As caixas que o HUD ocupa agora (cartões, etiqueta, deck, placa, avisos, dicas
## de baixo): o _draw desenha nelas e a prova confere que nenhuma encosta.
func retangulos() -> Array
## Troca a etiqueta (06): descola a velha, cola a nova e a caneta escreve.
func trocar_etiqueta(titulo: String, impresso: String, tinta: Color, inclinacao: float, lado_b: bool) -> void
```

`status_da_sala` sai, com as linhas 292 e 562 do main. O main põe, a cada
quadro em `_process`, `hud.combo[l] = sala.combo(l) if sala is SalaJogo and Forja.ocupado(l) else 0`
e `hud.pontos[l] = sala.pontos[l] if sala is SalaJogo else -1`.

### A escala e a língua na prova visual

`godot/scripts/forja.gd`, `aplicar_opcoes()`, logo depois da linha do
`FORJA_IDIOMA`:

```gdscript
	if OS.get_environment("FORJA_TEXTO") == "grande":
		Tema.escala_texto = Opcoes.ESCALA_DO_TEXTO[1]
```

`tests/prova_visual.sh` ganha duas passadas da partida de 4 jogadores
(`--robo=medio`, partida de 3): `FORJA_IDIOMA=en FORJA_TEXTO=grande` e
`FORJA_TEXTO=grande` em português, cada uma com a sua prancha
(`prancha-en-grande.png`, `prancha-pt-grande.png`), montadas do jeito que a
F09 monta as outras.

### As traduções (`traducoes.gd`, as que faltarem)

`"Sem controle": "No controller"`, `"Entrar": "Join"`, `"O Salão": "The Hall"`,
`"Quase": "Close"`, `"Afinado": "In tune"`, `"Ressonância!": "Resonance!"`,
`"EM CHAMAS": "ON FIRE"`, `"ACORDE MAIOR!": "MAJOR CHORD!"`,
`"VIRADA!": "COMEBACK!"`, `"POR UM FIO": "BY A HAIR"`, `"LIGA!": "ALLOY!"`, e
os padrões `["^LADO ([AB]) · FAIXA (\\d\\d)$", "SIDE $1 · TRACK $2"]` e
`["^A FORJA · LADO ([AB])$", "THE FORGE · SIDE $1"]`. Todo grito cabe em 14
caracteres nas duas línguas.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 5 e 8.

1. **O 13 primeiro:** no [kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04),
   na tabela do que o kit faz, a linha «o julgamento | `julgar(l, j, palavra, no_tempo_1)`
   (G04): o `jul_*` do lugar, a vibração e o carimbo; o erro só depois de
   `errou(l)`», e `combo(l) -> int` em `SalaJogo`.
2. **O som:** o encanamento (se ainda não há), as 22 cópias, o import e as
   linhas do mapa.
3. **`sala.gd` e `sala_jogo.gd`:** os três sinais, `julgar`, `combo`, as
   duas contas. **`centelha.gd` e `impacto.gd`:** `combo`. **A Centelha:**
   `julgar` no acerto e no erro.
4. **`desenho.gd`:** `vu`, `contador`, `carretel` (com `giro`), `deck`,
   `carimbo`.
5. **`visor.gd`** (novo, com o `.uid` que o Godot gera no import) e a ligação
   no main.
6. **`hud.gd`:** `cartao()`, os três estados, a etiqueta e o deck,
   `trocar_etiqueta` e o recorte da caneta, o salão, as placas que entram e
   saem, `retangulos()`, os avisos com o tempo novo. `_lugares()` e
   `status_da_sala` saem. O `_draw()` desenha a partir de `retangulos()`: um
   só cálculo para o desenho e para a prova.
7. **`painel_sala.gd`:** `_tempo()` não desenha mais o relógio (o deck é o
   relógio); a linha de progresso e o selo nas posições novas; as pílulas de
   `_dicas()` fogem dos cartões; `func retangulos() -> Array` com a linha de
   progresso e o selo, quando aparecem.
8. **`main.gd`:** o `Visor`, `combo`, `pontos`, `combo_max` zerado ao entrar,
   os sinais, a troca de etiqueta em `_entrar_na_sala` (quando a seção muda).
9. **`forja.gd`** (`FORJA_TEXTO`), **`traducoes.gd`**, **`tests/prova_visual.sh`**.
10. **As provas** (ver Provas).

## Armadilhas

- **Um cálculo só:** `cartao()` e `retangulos()` são a fonte do desenho e da
  prova. Se cada um calcula o seu, a prova passa e a tela colide.
- **Nada abaixo de 30 px:** o nome corta com «…» (`Desenho.caber`), nunca
  encolhe.
- **O texto por `Desenho.texto`/`paragrafo`/`dica`:** um `draw_string` direto
  escapa da coleta da F09. O carimbo também passa por `Desenho` (o
  `Desenho.carimbo` chama `Desenho.t` para traduzir e coletar).
- **O cartão não pulsa nem balança** (05). Só entra e sai.
- **Lugar vazio nunca segura nada:** o cartão vazio é só desenho.
- **Sem `Forja.robo` no HUD nem no Visor.**
- **O erro não tem palavra:** `julgar(l, 0)` toca e vibra, mas não desenha.
- **O Escudo primeiro:** quem chama `julgar(l, 0)` já perguntou `errou(l)`
  (G03). Escudo que absorveu toca o `escudo_*`, não o `jul_erro_*`.
- **A bancada e a sala sem HUD** (`com_hud = false`) continuam sem cartões; o
  `julgar` toca e vibra do mesmo jeito (o som não depende do HUD).
- **O tempo do carimbo é de relógio, não de quadro:** use o `Time.get_ticks_msec()`
  ou o `dt` somado, para o `--fixed-fps` da prova não esticar o carimbo.
- **Os casos que quebram:** `--robo=bom|medio|ruim`, partidas de 1 e 2
  jogadores (os cartões vazios nos outros cantos) e o controle que cai e
  volta (`simulador_cabo`): o cartão vira «Sem controle» e volta sem mudar de
  canto, com os pontos e o combo.

## Não fazer

- Não escrever as falas nem o «Cedo»/«Tarde» (G07); aqui, o lugar e o
  desenho.
- Não disparar `car_virada`, `car_por_um_fio`, `car_emburrado` (G07) nem
  `car_liga` (G13): eles chamam `Visor.bater`.
- Não desenhar o adesivo nem a roda (ficha própria; aqui só a âncora).
- Não mostrar bateria, USB/BT, VID:PID ou «sem módulo».
- Não mudar o que as salas escrevem em `status()`, `progresso()` ou
  `dica()`.
- Não fazer o «Salas vencidas» nem a dica presa ao portão do salão (G06).
- Não levar o `julgar` às outras salas (H04).

## Pronto quando

Os quatro cartões estão nos cantos com nome, pontos, combo, VU e item, nos
três estados; a etiqueta e o deck estão no alto da sala, e o deck conta o
tempo da faixa; n'A Centelha cada acerto bate o carimbo do julgamento acima
do cavaleiro, com o `jul_*` do lugar na TV e na mão, e cinco «Ressonância!»
seguidas batem «EM CHAMAS»; nenhuma caixa do HUD encosta em outra nas duas
línguas e nas duas escalas.

E só fecha com `bash tests/prova_visual.sh` passando nas seis passadas e as
pranchas olhadas; a aparência só se aprova na máquina do André, com placa de
vídeo, sem `--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função nova:

```gdscript
## O HUD nas duas escalas e nas duas línguas: nada encosta e tudo cabe (06).
func _confere_o_hud(onde: String) -> void:
	var escala_antes := Tema.escala_texto
	var idioma_antes := Traducoes.idioma
	var tela := Rect2(Vector2.ZERO, jogo.hud.size).grow(-0.5)
	for idioma in ["pt_BR", "en"]:
		for escala in Opcoes.ESCALA_DO_TEXTO:
			Tema.escala_texto = escala
			Traducoes.idioma = idioma
			var caixas: Array = jogo.hud.retangulos() + jogo.painel.retangulos()
			var ruins: Array = []
			for i in caixas.size():
				var a: Rect2 = caixas[i]
				if not tela.grow(0.5).encloses(a):
					ruins.append("fora %s" % a)
				for k in range(i + 1, caixas.size()):
					if a.intersects(caixas[k]):
						ruins.append("%s × %s" % [a, caixas[k]])
			_esperar(ruins.is_empty(), "HUD %s, %s, %.2f: nada encosta e tudo cabe %s" % [onde, idioma, escala, ruins])
	Tema.escala_texto = escala_antes
	Traducoes.idioma = idioma_antes
	for l in 4:
		var r := HudJogo.cartao(l, jogo.hud.size)
		_esperar(r.position.x >= Tema.MARGEM_X - 0.5 and r.end.x <= jogo.hud.size.x - Tema.MARGEM_X + 0.5
			and r.position.y >= Tema.MARGEM_Y - 0.5 and r.end.y <= jogo.hud.size.y - Tema.MARGEM_Y + 0.5,
			"%s: o cartão do P%d no canto, dentro da área segura" % [onde, l + 1])
```

Chamadas: logo depois de chegar ao salão pela construção
(`_confere_o_hud("no salão")`) e dentro do bloco d'A Centelha que a G03 abriu
(`_comeca_a_sala("centelha")`), depois das checagens do Escudo:

```gdscript
		_confere_o_hud("n'A Centelha")
		_esperar(jogo.hud.retangulos().size() >= 6, "Centelha: os quatro cartões, a etiqueta e o deck")
		# o julgamento: o carimbo, o som e a vibração do P4, sem o controle na mão
		centelha.julgar(3, 3)
		var forte := 0.0
		var fraco := 0.0
		var nota := 0.0
		for q in 6:
			await _quadros(1)
			forte = maxf(forte, float(_perc(3).get("forte", 0.0)))
			fraco = maxf(fraco, float(_perc(3).get("fraco", 0.0)))
			nota = maxf(nota, float(Forja.som_virtual(3).get("falante", 0.0)))
		_esperar(jogo.visor.do_lugar(3).any(func(c): return c.vaga == 0 and c.palavra == "Ressonância!"),
			"o carimbo «Ressonância!» acima do P4")
		_esperar(is_equal_approx(forte, 0.5) and is_equal_approx(fraco, 0.8), "a mão do P4 sente o perfeito (%.2f/%.2f)" % [forte, fraco])
		_esperar(nota > 0.0, "a nota do P4 sai no alto-falante dele (%.2f)" % nota)
		await get_tree().create_timer(0.6).timeout
		_esperar(not jogo.visor.do_lugar(3).any(func(c): return c.vaga == 0), "o carimbo do julgamento some em meio segundo")
		# EM CHAMAS: o 5º seguido
		for k in 4:
			centelha.julgar(3, 3)
		_esperar(jogo.visor.do_lugar(3).any(func(c): return c.id == "car_em_chamas"), "cinco seguidas: EM CHAMAS acima do P4")
		# o erro não desenha
		centelha.julgar(0, 0)
		await _quadros(1)
		_esperar(not jogo.visor.do_lugar(0).any(func(c): return c.vaga == 0), "o erro não tem palavra")
		# o acorde: os quatro no mesmo tempo 1
		for l in 4:
			centelha.julgar(l, 3, "", true)
		_esperar(jogo.visor.vivos.any(func(c): return c.id == "car_acorde"), "os quatro no tempo 1: ACORDE MAIOR!")
		# a vez: um sexto carimbo de ordem mais baixa não sai com dois vivos
		_esperar(not jogo.visor.bater(0, "car_liga"), "a vez: no máximo dois carimbos na tela")
		# a fala não divide a vaga com o carimbo
		_esperar(not jogo.visor.fala(3, "Deixa comigo o refrão!", 2.0), "a fala não aparece com o carimbo vivo do P4")
```

(As contas de `_ressonancias` e `_acorde` só valem fora do treino: o bloco
roda depois do treino, como as checagens do Escudo.)

Num controle que cai: com o `simulador_cabo` da prova de hoje, conferir que o
cartão do lugar passa a «Sem controle» (`Forja.lugar(l).conectado == false`
e o retângulo do cartão no mesmo canto).

**A prova visual (F09):** `bash tests/prova_visual.sh` com as seis passadas;
o `checagens.txt` sem reprovação de texto (nada abaixo de 30 px, nada
sobreposto, nada fora da área segura); nas pranchas, os cartões nos cantos
nas partidas de 4, 2 e 1 jogador, o «Sem controle», a etiqueta e o deck no
alto, um carimbo acima de um cavaleiro.

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo:
   olhar as pranchas, inclusive em inglês e com o texto grande, ao lado de
   `docs/imagens/direcao/01_centelha_depois.jpg`. Anotar no diário.
2. `./run-local.sh`, uma Centelha com um DualSense: o «Ressonância!» bate na
   cor do seu cavaleiro com a sua nota no controle; o erro soa desafinado no
   controle, sem palavra; cinco seguidas, «EM CHAMAS».
3. Numa TV, do sofá: o nome, os pontos e o combo se leem; a etiqueta e o deck
   não encostam nos cartões.
4. Opções › Texto › Grande e Idioma › English: uma sala inteira.

## Ao terminar

No [quadro](README.md), G04 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: o cartão de cada jogador no canto, a etiqueta e o deck da faixa, e o carimbo do julgamento com a nota de cada um
```

## O que foi feito (leva 1, as-telas)

**A medida antes:** no alto da sala, a fileira de quatro chips de 250 × 92 (`hud.gd:108-142`) com o
`status_da_sala` encolhendo até 20 px, abaixo do piso de 30. Nenhum julgamento na tela, nenhum `jul_*`/`car_*` em
`assets/sons/`. Na primeira passada do texto grande em inglês (partida 5 nova da prova visual), o carimbo do
julgamento saía da área segura com o cavaleiro na borda: «Resonance!» em x −49 e «In tune» em x 12.

**O que entrou:**

- `hud.gd`: os quatro cartões nos cantos (`HudJogo.cartao(l, tela)`: 96 px das laterais, 60 do alto ou de baixo,
  420 de largura, a altura cresce com o texto grande), com nome, pontos, combo, VU e item, nos três estados
  (jogando, «Sem controle», vazio); a etiqueta da faixa e o deck no alto, o deck contando o tempo da faixa;
  `retangulos()` para a prova. Os chips antigos saíram da tela.
- `visor.gd` (novo): a camada acima do HUD com a vaga 0 (o carimbo do julgamento, 500 ms) e a vaga 1 (um carimbo
  do jogo ou a fala), a vez de no máximo dois na tela, «EM CHAMAS» na quinta «Ressonância!» seguida, «ACORDE
  MAIOR!» com os quatro no tempo 1. O carimbo que segue o cavaleiro é empurrado para dentro da área segura
  (`Visor.na_area_segura`).
- `sala_jogo.gd`/`sala.gd`: `julgar(l, j, palavra, no_tempo_1)` toca o `jul_*` do lugar na TV e no controle, sente
  pela tabela (`Forja.sentir`) e emite `julgou`; `combo(l)`. Só A Centelha julga por ela (no acerto e no erro que o `errou` deixou passar); O Impacto
  só conta o `combo`, como a ficha pede («não levar o julgar às outras salas»).
- `desenho.gd`: o carimbo, a etiqueta, o VU e a caixa do carimbo. `painel_sala.gd`: o relógio, a linha de progresso,
  o selo do treino e as pílulas saem de cima dos cartões.
- Os 21 sons (`jul_{ressonancia,afinado,quase,erro}_p1..4`, `car_em_chamas`, `car_acorde`, `car_por_um_fio`,
  `car_liga`, `jin_virada`) copiados do estudo para `assets/sons/`, com `estado` = `no jogo` no `mapa.csv`.
- `tests/prova_visual.sh`: as partidas 5 (inglês, texto grande) e 6 (português, texto grande), com as pranchas
  `prancha-en-grande*.png` e `prancha-pt-grande*.png`.

**As provas:** `bash tests/prova_do_jogo.sh` verde (o único FAIL foi o do kit, «kit P2: otimo em N de 12 notas»,
conhecido em todas as árvores e que não é desta ficha: a G14b, antes da G04, já o tinha); `_confere_o_hud` nas duas línguas e nas duas escalas;
`_prova_do_julgamento` (o carimbo, o som no alto-falante do P4, a mão sente 0,5/0,8, some em meio segundo, EM CHAMAS,
o erro sem palavra, o acorde, a vez, a fala, a área segura); os portões verdes.

**As mordidas:** com os cartões no lugar antigo, «HUD n'A Centelha, pt_BR/en, 1.00/1.15: nada encosta e tudo cabe»
reprova nas quatro combinações; com o `Forja.vibrar` direto no julgamento e no visor, o portão «nenhuma vibração fora
da tabela de sensações» reprova (`sala_jogo.gd`, `visor.gd`); com o julgamento quebrado, reprovam «a mão do P4 sente o
perfeito», «cinco seguidas: EM CHAMAS», «a vez» e «a fala»; com o carimbo sem o empurrão, as quatro pontas de «o
carimbo com o cavaleiro em (40, 512) … fica dentro da área segura» reprovam. Tudo restaurado e verde de novo.

**A prova visual** (`PASSADAS=fixa PARTIDAS="5 6"`, as duas partidas novas do texto grande): os cartões nos cantos, a
etiqueta e o deck no alto e os carimbos acima dos cavaleiros, olhados nas pranchas. O HUD não reprovou nada. O carimbo
fora da área segura («Resonance!» em x −49, «Ressonância!» em x −84, «In tune» em 12, «Afinado» em −1) foi curado depois
da passada, e a cura está provada na prova do jogo, não numa segunda passada. As outras reprovações não são do HUD: o
título, o cartão do resultado, o placar e o contraste do carimbo sobre o chão aceso viraram a ficha
[G04c](G04c-o-texto-grande-fora-do-hud.md). A tela parada já é da F09b e da F09d. **O «Pronto quando» pede as seis
passadas verdes, e elas não fecham enquanto a G04c e a F09b estiverem abertas.**

**Escolhas a validar por ela** (a ficha não decidia):

- As tarjas do «ACORDE MAIOR!»: uma tarja por lugar com o P# no papel, embaixo da palavra.
- `quadro_da_sala`, `LARG_CHIP` e `status_da_sala` continuam no `hud.gd`, mas não se desenham mais (a G06 e o
  diagnóstico ainda escrevem neles).
- O acerto d'A Centelha não vibra mais pelo `"acerto"` além do julgamento: a vibração é só a do julgamento.
- O contador da G06 desceu para y 60; o deck tem 376 px de largura, com a janela da fita de 196; a fala sai inteira até a metade do sumiço (o
  papel não tem alfa); o número da seção vem de `Catalogo.apelido`.
- O carimbo do cavaleiro na borda anda para dentro da área segura em vez de sumir.

**Ficou para depois:** [G04b](G04b-as-placas-que-entram-e-a-troca-de-etiqueta.md), as placas que entram e a troca de
etiqueta com a caneta (só movimento), e [G04c](G04c-o-texto-grande-fora-do-hud.md). As fichas novas não ganharam
linha no quadro, porque quem marca o quadro é quem coordena.

**Para o André (local):** os quatro itens de «Para o André» acima, sem mudança: a prova visual sem `--fixed-fps`
com a placa de vídeo (as pranchas em inglês e com o texto grande ao lado de `01_centelha_depois.jpg`), a Centelha
com um DualSense (a nota no controle, o erro desafinado, EM CHAMAS), a TV do sofá e Opções › Texto › Grande com
Idioma › English.

**A conferência:** três frases deste relato estavam erradas e foram corrigidas acima (o cartão tem 420 de largura,
não 520; só A Centelha julga; o deck tem 376, a janela da fita é que tem 196). Os avisos do portão de som não eram
«os mesmos de antes»: subiram de 171 para 174, três ids que o portão não lê. O do visor (`Som.tocar(SOM[id])`) virou
um `match` com o id escrito em cada chamada, e o portão confere os cinco no mapa; os dois do `julgar`
(`"jul_%s_p%d"`) ficam, porque o portão só lê o literal na chamada, e os 16 ids estão no mapa. O portão de arte
acusava uma cor nova em `desenho.gd` (`Color(0, 0, 0, 0)` na `placa`), agora `Color.TRANSPARENT`. A prova de EM
CHAMAS passava com o limiar em 6: agora zera a conta, confere que quatro seguidas não acendem e que a quinta acende;
mordida com o limiar em 6, reprova.
