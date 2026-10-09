#!/usr/bin/env bash
# A prova da esteira: o scripts/esteira.py lê um quadro de mentira e diz o que despachar, o que segura e por quê;
# o scripts/costura.sh costura um ramo limpo, para no conflito (abortado, integração limpa) e para no primeiro
# vermelho. Tudo numa pasta temporária, com repositórios git de mentira: não toca o repositório de verdade.
#
# Não precisa de Godot, e roda em segundos. Uso: bash tests/prova_da_esteira.sh
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d /tmp/forja-prova-da-esteira-XXXXXX)"
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

## confere <o que> <expressão python sobre d, o JSON da esteira em $TMP/esteira.json>
confere() {
  local oque="$1" expr="$2"
  CASOS=$((CASOS + 1))
  if python3 -c "import json,sys; d = json.load(open(sys.argv[1])); sys.exit(0 if ($expr) else 1)" \
      "$TMP/esteira.json" 2> "$TMP/confere.log"; then
    echo "ok   $oque"
  else
    echo "FAIL $oque ($expr)"
    sed 's/^/     | /' "$TMP/confere.log" | tail -n 4
    FALHAS=$((FALHAS + 1))
  fi
}

# --- a esteira ---------------------------------------------------------------------------------------------------
Q="$TMP/quadro"
mkdir -p "$Q/docs/jogo/tarefas" "$Q/docs/jogo/o-time"
ficha() { # <código> <arquivos em crase, separados por espaço; vazio = sem a parte> [texto do resto]
  local f="$Q/docs/jogo/tarefas/$1.md"
  printf '# %s\n\n## Por quê\n\nPorque.\n\n## Ler antes\n\n- `docs/jogo/nao-conta.md`\n' "$1" > "$f"
  if [ -n "$2" ]; then
    printf '\n## Arquivos que mudam\n\n' >> "$f"
    for a in $2; do printf -- '- `%s`\n' "$a" >> "$f"; done
  fi
  [ -n "${3:-}" ] && printf '\n## O estado de hoje\n\n%s\n' "$3" >> "$f"
  return 0
}
cab='| ficha | título | tamanho | depende de | estado |
| --- | --- | --- | --- | --- |'
cat > "$Q/docs/jogo/tarefas/README.md" <<EOF
# O quadro

## F — A fundação

$cab
| [F00](F00.md) | Zero | P | — | feito |
| [F01](F01.md) | Um | M | F00 | a fazer |
| [F02](F02.md) | Dois | M | F01 | a fazer |

## G — As telas

$cab
| [G01](G01.md) | A tela | M | F00 | pronta |
| [G02](G02.md) | A outra | M | G01 | pronta |

## H — O ritmo

$cab
| [H01](H01.md) | O relógio | M | F02 | a fazer |

## I — [S1 — A Centelha: os cinco](I.md)

$cab
| [I1](I1.md) | O martelo | M | F00 | a fazer |

## J — [S2 — A Viga: os cinco](J.md)

$cab
| [J1](J1.md) | A viga | M | F00 | em voo (o-teste) |

## K — [S3 — O Molde: os cinco](K.md)

$cab
| [K1](K1.md) | O molde | M | F00 | pronta |

## L — [S4 — O Impacto: os cinco](L.md)

$cab
| [L1](L1.md) | O impacto | M | F00, as seções I a J prontas | pronta |

## M — [S5 — A Galeria: os cinco](M.md)

$cab
| [M1](M1.md) | A galeria | M | F00 (a nota), S1 a S2 | pronta |

## N — [S6 — O Canto: os cinco](N.md)

$cab
| [N1](N1.md) | O canto | M | F00 | pronta |

## V — A varredura

$cab
| [V01](V01.md) | O portão | M | a bíblia aprovada (o ESPERA-ELA) | a fazer |

## A soma

Nada aqui é ficha.
EOF
cat > "$Q/docs/jogo/o-time/ESPERA-ELA.md" <<'EOF'
# Espera a Vitória

| desde | o que ela decide | o que espera |
| --- | --- | --- |
| 08/10/2026 | aprovar a bíblia | o enriquecimento inteiro |
EOF
ficha F00 ""; ficha F01 "" 'O `godot/scripts/main.gd:12` faz.'; ficha F02 "godot/scripts/forja.gd"
ficha G01 "godot/scripts/telas.gd"; ficha G02 "godot/scripts/ui/"; ficha H01 "godot/scripts/relogio.gd"
ficha I1 "godot/scripts/salas/canto.gd"; ficha J1 "godot/scripts/salas/"; ficha K1 "godot/scripts/salas/molde.gd"
ficha L1 "godot/scripts/salas/impacto.gd"; ficha M1 "godot/scripts/galeria.gd"; ficha N1 "godot/scripts/telas.gd"
ficha V01 "scripts/portoes/arte.json"

espera 0 "esteira: lê o quadro de mentira" bash -c "python3 '$RAIZ/scripts/esteira.py' --raiz '$Q' > '$TMP/esteira.json'"
confere "esteira: despacha a base a fazer e a seção toda pronta, na ordem do quadro" \
  "[p['secao'] for p in d['prontas_para_despachar']] == ['F', 'G']"
confere "esteira: a seção pronta diz se é base (o molde não pede «A diversão» à base)" \
  "[(p['secao'], p['base']) for p in d['prontas_para_despachar']] == [('F', True), ('G', False)]"
confere "esteira: a dependência de dentro da seção não segura (F02 depende de F01)" \
  "next(p for p in d['prontas_para_despachar'] if p['secao'] == 'F')['fichas'] == ['F01', 'F02']"
confere "esteira: sem «Arquivos que mudam», os arquivos são estimados e o «Ler antes» não conta" \
  "(lambda p: p['estimado'] == ['F01'] and p['arquivos'] == ['godot/scripts/main.gd', 'godot/scripts/forja.gd'])(next(p for p in d['prontas_para_despachar'] if p['secao'] == 'F'))"
confere "esteira: a base com dependência de fora não feita fica bloqueada" \
  "any(b['secao'] == 'H' and any('F02 (a fazer)' in m for m in b['motivos']) for b in d['bloqueadas'])"
confere "esteira: a seção que não é base, com ficha a fazer, espera o enriquecimento" \
  "any(b['secao'] == 'I' and any(m.startswith('a enriquecer') for m in b['motivos']) for b in d['bloqueadas'])"
confere "esteira: o conjunto em voo aparece com o nome e os arquivos" \
  "d['em_voo'] == {'o-teste': {'secoes': ['J'], 'fichas': ['J1'], 'arquivos': ['godot/scripts/salas/']}}"
confere "esteira: a seção pronta cujo arquivo cai na pasta de um conjunto em voo fica bloqueada" \
  "any(b['secao'] == 'K' and any('em voo com o-teste' in m and 'molde.gd' in m for m in b['motivos']) for b in d['bloqueadas'])"
confere "esteira: «as seções I a J» viram as fichas das duas seções" \
  "any(b['secao'] == 'L' and any('I1' in m and 'J1' in m for m in b['motivos'] if m.startswith('depend')) for b in d['bloqueadas'])"
confere "esteira: «S1 a S2» se lê pelo título da seção, e o parêntese não conta" \
  "any(b['secao'] == 'M' and any('I1' in m and 'J1' in m for m in b['motivos'] if m.startswith('depend')) for b in d['bloqueadas'])"
confere "esteira: duas seções prontas com o mesmo arquivo: a segunda vai para a fila" \
  "d['na_fila'] == [{'secao': 'N', 'motivo': 'arquivos com a seção G: godot/scripts/telas.gd'}]"
confere "esteira: o ESPERA-ELA segura a ficha que o cita e a seção a enriquecer, não a seção pronta" \
  "(lambda s: 'V' in s and 'I' in s and 'G' not in s and 'K' not in s)(d['espera_ela'][0]['segura'])"
confere "esteira: a seção seguro pelo ESPERA-ELA diz o que ela decide" \
  "any(b['secao'] == 'V' and 'espera a Vitória: aprovar a bíblia' in b['motivos'] for b in d['bloqueadas'])"
confere "esteira: a dependência que não é código vai para conferir à mão" \
  "d['dependencias_em_texto'] == {'V01': 'a bíblia aprovada'}"
espera 0 "esteira: com o limite de 2 e um em voo, só uma seção sai" \
  bash -c "python3 '$RAIZ/scripts/esteira.py' --raiz '$Q' --limite 2 > '$TMP/esteira.json'"
confere "esteira: a que passou do limite fica na fila com o motivo" \
  "[p['secao'] for p in d['prontas_para_despachar']] == ['F'] and {'secao': 'G', 'motivo': 'o limite de 2 conjuntos juntos'} in d['na_fila']"
espera 2 "esteira: sem quadro, não diz nada (rc 2)" python3 "$RAIZ/scripts/esteira.py" --raiz "$TMP/nada"
espera 0 "esteira: o quadro do repositório se lê" \
  bash -c "python3 '$RAIZ/scripts/esteira.py' | python3 -c 'import json, sys; json.load(sys.stdin)'"

# --- a costura ---------------------------------------------------------------------------------------------------
R="$TMP/repo"
git init -q -b main "$R"
mkdir -p "$TMP/sem-ganchos"
git -C "$R" config core.hooksPath "$TMP/sem-ganchos"   # os ganchos globais da máquina não entram na prova
gr() { git -C "$R" -c user.name=prova -c user.email=prova@exemplo.invalid -c commit.gpgsign=false "$@"; }
printf 'um\n' > "$R/a.txt"; printf 'ok\n' > "$R/estado.txt"
printf '#!/usr/bin/env bash\n! grep -q VERMELHO estado.txt && echo "a prova olhou o estado"\n' > "$R/olha.sh"
printf '#!/usr/bin/env bash\necho rodou >> "${MARCA:?}"\n' > "$R/marca.sh"
gr add -A; gr commit -q -m "a base"
gr switch -q -c voo/limpo
printf 'dois\n' > "$R/b.txt"; gr add b.txt; gr commit -q -m "o primeiro"
printf 'tres\n' > "$R/c.txt"; gr add c.txt; gr commit -q -m "o segundo"
gr switch -q main
gr switch -q -c voo/briga
printf 'do ramo\n' > "$R/a.txt"; gr commit -q -am "o ramo muda o a"
gr switch -q main
gr switch -q -c voo/vermelho
printf 'VERMELHO\n' > "$R/estado.txt"; gr commit -q -am "o estado vermelho"
gr switch -q main
gr switch -q -c integra
printf 'da integração\n' > "$R/a.txt"; gr commit -q -am "a integração muda o a"
export GIT_AUTHOR_NAME=prova GIT_AUTHOR_EMAIL=prova@exemplo.invalid GIT_COMMITTER_NAME=prova
export GIT_COMMITTER_EMAIL=prova@exemplo.invalid
C="$RAIZ/scripts/costura.sh"
topo() { git -C "$R" rev-parse HEAD; }

espera 0 "costura: o ramo limpo entra e as provas passam" \
  bash "$C" voo/limpo --integracao "$R" --prova "bash olha.sh" --registro "$TMP/registro.md"
CASOS=$((CASOS + 1))
if [ "$(git -C "$R" log --format=%s -2 | tr '\n' '|')" = "o segundo|o primeiro|" ] && grep -q 'voo/limpo | 2 |' "$TMP/registro.md"; then
  echo "ok   costura: os dois commits na ordem do ramo, e a linha no registro"
else
  echo "FAIL costura: os dois commits na ordem do ramo, e a linha no registro"; FALHAS=$((FALHAS + 1))
fi
espera 0 "costura: rodar de novo não costura duas vezes (o git cherry diz que nada falta)" \
  bash -c "bash '$C' voo/limpo --integracao '$R' --prova 'bash olha.sh' | grep -q 'nada falta'"

ANTES="$(topo)"
espera 3 "costura: o conflito para (rc 3)" bash "$C" voo/briga --integracao "$R" --prova "bash olha.sh"
CASOS=$((CASOS + 1))
if [ "$(topo)" = "$ANTES" ] && [ -z "$(git -C "$R" status --porcelain)" ] && grep -q 'a.txt' "$TMP/saida.log"; then
  echo "ok   costura: no conflito, aborta, a integração volta limpa ao topo de antes e diz o arquivo"
else
  echo "FAIL costura: no conflito, aborta, a integração volta limpa ao topo de antes e diz o arquivo"; FALHAS=$((FALHAS + 1))
fi

export MARCA="$TMP/marca.log"; rm -f "$MARCA"
espera 1 "costura: o portão vermelho reprova (rc 1)" \
  bash "$C" voo/vermelho --integracao "$R" --prova "bash olha.sh" --prova "bash marca.sh"
CASOS=$((CASOS + 1))
if [ ! -e "$MARCA" ] && grep -q 'VERMELHO em «bash olha.sh»' "$TMP/saida.log" && grep -q "reset --keep" "$TMP/saida.log"; then
  echo "ok   costura: para no primeiro vermelho (a prova seguinte não roda) e diz como desfazer"
else
  echo "FAIL costura: para no primeiro vermelho (a prova seguinte não roda) e diz como desfazer"; FALHAS=$((FALHAS + 1))
fi
git -C "$R" reset -q --keep "$ANTES"

printf 'sujo\n' >> "$R/a.txt"
espera 2 "costura: a integração suja não começa (rc 2)" bash "$C" voo/limpo --integracao "$R" --prova "bash olha.sh"
git -C "$R" checkout -q -- a.txt
espera 2 "costura: o ramo que não existe não começa (rc 2)" bash "$C" voo/nada --integracao "$R" --prova "bash olha.sh"
espera 2 "costura: a prova que não existe não começa (rc 2)" bash "$C" voo/limpo --integracao "$R" --prova "bash falta.sh"
gr switch -q voo/limpo
espera 2 "costura: a integração no próprio ramo não começa (rc 2)" bash "$C" voo/limpo --integracao "$R" --prova "bash olha.sh"

# --- as regras de execução (WT04) ---------------------------------------------------------------------------------
## regras <raiz>: o regras.md existe, tem no máximo 60 linhas, e o 12, o COMO-CONTRIBUIR e a a-esteira apontam para ele.
regras() {
  local r="$1" f="$1/docs/jogo/o-time/regras.md" ok=0
  [ -f "$f" ] || { echo "falta o docs/jogo/o-time/regras.md"; return 1; }
  [ "$(wc -l < "$f")" -le 60 ] || { echo "o regras.md tem $(wc -l < "$f") linhas (o teto é 60)"; ok=1; }
  grep -q '](o-time/regras.md' "$r/docs/jogo/12-como-trabalhar.md" 2>/dev/null || { echo "o 12 não aponta"; ok=1; }
  grep -q '](jogo/o-time/regras.md' "$r/docs/COMO-CONTRIBUIR.md" 2>/dev/null || { echo "o COMO-CONTRIBUIR não aponta"; ok=1; }
  grep -q '](regras.md' "$r/docs/jogo/o-time/a-esteira.md" 2>/dev/null || { echo "a a-esteira não aponta"; ok=1; }
  return "$ok"
}
espera 0 "regras: o regras.md existe, cabe em 60 linhas, e o 12, o COMO-CONTRIBUIR e a a-esteira apontam" regras "$RAIZ"
G="$TMP/regras"
mkdir -p "$G/docs/jogo/o-time"
cp "$RAIZ/docs/COMO-CONTRIBUIR.md" "$G/docs/"; cp "$RAIZ/docs/jogo/12-como-trabalhar.md" "$G/docs/jogo/"
cp "$RAIZ/docs/jogo/o-time/a-esteira.md" "$G/docs/jogo/o-time/"
espera 1 "regras: sem o arquivo, reprova" regras "$G"
{ cat "$RAIZ/docs/jogo/o-time/regras.md"; seq 1 60; } > "$G/docs/jogo/o-time/regras.md"
espera 1 "regras: com mais de 60 linhas, reprova" regras "$G"
cp "$RAIZ/docs/jogo/o-time/regras.md" "$G/docs/jogo/o-time/"
sed -i 's|](o-time/regras.md|](o-time/outro.md|' "$G/docs/jogo/12-como-trabalhar.md"
espera 1 "regras: o 12 sem o link, reprova" regras "$G"

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova da esteira ok — $CASOS casos: a esteira lê o quadro e segura o que deve, a costura para no conflito e no vermelho"
  exit 0
fi
echo "prova da esteira: $FALHAS de $CASOS casos falharam"
exit 1
