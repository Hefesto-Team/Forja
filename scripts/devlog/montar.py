#!/usr/bin/env python3
"""Monta .cache/devlog/index.html com as entradas de docs/devlog/, a mais nova em cima.

Uso: montar.py [--raiz DIR] [--entrada PASTA]
Copia as fontes de godot/assets/fontes/ e as fotos para .cache/devlog/, lê as cores de godot/scripts/tema.gd
e imprime o caminho do index.html. Sem rede.
"""
import argparse
import html
import re
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cabecalho  # noqa: E402
import jpeg  # noqa: E402

CORES = {
    "FITA": "#0d0a16", "CASCO": "#17121f", "CASCO_ALTO": "#241c30", "GRAFITE": "#3a3346",
    "ETIQUETA": "#efe4c8", "ETIQUETA_SOMBRA": "#cfc2a0", "TINTA": "#1c1626", "TINTA_SUAVE": "#5a4f66",
    "MUDO": "#857a95", "VIOLETA": "#4a3aa8", "VIOLETA_FUNDO": "#1d1638",
}
LISTRAS = ["#c8432f", "#c79a2a"]
FONTES = {
    "Bungee": "Bungee-Regular.ttf",
    "Permanent Marker": "PermanentMarker-Regular.ttf",
    "VT323": "VT323-Regular.ttf",
    "Archivo Narrow": "ArchivoNarrow-wght.ttf",
}


def cores_do_tema(raiz: Path):
    cores, listras = dict(CORES), list(LISTRAS)
    tema = raiz / "godot/scripts/tema.gd"
    if tema.is_file():
        texto = tema.read_text(encoding="utf-8")
        for nome, valor in re.findall(r'^const (\w+) := Color\("(#[0-9a-fA-F]{6})"\)', texto, re.M):
            if nome in cores:
                cores[nome] = valor
        m = re.search(r"^const SECAO := \[(.*?)\]", texto, re.M | re.S)
        if m:
            achadas = re.findall(r'Color\("(#[0-9a-fA-F]{6})"\)', m.group(1))
            if len(achadas) >= 4:
                listras = [achadas[0], achadas[3]]
    return cores, listras


def esc(texto: str) -> str:
    return html.escape(texto, quote=True)


def inline(texto: str) -> str:
    s = esc(texto)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    return re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)


def resumo_html(corpo: str) -> str:
    saida, lista = [], False
    for linha in cabecalho.linhas_do_resumo(corpo):
        item = re.match(r"^\s*[-*]\s+(.*)$", linha)
        if item:
            if not lista:
                saida.append("<ul>")
                lista = True
            saida.append(f"<li>{inline(item.group(1))}</li>")
            continue
        if lista:
            saida.append("</ul>")
            lista = False
        saida.append(f"<p>{inline(linha.strip())}</p>")
    if lista:
        saida.append("</ul>")
    return "\n".join(saida)


def data_br(iso: str) -> str:
    m = re.match(r"^(\d{4})-(\d{2})-(\d{2})$", iso)
    return f"{m.group(3)}/{m.group(2)}/{m.group(1)}" if m else iso


def lista(valor: str) -> list:
    return [x.strip() for x in valor.split(",") if x.strip()]


def copiar_fotos(pasta: Path, destino: Path) -> dict:
    mapa = {}
    for lado in ("antes", "depois"):
        origem = pasta / lado
        mapa[lado] = {}
        if not origem.is_dir():
            continue
        (destino / lado).mkdir(parents=True, exist_ok=True)
        for f in sorted(origem.glob("*.jpg")):
            dados = f.read_bytes()
            shutil.copyfile(f, destino / lado / f.name)
            mapa[lado][f.stem] = (f"{destino.parent.name}/{destino.name}/{lado}/{f.name}", jpeg.medida(dados) or (1280, 720))
    return mapa


def figura(rotulo: str, nome: str, foto, classe: str) -> str:
    if foto is None:
        texto = "não existia" if rotulo == "ANTES" else "saiu"
        return f'<div class="quadro vazio {classe}"><span class="osd">{rotulo}</span><span class="nada">{texto}</span></div>'
    caminho, (w, h) = foto
    return (f'<div class="quadro {classe}"><span class="osd">{rotulo}</span>'
            f'<img class="zoom" src="{esc(caminho)}" width="{w}" height="{h}" loading="lazy" decoding="async" '
            f'alt="{esc(rotulo.lower())}: {esc(nome)}"></div>')


def entrada_html(pasta: Path, cache_fotos: Path) -> tuple:
    campos, corpo = cabecalho.ler(pasta / "entrada.md")
    fotos = copiar_fotos(pasta, cache_fotos / pasta.name)
    nomes = sorted(set(fotos["antes"]) | set(fotos["depois"]))
    pares = [n for n in nomes if n in fotos["antes"] and n in fotos["depois"]]
    so_antes = [n for n in nomes if n in fotos["antes"] and n not in fotos["depois"]]
    so_depois = [n for n in nomes if n in fotos["depois"] and n not in fotos["antes"]]
    fichas = lista(campos.get("fichas", ""))
    iguais = campos.get("iguais", "")
    osd = [f'BASE <b>{esc(campos.get("base", "?"))}</b>', f'TOPO <b>{esc(campos.get("topo", "?"))}</b>',
           f'<b>{len(pares)}</b> PAR' + ("ES" if len(pares) != 1 else "")]
    if so_depois:
        osd.append(f"<b>{len(so_depois)}</b> NOVA" + ("S" if len(so_depois) != 1 else ""))
    if so_antes:
        osd.append(f"<b>{len(so_antes)}</b> SÓ NO ANTES")
    if iguais and iguais != "0":
        osd.append(f"<b>{esc(iguais)}</b> IGUAL" + ("IS" if iguais != "1" else "") + " FORA")
    chips = "".join(f'<span class="ficha">{esc(f)}</span>' for f in fichas)
    quadros = []
    for n in pares + so_depois + so_antes:
        a, d = fotos["antes"].get(n), fotos["depois"].get(n)
        quadros.append(f'<figure class="par"><figcaption class="osd">{esc(n)}</figcaption>'
                       f'<div class="duas">{figura("ANTES", n, a, "antes")}{figura("DEPOIS", n, d, "depois")}</div></figure>')
    fotos_html = "\n".join(quadros) if quadros else '<p class="nada">Esta entrada ainda não tem fotos.</p>'
    ident = re.sub(r"[^a-z0-9-]", "-", pasta.name.lower())
    texto = f"""<article class="cassete" id="{ident}">
<div class="etiqueta">
<div class="listras"><i></i><i></i></div>
<div class="miolo">
<h2>{esc(campos.get("titulo", pasta.name))}</h2>
<p class="marca">{esc(data_br(campos.get("data", "")))} &middot; {esc(campos.get("ramo", ""))}</p>
<div class="resumo">{resumo_html(corpo)}</div>
</div>
</div>
<div class="faixa osd">{" &middot; ".join(osd)}<span class="fichas">{chips}</span></div>
<div class="pares">
{fotos_html}
</div>
</article>"""
    return (campos.get("data", ""), pasta.name), texto


ESTILO = """
:root{color-scheme:dark;--fita:@FITA@;--casco:@CASCO@;--casco-alto:@CASCO_ALTO@;--grafite:@GRAFITE@;--etiqueta:@ETIQUETA@;
--etiqueta-sombra:@ETIQUETA_SOMBRA@;--tinta:@TINTA@;--tinta-suave:@TINTA_SUAVE@;--mudo:@MUDO@;--violeta:@VIOLETA@;
--violeta-fundo:@VIOLETA_FUNDO@;--listra-a:@LISTRA_A@;--listra-b:@LISTRA_B@}
*{box-sizing:border-box}
html{background:var(--fita)}
body{margin:0;background:var(--fita);color:var(--etiqueta);font-family:"Archivo Narrow",system-ui,sans-serif;font-size:19px;line-height:1.4}
main{max-width:1280px;margin:0 auto;padding:32px 16px 96px}
header.topo{display:flex;flex-wrap:wrap;align-items:baseline;gap:8px 24px;margin-bottom:32px;border-bottom:2px solid var(--grafite);padding-bottom:16px}
header.topo h1{font-family:Bungee,sans-serif;font-weight:400;font-size:clamp(34px,6vw,64px);margin:0;letter-spacing:.02em}
.osd{font-family:VT323,monospace;font-size:22px;letter-spacing:.04em;color:var(--etiqueta-sombra)}
.osd b{color:var(--etiqueta);font-weight:400}
.cassete{background:var(--casco);border:2px solid var(--grafite);border-radius:16px;padding:20px;margin:0 0 40px;box-shadow:5px 7px 0 #000}
.etiqueta{background:var(--etiqueta);color:var(--tinta);border-radius:8px;overflow:hidden;box-shadow:inset 0 -6px 0 rgba(0,0,0,.08)}
.listras{display:flex;height:14px}
.listras i{flex:1;background:var(--listra-a)}
.listras i+i{background:var(--listra-b)}
.miolo{padding:16px 24px 20px}
.etiqueta h2{font-family:Bungee,sans-serif;font-weight:400;font-size:clamp(26px,4vw,44px);line-height:1.05;margin:0 0 4px;color:var(--tinta)}
.marca{font-family:"Permanent Marker",cursive;font-size:22px;color:var(--violeta);margin:0 0 12px;transform:rotate(-1deg);transform-origin:left}
.resumo p{margin:0 0 6px}
.resumo ul{margin:0 0 6px;padding-left:22px}
.resumo code{font-family:VT323,monospace;font-size:1.15em;background:rgba(0,0,0,.08);padding:0 4px;border-radius:3px}
.faixa{margin:14px 0 18px;padding:8px 14px;background:var(--fita);border:1px solid var(--grafite);border-radius:6px;display:flex;flex-wrap:wrap;gap:4px 8px;align-items:center}
.fichas{margin-left:auto;display:flex;flex-wrap:wrap;gap:6px}
.ficha{background:var(--violeta-fundo);border:1px solid var(--violeta);color:var(--etiqueta);padding:0 8px;border-radius:4px}
.pares{display:grid;gap:22px}
.par{margin:0}
.par figcaption{margin:0 0 6px;color:var(--mudo)}
.duas{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.quadro{position:relative;background:var(--fita);border:1px solid var(--grafite);border-radius:6px;overflow:hidden;min-height:120px}
.quadro .osd{position:absolute;left:8px;top:6px;z-index:1;background:rgba(13,10,22,.78);padding:0 8px;border-radius:3px;font-size:20px}
.quadro.depois .osd{color:var(--etiqueta);background:var(--violeta)}
.quadro img{display:block;width:100%;height:auto;cursor:zoom-in}
.quadro.vazio{display:flex;align-items:center;justify-content:center;border-style:dashed;aspect-ratio:16/9}
.nada{color:var(--mudo);font-family:VT323,monospace;font-size:24px}
.visor{position:fixed;inset:0;background:rgba(7,5,12,.94);display:none;align-items:center;justify-content:center;padding:16px;z-index:9;cursor:zoom-out}
.visor.aberto{display:flex}
.visor img{max-width:100%;max-height:100%;object-fit:contain;border:2px solid var(--grafite)}
@media (max-width:700px){.duas{grid-template-columns:1fr}.fichas{margin-left:0}.miolo{padding:14px 16px 16px}.cassete{padding:14px}}
@media (prefers-reduced-motion:no-preference){.quadro img{transition:opacity .15s}}
"""

SCRIPT = """
(function(){
var v=document.getElementById('visor'),g=v.querySelector('img');
document.addEventListener('click',function(e){
var t=e.target;
if(t.classList&&t.classList.contains('zoom')){g.src=t.src;g.alt=t.alt;v.classList.add('aberto');return;}
if(v.classList.contains('aberto')){v.classList.remove('aberto');g.removeAttribute('src');}
});
document.addEventListener('keydown',function(e){
if(e.key==='Escape'&&v.classList.contains('aberto')){v.classList.remove('aberto');g.removeAttribute('src');}
});
})();
"""


def pagina(entradas: list, cores: dict, listras: list) -> str:
    estilo = ESTILO
    for nome, valor in cores.items():
        estilo = estilo.replace(f"@{nome}@", valor)
    estilo = estilo.replace("@LISTRA_A@", listras[0]).replace("@LISTRA_B@", listras[1])
    faces = "".join(
        f'@font-face{{font-family:"{fam}";src:url("fontes/{arq}") format("truetype");font-display:swap;'
        + ("font-weight:100 900;" if fam == "Archivo Narrow" else "") + "}"
        for fam, arq in FONTES.items())
    n = len(entradas)
    corpo = "\n".join(e for _, e in entradas) if entradas else '<p class="nada">Nenhuma entrada no devlog ainda.</p>'
    return f"""<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Devlog da Forja</title>
<style>{faces}{estilo}</style>
</head>
<body>
<main>
<header class="topo"><h1>Devlog</h1><span class="osd">FORJA &middot; <b>{n}</b> ENTRADA{"S" if n != 1 else ""} &middot; A MAIS NOVA EM CIMA</span></header>
{corpo}
</main>
<div class="visor" id="visor" role="dialog" aria-label="Foto ampliada"><img alt=""></div>
<script>{SCRIPT}</script>
</body>
</html>
"""


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--raiz", default=str(Path(__file__).resolve().parent.parent.parent))
    ap.add_argument("--entrada", default=None)
    a = ap.parse_args()
    raiz = Path(a.raiz).resolve()
    if a.entrada:
        pastas = [Path(a.entrada).resolve()]
        if not (pastas[0] / "entrada.md").is_file():
            print(f"devlog: {a.entrada} não tem entrada.md", file=sys.stderr)
            return 2
    else:
        pastas = sorted(p.parent for p in (raiz / "docs/devlog").glob("*/entrada.md"))
    saida = raiz / ".cache/devlog"
    fotos = saida / "fotos"
    shutil.rmtree(fotos, ignore_errors=True)
    (saida / "fontes").mkdir(parents=True, exist_ok=True)
    for arq in FONTES.values():
        origem = raiz / "godot/assets/fontes" / arq
        if origem.is_file():
            shutil.copyfile(origem, saida / "fontes" / arq)
        else:
            print(f"devlog: falta a fonte {origem}", file=sys.stderr)
    entradas = sorted((entrada_html(p, fotos) for p in pastas), key=lambda x: x[0], reverse=True)
    cores, listras = cores_do_tema(raiz)
    destino = saida / "index.html"
    destino.write_text(pagina(entradas, cores, listras), encoding="utf-8")
    print(destino)
    return 0


if __name__ == "__main__":
    sys.exit(main())
