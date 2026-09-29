#!/usr/bin/env python3
"""O ícone e a versão do FORJA gravados no .exe exportado, sem rcedit.

O Godot 4.4 só troca o ícone e os metadados de um .exe chamando o rcedit
(outro .exe, pelo Wine). Este script faz o mesmo em Python puro: lê a árvore
de recursos do executável, troca o grupo de ícones pelo do forja.ico e a
versão pela do projeto, e grava a árvore nova numa seção nova no fim do
arquivo (a velha fica, sem ninguém apontando para ela). O resto do
executável não muda de lugar.

    icone_do_exe.py EXE ICO VERSAO    grava (VERSAO: 0.3.0)
    icone_do_exe.py --conferir EXE    diz os tamanhos do ícone e a versão
"""

import struct
import sys

RT_ICON, RT_GROUP_ICON, RT_VERSION = 3, 14, 16
EMPRESA = "Hefesto Team"
PRODUTO = "Forja"
DIREITOS = "Hefesto Team, MIT"
IDIOMA, PAGINA = 0x0416, 1200  # português do Brasil, Unicode


def alinhar(n: int, a: int) -> int:
    return (n + a - 1) // a * a


class Executavel:
    def __init__(self, dados: bytes) -> None:
        self.b = bytearray(dados)
        if self.b[:2] != b"MZ":
            raise ValueError("não é um executável do Windows")
        self.pe = struct.unpack_from("<I", self.b, 0x3C)[0]
        if self.b[self.pe : self.pe + 4] != b"PE\0\0":
            raise ValueError("não é um executável PE")
        self.coff = self.pe + 4
        self.n_secoes, = struct.unpack_from("<H", self.b, self.coff + 2)
        tam_opcional, = struct.unpack_from("<H", self.b, self.coff + 16)
        self.opc = self.coff + 20
        if struct.unpack_from("<H", self.b, self.opc)[0] != 0x20B:
            raise ValueError("só o PE32+ (64 bits)")
        self.tabela = self.opc + tam_opcional
        self.dir_recursos = self.opc + 112 + 8 * 2
        self.dir_seguranca = self.opc + 112 + 8 * 4

    def secoes(self) -> list:
        r = []
        for i in range(self.n_secoes):
            o = self.tabela + 40 * i
            nome = bytes(self.b[o : o + 8]).rstrip(b"\0").decode("latin-1")
            vtam, va, rtam, rptr = struct.unpack_from("<IIII", self.b, o + 8)
            r.append((nome, va, vtam, rptr, rtam))
        return r

    def deslocamento(self, rva: int) -> int:
        for _, va, vtam, rptr, rtam in self.secoes():
            if va <= rva < va + max(vtam, rtam):
                return rptr + rva - va
        raise ValueError("endereço fora das seções: 0x%x" % rva)

    def recursos(self) -> dict:
        rva, tam = struct.unpack_from("<II", self.b, self.dir_recursos)
        if not rva:
            return {}
        base = self.deslocamento(rva)

        def nome(v: int):
            if v & 0x80000000:
                o = base + (v & 0x7FFFFFFF)
                n, = struct.unpack_from("<H", self.b, o)
                return bytes(self.b[o + 2 : o + 2 + 2 * n]).decode("utf-16-le")
            return v

        def pasta(o: int) -> dict:
            nomeados, ids = struct.unpack_from("<HH", self.b, o + 12)
            r = {}
            for i in range(nomeados + ids):
                chave, alvo = struct.unpack_from("<II", self.b, o + 16 + 8 * i)
                if alvo & 0x80000000:
                    r[nome(chave)] = pasta(base + (alvo & 0x7FFFFFFF))
                else:
                    drva, dtam, pagina, _ = struct.unpack_from("<IIII", self.b, base + alvo)
                    d = self.deslocamento(drva)
                    r[nome(chave)] = (bytes(self.b[d : d + dtam]), pagina)
            return r

        return pasta(base)

    def gravar_recursos(self, arvore: dict) -> None:
        secao_alin, arq_alin = struct.unpack_from("<II", self.b, self.opc + 32)
        tam_cabecalho, = struct.unpack_from("<I", self.b, self.opc + 60)
        nova = self.tabela + 40 * self.n_secoes
        if nova + 40 > tam_cabecalho or any(self.b[nova : nova + 40]):
            raise ValueError("não há lugar no cabeçalho para mais uma seção")
        fim_bruto = max(rptr + rtam for _, _, _, rptr, rtam in self.secoes())
        if len(self.b) > fim_bruto:
            raise ValueError("o .exe tem dados depois das seções (pck embutido ou assinatura)")
        va = alinhar(max(va + vtam for _, va, vtam, _, _ in self.secoes()), secao_alin)
        corpo = serializar(arvore, va)
        rptr = alinhar(len(self.b), arq_alin)
        rtam = alinhar(len(corpo), arq_alin)
        self.b += b"\0" * (rptr - len(self.b)) + corpo + b"\0" * (rtam - len(corpo))
        struct.pack_into("<8sIIIIIIHHI", self.b, nova, b".forja", len(corpo), va, rtam, rptr,
                         0, 0, 0, 0, 0x40000040)
        self.n_secoes += 1
        struct.pack_into("<H", self.b, self.coff + 2, self.n_secoes)
        struct.pack_into("<I", self.b, self.opc + 56, alinhar(va + len(corpo), secao_alin))
        struct.pack_into("<II", self.b, self.dir_recursos, va, len(corpo))
        struct.pack_into("<II", self.b, self.dir_seguranca, 0, 0)
        struct.pack_into("<I", self.b, self.opc + 64, 0)
        struct.pack_into("<I", self.b, self.opc + 64, soma_de_verificacao(self.b, self.opc + 64))


def soma_de_verificacao(b: bytearray, campo: int) -> int:
    dados = bytes(b) + b"\0" * (len(b) % 2)
    s = 0
    for (w,) in struct.iter_unpack("<H", dados):
        s += w
        s = (s & 0xFFFF) + (s >> 16)
    s -= sum(struct.unpack_from("<HH", b, campo))  # o campo da soma conta como zero
    s = (s & 0xFFFF) + (s >> 16)
    return ((s & 0xFFFF) + len(b)) & 0xFFFFFFFF


def ordenadas(pasta: dict) -> list:
    nomes = sorted((k for k in pasta if isinstance(k, str)), key=str.upper)
    ids = sorted(k for k in pasta if isinstance(k, int))
    return nomes + ids


def serializar(arvore: dict, va: int) -> bytes:
    """A árvore em ordem: as pastas, os nomes, as entradas de dado e os dados."""
    pastas, fila = [], [arvore]
    while fila:
        p = fila.pop(0)
        pastas.append(p)
        fila += [p[k] for k in ordenadas(p) if isinstance(p[k], dict)]
    lugar_pasta, o = {}, 0
    for p in pastas:
        lugar_pasta[id(p)] = o
        o += 16 + 8 * len(p)
    lugar_nome, nomes = {}, b""
    for p in pastas:
        for k in p:
            if isinstance(k, str) and k not in lugar_nome:
                lugar_nome[k] = o + len(nomes)
                nomes += struct.pack("<H", len(k)) + k.encode("utf-16-le")
    o = alinhar(o + len(nomes), 4)
    folhas = [p[k] for p in pastas for k in ordenadas(p) if not isinstance(p[k], dict)]
    lugar_entrada = {}
    for i, f in enumerate(folhas):
        lugar_entrada[id(f)] = o + 16 * i
    o += 16 * len(folhas)
    entradas, dados = b"", b""
    for f in folhas:
        o_dado = alinhar(o + len(dados), 8)
        dados += b"\0" * (o_dado - o - len(dados)) + f[0]
        entradas += struct.pack("<IIII", va + o_dado, len(f[0]), f[1], 0)
    corpo = b""
    for p in pastas:
        ks = ordenadas(p)
        corpo += struct.pack("<IIHHHH", 0, 0, 0, 0, sum(isinstance(k, str) for k in ks),
                             sum(isinstance(k, int) for k in ks))
        for k in ks:
            chave = (lugar_nome[k] | 0x80000000) if isinstance(k, str) else k
            alvo = (lugar_pasta[id(p[k])] | 0x80000000) if isinstance(p[k], dict) else lugar_entrada[id(p[k])]
            corpo += struct.pack("<II", chave, alvo)
    corpo += nomes
    corpo += b"\0" * (alinhar(len(corpo), 4) - len(corpo))
    return corpo + entradas + dados


def bloco(chave: str, valor: bytes = b"", tipo: int = 0, tam_valor: int = 0, filhos=()) -> bytes:
    cab = struct.pack("<HHH", 0, tam_valor, tipo) + (chave + "\0").encode("utf-16-le")
    cab += b"\0" * (alinhar(len(cab), 4) - len(cab))
    corpo = cab + valor
    for f in filhos:
        corpo += b"\0" * (alinhar(len(corpo), 4) - len(corpo)) + f
    return struct.pack("<H", len(corpo)) + corpo[2:]


def versao(texto: str) -> bytes:
    partes = ([int(x) for x in texto.split(".")] + [0, 0, 0, 0])[:4]
    ms, ls = partes[0] << 16 | partes[1], partes[2] << 16 | partes[3]
    cheia = ".".join(str(x) for x in partes)
    fixa = struct.pack("<13I", 0xFEEF04BD, 0x00010000, ms, ls, ms, ls, 0x3F, 0, 0x40004, 1, 0, 0, 0)
    campos = {"CompanyName": EMPRESA, "FileDescription": PRODUTO, "FileVersion": cheia,
              "InternalName": PRODUTO, "LegalCopyright": DIREITOS, "OriginalFilename": "forja.exe",
              "ProductName": PRODUTO, "ProductVersion": cheia}
    textos = [bloco(k, (v + "\0").encode("utf-16-le"), 1, len(v) + 1) for k, v in campos.items()]
    tabela = bloco("%04X%04X" % (IDIOMA, PAGINA), tipo=1, filhos=textos)
    traducao = bloco("Translation", struct.pack("<HH", IDIOMA, PAGINA), 0, 4)
    return bloco("VS_VERSION_INFO", fixa, 0, len(fixa), [
        bloco("StringFileInfo", tipo=1, filhos=[tabela]),
        bloco("VarFileInfo", tipo=1, filhos=[traducao]),
    ])


def gravar(caminho: str, ico: str, texto_versao: str) -> None:
    exe = Executavel(open(caminho, "rb").read())
    arvore = exe.recursos()
    i = open(ico, "rb").read()
    reservado, tipo, n = struct.unpack_from("<HHH", i, 0)
    if reservado != 0 or tipo != 1 or not n:
        raise ValueError("%s não é um .ico" % ico)
    icones, grupo = {}, struct.pack("<HHH", 0, 1, n)
    for k in range(n):
        lar, alt, cores, _, planos, bits, tam, o = struct.unpack_from("<BBBBHHII", i, 6 + 16 * k)
        icones[k + 1] = {IDIOMA: (i[o : o + tam], 0)}
        grupo += struct.pack("<BBBBHHIH", lar, alt, cores, 0, planos, bits, tam, k + 1)
    velho = arvore.get(RT_GROUP_ICON, {})
    nome_grupo = ordenadas(velho)[0] if velho else 1
    arvore[RT_ICON] = icones
    arvore[RT_GROUP_ICON] = {nome_grupo: {IDIOMA: (grupo, 0)}}
    arvore[RT_VERSION] = {1: {IDIOMA: (versao(texto_versao), 0)}}
    exe.gravar_recursos(arvore)
    with open(caminho, "wb") as f:
        f.write(exe.b)


def conferir(caminho: str) -> int:
    arvore = Executavel(open(caminho, "rb").read()).recursos()
    for grupo in arvore.get(RT_GROUP_ICON, {}).values():
        for dado, _ in grupo.values():
            n, = struct.unpack_from("<H", dado, 4)
            tamanhos = [dado[6 + 14 * k] or 256 for k in range(n)]
            print("ícone:", " ".join(str(t) for t in tamanhos))
    for pasta in arvore.get(RT_VERSION, {}).values():
        for dado, _ in pasta.values():
            texto = dado.decode("utf-16-le", "replace")
            for chave in ("ProductName", "FileVersion", "CompanyName"):
                j = texto.find(chave + "\0")
                if j >= 0:
                    k = j + len(chave) + 1
                    while texto[k] == "\0":
                        k += 1
                    print("%s: %s" % (chave, texto[k : texto.find("\0", k)]))
    return 0


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "--conferir":
        sys.exit(conferir(a[1]))
    if len(a) != 3:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    gravar(*a)
