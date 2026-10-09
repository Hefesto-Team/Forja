# Q2 — Roubo de Bateria

**Sprint:** Q · **Slot:** S09_J42 · **Tamanho:** M · **Depende de:** Q1 (a seção no catálogo, o tipo `momento`), H04, H08, H07, F05 (`Forja.sentir`), F09 (`Forja.robo_acerta`), G03, G05, G13, G14, G15 · **Vem pela G13:** G10 (o Castle Kit, o Factory Kit e `Kit.caminho`; a reserva fica para o `.glb` que faltar)

## Por quê

Pega-bandeira em que quem carrega a bateria segura o pulso dela com L2 e R2 alternados, guiado pela mão; a
interferência invisível de hoje sai e entra o encontrão, que a sala vê, para que a bateria que cai na porta da base e
vai para o adversário faça a sala gritar pelo menos 1 vez em 100 s.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (onde mora, a FICHA, o robô, o registro, a prova)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) e, no mesmo arquivo, a seção «As decisões comuns dos
  minigames — H08»
- [A Q1, «Os ganchos»](Q1-a-prova.md#os-ganchos) (o `_gancho`, o `_respondeu`, a forma do `vencedor()` de equipe)

Tudo o mais que esta ficha usa (as cores, o brilho, a câmera, o movimento, o som, os stats, a régua da diversão)
está escrito aqui dentro, com o número.

As duas curvas do movimento (do 05): `ENTRA_SAI` é um `Tween` com `TRANS_SINE` e `EASE_IN_OUT`; `MOLA` é
`TRANS_BACK` com `EASE_OUT` (passa 4 % do alvo e volta).

## Arquivos que mudam

- `godot/scripts/minigames/s09/roubo_de_bateria.gd` (novo, `extends Minigame`, sem `class_name`) e o `.uid`.
- `godot/scripts/minigames/catalogo.gd`: `"S09_J42"` em `MINIGAMES` e na lista da seção `S09`, depois do `S09_J41`.
  **De todos:** Q1, Q3, Q4 e Q5.
- `godot/scripts/traducoes.gd`: as frases da tabela «As frases». **De todos:** Q1, Q3, Q4 e Q5.
- `godot/testes/prova_do_jogo.gd`: `_prova_roubo()` e a linha `"S09_J42": await _prova_roubo()` no `match` de
  `_prova_da_ficha`. **De todos:** Q1, Q3, Q4 e Q5.
- `docs/jogo/sistemas/minigames.csv`, linha 42: a coluna `faro` passa a «pista: o pulso da bateria chega antes» (a
  interferência saiu). Só esta linha; nenhuma outra ficha Q muda o arquivo.

## Como se joga

**Carregue no pulso!** Leve a bateria do meio até a sua base. Quem carrega segura o pulso dela: L2 e R2 alternados, no
tempo, e a mão diz qual (o pulso bate no atuador do lado do gatilho da vez). Quem não carrega anda e dá encontrões no
carregador da outra equipe.

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J42",
	"titulo": "Roubo de Bateria",
	"verbo": "Carregue no pulso!",
	"genero": "2v2",
	"icone": "gatilhos",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S09_J42",
	"duracao": 100.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir"],
	"material": "metal",
	"microjogo": {"verbo": "Carregue!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_HAPTICA,
	"textura_no_acerto": false,
	"gesto": "pick-up",
}
```

As entradas são três, todas eixos (fora da lista): o analógico esquerdo, o L2 e o R2. `textura_no_acerto` é `false`
porque a háptica é a pista do pulso: a textura do acerto encostaria nela.

### O tempo

A faixa `MUS_S09_J42` tem 138 BPM: uma batida dura 0,4348 s. 100 s são 230 batidas.

| constante | valor | o que é |
| --- | --- | --- |
| `VEL` | 4,0 m/s | andar, com o analógico (pelo `dt`, é entrada) |
| `LENTO` | 0,7 | o carregador anda a 0,7 × `VEL` |
| `LENTO_SOZINHO` | 0,85 | com três, o sozinho carrega a 0,85 × `VEL` |
| `BASE_X` | `[-6.5, 6.5]` | o centro da base da Brasa e o da Maré |
| `BASE_R` | 1,5 m | o raio da base |
| `PORTA` | de 3,0 a 5,0 m de \|x\| | a faixa de 2 m na frente da base, do lado do meio |
| `PEGA_R` | 0,8 m | a bateria livre a essa distância é de quem chegou primeiro |
| `ENCONTRAO_R` | 1,0 m | a distância do encontrão |
| `CAMBALEIO` | 0,5 m | o empurrão do encontrão, antes dos ganchos |
| `RECARGA` | 4 batidas | entre dois encontrões do mesmo lugar |
| `RECARGA_SOZINHO` | 8 batidas | entre dois encontrões contra o sozinho (com três) |
| `PONTOS` | `[0, 50, 75, 100]` | pontos da equipe por pulso julgado |
| `ENTREGA` | 200 | pontos da equipe por bateria entregue |
| `MANCHA_S` | 4,0 s | o tempo da mancha onde a bateria caiu |
| `FORCA_DE`, `FORCA_ATE` | 3, 8 | a força do peso nos gatilhos: começa em 3, +1 a cada 4 batidas carregando, até 8 |
| `SOBRECARGA_DE` | batida 76 (33,0 s) | o pulso passa a ser em toda batida |
| `DUAS_DE` | batida 152 (66,1 s) | duas baterias no meio |
| `DOBRO_DE` | batida 214 (93,0 s) | as últimas 16 batidas: a entrega vale 2 |

### As regras

- **As equipes:** `presentes()` na ordem; os dois primeiros são a Brasa, os dois seguintes a Maré, sem Aprendiz (ver
  «Com menos de quatro»).
- **Andar:** o analógico esquerdo (`Forja.eixo(l, Forja.LX)`, `Forja.LY`), a `VEL × velocidade` m/s; quem carrega anda a
  `LENTO` disso. Os cavaleiros se separam: a cada quadro, dois a menos de 0,9 m (raio
  0,45 cada) se afastam, cada um, metade da sobreposição, na linha entre os dois centros (o `prova.gd` de hoje não tem
  essa conta: as linhas 387 a 397 são o empurrão dos pilares e o limite da arena, que saem).
  O campo vai de x −8,0 a 8,0 e de z −3,5 a 3,5.
- **Pegar:** a bateria livre a menos de `PEGA_R` de um cavaleiro é dele (o primeiro a chegar; quem está na queda do
  `levantar` não pega). No mesmo quadro, os dois gatilhos ganham peso:
  `Forja.gatilho(l, 0, Forja.GATILHO_RESISTENCIA, 2, 3)` e `Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 3)`; a
  cada 4 batidas carregando, a força sobe 1 (os dois gatilhos de novo), até 8. É a bateria pesando na mão.
- **O pulso** (a nota do carregador): a partir da primeira batida inteira depois de pegar.
  - Antes da batida 76: um pulso a cada 2 batidas, nas pares; o pulso `k` (contado desde a pega) é L2 se `k` é par, R2
    se é ímpar.
  - Da batida 76 em diante: um pulso em toda batida; L2 nas pares, R2 nas ímpares.
  - Com `Ritmo.simples[l]`: sempre um pulso a cada 2 batidas, como antes da 76.
  - A pista vem em `t(bn) - 0.2174 - _gancho(l, "pista") / 1000.0` (meia batida antes, e o Faro adianta), no atuador do
    lado do gatilho: `Forja.som_haptica(l, "pulso", "", 1.0)` para o L2, `Forja.som_haptica(l, "", "pulso", 1.0)` para
    o R2, com `anotar("pista", l, {"n": n, "evento": "mandou", "canal": "haptica", "o_que": "L2"})` (ou `"R2"`).
  - O aperto é o gatilho passando de 0,6 subindo. O gatilho certo → `julgar_toque(l, t(bn), n, true)`. O outro →
    `_motivo[l] = "trocou"` e `nota_perdida(l, n)`. Nada até a nota passar (140 ms) → `nota_perdida(l, n)`.
- **Entregar:** o carregador dentro da própria base → `_baterias[e] += 1` (2 da batida 214 em diante),
  `marcar_equipe(e, ENTREGA)` (400 da batida 214 em diante), os gatilhos dele a `GATILHO_OFF`, e uma bateria nova nasce
  no meio (0, 0, 0) 2 batidas depois.
- **O encontrão:** quem não carrega, a menos de `ENCONTRAO_R` do carregador da outra equipe, com o analógico a 0,8 ou
  mais e a no máximo 45° da direção do carregador, dá o encontrão (uma vez a cada `RECARGA` batidas). O carregador
  cambaleia `CAMBALEIO × tranco(quem empurra) × empurrao(carregador)` metros na direção do analógico, em 1 colcheia
  com `ENTRA_SAI`, e não larga a bateria. É o que tira o carregador do caminho e o faz errar o pulso.
- **A curva:**

  | trecho | batidas | o que acontece |
  | --- | --- | --- |
  | 0 a 33 s | 0 a 75 | uma bateria no meio; o pulso a cada 2 batidas |
  | 33 a 66 s, a sobrecarga | 76 a 151 | o pulso em toda batida |
  | 66 s ao fim, a reta | 152 a 229 | duas baterias no meio, em (0, 0, −1,5) e (0, 0, 1,5); da batida 214 em diante, a entrega vale 2 |

  No primeiro quadro da batida 214 sai
  `anotar("momento", -1, {"nome": "reta", "lugar": -1, "t_musica": Ritmo.t_musica(), "objeto": {"entrega": 2}})`.
- **Ensina sem falar:** na contagem do kit (batidas 0 a 3), uma bateria aparece na mão do primeiro presente de cada
  equipe, a 4 m da própria base (x = −2,5 na Brasa, 2,5 na Maré), já com o peso nos gatilhos. O pulso dele começa na
  batida 4, como qualquer pega. A bateria do meio nasce na batida 4.

### A falha

A bateria cai: o pulso errado, trocado ou perdido.

- Ela cai no chão onde está, livre, com 12 faíscas `Efeitos.faiscas(self, pos, Tema.TUNGSTENIO, 12, 0.6)`;
- fica uma mancha `Kit.caixa(self, Vector3(1.2, 0.005, 1.2), pos_no_chao, Kit.material(Tema.TUNGSTENIO, 0.0, 1.0))`
  por `MANCHA_S`;
- os gatilhos dele vão a `GATILHO_OFF`; a mão sente `Forja.sentir(l, "golpe")`;
- ele fica parado meia batida, olhando a bateria (`olhar_para`), e não pega bateria nenhuma por
  `_queda_s(l) = maxf(0.1087, snappedf(2 * 0.4348 * _gancho(l, "levantar"), 0.1087))` (2 tempos × `levantar`,
  arredondado à semicolcheia de 0,1087 s);
- treme de lado ±0,02 m por 3 quadros, e a animação vai a 0,5× por 1 batida.

Qualquer um pode pegá-la, até ele mesmo quando a queda passa.

### Caiu na porta (o momento)

Quando a bateria cai com o centro dela na `PORTA` da base de quem a deixou cair (\|x\| entre 3,0 e 5,0, do lado da base
dele) e o primeiro a pegá-la é da outra equipe, no primeiro quadro da batida seguinte à pega:

1. `anotar("momento", l, {"nome": "caiu_na_porta", "lugar": l, "t_musica": Ritmo.t_musica()})`, com `l` = quem deixou
   cair;
2. `Forja.sentir(l, "golpe")` em quem deixou cair (ele não carrega, então não tem pista na mão);
3. o degrau **estrondo**: `tremer(TREMOR_ESTRONDO)` (0,05 m, 2 batidas, decai sozinho na câmera da G05); parada de 3 quadros (`p.anim.speed_scale = 0` nos
   quatro); 48 faíscas `Efeitos.faiscas(self, pos_da_bateria, Tema.TUNGSTENIO, 48, 1.0)`; o preenchimento
   (`environment.ambient_light_energy`, ver «A cena») a ×0,7 por 1 batida, volta em 1 batida; o contorno de quem pegou vai de 2,4 a 3,0 no mesmo tempo;
4. o rastro: a mancha já está no chão (4 s); quem deixou cair continua parado olhando até a queda passar.

Com `Opcoes.movimento == 1`: a câmera da G05 já não treme (a ficha chama `tremer` igual), e a ficha tira a parada.

### O fim e o vencedor

O kit fecha nos 100 s de música. O vencedor: a equipe com mais baterias entregues; no empate, `equipe_vencedora()` (a
de mais pontos; no empate, a Brasa). `vencedor()` devolve os da equipe vencedora (por pontos) e depois os da outra,
na forma da Q1.

### Com menos de quatro

Um boneco não carrega bateria: aqui não há Aprendiz.

| jogadores | o que muda | `com_poucos()` |
| --- | --- | --- |
| 3 | dois contra um; o sozinho carrega a `LENTO_SOZINHO`, e o encontrão contra ele espera `RECARGA_SOZINHO` | `"Dois contra um"` |
| 2 | um contra um | `""` |
| 1 | ele contra a sentinela (abaixo); o vencedor é ele, e a tela mostra as baterias | `"Contra a sentinela"` |

**A sentinela:** a torre `_peca("castle-kit/tower-base", "column", Vector3(0, 0, -3.0))` com um olho
`Kit.esfera` de 0,15 m de raio a 2,2 m de altura, `Tema.neon(Tema.VIOLETA, 1.0, "mundo")`. A cada 8 batidas em que ele
carrega, o olho vai a 1,2 por 1 batida e o carregador cambaleia `CAMBALEIO` na direção oposta à torre.

**O controle que cai:** se carregava, a bateria cai sem falha e sem momento; as notas dele não abrem; volta andando de
onde parou.

### O robô

Anda pelo analógico até o alvo (a bateria livre; a própria base se carrega; o carregador inimigo se a equipe dele não
carrega), sente o lado do pulso na placa virtual e aperta o gatilho certo no tempo. Quando `Forja.robo_acerta()` diz não
no encontrão, para a 1,5 m do carregador em vez de empurrar.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var p := jogador(l)
	if p == null:
		return
	var alvo := _robo_destino(l)
	var d := Vector2(alvo.x - p.position.x, alvo.z - p.position.z)
	var mv := d.normalized() if d.length() > 0.3 else Vector2.ZERO
	Forja.robo_eixo(l, Forja.LX, mv.x, 0.1)
	Forja.robo_eixo(l, Forja.LY, mv.y, 0.1)
	if not _carrega_alguma(l):
		return
	var b := Ritmo.batida()
	var n := ceili(b)
	if b > n - 0.55 and b < n - 0.1:
		var s := _robo_sente(l)
		if s.x + s.y > 0.05:
			_robo_lado[l] = 0 if s.x > s.y else 1
			_robo_pulso[l] = n
	if _robo_pulso[l] == n and _robo_apertou[l] != n:
		if _robo_decidiu[l] != n:
			_robo_decidiu[l] = n
			_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.25
		if Ritmo.t_musica() >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
			Forja.robo_eixo(l, Forja.L2 if _robo_lado[l] == 0 else Forja.R2, 1.0, 0.08)
			_robo_apertou[l] = n


func _robo_sente(l: int) -> Vector2:
	if _rumble[l]:
		var pc := Forja.percepcao(l)
		return Vector2(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0)))
	var v := Forja.som_virtual(l)
	return Vector2(float(v.get("esq", 0.0)), float(v.get("dir", 0.0)))
```

O `_robo_destino(l)` devolve, para quem não carrega e tem `_robo_empurra[l] == false`, um ponto a 1,5 m do carregador;
`_robo_empurra[l]` é sorteado com `Forja.robo_acerta()` a cada `RECARGA` batidas. Sem pista sentida, o robô não aperta:
perde a bateria, como gente.

### Os ganchos

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

`godot/scripts/minigames/s09/roubo_de_bateria.gd`:

```gdscript
extends Minigame
## Roubo de Bateria (S09_J42). Pega-bandeira: leve a bateria do meio até a
## sua base. Quem carrega segura o pulso dela (L2 e R2 alternados, no tempo; a
## mão diz o lado). Quem não carrega dá encontrões no carregador da outra equipe.
##
## A falha: o pulso falha e a bateria cai, livre. O vencedor: a equipe com
## mais baterias. O alto-falante do dono: o clique da pega. O registro mede: o
## pulso (pista, pela háptica ou pelo rumble) e a resposta, o peso nos gatilhos
## (saida), o momento caiu_na_porta. O robô: sente o lado do pulso na placa
## virtual. Com menos de quatro: dois contra um, um contra um, a sentinela.
## A régua: a cor da equipe está no chão; a bateria é do mundo até alguém pegar.

const FICHA := { ... }   # a de «A ficha de dados»
# as constantes de «O tempo»
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}

var _baterias := [0, 0]
var _bats: Array = []                 ## [{pos, carregador (-1 livre), nasce_em, caiu_de (-1), caiu_na_porta}]
var _carrega := -1                    ## quem carrega a primeira (o robô olha)
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _gatilho_da_nota := [0, 0, 0, 0]  ## 0 = L2, 1 = R2
var _n := [0, 0, 0, 0]
var _eixo_antes := [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
var _forca := [3, 3, 3, 3]
var _pegou_em := [-1.0, -1.0, -1.0, -1.0]
var _recarga_ate := [-99.0, -99.0, -99.0, -99.0]
var _parado_ate := [-1.0, -1.0, -1.0, -1.0]
var _sem_pegar_ate := [-1.0, -1.0, -1.0, -1.0]
var _motivo := ["", "", "", ""]
var _momento_pendente := -1           ## quem deixou cair, até a batida seguinte à pega
var _rumble := [false, false, false, false]
var _sentinela: Node3D = null
var _robo_lado := [0, 0, 0, 0]
var _robo_pulso := [-1, -1, -1, -1]
var _robo_apertou := [-1, -1, -1, -1]
var _robo_decidiu := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]
var _robo_empurra := [true, true, true, true]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 14.60, 12.72)   # a G05 recua ×1,0616 a 35 mm: a câmera fica em (0, 15,5, 13,5)
	camera_olhar = Vector3(0, 0, 0)
	_montar_cena()                  # «A cena»
	# as equipes (sem Aprendiz), as baterias da contagem, os cavaleiros nas bases, a sentinela (com um)


func iniciar_jogo() -> void:
	for l in presentes():
		_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)
		if _rumble[l]:
			anotar("troca", l, {"de": "haptica", "para": "rumble"})


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	for l in presentes():
		if not conectado(l):
			_largar_sem_culpa(l)        # se carregava, a bateria cai sem falha
			continue
		_andar(l, b, dt)                # o analógico; parado depois da falha; o cambaleio pela batida
		_encontrao(l, b)                # «As regras»
		_pegar(l, b)                    # a bateria livre perto: pega, o peso; marca o momento pendente
		if _carrega_alguma(l):
			_peso(l, b)                 # +1 de força a cada 4 batidas, até 8
			_pulso(l, b)                # a pista, o gatilho cruzando 0,6, a nota que passou
			_entregar(l, b)
	_nascer_baterias(b)
	_caiu_na_porta(b)               # o momento, no primeiro quadro da batida seguinte à pega
	_sentinela_age(b)
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar_equipe(equipe[l], PONTOS[j])
	_respondeu(l, _n[l] - 1, "certo")


func falha(l: int) -> void:
	_largar(l)                       # «A falha»


func vencedor() -> Array:
	var e := BRASA if _baterias[0] > _baterias[1] else (MARE if _baterias[1] > _baterias[0] else maxi(equipe_vencedora(), BRASA))
	var ganhou := presentes().filter(func(l): return equipe[l] == e)
	var perdeu := presentes().filter(func(l): return equipe[l] != e)
	ganhou.sort_custom(func(a, b): return pontos[a] > pontos[b])
	perdeu.sort_custom(func(a, b): return pontos[a] > pontos[b])
	return ganhou + perdeu


func _gancho(l: int, nome: String) -> float:
	return float(NEUTRO[nome])   # troque por Cavaleiro.gancho(l, nome) quando `grep -rn "static func gancho" godot/scripts/` achar


func _respondeu(l: int, n: int, resposta: String) -> void:
	anotar("entrada", l, {"o": "resposta", "n": n, "resposta": resposta})
```

As outras funções, uma frase cada:

- `_pulso(l, b)`: a próxima nota pela regra de «O pulso»; a pista na hora certa, uma vez (`_rumble[l]`:
  `Forja.sentir(l, "golpe_esq", 180)` ou `"golpe_dir"`, com `canal` `rumble`); `nova_nota`; o L2 e o R2 cruzando 0,6
  pelos `_eixo_antes`; o certo julga, o outro troca, a que passou se perde (`_respondeu(l, n, "nenhuma")`).
- `_peso(l, b)`: quando `floor((b - _pegou_em[l]) / 4)` sobe, `_forca[l] = mini(_forca[l] + 1, 8)` e os dois
  `Forja.gatilho(l, lado, Forja.GATILHO_RESISTENCIA, 2, _forca[l])`.
- `_encontrao(l, b)`: a regra de «As regras»; o cambaleio é um `Tween` de 1 colcheia; quem empurra sente
  `Forja.sentir(l, "acerto")`; `anotar("jogo", l, {"o": "encontrao", "alvo": c, "metros": m})`.
- `_largar(l)`: a falha; guarda `caiu_de = l` e `caiu_na_porta` (\|x\| entre 3,0 e 5,0, do lado da base de `l`).
- `_pegar(l, b)`: a pega; se a bateria tem `caiu_na_porta` e `l` é da outra equipe, `_momento_pendente = caiu_de`.
- `status(l)`: `"Brasa %d" % _baterias[0]` ou `"Maré %d" % _baterias[1]`.
- A dica, com `na_raia(l)`: carregando, `["@l2", "@r2"]` enquanto `not aprendeu(l)`; sem carregar, `["@stick_l"]`.

### A casa nova e o catálogo

1. Criar o script; `"$GODOT" --headless --path godot --import --quit`; commitar o `.uid`.
2. `catalogo.gd`: `"S09_J42": preload("res://scripts/minigames/s09/roubo_de_bateria.gd")` em `MINIGAMES`; `"S09_J42"`
   na lista da seção `S09`, depois do `S09_J41`.
3. `minigames.csv`, linha 42: na coluna `faro`, «pista: o pulso da bateria chega antes».

### As frases

| português | inglês |
| --- | --- |
| Roubo de Bateria | Battery Heist |
| Carregue no pulso! | Carry on the pulse! |
| Carregue! | Carry! |
| Dois contra um | Two against one |
| Contra a sentinela | Against the sentry |

`"Brasa"` e `"Maré"` já entraram pela Q1.

### O registro

- `pista` de cada pulso (`o_que` `L2` ou `R2`, `canal` `haptica` ou `rumble`) e a `entrada` `resposta`;
- `saida` do gatilho (o peso a cada pega, a cada degrau de força e a cada entrega);
- `troca` `haptica` → `rumble` no rádio, uma vez;
- `jogo` `encontrao`; `momento` `caiu_na_porta` e `reta`; `sensacao` `golpe`;
- `nota` e `toque` do pulso (o kit).

### Armadilhas

- **O L2 é do minigame aqui:** `usa_gatilho = true` no `montar()`, senão o item (G03) mexe no L2 e o peso some.
- **Uma pista, um lado:** `Forja.som_haptica(l, "pulso", "", 1.0)` ou `(l, "", "pulso", 1.0)`, nunca os dois.
- **No rádio, a pista e o acerto não se encostam:** a pista vem meia batida (217 ms) antes e dura 180 ms.
- **Rumble e háptica nunca juntos:** o carregador não sente o encontrão na mão (a mão dele é do pulso), e a textura do
  acerto está desligada (`textura_no_acerto: false`).
- **O cambaleio anda pela batida** (1 colcheia); o andar do analógico usa o `dt` (é entrada).

## A cena

- **A câmera:** a arena (35 mm, plongée de 48,9°, nunca corta). `camera_pos = Vector3(0, 14.60, 12.72)`,
  `camera_olhar = Vector3(0, 0, 0)`. No modo `"fixa"`, a G05 recua a câmera por `Lente.recuo(35)` = 1,0616 a partir do
  olhar: `olhar + (camera_pos − olhar) × 1,0616` = (0, 15,5, 13,5), que é onde se mediu. Medido por projeção com 37,8° vertical e 16:9: as bandeiras em (±8, 2,2, −2) caem
  em x 0,18 e 0,83; a `PORTA` (\|x\| de 3,0 a 5,0, z de −3,0 a 3,0) cai entre x 0,28 e 0,72, dentro dos 60 % do meio;
  o meio (0, 0, ±3,5) cai em y 0,33 e 0,71. Sem `camera_foco`.
- **A luz** (S9): a ficha não chama `Tema.luz_da_secao`. A entrada da sala chama `acender(9, partida.lado() == "B")` (G15 e
  G16): no lado A, densidade 0,012 e energia da chave 1,8; no lado B, 0,0156 e 1,53. A chave são as tochas de `luzes()`:
  o `Sala.acender(luz)` as pinta. Logo depois do `luzes(...)`, a ficha guarda em `_tochas` os `OmniLight3D` filhos da
  sala, menos o enchimento de cima, em (0, 9, 2). Quando a ficha mexe na chave, multiplica a `light_energy` das `_tochas`
  sobre a `energia_chave` que a G15 pôs. O preenchimento é `environment.ambient_light_energy` (0,42 pela G15) e a névoa
  é `environment.fog_density`, com `var environment := get_viewport().find_world_3d().environment`; os dois voltam ao
  valor de antes. As tochas de hoje: `luzes([Vector3(-10, 3, -6), Vector3(10, 3, -6), Vector3(-10, 3, 6),
  Vector3(10, 3, 6)])`. Na entrada da sobrecarga (batida 76), a `light_energy` das `_tochas` sobe 20 % em 1 batida e a
  `fog_density` vai a ×0,8; voltam em 2 batidas.
- **As bases:** `Kit.caixa(self, Vector3(3.0, 0.03, 3.0), Vector3(BASE_X[e], 0.02, 0), Kit.material(CORES_DAS_EQUIPES[e], 0.0, 0.9))`
  e a bandeira `Kit.peca(self, "banner", Vector3(±8.0, 0, -2.0), 0.0, 1.0)` em cada.
- **A porta:** nada desenhado; é a faixa de chão entre a base e o meio.
- **A bateria:** um `Node3D` `bateria` sem escala, com a peça `_peca("factory-kit/box-small", "barrel", Vector3.ZERO)`
  passada para dentro dele (`reparent(bateria)`). A caixa pequena do Factory Kit, que a G10 importa, sai do `Kit.peca`
  com a escala 0,5 do pacote: 0,30 × 0,28 × 0,25 m. A reserva é o `barrel` do Mini Dungeon com `scale` ×1,2: 0,62 ×
  0,58 × 0,62 m. O Platformer Kit (o `jewel`) não entra: a G10 não o importa. A runa fica em cima da peça,
  `Kit.caixa(bateria, Vector3(0.3, 0.06, 0.3), Vector3(0, h + 0.05, 0), mat)`, com `h` 0,28 na caixa e 0,58 no barril.
  `_peca(nome, reserva, pos)` é o da Q1: usa `nome` se `ResourceLoader.exists(Kit.caminho(nome))`, senão a reserva.
  - Livre: `Tema.neon(Tema.TUNGSTENIO, 1.0, "forja")`, sem pulsar (o tungstênio é do dono `"forja"`, teto 2,4; o
    `"mundo"` é o violeta).
  - Na mão: `Tema.neon(Tema.JOGADOR[l], 2.0, l)`, 2,6 por 4 quadros a cada pulso acertado; fica acima da cabeça
    (`pos + Vector3(0, 2.4, 0)`), e o cavaleiro faz `holding-both`.
  - Caída: no chão onde caiu, de novo `TUNGSTENIO` a 1,0.
- **O meio:** o disco `Kit.cilindro(self, 1.0, 0.02, Vector3.ZERO, Kit.material(Tema.GRAFITE, 0.0, 0.9))` e, no fundo,
  o baú de onde as baterias saem, `Kit.peca(self, "chest", Vector3(0, 0, -3.2), 0.0, 1.0)` (Mini Dungeon).
- **Os cavaleiros:** posições livres, `p.preso = true`, o disco da equipe sob cada um
  (`Kit.cilindro(self, 0.7, 0.02, pos, Kit.material(CORES_DAS_EQUIPES[e], 0.0, 0.9))`); `sprint`, `walk` ou `idle` pela
  velocidade (`p.animar(nome, vel)`).
- **O encontrão:** quem empurra faz `attack-melee-right` em 1 colcheia; o carregador inclina 10° para o lado do
  empurrão e volta com `MOLA` em 1 batida.
- **Os brilhos e os donos:**

  | o quê | dono | energia |
  | --- | --- | --- |
  | o contorno de cada cavaleiro | o lugar | 2,4; 3,0 por 1 batida em quem pegou na porta |
  | o acento da peça (friso, costura, runa do item) | o lugar | 1,6 (o da G13) |
  | a runa da bateria na mão | o lugar | 2,0; 2,6 por 4 quadros no acerto |
  | a runa da bateria livre ou caída | `"forja"` | 1,0 |
  | o olho da sentinela | `"mundo"` | 1,0; 1,2 por 1 batida quando empurra |
  | as faíscas da queda | `"forja"` | 1,0 por 12 quadros |
  | as bases, os discos, as bandeiras, a mancha | ninguém | 0 (impressos) |

- **O que sai:** a `atmosfera` com `Tema.CIANO`, a runa em `Tema.AMARELO` que pulsava até 3,0 e o olho vermelho de hoje.

## O som

| quando | onde | id do mapa | como |
| --- | --- | --- | --- |
| a partida | TV | `mus_s09_j42` (138 BPM, Sol menor; reserva `sint_trilha`) | a FICHA, `"faixa": "MUS_S09_J42"` |
| a pega | controle de quem pegou | `mod_coleta` | `Forja.som_falante(l, "coleta", 0.7)` |
| o pulso (a pista) | atuador do lado, no controle do carregador | `mod_pulso` | `Forja.som_haptica(l, "pulso", "", 1.0)` ou `(l, "", "pulso", 1.0)` |
| a entrega | TV | `ponto_0`/`ponto_1` | `Som.tocar("ponto", Vector3(BASE_X[e], 0, 0), -2.0)` |
| a bateria cai | TV | `vazio_0` | `Som.tocar("vazio", pos, -4.0)` |
| o encontrão | TV | `golpe_0` a `golpe_4` | `Som.tocar("golpe", pos, -6.0)` |
| caiu na porta | TV | `golpe_0` a `golpe_4` | `Som.tocar("golpe", pos, 0.0)`, no quadro do momento |
| a nota do perfeito, a quebrada do erro | controle do dono | `mod_nota_p1..p4`, `mod_nota_quebrada_p1..p4` | o kit |
| o apito, a vitória | TV | `jin_apito`; `vitoria_sala_0`/`1` | o kit |

O alto-falante toca um som por vez: vitória > julgamento > segredo > pio > coleta > clique.

## O controle

| evento | quem carrega | os outros | prova sem a mão |
| --- | --- | --- | --- |
| a pega | os dois gatilhos em Resistência (2, 3); `mod_coleta` 0,7 no alto-falante | nada | `percepcao(c).gatilho_esq == 0x21` e `gatilho_dir == 0x21`; os dos outros `0x05` |
| carregando, a cada 4 batidas | a força sobe 1, até 8 | nada | linha `saida` de gatilho com a força nova, de 4 em 4 batidas |
| o pulso | `mod_pulso` no atuador do lado (L2 esquerdo, R2 direito), meia batida antes; no rádio, `golpe_esq`/`golpe_dir` de 180 ms | nada | `som_virtual(c)`: `esq > 0.05` e `dir < 0.02` (ou o contrário) no quadro da pista; o robô aperta o lado que sentiu |
| a entrega, a queda | os gatilhos em Off; na queda, `golpe` (1,0/0,6/250) | nada | `gatilho_esq == 0x05` depois da entrega; linha `sensacao` `golpe` na queda |
| o encontrão | nada na mão (é do pulso) | quem empurra: `acerto` (0,3/0,6/80) | linha `sensacao` `acerto` em quem empurrou; linha `jogo` `encontrao` |
| caiu na porta | — | quem deixou cair: `golpe` | linha `sensacao` a até 16,7 ms do `momento` do mesmo lugar |
| a barra de luz | a cor do lugar, sempre | o mesmo | `percepcao(l).luz` na cor do lugar em ≥75 % das amostras |
| as luzinhas | o número do jogador, sempre | o mesmo | `leds_jogador == Forja.LEDS_DO_LUGAR[l]` |
| o microfone | Não se aplica: o roubo é de mão e de corpo | — | — |

**No rádio** (sem háptica, `not Forja.som_tem(l, Forja.PAPEL_HAPTICA)`): a pista vai pelo rumble do lado, com a
`troca` uma vez; o peso dos gatilhos vai pela ponte.

## O cavaleiro

- **Os stats** (`minigames.csv`, linha 42):
  - Peso: `tranco` no encontrão que ele dá (×0,84 a ×1,16 do stat 1 ao 5) e `empurrao` no que ele sofre (×1,16 a
    ×0,84). Um leve empurrado por um pesado cambaleia 0,5 × 1,16 × 1,16 = 0,67 m; um pesado empurrado por um leve,
    0,5 × 0,84 × 0,84 = 0,35 m.
  - Passo: `velocidade` só carregando (×0,94 a ×1,06): 2,63 m/s a 2,97 m/s com a bateria.
  - Fôlego: `levantar` no tempo sem pegar depois da queda, 2 tempos × 1,25 a × 0,75 (1,09 s a 0,65 s).
  - Faro: `pista` adianta a pista do pulso, −40 a +40 ms; a nota cai no mesmo tempo.
  - Nenhum stat mexe na janela de julgamento nem nos pontos.
- **A conta:** `_gancho(l, nome)` devolve o neutro até existir `Cavaleiro.gancho`.
- **Como aparece:** o cavaleiro entra como a G13 o montou (a raça, a cabeça, o superior em tecido L 0,46 a 0,58, o
  inferior em couro L 0,22 a 0,36), sem tinta do minigame. O néon do dono é o friso e a costura a 1,6 e o contorno a
  2,4; a runa da bateria na mão acende na cor dele a 2,0. A raça não muda a cápsula (raio 0,45 na separação), a
  velocidade nem a janela.
- **O item:** fica onde a G13 o pôs (a arma na mão direita, o Escudo no braço esquerdo, o amuleto no peito). Carregando,
  `holding-both` ergue as duas mãos com a bateria; a arma fica na mão.

## As reações

- **Adesivo:** nenhum durante o jogo; todos jogam a partida inteira.
- **Os carimbos que este minigame pode disparar** (o jogo detecta pelo registro):

  | carimbo | o evento aqui | onde |
  | --- | --- | --- |
  | `car_em_chamas` | 5 PERFEITOs seguidos de pulso do mesmo carregador | acima da cabeça dele |
  | `car_por_um_fio` | a equipe vence com 2 % dos pontos ou menos de diferença | acima da cabeça do vencedor, no resultado |

  O `car_acorde` não sai aqui: só os carregadores tocam nota, e nunca são quatro.

## A diversão

**O grito: caiu na porta da base** (`caiu_na_porta`). O pulso errado derruba a bateria a 2 m da própria base, e quem
pega é o adversário. Degrau estrondo.

- **O grito acontece no meio da tela:** a `PORTA` inteira cai entre `x_tela` 0,28 e 0,72, e a bateria com a runa a
  2,4 m tem `altura_tela` ≥ 0,08 na prancha de 480 × 270.
- **Quem perde ainda pega:** a bateria caída é de qualquer um, até de quem a deixou cair.
- **Como o jogador do time confere:**
  1. mesa das duplas (P1 `bom` e P2 `ruim` na Brasa contra P3 `medio` e P4 `medio`, semente 7): pelo menos 1 linha
     `momento` `caiu_na_porta` em 100 s;
  2. cada linha `momento` tem uma `sensacao` do mesmo lugar a até 16,7 ms, e o `t_musica` cai a até 1 quadro de uma
     batida;
  3. na prancha da mesa das duplas, uma bateria no chão com \|x\| entre 3,0 e 5,0 em pelo menos 1 quadro, com a mancha
     embaixo.

## Pronto quando

O `S09_J42` joga do aviso ao resultado com 4, 3, 2 e 1 jogador (com a sentinela) e com o robô nos três temperamentos,
aguenta o cabo que cai (a bateria cai sem culpa) e volta, fecha com uma equipe vencedora, pesa os dois gatilhos só em
quem carrega, não tem interferência nem ✕, e faz pelo menos 1 `caiu_na_porta` na mesa das duplas; as provas abaixo
passam e a prancha foi olhada.

## Provas

Em `godot/testes/prova_do_jogo.gd`, com a linha `"S09_J42": await _prova_roubo()` no `match` de `_prova_da_ficha(slot)`:

```gdscript
## S09_J42: quem carrega sente o peso nos dois gatilhos (0x21) e os outros
## não; o pulso bate num atuador só; a força sobe com o tempo carregando.
func _prova_roubo() -> void:
	var conta := {"peso": false, "solto": true, "lado": false, "forca_max": 0}
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var p := Forja.percepcao(l)
			var pesa := int(p.get("gatilho_dir", 0)) == 0x21 and int(p.get("gatilho_esq", 0)) == 0x21
			if mg._carrega_alguma(l):
				conta.peso = conta.peso or pesa
				conta.forca_max = maxi(conta.forca_max, mg._forca[l])
				var v := Forja.som_virtual(l)
				var esq := float(v.get("esq", 0.0))
				var dir := float(v.get("dir", 0.0))
				if (esq > 0.05 and dir < 0.02) or (dir > 0.05 and esq < 0.02):
					conta.lado = true
			elif pesa and mg._sem_pegar_ate[l] < Ritmo.t_musica():
				conta.solto = false
	var mg := await _joga_o_minigame("S09_J42", 150.0, olhar)
	if mg == null:
		return
	_esperar(conta.peso, "S09_J42: o carregador sente o peso nos dois gatilhos")
	_esperar(conta.solto, "S09_J42: quem não carrega tem os gatilhos soltos")
	_esperar(conta.lado, "S09_J42: o pulso bate num atuador só")
	_esperar(conta.forca_max >= 4, "S09_J42: a força do peso subiu (%d)" % conta.forca_max)
```

No `_prova_do_relatorio()`, com as linhas do `S09_J42`: há `pista` com `o_que` `L2` e com `R2`; nenhuma linha com
`o == "interferencia"`; cada `momento` tem `sensacao` do mesmo lugar a até 16,7 ms.

Os comandos:

```bash
SALA=S09_J42 bash tests/prova_do_jogo.sh
bash tests/prova_visual.sh
bash tests/prova_sem_rastro.sh
```

A mesa das duplas pede o robô por lugar (`--robo=bom,ruim,medio,medio --semente=7`), que a F09 ainda não tem: até
existir, a checagem da diversão roda com `--robo=ruim --semente=7` (o que mais derruba) e o mínimo de 1 vale igual.

**As pranchas que se olham** (`SAIDA/prancha-<n>.png`):

- a de quatro com `bom`: a bateria no alto na cor do carregador, as bases nas cores das equipes, alguém entregando;
- a de quatro com `ruim`: a bateria caída com a mancha na porta;
- a de um: a sentinela com o olho aceso;
- a do cabo que cai: a bateria no chão onde ele estava;
- nas quatro: as roupas de cima e de baixo de cada cavaleiro em valores diferentes, e o néon só no friso e na costura.

**Com o André (local):** `./run-local.sh -- --sala=S09_J42`, dois no cabo e dois no rádio. O pulso L2/R2 tem de dar
para seguir pela mão enquanto se corre; o peso tem de crescer até a entrega; o encontrão tem de tirar o carregador do
caminho sem arrancar a bateria. Com três, o sozinho não pode ser presa fácil.
