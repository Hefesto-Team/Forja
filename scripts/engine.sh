#!/usr/bin/env bash
# A versão da engine, num lugar só (ADR-009).
#
# Todo script que precisa do Godot faz:
#   source "$RAIZ/scripts/engine.sh"      # define FORJA_GODOT
#
# Subir de versão é mudar as duas linhas abaixo (a versão e o sha512 do zip
# dela) e rodar as provas: com a soma velha, o download recusa. Antes isto estava
# escrito com todas as letras em dezesseis arquivos, e cada um subia sozinho.

FORJA_GODOT_VER="${FORJA_GODOT_VER:-4.7.2-stable}"
# A soma do zip, do SHA512-SUMS.txt da página da versão. Quem troca a versão por
# variável de ambiente troca a soma junto (FORJA_GODOT_SHA512).
FORJA_GODOT_SHA512="${FORJA_GODOT_SHA512:-9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65}"

_engine_raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORJA_GODOT="${GODOT:-$_engine_raiz/tools/Godot_v${FORJA_GODOT_VER}_linux.x86_64}"
# A página da versão: o zip do editor e o pacote dos modelos de exportação
# (scripts/exportar.sh) saem dela, e o endereço mora só aqui.
FORJA_GODOT_RELEASE="https://github.com/godotengine/godot/releases/download/${FORJA_GODOT_VER}"
FORJA_GODOT_URL="${FORJA_GODOT_RELEASE}/Godot_v${FORJA_GODOT_VER}_linux.x86_64.zip"

## Baixa a engine para tools/ se ela não estiver lá, e só a descompacta se a
## soma do zip bate com FORJA_GODOT_SHA512. Não abre nada.
forja_baixar_engine() {
  [[ -x "$FORJA_GODOT" ]] && return 0
  echo "==> baixando Godot ${FORJA_GODOT_VER} (editor Linux x86_64, ~60 MB)"
  local tmp; tmp="$(mktemp -d)"
  if ! curl -fsSL -o "$tmp/godot.zip" "$FORJA_GODOT_URL"; then
    rm -rf "$tmp"; echo "não deu para baixar a engine de $FORJA_GODOT_URL" >&2; return 1
  fi
  local tem; tem="$(sha512sum "$tmp/godot.zip" | cut -d' ' -f1)"
  if [[ "$tem" != "$FORJA_GODOT_SHA512" ]]; then
    rm -rf "$tmp"
    echo "sha512 da engine não confere: $tem (esperado $FORJA_GODOT_SHA512)" >&2
    return 1
  fi
  mkdir -p "$_engine_raiz/tools"
  unzip -o -q "$tmp/godot.zip" -d "$_engine_raiz/tools" || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
  chmod +x "$FORJA_GODOT"
  [[ -x "$FORJA_GODOT" ]]
}
