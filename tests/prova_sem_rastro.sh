#!/usr/bin/env bash
# A prova sem rastro: nada do que o repositório publica pode denunciar a
# ferramenta ou o modelo que ajudou a escrevê-lo. Lê os arquivos que o git
# versiona (e os novos ainda sem `git add`, que os portões cegos deixariam
# passar) e reprova:
#   - o nome da ferramenta, da empresa dela e dos modelos;
#   - o «Opus» de modelo («Opus» seguido de versão, ou na tabela de modelos);
#     o «Opus» do som, o codec, passa: «o microfone chega como Opus a 48 kHz»;
#   - o campo de modelo das fichas (a coluna, o cabeçalho e o «sugerido»);
#   - o trailer de coautoria;
#   - o arquivo de regras das ferramentas versionado (AGENTS.md e o irmão dele),
#     em qualquer pasta, e a pasta de configuração delas (a lei do repositório
#     é docs/COMO-CONTRIBUIR.md, escrito para gente);
#   - um .gitignore que deixa de trancar esses arquivos.
# Depois da varredura, a prova MORDE a si mesma: monta um repositório de
# mentira com cada defeito e confere que a régua reprova cada um, e que o
# «Opus» do codec passa. Régua que passa com o defeito dentro não mede nada.
#
# Não precisa de Godot nem de módulo compilado, e roda em um segundo.
# Uso: bash tests/prova_sem_rastro.sh            (varre a árvore e morde)
#      bash tests/prova_sem_rastro.sh --so-varrer  (sem as mordidas)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

# As palavras nunca aparecem inteiras neste arquivo (colchete na regra, aspas
# no meio da palavra nas mordidas): a régua não pode reprovar a si mesma.
REGRA_NOMES='[c]laude|[a]nthropic|[s]onnet|[h]aiku'
REGRA_OPUS_VERSAO='[o]pus[ -]?[0-9]'
REGRA_OPUS_DE_MODELO='\|[ ]*[o]pus[ ]*\||\*\*[m]odelo:\*\*[^|·]*[o]pus'
REGRA_FICHA='[m]odelo[ ]sugerido|\*\*[m]odelo:\*\*|\|[ ]*[m]odelo[ ]*\|'
REGRA_TRAILER='[c]o-authored-by'
CL="clau""de"   # o irmão do AGENTS.md, sem escrevê-lo inteiro
REGRA="$REGRA_NOMES|$REGRA_OPUS_VERSAO|$REGRA_OPUS_DE_MODELO|$REGRA_FICHA|$REGRA_TRAILER"

## varrer <raiz> <saida>: escreve em <saida> uma linha por defeito; devolve 0 se limpo.
varrer() {
  local raiz="$1" saida="$2" lista
  : > "$saida"
  lista="$(mktemp)"
  git -C "$raiz" ls-files -z --cached --others --exclude-standard > "$lista"
  [ -s "$lista" ] || { echo "GUARDA: a lista de arquivos de $raiz está vazia" >&2; rm -f "$lista"; return 2; }
  # arquivo de nome vedado, em qualquer pasta
  tr '\0' '\n' < "$lista" | grep -i -E "(^|/)(agents|$CL)\\.md\$|(^|/)\\.$CL(/|\$)" \
    | sed 's/^/arquivo vedado versionado: /' >> "$saida"
  # o conteúdo (só texto: -I), menos as linhas do .gitignore que são a própria tranca
  while IFS= read -r -d '' f; do
    [ -f "$raiz/$f" ] || continue
    if [ "$f" = ".gitignore" ]; then
      grep -I -n -i -E -- "$REGRA" "$raiz/$f" | grep -v -i -E "^[0-9]+:/?(agents\\.md|$CL\\.md|\\.$CL/?)\$"
    else
      grep -I -n -i -E -- "$REGRA" "$raiz/$f"
    fi | sed "s|^|$f:|" >> "$saida"
  done < "$lista"
  rm -f "$lista"
  # a tranca: o .gitignore tem de ignorar os dois arquivos
  for alvo in 'AGENTS\.md' "${CL}\\.md"; do
    grep -q -i -E "^/?${alvo}\$" "$raiz/.gitignore" 2>/dev/null \
      || echo ".gitignore: falta a linha que tranca ${alvo//\\/}" >> "$saida"
  done
  [ ! -s "$saida" ]
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-sem-rastro-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0

if varrer "$RAIZ" "$TMP/real.txt"; then
  echo "ok   a árvore não tem rastro (nomes, modelos, trailer, arquivo da ferramenta)"
else
  echo "FAIL a árvore tem rastro:"
  sed 's/^/     /' "$TMP/real.txt" | head -60
  [ "$(wc -l < "$TMP/real.txt")" -le 60 ] || echo "     … e mais $(( $(wc -l < "$TMP/real.txt") - 60 ))"
  FALHAS=$((FALHAS + 1))
fi

[ "${1:-}" = "--so-varrer" ] && { [ "$FALHAS" -eq 0 ] && exit 0 || exit 1; }

# ---- as mordidas: um repositório de mentira por defeito ----
C1="Cl""aude"; A1="Anthr""opic"; S1="Son""net"; O1="Op""us"; M1="mod""elo"; T1="Co-Auth""ored-By"
LAR="$TMP/lar"
BASE_IGNORE="AGENTS.md"$'\n'"${CL^^}.md"$'\n'"bin/"$'\n'

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
}

mordida "o nome da ferramenta numa ficha"        reprova docs/f.md "# Ficha — uma sessão do $C1 Code faz"
mordida "o nome da empresa"                      reprova docs/f.md "feito pela $A1"
mordida "o nome de um modelo"                    reprova docs/f.md "fichas repetitivas: $S1 primeiro"
mordida "o campo sugerido, na ficha"             reprova docs/f.md "**Sprint:** F · $M1 sugerido: $S1"
mordida "o campo Modelo do cabeçalho (Opus)"     reprova docs/f.md "**Sprint:** F · **Tamanho:** G · **${M1^}:** $O1 · **Estimativa:** US\$ 3"
mordida "a coluna modelo do quadro"              reprova docs/q.md "| ficha | tamanho | $M1 | estimativa |"$'\n'"| --- | --- | --- | --- |"
mordida "a célula de modelo no quadro (Opus)"    reprova docs/q.md "| [F01](F01.md) | O Modo | G | $O1 | 3,5 |"
mordida "o Opus de versão"                       reprova docs/f.md "usar o $O1 5.5 na primeira ficha"
mordida "o trailer de coautoria"                 reprova docs/f.md "$T1: alguém <a@b.c>"
mordida "o trailer, em minúsculas"               reprova docs/f.md "${T1,,}: alguém"
mordida "o AGENTS.md versionado"                 reprova AGENTS.md "regras"
mordida "o irmão do AGENTS.md numa subpasta"     reprova "sub/${CL^^}.md" "regras"
mordida "a pasta de configuração da ferramenta"  reprova ".$CL/settings.json" "{}"
mordida "o Opus do som, a 48 kHz"                passa   docs/som.md "o microfone chega como $O1 a 48 kHz, em quadros de 20 ms"
mordida "o Opus do codec"                        passa   docs/som.md "o codec $O1 do microfone"
mordida "o OpusHead do conferidor de faixas"     passa   scripts/c.py "if corpo[:8] == b\"${O1}Head\":"
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
