#!/usr/bin/env bash
# A Prova de Fogo sem aparelho (ADR-003): o robô joga o gauntlet com
# controles simulados, e a linha do tempo diz o veredito de cada feature.
#
#   scripts/gauntlet.sh [binário]
#
# Duas provas:
#   1. o gauntlet limpo: todo veredito dado tem de ser PASSOU;
#   2. a prova da prova: cada defeito de mentira (--defeito) tem de virar
#      FALHOU na feature que ele quebra — se uma sala deixar um defeito passar,
#      ela não serve de régua para o Hefesto.
#
# Roda com o vídeo e o áudio de mentira do SDL e com --acelerado: minutos, não
# a partida em tempo real. "Passou no robô" prova o JOGO; o Hefesto se prova na
# mesa, com o roteiro do README.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${1:-$RAIZ/build/linux/hefesto-tech-demo}"
SEMENTE="${SEMENTE:-7}"
if [[ ! -x "$BIN" ]]; then
  echo "não achei o jogo em $BIN (scripts/compilar.sh linux)" >&2
  exit 2
fi

SAIDA="$(mktemp -d)"
trap 'rm -rf "$SAIDA"' EXIT
export SDL_VIDEO_DRIVER=offscreen SDL_AUDIO_DRIVER=dummy

falhas=0
diga() { printf '%s\n' "$*"; }
erro() {
  printf 'ERRO: %s\n' "$*"
  falhas=$((falhas + 1))
}

# rodar NOME ARGS... → a linha do tempo da sessão em $SAIDA/NOME.jsonl
rodar() {
  local nome="$1"
  shift
  mkdir -p "$SAIDA/$nome"
  if ! timeout 900 "$BIN" --tamanho 960x540 --relatorios "$SAIDA/$nome" --robo --acelerado \
    --semente "$SEMENTE" "$@" >"$SAIDA/$nome/saida.txt" 2>&1; then
    erro "$nome: o jogo saiu com erro"
    tail -5 "$SAIDA/$nome/saida.txt" || true
  fi
  cat "$SAIDA/$nome"/linha-do-tempo-*.jsonl >"$SAIDA/$nome.jsonl" 2>/dev/null || : >"$SAIDA/$nome.jsonl"
}

# vereditos ARQ → "jogador feature resultado", um por linha
vereditos() {
  grep '"tipo": "veredito"' "$1" |
    sed -E 's/.*"jogador": ([0-9]+).*"feature": "([a-z_]+)".*"resultado": "([a-z_]+)".*/\1 \2 \3/'
}

# ---------- 1. o gauntlet limpo ----------
diga "==> gauntlet limpo, quatro controles simulados"
rodar limpo --simular 4 --gauntlet
n=0
while read -r jogador feature resultado; do
  n=$((n + 1))
  [[ "$resultado" == passou ]] || erro "limpo: P$jogador $feature deu $resultado"
done < <(vereditos "$SAIDA/limpo.jsonl")
if ((n == 0)); then
  erro "limpo: nenhum veredito na linha do tempo"
else
  diga "    $n vereditos, todos conferidos"
fi

# ---------- 2. a prova da prova ----------
# defeito:sala:feature que tem de falhar
DEFEITOS=(
  "troca-cruz-circulo:centelha:botoes"
  "analogico-curto:centelha:analogicos"
  "gatilho-digital:centelha:gatilhos_analogicos"
  "giro-invertido:viga:giroscopio"
  "acel-escala:viga:acelerometro"
  "um-dedo:molde:touchpad_dois_dedos"
  "sem-clique:molde:touchpad_clique"
  "motores-trocados:cerco:vibracao_forte"
  "motores-trocados:cerco:vibracao_fraca"
  "vibra-vizinho:cerco:vibracao_isolamento"
  "luz-parada:cerco:lightbar"
  "gatilho-mudo:galeria:gatilho_resistencia"
  "gatilho-mudo:galeria:gatilho_arma"
  "gatilho-mudo:galeria:gatilho_vibracao"
  "leds-errados:galeria:leds_jogador"
  "sem-alto-falante:canto:alto_falante"
  "som-vizinho:canto:alto_falante"
  "haptica-trocada:caminhos:haptica_audio"
  "haptica-muda:caminhos:haptica_audio"
  "mic-surdo:cripta:microfone"
  "mudo-nao-chega:cripta:microfone_mudo"
  "led-mic-parado:cripta:led_microfone"
  "engasga:prova:tudo_junto"
)
for item in "${DEFEITOS[@]}"; do
  IFS=: read -r defeito sala feature <<<"$item"
  diga "==> defeito $defeito na sala $sala ($feature)"
  # o isolamento (da vibração e do som) precisa de vizinho: dois controles; um
  # defeito já rodado não roda de novo
  if [[ ! -s "$SAIDA/$defeito.jsonl" ]]; then
    rodar "$defeito" --simular 2 --sala "$sala" --defeito "$defeito"
  fi
  resultado="$(vereditos "$SAIDA/$defeito.jsonl" | awk -v f="$feature" '$1 == 1 && $2 == f { r = $3 } END { print r }')"
  if [[ "$resultado" == falhou ]]; then
    diga "    $feature: falhou, como devia"
  else
    erro "$defeito: $feature deu '${resultado:-nada}', devia dar falhou"
  fi
done

if ((falhas)); then
  diga "gauntlet: $falhas problema(s)"
  exit 1
fi
diga "gauntlet: tudo conferido"
