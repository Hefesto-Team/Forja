#!/usr/bin/env python3
"""O cabeçalho de uma entrada do devlog (entrada.md): chave: valor entre dois `---`.

Uso:
  cabecalho.py ler ARQ CHAVE          imprime o valor (vazio se não houver)
  cabecalho.py gravar ARQ CHAVE=VAL…  grava ou troca as chaves, antes do `---` de baixo
"""
import re
import sys
from pathlib import Path

CHAVES = ("titulo", "data", "ramo", "base", "topo", "fichas")
OPCIONAIS = ("so_antes", "so_depois", "iguais")


def separar(texto: str):
    """(linhas do cabeçalho, corpo); cabeçalho None se o arquivo não abre com `---`."""
    linhas = texto.split("\n")
    if not linhas or linhas[0].strip() != "---":
        return None, texto
    for i in range(1, len(linhas)):
        if linhas[i].strip() == "---":
            return linhas[1:i], "\n".join(linhas[i + 1:])
    return None, texto


def ler(caminho) -> tuple:
    """(dict do cabeçalho, corpo). Dict vazio se o cabeçalho não existe."""
    texto = Path(caminho).read_text(encoding="utf-8")
    cab, corpo = separar(texto)
    campos = {}
    for linha in cab or []:
        m = re.match(r"^([a-z_]+):\s*(.*?)\s*$", linha)
        if m:
            campos[m.group(1)] = m.group(2)
    return campos, corpo


def linhas_do_resumo(corpo: str) -> list:
    return [x for x in corpo.split("\n") if x.strip()]


def gravar(caminho, novos: dict) -> None:
    p = Path(caminho)
    cab, corpo = separar(p.read_text(encoding="utf-8"))
    cab = list(cab or [])
    for chave, valor in novos.items():
        linha = f"{chave}: {valor}".rstrip()
        for i, antiga in enumerate(cab):
            if re.match(rf"^{re.escape(chave)}:", antiga):
                cab[i] = linha
                break
        else:
            cab.append(linha)
    p.write_text("---\n" + "\n".join(cab) + "\n---\n" + corpo.lstrip("\n"), encoding="utf-8")


def main(argv) -> int:
    if len(argv) >= 4 and argv[1] == "ler":
        print(ler(argv[2])[0].get(argv[3], ""))
        return 0
    if len(argv) >= 4 and argv[1] == "gravar":
        novos = dict(a.split("=", 1) for a in argv[3:] if "=" in a)
        gravar(argv[2], novos)
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
