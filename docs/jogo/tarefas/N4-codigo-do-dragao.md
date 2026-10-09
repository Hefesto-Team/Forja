# N4 — Código do Dragão

**Sprint:** N · **Slot:** S06_J29 · **Tamanho:** M · **Depende de:** N1, H04, H06, H07, H08, F02, F03, F04, F05, F09, G05, G08, G10, G13, G14, G15

## Por quê

A memória da seção. O dragão sussurra uma senha no controle de cada um: a de cada um é diferente, e ninguém mais ouve
a sua. Repetida inteira, ela cresce uma nota; errada, o dragão cospe fumaça, e a senha recomeça em três. É o «Simon»
do alto-falante, com a pista privada. O verbo é **decorar**: a resposta não vem logo depois de cada nota (como no
Eco) nem copia uma frase curta (como n'O Canto). É a sequência inteira, de cabeça. A resposta toca na TV, e a fumaça
grande conta a todos que alguém foi longe.

## Ler antes

- [A N1, «A cena»](N1-o-canto.md#a-cena) (o `CenarioDoCanto` inteiro: a capela, o `falante`, o `ouvir`, os ganchos, a `momento`)
- [O molde de minigame](molde-de-minigame.md) (o `tct`, o `vencedor` e o `fim` em tempo)
- [O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s06/codigo_do_dragao.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/catalogo.gd` | `S06_J29` em `MINIGAMES` e na lista da seção `S06` | **da seção** |
| `godot/scripts/traducoes.gd` | `"Código do Dragão": "Dragon's Code"`, `"Decore!": "Memorize!"`, `"Grave": "Low"`, `"Média": "Middle"`, `"Aguda": "High"`, `"Senha %d": "Code %d"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_dragao()` e a linha `"S06_J29": await _prova_do_dragao()` no `match` do `_prova_da_ficha(slot)` (H08) | **de todos** |
| `scripts/importar_kenney.py` | as linhas `modular-dungeon-kit` e `hexagon-kit` em `APROVADOS` | **de todos** |

Os dois kits Kenney entram por `python3 scripts/importar_kenney.py modular-dungeon-kit hexagon-kit` (ele escreve
`godot/assets/kenney/<kit>/`, o `LEIA-ME.md` e a `LICENCAS-DE-TERCEIROS.md`). O `.uid` de `codigo_do_dragao.gd` sai
de `"$GODOT" --headless --path godot --import --quit` e entra no commit.

O `cenario_do_canto.gd` é da N1: esta ficha **só chama**.

### O que muda de hoje

O Código não existe hoje. O que muda da ficha antiga: `_notas` era declarada no minigame (agora é do kit, e o dado da
nota mora em `_info`); o robô contava o nível do alto-falante à mão (agora `CenarioDoCanto.ouvir`); a resposta casava
o toque à mão (agora `casar_toque` e `julgar_nota`); a câmera era uma pose solta (agora a da capela, com o olhar mais
alto); as cores do dragão e da fumaça eram hex (`#5e5870`, `#ff4a2a`, `#9a9eb8`: agora `GRAFITE`, `JANELA`, o
`TUNGSTENIO` da forja e o `MUDO`); os olhos iam a 3,0 no rugido (agora o teto do néon, 1,2); o `toque` em cada compasso
sai (colidia com a nota da resposta no tempo 1); a fumaça grande, a fuligem, o ensina e a reta são novos.

### O kit que esta ficha usa

```gdscript
presentes(); conectado(l); na_raia(l); raia(l); jogador(l); posicionar(l); marcar(l, pontos); anotar(tipo, l, campos)
nova_nota(l, n, t_alvo); notas_em_aberto(l); alvo_da(l, n); casar_toque(l); julgar_nota(l, n); nota_perdida(l, n); notas_perdidas(l)
andamento(); no_pico(); momento(nome, l, pos, altura_m, campos); aprendeu(l); var rng
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
var _notas := [{}, {}, {}, {}]  # do kit: não declare
CenarioDoCanto.montar(sala, 1.0, false); pose_da_camera(recuo, olhar); passar; exagero; so_o_dono; suporte(sala, l); balancar(s, forca)
CenarioDoCanto.gancho(l, nome); antecedencia(l); queda(l, tempos); proxima_colcheia(folga_s)
CenarioDoCanto.falante(sala, l, som, ganho); tempo_forte(); soltar_a_musica(sala); ouvir(l, o); luz_da_nota(l, forca)
Tema.emissivo(material, energia, dono); Tema.JOGADOR[l]; Kit.peca(pai, kit, peca, pos, giro_y, escala); Kit.caixa(pai, tam, pos, mat)
```

No acerto, o kit toca na TV `Som.tocar("nota", pos, -4 ou -9, TOM_DO_LUGAR[l])`: a resposta de cada um se ouve na
sala. O `nota_no_falante` vai a `false`: o alto-falante é só da senha.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## Código do Dragão (S06_J29) — o dragão canta uma senha no alto-falante do
## controle de cada um, uma nota por batida: grave (✕), média (○) ou aguda
## (△). Depois do silêncio, repita a senha inteira, uma nota por batida.
## Inteira e no tempo, ela cresce uma nota (até doze). Errou, o dragão cospe
## fumaça e a senha recomeça em três, nova. No pico, o dragão canta em
## colcheias (a resposta continua nas batidas).
##
## A falha: a fumaça do tamanho da senha perdida; de 7 notas para cima, a
## fumaça grande cobre o cavaleiro, e ele fica com fuligem.
## O vencedor: a senha mais longa repetida inteira; no empate, mais pontos.
## O alto-falante do dono: a senha (a protagonista).
## O registro mede: cada nota da senha (o som, se foi ao controle), a
## resposta dela (o toque do kit com o mesmo n), o fim de cada ciclo e o
## momento `fumaca_grande`.
## O robô: ouve as notas da senha no próprio alto-falante simulado e repete
## no tempo só as que ouviu, na altura que ouviu; quando não acerta, 250 ms tarde.
## Com menos de quatro: nada muda (cada um tem a sua senha e o seu tempo).
## A régua: (1) «Decore!» com o dragão olhando para cada um; (2) sim: a senha
## só existe no controle; (3) não pergunta nada.

const FICHA := {
	"slot": "S06_J29",
	"titulo": "Código do Dragão",
	"verbo": "Decore!",
	"genero": "tct",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ, Forja.CIRCULO, Forja.TRIANGULO],
	"camera": "fixa",
	"faixa": "MUS_S06_J29",
	"duracao": 100.0,
	"fim": "tempo",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "pedra",
	"microjogo": {"verbo": "Decore!", "segundos": 6.0},
	"nota_no_falante": false,  # o alto-falante é a pista: o kit não toca nada nele (H08)
	"papel_som": Forja.PAPEL_ALTO_FALANTE,
}

const PONTOS := [0, 10, 20, 30]  ## por nota da resposta: ERRO, BOM, OTIMO, PERFEITO
const POR_NOTA_DA_SENHA := 20  ## a senha inteira vale isto vezes o comprimento (o dobro na reta)
const INICIO := 3
const MAXIMO := 12
const GRANDE := 7  ## a senha perdida de 7 ou mais solta a fumaça grande
## As três alturas: Dó5 (523 Hz), Sol5 (784 Hz), Ré6 (1175 Hz).
const SOM := ["nota:0", "nota", "nota_alta"]
const BOTAO := [Forja.CRUZ, Forja.CIRCULO, Forja.TRIANGULO]
const GLIFO := ["cross", "circle", "triangle"]
const PIVO := Vector3(0.0, 1.6, -5.6)  ## o pescoço do dragão
const OLHAR := Vector3(0.0, 1.8, -2.0)
const PEDRA := 0.14  ## o lado da pedrinha do placar
const PEDRA_Z := -1.0  ## atrás do cavaleiro: Z_JOGADOR − 1,0
const PULSO_S := 0.12
const RETA_BATIDAS := 16
const ALTURA_DO_CAVALEIRO := 1.1
```

### O tempo

A faixa `MUS_S06_J29` tem 140 BPM: 1 batida = 0,429 s, 1 compasso = 1,71 s. Em 100 s, `_b_fim` = 233. O pico
(`no_pico()`, o terço do meio) vai de 33,3 a 66,7 s (batidas 78 a 155). A reta são as batidas 217 a 232.

### O ciclo de cada um

**Cada um tem o seu ciclo**, todos no mesmo relógio, e ninguém espera o outro. O primeiro começa na batida `S = 4`
(depois da contagem). Com `L = senha[l].size()` (começa em `INICIO`) e `p` = 0,5 se a batida `S` cai no pico e o
lugar não está com `Ritmo.simples[l]`, senão 1:

1. **A senha canta:** a nota `i` (de 0 a `L − 1`) na batida `S + i·p`, em
   `Ritmo.t_da_batida(S + i·p) − CenarioDoCanto.antecedencia(l)`:
   `var foi := CenarioDoCanto.falante(self, l, SOM[senha[l][i]], 0.9)` e
   `anotar("pista", l, {"n": <o n da resposta i>, "evento": "mandou", "canal": "alto_falante", "o_que": SOM[senha[l][i]], "no_controle": foi})`.
2. **O silêncio:** a resposta começa em `A = ceilf(S + L·p) + 1` fora do pico (uma batida inteira de silêncio) e
   `A = ceilf(S + L·0,5)` no pico (de meia a uma batida).
3. **A resposta:** `L` notas nas batidas `A + i`: `n = int(round((A + i) * 2))`,
   `_info[l][n] = {"i": i, "altura": senha[l][i], "b": A + i}` e `nova_nota(l, n, Ritmo.t_da_batida(A + i))`, todas
   quando o ciclo começa. O botão da altura (✕ grave, ○ média, △ aguda): `var nn := casar_toque(l)`; com `nn >= 0`,
   `_ultima[l] = _info[l][nn]`; a altura certa → `julgar_nota(l, nn)`; a errada → `nota_perdida(l, nn)`. A nota que
   passa: `nota_perdida` pelo `_passaram(l)` (o da N1).
4. **A senha inteira** (a última nota resolvida, nenhuma falha): `recorde[l] = maxi(recorde[l], L)`;
   `marcar(l, POR_NOTA_DA_SENHA * L)` (× 2 na reta); `Som.tocar("confirma", Vector3(RAIAS[l], 1.5, Z_JOGADOR), -6.0)`;
   a fuligem sai; `anotar("senha", l, {"L": L, "inteira": true})`. A senha ganha uma nota sorteada no fim
   (`rng.randi_range(0, 2)`). Em `MAXIMO`, ela recomeça em `INICIO`, nova, e o dragão faz a reverência (o pescoço
   inclina `rotation.x` 0,4 por 1 batida).
5. **A falha** (a primeira do ciclo): as notas que faltavam saem da fila sem julgar (`_notas[l].erase(nn)` e
   `_info[l].erase(nn)`: o kit não tem função para isso); `anotar("senha", l, {"L": L, "inteira": false})`; a fumaça
   (abaixo); a senha recomeça em `INICIO`, nova (`_senha_nova()`, pelo `rng`). O recorde fica.
6. **O próximo ciclo:**
   - depois da senha inteira, fora do pico: no começo de compasso **depois** de `A + L + 1`
     (`S' = 4 * (floori((A + L + 1) / 4.0) + 1)`);
   - depois da senha inteira, no pico: logo depois da última resposta (`S' = A + L`);
   - depois da falha: no primeiro começo de compasso a partir de `Ritmo.batida() + CenarioDoCanto.queda(l, 2.0)`.
   - O ciclo cuja última resposta passaria de `_b_fim − 1` não começa.

As contas da régua 5 (as notas de resposta por batida, de um lugar que acerta tudo): fora do pico, senha de 3 dá 3 em
12 batidas, de 5 dá 5 em 16, de 8 dá 8 em 20, de 12 dá 12 em 28; no pico, 3 em 5, 5 em 8, 8 em 12, 12 em 18. O pico
dá de **1,56×** (senha de 12) a **2,4×** (senha de 3). Fora do pico, a maior distância entre duas linhas `pista` ou
`toque` seguidas do mesmo lugar é de 6 batidas depois da senha inteira e de 7 depois da falha (o Fôlego 1: 2 batidas
mais o compasso): esta ficha fixa o item 7 em **8 batidas**.

A senha é sorteada pelo `rng` da semente, uma por lugar: com quatro, são quatro senhas diferentes, cada uma no seu
controle.

### A cabeça do dragão

- A cabeça gira para a raia de quem começou o canto por último: `pivo.rotation.y` para `atan2(RAIAS[l], Z_JOGADOR - PIVO.z)`
  (−40,6° no P1, −15,9° no P2, 15,9° no P3, 40,6° no P4), tween de 0,2 s.
- O queixo abre (`rotation.x` 0,3) enquanto qualquer canto toca e fecha 1 colcheia depois da última nota.
- **Na reta** (da batida 217), a cabeça fica na raia do líder: a maior `senha[l].size()`; no empate, o maior
  `recorde`; depois, o menor lugar. Ela só sai dali para a fumaça grande e volta logo depois.

### A fumaça (a falha)

A nuvem: um `Node3D` na raia, em `(RAIAS[l], 0.0, Z_JOGADOR)`, com 5 cubos `Kit.caixa` de 0,5 m
(`Kit.material(Tema.MUDO, 0.0, 1.0)`) em `(0, 0.5, 0)`, `(±0.35, 0.35, 0.1)` e `(±0.2, 0.8, -0.1)`. A escala dela é
`altura / 1.1`, com `altura`: `0.2 * L` m de 3 a 6 notas (0,6 a 1,2 m) e `1.5 * ALTURA_DO_CAVALEIRO` (1,65 m) de 7
para cima. Ela cresce de 0 à escala em 1 colcheia, fica 1 batida e some em 2 batidas.

**A fumaça pequena** (senha de 3 a 6), no ato da falha: a cabeça gira para a raia;
`Som.tocar("sopro", Vector3(RAIAS[l], 1.0, Z_JOGADOR), -8.0)`; o cavaleiro tosse (`gesto("emote-no", 0.6)`) e recua
0,5 m em z e volta em 1 batida. O controle sente o `erro` do kit; nada mais.

**A fumaça grande** (`fumaca_grande`, senha de 7 ou mais): `_fumaca_em[l] = CenarioDoCanto.proxima_colcheia(0.15)`. Na
colcheia (`_bater(l)`):

- a cabeça vira até a raia e o queixo abre 2 batidas;
- `Som.tocar("sopro", Vector3(RAIAS[l], 1.0, Z_JOGADOR), -2.0)` e `Som.tocar("golpe", Vector3(RAIAS[l], 1.0, Z_JOGADOR), -4.0)`;
- `Forja.sentir(l, "golpe")`; o R2 em Resistência (`Forja.gatilho(l, 1, Forja.GATILHO_RESISTENCIA, 2, 4)`) por
  0,25 s, depois Off;
- `CenarioDoCanto.exagero(self, _cenario, "catastrofe", jogador(l))` (tremor de 0,08 m por 4 batidas, a luz +40 % por
  1 compasso; +20 % sem flashes);
- `CenarioDoCanto.so_o_dono(self, l)`;
- o cavaleiro some (`visible = false`) enquanto a nuvem está cheia (1 batida) e volta tossindo (`gesto("emote-no", 0.6)`),
  com a fuligem;
- `momento("fumaca_grande", l, Vector3(RAIAS[l], 0.0, Z_JOGADOR), 1.65, {"L": L})`.

**A fuligem:** um `BoneAttachment3D` no osso `torso` do cavaleiro, com 3 manchas `Kit.caixa` de 0,22 × 0,16 × 0,02
(`Kit.material(Tema.GRAFITE, 0.0, 1.0)`) na frente do peito e nos ombros, até a próxima senha inteira dele.

### O pico

Na primeira batida com `no_pico()`, o dragão ruge: `Som.tocar("golpe", Vector3(0, 3.0, PIVO.z), -6.0)`, o queixo abre 2
batidas, `CenarioDoCanto.exagero(self, _cenario, "golpe")`, `Forja.sentir(l, "golpe")` em todos com controle (sem
gatilho), e o `CenarioDoCanto.passar` sobe a chave 20 % e recua a câmera 10 %. Daí em diante, os cantos que começam no
pico vêm em colcheias.

### A reta

Na batida 217, uma vez: `momento("reta", -1, Vector3(0, 0, Z_JOGADOR), 1.8, {"objeto": "pedrinhas", "valores": ",".join(recordes)})`.
Até o fim, a senha inteira vale o dobro, e a cabeça fica na raia do líder.

### O ensina

O primeiro ciclo de cada lugar (a senha de 3): enquanto o dragão canta a nota `i`, a pedrinha `i` do placar acende na
cor do lugar (`Tema.emissivo(mat, 1.2, l)`) e o glifo do botão da altura (`Desenho.glifo(GLIFO[senha[l][i]])`,
`Sprite3D` de 0,35 m, billboard, `shaded` false, `modulate` `Tema.ETIQUETA`) aparece sobre ela por 1 batida. Na
resposta, as três apagam de novo. Depois, só o som.

### O fim e o vencedor

`fim` `tempo`: 100 s de música, pelo kit (H08).

```gdscript
func vencedor() -> Array:
	var lista := presentes()
	lista.sort_custom(func(a, b):
		if int(recorde[a]) != int(recorde[b]):
			return int(recorde[a]) > int(recorde[b])
		if int(pontos[a]) != int(pontos[b]):
			return int(pontos[a]) > int(pontos[b])
		return a < b)
	return lista
```

### Com menos de quatro

- **Três, dois e um:** nada muda; cada um tem a sua senha e o seu ciclo. `com_poucos()` devolve `""`.
- **O controle que cai:** o ciclo dele para (as notas em aberto saem com `notas_perdidas(l)`, sem fumaça; a senha e o
  recorde ficam). Quando volta, um ciclo novo com a mesma senha no começo de compasso seguinte.

### Os ganchos

**O arquivo se monta à mão:** os blocos daqui são pedaços dele, e o resto sai da prosa; por isso nenhum leva `arquivo=`.

```gdscript
var _info := [{}, {}, {}, {}]  ## lugar -> {n: {i, altura, b}}
var _canto: Array = []  ## {l, b, i, som, n}: a tocar
var _ciclo := [{}, {}, {}, {}]  ## lugar -> {S, A, L, p, falhou}
var _ultima := [{}, {}, {}, {}]
var senha := [[], [], [], []]
var recorde := [0, 0, 0, 0]
var _compasso := 0
var _b_fim := 0
var _fora := [false, false, false, false]
var _pulso := [0.0, 0.0, 0.0, 0.0]
var _balanca_ate := [-1.0, -1.0, -1.0, -1.0]
var _fumaca_em := [-1.0, -1.0, -1.0, -1.0]
var _gatilho_ate := [-1.0, -1.0, -1.0, -1.0]
var _ensinou := [false, false, false, false]
var _fuligem := [null, null, null, null]
var _pedras := [[], [], [], []]  ## lugar -> [MeshInstance3D] × 12
var _rugiu := false
var _reta_anotada := false
var _sinos := {}
var _pivo: Node3D
var _queixo: Node3D
var _cenario := {}


func montar() -> void:
	var pose := CenarioDoCanto.pose_da_camera(1.0, OLHAR)
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDoCanto.montar(self, 1.0, false)
	_b_fim = int(floor(duracao * Ritmo.bpm / 60.0))
	_montar_o_fundo()  # a parede da masmorra e as duas torres
	_montar_o_dragao()
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = 0.0
		p.preso = true
		_sinos[l] = CenarioDoCanto.suporte(self, l)
		_montar_as_pedrinhas(l)
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	for l in presentes():
		senha[l] = _senha_nova()
		CenarioDoCanto.luz_da_nota(l, 1.0)
		_comecar_ciclo(l, 4.0)


func jogar(dt: float) -> void:
	var c := int(floor(Ritmo.batida() / 4.0))
	if c > _compasso:
		_compasso = c
		CenarioDoCanto.tempo_forte()
	CenarioDoCanto.passar(self, _cenario, no_pico())
	_tocar_o_canto()  # o falante, a pista, a cabeça, o queixo, o ensina
	_rugir_no_pico()
	_reta_no_tempo()
	for l in presentes():
		_apagar_o_pulso(l, dt)
		CenarioDoCanto.balancar(_sinos[l], 1.0 if Ritmo.batida() < float(_balanca_ate[l]) else 0.0)
		_fumaca_no_tempo(l)  # o _bater da fumaça grande e o gatilho que volta
		if not conectado(l):
			if not _fora[l]:
				_fora[l] = true
				notas_perdidas(l)
				_ciclo[l] = {}
			continue
		if _fora[l]:
			_fora[l] = false
			_comecar_ciclo(l, ceilf(Ritmo.batida() / 4.0) * 4.0 + 4.0)
		for k in 3:
			if Forja.apertou(l, BOTAO[k]):
				_responder(l, k)
		_passaram(l)
		_fechar_o_ciclo(l)  # a senha inteira ou a falha; o próximo ciclo pelo passo 6


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])  # o item, o kit já aplicou (H08)
	CenarioDoCanto.luz_da_nota(l, 0.6)
	_pulso[l] = PULSO_S
	_balanca_ate[l] = Ritmo.batida() + 1.0


func falha(l: int) -> void:
	_ultima[l] = {}
	if _ciclo[l].is_empty() or bool(_ciclo[l].get("falhou", false)):
		return
	_ciclo[l].falhou = true
	_fumaca(l, int(_ciclo[l].L))  # a pequena agora; a grande na próxima colcheia
	# o resto (limpar a resposta, a senha nova, o próximo ciclo) é do _fechar_o_ciclo,
	# depois do _passaram: a falha pode vir de dentro do laço dele


func status(l: int) -> String:
	return "Senha %d" % int(recorde[l]) if na_raia(l) else super(l)


func dica(l: int) -> Dictionary:
	if not na_raia(l):
		return {}
	return {"partes": ["@cross", "Grave", "@circle", "Média", "@triangle", "Aguda"], "pos": Vector3(RAIAS[l], 2.4, Z_JOGADOR)}


func com_poucos() -> String:
	return ""


func _exit_tree() -> void:
	CenarioDoCanto.soltar_a_musica(self)
```

`_comecar_ciclo(l, S)` monta `_ciclo[l]` pelos passos 1 a 3 (o canto em `_canto`, a resposta em `_info` e
`nova_nota`) e vira a cabeça. `_responder(l, k)` faz o passo 3. `_fechar_o_ciclo(l)` faz o passo 4 quando a última
resposta saiu da fila sem falha, e o passo 5 (as notas que faltavam saem com `_notas[l].erase(nn)` e
`_info[l].erase(nn)`, a linha `senha`, `senha[l] = _senha_nova()`) quando `falhou`; e então o passo 6. `_senha_nova()` devolve `INICIO` alturas pelo `rng`. `_tocar_o_canto()`,
`_rugir_no_pico()`, `_reta_no_tempo()`, `_fumaca(l, L)`, `_fumaca_no_tempo(l)`, `_apagar_o_pulso(l, dt)`,
`_montar_o_fundo()`, `_montar_o_dragao()` e `_montar_as_pedrinhas(l)` fazem o que as partes desta ficha dizem.
`_passaram(l)` é o da N1. A dica perde as palavras quando o lugar `aprendeu` (fica só o glifo: o painel faz).

O catálogo: `Catalogo.MINIGAMES["S06_J29"] = preload("res://scripts/minigames/s06/codigo_do_dragao.gd")` e
`"S06_J29"` na lista da seção `S06`.

## A cena

### A câmera

A da capela (N1), com o olhar mais alto para o dragão: `CenarioDoCanto.pose_da_camera(1.0, OLHAR)`, a câmera em
`(0, 15,59, 9,57)` olhando `(0, 1,8, −2,0)`, 35 mm, plongée de 50°, modo `fixa`, sem corte. O raio de cima passa em
y = 6,4 em z −5,6 (o topo do dragão está em 4,15); o de baixo chega ao chão em z 3,56 (as pedrinhas estão em z 0,4).
No pico, `pose_da_camera(1.1, OLHAR)`. O tremor é só o do `exagero`.

### A luz da seção

A da N1, sem pórtico: `CenarioDoCanto.montar(self, 1.0, false)`: a névoa `#050d26` (o main), o preenchimento
`#1f346a` a 0,2, a chave `#e5d3c6` a 0,47, as tochas `Tema.TUNGSTENIO` a 0,9.

- **O pico:** a chave +20 % em 1 batida (sem flashes, +10 % em 2).
- **A fumaça grande:** a luz +40 % por 1 compasso (sem flashes, +20 %), pelo degrau `catastrofe`.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `wall` | `Kit.arena(sala, 5, 3)` | o chão e as paredes |
| `modular-dungeon-kit/template-wall` (escala 4: 4 × 4,15 m) | `(-4, 0, -7.0)`, `(0, 0, -7.0)`, `(4, 0, -7.0)` | a parede da toca, atrás do dragão |
| `hexagon-kit/building-wizard-tower` (escala 3: 3,27 m) | `(±7.4, 0, -5.4)` | as duas torres dos lados |

O dragão (caixas do `Kit`, `metallic` 0, na proporção chibi: a cabeça grande). O pivô do pescoço é um `Node3D` em
`PIVO`; o queixo é um `Node3D` filho dele em `(0, 1.3, 0.2)`:

| objeto | forma | material |
| --- | --- | --- |
| o corpo | caixa 3,0 × 1,6 × 2,0 em `(0, 0.8, -6.2)` | `Kit.material(Tema.GRAFITE, 0.0, 0.95)` |
| o pescoço | caixa 0,8 × 1,4 × 0,8 em `(0, 0.7, 0)` do pivô | `GRAFITE` |
| a cabeça | caixa 2,0 × 1,3 × 1,6 em `(0, 1.9, 0.5)` do pivô (o topo em y 4,15) | `GRAFITE` |
| o queixo | caixa 1,7 × 0,4 × 1,4 em `(0, -0.15, 0.4)` do queixo | `GRAFITE` |
| a boca | caixa 1,6 × 0,1 × 1,3 em `(0, 1.32, 0.6)` do pivô | `Kit.material(Tema.JANELA, 0.0, 1.0)` |
| os olhos | caixa 0,3 × 0,18 × 0,08 em `(±0.5, 2.15, 1.32)` do pivô | `Kit.material(Tema.TUNGSTENIO, 1.2, 0.6, "forja")` |
| os chifres | caixa 0,16 × 0,6 × 0,16 em `(±0.7, 2.75, 0.2)` do pivô, inclinados ±20° em z | `GRAFITE` |
| a pedrinha `i` do lugar `l` (12) | cubo de 0,14 em `(RAIAS[l] - 0.88 + 0.16 * i, 0.07, Z_JOGADOR + PEDRA_Z)` | apagada `Kit.material(Tema.GRAFITE, 0.0, 0.9)`; acesa `Tema.emissivo(mat, 1.2, l)` |
| a nuvem de fumaça | 5 cubos de 0,5 | `Kit.material(Tema.MUDO, 0.0, 1.0)` |
| a fuligem | 3 manchas 0,22 × 0,16 × 0,02 no `torso` | `Kit.material(Tema.GRAFITE, 0.0, 1.0)` |
| o sino pequeno e o suporte | `CenarioDoCanto.suporte(self, l)` (N1) | o da N1 |
| o glifo do ensina | `Sprite3D` de 0,35 m | `modulate` `Tema.ETIQUETA` |

As `recorde[l]` primeiras pedrinhas ficam acesas: o placar, sem dizer as notas.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a pedrinha acesa (o recorde, o ensina) | o lugar | `Tema.emissivo(mat, 1.2, l)` |
| os olhos do dragão | a forja | 1,2 |
| as tochas | a forja | luz `Tema.TUNGSTENIO` 0,9 |

Nenhuma cor fora dos tokens. A fumaça e a fuligem não brilham.

### A montagem

- Por lugar: `raia(l)`, `posicionar(l)`, `rotation.y = 0.0` (de frente), `preso = true`, o sino com o suporte, as 12
  pedrinhas.
- `_montar_o_fundo()` e `_montar_o_dragao()`: as peças e as caixas das tabelas acima.

## O som

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a senha, grave | — (sem alto-falante: `nota` −10 dB, tom 0,6674, na raia) | `"nota:0"`, 0,9 | `mod_nota_p1`; `sint_nota` |
| a senha, média | — (sem alto-falante: `nota` −10 dB na raia) | `"nota"`, 0,9 | `mod_nota`; `sint_nota` |
| a senha, aguda | — (sem alto-falante: `nota_alta` −10 dB na raia) | `"nota_alta"`, 0,9 | `mod_nota_alta`; `sint_nota_alta` |
| a resposta certa | a nota do lugar, −4 ou −9 dB, `TOM_DO_LUGAR[l]` (o kit) | — | `sint_nota` |
| a resposta errada | a falha do kit (−6) | — | `falha_0..2` |
| a senha inteira | `Som.tocar("confirma", raia, -6.0)` | — | `confirma_0..2` |
| a fumaça pequena | `Som.tocar("sopro", raia, -8.0)` | — | `sint_sopro` |
| a fumaça grande | `Som.tocar("sopro", raia, -2.0)` e `Som.tocar("golpe", raia, -4.0)` | — | `sint_sopro`; `golpe_0..4` |
| o rugido do pico | `Som.tocar("golpe", Vector3(0, 3.0, -5.6), -6.0)` | — | `golpe_0..4` |
| o tempo forte | `Som.tocar("sino", SINO_TV, -16)` | — | `sint_sino` |
| a faixa | `MUS_S06_J29`: 140 BPM, Mi♭ menor, 150 s (toca 100); até ela existir, `sint_trilha` | — | `mus_s06_j29` |

- **A música abaixa na pista** (−12 dB por 1 batida, volta em 300 ms): cada nota da senha a abaixa.
- Sem alto-falante, a senha toca na raia dele na TV, na mesma altura do controle (o `falante` da N1), e o registro diz
  `no_controle: false`.
- O material `"pedra"`: a textura do acerto na háptica (o kit).

## O controle

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante |
| --- | --- | --- | --- | --- | --- |
| a senha | só o dono | — | — | — (nunca: entregaria a altura) | `nota:0`, `nota` ou `nota_alta`, 0,9 |
| a resposta BOM ou ÓTIMO | o dono | `acerto` (0,3 / 0,6, 80 ms; o kit) | — | 60 % por 0,12 s, volta a 100 % | — |
| a resposta PERFEITA | o dono | `perfeito` (0,5 / 0,8, 100 ms; o kit) | — | o kit: branco 0,15 s | — |
| a falha | o dono | `erro` (0,7 / 0,3, 160 ms; o kit) | — | o kit: escurecida 0,5 s | — |
| a fumaça grande | o dono | `golpe` (1,0 / 0,6, 250 ms) | R2 em Resistência (2, 4) por 250 ms, depois Off | — | — |
| o rugido do pico | todos | `golpe` | — | — | — |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar | — |

Fora da bancada, nunca pergunta.

### O robô

```gdscript
# O robô ouve as notas da senha no próprio alto-falante simulado
# (CenarioDoCanto.ouvir) enquanto o canto do ciclo toca, e repete no tempo
# só as que ouviu, na altura que ouviu. Quando não acerta, 250 ms tarde.
var _ouvido := [{}, {}, {}, {}]
var _robo_sons := [[], [], [], []]  ## o som de cada nota ouvida no canto de agora, na ordem
var _robo_ciclo := [-1.0, -1.0, -1.0, -1.0]
var _robo_feita := [-1, -1, -1, -1]
var _robo_tarde := [{}, {}, {}, {}]  ## {t, botao}


func robo(l: int, _dt: float) -> void:
	if not Forja.robo or _ciclo[l].is_empty():
		return
	if float(_ciclo[l].S) != float(_robo_ciclo[l]):
		_robo_ciclo[l] = float(_ciclo[l].S)
		_robo_sons[l] = []
	var a := CenarioDoCanto.ouvir(l, _ouvido[l])
	if not a.is_empty() and SOM.has(str(a.som)) and Ritmo.batida() < float(_ciclo[l].A):
		_robo_sons[l].append(str(a.som))
	var agora := Ritmo.t_musica()
	var tarde: Dictionary = _robo_tarde[l]
	if not tarde.is_empty() and agora >= float(tarde.t):
		Forja.robo_apertar(l, int(tarde.botao), 0.06)
		_robo_tarde[l] = {}
	for nn in notas_em_aberto(l):
		if nn <= int(_robo_feita[l]):
			continue
		if agora < alvo_da(l, nn):
			return
		_robo_feita[l] = nn
		var i := int(_info[l].get(nn, {}).get("i", 99))
		if i >= _robo_sons[l].size():
			return  # não ouviu: não responde
		var botao: int = BOTAO[SOM.find(_robo_sons[l][i])]
		if Forja.robo_acerta():
			Forja.robo_apertar(l, botao, 0.06)
		else:
			_robo_tarde[l] = {"t": agora + 0.25, "botao": botao}
		return
```

No pico, as notas do canto ficam a 0,214 s uma da outra: o `ouvir` (0,1 s) não as junta. O robô lê `_info` só para
saber a posição `i` da nota na senha, nunca a altura: a altura ele só tem se ouviu.

## O cavaleiro

O cavaleiro da montagem (G13), de frente, ao lado do sino. A cabeça, a parte de cima e a de baixo aparecem como estão;
as mãos ficam livres. Ele pode ser de outra raça (G08, parte B; a montagem é da G13): esta ficha usa o esqueleto comum de 7 ossos (a fuligem vai no
`torso`) e as animações `idle` e `emote-no`.

| stat | gancho | o que muda no Código | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | `empurrao` | não age: nada empurra | — | — | — |
| Passo | `velocidade` | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | quanto tempo depois da falha o próximo ciclo pode começar (`queda(l, 2)`) | 2,5 batidas | 2 | 1,5 |
| Faro | `pista` | a senha sai antes; a resposta fica no tempo | 40 ms depois | no tempo | 40 ms antes |
| Faro | `raio` | não age | — | — | — |

Os itens: o Escudo absorve o primeiro erro (o kit: a primeira falha não conta, e a senha não recomeça); a Âncora não
age; a Lanterna adianta a senha meio tempo (0,21 s a 140 BPM); o Martelo dobra o perfeito no tempo forte (o kit); o
Diapasão aumenta o ganho da nota do acerto (1,3). Nenhum stat muda a janela de julgamento.

O erro não tem squash. O desregistro do erro é do kit e da G08.

## As reações

- **Carimbos que o Código pode disparar** (do kit e do HUD, G04): `car_em_chamas` (5 Ressonâncias seguidas do mesmo
  lugar: a senha longa perfeita) e `car_acorde` (todos os que jogam acertam no mesmo tempo 1: sai quando as respostas
  caem juntas; o Código não o busca). O `car_por_um_fio` e o `car_virada` são do placar (G07): o Código não os chama.
- **Adesivos:** ninguém está fora da rodada; ninguém manda adesivo durante o jogo.
- Nenhum carimbo próprio.

## A diversão

**O momento: a fumaça grande** (`fumaca_grande`). Errar uma senha de 7 ou mais: a cabeça do dragão vira até a raia, a
fumaça de 1,65 m (1,5 vez o cavaleiro) cobre a raia, o cavaleiro some e volta tossindo e cinza. Degrau catástrofe
(tremor de 0,08 m por 4 batidas, a luz +40 % por 1 compasso).

- **Rastro:** a fuligem fica no cavaleiro até a próxima senha inteira dele; o recorde fica nas pedrinhas acesas.
- **A curva:** de 0 a 33 s, a senha em batidas, crescendo uma nota a cada acerto; de 33 a 67 s, o dragão canta em
  colcheias e o ciclo emenda no seguinte; de 67 s ao fim, batidas de novo, e nas últimas 16 a senha inteira vale o
  dobro e a cabeça fica na raia do líder.
- **Ensina sem falar:** a primeira senha de 3 acende as pedrinhas, com o glifo do botão, enquanto o dragão canta.
- **Quem está perdendo:** a senha recomeça em 3 e o recorde fica; quem errou cedo volta rápido. Quem tem a senha maior
  arrisca a fumaça maior.
- **A nota de hoje:** 3. A cabeça na raia do líder conta à sala, antes da fumaça, que alguém foi longe.

**Como o jogador do time confere.** A mesa padrão (P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `toque` com `t_musica` ≤ 10,0 (a primeira resposta cai em 3,4 s) | o quadro de 10 s mostra uma pedrinha acesa ou um sino balançando |
| 4. o momento | pelo menos 1 linha `momento` `fumaca_grande` em 100 s, de qualquer lugar | um cavaleiro com fuligem no quadro seguinte |
| 5. a curva | as linhas `toque` por segundo no 2.º terço ≥ 1,5 × as do 1.º (dá de 1,56 × a 2,4 ×); no 3.º ≥ 1,0 × (dá 1,0 ×); a linha `momento` `reta` existe | o quadro do meio do 2.º terço tem a luz 20 % acima do do 1.º |
| 6. a falha | o P4 tem pelo menos 5 linhas `senha` com `inteira` false | 1 quadro em 5 mostra uma nuvem de fumaça |
| 7. quem perde joga | a maior distância entre duas linhas `pista` ou `toque` seguidas de cada lugar é de até 8 batidas; o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | cada `fumaca_grande` tem 0,05 ≤ `x_tela` ≤ 0,95 e `altura_tela` ≥ 0,08 | a nuvem cabe inteira no quadro de 480 × 270 |
| 9. o impacto | para cada `fumaca_grande`, uma linha `sensacao` `golpe` a até 16,7 ms, a até 1 quadro de uma colcheia | o quadro seguinte mostra a nuvem cheia |
| 10. o placar no mundo | os recordes do `momento` `reta` batem com as linhas `senha` inteiras até ali | no quadro de 95 s, quem olha conta as pedrinhas acesas de cada um, e a conta bate com o registro |

O `x_tela` da fumaça vai de 0,05 a 0,95: ela cai na raia de quem errou, e as raias de fora (x ±6) ficam em 0,20 e 0,80
nesta câmera, na beira da faixa de 0,2 a 0,8 da régua. A `prova_do_jogo.sh` roda o `bom` nos quatro (`--robo --semente=7`, sem repassar argumentos): a prova
confere os itens 1, 4, 5, 8, 9 e 10 com ele, e o item 4 com uma falha que a prova força numa senha de 7 ou mais (em
«Provas»). A mesa padrão e os itens 6 e 7 esperam o robô por lugar (`--robo=bom,medio,medio,ruim`), que a F09 não faz.

## Pronto quando

O Código do Dragão joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o `bom`
chega a senhas de 7 ou mais); aguenta o cabo que cai e volta; fecha com o vencedor de senha mais longa; a fumaça
grande cai pelo menos 1 vez com a mesa boa; a prova do jogo passa; e `bash tests/prova_visual.sh` passa com a prancha
olhada.

## Provas

Na sessão: `SALA=S06_J29 bash tests/prova_do_jogo.sh` (a prova do Dragão, sem e com `--bancada`),
`bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a função abaixo, chamada pela linha `"S06_J29": await _prova_do_dragao()`
no `match` do `_prova_da_ficha(slot)` da H08. O robô da sh é o `bom`, que quase nunca erra: para a fumaça grande, a
prova força uma falha, uma vez, na primeira resposta de uma senha de 7 ou mais, 50 ms antes do alvo (antes do robô).

```gdscript
## Código do Dragão (S06_J29): cada um tem a sua senha, entre 3 e 12 notas; a
## senha chega ao alto-falante simulado; a fumaça grande põe o R2 em
## Resistência; o vencedor tem a senha mais longa.
func _prova_do_dragao() -> void:
	var fora := [0]
	var tocou := [false]
	var resistencia := [false]
	var forcou := [false]
	var olhar := func(mg: Minigame) -> void:
		for l in mg.presentes():
			var n := (mg.senha[l] as Array).size()
			if n < mg.INICIO or n > mg.MAXIMO:
				fora[0] += 1
			if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.3:
				tocou[0] = true
			if int(Forja.percepcao(l).get("gatilho_dir", 0)) == 0x21:
				resistencia[0] = true
			var abertas: Array = mg.notas_em_aberto(l)
			if not forcou[0] and (mg.senha[l] as Array).size() >= mg.GRANDE and not abertas.is_empty() \
					and Ritmo.t_musica() >= float(mg.alvo_da(l, abertas[0])) - 0.05:
				forcou[0] = true
				mg._ultima[l] = mg._info[l].get(abertas[0], {})
				mg.nota_perdida(l, abertas[0])
	var mg = await _joga_o_minigame("S06_J29", 140.0, olhar)
	if mg == null:
		return
	_esperar(fora[0] == 0, "Dragão: a senha sempre entre 3 e 12 notas")
	_esperar(tocou[0], "Dragão: a senha saiu de um alto-falante simulado")
	var v := mg.vencedor()
	_esperar(not v.is_empty() and int(mg.recorde[v[0]]) == v.map(func(l): return int(mg.recorde[l])).max(), "Dragão: vence a senha mais longa")
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S06_J29")
	var canto := linhas.filter(func(e): return e.get("tipo") == "pista" and e.get("evento") == "mandou")
	var toques := linhas.filter(func(e): return e.get("tipo") == "toque")
	var fumacas := linhas.filter(func(e): return e.get("tipo") == "momento" and e.get("nome") == "fumaca_grande")
	_esperar(canto.size() >= 3, "Dragão: %d notas de senha cantadas" % canto.size())
	for l in mg.presentes():
		_esperar(toques.any(func(e): return int(e.get("jogador", 0)) == l + 1 and float(e.get("t_musica", 99.0)) <= 10.0), "Dragão: o P%d respondeu até 10 s" % (l + 1))
	for f in fumacas:
		_esperar(int(f.get("L", 0)) >= mg.GRANDE, "Dragão: a fumaça grande vem de senha de 7 ou mais (%s)" % [f])
		_esperar(float(f.get("x_tela", 0.0)) >= 0.05 and float(f.get("x_tela", 0.0)) <= 0.95 \
			and float(f.get("altura_tela", 0.0)) >= 0.08, "Dragão: a fumaça grande na tela (%s)" % [f])
	_esperar(forcou[0], "Dragão: o bom chegou a uma senha de 7 ou mais")
	_esperar(fumacas.size() >= 1, "Dragão: %d fumaças grandes (o mínimo é 1)" % fumacas.size())
	_esperar(resistencia[0], "Dragão: a fumaça grande põe o R2 em Resistência (0x21)")
	if not Forja.bancada:
		_esperar(_linha_do_tempo().filter(func(e): return e.get("o") == "pergunta" and e.get("slot", "") == "S06_J29").is_empty(), "Dragão: fora da bancada, nenhuma pergunta")
```

### O que o registro mede

- `som_controle` (H07) de cada nota da senha e a `pista` (`canal` `alto_falante`: n da resposta, som, `no_controle`).
- O `toque` do kit em cada nota da resposta. O cruzamento: a senha inteira cantada com `placa` e a resposta que para
  sempre na mesma posição num controle é o alto-falante que cortou; a senha curta repetida bem e a longa errada no
  mesmo ponto é memória, não alto-falante.
- `senha` (`L`, `inteira`) no fim de cada ciclo; a `sensacao` `golpe` e o `momento` `fumaca_grande`; o `momento` `reta`.

### As pranchas que o jogador do time olha

A prancha da prova visual (480 × 270, um quadro a cada 2 s): o quadro de 10 s (as pedrinhas do ensina), os de 30 e 60
s (a cabeça do dragão virada), os quadros com a nuvem e o seguinte (a fuligem), e o de 95 s (as pedrinhas contadas).
O `Catalogo.sortear` da H08 põe o `S06_J29` na noite: rode a prova visual com a semente que o sorteia, `--semente=N`.

### O que o André joga e sente

`./run-local.sh -- --sala=S06_J29`, com quatro DualSense, dois no cabo e dois no rádio:

- as três alturas se distinguem no alto-falante pequeno, com a música na TV;
- a senha dos outros não atrapalha: cada controle canta na sua mão;
- o pico em colcheias é difícil e engraçado; a fumaça faz rir, e a grande faz a sala gritar;
- a senha longa (oito, dez notas) dá orgulho, e as pedrinhas mostram para todos.

### Armadilhas

- **Nunca toque a senha na TV**, a não ser na saída silenciosa (sem alto-falante), e aí o registro diz
  `no_controle: false`.
- **A falha só uma vez por ciclo:** a primeira falha limpa a resposta; as notas que sobraram não viram erro.
- **O canto do pico em colcheias, a resposta nas batidas:** o `A` é arredondado para cima.
- **A tela não conta a senha:** as pedrinhas mostram o recorde, nunca as notas (o ensina é a exceção, só na primeira).
- **Os pontos e o item:** o kit aplica `Itens.pontos_do_acerto` no `julgar_nota` (H08); marque cru.
- **`_notas` é do kit.** O dado da nota mora em `_info`.
- **A música:** o `_exit_tree` chama `soltar_a_musica`.

### Ao terminar

- No [quadro](README.md): a linha **N4**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer): `feat: Código do Dragão no kit, a senha que só o seu controle canta e a fumaça grande`
