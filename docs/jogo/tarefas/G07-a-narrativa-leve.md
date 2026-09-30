# G07 — A narrativa leve

**Sprint:** G · **Tamanho:** P · **Estimativa:** US$ 1,5 · **Depende de:** F00, F07, G03, G04, G06 · **Usado por:** H04 (o kit chama `falar` e `mostrar_julgamento`)

## Por quê

O ritmo precisa de um porquê no mundo sem texto longo: falas curtas ligadas
a eventos, raras, acima do cavaleiro, e um vocabulário próprio para o
julgamento ("Ressonância!", nunca "PERFECT").

## Ler antes

- [As falas](../07-narrativa-e-voz.md#as-falas) e [o vocabulário do visor](../07-narrativa-e-voz.md#o-vocabulário-do-visor)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04) (a linha "as falas")

## O estado de hoje

- Não há falas nem vocabulário de julgamento em lugar nenhum
  (`grep -rn "Ressonância\|Afinado" godot/scripts` não acha nada).
- A G04 deixou o visor: o sinal `Sala.no_visor(l, texto, segundos, fala)`,
  ligado pelo main a `hud.sobre_o_boneco`, que desenha o julgamento (0,5 s)
  e a fala (2 s) acima do boneco, na cor do lugar.
- A G03 deixou `SalaJogo.errou(l) -> bool` (o erro de um lugar; `true` se o
  Escudo absorveu), chamado hoje só n'A Centelha (o botão errado e
  `_perdeu`).
- `godot/scripts/salas/sala_jogo.gd`: `marcar(lugar, n)` (402-414) soma
  pontos e, fora do treino, conta `acertos`; `_reagir_ao_veredito()`
  (339-354) acha o `melhor` e dá as faíscas a quem fez mais pontos;
  `rng` é semeado em `entrar()` (80); `t` (de `Sala`) soma o `dt`.
- A G06 deixou `Colecao.registrar(...)` com os troféus do tipo `"recorde"`,
  chamado em `main.gd`, `_ao_terminar_a_sala()`.

## O alvo

### As frases (`godot/scripts/falas.gd`, `class_name Falas extends RefCounted`, estático)

```gdscript
## A numeração do julgamento do Ritmo (13): ERRO 0, BOM 1, OTIMO 2, PERFEITO 3.
const ERRO := 0
const BOM := 1
const OTIMO := 2
const PERFEITO := 3
const INTERVALO_S := 20.0   ## uma fala a cada 20 s por lugar (07)
const DURACAO_S := 2.0      ## quanto a fala fica na tela; nunca duas ao mesmo tempo
const DO_EVENTO := {
	"combo_equipe": ["Frequência travada!", "Ninguém nos apaga!"],
	"acorde": ["Acorde maior!"],
	"arrastando": ["Segura menos!", "Vai com o baixo!"],
	"correndo": ["Calma, espera o bumbo!"],
	"todos_erraram": ["Tá tudo desafinado!"],
	"voltou": ["De novo, do começo."],
	"ajudou": ["Deixa comigo o refrão!"],
	"vencedor": ["Faltou ginga pra eles.", "A forja canta de novo."],
}
const VISOR := ["", "Quase", "Afinado", "Ressonância!"]   ## por julgamento; o erro não tem palavra
const RECORDE := "Recorde!"
## A palavra do visor. No treino, o que não é perfeito diz o lado: "Cedo" (desvio < 0) ou "Tarde".
static func do_julgamento(j: int, no_treino := false, desvio_s := 0.0) -> String
```

### Quem fala (`SalaJogo`)

```gdscript
var _ultima_fala := [-INF, -INF, -INF, -INF]   ## o t da última fala de cada lugar
var _fala_ate := 0.0                            ## até quando há uma fala na tela
var _acertos_da_equipe := 0                     ## acertos seguidos da equipe (fora do treino)
var _erros_seguidos := [0, 0, 0, 0]
var _ultimo_erro := [-INF, -INF, -INF, -INF]

## Uma fala do cavaleiro do lugar por um evento de 07. Devolve false (e não
## fala) se o lugar falou há menos de 20 s ou se outra fala está na tela.
func falar(l: int, evento: String) -> bool:
	if not Falas.DO_EVENTO.has(evento) or t < _fala_ate or t - _ultima_fala[l] < Falas.INTERVALO_S:
		return false
	var frases: Array = Falas.DO_EVENTO[evento]
	var texto: String = frases[rng.randi() % frases.size()]
	_ultima_fala[l] = t
	_fala_ate = t + Falas.DURACAO_S
	no_visor.emit(l, texto, Falas.DURACAO_S, true)
	Forja.evento("fala", l + 1, {"evento": evento})
	return true

## A palavra do julgamento acima do boneco, por meio segundo (o kit chama a cada toque).
func mostrar_julgamento(l: int, j: int, desvio_s := 0.0) -> void:
	var s := Falas.do_julgamento(j, treinando, desvio_s)
	if s != "":
		no_visor.emit(l, s, 0.5, false)
```

Os eventos que as salas de hoje já têm:

| evento | onde | regra |
| --- | --- | --- |
| `vencedor` | `_reagir_ao_veredito()` | o primeiro lugar com `pontos == melhor` (e `melhor > 0`) fala |
| `combo_equipe` | `marcar(l, n)` com `n > 0`, fora do treino | `_acertos_da_equipe += 1`; em 15, `falar(l, "combo_equipe")` e volta a 0 |
| `voltou` | `marcar(l, n)` com `n > 0` | se `_erros_seguidos[l] >= 5`, `falar(l, "voltou")`; depois `_erros_seguidos[l] = 0` |
| `todos_erraram` | `errou(l)`, quando o Escudo **não** absorveu | `_ultimo_erro[l] = t`, `_erros_seguidos[l] += 1`, `_acertos_da_equipe = 0`; se todo lugar em `jogando` errou nos últimos 1,5 s, `falar(l, "todos_erraram")` |

Os outros (`acorde`, `arrastando`, `correndo`, `ajudou`) dependem do
julgamento com desvio: o kit (H04) os chama, com as regras que vão para o 13
no passo 1.

`errou(l)` fica assim (a parte da G03 continua igual):

```gdscript
func errou(l: int) -> bool:
	if treinando:
		return false
	if Itens.absorve_erro(l):
		…   # o Escudo (G03)
		return true
	_depois_do_erro(l)
	return false
```

**O recorde:** em `main.gd`, onde a G06 chama `Colecao.registrar`, para
cada troféu novo de tipo `"recorde"`:
`hud.sobre_o_boneco(t.lugar, Falas.RECORDE, 1.5)` (compare
`Colecao.trofeus.size()` antes e depois da chamada).

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3 e 4.

1. **O 13 primeiro:** no [kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04),
   a linha "as falas" passa a: "`falar(l, evento)` e
   `mostrar_julgamento(l, j, desvio_s)` vêm de `SalaJogo` (G07); o kit chama
   `falar(l, "arrastando")` com três toques seguidos acima de +60 ms,
   `"correndo"` com três abaixo de −40 ms, `"acorde"` quando dois ou mais
   lugares acertam perfeito no tempo 1 com menos de 50 ms entre eles,
   `"ajudou"` quando `Itens.puxa_o_combo_da_equipe`"; e na tabela do registro
   v2, a linha `fala` (`evento` — G07).
2. **`godot/scripts/falas.gd` (novo):** a classe; importar e commitar o
   `falas.gd.uid`.
3. **`godot/scripts/salas/sala_jogo.gd`:** as variáveis, `falar()`,
   `mostrar_julgamento()`, `_depois_do_erro(l)`, e os ganchos em `marcar()`,
   `errou()` e `_reagir_ao_veredito()`.
4. **`godot/scripts/main.gd`:** o "Recorde!" junto da coleção.
5. **`godot/scripts/traducoes.gd`:** as entradas (tabela abaixo).
6. **A prova** (ver Provas).

| português | inglês |
| --- | --- |
| Frequência travada! | Frequency locked! |
| Ninguém nos apaga! | Nobody puts us out! |
| Acorde maior! | Major chord! |
| Segura menos! | Ease off! |
| Vai com o baixo! | Ride the bass! |
| Calma, espera o bumbo! | Easy, wait for the kick! |
| Tá tudo desafinado! | Everything's out of tune! |
| De novo, do começo. | Again, from the top. |
| Deixa comigo o refrão! | I've got the chorus! |
| Faltou ginga pra eles. | They lacked the groove. |
| A forja canta de novo. | The forge sings again. |
| Ressonância! / Afinado / Quase | Resonance! / In tune / Almost |
| Cedo / Tarde / Recorde! | Early / Late / Record! |

## Armadilhas

- **`.uid`** do `falas.gd`.
- **Texto por `Traducoes` e com maiúscula:** o HUD traduz ao desenhar; a
  frase de `DO_EVENTO` é a chave. O portão da F07 reprova frase com
  minúscula.
- **O limite vale por sala:** `t` zera a cada sala; uma fala no fim de uma
  sala e outra no começo da seguinte podem sair com menos de 20 s — está
  certo (a tela mudou).
- **Sorteio pela semente:** use o `rng` da sala (semeado em `entrar()`),
  nunca `randi()`: as provas repetem.
- **Nada no erro:** o erro não tem palavra (07); `do_julgamento(ERRO)` é
  `""` e `mostrar_julgamento` não emite nada.
- **Salas às cegas:** `errou()` continua só n'A Centelha (G03); não o ponha
  nas outras salas agora.
- **O robô:** nenhum `Forja.robo`; o robô pode disparar falas jogando, e
  isso é o jogo.

## Não fazer

- Cutscene, diálogo, texto longo, legenda.
- PERFECT/MISS, nota, porcentagem na tela.
- Fala que manda olhar o controle ou que fala do hardware.
- Mudar o desenho do visor (é da G04).

## Pronto quando

Numa partida de cinco as falas aparecem acima do cavaleiro, nunca duas ao
mesmo tempo e nunca duas do mesmo cavaleiro em menos de 20 s; o julgamento
só usa "Ressonância!", "Afinado", "Quase" (e "Cedo"/"Tarde" no treino); o
recorde diz "Recorde!".

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função chamada no `_ready()` depois
de `_prova_do_percurso()` (com o HUD já montado):

```gdscript
## As falas e o visor, numa SalaJogo solta (sem cena, sem robô): as regras de 07.
func _prova_das_falas() -> void:
	var s := SalaJogo.new()
	s.no_visor.connect(jogo.hud.sobre_o_boneco)
	s.t = 100.0
	_esperar(s.falar(0, "vencedor"), "a primeira fala sai")
	_esperar(jogo.hud.visor[0].has("fala"), "a fala aparece acima do P1")
	s.t = 101.0
	_esperar(not s.falar(1, "combo_equipe"), "duas falas ao mesmo tempo, não")
	s.t = 102.1
	_esperar(s.falar(1, "combo_equipe"), "passados 2 s, a fala do P2 sai")
	s.t = 110.0
	_esperar(not s.falar(0, "voltou"), "o P1 não fala de novo antes de 20 s")
	s.t = 120.5
	_esperar(s.falar(0, "voltou"), "passados 20 s, o P1 fala de novo")
	_esperar(not s.falar(2, "nao_existe"), "evento sem frase não fala")
	s.free()
	_esperar(Falas.do_julgamento(Falas.PERFEITO) == "Ressonância!" and Falas.do_julgamento(Falas.OTIMO) == "Afinado"
		and Falas.do_julgamento(Falas.BOM) == "Quase" and Falas.do_julgamento(Falas.ERRO) == "", "o vocabulário do visor")
	_esperar(Falas.do_julgamento(Falas.BOM, true, -0.08) == "Cedo" and Falas.do_julgamento(Falas.OTIMO, true, 0.07) == "Tarde"
		and Falas.do_julgamento(Falas.PERFEITO, true, 0.01) == "Ressonância!", "no treino, cedo e tarde; o perfeito é perfeito")
	var sem := []
	for evento in Falas.DO_EVENTO:
		for frase in Falas.DO_EVENTO[evento]:
			if frase.substr(0, 1) != frase.substr(0, 1).to_upper() or not Traducoes.EN.has(frase):
				sem.append(frase)
	_esperar(sem.is_empty(), "toda fala começa com maiúscula e tem inglês %s" % [sem])
	jogo.hud.visor = [{}, {}, {}, {}]
```

## Para o André (local)

1. `./run-local.sh -- --partida=5`: jogar e contar as falas — nenhuma
   encavalada, nenhuma repetida pelo mesmo cavaleiro em seguida.
2. N'A Centelha, errar de propósito com os quatro ao mesmo tempo: "Tá tudo
   desafinado!".
3. Em inglês (Opções › Idioma): as mesmas falas traduzidas.

## Ao terminar

No [quadro](README.md), G07 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: as falas curtas dos cavaleiros e o vocabulário do visor
```
