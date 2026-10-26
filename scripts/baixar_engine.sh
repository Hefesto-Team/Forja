#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/engine.sh"
forja_baixar_engine
"$FORJA_GODOT" --version
