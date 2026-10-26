#!/usr/bin/env python3
"""Tira o comentário do código, arquivo por arquivo, e só grava o que provou (ADR-010).

O que é comentário diz o portão (``scripts/portoes/codigo_sem_comentario.py``). A prova usa outro leitor:
o ``ast`` no Python, o ``bash -n`` e o ``declare -f`` no shell, o ``tokenize`` do Python no GDScript, o
``gcc -fpreprocessed -E`` no C, no C++ e no gdshader, o TypeScript no JS e o ``html.parser`` no HTML.

Uso: python3 scripts/tirar_os_comentarios.py [ARQ...] [--provar | --aplicar] [--raiz DIR]
     sem modo, a conta por tipo
"""

from __future__ import annotations

import argparse
import ast
import collections
import html.parser
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tokenize
from collections.abc import Callable
from pathlib import Path
from types import ModuleType

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
APAGADA = "\0apagada\0"
MARCA = "\x01"
TYPESCRIPT = (
    Path("/usr/share/code/resources/app/extensions/node_modules/typescript"),
    Path("/usr/lib/node_modules/typescript"),
)


def _portao() -> ModuleType:
    caminho = AQUI / "portoes" / "codigo_sem_comentario.py"
    spec = importlib.util.spec_from_file_location("codigo_sem_comentario", caminho)
    if spec is None or spec.loader is None:
        raise SystemExit(f"o portão não carrega: {caminho}")
    modulo = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = modulo
    spec.loader.exec_module(modulo)
    return modulo


G = _portao()


def limpar(texto: str, tipo: str) -> tuple[str, int, int]:
    """``(texto sem comentário, comentários que saíram, diretivas que ficaram)``."""
    if MARCA in texto:
        raise ValueError("o texto já tem o caractere que marca o corte")
    trocas: list[tuple[int, int, str]] = []
    saiu = ficou = 0
    for c in G.comentarios(texto, tipo):
        forma = G.forma_da_diretiva(c, tipo)
        quebras = c.texto.count("\n")
        if forma is None:
            saiu += 1
            trocas.append((c.inicio, c.fim, "\n".join([MARCA] * (quebras + 1))))
        else:
            ficou += 1
            if forma != c.texto:
                trocas.append((c.inicio, c.fim, forma + ("\n" + MARCA) * quebras))
    if not trocas:
        return texto, saiu, ficou
    novo = texto
    for ini, fim, troca in sorted(trocas, reverse=True):
        novo = novo[:ini] + troca + novo[fim:]
    linhas = []
    for linha in novo.split("\n"):
        if MARCA not in linha:
            linhas.append(linha)
        elif not linha.replace(MARCA, "").strip():
            linhas.append(APAGADA)
        else:
            linhas.append(_arrumar(linha))
    return _juntar_brancas("\n".join(linhas), texto.endswith("\n")), saiu, ficou


def _arrumar(linha: str) -> str:
    """A linha que perdeu um comentário e guarda código: sem o espaço que ele deixa."""
    partes = linha.split(MARCA)
    texto = partes[0]
    for resto in partes[1:]:
        if not texto.strip():
            texto += resto.lstrip(" \t")
        elif not resto.strip():
            texto = texto.rstrip(" \t") + resto.strip(" \t")
        elif texto.endswith((" ", "\t")) and resto.startswith((" ", "\t")):
            texto += resto.lstrip(" \t")
        elif not texto.endswith((" ", "\t")) and not resto.startswith((" ", "\t")):
            texto += " " + resto
        else:
            texto += resto
    return texto.rstrip(" \t") if partes[-1].strip() == "" else texto


def _juntar_brancas(novo: str, termina_em_quebra: bool) -> str:
    """Cada bloco de linhas apagadas e brancas vira o maior trecho branco que havia nele."""
    linhas = novo.split("\n")
    saida: list[str] = []
    i = 0
    while i < len(linhas):
        if linhas[i] != APAGADA and not (linhas[i].strip() == "" and _toca_apagada(linhas, i)):
            saida.append(linhas[i])
            i += 1
            continue
        j = i
        maior = corrida = 0
        while j < len(linhas) and (linhas[j] == APAGADA or linhas[j].strip() == ""):
            if linhas[j] == APAGADA:
                corrida = 0
            else:
                corrida += 1
                maior = max(maior, corrida)
            j += 1
        if not any(linha == APAGADA for linha in linhas[i:j]):
            saida.extend(linhas[i:j])
        elif i != 0 and j != len(linhas):
            saida.extend([""] * maior)
        i = j
    texto = "\n".join(saida)
    if termina_em_quebra and texto and not texto.endswith("\n"):
        texto += "\n"
    return texto


def _toca_apagada(linhas: list[str], i: int) -> bool:
    j = i
    while j < len(linhas) and linhas[j].strip() == "" and linhas[j] != APAGADA:
        j += 1
    return j < len(linhas) and linhas[j] == APAGADA


class ProvaFalhou(Exception):
    """A prova do arquivo não fechou: ele não se grava."""


def prova_py(antes: str, depois: str, _rel: str) -> None:
    if ast.dump(ast.parse(antes)) != ast.dump(ast.parse(depois)):
        raise ProvaFalhou("o ast.dump mudou")


def _bash_canonico(texto: str) -> str:
    embrulho = "__arquivo_inteiro__() {\n" + texto + ("" if texto.endswith("\n") else "\n") + "}\n"
    feito = subprocess.run(
        ["bash", "--norc", "--noprofile", "-c", 'eval "$(cat)" && declare -f __arquivo_inteiro__'],
        input=embrulho, env={"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "LC_ALL": "C"},
        capture_output=True, text=True, check=False, timeout=60,
    )
    if feito.returncode != 0:
        raise ProvaFalhou(f"o bash não leu o arquivo embrulhado: {feito.stderr.strip()[:200]}")
    return feito.stdout


def prova_sh(antes: str, depois: str, _rel: str) -> None:
    feito = subprocess.run(["bash", "-n"], input=depois, capture_output=True, text=True, check=False, timeout=60)
    if feito.returncode != 0:
        raise ProvaFalhou(f"bash -n: {feito.stderr.strip()[:200]}")
    if _bash_canonico(antes) != _bash_canonico(depois):
        raise ProvaFalhou("o corpo que o bash imprime mudou")


_FORA_DO_FLUXO = {tokenize.COMMENT, tokenize.NL}


def _tokens_gd(texto: str) -> list[tuple[int, str]]:
    return [(t.type, t.string) for t in tokenize.generate_tokens(io.StringIO(texto).readline)
            if t.type not in _FORA_DO_FLUXO]


def prova_gd(antes: str, depois: str, _rel: str) -> None:
    if _tokens_gd(antes) != _tokens_gd(depois):
        raise ProvaFalhou("o fluxo de tokens do GDScript mudou")


_TOKEN_C = re.compile(r"""[A-Za-z_]\w*|\d[\w.]*|"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*'|\S""")


def _gcc_canonico(texto: str, rel: str) -> str:
    lingua = "c++" if rel.endswith((".cpp", ".hpp")) or rel.startswith("nativo/godot/") else "c"
    feito = subprocess.run(["gcc", "-fpreprocessed", "-dD", "-E", "-P", "-w", "-x", lingua, "-"],
                           input=texto, capture_output=True, text=True, check=False, timeout=60)
    if feito.returncode != 0:
        raise ProvaFalhou(f"o gcc não leu o arquivo: {feito.stderr.strip()[:200]}")
    return " ".join(_TOKEN_C.findall(feito.stdout))


def prova_c(antes: str, depois: str, rel: str) -> None:
    if _gcc_canonico(antes, rel) != _gcc_canonico(depois, rel):
        raise ProvaFalhou("o que o gcc lê sem comentário mudou")


def _typescript() -> Path | None:
    for pasta in TYPESCRIPT:
        if (pasta / "lib" / "typescript.js").is_file():
            return pasta
    return None


_IMPRESSOR_TS = r"""
const ts = require(process.argv[1]);
const entrada = JSON.parse(require("fs").readFileSync(0, "utf8"));
const impressor = ts.createPrinter({removeComments: true});
const saida = entrada.map((programa) => {
  const fonte = ts.createSourceFile("x.js", programa, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
  if (fonte.parseDiagnostics && fonte.parseDiagnostics.length) {
    return "ERRO: " + ts.flattenDiagnosticMessageText(fonte.parseDiagnostics[0].messageText, "\n");
  }
  return impressor.printFile(fonte);
});
process.stdout.write(JSON.stringify(saida));
"""


def _sem_trechos(texto: str, trechos: list[tuple[int, int]]) -> str:
    partes, pos = [], 0
    for ini, fim in sorted(trechos):
        partes.append(texto[pos:ini])
        partes.append(" ")
        pos = fim
    partes.append(texto[pos:])
    return "".join(partes)


def js_canonico(codigos: list[str]) -> list[str]:
    """O programa de cada código, impresso pelo TypeScript sem comentário (ou os tokens, sem ele)."""
    ts = _typescript()
    node = shutil.which("node")
    if ts is None or node is None:
        return [" ".join(_sem_trechos(c, [(x.inicio, x.fim) for x in G.comentarios_js(c)]).split()) for c in codigos]
    feito = subprocess.run([node, "-e", _IMPRESSOR_TS, str(ts / "lib" / "typescript.js")],
                           input=json.dumps(codigos), capture_output=True, text=True, check=False, timeout=300)
    if feito.returncode != 0:
        raise ProvaFalhou(f"o impressor do TypeScript falhou: {feito.stderr.strip()[:300]}")
    return list(json.loads(feito.stdout))


def prova_js(antes: str, depois: str, _rel: str) -> None:
    a, b = js_canonico([antes, depois])
    if a.startswith("ERRO") or a != b:
        raise ProvaFalhou(a if a.startswith("ERRO") else "o programa JS mudou")


def tokens_css(codigo: str) -> str:
    sem = _sem_trechos(codigo, [(c.inicio, c.fim) for c in G.comentarios_css(codigo)])
    return " ".join(re.findall(r"""[\w\-#.%]+|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[^\s\w]""", sem))


class _Eventos(html.parser.HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.eventos: list[tuple[str, str]] = []
        self.scripts: list[str] = []
        self.estilos: list[str] = []
        self._bruto: str | None = None
        self._pre = 0

    def _texto(self, dado: str) -> None:
        if self.eventos and self.eventos[-1][0] == "texto":
            self.eventos[-1] = ("texto", self.eventos[-1][1] + dado)
        else:
            self.eventos.append(("texto", dado))

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.eventos.append(("abre", f"{tag} {attrs!r}"))
        if tag in ("script", "style"):
            self._bruto = tag
        if tag in ("pre", "textarea"):
            self._pre += 1

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.eventos.append(("abre-fecha", f"{tag} {attrs!r}"))

    def handle_endtag(self, tag: str) -> None:
        self.eventos.append(("fecha", tag))
        self._bruto = None
        if tag in ("pre", "textarea"):
            self._pre -= 1

    def handle_data(self, data: str) -> None:
        if self._bruto == "script":
            self.scripts.append(data)
            self.eventos.append(("script", ""))
        elif self._bruto == "style":
            self.estilos.append(data)
            self.eventos.append(("style", ""))
        elif self._pre:
            self._texto(data)
        else:
            self._texto(" " if not data.strip() else re.sub(r"\s+", " ", data))

    def handle_entityref(self, name: str) -> None:
        self._texto(f"&{name};")

    def handle_charref(self, name: str) -> None:
        self._texto(f"&#{name};")

    def handle_decl(self, decl: str) -> None:
        self.eventos.append(("decl", decl))

    def handle_pi(self, data: str) -> None:
        self.eventos.append(("pi", data))


def _eventos(texto: str) -> _Eventos:
    p = _Eventos()
    p.feed(texto)
    p.close()
    p.eventos = [(t, re.sub(r"\s+", " ", d) if t == "texto" else d) for t, d in p.eventos]
    return p


def _js_dos_scripts(texto: str) -> list[str]:
    saida = []
    for m in G.BRUTOS.finditer(texto):
        if m.group(1).lower() != "script":
            continue
        tipo = G.TIPO_DO_SCRIPT.search(m.group(2))
        if (tipo.group(1).lower() if tipo else "") not in G.SCRIPT_JS:
            continue
        fecho = re.compile(r"</script\s*>", re.I).search(texto, m.end())
        saida.append(texto[m.end():fecho.start() if fecho else len(texto)])
    return saida


def prova_html(antes: str, depois: str, _rel: str) -> None:
    a, b = _eventos(antes), _eventos(depois)
    if a.eventos != b.eventos:
        raise ProvaFalhou("os eventos do HTML mudaram")
    if [tokens_css(s) for s in a.estilos] != [tokens_css(s) for s in b.estilos]:
        raise ProvaFalhou("o CSS de um <style> mudou")
    ja, jb = _js_dos_scripts(antes), _js_dos_scripts(depois)
    if len(ja) != len(jb):
        raise ProvaFalhou("o número de <script> mudou")
    canon = js_canonico(ja + jb)
    for js_a, js_b in zip(canon[:len(ja)], canon[len(ja):], strict=True):
        if js_a.startswith("ERRO") or js_a != js_b:
            raise ProvaFalhou(js_a if js_a.startswith("ERRO") else "o JS de um <script> mudou")


PROVAS: dict[str, Callable[[str, str, str], None]] = {
    "py": prova_py,
    "sh": prova_sh,
    "gd": prova_gd,
    "c": prova_c,
    "js": prova_js,
    "html": prova_html,
}


def contar(arquivos: list[tuple[str, str]], raiz: Path) -> dict[str, collections.Counter[str]]:
    conta: dict[str, collections.Counter[str]] = collections.defaultdict(collections.Counter)
    for rel, tipo in arquivos:
        _, sai, fica = limpar((raiz / rel).read_text(encoding="utf-8"), tipo)
        conta[tipo]["sai"] += sai
        conta[tipo]["fica"] += fica
        conta[tipo]["arquivos"] += 1
    return conta


def aplicar(arquivos: list[tuple[str, str]], raiz: Path, gravar: bool) -> int:
    recusados = []
    gravados = 0
    for rel, tipo in arquivos:
        caminho = raiz / rel
        texto = caminho.read_text(encoding="utf-8")
        try:
            novo, _, _ = limpar(texto, tipo)
            if novo == texto:
                continue
            PROVAS[tipo](texto, novo, rel)
            resto = G.achados_do_texto(novo, tipo, rel)
            if resto:
                raise ProvaFalhou(f"sobrou comentário na linha {resto[0].linha}")
        except (ProvaFalhou, SyntaxError, ValueError, tokenize.TokenError) as erro:
            recusados.append(f"{rel}: {erro}")
            continue
        if gravar:
            caminho.write_text(novo, encoding="utf-8")
        gravados += 1
    print(f"{'gravados' if gravar else 'provados'}: {gravados}; recusados: {len(recusados)}")
    for r in recusados:
        print(f"  RECUSADO {r}")
    return 1 if recusados else 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=(__doc__ or "").split("\n", 1)[0])
    p.add_argument("arquivos", nargs="*")
    p.add_argument("--aplicar", action="store_true", help="grava o que provou")
    p.add_argument("--provar", action="store_true", help="prova sem gravar")
    p.add_argument("--raiz", default=None)
    a = p.parse_args(argv)
    raiz = Path(a.raiz).resolve() if a.raiz else RAIZ
    pedidos = None
    if a.arquivos:
        pedidos = []
        for bruto in a.arquivos:
            caminho = Path(bruto)
            caminho = (caminho if caminho.is_absolute() else Path.cwd() / caminho).resolve()
            pedidos.append(caminho.relative_to(raiz).as_posix())
    arquivos = G.alvos(raiz, pedidos)
    if a.aplicar or a.provar:
        return aplicar(arquivos, raiz, a.aplicar)
    for tipo, conta in sorted(contar(arquivos, raiz).items()):
        print(f"{tipo}: {conta['arquivos']} arquivo(s), {conta['sai']} comentário(s) que saem, "
              f"{conta['fica']} diretiva(s) que ficam")
    return 0


if __name__ == "__main__":
    sys.exit(main())
