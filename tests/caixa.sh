#!/usr/bin/env bash

caixa_montar() {
  local pasta="$1"
  if ! command -v bwrap > /dev/null && [ -z "${CI:-}" ]; then
    echo "sem bwrap: a prova não roda fora da caixa (o controle ligado na máquina ficaria à vista do jogo)" >&2
    exit 2
  fi
  caixa_fonte libforja.linux.x86_64.so
  mkdir -p "$pasta/bin" "$pasta/sys-vazio"
  cat > "$pasta/bin/pactl" <<'PACTL'
#!/usr/bin/env bash
if [ "$*" = "list sinks" ] && [ -n "${SERVIDOR_DE_MENTIRA:-}" ] && [ -f "$SERVIDOR_DE_MENTIRA" ]; then
  cat "$SERVIDOR_DE_MENTIRA"
fi
exit 0
PACTL
  printf '#!/usr/bin/env bash\ncat > /dev/null\nexit 0\n' > "$pasta/bin/pw-cat"
  cat > "$pasta/bin/caixa" <<'CAIXA'
#!/usr/bin/env bash
# caixa <comando...>: o comando num /dev novo, sem hidraw nem input (tests/caixa.sh)
if command -v bwrap > /dev/null; then
  ligar=()
  for d in ${CAIXA_LIGAR:-}; do
    [ -e "$d" ] && ligar+=(--dev-bind "$d" "$d")
  done
  exec bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input --tmpfs /sys/class/hidraw \
    "${ligar[@]}" "$@"
fi
[ -n "${CI:-}" ] && exec "$@"
echo "sem bwrap: a prova não roda fora da caixa (o controle ligado na máquina ficaria à vista do jogo)" >&2
exit 2
CAIXA
  chmod +x "$pasta/bin/pactl" "$pasta/bin/pw-cat" "$pasta/bin/caixa"
  export PATH="$pasta/bin:$PATH"
  export FORJA_SYSFS="$pasta/sys-vazio"
  [ "$(command -v pactl)" = "$pasta/bin/pactl" ] || { echo "GUARDA: pactl não é o de mentira"; exit 1; }
  [ "$(command -v caixa)" = "$pasta/bin/caixa" ] || { echo "GUARDA: caixa não é a desta prova"; exit 1; }
}

caixa_julgar() {
  local registro="$1"
  local esperados="${CAIXA_ESPERADOS:-$(dirname "${BASH_SOURCE[0]}")/erros_esperados.txt}"
  [ -f "$registro" ] || return 0
  awk -v lista="$esperados" '
    BEGIN {
      while ((getline l < lista) > 0) {
        if (l ~ /^[[:space:]]*(#|$)/) continue
        p[++n] = l
      }
    }
    /^(SCRIPT )?ERROR: / {
      resto = 0
      for (i = 1; i <= n; i++) if ($0 ~ p[i]) next
      linha = $0
      if (linha ~ /^ERROR: /) linha = substr(linha, 8)
      print "FAIL erro do motor: " linha
      ruins++
      resto = 2
      next
    }
    resto > 0 { print "     " $0; resto-- }
    END { exit ruins > 0 }
  ' "$registro"
}

_CAIXA_RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
caixa_pasta() {
  CAIXA_NOME="$1"
  CAIXA_PASTA="$(mktemp -d "/tmp/forja-$1-XXXXXX")"
  trap '_caixa_fim $?' EXIT
}
_caixa_fim() {
  local rc="$1"
  [ -n "${CAIXA_PASTA:-}" ] && [ -d "$CAIXA_PASTA" ] || return 0
  if [ "$rc" -eq 0 ]; then
    rm -rf "$CAIXA_PASTA"
    return 0
  fi
  local x
  for x in ${CAIXA_SEM_GUARDAR:-}; do rm -rf "${CAIXA_PASTA:?}/$x"; done
  local base="$_CAIXA_RAIZ/.cache/provas"
  local destino="$base/$CAIXA_NOME-$(date +%Y%m%d-%H%M%S)"
  local n=2
  while [ -e "$destino" ]; do destino="${destino%-v*}-v$n"; n=$((n + 1)); done
  mkdir -p "$base" && cp -a "$CAIXA_PASTA" "$destino" && rm -rf "$CAIXA_PASTA"
  find "$base" -mindepth 1 -maxdepth 1 -type d -name "$CAIXA_NOME-[0-9]*" -printf '%f\n' | LC_ALL=C sort -r |
    tail -n +6 | while IFS= read -r velha; do rm -rf "${base:?}/$velha"; done
  local maior
  maior="$(find "$destino" -type f -name '*.log' -size +0c -printf '%s %p\n' 2> /dev/null | sort -n | tail -1 | cut -d' ' -f2-)"
  if [ -n "$maior" ]; then
    echo "--- as últimas 20 linhas de ${maior#"$_CAIXA_RAIZ"/}:"
    tail -n 20 "$maior"
  fi
  echo "o registro: $destino"
}

caixa_fonte() {
  local modulo="$1" alvo=linux
  case "$modulo" in *.dll) alvo=windows ;; esac
  local bin="$_CAIXA_RAIZ/godot/bin/$modulo"
  if [ ! -f "$bin" ]; then
    echo "sem o módulo godot/bin/$modulo: scripts/compilar.sh $alvo" >&2
    exit 2
  fi
  local agora gravada=""
  agora="$(bash "$_CAIXA_RAIZ/scripts/compilar.sh" soma)"
  [ -f "$bin.fonte" ] && gravada="$(cat "$bin.fonte")"
  if [ -z "$agora" ] || [ "$gravada" != "$agora" ]; then
    echo "o módulo é de outra fonte: scripts/compilar.sh $alvo" >&2
    exit 2
  fi
}
