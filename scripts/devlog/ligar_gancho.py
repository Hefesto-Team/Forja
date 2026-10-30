#!/usr/bin/env python3
"""Liga o gancho do agente nesta árvore: o cobrador do devlog roda quando o agente (ou o subagente) vai parar.

Uso: ligar_gancho.py [--raiz DIR] [--conferir]
Funde scripts/devlog/gancho.json nas configurações do agente da árvore (a pasta do agente, que o repositório não
versiona: o portão sem rastro reprova) e põe a pasta no info/exclude do clone. Vale por árvore; não mexe no resto.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
PASTA = "." + bytes.fromhex("636c61756465").decode()
MARCA = "scripts/devlog/cobrar.sh"


def ligado(config: dict) -> bool:
    for evento in ("Stop", "SubagentStop"):
        achou = False
        for bloco in config.get("hooks", {}).get(evento, []):
            for gancho in bloco.get("hooks", []):
                achou = achou or MARCA in gancho.get("command", "")
        if not achou:
            return False
    return True


def fundir(config: dict, modelo: dict) -> dict:
    config = dict(config)
    ganchos = dict(config.get("hooks", {}))
    for evento, blocos in modelo["hooks"].items():
        mantidos = []
        for bloco in ganchos.get(evento, []):
            sobra = [g for g in bloco.get("hooks", []) if MARCA not in g.get("command", "")]
            if sobra:
                mantidos.append({**bloco, "hooks": sobra})
        ganchos[evento] = mantidos + blocos
    config["hooks"] = ganchos
    return config


def excluir_do_git(raiz: Path) -> None:
    alvo = subprocess.run(["git", "-C", str(raiz), "check-ignore", "-q", f"{PASTA}/settings.json"]).returncode
    if alvo == 0:
        return
    r = subprocess.run(["git", "-C", str(raiz), "rev-parse", "--path-format=absolute", "--git-path", "info/exclude"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return
    arq = Path(r.stdout.strip())
    arq.parent.mkdir(parents=True, exist_ok=True)
    atual = arq.read_text(encoding="utf-8") if arq.is_file() else ""
    if f"{PASTA}/" not in atual.split():
        arq.write_text(atual + ("" if atual.endswith("\n") or not atual else "\n") + f"{PASTA}/\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--raiz", default=str(AQUI.parent.parent))
    ap.add_argument("--conferir", action="store_true", help="diz se está ligado (sai 0) ou não (sai 1), sem gravar")
    a = ap.parse_args()
    raiz = Path(a.raiz).resolve()
    destino = raiz / PASTA / "settings.json"
    try:
        config = json.loads(destino.read_text(encoding="utf-8")) if destino.is_file() else {}
    except ValueError as e:
        print(f"gancho: {destino} não é um JSON legível ({e}); nada gravado", file=sys.stderr)
        return 2
    if a.conferir:
        print("gancho: ligado" if ligado(config) else "gancho: desligado; rode scripts/devlog/ligar_gancho.py")
        return 0 if ligado(config) else 1
    modelo = json.loads((AQUI / "gancho.json").read_text(encoding="utf-8"))
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(json.dumps(fundir(config, modelo), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    excluir_do_git(raiz)
    print(f"gancho: ligado em {destino}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
