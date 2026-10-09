#!/usr/bin/env python3
"""O código de arquivo inteiro de uma ficha, por script.

Um bloco de código que é um arquivo inteiro diz para onde vai na cerca:

    ```gdscript arquivo=godot/scripts/minigames/s01/marcha.gd

A palavra depois da língua não muda o realce no leitor do repositório. Quando o
arquivo vem em mais de um bloco (o corpo, a FICHA de «A ficha de dados», o robô de
«O robô»), cada um leva a mesma marca, e os de fora do corpo levam `parte=N`: o
arquivo é o bloco sem parte (a parte 1), depois a 2, a 3..., com uma linha em
branco entre eles. Três modos:

  --escrever   grava cada bloco marcado no seu arquivo, byte a byte (a tabulação e
               a linha em branco do fim chegam iguais). Recusa caminho fora de
               godot/, scripts/ e tests/, ou com «..», e então não grava nada.
               O bloco sem a marca (um trecho) não se toca.
  --conferir   o diff unificado entre cada bloco marcado e o arquivo de hoje;
               sai 1 quando algum difere ou falta.
  --marcar     para cada bloco gdscript de mais de 80 linhas, sem a marca, que
               começa como arquivo (`extends`, `class_name` ou `@tool`), procura o
               caminho em crase na prosa logo acima e propõe o `arquivo=`. Só
               escreve na ficha com --sim. O bloco sem caminho claro é listado.

Saída: 0 ok; 1 diferença (--conferir) ou caminho recusado (--escrever); 2 uso ruim
ou ficha que não se lê.

Uso: python3 scripts/ficha_codigo.py <ficha.md>... (--escrever | --conferir | --marcar [--sim]) [--raiz DIR]
"""
import argparse
import difflib
import re
import sys
from pathlib import Path

RAIZ_DO_REPO = Path(__file__).resolve().parent.parent
PASTAS = ("godot/", "scripts/", "tests/")
ABRE = re.compile(r"^```(\w+)((?:\s+\S+)*)\s*$")
FECHA = re.compile(r"^```\s*$")
MARCA = re.compile(r"(?:^|\s)arquivo=(\S+)")
PARTE = re.compile(r"(?:^|\s)parte=(\d+)")
CAMINHO = re.compile(r"`((?:godot|scripts|tests)/[^`\s]+\.(?:gd|py|sh|gdshader|tscn|cfg|json|csv))`")
COMECO_DE_ARQUIVO = re.compile(r"^(extends|class_name|@tool)\b")
MINIMO = 80


class Bloco:
    def __init__(self, abre: int, fecha: int, lingua: str, info: str, linhas):
        self.abre, self.fecha, self.lingua, self.info, self.linhas = abre, fecha, lingua, info, linhas
        m = MARCA.search(info)
        self.arquivo = m.group(1) if m else None
        p = PARTE.search(info)
        self.parte = int(p.group(1)) if p else 1

    def texto(self) -> str:
        return "".join(l + "\n" for l in self.linhas)


def blocos(texto: str):
    """Os blocos de cerca da ficha (só os da coluna zero), com a linha de abrir e a de fechar."""
    linhas = texto.split("\n")
    achou, i = [], 0
    while i < len(linhas):
        m = ABRE.match(linhas[i])
        if m:
            j = i + 1
            while j < len(linhas) and not FECHA.match(linhas[j]):
                j += 1
            achou.append(Bloco(i, j, m.group(1), m.group(2) or "", linhas[i + 1:j]))
            i = j + 1
            continue
        if FECHA.match(linhas[i]):   # cerca sem língua: pula o bloco inteiro
            j = i + 1
            while j < len(linhas) and not FECHA.match(linhas[j]):
                j += 1
            i = j + 1
            continue
        i += 1
    return achou, linhas


def arquivos(ficha: Path):
    """[(caminho, texto, [blocos])] dos arquivos que a ficha marca, com as partes na ordem; e os erros."""
    bs, _ = blocos(ler(ficha))
    grupos, erros = {}, []
    for b in bs:
        if b.arquivo:
            grupos.setdefault(b.arquivo, []).append(b)
    saida = []
    for caminho, lista in grupos.items():
        lista.sort(key=lambda b: b.parte)   # estável: a ordem da ficha desempata
        partes = [b.parte for b in lista]
        if len(set(partes)) != len(partes):
            erros.append(f"{ficha.name}: arquivo={caminho} tem a mesma parte em dois blocos ({partes})")
            continue
        saida.append((caminho, "\n".join(b.texto() for b in lista), lista))
    return saida, erros


def recusa(caminho: str):
    """O motivo de recusar o caminho, ou None."""
    p = Path(caminho)
    if p.is_absolute() or ".." in p.parts:
        return "caminho absoluto ou com «..»"
    if not caminho.startswith(PASTAS):
        return "fora de godot/, scripts/ e tests/"
    return None


def proposta(linhas, bloco: Bloco):
    """O caminho em crase mais perto acima do bloco (até o bloco anterior ou 8 linhas com texto), ou None."""
    vistas, i = 0, bloco.abre - 1
    while i >= 0 and vistas < 8:
        linha = linhas[i]
        if linha.startswith("```"):
            break
        if linha.strip():
            vistas += 1
            achados = list(dict.fromkeys(CAMINHO.findall(linha)))
            if len(achados) == 1:
                return achados[0]
            if len(achados) > 1:
                return None      # dois caminhos na mesma linha: não é claro
        i -= 1
    return None


def ler(ficha: Path):
    try:
        return ficha.read_text(encoding="utf-8")
    except OSError as e:
        print(f"ficha código: não li {e.filename}", file=sys.stderr)
        sys.exit(2)


def escrever(fichas, raiz: Path) -> int:
    marcados, ruins = [], []
    for f in fichas:
        lista, erros = arquivos(f)
        ruins += erros
        marcados += [(f, c, t, bs) for c, t, bs in lista]
    for f, c, _, bs in marcados:
        if recusa(c):
            ruins.append(f"{f.name}:{bs[0].abre + 1}: arquivo={c} recusado ({recusa(c)})")
    for r in ruins:
        print(f"ficha código: {r}; nada foi gravado", file=sys.stderr)
    if ruins:
        return 1
    for f, c, texto, bs in marcados:
        alvo = raiz / c
        alvo.parent.mkdir(parents=True, exist_ok=True)
        with open(alvo, "w", encoding="utf-8", newline="") as saida:
            saida.write(texto)
        print(f"gravado {c} ({texto.count(chr(10))} linhas, de {f.name}, linhas "
              f"{', '.join(str(b.abre + 1) for b in bs)})")
    if not marcados:
        print("ficha código: nenhum bloco com arquivo= nas fichas", file=sys.stderr)
    return 0


def conferir(fichas, raiz: Path) -> int:
    rc, n = 0, 0
    for f in fichas:
        lista, erros = arquivos(f)
        for e in erros:
            print(f"ficha código: {e}", file=sys.stderr)
            rc = 1
        for c, texto, _ in lista:
            n += 1
            motivo = recusa(c)
            if motivo:
                print(f"ficha código: {f.name}: arquivo={c} recusado ({motivo})", file=sys.stderr)
                rc = 1
                continue
            alvo = raiz / c
            hoje = alvo.read_bytes().decode("utf-8") if alvo.is_file() else ""
            if hoje == texto:
                print(f"igual   {c}")
                continue
            rc = 1
            print(f"difere  {c}" + ("" if alvo.is_file() else " (o arquivo não existe)"))
            sys.stdout.writelines(difflib.unified_diff(
                hoje.splitlines(keepends=True), texto.splitlines(keepends=True),
                fromfile=f"{c} (hoje)", tofile=f"{c} ({f.name})"))
    print(f"{n} arquivos marcados conferidos")
    return rc


def marcar(fichas, sim: bool) -> int:
    sem = []
    for f in fichas:
        texto = ler(f)
        bs, linhas = blocos(texto)
        mudou = False
        for b in bs:
            if b.arquivo or b.lingua != "gdscript" or len(b.linhas) <= MINIMO:
                continue
            primeira = next((l for l in b.linhas if l.strip() and not l.lstrip().startswith("#")), "")
            if not COMECO_DE_ARQUIVO.match(primeira):
                sem.append(f"{f.name}:{b.abre + 1} ({len(b.linhas)} linhas): trecho, não começa como arquivo")
                continue
            caminho = proposta(linhas, b)
            if not caminho or recusa(caminho):
                sem.append(f"{f.name}:{b.abre + 1} ({len(b.linhas)} linhas): sem caminho claro na prosa acima")
                continue
            print(f"{f.name}:{b.abre + 1} ({len(b.linhas)} linhas): arquivo={caminho}")
            if sim:
                linhas[b.abre] = linhas[b.abre].rstrip() + f" arquivo={caminho}"
                mudou = True
        if mudou:
            f.write_text("\n".join(linhas), encoding="utf-8")
    for s in sem:
        print(f"sem marca  {s}")
    if not sim:
        print("(proposta: nada foi escrito; --sim grava)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(prog="ficha_codigo", description="O código de arquivo inteiro de uma ficha.")
    ap.add_argument("fichas", nargs="+", type=Path)
    modo = ap.add_mutually_exclusive_group(required=True)
    modo.add_argument("--escrever", action="store_true")
    modo.add_argument("--conferir", action="store_true")
    modo.add_argument("--marcar", action="store_true")
    ap.add_argument("--sim", action="store_true", help="com --marcar: grava as propostas na ficha")
    ap.add_argument("--raiz", type=Path, default=RAIZ_DO_REPO, help="a árvore onde os arquivos moram")
    a = ap.parse_args()
    if a.escrever:
        return escrever(a.fichas, a.raiz.resolve())
    if a.conferir:
        return conferir(a.fichas, a.raiz.resolve())
    return marcar(a.fichas, a.sim)


if __name__ == "__main__":
    sys.exit(main())
