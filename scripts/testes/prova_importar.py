#!/usr/bin/env python3
"""A prova do importador da Kenney (ficha G10): monta um zip de mentira com a estrutura do All-in-1 e confere.

    python3 scripts/testes/prova_importar.py

O boneco que passa é uma cópia do character-male-a.glb do All-in-1 de oficina/kenney/; os dois que reprovam são
ele com o JSON do glTF editado aqui (o nó `head` renomeado; a animação `emote-yes` renomeada). Sem o All-in-1 na
máquina, diz «sem o All-in-1» e sai com 0.
"""
import json
import struct
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(RAIZ / "scripts"))
import kenney  # noqa: E402

falhas = 0


def confere(cond, msg):
    global falhas
    print(("ok   " if cond else "FAIL ") + msg)
    if not cond:
        falhas += 1


def ler_glb(b):
    n = struct.unpack("<I", b[12:16])[0]
    return json.loads(b[20:20 + n]), b[20 + n:]


def gravar_glb(j, resto):
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * (-len(js) % 4)
    corpo = struct.pack("<II", len(js), 0x4E4F534A) + js + resto
    return b"glTF" + struct.pack("<II", 2, 12 + len(corpo)) + corpo


def sem_o_all_in_1():
    try:
        pasta = kenney.pasta_do_pacote()
    except SystemExit:
        return None
    _p, cats = kenney.catalogo(pasta)
    for c in cats:
        for p in c["packs"]:
            if p["name"] == "Mini Characters":
                f = pasta / Path(p["preview"]).parent / "Models" / "GLB format"
                if (f / "character-male-a.glb").is_file():
                    return f
    return None


def main():
    glb_dir = sem_o_all_in_1()
    if glb_dir is None:
        print("sem o All-in-1 em oficina/kenney/: a prova do importador não tem de onde tirar o boneco")
        return 0
    bom = (glb_dir / "character-male-a.glb").read_bytes()
    paleta = (glb_dir / "Textures" / "colormap.png").read_bytes()
    j, resto = ler_glb(bom)
    seis = json.loads(json.dumps(j))
    for n in seis["nodes"]:
        if n.get("name") == "head":
            n["name"] = "cabeca"
    sem_emote = json.loads(json.dumps(j))
    for a in sem_emote["animations"]:
        if a.get("name") == "emote-yes":
            a["name"] = "emote-sim"
    pecas = bom   # as peças do kit de cenário não passam pelo conferidor: qualquer glb serve

    base = "3D assets/"
    cat = {"categories": [
        {"name": "3D assets", "packs": [
            {"name": "Mini Characters", "preview": base + "Mini Characters/Preview.png", "folders": []},
            {"name": "Castle Kit", "preview": base + "Castle Kit/Preview.png", "folders": []}]},
        {"name": "2D assets", "packs": [
            {"name": "Pixel Platformer", "preview": "2D assets/Pixel Platformer/Preview.png", "folders": []}]}]}
    with tempfile.TemporaryDirectory(prefix="prova-importar-") as t:
        t = Path(t)
        zip_ = t / "all-in-1.zip"
        with zipfile.ZipFile(zip_, "w") as z:
            z.writestr("assets.json", json.dumps(cat))
            mc = base + "Mini Characters/"
            z.writestr(mc + "License.txt", "\n\tMini Characters (1.0)\n\n\tLicense: (Creative Commons Zero, CC0)\n")
            z.writestr(mc + "Models/GLB format/character-male-a.glb", bom)
            z.writestr(mc + "Models/GLB format/character-seis-ossos.glb", gravar_glb(seis, resto))
            z.writestr(mc + "Models/GLB format/character-sem-emote.glb", gravar_glb(sem_emote, resto))
            z.writestr(mc + "Models/GLB format/aid-cane.glb", pecas)
            z.writestr(mc + "Models/GLB format/Textures/colormap.png", paleta)
            ck = base + "Castle Kit/"
            z.writestr(ck + "License.txt", "\n\tCastle Kit (2.0)\n\n\tLicense: (Creative Commons Zero, CC0)\n")
            for nome in ("tower-base", "wall", "gate"):
                z.writestr(ck + "Models/GLB format/%s.glb" % nome, pecas)
            z.writestr(ck + "Models/GLB format/Textures/colormap.png", paleta)
            z.writestr("2D assets/Pixel Platformer/License.txt", "\n\tPixel Platformer (1.0)\n")
            z.writestr("2D assets/Pixel Platformer/Tilemap/tile.png", paleta)
        assets = t / "godot" / "assets"
        (assets / "kenney").mkdir(parents=True)
        (assets / "LEIA-ME.md").write_text("| pasta | o que é |\n|---|---|\n| `kenney/` | modelos Mini Dungeon | Kenney | CC0 |\n| `ost/` | a trilha | x | y |\n")
        licencas = t / "LICENCAS-DE-TERCEIROS.md"
        licencas.write_text("| o quê | de onde | licença |\n| --- | --- | --- |\n| Mini Dungeon | Kenney (www.kenney.nl) | CC0 1.0 |\n| SDL | x | zlib |\n")

        def rodar(*args):
            return subprocess.run([sys.executable, str(RAIZ / "scripts" / "importar_kenney.py"), "--assets", str(assets),
                                   "--licencas", str(licencas), *args], capture_output=True, text=True)

        r = rodar("--de", str(zip_), "mini-characters")
        pasta = assets / "kenney" / "mini-characters"
        copiados = sorted(p.name for p in pasta.glob("*.glb"))
        confere(copiados == ["character-male-a.glb"], "copia só o que o filtro pega e o conferidor aprova (%s)" % copiados)
        confere(r.returncode == 1 and "character-seis-ossos" in r.stdout and "character-sem-emote" in r.stdout
                and r.stdout.count("FALHOU") == 2,
                "os dois que reprovam repetem a linha FALHOU e o script sai com 1 (%d)" % r.returncode)
        confere("ossos" in r.stdout and "emote-yes" in r.stdout, "a linha FALHOU diz o porquê (os ossos e a animação)")
        confere((pasta / "Textures" / "colormap.png").is_file() and (pasta / "License.txt").is_file(),
                "copia a Textures/ e o License.txt do pacote")
        imp = (pasta / "Textures" / "colormap.png.import")
        confere(imp.is_file() and "compress/mode=0" in imp.read_text() and "res://assets/kenney/mini-characters/Textures/colormap.png" in imp.read_text(),
                "o .import da paleta sem compressão, com o caminho da pasta dela")
        r = rodar("--de", str(zip_), "castle-kit")
        castelo = assets / "kenney" / "castle-kit"
        confere(r.returncode == 0 and len(list(castelo.glob("*.glb"))) == 3, "o kit de cenário entra com as 3 peças")
        confere(not (assets / "kenney" / "Textures").exists(), "nenhuma Textures solta fora da pasta do pacote")
        confere((castelo / "Textures" / "colormap.png").is_file() and (pasta / "Textures" / "colormap.png").is_file(),
                "cada colormap.png fica na pasta do seu pacote")
        r = rodar("--de", str(zip_), "pixel-platformer")
        confere(r.returncode == 2 and "fora da curadoria" in r.stdout and not (assets / "kenney" / "pixel-platformer").exists(),
                "recusa a pasta fora da tabela, sem criar nada (%s)" % r.stdout.strip())
        leia = (assets / "LEIA-ME.md").read_text()
        lic = licencas.read_text()
        confere("`kenney/mini-characters/`" in leia and "`kenney/castle-kit/`" in leia and "| `kenney/` |" not in leia and "ost/" in leia,
                "a linha de cada pasta no LEIA-ME, sem a linha antiga e sem apagar as outras")
        confere("Mini Characters 1.0" in lic and "Castle Kit 2.0" in lic and "| Mini Dungeon |" not in lic and "| SDL |" in lic,
                "a linha de cada pacote nas licenças, com a versão do License.txt")
        rodar("--de", str(zip_), "castle-kit")
        confere(leia == (assets / "LEIA-ME.md").read_text() and lic == licencas.read_text(), "importar de novo não duplica a linha")
        r = subprocess.run([sys.executable, str(RAIZ / "scripts" / "importar_kenney.py"), "--lista"], capture_output=True, text=True)
        confere(all(p in r.stdout for p in ("mini-dungeon-personagens", "cube-pets", "graveyard-kit", "factory-kit")),
                "--lista diz o que a curadoria aceita")
    print("a prova do importador %s" % ("falhou: %d" % falhas if falhas else "ok"))
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main())
