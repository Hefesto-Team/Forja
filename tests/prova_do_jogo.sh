#!/usr/bin/env bash
# A prova do jogo, sem janela: o Godot --headless abre a cena inteira com
# quatro DualSense simulados (o módulo nativo, com o SDL3 dentro, roda todo) e
# confere o que cada controle simulado recebeu — player index, luz, lâmpadas,
# gatilhos, motores, LED do mudo — sala por sala, e o relatório gravado.
#
# O jogo roda na caixa (tests/caixa.sh): num /dev novo, sem hidraw nem input,
# com o servidor de som de mentira e o sysfs vazio. Com o nome que a Sony dá ao
# alto-falante na lista de som (o SERVIDOR_DE_MENTIRA de cada rodada), o jogo
# acha o alto-falante; sem ele, diz que não achou (a mordida). Sem o bwrap, a
# prova não roda (sai 2), a não ser no CI.
#
# Precisa do módulo compilado (scripts/compilar.sh linux).
# Uso: bash tests/prova_do_jogo.sh        (GODOT=<binário> para outro Godot)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT="$FORJA_GODOT"
[ -x "$GODOT" ] || { echo "sem Godot: rode ./run-local.sh uma vez, ou GODOT=<binário>"; exit 2; }
python3 "$RAIZ/scripts/check_texto_de_tela.py" || exit 1   # o portão do texto de tela (F07)
source "$RAIZ/tests/caixa.sh"
caixa_pasta prova-do-jogo; TMP="$CAIXA_PASTA"   # no vermelho, a pasta fica em .cache/provas/ (WQ04)
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

# a trilha (H05): antes do --import, que criaria o .ogg.import que faltou no commit
python3 "$RAIZ/scripts/conferir_ost.py" > "$TMP/ost.log" 2>&1
OST=$?
grep -E "^NÃO|^==>" "$TMP/ost.log"

caixa "$GODOT" --headless --path "$RAIZ/godot" --import --quit > "$TMP/import.log" 2>&1

FALHAS=0
[ "$OST" -eq 0 ] || { echo "FAIL a trilha não confere (python3 scripts/conferir_ost.py)"; FALHAS=$((FALHAS + 1)); }
# o que se publica é escrito por pessoas, sem trailer nem termo interno (tests/prova_sem_rastro.sh)
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
    timeout 1200 caixa "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn \
    -- --simular=4 --robo --semente=7 --relatorios="$rel" "$@" > "$TMP/$nome.log" 2>&1
  local rc=$?
  grep -E "alto-falante do sistema|FAIL|SCRIPT ERROR|prova do jogo ok" "$TMP/$nome.log"
  [ "$rc" -eq 0 ] || { echo "FAIL a prova com o servidor «$nome» (rc=$rc)"; FALHAS=$((FALHAS + 1)); }
  # o erro do motor que não está em tests/erros_esperados.txt reprova (WQ01)
  caixa_julgar "$TMP/$nome.log" || FALHAS=$((FALHAS + 1))
}
# a rodada «forma-a» é o jogo (sem o Modo bancada); a «antes» é a camada de validação (--bancada)
# --acelerado nas duas (a WE02): as duas jogam o kit, e na sessão acelerada o relógio do ritmo e o t da linha do
# tempo são o tempo do jogo, que a máquina carregada não estica (a prova do relógio desliga isso enquanto mede)
rodar forma-a "alto-falante: Alto-falante do Controle 1 (DualSense Wireless Controller)" --acelerado
rodar antes "nenhum alto-falante de controle na lista (2 dispositivos)" --bancada --acelerado
[ "$FALHAS" -eq 0 ] || exit 1
echo "prova do jogo ok — os quatro lugares, as salas e o relatório; com o nome da Sony o jogo acha o alto-falante, sem ele diz que não achou"
