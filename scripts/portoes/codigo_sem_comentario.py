#!/usr/bin/env python3
"""O portão do código sem comentário (ADR-010): só a diretiva que uma ferramenta lê fica, nua.

Cada linguagem é lida pelo analisador dela, nunca por ``grep``. A docstring do Python fica.

Uso: python3 scripts/portoes/codigo_sem_comentario.py [ARQ...] [--raiz DIR] [--modo aviso|reprova]
     [--lista] [--diretivas] [--catraca [--aceitar]]
"""

from __future__ import annotations

import argparse
import io
import json
import re
import subprocess
import sys
import tokenize
from dataclasses import dataclass
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
SUFIXOS = {
    "py": "py", "sh": "sh", "gd": "gd", "c": "c", "h": "c", "cpp": "c", "hpp": "c",
    "gdshader": "c", "js": "js", "html": "html",
}
TIPOS = tuple(sorted(set(SUFIXOS.values())))
FORA = ("third_party/",)
CADERNO = Path("scripts/portoes/codigo_sem_comentario.json")
TETO_DA_SAIDA = 40


@dataclass(frozen=True)
class Diretiva:
    nome: str
    forma: re.Pattern[str]
    tipos: tuple[str, ...]
    leitor: str


def _d(nome: str, forma: str, tipos: tuple[str, ...], leitor: str) -> Diretiva:
    return Diretiva(nome, re.compile(forma), tipos, leitor)


_CODIGOS = r"[A-Z]+[0-9]+(?:\s*,\s*[A-Z]+[0-9]+)*"
DIRETIVAS: tuple[Diretiva, ...] = (
    _d("type", r"type:\s*ignore(?:\[[\w\-, ]+\])?", ("py",), "mypy"),
    _d("noqa", rf"noqa(?::\s*{_CODIGOS})?(?![\w-])", ("py",), "ruff"),
    _d("pragma", r"pragma:\s*no\s+(?:cover|branch)", ("py",), "coverage"),
    _d("shellcheck", r"shellcheck\s+(?:disable|enable|source|shell|external-sources)=\S+", ("sh",), "shellcheck"),
    _d("spdx", r"SPDX-[\w\-]+:\s*\S.*", TIPOS, "licença"),
    _d("eslint", r"eslint-(?:disable-next-line|disable-line|disable|enable)(?:\s+[\w/\-]+(?:,\s*[\w/\-]+)*)?",
       ("js", "html"), "eslint"),
    _d("ts", r"@ts-(?:check|nocheck|ignore|expect-error)", ("js", "html"), "tsc"),
)


@dataclass(frozen=True)
class Comentario:
    inicio: int
    fim: int
    texto: str
    linha: int
    abre: str


def _linha_de(texto: str, indice: int) -> int:
    return texto.count("\n", 0, indice) + 1


def _miolo(c: Comentario) -> str:
    t = c.texto
    if c.abre == "#":
        return t[1:].strip()
    if c.abre == "//":
        return t[2:].strip()
    if c.abre == "/*":
        return t[2:-2].strip().strip("*").strip()
    return t[4:-3].strip()


def _ancoradas(trecho: str, tipo: str) -> list[str]:
    achadas = []
    pos = 0
    while pos < len(trecho):
        for d in DIRETIVAS:
            if tipo not in d.tipos:
                continue
            m = d.forma.match(trecho, pos)
            if m:
                achadas.append(m.group(0).strip())
                pos = m.end()
                while pos < len(trecho) and trecho[pos] in " \t,;":
                    pos += 1
                break
        else:
            break
    return achadas


def _embrulhar(abre: str, partes: list[str]) -> str:
    if abre == "#":
        return "  ".join(f"# {p}" for p in partes)
    if abre == "//":
        return f"// {' '.join(partes)}"
    if abre == "/*":
        return f"/* {' '.join(partes)} */"
    return f"<!-- {' '.join(partes)} -->"


def forma_da_diretiva(c: Comentario, tipo: str) -> str | None:
    """A forma nua que o comentário guarda, se ele é diretiva; ``None`` se ele sai inteiro."""
    if c.abre == "#" and c.linha == 1 and c.texto.startswith("#!"):
        return c.texto
    if c.abre == "#" and c.linha <= 2 and re.match(r"#.*?coding[:=]\s*[-\w.]+", c.texto):
        return c.texto
    miolo = _miolo(c)
    trechos = [t.strip() for t in miolo.split("#")] if c.abre == "#" else [miolo]
    partes: list[str] = []
    for trecho in trechos:
        partes += _ancoradas(trecho, tipo)
    return _embrulhar(c.abre, partes) if partes else None


def comentarios_py(texto: str) -> list[Comentario]:
    inicios = [0] + [m.end() for m in re.finditer("\n", texto)]
    achados = []
    for tok in tokenize.generate_tokens(io.StringIO(texto).readline):
        if tok.type == tokenize.COMMENT:
            (lin, col), (lin_fim, col_fim) = tok.start, tok.end
            achados.append(Comentario(inicios[lin - 1] + col, inicios[lin_fim - 1] + col_fim, tok.string, lin, "#"))
    return achados


_PALAVRA_SH = set(" \t\n;&|()")


def _heredoc(texto: str, i: int) -> tuple[int, str, bool] | None:
    j = i + 2
    tira_tab = False
    if j < len(texto) and texto[j] == "-":
        tira_tab, j = True, j + 1
    while j < len(texto) and texto[j] in " \t":
        j += 1
    k = j
    delim = []
    while k < len(texto) and texto[k] not in " \t\n;&|()<>":
        ch = texto[k]
        if ch in "'\"":
            fecha = texto.index(ch, k + 1)
            delim.append(texto[k + 1:fecha])
            k = fecha + 1
            continue
        if ch == "\\":
            k += 1
            continue
        delim.append(ch)
        k += 1
    if not delim:
        return None
    return k, "".join(delim), tira_tab


def _fecha_parenteses(texto: str, i: int) -> int:
    profundidade = 0
    while i < len(texto):
        ch = texto[i]
        if ch == "\\":
            i += 2
            continue
        if ch == "'":
            i = texto.index("'", i + 1) + 1
            continue
        if ch == '"':
            i = _fim_das_aspas(texto, i + 1)
            continue
        if ch == "(":
            profundidade += 1
        elif ch == ")":
            profundidade -= 1
            if profundidade == 0:
                return i + 1
        i += 1
    return i


def _fim_das_chaves(texto: str, i: int) -> int:
    profundidade = 1
    while i < len(texto):
        ch = texto[i]
        if ch == "\\":
            i += 2
            continue
        if ch == "'" and profundidade:
            i = texto.index("'", i + 1) + 1
            continue
        if ch == '"':
            i = _fim_das_aspas(texto, i + 1)
            continue
        if texto.startswith("${", i):
            i = _fim_das_chaves(texto, i + 2)
            continue
        if ch == "{":
            profundidade += 1
        elif ch == "}":
            profundidade -= 1
            if profundidade == 0:
                return i + 1
        i += 1
    return i


def _fim_das_aspas(texto: str, i: int) -> int:
    while i < len(texto):
        ch = texto[i]
        if ch == "\\":
            i += 2
            continue
        if ch == '"':
            return i + 1
        if texto.startswith("$((", i):
            i = _fecha_parenteses(texto, i + 1)
            continue
        if texto.startswith("$(", i):
            i = _varrer_sh(texto, i + 2, [], dentro=True)
            continue
        if texto.startswith("${", i):
            i = _fim_das_chaves(texto, i + 2)
            continue
        if ch == "`":
            i = _fim_da_crase(texto, i + 1)
            continue
        i += 1
    return i


def _fim_da_crase(texto: str, i: int) -> int:
    while i < len(texto):
        if texto[i] == "\\":
            i += 2
            continue
        if texto[i] == "`":
            return i + 1
        i += 1
    return i


def _varrer_sh(texto: str, i: int, achados: list[Comentario], dentro: bool = False) -> int:
    pendentes: list[tuple[str, bool]] = []
    profundidade = 0
    casos = 0
    n = len(texto)
    while i < n:
        ch = texto[i]
        if ch == "\\":
            i += 2
            continue
        if ch == "\n":
            i += 1
            for delim, tira_tab in pendentes:
                while i < n:
                    fim = texto.find("\n", i)
                    fim = n if fim == -1 else fim
                    linha = texto[i:fim]
                    i = fim + 1
                    if (linha.lstrip("\t") if tira_tab else linha) == delim:
                        break
            pendentes = []
            continue
        if ch == "#" and (i == 0 or texto[i - 1] in _PALAVRA_SH):
            fim = texto.find("\n", i)
            fim = n if fim == -1 else fim
            achados.append(Comentario(i, fim, texto[i:fim], _linha_de(texto, i), "#"))
            i = fim
            continue
        if ch == "'":
            i = texto.index("'", i + 1) + 1
            continue
        if ch == '"':
            i = _fim_das_aspas(texto, i + 1)
            continue
        if ch == "`":
            i = _fim_da_crase(texto, i + 1)
            continue
        if ch == "$":
            if texto.startswith("$'", i):
                i += 2
                while i < n and texto[i] != "'":
                    i += 2 if texto[i] == "\\" else 1
                i += 1
                continue
            if texto.startswith("$((", i):
                i = _fecha_parenteses(texto, i + 1)
                continue
            if texto.startswith("$(", i):
                i = _varrer_sh(texto, i + 2, achados, dentro=True)
                continue
            if texto.startswith("${", i):
                i = _fim_das_chaves(texto, i + 2)
                continue
            i += 2 if i + 1 < n and texto[i + 1] != "\n" else 1
            continue
        if texto.startswith("<<<", i):
            i += 3
            continue
        if texto.startswith("<<", i):
            lido = _heredoc(texto, i)
            if lido is not None:
                i, delim, tira_tab = lido
                pendentes.append((delim, tira_tab))
                continue
        if dentro:
            palavra = re.match(r"[A-Za-z_]+", texto[i:i + 5]) if (i == 0 or texto[i - 1] in _PALAVRA_SH) else None
            if palavra and palavra.group(0) == "case" and texto[i + 4:i + 5] in " \t\n":
                casos += 1
            elif palavra and palavra.group(0) == "esac" and texto[i + 4:i + 5] in " \t\n;)":
                casos -= 1
            if ch == "(":
                profundidade += 1
            elif ch == ")":
                if casos > 0 and profundidade == 0:
                    i += 1
                    continue
                if profundidade == 0:
                    return i + 1
                profundidade -= 1
        i += 1
    return i


def comentarios_sh(texto: str) -> list[Comentario]:
    achados: list[Comentario] = []
    _varrer_sh(texto, 0, achados)
    return achados


def comentarios_gd(texto: str) -> list[Comentario]:
    achados = []
    i, n = 0, len(texto)
    while i < n:
        ch = texto[i]
        if ch in "'\"":
            triplo = texto.startswith(ch * 3, i)
            fecho = ch * 3 if triplo else ch
            i += len(fecho)
            while i < n and not texto.startswith(fecho, i) and (triplo or texto[i] != "\n"):
                i += 2 if texto[i] == "\\" else 1
            i += len(fecho)
            continue
        if ch == "#":
            fim = texto.find("\n", i)
            fim = n if fim == -1 else fim
            achados.append(Comentario(i, fim, texto[i:fim], _linha_de(texto, i), "#"))
            i = fim
            continue
        i += 1
    return achados


def comentarios_c(texto: str, base: int = 0, fim: int | None = None) -> list[Comentario]:
    achados = []
    i, n = base, len(texto) if fim is None else fim
    while i < n:
        ch = texto[i]
        if ch in "'\"":
            i += 1
            while i < n and texto[i] != ch and texto[i] != "\n":
                i += 2 if texto[i] == "\\" else 1
            i += 1
            continue
        if texto.startswith("//", i):
            f = i
            while True:
                f = texto.find("\n", f)
                f = n if f == -1 or f > n else f
                if f < n and texto[f - 1] == "\\":
                    f += 1
                    continue
                break
            achados.append(Comentario(i, f, texto[i:f], _linha_de(texto, i), "//"))
            i = f
            continue
        if texto.startswith("/*", i):
            f = texto.find("*/", i + 2)
            f = n if f == -1 else f + 2
            achados.append(Comentario(i, f, texto[i:f], _linha_de(texto, i), "/*"))
            i = f
            continue
        i += 1
    return achados


def comentarios_css(texto: str, base: int = 0, fim: int | None = None) -> list[Comentario]:
    return [c for c in comentarios_c(texto, base, fim) if c.abre == "/*"]


_ANTES_DE_REGEX = set("(,=:[!&|?{};+-*%<>~^")
_PALAVRAS_DE_REGEX = {"return", "typeof", "instanceof", "in", "of", "new", "delete", "void", "throw",
                      "case", "do", "else", "yield", "await"}


def _regex_pode(texto: str, i: int, base: int) -> bool:
    j = i - 1
    while j >= base and texto[j] in " \t\r\n":
        j -= 1
    if j < base:
        return True
    ch = texto[j]
    if ch in _ANTES_DE_REGEX:
        return True
    if ch.isalnum() or ch in "_$":
        k = j
        while k >= base and (texto[k].isalnum() or texto[k] in "_$"):
            k -= 1
        return texto[k + 1:j + 1] in _PALAVRAS_DE_REGEX
    return False


def _varrer_js(texto: str, i: int, n: int, achados: list[Comentario], base: int, no_template: bool = False) -> int:
    chaves = 0
    while i < n:
        ch = texto[i]
        if no_template:
            if ch == "{":
                chaves += 1
            elif ch == "}":
                if chaves == 0:
                    return i + 1
                chaves -= 1
        if ch in "'\"":
            i += 1
            while i < n and texto[i] != ch and texto[i] != "\n":
                i += 2 if texto[i] == "\\" else 1
            i += 1
            continue
        if ch == "`":
            i += 1
            while i < n and texto[i] != "`":
                if texto[i] == "\\":
                    i += 2
                    continue
                if texto.startswith("${", i):
                    i = _varrer_js(texto, i + 2, n, achados, base, no_template=True)
                    continue
                i += 1
            i += 1
            continue
        if texto.startswith("//", i):
            f = texto.find("\n", i)
            f = n if f == -1 or f > n else f
            achados.append(Comentario(i, f, texto[i:f], _linha_de(texto, i), "//"))
            i = f
            continue
        if texto.startswith("/*", i):
            f = texto.find("*/", i + 2)
            f = n if f == -1 else f + 2
            achados.append(Comentario(i, f, texto[i:f], _linha_de(texto, i), "/*"))
            i = f
            continue
        if ch == "/" and _regex_pode(texto, i, base):
            i += 1
            classe = False
            while i < n and texto[i] != "\n":
                c = texto[i]
                if c == "\\":
                    i += 2
                    continue
                if c == "[":
                    classe = True
                elif c == "]":
                    classe = False
                elif c == "/" and not classe:
                    break
                i += 1
            i += 1
            continue
        i += 1
    return i


def comentarios_js(texto: str, base: int = 0, fim: int | None = None) -> list[Comentario]:
    achados: list[Comentario] = []
    n = len(texto) if fim is None else fim
    inicio = base
    if texto.startswith("#!", base):
        inicio = texto.find("\n", base)
        inicio = n if inicio == -1 else inicio
    _varrer_js(texto, inicio, n, achados, base)
    return achados


BRUTOS = re.compile(r"<(script|style|textarea|title|xmp)\b([^>]*)>", re.I)
TIPO_DO_SCRIPT = re.compile(r"""\btype\s*=\s*["']?([^"'\s>]+)""", re.I)
SCRIPT_JS = {"", "text/javascript", "module", "application/javascript"}


def comentarios_html(texto: str) -> list[Comentario]:
    achados: list[Comentario] = []
    i, n = 0, len(texto)
    while i < n:
        if texto.startswith("<!--", i):
            f = texto.find("-->", i + 4)
            f = n if f == -1 else f + 3
            achados.append(Comentario(i, f, texto[i:f], _linha_de(texto, i), "<!--"))
            i = f
            continue
        m = BRUTOS.match(texto, i) if texto[i] == "<" else None
        if m:
            nome = m.group(1).lower()
            fecho = re.compile(rf"</{nome}\s*>", re.I).search(texto, m.end())
            fim = n if fecho is None else fecho.start()
            if nome == "style":
                achados += comentarios_css(texto, m.end(), fim)
            elif nome == "script":
                tipo = TIPO_DO_SCRIPT.search(m.group(2))
                if (tipo.group(1).lower() if tipo else "") in SCRIPT_JS:
                    achados += comentarios_js(texto, m.end(), fim)
            i = n if fecho is None else fecho.end()
            continue
        if texto[i] == "<" and i + 1 < n and (texto[i + 1].isalpha() or texto[i + 1] == "/"):
            i = _fim_da_etiqueta(texto, i + 1, n)
            continue
        i += 1
    return achados


def _fim_da_etiqueta(texto: str, i: int, n: int) -> int:
    while i < n:
        ch = texto[i]
        if ch in "'\"":
            fecha = texto.find(ch, i + 1)
            i = n if fecha == -1 else fecha + 1
            continue
        if ch == ">":
            return i + 1
        i += 1
    return i


LEITORES = {
    "py": comentarios_py,
    "sh": comentarios_sh,
    "gd": comentarios_gd,
    "c": comentarios_c,
    "js": comentarios_js,
    "html": comentarios_html,
}


def comentarios(texto: str, tipo: str) -> list[Comentario]:
    """Os comentários de ``texto`` lidos pelo analisador de ``tipo``."""
    return LEITORES[tipo](texto)


def tipo_do_arquivo(rel: str, primeira_linha: str = "") -> str | None:
    """O tipo pelo sufixo; sem sufixo, pelo ``#!``. ``None``: fora do escopo."""
    if rel.startswith(FORA):
        return None
    nome = rel.rsplit("/", 1)[-1]
    if "." in nome:
        return SUFIXOS.get(nome.rsplit(".", 1)[1])
    if primeira_linha.startswith("#!"):
        if re.search(r"\b(bash|sh|dash|zsh)\b", primeira_linha):
            return "sh"
        if "python" in primeira_linha:
            return "py"
    return None


def _primeira_linha(caminho: Path) -> str:
    try:
        with caminho.open("rb") as f:
            return f.readline(200).decode("utf-8", "replace")
    except OSError:
        return ""


def alvos(raiz: Path = RAIZ, arquivos: list[str] | None = None) -> list[tuple[str, str]]:
    """``(arquivo, tipo)`` de cada arquivo no escopo: os versionados, ou os dados."""
    if arquivos is None:
        feito = subprocess.run(["git", "-C", str(raiz), "ls-files", "-z"], capture_output=True, text=True,
                               check=False)
        if feito.returncode != 0:
            raise RuntimeError(f"git ls-files falhou: {feito.stderr.strip()}")
        arquivos = [a for a in feito.stdout.split("\0") if a]
    saida = []
    for rel in sorted(set(arquivos)):
        caminho = raiz / rel
        if not caminho.is_file() or caminho.is_symlink():
            continue
        tipo = tipo_do_arquivo(rel, _primeira_linha(caminho))
        if tipo is not None:
            saida.append((rel, tipo))
    return saida


@dataclass(frozen=True)
class Achado:
    arquivo: str
    linha: int
    texto: str

    def __str__(self) -> str:
        return f"{self.arquivo}:{self.linha}: {self.texto[:100]}"


def achados_do_texto(texto: str, tipo: str, rel: str = "") -> list[Achado]:
    """Cada comentário de ``texto`` que não é diretiva nua."""
    try:
        lidos = comentarios(texto, tipo)
    except (tokenize.TokenError, SyntaxError, ValueError) as erro:
        return [Achado(rel, 0, f"o analisador de {tipo} não leu o arquivo: {type(erro).__name__}")]
    return [Achado(rel, c.linha, c.texto) for c in lidos if forma_da_diretiva(c, tipo) != c.texto]


def varrer(raiz: Path = RAIZ, arquivos: list[str] | None = None) -> list[Achado]:
    achados: list[Achado] = []
    for rel, tipo in alvos(raiz, arquivos):
        try:
            texto = (raiz / rel).read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            achados.append(Achado(rel, 0, "não é UTF-8"))
            continue
        achados += achados_do_texto(texto, tipo, rel)
    return achados


def por_arquivo(achados: list[Achado]) -> dict[str, int]:
    conta: dict[str, int] = {}
    for x in achados:
        conta[x.arquivo] = conta.get(x.arquivo, 0) + 1
    return conta


def ler_piso(raiz: Path) -> dict[str, int]:
    try:
        return dict(json.loads((raiz / CADERNO).read_text(encoding="utf-8"))["piso"])
    except (OSError, ValueError, KeyError) as erro:
        raise SystemExit(f"codigo sem comentario: não li o piso em {CADERNO}: {erro}") from None


def catraca(raiz: Path, aceitar: bool) -> int:
    """O número de comentários de cada arquivo só desce; o arquivo fora do piso tem piso zero."""
    agora = por_arquivo(varrer(raiz))
    piso = ler_piso(raiz)
    subiram = sorted((f, n, piso.get(f, 0)) for f, n in agora.items() if n > piso.get(f, 0))
    total, total_piso = sum(agora.values()), sum(piso.values())
    if subiram:
        for f, n, p in subiram:
            print(f"FAIL codigo sem comentario: {f}: {p} -> {n} comentário(s)")
        print(f"codigo sem comentario: o volume subiu em {len(subiram)} arquivo(s). Rode "
              "`python3 scripts/tirar_os_comentarios.py --aplicar ARQ` (ADR-010)")
        return 1
    if aceitar:
        (raiz / CADERNO).write_text(json.dumps({"piso": dict(sorted(agora.items()))}, ensure_ascii=False, indent=1)
                                    + "\n", encoding="utf-8")
        print(f"codigo sem comentario: piso gravado ({total_piso} -> {total})")
        return 0
    desceu = f"; desceu de {total_piso}: grave com `--catraca --aceitar`" if total < total_piso else ""
    print(f"codigo sem comentario: {total} comentário(s), nenhum arquivo acima do piso{desceu}")
    return 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="portoes/codigo_sem_comentario", description=(__doc__ or "").split("\n", 1)[0])
    p.add_argument("arquivos", nargs="*")
    p.add_argument("--raiz", default=None)
    p.add_argument("--modo", choices=("aviso", "reprova"), default="reprova")
    p.add_argument("--lista", action="store_true", help="todos os achados, sem teto")
    p.add_argument("--diretivas", action="store_true", help="as diretivas que ficam e quem lê cada uma")
    p.add_argument("--catraca", action="store_true", help="o volume por arquivo só desce (o piso do caderno)")
    p.add_argument("--aceitar", action="store_true", help="com --catraca: grava o piso de hoje")
    a = p.parse_args(argv)
    raiz = Path(a.raiz).resolve() if a.raiz else RAIZ
    if a.diretivas:
        print("#!  na linha 1, e o coding nas linhas 1 e 2: o interpretador")
        for d in DIRETIVAS:
            print(f"{d.nome}: {d.forma.pattern}  [{', '.join(d.tipos)}]  lida por {d.leitor}")
        return 0
    if a.catraca:
        return catraca(raiz, a.aceitar)
    pedidos = None
    if a.arquivos:
        pedidos = []
        for bruto in a.arquivos:
            caminho = Path(bruto)
            caminho = (caminho if caminho.is_absolute() else Path.cwd() / caminho).resolve()
            try:
                pedidos.append(caminho.relative_to(raiz).as_posix())
            except ValueError:
                continue
    achados = varrer(raiz, pedidos)
    if not achados:
        print("codigo sem comentario: 0 achados")
        return 0
    marca = "FAIL" if a.modo == "reprova" else "AVISO"
    mostrar = achados if a.lista else achados[:TETO_DA_SAIDA]
    for x in mostrar:
        print(f"{marca} codigo sem comentario: {x}")
    if len(achados) > len(mostrar):
        print(f"(e mais {len(achados) - len(mostrar)}; `--lista` mostra todos)")
    print(f"codigo sem comentario: {len(achados)} comentário(s) em {len(por_arquivo(achados))} arquivo(s) "
          f"(modo {a.modo}). O porquê vai a docs/o-porque-dos-modulos.md; a diretiva fica nua (`--diretivas`)")
    return 1 if a.modo == "reprova" else 0


if __name__ == "__main__":
    sys.exit(main())
