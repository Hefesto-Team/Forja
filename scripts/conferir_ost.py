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
