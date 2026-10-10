#!/usr/bin/env python3
"""Copia as tabelas do cavaleiro do designer de sistemas para o jogo (G13).

O jogo lê os stats, as peças, os itens, os arquétipos, os nomes e as regras de
`godot/dados/`, cópias idênticas de `docs/jogo/sistemas/`: nenhum número de
stat mora no código. Rode depois de mudar um CSV da pasta de sistemas:

    python3 scripts/dados_do_cavaleiro.py            copia
    python3 scripts/dados_do_cavaleiro.py --conferir sai com 1 se alguma cópia difere

Só a biblioteca padrão.
"""
import filecmp
import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGEM = os.path.join(RAIZ, "docs", "jogo", "sistemas")
DESTINO = os.path.join(RAIZ, "godot", "dados")
TABELAS = ["pecas", "itens", "stats", "arquetipos", "nomes", "regras"]


def main() -> int:
    conferir = "--conferir" in sys.argv[1:]
    diferentes = []
    os.makedirs(DESTINO, exist_ok=True)
    for t in TABELAS:
        de = os.path.join(ORIGEM, t + ".csv")
        para = os.path.join(DESTINO, t + ".csv")
        igual = os.path.exists(para) and filecmp.cmp(de, para, shallow=False)
        if conferir:
            if not igual:
                diferentes.append(t)
            continue
        if not igual:
            shutil.copyfile(de, para)
            print(f"copiado: {t}.csv")
    if diferentes:
        print("as cópias do jogo diferem dos sistemas: " + ", ".join(diferentes)
              + " (rode python3 scripts/dados_do_cavaleiro.py)")
        return 1
    print(f"os dados do cavaleiro: {len(TABELAS)} tabelas iguais em godot/dados/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
