#!/usr/bin/env python3
"""O título e a descrição de cada faixa, por um modelo de texto local (H10).

Antes de gerar som, a trilha ganha palavras: cada um dos 55 slots recebe um
**título** em português e uma **descrição** que diz onde a faixa se encaixa e
o que ela tem de fazer ali. A descrição é o que a pessoa lê na hora de
escolher entre as candidatas; o `prompt` em inglês é o que o ACE-Step recebe.

O modelo roda na própria máquina, pelo Ollama. O contexto sai dos documentos
do jogo (`scripts/trilha_fichas.py`), não de uma cópia deles.

**Nenhum trabalho se perde:** cada slot é gravado assim que fica pronto, e
uma segunda rodada só mexe no que falta. **A placa é devolvida no fim:** o
modelo é descarregado (`keep_alive: 0`), sempre, mesmo se der erro — é o que
deixa a memória livre para o ACE-Step, que vem depois e não cabe junto.

Só a biblioteca padrão.

  python3 scripts/descrever_trilha.py                 o que falta, slot a slot
  python3 scripts/descrever_trilha.py MUS_S01_J01     um só
  python3 scripts/descrever_trilha.py S01 --refazer   a seção inteira, de novo
  python3 scripts/descrever_trilha.py --prova         sem rede e sem placa
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from trilha_fichas import fichas  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
PROMPTS = Path(__file__).resolve().parent / "trilha_prompts.json"
OLLAMA = os.environ.get("OLLAMA_HOST", "127.0.0.1:11434")
URL = "http://" + OLLAMA.replace("http://", "")
MODELO = os.environ.get("FORJA_MODELO_TEXTO", "qwen3:8b")
PEDIDO_S = 300.0

SISTEMA = """Você escreve a trilha sonora de FORJA, um jogo de ritmo local para quatro pessoas no mesmo sofá, com visual de forja medieval sob luz de néon (cyberpunk). Cada minigame dura cerca de 90 segundos e toda ação acontece na batida.

A regra que manda em tudo: **os sons do jogo são parte da música**, como em Rhythm Heaven. Cada martelada, cada passo, cada acerto é uma nota no arranjo — quatro pessoas tocando por cima da faixa ao mesmo tempo, cada uma com o som dela saindo do alto-falante do próprio controle. Então a faixa tem de deixar lugar:

- **um buraco rítmico** onde o jogador entra: o arranjo não enche todas as semicolcheias; o tempo forte é claro e o contratempo fica respirando;
- **um buraco de frequência**: a região média-aguda (de uns 800 Hz a 4 kHz), onde moram as marteladas, os cliques e os sinos do jogo, fica mais limpa que o resto; o peso vai para o grave e para o colchão de fundo;
- **nada de melodia densa no agudo** competindo com a nota de quem está jogando;
- quando o jogador acerta, o som dele tem de soar **afinado com a faixa** — então o arranjo fica no tom e na escala pedidos, sem modulação no meio.

Você responde SEMPRE com um objeto JSON e nada mais, com exatamente estas três chaves:

- "titulo": o nome da faixa em português do Brasil, com acento. De duas a cinco palavras. É nome de música, não descrição: evocativo, concreto, do mundo da forja. Nunca repita o nome do minigame tal e qual, nunca use "tema de", nunca use dois-pontos.
- "descricao": duas a três frases em português do Brasil, com acento. Diz (1) o que se ouve: instrumentos, textura, o que marca o tempo; (2) como a faixa acompanha o que acontece em cena; (3) por que ela cai bem NESTE momento do jogo. Escreva para quem vai ouvir quatro candidatas e escolher uma. Nada de jargão de IA, nada de "esta faixa".
- "prompt": a instrução em INGLÊS para o modelo de música, uma linha longa. Só estilo, instrumentos, textura, estrutura e clima. NÃO escreva BPM, tom nem duração: eles vão como parâmetro, fora do texto. Mantenha o vocabulário de synthwave e chiptune da trilha, e use as marcas de estrutura entre colchetes quando ajudarem ([Intro], [Verse], [Pre-Chorus], [Chorus], [Drop], [Outro]).

Regras de voz: português do Brasil com todos os acentos. Nunca escreva "mesa", "uinput", "hidraw" nem "MAC"."""


def _pedir(corpo, rota="/api/chat"):
    pedido = urllib.request.Request(URL + rota, data=json.dumps(corpo).encode("utf-8"),
                                    headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(pedido, timeout=PEDIDO_S) as r:
        return json.loads(r.read().decode("utf-8"))


def no_ar():
    try:
        urllib.request.urlopen(URL + "/api/tags", timeout=2).read()
        return True
    except (urllib.error.URLError, OSError):
        return False


def subir_ollama():
    """Sobe o Ollama da pasta do projeto, se não estiver no ar. Devolve o processo (ou None)."""
    if no_ar():
        return None
    binario = RAIZ / "fontes" / "ollama" / "bin" / "ollama"
    if not binario.is_file():
        raise SystemExit("o Ollama não está no ar nem instalado.\n"
                         "Instale: scripts/trilha_ambiente.sh instalar")
    ambiente = dict(os.environ)
    ambiente.setdefault("OLLAMA_MODELS", str(RAIZ / "fontes" / "modelos" / "ollama"))
    p = subprocess.Popen([str(binario), "serve"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=ambiente)
    for _ in range(40):
        if no_ar():
            return p
        time.sleep(0.5)
    p.terminate()
    raise SystemExit("o Ollama não subiu em 20 s")


def soltar_a_placa(modelo=MODELO):
    """Descarrega o modelo da memória da placa (o `ollama stop` pela API)."""
    if not no_ar():
        return False
    try:
        _pedir({"model": modelo, "prompt": "", "keep_alive": 0, "stream": False}, "/api/generate")
        return True
    except (urllib.error.URLError, OSError, json.JSONDecodeError):
        return False


def memoria_da_placa():
    """(usada_MiB, livre_MiB) — ou None sem nvidia-smi."""
    try:
        saida = subprocess.run(["nvidia-smi", "--query-gpu=memory.used,memory.free",
                                "--format=csv,noheader,nounits"], capture_output=True, text=True, check=True).stdout
        usada, livre = (int(x) for x in saida.strip().splitlines()[0].split(","))
        return usada, livre
    except (FileNotFoundError, subprocess.CalledProcessError, ValueError, IndexError):
        return None


def o_pedido(ficha, usados=()):
    """O que o modelo lê sobre esta faixa, em português, sem invenção."""
    linhas = ["Slot: %s" % ficha["slot"],
              "Andamento: %s bpm · Tom: %s · Dura %s s" % (ficha["bpm"], ficha["tom"], ficha["duracao_s"])]
    if ficha["tipo"] == "minigame":
        linhas += [
            "Seção %s — %s" % (ficha["slot"][5:7], ficha["secao"]),
            "O recurso do controle que esta seção protagoniza: %s" % ficha["recurso_da_secao"],
            "O clima da seção: %s" % ficha["clima_da_secao"],
            "Minigame %s: %s (%s)" % (ficha["numero"], ficha["minigame"], ficha["genero"]),
            "O verbo que aparece na tela: «%s»" % ficha["verbo"],
            "Como se joga: %s" % ficha["como_se_joga"],
            "Como se falha: %s" % ficha["a_falha"],
            "Como termina: %s" % ficha["fim"],
            "A faixa toca os 90 segundos inteiros do minigame e tem de deixar a batida óbvia: "
            "é por ela que a pessoa acerta o tempo.",
        ]
    elif ficha["tipo"] == "tela":
        linhas += ["Isto não é minigame: é %s." % ficha["onde"],
                   "O que a música faz ali: %s." % ficha["papel"],
                   "Toca em laço, sem emenda, enquanto a pessoa estiver nessa tela."]
    else:
        linhas += ["Isto é um jingle curto, de uns %s segundos, que toca quando %s." % (
                       ficha.get("corte_s", 5), ficha["momento"]),
                   "Entra seco, resolve e para seco. Sem introdução e sem desvanecer."]
    linhas.append("")
    linhas.append("O prompt de hoje, que você vai melhorar (não copie, melhore): " + ficha["prompt_de_hoje"])
    if usados:
        gastas = set()
        for u in usados:
            gastas |= _palavras(u)
        linhas.append("")
        linhas.append("A trilha tem 55 faixas e nenhuma repete palavra com outra. Estas palavras JÁ estão "
                      "gastas em outros títulos e NÃO podem aparecer no seu: " + ", ".join(sorted(gastas)) + ".")
        linhas.append("Procure noutro canto da forja: a ferramenta, o material, a peça, o lugar, o gesto, "
                      "o som, o bicho, o tempo. (bigorna, têmpera, escória, fole, lingote, malho, brasa, "
                      "cadinho, bainha, lima, torno, vapor, engrenagem, fuligem, limalha, solda, verniz, "
                      "ferradura, esmeril, estopa… e o que mais você souber.)")
    return "\n".join(linhas)


## As palavras que denunciam um prompt escrito em português (o ACE-Step só
## entende inglês; o título e a descrição é que são nossos).
PALAVRAS_PT = {"com", "de", "para", "que", "uma", "dos", "das", "não", "no", "na",
               "ao", "pelo", "pela", "sons", "batida", "tempo", "forja", "jogo"}


## As palavras que denunciam um título escrito em inglês (o título é nosso,
## e é em português).
## «neon» fica de fora de propósito: é palavra do jogo em português (Portões
## de Néon), e com ou sem acento vale como título nosso.
PALAVRAS_EN = {"the", "of", "and", "in", "on", "from", "with", "forge", "fire", "flame",
               "night", "steel", "iron", "song", "theme", "beat", "hammer", "anvil", "spark"}

## O tom vai como parâmetro do motor, nunca escrito no prompt.
TONS = re.compile(r"\b([A-G])(\s*#|\s*b|\s*sharp|\s*flat)?\s+(minor|major)\b", re.I)


def conferir(campos, usados=()):
    """Rejeita o que não serve, para o modelo tentar de novo. Levanta ValueError."""
    titulo, descricao, prompt = campos["titulo"], campos["descricao"], campos["prompt"]
    palavras_nuas = titulo.split()
    if not 1 <= len(palavras_nuas) <= 5:
        raise ValueError("o título tem de ter de uma a cinco palavras, e veio %r" % titulo)
    if len(palavras_nuas) == 1 and len(titulo) < 5:
        raise ValueError("uma palavra só, e curta demais: %r" % titulo)
    if ":" in titulo or titulo.lower().startswith("tema"):
        raise ValueError("o título não leva dois-pontos nem começa com «tema»")
    palavras_do_titulo = {p.strip(".,;:!?").lower() for p in titulo.split()}
    em_ingles = palavras_do_titulo & PALAVRAS_EN
    if em_ingles:
        raise ValueError("o título é em PORTUGUÊS, e veio em inglês (%s)" % ", ".join(sorted(em_ingles)))
    # a trilha tem 55 faixas: nenhuma palavra de peso se repete entre elas, ou
    # tudo vira "Chama da Forja", "Fogo da Forja", "Forja Neon"
    meu = _palavras(titulo)
    if not meu:
        raise ValueError("o título é só artigo e preposição")
    gastas = set()
    for usado in usados:
        gastas |= _palavras(usado)
    repetidas = meu & gastas
    if repetidas:
        raise ValueError("estas palavras já estão em outro título da trilha e não podem voltar: %s. "
                         "Escolha outras, de outro canto da forja (ferramenta, material, peça, lugar, gesto)"
                         % ", ".join(sorted(repetidas)))
    if len(descricao.split()) < 20:
        raise ValueError("a descrição está curta demais")
    # o prompt é para o modelo de música, que só entende inglês
    palavras = {p.strip(".,;:[]()").lower() for p in prompt.split()}
    intrusas = palavras & PALAVRAS_PT
    if intrusas or any(c in prompt for c in "áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ"):
        raise ValueError("o \"prompt\" tem de estar em INGLÊS, e veio em português (%s)"
                         % ", ".join(sorted(intrusas)[:4] or ["com acento"]))
    if any(x in prompt.lower() for x in (" bpm", "beats per minute")):
        raise ValueError("o \"prompt\" não leva BPM: ele vai como parâmetro")
    tom = TONS.search(prompt)
    if tom:
        raise ValueError("o \"prompt\" não leva o tom («%s»): ele vai como parâmetro" % tom.group(0))
    return campos


ARTIGOS = {"a", "o", "as", "os", "de", "da", "do", "das", "dos", "e", "em", "no", "na", "um", "uma"}


def _palavras(titulo):
    """As palavras de peso do título, sem acento, sem artigo e sem plural."""
    tabela = str.maketrans("áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ", "aaaaeeiooouucAAAAEEIOOOUUC")
    saida = set()
    for p in titulo.lower().translate(tabela).replace(",", " ").split():
        p = p.strip(".;:!?'\"")
        if len(p) > 3 and p.endswith("s"):
            p = p[:-1]
        if p and p not in ARTIGOS:
            saida.add(p)
    return saida


class ModeloFalso:
    """O modelo da prova: sem rede, sem placa, resposta previsível."""

    nome = "mentira"

    def descrever(self, ficha, esforco=0, usados=()):
        nome = ficha.get("minigame") or ficha.get("onde") or ficha.get("momento") or ficha["slot"]
        return {"titulo": "Bigorna de Néon %s" % ficha["slot"][-3:],
                "descricao": "Serras analógicas e uma bigorna marcando o tempo forte, sob um arpejo de néon. "
                             "A batida fica óbvia do primeiro compasso, para %s. Esforço %d." % (nome, esforco),
                "prompt": ficha["prompt_de_hoje"]}


class ModeloOllama:
    """O modelo de texto local, pelo Ollama."""

    def __init__(self, modelo=MODELO):
        self.nome = modelo

    def descrever(self, ficha, esforco=0, usados=()):
        mensagens = [{"role": "system", "content": SISTEMA},
                     {"role": "user", "content": o_pedido(ficha, usados)}]
        erro = None
        for tentativa in range(3):
            corpo = {
                "model": self.nome,
                "format": "json",
                "stream": False,
                "keep_alive": "5m",
                "options": {
                    # a janela curta e a temperatura por esforço: a 4ª tentativa
                    # arrisca mais que a 1ª, e nada disso enche a memória da placa
                    "num_ctx": 4096,
                    "temperature": min(1.1, 0.6 + 0.15 * esforco + 0.1 * tentativa),
                    "top_p": 0.9,
                },
                "messages": mensagens,
            }
            texto = _pedir(corpo).get("message", {}).get("content", "")
            try:
                campos = self._ler(texto)
                conferir(campos, usados)
                return campos
            except ValueError as e:
                erro = e
                mensagens = mensagens[:2] + [
                    {"role": "assistant", "content": texto},
                    {"role": "user", "content": "Não serviu: %s. Responda de novo, só o JSON, "
                                                "e desta vez cumpra a regra." % e},
                ]
        raise ValueError(str(erro))

    @staticmethod
    def _ler(texto):
        texto = re.sub(r"<think>.*?</think>", "", texto, flags=re.S).strip()
        try:
            d = json.loads(texto)
        except json.JSONDecodeError:
            m = re.search(r"\{.*\}", texto, re.S)
            if not m:
                raise ValueError("o modelo não devolveu JSON: %r" % texto[:200])
            d = json.loads(m.group(0))
        for chave in ("titulo", "descricao", "prompt"):
            if not isinstance(d.get(chave), str) or not d[chave].strip():
                raise ValueError("falta %r na resposta do modelo" % chave)
        return {k: " ".join(d[k].split()) for k in ("titulo", "descricao", "prompt")}


def gravar(faixas_novas):
    """Grava o trilha_prompts.json inteiro, de uma vez e sem perder o resto."""
    d = json.loads(PROMPTS.read_text(encoding="utf-8"))
    for slot, campos in faixas_novas.items():
        d["faixas"][slot].update(campos)
    tmp = PROMPTS.with_suffix(".json.novo")
    tmp.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, PROMPTS)


def slots_do_alvo(alvo, todas):
    if not alvo or alvo == "tudo":
        return list(todas)
    if alvo in todas:
        return [alvo]
    achados = [s for s in todas if s.startswith("MUS_" + alvo.upper() + "_")]
    if not achados:
        raise SystemExit("não conheço %r: use um slot, uma seção (S01) ou tudo" % alvo)
    return achados


def descrever(alvo, modelo, refazer=False, esforco=0, aviso=print):
    """Descreve o que falta (ou tudo, com --refazer). Grava slot a slot."""
    todas = fichas()
    faixas = json.loads(PROMPTS.read_text(encoding="utf-8"))["faixas"]
    alvos = [s for s in slots_do_alvo(alvo, todas)
             if refazer or not faixas[s].get("titulo") or not faixas[s].get("descricao")]
    if not alvos:
        aviso("Nada a descrever: os slots pedidos já têm título e descrição.")
        return []
    feitos, faltaram = [], []
    usados = [f["titulo"] for s, f in faixas.items() if f.get("titulo") and s not in alvos]
    for i, slot in enumerate(alvos, start=1):
        começo = time.monotonic()
        try:
            campos = modelo.descrever(todas[slot], esforco, tuple(usados))
        except (ValueError, urllib.error.URLError, OSError, json.JSONDecodeError) as e:
            # o título velho não pode ficar no lugar: apagado, a próxima rodada
            # pega este slot de novo (é o que faz «nada se perde» valer nos dois
            # sentidos — nem o que ficou pronto, nem o que falta)
            gravar({slot: {"titulo": "", "descricao": ""}})
            faltaram.append(slot)
            aviso("%s: não deu (%s); fica para a próxima rodada" % (slot, e))
            continue
        campos["descrito_por"] = getattr(modelo, "nome", "?")
        gravar({slot: campos})  # um a um: nada se perde se parar no meio
        usados.append(campos["titulo"])
        feitos.append((slot, campos))
        aviso("%d/%d %s — «%s» (%.0f s)" % (i, len(alvos), slot, campos["titulo"], time.monotonic() - começo))
    if faltaram:
        aviso("Faltaram %d: %s. Rode de novo (sem --refazer) que só eles entram."
              % (len(faltaram), ", ".join(faltaram)))
    return feitos


def prova():
    falhas = 0

    def confere(ok, frase):
        nonlocal falhas
        print(("ok   " if ok else "FAIL ") + frase)
        falhas += 0 if ok else 1

    original = PROMPTS.read_text(encoding="utf-8")
    try:
        feitos = descrever("MUS_S01_J01", ModeloFalso(), refazer=True, aviso=lambda *_: None)
        confere(len(feitos) == 1, "o modelo de mentira descreveu um slot")
        d = json.loads(PROMPTS.read_text(encoding="utf-8"))["faixas"]["MUS_S01_J01"]
        confere(bool(d.get("titulo")) and bool(d.get("descricao")), "o título e a descrição foram gravados")
        confere(d.get("descrito_por") == "mentira", "o JSON diz quem descreveu")
        confere("O Martelo de Hefesto" in d["descricao"], "a descrição fala do minigame certo")
        confere(len(json.loads(PROMPTS.read_text(encoding="utf-8"))["faixas"]) == 55,
                "os outros 54 slots continuaram no arquivo")
        texto = o_pedido(fichas()["MUS_S01_J01"])
        confere("«Bata!»" in texto and "botões, analógicos" in texto,
                "o pedido ao modelo leva o verbo da tela e o recurso da seção")
        texto_tela = o_pedido(fichas()["MUS_TELA_SALAO"])
        confere("laço" in texto_tela, "a tela pede faixa em laço")
        texto_jingle = o_pedido(fichas()["JIN_VITORIA"])
        confere("para seco" in texto_jingle, "o jingle pede parada seca")
        lido = ModeloOllama._ler('<think>penso</think>\n{"titulo":"A","descricao":"B","prompt":"C"}')
        confere(lido == {"titulo": "A", "descricao": "B", "prompt": "C"},
                "a resposta do modelo se lê mesmo com <think> na frente")
    finally:
        PROMPTS.write_text(original, encoding="utf-8")  # a prova não mexe no arquivo de verdade
    confere(PROMPTS.read_text(encoding="utf-8") == original, "o trilha_prompts.json voltou como estava")
    return falhas


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("alvo", nargs="?", default="tudo", help="um slot, uma seção (S01) ou tudo")
    ap.add_argument("--refazer", action="store_true", help="refaz mesmo o que já tem título")
    ap.add_argument("--esforco", type=int, default=0, help="0 a 3: quanto o modelo arrisca")
    ap.add_argument("--modelo", default=MODELO)
    ap.add_argument("--manter", action="store_true", help="não descarrega o modelo no fim")
    ap.add_argument("--prova", action="store_true")
    a = ap.parse_args()
    if a.prova:
        sys.exit(1 if prova() else 0)

    meu = subir_ollama()
    try:
        descrever(a.alvo, ModeloOllama(a.modelo), a.refazer, a.esforco)
    finally:
        if not a.manter:
            soltar_a_placa(a.modelo)
            if meu is not None:
                meu.terminate()
                meu.wait(timeout=20)
            m = memoria_da_placa()
            if m:
                print("A placa foi devolvida: %d MiB em uso, %d MiB livres." % m)


if __name__ == "__main__":
    main()
