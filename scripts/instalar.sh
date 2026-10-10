#!/usr/bin/env bash
# O ambiente da Forja, numa máquina nova (Debian, Ubuntu ou Pop!_OS).
#
#   scripts/instalar.sh conferir   diz o que falta e não instala nada
#   scripts/instalar.sh sistema    os pacotes de scripts/requisitos-sistema.txt e a regra do udev (pede senha)
#   scripts/instalar.sh modulo     compila o módulo nativo e baixa a engine
#   scripts/instalar.sh trilha     o gerador de música (placa de vídeo; uns 20 GB)
#   scripts/instalar.sh tudo       os três, nesta ordem
#   scripts/instalar.sh desinstalar  tira o que a Forja trouxe (pede senha)
#
# Nada aqui conhece a máquina de ninguém: tudo sai da raiz do repositório e do
# $HOME de quem roda. A senha, quando é pedida, é a do próprio sudo e não fica
# gravada em lugar nenhum.
#
# Quem só quer jogar e mexer no jogo precisa de «sistema» e «modulo». A
# «trilha» só interessa a quem vai gerar música, e pede placa de vídeo.
#
# A regra do udev (udev/70-forja-dualsense.rules) dá o hidraw do DualSense a quem
# está sentado na máquina: sem ela, gatilho, barra de luz, luzinhas e o report
# cru não chegam ao controle. Com DESTDIR, ela vai para $DESTDIR/etc/udev/rules.d
# sem sudo e sem recarregar o udev (é como as provas a instalam numa raiz falsa).
# FORJA_SYSFS e FORJA_DEV trocam o /sys e o /dev que o conferir lê.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LISTA="$RAIZ/scripts/requisitos-sistema.txt"
OFICINA="${FORJA_OFICINA:-$RAIZ/oficina}"
# Os pacotes que a Forja instalou nesta máquina, um por linha. O que já estava
# aqui antes não entra, e por isso o desinstalar nunca tira o que era seu.
REGISTRO="$OFICINA/pacotes-do-sistema.txt"
# Os arquivos que a Forja pôs fora do repositório (a regra do udev), um por linha.
REGISTRO_ARQUIVOS="$OFICINA/arquivos-do-sistema.txt"
REGRA_UDEV="$RAIZ/udev/70-forja-dualsense.rules"
DESTDIR="${DESTDIR:-}"
PASTA_UDEV="$DESTDIR/etc/udev/rules.d"
SYSFS="${FORJA_SYSFS:-/sys}"
DEV="${FORJA_DEV:-/dev}"

if [[ -t 1 ]]; then
  N=$'\e[0m'; B=$'\e[1m'; VERDE=$'\e[38;5;114m'; AMARELO=$'\e[38;5;222m'; CINZA=$'\e[38;5;245m'
else
  N=""; B=""; VERDE=""; AMARELO=""; CINZA=""
fi
ok()    { printf '  %sok%s    %s\n' "$VERDE" "$N" "$*"; }
falta() { printf '  %sfalta%s %s\n' "$AMARELO" "$N" "$*"; }
titulo(){ printf '\n%s%s%s\n' "$B" "$*" "$N"; }

pacotes_da_lista() {
  grep -vE '^\s*(#|$)' "$LISTA" | awk '{print $1}'
}

pacotes_que_faltam() {
  local faltam=()
  while read -r p; do
    [[ -z "$p" ]] && continue
    dpkg -s "$p" >/dev/null 2>&1 || faltam+=("$p")
  done < <(pacotes_da_lista)
  printf '%s\n' "${faltam[@]}"
}

tem_apt() { command -v apt-get >/dev/null 2>&1; }

placa() {
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader | head -1
  elif [[ -d /sys/class/drm/card0 ]] && command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -qi "amd/ati"; then
    echo "AMD (sem CUDA)"
  else
    echo ""
  fi
}

# ---------------------------------------------------------------- conferir --

conferir() {
  titulo "O sistema"
  if ! tem_apt; then
    falta "esta máquina não usa apt; instale à mão o que está em scripts/requisitos-sistema.txt"
  else
    local faltam; faltam="$(pacotes_que_faltam | grep -v '^$' || true)"
    if [[ -z "$faltam" ]]; then
      ok "os $(pacotes_da_lista | wc -l) pacotes estão instalados"
    else
      falta "$(echo "$faltam" | wc -l) pacote(s): $(echo "$faltam" | tr '\n' ' ')"
      echo "        scripts/instalar.sh sistema"
    fi
  fi

  titulo "O controle"
  conferir_regra_udev

  titulo "O jogo"
  if [[ -f "$RAIZ/godot/bin/libforja.linux.x86_64.so" ]]; then
    ok "o módulo nativo está compilado"
  else
    falta "o módulo nativo (scripts/instalar.sh modulo)"
  fi
  local engine; engine="$(ls "$RAIZ"/tools/Godot_v*_linux.x86_64 2>/dev/null | tail -1)"
  if [[ -x "$engine" ]]; then
    ok "a engine: $("$engine" --version 2>/dev/null | tail -1)"
  else
    falta "a engine em tools/ (scripts/instalar.sh modulo)"
  fi

  titulo "A trilha (só para quem gera música)"
  local p; p="$(placa)"
  if [[ -z "$p" ]]; then
    falta "nenhuma placa de vídeo com CUDA; a geração roda só na CPU, e é lenta"
  else
    ok "placa: $p"
    local livre; livre="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)"
    if [[ -n "$livre" && "$livre" -lt 7000 ]]; then
      falta "menos de 7 GB de memória de vídeo: o modelo de música não cabe inteiro"
    fi
  fi
  [[ -d "$RAIZ/oficina/ace-step" ]] && ok "o gerador de música" || falta "o gerador de música (scripts/instalar.sh trilha)"
  [[ -x "$RAIZ/oficina/ollama/bin/ollama" ]] || command -v ollama >/dev/null 2>&1 \
    && ok "o modelo de texto" || falta "o modelo de texto (scripts/instalar.sh trilha)"
  [[ -x "$RAIZ/oficina/trilha-venv/bin/python" ]] && ok "a tela da bancada" || falta "a tela da bancada (scripts/instalar.sh trilha)"

  titulo "Como abrir"
  echo "  ./run.sh"
}

# O DualSense (054C:0CE6) e o Edge (054C:0DF2) ligados agora, como «hidrawN», um por linha.
hidraw_dos_dualsense() {
  local ev
  for ev in "$SYSFS"/class/hidraw/hidraw*/device/uevent; do
    [[ -f "$ev" ]] || continue
    grep -qiE '^HID_ID=[0-9a-f]+:0000054C:00000(CE6|DF2)$' "$ev" && basename "$(dirname "$(dirname "$ev")")"
  done
}

# Testa a permissão com -r e -w, sem abrir o nó.
conferir_regra_udev() {
  local n no sem=() com=()
  while read -r n; do
    [[ -z "$n" ]] && continue
    no="$DEV/$n"
    [[ -e "$no" ]] || continue
    if [[ -r "$no" && -w "$no" ]]; then com+=("$n"); else sem+=("$n"); fi
  done < <(hidraw_dos_dualsense)
  if (( ${#sem[@]} )); then
    falta "a regra do udev (os efeitos do controle): ${#sem[@]} DualSense sem gatilho, luz e luzinhas"
    echo "        scripts/instalar.sh sistema, e religue o controle"
  elif (( ${#com[@]} )); then
    ok "${#com[@]} DualSense com os efeitos (gatilho, luz e luzinhas)"
  elif [[ -f "$PASTA_UDEV/$(basename "$REGRA_UDEV")" ]]; then
    ok "a regra do udev está instalada (nenhum DualSense ligado agora)"
  else
    falta "a regra do udev (os efeitos do controle); com um DualSense ligado, o conferir mede"
    echo "        scripts/instalar.sh sistema"
  fi
}

# Como raiz: com DESTDIR, direto (a raiz falsa é de quem roda); sem ele, pelo sudo.
como_raiz() {
  if [[ -n "$DESTDIR" ]]; then "$@"; else sudo "$@"; fi
}

regra_udev_instalar() {
  local alvo; alvo="$PASTA_UDEV/$(basename "$REGRA_UDEV")"
  if [[ -f "$alvo" ]] && cmp -s "$REGRA_UDEV" "$alvo"; then
    ok "a regra do udev já está em $alvo"
  else
    echo "Vou pôr a regra do udev do DualSense em $PASTA_UDEV."
    [[ -n "$DESTDIR" ]] || echo "${CINZA}O sudo vai pedir a sua senha. Ela não fica gravada em lugar nenhum.${N}"
    como_raiz mkdir -p "$PASTA_UDEV" && como_raiz install -m 0644 "$REGRA_UDEV" "$alvo" || return 1
    ok "a regra do udev: $alvo"
  fi
  # a regra de antes (99-, com 0666 e o grupo plugdev) sai: ela abria o controle para toda conta
  if [[ -f "$PASTA_UDEV/99-forja-dualsense.rules" ]]; then
    como_raiz rm -f "$PASTA_UDEV/99-forja-dualsense.rules" && ok "a regra antiga (99-forja-dualsense.rules) saiu"
  fi
  mkdir -p "$OFICINA"
  { echo "$alvo"; cat "$REGISTRO_ARQUIVOS" 2>/dev/null; } | sort -u >"$REGISTRO_ARQUIVOS.novo"
  mv "$REGISTRO_ARQUIVOS.novo" "$REGISTRO_ARQUIVOS"
  if [[ -z "$DESTDIR" ]]; then
    sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=hidraw
    echo "  religue o controle (ou o cabo) para a regra valer nele"
  fi
}

# ---------------------------------------------------------------- instalar --

sistema() {
  local rc=0
  sistema_pacotes || rc=1
  regra_udev_instalar || rc=1
  return $rc
}

sistema_pacotes() {
  tem_apt || { echo "esta máquina não usa apt. Instale à mão o que está em $LISTA"; return 1; }
  local faltam; faltam="$(pacotes_que_faltam | grep -v '^$' || true)"
  if [[ -z "$faltam" ]]; then
    ok "nada a instalar: os pacotes já estão aqui"
    return 0
  fi
  echo "Vou instalar $(echo "$faltam" | wc -l) pacote(s) com o apt:"
  echo "$faltam" | sed 's/^/  /'
  echo
  echo "${CINZA}O sudo vai pedir a sua senha. Ela não fica gravada em lugar nenhum.${N}"
  # shellcheck disable=SC2086
  sudo apt-get update -qq && sudo apt-get install -y $(echo "$faltam" | tr '\n' ' ')
  mkdir -p "$OFICINA"
  local p
  while read -r p; do
    dpkg -s "$p" >/dev/null 2>&1 && echo "$p"
  done <<<"$faltam" | cat - "$REGISTRO" 2>/dev/null | sort -u >"$REGISTRO.novo"
  mv "$REGISTRO.novo" "$REGISTRO"
  local resto; resto="$(pacotes_que_faltam | grep -v '^$' || true)"
  [[ -z "$resto" ]] && ok "o sistema está pronto" || falta "ainda faltam: $resto"
}

modulo() {
  echo "==> compilando o módulo nativo (a primeira vez baixa o SDL3 e a godot-cpp)"
  bash "$RAIZ/scripts/compilar.sh" linux || return 1
  echo "==> a engine"
  # quem baixa a engine é o run-local.sh; aqui só a parte que não abre o jogo
  bash "$RAIZ/scripts/baixar_engine.sh" || return 1
  ok "o jogo está pronto: ./run.sh"
}

trilha() {
  local p; p="$(placa)"
  if [[ -z "$p" ]]; then
    echo "${AMARELO}Sem placa com CUDA, a geração de música roda na CPU e leva horas por faixa.${N}"
    read -r -p "Instalar mesmo assim? [s/N] " r
    [[ "$r" == "s" || "$r" == "S" ]] || return 0
  fi
  bash "$RAIZ/scripts/trilha_ambiente.sh" instalar || return 1
  bash "$RAIZ/scripts/trilha_ambiente.sh" modelo || return 1
  ok "a trilha está pronta: ./run.sh trilha"
}

# ------------------------------------------------------------- desinstalar --

desinstalar() {
  titulo "A trilha"
  if [[ -d "$OFICINA/ace-step" || -d "$OFICINA/ollama" || -d "$OFICINA/trilha-venv" ]]; then
    bash "$RAIZ/scripts/trilha_ambiente.sh" desinstalar
  else
    ok "nada da trilha nesta máquina"
  fi

  titulo "A regra do udev"
  local arq tirou=0 ficou=()
  if [[ -s "$REGISTRO_ARQUIVOS" ]]; then
    while read -r arq; do
      [[ -n "$arq" && -f "$arq" ]] || continue
      # o que não saiu (o sudo recusado) fica anotado, para o próximo desinstalar
      if como_raiz rm -f "$arq"; then
        ok "tirei $arq"; tirou=1
      else
        falta "não consegui tirar $arq"; ficou+=("$arq")
      fi
    done <"$REGISTRO_ARQUIVOS"
    if (( ${#ficou[@]} )); then printf '%s\n' "${ficou[@]}" >"$REGISTRO_ARQUIVOS"; else rm -f "$REGISTRO_ARQUIVOS"; fi
  fi
  if (( tirou )); then
    [[ -n "$DESTDIR" ]] || sudo udevadm control --reload-rules
  else
    ok "a Forja não pôs regra do udev nesta máquina"
  fi

  titulo "O sistema"
  local meus=""
  [[ -s "$REGISTRO" ]] && meus="$(grep -vE '^\s*(#|$)' "$REGISTRO" | while read -r p; do
    dpkg -s "$p" >/dev/null 2>&1 && echo "$p"; done || true)"
  if [[ -z "$meus" ]]; then
    ok "a Forja não instalou nenhum pacote nesta máquina"
    return 0
  fi
  echo "A Forja instalou $(echo "$meus" | wc -l) pacote(s) nesta máquina:"
  echo "$meus" | sed 's/^/  /'
  echo "${CINZA}O que já estava aqui antes da Forja não está nesta lista e fica.${N}"
  read -r -p "Remover? [s/N] " r
  [[ "$r" == "s" || "$r" == "S" ]] || { echo "deixei como estava"; return 0; }
  # shellcheck disable=SC2086
  sudo apt-get remove -y $(echo "$meus" | tr '\n' ' ') && rm -f "$REGISTRO"
}

case "${1:-conferir}" in
  conferir) conferir ;;
  sistema)  sistema ;;
  modulo)   modulo ;;
  trilha)   trilha ;;
  tudo)     sistema && modulo && trilha && conferir ;;
  desinstalar) desinstalar ;;
  *) sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
