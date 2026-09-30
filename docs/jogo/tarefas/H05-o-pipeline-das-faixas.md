# H05 — O pipeline das faixas

**Sprint:** H · **Tamanho:** M · **Estimativa:** US$ 2,5 · **Depende de:** F00, H01

## Por quê

As 45 faixas, as das telas e os jingles precisam entrar com nome, no lugar
certo, com mapa de batidas conferido e sem pesar o repositório mais do que o
necessário. Decisão do André (30/09): **as músicas ficam todas dentro do
git**, em `godot/assets/ost/`. O jogo procura cada faixa ali; sem a faixa,
toca a trilha sintetizada de hoje, e nada quebra.

## Ler antes

- [As 45 faixas](../04-ritmo-e-audio.md#as-45-faixas) e [as telas e os jingles](../04-ritmo-e-audio.md#as-telas-e-os-jingles)
- [Os arquivos no repositório](../04-ritmo-e-audio.md#os-arquivos-no-repositório)
- [O LEIA-ME da trilha](../../../godot/assets/ost/LEIA-ME.md) (o nome de cada arquivo e a regra do commit)
- [A arquitetura: o relógio de áudio](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03)

## O estado de hoje

- `godot/scripts/musica.gd` (depois da H01): `FAIXAS` por sala
  (`musica.gd:11-24`), a trilha sintetizada pelo módulo (`_stream(id)`,
  `musica.gd:43-61`, devolve `AudioStreamWAV`), `tocar(id)` com fade,
  `tocar_do_zero(slot)`, `mapa(slot)` (o andamento de verdade da síntese),
  `laco_s(tocador)` (só WAV) e `_id_da_faixa(slot)` (o `MUS_Sxx_Jyy` vira a
  sintetizada da seção).
- **A decisão (30/09, do André): a trilha no git**, em `godot/assets/ost/`.
  O 04 já diz isso ("As 45 faixas" e "Os arquivos no repositório"). Nada de
  Git LFS, nada de pacote de música no release: a versão anterior desta
  ficha (`scripts/musica.sh`, `scripts/musica.versao`, o download do
  release, o sha256, o `gh release`, a pasta `godot/assets/musica/`) caiu
  inteira. O Git LFS fica só como saída futura, se o repositório pesar
  demais, sem mudar a pasta (o 04).
- **A pasta já existe** (sem nenhuma faixa):

  ```
  godot/assets/ost/
    LEIA-ME.md          os nomes, o formato (OGG Vorbis 48 kHz estéreo) e a regra do commit
    S01/ … S09/         MUS_Sxx_Jyy.ogg + MUS_Sxx_Jyy.batidas.json (S01 tem J01..J05, S02 tem J06..J10, …)
    telas/              MUS_TELA_TITULO, _CONSTRUCAO, _SALAO, _PODIO, _CREDITOS e MUS_RELAMPAGO (.ogg + .batidas.json)
    jingles/            JIN_APITO, _VITORIA, _COOP_VITORIA, _DERROTA, _EMPATE, _RECORDE, _ENTRADA, _VIRADA (.ogg, sem mapa)
  ```

  Cada pasta tem um `.gitkeep`. O `.gitattributes` da raiz marca `*.ogg`,
  `*.wav`, `*.png`, `*.glb` e `*.ttf` como `binary` (sem conversão de fim de
  linha e sem diff de texto). Os dois já estão no git (commit `178446b`).
- A nuvem não tem `ffmpeg`, `ffprobe`, `oggenc`, `sox` nem `numpy`
  (medido), e o Godot não codifica Vorbis (só lê). **A sessão não consegue
  fazer um OGG de verdade**: a prova com faixa é do André. Os dois scripts
  desta ficha usam só a biblioteca padrão do Python; o do mapa chama o
  `ffmpeg` só para ler OGG (na máquina do André).
- `godot/project.godot` não fixa a taxa de mistura: o Godot mistura a
  44 100 Hz (medido: `AudioServer.get_mix_rate()` = 44100), e tudo do jogo é
  48 kHz (o 04: "uma taxa só em todo o projeto").
- `godot/export_presets.cfg`: `export_filter="all_resources"` (`:16` e
  `:47`) leva os OGG importados sozinhos; `include_filter=""` (`:17` e `:48`)
  **não** leva um `.json` (que não é recurso importado).
- `godot/scripts/main.gd:214`: `Musica.tocar(sala_id if qual == "sala" else "salao")`
  — o título e o lobby tocam a faixa do salão. O pódio pede `"podio"`
  (`main.gd:466`).
- `tests/prova_do_jogo.sh:51`: o `godot --import` antes da prova; é ele
  quem cria o `.ogg.import` de uma faixa nova.
- O `SPRINTS.md` já diz "tudo dentro do git, em `godot/assets/ost/`".
- A H06 (os jingles) já procura por `Musica.caminho(nome)` (desta ficha),
  isto é, em `res://assets/ost/jingles/`, que o `Musica.caminho("JIN_…")` desta ficha
  devolve. Esta ficha **não** mexe na H06 (ver "Ao terminar").
- **Provado nesta preparação (30/09):** o `mapa_de_batidas.py --prova`
  passa (quatro `ok`); o `conferir_ost.py --prova` passa (16 `ok`, com OGG
  de mentira: só os cabeçalhos) e o `conferir_ost.py` na pasta de hoje diz
  "0 faixas, a trilha confere". O código GDScript de "O alvo" foi provado
  antes, com a pasta antiga (`res://assets/musica`), numa cópia do projeto
  com a H01 a H04 (a prova do jogo verde); **a troca da pasta, o `tocar(id)`
  reescrito e o laço por tipo não rodaram** — quem prova é o passo 10.

## O alvo

(**Novo** no 13, na seção do relógio: `Musica.caminho(slot)` (minigame,
tela e jingle), `Musica.ler_mapa(texto)`, `Musica.mapa_gerado(slot)`,
`Musica.TELAS`, o laço por tipo, a regra "faixa gerada só toca com o mapa
conferido" e "a trilha mora em `godot/assets/ost/` e se confere com
`scripts/conferir_ost.py`".)

**O caminho de cada arquivo** — `godot/assets/ost/<pasta>/<arquivo>`:

| o quê | pasta | arquivos | mapa |
| --- | --- | --- | --- |
| as 45 faixas | `S01/` … `S09/` | `MUS_Sxx_Jyy.ogg` e `MUS_Sxx_Jyy.ogg.import` | `MUS_Sxx_Jyy.batidas.json` ao lado |
| as telas e o Relâmpago | `telas/` | `MUS_TELA_*.ogg`, `MUS_RELAMPAGO.ogg` e o `.ogg.import` de cada um | `.batidas.json` ao lado |
| os jingles | `jingles/` | `JIN_*.ogg` e o `.ogg.import` de cada um | nenhum (o jingle não tem batida a seguir) |

**O mapa de batidas** — `godot/assets/ost/S01/MUS_S01_J01.batidas.json`
(texto pequeno; as telas em `godot/assets/ost/telas/`):

```json
{
  "slot": "MUS_S01_J01",
  "bpm": 122.0,
  "primeiro_tempo_s": 0.372,
  "compassos": 64,
  "secoes": [{"nome": "introducao", "compasso": 0}, {"nome": "queda", "compasso": 16}],
  "conferido": false,
  "escorrega_ms": [0.0, 1.5, -2.0]
}
```

`conferido` só vira `true` pela mão do André, depois de ouvir. Faixa sem
mapa conferido não toca: o jogo avisa (`push_warning`) e toca a sintetizada.

**O laço, por tipo** (decidido no código, não no `.ogg.import`):

- **Tela e Relâmpago: voltam ao zero** (`loop = true`, `loop_offset = 0`).
  Ninguém sabe quanto tempo o lobby dura.
- **Minigame: não volta.** O minigame dura 90 s (o 03) e a faixa gerada tem
  a introdução e o fim dela; dar a volta num fim com fade soa como erro. O
  `conferir_ost.py` exige 120 s de faixa (os 90 s, a entrada e folga). Se
  mesmo assim a faixa acabar, o `Ritmo` segue pelo relógio do sistema (H01).
- **Jingle: nunca volta** (termina em parada seca — o 04). Quem toca é a H06.

O `.ogg.import` fica como o Godot o cria (`loop=false`): o `_ogg()` abaixo
põe o laço de cada tipo no recurso carregado, que é o mesmo para todo mundo
(o `load` guarda em cache). Um lugar só decide, e a prova confere.

**`godot/scripts/musica.gd`** — acrescente ao fim:

```gdscript
# ---------------------------------------------------------------- as faixas geradas (H05) --

const PASTA := "res://assets/ost"
## As telas e o Relâmpago (docs/jogo/04#as-telas-e-os-jingles): o id que o
## jogo pede à Musica -> o slot da faixa gerada.
const TELAS := {
	"titulo": "MUS_TELA_TITULO", "lobby": "MUS_TELA_CONSTRUCAO", "salao": "MUS_TELA_SALAO",
	"podio": "MUS_TELA_PODIO", "creditos": "MUS_TELA_CREDITOS", "relampago": "MUS_RELAMPAGO",
}

var _mapas := {}  ## slot -> o mapa conferido da faixa gerada ({} = não há)


## O caminho da faixa gerada de um slot, exista ou não:
## MUS_S01_J01 -> res://assets/ost/S01/MUS_S01_J01.ogg; JIN_* em jingles/;
## as telas e o Relâmpago em telas/.
static func caminho(slot: String) -> String:
	if slot.begins_with("MUS_S") and slot.length() >= 8:
		return "%s/%s/%s.ogg" % [PASTA, slot.substr(4, 3), slot]
	if slot.begins_with("JIN_"):
		return "%s/jingles/%s.ogg" % [PASTA, slot]
	return "%s/telas/%s.ogg" % [PASTA, slot]


## Um MUS_*.batidas.json já lido: {bpm, primeiro_tempo, compassos, secoes,
## conferido, sintetizada: false}; {} se o texto não é um mapa. Pura.
static func ler_mapa(texto: String) -> Dictionary:
	var leitor := JSON.new()
	if leitor.parse(texto) != OK or not leitor.data is Dictionary:
		return {}
	var d: Dictionary = leitor.data
	if float(d.get("bpm", 0.0)) <= 0.0 or not d.has("primeiro_tempo_s"):
		return {}
	return {"bpm": float(d.bpm), "primeiro_tempo": float(d.primeiro_tempo_s), "compassos": int(d.get("compassos", 0)),
		"secoes": d.get("secoes", []), "conferido": bool(d.get("conferido", false)), "sintetizada": false}


## O mapa da faixa gerada do slot, se ela existe e o mapa foi conferido à
## mão; {} se não (e aí toca a sintetizada).
func mapa_gerado(slot: String) -> Dictionary:
	if _mapas.has(slot):
		return _mapas[slot]
	var m := {}
	var ogg := caminho(slot)
	if slot.begins_with("MUS_") and ResourceLoader.exists(ogg):
		var json := ogg.get_basename() + ".batidas.json"
		if not FileAccess.file_exists(json):
			push_warning("%s: a faixa existe e o mapa de batidas não; toca a sintetizada" % slot)
		else:
			m = ler_mapa(FileAccess.get_file_as_string(json))
			if m.is_empty() or not bool(m.conferido):
				push_warning("%s: o mapa de batidas não foi conferido; toca a sintetizada" % slot)
				m = {}
	_mapas[slot] = m
	return m


## A faixa gerada, com o laço do tipo dela: a tela (e o Relâmpago) volta ao
## zero (o Ritmo conta as voltas a partir do 0); a de minigame não volta.
func _ogg(slot: String) -> AudioStreamOggVorbis:
	var s: AudioStreamOggVorbis = load(caminho(slot))
	s.loop = not slot.begins_with("MUS_S")
	s.loop_offset = 0.0
	return s
```

e ligue nas funções da H01 (as mudanças, uma por uma):

```gdscript
## em mapa(slot), a primeira coisa:
	var gerado := mapa_gerado(slot)
	if not gerado.is_empty():
		return gerado

## em tocar_do_zero(slot), no lugar do `var s: AudioStreamWAV = ...`:
	var s: AudioStream = null
	if not mapa_gerado(slot).is_empty():
		s = _ogg(slot)
	elif id != "":
		s = _stream(id)

## em laco_s(tocador), antes do teste do WAV:
	if tocador != null and tocador.stream is AudioStreamOggVorbis:
		var o := tocador.stream as AudioStreamOggVorbis
		return o.get_length() if o.loop else 0.0
```

E o `tocar(id)` inteiro fica assim. A tela sem faixa própria (o título, o
lobby, os créditos, o Relâmpago — que não têm sintetizada) e o id
desconhecido tocam **a faixa do salão**: a gerada, quando existe, senão a
sintetizada. O `atual` passa a ser o slot quando a faixa é gerada, para
duas telas com faixas diferentes trocarem e duas telas que caem no salão
não reiniciarem:

```gdscript
## Toca a faixa do lugar (o id da sala, a tela, ou "salao"); o mesmo não reinicia.
func tocar(id: String) -> void:
	var slot: String = TELAS.get(id, "")
	if (slot == "" or mapa_gerado(slot).is_empty()) and not FAIXAS.has(id):
		id = "salao"
		slot = TELAS.salao
	var gerada := slot != "" and not mapa_gerado(slot).is_empty()
	var chave := slot if gerada else id
	if chave == atual:
		return
	atual = chave
	var velho := _tocadores[_ativo]
	_ativo = 1 - _ativo
	var novo := _tocadores[_ativo]
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(velho, "volume_db", -80.0, FADE_S)
	var s: AudioStream = _ogg(slot) if gerada else _stream(id)
	if s == null:
		return
	novo.stream = s
	novo.volume_db = -40.0
	novo.play()
	_tw.tween_property(novo, "volume_db", VOLUME_DB, FADE_S)
```

**`scripts/mapa_de_batidas.py`** (novo) — o arquivo inteiro, provado nesta
preparação com a sua própria prova (`--prova`: cliques a 122, 160 e 90 bpm
com o primeiro tempo em lugares diferentes, e uma faixa que escorrega). Sem
`--saida`, ele escreve o `.batidas.json` ao lado da faixa, na pasta da
`ost/` onde ela está:

```python
#!/usr/bin/env python3
"""O rascunho do mapa de batidas de uma faixa (docs/jogo/04-ritmo-e-audio.md#as-45-faixas).

O BPM vem da tabela das 45 faixas (a faixa foi pedida nele); o script acha
onde cai o primeiro tempo, confere se o andamento escorrega ao longo da
faixa e escreve o MUS_*.batidas.json com "conferido": false. Quem confere,
com o ouvido, é o André.

Só a biblioteca padrão do Python. WAV (16 bits) se lê direto; OGG passa pelo
ffmpeg (a máquina do André tem; a sessão da nuvem não).

  python3 scripts/mapa_de_batidas.py FAIXA.ogg --bpm 122 [--slot MUS_S01_J01] [--saida X.batidas.json]
  python3 scripts/mapa_de_batidas.py --prova     (a prova sem arquivo: cliques sintetizados)
"""
import argparse
import array
import json
import math
import os
import subprocess
import sys
import wave

TAXA = 48000
PASSO_S = 0.005  # o envelope: um valor a cada 5 ms
JANELA_S = 30.0  # o andamento se confere em janelas de 30 s
COMECO_S = 8.0  # o primeiro tempo se acha nos primeiros 8 s
ESCORREGA_MS = 10.0  # mais que isto numa janela: a faixa escorrega, e o André decide


def ler_wav(caminho):
    with wave.open(caminho, "rb") as w:
        if w.getsampwidth() != 2:
            raise SystemExit("WAV de 16 bits, por favor")
        canais, taxa, n = w.getnchannels(), w.getframerate(), w.getnframes()
        dados = array.array("h", w.readframes(n))
    if sys.byteorder == "big":
        dados.byteswap()
    mono = [sum(dados[i:i + canais]) / (32768.0 * canais) for i in range(0, len(dados), canais)]
    return mono, taxa


def ler_com_ffmpeg(caminho):
    try:
        saida = subprocess.run(["ffmpeg", "-v", "error", "-i", caminho, "-ac", "1", "-ar", str(TAXA),
                                "-f", "s16le", "-"], check=True, capture_output=True).stdout
    except FileNotFoundError:
        raise SystemExit("sem ffmpeg: instale (sudo apt install ffmpeg) ou passe um WAV")
    dados = array.array("h", saida)
    if sys.byteorder == "big":
        dados.byteswap()
    return [v / 32768.0 for v in dados], TAXA


def envelope(amostras, taxa):
    """O fluxo de energia a cada PASSO_S: quanto a energia subiu (os ataques)."""
    bloco = max(1, int(taxa * PASSO_S))
    energia = []
    for i in range(0, len(amostras) - bloco, bloco):
        s = 0.0
        for v in amostras[i:i + bloco]:
            s += v * v
        energia.append(math.sqrt(s / bloco))
    return [max(0.0, energia[k] - energia[k - 1]) if k else 0.0 for k in range(len(energia))]


def melhor_fase(env, periodo_s, ini_s=0.0, fim_s=None):
    """A fase (s, de 0 ao período) em que a grade de batidas soma mais ataque."""
    n = len(env)
    ini = int(ini_s / PASSO_S)
    fim = n if fim_s is None else min(n, int(fim_s / PASSO_S))
    melhor, fase_melhor = -1.0, 0.0
    passos = int(periodo_s / PASSO_S)
    for p in range(passos):
        fase = p * PASSO_S
        s, t = 0.0, fase
        while t < ini * PASSO_S:
            t += periodo_s
        while True:
            k = int(round(t / PASSO_S))
            if k >= fim:
                break
            s += env[k]
            t += periodo_s
        if s > melhor:
            melhor, fase_melhor = s, fase
    return fase_melhor


def mapear(amostras, taxa, bpm):
    env = envelope(amostras, taxa)
    periodo = 60.0 / bpm
    duracao = len(env) * PASSO_S
    # a fase da grade no começo (se o andamento escorrega, a da faixa inteira
    # mentiria sobre o começo)
    fase = melhor_fase(env, periodo, 0.0, COMECO_S)
    # o primeiro tempo é a primeira batida da grade com som de verdade (±20 ms)
    limiar = max(env) * 0.2 if env else 0.0
    primeiro = fase
    while primeiro < min(duracao, COMECO_S):
        k = int(round(primeiro / PASSO_S))
        vizinhos = env[max(0, k - 4):k + 5]
        if vizinhos and max(vizinhos) >= limiar:
            # o ataque de verdade, perto da grade
            primeiro = (max(0, k - 4) + vizinhos.index(max(vizinhos))) * PASSO_S
            break
        primeiro += periodo
    if primeiro >= min(duracao, COMECO_S):
        primeiro = fase
    # o andamento escorrega? a fase de cada janela de 30 s contra a do começo
    escorregas = []
    t = 0.0
    while t + JANELA_S <= duracao:
        f = melhor_fase(env, periodo, t, t + JANELA_S)
        d = (f - fase + periodo / 2) % periodo - periodo / 2
        escorregas.append(round(d * 1000.0, 1))
        t += JANELA_S
    compassos = int((duracao - primeiro) / (periodo * 4))
    return {"bpm": bpm, "primeiro_tempo_s": round(primeiro, 3), "compassos": compassos,
            "escorrega_ms": escorregas}


def escrever(slot, mapa, saida):
    dados = {"slot": slot, "bpm": mapa["bpm"], "primeiro_tempo_s": mapa["primeiro_tempo_s"],
             "compassos": mapa["compassos"], "secoes": [{"nome": "introducao", "compasso": 0}],
             "conferido": False, "escorrega_ms": mapa["escorrega_ms"]}
    with open(saida, "w", encoding="utf-8") as f:
        json.dump(dados, f, ensure_ascii=False, indent=2)
        f.write("\n")


def cliques(bpm, primeiro_s, segundos, taxa=TAXA):
    """Uma faixa de mentira: um clique curto em cada tempo, com silêncio antes."""
    a = [0.0] * int(segundos * taxa)
    t = primeiro_s
    while t < segundos:
        i = int(t * taxa)
        for k in range(int(0.01 * taxa)):
            if i + k < len(a):
                a[i + k] = math.sin(2 * math.pi * 1000 * k / taxa) * math.exp(-k / (0.002 * taxa))
        t += 60.0 / bpm
    return a


def prova():
    falhas = 0
    for bpm, primeiro in [(122.0, 0.37), (160.0, 1.2), (90.0, 0.05)]:
        m = mapear(cliques(bpm, primeiro, 65.0), TAXA, bpm)
        ok = abs(m["primeiro_tempo_s"] - primeiro) <= 0.01 and all(abs(e) <= ESCORREGA_MS for e in m["escorrega_ms"])
        print(("ok   " if ok else "FAIL ") + "%.0f bpm, primeiro tempo em %.2f s: achou %.3f s, escorrega %s" % (
            bpm, primeiro, m["primeiro_tempo_s"], m["escorrega_ms"]))
        falhas += 0 if ok else 1
    # a faixa que escorrega: tocada a 122,3 e pedida a 122 (uns 150 ms por minuto)
    m = mapear(cliques(122.3, 0.37, 125.0), TAXA, 122.0)
    ok = abs(m["primeiro_tempo_s"] - 0.37) <= 0.01 and max(abs(e) for e in m["escorrega_ms"]) > ESCORREGA_MS
    print(("ok   " if ok else "FAIL ") + "a faixa que escorrega é apontada: primeiro tempo %.3f s, escorrega %s" % (
        m["primeiro_tempo_s"], m["escorrega_ms"]))
    return falhas + (0 if ok else 1)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("faixa", nargs="?")
    ap.add_argument("--bpm", type=float)
    ap.add_argument("--slot")
    ap.add_argument("--saida")
    ap.add_argument("--prova", action="store_true")
    a = ap.parse_args()
    if a.prova:
        sys.exit(1 if prova() else 0)
    if not a.faixa or not a.bpm:
        ap.error("a faixa e o --bpm (da tabela de docs/jogo/04)")
    amostras, taxa = ler_wav(a.faixa) if a.faixa.lower().endswith(".wav") else ler_com_ffmpeg(a.faixa)
    mapa = mapear(amostras, taxa, a.bpm)
    slot = a.slot or os.path.splitext(os.path.basename(a.faixa))[0]
    saida = a.saida or os.path.splitext(a.faixa)[0] + ".batidas.json"
    escrever(slot, mapa, saida)
    print("%s: primeiro tempo em %.3f s, %d compassos, escorrega %s ms (confira com o ouvido)" % (
        saida, mapa["primeiro_tempo_s"], mapa["compassos"], mapa["escorrega_ms"]))
    if any(abs(e) > ESCORREGA_MS for e in mapa["escorrega_ms"]):
        print("ATENÇÃO: o andamento escorrega mais de %.0f ms numa janela; a faixa não entra assim" % ESCORREGA_MS)


if __name__ == "__main__":
    main()
```

**`scripts/conferir_ost.py`** (novo, executável) — o arquivo inteiro,
provado nesta preparação com a sua própria prova (`--prova`: numa pasta
temporária, OGG de mentira, só com a página do cabeçalho e a página final;
três arquivos certos, entre eles a tela curta e o jingle sem mapa, que
valem; doze errados; e a pasta sem nenhuma faixa):

```python
#!/usr/bin/env python3
"""A conferência da trilha (godot/assets/ost/, docs/jogo/04-ritmo-e-audio.md#os-arquivos-no-repositório).

Lista o que não confere: faixa sem mapa, mapa sem faixa, mapa não conferido,
nome fora do padrão ou fora da pasta, arquivo que não é OGG Vorbis (MP3 com
nome de OGG, Opus, WAV), taxa diferente de 48 kHz, faixa que não é estéreo,
faixa de minigame curta demais e faixa sem o .ogg.import ao lado. Só a
biblioteca padrão do Python: a taxa, os canais e a duração saem dos
cabeçalhos do OGG (a primeira e a última página), sem decodificar nada.

  python3 scripts/conferir_ost.py              confere godot/assets/ost/ (sai 1 se algo não confere)
  python3 scripts/conferir_ost.py --pasta X    confere outra pasta com a mesma forma
  python3 scripts/conferir_ost.py --prova      a prova sem faixa: OGG de mentira numa pasta temporária
"""
import argparse
import json
import os
import re
import struct
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OST = os.path.join(RAIZ, "godot", "assets", "ost")
TAXA = 48000
MINIMO_MINIGAME_S = 120.0  # 90 s de minigame, a entrada e folga: a faixa de minigame não volta ao zero
SECOES = ["S%02d" % s for s in range(1, 10)]
TELAS = {"MUS_TELA_TITULO", "MUS_TELA_CONSTRUCAO", "MUS_TELA_SALAO", "MUS_TELA_PODIO",
         "MUS_TELA_CREDITOS", "MUS_RELAMPAGO"}
JINGLES = {"JIN_APITO", "JIN_VITORIA", "JIN_COOP_VITORIA", "JIN_DERROTA", "JIN_EMPATE",
           "JIN_RECORDE", "JIN_ENTRADA", "JIN_VIRADA"}
SOLTOS = {".gitkeep", "LEIA-ME.md"}
NOME_MINIGAME = re.compile(r"^MUS_S(\d\d)_J(\d\d)$")


def nome_certo(pasta, slot):
    """O slot cabe na pasta? S01 tem J01..J05, S02 tem J06..J10, e assim por diante."""
    if pasta in SECOES:
        m = NOME_MINIGAME.match(slot)
        if not m:
            return False
        s, j = int(m.group(1)), int(m.group(2))
        return 1 <= j <= 45 and "S%02d" % s == pasta and (j - 1) // 5 + 1 == s
    if pasta == "telas":
        return slot in TELAS
    if pasta == "jingles":
        return slot in JINGLES
    return False


def ler_ogg(caminho):
    """(taxa, canais, segundos) de um OGG Vorbis, ou o motivo de não ser um."""
    with open(caminho, "rb") as f:
        cabeca = f.read(4096)
        f.seek(0, os.SEEK_END)
        tamanho = f.tell()
        f.seek(max(0, tamanho - 65536))
        cauda = f.read()
    if cabeca[:3] == b"ID3" or (len(cabeca) > 1 and cabeca[0] == 0xFF and cabeca[1] & 0xE0 == 0xE0):
        return "é MP3 com nome de OGG (MP3 é proibido: o silêncio do começo quebra o laço)"
    if cabeca[:4] == b"RIFF":
        return "é WAV com nome de OGG"
    if cabeca[:4] != b"OggS" or len(cabeca) < 28:
        return "não é OGG"
    corpo = cabeca[27 + cabeca[26]:]
    if corpo[:8] == b"OpusHead":
        return "é Opus, não Vorbis (o Godot toca OGG Vorbis)"
    if corpo[:7] != b"\x01vorbis" or len(corpo) < 16:
        return "é OGG, mas não Vorbis"
    canais = corpo[11]
    taxa = struct.unpack("<I", corpo[12:16])[0]
    ultima = cauda.rfind(b"OggS")
    if ultima < 0 or ultima + 14 > len(cauda) or taxa == 0:
        return "OGG sem a página final (cortado?)"
    amostras = struct.unpack("<q", cauda[ultima + 6:ultima + 14])[0]
    return taxa, canais, max(0, amostras) / float(taxa)


def ler_mapa(caminho, slot):
    """O motivo de o mapa não valer, ou None se vale e foi conferido."""
    try:
        with open(caminho, encoding="utf-8") as f:
            d = json.load(f)
    except (OSError, ValueError):
        return "o mapa não é JSON"
    if not isinstance(d, dict):
        return "o mapa não é um objeto JSON"
    if d.get("slot") != slot:
        return "o mapa diz slot %r, e o arquivo é %s" % (d.get("slot"), slot)
    if not isinstance(d.get("bpm"), (int, float)) or d["bpm"] <= 0:
        return "o mapa não tem bpm"
    if not isinstance(d.get("primeiro_tempo_s"), (int, float)):
        return "o mapa não tem primeiro_tempo_s"
    if d.get("conferido") is not True:
        return "o mapa não foi conferido de ouvido (a faixa não toca: o jogo toca a sintetizada)"
    return None


def conferir(pasta):
    """[(arquivo relativo à pasta, o que não confere)] e o resumo {faixas, bytes}."""
    problemas, faixas, total = [], [], 0
    for nome in sorted(os.listdir(pasta)):
        if nome in SOLTOS:
            continue
        if nome not in SECOES + ["telas", "jingles"] or not os.path.isdir(os.path.join(pasta, nome)):
            problemas.append((nome, "fora do lugar: a trilha só tem S01..S09, telas/ e jingles/"))
            continue
        dentro = sorted(os.listdir(os.path.join(pasta, nome)))
        for arq in dentro:
            rel = "%s/%s" % (nome, arq)
            cam = os.path.join(pasta, nome, arq)
            if arq in SOLTOS:
                continue
            if arq.endswith(".ogg.import"):
                if arq[:-len(".import")] not in dentro:
                    problemas.append((rel, "import sem faixa (sobra de uma faixa que saiu)"))
                continue
            if arq.endswith(".batidas.json"):
                slot = arq[:-len(".batidas.json")]
                if nome == "jingles":
                    problemas.append((rel, "jingle não tem mapa de batidas"))
                elif slot + ".ogg" not in dentro:
                    problemas.append((rel, "mapa sem faixa"))
                continue
            base, ext = os.path.splitext(arq)
            if ext.lower() == ".mp3":
                problemas.append((rel, "MP3 é proibido: converta para OGG Vorbis 48 kHz estéreo"))
                continue
            if ext.lower() in (".wav", ".flac", ".opus", ".m4a", ".aac"):
                problemas.append((rel, "não é OGG: converta para OGG Vorbis 48 kHz estéreo"))
                continue
            if ext != ".ogg":
                problemas.append((rel, "arquivo que não é da trilha"))
                continue
            if not nome_certo(nome, base):
                problemas.append((rel, "nome fora do padrão ou fora da pasta (o LEIA-ME da ost diz o nome de cada arquivo)"))
            total += os.path.getsize(cam)
            info = ler_ogg(cam)
            if isinstance(info, str):
                problemas.append((rel, info))
                continue
            taxa, canais, segundos = info
            faixas.append((rel, taxa, canais, segundos))
            if taxa != TAXA:
                problemas.append((rel, "taxa de %d Hz: tudo do jogo é 48000 Hz" % taxa))
            if canais != 2:
                problemas.append((rel, "%d canal(is): a trilha é estéreo" % canais))
            if nome in SECOES and segundos < MINIMO_MINIGAME_S:
                problemas.append((rel, "%.1f s: a faixa de minigame não volta ao zero e precisa de %.0f s" % (
                    segundos, MINIMO_MINIGAME_S)))
            if arq + ".import" not in dentro:
                problemas.append((rel, "sem o .ogg.import ao lado: rode o Godot com --import e commite os dois juntos"))
            if nome != "jingles":
                mapa = base + ".batidas.json"
                if mapa not in dentro:
                    problemas.append((rel, "sem mapa de batidas (scripts/mapa_de_batidas.py)"))
                else:
                    motivo = ler_mapa(os.path.join(pasta, nome, mapa), base)
                    if motivo:
                        problemas.append(("%s/%s" % (nome, mapa), motivo))
    return problemas, faixas, total


def relatar(pasta):
    problemas, faixas, total = conferir(pasta)
    for rel, taxa, canais, segundos in faixas:
        print("     %s: %d Hz, %d canais, %.1f s" % (rel, taxa, canais, segundos))
    for rel, motivo in problemas:
        print("NÃO  %s: %s" % (rel, motivo))
    print("==> %d faixas, %.1f MB; %s" % (len(faixas), total / 1e6,
          "a trilha confere" if not problemas else "%d coisas não conferem" % len(problemas)))
    return 1 if problemas else 0


# ------------------------------------------------------------------ a prova --

def ogg_falso(taxa, canais, segundos, cabeca=b"\x01vorbis"):
    """Um OGG de mentira: a página do cabeçalho e a página final (o granule)."""
    def pagina(tipo, granule, corpo):
        return (b"OggS" + bytes([0, tipo]) + struct.pack("<qIII", granule, 1, 0, 0)
                + bytes([1, len(corpo)]) + corpo)
    ident = cabeca + struct.pack("<IBIiiiBB", 0, canais, taxa, 0, 128000, 0, 0xB8, 1)
    return pagina(2, 0, ident) + pagina(4, int(segundos * taxa), b"\x00" * 16)


def prova():
    mapa_ok = {"bpm": 122.0, "primeiro_tempo_s": 0.372, "compassos": 64, "secoes": [], "conferido": True}
    arquivos = {
        "S01/MUS_S01_J01.ogg": ogg_falso(48000, 2, 150.0),          # a faixa certa
        "S01/MUS_S01_J01.ogg.import": b"[remap]\n",
        "S01/MUS_S01_J01.batidas.json": dict(mapa_ok, slot="MUS_S01_J01"),
        "S01/MUS_S01_J02.ogg": ogg_falso(48000, 2, 150.0),          # sem mapa
        "S01/MUS_S01_J02.ogg.import": b"",
        "S01/MUS_S01_J03.ogg": ogg_falso(48000, 2, 150.0),          # mapa não conferido
        "S01/MUS_S01_J03.ogg.import": b"",
        "S01/MUS_S01_J03.batidas.json": dict(mapa_ok, slot="MUS_S01_J03", conferido=False),
        "S01/MUS_S02_J07.ogg": ogg_falso(48000, 2, 150.0),          # na pasta errada
        "S02/MUS_S02_J06.batidas.json": dict(mapa_ok, slot="MUS_S02_J06"),  # mapa sem faixa
        "S03/MUS_S03_J11.ogg": b"ID3\x04" + b"\x00" * 64,           # MP3 com nome de OGG
        "S04/MUS_S04_J16.mp3": b"ID3\x04",                          # MP3
        "S05/MUS_S05_J21.ogg": ogg_falso(48000, 2, 60.0),           # curta
        "S05/MUS_S05_J21.ogg.import": b"",
        "S05/MUS_S05_J21.batidas.json": dict(mapa_ok, slot="MUS_S05_J21"),
        "S06/MUS_S06_J26.ogg": ogg_falso(48000, 2, 150.0),          # sem .import
        "S06/MUS_S06_J26.batidas.json": dict(mapa_ok, slot="MUS_S06_J26"),
        "S07/MUS_S07_J31.ogg": ogg_falso(48000, 2, 150.0, b"OpusHead"),  # Opus
        "telas/MUS_TELA_SALAO.ogg": ogg_falso(44100, 2, 90.0),      # 44,1 kHz
        "telas/MUS_TELA_SALAO.ogg.import": b"",
        "telas/MUS_TELA_SALAO.batidas.json": dict(mapa_ok, slot="MUS_TELA_SALAO"),
        "telas/MUS_TELA_PODIO.ogg": ogg_falso(48000, 1, 90.0),      # mono
        "telas/MUS_TELA_PODIO.ogg.import": b"",
        "telas/MUS_TELA_PODIO.batidas.json": dict(mapa_ok, slot="MUS_TELA_PODIO"),
        "telas/MUS_TELA_TITULO.ogg": ogg_falso(48000, 2, 30.0),     # tela curta: vale (volta ao zero)
        "telas/MUS_TELA_TITULO.ogg.import": b"",
        "telas/MUS_TELA_TITULO.batidas.json": dict(mapa_ok, slot="MUS_TELA_TITULO"),
        "jingles/JIN_APITO.ogg": ogg_falso(48000, 2, 1.0),          # jingle certo, sem mapa
        "jingles/JIN_APITO.ogg.import": b"",
        "jingles/JIN_FESTA.ogg": ogg_falso(48000, 2, 3.0),          # jingle que não existe
        "jingles/JIN_FESTA.ogg.import": b"",
    }
    esperado = {
        ("S01/MUS_S01_J02.ogg", "sem mapa"),
        ("S01/MUS_S01_J03.batidas.json", "não foi conferido"),
        ("S01/MUS_S02_J07.ogg", "fora do padrão"),
        ("S01/MUS_S02_J07.ogg", "sem o .ogg.import"),
        ("S01/MUS_S02_J07.ogg", "sem mapa"),
        ("S02/MUS_S02_J06.batidas.json", "mapa sem faixa"),
        ("S03/MUS_S03_J11.ogg", "é MP3"),
        ("S04/MUS_S04_J16.mp3", "MP3 é proibido"),
        ("S05/MUS_S05_J21.ogg", "60.0 s"),
        ("S06/MUS_S06_J26.ogg", "sem o .ogg.import"),
        ("S07/MUS_S07_J31.ogg", "Opus"),
        ("telas/MUS_TELA_SALAO.ogg", "44100 Hz"),
        ("telas/MUS_TELA_PODIO.ogg", "1 canal"),
        ("jingles/JIN_FESTA.ogg", "fora do padrão"),
    }
    falhas = 0
    with tempfile.TemporaryDirectory() as tmp:
        for rel, conteudo in arquivos.items():
            cam = os.path.join(tmp, rel)
            os.makedirs(os.path.dirname(cam), exist_ok=True)
            with open(cam, "wb") as f:
                f.write(json.dumps(conteudo).encode() if isinstance(conteudo, dict) else conteudo)
        problemas, faixas, _ = conferir(tmp)
        for rel, trecho in sorted(esperado):
            ok = any(r == rel and trecho in m for r, m in problemas)
            print(("ok   " if ok else "FAIL ") + "%s: %s" % (rel, trecho))
            falhas += 0 if ok else 1
        sobra = [(r, m) for r, m in problemas if not any(r == e and t in m for e, t in esperado)]
        for r, m in sobra:
            print("FAIL apontou o que não devia: %s: %s" % (r, m))
        certa = [f for f in faixas if f[0] == "S01/MUS_S01_J01.ogg"]
        ok = certa == [("S01/MUS_S01_J01.ogg", 48000, 2, 150.0)]
        print(("ok   " if ok else "FAIL ") + "a faixa certa se lê: %s" % certa)
        falhas += len(sobra) + (0 if ok else 1)
        vazia = os.path.join(tmp, "vazia")
        for p in SECOES + ["telas", "jingles"]:
            os.makedirs(os.path.join(vazia, p))
            open(os.path.join(vazia, p, ".gitkeep"), "w").close()
        ok = conferir(vazia) == ([], [], 0)
        print(("ok   " if ok else "FAIL ") + "a pasta sem nenhuma faixa confere")
        falhas += 0 if ok else 1
    return falhas


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--pasta", default=OST)
    ap.add_argument("--prova", action="store_true")
    a = ap.parse_args()
    if a.prova:
        sys.exit(1 if prova() else 0)
    if not os.path.isdir(a.pasta):
        sys.exit("não achei a pasta %s" % a.pasta)
    sys.exit(relatar(a.pasta))


if __name__ == "__main__":
    main()
```

A taxa, os canais e a duração **saem dos cabeçalhos**, sem biblioteca: a
primeira página do OGG traz o cabeçalho de identificação do Vorbis
(`\x01vorbis`, os canais no byte 11 e a taxa nos bytes 12 a 15, inteiro de
32 bits little-endian), e a última página traz a posição da última amostra
(o *granule*, 64 bits, no byte 6 da página); a duração é uma dividida pela
outra. O script não decodifica: um OGG quebrado no meio passa por ele e
falha no `--import` do Godot (o `import.log` da prova). A primeira faixa de
verdade se confere também com o `ffprobe` do André (ver "Para o André"):
se os dois discordarem, vale o `ffprobe`, e o script está errado.

## Passos

1. **Prova verde antes** (`bash tests/prova_do_jogo.sh`).
2. **`scripts/mapa_de_batidas.py`**: crie e rode
   `python3 scripts/mapa_de_batidas.py --prova` (quatro `ok`).
3. **`scripts/conferir_ost.py`**: crie (`chmod +x`) e rode
   `python3 scripts/conferir_ost.py --prova` (16 `ok`) e
   `python3 scripts/conferir_ost.py` (sem faixa: "0 faixas, 0.0 MB; a
   trilha confere").
4. **`tests/prova_do_jogo.sh`**: a trilha se confere em toda prova, **antes**
   do `--import` da linha 51 (depois dele, o Godot já teria criado o
   `.ogg.import` que faltou no commit, e a falta passaria):

   ```bash
   # a trilha (H05): antes do --import, que criaria o .ogg.import que faltou no commit
   python3 "$RAIZ/scripts/conferir_ost.py" > "$TMP/ost.log" 2>&1
   OST=$?
   grep -E "^NÃO|^==>" "$TMP/ost.log"
   ```

   e, logo depois do `FALHAS=0`:

   ```bash
   [ "$OST" -eq 0 ] || { echo "FAIL a trilha não confere (python3 scripts/conferir_ost.py)"; FALHAS=$((FALHAS + 1)); }
   ```

5. **`godot/scripts/musica.gd`**: o bloco de "O alvo", as três ligações
   (`mapa`, `tocar_do_zero`, `laco_s`) e o `tocar(id)` novo. O `_stream()`
   continua devolvendo a sintetizada (`AudioStreamWAV`).
6. **`godot/scripts/main.gd:214`**: `Musica.tocar(sala_id if qual == "sala" else qual)`
   (o título, o lobby e o salão com a faixa de cada um; sem ela, a do
   salão, como hoje).
7. **`godot/project.godot`**: a seção nova

   ```
   [audio]

   driver/mix_rate=48000
   ```

   **(prova)** — a trilha sintetizada e os efeitos têm de soar igual; a
   prova do relógio (H01) tem de continuar verde.
8. **`godot/export_presets.cfg`**: nos dois presets (linhas 17 e 48),
   `include_filter="*.batidas.json"`. Os OGG não precisam de filtro (são
   recursos importados; o `all_resources` leva).
9. **Os LEIA-ME**: no `godot/assets/ost/LEIA-ME.md`, acrescente ao fim uma
   seção curta "Os comandos" (o `mapa_de_batidas.py`, o `--import` que cria
   o `.ogg.import` e o `conferir_ost.py`, como em "Para o André"), sem
   reescrever o resto — o texto é do André. Na tabela de
   `godot/assets/LEIA-ME.md`, a linha da pasta `ost/`: "a trilha: as 45
   faixas, as telas e os jingles, em OGG Vorbis 48 kHz estéreo, e os mapas
   de batidas". A origem já está decidida (30/09): o ACE-Step 1.5, na
   máquina do André, pelo gerador da [H09](H09-o-gerador-da-trilha.md);
   copie da seção "A origem e o uso" do LEIA-ME da trilha, sem inventar nada
   além.
10. **`godot/testes/prova_do_jogo.gd`**: `_prova_das_faixas()` (em
    "Provas"), chamada logo depois de `await _prova_do_relogio()`.
    **(prova)** E o metrônomo da H01 (`godot/testes/metronomo.gd`) passa a
    ler o slot do ambiente: `var slot := OS.get_environment("SLOT")`, com
    `"MUS_S01_J01"` quando vazio — é com ele que o André confere cada mapa.
11. **A documentação**: no 13, o que está marcado **novo**; em
    `docs/DESENVOLVER.md`, três linhas: onde a trilha mora, o
    `mapa_de_batidas.py` e o `conferir_ost.py` (que a prova do jogo também
    roda); no 04, em "Os arquivos no repositório", uma linha: "Quem confere
    a pasta é o `scripts/conferir_ost.py` (H05)"; no `SPRINTS.md:100`, troque
    "a decisão entre Git LFS e o pacote do release" por "a trilha no git, em
    `godot/assets/ost/` (H05)".

## Armadilhas

- **O git guarda tudo para sempre.** Cada versão de cada faixa fica no
  histórico, e todo clone completo leva todas. Trocar uma faixa de 5 MB três
  vezes custa 15 MB para sempre. A regra: **só entra faixa aprovada**,
  ouvida no jogo e com o mapa conferido; rascunho, geração descartada, o WAV
  de origem, os stems e o projeto da DAW **nunca** entram (ficam fora do
  repositório, não numa pasta ignorada dentro do `godot/`, onde o Godot
  importaria tudo). Antes do push, um erro se desfaz (`git reset` ou
  `git commit --amend`); depois do push, não se desfaz sem reescrever o
  histórico, e isso não se faz.
- **Nunca MP3**, nem convertido: o silêncio que o codificador de MP3 põe no
  começo quebra o laço e o tempo (o 04). Baixe a faixa do serviço em WAV e
  converta para OGG. Se o serviço só der MP3, o silêncio vira parte do OGG:
  o mapa mede o primeiro tempo no próprio OGG, então o tempo confere, mas o
  laço da tela ganha um respiro — prefira o WAV.
- **44,1 kHz é o normal dos serviços**, e o jogo é 48 kHz: a conversão é na
  máquina do André (`-ar 48000`), nunca em tempo de jogo. O
  `conferir_ost.py` recusa outra taxa.
- **O `.ogg.import` entra no commit junto com o `.ogg`.** O Godot o cria no
  primeiro `--import` (ou ao abrir o editor), com um `uid` próprio; faixa
  sem ele faz o próximo que rodar o jogo criar outro `uid`, e o diff de cada
  máquina briga. Não se escreve à mão. Não mude o laço no painel Importar do
  editor: não adianta (o `_ogg()` manda) e suja o diff. É algo como:

  ```
  [remap]

  importer="oggvorbisstr"
  type="AudioStreamOggVorbis"
  uid="uid://…"
  path="res://.godot/imported/MUS_S01_J01.ogg-….oggvorbisstr"

  [deps]

  source_file="res://assets/ost/S01/MUS_S01_J01.ogg"
  dest_files=["res://.godot/imported/MUS_S01_J01.ogg-….oggvorbisstr"]

  [params]

  loop=false
  loop_offset=0
  bpm=0
  beat_count=0
  bar_beats=4
  ```

  O `.godot/` (o recurso importado de verdade) continua fora do git.
- **O tamanho.** As 45 faixas a OGG Vorbis `-q:a 6` (uns 190 kbps; 3 a 4
  minutos cada, uns 4 a 6 MB) somam algo entre 150 e 250 MB; as telas e os
  jingles, mais uns 25 MB. Isso pesa três vezes: no clone (o de toda sessão
  da nuvem também, mesmo raso, porque o checkout traz as faixas de hoje), no
  `--import` da prova (a primeira vez numa pasta nova) e no jogo exportado
  (o `.pck` do Linux e o do Windows crescem o mesmo tanto). O GitHub avisa
  num arquivo de mais de 50 MB e recusa um de mais de 100 MB: uma faixa
  nunca chega perto; se chegar, está errada. Se um dia o repositório pesar
  demais, o caminho é o Git LFS sem mudar a pasta (o 04) — não é desta
  ficha.
- **O laço é por tipo, e a faixa de minigame não volta.** Se o
  `conferir_ost.py` recusar uma faixa curta, a resposta é outra geração,
  não ligar o laço. A tela volta ao zero (`loop_offset = 0`): o `Ritmo`
  conta as voltas supondo isso (`posicao_continua`, H01).
- **Mapa não conferido não toca**: é regra do 04 ("o mapa é conferido à mão
  antes de a faixa entrar no jogo"). Não ponha `"conferido": true` num mapa
  que ninguém ouviu. O `conferir_ost.py` recusa mapa não conferido, então a
  prova do jogo fica vermelha até ele ser ouvido: é de propósito (faixa com
  mapa por conferir não vai para o commit).
- **O `.json` na exportação**: sem o `include_filter`, o jogo exportado não
  acha o mapa e toca a sintetizada, calado (só o `push_warning`). A prova da
  exportação do André mostra.
- **A taxa de 48 kHz** muda a mistura do jogo inteiro: se alguma prova mudar
  de resultado no passo 7, pare e anote (não é para mudar nada).
- **O relógio sem faixa**: slot sem faixa gerada e sem sintetizada (A Voz, O
  Canto) continua pelo relógio do sistema (H01). Nenhum caminho de prova.
- **Os jingles**: esta ficha só dá o caminho (`caminho("JIN_APITO")`); quem
  os toca é a H06, pelo mesmo `Musica.caminho`.
- **`.uid`**: só GDScript novo tem `.uid`; esta ficha não cria `.gd` novo
  (só muda o `musica.gd`, o `main.gd` e o `prova_do_jogo.gd`).

## Não fazer

- Não gerar nem baixar faixa na sessão; não commitar faixa de teste,
  rascunho, WAV ou MP3 de origem, stem ou projeto de DAW.
- Não criar `scripts/musica.sh`, `scripts/musica.versao` nem
  `godot/assets/musica/`; não usar release, `gh release`, sha256 de pacote
  nem Git LFS para a música (a decisão de 30/09).
- Não usar MP3 (o 04). Não reamostrar nada em tempo de jogo: tudo a 48 kHz.
- Não reescrever o histórico do git para tirar uma faixa.
- Não mexer no `scripts/exportar.sh`, no `compilar.sh`, no SDL nem no
  godot-cpp; não mexer na H06.
- Não reescrever o `godot/assets/ost/LEIA-ME.md` nem o `.gitattributes`
  (são do André); só a seção nova do passo 9.

## Pronto quando

Sem nenhuma faixa em `godot/assets/ost/`, o jogo toca a trilha sintetizada
como hoje, o `conferir_ost.py` confere e a prova do jogo está verde; com
três faixas no lugar e o mapa de cada uma conferido (o André confere), cada
uma toca no seu minigame ou na sua tela, com o laço do tipo dela, o `Ritmo`
segue o mapa, a prova do jogo continua verde e a exportação leva as faixas
e os mapas.

## Provas

**Na sessão** (sem faixa: a nuvem não faz OGG):

```bash
python3 scripts/mapa_de_batidas.py --prova
python3 scripts/conferir_ost.py --prova && python3 scripts/conferir_ost.py
bash tests/prova_do_jogo.sh
```

A checagem nova em `godot/testes/prova_do_jogo.gd`. Vale com e sem faixa:
sem a faixa, exige a sintetizada; com ela na pasta, exige a gerada, com o
laço do tipo dela.

```gdscript
## As faixas (H05): o caminho de cada tipo, o mapa lido do JSON, e cada faixa
## de exemplo — sem ela, a trilha sintetizada; com ela e o mapa conferido, a
## gerada, com o laço do tipo dela. Pura (não toca nada).
func _prova_das_faixas() -> void:
	_esperar(Musica.caminho("MUS_S01_J01") == "res://assets/ost/S01/MUS_S01_J01.ogg", "faixas: o caminho de uma faixa de minigame")
	_esperar(Musica.caminho("MUS_TELA_SALAO") == "res://assets/ost/telas/MUS_TELA_SALAO.ogg", "faixas: o caminho de uma tela")
	_esperar(Musica.caminho("MUS_RELAMPAGO") == "res://assets/ost/telas/MUS_RELAMPAGO.ogg", "faixas: o caminho do Relâmpago")
	_esperar(Musica.caminho("JIN_APITO") == "res://assets/ost/jingles/JIN_APITO.ogg", "faixas: o caminho de um jingle")
	var m := Musica.ler_mapa('{"slot": "MUS_S01_J01", "bpm": 122.0, "primeiro_tempo_s": 0.372, "compassos": 64, "secoes": [], "conferido": true}')
	_esperar(is_equal_approx(float(m.get("bpm", 0.0)), 122.0) and is_equal_approx(float(m.get("primeiro_tempo", 0.0)), 0.372) and bool(m.get("conferido", false)),
		"faixas: o mapa se lê (%s)" % [m])
	_esperar(Musica.ler_mapa('{"bpm": 0}').is_empty() and Musica.ler_mapa("não é json").is_empty(), "faixas: mapa ruim não vale")
	_esperar(not bool(Musica.ler_mapa('{"bpm": 120.0, "primeiro_tempo_s": 0.0}').get("conferido", true)), "faixas: sem «conferido», não conferido")
	_esperar(AudioServer.get_mix_rate() == 48000.0, "faixas: a mistura a 48 kHz (%d)" % AudioServer.get_mix_rate())
	for slot in ["MUS_S01_J01", "MUS_S02_J06", "MUS_TELA_SALAO"]:
		if not ResourceLoader.exists(Musica.caminho(slot)):
			# sem a faixa na pasta (a nuvem nunca tem), a sintetizada da seção
			if slot.begins_with("MUS_S"):
				_esperar(Musica.mapa_gerado(slot).is_empty() and bool(Musica.mapa(slot).get("sintetizada", false)) == Forja.modulo,
					"faixas: sem a faixa %s, a trilha sintetizada" % slot)
			continue
		var g := Musica.mapa_gerado(slot)
		_esperar(not g.is_empty() and not bool(Musica.mapa(slot).get("sintetizada", true)),
			"faixas: %s, com o mapa conferido, no lugar da sintetizada (%s)" % [slot, g])
		var s := Musica._ogg(slot)
		var volta := not slot.begins_with("MUS_S")
		_esperar(s != null and s.loop == volta and is_zero_approx(s.loop_offset),
			"faixas: %s com o laço do tipo dela (volta: %s)" % [slot, volta])
```

**Com o André, local:** a mesma prova com as três faixas no lugar (abaixo).

## Para o André (local)

Com três faixas aprovadas — por exemplo `MUS_S01_J01` (122 bpm),
`MUS_S02_J06` (115 bpm) e `MUS_TELA_SALAO` (110 bpm) —, em WAV. Com a
[H09](H09-o-gerador-da-trilha.md) pronta, o `gerar_trilha.py escolher` já faz
os passos 1 e 2; sem ela, qualquer WAV de teste serve:

```bash
# 1. converter para OGG Vorbis 48 kHz estéreo, com o nome do slot, na pasta dele
ffmpeg -i <o WAV do serviço> -ar 48000 -ac 2 -c:a libvorbis -q:a 6 godot/assets/ost/S01/MUS_S01_J01.ogg
ffprobe -v error -show_entries stream=codec_name,sample_rate,channels:format=duration \
  -of default=nw=1 godot/assets/ost/S01/MUS_S01_J01.ogg      # vorbis, 48000, 2 e a duração
# 2. o rascunho do mapa (ao lado da faixa)
python3 scripts/mapa_de_batidas.py godot/assets/ost/S01/MUS_S01_J01.ogg --bpm 122
# 3. o .ogg.import, e o metrônomo na faixa (com "conferido": true provisório
#    no .json, só na sua máquina, para ela tocar); se o tique cai no tempo do
#    começo ao fim, o "conferido": true fica
tools/Godot_v4.4.1-stable_linux.x86_64 --headless --path godot --import --quit
SLOT=MUS_S01_J01 tools/Godot_v4.4.1-stable_linux.x86_64 --path godot res://testes/metronomo.tscn
# 4. o mesmo para MUS_S02_J06 (S02/, --bpm 115) e MUS_TELA_SALAO (telas/, --bpm 110); depois
python3 scripts/conferir_ost.py            # compare a taxa e a duração com o ffprobe
bash tests/prova_do_jogo.sh
./run-local.sh -- --sala=centelha          # e --sala=viga; o salão, entre uma e outra
scripts/exportar.sh linux && bash tests/prova_da_exportacao.sh
git status --short godot/assets/ost/       # de cada faixa: .ogg, .ogg.import e .batidas.json; nada mais
```

Diga: "as três tocam no lugar, no tempo, e o conferir concorda com o
ffprobe", ou o que escorregou (o `escorrega_ms` do mapa ajuda) ou
discordou. As três só vão para um commit seu (`feat: as três primeiras
faixas`) se foram aprovadas; se não, apague-as da pasta antes de qualquer
`git add`.

## Ao terminar

- Marque a H05 como **feito** no [quadro](README.md), com o commit e o gasto
  real.
- (A H06 já usa `Musica.caminho("JIN_…")`; nada a avisar.)
- Commit sugerido (sem trailer):
  `feat: o pipeline das faixas — a trilha em godot/assets/ost, o mapa de batidas e a faixa de cada tela`
