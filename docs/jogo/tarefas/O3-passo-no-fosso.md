# O3 — Passo no Fosso: a dança das placas

**Sprint:** O · **Slot:** S07_J33 · **Tamanho:** M · **Depende de:** H04, H07, H08, F09, O1, G05, G10, G13, G14, G15

## Por quê

A sala de hoje é a O2 com outro tempo: a mão pulsa, salte para avançar, cada um na sua raia (nota 2 na diversão). A
seção tinha dois verbos iguais e nenhum contato. A troca é **a dança das placas**: um fosso de plasma, uma ilha de
placas no meio, os quatro em volta, e **menos placas que cavaleiros**. No contratempo, cada um aponta o analógico para
uma placa e pisa com ✕; quem chega mais perto do contratempo fica, quem chega depois na mesma placa é empurrado para o
plasma. A dança das cadeiras com o contratempo sentido na mão. Fica o que a seção mede: o pulso no contratempo e o
vapor que só a mão atravessa.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A diversão da seção O](../diversao/O-os-caminhos.md)

Tudo o mais está copiado aqui: o `_pista`, o `_respondeu`, os ids de som e os números de luz e câmera.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s07/passo_no_fosso.gd` e o `.uid` | novo | não |
| `godot/scripts/minigames/catalogo.gd` | `"S07_J33"` em `MINIGAMES` e na seção `S07`, depois do `S07_J32` | **sim** |
| `godot/scripts/traducoes.gd` | as frases novas | **sim** |
| `godot/testes/prova_do_jogo.gd` | a `_prova_passo_no_fosso()` no `match` de `_prova_da_ficha` | **sim** |
| `godot/assets/kenney/platformer-kit/` | `python3 scripts/importar_kenney.py "oficina/kenney/3.7.0/3D assets" platformer-kit` (G10) | **sim** |
| `docs/jogo/sistemas/minigames.csv`, linha da O3 | `genero` de `corrida` para `tct`; os ganchos não mudam | **sim** |

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J33",
	"titulo": "Passo no Fosso",
	"verbo": "Pise no contratempo!",
	"genero": "tct",
	"icone": "haptica",
	"entradas": [Forja.CRUZ],          # a placa se escolhe com o analógico, lido por Forja.mover(l)
	"camera": "fixa",
	"faixa": "MUS_S07_J33",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "grama",
	"microjogo": {"verbo": "Pise!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "jump",
}
```

O `material` é `grama` (o ruído macio) para o acerto do kit não se confundir com o pulso da placa, `material:metal` (o
clique seco). O `genero` passa a `tct`: não há mais corrida.

## Como se joga

A faixa é `MUS_S07_J33`, 150 bpm (uma batida = 0,4 s; um compasso = 4 batidas = 1,6 s). `BATIDA_DA_PRIMEIRA_NOTA` = 4
(do kit). `_fim_b := floor(duracao / _t_batida())` = 225.

**A geometria** (o centro do fosso `C := Vector3(0, 0, -1)`; o ângulo `a` em graus, 0° para a direita da tela, 90° para
o fundo): `_no_circulo(a, r) = C + Vector3(r * cos(deg_to_rad(a)), 0, -r * sin(deg_to_rad(a)))`.

- **Os cantos** (raio 4): P1 em 135°, P2 em 45°, P3 em 225°, P4 em 315° (x ±2,83, z −3,83 ou 1,83). Cada cavaleiro fica
  no seu canto, virado para `C`: `p.rotation.y = atan2(C.x - pos.x, C.z - pos.z)`.
- **As placas** (raio 1,4): com quatro, **3 placas** em 90°, 210° e 330°; no pico, **2 placas** em 0° e 180°. Com menos
  gente, em «Com menos de quatro».

**Um compasso** começa em `c0 = BATIDA_DA_PRIMEIRA_NOTA + 4 * m`. O salto é no contratempo do 2: `alvo =
Ritmo.t_da_batida(c0 + 1.5)`, a nota `m` de todos.

| batida | o que acontece |
| --- | --- |
| `c0` | todos no canto; o analógico já escolhe (a placa do líder acende, abaixo) |
| `c0 + 1.0` | a entrada abre (200 ms antes do alvo); antes disso o ✕ é ignorado |
| `c0 + 1.5` | **o salto**: ✕ no contratempo, a placa que o analógico aponta |
| `c0 + 1.5 + 0,35 batida` (alvo + 140 ms) | **a resolução** de quem fica em cada placa |
| `c0 + 3.5` a `c0 + 4` | quem está numa placa salta de volta ao canto (`jump`, 0,5 batida) |

- **A escolha da placa:** no aperto, `v := Forja.mover(l)` (o analógico esquerdo e o d-pad, com zona morta; `LY`
  positivo é para baixo, para a câmera). Se `v.length() >= 0.3`, a placa de maior `Vector3(v.x, 0, v.y).normalized()
  .dot((placa - canto).normalized())`; senão, a placa mais perto do canto. A escolha não se troca depois do ✕.
- **O julgamento:** `_motivo[l] = "caiu"`, `_desvio[l] = Ritmo.t_musica() - alvo`, `_placa[l] = <a escolhida>` e
  `julgar_toque(l, alvo, m, true)` (o plasma é perigo físico: quem está em último ganha a folga do kit). ERRO (fora de
  140 ms) → `falha`: o salto sai curto e ele cai no plasma em frente ao canto.
- **A resolução** (uma vez por compasso, em `alvo + Ritmo.JANELA_BOM`): para cada placa, entre os que pisaram nela com
  BOM ou melhor, **fica o de menor `absf(_desvio)`**. No empate (mesmo quadro), fica quem tem menos `_vezes`; depois, o
  menor lugar. Os outros são **empurrados** (o grito). Quem ficou: `_vezes[l] += 1` (2 na placa de ouro), `marcar(l,
  100)` (200 na de ouro), `_respondeu(l, m, "certo")`.
- **Sem ✕ até o alvo + 140 ms:** `_motivo[l] = "parou"` e `nota_perdida(l, m)`: ele fica no canto, `emote-no` (0,4 s).
  Não perde nada além do compasso.
- **O pulso na mão** (de todos, à vista): as placas afundam em cada batida inteira e sobem em cada contratempo:
  `y = -0.35 * (0.5 + 0.5 * cos(TAU * fposmod(b, 1.0)))`, no fundo em `b` inteiro e no alto em `b + 0.5`. Em **todo**
  contratempo `k + 0.5` (de `k = BATIDA_DA_PRIMEIRA_NOTA - 1` em diante), cada lugar recebe `material:metal` nos dois
  atuadores, ganho 0,7 (`Forja.som_haptica` direto: é metrônomo, não informação). No contratempo **do salto**
  (`c0 + 1.5`), o pulso vai pelo `_pista` com ganho 1,0 (`o_que` = `"contratempo"`), adiantado pelo Faro e pela
  Lanterna.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar salta só nos compassos de `m` par; nos ímpares fica no canto,
  sem nota, e não perde nada.
- **O pico, o vapor** (de 30 a 60 s: os compassos com `c0` de 76 a 148, `PICO_DE := 76`, `PICO_ATE := 152`): **2
  placas** em 0° e 180°. As duas novas aparecem paradas 2 batidas antes do primeiro compasso do pico (em `PICO_DE - 2`),
  e as três de antes afundam e somem no mesmo instante. O vapor cobre as placas: elas param de subir e descer na tela
  (`y` fica em −0,1) e só o pulso na mão marca o contratempo. A TV toca `Som.tocar("vento", null, -6.0)` na entrada. No
  fim do pico, as 3 placas voltam do mesmo jeito (2 batidas antes, paradas).
- **A reta** (os compassos com `c0 + 1.5 >= _fim_b - 16`, isto é `c0` de 208 a 220, quatro compassos): em cada um, uma
  das 3 placas é **de ouro**, sorteada pelo `rng` do kit, à vista desde `c0`. Ficar nela vale 2 vezes e 200 pontos.
- **O líder** (o maior `_vezes`, depois os pontos; sem líder se o topo empata ou se todos têm 0): a placa para onde o
  analógico dele aponta (a mesma regra da escolha) tem o contorno da cor dele de `c0` até a resolução, e a placa em que
  ele ficou, até a volta. Os outros sabem de quem tirar.
- **Ensina sem falar:** na contagem (batidas 0 a 4), as placas já sobem no contratempo e a mão pulsa; em `b` 2,5 os
  quatro cavaleiros saltam sozinhos para as placas mais perto, e um sobra e escorrega (só animação, sem nota, sem
  registro de `momento`). A sala entende a cadeira em 2 s.

## A cena

**A câmera:** `camera_pos = Vector3(0, 9.8, 7.0)`, `camera_olhar = Vector3(0, 0.7, -1.0)`, no começo do `montar()`. Lente
de 35 mm (37,8° vertical), plongée de 49°, 12,1 m do alvo; em 16:9, 14,8 m de largura vista. Medido com a projeção da
lente: a cabeça dos cavaleiros do fundo fica a 69 % da meia altura, os pés dos da frente a 66 %, e o canto da frente
do plasma a 87 %. Roll zero. Nunca corta. Enquanto o kit não tem a lente por sala, vale o campo de 40°
de hoje com a mesma pose.

**A luz** (S7, lado B, tinta petróleo `Tema.SECAO[2]`): `Tema.luz_da_secao(7, "B")` (G15): névoa `#011311`,
preenchimento `#11413b`, chave `#e5d7ad`, com a chave a ×0,85 e a névoa a ×1,3. Saem o `luzes(...)`, o
`atmosfera(Color("#ffb070"), Tema.CIANO, ...)` e o plasma `Tema.CIANO` de hoje.

- **O pico:** na entrada do vapor, a chave sobe 20 % em 1 batida e a névoa abre (densidade ×0,8); volta em 2 batidas no
  fim do pico. Com `Opcoes.flashes` desligado, sobe 10 % em 2 batidas.
- **O dono do grito:** no empurrão de `l`, o contorno do canto dos outros três cai 30 % (de 2,0 a 1,4) por 1 batida e
  volta em 1 batida.

**As peças** (G10, `Kit.peca(pai, "<pacote>/<peça>", pos, rot_y, escala)`):

| papel | peça | escala | onde |
| --- | --- | --- | --- |
| o chão em volta | `Kit.arena(self, 5, 3)` (do kit) | — | — |
| o plasma | `Kit.caixa(self, Vector3(7.0, 0.05, 7.0), Vector3(0, 0.01, -1), plasma)` | — | o fosso, centrado em `C` |
| o canto de cada um | `platformer-kit/platform` | 1,6 (1,6 × 0,32 × 1,6 m) | no canto do lugar; o cavaleiro em `y = 0.32` |
| a placa | `platformer-kit/block-moving` | 1,4 (1,4 × 0,42 × 1,4 m) | em `_no_circulo(a, 1.4)`, `y` pela fórmula do pulso; o cavaleiro nela em `y + 0.42` |
| o vapor | `Efeitos.poeira(self, Vector3(0, 0.4, -1), Vector3(4.4, 0.8, 4.4), Tema.ETIQUETA, 60)` | — | `emitting` só no pico |

`plasma := Tema.emissivo(Kit.material(Tema.SECAO[2], 0.0, 0.9), 1.0, "mundo")`: o petróleo da seção, energia 1,0,
dono `"mundo"`. `metallic` no máximo 0,2 em tudo. Partículas vivas no máximo 300 (o vapor usa 60).

**O que brilha e de quem é:**

| o quê | energia | dono |
| --- | --- | --- |
| a placa do líder, `Tema.contorno(Tema.JOGADOR[lider], 0.04, 2.0, lider)` | 2,0; 2,6 por 4 quadros quando ele fica nela | o líder |
| a placa de ouro (a reta), `Tema.contorno(Tema.TUNGSTENIO, 0.04, 2.4, "forja")` | 2,4 | `"forja"` |
| o canto de `l`, `Tema.contorno(Tema.JOGADOR[l], 0.03, 2.0, l)` | 2,0; 2,6 por 4 quadros quando ele fica numa placa | `l` |
| o plasma | 1,0 | `"mundo"` |
| qualquer outra coisa | no máximo 1,0 | `"mundo"` |

Quando a placa de ouro é também a do líder, fica o contorno de ouro (o líder já se vê pelo canto). **Não há luz de
dono** aqui: no fosso ela cairia sobre os cavaleiros das placas ou fora do quadro; o dono se lê pelo contorno do canto.

## O som

Só ids do mapa (`docs/jogo/audio/mapa.csv`):

| evento | id | onde toca | chamada |
| --- | --- | --- | --- |
| a faixa | `mus_s07_j33` (150 bpm) | TV | a `faixa` da FICHA |
| o pulso de todo contratempo | `mod_material_metal` | atuadores de cada um | `Forja.som_haptica(l, "material:metal", "material:metal", 0.7)` |
| o pulso do salto | `mod_material_metal` | atuadores do dono | `_pista(l, "material:metal", "material:metal", "acerto", m, "contratempo")` |
| ficou na placa (o acerto do kit) | `mod_material_grama` | atuadores do dono | o `material` da FICHA, pelo kit |
| o empurrão e a queda, na mão | `mod_material_lama` | atuadores do dono | `Forja.tocar_material(l, "lama", "golpe", 1.0)` |
| o empurrão e a queda, na TV | `falha_*` e `fx_tropeco_*` | TV | `Som.tocar("falha", pos, -6.0)` |
| a placa de ouro | `mod_coleta` | alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` |
| o vapor | `sint_vento` | TV | `Som.tocar("vento", null, -6.0)` |

## O controle

| evento | para quem | háptica (cabo) | rumble (rádio) | prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| todo contratempo | cada um | `material:metal`, 0,7, nos dois | `Forja.sentir(l, "toque")` | `Forja.som_virtual(l)`: de `k + 0.5` a `k + 0.6`, `esq` e `dir` > 0,05 |
| o contratempo do salto | o dono | `material:metal`, 1,0, nos dois | `Forja.sentir(l, "acerto")` **meio tempo antes** (`c0 + 1.0`) | a linha `pista` `mandou` com `canal` |
| ficou | o dono | `material:grama` (o kit) | `acerto` (o kit) | a linha `toque` |
| empurrado ou caiu | o dono | `material:lama`, `golpe` | `Forja.sentir(l, "golpe")` | `Forja.percepcao(l).forte > 0` no quadro do empurrão |
| a barra (mágica 3) | cada um | a cor do lugar a 60 % (`darkened(0.4)`), a 100 % por 80 ms em cada contratempo (2,5 por segundo) | a mesma | `Forja.percepcao(l).luz`: a 0,04 s do contratempo, a menos de 0,1 de `cor_do_lugar(l)`; a 0,25 s, a menos de 0,1 de `darkened(0.4)` |
| a barra sem Flashes | cada um | a cor do lugar a 100 %, parada | a mesma | `luz` a menos de 0,08 de `cor_do_lugar(l)` em todo quadro fora do piscar do kit |
| a placa de ouro | o dono | a coleta no alto-falante | a mesma | `som_virtual(l).falante > 0,05` no quadro da resolução |

- **O analógico:** lido por `Forja.mover(l)`; o robô o mexe com `Forja.robo_eixo(l, Forja.LX, x, 0.6)` e
  `Forja.robo_eixo(l, Forja.LY, y, 0.6)`. Prova: a placa escolhida pelo robô é a que ele mirou (`_placa[l] ==
  _robo_alvo[l]` em todo salto do robô bom).
- **A barra, como se manda:** `Forja.luz(l, ...)` só quando a cor muda (duas vezes por contratempo). Depois de cada
  `toque` e `falha`, espera 0,5 s (o piscar do kit) antes de voltar a pulsar.
- **No rádio:** o acerto do kit é rumble no instante do salto; por isso o pulso da nota sai meio tempo antes no rádio,
  nunca junto (rumble e háptica nunca juntos, 05). `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)` e a linha
  `troca` (`haptica` → `rumble`, `sem_placa`) uma vez.
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

## O cavaleiro

Chega pronto da G13 (`jogador(l)`), de qualquer raça (humana, orc, autômato, golem, raposa), com a cabeça, o superior,
o inferior e o item. A ficha **nunca recolore** nem muda a energia de uma peça: o superior fica na faixa do tecido (L
0,46 a 0,58), o inferior na do couro (0,22 a 0,36), o néon do dono só nos acentos, a 1,6. O empurrado **não** fica
«molhado de ciano»: o respingo é o rastro no chão e as gotas em partículas, nunca uma cor nele. Não há luz de dono: nada
ilumina as peças com a cor de alguém. A raça não muda o salto, o empurrão nem a janela.

Os ganchos (`Cavaleiro.gancho(l, "<gancho>")`, H04; a O3 no `minigames.csv`):

| stat | gancho | o que muda aqui | 1 | 3 | 5 |
| --- | --- | --- | --- | --- | --- |
| Passo | `velocidade` | o voo do salto até a placa: 0,35 batida / gancho (só a animação; a resolução não muda) | ×0,94 | ×1 | ×1,06 |
| Fôlego | `levantar` | a volta do plasma ao canto: 2 batidas × gancho, arredondado a 0,25 batida, mínimo 0,25 | ×1,25 | ×1 | ×0,75 |
| Faro | `pista` | o pulso do salto chega antes: `- pista / 1000 / 0.4` batida | −40 ms | 0 | +40 ms |

O Peso não se usa. **Os itens:** o Martelo não muda nada (o salto é no contratempo, nunca no tempo forte); a Âncora
empurrada escorrega só 0,5 m e volta em metade do tempo, e voa 10 % mais devagar (multiplica o `velocidade`); o Escudo
absorve o primeiro ERRO (o kit), não o empurrão; o Fole é do combo (o kit); a Lanterna adianta o pulso do salto meio
tempo (0,2 s), somada ao Faro. O Diapasão não muda nada (não é dupla). A cadeira de rodas salta na velocidade do
Passo. Nenhum stat nem item muda a janela (140 ms), a resolução nem os pontos.

## As reações

Os carimbos vêm do kit; a ficha não chama nada:

- `car_virada`: quem passa a ser o líder (o primeiro em `_vezes`).
- `car_em_chamas`: 5 «Ressonância!» seguidas do mesmo jogador.
- `car_por_um_fio`: o vencedor com 2 % dos pontos ou menos de vantagem.
- `car_emburrado`: o último, no inserto do resultado.
- `car_acorde`: **não sai** aqui: todo salto é no contratempo, nunca no tempo 1.

No máximo 1 carimbo vivo por jogador e 2 na tela. Adesivos `rea_*`: não há quem esteja fora da rodada (ninguém sai).

## A diversão

**O grito: o empurrão no plasma** (`empurrao`), degrau «estrondo». Dois cavaleiros pulam na mesma placa; o atrasado voa
para trás e cai no plasma: de `placa` até `placa + (placa - C).normalized() * 1.0` em 0,25 batida, `y` de 0,42 a −0,5,
`p.gesto("fall", 0.5)`. Sobe pelo canto em `2 * levantar` batidas.

- **O exagero:** 48 partículas no respingo (`Efeitos.faiscas(self, pos, Tema.SECAO[2], 48, 1.0)`);
  `tremer(Sala.TREMOR_GOLPE)` (G05); hit-stop de 3 quadros (50 ms) só no empurrado (`p.anim.speed_scale = 0.0`, de volta
  a 1,0 depois de 0,05 s); a mão, a TV e a luz no mesmo quadro.
- **O rastro:** a mancha do respingo na borda, `Kit.caixa(self, Vector3(1.2, 0.02, 1.2), <pos na borda>, plasma)`, que
  some 4 s de música depois; e as gotas: `Efeitos.faiscas(self, p.global_position + Vector3(0, 0.8, 0),
  Tema.SECAO[2], 10, 0.3)` em cada contratempo até o próximo salto dele.
- **A linha:** no empurrão, `anotar("momento", l, {"nome": "empurrao", "t_musica": Ritmo.t_musica(), "por": <o lugar
  que ficou>})`. Na batida `_fim_b - 16`, `anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(),
  "ordem": <os lugares por _vezes>})`.
- **A queda por ERRO** (o salto curto) usa o mesmo plasma, as mesmas 48 partículas e o mesmo tremor, sem `momento`.
- **A curva:** 0 a 30 s, 3 placas para 4, um salto por compasso; 30 a 60 s, o vapor: 2 placas, dois empurrões por
  compasso; 60 s ao fim, 3 placas, e nas últimas 16 batidas a placa de ouro, que todos querem.
- **Quem está perdendo:** volta em 2 batidas e pula no compasso seguinte (o próximo salto é 4 batidas depois do anterior).

**Como o jogador do time confere** (mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

1. Robô: pelo menos 6 linhas `momento` `empurrao` em 90 s, pelo menos 3 com `t_musica` entre 30 e 60 s, e 1 `momento`
   `reta`.
2. Prancha: no pico, um cavaleiro no plasma em 1 quadro de cada 3.
3. Enquanto o robô por lugar não existe, a mesa padrão se confere só pela prancha, com o temperamento único.

## A falha

- **Empurrado:** o grito, acima. `_em_placa[l] = -1`, `_volta_ate[l] = b + maxf(0.25, snappedf(2.0 * levantar, 0.25))`;
  enquanto `b < _volta_ate[l]` ele não salta (sem nota nesse compasso, se cair nele).
- **Caiu** (ERRO): o salto curto, 0,7 m à frente do canto, no plasma; a mesma volta.
- **Parou** (sem ✕): `emote-no` no canto.

## O fim e o vencedor

`"fim": "tempo"`: o kit fecha aos 90 s de música. `vencedor()`: por `_vezes` (do maior ao menor), depois pelos pontos,
depois o menor lugar.

## Com menos de quatro

- **As placas:** `_n_placas := maxi(1, presentes().size() - 1)` no `iniciar_jogo()`; no pico, `maxi(1, _n_placas - 1)`.
  Os ângulos: 3 placas em 90°, 210°, 330°; 2 em 0° e 180°; 1 no centro (raio 0). Com quatro: 3 e 2. Com três: 2 e 1. Com
  dois: 1 e 1. Com um: 1 placa, e ele pontua em todo salto certo (é o treino da cadeira).
- **Os cantos** não mudam: cada lugar no seu.
- **O controle que cai:** o lugar fica no canto, sem nota (`_fora[l] = true`); o número de placas não muda. Quando
  volta, salta a partir do próximo compasso.
- **Duplas:** não há.

## O robô

Mira a placa mais perto do canto dele; 1 em 4 compassos, a de outro (sorteada entre as restantes). Mexe o analógico no
começo do compasso e pisa pelo relógio da música.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo or _fora[l]:
		return
	var b := Ritmo.batida()
	var m := _compasso(b)
	if m < 0 or b < _volta_ate[l] or (Ritmo.simples[l] and m % 2 == 1):
		return
	var c0 := BATIDA_DA_PRIMEIRA_NOTA + 4 * m
	if _robo_m[l] != m and b >= c0 + 0.5:
		_robo_m[l] = m
		var placas := _placas_agora()
		var perto := _mais_perto(CANTO[l], placas)
		_robo_alvo[l] = perto
		if placas.size() > 1 and _robo_rng.randf() < 0.25:
			_robo_alvo[l] = (perto + 1 + _robo_rng.randi_range(0, placas.size() - 2)) % placas.size()
		var d: Vector3 = (placas[_robo_alvo[l]] - CANTO[l]).normalized()
		Forja.robo_eixo(l, Forja.LX, d.x, 0.6)
		Forja.robo_eixo(l, Forja.LY, d.z, 0.6)
		var certo := Forja.robo_acerta()
		_robo_mira[l] = 0.0 if certo else (0.1 if _robo_rng.randf() < 0.6 else 99.0)
	if _robo_m[l] == m and _robo_pisou[l] != m:
		if Ritmo.t_musica() >= Ritmo.t_da_batida(c0 + 1.5) + float(_robo_mira[l]):
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
			_robo_pisou[l] = m
```

`_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`. O robô bom mira com desvio 0: dois robôs bons na mesma placa
empatam no quadro, e o empate decide por `_vezes` e pelo lugar. O `medio` e o `ruim` atrasam 100 ms (BOM, perde a
placa para quem foi no tempo) ou não pisam.

## Os ganchos

`godot/scripts/minigames/s07/passo_no_fosso.gd`, `extends Minigame`, sem `class_name`.

```gdscript
extends Minigame
## Passo no Fosso (S07_J33), a dança das placas. Um fosso de plasma, menos
## placas que cavaleiros; no contratempo, o analógico aponta e ✕ pisa. Fica
## quem chegou mais perto do contratempo; o atrasado vai para o plasma.

const FICHA := { ... }   # a de cima

const C := Vector3(0, 0, -1)
const CANTO := [Vector3(-2.83, 0.32, -3.83), Vector3(2.83, 0.32, -3.83), Vector3(-2.83, 0.32, 1.83), Vector3(2.83, 0.32, 1.83)]
const RAIO_PLACA := 1.4
const ANGULOS := {3: [90.0, 210.0, 330.0], 2: [0.0, 180.0], 1: [0.0]}
const PICO_DE := 76
const PICO_ATE := 152
const EMPURRAO := 1.0
const PONTOS_PLACA := 100

var _n_placas := 3
var _placa := [-1, -1, -1, -1]       ## a placa escolhida no salto deste compasso
var _desvio := [0.0, 0.0, 0.0, 0.0]
var _julgou := [-1, -1, -1, -1]      ## o compasso em que o lugar pisou com BOM ou melhor
var _em_placa := [-1, -1, -1, -1]
var _vezes := [0, 0, 0, 0]
var _volta_ate := [-1.0, -1.0, -1.0, -1.0]
var _motivo := ["", "", "", ""]
var _ouro := -1                      ## a placa de ouro do compasso (−1 fora da reta)
var _resolvido := -1                 ## o último compasso resolvido
var _aberto := -1                    ## o último compasso aberto
var _pulso_feito := -1
var _reta_anotada := false
var _rumble := [false, false, false, false]
var _fora := [false, false, false, false]
var _nos := {}                       ## as placas, o vapor, os cantos
var _robo_rng := RandomNumberGenerator.new()
var _robo_m := [-1, -1, -1, -1]
var _robo_pisou := [-1, -1, -1, -1]
var _robo_alvo := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 9.8, 7.0)
	camera_olhar = Vector3(0, 0.7, -1.0)
	Kit.arena(self, 5, 3)
	# o plasma, os cantos com o contorno do dono, as placas e o vapor: «A cena»
	for p in jogadores:
		p.global_position = CANTO[p.lugar]
		p.rotation.y = atan2(C.x - CANTO[p.lugar].x, C.z - CANTO[p.lugar].z)
		p.preso = true
		Forja.gatilhos_off(p.lugar)


func iniciar_jogo() -> void:
	_robo_rng.seed = rng.seed + 99
	_n_placas = maxi(1, presentes().size() - 1)
	for l in presentes():
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)
		if _rumble[l]:
			anotar("troca", l, {"de": "haptica", "para": "rumble", "motivo": "sem_placa"})


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	var k := int(floor(b))
	if b >= k + 0.5 and _pulso_feito < k and k >= BATIDA_DA_PRIMEIRA_NOTA - 1:
		_pulso_feito = k
		_pulsar(k)                 # o metrônomo de todos e o pulso do salto
	if b >= _fim_b() - 16 and not _reta_anotada:
		_reta_anotada = true
		anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": vencedor()})
	var m := _compasso(b)
	if m >= 0:
		if _aberto < m:
			_aberto = m
			_novo_compasso(m)          # zera _placa, _em_placa; sorteia o ouro na reta; abre as notas (nova_nota)
		var c0 := BATIDA_DA_PRIMEIRA_NOTA + 4 * m
		var alvo := Ritmo.t_da_batida(c0 + 1.5)
		for l in presentes():
			if not conectado(l):
				_fora[l] = true
				continue
			_fora[l] = false
			if _salta_neste(l, m) and _julgou[l] != m and _placa[l] < 0 and b >= c0 + 1.0:
				if Forja.apertou(l, Forja.CRUZ):
					_placa[l] = _escolher(l)
					_desvio[l] = Ritmo.t_musica() - alvo
					_motivo[l] = "caiu"
					julgar_toque(l, alvo, m, true)
				elif Ritmo.t_musica() > alvo + FOLGA_PERDIDA:
					_placa[l] = -2
					_motivo[l] = "parou"
					_respondeu(l, m, "nenhuma")
					nota_perdida(l, m)
		if _resolvido < m and Ritmo.t_musica() >= alvo + Ritmo.JANELA_BOM:
			_resolvido = m
			_resolver(m)
	_barra(b)
	_mostrar(b)


func toque(l: int, _j: int) -> void:
	_julgou[l] = _compasso(Ritmo.batida())   # pisou com BOM ou melhor: entra na resolução


func falha(l: int) -> void:
	if _motivo[l] == "parou":
		jogador(l).gesto("emote-no", 0.4)
	else:
		_cair(l, false)                       # o salto curto; sem momento


func _resolver(m: int) -> void:
	var por_placa := {}
	for l in presentes():
		if _julgou[l] == m and _placa[l] >= 0:
			if not por_placa.has(_placa[l]):
				por_placa[_placa[l]] = []
			por_placa[_placa[l]].append(l)
	for pl in por_placa:
		var quem: Array = por_placa[pl]
		quem.sort_custom(func(a, b):
			if absf(_desvio[a]) != absf(_desvio[b]):
				return absf(_desvio[a]) < absf(_desvio[b])
			if _vezes[a] != _vezes[b]:
				return _vezes[a] < _vezes[b]
			return a < b)
		var fica: int = quem[0]
		var vale := 2 if pl == _ouro else 1
		_em_placa[fica] = pl
		_vezes[fica] += vale
		marcar(fica, PONTOS_PLACA * vale)
		_respondeu(fica, m, "certo")
		if vale == 2:
			Forja.som_falante(fica, "coleta", 0.7)
		for i in range(1, quem.size()):
			_respondeu(quem[i], m, "errado")
			_cair(quem[i], true, fica)       # o empurrão: o grito


func vencedor() -> Array:
	var ordem := presentes()
	ordem.sort_custom(func(a, b):
		if _vezes[a] != _vezes[b]:
			return _vezes[a] > _vezes[b]
		if pontos[a] != pontos[b]:
			return pontos[a] > pontos[b]
		return a < b)
	return ordem


func _fim_b() -> int:
	return int(floor(duracao / _t_batida()))


func _t_batida() -> float:
	return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)
```

As funções que faltam, pelo que já foi dito:

- `_compasso(b)`: `floori((b - BATIDA_DA_PRIMEIRA_NOTA) / 4.0)`, ou −1 antes da primeira nota ou se `c0 + 1.5 >
  _fim_b()`.
- `_no_pico(m)`: `c0 >= PICO_DE and c0 < PICO_ATE`. `_placas_agora()`: as posições de `ANGULOS[n]` com `n =
  _n_placas` (ou `maxi(1, _n_placas - 1)` no pico), em `_no_circulo(a, RAIO_PLACA)` (raio 0 com uma placa).
- `_salta_neste(l, m)`: `b >= _volta_ate[l]` e, com `Ritmo.simples[l]`, `m % 2 == 0`.
- `_novo_compasso(m)`: `_placa`, `_em_placa` e `_desvio` zerados; `nova_nota(l, m, alvo)` para quem salta neste; na
  reta, `_ouro = rng.randi_range(0, n - 1)`; senão −1.
- `_escolher(l)`: a regra da escolha. `_mais_perto(pos, placas)`: o índice da placa mais perto.
- `_cair(l, empurrado, por := -1)`: o grito de «A diversão»; com `empurrado`, o `momento` `empurrao` com `por`.
- `_pulsar(k)`: o metrônomo de todos; para quem salta no compasso de `k`, o pulso do salto pelo `_pista` em `c0 + 1.5`
  (adiantado pelo Faro e pela Lanterna; no rádio, em `c0 + 1.0`).
- `_barra(b)`: a mágica 3 da tabela do controle. `_mostrar(b)`: as placas, o vapor e os contornos.

A dica (`dica(l)`, com a guarda `if not na_raia(l): return {}`): `{"partes": ["@stick_l", "@cross"], "pos":
CANTO[l] + Vector3(0, 0, 1.2)}` enquanto `not aprendeu(l)`. O `status(l)`: `"%d na placa" % _vezes[l]`.

`godot/scripts/traducoes.gd`: `"Passo no Fosso": "Step over the Pit"`, `"Pise no contratempo!": "Step on the
offbeat!"`, `"Pise!": "Step!"`, `"%d na placa": "%d on a plate"`.

## O que o registro mede

- `pista` `mandou` do pulso de cada salto (`o_que` `contratempo`, `canal`) e a `entrada` `resposta` (`certo` para quem
  ficou, `errado` para o empurrado, `nenhuma` para quem parou);
- o desvio de cada salto (`toque`, `desvio_ms`, do kit): o contratempo é onde o desvio de quem joga de ouvido mais
  cresce, e a noite compara com o do rádio;
- `som_controle` de todo pulso (2,5 por segundo por controle); `troca` no rádio;
- `momento` `empurrao` (com `por`) e `reta`.

## Armadilhas

- **O robô sorteia no dele** (`_robo_rng`): o ouro sai do `rng` do kit, e o robô não pode mudar o sorteio.
- **A resolução é uma só por compasso**, em `alvo + 140 ms`, depois de todos os julgamentos. Não resolva no `toque`:
  quem pisou primeiro no relógio pode ter pisado mais longe do contratempo.
- **A altura das placas é função da batida**, nunca `+= dt`. O mesmo para o voo e o empurrão.
- **150 bpm:** com o `JANELA_BOM` de 140 ms, pisar na batida (200 ms antes ou depois do contratempo) é ERRO. É a regra;
  não mude a janela.
- **Rumble e háptica nunca juntos, no rádio:** o pulso do salto sai meio tempo antes no rádio. No cabo, os dois são
  háptica e se misturam no mixer.
- **A prova roda a `duracao` inteira** pelo relógio de parede: o pico e a reta chegam.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo que cai e volta;
fecha com vencedor por `_vezes`; nunca dois cavaleiros na mesma placa depois da resolução; o pulso chega a todo
contratempo na mão de todos; a barra pulsa a 2,5 por segundo (parada sem Flashes); a mesa padrão grava pelo menos 6
`empurrao`; as raias, a distância e a meta de hoje saíram; e as provas abaixo passam com a prancha olhada.

## Provas

`_prova_passo_no_fosso()` em `godot/testes/prova_do_jogo.gd`, chamada pelo `match` de `_prova_da_ficha(slot)`:
`"S07_J33": await _prova_passo_no_fosso()`.

```gdscript
## S07_J33: o pulso do contratempo chega à placa virtual de todos, nunca há
## dois numa placa, a barra pulsa, e o empurrão se registra.
func _prova_passo_no_fosso() -> void:
	var sentiu := [false, false, false, false]
	var dois_numa := [0]
	var barra_alta := [0]
	var barra_baixa := [0]
	var olhar := func(mg: Minigame) -> void:
		var b := Ritmo.batida()
		var f := fposmod(b, 1.0)
		var vistos := {}
		for l in mg.presentes():
			var v := Forja.som_virtual(l)
			if f >= 0.5 and f < 0.6 and float(v.get("esq", 0.0)) > 0.05 and float(v.get("dir", 0.0)) > 0.05:
				sentiu[l] = true
			var pl: int = mg._em_placa[l]
			if pl >= 0:
				if vistos.has(pl):
					dois_numa[0] += 1
				vistos[pl] = true
			if not Opcoes.flashes:
				continue
			var c: Color = Forja.percepcao(l).get("luz", Color.BLACK)
			var dt := (f - 0.5) * 0.4   # segundos depois do contratempo (0,4 s por batida)
			var cheia := Forja.cor_do_lugar(l)
			var meia := cheia.darkened(0.4)
			if dt >= 0.03 and dt <= 0.05 and Vector3(c.r - cheia.r, c.g - cheia.g, c.b - cheia.b).length() < 0.1:
				barra_alta[0] += 1
			if dt >= 0.2 and dt <= 0.3 and Vector3(c.r - meia.r, c.g - meia.g, c.b - meia.b).length() < 0.1:
				barra_baixa[0] += 1
	var mg := await _joga_o_minigame("S07_J33", 130.0, olhar)
	if mg == null:
		return
	_esperar(sentiu.all(func(s): return s), "S07_J33: o pulso chegou aos dois lados da mão dos quatro %s" % [sentiu])
	_esperar(dois_numa[0] == 0, "S07_J33: nunca dois numa placa depois da resolução (%d)" % dois_numa[0])
	if Opcoes.flashes:
		_esperar(barra_alta[0] >= 10 and barra_baixa[0] >= 10,
			"S07_J33: a barra pulsou de 60 %% a 100 %% (%d alto, %d baixo)" % [barra_alta[0], barra_baixa[0]])
	_esperar(mg._vezes.max() >= 1, "S07_J33: alguém ficou numa placa (%s)" % [mg._vezes])
	_esperar(mg.colocacao().size() == mg.presentes().size(), "S07_J33: a colocação tem todos")
	_esperar(mg._vezes[mg.vencedor()[0]] == mg._vezes.max(), "S07_J33: o vencedor é quem ficou mais vezes")
```

No `_prova_do_relatorio()`, no laço da linha do tempo, do `S07_J33`: ≥ 6 `momento` `empurrao`, ≥ 3 deles com
`t_musica` entre 30 e 60; 1 `momento` `reta`; os `toque` com `julgamento != "erro"` têm `absf(desvio_ms) <= 140`; as
`pista` `mandou` têm `o_que == "contratempo"`.

Os comandos:

1. `SALA=S07_J33 bash tests/prova_do_jogo.sh`
2. `bash tests/prova_visual.sh`, e olhar a prancha nas partidas com quatro (`bom` e `ruim`), com dois, com um e com o
   cabo que cai. O que se olha: os quatro cantos e as placas no quadro inteiro, o plasma petróleo (nunca ciano), um
   cavaleiro no plasma em 1 quadro de cada 3 do pico, o vapor no pico, o ouro na reta, e as peças do cavaleiro com as
   tintas da montagem em todo quadro.
3. Na máquina do André: `./run-local.sh -- --sala=S07_J33`. O pulso no contratempo tem de puxar o salto sem pensar; no
   vapor, jogar só pela mão tem de dar. No rádio, o pulso pelo rumble a 150 bpm não pode virar um zumbido contínuo; se
   virar, anote aqui.

## Ao terminar

- No [quadro](README.md), a linha O3: **feito**, com o commit.
- Commit sugerido: `feat(fosso): Passo no Fosso vira a dança das placas, menos placas que cavaleiros`
