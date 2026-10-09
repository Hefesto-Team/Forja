#!/usr/bin/env python3
"""A esteira: lê o quadro e o ESPERA-ELA e diz, em JSON, o que despachar agora.

É a volta 1 a 3 de docs/jogo/o-time/a-esteira.md, por script: não despacha nada,
só responde. Quem despacha é o molde de workflow de quem coordena (fora do
repositório), que lê esta saída.

Lê:
  docs/jogo/tarefas/README.md     as seções `## <Letra> — <nome>` e as linhas
                                  `| [COD](ficha.md) | título | tam | depende de | estado |`
  docs/jogo/o-time/ESPERA-ELA.md  a tabela `| desde | o que ela decide | o que espera |`
  cada ficha                      a parte `## Arquivos que mudam` (os caminhos em crase)

Os estados: a fazer, enriquecida, pronta, em voo (com o conjunto: «em voo (o-controle)»),
conferida, jogada, feito. «fazendo» conta como em voo. As bases (--bases, padrão F, H, V, X)
vão de «a fazer» direto para em voo; as outras seções só saem com toda ficha «pronta».

Uma seção está pronta para despachar quando:
  1. nenhuma ficha dela está em voo, conferida ou jogada, e alguma ainda não está feita;
  2. toda ficha não feita está «pronta» (numa base, «a fazer» também vale);
  3. toda dependência de fora da seção está feita (a de dentro, o conjunto faz em ordem);
  4. nenhuma linha do ESPERA-ELA a segura (a linha cita a seção ou uma ficha dela, ou espera
     «o enriquecimento» e a seção não é base e tem ficha «a fazer», ou uma ficha diz
     «ESPERA-ELA» na coluna «depende de»);
  5. os arquivos dela não cruzam os de um conjunto em voo.
Das prontas, saem na ordem do quadro até o limite de conjuntos juntos (--limite, padrão 4,
contando os em voo), cada uma com arquivos que não cruzam os das já escolhidas; o resto fica
na fila, com o motivo.

Os arquivos de uma ficha vêm da parte «Arquivos que mudam». Ficha sem essa parte tem os
arquivos estimados pelos caminhos em crase do resto dela (menos o «Ler antes» e as
«Provas»), e a saída diz «estimado».

A dependência se lê pelo código da ficha (F04, I1, R) e por «seção I», «seções I a Q» e
«S5 a S8» (o S<n> do título da seção). O que não se lê assim (G14 fora do quadro, «a bíblia
aprovada») vai para `dependencias_em_texto`, para conferir à mão: não segura nem solta.

Saída (stdout, JSON):
  {"prontas_para_despachar": [{"secao", "nome", "base" (sim/não: a seção não espera enriquecimento, e as fichas
                               dela não têm «A diversão»), "fichas", "caminhos" (das fichas), "arquivos", "estimado"}],
   "na_fila": [{"secao", "motivo"}],
   "em_voo": {"<conjunto>": {"secoes", "fichas", "arquivos"}},
   "espera_ela": [{"desde", "decide", "espera", "segura"}],
   "bloqueadas": [{"secao", "motivos"}],
   "dependencias_em_texto": {"<ficha>": "<texto>"}}

Uso: python3 scripts/esteira.py [--raiz DIR] [--bases F,H,V,X] [--limite 4]
rc: 0 leu; 2 não leu o quadro.
"""
import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

QUADRO = "docs/jogo/tarefas/README.md"
ESPERA = "docs/jogo/o-time/ESPERA-ELA.md"
SECAO = re.compile(r"^##\s+([A-Z])\s+—\s+(.+?)\s*$")
LINHA = re.compile(r"^\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|(.*)\|\s*$")
LINK_MD = re.compile(r"\[([^\]]*)\]\([^)]*\)")
CRASE = re.compile(r"`([^`\s]+)`")
PREFIXOS = ("godot/", "scripts/", "tests/", "docs/", "nativo/", "src/", "include/", "cmake/", "tools/",
            "udev/", "oficina/", "experimental/", "third_party/", ".github/")
ESTADOS = ["a fazer", "enriquecida", "pronta", "em voo", "fazendo", "conferida", "jogada", "feito"]
NO_AR = {"em voo", "conferida", "jogada"}


def estado_de(texto: str):
    """(estado normalizado, conjunto) de «em voo (o-controle)», «feito, sem…», «fazendo — Ana»."""
    t = texto.strip()
    baixo = t.lower()
    for e in ESTADOS:
        if baixo.startswith(e):
            resto = t[len(e):].strip(" ,:—-")
            m = re.match(r"^\(([^)]+)\)", resto)
            conjunto = (m.group(1) if m else resto.split(",")[0]).strip(" `*") or None
            return ("em voo" if e == "fazendo" else e), conjunto
    return baixo or "a fazer", None


def partes_da_ficha(texto: str):
    achou, atual, corpo = {}, None, []
    for linha in texto.splitlines():
        if linha.startswith("## "):
            if atual is not None:
                achou[atual] = "\n".join(corpo)
            atual, corpo = linha[3:].strip().lower(), []
        elif atual is not None:
            corpo.append(linha)
    if atual is not None:
        achou[atual] = "\n".join(corpo)
    return achou


def caminhos(texto: str, raiz: Path):
    vistos = []
    for c in CRASE.findall(texto):
        c = re.sub(r":\d+(?:[-–]\d+)?$", "", c.strip().rstrip(".,;)"))
        ok = c.startswith(PREFIXOS) or ("/" not in c and (raiz / c).is_file())
        if ok and c not in vistos:
            vistos.append(c)
    return vistos


def arquivos_da_ficha(arq: Path, raiz: Path):
    """(caminhos, estimado)."""
    try:
        partes = partes_da_ficha(arq.read_text(encoding="utf-8"))
    except OSError:
        return [], True
    if "arquivos que mudam" in partes:
        return caminhos(partes["arquivos que mudam"], raiz), False
    resto = "\n".join(v for k, v in partes.items() if k not in ("ler antes", "provas"))
    return caminhos(resto, raiz), True


def cruzam(a: str, b: str) -> bool:
    if a == b:
        return True
    for x, y in ((a, b), (b, a)):
        if x.endswith("/") and y.startswith(x):
            return True
        if any(ch in x for ch in "*?[") and fnmatch.fnmatch(y, x):
            return True
    return False


def cruzamento(lista_a, lista_b):
    return sorted({a for a in lista_a for b in lista_b if cruzam(a, b)})


def ler_quadro(raiz: Path):
    """[{letra, nome, apelido, fichas: [{codigo, arquivo, titulo, depende, estado, conjunto}]}]."""
    secoes, atual = [], None
    for linha in (raiz / QUADRO).read_text(encoding="utf-8").splitlines():
        m = SECAO.match(linha)
        if m:
            nome = LINK_MD.sub(r"\1", m.group(2))
            apelido = re.match(r"^(S\d+)\s+—", nome)
            atual = {"letra": m.group(1), "nome": nome, "apelido": apelido.group(1) if apelido else None,
                     "fichas": []}
            secoes.append(atual)
            continue
        if linha.startswith("## "):
            atual = None
            continue
        m = LINHA.match(linha)
        if m and atual is not None:
            cols = [c.strip() for c in m.group(3).split("|")]
            if len(cols) < 4:
                continue
            estado, conjunto = estado_de(cols[-1])
            atual["fichas"].append({"codigo": m.group(1), "arquivo": m.group(2), "titulo": cols[0],
                                    "depende": cols[-2], "estado": estado, "conjunto": conjunto})
    return [s for s in secoes if s["fichas"]]


def ler_espera(raiz: Path):
    p = raiz / ESPERA
    if not p.is_file():
        return []
    linhas = []
    for linha in p.read_text(encoding="utf-8").splitlines():
        if not linha.startswith("|") or set(linha.replace("|", "").strip()) <= {"-", " "}:
            continue
        cols = [c.strip() for c in linha.strip().strip("|").split("|")]
        if len(cols) < 3 or cols[0].lower() == "desde":
            continue
        linhas.append({"desde": cols[0], "decide": cols[1], "espera": cols[2]})
    return linhas


def dependencias(texto: str, codigos, por_letra, apelidos):
    """(códigos de que depende, o que não se leu)."""
    t = re.sub(r"\([^)]*\)", " ", texto)
    deps = []
    ref = lambda x: apelidos.get(x, x if x in por_letra else None)  # noqa: E731
    letras = list(por_letra)

    def faixa(m):
        a, b = ref(m.group(1)), ref(m.group(2)) if m.group(2) else None
        if a is None:
            return m.group(0)
        if b is None:
            alvo = [a]
        else:
            i, j = letras.index(a), letras.index(b)
            alvo = letras[min(i, j):max(i, j) + 1]
        for letra in alvo:
            deps.extend(por_letra[letra])
        return " "

    t = re.sub(r"seç(?:ão|ões)\s+([A-Z]\d*)(?:\s+a\s+([A-Z]\d*))?", faixa, t)
    t = re.sub(r"\b(S\d+)\s+a\s+(S\d+)\b", lambda m: faixa(m) if m.group(1) in apelidos else m.group(0), t)
    for tok in re.findall(r"\b[A-Z][A-Z0-9]*\d*\b", t):
        if tok in codigos:
            deps.append(tok)
    sobra = re.sub(r"\b[A-Z][0-9]*\b", lambda m: "" if m.group(0) in codigos else m.group(0), t)
    sobra = re.sub(r"(?:[\s,;—–]|\be\b)+", " ", sobra).strip(" .")
    vazias = {"a", "as", "o", "os", "e", "de", "da", "do", "com", "pronta", "prontas", "feita", "feitas"}
    sobra = "" if all(p.lower() in vazias for p in sobra.split()) else sobra
    return list(dict.fromkeys(deps)), sobra


def main() -> int:
    ap = argparse.ArgumentParser(description="O que a esteira despacha agora, em JSON.")
    ap.add_argument("--raiz", type=Path, default=Path(__file__).resolve().parent.parent)
    ap.add_argument("--bases", default="F,H,V,X", help="as seções que não esperam enriquecimento")
    ap.add_argument("--limite", type=int, default=4, help="conjuntos juntos, contando os em voo")
    a = ap.parse_args()
    raiz = a.raiz.resolve()
    bases = {b.strip() for b in a.bases.split(",") if b.strip()}
    try:
        secoes = ler_quadro(raiz)
    except OSError as e:
        print(f"esteira: não li o quadro: {e}", file=sys.stderr)
        return 2
    espera = ler_espera(raiz)
    pasta = (raiz / QUADRO).parent

    fichas = {f["codigo"]: (s, f) for s in secoes for f in s["fichas"]}
    por_letra = {s["letra"]: [f["codigo"] for f in s["fichas"]] for s in secoes}
    apelidos = {s["apelido"]: s["letra"] for s in secoes if s["apelido"]}
    em_texto = {}
    for s in secoes:
        for f in s["fichas"]:
            f["deps"], sobra = dependencias(f["depende"], fichas, por_letra, apelidos)
            if sobra and f["estado"] != "feito":
                em_texto[f["codigo"]] = sobra
            f["arquivos"], f["estimado"] = arquivos_da_ficha(pasta / f["arquivo"], raiz)

    em_voo = {}
    for s in secoes:
        for f in s["fichas"]:
            if f["estado"] in NO_AR:
                nome = f["conjunto"] or f"secao-{s['letra']}"
                c = em_voo.setdefault(nome, {"secoes": [], "fichas": [], "arquivos": []})
                if s["letra"] not in c["secoes"]:
                    c["secoes"].append(s["letra"])
                c["fichas"].append(f["codigo"])
                c["arquivos"] = list(dict.fromkeys(c["arquivos"] + f["arquivos"]))

    def segura(linha, s):
        texto = f"{linha['decide']} {linha['espera']}"
        if (re.search(r"\benriquecimento\b", texto, re.I) and s["letra"] not in bases
                and any(f["estado"] == "a fazer" for f in s["fichas"])):
            return True
        if re.search(rf"\bse[çc](?:ão|ões)\s+{s['letra']}\b", texto):
            return True
        codigos = {f["codigo"] for f in s["fichas"]}
        if any(tok in codigos for tok in re.findall(r"\b[A-Z]\d+\b", texto)):
            return True
        return any("ESPERA-ELA" in f["depende"] for f in s["fichas"] if f["estado"] != "feito")

    saida_espera = []
    for linha in espera:
        saida_espera.append(dict(linha, segura=[s["letra"] for s in secoes
                                                if any(f["estado"] != "feito" for f in s["fichas"])
                                                and segura(linha, s)]))

    prontas, bloqueadas = [], []
    for s in secoes:
        abertas = [f for f in s["fichas"] if f["estado"] != "feito"]
        if not abertas or any(f["estado"] in NO_AR for f in s["fichas"]):
            continue
        motivos = []
        aceitos = {"pronta", "a fazer"} if s["letra"] in bases else {"pronta"}
        falta = [f"{f['codigo']} ({f['estado']})" for f in abertas if f["estado"] not in aceitos]
        if falta:
            motivos.append("a enriquecer ou revisar: " + ", ".join(falta))
        dentro = {f["codigo"] for f in s["fichas"]}
        fora = []
        for f in abertas:
            for d in f["deps"]:
                if d not in dentro and fichas[d][1]["estado"] != "feito":
                    fora.append(f"{d} ({fichas[d][1]['estado']})")
        if fora:
            motivos.append("dependências não feitas: " + ", ".join(dict.fromkeys(fora)))
        seguram = [l["decide"] for l in espera if segura(l, s)]
        if seguram:
            motivos.append("espera a Vitória: " + "; ".join(seguram))
        arquivos = list(dict.fromkeys(a for f in abertas for a in f["arquivos"]))
        for nome, c in em_voo.items():
            x = cruzamento(arquivos, c["arquivos"])
            if x:
                motivos.append(f"arquivos em voo com {nome}: " + ", ".join(x))
        if motivos:
            bloqueadas.append({"secao": s["letra"], "motivos": motivos})
            continue
        prontas.append({"secao": s["letra"], "nome": s["nome"], "base": s["letra"] in bases,
                        "fichas": [f["codigo"] for f in abertas],
                        "caminhos": [str((pasta / f["arquivo"]).relative_to(raiz)) for f in abertas],
                        "arquivos": arquivos, "estimado": [f["codigo"] for f in abertas if f["estimado"]]})

    vagas = max(0, a.limite - len(em_voo))
    escolhidas, na_fila = [], []
    for p in prontas:
        if len(escolhidas) >= vagas:
            na_fila.append({"secao": p["secao"], "motivo": f"o limite de {a.limite} conjuntos juntos"})
            continue
        x = [(e["secao"], cruzamento(p["arquivos"], e["arquivos"])) for e in escolhidas]
        x = [(sec, arqs) for sec, arqs in x if arqs]
        if x:
            na_fila.append({"secao": p["secao"], "motivo": "; ".join(
                f"arquivos com a seção {sec}: {', '.join(arqs)}" for sec, arqs in x)})
            continue
        escolhidas.append(p)

    json.dump({"prontas_para_despachar": escolhidas, "na_fila": na_fila, "em_voo": em_voo,
               "espera_ela": saida_espera, "bloqueadas": bloqueadas, "dependencias_em_texto": em_texto},
              sys.stdout, ensure_ascii=False, indent=2)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
