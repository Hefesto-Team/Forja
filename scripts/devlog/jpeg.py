"""A medida de um JPEG, lida do cabeçalho, sem biblioteca de imagem."""
import struct

SOF = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}


def e_jpeg(dados: bytes) -> bool:
    return dados[:3] == b"\xff\xd8\xff"


def medida(dados: bytes):
    """(largura, altura) de um JPEG, ou None se não for JPEG ou não tiver quadro."""
    if not e_jpeg(dados):
        return None
    i, n = 2, len(dados)
    while i + 4 <= n:
        if dados[i] != 0xFF:
            i += 1
            continue
        marca = dados[i + 1]
        if marca == 0xFF:
            i += 1
            continue
        if marca in (0x01, 0xD8) or 0xD0 <= marca <= 0xD7:
            i += 2
            continue
        tam = struct.unpack(">H", dados[i + 2:i + 4])[0]
        if marca in SOF and i + 9 <= n:
            altura, largura = struct.unpack(">HH", dados[i + 5:i + 9])
            return largura, altura
        i += 2 + tam
    return None
