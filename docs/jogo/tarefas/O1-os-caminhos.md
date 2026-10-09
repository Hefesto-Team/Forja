# O1 — Os Caminhos

**Sprint:** O · **Slot:** S07_J31 · **Tamanho:** G · **Depende de:** H04, H07, H08, F01, F09, G05, G08, G10, G13, G14, G15

## Por quê

A sala de hoje (`godot/scripts/salas/caminhos.gd`) é uma prova às cegas: três passos no escuro e a pergunta «que chão é
esse?». No kit ela vira corrida: a senha do seu portão chega **só na sua mão** (a textura do chão certo), três trilhas
se abrem à sua frente, e você pisa na certa no tempo. A pergunta some: a trilha escolhida **é** a resposta, e continua
alimentando o veredito `haptica_audio` da bancada.

## Ler antes

- [O molde de minigame](molde-de-minigame.md)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A diversão da seção O](../diversao/O-os-caminhos.md)

Tudo o mais que esta ficha usa está copiado aqui: o `_pista`, o `_respondeu`, o `_robo_sentir`, os ids de som e os
números de luz e câmera.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s07/os_caminhos.gd` e o `.uid` | novo | não |
| `godot/scripts/minigames/catalogo.gd` | `"S07_J31"` em `MINIGAMES` e na seção `S07`; tirar `"caminhos"` de `SALAS_ANTIGAS` | **sim** (O2 a O5 também) |
| `godot/scripts/traducoes.gd` | as frases novas; tirar as que só a sala velha usava | **sim** |
| `godot/testes/prova_do_jogo.gd` | a `_prova_os_caminhos()` no `match` de `_prova_da_ficha`; tirar a prova às cegas velha | **sim** |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO`, se ainda não estiver | **sim** (o kit) |
| `docs/jogo/13-arquitetura.md` | a linha `momento` na tabela «Os eventos do jogo», no mesmo commit | **sim** |
| `godot/scripts/salas/caminhos.gd` e o `.uid` | saem (`git rm`) | não |
| `scripts/importar_kenney.py` | três linhas novas, no formato das que já estão lá (pasta → pacote, papel, filtro): `mini-forest` → Mini Forest, `hexagon-kit` → Hexagon Kit, `tower-defense-kit` → Tower Defense Kit em `APROVADOS`, papel `cenario`, filtro «tudo» (a G10 manda os kits da coluna «entra» do 14 entrarem assim quando um minigame pede) | **sim** |
| `godot/assets/kenney/mini-forest/`, `hexagon-kit/`, `tower-defense-kit/`, `graveyard-kit/` | importados pelo script da G10 | **sim** (a O2 e a O4 usam o `graveyard-kit`) |

Na `prova_do_jogo.gd`, o que sai e o que muda (as linhas de hoje):

1. O bloco «Os Caminhos, às cegas» (linhas 226 a 248) sai inteiro.
2. Em `_em_pergunta`, o ramo `"caminhos":` (linhas 872 a 875, `SalaCaminhos.PERGUNTA`) sai.
3. Em `_prova_do_modo`, `"caminhos"` sai da lista das perguntas da bancada (linha 906).
4. Na linha 912, a linha do tempo compara pelo apelido: `Catalogo.apelido(str(e.get("slot", ""))) == id`.

Continuam valendo pelo apelido, sem mudar: `SALAS=...caminhos` em `tests/prova_de_poucos.sh`, `musica.gd`,
`partida.gd` e `salao.gd`. `grep -rn "SalaCaminhos" godot/` tem de dar vazio no fim.

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S07_J31",
	"titulo": "Os Caminhos",
	"verbo": "Sinta e pise!",
	"genero": "corrida",
	"icone": "haptica",
	"entradas": [Forja.ESQUERDA, Forja.CIMA, Forja.DIREITA],
	"camera": "fixa",
	"faixa": "MUS_S07_J31",
	"duracao": 100.0,
	"fim": "primeiro_a_chegar",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Sinta!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_HAPTICA,  # o kit abre este papel de som no entrar() (H08)
	"features": ["haptica_audio"],     # a bancada: o veredito da háptica sai das trilhas escolhidas
	"botoes_medidos": [Forja.ESQUERDA, Forja.CIMA, Forja.DIREITA, Forja.TOUCHPAD],
	"gesto": "lados",
}
```

O verbo é o da [diversão](../diversao/O-os-caminhos.md#o1--os-caminhos): «Sinta e pise!» (duas palavras de ação, a régua
item 2).

## Como se joga

A faixa é `MUS_S07_J31`, 120 bpm (uma batida = 0,5 s). As quatro primeiras batidas são a contagem
(`BATIDA_DA_PRIMEIRA_NOTA` = 4, do kit, H08).

**Uma bifurcação** dura `CICLO := 8` batidas. Para o lugar `l`, a bifurcação `k` começa na batida `b0`:

| batida | o que acontece |
| --- | --- |
| `b0` | a senha, 1º passo: `passo:<senha>:<k % 3>` **só no atuador esquerdo** do dono |
| `b0 + 2` | a senha, 2º passo: `passo:<senha>:<(k + 1) % 3>` **só no atuador direito** |
| `b0 + 4` | as três trilhas sobem na frente do cavaleiro (esquerda, meio, direita), cada uma num chão; uma é a da senha |
| `b0 + 6` | **a escolha**: ◀, ▲ ou ▶ no tempo (a nota `k`, alvo `Ritmo.t_da_batida(b0 + 6)`) |
| `b0 + 6` a `b0 + 8` | o cavaleiro anda para a trilha escolhida (o mundo desliza pela batida) |

A senha **anda** na mão: da esquerda para a direita, como um passo. É a mágica 1 da pesquisa, e é o que ensina sem
falar que o chão vem de baixo e passa.

- **O hoqueto:** a primeira bifurcação de cada um começa em `BATIDA_DA_PRIMEIRA_NOTA + 2 * i`, onde `i` é a posição do
  lugar em `presentes()`. Com quatro, as escolhas caem nas batidas 2, 4, 6 e 8 de cada ciclo, uma por jogador, e a nota
  de cada um soa na TV (`TOM_DO_LUGAR` do kit). A frase só fica inteira se os quatro escolhem no tempo.
- **A entrada:** a direção vale de `b0 + 4` até `alvo + Ritmo.JANELA_BOM` (140 ms). Antes de `b0 + 4` o aperto é
  ignorado. A primeira direção apertada é a escolha, e não se troca.
- **O julgamento:** trilha certa → `julgar_toque(l, alvo, k, true)` (a trilha é perigo físico: quem está em último ganha
  a folga do kit). Trilha errada → `nota_perdida(l, k)` com `_motivo[l] = "lama"`. Nenhuma direção até a nota passar →
  `nota_perdida(l, k)` com `_motivo[l] = "parou"`.
- **Os pontos e o avanço** (`toque`): o cavaleiro avança `AVANCO[j]` trechos (BOM 1,0; ÓTIMO 1,25; PERFEITO 1,5) e
  marca `round(100 * avanço)`.
- **A meta:** `META := 57.0` trechos até o portão. Um trecho = `LADRILHO := 1.5` m. O número vem da conta da
  partida: o perfeito faz 48 trechos até 66 s e chega na batida 178 ou depois, e com a `CORTESIA` de 8 batidas a
  partida passa de `RETA_B` (184); o robô `bom` (95 %) chega em 44 % das sementes, perto da batida 182; o `medio` não
  chega. Assim o pico e a reta acontecem em toda partida. A trilha tem `META + 3` = 60 trechos.
- **A partitura simples** (`Ritmo.simples[l]`): as bifurcações de `k` ímpar, fora do pico, viram corredor reto: sem
  senha, sem nota; o cavaleiro anda 0,5 trecho sozinho em `b0 + 6`.
- **O relógio:** a `duracao` é 100 s de música (o kit conta em tempo de música, H08). `FIM_BATIDA :=
  BATIDA_DA_PRIMEIRA_NOTA + 196` só serve para prever as bifurcações.
- **O pico, a descida** (33 a 66 s): toda bifurcação que **começa** com `b0` de `PICO_DE_B := 66` (33 s) até antes de
  `PICO_ATE_B := 132` (66 s) vem no dobro (`CICLO_PICO := 4`): o 1º passo da senha em `b0`, **nos dois atuadores**, as
  trilhas e a escolha em `b0 + 2`, e o avanço vale 1,5 vez. O pico se mede pela batida, não pelo número da
  bifurcação: com o hoqueto, cada lugar entra e sai nele na sua vez.
- **A reta** (as últimas 16 batidas, de `RETA_B := FIM_BATIDA - 16` em diante): cada bifurcação certa vale **2 trechos**
  (no lugar de `AVANCO[j]`) e `200` pontos, para todos. Nenhuma regra nova.
- **A lama se espalha** (quem está perdendo): quando alguém cai na lama de chão `c`, a próxima bifurcação do líder
  (o maior `_dist` entre os outros) chega enlameada se a trilha certa dele tem o chão `c`: o acerto nela avança metade
  (`ganho * 0.5`). A janela não muda.

## A cena

**A câmera** (a «arena» do [01](../arte/01-cinema.md#o-plano-de-cada-momento)): lente de 35 mm, campo vertical de
37,8°, plongée de 50°. `camera_pos = Vector3(0, 12.6, 8.6)`, `camera_olhar = Vector3(0, 0.4, -1.6)`, no começo do
`montar()`. A 15,9 m do alvo, a largura vista em 16:9 é 19,4 m: o cavaleiro de fora (x ±6, até 1,8 m de altura) fica a
77 % da meia largura e as placas de fora (x ±6,8) a 74 %, medido com a projeção da lente. Roll zero. **Nunca corta** durante o jogo. Enquanto o kit não tem a lente por sala, a câmera do main fica com o
campo de hoje (40°) e a pose acima vale do mesmo jeito (2 % mais aberta).

**A luz** (S7, tinta petróleo `Tema.SECAO[2]` = `#1f8a7e`): a ficha não chama `Tema.luz_da_secao`. A entrada da sala
chama `acender(7, partida.lado() == "B")` (G15 e G16), e o lado não é fixo: a S7 pode cair no lado A (antes do
intervalo) ou no B (depois). A G15 tira de `Tema.luz_da_secao(7, lado_b)` a névoa `#011311`, o preenchimento `#11413b` e a chave
`#e5d7ad`, com densidade 0,012 e energia da chave 1,8; no lado B, densidade ×1,3 (0,0156) e chave ×0,85 (1,53). A
chave são as tochas de `luzes()`: a ficha as monta com `luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0,
3.0, 4)])`, e o `Sala.acender(luz)` as pinta. Quando a ficha mexe na chave, multiplica a `light_energy` dessas tochas
sobre a `energia_chave` que a G15 pôs. O preenchimento é `environment.ambient_light_energy` (0,42 pela G15) e a névoa é
`environment.fog_density` (sobre a `densidade`), com `var environment := get_viewport().find_world_3d().environment`.
A ficha não escreve cor de luz em hex: sai o `atmosfera(Color("#b9b0ff"), ...)` de hoje e
a cor `#ffb070` das tochas passa a vir da G15.

- **O pico:** na batida `PICO_DE_B` (66, 33 s), a chave sobe 20 % em 1 batida (0,5 s) e a névoa abre (densidade
  ×0,8); volta em 2 batidas a partir de `PICO_ATE_B` (132, 66 s). Com `Opcoes.flashes` desligado, sobe 10 % em 2 batidas.
- **O dono do grito:** na lama de `l`, a luz de dono das outras três raias cai 30 % por 1 batida e volta em 1 batida.

**As peças Kenney** (G10, `Kit.peca(pai, "<pacote>/<peça>", pos, rot_y, escala)`; sem barra = `mini-dungeon`). Antes:
as três linhas novas de `APROVADOS` (em «Arquivos que mudam») e `python3 scripts/importar_kenney.py mini-forest hexagon-kit
tower-defense-kit graveyard-kit`, que acha o All-in-1 em `oficina/kenney/` sozinho.

| papel | peça | escala | onde |
| --- | --- | --- | --- |
| o chão da arena | `Kit.arena(self, 5, 3)` (do kit) | — | — |
| o corredor de cada raia | `graveyard-kit/road`, duas por trecho, lado a lado | 1,9 (1,52 × 1,50 m cada) | `Node3D` `trilha` em `(RAIAS[l], 0, Z_JOGADOR)`, x = ±0,76, z = `-s * LADRILHO`, `META + 3` trechos |
| a borda | `mini-forest/rocks-low` | 0,6 | x = ±1,7, a cada dois trechos, giro `_rng[l].randf() * TAU` |
| o portão | `gate` (mini-dungeon) | 1 | `(0, 0, -META * LADRILHO - 0.8)` na trilha |
| a trilha **grama** | `mini-forest/patch-grass` | 0,8 | as placas, abaixo |
| a trilha **cascalho** | `mini-forest/patch-dirt` com `mini-forest/stones` em cima | 0,8 e 0,4 | |
| a trilha **metal** | `tower-defense-kit/tile` | 0,8 | |
| a trilha **água** | `hexagon-kit/water` | 0,7 | |
| a lama | `Kit.caixa(self, Vector3(1.0, 0.5, 1.0), <pos do cavaleiro>, Kit.material(Tema.OXIDO, 0.0, 1.0))` | — | em volta do cavaleiro, na bifurcação seguinte à queda |

As três placas da bifurcação são filhas de `self` (ficam sempre à frente do cavaleiro), em
`(RAIAS[l] + DX_TRILHA[d], -0.2, Z_JOGADOR - 1.4)`, com `DX_TRILHA := [-0.8, 0.0, 0.8]`. Cada placa tem as quatro peças
de chão filhas, e só a do chão da vez fica visível. Em `b0 + 4` sobem de y = −0,2 a 0,05 em 1 batida. `metallic` no
máximo 0,2 em tudo; nenhuma cor de chão em hex: a diferença entre os chãos vem da peça.

**O que brilha e de quem é:**

| o quê | energia | dono |
| --- | --- | --- |
| a placa escolhida, `Tema.contorno(Tema.JOGADOR[l], 0.03, 2.0, l)` | 2,0; 2,6 por 4 quadros no acerto | `l` |
| a placa certa da **primeira** senha de cada um (o ensino), o mesmo contorno, de `b0 + 4` a `b0 + 5` | 2,0 | `l` |
| a luz de dono, `OmniLight3D` cor `Tema.JOGADOR[l]`, em `(RAIAS[l], 0.3, Z_JOGADOR - 2.6)`: o cavaleiro fica a 2,3 m ou mais, fora do alcance | 0,9, alcance 2,0 m | `l` |
| as faíscas da lama, `Efeitos.faiscas(self, pos, Tema.OXIDO_BRILHO, 48, 1.0)` | 2,4 por 12 quadros | `l` |
| a borda da raia (do kit) | a do kit | `l` |
| qualquer outra coisa | no máximo 1,0 | `"mundo"` |

**O cavaleiro na cena:** `raia(l)` e `posicionar(l)` do kit; `p.rotation.y = PI` (de costas, andando para o fundo) e
`p.preso = true`. O mundo desliza pela batida: `trilha.position.z = Z_JOGADOR + LADRILHO * lerpf(_de[l], _ate[l],
clampf(b - _passo_b[l], 0.0, 1.0))`. O cavaleiro faz `walk` enquanto `b - _passo_b < 1`, `sprint` no PERFEITO, `idle`
no resto.

## O som

Só ids do [mapa do áudio](../o-time/o-mapa-do-audio.md) (`docs/jogo/audio/mapa.csv`):

| evento | id | onde toca | chamada |
| --- | --- | --- | --- |
| a faixa | `mus_s07_j31` (120 bpm, Sol menor) | TV | a `faixa` da FICHA |
| a senha, cada passo | `mod_passo_<chão>_<v>` (grama, cascalho, metal, agua; v de 0 a 2) | atuadores do dono | `Forja.som_haptica(l, "passo:<s>:<v>", "", 1.0)` e o espelho |
| a trilha certa (o kit) | `mod_material_pedra` | atuadores do dono | o `material` da FICHA, pelo kit |
| a lama | `mod_material_lama` | atuadores do dono | `Forja.tocar_material(l, "lama", "golpe", 1.0)` |
| a lama, na TV | `fx_tropeco_*` (hoje `falha_*`, que ele substitui) | TV | `Som.tocar("falha", pos, -4.0)` |
| a chegada | `portao_0` | TV | `Som.tocar("portao", pos)` |
| a chegada, no dono | `mod_coleta` | alto-falante do dono | `Forja.som_falante(l, "coleta", 0.7)` |
| a descida (o pico) | `sobe_0` | TV | `Som.tocar("sobe")` na batida `PICO_DE_B` (66) |

A nota de cada um e o julgamento escrito são do kit. `fx_tropeco_*` e `falha_*` já listam a O1 na coluna `fichas` do
mapa.

## O controle

| evento | para quem | háptica (cabo) | rumble (rádio) | prova sem o controle na mão |
| --- | --- | --- | --- | --- |
| senha, 1º passo (`b0`) | só o dono | `passo` **só no esquerdo**, ganho 1,0 | `Forja.sentir(l, RUMBLE_CHAO[s])` | `Forja.som_virtual(l)`: de `b0` a `b0 + 0,3`, `esq > 0,05` e `dir < 0,02` |
| senha, 2º passo (`b0 + 2`) | só o dono | `passo` **só no direito**, ganho 1,0 | o mesmo `sentir` | de `b0 + 2` a `b0 + 2,3`, `dir > 0,05` e `esq < 0,02` |
| senha no pico | só o dono | `passo` nos **dois**, ganho 1,0 | o mesmo | `esq` e `dir` > 0,05 |
| trilha certa | o dono | `material:pedra` nos dois, 60 ms (o kit) | `acerto` (o kit) | a linha `toque` com julgamento |
| lama | o dono | `material:lama`, `golpe` | `Forja.sentir(l, "golpe")` | `Forja.percepcao(l)`: `forte > 0` no rádio simulado |

- `RUMBLE_CHAO := ["toque", "golpe_esq", "golpe", "golpe_dir"]`: grama leve, cascalho à esquerda, metal forte, água à
  direita. No rádio a senha não anda de lado (o rumble não separa os atuadores como a placa).
- **O rádio:** `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)` no `iniciar_jogo()`, e a linha `troca`
  (`de` `haptica`, `para` `rumble`, `motivo` `sem_placa`) uma vez.
- **A barra de luz:** a cor do lugar, sempre; o minigame não chama `Forja.luz`. Prova: `Forja.percepcao(l).luz` igual a
  `Forja.cor_do_lugar(l)` fora do piscar do kit.
- **O gatilho:** nada a segurar: `Forja.gatilhos_off(l)` no `montar()`. Prova: `percepcao(l).gatilho_dir == 0`.
- **O alto-falante:** a nota do dono no PERFEITO (o kit) e a coleta na chegada. Prova: `som_virtual(l).falante > 0,05`
  no quadro da chegada.
- **O microfone:** não se usa.
- **Os outros jogadores** não sentem nada da senha de ninguém: a pista é privada.

O código da pista, igual nas cinco fichas da seção:

```gdscript
# A pista na mão do lugar: no cabo, a onda nos atuadores; sem placa (o
# rádio), a mesma pista pelo rumble, nunca os dois (docs/jogo/05, o rádio).
func _pista(l: int, esq: String, dir: String, sensacao: String, n: int, o_que: String) -> void:
	if _rumble[l]:
		Forja.sentir(l, sensacao)
	else:
		Forja.som_haptica(l, esq, dir, 1.0)
	anotar("pista", l, {"n": n, "evento": "mandou",
		"canal": "rumble" if _rumble[l] else "haptica", "o_que": o_que})


func _respondeu(l: int, n: int, resposta: String) -> void:
	anotar("entrada", l, {"o": "resposta", "n": n, "resposta": resposta})  # o que o jogador fez com a pista (13, H08)
```

A senha: no 1º passo `_pista(l, "passo:%d:%d" % [s, v], "", RUMBLE_CHAO[s], k, NOME_CHAO[s])`; no 2º
`_pista(l, "", "passo:%d:%d" % [s, v], ...)`; no pico os dois lados com o mesmo som.

## O cavaleiro

O cavaleiro chega pronto da G13 (`jogador(l)`): cabeça, superior, inferior e item, de qualquer raça. A ficha não
presume que ele é humano e **nunca recolore** uma peça: a roupa de cima e a de baixo ficam com as tintas da montagem
do começo ao fim. A lama é uma caixa em volta dele, não uma cor nele. A luz de dono fica 2,6 m à frente, com alcance de 2,0 m,
e não chega às peças. A raça não muda a raia, o passo nem a janela; o superior e o inferior ficam nas faixas de
valor da bíblia do cavaleiro (tecido L 0,46 a 0,58, couro 0,22 a 0,36), com o néon do dono só nos acentos a 1,6.

Os ganchos (`Cavaleiro.gancho(l, "<gancho>")`, H04; a O1 no `minigames.csv`):

| stat | gancho | o que muda aqui | 1 | 3 | 5 |
| --- | --- | --- | --- | --- | --- |
| Passo | `velocidade` | o deslize do trecho: `clampf((b - _passo_b) * gancho, 0, 1)` | ×0,94 | ×1 | ×1,06 |
| Fôlego | `levantar` | a queda na lama: 3 tempos × gancho, arredondado à semicolcheia, mínimo uma | ×1,25 | ×1 | ×0,75 |
| Faro | `pista` | a senha chega antes: `b0 - gancho / 1000 / 0,5` batidas (a nota não muda) | −40 ms | 0 | +40 ms |

O Peso não se usa aqui. **Os itens:** o Martelo dobra o PERFEITO no tempo forte (o kit); a Âncora anda 10 % mais devagar
fora da liga (multiplica o `velocidade`); o Escudo absorve o primeiro erro (o kit); o Fole é do combo (o kit); a
Lanterna adianta a senha meio tempo (0,25 s), somada ao Faro. O Diapasão não muda nada aqui (não é dupla). A cadeira de
rodas anda na velocidade do Passo, como as pernas. **Nenhum stat nem item muda a janela** (140 ms) nem o momento da nota.

## As reações

Os carimbos vêm do kit; a ficha não chama nada, só diz quais podem sair:

- `car_em_chamas`: 5 «Ressonância!» seguidas do mesmo jogador (possível: uma escolha por ciclo).
- `car_por_um_fio`: o vencedor chega com 2 % dos pontos ou menos de vantagem.
- `car_virada`: quem passa a ser o primeiro no placar.
- `car_emburrado`: o último, no inserto do resultado.
- `car_acorde`: **não sai** aqui: o hoqueto põe uma escolha por tempo, os quatro nunca acertam no mesmo tempo 1.

No máximo 1 carimbo vivo por jogador e 2 na tela. Adesivos `rea_*`: só de quem já chegou ao portão.

## A diversão

**O grito: a lama** (`lama`), degrau «estrondo». A trilha errada vira lama: o cavaleiro afunda 0,5 m (`p.position.y =
-0.5`), faz `fall` (0,8 s), e a bifurcação seguinte se perde no lamaçal: sem senha, sem nota, `walk` a 0,4 e avanço de
0,25 trecho, enquanto os outros passam.

- **O exagero:** 48 partículas de lama; `tremer(Sala.TREMOR_GOLPE)` (G05: é o tremor do degrau nesta versão, e a ficha não cria outro);
  hit-stop de 3 quadros (50 ms) só no cavaleiro (`p.anim.speed_scale = 0.0` e volta a 1,0 depois de 0,05 s de
  música); a mão, a TV e o quadro no mesmo quadro de 16,7 ms.
- **O rastro:** a caixa de lama fica em volta dele até o fim da bifurcação seguinte (8 batidas = 4 s); a placa de lama
  fica no caminho e quem vem atrás a vê.
- **A linha:** na queda, `anotar("momento", l, {"nome": "lama", "t_musica": Ritmo.t_musica()})`. Na batida `RETA_B`,
  `anotar("momento", -1, {"nome": "reta", "t_musica": Ritmo.t_musica(), "ordem": <os lugares por _dist, do maior ao menor>})`.
- **A curva:** 0 a 33 s, uma bifurcação a cada 8 batidas; 33 a 66 s, a descida no dobro; 66 a 92 s, uma a cada 8 de
  novo; 92 s (batida 184) ao fim, a reta.
- **Ensina sem falar:** a primeira senha de cada um vem com a placa certa acesa por 1 batida.
- **Quem está na frente se vê:** a distância na pista (o portão de cada raia mais perto).

**Como o jogador do time confere** (mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7):

1. Robô: pelo menos 4 linhas `momento` `lama` em 100 s, pelo menos 1 antes de 20 s, e 1 linha `momento` `reta`.
2. Prancha: um cavaleiro na caixa de lama em 1 quadro de cada 4.
3. Enquanto o robô por lugar (`--robo=bom,medio,medio,ruim`) não existe, a conferência da mesa padrão é só pela
   prancha, com o temperamento único.

## A ficha do código

`godot/scripts/minigames/s07/os_caminhos.gd`, `extends Minigame`, sem `class_name`. O que sai do `caminhos.gd` de hoje:

| sai | por quê |
| --- | --- |
| `class_name SalaCaminhos`, `_init()`, `const RAIAS`, `Z_JOGADOR`, `_conectado` | o kit tem |
| `PERGUNTA`, `REVELA`, `pergunta()`, `_fechar_pergunta()`, o `objetivo` | a pergunta vira a escolha da trilha |
| o tropeço (`trop_*`, `_fechar_tropeco`, `CAMINHO_NADA_LADO`) e o `robo_lado` | o lado da háptica é da O4 |
| o treino próprio (`TREINO`, `com_treino = false`) | o treino do kit (10 s) ensina |
| o `_process` e o `e.t += dt` | o kit não deixa sobrescrever `_process`; tudo pela batida |

```gdscript
extends Minigame
## Os Caminhos (S07_J31). A senha do seu portão chega só na sua mão, o passo
## de um chão andando da esquerda para a direita; três trilhas sobem à sua
## frente, e ◀ ▲ ▶ no tempo pisa na que tem aquele chão.

const FICHA := { ... }   # a de cima

const FIM_BATIDA := BATIDA_DA_PRIMEIRA_NOTA + 196
const RETA_B := FIM_BATIDA - 16
const CICLO := 8
const CICLO_PICO := 4
const PICO_DE_B := 66.0      ## 33 s
const PICO_ATE_B := 132.0    ## 66 s
const META := 57.0
const CORTESIA := 8.0
const LADRILHO := 1.5
const AVANCO := [0.0, 1.0, 1.25, 1.5]
const DX_TRILHA := [-0.8, 0.0, 0.8]
const DIRECAO := [Forja.ESQUERDA, Forja.CIMA, Forja.DIREITA]
const NOME_CHAO := ["grama", "cascalho", "metal", "água"]
const PECA_CHAO := ["mini-forest/patch-grass", "mini-forest/patch-dirt", "tower-defense-kit/tile", "hexagon-kit/water"]
const RUMBLE_CHAO := ["toque", "golpe_esq", "golpe", "golpe_dir"]
const CAMINHO_NADA := 4  ## «não senti» (cegas.h), só na bancada
const ENV_MAX := 64

var _rng := {}            ## lugar -> RandomNumberGenerator (a semente do kit + 7919 * (l + 1))
var _robo_rng := RandomNumberGenerator.new()   ## a semente do kit + 99: o robô nunca muda o sorteio do jogo
var _k := [0, 0, 0, 0]
var _b0 := [0.0, 0.0, 0.0, 0.0]
var _senha := [0, 0, 0, 0]
var _trilhas := [[], [], [], []]
var _escolheu := [-1, -1, -1, -1]
var _reto := [false, false, false, false]
var _lama := [-1, -1, -1, -1]
var _enlameada := [-1, -1, -1, -1]   ## a bifurcação do líder que chega com lama (o acerto vale metade)
var _motivo := ["", "", "", ""]
var _dist := [0.0, 0.0, 0.0, 0.0]
var _de := [0.0, 0.0, 0.0, 0.0]
var _ate := [0.0, 0.0, 0.0, 0.0]
var _passo_b := [-9.0, -9.0, -9.0, -9.0]
var _passos_dados := [0, 0, 0, 0]
var _chegada: Array = []
var _fim_batida := -1.0
var _reta_anotada := false
var _rumble := [false, false, false, false]
var _chao := {}           ## lugar -> Cega (a bancada)
var _fora := [false, false, false, false]
var _nos := {}            ## lugar -> {trilha, placas, luz}
var _robo_k := [-1, -1, -1, -1]
var _robo_mira_de := [-1, -1, -1, -1]
var _robo_certo := [true, true, true, true]
var _robo_atraso := [0.0, 0.0, 0.0, 0.0]
var _robo_env := [[], [], [], []]
var _robo_gravando := [false, false, false, false]
var _robo_silencio := [0, 0, 0, 0]
var _robo_somas := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _robo_votos := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]


func montar() -> void:
	camera_pos = Vector3(0, 12.6, 8.6)
	camera_olhar = Vector3(0, 0.4, -1.6)
	Kit.arena(self, 5, 3)
	luzes([Vector3(-9, 2.5, -4), Vector3(9, 2.5, -4), Vector3(0, 3.0, 4)])   # a cor e a energia: acender (G15), «A cena»
	for p in jogadores:
		var l: int = p.lugar
		_nos[l] = _montar_raia(l)
		_chao[l] = Cega.nova()
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	_robo_rng.seed = rng.seed + 99
	var ordem := presentes()
	for i in ordem.size():
		var l: int = ordem[i]
		var r := RandomNumberGenerator.new()
		r.seed = rng.seed + 7919 * (l + 1)
		_rng[l] = r
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)
		if _rumble[l]:
			anotar("troca", l, {"de": "haptica", "para": "rumble", "motivo": "sem_placa"})
		_b0[l] = float(BATIDA_DA_PRIMEIRA_NOTA + 2 * i)
		_nova_bifurcacao(l)


func jogar(_dt: float) -> void:
	var b := Ritmo.batida()
	if b >= RETA_B and not _reta_anotada:
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
			while _b0[l] + _ciclo_de(_b0[l]) - 2 < b + 0.5:
				_pular(l)
		_senha_na_mao(l, b)
		var k: int = _k[l]
		var escolha := _b0[l] + _ciclo_de(_b0[l]) - 2
		var alvo := Ritmo.t_da_batida(escolha)
		acender_raia(l, clampf(1.0 - absf(Ritmo.t_musica() - alvo) * 4.0, 0.0, 1.0))
		if _lama[l] == k or _reto[l]:
			if b >= escolha and _passo_b[l] < escolha:
				_andar(l, 0.25 if _lama[l] == k else 0.5, escolha)
		elif _escolheu[l] < 0 and b >= _b0[l] + _ciclo_de(_b0[l]) / 2:
			var d := _direcao(l)
			if d >= 0:
				_escolher(l, d, alvo)
			elif Forja.bancada and Forja.apertou(l, Forja.TOUCHPAD):
				_escolheu[l] = 3
				Cega.errado(_chao[l], CAMINHO_NADA)
				_respondeu(l, k, "nenhuma")
				_motivo[l] = "parou"
				nota_perdida(l, k)
			elif Ritmo.t_musica() > alvo + FOLGA_PERDIDA:
				_escolheu[l] = 3
				Cega.perdido(_chao[l])
				_respondeu(l, k, "nenhuma")
				_motivo[l] = "parou"
				nota_perdida(l, k)
		if b >= _b0[l] + _ciclo_de(_b0[l]):
			_b0[l] += _ciclo_de(_b0[l])
			_k[l] = k + 1
			_nova_bifurcacao(l)
	if _fim_batida > 0.0 and b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	var k: int = _k[l]
	var b_escolha := _b0[l] + _ciclo_de(_b0[l]) - 2
	var ganho: float = 2.0 if b_escolha >= RETA_B else AVANCO[j] * (1.5 if _no_pico(_b0[l]) else 1.0)
	if _enlameada[l] == k:
		ganho *= 0.5
	marcar(l, int(round(100.0 * ganho)))
	_andar(l, ganho, b_escolha)


func falha(l: int) -> void:
	var p := jogador(l)
	if _motivo[l] == "lama":
		_lama[l] = _k[l] + 1
		p.gesto("fall", 0.8)
		Forja.tocar_material(l, "lama", "golpe", 1.0)
		Som.tocar("falha", p.global_position, -4.0)
		anotar("momento", l, {"nome": "lama", "t_musica": Ritmo.t_musica()})
		_espalhar_lama(l, int(_trilhas[l][_escolheu[l]]))
		# a caixa de lama, as 48 partículas, o tremor, o hit-stop e a luz das outras raias: «A diversão»
	else:
		p.gesto("emote-no", 0.6)


func vencedor() -> Array:
	var resto := presentes().filter(func(l): return not l in _chegada)
	resto.sort_custom(func(a, b):
		return _dist[a] > _dist[b] or (_dist[a] == _dist[b] and pontos[a] > pontos[b]))
	return _chegada + resto


func dar_vereditos(l: int) -> Array:
	var tem := Forja.som_tem(l, Forja.PAPEL_HAPTICA)
	var v := Forja.cega_veredito(l, "haptica_audio", {"cega": _chao[l], "esq": Cega.nova(), "dir": Cega.nova(), "tem": tem})
	return [] if v.is_empty() else [v]
```

As funções que faltam, pelo que já foi dito:

- `_ciclo_de(b0)`: `CICLO_PICO` se `_no_pico(b0)`, senão `CICLO`. `_no_pico(b0)`: `b0 >= PICO_DE_B and b0 < PICO_ATE_B`.
- `_nova_bifurcacao(l)`: sorteia a senha e os outros dois chãos com `_rng[l]`, põe a certa numa das três posições,
  `_escolheu[l] = -1`, `_passos_dados[l] = 0`, `_reto[l] = Ritmo.simples[l] and k % 2 == 1 and not _no_pico(_b0[l])`, zera
  `_robo_votos[l]`, e `nova_nota(l, k, Ritmo.t_da_batida(escolha))` se não for reta nem lama.
- `_pular(l)`: avança `_b0` e `_k` sem nota.
- `_senha_na_mao(l, b)`: os passos em `b0` (esquerdo) e `b0 + 2` (direito), no pico só `b0` (os dois), adiantados pelo
  Faro e pela Lanterna, pelo `_pista`, uma vez cada (`_passos_dados`).
- `_direcao(l)`: a primeira de `DIRECAO` com `Forja.apertou`.
- `_escolher(l, d, alvo)`: `_escolheu[l] = d`; certo: `Cega.certo(_chao[l])`, `_respondeu(l, k, "certo")`,
  `_motivo[l] = "parou"`, `julgar_toque(l, alvo, k, true)`; errado: `Cega.errado(_chao[l], chao)`,
  `_respondeu(l, k, "errado")`, `_motivo[l] = "lama"`, `nota_perdida(l, k)`.
- `_andar(l, ganho, b_de)`: `_de = _dist`, `_dist += ganho`, `_ate = _dist`, `_passo_b = b_de`; se `_dist >= META` e
  `not l in _chegada`: `_chegada.append(l)`, `acabou[l] = true`, `p.gesto("emote-yes", 1.2)`, o portão e a coleta; na
  primeira chegada, `_fim_batida = b + CORTESIA`.
- `_espalhar_lama(l, c)`: o líder `d` (maior `_dist`, `d != l`); se a senha da bifurcação seguinte dele é `c`,
  `_enlameada[d] = _k[d] + 1` e a placa certa dele aparece com a caixa de lama de 0,2 m de altura.
- `_ordem_por_distancia()`: `presentes()` pelo `_dist`, do maior ao menor.
- `_montar_raia(l)` e `_mostrar(b)`: a cena de cima.

A dica (`dica(l)`, com a guarda `if not na_raia(l): return {}`): na escolha, `{"partes": ["@dpad_left", "@dpad_up",
"@dpad_right"], "pos": Vector3(RAIAS[l], 0, 4.6)}` enquanto `not aprendeu(l)`. O `status(l)`: `"%d de %d" %
[floor(_dist[l]), META]`, ou `"Chegou"`. Nenhuma frase fala de chão, de háptica ou de controle.

`godot/scripts/traducoes.gd`: `"Os Caminhos": "The Paths"`, `"Sinta e pise!": "Feel and step!"`, `"Sinta!": "Feel!"`,
`"Chegou": "Made it"`. Tire `"Que chão é esse?"`, `"treino: sinta %s"` e `"tropeçou!"` se `grep -rn` não achar outro uso.

## O robô

Ele **sente** a senha na placa virtual: um defeito de mentira que corta a háptica faz o robô errar, e o
`scripts/gauntlet.sh` vê o veredito cair.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	_robo_sentir(l)
	var k: int = _k[l]
	if _lama[l] == k or _reto[l] or _escolheu[l] >= 0 or _robo_k[l] == k:
		return
	var b := Ritmo.batida()
	if b < _b0[l] + _ciclo_de(_b0[l]) / 2:
		return
	if _robo_mira_de[l] != k:
		_robo_mira_de[l] = k
		_robo_certo[l] = Forja.robo_acerta()
		_robo_atraso[l] = 0.0 if _robo_certo[l] or _robo_rng.randf() < 0.5 else 0.25
	var alvo := Ritmo.t_da_batida(_b0[l] + _ciclo_de(_b0[l]) - 2)
	if Ritmo.t_musica() < alvo + float(_robo_atraso[l]):
		return
	var sentido := _mais_votado(l)   # o chão que a mão sentiu, ou -1
	var d := -1
	if sentido >= 0:
		d = (_trilhas[l] as Array).find(sentido)
	if d < 0:
		if Forja.bancada:
			Forja.robo_apertar(l, Forja.TOUCHPAD, 0.08)   # «não senti»
			_robo_k[l] = k
			return
		d = _robo_rng.randi_range(0, 2)
	if not _robo_certo[l] and float(_robo_atraso[l]) == 0.0:
		d = (d + 1 + _robo_rng.randi_range(0, 1)) % 3   # erra a trilha
	Forja.robo_apertar(l, DIRECAO[d], 0.08)
	_robo_k[l] = k


# O envelope de cada passo na placa virtual vota num chão. A senha anda de um
# atuador para o outro, então o ramo «um lado só» de hoje sai: todo passo vota.
func _robo_sentir(l: int) -> void:
	var v := Forja.som_virtual(l)
	var esq := float(v.get("esq", 0.0))
	var dir := float(v.get("dir", 0.0))
	var nivel := maxf(esq, dir)
	var env: Array = _robo_env[l]
	if not _robo_gravando[l] and nivel > 0.05:
		_robo_gravando[l] = true
		env.clear()
		env.append(0.0)
		env.append(0.0)
		_robo_somas[l] = Vector2.ZERO
		_robo_silencio[l] = 0
	if not _robo_gravando[l]:
		return
	if env.size() < ENV_MAX:
		env.append(nivel)
	_robo_somas[l] += Vector2(esq, dir)
	_robo_silencio[l] = int(_robo_silencio[l]) + 1 if nivel < 0.02 else 0
	# 0,2 s de silêncio fecham o passo: a água tem um vão de 0,1 s entre as duas ondas
	if int(_robo_silencio[l]) < 12 and env.size() < ENV_MAX:
		return
	_robo_gravando[l] = false
	if (_robo_somas[l] as Vector2).length() <= 0.0:
		return
	var c := Forja.chao_do_envelope(PackedFloat32Array(env))
	if c >= 0 and c < 4:
		_robo_votos[l][c] = int(_robo_votos[l][c]) + 1


func _mais_votado(l: int) -> int:
	var votos: Array = _robo_votos[l]
	var m := -1
	for c in 4:
		if int(votos[c]) > 0 and (m < 0 or int(votos[c]) > int(votos[m])):
			m = c
	return m
```

## A falha

- **«lama»** (trilha errada): o grito da seção, em «A diversão». A recuperação: a bifurcação seguinte se perde
  (`_lama[l] = k + 1`), com o tempo de queda do `levantar`.
- **«parou»** (atrasou, adiantou demais ou não escolheu): `emote-no` (0,6 s) diante das placas; não avança; a próxima
  bifurcação vem normal.

## O fim e o vencedor

Quem passa do `META` chega. Na primeira chegada, os outros correm mais `CORTESIA` = 8 batidas (dois compassos), e todos
acabam. Sem chegada, o kit fecha aos 100 s de música. `vencedor()`: a ordem de `_chegada`, depois os outros pela
distância, e pelos pontos no empate.

## Com menos de quatro

- **3, 2, 1:** a regra não muda; o hoqueto espalha as escolhas pelas posições em `presentes()` (com dois, batidas 2 e 4
  de cada ciclo). Com um, ele corre contra o portão e vence ao chegar, ou ao fim, pela distância.
- **O controle que cai:** a nota de quem está sem controle não vira erro (`_fora[l] = true`). Quando volta, as
  bifurcações já começadas são puladas sem registro, e a próxima vem normal.
- **Duplas:** não há.

## O que o registro mede

- `pista` `mandou` de cada senha (`o_que` = o chão, `canal`), e a `entrada` `resposta` (`certo`, `errado`, `nenhuma`);
- `troca` quando o lugar não tem placa;
- `som_controle` de cada passo (H07, com `placa`), `nota` e `toque` (o kit);
- `momento` `lama` e `reta`;
- o veredito `haptica_audio` (a bancada), calculado nos dois modos.

## Armadilhas

- **O robô sorteia no dele** (`_robo_rng`, semente do kit + 99): com robô ou com gente, o mesmo jogo.
- **A cauda do metal.** O passo de metal soa por 0,55 s; os dois passos ficam a 2 batidas (1 s) para o envelope fechar
  entre eles (0,2 s de silêncio). Não aproxime.
- **O acerto do kit também toca na háptica** (`material:pedra`, 60 ms, na escolha), 2 batidas antes da próxima senha:
  os votos zeram em `_nova_bifurcacao`, depois dele.
- **A placa virtual e o relógio.** Com `--fixed-fps 60` o jogo anda cerca de 16 vezes mais depressa que a música. Meça
  o tamanho do envelope por passo numa rodada da prova; se passar de `ENV_MAX`, feche o envelope por 0,2 s de
  `Ritmo.t_musica()` em vez de 12 quadros, e anote aqui o que mediu.
- **A prova fica mais longa:** a corrida inteira roda (até 100 s de relógio). Se o `timeout 1200` de
  `tests/prova_do_jogo.sh` apertar, anote e avise; não encurte a corrida.
- **Não chame `errou()`** nem `Forja.vibrar`: o Escudo e as sensações são do kit.
- **`--sala=caminhos`** continua abrindo, pelo apelido, o `S07_J31`.

## Pronto quando

`--sala=caminhos` abre Os Caminhos no kit e joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos; aguenta o cabo que cai; fecha com vencedor; nenhuma pergunta aparece fora da bancada; com `--bancada` o
`haptica_audio` sai PASSOU com o robô bom e cai com o defeito de mentira da háptica; a senha anda (esquerda em `b0`,
direita em `b0 + 2`); `salas/caminhos.gd` saiu; a mesa padrão grava pelo menos 4 `momento` `lama`; e as provas abaixo
passam com a prancha olhada.

## Provas

`_prova_os_caminhos()` em `godot/testes/prova_do_jogo.gd`, chamada pelo `match` de `_prova_da_ficha(slot)`:
`"S07_J31": await _prova_os_caminhos()`. Não entra no percurso.

```gdscript
## S07_J31: a senha anda na mão (esquerda, depois direita), o robô escolhe
## trilhas, nenhuma pergunta fora da bancada, e o haptica_audio sai das trilhas.
func _prova_os_caminhos() -> void:
	var esq_so := [false, false, false, false]
	var dir_so := [false, false, false, false]
	var vazou := [0]
	var olhar := func(mg: Minigame) -> void:
		var b := Ritmo.batida()
		for l in mg.presentes():
			if mg._no_pico(mg._b0[l]) or mg._reto[l] or mg._lama[l] == mg._k[l]:
				continue
			var v := Forja.som_virtual(l)
			var e := float(v.get("esq", 0.0))
			var d := float(v.get("dir", 0.0))
			var b0: float = mg._b0[l]
			if b >= b0 and b < b0 + 0.3 and e > 0.05:
				esq_so[l] = true
				if d >= 0.02:
					vazou[0] += 1
			if b >= b0 + 2.0 and b < b0 + 2.3 and d > 0.05:
				dir_so[l] = true
				if e >= 0.02:
					vazou[0] += 1
	var mg := await _joga_o_minigame("S07_J31", 140.0, olhar)
	if mg == null:
		return
	_esperar(esq_so.all(func(s): return s), "S07_J31: o 1º passo chegou só à esquerda dos quatro %s" % [esq_so])
	_esperar(dir_so.all(func(s): return s), "S07_J31: o 2º passo chegou só à direita dos quatro %s" % [dir_so])
	_esperar(vazou[0] == 0, "S07_J31: nenhum passo vazou para o outro atuador (%d)" % vazou[0])
	_confere_os_vereditos(mg, ["haptica_audio"])
```

No `_prova_do_relatorio()`, no laço da linha do tempo: as `pista` com `slot == "S07_J31"` e `evento == "mandou"` são
≥ 8 e todas `canal == "haptica"`; as `entrada` `resposta` com `resposta == "certo"` são ≥ 4; há ≥ 1 `momento` `lama` e
1 `momento` `reta`; não há `troca` desse slot.

Os comandos:

1. `SALA=S07_J31 bash tests/prova_do_jogo.sh`
2. `bash tests/prova_visual.sh`, e olhar a prancha `SAIDA/prancha-<n>.png` (480 × 270 a cada 2 s, 6 colunas) nas
   partidas com quatro (`bom` e `ruim`), com dois (`medio`), com um e com o cabo que cai. O que se olha: as três placas
   com chãos diferentes, o cavaleiro andando, a caixa de lama em 1 quadro de cada 4, as peças do cavaleiro com as tintas
   da montagem em todo quadro, e o portão.
3. Na máquina do André: `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`; `./run-local.sh -- --sala=caminhos`
   com um controle no cabo e um no rádio. No cabo, o passo tem de atravessar a palma da esquerda para a direita, e cada
   chão tem de ser outro na mão.

## Ao terminar

- No [quadro](README.md), a linha O1: **feito**, com o commit.
- Commit sugerido: `feat(caminhos): Os Caminhos no kit, a senha anda na mão e escolhe a trilha`
