#!/usr/bin/env python3
"""O portão do devlog: toda entrada de docs/devlog/ está inteira e leve.

Por entrada: o cabeçalho tem titulo, data, ramo, base, topo e fichas, e a pasta começa pela data; o resumo tem de
1 a 8 linhas e não é o «A ESCREVER» do entrada.sh; toda foto de antes/ e depois/ é JPEG (.jpg) de até 1280 px;
a entrada pesa até 6 MB; toda foto de um lado só consta em so_antes ou so_depois (senão, par sem irmão).
Nenhum PNG vive em docs/devlog/. Modo: reprova (é portão da base).

Uso: python3 scripts/portoes/devlog.py [--raiz DIR] [--modo aviso|reprova]
"""
import re
import sys
from pathlib import Path

import comum

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "devlog"))
import cabecalho  # noqa: E402
import jpeg  # noqa: E402

LARGURA = 1280
PESO = 6 * 1024 * 1024
LINHAS = 8
OBRIGATORIOS = ("titulo", "data", "ramo", "base", "topo")


def lista(valor: str) -> list:
    return [x.strip() for x in valor.split(",") if x.strip()]


def conferir(pasta: Path, raiz: Path, relato) -> None:
    rel = pasta.relative_to(raiz)
    entrada = pasta / "entrada.md"
    campos, corpo = cabecalho.ler(entrada)
    if not campos:
        relato.achou(rel / "entrada.md", 1, "sem cabeçalho (--- chave: valor ---)")
    for chave in OBRIGATORIOS:
        if not campos.get(chave):
            relato.achou(rel / "entrada.md", 1, f"falta «{chave}» no cabeçalho")
    if campos and "fichas" not in campos:
        relato.achou(rel / "entrada.md", 1, "falta «fichas» no cabeçalho (pode ficar vazia)")
    data = campos.get("data", "")
    if data and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", data):
        relato.achou(rel / "entrada.md", 1, f"a data «{data}» não é AAAA-MM-DD")
    elif data and not pasta.name.startswith(data + "-"):
        relato.achou(rel, 0, f"a pasta não começa pela data do cabeçalho ({data}-)")
    for chave in ("base", "topo"):
        if campos.get(chave) and not re.fullmatch(r"[0-9a-f]{7,40}", campos[chave]):
            relato.achou(rel / "entrada.md", 1, f"«{chave}» não é um SHA")
    linhas = cabecalho.linhas_do_resumo(corpo)
    if not linhas:
        relato.achou(rel / "entrada.md", 0, "sem resumo")
    elif len(linhas) > LINHAS:
        relato.achou(rel / "entrada.md", 0, f"o resumo tem {len(linhas)} linhas; o máximo é {LINHAS}")
    if "A ESCREVER" in corpo:
        relato.achou(rel / "entrada.md", 0, "o resumo ainda é o «A ESCREVER» do entrada.sh")

    nomes = {}
    for lado in ("antes", "depois"):
        nomes[lado] = set()
        for f in sorted((pasta / lado).glob("*")) if (pasta / lado).is_dir() else []:
            fr = f.relative_to(raiz)
            if f.suffix != ".jpg":
                relato.achou(fr, 0, "a foto tem de ser JPEG (.jpg)")
                continue
            medida = jpeg.medida(f.read_bytes())
            if medida is None:
                relato.achou(fr, 0, "não é um JPEG legível")
            elif medida[0] > LARGURA:
                relato.achou(fr, 0, f"{medida[0]} px de largura; o máximo é {LARGURA}")
            nomes[lado].add(f.stem)
    for f in sorted(pasta.iterdir()):
        if f.name not in ("entrada.md", "antes", "depois"):
            relato.achou(f.relative_to(raiz), 0, "arquivo fora do lugar (só entrada.md, antes/ e depois/)")
    total = sum(f.stat().st_size for f in pasta.rglob("*") if f.is_file())
    if total > PESO:
        relato.achou(rel, 0, f"a entrada pesa {total / 1048576:.1f} MB; o máximo é {PESO // 1048576} MB")

    so = {"antes": set(lista(campos.get("so_antes", ""))), "depois": set(lista(campos.get("so_depois", "")))}
    outro = {"antes": "depois", "depois": "antes"}
    for lado in ("antes", "depois"):
        for n in sorted(nomes[lado] - nomes[outro[lado]] - so[lado]):
            relato.achou(rel / lado / f"{n}.jpg", 0, f"par sem irmão: não há {n}.jpg em {outro[lado]}/ nem ele consta em so_{lado}")
        for n in sorted(so[lado]):
            if n not in nomes[lado]:
                relato.achou(rel / "entrada.md", 1, f"so_{lado} cita {n}, que não está em {lado}/")
            elif n in nomes[outro[lado]]:
                relato.achou(rel / "entrada.md", 1, f"so_{lado} cita {n}, que tem irmão em {outro[lado]}/")


def main() -> int:
    a = comum.argumentos("devlog", __doc__.splitlines()[0], com_regras=False)
    relato = comum.Relato("devlog", a.modo or "reprova")
    base = a.raiz / "docs/devlog"
    entradas = sorted(p.parent for p in base.glob("*/entrada.md")) if base.is_dir() else []
    for p in entradas:
        conferir(p, a.raiz, relato)
    if base.is_dir():
        for sem in sorted(p for p in base.iterdir() if p.is_dir() and not (p / "entrada.md").is_file()):
            relato.achou(sem.relative_to(a.raiz), 0, "pasta sem entrada.md")
        for png in sorted(base.rglob("*.png")):
            relato.achou(png.relative_to(a.raiz), 0, "PNG no devlog: só JPEG")
    return relato.fechar(f"{len(entradas)} entrada(s)")


if __name__ == "__main__":
    sys.exit(main())
