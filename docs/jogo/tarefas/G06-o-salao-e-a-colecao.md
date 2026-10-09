# G06 — O salão e a coleção

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F09 (a prova visual), G02 (`ACABAMENTOS`, `Opcoes.noite()`), G04 (a etiqueta do salão, `Desenho.contador`, `retangulos()`), G05 (a lente de 35 mm), G08 (o `cavaleiro.gdshader`, o acento), G11 (`Desenho.chip`, `dica`, `etiqueta`), G12 (`partida.lado()`), G14 (os tokens e as fontes), G15 (`Tema.neon`, o brilho com dono) · **Usado por:** G07 (a noite que o fim da fita conta), G16 (o lado B no salão)

## Por quê

O salão não conta a noite. As placas dos portões dizem «Seção 1» numa letra
de app, nada acende quando uma seção é vencida e o grupo não guarda nada do
que conquistou. A volta ao salão depois de uma faixa tem de dar gosto: o
portão vencido acende, o contador sobe, a taça na cor de quem venceu aparece
na vitrine. É o salão do quadro `docs/imagens/direcao/02_salao.jpg`.

## Ler antes

- [sistemas — a progressão e a coleção](../sistemas/README.md#a-progressão-e-a-coleção) (nada que muda stat se ganha jogando; os acabamentos e os troféus)
- [06 — os objetos e a etiqueta](../arte/06-interface-e-texto.md#os-objetos) (o chip, a dica de botão, a etiqueta com a tarja e a inclinação)
- [07 — o que conta como brilho](../arte/07-vfx.md#o-que-conta-como-brilho) (o dono de cada brilho e o teto)

Os números do 01 (o plano do salão) e do 03 (os sons do salão) estão
copiados em A cena e em O som.

## Arquivos que mudam

| arquivo | também muda em |
| --- | --- |
| `godot/scripts/colecao.gd` e `.uid` (novo, `class_name Colecao`) | — |
| `godot/scripts/mundo/salao.gd` (a etiqueta do portão, a vitrine, `mostrar_colecao`) | **G01**, **G05**, **G08** (A8), **G10** (o caminho), **G14**, **G15** (a luz e o brilho) |
| `godot/scripts/main.gd` (`_quadro_salao`, `_perto_da_bigorna`, `_ao_terminar_a_sala`, `_ir_para_o_salao`, a pose do salão) | **G01, G02, G03, G04, G05, G07, G08** |
| `godot/scripts/ui/hud.gd` (o salão: o contador, os chips, a dica presa) | **G04**, **G11**, **G14** |
| `godot/scripts/ui/desenho.gd` (`chip` ganha `palavra`) | **G04, G11, G12, G13, G14, G16** |
| `godot/scripts/player.gd` (Cromado e Néon, `acabamentos_disponiveis`) | **G02**, **G03**, **G08**, **G13** |
| `godot/scripts/musica.gd` (`jingle`) | **H05** |
| `godot/scripts/forja.gd` (`Colecao.carregar`) | **G04**, **G14** |
| `godot/scripts/traducoes.gd` | **G04, G07, G09, G11, G16** |
| `godot/assets/sons/` (3 WAV) e `docs/jogo/audio/mapa.csv` | **G01, G03, G04, G07, G11, G12, G16** |
| `docs/jogo/13-arquitetura.md` (a coleção, o registro) | **H04** |
| `godot/testes/prova_do_jogo.gd` | **todas as G** |

## Como se joga

A coleção é da noite (`Opcoes.noite()`): outra noite começa vazia. Ela conta
três coisas e nenhuma muda stat.

| conquista | quando | o que dá |
| --- | --- | --- |
| a vitória | o primeiro a vencer um minigame na noite (o de mais pontos entre os `presentes`, com pontos > 0; empate em cima: o menor lugar) | uma taça na cor dele, na vitrine |
| o recorde | vencer de novo um minigame já vencido, com mais pontos que o recorde da noite | uma moeda de pé na vitrine, o aviso e o `jin_recorde` |
| o coop sem erro | um coop vencido sem nenhum erro | quatro cubos, um em cada cor |

Uma seção acende quando todos os minigames dela foram vencidos na noite. Os
desbloqueios, cada um uma vez por noite:

| acabamento | desbloqueia com |
| --- | --- |
| Dourado | o primeiro troféu da noite |
| Cromado | três seções acesas |
| Néon | um troféu de coop |

O acabamento desbloqueado aparece na construção (G02, a linha Acabamento) e
não muda stat (sistemas, o mantra).

## A cena

### A câmera do salão (01: 35 mm, alto, 3/4, deriva de 2 % em 16 compassos)

A pose de hoje (`main.gd:940-957`), com a lente de 35 mm da G05 e o recuo
dela (×1,0616): `dist = clampf(12.2 + abertura * 0.53, 12.2, 19.1)`. A
deriva: um pan lateral de 2 % da distância, ida em 16 compassos e volta em 16,
`ENTRA_SAI`:

```gdscript
## A deriva do salão (01): 0..1..0 em 32 compassos, curva seno (ENTRA_SAI).
func _deriva_do_salao() -> float:
	var bpm := Ritmo.bpm if Ritmo.bpm > 0.0 else 110.0
	var f := fmod(_t * bpm / 60.0 / 64.0, 2.0)
	var k := f if f < 1.0 else 2.0 - f
	return (1.0 - cos(PI * k)) * 0.5
```

`c.x += dist * 0.02 * (_deriva_do_salao() - 0.5)`, na posição e no olhar
(o salão olha para −z; o eixo lateral é o x). A 110 BPM, 16 compassos são
34,9 s. Com o movimento reduzido (`not Opcoes.tremor` até a G16;
`Opcoes.movimento == 1` depois), sem deriva.

### A etiqueta do portão (o quadro 02)

No lugar do nome em Archivo, do ícone e do «Seção N» de hoje, a placa
(`portoes[id].placa`, mesma posição e rotação) vira a etiqueta do cassete,
em 3D. `n = Musica.SALA_DA_SECAO.find(id)`; `tinta = Tema.tinta_da_secao(n)`.

| peça | medida (m) | posição na placa | material |
| --- | --- | --- | --- |
| o papel | caixa 2,9 × 0,95 × 0,04 | (0, 0, 0) | acesa: `ETIQUETA`; apagada: `ETIQUETA_SOMBRA`; fosco, rugoso 0,9, sem sombra projetada |
| a tarja | caixa 2,9 × 0,10 × 0,05 | (0, 0,33, 0,01) | `tinta` (acesa) ou `tinta.darkened(0.15)` (apagada); no lado B, duas caixas de 0,058 com 0,033 de vão (os 7 + 4 + 7 px do 06, na mesma razão) |
| o nome | `Label3D`, Permanent Marker (`Tema.marcador()`), `font_size` 88, `pixel_size` 0,0042, `TINTA`, alinhado à esquerda | (−1,3, −0,03, 0,03) | `shaded = true`, sem contorno |
| a linha impressa | `Label3D`, VT323 (`Tema.vt()`), `font_size` 72, `pixel_size` 0,0036, `TINTA_SUAVE` | (−1,3, −0,32, 0,03) | `"S%d · %d FAIXA" % [n, total]` com 1, `"S%d · %d FAIXAS"` com mais; portão fechado: `"S%d · EM BREVE"` |
| as marcas | uma caixa 0,12 × 0,12 × 0,01 por minigame da seção, a cada 0,18, da direita para a esquerda a partir de x 1,25 | (1,25 − 0,18·i, −0,32, 0,03) | vencido: `TINTA`; a vencer: `ETIQUETA_SOMBRA` sobre o papel aceso, `TINTA_SUAVE` sobre o apagado |

**O portão aceso** (`Colecao.secao_acesa(id)`): um `SpotLight3D` em
`TUNGSTENIO` acima da soleira (posição `pos + frente * 5.0 + (0, 6.5, 0)`,
olhando para `pos + frente * 0.6 + (0, 1.4, 0)`), energia 3,2, alcance 24,
ângulo 12°; apagado, energia 0,55 (o quadro). E o tubo em cima do papel:
caixa 3,1 × 0,06 × 0,06 em (0, 0,57, 0,01), `Tema.neon(Tema.TUNGSTENIO, 1.3, "forja")`
(o dono é a forja: teto 2,4). Apagado, o tubo não existe. As tintas não
brilham (07): o papel e a tarja são foscos.

### A vitrine (parede leste, entre os dois portões)

- Sai `peca("stones", Vector3(10.4, 0, -1.0), …)` de `_enfeites()` (`salao.gd:408`).
- `vitrine_no := Node3D` em `Vector3(10.6, 0, 0.0)`, `rotation.y = -PI * 0.5`.
- A madeira: `Kit.material(Tema.OXIDO, 0.0, 0.9)`. Dois lados
  `Kit.caixa(vitrine_no, Vector3(0.08, 1.9, 0.5), Vector3(±1.25, 0.95, 0), madeira)`;
  três prateleiras `Kit.caixa(vitrine_no, Vector3(2.5, 0.08, 0.5), Vector3(0, y, 0), madeira)`
  com `y` em 0,6, 1,2 e 1,8. Os portões leste estão em z ±3 (abertura de 2 m):
  a vitrine vai de z −1,25 a +1,25 e sobra 0,75 m de cada lado.
- `trofeus_no` filho de `vitrine_no`; o troféu `i` (até 18) em
  `Vector3(-1.0 + (i % 6) * 0.4, 0.64 + floor(i / 6) * 0.6, 0)`. Do 19º em
  diante, a vitrine mostra os 18 últimos.

Os troféus: foscos, `metallic` 0, nenhum brilha. A cor de jogador só no
troféu de quem ganhou, por variável de lugar (portão 3).

| tipo | peça |
| --- | --- |
| vitória | taça: base `Kit.caixa(t, Vector3(0.16, 0.04, 0.16), Vector3(0, 0.02, 0), m)`, haste `Kit.cilindro(t, 0.03, 0.10, Vector3(0, 0.09, 0), m)`, copo `Kit.cilindro(t, 0.06, 0.14, Vector3(0, 0.21, 0), m, 0.09)`; `m = Kit.material(Tema.JOGADOR[lugar], 0.0, 0.6)` |
| recorde | `Kit.peca(t, "coin", Vector3(0, 0.12, 0), 0.0, 0.8)` de pé (`rotation.x = PI * 0.5`) sobre uma base `Kit.caixa(t, Vector3(0.16, 0.04, 0.16), Vector3(0, 0.02, 0), madeira)` |
| coop | quatro cubos de 0,07 lado a lado (x de −0,105 a +0,105, a cada 0,07), `for k in 4: Kit.material(Tema.JOGADOR[k], 0.0, 0.6)` |

### O HUD do salão (o quadro 02)

A etiqueta «O Salão» é da G04 (em (96, 60), 520 × 150). Esta ficha põe o
resto; tudo entra em `hud.retangulos()`:

| o quê | onde | como |
| --- | --- | --- |
| o contador | o canto direito em x `w − 96`, topo em y 60: 121 × 73 px (3 rodas de VT323 64) | `Desenho.contador(ci, Vector2(w - 96 - 121, 60), "%d/9" % vencidas, 64)`; `vencidas` = as seções acesas entre as 9 (os 8 portões e A Prova) |
| «Salas vencidas» | alinhado à direita em x `w − 96 − 121 − 20`, linha de base y 108 | Archivo 500 32, `ETIQUETA` |
| a dica presa ao cavaleiro | ver abaixo | `Desenho.etiqueta` na cor do dono com `Desenho.dica(..., true)` |
| os chips | uma fileira de 4 × 400 × 64, vão de 16, centrada (x 136 em 1920), y `h − 60 − 64` | `Desenho.chip(ci, r, l, pronto, palavra)`: só dos lugares ocupados |

**Os chips:** o `Desenho.chip` da G11 ganha `palavra := ""` no fim (vazio:
«Pronto» ou «Treinando», como hoje; os outros chamadores não mudam). No
salão: com controle, `pronto = true` e `palavra` = o nome do cavaleiro
(`ForjaPlayer.nome`, `Desenho.caber` até 400 − 18 − 80 px); sem controle,
`pronto = false` e «Sem controle». Assim a primeira coisa que cada um vê no
salão é o próprio nome na própria cor.

**A dica presa** (a placa do portão da G04 sai): quando um cavaleiro visível
está perto de um portão (`salao.portao_perto`) ou da bigorna (3,1 m), uma
placa presa à cabeça dele: `c = cam.unproject_position(p.global_position + Vector3(0, 1.9, 0))`.

| peça | medida |
| --- | --- |
| o papel | `Desenho.etiqueta(ci, r, Tema.JOGADOR[l])` (G11: papel `ETIQUETA`, a tarja de 12 px a 14 px do topo na cor do dono, a mesma etiqueta da fala da G04); altura = 34 + 62 × linhas + 10 (a faixa da tarja, e 52 de glifo mais 10 por linha); largura = 24 + a largura da `dica` mais longa + 24 |
| onde | canto de cima à esquerda em `c + (60, −60)`; se passa de `w − 96`, vai para `c + (−60 − largura, −60)`; y nunca menos que 60 |
| a ponta | triângulo de 16 px em `ETIQUETA` no lado do cavaleiro, entre 40 e 72 px do topo |
| as linhas, no portão aberto | `dica("cruz", "Tocar a faixa")` |
| no portão fechado | `dica("cruz", "Em breve")`, a tarja em `ETIQUETA_SOMBRA` no lugar da cor do dono |
| na bigorna | três linhas, a cada 62 px: `dica("cruz", "Tocar A Prova")`, `dica("quadrado", "Partida")`, `dica("triangulo", "Prova de Fogo")` |

O nome do portão já está na etiqueta 3D: a dica só diz o verbo.

## O som

O encanamento, igual nas fichas G01, G03, G04, G09, G11, G12 e G16 (se outra
ficha já fez, usar o dela): copiar `<id>.wav` de `godot/estudos/direcao/som/`
para `godot/assets/sons/<id>.wav`; `"$GODOT" --headless --path godot --import --quit`
e conferir `compress/mode=0` no `.import`; `Som.tocar`, `Som.no_controle` e
`Som.laco` tocam primeiro `res://assets/sons/<nome>.wav` quando ele existe
(no `laco`, com `loop_mode = AudioStreamWAV.LOOP_FORWARD` do primeiro ao
último quadro). A linha do mapa ganha `arquivo` = `godot/assets/sons/<id>.wav`
e `estado` = `no jogo`.

| quando | id | onde | volume |
| --- | --- | --- | --- |
| o salão aparece | `amb_salao` (8 s em laço: o fogo, o chiado a −62 dBFS, uma brasa a cada 1,7 s) | TV, `Som.laco("amb_salao", salao, salao.bigorna.position, 0.0)`, criado uma vez no `_ready` do salão; `stream_paused = estado != "salao"` | o arquivo já está a −18 dBFS (o Ambiente) |
| ✕ num portão aberto ou na bigorna | `ui_confirma` (90 ms) | TV e o alto-falante de quem apertou | −12 dB na TV; ganho 0,85 no controle |
| ✕ num portão fechado | `ui_volta` (90 ms) | o mesmo | o mesmo |
| um recorde da noite | `jin_recorde` (140 BPM, Sol maior; 10 s gerados, corte em 3 s no fim do compasso) | TV, `Musica.jingle("JIN_RECORDE")` | `Musica.VOLUME_DB` |

- `Musica.jingle(slot)`, novo: se `ResourceLoader.exists(Musica.caminho(slot))`,
  um `AudioStreamPlayer` filho da `Musica`, no mesmo bus das faixas, toca o
  OGG uma vez e se apaga no `finished`; sem o OGG (a H05 o gera), nada.
- O `mus_salao` (110 BPM, Dó menor) já sai por `Musica.tocar("salao")`
  quando a H05 o gerar. Os `passo_*` e o `sint_fogo` já estão no jogo. O
  `portao` de hoje (o portão que abre perto, −8 dB) fica.
- Copiar 3 arquivos: `amb_salao.wav`, `ui_confirma.wav`, `ui_volta.wav`.

## O controle

| evento | para quem | vibração (forte/fraco/ms) | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- | --- |
| ✕ num portão aberto ou na bigorna | quem apertou | toque 0/0,45/60 | não muda | não muda | `ui_confirma` | não se usa |
| ✕ num portão fechado | quem apertou | toque 0/0,45/60 (no lugar do 0,2/0/60 de hoje) | não muda | não muda | `ui_volta` | não se usa |
| um recorde | quem fez | acerto 0,3/0,6/80 | não muda | não muda | nada | não se usa |
| o resto do salão | ninguém | nada | nada | nada | nada | não se usa |

Sem o controle na mão: `_perc(l)` traz `forte` e `fraco`;
`Forja.som_virtual(l).falante` mede o alto-falante (Provas).

## O cavaleiro

- **Os stats:** nada daqui muda stat. O Cromado e o Néon são aparência.
- **Os acabamentos novos** em `ForjaPlayer.ACABAMENTOS` (G02), depois do
  Dourado:

```gdscript
	{"nome": "Cromado", "rugoso": 0.25, "metal": 0.2, "claro": 0.0, "livre": false},
	{"nome": "Néon", "rugoso": 0.6, "metal": 0.0, "claro": 0.0, "acento": 2.4, "livre": false},
```

  `metal` nunca passa de 0,2 (11). `"acento"`: a energia de repouso do
  acento da peça (G08: 1,6), dono o lugar, teto 3,0; o encaixe continua
  subindo 1,0 acima dela (a 3,0 no Néon, no teto). Depois da G08, o
  `_aplicar_acabamento` escreve em cada material de `_mats_corpo`
  `set_shader_parameter("rugoso_cima", a.rugoso)`,
  `("rugoso_baixo", a.rugoso)` e `("metal", a.metal)`: os uniforms do
  `cavaleiro.gdshader` da G08 (A2). Esta ficha não cria uniform.
- `acabamentos_disponiveis()` passa a incluir os de `"livre": false` com
  `Colecao.desbloqueado(nome)`.
- **A raça** (G08) não entra na coleção: as quatro estão livres desde o
  primeiro minuto.

## As reações

Não se aplica: o salão não tem carimbo nem adesivo. O recorde é aviso e
jingle; a G16 faz as reações fora do jogo.

## A diversão

**O momento:** os quatro voltam d'A Centelha; o portão dela, que estava a
0,55 de luz, agora está a 3,2 com o tubo de tungstênio aceso; o contador vai a
«1/9»; na vitrine, uma taça na cor do P2. O P2 anda até ela. **Como se
confere:**

1. A prova: depois da partida, `salao.portao_aceso("centelha")`,
   `hud.vencidas == 1`, `salao.trofeus_na_vitrine() == mini(Colecao.trofeus.size(), 18)`
   e a cor da taça é `Tema.JOGADOR` do vencedor.
2. A prova: o P1 perto de um portão tem a dica presa dentro da tela, e o ✕
   toca `ui_confirma` no alto-falante dele.
3. A prancha do salão (F09), ao lado de `02_salao.jpg`: o portão aceso se vê
   de longe, os chips com os nomes embaixo.

## O estado de hoje

- `godot/scripts/mundo/salao.gd:15-24`, `PORTOES`: 8 portões (`centelha`,
  `viga`, `molde`, `impacto`, `galeria`, `voz`, `caminhos`, `canto`), com
  `"nome"`, `"sobre"` («Seção 1» a «Seção 8»), `"icone"`, `"lado"`, `"t"`,
  `"aberta"` (todos `true`).
- `salao.gd:143-211`, `_portao(p)`: a moldura, o portão animado, a placa em
  `pos + frente * 1.15 + (0, 2.75, 0)` com o nome (`Label3D` Archivo 700 de
  96, contorno 18), o ícone (`Sprite3D`) e o `sobre` (`Label3D` 64 em
  y −0,3), as duas tochas (`_tocha`, 213-249); guarda tudo em `portoes[p.id]`.
- `salao.gd:395-416`, `_enfeites()`: as pedras em `(10.4, 0, -1.0)` na
  parede leste (linha 408). Não há vitrine.
- `godot/scripts/main.gd:651-685`, `_quadro_salao()`: perto de um portão,
  `hud.placa = {"nome", "sobre", "aberta"}` (676); ✕ num fechado vibra
  0,2/0/60 (685). `_perto_da_bigorna()` (689-710): a placa «A Prova» com
  «Seção 9 · □ a partida · △ a Prova de Fogo».
- `main.gd:343-376`, `_ao_terminar_a_sala()`: depois das guardas, com
  partida, `_placar_da_sala(sj)` (400-413); nada guarda a vitória fora da
  partida.
- `main.gd:940-957`: a pose do salão (distância 11,5 a 18, a 40°), sem
  deriva. `main.gd:217`: `Musica.tocar("salao")`.
- `godot/scripts/player.gd` e `opcoes.gd`: ainda sem `ACABAMENTOS` nem
  `noite()` (a G02 os traz).
- Cada seção tem hoje **um** minigame. O catálogo das seções
  (`godot/scripts/minigames/catalogo.gd`, H04) ainda não existe.
- `amb_salao`, `ui_confirma` e `ui_volta` estão no estudo e no mapa com
  `estado` = `gerado`; `jin_recorde` e `mus_salao` estão `a fazer` (H05).

## O alvo

### A coleção (`godot/scripts/colecao.gd`, `class_name Colecao extends RefCounted`, estática)

```gdscript
const ARQUIVO := "user://colecao.cfg"
## Os acabamentos que a coleção desbloqueia, e o que desbloqueia cada um.
const DESBLOQUEIOS := {
	"Dourado": "o primeiro troféu da noite",
	"Cromado": "três seções acesas",
	"Néon": "um coop sem erro",
}
const SECOES := 9                    ## os 8 portões e A Prova
static var noite := ""              ## Opcoes.noite() da coleção carregada
static var vencidos := {}           ## id do minigame -> lugar que venceu primeiro na noite
static var recordes := {}           ## id do minigame -> os pontos mais altos da noite
static var trofeus: Array = []      ## [{"id", "lugar", "tipo": "vitoria" | "recorde" | "coop"}]
static var desbloqueados: Array = []  ## os nomes de DESBLOQUEIOS já ganhos na noite
static var _robo := false

static func carregar(robo: bool) -> void       ## lê a seção da noite de hoje; outra noite começa vazia
static func guardar() -> void                   ## grava (nada com o robô)
static func zerar() -> void                     ## a coleção vazia (a prova usa)
## Um minigame acabou: devolve {"desbloqueou": [nomes], "recorde": lugar ou -1}.
static func registrar(id: String, pontos: Array, presentes: Array, coop := false, sem_erro := false) -> Dictionary
static func minigames_da_secao(id_do_portao: String) -> Array
static func secao_acesa(id_do_portao: String) -> bool
static func secoes_acesas() -> int             ## de 0 a SECOES: os 8 portões e "prova"
static func marcas(id_do_portao: String) -> Array   ## [bool] por minigame da seção: vencido na noite?
static func desbloqueado(nome: String) -> bool
```

As regras de `registrar(id, pontos, presentes, coop, sem_erro)`:

1. O vencedor: entre os `presentes`, o de mais pontos, se for **> 0**; empate
   em cima: o de menor lugar.
2. **Vitória:** com vencedor e `id` fora de `vencidos`: `vencidos[id] = lugar`
   e o troféu `{"id": id, "lugar": lugar, "tipo": "vitoria"}`.
3. **Recorde** (só com vencedor): se `recordes.has(id)` e `maior > recordes[id]`,
   o troféu `"recorde"` para quem fez, e `"recorde": lugar` na volta; depois,
   `recordes[id] = maxi(recordes.get(id, 0), maior)`. Uma rodada de zeros não
   vira base de recorde.
4. **Coop sem erro:** `coop and sem_erro`: o troféu `"coop"` com `lugar = -1`.
5. **Desbloqueios**, na ordem, cada um uma vez: Dourado com
   `trofeus.size() >= 1`; Cromado com `secoes_acesas() >= 3`; Néon com um
   troféu `"coop"`.
6. `Forja.evento("colecao", 0, {"id": id, "trofeus": [os tipos novos], "desbloqueou": [...]})`,
   `Forja.registrar(...)` com o mesmo, e `guardar()`.

`minigames_da_secao(id)`: com `catalogo.gd` (H04), os `"minigames"` da seção
cujo primeiro minigame é o apelido `id`; **hoje**, `[id]` (escrever
`return [id]` com o comentário do que a H04 troca). `secao_acesa`: todos os
de `minigames_da_secao` em `vencidos`.

`carregar(robo)` em `godot/scripts/forja.gd`, logo depois de
`Opcoes.carregar(robo)` (linha 125); no cfg, uma seção por noite
(`[2026-10-09]`) com `vencidos`, `recordes`, `trofeus`, `desbloqueados`.

### O salão (`salao.gd`)

```gdscript
var vitrine_no: Node3D
var trofeus_no: Node3D
var _amb: AudioStreamPlayer3D
## Acende etiquetas, marcas e tubos pela Colecao, refaz a vitrine; `lado_b` põe a tarja dupla.
func mostrar_colecao(lado_b := false) -> void
func portao_aceso(id: String) -> bool       ## a prova lê
func trofeus_na_vitrine() -> int
func cor_do_trofeu(i: int) -> Color         ## a prova lê: o albedo do copo da taça i
```

`PORTOES` perde `"sobre"` e `"icone"`. `portoes[id]` guarda `"papel"`,
`"tarjas"`, `"marcas"`, `"tubo"` e `"foco"`.

### O main (`main.gd`)

- `_quadro_salao()`: sai o `hud.placa`; entra
  `hud.dica_presa = {"lugar": quem, "linhas": [["cruz", "Tocar a faixa"]], "fechado": not dados.aberta}`
  (vazio sem ninguém perto). No ✕: `Som.tocar("ui_confirma", null, -12.0)`,
  `Som.no_controle(l, "ui_confirma", 0.85)`, `Forja.vibrar(l, 0.0, 0.45, 60)`
  antes de `_entrar_na_sala`; no fechado, o mesmo com `ui_volta`.
- `_perto_da_bigorna()`: a dica presa com as três linhas; o mesmo som no ✕,
  no □ e no △.
- `_ao_terminar_a_sala()`, **depois** das guardas e antes do ramo da partida:

```gdscript
	if sala is SalaJogo:
		var sj := sala as SalaJogo
		var presentes: Array = []
		for l in 4:
			if sj.jogando[l]:
				presentes.append(l)
		var r := Colecao.registrar(sj.id, sj.pontos, presentes, sj.coop, sj.coop and sj.coop_venceu and sj.erros_do_grupo() == 0)
		for nome in r.desbloqueou:
			Forja.aviso.emit("%s na forja" % nome)
		if r.recorde >= 0:
			Forja.aviso.emit("Recorde da noite: P%d" % (r.recorde + 1))
			Musica.jingle("JIN_RECORDE")
			Forja.vibrar(r.recorde, 0.3, 0.6, 80)
```

  `Forja.aviso` é o sinal de hoje (`forja.gd:30`, `signal aviso(texto)`), que o
  HUD já ouve: por isso `emit`.
  `SalaJogo.erros_do_grupo() -> int` é novo: devolve 0 por padrão; o kit
  (H04) soma os `julgar(l, 0)` da G04. Até lá, todo coop vencido conta como
  sem erro só se a sala sobrescreve e devolve 0.
- `_ir_para_o_salao()`, dentro do `feito`:
  `salao.mostrar_colecao(partida != null and partida.lado() == "B")` e
  `hud.vencidas = Colecao.secoes_acesas()`.
- A pose do salão com a lente de 35 mm e a deriva (A cena).

### O HUD (`hud.gd`)

```gdscript
var vencidas := -1          ## -1: fora do salão (não desenha o contador)
var dica_presa := {}        ## {lugar, linhas: [[glifo, frase]], fechado}
var camera: Camera3D        ## o main põe: a dica presa segue a cabeça
```

O salão desenha o contador, «Salas vencidas», os chips e a dica presa, e
os põe em `retangulos()`.

### As traduções (`traducoes.gd`, as que faltarem)

`"Salas vencidas": "Rooms cleared"`, `"Tocar a faixa": "Play the track"`,
`"Tocar A Prova": "Play The Trial"`, `"Partida": "Match"`,
`"Prova de Fogo": "Trial by Fire"`, `"Em breve": "Coming soon"`,
`"Cromado": "Chrome"`, `"Néon": "Neon"`, e os padrões
`["^(.+) na forja$", "$1 in the forge"]`,
`["^Recorde da noite: P(\\d)$", "Record of the night: P$1"]`,
`["^S(\\d) · 1 FAIXA$", "S$1 · 1 TRACK"]`,
`["^S(\\d) · (\\d+) FAIXAS$", "S$1 · $2 TRACKS"]`,
`["^S(\\d) · EM BREVE$", "S$1 · COMING SOON"]`. Os nomes dos portões são
nomes próprios: não traduzem.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 5 e 7.

1. **O 13 primeiro:** uma seção «### A coleção — G06» com a API de `Colecao`
   (o bloco acima) e, na tabela do registro v2, a linha `colecao` (`id`,
   `trofeus`, `desbloqueou`).
2. **O som:** o encanamento (se ainda não há), os 3 WAV, o import, as linhas
   do mapa; `Musica.jingle`.
3. **`colecao.gd`** (novo; importar e commitar o `.uid`) e
   `Colecao.carregar(robo)` em `forja.gd`.
4. **`salao.gd`:** `PORTOES` sem `"sobre"` e `"icone"`; a etiqueta do
   portão; o foco e o tubo; `_vitrine()`; as pedras saem;
   `mostrar_colecao()`, `portao_aceso()`, `trofeus_na_vitrine()`,
   `cor_do_trofeu()`; o `amb_salao`.
5. **`player.gd`:** Cromado e Néon; `acabamentos_disponiveis()` com a
   coleção; o `"acento"` e os dois uniforms.
6. **`desenho.gd`** (`chip` com `palavra`) e **`hud.gd`:** o contador, os
   chips, a dica presa, `retangulos()`.
7. **`main.gd`:** a coleção no fim da sala, `mostrar_colecao` e `vencidas`
   no salão, a dica presa, os sons do ✕, a pose com a deriva;
   `SalaJogo.erros_do_grupo()`.
8. **`traducoes.gd`** e **as provas**.

## Armadilhas

- **`.uid`** do `colecao.gd`.
- **Nada de `Forja.robo` fora do `forja.gd`:** `Colecao.carregar(robo)` recebe
  o valor de lá; `guardar()` usa o `_robo` guardado (o padrão do
  `Opcoes.guardar()` da G02).
- **A noite:** `Opcoes.noite()`; a coleção de ontem não aparece hoje.
- **O `sobre` sai de três lugares:** `PORTOES`, a placa 3D e o
  `dados.sobre` do main.
- **A cor do lugar é sagrada** (portão 3): o tubo é `TUNGSTENIO` da forja; as
  marcas são `TINTA`; só a taça de quem venceu leva a cor dele, por variável.
- **`darkened` até 0,15** (portão 1): o papel apagado é o token
  `ETIQUETA_SOMBRA`, não `ETIQUETA.darkened(0.55)` como no estudo.
- **O brilho tem dono:** o tubo com `Tema.neon(..., "forja")` (teto 2,4); o
  acento do Néon com o lugar (teto 3,0); nada mais brilha na vitrine.
- **A luz das tochas e a chama** são da G15: não mexer.
- **`Label3D` não passa pelo portão 4** (o tamanho conta na tela): o nome a
  88 e `pixel_size` 0,0042 dá 0,37 m de letra, legível na prancha a 19 m.
- **A Prova não é portão:** ela conta em `secoes_acesas()` pela vitória,
  sem etiqueta nem tubo.
- **Os casos que quebram:** `--robo=bom|medio|ruim` (com o ruim, uma sala
  pode acabar sem ninguém pontuar: sem troféu, sem erro), partidas de 1 e 2
  jogadores (com 1, o vencedor é ele se pontuou; os chips só dos ocupados) e
  o controle que cai no meio da sala (não tira a vitória de quem venceu; o
  chip dele vira «Sem controle»).

## Não fazer

- Loja, moeda, contagem de pontos da coleção.
- Peças, itens ou raças desbloqueáveis: tudo o que muda stat ou aparência
  de base está livre desde o primeiro minuto (sistemas).
- A gaveta e os riscos dos cavaleiros (sistemas, a progressão): ficha própria.
- Mudar a regra da partida, do placar ou do pódio.
- Mudar a posição dos portões ou o tamanho do salão (o quadro 02 tem 5
  portões na parede do fundo; o jogo tem 8 em três paredes e fica assim).
- Texto longo no salão: a etiqueta diz o nome, a seção e as faixas; a dica,
  só o verbo.

## Pronto quando

Depois de uma partida de três, o salão mostra o portão vencido aceso, o
contador em «n/9», os troféus na vitrine, os chips com os nomes, e a
construção oferece o Dourado; perto de um portão, a dica presa diz «Tocar a
faixa» e o ✕ soa na mão; outra noite começa com a coleção vazia.

E só fecha com `bash tests/prova_visual.sh` passando e a prancha olhada; a
aparência só se aprova na máquina do André, com placa de vídeo, sem
`--fixed-fps`.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função pura, chamada no `_ready()`
depois de `_prova_das_contas_da_partida()` (linha 65); ela guarda e devolve
o estado:

```gdscript
## As contas da coleção, sem sala.
func _prova_das_contas_da_colecao() -> void:
	var antes := [Colecao.vencidos.duplicate(), Colecao.recordes.duplicate(), Colecao.trofeus.duplicate(), Colecao.desbloqueados.duplicate()]
	Colecao.zerar()
	_esperar(Colecao.registrar("molde", [0, 0, 0, 0], [0, 1]).desbloqueou == [], "coleção: ninguém pontuou, nada se ganha")
	_esperar(Colecao.trofeus.is_empty() and not Colecao.vencidos.has("molde"), "coleção: zero pontos não é vitória")
	_esperar(Colecao.registrar("molde", [10, 40, 40, 0], [0, 1, 2]).desbloqueou == ["Dourado"], "coleção: a primeira vitória desbloqueia o Dourado")
	_esperar(Colecao.vencidos["molde"] == 1, "coleção: o empate em cima vai para o menor lugar")
	var r := Colecao.registrar("molde", [90, 0, 0, 0], [0, 1])
	var tipos := Colecao.trofeus.map(func(t): return str(t.tipo))
	_esperar(tipos == ["vitoria", "recorde"] and r.recorde == 0, "coleção: vencer de novo com mais pontos é recorde (%s)" % [tipos])
	_esperar(Colecao.secao_acesa("molde") and not Colecao.secao_acesa("viga"), "coleção: a seção acende só com os minigames dela vencidos")
	Colecao.registrar("viga", [5, 0, 0, 0], [0])
	Colecao.registrar("canto", [0, 5, 0, 0], [1])
	_esperar(Colecao.secoes_acesas() == 3 and Colecao.desbloqueado("Cromado"), "coleção: três seções acesas desbloqueiam o Cromado")
	Colecao.registrar("caminhos", [1, 1, 1, 1], [0, 1, 2, 3], true, true)
	_esperar(Colecao.desbloqueado("Néon"), "coleção: o coop sem erro desbloqueia o Néon")
	for a in ForjaPlayer.ACABAMENTOS:
		_esperar(float(a.get("metal", 0.0)) <= 0.2 and float(a.get("acento", 1.6)) <= 3.0, "acabamento %s: metal até 0,2 e acento até 3,0" % a.nome)
	Colecao.vencidos = antes[0]
	Colecao.recordes = antes[1]
	Colecao.trofeus = antes[2]
	Colecao.desbloqueados = antes[3]
```

E no fim de `_prova_da_partida()`, depois de voltar ao salão:

```gdscript
	_esperar(Colecao.vencidos.has("centelha"), "coleção: A Centelha foi vencida nesta noite")
	_esperar(jogo.salao.portao_aceso("centelha"), "o portão d'A Centelha acendeu")
	_esperar(jogo.hud.vencidas == Colecao.secoes_acesas() and jogo.hud.vencidas >= 1, "o contador do salão (%d/9)" % jogo.hud.vencidas)
	_esperar(jogo.salao.trofeus_na_vitrine() == mini(Colecao.trofeus.size(), 18), "a vitrine mostra os troféus (%d)" % Colecao.trofeus.size())
	var dono: int = int(Colecao.vencidos["centelha"])
	_esperar(jogo.salao.cor_do_trofeu(0).is_equal_approx(Tema.JOGADOR[dono]), "a taça tem a cor de quem venceu")
	_esperar(ForjaPlayer.acabamentos_disponiveis().has(3), "a construção oferece o Dourado")
	_confere_o_hud("no salão, com a coleção")
	# a dica presa e o som do ✕, sem entrar
	jogo.jogadores[0].global_position = jogo.salao.saida_do_portao("centelha", 0)
	await _quadros(3)
	_esperar(jogo.hud.dica_presa.get("lugar", -1) == 0, "perto do portão, a dica presa ao P1")
	_esperar(jogo.hud.retangulos().all(func(r): return Rect2(Vector2.ZERO, jogo.hud.size).encloses(r)), "a dica presa cabe na tela")
```

(O ✕ que entra na sala já é provado pelo percurso; o `ui_confirma` no
alto-falante se confere com `Forja.som_virtual(0).falante > 0` nos 6
quadros depois do `_aperta(0, Forja.CRUZ)` que o percurso já faz no salão.)

**A prova visual (F09):** `bash tests/prova_visual.sh`; na prancha, o salão
depois de cada partida com o portão aceso, o contador e a vitrine crescendo,
ao lado de `docs/imagens/direcao/02_salao.jpg`.

## Para o André (local)

1. `./run-local.sh`, uma partida de três: voltar ao salão; o portão vencido
   aceso, o contador, os chips com os nomes; andar até a vitrine (parede da
   direita).
2. Parar perto de um portão: a dica presa acompanha a cabeça; ✕ soa no
   controle.
3. Voltar à construção pela pausa: o Dourado no acabamento.
4. Fechar e abrir na mesma noite: a vitrine continua; apagar `colecao.cfg`
   da pasta de dados do Godot: a coleção vazia.
5. `bash tests/prova_visual.sh` sem `--fixed-fps`, com a placa de vídeo:
   o tungstênio do portão aceso contra o violeta do resto.

## Ao terminar

No [quadro](README.md), G06 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: o salão conta a noite, com o portão que acende, o contador, a vitrine e os acabamentos que se ganham jogando
```

## O que foi feito (leva 1, o-cavaleiro)

**Feita no que as fichas anteriores deixam.** O HUD do salão ficou no núcleo, porque a G04, a G11 e a G14 ainda não chegaram.

- **A coleção** (`godot/scripts/colecao.gd`, `class_name Colecao`, e o `.uid`): a API da ficha (`carregar`, `ler`, `guardar`, `gravar`, `zerar`,
  `registrar`, `minigames_da_secao`, `secao_acesa`, `secoes_acesas`, `marcas`, `desbloqueado`); `user://colecao.cfg` com uma seção por noite
  (as 14 mais novas ficam); o evento `colecao` (`id`, `trofeus`, `desbloqueou`) no registro; `Colecao.carregar(robo)` no `forja.gd`, depois de
  `Opcoes.carregar`. Com o robô nada se lê nem se grava.
- **O salão** (`salao.gd`): `PORTOES` sem `sobre` e `icone`; a etiqueta do cassete em 3D (papel, tarja na tinta da seção, nome em Permanent
  Marker, linha em VT323, uma marca por minigame); o `SpotLight3D` a 3,2 (aceso) e 0,55 (apagado) e o tubo de tungstênio só no aceso; a
  vitrine na parede leste (as pedras saem), com a taça, a moeda e os quatro cubos, os 18 troféus mais novos; `mostrar_colecao(lado_b)`,
  `portao_aceso`, `trofeus_na_vitrine`, `cor_do_trofeu`, `pausar_ambiente`; o laço `amb_salao`.
- **O som:** `amb_salao.wav` entra no jogo (`edit/loop_mode=2`, `compress/mode=0`; no mapa passa a `no jogo`); `Som.laco` toca o arquivo do mapa
  em laço (uma cópia, para o `tocar` do mesmo id não herdar o laço); `Musica.jingle(slot)` toca o `JIN_*` se o OGG existe (hoje nenhum
  existe: a H05 os traz); `ui_confirma` e `ui_volta` (já no jogo) soam no ✕ do salão, na TV e na mão de quem apertou, com o toque.
- **O cavaleiro** (`player.gd`): o Cromado e o Néon (`acento` 2,4, teto 3,0) em `ACABAMENTOS`, `acabamentos_disponiveis()` com a coleção, e o
  acento de repouso do acabamento escrito no shader (o encaixe sobe 1,0 acima dele).
- **O HUD** (`hud.gd`, `desenho.gd`): o contador `n/9`, «Salas vencidas», os chips com o nome do cavaleiro na cor do lugar (`Desenho.chip`
  novo, com `palavra`), a dica presa à cabeça de quem chegou num portão ou na bigorna (a placa de baixo sai) e `retangulos()`.
- **O main:** `Colecao.registrar` no fim de toda sala (`SalaJogo.erros_do_grupo()` novo, devolve 0), o aviso «X na forja» e «Recorde da noite»,
  `mostrar_colecao` e `vencidas` na volta ao salão, a deriva da câmera de 2 % e `Forja.som_preparar` ao entrar no salão (sem isso o
  alto-falante do controle fica calado ali).
- **`Tema`:** `ETIQUETA_SOMBRA`, `TINTA_SUAVE` e `tinta_da_secao(n)` (os tokens do arte/02 que faltavam).
- **As provas** (`prova_do_jogo.gd`): `_prova_das_contas_da_colecao` (as contas, o arquivo, a noite que muda, as 14 noites, o robô que não grava, os
  acabamentos) e `_prova_da_colecao_no_salao` ao fim da partida (o portão aceso, o foco, o tubo, o contador, a vitrine, a cor da taça, o
  Dourado, a dica presa, o ✕ no alto-falante). Mordida: contar zero ponto como vitória, tirar a coleção de `acabamentos_disponiveis` e apagar o
  `mostrar_colecao` reprovaram 11 checagens; as curas voltaram.

### Desvios e decisões (a validar por ela)

- A G04, a G11 e a G14 não chegaram: o contador fica logo abaixo dos lugares (y 148, e não em y 60), os chips sobem 70 px (y 886) para não
  cair em cima das dicas de baixo, e o `Desenho.chip` e a dica presa são os mínimos desta ficha. O resto (a etiqueta «O Salão», o contador de
  rodas na posição final, a `Desenho.etiqueta` da G11) é delas.
- Sem `Tema.neon` (G15), o tubo usa `Kit.neon(TUNGSTENIO, 1,3)`; a etiqueta da lente de 35 mm é da G05 e não entrou, só a deriva.
- «Salas vencidas» já existia na tabela como «Rooms won»; ficou, e não «Rooms cleared» como na ficha.
- A deriva usa `Opcoes.tremor` até a G16 trazer `Opcoes.movimento`.
- O recorde dá `Forja.sentir(lugar, "acerto")` (0,3/0,6/80 na tabela), e o ✕ do salão dá `"toque"` (0/0,45/60), no lugar do `"erro"` de hoje.
- A prova tira «voz» da noite por um instante para ter um portão apagado: o robô vence todos nos percursos anteriores.

### O que fica para a mão dela e do André

- A prancha do salão ao lado de `02_salao.jpg` com placa de vídeo e sem `--fixed-fps` (o tungstênio contra o violeta, a vitrine, os chips).
- Parar perto de um portão: a dica acompanha a cabeça e o ✕ soa na mão; fechar e abrir na mesma noite (a vitrine continua); apagar o
  `colecao.cfg` (a coleção volta vazia).

### A conferência (leva 1, o-cavaleiro)

- **Corrigido:** o troféu de coop e o som da cruz traziam avisos novos nos portões de arte e de som (cor literal, `JOGADOR[0]` por índice fixo,
  id de som lido de variável); saíram, e os avisos voltaram aos da base. A ponta da dica presa vai de 40 a 72 px do topo, como a ficha manda
  (ia de 56 a 88).
- **A prova do som da cruz** chamava a função direto; agora aperta a cruz pelo controle simulado no portão aberto, confere que o alto-falante do
  P1 estava calado antes e soa depois, que a sala abre, e volta ao salão. A dica precisa dizer «Tocar a faixa».
- **O «Pronto quando» não fecha inteiro:** a prova visual não passa pelo salão depois da partida, e a prancha do salão ao lado de
  `02_salao.jpg` não existe. A lente de 35 mm é da G05.
