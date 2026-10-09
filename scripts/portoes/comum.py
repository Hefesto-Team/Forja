"""O que os portões de scripts/portoes/ dividem: os argumentos, as regras em
arquivo de dados, a varredura dos arquivos e a saída.

Todo portão aceita:
    --raiz DIR      a árvore que se confere (padrão: a do repositório)
    --regras ARQ    o arquivo de regras (padrão: <portão>.json ao lado do script)
    --modo M        aviso | reprova (padrão: o "modo" do arquivo de regras)

A saída é uma linha por achado, `AVISO <portão>: <caminho>:<linha>: <o quê>`
no modo aviso e `FAIL <portão>: ...` no modo reprova, e uma linha de resumo
no fim. O código de saída: 0 sem achado, ou com achado em modo aviso; 1 com
achado em modo reprova; 2 quando o portão não conseguiu conferir (regras
ilegíveis, argumento ruim).
"""
import argparse
import json
import pathlib
import sys

RAIZ_DO_REPO = pathlib.Path(__file__).resolve().parent.parent.parent
MODOS = ("aviso", "reprova")


def argumentos(nome: str, descricao: str, com_regras: bool = True, extra=None):
    ap = argparse.ArgumentParser(prog=f"portoes/{nome}", description=descricao)
    ap.add_argument("--raiz", default=str(RAIZ_DO_REPO), help="a árvore que se confere")
    if com_regras:
        ap.add_argument("--regras", default=str(pathlib.Path(__file__).with_name(f"{nome}.json")),
                        help="o arquivo de regras")
    ap.add_argument("--modo", choices=MODOS, default=None, help="aviso ou reprova (padrão: o do arquivo de regras)")
    if extra:
        extra(ap)
    a = ap.parse_args()
    a.raiz = pathlib.Path(a.raiz).resolve()
    return a


def regras(caminho: str) -> dict:
    try:
        return json.loads(pathlib.Path(caminho).read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"portão: não li as regras em {caminho}: {e}", file=sys.stderr)
        sys.exit(2)


def modo_de(a, r: dict) -> str:
    m = a.modo or r.get("modo", "aviso")
    if m not in MODOS:
        print(f"portão: modo desconhecido {m!r} (aviso ou reprova)", file=sys.stderr)
        sys.exit(2)
    return m


def arquivos(raiz: pathlib.Path, escopo, extensoes, ignorar=()):
    """Os arquivos do escopo (pastas ou arquivos, relativos à raiz), em ordem."""
    vistos = []
    for item in escopo:
        p = raiz / item
        if p.is_file():
            vistos.append(p)
        elif p.is_dir():
            vistos += [f for f in sorted(p.rglob("*")) if f.is_file() and f.suffix in extensoes]
    fora = tuple(ignorar)
    return [f for f in vistos if not str(f.relative_to(raiz)).startswith(fora)]


def args_da_chamada(texto: str, abre: int):
    """Os argumentos da chamada cujo `(` está em `abre`: uma lista de textos,
    respeitando parênteses, colchetes, chaves e strings. None se não fecha."""
    nivel, atual, args, i, aspas = 0, [], [], abre + 1, ""
    while i < len(texto):
        c = texto[i]
        if aspas:
            atual.append(c)
            if c == "\\" and i + 1 < len(texto):
                atual.append(texto[i + 1])
                i += 1
            elif c == aspas:
                aspas = ""
        elif c in "\"'":
            aspas = c
            atual.append(c)
        elif c in "([{":
            nivel += 1
            atual.append(c)
        elif c in ")]}":
            if nivel == 0:
                args.append("".join(atual).strip())
                return [x for x in args if x != ""] if args != [""] else []
            nivel -= 1
            atual.append(c)
        elif c == "," and nivel == 0:
            args.append("".join(atual).strip())
            atual = []
        else:
            atual.append(c)
        i += 1
    return None


def sem_comentarios(texto: str) -> str:
    """O texto com cada comentário de GDScript (`#` fora de string até o fim
    da linha) trocado por espaços: as posições e as linhas não mudam."""
    saida, i, aspas = list(texto), 0, ""
    while i < len(texto):
        c = texto[i]
        if aspas:
            if c == "\\":
                i += 1
            elif c == aspas or c == "\n":
                aspas = ""
        elif c in "\"'":
            aspas = c
        elif c == "#":
            while i < len(texto) and texto[i] != "\n":
                saida[i] = " "
                i += 1
            continue
        i += 1
    return "".join(saida)


def linha_de(texto: str, pos: int) -> int:
    return texto.count("\n", 0, pos) + 1


class Relato:
    def __init__(self, nome: str, modo: str):
        self.nome, self.modo, self.achados = nome, modo, []

    def achou(self, caminho, linha, oque: str):
        self.achados.append((str(caminho), linha, oque))

    def fechar(self, resumo: str = "") -> int:
        marca = "FAIL" if self.modo == "reprova" else "AVISO"
        for caminho, linha, oque in self.achados:
            onde = f"{caminho}:{linha}" if linha else caminho
            print(f"{marca} {self.nome}: {onde}: {oque}")
        n = len(self.achados)
        extra = f"; {resumo}" if resumo else ""
        print(f"{self.nome}: {n} {'achado' if n == 1 else 'achados'} (modo {self.modo}){extra}")
        return 1 if (n and self.modo == "reprova") else 0
