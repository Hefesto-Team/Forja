#!/usr/bin/env python3
"""Confere um boneco .glb antes de ele entrar no Forja (docs/jogo/arte/04).

    python3 scripts/conferir_bonecos.py                 os character-*.glb de godot/assets/kenney
    python3 scripts/conferir_bonecos.py <arquivo|pasta>...
    python3 scripts/conferir_bonecos.py --teste         a prova da mordida

Uma linha por arquivo: PASSOU ou FALHOU e o porquê. Sai com 1 se algum falhou.
"""
import json
import pathlib
import struct
import sys

OSSOS = ["root", "leg-left", "leg-right", "torso", "arm-left", "arm-right", "head"]
PAI = {"leg-left": "root", "leg-right": "root", "torso": "root",
       "arm-left": "torso", "arm-right": "torso", "head": "torso"}
ANIMACOES = ["idle", "walk", "sprint", "jump", "fall", "die", "emote-yes", "emote-no",
             "attack-melee-right", "holding-right", "static", "interact-right"]
TRIANGULOS = 1500
ALTURA = 0.755
RAIZ = pathlib.Path(__file__).resolve().parent.parent


def ler(caminho):
    b = pathlib.Path(caminho).read_bytes()
    if b[:4] != b"glTF":
        raise ValueError("não é glTF binário")
    n = struct.unpack("<I", b[12:16])[0]
    return json.loads(b[20:20 + n])


def conferir(j, pasta):
    falhas = []
    nos = j.get("nodes", [])
    nome = lambda i: nos[i].get("name", "")
    pai = {}
    for n in nos:
        for c in n.get("children", []):
            pai[nome(c)] = n.get("name", "")
    if j.get("skins"):
        tipo = "skin"
        for s in j["skins"]:
            juntas = [nome(i) for i in s["joints"]]
            if sorted(juntas) != sorted(OSSOS):
                falhas.append(f"ossos {juntas}")
    else:
        tipo = "rígido"
        por_nome = {n.get("name", ""): n for n in nos}
        faltam = [o for o in OSSOS if o not in por_nome]
        if faltam:
            falhas.append(f"ossos {faltam} faltam")
        tem_malha = lambda n: "mesh" in n or any("mesh" in nos[c] for c in n.get("children", []))
        if "head" in por_nome and not tem_malha(por_nome["head"]):
            falhas.append("head sem malha")
    for osso, p in PAI.items():
        if pai.get(osso) != p:
            falhas.append(f"{osso} pendurado em {pai.get(osso)!r}, não em {p!r}")
    anims = {a.get("name", "") for a in j.get("animations", [])}
    faltam = [a for a in ANIMACOES if a not in anims]
    if faltam:
        falhas.append(f"faltam as animações {faltam}")
    tri, alto, baixo = 0, -1e9, 1e9
    for m in j.get("meshes", []):
        for p in m["primitives"]:
            pos = j["accessors"][p["attributes"]["POSITION"]]
            alto, baixo = max(alto, pos["max"][1]), min(baixo, pos["min"][1])
            conta = j["accessors"][p["indices"]]["count"] if "indices" in p else pos["count"]
            tri += conta // 3
    if tri > TRIANGULOS:
        falhas.append(f"{tri} triângulos (máximo {TRIANGULOS})")
    if tipo == "skin" and abs(alto - ALTURA) > ALTURA * 0.15:
        falhas.append(f"altura {alto:.3f} (a do kit é {ALTURA})")
    if tipo == "skin" and abs(baixo) > 0.03:
        falhas.append(f"a origem não está nos pés (o mais baixo em {baixo:.3f})")
    for mat in j.get("materials", []):
        metal = mat.get("pbrMetallicRoughness", {}).get("metallicFactor", 1.0)
        if metal > 0.2:
            falhas.append(f"material {mat.get('name')!r} com metallic {metal} (máximo 0,2)")
    for img in j.get("images", []):
        if "uri" in img and not (pasta / img["uri"]).exists():
            falhas.append(f"a textura {img['uri']} não está ao lado do .glb")
    return falhas, tri, len(anims), tipo


def arquivos(args):
    alvos = [pathlib.Path(a) for a in args] or [RAIZ / "godot/assets/kenney"]
    for a in alvos:
        yield from (sorted(a.rglob("character-*.glb")) if a.is_dir() else [a])


def teste():
    f = next(arquivos([]))
    j = ler(f)
    bom = conferir(j, f.parent)[0]
    for n in j["nodes"]:
        if n.get("name") == "head":
            n["name"] = "cabeca"
    j["animations"] = [a for a in j["animations"] if a.get("name") != "idle"]
    ruim = conferir(j, f.parent)[0]
    ok = not bom and any("ossos" in x for x in ruim) and any("idle" in x for x in ruim)
    print("PASSOU  a mordida: o boneco passa; sem 'head' e sem 'idle', falha" if ok else f"FALHOU  a mordida: {bom} / {ruim}")
    return 0 if ok else 1


def main():
    if sys.argv[1:] == ["--teste"]:
        return teste()
    rc = 0
    for f in arquivos(sys.argv[1:]):
        falhas, tri, n, tipo = conferir(ler(f), f.parent)
        rel = f.resolve().relative_to(RAIZ) if f.resolve().is_relative_to(RAIZ) else f.name
        if falhas:
            rc = 1
            print(f"FALHOU  {rel}: " + "; ".join(falhas))
        else:
            print(f"PASSOU  {rel} ({tipo}, {tri} triângulos, {n} animações)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
