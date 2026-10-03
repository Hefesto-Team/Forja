#!/usr/bin/env python3
"""A bancada da Forja: a porta de entrada, em tela de terminal.

A mesma lista de ferramentas do `run.sh` — ela é lida de lá, para não existir
em dois lugares —, só que clicável, com o estado de cada coisa ao lado. Quem
abre a bancada vê, antes de escolher, o que já está pronto e o que falta: as
candidatas esperando escolha, o servidor no ar ou não, a memória da placa.

A ferramenta escolhida roda no terminal de verdade, não dentro da tela: a
bancada se recolhe, o comando imprime o que tem para imprimir, e ao voltar o
que ele escreveu continua no histórico, para rolar depois.

Três coisas no repositório se chamam «bancada», e é bom não confundir:
esta tela (a porta de entrada), a bancada da trilha (`trilha_tui.py`, que
conduz a geração da OST) e o Modo bancada do jogo (`tests/prova_da_bancada.sh`,
onde se valida o controle). A sem sobrenome é esta.

  ./run.sh                                       (o jeito certo)
  oficina/trilha-venv/bin/python scripts/bancada_tui.py
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from textual import on
from textual.app import App, ComposeResult
from textual.containers import Horizontal, VerticalScroll
from textual.widgets import Footer, Header, Label, ListItem, ListView, Static

RAIZ = Path(__file__).resolve().parent.parent
OFICINA = Path(os.environ.get("FORJA_OFICINA", RAIZ / "oficina"))
TRABALHO = Path(os.environ.get("FORJA_TRILHA", OFICINA / "trilha"))
OST = RAIZ / "godot" / "assets" / "ost"
## As descrições moram ao lado do script que as escreve, no git: elas são
## trabalho que se guarda, não material bruto.
PROMPTS = RAIZ / "scripts" / "trilha_prompts.json"


# ------------------------------------------------------------------ o kit --

def kit():
    """As ferramentas, lidas do run.sh. Acrescentar lá aparece aqui."""
    texto = (RAIZ / "run.sh").read_text(encoding="utf-8")
    bloco = re.search(r"^KIT=\((.*?)^\)", texto, re.S | re.M)
    if not bloco:
        raise SystemExit("não achei o KIT no run.sh")
    saida = []
    for linha in re.findall(r'"([^"]+)"', bloco.group(1)):
        partes = linha.split("|")
        if len(partes) >= 2:
            saida.append((partes[0], partes[1]))
    return saida


# ------------------------------------------------------------------ o estado --
# Cada ferramenta diz, em uma ou duas linhas, como ela está agora. É o que
# transforma um menu numa bancada: dá para decidir olhando, sem abrir nada.

def conta(pasta, sufixo):
    p = Path(pasta)
    return sum(1 for _ in p.rglob("*" + sufixo)) if p.is_dir() else 0


def peso(pasta):
    p = Path(pasta)
    if not p.is_dir():
        return "—"
    n = sum(f.stat().st_size for f in p.rglob("*") if f.is_file())
    for unidade in ("B", "kB", "MB", "GB", "TB"):
        if n < 1024 or unidade == "TB":
            return "%.0f %s" % (n, unidade) if unidade != "B" else "%d B" % n
        n /= 1024.0


def descritas():
    """Quantas das 55 já têm título e descrição escritos."""
    import json
    try:
        d = json.loads(PROMPTS.read_text(encoding="utf-8"))["faixas"]
    except (ValueError, OSError, KeyError):
        return 0
    return sum(1 for f in d.values() if f.get("titulo") and f.get("prompt"))


def servidor_no_ar():
    import urllib.error
    import urllib.request
    try:
        urllib.request.urlopen("http://127.0.0.1:8001/docs", timeout=1)
        return True
    except (urllib.error.URLError, OSError):
        return False


def placa():
    if not shutil.which("nvidia-smi"):
        return None
    try:
        s = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used,memory.total",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=4)
        usada, total = (int(x) for x in s.stdout.splitlines()[0].split(","))
        return usada, total
    except (ValueError, IndexError, OSError, subprocess.SubprocessError):
        return None


def estado(verbo):
    """Linhas de estado da ferramenta, já com a cor. Lista vazia = sem estado."""
    if verbo == "trilha":
        c = conta(TRABALHO, ".wav")
        f = conta(OST, ".ogg")
        return ["Descritas: [b]%d[/b] de 55" % descritas(),
                "Candidatas esperando escolha: [b]%d[/b]" % c,
                "Faixas já no jogo: [b]%d[/b] de 55" % f,
                "" if c else "[dim]Nada gerado ainda: é aqui que começa.[/dim]"]
    if verbo == "servidor":
        return ["[green]No ar na porta 8001[/green]" if servidor_no_ar()
                else "[yellow]Fora do ar[/yellow] — a geração precisa dele"]
    if verbo == "palavras":
        return ["Faixas com título e descrição: [b]%d[/b] de 55" % descritas()]
    if verbo == "escutar":
        return ["Candidatas: [b]%d[/b] · %s no disco" % (conta(TRABALHO, ".wav"), peso(TRABALHO))]
    if verbo == "jogo":
        mod = (RAIZ / "godot" / "bin" / "libforja.linux.x86_64.so").is_file()
        eng = list((RAIZ / "tools").glob("Godot_v*_linux.x86_64")) if (RAIZ / "tools").is_dir() else []
        return ["[green]Módulo compilado[/green]" if mod else "[yellow]Módulo por compilar[/yellow]",
                "[green]Engine: %s[/green]" % eng[-1].name if eng
                else "[yellow]Engine ainda não baixada[/yellow]"]
    if verbo == "kenney":
        pacotes = sorted(OFICINA.glob("kenney/*/assets.json")) if OFICINA.is_dir() else []
        return ["[green]O pacote está aqui: %s[/green]" % pacotes[-1].parent.name if pacotes
                else "[yellow]O pacote não foi descompactado em oficina/kenney/[/yellow]"]
    if verbo == "oficina":
        if not OFICINA.is_dir():
            return ["[yellow]Ainda não existe nesta máquina[/yellow]"]
        subs = sorted(p for p in OFICINA.iterdir() if p.is_dir())
        return ["%s · %s" % (p.name + "/", peso(p)) for p in subs[:6]]
    if verbo == "onde":
        return ["No jogo: [b]%d[/b] faixas" % conta(OST, ".ogg"),
                "Na oficina: [b]%d[/b] candidatas" % conta(TRABALHO, ".wav")]
    if verbo == "soltar":
        p = placa()
        return ["Em uso agora: [b]%d MiB[/b] de %d" % p if p else "[dim]Sem placa NVIDIA[/dim]"]
    return []


## O nome curto, para caber na lista. A frase inteira do run.sh continua
## aparecendo no painel, ao lado — a lista não corta texto, ela resume.
ROTULO = {
    "trilha": "A trilha",
    "servidor": "O servidor de música",
    "palavras": "Os títulos e as descrições",
    "escutar": "Escutar as candidatas",
    "jogo": "Abrir o jogo",
    "metronomo": "O metrônomo",
    "provas": "As provas",
    "kenney": "O pacote da Kenney",
    "onde": "Onde mora cada coisa",
    "oficina": "A oficina",
    "instalar": "Preparar esta máquina",
    "estado": "O que está instalado",
    "soltar": "Soltar a placa",
}


## O que cada ferramenta é, em uma frase que não repete o rótulo.
PORQUE = {
    "trilha": "A tela que conduz a geração: descrever, gerar, ouvir e escolher, "
              "sem nunca perder trabalho e sem nunca pôr os dois modelos na placa ao mesmo tempo.",
    "servidor": "O ACE-Step fica preso numa janela enquanto serve. Abra noutra aba "
                "e deixe de lado; a bancada da trilha conversa com ele.",
    "palavras": "O modelo de texto escreve o título e a descrição de cada faixa, "
                "a partir da ficha do minigame. Ele não repete palavra entre os 55 títulos.",
    "escutar": "Uma página no navegador com as candidatas lado a lado, "
               "para comparar de ouvido antes de escolher.",
    "jogo": "Abre A Forja na engine, com o módulo nativo compilado.",
    "metronomo": "Um clique no tempo contra a faixa escolhida. Se escorregar, "
                 "o relógio de áudio não está preso na batida — e o jogo inteiro depende disso.",
    "provas": "As provas do jogo: lobby, lugares, salas, relógio e trilha.",
    "kenney": "Procura dentro dos 24 mil arquivos do pacote comprado, sem abrir pasta nenhuma. "
              "A busca entende português: «martelo» acha «hammer».",
    "onde": "O mapa do repositório com as contas de verdade: quanto tem em cada pasta, agora.",
    "oficina": "O material bruto — o pacote da Kenney, os pesos dos modelos, as candidatas. "
               "Fica fora do git e fora do res:// da Godot, de propósito.",
    "instalar": "Prepara uma máquina nova: pacotes do sistema, módulo nativo, engine e, "
                "para quem vai gerar música, o ambiente da trilha.",
    "estado": "O que está instalado e o que falta, item por item.",
    "soltar": "Descarrega os modelos e devolve a memória da placa, agora.",
}


# ------------------------------------------------------------------ a tela --

class Bancada(App):
    ## As cores são as do app Hefesto (estudo 03): o rosa é a marca, o ciano
    ## é o que se pode fazer. Nenhuma informação vive só na cor — o item
    ## escolhido também ganha negrito e a seta.
    CSS = """
    Screen { layout: vertical; background: $surface; }
    #corpo { height: 1fr; }
    #lista { width: 38%; border: round #ff87d7; padding: 0 1; background: $surface; }
    #lista > ListItem { padding: 0 1; }
    #lista > ListItem:hover { background: #87d7ff 20%; }
    #lista > ListItem.-highlight { background: #ff87d7 25%; text-style: bold; }
    #lista:focus > ListItem.-highlight { background: #ff87d7 45%; color: $text; }
    #painel { width: 1fr; border: round #87d7ff; padding: 1 2; }
    #titulo { text-style: bold; color: #87d7ff; }
    #porque { margin: 1 0; }
    #estado { margin: 1 0; }
    #placa { height: 1; padding: 0 2; background: $panel; color: $text-muted; }
    """

    BINDINGS = [
        ("q", "sair", "Sair"),
        ("s", "soltar", "Soltar a placa"),
        ("r", "recarregar", "Atualizar"),
    ]

    def __init__(self):
        super().__init__()
        self.kit = kit()

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="corpo"):
            yield ListView(
                *[ListItem(Label("%s  [$accent]%s[/]" % (ROTULO.get(v, t), v)),
                           id="f_" + v)
                  for v, t in self.kit],
                id="lista")
            yield VerticalScroll(
                Static(id="titulo"), Static(id="porque"), Static(id="estado"),
                id="painel")
        yield Static(id="placa")
        yield Footer()

    def on_mount(self):
        self.title = "A Forja"
        self.sub_title = "a bancada"
        self.query_one("#lista", ListView).focus()
        self.set_interval(3.0, self.atualizar_placa)
        self.atualizar_placa()
        self.mostrar(0)

    # ------------------------------------------------------------ o painel --

    def mostrar(self, i):
        verbo, texto = self.kit[i]
        self.query_one("#titulo", Static).update("› %s" % texto)
        self.query_one("#porque", Static).update(PORQUE.get(verbo, ""))
        linhas = [l for l in estado(verbo) if l]
        corpo = "\n".join(linhas) if linhas else "[dim]Sem estado para mostrar.[/dim]"
        self.query_one("#estado", Static).update(
            corpo + "\n\n[dim]Na linha de comando: ./run.sh %s[/dim]" % verbo)

    def atualizar_placa(self):
        p = placa()
        if p:
            usada, total = p
            barra = "█" * round(20 * usada / total) + "░" * (20 - round(20 * usada / total))
            self.query_one("#placa", Static).update(
                "placa  %s  %d de %d MiB" % (barra, usada, total))
        else:
            self.query_one("#placa", Static).update("placa  sem NVIDIA nesta máquina")

    # ------------------------------------------------------------ as ações --

    @on(ListView.Highlighted, "#lista")
    def _andou(self, e: ListView.Highlighted):
        if e.list_view.index is not None:
            self.mostrar(e.list_view.index)

    @on(ListView.Selected, "#lista")
    def _escolheu(self, e: ListView.Selected):
        self.rodar(self.kit[e.list_view.index][0])

    def rodar(self, verbo):
        """Roda no terminal de verdade: o que o comando imprime fica no histórico."""
        ambiente = dict(os.environ, FORJA_SEM_SOLTAR="1")
        with self.suspend():
            os.system("clear")
            subprocess.run(["bash", str(RAIZ / "run.sh"), verbo], cwd=RAIZ, env=ambiente)
            input("\n  Enter para voltar à bancada ")
        self.refresh()
        self.atualizar_placa()
        if self.query_one("#lista", ListView).index is not None:
            self.mostrar(self.query_one("#lista", ListView).index)

    def action_soltar(self):
        self.rodar("soltar")

    def action_recarregar(self):
        self.atualizar_placa()
        i = self.query_one("#lista", ListView).index
        if i is not None:
            self.mostrar(i)
        self.notify("Atualizado.")

    def action_sair(self):
        self.exit()


def main():
    if "--prova" in sys.argv:
        falhas = 0

        def confere(ok, frase):
            nonlocal falhas
            print(("ok   " if ok else "FAIL ") + frase)
            falhas += 0 if ok else 1

        k = kit()
        confere(len(k) >= 10, "o kit sai do run.sh (%d ferramentas)" % len(k))
        verbos = [v for v, _ in k]
        confere("oficina" in verbos, "a oficina é uma das opções")
        confere(all(v in PORQUE for v in verbos),
                "toda ferramenta tem a frase que a explica")
        confere(isinstance(estado("onde"), list), "o estado volta como lista de linhas")
        confere(peso(RAIZ / "scripts").endswith(("kB", "MB")), "o peso de uma pasta se lê")
        sys.exit(1 if falhas else 0)
    Bancada().run()


if __name__ == "__main__":
    main()
