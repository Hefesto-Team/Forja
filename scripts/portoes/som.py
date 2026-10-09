#!/usr/bin/env python3
"""O portão de som: todo som que o jogo toca está no mapa do áudio, e todo
arquivo do mapa tem a duração e o pico que o mapa diz, sem clique.

Lê as regras de scripts/portoes/som.json (as chamadas e o índice do argumento
que é o id, o caminho do mapa, as tolerâncias) e confere:

  1. todo id tocado existe no mapa (`docs/jogo/audio/mapa.csv`): o literal no
     argumento da chamada, e os dois lados de um `"a" if x else "b"`. Uma
     chamada sem literal (o id numa variável) aparece como «não se lê»;
  2. a grafia: o id que só existe no mapa com outra caixa é achado próprio;
  3. cada linha do mapa com `arquivo`: o arquivo existe; se é WAV, a duração
     bate com `duracao_ms` (± a tolerância), o pico não passa do `pico_dbfs`
     da linha nem do teto geral, e o começo e o fim não estalam (a amostra na janela da
     borda acima do limiar). OGG e outros: «não medido».

Sem o mapa, diz quantos ids ficaram sem conferência.

MODO: entra em AVISO (não reprova o CI) até o mapa do áudio e os arquivos
entrarem. Para virar, ponha "modo": "reprova" em scripts/portoes/som.json (a
ficha V08 diz quando). Para testar a régua sem virar: --modo reprova.

Uso: python3 scripts/portoes/som.py [--raiz DIR] [--regras ARQ] [--modo aviso|reprova]
"""
import array
import csv
import math
import re
import sys
import wave

import comum

LITERAL = re.compile(r"\"((?:[^\"\\]|\\.)*)\"|'((?:[^'\\]|\\.)*)'")


def ids_tocados(raiz, r):
    """{id: [(caminho, linha), ...]} e a lista das chamadas sem literal."""
    tocados, dinamicas = {}, []
    chamadas = r.get("chamadas", {})
    rx = {n: re.compile(r"(?<![\w.])" + re.escape(n) + r"\s*\(") for n in chamadas}
    for f in comum.arquivos(raiz, r.get("escopo", []), set(r.get("extensoes", [".gd"])), r.get("ignorar", [])):
        rel_f = str(f.relative_to(raiz))
        texto = comum.sem_comentarios(f.read_text(encoding="utf-8", errors="replace"))
        for nome, indice in chamadas.items():
            for m in rx[nome].finditer(texto):
                args = comum.args_da_chamada(texto, m.end() - 1)
                if not args or len(args) <= indice:
                    continue
                linha = comum.linha_de(texto, m.start())
                achados = [a or b for a, b in LITERAL.findall(args[indice])]
                if not achados:
                    dinamicas.append((rel_f, linha, f"{nome}({args[indice]})"))
                for i in achados:
                    tocados.setdefault(i, []).append((rel_f, linha))
    return tocados, dinamicas


def ler_mapa(caminho, colunas):
    with open(caminho, encoding="utf-8", newline="") as fh:
        linhas = list(csv.DictReader(fh))
    return [{k: (l.get(v) or "").strip() for k, v in colunas.items()} for l in linhas]


def medir_wav(caminho, janela_ms):
    """(duração em ms, pico em dBFS, maior amostra no começo, no fim), 0..1."""
    with wave.open(str(caminho), "rb") as w:
        canais, largura, taxa, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        cru = w.readframes(n)
    if largura == 1:
        amostras = [(b - 128) / 128.0 for b in cru]
    elif largura == 2:
        a = array.array("h")
        a.frombytes(cru)
        if sys.byteorder == "big":
            a.byteswap()
        amostras = [x / 32768.0 for x in a]
    elif largura == 3:
        amostras = [int.from_bytes(cru[i:i + 3], "little", signed=True) / 8388608.0 for i in range(0, len(cru), 3)]
    elif largura == 4:
        a = array.array("i")
        a.frombytes(cru)
        if sys.byteorder == "big":
            a.byteswap()
        amostras = [x / 2147483648.0 for x in a]
    else:
        raise ValueError(f"WAV de {largura * 8} bits")
    dur = n * 1000.0 / taxa if taxa else 0.0
    pico = max((abs(x) for x in amostras), default=0.0)
    pico_db = 20 * math.log10(pico) if pico > 0 else -math.inf
    borda = max(1, int(taxa * janela_ms / 1000.0)) * canais
    inicio = max((abs(x) for x in amostras[:borda]), default=0.0)
    fim = max((abs(x) for x in amostras[-borda:]), default=0.0)
    return dur, pico_db, inicio, fim


def num(s):
    try:
        return float(s.replace(",", "."))
    except (AttributeError, ValueError):
        return None


def main() -> int:
    a = comum.argumentos("som", "O portão de som: os ids tocados existem no mapa do áudio, e os arquivos batem com ele.")
    r = comum.regras(a.regras)
    rel = comum.Relato("som", comum.modo_de(a, r))
    raiz = a.raiz
    tocados, dinamicas = ids_tocados(raiz, r)
    for caminho, linha, chamada in dinamicas:
        rel.achou(caminho, linha, f"id do som não se lê ({chamada}): ponha os ids numa tabela constante")

    mapa_p = raiz / r.get("mapa", "docs/jogo/audio/mapa.csv")
    if not mapa_p.is_file():
        rel.achou(r.get("mapa"), 0, f"o mapa do áudio não existe: {len(tocados)} ids tocados sem conferência "
                                    f"({', '.join(sorted(tocados)[:12])}{'…' if len(tocados) > 12 else ''})")
        return rel.fechar(f"{len(tocados)} ids tocados")

    try:
        mapa = ler_mapa(mapa_p, r.get("colunas", {"id": "id"}))
    except (OSError, csv.Error) as e:
        print(f"som: não li o mapa {mapa_p}: {e}", file=sys.stderr)
        return 2
    ids = {l["id"] for l in mapa if l.get("id")}
    baixa = {i.lower(): i for i in ids}
    for i, onde in sorted(tocados.items()):
        if i in ids:
            continue
        caminho, linha = onde[0]
        if i.lower() in baixa:
            rel.achou(caminho, linha, f"o id «{i}» está no mapa como «{baixa[i.lower()]}» (uma grafia só)")
        else:
            rel.achou(caminho, linha, f"o id «{i}» não está no mapa do áudio")

    tol_d = float(r.get("tolerancia_duracao_ms", 30))
    tol_p = float(r.get("tolerancia_pico_db", 1.0))
    teto = float(r.get("pico_maximo_dbfs", -1.0))
    clique = r.get("clique", {})
    sem_arquivo = set(r.get("estados_sem_arquivo", []))
    raiz_res = raiz / r.get("raiz_do_res", "godot")
    medidos = 0
    for l in mapa:
        arq = l.get("arquivo", "")
        if not arq:
            continue
        if l.get("estado", "") in sem_arquivo:
            continue
        p = raiz_res / arq[len("res://"):] if arq.startswith("res://") else raiz / arq
        onde = f"{r.get('mapa')} ({l['id']})"
        if not p.is_file():
            rel.achou(onde, 0, f"o arquivo {arq} não existe")
            continue
        if p.suffix.lower() != ".wav":
            rel.achou(onde, 0, f"{arq}: não medido (só WAV se mede aqui)")
            continue
        try:
            dur, pico, ini, fim = medir_wav(p, float(clique.get("janela_ms", 2.0)))
        except (wave.Error, ValueError, EOFError) as e:
            rel.achou(onde, 0, f"{arq}: WAV ilegível ({e})")
            continue
        medidos += 1
        esperado = num(l.get("duracao_ms"))
        if esperado is not None and abs(dur - esperado) > tol_d:
            rel.achou(onde, 0, f"{arq}: dura {dur:.0f} ms e o mapa diz {esperado:.0f} ms")
        esperado = num(l.get("pico_dbfs"))
        if esperado is not None and pico > esperado + tol_p:
            rel.achou(onde, 0, f"{arq}: pico de {pico:.1f} dBFS passa do máximo do mapa, {esperado:.1f}")
        if pico > teto:
            rel.achou(onde, 0, f"{arq}: pico de {pico:.1f} dBFS passa do teto de {teto:.1f}")
        limiar = float(clique.get("limiar", 0.05))
        if ini > limiar:
            rel.achou(onde, 0, f"{arq}: estala no começo (amostra de {ini:.2f} na primeira janela)")
        if fim > limiar:
            rel.achou(onde, 0, f"{arq}: estala no fim (amostra de {fim:.2f} na última janela)")
    return rel.fechar(f"{len(tocados)} ids tocados, {len(ids)} no mapa, {medidos} arquivos medidos")


if __name__ == "__main__":
    sys.exit(main())
