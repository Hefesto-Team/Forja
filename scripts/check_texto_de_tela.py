#!/usr/bin/env python3
"""O portão do texto de tela (docs/jogo/06, a voz do texto): toda frase da
tabela de traduções começa com maiúscula, em português e em inglês."""
import pathlib, re, sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
src = (RAIZ / "godot/scripts/traducoes.gd").read_text(encoding="utf-8")
en = src[src.index("const EN := {"):src.index("const EN_PADROES")]
pad = src[src.index("const EN_PADROES"):]
pares = re.findall(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"', en, re.M)
padroes = re.findall(r'^\s*\["((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\]', pad, re.M)


def minuscula(s: str) -> bool:
    for c in s:
        if c.isdigit() or c in "$(\\[":
            return False  # número, grupo ou referência: não se julga
        if c.isalpha():
            return not c.isupper()
    return False


falhas = [f"{k!r} → {v!r}" for k, v in pares if minuscula(k) or minuscula(v)]
falhas += [f"{p!r} → {v!r}" for p, v in padroes if minuscula(p.lstrip("^")) or minuscula(v)]
chaves = [k for k, _ in pares]
falhas += [f"{k!r} repetida na tabela (o Godot não carrega)" for k in sorted(set(chaves)) if chaves.count(k) > 1]
for f in falhas:
    print("FAIL texto de tela com minúscula:", f)
print(f"texto de tela: {len(pares)} frases e {len(padroes)} padrões, {len(falhas)} com minúscula")
sys.exit(1 if falhas else 0)
