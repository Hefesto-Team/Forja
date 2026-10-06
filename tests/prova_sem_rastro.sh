#!/usr/bin/env bash
# A prova sem rastro: o que o repositório publica é escrito por pessoas, e só
# elas assinam. Lê os arquivos que o git versiona (e os novos ainda sem
# `git add`, que os portões cegos deixariam passar) e reprova:
#   - um termo interno da casa, no conteúdo ou no nome do arquivo (a lista vem
#     codificada logo abaixo, para não aparecer escrita no repositório);
#   - o campo de modelo das fichas (a coluna, o cabeçalho e o «sugerido»);
#   - o trailer de coautoria;
#   - um AGENTS.md versionado, em qualquer pasta (a lei do repositório é
#     docs/COMO-CONTRIBUIR.md), e um .gitignore que deixa de trancá-lo.
# A saída diz o arquivo e a linha, nunca o termo nem a linha que casou: o log
# do CI é público.
# O «Opus» do som, o codec, passa: «o microfone chega como Opus a 48 kHz».
# Depois da varredura, a prova MORDE a si mesma: monta um repositório de
# mentira com cada defeito e confere que a régua reprova cada um, e que o
# codec passa. Régua que passa com o defeito dentro não mede nada.
#
# Não precisa de Godot nem de módulo compilado, e roda em um segundo.
# Uso: bash tests/prova_sem_rastro.sh            (varre a árvore e morde)
#      bash tests/prova_sem_rastro.sh --so-varrer  (sem as mordidas)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

dec() { printf '%s' "$1" | base64 -d; }
NOMES="$(dec Y2xhdWRlfGFudGhyb3BpY3xzb25uZXR8aGFpa3U=)"
OP="$(dec b3B1cw==)"
CL="${NOMES%%|*}"
if [ -z "$OP" ] || [ -z "$CL" ] || [ "$CL" = "$NOMES" ]; then
  echo "GUARDA: a lista codificada não se leu (falta o base64?)" >&2; exit 2
fi

REGRA_OPUS_VERSAO="${OP}[ -]?[0-9]"
REGRA_OPUS_DE_MODELO="\\|[ ]*${OP}[ ]*\\||\\*\\*[m]odelo:\\*\\*[^|·]*${OP}"
REGRA_FICHA='[m]odelo[ ]sugerido|\*\*[m]odelo:\*\*|\|[ ]*[m]odelo[ ]*\|'
REGRA_TRAILER='[c]o-authored-by'
REGRA="$NOMES|$REGRA_OPUS_VERSAO|$REGRA_OPUS_DE_MODELO|$REGRA_FICHA|$REGRA_TRAILER"

## onde <caminho>: a pasta do arquivo, sem o nome e com o termo tapado.
onde() {
  case "$1" in
    */*) printf 'em %s/\n' "${1%/*}" | sed -E "s/($NOMES)/…/Ig" ;;
    *) echo "na raiz" ;;
  esac
}

## varrer <raiz> <saida>: escreve em <saida> uma linha por defeito; devolve 0 se limpo.
varrer() {
  local raiz="$1" saida="$2" lista f
  : > "$saida"
  lista="$(mktemp)"
  git -C "$raiz" ls-files -z --cached --others --exclude-standard > "$lista"
  [ -s "$lista" ] || { echo "GUARDA: a lista de arquivos de $raiz está vazia" >&2; rm -f "$lista"; return 2; }
  while IFS= read -r -d '' f; do
    # o nome: AGENTS.md (ou o irmão), a pasta de configuração, ou um termo no caminho
    if printf '%s\n' "$f" | grep -q -i -E "(^|/)(agents|$CL)\\.md\$|(^|/)\\.$CL(/|\$)"; then
      echo "arquivo de regras versionado $(onde "$f")" >> "$saida"
    elif printf '%s\n' "$f" | grep -q -i -E -- "$NOMES"; then
      echo "termo interno no nome de um arquivo $(onde "$f")" >> "$saida"
    fi
    # o conteúdo (só texto: -I); a saída leva só o número da linha
    [ -f "$raiz/$f" ] || continue
    grep -I -n -i -E -- "$REGRA" "$raiz/$f" | cut -d: -f1 | sed "s|^|$f:|; s|\$|: termo interno, campo de modelo ou trailer|" >> "$saida"
  done < "$lista"
  rm -f "$lista"
  # a tranca: o .gitignore tem de ignorar o AGENTS.md
  grep -q -i -E '^/?AGENTS\.md$' "$raiz/.gitignore" 2>/dev/null \
    || echo ".gitignore: falta a linha que tranca AGENTS.md" >> "$saida"
  [ ! -s "$saida" ]
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-sem-rastro-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0

if varrer "$RAIZ" "$TMP/real.txt"; then
  echo "ok   a árvore não tem rastro (termos, campo de modelo, trailer, AGENTS.md)"
else
  echo "FAIL a árvore tem rastro:"
  sed 's/^/     /' "$TMP/real.txt" | head -60
  [ "$(wc -l < "$TMP/real.txt")" -le 60 ] || echo "     … e mais $(( $(wc -l < "$TMP/real.txt") - 60 ))"
  FALHAS=$((FALHAS + 1))
fi

[ "${1:-}" = "--so-varrer" ] && { [ "$FALHAS" -eq 0 ] && exit 0 || exit 1; }

# ---- as mordidas: um repositório de mentira por defeito ----
# Os termos daqui são escritos por outro caminho (octal), independente da lista
# codificada lá em cima: se a lista se corromper, as mordidas reprovam.
C1="$(printf '\103\154\141\165\144\145')"; A1="$(printf '\101\156\164\150\162\157\160\151\143')"
S1="$(printf '\123\157\156\156\145\164')"; H1="$(printf '\110\141\151\153\165')"
O1="$(printf '\117\160\165\163')"; M1="mod""elo"; T1="Co-Auth""ored-By"
LAR="$TMP/lar"
BASE_IGNORE="AGENTS.md"$'\n'"bin/"$'\n'

## mordida <nome> <esperado: reprova|passa> <arquivo> <conteúdo>
mordida() {
  local nome="$1" esperado="$2" arquivo="$3" conteudo="$4" ignore="$BASE_IGNORE"
  rm -rf "$LAR"; mkdir -p "$LAR"
  git -C "$LAR" init -q
  printf '%s' "$ignore" > "$LAR/.gitignore"
  mkdir -p "$LAR/$(dirname "$arquivo")"
  printf '%s\n' "$conteudo" > "$LAR/$arquivo"
  git -C "$LAR" add -f -- "$arquivo"   # versionado de verdade, ainda que o .gitignore o tranque
  varrer "$LAR" "$TMP/m.txt" > /dev/null 2>&1
  local rc=$?
  if { [ "$esperado" = reprova ] && [ "$rc" -eq 1 ]; } || { [ "$esperado" = passa ] && [ "$rc" -eq 0 ]; }; then
    echo "ok   morde: $nome ($esperado)"
  else
    echo "FAIL morde: $nome (esperava $esperado, rc=$rc)"; sed 's/^/     /' "$TMP/m.txt"
    FALHAS=$((FALHAS + 1))
  fi
  # a saída nunca leva o termo (o log do CI é público)
  if grep -q -i -E -- "$NOMES|${OP}" "$TMP/m.txt"; then
    echo "FAIL morde: $nome: a saída da régua escreveu o termo"; FALHAS=$((FALHAS + 1))
  fi
}

mordida "o nome da ferramenta numa ficha"        reprova docs/f.md "# Ficha — uma sessão do $C1 Code faz"
mordida "o nome da empresa"                      reprova docs/f.md "feito pela $A1"
mordida "o nome de um modelo"                    reprova docs/f.md "fichas repetitivas: $S1 primeiro"
mordida "o nome do modelo pequeno"               reprova docs/f.md "um $H1 basta"
mordida "o termo no meio de um identificador"    reprova scripts/s.sh "[ -n \"\$${C1^^}_CODE_REMOTE\" ] && exit 0"
mordida "o campo sugerido, na ficha"             reprova docs/f.md "**Sprint:** F · $M1 sugerido: $S1"
mordida "o campo Modelo do cabeçalho"            reprova docs/f.md "**Sprint:** F · **Tamanho:** G · **${M1^}:** $O1 · **Estimativa:** US\$ 3"
mordida "a coluna modelo do quadro"              reprova docs/q.md "| ficha | tamanho | $M1 | estimativa |"$'\n'"| --- | --- | --- | --- |"
mordida "a célula de modelo no quadro"           reprova docs/q.md "| [F01](F01.md) | O Modo | G | $O1 | 3,5 |"
mordida "o $O1 de versão"                        reprova docs/f.md "usar o $O1 5.5 na primeira ficha"
mordida "o trailer de coautoria"                 reprova docs/f.md "$T1: alguém <a@b.c>"
mordida "o trailer, em minúsculas"               reprova docs/f.md "${T1,,}: alguém"
mordida "o AGENTS.md versionado"                 reprova AGENTS.md "regras"
mordida "o irmão do AGENTS.md numa subpasta"     reprova "sub/${C1^^}.md" "regras"
mordida "a pasta de configuração da ferramenta"  reprova ".${C1,,}/settings.json" "{}"
mordida "um termo no nome de um arquivo"         reprova "docs/plano-${S1,,}.md" "o plano"
mordida "o .gitignore que nomeia a ferramenta"   reprova .gitignore "AGENTS.md"$'\n'"${C1^^}.md"
mordida "o $O1 do som, a 48 kHz"                 passa   docs/som.md "o microfone chega como $O1 a 48 kHz, em quadros de 20 ms"
mordida "o $O1 do codec"                         passa   docs/som.md "o codec $O1 do microfone"
mordida "o ${O1}Head do conferidor de faixas"    passa   scripts/c.py "if corpo[:8] == b\"${O1}Head\":"
mordida "modelo 3D, que é outra coisa"           passa   godot/p.gd "var modelo_i := 0  # o modelo do boneco"

# o .gitignore sem a tranca
rm -rf "$LAR"; mkdir -p "$LAR"; git -C "$LAR" init -q
printf 'bin/\n' > "$LAR/.gitignore"; echo ok > "$LAR/a.md"
if varrer "$LAR" "$TMP/m.txt" > /dev/null 2>&1; then
  echo "FAIL morde: o .gitignore sem a tranca passou"; FALHAS=$((FALHAS + 1))
else
  echo "ok   morde: o .gitignore sem a tranca (reprova)"
fi

# o arquivo novo, ainda sem git add, também é lido (o portão cego a arquivo novo não vale aqui)
rm -rf "$LAR"; mkdir -p "$LAR"; git -C "$LAR" init -q
printf '%s' "$BASE_IGNORE" > "$LAR/.gitignore"; echo "fala do $C1" > "$LAR/novo.md"
if varrer "$LAR" "$TMP/m.txt" > /dev/null 2>&1; then
  echo "FAIL morde: o arquivo novo sem git add passou"; FALHAS=$((FALHAS + 1))
else
  echo "ok   morde: o arquivo novo sem git add (reprova)"
fi

if [ "$FALHAS" -eq 0 ]; then
  echo "prova sem rastro ok — a árvore limpa, e a régua reprova cada defeito e deixa passar o codec"
  exit 0
fi
exit 1
