#!/usr/bin/env python3
"""O portão da regra do udev: o hidraw do DualSense só para quem está na máquina, no cabo, no rádio e no uhid.

A regra que o pacote leva (udev/*-forja-dualsense.rules) segue o padrão das regras do sistema:
  - nenhuma linha abre o nó para todos (MODE="0666", ou qualquer modo que dê escrita a «outros») nem
    entrega o nó a um grupo (GROUP=, que Fedora e Arch não têm do mesmo jeito);
  - toda linha de hidraw leva TAG+="uaccess" (a ACL vai para a sessão ativa);
  - para o DualSense (054C:0CE6) e o DualSense Edge (054C:0DF2), uma linha pelo pai USB
    (ATTRS{idVendor}/ATTRS{idProduct}, o cabo) e uma pelo nome do aparelho HID (KERNELS=="*054C:0CE6*",
    o rádio e o nó virtual por uhid, que não tem pai USB);
  - as linhas do cabo e do rádio só contam quando são do hidraw e dão o uaccess, e com a caixa das letras
    do sysfs (o udev compara com caixa: «054c» no pai USB, «054C:0CE6» no nome do aparelho HID);
  - o número do arquivo vem antes do 73 (o 73-seat-late.rules aplica o uaccess: marca que chega depois
    dele não vale).

Modo: reprova (é portão da base).

Uso: python3 scripts/portoes/udev.py [--raiz DIR] [--modo aviso|reprova]
"""
import re
import sys

import comum

CONTROLES = (("054c", "0ce6", "DualSense"), ("054c", "0df2", "DualSense Edge"))
MODO = re.compile(r'\bMODE:?="?(0?[0-7]{3})"?')


def linhas_de_regra(texto: str):
    """As linhas de regra (sem comentário nem linha em branco), com o número."""
    for n, linha in enumerate(texto.splitlines(), 1):
        limpa = linha.strip()
        if limpa and not limpa.startswith("#"):
            yield n, limpa


def main() -> int:
    a = comum.argumentos("udev", __doc__.splitlines()[0], com_regras=False)
    relato = comum.Relato("regra do udev", a.modo or "reprova")
    regras = sorted((a.raiz / "udev").glob("*forja-dualsense.rules"))
    if not regras:
        relato.achou("udev/", 0, "falta a regra do hidraw do DualSense (udev/<nn>-forja-dualsense.rules)")
        return relato.fechar("nenhuma regra")
    for f in regras:
        rel = f.relative_to(a.raiz)
        numero = re.match(r"(\d+)-", f.name)
        if not numero or int(numero.group(1)) >= 73:
            relato.achou(rel, 0, "o nome tem de começar por um número abaixo de 73: o uaccess só vale antes do "
                                 "73-seat-late.rules")
        texto = f.read_text(encoding="utf-8", errors="replace")
        linhas = list(linhas_de_regra(texto))
        for n, linha in linhas:
            m = MODO.search(linha)
            if m and int(m.group(1), 8) & 0o006:
                relato.achou(rel, n, f"MODE {m.group(1)} abre o controle para toda conta da máquina (o certo: 0660)")
            if re.search(r"\bGROUP:?=", linha):
                relato.achou(rel, n, "GROUP= entrega o controle a um grupo; o acesso é da sessão (TAG+=\"uaccess\")")
            if 'KERNEL=="hidraw*"' in linha and 'TAG+="uaccess"' not in linha:
                relato.achou(rel, n, 'a linha do hidraw sem TAG+="uaccess"')
        # Só conta a linha que é do hidraw e dá o uaccess. E a caixa das letras é a do sysfs, porque o udev
        # compara com caixa: o idVendor e o idProduct do pai USB vêm em minúscula («054c»), e o nome do
        # aparelho HID em maiúscula («0003:054C:0CE6.0001»); um «*054c:0ce6*» não casaria nada.
        do_hidraw = [(n, l) for n, l in linhas if "hidraw" in l and 'TAG+="uaccess"' in l]
        for vid, pid, nome in CONTROLES:
            cabo = [n for n, l in do_hidraw if f'ATTRS{{idVendor}}=="{vid}"' in l
                    and f'ATTRS{{idProduct}}=="{pid}"' in l]
            radio = [n for n, l in do_hidraw if f'KERNELS=="*{vid.upper()}:{pid.upper()}*"' in l]
            if not cabo:
                relato.achou(rel, 0, f"falta a linha do {nome} no cabo (ATTRS{{idVendor}}==\"{vid}\", "
                                     f"ATTRS{{idProduct}}==\"{pid}\")")
            if not radio:
                relato.achou(rel, 0, f"falta a linha do {nome} no rádio e no uhid "
                                     f"(KERNELS==\"*{vid.upper()}:{pid.upper()}*\")")
    return relato.fechar(f"{len(regras)} regra(s) do hidraw")


if __name__ == "__main__":
    sys.exit(main())
