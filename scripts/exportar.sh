#!/usr/bin/env bash
# A exportação do FORJA: o jogo inteiro, pronto para rodar sem o editor.
#
#   scripts/exportar.sh linux     dist/forja-linux-x86_64/    forja.x86_64, forja.pck e o módulo
#   scripts/exportar.sh windows   dist/forja-windows-x86_64/  forja.exe, forja.pck e a DLL
#   scripts/exportar.sh tudo      os dois
#
# Cada pasta sai também empacotada ao lado (o .tar.gz do Linux guarda o bit de
# executável; o .zip do Windows é o que se abre no Windows e no Proton).
#
# Precisa do módulo da plataforma em godot/bin/ (scripts/compilar.sh linux ou
# windows; no CI, o artefato do job que compilou). O Godot é o mesmo do
# run-local.sh; GODOT=<binário> usa outro da mesma versão.
#
# Os modelos de exportação do Godot (os executáveis sem o editor) entram por
# versão E por sha256, como o SDL no compilar.sh: só os dois que o FORJA usa,
# tirados por pedaços do pacote oficial (scripts/modelos_de_exportacao.py), e
# guardados em .cache/, sem tocar na pasta de dados do Godot da máquina.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

GODOT_VER="4.4.1-stable"
GODOT_BIN="${GODOT:-$RAIZ/tools/Godot_v${GODOT_VER}_linux.x86_64}"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_linux.x86_64.zip"
MODELOS_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_export_templates.tpz"
MODELO_LINUX="linux_release.x86_64"
MODELO_LINUX_SHA256="820f3fec74869f088dc4509737a5d30a8b54208a75d148ec26da9e0e839d9d9a"
MODELO_WINDOWS="windows_release_x86_64.exe"
MODELO_WINDOWS_SHA256="b493c1d53fb915f7805f360cfe42d1c3126e720dfc234a4b0f2feb99200f9a4b"

CACHE="${FORJA_CACHE:-$RAIZ/.cache}"
# O Godot procura os modelos em $XDG_DATA_HOME/godot/export_templates/<versão>:
# a exportação roda com o XDG_DATA_HOME apontando para o cache.
DADOS="$CACHE/godot-dados"
MODELOS="$DADOS/godot/export_templates/${GODOT_VER/-/.}"
DIST="$RAIZ/dist"

diga() { printf '==> %s\n' "$*"; }

garantir_godot() {
  if [[ -x "$GODOT_BIN" ]]; then
    return
  fi
  diga "baixando Godot ${GODOT_VER} (editor Linux x86_64, ~60 MB)"
  mkdir -p "$RAIZ/tools"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/godot.zip" "$GODOT_URL"
  unzip -o -q "$tmp/godot.zip" -d "$RAIZ/tools"
  chmod +x "$GODOT_BIN"
  rm -rf "$tmp"
}

confere() { # $1 = arquivo, $2 = sha256
  [[ -f "$1" ]] && [[ "$(sha256sum "$1" | cut -d' ' -f1)" == "$2" ]]
}

garantir_modelos() {
  if confere "$MODELOS/$MODELO_LINUX" "$MODELO_LINUX_SHA256" &&
    confere "$MODELOS/$MODELO_WINDOWS" "$MODELO_WINDOWS_SHA256"; then
    return
  fi
  diga "baixando os modelos de exportação do Godot ${GODOT_VER} (só o Linux e o Windows, ~60 MB)"
  python3 "$RAIZ/scripts/modelos_de_exportacao.py" "$MODELOS_URL" "$MODELOS" \
    "$MODELO_LINUX=$MODELO_LINUX_SHA256" "$MODELO_WINDOWS=$MODELO_WINDOWS_SHA256"
  printf '%s\n' "${GODOT_VER/-/.}" > "$MODELOS/version.txt"
}

godot() {
  XDG_DATA_HOME="$DADOS" "$GODOT_BIN" --headless --path "$RAIZ/godot" "$@"
}

leia_me() { # $1 = linux | windows
  local exe="./forja.x86_64"
  [[ "$1" == windows ]] && exe="forja.exe"
  cat <<TEXTO
FORJA, a Hefesto Tech Demo
==========================

Quatro jogadores no mesmo sofá, cada um com um DualSense, num salão de forja
com uma sala por recurso do controle. No fim, o relatório da sessão: o que o
jogo pediu a cada controle e o que chegou.

Os arquivos desta pasta andam juntos: o jogo, o forja.pck e o módulo nativo.

  ${exe}                                   abre o jogo
  ${exe} -- --prova-de-fogo                todas as salas, na ordem, e o livro no fim
  ${exe} -- --semente=7                    o mesmo sorteio, para comparar sessões
  ${exe} -- --simular=4 --robo             sem controle: quatro de mentira, e o robô joga
  ${exe} -- --relatorios=PASTA             os relatórios em outra pasta

Sem controle nenhum, o título oferece jogar no teclado. Os relatórios vão para
relatorios/, ao lado do jogo (ou para a pasta de dados do usuário, quando ali
não dá para escrever).
TEXTO
  if [[ "$1" == linux ]]; then
    cat <<'TEXTO'

Para ler e escrever o hidraw do DualSense no cabo sem root (o report cru do
jack do fone), a regra do udev que vem junto:

  sudo cp 99-forja-dualsense.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules && sudo udevadm trigger
TEXTO
  else
    cat <<'TEXTO'

Pelo Proton, na Steam:

  1. Jogos > Adicionar um jogo não-Steam à minha biblioteca > Procurar, com o
     filtro em todos os arquivos, e escolha o forja.exe.
  2. Propriedades > Compatibilidade > Forçar o uso de uma ferramenta de
     compatibilidade específica do Steam Play, e escolha um Proton.
  3. Propriedades > Controle: desative o Steam Input para este jogo (com ele
     ligado, o jogo recebe um controle Xbox e perde o resto do DualSense).
  4. Os argumentos entram em Propriedades > Geral > Opções de inicialização,
     depois de um "--" (por exemplo: -- --semente=7).
TEXTO
  fi
}

# $1 = linux | windows
exportar() {
  local qual="$1" preset nome exe modulo
  case "$qual" in
    linux) preset="Linux" exe="forja.x86_64" modulo="libforja.linux.x86_64.so" ;;
    windows) preset="Windows" exe="forja.exe" modulo="libforja.windows.x86_64.dll" ;;
  esac
  nome="forja-${qual}-x86_64"
  if [[ ! -f "$RAIZ/godot/bin/$modulo" ]]; then
    echo "falta godot/bin/$modulo: rode scripts/compilar.sh $qual antes" >&2
    exit 1
  fi
  local saida="$DIST/$nome"
  rm -rf "$saida" "$DIST/$nome.tar.gz" "$DIST/$nome.zip"
  mkdir -p "$saida"
  diga "exportando para ${preset} → dist/$nome/"
  godot --export-release "$preset" "$saida/$exe" > "$DIST/$nome.log" 2>&1 || {
    cat "$DIST/$nome.log" >&2
    exit 1
  }
  if grep -E "^(ERROR|SCRIPT ERROR)|completed with warnings" "$DIST/$nome.log" >&2; then
    echo "a exportação para ${preset} reclamou (dist/$nome.log)" >&2
    exit 1
  fi
  for f in "$exe" forja.pck "$modulo"; do
    [[ -s "$saida/$f" ]] || { echo "a exportação para ${preset} não deixou $f" >&2; exit 1; }
  done
  leia_me "$qual" > "$saida/LEIA-ME.txt"
  if [[ "$qual" == linux ]]; then
    cp "$RAIZ/udev/99-forja-dualsense.rules" "$saida/"
    tar -C "$DIST" -czf "$DIST/$nome.tar.gz" "$nome"
    diga "dist/$nome.tar.gz"
  else
    (cd "$DIST" && rm -f "$nome.zip" && zip -q -r "$nome.zip" "$nome")
    diga "dist/$nome.zip"
  fi
}

ALVO="${1:-tudo}"
case "$ALVO" in
  linux | windows | tudo) ;;
  *)
    echo "uso: $0 linux|windows|tudo" >&2
    exit 2
    ;;
esac

garantir_godot
garantir_modelos
mkdir -p "$DIST"
diga "importando os assets"
godot --import > "$DIST/importar.log" 2>&1 || { cat "$DIST/importar.log" >&2; exit 1; }
case "$ALVO" in
  linux) exportar linux ;;
  windows) exportar windows ;;
  tudo) exportar linux && exportar windows ;;
esac
