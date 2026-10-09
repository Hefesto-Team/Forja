# P1 — A Voz

**Sprint:** P · **Slot:** S08_J36 · **Tamanho:** G · **Depende de:** H04, H08, F01, F04, F05, F06, F09, H06, H07, G04, G05, G08, G10, G12, G13, G14, G15

## Por quê

A Voz de hoje (`godot/scripts/salas/voz.gd`) é uma medida do microfone com cara de jogo. O silêncio, o chamado, o
mudo e a pergunta da luz vêm um de cada vez, sem tempo de música. A Voz nova é a mesma cripta tocada no tempo da
faixa. Cada um chama o guardião na sua vez. Depois os quatro sopram juntos a forja nos tempos da respiração dele. O
guardião ruge duas vezes: o meio rugido avisa, e o rugido joga para trás quem não ficou mudo. É o primeiro minigame
da seção: muda a sala para o kit e cria o que P2 a P5 usam (o ouvido, o cenário comum e a escuta da música).

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o que o kit dá pronto)
- [`godot/scripts/salas/voz.gd`](../../../godot/scripts/salas/voz.gd) (inteiro: esta ficha o desmonta; a bancada
  copia partes dele)
- [O índice da seção](P-a-voz.md) (o que fica fora destas fichas). Onde o índice diverge desta ficha (a
  `MARGEM_AR` 0,12, a luz da casa, o verbo «Silêncio!»), vale esta ficha.

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG) já está copiado nesta ficha, com os
números. Não abra outro documento.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/s08/a_voz.gd` | novo: o minigame | só desta |
| `godot/scripts/minigames/s08/ouvido.gd` | novo: o ouvido da seção (a voz, os 6 dB, o mudo, a escuta) | **da seção**: a P1 cria; P2 a P5 só chamam, nenhuma reescreve |
| `godot/scripts/minigames/s08/cenario_da_voz.gd` | novo: o cenário comum da seção | **da seção**: a P1 cria; P2 a P5 só chamam |
| `godot/scripts/musica.gd` | `escuta()`, `ESCUTA_DB`, a faixa de reserva `"sopro"` e `SALA_DA_SECAO[8]` | **de todos**: se outra ficha já pôs `escuta()`, não escreva de novo |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO` e a função `momento()` | **de todos**: se a L1 ou outra ficha já pôs, não escreva de novo |
| `godot/scripts/minigames/catalogo.gd` | `S08_J36` em `MINIGAMES` e em `SECOES`; sai `"voz"` de `SALAS_ANTIGAS` | **da seção**: P2 a P5 acrescentam uma linha cada |
| `godot/scripts/traducoes.gd` | `"A Voz"`, `"Chame a forja!"`, `"Sopre!"`, `"Mudo, sussurre baixinho"` | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_a_voz()` e a chamada no percurso | **de todos** |
| `docs/jogo/13-arquitetura.md` | a linha `momento` na tabela «Os eventos do jogo» | **de todos**: se já existe, não escreva de novo |
| `godot/scripts/salas/voz.gd` e `.uid` | `git rm` | só desta |
| `godot/scripts/main.gd` | sai a linha 19 (`"voz": preload("res://scripts/salas/voz.gd")`) se a H04 ainda não a tirou | **de todos** |

Os três `.uid` novos (`a_voz.gd.uid`, `ouvido.gd.uid`, `cenario_da_voz.gd.uid`) saem do import
`"$GODOT" --headless --path godot --import --quit` e entram no commit.

### O que muda de hoje

Hoje a Voz anda por estados (`SILENCIO`, `CHAMADO`, `MUDO`, `SUSSURRO`, `LUZ`, `ESPERA`, `SUSTO`), um de cada
vez, pelo relógio do sistema. A Voz nova anda pela batida: o chamado em hoqueto, o sopro de todos, o meio rugido e
o rugido. A música baixa 12 dB sempre que um microfone escuta. O sussurro e a pergunta da luz ficam só no Modo
bancada, depois do fim da faixa.

### O kit que esta ficha usa

As funções que a H04 e a H08 deixam no `Minigame` (não reimplemente):

```gdscript
presentes() -> Array; conectado(l) -> bool; na_raia(l) -> bool; raia(l) -> Node3D; jogador(l)
acender_raia(l, forca); posicionar(l)          # posicionar põe o boneco na raia, de mãos livres
nova_nota(l, n, t_alvo, perigo := false); notas_em_aberto(l) -> Array; alvo_da(l, n) -> float
julgar_nota(l, n) -> int; notas_perdidas(l) -> Array   # a cada quadro: a nota que passou vira erro
anotar(tipo, l, campos := {}); andamento() -> float (0..1); no_pico() -> bool; marcar(l, pontos); aprendeu(l)
const RAIAS := [-6.0, -2.0, 2.0, 6.0]; const Z_JOGADOR := 1.4; const FOLGA_PERDIDA := 0.140
const BATIDA_DA_PRIMEIRA_NOTA := 4
var rng; var treinando; var jogadores; var pontos; var coop_venceu; var jogando; var acabou; var duracao
```

Do `Forja` e do `Ritmo`:

- `Forja.sentir(l, nome, ms := -1)` (F05: `toque`, `acerto`, `perfeito`, `erro`, `aviso`, `explosao`);
  `Forja.textura(l, material, forca) -> bool` (H07);
- `Forja.led_mic(l, modo) -> bool` (0 apagado, 1 aceso, 2 piscando, 3 piscando lento);
  `Forja.som_tem(l, Forja.PAPEL_MICROFONE)`; `Forja.som_mic(l)` (`nivel` e `pico` de 0 = −54 dB a 1 = 0 dB, e
  `quadros`); `Forja.som_falante(l, som, ganho) -> int` (−1 quando não toca);
- `Forja.apertou(l, botao)`, `Forja.MICROFONE` (15), `Forja.gatilhos_off(l)`, `Forja.percepcao(l)` (`led_mic`,
  `forte`, `fraco`, `luz`);
- `Forja.robo_falar(l, nivel, s)`, `Forja.robo_apertar(l, botao, s)`, `Forja.robo_acerta()` (F09: `bom` 95 %,
  `medio` 66 %, `ruim` 30 %); `Forja.mic_veredito`, `Forja.cega_veredito`, `Forja.cega_decidida`;
- `Ritmo.t_musica()`, `Ritmo.batida()`, `Ritmo.t_da_batida(b)`, `Ritmo.bpm`, `Ritmo.simples[l]`,
  `Ritmo.desvio[l]`, `Ritmo.PERFEITO`, `Ritmo.ERRO`, `Ritmo.calada()`.

Do G03: `Itens.antecipacao_s(l, bpm)` (a Lanterna) e `Itens.resiste_a_empurrao(l)` (a Âncora: 0,5 ou 1,0). Dos
efeitos: `Efeitos.faiscas(pai, pos, cor, n, forca)`, `Efeitos.anel(pai, pos, cor, raio, virado_para)`,
`Efeitos.poeira(pai, centro, tam, cor, n)`.

### A função `momento` (em `minigame.gd`, de todos)

O tipo `momento` é o da [régua da diversão](../diversao/README.md#4-um-momento-de-grito-com-nome). Se a L1 (ou
outra ficha) ainda não o pôs, acrescente `"momento"` ao fim de `TIPOS_DO_JOGO` e isto ao fim do arquivo:

```gdscript
## Um momento de grito (docs/jogo/diversao/README.md, itens 4 e 8): a linha
## `momento` com o nome, o tempo de música e onde o objeto dele está na tela
## (x_tela e altura_tela, de 0 a 1). `l` é -1 quando o momento é de todos.
func momento(nome: String, l: int, pos: Vector3, altura_m: float, campos := {}) -> void:
	var c: Dictionary = campos.duplicate()
	c["nome"] = nome
	c["t_musica"] = snappedf(Ritmo.t_musica(), 0.001)
	var cam := get_viewport().get_camera_3d()
	var tam := get_viewport().get_visible_rect().size
	if cam and tam.y > 0.0:
		var base := cam.unproject_position(pos)
		var topo := cam.unproject_position(pos + Vector3.UP * altura_m)
		c["x_tela"] = snappedf(base.x / tam.x, 0.001)
		c["altura_tela"] = snappedf(absf(base.y - topo.y) / tam.y, 0.001)
	anotar("momento", l, c)
```

No [13](../13-arquitetura.md), na tabela «Os eventos do jogo», depois da linha `estacao` (se ainda não existe):
`| \`momento\` | o momento de grito do minigame: \`nome\`, \`t_musica\`, \`x_tela\` e \`altura_tela\` (0 a 1); \`lugar\` 0 quando é de todos (docs/jogo/diversao/README.md) |`.

### A escuta da música (em `musica.gd`, de todos)

O [mapa do áudio](../audio/mapa.csv) pede, nas cinco faixas da seção: «o microfone ouve a sala: −12 dB enquanto
ele escuta». A escuta mora na `Musica`, porque só ela sabe qual tocador está ativo. Acrescente, depois de `FADE_S`:

```gdscript
## O microfone ouve a sala (docs/jogo/audio/mapa.csv, a seção A Voz): a música
## desce 12 dB enquanto algum microfone escuta, entra em 1 quadro e sai em 0,3 s.
const ESCUTA_DB := -12.0
const ESCUTA_ENTRA_S := 0.017
const ESCUTA_SAI_S := 0.3
var _tw_escuta: Tween = null
var _escutando := false


## Liga ou desliga a escuta (o ouvido da S08 chama). Com a música calada
## (Ritmo.calar), não mexe: o silêncio já é o silêncio.
func escuta(ligada: bool) -> void:
	if ligada == _escutando:
		return
	_escutando = ligada
	if Ritmo.calada():
		return
	if _tw_escuta:
		_tw_escuta.kill()
	_tw_escuta = create_tween()
	_tw_escuta.tween_property(_tocadores[_ativo], "volume_db", VOLUME_DB + (ESCUTA_DB if ligada else 0.0),
		ESCUTA_ENTRA_S if ligada else ESCUTA_SAI_S)
```

Em `tocar_do_zero`, logo antes de `atual = slot`: `_escutando = false` e `if _tw_escuta: _tw_escuta.kill()`.

**A faixa de reserva da seção.** Hoje `SALA_DA_SECAO[8]` é `"voz"`, e `FAIXAS["voz"]` é `[]` (o silêncio do
`Musica.calar()`). Sem o `.ogg` da H05 (a pasta `godot/assets/ost/S08/` está vazia), os cinco minigames da seção
tocariam em silêncio, e o `mapa()` daria 120 bpm. Acrescente `"sopro": [62, 105, 1]` em `FAIXAS` (Ré, 105 bpm,
energia 1, a faixa da P1) e troque `SALA_DA_SECAO[8]` de `"voz"` para `"sopro"`. O `"voz": []` fica: é o `calar`.
Até a H05, as P2 a P5 tocam a reserva a 105 bpm. Todas contam por batida e por `B_FIM`, então nada quebra.

## Como se joga

### A ficha de dados

```gdscript
extends Minigame
## A Voz (S08_J36) — o guardião da cripta escuta pelo microfone do controle.
## Cada um o chama na sua vez (os outros fazem eco); depois os quatro sopram
## juntos a forja nos tempos da respiração dele. Ele ruge duas vezes: o meio
## rugido avisa; o rugido joga para trás quem não está mudo (o Botão do
## microfone é o escudo, e a luz dele acende).
##
## A falha: a voz fora de toda nota espalha cinza (a chama desce, o cavaleiro
## tosse); o rugido senta no chão quem não ficou mudo.
## O vencedor: coop (a forja acende); o destaque é o pulmão mais afinado.
## O alto-falante do dono: o sino do aviso, o grito do rugido, a nota do perfeito
## (fora da escuta).
## O registro mede: a voz de cada controle (`voz`), as notas de voz e de botão,
## a luz do mudo (`saida` led_microfone), os momentos `meio_rugido`, `reta` e
## `rugido`; na bancada, os três vereditos.
## O robô: fala pelo controle simulado (0,8 por 0,3 s) e aperta o mudo no tempo.
## Com menos de quatro: o chamado gira por quem está; a conta da chama usa `np`.
## A régua: (1) "Chame a forja!" e o ícone do microfone; (2) sim: o guardião
## respira no tempo; (3) não pergunta nada fora da bancada.

const FICHA := {
	"slot": "S08_J36",
	"titulo": "A Voz",
	"verbo": "Chame a forja!",
	"genero": "coop",
	"icone": "microfone",
	"entradas": [Forja.MICROFONE],
	"camera": "fixa",
	"faixa": "MUS_S08_J36",
	"duracao": 80.0,
	"fim": "tempo",
	"sensacoes": ["toque", "aviso", "explosao", "erro"],
	"material": "pedra",
	"microjogo": {"verbo": "Sopre!", "segundos": 6.0},
	"papel_som": Forja.PAPEL_MICROFONE,  # o kit abre o microfone no entrar() (H08)
	"textura_no_acerto": false,  # o minigame toca a textura fora da escuta (O controle)
	"nota_no_falante": false,  # o alto-falante não toca enquanto o microfone escuta
	# o que a bancada mede (o veredito é do núcleo, como hoje)
	"features": ["microfone", "microfone_mudo", "led_microfone"],
	"botoes_medidos": [Forja.MICROFONE, Forja.CRUZ, Forja.CIRCULO, Forja.QUADRADO],
	"gesto": "interact-right",
	"treino": false,  # o chamado ensina
}

const Ouvido := preload("res://scripts/minigames/s08/ouvido.gd")
const PONTOS := [0, 50, 75, 100]  ## ERRO, BOM, OTIMO, PERFEITO
const PESO := [0.0, 0.6, 0.8, 1.0]  ## o quanto cada sopro sobe a chama
const COMPASSOS_DO_CHAMADO := 11  ## o chamado: batidas 4 a 47
const PICO_DE := 16  ## o pico do sopro: de _c0 + 16 a _c0 + 31 (64 a 79 a 105 bpm)
const PICO_ATE := 31
const CINZA := 0.3  ## a voz fora de nota tira 0,3 sopro da chama
const CINZA_RETA := 0.6  ## na reta, o dobro
const SOZINHO_PONTOS := 25  ## sem microfone (ou mudo esquecido): o sopro sozinho
const SOZINHO_PESO := 0.4
const RECUO_M := 0.6  ## o rugido joga 0,6 m para trás
const SENTADO_TEMPOS := 2.0  ## e o cavaleiro fica sentado 2 batidas
const TOSSE_TEMPOS := 1.0  ## a cinza: tosse 1 batida (a queda da P1)
const NUCA_GRAUS := 25.0  ## a cabeça vai para trás 25° no rugido
const ATRASO_ROBO := 0.35  ## o mudo do robô que erra: 0,35 s tarde
const ATRASO_ROBO_RUGIDO := 0.65  ## na nota de B_FIM - 9, tarde o bastante para levar o rugido
const BANCADA_S := 40.0  ## a bancada acontece depois da faixa: até 40 s a mais (o teto é 120)
const GUARDIAO := Vector3(0.0, 3.05, -3.0)  ## o pivô da cabeça; de pé, sobe a 4,1
const ALTAR := Vector3(0.0, 0.0, -1.2)
```

`duracao` 80 é o fim da faixa (`B_FIM` = 140 a 105 bpm). Com `Forja.bancada`, o `montar()` soma `BANCADA_S`:
`duracao = minf(duracao + BANCADA_S, 120.0)`. A bancada fecha antes, quando todos respondem (`acabou[l] = true`).
Sem treino: o chamado ensina, e quem chama errado só perde os pontos daquela nota.

Do `voz.gd` de hoje continuam, **iguais** e só para a bancada: `SUSSURRO_S`, `LUZ_ESPERA`, `LUZ_MAX`,
`LUZ_REVELA`, `LUZ_RODADAS`, `NOME_LUZ`, `BOTAO_LUZ`, `GLIFO_LUZ` e o `enum { OLHAR, REVELA_LUZ, FIM_LUZ }`
(linhas 26 a 35 e 42). Saem:

- `F` (use `Forja`), `RAIAS` e `Z_JOGADOR` (são do kit);
- `SILENCIO_S`, `CHAMADO_MAX`, `MUDO_MAX`, `ESPERA_S` e `SUSTO_S`;
- `VOZ_ACIMA` (vai para o ouvido);
- o `enum` de estados (o tempo agora é da música).

### Os números de 105 bpm

Uma batida dura 60 / 105 = 0,5714 s. `B_FIM = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))` = 140 (80 s).
Os terços do kit caem nas batidas 47 e 93. **Tudo depois do chamado conta de `B_FIM`**, para que a mesma partitura
caiba noutro andamento: a 120 bpm, sem a reserva, `B_FIM` = 160, e o sopro só fica mais longo.

`_c0 = BATIDA_DA_PRIMEIRA_NOTA + 4 * COMPASSOS_DO_CHAMADO` = 48.

### A linha do tempo

| batidas (a 105 bpm) | relativo | o que acontece |
| --- | --- | --- |
| 0–3 | — | a contagem (H06): ninguém sopra; o ouvido mede o piso de cada microfone |
| 4–47 | `4` a `_c0 − 1` | **o chamado**: no compasso `k` (batidas `4 + 4k` a `4 + 4k + 3`), o dono é `ordem[k % np]`; ele chama em `+0` e `+2`; os outros fazem eco em `+3` |
| 48–91 | `_c0` a `B_FIM − 49` | **o sopro**: todos em `+0` e `+2` de cada compasso; **o pico** de `_c0 + 16` a `_c0 + 31` (64–79): em toda batida |
| 92–104 | `B_FIM − 48` a `B_FIM − 36` | o sopro nas batidas pares (7 notas) |
| 104 | `B_FIM − 36` | os olhos do guardião abrem (1 batida); o ícone `@mic` pisca sobre as cabeças até 108 |
| 106 | `B_FIM − 34` | o sino `pronto` no alto-falante de cada um (500 ms); **o escudo** vale de 106 a 113 (quem já está mudo em 106 ganha o escudo) |
| 107 | `B_FIM − 33` | **a nota do mudo** (botão), para quem ainda não está mudo |
| 108 | `B_FIM − 32` | **o meio rugido**: a boca abre 0,25 m, o degrau golpe, o `aviso` na mão de quem não está mudo; ninguém sai do lugar |
| 112 | `B_FIM − 28` | **o alívio**: a nota do botão para quem está mudo (desligar) |
| 113 | `B_FIM − 27` | o escudo acaba: quem segue mudo fica com a luz 2 (piscando) e sopra sozinho |
| 114–122 | `B_FIM − 26` a `B_FIM − 18` | o sopro nas pares (5 notas); quem segue mudo tem a nota da volta (botão) em 114 e 122 |
| 124 | `B_FIM − 16` | **a reta**: `momento("reta")`; a cinza tira o dobro |
| 124, 126, 128 | | o sopro |
| 128 | `B_FIM − 12` | o ícone `@mic` pisca de novo até 132 |
| 130 | `B_FIM − 10` | o sino; o guardião **fica de pé** em 1 batida; o escudo vale de 130 a 137 |
| 131 | `B_FIM − 9` | a nota do mudo |
| 132 | `B_FIM − 8` | **o rugido** (75,4 s de música) |
| 136 | `B_FIM − 4` | o alívio |
| 138 | `B_FIM − 2` | o último sopro |
| 140 | `B_FIM` | o fim da faixa: `coop_venceu = _chama >= 1.0`; sem a bancada, o kit fecha no `duracao` |

**A densidade.** Com quatro, no chamado cada lugar tem 5 notas a cada 16 batidas (0,31 por batida: 2 como dono, 3
de eco). No sopro, são 30 notas em 44 batidas (0,68 por batida). A razão é 2,18: o meio é mais denso que o começo
(a régua, item 5). Cada lugar tem **46 sopros** no total (30 + 7 + 5 + 3 + 1).

**A partitura simples** (`Ritmo.simples[l]`): no chamado, o dono só chama em `+0` (o eco fica); no sopro, só `+0`
de cada compasso; no pico, só as batidas pares. Depois de 92, nada muda.

### O ouvido: a voz, os 6 dB e o mudo

O ouvido (`s08/ouvido.gd`; o arquivo inteiro está em «O ouvido inteiro», mais abaixo) lê o microfone de cada
controle a cada quadro e chama de volta o minigame:

- `_comecou(l)`: a voz do lugar começou. O começo vale quando o nível passa de `piso + 0,30` **e** fica a até 6 dB
  (0,111 na escala) do microfone mais alto entre os que ouvem. É a regra dos 6 dB: a risada de um vaza para os
  quatro microfones, mas só conta para quem riu mais alto (e para quem está a 6 dB dele, como quatro sopros juntos).
- `_parou(l)`: o nível caiu abaixo de `piso + 0,18`.
- `_mudou(l, mudo)`: o Botão do microfone. O mudo é contado **por paridade**: o 1.º aperto liga, o 2.º desliga.

A Voz casa a voz em `_comecou(l)`:

1. `var n := ouvido.casar_voz(l)` acha a nota de voz em aberto mais perto, a até 0,25 s.
2. Com `n >= 0`, `julgar_nota(l, n)`.
3. Sem nota, de `_c0` a `B_FIM`, fora da tosse, é **a cinza**. Antes de `_c0`, a voz fora de nota é ignorada: o
   chamado é para aprender.

A cada quadro, `notas_perdidas(l)` fecha as que passaram.

### O chamado (4 a 47)

O dono do compasso chama duas vezes; os outros respondem no tempo 4. O braseiro do dono acende a 0,9 m na pista
(abaixo). Os olhos do guardião abrem um pouco a cada chamado certo: o `scale.y` dos olhos sobe 0,02 por acerto, de
0,15 até 0,5, e a energia deles vai de 0 a 0,6 (o teto do mundo é 1,2). A chama do altar não sobe no chamado: só os
pontos.

### O sopro (48 a 139)

Cada nota certa sobe a chama da forja coletiva: `_chama += PESO[julgamento] / _den`, com `_den = 0.6 * S * np`.
`S` são os sopros de cada lugar, contados da partitura no `iniciar_jogo()`: 46 a 105 bpm. Quatro lugares que sopram
tudo no BOM acendem a forja no último sopro. `_chama` fica entre 0 e 1,0; quando chega a 1,0 a primeira vez, a
forja acende (abaixo).

**A pista** de cada sopro: a chama do braseiro do lugar salta para 0,9 m por 1 colcheia em
`Ritmo.t_da_batida(bn - 1) - CenarioDaVoz.antecedencia(l)` (o Faro e a Lanterna).

**A cinza** é a voz fora de toda nota, de `_c0` a `B_FIM`:

- `_chama -= CINZA / _den` (`CINZA_RETA` de `B_FIM − 16` em diante), nunca abaixo de 0;
- o braseiro cospe `Efeitos.poeira(self, b.base + Vector3(0, 0.6, 0), Vector3(0.6, 0.6, 0.6), Tema.OXIDO, 16)`;
- o cavaleiro tosse: `emote-no` por `CenarioDaVoz.queda_s(l, TOSSE_TEMPOS)`, e a voz dele é ignorada nesse tempo
  (`ouvido.surdo_ate[l] = Ritmo.t_musica() + queda`);
- `Som.tocar("sopro", b.base, -10.0)`;
- o registro: `anotar("entrada", l, {"o": "cinza"})`.

**O sopro sozinho** vale para `ouvido.sozinho(l)`: sem microfone, mudo no sistema, ou mudo fora do escudo. Na
batida de cada sopro dele, sem nota, `marcar(l, SOZINHO_PONTOS)` e `_chama += SOZINHO_PESO / _den`. O braseiro dele
acende a metade (0,45 m) por 1 colcheia.

### O mudo, o meio rugido e o rugido

**As notas do botão** são notas como as de voz, só que casadas pelo aperto. Abrem 1 batida antes com
`nova_nota(l, n, Ritmo.t_da_batida(bn))`, sem a latência do microfone. No `_mudou(l, mudo)`, a nota de botão em
aberto mais perto, a até 0,5 s, é julgada (`julgar_nota`). O aperto **sempre** muda o mudo (a paridade), julgado
certo ou não: o ERRO só tira os pontos.

| nota | batida | para quem abre | o que o aperto faz |
| --- | --- | --- | --- |
| o mudo | `B_FIM − 33` (107) e `B_FIM − 9` (131) | quem não está mudo 1 batida antes | liga o mudo dentro do escudo: luz 1 (acesa) |
| o alívio | `B_FIM − 28` (112) e `B_FIM − 4` (136) | quem está mudo 1 batida antes | desliga: luz 0 |
| a volta | `B_FIM − 26` (114) e `B_FIM − 18` (122) | quem segue mudo depois do escudo | desliga: luz 0, e a voz volta a contar |

A nota do botão que passa sem aperto vira `nota_perdida`: o braseiro pisca e o cavaleiro faz `emote-no` 0,4 s (o
`falha`).

**O escudo** (`ouvido.proteger(l, true)`) vale de `B_FIM − 34` a `B_FIM − 27` e de `B_FIM − 10` a `B_FIM − 3`.
Quem está mudo dentro dele tem a luz 1 (acesa: o escudo) e não sopra sozinho. Quem fica mudo fora dele tem a luz 2
(piscando: o mudo esquecido) e sopra sozinho. Quem aperta o mudo noutra hora qualquer também fica com a luz 2.

**O meio rugido** (`B_FIM − 32`):

- a boca do guardião abre 0,25 m em 1 colcheia e fecha em 1 batida;
- `CenarioDaVoz.exagero(self, _cenario, "golpe")`;
- `Som.tocar("grito", GUARDIAO, -8.0)` na TV;
- `ouvido.sentir(l, "aviso")` em quem não está mudo;
- `momento("meio_rugido", -1, Vector3(0, 0, -3.0), 4.75)`.

Ninguém sai do lugar: é o ensaio.

**O guardião de pé** (`B_FIM − 10`): a cabeça sobe de 3,05 a 4,1 e o tronco aparece (`scale.y` de 0 a 1) em 1
batida, curva `ENTRA`. Fica de pé até o fim.

**O rugido** (`B_FIM − 8`), tudo no mesmo quadro:

- `momento("rugido", -1, Vector3(0, 0, -3.0), 4.75, {"caiu": "P2,P4"})`, com os lugares que caíram (`""` se
  ninguém caiu);
- `CenarioDaVoz.exagero(self, _cenario, "catastrofe")`: o tremor de 0,08 m por 4 batidas e a chave +40 % por 1
  batida;
- a boca abre 0,5 m em 1 colcheia e fica aberta 2 batidas; o foco vai a 4,0 por 1 batida;
- na TV: `Som.tocar("grito", GUARDIAO, 0.0)` e `Som.tocar("martelo", GUARDIAO, 2.0)`;
- quem **não** está mudo (conectado, com ou sem microfone):
  - `ouvido.sentir(l, "explosao")` e `ouvido.falante(l, "grito", 0.8, 900)`;
  - `_derrubar(l)` (O cavaleiro): para trás `RECUO_M × Itens.resiste_a_empurrao(l)` m, `sit` e a cabeça para trás
    25° pela `queda_s(l, SENTADO_TEMPOS)`;
  - o braseiro dele treme (±0,04 m em x, 12 vezes por segundo, por 2 batidas) e **apaga até o fim** (o rastro);
  - `marcar(l, -50)`;
- quem está mudo: `Efeitos.anel(self, jogador(l).global_position + Vector3(0, 0.1, 0), Tema.JOGADOR[l], 0.9, Vector3.UP)`
  e `ouvido.sentir(l, "toque")` (o escudo segurou).

O rugido não mexe na chama da forja coletiva: só derruba quem esqueceu.

### A reta

Na batida `B_FIM − 16`: `momento("reta", -1, ALTAR, 0.69 + 1.7, {"objeto": "chama", "valores": "%.2f" % _chama})`.
Daí ao fim, a cinza tira o dobro.

### A forja acende

Na primeira vez em que `_chama` chega a 1,0:

- `Efeitos.faiscas(self, ALTAR + Vector3(0, 2.0, 0), Tema.TUNGSTENIO, 60, 1.6)`;
- `Som.tocar("fogo", ALTAR, 0.0)` e `Som.tocar("sucesso", null, -4.0)`;
- os quatro cavaleiros fazem `emote-yes` por 1 batida;
- `anotar("entrada", -1, {"o": "forja_acesa"})`.

A chama fica no máximo até o fim.

### A bancada

Só com `Forja.bancada`, depois de `B_FIM`. O `_bancada_passa(dt)` anda pelo `dt`: é a camada da bancada, não o
ritmo.

1. **O sussurro** (`SUSSURRO_S`, 3,0 s): o jogo liga o mudo de todos (`ouvido.mudo[l] = true`,
   `Forja.led_mic(l, 1)`). A dica é `["@mic", "Mudo, sussurre baixinho"]`. O maior `Forja.som_mic(l).nivel` vai
   para `_mudo_nivel[l]`, e `_viu_mudo[l] = true` depois de 1,0 s.
2. **A luz do microfone:** `_luz_rodada` (`voz.gd:263-276`), `_comecar_luz` (278-288) e `_atualizar_luz` (333-365),
   copiados iguais. Troque `F` por `Forja`, `_conectado` por `conectado` e `estado = LUZ` por `_bancada = LUZ_B`.
3. Quando todos chegam a `FIM_LUZ`, `acabou[l] = true` para todos, e o kit fecha.

`pergunta(l)` é a de hoje (`voz.gd:608-633`), com `estado != LUZ` trocado por `_bancada != LUZ_B`; fora da bancada,
devolve `{}`. `dar_vereditos(l)` é o de hoje (`voz.gd:471-484`), com os dados do minigame:

| dado | de onde vem |
| --- | --- |
| `tem` | `Forja.som_tem(l, Forja.PAPEL_MICROFONE)` no `iniciar_jogo()` |
| `piso`, `viu_piso` | `ouvido.piso[l]` na batida 4; `true` depois da batida 4 |
| `voz` | o maior `ouvido.nivel[l]` nas notas de chamado em que ele era o dono (`_voz_max[l]`) |
| `mudo`, `viu_mudo` | `_mudo_nivel[l]`, `_viu_mudo[l]` (o sussurro) |
| `apertou_mudo` | `ouvido.apertos[l] > 0` |
| `pediu_mudo` | `true` se estava conectado no rugido |
| `quadros` | `Forja.som_mic(l).quadros` menos `_quadros_ini[l]` (o do `montar()`) |
| `mexeu` | `apertou_mudo` ou alguma resposta da luz |

O `led_microfone` usa a `Cega` da luz, e `sdl_aceitou` = alguma `led_mic` devolveu `true` (o escudo do jogo já
conta, F01).

### O fim e o vencedor

Acaba pelo tempo: 80 s de música, ou mais `BANCADA_S` com a bancada, contados pelo kit. É coop: na batida `B_FIM`,
`coop_venceu = _chama >= 1.0`, e o kit grava `vencedor` −1 (H08). O destaque é o pulmão mais afinado (os pontos;
no empate, o lugar menor):

```gdscript
func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return pontos[a] > pontos[b] or (pontos[a] == pontos[b] and a < b))
	return int(lista[0]) if not lista.is_empty() else -1
```

### Com menos de quatro

- **Três, dois:** o chamado gira por `ordem` (`presentes()` em ordem crescente); `_den` usa `np`.
- **Um:** ele é o dono de todo compasso do chamado, sem eco (0,5 nota por batida); a forja é só dele.
  `com_poucos()` devolve `""` (coop: nada a dizer).
- **O controle que cai:** as notas dele não abrem enquanto está fora, e as abertas fecham caladas
  (`notas_perdidas` já devolve `[]` sem controle). O rugido não o derruba. Quando volta, entra na próxima nota.

### Os ganchos

O que muda do `voz.gd` de hoje, na ordem do arquivo:

| hoje | na Voz nova |
| --- | --- |
| `class_name SalaVoz`, `extends SalaJogo`, o cabeçalho | `extends Minigame`, sem `class_name`, o cabeçalho de «A ficha de dados» |
| as constantes de 22 a 42 | as de «A ficha de dados» |
| `estado`, `t_estado`, `vez`, `ordem`, `i_vez`, `olhos`, `grito`, `flash`, `g` | as variáveis do esqueleto abaixo |
| `_init()` | sai (a FICHA; a câmera vai para o `montar`) |
| `montar()`, `_montar_guardiao()`, `_montar_raia()` | o de «A cena» |
| `_novo_jogador()` | sai: o estado da voz é do ouvido; a bancada guarda `_mudo_nivel`, `_viu_mudo`, `_voz_max`, `_quadros_ini` |
| `iniciar_jogo()`, `_mudo_no_sistema`, `_conectado`, `_proxima_vez` | o de baixo (o mudo do sistema é do ouvido) |
| `_luz_rodada`, `_comecar_luz`, `_atualizar_luz`, `pergunta()`, `dar_vereditos()` | ficam, **só na bancada** (A bancada) |
| `_susto()` | `_meio_rugido()` e `_rugido()` |
| `_medir()` | sai: o ouvido mede |
| `jogar()`, `_ir_para_o_mudo()` | o `jogar` de baixo |
| `_process` e `_mostrar` (488 a 543) | `_mostrar(dt)`, chamado do fim do `jogar`: o guardião, as chamas |
| `status()` | `""` quando `na_raia(l)` (a chama mora no altar); senão `super` |
| `progresso()` | sai (a barra de tempo do kit) |
| `dica()` | `{"partes": ["@mic"], "pos": Vector3(RAIAS[l], 2.6, Z_JOGADOR)}` de `B_FIM − 36` a `B_FIM − 32` e de `B_FIM − 12` a `B_FIM − 8`, só na primeira metade de cada batida (pisca a 2 Hz a 105 bpm), e no chamado na vez dele enquanto `not aprendeu(l)`; na bancada, o sussurro; senão `{}` |
| `_robo` | `robo(l, dt)` de «O controle» |
| — | `combo(l)` (G04): `return _perfeitos[l]` |

O esqueleto:

```gdscript
var ouvido: Ouvido
var _cenario := {}
var _g := {}  ## o guardião: {corpo, pivo, cabeca, olhos, mat_olhos, boca, dentes, tronco, foco}
var _c0 := 48
var _b_fim := 140
var _den := 1.0
var _chama := 0.0
var _acesa := false
var _plano := [[], [], [], []]  ## por lugar: [{bn, fase}] em ordem; fase "chamado", "sopro", "mudo", "alivio", "volta"
var _i_plano := [0, 0, 0, 0]  ## a próxima entrada do plano a abrir
var _fase := {}  ## "l:n" -> a fase da nota
var _ultima := ["", "", "", ""]  ## a fase da última nota julgada do lugar
var _n := [0, 0, 0, 0]  ## o próximo n de cada lugar
var _fez := {}  ## as batidas do roteiro já feitas (meio rugido, rugido, reta, sino...)
var _braseiro := {}  ## lugar -> o dicionário de CenarioDaVoz.braseiro
var _nuca := {}  ## lugar -> o modificador da cabeça
var _perfeitos := [0, 0, 0, 0]
var _voz_max := [0.0, 0.0, 0.0, 0.0]
var _mudo_nivel := [0.0, 0.0, 0.0, 0.0]
var _viu_mudo := [false, false, false, false]
var _quadros_ini := [0, 0, 0, 0]
var _bancada := 0  ## 0 o jogo; SUSSURRO_B; LUZ_B; FIM_B
const SUSSURRO_B := 1
const LUZ_B := 2
const FIM_B := 3


func montar() -> void:
	var pose := CenarioDaVoz.pose_da_camera()
	camera_pos = pose[0]
	camera_olhar = pose[1]
	_cenario = CenarioDaVoz.montar(self)
	_g = _montar_guardiao()  # A cena
	_montar_altar()  # A cena
	if Forja.bancada:
		duracao = minf(duracao + BANCADA_S, 120.0)
	for p in jogadores:
		var l: int = p.lugar
		raia(l)
		posicionar(l)
		p.rotation.y = PI  # de costas para a câmera, de frente para o guardião
		p.preso = true
		_braseiro[l] = CenarioDaVoz.braseiro(self, l)
		_nuca[l] = _montar_nuca(p)  # O cavaleiro
		_quadros_ini[l] = int(Forja.som_mic(l).get("quadros", 0))
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	ouvido = Ouvido.new(self)
	ouvido.comecar()
	_b_fim = int(floor(float(FICHA.duracao) * Ritmo.bpm / 60.0))
	_c0 = BATIDA_DA_PRIMEIRA_NOTA + 4 * COMPASSOS_DO_CHAMADO
	_robo_rng.seed = rng.seed + 99
	var ordem := presentes()
	ordem.sort()
	var s := 0
	for l in ordem:
		_plano[l] = _partitura(l, ordem)  # A linha do tempo
		s = maxi(s, _plano[l].filter(func(x): return x.fase == "sopro").size())
	_den = 0.6 * float(maxi(s, 1)) * float(maxi(ordem.size(), 1))


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	if _bancada != 0:
		_bancada_passa(dt)  # A bancada
		_mostrar(dt)
		return
	ouvido.ouvir(dt)  # chama _comecou, _parou e _mudou
	CenarioDaVoz.passar(self, _cenario, no_pico())
	_roteiro(b)  # os olhos, o sino, o escudo, o meio rugido, a reta, de pé, o rugido
	for l in presentes():
		if not conectado(l):
			continue
		_abrir_notas(l, b)  # as de voz e as de botão, 1 batida antes
		_pista(l)
		notas_perdidas(l)
	if b >= _b_fim and not _fez.has("fim"):
		_fez["fim"] = true
		coop_venceu = _chama >= 1.0
		ouvido.fechar()
		if Forja.bancada:
			_bancada = SUSSURRO_B
			_comecar_sussurro()
		else:
			for l in presentes():
				Forja.led_mic(l, 0)
	_mostrar(dt)


func _comecou(l: int) -> void:
	if _bancada != 0:
		return
	var n := ouvido.casar_voz(l)
	if n >= 0:
		julgar_nota(l, n)
	elif Ritmo.batida() >= _c0 and Ritmo.batida() < _b_fim:
		_cinza(l)


func _parou(_l: int) -> void:
	pass  # A Voz não julga o fim da voz


func _mudou(l: int, _mudo: bool) -> void:
	var n := ouvido.casar_botao(l)  # a nota de botão em aberto a até 0,5 s; -1: nenhuma
	if n >= 0:
		julgar_nota(l, n)


func toque(l: int, julgamento: int) -> void:
	marcar(l, PONTOS[julgamento])
	_perfeitos[l] = _perfeitos[l] + 1 if julgamento == Ritmo.PERFEITO else 0
	var fase: String = _ultima[l]  # o julgar_nota guarda: _ultima[l] = _fase["%d:%d" % [l, n]]
	if fase == "sopro":
		_subir(PESO[julgamento] / _den)
	if fase == "chamado" or fase == "sopro":
		_acender(l, 2.6, 4)  # o braseiro: 2,6 por 4 quadros
		jogador(l).gesto("interact-right", 30.0 / Ritmo.bpm)
		var perfeito := julgamento == Ritmo.PERFEITO
		ouvido.depois(l, func():
			if not Forja.textura(l, "pedra", 0.5):
				ouvido.sentir(l, "toque")
			if perfeito:
				ouvido.falante(l, "nota:%d" % l, 0.8, 300))


func falha(l: int) -> void:
	_perfeitos[l] = 0
	_apagar_um_instante(l)  # o braseiro cai a 0,2 m por 1 colcheia
	jogador(l).gesto("emote-no", 0.4)


func _subir(d: float) -> void:
	_chama = clampf(_chama + d, 0.0, 1.0)
	if _chama >= 1.0 and not _acesa:
		_acesa = true
		_forja_acende()  # A forja acende
```

`_partitura(l, ordem)`, `_abrir_notas(l, b)`, `_pista(l)`, `_cinza(l)`, `_roteiro(b)`, `_meio_rugido()`,
`_rugido()`, `_forja_acende()`, `_acender`, `_apagar_um_instante`, `_mostrar(dt)`, `_comecar_sussurro()` e
`_bancada_passa(dt)` fazem o que as partes desta ficha dizem. Três regras valem para todos:

- `_abrir_notas` abre a entrada `_i_plano[l]` do plano quando `b >= bn - 1`, com `n = _n[l]` e
  `_fase["%d:%d" % [l, n]] = fase`. A de voz abre com `ouvido.nova_voz(l, n, bn)` (que soma a `LATENCIA_MIC`). Se
  `ouvido.sozinho(l)`, a de voz não abre: na batida `bn`, o lugar faz o sopro sozinho.
- As notas de botão abrem com `nova_nota(l, n, Ritmo.t_da_batida(bn))`, só para quem cumpre a coluna «para quem
  abre» na hora de abrir.
- `_roteiro(b)` faz cada batida da linha do tempo uma vez só (`_fez[nome] = true`), pela batida, nunca pelo `dt`.

O `julgar_nota` do kit chama `toque` ou `falha`. Antes dele, a Voz guarda a fase: troque as duas chamadas de
`julgar_nota(l, n)` por `_julgar(l, n)`, que faz `_ultima[l] = _fase.get("%d:%d" % [l, n], "")` e depois
`julgar_nota(l, n)`.

O catálogo:

- `Catalogo.MINIGAMES["S08_J36"] = preload("res://scripts/minigames/s08/a_voz.gd")`;
- na seção `S08` de `SECOES`, `"minigames": ["S08_J36"]`;
- sai `"voz"` de `SALAS_ANTIGAS`.

A limpeza: `git rm godot/scripts/salas/voz.gd godot/scripts/salas/voz.gd.uid`; tire a linha 19 de `main.gd` se a
H04 ainda não tirou. Confira com `grep -rn "salas/voz.gd\|SalaVoz" godot/`: tem que sair vazio. O id `"voz"` como
apelido (`salao.gd:21`, `partida.gd:28`) fica.

As traduções, em `godot/scripts/traducoes.gd` (as que ainda não existirem): `"A Voz": "The Voice"`,
`"Chame a forja!": "Call the forge!"`, `"Sopre!": "Blow!"`, `"Mudo, sussurre baixinho": "Muted, whisper softly"`.
Tire as frases que só a sala de hoje usava (`acao`, `objetivo`, «Mudo», «…»).

### O ouvido inteiro (`godot/scripts/minigames/s08/ouvido.gd`)

```gdscript
extends RefCounted
## O ouvido da seção A Voz (S08, docs/jogo/tarefas/P-a-voz.md): o mesmo nas
## cinco fichas. Lê o microfone de cada controle, acha o começo e o fim da voz
## de cada lugar pela regra dos 6 dB (a voz de um não conta para os outros),
## conta o mudo por paridade, abaixa a música enquanto algum microfone escuta
## e grava a troca para o "sem microfone". Uso: const Ouvido := preload(...);
## ouvido = Ouvido.new(self) no iniciar_jogo(); ouvido.ouvir(dt) a cada quadro.
## O minigame tem _comecou(l), _parou(l) e _mudou(l, mudo).

const VOZ_ACIMA := 0.30  ## o começo: o nível 0,30 acima do piso (0 = -54 dB, 1 = 0 dB)
const VOZ_FICA := 0.18  ## quem já fala segue falando até cair abaixo de piso + 0,18
const SEIS_DB := 6.0 / 54.0  ## 6 dB na escala do nível (0,111)
const LATENCIA_MIC := 0.08  ## o nível sobe 80 ms depois da voz
const SURDO_FOLGA := 0.05  ## o alto-falante cala e o microfone ainda ouve o eco por 50 ms
const MUDO_NO_SISTEMA := 0.001  ## quem nunca passou disto até a batida 4 tem o mudo do sistema
const BATIDA_DO_SISTEMA := 4.0
const ALCANCE_DO_BOTAO := 0.5
const LEVES := ["toque", "toque_esq", "toque_dir"]  ## a vibração que pode cair na escuta

var mg: Minigame
var nivel := [0.0, 0.0, 0.0, 0.0]
var piso := [0.0, 0.0, 0.0, 0.0]
var falando := [false, false, false, false]
var pico := [0.0, 0.0, 0.0, 0.0]
var maior_nivel := [0.0, 0.0, 0.0, 0.0]
var apertos := [0, 0, 0, 0]
var mudo := [false, false, false, false]
var escudo := [false, false, false, false]
var sem_mic := [false, false, false, false]
var motivo := ["", "", "", ""]
var escuta := [false, false, false, false]
var segura := [false, false, false, false]  ## a escuta aberta pelo minigame (o silêncio da P3)
var surdo_ate := [-1.0, -1.0, -1.0, -1.0]
var abaixa := true  ## a música desce na escuta (a P3 desliga: o silêncio já é dela)
var janela_casa := 0.25  ## até onde um começo de voz casa com a nota (e a escuta abre antes do alvo)
var _voz_da_nota := {}  ## "l:n" -> true: a nota é de voz
var _primeiro := [false, false, false, false]
var _medido := [false, false, false, false]
var _alguma_escuta := false
var _trocas := {}
var _depois := [[], [], [], []]


func _init(minigame: Minigame) -> void:
	mg = minigame


## A regra dos 6 dB: o lugar `l` conta quando passa do piso dele e fica a até
## 6 dB do mais alto dos `ouvidos` (os lugares que ouvem agora).
static func conta(niveis: Array, pisos: Array, l: int, ouvidos: Array) -> bool:
	if float(niveis[l]) < float(pisos[l]) + VOZ_ACIMA:
		return false
	var mais := 0.0
	for o in ouvidos:
		mais = maxf(mais, float(niveis[o]))
	return float(niveis[l]) >= mais - SEIS_DB


## No começo do jogo: as luzes do mudo apagadas; quem não tem microfone sopra sozinho.
func comecar() -> void:
	for l in mg.presentes():
		Forja.led_mic(l, 0)
		if not Forja.som_tem(l, Forja.PAPEL_MICROFONE):
			_sem_microfone(l, "sem_microfone")


func ouvir(dt: float) -> void:
	var agora := Ritmo.t_musica()
	var ouvem: Array = []
	for l in mg.presentes():
		if not mg.conectado(l):
			continue
		nivel[l] = float(Forja.som_mic(l).get("nivel", 0.0))
		if not _primeiro[l]:
			_primeiro[l] = true
			piso[l] = nivel[l]
		maior_nivel[l] = maxf(maior_nivel[l], nivel[l])
		if Forja.apertou(l, Forja.MICROFONE):
			apertos[l] += 1
			mudo[l] = apertos[l] % 2 == 1
			Forja.led_mic(l, luz_do_mudo(l))
			if mudo[l] and not escudo[l]:
				_trocar(l, "mudo_no_jogo")
			mg._mudou(l, mudo[l])
		if not _medido[l] and Ritmo.batida() >= BATIDA_DO_SISTEMA:
			_medido[l] = true
			if maior_nivel[l] <= MUDO_NO_SISTEMA:
				_sem_microfone(l, "mudo_no_sistema")
		if _ouve(l, agora):
			ouvem.append(l)
	var alguem := false
	for l in mg.presentes():
		if not mg.conectado(l):
			continue
		var antes: bool = falando[l]
		var fala := false
		if l in ouvem:
			fala = nivel[l] >= piso[l] + VOZ_FICA if antes else conta(nivel, piso, l, ouvem)
		alguem = alguem or fala
		if fala:
			pico[l] = maxf(pico[l], nivel[l])
		if fala != antes:
			falando[l] = fala
			mg.anotar("voz", l, {"evento": "comecou" if fala else "parou",
				"nivel": snappedf(nivel[l] if fala else pico[l], 0.001),
				"limiar": snappedf(piso[l] + (VOZ_ACIMA if fala else VOZ_FICA), 0.001)})
			if fala:
				pico[l] = nivel[l]
				mg._comecou(l)
			else:
				mg._parou(l)
	if not alguem:  # o piso anda só quando ninguém fala (a voz do vizinho não vira piso)
		for l in ouvem:
			piso[l] = lerpf(piso[l], nivel[l], minf(1.0, dt * 0.5))
	_escutas(agora)


## O lugar ouve agora: conectado, sem mudo, com microfone e fora do próprio alto-falante.
func _ouve(l: int, agora: float) -> bool:
	return mg.conectado(l) and not mudo[l] and not sem_mic[l] and agora >= surdo_ate[l]


## Sem microfone, mudo no sistema, ou mudo fora do escudo: o lugar joga sozinho.
func sozinho(l: int) -> bool:
	return sem_mic[l] or (mudo[l] and not escudo[l])


## A nota de voz: o alvo é a batida mais a latência do microfone (o começo
## da voz). O fim da voz desce mais devagar: a P2 passa `latencia` 0,12.
func nova_voz(l: int, n: int, bn: float, latencia := LATENCIA_MIC) -> void:
	mg.nova_nota(l, n, Ritmo.t_da_batida(bn) + latencia)
	_voz_da_nota["%d:%d" % [l, n]] = true


func e_voz(l: int, n: int) -> bool:
	return _voz_da_nota.has("%d:%d" % [l, n])


## A nota de voz em aberto mais perto de agora, a até `janela_casa`; -1: nenhuma.
func casar_voz(l: int) -> int:
	return _casar(l, true, janela_casa)


## A nota de botão em aberto mais perto de agora, a até 0,5 s; -1: nenhuma.
func casar_botao(l: int) -> int:
	return _casar(l, false, ALCANCE_DO_BOTAO)


func _casar(l: int, de_voz: bool, alcance: float) -> int:
	var agora := Ritmo.t_musica() - float(Ritmo.desvio[l])
	var melhor := -1
	var perto := alcance
	for n in mg.notas_em_aberto(l):
		if e_voz(l, n) != de_voz:
			continue
		var d := absf(agora - mg.alvo_da(l, n))
		if d <= perto:
			perto = d
			melhor = int(n)
	return melhor


## O escudo do minigame (a P1 no rugido, a P3 no silêncio): o mudo vale e a luz acende.
func proteger(l: int, sim: bool) -> void:
	escudo[l] = sim
	Forja.led_mic(l, luz_do_mudo(l))
	if mudo[l] and not sim:
		_trocar(l, "mudo_no_jogo")


## A luz do mudo: 0 sem mudo; 1 (acesa) com o escudo; 2 (piscando) o mudo esquecido.
func luz_do_mudo(l: int) -> int:
	if not mudo[l]:
		return 0
	return 1 if escudo[l] else 2


## O alto-falante do dono, só fora da escuta: o microfone não pode ouvir o
## próprio controle. Fora dela, o lugar fica surdo até o som acabar.
func falante(l: int, som: String, ganho: float, ms: int) -> bool:
	if escuta[l]:
		return false
	surdo_ate[l] = Ritmo.t_musica() + ms / 1000.0 + SURDO_FOLGA
	return Forja.som_falante(l, som, ganho) >= 0


## A vibração: na escuta, só as leves (o motor forte o microfone ouve).
func sentir(l: int, nome: String, ms := -1) -> bool:
	if escuta[l] and not nome in LEVES:
		nome = "toque"
	return Forja.sentir(l, nome, ms)


## Guarda `f` para o primeiro quadro em que o lugar sai da escuta (a textura e o eco do acerto).
func depois(l: int, f: Callable) -> void:
	if escuta[l]:
		_depois[l].append(f)
	else:
		f.call()


## O fim do jogo: a música volta e as escutas fecham.
func fechar() -> void:
	for l in 4:
		escuta[l] = false
		segura[l] = false
	_alguma_escuta = false
	Musica.escuta(false)


func _escutas(agora: float) -> void:
	var alguma := false
	for l in mg.presentes():
		var aberta: bool = segura[l]
		if not aberta and mg.conectado(l) and not sem_mic[l]:
			for n in mg.notas_em_aberto(l):
				if e_voz(l, n) and agora >= mg.alvo_da(l, n) - janela_casa:
					aberta = true
					break
		escuta[l] = aberta
		alguma = alguma or aberta
		if not aberta and not _depois[l].is_empty():
			var fs: Array = _depois[l]
			_depois[l] = []
			for f in fs:
				f.call()
	if alguma != _alguma_escuta:
		_alguma_escuta = alguma
		if abaixa:
			Musica.escuta(alguma)


func _sem_microfone(l: int, por: String) -> void:
	sem_mic[l] = true
	motivo[l] = por
	_trocar(l, por)


## A troca do registro (F06), uma vez por lugar e motivo.
func _trocar(l: int, por: String) -> void:
	var chave := "%d:%s" % [l, por]
	if _trocas.has(chave):
		return
	_trocas[chave] = true
	mg.anotar("troca", l, {"de": "microfone", "para": "sem_microfone", "motivo": por})
```

## A cena

### A câmera

A cripta vista do [cinema](../arte/01-cinema.md): lente de 35 mm (FOV vertical 37,8°), plongée de 50°, o modo
`fixa` da G05. **Não corta** do apito ao apito. `CenarioDaVoz.pose_da_camera()` devolve
`[Vector3(0, 11.54, 7.08), Vector3(0, 1.2, -1.6)]`: o centro `(0; 1,2; −1,6)` visto a 13,5 m, 50° abaixo da
horizontal. Com 35 mm em 16:9:

- a borda de baixo do quadro, no chão, cai em z = 2,63: os cavaleiros em z = 1,4 cabem inteiros;
- o topo do quadro, na altura y, segue `y = 11.54 − 0.6032 × (7.08 − z)`: dá 5,07 m em z = −3,65 e 5,46 m em
  z = −3,0. O guardião de pé chega a 4,75 m em z = −3,0: sobra 0,7 m;
- a meia largura, na altura dos cavaleiros, é de 7,1 m: as raias de x = −6 a 6 cabem com 1,1 m de folga.

**O pico** (`no_pico()`): a câmera recua 10 % (`pose_da_camera(1.1)`, a 14,85 m) e volta ao sair; o `lerp` do
main faz o caminho. **O tremor é do evento**: só o de `CenarioDaVoz.exagero`. Roll zero.

### A luz da seção

S8 é a tinta ameixa (`Tema.SECAO[4]`, `#86409a`), lado B. `Tema.luz_da_secao(4, "B")` (G15) devolve a névoa
`#18081c`, o preenchimento `#4a2854` e a chave `#f8ccba`. No lado B, a chave fica a 0,85 (0,9 × 0,85 = **0,77**). A
névoa 30 % mais densa é da G15 e do main: esta ficha não mexe na névoa. O cenário comum põe o preenchimento (o
`atmosfera` da sala) e a chave (uma `OmniLight3D` em `(0, 8, 3)`, energia 0,77, alcance 26).

- **O pico:** a chave sobe 20 % em 1 batida (curva `ENTRA_SAI`) e volta em 2 batidas. Sem flashes: +10 % em 2
  batidas.
- **A catástrofe (o rugido):** a chave sobe 40 % por 1 batida e volta. Sem flashes: +20 %.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `floor-detail`, `wall`, `wall-half` | `Kit.arena(sala, 5, 3)` | o chão e as paredes da cripta (x de −10 a 10, z de −6 a 6) |
| `graveyard-kit/pillar-square` (escala 1,6: 1,84 m) | `(±9, 0, −5)` | o pé das duas tochas do fundo |
| `fire-basket` (escala 2,0) | em cima de cada pilar, em `(±9, 1.84, −5)` | o cesto da tocha |
| `candle-multiple` (escala 2,5) | `(±6.5, 0, −5.4)` e `(±3.5, 0, −5.6)` | as velas do fundo |
| `pillar-large` (escala 3,0: 3,4 m) | `(±3.2, 0, −3.4)` | as colunas dos lados do guardião |
| `fire-basket` (escala 2,0: 0,84 × 0,34 m) | `(RAIAS[l], 0, −0.4)`, um por lugar | o braseiro do lugar |
| `altar-stone` (escala 1,4: topo em 0,69 m) | `ALTAR = (0, 0, −1.2)` | a forja coletiva (só da P1) |

As cores das peças são as do colormap da G10, recolorido pela G14: esta ficha não tinge peça Kenney.

O que não é peça Kenney (caixas do `Kit`, nenhuma esfera, nada metálico, `metallic` 0):

| objeto | forma | onde | material |
| --- | --- | --- | --- |
| o corpo do guardião | caixa 3,4 × 2,5 × 1,6 | centro `(0, 1.25, −3.4)` | pedra: `Kit.material(Tema.GRAFITE, 0.0, 0.9)`; o peito respira: `scale.y = 1.0 + 0.03 * sin(Ritmo.batida() * PI)` |
| a cabeça | caixa 1,8 × 1,3 × 1,3 | no pivô `GUARDIAO` (de pé, o pivô sobe a 4,1; o topo chega a 4,75) | pedra |
| os olhos | 2 caixas 0,36 × 0,14 × 0,06 | pivô + `(±0.42, 0.18, 0.66)` | `Tema.neon(Tema.VIOLETA, e, "mundo")`, `e` de 0 a 1,2; `scale.y` de 0,15 (fechados) a 1 |
| a boca | caixa 1,0 × 0,08 × 0,06 | pivô + `(0, −0.32, 0.66)` | `Kit.material(Tema.JANELA, 0.0, 1.0)`; abre até 0,5 m (`scale.y` até 6,25) |
| os dentes | 4 caixas 0,12 × 0,14 × 0,05 | pivô + `(x, −0.30, 0.69)`, x = ±0,12 e ±0,36 | `Kit.material(Tema.ETIQUETA, 0.0, 0.8)`; visíveis com a boca acima de 0,2 m |
| o tronco | caixa 2,2 × 1,0 × 1,2 | `(0, 2.95, −3.2)` | pedra; `scale.y` 0 sentado, 1 de pé (1 batida) |
| os braços | 2 caixas 0,7 × 2,2 × 0,7 | `(±2.05, 1.1, −2.8)` | pedra |
| o foco | `SpotLight3D` | `(0, 6.5, 0.5)`, mira o pivô | `Tema.TUNGSTENIO`, energia 1,2 (4,0 no rugido por 1 batida), alcance 10, ângulo 30° |
| a chama da tocha | caixa 0,3 × 0,4 × 0,3 | `(±9, 2.2, −5)` | `Tema.neon(Tema.TUNGSTENIO, 1.8, "forja")`; `OmniLight3D` `Tema.TUNGSTENIO` 0,8, alcance 7, em y 2,4 |
| a chama do braseiro | caixa 0,26 × h × 0,26, h de 0,2 a 0,9 m | `(RAIAS[l], 0.34 + h / 2, −0.4)` | `Tema.neon(Tema.JOGADOR[l], 2.0)`; 2,6 no acerto por 4 quadros; `OmniLight3D` da cor do lugar 0,9, alcance 3,4, em y 1,2 |
| a chama da forja | caixa 0,5 × h × 0,5, `h = 0.1 + 1.6 * _chama` | `ALTAR + (0, 0.69 + h / 2, 0)` | `Tema.neon(Tema.TUNGSTENIO, 0.4 + 1.4 * _chama, "forja")`; `OmniLight3D` `Tema.TUNGSTENIO` `0.3 + 0.9 * _chama`, alcance 6, em y 2,0 |

**A chama do braseiro pelo nível.** A cada quadro, enquanto `ouvido.falando[l]`:
`h = lerpf(0.2, 0.9, clampf((ouvido.nivel[l] - ouvido.piso[l]) / 0.5, 0.0, 1.0))`; senão, 0,2. Aplique com
`CenarioDaVoz.chama_em(b, h)`. A pista (o salto a 0,9 m por 1 colcheia) vale por cima. O braseiro de quem levou o
rugido fica apagado (h 0, energia 0, luz 0) até o fim.

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a chama do braseiro | o lugar | 2,0; 2,6 no acerto por 4 quadros |
| a luz do braseiro | o lugar | omni 0,9, alcance 3,4 |
| o anel do escudo no rugido | o lugar | `Efeitos.anel` na cor do lugar, raio 0,9 |
| os olhos do guardião | o mundo | `Tema.VIOLETA`, de 0 a 1,2 (o teto do mundo) |
| a chama da forja coletiva | a forja | `Tema.TUNGSTENIO`, de 0,4 a 1,8 (o teto da forja é 2,4) |
| as tochas | a forja | 1,8; luz 0,8 |
| as faíscas da forja acesa | a forja | `Efeitos.faiscas(self, ..., Tema.TUNGSTENIO, 60, 1.6)` |
| o foco do guardião | a cena | spot de 1,2 a 4,0 |

Nenhuma cor fora dos tokens. Somem os `#7fe8ff`, `#5a4f8f`, `#e8dcc0`, `#ffb050`, `#ff9a40`, `#6a4a2c`, `#2a1a10`,
`#ff3a1a` e o `Tema.VERDE` de hoje, e também a esfera de bronze do rosto. A cinza é `Tema.OXIDO`. As tintas das
seções nunca brilham.

### O cenário comum (`godot/scripts/minigames/s08/cenario_da_voz.gd`)

O arquivo inteiro:

```gdscript
class_name CenarioDaVoz
extends RefCounted
## O cenário comum d'A Voz (S08, docs/jogo/tarefas/P-a-voz.md): a cripta da
## tinta ameixa, as tochas e as velas do fundo, as colunas, o braseiro de cada
## lugar, a câmera, o exagero do impacto e os ganchos do cavaleiro. Os cinco
## minigames da seção montam com isto; o que é só de um fica no script dele.

const SECAO := 4  ## Tema.SECAO[4], a ameixa
const LADO := "B"
const CHAVE_ENERGIA := 0.77  ## 0,9 × 0,85: a chave do lado B
const CAMERA_OLHAR := Vector3(0, 1.2, -1.6)
const CAMERA_ANGULO := 50.0
const CAMERA_DISTANCIA := 13.5
const Z_BRASEIRO := -0.4
## O exagero do impacto (docs/jogo/diversao/README.md#o-exagero-do-impacto).
const DEGRAUS := {
	"golpe": {"tremor_m": 0.02, "batidas": 1.0, "hit_stop": 2, "luz": 0.0},
	"estrondo": {"tremor_m": 0.05, "batidas": 2.0, "hit_stop": 3, "luz": 0.0},
	"catastrofe": {"tremor_m": 0.08, "batidas": 4.0, "hit_stop": 0, "luz": 0.4},
}
const METROS_POR_TREMOR := 0.12  ## o main treme 0,12 m por unidade de `tremor`
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}


static func pose_da_camera(recuo := 1.0, olhar := CAMERA_OLHAR) -> Array:
	var a := deg_to_rad(CAMERA_ANGULO)
	return [olhar + Vector3(0, sin(a), cos(a)) * CAMERA_DISTANCIA * recuo, olhar]


## A cripta da tinta ameixa. `escuro` 1,0 é A Voz; 0,6 é o Zero Absoluto (a
## caverna escurece, não troca). Devolve o que `passar` e `exagero` mexem.
static func montar(sala: SalaJogo, escuro := 1.0) -> Dictionary:
	Kit.arena(sala, 5, 3)
	var luz: Dictionary = Tema.luz_da_secao(SECAO, LADO)
	sala.atmosfera(luz.preenchimento, Tema.VIOLETA, false, 30, 22.0, -7.8, 0.35 * escuro)
	var chave := OmniLight3D.new()
	chave.position = Vector3(0, 8.0, 3.0)
	chave.light_color = luz.chave
	chave.light_energy = CHAVE_ENERGIA * escuro
	chave.omni_range = 26.0
	sala.add_child(chave)
	for x in [-9.0, 9.0]:
		Kit.peca(sala, "graveyard-kit/pillar-square", Vector3(x, 0, -5.0), 0.0, 1.6)
		Kit.peca(sala, "fire-basket", Vector3(x, 1.84, -5.0), 0.0, 2.0)
		Kit.caixa(sala, Vector3(0.3, 0.4, 0.3), Vector3(x, 2.2, -5.0), Tema.neon(Tema.TUNGSTENIO, 1.8, "forja"))
		var tocha := OmniLight3D.new()
		tocha.position = Vector3(x, 2.4, -5.0)
		tocha.light_color = Tema.TUNGSTENIO
		tocha.light_energy = 0.8 * escuro
		tocha.omni_range = 7.0
		sala.add_child(tocha)
	for v in [Vector3(-6.5, 0, -5.4), Vector3(6.5, 0, -5.4), Vector3(-3.5, 0, -5.6), Vector3(3.5, 0, -5.6)]:
		Kit.peca(sala, "candle-multiple", v, 0.0, 2.5)
	for x in [-3.2, 3.2]:
		Kit.peca(sala, "pillar-large", Vector3(x, 0, -3.4), 0.0, 3.0)
	return {"chave": chave, "chave_energia": chave.light_energy, "pico": false, "tremor_ate": -1.0,
		"luz_ate": -1.0, "pose": pose_da_camera()}


## O braseiro do lugar: o cesto, a chama (uma caixa na cor do lugar) e a luz
## de dono. Devolve {chama, mat, luz, base, apagado, treme_ate, salto_ate, brilho_ate}.
static func braseiro(sala: SalaJogo, l: int) -> Dictionary:
	var base := Vector3(Minigame.RAIAS[l], 0.0, Z_BRASEIRO)
	Kit.peca(sala, "fire-basket", base, 0.0, 2.0)
	var mat := Tema.neon(Tema.JOGADOR[l], 2.0)
	var chama := Kit.caixa(sala, Vector3(0.26, 1.0, 0.26), base + Vector3(0, 0.44, 0), mat)
	chama.scale.y = 0.2
	var luz := OmniLight3D.new()
	luz.position = base + Vector3(0, 1.2, 0)
	luz.light_color = Tema.JOGADOR[l]
	luz.light_energy = 0.9
	luz.omni_range = 3.4
	sala.add_child(luz)
	return {"chama": chama, "mat": mat, "luz": luz, "base": base, "apagado": false, "treme_ate": -1.0,
		"salto_ate": -1.0, "brilho_ate": -1.0}


## A altura da chama do braseiro (m, de 0 a 0,9): a caixa cresce de baixo.
static func chama_em(b: Dictionary, h: float) -> void:
	var c: MeshInstance3D = b.chama
	c.scale.y = maxf(h, 0.001)
	c.position.y = 0.34 + h / 2.0


static func passar(sala: SalaJogo, c: Dictionary, no_pico: bool) -> void:
	var agora := Ritmo.t_musica()
	var batida := 60.0 / Ritmo.bpm
	if no_pico != bool(c.pico):
		c.pico = no_pico
		var pose := pose_da_camera(1.1 if no_pico else 1.0)
		sala.camera_pos = pose[0]
		sala.camera_olhar = pose[1]
		var sobe := (0.2 if Opcoes.flashes else 0.1) if no_pico else 0.0
		var em := (1.0 if Opcoes.flashes else 2.0) if no_pico else 2.0
		var tw := sala.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(c.chave, "light_energy", float(c.chave_energia) * (1.0 + sobe), em * batida)
	if float(c.tremor_ate) >= 0.0 and agora >= float(c.tremor_ate):
		sala.tremor = 0.0
		c.tremor_ate = -1.0
	if float(c.luz_ate) >= 0.0 and agora >= float(c.luz_ate):
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.2 if c.pico and Opcoes.flashes else 1.0)
		c.luz_ate = -1.0


static func exagero(sala: SalaJogo, c: Dictionary, degrau: String, boneco: Node3D = null) -> void:
	var d: Dictionary = DEGRAUS[degrau]
	var batida := 60.0 / Ritmo.bpm
	sala.tremor = maxf(sala.tremor, float(d.tremor_m) / METROS_POR_TREMOR)
	c.tremor_ate = Ritmo.t_musica() + float(d.batidas) * batida
	if int(d.hit_stop) > 0 and boneco and Opcoes.tremor:
		congelar(boneco, int(d.hit_stop))
	if float(d.luz) > 0.0:
		var k := float(d.luz) if Opcoes.flashes else float(d.luz) * 0.5
		(c.chave as OmniLight3D).light_energy = float(c.chave_energia) * (1.0 + k)
		c.luz_ate = Ritmo.t_musica() + batida


## O hit-stop visual: a animação do boneco para `quadros` quadros (60 por s).
static func congelar(boneco: Node3D, quadros: int) -> void:
	var anim: AnimationPlayer = boneco.get("anim")
	if anim == null:
		return
	var antes := anim.speed_scale
	anim.speed_scale = 0.0
	boneco.get_tree().create_timer(quadros / 60.0).timeout.connect(func(): anim.speed_scale = antes)


## O gancho do stat do cavaleiro (G13); o neutro enquanto a classe não existe.
static func gancho(l: int, nome: String) -> float:
	for c in ProjectSettings.get_global_class_list():
		if c["class"] == "Cavaleiro":
			return float(load(c["path"]).gancho(l, nome))
	return float(NEUTRO[nome])


## A antecedência da pista do lugar, em s: o Faro (±40 ms) e a Lanterna (meio tempo).
static func antecedencia(l: int) -> float:
	return gancho(l, "pista") / 1000.0 + Itens.antecipacao_s(l, Ritmo.bpm)


## A queda do lugar, em s: `tempos` × o Fôlego, na semicolcheia, no mínimo uma.
static func queda_s(l: int, tempos: float) -> float:
	var semi := 60.0 / Ritmo.bpm / 4.0
	return maxf(semi, roundf(tempos * gancho(l, "levantar") * 4.0) * semi)
```

A G15 passa o néon da `atmosfera` pelo `Tema.neon` (energia 3,0 hoje): esta ficha não mexe nele.

### A montagem da Voz

- Por lugar presente: `raia(l)`; `posicionar(l)`; `jogador(l).rotation.y = PI` e `jogador(l).preso = true`;
  `CenarioDaVoz.braseiro(self, l)`; a nuca (O cavaleiro).
- O guardião: `_montar_guardiao()` com as caixas da tabela. O pivô é um `Node3D` em `GUARDIAO`; a cabeça, os olhos,
  a boca e os dentes são filhos dele e sobem juntos quando ele fica de pé.
- O altar e a chama da forja: `_montar_altar()`, com `Kit.peca(self, "altar-stone", ALTAR, 0.0, 1.4)` e as caixas.
- O foco: `SpotLight3D` com `look_at(GUARDIAO)` depois de entrar na árvore.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos já existem; nenhum som novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| a voz certa | a nota do kit (`Som.tocar("nota", ...)`, H08) | `nota:%d` no perfeito, 0,8, **depois da escuta** | `nota_*` |
| a cinza | `Som.tocar("sopro", b.base, -10.0)` | — | `sint_sopro` |
| o sino do mudo (`B_FIM − 34`, `B_FIM − 10`) | — | `pronto`, 0,6 (500 ms), pelo `ouvido.falante` | `mod_pronto` |
| o aperto do mudo | — | — (a luz do mudo responde) | — |
| o meio rugido | `Som.tocar("grito", GUARDIAO, -8.0)` | — | `grito_*` |
| o rugido | `Som.tocar("grito", GUARDIAO, 0.0)` e `Som.tocar("martelo", GUARDIAO, 2.0)` | `grito`, 0,8 (900 ms), em quem caiu | `grito_*`, `martelo_*` |
| a forja acende | `Som.tocar("fogo", ALTAR, 0.0)` e `Som.tocar("sucesso", null, -4.0)` | — | `fogo_*`, `sucesso_*` |
| a faixa | `MUS_S08_J36`: 105 BPM, Ré menor; até ela existir, a reserva `"sopro"` (105 bpm) | — | `mus_s08_j36` |

- **A música desce 12 dB enquanto um microfone escuta** (`Musica.escuta`, pelo ouvido). No pico do sopro, a escuta
  abre 0,25 s antes de cada batida e fecha no julgamento: a música respira com a forja.
- **O `falha` não existe aqui.** O bipe é proibido pela bíblia. A voz errada soa como cinza (`sopro`); o erro de
  julgamento é do kit (`jul_erro_p{n}`, e o `fx_tropeco_*` quando a H11 trocar a falha da TV).
- **O alto-falante toca um som por vez, e nunca na escuta**: o microfone do mesmo controle o ouviria e contaria
  como voz. `ouvido.falante` devolve `false` na escuta; fora dela, deixa o lugar surdo até o som acabar, mais 50 ms.
- **A mixagem é da H11.** O material `"pedra"` (`mod_material_pedra`, 80 Hz, 60 ms) toca pelo minigame, depois da
  escuta (`Forja.textura(l, "pedra", 0.5)`).

## O controle

Evento por evento. O piso é o da F05.

| evento | quem sente | vibração | gatilho | barra de luz | alto-falante | luz do mudo |
| --- | --- | --- | --- | --- | --- | --- |
| começar | todos | — | `gatilhos_off(l)` | a cor do lugar | — | 0 (apagada) |
| a voz certa | o dono | a textura `pedra` 0,5 depois da escuta; sem háptica, `toque` | — | o kit: branco 0,15 s no perfeito | `nota:%d` no perfeito, depois da escuta | — |
| a voz julgada ERRO | o dono | o kit: `erro` (0,7 / 0,3, 160 ms) | — | o kit: a cor escurecida 0,5 s | — | — |
| a cinza | o dono | — | — | — | — | — |
| o sino do mudo | todos | — | — | — | `pronto` 0,6 | — |
| o mudo no escudo | quem apertou | — | — | — | — | 1 (acesa) |
| o mudo fora do escudo | quem apertou | — | — | — | — | 2 (piscando) |
| o meio rugido | quem não está mudo | `aviso` | — | — | — | — |
| o rugido | quem não está mudo | `explosao` | — | — | `grito` 0,8 | — |
| o rugido | quem está mudo | `toque` (o escudo segurou) | — | — | — | 1 |
| o fim, fora da bancada | todos | — | — | — | — | 0: o `jogar` chama `Forja.led_mic(l, 0)` |

- **Na escuta, nada forte vibra.** O motor forte faz ruído no microfone do mesmo controle. `ouvido.sentir` troca
  tudo que não é `toque`, `toque_esq` ou `toque_dir` por `toque` enquanto o lugar escuta. O `erro` do kit cai
  depois do julgamento: no pico (uma nota por batida), ele pode encostar 0,09 s na escuta seguinte (Armadilhas).
- A barra de luz é **sempre a cor do lugar**; ninguém mexe nela além do piscar do kit.
- A luz do mudo não é identidade: ela pode acender e piscar à vontade.
- **No rádio:** sem placa de áudio não há microfone nem alto-falante. O ouvido marca `sem_microfone` desde o começo
  e o lugar sopra sozinho. A luz do mudo (saída HID) passa pela ponte.

### O robô

```gdscript
# O robô fala no microfone do controle simulado e aperta o mudo no tempo. Ele
# não lê a luz do mudo no jogo (aperta toda nota de botão aberta), e sorteia no
# rng dele: o rng do kit é do jogo.
var _robo_rng := RandomNumberGenerator.new()
var _robo_nota := [-1, -1, -1, -1]
var _robo_feita := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]  ## o atraso (s); 99: calado


func robo(l: int, dt: float) -> void:
	if not Forja.robo:
		return
	if _bancada != 0:
		_robo_bancada(l, dt)  # o sussurro e a luz, como hoje
		return
	for n in notas_em_aberto(l):
		if int(n) <= int(_robo_feita[l]):
			continue
		if int(_robo_nota[l]) != int(n):
			_robo_nota[l] = n
			var certo := Forja.robo_acerta()
			if ouvido.e_voz(l, n):
				# quando erra: metade das vezes 0,2 s atrasado, metade calado
				_robo_mira[l] = 0.0 if certo else (0.2 if _robo_rng.randf() < 0.5 else 99.0)
			else:
				var rugido := absf(alvo_da(l, n) - Ritmo.t_da_batida(_b_fim - 9)) < 0.01
				_robo_mira[l] = 0.0 if certo else (ATRASO_ROBO_RUGIDO if rugido else ATRASO_ROBO)
		if Ritmo.t_musica() >= alvo_da(l, n) + float(_robo_mira[l]):
			if ouvido.e_voz(l, n):
				Forja.robo_falar(l, 0.8, 0.3)
			else:
				Forja.robo_apertar(l, Forja.MICROFONE, 0.08)
			_robo_feita[l] = n
		break
```

A 105 bpm, o rugido cai 0,571 s depois da nota do mudo: o robô que erra (0,65 s tarde) leva o rugido. A chance de
cair no rugido é 0,05 no `bom`, 0,34 no `medio` e 0,7 no `ruim`. Na mesa padrão (`bom`, `medio`, `medio`, `ruim`),
a chance de ninguém cair é de 0,95 × 0,66 × 0,66 × 0,3 = 12 %; a de alguém cair, 88 %. `_robo_bancada(l, dt)` é o
`_robo` de hoje nos ramos `SUSSURRO` e `LUZ` (`voz.gd:651-666`), com o `estado` trocado por `_bancada`.

## O cavaleiro

O cavaleiro é o da montagem (G13): a cabeça, a parte de cima e a de baixo que a pessoa escolheu aparecem como estão,
de costas para a câmera. `posicionar(l)` deixa as mãos livres: o item não aparece na Voz, mas o efeito dele vale. O
cavaleiro pode ser de outra raça (G13, o ajuste dela de 09/10): esta ficha não supõe corpo humano; usa só o
esqueleto comum de 7 ossos (o osso `head` na nuca) e as animações `interact-right`, `emote-no`, `emote-yes`, `sit`
e `idle`.

| stat | gancho | o que muda na Voz | stat 1 | stat 3 | stat 5 |
| --- | --- | --- | --- | --- | --- |
| Peso | — | não age (o RPG da Voz é Fôlego e Faro) | — | — | — |
| Passo | — | não age: o boneco fica preso na raia | — | — | — |
| Fôlego | `levantar` | a tosse da cinza (1 tempo) e o tempo sentado no rugido (2 tempos) | 1,25 / 2,5 tempos | 1 / 2 tempos | 0,75 / 1,5 tempo |
| Faro | `pista` | o salto da chama do braseiro chega antes; a nota cai no mesmo tempo | −40 ms | 0 | +40 ms |

Os itens:

- o Escudo absorve o primeiro erro (o kit, G03);
- a Âncora divide o recuo do rugido por 2 (0,3 m);
- a Lanterna adianta a pista meio tempo;
- o Fole devolve metade do combo;
- o Martelo dobra o perfeito no tempo forte (o kit; os sopros em `+0` caem no tempo forte);
- o Diapasão é do kit (a nota 1,3× e o perfeito puxa o combo da equipe).

Nenhum stat muda a janela de julgamento; nenhum tira o rugido.

```gdscript
## A cabeça para trás no rugido: um modificador do esqueleto roda o osso `head`
## depois da animação (o `sit` segue tocando). `graus` 0 é a pose da animação.
class Nuca extends SkeletonModifier3D:
	var graus := 0.0

	func _process_modification_with_delta(_delta: float) -> void:
		var esq := get_skeleton()
		var o := esq.find_bone("head") if esq else -1
		if o < 0 or graus == 0.0:
			return
		var r := esq.get_bone_pose_rotation(o)
		esq.set_bone_pose_rotation(o, r * Quaternion(Vector3.RIGHT, deg_to_rad(-graus)))


func _montar_nuca(p) -> Nuca:
	var esq: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false) if p.modelo else null
	if esq == null:
		return null
	var m := Nuca.new()
	esq.add_child(m)
	return m


## O rugido em quem não estava mudo: para trás (+z) em 1 colcheia, sentado com a
## cabeça para trás a queda do Fôlego; depois volta em 1 batida.
func _derrubar(l: int) -> void:
	var p := jogador(l)
	var m := RECUO_M * Itens.resiste_a_empurrao(l)
	var colcheia := 30.0 / Ritmo.bpm
	var queda := CenarioDaVoz.queda_s(l, SENTADO_TEMPOS)
	p.create_tween().tween_property(p, "position:z", Z_JOGADOR + m, colcheia) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	p.gesto("sit", queda)
	var nuca: Nuca = _nuca.get(l)
	if nuca:
		nuca.graus = NUCA_GRAUS
	get_tree().create_timer(queda).timeout.connect(func():
		if nuca:
			nuca.graus = 0.0
		p.create_tween().tween_property(p, "position:z", Z_JOGADOR, 60.0 / Ritmo.bpm) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
```

O `Timer` aqui é enfeite (a volta do boneco); o julgamento e o roteiro andam pela batida. O desregistro do erro (o
contorno de 2,4 a 0,6, o tremor de ±0,02 m por 3 quadros) é do kit e da G08.

## As reações

- **Carimbos que a Voz pode disparar** (do kit e do HUD, G04; a Voz não chama nenhum):
  - `car_em_chamas`: 5 Ressonâncias seguidas do mesmo lugar (os perfeitos contam);
  - `car_acorde`: os quatro na Ressonância no mesmo tempo 1 (acontece nos sopros em `+0`, que são de todos).
  - O `car_por_um_fio` não acontece: é coop, sem vencedor por pontos.
- **Adesivos:** ninguém sai da rodada (quem cai no rugido volta em 2 batidas), então ninguém manda adesivo durante
  o jogo.
- Nenhum carimbo próprio de minigame.

## A diversão

**O momento: o rugido** (`rugido`). O guardião fica de pé e ruge. Quem está com o mudo ligado (a luz acesa) fica
protegido; quem não está é jogado para trás e senta no chão. A sala grita «muta!» um segundo antes, e os quatro
correm para o botão. Degrau catástrofe: o guardião de pé tem 4,75 m, 3 vezes o cavaleiro.

- **Rastro:** quem caiu fica sentado 2 batidas, com a cabeça (osso `head`) inclinada 25° para trás. O braseiro dele
  treme e apaga até o fim.
- **A curva:** de 0 a 27 s, o chamado (cada um na sua vez, o guardião abre os olhos aos poucos); de 27 a 53 s, o
  sopro (no pico, em toda batida); de 53 s ao fim, a reta. O meio rugido avisa em 108 (61,7 s), e o rugido de
  verdade vem em 132 (75,4 s).
- **Ensina sem falar:** o peito do guardião sobe e desce no tempo (`sin(batida × π)`); o braseiro de cada um
  acende quando o microfone dele ouve; no meio rugido, o ícone do Botão do microfone pisca sobre as cabeças.
- **Quem está perdendo:** é coop. A chama é de todos, e o rugido não apaga a forja.
- **A nota de hoje:** 3. Gênero `coop`.

**Como o jogador do time confere** (a mesa padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim`, semente 7, sem a
bancada, pela prova visual da F09):

| item da régua | pelo robô | pela prancha |
| --- | --- | --- |
| 1. a graça em 10 s | cada lugar tem uma linha `voz` `comecou` e uma `toque` com `t_musica` ≤ 10,0 (o eco do chamado cai na batida 7, 4,0 s) | o quadro de 10 s mostra pelo menos um braseiro aceso acima de 0,5 m |
| 4. o momento | 1 linha `momento` `rugido` com `t_musica` entre 53 e 80 e o campo `caiu` não vazio | o quadro do rugido (76 s) mostra o guardião de pé e pelo menos 1 cavaleiro sentado |
| 5. a curva | notas por batida de 48 a 91 ≥ 2,0 × as de 4 a 47; existem as linhas `momento` `meio_rugido` e `reta` | o quadro de 40 s tem a luz 20 % acima do de 20 s |
| 6. a falha | o P4 tem pelo menos 3 linhas `toque` com `erro` ou `entrada` `cinza` | 1 quadro em 5 mostra o braseiro do P4 abaixo de 0,3 m ou o P4 sentado |
| 7. quem perde joga | a maior distância entre duas linhas `nota` seguidas de cada lugar é de até 8 batidas (as notas de botão contam); o P4 tem um `toque` BOM ou melhor em cada terço | o P4 aparece em 100 % dos quadros de jogo |
| 8. a câmera | o `rugido` tem 0,2 ≤ `x_tela` ≤ 0,8 e `altura_tela` ≥ 0,08 | o guardião inteiro cabe no quadro de 480 × 270 |
| 9. o impacto | uma linha `sensacao` `explosao` a até 16,7 ms do `rugido` | o quadro seguinte ao rugido mostra a boca aberta |
| 10. o placar no mundo | o `valores` do `momento` `reta` bate com `_chama` a ±0,01 | no quadro de 70 s, a chama do altar tem a altura `0.1 + 1.6 × chama` |

A mesa padrão roda em duas rodadas até o robô por lugar existir: `bash tests/prova_do_jogo.sh --robo=medio` (os
itens 1, 4, 5, 8, 9 e 10) e `--robo=ruim` (os itens 6 e 7, com os quatro `ruim`).

## Pronto quando

A Voz joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos. Aguenta o cabo que cai
e volta, e fecha sempre (coop, com o destaque). `--sala=voz` abre o `S08_J36`. O meio rugido e o rugido acontecem
nas batidas `B_FIM − 32` e `B_FIM − 8`, e o rugido derruba quem não está mudo. A música desce 12 dB na escuta, e
nada forte vibra na escuta. A luz do mudo acende no escudo e pisca fora dele. Com `--bancada`, o sussurro e a
pergunta da luz vêm depois da faixa e os três vereditos saem como antes. A prova do jogo passa (sem e com
`--bancada`), e `bash tests/prova_visual.sh` passa com a prancha olhada.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`, a checagem da Voz usa o `_joga_o_minigame(apelido, limite_s, olhar)` da H08: abre
pelo catálogo, deixa o aviso passar e espera o fim pelo relógio de parede (80 s de música cabem em 130 s; com a
bancada, 170 s). Chame-a no percurso logo depois da última sala de hoje, antes do relatório:

```gdscript
## A Voz (S08_J36): o apelido abre o minigame; a regra dos 6 dB; a música desce
## na escuta; nada forte vibra na escuta; a luz do mudo acende no escudo; o
## rugido derruba quem não está mudo; o registro tem a voz e os momentos.
func _prova_a_voz() -> void:
	var Ouvido := load("res://scripts/minigames/s08/ouvido.gd")
	var pisos := [0.1, 0.1, 0.1, 0.1]
	_esperar(Ouvido.conta([0.8, 0.65, 0.65, 0.65], pisos, 0, [0, 1, 2, 3]) \
		and not Ouvido.conta([0.8, 0.65, 0.65, 0.65], pisos, 1, [0, 1, 2, 3]), "Voz: 6 dB abaixo do mais alto não conta")
	_esperar(Ouvido.conta([0.8, 0.8, 0.8, 0.8], pisos, 3, [0, 1, 2, 3]), "Voz: quatro sopros juntos contam os quatro")
	var forte_na_escuta := [0]
	var baixou := [0]
	var escuta_amostras := [0]
	var luzes := {}
	var olhar := func(mg) -> void:
		if mg.ouvido == null:
			return
		for l in mg.presentes():
			var pc := Forja.percepcao(l)
			luzes[int(pc.get("led_mic", 0))] = true
			if mg.ouvido.escuta[l]:
				escuta_amostras[0] += 1
				if maxf(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0))) > 0.75:
					forte_na_escuta[0] += 1
		if Musica._escutando and Musica._tocadores[Musica._ativo].volume_db <= Musica.VOLUME_DB - 11.0:
			baixou[0] += 1
	var mg = await _joga_o_minigame("voz", 170.0 if Forja.bancada else 130.0, olhar)
	if mg == null:
		return
	_esperar(mg.id == "S08_J36", "Voz: --sala=voz abre o S08_J36")
	_esperar(escuta_amostras[0] > 0 and baixou[0] > 0, "Voz: a música desceu 12 dB na escuta (%d quadros)" % baixou[0])
	_esperar(forte_na_escuta[0] == 0, "Voz: nada forte vibrou na escuta (%d amostras)" % forte_na_escuta[0])
	_esperar(luzes.has(1), "Voz: a luz do mudo acendeu no escudo (%s)" % [luzes.keys()])
	_esperar(mg.coop_venceu == (mg._chama >= 1.0), "Voz: o coop é a forja acesa (%.2f)" % mg._chama)
	var linhas := _linha_do_tempo().filter(func(e): return e.get("slot") == "S08_J36")
	var vozes := linhas.filter(func(e): return e.get("tipo") == "voz" and e.get("evento") == "comecou")
	var momentos := linhas.filter(func(e): return e.get("tipo") == "momento")
	var rugido := momentos.filter(func(e): return e.get("nome") == "rugido")
	_esperar(vozes.size() >= 4, "Voz: o registro tem %d começos de voz" % vozes.size())
	_esperar(momentos.any(func(e): return e.get("nome") == "meio_rugido"), "Voz: o meio rugido aparece")
	_esperar(momentos.filter(func(e): return e.get("nome") == "reta").size() == 1, "Voz: a reta aparece uma vez")
	_esperar(rugido.size() == 1 and float(rugido[0].get("t_musica", 0.0)) >= 53.0 \
		and float(rugido[0].get("t_musica", 0.0)) <= 80.0, "Voz: um rugido entre 53 e 80 s (%s)" % [rugido])
	if rugido.size() == 1:
		_esperar(float(rugido[0].get("x_tela", 0.0)) >= 0.2 and float(rugido[0].get("x_tela", 0.0)) <= 0.8 \
			and float(rugido[0].get("altura_tela", 0.0)) >= 0.08, "Voz: o guardião no meio da tela (%s)" % [rugido[0]])
		if Forja.robo_temperamento == "ruim":
			_esperar(str(rugido[0].get("caiu", "")) != "", "Voz: o rugido derrubou alguém na mesa ruim")
	if not Forja.bancada:
		_esperar(linhas.filter(func(e): return e.get("tipo") == "pergunta").is_empty(), "Voz: fora da bancada, nenhuma pergunta")
```

`_linha_do_tempo` é da F01 e já está na prova; `Forja.robo_temperamento` é o da F09 (se o nome lá for outro, use o
da F09 e anote). As checagens que hoje olham `"voz"` pelo id, como as de `SO_COM_PERGUNTA`, passam a olhar pelo
apelido com `_e_a_sala` da H04.

### O que o registro mede

- `voz` de cada começo e fim de voz (`nivel`, `limiar`): o nível do microfone de cada controle, a noite inteira.
- `nota` e `toque` de cada chamado, sopro e nota de botão (o desvio no tempo pedido); `entrada` `cinza` e
  `forja_acesa`.
- `saida` `led_microfone` (cada `led_mic`, com `seq` e `ok`) e o botão pelas medidas.
- `troca` de `microfone` para `sem_microfone`, com o `motivo` (`sem_microfone`, `mudo_no_sistema`,
  `mudo_no_jogo`).
- `momento` `meio_rugido`, `reta` e `rugido`.
- Na bancada, além disso, a `pergunta` da luz e os três vereditos (`dar_vereditos`).

### As pranchas que o jogador do time olha

A prancha da prova visual (`SAIDA/prancha-<n>.png`, um quadro de 480 × 270 a cada 2 s):

- o quadro de 10 s: um braseiro aceso no chamado;
- o de 40 s: a luz do pico, a câmera mais longe, os quatro braseiros juntos;
- o de 62 s: o meio rugido, com a boca entreaberta;
- o de 76 s: o guardião de pé e alguém sentado com a cabeça para trás;
- o último: os braseiros apagados de quem caiu e a chama do altar.

### O que o André joga e sente

`./run-local.sh -- --sala=voz`, com quatro DualSense, dois no cabo e dois no rádio:

- o braseiro dele acende quando ele fala, e não acende quando o vizinho ri baixo;
- a música desce quando chega a vez de soprar, e volta logo depois;
- no meio rugido, a mão vibra de aviso e o ícone do microfone pisca; o Botão do microfone acende a luz laranja;
- no rugido, quem esqueceu sente a explosão na mão, ouve o grito no controle, e o cavaleiro senta com a cabeça para
  trás;
- quem esquece o mudo ligado vê a luz piscando e o braseiro soprando sozinho;
- os dois no rádio jogam sozinhos desde o começo (sem microfone), e a luz do mudo deles ainda acende;
- com `--bancada`, o sussurro e a pergunta da luz vêm depois da música; sem ela, somem.

### Armadilhas

- **`main.gd:19` ainda carrega `salas/voz.gd`** até a H04 trocar o `SALAS` pelo catálogo. Não faça o `git rm`
  antes da H04 (ou tire a linha junto).
- **O erro do kit encosta na escuta no pico.** O `erro` (0,7 / 0,3, 160 ms) sai do `_reagir` no julgamento. Com
  uma nota por batida (0,571 s), a escuta seguinte abre 0,32 s depois do alvo, e um erro julgado tarde (até
  +0,25 s) vibra até 0,41 s: 0,09 s dentro da escuta. A prova olha só acima de 0,75 por isso. Não corrija no kit:
  anote se a bancada mostrar voz fantasma no pico.
- **O robô sorteia no dele.** `_robo_rng.seed = rng.seed + 99` no `iniciar_jogo()`: o robô não pode mudar o que o
  jogo sorteia (a paridade: com robô ou com gente, o mesmo jogo).
- **O piso do simulado.** O robô depende de o microfone simulado ter fundo acima de 0,001; senão o ouvido marca
  `mudo_no_sistema`. Confira com um `print` do `ouvido.maior_nivel` na batida 4.
- **O vazamento no simulador.** Se o controle simulado não vaza a voz de um robô para os outros, a regra dos 6 dB
  só se prova pela checagem estática (`Ouvido.conta`). Não invente vazamento na prova.
- **O mudo é do jogo, por paridade.** O Botão do microfone no controle de verdade também pode mudar o sistema; o
  minigame não depende disso: `ouvido.mudo[l]` manda. Se o controle já chega mudo pelo sistema, o ouvido o marca
  `mudo_no_sistema` na batida 4, e ele sopra sozinho.
- **`Forja.vibrar` não é para a sala** (o susto de hoje chamava): só `ouvido.sentir`.
- **O `dt` no ouvido** é o piso andando (uma medida), não o mundo; o guardião e as chamas andam pela batida.
- **A Nuca** é `SkeletonModifier3D` (Godot 4.7): o `_process_modification_with_delta` roda depois da animação. Se a
  prancha mostrar a cabeça para a frente em vez de para trás, o eixo do osso `head` é outro: troque o sinal e
  anote.

### Ao terminar

- No [quadro](README.md): a linha **P1**, com o commit (`feito (<commit>)`).
- Commit sugerido (sem trailer):
  `feat: A Voz no kit, no tempo da faixa, com o ouvido da seção, o meio rugido e o rugido`
