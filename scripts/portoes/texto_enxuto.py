#!/usr/bin/env python3
"""O texto enxuto: o código mudado não tem comentário, e a docstring longa só diminui.

Uso: python3 scripts/portoes/texto_enxuto.py [--mudados | --catraca [--aceitar] | --aplicar ARQ...] [--raiz DIR]
  --mudados   os arquivos mudados desde o main (e os novos): comentário e docstring longa nova
  --catraca   as linhas de docstring acima de 10 linhas, por arquivo, só descem (texto_enxuto.json)
  --aplicar   os arquivos dados, como o gancho do editor chama; aponta o que falta, não corta
Sai 0 limpo, 1 com achado, 2 sem o portão ou sem a base do git.
"""

from __future__ import annotations

import argparse
import ast
import importlib.util
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[1]
LIMITE = 10
CADERNO = Path("scripts/portoes/texto_enxuto.json")
REFS_DA_BASE = ("main", "origin/main")
TETO_DA_SAIDA = 40
AJUDA = {
    "comentário": "o código não tem comentário (ADR-010): o porquê vai a docs/o-porque-dos-modulos.md, a diretiva "
                  "fica nua",
    "docstring": f"a docstring passa de {LIMITE} linhas: corte o que repete o código",
}


class SemBase(Exception):
    """Falta o portão ou a base do git: o portão não conferiu."""


def _portao() -> ModuleType:
    caminho = AQUI / "codigo_sem_comentario.py"
    spec = importlib.util.spec_from_file_location("codigo_sem_comentario", caminho)
    if spec is None or spec.loader is None:
        raise SemBase(f"sem o portão {caminho}")
    modulo = importlib.util.module_from_spec(spec)
    sys.modules.setdefault(spec.name, modulo)
    spec.loader.exec_module(modulo)
    return modulo


@dataclass(frozen=True)
class Achado:
    arquivo: str
    linha: int
    regua: str
    conserto: str

    def __str__(self) -> str:
        return f"{self.arquivo}:{self.linha} [{self.regua}] {self.conserto}"


def docstrings_longas(fonte: str) -> list[tuple[str, int, int]]:
    """``(nome, linhas, linha do nome)`` de cada docstring acima de ``LIMITE``."""
    try:
        arvore = ast.parse(fonte)
    except SyntaxError:
        return []
    saida = []
    for no in ast.walk(arvore):
        if isinstance(no, ast.Module | ast.ClassDef | ast.FunctionDef | ast.AsyncFunctionDef):
            doc = ast.get_docstring(no, clean=False)
            if doc is not None and len(doc.splitlines()) > LIMITE:
                saida.append((getattr(no, "name", "<módulo>"), len(doc.splitlines()), getattr(no, "lineno", 1)))
    return saida


def _git(raiz: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", "-C", str(raiz), *args], capture_output=True, text=True, check=False)


def no_head(raiz: Path, rel: str) -> str:
    feito = _git(raiz, "show", f"HEAD:{rel}")
    return feito.stdout if feito.returncode == 0 else ""


def examinar(g: ModuleType, raiz: Path, rel: str, texto: str) -> list[Achado]:
    tipo = g.tipo_do_arquivo(rel, texto.split("\n", 1)[0])
    if tipo is None:
        return []
    achados = [Achado(rel, a.linha, "comentário", AJUDA["comentário"]) for a in g.achados_do_texto(texto, tipo, rel)]
    if tipo != "py":
        return achados
    agora = docstrings_longas(texto)
    antes = [(n, k) for n, k, _ in docstrings_longas(no_head(raiz, rel))]
    if sum(k for _, k, _ in agora) <= sum(k for _, k in antes):
        return achados
    for nome, k, linha in agora:
        if (nome, k) in antes:
            antes.remove((nome, k))
            continue
        achados.append(Achado(rel, linha, "docstring", f"`{nome}` tem {k} linhas: {AJUDA['docstring']}"))
    return achados


def mudados(raiz: Path) -> list[str]:
    for ref in REFS_DA_BASE:
        base = _git(raiz, "merge-base", ref, "HEAD")
        if base.returncode == 0 and base.stdout.strip():
            break
    else:
        raise SemBase("sem base: nem `main` nem `origin/main` alcançável deste HEAD (no CI, `fetch-depth: 0`)")
    feito = _git(raiz, "diff", "--name-only", "--diff-filter=ACMR", "-z", base.stdout.strip())
    novos = _git(raiz, "ls-files", "-z", "--others", "--exclude-standard")
    return sorted({r for r in (feito.stdout + novos.stdout).split("\0") if r})


def relativos(raiz: Path, pedidos: list[str]) -> list[str]:
    saida = []
    for p in pedidos:
        caminho = Path(p)
        caminho = (caminho if caminho.is_absolute() else Path.cwd() / caminho).resolve()
        try:
            rel = caminho.relative_to(raiz).as_posix()
        except ValueError:
            continue
        if caminho.is_file():
            saida.append(rel)
    return saida


def rodar(g: ModuleType, raiz: Path, arquivos: list[str], aplicar: bool) -> int:
    achados: list[Achado] = []
    for rel in arquivos:
        try:
            texto = (raiz / rel).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if not rel.startswith(g.FORA):
            achados += examinar(g, raiz, rel, texto)
    if aplicar:
        if not achados:
            return 0
        print(f"texto enxuto: corrigi 0 arquivo(s); restam {len(achados)} achado(s)")
    elif not achados:
        print(f"texto enxuto: 0 achados em {len(arquivos)} arquivo(s) mudado(s)")
        return 0
    else:
        print(f"texto enxuto: {len(achados)} achado(s) em {len({a.arquivo for a in achados})} arquivo(s)")
    for a in achados[:TETO_DA_SAIDA]:
        print(a)
    if len(achados) > TETO_DA_SAIDA:
        print(f"(e mais {len(achados) - TETO_DA_SAIDA})")
    return 1


def volume(g: ModuleType, raiz: Path) -> dict[str, int]:
    conta = {}
    for rel, tipo in g.alvos(raiz):
        if tipo != "py":
            continue
        k = sum(n for _, n, _ in docstrings_longas((raiz / rel).read_text(encoding="utf-8")))
        if k:
            conta[rel] = k
    return conta


def catraca(g: ModuleType, raiz: Path, aceitar: bool) -> int:
    agora = volume(g, raiz)
    try:
        piso = dict(json.loads((raiz / CADERNO).read_text(encoding="utf-8"))["piso"])
    except (OSError, ValueError, KeyError) as erro:
        raise SemBase(f"não li o piso em {CADERNO}: {erro}") from None
    subiram = sorted((f, n, piso.get(f, 0)) for f, n in agora.items() if n > piso.get(f, 0))
    total, total_piso = sum(agora.values()), sum(piso.values())
    for f, n, p in subiram:
        print(f"FAIL texto enxuto: {f}: {p} -> {n} linha(s) de docstring acima de {LIMITE} linhas")
    if subiram:
        print(f"texto enxuto: a docstring longa cresceu em {len(subiram)} arquivo(s): corte o que repete o código")
        return 1
    if aceitar:
        (raiz / CADERNO).write_text(json.dumps({"piso": dict(sorted(agora.items()))}, ensure_ascii=False, indent=1)
                                    + "\n", encoding="utf-8")
        print(f"texto enxuto: piso gravado ({total_piso} -> {total})")
        return 0
    desceu = f"; desceu de {total_piso}: grave com `--catraca --aceitar`" if total < total_piso else ""
    print(f"texto enxuto: {total} linha(s) de docstring longa, nenhum arquivo acima do piso{desceu}")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="portoes/texto_enxuto", description=(__doc__ or "").split("\n", 1)[0])
    p.add_argument("arquivos", nargs="*")
    p.add_argument("--raiz", default=None)
    modo = p.add_mutually_exclusive_group()
    modo.add_argument("--mudados", action="store_true")
    modo.add_argument("--catraca", action="store_true")
    modo.add_argument("--aplicar", action="store_true")
    p.add_argument("--aceitar", action="store_true")
    a = p.parse_args(argv)
    raiz = Path(a.raiz).resolve() if a.raiz else RAIZ
    try:
        g = _portao()
        if a.catraca:
            return catraca(g, raiz, a.aceitar)
        if a.aplicar:
            return rodar(g, raiz, relativos(raiz, a.arquivos), aplicar=True)
        return rodar(g, raiz, relativos(raiz, a.arquivos) if a.arquivos else mudados(raiz), aplicar=False)
    except SemBase as erro:
        print(f"ERRO texto enxuto: {erro}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
