#!/usr/bin/env bash
set -uo pipefail
uso() {
  cat <<'FIM'
Tira as fotos do antes e do depois de uma entrada do devlog, pelo próprio jogo, numa tela de mentira.

Uso: scripts/devlog/fotos.sh <pasta-da-entrada> [--roteiros a,b,c]
  Lê base e topo do entrada.md, monta as duas árvores em .cache/devlog/arvores/<sha>, garante o módulo nativo e
  o import de cada uma, fotografa as duas com os mesmos roteiros, a mesma semente (7) e a mesma resolução do
  tests/telas.sh, e guarda antes/ e depois/ (scripts/devlog/pares.sh).
  --roteiros   telas, extras, cavaleiro, partida, salas (centelha, viga, molde) ou uma sala:
               centelha, viga, molde, impacto, galeria, canto, caminhos, voz, prova.
               Padrão: os que tocam os arquivos mudados entre base e topo; sem palpite, todos.
Todo Godot pesado passa pelo scripts/vez.sh (VEZ_N vagas). Nunca abre janela na tela.
Cada roteiro tenta até 3 vezes, com FOTOS_TEMPO segundos cada (padrão 1500). As fotos de cada roteiro ficam em
.cache/devlog/png/<sha>/<roteiro> e a nova chamada as reaproveita. O roteiro que falha num lado fica fora dos dois
(sai 1 e pede a nova chamada); o que não existe numa árvore fica só no outro lado; o que estoura o tempo duas vezes
sem passar do mesmo ponto fica com as fotos que tirou.
FIM
}
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
TODOS=(telas extras cavaleiro partida centelha viga molde impacto galeria canto caminhos voz prova)
ENTRADA=""
PEDIDOS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --ajuda) uso; exit 0 ;;
    --roteiros) PEDIDOS="${2:?falta o valor de --roteiros}"; shift ;;
    -*) echo "fotos: argumento desconhecido: $1" >&2; exit 2 ;;
    *) [ -z "$ENTRADA" ] || { uso >&2; exit 2; }; ENTRADA="$1" ;;
  esac
  shift
done
[ -n "$ENTRADA" ] || { uso >&2; exit 2; }
ENTRADA="$(realpath -m "$ENTRADA")"
[ -f "$ENTRADA/entrada.md" ] || { echo "fotos: $ENTRADA não tem entrada.md" >&2; exit 2; }
cd "$RAIZ" || exit 2

cab() { python3 "$AQUI/cabecalho.py" ler "$ENTRADA/entrada.md" "$1"; }
resolver() { git rev-parse --verify "$1^{commit}" 2> /dev/null; }
BASE="$(resolver "$(cab base)")" || { echo "fotos: a base «$(cab base)» não existe neste repositório" >&2; exit 2; }
TOPO="$(resolver "$(cab topo)")" || { echo "fotos: o topo «$(cab topo)» não existe neste repositório" >&2; exit 2; }

palpite() {
  local f mudou=0 achou
  declare -A quer=()
  while IFS= read -r f; do
    case "$f" in godot/testes/* | *.import | *.uid) continue ;; godot/*) ;; *) continue ;; esac
    mudou=1
    case "$f" in
      godot/scripts/salas/sala.gd | godot/scripts/salas/sala_jogo.gd) quer[centelha]=1; quer[viga]=1; quer[molde]=1 ;;
      godot/scripts/salas/viga.gd) quer[viga]=1 ;;
      godot/scripts/salas/molde.gd) quer[molde]=1 ;;
      godot/scripts/salas/impacto.gd) quer[impacto]=1 ;;
      godot/scripts/salas/galeria.gd) quer[galeria]=1 ;;
      godot/scripts/salas/canto.gd) quer[canto]=1 ;;
      godot/scripts/salas/caminhos.gd) quer[caminhos]=1 ;;
      godot/scripts/salas/voz.gd) quer[voz]=1 ;;
      godot/scripts/salas/prova.gd) quer[prova]=1 ;;
      godot/scripts/partida.gd) quer[partida]=1 ;;
      godot/scripts/cavaleiro.gd | godot/assets/kenney/*) quer[cavaleiro]=1 ;;
      godot/scripts/mundo/montar.gd | godot/scripts/mundo/pintura.gd | godot/scripts/mundo/kit.gd | godot/scripts/mundo/malha_bigorna.gd)
        quer[cavaleiro]=1; quer[centelha]=1; quer[viga]=1; quer[molde]=1; quer[partida]=1 ;;
      godot/scripts/ui/* | godot/scripts/main.gd | godot/scripts/mundo/*)
        quer[centelha]=1; quer[viga]=1; quer[molde]=1; quer[partida]=1 ;;
    esac
  done < <(git diff --name-only "$BASE" "$TOPO" -- godot)
  [ "$mudou" -eq 1 ] || return 0
  achou=0
  local r
  for r in "${TODOS[@]}"; do
    [ -n "${quer[$r]:-}" ] && { echo "$r"; achou=1; }
  done
  [ "$achou" -eq 1 ] || printf '%s\n' "${TODOS[@]}"
}

ROTEIROS=()
if [ -n "$PEDIDOS" ]; then
  for r in ${PEDIDOS//,/ }; do
    if [ "$r" = salas ]; then ROTEIROS+=(centelha viga molde); continue; fi
    case " ${TODOS[*]} " in *" $r "*) ROTEIROS+=("$r") ;; *) echo "fotos: não conheço o roteiro «$r»" >&2; exit 2 ;; esac
  done
else
  mapfile -t ROTEIROS < <(palpite)
fi
if [ "${#ROTEIROS[@]}" -eq 0 ]; then
  echo "fotos: nenhum arquivo visual mudou entre ${BASE:0:7} e ${TOPO:0:7}; nada a fotografar"
  exit 0
fi
mapfile -t ROTEIROS < <(printf '%s\n' "${ROTEIROS[@]}" | awk '!v[$0]++')
echo "fotos: ${BASE:0:7} -> ${TOPO:0:7}; roteiros: ${ROTEIROS[*]}"

COMUM="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
GODOT="$(bash -c 'source "$1/scripts/engine.sh"; echo "$FORJA_GODOT"' _ "$RAIZ")"
[ -x "$GODOT" ] || GODOT="$COMUM/tools/$(basename "$GODOT")"
[ -x "$GODOT" ] || { echo "fotos: sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>" >&2; exit 2; }
command -v xvfb-run > /dev/null || { echo "fotos: falta o xvfb-run" >&2; exit 2; }
CACHE_BUILD="$RAIZ/.cache"
compgen -G "$CACHE_BUILD/sdl-*-linux/.pronto" > /dev/null || CACHE_BUILD="$COMUM/.cache"

TRABALHO="$RAIZ/.cache/devlog/trabalho/$(basename "$ENTRADA")-$$"
ARVORES="$RAIZ/.cache/devlog/arvores"
mkdir -p "$TRABALHO" "$ARVORES"
VEZ="$RAIZ/scripts/vez.sh"

arvore() {
  local sha="$1" dir="$ARVORES/$1"
  if [ -d "$dir" ] && [ "$(git -C "$dir" rev-parse HEAD 2> /dev/null)" = "$sha" ]; then
    return 0
  fi
  rm -rf "$dir"
  git worktree prune
  git worktree add -q --detach "$dir" "$sha" || return 1
}

modulo() {
  local arv="$1" bin soma w
  bin="$arv/godot/bin/libforja.linux.x86_64.so"
  soma="$(bash "$arv/scripts/compilar.sh" soma)"
  [ -n "$soma" ] || return 1
  if [ -f "$bin" ] && [ "$(cat "$bin.fonte" 2> /dev/null)" = "$soma" ]; then
    return 0
  fi
  mkdir -p "$arv/godot/bin"
  while IFS= read -r w; do
    [ "$w" = "$arv" ] && continue
    if [ -f "$w/godot/bin/libforja.linux.x86_64.so" ] && [ "$(cat "$w/godot/bin/libforja.linux.x86_64.so.fonte" 2> /dev/null)" = "$soma" ]; then
      cp "$w/godot/bin/libforja.linux.x86_64.so" "$bin" && cp "$w/godot/bin/libforja.linux.x86_64.so.fonte" "$bin.fonte"
      echo "módulo de $(basename "$arv"): copiado de $w"
      return 0
    fi
  done < <(git worktree list --porcelain | sed -n 's/^worktree //p')
  echo "módulo de $(basename "$arv"): compilando (scripts/compilar.sh linux)"
  FORJA_CACHE="$CACHE_BUILD" "$VEZ" bash "$arv/scripts/compilar.sh" linux > "$TRABALHO/compilar-$(basename "$arv").log" 2>&1 || {
    tail -n 15 "$TRABALHO/compilar-$(basename "$arv").log" >&2
    return 1
  }
}

importar() {
  local arv="$1"
  [ -f "$arv/godot/.godot/devlog-importado" ] && return 0
  XDG_DATA_HOME="$TRABALHO/dados-import-$(basename "$arv")" "$VEZ" "$GODOT" --headless --path "$arv/godot" --import --quit \
    > "$TRABALHO/import-$(basename "$arv").log" 2>&1
  mkdir -p "$arv/godot/.godot" && : > "$arv/godot/.godot/devlog-importado"
}

preparar() {
  local sha="$1"
  arvore "$sha" && modulo "$ARVORES/$sha" && importar "$ARVORES/$sha"
}

LADOS=("$BASE")
[ "$TOPO" = "$BASE" ] || LADOS+=("$TOPO")
pids=()
for sha in "${LADOS[@]}"; do
  preparar "$sha" > "$TRABALHO/preparo-$sha.log" 2>&1 &
  pids+=($!)
done
falhou=0
for i in "${!pids[@]}"; do
  if ! wait "${pids[$i]}"; then
    echo "fotos: o preparo da árvore ${LADOS[$i]:0:7} falhou:" >&2
    tail -n 15 "$TRABALHO/preparo-${LADOS[$i]}.log" >&2
    falhou=1
  fi
  sed 's/^/  /' "$TRABALHO/preparo-${LADOS[$i]}.log" | grep -E "^  (módulo|fotos)" || true
done
[ "$falhou" -eq 0 ] || { echo "o registro: $TRABALHO" >&2; exit 1; }

variaveis() {
  case "$1" in
    telas) echo "ROTEIRO=telas" ;;
    extras | cavaleiro | partida) echo "ROTEIRO=$1" ;;
    *) echo "ROTEIRO=salas SALAS=$1" ;;
  esac
}
com_robo() {
  case "$1" in partida | centelha | viga | molde | impacto | galeria | canto | caminhos | voz | prova) return 0 ;; esac
  return 1
}

FOTOS="$RAIZ/.cache/devlog/png"
TEMPO="${FOTOS_TEMPO:-1500}"

existe() {
  local captura="$ARVORES/$1/godot/testes/captura_jogo.gd" r="$2"
  [ -f "$captura" ] || return 1
  case "$r" in
    telas) return 0 ;;
    extras | cavaleiro | partida) grep -q "\"$r\":" "$captura" ;;
    *) grep -qE "^[[:space:]]*\"$r\": *\[" "$captura" ;;
  esac
}

roteiro_de() {
  local sha="$1" r="$2" arv="$ARVORES/$1" out="$FOTOS/$1/$2" rel tentativa rc robo n tentou melhor=-1
  if [ -f "$out/feito" ]; then
    echo "  ${sha:0:7} $r: $(ls "$out"/*.png 2> /dev/null | wc -l) foto(s), já tiradas"
    return 0
  fi
  if ! existe "$sha" "$r"; then
    rm -rf "$out"; mkdir -p "$out"; : > "$out/feito"
    echo "  ${sha:0:7} $r: o roteiro não existe nesta árvore"
    return 0
  fi
  robo=""
  com_robo "$r" && robo="--robo"
  rm -rf "$out" "$out".t* "$out.melhor"
  for tentativa in 1 2 3; do
    tentou="$out.t$tentativa"
    rel="$TRABALHO/rel-${sha:0:7}-$r-$tentativa"
    mkdir -p "$tentou" "$rel"
    env SAIDA="$tentou" RAPIDO=1 $(variaveis "$r") XDG_DATA_HOME="$TRABALHO/dados-${sha:0:7}-$r-$tentativa" "$VEZ" \
      timeout "$TEMPO" xvfb-run -a -s "-screen 0 1920x1080x24" \
      caixa "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --fixed-fps 60 --path "$arv/godot" --resolution 1920x1080 \
      res://testes/captura_jogo.tscn -- --simular=4 --semente=7 --relatorios="$rel" $robo > "$TRABALHO/${sha:0:7}-$r-$tentativa.log" 2>&1
    rc=$?
    n="$(find "$tentou" -maxdepth 1 -name '*.png' | wc -l)"
    if [ "$rc" -eq 0 ] && [ "$n" -gt 0 ]; then
      mv "$tentou" "$out" && rm -rf "$out".t* "$out.melhor" && : > "$out/feito"
      echo "  ${sha:0:7} $r: $n foto(s)"
      return 0
    fi
    if [ "$rc" -eq 124 ] && [ "$n" -gt 0 ]; then
      if [ "$n" -le "$melhor" ]; then
        mv "$out.melhor" "$out" && rm -rf "$out".t* && : > "$out/feito"
        echo "  ${sha:0:7} $r: $melhor foto(s), parcial: estourou o tempo duas vezes sem passar do mesmo ponto"
        return 0
      fi
      melhor="$n"
      rm -rf "$out.melhor"
      mv "$tentou" "$out.melhor"
    fi
    echo "  ${sha:0:7} $r: a tentativa $tentativa falhou (rc=$rc, $n foto(s))"
    sleep $((tentativa * 5))
  done
  return 1
}

lado_de() {
  local sha="$1" r
  (
    source "$ARVORES/$sha/tests/caixa.sh"
    caixa_montar "$TRABALHO/caixa-${sha:0:7}"
    for r in "${ROTEIROS[@]}"; do
      roteiro_de "$sha" "$r" &
      sleep 1.5
    done
    wait
  )
}

echo "fotos: fotografando (${#ROTEIROS[@]} roteiro(s) por lado, pelo vez.sh; o que já foi tirado se reaproveita)"
for sha in "${LADOS[@]}"; do
  lado_de "$sha" &
done
wait

FALHOS=()
VALEM=()
for r in "${ROTEIROS[@]}"; do
  ok=1
  for sha in "${LADOS[@]}"; do
    [ -f "$FOTOS/$sha/$r/feito" ] || ok=0
  done
  if [ "$ok" -eq 1 ]; then VALEM+=("$r"); else FALHOS+=("$r"); fi
done

juntar() {
  local destino_a="$TRABALHO/png-antes" destino_d="$TRABALHO/png-depois" r f n
  mkdir -p "$destino_a" "$destino_d"
  for r in "${VALEM[@]}"; do
    for f in "$FOTOS/$BASE/$r"/*.png "$FOTOS/$TOPO/$r"/*.png; do
      [ -f "$f" ] || continue
      n="$(basename "$f")"
      [ -e "$destino_a/$n" ] || [ -e "$destino_d/$n" ] && continue
      [ -f "$FOTOS/$BASE/$r/$n" ] && cp "$FOTOS/$BASE/$r/$n" "$destino_a/"
      [ -f "$FOTOS/$TOPO/$r/$n" ] && cp "$FOTOS/$TOPO/$r/$n" "$destino_d/"
    done
  done
}
juntar
n_a="$(ls "$TRABALHO/png-antes" 2> /dev/null | wc -l)"
n_d="$(ls "$TRABALHO/png-depois" 2> /dev/null | wc -l)"
if [ "${#FALHOS[@]}" -gt 0 ]; then
  echo "fotos: o(s) roteiro(s) ${FALHOS[*]} falhou(aram) num lado e ficou(aram) fora dos dois; rode de novo o mesmo comando (o que já foi tirado se reaproveita)" >&2
  echo "o registro: $TRABALHO" >&2
fi
if [ "$n_d" -eq 0 ]; then
  echo "fotos: nenhuma foto do depois" >&2
  exit 1
fi
echo "fotos: $n_a do antes e $n_d do depois"
bash "$AQUI/pares.sh" "$TRABALHO/png-antes" "$TRABALHO/png-depois" "$ENTRADA" || exit 1
[ "${#FALHOS[@]}" -eq 0 ] || exit 1
rm -rf "$TRABALHO"
du -sh "$ENTRADA" | sed 's/^/peso: /'
