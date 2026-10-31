#!/usr/bin/env bash
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-prova-do-devlog-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0
CASOS=0

espera() {
  local quer="$1" oque="$2"; shift 2
  CASOS=$((CASOS + 1))
  "$@" > "$TMP/saida.log" 2>&1
  local rc=$?
  if [ "$rc" -eq "$quer" ]; then
    echo "ok   $oque"
  else
    echo "FAIL $oque (saiu $rc, esperava $quer)"
    sed 's/^/     | /' "$TMP/saida.log" | tail -n 8
    FALHAS=$((FALHAS + 1))
  fi
}

confere() {
  local oque="$1"; shift
  CASOS=$((CASOS + 1))
  if "$@"; then
    echo "ok   $oque"
  else
    echo "FAIL $oque"
    FALHAS=$((FALHAS + 1))
  fi
}

echo "==> vez.sh"
export XDG_RUNTIME_DIR="$TMP/run"
mkdir -p "$XDG_RUNTIME_DIR"
export VEZ_SONDA=0.1
vez_serial() {
  : > "$TMP/ordem"
  local i
  for i in 1 2 3; do
    VEZ_N=1 bash "$RAIZ/scripts/vez.sh" bash -c "echo ini$i >> '$TMP/ordem'; sleep 0.4; echo fim$i >> '$TMP/ordem'" &
  done
  wait
  awk '/^ini/ { if (aberto) exit 1; aberto = 1 } /^fim/ { aberto = 0 } END { exit NR != 6 }' "$TMP/ordem"
}
confere "vez: com uma vaga, os comandos não se sobrepõem" vez_serial
vez_paralelo() {
  local t0 t1
  t0="$(date +%s%N)"
  for i in 1 2 3; do VEZ_N=3 bash "$RAIZ/scripts/vez.sh" sleep 0.6 & done
  wait
  t1="$(date +%s%N)"
  [ $(((t1 - t0) / 1000000)) -lt 1500 ]
}
confere "vez: com três vagas, três comandos andam juntos" vez_paralelo
espera 7 "vez: devolve o código do comando" env VEZ_N=2 bash "$RAIZ/scripts/vez.sh" bash -c 'exit 7'
espera 2 "vez: VEZ_N inválido sai 2" env VEZ_N=abc bash "$RAIZ/scripts/vez.sh" true
espera 2 "vez: sem comando sai 2" bash "$RAIZ/scripts/vez.sh"
unset XDG_RUNTIME_DIR VEZ_SONDA

em() { local d="$1"; shift; (cd "$d" && "$@" < /dev/null); }

foto() {
  convert -size "${2:-64x36}" "${3:-xc:red}" -quality 78 "$1"
}

repo_falso() {
  R="$TMP/repo"
  rm -rf "$R"
  mkdir -p "$R/scripts/devlog" "$R/scripts/portoes" "$R/godot/scripts" "$R/godot/testes" "$R/godot/assets/fontes" "$R/docs/jogo/tarefas"
  cp "$RAIZ/devlog.sh" "$R/"
  cp "$RAIZ"/scripts/devlog/{cabecalho.py,entrada.sh,cobrar.sh,jpeg.py,montar.py,pares.sh,ligar_gancho.py,gancho.json} "$R/scripts/devlog/"
  cp "$RAIZ"/scripts/portoes/{devlog.py,comum.py} "$R/scripts/portoes/"
  cp "$RAIZ/godot/scripts/tema.gd" "$R/godot/scripts/"
  cp "$RAIZ"/godot/assets/fontes/*.ttf "$R/godot/assets/fontes/"
  git -C "$R" init -q -b main
  git -C "$R" config user.name prova
  git -C "$R" config user.email prova@forja.invalid
  git -C "$R" config commit.gpgsign false
  git -C "$R" config core.hooksPath /dev/null
  echo "extends Node" > "$R/godot/scripts/a.gd"
  printf '.cache/\n' > "$R/.gitignore"
  git -C "$R" add -A
  git -C "$R" commit -q -m "base"
}
commita() {
  git -C "$R" add -A
  git -C "$R" commit -q -m "$1"
}

echo "==> entrada.sh"
repo_falso
git -C "$R" checkout -q -b voo
export DEVLOG_DATA=2026-10-30
espera 0 "entrada: cria a pasta e imprime o caminho" em "$R" bash scripts/devlog/entrada.sh teste "Um teste"
E="$R/docs/devlog/2026-10-30-teste"
for chave in titulo data ramo base topo fichas; do
  confere "entrada: o cabeçalho tem $chave" grep -q "^$chave:" "$E/entrada.md"
done
confere "entrada: ramo e base certos" bash -c "grep -q '^ramo: voo\$' '$E/entrada.md' && grep -q \"^base: \$(git -C '$R' rev-parse --short=7 main)\$\" '$E/entrada.md'"
espera 1 "entrada: não sobrescreve uma entrada que existe" em "$R" bash scripts/devlog/entrada.sh teste "Outro"
espera 2 "entrada: slug com maiúscula ou espaço sai 2" em "$R" bash scripts/devlog/entrada.sh "Um Teste" "x"
espera 2 "entrada: base que não existe sai 2" em "$R" bash scripts/devlog/entrada.sh outro "x" --base 0000000000000000000000000000000000000000

echo "==> pares.sh e fotos"
mkdir -p "$TMP/png-a" "$TMP/png-d"
foto "$TMP/png-a/igual.png" 1920x1080 gradient:red-blue
cp "$TMP/png-a/igual.png" "$TMP/png-d/igual.png"
foto "$TMP/png-a/muda.png" 1920x1080 gradient:red-blue
convert "$TMP/png-a/muda.png" -fill white -draw 'rectangle 100,100 1200,800' "$TMP/png-d/muda.png"
foto "$TMP/png-d/nova.png" 1920x1080 xc:green
foto "$TMP/png-a/velha.png" 1920x1080 xc:black
espera 0 "pares: monta antes/ e depois/" em "$R" bash scripts/devlog/pares.sh "$TMP/png-a" "$TMP/png-d" "$E"
confere "pares: o par igual sai dos dois lados" test ! -e "$E/antes/igual.jpg" -a ! -e "$E/depois/igual.jpg"
confere "pares: o par diferente fica nos dois lados" test -f "$E/antes/muda.jpg" -a -f "$E/depois/muda.jpg"
confere "pares: a tela só do depois fica só nele" test -f "$E/depois/nova.jpg" -a ! -e "$E/antes/nova.jpg"
confere "pares: a tela só do antes fica só nele" test -f "$E/antes/velha.jpg" -a ! -e "$E/depois/velha.jpg"
confere "pares: JPEG de no máximo 1280 px" bash -c "[ \"\$(identify -format '%w %m' '$E/depois/muda.jpg')\" = '1280 JPEG' ]"
confere "pares: sem metadados" bash -c "! identify -verbose '$E/depois/muda.jpg' | grep -qE 'exif:|Software'"
confere "pares: o cabeçalho guarda so_antes, so_depois e iguais" bash -c "grep -q '^so_antes: velha\$' '$E/entrada.md' && grep -q '^so_depois: nova\$' '$E/entrada.md' && grep -q '^iguais: 1\$' '$E/entrada.md'"
espera 2 "pares: pasta que não é entrada sai 2" em "$R" bash scripts/devlog/pares.sh "$TMP/png-a" "$TMP/png-d" "$TMP"
mkdir -p "$TMP/apertar/antes" "$TMP/apertar/depois"
convert -size 1280x720 plasma:fractal -quality 90 "$TMP/apertar/depois/p.jpg"
espera 0 "pares: --apertar encolhe a entrada acima do teto" env DEVLOG_TETO=60000 bash "$RAIZ/scripts/devlog/pares.sh" --apertar "$TMP/apertar"
confere "pares: --apertar deixou a foto menor que 1280 px" bash -c "[ \"\$(identify -format '%w' '$TMP/apertar/depois/p.jpg')\" -lt 1280 ]"
espera 1 "pares: --apertar sai 1 quando nem encolhendo cabe" env DEVLOG_TETO=100 bash "$RAIZ/scripts/devlog/pares.sh" --apertar "$TMP/apertar"

resumo_bom() {
  printf -- '---\n' > "$TMP/novo.md"
  sed -n '2,/^---$/p' "$E/entrada.md" | sed '$d' >> "$TMP/novo.md"
  printf -- '---\n- **Capa:** o título novo.\n- Segunda linha com `codigo`.\n' >> "$TMP/novo.md"
  cp "$TMP/novo.md" "$E/entrada.md"
}
resumo_bom

echo "==> devlog.sh"
espera 0 "devlog.sh --sem-abrir monta a página" em "$R" bash devlog.sh --sem-abrir
H="$R/.cache/devlog/index.html"
confere "devlog: imprime o caminho do index.html" bash -c "[ \"\$(cd '$R' && bash devlog.sh --sem-abrir)\" = '$H' ]"
confere "devlog: a página tem o título e o resumo da entrada" bash -c "grep -q 'Um teste' '$H' && grep -q 'o título novo' '$H'"
confere "devlog: três quadros de foto (um par e duas telas de um lado só)" bash -c "[ \"\$(grep -o 'class=\"par\"' '$H' | wc -l)\" = 3 ]"
confere "devlog: o par igual não aparece" bash -c "! grep -q 'igual' '$H'"
confere "devlog: as fotos e as fontes foram copiadas" test -f "$R/.cache/devlog/fotos/2026-10-30-teste/depois/muda.jpg" -a -f "$R/.cache/devlog/fontes/Bungee-Regular.ttf"
confere "devlog: as cores vêm do tema.gd" bash -c "grep -q '$(grep -o 'const FITA := Color("#[0-9a-f]*")' "$RAIZ/godot/scripts/tema.gd" | grep -o '#[0-9a-f]*')' '$H'"
confere "devlog: sem rede (nenhum http na página)" bash -c "! grep -qE 'https?://' '$H'"
espera 0 "devlog.sh --entrada monta só aquela" em "$R" bash devlog.sh --sem-abrir --entrada docs/devlog/2026-10-30-teste
espera 2 "devlog.sh --entrada de pasta sem entrada.md sai 2" em "$R" bash devlog.sh --sem-abrir --entrada docs
espera 2 "devlog.sh recusa argumento desconhecido" em "$R" bash devlog.sh --nada

echo "==> o portão do devlog"
espera 0 "portão: a entrada inteira passa" python3 "$RAIZ/scripts/portoes/devlog.py" --raiz "$R"
portao_com() {
  local oque="$1" mexer="$2"
  rm -rf "$TMP/pt"
  mkdir -p "$TMP/pt/docs"
  cp -r "$R/docs/devlog" "$TMP/pt/docs/devlog"
  PTE="$TMP/pt/docs/devlog/2026-10-30-teste"
  eval "$mexer"
  espera 1 "portão: reprova $oque" python3 "$RAIZ/scripts/portoes/devlog.py" --raiz "$TMP/pt"
}
portao_com "foto PNG" 'cp "$TMP/png-a/velha.png" "$PTE/antes/velha.png"'
portao_com "foto de um JPEG largo" 'foto "$PTE/depois/muda.jpg" 1600x900 xc:blue'
portao_com "foto que não é JPEG com nome de JPEG" 'cp "$TMP/png-a/velha.png" "$PTE/antes/velha.jpg"'
portao_com "resumo de nove linhas" 'for i in 1 2 3 4 5 6 7 8 9; do echo "- linha $i" >> "$PTE/entrada.md"; done'
portao_com "o A ESCREVER que ficou" 'echo "A ESCREVER: o que mudou, em até 8 linhas." >> "$PTE/entrada.md"'
portao_com "par sem irmão" 'rm "$PTE/depois/muda.jpg"'
portao_com "cabeçalho sem a base" 'sed -i "/^base:/d" "$PTE/entrada.md"'
portao_com "entrada acima de 6 MB" 'for i in 1 2 3; do convert -size 1280x720 xc: +noise Random -quality 100 "$PTE/antes/ruido$i.jpg"; cp "$PTE/antes/ruido$i.jpg" "$PTE/depois/ruido$i.jpg"; done'
portao_com "PNG solto na pasta" 'cp "$TMP/png-a/velha.png" "$PTE/solta.png"'

echo "==> o cobrador"
repo_falso
git -C "$R" checkout -q -b voo
espera 0 "cobrar: ramo sem mudança visual sai 0" em "$R" bash scripts/devlog/cobrar.sh
echo "extends Node" > "$R/godot/testes/t.gd"; commita "teste"
espera 0 "cobrar: mudança só em godot/testes sai 0" em "$R" bash scripts/devlog/cobrar.sh
echo "extends Control" > "$R/godot/scripts/b.gd"; commita "visual"
espera 2 "cobrar: mudança visual sem entrada sai 2" em "$R" bash scripts/devlog/cobrar.sh
em "$R" bash scripts/devlog/cobrar.sh > /dev/null 2> "$TMP/cobrou.txt"
confere "cobrar: diz os dois comandos que faltam, um por linha" bash -c "grep -c 'scripts/devlog/' '$TMP/cobrou.txt' | grep -qx 2 && grep -q 'entrada.sh' '$TMP/cobrou.txt' && grep -q 'fotos.sh' '$TMP/cobrou.txt'"
confere "cobrar: o JSON com stop_hook_active sai 0" bash -c "cd '$R' && printf '%s' '{\"stop_hook_active\": true}' | bash scripts/devlog/cobrar.sh"
confere "cobrar: o JSON sem stop_hook_active ainda cobra" bash -c "cd '$R' && printf '%s' '{\"stop_hook_active\": false}' | bash scripts/devlog/cobrar.sh 2> /dev/null; [ \$? -eq 2 ]"
espera 0 "cobrar: fora de um repositório sai 0" em "$TMP" bash "$R/scripts/devlog/cobrar.sh"
git -C "$R" checkout -q main
git -C "$R" merge -q --ff-only voo
espera 0 "cobrar: no main sai 0" em "$R" bash scripts/devlog/cobrar.sh
git -C "$R" checkout -q -b voo2 main
echo "extends Panel" > "$R/godot/scripts/d.gd"; commita "visual de novo"
espera 2 "cobrar: o ramo de novo com mudança visual sai 2" em "$R" bash scripts/devlog/cobrar.sh
em "$R" bash scripts/devlog/entrada.sh quase "Quase" > /dev/null
espera 2 "cobrar: entrada sem foto do depois sai 2" em "$R" bash scripts/devlog/cobrar.sh
em "$R" bash scripts/devlog/cobrar.sh > /dev/null 2> "$TMP/cobrou.txt"
confere "cobrar: sem foto, só falta o fotos.sh" bash -c "grep -c 'scripts/devlog/' '$TMP/cobrou.txt' | grep -qx 1 && grep -q 'fotos.sh docs/devlog/2026-10-30-quase' '$TMP/cobrou.txt'"
mkdir -p "$R/docs/devlog/2026-10-30-quase/depois"
foto "$R/docs/devlog/2026-10-30-quase/depois/a.jpg"
espera 0 "cobrar: entrada com topo no HEAD e foto do depois sai 0" em "$R" bash scripts/devlog/cobrar.sh
commita "a entrada"
espera 0 "cobrar: commit só de documento depois do topo sai 0" em "$R" bash scripts/devlog/cobrar.sh
echo "extends Panel" > "$R/godot/scripts/c.gd"; commita "mais visual"
espera 2 "cobrar: commit visual depois do topo volta a cobrar" em "$R" bash scripts/devlog/cobrar.sh
git -C "$R" reset -q --hard HEAD~1
echo "extends Label" >> "$R/godot/scripts/b.gd"
espera 2 "cobrar: mudança visual sem commit cobra" em "$R" bash scripts/devlog/cobrar.sh

echo "==> o gancho do agente"
gancho_ok() {
  python3 - "$1" <<'FIM'
import json, sys
d = json.load(open(sys.argv[1]))
assert set(d["hooks"]) >= {"Stop", "SubagentStop"}
for ev in ("Stop", "SubagentStop"):
    cmd = d["hooks"][ev][0]["hooks"][0]
    assert cmd["type"] == "command" and "scripts/devlog/cobrar.sh" in cmd["command"]
FIM
}
confere "gancho: o modelo é um JSON com Stop e SubagentStop" gancho_ok "$RAIZ/scripts/devlog/gancho.json"
espera 1 "gancho: desligado numa árvore nova" python3 "$RAIZ/scripts/devlog/ligar_gancho.py" --raiz "$R" --conferir
printf '{"model": "x", "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo meu"}]}]}}\n' > "$TMP/antes.json"
AG="$(python3 -c 'print(bytes.fromhex("636c61756465").decode())')"
mkdir -p "$R/.$AG"
cp "$TMP/antes.json" "$R/.$AG/settings.json"
espera 0 "gancho: liga sem apagar o que já havia" python3 "$RAIZ/scripts/devlog/ligar_gancho.py" --raiz "$R"
espera 0 "gancho: conferir diz ligado" python3 "$RAIZ/scripts/devlog/ligar_gancho.py" --raiz "$R" --conferir
python3 "$RAIZ/scripts/devlog/ligar_gancho.py" --raiz "$R" > /dev/null
confere "gancho: ligar duas vezes não duplica, e o resto fica" python3 - "$R/.$AG/settings.json" <<'FIM'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["model"] == "x"
cmds = [g["command"] for b in d["hooks"]["Stop"] for g in b["hooks"]]
assert cmds.count("echo meu") == 1 and sum("cobrar.sh" in c for c in cmds) == 1, cmds
assert sum("cobrar.sh" in g["command"] for b in d["hooks"]["SubagentStop"] for g in b["hooks"]) == 1
FIM
confere "gancho: a pasta do agente fica fora do git" bash -c "[ -z \"\$(git -C '$R' status --short | grep -i '$AG')\" ]"
CMD="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['hooks']['Stop'][-1]['hooks'][0]['command'])" "$R/.$AG/settings.json")"
confere "gancho: o comando do arquivo cobra no ramo com mudança visual (sai 2)" bash -c "cd '$R' && printf '{}' | bash -c \"\$1\" 2> /dev/null; [ \$? -eq 2 ]" _ "$CMD"
confere "gancho: o comando com stop_hook_active sai 0" bash -c "cd '$R' && printf '{\"stop_hook_active\": true}' | bash -c \"\$1\"" _ "$CMD"
confere "gancho: o comando fora de um repositório sai 0" bash -c "cd '$TMP' && printf '{}' | bash -c \"\$1\"" _ "$CMD"
unset DEVLOG_DATA

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova do devlog ok — $CASOS casos"
  exit 0
fi
echo "prova do devlog: $FALHAS de $CASOS casos falharam"
exit 1
