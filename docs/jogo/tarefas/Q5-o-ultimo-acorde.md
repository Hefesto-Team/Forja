# Q5 — O Último Acorde

**Sprint:** Q · **Slot:** S09_J45 · **Tamanho:** G · **Depende de:** Q1 (a seção no catálogo, o tipo `momento`), Q4 (o dragão, a forma do medley), H04, H07, H08, F05 (`Forja.sentir`), F09 (`Forja.robo_acerta`), G03, G05, G13, G14, G15

## Por quê

O fim da noite. O dragão está de pé, e a turma o derruba com os verbos da segunda metade: atirar (S5), repetir (S6),
sentir (S7) e soprar (S8). No fim, 32 respostas em chamada e resposta divididas entre os quatro: o dragão chama um, e
esse um responde. Se faltam mais de 6, o dragão se levanta de novo e vêm mais 8. A ficha existe para que a mesa fraca
veja o dragão se levantar pelo menos 1 vez e depois cair, e para que a mesa boa o derrube sem ele levantar.

## Ler antes

- [O molde de minigame](molde-de-minigame.md) (onde mora, a FICHA, o robô, o registro, a prova)
- [O kit, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) e, no mesmo arquivo, a seção «As decisões comuns dos
  minigames — H08» (a linha `estacao`, a `troca`)
- [A Q4, «Como se joga»](Q4-ruge-o-reator.md#como-se-joga) (o dragão de peças, o hoqueto, o `_queda_s`, o `_gancho`: esta ficha tem a mesma forma)

Tudo o mais que esta ficha usa (as cores, o brilho, a câmera, o movimento, o som, os stats, o ouvido da P1, a pedra da
O2, o tiro da M1, o canto da N1, a régua da diversão) está escrito aqui dentro, com o número. O medley não abre o
minigame de origem.

As duas curvas do movimento (do 05): `ENTRA_SAI` é um `Tween` com `TRANS_SINE` e `EASE_IN_OUT`; `MOLA` é
`TRANS_BACK` com `EASE_OUT` (passa 4 % do alvo e volta).

## Arquivos que mudam

- `godot/scripts/minigames/s09/o_ultimo_acorde.gd` (novo, `extends Minigame`, sem `class_name`) e o `.uid`.
- `godot/scripts/minigames/catalogo.gd`: `"S09_J45"` em `MINIGAMES` e na lista da seção `S09`, depois do `S09_J44`.
  **De todos:** Q1, Q2, Q3 e Q4.
- `godot/scripts/traducoes.gd`: as frases da tabela «As frases». **De todos:** Q1, Q2, Q3 e Q4.
- `godot/testes/prova_do_jogo.gd`: `_prova_o_ultimo_acorde()` e a linha `"S09_J45": await _prova_o_ultimo_acorde()`
  no `match` de `_prova_da_ficha`. **De todos:** Q1, Q2, Q3 e Q4.

## Como se joga

**Derrube o dragão!** Quatro estações sem pausa na mesma música, uma batida de cada vez, em roda. Atirar é o R2 até o
clique; repetir é ouvir duas notas no seu controle e devolver no ✕; sentir é ✕ quando a pedra bate na mão e nada na
neblina; soprar é a voz no tempo. No fim, o dragão chama cada um pelo alto-falante do controle dele, e ele responde no
✕.

### A ficha de dados

```gdscript
const FICHA := {
	"slot": "S09_J45",
	"titulo": "O Último Acorde",
	"verbo": "Derrube o dragão!",
	"genero": "coop",
	"icone": "alto_falante",
	"entradas": [Forja.CRUZ],
	"camera": "fixa",
	"faixa": "MUS_S09_J45",
	"duracao": 0.0,
	"fim": "meta_coletiva",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "explosao", "aviso"],
	"material": "metal",
	"microjogo": {"verbo": "Acorde!", "segundos": 7.0},
	"papel_som": Forja.PAPEL_MICROFONE,
	"gesto": "holding-right-shoot",
	"treino": false,
}
```

A entrada-botão é uma (✕); o R2 (eixo) e a voz entram fora da lista, uma estação cada. `papel_som` é o microfone, para
a estação 4 achar o microfone no aviso; o alto-falante e a háptica tocam pela placa aberta desde a entrada do lugar
(H07). `duracao` é 0: o medley acaba pelo dragão, entre a batida 276 (110,4 s) e a 316 (126,4 s). Sem treino.

### O tempo

A faixa `MUS_S09_J45` tem 150 BPM: uma batida dura 0,4 s, a colcheia 0,2 s, a semicolcheia 0,1 s.

| trecho | batidas | segundos | o verbo |
| --- | --- | --- | --- |
| a contagem | 0 a 3 | 0 a 1,6 | o dragão se ergue; o piso de cada microfone é medido (batidas 1 a 3,5) |
| 1. Atirar (a galeria da M1) | 4 a 51 | 1,6 a 20,8 | o R2 até o clique, na sua batida |
| 2. Repetir (o canto da N1) | 52 a 99 | 20,8 a 40,0 | o seu controle canta duas notas; devolva no ✕ |
| o eclipse | 100 a 107 | 40,0 a 43,2 | a TV canta quatro notas; os quatro devolvem juntos |
| 3. Sentir (a neblina da O2) | 108 a 155 | 43,2 a 62,4 | ✕ quando a pedra bate na mão; nada na neblina |
| 4. Soprar (a voz da P1) | 156 a 203 | 62,4 a 81,6 | a voz na sua batida |
| o acorde final | 204 a 267 | 81,6 a 107,2 | 32 chamadas e respostas |
| o descanso, a volta 1 | 268 a 271, 272 a 287 | 107,2 a 115,2 | só se o dragão levantou: 8 respostas |
| o descanso, a volta 2 | 288 a 291, 292 a 307 | 115,2 a 123,2 | só se ele levantou de novo: 8 respostas |
| o fim | a queda + 8 batidas | 110,4 a 126,4 | o dragão no chão |

| constante | valor | o que é |
| --- | --- | --- |
| `RESPOSTAS` | 32 | as respostas do acorde final |
| `EXTRA` | 8 | as respostas de cada volta |
| `FALTAS_MAX` | 6 | mais que isto nas 32, o dragão levanta |
| `FALTAS_MAX_EXTRA` | 2 | mais que isto nas 8 de uma volta, ele levanta de novo (na volta 1) ou cai cansado (na volta 2) |
| `VOLTAS_MAX` | 2 | as voltas extras |
| `RITMOS` | `[[0.0, 0.5], [0.0, 1.0], [0.5, 1.0], [0.0, 1.5]]` | as duas notas do canto, em batidas desde o começo do compasso |
| `FRASE` | `[0.0, 1.0, 1.5, 3.0]` | as quatro notas do eclipse |
| `FIRME` | 0,6 | a chance de pedra numa batida da estação 3 |
| `R2_CLIQUE`, `R2_SOLTA` | 0,62, 0,2 | o tiro e o rearme (os da M1) |
| `LATENCIA_MIC` | 0,08 s | do som ao nível subir (o da P1) |
| `PONTOS` | `[0, 50, 75, 100]` | por nota; cada resposta do acorde final vale o dobro |

### As regras

- **O hoqueto (estações 1 e 3):** a batida `x` da estação é de `presentes()[(x - de) % np]`. Cada nota abre uma batida
  antes. Com `Ritmo.simples[l]`: uma nota dele sim, uma não.
- **O hoqueto do sopro (estação 4):** só as batidas pares da estação têm nota, e a batida `x` com `(x - de) % 2 == 0` é
  de `presentes()[((x - de) / 2) % np]`. A voz precisa de 0,8 s entre um sopro e outro para parar e começar de novo.
- **Atirar:** o R2 de todos em `Forja.gatilho(l, 1, Forja.GATILHO_ARMA, 2, 6, 8)` do primeiro quadro da estação até
  o último; depois, `Forja.gatilhos_off(l)`. O tiro é o R2 cruzando `R2_CLIQUE` subindo, com o R2 rearmado (abaixo de
  `R2_SOLTA` desde o último tiro) → `julgar_toque(l, t(x), n)`. No tiro, `Forja.som_falante(l, "clique", 0.6)` no
  dono. O alvo de 8 lados da raia dele acende em `t(x) - 0.45 - _gancho(l, "pista") / 1000.0` (o aviso da M1: no
  mínimo 0,45 s). Um tiro sem nota aberta não conta.
- **Repetir:** o dono é o compasso. O compasso `c` da estação (`c0 = 52 + 4c`) é de `presentes()[c % np]`; com um
  jogador, só os compassos pares têm canto, e o ímpar descansa (a nota da resposta não pode encostar no canto
  seguinte no mesmo alto-falante). O ritmo `[a, b]` sai de `RITMOS` pelo `rng` do kit. O alto-falante do dono canta
  `Forja.som_falante(l, "nota:%d" % l, 0.8)` em `c0 + a` e em `c0 + b`, com a linha `pista` (`canal`
  `alto_falante`, `o_que` o ritmo, como `"0.0-0.5"`). A TV fica calada. A resposta são duas notas com ✕, com alvos
  `c0 + 2 + a` e `c0 + 2 + b`, abertas em `c0 + 2`. Com `Ritmo.simples[l]`: só a primeira nota da resposta abre.
- **Sem alto-falante** (`not Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)`, decidido no primeiro quadro da estação 2):
  o canto do dono toca na TV, `Som.tocar("nota", pos_do_sino, -6.0, TOM_DO_LUGAR[l])`, com a `troca` (`de`
  `alto_falante`, `para` `tv`, `motivo` `sem_placa`) uma vez. O mesmo vale para a chamada do acorde final.
- **O eclipse:** na batida 100, a TV canta `Som.tocar("nota", pos_da_cabeca, -4.0, TOM_DO_LUGAR[k])` na batida
  `100 + FRASE[k]`, com `k` de 0 a 3 (as notas dos quatro lugares, do grave ao agudo). De 104 a 107, todos devolvem
  com ✕ nos alvos `104 + FRASE[k]` (104; 105; 105,5; 107). Com `Ritmo.simples[l]`: só 104 e 105,5.
- **Sentir:** na estação 3, `_firme[x]` pelo `rng` do kit (`FIRME` 0,6, nunca três neblinas seguidas), sorteado para
  as 48 batidas no primeiro quadro da estação. Em `t(x) - 0.2 - _gancho(l, "pista") / 1000.0` (meia batida antes), se
  `_firme[x]`, a pedra na mão do dono: `_pista(l, "material:pedra", "material:pedra", "aviso", n, "firme")` e
  `nova_nota`. Na neblina, nada: o silêncio é a pista. ✕ com a nota aberta → `julgar_toque(l, t(x), n)`. ✕ numa
  batida dele sem pedra, a até `Ritmo.JANELA_BOM` dela → `falha(l)` sem nota (o salto no nada) e `_respondeu(l, x,
  "errado")`. A pedra que passou sem ✕ → `nota_perdida`.
- **O rádio na estação 3:** `_rumble[l] = not Forja.som_tem(l, Forja.PAPEL_HAPTICA)`, decidido no primeiro quadro da
  estação, com a `troca` (`haptica` → `rumble`, `sem_placa`) uma vez.
- **Soprar:** o ouvido da P1 (abaixo). O começo da voz a até 0,35 s do alvo dele → `julgar_toque(l, t(x) +
  LATENCIA_MIC, n)`. Começo de voz longe de toda nota dele não conta nem pune (a sala grita no fim da noite). A nota
  que passa sem voz até `t(x) + LATENCIA_MIC + Ritmo.JANELA_BOM` → `nota_perdida`.
- **O silêncio do sopro:** na estação 4, `_nota_no_falante = false` e `_textura_no_acerto = false` (as duas chaves do
  kit, H08), e esta ficha não manda som nem háptica a nenhum controle de `t(x) - 0.4` a `t(x) + 0.35` de cada nota: o
  microfone não pode ouvir o próprio controle.
- **Sem microfone ou mudo:** no primeiro quadro da estação 4, `_sem_mic[l] = not Forja.som_tem(l,
  Forja.PAPEL_MICROFONE)` (`troca` `microfone` → `sem_microfone`); na batida 158, quem tem `_maior_nivel[l] <= 0.001`
  passa a `_sem_mic` (`motivo` `mudo_no_sistema`). Ele sopra sozinho: as notas dele não abrem, e cada batida de sopro
  dele marca 25 pontos.
- **O acorde final:** 16 compassos (`c0 = 204 + 4c`). Nas batidas `c0` e `c0 + 2`, a chamada `r` (contada de 0 desde
  a 204) vai para `presentes()[r % np]`, pulando quem está sem controle; ninguém conectado → a chamada passa sem
  contar. O chamado recebe no mesmo quadro: `Forja.som_falante(l, "nota:%d" % l, 0.8)`, `Forja.sentir(l, "aviso")`, a
  barra de luz a 100 % (`Forja.luz(l, Forja.cor_do_lugar(l))`) e a linha `pista` (`canal` `alto_falante`, `o_que`
  `chamada`). A TV ruge curto: `Som.tocar("grito", pos_da_cabeca, -10.0)`. A nota de resposta abre na chamada, com o
  alvo uma batida depois (`c0 + 1` ou `c0 + 3`). Depois da resposta julgada, a barra volta a 30 %
  (`Forja.cor_do_lugar(l).darkened(0.7)`) em 0,2 s. No acorde final e no repetir, `_nota_no_falante = false`: o
  alto-falante é a pista.
- **As faltas:** cada resposta errada ou perdida soma 1 em `_faltas`. A cabeça do dragão sobe `1.0 / limite` m em 1
  colcheia, e os olhos sobem `0.2 / limite` de energia (de 1,0 até 1,2), com `limite` = `FALTAS_MAX` nas 32 e
  `FALTAS_MAX_EXTRA` nas voltas. A sala vê quanto falta.
- **A conta, quando a última resposta da volta é julgada:**
  - `_faltas <= limite` → **o dragão cai**: `_caiu = true` (ver «O fim e o vencedor»);
  - senão, se `_voltas < VOLTAS_MAX` → **o dragão se levanta** (o momento, abaixo); `_voltas += 1`, `_faltas = 0`; a
    volta começa depois de 1 compasso de descanso;
  - senão → **o dragão cai cansado**: `_caiu = true`, `coop_venceu = false`.
- **Pontos:** `PONTOS[j]` por nota com `marcar(l, ...)`; resposta do acorde final, o dobro.
- **A curva:** as estações são a curva (19,2 s cada, o eclipse no meio, o acorde final que junta os quatro). No
  primeiro quadro da batida 204 sai `anotar("momento", -1, {"nome": "reta", "lugar": -1, "t_musica":
  Ritmo.t_musica()})` e `Som.tocar("especial", pos_da_cabeca, -4.0)`.
- **Ensina sem falar:** cada estação usa o objeto do minigame de origem (o alvo, o sino, a laje, o braseiro). O objeto
  da estação seguinte sobe do chão (y −0,5 → 0 com `ENTRA_SAI`) nas 4 batidas antes dela, e o da que acabou desce nas
  2 batidas depois. A dica do kit mostra o glifo do verbo sempre.

### O dragão se levanta (o momento)

No quadro em que a conta manda levantar:

1. `anotar("momento", -1, {"nome": "levanta", "lugar": -1, "t_musica": Ritmo.t_musica(), "objeto": {"faltas":
   _faltas, "volta": _voltas + 1}})`;
2. `Forja.sentir(l, "explosao")` em todos os presentes, no mesmo quadro (ninguém tem nota no descanso);
3. o degrau **catástrofe**: o corpo sobe 0,6 m e a cabeça vai a `CABECA_EM_PE + 0.6` em 1 batida, com
   `ENTRA_SAI`; os olhos a 1,2; `Som.tocar("martelo", pos_da_cabeca, 0.0)`; `tremer(TREMOR_CATASTROFE)`
   (0,08 m, 4 batidas, decai sozinho na câmera da G05); a `light_energy` das `_tochas` +20 % e a `fog_density` ×0,8
   em 1 batida, voltando em 2 (ver «A cena»); sem parada;
4. na última batida do descanso, o dragão se ajoelha de novo (a cabeça a `CABECA_AJOELHADO`, o corpo a 0) em 1 batida,
   e os olhos voltam a 1,0: a volta começa do zero.

Com `Opcoes.movimento == 1`: a câmera da G05 já não treme; a ficha chama `tremer` igual.

### A falha

- **Atirar:** o alvo não se parte; o cavaleiro faz `emote-no` em 0,3 s.
- **Repetir:** o sino dele balança torto 1 batida (±25° em `rotation.z`, volta com `MOLA`).
- **Sentir:** o salto no nada: o cavaleiro some (`visible = false`) e volta inteiro depois do `_queda_s`; `Forja.sentir(l,
  "golpe")` nos dois modos.
- **Soprar:** o braseiro cospe cinza: 12 faíscas `Efeitos.faiscas(self, pos_do_braseiro, Tema.ETIQUETA_SOMBRA, 12,
  0.6)`.
- **Em toda estação, o dragão ri:** a mandíbula abre 10° e fecha em 1 batida.
- **A queda do cavaleiro:** a nota do lugar que cairia antes de `t_erro + _queda_s(l, verbo)` não abre (nem acerta nem
  erra), com `_queda_s = maxf(0.1, snappedf(tempos × 0.4 × _gancho(l, "levantar"), 0.1))` e `tempos` de
  `QUEDA_TEMPOS` (1 em atirar, repetir, eclipse, soprar e no acorde final; 2 em sentir). No acorde final, a resposta
  que cairia dentro da queda conta como falta, para as 32 continuarem 32.

### O fim e o vencedor

O `coop` vem do gênero da FICHA (H08). Na conta que derruba:

- **O dragão cai** (`_caiu = true`, `coop_venceu = true`): a cabeça desce a y 1,0 e avança a z −3,5 em 2 compassos com
  `ENTRA_SAI`; os olhos vão a 0 em 2 batidas; `Forja.sentir(l, "explosao")` em todos; quando a cabeça toca o chão,
  `Som.tocar("golpe", pos_da_cabeca, 0.0)`; a chuva de luz, `Efeitos.faiscas(self, pos_da_cabeca, Tema.TUNGSTENIO,
  120, 2.0)` e `Efeitos.brasas(self, Vector3(0, 6, -4), Vector3(16, 4, 6), Tema.TUNGSTENIO, 96)`, que ficam até o
  pódio.
- **O dragão cai cansado** (`_caiu = true`, `coop_venceu = false`): a mesma queda, sem a chuva de luz e sem a
  `explosao`.

Nos dois casos, `_fim_batida = floor(Ritmo.batida()) + 8` e todos acabam nela. O registro grava `vencedor` −1 (coop);
`destaque()`: quem errou menos no medley inteiro (`_erros[l]`), depois mais pontos. A noite segue ao pódio
(`main.gd`).

### Com menos de quatro

| jogadores | o que muda | `com_poucos()` |
| --- | --- | --- |
| 3 | o hoqueto, os compassos do repetir e as chamadas se repartem por três | `""` |
| 2 | cada um tem metade | `""` |
| 1 | ele toca todas; o repetir só nos compassos pares; ele responde as 32 sozinho | `""` |

Sem Aprendiz: o coop é de quem joga. **O controle que cai:** as notas dele não abrem nem erram; no acorde final, a
chamada dele pula para o próximo presente conectado. Volta na próxima nota dele.

### O robô

Um ramo por verbo, sempre pelo controle simulado e pelo relógio. No repetir e no acorde final, ele só responde se o som
chegou ao alto-falante simulado dele; no sentir, ele sente a pedra. O robô sorteia no dele: `_robo_rng.seed = rng.seed
+ 99` no `iniciar_jogo()`, para nunca mudar o que o jogo sorteia.

```gdscript
func robo(l: int, _dt: float) -> void:
	if not Forja.robo:
		return
	var b := Ritmo.batida()
	if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
		_robo_ouviu_b[l] = b
	if _verbo_da_vez == SENTIR:
		var prox := ceili(b)
		if b > prox - 0.55 and b < prox - 0.05 and _robo_sente(l).length() > 0.05:
			_robo_firme[l] = prox
	var n: int = _nota[l]
	if n < 0:
		if Forja.eixo(l, Forja.R2) > 0.0:
			Forja.robo_eixo(l, Forja.R2, 0.0, 0.05)        # rearma entre os tiros
		return
	if _robo_tocou[l] == n:
		return
	if _robo_nota[l] != n:
		_robo_nota[l] = n
		_robo_mira[l] = 0.0 if Forja.robo_acerta() else (0.25 if _robo_rng.randf() < 0.6 else 99.0)
	var alvo := float(_alvo[l]) + float(_robo_mira[l])
	match _verbo[l]:
		ATIRAR:
			if Ritmo.t_musica() >= alvo:
				Forja.robo_eixo(l, Forja.R2, 1.0, 0.08)
				_robo_tocou[l] = n
		REPETIR, ECLIPSE, FINAL:
			if not _robo_ouviu_para(l, n):
				return
			if Ritmo.t_musica() >= alvo:
				Forja.robo_apertar(l, Forja.CRUZ, 0.05)
				_robo_tocou[l] = n
		SENTIR:
			if _robo_firme[l] == roundi(_bn[l]) and Ritmo.t_musica() >= alvo:
				Forja.robo_apertar(l, Forja.CRUZ, 0.05)
				_robo_tocou[l] = n
		SOPRAR:
			if Ritmo.t_musica() >= alvo + LATENCIA_MIC:
				Forja.robo_falar(l, 0.8, 0.25)
				_robo_tocou[l] = n


## O que a mão do controle simulado sente agora: (esquerda, direita).
func _robo_sente(l: int) -> Vector2:
	if _rumble[l]:
		var pc := Forja.percepcao(l)
		return Vector2(float(pc.get("forte", 0.0)), float(pc.get("fraco", 0.0)))
	var v := Forja.som_virtual(l)
	return Vector2(float(v.get("esq", 0.0)), float(v.get("dir", 0.0)))
```

`_robo_ouviu_para(l, n)`: no repetir, `_robo_ouviu_b[l] >= c0` do compasso da nota; no acorde final,
`_robo_ouviu_b[l] >= _bn[l] - 1.2`; no eclipse, sempre verdadeiro (a frase é na TV). O ritmo ele lê do minigame
(`_alvo[l]`): o que se prova é que o som chegou. Com o alto-falante com defeito de mentira, ele não responde, e o
registro mostra. O `ruim`, com a mira 99,0, também não responde.

### O ouvido (o da P1, igual)

```gdscript
const VOZ_ACIMA := 0.30     ## a voz acima do piso
const VOZ_FICA := 0.18      ## abaixo disto (acima do piso) a voz parou
const MARGEM_AR := 0.12     ## conta a voz do microfone a menos disto do mais alto
const LATENCIA_MIC := 0.08  ## do som ao nível subir, em s

var _nivel := [0.0, 0.0, 0.0, 0.0]
var _piso := [0.0, 0.0, 0.0, 0.0]
var _falando := [false, false, false, false]
var _pico_voz := [0.0, 0.0, 0.0, 0.0]
var _sem_mic := [false, false, false, false]
var _maior_nivel := [0.0, 0.0, 0.0, 0.0]


func _ouvir(dt: float) -> void:
	var mais_alto := 0.0
	for l in presentes():
		_nivel[l] = float(Forja.som_mic(l).get("nivel", 0.0)) if conectado(l) else 0.0
		_maior_nivel[l] = maxf(_maior_nivel[l], _nivel[l])
		if not _sem_mic[l]:
			mais_alto = maxf(mais_alto, _nivel[l])
	for l in presentes():
		var pode: bool = conectado(l) and not _sem_mic[l]
		var agora: bool
		if _falando[l]:
			agora = pode and _nivel[l] >= _piso[l] + VOZ_FICA
		else:
			agora = pode and _nivel[l] >= _piso[l] + VOZ_ACIMA and _nivel[l] >= mais_alto - MARGEM_AR
		if not agora and not _falando[l]:
			_piso[l] = lerpf(_piso[l], _nivel[l], minf(1.0, dt * 0.5))
		if agora:
			_pico_voz[l] = maxf(_pico_voz[l], _nivel[l])
		if agora and not _falando[l]:
			_falando[l] = true
			_pico_voz[l] = _nivel[l]
			anotar("voz", l, {"evento": "comecou", "nivel": snappedf(_nivel[l], 0.01), "limiar": snappedf(_piso[l] + VOZ_ACIMA, 0.01)})
			_comecou(l)                  # só na estação 4: casa com a nota aberta dele a até 0,35 s
		elif not agora and _falando[l]:
			_falando[l] = false
			anotar("voz", l, {"evento": "parou", "nivel": snappedf(_pico_voz[l], 0.01), "limiar": snappedf(_piso[l] + VOZ_FICA, 0.01)})
```

O piso começa na média do `nivel` das batidas 1 a 3,5 (`_piso_medido`).

### A pista e a resposta (as da O2, iguais)

```gdscript
func _pista(l: int, esq: String, dir: String, sensacao: String, n: int, o_que: String) -> void:
	if _rumble[l]:
		Forja.sentir(l, sensacao)
	else:
		Forja.som_haptica(l, esq, dir, 1.0)
	anotar("pista", l, {"n": n, "evento": "mandou",
		"canal": "rumble" if _rumble[l] else "haptica", "o_que": o_que})


func _respondeu(l: int, n: int, resposta: String) -> void:
	anotar("entrada", l, {"o": "resposta", "n": n, "resposta": resposta})
```

O canto e a chamada gravam a `pista` com `canal` `alto_falante` (ou `tv` sem a placa) direto, sem o `_pista`.

### Os ganchos

`godot/scripts/minigames/s09/o_ultimo_acorde.gd`:

```gdscript
extends Minigame
## O Último Acorde (S09_J45). O fim da noite: quatro estações sem pausa,
## atirar (R2 até o clique), repetir (o seu controle canta; devolva no ✕),
## sentir (a pedra na mão; ✕ no firme), soprar (a voz no tempo), o eclipse
## e o acorde final: 32 chamadas e respostas divididas entre os quatro. Se
## faltam mais de 6, o dragão se levanta de novo: mais oito.
##
## A falha: a falta sobe a cabeça do dragão. O vencedor: coop (o dragão cai
## na chuva de luz); o destaque é quem errou menos. O alto-falante do dono:
## o canto, a chamada e o clique, só dele. O registro mede: cada estação
## (estacao), as pistas do alto-falante e da háptica com a resposta, a voz,
## o momento levanta. O robô: ouve o próprio alto-falante e sente a pedra.
## Com menos de quatro: o hoqueto e as chamadas se repartem.

const FICHA := { ... }   # a de «A ficha de dados»
enum { ATIRAR, REPETIR, ECLIPSE, SENTIR, SOPRAR, FINAL }
const ROTEIRO := [
	{"de": 4, "ate": 52, "verbo": ATIRAR, "nome": "atirar"},
	{"de": 52, "ate": 100, "verbo": REPETIR, "nome": "repetir"},
	{"de": 100, "ate": 108, "verbo": ECLIPSE, "nome": "eclipse"},
	{"de": 108, "ate": 156, "verbo": SENTIR, "nome": "sentir"},
	{"de": 156, "ate": 204, "verbo": SOPRAR, "nome": "soprar"},
	{"de": 204, "ate": 268, "verbo": FINAL, "nome": "final"},   # as voltas: 272 a 288 e 292 a 308
]
const QUEDA_TEMPOS := [1, 1, 1, 2, 1, 1]   # atirar (M1), repetir (N1), eclipse, sentir (O2), soprar (P1), final
const CABECA_EM_PE := 6.48                 # o centro da cabeça, em y (o dragão a 1,2)
const CABECA_AJOELHADO := 5.48             # no acorde final
# as constantes de «O tempo» e as do ouvido
const NEUTRO := {"empurrao": 1.0, "tranco": 1.0, "ruido": 1.0, "velocidade": 1.0, "levantar": 1.0, "pista": 0.0, "raio": 1.0}

var _verbo_da_vez := ATIRAR
var _trecho := -1
var _nota := [-1, -1, -1, -1]
var _alvo := [0.0, 0.0, 0.0, 0.0]
var _bn := [0.0, 0.0, 0.0, 0.0]          ## a batida da nota aberta
var _verbo := [ATIRAR, ATIRAR, ATIRAR, ATIRAR]
var _n := [0, 0, 0, 0]
var _feita := -1.0
var _armado := [true, true, true, true]
var _firme := {}
var _ritmo := {}                         ## compasso -> [a, b]
var _rumble := [false, false, false, false]
var _sem_falante := [false, false, false, false]
var _voltas := 0
var _faltas := 0
var _respostas := 0                      ## as julgadas da volta de agora
var _r := 0                              ## a próxima chamada
var _caiu := false
var _fim_batida := 9999.0
var _erros := [0, 0, 0, 0]
var _sem_nota_ate := [-1.0, -1.0, -1.0, -1.0]
var _robo_rng := RandomNumberGenerator.new()
var _robo_ouviu_b := [-9.0, -9.0, -9.0, -9.0]
var _robo_firme := [-1, -1, -1, -1]
var _robo_nota := [-1, -1, -1, -1]
var _robo_tocou := [-1, -1, -1, -1]
var _robo_mira := [0.0, 0.0, 0.0, 0.0]


func montar() -> void:
	usa_gatilho = true
	camera_pos = Vector3(0, 11.48, 14.90)   # a G05 recua ×1,0616 a 35 mm: a câmera fica em (0, 12, 16)
	camera_olhar = Vector3(0, 3.0, -3.0)
	_montar_cena()                       # «A cena»
	for l in presentes():
		Forja.gatilhos_off(l)


func iniciar_jogo() -> void:
	_robo_rng.seed = rng.seed + 99


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)
	_trocar_trecho(b)                    # a linha estacao, o R2, as chaves do kit, os objetos, a coleta
	_cantar(b)                           # o canto do repetir; a frase do eclipse
	_chamar(b)                           # a chamada do acorde final
	_distribuir(b)                       # as notas, uma batida antes
	for l in presentes():
		if not conectado(l):
			_nota[l] = -1
			continue
		_pedra(l, b)                     # a pista da estação 3, na hora
		_entrada(l)                      # o R2, o ✕
		_prazo(l)                        # a nota que passou
	_reta(b)
	if b >= _fim_batida:
		for l in presentes():
			acabou[l] = true
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j] * (2 if _verbo[l] == FINAL else 1))
	if _verbo[l] == FINAL:
		_resolver_resposta(false)
	_gesto_do_verbo(l)                   # o alvo que se parte, o sino, o salto, a brasa, o golpe


func falha(l: int) -> void:
	_erros[l] += 1
	jogador(l).gesto("emote-no", 0.3)
	_sem_nota_ate[l] = Ritmo.t_musica() + _queda_s(l, _verbo[l])
	if _verbo[l] == FINAL:
		_resolver_resposta(true)
	_falha_da_estacao(l)


func _resolver_resposta(faltou: bool) -> void:
	_respostas += 1
	if faltou:
		_faltas += 1
		_subir_a_cabeca()
	var limite := FALTAS_MAX if _voltas == 0 else FALTAS_MAX_EXTRA
	if _respostas < (RESPOSTAS if _voltas == 0 else EXTRA):
		return
	_respostas = 0
	if _faltas <= limite:
		_derrubar(true)
	elif _voltas < VOLTAS_MAX:
		_levantar()                      # o momento
	else:
		_derrubar(false)


func destaque() -> int:
	var lista := presentes()
	lista.sort_custom(func(a, b): return _erros[a] < _erros[b] or (_erros[a] == _erros[b] and pontos[a] > pontos[b]))
	return int(lista[0]) if not lista.is_empty() else -1


func _queda_s(l: int, verbo: int) -> float:
	return maxf(0.1, snappedf(QUEDA_TEMPOS[verbo] * 0.4 * _gancho(l, "levantar"), 0.1))


func _gancho(l: int, nome: String) -> float:
	return float(NEUTRO[nome])   # troque por Cavaleiro.gancho(l, nome) quando `grep -rn "static func gancho" godot/scripts/` achar
```

As outras funções, uma frase cada:

- `_trocar_trecho(b)`: no primeiro quadro de cada trecho, `anotar("estacao", -1, {"nome": nome, "evento": "comecou",
  "batida": de})`, `Som.tocar("transicao")`, `Forja.som_falante(l, "coleta", 0.7)` em todos (fora da estação 4); o
  R2 em arma na entrada da estação 1 e solto na saída; `_nota_no_falante` falso no repetir, no soprar e no acorde
  final, verdadeiro no resto; `_textura_no_acerto` falso só no soprar; o `_rumble`, o `_sem_falante` e o `_sem_mic`
  nas estações que os usam.
- `_distribuir(b)`: para a batida `x = floor(b) + 1` (uma vez cada, `_feita`), quem toca e com que verbo, pelas
  regras; nada antes de `_sem_nota_ate[l]`; `_nota[l] = _n[l]`, `_n[l] += 1`, `_verbo[l]`, `_bn[l]`, `_alvo[l]`,
  `nova_nota`. No acorde final, a resposta abre na chamada (`_chamar`).
- `_entrada(l)`: `ATIRAR`, o R2 cruzou `R2_CLIQUE` armado (o `_armado` volta abaixo de `R2_SOLTA`); `REPETIR`,
  `ECLIPSE`, `SENTIR`, `FINAL`, `Forja.apertou(l, Forja.CRUZ)`; o `SOPRAR` vem do `_comecou(l)`.
- `_subir_a_cabeca()`: a cabeça a `CABECA_AJOELHADO + _faltas * 1.0 / limite` em 1 colcheia, os olhos a
  `1.0 + _faltas * 0.2 / limite` (até 1,2).
- A dica, com `na_raia(l)`, sempre: `["@r2"]`, `["@cross"]` (repetir, eclipse, sentir, acorde final), `["@mic"]`.
- `progresso()`: `"Atire!"`, `"Repita!"`, `"Repita!"` no eclipse, `"Salte no firme!"`, `"Sopre!"`, `"Responda!"`.
  `status(l)`: `"%d erros" % _erros[l]`.

### A casa nova e o catálogo

1. Criar o script; `"$GODOT" --headless --path godot --import --quit`; commitar o `.uid`.
2. `catalogo.gd`: `"S09_J45": preload("res://scripts/minigames/s09/o_ultimo_acorde.gd")` em `MINIGAMES`; `"S09_J45"`
   na lista da seção `S09`, depois do `S09_J44`.

### As frases

| português | inglês |
| --- | --- |
| O Último Acorde | The Last Chord |
| Derrube o dragão! | Bring down the dragon! |
| Acorde! | Chord! |
| Responda! | Answer! |

`"Atire!"` veio da M1, `"Repita!"` da N1, `"Salte no firme!"` da O2, `"Sopre!"` da P1 e `"%d erros"` da Q4.

### O registro

- `estacao` a cada trecho (`atirar`, `repetir`, `eclipse`, `sentir`, `soprar`, `final`): no fim da noite, o jogador
  ainda percebe as pistas do controle como no começo?
- `pista` do canto e da chamada (`canal` `alto_falante`, ou `tv` sem a placa) e da pedra (`canal` `haptica` ou
  `rumble`), com a `entrada` `resposta`;
- `saida` do gatilho de arma (o `Forja`, F06), `voz` do sopro, `nota` e `toque` de tudo;
- `troca` `alto_falante` → `tv`, `haptica` → `rumble`, `microfone` → `sem_microfone`;
- `momento` `reta` e `levanta`; `sensacao` `explosao`, `golpe`, `aviso`.

### Armadilhas

- **O alto-falante toca um som por vez:** vitória > julgamento > segredo > pio > coleta > clique. Por isso o
  `_nota_no_falante` desliga no repetir, no soprar e no acorde final, e o repetir com um jogador descansa nos
  compassos ímpares.
- **O microfone ouve o controle:** no soprar, nada toca no controle de `t(x) - 0.4` a `t(x) + 0.35`. A coleta da troca
  para a estação 4 não toca.
- **O robô só responde se o som chegou** ao alto-falante simulado dele. Não tire essa porta: é ela que faz o defeito do
  alto-falante aparecer no registro.
- **A conta das voltas vem da resposta julgada,** não da batida: a última resposta pode cair na janela da batida
  seguinte.
- **A prova fica mais longa** (até 126,4 s de relógio): a checagem do medley roda só na rodada sem a bancada.

## A cena

- **A câmera:** a arena (35 mm, plongée de 25,3°, nunca corta). `camera_pos = Vector3(0, 11.48, 14.90)`,
  `camera_olhar = Vector3(0, 3.0, -3.0)`. No modo `"fixa"`, a G05 recua a câmera por `Lente.recuo(35)` = 1,0616 a
  partir do olhar: `olhar + (camera_pos − olhar) × 1,0616` = (0, 12,0, 16,0), que é onde se mediu. Medido por projeção com 37,8° vertical e 16:9: a cabeça do dragão em pé
  (0, 5,52 a 7,44, −6) cai em x 0,50 e y de 0,27 a 0,15; ajoelhado (4,52 a 6,44) em y de 0,33 a 0,21; levantado
  (6,12 a 8,04) em y de 0,23 a 0,11 (`altura_tela` 0,127); o pé do dragão (0, 0, −6) em y 0,58; os pés dos cavaleiros
  (±6, 0, `Z_JOGADOR`) em x 0,23 e 0,77, y 0,87; a frente das raias (±6, 0, 3,4) em y 0,98; os alvos (±6, 2,5, −1,5)
  em x 0,25 e 0,75, y 0,58. Sem `camera_foco` (o dragão é de todos).
- **A luz** (S9): a ficha não chama `Tema.luz_da_secao`. A entrada da sala chama `acender(9, partida.lado() == "B")` (G15 e
  G16): no lado A, densidade 0,012 e energia da chave 1,8; no lado B, 0,0156 e 1,53. A chave são as tochas de `luzes()`:
  o `Sala.acender(luz)` as pinta. Logo depois do `luzes(...)`, a ficha guarda em `_tochas` os `OmniLight3D` filhos da
  sala, menos o enchimento de cima, em (0, 9, 2). Quando a ficha mexe na chave, multiplica a `light_energy` das `_tochas`
  sobre a `energia_chave` que a G15 pôs. O preenchimento é `environment.ambient_light_energy` (0,42 pela G15) e a névoa
  é `environment.fog_density`, com `var environment := get_viewport().find_world_3d().environment`; os dois voltam ao
  valor de antes. As tochas: `luzes([Vector3(-9, 3, 3), Vector3(9, 3, 3)])`.
  - No eclipse, a `light_energy` das `_tochas` a ×0,3 em 1 batida, de volta em 2 batidas depois da 107.
  - No sentir, as `_tochas` a ×0,5 em 1 batida (de volta em 2 batidas depois da 155), e a luz de dono de cada raia: um
    `OmniLight3D` da ficha, cor `Tema.JOGADOR[l]`, energia 0,9, sem sombra, em `(RAIAS[l], 0.6, Z_JOGADOR - 1.4)`
    (sobre a laje), alcance `3.4 × _gancho(l, "raio")` m (2,7 a 4,1 m), aceso só na estação 3.
  - No momento, as `_tochas` +20 % e a `fog_density` ×0,8 (ver «O dragão se levanta»).
- **O dragão:** o da Q4, as mesmas peças e números, dentro de um `Node3D` `_dragao` em (0, 0, 0) com `scale` 1,2 (a
  cabeça fica em (0, 6,48, −6)). Os olhos `Tema.neon(Tema.VIOLETA, 1.0, "mundo")`. Ele respira 0,1 m por compasso. No
  acorde final, ele se ajoelha (a cabeça a `CABECA_AJOELHADO` em 1 compasso a partir da 204).
- **As raias e os cavaleiros:** `raia(l)` e `posicionar(l)`, de frente para o dragão (`rotation.y = PI`). Os gestos:
  `holding-right-shoot` no atirar, `interact-right` no repetir e no eclipse, `jump` no sentir, `interact-left` no
  soprar, `attack-melee-right` no acorde final.
- **Os objetos das estações** (de cada raia, visíveis na estação deles):
  - atirar: o alvo de 8 lados, `Kit.cilindro(self, 0.5, 0.1, Vector3(RAIAS[l], 2.5, -1.5), mat)` com
    `radial_segments = 8` e `rotation.x = PI / 2`, em `Kit.material(Tema.GRAFITE, 0.0, 0.9)`; a borda (um segundo
    cilindro de 0,55 × 0,05) acende `Tema.neon(Tema.JOGADOR[l], 2.0, l)` no aviso; no acerto, o alvo se parte em duas
    metades que caem em 1 batida e voltam inteiras na nota seguinte dele;
  - repetir: o sino, `Kit.cilindro(self, 0.35, 0.5, Vector3(RAIAS[l], 2.2, Z_JOGADOR - 1.4), Kit.material(Tema.OXIDO,
    0.0, 0.6), 0.15)`, com o aro (cilindro de 0,37 × 0,04 na boca) que acende na cor do dono a 2,0 no canto dele e
    balança 1 batida;
  - sentir: a laje de pedra, `Kit.caixa(self, Vector3(1.2, 0.2, 1.2), Vector3(RAIAS[l], 0.1, Z_JOGADOR - 1.4),
    Kit.material(Tema.GRAFITE, 0.0, 0.9))`, que aparece no acerto, quando ele pousa, e some em 1 batida; o pouso
    levanta `roundi(10 * _gancho(l, "ruido"))` faíscas `Tema.ETIQUETA_SOMBRA`; o salto leva `0.4 /
    _gancho(l, "velocidade")` s;
  - soprar: o braseiro, `Kit.cilindro(self, 0.45, 0.5, Vector3(RAIAS[l], 0.25, Z_JOGADOR - 1.4),
    Kit.material(Tema.GRAFITE, 0.0, 0.9), 0.6)`, com a brasa `Kit.esfera(braseiro, 0.25, Vector3(0, 0.35, 0), mat)`
    que acende `Tema.neon(Tema.JOGADOR[l], 2.0, l)` em `t(x) - 0.4 - _gancho(l, "pista") / 1000.0` e cresce com a voz
    (escala `1 + 1.5 × nivel`);
  - acorde final: nenhum objeto; o chamado tem o aro de luz do kit aceso.
- **Os brilhos e os donos:**

  | o quê | dono | energia |
  | --- | --- | --- |
  | o contorno de cada cavaleiro | o lugar | 2,4 |
  | o acento da peça (friso, costura, runa do item) | o lugar | 1,6 (o da G13) |
  | a borda do alvo, o aro do sino, a brasa | o lugar | 2,0 na nota dele; 0 fora |
  | os olhos do dragão | `"mundo"` | 1,0; até 1,2 com as faltas e no momento |
  | a chuva de luz | `"forja"` (`TUNGSTENIO`) | 2,0 nas faíscas; 1,0 nas brasas |
  | a luz de dono do sentir | o lugar | 0,9 (luz, não brilho) |
  | o alvo, o sino, a laje, o braseiro, o dragão | ninguém | 0 (impressos) |

- **O que sai:** o `Kit.arena`, a `atmosfera` com `Tema.ROXO` e as cores escritas à mão da ficha antiga (a névoa, a
  chuva de luz): nenhum `Color("#...")` no script.

## O som

| quando | onde | id do mapa | como |
| --- | --- | --- | --- |
| a partida | TV | `mus_s09_j45` (150 BPM, Mi menor; reserva `sint_trilha`) | a FICHA, `"faixa": "MUS_S09_J45"` |
| a troca de estação | TV; controle de todos | `transicao_0`/`1`; `mod_coleta` | `Som.tocar("transicao")`; `Forja.som_falante(l, "coleta", 0.7)` (não na entrada do soprar) |
| o tiro | controle do dono | `mod_clique` | `Forja.som_falante(l, "clique", 0.6)` |
| o alvo que se parte | TV | `golpe_0` | `Som.tocar("golpe", pos_do_alvo, -6.0)` |
| o canto, a chamada | controle do dono | `mod_nota_p1..p4` (0,42 s) | `Forja.som_falante(l, "nota:%d" % l, 0.8)` |
| o canto sem a placa | TV | `sint_nota` | `Som.tocar("nota", pos_do_sino, -6.0, TOM_DO_LUGAR[l])` |
| a frase do eclipse | TV | `sint_nota` | `Som.tocar("nota", pos_da_cabeca, -4.0, TOM_DO_LUGAR[k])` |
| a pedra | atuadores do dono | `mod_material_pedra` | `_pista(l, "material:pedra", ...)`; no rádio, `aviso` |
| a reta (batida 204) | TV | `especial_0` | `Som.tocar("especial", pos_da_cabeca, -4.0)` |
| a chamada, o rugido curto | TV | `sint_grito` | `Som.tocar("grito", pos_da_cabeca, -10.0)` |
| o dragão se levanta | TV | `martelo_0` a `martelo_4` | `Som.tocar("martelo", pos_da_cabeca, 0.0)` |
| a cabeça no chão | TV | `golpe_0` | `Som.tocar("golpe", pos_da_cabeca, 0.0)` |
| a textura do acerto | atuadores do dono | `mod_material_metal` | o kit (`"material": "metal"`), fora do soprar |
| o apito, a vitória coop | TV | `jin_apito`; `jin_coop_vitoria` (reserva `vitoria_noite_0`) | o kit |

## O controle

| evento | quem tem a nota | os outros | prova sem a mão |
| --- | --- | --- | --- |
| atirar | o R2 em Arma (2, 6, 8) até o clique; `mod_clique` no tiro | o R2 em Arma | `percepcao(l).gatilho_dir == 0x25` em todos na estação 1, e `0x05` fora dela |
| repetir | o canto de duas notas no alto-falante, só nele; ✕ | nada | `som_virtual(dono).falante > 0.05` e os outros < 0,05 entre `c0 + 0.6` e `c0 + 1.9` |
| sentir | `material:pedra` nos dois atuadores meia batida antes, só na pedra; no rádio, `aviso` | nada | `som_virtual(l)`: entre `x - 0.5` e `x - 0.1`, `esq` e `dir` > 0,05 na pedra e < 0,02 na neblina |
| o salto no nada | `golpe` nos dois modos | — | `percepcao(l).forte > 0` no quadro da queda |
| soprar | o microfone; nada no controle de `t - 0.4` a `t + 0.35` | nada | `som_virtual(dono)`: `falante`, `esq` e `dir` < 0,02 nessa janela; linha `voz` `comecou` a até 0,35 s do alvo |
| a chamada do acorde final | `nota:l` no alto-falante, `aviso` no rumble, a barra a 100 % | a barra a 30 % | `som_virtual(chamado).falante > 0.05` no quadro da chamada; `percepcao(chamado).luz` a menos de 0,08 da cor inteira |
| o dragão se levanta, o dragão cai | `explosao` (1,0/1,0/400) em todos | — | linha `sensacao` `explosao` de cada lugar a até 16,7 ms do `momento` `levanta` |
| a barra de luz | a cor do lugar; no acorde final, 30 % e 100 % na chamada | o mesmo | `percepcao(l).luz` a menos de 0,08 de `cor_do_lugar(l).darkened(0.7)` entre as chamadas |
| as luzinhas | o número do jogador, sempre | o mesmo | `leds_jogador == Forja.LEDS_DO_LUGAR[l]` |
| a troca de estação | `mod_coleta` 0,7 | o mesmo | `som_virtual(l).falante > 0.05` no quadro da troca, em todos, fora da entrada do soprar |

**No rádio:** a pedra vai pelo `aviso`, com a `troca`; o canto e a chamada vão para a TV, com a `troca`; a chamada já
tem o `aviso` junto. **Sem microfone ou mudo:** sopra sozinho (ver «As regras»). Rumble e háptica nunca juntos: a pedra
sai meia batida antes da nota, e o `aviso` da chamada uma batida antes da resposta.

## O cavaleiro

- **Os stats** (`minigames.csv`, linha 45: «como no minigame de origem de cada trecho»). Cada verbo usa os ganchos do
  minigame de origem:

  | verbo (origem) | ganchos | o que muda aqui |
  | --- | --- | --- |
  | atirar (M1) | levantar, pista | a queda de 1 tempo × `levantar` (0,5 s a 0,3 s); o alvo acende `pista` antes |
  | repetir e eclipse (N1) | levantar | a queda de 1 tempo × `levantar` |
  | sentir (O2) | ruido, velocidade, levantar, pista, raio | as faíscas do pouso, 10 × `ruido` (8 a 12); o salto em 0,4 s / `velocidade`; a queda de 2 tempos × `levantar` (1,0 s a 0,6 s); a pedra chega `pista` antes; a luz de dono a 3,4 m × `raio` (2,7 m a 4,1 m) |
  | soprar (P1) | levantar, pista | a queda de 1 tempo × `levantar`; a brasa acende `pista` antes |
  | acorde final (N1) | levantar | a queda de 1 tempo × `levantar` |

  Os fatores: `ruido` ×0,8 a ×1,2, `velocidade` ×0,94 a ×1,06, `levantar` ×1,25 a ×0,75, `pista` −40 a +40 ms, `raio`
  ×0,8 a ×1,2, do stat 1 ao 5. Nenhum stat mexe na janela de julgamento, nas faltas nem nos pontos.
- **A conta:** `_gancho(l, nome)` devolve o neutro até existir `Cavaleiro.gancho`.
- **Como aparece:** o cavaleiro entra como a G13 o montou (a raça, a cabeça, o superior em tecido L 0,46 a 0,58, o
  inferior em couro L 0,22 a 0,36), sem tinta do minigame. O néon do dono é o friso e a costura a 1,6 e o contorno a
  2,4. A raça (humana, orc, autômato, golem, raposa) não muda a cápsula, a velocidade nem a janela. O salto no nada
  esconde o cavaleiro e o devolve inteiro, sem trocar material.
- **O item:** fica onde a G13 o pôs; a ficha não põe nada na mão.

## As reações

- **Adesivo:** nenhum durante o jogo; todos jogam a partida inteira.
- **Os carimbos que este minigame pode disparar** (o jogo detecta pelo registro):

  | carimbo | o evento aqui | onde |
  | --- | --- | --- |
  | `car_acorde` | os quatro com PERFEITO na mesma batida de tempo 1 (`b % 4 == 0`): só a 104 tem nota de todos no tempo 1 (a primeira do eclipse) | centro da tela, y 300 |
  | `car_em_chamas` | 5 PERFEITOs seguidos do mesmo lugar | acima da cabeça dele |

  Quando dois disputam a vez: `car_acorde` > `car_em_chamas`. O `car_por_um_fio` não sai: é coop.

## A diversão

**O grito: o dragão se levanta de novo** (`levanta`). Nas 32 respostas do acorde final, cada falta sobe a cabeça do
dragão 1/6 m e acende mais os olhos; com mais de 6, ele se levanta, a TV bate o martelo e vêm mais 8. O alívio vem
depois: o dragão cai na chuva de luz. Degrau catástrofe.

- **O grito acontece no meio da tela:** a cabeça do dragão em `x_tela` 0,50, com `altura_tela` 0,127.
- **Rastro:** a chuva de luz fica até o pódio.
- **Quem está perdendo:** é coop; a cabeça e os olhos do dragão contam quanto falta, e o dragão que levanta dá mais 8
  respostas à turma, nunca o fim de cara.
- **Como o jogador do time confere:**
  1. mesa boa (os quatro `bom`, semente 7): nenhuma linha `momento` `levanta`, e `coop_venceu` no fim;
  2. mesa fraca (os quatro `medio`, semente 7): pelo menos 1 linha `momento` `levanta` com `t_musica` de 82 a 120 s,
     e o dragão no chão no último quadro;
  3. cada `momento` `levanta` tem uma `sensacao` `explosao` de cada lugar a até 16,7 ms;
  4. na prancha da mesa fraca, o dragão de pé num quadro e caído no último.

## Pronto quando

O `S09_J45` joga do aviso ao resultado com 4, 3, 2 e 1 jogador e com o robô nos três temperamentos (o `bom` derruba o
dragão sem ele levantar; o `ruim` o faz levantar duas vezes e cair cansado), aguenta o cabo que cai e volta, passa
pelas quatro estações, o eclipse e o acorde final sem pausa na música, fecha com o resultado coop e o destaque, faz o
momento `levanta` na mesa fraca, e não tem nenhuma cor escrita à mão; as provas abaixo passam e a prancha foi olhada.

## Provas

Em `godot/testes/prova_do_jogo.gd`, com a linha `"S09_J45": await _prova_o_ultimo_acorde()` no `match` de
`_prova_da_ficha(slot)`, chamada só na rodada sem a bancada (`if not Forja.bancada:`):

```gdscript
## S09_J45: o R2 em arma só no atirar; o canto só no alto-falante do dono;
## o soprar com o controle calado; as 32 respostas; o robô bom derruba o dragão.
func _prova_o_ultimo_acorde() -> void:
	var conta := {"arma": false, "arma_fora": false, "canto": false, "canto_privado": true, "barulho_no_sopro": false}
	var olhar := func(mg: Minigame) -> void:
		var b := Ritmo.batida()
		for l in mg.presentes():
			var g := int(Forja.percepcao(l).get("gatilho_dir", 0x05))
			if mg._verbo_da_vez == mg.ATIRAR and g == 0x25:
				conta.arma = true
			elif mg._verbo_da_vez != mg.ATIRAR and b > 53.0 and g == 0x25:
				conta.arma_fora = true
			if mg._verbo_da_vez == mg.SOPRAR and mg._nota[l] >= 0:
				var falta := Ritmo.t_musica() - float(mg._alvo[l])
				var v := Forja.som_virtual(l)
				if falta > -0.4 and falta < 0.35 and maxf(float(v.get("falante", 0.0)), maxf(float(v.get("esq", 0.0)), float(v.get("dir", 0.0)))) > 0.02:
					conta.barulho_no_sopro = true
		var dentro := fposmod(b - 52.0, 4.0)
		if mg._verbo_da_vez == mg.REPETIR and dentro > 0.6 and dentro < 1.9:
			var tocando := []
			for l in 4:
				if float(Forja.som_virtual(l).get("falante", 0.0)) > 0.05:
					tocando.append(l)
			if tocando.size() == 1:
				conta.canto = true
			elif tocando.size() > 1:
				conta.canto_privado = false
	var mg := await _joga_o_minigame("S09_J45", 170.0, olhar)
	if mg == null:
		return
	_esperar(conta.arma and not conta.arma_fora, "S09_J45: o R2 em arma (0x25) só no atirar")
	_esperar(conta.canto and conta.canto_privado, "S09_J45: o canto sai só no alto-falante do dono")
	_esperar(not conta.barulho_no_sopro, "S09_J45: nada toca no controle de quem sopra")
	_esperar(mg._caiu and mg.coop_venceu, "S09_J45: o robô bom derrubou o dragão")
	_esperar(mg.coop and mg.destaque() >= 0, "S09_J45: o resultado é coop, com o destaque")
```

No `_prova_do_relatorio()`, com as linhas do `S09_J45`:

- as linhas `estacao` são seis, na ordem do roteiro;
- há `pista` com `canal` `alto_falante` de cada lugar, e `pista` com `o_que` `firme`;
- há `voz` `comecou` de cada lugar com microfone;
- 32 linhas `toque` ou `nota` julgadas com verbo do acorde final, a partir da batida 204;
- nenhuma `sensacao` e nenhum `som_controle` de háptica no mesmo controle e no mesmo quadro.

Os comandos:

```bash
SALA=S09_J45 bash tests/prova_do_jogo.sh
bash tests/prova_visual.sh
bash tests/prova_sem_rastro.sh
```

A mesa boa e a mesa fraca rodam hoje, porque o temperamento é um só para os quatro: `--robo=bom --semente=7` e
`--robo=medio --semente=7`.

**As pranchas que se olham** (`SAIDA/prancha-<n>.png`):

- a de quatro com `bom`: as estações trocando, os objetos de origem, o dragão caindo na chuva de luz;
- a de quatro com `medio`: o dragão de pé num quadro (o momento) e caído no último;
- a de um: o cavaleiro sozinho, o repetir só nos compassos pares;
- a do cabo que cai: a chamada dele pulando para o próximo;
- nas quatro: as roupas de cima e de baixo de cada cavaleiro em valores diferentes, e o néon só no friso e na costura.

**Com o André (local):** `./run-local.sh -- --sala=S09_J45`, com quatro, no fim de uma noite. O canto no controle tem
de ser reconhecível e só seu; a pedra na mão ainda tem de ser sentida no fim; o acorde final tem de soar como a música
dividida entre os quatro; e o dragão caindo tem de parecer o fim de uma noite.
