#!/usr/bin/env python3
"""O gerador da trilha (ficha H09; godot/assets/ost/LEIA-ME.md).

Gera candidatas de cada faixa com o ACE-Step 1.5 rodando na máquina, confere
o andamento de cada uma com o mapa de batidas da H05, monta uma página para
escutar e, na escolhida, grava o OGG no lugar que o jogo procura.

O BPM, o tom e a duração vão como parâmetro do motor, não como pedido no
texto. A pasta de trabalho fica fora do repositório.

  python3 scripts/gerar_trilha.py gerar S01                 as 5 faixas da seção, 4 candidatas cada
  python3 scripts/gerar_trilha.py gerar MUS_TELA_TITULO -n 6
  python3 scripts/gerar_trilha.py gerar tudo                os 55 slots
  python3 scripts/gerar_trilha.py ouvir                     abre a página de escuta
  python3 scripts/gerar_trilha.py escolher MUS_S01_J01 2    a candidata 2 vira a faixa do jogo
  python3 scripts/gerar_trilha.py --prova                   o fluxo inteiro, com o motor de mentira

Só a biblioteca padrão do Python. O ffmpeg entra para converter e para
escrever o OGG (sem ele, o script diz o que instalar e para).
"""
import argparse
import array
import html
import json
import math
import os
import random
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import wave
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mapa_de_batidas import ESCORREGA_MS, TAXA, cliques, ler_wav, mapear  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
PROMPTS = Path(__file__).resolve().parent / "trilha_prompts.json"
OST = RAIZ / "godot" / "assets" / "ost"

URL_PADRAO = "http://127.0.0.1:8001"
ESPERA_S = 2.0  # de quanto em quanto tempo se pergunta ao servidor
PEDIDO_S = 30.0  # o tempo de cada pedido ao servidor
DESISTE_S = 600.0  # dez minutos por slot, e o script desiste com uma frase clara
CARGA_S = 3600.0  # a carga do modelo na placa, com os pesos descendo, leva o tempo que levar
MOTOR = "ace-step-1.5"
RAMPA_S = 0.005  # a rampa no fim do jingle, para não estalar


# ------------------------------------------------------------------ os lugares --

def pasta_de_trabalho():
    """A pasta das candidatas: `fontes/trilha/` na raiz do repositório.

    Fica junto do resto do material bruto (a `fontes/` inteira está no
    .gitignore), e nunca no git: WAV de rascunho não entra no repositório.
    FORJA_TRILHA troca a pasta, para quem quiser o disco noutro lugar.
    """
    escolhida = os.environ.get("FORJA_TRILHA")
    return Path(escolhida) if escolhida else RAIZ / "fontes" / "trilha"


def destino(slot, ost=OST):
    """O caminho da faixa no jogo — o mesmo que o Musica.caminho(slot) da H05."""
    if slot.startswith("MUS_S") and len(slot) >= 8:
        return Path(ost) / slot[4:7] / (slot + ".ogg")
    if slot.startswith("JIN_"):
        return Path(ost) / "jingles" / (slot + ".ogg")
    return Path(ost) / "telas" / (slot + ".ogg")


def ler_prompts(caminho=PROMPTS):
    with open(caminho, encoding="utf-8") as f:
        d = json.load(f)
    return d["faixas"], d["sufixo"]


def slots_do_alvo(faixas, alvo):
    """"tudo", uma seção ("S01") ou um slot ("MUS_S01_J01")."""
    if alvo == "tudo":
        return list(faixas)
    if alvo in faixas:
        return [alvo]
    secao = alvo.upper()
    achados = [s for s in faixas if s.startswith("MUS_" + secao + "_")]
    if not achados:
        raise SystemExit("não conheço %r: use um slot, uma seção (S01) ou tudo" % alvo)
    return achados


# ------------------------------------------------------------------ os arquivos --

def tem_ffmpeg():
    return shutil.which("ffmpeg") is not None


def exige_ffmpeg():
    if not tem_ffmpeg():
        raise SystemExit("sem ffmpeg: sudo apt install ffmpeg")


def escrever_wav(caminho, amostras, taxa=TAXA, canais=1):
    dados = array.array("h", (max(-32768, min(32767, int(v * 32767))) for v in amostras))
    if sys.byteorder == "big":
        dados.byteswap()
    with wave.open(str(caminho), "wb") as w:
        w.setnchannels(canais)
        w.setsampwidth(2)
        w.setframerate(taxa)
        w.writeframes(dados.tobytes())


def wav_de_48k_16(caminho):
    """True se já é WAV de 16 bits a 48 kHz (e dá para ler sem o ffmpeg)."""
    try:
        with wave.open(str(caminho), "rb") as w:
            return w.getsampwidth() == 2 and w.getframerate() == TAXA
    except (wave.Error, EOFError):
        return False


def normalizar(caminho):
    """A candidata vira WAV de 16 bits a 48 kHz, no lugar."""
    caminho = Path(caminho)
    if wav_de_48k_16(caminho):
        return caminho
    exige_ffmpeg()
    tmp = caminho.with_suffix(".48k.wav")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(caminho),
                    "-ar", str(TAXA), "-sample_fmt", "s16", str(tmp)], check=True)
    tmp.replace(caminho.with_suffix(".wav"))
    if caminho.suffix.lower() != ".wav":
        caminho.unlink(missing_ok=True)
    return caminho.with_suffix(".wav")


def cortar_jingle(caminho, bpm, corte_s):
    """Corta no fim do compasso mais perto de corte_s, com uma rampa no fim."""
    amostras, taxa = ler_wav(str(caminho))
    compasso = 4 * 60.0 / bpm
    compassos = max(1, int(round(corte_s / compasso)))
    fim = min(len(amostras), int(compassos * compasso * taxa))
    corte = list(amostras[:fim])
    rampa = min(int(RAMPA_S * taxa), len(corte))
    for k in range(rampa):
        corte[len(corte) - rampa + k] *= 1.0 - (k + 1) / rampa
    escrever_wav(caminho, corte, taxa)
    return compassos * compasso


# ------------------------------------------------------------------ os motores --

class MotorFalso:
    """O motor da prova: cliques no BPM do slot, sem rede e sem placa de vídeo.

    A candidata 1 sai no andamento certo; a 2 sai tocada a bpm * 1.003, para
    o escorrega ser apontado.
    """

    nome = "mentira"

    def gerar(self, slot, faixa, n, pasta, aviso=print):
        feitos = []
        for i in range(1, n + 1):
            bpm = faixa["bpm"] * (1.003 if i == 2 else 1.0)
            caminho = pasta / ("%d.wav" % i)
            escrever_wav(caminho, cliques(bpm, 0.37, float(faixa["duracao_s"])))
            feitos.append({"caminho": caminho, "semente": i})
        return feitos


class MotorAceStep:
    """O ACE-Step 1.5 pelo servidor local de API (python -m acestep.api_server).

    Os nomes dos campos se conferem na versão instalada, em /docs do servidor.
    Se algum mudou, só esta classe muda.
    """

    nome = MOTOR

    passos = 60  ## inference_steps; a tela do terminal troca por esforço

    def __init__(self, url=URL_PADRAO):
        self.url = url.rstrip("/")

    def _post(self, rota, corpo, espera=PEDIDO_S):
        pedido = urllib.request.Request(
            self.url + rota, data=json.dumps(corpo).encode("utf-8"),
            headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(pedido, timeout=espera) as r:
                resposta = json.loads(r.read().decode("utf-8"))
        except urllib.error.URLError as e:
            raise SystemExit("o servidor do ACE-Step não respondeu em %s (%s).\n"
                             "Deixe rodando noutro terminal: scripts/ace_step.sh servir" % (self.url, e))
        return self._desembrulhar(resposta)

    @staticmethod
    def _desembrulhar(resposta):
        """O servidor embrulha tudo em {data, code, error}. Aqui só o miolo passa."""
        if isinstance(resposta, dict) and "code" in resposta and "data" in resposta:
            if resposta.get("error"):
                raise SystemExit("o ACE-Step recusou: %s" % resposta["error"])
            miolo = resposta["data"]
            return miolo if isinstance(miolo, dict) else {"result": miolo}
        return resposta

    def _baixar(self, arquivo, caminho):
        """O GET /v1/audio?path=… do servidor (api_routes.py: get_audio)."""
        alvo = "%s/v1/audio?%s" % (self.url, urllib.parse.urlencode({"path": arquivo}))
        try:
            with urllib.request.urlopen(alvo, timeout=PEDIDO_S) as r:
                dados = r.read()
        except urllib.error.URLError as e:
            # o servidor pode estar na mesma máquina: o caminho serve direto
            local = Path(arquivo)
            if local.is_file():
                shutil.copyfile(local, caminho)
                return True
            raise SystemExit("não consegui baixar %r do servidor (%s)" % (arquivo, e))
        if not dados:
            raise SystemExit("o servidor devolveu um arquivo vazio para %r" % arquivo)
        caminho.write_bytes(dados)
        return True

    def _garantir_modelo(self, aviso=print):
        """O servidor sobe sem modelo nenhum: a primeira faixa manda carregar.

        Sem isto a tarefa entra na fila e fica lá para sempre
        (`/health` diz `models_initialized: false`). Na primeira vez, os pesos
        descem — são vários GB e demora.
        """
        try:
            with urllib.request.urlopen(self.url + "/health", timeout=PEDIDO_S) as r:
                saude = json.loads(r.read().decode("utf-8")).get("data", {})
        except (urllib.error.URLError, OSError, json.JSONDecodeError) as e:
            raise SystemExit("o servidor do ACE-Step não respondeu em %s (%s).\n"
                             "Deixe rodando noutro terminal: scripts/ace_step.sh servir" % (self.url, e))
        if saude.get("models_initialized"):
            return
        modelo = saude.get("loaded_model") or "acestep-v15-turbo"
        aviso("==> carregando o %s na placa (na primeira vez os pesos descem; demora)" % modelo)
        # a carga é síncrona e pode levar muitos minutos: espera própria, longa
        self._post("/v1/init", {"model": modelo}, espera=CARGA_S)
        aviso("==> modelo carregado")

    def gerar(self, slot, faixa, n, pasta, aviso=print):
        self._garantir_modelo(aviso)
        semente = random.randrange(1, 2 ** 31 - 1)
        tom = " ".join(p.capitalize() for p in str(faixa["tom"]).split())
        caption = faixa["prompt"] + " " + self.sufixo
        pedido = {
            "caption": caption,
            "prompt": caption,
            "lyrics": "[Instrumental]",
            "bpm": faixa["bpm"],
            "key_scale": tom,
            "time_signature": "4",
            "audio_duration": faixa["duracao_s"],
            "inference_steps": self.passos,
            # sem isto o servidor sorteia a semente e a faixa não se refaz
            "use_random_seed": False,
            "seed": semente,
            "batch_size": min(8, n),
            "audio_format": "wav",
        }
        tarefa = self._post("/release_task", pedido)
        task_id = tarefa.get("task_id") or tarefa.get("id")
        if not task_id:
            raise SystemExit("o /release_task não devolveu task_id: %r" % tarefa)
        começo = time.monotonic()
        while True:
            estado, itens = self._estado(task_id)
            if estado == 1:
                break
            if estado == 2:
                raise SystemExit("o ACE-Step falhou em %s (veja o terminal do servidor)" % slot)
            if time.monotonic() - começo > DESISTE_S:
                raise SystemExit("%s passou de %d minutos no ACE-Step; parei. Veja o terminal do servidor."
                                 % (slot, DESISTE_S // 60))
            time.sleep(ESPERA_S)
        feitos = []
        for i, item in enumerate(itens, start=1):
            caminho = pasta / ("%d.wav" % i)
            self._baixar(item["file"], caminho)
            feitos.append({"caminho": caminho, "semente": item.get("seed", semente)})
        if not feitos:
            raise SystemExit("o ACE-Step disse que terminou %s e não trouxe arquivo" % slot)
        return feitos

    def _estado(self, task_id):
        """(estado, itens) do /query_result — que recebe uma LISTA de task_id e
        devolve o `result` como TEXTO JSON (api_routes.py: query_result)."""
        resposta = self._post("/query_result", {"task_id_list": [task_id]})
        lista = resposta.get("result", resposta)
        if not isinstance(lista, list):
            lista = [lista]
        for entrada in lista:
            if not isinstance(entrada, dict) or entrada.get("task_id") != task_id:
                continue
            estado = int(entrada.get("status", 0))
            bruto = entrada.get("result", "[]")
            try:
                itens = json.loads(bruto) if isinstance(bruto, str) else bruto
            except json.JSONDecodeError:
                itens = []
            itens = [x for x in itens if isinstance(x, dict) and x.get("file")]
            return estado, itens
        return 0, []


# ------------------------------------------------------------------ gerar --

def gerar(alvo, n, motor, trabalho, faixas, sufixo, aviso=print):
    """O `aviso` é por onde a saída passa: print na linha de comando, o
    registro da tela do terminal na bancada (H10) — nada escreve direto na
    tela, que o Textual desenha."""
    motor.sufixo = sufixo
    slots = slots_do_alvo(faixas, alvo)
    for slot in slots:
        faixa = faixas[slot]
        pasta = trabalho / slot
        pasta.mkdir(parents=True, exist_ok=True)
        aviso("==> %s (%d bpm, %s, %ds): %d candidata(s)" % (
            slot, faixa["bpm"], faixa["tom"], faixa["duracao_s"], n))
        começo = time.monotonic()
        for i, feito in enumerate(motor.gerar(slot, faixa, n, pasta, aviso), start=1):
            caminho = normalizar(feito["caminho"])
            if slot.startswith("JIN_"):
                segundos = cortar_jingle(caminho, faixa["bpm"], faixa.get("corte_s", faixa["duracao_s"]))
                mapa, escorrega = None, False
                aviso("    %d: cortada em %.2f s (o fim do compasso)" % (i, segundos))
            else:
                amostras, taxa = ler_wav(str(caminho))
                mapa = mapear(amostras, taxa, float(faixa["bpm"]))
                escorrega = any(abs(e) > ESCORREGA_MS for e in mapa["escorrega_ms"])
                destino_mapa = caminho.with_suffix(".batidas.json")
                # o `tom` e o `titulo` vão no mapa de propósito: os sons do jogo
                # são notas do arranjo (a regra Rhythm Heaven), e quem sintetiza
                # a martelada precisa saber em que tom afinar.
                dados = {"slot": slot, "bpm": mapa["bpm"], "primeiro_tempo_s": mapa["primeiro_tempo_s"],
                         "compassos": mapa["compassos"], "secoes": [{"nome": "introducao", "compasso": 0}],
                         "conferido": False, "escorrega_ms": mapa["escorrega_ms"], "motor": motor.nome,
                         "tom": faixa["tom"], "titulo": faixa.get("titulo", "")}
                destino_mapa.write_text(json.dumps(dados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
                aviso("    %d: primeiro tempo em %.3f s, %d compassos, escorrega %s%s" % (
                    i, mapa["primeiro_tempo_s"], mapa["compassos"], mapa["escorrega_ms"],
                    "  <- escorrega demais" if escorrega else ""))
            ficha = {"slot": slot, "prompt": faixa["prompt"] + " " + sufixo, "motor": motor.nome,
                     "semente": feito.get("semente"), "data": time.strftime("%Y-%m-%d %H:%M:%S"),
                     "bpm": faixa["bpm"], "tom": faixa["tom"], "duracao_s": faixa["duracao_s"],
                     "escorrega": escorrega,
                     "primeiro_tempo_s": mapa["primeiro_tempo_s"] if mapa else None}
            caminho.with_suffix(".json").write_text(
                json.dumps(ficha, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        aviso("    %.0f s" % (time.monotonic() - começo))
    tamanho = sum(f.stat().st_size for f in trabalho.rglob("*") if f.is_file())
    aviso("A pasta de trabalho (%s) está com %.1f GB." % (trabalho, tamanho / 1e9))
    aviso("Escute: python3 scripts/gerar_trilha.py ouvir")


# ------------------------------------------------------------------ ouvir --

def fichas(trabalho):
    """Todas as candidatas da pasta de trabalho: {slot: [(n, ficha), ...]}."""
    saida = {}
    for pasta in sorted(p for p in trabalho.iterdir() if p.is_dir()):
        candidatas = []
        for f in sorted(pasta.glob("*.json"), key=lambda p: p.name):
            if f.name.endswith(".batidas.json"):
                continue
            if not f.with_suffix(".wav").is_file():
                continue
            candidatas.append((f.stem, json.loads(f.read_text(encoding="utf-8"))))
        if candidatas:
            saida[pasta.name] = candidatas
    return saida


def pagina(trabalho):
    todas = fichas(trabalho)
    partes = ["""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>A trilha do Forja — escolher</title>
<style>
 :root { color-scheme: dark; }
 body { background:#14101c; color:#eee; font:16px/1.5 system-ui, sans-serif; margin:0 auto; padding:2rem; max-width:60rem; }
 h1 { color:#ff4ecd; }
 section { border:1px solid #352b47; border-radius:.6rem; padding:1rem 1.2rem; margin:1.2rem 0; }
 h2 { margin:0 0 .3rem; color:#7af7ff; font-size:1.1rem; }
 .prompt { color:#9a90ad; font-size:.85rem; margin:0 0 1rem; }
 .candidata { border-top:1px solid #241d30; padding:.7rem 0; }
 .candidata.escorrega .titulo { text-decoration:line-through; color:#ff7a7a; }
 .titulo { font-weight:600; }
 .dados { color:#9a90ad; font-size:.85rem; }
 code { background:#241d30; padding:.15rem .4rem; border-radius:.3rem; color:#ffd36e; }
 audio { width:100%; margin:.4rem 0; }
</style></head><body>
<h1>A trilha do Forja</h1>
<p>Escute, escolha uma por faixa e rode o comando dela. A riscada escorrega o andamento mais de """
               + ("%.0f" % ESCORREGA_MS) + " ms.</p>\n"]
    if not todas:
        partes.append("<p>Nada gerado ainda. Rode <code>python3 scripts/gerar_trilha.py gerar S01</code>.</p>")
    for slot, candidatas in todas.items():
        prim = candidatas[0][1]
        partes.append('<section><h2>%s — %s bpm, %s, %s s</h2><p class="prompt">%s</p>' % (
            html.escape(slot), prim.get("bpm"), html.escape(str(prim.get("tom"))), prim.get("duracao_s"),
            html.escape(str(prim.get("prompt", "")))))
        for n, ficha in candidatas:
            mapa = trabalho / slot / (n + ".batidas.json")
            pior = "—"
            if mapa.is_file():
                m = json.loads(mapa.read_text(encoding="utf-8"))
                lista = m.get("escorrega_ms") or [0.0]
                pior = "%.1f ms" % max(abs(float(e)) for e in lista)
            partes.append(
                '<div class="candidata%s"><div class="titulo">Candidata %s</div>'
                '<audio controls preload="none" src="%s"></audio>'
                '<div class="dados">semente %s · primeiro tempo %s · pior escorrega %s · %s</div>'
                '<div class="dados">no jogo: <code>python3 scripts/gerar_trilha.py escolher %s %s</code></div></div>'
                % (" escorrega" if ficha.get("escorrega") else "", html.escape(n),
                   html.escape("%s/%s.wav" % (slot, n)), html.escape(str(ficha.get("semente"))),
                   ("%.3f s" % ficha["primeiro_tempo_s"]) if ficha.get("primeiro_tempo_s") is not None else "—",
                   pior, html.escape(str(ficha.get("data", ""))),
                   html.escape(slot), html.escape(n)))
        partes.append("</section>")
    partes.append("</body></html>\n")
    alvo = trabalho / "index.html"
    alvo.write_text("".join(partes), encoding="utf-8")
    return alvo


def ouvir(trabalho, abrir=True):
    trabalho.mkdir(parents=True, exist_ok=True)
    alvo = pagina(trabalho)
    print(alvo)
    if abrir and shutil.which("xdg-open"):
        subprocess.Popen(["xdg-open", str(alvo)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return alvo


# ------------------------------------------------------------------ escolher --

def escolher(slot, n, trabalho, ost=OST, forcar=False, aviso=print):
    origem = trabalho / slot / ("%s.wav" % n)
    if not origem.is_file():
        raise SystemExit("não achei a candidata %s de %s em %s" % (n, slot, trabalho / slot))
    alvo = destino(slot, ost)
    alvo.parent.mkdir(parents=True, exist_ok=True)
    if alvo.exists() and not forcar:
        raise SystemExit("%s já existe; ouça as duas e passe --forcar se é para trocar" % alvo)
    if tem_ffmpeg():
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(origem),
                        "-c:a", "libvorbis", "-q:a", "6", "-ar", str(TAXA), "-ac", "2", str(alvo)], check=True)
        mp3 = em_mp3(origem, slot, trabalho)
    else:
        aviso("sem ffmpeg: o OGG não foi escrito (sudo apt install ffmpeg)")
        mp3 = None
    mapa = origem.with_suffix(".batidas.json")
    if mapa.is_file() and not slot.startswith("JIN_"):
        shutil.copyfile(mapa, alvo.with_suffix(".batidas.json"))
    aviso("%s pronta. O mapa segue com \"conferido\": false: confira no metrônomo antes de jogar." % alvo)
    if mp3:
        aviso("para ouvir fora do jogo (num tocador qualquer): %s" % mp3)
    return alvo


def em_mp3(origem, slot, trabalho):
    """Uma cópia em MP3 para escutar fora do jogo, na pasta de trabalho.

    O jogo nunca toca MP3 (o LEIA-ME da trilha: o silêncio que o MP3 põe no
    começo e no fim quebra o laço e o tempo). Esta cópia é só para o ouvido,
    e por isso fica em fontes/trilha/mp3/, fora do git.
    """
    pasta = Path(trabalho) / "mp3"
    pasta.mkdir(parents=True, exist_ok=True)
    alvo = pasta / (slot + ".mp3")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(origem),
                    "-c:a", "libmp3lame", "-q:a", "2", "-ar", "44100", "-ac", "2", str(alvo)], check=True)
    return alvo


# ------------------------------------------------------------------ a prova --

def prova():
    falhas = []

    def confere(ok, frase):
        print(("ok   " if ok else "FAIL ") + frase)
        if not ok:
            falhas.append(frase)

    faixas, sufixo = ler_prompts()
    completos = [s for s, f in faixas.items()
                 if all(f.get(c) for c in ("bpm", "tom", "duracao_s", "prompt"))]
    confere(len(faixas) == 55 and len(completos) == 55,
            "os 55 slots do JSON, todos com bpm, tom, duração e prompt (%d/%d)" % (len(completos), len(faixas)))

    with tempfile.TemporaryDirectory(prefix="forja-trilha-prova-") as tmp:
        trabalho = Path(tmp) / "trabalho"
        trabalho.mkdir()
        slot = "MUS_S01_J01"
        gerar(slot, 2, MotorFalso(), trabalho, faixas, sufixo)
        f1 = json.loads((trabalho / slot / "1.json").read_text(encoding="utf-8"))
        f2 = json.loads((trabalho / slot / "2.json").read_text(encoding="utf-8"))
        confere(not f1["escorrega"], "a candidata 1 de %s passa no andamento" % slot)
        confere(f2["escorrega"], "a candidata 2 de %s é apontada como escorrega" % slot)
        m1 = json.loads((trabalho / slot / "1.batidas.json").read_text(encoding="utf-8"))
        confere(m1["motor"] == "mentira" and m1["conferido"] is False and m1["bpm"] == faixas[slot]["bpm"],
                "o mapa traz o motor, o bpm do slot e \"conferido\": false")

        alvo = ouvir(trabalho, abrir=False)
        texto = alvo.read_text(encoding="utf-8")
        confere(texto.count("<audio") == 2, "a página tem as duas candidatas")
        confere('class="candidata escorrega"' in texto and texto.count('class="candidata"') == 1,
                "só a candidata 2 sai riscada")
        confere("escolher MUS_S01_J01 2" in texto, "o comando de escolher está pronto para copiar")

        ost = Path(tmp) / "ost"
        shutil.copytree(OST, ost)
        escolher(slot, "1", trabalho, ost=ost)
        ogg = destino(slot, ost)
        confere(ogg == ost / "S01" / "MUS_S01_J01.ogg", "a faixa vai para a pasta da seção")
        confere(ogg.with_suffix(".batidas.json").is_file(), "o mapa vai junto com a faixa")
        if tem_ffmpeg():
            confere(ogg.is_file() and ogg.stat().st_size > 1000, "o OGG foi escrito")
            mp3 = trabalho / "mp3" / (slot + ".mp3")
            confere(mp3.is_file() and mp3.stat().st_size > 1000,
                    "a cópia em MP3 para escutar fora do jogo saiu em %s" % mp3.parent)
            if shutil.which("ffprobe"):
                saida = subprocess.run(
                    ["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
                     "stream=codec_name,sample_rate,channels", "-of", "csv=p=0", str(ogg)],
                    capture_output=True, text=True).stdout.strip()
                confere(saida == "vorbis,48000,2", "o OGG é Vorbis 48 kHz estéreo (%s)" % saida)
        else:
            print("ok   sem ffmpeg: a prova conferiu só o caminho e o mapa")
        confere(not destino(slot, OST).exists(), "nada foi escrito na pasta de verdade da trilha")

        jingle = "JIN_RECORDE"
        gerar(jingle, 1, MotorFalso(), trabalho, faixas, sufixo)
        amostras, taxa = ler_wav(str(trabalho / jingle / "1.wav"))
        compasso = 4 * 60.0 / faixas[jingle]["bpm"]
        esperado = max(1, int(round(faixas[jingle]["corte_s"] / compasso))) * compasso
        confere(abs(len(amostras) / taxa - esperado) < 0.01,
                "o jingle foi cortado no fim do compasso (%.2f s)" % esperado)
        confere(not (trabalho / jingle / "1.batidas.json").exists(), "o jingle não ganha mapa de batidas")

    return len(falhas)


# ------------------------------------------------------------------ a linha de comando --

def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("comando", nargs="?", choices=["gerar", "ouvir", "escolher"])
    ap.add_argument("alvo", nargs="?", help="o slot, a seção (S01) ou tudo; no escolher, o slot")
    ap.add_argument("candidata", nargs="?", help="no escolher, o número da candidata")
    ap.add_argument("-n", type=int, default=4, help="quantas candidatas por faixa (padrão 4)")
    ap.add_argument("--url", default=URL_PADRAO, help="o servidor do ACE-Step")
    ap.add_argument("--pasta", help="a pasta de trabalho (padrão: ~/.cache/forja-trilha)")
    ap.add_argument("--forcar", action="store_true", help="no escolher, troca uma faixa que já existe")
    ap.add_argument("--prova", action="store_true", help="o fluxo inteiro, com o motor de mentira")
    a = ap.parse_args()

    if a.prova:
        sys.exit(1 if prova() else 0)
    if not a.comando:
        ap.error("o comando: gerar, ouvir, escolher (ou --prova)")

    trabalho = Path(a.pasta) if a.pasta else pasta_de_trabalho()
    if a.comando == "ouvir":
        ouvir(trabalho)
        return
    if a.comando == "escolher":
        if not a.alvo or not a.candidata:
            ap.error("escolher SLOT N")
        escolher(a.alvo, a.candidata, trabalho, forcar=a.forcar)
        return
    if not a.alvo:
        ap.error("gerar SLOT|SEÇÃO|tudo")
    faixas, sufixo = ler_prompts()
    trabalho.mkdir(parents=True, exist_ok=True)
    gerar(a.alvo, a.n, MotorAceStep(a.url), trabalho, faixas, sufixo)


if __name__ == "__main__":
    main()
