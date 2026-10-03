#!/usr/bin/env python3
"""A bancada da trilha: a tela do terminal que conduz a geração da OST (H10).

Uma tela só, com os 55 slots à esquerda e, à direita, a ficha da faixa (de que
minigame ela é, que verbo aparece na tela, como se joga), o título e a
descrição escritos pelo modelo de texto, e as candidatas já geradas com o
andamento de cada uma.

O que ela garante, e é por isso que ela existe:

- **Nenhum trabalho se perde.** Tudo é gravado assim que fica pronto: a
  descrição no `trilha_prompts.json`, as candidatas na pasta de trabalho.
  Fechar a tela no meio não apaga nada; ao abrir de novo, ela continua.
- **Dois modelos nunca dividem a placa.** O de texto (Ollama) e o de música
  (ACE-Step) não cabem juntos nos 8 GB. Antes de gerar som, a tela descarrega
  o de texto; antes de escrever texto, ela avisa quanto sobra. Ao sair,
  solta os dois e mostra a memória devolvida.
- **O controle é seu enquanto escuta.** Refazer, pedir mais esforço, gerar
  mais candidatas e escolher são botões, com a faixa tocando.

  scripts/trilha_ambiente.sh tela            (o jeito certo: usa o ambiente)
  oficina/trilha-venv/bin/python scripts/trilha_tui.py
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import descrever_trilha as dt  # noqa: E402
import gerar_trilha as gt  # noqa: E402
from trilha_fichas import fichas  # noqa: E402

from textual import on, work  # noqa: E402
from textual.app import App, ComposeResult  # noqa: E402
from textual.containers import Horizontal, Vertical, VerticalScroll  # noqa: E402
from textual.widgets import (  # noqa: E402
    Button, DataTable, Footer, Header, Log, Static,
)

ESFORCOS = [
    # (rótulo, candidatas, passos do ACE-Step, risco do modelo de texto)
    ("leve", 2, 32, 0),
    ("normal", 4, 60, 1),
    ("caprichado", 6, 90, 2),
    ("teimoso", 8, 120, 3),
]


class Bancada(App):
    CSS = """
    Screen { layout: vertical; }
    #corpo { height: 1fr; }
    #lista { width: 46%; border: round $primary; }
    #direita { width: 1fr; }
    #ficha { border: round $primary; padding: 0 1; height: 1fr; }
    #registro { border: round $accent; height: 10; }
    #botoes { height: auto; padding: 0 1; }
    #botoes Button { margin: 0 1 0 0; min-width: 14; }
    #placa { padding: 0 1; color: $text-muted; }
    .titulo { text-style: bold; color: $accent; }
    """

    BINDINGS = [
        ("d", "descrever", "Descrever"),
        ("g", "gerar", "Gerar"),
        ("m", "mais_esforco", "Mais esforço"),
        ("r", "refazer", "Refazer"),
        ("e", "escolher", "Escolher"),
        ("o", "ouvir", "Ouvir"),
        ("t", "tudo", "Tudo"),
        ("l", "soltar", "Soltar a placa"),
        ("q", "sair", "Sair"),
    ]

    def __init__(self):
        super().__init__()
        self.trabalho = gt.pasta_de_trabalho()
        self.trabalho.mkdir(parents=True, exist_ok=True)
        self.esforco = 1
        self.ocupada = False
        self.ollama = None  # o processo do Ollama, se fomos nós que subimos
        self.fichas = {}
        self.faixas = {}

    # ---------------------------------------------------------------- a tela --

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="corpo"):
            yield DataTable(id="lista", cursor_type="row", zebra_stripes=True)
            with Vertical(id="direita"):
                yield VerticalScroll(Static(id="ficha"))
                yield Log(id="registro", highlight=False)
        yield Static(id="placa")
        with Horizontal(id="botoes"):
            yield Button("Descrever", id="b_descrever", variant="primary")
            yield Button("Gerar", id="b_gerar", variant="success")
            yield Button("Mais esforço", id="b_esforco")
            yield Button("Refazer", id="b_refazer", variant="warning")
            yield Button("Escolher", id="b_escolher", variant="success")
            yield Button("Ouvir", id="b_ouvir")
            yield Button("Soltar a placa", id="b_soltar", variant="error")
        yield Footer()

    def on_mount(self) -> None:
        self.title = "A trilha do FORJA"
        t = self.query_one("#lista", DataTable)
        t.add_columns("slot", "título", "estado", "pior escorrega")
        self.recarregar()
        self.atualizar_placa()
        self.set_interval(5.0, self.atualizar_placa)
        self.registrar("A pasta de trabalho é %s" % self.trabalho)
        self.registrar("Esforço: %s. Nada é apagado: sair no meio não perde trabalho." % self.rotulo_do_esforco())

    # ---------------------------------------------------------------- o estado --

    def rotulo_do_esforco(self):
        r, n, passos, _ = ESFORCOS[self.esforco]
        return "%s (%d candidatas, %d passos)" % (r, n, passos)

    def recarregar(self) -> None:
        self.fichas = fichas()
        self.faixas = json.loads(dt.PROMPTS.read_text(encoding="utf-8"))["faixas"]
        t = self.query_one("#lista", DataTable)
        linha = t.cursor_row
        t.clear()
        for slot in self.faixas:
            estado, pior = self.estado_do_slot(slot)
            t.add_row(slot, self.faixas[slot].get("titulo", "—")[:28], estado, pior, key=slot)
        if linha is not None and linha < t.row_count:
            t.move_cursor(row=linha)
        self.mostrar_ficha()

    def candidatas(self, slot):
        pasta = self.trabalho / slot
        if not pasta.is_dir():
            return []
        saida = []
        for f in sorted(pasta.glob("*.json")):
            if f.name.endswith(".batidas.json") or not f.with_suffix(".wav").is_file():
                continue
            saida.append((f.stem, json.loads(f.read_text(encoding="utf-8"))))
        return saida

    def estado_do_slot(self, slot):
        if gt.destino(slot).exists():
            return "escolhida ✓", ""
        c = self.candidatas(slot)
        if c:
            boas = sum(1 for _, f in c if not f.get("escorrega"))
            pior = ""
            mapa = self.trabalho / slot / (c[0][0] + ".batidas.json")
            if mapa.is_file():
                e = json.loads(mapa.read_text(encoding="utf-8")).get("escorrega_ms") or [0.0]
                pior = "%.1f ms" % max(abs(float(x)) for x in e)
            return "%d candidatas (%d no tempo)" % (len(c), boas), pior
        if self.faixas[slot].get("titulo"):
            return "descrita", ""
        return "—", ""

    @property
    def slot(self):
        t = self.query_one("#lista", DataTable)
        if t.cursor_row is None or t.row_count == 0:
            return ""
        return str(t.get_row_at(t.cursor_row)[0])

    def mostrar_ficha(self) -> None:
        slot = self.slot
        if not slot:
            return
        f, faixa = self.fichas[slot], self.faixas[slot]
        linhas = ["[b]%s[/b]  ·  %s bpm  ·  %s  ·  %s s" % (slot, f["bpm"], f["tom"], f["duracao_s"]), ""]
        if f["tipo"] == "minigame":
            linhas += ["[dim]Seção[/dim] %s — protagoniza %s" % (f["secao"], f["recurso_da_secao"]),
                       "[dim]Minigame[/dim] %s · %s · verbo «%s»" % (f["minigame"], f["genero"], f["verbo"]),
                       "[dim]Como se joga[/dim] %s" % f["como_se_joga"],
                       "[dim]A falha[/dim] %s" % f["a_falha"],
                       "[dim]O fim[/dim] %s" % f["fim"]]
        elif f["tipo"] == "tela":
            linhas += ["[dim]Toca em[/dim] %s" % f["onde"], "[dim]O papel[/dim] %s" % f["papel"]]
        else:
            linhas += ["[dim]Jingle de %s s[/dim] quando %s" % (f.get("corte_s", 5), f["momento"])]
        linhas.append("")
        if faixa.get("titulo"):
            linhas += ["[b green]%s[/b green]" % faixa["titulo"], faixa.get("descricao", ""), ""]
        else:
            linhas += ["[yellow]Sem título ainda. Botão Descrever (D).[/yellow]", ""]
        linhas += ["[dim]O prompt que o ACE-Step recebe:[/dim]", faixa["prompt"], ""]
        c = self.candidatas(slot)
        if c:
            linhas.append("[b]As candidatas[/b]")
            for n, ficha in c:
                marca = "[red]escorrega[/red]" if ficha.get("escorrega") else "[green]no tempo[/green]"
                primeiro = ficha.get("primeiro_tempo_s")
                linhas.append("  %s · %s · semente %s%s" % (
                    n, marca, ficha.get("semente"),
                    (" · primeiro tempo %.3f s" % primeiro) if primeiro is not None else ""))
            linhas.append("")
            linhas.append("[dim]Ouvir (O) toca a primeira; Escolher (E) põe a 1 no jogo.[/dim]")
        self.query_one("#ficha", Static).update("\n".join(linhas))

    def registrar(self, msg: str) -> None:
        self.query_one("#registro", Log).write_line(msg)

    def atualizar_placa(self) -> None:
        m = dt.memoria_da_placa()
        carregado = "texto no ar" if dt.no_ar() else "texto descarregado"
        acestep = "ACE-Step no ar" if self._acestep_no_ar() else "ACE-Step parado"
        texto = "Esforço: %s   ·   %s   ·   %s" % (self.rotulo_do_esforco(), carregado, acestep)
        if m:
            texto += "   ·   placa: %d MiB em uso, %d MiB livres" % m
        self.query_one("#placa", Static).update(texto)

    @staticmethod
    def _acestep_no_ar():
        try:
            import urllib.request
            urllib.request.urlopen(gt.URL_PADRAO + "/docs", timeout=1).read(1)
            return True
        except Exception:
            return False

    # ---------------------------------------------------------------- os botões --

    @on(DataTable.RowHighlighted)
    def _mudou_a_linha(self) -> None:
        self.mostrar_ficha()

    @on(Button.Pressed, "#b_descrever")
    def _b_descrever(self) -> None:
        self.action_descrever()

    @on(Button.Pressed, "#b_gerar")
    def _b_gerar(self) -> None:
        self.action_gerar()

    @on(Button.Pressed, "#b_esforco")
    def _b_esforco(self) -> None:
        self.action_mais_esforco()

    @on(Button.Pressed, "#b_refazer")
    def _b_refazer(self) -> None:
        self.action_refazer()

    @on(Button.Pressed, "#b_escolher")
    def _b_escolher(self) -> None:
        self.action_escolher()

    @on(Button.Pressed, "#b_ouvir")
    def _b_ouvir(self) -> None:
        self.action_ouvir()

    @on(Button.Pressed, "#b_soltar")
    def _b_soltar(self) -> None:
        self.action_soltar()

    def action_mais_esforco(self) -> None:
        self.esforco = (self.esforco + 1) % len(ESFORCOS)
        self.registrar("Esforço agora: %s" % self.rotulo_do_esforco())
        self.atualizar_placa()

    def action_soltar(self) -> None:
        self.soltar_tudo()

    def action_descrever(self) -> None:
        self.tarefa_descrever(self.slot, False)

    def action_refazer(self) -> None:
        self.tarefa_descrever(self.slot, True)

    def action_gerar(self) -> None:
        self.tarefa_gerar(self.slot)

    def action_tudo(self) -> None:
        self.tarefa_descrever("tudo", False)

    def action_escolher(self) -> None:
        slot = self.slot
        c = self.candidatas(slot)
        if not c:
            self.registrar("%s: não há candidata para escolher. Gere primeiro (G)." % slot)
            return
        boa = next((n for n, f in c if not f.get("escorrega")), c[0][0])
        try:
            alvo = gt.escolher(slot, boa, self.trabalho, forcar=True, aviso=self.registrar)
        except SystemExit as e:
            self.registrar("%s: %s" % (slot, e))
            return
        self.registrar("%s: a candidata %s virou %s" % (slot, boa, alvo))
        self.recarregar()

    def action_ouvir(self) -> None:
        slot = self.slot
        c = self.candidatas(slot)
        alvo = (self.trabalho / slot / (c[0][0] + ".wav")) if c else gt.destino(slot)
        if not Path(alvo).is_file():
            self.registrar("%s: não há o que ouvir ainda." % slot)
            return
        tocador = shutil.which("ffplay") or shutil.which("mpv") or shutil.which("xdg-open")
        if not tocador:
            self.registrar("Sem tocador: instale ffmpeg (ffplay) ou mpv.")
            return
        cmd = [tocador, "-autoexit", "-nodisp", str(alvo)] if tocador.endswith("ffplay") else [tocador, str(alvo)]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.registrar("Tocando %s (feche o tocador quando quiser)." % alvo)

    def action_sair(self) -> None:
        self.soltar_tudo()
        self.exit()

    # ---------------------------------------------------------------- o trabalho --

    def soltar_tudo(self) -> None:
        dt.soltar_a_placa()
        if self.ollama is not None:
            self.ollama.terminate()
            try:
                self.ollama.wait(timeout=20)
            except subprocess.TimeoutExpired:
                self.ollama.kill()
            self.ollama = None
        m = dt.memoria_da_placa()
        self.registrar("Placa devolvida: %d MiB em uso, %d MiB livres." % m if m
                       else "Modelos descarregados.")
        self.atualizar_placa()

    def ocupar(self, sim: bool) -> None:
        self.ocupada = sim
        for b in self.query(Button):
            b.disabled = sim

    @work(thread=True, exclusive=True)
    def tarefa_descrever(self, alvo: str, refazer: bool) -> None:
        if not alvo:
            return
        self.call_from_thread(self.ocupar, True)
        try:
            self.call_from_thread(self.registrar, "Subindo o modelo de texto…")
            self.ollama = dt.subir_ollama() or self.ollama
            modelo = dt.ModeloOllama()
            esforco = ESFORCOS[self.esforco][3]
            dt.descrever(alvo, modelo, refazer, esforco,
                         aviso=lambda m: self.call_from_thread(self.registrar, m))
        except SystemExit as e:
            self.call_from_thread(self.registrar, "Parou: %s" % e)
        finally:
            self.call_from_thread(self.ocupar, False)
            self.call_from_thread(self.recarregar)
            self.call_from_thread(self.atualizar_placa)

    @work(thread=True, exclusive=True)
    def tarefa_gerar(self, alvo: str) -> None:
        if not alvo:
            return
        self.call_from_thread(self.ocupar, True)
        try:
            # a regra da casa: os dois modelos não cabem juntos na placa
            if dt.no_ar():
                self.call_from_thread(self.registrar, "Descarregando o modelo de texto antes de gerar som…")
                self.soltar_na_thread()
            if not self._acestep_no_ar():
                self.call_from_thread(
                    self.registrar,
                    "O ACE-Step não está no ar. Suba noutro terminal: scripts/ace_step.sh servir")
                return
            _, n, passos, _ = ESFORCOS[self.esforco]
            motor = gt.MotorAceStep()
            motor.passos = passos
            faixas = {k: v for k, v in self.faixas.items()}
            sufixo = json.loads(dt.PROMPTS.read_text(encoding="utf-8"))["sufixo"]
            self.call_from_thread(self.registrar, "Gerando %s com %d candidatas…" % (alvo, n))
            gt.gerar(alvo, n, motor, self.trabalho, faixas, sufixo,
                     aviso=lambda m: self.call_from_thread(self.registrar, m))
            self.call_from_thread(self.registrar, "Pronto: %s" % alvo)
        except SystemExit as e:
            self.call_from_thread(self.registrar, "Parou: %s" % e)
        except Exception as e:  # a tela nunca morre por causa de uma faixa
            self.call_from_thread(self.registrar, "Deu erro em %s: %s" % (alvo, e))
        finally:
            self.call_from_thread(self.ocupar, False)
            self.call_from_thread(self.recarregar)
            self.call_from_thread(self.atualizar_placa)

    def soltar_na_thread(self) -> None:
        dt.soltar_a_placa()
        if self.ollama is not None:
            self.ollama.terminate()
            try:
                self.ollama.wait(timeout=20)
            except subprocess.TimeoutExpired:
                self.ollama.kill()
            self.ollama = None


def main():
    if os.environ.get("FORJA_TRILHA_PROVA"):
        # a prova sem terminal: a tela monta, lista os 55 e sai
        app = Bancada()

        async def correr():
            async with app.run_test() as p:
                await p.pause()
                t = app.query_one("#lista", DataTable)
                assert t.row_count == 55, "a lista tem de ter os 55 slots (tem %d)" % t.row_count
                assert app.slot.startswith("MUS_"), "o cursor começa num slot"
                app.query_one("#ficha", Static)
                app.action_mais_esforco()
                print("ok   a tela monta, lista os 55 slots e troca o esforço")

        import asyncio
        asyncio.run(correr())
        return
    Bancada().run()


if __name__ == "__main__":
    main()
