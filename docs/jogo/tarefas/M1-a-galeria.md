# M1 — A Galeria

**Sprint:** M · **Slot:** S05_J21 · **Tamanho:** G · **Depende de:** H04, H08, F09, F01, F04, F05, F06, H06, H07, G03, G08, G12

## Por quê

O estande no tempo da faixa: o alvo sobe na sua batida, você mira e atira, o tiro só sai quando o dedo passa do
clique da Weapon, e nas últimas 16 batidas um alvo de ouro no meio do muro põe os quatro atirando no mesmo instante.

A Galeria de hoje (`godot/scripts/salas/galeria.gd`, 751 linhas) é uma prova às cegas: a arma chega no baú
fechado, a pessoa diz qual é e conta as luzinhas. A identificação e a contagem continuam, **só no Modo bancada**,
porque medem os quatro vereditos da sala. Esta ficha também cria o cenário comum que as M2 a M5 usam.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (o kit, a ficha de dados, o catálogo, a régua)
- [O Modo bancada, no 13](../13-arquitetura.md#o-modo-bancada--f01) (o que a Galeria faz com e sem a bancada)
- [A Galeria de hoje](../../../godot/scripts/salas/galeria.gd) (inteira: a bancada continua dela)

Tudo o que esta ficha tira da bíblia de arte, do mapa do áudio, da régua da diversão e do RPG está escrito
aqui, com o número. Não é preciso abrir esses documentos.

## Arquivos que mudam

- `godot/scripts/minigames/s05/a_galeria.gd` (novo, com o `.uid` que o Godot gera)
- `godot/scripts/minigames/s05/cenario_da_galeria.gd` (novo, `class_name CenarioDaGaleria`, com o `.uid`).
  **De todos:** esta ficha cria e escreve; as M2 a M5 só usam.
- `godot/scripts/salas/galeria.gd` e `godot/scripts/salas/galeria.gd.uid` (saem, com `git rm`)
- `godot/scripts/minigames/catalogo.gd`: o slot `S05_J21`, a seção `S05` e o apelido `galeria` fora de
  `SALAS_ANTIGAS`. **De todos:** as M2 a M5 também mudam este arquivo
- `godot/scripts/traducoes.gd`: as frases novas. **De todos:** as M2 a M5 também mudam este arquivo
- `godot/testes/prova_do_jogo.gd`: a prova da Galeria, o teste às cegas sob a bancada e as 5 citações de
  `SalaGaleria` e de `"galeria"` trocadas (veja Provas). **De todos:** as M2 a M5 também mudam este arquivo
- `godot/testes/captura_jogo.gd`: os 4 momentos `"galeria"` (linhas 141 a 147) passam a ser por tempo. **De
  todos:** a J1, a J3 e a G01 também mudam este arquivo

## Como se joga

**O dono da batida.** As notas comuns são de um lugar por batida: `presentes()` em ordem, `lista[b % k]`. Com um
jogador, todas as batidas são dele. O compasso 0 é a contagem. O compasso `c` (batidas `4c` a `4c + 3`) é gerado
quando `Ritmo.batida() >= 4c − 4`.

**A curva** (os terços pelo tempo de música da nota, `CenarioDaGaleria.andamento_em(self, t)`):

| parte | segundos (de 90) | chance de alvo na batida do dono | o segundo alvo em `b + 0,5` |
| --- | --- | --- | --- |
| entrada | 0 a 30 | 0,75 | não |
| **pico** | 30 a 60 | 1,0 | chance 0,5, em outra coluna (densidade ×2 da entrada) |
| saída | 60 a 90 | 0,75 | não |
| **a reta** | as últimas 16 batidas (82,6 a 90 s a 130 bpm) | 0,75, e o alvo vale 2 | não |

- A entrada fica em 0,75, e não em 0,6, porque com 0,6 o pico daria densidade ×2,5, acima do teto ×2 da régua.
- Na saída (de 60 s até a reta), 10 % dos alvos são **dourados**: os discos em mostarda `#c79a2a`, o aro na cor
  do dono. Valem `PONTOS[j] × 2` e 2 alvos (`_info[l][n].dourado = true`).
- Se a vez anterior do dono não teve nota, esta tem (chance 1). Assim, com 4 jogadores, ninguém passa de 8
  batidas sem nota.
- Quem está com `Ritmo.simples[l]` nunca recebe o segundo alvo do pico.
- O sorteio usa o `rng` do kit (a semente da partida).

**A nota** do dono na batida `b`, pela fila do kit: `nova_nota(l, n, Ritmo.t_da_batida(b))`, com
`n = int(round(b * 2))`. Os dados dela ficam em `_info[l][n] = {"b": b, "tipo": "alvo", "coluna": 0 | 1 | 2}`.

**O alvo sobe** num tween de escala de 0 a 1, de `t_da_batida(b − A) − pista` até `t_da_batida(b − A / 2) − pista`.
O alvo fica no alto até `b + 0,25` e cai de 1 a 0 até `b + 0,5`. Aqui `A = CenarioDaGaleria.aviso_b()`, que dá
1 batida a 130 e a 104 bpm. `pista = CenarioDaGaleria.pista_s(l)` vem do Faro e da Lanterna (O cavaleiro).

**A mira.** O analógico esquerdo escolhe a coluna: `LX < −0,5` é a esquerda, `LX > 0,5` a direita, senão o
meio. O anel da mira fica no muro, na coluna escolhida, na altura `Y_ALVO`.

**O tiro.** É o R2 subindo até `CenarioDaGaleria.R2_CLIQUE` (0,62, o clique da Weapon). Ele rearma abaixo de
`R2_SOLTA` (0,2). Cada tiro gasta uma bala; com o tambor vazio, o R2 não dispara. O tiro casa com
`casar_toque(l)` (o alcance do kit é 0,5 s):

- **coluna certa:** `julgar_nota(l, n)`. O kit chama `toque` (o alvo estoura) ou `falha` (fora do tempo, ERRO).
- **coluna errada:** `nota_perdida(l, n)`. O tiro espirra no muro (a falha).
- **sem nota perto:** é o tiro à toa. Sai uma faísca no muro, sem ponto e sem erro.
- **na reta, a nota `ouro`** (abaixo) não tem coluna: todo tiro casado vale.

Todo tiro grava `anotar("entrada", l, {"o": "disparo", "n": n, "modo": "arma", "curso": r2, "curso_max": <o maior R2 até soltar>})`.
O `curso_max` se escreve ao soltar: guarde o evento em `_disparo[l]` até lá.

**A munição.** `balas[l]` começa em `BALAS` (6). A força da Weapon acompanha o tambor:
`Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, c)`, com `c` 8 se restam 3 ou mais, 6 se restam 2 e 4 se resta 1.
Mande de novo só quando `c` muda.

Com o tambor vazio, vai `Forja.gatilho(l, 1, Forja.GATILHO_OFF)`: o clique seco. No instante do aviso
(`b − A`), a próxima nota do dono vira **recarga** (`_info[l][n].tipo = "recarga"`). O alvo não sobe, e as seis
balas da mesa brilham na cor do lugar.

O □ casa com `casar_toque(l)`:
- BOM ou melhor enche o tambor (`balas = BALAS`, ou `BALAS − 1` para o líder da reta, abaixo), e a Weapon
  (2, 6, 8) volta;
- ERRO ou nota perdida deixa o tambor vazio, e a próxima nota dele é recarga de novo.

**Os pontos.** Use `const PONTOS := [0, 40, 70, 100]` (ERRO, BOM, ÓTIMO, PERFEITO), sempre por `marcar`, que
passa pelo item:

| nota | pontos | alvos |
| --- | --- | --- |
| alvo | `PONTOS[j]` | +1 |
| alvo dourado (saída) ou alvo na reta | `PONTOS[j] × 2` | +2 |
| recarga | `PONTOS[j] / 2` | 0 |
| ouro, quem acertou e não levou | `PONTOS[j]` | 0 |
| ouro, quem levou | mais `PONTOS[j] × 2` na resolução, sem o item (o Martelo não vale no ouro) | +3 |

**O pico.** No primeiro quadro com `no_pico()`:
- chame `CenarioDaGaleria.pico(self)`, uma vez;
- durante o pico, os alvos sobem girando: `rotation.z` de 0 a `TAU` entre `b − A` e `b`.

**A reta.** No primeiro quadro com `CenarioDaGaleria.na_reta(self)`:
- `CenarioDaGaleria.momento(self, "reta", -1)`;
- guarde `_lider_da_reta = vencedor()[0]`. Daí até o fim, toda recarga boa dele enche `BALAS − 1` (5): é a bala
  a menos do líder.

O carretel do HUD nas últimas 16 batidas é do kit.

### O ouro da reta

- **Quando.** Seja `r` a primeira batida inteira da reta. Os ouros caem nas batidas `r`, `r + 4`, `r + 8` e
  `r + 12`: quatro ouros, sempre.
- **Para quem.** Para todos os presentes, com `n = int(round(b * 2))` e `_info[l][n].tipo = "ouro"`. Nessas
  batidas não há nota comum.
- **O alvo.** Um alvo de ouro só, no meio do muro, em `OURO_POS`, escala `OURO_ESCALA`. Ele sobe como os outros,
  uma batida antes. Os rastros de todos convergem nele.
- **Quem leva.** Resolve em `t_da_batida(b + 0,5)`, uma colcheia depois. Concorrem os que tiveram BOM ou melhor
  (o `toque` guarda `{l, j, desvio_ms}`), e a ordem é esta:
  1. quem tem **menos ouros** até ali;
  2. o menor `|desvio_ms|`;
  3. o lugar menor.
- **Por que menos ouros primeiro.** Assim o mesmo atirador não leva os quatro, e quem está atrás tem a chance
  dele.
- **Quem levou recebe**, no mesmo quadro da resolução:
  - os pontos e alvos da tabela;
  - `Forja.sentir(l, "golpe")`;
  - `Forja.som_falante(l, "coleta", 1.0)`;
  - `CenarioDaGaleria.impacto(self, "golpe", OURO_POS, l, <o nó do ouro>)`;
  - três moedas no balcão dele, que ficam até o fim;
  - `CenarioDaGaleria.momento(self, "alvo_de_ouro", l)`.
- **Ninguém acertou:** o ouro cai sem moeda e sem momento.

### A ficha de dados

O cabeçalho do script `godot/scripts/minigames/s05/a_galeria.gd` é um comentário `#` com estas linhas:
- **o jogo:** na batida do dono, um alvo sobe numa das três colunas do muro dele, uma batida antes. Mire com o
  analógico esquerdo e atire com R2 na batida; a pistola (Weapon) só dispara quando o dedo passa do clique. São
  seis balas no tambor; vazio, o R2 fica solto e a próxima nota dele é a recarga (□ no tempo). Nas últimas 16
  batidas, quatro alvos de ouro para todos;
- **a falha:** o tiro fora do tempo ou na coluna errada espirra no muro, o coice joga o cavaleiro 0,5 m para trás
  e a fuligem fica 4 s no muro; a recarga fora do tempo emperra;
- **o vencedor:** mais alvos; no empate, mais pontos;
- **o alto-falante do dono:** o tiro à toa, a recarga, o clique seco e a coleta do ouro;
- **o registro:** cada `saida` de gatilho (Weapon com a força pelo tambor, e Off) e o curso do R2 no disparo;
- **o robô:** mira a coluna e atira na batida; quando não acerta, mira a coluna do lado;
- **com menos de quatro:** as batidas se dividem; sozinho, todas são dele;
- **a régua:** (1) «Atire!» com o alvo e a mira; (2) não se joga sem tela; (3) não pergunta nada fora da bancada.

```gdscript
extends Minigame

const FICHA := {
	"slot": "S05_J21",
	"titulo": "A Galeria",
	"verbo": "Atire!",
	"genero": "tct",
	"icone": "gatilho_adaptativo",
	"entradas": [Forja.QUADRADO],
	"camera": "fixa",
	"faixa": "MUS_S05_J21",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "toque", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Atire!", "segundos": 6.0},
	# o que a bancada mede (o veredito é do núcleo, como hoje)
	"features": ["gatilho_resistencia", "gatilho_arma", "gatilho_vibracao", "leds_jogador"],
	"botoes_medidos": [Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO, Forja.TRIANGULO],
	"gesto": "holding-right-shoot",
}
```

### As constantes

```gdscript
const PONTOS := [0, 40, 70, 100]  # ERRO, BOM, OTIMO, PERFEITO
const BALAS := 6
const COLUNAS := [0.2, 0.5, 0.8]  # o x da mira de cada coluna (0..1 no muro)
const Y_ALVO := 0.5
const LX_COLUNA := 0.5  # |LX| acima disto escolhe a coluna do lado
const CHANCE := [0.75, 1.0, 0.75]  # entrada, pico, saída
const CHANCE_DO_SEGUNDO := 0.5  # o segundo alvo do pico, em b + 0,5
const CHANCE_DOURADO := 0.1  # na saída, até a reta
const OURO_POS := Vector3(0, 2.2, CenarioDaGaleria.Z_ALVOS + 0.12)
const OURO_ESCALA := 1.6
const OURO_ALVOS := 3
const COICE_M := 0.5  # a falha: o cavaleiro vai 0,5 m para trás
const FULIGEM_S := 4.0
```

Da `galeria.gd` de hoje continuam **iguais**, para a bancada:
- as constantes `VEZES`, `MAX_EXTRAS`, `IDENTIFICA_MAX`, `REVELA`, `MUNICAO_MAX`, `NOME_ARMA`, `SENTE`,
  `BOTAO_OPCAO` e `GLIFO_OPCAO`;
- os `enum` de arma e de passo, com o passo novo `RITMO` no lugar de `ATIRAR`.

Saem:
- `F`, `RAIAS`, `Z_JOGADOR`, `Z_BAU` e `Z_ALVOS`, que vêm do kit e do cenário comum;
- `ATIRA`, `N_ALVOS`, `n_alvos`, `BALAS_MG` e `MIRA_*`.

### O Modo bancada (só com `Forja.bancada`)

A bancada acrescenta duas camadas; fora dela, nenhuma existe.

1. **A prateleira**, antes do primeiro alvo de cada um.
   - O baú fechado traz as quatro armas, duas vezes cada, na ordem de
     `Array(Forja.cega_plano_armas(VEZES, rng.randi()))`.
   - É o fluxo de hoje `IDENTIFICAR` → `REVELANDO`: `_responder_arma`, linhas 434 a 455, e `_proxima_rodada`,
     linhas 489 a 512, com o desempate.
   - Enquanto a prateleira do lugar não acaba, o gerador não dá nota a ele.
   - Quando acaba: a pistola na mão, a Weapon no R2 e o passo `RITMO`.
   - A F01 grava o evento `pergunta` (`qual` = `"arma"`) em cada rodada.
2. **A contagem**, depois de cada recarga boa.
   - É o `_perguntar_municao(l)` de hoje, linhas 456 a 488: as luzinhas com 1 a 5 acesas, e os botões X, círculo, quadrado e triângulo.
   - Usa o `MUNICAO` e o `MUNICAO_RESP` de hoje.
   - Enquanto a pergunta está aberta, o lugar não recebe nota.
   - Quando fecha: `Forja.leds_do_lugar(l)` (o número de volta) e o passo `RITMO`.
   - A F01 grava o evento `pergunta` (`qual` = `"leds"`).

Os quatro vereditos (`dar_vereditos`, linhas 513 a 525) continuam iguais e saem nos dois modos. Fora da bancada,
sem resposta, saem «não medido», como a F01 manda. Os passos `IDENTIFICAR` e `MUNICAO` do `_robo` de hoje
(linhas 679 a 735) viram `_robo_da_bancada`, com `_arma_sentida` e `_luzes_acesas` copiadas iguais.

### A falha

Toda falha muda a silhueta e deixa rastro (a régua: 0,5 m ou mais por pelo menos 1 batida, e rastro de 2 s ou
mais).

- **O coice** (`CenarioDaGaleria.coice(jogador(l), COICE_M)`). O cavaleiro vai 0,5 m para trás (+z, longe do
  muro):
  - sai em 1 colcheia (`TRANS_QUAD`, `EASE_OUT`);
  - fica 1 batida;
  - volta em 1 batida (`TRANS_SPRING`).
  - Peso não muda o coice: a coluna Peso desta ficha é «—».
- **O tiro que espirra** (fora do tempo, coluna errada ou nota perdida):
  - o rastro vai à coluna mirada, na cor do dono;
  - fica no muro uma mancha de fuligem: um disco OXIDO `#3b2a22`, Ø 0,3 m, fosco, por `FULIGEM_S` (4 s);
    depois some em 0,5 s;
  - o alvo de verdade cai para trás sem estourar (tween de `rotation.x` até −1,4 em 1/2 batida);
  - 1 batida depois do coice, `gesto("emote-no", 0.3)`.
- **A recarga que emperra:**
  - as seis balas giram uma volta em `y` em 1/2 batida e continuam apagadas;
  - uma bala cai no chão aos pés do cavaleiro e fica 4 s;
  - o mesmo coice.
- **O primeiro tambor vazio de cada lugar.** Não é falha, é o aviso: as seis balas giram uma volta em 1 batida e
  ficam com o albedo ×0,4 por 2 batidas.
- **A queda.** Depois da falha, o tiro fica travado por `1 batida × CenarioDaGaleria.gancho(l, "levantar")`,
  arredondado à semicolcheia e com no mínimo uma (`CenarioDaGaleria.queda_s(l, 1.0)`).
- **A volta.** A próxima nota do lugar é a próxima vez dele; a recarga repete até dar certo.

### O fim e o vencedor

São 90 s de música, pelo kit (H08).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(alvos[a]) != int(alvos[b]):
			return int(alvos[a]) > int(alvos[b])
		return int(pontos[a]) > int(pontos[b]))
	return lista
```

### Com menos de quatro

- **Com três ou dois,** a roda do dono vale como está.
- **Com um,** todas as batidas são dele. O ouro também, sem disputa: ele leva se acertar.
- **O controle que cai:** as notas dele saem caladas (`notas_perdidas` do kit), e o tambor fica como estava. Na
  bancada, a prateleira ou a pergunta abertas esperam por ele, como hoje.

### O robô

```gdscript
# O robô vê a nota da vez (a fila do kit e o _info), mira a coluna com o
# analógico e atira na batida, pelo relógio da música. Quando não acerta
# (Forja.robo_acerta() falso), mira a coluna do lado: a nota vira ERRO e a
# falha aparece; no ouro, que não tem coluna, ele não atira e a nota sai
# como perdida. Sente o gatilho solto (Off, 0x05) e recarrega na nota de
# recarga. Na bancada, identifica a arma pelo que chegou ao dedo e conta as
# luzinhas, como hoje.
var _robo_nota := [-1, -1, -1, -1]
var _robo_erra := [false, false, false, false]


func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	if Forja.bancada and int(j[l].passo) != RITMO:
		_robo_da_bancada(l, j[l], dt)
		return
	var r2 := 0.0
	var abertas := notas_em_aberto(l)
	if not abertas.is_empty():
		var nn: int = abertas[0]
		var info: Dictionary = _info[l][nn]
		if nn != _robo_nota[l]:
			_robo_nota[l] = nn
			_robo_erra[l] = not Forja.robo_acerta()
		var vazio := int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x05
		var t_alvo := alvo_da(l, nn)
		if Ritmo.t_musica() >= t_alvo - 60.0 / Ritmo.bpm:
			if info.tipo == "alvo" and not vazio:
				var col := int(info.coluna)
				if _robo_erra[l]:
					col = (col + 1) % 3
				Forja.robo_eixo(l, Forja.LX, float(col - 1), 0.06)
				if Ritmo.t_musica() >= t_alvo:
					r2 = 1.0
			elif info.tipo == "ouro" and not vazio and not _robo_erra[l]:
				if Ritmo.t_musica() >= t_alvo:
					r2 = 1.0
			elif info.tipo == "recarga" and vazio and Ritmo.t_musica() >= t_alvo:
				Forja.robo_apertar(l, Forja.QUADRADO, 0.06)
	Forja.robo_eixo(l, Forja.R2, r2, 0.06)
```

O R2 fica apertado até o tiro sair. A nota julgada sai da fila, e na próxima o R2 volta a 0 e rearma.

### Os ganchos

O que muda do `galeria.gd` de hoje:

| hoje | na Galeria nova |
| --- | --- |
| `class_name SalaGaleria`, `extends SalaJogo` | `extends Minigame`, sem `class_name` |
| `_init()` | sai (a FICHA; a câmera vai para o `montar`) |
| `montar()`, `_montar_raia()` (90 a 141), `_alvo_no()` (142), `_arma()` (153), `_no_muro()` (409), `_rastro()` (414), `_arma_na_mao()` (561) | o `montar` de baixo, com o cenário comum |
| `_novo_jogador()` (78) | fica (é da bancada), com `"passo": RITMO` fora dela |
| `_gatilho(l, arma)` (185) | fica: a bancada usa as quatro armas; o jogo, a pistola e o Off |
| `_leds` (200), `_luzes_da_mg` (206) | `_leds` fica só para a pergunta da bancada; `_luzes_da_mg` sai |
| `jogar()` (244) e `_jogar()` (259) com `ATIRAR` | o `jogar` de baixo; `IDENTIFICAR`, `REVELANDO`, `MUNICAO` e `MUNICAO_RESP` só na bancada (`_jogar_a_bancada`) |
| `_nova_rodada` (220), `_atirar` (369) | `_gerar_compasso(c)`, `_atirar(l, r2)` |
| `_responder_arma`, `_perguntar_municao`, `_proxima_rodada`, `_fechar_bau`, `_abrir_bau`, `_guardar_arma`, `pergunta()`, `dar_vereditos()` | ficam iguais (a bancada); no fim da prateleira, `_proxima_rodada` vai para `RITMO` em vez de `PRONTO` |
| `_mostrar` (586) | `_mostrar(l)` no fim do `jogar`: os alvos pela batida, a mira e o tambor |
| `status()` (614) | `"%d alvos" % alvos[l]` quando `na_raia(l)` |
| `dica()` (621) | `{"partes": ["@stick_l", "Mira", "@r2", "Atira"]}`; vazio: `["@square", "Recarrega"]`; só com `na_raia(l)` e `not aprendeu(l)` |
| `_robo` (679) | o `robo(l, dt)` de cima |

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

O esqueleto:

```gdscript
var _info := [{}, {}, {}, {}]  # lugar -> n -> {b, tipo, coluna}
var _vez_vazia := [false, false, false, false]  # a vez anterior do dono não teve nota
var _nota_em_curso := [-1, -1, -1, -1]  # o n que o toque ou a falha estão julgando
var _gerado := 1
var _armado := [true, true, true, true]
var _travado_ate := [0.0, 0.0, 0.0, 0.0]  # a queda da falha, em t_musica
var _forca := [8, 8, 8, 8]  # o c da Weapon mandado por último (0: Off)
var balas := [BALAS, BALAS, BALAS, BALAS]
var alvos := [0, 0, 0, 0]
var ouros := [0, 0, 0, 0]
var _ouro_concorre := []  # [{l, j, desvio}] do ouro em curso
var _ouro_resolve := -1.0  # t_musica da resolução do ouro em curso
var _lider_da_reta := -1
var _pico_feito := false
var _reta_feita := false
var _disparo := [{}, {}, {}, {}]  # o evento do tiro, até soltar (o curso_max)
var j := {}  # lugar -> o estado da bancada (o _novo_jogador de hoje)
var n := {}  # lugar -> os nós da raia (alvos, mira, balas, balcão, arma_mao)


func montar() -> void:
	camera_pos = Vector3(0, 7.5, 11.0)
	camera_olhar = Vector3(0, 0.2, -2.2)
	CenarioDaGaleria.montar(self)
	for p in jogadores:
		var l: int = p.lugar
		j[l] = _novo_jogador()
		raia(l)
		posicionar(l)
		p.rotation.y = PI
		p.preso = true
		n[l] = _montar_raia(l)  # faixa, balcão, baú, tambor, três alvos, mira (A cena)
		if not Forja.bancada:
			j[l].passo = RITMO
			n[l].arma_mao = CenarioDaGaleria.arma_na_mao(p, CenarioDaGaleria.PISTOLA)
			Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)


func sair() -> void:
	for p in jogadores:
		CenarioDaGaleria.guardar_arma(p)
	CenarioDaGaleria.sair(self)
	super()


func jogar(dt: float) -> void:
	while _gerado <= int(floor(Ritmo.batida() / 4.0)) + 1:
		_gerar_compasso(_gerado)  # só para quem está no passo RITMO
		_gerado += 1
	if not _pico_feito and no_pico():
		_pico_feito = true
		CenarioDaGaleria.pico(self)
	if not _reta_feita and CenarioDaGaleria.na_reta(self):
		_reta_feita = true
		_lider_da_reta = int(vencedor()[0])
		CenarioDaGaleria.momento(self, "reta", -1)
	if _ouro_resolve >= 0.0 and Ritmo.t_musica() >= _ouro_resolve:
		_resolver_o_ouro()
	for l in presentes():
		if int(j[l].passo) != RITMO:
			_jogar_a_bancada(l, jogador(l), j[l], dt)
			continue
		notas_perdidas(l)
		if not conectado(l):
			continue
		var r2 := Forja.eixo(l, Forja.R2)
		var livre := Ritmo.t_musica() >= float(_travado_ate[l])
		if _armado[l] and r2 >= CenarioDaGaleria.R2_CLIQUE and balas[l] > 0 and livre:
			_armado[l] = false
			_atirar(l, r2)
		elif r2 <= CenarioDaGaleria.R2_SOLTA:
			if not _armado[l]:
				_soltou(l)  # grava o disparo com o curso_max
			_armado[l] = true
		if not _armado[l]:
			_disparo[l]["curso_max"] = maxf(float(_disparo[l].get("curso_max", 0.0)), r2)
		if Forja.apertou(l, Forja.QUADRADO):
			_recarregar(l)  # casar_toque com a nota recarga
		_mostrar(l)


func toque(l: int, julgamento: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	var reta := CenarioDaGaleria.na_reta(self)
	match str(info.get("tipo", "")):
		"recarga":
			marcar(l, PONTOS[julgamento] / 2)
			balas[l] = BALAS - 1 if l == _lider_da_reta else BALAS
			_mandar_a_arma(l)
			Som.no_controle(l, "recarga", 0.6)
			Som.tocar("recarga", _pos_do_tambor(l))
			if Forja.bancada:
				_perguntar_municao(l)
		"ouro":
			marcar(l, PONTOS[julgamento])
			_ouro_concorre.append({"l": l, "j": julgamento,
				"desvio": absf(Ritmo.desvio_ms(l, Ritmo.t_musica(), Ritmo.t_da_batida(float(info.b))))})
		_:
			var vale := 2 if reta or bool(info.get("dourado", false)) else 1
			marcar(l, PONTOS[julgamento] * vale)
			alvos[l] += vale
			_estourar_o_alvo(l, info)  # o aro a 2,6 por 4 quadros, as faíscas, "alvo" na TV


func nota_perdida(l: int, nn: int) -> void:
	_nota_em_curso[l] = nn
	super(l, nn)


func falha(l: int) -> void:
	var info: Dictionary = _info[l].get(_nota_em_curso[l], {})
	if str(info.get("tipo", "")) == "recarga":
		_emperrar(l)
	else:
		_espirrar(l, info)
	CenarioDaGaleria.coice(jogador(l), COICE_M)
	_travado_ate[l] = Ritmo.t_musica() + CenarioDaGaleria.queda_s(l, 1.0)
```

- `_atirar(l, r2)` e `_recarregar(l)` guardam em `_nota_em_curso[l]` o `n` que casaram, antes do `julgar_nota`.
- `_mandar_a_arma(l)` faz a Weapon (2, 6, c) pelo tambor, ou o Off se está vazio, e só manda quando `_forca[l]`
  muda.
- `_atirar(l, r2)`:
  - gasta a bala e chama `_mandar_a_arma`;
  - mostra o rastro na cor do dono e toca o tiro (O som);
  - casa a nota e decide pelas regras do tiro acima;
  - abre `_disparo[l]`.
- `_resolver_o_ouro()` ordena `_ouro_concorre` pelas regras de «O ouro da reta», dá o prêmio, esvazia a lista e
  põe `_ouro_resolve = -1`.
- O gerador marca `_ouro_resolve = t_da_batida(b + 0.5)` quando a batida `b` do ouro chega.

### O catálogo e as traduções

- No `catalogo.gd`:
  - `Catalogo.MINIGAMES["S05_J21"] = preload("res://scripts/minigames/s05/a_galeria.gd")`;
  - `"minigames": ["S05_J21"]` na seção `S05`;
  - o apelido `"galeria"` sai de `SALAS_ANTIGAS`.
- O apelido continua abrindo pelo `Catalogo.resolver`. Ninguém troca isto: `musica.gd`, `salao.gd`, `partida.gd`,
  `prova_de_poucos.gd` e `prova_de_poucos.sh`, e o preload de `main.gd:16`, que a H04 tira.
- `git rm godot/scripts/salas/galeria.gd godot/scripts/salas/galeria.gd.uid`.
- Os `.uid` novos: `a_galeria.gd.uid` e `cenario_da_galeria.gd.uid`, gerados com
  `"$GODOT" --headless --path godot --import --quit`.
- As traduções que ainda não existirem: `"Atire!": "Shoot!"`, `"Mira": "Aim"`, `"Atira": "Shoot"`,
  `"Recarrega": "Reload"`, `"%d alvos": "%d targets"`.

### O registro

- **A `saida` de gatilho**, gravada pelo `Forja` (F06): `o` `"gatilho"`, `lado` `"R2"`, `modo` `"arma"` com
  `params` `[2, 6, c]` (c em 8, 6 ou 4), e `"off"`, com `seq`, `ok` e `byte_modo`.
- **`entrada` `disparo`** (`n`, `modo` `"arma"`, `curso`, `curso_max`) em todo tiro, e o `toque` do kit. O curso
  no disparo mostra o clique no ponto certo.
- **A linha `momento`** por `CenarioDaGaleria.momento`: `reta` (lugar −1) e `alvo_de_ouro` (o lugar de quem
  levou).
- **Na bancada:** a `pergunta` (`"arma"`, `"leds"`), as respostas de hoje (`resposta_arma`, `resposta_municao`) e
  os quatro vereditos.

### Armadilhas

- **As luzinhas são do número do jogador.** Fora da bancada, nenhum `Forja.leds_jogador`. Na bancada, depois da
  pergunta, `Forja.leds_do_lugar(l)`.
- **O tiro só sai com bala.** Com o tambor vazio, o R2 está em Off e o curso não dispara. Sem isso, quem não
  sente peso no dedo atiraria de graça.
- **No pico, a meia batida** (0,23 s a 130 bpm) dá para soltar abaixo de 0,2 e apertar de novo. O robô solta o
  R2 quando a nota sai da fila.
- **A bancada não muda a regra do jogo.** Ela só acrescenta a prateleira antes e a contagem depois da recarga.
- **A barra de luz é do kit:** o piscar do perfeito e o escurecer do erro (`_reagir`, H08). O minigame não mexe
  nela.
- **Não declare `_notas`.** A fila é do kit (H08). O que é da Galeria fica em `_info`.

## A cena

### A câmera

Plano fixo, `"camera": "fixa"`, sem corte do apito ao apito:
- posição `Vector3(0, 7.5, 11.0)`, olhando para `Vector3(0, 0.2, -2.2)`. A plongée é de 29°;
- lente de 35 mm (FOV vertical 37,8°), a da arena no cinema.

O cinema pede plongée de 50° para a arena. A Galeria fica com 29°, porque o muro dos alvos tem 2,7 m de altura em
z = −6,4 e, a 50°, sai do quadro por cima. O tremor vem de `CenarioDaGaleria.impacto`.

### A luz (S5, a tinta ameixa `#86409a`)

Até a G15 trazer `Tema.luz_da_secao`, o cenário comum guarda as três luzes como constantes nomeadas (os valores
são do cinema):

| luz | constante | hex | onde |
| --- | --- | --- | --- |
| névoa | `NEVOA` | `#18081c` | `fog_light_color` do `Environment` do mundo, guardada e devolvida no `sair` |
| preenchimento | `PREENCHIMENTO` | `#4a2854` | `sala.atmosfera(PREENCHIMENTO, VIOLETA, false, 50)`, energia 0,35 |
| chave | `CHAVE` | `#f8ccba` | um `DirectionalLight3D`, energia 1,0, `rotation_degrees = Vector3(-50, -20, 0)` |

- **O néon do mundo** é o VIOLETA `#4a3aa8` (as duas barras da `atmosfera`). A `atmosfera` de hoje põe energia
  3,0, acima do teto de 1,2: o corte é da G15, e esta ficha não mexe em `sala_jogo.gd`.
- **O pico** (`CenarioDaGaleria.pico`):
  - a chave vai a ×1,2 em 1 batida e a densidade da névoa a ×0,8;
  - as duas voltam em 2 batidas.
  - Isso substitui o «muro pisca ciano» de hoje.
- **A catástrofe** (só na M3) põe a chave a ×1,4 por 1 batida.
- **Saem** as tochas `#ffb070` e a luz `#b9b0ff` de `sala.luzes`, e as cores `AR` `#c28bff`, `Tema.CIANO`,
  `Tema.ROSA`, `Tema.ROXO` e `Tema.LARANJA`.

### As peças

| peça | de onde | o papel | escala pedida |
| --- | --- | --- | --- |
| o chão e as paredes | Mini Dungeon, `Kit.arena(sala, 5, 3)` | o estande, de x −12 a 12 e z −8 a 8 | `Kit.K` |
| o alvo | `CenarioDaGaleria.alvo(pai, false, l)`, sempre: o `blaster-kit/target-large` mede 0,34 m (0,10 m a ×0,3) e não tem o aro do dono | os três alvos de cada muro, Ø 0,92 m | 1,0 |
| o alvo de ouro | o substituto `CenarioDaGaleria.alvo(pai, true)`, sempre | o ouro da reta | `OURO_ESCALA` 1,6 |
| o alvo dourado | o substituto `CenarioDaGaleria.alvo(pai, false, l)` com os discos trocados para mostarda | 10 % dos alvos da saída | 1,0 |
| a pistola | `blaster-kit/blaster-a`, por `peca_ou`; o substituto é `CenarioDaGaleria.arma(pai, PISTOLA)` | na mão direita | 1,0 (×0,3) |
| o suporte das armas | `mini-arena/weapon-rack`, por `peca_ou`; sem o pacote, nada | um atrás de cada cavaleiro, em z = `Z_JOGADOR` + 0,9 | 2,0 (`Kit.K`: a série Mini é 1× do pacote) |
| o balcão | `Kit.caixa`, 1,3 × 0,5 × 0,9 m, GRAFITE `#3a3346` | à frente do cavaleiro, em z = `Z_JOGADOR` − 1,35 | — |
| o baú | Mini Dungeon `chest` | sobre o balcão; só abre na bancada | 1,9 |
| as balas | `Kit.caixa` 0,1 × 0,18 × 0,1 m, ETIQUETA_SOMBRA `#cfc2a0` | seis, em x = `RAIAS[l]` − 0,33 + 0,13·k, y 0,6, z = `Z_JOGADOR` − 1,1; a gasta some | — |
| as moedas | Mini Dungeon `coin` | três no balcão de quem leva o ouro, até o fim | 1,0 |

- **As cores das armas e dos alvos** em blocos:
  - o ferro é GRAFITE `#3a3346`; o "claro" é ETIQUETA_SOMBRA `#cfc2a0`; a madeira é OXIDO_BRILHO `#7a5640`;
  - o alvo tem os discos ETIQUETA `#efe4c8`, vermelhão `#c8432f` e ETIQUETA, todos foscos (brilho 0);
  - o alvo de ouro tem os discos em mostarda `#c79a2a`, fosco.
- **Os tokens.** Os nomes em maiúsculas são os da bíblia (a G14 os traz ao `Tema`). Até lá, viram constantes
  nomeadas no `cenario_da_galeria.gd`, com o hex acima.

### O que brilha, e de quem é o brilho

| o quê | cor | emissivo | dono |
| --- | --- | --- | --- |
| a borda da raia | a cor do lugar | a do kit | o jogador |
| o aro do alvo (um toro de 0,42 a 0,46 m em volta dos discos) | a cor do lugar | 2,0; no acerto, 2,6 por 4 quadros, e estoura | o jogador |
| o aro do ouro | TUNGSTENIO `#ffd9a8` | 2,4 | a forja |
| as balas, uma batida antes da recarga | a cor do lugar | 1,5 | o jogador |
| o rastro do tiro | a cor do lugar, alfa 0,9 | chapado, some em 0,12 s | o jogador |
| as faíscas do acerto e do espirro | TUNGSTENIO `#ffd9a8` | chapadas (`Efeitos.faiscas`) | a forja |
| o néon do mundo | VIOLETA `#4a3aa8` | 3,0 hoje, 1,2 com a G15 | o mundo |

Nada mais brilha. As tintas, a fuligem, o balcão e as moedas são foscos.

### O impacto

`CenarioDaGaleria.impacto(sala, degrau, pos, l, objeto)` aplica a tabela da régua:

| degrau | imagem | tremor (`sala.tremor`, que decai a 0 em tween) | parada (hit-stop) |
| --- | --- | --- | --- |
| `toque` | 10 faíscas TUNGSTENIO | nenhum | nenhuma |
| `golpe` | o `objeto` vai a 130 % e volta em 1/2 batida; 24 faíscas | 0,167 (0,02 m) por 1 batida | 33 ms no `AnimationPlayer` do cavaleiro `l` |
| `estrondo` | 50 faíscas | 0,417 (0,05 m) por 2 batidas | 50 ms no cavaleiro `l` |
| `catastrofe` | a chave a ×1,4 por 1 batida; 60 faíscas | 0,667 (0,08 m) por 4 batidas | nenhuma |

O tremor da câmera é 0,12 m × `sala.tremor` (`main.gd:988`); por isso, tremor = amplitude ÷ 0,12. Quando a G05
trouxer `tremer(forca)`, o `impacto` passa a chamá-la, e as fichas não mudam.

### O cenário comum (`godot/scripts/minigames/s05/cenario_da_galeria.gd`)

O cabeçalho é um comentário `#`: «O cenário comum d'A Galeria (S5): o estande, a luz ameixa, a faixa de cada
raia, o alvo, as armas, o muro, o curso do R2, o momento, a reta, o aviso, os ganchos do cavaleiro e o impacto.
As cinco fichas M usam isto.»

```gdscript arquivo=godot/scripts/minigames/s05/cenario_da_galeria.gd
class_name CenarioDaGaleria
extends RefCounted

enum { PISTOLA, METRALHADORA, ARCO, NENHUMA }

# A luz da S5 (a ameixa) e as cores da bíblia, até a G14 e a G15.
const NEVOA := Color("#18081c")
const PREENCHIMENTO := Color("#4a2854")
const CHAVE := Color("#f8ccba")
const VIOLETA := Color("#4a3aa8")  # o néon do mundo
const TUNGSTENIO := Color("#ffd9a8")
const ETIQUETA := Color("#efe4c8")
const ETIQUETA_SOMBRA := Color("#cfc2a0")
const GRAFITE := Color("#3a3346")
const OXIDO := Color("#3b2a22")
const OXIDO_BRILHO := Color("#7a5640")
const VERMELHAO := Color("#c8432f")  # SECAO[0]
const MOSTARDA := Color("#c79a2a")  # SECAO[3]
const BRILHO_DO_ALVO := 2.0
const BRILHO_DO_ACERTO := 2.6
const BRILHO_DA_FORJA := 2.4
# O muro dos alvos.
const Z_ALVOS := -6.4
const MIRA_LARG := 2.8
const MIRA_Y0 := 0.8
const MIRA_Y1 := 2.7
# O curso do R2: o clique da Weapon, o apertar e o soltar.
const R2_CLIQUE := 0.62
const R2_APERTA := 0.5
const R2_SOLTA := 0.2
# A escala de cada pacote (G10), enquanto o Kit.peca não a aplica.
const FATOR := {"blaster-kit": 0.3, "castle-kit": 1.4, "pirate-kit": 0.4}


static func montar(sala: SalaJogo) -> void:
	Kit.arena(sala, 5, 3)
	sala.atmosfera(PREENCHIMENTO, VIOLETA, false, 50, 22.0, -7.8, 0.35)
	var chave := DirectionalLight3D.new()
	chave.light_color = CHAVE
	chave.light_energy = 1.0
	chave.rotation_degrees = Vector3(-50, -20, 0)
	sala.add_child(chave)
	sala.set_meta("chave", chave)
	var env := sala.get_world_3d().environment
	if env:
		sala.set_meta("nevoa_antiga", [env.fog_light_color, env.fog_density])
		env.fog_light_color = NEVOA


static func sair(sala: SalaJogo) -> void:
	var env := sala.get_world_3d().environment
	if env and sala.has_meta("nevoa_antiga"):
		env.fog_light_color = sala.get_meta("nevoa_antiga")[0]
		env.fog_density = sala.get_meta("nevoa_antiga")[1]


# A faixa no chão na cor do lugar, do boneco até o muro dos alvos.
static func faixa(sala: Node3D, l: int) -> void:
	var z0 := Minigame.Z_JOGADOR
	Kit.caixa(sala, Vector3(1.5, 0.02, z0 - Z_ALVOS + 0.6), Vector3(Minigame.RAIAS[l], 0.02, (z0 + Z_ALVOS) * 0.5),
		Kit.material(Forja.cor_do_lugar(l).darkened(0.6), 0.0, 0.8))


# Um alvo: três discos de 8 lados, foscos, de frente para o jogador, e o aro
# emissivo do dono (l) ou da forja (ouro).
static func alvo(pai: Node3D, ouro := false, l := -1) -> Node3D:
	var a := Node3D.new()
	pai.add_child(a)
	var cores := [MOSTARDA, MOSTARDA, MOSTARDA] if ouro else [ETIQUETA, VERMELHAO, ETIQUETA]
	for i in 3:
		var disco := Kit.cilindro(a, 0.42 - 0.13 * i, 0.04, Vector3(0, 0, 0.012 * i), Kit.material(cores[i], 0.0, 0.6))
		disco.rotation.x = PI * 0.5
	var aro := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.42
	tor.outer_radius = 0.46
	aro.mesh = tor
	aro.rotation.x = PI * 0.5
	var cor := TUNGSTENIO if ouro else Forja.cor_do_lugar(maxi(l, 0))
	aro.material_override = Kit.material(cor, BRILHO_DA_FORJA if ouro else BRILHO_DO_ALVO, 0.6)
	a.add_child(aro)
	a.set_meta("aro", aro)
	return a


# A peça do pacote, se ele já foi importado (G10); senão, o substituto.
# O substituto é um Callable(pai) -> Node3D.
static func peca_ou(pai: Node3D, nome: String, substituto: Callable, pos: Vector3, rot_y := 0.0, escala := 1.0) -> Node3D:
	var caminho := "res://assets/kenney/%s.glb" % nome
	var no: Node3D
	if ResourceLoader.exists(caminho):
		no = (load(caminho) as PackedScene).instantiate()
		pai.add_child(no)
		no.scale = Vector3.ONE * escala * float(FATOR.get(nome.get_slice("/", 0), 1.0))
	else:
		no = substituto.call(pai)
		if no == null:
			return null
		no.scale = Vector3.ONE * escala
	no.position = pos
	no.rotation.y = rot_y
	return no


# A linha momento da régua da diversão. Enquanto "momento" não está nos
# TIPOS_DO_JOGO do kit, vai como linha jogo com o: "momento".
static func momento(mg: Minigame, nome: String, l: int) -> void:
	var t := snappedf(Ritmo.t_musica(), 0.001)
	if "momento" in Minigame.TIPOS_DO_JOGO:
		mg.anotar("momento", l, {"nome": nome, "lugar": l, "t_musica": t})
	else:
		mg.anotar("jogo", l, {"o": "momento", "nome": nome, "lugar": l, "t_musica": t})


# O andamento (0..1) no tempo de música t, e a reta (as últimas 16 batidas).
static func andamento_em(mg: Minigame, t: float) -> float:
	var inicio := Ritmo.t_musica() - mg.tempo_jogado()
	return clampf((t - inicio) / mg.duracao, 0.0, 1.0) if mg.duracao > 0.0 else 0.0


static func na_reta_em(mg: Minigame, t: float) -> bool:
	var inicio := Ritmo.t_musica() - mg.tempo_jogado()
	return mg.duracao > 0.0 and t - inicio >= mg.duracao - 16.0 * 60.0 / Ritmo.bpm


static func na_reta(mg: Minigame) -> bool:
	return na_reta_em(mg, Ritmo.t_musica())


# O aviso visual, em batidas: no mínimo 1 batida e no mínimo 0,45 s.
static func aviso_b() -> float:
	return maxf(1.0, ceilf(0.45 * Ritmo.bpm / 60.0))


# O gancho do cavaleiro (o RPG). Sem a classe Cavaleiro, neutro.
static func gancho(l: int, nome: String) -> float:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == "Cavaleiro":
			return float(load(c["path"]).gancho(l, nome))
	return 0.0 if nome == "pista" else 1.0


# Quanto antes o aviso do lugar aparece, em s: o Faro e a Lanterna.
static func pista_s(l: int) -> float:
	return gancho(l, "pista") / 1000.0 + Itens.antecipacao_s(l, Ritmo.bpm)


# A queda depois da falha, em s: tempos × levantar, à semicolcheia, no mínimo uma.
static func queda_s(l: int, tempos: float) -> float:
	var semi := 15.0 / Ritmo.bpm
	return maxf(semi, roundf(tempos * gancho(l, "levantar") * 60.0 / Ritmo.bpm / semi) * semi)


# O pico: a chave a ×1,2 em 1 batida e a névoa a ×0,8; voltam em 2 batidas.
static func pico(sala: SalaJogo) -> void:
	var b := 60.0 / Ritmo.bpm
	var chave: DirectionalLight3D = sala.get_meta("chave", null)
	if chave:
		var tw := chave.create_tween()
		tw.tween_property(chave, "light_energy", 1.2, b)
		tw.tween_property(chave, "light_energy", 1.0, 2.0 * b)
	var env := sala.get_world_3d().environment
	if env:
		var d := env.fog_density
		var tw2 := sala.create_tween()
		tw2.tween_property(env, "fog_density", d * 0.8, b)
		tw2.tween_property(env, "fog_density", d, 2.0 * b)
```

E mais estes, com o corpo descrito aqui:

- **`static func impacto(sala: SalaJogo, degrau: String, pos: Vector3, l: int, objeto: Node3D = null)`**
  - aplica a tabela de «O impacto»: `Efeitos.faiscas(sala, pos, TUNGSTENIO, n)`;
  - põe `sala.tremor` no valor e o leva a 0 num tween da duração;
  - no golpe, faz a escala de `objeto` ir a 1,3 × a de agora e voltar em 1/2 batida;
  - na parada, faz `speed_scale = 0` no `AnimationPlayer` do cavaleiro `l`
    (`find_child("AnimationPlayer", true, false)`) e o devolve a 1 depois de 0,033 ou 0,050 s
    (`sala.get_tree().create_timer`);
  - na catástrofe, leva a chave a 1,4 por 1 batida.
- **Movidas de `galeria.gd` com o corpo de hoje**, mais as trocas de cor da tabela de «As peças»:
  - `static func arma(pai, qual) -> Node3D` (linhas 153 a 184);
  - `static func no_muro(l, m: Vector2) -> Vector3` (409 a 413, com `Minigame.RAIAS`).
- **`static func rastro(sala, de, ate, cor)`** (414 a 433). Recebe `de` e `ate` em vez do jogador, e a cor do dono
  no lugar de `Tema.AMARELO`. As faíscas da boca são TUNGSTENIO, 6, força 0,3.
- **`static func arma_na_mao(p: ForjaPlayer, qual: int) -> Node3D`** (561 a 579). Devolve o `BoneAttachment3D`
  em vez de guardá-lo. Antes de criar, põe `visible = false` em todo outro `BoneAttachment3D` do esqueleto com
  `bone_name` `"arm-right"` (o item da mão: Martelo, Âncora) e marca cada um com `set_meta("galeria_escondeu", true)`.
- **`static func coice(p: ForjaPlayer, metros := 0.5)`**: um tween em `p.position.z`, de `Minigame.Z_JOGADOR` a
  `Z_JOGADOR + metros` em 1 colcheia (`TRANS_QUAD`, `EASE_OUT`), parado 1 batida, e de volta em 1 batida
  (`TRANS_SPRING`). Um coice novo no meio do outro mata o tween velho (`p.get_meta("coice")`).
- **`static func guardar_arma(p: ForjaPlayer)`**
  - tira o `BoneAttachment3D` da arma;
  - devolve `visible = true` a quem tem o meta `galeria_escondeu`.

## O som

| evento | id do mapa | onde | como |
| --- | --- | --- | --- |
| a música | `mus_s05_j21` (130 bpm, Ré menor, 150 s; seca, sem cauda de reverberação) | TV | `"faixa": "MUS_S05_J21"`; sem a faixa (H05), a trilha sintetizada `"galeria"` a 104 bpm |
| todo tiro | `tiro_0` a `tiro_4` | TV | `Som.tocar("tiro", <a boca da arma>, -10.0)` |
| o tiro à toa | `tiro_*` | alto-falante do dono | `Som.no_controle(l, "tiro", 0.45)` |
| o tiro julgado | `jul_ressonancia_p{n}`, `jul_afinado_p{n}`, `jul_quase_p{n}`, `jul_erro_p{n}` | TV e alto-falante | o kit (`_reagir`); a ficha não toca nada |
| o alvo que estoura | `alvo_0` a `alvo_4` | TV | `Som.tocar("alvo", <pos do alvo>)` |
| o ouro levado | `alvo_*` e `mod_coleta` | TV e alto-falante do ganhador | `Som.tocar("alvo", OURO_POS, 0.0, 0.8)` e `Forja.som_falante(l, "coleta", 1.0)` |
| o R2 no tambor vazio | `vazio_0` e `mod_clique` | TV (−6 dB) e alto-falante | `Som.tocar("vazio", <pos do tambor>, -6.0)` e `Forja.som_falante(l, "clique", 0.7)` |
| a recarga boa | `recarga_0` | TV e alto-falante | `Som.tocar("recarga", <pos do tambor>)` e `Som.no_controle(l, "recarga", 0.6)` |
| a recarga que emperra | `vazio_0` | TV | `Som.tocar("vazio", <pos do tambor>, -6.0)` |
| a falha | `fx_tropeco_*` | TV | o kit (H11); a ficha não toca nada |
| os carimbos | `car_em_chamas`, `car_acorde`, `jin_virada` (o carimbo `car_virada`), `car_por_um_fio` | TV | o kit e o HUD |

- **O alto-falante toca um som por vez**, nesta prioridade: vitória e derrota, o julgamento, o segredo, o pio, a
  coleta e o clique.
- **No ouro,** a coleta sai uma colcheia depois do julgamento, quando ele já acabou.
- **O `tique` de hoje** no espirro sai: a falha tem o `fx_tropeco` do kit.

## O controle

| recurso | evento | quem joga | os outros |
| --- | --- | --- | --- |
| **gatilho R2 (protagonista)** | com bala no tambor | `GATILHO_ARMA` (2, 6, c): c = 8 com 3 ou mais balas, 6 com 2, 4 com 1 | nada |
| gatilho R2 | o tambor vazio, até a recarga boa | `GATILHO_OFF`: o clique seco | nada |
| gatilho R2 | a recarga boa | `GATILHO_ARMA` (2, 6, 8) de novo | nada |
| vibração | o tiro julgado | `acerto` (0,3/0,6, 80 ms), `perfeito` (0,5/0,8, 100 ms) ou `erro` (0,7/0,3, 160 ms), pelo kit | nada |
| vibração | o tiro à toa e o R2 no tambor vazio | `Forja.sentir(l, "toque")` (0/0,45, 60 ms) | nada |
| vibração | quem leva o ouro | `Forja.sentir(l, "golpe")` (1,0/0,6, 250 ms), no quadro do `momento` | nada |
| háptica | o acerto | a textura `"metal"`, pelo kit | nada |
| barra de luz | sempre | a cor do lugar, 100 % | a cor de cada um |
| barra de luz | o toque julgado | o kit pisca branco no perfeito e escurece no erro | nada |
| luzinhas | sempre | o número do lugar; só a pergunta da bancada mexe nelas | o número de cada um |
| alto-falante | O som | o tiro à toa, o clique seco, a recarga e a coleta do ouro | nada |
| microfone | — | Não se aplica: a Galeria não ouve | — |

O que espera uma medida, e o caminho sem ela:
- **A força do ouro.** A pesquisa propôs Weapon (4, 7, 8) no ouro. Fica fora até o limiar do R2 ser medido na
  bancada. Hoje o ouro usa a Weapon do tambor.
- **O 03 (som) diverge desta ficha.** O 03 dá Resistência 1,8 ao tambor vazio e Off à recarga. Esta ficha fica
  com Off no vazio, porque o clique seco é o sinal do tambor vazio, e com a Weapon de volta na recarga. A
  divergência vai para o diretor de som.

**A prova sem o controle na mão:**
- o robô sente o modo pelo primeiro byte (`Forja.percepcao(l)["gatilho_dir"]`: `0x25` Weapon, `0x05` Off);
- a força se confere pelos `params` da `saida` no registro.

## O cavaleiro

| stat | gancho | o que muda aqui |
| --- | --- | --- |
| Fôlego | `levantar` | a trava do tiro depois da falha: 1 batida × (1 − 0,125 × (Fôlego − 3)); Fôlego 1 dá 1,25 batida, e 5 dá 0,75. Arredonda à semicolcheia, no mínimo uma (`CenarioDaGaleria.queda_s(l, 1.0)`) |
| Faro | `pista` | o alvo começa a subir 20 ms × (Faro − 3) antes; Faro 5 dá +40 ms, e 1 dá −40 ms (`pista_s`) |
| Peso | — | não muda nada |
| Passo | — | não muda nada |

- **Os itens são do kit:**
  - os pontos do Martelo (`Itens.pontos_do_acerto`, pelo `marcar`, menos no prêmio do ouro);
  - o Escudo, que absorve o primeiro erro;
  - o Fole;
  - o Diapasão;
  - a Lanterna, que `pista_s` soma ao aviso (`Itens.antecipacao_s`).
- **A peça.** O cavaleiro fica de costas (`rotation.y = PI`).
  - O item da mão direita (Martelo, Âncora) some enquanto a pistola está na mão e volta no `sair()`.
  - O Escudo, no `arm-left`, e os amuletos do peito ficam à vista.
  - As cores da montagem não mudam nesta ficha.

## As reações

- **Nenhum adesivo.** Todos jogam todas as batidas, e ninguém fica fora da rodada para mandar um.
- **Os carimbos são do kit e do HUD**, e esta ficha não chama nenhum:
  - `car_em_chamas`: 5 Ressonância! seguidas;
  - `car_acorde`: os quatro acertam Ressonância! no mesmo tempo 1;
  - `car_virada`: no placar;
  - `car_por_um_fio`: venceu por 2 % ou menos.
- **O ouro é a chance do `car_acorde`.** É a única nota em que os quatro atiram no mesmo instante. Quando um ouro
  cai num tempo 1 e os quatro acertam Ressonância!, o kit carimba.

## A diversão

**O momento: `alvo_de_ouro`**
- **Quando:** a janela é de 80 a 90 s, na mesa padrão. Na reta, um alvo de ouro sobe no meio do muro, os quatro
  rastros convergem nele, e quem acerta com menos ouros (no empate, o mais no tempo) leva três alvos de uma vez.
- **O que se vê:** o ouro vai a 130 % (o golpe), a câmera treme uma batida e caem três moedas no balcão dele.
  - É no balcão que o grupo vê quem levou.
  - Como os ouros vão primeiro para quem tem menos, o líder raramente leva dois.
  - O líder ainda recarrega com uma bala a menos.

**Como o jogador do time confere:**
- **No registro,** pelo robô na mesa padrão, semente 7:
  - pelo menos **4 linhas `momento` `alvo_de_ouro`**, de **2 ou mais lugares** diferentes, com `t_musica` entre 80
    e 90 s;
  - para cada uma, uma linha `sensacao` `golpe` do mesmo lugar a até 16,7 ms;
  - o `t_musica` cai a até 1 quadro de uma colcheia (`b + 0,5`).
- **Na prancha (F09):**
  - no último quadro, há moedas em 2 ou mais balcões;
  - no quadro do ouro, o alvo de ouro fica com x_tela 0,5 e altura_tela de 0,10 (1,34 m a 19,5 m da câmera, com
    13,4 m de quadro na vertical; o mínimo é 0,08).
- **A falha à vista:** o P4 (`ruim`) tem pelo menos 10 linhas `toque` com `erro` em 90 s. Em pelo menos 1 quadro
  de cada 5 da prancha, há fuligem no muro do P4.
- **Ninguém para:** a maior distância entre duas notas seguidas do mesmo lugar é de até 8 batidas. O P4 tem pelo
  menos um toque BOM ou melhor em cada terço.

Até o robô por lugar (`--robo=bom,medio,medio,ruim`, pedido ao arquiteto na régua) existir, a prova roda com o
`--robo` da `prova_do_jogo.sh` num temperamento só e confere o momento, o golpe no quadro e as `saida`; a falha à vista e o
P4 de «Ninguém para» (que pedem o P4 `ruim`) esperam o robô por lugar.

## Pronto quando

A Galeria joga do aviso ao resultado:
- com 4, 3, 2 e 1 jogador, e com o robô nos três temperamentos;
- aguenta o cabo que cai e volta;
- fecha com vencedor;
- abre o `S05_J21` com `--sala=galeria`;
- dá os quatro ouros da reta e grava as linhas `momento`;
- com `--bancada`, mostra a prateleira e a contagem e dá os quatro vereditos de antes (o gauntlet e a prova de
  poucos passam).

A prova do jogo passa nas duas rodadas, e a prova visual passa com a prancha olhada.

### Ao terminar

- No [quadro](README.md), quem coordena marca a linha **M1** com o commit.
- Commit sugerido (sem trailer): `feat: A Galeria no kit, o estande no tempo, a munição no tambor e no gatilho e o
  ouro da reta`.

## Provas

Os comandos: `SALA=S05_J21 bash tests/prova_do_jogo.sh` (o sh roda duas rodadas, sem bancada e com
`--bancada`), `bash tests/prova_do_jogo.sh` (o jogo inteiro) e `bash tests/prova_visual.sh`.

A `galeria.gd` sai, e a classe `SalaGaleria` some com ela. Em `godot/testes/prova_do_jogo.gd`, as 5 citações
mudam, ou o script não compila:

- linha 22: a chave `"galeria"` de `SO_COM_PERGUNTA` vira `"S05_J21"`. O `_termina_a_sala` lê a chave pelo
  `sala.id`, e o id agora é o slot;
- linhas 147 a 159: o bloco continua nos dois modos, para o percurso passar pela Galeria. Só o laço das armas
  (linhas 151 a 158) entra em `if Forja.bancada:`, e `SalaGaleria.NOME_ARMA` vira `galeria.NOME_ARMA` (o script
  carregado pelo catálogo). Com o bloco inteiro no `if`, a checagem da linha 912 falha fora da bancada;
- linhas 864 a 867 (`_em_pergunta`): `"galeria":` vira `"S05_J21":`, e `SalaGaleria.IDENTIFICAR`,
  `SalaGaleria.MUNICAO` e `SalaGaleria.MUNICAO_RESP` viram `sala.IDENTIFICAR`, `sala.MUNICAO` e
  `sala.MUNICAO_RESP`;
- linhas 904 e 912 (`_prova_do_modo`): `"galeria"` vira `"S05_J21"` nas duas listas.

Em `godot/testes/captura_jogo.gd`, os 4 momentos `"galeria"` (linhas 141 a 147) usam `SalaGaleria` e o passo
`ATIRAR`, que não existe mais. Eles passam a ser por tempo, como na J1. A chave continua `"galeria"`, porque é
o nome que o `SALAS=` pede:

```gdscript
		"galeria": [
			["galeria_tiro", fase.call("jogo", 6.0)],
			["galeria_pico", fase.call("jogo", 45.0)],
			["galeria_reta", fase.call("jogo", 86.0)],
		],
```

A prova entra como uma linha no `match` de `_prova_da_ficha` (o modelo da H08):

```gdscript
		"S05_J21", "galeria": await _prova_da_galeria()
```

E acrescente a função abaixo. O `_joga_o_minigame(slot, limite_s, a_cada_quadro)` é da H08.

```gdscript
# A Galeria (S05_J21): o apelido abre o minigame; o R2 recebeu a Weapon com a
# força do tambor; fora da bancada, as luzinhas nunca saem do número; o
# disparo tem o curso; a reta dá os quatro ouros, com o golpe no mesmo quadro.
func _prova_da_galeria() -> void:
	var leds_ok := [true]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if not Forja.bancada and int(Forja.percepcao(l).get("leds_jogador", 0)) != Forja.LEDS_DO_LUGAR[l]:
				leds_ok[0] = false
	var mg = await _joga_o_minigame("galeria", 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S05_J21", "Galeria: --sala=galeria abre o S05_J21")
	var linhas := _linha_do_tempo()
	var gat := linhas.filter(func(e): return e.get("tipo") == "saida" and e.get("o") == "gatilho" and e.get("lado") == "R2")
	var forcas := {}
	for e in gat:
		if e.get("modo") == "arma":
			forcas[int(e.get("params", [0, 0, 0])[2])] = true
	_esperar(forcas.has(8), "Galeria: a Weapon (2, 6, 8) chegou ao R2 (forças vistas: %s)" % [forcas.keys()])
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.alvos[v[0]]) == v.map(func(l): return int(mg.alvos[l])).max(),
		"Galeria: vence quem estourou mais alvos")
	if Forja.bancada:
		return
	_esperar(leds_ok[0], "Galeria: as luzinhas mostraram o número do jogador o tempo todo")
	var disparos := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("slot") == "S05_J21" and e.get("o") == "disparo")
	_esperar(disparos.size() >= 1 and disparos.all(func(e): return float(e.get("curso", 0.0)) >= 0.62),
		"Galeria: %d disparos, todos depois do clique" % disparos.size())
	var ouros := linhas.filter(func(e): return e.get("slot") == "S05_J21" and e.get("nome") == "alvo_de_ouro"
		and (e.get("tipo") == "momento" or e.get("o") == "momento"))
	var donos := {}
	for e in ouros:
		donos[int(e.get("lugar", -1))] = true
	_esperar(ouros.size() >= 4 and donos.size() >= 2, "Galeria: %d ouros, de %d lugares" % [ouros.size(), donos.size()])
	var com_golpe := ouros.filter(func(o): return linhas.any(func(e): return e.get("tipo") == "sensacao"
		and e.get("nome") == "golpe" and int(e.get("lugar", -1)) == int(o.get("lugar", -2))
		and absf(float(e.get("t", 0.0)) - float(o.get("t", 0.0))) <= 0.0167))
	_esperar(com_golpe.size() == ouros.size(), "Galeria: o golpe sai no quadro de cada ouro (%d de %d)" % [com_golpe.size(), ouros.size()])
	var reta := linhas.filter(func(e): return e.get("slot") == "S05_J21" and e.get("nome") == "reta")
	_esperar(reta.size() == 1, "Galeria: uma linha momento reta")
```

**Na prova visual** (`bash tests/prova_visual.sh`, F09), a Galeria está nas partidas de 3 e de 5.

O jogador do time olha a prancha:
- o quadro do meio do pico, com a luz da chave mais forte;
- um quadro com fuligem no muro e o cavaleiro recuado;
- o último quadro, com as moedas nos balcões.

**O que o André joga e sente** (`./run-local.sh -- --sala=galeria`):
- o tiro só sai no clique, e o clique no tempo dá prazer;
- o tambor esvazia na mesa e a parede do R2 afina de 8 para 6 e para 4 antes do clique seco;
- no pico, a luz sobe, os alvos sobem girando e às vezes vêm dois por batida;
- na reta, o ouro no meio do muro e os quatro atirando juntos, e as moedas no balcão de quem levou;
- com `--bancada`, a prateleira e a contagem das luzinhas, como antes.
