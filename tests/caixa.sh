#!/usr/bin/env bash
# A caixa das provas, num lugar só: toda prova que abre o Godot (ou o jogo
# exportado) passa por aqui. Numa prova o jogo não pode achar o DualSense
# ligado na máquina: se acha, o controle de verdade ganha um lugar, e a prova
# toca o alto-falante, a háptica e os gatilhos dele. O --headless não protege:
# ele cala a TV, não o módulo.
#
# A caixa é:
#   - o bwrap, com um /dev novo e o /run/udev, o /sys/class/input e o
#     /sys/class/hidraw vazios: o jogo não enxerga hidraw nem input;
#   - o pactl e o pw-cat de mentira, na frente do PATH: o jogo não acha o
#     alto-falante do controle de verdade pelo nome (o `pactl list sinks`
#     imprime o arquivo $SERVIDOR_DE_MENTIRA quando ele existe, e nada quando
#     não);
#   - o FORJA_SYSFS numa pasta vazia.
#
# Uso, numa prova (com RAIZ definido):
#   source "$RAIZ/tests/caixa.sh"
#   caixa_montar "$TMP"                  sai 2 sem o bwrap (fora do CI); monta a pasta da caixa em $TMP
#                                        sai 2 também com o módulo de outra fonte (caixa_fonte, a WQ03)
#   caixa "$GODOT" ...                   o comando dentro do bwrap
#   timeout 600 caixa "$GODOT" ...       o `caixa` é um executável no PATH: vale depois do timeout e do xvfb-run
#   CAIXA_LIGAR="/dev/dri ..."           aparelhos que entram na caixa (a placa de vídeo, na prova visual NA_TELA)
#
# Sem o bwrap, só o CI roda direto (a variável CI, que o runner e o ci-local
# definem: lá não há controle nem bwrap). Fora dele a prova não roda, e não
# há variável de escape.
#
# O portão scripts/portoes/caixa.py reprova a chamada do Godot em tests/ e
# scripts/ que abra cena ou jogo fora do `caixa`.

## caixa_montar <pasta>: confere o bwrap, monta o pactl, o pw-cat e o `caixa`
## em <pasta>/bin (na frente do PATH) e o sysfs vazio em <pasta>/sys-vazio.
caixa_montar() {
  local pasta="$1"
  if ! command -v bwrap > /dev/null && [ -z "${CI:-}" ]; then
    echo "sem bwrap: a prova não roda fora da caixa (o controle ligado na máquina ficaria à vista do jogo)" >&2
    exit 2
  fi
  caixa_fonte libforja.linux.x86_64.so   # o módulo que o jogo carrega saiu da fonte de agora (a WQ03)
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

## caixa_julgar <registro>: o erro do motor reprova (a WQ01). Conta as linhas
## que começam por «ERROR:» ou «SCRIPT ERROR:» e não casam com nenhuma
## expressão de tests/erros_esperados.txt, imprime cada uma como «FAIL erro do
## motor: …» com as duas linhas seguintes (o «at:»), e devolve 1 se houver
## alguma. O «WARNING:» não reprova, nem a palavra «erro» que o registro do
## jogo escreve em português.
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

## caixa_pasta <nome>: a pasta temporária da prova (a WQ04), em CAIXA_PASTA, com
## o trap da saída. No verde (a prova sai 0), apaga a pasta. No vermelho, copia
## a pasta para .cache/provas/<nome>-<AAAAMMDD-HHMMSS>/, guarda só as cinco
## mais novas da prova, mostra as últimas 20 linhas do maior registro e, por
## último, «o registro: <caminho>». Uso, logo depois do source:
##   caixa_pasta prova-do-jogo; TMP="$CAIXA_PASTA"
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
  local base="$_CAIXA_RAIZ/.cache/provas"
  local destino="$base/$CAIXA_NOME-$(date +%Y%m%d-%H%M%S)"
  local n=2
  while [ -e "$destino" ]; do destino="${destino%-v*}-v$n"; n=$((n + 1)); done
  mkdir -p "$base" && cp -a "$CAIXA_PASTA" "$destino" && rm -rf "$CAIXA_PASTA"
  # só as cinco mais novas desta prova (o nome leva a data, e a ordem do nome é a do tempo)
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

## caixa_fonte <módulo>: o módulo de godot/bin saiu da fonte de agora? (a WQ03)
## O scripts/compilar.sh grava ao lado de cada módulo o <módulo>.fonte, com a
## soma da fonte de que ele saiu; aqui ela é comparada com a soma da fonte de
## agora (`scripts/compilar.sh soma`, a mesma função). Sem o módulo, sem o
## .fonte ou com a soma diferente, sai 2 e diz o que rodar. Não compila nada,
## e não há variável de escape.
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
