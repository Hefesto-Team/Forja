#!/usr/bin/env python3
"""O gerador de sons da Forja (docs/jogo/arte/03-som.md, «O gerador»).

Só a biblioteca padrão. Toda receita é síntese por código, 48 kHz, mono,
16 bits, com semente fixa: rodar duas vezes dá os mesmos bytes. Nenhum som
sai de IA, nenhum som toca: o gerador só escreve arquivos.

    python3 gerar_sons.py                  # os 77 sons da bíblia, WAV e OGG
    python3 gerar_sons.py --so 'jul_*'     # uma família (padrão do fnmatch)
    python3 gerar_sons.py --lista          # id, família, duração e pico, sem escrever
    python3 gerar_sons.py --conferir       # confere os WAV contra o mapa; sai 1 se falhar
    python3 gerar_sons.py --marcar         # depois de gerar: o mapa diz «gerado» e o caminho
    python3 gerar_sons.py kenney "Impact Sounds/Audio/impactWood_heavy_000.ogg" carimbo_0 --cru

A saída padrão é esta pasta (godot/estudos/direcao/som/, com .gdignore: o
Godot não importa nada daqui). A cópia para godot/assets/sons/ é da H11.
O OGG (libvorbis, q6) sai pelo ffmpeg, se ele existir; o WAV não precisa dele.
"""

import argparse
import array
import csv
import fnmatch
import io
import math
import random
import shutil
import subprocess
import sys
import wave
import zlib
from pathlib import Path

SR = 48000
AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[3]
MAPA = RAIZ / "docs/jogo/audio/mapa.csv"
KENNEY = RAIZ / "oficina/kenney/3.7.0/Audio"
TAU = 2.0 * math.pi

# ------------------------------------------------------------ as constantes --
## A nota de cada lugar (H04, TOM_DO_LUGAR): Dó5, Ré5, Fá5, Sol5.
NOTA = {1: 523.25, 2: 587.33, 3: 698.46, 4: 783.99}
## O pio: a segunda nota, em semitons sobre a do lugar.
INTERVALO = {"segunda": 2, "terca": -4, "quarta": 5, "quinta": 7, "quinta_baixo": -7, "oitava": 12}
## As parciais da bigorna (sintese.c): razão e amplitude.
PARCIAIS = [(1.0, 1.0), (2.76, 0.62), (5.40, 0.45), (8.93, 0.30), (13.34, 0.18), (18.64, 0.10)]
## O teto de duração por prefixo, em ms (03, «O formato»).
TETO = [("ui_sorteio", 480), ("ui_", 120), ("reacao_", 120), ("jul_", 250), ("ass_", 400),
        ("pio_", 400), ("car_", 1200), ("fx_", 1600), ("jin_", 2000), ("amb_", 8000)]


def amostras(seg):
    return int(round(seg * SR))


def semi(s):
    return 2.0 ** (s / 12.0)


# -------------------------------------------------------------- os filtros --
def biquad(x, tipo, f, q=0.7071, ganho_db=0.0):
    """Os biquads do RBJ: lp, hp, bp (pico 0 dB) e grave (prateleira, S = 1)."""
    w = TAU * min(f, SR * 0.45) / SR
    cw, sw = math.cos(w), math.sin(w)
    al = sw / (2.0 * q)
    if tipo == "lp":
        b0, b1, b2, a0, a1, a2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2, 1 + al, -2 * cw, 1 - al
    elif tipo == "hp":
        b0, b1, b2, a0, a1, a2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2, 1 + al, -2 * cw, 1 - al
    elif tipo == "bp":
        b0, b1, b2, a0, a1, a2 = al, 0.0, -al, 1 + al, -2 * cw, 1 - al
    elif tipo == "grave":
        A = 10 ** (ganho_db / 40.0)
        al = sw / 2.0 * math.sqrt(2.0)
        r = 2 * math.sqrt(A) * al
        b0 = A * ((A + 1) - (A - 1) * cw + r)
        b1 = 2 * A * ((A - 1) - (A + 1) * cw)
        b2 = A * ((A + 1) - (A - 1) * cw - r)
        a0 = (A + 1) + (A - 1) * cw + r
        a1 = -2 * ((A - 1) + (A + 1) * cw)
        a2 = (A + 1) + (A - 1) * cw - r
    else:
        raise ValueError(tipo)
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    y = [0.0] * len(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        o = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, o
        y[i] = o
    return y


def svf(x, fc, q=0.7071, modo="lp"):
    """O filtro de estado variável (TPT): o corte pode mudar a cada amostra.
    fc é um número ou uma função do tempo em segundos."""
    k = 1.0 / q
    ic1 = ic2 = 0.0
    y = [0.0] * len(x)
    fixo = not callable(fc)
    if fixo:
        g = math.tan(math.pi * min(fc, SR * 0.45) / SR)
    for i, v in enumerate(x):
        if not fixo:
            g = math.tan(math.pi * min(max(fc(i / SR), 10.0), SR * 0.45) / SR)
        a1 = 1.0 / (1.0 + g * (g + k))
        a2 = g * a1
        a3 = g * a2
        v3 = v - ic2
        v1 = a1 * ic1 + a2 * v3
        v2 = ic2 + a2 * ic1 + a3 * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        y[i] = v2 if modo == "lp" else (v1 if modo == "bp" else v - k * v1 - v2)
    return y


def um_polo(x, f, modo="lp"):
    a = math.exp(-TAU * f / SR)
    y = [0.0] * len(x)
    s = 0.0
    for i, v in enumerate(x):
        s = (1 - a) * v + a * s
        y[i] = s if modo == "lp" else v - s
    return y


# ---------------------------------------------------------- os osciladores --
def _blep(t, dt):
    if t < dt:
        t /= dt
        return t + t - t * t - 1.0
    if t > 1.0 - dt:
        t = (t - 1.0) / dt
        return t * t + t + t + 1.0
    return 0.0


def oscilador(forma, n, freq, largura=0.5, fase=0.0):
    """freq(t) em Hz. Formas: seno, serra, quadrada, pulso (polyBLEP)."""
    y = [0.0] * n
    p = fase
    for i in range(n):
        f = freq(i / SR)
        dt = f / SR
        if forma == "seno":
            y[i] = math.sin(TAU * p)
        elif forma == "serra":
            y[i] = 2.0 * p - 1.0 - _blep(p, dt)
        else:
            w = 0.5 if forma == "quadrada" else largura
            v = 1.0 if p < w else -1.0
            v += _blep(p, dt)
            v -= _blep((p + 1.0 - w) % 1.0, dt)
            y[i] = v - (2.0 * w - 1.0)  # o pulso estreito tem média: fora, ou vira baque grave
        p += dt
        p -= math.floor(p)
    return y


def ruido(n, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def rosa(n, rng):
    """O ruído rosa de Paul Kellet."""
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    y = [0.0] * n
    for i in range(n):
        w = rng.uniform(-1.0, 1.0)
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        y[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11
        b6 = w * 0.115926
    return y


# ------------------------------------------------------------- utilidades --
def vazio(seg):
    return [0.0] * amostras(seg)


def somar(dst, src, inicio=0.0, ganho=1.0):
    o = amostras(inicio)
    for i, v in enumerate(src):
        j = o + i
        if 0 <= j < len(dst):
            dst[j] += v * ganho
    return dst


def pico(x):
    return max((abs(v) for v in x), default=0.0)


def normalizar(x, alvo=1.0):
    p = pico(x)
    return [v * alvo / p for v in x] if p > 0 else x


def envelope(n, ataque=0.005, queda60=None, soltar=0.005):
    """Ataque linear, queda exponencial (−60 dB em queda60 s) e uma rampa
    curta no fim, para a nota acabar sem clique."""
    queda60 = queda60 or n / SR
    na, ns = max(1, amostras(ataque)), max(1, amostras(soltar))
    e = [0.0] * n
    for i in range(n):
        t = i / SR
        v = 10 ** (-3.0 * t / queda60)
        if i < na:
            v *= i / na
        if i >= n - ns:
            v *= (n - 1 - i) / ns
        e[i] = v
    return e


def vezes(x, e):
    return [a * b for a, b in zip(x, e)]


# ----------------------------------------------------------- os timbres --
def bigorna(f, seg, brilho=1.0, rng=None, ruido_ms=4.0):
    """A família metal: as seis parciais da bigorna, as altas caindo mais
    rápido, e 4 ms de ruído no ataque."""
    n = amostras(seg)
    y = [0.0] * n
    for k, (r, a) in enumerate(PARCIAIS):
        fk = f * r
        if fk > SR * 0.45:
            continue
        a = a * (brilho if k else 1.0)
        decai = 6.9 * math.sqrt(r) / seg
        ph = TAU * fk / SR
        for i in range(n):
            y[i] += a * math.sin(ph * i) * math.exp(-decai * i / SR)
    if rng is not None and ruido_ms > 0:
        nr = amostras(ruido_ms / 1000.0)
        rr = um_polo(ruido(nr, rng), 2000.0, "hp")
        for i in range(nr):
            y[i] += 0.9 * rr[i] * (1.0 - i / nr)
    na = amostras(0.0015)
    for i in range(min(na, n)):
        y[i] *= i / na
    ns = amostras(0.004)
    for i in range(max(0, n - ns), n):
        y[i] *= (n - 1 - i) / ns
    return y


def martelada(f, seg=0.3, rng=None, brilho=1.0):
    """A martelada: a bigorna com um baque grave no ataque."""
    y = bigorna(f, seg, brilho, rng)
    b = baque(min(f, 110.0), 0.06)
    return somar(y, b, 0.0, 0.8)


def baque(f, seg):
    """Um baque surdo: um seno que cai uma oitava em 30 ms."""
    n = amostras(seg)
    y = oscilador("seno", n, lambda t: f * (1.0 + math.exp(-t / 0.012)))
    return vezes(y, envelope(n, 0.001, seg, 0.004))


def voz(lugar, f, seg, fm=None, queda60=None, ataque=0.005):
    """A nota no timbre do lugar (03, «A voz de cada cavaleiro»).
    fm(t) multiplica a frequência (o wow do erro, a fita acelerando)."""
    n = amostras(seg)
    fm = fm or (lambda t: 1.0)
    if lugar == 1:
        # o cristal: FM 1:3,5, índice 2,5 caindo a 0 em 400 ms
        y = [0.0] * n
        pc = pm = 0.0
        for i in range(n):
            t = i / SR
            fi = f * fm(t)
            ind = 2.5 * max(0.0, 1.0 - t / 0.4)
            y[i] = math.sin(TAU * pc + ind * math.sin(TAU * pm))
            pc = (pc + fi / SR) % 1.0
            pm = (pm + 3.5 * fi / SR) % 1.0
    elif lugar == 2:
        # o pulso: 25 %, passa-baixa em 3 kHz
        y = biquad(oscilador("pulso", n, lambda t: f * fm(t), 0.25), "lp", 3000.0)
    elif lugar == 3:
        # a faísca: quadrada que começa 2 semitons acima e cai em 30 ms
        y = oscilador("quadrada", n, lambda t: f * fm(t) * semi(2.0 * max(0.0, 1.0 - t / 0.03)))
        y = biquad(y, "lp", 6000.0)
    else:
        # o bronze: duas serras a ±7 cents, passa-baixa em 2,2 kHz
        a = oscilador("serra", n, lambda t: f * fm(t) * 2 ** (7 / 1200))
        b = oscilador("serra", n, lambda t: f * fm(t) * 2 ** (-7 / 1200), fase=0.37)
        y = biquad([(u + v) * 0.5 for u, v in zip(a, b)], "lp", 2200.0)
    return vezes(normalizar(y), envelope(n, ataque, queda60 or seg))


def acorde_forja(seg, oitava=0, queda60=None):
    """Dó, Ré, Fá e Sol, cada um na voz do dono."""
    y = vazio(seg)
    for l in (1, 2, 3, 4):
        somar(y, voz(l, NOTA[l] * 2 ** oitava, seg, queda60=queda60), 0.0, 0.25)
    return y


def baixa_brilho(x, f, brilho):
    lp = um_polo(x, f)
    return [l + brilho * (v - l) for v, l in zip(x, lp)]


def clunk(rng, grave=110.0):
    """A tecla do deck: o baque do mecanismo e o estalo do plástico."""
    y = vazio(0.12)
    somar(y, baque(grave, 0.08), 0.0, 1.0)
    nr = amostras(0.008)
    est = svf(ruido(nr, rng), 2800.0, 1.2, "bp")
    somar(y, vezes(est, [1 - i / nr for i in range(nr)]), 0.0, 1.6)
    somar(y, vezes(oscilador("seno", amostras(0.03), lambda t: 1850.0), envelope(amostras(0.03), 0.0005, 0.03)), 0.002, 0.25)
    return y


def motor(seg, f0, f1, rng, sobe=True):
    """O motor do deck: um zumbido que acelera (ou para) e o atrito."""
    n = amostras(seg)
    def f(t):
        u = min(1.0, t / seg)
        return f0 + (f1 - f0) * (1 - (1 - u) ** 2 if sobe else u * u)
    z = biquad(oscilador("serra", n, f), "lp", 900.0)
    a = biquad(ruido(n, rng), "bp", 1200.0, 0.8)
    y = [0.7 * u + 0.15 * v for u, v in zip(z, a)]
    e = [(min(1, i / n * 3) if sobe else max(0.0, 1 - i / n)) for i in range(n)]
    return vezes(y, e)


def varredura(seg, f0, f1, rng, q=1.4, curva=None):
    """Uma banda de ruído que corre de f0 a f1 (exponencial)."""
    n = amostras(seg)
    return svf(ruido(n, rng), lambda t: f0 * (f1 / f0) ** min(1.0, t / seg), q, "bp")


def blip(f, seg, f_fim=None):
    n = amostras(seg)
    f_fim = f_fim or f
    y = oscilador("seno", n, lambda t: f * (f_fim / f) ** min(1.0, t / seg))
    return vezes(y, envelope(n, 0.001, seg * 1.2, 0.004))


def boing(seg, f0=300.0, f1=120.0, vib=12.0, prof=0.06):
    n = amostras(seg)
    y = oscilador("seno", n, lambda t: (f0 * (f1 / f0) ** min(1.0, t / seg)) * (1 + prof * math.sin(TAU * vib * t)))
    y2 = oscilador("seno", n, lambda t: 2 * (f0 * (f1 / f0) ** min(1.0, t / seg)))
    y = [u + 0.25 * v for u, v in zip(y, y2)]
    return vezes(y, envelope(n, 0.003, seg * 1.6, 0.01))


# ------------------------------------------------------ o tratamento de fita --
def fita(x, modo, rng, alvo_db):
    """03, «O tratamento de fita»: wow, flutter, saturação, corpo, teto,
    chiado e dropouts. Termina no pico do mapa, com rampas de 3 ms."""
    n = len(x)
    alvo = 10 ** (alvo_db / 20.0)
    if modo == "cru":
        return [v * alvo / pico(x) for v in x]
    wow = 0.00038 * SR if modo in ("cheia", "quebrada") else 0.0
    flu = 0.0000088 * SR * (1.0 if modo in ("cheia", "quebrada") else 0.5)
    fw, ff = rng.uniform(0, TAU), rng.uniform(0, TAU)
    base = 20.0
    y = [0.0] * n
    for i in range(n):
        t = i / SR
        d = i - (base + wow * math.sin(TAU * 0.5 * t + fw) + flu * math.sin(TAU * 9.0 * t + ff))
        j = math.floor(d)
        u = d - j
        a = x[j] if 0 <= j < n else 0.0
        b = x[j + 1] if 0 <= j + 1 < n else 0.0
        y[i] = a + (b - a) * u
    y = normalizar(y, 1.0)
    k = math.tanh(1.8)
    y = [math.tanh(1.8 * v) / k for v in y]
    y = biquad(y, "grave", 90.0, ganho_db=2.0)
    y = biquad(y, "lp", 12000.0)
    y = um_polo(y, 15.0, "hp")  # o desvio DC fora
    y = normalizar(y, alvo)
    if modo in ("cheia", "quebrada"):
        ch = biquad(rosa(n, rng), "hp", 2000.0)
        rms = math.sqrt(sum(v * v for v in ch) / max(1, n)) or 1.0
        g = 10 ** (-62 / 20.0) / rms
        y = [v + c * g for v, c in zip(y, ch)]
    if modo == "quebrada":
        t = rng.expovariate(1 / 0.4) * 0.5
        fundo = 10 ** (-18 / 20.0)
        while t < n / SR:
            i0, dur, r = amostras(t), amostras(0.030), amostras(0.003)
            for i in range(i0, min(n, i0 + dur)):
                k2 = i - i0
                m = min(k2, dur - 1 - k2, r) / r
                y[i] *= 1.0 - (1.0 - fundo) * m
            t += 0.030 + rng.expovariate(1 / 0.4)
    r = amostras(0.003)
    for i in range(min(r, n)):
        w = 0.5 - 0.5 * math.cos(math.pi * i / r)
        y[i] *= w
        y[n - 1 - i] *= w
    return normalizar(y, alvo)


# --------------------------------------------------------------- as receitas --
class Som:
    def __init__(self, id, familia, ms, pico_db, modo, gerar, lugar=None, intervalo=None, semente=0):
        self.id, self.familia, self.ms, self.pico_db, self.modo = id, familia, ms, pico_db, modo
        self.gerar, self.lugar, self.intervalo, self.semente = gerar, lugar, intervalo, semente


def _ass(c):
    return voz(c.lugar, NOTA[c.lugar], 0.40)


def _pio(c):
    f = NOTA[c.lugar]
    y = vazio(0.30)
    somar(y, voz(c.lugar, f, 0.12, queda60=0.5), 0.0, 1.0)
    somar(y, voz(c.lugar, f * semi(INTERVALO[c.intervalo]), 0.20, queda60=0.32), 0.10, 1.0)
    return y


def _jul_ressonancia(c):
    f = NOTA[c.lugar]
    y = voz(c.lugar, f, 0.18, queda60=0.5)
    return somar(y, bigorna(f, 0.07, 1.0, c.rng), 0.0, 0.55)


def _jul_afinado(c):
    f = NOTA[c.lugar]
    return baixa_brilho(voz(c.lugar, f, 0.15, queda60=0.45), 2.5 * f, 0.5)


def _jul_quase(c):
    return biquad(voz(c.lugar, NOTA[c.lugar], 0.12, queda60=0.4), "lp", 1200.0)


def _jul_erro(c):
    f = NOTA[c.lugar] * 2 ** (-60 / 1200)
    y = voz(c.lugar, f, 0.22, fm=lambda t: 1 + 0.008 * math.sin(TAU * 4.0 * t), queda60=0.5)
    y = normalizar(y)
    return [round(v * 31) / 31 for v in y]  # 6 bits


def _vitoria(c):
    f = NOTA[c.lugar] / 2
    y = vazio(1.0)
    for k, s in enumerate((0, 4, 7, 12)):
        somar(y, voz(c.lugar, f * semi(s), 0.14, queda60=0.5), 0.125 * k, 0.8)
    for s in (0, 4, 7, 12):
        somar(y, voz(c.lugar, f * semi(s), 0.50, queda60=0.9), 0.5, 0.35)
    somar(y, martelada(f, 0.45, c.rng), 0.5, 0.5)
    return y


def _derrota(c):
    seg = 1.4
    n = amostras(seg)
    r = lambda t: 0.25 ** (min(t, 0.7) / 0.7)
    fonte = vazio(seg)
    for s, f in ((0, 261.63), (2, 293.66), (5, 349.23), (7, 392.0)):
        somar(fonte, oscilador("serra", n, lambda t, f=f: f * r(t)), 0.0, 0.25)
    fonte = svf(fonte, lambda t: 8000.0 * (400.0 / 8000.0) ** min(1.0, t / 0.7), 0.9, "lp")
    e = [min(1.0, i / amostras(0.01)) * (1.0 if i / SR < 0.55 else max(0.0, 1 - (i / SR - 0.55) / 0.3)) for i in range(n)]
    y = vezes(fonte, e)
    somar(y, blip(2000.0, 0.015), 0.9, 0.35)  # o plic do carretel
    return y


def _play(c):
    y = vazio(0.4)
    somar(y, clunk(c.rng), 0.0, 1.0)
    somar(y, motor(0.36, 25.0, 110.0, c.rng), 0.03, 0.35)
    return y


def _stop(c):
    y = vazio(0.25)
    somar(y, clunk(c.rng, 95.0), 0.0, 1.0)
    somar(y, motor(0.22, 110.0, 30.0, c.rng, sobe=False), 0.0, 0.3)
    return y


def _entrada(c):
    y = vazio(0.9)
    rasgo = varredura(0.6, 300.0, 6000.0, c.rng, 1.2)
    nr, nf = len(rasgo), amostras(0.008)
    rasgo = vezes(rasgo, [(i / nr) ** 1.5 * min(1.0, (nr - 1 - i) / nf) for i in range(nr)])
    somar(y, rasgo, 0.0, 1.4)
    somar(y, martelada(98.0, 0.30, c.rng), 0.600, 1.0)  # o impacto cravado em 600 ms
    return y


def _rebobinar(c):
    y = vazio(0.9)
    g = varredura(0.80, 400.0, 2400.0, c.rng, 2.5)
    n = len(g)
    g = vezes(g, [min(1.0, i / amostras(0.06)) * (0.6 + 0.4 * i / n) * (1 + 0.25 * math.sin(TAU * 23 * i / SR)) for i in range(n)])
    somar(y, g, 0.0, 1.0)
    somar(y, clunk(c.rng), 0.78, 0.9)
    return y


def _virar(c):
    y = vazio(1.6)
    somar(y, clunk(c.rng, 130.0), 0.0, 1.0)  # o eject
    t = 0.25
    while t < 1.15:  # o plástico na mão
        nr = amostras(0.012)
        est = svf(ruido(nr, c.rng), c.rng.uniform(1500, 3500), 2.0, "bp")
        somar(y, vezes(est, [1 - i / nr for i in range(nr)]), t, c.rng.uniform(0.25, 0.6))
        t += c.rng.uniform(0.04, 0.16)
    somar(y, clunk(c.rng, 100.0), 1.38, 1.0)  # o clunk de entrar
    return y


def _autostop(c):
    y = vazio(0.2)
    nr = amostras(0.004)
    somar(y, svf(ruido(nr, c.rng), 3500.0, 1.0, "bp"), 0.0, 1.5)
    somar(y, vezes(oscilador("seno", amostras(0.12), lambda t: 2400.0), envelope(amostras(0.12), 0.0005, 0.12)), 0.001, 0.25)
    somar(y, baque(140.0, 0.05), 0.0, 0.6)
    return y


def _caneta(c):
    y = vazio(0.4)
    for k, (t0, d) in enumerate(((0.01, 0.10), (0.14, 0.09), (0.26, 0.12))):
        n = amostras(d)
        s = svf(ruido(n, c.rng), lambda t: 3500.0 + 800.0 * math.sin(TAU * 7 * t), 1.6, "bp")
        e = [math.sin(math.pi * i / n) ** 0.7 * (1 + 0.3 * math.sin(TAU * 31 * i / SR)) for i in range(n)]
        somar(y, vezes(s, e), t0, 1.0)
    return y


def _boing(c):
    return boing(0.25)


def _tropeco(c):
    y = vazio(0.35)
    v = c.rng.uniform(0.95, 1.05)
    somar(y, baque(90.0 * v, 0.06), 0.0, 1.0)
    somar(y, boing(0.25, 300.0 * v, 120.0 * v, 12.0), 0.07 + c.rng.uniform(-0.01, 0.01), 0.7)
    return y


def _ui_tique(c):
    return blip(1760.0, 0.035)


def _ui_confirma(c):
    y = vazio(0.09)
    somar(y, blip(1046.5, 0.04), 0.0, 1.0)
    somar(y, blip(1568.0, 0.05), 0.04, 1.0)
    return y


def _ui_volta(c):
    y = vazio(0.09)
    somar(y, blip(1568.0, 0.04), 0.0, 1.0)
    somar(y, blip(1046.5, 0.05), 0.04, 1.0)
    return y


def _ui_peca(c):
    y = vazio(0.12)
    somar(y, bigorna(1318.5, 0.12, 0.7, c.rng, 2.0), 0.0, 0.8)
    nr = amostras(0.003)
    somar(y, svf(ruido(nr, c.rng), 4000.0, 1.0, "bp"), 0.0, 1.2)
    return y


def _ui_trava(c):
    y = vazio(0.08)
    nr = amostras(0.004)
    somar(y, svf(ruido(nr, c.rng), 3000.0, 1.0, "bp"), 0.0, 1.2)
    somar(y, blip(660.0, 0.07, 520.0), 0.002, 0.8)
    return y


def _ui_sorteio(c):
    y = vazio(0.48)
    t, passo = 0.0, 0.045
    for k in range(6):  # seis tiques que freiam
        somar(y, blip(1760.0 if k < 5 else 2093.0, 0.03), t, 1.0)
        t += passo
        passo *= 1.32
    return y


def _ui_tecla(c):
    y = vazio(0.03)
    nr = amostras(0.003)
    somar(y, svf(ruido(nr, c.rng), 2600.0, 1.0, "bp"), 0.0, 1.0)
    somar(y, blip(2637.0, 0.022), 0.0, 0.5)
    return y


def _reacao_pop(c):
    y = vazio(0.12)
    somar(y, blip(420.0, 0.09, 950.0), 0.0, 1.0)
    nr = amostras(0.003)
    somar(y, svf(ruido(nr, c.rng), 1800.0, 1.0, "bp"), 0.0, 0.8)
    return y


def _car_em_chamas(c):
    y = vazio(0.6)
    s = varredura(0.42, 300.0, 3000.0, c.rng, 0.9)
    s = vezes(s, [min(1.0, i / amostras(0.05)) * (1 - 0.6 * (i / len(s))) for i in range(len(s))])
    somar(y, s, 0.0, 1.0)
    somar(y, _jul_ressonancia(c), 0.40, 0.8)
    return y


def _car_por_um_fio(c):
    n = amostras(0.7)
    def f(t):
        cents = -50.0 * math.sin(math.pi * min(1.0, t / 0.7))
        return 1000.0 * 2 ** (cents / 1200) * (1 + 0.004 * math.sin(TAU * 6.0 * t))
    y = oscilador("seno", n, f)
    y2 = oscilador("seno", n, lambda t: 2 * f(t))
    y = [u + 0.2 * v for u, v in zip(y, y2)]
    return vezes(y, envelope(n, 0.01, 2.0, 0.06))


def _car_liga(c):
    y = vazio(0.4)
    somar(y, bigorna(523.25, 0.34, 1.0, c.rng), 0.0, 1.0)
    somar(y, bigorna(783.99, 0.34, 1.0, c.rng), 0.06, 1.0)
    return y


def _car_acorde(c):
    y = vazio(1.2)
    somar(y, martelada(98.0, 0.6, c.rng), 0.0, 0.8)
    for l in (1, 2, 3, 4):
        somar(y, voz(l, NOTA[l], 1.2, queda60=1.6), 0.0, 0.35)
    return y


def _jin_apito(c):
    y = vazio(1.0)
    somar(y, clunk(c.rng, 100.0), 0.0, 1.0)
    n = amostras(0.45)
    a = oscilador("seno", n, lambda t: 2093.0 * (1 + 0.006 * math.sin(TAU * 28 * t)))
    sopro = svf(ruido(n, c.rng), 2093.0, 6.0, "bp")
    ap = [u + 0.35 * v for u, v in zip(a, sopro)]
    e = [min(1.0, i / amostras(0.015)) * min(1.0, (n - 1 - i) / amostras(0.01)) for i in range(n)]
    somar(y, vezes(ap, e), 0.06, 0.6)
    return y


def _jin_virada(c):
    y = vazio(2.0)
    n = amostras(0.32)
    acel = vazio(0.32)
    for l in (1, 2, 3, 4):
        f0 = NOTA[l] / 2
        somar(acel, oscilador("serra", n, lambda t, f0=f0: f0 * semi(-5.0 * (1 - min(1.0, t / 0.3)))), 0.0, 0.25)
    acel = biquad(acel, "lp", 2500.0)
    acel = vezes(acel, [(i / n) ** 1.2 * min(1.0, (n - 1 - i) / amostras(0.01)) for i in range(n)])
    somar(y, acel, 0.0, 0.8)
    somar(y, martelada(98.0, 0.5, c.rng), 0.30, 1.0)
    for k, l in enumerate((1, 2, 3, 4)):
        somar(y, voz(l, NOTA[l], 0.70, queda60=0.9), 0.30 + 0.25 * k, 0.55)
    return y


def _jin_entrada_tique(c):
    return martelada(1568.0, 0.12, c.rng)


def _jin_entrada_vai(c):
    y = vazio(0.4)
    somar(y, martelada(98.0, 0.4, c.rng), 0.0, 1.0)
    somar(y, acorde_forja(0.4, 0, queda60=0.7), 0.0, 1.2)
    return y


def _amb_salao(c):
    seg, xf = 8.0, 0.5
    n = amostras(seg + xf)
    # o fogo: um ruído grave que respira devagar, mais um crepitar miúdo
    grave = biquad(biquad(ruido(n, c.rng), "lp", 420.0), "lp", 420.0)
    resp = []
    v, alvo = 0.6, 0.6
    for i in range(n):
        if i % 2400 == 0:
            alvo = c.rng.uniform(0.4, 1.0)
        v += (alvo - v) * 0.0004
        resp.append(v)
    y = [g * r for g, r in zip(grave, resp)]
    y = normalizar(y, 0.6)
    crep = [0.0] * n
    for i in range(n):
        if c.rng.random() < 0.0009:
            crep[i] = c.rng.uniform(-1, 1)
    crep = svf(crep, 2500.0, 1.5, "bp")
    y = [a + 3.0 * b for a, b in zip(y, crep)]
    # a brasa que estala, uma a cada 1,7 s em média
    t = c.rng.uniform(0.2, 1.0)
    while t < seg + xf - 0.1:
        nr = amostras(0.025)
        est = svf(ruido(nr, c.rng), c.rng.uniform(1200, 3000), 3.0, "bp")
        somar(y, vezes(est, [(1 - i / nr) ** 2 for i in range(nr)]), t, c.rng.uniform(1.2, 2.2))
        t += c.rng.expovariate(1 / 1.7)
    # o laço: os últimos 0,5 s se fundem nos primeiros, sem clique
    ns, nx = amostras(seg), amostras(xf)
    out = y[:ns]
    for i in range(nx):
        w = i / nx
        out[i] = out[i] * w + y[ns + i] * (1 - w)
    return out


def receitas():
    s = []
    for l in (1, 2, 3, 4):
        p = f"p{l}"
        s.append(Som(f"ass_{p}", "voz", 400, -12, "cheia", _ass, l))
        for iv in INTERVALO:
            s.append(Som(f"pio_{p}_{iv}", "voz", 300, -12, "cheia", _pio, l, iv))
        s.append(Som(f"jul_ressonancia_{p}", "voz", 180, -12, "cheia", _jul_ressonancia, l))
        s.append(Som(f"jul_afinado_{p}", "voz", 150, -12, "cheia", _jul_afinado, l))
        s.append(Som(f"jul_quase_{p}", "voz", 120, -12, "cheia", _jul_quase, l))
        s.append(Som(f"jul_erro_{p}", "dissonancia", 220, -12, "quebrada", _jul_erro, l))
        s.append(Som(f"fx_vitoria_{p}", "voz", 1000, -9, "cheia", _vitoria, l))
    s += [
        Som("fx_derrota", "dissonancia", 1400, -6, "quebrada", _derrota),
        Som("fx_play", "fita", 400, -6, "cheia", _play),
        Som("fx_stop", "fita", 250, -6, "cheia", _stop),
        Som("fx_entrada", "fita", 900, -6, "cheia", _entrada),
        Som("fx_rebobinar", "fita", 900, -6, "cheia", _rebobinar),
        Som("fx_virar", "fita", 1600, -6, "cheia", _virar),
        Som("fx_autostop", "fita", 200, -6, "cheia", _autostop),
        Som("fx_caneta", "fita", 400, -6, "cheia", _caneta),
        Som("fx_boing", "corpo", 250, -6, "cheia", _boing),
    ]
    for k in range(3):
        s.append(Som(f"fx_tropeco_{k}", "corpo", 350, -6, "cheia", _tropeco, semente=k))
    s += [
        Som("ui_tique", "interface", 35, -12, "leve", _ui_tique),
        Som("ui_confirma", "interface", 90, -12, "leve", _ui_confirma),
        Som("ui_volta", "interface", 90, -12, "leve", _ui_volta),
        Som("ui_peca", "interface", 120, -12, "leve", _ui_peca),
        Som("ui_trava", "interface", 80, -12, "leve", _ui_trava),
        Som("ui_sorteio", "interface", 480, -12, "leve", _ui_sorteio),
        Som("ui_tecla", "interface", 30, -12, "leve", _ui_tecla),
        Som("reacao_pop", "interface", 120, -12, "leve", _reacao_pop),
        Som("car_em_chamas", "voz", 600, -9, "leve", _car_em_chamas, 1),
        Som("car_por_um_fio", "voz", 700, -9, "leve", _car_por_um_fio),
        Som("car_liga", "voz", 400, -9, "leve", _car_liga),
        Som("car_acorde", "voz", 1200, -9, "leve", _car_acorde),
        Som("jin_apito", "fita", 1000, -6, "cheia", _jin_apito),
        Som("jin_virada", "voz", 2000, -9, "leve", _jin_virada),
        Som("jin_entrada_tique", "metal", 120, -9, "cheia", _jin_entrada_tique),
        Som("jin_entrada_vai", "metal", 400, -6, "cheia", _jin_entrada_vai),
        Som("amb_salao", "ambiente", 8000, -18, "cheia", _amb_salao),
    ]
    return {x.id: x for x in s}


# ------------------------------------------------------------ a escrita --
class Ctx:
    def __init__(self, som):
        self.lugar, self.intervalo = som.lugar, som.intervalo
        self.rng = random.Random(zlib.crc32(som.id.encode()) * 1000 + som.semente)


def gerar(som):
    c = Ctx(som)
    y = som.gerar(c)
    n = amostras(som.ms / 1000.0)
    y = (y + [0.0] * n)[:n]
    return fita(y, som.modo, c.rng, som.pico_db)


def escrever_wav(caminho, y):
    a = array.array("h", (max(-32767, min(32767, int(round(v * 32767)))) for v in y))
    if sys.byteorder != "little":
        a.byteswap()
    with wave.open(str(caminho), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(a.tobytes())


def escrever_ogg(wav):
    if not shutil.which("ffmpeg"):
        return False
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "6",
                    "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
                    str(wav.with_suffix(".ogg"))], check=True)
    return True


def ler_wav(caminho):
    with wave.open(str(caminho), "rb") as w:
        fmt = (w.getframerate(), w.getnchannels(), w.getsampwidth())
        dados = w.readframes(w.getnframes())
    a = array.array("h")
    a.frombytes(dados[: len(dados) // 2 * 2])
    if sys.byteorder != "little":
        a.byteswap()
    if fmt[1] > 1:
        a = a[:: fmt[1]]
    return fmt, [v / 32768.0 for v in a]


def medir(caminho):
    fmt, y = ler_wav(caminho)
    p = pico(y)
    return {
        "fmt": fmt,
        "ms": len(y) * 1000.0 / fmt[0],
        "pico_db": 20 * math.log10(p) if p > 0 else -120.0,
        "dc": abs(sum(y) / max(1, len(y))) / p if p > 0 else 0.0,
        "pontas": max(abs(y[0]), abs(y[-1])) if y else 0.0,
    }


def teto(id):
    for pre, ms in TETO:
        if id.startswith(pre):
            return ms
    return None


def ler_mapa():
    texto = MAPA.read_text(encoding="utf-8")
    linhas = list(csv.reader(io.StringIO(texto)))
    return linhas[0], linhas[1:]


def gravar_mapa(cab, linhas):
    o = io.StringIO()
    csv.writer(o, lineterminator="\n").writerows([cab] + linhas)
    MAPA.write_text(o.getvalue(), encoding="utf-8")


def conferir(saida):
    """O formato do 03, cada som do gerador, e cada linha do mapa com arquivo."""
    falhas = []
    cab, linhas = ler_mapa()
    ix = {k: i for i, k in enumerate(cab)}
    vistos = 0
    for l in linhas:
        id, estado, arq = l[ix["id"]], l[ix["estado"]], l[ix["arquivo"]]
        if estado not in ("gerado", "no jogo") or not arq.endswith(".wav"):
            continue
        caminho = RAIZ / arq
        if not caminho.exists():
            falhas.append(f"{id}: falta {arq}")
            continue
        m = medir(caminho)
        vistos += 1
        if m["fmt"] != (SR, 1, 2):
            falhas.append(f"{id}: formato {m['fmt']}, não 48 kHz mono 16 bits")
        ms = float(l[ix["duracao_ms"]] or 0)
        if ms and abs(m["ms"] - ms) > 0.05 * ms:
            falhas.append(f"{id}: {m['ms']:.0f} ms, o mapa diz {ms:.0f}")
        alvo = float(l[ix["pico_dbfs"]] or 0)
        if abs(m["pico_db"] - alvo) > 0.5:
            falhas.append(f"{id}: pico {m['pico_db']:.1f} dBFS, o mapa diz {alvo:.1f}")
        if "gerar_sons.py --so" in l[ix["receita"]]:
            tt = teto(id)
            if tt and m["ms"] > tt + 0.5:
                falhas.append(f"{id}: {m['ms']:.0f} ms passa do teto de {tt}")
            if m["pico_db"] > -1.0:
                falhas.append(f"{id}: pico acima de −1 dBFS")
            if m["dc"] > 0.005:
                falhas.append(f"{id}: desvio DC de {m['dc'] * 100:.2f} % do pico")
            if m["pontas"] >= 0.001:
                falhas.append(f"{id}: a ponta vale {m['pontas']:.4f}")
    for id, som in receitas().items():
        caminho = saida / f"{id}.wav"
        if not caminho.exists():
            falhas.append(f"{id}: o gerador não escreveu {caminho.relative_to(RAIZ)}")
    for f in falhas:
        print("FALHA", f)
    print(f"{vistos} arquivos do mapa conferidos, {len(falhas)} falhas")
    return 1 if falhas else 0


def marcar(saida, ids):
    cab, linhas = ler_mapa()
    ix = {k: i for i, k in enumerate(cab)}
    n = 0
    for l in linhas:
        if l[ix["id"]] in ids and (saida / f"{l[ix['id']]}.wav").exists():
            l[ix["arquivo"]] = str((saida / f"{l[ix['id']]}.wav").relative_to(RAIZ))
            l[ix["estado"]] = "gerado"
            n += 1
    gravar_mapa(cab, linhas)
    print(f"{n} linhas do mapa marcadas «gerado»")


def kenney(args):
    origem = KENNEY / args.origem
    saida = Path(args.saida) if args.saida else RAIZ / "godot/assets/sons"
    saida.mkdir(parents=True, exist_ok=True)
    bruto = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(origem), "-ac", "1", "-ar", str(SR),
                            "-f", "s16le", "-"], check=True, capture_output=True).stdout
    a = array.array("h")
    a.frombytes(bruto[: len(bruto) // 2 * 2])
    y = [v / 32768.0 for v in a]
    if not args.cru:
        som = Som(args.id, "interface", 0, -12, "leve", None)
        y = fita(y, "leve", Ctx(som).rng, 20 * math.log10(pico(y)))
    escrever_wav(saida / f"{args.id}.wav", y)
    print(saida / f"{args.id}.wav")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "kenney":
        ap = argparse.ArgumentParser(prog="gerar_sons.py kenney")
        ap.add_argument("_k")
        ap.add_argument("origem")
        ap.add_argument("id")
        ap.add_argument("--cru", action="store_true")
        ap.add_argument("--saida")
        return kenney(ap.parse_args())
    ap = argparse.ArgumentParser(description="Os sons da Forja, por código.")
    ap.add_argument("--so", help="um id ou um padrão ('jul_*')")
    ap.add_argument("--lista", action="store_true")
    ap.add_argument("--conferir", action="store_true")
    ap.add_argument("--marcar", action="store_true", help="o mapa diz «gerado» e aponta o arquivo")
    ap.add_argument("--saida", default=str(AQUI))
    ap.add_argument("--sem-ogg", action="store_true")
    ap.add_argument("--fita", choices=["cheia", "leve", "quebrada", "cru"])
    ap.add_argument("--lugar", type=int, choices=[1, 2, 3, 4])
    ap.add_argument("--intervalo", choices=list(INTERVALO))
    ap.add_argument("--semente", type=int)
    ap.add_argument("--laco", action="store_true", help="o som é um laço (só documenta: amb_ já fecha o laço)")
    a = ap.parse_args()
    saida = Path(a.saida).resolve()
    todos = receitas()
    ids = [i for i in todos if not a.so or fnmatch.fnmatch(i, a.so)]
    if a.so and not ids:
        print(f"nenhum som casa com {a.so}", file=sys.stderr)
        return 2
    if a.conferir:
        return conferir(saida)
    if a.lista:
        for i in ids:
            s = todos[i]
            print(f"{i:24} {s.familia:12} {s.ms:6} ms {s.pico_db:5} dBFS  --fita {s.modo}")
        return 0
    if a.marcar:
        return marcar(saida, set(ids))
    saida.mkdir(parents=True, exist_ok=True)
    (saida / ".gdignore").touch()
    for i in ids:
        s = todos[i]
        if len(ids) == 1:  # a receita do mapa pode afinar um som só
            s.modo = a.fita or s.modo
            s.lugar = a.lugar or s.lugar
            s.intervalo = a.intervalo or s.intervalo
            s.semente = s.semente if a.semente is None else a.semente
        wav = saida / f"{i}.wav"
        escrever_wav(wav, gerar(s))
        ogg = "" if a.sem_ogg else (" + ogg" if escrever_ogg(wav) else " (sem ffmpeg: só wav)")
        m = medir(wav)
        print(f"{i:24} {m['ms']:7.1f} ms  pico {m['pico_db']:6.2f} dBFS{ogg}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
