#!/usr/bin/env python3
"""O portão da ficha pronta: ficha marcada «pronta» no quadro tem todas as
partes de docs/jogo/o-time/ficha-pronta.md.

As partes são lidas da tabela «As partes» daquele documento (a primeira
coluna, em negrito): o documento é a regra, e o portão segue quando ele muda.
Para cada linha do quadro (`docs/jogo/tarefas/README.md`) cujo estado começa
com «pronta», confere na ficha:

  1. cada parte é um título `## <parte>` e tem texto embaixo (uma parte que
     não se aplica diz «Não se aplica: <por quê>», e isso conta);
  2. o «Ler antes» tem de um a três links, e cada link relativo aponta para
     um arquivo que existe;
  3. a âncora do link casa com um título do arquivo (a âncora do GitHub, a
     mesma função do scripts/ler_antes.py);
  4. o link sem âncora não aponta para arquivo de mais de 20 KB, salvo o
     molde de minigame (a régua das fichas, que se lê inteiro) e o arquivo que
     a própria ficha muda (está nos «Arquivos que mudam»: lê-lo é o trabalho);
  5. o link não aponta para ficha **feito** no quadro: o que ela deixou está
     no 13, e a ficha feita fica como registro do código de quando foi feita.

Fichas em outro estado não se conferem. Modo: reprova (é portão da base).

Uso: python3 scripts/portoes/ficha_pronta.py [--raiz DIR] [--modo aviso|reprova]
"""
import re
import sys
from pathlib import Path

import comum

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import ler_antes  # noqa: E402  (o scripts/ler_antes.py: a mesma âncora para o script e o portão)

REGRA = "docs/jogo/o-time/ficha-pronta.md"
QUADRO = "docs/jogo/tarefas/README.md"
LINHA_DO_QUADRO = re.compile(r"^\|\s*\[([^\]]+)\]\(([^)]+)\)\s*\|(.*)\|\s*$")
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
LIMITE = 20 * 1024  # bytes: acima disto, o «Ler antes» aponta para a seção
MOLDES = ("docs/jogo/tarefas/molde-de-minigame.md",)


def partes(texto: str):
    """As partes, na ordem da tabela «As partes»."""
    ini = texto.find("## As partes")
    if ini < 0:
        return []
    fim = texto.find("\n## ", ini + 5)
    bloco = texto[ini:fim if fim > 0 else len(texto)]
    return re.findall(r"^\|\s*\*\*([^*]+)\*\*\s*\|", bloco, re.M)


def secoes(texto: str):
    """{título normalizado: corpo} dos `## ` da ficha."""
    achou, atual, corpo = {}, None, []
    for linha in texto.splitlines():
        if linha.startswith("## "):
            if atual is not None:
                achou[atual] = "\n".join(corpo).strip()
            atual, corpo = linha[3:].strip().lower(), []
        elif atual is not None:
            corpo.append(linha)
    if atual is not None:
        achou[atual] = "\n".join(corpo).strip()
    return achou


def main() -> int:
    a = comum.argumentos("ficha_pronta", "As fichas «pronta» do quadro têm todas as partes da ficha pronta.",
                         com_regras=False)
    rel = comum.Relato("ficha pronta", a.modo or "reprova")
    raiz = a.raiz
    try:
        lista = partes((raiz / REGRA).read_text(encoding="utf-8"))
        quadro = (raiz / QUADRO).read_text(encoding="utf-8").splitlines()
    except OSError as e:
        print(f"ficha pronta: não li {e.filename}", file=sys.stderr)
        return 2
    if not lista:
        print(f"ficha pronta: a tabela «As partes» de {REGRA} não se leu", file=sys.stderr)
        return 2
    pastas = (raiz / QUADRO).parent
    feitas = set()
    for linha in quadro:
        m = LINHA_DO_QUADRO.match(linha)
        if m and m.group(3).split("|")[-1].strip().lower().startswith("feito"):
            feitas.add((pastas / m.group(2)).resolve())
    conferidas = 0
    for n, linha in enumerate(quadro, 1):
        m = LINHA_DO_QUADRO.match(linha)
        if not m:
            continue
        estado = m.group(3).split("|")[-1].strip().lower()
        if not estado.startswith("pronta"):
            continue
        conferidas += 1
        codigo, alvo = m.group(1), pastas / m.group(2)
        if not alvo.is_file():
            rel.achou(QUADRO, n, f"{codigo} está pronta e a ficha {m.group(2)} não existe")
            continue
        ficha = secoes(alvo.read_text(encoding="utf-8"))
        nome = str(alvo.relative_to(raiz))
        for p in lista:
            corpo = ficha.get(p.strip().lower())
            if corpo is None:
                rel.achou(nome, 0, f"{codigo} pronta sem a parte «{p}»")
            elif not corpo:
                rel.achou(nome, 0, f"{codigo} pronta com a parte «{p}» vazia")
        ler = ficha.get("ler antes")
        if ler:
            links = LINK.findall(ler)
            if not 1 <= len(links) <= 3:
                rel.achou(nome, 0, f"{codigo}: o «Ler antes» tem {len(links)} links (de um a três)")
            muda = ficha.get("arquivos que mudam", "")
            for ln in links:
                if "://" in ln:
                    continue
                destino, anc = ler_antes.resolver(alvo, ln)
                caminho = ln.split("#", 1)[0] or alvo.name
                if not destino.exists():
                    rel.achou(nome, 0, f"{codigo}: o «Ler antes» aponta para {caminho}, que não existe")
                    continue
                if destino.resolve() in feitas:
                    rel.achou(nome, 0, f"{codigo}: o «Ler antes» aponta para a ficha feita {caminho} "
                                       "(o que ela deixou está no 13)")
                if not destino.is_file():
                    continue
                if anc:
                    if ler_antes.secao(destino.read_text(encoding="utf-8"), anc) is None:
                        rel.achou(nome, 0, f"{codigo}: o «Ler antes» aponta para {caminho}#{anc}, âncora que não "
                                           "casa com título nenhum")
                    continue
                try:
                    de_raiz = destino.resolve().relative_to(raiz).as_posix()
                except ValueError:
                    de_raiz = caminho
                tamanho = destino.stat().st_size
                if tamanho > LIMITE and de_raiz not in MOLDES and f"`{de_raiz}`" not in muda:
                    rel.achou(nome, 0, f"{codigo}: o «Ler antes» aponta para {caminho} inteiro ({tamanho // 1024} KB); "
                                       "aponte para a seção, pela âncora")
    return rel.fechar(f"{conferidas} fichas prontas, {len(lista)} partes")


if __name__ == "__main__":
    sys.exit(main())
