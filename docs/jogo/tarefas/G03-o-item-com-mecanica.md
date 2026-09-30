# G03 — O item com mecânica

**Sprint:** G · **Tamanho:** M · **Estimativa:** US$ 3,0 · **Depende de:** F00, F05, F06, G02 · **Usado por:** H04 (o kit chama o `Itens` no julgamento)

## Por quê

O item escolhido na construção hoje é só enfeite; cada um passa a ser um
poder pequeno que se vê nas costas, se sente no gatilho e vai para o
registro, com a mesma regra nos 45 minigames.

## Ler antes

- [O item tem mecânica](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica) (a tabela dos seis)
- [O item — G03](../13-arquitetura.md#o-item--g03) e [o kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04) (quem chama)
- [As regras de coerência](../11-arte-e-personagens.md#as-regras-de-coerência) (as peças 3D)

## O estado de hoje

- `godot/scripts/player.gd`: a G02 deixou `ITENS` com o índice da mecânica
  (0 "Mãos livres", 1 "Martelo", 2 "Escudo", 3 "Fole", 4 "Lanterna",
  5 "Diapasão", 6 "Âncora"), cada um com `"icone"`, **sem peça 3D**;
  `_segurar()` só prende peças de mão (`"direita"`/`"esquerda"`), que ninguém
  mais usa; `POSE_DO_ITEM` (32-38) sobrou.
- `godot/scripts/ui/tela_lobby.gd`: a G02 deixou `_sentir_o_item(l)` só com
  `Forja.sentir(l, "toque")`, e `_forjou(l)` grava o cavaleiro.
- `godot/scripts/salas/sala_jogo.gd`: `entrar()` (79-97), `comecar()`
  (282-293), `marcar(lugar, n)` (402-414), `terminar()` (317-333). Não há
  gancho de erro; cada sala zera o próprio combo. Em
  `godot/scripts/salas/centelha.gd`, o botão errado (266-269:
  `e.combo = 0`, `e.tremor = 0.6`, o som `"falha"`) e `_perdeu()` (349-356:
  `e.combo = 0`, `e.tremor = 1.0`, `"falha"`, `emote-no`).
- `sala_jogo.gd:111-115`, `maos_livres(p)`: a sala tira o item **visual**
  (`p.visual(p.modelo_i, 0)`) e devolve na saída. A mecânica não pode morar
  no `item_i` do boneco.
- Os gatilhos: só a Galeria (`galeria.gd:188-194`), A Prova
  (`prova.gd:235-237, 301`) e a bancada usam `Forja.gatilho`. As provas
  conferem o R2 solto (`0x05`) no salão e depois de cada sala
  (`godot/testes/prova_do_jogo.gd:271, 334`) e o L2 solto na Galeria (130).
- Não existe `godot/scripts/itens.gd`. O [13](../13-arquitetura.md#o-item--g03)
  lista a API; ela precisa de um ajuste (passo 1).

## O alvo

### A classe `Itens` (`godot/scripts/itens.gd`, `class_name Itens extends RefCounted`, estática)

```gdscript
enum { NENHUM, MARTELO, ESCUDO, FOLE, LANTERNA, DIAPASAO, ANCORA }
## O julgamento, na numeração do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const PERFEITO := 3
## O item de cada lugar, para a mecânica (a construção escreve; a sala não mexe).
static var escolhido := [NENHUM, NENHUM, NENHUM, NENHUM]
static var _escudo := [true, true, true, true]

static func do_lugar(l: int) -> int
## Martelo: o perfeito no tempo forte vale o dobro; o acerto fora do tempo forte, 85%.
static func pontos_do_acerto(l: int, pontos: int, julgamento: int, no_tempo_forte: bool) -> int
## Escudo: true na primeira vez em cada minigame (e o escudo quebra).
static func absorve_erro(l: int) -> bool
static func escudo_inteiro(l: int) -> bool
## Escudo: começa o minigame sem o bônus de entrada do combo.
static func combo_inicial(l: int, normal: int) -> int
## Fole: depois de um erro, o combo volta na metade dos acertos; o teto é 3/4.
static func acertos_para_voltar_o_combo(l: int, normal: int) -> int
static func combo_maximo(l: int, normal: int) -> int
## Lanterna: a pista chega meio tempo antes; a janela perfeito encolhe 10 ms.
static func antecipacao_s(l: int, bpm: float) -> float
static func janela_perfeito(l: int, janela: Vector2) -> Vector2
## Diapasão: a nota mais alta e o perfeito que puxa o combo da equipe — nunca no "tct".
static func ganho_da_nota(l: int, genero: String) -> float
static func puxa_o_combo_da_equipe(l: int, genero: String) -> bool
## Âncora: resiste a empurrão (0..1 do empurrão que ele NÃO sofre) e anda 10% mais devagar na corrida.
static func resiste_a_empurrao(l: int) -> float
static func velocidade(l: int, genero: String) -> float
## O gatilho do item: Escudo inteiro firme no L2; Âncora, peso leve no L2; os outros, L2 solto.
static func sentir(l: int) -> void
static func novo_minigame() -> void          # repõe o Escudo dos quatro
static func registrar(l: int, efeito: String) -> void
```

Os números (a tabela de [06b](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica)):

| função | o item | valor | os outros |
| --- | --- | --- | --- |
| `pontos_do_acerto` | MARTELO | `pontos * 2` com `julgamento == PERFEITO and no_tempo_forte`; `int(round(pontos * 0.85))` com `not no_tempo_forte` | `pontos` |
| `absorve_erro` | ESCUDO | `true` se `_escudo[l]`; põe `_escudo[l] = false`, `registrar(l, "absorveu")` | `false` |
| `combo_inicial` | ESCUDO | `0` | `normal` |
| `acertos_para_voltar_o_combo` | FOLE | `int(ceil(normal / 2.0))` | `normal` |
| `combo_maximo` | FOLE | `int(normal * 3 / 4)` | `normal` |
| `antecipacao_s` | LANTERNA | `30.0 / bpm` | `0.0` |
| `janela_perfeito` | LANTERNA | `Vector2(janela.x + 0.005, janela.y - 0.005)` | `janela` |
| `ganho_da_nota` | DIAPASAO, `genero != "tct"` | `1.3` | `1.0` |
| `puxa_o_combo_da_equipe` | DIAPASAO, `genero in ["2v2", "coop"]` | `true` | `false` |
| `resiste_a_empurrao` | ANCORA | `0.5` | `0.0` |
| `velocidade` | ANCORA, `genero == "corrida"` | `0.9` | `1.0` |

`sentir(l)`: ESCUDO com `_escudo[l]` → `Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 1, 5)`;
ANCORA → `Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 2)`; senão
`Forja.gatilho(l, 0, Forja.GATILHO_OFF)`. **Só o L2** (lado 0): o R2 é das salas
e das provas.

`registrar(l, efeito)`:
`Forja.evento("item", l + 1, {"item": ForjaPlayer.ITENS[do_lugar(l)].nome, "efeito": efeito})`
e `Forja.registrar("P%d: %s %s" % [l + 1, nome, efeito])`. Os efeitos:
`"leva"` (ao entrar num minigame), `"absorveu"`, `"quebrou"`, e os do kit
(`"dobrou"`, `"antecipou"`, `"puxou"`, `"resistiu"`) quando a H04 chamar.

### A peça nas costas (`godot/scripts/player.gd`)

`_segurar()` passa a prender **uma** peça no osso `torso`, num
`BoneAttachment3D` chamado `"Item"`, atrás do corpo (−z), feita de caixas
(`Kit.caixa`) e do kit. Materiais foscos (`metallic` ≤ 0,2):
`ferro = Kit.material(Color("#5b6275"), 0.0, 0.6)`,
`madeira = Kit.material(Color("#8a5a33"), 0.0, 0.85)`,
`couro = Kit.material(Color("#4a3426"), 0.0, 0.9)`,
`claro = Kit.material(Color("#c8ccda"), 0.0, 0.5)`.

| item | peça (posições no espaço do osso `torso`) |
| --- | --- |
| Martelo | `Kit.martelo(presa, 0.45)` em `(0.06, 0.02, -0.14)`, `rotation_degrees = Vector3(0, 0, 35)` |
| Escudo | `Kit.peca(presa, "shield-round", Vector3(0, 0.05, -0.15), PI, 0.7)` |
| Fole | tábuas `(0.16, 0.20, 0.03)` em `(0, 0.02, -0.14)` e `(0, 0.02, -0.19)` de madeira; o couro `(0.14, 0.18, 0.05)` em `(0, 0.02, -0.165)`; o bico `(0.03, 0.08, 0.03)` de ferro em `(0, -0.11, -0.165)` |
| Lanterna | a armação `(0.10, 0.14, 0.10)` de ferro em `(0.08, 0.0, -0.15)`; a chama `(0.07, 0.09, 0.07)` com `Kit.material(Tema.LARANJA, 1.5)` no mesmo centro; a alça `(0.06, 0.02, 0.02)` em `(0.08, 0.08, -0.15)` |
| Diapasão | as hastes `(0.02, 0.16, 0.02)` de claro em `(±0.03, 0.05, -0.15)`; a base `(0.08, 0.02, 0.02)` em `(0, -0.03, -0.15)`; o cabo `(0.02, 0.08, 0.02)` em `(0, -0.08, -0.15)` |
| Âncora | a haste `(0.025, 0.2, 0.025)` de ferro em `(0, 0, -0.16)`; a travessa `(0.1, 0.02, 0.02)` em `(0, 0.07, -0.16)`; os braços `(0.07, 0.02, 0.02)` em `(±0.04, -0.09, -0.16)` com `rotation.z = ∓0.6` |
| Mãos livres | nada |

`POSE_DO_ITEM` e o código de `"direita"`/`"esquerda"` saem. `_segurar()`
apaga só os `BoneAttachment3D` que não começam com `"Peca"` (a regra da G02).

### Onde o item age hoje (sem o kit)

| onde | o quê |
| --- | --- |
| `TelaLobby._sentir_o_item(l)` | `Itens.escolhido[l] = jogadores[l].item_i` e `Itens.sentir(l)`; mais `Forja.sentir(l, "toque")` |
| `TelaLobby._forjou(l)` e o cavaleiro guardado em `abrir()` | `Itens.escolhido[l] = jogadores[l].item_i` |
| `main.gd`, `_todos_entram()` (os argumentos `--sala`, `--partida`…) | `Itens.escolhido[l] = jogadores[l].item_i` de cada lugar ocupado |
| `SalaJogo.entrar()` | `Itens.novo_minigame()`; para cada jogador, `Itens.registrar(l, "leva")` |
| `SalaJogo.comecar()` | se `not usa_gatilho`: `Itens.sentir(l)` para cada jogador |
| `SalaJogo.errou(l) -> bool` (novo) | o erro de um lugar; devolve `true` se o Escudo absorveu (a sala então não quebra o combo nem pune) |
| A Centelha | o botão errado e `_perdeu()` perguntam `errou(l)` antes de zerar o combo |

`SalaJogo` ganha `var usa_gatilho := false`; `galeria.gd`, `prova.gd` e
`bancada.gd` põem `true` no `_init()` (ou onde já montam `features`).

```gdscript
## Um erro do lugar. Devolve true se o item absorveu (o Escudo): aí a sala não
## quebra o combo nem pune; o escudo quebra, o gatilho afrouxa e o som diz.
func errou(l: int) -> bool:
	if treinando or not Itens.absorve_erro(l):
		return false
	Som.no_controle(l, "escudo", 0.8)
	Som.tocar("escudo", jogador(l).global_position + Vector3(0, 1.2, 0), -4.0)
	Forja.sentir(l, "golpe")
	if not usa_gatilho:
		Itens.sentir(l)   # o escudo quebrado solta o L2
	Itens.registrar(l, "quebrou")
	return true
```

(`Itens.absorve_erro` já registrou `"absorveu"`.)

Na Centelha, `centelha.gd:266`:

```gdscript
		if pedido >= 0:
			if errou(l):
				return
			e.combo = 0
			…
```

e no começo de `_perdeu(l, p)`: `if errou(l): _proxima(l); return` (a runa
passa sem castigo — confira que `_proxima` é o que avança a fila).

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3, 5 e 6.

1. **O 13 primeiro:** trocar o bloco de código de
   [O item — G03](../13-arquitetura.md#o-item--g03) pela API do alvo
   (acima) e a frase "o item visual e o de mecânica são o mesmo índice" por:
   "o índice é o mesmo; a mecânica lê `Itens.escolhido`, porque a sala pode
   tirar o item **visual** (`maos_livres`)". Tirar `ajustar_julgamento`
   (o Martelo mexe nos pontos, não no julgamento). No mesmo bloco do kit, a
   linha de `julgar_toque` passa a citar `Itens.janela_perfeito`,
   `Itens.pontos_do_acerto`, `Itens.absorve_erro` e `Itens.ganho_da_nota`.
2. **`godot/scripts/itens.gd` (novo):** a classe inteira; rodar
   `"$GODOT" --headless --path godot --import --quit` e commitar o
   `itens.gd.uid`.
3. **`godot/scripts/player.gd`:** a peça nas costas em `_segurar()`; sair
   `POSE_DO_ITEM`.
4. **`godot/scripts/ui/tela_lobby.gd` e `godot/scripts/main.gd`:** as linhas
   de `Itens.escolhido` e `Itens.sentir` da tabela; no main, ao sair do lobby,
   `Forja.gatilhos_off(l)` nos quatro já existe desde a G02 — confira.
5. **`godot/scripts/salas/sala_jogo.gd`:** `usa_gatilho`, `errou()`, e as
   chamadas em `entrar()` e `comecar()`; `galeria.gd`, `prova.gd`,
   `bancada.gd` com `usa_gatilho = true`.
6. **`godot/scripts/salas/centelha.gd`:** os dois `errou(l)`.
7. **A prova** (ver Provas).

## Armadilhas

- **`.uid`** do `itens.gd`: importar e commitar.
- **`Itens.escolhido`, não `jogadores[l].item_i`:** a sala troca o item
  visual (`maos_livres`); a mecânica tem de seguir o que foi escolhido na
  construção.
- **O R2 é das provas:** o item só mexe no L2. A prova confere o R2 solto
  (`0x05`) no salão e depois de cada sala.
- **`Forja.silencio(l)`** no `terminar()` e no `sair()` da sala já solta os
  gatilhos: não repita.
- **Salas às cegas:** não ponha `errou()` no Impacto, na Galeria, no Canto,
  nos Caminhos nem n'A Voz — a medida delas não pode mudar por item; o kit
  (H04) e as seções levam o item a elas.
- **Treino:** `errou()` não gasta o Escudo no treino (`treinando`).
- **O robô:** nenhum `Forja.robo` aqui.
- **As peças 3D** passam pelo [checklist](../11-arte-e-personagens.md#o-checklist-de-aprovação):
  foscas, em blocos; o único brilho é a chama da Lanterna.

## Não fazer

- Não mexer em `julgar`, janelas ou relógio (H01, H02): o `Itens` só
  responde; quem pergunta é o kit (H04).
- Não mostrar o item no HUD (é a G04, que já conta com `Itens.escudo_inteiro`).
- Não balancear pela noite: os números são os da tabela; a noite de seis
  horas (S) mede.
- Não usar a barra de luz para o item.

## Pronto quando

Cada um dos seis itens tem a peça nas costas e o efeito da tabela na classe
`Itens`; o Escudo absorve o primeiro erro de cada sala na Centelha e firma o
L2 enquanto inteiro; o registro mostra o item de cada lugar ao entrar numa
sala e cada vez que o Escudo agiu.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função nova chamada no `_ready()`
logo depois de `_prova_das_contas_da_partida()`:

```gdscript
## As contas dos seis itens, sem sala (como as da partida).
func _prova_das_contas_dos_itens() -> void:
	var antes: Array = Itens.escolhido.duplicate()
	Itens.escolhido = [Itens.MARTELO, Itens.ESCUDO, Itens.FOLE, Itens.LANTERNA]
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, true) == 200, "Martelo: o perfeito no tempo forte vale o dobro")
	_esperar(Itens.pontos_do_acerto(0, 100, Itens.PERFEITO, false) == 85, "Martelo: fora do tempo forte, 85%")
	_esperar(Itens.pontos_do_acerto(1, 100, Itens.PERFEITO, true) == 100, "sem Martelo, os pontos não mudam")
	Itens.novo_minigame()
	_esperar(Itens.absorve_erro(1) and not Itens.absorve_erro(1), "Escudo: absorve o primeiro erro, só ele")
	_esperar(not Itens.escudo_inteiro(1), "Escudo: quebrou")
	Itens.novo_minigame()
	_esperar(Itens.escudo_inteiro(1), "Escudo: inteiro de novo no minigame seguinte")
	_esperar(not Itens.absorve_erro(0), "sem Escudo, nada se absorve")
	_esperar(Itens.acertos_para_voltar_o_combo(2, 10) == 5 and Itens.combo_maximo(2, 20) == 15, "Fole: volta na metade, teto de 3/4")
	_esperar(is_equal_approx(Itens.antecipacao_s(3, 120.0), 0.25), "Lanterna: meio tempo antes")
	_esperar(Itens.janela_perfeito(3, Vector2(-0.040, 0.060)).is_equal_approx(Vector2(-0.035, 0.055)), "Lanterna: o perfeito encolhe 10 ms")
	Itens.escolhido = [Itens.DIAPASAO, Itens.ANCORA, Itens.NENHUM, Itens.NENHUM]
	_esperar(is_equal_approx(Itens.ganho_da_nota(0, "coop"), 1.3) and is_equal_approx(Itens.ganho_da_nota(0, "tct"), 1.0), "Diapasão: nada no todos contra todos")
	_esperar(Itens.puxa_o_combo_da_equipe(0, "2v2") and not Itens.puxa_o_combo_da_equipe(0, "tct"), "Diapasão: puxa o combo só em equipe")
	_esperar(is_equal_approx(Itens.resiste_a_empurrao(1), 0.5) and is_equal_approx(Itens.velocidade(1, "corrida"), 0.9), "Âncora: resiste e anda mais devagar")
	Itens.escolhido = antes
```

E dentro do percurso, logo depois de `_esperar(jogo.estado == "salao", "com os quatro forjados, …")`:

```gdscript
	for l in 4:
		_esperar(Itens.escolhido[l] == jogo.jogadores[l].item_i and Itens.escolhido[l] >= 1,
			"P%d: a mecânica leva o item escolhido (%d)" % [l + 1, Itens.escolhido[l]])
		var esqueleto: Skeleton3D = jogo.jogadores[l].modelo.find_child("Skeleton3D", true, false)
		_esperar(esqueleto.find_child("Item*", false, false) != null, "P%d: o item nas costas" % (l + 1))
```

E na Centelha jogada pelo robô (`_joga_a_sala("centelha", …)`): antes, com
o P2 de Escudo, trocar `_joga_a_sala` por `_comeca_a_sala` + checagens +
`_termina_a_sala`:

```gdscript
	var centelha = await _comeca_a_sala("centelha")
	if centelha:
		Itens.escolhido[1] = Itens.ESCUDO
		Itens.escolhido[0] = Itens.MARTELO
		Itens.novo_minigame()
		var qt := 0
		while is_instance_valid(centelha) and centelha.treinando and qt < 1200:
			await _quadros(2)
			qt += 2
		_esperar(centelha.errou(1) and not centelha.errou(1), "Centelha: o Escudo do P2 absorve um erro, e só um")
		_esperar(not centelha.errou(0), "Centelha: o P1, sem Escudo, erra de verdade")
		await _termina_a_sala(centelha, ["botoes", "analogicos", "gatilhos_analogicos"])
```

(A espera do treino é porque `errou()` não gasta o Escudo no treino.)

Na leitura da linha do tempo de `_prova_do_relatorio()` (o laço que a G02
pôs para a `calibracao`), declarar `var absorveu := 0` junto de
`calibracoes` e contar também:

```gdscript
				if d is Dictionary and str(d.get("tipo", "")) == "item" and str(d.get("efeito", "")) == "absorveu":
					absorveu += 1
```

e `_esperar(absorveu >= 1, "o registro tem o Escudo agindo")`.

## Para o André (local)

1. `bash tests/telas.sh fotos /tmp/fotos-g03`: os seis itens nas costas na
   foto da construção (troque o item dos cartões à mão numa rodada
   `./run-local.sh` se a foto só mostrar quatro).
2. Na construção, com um DualSense: passar pelos itens — o L2 fica firme no
   Escudo, pesa pouco na Âncora, solta nos outros.
3. Uma Centelha com o Escudo: errar uma vez (nada acontece, o escudo quebra
   com som no controle, o L2 afrouxa), errar de novo (o combo zera).
4. `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`.

## Ao terminar

No [quadro](README.md), G03 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: os seis itens têm mecânica, peça nas costas e registro; o Escudo já age n'A Centelha
```
