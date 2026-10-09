#!/usr/bin/env python3
"""O portão da caixa: prova e script abrem o jogo só dentro da caixa.

Numa prova o jogo não pode achar o DualSense ligado na máquina: se acha, o
controle de verdade ganha um lugar, e a prova toca o alto-falante, a háptica e
os gatilhos dele. A caixa (tests/caixa.sh) roda o Godot num /dev novo, sem
hidraw nem input; o `--headless` não protege (ele cala a TV, não o módulo).

Para cada script de shell em tests/ e scripts/, junta as linhas de
continuação (`\\` no fim), como o teste mudo, e reprova o comando que chama o
Godot com cena, `--simular`, `--robo` ou `res://` sem o `caixa` antes. Ficam
de fora o `--import`, o `--export-*` e o `-s <script>.gd` (não abrem a cena
do jogo), e o próprio tests/caixa.sh.

Modo: reprova (é portão da base).

Uso: python3 scripts/portoes/caixa.py [--raiz DIR] [--modo aviso|reprova]
"""
import re
import sys

import comum

ESCOPO = ("tests", "scripts")
# o executável do Godot: a variável, o binário baixado, ou a função `godot` de um script
GODOT = re.compile(r'"?\$\{?(?:GODOT|FORJA_GODOT|GODOT_BIN)\}?"?(?=\s|$)|Godot_v\S*|(?:^|(?<=[\s;&|(]))godot(?=\s)')
ABRE = ("res://", ".tscn", "--simular", "--robo")
NAO_ABRE = re.compile(r"(?:^|\s)(?:--import|--export-\S+|-s|--script)(?=\s|$)")
CAIXA = re.compile(r"(?:^|(?<=[\s;&|(]))caixa(?=\s)")
TESTE = re.compile(r"^\s*(?:\[\[?|test)\s")


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
    a = comum.argumentos("caixa", __doc__.splitlines()[0], com_regras=False)
    relato = comum.Relato("caixa", a.modo or "reprova")
    vistos = 0
    # a caixa é o lugar que monta o bwrap; a prova dos portões traz o caso ruim de propósito
    ignorar = ("tests/caixa.sh", "tests/prova_dos_portoes.sh")
    for f in comum.arquivos(a.raiz, ESCOPO, {".sh"}, ignorar=ignorar):
        texto = f.read_text(encoding="utf-8", errors="replace")
        for linha, cmd in comandos(texto):
            if cmd.lstrip().startswith("#") or TESTE.match(cmd):
                continue
            m = GODOT.search(cmd)
            if not m:
                continue
            resto = cmd[m.end():]
            if NAO_ABRE.search(resto) or not any(x in resto for x in ABRE):
                continue
            vistos += 1
            if not CAIXA.search(cmd[:m.start()]):
                relato.achou(f.relative_to(a.raiz), linha,
                             "o Godot abre o jogo fora da caixa: chame por `caixa` (tests/caixa.sh)")
    return relato.fechar(f"{vistos} chamadas do Godot que abrem o jogo")


if __name__ == "__main__":
    sys.exit(main())
