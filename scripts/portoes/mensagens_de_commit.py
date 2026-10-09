#!/usr/bin/env python3
"""O portão das mensagens de commit: a mensagem é texto de gente, sem símbolo
de botão, seta, marca de conferido nem emoji, e sem trailer de coautoria.

Confere só os commits novos (o histórico antigo tem símbolos e não se
reescreve). O intervalo, em ordem de preferência:

  --intervalo A..B          o que for pedido;
  BASE_DO_PR=<ramo>         num pull request: origin/<ramo>..HEAD;
  ANTES=<sha>               num push: <sha>..HEAD (o `github.event.before`;
                            zeros = ramo novo, cai no próximo);
  o resto                   merge-base(HEAD, origin/main ou main)..HEAD.

Intervalo vazio passa. Modo: reprova (é portão da base).

Uso: python3 scripts/portoes/mensagens_de_commit.py [--raiz DIR] [--intervalo A..B] [--modo aviso|reprova]
"""
import os
import re
import subprocess
import sys
import unicodedata

import comum

# As faixas de símbolo: setas, técnico (⏎ ⌘), formas (▶ ◀ ▼ △ □ ○), símbolos
# diversos e dingbats (✕ ✓ ✗ ★), e os planos de emoji. O travessão, as aspas
# angulares e o ponto médio são pontuação e passam.
FAIXAS = [
    (0x2190, 0x21FF), (0x2300, 0x23FF), (0x25A0, 0x25FF), (0x2600, 0x26FF), (0x2700, 0x27BF),
    (0x2B00, 0x2BFF), (0x1F000, 0x1FAFF), (0xFE0F, 0xFE0F), (0x200D, 0x200D),
]
TRAILER = re.compile(r"^\s*[c]o-authored-by\s*:", re.I | re.M)


def simbolo(c: str) -> bool:
    o = ord(c)
    return any(a <= o <= b for a, b in FAIXAS)


def git(raiz, *args, ok_falha=False):
    p = subprocess.run(["git", "-C", str(raiz), *args], capture_output=True, text=True)
    if p.returncode != 0 and not ok_falha:
        raise RuntimeError(p.stderr.strip() or f"git {' '.join(args)} falhou")
    return p.stdout.strip() if p.returncode == 0 else None


def existe(raiz, ref) -> bool:
    return git(raiz, "rev-parse", "--verify", "--quiet", ref + "^{commit}", ok_falha=True) is not None


def intervalo(raiz, pedido: str) -> str:
    if pedido:
        return pedido
    base = os.environ.get("BASE_DO_PR", "").strip()
    if base and existe(raiz, f"origin/{base}"):
        return f"origin/{base}..HEAD"
    antes = os.environ.get("ANTES", "").strip()
    if antes and set(antes) != {"0"} and existe(raiz, antes):
        return f"{antes}..HEAD"
    for principal in ("origin/main", "main"):
        if existe(raiz, principal):
            mb = git(raiz, "merge-base", "HEAD", principal, ok_falha=True)
            if mb:
                return f"{mb}..HEAD"
    return ""


def main() -> int:
    a = comum.argumentos("mensagens_de_commit", "As mensagens dos commits novos, sem símbolo e sem trailer.",
                         com_regras=False,
                         extra=lambda ap: ap.add_argument("--intervalo", default="", help="A..B (padrão: o que o CI diz)"))
    rel = comum.Relato("mensagens", a.modo or "reprova")
    try:
        faixa = intervalo(a.raiz, a.intervalo)
        if not faixa:
            return rel.fechar("sem intervalo para conferir")
        shas = (git(a.raiz, "rev-list", "--no-merges", faixa) or "").split()
    except RuntimeError as e:
        print(f"mensagens: não li o git: {e}", file=sys.stderr)
        return 2
    for sha in shas:
        msg = git(a.raiz, "log", "-1", "--format=%B", sha) or ""
        curto = sha[:9]
        vistos = sorted({c for c in msg if simbolo(c)})
        if vistos:
            nomes = ", ".join(f"U+{ord(c):04X} {unicodedata.name(c, '?').lower()}" for c in vistos)
            rel.achou(curto, 0, f"símbolo na mensagem: {nomes} (escreva o nome do botão: «o botão Cruz»)")
        if TRAILER.search(msg):
            rel.achou(curto, 0, "trailer de coautoria na mensagem")
    return rel.fechar(f"{len(shas)} commits em {faixa}")


if __name__ == "__main__":
    sys.exit(main())
