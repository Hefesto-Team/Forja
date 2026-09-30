# H05 — O pipeline das faixas

**Sprint:** H · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5 · **Depende de:** F00, H01

## Por quê

As 45 faixas (e as das telas) precisam entrar com nome, com mapa de batidas
conferido e sem pesar o repositório. Sem a faixa, o jogo toca a trilha
sintetizada de hoje, e nada quebra.

## Ler antes

- [As 45 faixas](../04-ritmo-e-audio.md#as-45-faixas) e [as telas e os jingles](../04-ritmo-e-audio.md#as-telas-e-os-jingles)
- [Os arquivos no repositório](../04-ritmo-e-audio.md#os-arquivos-no-repositório)
- [A arquitetura: o relógio de áudio](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03)

## O estado de hoje

- `godot/scripts/musica.gd` (depois da H01): `FAIXAS` por sala
  (`musica.gd:11-24`), a trilha sintetizada pelo módulo (`_stream(id)`,
  `musica.gd:43-61`, devolve `AudioStreamWAV`), `tocar(id)` com fade,
  `tocar_do_zero(slot)`, `mapa(slot)` (o andamento de verdade da síntese),
  `laco_s(tocador)` (só WAV) e `_id_da_faixa(slot)` (o `MUS_Sxx_Jyy` vira a
  sintetizada da seção).
- **Decisão desta ficha** (o 04 deixou para a Sprint H): **o pacote de
  música no release**, fixado por versão e sha256 como o SDL
  (`scripts/compilar.sh:21-50`), e não o Git LFS. O clone continua leve e a
  exportação reprodutível. Os mapas `*.batidas.json` (texto pequeno) entram
  no git; os OGG não.
- Não há nenhuma faixa gerada no repositório, e a nuvem não tem `ffmpeg`
  nem `numpy` (medido). O script do mapa usa só a biblioteca padrão do
  Python e chama o `ffmpeg` só para OGG (na máquina do André).
- `godot/project.godot` não fixa a taxa de mistura: o Godot mistura a
  44 100 Hz (medido: `AudioServer.get_mix_rate()` = 44100), e tudo do jogo é
  48 kHz (o 04: "uma taxa só em todo o projeto").
- `godot/export_presets.cfg:17` e `:48`: `include_filter=""` — um `.json`
  (que não é recurso importado) **não** entra no `.pck` sem filtro.
- `godot/scripts/main.gd:214`: `Musica.tocar(sala_id if qual == "sala" else "salao")`
  — o título e o lobby tocam a faixa do salão.
- `scripts/exportar.sh:256`: o `godot --import` antes de exportar.
- **Provado nesta preparação**, numa cópia do projeto com a H01 a H04: o
  código de "O alvo" (as funções novas, o `tocar(id)` inteiro e a mistura a
  48 kHz) deixa a prova do jogo verde; o `musica.sh` empacota, baixa do
  `.cache`, confere o sha256 e sai o mesmo pacote duas vezes (reproduzível);
  o `mapa_de_batidas.py --prova` passa.

## O alvo

(**Novo** no 13, na seção do relógio: `Musica.caminho(slot)`,
`Musica.ler_mapa(texto)`, `Musica.mapa_gerado(slot)`, `Musica.TELAS`, e a
regra "faixa gerada só toca com o mapa conferido".)

**O mapa de batidas** — `godot/assets/musica/Sxx/MUS_Sxx_Jyy.batidas.json`
(as telas em `godot/assets/musica/telas/`):

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

**`godot/scripts/musica.gd`** — acrescente ao fim:

```gdscript
# ---------------------------------------------------------------- as faixas geradas (H05) --

const PASTA := "res://assets/musica"
## As telas e o Relâmpago (docs/jogo/04#as-telas-e-os-jingles): o id que o
## jogo pede à Musica -> o slot da faixa gerada.
const TELAS := {
	"titulo": "MUS_TELA_TITULO", "lobby": "MUS_TELA_CONSTRUCAO", "salao": "MUS_TELA_SALAO",
	"podio": "MUS_TELA_PODIO", "creditos": "MUS_TELA_CREDITOS", "relampago": "MUS_RELAMPAGO",
}

var _mapas := {}  ## slot -> o mapa conferido da faixa gerada ({} = não há)


## O caminho da faixa gerada de um slot, exista ou não:
## MUS_S01_J01 -> res://assets/musica/S01/MUS_S01_J01.ogg; as telas em telas/.
static func caminho(slot: String) -> String:
	if slot.begins_with("MUS_S") and slot.length() >= 8:
		return "%s/%s/%s.ogg" % [PASTA, slot.substr(4, 3), slot]
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


## A faixa gerada, em laço desde o zero (o Ritmo conta as voltas a partir do 0).
func _ogg(slot: String) -> AudioStreamOggVorbis:
	var s: AudioStreamOggVorbis = load(caminho(slot))
	s.loop = true
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

E o `tocar(id)` inteiro fica assim (a faixa gerada da tela quando existe;
o `atual` passa a ser o slot quando a faixa é gerada, senão "titulo" e
"lobby" — que caem em `"salao"` na troca do id desconhecido — nunca achariam
a faixa deles):

```gdscript
## Toca a faixa do lugar (o id da sala, a tela, ou "salao"); o mesmo não reinicia.
func tocar(id: String) -> void:
	var slot: String = TELAS.get(id, id)
	var gerada := not mapa_gerado(slot).is_empty()
	if not gerada and not FAIXAS.has(id):
		id = "salao"
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

**`scripts/musica.sh`** (novo, executável) — o arquivo inteiro:

```bash
#!/usr/bin/env bash
# O pacote de música (docs/jogo/04-ritmo-e-audio.md#os-arquivos-no-repositório).
# As faixas geradas (OGG) não entram no git: vão num pacote anexado a um
# release do repositório, fixado por versão E por sha256 em
# scripts/musica.versao, como o SDL no compilar.sh. Os mapas de batidas
# (*.batidas.json) entram no git.
#
#   scripts/musica.sh baixar       baixa o pacote da versão fixada, confere e abre em godot/assets/musica/
#   scripts/musica.sh empacotar N  (o André) junta os OGG no pacote N e reescreve o musica.versao
#   scripts/musica.sh conferir     o que falta: faixa sem mapa, mapa não conferido, mapa sem faixa
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PASTA="$RAIZ/godot/assets/musica"
CACHE="${FORJA_CACHE:-$RAIZ/.cache}"
VERSOES="$RAIZ/scripts/musica.versao"
# shellcheck source=/dev/null
source "$VERSOES"   # MUSICA_VERSAO e MUSICA_SHA256
REPO="Hefesto-Team/Forja"
diga() { printf '==> %s\n' "$*"; }

baixar() {
  if [[ "$MUSICA_VERSAO" == "0" ]]; then
    diga "ainda não há pacote de música: o jogo toca a trilha sintetizada"
    return 0
  fi
  local nome="forja-musica-${MUSICA_VERSAO}.tar.gz"
  local tar="$CACHE/$nome"
  mkdir -p "$CACHE"
  if [[ ! -f "$tar" ]] || [[ "$(sha256sum "$tar" | cut -d' ' -f1)" != "$MUSICA_SHA256" ]]; then
    diga "baixando o pacote de música ${MUSICA_VERSAO}"
    rm -f "$tar.parcial"
    if ! curl -fsSL -o "$tar.parcial" "https://github.com/$REPO/releases/download/musica-${MUSICA_VERSAO}/$nome"; then
      # repositório privado: o gh com o login de quem roda
      command -v gh > /dev/null || { echo "não deu para baixar o pacote de música (sem acesso e sem gh)" >&2; exit 1; }
      rm -f "$tar.parcial"
      gh release download "musica-${MUSICA_VERSAO}" -R "$REPO" -p "$nome" -O "$tar.parcial"
    fi
    mv "$tar.parcial" "$tar"
  fi
  local tem
  tem="$(sha256sum "$tar" | cut -d' ' -f1)"
  if [[ "$tem" != "$MUSICA_SHA256" ]]; then
    echo "sha256 do pacote de música não confere: $tem (esperado $MUSICA_SHA256)" >&2
    rm -f "$tar"
    exit 1
  fi
  mkdir -p "$PASTA"
  tar -xzf "$tar" -C "$PASTA"
  diga "música ${MUSICA_VERSAO} em godot/assets/musica ($(find "$PASTA" -name '*.ogg' | wc -l) faixas)"
}

empacotar() {
  local versao="${1:?a versão nova do pacote (um número)}"
  local nome="forja-musica-${versao}.tar.gz"
  mkdir -p "$RAIZ/dist"
  (cd "$PASTA" && find . -name '*.ogg' -printf '%P\n' | LC_ALL=C sort > "$RAIZ/dist/musica.lista")
  [[ -s "$RAIZ/dist/musica.lista" ]] || { echo "nenhum OGG em godot/assets/musica" >&2; exit 1; }
  # reproduzível: a mesma música dá o mesmo pacote (ordem, datas e dono fixos)
  tar --mtime=@0 --owner=0 --group=0 --numeric-owner -C "$PASTA" -cf - -T "$RAIZ/dist/musica.lista" \
    | gzip -n -9 > "$RAIZ/dist/$nome"
  local sha
  sha="$(sha256sum "$RAIZ/dist/$nome" | cut -d' ' -f1)"
  printf 'MUSICA_VERSAO=%s\nMUSICA_SHA256=%s\n' "$versao" "$sha" > "$VERSOES"
  diga "dist/$nome ($(wc -l < "$RAIZ/dist/musica.lista") faixas), sha256 $sha"
  diga "suba com: gh release create musica-$versao dist/$nome -R $REPO --title \"Música $versao\" --notes \"O pacote de música $versao.\""
  diga "e faça commit do scripts/musica.versao"
}

conferir() {
  local falta=0
  while IFS= read -r ogg; do
    local mapa="${ogg%.ogg}.batidas.json"
    if [[ ! -f "$mapa" ]]; then
      echo "sem mapa: ${ogg#"$PASTA"/}"; falta=1
    elif ! grep -q '"conferido": *true' "$mapa"; then
      echo "mapa não conferido: ${mapa#"$PASTA"/}"; falta=1
    fi
  done < <(find "$PASTA" -name '*.ogg' | LC_ALL=C sort)
  while IFS= read -r mapa; do
    [[ -f "${mapa%.batidas.json}.ogg" ]] || echo "mapa sem faixa (o pacote foi baixado?): ${mapa#"$PASTA"/}"
  done < <(find "$PASTA" -name '*.batidas.json' | LC_ALL=C sort)
  [[ "$falta" == 0 ]] && diga "a música confere" || return 1
}

case "${1:-}" in
  baixar) baixar ;;
  empacotar) empacotar "${2:-}" ;;
  conferir) conferir ;;
  *) echo "uso: scripts/musica.sh baixar | empacotar N | conferir" >&2; exit 2 ;;
esac
```

**`scripts/musica.versao`** (novo):

```
MUSICA_VERSAO=0
MUSICA_SHA256=
```

**`scripts/mapa_de_batidas.py`** (novo) — o arquivo inteiro, provado nesta
preparação com a sua própria prova (`--prova`: cliques a 122, 160 e 90 bpm
com o primeiro tempo em lugares diferentes, e uma faixa que escorrega):

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

## Passos

1. **Prova verde antes** (`bash tests/prova_do_jogo.sh`).
2. **`scripts/mapa_de_batidas.py`**: crie e rode
   `python3 scripts/mapa_de_batidas.py --prova` (quatro `ok`).
3. **`scripts/musica.sh`** e **`scripts/musica.versao`**: crie (`chmod +x`
   no `.sh`). Rode `scripts/musica.sh baixar` (diz que ainda não há pacote)
   e `scripts/musica.sh conferir` (sem faixa, confere).
4. **`.gitignore`**: acrescente

   ```
   # as faixas geradas vêm do pacote de música (scripts/musica.sh), não do git
   godot/assets/musica/**/*.ogg
   godot/assets/musica/**/*.ogg.import
   ```

   e crie `godot/assets/musica/LEIA-ME.md` curto: de onde vêm as faixas (o
   André diz o serviço e a licença; a sessão **não** inventa), o formato do
   mapa, e os três comandos do `musica.sh`. Acrescente a linha da pasta na
   tabela de `godot/assets/LEIA-ME.md`.
5. **`godot/scripts/musica.gd`**: o bloco de "O alvo", as três ligações
   (`mapa`, `tocar_do_zero`, `laco_s`) e o `tocar(id)` novo. O `_stream()`
   continua devolvendo a sintetizada (`AudioStreamWAV`).
6. **`godot/scripts/main.gd:214`**: `Musica.tocar(sala_id if qual == "sala" else qual)`
   (o título, o lobby e o salão com a faixa de cada um; sem ela, a
   sintetizada do salão, como hoje). O pódio já pede `"podio"`
   (`main.gd:466`).
7. **`godot/project.godot`**: a seção nova

   ```
   [audio]

   driver/mix_rate=48000
   ```

   **(prova)** — a trilha sintetizada e os efeitos têm de soar igual; a
   prova do relógio (H01) tem de continuar verde.
8. **`godot/export_presets.cfg`**: nos dois presets (linhas 17 e 48),
   `include_filter="*.batidas.json"`.
9. **`scripts/exportar.sh`**: antes do `godot --import` (linha 256),
   `"$RAIZ/scripts/musica.sh" baixar`. Com `MUSICA_VERSAO=0` ele só avisa.
10. **`godot/testes/prova_do_jogo.gd`**: `_prova_das_faixas()` (em
    "Provas"), chamada logo depois de `await _prova_do_relogio()`.
    **(prova)** E o metrônomo da H01 (`godot/testes/metronomo.gd`) passa a
    ler o slot do ambiente: `var slot := OS.get_environment("SLOT")`, com
    `"MUS_S01_J01"` quando vazio — é com ele que o André confere cada mapa.
11. **O 13** e a **documentação**: o que está marcado **novo**; em
    `docs/DESENVOLVER.md`, três linhas sobre o `scripts/musica.sh`; no 04,
    "Os arquivos no repositório", troque "A recomendação é a segunda" por "A
    Sprint H escolheu a segunda (H05)".

## Armadilhas

- **Nenhum OGG no git**, nem para teste: o `.gitignore` do passo 4 vem
  antes de qualquer faixa.
- **O laço do OGG volta ao zero** (`loop_offset = 0`): o `Ritmo` conta as
  voltas supondo isso (`posicao_continua`, H01).
- **Mapa não conferido não toca**: é regra do 04 ("o mapa é conferido à mão
  antes de a faixa entrar no jogo"). Não ponha `"conferido": true` num mapa
  que ninguém ouviu.
- **O `.json` na exportação**: sem o `include_filter`, o jogo exportado não
  acha o mapa e toca a sintetizada, calado (só o `push_warning`). A
  prova da exportação do André mostra.
- **O repositório pode ser privado**: o `curl` do release dá 404; o
  `musica.sh` cai no `gh release download` com o login de quem roda.
- **A taxa de 48 kHz** muda a mistura do jogo inteiro: se alguma prova
  mudar de resultado no passo 7, pare e anote (não é para mudar nada).
- **O relógio sem faixa**: slot sem faixa gerada e sem sintetizada (A Voz,
  O Canto) continua pelo relógio do sistema (H01). Nenhum caminho de prova.
- **`.uid`**: só GDScript novo tem `.uid`; esta ficha não cria `.gd` novo
  (só muda o `musica.gd`).

## Não fazer

- Não gerar nem baixar faixa na sessão; não pôr faixa de teste no git.
- Não usar MP3 (o preenchimento de silêncio quebra o laço — o 04).
- Não reamostrar nada em tempo de jogo: tudo a 48 kHz.
- Não mexer no `compilar.sh`, no SDL nem no godot-cpp.

## Pronto quando

Sem faixa gerada, o jogo toca a trilha sintetizada como hoje; com uma faixa
e o mapa conferido no lugar (o André confere com três faixas), cada uma toca
no seu minigame e na sua tela, o `Ritmo` segue o mapa, o pacote de música se
empacota, sobe, baixa e confere por sha256, e a exportação leva os mapas.

## Provas

**Na sessão:**

```bash
python3 scripts/mapa_de_batidas.py --prova
scripts/musica.sh baixar && scripts/musica.sh conferir
bash tests/prova_do_jogo.sh
```

A checagem nova em `godot/testes/prova_do_jogo.gd`:

```gdscript
## As faixas (H05): o caminho de cada slot, o mapa lido do JSON, e sem a
## faixa gerada, a trilha sintetizada. Pura (não toca nada).
func _prova_das_faixas() -> void:
	_esperar(Musica.caminho("MUS_S01_J01") == "res://assets/musica/S01/MUS_S01_J01.ogg", "faixas: o caminho de uma faixa de minigame")
	_esperar(Musica.caminho("MUS_TELA_SALAO") == "res://assets/musica/telas/MUS_TELA_SALAO.ogg", "faixas: o caminho de uma tela")
	var m := Musica.ler_mapa('{"slot": "MUS_S01_J01", "bpm": 122.0, "primeiro_tempo_s": 0.372, "compassos": 64, "secoes": [], "conferido": true}')
	_esperar(is_equal_approx(float(m.get("bpm", 0.0)), 122.0) and is_equal_approx(float(m.get("primeiro_tempo", 0.0)), 0.372) and bool(m.get("conferido", false)),
		"faixas: o mapa se lê (%s)" % [m])
	_esperar(Musica.ler_mapa('{"bpm": 0}').is_empty() and Musica.ler_mapa("não é json").is_empty(), "faixas: mapa ruim não vale")
	_esperar(not bool(Musica.ler_mapa('{"bpm": 120.0, "primeiro_tempo_s": 0.0}').get("conferido", true)), "faixas: sem «conferido», não conferido")
	_esperar(AudioServer.get_mix_rate() == 48000.0, "faixas: a mistura a 48 kHz (%d)" % AudioServer.get_mix_rate())
	# sem a faixa gerada na pasta (a sessão da nuvem nunca tem), a sintetizada
	if not ResourceLoader.exists(Musica.caminho("MUS_S01_J01")):
		_esperar(Musica.mapa_gerado("MUS_S01_J01").is_empty() and bool(Musica.mapa("MUS_S01_J01").get("sintetizada", false)) == Forja.modulo,
			"faixas: sem a faixa gerada, a trilha sintetizada")
```

**Com o André, local:** ver abaixo.

## Para o André (local)

Com três faixas prontas (por exemplo `MUS_S01_J01`, `MUS_S02_J06` e
`MUS_TELA_SALAO`), em OGG 48 kHz estéreo, na pasta de cada uma:

```bash
python3 scripts/mapa_de_batidas.py godot/assets/musica/S01/MUS_S01_J01.ogg --bpm 122
# ouvir o metrônomo na faixa (com "conferido": true provisório no .json, só
# na sua máquina, para ela tocar); se o tique cai no tempo do começo ao fim,
# o "conferido": true fica e vai para o commit
SLOT=MUS_S01_J01 tools/Godot_v4.4.1-stable_linux.x86_64 --path godot res://testes/metronomo.tscn
scripts/musica.sh conferir
scripts/musica.sh empacotar 1     # e o gh release create que ele imprime
scripts/exportar.sh linux && bash tests/prova_da_exportacao.sh
```

Diga: "as três tocam no lugar, no tempo" ou o que escorregou (o
`escorrega_ms` do mapa ajuda).

## Ao terminar

- Marque a H05 como **feito** no [quadro](README.md), com o commit e o gasto
  real.
- Commit sugerido (sem trailer):
  `feat: o pipeline das faixas — o pacote de música no release, o mapa de batidas e a faixa de cada tela`
