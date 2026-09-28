#!/usr/bin/env python3
"""Os modelos de exportação do Godot que o FORJA usa, e só eles.

O pacote oficial (o .tpz da página de versões do Godot) tem 1,2 GB: todas as
plataformas, em debug e em release. O FORJA exporta dois executáveis — o
Linux x86_64 e o Windows x86_64, em release —, então este script lê o índice
do pacote (ele é um zip) e baixa só os pedaços desses dois, por HTTP Range.
Cada arquivo sai conferido pelo sha256, como o SDL no compilar.sh.

    modelos_de_exportacao.py URL PASTA nome=sha256 [nome=sha256 ...]

Os nomes são os de dentro do pacote, sem o "templates/" da frente.
"""

import hashlib
import io
import os
import sys
import urllib.request
import zipfile


class PacoteRemoto(io.RawIOBase):
    """O pacote lido por pedaços: cada leitura é um pedido com Range."""

    def __init__(self, url: str) -> None:
        super().__init__()
        self.url = url
        pedido = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(pedido, timeout=60) as r:
            if r.headers.get("Accept-Ranges", "") != "bytes":
                raise SystemExit("o servidor do pacote não aceita pedidos por pedaço (Range)")
            self.tamanho = int(r.headers["Content-Length"])
        self.pos = 0

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self.pos

    def seek(self, deslocamento: int, de_onde: int = io.SEEK_SET) -> int:
        base = {io.SEEK_SET: 0, io.SEEK_CUR: self.pos, io.SEEK_END: self.tamanho}[de_onde]
        self.pos = base + deslocamento
        return self.pos

    def readinto(self, destino) -> int:
        n = min(len(destino), self.tamanho - self.pos)
        if n <= 0:
            return 0
        # o link do github.com redireciona para um endereço assinado que vence
        # em minutos: cada pedido sai do link original (o Range vai junto)
        pedido = urllib.request.Request(self.url, headers={"Range": f"bytes={self.pos}-{self.pos + n - 1}"})
        with urllib.request.urlopen(pedido, timeout=300) as r:
            if r.status != 206:
                raise SystemExit(f"o servidor devolveu {r.status} para um pedido por pedaço")
            dados = r.read()
        destino[: len(dados)] = dados
        self.pos += len(dados)
        return len(dados)


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    url, pasta, pedidos = sys.argv[1], sys.argv[2], sys.argv[3:]
    os.makedirs(pasta, exist_ok=True)
    pacote = zipfile.ZipFile(io.BufferedReader(PacoteRemoto(url), buffer_size=1 << 20))
    for pedido in pedidos:
        nome, _, esperado = pedido.partition("=")
        dados = pacote.read("templates/" + nome)  # o zip confere o CRC
        tem = hashlib.sha256(dados).hexdigest()
        if esperado and tem != esperado:
            print(f"sha256 de {nome} não confere: {tem} (esperado {esperado})", file=sys.stderr)
            return 1
        destino = os.path.join(pasta, nome)
        with open(destino + ".parcial", "wb") as f:
            f.write(dados)
        os.chmod(destino + ".parcial", 0o755)
        os.replace(destino + ".parcial", destino)
        print(f"    {nome}: {len(dados) / 1e6:.1f} MB, sha256 {tem}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
