#!/usr/bin/env python3
"""O «Ler antes» de uma ficha, só o que ele manda ler.

Para cada link da seção «Ler antes» da ficha, imprime só a seção da âncora (do
título até o próximo título do mesmo nível ou maior, fora dos blocos de
código), ou o arquivo inteiro quando o link não tem âncora. Cada parte vem com
o cabeçalho «== caminho#âncora (N caracteres) ==».

A âncora é a do GitHub: minúsculas, sem pontuação, o espaço vira hífen; as
letras acentuadas ficam, e o travessão some deixando dois hífens
(«O kit do minigame — H04» vira «o-kit-do-minigame--h04»). O título repetido
ganha «-1», «-2». O portão da ficha pronta (scripts/portoes/ficha_pronta.py)
usa estas mesmas funções.

Sai 1 quando uma âncora não casa ou o arquivo não existe (com o nome do link);
2 quando a ficha não se lê ou não tem «Ler antes».

Uso: python3 scripts/ler_antes.py <ficha.md>
     python3 scripts/ler_antes.py --medir <ficha.md>...   (o total de cada ficha e a mediana)
"""
import re
import statistics
import sys
from pathlib import Path

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
TITULO = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
CERCA = re.compile(r"^\s*(```|~~~)")


def ancora(titulo: str) -> str:
    """A âncora que o GitHub dá a um título (sem o sufixo de repetição)."""
    texto = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", titulo)   # o link vale pelo texto
    texto = texto.strip().lower()
    texto = re.sub(r"[^\w\- ]", "", texto)                   # \w do Python já guarda o acento
    return texto.replace(" ", "-")


def titulos(texto: str):
    """[(nível, âncora, n.º da linha)] dos títulos fora dos blocos de código, com o sufixo do repetido."""
    achou, vistos, dentro = [], {}, False
    for n, linha in enumerate(texto.splitlines()):
        if CERCA.match(linha):
            dentro = not dentro
            continue
        if dentro:
            continue
        m = TITULO.match(linha)
        if not m:
            continue
        base = ancora(m.group(2))
        vezes = vistos.get(base, 0)
        vistos[base] = vezes + 1
        achou.append((len(m.group(1)), base if vezes == 0 else f"{base}-{vezes}", n))
    return achou


def secao(texto: str, alvo: str):
    """O texto da seção da âncora `alvo`, ou None quando ela não existe."""
    alvo = alvo.lower()
    linhas = texto.splitlines()
    lista = titulos(texto)
    for i, (nivel, anc, n) in enumerate(lista):
        if anc != alvo:
            continue
        fim = len(linhas)
        for nivel2, _, n2 in lista[i + 1:]:
            if nivel2 <= nivel:
                fim = n2
                break
        return "\n".join(linhas[n:fim]).rstrip() + "\n"
    return None


def corpo_do_ler_antes(texto: str):
    """O corpo da seção «Ler antes» da ficha (até o próximo `## `), ou None."""
    dentro, corpo = False, []
    for linha in texto.splitlines():
        if linha.startswith("## "):
            if dentro:
                break
            dentro = linha[3:].strip().lower() == "ler antes"
            continue
        if dentro:
            corpo.append(linha)
    return "\n".join(corpo) if dentro or corpo else None


def links(texto: str):
    """Os links relativos do «Ler antes» (o endereço da rede não conta)."""
    corpo = corpo_do_ler_antes(texto)
    if corpo is None:
        return None
    return [ln for ln in LINK.findall(corpo) if "://" not in ln and not ln.startswith("mailto:")]


def resolver(ficha: Path, link: str):
    """(caminho, âncora ou "") de um link relativo à pasta da ficha."""
    caminho, _, anc = link.partition("#")
    alvo = (ficha.parent / caminho) if caminho else ficha
    return alvo, anc


def partes(ficha: Path):
    """[(link, caminho, âncora, texto ou None)] do «Ler antes»; None no texto é o que não casou."""
    lista = links(ficha.read_text(encoding="utf-8"))
    if lista is None:
        return None
    saida = []
    for ln in lista:
        alvo, anc = resolver(ficha, ln)
        if not alvo.is_file():
            saida.append((ln, alvo, anc, None))
            continue
        texto = alvo.read_text(encoding="utf-8")
        saida.append((ln, alvo, anc, secao(texto, anc) if anc else texto))
    return saida


def main(argv) -> int:
    medir = "--medir" in argv
    fichas = [Path(a) for a in argv if a != "--medir"]
    if not fichas or any(a.startswith("-") and a != "--medir" for a in argv):
        print(__doc__.strip().splitlines()[-2].strip(), file=sys.stderr)
        return 2
    rc, totais = 0, []
    for ficha in fichas:
        try:
            lista = partes(ficha)
        except OSError as e:
            print(f"ler antes: não li {e.filename}", file=sys.stderr)
            return 2
        if lista is None:
            print(f"ler antes: {ficha} não tem a seção «Ler antes»", file=sys.stderr)
            return 2
        total = 0
        for ln, alvo, anc, texto in lista:
            if texto is None:
                falta = "o arquivo não existe" if not alvo.is_file() else f"a âncora #{anc} não casa com título nenhum"
                print(f"ler antes: {ficha.name}: o link {ln}: {falta}", file=sys.stderr)
                rc = 1
                continue
            total += len(texto)
            if not medir:
                nome = alvo.resolve().relative_to(Path.cwd().resolve()) if alvo.resolve().is_relative_to(
                    Path.cwd().resolve()) else alvo
                print(f"== {nome}{'#' + anc if anc else ''} ({len(texto)} caracteres) ==")
                print(texto.rstrip())
                print()
        totais.append(total)
        if medir:
            print(f"{total:>7} caracteres  {ficha.name}")
    if medir and totais:
        print(f"mediana: {int(statistics.median(totais))} caracteres em {len(totais)} fichas")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
