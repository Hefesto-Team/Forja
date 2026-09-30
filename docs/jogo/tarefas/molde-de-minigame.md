# O molde de minigame

Como se escreve um minigame no kit. Uma sessão que faz um minigame lê esta
página, a linha do minigame em [03](../03-os-45-minigames.md) e o
[kit](../13-arquitetura.md#o-kit-do-minigame--h04) — e nada mais. O código do
kit está em `godot/scripts/minigames/minigame.gd` (H04); o exemplo pequeno e
completo é `godot/testes/minigame_de_prova.gd`.

## Onde mora

- O script: `godot/scripts/minigames/sNN/<nome_em_minusculas>.gd`
  (`s01/martelo_de_hefesto.gd`, `s02/pendulos_do_caos.gd`…), `extends Minigame`,
  **sem `class_name`** (o catálogo carrega pelo caminho).
- No catálogo (`godot/scripts/minigames/catalogo.gd`): o slot em
  `MINIGAMES` (`"S02_J07": preload("res://scripts/minigames/s02/pendulos_do_caos.gd")`)
  e na lista `minigames` da seção, em `SECOES`. O primeiro da lista é o que o
  apelido da seção abre (`--sala=viga`).
- O `.uid`: depois de criar o `.gd`, `"$GODOT" --headless --path godot --import --quit`,
  e o `<nome>.gd.uid` entra no commit.
- As frases novas da tela (título, verbo) em `godot/scripts/traducoes.gd`.

## A ficha de dados: o `const FICHA`

Um dicionário constante no começo do script. É texto: cabe no diff e se
escreve sem o editor. O kit lê no `_init()` e confere no `entrar()` (falta
chave: `push_error` com o nome dela).

```gdscript
extends Minigame
## Pêndulos do Caos (S02_J07). <como se joga, em duas ou três linhas>
##
## A falha: <o que acontece fisicamente no erro — docs/jogo/02#6>.
## O vencedor: <o critério>.
## O alto-falante do dono: <o som pessoal — docs/jogo/05#a-agenda-do-alto-falante>.
## O registro mede: <a validação do recurso, por baixo — a linha "O registro
## mede" da seção em docs/jogo/03>.
## O robô: <como joga, e como erra quando não acerta>.
## Com menos de quatro: <o que muda; "nada" se nada muda>.
## A régua: <as três respostas de "A régua, antes do commit", abaixo>.

const FICHA := {
	"slot": "S02_J07",
	"titulo": "Pêndulos do Caos",
	"verbo": "Vire no alto!",
	"genero": "sobrevivencia",
	"icone": "giroscopio",
	"entradas": [],
	"camera": "fixa",
	"faixa": "MUS_S02_J07",
	"duracao": 90.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe"],
	"material": "metal",
	"microjogo": {"verbo": "Vire!", "segundos": 6.0},
}
```

As chaves obrigatórias (as mesmas de `Minigame.CHAVES`):

| chave | o que é | valores |
| --- | --- | --- |
| `slot` | a seção e o número | `"Sxx_Jyy"` (o `id` da sala) |
| `titulo` | o nome na tela (o `nome`) | o da tabela de [03](../03-os-45-minigames.md) |
| `verbo` | a única instrução, de uma a três palavras (a `acao`) | `"Bata!"` |
| `genero` | o gênero | `tct`, `2v2`, `coop`, `corrida`, `sobrevivencia`, `terror`, `sabotagem` |
| `icone` | a parte do controle, para o aviso | `botoes`, `analogicos`, `gatilhos`, `giroscopio`, `touchpad`, `vibracao`, `gatilho_adaptativo`, `alto_falante`, `haptica`, `microfone` |
| `entradas` | os botões usados (no máximo três), com `Forja.CRUZ`… | `[Forja.CRUZ]`; `[]` quando a entrada é movimento, toque ou voz |
| `camera` | o modo de câmera (G05) | `fixa`, `grupo`, `corrida` |
| `faixa` | o slot musical ([04](../04-ritmo-e-audio.md#as-45-faixas)) | `"MUS_Sxx_Jyy"`; `""` = sem música (o relógio do sistema) |
| `duracao` | em segundos, até 120 | `0.0` = acaba pelo próprio jogo |
| `fim` | como acaba | `tempo`, `ultimo_em_pe`, `primeiro_a_chegar`, `meta_coletiva` |
| `sensacoes` | as sensações usadas, pelo nome (F05) | `acerto`, `perfeito`, `erro`, `golpe`, `explosao`, `aviso` |
| `material` | o chão e os objetos ([05](../05-haptica-e-controle.md#a-háptica-por-material)) | `metal`, `pedra`, `areia`, `gelo`, `grama`, `lama`, `plasma`, `madeira` |
| `microjogo` | o recorte para o Relâmpago | `{"verbo": "Bata!", "segundos": 6.0}` (5 a 8 s) |

As chaves opcionais:

| chave | o que é | sem ela |
| --- | --- | --- |
| `features` | as features que a bancada mede (as chaves do catálogo do núcleo) | nenhuma: nada de veredito |
| `botoes_medidos` | os botões que as medidas do núcleo acompanham | nenhum |
| `gesto` | o gesto do boneco no aviso (`"attack-melee-right"`, `"lados"`) | o boneco só espera |
| `treino` | `false` desliga o treino de 10 s | com treino |

## Os ganchos

O kit cuida do relógio, do julgamento, do registro, do fechamento, das
raias e de quem está conectado. O minigame escreve só estes (todos
opcionais, menos `montar`, `jogar` e `robo`):

| gancho | quando | o que faz |
| --- | --- | --- |
| `montar()` | ao entrar | o cenário, com peças do kit ([11](../11-arte-e-personagens.md#as-regras-de-coerência)); a câmera (`camera_pos`, `camera_olhar`); `raia(l)` e `posicionar(l)` de cada lugar |
| `iniciar_jogo()` | a fase jogo começou (a faixa já está tocando do zero) | as primeiras notas (`nova_nota`), a partir do tempo `BATIDA_DA_PRIMEIRA_NOTA` (4): os quatro primeiros são a contagem de entrada (H06) |
| `jogar(dt)` | a cada quadro da fase jogo | lê a entrada (`Forja.apertou`, `Forja.eixo`…), chama `julgar_toque` no toque e `nota_perdida` quando a nota passou; mexe o mundo **pela batida** (`Ritmo.batida()`), nunca somando `dt` |
| `toque(l, julgamento)` | um toque julgado BOM, OTIMO ou PERFEITO | a consequência no mundo e os pontos (`marcar(l, n)`) |
| `falha(l)` | um toque ERRO ou uma nota perdida | a falha física |
| `vencedor()` | no fim | os lugares na ordem de colocação (padrão: pelos pontos) |
| `robo(l, dt)` | a cada quadro, antes de `jogar`, para cada lugar em jogo e conectado | o jogo do robô, **só pelo controle simulado** |

O que o kit dá para usar (não reescreva):

| do kit | para quê |
| --- | --- |
| `RAIAS`, `Z_JOGADOR` | onde fica cada lugar (não redeclare: é erro de análise) |
| `raia(l) -> Node3D`, `acender_raia(l, forca)`, `posicionar(l)` | a laje, a borda na cor do lugar, a luz da vez; o boneco nela |
| `conectado(l)`, `presentes()`, `na_raia(l)` | quem tem controle, quem joga, e a guarda da `dica`/`status` |
| `julgar_toque(l, t_alvo, n := -1, perigo := false) -> int` | o julgamento do toque de agora; `perigo`: a folga de quem está em último |
| `nota_perdida(l, n)`, `nova_nota(l, n, t_alvo)` | o registro da nota e do erro sem toque |
| `falar(l, evento) -> bool` | a fala do cavaleiro, uma a cada 20 s por lugar |
| `Ritmo.t_da_batida(n)`, `Ritmo.batida()`, `Ritmo.t_musica()`, `Ritmo.simples[l]` | o tempo das notas, e a partitura mais simples de quem está errando |
| `marcar(l, n)`, `pontos`, `acabou`, `jogando`, `treinando`, `variante`, `rng` | o de sempre da `SalaJogo` |

O minigame **não** escreve `_init()` (se escrever, a primeira linha é
`super()`, senão a FICHA não é lida), não redeclara `RAIAS`, e não sobrescreve
`comecar`, `terminar`, `sair`, `congelar` nem `_process` (são do kit).

## O robô

- **`Forja.robo` só aparece aqui**, na primeira linha do gancho:
  `if not Forja.robo: return`. Fora dele o jogo não sabe que é robô
  ([a paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)).
- **Só pelo controle simulado:** `Forja.robo_apertar`, `robo_eixo`,
  `robo_girar`, `robo_tocar`, `robo_falar`, `robo_sacudir`. Nunca mexe em
  estado do minigame.
- **O robô erra.** Para cada nota (ou cada decisão), ele consulta
  `Forja.robo_acerta()` (o temperamento `--robo=bom|medio|ruim`, F09) uma
  vez; quando não acerta, aperta atrasado ou não aperta. O
  `godot/testes/minigame_de_prova.gd` mostra o jeito:

  ```gdscript
  if _robo_nota[l] != n:
  	_robo_nota[l] = n
  	_robo_mira[l] = 0.0 if Forja.robo_acerta() else 0.25   # 250 ms atrasado: erro
  if Ritmo.t_musica() >= Ritmo.t_da_batida(n) + float(_robo_mira[l]):
  	Forja.robo_apertar(l, Forja.CRUZ, 0.05)
  ```

- **O robô mira pelo relógio da música**, não por `dt`: com `--fixed-fps 60`
  sem janela, o jogo anda muito mais depressa que a música.

## Os casos que quebram jogo

Todo minigame aguenta, sem mudar a regra:

- **1, 2, 3 e 4 jogadores.** Tudo passa por `jogadores` e `presentes()`;
  nada supõe quatro. O `2v2` com três ou menos diz no cabeçalho o que muda
  (e a `com_poucos()` da `SalaJogo` diz em poucas palavras para o aviso).
- **Um controle que cai no meio** (o cabo que sai; na prova,
  `Forja.ctl.simulador_cabo(sim, false)`): a nota de quem está sem controle
  **não** vira erro, o minigame segue sem ele, e quando o controle volta a
  nota da vez é a próxima que ainda não passou (o `_fora` do minigame de
  prova).
- **A pausa**: o kit congela o jogo e o relógio juntos; o minigame não faz
  nada.
- **O treino**: julga igual, não soma (é o `marcar()`).

## O registro

O kit grava sozinho: a `nota` (`nova_nota`), o `toque` (com o julgamento e o
desvio, ou `perdida`), o `minigame` `comecou` e `terminou` — sempre com
`vencedor` — e o `desempenho` (fps mínimo e médio da fase jogo). O minigame
grava só o que "O registro mede" pede da seção dele, com `Forja.evento(...)`
ou pelas medidas do núcleo (`Forja.med_*`), num tipo que já esteja na
[tabela do registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07)
(tipo novo: acrescente lá no mesmo commit).

## A prova

- Uma checagem nova em `godot/testes/prova_do_jogo.gd`, no padrão
  `_esperar(cond, "mensagem")`: o minigame abre pelo catálogo
  (`jogo._entrar_na_sala("S02_J07", false)`), o aviso passa, o robô joga
  até o fim (espere a fase `jogo` pelo relógio de parede, com limite), o
  `minigame` `terminou` tem `vencedor`, e o que só este minigame faz
  (a saída que chegou ao controle certo, o julgamento que o robô mirou).
- `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` passam, e a
  prancha da prova visual foi **olhada** (o minigame aparece nas partidas
  com quatro, com dois, com um jogador e com o cabo que cai).

## A régua, antes do commit

1. Alguém que nunca jogou entende o que fazer só com o título, o verbo e o
   ícone?
2. Sem a tela, dá para jogar só com o controle? (Nos minigames em que a
   feature é a pista.)
3. O minigame pergunta ao jogador se o controle funcionou? Se sim, volta para
   o Modo bancada.
4. Todo objeto novo passa no checklist de arte de
   [11](../11-arte-e-personagens.md#o-checklist-de-aprovação)?

## Pronto quando

O minigame joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô
nos três temperamentos; aguenta o cabo que cai e volta; fecha sempre com
vencedor; a prova do jogo passa; e **`bash tests/prova_visual.sh` passa com
a prancha olhada** — nenhum minigame fecha só com fotos.
