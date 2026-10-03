#!/usr/bin/env bash
# Baixa a engine para tools/, e só isso (o run-local.sh abre o jogo; este não).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/engine.sh"
forja_baixar_engine
"$FORJA_GODOT" --version
