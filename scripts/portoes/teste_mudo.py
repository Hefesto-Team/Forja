#!/usr/bin/env python3
"""O portão do teste mudo: prova, foto e estudo rodam sem som e sem janela.

O Godot com `--headless` já não toca nada (o driver de áudio é o mudo). Quem
toca é o Godot aberto numa tela de mentira (`xvfb-run`), para a foto e a prova
visual: ali ele abre a saída de som da máquina, e o som do teste sai na TV de
quem está do lado. O `--write-movie` também é mudo (o som vai para o filme).

Para cada script de shell em tests/, scripts/ e godot/estudos/, junta as linhas
de continuação (`\\` no fim) e, em todo comando que chama o `xvfb-run` e o
Godot, exige `--audio-driver Dummy` ou `--write-movie`.

Modo: reprova (é portão da base).

Uso: python3 scripts/portoes/teste_mudo.py [--raiz DIR] [--modo aviso|reprova]
"""
import re
import sys

import comum

ESCOPO = ("tests", "scripts", "godot/estudos")
GODOT = re.compile(r"(\$\{?GODOT|Godot_v|\bgodot\b)", re.I)
MUDO = ("--audio-driver Dummy", "--audio-driver=Dummy", "--write-movie")


def comandos(texto: str):
    """Os comandos, com as continuações juntadas, e a linha onde cada um começa."""
    junto, comeco = "", 1
    for n, linha in enumerate(texto.splitlines(), 1):
        if not junto:
            comeco = n
        if linha.rstrip().endswith("\\"):
            junto += linha.rstrip()[:-1] + " "
            continue
        yield comeco, junto + linha
        junto = ""
    if junto:
        yield comeco, junto


def main() -> int:
    a = comum.argumentos("teste_mudo", __doc__.splitlines()[0], com_regras=False)
    relato = comum.Relato("teste mudo", a.modo or "reprova")
    vistos = 0
    # a prova dos portões traz o caso ruim de propósito
    for f in comum.arquivos(a.raiz, ESCOPO, {".sh"}, ignorar=("tests/prova_dos_portoes.sh",)):
        texto = f.read_text(encoding="utf-8", errors="replace")
        for linha, cmd in comandos(texto):
            sem = cmd.split("#", 1)[0] if cmd.lstrip().startswith("#") else cmd
            if "xvfb-run" not in sem or not GODOT.search(sem.split("xvfb-run", 1)[1]):
                continue
            vistos += 1
            if not any(m in sem for m in MUDO):
                relato.achou(f.relative_to(a.raiz), linha,
                             "o Godot na tela de mentira toca som: falta --audio-driver Dummy")
    return relato.fechar(f"{vistos} chamadas do Godot pelo xvfb-run")


if __name__ == "__main__":
    sys.exit(main())
