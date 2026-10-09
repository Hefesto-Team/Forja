# O4 — Fuga do Mecha Cego

**Sprint:** O · **Slot:** S07_J34 · **Tamanho:** M · **Depende de:** H04, H07, H08, F09, O1, G05, G10, G13, G14, G15

## Por quê

O mecha é cego e caça pelo som. Os passos dele chegam **no atuador do lado em que ele está**, esquerdo ou direito, e
cada cavaleiro o sente do seu lugar. Quem foge para o lado oposto no tempo e **congela quando ele para** sobrevive. É a
prova do isolamento esquerda e direita da háptica, sem perguntar nada: o lado que o jogador escolhe diz se o lado
chegou. A diversão dá nota 5 («o melhor terror do jogo»); o que muda é o verbo, o mecha à vista na captura e a reta.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A diversão da seção O](../diversao/O-os-caminhos.md)

Tudo o mais está copiado aqui: o `_pista`, o `_respondeu`, o `_robo_sente`, os ids de som, os números de luz e câmera,
e o contrato do `Cega` da bancada (o mesmo da O1).

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s07/fuga_do_mecha_cego.gd` e o `.uid` | novo | não |
| `godot/scripts/minigames/catalogo.gd` | `"S07_J34"` em `MINIGAMES` e na seção `S07`, depois do `S07_J33` | **sim** |
| `godot/scripts/traducoes.gd` | as frases novas | **sim** |
| `godot/testes/prova_do_jogo.gd` | a `_prova_mecha_cego()` no `match` de `_prova_da_ficha` | **sim** |
| `godot/assets/kenney/factory-kit/`, `modular-cave-kit/`, `graveyard-kit/` | `python3 scripts/importar_kenney.py "oficina/kenney/3.7.0/3D assets" factory-kit modular-cave-kit graveyard-kit` (G10; o `graveyard-kit` já vem da O1) | **sim** (a O5 usa o `factory-kit`) |

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J34",
	"titulo": "Fuga do Mecha Cego",
	"verbo": "Pare quando ele parar!",
	"genero": "sobrevivencia",
	"icone": "haptica",
	"entradas": [Forja.ESQUERDA, Forja.DIREITA, Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S07_J34",
	"duracao": 100.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir"],
	"material": "pedra",
	"microjogo": {"verbo": "Pare!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"features": ["haptica_audio"],     # a bancada: os lados da háptica saem das fugas
	"gesto": "lados",
}
```

O verbo é o da [diversão](../diversao/O-os-caminhos.md#o4--fuga-do-mecha-cego). `CRUZ` é do fantasma (em «A falha»).

## Como se joga

A faixa é `MUS_S07_J34`, 140 bpm (uma batida = 0,4286 s). `BATIDA_DA_PRIMEIRA_NOTA` = 4 (do kit).
`_fim_b := floor(duracao / _t_batida())` = 233.

**Uma ronda** dura `FRASE := 8` batidas; a ronda `f` começa em `b0 = BATIDA_DA_PRIMEIRA_NOTA + 8 * f`. Cada ronda tem
uma ou duas **paradas**. Em cada parada o mecha sorteia onde está, com o `_rng` do jogo (semente do kit + 34):
`_x_mecha = [-8.0, -4.0, 0.0, 4.0, 8.0][_rng.randi_range(0, 4)]` (nunca o x de uma raia). Para o lugar `l`, o lado é `0`
(esquerda) se `_x_mecha < RAIAS[l]`, senão `1` (direita).

| ronda | os passos | a fuga (a nota) | o silêncio | a varredura |
| --- | --- | --- | --- | --- |
| normal | `b0`, `b0 + 1`, `b0 + 2`, `b0 + 3`, num atuador só | `b0 + 4` | `b0 + 4` + 140 ms até `b0 + 6.5` | `b0 + 6` |
| pico (o mecha corre) | 8 colcheias de `b0` a `b0 + 3.5`, **atravessando a mão** | `b0 + 4` | até `b0 + 7.5` | `b0 + 5` e `b0 + 7` |
| reta (ele para duas vezes) | `b0`, `b0 + 1`; depois `b0 + 4`, `b0 + 5` (um novo `_x_mecha`) | `b0 + 2` e `b0 + 6` | até `b0 + 3.5` e `b0 + 7.5` | `b0 + 3` e `b0 + 7` |

- **Os passos (normal e reta):** `material:metal` **só no atuador do lado**, ganho `0.45 + 0.55 * clampf(1.0 -
  absf(_x_mecha - RAIAS[l]) / (14.0 * raio), 0.0, 1.0)` (perto = forte), × 0,6 se um fantasma fez barulho na ronda
  anterior. O primeiro passo de cada parada vai pelo `_pista` (`o_que` = `"esquerda"` ou `"direita"`); os outros, por
  `Forja.som_haptica` direto.
- **Os passos no pico (mágica 1):** o mecha atravessa a palma. As 8 colcheias vão, aos pares, com os ganhos (lado de
  partida, lado de chegada) = (1,0; 0), (0,7; 0,3), (0,3; 0,7), (0; 1,0), e **o lado de chegada é o lado da parada**: é
  dele que se foge. O lado de partida é o oposto. Ganho 1,0 × o abafado.
- **A fuga:** ◀ ou ▶ de `fuga - 1` até a nota passar. Lado oposto ao do mecha → `julgar_toque(l, alvo, n, true)`
  (o alvo é `Ritmo.t_da_batida(fuga)`). Mesmo lado → `_respondeu(l, n, "errado")`, `nota_perdida(l, n)`. Nada até a
  nota passar → `_respondeu(l, n, "nenhuma")`, `nota_perdida(l, n)`. O cavaleiro corre (`sprint`, 0,5 batida /
  `velocidade`) para o lado apertado da coluna.
- **O barulho:** ◀ ou ▶ no silêncio (depois de a nota da fuga fechar, até o fim do silêncio) → `_exposto[l] = true`.
- **A falha da fuga** (o kit chama `falha` depois de descontar o Escudo) → `_exposto[l] = true`.
- **A varredura:** cada lugar vivo e conectado com `_exposto[l]` e `absf(_x_mecha - RAIAS[l]) <= 10.0 * ruido` é
  **pego** (o grito). Quem está exposto e longe demais escapa por pouco.
- **Os pontos:** a fuga julgada marca `PONTOS_FUGA[j]` = `[0, 25, 40, 50][j]` (na reta, ×2); sobreviver à última
  varredura da parada marca 100.
- **O hoqueto:** todos fogem na mesma batida, cada um para o seu lado; a nota de cada um soa na TV (o kit). O acorde da
  fuga só fecha se todos acertam.
- **A partitura simples** (`Ritmo.simples[l]`): os passos da ronda normal começam 1 batida antes (`b0 - 1`, cinco
  passos); a fuga não muda. No pico e na reta, nada muda.
- **O pico:** as três rondas a partir de `_pico_f := floor((_fim_b - BATIDA_DA_PRIMEIRA_NOTA) / FRASE / 2)` = 14 (b0 de
  116 a 132, 49,7 s a 66 s).
- **A reta:** as rondas com `b0 >= _fim_b - 16` (b0 220 e 228). A ronda 228 é cortada pelo fim aos 100 s: vale o que
  couber.
- **Ensina sem falar:** na ronda 0, o mecha fica **à vista** a ronda inteira, no x dele; o primeiro passo vem do lado
  dele. Da ronda 1 em diante, ele só aparece 0,5 batida antes de cada varredura.

## A cena

**A câmera:** `camera_pos = Vector3(0, 6.5, 13.0)`, `camera_olhar = Vector3(0, 2.4, -1.8)`, no começo do `montar()`.
Lente de 35 mm (37,8° vertical), plongée de 15°, 15,4 m do alvo, 18,7 m de largura vista. A câmera baixa faz o mecha
crescer sobre a sala. Medido com a projeção da lente: os cavaleiros de fora (x ±6,8, escondidos) ficam a 91 % da meia
largura, e o topo do mecha (6,6 m) a 83 % da meia altura. Roll zero. Nunca corta. Enquanto o kit não tem a lente por
sala, vale o campo de 40° de hoje com a mesma pose.

**A luz** (S7, lado B, tinta petróleo `Tema.SECAO[2]`): `Tema.luz_da_secao(7, "B")` (G15): névoa `#011311`,
preenchimento `#11413b`, chave `#e5d7ad`, chave ×0,85 e névoa ×1,3. **O terror é a mesma luz, escurecida:** a chave e o
preenchimento a ×0,35. Saem o `atmosfera(Color("#b9b0ff"), ...)`, as tochas `#ffb070`, o aço `#4a4452` e o olho
`#ff3a1a` de hoje.

- **O pico:** a luz não muda (a pressa do mecha é o pico).
- **A catástrofe:** em cada pego, a chave sobe 40 % (de ×0,35 a ×0,49) por 1 batida e volta em 1 batida; com
  `Opcoes.flashes` desligado, sobe 20 % em 2 batidas.

**O mecha** (peças do kit, `Kit.peca`; o `factory-kit` já entra a 0,5× pelo `ESCALA_DO_PACOTE` da G10, então a escala
pedida é o dobro do tamanho final), um `Node3D` `_mecha` em `(_x_mecha, 0, -5.4)`:

| parte | peça | escala pedida | tamanho final | onde, em `_mecha` |
| --- | --- | --- | --- | --- |
| as pernas | `factory-kit/piston-round`, duas | 5,0 | 2,5 × 2,5 × 2,5 m | `(±1.3, 0, 0)` |
| o tronco | `factory-kit/machine` | 4,0 | 2,4 × 2,6 × 3,0 m | `(0, 2.5, 0)` |
| a cabeça | `factory-kit/screen-small` | 3,0 | 0,9 × 1,49 × 0,75 m | `(0, 5.1, 0.6)` |
| o olho | `Kit.caixa(_mecha, Vector3(0.5, 0.25, 0.08), Vector3(0, 5.85, 1.0), Tema.neon(Tema.VIOLETA, 1.2, "mundo"))` | — | — | `visible` só na varredura |
| o holofote | `SpotLight3D`, cor `Tema.TUNGSTENIO`, `spot_angle` 18°, alcance 16 m | — | — | `(0, 5.8, 1.0)`; energia 0, e 4,0 na varredura, apontado para a raia de cada pego |

Altura total: 6,6 m, 3,7 vezes o cavaleiro (1,8 m). O mecha fica `visible = false` fora das janelas de aparecer (a
ronda 0 inteira; 0,5 batida antes de cada varredura até o começo dos próximos passos). Em cada pego, ele gira para o
pego em 0,5 batida: `_mecha.rotation.y = atan2(RAIAS[l] - _x_mecha, Z_JOGADOR + 5.4)`.

**O resto da cena** (G10):

| papel | peça | escala | onde |
| --- | --- | --- | --- |
| o chão | `Kit.arena(self, 5, 3)` (do kit) | — | — |
| o esconderijo de cada raia | `graveyard-kit/column-large` | 2,4 (0,94 × 2,71 × 0,94 m) | `(RAIAS[l], 0, Z_JOGADOR - 0.9)`; o cavaleiro em `RAIAS[l] ± 0.8` |
| o fundo | `modular-cave-kit/gate-rock`, três | 4,0 (o pacote a 0,25×: 4,0 × 4,05 × 2,45 m) | `(-8, 0, -8.5)`, `(0, 0, -8.5)`, `(8, 0, -8.5)` |
| as árvores | `graveyard-kit/pine-crooked`, quatro | 1,6 | `(±11.5, 0, -6)` e `(±11.5, 0, -2)` |
| a névoa onde o mecha anda | `Efeitos.poeira(self, Vector3(0, 1.2, -5.4), Vector3(22, 2.4, 3.0), Tema.ETIQUETA_SOMBRA, 80)` | — | — |
| a lanterna caída do pego | `graveyard-kit/lantern-candle` | 1,5 | ao pé do pego, `+0.4` em x |

`metallic` no máximo 0,2 em tudo. Partículas vivas no máximo 300.

**O que brilha e de quem é:**

| o quê | energia | dono |
| --- | --- | --- |
| a coluna de `l`, `Tema.contorno(Tema.JOGADOR[l], 0.03, 2.0, l)` | 2,0; 2,6 por 4 quadros na fuga certa | `l` |
| a luz de dono, `OmniLight3D` cor `Tema.JOGADOR[l]`, em `(RAIAS[l], 0.3, Z_JOGADOR - 2.9)` | 0,9, alcance 2,0 m: o cavaleiro fica a 3,0 m, fora do alcance; 0 depois de pego | `l` |
| o olho do mecha | 1,2, só na varredura | `"mundo"` |
| as faíscas do barulho do fantasma, `Efeitos.faiscas(self, pos, Tema.JOGADOR[l], 12, 0.6)` | 2,4 por 12 quadros | `l` |
| qualquer outra coisa | no máximo 1,0 | `"mundo"` |

**O cavaleiro na cena:** `raia(l)` e `posicionar(l)` do kit; `p.rotation.y = PI`, `p.preso = true`; a posição x anda
por `lerpf` na fuga (pela batida).

## O som

Só ids do mapa (`docs/jogo/audio/mapa.csv`):

| evento | id | onde toca | chamada |
| --- | --- | --- | --- |
| a faixa | `mus_s07_j34` (140 bpm) | TV | a `faixa` da FICHA |
| o passo do mecha | `mod_material_metal` | **um** atuador do dono | `Forja.som_haptica(l, "material:metal", "", g)` ou `(l, "", "material:metal", g)` |
| a fuga certa (o kit) | `mod_material_pedra` | atuadores do dono | o `material` da FICHA, pelo kit |
| o mecha aparece | `martelo_*` | TV, no mecha | `Som.tocar("martelo", _mecha.global_position, -2.0)` na batida em que aparece |
| o pego, na TV | `sint_sino` | TV | `Som.tocar("sino", null, -6.0)` |
| o pego, no dono | `mod_grito` | alto-falante do dono | `Forja.som_falante(l, "grito", 0.5)` |
| o barulho do fantasma | `carimbo_*` | TV | `Som.tocar("carimbo", pos, -4.0)` |

A TV nunca toca nada durante os passos: um som posicional do mecha entregaria o lado a todos. `mod_material_metal` ainda
não lista a O4 na coluna `fichas` do mapa: o diretor de som acrescenta.

## O controle

| evento | para quem | háptica (cabo) | rumble (rádio ou um canal só) | prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| o passo (normal, reta) | só o dono | `material:metal` **só no lado do mecha** | `Forja.sentir(l, "golpe_esq")` ou `"golpe_dir"` | `Forja.som_virtual(l)`: no 1º passo (até 0,3 batida), o lado dele > 0,05 e o outro < 0,02 |
| o passo no pico (mágica 1) | só o dono | as colcheias atravessam: o lado de partida 1,0 no 1º par, o de chegada 1,0 no 4º | os dois primeiros pares no motor de partida, os dois últimos no de chegada | no 1º par, partida > 0,05 e chegada < 0,02; no 4º par, o contrário |
| a fuga certa | o dono | `material:pedra` (o kit) | `acerto` (o kit) | a linha `toque` |
| o pego | o dono | — | `Forja.sentir(l, "golpe")` nos dois modos | `Forja.percepcao(l).forte > 0` no quadro do pego |
| a barra | o dono | a cor do lugar a 30 % (`darkened(0.7)`) | a mesma | `Forja.percepcao(l).luz` a menos de 0,08 dela, fora do piscar do kit |
| o pego na barra (mágica 2) | o pego | de 30 % a 100 % em 0,05 s, de volta a 30 % em 0,43 s | a mesma | entre `t_pego + 0.05` e `t_pego + 0.08`, `luz` a menos de 0,1 de `cor_do_lugar(l)` |
| o grito | o pego | o alto-falante | o mesmo | `som_virtual(l).falante > 0,05` no quadro do pego |

- **Sem os dois lados:** `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA) or not Forja.som_estereo(l,
  Forja.PAPEL_HAPTICA)`; a `troca` tem `motivo` `sem_placa` ou `sem_estereo`, uma vez.
- **A barra, como se manda:** `Forja.luz(l, ...)` no `iniciar_jogo()`, no pego, e 0,5 s depois de cada `toque` e
  `falha` (o piscar do kit). Só quando a cor muda. 30 % é o piso da F04.
- **O gatilho:** `Forja.gatilhos_off(l)` no `montar()`. Prova: `percepcao(l).gatilho_dir == 0`.
- **O microfone:** não se usa.

O código da pista, igual nas cinco fichas da seção:

```gdscript
func _pista(l: int, esq: String, dir: String, sensacao: String, n: int, o_que: String) -> void:
	if _rumble[l]:
		Forja.sentir(l, sensacao)
	else:
		Forja.som_haptica(l, esq, dir, 1.0)
	anotar("pista", l, {"n": n, "evento": "mandou",
		"canal": "rumble" if _rumble[l] else "haptica", "o_que": o_que})


func _respondeu(l: int, n: int, resposta: String) -> void:
	anotar("entrada", l, {"o": "resposta", "n": n, "resposta": resposta})
```

O passo com ganho: o `_pista` manda 1,0; o primeiro passo de cada parada passa pelo `_pista` com o som no lado certo e
o ganho aplicado por `Forja.som_haptica(l, esq, dir, g)` logo depois, no mesmo quadro, só no cabo (no rádio o `_pista`
já mandou o `sentir`). Escreva um `_passo(l, g_esq, g_dir, primeiro, n)` que faça isso.

## O cavaleiro

Chega pronto da G13 (`jogador(l)`), de qualquer raça (humana, orc, autômato, golem, raposa), com a cabeça, o superior,
o inferior e o item. A ficha **nunca recolore** nem muda a energia de uma peça: o superior fica na faixa do tecido (L
0,46 a 0,58), o inferior na do couro (0,22 a 0,36), o néon do dono só nos acentos, a 1,6. **O fantasma não é
transparente nem cinza:** o pego fica deitado (`die`, a última pose segurada) na raia dele até o fim, com as tintas da
montagem; o que diz «fantasma» é a lanterna caída, a luz de dono apagada e o `status`. O holofote é luz do mundo
(`TUNGSTENIO`), não tinta. A luz de dono fica 2,9 m à frente e não chega às peças.

Os ganchos (`Cavaleiro.gancho(l, "<gancho>")`, H04; a O4 no `minigames.csv`):

| stat | gancho | o que muda aqui | 1 | 3 | 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `ruido` | o mecha ouve o exposto até `10 m × gancho` | ×0,8 (8 m) | ×1 (10 m) | ×1,2 (12 m) |
| Passo | `velocidade` | a corrida para o lado da coluna: 0,5 batida / gancho (só a animação) | ×0,94 | ×1 | ×1,06 |
| Faro | `raio` | o alcance do passo na mão: o divisor 14 m × gancho | ×0,8 | ×1 | ×1,2 |
| Faro | `pista` | os passos chegam antes: `- pista / 1000 / 0.4286` batida | −40 ms | 0 | +40 ms |

O Peso alto é pior aqui (o mecha ouve mais longe); o Fôlego não se usa (não há queda). **Os itens:** o Martelo dobra o
PERFEITO da fuga, que cai no tempo 1 (o kit); a Âncora corre 10 % mais devagar; o Escudo absorve o primeiro erro de
fuga (o kit não chama `falha`, e ele não fica exposto), não o barulho; o Fole é do combo (o kit); a Lanterna adianta os
passos meio tempo (0,21 s), somada ao Faro. O Diapasão não muda nada. A cadeira de rodas corre na velocidade do Passo.
Nenhum stat nem item muda a janela (140 ms) nem os pontos.

## As reações

Os carimbos vêm do kit; a ficha não chama nada:

- `car_acorde`: os quatro com PERFEITO na mesma fuga, que cai no tempo 1 (`b0 + 4`). Possível.
- `car_em_chamas`: 5 «Ressonância!» seguidas do mesmo jogador.
- `car_por_um_fio`: o vencedor com 2 % dos pontos ou menos de vantagem.
- `car_virada`: quem passa a ser o primeiro.
- `car_emburrado`: o último, no inserto do resultado.

No máximo 1 carimbo vivo por jogador e 2 na tela. **Adesivos `rea_*`:** os fantasmas podem mandar (estão fora da
rodada); os vivos, não.

## A diversão

**O grito: o holofote** (`pego`), degrau «catástrofe». Quem se mexe quando ele para é pego: o mecha aparece e gira para
ele, o olho acende, o holofote cai sobre a raia, o cavaleiro faz `die`, o alto-falante dele grita. A sala inteira prende
o ar em cada parada.

- **O exagero:** o objeto é 3,7 vezes o cavaleiro; a chave +40 % por 1 batida; `tremer(Sala.TREMOR_EXPLOSAO)` (G05,
  o degrau pede 0,08 por 4 batidas); **sem** hit-stop; a mão (`golpe`), a barra (mágica 2), a TV (sino) e o grito no
  mesmo quadro.
- **O rastro:** o cavaleiro fica caído no holofote até o fim da ronda (o holofote apaga no `b0` seguinte); a lanterna
  caída fica no chão até o fim da partida.
- **O dono do grito:** a luz de dono dos outros cai 30 % por 1 batida e volta em 1 batida.
- **A linha:** no pego, `anotar("momento", l, {"nome": "pego", "t_musica": Ritmo.t_musica()})`. Na batida `_fim_b -
  16`, `anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": vencedor()})`.
- **A curva:** 0 a 49,7 s, o mecha anda (um lado por parada); 49,7 a 66 s, o mecha corre (atravessa a mão, duas
  varreduras); 66 s ao fim, as rondas normais e os fantasmas fazendo barulho; nas últimas 16 batidas, duas paradas por
  ronda, e as fugas valem 2.
- **Quem está perdendo:** o fantasma aperta ✕ uma vez por ronda, nos passos; os passos da ronda seguinte chegam a 0,6
  para todos os vivos. Fica.

**Como o jogador do time confere** (mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

1. Robô: pelo menos 2 linhas `momento` `pego` em 100 s, a primeira do P4, e 1 `momento` `reta`.
2. Prancha: um holofote aceso em 1 quadro de cada 5.
3. Enquanto o robô por lugar não existe, a mesa padrão se confere só pela prancha, com o temperamento único (aí a
   primeira captura pode não ser do P4).

**O que se corta:** nada. Nunca na mesma partida que a P3 (README da diversão, regra 3): isso é do sorteio da noite, não
desta ficha.

## A falha

- **Pego:** o grito. Com dois ou mais, ele vira **fantasma**: fica deitado, e em cada ronda pode apertar ✕ uma vez
  nos passos (`b0` a `b0 + 3.9`): o barulho dele (`carimbo`, as 12 faíscas na cor dele) deixa os passos da ronda
  seguinte a ×0,6 para todos os vivos.
- **Com um jogador só:** três vidas (`_vidas[l] = 3`): pego, perde uma, levanta (`emote-no`, 0,6 s) e segue.
- **A fuga errada ou atrasada** não derruba na hora: deixa exposto (`falha`), e a varredura decide.

## O fim e o vencedor

`ultimo_em_pe`: com dois ou mais, quando sobra um vivo, ele vence e, no fim daquela ronda, todos acabam. Todos pegos na
mesma varredura: acaba ali, e a colocação é pelos pontos. Com um, acaba nas três capturas ou aos 100 s. `vencedor()`: os
vivos pelos pontos; depois os pegos, do último pego ao primeiro (`_pego_em[l]`).

## Com menos de quatro

- **3, 2:** nada muda. **1:** três vidas.
- **O controle que cai:** quem está sem controle não recebe passos nem nota e **não pode ser pego** (o holofote o
  ignora); quando volta, entra na próxima parada que ainda não começou.
- **Duplas:** não há.

## O robô

Sente o lado nos atuadores (ou nos motores), foge para o outro no tempo, e erra pelo temperamento. No pico, só os dois
últimos passos contam (é o lado de chegada).

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var p := _parada_agora()      # {"n", "de", "ate", "fuga"}: a parada em curso
	if p.is_empty():
		return
	var n: int = p.n
	var b := Ritmo.batida()
	if _robo_n[l] != n:
		_robo_n[l] = n
		_robo_somas[l] = Vector2.ZERO
		_robo_fugiu[l] = false
		_robo_certo[l] = Forja.robo_acerta()
	# os dois últimos tempos dos passos: o lado de chegada no pico, o lado de sempre fora dele
	if b >= float(p.ate) - 2.0 and b < float(p.ate) - 0.1:
		_robo_somas[l] += _robo_sente(l)
	if _pego[l]:
		if presentes().size() > 1 and b >= float(p.de) + 1.0 and b < float(p.de) + 1.2 and _robo_barulho[l] != n:
			_robo_barulho[l] = n
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		return
	if _robo_fugiu[l] or Ritmo.t_musica() < Ritmo.t_da_batida(float(p.fuga)):
		return
	var somas: Vector2 = _robo_somas[l]
	var lado := 0 if somas.x > somas.y else 1
	var para := Forja.DIREITA if lado == 0 else Forja.ESQUERDA
	if not _robo_certo[l]:
		para = Forja.ESQUERDA if para == Forja.DIREITA else Forja.DIREITA   # foge para o lado do mecha
	Forja.robo_apertar(l, para, 0.05)
	_robo_fugiu[l] = true


## O que a mão do controle simulado sente agora: (esquerda, direita).
func _robo_sente(l: int) -> Vector2:
	if _rumble[l]:
		var pc := Forja.percepcao(l)
		return Vector2(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0)))
	var v := Forja.som_virtual(l)
	return Vector2(float(v.get("esq", 0.0)), float(v.get("dir", 0.0)))
```

Sem nada sentido, `somas` fica zero e ele foge para a direita: o defeito de mentira que corta um atuador aparece como
erro de lado no veredito. O robô nunca mexe no silêncio (não faz barulho).

## Os ganchos

`godot/scripts/minigames/s07/fuga_do_mecha_cego.gd`, `extends Minigame`, sem `class_name`.

```gdscript
extends Minigame
## Fuga do Mecha Cego (S07_J34). O mecha cego caça pelo som; os passos dele
## chegam só no atuador do lado em que ele está. Fuja para o outro lado da
## coluna no tempo (◀ ou ▶) e pare quando ele parar.

const FICHA := { ... }   # a de cima

const FRASE := 8
const XS_MECHA := [-8.0, -4.0, 0.0, 4.0, 8.0]
const PONTOS_FUGA := [0, 25, 40, 50]
const PICO_RONDAS := 3
const PICO_PARES := [[1.0, 0.0], [0.7, 0.3], [0.3, 0.7], [0.0, 1.0]]   ## (partida, chegada)
const OUVIDO := 10.0
const ABAFADO := 0.6

var _rng := RandomNumberGenerator.new()   ## o x do mecha (a semente do kit + 34)
var _robo_rng := RandomNumberGenerator.new()
var _f := -1                 ## a ronda da vez
var _paradas: Array = []     ## as paradas da ronda: {"n", "de", "ate", "fuga", "varre": [..], "x"}
var _n := 0                  ## o número da próxima parada (a nota)
var _x_mecha := 0.0
var _lado := [0, 0, 0, 0]
var _passos_feitos := {}     ## "n:i" -> true
var _exposto := [false, false, false, false]
var _pego := [false, false, false, false]
var _pego_em := [-1.0, -1.0, -1.0, -1.0]
var _t_pego := [-9.0, -9.0, -9.0, -9.0]
var _vidas := [1, 1, 1, 1]
var _abafado := false        ## um fantasma fez barulho nesta ronda: a próxima vem mais fraca
var _abafa_proxima := false
var _varridas := {}          ## "n:b" -> true
var _pico_f := 999
var _fim_b := 233
var _reta_anotada := false
var _rumble := [false, false, false, false]
var _le := {}                ## lugar -> Cega (mecha à esquerda)
var _ld := {}                ## lugar -> Cega (mecha à direita)
var _fora := [false, false, false, false]
var _fim_ronda := -1
var _nos := {}
var _robo_n := [-1, -1, -1, -1]
var _robo_somas := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _robo_fugiu := [false, false, false, false]
var _robo_certo := [true, true, true, true]
var _robo_barulho := [-1, -1, -1, -1]


func montar() -> void:
	camera_pos = Vector3(0, 6.5, 13.0)
	camera_olhar = Vector3(0, 2.4, -1.8)
	Kit.arena(self, 5, 3)
	# a luz a 0,35, o mecha, as colunas, o fundo, a névoa: «A cena»
	for p in jogadores:
		_nos[p.lugar] = _montar_raia(p.lugar)
		_le[p.lugar] = Cega.nova()
		_ld[p.lugar] = Cega.nova()
		Forja.gatilhos_off(p.lugar)


func iniciar_jogo() -> void:
	_rng.seed = rng.seed + 34
	_robo_rng.seed = rng.seed + 99
	_fim_b = int(floor(duracao / _t_batida()))
	_pico_f = int(floor(float(_fim_b - BATIDA_DA_PRIMEIRA_NOTA) / FRASE / 2.0))
	for l in presentes():
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA) or not Forja.som_estereo(l, Forja.PAPEL_HAPTICA)
		if _rumble[l]:
			var motivo := "sem_placa" if not Forja.som_tem(l, Forja.PAPEL_HAPTICA) else "sem_estereo"
			anotar("troca", l, {"de": "haptica", "para": "rumble", "motivo": motivo})
		Forja.luz(l, Forja.cor_do_lugar(l).darkened(0.7))
		_vidas[l] = 3 if presentes().size() == 1 else 1


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	if b >= _fim_b - 16 and not _reta_anotada:
		_reta_anotada = true
		anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": vencedor()})
	var f := floori((b - BATIDA_DA_PRIMEIRA_NOTA) / FRASE)
	if f < 0:
		_mostrar(b)
		return
	if f != _f:
		if _fim_ronda >= 0 and _f == _fim_ronda:
			for l in presentes():
				acabou[l] = true
			return
		_f = f
		_nova_ronda()               # monta _paradas pela tabela; sorteia o x de cada parada; abre as notas
	for p in _paradas:
		_passos_do_mecha(p, b)       # os passos de cada lugar vivo e conectado, uma vez cada (_passos_feitos)
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			continue
		if _pego[l]:
			_fantasma(l, b)           # ✕ nos passos: _abafa_proxima = true (uma vez por ronda por fantasma)
			continue
		_fuga(l, b)                   # a nota da fuga e o barulho do silêncio
	_varrer_se_hora(b)                # em cada batida de "varre" de cada parada, uma vez
	_barra()
	_mostrar(b)


func toque(l: int, j: int) -> void:
	var p := _parada_agora()
	var reta := float(p.get("de", 0.0)) >= _fim_b - 16
	marcar(l, PONTOS_FUGA[j] * (2 if reta else 1))
	_respondeu(l, int(p.get("n", -1)), "certo")
	if not _rumble[l] and not _no_pico():
		Cega.certo(_le[l] if _lado[l] == 0 else _ld[l])


func falha(l: int) -> void:
	_exposto[l] = true
	jogador(l).gesto("emote-no", 0.3)


func vencedor() -> Array:
	var vivos := presentes().filter(func(l): return not _pego[l])
	vivos.sort_custom(func(a, b): return pontos[a] > pontos[b])
	var pegos := presentes().filter(func(l): return _pego[l])
	pegos.sort_custom(func(a, b): return _pego_em[a] > _pego_em[b])
	return vivos + pegos


func dar_vereditos(l: int) -> Array:
	var tem := Forja.som_tem(l, Forja.PAPEL_HAPTICA)
	var v := Forja.cega_veredito(l, "haptica_audio", {"cega": Cega.nova(), "esq": _le[l], "dir": _ld[l], "tem": tem})
	return [] if v.is_empty() else [v]


func _t_batida() -> float:
	return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)
```

**Os lados para a bancada.** A fuga diz de que lado a mão sentiu o mecha: fugir para a direita é «o mecha está à
esquerda» (`0`); para a esquerda, «está à direita» (`1`). O `Cega` é `_le[l]` quando o mecha estava à esquerda e
`_ld[l]` quando à direita. Fuga certa: `Cega.certo(c)` (no `toque`). Fuga para o lado errado: `Cega.errado(c, dito)`,
com `dito` = o lado que a fuga disse. Sem fuga: `Cega.perdido(c)`. Só entra quem tem os dois atuadores
(`not _rumble[l]`), e **o pico fica fora** (lá os dois atuadores tocam, e o lado é o de chegada).

As funções que faltam, pelo que já foi dito:

- `_nova_ronda()`: as paradas da tabela (normal, pico ou reta); para cada uma, `x` sorteado com `_rng`; `_abafado =
  _abafa_proxima`, `_abafa_proxima = false`; zera `_exposto`; `nova_nota(l, n, Ritmo.t_da_batida(fuga))` para cada
  vivo conectado; o holofote apaga.
- `_parada_agora()`: a parada cujo `de` já passou e cujo silêncio ainda não acabou; `{}` fora delas. Ao entrar numa
  parada, `_x_mecha = p.x` e `_lado[l]` de cada um.
- `_passos_do_mecha(p, b)`: os passos da tabela, adiantados pelo Faro e pela Lanterna, pelo `_passo(...)`.
- `_fuga(l, b)`: a regra da fuga e do barulho. `_fantasma(l, b)`: o ✕ do fantasma.
- `_varrer_se_hora(b)`: o mecha aparece 0,5 batida antes (`martelo`); na batida, para cada vivo conectado exposto e
  ao alcance do `ruido`: `_pego[l]` (ou `_vidas[l] -= 1` com um), `_pego_em[l] = b`, `_t_pego[l] =
  Ritmo.t_musica()`, o grito; quem sobrou marca 100 na última varredura da parada; com dois ou mais e um só vivo,
  `_fim_ronda = _f`; todos pegos: `_fim_ronda = _f`.
- `_barra()`: 30 %; no pego, `darkened(lerpf(0.7, 0.0, dt / 0.05))` de 0 a 0,05 s e `darkened(lerpf(0.0, 0.7, (dt -
  0.05) / 0.43))` de 0,05 a 0,48 s; e a volta 0,5 s depois do piscar do kit.
- `_no_pico()`: `_f >= _pico_f and _f < _pico_f + PICO_RONDAS`.
- `_montar_raia(l)` e `_mostrar(b)`: a cena.

A dica (com a guarda `if not na_raia(l): return {}`): `["@dpad_left", "@dpad_right"]` sob a raia enquanto `not
aprendeu(l)`; o fantasma, `["@cross"]`. O `status(l)`: `"Vivo"` ou `"Fantasma"` (com um jogador, `"%d vidas" %
_vidas[l]`).

`godot/scripts/traducoes.gd`: `"Fuga do Mecha Cego": "Escape the Blind Mech"`, `"Pare quando ele parar!": "Stop when it
stops!"`, `"Pare!": "Stop!"`, `"Vivo": "Alive"`, `"Fantasma": "Ghost"`, `"%d vidas": "%d lives"`. Tire `"Esconda-se!"`
se `grep -rn` não achar outro uso.

## O que o registro mede

- `pista` `mandou` de cada parada com o lado (`o_que`) e o `canal`; a `entrada` `resposta` da fuga (`certo`, `errado`,
  `nenhuma`);
- o isolamento esquerda e direita dos atuadores: com os lados de cada controle, a noite vê «P3 fugiu certo 90 % com o
  mecha à esquerda e 40 % à direita»: o atuador direito não chega;
- `troca` com `sem_estereo` quando a placa só tem um canal; o veredito `haptica_audio` (lados) na bancada;
- `momento` `pego` e `reta`.

## Armadilhas

- **Nunca os dois atuadores no passo fora do pico.** `Forja.som_haptica(l, som, "", g)` para a esquerda e
  `Forja.som_haptica(l, "", som, g)` para a direita. O acerto do kit toca nos dois lados na fuga, depois dos passos.
- **A TV não diz o lado.** Nenhum som na TV durante os passos; o mecha invisível fora das janelas de aparecer.
- **O barulho do silêncio** só conta depois de a nota da fuga fechar (senão a própria fuga seria barulho).
- **Quem está sem controle não é pego**: senão o cabo que cai elimina.
- **A prova roda a `duracao` inteira** pelo relógio de parede: o pico e a reta chegam.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo que cai e volta;
fecha com vencedor; o passo treme só o atuador do lado fora do pico e atravessa a mão no pico; a barra sobe a 100 % no
pego; com `--bancada` o `haptica_audio` sai medido pelos lados (sem o pico); a mesa padrão grava pelo menos 2 `pego`; e
as provas abaixo passam com a prancha olhada.

## Provas

`_prova_mecha_cego()` em `godot/testes/prova_do_jogo.gd`, chamada pelo `match` de `_prova_da_ficha(slot)`:
`"S07_J34": await _prova_mecha_cego()`.

```gdscript
## S07_J34: o passo treme só o atuador do lado (fora do pico) e atravessa a
## mão no pico; a barra do pego sobe a 100 %; fecha com vencedor.
func _prova_mecha_cego() -> void:
	var um_lado := [0]
	var vazou := [0]
	var atravessou := [false, false]   # [partida no 1º par, chegada no 4º par]
	var barra_pego := [0]
	var olhar := func(mg: Minigame) -> void:
		var b := Ritmo.batida()
		var p: Dictionary = mg._parada_agora()
		for l in mg.presentes():
			if mg._t_pego[l] > 0.0:
				var dt := Ritmo.t_musica() - float(mg._t_pego[l])
				var c: Color = Forja.percepcao(l).get("luz", Color.BLACK)
				var cheia := Forja.cor_do_lugar(l)
				if dt >= 0.05 and dt <= 0.08 and Vector3(c.r - cheia.r, c.g - cheia.g, c.b - cheia.b).length() < 0.1:
					barra_pego[0] += 1
			if p.is_empty() or mg._pego[l] or mg._rumble[l]:
				continue
			var v := Forja.som_virtual(l)
			var lado: int = mg._lado[l]
			var dele := float(v.get("esq" if lado == 0 else "dir", 0.0))
			var outro := float(v.get("dir" if lado == 0 else "esq", 0.0))
			var de := float(p.de)
			if not mg._no_pico():
				if b > de + 0.05 and b < de + 0.3 and dele > 0.05:
					um_lado[0] += 1
					if outro >= 0.02:
						vazou[0] += 1
			else:
				if b > de + 0.05 and b < de + 0.3 and outro > 0.05 and dele < 0.02:
					atravessou[0] = true   # 1º par: o lado de partida (o oposto)
				if b > de + 3.05 and b < de + 3.3 and dele > 0.05 and outro < 0.02:
					atravessou[1] = true   # 4º par: o lado de chegada
	var mg := await _joga_o_minigame("S07_J34", 140.0, olhar)
	if mg == null:
		return
	_esperar(um_lado[0] >= 4, "S07_J34: o passo chegou a um atuador só (%d quadros)" % um_lado[0])
	_esperar(vazou[0] == 0, "S07_J34: o passo nunca vazou para o outro atuador fora do pico (%d)" % vazou[0])
	_esperar(atravessou[0] and atravessou[1], "S07_J34: no pico o passo atravessou a mão %s" % [atravessou])
	_esperar(mg._pego.has(true) == (barra_pego[0] > 0), "S07_J34: a barra do pego subiu a 100 %% (%d)" % barra_pego[0])
	_esperar(mg.colocacao().size() == mg.presentes().size(), "S07_J34: a colocação tem todos")
	_confere_os_vereditos(mg, ["haptica_audio"])
```

No `_prova_do_relatorio()`, no laço da linha do tempo, do `S07_J34`: ≥ 4 `entrada` `resposta`; 1 `momento` `reta` se a
partida chegou à batida 217; cada `momento` `pego` tem um `toque` ou uma nota perdida do mesmo lugar na parada antes.

Os comandos:

1. `SALA=S07_J34 bash tests/prova_do_jogo.sh`
2. `bash tests/prova_visual.sh`, e olhar a prancha nas partidas com quatro (`bom` e `ruim`), com dois, com um e com o
   cabo que cai. O que se olha: o mecha inteiro no quadro quando aparece (pés e cabeça), invisível nos passos fora da
   ronda 0, um holofote em 1 quadro de cada 5, os pegos deitados com as tintas da montagem, nada de tela vazia no
   escuro.
3. Na máquina do André: `./run-local.sh -- --sala=S07_J34`, com um controle no cabo. O lado do passo tem de ser óbvio na
   palma sem olhar a tela; no pico, o passo tem de atravessar a palma; o fantasma que faz barulho tem de fazer os vivos
   xingarem. Com `--bancada`, confira no relatório o `haptica_audio` com os lados.

## Ao terminar

- No [quadro](README.md), a linha O4: **feito**, com o commit.
- Commit sugerido: `feat(mecha): Fuga do Mecha Cego no kit, o lado do passo só na mão e o holofote na captura`
