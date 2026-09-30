# G01 — O título e a introdução

**Sprint:** G · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5 · **Depende de:** F00, F04, F07, F08

## Por quê

O jogo abre num título que fala de módulo e de relatório e cai direto no
lobby; ele precisa de um começo que apresente o mundo sem uma frase, e o
robô tem de passar por esse começo apertando botões, como uma pessoa.

## Ler antes

- [As telas](../06-telas-e-fluxo.md#as-telas) (as linhas "título" e "introdução")
- [O mundo](../07-narrativa-e-voz.md#o-mundo) (a Dissonância, as armaduras)
- [A paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)
- [As convenções](../13-arquitetura.md#as-convenções) (o `.uid`, o texto por `Traducoes`)

## O estado de hoje

- `godot/scripts/main.gd:29` começa em `var estado := "titulo"`; `_ready()`
  chama `_mostrar("titulo")` (`main.gd:80`).
- `godot/scripts/main.gd:212-225`, `_mostrar()`: a música é sempre a do salão
  fora das salas:
  ```gdscript
  Musica.tocar(sala_id if qual == "sala" else "salao")
  ```
- `godot/scripts/main.gd:569-583`, `_quadro_titulo()`: ✕ (ou Options) de
  qualquer controle vai direto ao lobby com `_trocar(_ir_para_o_lobby)`; △ abre
  os créditos; sem controle, Enter chama `Forja.jogar_no_teclado()`.
- `godot/scripts/main.gd:536-553`, `_process()`: o `match estado` chama
  `_quadro_titulo`, `_quadro_lobby`… Não há estado de introdução.
- `godot/scripts/main.gd:909-915`: a câmera do título gira em volta da bigorna
  (`_t * 0.08`), parada com `Opcoes.tremor` desligado.
- `godot/scripts/ui/tela_titulo.gd:35-59` escreve o que o jogo vê: "O módulo
  nativo não carregou…", "Compile com scripts/compilar.sh linux.", "Nenhum
  controle.", "2 controles · 1 USB · 1 BT". `tela_titulo.gd:70-72` escreve o
  rodapé `"FORJA %s  ·  relatórios ao lado do jogo"`. Os dois saem (06).
- `godot/scripts/musica.gd:11-24`, `FAIXAS`: não há faixa de título; o título
  toca `"salao"` (92 bpm).
- `godot/scripts/mundo/salao.gd:307-313`: a luz da forja (`forja`, uma
  `OmniLight3D`) entra em `_tochas`, e `_process` (`salao.gd:50-55`) a faz
  tremular como as tochas. Nada a acende "no ritmo".
- Não existe o pio do cavaleiro: `grep -rn "pio" godot/scripts` não acha nada.
  O jeito de pôr um som no alto-falante de um controle é o de
  `godot/scripts/som.gd:152-165` (`Som.no_controle`): registra o PCM no módulo
  com `Forja.ctl.som_registrar(nome, pcm16, taxa)` e toca com
  `Forja.som_falante(lugar, nome, ganho)`. O módulo sintetiza PCM com
  `Forja.ctl.sintetizar_pcm16(tipo, parametros)` (tipos `"acorde"`, `"blip"`,
  `"tom"`, `"bigorna"`… em `nativo/godot/forja_medidas.cpp:399-431`).
- `godot/testes/prova_do_jogo.gd:71-75` aperta ✕ no título e espera
  `jogo.estado == "lobby"` 40 quadros depois.
- `godot/testes/captura_jogo.gd` navega o título apertando ✕ em todos os
  roteiros: `_roteiro_das_telas` (67-70), `_roteiro_das_salas` (183-186),
  `_roteiro_da_partida` (216-219), `_roteiro_do_trailer` (247-251),
  `_roteiro_dos_extras` (267-270).

## O alvo

O fluxo ([06](../06-telas-e-fluxo.md#o-fluxo)): **título → introdução (só na
primeira vez da sessão) → construção** (o estado `"lobby"`, que a G02
transforma na construção).

**O título** (`TelaTitulo`, desenhado em `_draw()`, tela lógica 1920×1080):

| o quê | onde | como |
| --- | --- | --- |
| a tarja escura da esquerda | `Rect2(0, 0, 900, h)` + o degradê de 24 faixas | como hoje |
| o brilho da forja atrás do logo | `draw_circle(Vector2(220, 270), 150, Color(Tema.ROSA, 0.12 * pulso))` | `pulso` 0..1, posto pelo main a cada quadro |
| o logo | `Rect2(120, 170, 200, 200)` | como hoje |
| "Hefesto" / "Tech Demo" | x 120, y 480 e 590, `Tema.fonte(700)`, 112 px, `Tema.ROSA` / `Tema.FG` | como hoje |
| "Quatro DualSense no mesmo sofá." | x 124, y 660, `Tema.T_SUBTITULO`, `Tema.SUAVE` | como hoje |
| sem nenhum controle | x 120, y 770: "Nenhum controle encontrado", `Tema.fonte(600)`, `Tema.T_CORPO`, `Tema.LARANJA`; e em y 900 a dica "Botão Enter (Jogar no teclado)" | só quando `Forja.conectados() == 0` (com ou sem módulo) |
| com controle | y 900: a dica de ✕ "Começar", 40 px, glifo em `Color(Tema.ROSA, 0.75 + 0.25 * sin(_t * 3.0))`, texto `Tema.FG`; ao lado, a de △ "Créditos", `Tema.T_ROTULO` | como hoje, com a escrita da F07 |
| rodapé, contagem USB/BT, módulo | — | **saem** |

As dicas de botão seguem a F07 ("Botão ✕ (Começar)"): use a mesma função que
a F07 usou nas outras telas (`grep -rn "Botão" godot/scripts/ui/*.gd`). A
versão vai para o registro: `Forja.registrar("FORJA %s" % Forja.versao())` uma
vez, no `_ready()` do main.

**A forja acendendo no ritmo:** a faixa nova `"titulo"` em `Musica.FAIXAS`,
`[57, 115, 1]` (115 bpm, o `MUS_TELA_TITULO` de
[04](../04-ritmo-e-audio.md#as-telas-e-os-jingles); a H05 troca pela faixa de
verdade). No título, o main põe em `salao.pulso` e em `titulo.pulso`:

```gdscript
var batida := fmod(_t_titulo * 115.0 / 60.0, 1.0)
var k := clampf(_t_titulo / 2.0, 0.0, 1.0) * (0.55 + 0.45 * pow(1.0 - batida, 3.0))
```

(`_t_titulo` zera quando o título aparece.)

**O pio:** cada controle que aperta ✕ ○ □ △ ou Options no título solta o
pio do boneco do seu lugar **no próprio alto-falante** ([05](../05-haptica-e-controle.md#a-agenda-do-alto-falante)).
O pio de cada modelo mora em `godot/scripts/player.gd`, alinhado com
`MODELOS`:

```gdscript
## O pio de cada boneco no alto-falante do controle (05): [tipo, parâmetros]
## do sintetizador do módulo. A G08 acrescenta um por boneco novo.
const PIO_DO_MODELO := [
	["acorde", {"freqs": [880.0, 1318.5], "espaco": 0.05, "dur_nota": 0.14}],  # humano: dois bipes subindo
	["acorde", {"freqs": [392.0, 293.66], "espaco": 0.07, "dur_nota": 0.18}],  # orc: dois graves descendo
]
```

e toca por uma função nova em `godot/scripts/som.gd`:

```gdscript
func pio(lugar: int, boneco: int) -> void
```

**A introdução** (`godot/scripts/ui/tela_intro.gd`, `class_name TelaIntro
extends Control`, novo; **sem nenhum texto**):

```gdscript
const DURACAO := 24.0
var t := 0.0
var acabou := false
func comecar(salao: Salao, jogadores: Array) -> void
func quadro(dt: float) -> void          # anda a linha do tempo; o main chama no estado "intro"
func terminar() -> void                  # devolve o salão e os bonecos ao normal (também quando pula)
func pose_da_camera() -> Array           # [posição, olhar]
```

| tempo (s) | o que acontece |
| --- | --- |
| 0 – 4 | a forja acesa no ritmo (`salao.pulso` como no título); câmera perto da bigorna: `[B + Vector3(3.2, 2.2, 4.2), B + Vector3(0, 1.2, 0)]`, com `B = salao.bigorna.global_position` |
| 4 – 9 | a Dissonância: `salao.apagado` sobe de 0 a 1 (tochas e forja apagam); a estática cresce de 0 a 1; `Musica.calar()` aos 4,0 s; `Som.tocar("vento")` aos 4,0 e aos 6,5 s |
| 9 – 12 | escuro; a estática baixa para 0,35; a câmera vai para os pedestais: `[Vector3(0, 2.4, 11.0), Vector3(0, 1.0, 4.4)]` |
| 12 – 19 | as quatro armaduras vazias: os quatro bonecos nos pedestais, visíveis, sem a cabeça (`cabeca(false)`), na animação `"static"`, tingidos de cinza (`tingir(0.0)`). Aos 12,5 / 14,0 / 15,5 / 17,0 s, a do P1, P2, P3, P4 acende: `tingir(1.0)`, `Som.tocar("bigorna")`, `Efeitos.faiscas(salao, pos + Vector3(0, 1.6, 0), Forja.cor_do_lugar(l), 24, 0.8)` |
| 19 – 24 | a forja reacende: `salao.apagado` desce a 0; `Musica.tocar("titulo")`; a estática some; aos 24,0 s, `acabou = true` |

A estática, em `_draw()`: um `RandomNumberGenerator` com
`seed = int(t * 24.0)`; `int(60 * densidade)` faixas horizontais
`Rect2(0, y, size.x, h)` com `y` sorteado, `h` de 2 a 10 px, cor
`Tema.COMMENT` ou `Tema.FG` com alfa de 0,05 a 0,25 × densidade (× 0,4 com
`Opcoes.flashes` desligado), e um véu `Color(Tema.CASA, 0.35 * escuro)` por
cima de tudo.

`ForjaPlayer` ganha duas funções (a G02 usa `tingir` nas marteladas):

```gdscript
func tingir(k: float) -> void      # 0: armadura cinza (Tema.SUTIL); 1: a cor do lugar (a de hoje)
func cabeca(visivel: bool) -> void # mostra ou esconde a malha "head-mesh"
```

`Salao` ganha:

```gdscript
var luz_da_forja: OmniLight3D   # a luz de _bigorna(), fora de _tochas
var pulso := -1.0               # 0..1: o título e a introdução mandam; -1: tremula como hoje
var apagado := 0.0              # 0..1: a Dissonância apaga tochas e forja
```

**O robô do fluxo** (a regra 2 da [paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)):
uma função `_robo(dt)` no main, chamada numa linha só
`if Forja.robo: _robo(dt)` dentro de `_process`. Ela só aperta botões no
controle simulado (`Forja.robo_apertar`):

| estado | o robô |
| --- | --- |
| `titulo` | espera 3,0 s e aperta ✕ no controle do P1 |
| `intro` | nada: a introdução acaba sozinha em 24 s |
| `lobby` | a cada 0,6 s, aperta ✕ em cada lugar com controle que ainda não está pronto (a G02 troca este ramo pelo robô da construção) |

## Passos

Cada passo termina com o jogo abrindo: `bash tests/prova_do_jogo.sh` depois
dos passos 3, 6 e 9.

1. **`godot/scripts/player.gd`:** acrescentar `PIO_DO_MODELO` (acima) logo
   depois de `NOME_DO_MODELO`; em `_vestir()`, guardar cada material de roupa
   criado numa lista `var _roupas: Array[StandardMaterial3D] = []` (esvaziar a
   lista quando `visual()` troca de modelo, antes de `_vestir(modelo)`);
   escrever `tingir(k)` (`m.albedo_color = Tema.SUTIL.lerp(cor.lerp(Color.WHITE, 0.25), k)`
   para cada `m` de `_roupas`) e `cabeca(visivel)`
   (`modelo.find_child("head-mesh", true, false)`; se achar, `.visible = visivel`).
2. **`godot/scripts/som.gd`:** escrever `pio(lugar, boneco)`:
   ```gdscript
   var _pios := {}  ## "pio_N" -> registrado no módulo
   ## O pio do cavaleiro no alto-falante do controle do lugar (05).
   func pio(lugar: int, boneco: int) -> void:
   	if not Forja.modulo or lugar < 0:
   		return
   	if not Forja.ctl.som_preparado():
   		Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)
   	var i := wrapi(boneco, 0, ForjaPlayer.PIO_DO_MODELO.size())
   	var nome := "pio_%d" % i
   	if not _pios.has(nome):
   		var r: Array = ForjaPlayer.PIO_DO_MODELO[i]
   		_pios[nome] = Forja.ctl.som_registrar(nome, Forja.ctl.sintetizar_pcm16(r[0], r[1]), 48000)
   	if _pios[nome]:
   		Forja.som_falante(lugar, nome, 0.85)
   ```
3. **`godot/scripts/musica.gd` e `godot/scripts/mundo/salao.gd`:** a faixa
   `"titulo": [57, 115, 1]` em `FAIXAS`; em `Salao._bigorna()`, guardar a luz
   em `luz_da_forja` e **tirar** a linha `_tochas.append(forja)`
   (`salao.gd:313`); em `Salao._process`, multiplicar a energia de cada tocha
   por `1.0 - apagado` e pôr a da forja:
   `luz_da_forja.light_energy = ((0.5 + 3.0 * pulso) if pulso >= 0.0 else (1.6 + 0.25 * sin(_t * 7.3))) * (1.0 - apagado)`.
4. **`godot/scripts/ui/tela_titulo.gd`:** `var pulso := 0.0`; o brilho atrás
   do logo; apagar as linhas 35-59 (o que o jogo vê) e 70-72 (o rodapé); o
   bloco "sem controle" e as dicas como na tabela do alvo; nenhum texto sobre
   módulo.
5. **`godot/scripts/ui/tela_intro.gd` (novo):** `TelaIntro` como no alvo.
   `comecar()` guarda as referências, zera `t` e `acabou`, mostra os quatro
   bonecos em `salao.pedestais[l]` (`visible = true`, `rotation.y = 0`,
   `animar("static")`, `cabeca(false)`, `tingir(0.0)`). `terminar()` volta
   `salao.pulso = -1.0`, `salao.apagado = 0.0`, `cabeca(true)`, `tingir(1.0)`
   e `animar("idle")` nos quatro. `_process` só chama `queue_redraw()`. Rodar
   `"$GODOT" --headless --path godot --import --quit` para nascer o
   `tela_intro.gd.uid`.
6. **`godot/scripts/main.gd`:**
   - `var intro: TelaIntro` criado em `_interface()` junto das outras telas
     (antes da `cortina`), `visible = false`;
   - `var _viu_a_intro := false` e `var _t_titulo := 0.0`;
   - `_mostrar()`: `intro.visible = qual == "intro"`; a música por `match`:
     `"sala"` → `Musica.tocar(sala_id)`; `"titulo"`, `"intro"` →
     `Musica.tocar("titulo")`; o resto → `Musica.tocar("salao")`;
     `salao.pedestais_no.visible = qual in ["lobby", "podio", "intro"]`; ao
     mostrar `"titulo"`, `_t_titulo = 0.0`;
   - `_quadro_titulo()`: no lugar de `_trocar(_ir_para_o_lobby)`, chamar
     `_depois_do_titulo()`, que faz
     `_trocar(_ir_para_a_intro if not _viu_a_intro else _ir_para_o_lobby)`;
     antes das checagens, o pio:
     ```gdscript
     for p in Forja.pads():
     	var l := int(p.lugar)
     	if l < 0:
     		continue
     	for b in [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO, Forja.OPTIONS]:
     		if Forja.pad_apertou(int(p.pad), b):
     			Som.pio(l, jogadores[l].modelo_i)
     			break
     ```
     e o pulso: `_t_titulo += get_process_delta_time()`, a conta do alvo em
     `salao.pulso` e `titulo.pulso`. Sem módulo, ✕ (Enter) também chama
     `_depois_do_titulo()`;
   - `_ir_para_a_intro()`: `_viu_a_intro = true`, `_mostrar("intro")`,
     `intro.comecar(salao, jogadores)`;
   - `_quadro_intro(dt)`: `intro.quadro(dt)`; se `intro.t > 0.5` e algum pad
     apertou ✕ ○ □ △ ou Options (`Forja.pad_apertou`), ou sem módulo
     `Forja.apertou(0, Forja.CRUZ)`, ou `intro.acabou`:
     `_trocar(func() -> void: intro.terminar(); _ir_para_o_lobby())`;
   - `_process`: `"intro": _quadro_intro(dt)` no `match`;
   - `_pose_da_camera()`: `"intro": return intro.pose_da_camera()`;
     `_mover_camera`: o `k` de 1,2 vale para `"titulo"` e `"intro"`;
   - `_ready()`: `Forja.registrar("FORJA %s" % Forja.versao())`.
7. **`godot/scripts/main.gd`, o robô do fluxo:** `_robo(dt)` como na tabela
   do alvo, com `var _robo_estado := ""` e `var _robo_espera := 0.0` (ao mudar
   de estado, `_robo_espera` volta a 3,0 no título e a 0,6 no lobby); nada
   roda com `_trocando` ou com overlay aberto. Em `_process`, depois do
   `match`: `if Forja.robo: _robo(dt)`. Nenhum outro `Forja.robo` entra no
   main.
8. **`godot/scripts/traducoes.gd`:** as entradas novas, se a F07 ainda não as
   pôs: `"Nenhum controle encontrado": "No controller found"`,
   `"Jogar no teclado": "Play on the keyboard"`, `"Começar": "Start"`,
   `"Créditos": "Credits"`.
9. **As provas e as fotos:** a navegação nova em
   `godot/testes/prova_do_jogo.gd` e em `godot/testes/captura_jogo.gd` (ver
   Provas).

## Armadilhas

- **`.uid`:** `tela_intro.gd` é script novo; sem o `.uid` commitado, a
  exportação quebra. Importe e commite o `tela_intro.gd.uid`.
- **Tudo em `_draw()`:** a estática e o título são desenho 2D; nada de
  `Label` novo.
- **Texto por `Traducoes`, com maiúscula:** `Desenho.texto` e `Glifo.dica`
  já traduzem; a frase nova precisa da entrada em `traducoes.gd`. A
  introdução não tem texto nenhum.
- **O robô só aperta:** nenhuma condição `Forja.robo` fora de `_robo`
  (a checagem estática da F08 reprova). O robô não pula a introdução: a
  prova confere que ela acaba sozinha.
- **Os roteiros com `--robo` não apertam mais no título nem no lobby:** o
  robô do main já aperta; um ✕ a mais do roteiro cai na introdução e a pula,
  ou cai na construção e confirma alguém fora de hora.
- **O ✕ que abriu a introdução não a pula:** a guarda de 0,5 s em
  `_quadro_intro`.
- **Lugar vazio:** na introdução os quatro bonecos aparecem mesmo sem
  jogador; `_ir_para_o_lobby` → `_mostrar("lobby")` →
  `_sincronizar_jogadores()` esconde os vazios. Confira que `terminar()` roda
  também quando se pula (o `_trocar` com a função que chama os dois).
- **`_tochas` sem a forja:** se a luz da forja ficar nas duas listas, o
  `_process` do salão briga com o pulso e ela pisca.
- **O pio precisa da placa preparada:** `Som.pio` prepara
  (`Forja.som_preparar`) só se `Forja.ctl.som_preparado()` for falso; a
  entrada numa sala prepara de novo, e isso é o comportamento de hoje.

## Não fazer

- Nenhum texto na introdução, nenhuma pergunta, nenhum "olhe o LED".
- Não mexer no lobby além do ramo do robô (a construção é a G02).
- Não criar arquivo de áudio: a faixa `"titulo"` é sintetizada como as
  outras até a H05.
- Não mostrar na tela "módulo", "relatório", USB/BT, versão.
- Não pular a introdução com `Forja.robo`.

## Pronto quando

Alguém que nunca viu o jogo liga, vê o título com a forja pulsando, aperta
✕, ouve o pio no próprio controle, vê a introdução de 24 s sem uma palavra
(ou a pula com qualquer botão) e chega à construção; `--simular=4 --robo`
faz o mesmo caminho sozinho, só apertando botões.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, `_prova_do_percurso()`: **trocar** o
trecho que vai de `_esperar(jogo.estado == "titulo", …)` até o
`await _quadros(40)` + `_esperar(jogo.estado == "lobby", …)` por:

```gdscript
	_esperar(jogo.estado == "titulo", "o jogo abre no título")
	# o título: quem aperta ✕ é o robô do fluxo (main.gd _robo), no controle do P1
	var pio := [0.0, 0.0]
	var q := 0
	while jogo.estado == "titulo" and q < 600:
		await _quadros(1)
		q += 1
		for l in 2:
			pio[l] = maxf(pio[l], float(Forja.som_virtual(l).get("falante", 0.0)))
	_esperar(jogo.estado == "intro", "✕ no título leva à introdução")
	_esperar(jogo.intro.visible and not jogo.titulo.visible, "a introdução aparece no lugar do título")
	var armaduras := 0
	q = 0
	while jogo.estado == "intro" and q < 1800:
		await _quadros(1)
		q += 1
		for l in 2:
			pio[l] = maxf(pio[l], float(Forja.som_virtual(l).get("falante", 0.0)))
		if jogo.intro.t > 18.0:
			var n := 0
			for p in jogo.jogadores:
				if p.visible:
					n += 1
			armaduras = maxi(armaduras, n)
	_esperar(pio[0] > 0.05, "o pio do P1 saiu no alto-falante do P1 (%.2f)" % pio[0])
	_esperar(pio[1] < 0.02, "e não no do P2 (%.2f)" % pio[1])
	_esperar(armaduras == 4, "a introdução acende as quatro armaduras (%d)" % armaduras)
	_esperar(q >= 60 * 20, "a introdução dura mais de 20 s sem ninguém apertar (%d quadros)" % q)
	_esperar(jogo.estado == "lobby", "a introdução acaba sozinha e leva à construção")
```

O resto do lobby continua como a F04 deixou, com uma diferença: o robô do
main aperta ✕ em cada lugar a cada 0,6 s. Onde a prova apertava ✕ para os
quatro entrarem e ficarem prontos, **tire** esses `_aperta(s, Forja.CRUZ)`; os
testes de ◀▶ (P2) e ▲▼ (P3) continuam, apertados logo que
`Forja.ocupado(1)` e `Forja.ocupado(2)` ficam verdadeiros (antes do próximo ✕
do robô). A espera do salão passa a ser um laço:
`while (jogo.estado != "salao" or jogo._trocando) and q < 1200`.

Em `godot/testes/captura_jogo.gd`:

- `_roteiro_das_telas` (sem robô): depois de `["aperta", 0, Forja.CRUZ], ["espera", 40]`,
  acrescentar `["espera", 600], ["foto", "introducao"], ["espera", 420], ["foto", "introducao_armaduras"], ["aperta", 0, Forja.CRUZ], ["espera", 40]`.
- `_roteiro_dos_extras` (sem robô): depois do ✕ do título, `["espera", 60], ["aperta", 0, Forja.CRUZ], ["espera", 40]` (pula a introdução) antes dos ✕ do lobby.
- `_roteiro_das_salas`, `_roteiro_da_partida` (com `--robo`): trocar os
  `["aperta", …]` do título e do lobby por nada — só `["ate", no_salao]`.
- `_roteiro_do_trailer` (com `--robo`): tirar os ✕ do título e do lobby;
  depois de `["espera", 200]`, pôr
  `["ate", func() -> bool: return jogo.estado == "intro"], ["espera", 240], ["aperta", 0, Forja.CRUZ]`
  e esperar o salão antes das salas.

## Para o André (local)

1. `bash tests/telas.sh fotos /tmp/fotos-g01` e olhar `titulo.png`,
   `introducao.png` e `introducao_armaduras.png` (a escuridão e as quatro
   armaduras, sem texto).
2. `./run-local.sh`, com dois DualSense: apertar ✕ num e ○ no outro no
   título — cada pio sai só no controle que apertou; ver a introdução inteira
   uma vez e pular na segunda abertura com qualquer botão.
3. `./run-local.sh -- --simular=4 --robo`: o robô passa do título à
   construção sem ninguém tocar.

## Ao terminar

No [quadro](README.md), G01 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: o título com a forja no ritmo, a introdução sem texto e o pio no controle
```
