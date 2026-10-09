#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
python3 "$RAIZ/scripts/check_texto_de_tela.py" || exit 1
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-do-jogo; TMP="$CAIXA_PASTA"
caixa_montar "$TMP"

cat > "$TMP/forma-a" <<'SINKS'
Sink #40
	Name: alsa_output.pci-0000_0a_00.1.hdmi-stereo
	Description: HDA NVidia Digital Stereo (HDMI)
	Sample Specification: s32le 2ch 48000Hz
Sink #593
	Name: no_do_radio_000001
	Description: Alto-falante do Controle 1 (DualSense Wireless Controller)
	Sample Specification: s16le 2ch 48000Hz
SINKS
sed 's/ (DualSense Wireless Controller)$//' "$TMP/forma-a" > "$TMP/antes"

python3 "$RAIZ/scripts/conferir_ost.py" > "$TMP/ost.log" 2>&1
OST=$?
grep -E "^NÃO|^==>" "$TMP/ost.log"

python3 "$RAIZ/scripts/conferir_bonecos.py" > "$TMP/bonecos.log" && python3 "$RAIZ/scripts/conferir_bonecos.py" --teste >> "$TMP/bonecos.log" || { cat "$TMP/bonecos.log"; echo "FAIL os bonecos"; exit 1; }

caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

FALHAS=0
SALA="${SALA:-}"
FICHA_ARG=()
[ -n "$SALA" ] && FICHA_ARG=("--ficha=$SALA")
[ "$OST" -eq 0 ] || { echo "FAIL a trilha não confere (python3 scripts/conferir_ost.py)"; FALHAS=$((FALHAS + 1)); }
if git -C "$RAIZ" rev-parse --git-dir > /dev/null 2>&1; then
  bash "$RAIZ/tests/prova_sem_rastro.sh" > "$TMP/sem-rastro.log" 2>&1
  SEM_RASTRO=$?
  grep -E "^FAIL|^     |prova sem rastro ok" "$TMP/sem-rastro.log"
  [ "$SEM_RASTRO" -eq 0 ] || { echo "FAIL a prova sem rastro (bash tests/prova_sem_rastro.sh)"; FALHAS=$((FALHAS + 1)); }
else
  echo "sem git aqui: a prova sem rastro foi pulada (ela lê o que o git versiona)"
fi
rodar() {
  local nome=$1 esperado=$2
  shift 2
  local rel="$TMP/relatorios-$nome"
  mkdir -p "$rel"
  SERVIDOR_DE_MENTIRA="$TMP/$nome" ESPERADO="$esperado" \
    timeout 1200 "${CAIXA[@]}" "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn \
    -- --simular=4 --robo --semente=7 --relatorios="$rel" ${FICHA_ARG[@]+"${FICHA_ARG[@]}"} "$@" > "$TMP/$nome.log" 2>&1
  local rc=$?
  grep -E "alto-falante do sistema|FAIL|SCRIPT ERROR|prova do jogo ok" "$TMP/$nome.log"
  [ "$rc" -eq 0 ] || { echo "FAIL a prova com o servidor «$nome» (rc=$rc)"; FALHAS=$((FALHAS + 1)); }
  caixa_julgar "$TMP/$nome.log" || FALHAS=$((FALHAS + 1))
}
rodar forma-a "alto-falante: Alto-falante do Controle 1 (DualSense Wireless Controller)" --acelerado
rodar antes "nenhum alto-falante de controle na lista (2 dispositivos)" --bancada --acelerado
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova do jogo ok — os quatro lugares, as salas${SALA:+ e o minigame $SALA} e o relatório; com o nome da Sony o jogo acha o alto-falante, sem ele diz que não achou"
