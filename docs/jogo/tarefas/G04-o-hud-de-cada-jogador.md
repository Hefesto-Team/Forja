# G04 — O HUD de cada jogador

**Sprint:** G · **Tamanho:** G · **Estimativa:** US$ 3,5 · **Depende de:** F00, F07, G02, G03

## Por quê

O HUD é uma fileira de chips em pixels fixos no alto à direita, com
conexão e bateria; ele colide com o nome da sala e com o relógio, e não diz
o que importa. Cada jogador precisa do seu cartão no seu canto, e o
julgamento e a fala precisam de um lugar acima do boneco.

## Ler antes

- [O HUD de cada jogador](../06-telas-e-fluxo.md#o-hud-de-cada-jogador)
- [Os tokens de cor](../../estudos/03-o-sistema-visual-do-app-hefesto.md#1-tokens-de-cor) e a seção 7 do mesmo estudo (o fator ×2)
- [As convenções](../13-arquitetura.md#as-convenções)

## O estado de hoje

- `godot/scripts/ui/hud.gd:233-296`, `_draw()`: a tarja de cima; no salão o
  cabeçalho em `(Tema.MARGEM_X, 40)`; numa sala o quadro do nome e da ação em
  `Rect2(Vector2(Tema.MARGEM_X - 28, 40), Vector2(larg, 118))`; a fileira
  dos lugares `_lugares(Vector2(w - Tema.MARGEM_X, 40))`; a placa do portão em
  `Rect2(Vector2((w - larg_p) * 0.5, h - 230), Vector2(larg_p, 150))` com
  `larg_p` até `w - 2 * Tema.MARGEM_X`; as dicas Create/Options em
  `(w - Tema.MARGEM_X, h - Tema.MARGEM_Y)`; os avisos a partir de `y = 190`.
- `godot/scripts/ui/hud.gd:300-334`, `_lugares()`: quatro chips de
  `250 × 92` lado a lado no alto à direita, com "P1", USB/BT, a bateria e a
  linha `status_da_sala[l]` (que encolhe até 20 px — abaixo do piso de 30).
- `godot/scripts/main.gd:554-556`: a cada quadro,
  `hud.status_da_sala[l] = sala.status(l)`.
- `godot/scripts/ui/painel_sala.gd:327-353`, `_tempo()`: o relógio em
  `p = Vector2(Tema.MARGEM_X - 28, 184)` (em cima do canto do P1); a linha de
  progresso em `(Tema.MARGEM_X - 28, 162)`; `_treino_e_valendo()` (426-443)
  põe o selo do treino em y 176; o quadro do aviso (`_aviso`, 35-110) em
  y 176; as dicas das raias (`_dicas`, 151-210) se prendem a `d.pos` e se
  limitam a `y ≤ size.y - 140`, podendo cair em cima dos cartões de baixo.
- Não há combo genérico: A Centelha e O Impacto guardam `j[l].combo`
  (`centelha.gd:109`, `impacto.gd:100`). A G02 deu `ForjaPlayer.nome`; a G03
  deu `Itens.do_lugar(l)`, `Itens.escudo_inteiro(l)` e os ícones
  `item_*` em `Glifo`.
- Nada mostra um julgamento ou uma fala acima do boneco.
- `tests/telas.sh` fotografa só em português e na escala 1,0.
  `godot/scripts/forja.gd:126-137`, `aplicar_opcoes()`, já lê
  `FORJA_IDIOMA`; não há variável para a escala do texto.

## O alvo

### Os quatro cartões ([06](../06-telas-e-fluxo.md#o-hud-de-cada-jogador))

P1 no alto à esquerda, P2 no alto à direita, P3 embaixo à esquerda, P4
embaixo à direita. A área segura é a margem do `Tema`: `Tema.MARGEM_X` (96 =
5% de 1920) e `Tema.MARGEM_Y` (60, que passa dos 54 de 5% de 1080). Tudo sai
de `size` (a tela pode ser mais larga ou mais alta que 1920×1080: âncoras,
não pixels).

```gdscript
const LARG_CARTAO := 392.0
const ALT_CARTAO := 128.0
## O cartão do lugar na tela `tela`: o canto dele, crescendo para dentro.
static func cartao(l: int, tela: Vector2) -> Rect2:
	var e := Tema.escala_texto
	var tam := Vector2(LARG_CARTAO, ALT_CARTAO) * e
	var x := Tema.MARGEM_X if l % 2 == 0 else tela.x - Tema.MARGEM_X - tam.x
	var y := Tema.MARGEM_Y if l < 2 else tela.y - Tema.MARGEM_Y - tam.y
	return Rect2(Vector2(x, y), tam)
```

O cartão (medidas × `e = Tema.escala_texto`, a partir do canto de cima à
esquerda do cartão):

| estado | moldura | linha 1 (base 44) | ícone | linha 2 (base 100) |
| --- | --- | --- | --- | --- |
| jogando | fundo `Color(Tema.APP, 0.9)`, borda 3 px `Tema.tom_para_a_borda(Forja.cor_do_lugar(l))`, raio `Tema.RAIO_CARTAO` | "P1" em x 20, `Tema.fonte(700)`, `Tema.T_CORPO`, cor da borda; o nome do cavaleiro em x 72, `Tema.fonte(500)`, `Tema.T_CORPO`, `Tema.FG`, `Desenho.caber` numa linha | o item: `Glifo.desenhar(self, ForjaPlayer.ITENS[Itens.do_lugar(l)].icone, Rect2(canto + (larg − 20 − 44, 14), (44, 44)), Tema.FG)`; o Escudo quebrado em `Tema.MUDO` com um traço diagonal de 3 px `Tema.MUDO` | `status_da_sala[l]` em x 20, `Tema.fonte(500)`, `Tema.T_ROTULO`, `Tema.SUAVE`, `Desenho.caber` numa linha; o combo, se ≥ 2, `"×%d"` alinhado à direita em `larg − 20`, `Tema.mono(500)`, `Tema.T_MONO`, `Tema.CIANO` |
| sem controle | fundo `Color(Tema.APP, 0.9)`, borda 2 `Tema.SUTIL` + `Desenho.tracejado(self, r.grow(-6), Tema.LARANJA, 2.0, 14.0)` | "P1" e o nome, como acima | — | "Sem controle", `Tema.fonte(600)`, `Tema.T_ROTULO`, `Tema.LARANJA` |
| lugar vazio | fundo `Color(Tema.APP, 0.5)` (translúcido), borda 2 `Tema.SUTIL` | "P3", `Tema.fonte(700)`, `Tema.T_CORPO`, `Tema.MUDO` | — | a dica de ✕ "Entrar", `Tema.T_ROTULO`, glifo e texto `Tema.MUDO` |

Sai do HUD: USB/BT, bateria, as lâmpadas (06: "Nada mais"). O texto do
lugar vazio **não** usa alfa (a regra do estudo 03: opacidade não apaga
texto); só o fundo é translúcido.

### O resto do HUD, sem encostar nos cartões

| o quê | onde (tela lógica 1920×1080) |
| --- | --- |
| salão: o cabeçalho | centrado: `Desenho.cabecalho(self, Vector2((w - 200) * 0.5, 40), 60.0)` |
| sala: o quadro do nome e da ação | centrado em x, y 40, altura 118; largura do texto + 56, no máximo `w - 2 * (Tema.MARGEM_X + LARG_CARTAO * e + 24)`; nome e ação cortados com `Desenho.caber` numa linha |
| o relógio da sala (`painel_sala._tempo`) | centrado em x: `Rect2(Vector2((size.x - 590) * 0.5, 170), Vector2(590, 52))`, o trilho de 480 dentro, a 20 da esquerda |
| a linha de progresso (sem relógio) | centrada, y 170, altura 52 |
| o selo do treino | centrado, y 236 |
| o quadro do aviso da sala | y 210 (em vez de 176) |
| os avisos que somem | a partir de y 310 (abaixo do selo do treino) |
| a placa do portão | y `h - 260`; largura no máximo `w - 2 * (Tema.MARGEM_X + LARG_CARTAO * e + 24)` |
| as dicas Create/Options | centradas embaixo, base `h - Tema.MARGEM_Y` |
| as dicas das raias (`painel_sala._dicas`) | se a pílula cruza um `HudJogo.cartao(l, size)`, sobe para `cartao.position.y - pílula.size.y - 8` |

### O visor acima do boneco

```gdscript
# hud.gd
var jogadores: Array = []                ## os ForjaPlayer (o main põe)
var combo := [0, 0, 0, 0]                ## o main põe, pela sala
var visor := [{}, {}, {}, {}]            ## por lugar: {"julgamento": [texto, resta], "fala": [texto, resta]}
## Um texto acima do boneco do lugar, na cor dele, por `segundos`: o julgamento
## (0,5 s, 07) ou, com `fala`, a fala do cavaleiro (2 s, G07).
func sobre_o_boneco(l: int, texto: String, segundos: float, fala := false) -> void
## As caixas que o HUD ocupa agora (cartões, quadro da sala, placa, avisos,
## dicas de baixo): o _draw desenha nelas e a prova confere que nenhuma encosta.
func retangulos() -> Array

# sala.gd
signal no_visor(l: int, texto: String, segundos: float, fala: bool)

# sala_jogo.gd
func combo(_l: int) -> int:      # as salas com combo devolvem o delas
	return 0
```

O desenho, para cada lugar com texto vivo e boneco visível: a cabeça na
tela `c = cam.unproject_position(jogadores[l].global_position + Vector3(0, 2.35, 0))`
(pule se `cam.is_position_behind(...)`).

- **julgamento:** pílula centrada em `c`, altura 64, fundo
  `Color(Tema.PAINEL, 0.9)`, borda 2 na cor do lugar (`tom_para_a_borda`);
  texto `Tema.fonte(700)`, `Tema.T_AVISO` (46), na cor do lugar.
- **fala:** pílula acima da do julgamento (`c.y - 90`), largura até 420,
  fundo `Color(Tema.ELEVADO, 0.95)`, borda 2 na cor do lugar; texto
  `Tema.fonte(500)`, `Tema.T_ROTULO`, `Tema.FG`, até duas linhas
  (`Desenho.caber` + `Desenho.paragrafo`).

O main liga o sinal em `_entrar_na_sala`:
`sala.no_visor.connect(hud.sobre_o_boneco)`, e zera `hud.visor` em
`_sair_da_sala`.

### A escala e a língua nas fotos

`godot/scripts/forja.gd`, `aplicar_opcoes()`, logo depois da linha do
`FORJA_IDIOMA`:

```gdscript
	if OS.get_environment("FORJA_TEXTO") == "grande":
		Tema.escala_texto = Opcoes.ESCALA_DO_TEXTO[1]
```

`tests/telas.sh fotos <pasta>` passa a fotografar quatro variantes, cada
uma numa subpasta: `pt_BR-normal`, `pt_BR-grande`, `en-normal`, `en-grande`.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 5 e 7.

1. **O 13 primeiro:** acrescentar ao [kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04),
   na tabela do que o kit faz, a linha "o visor | `no_visor.emit(l, texto, s, fala)`
   (o sinal de `Sala`, G04); o HUD desenha acima do boneco" e, em
   `SalaJogo`, `combo(l) -> int`.
2. **`godot/scripts/salas/sala.gd`:** o sinal `no_visor`.
   **`sala_jogo.gd`:** `combo(_l) -> int` devolvendo 0. **`centelha.gd` e
   `impacto.gd`:** `func combo(l: int) -> int: return int(j[l].combo) if j.has(l) else 0`.
3. **`godot/scripts/ui/hud.gd`:** `cartao()`, `retangulos()`, os cartões no
   lugar de `_lugares()` (que sai), o reposicionamento da tabela, `jogadores`,
   `combo`, `visor`, `sobre_o_boneco()` e o desenho do visor; `_process`
   desconta o `resta` e apaga o que chega a 0. `_draw()` pega as caixas de
   `retangulos()` — um só cálculo para o desenho e para a prova.
4. **`godot/scripts/ui/painel_sala.gd`:** `_tempo()`, a linha de progresso,
   o selo do treino e o quadro do aviso nas posições novas; as pílulas de
   `_dicas()` fogem dos cartões; `func retangulos() -> Array` com o relógio (ou
   a linha de progresso) e o selo do treino, quando aparecem.
5. **`godot/scripts/main.gd`:** em `_interface()`, `hud.jogadores = jogadores`;
   em `_process`, junto do `status_da_sala`,
   `hud.combo[l] = sala.combo(l) if sala is SalaJogo and Forja.ocupado(l) else 0`;
   o sinal em `_entrar_na_sala`; `hud.visor = [{}, {}, {}, {}]` em
   `_sair_da_sala`.
6. **`godot/scripts/forja.gd`:** o `FORJA_TEXTO`. **`tests/telas.sh`:** as
   quatro variantes (abaixo).
7. **`godot/scripts/traducoes.gd`:** `"Sem controle": "No controller"` e
   `"Entrar": "Join"`, se ainda não existem.
8. **As provas** (ver Provas).

`tests/telas.sh`, a função `fotos()` vira:

```bash
fotos() {
  local base
  base="$(realpath -m "$1")"
  "$GODOT" --headless --path "$RAIZ/godot" --import --quit > /dev/null 2>&1
  local total=0
  for variante in pt_BR-normal pt_BR-grande en-normal en-grande; do
    local pasta="$base/$variante"
    mkdir -p "$pasta"
    local rel
    rel="$(mktemp -d)"
    roteiro() {
      local r="$1"
      shift
      env SAIDA="$pasta" ROTEIRO="$r" RAPIDO=1 FORJA_IDIOMA="${variante%-*}" FORJA_TEXTO="${variante#*-}" "$@" \
        timeout 900 xvfb-run -a -s "-screen 0 1920x1080x24" \
        "$GODOT" --rendering-driver opengl3 --fixed-fps 60 --path "$RAIZ/godot" --resolution 1920x1080 \
        res://testes/captura_jogo.tscn -- --simular=4 --semente=7 --relatorios="$rel" ${ROBO:-}
    }
    roteiro extras > "$pasta/extras.log" 2>&1
    ROBO=--robo roteiro salas SALAS=centelha FOTOS=centelha_aviso,centelha_jogo,centelha_fim > "$pasta/salas.log" 2>&1
    ROBO=--robo roteiro partida FOTOS=partida_escolha,partida_placar_1,partida_podio > "$pasta/partida.log" 2>&1
    rm -rf "$rel"
    local n
    n="$(ls "$pasta"/*.png 2> /dev/null | wc -l)"
    echo "$variante: $n foto(s)"
    [ "$n" -ge 9 ] || { grep -hE "SCRIPT ERROR|não chegou" "$pasta"/*.log | head; exit 1; }
    total=$((total + n))
  done
  echo "$total foto(s) em $1"
}
```

(O `comparar` continua comparando duas pastas; compare variante com
variante.)

## Armadilhas

- **Tudo em `_draw()`**, e o cálculo das caixas numa função só
  (`retangulos()`, `cartao()`): se o desenho e a prova calcularem cada um o
  seu, a prova passa e a tela colide.
- **Nada abaixo de 30 px:** o `status` não encolhe mais (corta com
  `Desenho.caber`); o único texto menor que 30 seria erro.
- **Texto por `Traducoes`, com maiúscula** (F07). O nome do cavaleiro é nome
  próprio: não traduz.
- **Lugar vazio nunca segura nada:** o cartão vazio é só desenho; ele não
  entra em `jogando` nem no robô.
- **`size`, não 1920:** no Steam Deck (16:10) a tela lógica fica mais alta;
  os cartões de baixo acompanham `size.y`.
- **A bancada e a sala sem HUD** (`com_hud = false`) continuam sem cartões.
- **O robô:** nenhum `Forja.robo` no HUD.
- **O visor sem câmera:** no título e no lobby não há sala; `sobre_o_boneco`
  só desenha no salão e nas salas (quando o HUD está visível).
- **Sem script novo** (sem `.uid`).

## Não fazer

- Não escolher o vocabulário do julgamento nem as falas (G07); aqui só o
  lugar onde aparecem.
- Não mudar o que cada sala escreve em `status()`; só onde aparece.
- Não mostrar bateria, USB/BT, VID:PID ou "sem módulo" no HUD.
- Não mexer na construção (G02) nem no placar.

## Pronto quando

As fotos de todas as telas nas duas escalas e nas duas línguas não mostram
texto encostando em texto nem abaixo de 30 px; a prova confere, sem janela,
que nenhuma caixa do HUD encosta em outra nas quatro combinações, no salão e
numa sala.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função nova:

```gdscript
## O HUD nas duas escalas e nas duas línguas: nada encosta e tudo cabe (06).
func _confere_o_hud(onde: String) -> void:
	var escala_antes := Tema.escala_texto
	var idioma_antes := Traducoes.idioma
	var tela := Rect2(Vector2.ZERO, jogo.hud.size)
	for idioma in ["pt_BR", "en"]:
		for escala in Opcoes.ESCALA_DO_TEXTO:
			Tema.escala_texto = escala
			Traducoes.idioma = idioma
			var caixas: Array = jogo.hud.retangulos() + jogo.painel.retangulos()
			var ruins: Array = []
			for i in caixas.size():
				var a: Rect2 = caixas[i]
				if not tela.encloses(a):
					ruins.append("fora %s" % a)
				for k in range(i + 1, caixas.size()):
					if a.intersects(caixas[k]):
						ruins.append("%s × %s" % [a, caixas[k]])
			_esperar(ruins.is_empty(), "HUD %s, %s, %.2f: nada encosta e tudo cabe %s" % [onde, idioma, escala, ruins])
	Tema.escala_texto = escala_antes
	Traducoes.idioma = idioma_antes
```

Chamadas: logo depois de chegar ao salão pela construção
(`await _confere_o_hud("no salão")`, sem `await` se a função não espera
quadros), e dentro d'A Centelha, depois do treino (onde a G03 pôs as
checagens do Escudo), `_confere_o_hud("n'A Centelha")`, com esta checagem do
visor:

```gdscript
		jogo.hud.sobre_o_boneco(0, "Afinado", 0.5)
		centelha.no_visor.emit(1, "Deixa comigo o refrão!", 2.0, true)
		await _quadros(2)
		_esperar(jogo.hud.visor[0].has("julgamento") and jogo.hud.visor[1].has("fala"), "o visor mostra o julgamento e a fala acima do boneco")
		await _quadros(45)
		_esperar(not jogo.hud.visor[0].has("julgamento") and jogo.hud.visor[1].has("fala"), "o julgamento some em meio segundo; a fala fica")
```

E uma checagem do cartão: com os quatro jogando,
`_esperar(HudJogo.cartao(3, jogo.hud.size).end.x <= jogo.hud.size.x - Tema.MARGEM_X + 0.5, "o P4 fica no canto de baixo à direita, dentro da área segura")`.

## Para o André (local)

1. `bash tests/telas.sh fotos /tmp/fotos-g04` e olhar lado a lado as quatro
   subpastas: nenhum texto encostando, nada cortado, os cartões nos cantos.
2. `./run-local.sh` com o texto grande (Opções › Texto › Grande) e em
   inglês: uma sala inteira.
3. Numa TV, de onde se joga: o nome do cavaleiro e o combo se leem.

## Ao terminar

No [quadro](README.md), G04 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: o cartão de cada jogador no seu canto, o visor acima do boneco e as fotos nas duas escalas e línguas
```
