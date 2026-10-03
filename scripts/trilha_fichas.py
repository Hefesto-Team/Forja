#!/usr/bin/env python3
"""A ficha de cada faixa da trilha: de onde ela vem no jogo (ficha H10).

Lê os documentos do jogo — não uma cópia deles — e devolve, por slot, o que
a faixa tem de acompanhar: a seção, o recurso protagonista da seção, o
minigame, o verbo da tela, como se joga, como se falha e como termina.

É isto que o modelo de texto recebe para escrever o título e a descrição de
cada faixa, e é isto que a tela do terminal mostra ao lado dela.

Só a biblioteca padrão.

  python3 scripts/trilha_fichas.py              as 55 fichas, em JSON
  python3 scripts/trilha_fichas.py MUS_S01_J01  uma só, legível
  python3 scripts/trilha_fichas.py --prova      confere que os 55 slots acharam ficha
"""
import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
MINIGAMES = RAIZ / "docs" / "jogo" / "03-os-45-minigames.md"
RITMO = RAIZ / "docs" / "jogo" / "04-ritmo-e-audio.md"
PROMPTS = Path(__file__).resolve().parent / "trilha_prompts.json"

## O id da seção -> o nome da sala no jogo (a ordem de docs/jogo/03).
SECOES = ["", "centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz", "prova"]

## As telas e o Relâmpago: o slot -> (onde toca, o que a música tem de fazer ali).
TELAS = {
    "MUS_TELA_TITULO": ("a tela de título", "a primeira coisa que se ouve na noite; convida a pegar o controle"),
    "MUS_TELA_CONSTRUCAO": ("a construção do cavaleiro", "quatro pessoas escolhendo peças ao mesmo tempo, sem pressa"),
    "MUS_TELA_SALAO": ("o salão entre as salas", "o lugar onde se respira, se olha a coleção e se escolhe a próxima"),
    "MUS_TELA_PODIO": ("o pódio do fim da noite", "a comemoração; toca por cima de quem está gritando"),
    "MUS_TELA_CREDITOS": ("os créditos", "o fim; dá para ouvir inteira sem pressa"),
    "MUS_RELAMPAGO": ("o Relâmpago", "a rodada curta e rápida, fora da noite inteira"),
}

## Os jingles: o slot -> o momento exato em que ele toca.
JINGLES = {
    "JIN_VITORIA": "alguém venceu o minigame",
    "JIN_DERROTA": "o minigame acabou e esta pessoa ficou em último",
    "JIN_EMPATE": "o minigame acabou empatado",
    "JIN_RECORDE": "alguém bateu o próprio recorde da noite",
}


def _secoes_do_doc(texto):
    """Os cabeçalhos «## S1 — A Centelha · botões...» e o parágrafo de clima."""
    saida = {}
    padrao = re.compile(r"^## S(\d) — (.+?) · (.+)$", re.M)
    achados = list(padrao.finditer(texto))
    for i, m in enumerate(achados):
        fim = achados[i + 1].start() if i + 1 < len(achados) else len(texto)
        corpo = texto[m.end():fim]
        clima = ""
        for par in corpo.split("\n\n"):
            par = par.strip()
            if par and not par.startswith(("**", "|", "#")):
                clima = " ".join(par.split())
                break
        saida[int(m.group(1))] = {"nome": m.group(2).strip(), "recurso": m.group(3).strip(), "clima": clima}
    return saida


def _linhas_da_tabela(texto):
    """As linhas «| 1 | **O Martelo** | TcT | "Bata!" | ... | `MUS_S01_J01` |»."""
    saida = {}
    for linha in texto.splitlines():
        if not linha.startswith("|") or "MUS_S" not in linha:
            continue
        campos = [c.strip() for c in linha.strip().strip("|").split("|")]
        if len(campos) < 8:
            continue
        slot = campos[-1].strip("`")
        if not slot.startswith("MUS_S"):
            continue
        saida[slot] = {
            "numero": campos[0],
            "minigame": re.sub(r"\*\*(.+?)\*\*", r"\1", campos[1]).strip(),
            "genero": campos[2],
            "verbo": campos[3].strip('"'),
            "como_se_joga": campos[4],
            "a_falha": campos[5],
            "fim": campos[6],
        }
    return saida


def fichas():
    """{slot: ficha}, para os 55 slots de trilha_prompts.json."""
    texto = MINIGAMES.read_text(encoding="utf-8")
    secoes = _secoes_do_doc(texto)
    tabela = _linhas_da_tabela(texto)
    faixas = json.loads(PROMPTS.read_text(encoding="utf-8"))["faixas"]

    saida = {}
    for slot, faixa in faixas.items():
        f = {"slot": slot, "bpm": faixa["bpm"], "tom": faixa["tom"], "duracao_s": faixa["duracao_s"],
             "prompt_de_hoje": faixa["prompt"]}
        if slot.startswith("MUS_S"):
            n = int(slot[5:7])
            s = secoes.get(n, {})
            f.update({"tipo": "minigame", "secao": s.get("nome", SECOES[n] if n < len(SECOES) else ""),
                      "recurso_da_secao": s.get("recurso", ""), "clima_da_secao": s.get("clima", "")})
            f.update(tabela.get(slot, {"minigame": "", "verbo": "", "como_se_joga": "",
                                       "a_falha": "", "fim": "", "genero": "", "numero": ""}))
        elif slot.startswith("JIN_"):
            f.update({"tipo": "jingle", "momento": JINGLES.get(slot, ""),
                      "corte_s": faixa.get("corte_s")})
        else:
            onde, papel = TELAS.get(slot, ("", ""))
            f.update({"tipo": "tela", "onde": onde, "papel": papel})
        saida[slot] = f
    return saida


def prova():
    f = fichas()
    falhas = 0

    def confere(ok, frase):
        nonlocal falhas
        print(("ok   " if ok else "FAIL ") + frase)
        falhas += 0 if ok else 1

    confere(len(f) == 55, "as 55 fichas (%d)" % len(f))
    minigames = [v for v in f.values() if v["tipo"] == "minigame"]
    confere(len(minigames) == 45, "os 45 minigames (%d)" % len(minigames))
    sem_nome = [v["slot"] for v in minigames if not v.get("minigame")]
    confere(not sem_nome, "todo minigame achou o nome no doc 03 (faltam: %s)" % (sem_nome or "nenhum"))
    sem_verbo = [v["slot"] for v in minigames if not v.get("verbo")]
    confere(not sem_verbo, "todo minigame achou o verbo da tela (faltam: %s)" % (sem_verbo or "nenhum"))
    sem_secao = [v["slot"] for v in minigames if not v.get("recurso_da_secao")]
    confere(not sem_secao, "toda seção achou o recurso protagonista (faltam: %s)" % (sem_secao or "nenhum"))
    telas = [v for v in f.values() if v["tipo"] == "tela"]
    confere(len(telas) == 6 and all(v["onde"] for v in telas), "as 6 telas sabem onde tocam")
    jingles = [v for v in f.values() if v["tipo"] == "jingle"]
    confere(len(jingles) == 4 and all(v["momento"] for v in jingles), "os 4 jingles sabem o momento")
    exemplo = f["MUS_S01_J01"]
    confere(exemplo["minigame"] == "O Martelo de Hefesto (a Centelha atual)",
            "MUS_S01_J01 é «%s»" % exemplo["minigame"])
    return falhas


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--prova":
        sys.exit(1 if prova() else 0)
    f = fichas()
    if arg:
        if arg not in f:
            raise SystemExit("não conheço o slot %r" % arg)
        for k, v in f[arg].items():
            print("%-18s %s" % (k, v))
        return
    print(json.dumps(f, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
