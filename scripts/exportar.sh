#!/usr/bin/env bash
# A exportação do FORJA: o jogo inteiro, pronto para rodar sem o editor.
#
#   scripts/exportar.sh linux     dist/forja-linux-x86_64/    forja.x86_64, forja.pck e o módulo
#   scripts/exportar.sh windows   dist/forja-windows-x86_64/  forja.exe, forja.pck e a DLL
#   scripts/exportar.sh tudo      os dois
#   scripts/exportar.sh appimage  dist/FORJA-x86_64.AppImage (depois do linux)
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

source "$RAIZ/scripts/engine.sh"   # a versão da engine mora lá (ADR-009)
GODOT_VER="$FORJA_GODOT_VER"
GODOT_BIN="$FORJA_GODOT"
MODELOS_URL="${FORJA_GODOT_RELEASE}/Godot_v${GODOT_VER}_export_templates.tpz"
MODELO_LINUX="linux_release.x86_64"
MODELO_LINUX_SHA256="d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63"
MODELO_WINDOWS="windows_release_x86_64.exe"
MODELO_WINDOWS_SHA256="d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562"
# O AppImage: o appimagetool por versão E por sha256; o runtime sai do começo
# dele mesmo (um AppImage é o runtime seguido do squashfs), e fica fixo junto.
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/1.9.0/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="46fdd785094c7f6e545b61afcfb0f3d98d8eab243f644b4b17698c01d06083d1"

CACHE="${FORJA_CACHE:-$RAIZ/.cache}"
# O Godot procura os modelos em $XDG_DATA_HOME/godot/export_templates/<versão>:
# a exportação roda com o XDG_DATA_HOME apontando para o cache.
DADOS="$CACHE/godot-dados"
MODELOS="$DADOS/godot/export_templates/${GODOT_VER/-/.}"
DIST="$RAIZ/dist"

diga() { printf '==> %s\n' "$*"; }

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

Sem a regra do udev que vem junto, o controle chega pelo joystick genérico do
sistema: os botões funcionam, mas os gatilhos, a barra de luz, as luzinhas de
jogador e o report cru não chegam. A regra vale só para quem está sentado na
máquina, no cabo e no rádio, para o DualSense e o DualSense Edge:

  sudo cp 70-forja-dualsense.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules && sudo udevadm trigger

Depois, desligue e religue o controle. Sem a regra, o relatório da sessão diz
a causa na linha «efeitos» de cada controle.

O atalho no menu do sistema: rode ./instalar-atalho.sh nesta pasta. Ele não
pede senha e aponta para esta pasta; se ela mudar de lugar, rode de novo.

Pela Steam (o jogo adicionado à biblioteca, ou no Steam Deck), o Steam Input
vem ligado:

  Propriedades > Controle: desative o Steam Input para este jogo (com ele
  ligado, o jogo recebe um controle Xbox e perde o resto do DualSense).
TEXTO
  else
    cat <<'TEXTO'

Abrindo o forja.exe:

  1. Ligue o DualSense no cabo: sem fio, o jogo recebe só os botões. O som
     no alto-falante do controle, a háptica, os gatilhos, a luz e o
     microfone pedem o cabo.
  2. Feche os programas que remapeiam o DualSense ou o escondem do Windows
     (os que o fazem passar por um controle Xbox): com eles abertos, o jogo
     não vê o controle de verdade.
  3. Com a Steam aberta, ela pode segurar o controle mesmo para um jogo de
     fora dela. Feche a Steam antes de abrir o jogo, ou adicione o forja.exe
     à biblioteca e desative o Steam Input para ele (o passo 3 abaixo).
  4. Na primeira abertura, o Windows avisa que o aplicativo é de um
     fornecedor desconhecido (o forja.exe não é assinado): Mais informações >
     Executar assim mesmo.

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

# Os avisos de licença que vão com o jogo: os do repositório e os do Godot (e
# do que ele embute), tirados do próprio binário.
licencas() {
  cat "$RAIZ/LICENCAS-DE-TERCEIROS.md"
  local tmp
  tmp="$(mktemp)"
  "$GODOT_BIN" --headless -s "$RAIZ/scripts/licencas.gd" -- "$tmp" > /dev/null 2>&1
  printf '\n## Godot, e o que ele embute\n\n'
  cat "$tmp"
  rm -f "$tmp"
}

# A entrada do menu no AppImage (o AppRun acha o jogo). Na pasta solta, quem a
# escreve é o instalar-atalho.sh, com o caminho de onde a pasta está.
desktop() {
  cat <<'TEXTO'
[Desktop Entry]
Type=Application
Name=A Forja
GenericName=Jogo de festa para quatro DualSense
Comment=Quatro DualSense no mesmo sofá
Exec=forja.x86_64
Icon=forja
Terminal=false
Categories=Game;
TEXTO
}

# O instalar-atalho.sh da pasta do Linux: escreve a entrada do menu na pasta de
# quem roda, sem sudo, com o caminho absoluto do jogo e do ícone. Os campos são
# os da desktop(); só o Exec, o Path e o Icon mudam. O Exec segue as aspas da
# especificação das entradas de menu (\ " ` $ escapados, e % dobrado).
instalar_atalho() {
  cat <<'TEXTO'
#!/bin/sh
# O atalho do FORJA no menu do sistema, para esta pasta. Não pede senha: a
# entrada vai para ~/.local/share/applications. Se a pasta mudar de lugar,
# rode de novo.
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
[ -x "$AQUI/forja.x86_64" ] || { echo "não achei o forja.x86_64 ao lado deste script" >&2; exit 1; }
escapa() { printf '%s' "$1" | sed 's/\\/\\\\/g'; }
EXEC="\"$(printf '%s' "$AQUI/forja.x86_64" | sed 's/[\\"`$]/\\&/g; s/%/%%/g' | sed 's/\\/\\\\/g')\""
PASTA="$(escapa "$AQUI")"
ICONE="$(escapa "$AQUI/forja.png")"
DESTINO="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$DESTINO"
cat > "$DESTINO/forja.desktop" <<FIM
TEXTO
  desktop | sed -e 's|^Exec=.*|Exec=$EXEC\nPath=$PASTA|' -e 's|^Icon=.*|Icon=$ICONE|'
  cat <<'TEXTO'
FIM
if command -v update-desktop-database > /dev/null 2>&1; then
  update-desktop-database "$DESTINO" > /dev/null 2>&1 || true
fi
echo "o atalho do FORJA está no menu: $DESTINO/forja.desktop"
TEXTO
}

# O AppImage, a partir da pasta do Linux já exportada.
appimage() {
  local pasta="$DIST/forja-linux-x86_64"
  [[ -x "$pasta/forja.x86_64" ]] || { echo "exporte o linux antes (scripts/exportar.sh linux)" >&2; exit 1; }
  local ferramenta="$CACHE/appimagetool-1.9.0"
  if ! confere "$ferramenta" "$APPIMAGETOOL_SHA256"; then
    diga "baixando o appimagetool 1.9.0"
    curl -fsSL -o "$ferramenta.parcial" "$APPIMAGETOOL_URL"
    mv "$ferramenta.parcial" "$ferramenta"
    confere "$ferramenta" "$APPIMAGETOOL_SHA256" || { echo "sha256 do appimagetool não confere" >&2; rm -f "$ferramenta"; exit 1; }
  fi
  chmod +x "$ferramenta"
  local runtime="$CACHE/appimage-runtime-x86_64"
  head -c "$(APPIMAGE_EXTRACT_AND_RUN=1 "$ferramenta" --appimage-offset)" "$ferramenta" > "$runtime"
  local app="$DIST/FORJA.AppDir"
  rm -rf "$app"
  mkdir -p "$app/usr/bin"
  cp "$pasta/forja.x86_64" "$pasta/forja.pck" "$pasta/libforja.linux.x86_64.so" "$app/usr/bin/"
  cp "$pasta/LEIA-ME.txt" "$pasta/LICENCAS.txt" "$app/"
  cp "$pasta/forja.png" "$app/forja.png"
  cp "$pasta/forja.png" "$app/.DirIcon"
  desktop > "$app/forja.desktop"
  cat > "$app/AppRun" <<'TEXTO'
#!/bin/sh
# O FORJA dentro do AppImage: os relatórios vão para a pasta de dados do
# usuário (ao lado do jogo, aqui dentro, não dá para escrever).
AQUI="$(dirname "$(readlink -f "$0")")"
exec "$AQUI/usr/bin/forja.x86_64" "$@"
TEXTO
  chmod +x "$app/AppRun"
  diga "empacotando dist/FORJA-x86_64.AppImage"
  ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$ferramenta" --runtime-file "$runtime" --no-appstream "$app" \
    "$DIST/FORJA-x86_64.AppImage" > "$DIST/appimage.log" 2>&1 || { cat "$DIST/appimage.log" >&2; exit 1; }
  rm -rf "$app"
  diga "dist/FORJA-x86_64.AppImage"
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
  licencas > "$saida/LICENCAS.txt"
  if [[ "$qual" == linux ]]; then
    cp "$RAIZ/udev/70-forja-dualsense.rules" "$saida/"
    cp "$RAIZ/godot/assets/forja-logo.png" "$saida/forja.png"
    instalar_atalho > "$saida/instalar-atalho.sh"
    chmod +x "$saida/instalar-atalho.sh"
    tar -C "$DIST" -czf "$DIST/$nome.tar.gz" "$nome"
    diga "dist/$nome.tar.gz"
  else
    # o ícone e a versão do FORJA no .exe (o Godot 4.4 pediria o rcedit)
    local versao
    versao="$(sed -n 's/^config\/version="\(.*\)"/\1/p' "$RAIZ/godot/project.godot")"
    python3 "$RAIZ/scripts/icone_do_exe.py" "$saida/$exe" "$RAIZ/scripts/forja.ico" "$versao"
    (cd "$DIST" && rm -f "$nome.zip" && zip -q -r "$nome.zip" "$nome")
    diga "dist/$nome.zip"
  fi
}

ALVO="${1:-tudo}"
case "$ALVO" in
  linux | windows | tudo | appimage) ;;
  *)
    echo "uso: $0 linux|windows|tudo|appimage" >&2
    exit 2
    ;;
esac

if [[ "$ALVO" == appimage ]]; then
  forja_baixar_engine || exit 1   # o download e a soma moram no engine.sh, num lugar só
  appimage
  exit 0
fi
forja_baixar_engine || exit 1
garantir_modelos
mkdir -p "$DIST"
diga "importando os assets"
godot --import > "$DIST/importar.log" 2>&1 || { cat "$DIST/importar.log" >&2; exit 1; }
case "$ALVO" in
  linux) exportar linux ;;
  windows) exportar windows ;;
  tudo) exportar linux && exportar windows ;;
esac
