# M5 — A Catapulta

**Sprint:** M · **Slot:** S05_J25 · **Tamanho:** M · **Depende de:** H04, H08, F09, M1, M4

## Por quê

O segundo 2v2 da seção, e o único em que a carga passa **de um dedo para o outro**. Na dupla, um puxa a corda: o
R2 dele resiste cada vez mais. O outro trava no contratempo: o R2 dele tem a parede e o clique da Weapon. Quando o
primeiro solta a corda, o peso passa para o dedo do segundo, que segura e lança. A pedra só voa se os dois fazem a
parte no tempo. O verbo é **carregar e passar adiante**.

A melhor falha do jogo também é dos dois: a trava que escapa joga a pedra no próprio castelo. O buraco fica até o
fim, com a bandeira da outra dupla espetada nele.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o kit, a ficha de dados, o catálogo, a régua, o `2v2`)
- [A M1, «A cena»](M1-a-galeria.md#a-cena) (o cenário comum `CenarioDaGaleria`, a luz, o impacto e o
  `_joga_o_minigame` da prova)
- [A M4, «Como se joga»](M4-espada-de-fita.md#como-se-joga) (as duplas do kit, o Aprendiz, a `equipe_vencedora()` trocada e o
  `_r2`)

Tudo o que esta ficha tira da bíblia de arte, do mapa do áudio, da régua da diversão e do RPG está escrito aqui ou
na M1, com o número. O cenário comum da M1 não muda nesta ficha: ela só o usa.

## Arquivos que mudam

- `godot/scripts/minigames/s05/a_catapulta.gd` (novo, com o `.uid` que o Godot gera)
- `godot/scripts/minigames/catalogo.gd`: o slot `S05_J25` em `MINIGAMES` e na seção `S05`. **De todos:** as M1 a
  M5 mudam este arquivo
- `godot/scripts/traducoes.gd`: as frases novas. **De todos:** as M1 a M5 mudam este arquivo
- `godot/testes/prova_do_jogo.gd`: a prova da Catapulta. **De todos:** as M1 a M5 mudam este arquivo

## Como se joga

A faixa é `mus_s05_j25`, a 135 bpm (1 batida = 0,444 s). São 90 s, ou 202 batidas. Sem a faixa, a trilha
`"galeria"` toca a 104 bpm, e tudo abaixo está em batidas.

**As duplas** são as da M4: as equipes do kit (H08), e o Aprendiz da Q1 completa a dupla que tem menos de dois.
Toda dupla tem sempre dois na catapulta.

**Os postos.** Cada dupla tem duas vagas. A **vaga de fora** é o **puxador**; a **de dentro**, o **travador**:

| vaga | x | z |
| --- | --- | --- |
| Brasa, puxador | −6,0 | 1,4 |
| Brasa, travador | −2,0 | 1,4 |
| Maré, puxador | 6,0 | 1,4 |
| Maré, travador | 2,0 | 1,4 |

- No começo, o 1º da dupla (`da_equipe(e)[0]`) puxa e o 2º trava. O Aprendiz fica com a vaga que sobra.
- **A troca:** os compassos `c` com `c % TROCA_A_CADA == 0` (8, 16, 24…) não têm lançamento. Neles, os dois da dupla
  trocam de vaga e de posto (A cena).
- **O respiro:** no tempo 1 da troca, os dois R2 vão a `GATILHO_OFF` por 1 batida. No tempo 2, o novo puxador
  recebe a corda parada, e o novo travador recebe a trava.
- O `raia(l)` do kit anda com o cavaleiro (`raia(l).position = VAGA`).

**O gatilho diz o posto:**
- o puxador fica com `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, CORDA_PARADA)` (1);
- o travador fica com `Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 7)`: a parede de 2 a 6, força 7, e o clique.

**O lançamento** de cada dupla no compasso `c` (`b0 = 4c`, gerado quando `Ritmo.batida() >= 4c − 4`), com os
tempos da parte (os terços pelo tempo de música de `b0`, `CenarioDaGaleria.andamento_em(self, t)`):

| parte | segundos (de 90) | `puxa` (puxador aperta) | `trava` (travador aperta até o clique) | `solta` (puxador solta) | `lanca` (travador solta) |
| --- | --- | --- | --- | --- | --- |
| entrada | 0 a 30 | `b0` | `b0 + 1,5` | `b0 + 2` | `b0 + 3` |
| **pico** | 30 a 60 | `b0` | `b0 + 2,5` | `b0 + 3` | `b0 + 3,5` |
| saída | 60 a 90 | `b0` | `b0 + 1,5` | `b0 + 2` | `b0 + 3` |
| **a reta** | as últimas 16 batidas (82,9 a 90 s a 135 bpm) | como na saída | como na saída | como na saída | como na saída; a pedra em chamas |

- **A trava é sempre no contratempo.** No pico, ela cai no «e» do tempo 3, e o lançamento vem 1 colcheia depois da
  soltura: o contratempo mais difícil.
- **A partitura simples:** quem está com `Ritmo.simples[l]` fica com os tempos da entrada também no pico. Se é o
  travador, a dupla toda usa os tempos da entrada naquele compasso.
- **A contagem:** no compasso 0, na batida 2, as duas catapultas disparam vazias, com o som do vazio. A sala vê o
  movimento antes da primeira pedra.

**As notas.** Cada nota é `nova_nota(l, n, Ritmo.t_da_batida(b))` na geração, no lugar de quem tem o posto
naquele compasso. `n = int(round(b * 4))` nas de apertar (`puxa`, `trava`) e `int(round(b * 4)) + 1` nas de soltar
(`solta`, `lanca`). Os dados ficam em `_info[l][n] = {"b": b, "tipo": ..., "c": c, "d": <a dupla>}`. O mesmo
lugar nunca tem duas notas na mesma batida.

**Apertar** casa com `casar_toque(l)`: o puxador a partir de `CenarioDaGaleria.R2_APERTA` (0,5), e o travador a
partir de `R2_CLIQUE` (0,62), que é o clique da Weapon. **Soltar** é o R2 caindo até `R2_SOLTA` (0,2), com a nota de
soltar em aberto: `julgar_nota(l, n)` direto. Guarde `_nota_em_curso[l] = n` antes de julgar.

**A corda e a carga:**
- **A puxada boa** faz a corda pesar no R2 do puxador: Feedback (2, 2), e +2 a cada meia batida, até a força final
  `mini(8, 2 + 2 * DANO[j_puxa])`. São 4 no BOM, 6 no ÓTIMO e 8 no PERFEITO: o dedo sente se puxou bem.
- **A trava boa:** o puxador sente o clique do outro (`toque_dir` ou `toque_esq`, do lado em que o travador está).
  O travador ouve o `clique` no alto-falante; no PERFEITO, quem toca é o kit.
- **A soltura boa:** a carga passa. O R2 do puxador volta a (2, 1), e o do travador vai a Feedback (2, força final
  da corda) até o lançamento. Ele sente o peso que o outro largou, e o toque do lado do puxador.
- **O lançamento:** o R2 do travador volta à trava, (2, 6, 7), e a pedra voa.

**O que cada julgamento faz:**

| nota | ERRO (ou perdida) |
| --- | --- |
| `puxa` | a concha vai vazia: as outras notas seguem, e o braço dispara sem pedra |
| `trava` | **a corda escapa:** a pedra cai no próprio castelo. A `solta` e a `lanca` daquele lançamento ficam caladas (`_info.calada`) |
| `solta` ou `lanca` | a pedra sai torta: o dano pela metade |

**O dano** do lançamento é a soma de `DANO[j]` (0, 1, 2, 3) das quatro notas, de 0 a 12. Depois vêm os fatores,
nesta ordem, arredondando para baixo no fim:

| quando | fator |
| --- | --- |
| a pedra torta | ×0,5 |
| a concha maior (abaixo) | ×1,5 |
| o castelo rival já sem a muralha da frente (do pico em diante) | ×1,5 |
| a reta: a pedra em chamas | ×2 |

A pedra cai no castelo da outra dupla em `Ritmo.t_da_batida(b_lanca + 1,5)`: o voo tem 1,5 batida. Nesse quadro,
`vida[1 − d] -= dano` e `marcar_equipe(d, dano * PONTOS_POR_DANO)`. Os pontos das notas vão à dupla de quem tocou:
`marcar_equipe(equipe[l], PONTOS[j])` (40, 70, 100), sempre pelo kit, que passa pelo item.

**A pedra no próprio castelo** (a corda escapou com pedra na concha). Ela faz um arco curto e cai no castelo da
própria dupla em `Ritmo.t_da_batida(b_trava + 1)`:
- `vida[d] -= PROPRIO` (12);
- `CenarioDaGaleria.momento(self, "pedra_propria", l)`, com `l` o travador, ou −1 se ele é o Aprendiz;
- o buraco e a bandeira da outra dupla ficam até o fim (A cena).

**O pico.** No primeiro quadro com `no_pico()`, chame `CenarioDaGaleria.pico(self)`. A muralha da frente dos dois
castelos desaba (A cena), e daí até o fim toda pedra acerta a torre (×1,5).

**A dupla de trás.** Nos compassos `c` com `c % 4 == 2`, a dupla com o castelo de menos vida (estritamente) lança
com a **concha maior**: a concha cresce no aviso, a pedra é maior, e o dano vale ×1,5.

**As vidas.** As duas contas saem no `iniciar_jogo`:
`VIDA = int(round(VIDA_POR_BATIDA * 90.0 * Ritmo.bpm / 60.0))`, com 2,5 por batida: 506 a 135 bpm e 390 a 104.
- Na mesa boa (perto de 9,6 de dano por lançamento antes do pico), a conta derruba o castelo perto dos 80 s.
- Se a mesa boa derrubar antes de 60 s, `VIDA_POR_BATIDA` sobe 0,5 até cair depois.
- **O castelo cai** com a vida em 0: `Forja.sentir(l, "explosao")` nos dois da dupla dele, e todos `acabou`.

**A reta.** No primeiro quadro com `CenarioDaGaleria.na_reta(self)`, chame
`CenarioDaGaleria.momento(self, "reta", -1)`. Daí até o fim, toda pedra sai em chamas e vale o dobro.

Todo aperto e toda soltura julgados gravam
`anotar("entrada", l, {"o": "disparo", "n": n, "modo": <"resistencia" ou "arma">, "curso": r2, "curso_max": <o maior R2 desde o aperto>})`.
Todo lançamento grava `anotar("jogo", -1, {"o": "lancamento", "dupla": d, "dano": dano, "como": <"inteira", "torta", "vazia" ou "escapou">})`.

### A ficha de dados

O cabeçalho do script `godot/scripts/minigames/s05/a_catapulta.gd` é um comentário `#` com estas linhas:
- **o jogo:** cada dupla tem uma catapulta e um castelo. O puxador puxa a corda no tempo 1 (Feedback que pesa a cada
  meia batida) e solta no tempo 3; o travador aperta até o clique no contratempo (Weapon), recebe o peso da corda e
  lança no tempo 4. A cada 8 compassos, os dois trocam de posto;
- **a falha:** a trava fora do tempo deixa a corda escapar, e a pedra cai no próprio castelo; a puxada fora do tempo
  deixa a concha vazia; a soltura fora do tempo entorta a pedra (meio dano);
- **o vencedor:** a dupla de castelo de pé, depois a que tem mais vida no castelo, depois mais pontos;
- **o alto-falante do dono:** o clique da trava, a coleta da pedra no castelo rival e o golpe da pedra no próprio;
- **o registro:** a corda (Feedback), a trava (Weapon), a carga no travador (Feedback) e o respiro (Off); o curso
  do R2 em cada nota; o `lancamento`;
- **o robô:** faz a parte do posto pelo relógio da música; quando não acerta, 250 ms tarde;
- **com menos de quatro:** o Aprendiz completa as duplas (H08), como na M4;
- **a régua:** (1) «Carregue e lance!» com a catapulta e o castelo rival; (2) sim: o posto e o tempo estão no
  gatilho; (3) não pergunta nada.

```gdscript
extends Minigame

const FICHA := {
	"slot": "S05_J25",
	"titulo": "A Catapulta",
	"verbo": "Carregue e lance!",
	"genero": "2v2",
	"icone": "gatilho_adaptativo",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S05_J25",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao", "toque_dir", "toque_esq"],
	"material": "madeira",
	"microjogo": {"verbo": "Lance!", "segundos": 6.0},
	"gesto": "interact-right",
}
```

### As constantes

```gdscript
const PONTOS := [0, 40, 70, 100]  # ERRO, BOM, OTIMO, PERFEITO, por nota, para a dupla
const DANO := [0, 1, 2, 3]  # o que cada nota põe na pedra
const PONTOS_POR_DANO := 10
const PROPRIO := 12  # a pedra no próprio castelo
const VIDA_POR_BATIDA := 2.5
const ACERTO_APRENDIZ := 0.8
const TROCA_A_CADA := 8  # compassos
const CORDA_PARADA := 1
const CORDA_INICIO := 2
const CORDA_PASSO := 2  # a cada meia batida
const TRAVA := [2, 6, 7]  # Weapon: começo, fim, força
const TEMPOS := [[0.0, 1.5, 2.0, 3.0], [0.0, 2.5, 3.0, 3.5], [0.0, 1.5, 2.0, 3.0]]  # puxa, trava, solta, lanca
const VOO_B := 1.5
const CONCHA_MAIOR := 1.5
const TORRE := 1.5
const VAGAS := [[Vector3(-6.0, 0, 1.4), Vector3(-2.0, 0, 1.4)], [Vector3(6.0, 0, 1.4), Vector3(2.0, 0, 1.4)]]
const RECUO_M := 0.5
```

### A falha

Toda falha muda a silhueta e deixa rastro (a régua: 0,5 m ou mais por pelo menos 1 batida, e rastro de 2 s ou
mais).

- **A corda escapa** (trava ERRO, com pedra na concha):
  - o braço volta sozinho, e a pedra faz o arco curto até o próprio castelo em 1 batida;
  - **o puxador é puxado pela corda e cai:** `_recuar(l, RECUO_M)` para a frente, para o lado da catapulta (o
    recuo da M4), e `gesto("fall", 0.5)`. O R2 dele fica em `GATILHO_OFF` por `CenarioDaGaleria.queda_s(l, 2.0)`;
    depois, a corda parada. A puxada seguinte se julga normalmente, mas a corda só pesa quando ele levanta;
  - o travador: `gesto("emote-no", 0.4)`;
  - no castelo: o buraco, a bandeira e a fumaça (A cena), que ficam até o fim.
- **A concha vazia** (puxada ERRO): o braço dispara sem pedra no lançamento, e o puxador recua 0,5 m, com
  `emote-no`. A corda caída fica no chão por 2 s.
- **A pedra torta** (soltura ou lançamento ERRO): a pedra voa baixa e bate na base do castelo rival. Ela deixa uma
  mancha OXIDO `#3b2a22` de Ø 0,6 m no chão, por 4 s. Quem errou recua 0,5 m, com `emote-no`.
- **A volta:** o compasso seguinte é um lançamento novo. O monte de pedras não acaba.

### O fim e o vencedor

`fim` `tempo`: aos 90 s de música, ou antes, quando um castelo cai (todos `acabou`). A tela diz «A Brasa venceu!» ou
«A Maré venceu!» pela `equipe_vencedora()`, trocada como na M4:

```gdscript
# A dupla na frente: castelo de pé, depois mais vida no castelo, depois mais pontos. -1 no empate.
func equipe_vencedora() -> int:
	var de_pe := [1 if vida[BRASA] > 0 else 0, 1 if vida[MARE] > 0 else 0]
	var pts := [pontos_da_equipe(BRASA), pontos_da_equipe(MARE)]
	for par in [de_pe, vida, pts]:
		if int(par[0]) != int(par[1]):
			return BRASA if int(par[0]) > int(par[1]) else MARE
	return -1
```

O `vencedor()` é o da M4: a dupla na frente primeiro e, dentro dela, quem somou mais `VALOR` nas próprias notas
(`_valor[l]`, com `DANO` no lugar de `VALOR`). O destaque é o padrão do kit.

### Com menos de quatro

- **Com três, dois e um,** o Aprendiz completa (a tabela da M4). Ele ocupa o posto que sobra e troca de vaga como
  qualquer um. `com_poucos()` diz `"Com o Aprendiz"` com três e dois, e `"Você e o Aprendiz contra 2"` com um.
- **O Aprendiz** acerta cada nota com 0,8 (o `rng` do kit), sempre como BOM. Na trava que ele erra, a corda escapa
  como em qualquer trava ERRO.
- **O controle que cai:** a parte dele é sorteada como a de um Aprendiz até ele voltar. As notas dele saem caladas
  pelo kit. A troca de posto não espera por ele.

### O robô

```gdscript
# O robô faz a parte do posto pelo relógio da música: aperta na nota de
# apertar (até o fundo, além do clique) e segura até a nota de soltar.
# Quando não acerta (Forja.robo_acerta() falso), 250 ms tarde: na trava, a
# corda escapa. As notas caladas não contam.
var _robo_nota := [-1, -1, -1, -1]
var _robo_aperta_em := [INF, INF, INF, INF]
var _robo_solta_em := [INF, INF, INF, INF]


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var abertas := notas_em_aberto(l).filter(func(nn): return not bool(_info[l][nn].get("calada", false)))
	if not abertas.is_empty() and int(abertas[0]) != _robo_nota[l]:
		var nn: int = abertas[0]
		_robo_nota[l] = nn
		var em := alvo_da(l, nn) + (0.0 if Forja.robo_acerta() else 0.25)
		if str(_info[l][nn].tipo) in ["puxa", "trava"]:
			_robo_aperta_em[l] = em
			_robo_solta_em[l] = INF
		else:
			_robo_solta_em[l] = em
	var agora := Ritmo.t_musica()
	var segura := agora >= float(_robo_aperta_em[l]) and agora < float(_robo_solta_em[l])
	Forja.robo_eixo(l, Forja.R2, 1.0 if segura else 0.0, 0.06)
```

A prova olha o primeiro byte (`Forja.percepcao(l)["gatilho_dir"]`): `0x21` a corda e a carga, `0x25` a trava e
`0x05` o respiro.

### Os ganchos

```gdscript
var _info := [{}, {}, {}, {}]  # lugar -> n -> {b, tipo, c, d, calada}
var _nota_em_curso := [-1, -1, -1, -1]
var _gerado := 1
var _apertado := [false, false, false, false]
var _disparo := [{}, {}, {}, {}]
var _gat := [[], [], [], []]  # o último [modo, a, b, c] mandado ao R2
var _sem_corda_ate := [-1.0, -1.0, -1.0, -1.0]  # a queda, em t_musica
var _valor := [0, 0, 0, 0]
var _posto := [[-1, -1], [-1, -1]]  # dupla -> [o lugar do puxador, o do travador]; -1 é o Aprendiz
var _lances := {}  # "c:d" -> {j: [puxa, trava, solta, lanca], forca, concha, como, resolvido}
var _pedras := []  # [{d, alvo: dupla, t, dano, chamas}] no ar
var vida := [0, 0]
var _muralha := true
var _reta_feita := false
var n := {}  # "catapultas", "castelos", "muralhas", "buracos", "montes"; lugar -> {disco}


func montar() -> void:
	camera_pos = Vector3(0, 8.4, 11.6)
	camera_olhar = Vector3(0, 0.8, -2.4)
	CenarioDaGaleria.montar(self)
	_montar_os_castelos_e_as_catapultas()  # A cena
	for e in [BRASA, MARE]:
		var lugares := da_equipe(e)
		_posto[e] = [lugares[0] if lugares.size() > 0 else -1, lugares[1] if lugares.size() > 1 else -1]
		for i in 2:
			var l: int = _posto[e][i]
			if l < 0:
				_montar_o_aprendiz(e, VAGAS[e][i])  # o boneco da M4
				continue
			var p := jogador(l)
			raia(l).position = VAGAS[e][i]
			posicionar(l)
			p.position = VAGAS[e][i] + Vector3(0, 0.1, 0)
			p.rotation.y = PI
			p.preso = true
			n[l] = {"disco": _disco_da_dupla(e, VAGAS[e][i])}
	_dar_os_gatilhos()  # a corda parada ao puxador, a trava ao travador


func sair() -> void:
	CenarioDaGaleria.sair(self)
	super()


func iniciar_jogo() -> void:
	var v := int(round(VIDA_POR_BATIDA * 90.0 * Ritmo.bpm / 60.0))
	vida = [v, v]


func jogar(_dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # os lançamentos, a troca, a concha maior
		_gerado += 1
	_o_mundo()  # a contagem vazia, a troca e o respiro, o pico e a muralha, a reta
	for l in presentes():
		notas_perdidas(l)
		if not conectado(l):
			_apertado[l] = false
			continue
		var r2 := Forja.eixo(l, Forja.R2)
		if _apertado[l]:
			_disparo[l]["curso_max"] = maxf(float(_disparo[l].get("curso_max", 0.0)), r2)
		var limiar := CenarioDaGaleria.R2_CLIQUE if _e_travador(l) else CenarioDaGaleria.R2_APERTA
		if not _apertado[l] and r2 >= limiar:
			_apertado[l] = true
			_apertar(l, r2)
		elif _apertado[l] and r2 <= CenarioDaGaleria.R2_SOLTA:
			_apertado[l] = false
			_soltar(l, r2)
		_puxar_a_corda(l)  # +2 a cada meia batida até a força final; a volta da queda
	_os_aprendizes()  # sorteia as notas do Aprendiz e de quem está fora, na batida delas
	_voar_as_pedras()  # pela batida; ao cair, o dano, o castelo e o fim
	if (vida[0] <= 0 or vida[1] <= 0) and not acabou.all(func(a): return a):
		_o_castelo_cai()


func toque(l: int, julgamento: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	marcar_equipe(equipe[l], PONTOS[julgamento])
	_valor[l] += DANO[julgamento]
	_guardar(info, julgamento)  # em _lances["c:d"].j
	match str(info.get("tipo", "")):
		"puxa":
			_r2(l, [Forja.GATILHO_RESISTENCIA, 2, CORDA_INICIO, 0])
		"trava":
			_parceiro_sente(l)  # toque_dir ou toque_esq no puxador
			if julgamento != Ritmo.PERFEITO:
				Forja.som_falante(l, "clique", 0.7)
		"solta":
			_r2(l, [Forja.GATILHO_RESISTENCIA, 2, CORDA_PARADA, 0])
			_a_carga_passa(info)  # Feedback (2, força final) no travador, e o toque do lado
		"lanca":
			_lancar(info)


func falha(l: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	_guardar(info, Ritmo.ERRO)
	match str(info.get("tipo", "")):
		"puxa":
			_concha_vazia(info)
		"trava":
			_a_corda_escapa(info)  # cala a solta e a lanca; a pedra no próprio castelo
		"solta":
			_r2(l, [Forja.GATILHO_RESISTENCIA, 2, CORDA_PARADA, 0])
			_a_carga_passa(info)
		"lanca":
			_lancar(info)  # torta
	if str(info.get("tipo", "")) != "trava":
		_recuar(l, RECUO_M)
		jogador(l).gesto("emote-no", 0.4)


func nota_perdida(l: int, nn: int) -> void:
	_nota_em_curso[l] = nn
	if bool(_info[l].get(nn, {}).get("calada", false)):
		return
	super(l, nn)


# Quem espera a vez na dupla manda adesivo (G04): o puxador, da soltura ao
# aviso da puxada seguinte.
func fora_da_rodada(l: int) -> bool:
	return not _e_travador(l) and notas_em_aberto(l).is_empty() and not _aviso_aceso(l)
```

- `_r2(l, g)`, `_recuar(l, m)` e `_montar_o_aprendiz(e, vaga)` são métodos do script da M4
  (`espada_de_fita.gd`), e a Catapulta não herda dele: copie os três para `a_catapulta.gd`. O arquivo da M4
  não muda. O `_r2` manda só quando o `[modo, a, b, c]` muda.
- `_puxar_a_corda(l)`: do aperto bom da `puxa` até a `solta`, a força é
  `mini(forca_final, CORDA_INICIO + CORDA_PASSO * floor((Ritmo.batida() − b_puxa) * 2))`, pelo `_r2`. Durante a
  queda (`_sem_corda_ate`), `[GATILHO_OFF, 0, 0, 0]`.
- `_lancar(info)`: resolve o lançamento uma vez (`resolvido`), calcula o dano pela tabela, dispara o braço e põe a
  pedra no ar em `_pedras`, com o `t` da queda. O R2 do travador volta à `TRAVA`.
- `_o_mundo()`: na troca, o `GATILHO_OFF` nos dois no tempo 1, a corrida e a troca de `_posto` e de `raia`, e
  `_dar_os_gatilhos()` no tempo 2; o `sino_viga` na TV.
- `status(l)`: `"%d de vida" % vida[1 - equipe[l]]` quando `na_raia(l)`: a vida do castelo rival.
- `dica(l)`: `{"partes": ["@r2", "Puxe a corda"]}` para o puxador e `{"partes": ["@r2", "Trave e lance"]}` para o
  travador, só com `na_raia(l)` e `not aprendeu(l)`.

### O catálogo e as traduções

- No `catalogo.gd`: `Catalogo.MINIGAMES["S05_J25"] = preload("res://scripts/minigames/s05/a_catapulta.gd")`, e
  `"S05_J25"` na lista `"minigames"` da seção `S05`, depois do `S05_J24`.
- O `.uid` novo: `a_catapulta.gd.uid`, gerado com `"$GODOT" --headless --path godot --import --quit`.
- As traduções que ainda não existirem: `"A Catapulta": "The Catapult"`, `"Carregue e lance!": "Load and launch!"`,
  `"Lance!": "Launch!"`, `"Puxe a corda": "Pull the rope"`, `"Trave e lance": "Lock and launch"`,
  `"%d de vida": "%d health"`. As duas do Aprendiz vêm da M4.

### O registro

- **A `saida` de gatilho**, gravada pelo `Forja` (F06): `lado` `"R2"`, com `modo` `"resistencia"` e `params`
  `[2, f, 0]` (a corda, f de 1 a 8, e a carga no travador), `"arma"` com `[2, 6, 7]` (a trava) e `"off"` (o respiro
  da troca e a queda).
- **`entrada` `disparo`** nas quatro notas, o `toque` do kit e `jogo` `lancamento` com a `dupla`, o `dano` e o
  `como`.
- **A linha `momento`** por `CenarioDaGaleria.momento`: `pedra_propria` (o travador) e `reta` (lugar −1).
- **O cruzamento:** a trava no tempo, com o `curso` logo acima de 0,62 e a Weapon `ok`, é o clique que chegou. O
  mesmo lugar travando cedo sempre, com o `curso` baixo, é a parede que não chegou naquele controle.

### Armadilhas

- **O limiar do aperto depende do posto:** o travador só aperta no clique (`R2_CLIQUE`), e o puxador em
  `R2_APERTA`.
- **A trava ERRO cala o resto do lançamento.** A falha dela já é a pedra no próprio castelo; a `solta` e a `lanca`
  não viram mais erros.
- **A troca muda o modo dos dois**, no compasso sem notas, depois do respiro de 1 batida.
- **O dano se calcula uma vez**, no lançamento, e cai pelo relógio da música, em `b_lanca + 1,5`.
- **A cor da dupla nunca vai para a barra de luz** (F04).
- **O L2 é do item.** A catapulta é só o R2.
- **Não declare `_notas`.** A fila é do kit (H08). O que é da Catapulta fica em `_info`.

## A cena

### A câmera

Plano fixo, `"camera": "fixa"`, sem corte do apito ao apito:
- posição `Vector3(0, 8.4, 11.6)`, olhando para `Vector3(0, 0.8, -2.4)`. A plongée é de 28°;
- lente de 35 mm (FOV vertical 37,8°).

A câmera é mais alta que a da M1 para caber os dois castelos (a 17,6 m de profundidade, o quadro mostra ±10,7 m na
horizontal) e os puxadores em x ±6 (a 12,5 m, ±7,6 m). O tremor vem de `CenarioDaGaleria.impacto`.

### A luz

A da M1, por `CenarioDaGaleria.montar(self)`: a névoa NEVOA `#18081c`, o preenchimento PREENCHIMENTO `#4a2854`
(energia 0,35), a chave CHAVE `#f8ccba` (energia 1,0) e o néon do mundo VIOLETA `#4a3aa8`.

- **O pico:** `CenarioDaGaleria.pico(self)` quando a muralha cai.
- **Nenhuma cor nova.**

### As peças

| peça | de onde | o papel | escala pedida |
| --- | --- | --- | --- |
| a catapulta | `castle-kit/siege-catapult`, por `peca_ou`; o substituto é `Kit.peca(pai, "wood-structure", Vector3.ZERO, 0.0, 1.6)` com um braço `Kit.caixa` 0,22 × 0,22 × 2,0 m | entre as vagas da dupla, em (∓4,0, 0, −0,2), virada para o castelo rival: `rot_y = atan2(−dz, dx)`, 0,475 rad na Brasa e 2,667 rad na Maré | 1,0 (×1,4 do pacote: 3,0 m de comprido) |
| o braço | o nó `catapult` do GLB (`find_child("catapult")`), que gira em `rotation.z` | carregar: de 0 a +0,15 rad com a corda; disparar: a −1,4 rad em 0,15 s, e de volta em 1 batida | — |
| a concha e a pedra | a pedra é `Kit.peca(braço, "rocks", <a ponta>, 0.0, 0.5)`; na concha maior, 0,8, e a ponta do braço a ×1,5 | na ponta do braço, x −1,0 do nó | — |
| a corda | `Kit.caixa` 0,04 × 0,04 × 1,0 m OXIDO `#3b2a22`, fosca | da ponta do braço à mão do puxador, refeita a cada quadro | — |
| o monte de pedras | `Kit.peca(self, "stones", <ao lado da catapulta, 1,2 m para fora>, 0.0, 1.2)` | encolhe de 1,2 a 0,5 ao longo dos 8 compassos do posto, e enche na troca | — |
| o castelo | a torre de `castle-kit/tower-square-base`, `tower-square-mid`, `tower-square-mid-windows` e `tower-square-top-roof`, por `peca_ou`; o substituto é `Kit.peca(pai, "wall", ..., 0.0, 2.0)` em 3 andares | em (−6,5, 0, −6,0) o da Brasa e (6,5, 0, −6,0) o da Maré | 1,5 (2,1 m de largura, 1,4 m por andar) |
| a muralha da frente | 3 `castle-kit/wall`, por `peca_ou`; o substituto é `Kit.peca(pai, "wall", ..., 0.0, 2.0)` | 1,4 m na frente da torre, de x −2,1 a 2,1 dela | 1,5 (2,75 m de altura) |
| a bandeira do castelo | `castle-kit/flag`, tingida inteira na cor da dupla (`SalaProva._tingir`) | no topo da torre | 2,0 (2,4 m) |
| o disco da dupla | o da M4: `Kit.cilindro` Ø 1,4 × 0,02 m, `CORES_DAS_EQUIPES[e]`, fosco | sob os pés de cada vaga | — |
| o buraco | `Kit.cilindro` Ø 1,0 × 0,02 m GRAFITE `#3a3346`, deitado na face da torre, e `castle-kit/rocks-small` ao pé | na torre da dupla que levou a pedra própria; até 4, um por andar, de baixo para cima | 1,0 |
| a bandeira espetada | `castle-kit/flag` tingida na cor da **outra** dupla, inclinada 0,4 rad | no buraco, até o fim | 1,2 |
| os destroços | `castle-kit/siege-catapult-demolished` não entra; a muralha caída vira `castle-kit/rocks-small` | ao pé da muralha, do pico em diante | 1,5 |
| o Aprendiz | o da M4 (`character-human`, ETIQUETA_SOMBRA `#cfc2a0`) | na vaga que sobra | 2,0 |

- **Os pacotes.** O Castle Kit tem `FATOR` 1,4 no `peca_ou` (a G10). Sem o pacote importado, o `peca_ou` põe o
  substituto.
- **A pedra no ar:** da ponta do braço ao castelo rival em `VOO_B` (1,5) batida, em parábola com 6 m de altura no
  meio. Na reta, a pedra em chamas leva `Efeitos.brasas(<a pedra>, Vector3.ZERO, Vector3(0.4, 0.4, 0.4), CenarioDaGaleria.TUNGSTENIO, 24)`.
- **O castelo apanha:** a cada 25 % de vida perdida, a peça de cima cai ao chão em 1 batida e some. Em 0, a torre
  inteira desaba em 1 batida.
- **A pedra própria:** o arco curto sobe 2 m e cai na torre da própria dupla em 1 batida; ali ficam o buraco, a
  bandeira da outra dupla e a fumaça `Efeitos.poeira(self, <o buraco>, Vector3(0.6, 1.2, 0.6), CenarioDaGaleria.GRAFITE, 12)`
  até o fim.
- **A muralha do pico:** as três peças tombam para a frente em 1 batida, viram destroços, e a fumaça sobe 2 s.
- **A troca:** os dois da dupla correm um para a vaga do outro em 0,5 s (`animar("sprint")`), e o `raia` vai junto.

### O que brilha, e de quem é o brilho

| o quê | cor | emissivo | dono |
| --- | --- | --- | --- |
| a borda da raia | a cor do lugar | a do kit; 1,0 do aviso à nota | o jogador |
| a pedra em chamas e as brasas | TUNGSTENIO `#ffd9a8` | 2,4 | a forja |
| as faíscas | TUNGSTENIO | chapadas | a forja |
| o néon do mundo | VIOLETA `#4a3aa8` | 3,0 hoje, 1,2 com a G15 | o mundo |

Nada mais brilha. A madeira, as pedras, o castelo, as bandeiras, o disco, o buraco e a fumaça são foscos.

### O impacto

Por `CenarioDaGaleria.impacto` (a tabela da M1):
- a pedra no castelo rival: `golpe` na torre (24 faíscas, tremor 0,167 por 1 batida), com `l` −1;
- a pedra no próprio castelo: `estrondo` na torre (50 faíscas, tremor 0,417 por 2 batidas), com `l` o puxador
  (o hit-stop de 50 ms nele, que cai);
- a muralha do pico: `estrondo` em cada castelo, com `l` −1;
- o castelo que desaba: `catastrofe` (60 faíscas, tremor 0,667 por 4 batidas, a chave a ×1,4).

## O som

| evento | id do mapa | onde | como |
| --- | --- | --- | --- |
| a música | `mus_s05_j25` (135 bpm, Lá menor, 150 s; queimada, quebra e explosão; seca, sem cauda de reverberação) | TV | `"faixa": "MUS_S05_J25"`; sem a faixa (H05), a trilha sintetizada `"galeria"` a 104 bpm |
| as quatro notas julgadas | `jul_ressonancia_p{n}`, `jul_afinado_p{n}`, `jul_quase_p{n}`, `jul_erro_p{n}` | TV e alto-falante | o kit (`_reagir`); a ficha não toca nada |
| a trava boa, menos o perfeito | `mod_clique` | alto-falante do travador | `Forja.som_falante(l, "clique", 0.7)` |
| a pedra no castelo rival | `pedra_*` e `mod_coleta` | TV e alto-falante dos dois que lançaram | `Som.tocar("pedra", <a torre>)` e `Forja.som_falante(l, "coleta", 0.7)` |
| a pedra no próprio castelo | `pedra_*` e `golpe_*` | TV e alto-falante dos dois da dupla | `Som.tocar("pedra", <a torre>)` e `Som.no_controle(l, "golpe", 0.7)` |
| a concha vazia e a contagem | `vazio_0` | TV | `Som.tocar("vazio", <a catapulta>)` |
| a troca de posto | `sino_0` a `sino_4` | TV | `Som.tocar("sino_viga", null, -6.0)` |
| a pedra em chamas | `sint_fogo` | TV | `Som.tocar("fogo", <a pedra>, -8.0)` no lançamento |
| o castelo desaba | `pedra_*` | TV | `Som.tocar("pedra", <a torre>)` duas vezes, com 1 colcheia entre elas |
| a falha | `fx_tropeco_*` | TV | o kit (H11); a ficha não toca nada |
| os carimbos | `car_em_chamas`, `car_acorde`, `jin_virada` (o carimbo `car_virada`), `car_por_um_fio` | TV | o kit e o HUD |

- **O alto-falante toca um som por vez**, na prioridade do kit: o julgamento, a coleta, o golpe e o clique.

## O controle

| recurso | evento | quem joga | os outros |
| --- | --- | --- | --- |
| **gatilho R2 (protagonista)** | o puxador, da puxada boa à soltura | `GATILHO_RESISTENCIA` (2, f): f de 2, +2 a cada meia batida, até 4, 6 ou 8 pelo julgamento da puxada | — |
| **gatilho R2 (protagonista)** | o travador, fora da carga | `GATILHO_ARMA` (2, 6, 7): a parede e o clique | — |
| gatilho R2 | o travador, da soltura do outro ao lançamento | `GATILHO_RESISTENCIA` (2, a força final da corda): a carga que passou | — |
| gatilho R2 | o puxador parado | `GATILHO_RESISTENCIA` (2, 1) | — |
| gatilho R2 | o respiro da troca | `GATILHO_OFF` por 1 batida, nos dois da dupla | — |
| gatilho R2 | o puxador que caiu | `GATILHO_OFF` por `queda_s(l, 2.0)` | — |
| vibração | as quatro notas julgadas | `acerto` (0,3/0,6, 80 ms), `perfeito` (0,5/0,8, 100 ms) ou `erro` (0,7/0,3, 160 ms), pelo kit | — |
| vibração | a trava boa e a soltura boa | — | o parceiro sente `toque_dir` ou `toque_esq` (0,4, 80 ms), do lado em que o outro está |
| vibração | uma pedra cai no castelo da dupla | — | `Forja.sentir(l, "golpe")` (1,0/0,6, 250 ms) nos dois da dupla que levou |
| vibração | o castelo cai | — | `Forja.sentir(l, "explosao")` (1/1, 400 ms) nos dois da dupla dele |
| háptica | o toque julgado | a textura `"madeira"`, pelo kit | — |
| barra de luz | sempre | a cor do lugar, 100 %; o kit pisca branco no perfeito e escurece no erro | a cor de cada um |
| luzinhas | sempre | o número do lugar | o número de cada um |
| alto-falante | O som | o clique, a coleta e o golpe | — |
| microfone | — | Não se aplica: a Catapulta não ouve | — |

**A prova sem o controle na mão:**
- o robô joga pelo relógio da música, e a prova junta os bytes do modo (`Forja.percepcao(l)["gatilho_dir"]`:
  `0x21` a corda e a carga, `0x25` a trava, `0x05` o respiro);
- os `params` da `saida` no registro dizem a corda, a trava e a carga.

## O cavaleiro

| stat | gancho | o que muda aqui |
| --- | --- | --- |
| Fôlego | `levantar` | o puxador que a corda derrubou fica sem corda por 2 batidas × (1 − 0,125 × (Fôlego − 3)); Fôlego 1 dá 2,5 batidas, e 5 dá 1,5 (`CenarioDaGaleria.queda_s(l, 2.0)`) |
| Faro | `pista` | a raia acende para a nota de apertar 20 ms × (Faro − 3) antes; Faro 5 dá +40 ms, e 1 dá −40 ms (`pista_s`). O aviso é `acender_raia(l, 1.0)` em `t_da_batida(b − aviso_b()) − pista_s(l)` |
| Peso | — | não muda nada |
| Passo | — | não muda nada |

- **Os itens são do kit:** o Martelo (pelo `marcar_equipe`, uma vez para a dupla), o Escudo (o primeiro erro), o
  Fole, o Diapasão e a Lanterna (somada pela `pista_s`).
- **A peça.** O cavaleiro fica de costas (`rotation.y = PI`), com as mãos vazias: a corda e a trava estão na
  catapulta. O item da mão direita fica à vista. As cores da montagem não mudam nesta ficha.

## As reações

- **Os adesivos `rea_*`:** só quem espera a vez na dupla manda. É o puxador, da soltura até o aviso da puxada
  seguinte: `fora_da_rodada(l)` devolve `true`. A roda de adesivos (G04) lê esse gancho.
- **Os carimbos são do kit e do HUD**, e esta ficha não chama nenhum: `car_em_chamas`, `car_acorde`, `car_virada` e
  `car_por_um_fio`.
- **A bandeira espetada é a provocação que fica.** A outra dupla vê a cor dela no castelo do rival até o fim.

## A diversão

**O momento: `pedra_propria`**
- **Quando:** a janela é a faixa inteira (0 a 90 s), na mesa das duplas. A trava escapa, o braço volta sozinho, a
  pedra faz o arco curto e cai no castelo da própria dupla, e o puxador é puxado pela corda e cai. É o gol contra do
  jogo. Degrau estrondo.
- **O que se vê:** a câmera treme 2 batidas, o puxador para 50 ms no chão, e o buraco fica na torre com a bandeira
  da outra dupla espetada, até o fim.

**Como o jogador do time confere:**
- **No registro,** pelo robô na mesa das duplas (P1 `bom` e P2 `ruim` na Brasa, P3 e P4 `medio` na Maré), semente
  7:
  - pelo menos **2 linhas `momento` `pedra_propria`** em 90 s;
  - pelo menos 1 delas com o lugar da Brasa (a dupla do P2 `ruim`);
  - para cada uma, uma linha `sensacao` `golpe` de um lugar da mesma dupla a até 1 batida depois.
- **Na prancha (F09):** no último quadro, o castelo da Brasa com o buraco e a bandeira turquesa.
- **A falha à vista:** o P2 (`ruim`) tem pelo menos 10 linhas `toque` com `erro` em 90 s. Em pelo menos 1 quadro de
  cada 5, há uma mancha no chão ou um cavaleiro recuado.
- **Quem está perdendo:** pelo menos 1 lançamento com a concha maior (`jogo` `lancamento` num compasso com
  `c % 4 == 2`, da dupla de menos vida) quando as vidas diferem.
- **Ninguém para:** a maior distância entre duas notas do mesmo lugar é de até 8 batidas (a troca).

Até o robô por lugar (`--robo=bom,ruim,medio,medio`, pedido ao arquiteto na régua) existir, a prova roda com o
`--robo` da `prova_do_jogo.sh` num temperamento só e confere o momento, o golpe no quadro e as `saida`; os
itens que pedem o P2 `ruim` (a falha à vista e o lugar da Brasa) esperam o robô por lugar.

## Pronto quando

A Catapulta joga do aviso ao resultado:
- com 4, 3, 2 e 1 jogador (o Aprendiz completa), e com o robô nos três temperamentos;
- troca os postos a cada 8 compassos, com o respiro;
- aguenta o cabo que cai no meio de um lançamento;
- fecha com a dupla na frente e a frase da equipe;
- abre o `S05_J25` com `--sala=S05_J25`;
- grava as linhas `momento` da pedra própria e da reta.

A prova do jogo passa, e a prova visual passa com a prancha olhada.

### Ao terminar

- No [quadro](README.md), quem coordena marca a linha **M5** com o commit. Com as cinco feitas, a linha **M** da
  seção também vira feita.
- Commit sugerido (sem trailer): `feat: A Catapulta, a corda num gatilho e a trava no outro, com a carga que passa`.

## Provas

Os comandos: `SALA=S05_J25 bash tests/prova_do_jogo.sh` (o sh roda duas rodadas, sem bancada e com
`--bancada`), `bash tests/prova_do_jogo.sh` (o jogo inteiro) e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a prova entra como uma linha no `match` de `_prova_da_ficha` (o modelo
da H08):

```gdscript
		"S05_J25": await _prova_da_catapulta()
```

E acrescente a função abaixo, depois da prova da Espada. O `_joga_o_minigame(slot, limite_s, a_cada_quadro)` é da H08.

```gdscript
# A Catapulta (S05_J25): numa dupla de dois, a corda num dedo e a trava no
# outro; a carga chegou ao travador; o castelo só perde vida; a trava é
# (2, 6, 7); a dupla na frente vem primeiro.
func _prova_da_catapulta() -> void:
	var postos_ok := [false]
	var vidas: Array = []
	var olhar := func(mg: Minigame) -> void:
		for e in [Minigame.BRASA, Minigame.MARE]:
			var par: Array = mg._posto[e]
			if par[0] >= 0 and par[1] >= 0:
				var a := int(Forja.percepcao(par[0]).get("gatilho_dir", 0))
				var b := int(Forja.percepcao(par[1]).get("gatilho_dir", 0))
				if a == 0x21 and b == 0x25:
					postos_ok[0] = true
		vidas.append([int(mg.vida[0]), int(mg.vida[1])])
	var mg = await _joga_o_minigame("S05_J25", 135.0, olhar)
	if mg == null:
		return
	if mg.presentes().size() >= 3:
		_esperar(postos_ok[0], "Catapulta: a corda num dedo e a trava no outro")
	var subiu := false
	for i in range(1, vidas.size()):
		for d in 2:
			if vidas[i][d] > vidas[i - 1][d] and vidas[i - 1][d] > 0:
				subiu = true
	_esperar(not subiu, "Catapulta: o castelo nunca ganha vida")
	var linhas := _linha_do_tempo()
	var gat := linhas.filter(func(x): return x.get("tipo") == "saida" and x.get("o") == "gatilho" and x.get("lado") == "R2")
	var travas := gat.filter(func(x): return x.get("modo") == "arma")
	_esperar(not travas.is_empty() and travas.all(func(x): return x.get("params", []) == [2, 6, 7]),
		"Catapulta: a trava é (2, 6, 7)")
	var lances := linhas.filter(func(x): return x.get("slot") == "S05_J25" and x.get("o") == "lancamento")
	_esperar(not lances.is_empty(), "Catapulta: houve lançamento (%d)" % lances.size())
	var proprias := linhas.filter(func(x): return x.get("slot") == "S05_J25" and x.get("nome") == "pedra_propria"
		and (x.get("tipo") == "momento" or x.get("o") == "momento"))
	for o in proprias:
		_esperar(float(o.get("t_musica", -1.0)) >= 0.0, "Catapulta: a pedra própria tem o tempo de música")
	var e := mg.equipe_vencedora()
	var v: Array = mg.vencedor()
	_esperar(e < 0 or v.is_empty() or mg.da_equipe(e).is_empty() or v[0] in mg.da_equipe(e),
		"Catapulta: a dupla na frente vem primeiro (%s)" % [v])
	var reta := linhas.filter(func(x): return x.get("slot") == "S05_J25" and x.get("nome") == "reta")
	_esperar(reta.size() <= 1, "Catapulta: no máximo uma linha momento reta (o castelo pode cair antes)")
```

**Na prova visual** (`bash tests/prova_visual.sh`, F09), a Catapulta entra pela semente que o `Catalogo.sortear`
da H08 põe na noite (`--semente=N`). O jogador do time olha a prancha:
- o último quadro, com os buracos e as bandeiras espetadas que a partida deixou;
- um quadro do pico em diante, com as muralhas caídas;
- os discos e as bandeiras na cor das duplas, e a barra de luz de cada um na cor do lugar.

**O que o André joga e sente** (`./run-local.sh -- --sala=S05_J25`):
- a corda pesa mais a cada meia batida, e a força final diz se a puxada foi boa;
- a trava tem a parede e o clique, no contratempo; a do pico é difícil e boa;
- a carga chega no dedo do travador quando o outro solta;
- o respiro da troca limpa a mão antes do posto novo.
