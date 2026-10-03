#!/usr/bin/env python3
"""Achar coisa no pacote da Kenney, sem abrir 1,3 GB de pastas.

O All-in-1 vem com um catálogo (`assets.json`): 248 pacotes em seis
categorias, com o caminho de cada arquivo. Este script lê o catálogo e
responde em segundos — para quem procura com os olhos e para quem procura
com um comando.

O pacote fica em `oficina/kenney/<versão>/`, fora do git: é material bruto.
Nada daqui entra no jogo sozinho; o que entra vai para `godot/assets/`,
pela ficha do quadro que decidir.

  python3 scripts/kenney.py                      as categorias e o tamanho de cada uma
  python3 scripts/kenney.py pacotes 3D           os pacotes de uma categoria
  python3 scripts/kenney.py buscar martelo       procura por palavra, em tudo
  python3 scripts/kenney.py ver "Castle Kit"     o que tem dentro de um pacote
  python3 scripts/kenney.py onde "Castle Kit"    o caminho da pasta, para abrir
  python3 scripts/kenney.py --prova              confere sem depender do pacote

A busca é sem acento e sem caixa: «canhao» acha «cannon».
"""
import argparse
import json
import os
import sys
import unicodedata
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
OFICINA = Path(os.environ.get("FORJA_OFICINA", RAIZ / "oficina")) / "kenney"

## Palavra em português -> o jeito que a Kenney escreve. A Kenney é toda em
## inglês; sem isto, procurar «martelo» não acha nada.
TRADUZ = {
    "martelo": "hammer", "bigorna": "anvil", "espada": "sword", "escudo": "shield",
    "castelo": "castle", "tijolo": "brick", "torre": "tower", "porta": "door",
    "parede": "wall", "chao": "floor", "pedra": "stone", "rocha": "rock",
    "arvore": "tree", "fogo": "fire", "chama": "flame", "canhao": "cannon",
    "personagem": "character", "boneco": "character", "robo": "robot",
    "carro": "car", "nave": "spaceship", "arma": "blaster", "arco": "bow",
    "som": "audio", "musica": "music", "interface": "ui", "icone": "icon",
    "botao": "button", "moeda": "coin", "bau": "chest", "caixa": "crate",
    "ponte": "bridge", "escada": "stairs", "grade": "fence", "bandeira": "banner",
}


def nu(texto):
    """Sem acento, sem caixa, para comparar."""
    return "".join(c for c in unicodedata.normalize("NFD", str(texto).lower())
                   if unicodedata.category(c) != "Mn")


def pasta_do_pacote():
    """A versão mais nova do All-in-1 que estiver em oficina/kenney/."""
    if not OFICINA.is_dir():
        raise SystemExit("o pacote da Kenney não está em %s.\n"
                         "Descompacte o All-in-1 ali (é material bruto, fora do git)." % OFICINA)
    achados = sorted((p for p in OFICINA.iterdir() if (p / "assets.json").is_file()),
                     key=lambda p: p.name, reverse=True)
    if not achados:
        raise SystemExit("não achei nenhum assets.json em %s/*/" % OFICINA)
    return achados[0]


def catalogo(pasta=None):
    pasta = pasta or pasta_do_pacote()
    with open(pasta / "assets.json", encoding="utf-8") as f:
        return pasta, json.load(f)["categories"]


def arquivos_do_pacote(pacote):
    for p in pacote.get("folders", []):
        for a in p.get("files", []):
            yield a


# ------------------------------------------------------------------ as vistas --

def categorias(cats, pasta):
    print("O pacote: %s" % pasta)
    print()
    for c in cats:
        n = sum(1 for p in c["packs"] for _ in arquivos_do_pacote(p))
        print("  %-12s %3d pacotes, %5d arquivos" % (c["name"], len(c["packs"]), n))
    print()
    print("  Para ver os de uma categoria:  scripts/kenney.py pacotes 3D")


def pacotes(cats, alvo):
    achou = False
    for c in cats:
        if nu(alvo) not in nu(c["name"]):
            continue
        achou = True
        print("%s — %d pacotes" % (c["name"], len(c["packs"])))
        for p in sorted(c["packs"], key=lambda x: x["name"]):
            n = sum(1 for _ in arquivos_do_pacote(p))
            print("  %-42s %4d arquivos" % (p["name"], n))
    if not achou:
        print("não achei a categoria %r. As que existem: %s"
              % (alvo, ", ".join(c["name"] for c in cats)))


def buscar(cats, palavra, limite=40):
    alvos = {nu(palavra)}
    if nu(palavra) in TRADUZ:
        alvos.add(TRADUZ[nu(palavra)])
        print("(«%s» em inglês é «%s»)\n" % (palavra, TRADUZ[nu(palavra)]))

    por_pacote = []
    arquivos = []
    for c in cats:
        for p in c["packs"]:
            if any(a in nu(p["name"]) for a in alvos):
                por_pacote.append((c["name"], p))
                continue
            for arq in arquivos_do_pacote(p):
                if any(a in nu(Path(arq).name) for a in alvos):
                    arquivos.append((c["name"], p["name"], arq))

    if por_pacote:
        print("Pacotes com esse nome:")
        for cat, p in por_pacote:
            n = sum(1 for _ in arquivos_do_pacote(p))
            print("  [%s] %-40s %d arquivos" % (cat, p["name"], n))
        print()
    if arquivos:
        print("Arquivos (%d achados%s):" % (len(arquivos), ", mostrando os %d primeiros" % limite
                                            if len(arquivos) > limite else ""))
        for cat, pac, arq in arquivos[:limite]:
            print("  [%s] %s" % (pac, arq))
        if len(arquivos) > limite:
            print("  …")
    if not por_pacote and not arquivos:
        print("Nada com «%s». Tente em inglês, ou veja as categorias: scripts/kenney.py" % palavra)


def ver(cats, alvo, pasta):
    for c in cats:
        for p in c["packs"]:
            if nu(alvo) not in nu(p["name"]):
                continue
            print("%s  [%s]" % (p["name"], c["name"]))
            print("  pasta: %s" % (pasta / Path(p["preview"]).parent))
            if p.get("preview"):
                print("  amostra: %s" % (pasta / p["preview"]))
            for sub in p.get("folders", []):
                arqs = sub.get("files", [])
                print("  %s/ — %d arquivos" % (sub.get("name", "?"), len(arqs)))
                for a in arqs[:6]:
                    print("      %s" % Path(a).name)
                if len(arqs) > 6:
                    print("      … e mais %d" % (len(arqs) - 6))
            return
    print("não achei o pacote %r. Procure: scripts/kenney.py buscar %s" % (alvo, alvo))


def onde(cats, alvo, pasta):
    for c in cats:
        for p in c["packs"]:
            if nu(alvo) in nu(p["name"]):
                print(pasta / Path(p["preview"]).parent)
                return
    raise SystemExit("não achei o pacote %r" % alvo)


# ------------------------------------------------------------------ a prova --

def prova():
    falhas = 0

    def confere(ok, frase):
        nonlocal falhas
        print(("ok   " if ok else "FAIL ") + frase)
        falhas += 0 if ok else 1

    confere(nu("Canhão") == "canhao", "a busca tira o acento e a caixa")
    confere(TRADUZ["martelo"] == "hammer", "a tabela traduz o que a gente procura")
    falso = [{"name": "3D assets", "packs": [
        {"name": "Castle Kit", "preview": "3D assets/Castle Kit/Preview.png",
         "folders": [{"name": "Models", "files": ["3D assets/Castle Kit/Models/wall-hammer.glb"]}]}]}]
    confere(sum(1 for _ in arquivos_do_pacote(falso[0]["packs"][0])) == 1,
            "os arquivos de um pacote se contam")
    if OFICINA.is_dir():
        try:
            pasta, cats = catalogo()
            confere(len(cats) >= 5, "o catálogo de verdade tem as categorias (%d)" % len(cats))
            total = sum(1 for c in cats for p in c["packs"] for _ in arquivos_do_pacote(p))
            confere(total > 1000, "o catálogo lista %d arquivos" % total)
        except SystemExit as e:
            confere(False, "o catálogo de verdade: %s" % e)
    else:
        print("ok   sem o pacote baixado, a prova conferiu só as partes puras")
    return falhas


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("comando", nargs="?", choices=["pacotes", "buscar", "ver", "onde"])
    ap.add_argument("alvo", nargs="?")
    ap.add_argument("--prova", action="store_true")
    a = ap.parse_args()
    if a.prova:
        sys.exit(1 if prova() else 0)
    pasta, cats = catalogo()
    if not a.comando:
        categorias(cats, pasta)
    elif not a.alvo:
        ap.error("falta o quê: scripts/kenney.py %s <alvo>" % a.comando)
    elif a.comando == "pacotes":
        pacotes(cats, a.alvo)
    elif a.comando == "buscar":
        buscar(cats, a.alvo)
    elif a.comando == "ver":
        ver(cats, a.alvo, pasta)
    else:
        onde(cats, a.alvo, pasta)


if __name__ == "__main__":
    main()
