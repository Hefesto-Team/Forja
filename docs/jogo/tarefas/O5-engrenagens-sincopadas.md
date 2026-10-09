# O5 — Engrenagens Sincopadas

**Sprint:** O · **Slot:** S07_J35 · **Tamanho:** M · **Depende de:** H04, H07, H08, F09, G03, G05, G10, G13, G14, G15, O1

## Por quê

A dupla da seção. Duas torres de engrenagens, e cada dupla sobe alternando saltos na síncope. Os dentes passam sob a
mão em três cliques, e o salto é no vão que vem depois: no «e» do 2 para um, no «e» do 4 para o outro. A dupla divide
o acorde (fundamental e quinta) e sobe a cada encaixe. A diversão dá nota 3: a dupla é bonita, mas duas torres que
sobem têm pouco para ver. O que muda: o verbo, a **engrenagem-mestra** gigante no pico (vale 3 engrenagens e fica
girando na cor de quem a ganhou), a reta que vale 2, e o Aprendiz que deixa de usar um corpo de jogador.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A diversão da seção O](../diversao/O-os-caminhos.md)

Tudo o mais está copiado aqui: o `_pista` e o `_respondeu` (os da O1), a regra das equipes d'A Prova (o kit monta,
H08), os ids de som, os números de luz e câmera.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s07/engrenagens_sincopadas.gd` e o `.uid` | novo | não |
| `godot/scripts/minigames/catalogo.gd` | `"S07_J35"` em `MINIGAMES` e na seção `S07`, depois do `S07_J34` | **sim** |
| `godot/scripts/traducoes.gd` | as frases novas | **sim** |
| `godot/testes/prova_do_jogo.gd` | a `_prova_engrenagens()` no `match` de `_prova_da_ficha` | **sim** |
| `godot/assets/kenney/factory-kit/` | `python3 scripts/importar_kenney.py factory-kit` (G10; já está em `APROVADOS`), se a O4 ainda não importou | **sim** (a O4 usa) |

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J35",
	"titulo": "Engrenagens Sincopadas",
	"verbo": "Salte no vão!",
	"genero": "2v2",
	"icone": "haptica",
	"entradas": [Forja.CRUZ],
	"camera": "grupo",
	"faixa": "MUS_S07_J35",
	"duracao": 90.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "toque"],
	"material": "metal",
	"microjogo": {"verbo": "Salte!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "jump",
}
```

O verbo é o da [diversão](../diversao/O-os-caminhos.md#o5--engrenagens-sincopadas): «Salte no vão!».

## Como se joga

A faixa é `MUS_S07_J35`, 130 bpm (uma batida = 0,4615 s). `BATIDA_DA_PRIMEIRA_NOTA` = 4 (do kit).
`_fim_b := floor(duracao / _t_batida())` = 195.

- **As equipes** (o kit, H08, a regra d'A Prova): `presentes()` na ordem; os dois primeiros são a **Brasa**
  (`BRASA`), os dois seguintes a **Maré** (`MARE`). O kit preenche `equipe[l]` e `aprendizes[e]` (quantos Aprendizes a
  equipe tem). Em cada equipe, o primeiro presente é **A** (`_papel[l] = 0`), o segundo é **B** (`1`). O Aprendiz faz
  o papel que falta (ver «Com menos de quatro»).
- **Um compasso** (4 batidas, a partir de `c0 = BATIDA_DA_PRIMEIRA_NOTA + 4 * m`):

  | batida | A | B |
  | --- | --- | --- |
  | `c0`, `c0 + 0.5`, `c0 + 1.0` | três cliques dos dentes na mão | — |
  | `c0 + 1.5` | **o salto** (a nota) | — |
  | `c0 + 2`, `c0 + 2.5`, `c0 + 3.0` | — | três cliques na mão |
  | `c0 + 3.5` | — | **o salto** (a nota) |

  `SINCOPE := [1.5, 3.5]`. Os cliques ficam em `c0 + SINCOPE[papel] - 1.5`, `- 1.0` e `- 0.5`, adiantados pelo Faro e
  pela Lanterna. O primeiro vai pelo `_pista` (`o_que` = `"encaixe"`, ganho 1,0); os outros dois, por
  `Forja.som_haptica(l, "material:metal", "material:metal", 0.8)` direto. A mão conta «um, e, dois» e salta no «e».
- **As duas equipes jogam ao mesmo tempo**, cada uma na sua torre: os A das duas saltam juntos no «e» do 2, os B no «e»
  do 4. A nota de cada lugar soa na TV (o kit): A e B de uma dupla fazem fundamental e quinta.
- **A entrada:** ✕. A nota abre com `nova_nota` no primeiro clique e é julgada com `julgar_toque(l,
  Ritmo.t_da_batida(c0 + SINCOPE[papel]), n, true)` (a engrenagem é perigo físico). Sem ✕ até a nota passar
  (`FOLGA_PERDIDA`, do kit) → `_respondeu(l, n, "nenhuma")`, `nota_perdida(l, n)`.
- **A subida:** cada salto julgado sobe a **equipe** 1 engrenagem (`_subir(e, 1)`) e marca `marcar_equipe(e,
  PONTOS[j])`, `PONTOS := [0, 50, 75, 100]` (os pontos vão para os dois da dupla: o kit).
- **A meta:** `META := 68` engrenagens. O número vem da conta da partida (400 sementes; salto certo +1, erro −1, a
  mestra +3, a reta +2): a equipe perfeita chega na batida 120 (55,4 s), depois da mestra; com os quatro `bom`, na
  mediana na 132 (60,9 s), e a mestra decide em todas; na mesa padrão, a Brasa chega em 77 % das sementes, na mediana
  na batida 184 (84,9 s), e a reta é anotada em 82 %. Com 16, a equipe perfeita chegava na batida 36 (16,6 s), a
  partida acabava antes do pico e a prova `_mestra_decidiu >= 0` falhava.
- **A partitura simples** (`Ritmo.simples[l]`): o lugar salta só nos compassos pares; nos ímpares, nem clique nem nota
  para ele. No pico, salta nos quatro.
- **O pico, a engrenagem-mestra:** os `PICO_COMPASSOS := 4` compassos a partir de `_pico_m := floor((_fim_b -
  BATIDA_DA_PRIMEIRA_NOTA) / 4 / 2)` = 23 (c0 de 96 a 108, 44,3 s a 51,7 s). Neles, A e B saltam **juntos** nas duas
  síncopes, cada um com os seus cliques e a sua nota (duas notas por compasso: a segunda abre quando a primeira fecha,
  pela fila `_fila[l]`). Cada salto certo sobe 1, como sempre, e conta em `_acertos_pico[e]` (o Aprendiz também conta).
  Sai o +1 extra do duplo acerto de hoje.
- **A mestra decide** na batida `c0` do compasso 27 (batida 112, 51,7 s): a equipe com mais `_acertos_pico` sobe **3**
  (`_subir(e, 3)`). No empate, a equipe **mais baixa**; com a mesma altura, a de mais pontos (`equipe_vencedora()`, a
  Brasa no empate). A outra é derrubada pelo dente: os dois fazem `fall` (0,8 s) e **não** perdem altura.
- **A reta:** nas batidas `b >= _fim_b - 16` (179, 82,6 s em diante), cada salto certo sobe 2.
- **Ensina sem falar:** nos compassos 0 e 1, no terceiro clique de cada um, a engrenagem acima do cavaleiro acende o
  contorno do dono por 0,5 batida: é ali que ele vai pisar. A torre do outro sobe na contagem e a sala vê o salto.

## A cena

**A câmera:** `camera_modo` `"grupo"` (G05, pela `camera` da FICHA), com `camera_distancia = Vector2(12.0, 28.0)` e a
direção da pose `camera_pos = Vector3(0, 5.5, 13.0)`, `camera_olhar = Vector3(0, 3.0, -1.0)` (plongée de 7°), no começo
do `montar()`. `alvos_da_camera()` devolve os quatro bonecos da torre (jogadores e Aprendizes) e, enquanto a mestra está
de pé, o centro dela. A G05 amortece (`k = dt * 4.0`): nunca salta. Lente de 35 mm por sala quando o kit tiver; até lá,
o campo de 40° de hoje. Roll zero.

**A luz** (S7, tinta petróleo `Tema.SECAO[2]` = `#1f8a7e`): a ficha não chama `Tema.luz_da_secao`. A entrada da sala
chama `acender(7, partida.lado() == "B")` (G15 e G16), e o lado não é fixo: a S7 pode cair no lado A (antes do
intervalo) ou no B (depois). A G15 tira de `Tema.luz_da_secao(7, lado_b)` a névoa `#011311`, o preenchimento `#11413b` e a chave
`#e5d7ad`, com densidade 0,012 e energia da chave 1,8; no lado B, densidade ×1,3 (0,0156) e chave ×0,85 (1,53). A
chave são as tochas de `luzes()`: a ficha as monta com `luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0,
3.0, 4)])`, e o `Sala.acender(luz)` as pinta. Quando a ficha mexe na chave, multiplica a `light_energy` dessas tochas
sobre a `energia_chave` que a G15 pôs. O preenchimento é `environment.ambient_light_energy` (0,42 pela G15) e a névoa é
`environment.fog_density` (sobre a `densidade`), com `var environment := get_viewport().find_world_3d().environment`.
A ficha não escreve cor de luz em hex: saem o `atmosfera(Color("#ffb070"), ...)` e o ferro
`#3b3f4c` / `#5b6275` de hoje, e as tochas do `luzes(...)` de hoje dão lugar às três de cima.

- **O pico:** quando a mestra entra (batida 92), a chave sobe 20 % em 1 batida e fica até ela decidir.
- **A decisão:** a chave sobe mais 40 % por 1 batida e volta à luz da seção em 2 batidas. Com `Opcoes.flashes`
  desligado, sobe 20 % em 2 batidas.

**As peças** (G10, `Kit.peca(pai, "<pacote>/<peça>", pos, rot_y, escala)`; o `factory-kit` entra a 0,5× pelo
`ESCALA_DO_PACOTE`, então a escala pedida é o dobro do tamanho final):

| papel | peça | escala pedida | tamanho final | onde |
| --- | --- | --- | --- | --- |
| o chão | `Kit.arena(self, 5, 3)` (do kit) | — | — | — |
| as torres | um `Node3D` por equipe | — | — | `(X_TORRE[e], 0, -1.0)`, `X_TORRE := [-3.6, 3.6]` |
| o eixo | `Kit.cilindro(torre, 0.2, ALTURA_ENG * (META + 2), Vector3(0, ALTURA_ENG * (META + 2) / 2.0, 0), Kit.material(Tema.OXIDO_BRILHO, 0.2, 0.7))` | — | 17,5 m | no centro da torre |
| as engrenagens | `factory-kit/cog-a`, `META + 1` por torre | 4,4, e depois `scale.y *= 0.5` (achatada) | 2,2 m de diâmetro, 0,25 m de espessura | `(0, ALTURA_ENG * nivel, 0)`, `ALTURA_ENG := 0.25`: as engrenagens empilham encostadas; o topo de cada uma fica a `+0.08` (a peça vai de −0,15 a +0,075 m na escala 1) |
| a mestra | `factory-kit/cog-e`, uma | 14,4 | 7,2 m de diâmetro, 1,58 m (4 vezes o cavaleiro) | num `Node3D` `_mestra` em `(0, y_m, -4.5)`, de pé (`rotation.x = PI / 2`) |
| o Aprendiz | `load(Kit.caminho("mini-dungeon-personagens/character-human")).instantiate()` (G10) | `ForjaPlayer.ESCALA` | 1,8 m | no lugar do membro que falta |

- **As engrenagens giram** pela batida: `rotation.y = (1 if nivel % 2 == 0 else -1) * Ritmo.batida() * PI / 4`. A
  torre que ganhou a mestra gira ×4 por 2 batidas.
- **A torre cabe na câmera:** 69 engrenagens de 0,25 m dão 17,25 m; a maior distância de altura entre as duplas é
  `META * ALTURA_ENG` = 17 m, e a câmera `"grupo"` no teto de `camera_distancia` (28 m) vê 20,4 m na vertical com o
  campo de 40°. As duas duplas cabem sempre no quadro.
- **A mestra:** escondida (`visible = false`) até a batida 92; aí sobe de `y = -3.6` a `y_m` em 2 batidas, com
  `y_m = maxf(3.8, ALTURA_ENG * (_altura[0] + _altura[1]) / 2.0 + 1.0)`, medido na entrada. Gira no próprio eixo
  `PI / 8` por batida. Depois da decisão, fica de pé e girando até o fim, pintada da equipe que a ganhou.
- **A cor da equipe, no mundo:** `CORES_DAS_EQUIPES[e]` (o kit, H08), em `Kit.material(cor, 0.0, 0.9)`, sem emissivo,
  em três lugares só: a laje `Kit.caixa(self, Vector3(3.0, 0.03, 3.0), Vector3(X_TORRE[e], 0.02, -1.0), ...)` na base
  da torre; o disco `Kit.cilindro(boneco, 0.55, 0.03, Vector3.ZERO, ...)` sob os pés de cada boneco; e as engrenagens
  já subidas (`material_override` em cada `MeshInstance3D` de `cog-a`, de `nivel < _altura[e]`). A mestra ganha o mesmo
  na decisão. **Nunca** na barra de luz nem no cavaleiro.
- `metallic` no máximo 0,2 em tudo. Partículas vivas no máximo 300.

**O que brilha e de quem é:**

| o quê | energia | dono |
| --- | --- | --- |
| a borda do disco de `l`, `Tema.contorno(Tema.JOGADOR[l], 0.03, 2.0, l)` | 2,0; 2,6 por 4 quadros no encaixe | `l` |
| a engrenagem do ensino (compassos 0 e 1), o mesmo contorno | 2,0 por 0,5 batida | `l` |
| as faíscas do escorregão, `Efeitos.faiscas(self, pos_do_dente, CORES_DAS_EQUIPES[e], 24, 0.8)` | 2,4 por 12 quadros | `"mundo"` |
| qualquer outra coisa | no máximo 1,0 | `"mundo"` |

Sem luz de dono: o dono se lê pela borda do disco e pelos acentos do cavaleiro. O Aprendiz não tem borda.

**Os cavaleiros na cena:** o minigame **não** chama `raia(l)` nem `posicionar(l)` (a dupla está na torre). A em
`X_TORRE[e] - 0.9`, B em `X_TORRE[e] + 0.9`, `z = -1.0`, na altura `ALTURA_ENG * _altura[e] + 0.08`, de frente para a
câmera (`rotation.y = 0`), `p.preso = true`. O salto: `p.gesto("jump", 0.35)`, e a altura anda por `lerpf` na meia
batida depois do salto (pela batida, dividida pelo `velocidade`).

## O som

Só ids do mapa (`docs/jogo/audio/mapa.csv`):

| evento | id | onde toca | chamada |
| --- | --- | --- | --- |
| a faixa | `mus_s07_j35` (130 bpm) | TV | a `faixa` da FICHA |
| os cliques dos dentes | `mod_material_metal` | atuadores do dono, os dois | o `_pista` e `Forja.som_haptica(l, "material:metal", "material:metal", 0.8)` |
| o encaixe (o kit) | `mod_material_metal` | atuadores do dono | o `material` da FICHA, pelo kit |
| a coleta, a cada 4 engrenagens da equipe | `mod_coleta` | alto-falante dos dois | `Forja.som_falante(l, "coleta", 0.7)` |
| a mestra entra | `sobe_0` | TV | `Som.tocar("sobe")` na batida 92 |
| a mestra decide, a torre gira | `martelo_*` | TV | `Som.tocar("martelo", torre.global_position, 0.0)` |
| o escorregão | `martelo_*` | TV | `Som.tocar("martelo", pos_do_dente, -6.0)` |
| o topo | `portao_0` | TV | `Som.tocar("portao")` |

## O controle

| evento | para quem | háptica (cabo) | rumble (rádio) | prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| os cliques | só o dono | `material:metal` nos dois atuadores, 1,0 no 1º, 0,8 nos outros | `Forja.sentir(l, "toque")` em cada um | `Forja.som_virtual(l).esq > 0,05` até 0,3 batida depois de cada clique |
| o encaixe | o dono | `material:metal` (o kit) | `acerto` (o kit) | a linha `toque` |
| o escorregão | os dois da equipe | — | `Forja.sentir(o, "golpe")` nos dois modos | `Forja.percepcao(o).forte > 0` no quadro da falha |
| a mestra perdida | os dois da equipe | — | `Forja.sentir(o, "golpe")` | o mesmo, no quadro da decisão |
| o gatilho R2 | cada um, o jogo inteiro | `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 3)` | o mesmo | `percepcao(l).gatilho_dir`: o primeiro byte é `0x21` |
| a barra | o dono | a cor do lugar (o kit); o minigame não chama `Forja.luz` | a mesma | `percepcao(l).luz` igual a `cor_do_lugar(l)` fora do piscar |

- **O rádio:** `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)` no `iniciar_jogo()`, e a linha `troca` (`de`
  `haptica`, `para` `rumble`, `motivo` `sem_placa`) uma vez. Os cliques nunca vão pelos dois canais.
- **O gatilho:** `usa_gatilho = true` no `montar()`, antes de o kit começar: o L2 fica com o item (G03). A catraca de
  dentes no R2 (zonas 3, 5 e 7, força 6) é um quinto modo de gatilho e **não** entra: `forja.gd` só tem os quatro
  oficiais. Ela espera a emenda da Vitória; até lá, a resistência contínua.
- **O alto-falante:** a nota do dono no PERFEITO (o kit) e a coleta.
- **O microfone:** não se usa.
- **O baque do parceiro** (90 Hz no lado dele, a mágica 1 da pesquisa) não entra: o som não existe no `sons_salas.c`.

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

O primeiro clique: `_pista(l, "material:metal", "material:metal", "toque", n, "encaixe")`.

## O cavaleiro

Chega pronto da G13 (`jogador(l)`), de qualquer raça (humana, orc, autômato, golem, raposa), com a cabeça, o superior,
o inferior e o item. A ficha **nunca recolore** nem muda a energia de uma peça: o superior fica na faixa do tecido (L
0,46 a 0,58), o inferior na do couro (0,22 a 0,36), o néon do dono só nos acentos, a 1,6. A cor da equipe vai no chão,
no disco e nos dentes, nunca na roupa.

**O Aprendiz não é jogador:** é o `character-human` do pacote, tingido inteiro de `Tema.ETIQUETA_SOMBRA` (`#cfc2a0`)
pelo `_tingir` abaixo, sem cabeça, roupa nem item da G13, sem contorno, sem borda no disco. A cor de areia sem acento é o que o separa dos cavaleiros. **Não** use o `character-orc`: o orc agora é uma raça
de jogador. Ele anima pelo `AnimationPlayer` dele (`jump`, `idle`, `fall`). O `_tingir`, copiado de
`godot/scripts/salas/prova.gd` (linhas 200 a 210), com a cor `Tema.ETIQUETA_SOMBRA`:

```gdscript
static func _tingir(n: Node, cor: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var mat := StandardMaterial3D.new()
				mat.albedo_color = cor
				mat.roughness = 0.9
				mi.set_surface_override_material(s, mat)
	for filho in n.get_children():
		_tingir(filho, cor)
```

Os ganchos (`Cavaleiro.gancho(l, "<gancho>")`, H04; a O5 no `minigames.csv`):

| stat | gancho | o que muda aqui | 1 | 3 | 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | o escorregão: `_resto[e] += gancho × (1 - Kit.resiste_a_empurrao(l))`; a equipe desce `floor(_resto[e])` e guarda o resto | ×1,16 | ×1 | ×0,84 |
| Passo | `velocidade` | o voo do salto até a engrenagem: 0,5 batida / gancho (só a animação) | ×0,94 | ×1 | ×1,06 |
| Fôlego | `levantar` | quem escorregou fica deitado 2 tempos × gancho (só a animação; a próxima nota dele vem 4 batidas depois) | ×1,25 | ×1 | ×0,75 |
| Faro | `pista` | os cliques chegam antes: `- pista / 1000 / 0.4615` batida (a nota não muda) | −40 ms | 0 | +40 ms |

**Os itens:** o Martelo nunca dobra aqui (o salto cai no «e», nunca no tempo 1); a Âncora segura o escorregão (o
`resiste_a_empurrao` acima); o Escudo absorve o primeiro erro (o kit); o Fole é do combo (o kit); a Lanterna adianta os
cliques meio tempo (0,23 s), somada ao Faro; o Diapasão puxa o combo da dupla (o kit, `puxa_o_combo_da_equipe`). A
cadeira de rodas salta na velocidade do Passo. Nenhum stat nem item muda a janela (140 ms) nem os pontos.

## As reações

Os carimbos vêm do kit; a ficha não chama nada:

- `car_em_chamas`: 5 «Ressonância!» seguidas do mesmo jogador.
- `car_por_um_fio`: a equipe vencedora com 2 % dos pontos ou menos de vantagem.
- `car_virada`: quem passa a ser o primeiro.
- `car_emburrado`: o último, no inserto do resultado.
- `car_acorde`: **não sai** aqui: os saltos caem no «e», nunca no tempo 1.

No máximo 1 carimbo vivo por jogador e 2 na tela. Adesivos `rea_*`: ninguém sai da rodada, então só depois do topo.

## A diversão

**O grito: a engrenagem-mestra** (`mestra`), degrau «catástrofe». No pico, uma engrenagem de 7,2 m sobe do chão entre
as duas torres. Depois de 4 compassos de saltos em dupla, ela decide: a torre de quem encaixou mais gira com estrondo e
a dupla sobe 3 de uma vez; a outra é derrubada pelo dente.

- **O exagero:** a mestra é 4 vezes o cavaleiro; a chave +40 % por 1 batida; `tremer(Sala.TREMOR_EXPLOSAO)` (G05);
  **sem** hit-stop; a torre gira ×4 por 2 batidas; o `martelo` a 0 dB; o golpe na mão dos que perderam e a coleta a 0,9
  no alto-falante dos que ganharam, no mesmo quadro.
- **O rastro:** a mestra fica de pé, girando na cor da equipe que a ganhou, até o fim.
- **A linha:** na decisão, `anotar("momento", -1, {"nome": "mestra", "t_musica": Ritmo.t_musica(), "equipe": e,
  "acertos": _acertos_pico.duplicate()})`. Na batida `_fim_b - 16`, `anotar("momento", -1, {"nome": "reta",
  "t_musica": Ritmo.t_musica(), "ordem": vencedor()})`.
- **A curva:** 0 a 42,5 s, a síncope, um salto por compasso para cada um; 42,5 s a 51,7 s, a mestra; 51,7 s a 82,6 s,
  a síncope; 82,6 s ao fim, a reta (cada encaixe sobe 2).
- **Quem está perdendo:** a dupla escorrega no máximo uma engrenagem por erro. A mestra vale 3: uma dupla 3 atrás vira
  no pico.

**Como o jogador do time confere** (mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7; a Brasa é
P1 e P2, a Maré é P3 e P4):

1. Robô: 1 linha `momento` `mestra` entre 40 e 55 s (a decisão cai em 51,7 s), da equipe com mais `acertos` (na mesa
   padrão, espera-se a Brasa), e 1 `momento` `reta` se a partida chegou à batida 179.
2. Prancha: no quadro de 60 s, a mestra de pé na cor de uma equipe.
3. Enquanto o robô por lugar não existe, a mesa padrão se confere só pela prancha, com o temperamento único.

**O que se corta:** nada.

## A falha

**Salta fora do encaixe** (erro ou nota perdida, depois do Escudo): o cavaleiro bate no dente, `p.gesto("fall",
0.5)`, e a equipe escorrega (o `empurrao` acima: em regra 1 engrenagem, nunca abaixo de 0). Os dois sentem o golpe; 24
faíscas na cor da equipe no dente. **A recuperação:** o próximo salto já sobe. O Aprendiz que erra faz o mesmo, com
gancho 1.

## O fim e o vencedor

A primeira equipe com `_altura[e] >= META` chega ao topo: `Som.tocar("portao")`, os dois fazem `emote-yes`, e todos
acabam no fim daquele compasso (`_fim_batida = BATIDA_DA_PRIMEIRA_NOTA + 4 * (_m_feito + 1)`). Sem chegada, o kit fecha
na `duracao`. **O vencedor:** a equipe mais alta (no empate, `equipe_vencedora()`, a de mais pontos, a Brasa no
empate); `vencedor()` devolve os lugares da equipe vencedora (pelos pontos) e depois os da outra.

## Com menos de quatro

- **Três:** Brasa = os dois primeiros; Maré = o terceiro (A) + o Aprendiz (B).
- **Dois:** Brasa = o primeiro + o Aprendiz; Maré = o segundo + o Aprendiz.
- **Um:** Brasa = ele + o Aprendiz; Maré = dois Aprendizes.
- **O Aprendiz** salta na síncope do papel dele e acerta com `ACERTO_APRENDIZ := 0.8` (sorteado com o `rng` do kit):
  acerto sobe a equipe 1 (2 na reta) e conta no pico; erro desce 1. Não é lugar, não marca pontos, não entra na
  colocação nem no registro de notas.
- **O controle que cai:** as notas dele não abrem (nem cliques); a equipe segue com o outro; ninguém o substitui.
  Quando volta, entra no próximo compasso.
- `com_poucos()`: `"Com o Aprendiz"` quando há Aprendiz.

## O robô

Pelo relógio da música: o salto é na síncope, sempre no mesmo lugar do compasso.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var n: int = _nota[l]
	if n < 0 or _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		# quando não acerta, salta no tempo (sem a síncope) ou atrasado
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (-0.23 if _robo_rng.randf() < 0.5 else 0.25)
	if Ritmo.t_musica() >= float(_alvo[l]) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n
```

## Os ganchos

`godot/scripts/minigames/s07/engrenagens_sincopadas.gd`, `extends Minigame`, sem `class_name`.

```gdscript
extends Minigame
## Engrenagens Sincopadas (S07_J35). Duas duplas escalam duas torres de
## engrenagens. Três cliques dos dentes na mão, e ✕ no vão que vem depois: o
## «e» do 2 para um, o «e» do 4 para o outro. No pico, a engrenagem-mestra.

const FICHA := { ... }   # a de cima

const META := 68
const ALTURA_ENG := 0.25
const PONTOS := [0, 50, 75, 100]
const ACERTO_APRENDIZ := 0.8
const X_TORRE := [-3.6, 3.6]
const SINCOPE := [1.5, 3.5]   ## o salto de A e de B no compasso
const PICO_COMPASSOS := 4
const MESTRA_SOBE := 3

var _papel := {}              ## lugar -> 0 (A) ou 1 (B)
var _bonecos_aprendiz := [[], []]   ## equipe -> [{"papel", "no", "anim"}]
var _altura := [0, 0]
var _resto := [0.0, 0.0]      ## o escorregão que sobrou (o empurrao)
var _m_feito := -1
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _n := [0, 0, 0, 0]
var _fila := [[], [], [], []] ## as notas do compasso que esperam abrir: [{"alvo_b", "cliques"}]
var _cliques := [[], [], [], []]
var _acertos_pico := [0, 0]
var _mestra_decidiu := -1     ## a equipe que ganhou a mestra
var _chegou := -1
var _fim_batida := -1.0
var _pico_m := 999
var _fim_b := 195
var _reta_anotada := false
var _rumble := [false, false, false, false]
var _fora := [false, false, false, false]
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 5.5, 13.0)
	camera_olhar = Vector3(0, 3.0, -1.0)
	camera_distancia = Vector2(12.0, 28.0)
	Kit.arena(self, 5, 3)
	_formar_papeis()            # _papel e os Aprendizes que faltam, por equipe[l] e aprendizes[e] do kit
	# as torres, as lajes, os discos, a mestra escondida, os Aprendizes: «A cena»


func iniciar_jogo() -> void:
	_robo_rng.seed = rng.seed + 99
	_fim_b = int(floor(duracao / _t_batida()))
	_pico_m = int(floor(float(_fim_b - BATIDA_DA_PRIMEIRA_NOTA) / 4.0 / 2.0))
	for l in presentes():
		Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 3)
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)
		if _rumble[l]:
			anotar("troca", l, {"de": "haptica", "para": "rumble", "motivo": "sem_placa"})


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	if b >= _fim_b - 16 and not _reta_anotada:
		_reta_anotada = true
		anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": vencedor()})
	var m := int(floor((b - BATIDA_DA_PRIMEIRA_NOTA) / 4.0))
	if b >= BATIDA_DA_PRIMEIRA_NOTA and m > _m_feito:
		_m_feito = m
		if m == _pico_m + PICO_COMPASSOS and _mestra_decidiu < 0:
			_decidir_a_mestra()
		_abrir_compasso(m)
	for l in presentes():
		if not conectado(l):
			_fora[l] = true
			_nota[l] = -1
			_fila[l].clear()
			_cliques[l].clear()
			continue
		_fora[l] = false
		_mandar_cliques(l, b)
		if _nota[l] >= 0:
			if Forja.apertou(l, Forja.CRUZ):
				var n: int = _nota[l]
				_nota[l] = -1
				julgar_toque(l, float(_alvo[l]), n, true)
				_abrir_da_fila(l)
			elif Ritmo.t_musica() > float(_alvo[l]) + FOLGA_PERDIDA:
				var n2: int = _nota[l]
				_nota[l] = -1
				_respondeu(l, n2, "nenhuma")
				nota_perdida(l, n2)
				_abrir_da_fila(l)
	_aprendizes(b)
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	var e: int = equipe[l]
	marcar_equipe(e, PONTOS[j])
	_respondeu(l, _n[l] - 1, "certo")
	_subir(e, 2 if Ritmo.batida() >= _fim_b - 16 else 1)
	if _no_pico():
		_acertos_pico[e] += 1


func falha(l: int) -> void:
	var e: int = equipe[l]
	jogador(l).gesto("fall", 0.5)
	_resto[e] += Cavaleiro.gancho(l, "empurrao") * (1.0 - Kit.resiste_a_empurrao(l))
	var desce := int(floor(_resto[e]))
	_resto[e] -= desce
	_subir(e, -desce)
	for o in presentes():
		if equipe[o] == e and conectado(o):
			Forja.sentir(o, "golpe")


func vencedor() -> Array:
	var e := _chegou
	if e < 0:
		e = 0 if _altura[0] > _altura[1] else (1 if _altura[1] > _altura[0] else equipe_vencedora())
	var primeiro := presentes().filter(func(l): return equipe[l] == e)
	var outro := presentes().filter(func(l): return equipe[l] != e)
	primeiro.sort_custom(func(a, b): return pontos[a] > pontos[b])
	outro.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return primeiro + outro


func _t_batida() -> float:
	return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)
```

As funções que faltam, pelo que já foi dito:

- `_subir(e, d)`: `_altura[e] = clampi(_altura[e] + d, 0, META)`; pinta as engrenagens abaixo da altura; a coleta nos
  dois a cada múltiplo de 4 cruzado para cima; se chegou a `META` e `_chegou < 0`: `_chegou = e`, `_fim_batida =
  BATIDA_DA_PRIMEIRA_NOTA + 4 * (_m_feito + 1)`.
- `_abrir_compasso(m)`: para cada lugar conectado cujo papel salta neste compasso (os dois papéis no pico; só os pares
  com `Ritmo.simples[l]`): agenda os três cliques e abre a nota (`nova_nota(l, _n[l], alvo)`, `_nota[l] = _n[l]`,
  `_alvo[l] = alvo`, `_n[l] += 1`); no pico, a segunda síncope vai para `_fila[l]`. No começo do compasso
  `_pico_m - 1` (batida 92, 42,5 s), a mestra entra.
- `_abrir_da_fila(l)`: abre a próxima nota da fila, se houver.
- `_mandar_cliques(l, b)`: o primeiro pelo `_pista`, os outros direto, uma vez cada.
- `_decidir_a_mestra()`: a regra de «Como se joga»; o momento `mestra`; o exagero e o rastro de «A diversão».
- `_aprendizes(b)`: para cada Aprendiz, na batida da síncope dele (e nas duas, no pico), sorteia com `rng`, sobe ou
  desce a equipe (sem nota, sem registro de toque) e anima o boneco.
- `_no_pico()`: `_m_feito >= _pico_m and _m_feito < _pico_m + PICO_COMPASSOS`.
- `alvos_da_camera()`: os bonecos e, com a mestra de pé, `_mestra.global_position`.
- `_mostrar(b)`: as alturas por `lerpf`, o giro das engrenagens, a mestra.

A dica (com a guarda `if not na_raia(l): return {}`): `["@cross"]` sob o cavaleiro enquanto `not aprendeu(l)` (a `pos`
é o pé do boneco, `jogador(l).global_position`). `status(l)`: `"Brasa %d" % _altura[0]` ou `"Maré %d" % _altura[1]`.

`godot/scripts/traducoes.gd`: `"Engrenagens Sincopadas": "Syncopated Gears"`, `"Salte no vão!": "Jump in the gap!"`,
`"Salte!": "Jump!"`, `"Brasa %d": "Ember %d"`, `"Maré %d": "Tide %d"`, `"Com o Aprendiz": "With the Apprentice"`.

## O que o registro mede

- `pista` `mandou` do primeiro clique de cada salto (`canal`) e a `entrada` `resposta` (`certo`, `nenhuma`); o `toque`
  com o desvio de cada salto na síncope: a noite compara o desvio na síncope entre cabo e rádio;
- o retorno do `Forja.gatilho` do R2 de cada um, uma vez;
- `troca` no rádio;
- `momento` `mestra` e `reta`.

## Armadilhas

- **O robô sorteia no dele.** `_robo_rng.seed = rng.seed + 99`: o `rng` do kit é do jogo (o Aprendiz), e o robô não
  pode mudar o que o jogo sorteia.
- **O Aprendiz não é robô.** É regra do jogo: nada de `Forja.robo` nele, nada de controle simulado.
- **Não chame `raia(l)`/`posicionar(l)`:** os cavaleiros estão nas torres.
- **O gatilho no R2 só:** o L2 é do item (G03).
- **A cor da equipe** nunca vai em `Forja.luz` nem numa peça do cavaleiro.
- **Na prova o pico chega:** o fim conta em tempo de música (H08), e a `duracao` inteira roda pelo relógio de parede.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com o Aprendiz) e com o robô nos três temperamentos; aguenta o cabo
que cai e volta; fecha com vencedor (uma equipe); o R2 fica em resistência e o L2 com o item; a mestra entra, decide e
fica girando na cor de quem ganhou; a mesa padrão grava 1 `mestra` entre 40 e 55 s; e as provas abaixo passam com a
prancha olhada.

## Provas

`_prova_engrenagens()` em `godot/testes/prova_do_jogo.gd`, chamada pelo `match` de `_prova_da_ficha(slot)`:
`"S07_J35": await _prova_engrenagens()`.

```gdscript
## S07_J35: os cliques chegam à mão dos quatro, o R2 fica em resistência, a
## mestra decide uma vez entre 40 e 55 s, e fecha com vencedor de uma equipe.
func _prova_engrenagens() -> void:
	var r2 := [false, false, false, false]
	var sentiu := [false, false, false, false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var g = Forja.percepcao(l).get("gatilho_dir", 0)
			var modo := int(g[0]) if (g is PackedByteArray or g is Array) and g.size() > 0 else int(g)
			if modo == 0x21:
				r2[l] = true
			if float(Forja.som_virtual(l).get("esq", 0.0)) > 0.05:
				sentiu[l] = true
	var mg := await _joga_o_minigame("S07_J35", 130.0, olhar)
	if mg == null:
		return
	for l in mg.presentes():
		_esperar(r2[l], "S07_J35 P%d: o R2 em resistência" % (l + 1))
		_esperar(sentiu[l], "S07_J35 P%d: os cliques chegaram à mão" % (l + 1))
	_esperar(mg._mestra_decidiu >= 0, "S07_J35: a mestra decidiu")
	_esperar(mg._altura[0] + mg._altura[1] >= 1, "S07_J35: alguém subiu (%s)" % [mg._altura])
	var c: Array = mg.colocacao()
	_esperar(c.size() == mg.presentes().size(), "S07_J35: a colocação tem todos")
	if c.size() == 4:
		_esperar(mg.equipe[c[0]] == mg.equipe[c[1]], "S07_J35: os dois primeiros são da mesma equipe (%s)" % [c])
```

No `_prova_do_relatorio()`, no laço da linha do tempo, do `S07_J35`: exatamente 1 `momento` `mestra`, com `t_musica`
entre 40 e 55; ≥ 8 `entrada` `resposta`.

Os comandos:

1. `SALA=S07_J35 bash tests/prova_do_jogo.sh`
2. `bash tests/prova_visual.sh`, e olhar a prancha com quatro, com três (o Aprendiz de areia, sem borda), com um e com
   o cabo que cai. O que se olha: as duas torres e os quatro bonecos no quadro, a câmera subindo com eles, a mestra
   inteira quando entra, a mestra na cor de uma equipe no quadro de 60 s, as engrenagens subidas na cor da equipe.
3. Na máquina do André: `./run-local.sh -- --sala=S07_J35`, com duas duplas. Os três cliques têm de ensinar a
   síncope sem explicação; a decisão da mestra tem de dar vontade de gritar; com três jogadores, o Aprendiz não pode
   ser nem inútil nem imbatível.

## Ao terminar

- No [quadro](README.md), a linha O5: **feito**, com o commit.
- Commit sugerido: `feat(engrenagens): Engrenagens Sincopadas no kit, a dupla salta no vão e a mestra decide o pico`
