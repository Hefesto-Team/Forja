#!/usr/bin/env python3
"""Confere as tabelas do RPG da Forja e monta um cavaleiro no papel.

Só a biblioteca padrão. Lê os CSV desta pasta, confere que estão coerentes
e imprime as contas que o README cita. Com argumentos, monta um cavaleiro:

    python3 docs/jogo/sistemas/conferir.py                    (confere e conta)
    python3 docs/jogo/sistemas/conferir.py male-c female-f male-a martelo
        (cabeça, superior e inferior pelo personagem; o item pelo id)

Sai com 1 se alguma conferência falhar.
"""
import csv
import itertools
import os
import sys
from collections import Counter

AQUI = os.path.dirname(os.path.abspath(__file__))
ST = ["peso", "passo", "folego", "faro"]
NOME_ST = {"peso": "Peso", "passo": "Passo", "folego": "Fôlego", "faro": "Faro"}
PARTES = ["cabeca", "superior", "inferior"]
falhas = []


def ler(nome):
    with open(os.path.join(AQUI, nome), newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def confere(cond, msg):
    if not cond:
        falhas.append(msg)


REGRAS = {r["chave"]: r["valor"] for r in ler("regras.csv")}
BASE = int(REGRAS["stat_base"])
TETO = int(REGRAS["stat_teto"])
OPOSTO = {}
for par in REGRAS["opostos"].split(";"):
    a, b = par.split(":")
    OPOSTO[a], OPOSTO[b] = b, a

PECAS = ler("pecas.csv")
POR_PARTE = {p: [x for x in PECAS if x["parte"] == p] for p in PARTES}
ITENS = ler("itens.csv")
GANCHOS = ler("stats.csv")
ARQ = ler("arquetipos.csv")
NOMES = ler("nomes.csv")
JOGOS = ler("minigames.csv")


def vetor(peca):
    return [int(peca[s]) for s in ST]


# ---- as conferências ------------------------------------------------------
for p in PARTES:
    lista = POR_PARTE[p]
    confere(len(lista) == 12, f"{p}: {len(lista)} peças, devia ter 12")
    pares = set()
    for x in lista:
        v = vetor(x)
        confere(sum(v) == int(REGRAS["pontos_por_peca"]), f"{x['id']}: soma {sum(v)}")
        confere(sorted(v) == [0, 0, 1, 2], f"{x['id']}: perfil {v} não é +2 e +1")
        confere(ST[v.index(2)] == x["principal"], f"{x['id']}: principal errado")
        confere(len(x["nome"]) <= 14, f"{x['id']}: nome com mais de 14 letras")
        pares.add((v.index(2), v.index(1)))
    confere(len(pares) == 12, f"{p}: os 12 pares (principal, secundário) não aparecem uma vez cada")

for g in GANCHOS:
    n, pp = float(g["neutro"]), float(g["por_ponto"])
    for s in range(1, 6):
        confere(abs(float(g[f"valor_{s}"]) - (n + pp * (s - 3))) < 1e-6,
                f"stats.csv {g['gancho']}: valor_{s} não bate com a conta")
IDS_GANCHO = {g["gancho"] for g in GANCHOS} | {"medley"}
confere(len(JOGOS) == 45, f"minigames.csv: {len(JOGOS)} linhas, devia ter 45")
for j in JOGOS:
    for h in filter(None, j["ganchos"].split(";")):
        confere(h in IDS_GANCHO, f"minigame {j['n']}: gancho {h} não existe")
for a in ARQ:
    if a["raro"] == "nao":
        n = [x for x in NOMES if x["arquetipo"] == a["id"]]
        confere(len(n) == 6, f"nomes.csv: {a['id']} tem {len(n)} nomes, devia ter 6")
for x in NOMES:
    confere(int(REGRAS["nome_minimo"]) <= len(x["nome"]) <= int(REGRAS["nome_maximo"]),
            f"nomes.csv: {x['nome']} fora do tamanho")


# ---- as contas ------------------------------------------------------------
def stats(trio):
    bruto = [BASE] * 4
    for peca in trio:
        for i, v in enumerate(vetor(peca)):
            bruto[i] += v
    com_teto = [min(TETO, v) for v in bruto]
    return com_teto, sum(bruto) - sum(com_teto)


def valido(trio):
    principais = {p["principal"] for p in trio}
    return not any(OPOSTO[s] in principais for s in principais)


def arquetipo(s, trio):
    prin = Counter(p["principal"] for p in trio)
    dois = sorted(range(4), key=lambda i: (-s[i], -prin[ST[i]], i))[:2]
    par = {ST[i] for i in dois}
    return next(a for a in ARQ if {a["stat_a"], a["stat_b"]} == par)


def pede(item, s, chave="pede"):
    return all(s[i] >= int(item[f"{chave}_{st}"]) for i, st in enumerate(ST))


def coerente(item, s):
    dois = set(sorted(range(4), key=lambda i: (-s[i], i))[:2])
    return all(i in dois for i, st in enumerate(ST) if int(item[f"pede_{st}"]) > 0)


def chaves(trio):
    prin = {p["principal"] for p in trio}
    corpo = "Peso" if "peso" in prin else "Passo" if "passo" in prin else "meio"
    espirito = "Fôlego" if "folego" in prin else "Faro" if "faro" in prin else "meio"
    return corpo, espirito


def uma_troca_da_liga(trio, item):
    for k in range(3):
        for nova in POR_PARTE[PARTES[k]]:
            if nova is trio[k]:
                continue
            t = list(trio)
            t[k] = nova
            if valido(t):
                s, _ = stats(t)
                if pede(item, s, "liga"):
                    return True
    return False


def todos():
    for trio in itertools.product(*(POR_PARTE[p] for p in PARTES)):
        if valido(trio):
            yield trio


def contar():
    total = 12 ** 3
    validos = desp = 0
    perdidos, arqs, n_itens = Counter(), Counter(), Counter()
    cabe, liga = Counter(), Counter()
    boas = sorteaveis = 0
    sort_arq = Counter()
    for trio in todos():
        validos += 1
        s, w = stats(trio)
        perdidos[w] += 1
        a = arquetipo(s, trio)
        arqs[a["nome"]] += 1
        possiveis = [i for i in ITENS if pede(i, s)]
        n_itens[len(possiveis)] += 1
        for i in possiveis:
            cabe[i["nome"]] += 1
            if pede(i, s, "liga"):
                liga[i["nome"]] += 1
        if w == 0 and any(coerente(i, s) and pede(i, s, "liga") for i in possiveis):
            boas += 1
        if w == 0 and a["raro"] == "nao":
            ok = [i for i in possiveis if coerente(i, s) and not pede(i, s, "liga")
                  and uma_troca_da_liga(trio, i)]
            if ok:
                sorteaveis += 1
                sort_arq[a["nome"]] += 1
    print(f"corpos: {total}; válidos pela regra dos opostos: {validos} ({100 * validos / total:.0f} %)")
    print(f"pontos perdidos no teto: {dict(sorted(perdidos.items()))}")
    print(f"arquétipos: {dict(arqs.most_common())}")
    print(f"itens possíveis por corpo: {dict(sorted(n_itens.items()))}")
    print(f"corpos que podem levar cada item: {dict(cabe.most_common())}")
    print(f"corpos em liga com cada item: {dict(liga.most_common())}")
    print(f"corpos com build boa possível: {boas}")
    print(f"corpos sorteáveis no pré-montado: {sorteaveis} {dict(sort_arq.most_common())}")
    originais = []
    for c in sorted({p["personagem"] for p in PECAS}):
        trio = [next(p for p in POR_PARTE[k] if p["personagem"] == c) for k in PARTES]
        confere(valido(trio), f"o personagem original {c} não passa na regra")
        s, w = stats(trio)
        originais.append(f"{c} {s} {arquetipo(s, trio)['nome']}" + (f" perde {w}" if w else ""))
    print("os originais: " + "; ".join(originais))


def peca(parte, chave):
    for p in POR_PARTE[parte]:
        if chave in (p["personagem"], p["id"]):
            return p
    sys.exit(f"não achei a peça {chave} em {parte}")


def montar(args):
    trio = [peca(PARTES[k], args[k]) for k in range(3)]
    item = next((i for i in ITENS if i["id"] == args[3]), None) if len(args) > 3 else None
    for k, p in enumerate(trio):
        print(f"{PARTES[k]:9} {p['nome']:15} +2 {NOME_ST[p['principal']]}")
    if not valido(trio):
        print("TRAVADO: duas peças com principais opostos (Peso e Passo, ou Fôlego e Faro)")
        return
    s, w = stats(trio)
    for i, st in enumerate(ST):
        print(f"  {NOME_ST[st]:7} {'#' * s[i]}{'.' * (TETO - s[i])} {s[i]}")
    corpo, espirito = chaves(trio)
    print(f"chaves: corpo {corpo}, espírito {espirito}; pontos perdidos: {w}")
    a = arquetipo(s, trio)
    print(f"arquétipo: {a['nome']}" + (" (raro)" if a["raro"] == "sim" else ""))
    print("itens possíveis: " + ", ".join(
        i["nome"] + (" (em liga)" if pede(i, s, "liga") else "") for i in ITENS if pede(i, s)))
    if item:
        if not pede(item, s):
            print(f"{item['nome']}: o corpo não alcança")
        else:
            em_liga = pede(item, s, "liga")
            boa = w == 0 and coerente(item, s) and em_liga
            print(f"{item['nome']}: {'em liga' if em_liga else 'fora da liga'}; build boa: {'sim' if boa else 'não'}")
    print("os ganchos:")
    for g in GANCHOS:
        v = s[ST.index(g["stat"])]
        print(f"  {g['gancho']:10} {g[f'valor_{v}']:>6}  ({g['unidade']})")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        montar(sys.argv[1:])
    else:
        contar()
    for f in falhas:
        print("FALHA:", f)
    sys.exit(1 if falhas else 0)
