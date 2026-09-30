# H01 — O relógio de áudio

**Sprint:** H · **Tamanho:** M · **Estimativa:** US$ 3,0 · **Depende de:** F00

## Por quê

Todo tempo do jogo é soma de `delta` e escorrega da música. O relógio
passa a ser a placa de som: o autoload `Ritmo` diz a posição da música que
se ouve agora e a batida, e todo o resto (as janelas da H02, o kit da H04)
lê dele.

## Ler antes

- [A arquitetura: o relógio de áudio e o julgamento](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03) (a API, e só ela)
- [O relógio de áudio](../04-ritmo-e-audio.md#o-relógio-de-áudio)
- [A paridade entre a prova e o jogo](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08) (as regras 1, 2 e 7)

## O estado de hoje

- Não existe relógio de música. `godot/project.godot:13-17` tem três
  autoloads: `Forja`, `Som`, `Musica`.
- `godot/scripts/musica.gd:11-24`: a tabela `FAIXAS` é por sala
  (`"centelha": [60, 108, 2]` = tônica, bpm, energia). `tocar(id)`
  (`musica.gd:65-82`) troca com um fade de 0,8 s entre dois
  `AudioStreamPlayer`, e o tween não fica guardado em lugar nenhum:

  ```gdscript
  var tw := create_tween().set_parallel(true)
  tw.tween_property(velho, "volume_db", -80.0, FADE_S)
  ...
  novo.play()
  tw.tween_property(novo, "volume_db", VOLUME_DB, FADE_S)
  ```

- A trilha é sintetizada pelo módulo, oito compassos em laço
  (`nativo/som/sintese.c:439-446`). O tempo vira um número inteiro de
  amostras, e o andamento escorrega do pedido:

  ```c
  float tempo = 60.0f / bpm;
  int por_tempo = (int)(tempo * SINT_TAXA);   /* 108 bpm → 26666 amostras → 108,0027 bpm */
  ```

  Em três minutos, os 0,0027 bpm dão uns 4,5 ms — quase o limite do "Pronto
  quando". O `Ritmo` tem de usar o andamento **de verdade** da síntese.
- A entrada dos controles não passa pelo `Input` do Godot: o módulo lê o SDL
  uma vez por quadro (`godot/scripts/forja.gd:349`, `apertou()` →
  `ctl.apertou`). O `Input.use_accumulated_input` só mexe no teclado e no
  mouse; desliga-se mesmo assim, como o 04 pede.
- O que foi **medido** nesta preparação (Godot 4.4.1, `--headless`, driver
  `Dummy`, um `AudioStreamPlayer` com um WAV em laço de 2 s):
  - `AudioServer.get_output_latency()` devolve `0.0` e custa 1 µs no Dummy
    (num driver de verdade pode custar caro: continua lida uma vez por faixa);
  - `get_playback_position() + get_time_since_last_mix()` anda, mas **recua
    um pouco** às vezes (3 recuos em 30 s): o `max` com o anterior é
    obrigatório;
  - a posição **volta ao começo** a cada laço: é preciso contar as voltas;
  - o Dummy mistura um pouco mais devagar que o relógio do sistema (−90 ms
    em 27 s): nunca compare o relógio da placa com o do sistema numa prova da
    nuvem;
  - com `--fixed-fps 60 --headless`, o jogo roda muito mais depressa que o
    relógio de parede (numa cena vazia, 750 quadros por segundo de parede);
  - `play()` de um `AudioStreamPlayer` fora da árvore dá erro
    (`Playback can only happen when a node is inside the scene tree`).

## O alvo

A API do [13](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03),
com o que falta para ela funcionar. O que não está no 13 hoje (marcado
**novo**) entra no 13, no mesmo commit, na seção do relógio.

`godot/scripts/ritmo.gd` (autoload `Ritmo`, sem `class_name`) — o arquivo
inteiro desta ficha (a H02 acrescenta o julgamento embaixo):

```gdscript
extends Node
## O relógio do jogo de ritmo (autoload «Ritmo»): a posição da música que se
## ouve agora e a batida. Ninguém soma delta para saber o tempo da música:
## pergunta aqui (docs/jogo/04-ritmo-e-audio.md#o-relógio-de-áudio).
##
## Com uma faixa tocando, o relógio é a placa de som, como no guia do Godot
## 4.4 "Sync the gameplay with audio and music":
##   posição + AudioServer.get_time_since_last_mix() − latência de saída,
## com a latência lida uma vez por faixa (é cara). Sem faixa tocando (A Voz,
## O Canto, o jogo sem o módulo), o relógio do sistema. Nos dois, o tempo
## nunca anda para trás.
##
## O tempo é medido uma vez por quadro, antes das salas (process_priority), e
## todo mundo naquele quadro lê o mesmo número.

signal batida_cheia(n: int)  ## a cada tempo inteiro (n = 0 é o primeiro tempo da faixa)
signal compasso(n: int)  ## a cada 4 tempos (n = 0 é o primeiro compasso)

var slot := ""  ## a faixa que o relógio segue ("" = nenhuma)
var bpm := 120.0
var primeiro_tempo := 0.0  ## s, em tempo de música: onde cai o tempo 0

var _tocador: AudioStreamPlayer = null
var _laco_s := 0.0  ## a duração do laço da faixa (0: não é laço)
var _voltas := 0
var _pos_anterior := 0.0
var _latencia := 0.0
var _t := 0.0  ## o t_musica deste quadro (nunca anda para trás)
var _pelo_audio := false
var _base_us := 0  ## o relógio do sistema: no instante _base_us, o t valia _base_t
var _base_t := 0.0
var _pausado := false
var _batida_anterior := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -90  # depois do Forja (-101) e do módulo (-100), antes das salas (0)
	Input.use_accumulated_input = false
	_base_us = Time.get_ticks_usec()


func _process(_dt: float) -> void:
	_t = maxf(_t, _medir())
	var b := int(floor(batida()))
	while _batida_anterior < b:
		_batida_anterior += 1
		if _batida_anterior >= 0:
			batida_cheia.emit(_batida_anterior)
			if _batida_anterior % 4 == 0:
				compasso.emit(int(_batida_anterior / 4.0))


## Começa a seguir a faixa do slot, do zero. O zero é agendado: o som sai no
## próximo mix, mais a latência (o guia do Godot). Slot vazio, ou sem faixa:
## o relógio do sistema, com o mesmo bpm.
func tocar(slot_da_faixa: String, bpm_da_faixa: float, primeiro_tempo_s: float) -> void:
	slot = slot_da_faixa
	bpm = maxf(bpm_da_faixa, 1.0)
	primeiro_tempo = primeiro_tempo_s
	_latencia = AudioServer.get_output_latency()  # cara: uma vez por faixa, nunca por quadro
	_voltas = 0
	_pos_anterior = 0.0
	_pausado = false
	_t = 0.0
	_batida_anterior = -1
	_tocador = Musica.tocar_do_zero(slot)
	_pelo_audio = _tocador != null
	_laco_s = Musica.laco_s(_tocador)
	_base_t = 0.0
	_base_us = Time.get_ticks_usec() + int((AudioServer.get_time_to_next_mix() + _latencia) * 1000000.0)


## Para de seguir a faixa (a música é da Musica: quem para o som é ela). O
## relógio continua pelo sistema, do ponto em que estava.
func parar() -> void:
	slot = ""
	_tocador = null
	if _pelo_audio:
		_para_o_sistema(Time.get_ticks_usec())


## A pausa (e o diagnóstico) por cima do minigame: o tempo para, e a faixa também.
func pausar(sim: bool) -> void:
	if sim == _pausado:
		return
	_pausado = sim
	if is_instance_valid(_tocador):
		_tocador.stream_paused = sim
	if not sim and not _pelo_audio:
		_base_t = _t
		_base_us = Time.get_ticks_usec()


## A posição da música que se ouve agora, em s (nunca anda para trás).
func t_musica() -> float:
	return _t


## A batida agora: (t_musica − primeiro tempo) × bpm / 60. Negativa antes do primeiro tempo.
func batida() -> float:
	return (_t - primeiro_tempo) * bpm / 60.0


## O t_musica da batida n (n pode ser fracionário: 2,5 é o contratempo do 2).
func t_da_batida(n: float) -> float:
	return primeiro_tempo + n * 60.0 / bpm


## Uma nota nova do lugar, no registro (o tipo `nota` do registro v2).
func registrar_nota(l: int, n: int, t_alvo: float) -> void:
	Forja.evento("nota", l + 1, {"slot": slot, "lugar": l, "n": n, "t_alvo": snappedf(t_alvo, 0.001),
		"t_musica": snappedf(_t, 0.001)})


## A posição sem o salto do laço: quando a faixa volta ao começo, soma uma
## volta. Devolve [posição contínua, voltas]. Pura, para a prova.
static func posicao_continua(pos: float, anterior: float, voltas: int, laco_s: float) -> Array:
	if laco_s > 0.0 and pos < anterior - laco_s * 0.5:
		voltas += 1
	return [voltas * laco_s + pos, voltas]


func _medir() -> float:
	if _pausado:
		return _t
	var agora_us := Time.get_ticks_usec()
	if _pelo_audio:
		if is_instance_valid(_tocador) and _tocador.playing:
			var pos := _tocador.get_playback_position() + AudioServer.get_time_since_last_mix()
			var r := posicao_continua(pos, _pos_anterior, _voltas, _laco_s)
			_voltas = int(r[1])
			_pos_anterior = pos
			return float(r[0]) - _latencia
		# a faixa parou (outra entrou, o jingle cortou): segue pelo sistema
		_para_o_sistema(agora_us)
	return _base_t + (agora_us - _base_us) / 1000000.0


func _para_o_sistema(agora_us: int) -> void:
	_pelo_audio = false
	_base_t = _t
	_base_us = agora_us
```

`godot/scripts/musica.gd` ganha (**novo**, entra no 13):

```gdscript
## O slot de uma faixa (MUS_Sxx_Jyy) enquanto as faixas geradas não chegam
## (H05): a trilha sintetizada da seção. S01 é A Centelha ... S09 é A Prova
## (a ordem das seções de docs/jogo/03).
const SALA_DA_SECAO := ["", "centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]
const TAXA := 48000  ## a taxa da síntese (SINT_TAXA, nativo/som/sintese.h)

var _tw: Tween = null  ## o fade em curso (um só: o novo mata o velho)


## Toca a faixa do slot do zero, sem fade de entrada (o Ritmo parte dela);
## devolve o tocador, ou null quando a faixa é silêncio (e aí a música cala).
func tocar_do_zero(slot: String) -> AudioStreamPlayer:
	var id := _id_da_faixa(slot)
	var s: AudioStreamWAV = _stream(id) if id != "" else null
	if _tw:
		_tw.kill()
	var velho := _tocadores[_ativo]
	_tw = create_tween()
	_tw.tween_property(velho, "volume_db", -80.0, 0.03)
	atual = slot
	if s == null:
		return null
	_ativo = 1 - _ativo
	var novo := _tocadores[_ativo]
	novo.stream = s
	novo.volume_db = VOLUME_DB
	novo.play(0.0)
	return novo


## O mapa de batidas do slot: {bpm, primeiro_tempo, sintetizada}. Da trilha
## sintetizada, o andamento de verdade da síntese; sem faixa, 120. (A H05 lê
## o MUS_*.batidas.json quando a faixa gerada existe.)
func mapa(slot: String) -> Dictionary:
	var f: Array = FAIXAS.get(_id_da_faixa(slot), [])
	if f.size() == 3:
		return {"bpm": bpm_sintetizado(float(f[1])), "primeiro_tempo": 0.0, "sintetizada": true}
	return {"bpm": 120.0, "primeiro_tempo": 0.0, "sintetizada": false}


## A duração do laço da faixa do tocador, em s (0: sem laço ou sem faixa).
static func laco_s(tocador: AudioStreamPlayer) -> float:
	if tocador == null or not tocador.stream is AudioStreamWAV:
		return 0.0
	var w := tocador.stream as AudioStreamWAV
	if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		return 0.0
	return float(w.loop_end - w.loop_begin) / float(w.mix_rate)


## O andamento que a síntese toca de verdade: o tempo vira um número inteiro
## de amostras (sintese.c, `por_tempo = (int)(tempo * SINT_TAXA)`).
static func bpm_sintetizado(bpm: float) -> float:
	var por_tempo := int(60.0 / maxf(bpm, 60.0) * TAXA)
	return 60.0 * TAXA / por_tempo


func _id_da_faixa(slot: String) -> String:
	if FAIXAS.has(slot):
		return slot
	if slot.begins_with("MUS_S") and slot.length() >= 7:
		var s := int(slot.substr(5, 2))
		if s >= 1 and s < SALA_DA_SECAO.size():
			return SALA_DA_SECAO[s]
	return ""
```

`godot/project.godot`, em `[autoload]`, **depois** de `Musica`:

```
Ritmo="*res://scripts/ritmo.gd"
```

## Passos

1. **Medir antes de mudar.** Rode a prova como está
   (`bash tests/prova_do_jogo.sh`) e anote o tempo. Ela tem de estar verde
   antes; se não estiver, pare (é a F00).
2. **`godot/scripts/ritmo.gd`**: crie com o código de "O alvo". Rode
   `"$GODOT" --headless --path godot --import --quit` e confira que nasceu
   `godot/scripts/ritmo.gd.uid`. (`GODOT=tools/Godot_v4.4.1-stable_linux.x86_64`.)
3. **`godot/project.godot`**: acrescente `Ritmo` como último autoload. A ordem
   importa: o `Ritmo` usa `Musica` e `Forja`, que têm de existir antes.
4. **`godot/scripts/musica.gd`**:
   - acrescente `SALA_DA_SECAO`, `TAXA`, `_tw`, `tocar_do_zero`, `mapa`,
     `laco_s`, `bpm_sintetizado` e `_id_da_faixa` do alvo;
   - em `tocar(id)` (linha 65), troque o `var tw := create_tween()...` por
     `if _tw: _tw.kill()` e `_tw = create_tween().set_parallel(true)`, e use
     `_tw` nas duas `tween_property`. Sem isso, um fade velho continua
     puxando o volume do tocador novo para −80 dB;
   - não mude `FAIXAS` nem o que `tocar(id)` faz para as salas de hoje.
   Rode a prova: continua verde (nada chama o `Ritmo` ainda).
5. **`godot/testes/prova_do_jogo.gd`**: acrescente `_prova_do_relogio()` e
   `_medir_o_relogio()` (em "Provas", abaixo) e chame
   `await _prova_do_relogio()` em `_ready()`, logo depois de
   `_prova_o_alto_falante_do_sistema()` e **antes** de instanciar a cena
   principal. Rode a prova.
6. **O metrônomo do André** (a prova que só o ouvido faz): crie
   `godot/testes/metronomo.gd` e `godot/testes/metronomo.tscn`. O script
   (`extends Node`): no `_ready`, `var m := Musica.mapa("MUS_S01_J01")` e
   `Ritmo.tocar("MUS_S01_J01", m.bpm, m.primeiro_tempo)`; conecta
   `Ritmo.batida_cheia` a uma função que toca `Som.tocar("tique", null, 0.0)`
   e pisca um `ColorRect` de tela cheia (branco por 60 ms, depois preto); a
   cada 10 s imprime `"%.1f s: batida %.3f"` com `Ritmo.t_musica()` e
   `Ritmo.batida()`; fecha sozinho em 190 s. A cena:

   ```
   [gd_scene format=3]

   [ext_resource type="Script" path="res://testes/metronomo.gd" id="1"]

   [node name="Metronomo" type="Node"]
   script = ExtResource("1")
   ```

   Importe de novo (os `.uid`). A pasta `testes/` já fica fora da exportação
   (`godot/export_presets.cfg:18`).
7. **O 13**: na seção "O relógio de áudio e o julgamento", acrescente
   `parar()`, `pausar(sim)`, `t_da_batida(n)`, `registrar_nota(l, n, t_alvo)`,
   `posicao_continua(...)` e, numa linha, as funções novas da `Musica`
   (`tocar_do_zero`, `mapa`, `laco_s`, `bpm_sintetizado`). Troque a frase
   "Sem faixa tocando, `t_musica()` anda pelo relógio do sistema, para as
   provas sem som" por "Sem faixa tocando, `t_musica()` anda pelo relógio do
   sistema (A Voz, O Canto, o jogo sem o módulo)".
8. **O registro**: confira se a F06 já grava `lugar` e `t_musica` sozinha em
   toda linha (`grep -n "t_musica\|lugar" nativo/nucleo/linha_tempo.c`). Se
   grava, tire esses dois campos de `registrar_nota` (o JSON não pode ter
   chave repetida).

## Armadilhas

- **Nenhum caminho de prova.** O relógio não sabe se é prova, robô ou
  `--headless`: com faixa tocando, a placa (no `--headless`, o driver
  `Dummy`); sem faixa, o sistema. Nada de `Forja.robo`, de
  `DisplayServer.get_name()` ou de `--fixed-fps` no `ritmo.gd`
  ([F08](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)).
- **O `--fixed-fps 60` separa o jogo do relógio.** Na prova sem janela, um
  segundo de jogo (60 quadros) passa em bem menos de um segundo de parede, e
  o `Ritmo` anda pela parede. Toda espera por música na prova é pelo relógio
  de parede (`Time.get_ticks_usec()`), nunca por número de quadros. Toda
  espera por fase de sala continua em quadros.
- **O Dummy não é o relógio do sistema.** Ele mistura ~0,3% mais devagar e
  começa um bloco adiantado (a latência dele é 0). As checagens da nuvem
  usam folga larga (±30%); a precisão de 5 ms é do André, com driver de
  verdade.
- **O relógio recua de leve e dá a volta.** O `maxf(_t, ...)` e o
  `posicao_continua` não saem, nem "para simplificar".
- **O laço da trilha sintetizada** tem 8 compassos (17,8 s a 108 bpm); o
  `loop_end` do WAV está em amostras (`musica.gd:59`). Se um dia a faixa
  começar o laço fora do zero, `laco_s` e `posicao_continua` precisam mudar
  juntos.
- **Um tween por vez na `Musica`.** Ver o passo 4.
- **A pausa**: o `Ritmo` tem `process_mode = ALWAYS` porque a `Musica` também
  tem (`musica.gd:35`); quem para o tempo é `pausar(true)`, que a H04 chama
  do `congelar()` da sala. Sem isso, as notas passam com o jogo congelado.
- **`AudioStreamPlayer` fora da árvore não toca** (medido). Os tocadores da
  `Musica` já estão na árvore (`musica.gd:36-40`); não crie tocador novo no
  `Ritmo`.
- **A latência é cara**: `get_output_latency()` só dentro de `tocar()`.
- **O robô, o lugar desconectado, o treino**: nada disso existe nesta ficha
  (o `Ritmo` é por música, não por lugar). É da H02 e da H04.
- **`.uid`**: o `ritmo.gd.uid`, o `metronomo.gd.uid` e o `metronomo.tscn`
  entram no commit.
- **Não passe `NAN` nem `INF` ao `Forja.evento`**: o C escreve `nan` e a
  linha do tempo deixa de ser JSON.

## Não fazer

- Não mudar nenhuma sala, nem o `main.gd`: quem usa o `Ritmo` é o kit (H04).
- Não mexer em `nativo/som/sintese.c` para "consertar" o andamento: o jogo
  lê o andamento de verdade (`bpm_sintetizado`).
- Não criar o julgamento aqui (é a H02).
- Não baixar nem tocar faixa gerada (é a H05).

## Pronto quando

Com a trilha sintetizada tocando, `Ritmo.t_musica()` segue a placa, nunca
anda para trás, soma as voltas do laço e dá a batida com o andamento de
verdade; sem faixa, anda pelo relógio do sistema; a prova do jogo passa com
as checagens novas; e o André ouve o metrônomo preso à faixa por três
minutos a 20 e a 60 quadros por segundo.

## Provas

**Na sessão:**

```bash
bash tests/prova_do_jogo.sh
```

As checagens novas em `godot/testes/prova_do_jogo.gd`:

```gdscript
## O relógio (H01): a volta do laço (a conta pura), o relógio do sistema sem
## faixa e o da placa com a trilha sintetizada. Espera pelo relógio de
## parede: com --fixed-fps 60 sem janela, o jogo anda mais depressa que ele.
func _prova_do_relogio() -> void:
	var r := Ritmo.posicao_continua(0.2, 17.6, 0, 17.8)
	_esperar(int(r[1]) == 1 and absf(float(r[0]) - 18.0) < 0.0001, "relógio: a volta do laço soma a duração (%s)" % [r])
	r = Ritmo.posicao_continua(5.0, 4.98, 1, 17.8)
	_esperar(int(r[1]) == 1 and absf(float(r[0]) - 22.8) < 0.0001, "relógio: sem volta, a posição segue")
	var b := Musica.bpm_sintetizado(108.0)
	_esperar(absf(b - 108.0027) < 0.0001, "relógio: o andamento de verdade da síntese (%.4f)" % b)
	await _medir_o_relogio("", 0.8, "sem faixa", false)
	await _medir_o_relogio("MUS_S01_J01", 1.5, "com a faixa", Forja.modulo)
	Ritmo.parar()


func _medir_o_relogio(slot: String, segundos: float, rotulo: String, pela_placa: bool) -> void:
	var mapa := Musica.mapa(slot)
	Ritmo.tocar(slot, float(mapa.bpm), float(mapa.primeiro_tempo))
	_esperar(Ritmo._pelo_audio == pela_placa, "relógio %s: %s" % [rotulo, "pela placa" if pela_placa else "pelo sistema"])
	var sinais := [0]
	var conta := func(_n: int) -> void: sinais[0] += 1
	Ritmo.batida_cheia.connect(conta)
	var inicio := Time.get_ticks_usec()
	var antes := Ritmo.t_musica()
	var recuou := false
	var batida_certa := true
	while Time.get_ticks_usec() - inicio < int(segundos * 1000000.0):
		await _quadros(1)
		var t := Ritmo.t_musica()
		recuou = recuou or t < antes
		antes = t
		var esperada := (t - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
		batida_certa = batida_certa and absf(Ritmo.batida() - esperada) < 0.000001
	Ritmo.batida_cheia.disconnect(conta)
	var andou := Ritmo.t_musica()
	_esperar(not recuou, "relógio %s: nunca anda para trás" % rotulo)
	_esperar(batida_certa, "relógio %s: a batida é (t_musica − primeiro tempo) × bpm / 60" % rotulo)
	_esperar(andou > segundos * 0.7 and andou < segundos * 1.3,
		"relógio %s: andou %.3f s em %.1f s de relógio" % [rotulo, andou, segundos])
	var tempos := int(floor(andou * float(mapa.bpm) / 60.0)) + 1  # o tempo 0 também conta
	_esperar(absi(sinais[0] - tempos) <= 1, "relógio %s: um sinal por tempo (%d sinais, %d tempos)" % [rotulo, sinais[0], tempos])
```

**Com o André, local:** ver "Para o André".

## Para o André (local)

```bash
./run-local.sh   # uma vez, para compilar e importar
tools/Godot_v4.4.1-stable_linux.x86_64 --path godot --max-fps 20 res://testes/metronomo.tscn
tools/Godot_v4.4.1-stable_linux.x86_64 --path godot --max-fps 60 res://testes/metronomo.tscn
```

Nos dois, por três minutos: o tique e o clarão têm de cair no bumbo da
trilha d'A Centelha do começo ao fim, sem ir se afastando. A 20 quadros o
clarão treme (é o quadro), mas o tique não escorrega. Diga "preso" ou
"escorregou por volta de X s".

## Ao terminar

- Marque a H01 como **feito** no [quadro](README.md), com o commit e o gasto
  real.
- Commit sugerido (sem trailer):
  `feat: o relógio de áudio — o Ritmo segue a placa de som e dá a batida`
