#!/usr/bin/env python3
"""O portão de arte: o que a tela mostra segue a bíblia de arte.

Lê as regras de scripts/portoes/arte.json (os tokens, as cores dos jogadores,
as fontes, o tamanho mínimo, as chamadas que levam tamanho) e confere, no
escopo (godot/scripts, godot/scenes, godot/project.godot):

  1. cor só por token: nenhum `Color("#…")`, `Color(0.1, …)`, `Color8(…)`,
     `Color.html(…)` nem `Color.WHITE` fora do arquivo de tokens; e, dentro
     dele, só hex que a bíblia tem;
  2. só as fontes da bíblia: todo `.ttf`/`.otf` citado, e todo arquivo na
     pasta das fontes, está na lista;
  3. o texto mínimo: tamanho literal abaixo do mínimo numa chamada de desenho
     (pelo índice do argumento), num `font_size` de cena ou numa constante
     `T_*` do arquivo de tokens;
  4. as cores dos jogadores só nos jogadores: o hex de um jogador escrito fora
     do arquivo de tokens, e a cor de jogador pedida por índice literal
     (`JOGADOR[0]`, `cor_do_lugar(2)`): a cor do P1 usada como enfeite.

MODO: entra em AVISO (não reprova o CI) até a bíblia entrar no jogo pela G14.
Para virar, ponha "modo": "reprova" em scripts/portoes/arte.json (a ficha
V08 diz quando). Para testar a régua sem virar: --modo reprova.

Uso: python3 scripts/portoes/arte.py [--raiz DIR] [--regras ARQ] [--modo aviso|reprova]
"""
import re
import sys

import comum

COR_LITERAL = re.compile(r"\bColor8\s*\(|\bColor\.html\s*\(|\bColor\s*\(\s*(\"|'|-?\d|\.\d)")
COR_NOMEADA = re.compile(r"\bColor\.([A-Z][A-Z_]+)\b")
HEX = re.compile(r"#([0-9a-fA-F]{8}|[0-9a-fA-F]{6})\b")
FONTE = re.compile(r"[\w./-]+\.(?:ttf|otf|woff2?)\b")


def main() -> int:
    a = comum.argumentos("arte", "O portão de arte: cor, fonte, tamanho e as cores dos jogadores pela bíblia.")
    r = comum.regras(a.regras)
    rel = comum.Relato("arte", comum.modo_de(a, r))
    raiz = a.raiz
    tokens = r.get("arquivo_de_tokens", "")
    hex_da_biblia = {v.lower() for v in r.get("tokens", {}).values()} | {v.lower() for v in r.get("jogadores", {}).values()}
    hex_jogador = {v.lower(): k for k, v in r.get("jogadores", {}).items()}
    nomeadas_ok = set(r.get("cores_nomeadas_permitidas", []))
    fontes_ok = set(r.get("fontes", []))
    minimo = int(r.get("tamanho_minimo", 30))
    chamadas = r.get("chamadas_com_tamanho", {})
    em_cena = [re.compile(x) for x in r.get("tamanho_em_cena", [])]
    const_tam = re.compile(r.get("constantes_de_tamanho", r"^$"), re.M)
    por_indice = [re.compile(x) for x in r.get("jogador_por_indice_literal", [])]
    indice_ok = set(r.get("jogador_indice_literal_permitido", []))
    chamada_re = {nome: re.compile(r"(?<![\w.])" + re.escape(nome) + r"\s*\(") for nome in chamadas}

    lista = comum.arquivos(raiz, r.get("escopo", []), set(r.get("extensoes", [".gd"])), r.get("ignorar", []))
    for f in lista:
        rel_f = str(f.relative_to(raiz))
        bruto = f.read_text(encoding="utf-8", errors="replace")
        texto = comum.sem_comentarios(bruto) if f.suffix == ".gd" else bruto
        e_tokens = rel_f == tokens

        # 1. a cor
        if e_tokens:
            for m in HEX.finditer(texto):
                h = "#" + m.group(1)[:6].lower()
                if h not in hex_da_biblia:
                    rel.achou(rel_f, comum.linha_de(texto, m.start()), f"cor {h} no arquivo de tokens não está na bíblia")
        else:
            for m in COR_LITERAL.finditer(texto):
                rel.achou(rel_f, comum.linha_de(texto, m.start()), "cor escrita fora do arquivo de tokens (peça o token)")
            for m in COR_NOMEADA.finditer(texto):
                if m.group(1) not in nomeadas_ok:
                    rel.achou(rel_f, comum.linha_de(texto, m.start()), f"Color.{m.group(1)} fora do arquivo de tokens")
            for m in HEX.finditer(texto):
                h = "#" + m.group(1)[:6].lower()
                if h in hex_jogador:
                    rel.achou(rel_f, comum.linha_de(texto, m.start()),
                              f"a cor do jogador ({hex_jogador[h]}) escrita fora do arquivo de tokens")

        # 2. a fonte
        for m in FONTE.finditer(texto):
            nome = m.group(0).rsplit("/", 1)[-1]
            if nome not in fontes_ok:
                rel.achou(rel_f, comum.linha_de(texto, m.start()), f"fonte {nome} fora da bíblia")

        # 3. o tamanho
        for nome, indice in chamadas.items():
            for m in chamada_re[nome].finditer(texto):
                args = comum.args_da_chamada(texto, m.end() - 1)
                if not args or len(args) <= indice:
                    continue
                v = args[indice].strip()
                if re.fullmatch(r"\d+", v) and int(v) < minimo:
                    rel.achou(rel_f, comum.linha_de(texto, m.start()),
                              f"texto de {v} px em {nome} (o mínimo é {minimo})")
        if f.suffix in (".tscn", ".tres", ".godot"):
            for rx in em_cena:
                for m in rx.finditer(texto):
                    if int(m.group(1)) < minimo:
                        rel.achou(rel_f, comum.linha_de(texto, m.start()), f"font_size {m.group(1)} na cena (o mínimo é {minimo})")
        if e_tokens:
            for m in const_tam.finditer(texto):
                if int(m.group(1)) < minimo:
                    rel.achou(rel_f, comum.linha_de(texto, m.start()), f"tamanho {m.group(1)} no arquivo de tokens (o mínimo é {minimo})")

        # 4. a cor do jogador por índice literal
        if rel_f not in indice_ok:
            for rx in por_indice:
                for m in rx.finditer(texto):
                    rel.achou(rel_f, comum.linha_de(texto, m.start()),
                              f"a cor de um jogador pedida por índice fixo ({m.group(0)}): só o dono usa a cor dele")

    pasta = raiz / r.get("pasta_das_fontes", "")
    if r.get("pasta_das_fontes") and pasta.is_dir():
        for f in sorted(pasta.iterdir()):
            if f.suffix in (".ttf", ".otf", ".woff", ".woff2") and f.name not in fontes_ok:
                rel.achou(str(f.relative_to(raiz)), 0, "fonte na pasta das fontes que a bíblia não tem")

    return rel.fechar(f"{len(lista)} arquivos, regras de {r.get('fonte_das_regras', '?')}")


if __name__ == "__main__":
    sys.exit(main())
