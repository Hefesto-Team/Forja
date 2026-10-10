#!/usr/bin/env python3
"""Os seis ícones de botão que faltavam, do Input Prompts da Kenney (CC0).

Os glifos de `godot/assets/glifos/` vêm do app Hefesto e cobrem quase tudo; o
mudo e os gestos do touchpad faltavam (a G11). Este script exporta os seis do
SVG do PS5 com `rsvg-convert -w 128 -h 128`, em branco sobre transparente (o
jogo tinge), e confere o que saiu. Só o desenho do botão e do gesto: nenhum
logo, nenhuma versão Pixel ou 1-Bit.

  python3 scripts/glifos_do_kenney.py              exporta os seis (precisa do All-in-1 em oficina/kenney/)
  python3 scripts/glifos_do_kenney.py --conferir   confere os seis PNG do jogo: 128×128, todo pixel visível branco

Sem dependência fora da biblioteca padrão: o PNG se lê e se escreve aqui.
"""
import argparse
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
GLIFOS = RAIZ / "godot" / "assets" / "glifos"
LADO = 128

## o arquivo do jogo -> o SVG do Input Prompts (PlayStation Series/Vector)
SEIS = {
    "mudo": "playstation5_button_mute.svg",
    "touchpad_esquerda": "playstation5_touchpad_press_left.svg",
    "touchpad_direita": "playstation5_touchpad_press_right.svg",
    "touchpad_deslizar": "playstation5_touchpad_swipe_horizontal.svg",
    "touchpad_cima": "playstation5_touchpad_swipe_up.svg",
    "touchpad_baixo": "playstation5_touchpad_swipe_down.svg",
}


# ------------------------------------------------------------------ o PNG --

def ler_png(caminho):
    """(largura, altura, linhas RGBA) de um PNG de 8 bits por canal, RGBA ou RGB, sem entrelaçar."""
    dados = Path(caminho).read_bytes()
    if dados[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("%s não é PNG" % caminho)
    pos = 8
    idat = b""
    largura = altura = tipo = profundidade = entrelacado = None
    while pos < len(dados):
        n, = struct.unpack(">I", dados[pos:pos + 4])
        nome = dados[pos + 4:pos + 8]
        corpo = dados[pos + 8:pos + 8 + n]
        pos += 12 + n
        if nome == b"IHDR":
            largura, altura, profundidade, tipo, _, _, entrelacado = struct.unpack(">IIBBBBB", corpo)
        elif nome == b"IDAT":
            idat += corpo
        elif nome == b"IEND":
            break
    if profundidade != 8 or tipo not in (2, 6) or entrelacado:
        raise ValueError("%s: só PNG de 8 bits, RGB ou RGBA, sem entrelaçar (tipo %s, %s bits)" % (caminho, tipo, profundidade))
    canais = 4 if tipo == 6 else 3
    cru = zlib.decompress(idat)
    passo = largura * canais
    linhas = []
    antes = bytearray(passo)
    i = 0
    for _ in range(altura):
        filtro = cru[i]
        linha = bytearray(cru[i + 1:i + 1 + passo])
        i += 1 + passo
        for x in range(passo):
            a = linha[x - canais] if x >= canais else 0
            b = antes[x]
            c = antes[x - canais] if x >= canais else 0
            if filtro == 1:
                linha[x] = (linha[x] + a) & 0xFF
            elif filtro == 2:
                linha[x] = (linha[x] + b) & 0xFF
            elif filtro == 3:
                linha[x] = (linha[x] + (a + b) // 2) & 0xFF
            elif filtro == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                linha[x] = (linha[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 0xFF
        antes = linha
        if canais == 3:
            rgba = bytearray()
            for x in range(largura):
                rgba += linha[x * 3:x * 3 + 3] + b"\xff"
            linha = rgba
        linhas.append(bytes(linha))
    return largura, altura, linhas


def escrever_png(caminho, largura, altura, linhas):
    def bloco(nome, corpo):
        return struct.pack(">I", len(corpo)) + nome + corpo + struct.pack(">I", zlib.crc32(nome + corpo) & 0xFFFFFFFF)
    cru = b"".join(b"\x00" + linha for linha in linhas)
    Path(caminho).write_bytes(b"\x89PNG\r\n\x1a\n"
                              + bloco(b"IHDR", struct.pack(">IIBBBBB", largura, altura, 8, 6, 0, 0, 0))
                              + bloco(b"IDAT", zlib.compress(cru, 9))
                              + bloco(b"IEND", b""))


def em_branco(linhas):
    """Todo pixel com alfa > 0 vira branco (o jogo tinge); o alfa fica."""
    saida = []
    for linha in linhas:
        nova = bytearray(linha)
        for x in range(0, len(nova), 4):
            if nova[x + 3] > 0:
                nova[x:x + 3] = b"\xff\xff\xff"
            else:
                nova[x:x + 3] = b"\x00\x00\x00"
        saida.append(bytes(nova))
    return saida


def achados_de(caminho):
    """O que está errado num glifo do jogo (vazio: certo)."""
    if not caminho.is_file():
        return ["%s não existe" % caminho.name]
    try:
        largura, altura, linhas = ler_png(caminho)
    except ValueError as e:
        return [str(e)]
    erros = []
    if (largura, altura) != (LADO, LADO):
        erros.append("%s tem %d×%d, e não %d×%d" % (caminho.name, largura, altura, LADO, LADO))
    fora = visiveis = 0
    for linha in linhas:
        for x in range(0, len(linha), 4):
            if linha[x + 3] > 0:
                visiveis += 1
                if linha[x:x + 3] != b"\xff\xff\xff":
                    fora += 1
    if visiveis == 0:
        erros.append("%s está vazio" % caminho.name)
    if fora:
        erros.append("%s tem %d pixel(s) visível(is) fora do branco" % (caminho.name, fora))
    return erros


# ------------------------------------------------------------------ o export --

def exportar():
    sys.path.insert(0, str(RAIZ / "scripts"))
    from kenney import pasta_do_pacote
    vetor = pasta_do_pacote() / "Icons" / "Input Prompts" / "PlayStation Series" / "Vector"
    if not vetor.is_dir():
        raise SystemExit("não achei o Input Prompts em %s" % vetor)
    with tempfile.TemporaryDirectory() as tmp:
        for nome, svg in SEIS.items():
            origem = vetor / svg
            if not origem.is_file():
                raise SystemExit("falta %s" % origem)
            bruto = Path(tmp) / (nome + ".png")
            subprocess.run(["rsvg-convert", "-w", str(LADO), "-h", str(LADO), "-o", str(bruto), str(origem)], check=True)
            largura, altura, linhas = ler_png(bruto)
            if (largura, altura) != (LADO, LADO):
                raise SystemExit("%s saiu com %d×%d" % (svg, largura, altura))
            escrever_png(GLIFOS / (nome + ".png"), largura, altura, em_branco(linhas))
            print("ok   %s.png  <-  %s" % (nome, svg))


def conferir():
    erros = []
    for nome in SEIS:
        erros += achados_de(GLIFOS / (nome + ".png"))
    for e in erros:
        print("FAIL", e)
    if erros:
        return 1
    print("glifos do Kenney ok — os seis com %d×%d, todo pixel visível em branco" % (LADO, LADO))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--conferir", action="store_true", help="só confere os seis PNG do jogo")
    args = ap.parse_args()
    if not args.conferir:
        exportar()
    return conferir()


if __name__ == "__main__":
    sys.exit(main())
