# P1 — A Voz

**Sprint:** P · **Slot:** S08_J36 · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 2,0 · **Depende de:** H04, H08, F09, F01, H07, G08

## Por quê

A sala de hoje (`godot/scripts/salas/voz.gd`) mede em estados soltos — o
silêncio, o chamado, o mudo, o sussurro — e termina perguntando "como está a
luz do microfone?". No kit ela vira coop no tempo: o guardião dorme, cada um
o chama na sua vez, os quatro sopram juntos nos tempos da respiração dele
para acender a chama, e quando ele acorda rugindo, **o botão do mudo é o
escudo** (a luz laranja acende: está protegido). A pergunta da luz só existe
no Modo bancada.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) e [o kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)
- [A ficha-mãe da seção](P-a-voz.md) e [as decisões comuns do 13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08) (as linhas `voz`, `troca` e `pista`, o fim em tempo de música)
- `godot/scripts/salas/voz.gd` inteiro (é o que sai), em especial
  `_montar_guardiao` (já em blocos pela G08), `_montar_raia` (o braseiro),
  `_medir`, `dar_vereditos` e `_robo`
- [05 — a agenda do alto-falante](../05-haptica-e-controle.md#a-agenda-do-alto-falante)

## A ficha de dados

```gdscript
const FICHA := {
	"slot": "S08_J36",
	"titulo": "A Voz",
	"verbo": "Chame a forja!",
	"genero": "coop",
	"icone": "mic",
	"entradas": [Forja.MICROFONE],
	"camera": "fixa",
	"faixa": "MUS_S08_J36",
	"duracao": 80.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao"],
	"material": "pedra",
	"microjogo": {"verbo": "Sopre!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,  # o kit abre este papel de som no entrar() (H08)
	# a bancada: o microfone, o botão do mudo e a luz dele
	"features": ["microfone", "microfone_mudo", "led_microfone"],
	"botoes_medidos": [Forja.MICROFONE, Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO],
	"gesto": "interact-right",
	"treino": false,
}
```

`duracao` 80: o teto, contado pelo kit em tempo de música (H08). A Voz
acaba antes, pela partitura — o susto na batida `S0 + 8` (uns 52 s de
música com quatro, a 105 bpm) —, e o susto acontece também na prova, onde o
jogo anda 16 vezes mais depressa que a música. Sem treino: o chamado ensina.

## Como se joga

A faixa é `MUS_S08_J36`, 105 bpm (uma batida ≈ 0,57 s). `BATIDA_DA_PRIMEIRA_NOTA` (4, do kit: H08). Com
`np` lugares em `presentes()`:

| trecho | batidas | o que acontece |
| --- | --- | --- |
| a contagem | 0 a 3 | o guardião ronca; o piso de cada microfone é medido (`_piso_medido`, a média de 1 a 3,5) |
| **o chamado** | `4 + 4i` a `8 + 4i`, um compasso para o lugar `i` de `presentes()` | o foco na raia dele; **duas chamadas**: vozes nas batidas `+0` e `+2` do compasso dele. Os outros, quietos (a voz deles não conta nem pune) |
| **o sopro** | `C0 = 4 + 4 * np` a `C0 + 64` (16 compassos) | a respiração do guardião: **todos** sopram nas batidas `+0` e `+2` de cada compasso; cada sopro no tempo sobe a chama da forja |
| o pico | compassos 6 a 9 do sopro | o guardião se mexe (a cabeça vira, a poeira cai): sopro em **toda** batida |
| **o susto** | `S0 = C0 + 64` a `S0 + 8` | `S0`: os olhos abrem; `S0 + 2`: o sino no alto-falante de cada um (o aviso é pessoal); `S0 + 3`: **a nota do mudo** — Botão do microfone; `S0 + 4`: **o rugido** |
| o fim | `S0 + 8` | todos acabam (sem a bancada) |

- **A voz** (o ouvido, abaixo): cada começo de voz de um lugar é casado com a
  nota aberta dele mais perto; se o começo cai a até 0,35 s do alvo,
  `julgar_toque(l, Ritmo.t_da_batida(bn) + LATENCIA_MIC, n)`. Um começo de
  voz **no sopro** longe de toda nota é **a cinza** (`_cinza(l)`: a falha, sem
  nota). No chamado, a voz fora da vez não conta.
- **A nota que passa** (sem voz até o alvo + `LATENCIA_MIC` + `JANELA_BOM`):
  `nota_perdida(l, n)`.
- **O mudo do susto:** o Botão do microfone de `S0 + 2` até o rugido liga o
  mudo (`_mudo[l] = true`, `Forja.led_mic(l, 1)`) e é julgado contra
  `Ritmo.t_da_batida(S0 + 3)` (`julgar_toque`, a nota do mudo). Julgado
  ERRO (cedo demais ou tarde) ainda protege — só não pontua. Depois do
  rugido, o botão não protege mais.
- **O rugido** (`S0 + 4`): quem não está mudo recebe o golpe (ver "A falha").
- **Pontos:** cada voz julgada marca `[0, 50, 75, 100][j]`; a nota do mudo,
  `[0, 50, 75, 100][j]`.
- **A chama da forja** (a meta coletiva, 0 a 1): cada sopro julgado soma
  `PESO[j] / _denominador` (`PESO := [0.0, 0.6, 0.8, 1.0]`,
  `_denominador = 0.6 * 40 * np` — 40 sopros por lugar, com o pico); a cinza
  tira `0.3 / _denominador`. Em 1,0 a forja acende de vez (faíscas, a
  bigorna na TV) e fica acesa.
- **O hoqueto:** no chamado, uma voz por vez; no sopro, todos juntos (é o
  coro do coop); a nota de cada lugar soa na TV (kit) no sopro dele.
- **A partitura simples** (`Ritmo.simples[l]`): no sopro, o lugar sopra só na
  batida `+0` de cada compasso (e, no pico, nas `+0` e `+2`).

### O ouvido (o mesmo nas cinco fichas da seção)

```gdscript
const VOZ_ACIMA := 0.30     ## a voz acima do piso (MED_VOZ_ACIMA, com folga)
const VOZ_FICA := 0.18      ## abaixo disto (acima do piso) a voz parou
const MARGEM_AR := 0.12     ## a regra do ar: conta a voz do microfone a menos disto do mais alto
const LATENCIA_MIC := 0.08  ## do som ao nível subir, em s (ajuste pelo desvio_ms dos toques da noite)

var _nivel := [0.0, 0.0, 0.0, 0.0]
var _piso := [0.0, 0.0, 0.0, 0.0]
var _falando := [false, false, false, false]
var _pico_voz := [0.0, 0.0, 0.0, 0.0]
var _mudo := [false, false, false, false]     ## o mudo do jogo (o botão)
var _sem_mic := [false, false, false, false]  ## sem microfone, ou mudo no sistema
var _maior_nivel := [0.0, 0.0, 0.0, 0.0]      ## o maior nível já ouvido (o mudo no sistema)


## Um quadro do ouvido: chama _comecou(l) e _parou(l) nas bordas da voz.
func _ouvir(dt: float) -> void:
	var mais_alto := 0.0
	for l in presentes():
		_nivel[l] = float(Forja.som_mic(l).get("nivel", 0.0)) if conectado(l) else 0.0
		_maior_nivel[l] = maxf(_maior_nivel[l], _nivel[l])
		if not _mudo[l] and not _sem_mic[l]:
			mais_alto = maxf(mais_alto, _nivel[l])
	for l in presentes():
		var pode: bool = conectado(l) and not _mudo[l] and not _sem_mic[l]
		var agora: bool
		if _falando[l]:
			agora = pode and _nivel[l] >= _piso[l] + VOZ_FICA
		else:
			agora = pode and _nivel[l] >= _piso[l] + VOZ_ACIMA and _nivel[l] >= mais_alto - MARGEM_AR
		if not agora and not _falando[l]:
			_piso[l] = lerpf(_piso[l], _nivel[l], minf(1.0, dt * 0.5))   # medida, não mundo: o dt vale
		if agora:
			_pico_voz[l] = maxf(_pico_voz[l], _nivel[l])
		if agora and not _falando[l]:
			_falando[l] = true
			_pico_voz[l] = _nivel[l]
			Forja.evento("voz", l + 1, {"slot": id, "evento": "comecou", "nivel": snappedf(_nivel[l], 0.01), "piso": snappedf(_piso[l], 0.01)})
			_comecou(l)
		elif not agora and _falando[l]:
			_falando[l] = false
			Forja.evento("voz", l + 1, {"slot": id, "evento": "parou", "nivel": snappedf(_pico_voz[l], 0.01), "piso": snappedf(_piso[l], 0.01)})
			_parou(l)
```

**Sem microfone:** no `iniciar_jogo()`, `_sem_mic[l] = not Forja.som_tem(l, Forja.PAPEL_MICROFONE)`
(`troca` `de` `microfone` `para` `sem_microfone`); na batida `BATIDA_DA_PRIMEIRA_NOTA`, quem tem
`_maior_nivel[l] <= 0.001` passa a `_sem_mic` (motivo `mudo_no_sistema`).
**O mudo fora da hora** (o Botão do microfone antes do susto) liga e desliga
`_mudo[l]` e a luz (`Forja.led_mic(l, 1 / 0)`), com a `troca` `mudo_no_jogo`
uma vez. Quem está sem microfone ou mudo **sopra sozinho, mais fraco**: as
notas dele não são abertas; em cada batida de sopro dele, `marcar(l, 25)` e a
chama sobe `0.4 / _denominador`. Ninguém fica travado.

## O cenário

- O de hoje, com o guardião de pedra em blocos da G08 (copie o
  `_montar_guardiao()` do `voz.gd` **como está**, depois da G08): a cripta
  (`Kit.arena(self, 5, 3)`, `atmosfera(Color("#7fe8ff"), Tema.VERDE, true, 40, 22.0, -7.8, 0.15)`,
  o enchimento frio `#5a4f8f` a 0,35), as quatro velas do fundo (a chama da
  vela: `Kit.caixa(self, Vector3(0.1, 0.14, 0.1), ...)` emissiva `#ffb050`, no
  lugar da esfera), o guardião em `GUARDIAO := Vector3(0.0, 3.05, -4.35)`.
- **A forja do guardião** (a meta coletiva), em `(0, 0, -2.6)`:
  `Kit.peca(self, "column", Vector3(0, 0, -2.6), 0.0, 0.7)` de base e a chama
  grande: `Kit.cilindro(self, 0.5, 1.0, ..., chama)` (8 lados) emissiva
  `#ff7a1a`, altura `0.1 + 2.2 * _chama`, com uma `OmniLight3D` `#ff9a40` de
  energia `0.3 + 3.0 * _chama`.
- **Cada raia:** `raia(l)` e `posicionar(l)` do kit, `p.rotation.y = PI`,
  `p.preso = true`; o braseiro pequeno de hoje à frente do boneco (as pedras
  com `Kit.cilindro` de 8 lados, a chama da voz dele sobe com o `_nivel[l]`,
  apaga no mudo); o foco de quem tem a vez no chamado (o `SpotLight3D` de
  hoje).
- **A câmera:** `camera_pos = Vector3(0, 5.4, 10.8)`, `camera_olhar = Vector3(0, 1.7, -1.2)`.
- **O guardião, pela batida:** os olhos fechados na contagem, entreabertos
  no chamado, abrindo com a chama no sopro, abertos no susto; a boca abre em
  degraus no rugido (a animação de hoje, com `snappedf(grito, 0.25)`, G08); no
  pico, `pivo.rotation.y = 0.25 * sin(Ritmo.batida() * PI / 2)`. Tudo no
  `_mostrar(b)`, chamado do fim do `jogar`.
- **Checklist de arte (11):** sem esfera (a brasa de hoje vira caixa), sem
  bronze, `metallic` 0; o emissivo nos olhos, nas chamas e na borda da raia;
  nenhuma cor de lugar no guardião; a prancha com os bonecos à frente dele.

## O repertório

| recurso | o quê | quando |
| --- | --- | --- |
| **microfone (protagonista)** | o chamado, o sopro | no tempo de cada nota |
| **luz do mudo** | o escudo: acesa (`led_mic(l, 1)`) = mudo, protegido; apagada no fim | do botão até o fim |
| vibração | cresce com a voz: a cada voz julgada, o kit (`acerto`/`perfeito`); o rugido em quem não está mudo: `Forja.sentir(l, "explosao")`; o mudo que segura: `Forja.sentir(l, "toque")` | no toque; no rugido |
| barra de luz | a cor do lugar; o minigame não chama `Forja.luz` | — |
| alto-falante do dono | o eco curto da própria voz: `Forja.som_falante(l, "nota:%d" % l, 0.5)` na voz julgada PERFEITO (o kit já toca); `Forja.som_falante(l, "pronto", 0.8)` em `S0 + 2` (o aviso); `Forja.som_falante(l, "grito", 0.8)` no rugido, só em quem não está mudo | — |
| háptica por material | o kit (`material:pedra` no acerto, no cabo) | no toque |
| gatilho | nada a segurar: `Forja.gatilhos_off(l)` | — |
| TV | a música com espaço para a voz; `Som.tocar("bigorna", GUARDIAO, -4.0)` quando a forja acende; `Som.tocar("grito", GUARDIAO, 0.0)` e `Som.tocar("martelo", GUARDIAO, 2.0)` no rugido; `tremor = 1.4` | — |

**No rádio:** não há placa de áudio — nem alto-falante, nem
microfone, nem atuadores. O lugar cai no "sopra sozinho" desde o começo
(`Forja.som_tem(l, Forja.PAPEL_MICROFONE)` falso: a `troca` com `motivo`
`sem_microfone`), o sino e o grito do alto-falante não soam (o aviso do susto
fica na vibração: `Forja.sentir(l, "aviso")` em `S0 + 2` para quem não tem
alto-falante), e a háptica do kit vai pelo rumble. A **luz do mudo** é saída
HID: passa pela ponte, e o escudo do susto funciona igual.

## A falha

- **A cinza** (voz no sopro fora de toda nota): o braseiro do lugar cospe
  cinza (`Efeitos.poeira(self, bras, Vector3(0.6, 0.6, 0.6), Color("#6a6470"), 16)`
  por meio segundo) e a chama da forja desce um pouco; o boneco tosse
  (`emote-no`, 0,4 s).
- **A nota que passou:** o braseiro dele pisca apagado; `emote-no`.
- **O rugido sem mudo:** o boneco é jogado para trás (`fall`, 0,9 s,
  `p.position.z` anda 0,6 para trás e volta em duas batidas), a mão sente a
  explosão, o alto-falante grita. Não perde a chama, só os pontos
  (`marcar(l, -50)` fora do treino).

## O fim e o vencedor

Na batida `S0 + 8` (sem a bancada), todos acabam. O `coop` vem do gênero da
FICHA (H08); `coop_venceu = _chama >= 1.0`, posto na batida `S0 + 8`. O
registro grava `vencedor` −1 (coop); `destaque()`: "o pulmão mais afinado",
pelos pontos (no empate, o lugar menor).

## Com menos de quatro

- **3, 2, 1:** o chamado tem um compasso por lugar em `presentes()`; o
  `_denominador` usa `np`; com um, ele sopra sozinho a forja inteira (a meta
  é a mesma por lugar).
- **O controle que cai:** as notas dele não são abertas enquanto estiver sem
  controle (e as abertas não viram erro: feche-as sem registro); no chamado,
  a vez dele passa. Quando volta, entra na próxima nota de sopro.
- **Duplas:** não há.

## A bancada (só com `Forja.bancada`)

Depois do rugido, antes do fim:

1. **O sussurro** (`S0 + 4` a `S0 + 12`): quem está mudo sussurra; o maior
   nível ouvido no mudo vai para `_mudo_nivel[l]` (a medida do
   `microfone_mudo`: o sistema cortou, ou o mudo ficou só com o jogo?).
2. **A luz do microfone:** o `_luz_rodada`, o `_atualizar_luz` e o
   `pergunta(l)` de hoje (`voz.gd:258-358`, `:597-619`), sem mudar, das
   batidas `S0 + 12` em diante, com o `t` delas pelo `dt` (é a camada da
   bancada, não o ritmo). Quando todos fecham, todos acabam.

`pergunta(l)` devolve `{}` sem a bancada. `dar_vereditos(l)` é o de hoje
(`voz.gd:460-472`), com os dados do minigame: `tem`, `piso` (o
`_piso_medido`), `viu_piso` (`true` depois da contagem), `voz` (o maior
nível na vez dele no chamado), `mudo` (`_mudo_nivel`), `viu_mudo` (ficou mudo
uma batida inteira com a medida aberta), `apertou_mudo`, `pediu_mudo`
(`true` se estava conectado no susto), `quadros` e `mexeu`; o
`led_microfone` com a `Cega` da luz e `sdl_aceitou` = alguma `led_mic`
devolveu `true` (o mudo do susto já conta, F01).

## O robô

Fala no microfone do controle simulado dele (`Forja.robo_falar`), aperta o
Botão do microfone, e na bancada olha a luz dele (a `percepcao`, como hoje).

```gdscript
func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	# as vozes: o chamado e o sopro
	var n: int = _nota[l]
	if n >= 0 and _robo_falou[l] != n:
		if _robo_nota[l] != n:
			_robo_nota[l] = n
			_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.3 if _robo_rng.randf() < 0.5 else 99.0)
		if Ritmo.t_musica() >= float(_alvo[l]) + LATENCIA_MIC + float(_robo_mira[l]):
			Forja.robo_falar(l, 0.8, 0.3)
			_robo_falou[l] = n
	# o mudo do susto
	if b >= _s0 + 2.0 and b < _s0 + 4.0 and not _mudo[l] and not _robo_mudou[l]:
		if _robo_mira_mudo[l] < -1.0:
			_robo_mira_mudo[l] = 0.0 if Forja.robo_acerta() else 0.35
		if Ritmo.t_musica() >= Ritmo.t_da_batida(_s0 + 3.0) + _robo_mira_mudo[l]:
			Forja.robo_apertar(l, Forja.MICROFONE, 0.08)
			_robo_mudou[l] = true
	# a bancada: o sussurro mudo e a luz (o _robo de hoje, voz.gd:641-653)
	if Forja.bancada:
		_robo_bancada(l, b, dt)
```

(`_robo_mira_mudo` começa em −9,0: "ainda não decidido". O atraso de 0,35 s
ainda cai antes do rugido — uma batida é 0,57 s —, então protege, mas é ERRO.
O 99,0 da voz é "não fala".) O `_robo_bancada` é o `SUSSURRO` e o `LUZ` do `_robo`
de hoje, com `e.*` trocado pelos arrays do minigame.

## Os ganchos

`godot/scripts/minigames/s08/a_voz.gd`, `extends Minigame`. O que muda do
`voz.gd` de hoje:

| sai | por quê |
| --- | --- |
| `class_name SalaVoz`, `_init()`, `RAIAS`, `Z_JOGADOR`, `_conectado`, `objetivo` | o kit tem; nenhum texto longo |
| os estados `SILENCIO`, `CHAMADO`, `MUDO`, `SUSSURRO`, `ESPERA`, `SUSTO` com `t_estado += dt` | o fluxo é pela batida |
| `Forja.vibrar(l, 1.0, 1.0, 700)` e `Forja.luz(l, vermelho)` do susto | `Forja.sentir(l, "explosao")`; a barra de luz nunca troca de cor aqui |
| `progresso()`, `status()` e `dica()` com frases minúsculas e metalinguagem ("fale alto", "mudo no sistema") | ver abaixo |
| o `_process` | o `_mostrar(b)` no fim do `jogar` |

```gdscript
extends Minigame
## A Voz (S08_J36). O guardião dorme. Cada um o chama na sua vez; os quatro
## sopram juntos nos tempos da respiração dele para acender a forja; quando ele
## acorda rugindo, o Botão do microfone é o escudo (a luz dele acende).
##
## A falha: a voz fora do tempo espalha cinza; o rugido joga para trás quem
## não ficou mudo. O vencedor: coop (a forja acende); o destaque é o pulmão
## mais afinado. O alto-falante do dono: o sino do aviso, o grito do rugido.
## O registro mede: a voz de cada controle (voz), o mudo e a luz do mudo
## (saida led_microfone); na bancada, os três vereditos. O robô: fala pelo
## controle simulado. Com menos de quatro: o chamado encurta; a meta é por
## lugar. A régua: nenhuma pergunta fora da bancada; sem microfone, sopra
## sozinho.

const FICHA := { ... }

const SOPRO_COMPASSOS := 16
const PICO_DE := 6          ## o pico: os compassos 6 a 9 do sopro
const PICO_ATE := 10
const PESO := [0.0, 0.6, 0.8, 1.0]
const PONTOS := [0, 50, 75, 100]
const JANELA_CASA := 0.35   ## até onde um começo de voz se casa com uma nota
const GUARDIAO := Vector3(0.0, 3.05, -4.35)
# ... e as do ouvido

var _c0 := 0.0             ## o começo do sopro
var _s0 := 0.0             ## o começo do susto
var _vez := {}             ## lugar -> a batida do compasso dele no chamado
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _bn := [0.0, 0.0, 0.0, 0.0]   ## a batida da nota aberta
var _n := [0, 0, 0, 0]
var _feita := [-1.0, -1.0, -1.0, -1.0]   ## a última batida de nota já aberta
var _chama := 0.0
var _denominador := 1.0
var _acendeu := false
var _rugiu := false
var _mudo_do_susto := [false, false, false, false]
var _piso_medido := [0.0, 0.0, 0.0, 0.0]
var _voz_na_vez := [0.0, 0.0, 0.0, 0.0]
var _mudo_nivel := [0.0, 0.0, 0.0, 0.0]
var _motivo := ["", "", "", ""]
var _luz := {}             ## a bancada: lugar -> Cega da luz (o de hoje)
var _nos := {}
var _g := {}               ## os nós do guardião
# o robô
var _robo_nota := [-1, -1, -1, -1]
var _robo_falou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_mudou := [false, false, false, false]
var _robo_mira_mudo := [-9.0, -9.0, -9.0, -9.0]


func montar() -> void:
	camera_pos = Vector3(0, 5.4, 10.8)
	camera_olhar = Vector3(0, 1.7, -1.2)
	# a cripta, as velas, o guardião (G08), a forja do guardião; cada raia; gatilhos_off


func iniciar_jogo() -> void:
	var ordem := presentes()
	for i in ordem.size():
		_vez[ordem[i]] = float(BATIDA_DA_PRIMEIRA_NOTA + 4 * i)
		Forja.led_mic(ordem[i], 0)
		# sem microfone: _sem_mic e a troca
	_c0 = float(BATIDA_DA_PRIMEIRA_NOTA + 4 * ordem.size())
	_s0 = _c0 + 4.0 * SOPRO_COMPASSOS
	_denominador = 0.6 * 40.0 * maxi(1, ordem.size())


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)
	_medir_para_a_bancada(b)      # o piso da contagem, a voz na vez, o nível no mudo
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_abrir_notas(l, b)         # chamado (na vez dele), sopro, pico; o sopro sozinho de quem não tem voz
		_botao_do_mudo(l, b)       # fora do susto: liga/desliga; no susto: a nota do mudo
		if _nota[l] >= 0 and Ritmo.t_musica() > float(_alvo[l]) + LATENCIA_MIC + Ritmo.JANELA_BOM:
			var n: int = _nota[l]
			_nota[l] = -1
			_motivo[l] = "passou"
			nota_perdida(l, n)
	if b >= _s0 + 4.0 and not _rugiu:
		_rugido()
	if b >= _s0 + 8.0:
		coop_venceu = _chama >= 1.0
		if not Forja.bancada:
			for l in presentes():
				acabou[l] = true
		else:
			_bancada(b, dt)       # o sussurro, depois a luz; quando todos fecham, acabou
	_mostrar(b)


## O começo de uma voz: casa com a nota aberta, ou é cinza no sopro.
func _comecou(l: int) -> void:
	var n: int = _nota[l]
	if n >= 0 and absf(Ritmo.t_musica() - float(_alvo[l]) - LATENCIA_MIC) <= JANELA_CASA:
		_nota[l] = -1
		_motivo[l] = "cinza"
		julgar_toque(l, float(_alvo[l]) + LATENCIA_MIC, n)
	elif Ritmo.batida() >= _c0 and Ritmo.batida() < _s0:
		_cinza(l)


func _parou(_l: int) -> void:
	pass   # A Voz não julga o fim da voz


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	if _bn[l] >= _c0 and _bn[l] < _s0:
		_subir_a_chama(PESO[j] / _denominador)


func falha(l: int) -> void:
	jogador(l).gesto("emote-no", 0.4)   # a cinza, a nota que passou, o mudo fora de hora


## Coop: o kit grava vencedor −1 (H08); o destaque é o pulmão mais afinado.
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return pontos[a] > pontos[b] or (pontos[a] == pontos[b] and a < b))
	return int(lista[0]) if not lista.is_empty() else -1


func pergunta(l: int) -> Dictionary:
	if not Forja.bancada:
		return {}
	return _pergunta_da_luz(l)    # a de hoje


func dar_vereditos(l: int) -> Array:
	# a de hoje (voz.gd:460-472), com os dados do minigame (ver "A bancada")
	return _vereditos_da_voz(l)
```

`_abrir_notas(l, b)`: a nota seguinte do lugar é a primeira batida `bn` da
lista dele que ainda não foi aberta (`bn > _feita[l]`) — as duas do compasso
do chamado (`_vez[l]`, `_vez[l] + 2`), depois as do sopro (`_c0 + 4k` e
`_c0 + 4k + 2`, e as ímpares no pico; só `+0` com `Ritmo.simples[l]`) — e ela
abre quando `b >= bn - 1.0` e não há nota aberta:
`_nota[l] = _n[l]`, `_n[l] += 1`, `_bn[l] = bn`, `_alvo[l] = Ritmo.t_da_batida(bn)`,
`nova_nota(l, _nota[l], _alvo[l])`, `_feita[l] = bn`. Quem está `_sem_mic` ou
`_mudo`: na batida `bn`, o sopro sozinho (sem nota). `_rugido()`: para cada
lugar conectado, mudo → `Forja.sentir(l, "toque")` e o escudo (faíscas
azuis-claras `Color("#9fd4ff")` no boneco); não mudo → a falha do rugido.
Depois do rugido, `Forja.led_mic(l, 0)` na batida `S0 + 8` (sem a bancada;
com ela, no fim da luz). `_subir_a_chama(d)`: `_chama = clampf(_chama + d, 0.0, 1.0)`;
na primeira vez em 1,0, a forja acende (`_acendeu`, a bigorna na TV, faíscas
`Efeitos.faiscas(self, Vector3(0, 2, -2.6), Color("#ffb070"), 60, 1.6)`).

A dica (com `na_raia(l)`): no chamado, na vez dele, `["@mic"]` só enquanto
`not aprendeu(l)`; no susto, entre `S0 + 2` e o rugido, `["@mic", "Escudo!"]`
— o botão do microfone é o escudo (é verbo do mundo, não pergunta). Nada
mais. `status(l)`: `"%d pontos" % pontos[l]`; `progresso()`: `""`.

**A casa nova e o catálogo:** `godot/scripts/minigames/s08/a_voz.gd` e o
`.uid`; `"S08_J36"` em `MINIGAMES` e `"minigames": ["S08_J36"]` na seção
`S08`; tire `"voz"` de `SALAS_ANTIGAS`; `git rm godot/scripts/salas/voz.gd godot/scripts/salas/voz.gd.uid`
(e `grep -rn "SalaVoz" godot/` vazio). Traduções: `"A Voz": "The Voice"`,
`"Chame a forja!": "Call the forge!"`, `"Sopre!": "Blow!"`,
`"Escudo!": "Shield!"`; tire as frases que só a sala de hoje usava.

## O que o registro mede

- `voz` de cada começo e fim de voz (`nivel`, `piso`) — o nível do microfone
  de cada controle, a noite inteira;
- `nota` e `toque` de cada chamado, sopro e do mudo do susto (o desvio da voz
  no tempo pedido);
- `saida` `led_microfone` (o mudo, com `seq` e `ok`) e o botão pelas medidas;
- `troca` `de` `microfone` `para` `sem_microfone`; os três vereditos na bancada.

A linha `voz` é a do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08)
(H08): `slot`, `evento` (`comecou`/`parou`), `nivel` (no começo; o pico no
`parou`) e o `piso` (o limiar).

## Armadilhas

- **O robô sorteia no dele.** `var _robo_rng := RandomNumberGenerator.new()`, com
  `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o `rng` do kit é do jogo
  (os caminhos, os lados, o Aprendiz), e o robô não pode mudar o que o jogo sorteia
  (a paridade: com robô ou com gente, o mesmo jogo).
- **A prova fica mais longa.** A Voz acaba pela música (uns 55 s de relógio,
  e uns 20 s a mais com a bancada, nas duas rodadas). Não encurte (a regra 7
  da paridade); se o `timeout 1200` apertar, anote e avise.
- **O piso do simulado.** O robô depende de o microfone simulado ter um
  fundo acima de 0,001 (senão ele cai em "mudo no sistema"). A prova de hoje
  já passa com isso; confira com um `print` do `_maior_nivel` na contagem.
- **O mudo é do jogo.** O Botão do microfone no controle de verdade também
  pode mudar o sistema; o minigame não depende disso: `_mudo[l]` manda.
- **`Forja.robo` só no `robo()`** — o `_robo_bancada` é chamado de dentro
  dele, e não tem a palavra.
- **A luz do mudo não é identidade** (não é a barra nem as luzinhas): pode
  acender e apagar à vontade.
- **O `dt` no `_ouvir`** é o piso andando (uma medida), não o mundo; o mundo
  (o guardião, a chama) anda pela batida.
- **Não chame `Forja.vibrar`** (o susto de hoje chamava): `sentir`.

## Pronto quando

`--sala=voz` abre A Voz no kit; joga do aviso ao resultado com 4, 3, 2 e 1
jogador e com o robô nos três temperamentos; aguenta o cabo que cai e volta;
fecha com o resultado coop (a forja acesa ou não) e o destaque; sem a
bancada, nenhuma pergunta; com `--bancada`, os três vereditos saem como hoje
(e caem com os defeitos de mentira do microfone e do LED, no gauntlet);
`salas/voz.gd` saiu; `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`
passam, e a prancha foi olhada (o guardião de pedra, as chamas, o rugido).

## Provas

Em `godot/testes/prova_do_jogo.gd`, no lugar do bloco "A Voz" de hoje (o
`SalaVoz.MUDO` some):

```gdscript
## S08_J36: o robô chama e sopra no microfone do controle dele; no susto, o
## mudo acende o LED de quem apertou, e só o dele; os três vereditos da voz.
func _prova_a_voz() -> void:
	var sala = await _comeca_a_sala("voz")
	if sala == null:
		return
	_esperar(sala.id == "S08_J36", "voz: o apelido abre o S08_J36")
	var inicio := Time.get_ticks_usec()
	while is_instance_valid(sala) and Ritmo.batida() < sala._s0 + 3.8 and Time.get_ticks_usec() - inicio < 90000000:
		await _quadros(1)
	if is_instance_valid(sala):
		for l in 4:
			var aceso := int(_perc(l).get("led_mic", 0)) != 0
			_esperar(aceso == bool(sala._mudo[l]), "voz: o LED do mudo do P%d %s" % [l + 1, "aceso" if sala._mudo[l] else "apagado"])
		_esperar(sala._chama > 0.0, "voz: a chama subiu com os sopros (%.2f)" % sala._chama)
	await _termina_a_sala(sala, ["microfone", "microfone_mudo", "led_microfone"])
```

(A lista de vereditos esperados por modo é a que a F01 deixou: sem a
bancada, `led_microfone` não se exige.) E no `_prova_do_relatorio()`: há
`voz` do `S08_J36` de cada lugar (`comecou` ≥ 2 por lugar) e há `saida` com
`o == "led_microfone"`.

`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

**Com o André (local):** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`;
`./run-local.sh -- --sala=voz`. Quatro pessoas no sofá: a regra do ar tem de
dar a voz a quem falou (se a voz de um acende o braseiro do vizinho, anote o
`nivel` dos dois na `voz` e ajuste `MARGEM_AR`); o sopro junto tem de soar
como coro; o rugido tem de assustar quem não ficou mudo, e a luz laranja tem
de ser o alívio. Com um controle mudo no sistema: ele sopra sozinho, e
ninguém trava.

## Ao terminar

- No [quadro](README.md), a linha P1: **feito**, com o commit e o gasto real.
- Commit sugerido (sem trailer):
  `feat: A Voz no kit — o sopro em coro, o mudo é o escudo, sem pergunta`
