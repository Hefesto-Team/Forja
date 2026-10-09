#!/usr/bin/env python3
"""Importa para o jogo os pacotes da Kenney que a curadoria aceita (docs/jogo/14, ficha G10).

    python3 scripts/importar_kenney.py <pasta> [<pasta>...]         do All-in-1 em oficina/kenney/ (a versão mais nova)
    python3 scripts/importar_kenney.py --de <zip ou pasta> <pasta>  de outro lugar (o All-in-1, ou a pasta de um pacote)
    python3 scripts/importar_kenney.py --lista                      o que a curadoria aceita

`<pasta>` é a pasta de destino em godot/assets/kenney/ (a tabela APROVADOS). Cada pacote mora na pasta
dele: o `Textures/colormap.png` de um pacote sobrescreveria o do outro. Copia só os `Models/GLB format/*.glb`
do filtro, a `Textures/` irmã e o `License.txt`; escreve o `.import` da paleta sem compressão; e acerta
a linha da pasta em godot/assets/LEIA-ME.md e em LICENCAS-DE-TERCEIROS.md.

Todo `character-*.glb` passa antes pelo conferidor (scripts/conferir_bonecos.py): o que reprova não é copiado.
Interface e áudio não passam por aqui (a interface é da G11; o som entra pelo mapa do áudio).
Só a biblioteca padrão. Sai com 1 se algum boneco reprovou, 2 se o pedido não é aceito.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent
sys.path.insert(0, str(AQUI))
import kenney  # noqa: E402  (o catálogo e a busca do All-in-1 são de lá; não se copia o código)

PERSONAGENS = ("character-",)


def so_personagens(nomes):
    return lambda n: n in nomes


## pasta de destino -> (pacote no catálogo, papel, o filtro em palavras, o filtro)
APROVADOS = {
    "mini-dungeon": ("Mini Dungeon", "cenario", "tudo menos character-*",
                     lambda n: not n.startswith(PERSONAGENS)),
    "mini-dungeon-personagens": ("Mini Dungeon", "personagem", "character-orc, character-human",
                                 so_personagens({"character-orc", "character-human"})),
    "mini-characters": ("Mini Characters", "personagem", "character-*",
                        lambda n: n.startswith(PERSONAGENS)),
    "cube-pets": ("Cube Pets", "peca", "animal-fox", so_personagens({"animal-fox"})),
    "graveyard-kit": ("Graveyard Kit", "cenario", "tudo", lambda n: True),
    "castle-kit": ("Castle Kit", "cenario", "tudo", lambda n: True),
    "factory-kit": ("Factory Kit", "cenario", "tudo", lambda n: True),
}

IMPORT_DA_PALETA = """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://{caminho}"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


def lista():
    print("O que a curadoria aceita (docs/jogo/14):")
    for pasta, (pacote, papel, filtro, _f) in APROVADOS.items():
        print("  %-26s %-16s %-10s %s" % (pasta, pacote, papel, filtro))


# ------------------------------------------------------------------ achar o pacote --

def _exato(catalogo, nome):
    """O pacote do catálogo com este nome (sem acento nem caixa). Devolve (pacote, caminho relativo)."""
    for c in catalogo:
        for p in c["packs"]:
            if kenney.nu(p["name"]) == kenney.nu(nome):
                return p, Path(p["preview"]).parent
    raise SystemExit("o pacote %r não está no catálogo (assets.json)" % nome)


def achar_no_diretorio(raiz, nome):
    """A pasta do pacote dentro de `raiz`: o catálogo, ou a própria pasta, ou uma que tem o nome dele."""
    if (raiz / "assets.json").is_file():
        _pasta, cats = kenney.catalogo(raiz)
        _p, rel = _exato(cats, nome)
        return raiz / rel
    if (raiz / "Models" / "GLB format").is_dir():
        return raiz
    for cand in sorted(raiz.rglob("GLB format")):
        pacote = cand.parent.parent
        if kenney.nu(pacote.name) == kenney.nu(nome):
            return pacote
    raise SystemExit("não achei o pacote %r em %s" % (nome, raiz))


def achar_no_zip(caminho, nome, temp):
    """Extrai só a pasta do pacote do zip (o All-in-1 tem 1,3 GB) e devolve onde ficou."""
    with zipfile.ZipFile(caminho) as z:
        membros = z.namelist()
        prefixo = None
        catalogos = [m for m in membros if m.endswith("assets.json") and m.count("/") <= 1]
        if catalogos:
            base = catalogos[0][: -len("assets.json")]
            cats = json.loads(z.read(catalogos[0]))["categories"]
            _p, rel = _exato(cats, nome)
            prefixo = base + rel.as_posix() + "/"
        else:
            for m in membros:
                partes = m.split("/")
                if "GLB format" in partes:
                    i = partes.index("GLB format")
                    if i >= 2 and kenney.nu(partes[i - 2]) == kenney.nu(nome):
                        prefixo = "/".join(partes[: i - 1]) + "/"
                        break
        if prefixo is None:
            raise SystemExit("não achei o pacote %r em %s" % (nome, caminho))
        for m in membros:
            if m.startswith(prefixo) and not m.endswith("/"):
                destino = Path(temp) / m
                destino.parent.mkdir(parents=True, exist_ok=True)
                with z.open(m) as de, open(destino, "wb") as para:
                    shutil.copyfileobj(de, para)
        return Path(temp) / prefixo.rstrip("/")


def achar_o_pacote(fonte, nome, temp):
    if fonte is None:
        pasta = kenney.pasta_do_pacote()
        return achar_no_diretorio(pasta, nome)
    fonte = Path(fonte)
    if fonte.is_file() and zipfile.is_zipfile(fonte):
        return achar_no_zip(fonte, nome, temp)
    if fonte.is_dir():
        return achar_no_diretorio(fonte, nome)
    raise SystemExit("--de %s: não é um zip nem uma pasta" % fonte)


# ------------------------------------------------------------------ copiar --

def versao_do_pacote(pasta_do_pacote):
    """O número entre parênteses da linha do nome no License.txt: «Mini Characters (1.0)» dá 1.0."""
    lic = pasta_do_pacote / "License.txt"
    if lic.is_file():
        for linha in lic.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^\s*(.+?) \((\d+(?:\.\d+)*)\)\s*$", linha)
            if m:
                return m.group(2)
    return "?"


def conferir(arquivo):
    """Roda o conferidor de bonecos no arquivo de origem. Devolve (passou, a linha que ele disse)."""
    r = subprocess.run([sys.executable, str(AQUI / "conferir_bonecos.py"), str(arquivo)],
                       capture_output=True, text=True)
    return r.returncode == 0, (r.stdout.strip().splitlines() or [r.stderr.strip()])[0]


def importar(pasta, fonte, assets):
    if pasta not in APROVADOS:
        print("fora da curadoria: veja docs/jogo/14 (%s)" % pasta)
        return 2, None
    pacote, papel, _filtro, aceita = APROVADOS[pasta]
    with tempfile.TemporaryDirectory(prefix="importar-kenney-") as temp:
        origem = achar_o_pacote(fonte, pacote, temp)
        glbs = origem / "Models" / "GLB format"
        if not glbs.is_dir():
            print("%s: sem Models/GLB format em %s" % (pasta, origem))
            return 2, None
        destino = assets / "kenney" / pasta
        destino.mkdir(parents=True, exist_ok=True)
        copiados, recusados = 0, 0
        for f in sorted(glbs.glob("*.glb")):
            if not aceita(f.stem):
                continue
            if f.stem.startswith("character-"):
                passou, linha = conferir(f)
                if not passou:
                    recusados += 1
                    print(linha)
                    continue
            shutil.copy2(f, destino / f.name)
            copiados += 1
        texturas = glbs / "Textures"
        if not texturas.is_dir():
            texturas = origem / "Textures"
        if texturas.is_dir():
            shutil.copytree(texturas, destino / "Textures", dirs_exist_ok=True)
            paleta = destino / "Textures" / "colormap.png"
            if paleta.is_file():
                caminho = paleta.resolve().relative_to(assets.resolve().parent).as_posix()
                (destino / "Textures" / "colormap.png.import").write_text(
                    IMPORT_DA_PALETA.format(caminho=caminho), encoding="utf-8")
        if (origem / "License.txt").is_file():
            shutil.copy2(origem / "License.txt", destino / "License.txt")
        versao = versao_do_pacote(origem)
    print("%-26s %2d peças copiadas, %d recusadas pelo conferidor (%s %s, %s)" % (pasta, copiados, recusados, pacote, versao, papel))
    return (1 if recusados else 0), (pacote, versao, papel, copiados)


# ------------------------------------------------------------------ as linhas de licença --

def _trocar_linha(arquivo, chave, linha, apagar_antes=()):
    """A linha que contém `chave` vira `linha`; sem ela, entra depois da última linha da tabela (ou da `apagar_antes`)."""
    if not arquivo.is_file():
        return
    linhas = arquivo.read_text(encoding="utf-8").split("\n")
    linhas = [x for x in linhas if not any(x.startswith(p) for p in apagar_antes)]
    for i, x in enumerate(linhas):
        if x.startswith("|") and chave in x:
            linhas[i] = linha
            arquivo.write_text("\n".join(linhas), encoding="utf-8")
            return
    ultima = max((i for i, x in enumerate(linhas) if x.startswith("| `kenney/") or x.startswith("| Mini Dungeon")
                  or x.startswith("| ") and "Kenney" in x), default=-1)
    if ultima < 0:
        ultima = max((i for i, x in enumerate(linhas) if x.startswith("|")), default=len(linhas) - 1)
    linhas.insert(ultima + 1, linha)
    arquivo.write_text("\n".join(linhas), encoding="utf-8")


def escrever_licencas(pasta, info, assets, licencas):
    pacote, versao, papel, n = info
    _trocar_linha(assets / "LEIA-ME.md", "`kenney/%s/`" % pasta,
                  "| `kenney/%s/` | %s (%s), %d modelos | Kenney (www.kenney.nl), %s %s | CC0, `kenney/%s/License.txt` |"
                  % (pasta, pacote, papel, n, pacote, versao, pasta),
                  apagar_antes=("| `kenney/` |",))
    _trocar_linha(licencas, "`kenney/%s/`" % pasta,
                  "| %s %s (`kenney/%s/`) | Kenney (www.kenney.nl) | CC0 1.0 |" % (pacote, versao, pasta),
                  apagar_antes=("| Mini Dungeon |",))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pastas", nargs="*", help="as pastas de destino (veja --lista)")
    ap.add_argument("--de", help="um zip ou uma pasta, em vez do All-in-1 de oficina/kenney/")
    ap.add_argument("--lista", action="store_true", help="o que a curadoria aceita")
    ap.add_argument("--assets", default=str(RAIZ / "godot" / "assets"), help="a pasta assets do jogo (a prova usa uma temporária)")
    ap.add_argument("--licencas", default=str(RAIZ / "LICENCAS-DE-TERCEIROS.md"))
    a = ap.parse_args(argv)
    if a.lista:
        lista()
        return 0
    if not a.pastas:
        ap.print_usage()
        return 2
    rc = 0
    for pasta in a.pastas:
        r, info = importar(pasta, a.de, Path(a.assets))
        rc = max(rc, r)
        if info:
            escrever_licencas(pasta, info, Path(a.assets), Path(a.licencas))
    return rc


if __name__ == "__main__":
    sys.exit(main())
