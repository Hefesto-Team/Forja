#!/usr/bin/env bash
# A prova dos portões: cada portão de scripts/portoes/ REPROVA o defeito que diz pegar, e deixa passar o
# caso limpo. Portão que passa com o defeito dentro não mede nada.
#
# Cada caso monta uma árvore de mentira numa pasta temporária, com o defeito, e roda o portão nela com
# `--raiz` (e `--modo reprova`, para a arte e o som, que no repositório estão em aviso). O texto de tela acha
# a raiz pelo próprio caminho: a prova copia o script para a árvore de mentira. A prova sem rastro morde a si
# mesma: aqui ela só é chamada inteira.
#
# Não precisa de Godot nem de módulo, e roda em segundos. Uso: bash tests/prova_dos_portoes.sh
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
P="$RAIZ/scripts/portoes"
TMP="$(mktemp -d /tmp/forja-prova-dos-portoes-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0
CASOS=0

## espera <rc esperado> <o que> <comando...>
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

## arvore <nome>: uma pasta nova para um caso
arvore() { rm -rf "$TMP/$1"; mkdir -p "$TMP/$1"; echo "$TMP/$1"; }

# --- o texto de tela ---------------------------------------------------------------------------------------------
traducoes() { # <pasta> <chave> <valor>
  mkdir -p "$1/scripts" "$1/godot/scripts"
  cp "$RAIZ/scripts/check_texto_de_tela.py" "$1/scripts/"
  printf 'class_name Traducoes\nconst EN := {\n\t"%s": "%s",\n}\nconst EN_PADROES := [\n\t["^Canto (\\\\d+)$", "Song $1"],\n]\n' \
    "$2" "$3" > "$1/godot/scripts/traducoes.gd"
}
A="$(arvore texto-ruim)"; traducoes "$A" "começar" "start"
espera 1 "texto de tela: reprova a frase com minúscula" python3 "$A/scripts/check_texto_de_tela.py"
A="$(arvore texto-bom)"; traducoes "$A" "Começar" "Start"
espera 0 "texto de tela: deixa passar a frase com maiúscula" python3 "$A/scripts/check_texto_de_tela.py"

# --- sem rastro -------------------------------------------------------------------------------------------------
espera 0 "sem rastro: a prova inteira (ela monta cada defeito e confere que reprova)" bash "$RAIZ/tests/prova_sem_rastro.sh"

# --- as mensagens de commit -------------------------------------------------------------------------------------
repo() { # <pasta>: um repositório com main e um ramo
  git -C "$1" init -q -b main
  git -C "$1" config user.name prova; git -C "$1" config user.email prova@forja.invalid
  git -C "$1" config commit.gpgsign false; git -C "$1" config core.hooksPath /dev/null
  echo a > "$1/a"; git -C "$1" add a; git -C "$1" commit -q -m "base"
  git -C "$1" checkout -q -b voo
}
commit() { echo "$RANDOM" >> "$1/a"; git -C "$1" add a; git -C "$1" commit -q -m "$2" ${3:+-m "$3"}; }
A="$(arvore msg-simbolo)"; repo "$A"; commit "$A" "feat: aperte ✕ para entrar"
espera 1 "mensagens: reprova o símbolo de botão" python3 "$P/mensagens_de_commit.py" --raiz "$A" --intervalo main..HEAD
A="$(arvore msg-emoji)"; repo "$A"; commit "$A" "fix: o som volta 🔊"
espera 1 "mensagens: reprova o emoji" python3 "$P/mensagens_de_commit.py" --raiz "$A" --intervalo main..HEAD
A="$(arvore msg-trailer)"; repo "$A"; commit "$A" "docs: a ficha" "$(printf '%s-authored-by: Alguém <a@b.c>' Co)"
espera 1 "mensagens: reprova o trailer de coautoria" python3 "$P/mensagens_de_commit.py" --raiz "$A" --intervalo main..HEAD
A="$(arvore msg-limpa)"; repo "$A"; commit "$A" "fix(texto): o botão Cruz — em português, «com aspas» · e acento"
espera 0 "mensagens: deixa passar o travessão, as aspas e o acento" python3 "$P/mensagens_de_commit.py" --raiz "$A" --intervalo main..HEAD
espera 0 "mensagens: sem intervalo explícito, confere desde o main (só o commit limpo)" \
  env -u ANTES -u BASE_DO_PR python3 "$P/mensagens_de_commit.py" --raiz "$A"
A="$(arvore msg-desde-o-main)"; repo "$A"; commit "$A" "feat: ▶ começar"
espera 1 "mensagens: sem intervalo explícito, o símbolo desde o main reprova" \
  env -u ANTES -u BASE_DO_PR python3 "$P/mensagens_de_commit.py" --raiz "$A"
espera 1 "mensagens: no push, ANTES..HEAD é o intervalo" \
  env -u BASE_DO_PR ANTES="$(git -C "$A" rev-parse main)" python3 "$P/mensagens_de_commit.py" --raiz "$A"
espera 2 "mensagens: um intervalo que não existe não conta como verde" \
  python3 "$P/mensagens_de_commit.py" --raiz "$A" --intervalo nada..HEAD

# --- a ficha pronta ---------------------------------------------------------------------------------------------
ficha_tree() { # <pasta> <estado> <ficha (texto)>
  mkdir -p "$1/docs/jogo/o-time" "$1/docs/jogo/tarefas"
  cp "$RAIZ/docs/jogo/o-time/ficha-pronta.md" "$1/docs/jogo/o-time/"
  printf '# O quadro\n\n| ficha | título | tamanho | depende de | estado |\n| --- | --- | --- | --- | --- |\n| [Z1](Z1.md) | A de prova | P | — | %s |\n' \
    "$2" > "$1/docs/jogo/tarefas/README.md"
  printf '%s\n' "$3" > "$1/docs/jogo/tarefas/Z1.md"
  echo "# o 13" > "$1/docs/jogo/13.md"
}
ficha_inteira() { # [ler antes] [sem a parte]
  local ler="${1:-- [13](../13.md)}" sem="${2:-}" p
  echo "# Z1"
  while IFS= read -r p; do
    [ "$p" = "$sem" ] && continue
    echo; echo "## $p"; echo
    if [ "$p" = "Ler antes" ]; then printf '%s\n' "$ler"; else echo "Não se aplica: a ficha de prova."; fi
  done < <(python3 - "$RAIZ/docs/jogo/o-time/ficha-pronta.md" <<'EOF'
import re, sys
t = open(sys.argv[1], encoding="utf-8").read()
b = t[t.index("## As partes"):]
b = b[:b.find("\n## ", 5)]
print("\n".join(re.findall(r"^\|\s*\*\*([^*]+)\*\*\s*\|", b, re.M)))
EOF
)
}
A="$(arvore ficha-sem-parte)"; ficha_tree "$A" "pronta" "$(ficha_inteira '' 'A diversão')"
espera 1 "ficha pronta: reprova a ficha pronta sem «A diversão»" python3 "$P/ficha_pronta.py" --raiz "$A"
A="$(arvore ficha-parte-vazia)"; ficha_tree "$A" "pronta" "$(ficha_inteira | sed '/^## O som$/{n;n;d}')"
espera 1 "ficha pronta: reprova a parte vazia" python3 "$P/ficha_pronta.py" --raiz "$A"
A="$(arvore ficha-quatro-links)"; ficha_tree "$A" "pronta" "$(ficha_inteira "$(printf -- '- [a](../13.md)\n- [b](../13.md)\n- [c](../13.md)\n- [d](../13.md)')")"
espera 1 "ficha pronta: reprova o «Ler antes» com quatro links" python3 "$P/ficha_pronta.py" --raiz "$A"
A="$(arvore ficha-link-morto)"; ficha_tree "$A" "pronta" "$(ficha_inteira '- [x](../nao-existe.md)')"
espera 1 "ficha pronta: reprova o link que não existe" python3 "$P/ficha_pronta.py" --raiz "$A"
A="$(arvore ficha-boa)"; ficha_tree "$A" "pronta" "$(ficha_inteira)"
espera 0 "ficha pronta: deixa passar a ficha com todas as partes" python3 "$P/ficha_pronta.py" --raiz "$A"
A="$(arvore ficha-a-fazer)"; ficha_tree "$A" "a fazer" "# Z1"
espera 0 "ficha pronta: não confere a ficha que não está pronta" python3 "$P/ficha_pronta.py" --raiz "$A"

# --- a arte -----------------------------------------------------------------------------------------------------
arte_tree() { # <pasta> <linha de gdscript>
  mkdir -p "$1/godot/scripts/ui" "$1/godot/scenes" "$1/godot/assets/fontes"
  printf 'class_name Tema\nconst ETIQUETA := Color("#efe4c8")\nconst JOGADOR := [Color("#29e6ff"), Color("#ff3ea5"), Color("#d4ff4a"), Color("#ee9a1e")]\nconst T_ROTULO := 30\nconst _VOZ := "res://assets/fontes/ArchivoNarrow-wght.ttf"\n' \
    > "$1/godot/scripts/tema.gd"
  printf 'extends Node2D\nfunc _draw() -> void:\n\t%s\n' "$2" > "$1/godot/scripts/ui/tela.gd"
  : > "$1/godot/assets/fontes/ArchivoNarrow-wght.ttf"
  printf '[gd_scene format=3]\n' > "$1/godot/scenes/main.tscn"
  printf 'config_version=5\n' > "$1/godot/project.godot"
}
arte() { python3 "$P/arte.py" --raiz "$1" --modo reprova; }
A="$(arvore arte-hex)"; arte_tree "$A" 'modulate = Color("#123456")'
espera 1 "arte: reprova a cor escrita fora do arquivo de tokens" arte "$A"
A="$(arvore arte-color8)"; arte_tree "$A" 'modulate = Color8(0, 72, 255)'
espera 1 "arte: reprova o Color8" arte "$A"
A="$(arvore arte-tema-fora)"; arte_tree "$A" 'pass'; printf 'const ROXO := Color("#bd93f9")\n' >> "$A/godot/scripts/tema.gd"
espera 1 "arte: reprova o token que a bíblia não tem" arte "$A"
A="$(arvore arte-fonte)"; arte_tree "$A" 'var f := load("res://assets/fontes/SpaceGrotesk-wght.ttf")'
espera 1 "arte: reprova a fonte fora da bíblia" arte "$A"
A="$(arvore arte-fonte-na-pasta)"; arte_tree "$A" 'pass'; : > "$A/godot/assets/fontes/Comic.ttf"
espera 1 "arte: reprova a fonte na pasta que a bíblia não tem" arte "$A"
A="$(arvore arte-pequeno)"; arte_tree "$A" 'Desenho.texto(self, Vector2(10, 10), "Oi", Tema.fonte(600), 24, Tema.ETIQUETA)'
espera 1 "arte: reprova o texto de 24 px" arte "$A"
A="$(arvore arte-pequeno-cena)"; arte_tree "$A" 'pass'; printf 'theme_override_font_sizes/font_size = 20\n' >> "$A/godot/scenes/main.tscn"
espera 1 "arte: reprova o font_size 20 na cena" arte "$A"
A="$(arvore arte-jogador-hex)"; arte_tree "$A" 'var c := "#29e6ff"'
espera 1 "arte: reprova o hex de um jogador fora do arquivo de tokens" arte "$A"
A="$(arvore arte-jogador-indice)"; arte_tree "$A" 'draw_rect(Rect2(0, 0, 9, 9), Tema.JOGADOR[0])'
espera 1 "arte: reprova a cor do P1 pedida por índice fixo" arte "$A"
A="$(arvore arte-boa)"; arte_tree "$A" 'Desenho.texto(self, Vector2(10, 10), "Oi", Tema.fonte(600), 30, Tema.JOGADOR[lugar]) # Color("#123456") no comentário'
espera 0 "arte: deixa passar o token, os 30 px, a cor do dono e o comentário" arte "$A"
espera 0 "arte: no modo aviso, o defeito não reprova" python3 "$P/arte.py" --raiz "$TMP/arte-hex" --modo aviso

# --- o som ------------------------------------------------------------------------------------------------------
wav() { # <arquivo> <ms> <amplitude 0..1> <estala: 0|1>
  python3 - "$@" <<'EOF'
import math, struct, sys, wave
caminho, ms, amp, estala = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), sys.argv[4] == "1"
taxa = 48000
n = int(taxa * ms / 1000)
amostras = []
for i in range(n):
    env = min(1.0, i / 480, (n - 1 - i) / 480)  # 10 ms de rampa nas duas bordas
    if estala:
        env = 1.0
    amostras.append(int(32767 * amp * env * math.sin(2 * math.pi * 440 * i / taxa + (math.pi / 2 if estala else 0))))
with wave.open(caminho, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(taxa)
    w.writeframes(struct.pack("<%dh" % n, *amostras))
EOF
}
som_tree() { # <pasta> <linha de gdscript> [linhas do mapa...]
  local A="$1" linha="$2"; shift 2
  mkdir -p "$A/godot/scripts" "$A/godot/assets/sons" "$A/docs/jogo/audio"
  printf 'extends Node\nfunc _ready() -> void:\n\t%s\n' "$linha" > "$A/godot/scripts/sala.gd"
  { echo "id,tipo,familia,onde_toca,evento,fichas,receita,duracao_ms,pico_dbfs,haptica,arquivo,estado"
    printf '%s\n' "$@"; } > "$A/docs/jogo/audio/mapa.csv"
}
som() { python3 "$P/som.py" --raiz "$1" --modo reprova; }
LINHA_BOA='martelo,efeito,golpe,tv,acerto,I1,,300,-6.0,,res://assets/sons/martelo.wav,gravado'
A="$(arvore som-fora)"; som_tree "$A" 'Som.tocar("trombeta")' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 300 0.5 0
espera 1 "som: reprova o id tocado que o mapa não tem" som "$A"
A="$(arvore som-ternario)"; som_tree "$A" 'Som.no_controle(l, "martelo" if x else "pedra", 0.7)' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 300 0.5 0
espera 1 "som: reprova o lado do ternário que o mapa não tem" som "$A"
A="$(arvore som-caixa)"; som_tree "$A" 'Som.tocar("MARTELO")' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 300 0.5 0
espera 1 "som: reprova a grafia diferente do mapa" som "$A"
A="$(arvore som-sem-mapa)"; som_tree "$A" 'Som.tocar("martelo")'; rm "$A/docs/jogo/audio/mapa.csv"
espera 1 "som: reprova sem o mapa do áudio" som "$A"
A="$(arvore som-sem-arquivo)"; som_tree "$A" 'Som.tocar("martelo")' "$LINHA_BOA"
espera 1 "som: reprova o arquivo do mapa que não existe" som "$A"
A="$(arvore som-duracao)"; som_tree "$A" 'Som.tocar("martelo")' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 500 0.5 0
espera 1 "som: reprova a duração diferente da do mapa" som "$A"
A="$(arvore som-pico)"; som_tree "$A" 'Som.tocar("martelo")' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 300 0.99 0
espera 1 "som: reprova o pico acima do máximo do mapa" som "$A"
A="$(arvore som-clique)"; som_tree "$A" 'Som.tocar("martelo")' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 300 0.5 1
espera 1 "som: reprova o arquivo que estala no começo" som "$A"
A="$(arvore som-bom)"; som_tree "$A" 'Som.tocar("martelo") # Som.tocar("trombeta") no comentário' "$LINHA_BOA"; wav "$A/godot/assets/sons/martelo.wav" 300 0.5 0
espera 0 "som: deixa passar o id do mapa e o arquivo que bate" som "$A"
espera 0 "som: no modo aviso, o defeito não reprova" python3 "$P/som.py" --raiz "$TMP/som-fora" --modo aviso

# --- o teste mudo -----------------------------------------------------------------------------------------------
mudo_tree() { # <pasta> <linhas do script>
  mkdir -p "$1/tests"; printf '%s\n' "$2" > "$1/tests/foto.sh"
}
A="$(arvore mudo-toca)"; mudo_tree "$A" 'xvfb-run -a \
  "$GODOT" --rendering-driver opengl3 --path godot'
espera 1 "teste mudo: reprova o Godot no xvfb-run sem o driver mudo, com a linha continuada" python3 "$P/teste_mudo.py" --raiz "$A"
A="$(arvore mudo-ok)"; mudo_tree "$A" 'xvfb-run -a "$GODOT" --audio-driver Dummy --path godot
xvfb-run -a "$GODOT" --write-movie f.avi --path godot
"$GODOT" --headless --path godot
# xvfb-run "$GODOT" num comentário'
espera 0 "teste mudo: deixa passar o driver mudo, o filme, o headless e o comentário" python3 "$P/teste_mudo.py" --raiz "$A"

# --- a caixa ---------------------------------------------------------------------------------------------------
caixa_tree() { # <pasta> <linhas do script>
  mkdir -p "$1/tests" "$1/scripts"; printf '%s\n' "$2" > "$1/scripts/prova.sh"
}
A="$(arvore caixa-solta)"; caixa_tree "$A" 'timeout 600 "$GODOT" --headless --fixed-fps 60 --path godot \
  res://testes/prova_do_jogo.tscn -- --simular=4 --robo'
espera 1 "caixa: reprova o Godot que abre o jogo fora da caixa, com a linha continuada" python3 "$P/caixa.py" --raiz "$A"
A="$(arvore caixa-opcional)"; caixa_tree "$A" '"${CAIXA[@]}" "$GODOT" --headless --path godot -- --simular=4'
espera 1 "caixa: reprova a caixa opcional (o array que fica vazio sem o bwrap)" python3 "$P/caixa.py" --raiz "$A"
A="$(arvore caixa-ok)"; caixa_tree "$A" 'timeout 600 caixa "$GODOT" --headless --path godot res://testes/prova.tscn -- --robo
xvfb-run -a caixa "$GODOT" --audio-driver Dummy --path godot -- --simular=4
"$GODOT" --headless --path godot --import --quit
"$GODOT" --headless -s scripts/comparar_telas.gd -- a b
godot --export-release "Linux" dist/forja.x86_64
# "$GODOT" --path godot -- --simular=4 num comentário'
espera 0 "caixa: deixa passar a chamada pela caixa, o --import, o -s, o --export e o comentário" python3 "$P/caixa.py" --raiz "$A"

# --- o rodar.sh -------------------------------------------------------------------------------------------------
espera 0 "rodar.sh: os portões do repositório passam (a arte e o som em aviso)" bash "$P/rodar.sh"

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova dos portões ok — $CASOS casos: cada portão reprova o defeito e deixa passar o caso limpo"
  exit 0
fi
echo "prova dos portões: $FALHAS de $CASOS casos falharam"
exit 1
