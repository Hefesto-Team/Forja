# S — A noite de seis horas

**Sprint:** S · **Tamanho:** M · **Estimativa:** US$ 3,0 · **Depende de:** F06 (o registro v2), F09, H07, as seções I a Q e a R prontas; a O1 e a P1 (as linhas `pista`, `troca`, `voz` no 13); e, com o André, a noite em si

## Por quê

A validação final não é uma prova sem aparelho: é o jogo completo jogado de
verdade. Quatro pessoas, seis horas, dois controles no cabo e dois no rádio
(trocam na metade). O jogo manda e registra tudo; depois, um script cruza o
que o jogo mandou com o que a ponte do rádio registrou e com o que os
jogadores fizeram. Esta ficha escreve esse script — **inteiro aqui embaixo,
já provado** com uma noite sintética —, a prova dele, e o roteiro da noite
para o André.

## Ler antes

- [08 — A noite de seis horas](../08-a-noite-de-6-horas.md) (o protocolo e as perguntas)
- [13 — O registro v2](../13-arquitetura.md#o-registro-v2--f06-h01-h02-g02-h07) (os tipos e os campos; `pista`, `troca`, `voz` e `estacao` vêm da O1, da P1 e da Q4)
- [05 — O rádio](../05-haptica-e-controle.md#o-rádio) e o [CONTRATO](../../../CONTRATO.md) (o jogo nunca fala com a ponte)

## O que o script lê

Tudo numa **pasta da noite** (a de `--relatorios=<pasta>`):

1. **As linhas do tempo do jogo**, `linha-do-tempo-<sessão>.jsonl`, uma por
   sessão (o jogo pode ter sido reaberto na noite). Só as do formato
   `hefesto-tech-demo/linha-do-tempo/2` entram; as outras saem com aviso.
   Linhas que não são JSON são contadas e puladas. As sessões se ordenam pelo
   nome e se somam uma depois da outra — é o "tempo de noite" das horas. Uma
   sessão com `"relogio": "jogo"` (o `--acelerado` da F06) não cruza com a
   ponte.
2. **O registro da ponte**, `ponte*.csv` ou `ponte*.jsonl` (um ou vários,
   de qualquer origem). **O formato mínimo esperado** — uma linha por
   relatório USB `0x02` que a ponte recebeu para um controle:

   | campo | obrigatório | o que é |
   | --- | --- | --- |
   | `t` | sim | segundos, no relógio da ponte (qualquer origem: o script acha a diferença para o do jogo) |
   | `lugar` | um dos dois | 0..3 — o jogador; a ponte o tira das luzinhas de jogador do próprio relatório (a tabela do CONTRATO: `0x04` P1, `0x0A` P2, `0x15` P3, `0x1B` P4) |
   | `controle` | um dos dois | um nome opaco da ponte (`radio-1`...), quando ela não sabe o lugar; o `--mapa radio-1=2,...` diz de quem é. Nunca endereço de aparelho: o COMO-CONTRIBUIR proíbe |
   | `o` | não | o tipo da saída, se a ponte decodifica (`vibracao`, `gatilho`, `lightbar`, `leds_jogador`, `led_microfone`, `audio_hid`) — com ele, o casamento só junta saídas do mesmo tipo |
   | `escreveu` | não | `1`/`0` (ou `true`/`false`): a ponte escreveu no rádio; sem o campo, conta como escrita |
   | `seq` | não | a contagem da própria ponte (o `0x02` não carrega o `seq` do jogo); o script não a usa para casar |

   Exemplo em CSV:

   ```csv
   t,lugar,o,escreveu
   1042.3317,2,vibracao,1
   1042.8120,2,gatilho,1
   ```

3. **As notas à mão**, `anotacoes.txt`: uma nota por linha, `HH:MM texto`
   ("21:10 P2 pediu mais uma"). O script conta as que dizem "mais uma" (sem
   diferença de caixa nem de acento) e lista todas.

## O casamento

Por lugar e por sessão, só as saídas do jogo feitas **no rádio** (o
transporte da última `conexao` daquele lugar antes da saída é `bt`):

1. **A diferença dos relógios**, por voto: cada uma das primeiras 20 saídas
   do jogo vota em todas as diferenças `t_ponte − t_jogo` possíveis, em
   baldes de 10 ms; o balde mais votado é a diferença. Depois, o resíduo
   mediano das saídas casadas afina a diferença (o balde tem 10 ms; o
   resíduo leva ao milissegundo). `--desvio S` força uma diferença.
2. **O casamento pela ordem e pela janela**: cada saída do jogo, em ordem,
   casa com a primeira linha **livre** da ponte do mesmo lugar (e do mesmo
   `o`, se os dois têm) a menos de `--janela` (padrão 50 ms) do instante
   esperado; uma linha da ponte casa uma vez só.
3. **"A ponte escreveu"** é a linha casada com `escreveu` verdadeiro.

## As perguntas do 08 e as contas

| pergunta | a conta |
| --- | --- |
| o jogo mandou quanto? | `saida` por lugar, transporte e `o` |
| o SDL aceitou quanto? | as mesmas com `ok` |
| a ponte recebeu quanto? | as casadas no registro da ponte (só no rádio) |
| a ponte traduziu quanto? | as casadas com `escreveu` |
| o jogador percebeu? | `pista` `respondeu` `certo` sobre `pista` `mandou`, por lugar, transporte e `via`; contra o acerto dos toques nos minigames sem pista, do mesmo lugar e transporte |
| o tempo de cada um | o desvio médio e o espalhamento (desvio padrão) dos `toque` sem erro, por lugar e transporte; a `calibracao` (mediana) |
| o cansaço | o erro e o desvio por hora de noite, por lugar |
| o item | vitórias sobre participações por item (o `item` mais recente do lugar antes de cada `minigame` `terminou`) |
| a diversão | as notas com "mais uma" e a lista das notas |

E mais, para a próxima rodada de trabalho: as `troca` (o recurso que faltou,
por lugar e transporte) e os `som_controle` com e sem placa.

**A saída:** `<pasta>/cruzamento.txt` (o texto, em PT-BR, com milhar em ponto
e decimal em vírgula — "O jogo mandou 41.203 vibrações ao P3 no rádio; o SDL
aceitou 41.203; a ponte registrou 38.910 (94%) e escreveu no rádio 38.870.")
e `<pasta>/cruzamento.csv` (a tabela, para máquina: uma linha por lugar,
transporte e tipo de saída, ponto decimal). O texto sai também na tela.

## O script: `scripts/cruzar_noite.py`

Copie inteiro (é o que foi provado nesta preparação: a prova sintética
passa com as 17 checagens):

```python
#!/usr/bin/env python3
"""O cruzamento da noite de seis horas (docs/jogo/08-a-noite-de-6-horas.md).

Lê, na pasta da noite, as linhas do tempo do jogo (linha-do-tempo-*.jsonl,
formato hefesto-tech-demo/linha-do-tempo/2), o registro da ponte do rádio
(ponte*.csv ou ponte*.jsonl) e as notas à mão (anotacoes.txt), e responde,
por controle e por transporte: quanto o jogo mandou, quanto o SDL aceitou,
quanto a ponte recebeu e escreveu, quanto o jogador percebeu das pistas, o
tempo de cada um e o cansaço por hora, as vitórias por item e a diversão.

O jogo nunca fala com a ponte: o encontro é só nos arquivos, depois. Cada
saída do jogo casa com uma linha da ponte do mesmo lugar, pela ordem e por
uma janela de tempo, depois de estimar a diferença entre os dois relógios.

Só a biblioteca padrão do Python. Uso:

    python3 scripts/cruzar_noite.py <pasta da noite> [--janela 0.05] [--desvio S] [--mapa radio-1=2,...]
    python3 scripts/cruzar_noite.py --prova          # a prova, com uma noite sintética

Escreve <pasta>/cruzamento.txt e <pasta>/cruzamento.csv, e mostra o texto.
"""

import argparse
import bisect
import csv
import json
import os
import random
import statistics
import sys
import tempfile
import unicodedata
from collections import Counter, defaultdict

FORMATO_V2 = "hefesto-tech-demo/linha-do-tempo/2"
JANELA_S = 0.050  # o casamento: a saída do jogo e a linha da ponte a menos disto
PRIMEIRAS = 20  # quantas saídas do começo de cada sessão votam na diferença dos relógios
BALDE_S = 0.010  # o balde do voto


# ---------------------------------------------------------------- a leitura --

def ler_linha_do_tempo(caminho):
    """Uma sessão: {nome, formato, relogio, linhas}. Linhas sem JSON válido são contadas e puladas."""
    sessao = {"nome": os.path.basename(caminho), "formato": "", "relogio": "parede", "linhas": [], "quebradas": 0}
    with open(caminho, encoding="utf-8") as f:
        for texto in f:
            texto = texto.strip()
            if not texto:
                continue
            try:
                ev = json.loads(texto)
            except json.JSONDecodeError:
                sessao["quebradas"] += 1
                continue
            if not isinstance(ev, dict):
                sessao["quebradas"] += 1
                continue
            if ev.get("tipo") == "sessao" and "formato" in ev:
                sessao["formato"] = ev.get("formato", "")
                sessao["relogio"] = ev.get("relogio", "parede")
            if "lugar" not in ev and isinstance(ev.get("jogador"), int) and ev["jogador"] > 0:
                ev["lugar"] = ev["jogador"] - 1
            sessao["linhas"].append(ev)
    return sessao


def _bool(v):
    if isinstance(v, bool):
        return v
    return str(v).strip().lower() in ("1", "true", "sim", "verdadeiro", "yes")


def ler_ponte(caminhos, mapa):
    """O registro da ponte: lugar -> lista ordenada de {t, o, escreveu}."""
    linhas = defaultdict(list)
    sem_lugar = 0
    for caminho in caminhos:
        if caminho.endswith(".csv"):
            with open(caminho, encoding="utf-8", newline="") as f:
                brutas = list(csv.DictReader(f))
        else:
            brutas = []
            with open(caminho, encoding="utf-8") as f:
                for texto in f:
                    texto = texto.strip()
                    if texto:
                        try:
                            brutas.append(json.loads(texto))
                        except json.JSONDecodeError:
                            pass
        for r in brutas:
            try:
                t = float(r["t"])
            except (KeyError, TypeError, ValueError):
                continue
            lugar = None
            bruto = r.get("lugar")
            if bruto is not None and str(bruto).strip() != "":
                lugar = int(bruto)
            elif r.get("controle") is not None and str(r["controle"]) in mapa:
                lugar = mapa[str(r["controle"])]
            if lugar is None or not 0 <= lugar <= 3:
                sem_lugar += 1
                continue
            escreveu = _bool(r["escreveu"]) if r.get("escreveu") is not None and str(r["escreveu"]).strip() != "" else None
            linhas[lugar].append({"t": t, "o": str(r.get("o", "") or ""), "escreveu": escreveu})
    for lugar in linhas:
        linhas[lugar].sort(key=lambda x: x["t"])
    return linhas, sem_lugar


def ler_anotacoes(caminho):
    if not os.path.exists(caminho):
        return []
    with open(caminho, encoding="utf-8") as f:
        return [linha.rstrip("\n") for linha in f if linha.strip()]


def _sem_acento(s):
    return "".join(c for c in unicodedata.normalize("NFD", s.casefold()) if unicodedata.category(c) != "Mn")


# ---------------------------------------------------------------- o casamento --

def estimar_desvio(t_jogo, t_ponte):
    """A diferença entre o relógio da ponte e o do jogo (ponte = jogo + desvio), pelo voto."""
    if not t_jogo or not t_ponte:
        return None
    votos = Counter()
    for tj in t_jogo[:PRIMEIRAS]:
        for tp in t_ponte:
            votos[round((tp - tj) / BALDE_S)] += 1
    balde, n = votos.most_common(1)[0]
    if n < min(len(t_jogo), PRIMEIRAS) // 2:
        return None
    return balde * BALDE_S


def casar(saidas, ponte, desvio, janela):
    """Casa cada saída do jogo (em ordem) com a primeira linha livre da ponte do
    mesmo tipo dentro da janela; a ponte nunca volta atrás. Devolve a lista de
    índices da ponte (ou None) por saída, e a mediana do resíduo."""
    tps = [p["t"] for p in ponte]
    casados = []
    residuos = []
    usado = [False] * len(ponte)
    for s in saidas:
        alvo = s["t"] + desvio
        i = bisect.bisect_left(tps, alvo - janela)
        achou = None
        while i < len(ponte) and tps[i] <= alvo + janela:
            p = ponte[i]
            if not usado[i] and (not p["o"] or not s["o"] or p["o"] == s["o"]):
                achou = i
                break
            i += 1
        if achou is not None:
            usado[achou] = True
            residuos.append(tps[achou] - alvo)
        casados.append(achou)
    return casados, (statistics.median(residuos) if residuos else 0.0)


# ---------------------------------------------------------------- as contas --

def transporte_em(conexoes, lugar, t):
    """O transporte do lugar no instante t: o da última conexão antes dele."""
    lista = conexoes.get(lugar, [])
    i = bisect.bisect_right([c[0] for c in lista], t) - 1
    return lista[i][1] if i >= 0 else "desconhecido"


def cruzar(pasta, janela=JANELA_S, desvio_fixo=None, mapa=None):
    mapa = mapa or {}
    nomes = sorted(os.listdir(pasta))
    sessoes = [ler_linha_do_tempo(os.path.join(pasta, n)) for n in nomes
               if n.startswith("linha-do-tempo-") and n.endswith(".jsonl")]
    ponte, ponte_sem_lugar = ler_ponte([os.path.join(pasta, n) for n in nomes
                                        if n.startswith("ponte") and (n.endswith(".csv") or n.endswith(".jsonl"))], mapa)
    anotacoes = ler_anotacoes(os.path.join(pasta, "anotacoes.txt"))

    r = {
        "avisos": [], "saidas": defaultdict(lambda: {"mandou": 0, "ok": 0, "recebeu": 0, "escreveu": 0, "ponte": False}),
        "pistas": defaultdict(lambda: {"mandou": 0, "certo": 0, "errado": 0}),
        "toques": defaultdict(lambda: {"n": 0, "erros": 0, "desvios": []}),
        "horas": defaultdict(lambda: {"n": 0, "erros": 0, "desvios": []}),
        "sem_pista": defaultdict(lambda: {"n": 0, "certos": 0}),
        "itens": defaultdict(lambda: {"jogou": 0, "venceu": 0}),
        "trocas": Counter(), "som": Counter(), "calibracao": defaultdict(list),
        "desvios_relogio": [], "anotacoes": anotacoes,
        "mais_uma": [a for a in anotacoes if "mais uma" in _sem_acento(a)],
    }
    if ponte_sem_lugar:
        r["avisos"].append("%d linhas da ponte sem lugar (use --mapa controle=lugar)" % ponte_sem_lugar)

    base = 0.0  # o tempo de noite: as sessões em ordem de nome, uma depois da outra
    for s in sessoes:
        if s["formato"] != FORMATO_V2:
            r["avisos"].append("%s: formato «%s», não é o v2 — pulada" % (s["nome"], s["formato"] or "?"))
            continue
        if s["quebradas"]:
            r["avisos"].append("%s: %d linhas que não são JSON — puladas" % (s["nome"], s["quebradas"]))
        linhas = s["linhas"]
        conexoes = defaultdict(list)
        for ev in linhas:
            if ev.get("tipo") == "conexao" and "lugar" in ev and ev.get("transporte"):
                conexoes[ev["lugar"]].append((float(ev["t"]), ev["transporte"]))
        item_de = {}
        slots_com_pista = {ev.get("slot") for ev in linhas if ev.get("tipo") == "pista"}
        pista_aberta = {}
        saidas_do_lugar = defaultdict(list)
        fim = 0.0
        for ev in linhas:
            t = float(ev.get("t", 0.0))
            fim = max(fim, t)
            tipo = ev.get("tipo")
            lugar = ev.get("lugar")
            tr = transporte_em(conexoes, lugar, t) if lugar is not None else ""
            if tipo == "saida" and lugar is not None:
                o = ev.get("o", "")
                c = r["saidas"][(lugar, tr, o)]
                c["mandou"] += 1
                c["ok"] += 1 if ev.get("ok") else 0
                saidas_do_lugar[lugar].append({"t": t, "o": o, "tr": tr, "chave": (lugar, tr, o)})
            elif tipo == "som_controle" and lugar is not None:
                r["som"][(lugar, tr, ev.get("papel", ""), bool(ev.get("placa")))] += 1
            elif tipo == "troca" and lugar is not None:
                r["trocas"][(lugar, tr, ev.get("recurso", ""), ev.get("para", ""), ev.get("motivo", ""))] += 1
            elif tipo == "calibracao" and lugar is not None:
                r["calibracao"][(lugar, ev.get("transporte", tr))].append(ev.get("desvio_ms"))
            elif tipo == "pista" and lugar is not None:
                chave = (lugar, ev.get("slot"), ev.get("n"))
                if ev.get("evento") == "mandou":
                    via = ev.get("via", "")
                    r["pistas"][(lugar, tr, via)]["mandou"] += 1
                    pista_aberta[chave] = (tr, via)
                elif ev.get("evento") == "respondeu" and chave in pista_aberta:
                    # "nenhuma" não se conta: é o que sobra das mandadas
                    tr0, via = pista_aberta.pop(chave)
                    resp = ev.get("resposta", "nenhuma")
                    if resp in ("certo", "errado"):
                        r["pistas"][(lugar, tr0, via)][resp] += 1
            elif tipo == "toque" and lugar is not None:
                erro = ev.get("julgamento") == "erro"
                hora = int((base + t) // 3600)
                for grupo in (r["toques"][(lugar, tr)], r["horas"][(hora, lugar)]):
                    grupo["n"] += 1
                    grupo["erros"] += 1 if erro else 0
                    if not erro and isinstance(ev.get("desvio_ms"), (int, float)):
                        grupo["desvios"].append(float(ev["desvio_ms"]))
                if ev.get("slot") not in slots_com_pista:
                    g = r["sem_pista"][(lugar, tr)]
                    g["n"] += 1
                    g["certos"] += 0 if erro else 1
            elif tipo == "item" and lugar is not None:
                item_de[lugar] = ev.get("item", "")
            elif tipo == "minigame" and ev.get("evento") == "terminou":
                col = ev.get("colocacao", "")
                lugares = [int(x) for x in col.split(",") if x.strip() != ""] if isinstance(col, str) else list(col or [])
                for l in lugares:
                    r["itens"][item_de.get(l, "sem item")]["jogou"] += 1
                v = ev.get("vencedor", -1)
                if isinstance(v, int) and v >= 0:
                    r["itens"][item_de.get(v, "sem item")]["venceu"] += 1
        # a ponte: só com o relógio de parede
        if s["relogio"] != "parede":
            r["avisos"].append("%s: relógio «%s» — sem cruzamento com a ponte" % (s["nome"], s["relogio"]))
        else:
            for lugar, saidas in saidas_do_lugar.items():
                do_radio = [x for x in saidas if x["tr"] == "bt"]
                if not do_radio or not ponte.get(lugar):
                    continue
                desvio = desvio_fixo if desvio_fixo is not None else estimar_desvio([x["t"] for x in do_radio], [p["t"] for p in ponte[lugar]])
                if desvio is None:
                    r["avisos"].append("%s P%d: não achei a diferença dos relógios com a ponte" % (s["nome"], lugar + 1))
                    continue
                casados, residuo = casar(do_radio, ponte[lugar], desvio, janela)
                if desvio_fixo is None and abs(residuo) > 0.001:
                    desvio += residuo  # o voto acha o balde de 10 ms; o resíduo mediano afina
                    casados, _ = casar(do_radio, ponte[lugar], desvio, janela)
                r["desvios_relogio"].append((s["nome"], lugar, desvio))
                for x, i in zip(do_radio, casados):
                    c = r["saidas"][x["chave"]]
                    c["ponte"] = True
                    if i is not None:
                        c["recebeu"] += 1
                        if ponte[lugar][i]["escreveu"] is not False:
                            c["escreveu"] += 1
        base += fim
    r["horas_total"] = base / 3600.0
    return r


# ---------------------------------------------------------------- a saída --

def _n(x):
    return "{:,}".format(int(x)).replace(",", ".")


def _dec(x, casas=1):
    return ("%%.%df" % casas % x).replace(".", ",")


def _vezes(n):
    return "%s vez" % _n(n) if n == 1 else "%s vezes" % _n(n)


def _pc(a, b):
    return "—" if b == 0 else "%d%%" % round(100.0 * a / b)


def _media_dp(v):
    if not v:
        return "—", "—"
    return _dec(statistics.mean(v)), (_dec(statistics.stdev(v)) if len(v) > 1 else "0,0")


NOME_SAIDA = {"vibracao": "vibrações", "gatilho": "efeitos de gatilho", "lightbar": "cores da barra de luz",
              "leds_jogador": "luzinhas", "player_index": "números de jogador", "led_microfone": "luzes do mudo",
              "audio_hid": "ajustes do alto-falante"}
NOME_VIA = {"haptica": "háptica", "rumble": "rumble", "alto_falante": "alto-falante"}
NOME_RECURSO = {"haptica": "háptica", "microfone": "microfone", "alto_falante": "alto-falante", "giroscopio": "giroscópio",
                "rumble": "rumble", "sozinho": "sozinho", "analogico": "analógico", "tv": "TV"}
NOME_TRANSPORTE = {"usb": "no cabo", "bt": "no rádio", "virtual": "simulado", "desconhecido": "sem transporte"}


def escrever(r, pasta):
    t = []
    t.append("O cruzamento da noite (%s horas de jogo)" % _dec(r["horas_total"]))
    t.append("")
    t.append("## O que o jogo mandou, o SDL aceitou e a ponte recebeu")
    for (lugar, tr, o), c in sorted(r["saidas"].items()):
        frase = "O jogo mandou %s %s ao P%d %s; o SDL aceitou %s" % (
            _n(c["mandou"]), NOME_SAIDA.get(o, o), lugar + 1, NOME_TRANSPORTE.get(tr, tr), _n(c["ok"]))
        if c["ponte"]:
            frase += "; a ponte registrou %s (%s) e escreveu no rádio %s" % (
                _n(c["recebeu"]), _pc(c["recebeu"], c["mandou"]), _n(c["escreveu"]))
        t.append(frase + ".")
    t.append("")
    t.append("## O jogador percebeu? (as pistas só do controle)")
    for (lugar, tr, via), p in sorted(r["pistas"].items()):
        sem = r["sem_pista"].get((lugar, tr), {"n": 0, "certos": 0})
        nenhuma = p["mandou"] - p["certo"] - p["errado"]
        t.append("P%d %s respondeu às pistas por %s em %s das vezes (%s de %s; %s erradas, %s sem resposta); sem pista, acertou %s." % (
            lugar + 1, NOME_TRANSPORTE.get(tr, tr), NOME_VIA.get(via, via), _pc(p["certo"], p["mandou"]), _n(p["certo"]),
            _n(p["mandou"]), _n(p["errado"]), _n(nenhuma), _pc(sem["certos"], sem["n"])))
    t.append("")
    t.append("## O tempo de cada um")
    for (lugar, tr), g in sorted(r["toques"].items()):
        m, dp = _media_dp(g["desvios"])
        t.append("P%d %s: %s toques, %s de erro; desvio médio %s ms, espalhamento %s ms." % (
            lugar + 1, NOME_TRANSPORTE.get(tr, tr), _n(g["n"]), _pc(g["erros"], g["n"]), m, dp))
    for (lugar, tr), v in sorted(r["calibracao"].items()):
        vs = [x for x in v if isinstance(x, (int, float))]
        if vs:
            t.append("P%d %s: calibração de %s ms." % (lugar + 1, NOME_TRANSPORTE.get(tr, tr), _dec(statistics.median(vs), 0)))
    t.append("")
    t.append("## O cansaço (por hora de noite)")
    for (hora, lugar), g in sorted(r["horas"].items()):
        m, dp = _media_dp(g["desvios"])
        t.append("Hora %d, P%d: %s de erro; desvio médio %s ms, espalhamento %s ms." % (hora + 1, lugar + 1, _pc(g["erros"], g["n"]), m, dp))
    t.append("")
    t.append("## O item")
    for item, g in sorted(r["itens"].items()):
        t.append("%s: %s vitórias em %s minigames (%s)." % (item or "sem item", _n(g["venceu"]), _n(g["jogou"]), _pc(g["venceu"], g["jogou"])))
    t.append("")
    t.append("## As trocas (o recurso que faltou e o caminho que o jogo tomou)")
    for (lugar, tr, recurso, para, motivo), n in sorted(r["trocas"].items()):
        t.append("P%d %s: %s → %s (%s), %s." % (lugar + 1, NOME_TRANSPORTE.get(tr, tr), NOME_RECURSO.get(recurso, recurso),
                                              NOME_RECURSO.get(para, para), motivo.replace("_", " "), _vezes(n)))
    for (lugar, tr, papel, placa), n in sorted(r["som"].items()):
        t.append("P%d %s: %s sons em %s, %s." % (lugar + 1, NOME_TRANSPORTE.get(tr, tr), _n(n), papel, "com placa" if placa else "sem placa"))
    t.append("")
    t.append("## A diversão")
    t.append("\"Mais uma?\": %s." % _vezes(len(r["mais_uma"])))
    for a in r["anotacoes"]:
        t.append("- " + a)
    if r["desvios_relogio"] or r["avisos"]:
        t.append("")
        t.append("## Para conferir")
        for nome, lugar, d in r["desvios_relogio"]:
            t.append("%s P%d: o relógio da ponte está %s s à frente do do jogo." % (nome, lugar + 1, _dec(d, 3)))
        for a in r["avisos"]:
            t.append("Aviso: " + a)
    texto = "\n".join(t) + "\n"
    with open(os.path.join(pasta, "cruzamento.txt"), "w", encoding="utf-8") as f:
        f.write(texto)
    with open(os.path.join(pasta, "cruzamento.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["lugar", "transporte", "saida", "mandou", "sdl_aceitou", "ponte_recebeu", "ponte_escreveu",
                    "pistas", "pistas_certas", "toques", "erros", "desvio_medio_ms", "desvio_dp_ms"])
        for (lugar, tr, o), c in sorted(r["saidas"].items()):
            p = {"mandou": 0, "certo": 0}
            for (l2, tr2, _via), q in r["pistas"].items():
                if l2 == lugar and tr2 == tr:
                    p = {"mandou": p["mandou"] + q["mandou"], "certo": p["certo"] + q["certo"]}
            g = r["toques"].get((lugar, tr), {"n": 0, "erros": 0, "desvios": []})
            # a tabela é para máquina: ponto decimal, sem separador de milhar
            v = g["desvios"]
            m = "%.1f" % statistics.mean(v) if v else ""
            dp = "%.1f" % statistics.stdev(v) if len(v) > 1 else ""
            w.writerow(["P%d" % (lugar + 1), tr, o, c["mandou"], c["ok"], c["recebeu"] if c["ponte"] else "",
                        c["escreveu"] if c["ponte"] else "", p["mandou"], p["certo"], g["n"], g["erros"], m, dp])
    return texto


# ---------------------------------------------------------------- a prova --

def _gerar_noite(pasta):
    """Uma noite sintética com a resposta conhecida: duas sessões de 30 min, P1 e
    P2 no cabo e P3 e P4 no rádio na primeira, trocados na segunda; a ponte com
    o relógio adiantado (12,345 s e 500 s), um tremor de ±5 ms, e perdas
    marcadas; pistas com 94% e 71% de acerto; itens e vitórias; as notas."""
    rnd = random.Random(7)
    ponte_csv, ponte_jsonl = [], []
    for k, (nome, radio, desvio) in enumerate([("a", (2, 3), 12.345), ("b", (0, 1), 500.0)]):
        linhas = [{"t": 0.0, "tipo": "sessao", "formato": FORMATO_V2, "relogio": "parede"}]
        for l in range(4):
            linhas.append({"t": 0.1, "tipo": "conexao", "jogador": l + 1, "lugar": l,
                           "transporte": "bt" if l in radio else "usb", "evento": "conectou"})
        itens = ["MARTELO", "ESCUDO", "NENHUM", "FOLE"]
        for l in range(4):
            linhas.append({"t": 0.2, "tipo": "item", "jogador": l + 1, "lugar": l, "item": itens[l], "efeito": "leva"})
        # 1.200 vibrações por lugar, em intervalos irregulares; a ponte recebe as do rádio
        for l in range(4):
            t, seq = 1.0, 0
            for i in range(1200):
                t += rnd.uniform(0.3, 2.4)
                seq += 1
                linhas.append({"t": round(t, 3), "tipo": "saida", "jogador": l + 1, "lugar": l, "seq": seq, "o": "vibracao", "ok": True})
                if l in radio:
                    if l == radio[0] and i % 10 == 9:
                        continue  # a ponte perdeu 1 em cada 10 do primeiro do rádio
                    escreveu = i % 20 != 4  # e não escreveu 1 em cada 20 (nenhuma delas perdida)
                    linha = {"t": round(t + desvio + rnd.uniform(-0.005, 0.005), 4), "lugar": l, "o": "vibracao",
                             "escreveu": escreveu}
                    (ponte_csv if k == 0 else ponte_jsonl).append(linha)
        # as pistas: P1 94 de 100 no cabo (sessão a), P3 71 de 100 no rádio (sessão a)
        if k == 0:
            for l, certas, via in ((0, 94, "haptica"), (2, 71, "rumble")):
                for n in range(100):
                    tp = 100.0 + n * 10.0 + l
                    linhas.append({"t": tp, "tipo": "pista", "jogador": l + 1, "lugar": l, "slot": "S07_J32", "n": n,
                                   "evento": "mandou", "via": via, "o_que": "firme"})
                    resp = "certo" if n < certas else ("errado" if n % 2 == 0 else "nenhuma")
                    linhas.append({"t": tp + 0.3, "tipo": "pista", "jogador": l + 1, "lugar": l, "slot": "S07_J32", "n": n,
                                   "evento": "respondeu", "resposta": resp})
        # os toques: 300 por lugar, 5% de erro, desvio conhecido
        for l in range(4):
            for n in range(300):
                erro = n % 20 == 0
                linhas.append({"t": 50.0 + n * 5.0 + l * 0.1, "tipo": "toque", "jogador": l + 1, "lugar": l, "slot": "S01_J01",
                               "n": n, "julgamento": "erro" if erro else "otimo", "desvio_ms": None if erro else (10.0 if n % 2 else 30.0)})
        # dez minigames: vence o P1 em 4, o P2 em 3, o P3 em 2, o P4 em 1
        for m, v in enumerate([0, 0, 0, 0, 1, 1, 1, 2, 2, 3]):
            linhas.append({"t": 1600.0 + m, "tipo": "minigame", "slot": "S01_J01", "evento": "terminou", "vencedor": v,
                           "colocacao": ",".join(str(x) for x in [v] + [y for y in range(4) if y != v])})
        if k == 0:
            linhas.append({"t": 5.0, "tipo": "troca", "jogador": 3, "lugar": 2, "slot": "S07_J32", "recurso": "haptica",
                           "para": "rumble", "motivo": "sem_placa"})
        linhas.sort(key=lambda e: e["t"])
        with open(os.path.join(pasta, "linha-do-tempo-noite-%s.jsonl" % nome), "w", encoding="utf-8") as f:
            for e in linhas:
                f.write(json.dumps(e, ensure_ascii=False) + "\n")
    with open(os.path.join(pasta, "ponte-a.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["t", "lugar", "o", "escreveu"])
        w.writeheader()
        for linha in ponte_csv:
            w.writerow({**linha, "escreveu": "1" if linha["escreveu"] else "0"})
    with open(os.path.join(pasta, "ponte-b.jsonl"), "w", encoding="utf-8") as f:
        for linha in ponte_jsonl:
            f.write(json.dumps(linha) + "\n")
    # uma sessão v1 (deve ser pulada) e as notas à mão
    with open(os.path.join(pasta, "linha-do-tempo-velha.jsonl"), "w", encoding="utf-8") as f:
        f.write(json.dumps({"t": 0.0, "tipo": "sessao", "formato": "hefesto-tech-demo/linha-do-tempo/1"}) + "\n")
    with open(os.path.join(pasta, "anotacoes.txt"), "w", encoding="utf-8") as f:
        f.write("21:10 P2 pediu mais uma\n22:40 P4 reclamou do Mecha Cego no rádio\n23:55 Todos: MAIS UMA!\n")


def prova():
    falhas = []

    def espera(cond, msg):
        print(("ok   " if cond else "FAIL ") + msg)
        if not cond:
            falhas.append(msg)

    with tempfile.TemporaryDirectory() as pasta:
        _gerar_noite(pasta)
        r = cruzar(pasta)
        texto = escrever(r, pasta)
        s = r["saidas"]
        espera(s[(2, "bt", "vibracao")]["mandou"] == 1200 and s[(2, "bt", "vibracao")]["ok"] == 1200, "P3 no rádio: o jogo mandou 1.200 e o SDL aceitou 1.200")
        espera(s[(2, "bt", "vibracao")]["recebeu"] == 1080, "P3 no rádio: a ponte recebeu 1.080 (perdeu 1 em 10): %d" % s[(2, "bt", "vibracao")]["recebeu"])
        espera(s[(2, "bt", "vibracao")]["escreveu"] == 1020, "P3 no rádio: a ponte escreveu 1.020: %d" % s[(2, "bt", "vibracao")]["escreveu"])
        espera(s[(3, "bt", "vibracao")]["recebeu"] == 1200 and s[(3, "bt", "vibracao")]["escreveu"] == 1140, "P4 no rádio: 1.200 recebidas, 1.140 escritas: %d, %d" % (s[(3, "bt", "vibracao")]["recebeu"], s[(3, "bt", "vibracao")]["escreveu"]))
        espera(s[(0, "bt", "vibracao")]["recebeu"] == 1080 and s[(1, "bt", "vibracao")]["recebeu"] == 1200, "a segunda sessão (a troca: P1 e P2 no rádio), pelo JSONL da ponte: %d, %d" % (s[(0, "bt", "vibracao")]["recebeu"], s[(1, "bt", "vibracao")]["recebeu"]))
        espera(not s[(0, "usb", "vibracao")]["ponte"] and s[(0, "usb", "vibracao")]["mandou"] == 1200, "P1 no cabo: sem ponte, 1.200 mandadas")
        d = {(nome, l): v for nome, l, v in r["desvios_relogio"]}
        espera(abs(d[("linha-do-tempo-noite-a.jsonl", 2)] - 12.345) < 0.003, "o relógio da ponte achado: 12,345 s na sessão a (%.3f)" % d[("linha-do-tempo-noite-a.jsonl", 2)])
        espera(abs(d[("linha-do-tempo-noite-b.jsonl", 0)] - 500.0) < 0.003, "e 500 s na sessão b")
        espera(r["pistas"][(0, "usb", "haptica")]["certo"] == 94 and r["pistas"][(2, "bt", "rumble")]["certo"] == 71, "as pistas: P1 94 de 100, P3 71 de 100")
        espera("P1 no cabo respondeu às pistas por háptica em 94%" in texto and "P3 no rádio respondeu às pistas por rumble em 71%" in texto, "a frase das pistas")
        espera("(71 de 100; 14 erradas, 15 sem resposta)" in texto, "as pistas sem resposta são as que sobram")
        g = r["toques"][(0, "usb")]
        # os erros são os n múltiplos de 20 (pares): sobram 150 de 10 ms e 135 de 30 ms
        espera(g["n"] == 300 and g["erros"] == 15 and abs(statistics.mean(g["desvios"]) - 5550.0 / 285.0) < 1e-9,
               "os toques do P1 no cabo: 300, 15 erros, 19,5 ms de desvio médio")
        espera(r["itens"]["MARTELO"]["venceu"] == 8 and r["itens"]["MARTELO"]["jogou"] == 20, "o Martelo: 8 vitórias em 20 minigames")
        espera(len(r["mais_uma"]) == 2, "duas vezes \"mais uma\" nas notas à mão")
        espera(any("formato" in a and "velha" in a for a in r["avisos"]), "a sessão v1 foi pulada com aviso")
        espera(os.path.exists(os.path.join(pasta, "cruzamento.csv")) and os.path.exists(os.path.join(pasta, "cruzamento.txt")), "a tabela e o texto na pasta")
        espera("O jogo mandou 1.200 vibrações ao P3 no rádio; o SDL aceitou 1.200; a ponte registrou 1.080 (90%)" in texto, "a frase do 08, com os números")
    if falhas:
        print("FAIL a prova do cruzamento: %d falhas" % len(falhas))
        return 1
    print("prova do cruzamento ok")
    return 0


def main():
    ap = argparse.ArgumentParser(description="O cruzamento da noite de seis horas.")
    ap.add_argument("pasta", nargs="?", help="a pasta da noite (os relatórios do jogo e o registro da ponte)")
    ap.add_argument("--janela", type=float, default=JANELA_S, help="a janela do casamento, em s (padrão 0,05)")
    ap.add_argument("--desvio", type=float, default=None, help="força a diferença dos relógios (ponte = jogo + desvio), em s")
    ap.add_argument("--mapa", default="", help="controle=lugar da ponte, separados por vírgula (lugar 0..3)")
    ap.add_argument("--prova", action="store_true", help="roda a prova com uma noite sintética")
    a = ap.parse_args()
    if a.prova:
        return prova()
    if not a.pasta or not os.path.isdir(a.pasta):
        ap.error("diga a pasta da noite")
    mapa = {}
    for par in filter(None, a.mapa.split(",")):
        nome, _, lugar = par.partition("=")
        mapa[nome.strip()] = int(lugar)
    r = cruzar(a.pasta, a.janela, a.desvio, mapa)
    print(escrever(r, a.pasta), end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

## A prova

- **`tests/prova_do_cruzamento.sh`** (novo):

  ```bash
  #!/usr/bin/env bash
  # A prova do cruzamento da noite: uma noite sintética com a resposta
  # conhecida (duas sessões, a troca de cabo e rádio na metade, a ponte com o
  # relógio adiantado e perdas marcadas, em CSV e em JSONL, pistas, toques,
  # itens, uma sessão v1 e as notas à mão). Só Python, sem Godot.
  set -eu
  RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
  python3 "$RAIZ/scripts/cruzar_noite.py" --prova
  ```

  `chmod +x`. Ela passa **sem aparelho e sem Godot** (uns 0,3 s).
- **Com uma rodada de robôs** (com o André, local — o `./run-local.sh` abre
  a janela e não roda numa sessão da nuvem): uma partida de robô com os
  relatórios numa pasta,
  `./run-local.sh -- --simular=4 --robo --partida=5 --sorteada --relatorios=<pasta>`,
  e `python3 scripts/cruzar_noite.py <pasta>`. Os controles simulados são
  `virtual`: a seção da ponte fica vazia, as outras respondem (as pistas com
  `via` `haptica`, os toques, os itens) sem erro.
- Acrescente `bash tests/prova_do_cruzamento.sh` à lista "Antes de todo push"
  do `docs/DESENVOLVER.md` (as provas rápidas).

## A noite (com o André)

O protocolo é o do 08. O que esta ficha acrescenta, na ordem:

1. **Antes:** `scripts/exportar.sh tudo && bash tests/prova_da_exportacao.sh`
   (a noite roda o pacote exportado, a regra 6 da paridade); a pasta da noite
   vazia; a ponte gravando o registro dela **na mesma pasta**, no formato
   acima; `bash tests/prova_do_cruzamento.sh` verde.
2. **Começo:** o pacote com `--relatorios=<pasta da noite>`; P1 e P2 no cabo,
   P3 e P4 no rádio; o Relâmpago de aquecimento (três vidas).
3. **A noite:** partidas sorteadas de 5 e de 9; os 45 minigames aparecem pelo
   menos uma vez (a partida de 9 é uma de cada seção: umas cinco partidas de
   9 cobrem); dez minutos de pausa a cada hora; na metade, P1 e P2 vão para o
   rádio e P3 e P4 para o cabo (o jogo segue; a `conexao` registra a troca).
4. **Durante:** só as notas à mão em `anotacoes.txt` — quem pediu "mais uma",
   quem reclamou do quê, a hora do cansaço. O jogo não pergunta nada a
   ninguém.
5. **Depois:** `python3 scripts/cruzar_noite.py <pasta da noite>`; os
   resultados (o `cruzamento.txt` resumido, os números que importam) entram
   em `docs/jogo/08-a-noite-de-6-horas.md`, numa seção "A primeira noite
   (<data>)", e em `experimental/RESULTADOS.md`.
6. **Cada número estranho vira uma ficha nova** no [quadro](README.md): uma
   ponte que registrou 90% das vibrações de um controle, um P3 que respondeu
   71% às pistas no rádio contra 94% no cabo, um desvio que cresce depois da
   terceira hora.
7. **O que sobrou do Sprint A:** o `.exe` pela Steam (a Steam Input no
   caminho), a TV de 40" a 3 m (o texto de 30 px lido do sofá), o Steam Deck
   (um controle a mais) — cada um com uma linha nas notas à mão.

## Armadilhas

- **Nenhum endereço de aparelho** no registro da ponte, no script ou no
  relatório (o COMO-CONTRIBUIR): a ponte identifica pelo lugar (as luzinhas do
  relatório) ou por um nome opaco com `--mapa`. Se a ponte de hoje só souber
  o endereço, ela escreve um nome opaco e guarda a tabela dela fora da pasta
  da noite.
- **O relógio da ponte não é o do jogo.** Nunca some ou compare os `t` direto:
  o script acha a diferença por sessão e por lugar (o jogo reaberto começa do
  zero; a ponte, não).
- **Saídas periódicas enganam o voto** (uma saída por segundo casaria com a
  ponte deslocada de um segundo). O jogo de verdade não é periódico; se o
  aviso "não achei a diferença dos relógios" aparecer, rode com `--desvio`
  (a diferença que a ponte mostrar numa saída conhecida, como o `player_index`
  da conexão).
- **"Sem resposta" é o que sobra:** o script conta as `pista` `mandou` e as
  respostas `certo`/`errado`; as outras são "sem resposta" (o `respondeu`
  `nenhuma` que o minigame grava só confirma).
- **Só biblioteca padrão:** nada de `pandas`, `numpy` ou `matplotlib` — o
  script tem de rodar no computador da noite sem instalar nada.

## Pronto quando

`bash tests/prova_do_cruzamento.sh` passa; o script responde as perguntas do
08 numa pasta de robôs (sem a ponte) sem erro; a noite acontece, os quatro
jogam seis horas com vontade, e o cruzamento responde as perguntas para os
quatro controles nos dois transportes; os resultados estão no 08 e em
`experimental/RESULTADOS.md`; e cada número estranho virou ficha.

## Provas

- **Na sessão:** `bash tests/prova_do_cruzamento.sh` e `bash tests/prova_do_jogo.sh`
  (nada do jogo muda, mas a regra é a de todo push).
- **Com o André:** a noite inteira, e o cruzamento sobre a pasta dela.

## Ao terminar

- No [quadro](README.md), a linha S: **feito**, com o commit e o gasto real;
  e as fichas novas que a noite pediu.
- Commits sugeridos (sem trailer):
  `feat: o cruzamento da noite — o jogo, a ponte e os jogadores, por controle e por transporte`
  e, depois da noite, `docs: a primeira noite de seis horas, e o que ela pediu`
