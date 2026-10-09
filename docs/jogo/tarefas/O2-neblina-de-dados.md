# O2 — Neblina de Dados

**Sprint:** O · **Slot:** S07_J32 · **Tamanho:** M · **Depende de:** H04, H07, H08, F09, O1, G05, G10, G13, G14, G15

## Por quê

O terror da seção: neblina total, e só a mão sabe onde há chão. Meio tempo antes de cada batida, a pedra firme bate
na palma; quem salta no firme avança, quem salta na neblina some no escuro. É a háptica como **informação privada**:
quatro no sofá, cada um com o seu caminho. A sala de hoje funciona (nota 3 na diversão), mas o tombo sai do quadro e
ninguém o vê: o redemoinho no lugar da queda é o que muda.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A diversão da seção O](../diversao/O-os-caminhos.md)

Tudo o mais está copiado aqui: o `_pista`, o `_respondeu`, o `_robo_sente`, os ids de som e os números de luz e câmera.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s07/neblina_de_dados.gd` e o `.uid` | novo | não |
| `godot/scripts/minigames/catalogo.gd` | `"S07_J32"` em `MINIGAMES` e na seção `S07`, depois do `S07_J31` | **sim** |
| `godot/scripts/traducoes.gd` | as frases novas | **sim** |
| `godot/testes/prova_do_jogo.gd` | a `_prova_neblina()` no `match` de `_prova_da_ficha` | **sim** |
| `godot/assets/kenney/graveyard-kit/`, `hexagon-kit/` | importados pela O1; se faltarem, `python3 scripts/importar_kenney.py "oficina/kenney/3.7.0/3D assets" graveyard-kit hexagon-kit` (G10) | **sim** |

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J32",
	"titulo": "Neblina de Dados",
	"verbo": "Salte no firme!",
	"genero": "terror",
	"icone": "haptica",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S07_J32",
	"duracao": 100.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "areia",
	"microjogo": {"verbo": "Salte!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"gesto": "jump",
}
```

O `material` é `areia` de propósito: o acerto do kit toca `material:areia` (granulado, 0,14 s) na mão, e a pista é
`material:pedra` (a batida surda). Os dois não se confundem.

## Como se joga

A faixa é `MUS_S07_J32`, 100 bpm (uma batida = 0,6 s). `BATIDA_DA_PRIMEIRA_NOTA` = 4 (do kit). O fim previsto é
`_fim_b := floor(duracao / _t_batida())` = 166; a reta começa em `RETA_B := _fim_b - 16` = 150 (90 s).

- **O caminho de cada um:** para cada batida `n >= BATIDA_DA_PRIMEIRA_NOTA`, `_firme[l][n]` diz se ali há pedra,
  sorteado com o `RandomNumberGenerator` do lugar (semente do kit + `7919 * (l + 1)`): 60 % firme, nunca três neblinas
  seguidas. Gere 400 batidas no `iniciar_jogo()`.
- **A pista:** em `n - 0.5` (adiantada pelo Faro e pela Lanterna, em «O cavaleiro»), se `_firme[l][n]`, a pedra na
  mão: `_pista(l, "material:pedra", "material:pedra", "aviso", n, "firme")` e `nova_nota(l, n, Ritmo.t_da_batida(n))`.
  Na neblina, **nada**: o silêncio é a pista.
- **A entrada:** ✕. No aperto, `m := roundi(Ritmo.batida())`:
  - `_firme[l][m]` e a nota `m` ainda aberta → `_motivo[l] = "hesitou"` e `julgar_toque(l, Ritmo.t_da_batida(m), m,
    true)`;
  - neblina em `m` e `absf(Ritmo.t_musica() - Ritmo.t_da_batida(m)) <= Ritmo.JANELA_BOM` (140 ms) → **o salto no
    nada** (`_cair(l, m)`) e `_respondeu(l, m, "errado")`;
  - fora disso, o aperto não conta: o cavaleiro só dobra os joelhos (`p.gesto("jump", 0.2)`), sem avançar.
- **A nota que passa:** firme em `n` sem aperto até `t(n) + JANELA_BOM` → `_motivo[l] = "hesitou"`,
  `_respondeu(l, n, "nenhuma")`, `nota_perdida(l, n)`.
- **O hoqueto:** todos saltam nas mesmas batidas, cada um no seu caminho; a nota de cada lugar (`TOM_DO_LUGAR`, do kit)
  só soa quando ele pisa firme. A melodia da neblina é a soma dos pés certos.
- **Os pontos e o avanço** (`toque`): uma laje por salto julgado; `marcar(l, PONTOS[j])` com `PONTOS := [0, 50, 75,
  100]`; `_respondeu(l, n, "certo")`.
- **A meta:** `META := 24` lajes; um marco a cada `MARCO := 4`, para todos. A diversão pede «marco a cada 4 para quem
  está em último»: já é 4 para todos hoje, e fica assim.
- **A partitura simples** (`Ritmo.simples[l]`): dali em diante, só as batidas pares podem ser firmes (as ímpares viram
  neblina).
- **O pico, a neblina engrossa:** as 16 batidas a partir de `_pico_b := BATIDA_DA_PRIMEIRA_NOTA + floor((_fim_b -
  BATIDA_DA_PRIMEIRA_NOTA) / 2.0)` = 85 (51 s a 60,6 s): a pista chega em `n - 0.25`, e a TV toca
  `Som.tocar("vento", null, -4.0)` na entrada.
- **A reta** (de `RETA_B` ao fim): cada salto certo vale **2 lajes** e `2 * PONTOS[j]`. O portão aparece no fim da
  neblina: a laje `META` ganha o portão já na batida `RETA_B`.
- **Ensina sem falar:** na contagem, a laje 0 sob o cavaleiro acende (contorno do dono, de `b` 2 a 4); em `b` 2,5 a pedra
  bate na mão (`_pista(..., -1, "ensino")`, sem nota); em `b` 3 o cavaleiro salta sozinho no lugar
  (`p.gesto("jump", 0.4)`). Sem ponto, sem `_dist`.

## A cena

**A câmera** (a «arena» do 01): `camera_pos = Vector3(0, 12.6, 8.6)`, `camera_olhar = Vector3(0, 0.4, -1.6)`, no começo
do `montar()`. Lente de 35 mm (37,8° vertical), plongée de 50°, 15,9 m do alvo, 19,4 m de largura vista: o cavaleiro
de fora (x ±6, até 1,8 m de altura) fica a 77 % da meia largura e a cerca de fora (x ±7,4) a 92 %, medido com a projeção
da lente. Roll zero. Nunca corta. Enquanto o kit não tem a lente por sala, vale o campo de 40° de
hoje com a mesma pose.

**A luz** (S7, lado B, tinta petróleo `Tema.SECAO[2]`): `Tema.luz_da_secao(7, "B")` (G15) dá a névoa `#011311`, o
preenchimento `#11413b` e a chave `#e5d7ad`, com a chave a ×0,85 e a névoa a ×1,3. **O terror é a mesma luz,
escurecida:** a chave e o preenchimento a ×0,35 da energia que a G15 devolve. Saem o `atmosfera(Color("#b9b0ff"), ...)`,
as tochas `#ffb070` e a laje `#0d0b14` de hoje.

- **O pico:** a regra do pico do 01 (chave +20 %) não vale no terror. Na batida `_pico_b`, a chave desce de ×0,35 para
  ×0,25 em 1 batida e a densidade da névoa sobe ×1,5; volta em 2 batidas depois das 16. Com `Opcoes.flashes` desligado,
  o mesmo (escurecer não pisca).
- **O dono do grito:** no salto no nada de `l`, a luz de dono das outras três raias cai 30 % por 1 batida e volta em 1
  batida.

**As peças Kenney** (G10, `Kit.peca(pai, "<pacote>/<peça>", pos, rot_y, escala)`; sem barra = `mini-dungeon`):

| papel | peça | escala | onde |
| --- | --- | --- | --- |
| o chão da arena | `Kit.arena(self, 5, 3)` (do kit) | — | — |
| a laje escura por cima | `Kit.caixa(self, Vector3(26, 0.02, 14), Vector3(0, 0.02, 0), Kit.material(Tema.CASCO, 0.0, 1.0))` | — | — |
| a laje pisada | `hexagon-kit/stone` | 1,1 (1,1 × 0,22 × 1,27 m) | no `Node3D` `caminho` de `l`, em `(0, -0.2, -i * PASSO)`, criada **quando o cavaleiro pousa nela** |
| o marco | `graveyard-kit/gravestone-round` | 2,0 (0,9 × 1,14 × 0,5 m) | `(0.9, 0, -i * PASSO)` a cada `MARCO` lajes |
| a vela do marco | `graveyard-kit/lantern-candle` | 1,5 | em cima do marco, y = 1,14 |
| a cerca da raia | `graveyard-kit/iron-fence` | 1,5 | x = ±1,4, a cada 1,5 m, giro 90° (corre em z) |
| o fundo | `graveyard-kit/pine-crooked` | 1,6 | seis, em x = ±9, z = −4, −8 e −12 |
| o portão | `gate` (mini-dungeon) | 1 | `(0, 0, -META * PASSO - 0.6)` no `caminho` |

`PASSO := 1.2` m. À frente do cavaleiro, nada: é neblina. A neblina rasteira:
`Efeitos.poeira(self, Vector3(0, 0.6, -2), Vector3(24, 1.2, 10), Tema.ETIQUETA_SOMBRA, 90)`. `metallic` no máximo 0,2
em tudo. Partículas vivas no máximo 300.

**O que brilha e de quem é:**

| o quê | energia | dono |
| --- | --- | --- |
| a laje em que o cavaleiro está, `Tema.contorno(Tema.JOGADOR[l], 0.03, 2.0, l)` | 2,0; 2,6 por 4 quadros no pouso | `l` |
| a luz de dono, `OmniLight3D` cor `Tema.JOGADOR[l]`, em `(RAIAS[l], 0.3, Z_JOGADOR - 2.9)` | 0,9; alcance 2,0 m × `raio` (1,6 a 2,4 m): o cavaleiro fica a 2,6 m ou mais, fora do alcance | `l` |
| a luz do marco, `OmniLight3D` cor `Tema.TUNGSTENIO`, no alto da vela | 0,6, alcance 2,5 m | `"mundo"` |
| o redemoinho do salto no nada | `Tema.GRAFITE`, sem emissão | `"mundo"` |
| qualquer outra coisa | no máximo 1,0 | `"mundo"` |

**O movimento, pela batida:** `caminho.position.z = Z_JOGADOR + PASSO * lerpf(_de[l], _ate[l], clampf((b - _salto_b[l])
/ (0.5 / velocidade), 0.0, 1.0))`; o cavaleiro faz `jump` no meio tempo do salto e `idle` no resto. `raia(l)`,
`posicionar(l)`, `p.rotation.y = PI`, `p.preso = true`.

## O som

Só ids do mapa (`docs/jogo/audio/mapa.csv`):

| evento | id | onde toca | chamada |
| --- | --- | --- | --- |
| a faixa | `mus_s07_j32` (100 bpm) | TV | a `faixa` da FICHA |
| a pedra (a pista) | `mod_material_pedra` | atuadores do dono | `_pista(l, "material:pedra", "material:pedra", "aviso", n, "firme")` |
| o pouso (o acerto do kit) | `mod_material_areia` | atuadores do dono | o `material` da FICHA, pelo kit |
| o marco | `mod_coleta` | alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` |
| o salto no nada, na mão | `mod_nota_quebrada_p1..p4` | alto-falante do dono | `Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)` |
| o salto no nada, na TV | `sint_vento` | TV | `Som.tocar("vento", pos, -8.0)` |
| o pico | `sint_vento` | TV | `Som.tocar("vento", null, -4.0)` |
| a chegada | `portao_0` | TV | `Som.tocar("portao", pos)` |

A O2 não usa `falha_*` nem `fx_tropeco_*`: o tombo da neblina é o vento.

## O controle

| evento | para quem | háptica (cabo) | rumble (rádio) | prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| a pedra (batida firme) | só o dono | `material:pedra` nos dois atuadores | `Forja.sentir(l, "aviso")` | `Forja.som_virtual(l)`: entre `n - 0.5` e `n - 0.1`, `esq` e `dir` > 0,05 |
| a neblina (batida sem pedra) | só o dono | **nada** | nada | entre `n - 0.5` e `n - 0.1` de uma neblina, `esq` e `dir` < 0,02 |
| o pouso | o dono | `material:areia` (o kit) | `acerto` (o kit) | a linha `toque` |
| o salto no nada | o dono | — | `Forja.sentir(l, "golpe")` nos dois modos | `Forja.percepcao(l).forte > 0` no quadro da queda |
| a barra de luz | o dono | a cor do lugar a 30 %: `Forja.cor_do_lugar(l).darkened(0.7)` | a mesma | `Forja.percepcao(l).luz` a menos de 0,08 dela fora do piscar do kit |
| o marco (mágica 2) | o dono | a barra sobe a 70 % (`darkened(0.3)`) em 0,1 s e volta a 30 % em 0,5 s | a mesma | entre `t_marco + 0.08` e `t_marco + 0.12`, `luz` a menos de 0,1 de `darkened(0.3)` |
| o alto-falante | o dono | a coleta no marco, a nota quebrada na queda | o mesmo | `som_virtual(l).falante > 0,05` no quadro do marco |

- **O gatilho:** nada a segurar: `Forja.gatilhos_off(l)` no `montar()`. Prova: `percepcao(l).gatilho_dir == 0`.
- **A barra, como se manda:** `Forja.luz(l, ...)` no `iniciar_jogo()`, no marco, e de novo 0,5 s depois de cada `toque`
  e `falha` (o piscar do kit acaba aí e devolve a cor do lugar inteira). Nunca a cada quadro: o piscar do kit é a
  resposta do acerto. 30 % é o piso da F04: não escureça mais.
- **O rádio:** `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)` e a linha `troca` (`haptica` → `rumble`,
  `sem_placa`) uma vez.
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

Chega pronto da G13 (`jogador(l)`): qualquer raça (humana, orc, autômato, golem, raposa), com a cabeça, o superior, o
inferior e o item. A ficha **nunca recolore** nem muda a energia de uma peça: o superior fica na faixa de valor do tecido
(L 0,46 a 0,58), o inferior na do couro (0,22 a 0,36), e o néon do dono só nos acentos, a 1,6. No escuro do terror, o
que o separa da neblina é o contorno do dono (G15), não uma luz em cima dele: a luz de dono fica 2,9 m à frente. O
salto no nada esconde o cavaleiro (`p.visible = false`) e o devolve inteiro, sem trocar material.

Os ganchos (`Cavaleiro.gancho(l, "<gancho>")`, H04; a O2 no `minigames.csv`):

| stat | gancho | o que muda aqui | 1 | 3 | 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `ruido` | o pouso levanta `roundi(10 * ruido)` faíscas `Tema.ETIQUETA_SOMBRA` | ×0,8 (8) | ×1 (10) | ×1,2 (12) |
| Passo | `velocidade` | o deslize do salto: `/ (0.5 / velocidade)` | ×0,94 | ×1 | ×1,06 |
| Fôlego | `levantar` | a volta do escuro: 2 batidas × gancho, arredondado a 0,25 batida, mínimo 0,25 | ×1,25 | ×1 | ×0,75 |
| Faro | `raio` | o alcance da luz de dono, 2,0 m × gancho | ×0,8 | ×1 | ×1,2 |
| Faro | `pista` | a pedra chega antes: `- pista / 1000 / 0.6` batida | −40 ms | 0 | +40 ms |

**Os itens:** o Martelo dobra o PERFEITO no tempo forte (o kit); a Âncora tira 10 % do `velocidade`; o Escudo absorve
o primeiro erro (o kit); o Fole é do combo (o kit). **A Lanterna** adianta a pedra **0,25 batida (0,15 s)**, não meio
tempo: meio tempo a mais poria a pedra em cima do pouso da batida anterior (`material:areia`, 0,14 s), e as duas se
confundiriam na mão. O Diapasão não muda nada (não é dupla). A cadeira de rodas salta na velocidade do Passo. Nenhum
stat nem item muda a janela (140 ms) nem os pontos.

## As reações

Os carimbos vêm do kit; a ficha não chama nada:

- `car_acorde`: os quatro com PERFEITO na mesma batida de tempo 1 (`n % 4 == 0`). Possível: todos saltam nas mesmas
  batidas, quando as quatro têm pedra ali.
- `car_em_chamas`: 5 «Ressonância!» seguidas do mesmo jogador.
- `car_por_um_fio`: o vencedor chega com 2 % dos pontos ou menos de vantagem.
- `car_virada`: quem passa a ser o primeiro.
- `car_emburrado`: o último, no inserto do resultado.

No máximo 1 carimbo vivo por jogador e 2 na tela. Adesivos `rea_*`: só de quem já chegou ao portão.

## A diversão

**O grito: o salto no nada** (`salto_no_nada`), degrau «estrondo». Quem salta na neblina some para baixo, de braços
abertos (`fall`, 1 batida: `p.position.y` de 0,1 a −2,5), fica invisível até `_caindo_ate`, e volta ao último marco
(`_dist[l] = floor(_dist[l] / MARCO) * MARCO`, `p.visible = true`, `p.position.y = 0.1`). As lajes depois do marco
apagam (`visible = false`) no mesmo quadro.

- **O exagero:** 48 partículas (`Efeitos.faiscas(self, pos, Tema.GRAFITE, 48, 1.0)`); `tremer(Sala.TREMOR_GOLPE)` (G05);
  hit-stop de 3 quadros (50 ms) só no cavaleiro (`p.anim.speed_scale = 0.0`, de volta a 1,0 depois de 0,05 s); a mão
  (`golpe`), a TV (vento) e o alto-falante no mesmo quadro.
- **O rastro:** o redemoinho no buraco: `Efeitos.poeira(self, pos, Vector3(1.4, 1.0, 1.4), Tema.GRAFITE, 48)`, que
  some (`queue_free`) 4 s de música depois. As lajes perdidas ficam apagadas.
- **A linha:** `anotar("momento", l, {"nome": "salto_no_nada", "t_musica": Ritmo.t_musica()})` na queda; na batida
  `RETA_B`, `anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": <os lugares por _dist>})`.
- **A curva:** 0 a 51 s, a pedra meio tempo antes; 51 a 60,6 s, a neblina engrossa (um quarto antes, a luz mais
  escura); 90 s ao fim, a reta, cada salto vale 2.
- **Quem está na frente se vê:** as lajes pisadas de cada raia, e o portão mais perto.

**Como o jogador do time confere** (mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

1. Robô: pelo menos 4 linhas `momento` `salto_no_nada` em 100 s, pelo menos 2 entre `_pico_b` e `_pico_b + 16`, e 1
   `momento` `reta`.
2. Prancha: um redemoinho em 1 quadro de cada 4.
3. Enquanto o robô por lugar não existe, a mesa padrão se confere só pela prancha, com o temperamento único.

## A falha

- **O salto no nada:** o grito, acima. As notas firmes que caem enquanto `b < _caindo_ate[l]` não contam (sem pista, sem
  nota). `_caindo_ate[l] = b + maxf(0.25, snappedf(2.0 * levantar, 0.25))`.
- **Hesitou** (a pedra passou sem salto, ou o salto saiu fora da janela): `p.gesto("emote-no", 0.4)`; fica na mesma laje.

## O fim e o vencedor

Quem pousa na laje `META` chega: `_chegada.append(l)`, `acabou[l] = true`, `p.gesto("emote-yes", 1.2)`, o portão e a
coleta. Na primeira chegada, `_fim_batida = b + 8`; depois dela todos acabam. Sem chegada, o kit fecha aos 100 s.
`vencedor()`: `_chegada`, depois os outros pela distância, depois pelos pontos.

## Com menos de quatro

- **3, 2, 1:** nada muda; cada um tem o seu caminho. Com um, ele corre contra o portão.
- **O controle que cai:** nenhuma pista nem nota para ele (`_fora[l] = true`); quando volta, a primeira batida firme a
  partir de `ceili(b + 1)` é a que vale (as do meio não viram erro).
- **Duplas:** não há.

## O robô

Sente a pedra na placa virtual (ou nos motores, no rádio), mira pelo relógio da música e erra pelo temperamento.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	var n := ceili(b)
	# a janela de sentir: da pista (n - 0,5) até pouco antes da batida; o pouso anterior (0,14 s) já passou
	if b > n - 0.55 and b < n - 0.05:
		var s := _robo_sente(l)
		if s.x + s.y > 0.05:
			_robo_firme[l] = n
	if _robo_firme[l] != n or _robo_saltou[l] == n:
		return
	if _robo_decidiu[l] != n:
		_robo_decidiu[l] = n
		var certo := Forja.robo_acerta()
		_robo_mira[l] = 0.0 if certo else (0.25 if _robo_rng.randf() < 0.5 else -1.0)
	if float(_robo_mira[l]) < 0.0:
		# erra saltando na batida seguinte: na neblina, ou atrasado numa pedra
		if Ritmo.t_musica() >= Ritmo.t_da_batida(n + 1):
			Forja.robo_apertar(l, Forja.CRUZ, 0.05)
			_robo_saltou[l] = n
		return
	if Ritmo.t_musica() >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_saltou[l] = n


## O que a mão do controle simulado sente agora: (esquerda, direita).
func _robo_sente(l: int) -> Vector2:
	if _rumble[l]:
		var pc := Forja.percepcao(l)
		return Vector2(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0)))
	var v := Forja.som_virtual(l)
	return Vector2(float(v.get("esq", 0.0)), float(v.get("dir", 0.0)))
```

`_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o robô nunca muda o sorteio do jogo.

## Os ganchos

`godot/scripts/minigames/s07/neblina_de_dados.gd`, `extends Minigame`, sem `class_name`.

```gdscript
extends Minigame
## Neblina de Dados (S07_J32). Neblina total: meio tempo antes de cada batida
## em que há pedra, a pedra bate na mão (só na sua). ✕ no tempo salta para
## ela; saltar onde a mão ficou calada é cair na neblina.

const FICHA := { ... }   # a de cima

const META := 24
const MARCO := 4
const PASSO := 1.2
const PONTOS := [0, 50, 75, 100]
const FIRME_CHANCE := 0.6
const PICO_BATIDAS := 16
const LUZ_TERROR := 0.35
const LUZ_PICO := 0.25

var _rng := {}
var _robo_rng := RandomNumberGenerator.new()
var _firme := [[], [], [], []]   ## lugar -> [bool por batida]
var _aberta := [{}, {}, {}, {}]  ## lugar -> {n: true}, as notas firmes à espera
var _pistas := [-1, -1, -1, -1]  ## a última batida cuja pista já saiu
var _dist := [0, 0, 0, 0]
var _de := [0.0, 0.0, 0.0, 0.0]
var _ate := [0.0, 0.0, 0.0, 0.0]
var _salto_b := [-9.0, -9.0, -9.0, -9.0]
var _caindo_ate := [-1.0, -1.0, -1.0, -1.0]
var _motivo := ["", "", "", ""]
var _chegada: Array = []
var _fim_b := 166
var _fim_batida := -1.0
var _pico_b := 9999.0
var _reta_anotada := false
var _rumble := [false, false, false, false]
var _fora := [false, false, false, false]
var _luz_marco_t := [-9.0, -9.0, -9.0, -9.0]
var _luz_volta_t := [-9.0, -9.0, -9.0, -9.0]
var _nos := {}                    ## lugar -> {caminho, lajes, luz}
var _robo_firme := [-1, -1, -1, -1]
var _robo_saltou := [-1, -1, -1, -1]
var _robo_decidiu := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 12.6, 8.6)
	camera_olhar = Vector3(0, 0.4, -1.6)
	Kit.arena(self, 5, 3)
	# a luz da seção a 0,35, a laje escura, o fundo e a neblina: «A cena»
	for p in jogadores:
		_nos[p.lugar] = _montar_raia(p.lugar)
		Forja.gatilhos_off(p.lugar)


func iniciar_jogo() -> void:
	_robo_rng.seed = rng.seed + 99
	_fim_b = int(floor(duracao / _t_batida()))
	_pico_b = BATIDA_DA_PRIMEIRA_NOTA + floor((_fim_b - BATIDA_DA_PRIMEIRA_NOTA) / 2.0)
	for l in presentes():
		# o rng do lugar, o caminho (_gerar), o rádio (_rumble e a troca)
		Forja.luz(l, Forja.cor_do_lugar(l).darkened(0.7))


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	if b >= _fim_b - 16 and not _reta_anotada:
		_reta_anotada = true
		anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": _ordem_por_distancia()})
	for l in presentes():
		if acabou[l]:
			continue
		if not conectado(l):
			_fora[l] = true
			continue
		if _fora[l]:
			_fora[l] = false
			_aberta[l].clear()
			_pistas[l] = ceili(b + 1) - 1
		_pistas_na_mao(l, b)       # a pedra de n em n - 0,5 (no pico, n - 0,25), adiantada; abre a nota
		if Forja.apertou(l, Forja.CRUZ) and b >= _caindo_ate[l]:
			_salto(l)
		_notas_que_passaram(l)     # firme sem salto: "hesitou", nenhuma, nota_perdida
		_barra(l)                  # o marco (70 % e volta) e a volta depois do piscar do kit
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	var reta := Ritmo.batida() >= _fim_b - 16
	marcar(l, PONTOS[j] * (2 if reta else 1))
	_pousar(l, 2 if reta else 1)   # _dist, a laje nova, o marco (coleta, barra), a chegada
	_luz_volta_t[l] = Ritmo.t_musica() + 0.5


func falha(l: int) -> void:
	_luz_volta_t[l] = Ritmo.t_musica() + 0.5
	if _motivo[l] == "hesitou":
		jogador(l).gesto("emote-no", 0.4)


func vencedor() -> Array:
	var resto := presentes().filter(func(l): return not l in _chegada)
	resto.sort_custom(func(a, b): return _dist[a] > _dist[b] or (_dist[a] == _dist[b] and pontos[a] > pontos[b]))
	return _chegada + resto


func _t_batida() -> float:
	return Ritmo.t_da_batida(1.0) - Ritmo.t_da_batida(0.0)
```

As funções que faltam, pelo que já foi dito:

- `_salto(l)`: o que «A entrada» diz; a nota firme aberta vai para `julgar_toque` e sai de `_aberta`.
- `_cair(l, m)`: o grito de «A diversão»: `Forja.sentir(l, "golpe")`, a nota quebrada, o vento, as faíscas, o
  redemoinho, o tremor, o hit-stop, `_caindo_ate`, o `_dist` volta ao marco, a luz das outras raias, o `momento`.
- `_pousar(l, quanto)`: `_dist += quanto` (no máximo `META`), a laje nova, as faíscas do `ruido`; no múltiplo de
  `MARCO`, a coleta e `_luz_marco_t[l] = Ritmo.t_musica()`; em `META`, a chegada.
- `_barra(l)`: com `dt := Ritmo.t_musica() - _luz_marco_t[l]`: de 0 a 0,1 s, `darkened(lerpf(0.7, 0.3, dt / 0.1))`;
  de 0,1 a 0,6 s, `darkened(lerpf(0.3, 0.7, (dt - 0.1) / 0.5))`; no quadro em que `t_musica` passa de
  `_luz_volta_t[l]`, `darkened(0.7)`. Manda `Forja.luz` só quando a cor muda.
- `_pistas_na_mao`, `_notas_que_passaram`, `_ordem_por_distancia`, `_montar_raia` e `_mostrar`: a cena e as regras de
  cima.

A dica: `["@cross"]` sob a raia enquanto `not aprendeu(l)`, com a guarda `if not na_raia(l): return {}`. O `status(l)`:
`"%d de %d" % [_dist[l], META]`, ou `"Chegou"`.

`godot/scripts/traducoes.gd`: `"Neblina de Dados": "Data Fog"`, `"Salte no firme!": "Jump on solid ground!"`,
`"Salte!": "Jump!"` (a O1 já pôs `"Chegou"`).

## O que o registro mede

- `pista` `mandou` de cada pedra (`o_que` `firme`, `canal`) e a `entrada` `resposta` (`certo` no salto julgado,
  `nenhuma` na pedra que passou, `errado` no salto na neblina): é daqui que a noite tira «P3 respondeu às pistas só de
  háptica em 71 % das vezes»;
- `troca` no rádio; `som_controle` de cada pedra; `nota` e `toque` (o kit);
- `momento` `salto_no_nada` e `reta`.

## Armadilhas

- **O robô sorteia no dele** (`_robo_rng`): com robô ou com gente, o mesmo jogo.
- **Duas coisas na háptica ao mesmo tempo.** O pouso (areia, 0,14 s) sai na batida `n`; a próxima pedra, em `n + 0.5`
  (no pico, `n + 0.75`; com Faro 5 e Lanterna, `n + 0.18`, ainda depois dos 0,14 s). A 100 bpm sobra tempo; não suba o
  andamento nem a antecedência.
- **Rumble e háptica nunca juntos:** a queda chama `sentir` (250 ms) na batida `m`; não mande pista enquanto `b <
  _caindo_ate[l]`.
- **A luz a 30 %** é o piso da F04. O kit devolve a cor do lugar no fim (`Forja.silencio` no `terminar`).
- **A prova roda a `duracao` inteira** pelo relógio de parede (o fim conta em tempo de música, H08): o pico e a reta
  chegam.

## Pronto quando

Joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos; aguenta o cabo que cai e volta;
fecha com vencedor; a barra fica a 30 % na cor do lugar, sobe a 70 % no marco e volta no fim; a neblina fica calada na
mão; a mesa padrão grava pelo menos 4 `salto_no_nada`; e as provas abaixo passam com a prancha olhada.

## Provas

`_prova_neblina()` em `godot/testes/prova_do_jogo.gd`, chamada pelo `match` de `_prova_da_ficha(slot)`:
`"S07_J32": await _prova_neblina()`.

```gdscript
## S07_J32: a pedra chega à placa virtual de cada um e a neblina fica calada,
## a barra fica a 30 % e sobe no marco, e o salto no nada se registra.
func _prova_neblina() -> void:
	var sentiu := [false, false, false, false]
	var vazou := [0]
	var luz_fora := [0]
	var marco_ok := [0]
	var q := [0]
	var olhar := func(mg: Minigame) -> void:
		q[0] += 1
		var b := Ritmo.batida()
		var n := ceili(b)
		for l in mg.presentes():
			var c: Color = Forja.percepcao(l).get("luz", Color.BLACK)
			var dt := Ritmo.t_musica() - float(mg._luz_marco_t[l])
			if dt >= 0.08 and dt <= 0.12:
				var alto := Forja.cor_do_lugar(l).darkened(0.3)
				if Vector3(c.r - alto.r, c.g - alto.g, c.b - alto.b).length() < 0.1:
					marco_ok[0] += 1
			elif q[0] > 60 and dt > 0.7:
				var alvo := Forja.cor_do_lugar(l).darkened(0.7)
				if Vector3(c.r - alvo.r, c.g - alvo.g, c.b - alvo.b).length() > 0.08:
					luz_fora[0] += 1
			# a mão: só na janela da pista (n - 0,5 a n - 0,1), fora da queda
			if b <= n - 0.5 or b >= n - 0.1 or b < mg._caindo_ate[l] or n >= mg._firme[l].size():
				continue
			var v := Forja.som_virtual(l)
			var e := float(v.get("esq", 0.0))
			var d := float(v.get("dir", 0.0))
			if mg._firme[l][n] and e > 0.05 and d > 0.05:
				sentiu[l] = true
			if not mg._firme[l][n] and (e >= 0.02 or d >= 0.02):
				vazou[0] += 1
	var mg := await _joga_o_minigame("S07_J32", 140.0, olhar)
	if mg == null:
		return
	_esperar(sentiu.all(func(s): return s), "S07_J32: a pedra chegou aos dois lados da mão dos quatro %s" % [sentiu])
	_esperar(vazou[0] == 0, "S07_J32: a neblina ficou calada na mão (%d quadros com toque)" % vazou[0])
	_esperar(marco_ok[0] >= 1, "S07_J32: a barra subiu a 70 %% em algum marco (%d)" % marco_ok[0])
	# o piscar do kit (até 0,5 s) sai dos 30 %; no máximo um quarto dos quadros
	_esperar(luz_fora[0] * 4 <= maxi(q[0] - 60, 1), "S07_J32: a barra ficou a 30 %% fora do piscar (%d fora)" % luz_fora[0])
	_esperar(mg._dist.max() >= 1, "S07_J32: alguém pousou numa pedra (%s)" % [mg._dist])
	_esperar(mg.colocacao().size() == mg.presentes().size(), "S07_J32: a colocação tem todos")
```

No `_prova_do_relatorio()`, no laço da linha do tempo, do `S07_J32`: ≥ 1 `entrada` `resposta` `certo`; ≥ 1 `momento`
`salto_no_nada`; 1 `momento` `reta`.

Os comandos:

1. `SALA=S07_J32 bash tests/prova_do_jogo.sh`
2. `bash tests/prova_visual.sh`, e olhar a prancha nas partidas com quatro (`bom` e `ruim`), com dois, com um e com o
   cabo que cai. O que se olha: a neblina não vira tela vazia (o cavaleiro com o contorno, as lajes pisadas e os marcos
   aparecem em todo quadro), o redemoinho em 1 quadro de cada 4, e as peças do cavaleiro com as tintas da montagem.
3. Na máquina do André: `./run-local.sh -- --sala=S07_J32`, com um controle no cabo e um no rádio. No cabo, a pedra tem
   de ser inconfundível na palma e chegar com tempo de reagir; no rádio, o `aviso` pelo rumble tem de dar para jogar.

## Ao terminar

- No [quadro](README.md), a linha O2: **feito**, com o commit.
- Commit sugerido: `feat(neblina): Neblina de Dados no kit, só a mão sabe onde há chão`
