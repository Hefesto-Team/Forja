# H08 — Os acréscimos do kit

**Sprint:** H · **Tamanho:** G · **Estimativa:** US$ 4,0 · **Depende de:** H04, H01, H02, F03, F05, G03

## Por quê

As 45 fichas de minigame foram escritas depois do kit (H04) e, ao se
escreverem, repetiram as mesmas peças: a fila de notas, o `_no_pico()`, o
`_proxima_batida()`, a barra de luz que pisca, o `Itens.pontos_do_acerto`, o
coop à mão, o ícone copiado no `montar()`. Pior: medem o fim pelo tempo do
jogo, que com `--fixed-fps 60` corre cerca de 16 vezes mais depressa que a
música — o minigame de 90 s acaba na prova em uns 6 s de verdade, antes do
pico, e algumas fichas remendam com `"duracao": 0.0`. A seção
[As decisões comuns dos minigames — H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
do 13 decidiu tudo isso numa língua só. Esta ficha constrói, no código do
kit, cada linha daquela seção — para que nenhuma ficha de minigame
reimplemente nada e todas dependam só daqui.

## Ler antes

- [13 — As decisões comuns dos minigames — H08](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08) (o que esta ficha constrói, linha por linha)
- [13 — O kit do minigame — H04](../13-arquitetura.md#o-kit-do-minigame--h04), [o relógio de áudio](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03), [a tela de resultado](../13-arquitetura.md#a-tela-de-resultado--f03), [o item](../13-arquitetura.md#o-item--g03)
- [13 — A paridade (F08)](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08) e [a prova visual (F09)](../13-arquitetura.md#a-prova-visual--f09)
- [H04](H04-o-kit-do-minigame.md) — o código do kit (`minigame.gd`, `catalogo.gd`, `martelo_de_hefesto.gd`, `minigame_de_prova.gd`): esta ficha **estende esse código**
- [F03](F03-todo-minigame-fecha.md) (o fim, o `colocacao`, o `coop`, o `t_jogo`, o `_celebrar`) e [G03](G03-o-item-com-mecanica.md) (`Itens`, `errou(l)`)
- [Q — A Prova](Q-a-prova.md#o-cenário-comum) (a regra das equipes e do Aprendiz)
- [O molde de minigame](molde-de-minigame.md) (já descreve o kit com o que esta ficha põe; ao fim, confira que bate)

## O estado de hoje

**O que a H04 entrega** (confira no código antes de começar — a H04 pode ter
ajustado algo no passo 2 dela):

- `godot/scripts/minigames/minigame.gd`, `class_name Minigame extends SalaJogo`:
  `CHAVES`, `GENEROS`, `FINS`, `CAMERAS`, `MATERIAIS`, `RAIAS`, `Z_JOGADOR`,
  `TOM_DO_LUGAR`, `FALA_S`; `var ficha`; `_init()` (lê a `FICHA` e preenche
  `id`, `nome`, `acao`, `duracao`, `features`, `botoes_pedidos`,
  `gesto_do_aviso`, `com_treino`); `entrar(js)` (chama `conferir_a_ficha()`
  e `super`); `conferir_a_ficha() -> bool`; `comecar()` (`Ritmo.tocar` com a
  faixa da ficha, `Ritmo.dono = id`, `Ritmo.zerar_ajuda()`, `super()`);
  `terminar()` (`Ritmo.parar()` e `super()`); `sair()`; `congelar(sim)`;
  `_process(dt)` (chama `robo(l, dt)` de quem joga, antes do `super`); os
  ganchos `toque`, `falha`, `vencedor`, `robo`; `conectado(l)`,
  `presentes()`, `na_raia(l)`, `raia(l)`, `acender_raia(l, forca)`,
  `posicionar(l)`, `julgar_toque(l, t_alvo, n := -1, perigo := false)`,
  `nota_perdida(l, n)`, `nova_nota(l, n, t_alvo)`, `falar(l, evento)` e
  `_reagir(l, j)` (hoje: `Forja.sentir` e o som `"nota"` na TV).
- `godot/scripts/minigames/catalogo.gd`, `class_name Catalogo`: `SECOES` (cada
  uma com `id`, `nome`, `apelido`, `minigames`), `MINIGAMES`,
  `SALAS_ANTIGAS`, `NOMES_VELHOS`, `resolver(id)`, `existe(id)`,
  `criar(id)`, `apelido(id)`. **Não sorteia**: o apelido abre sempre o
  primeiro da seção.
- `godot/scripts/minigames/s01/martelo_de_hefesto.gd` (`S01_J01`,
  `"icone": "botoes"`, `"duracao": 100.0`, `"fim": "tempo"`) e
  `godot/testes/minigame_de_prova.gd` (`T00_J00`, `"duracao": 0.0`,
  `"fim": "meta_coletiva"`, sem treino).
- `godot/scripts/main.gd`: `_entrar_na_sala(id, com_cortina := true, pronta: Sala = null)`,
  `Catalogo.existe`/`Catalogo.criar` no lugar do `SALAS`.
- `godot/testes/prova_do_jogo.gd`: `_e_a_sala(sala, id)`,
  `_prova_do_catalogo()`, `_prova_do_kit()` e a checagem do registro em
  `_prova_do_relatorio()` que reprova `vencedor < 0`.

**O que a F03, a F05, a G03 e a F02 deixam** (e esta ficha usa):
`SalaJogo.colocacao` (**variável**, preenchida por `vencedor()` no
`terminar()`), `SalaJogo.coop`, `SalaJogo.coop_venceu`, `SalaJogo.t_jogo`, o
fim por tempo `duracao > 0.0 and t_jogo >= duracao` no `_process`, o
`Forja.evento("minigame", ...)` do `terminar()`, `_celebrar()`,
`TelaResultado.abrir(col, pts, eh_coop, venceu, nome)` e a barra do
`painel_sala.gd` `_tempo()` por `t_jogo` (F03); `Forja.SENSACOES`,
`Forja.sentir(l, nome, ms)`, `Forja._agora` e o motor que vence a háptica
(F05); `Itens.pontos_do_acerto(...)`, `Itens.PERFEITO` e `SalaJogo.errou(l)`
(G03); `SalaJogo.icone` (F02, `var icone := ""`).

**O código real que esta ficha muda:**

- **O fim conta no tempo do jogo.** `godot/scripts/salas/sala_jogo.gd:220`
  (a F03 troca `t_fase` por `t_jogo`): `if todos or (duracao > 0.0 and t_fase >= duracao):`.
  O `t_jogo` soma `dt`: com `--fixed-fps 60` sem janela, anda ~16 vezes mais
  depressa que a música.
- **Um nome já ocupado.** `sala_jogo.gd:452` já tem
  `func progresso() -> String` (a linha "onda 1 de 3" do painel,
  `ui/painel_sala.gd:333`), sobrescrita em `impacto.gd:527`, `canto.gd:518`,
  `prova.gd:747`, `voz.gd:555` e em fichas (L3). O `progresso() -> float` do
  13 não pode existir no kit (assinatura diferente da mãe é erro de análise):
  aqui ele se chama **`andamento() -> float`**, e o 13 muda no passo 12.
- **A partida fala por apelido.** `godot/scripts/partida.gd:22-25`:

  ```gdscript
  const NA_ORDEM := {
  	3: ["centelha", "galeria", "prova"],
  	5: ["centelha", "viga", "impacto", "galeria", "prova"],
  }
  ```

  `roteiro()` (`:46`) devolve apelidos, `nova()` (`:65`) os guarda em
  `salas`, `registrar()` (`:108`) tira o nome de `NOMES.get(id, id)` e
  `ui/placar.gd:212` escreve `"a seguir: %s" % Partida.NOMES.get(seguinte, seguinte)`.
  O Canto não está em partida nenhuma (as fichas N trocam `"viga"` por
  `"canto"` à mão para a prova visual).
- **O salão abre pelo apelido.** `godot/scripts/mundo/salao.gd:15-24`,
  `PORTOES` por `id` (`"centelha"`…); `main.gd:674` `_entrar_na_sala(perto)`;
  `main.gd:214` `Musica.tocar(sala_id if qual == "sala" else "salao")` (com um
  slot, `Musica.tocar` não acha a faixa e toca a do salão, `musica.gd:66-67`);
  `main.gd:281` `salao.saida_do_portao(sala_id, p.lugar)`.
- **Os glifos são dois.** `godot/scripts/ui/glifo.gd` desenha em vetor os
  botões das dicas (`"cruz"`, `"circulo"`, `"quadrado"`, `"triangulo"`,
  `"cima"`, `"baixo"`, `"esquerda"`, `"direita"`, `"options"`, `"create"`,
  `"touchpad"`, `"microfone"`, `"l1"`, `"r1"`, `"l2"`, `"r2"`,
  `"analogico_l"`, `"analogico_r"`) — **não** tem `cross` nem `giroscopio`. O
  ícone do aviso é outro: `Desenho.glifo(nome)` (`ui/desenho.gd:24`) carrega
  `res://assets/glifos/<nome>.png`, e a F02 confere com ele. Os nomes que
  existem lá: `acelerometro`, `alto-falante`, `bateria`, `circle`, `cross`,
  `dpad_down`, `dpad_left`, `dpad_right`, `dpad_up`, `giroscopio`, `l1`,
  `l2`, `led-jogador`, `lightbar`, `mic`, `options`, `r1`, `r2`,
  `rumble_direito`, `rumble_esquerdo`, `share`, `square`, `stick_l`,
  `stick_r`, `touchpad`, `triangle`. As fichas escritas usam apelidos da
  parte do controle (`"botoes"` 4×, `"gatilho_adaptativo"` 7×,
  `"alto_falante"` 6×, `"vibracao"` 5×, `"haptica"` 5×, `"microfone"` 5×,
  `"gatilhos"` 1×) que **não** são glifos: o kit traduz (`ICONE_DA_PARTE`).
- **A barra de luz.** `godot/scripts/forja.gd:452`:
  `func luz(l, cor): return ctl.luz(l, cor) if modulo else false` — sem piso,
  sem piscar. O Impacto de hoje desce a 12% (`impacto.gd:180-182`), A Prova a
  6% (`prova.gd:255-264`).
- **O som que o robô ouve.** `forja.gd:801`: `som_virtual(l)` devolve
  `{falante, esq, dir}` (os níveis da placa virtual); não diz **qual** som.
  `forja.gd:777`: `som_falante(l, som, ganho)` devolve o número da voz do
  mixer, ou -1.
- **A música não cala.** `godot/scripts/ritmo.gd` (H01) não tem `calar`;
  `Musica.VOLUME_DB := -9.0` (`musica.gd:25`).
- **A prova do jogo** (`godot/testes/prova_do_jogo.gd`) joga as nove salas do
  percurso inteiras pelo número de quadros (`_termina_a_sala`, `:305-340`,
  até 12 000 quadros) — que, com o fim em tempo de música, não cabem num
  minigame de 90 s. `tests/prova_do_jogo.sh:58-59` não recebe o minigame da
  ficha. As fichas L1, M1, N1… copiam um `_joga_o_minigame(id, limite_s := 60.0, a_cada_quadro)`
  (`L1-o-cerco.md:601`) que espera 60 s de parede — pouco para 90 s de música.
- **Talvez já existam** (confira no passo 1): `Minigame.BATIDA_DA_PRIMEIRA_NOTA`
  e a contagem de entrada (H06); `Minigame._reagir` com
  `Forja.tocar_material`, `COMBO`, `_perfeitos_seguidos` e `Musica.reagir`
  (H07). Esta ficha funciona com e sem elas; os passos dizem o que fazer em
  cada caso.
- Nada do código de "O alvo" foi rodado nesta preparação: cada passo tem a
  sua prova, e o que reprovar se conserta antes de seguir.

## O alvo

(**Novo** no 13, no passo 12: tudo o que está abaixo e não está na seção
H08 dele — `andamento()`, `tempo_jogado()`, `tempo_acabou()`,
`tempo_que_resta()`, `campos_do_fim()`, `frase_do_resultado()`,
`quem_comemora()`, `quem_brilha()`, `julgar_nota`, `notas_em_aberto`,
`alvo_da`, `anotar`, as equipes, `Catalogo.secao/ordem/proximo/titulo`,
`Partida.secoes/nome`, `Forja.luz_com_piso`, `PISO_DA_LUZ`,
`Ritmo.calada()`.)

### `godot/scripts/forja.gd`

Na tabela `SENSACOES` (F05), depois de `"golpe_dir"`:

```gdscript
	# o toque leve de um lado (H08): aponta o lado sem assustar
	"toque_esq": [0.4, 0.0, 80],
	"toque_dir": [0.0, 0.4, 80],
```

A barra de luz: troque `func luz(...)` e `func luz_do_lugar(...)`
(`forja.gd:452-458`) por este bloco inteiro:

```gdscript
# ---------------------------------------------------------------- a barra de luz (H08) --
# A barra de luz nunca fica abaixo de PISO_DA_LUZ de brilho, e um piscar de
# outra cor dura no máximo PISCAR_MAX_S: a cor que o jogo pediu sempre volta
# (docs/jogo/13, a identidade e as decisões comuns).

const PISO_DA_LUZ := 0.3
const PISCAR_MAX_S := 0.5
var _piscar_ate := [0.0, 0.0, 0.0, 0.0]  ## o _agora em que o piscar acaba (0: sem piscar)
## A última cor que o jogo pediu a cada lugar; alfa 0 = a cor do lugar.
var _cor_pedida := [Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]


## A barra de luz do lugar numa cor (com o piso de brilho). Durante um
## piscar, a cor fica guardada e sai quando o piscar acaba.
func luz(l: int, cor: Color) -> bool:
	if not modulo:
		return false
	_cor_pedida[l] = Color(cor.r, cor.g, cor.b, 1.0)
	if _piscar_ate[l] > 0.0:
		return true
	return ctl.luz(l, luz_com_piso(cor, cor_do_lugar(l)))


func luz_do_lugar(l: int) -> bool:
	_cor_pedida[l] = Color(0, 0, 0, 0)
	_piscar_ate[l] = 0.0
	return ctl.luz_do_lugar(l) if modulo else false


## Pisca a barra de luz do lugar em `cor` por `s` segundos (no máximo
## PISCAR_MAX_S); depois, volta a cor que o jogo tinha pedido.
func piscar(l: int, cor: Color, s := 0.15) -> bool:
	if not modulo:
		return false
	_piscar_ate[l] = _agora + clampf(s, 0.0, PISCAR_MAX_S)
	return ctl.luz(l, luz_com_piso(cor, cor_do_lugar(l)))


## A mesma cor com o piso de brilho: abaixo de PISO_DA_LUZ, clareia até ele
## sem mudar o tom; a preta vira a cor do lugar no piso. Pura.
static func luz_com_piso(cor: Color, do_lugar: Color) -> Color:
	var v := maxf(cor.r, maxf(cor.g, cor.b))
	if v >= PISO_DA_LUZ:
		return Color(cor.r, cor.g, cor.b, 1.0)
	if v < 0.001:
		cor = do_lugar
		v = maxf(cor.r, maxf(cor.g, cor.b))
	var k := PISO_DA_LUZ / maxf(v, 0.001)
	return Color(cor.r * k, cor.g * k, cor.b * k, 1.0)


## O piscar acabou: a cor pedida (ou a do lugar) volta. No fim do _process.
func _voltar_a_cor() -> void:
	for l in 4:
		if _piscar_ate[l] <= 0.0 or _agora < _piscar_ate[l]:
			continue
		_piscar_ate[l] = 0.0
		var c: Color = _cor_pedida[l]
		if c.a <= 0.0:
			ctl.luz_do_lugar(l)
		else:
			ctl.luz(l, luz_com_piso(c, cor_do_lugar(l)))
```

No `_process` do `forja.gd` (`:201`), **depois** do `if not modulo: return`
(o `_agora += dt` da F05 fica onde está), a última linha: `_voltar_a_cor()`.
Em `silencio(l)` (`:484`), antes do `ctl.silencio(l)`:
`_cor_pedida[l] = Color(0, 0, 0, 0)` e `_piscar_ate[l] = 0.0`; em
`silencio_todos()`, o mesmo para os quatro.

A textura só na mão, e o último som do alto-falante — na seção do som de
cada controle, troque `som_falante` e `som_virtual` (`:777` e `:801`; se a
H07 mexeu no `som_falante`, mantenha o que ela pôs e só guarde o retorno) e
acrescente `textura`:

```gdscript
var _ultimo_som := ["", "", "", ""]  ## o último som que o alto-falante do lugar aceitou
var _som_seq := [0, 0, 0, 0]  ## quantos sons o alto-falante do lugar já aceitou


## Um som da forja no alto-falante do controle ("sino", "nota:2"...).
func som_falante(l: int, som: String, ganho := 0.9) -> int:
	# o volume do alto-falante do controle (as opções da sessão)
	var r: int = ctl.som_falante(l, som, ganho * Opcoes.volume_controle / 100.0) if modulo else -1
	if r >= 0:
		_ultimo_som[clampi(l, 0, 3)] = som
		_som_seq[clampi(l, 0, 3)] += 1
	return r


## O que a placa virtual do controle simulado do lugar toca agora, 0..1:
## {falante, esq, dir}, e o último som que o alto-falante aceitou ({som,
## som_seq}: o robô ouve a altura). É o que o robô ouve e sente.
func som_virtual(l: int) -> Dictionary:
	var d: Dictionary = ctl.som_virtual(l) if modulo else {}
	if not d.is_empty():
		d["som"] = _ultimo_som[clampi(l, 0, 3)]
		d["som_seq"] = _som_seq[clampi(l, 0, 3)]
	return d


## A textura do material só nos atuadores do lugar — o alto-falante fica
## livre para a pista (docs/jogo/13, as decisões comuns). O gelo é de um
## atuador só. Devolve false sem háptica (o rádio) ou com o motor vibrando
## (F05): quem chama sente pelo rumble.
func textura(l: int, material: String, forca := 1.0) -> bool:
	if not som_tem(l, PAPEL_HAPTICA):
		return false
	var nome := "material:" + material
	return som_haptica(l, nome, "" if material == "gelo" else nome, forca) >= 0
```

(O som `material:<nome>` é da H07, no C. Sem a H07, o C não o conhece,
`som_haptica` devolve -1 e o kit sente pelo rumble: é o certo.)

### `godot/scripts/ritmo.gd`

Ao fim do arquivo:

```gdscript
# ---------------------------------------------------------------- calar (H08) --

var _calada_ate := -1.0  ## a batida em que a música volta (-1: tocando)
var _tw_calar: Tween = null


## A música cala por `batidas` batidas e o relógio segue (o Zero Absoluto): o
## tocador abaixa a -80 dB em 20 ms e volta, também em 20 ms, na batida
## certa. A posição da faixa não para, então t_musica() nem sente. Sem faixa
## tocando, não há o que calar.
func calar(batidas: float) -> void:
	if not is_instance_valid(_tocador) or batidas <= 0.0:
		return
	_calada_ate = batida() + batidas
	_rampa(-80.0)


## A música está calada agora?
func calada() -> bool:
	return _calada_ate >= 0.0


func _rampa(db: float) -> void:
	if _tw_calar:
		_tw_calar.kill()
	if not is_instance_valid(_tocador):
		return
	_tw_calar = create_tween()
	_tw_calar.tween_property(_tocador, "volume_db", db, 0.02)
```

No `_process` do `Ritmo`, logo depois de `_t = maxf(_t, _medir())`:

```gdscript
	if _calada_ate >= 0.0 and batida() >= _calada_ate:
		_calada_ate = -1.0
		_rampa(Musica.VOLUME_DB)
```

E, no começo de `tocar()` e de `parar()`: `_calada_ate = -1.0` e
`if _tw_calar: _tw_calar.kill()`.

### `godot/scripts/salas/sala_jogo.gd`

O relógio da sala vira três funções que o kit troca (acrescente perto do
`terminar()`):

```gdscript
## O tempo que já valeu, em s (o treino fora). O kit troca pelo tempo de
## música (H08): nunca o t_fase, que com --fixed-fps corre mais depressa.
func tempo_jogado() -> float:
	return t_jogo


## O tempo da sala acabou?
func tempo_acabou() -> bool:
	return duracao > 0.0 and tempo_jogado() >= duracao


## O que resta do relógio, em s (a barra do painel e a prova do relógio).
func tempo_que_resta() -> float:
	return maxf(0.0, duracao - tempo_jogado())
```

- no `_process`, o fim por tempo (a linha da F03, perto de `:220`) passa a
  ser `if todos or tempo_acabou():`;
- em `ui/painel_sala.gd` `_tempo()` (a linha da F03 com
  `d - float(sala.t_jogo)`): `var resta := float(sala.tempo_que_resta())`;
- rode `grep -rn "t_jogo" godot/scripts godot/testes`: todo **leitor** do
  relógio da sala (fora a soma do `_process` da `SalaJogo`) passa a
  `tempo_jogado()` ou `tempo_que_resta()` — em especial a checagem da F03
  "o relógio nunca volta a encher", que vira
  `var resta: float = sala.tempo_que_resta()`.

O fim, em três ganchos que o kit troca:

```gdscript
## Os campos do `minigame` `terminou` (o registro v2). O kit acrescenta o
## gênero, o coop e a dupla (H08).
func campos_do_fim() -> Dictionary:
	return {"slot": id, "evento": "terminou", "vencedor": int(colocacao[0]) if not colocacao.is_empty() else -1,
		"pontos": pontos, "duracao": snappedf(tempo_jogado(), 0.1)}


## A frase do resultado no lugar de "P1 venceu!" (vazia: a da tela). O kit
## diz a do coop e a da dupla.
func frase_do_resultado() -> String:
	return ""


## Quem comemora no fim (o gesto): o primeiro colocado.
func quem_comemora() -> Array:
	return [colocacao[0]] if not colocacao.is_empty() else []


## Quem ganha as faíscas no fim: o primeiro colocado (-1: ninguém).
func quem_brilha() -> int:
	return int(colocacao[0]) if not colocacao.is_empty() else -1
```

- no `terminar()`, o `Forja.evento("minigame", 0, {...})` da F03 vira
  `Forja.evento("minigame", 0, campos_do_fim())` — **todo** campo que já
  estava no dicionário (o `itens` da G03, o que mais houver) passa para
  dentro de `campos_do_fim()`;
- o `_celebrar()` da F03 passa a ler os ganchos (o som que já está nele — o
  `"sucesso"` da F03 ou o que a H06 pôs — fica como está):

  ```gdscript
  func _celebrar() -> void:
  	for l in quem_comemora():
  		var p := jogador(int(l))
  		if p:
  			p.gesto("emote-yes", 1.4)
  	var b := quem_brilha()
  	var pb := jogador(b) if b >= 0 else null
  	if pb:
  		Efeitos.faiscas(self, pb.global_position + Vector3(0, 2.2, 0), Forja.cor_do_lugar(b), 40, 1.3)
  	# (o som do fim que já está aqui, sem mudar)
  ```

- se não existir `var icone` (a F02 ainda não entrou), acrescente perto de
  `features`: `var icone := ""  ## o glifo da parte do controle (assets/glifos/); a FICHA.icone, no kit`.

### `godot/scripts/ui/resultado.gd` e `godot/scripts/main.gd` (a frase)

- `TelaResultado`: `var frase := ""  ## a frase do vencedor que o minigame dá (coop, dupla); vazia: a de sempre`;
  `abrir(col, pts, eh_coop := false, venceu := false, nome := "", frase_do_minigame := "")`
  guarda `frase = frase_do_minigame`; no `_draw()`, a linha do vencedor usa
  `frase` quando ela não é vazia (por `Desenho.t`, como o resto) e a de hoje
  ("P%d venceu!", "P%d e P%d empatam!") quando é.
- `main.gd` `_quadro_sala()` (a chamada da F03):
  `resultado.abrir(sj.colocacao, sj.pontos, sj.coop, sj.coop_venceu, sj.nome, sj.frase_do_resultado())`.

### `godot/scripts/minigames/minigame.gd`

**As constantes e as variáveis** — depois das de hoje (`FALA_S`):

```gdscript
# ---------------------------------------------------------------- H08: as decisões comuns --
# docs/jogo/13-arquitetura.md#as-decisões-comuns-dos-minigames--h08

## O teto do minigame, já com o ritmo do nível.
const DURACAO_MAX := 120.0
## A primeira nota vem neste tempo ou depois: os quatro primeiros são a
## contagem de entrada. (Se a H06 já declarou, NÃO declare de novo.)
const BATIDA_DA_PRIMEIRA_NOTA := 4
## Depois disto (s de música além do alvo, já sem a calibração), a nota passou.
const FOLGA_PERDIDA := 0.140
## Até onde um toque procura a nota em aberto, para os dois lados (s de música).
const ALCANCE_DO_TOQUE := 0.5
## A barra de luz no toque julgado: o perfeito pisca branco; o erro escurece a cor do lugar.
const PISCA_PERFEITO_S := 0.15
const PISCA_ERRO_S := 0.5
## A parte do controle (os nomes das fichas) -> o glifo de godot/assets/glifos/.
const ICONE_DA_PARTE := {
	"botoes": "cross", "analogicos": "stick_l", "gatilhos": "l2", "gatilho_adaptativo": "r2",
	"vibracao": "rumble_esquerdo", "haptica": "rumble_direito", "alto_falante": "alto-falante",
	"microfone": "mic", "barra_de_luz": "lightbar",
}
## Os eventos do jogo (o 13) e o que eles aceitam.
const TIPOS_DO_JOGO := ["entrada", "jogo", "pista", "troca", "voz", "estacao"]
const CANAIS_DA_PISTA := ["haptica", "alto_falante", "rumble", "tela"]
const TROCAS := {"giroscopio": "analogico", "haptica": "rumble", "microfone": "sem_microfone", "alto_falante": "tv"}
## As equipes do 2v2: a cor vai no chão e na armadura, nunca na barra de luz.
const BRASA := 0
const MARE := 1
const NOMES_DAS_EQUIPES := ["A Brasa", "A Maré"]
const FRASES_DAS_EQUIPES := ["A Brasa venceu!", "A Maré venceu!"]
const CORES_DAS_EQUIPES := [Color(0.910, 0.639, 0.235), Color(0.184, 0.702, 0.702)]  # #e8a33c, #2fb3b3

var equipe := [-1, -1, -1, -1]  ## lugar -> BRASA, MARE, ou -1 (fora do 2v2)
var aprendizes := [0, 0]  ## quantos Aprendizes completam cada equipe (docs/jogo/tarefas/Q-a-prova.md)
var _pontos_sem_lugar := [0, 0]  ## os pontos da equipe que só tem Aprendizes
var _notas := [{}, {}, {}, {}]  ## lugar -> {n: [t_alvo, perigo]}: as notas em aberto
var _inicio_valendo := -1.0  ## o t_musica em que o jogo passou a valer (-1: ainda não)
var _tempo_final := -1.0  ## o tempo jogado no instante do fim (-1: não acabou)
var _julgando := [-1, -1, -1, -1]  ## o julgamento do toque em curso (o marcar dentro do toque() passa pelo item)
var _tempo_forte := [false, false, false, false]
var _nota_no_falante := true
var _textura_no_acerto := true
```

**`_init()`** — ao fim do de hoje:

```gdscript
	# H08: o que sai da FICHA sem ninguém repetir
	coop = str(ficha.get("genero", "")) == "coop"
	var parte := str(ficha.get("icone", ""))
	icone = str(ICONE_DA_PARTE.get(parte, parte))
	_nota_no_falante = bool(ficha.get("nota_no_falante", true))
	_textura_no_acerto = bool(ficha.get("textura_no_acerto", true))
	if ficha.has("papel_som"):
		papel_som = int(ficha.papel_som)
```

**`conferir_a_ficha()`** — antes do `return ok` final:

```gdscript
	if not ResourceLoader.exists("res://assets/glifos/%s.png" % icone):
		push_error("minigame %s: o ícone «%s» não é um glifo de assets/glifos/ (o molde lista)" % [id, ficha.icone])
		ok = false
	var d := float(ficha.duracao)
	if d > DURACAO_MAX:
		push_error("minigame %s: a duração passa de %d s" % [id, int(DURACAO_MAX)])
		ok = false
	if d <= 0.0 and str(ficha.fim) == "tempo":
		push_error("minigame %s: fim «tempo» sem duração (0.0 só vale para o fim do próprio jogo)" % id)
		ok = false
	if ficha.has("papel_som") and not int(ficha.papel_som) in [Forja.PAPEL_ALTO_FALANTE, Forja.PAPEL_HAPTICA, Forja.PAPEL_MICROFONE]:
		push_error("minigame %s: «papel_som» não é um Forja.PAPEL_*" % id)
		ok = false
```

**`entrar()`** — o de hoje inteiro vira:

```gdscript
func entrar(js: Array) -> void:
	conferir_a_ficha()
	if str(ficha.get("genero", "")) == "2v2":
		# antes do montar(): o chão e a armadura já sabem a equipe
		var lugares: Array = []
		for p in js:
			lugares.append(int(p.lugar))
		montar_equipes(lugares)
	super(js)
	# a SalaJogo multiplicou pelo ritmo do nível; o teto fica
	duracao = minf(duracao, DURACAO_MAX)
```

**`comecar()`** — na primeira linha: `_notas = [{}, {}, {}, {}]`,
`_inicio_valendo = -1.0` e `_tempo_final = -1.0`; e, logo **depois** do
`super()`:

```gdscript
	if not treinando:
		_inicio_valendo = Ritmo.t_musica()
```

**`terminar()`** — logo depois da guarda `if fase == "fim": return`, antes
do `Ritmo.parar()`: `_tempo_final = tempo_jogado()`.

**`_process(dt)`** — dentro do `if not congelada and fase == "jogo":`, como
primeiras linhas:

```gdscript
		if not treinando and _inicio_valendo < 0.0:
			_inicio_valendo = Ritmo.t_musica()  # o treino acabou: daqui vale
```

**O tempo de música** — acrescente:

```gdscript
# ---------------------------------------------------------------- o tempo (H08) --

## O tempo que já valeu (o treino fora), em s de música: com faixa, a placa
## de som; sem faixa, o relógio do sistema — os dois pelo Ritmo. Congela no
## fim e na pausa. O fim da SalaJogo (tempo_acabou) e a barra do painel
## (tempo_que_resta) leem daqui.
func tempo_jogado() -> float:
	if _tempo_final >= 0.0:
		return _tempo_final
	if _inicio_valendo < 0.0:
		return 0.0
	return maxf(0.0, Ritmo.t_musica() - _inicio_valendo)


## 0..1 da duração (0 sem duração: o fim é do próprio jogo). É o `progresso`
## do 13: `progresso()` já é a linha de texto da SalaJogo.
func andamento() -> float:
	return clampf(tempo_jogado() / duracao, 0.0, 1.0) if duracao > 0.0 else 0.0


## O terço do meio da duração: o pico da faixa.
func no_pico() -> bool:
	var a := andamento()
	return a >= 1.0 / 3.0 and a < 2.0 / 3.0
```

**A fila de notas** — acrescente, e troque o `nova_nota`, o `nota_perdida` e
o `julgar_toque` de hoje pelos daqui (se a G03 pôs a Lanterna no
`nova_nota`, mantenha a linha dela):

```gdscript
# ---------------------------------------------------------------- a fila de notas (H08) --

## A próxima batida do lugar **depois** de `desde`, num passo de `passo`
## batidas deslocado de `desloc` (o hoqueto: a vez de cada um), nunca antes de
## BATIDA_DA_PRIMEIRA_NOTA. Quem está na partitura mais simples
## (Ritmo.simples) tem o passo dobrado.
func proxima_batida(l: int, desde: float, passo: float, desloc := 0.0) -> float:
	if Ritmo.simples[l]:
		passo *= 2.0
	passo = maxf(passo, 0.25)
	var k := floorf((desde - desloc) / passo) + 1.0
	return maxf(k * passo + desloc, BATIDA_DA_PRIMEIRA_NOTA + desloc)


## Uma nota nova do lugar: vai para o registro e para a fila das notas em
## aberto (casar_toque, notas_perdidas). `perigo`: a folga de quem está em
## último vale nela (docs/jogo/02#8).
func nova_nota(l: int, n: int, t_alvo: float, perigo := false) -> void:
	_notas[l][n] = [t_alvo, perigo]
	Ritmo.registrar_nota(l, n, t_alvo)


## Os n das notas em aberto do lugar, da mais velha à mais nova.
func notas_em_aberto(l: int) -> Array:
	var r: Array = _notas[l].keys()
	r.sort()
	return r


## O t_alvo da nota n do lugar (-1 se ela não está em aberto).
func alvo_da(l: int, n: int) -> float:
	var nota: Array = _notas[l].get(n, [])
	return float(nota[0]) if not nota.is_empty() else -1.0


## A nota em aberto do lugar mais perto do toque de agora (o toque já
## corrigido pela calibração do lugar), dentro de ALCANCE_DO_TOQUE; -1: nenhuma.
func casar_toque(l: int) -> int:
	var agora := Ritmo.t_musica() - float(Ritmo.desvio[l])
	var melhor := -1
	var perto := ALCANCE_DO_TOQUE
	for n in _notas[l]:
		var d := absf(agora - float(_notas[l][n][0]))
		if d <= perto:
			perto = d
			melhor = int(n)
	return melhor


## Julga o toque de agora contra a nota n do lugar (a da fila) e a fecha.
## -1 se a nota não está em aberto.
func julgar_nota(l: int, n: int) -> int:
	var nota: Array = _notas[l].get(n, [])
	if nota.is_empty():
		return -1
	return julgar_toque(l, float(nota[0]), n, bool(nota[1]))


## As notas do lugar que passaram de FOLGA_PERDIDA (mais a folga de quem está
## em último, nas de perigo) sem toque: saem da fila e cada uma vira
## nota_perdida (o erro, a falha). Sem controle, saem caladas — não é erro de
## quem caiu. Devolve os n que viraram erro.
func notas_perdidas(l: int) -> Array:
	var agora := Ritmo.t_musica() - float(Ritmo.desvio[l])
	var passaram: Array = []
	for n in _notas[l].keys():
		var nota: Array = _notas[l][n]
		var folga := Ritmo.folga_para(l, pontos, presentes()) if bool(nota[1]) else 0.0
		if agora > float(nota[0]) + FOLGA_PERDIDA + folga:
			_notas[l].erase(n)
			passaram.append(int(n))
	if not conectado(l) or not jogando[l] or acabou[l]:
		return []
	passaram.sort()
	for n in passaram:
		nota_perdida(l, n)
	return passaram


## Julga o toque do lugar agora contra a nota em t_alvo (tempo de música) e
## faz o que todo toque julgado faz: fecha a nota n, a folga de quem está em
## último (só se a nota é perigo), o registro, a ajuda, a reação (controle,
## TV, barra de luz) — e chama toque() nos acertos ou falha() no erro. O
## Escudo (G03) absorve o primeiro erro; o Martelo mexe nos pontos que o
## toque() marcar. Devolve o julgamento.
func julgar_toque(l: int, t_alvo: float, n := -1, perigo := false) -> int:
	if n >= 0:
		_notas[l].erase(n)
	var t_toque := Ritmo.t_musica()
	var folga := Ritmo.folga_para(l, pontos, presentes()) if perigo else 0.0
	var j := Ritmo.julgar(l, t_toque, t_alvo, folga)
	Ritmo.registrar_toque(l, n, j, Ritmo.desvio_ms(l, t_toque, t_alvo))
	Ritmo.contar_para_ajuda(l, j)
	_reagir(l, j)
	if j == Ritmo.ERRO:
		if not errou(l):
			falha(l)
		return j
	_julgando[l] = j
	_tempo_forte[l] = _no_tempo_forte(t_alvo)
	toque(l, j)
	_julgando[l] = -1
	return j


## A nota n do lugar passou sem toque: é erro, com a falha física (o Escudo
## absorve o primeiro).
func nota_perdida(l: int, n: int) -> void:
	_notas[l].erase(n)
	Ritmo.registrar_toque(l, n, Ritmo.ERRO)
	Ritmo.contar_para_ajuda(l, Ritmo.ERRO)
	_reagir(l, Ritmo.ERRO)
	if not errou(l):
		falha(l)


## Os pontos de um toque julgado passam pelo item (G03, o Martelo): o
## minigame chama marcar(l, n) dentro do toque() e nunca
## Itens.pontos_do_acerto.
func marcar(l: int, n: int) -> void:
	if _julgando[l] > Ritmo.ERRO and n > 0:
		n = Itens.pontos_do_acerto(l, n, _julgando[l], _tempo_forte[l])
	super(l, n)


## A nota cai no primeiro tempo do compasso (o tempo forte do Martelo)?
func _no_tempo_forte(t_alvo: float) -> bool:
	var b := (t_alvo - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
	var inteira := roundf(b)
	return absf(b - inteira) < 0.05 and posmod(int(inteira), 4) == 0
```

**A reação** — troque o `_reagir` de hoje (o da H04, ou o da H07) inteiro
por este, e acrescente `_musica_reage`:

```gdscript
## O que todo toque julgado faz no controle do dono, na TV e na barra de luz.
## A textura vai só aos atuadores (o alto-falante fica para a nota); a FICHA
## desliga a nota (nota_no_falante) ou a textura (textura_no_acerto) quando
## aquele canal é a pista do minigame.
func _reagir(l: int, j: int) -> void:
	var p := jogador(l)
	var pos := p.global_position + Vector3(0, 1.2, 0) if p else Vector3(RAIAS[l], 1.2, Z_JOGADOR)
	_musica_reage(l, j)  # H07 — sem a H07, apague esta linha e a função
	if j == Ritmo.ERRO:
		Forja.piscar(l, Forja.cor_do_lugar(l).darkened(0.7), PISCA_ERRO_S)
		Forja.sentir(l, "erro")
		if _nota_no_falante:
			Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)
		Som.tocar("falha", pos, -6.0)
		return
	var perfeito := j == Ritmo.PERFEITO
	# o acerto na mão: a textura do material nos atuadores; sem háptica (o rádio), pelo rumble
	if _textura_no_acerto and not Forja.textura(l, str(ficha.material), 1.0 if perfeito else 0.7):
		Forja.sentir(l, "perfeito" if perfeito else "acerto")
	Som.tocar("nota", pos, -4.0 if perfeito else -9.0, TOM_DO_LUGAR[l])
	if perfeito:
		Forja.piscar(l, Color.WHITE, PISCA_PERFEITO_S)
		if _nota_no_falante:
			Forja.som_falante(l, "nota:%d" % l, 0.8)


## A música reage e o combo conta (H07: Musica.reagir, COMBO, _perfeitos_seguidos).
func _musica_reage(l: int, j: int) -> void:
	if j == Ritmo.ERRO:
		_perfeitos_seguidos[l] = 0
		Musica.reagir("erro")
	elif j != Ritmo.PERFEITO:
		_perfeitos_seguidos[l] = 0
	else:
		_perfeitos_seguidos[l] += 1
		if _perfeitos_seguidos[l] >= COMBO:
			_perfeitos_seguidos[l] = 0
			Musica.reagir("combo")
		else:
			Musica.reagir("perfeito")
```

**O fim: coop, dupla, destaque e registro** — acrescente:

```gdscript
# ---------------------------------------------------------------- o fim (H08) --

## Quem jogou melhor: o coop e a dupla mostram (as faíscas) e o registro
## leva. Padrão: o primeiro do vencedor(). O minigame troca quando o critério
## é outro.
func destaque() -> int:
	var v := vencedor()
	return int(v[0]) if not v.is_empty() else -1


## O `minigame` `terminou`: o gênero sempre; no coop, vencedor -1 (todos
## venceram ou todos perderam), coop_venceu e o destaque; na dupla, a equipe.
func campos_do_fim() -> Dictionary:
	var c := super()
	var genero := str(ficha.get("genero", ""))
	c["genero"] = genero
	if coop:
		c["vencedor"] = -1
		c["coop_venceu"] = coop_venceu
		c["destaque"] = destaque()
	elif genero == "2v2":
		c["equipe"] = equipe_vencedora()
		c["equipes"] = equipe.duplicate()
	return c


func frase_do_resultado() -> String:
	if coop:
		return "Todos venceram!" if coop_venceu else "A forja apagou."
	if str(ficha.get("genero", "")) == "2v2":
		var e := equipe_vencedora()
		return "Empate!" if e < 0 else str(FRASES_DAS_EQUIPES[e])
	return super()


func quem_comemora() -> Array:
	if coop:
		return presentes() if coop_venceu else []
	if str(ficha.get("genero", "")) == "2v2":
		var e := equipe_vencedora()
		return da_equipe(e) if e >= 0 else []
	return super()


func quem_brilha() -> int:
	if coop or str(ficha.get("genero", "")) == "2v2":
		return destaque()
	return super()


# ---------------------------------------------------------------- as equipes (H08) --

## As equipes do 2v2 (a regra de docs/jogo/tarefas/Q-a-prova.md): os lugares
## na ordem; os dois primeiros são A Brasa, os dois seguintes A Maré; falta
## gente, o Aprendiz completa (aprendizes[e] diz quantos em cada equipe).
func montar_equipes(lugares: Array) -> void:
	equipe = [-1, -1, -1, -1]
	aprendizes = [0, 0]
	_pontos_sem_lugar = [0, 0]
	var ls := lugares.duplicate()
	ls.sort()
	match ls.size():
		4:
			for i in 4:
				equipe[ls[i]] = BRASA if i < 2 else MARE
		3:
			equipe[ls[0]] = BRASA
			equipe[ls[1]] = BRASA
			equipe[ls[2]] = MARE
			aprendizes = [0, 1]
		2:
			equipe[ls[0]] = BRASA
			equipe[ls[1]] = MARE
			aprendizes = [1, 1]
		1:
			equipe[ls[0]] = BRASA
			aprendizes = [1, 2]


## Os lugares da equipe (sem os Aprendizes).
func da_equipe(e: int) -> Array:
	return range(4).filter(func(l): return equipe[l] == e)


## Os pontos da equipe (os da dupla são os mesmos: marcar_equipe).
func pontos_da_equipe(e: int) -> int:
	var lista := da_equipe(e)
	return int(pontos[lista[0]]) if not lista.is_empty() else int(_pontos_sem_lugar[e])


## Pontos para a equipe inteira: vão para os dois da dupla (o item de quem
## tocou vale uma vez para a equipe). Equipe só de Aprendizes: fica nela.
func marcar_equipe(e: int, n: int) -> void:
	for l in 4:
		if equipe[l] == e and _julgando[l] > Ritmo.ERRO and n > 0:
			n = Itens.pontos_do_acerto(l, n, _julgando[l], _tempo_forte[l])
			break
	var lista := da_equipe(e)
	if lista.is_empty():
		if not treinando:
			_pontos_sem_lugar[e] += n
		return
	for l in lista:
		super.marcar(l, n)


## A equipe que venceu (BRASA ou MARE); -1 no empate.
func equipe_vencedora() -> int:
	var b := pontos_da_equipe(BRASA)
	var m := pontos_da_equipe(MARE)
	if b == m:
		return -1
	return BRASA if b > m else MARE


# ---------------------------------------------------------------- os eventos do jogo (H08) --

## Um evento do jogo (docs/jogo/13, os eventos do jogo), com o slot. `l` é o
## lugar (0..3), ou -1 para o que é do minigame todo. Tipo fora da lista,
## canal de pista ou troca que não existe: push_error, e não grava.
func anotar(tipo: String, l: int, campos := {}) -> void:
	if not tipo in TIPOS_DO_JOGO:
		push_error("minigame %s: o evento «%s» não existe (13, os eventos do jogo)" % [id, tipo])
		return
	if tipo == "pista" and not str(campos.get("canal", "")) in CANAIS_DA_PISTA:
		push_error("minigame %s: pista por um canal que não existe (%s)" % [id, campos.get("canal", "")])
		return
	if tipo == "troca" and str(TROCAS.get(str(campos.get("de", "")), "")) != str(campos.get("para", "")):
		push_error("minigame %s: troca que não existe (%s → %s)" % [id, campos.get("de", ""), campos.get("para", "")])
		return
	var c: Dictionary = campos.duplicate()
	c["slot"] = id
	Forja.evento(tipo, l + 1 if l >= 0 else 0, c)
```

### `godot/scripts/minigames/catalogo.gd`

Ao fim do arquivo:

```gdscript
## A seção do apelido, do id (S01) ou de um slot; {} se não é de seção.
static func secao(id: String) -> Dictionary:
	var chave: String = NOMES_VELHOS.get(id, id)
	for s in SECOES:
		if s.apelido == chave or s.id == chave or chave in s.minigames:
			return s
	return {}


## A ordem da noite dos minigames de uma seção: uma permutação de `lista` pela
## semente e pela seção (Fisher–Yates, a mesma em toda máquina). Pura.
static func ordem(lista: Array, chave: String, semente: int) -> Array:
	var r := lista.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [chave, semente])
	for i in range(r.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp = r[i]
		r[i] = r[k]
		r[k] = tmp
	return r


## O minigame da seção na vez `vez` da noite (0, 1, 2...): nenhum repete até
## os cinco saírem, e a volta seguinte segue a mesma ordem. Seção sem
## minigame ainda: o próprio apelido (a sala de hoje).
static func sortear(apelido: String, semente: int, vez: int) -> String:
	var s := secao(apelido)
	if s.is_empty():
		return str(NOMES_VELHOS.get(apelido, apelido))
	var lista: Array = s.minigames
	if lista.is_empty():
		return str(s.apelido)
	var o := ordem(lista, str(s.apelido), semente)
	return str(o[posmod(vez, o.size())])


## O próximo minigame da seção que ainda não se jogou na noite (`jogados`:
## slot -> true). Os cinco jogados: a ordem recomeça do primeiro.
static func proximo(apelido: String, semente: int, jogados: Dictionary) -> String:
	var s := secao(apelido)
	if s.is_empty() or s.minigames.is_empty():
		return sortear(apelido, semente, 0)
	for vez in s.minigames.size():
		var slot := sortear(apelido, semente, vez)
		if not jogados.has(slot):
			return slot
	return sortear(apelido, semente, 0)


## O título do minigame pela FICHA, sem abrir o minigame; "" se não é minigame.
static func titulo(slot: String) -> String:
	if not MINIGAMES.has(slot):
		return ""
	var f = (MINIGAMES[slot] as Script).get_script_constant_map().get("FICHA", {})
	return str((f as Dictionary).get("titulo", slot))
```

### `godot/scripts/partida.gd`

- `NA_ORDEM` (`:22-25`), e o comentário acima dele:

  ```gdscript
  ## As partidas na ordem, por seção (o apelido). A de cinco tem O Canto (o
  ## alto-falante do controle é do jogo, docs/jogo/13 H08); A Prova sempre no
  ## fim. A de nove é o percurso.
  const NA_ORDEM := {
  	3: ["centelha", "galeria", "prova"],
  	5: ["centelha", "impacto", "canto", "galeria", "prova"],
  }
  ```

- as variáveis: `var secoes: Array = []  ## os apelidos das seções, na ordem (o roteiro)`
  e o comentário de `salas` vira
  `## o que se abre, na ordem: o slot sorteado de cada seção (o apelido, se a seção ainda não tem minigame)`;
- `nova()` inteira:

  ```gdscript
  ## A partida: o roteiro das seções e, de cada uma, o próximo minigame que a
  ## noite ainda não jogou (Catalogo.proximo, pela semente da noite).
  static func nova(n: int, sortear: bool, semente: int, percurso: Array, jogados := {}, semente_da_noite := 0) -> Partida:
  	var p := Partida.new()
  	p.secoes = roteiro(n, sortear, semente, percurso)
  	var ja: Dictionary = jogados.duplicate()
  	for ap in p.secoes:
  		var slot := Catalogo.proximo(str(ap), semente_da_noite, ja)
  		ja[slot] = true
  		p.salas.append(slot)
  	p.sorteada = sortear
  	p.semente = semente
  	return p


  ## O nome de um slot ou de um apelido: o título do minigame, ou o da seção.
  static func nome(id: String) -> String:
  	var t := Catalogo.titulo(id)
  	return t if t != "" else str(NOMES.get(Catalogo.apelido(id), id))
  ```

- `registrar()` (`:108`): `"nome": nome(id)` no lugar de `NOMES.get(id, id)`;
- `ui/placar.gd:212`: `"a seguir: %s" % Partida.nome(seguinte)`.

### `godot/scripts/main.gd`

- junto das variáveis:
  `var jogados_na_noite := {}  ## slot -> true: os minigames que a noite já abriu (o sorteio não repete)`;
- em `_entrar_na_sala`, dentro do `feito`, logo depois de `sala = ...`:
  `_marcar_jogado(sala.id)`;
- a função nova:

  ```gdscript
  ## O minigame entrou na noite. Os da seção todos jogados: a volta recomeça
  ## (sem o que acabou de sair, para não repetir em seguida).
  func _marcar_jogado(slot: String) -> void:
  	var s := Catalogo.secao(slot)
  	if s.is_empty() or not slot in s.minigames:
  		return
  	jogados_na_noite[slot] = true
  	for m in s.minigames:
  		if not jogados_na_noite.has(m):
  			return
  	for m in s.minigames:
  		jogados_na_noite.erase(m)
  	jogados_na_noite[slot] = true
  ```

- o portão (`:674`): `_entrar_na_sala(Catalogo.proximo(perto, Forja.semente, jogados_na_noite))`;
- a partida (`:384`):
  `partida = Partida.nova(n, sorteada, Forja.semente + _partidas, ORDEM_DO_FOGO, jogados_na_noite, Forja.semente)`;
- `_mostrar` (`:214`): `Musica.tocar(Catalogo.apelido(sala_id) if qual == "sala" else "salao")`;
- `_ir_para_o_salao` (`:281`): `salao.saida_do_portao(Catalogo.apelido(sala_id), p.lugar)`.

(`--sala=<apelido>` e a Prova de Fogo continuam abrindo o n.º1 da seção por
`Catalogo.resolver`: são da bancada, e o n.º1 é o que mede.)

### `godot/testes/minigame_de_tempo.gd`

O minigame de prova da H08 (fora do jogo e da exportação, como o da H04). O
arquivo inteiro:

```gdscript
extends Minigame
## O minigame de tempo da H08 (fica em testes/: não entra no jogo nem na
## exportação). Coop de 90 s na trilha d'A Centelha: cada lugar tem a sua nota
## a cada dois tempos, no hoqueto (meio tempo de um para o outro), pela fila
## de notas do kit. O robô de cada lugar mira um desvio: P1 no tempo, P2 nunca
## aperta (as notas passam), P3 atrasado (bom), P4 adiantado (ótimo). No tempo
## 40, a música cala por quatro tempos e o relógio segue. Prova que o fim conta
## em tempo de música, que a fila casa e perde, que o coop fecha com vencedor
## -1 e destaque, e que os seis eventos do jogo vão para o registro.

const FICHA := {
	"slot": "T00_J01",
	"titulo": "A Forja de Todos",
	"verbo": "Juntos!",
	"genero": "coop",
	"icone": "botoes",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S01_J01",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro"],
	"material": "metal",
	"microjogo": {"verbo": "Juntos!", "segundos": 6.0},
	"treino": false,
}
const PASSO := 2.0  ## uma nota a cada dois tempos
const A_FRENTE := 2  ## quantas notas de cada lugar ficam na fila
const NUNCA := 99.0
const MIRA := [0.0, NUNCA, 0.110, -0.070]  ## o desvio que o robô de cada lugar mira, em s
const PONTOS := [0, 1, 2, 3]  ## ERRO, BOM, OTIMO, PERFEITO
const META := 20  ## perfeitos da equipe para todos vencerem
const CALA_NA_BATIDA := 40.0
const CALA_POR := 4.0

var contagem := [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]  ## [lugar][julgamento]
var perdidas := [0, 0, 0, 0]
var sem_nota := [0, 0, 0, 0]  ## toques que não acharam nota em aberto
var calou := false
var _n := [0, 0, 0, 0]  ## o número da última nota de cada lugar
var _b := [0.0, 0.0, 0.0, 0.0]  ## a batida da última nota de cada lugar
var _robo_apertou := [-1, -1, -1, -1]
var _robo_nota := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 12.0)
	camera_olhar = Vector3(0, 0.8, 0)
	Kit.arena(self, 5, 3)
	luzes([Vector3(-6, 3.0, 3), Vector3(6, 3.0, 3)])
	for p in jogadores:
		raia(p.lugar)
		posicionar(p.lugar)


func iniciar_jogo() -> void:
	for p in jogadores:
		_encher(p.lugar)
	# um de cada evento do jogo, para a prova do registro
	anotar("estacao", -1, {"nome": "a forja", "evento": "comecou"})
	anotar("jogo", -1, {"o": "brasa", "calor": 0})
	anotar("pista", 0, {"canal": "tela", "o": "nota"})
	anotar("troca", 3, {"de": "haptica", "para": "rumble"})
	anotar("voz", 1, {"nivel": 0.0, "limiar": 0.5})
	anotar("entrada", 2, {"o": "botao", "chegou": "cross"})


func jogar(_dt: float) -> void:
	if not calou and Ritmo.batida() >= CALA_NA_BATIDA:
		calou = true
		Ritmo.calar(CALA_POR)
	var perfeitos := 0
	for p in jogadores:
		var l: int = p.lugar
		perfeitos += int(contagem[l][Ritmo.PERFEITO])
		if not conectado(l):
			notas_perdidas(l)  # saem caladas: não é erro de quem caiu
			continue
		if Forja.apertou(l, Forja.CRUZ):
			var n := casar_toque(l)
			if n >= 0:
				contagem[l][julgar_nota(l, n)] += 1
			else:
				sem_nota[l] += 1
		perdidas[l] += notas_perdidas(l).size()
		_encher(l)
		var abertas := notas_em_aberto(l)
		var perto := not abertas.is_empty() and absf(Ritmo.t_musica() - alvo_da(l, abertas[0])) < 0.15
		acender_raia(l, 1.0 if perto else 0.15)
	coop_venceu = perfeitos >= META


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])
	var p := jogador(l)
	if p:
		p.gesto("attack-melee-right", 0.3)


func falha(l: int) -> void:
	var p := jogador(l)
	if p:
		p.gesto("emote-no", 0.4)


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	if MIRA[l] == NUNCA:
		return
	var abertas := notas_em_aberto(l)
	if abertas.is_empty():
		return
	var n: int = abertas[0]
	if _robo_apertou[l] == n:
		return
	if _robo_nota[l] != n:
		# o temperamento (--robo=bom|medio|ruim): quando não acerta, aperta tarde demais
		_robo_nota[l] = n
		_robo_mira[l] = MIRA[l] if Forja.robo_acerta() else 0.25
	if Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]):
		Forja.robo_apertar(l, Forja.CRUZ, 0.05)
		_robo_apertou[l] = n


## Mantém A_FRENTE notas do lugar na fila, no hoqueto (meio tempo por lugar).
func _encher(l: int) -> void:
	while notas_em_aberto(l).size() < A_FRENTE:
		_b[l] = proxima_batida(l, maxf(float(_b[l]), Ritmo.batida()), PASSO, 0.5 * l)
		_n[l] += 1
		nova_nota(l, _n[l], Ritmo.t_da_batida(_b[l]))
```

### `tests/prova_do_jogo.sh`

O minigame da ficha entra pela variável `SALA` (o slot, ou o apelido):

- depois de `FALHAS=0`:

  ```bash
  # O minigame da ficha: SALA=S04_J16 bash tests/prova_do_jogo.sh joga ele
  # inteiro, em tempo de música (os 45 inteiros são do gauntlet e da prova visual).
  SALA="${SALA:-}"
  FICHA_ARG=()
  [ -n "$SALA" ] && FICHA_ARG=("--ficha=$SALA")
  ```

- na linha do Godot, depois de `--relatorios="$rel"`:
  `${FICHA_ARG[@]+"${FICHA_ARG[@]}"}` (a forma que o `set -u` aceita com a
  lista vazia);
- o `echo` final ganha `${SALA:+ e o minigame $SALA}` depois de "as salas".

### `godot/testes/prova_do_jogo.gd`

(As funções estão em "Provas"; aqui, onde entram.)

- `var slot_da_ficha := ""` junto de `var pasta`; no `_ready`, no laço dos
  argumentos: `if a.begins_with("--ficha="): slot_da_ficha = a.substr(8)`;
- `_prova_das_decisoes()` em `_ready()`, logo depois de `_prova_do_catalogo()`;
- `_joga_a_sala(id, features)` ganha o caminho curto dos minigames (o
  percurso não joga 90 s de cada um: isso é da prova da ficha e do gauntlet);
- `await _prova_do_tempo_de_musica()` no percurso, logo depois de
  `await _prova_do_kit()`;
- `await _prova_da_ficha(slot_da_ficha)` em `_ready()`, depois de
  `await _prova_da_partida()` (e das que vierem depois dela), antes do
  veredito final, quando `slot_da_ficha != ""`;
- em `_prova_do_relatorio()`, as checagens do registro;
- se já existir um `_joga_o_minigame` (alguma ficha de seção chegou antes),
  troque-o pelo daqui.

### `godot/testes/checagens_visuais.gd` (F09)

`fim_sem_vencedor(linha_do_tempo)`: um `minigame` `terminou` com
`vencedor` -1 **e** `"genero": "coop"` não é fim sem vencedor.

### `godot/scripts/traducoes.gd`

`"Todos venceram!": "Everyone won!"`, `"A forja apagou.": "The forge went out."`,
`"A Brasa venceu!": "The Ember won!"`, `"A Maré venceu!": "The Tide won!"`,
`"Empate!": "Draw!"`, `"A Forja de Todos": "Everyone's Forge"`,
`"Juntos!": "Together!"`.

## Passos

Rode `bash tests/prova_do_jogo.sh` no fim de todo passo marcado **(prova)**.
Reprovou: conserte antes de seguir. A prova fica uns 3 min mais longa
(o minigame de tempo, 90 s em cada uma das duas rodadas).

1. **Antes de tudo (prova).** A prova verde. As dependências, uma linha
   cada — faltou alguma, pare e diga qual:
   `grep -n "func julgar_toque" godot/scripts/minigames/minigame.gd` (H04),
   `grep -n "func sentir\|var _agora" godot/scripts/forja.gd` (F05),
   `grep -n "static func pontos_do_acerto" godot/scripts/itens.gd` e
   `grep -n "func errou" godot/scripts/salas/sala_jogo.gd` (G03),
   `grep -n "var coop\|var t_jogo\|var colocacao\|func _celebrar" godot/scripts/salas/sala_jogo.gd` (F03),
   `grep -n "func t_da_batida\|func julgar\|func folga_para" godot/scripts/ritmo.gd` (H01, H02).
   E anote o que já existe (muda o que se faz depois):
   - `grep -n "BATIDA_DA_PRIMEIRA_NOTA" godot/scripts/minigames/minigame.gd` —
     com a H06, não declare a constante de novo;
   - `grep -n "func reagir" godot/scripts/musica.gd` — sem a H07, apague do
     `_reagir` a linha `_musica_reage(l, j)` e a função `_musica_reage`;
   - `grep -n "var icone" godot/scripts/salas/sala_jogo.gd` — sem a F02,
     acrescente a variável (em "O alvo");
   - `grep -n '"minigame"' godot/scripts/salas/sala_jogo.gd godot/scripts/minigames/minigame.gd`
     — o `minigame` `terminou` tem de ser gravado **só** na `SalaJogo` (o
     passo 2 da H04); se o kit ainda grava o dele, leve os campos para o
     `campos_do_fim()` do kit e apague a gravação do kit;
   - `grep -n "func colocacao" godot/scripts/minigames/minigame.gd` — a H04
     escreveu `func colocacao()`, mas a F03 tem `var colocacao`: se a função
     ainda está lá, apague-a (o kit sobrescreve só `vencedor()`) e troque
     `mg.colocacao()` por `mg.colocacao` na prova.
2. **`godot/scripts/forja.gd`**: `toque_esq`/`toque_dir`, o bloco da barra
   de luz, o `_voltar_a_cor()` no `_process`, o `silencio`, `som_falante`,
   `som_virtual` e `textura`. **(prova)** — e `bash tests/prova_da_bancada.sh`:
   o piso muda o brilho do Impacto e d'A Prova de hoje (ver "Armadilhas").
3. **`godot/scripts/ritmo.gd`**: `calar`, `calada`, `_rampa`, a volta no
   `_process` e o reinício em `tocar()`/`parar()`. **(prova)**
4. **`godot/scripts/salas/sala_jogo.gd`**, `ui/painel_sala.gd`,
   `ui/resultado.gd`, `main.gd` (`_quadro_sala`): o relógio em três funções,
   o `campos_do_fim`, a frase, `quem_comemora`/`quem_brilha`, e os leitores
   de `t_jogo` (o `grep`). **(prova)** — nada muda ainda para quem joga.
5. **O percurso curto, antes do kit mudar.** Em `godot/testes/prova_do_jogo.gd`:
   `_passa_pelo_minigame(id)`, `_volta_ao_salao(rotulo)` e o começo novo do
   `_joga_a_sala` (em "Provas"). **(prova)** — A Centelha agora passa pelo
   caminho curto no percurso. (Sem este passo, o passo 6 reprova: o
   Martelo passa a durar 100 s de verdade, e `_termina_a_sala` espera
   quadros.)
6. **`godot/scripts/minigames/minigame.gd`**: as constantes e variáveis, o
   `_init`, o `conferir_a_ficha`, o `entrar`, o `comecar`, o `terminar`, o
   `_process`, o tempo, a fila de notas (com o `julgar_toque`, o
   `nota_perdida` e o `nova_nota` novos, e o `marcar`), a reação, o fim, as
   equipes e o `anotar`. Importe
   (`"$GODOT" --headless --path godot --import --quit`). **(prova)** — o
   minigame de prova da H04 continua dando os quatro julgamentos.
7. **`catalogo.gd`, `partida.gd`, `main.gd`, `ui/placar.gd`**: o sorteio, a
   partida de slots com O Canto, o portão e o apelido na música e na volta
   ao salão. **(prova)** — a partida de 3 da prova abre `S01_J01` na
   Centelha (o `_e_a_sala` aceita pelo apelido).
8. **`godot/testes/minigame_de_tempo.gd`**: crie, e importe (o `.uid`).
9. **A prova**: `_prova_das_decisoes()`, `_joga_o_minigame(...)`,
   `_mesmo_tom` (se faltar), `_prova_do_tempo_de_musica()`,
   `_prova_da_ficha(...)` com `_confere_os_vereditos(...)`, as checagens do
   registro, e `tests/prova_do_jogo.sh` com `SALA`. **(prova)** e depois
   `SALA=S01_J01 bash tests/prova_do_jogo.sh` (o Martelo inteiro, com os três
   vereditos, em uns 100 s de música por rodada).
10. **`checagens_visuais.gd`** (F09): o coop com -1 aceito.
11. **`traducoes.gd`**: as sete frases.
12. **O 13**, na seção "As decisões comuns dos minigames — H08":
    - `progresso() -> float` vira `andamento() -> float` ("`progresso()` já é
      a linha de texto da `SalaJogo`");
    - "O ícone da FICHA é o nome de um glifo de `godot/scripts/ui/glifo.gd`
      (`cross`, …)" vira "…de `godot/assets/glifos/` (o que
      `Desenho.glifo` carrega; `cross`, `giroscopio`, `touchpad`…); os nomes
      da parte do controle (`botoes`, `haptica`…) o kit traduz
      (`Minigame.ICONE_DA_PARTE`)";
    - "`Partida.NA_ORDEM` inclui o Canto" ganha "na de cinco, no lugar d'A Viga";
    - o Aprendiz: "Com 3 jogadores, o terceiro entra como o Aprendiz na
      equipe que perdeu a rodada anterior" vira a tabela de
      [Q](Q-a-prova.md#o-cenário-comum) (3: Brasa 1º e 2º, Maré 3º e o
      Aprendiz; 2: cada um com um Aprendiz; 1: o 1º com um Aprendiz contra
      dois), que é o que o kit faz;
    - o que está marcado **novo** em "O alvo"; na tabela do registro v2, a
      linha `minigame` ganha `genero`, `coop_venceu`, `destaque`, `equipe`,
      `equipes`, e as seis linhas `entrada`, `jogo`, `pista`, `troca`, `voz`,
      `estacao` (com `slot`);
    - na seção do kit, `julgar_toque` cita `errou(l)` (o Escudo) e o
      `marcar` do kit (o Martelo).
13. **O molde**: confira que [o molde](molde-de-minigame.md) bate com o kit
    que ficou (cada nome de função, de constante e de chave). Não bateu, o
    molde muda.
14. **A prova visual** (F09): `bash tests/prova_visual.sh`, e olhe a prancha
    das partidas de 5 (O Canto está nelas agora). **(prova)** no fim.

### Os dois acréscimos decididos depois da harmonização

- **A luz de repouso.** No kit: `func luz_de_repouso(l: int) -> Color: return Forja.cor_do_lugar(l)`,
  e o `_reagir` volta a barra a ela (não à cor cheia do lugar) depois do
  piscar. O minigame que carrega estado na barra sobrescreve, mantendo a cor
  do lugar e mudando só o brilho (piso de 30%). As fichas L1, L5, O2, O4 e P3
  repõem o brilho à mão 0,5 s depois: com este gancho, troque por
  `luz_de_repouso` quando executar essas fichas.
- **O destaque no 2v2** sai de `acertos[l]`, não de `pontos[l]`, porque
  `marcar_equipe` iguala os pontos da dupla.

## Armadilhas

- **`progresso` não.** A `SalaJogo` já tem `progresso() -> String`;
  redeclarar com `-> float` é erro de análise. O do kit é `andamento()`.
- **Constante repetida é erro.** `BATIDA_DA_PRIMEIRA_NOTA` pode já estar no
  kit (H06); `COMBO` e `_perfeitos_seguidos` são da H07. Declare só o que
  falta.
- **`var colocacao` × `func colocacao()`.** A F03 pôs a variável na
  `SalaJogo`; um método com o mesmo nome no kit não compila. O kit
  sobrescreve só `vencedor()`.
- **O percurso não joga os minigames inteiros.** Com o fim em tempo de
  música, o Martelo leva 100 s de verdade; `_termina_a_sala` espera
  quadros (~12 s de parede) e reprovaria. O caminho curto força o
  `terminar()` depois de 1,5 s de jogo — é a prova que força, não o jogo
  (nenhum argumento encurta sala, [paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08) regra 7).
- **Espera por fase em quadros, por música em relógio de parede.** O
  `_joga_o_minigame` espera o aviso em quadros e o jogo em
  `Time.get_ticks_usec()`, e sobe o limite sozinho para a duração + 45 s
  (as fichas passam 60 s: com 90 s de música, não caberia).
- **O treino não conta.** O tempo de música começa quando o treino acaba
  (`_inicio_valendo`); com `"treino": false`, no `comecar()`.
- **O `andamento()` congela no fim** (`_tempo_final`): depois do
  `Ritmo.parar()`, o `t_musica()` segue pelo relógio do sistema.
- **O piso da luz muda salas de hoje.** O Impacto desce a 12% e A Prova pisca
  entre 25% e 6%: com o piso, as duas ficam em 30% no fundo e o pulso d'A
  Prova some. É a regra (13, F04); as fichas L e Q refazem essas luzes. Se a
  prova da bancada reprovar pelo **brilho** (o veredito comparando o que
  pediu com o que chegou), pare e anote — não afrouxe a checagem.
- **O `Forja.luz` durante um piscar** guarda a cor e devolve `true`; ela
  sai quando o piscar acaba (no máximo 0,5 s). Quem mede a saída pela linha
  do tempo (F06) vê a cor no instante em que saiu.
- **O piscar conta pelo `_agora` da F05** (o tempo do jogo, em quadros), como
  o motor: com `--fixed-fps 60`, 0,15 s são 9 quadros.
- **A nota de quem caiu** sai calada da fila (`notas_perdidas` devolve `[]`
  sem controle): nada de erro, nada de falha.
- **O Escudo no kit.** `julgar_toque` e `nota_perdida` chamam `errou(l)`
  (G03) antes de `falha(l)`: o primeiro erro de quem leva o Escudo não tem
  falha física. O toque continua registrado como erro.
- **O Martelo só dentro do `toque()`.** O `marcar` do kit aplica
  `Itens.pontos_do_acerto` enquanto `_julgando[l]` está aceso (só durante o
  `toque(l, j)` que o `julgar_toque` chama). Ponto marcado fora do toque (o
  fim de uma rodada) não passa pelo item — é o certo.
- **`som_virtual` sem módulo** devolve `{}` (sem `som`): quem lê usa
  `.get("som", "")`.
- **`Ritmo.calar` sem faixa** não faz nada: com `"faixa": ""`, não há música
  para calar (e o relógio, que é o do sistema, segue).
- **O sorteio é da noite, não da partida.** A semente do sorteio é
  `Forja.semente` (a mesma para o portão e para a partida); a da partida
  (`Forja.semente + _partidas`) só embaralha as seções.
- **`hash()` de texto é o mesmo em toda máquina** (o `sala_jogo.gd:82` já
  usa para a variante); não troque por `randi()` solto.
- **`.uid`**: o `minigame_de_tempo.gd.uid` entra no commit.

## Não fazer

- Não mudar a regra de minigame nenhum (nem do Martelo, nem do minigame de
  prova da H04): esta ficha é do kit.
- Não pôr `Forja.robo`, `--fixed-fps` ou caminho de prova no kit, no
  `Ritmo`, no `Forja` nem no `Catalogo`.
- Não mudar a conta da noite no coop (a `Partida` continua pela colocação
  nos pontos) nem inventar o Aprendiz (o boneco é da ficha [Q](Q-a-prova.md)).
- Não aplicar a Lanterna (`Itens.janela_perfeito`) nem o Diapasão
  (`Itens.ganho_da_nota`) no kit: pedem mudar o `Ritmo.julgar` e o som da
  nota, e não estão no 13.
- Não mexer no C: `material:<nome>`, `nota:<lugar>` e `nota_quebrada:<lugar>`
  são da H07.
- Não tirar do percurso as salas de hoje (elas continuam inteiras) nem
  apagar as fichas de seção que já escreveram o seu `_joga_o_minigame`.

## Pronto quando

Um minigame de 90 s dura ~90 s de parede com `--fixed-fps 60` e acaba sem
`"duracao": 0.0`; a FICHA com fim `tempo` sem duração, com mais de 120 s ou
com ícone que não é glifo falha alto; o ícone chega a `SalaJogo.icone`; o
sorteio não repete até os cinco e o portão abre o próximo da seção; a
partida de 5 tem O Canto e guarda slots; a fila de notas casa, perde e
esquece a nota de quem caiu; a barra de luz pisca branco no perfeito e
escurece no erro, nunca abaixo de 30%, e a cor volta; o coop fecha com
vencedor -1 e destaque, a dupla com "A Brasa venceu!"; os seis eventos do
jogo vão ao registro com o slot; `Ritmo.calar` cala e o relógio segue;
`bash tests/prova_do_jogo.sh` e `SALA=S01_J01 bash tests/prova_do_jogo.sh`
passam; e `bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

**Na sessão:**

```bash
bash tests/prova_do_jogo.sh
SALA=S01_J01 bash tests/prova_do_jogo.sh
bash tests/prova_da_bancada.sh
bash tests/prova_visual.sh
```

As funções novas em `godot/testes/prova_do_jogo.gd`:

```gdscript
## As decisões comuns (H08), puras: o sorteio, o portão, a partida de slots
## com O Canto, o ícone, o piso da luz, as sensações de um lado, o hoqueto,
## as equipes e o coop.
func _prova_das_decisoes() -> void:
	# o sorteio: cinco sem repetir, a mesma semente dá a mesma ordem
	var cinco := ["A", "B", "C", "D", "E"]
	var o := Catalogo.ordem(cinco, "viga", 7)
	var unicos := {}
	for s in o:
		unicos[s] = true
	_esperar(unicos.size() == 5 and o == Catalogo.ordem(cinco, "viga", 7),
		"sorteio: os cinco saem sem repetir, e a mesma semente dá a mesma ordem (%s)" % [o])
	var outra := false
	for semente in range(1, 20):
		outra = outra or Catalogo.ordem(cinco, "viga", semente) != o
	_esperar(outra, "sorteio: outra semente, outra ordem")
	for s in Catalogo.SECOES:
		var ms: Array = s.minigames
		if ms.is_empty():
			_esperar(Catalogo.sortear(s.apelido, 7, 3) == s.apelido, "sorteio: %s sem minigame abre a sala de hoje" % s.apelido)
			continue
		var saidos := {}
		for vez in ms.size():
			saidos[Catalogo.sortear(s.apelido, 7, vez)] = true
		_esperar(saidos.size() == ms.size(), "sorteio: %s dá os %d sem repetir" % [s.apelido, ms.size()])
		_esperar(Catalogo.sortear(s.apelido, 7, ms.size()) == Catalogo.sortear(s.apelido, 7, 0), "sorteio: %s, a volta segue a mesma ordem" % s.apelido)
		var jogados := {}
		for k in ms.size():
			var p := Catalogo.proximo(s.apelido, 7, jogados)
			_esperar(not jogados.has(p) and p in ms, "portão de %s: o %dº é um que ainda não saiu (%s)" % [s.apelido, k + 1, p])
			jogados[p] = true
	# a partida guarda slots, e a de cinco tem O Canto
	var ordem: Array = jogo.ORDEM_DO_FOGO
	var p5 := Partida.nova(5, false, 7, ordem)
	_esperar(p5.secoes == ["centelha", "impacto", "canto", "galeria", "prova"], "partida de 5: com O Canto (%s)" % [p5.secoes])
	var casam := p5.salas.size() == 5
	for i in p5.salas.size():
		casam = casam and Catalogo.apelido(p5.salas[i]) == p5.secoes[i] and Catalogo.existe(p5.salas[i])
	_esperar(casam, "partida: um slot por seção, e todos abrem (%s)" % [p5.salas])
	_esperar(Partida.nome("centelha") == "A Centelha" and Partida.nome(Catalogo.resolver("centelha")) == Catalogo.titulo(Catalogo.resolver("centelha")),
		"partida: o nome é o título do minigame, ou o da seção")
	# o ícone é um glifo de assets/glifos, e o kit o copia
	for parte in Minigame.ICONE_DA_PARTE:
		_esperar(ResourceLoader.exists("res://assets/glifos/%s.png" % Minigame.ICONE_DA_PARTE[parte]), "ícone: «%s» vira um glifo que existe" % parte)
	for slot in Catalogo.MINIGAMES:
		var m: Minigame = Catalogo.MINIGAMES[slot].new()
		_esperar(Desenho.glifo(m.icone) != null, "ícone: %s mostra «%s» no aviso" % [slot, m.icone])
		m.free()
	# o piso da luz: o mesmo tom, nunca abaixo de 30%
	var escura := Forja.luz_com_piso(Color(0.1, 0.05, 0.0), Color.RED)
	_esperar(is_equal_approx(maxf(escura.r, maxf(escura.g, escura.b)), Forja.PISO_DA_LUZ) and is_equal_approx(escura.g / escura.r, 0.5),
		"luz: a cor escura clareia até o piso sem mudar o tom (%s)" % escura)
	_esperar(Forja.luz_com_piso(Color.BLACK, Color(0.0, 0.5, 1.0)).is_equal_approx(Color(0.0, 0.15, 0.3)), "luz: a preta vira a cor do lugar no piso")
	_esperar(Forja.luz_com_piso(Color(0.8, 0.2, 0.1), Color.RED).is_equal_approx(Color(0.8, 0.2, 0.1)), "luz: acima do piso, nada muda")
	_esperar(Forja.SENSACOES.get("toque_esq", []) == [0.4, 0.0, 80] and Forja.SENSACOES.get("toque_dir", []) == [0.0, 0.4, 80],
		"sensações: o toque leve de cada lado")
	# o hoqueto e a partitura mais simples
	var mg: Minigame = load("res://testes/minigame_de_prova.gd").new()
	var guardado: Array = Ritmo.simples.duplicate()
	Ritmo.simples = [false, false, false, false]
	_esperar(mg.proxima_batida(1, 4.0, 2.0, 0.5) == 4.5 and mg.proxima_batida(1, 4.5, 2.0, 0.5) == 6.5,
		"hoqueto: a próxima vez do P2 vem depois, meio tempo deslocada")
	_esperar(mg.proxima_batida(0, 0.0, 2.0) == float(Minigame.BATIDA_DA_PRIMEIRA_NOTA), "hoqueto: nunca antes da contagem de entrada")
	Ritmo.simples[2] = true
	_esperar(mg.proxima_batida(2, 4.0, 2.0, 1.0) == 5.0 and mg.proxima_batida(2, 5.0, 2.0, 1.0) == 9.0, "hoqueto: na partitura simples, o passo dobra")
	Ritmo.simples = guardado
	# as equipes (a tabela de Q) e a frase da dupla
	mg.montar_equipes([0, 1, 2, 3])
	_esperar(mg.equipe == [0, 0, 1, 1] and mg.aprendizes == [0, 0], "equipes com quatro: P1 e P2 A Brasa, P3 e P4 A Maré")
	mg.montar_equipes([0, 2, 3])
	_esperar(mg.equipe == [0, -1, 0, 1] and mg.aprendizes == [0, 1], "equipes com três: o Aprendiz completa A Maré")
	mg.montar_equipes([1])
	_esperar(mg.equipe == [-1, 0, -1, -1] and mg.aprendizes == [1, 2], "equipes com um: um Aprendiz com ele, dois na Maré")
	mg.montar_equipes([0, 1, 2, 3])
	mg.ficha["genero"] = "2v2"
	mg.marcar_equipe(Minigame.MARE, 5)
	_esperar(mg.pontos == [0, 0, 5, 5] and mg.equipe_vencedora() == Minigame.MARE and mg.frase_do_resultado() == "A Maré venceu!",
		"dupla: os pontos vão para os dois, e a tela diz a equipe (%s)" % [mg.pontos])
	_esperar(int(mg.campos_do_fim().get("equipe", -9)) == Minigame.MARE, "dupla: o registro leva a equipe")
	# o coop: vencedor -1 e a frase
	mg.ficha["genero"] = "coop"
	mg.coop = true
	mg.coop_venceu = false
	_esperar(int(mg.campos_do_fim().get("vencedor", 0)) == -1 and mg.frase_do_resultado() == "A forja apagou.",
		"coop: o vencedor é -1, e a tela diz que a forja apagou")
	mg.free()


## Um minigame no percurso: abre pelo apelido, o aviso passa e o jogo começa
## no relógio da faixa; a prova força o fim (jogar 90 s de verdade é da prova
## da ficha, SALA=<slot>, e do gauntlet). Confere o fechamento e a volta.
func _passa_pelo_minigame(id: String) -> void:
	var sala = await _comeca_a_sala(id)
	if sala == null:
		return
	_esperar(sala is Minigame and Ritmo.dono == sala.id, "%s: o minigame %s joga no relógio da faixa" % [id, sala.id])
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(sala) and sala.fase == "jogo" and Time.get_ticks_usec() - inicio < 1500000:
		await _quadros(1)
	if is_instance_valid(sala) and sala.fase == "jogo":
		sala.terminar()
	await _quadros(2)
	_esperar(is_instance_valid(sala) and sala.fase == "fim", "%s: fechou" % id)
	await _volta_ao_salao(id)


func _volta_ao_salao(rotulo: String) -> void:
	var q := 0
	while (jogo.estado != "salao" or jogo._trocando) and q < 900:
		await _quadros(5)
		q += 5
	_esperar(jogo.estado == "salao", "%s: de volta ao salão" % rotulo)
```

O começo novo do `_joga_a_sala` (o resto fica):

```gdscript
func _joga_a_sala(id: String, features: Array) -> void:
	if Catalogo.MINIGAMES.has(Catalogo.resolver(id)):
		await _passa_pelo_minigame(id)
		return
	var sala = await _comeca_a_sala(id)
	if sala:
		await _termina_a_sala(sala, features)
```

O jogo inteiro de um minigame (o que as fichas de seção usam):

```gdscript
## Abre o minigame pelo catálogo — o mesmo caminho do --sala=<slot> —, deixa
## o aviso passar (em quadros) e o jogo correr até o fim (pelo relógio de
## parede: o fim é em tempo de música). O limite sobe sozinho para a duração
## + 45 s. `a_cada_quadro` recebe o minigame a cada quadro da fase jogo.
## Confere o que todo minigame deve: fechou, com vencedor (-1 só no coop), e,
## no fim por tempo, a duração em tempo de música. Devolve o minigame, ou null.
func _joga_o_minigame(id: String, limite_s := 60.0, a_cada_quadro := Callable()) -> Minigame:
	jogo._entrar_na_sala(id, false)
	await _quadros(2)
	var mg = jogo.sala
	_esperar(mg is Minigame and mg.fase == "aviso", "%s: abriu pelo catálogo" % id)
	if not mg is Minigame:
		return null
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	var limite := maxf(limite_s, float(mg.duracao) + 45.0) if mg.duracao > 0.0 else limite_s
	var inicio := Time.get_ticks_usec()
	var valendo := -1
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < int(limite * 1e6):
		if valendo < 0 and not mg.treinando:
			valendo = Time.get_ticks_usec()
		if a_cada_quadro.is_valid():
			a_cada_quadro.call(mg)
		await _quadros(1)
	var nome: String = mg.id if is_instance_valid(mg) else id
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "%s: acabou (%.1f s)" % [nome, (Time.get_ticks_usec() - inicio) / 1e6])
	if not is_instance_valid(mg):
		return null
	var v := int(mg.campos_do_fim().get("vencedor", -1))
	_esperar(v >= 0 or (mg.coop and v == -1), "%s: fechou com vencedor (%d%s)" % [nome, v, ", coop" if mg.coop else ""])
	if str(mg.ficha.get("fim", "")) == "tempo" and mg.duracao > 0.0 and valendo > 0:
		var parede := (Time.get_ticks_usec() - valendo) / 1e6
		_esperar(absf(parede - mg.duracao) <= mg.duracao * 0.1 + 1.0,
			"%s: %.0f s de música em %.1f s de parede (o fim conta em tempo de música)" % [nome, mg.duracao, parede])
	return mg


## O minigame da ficha (SALA=<slot> no tests/prova_do_jogo.sh). Cada ficha de
## minigame acrescenta a sua linha no match, com a checagem dela; sem linha,
## o jogo inteiro com as checagens de todo minigame.
func _prova_da_ficha(slot: String) -> void:
	_esperar(Catalogo.existe(slot), "SALA=%s: está no catálogo" % slot)
	if not Catalogo.existe(slot):
		return
	match slot:
		"S01_J01", "centelha":
			var mg := await _joga_o_minigame("centelha")
			if mg:
				_confere_os_vereditos(mg, ["botoes", "analogicos", "gatilhos_analogicos"])
		# "S04_J16": await _prova_do_cerco()   ← o modelo: uma linha por ficha
		_:
			await _joga_o_minigame(slot)
	await _volta_ao_salao(slot)


## Os vereditos da bancada que o minigame (o n.º1 da seção) deu a cada lugar,
## calculados e gravados também fora do Modo bancada (F01).
func _confere_os_vereditos(mg: Minigame, features: Array) -> void:
	for l in mg.presentes():
		for f in features:
			var v := {}
			for item in mg.vereditos.get(l, []):
				if item.get("feature", "") == f:
					v = item
			_esperar(int(v.get("resultado", -1)) == Forja.PASSOU,
				"%s P%d: %s → %s" % [mg.id, l + 1, f, str(v.get("rotulo", "sem veredito"))])
```

(O `_termina_a_sala` não serve aqui: a F03 pôs nele o `get_meta("fim")`,
que só o `_comeca_a_sala` grava.)

O minigame de tempo:

```gdscript
## A mesma cor, com outro brilho. (Se a F04 já pôs _mesmo_tom, use a dela.)
func _mesmo_tom(a: Color, b: Color) -> bool:
	var ma := maxf(a.r, maxf(a.g, a.b))
	var mb := maxf(b.r, maxf(b.g, b.b))
	if ma < 0.01 or mb < 0.01:
		return false
	return absf(a.r / ma - b.r / mb) < 0.08 and absf(a.g / ma - b.g / mb) < 0.08 and absf(a.b / ma - b.b / mb) < 0.08


## O fim em tempo de música (H08): o minigame de tempo (godot/testes/
## minigame_de_tempo.gd) dura 90 s de música — ~90 s de parede, com o jogo
## correndo muito mais depressa —; a fila casa e perde; a barra de luz pisca
## e escurece sem passar do piso; a música cala e o relógio segue; o coop fecha
## com vencedor -1; o som que o robô ouve tem nome, e a textura não passa
## pelo alto-falante.
func _prova_do_tempo_de_musica() -> void:
	var mg: Minigame = load("res://testes/minigame_de_tempo.gd").new()
	jogo._entrar_na_sala(mg.id, false, mg)
	await _quadros(2)
	_esperar(jogo.sala == mg and mg.fase == "aviso" and mg.icone == "cross" and mg.coop, "tempo de música: abriu, coop, com o glifo da parte (%s)" % mg.icone)
	var q := 0
	while is_instance_valid(mg) and mg.fase == "aviso" and q < 900:
		await _quadros(1)
		q += 1
	var inicio := Time.get_ticks_usec()
	var quadros := 0
	var abaixo_do_piso := 0
	var viu_branco := false
	var viu_escuro := false
	var branco_seguido := 0
	var branco_max := 0
	var viu_pico := false
	var andamento_antes := 0.0
	var voltou := false
	var calou_em := -1.0
	var calada_ok := true
	var calada_s := 0.0
	var som_testado := false
	while is_instance_valid(mg) and mg.fase == "jogo" and Time.get_ticks_usec() - inicio < 150000000:
		quadros += 1
		for l in mg.presentes():
			var c: Color = _perc(l).get("luz", Color.BLACK)
			if maxf(c.r, maxf(c.g, c.b)) < Forja.PISO_DA_LUZ - 0.02:
				abaixo_do_piso += 1
			if l == 0:
				var branco := c.is_equal_approx(Color.WHITE)
				viu_branco = viu_branco or branco
				branco_seguido = branco_seguido + 1 if branco else 0
				branco_max = maxi(branco_max, branco_seguido)
			if l == 1 and _mesmo_tom(c, Forja.cor_do_lugar(1)) and maxf(c.r, maxf(c.g, c.b)) < 0.45:
				viu_escuro = true
		viu_pico = viu_pico or mg.no_pico()
		voltou = voltou or mg.andamento() < andamento_antes - 0.0001
		andamento_antes = mg.andamento()
		if Ritmo.calada():
			if calou_em < 0.0:
				calou_em = Ritmo.t_musica()
			elif Ritmo.t_musica() - calou_em > 0.1 and is_instance_valid(Ritmo._tocador):
				calada_ok = calada_ok and Ritmo._tocador.volume_db < -60.0
		elif calou_em >= 0.0 and calada_s == 0.0:
			calada_s = Ritmo.t_musica() - calou_em
		if not som_testado and Time.get_ticks_usec() - inicio > 5000000 and Forja.som_tem(0, Forja.PAPEL_ALTO_FALANTE):
			som_testado = true
			var antes := int(Forja.som_virtual(0).get("som_seq", 0))
			Forja.som_falante(0, "sino", 0.3)
			var d := Forja.som_virtual(0)
			_esperar(str(d.get("som", "")) == "sino" and int(d.get("som_seq", 0)) == antes + 1,
				"som virtual: o robô ouve qual som saiu (%s)" % [d])
			Forja.textura(0, "metal")
			_esperar(int(Forja.som_virtual(0).get("som_seq", 0)) == antes + 1, "textura: não passa pelo alto-falante")
		await _quadros(1)
	var parede := (Time.get_ticks_usec() - inicio) / 1e6
	print("tempo de música: %d quadros (%.0f s de jogo) em %.1f s de parede" % [quadros, quadros / 60.0, parede])
	_esperar(is_instance_valid(mg) and mg.fase == "fim", "tempo de música: acabou pelo relógio da faixa")
	if not is_instance_valid(mg):
		return
	_esperar(absf(parede - 90.0) <= 9.0, "tempo de música: 90 s de minigame em %.1f s de parede, com --fixed-fps 60" % parede)
	_esperar(viu_pico and not voltou and is_equal_approx(mg.andamento(), 1.0), "tempo de música: o andamento sobe até 1, e o pico passou no meio")
	# a fila de notas: casa e perde
	var esperado := [Ritmo.PERFEITO, -1, Ritmo.BOM, Ritmo.OTIMO]
	for l in [0, 2, 3]:
		var c: Array = mg.contagem[l]
		var julgadas := int(c[0]) + int(c[1]) + int(c[2]) + int(c[3])
		_esperar(julgadas >= 30 and int(c[esperado[l]]) * 10 >= julgadas * 7,
			"fila P%d: %s em %d de %d notas casadas %s" % [l + 1, Ritmo.NOMES_DO_JULGAMENTO[esperado[l]], int(c[esperado[l]]), julgadas, c])
	var c2: Array = mg.contagem[1]
	_esperar(int(c2[0]) + int(c2[1]) + int(c2[2]) + int(c2[3]) == 0 and int(mg.perdidas[1]) >= 20,
		"fila P2: sem toque, %d notas passaram e viraram erro" % int(mg.perdidas[1]))
	_esperar(mg.sem_nota == [0, 0, 0, 0], "fila: todo toque achou a sua nota (%s)" % [mg.sem_nota])
	# a barra de luz
	_esperar(abaixo_do_piso == 0, "luz: nunca abaixo de 30%% (%d amostras abaixo)" % abaixo_do_piso)
	_esperar(viu_branco and branco_max <= int(Forja.PISCAR_MAX_S * 60.0) + 2, "luz: o perfeito pisca branco e volta (%d quadros no máximo)" % branco_max)
	_esperar(viu_escuro, "luz: o erro escurece a cor do P2, no mesmo tom")
	# a música cala e o relógio segue
	if Forja.modulo:
		var quatro := 4.0 * 60.0 / Ritmo.bpm
		_esperar(mg.calou and calada_ok and absf(calada_s - quatro) < 0.3,
			"calar: a música calou %.2f s (quatro tempos são %.2f s) e o relógio seguiu" % [calada_s, quatro])
	# o coop fecha com vencedor -1 e destaque
	var fim := mg.campos_do_fim()
	_esperar(int(fim.get("vencedor", 0)) == -1 and int(fim.get("destaque", -1)) >= 0 and fim.get("genero", "") == "coop",
		"coop: vencedor -1, destaque P%d (%s)" % [int(fim.get("destaque", -1)) + 1, fim])
	_esperar(mg.frase_do_resultado() == ("Todos venceram!" if mg.coop_venceu else "A forja apagou."), "coop: a frase do resultado")
	await _volta_ao_salao("tempo de música")
```

Em `_prova_do_relatorio()`, no laço da linha do tempo que a H04 pôs
(`julgamentos`, `sem_vencedor`, `terminados`), junte:

```gdscript
	# (antes do laço)
	var tipos_do_jogo := {}
	var coop_fim := {}
	# (dentro do laço, para cada `ev`)
			if ev.get("slot", "") == "T00_J01" and ev.get("tipo", "") in Minigame.TIPOS_DO_JOGO:
				tipos_do_jogo[ev.tipo] = true
			if ev.get("tipo", "") == "minigame" and ev.get("evento", "") == "terminou" and ev.get("slot", "") == "T00_J01":
				coop_fim = ev
	# (depois do laço)
	_esperar(tipos_do_jogo.size() == Minigame.TIPOS_DO_JOGO.size(),
		"registro: os seis eventos do jogo, com o slot (%s)" % [tipos_do_jogo.keys()])
	_esperar(int(coop_fim.get("vencedor", 0)) == -1 and coop_fim.get("genero", "") == "coop" and int(coop_fim.get("destaque", -1)) >= 0,
		"registro: o coop terminou com vencedor -1 e destaque (%s)" % [coop_fim])
```

e, na checagem da H04, o vencedor -1 do coop passa:

```gdscript
				if int(ev.get("vencedor", -1)) < 0 and ev.get("genero", "") != "coop":
					sem_vencedor.append(ev)
```

(O `_prova_do_relatorio()` roda depois do percurso: o minigame de tempo já
gravou. Se a F03 tem outra checagem de "terminou com vencedor", ela aceita
o -1 do coop do mesmo jeito.)

**Com o André, local:** ver abaixo.

## Para o André (local)

```bash
scripts/gauntlet.sh
bash tests/prova_de_poucos.sh
./run-local.sh -- --partida=5
./run-local.sh -- --sala=centelha
```

- A prova de poucos e o gauntlet ficam mais longos: o Martelo agora dura os
  100 s da música, com dois, com um e com quatro.
- Na partida de 5, O Canto aparece (no lugar d'A Viga), e o placar diz "a
  seguir: <o título do minigame>".
- Com o controle na mão, no Martelo: o perfeito pisca a barra de luz de
  branco, rápido; o erro a escurece na sua cor por meio segundo; ela nunca
  apaga. Diga se o piscar incomoda ou some.
- No salão, entre duas vezes no mesmo portão quando a seção tiver mais de um
  minigame: o segundo é outro.
- Na prova visual da sua máquina, olhe as pranchas das partidas de 5.

## Ao terminar

- No [quadro](README.md), acrescente a linha da H08 depois da H07
  (`| [H08](H08-os-acrescimos-do-kit.md) | H | Os acréscimos do kit | G | 4,0 | feito (<commit>) | <gasto> |`),
  some os US$ 4,0 na linha da soma (H passa a 24,0 e o total a 122,5) e diga em "A ordem" que
  as seções (I a Q) dependem da H08.
- Commit sugerido (sem trailer):
  `feat: os acréscimos do kit — o fim em tempo de música, o sorteio dos cinco, a fila de notas e a luz que reage`
