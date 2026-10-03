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
