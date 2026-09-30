# G06 — O salão e a coleção

**Sprint:** G · **Tamanho:** M · **Estimativa:** US$ 2,5 · **Depende de:** F00, G02

## Por quê

O salão não conta a noite: os portões dizem o hardware ("botões,
analógicos e gatilhos"), nada acende quando uma seção é vencida e o grupo
não guarda nada do que conquistou.

## Ler antes

- [A coleção](../06b-a-construcao-do-cavaleiro.md#a-coleção)
- [As telas](../06-telas-e-fluxo.md#as-telas) (a linha "salão")
- [O mundo](../07-narrativa-e-voz.md#o-mundo) (o portão acende quando a sala volta ao compasso)
- [As regras de coerência](../11-arte-e-personagens.md#as-regras-de-coerência) (a vitrine e os troféus)

## O estado de hoje

- `godot/scripts/mundo/salao.gd:15-24`, `PORTOES`: um por sala, com
  `"nome"` ("A Centelha"), `"sobre"` (o hardware), `"icone"`, `"lado"`,
  `"t"` e `"aberta"`.
- `godot/scripts/mundo/salao.gd:143-210`, `_portao(p)`: a moldura, o portão
  animado, a placa 3D com o nome (`Label3D`, 96), o ícone (`Sprite3D`) e o
  `sobre` (`Label3D`, 64, em `position.y = -0.3`), as duas tochas; guarda
  tudo em `portoes[p.id]`.
- `godot/scripts/main.gd:669-670`, `_quadro_salao()`: perto de um portão,
  `hud.placa = {"nome": dados.nome, "sobre": dados.sobre, "aberta": dados.aberta}`;
  o HUD desenha o `sobre` embaixo do nome (`hud.gd`, a placa).
- `godot/scripts/main.gd:340-365`, `_ao_terminar_a_sala()`: a sala acabou
  (depois das guardas `estado != "sala" or overlay != "" or _trocando`); com
  partida, `_placar_da_sala(sj)` (395-406) calcula a colocação pela
  `Partida.registrar(sj.id, sj.pontos, presentes)`. Nada guarda a vitória
  fora da partida.
- `godot/scripts/mundo/salao.gd:395-416`, `_enfeites()`: barris, baú, mesa,
  pedras em `(10.4, 0, -1.0)` na parede leste, o suporte de armas na oeste.
  Não há vitrine.
- `godot/scripts/player.gd` (G02): `ACABAMENTOS` com `"livre": false` no
  Dourado; `acabamentos_disponiveis()` devolve só os livres. A construção
  (`TelaLobby`) passa pelo acabamento com ◀▶ entre os disponíveis.
- `godot/scripts/opcoes.gd` (G02): `noite()` e `guardar()`; o padrão de
  arquivo `user://*.cfg` que o robô não lê nem grava.
- Hoje cada seção tem **um** minigame (a sala). O catálogo das seções
  (`Catalogo.SECOES`, H04) ainda não existe.

## O alvo

### A coleção (`godot/scripts/colecao.gd`, `class_name Colecao extends RefCounted`, estática)

```gdscript
const ARQUIVO := "user://colecao.cfg"
## Os acabamentos que a coleção desbloqueia, e o que desbloqueia cada um.
const DESBLOQUEIOS := {
	"Dourado": "o primeiro troféu da noite",
	"Cromado": "três seções de volta ao compasso",
	"Néon": "um coop sem erro",
}
static var noite := ""              ## Opcoes.noite() da coleção carregada
static var vencidos := {}           ## id do minigame -> lugar que venceu primeiro na noite
static var recordes := {}           ## id do minigame -> os pontos mais altos da noite
static var trofeus: Array = []      ## [{"id", "lugar", "tipo": "vitoria" | "recorde" | "coop"}]
static var desbloqueados: Array = []  ## os nomes de DESBLOQUEIOS já ganhos na noite
static var _robo := false

static func carregar(robo: bool) -> void       ## lê a seção da noite de hoje; outra noite começa vazia
static func guardar() -> void                   ## grava (nada com o robô)
static func zerar() -> void                     ## a coleção vazia (a prova usa)
## Um minigame acabou: devolve os nomes desbloqueados agora ([] se nada).
static func registrar(id: String, pontos: Array, presentes: Array, coop := false, sem_erro := false) -> Array
static func minigames_da_secao(id_do_portao: String) -> Array
static func secao_acesa(id_do_portao: String) -> bool
static func marcas(id_do_portao: String) -> Array   ## [bool] por minigame da seção: vencido na noite?
static func desbloqueado(nome: String) -> bool
```

As regras de `registrar(id, pontos, presentes, coop, sem_erro)`:

1. O vencedor: entre os `presentes`, o de mais pontos, se for **> 0**; empate
   em cima: o de menor lugar.
2. **Vitória:** se há vencedor e `id` não está em `vencidos`:
   `vencidos[id] = lugar` e um troféu `{"id": id, "lugar": lugar, "tipo": "vitoria"}`.
3. **Recorde** (só com vencedor, isto é, `maior > 0`): se `recordes.has(id)`
   e `maior > recordes[id]`, um troféu `"recorde"` para quem fez; depois,
   `recordes[id] = maxi(recordes.get(id, 0), maior)`. Sem vencedor, o
   recorde não se toca (uma rodada de zeros não vira base de recorde).
4. **Coop sem erro:** `coop and sem_erro`: um troféu `"coop"` com `lugar = -1`
   (o grupo).
5. **Desbloqueios**, na ordem, cada um uma vez: Dourado com
   `trofeus.size() >= 1`; Cromado com três portões acesos
   (`secao_acesa`); Néon com um troféu `"coop"`.
6. `Forja.evento("colecao", 0, {"id": id, "trofeus": [os tipos novos], "desbloqueou": [...]})`,
   `Forja.registrar(...)` com o mesmo, e `guardar()`.

`minigames_da_secao(id)`: se o arquivo `godot/scripts/minigames/catalogo.gd`
já existir (H04 feita), os `"minigames"` da seção cujo primeiro minigame é o
apelido `id`; **hoje**, `[id]`. (Escreva hoje `return [id]` com um comentário
dizendo o que a H04 troca.) `secao_acesa`: todos os de
`minigames_da_secao` em `vencidos`.

`carregar(robo)` é chamado em `godot/scripts/forja.gd`, logo depois de
`Opcoes.carregar(robo)`; no cfg, uma seção por noite (`[2026-09-30]`) com
`vencidos`, `recordes`, `trofeus`, `desbloqueados`.

### O salão

**O portão** (`_portao(p)`):

| o quê | como |
| --- | --- |
| o `sobre` (hardware) | **sai** da placa 3D (o `Label3D` de `position.y = -0.3`) e de `PORTOES` |
| as marcas | embaixo do nome, em `position.y = -0.35`: uma caixa `Vector3(0.18, 0.18, 0.04)` por minigame da seção, a cada 0,3 m, centradas; apagada `Kit.material(Tema.TRILHO)`, vencida `Kit.material(Tema.ROSA, 1.6)` |
| o arco | uma caixa `Vector3(3.2, 0.12, 0.12)` no alto da abertura (`pos + frente * 0.25 + Vector3(0, 2.35, 0)`, girada com o portão): apagado `Kit.material(Tema.TRILHO)`; seção acesa `Kit.material(Tema.ROSA, 2.0)` e uma `OmniLight3D` rosa de energia 0,8, alcance 4, ali embaixo |

`portoes[id]` guarda `"marcas": Array[MeshInstance3D]`, `"arco"` e
`"luz_do_arco"`. Novo:

```gdscript
func mostrar_colecao() -> void          # acende marcas e arcos pela Colecao e refaz a vitrine
func portao_aceso(id: String) -> bool   # o arco aceso (a prova usa)
func trofeus_na_vitrine() -> int
```

**A placa do HUD** (`main.gd:669-670`): `hud.placa = {"nome": dados.nome, "marcas": Colecao.marcas(perto), "aberta": dados.aberta}`.
Em `hud.gd`, na placa, no lugar da linha do `sobre`: uma fileira de
círculos de raio 9 a cada 28 px, a partir de `r.position + Vector2(40, 100)`,
cheios em `Tema.ROSA` (vencido) ou `Tema.TRILHO`. A largura mínima da placa
continua 620.

**A vitrine** (`_vitrine()`, chamada no `_ready()` do salão), encostada na
parede leste entre os dois portões, virada para dentro do salão:

- tirar `peca("stones", Vector3(10.4, 0, -1.0), …)` de `_enfeites()`;
- `vitrine_no := Node3D` em `Vector3(10.6, 0, 0.0)`, `rotation.y = -PI * 0.5`;
- madeira `Kit.material(Color("#6b4a32"), 0.0, 0.9)`: dois lados
  `Kit.caixa(vitrine_no, Vector3(0.08, 1.9, 0.5), Vector3(±1.25, 0.95, 0), madeira)`,
  três prateleiras `Kit.caixa(vitrine_no, Vector3(2.5, 0.08, 0.5), Vector3(0, y, 0), madeira)`
  com `y` em 0,6, 1,2 e 1,8;
- `trofeus_no := Node3D` filho de `vitrine_no`; troféu `i` (até 18) em
  `Vector3(-1.0 + (i % 6) * 0.4, 0.64 + floor(i / 6) * 0.6, 0)`.

Os troféus (foscos, `metallic` ≤ 0,2; a cor do lugar só no troféu de quem
venceu — a regra 6 de [11](../11-arte-e-personagens.md#as-regras-de-coerência)):

| tipo | peça |
| --- | --- |
| vitoria | taça: base `Kit.caixa(t, Vector3(0.16, 0.04, 0.16), Vector3(0, 0.02, 0), m)`, haste `Kit.cilindro(t, 0.03, 0.10, Vector3(0, 0.09, 0), m)`, copo `Kit.cilindro(t, 0.06, 0.14, Vector3(0, 0.21, 0), m, 0.09)`; `m = Kit.material(Forja.cor_do_lugar(lugar).lerp(Color("#8a8fa8"), 0.3), 0.0, 0.6)` |
| recorde | `Kit.peca(t, "coin", Vector3(0, 0.12, 0), 0.0, 0.8)` de pé (`rotation.x = PI * 0.5`) e uma base de madeira |
| coop | quatro cubos `Vector3(0.07, 0.07, 0.07)` lado a lado nas quatro cores dos lugares |

**A construção oferece o desbloqueado:** `ForjaPlayer.ACABAMENTOS` ganha

```gdscript
	{"nome": "Cromado", "rugoso": 0.25, "metal": 0.2, "claro": 0.45, "livre": false},
	{"nome": "Néon", "rugoso": 0.6, "metal": 0.0, "claro": 0.1, "brilho": 0.6, "livre": false},
```

(`"brilho"`: `emission_enabled`, `emission` = a cor do lugar,
`emission_energy_multiplier` = o valor — o néon é brilho com dono), e
`acabamentos_disponiveis()` passa a incluir os de `"livre": false` com
`Colecao.desbloqueado(nome)`.

### Onde a coleção ouve

`main.gd`, `_ao_terminar_a_sala()`, **depois** das guardas e antes do ramo
da partida:

```gdscript
	if sala is SalaJogo:
		var sj := sala as SalaJogo
		var presentes: Array = []
		for l in 4:
			if sj.jogando[l]:
				presentes.append(l)
		var novos := Colecao.registrar(sj.id, sj.pontos, presentes)
		for nome in novos:
			hud.mostrar_aviso("%s na forja" % nome)
```

(Se a F03 já moveu o fim para a `TelaResultado`, ponha a chamada onde o
resultado fecha — o mesmo lugar que chama `_placar_da_sala`.)
`_ir_para_o_salao()` chama `salao.mostrar_colecao()` dentro do `feito`.

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 3 e 5.

1. **O 13 primeiro:** uma seção nova "### A coleção — G06" com a API de
   `Colecao` (o bloco acima) e, na tabela do registro v2, a linha
   `colecao` (`id`, `trofeus`, `desbloqueou` — G06).
2. **`godot/scripts/colecao.gd` (novo):** a classe; importar e commitar o
   `colecao.gd.uid`; `Colecao.carregar(robo)` em `forja.gd`.
3. **`godot/scripts/mundo/salao.gd`:** `PORTOES` sem `"sobre"`; `_portao()`
   com marcas e arco; `_vitrine()`; `mostrar_colecao()`, `portao_aceso()`,
   `trofeus_na_vitrine()`; tirar as pedras da parede leste.
4. **`godot/scripts/player.gd`:** Cromado e Néon;
   `acabamentos_disponiveis()` com a coleção; o `"brilho"` em
   `_aplicar_acabamento()`.
5. **`godot/scripts/main.gd` e `godot/scripts/ui/hud.gd`:** o registro no fim
   da sala, `mostrar_colecao()` no salão, a placa com marcas.
6. **`godot/scripts/traducoes.gd`:** `"Cromado": "Chrome"`,
   `"Néon": "Neon"`, e o padrão `["^(.+) na forja$", "$1 in the forge"]`.
7. **As provas** (ver Provas).

## Armadilhas

- **`.uid`** do `colecao.gd`.
- **Nada de `Forja.robo` fora do `forja.gd`:** `Colecao.carregar(robo)`
  recebe o valor de lá; `guardar()` usa o `_robo` guardado (o mesmo padrão
  do `Opcoes.guardar()` da G02).
- **A noite:** use `Opcoes.noite()`; a coleção de ontem não aparece hoje.
- **O Label3D apagado:** tirar o `sobre` da placa 3D e de `PORTOES` exige
  tirar também o uso em `main.gd` (`dados.sobre`) e na placa do HUD.
- **A cor do lugar é sagrada:** o arco e as marcas são rosa (a marca da
  casa), nunca a cor de um lugar; só a taça de quem venceu leva a cor dele.
- **O brilho tem dono:** o Néon é emissivo por ser néon; nada mais na vitrine
  brilha.
- **Texto:** o aviso de desbloqueio passa pelo `Traducoes` e começa com
  maiúscula (o nome do acabamento já começa).
- **A bigorna ("A Prova") não é portão:** `minigames_da_secao("prova")` só
  vale quando houver o portão dela; hoje A Prova conta pela vitória, sem
  arco.

## Não fazer

- Loja, moeda, contagem de pontos da coleção.
- Peças novas desbloqueáveis (a G08 cria as peças; quando existirem, uma
  ficha pequena as põe em `DESBLOQUEIOS`).
- Mudar a regra da partida ou do pódio.
- Texto longo no salão: o portão mostra o nome e as marcas; nada mais.

## Pronto quando

Depois de uma partida de três, o salão mostra os troféus na vitrine, o arco
d'A Centelha aceso, e a construção oferece o Dourado; outra noite começa com
a coleção vazia.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd`, uma função pura, chamada no `_ready()`
depois de `_prova_das_contas_da_partida()` — ela guarda e devolve o estado:

```gdscript
## As contas da coleção, sem sala.
func _prova_das_contas_da_colecao() -> void:
	var antes := [Colecao.vencidos.duplicate(), Colecao.recordes.duplicate(), Colecao.trofeus.duplicate(), Colecao.desbloqueados.duplicate()]
	Colecao.zerar()
	_esperar(Colecao.registrar("molde", [0, 0, 0, 0], [0, 1]) == [], "coleção: ninguém pontuou, nada se ganha")
	_esperar(Colecao.trofeus.is_empty() and not Colecao.vencidos.has("molde"), "coleção: zero pontos não é vitória")
	_esperar(Colecao.registrar("molde", [10, 40, 40, 0], [0, 1, 2]) == ["Dourado"], "coleção: a primeira vitória desbloqueia o Dourado")
	_esperar(Colecao.vencidos["molde"] == 1, "coleção: o empate em cima vai para o menor lugar")
	Colecao.registrar("molde", [90, 0, 0, 0], [0, 1])
	var tipos := Colecao.trofeus.map(func(t): return str(t.tipo))
	_esperar(tipos == ["vitoria", "recorde"], "coleção: vencer de novo com mais pontos é recorde (%s)" % [tipos])
	_esperar(Colecao.secao_acesa("molde") and not Colecao.secao_acesa("viga"), "coleção: a seção acende só com os minigames dela vencidos")
	Colecao.registrar("viga", [5, 0, 0, 0], [0])
	Colecao.registrar("canto", [0, 5, 0, 0], [1])
	_esperar(Colecao.desbloqueado("Cromado"), "coleção: três seções acesas desbloqueiam o Cromado")
	Colecao.registrar("caminhos", [1, 1, 1, 1], [0, 1, 2, 3], true, true)
	_esperar(Colecao.desbloqueado("Néon"), "coleção: o coop sem erro desbloqueia o Néon")
	Colecao.vencidos = antes[0]
	Colecao.recordes = antes[1]
	Colecao.trofeus = antes[2]
	Colecao.desbloqueados = antes[3]
```

E no fim de `_prova_da_partida()`, depois de voltar ao salão:

```gdscript
	_esperar(Colecao.vencidos.has("centelha"), "coleção: A Centelha foi vencida nesta noite")
	_esperar(jogo.salao.portao_aceso("centelha"), "o arco d'A Centelha acendeu")
	_esperar(jogo.salao.trofeus_na_vitrine() == mini(Colecao.trofeus.size(), 18), "a vitrine mostra os troféus (%d)" % Colecao.trofeus.size())
	_esperar(ForjaPlayer.acabamentos_disponiveis().has(3), "a construção oferece o Dourado")
```

## Para o André (local)

1. `./run-local.sh`, uma partida de três: voltar ao salão, andar até a
   vitrine (parede da direita) e ao portão d'A Centelha (arco rosa aceso,
   marca acesa na placa).
2. Voltar à construção pela pausa: o Dourado aparece no acabamento.
3. Fechar e abrir na mesma noite: a vitrine continua; mudar a data do
   sistema (ou apagar `colecao.cfg` da pasta de dados do Godot) e ver a
   coleção vazia.
4. `bash tests/telas.sh fotos /tmp/fotos-g06` e olhar `salao_depois.png`.

## Ao terminar

No [quadro](README.md), G06 **feito** com o commit e o gasto. Commit
sugerido (sem trailer):

```
feat: a coleção da noite — troféus na vitrine, o portão que acende e os acabamentos que se ganham jogando
```
