# N5 — Corta-Fio

**Sprint:** N · **Slot:** S06_J30 · **Tamanho:** M · **Depende de:** N1, H04, H06, H07, H08, F02, F03, F04, F05, F09, G05, G08, G10, G13, G14, G15

## Por quê

A sabotagem da seção. Cada um tem uma bomba no peito, e ela bipa **no alto-falante do próprio controle**: o estalo
seco é o fio errado; o bipe alto e claro é o fio certo, e o corte é na batida seguinte. Quem corta perfeito ganha um
bipe falso para mandar ao controle de quem está na frente: um bipe quase igual ao certo, uma quarta abaixo. O verbo
do alto-falante aqui é **desconfiar**: ouvir não basta, tem de ouvir **qual**. O falso vai sempre para quem está na
frente: o ambiente pesa na liderança, e ninguém é punido por estar atrás.

## Ler antes

- [A N1, «A cena»](N1-o-canto.md#a-cena) (o `CenarioDoCanto` inteiro: a capela, o `falante`, o `ouvir`, os ganchos, a `momento`)
- [O molde de minigame](molde-de-minigame.md) (a `sabotagem`, o `vencedor` e o `fim` em tempo)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s06/corta_fio.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S06_J30` em `MINIGAMES` e na lista da seção `S06` | **da seção** |
| `godot/scripts/traducoes.gd` | `"Corta-Fio": "Wire Cutter"`, `"Corte no bipe!": "Cut on the beep!"`, `"Corte!": "Cut!"`, `"Sem bipe falso": "No fake beeps"`, `"Corte": "Cut"`, `"Bipe falso": "Fake beep"`, `"%d bombas": "%d bombs"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_corta_fio()` e a linha `"S06_J30": await _prova_do_corta_fio()` no `match` do `_prova_da_ficha(slot)` (H08) | **de todos** |
| `scripts/importar_kenney.py` | a linha `platformer-kit` em `APROVADOS` (o `factory-kit` já está) | **de todos** |

O kit Kenney entra por `python3 scripts/importar_kenney.py platformer-kit` (ele escreve
`godot/assets/kenney/platformer-kit/`, o `LEIA-ME.md` e a `LICENCAS-DE-TERCEIROS.md`). O `.uid` de `corta_fio.gd` sai
de `"$GODOT" --headless --path godot --import --quit` e entra no commit.

O `cenario_do_canto.gd` é da N1: esta ficha **só chama**.

### O que muda de hoje

O Corta-Fio não existe hoje. O que muda da ficha antiga: `_notas` era declarada no minigame (agora é do kit, e o dado
da nota mora em `_info`); o robô contava o nível do alto-falante à mão (agora `CenarioDoCanto.ouvir`); a câmera era uma
pose solta (agora a da capela); as cores da bomba, dos fios e do confete eram hex (`#3a3a44`, `#ff4a2a`, `#e8b44c`,
`#6fd3c8`, `#c28bff`, `#e9e7f2`, `#4a4e5e`: agora a bomba Kenney, `TUNGSTENIO`, `ETIQUETA`, `OXIDO_BRILHO`, `MUDO` e a
cor do lugar); a bomba era uma caixa (agora o `bomb` do Platformer Kit); o chute `attack-kick-right` não existe (agora
`interact-right`); a sensação `explosao` vira `golpe`, sem gatilho; o `toque` em cada compasso sai (colidia com o
corte); o falso chega meia batida depois do bipe do alvo, em vez de trocar um estalo; o verbo vira «Corte no bipe!»;
o confete, o `caiu_no_falso`, o ensina e a reta são novos.

### O kit que esta ficha usa

```gdscript
presentes(); conectado(l); na_raia(l); raia(l); jogador(l); posicionar(l); marcar(l, pontos); anotar(tipo, l, campos)
nova_nota(l, n, t_alvo); notas_em_aberto(l); alvo_da(l, n); casar_toque(l); julgar_nota(l, n); nota_perdida(l, n); notas_perdidas(l)
andamento(); no_pico(); momento(nome, l, pos, altura_m, campos); aprendeu(l); var rng
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
var _notas := [{}, {}, {}, {}]  # do kit: não declare
CenarioDoCanto.montar(sala); pose_da_camera(); passar; exagero; so_o_dono
CenarioDoCanto.gancho(l, nome); antecedencia(l); queda(l, tempos); proxima_colcheia(folga_s)
CenarioDoCanto.falante(sala, l, som, ganho); tempo_forte(); soltar_a_musica(sala); ouvir(l, o); luz_da_nota(l, forca)
Tema.emissivo(material, energia, dono); Tema.JOGADOR[l]; Kit.peca(pai, kit, peca, pos, giro_y, escala); Kit.caixa(pai, tam, pos, mat)
```

No corte certo, o kit toca na TV `Som.tocar("nota", pos, -4 ou -9, TOM_DO_LUGAR[l])`: a sala ouve quem cortou. O
`nota_no_falante` vai a `false`: o alto-falante é só do bipe.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Corta-Fio (S06_J30) — a bomba no peito bipa no alto-falante do seu
## controle, na sua batida: o estalo ("clique") é o fio errado; o bipe claro
## ("pronto") é o fio certo: corte com ✕ na batida seguinte. Três fios certos
## desarmam a bomba, e vem outra. Cortar depois do estalo, ou depois do bipe
## falso, estoura a bomba em confete. Quem corta perfeito ganha um bipe falso
## (△) para mandar a quem está na frente.
##
## A falha: a bomba estoura em confete (os fios cortados daquela bomba voltam);
## o fio certo sem corte escapa (nada estoura).
## O vencedor: mais bombas desarmadas; depois mais fios; depois mais pontos.
## O alto-falante do dono: o bipe (o protagonista) e o falso.
## O registro mede: cada bipe (qual, se foi ao controle), o corte depois dele,
## a sabotagem e o momento `caiu_no_falso`.
## O robô: ouve o bipe no próprio alto-falante simulado e corta na batida
## seguinte se o que ouviu era o certo; quando não acerta, corta 250 ms tarde
## ou corta a armadilha. Manda o falso logo que ganha.
## Com menos de quatro: as batidas se dividem; sozinho, só as pares e sem falso.
## A régua: (1) «Corte no bipe!» com a bomba no peito e o alicate; (2) sim: o
## fio certo só se ouve; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J30",
	"titulo": "Corta-Fio",
	"verbo": "Corte no bipe!",
	"genero": "sabotagem",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ, Forja.TRIANGULO],
	"camera": "fixa",
	"faixa": "MUS_S06_J30",
	"duracao": 90.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Corte!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca nada nele (H08)
	"papel_som": Forja.PAPEL_ALTO_FALANTE,
}

const PONTOS := [0, 40, 70, 100]  ## o corte: ERRO, BOM, OTIMO, PERFEITO
const POR_BOMBA := 150
const FIOS_POR_BOMBA := 3
const CERTO := 0
const ERRADO := 1
const FALSO := 2
## O certo é o Sol6 (1568 Hz), o estalo é seco, o falso é o Ré6 (1175 Hz): uma quarta abaixo.
const BIPE := ["pronto", "clique", "nota_alta"]
const NOME := ["certo", "errado", "falso"]
## A chance de o bipe ser o certo, por terço (0–30 s, o pico 30–60 s, 60–90 s).
const CHANCE_CERTO := [0.55, 0.45, 0.6]
const ENSINA_CERTOS := 2  ## os dois primeiros bipes de cada um são o certo
const FALSOS_NA_FILA := 2  ## no máximo, por alvo
const COR_DO_FIO := [Tema.ETIQUETA, Tema.OXIDO_BRILHO, Tema.MUDO]
const PULSO_S := 0.12
const RETA_BATIDAS := 16
const ALTURA_DO_CAVALEIRO := 1.1
```

### O tempo

A faixa `MUS_S06_J30` tem 125 BPM: 1 batida = 0,48 s, 1 compasso = 1,92 s. Em 90 s, `_b_fim` = 187. O pico
(`no_pico()`) vai de 30 a 60 s (batidas 63 a 124). A reta são as batidas 171 a 186.

### O dono da batida

`lista = presentes()` em ordem, `k = lista.size()`: a batida `b` é de `lista[b % k]`; sozinho, só as batidas pares. O
compasso 0 é a contagem; o compasso `c` se gera quando `Ritmo.batida() >= 4c − 4`, e só agenda (lugar, batida): o tipo
do bipe se decide na hora de tocar.

### O bipe

Na hora (`Ritmo.t_musica() >= Ritmo.t_da_batida(b) - CenarioDoCanto.antecedencia(l)`), se o lugar não está sentado
(`Ritmo.batida() >= _sentado_ate[l]`):

1. **O tipo:** os `ENSINA_CERTOS` primeiros de cada lugar são `CERTO`; depois, `CERTO` com a chance do terço
   (`rng.randf() < CHANCE_CERTO[terço]`), senão `ERRADO`.
2. **O som:** `var foi := CenarioDoCanto.falante(self, l, BIPE[tipo], 0.9)` e
   `anotar("pista", l, {"n": int(round((b + 1) * 2)), "evento": "mandou", "canal": "alto_falante", "o_que": BIPE[tipo], "no_controle": foi, "tipo": NOME[tipo]})`.
3. **A luzinha da bomba** acende igual nos três (`Tema.emissivo(mat_luz, 1.2, "forja")` por 0,1 s, depois 0): a tela
   diz **quando** bipou, nunca **qual**.
4. **O corte:** o `CERTO` vira a nota de corte `n = int(round((b + 1) * 2))`,
   `_info[l][n] = {"b": b + 1, "tipo": CERTO}`, `nova_nota(l, n, Ritmo.t_da_batida(b + 1))`; o `ERRADO` e o `FALSO`
   viram a armadilha `{"b": b + 1, "t": Ritmo.t_da_batida(b + 1), "tipo": tipo, "de": remetente}` em `_armadilhas[l]`
   (não é nota do kit: nada de `nova_nota`).

**O pico:** a batida do dono tem dois bipes, em `b` e `b + 0,5`, cada um com o seu tipo e o seu corte em `b + 1` e
`b + 1,5`. Quem está com `Ritmo.simples[l]` fica com um.

**O falso pendente** (`_falsos[l]`, a fila dos remetentes, no máximo `FALSOS_NA_FILA`): no próximo bipe do lugar, o
falso chega meia batida depois dele, em `b + 0,5`, com o corte proibido em `b + 1,5`. No pico, ele toma o lugar do
segundo bipe. O falso toca `BIPE[FALSO]` e anota a `pista` com `"tipo": "falso"` e `"de": remetente + 1`.

### O corte (✕)

O alicate fecha (0,1 s). Entre a nota de corte em aberto mais perto (`casar_toque(l)`) e a armadilha mais perto a até
`Ritmo.JANELA_BOM` (0,14 s), vale a mais perto do agora:

- **a nota:** `_ultima[l] = _info[l][nn].merged({"cortou": true})` e `julgar_nota(l, nn)`. BOM ou melhor corta o fio
  (o `toque`); ERRO estoura (a `falha` com `cortou`);
- **a armadilha `ERRADO`:** estoura (o estouro comum) e `anotar("jogo", l, {"o": "armadilha", "tipo": "errado"})`;
- **a armadilha `FALSO`:** cai no falso (o momento, abaixo) e `anotar("jogo", l, {"o": "armadilha", "tipo": "falso", "de": de + 1})`;
- **nada perto:** o alicate fecha no ar.

O certo sem corte passa pelo `_passaram(l)` (o da N1): `nota_perdida`, e **o fio escapa** (a `falha` sem `cortou`): o
fio treme 1 batida e fica; nada estoura. A armadilha que passa de `JANELA_BOM` sai da lista.

**O fio cortado:** o fio `fios[l]` some (escala a 0 em 0,1 s) com 6 faíscas `Tema.TUNGSTENIO`; `fios[l] += 1`. No
terceiro: `bombas[l] += 1`, `fios[l] = 0`, `marcar(l, POR_BOMBA)`, `Som.tocar("sucesso", peito, -10.0)`, a bomba
desarmada vai para a fileira no chão, os três fios voltam, e o confete dele some (o rastro acaba).

### O bipe falso (△)

O corte PERFEITO dá carga: `carga[l] = 1` (na reta, `2`); sozinho, nunca. △ com carga e o alvo com a fila abaixo de
`FALSOS_NA_FILA` manda um falso **para quem está na frente**: `_na_frente(l)`, o primeiro do `vencedor()` que não seja
ele. Então: `_falsos[alvo].append(l)`, `carga[l] -= 1`, `Som.tocar("especial", Vector3(0, 2.0, -4.0), -10.0)` na TV
(todos ouvem que alguém sabotou; ninguém ouve quem), o cavaleiro de quem mandou faz `gesto("interact-right", 0.4)`, e
`anotar("entrada", l, {"o": "sabotagem", "para": alvo + 1})`. Com a fila do alvo cheia, o △ não sai e a carga fica.

### O estouro comum

Cortar depois do estalo, ou cortar o certo fora do tempo: `Som.tocar("golpe", peito, -8.0)`;
`Forja.sentir(l, "golpe")` (sem gatilho); `CenarioDoCanto.exagero(self, _cenario, "golpe", jogador(l))`; o confete de
24 tiras; `gesto("emote-no", 0.6)`; `fios[l] = 0` e os três fios voltam.

### Caiu no falso (o momento)

`_caiu_em[l] = CenarioDoCanto.proxima_colcheia(0.15)`. Na colcheia (`_bater(l)`):

- `Som.tocar("golpe", peito, -4.0)`;
- `Forja.sentir(l, "golpe")` (sem gatilho);
- `CenarioDoCanto.exagero(self, _cenario, "estrondo", jogador(l))` (tremor de 0,05 m por 2 batidas, hit-stop de 3
  quadros);
- `CenarioDoCanto.so_o_dono(self, l)`;
- o confete de 48 tiras;
- `jogador(l).gesto("sit", sentado_s)`, com `_sentado_ate[l] = _caiu_em[l] + CenarioDoCanto.queda(l, 2.0)` (1,5 a 2,5
  batidas): os bipes dele nesse tempo não tocam, e os falsos da fila esperam;
- `fios[l] = 0` e os três fios voltam;
- `momento("caiu_no_falso", l, Vector3(RAIAS[l], 0.0, Z_JOGADOR), ALTURA_DO_CAVALEIRO, {"de": de + 1, "lider": _na_frente(-1) == l})`.

**O confete** (`_confete(l, n)`): `n` tiras `Kit.caixa` de 0,05 × 0,22 × 0,008, do peito
(`(RAIAS[l], 0.9, Z_JOGADOR + 0.2)`). A cor da tira `i`: `i % 10` de 0 a 4 é `Tema.OXIDO_BRILHO`, 5 e 6 é
`Tema.ETIQUETA`, de 7 a 9 é `Tema.JOGADOR[l]` (`Kit.material(cor, 0.0, 0.9)`). A tira sobe 0,5 m em 0,2 s
(`EASE_OUT`) e cai em 0,4 s (`EASE_IN`) no chão da raia, em `(RAIAS[l] + 0.9 * sin(2.4 * i), 0.004, Z_JOGADOR + 0.8 * cos(1.7 * i))`,
girada `(1.3 * i, 2.1 * i, 0)` rad (sem `rng`: o confete não mexe na semente). As 8 primeiras vão para o cavaleiro: um
`BoneAttachment3D` no `torso`, em `(0.12 * sin(i), 0.15 + 0.05 * i, 0.16)`. O confete fica até a próxima bomba
desarmada dele.

### O pico

Na primeira batida com `no_pico()`: `Som.tocar("golpe", Vector3(0, 3.0, -6.0), -6.0)`, `Forja.sentir(l, "golpe")` em
todos com controle (sem gatilho), e o `CenarioDoCanto.passar` sobe a chave 20 % e recua a câmera 10 %. Com
`Opcoes.flashes`, a luz da capela faz o falso-contato: a chave cai a 50 % por 1 colcheia nas batidas 0, 1 e 2 desse
compasso; sem flashes, nada.

### A reta

Na batida 171, uma vez: `momento("reta", -1, Vector3(0, 0, Z_JOGADOR), 1.8, {"objeto": "bombas", "valores": ",".join(bombas)})`.
Até o fim, cada corte perfeito dá carga 2: dois falsos.

### O ensina

Os dois primeiros bipes de cada um são o certo: o som do certo se aprende antes do estalo. O primeiro falso que cada
um recebe chega com o fio do meio piscando na cor de quem mandou (`Tema.emissivo(mat_do_fio, 1.2, remetente)` por 1
batida, a partir do bipe): o ladrão se vê. Depois do primeiro, o fio não pisca mais, e a sala só sabe pelo confete.

### O fim e o vencedor

`fim` `tempo`: 90 s de música, pelo kit (H08).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(bombas[a]) != int(bombas[b]):
			return int(bombas[a]) > int(bombas[b])
		if int(fios[a]) != int(fios[b]):
			return int(fios[a]) > int(fios[b])
		if int(pontos[a]) != int(pontos[b]):
			return int(pontos[a]) > int(pontos[b])
		return a < b)
	return lista


## Quem está na frente, sem `fora` (−1: ninguém de fora).
func _na_frente(fora: int) -> int:
	for l in vencedor():
		if l != fora:
			return l
	return -1
```

### Com menos de quatro

- **Três e dois:** a roda do dono (`b % k`); o falso vai para quem está na frente.
- **Um:** só as batidas pares, sem carga nem falso. `com_poucos()` devolve `"Sem bipe falso"`.
- **O controle que cai:** os bipes dele não tocam, as notas saem caladas (`notas_perdidas(l)`) e as armadilhas somem;
  a fila de falsos e a carga dele ficam.

### Os ganchos

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

```gdscript
var _info := [{}, {}, {}, {}]  ## lugar -> {n: {b, tipo}}
var _armadilhas := [[], [], [], []]  ## {b, t, tipo, de}
var _agenda: Array = []  ## {l, b}: os bipes a tocar
var _ultima := [{}, {}, {}, {}]
var _gerado := 1
var _compasso := 0
var _b_fim := 0
var _fora := [false, false, false, false]
var fios := [0, 0, 0, 0]
var bombas := [0, 0, 0, 0]
var carga := [0, 0, 0, 0]
var _falsos := [[], [], [], []]  ## lugar -> [remetente, ...]
var _bipes_tocados := [0, 0, 0, 0]
var _ensinou_falso := [false, false, false, false]
var _caiu_em := [-1.0, -1.0, -1.0, -1.0]
var _caiu_de := [-1, -1, -1, -1]
var _sentado_ate := [-1.0, -1.0, -1.0, -1.0]
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _confetes := [[], [], [], []]
var _bomba := [{}, {}, {}, {}]  ## lugar -> {presa, luz, fios: [MeshInstance3D] × 3, alicate}
var _pico_tocou := false
var _reta_anotada := false
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoCanto.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoCanto.montar(self)
	_b_fim = int(floor(duracao * Ritmo.bpm / 60.0))
	_montar_o_fundo()  # os canos e a alavanca
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = 0.0
		p.preso = true
		_bomba[l] = _montar_a_bomba_e_o_alicate(l, p)
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	for l in presentes():
		CenarioDoCanto.luz_da_nota(l, 1.0)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
	while _gerado <= c + 1:
		_gerar_compasso(_gerado)  # agenda os bipes de cada dono
		_gerado += 1
	CenarioDoCanto.passar(self, _cenario, no_pico())
	_tocar_os_bipes()  # o tipo, o falso da fila, o falante, a pista, a luzinha, a nota ou a armadilha
	_pico_no_tempo()
	_reta_no_tempo()
	var agora := Ritmo.t_musica()
	for l in presentes():
		_apagar_o_pulso(l, dt)
		_caiu_no_tempo(l)  # o _bater do caiu_no_falso
		if not conectado(l):
			if not _fora[l]:
				_fora[l] = true
				notas_perdidas(l)
				_armadilhas[l] = []
			continue
		_fora[l] = false
		if Forja.apertou(l, Forja.CRUZ):
			_cortar(l)
		if Forja.apertou(l, Forja.TRIANGULO) and int(carga[l]) > 0:
			_sabotar(l)
		_passaram(l)
		_armadilhas[l] = _armadilhas[l].filter(func(a): return agora <= float(a.t) + Ritmo.JANELA_BOM)


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	_cortar_o_fio(l)  # o fio, a bomba desarmada, a fileira, o confete que some
	if julgamento == Ritmo.PERFEITO and presentes().size() > 1:
		carga[l] = 2 if Ritmo.batida() >= _b_fim - RETA_BATIDAS else maxi(int(carga[l]), 1)
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S


func falha(l: int) -> void:
	var nt: Dictionary = _ultima[l]
	_ultima[l] = {}
	if bool(nt.get("cortou", false)):
		_estourar(l)  # cortou o certo fora do tempo
	else:
		_fio_escapa(l)


func status(l: int) -> String:
	return "%d bombas" % int(bombas[l]) if na_raia(l) else super(l)


func dica(l: int) -> Dictionary:
	if not na_raia(l):
		return {}
	var partes := ["@cross", "Corte"]
	if int(carga[l]) > 0:
		partes += ["@triangle", "Bipe falso"]
	return {"partes": partes, "pos": Vector3(RAIAS[l], 2.4, Z_JOGADOR)}


func com_poucos() -> String:
	return "Sem bipe falso" if presentes().size() == 1 else ""


func _exit_tree() -> void:
	CenarioDoCanto.soltar_a_musica(self)
```

`_cortar(l)` faz «O corte». `_sabotar(l)` faz «O bipe falso». `_estourar(l)` faz «O estouro comum». `_cair(l, de)`
marca `_caiu_em` e `_caiu_de`; `_caiu_no_tempo(l)` faz «Caiu no falso» na colcheia. `_gerar_compasso(c)`,
`_tocar_os_bipes()`, `_pico_no_tempo()`, `_reta_no_tempo()`, `_cortar_o_fio(l)`, `_fio_escapa(l)`, `_confete(l, n)`,
`_apagar_o_pulso(l, dt)`, `_montar_o_fundo()` e `_montar_a_bomba_e_o_alicate(l, p)` fazem o que as partes desta ficha
dizem. `_passaram(l)` é o da N1. A dica perde as palavras quando o lugar `aprendeu` (fica só o glifo: o painel faz).

O catálogo: `Catalogo.MINIGAMES["S06_J30"] = preload("res://scripts/minigames/s06/corta_fio.gd")` e `"S06_J30"` na
lista da seção `S06`.

## A cena

### A câmera

A da capela (N1): `CenarioDoCanto.pose_da_camera()`, a câmera em `(0, 14,99, 10,07)` olhando `(0, 1,2, −1,5)`, 35 mm,
plongée de 50°, modo `fixa`, sem corte. A bomba no peito (0,30 m) fica a 0,9 m do chão, de frente para a câmera. No
pico, `pose_da_camera(1.1)`. O tremor é só o do `exagero`.

### A luz da seção

A da N1, com o pórtico: `CenarioDoCanto.montar(self)`: a névoa `#050d26` (o main), o preenchimento `#1f346a` a 0,2, a
chave `#e5d3c6` a 0,47, as tochas `Tema.TUNGSTENIO` a 0,9, o sino grande no foco.

- **O pico:** a chave +20 % em 1 batida (sem flashes, +10 % em 2), e o falso-contato só com flashes.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `wall` | `Kit.arena(sala, 5, 3)` | o chão e as paredes |
| o pórtico, o sino grande e as torres | `CenarioDoCanto.montar(self)` (N1) | a capela |
| `factory-kit/pipe-large-long` (escala 4: 4 × 2 × 2 m; o pacote já é 0,5) | `(-4.6, 0, -6.6)` e `(4.6, 0, -6.6)` | os canos do paiol, no fundo |
| `platformer-kit/lever` (escala 2: 1,2 × 1,28 m) | `(-4.6, 0, -4.4)` | a alavanca do detonador |
| `platformer-kit/bomb` (escala 0,6: 0,30 × 0,33 m) | no peito, num `BoneAttachment3D` do `torso`, em `(0, 0.1, 0.2)` | a bomba de cada um |
| `platformer-kit/bomb` (escala 0,5: 0,25 m) | a fileira das desarmadas: `(RAIAS[l] - 0.75 + 0.3 * (i % 6), 0, Z_JOGADOR - 1.0 - 0.3 * (i / 6))`, até 12 | o placar no mundo |

O que não é peça Kenney (caixas do `Kit`; `metallic` 0):

| objeto | forma | material |
| --- | --- | --- |
| a luzinha da bomba | cubo de 0,05 em `(0.08, 0.36, 0.26)` da bomba | `Kit.material(Tema.TUNGSTENIO, 0.0, 0.6, "forja")`; no bipe, `Tema.emissivo(mat, 1.2, "forja")` por 0,1 s |
| o fio `k` (3) | caixa 0,28 × 0,03 × 0,03 em `(0, 0.16 - 0.06 * k, 0.36)` da bomba | `Kit.material(COR_DO_FIO[k], 0.0, 0.8)` |
| o alicate | duas caixas 0,04 × 0,22 × 0,04 num `BoneAttachment3D` de `arm-right`, que fecham (rotação 0,4) no ✕ | `Kit.material(Tema.GRAFITE, 0.0, 0.7)` |
| a tira de confete | caixa 0,05 × 0,22 × 0,008 | `OXIDO_BRILHO`, `ETIQUETA` ou `Tema.JOGADOR[l]` |

Passou de 12 bombas, a fileira fica com 12 e o `status` conta.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a luzinha da bomba, no bipe | a forja | 1,2 por 0,1 s |
| o fio do meio no primeiro falso | quem mandou | 1,2 por 1 batida |
| as faíscas do fio cortado | a forja | `Tema.TUNGSTENIO`, 6 |
| as tochas e o foco do sino | a forja | luz `Tema.TUNGSTENIO` |

Nenhuma cor fora dos tokens. O confete não brilha.

### A montagem

- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = 0.0` (de frente), `preso = true`, a bomba com a luzinha e os
  três fios no peito, o alicate na mão direita.
- `_montar_o_fundo()`: os dois canos e a alavanca.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o bipe certo | — (sem alto-falante: `nota_alta` −10 dB, tom 1,3348, na raia) | `"pronto"`, 0,9 | `mod_pronto`; `sint_nota_alta` |
| o estalo | — (sem alto-falante: `tique` −10 dB na raia) | `"clique"`, 0,9 | `mod_clique`; `tique_0..2` |
| o bipe falso | — (sem alto-falante: `nota_alta` −10 dB na raia) | `"nota_alta"`, 0,9 | `mod_nota_alta`; `sint_nota_alta` |
| o corte certo | a nota do lugar, −4 ou −9 dB, `TOM_DO_LUGAR[l]` (o kit) | — | `sint_nota` |
| o fio que escapa | a falha do kit (−6) | — | `falha_0..2` |
| a bomba desarmada | `Som.tocar("sucesso", peito, -10.0)` | — | `vitoria_sala_0..1` (reserva `sint_sucesso`) |
| a sabotagem | `Som.tocar("especial", Vector3(0, 2.0, -4.0), -10.0)` | — | `especial_0..` |
| o estouro comum | `Som.tocar("golpe", peito, -8.0)` | — | `golpe_0..4` |
| caiu no falso | `Som.tocar("golpe", peito, -4.0)` | — | `golpe_0..4` |
| o pico | `Som.tocar("golpe", Vector3(0, 3.0, -6.0), -6.0)` | — | `golpe_0..4` |
| o tempo forte | `Som.tocar("sino", SINO_TV, -16)` | — | `sint_sino` |
| a faixa | `MUS_S06_J30`: 125 BPM, Lá menor, 150 s (toca 90); até ela existir, `sint_trilha` | — | `mus_s06_j30` |

- **A música abaixa na pista** (−12 dB por 1 batida, volta em 300 ms): cada bipe a abaixa.
- **Um som por vez no controle** (H07): no pico, o segundo bipe vem 0,24 s depois do primeiro e o corta; o `pronto`
  (0,5 s) se reconhece no ataque.
- O material `"metal"`: a textura do acerto na háptica (o kit).

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| o bipe (os três) | só o dono | — | — | — (nunca: entregaria qual) | `pronto`, `clique` ou `nota_alta`, 0,9 |
| o corte BOM ou ÓTIMO | o dono | `acerto` (0,3 / 0,6, 80 ms; o kit) | — | 60 % por 0,12 s, volta a 100 % | — |
| o corte PERFEITO | o dono | `perfeito` (0,5 / 0,8, 100 ms; o kit) | — | o kit: branco 0,15 s | — |
| o fio que escapa | o dono | `erro` (0,7 / 0,3, 160 ms; o kit) | — | o kit: escurecida 0,5 s | — |
| o estouro e o caiu no falso | o dono | `golpe` (1,0 / 0,6, 250 ms) | — | — (a bomba é do mundo) | — |
| o pico | todos | `golpe` | — | — | — |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar | — |

Fora da bancada, nunca pergunta.

### O robô

```gdscript
# O robô ouve o bipe no próprio alto-falante simulado (CenarioDoCanto.ouvir).
# O certo: corta na batida seguinte; quando não acerta, 250 ms tarde (o fio
# escapa). O estalo: não corta; quando não acerta, corta (estoura). O falso é
# quase o certo: o robô só o reconhece se acertar duas vezes seguidas; senão,
# corta (cai no falso). Manda o falso logo que ganha a carga.
var _ouvido := [{}, {}, {}, {}]
var _robo_cortes := [[], [], [], []]  ## os instantes de ✕, em ordem


func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var a := CenarioDoCanto.ouvir(l, _ouvido[l])
	if not a.is_empty() and BIPE.has(str(a.som)):
		var tipo := BIPE.find(str(a.som))
		var corte := float(a.t) + CenarioDoCanto.antecedencia(l) + 60.0 / Ritmo.bpm
		var acerta := Forja.robo_acerta()
		if tipo == FALSO:
			acerta = acerta and Forja.robo_acerta()
		if tipo == CERTO:
			_robo_cortes[l].append(corte if acerta else corte + 0.25)
		elif not acerta:
			_robo_cortes[l].append(corte)
		_robo_cortes[l].sort()
	if not _robo_cortes[l].is_empty() and Ritmo.t_musica() >= float(_robo_cortes[l][0]):
		_robo_cortes[l].pop_front()
		Forja.robo_apertar(l, Forja.CRUZ, 0.06)
	if int(carga[l]) > 0:
		Forja.robo_apertar(l, Forja.TRIANGULO, 0.06)
```

O `t` do `ouvir` é quando o jogo mandou o bipe (`t_da_batida(b)` menos a antecedência): o corte é uma batida depois de
`t_da_batida(b)`. No pico, os dois bipes ficam a 0,24 s: o `ouvir` (0,1 s) não os junta. O robô nunca lê o tipo do
bipe no minigame: só o que ouviu.

## O cavaleiro

O cavaleiro da montagem (G13), de frente, com a bomba no peito e o alicate na mão direita. A cabeça e a parte de baixo
aparecem como estão; a parte de cima fica meio coberta pela bomba (0,30 m no peito). Ele pode ser de outra raça
(G08, parte B; a montagem é da G13): esta ficha usa o esqueleto comum de 7 ossos (a bomba e o confete vão no `torso`, o alicate no `arm-right`) e
as animações `idle`, `emote-no`, `sit` e `interact-right`. O conferidor da G08 não exige o `sit`: num corpo sem ele, o
`gesto("sit", ...)` não faz nada (`player.gd:185`) e o cavaleiro fica de pé no confete o tempo do sentado. Isso é
aceito; o corte segue parado pelo `_sentado_ate`.

| stat | gancho | o que muda no Corta-Fio | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: nada empurra | — | — | — |
| Passo | `velocidade` | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | quanto tempo ele fica sentado depois de cair no falso (`queda(l, 2)`) | 2,5 batidas | 2 | 1,5 |
| Faro | `pista` | o bipe sai antes; o corte fica no tempo | 40 ms depois | no tempo | 40 ms antes |
| Faro | `raio` | não age | — | — | — |

Os itens: o Escudo absorve o primeiro erro (o kit: o primeiro fio que escapa não conta); a Âncora não age; a Lanterna
adianta o bipe meio tempo (0,24 s a 125 BPM); o Martelo dobra o perfeito no tempo forte (o kit); o Diapasão aumenta o
ganho da nota do corte (1,3). Nenhum stat muda a janela de julgamento.

O erro não tem squash. O desregistro do erro é do kit e da G08.

## As reações

- **Carimbos que o Corta-Fio pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do
  mesmo lugar). O `car_acorde` não sai: a roda do dono nunca põe dois cortes no mesmo tempo. O `car_por_um_fio` e o
  `car_virada` são do placar (G07): o Corta-Fio não os chama.
- **Adesivos:** ninguém está fora da rodada; ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: caiu no falso** (`caiu_no_falso`). Quem corta perfeito manda um bipe falso para o controle de quem está
na frente. Ele corta no falso, e a bomba no peito estoura em confete; ele cai sentado, coberto. Degrau estrondo
(tremor de 0,05 m por 2 batidas, hit-stop de 3 quadros).

- **Rastro:** o confete fica no cavaleiro e no chão da raia até ele desarmar a próxima bomba.
- **A curva:** de 0 a 30 s, um bipe por vez, 55 % certos; de 30 a 60 s, dois bipes por vez, 45 % certos; de 60 s ao
  fim, um por vez, 60 % certos, e nas últimas 16 batidas cada perfeito manda 2 falsos.
- **Ensina sem falar:** os dois primeiros bipes são o certo; o primeiro falso de cada um chega com o fio piscando na
  cor de quem mandou.
- **Quem está perdendo:** o falso vai sempre para quem está na frente. Quem está atrás nunca recebe um.
- **A nota de hoje:** 4. O fio que pisca no primeiro falso conta à sala que o falso existe.

**Como o jogador do time confere.** A mesa padrão (P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 (o primeiro corte cai entre 2,4 e 3,8 s: os dois primeiros bipes são o certo) | o quadro de 10 s mostra um fio a menos numa bomba |
| 4. o momento | pelo menos 3 linhas `momento` `caiu_no_falso` em 90 s, pelo menos 2 com `lider` true | confete numa raia em 1 quadro em 4 |
| 5. a curva | as linhas `pista` por segundo no 2.º terço ≥ 1,5 × as do 1.º (dá 2,0 ×); no 3.º ≥ 1,0 × (dá 1,0 ×); a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a luz 20 % acima do do 1.º |
| 6. a falha | o P4 tem pelo menos 5 linhas `jogo` `armadilha` | 1 quadro em 5 mostra confete |
| 7. quem perde joga | a maior distância entre duas linhas `pista` seguidas de cada lugar é de até 8 batidas (4 na roda, mais o tempo sentado); o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `caiu_no_falso` tem 0,05 ≤ `x_tela` ≤ 0,95 e `altura_tela` ≥ 0,08 | a raia inteira se vê no quadro de 480 × 270 |
| 9. o impacto | para cada `caiu_no_falso`, uma linha `sensacao` `golpe` a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte mostra o cavaleiro sentado no confete |
| 10. o placar no mundo | as bombas do `momento` `reta` batem com o `bombas` do registro naquele tempo | no quadro de 85 s, quem olha conta as bombas na fileira de cada um, e a conta bate com o registro |

O `x_tela` vai de 0,05 a 0,95: o momento cai na raia de quem caiu, e as raias de fora (x ±6) ficam em 0,20 e 0,80
nesta câmera. A `prova_do_jogo.sh` roda o `bom` nos quatro (`--robo --semente=7`, sem repassar argumentos), e o `bom`
quase nunca corta o falso. A prova faz a mesa média por cima dele: 50 ms antes de cada falso, corta com 30 % de chance,
pela semente 7 (em «Provas»). Com ela, a prova confere os itens 1, 4, 5, 8, 9 e 10 (o líder também cai). Os itens 6 e
7 esperam o robô por lugar (`--robo=bom,medio,medio,ruim`), que a F09 não faz.

## Pronto quando

O Corta-Fio joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o `ruim` estoura);
aguenta o cabo que cai e volta; fecha com o vencedor de mais bombas; o falso cai pelo menos 3 vezes, 2 no líder; a
prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `SALA=S06_J30 bash tests/prova_do_jogo.sh` (a prova do Corta-Fio, sem e com `--bancada`),
`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a função abaixo, chamada pela linha
`"S06_J30": await _prova_do_corta_fio()` no `match` do `_prova_da_ficha(slot)` da H08. Ela reaproveita
o `_mesa_rng`, o `_mesa_vistas` e o `_mesa_comeca()` da mesa da prova da N1; a chave da armadilha vista é o `b` dela.

```gdscript
## Corta-Fio (S06_J30): os bipes chegam ao alto-falante simulado, os três
## tipos no registro, o falso nunca vai para quem mandou, e caiu no falso é o
## momento.
func _prova_do_corta_fio() -> void:
	var tocou := [false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.3:
				tocou[0] = true
			if not mg.conectado(l):
				continue
			for a in mg._armadilhas[l]:
				if int(a.tipo) != mg.FALSO or _mesa_vistas[l].has(float(a.b)) or Ritmo.t_musica() < float(a.t) - 0.05:
					continue
				_mesa_vistas[l][float(a.b)] = true
				if _mesa_rng.randf() < 0.3:  # a mesa média: corta o falso
					Forja.robo_apertar(l, Forja.CRUZ, 0.06)
	_mesa_comeca()
	var mg = await _joga_o_minigame("S06_J30", 130.0, olhar)
	if mg == null:
		return
	_esperar(tocou[0], "Corta-Fio: o bipe saiu de um alto-falante simulado")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S06_J30")
	var bipes := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("evento") == "mandou")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	var tipos := {}
	for e in bipes:
		tipos[str(e.get("tipo", ""))] = true
	_esperar(tipos.has("certo") and tipos.has("errado"), "Corta-Fio: bipes certos e errados (%s)" % [tipos.keys()])
	var sabotagens := linhas.filter(func(e): return e.get("tipo") == "entrada" and e.get("o") == "sabotagem")
	_esperar(sabotagens.all(func(e): return int(e.get("para", 0)) != int(e.get("jogador", -1))), "Corta-Fio: o falso nunca volta para quem mandou")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.bombas[v[0]]) == v.map(func(l): return int(mg.bombas[l])).max(), "Corta-Fio: vence quem desarmou mais")
	for l in mg.presentes():
		_esperar(toques.any(func(e): return int(e.get("jogador", 0)) == l + 1 and float(e.get("t_musica", 99.0)) <= 10.0), "Corta-Fio: o P%d cortou até 10 s" % (l + 1))
	var caidas := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "caiu_no_falso")
	for a in caidas:
		_esperar(float(a.get("x_tela", 0.0)) >= 0.05 and float(a.get("x_tela", 0.0)) <= 0.95 \
			and float(a.get("altura_tela", 0.0)) >= 0.08, "Corta-Fio: caiu no falso na tela (%s)" % [a])
	if mg.presentes().size() == 4:  # a mesa média da prova
		_esperar(caidas.size() >= 3, "Corta-Fio: %d caíram no falso (o mínimo é 3)" % caidas.size())
		_esperar(caidas.filter(func(e): return bool(e.get("lider", false))).size() >= 2, "Corta-Fio: o líder caiu no falso pelo menos 2 vezes")
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("slot", "") == "S06_J30").is_empty(), "Corta-Fio: fora da bancada, nenhuma pergunta")
```

### O que o registro mede

- `som_controle` (H07) de cada bipe; a `pista` (`canal` `alto_falante`) com o `tipo` (certo, errado, falso) e
  `no_controle`; a `troca` de quem não tem alto-falante.
- O `toque` do kit no corte certo (e o perdido: o fio que escapou); o `jogo` `armadilha`; a `entrada` `sabotagem`.
- O cruzamento: com `placa`, cortar o certo e deixar o estalo é o ouvido que distingue; cortar tudo ou nada, sempre
  num controle, é o alto-falante que não chegou (o jogador chuta).
- A `sensacao` `golpe` e o `momento` `caiu_no_falso`; o `momento` `reta`.

### As pranchas que o jogador do time olha

A prancha da prova visual (480 × 270, um quadro a cada 2 s): o quadro de 10 s (um fio a menos), os quadros com confete
(caiu no falso ou o estouro) e o seguinte (sentado), e o de 85 s (as bombas contadas). O `Catalogo.sortear` da H08 põe
o `S06_J30` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`.

### O que o André joga e sente

`./run-local.sh -- --sala=S06_J30`, com quatro DualSense, dois no cabo e dois no rádio:

- o estalo e o bipe claro se distinguem na mão, com a música;
- o falso engana na primeira vez e dá para aprender a ouvir a diferença (uma quarta abaixo);
- a sabotagem faz a sala gritar (o `especial` na TV) sem dizer quem foi;
- o confete é engraçado; ninguém sai do jogo.

### Armadilhas

- **A tela nunca diz qual bipe:** a luzinha da bomba pisca igual nos três; a barra de luz só pulsa no corte. O fio
  que pisca no primeiro falso é a única exceção, e é de propósito.
- **A armadilha não é nota do kit:** nada de `nova_nota` nem `julgar_nota` para ela; o estouro é da própria ficha.
- **O falso vai para quem está na frente**, nunca para quem mandou; com um jogador, não existe.
- **O confete não usa o `rng`:** a semente fica só para o jogo.
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_nota` (H08); marque cru.
- **`_notas` é do kit.** O dado da nota mora em `_info`.
- **A música:** o `_exit_tree` chama `soltar_a_musica`.

### Ao terminar

- No [quadro](README.md): a linha **N5**, com o commit (`feito (<commit>)`). Com as cinco feitas, a linha **N** da
  seção também vira **feito**.
- Commit sugerido (sem trailer): `feat: Corta-Fio no kit, o bipe certo, o estalo e o falso, cada um no seu controle`
