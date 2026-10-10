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

## as pesadas (WE04): o ci-local que não rodou (rc 2) não é vermelho. Um ci-local de mentira, fora do índice (a costura
## só olha o que é versionado), sai com o rc de CI_FALSO_RC.
gr switch -q integra
mkdir -p "$R/scripts"
printf '#!/usr/bin/env bash\necho "ci-local de mentira $*"\nexit "${CI_FALSO_RC:?}"\n' > "$R/scripts/ci-local.sh"
for n in 2 1; do
  gr switch -q -c "voo/pesadas-$n" main; printf '%s\n' "$n" > "$R/p$n.txt"; gr add "p$n.txt"; gr commit -q -m "as pesadas $n"
done
gr switch -q integra
ANTES="$(topo)"
espera 4 "costura --pesadas: o ci-local que sai 2 não rodou (rc 4)" \
  env -u VEZ CI_FALSO_RC=2 bash "$C" voo/pesadas-2 --integracao "$R" --prova "bash olha.sh" --pesadas
CASOS=$((CASOS + 1))
if grep -q 'costura: as pesadas não rodaram (o ci-local saiu 2)' "$TMP/saida.log" && ! grep -q VERMELHO "$TMP/saida.log"; then
  echo "ok   costura --pesadas: diz «as pesadas não rodaram», e não «VERMELHO»"
else
  echo "FAIL costura --pesadas: diz «as pesadas não rodaram», e não «VERMELHO»"; FALHAS=$((FALHAS + 1))
fi
git -C "$R" reset -q --keep "$ANTES"
espera 1 "costura --pesadas: o ci-local que sai 1 é vermelho (rc 1)" \
  env -u VEZ CI_FALSO_RC=1 bash "$C" voo/pesadas-1 --integracao "$R" --prova "bash olha.sh" --pesadas
CASOS=$((CASOS + 1))
if grep -q 'costura: VERMELHO em «bash scripts/ci-local.sh --rapido»' "$TMP/saida.log" \
    && ! grep -q 'não rodaram' "$TMP/saida.log"; then
  echo "ok   costura --pesadas: o 1 do ci-local diz «VERMELHO»"
else
  echo "FAIL costura --pesadas: o 1 do ci-local diz «VERMELHO»"; FALHAS=$((FALHAS + 1))
fi
git -C "$R" reset -q --keep "$ANTES"

# --- o ci-local com casa própria (WE04) -----------------------------------------------------------------------------
## Um HOME vazio, um curl de mentira que entrega um pacote do act feito na hora (ou falha como rede caída) e um docker
## que não responde: o ci-local baixa e confere o act, e para no docker com rc 2. Nada sai para a rede.
H="$TMP/ci-local"
mkdir -p "$H/home" "$H/bin" "$H/pacote" "$H/tmp"
printf '#!/bin/sh\necho "act de mentira"\n' > "$H/pacote/act"; chmod +x "$H/pacote/act"
tar -czf "$H/act.tar.gz" -C "$H/pacote" act
SOMA_ACT="$(sha256sum "$H/act.tar.gz" | cut -d' ' -f1)"
cat > "$H/bin/curl" <<CURL
#!/bin/sh
[ -n "\${CURL_FALSO_SEM_REDE:-}" ] && exit 6
while [ \$# -gt 0 ]; do [ "\$1" = -o ] && { cp "$H/act.tar.gz" "\$2"; exit 0; }; shift; done
exit 1
CURL
printf '#!/bin/sh\nexit 1\n' > "$H/bin/docker"
chmod +x "$H/bin/curl" "$H/bin/docker"
cil() { # [VAR=valor ...] argumentos do ci-local
  local mais=()
  while [ $# -gt 0 ] && [ "${1#*=}" != "$1" ]; do mais+=("$1"); shift; done
  env -u FORJA_CASA HOME="$H/home" TMPDIR="$H/tmp" PATH="$H/bin:$PATH" "${mais[@]}" bash "$RAIZ/scripts/ci-local.sh" "$@"
}
CASA_ACT="$H/home/.local/state/forja-casa/bin/act"
espera 0 "ci-local: com o HOME vazio, o --listar passa" cil --listar
if command -v act > /dev/null 2>&1; then
  echo "     (esta máquina tem um act no PATH: os casos do download ficam de fora)"
else
  espera 2 "ci-local: sem rede, o act não baixa e o --rapido sai 2 (não rodou)" cil CURL_FALSO_SEM_REDE=1 --rapido
  cp "$TMP/saida.log" "$H/ultima.log"
  espera 0 "ci-local: e diz que o act não baixou" grep -q "o act não baixou de " "$H/ultima.log"
  espera 2 "ci-local: com a soma do act trocada, sai 2" cil FORJA_ACT_SHA256="$(printf '%064d' 0)" --rapido
  cp "$TMP/saida.log" "$H/ultima.log"
  espera 0 "ci-local: e diz que a soma não confere" grep -q "sha256 do act não confere: $SOMA_ACT" "$H/ultima.log"
  espera 0 "ci-local: e não deixa o act na casa nem o pacote no temporário" \
    bash -c '[ ! -e "$1" ] && [ -z "$(ls -A "$2")" ]' _ "$CASA_ACT" "$H/tmp"
  espera 2 "ci-local: com a soma certa, baixa o act e para no docker que não responde (rc 2)" \
    cil FORJA_ACT_SHA256="$SOMA_ACT" --rapido
  cp "$TMP/saida.log" "$H/ultima.log"
  espera 0 "ci-local: o act conferido mora na casa da Forja e não na do Hefesto" \
    bash -c '[ -x "$1" ] && [ ! -e "$2" ] && grep -q "act .* conferido em $1" "$3" && grep -q "o docker não responde" "$3"' \
    _ "$CASA_ACT" "$H/home/.local/state/hefesto-casa" "$H/ultima.log"
fi

# --- o gauntlet: a lista é a do simulador (WE03) ------------------------------------------------------------------
## As partes do scripts/gauntlet.sh que não abrem o Godot: as pernas do CI saem da tabela do simulador e cobrem todo
## defeito que o simulador.h declara; lista vazia e defeito desconhecido não rodam (rc 2).
pernas_cobrem() { # <raiz>: as pernas do --pernas 4 cobrem os DEFEITO_* do simulador.h, uma vez cada, e a primeira leva o limpo
  bash "$1/scripts/gauntlet.sh" --pernas 4 > "$TMP/pernas.json" || return 1
  python3 - "$TMP/pernas.json" "$1/nativo/nucleo/simulador.h" <<'PY'
import json, re, sys
pernas = json.load(open(sys.argv[1]))
h = open(sys.argv[2], encoding="utf-8").read()
declarados = [n.lower().replace("_", "-") for n in re.findall(r"^\s*DEFEITO_([A-Z0-9_]+)\s*=\s*1\s*<<", h, re.M)]
so = [d for p in pernas for d in p["so"].split(",")]
nomes_ok = all(p["nome"] == p["so"].replace(",", ", ") for p in pernas)
print("pernas:", len(pernas), "declarados:", len(declarados), "nas pernas:", len(so))
sys.exit(0 if (len(pernas) == 4 and so[0] == "limpo" and so.count("limpo") == 1 and nomes_ok
               and sorted(d for d in so if d != "limpo") == sorted(declarados) and declarados) else 1)
PY
}
espera 0 "gauntlet: as quatro pernas cobrem todo defeito do simulador.h, uma vez cada, e a primeira leva o limpo" \
  pernas_cobrem "$RAIZ"
K="$TMP/gauntlet"
mkdir -p "$K/scripts" "$K/nativo/nucleo"
cp "$RAIZ/scripts/gauntlet.sh" "$K/scripts/"; cp "$RAIZ/nativo/nucleo/simulador.h" "$K/nativo/nucleo/"
grep -v '^    {"' "$RAIZ/nativo/nucleo/simulador.c" > "$K/nativo/nucleo/simulador.c"
espera 2 "gauntlet: a tabela do simulador sem nenhum defeito sai 2" bash "$K/scripts/gauntlet.sh" --pernas 4
grep -v '{"engasga", DEFEITO_ENGASGA}' "$RAIZ/nativo/nucleo/simulador.c" > "$K/nativo/nucleo/simulador.c"
espera 1 "gauntlet: o defeito que o simulador.h declara e a tabela esquece fica sem perna, e reprova" pernas_cobrem "$K"
espera 2 "gauntlet: --so com um defeito que o simulador não tem sai 2" bash "$RAIZ/scripts/gauntlet.sh" --so limpo,nada

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
cp "$RAIZ/docs/jogo/12-como-trabalhar.md" "$G/docs/jogo/"
sed -i 's|](jogo/o-time/regras.md|](jogo/o-time/outro.md|' "$G/docs/COMO-CONTRIBUIR.md"
espera 1 "regras: o COMO-CONTRIBUIR sem o link, reprova" regras "$G"
cp "$RAIZ/docs/COMO-CONTRIBUIR.md" "$G/docs/"
sed -i 's|](regras.md|](outro.md|' "$G/docs/jogo/o-time/a-esteira.md"
espera 1 "regras: a a-esteira sem o link, reprova" regras "$G"

# --- os estados de uma ficha (WT05) -------------------------------------------------------------------------------
## estados_iguais <raiz>: a lista da a-esteira («Os estados de uma ficha», os itens em negrito) é a ESTADOS do script.
estados_iguais() {
  python3 - "$1/docs/jogo/o-time/a-esteira.md" "$RAIZ/scripts" <<'PY'
import re, sys
sys.path.insert(0, sys.argv[2])
from esteira import ESTADOS
texto = open(sys.argv[1], encoding="utf-8").read()
secao = texto.split("## Os estados de uma ficha", 1)[1].split("\n## ", 1)[0]
doc = re.findall(r"^- \*\*([^*:]+):\*\*", secao, re.M)
print("a-esteira:", doc); print("esteira.py:", ESTADOS)
sys.exit(0 if doc == ESTADOS else 1)
PY
}
espera 0 "estados: a lista da a-esteira e a do scripts/esteira.py são a mesma" estados_iguais "$RAIZ"
E="$TMP/estados"; mkdir -p "$E/docs/jogo/o-time"
grep -v '^- \*\*espera o André:\*\*' "$RAIZ/docs/jogo/o-time/a-esteira.md" > "$E/docs/jogo/o-time/a-esteira.md"
espera 1 "estados: a a-esteira sem um estado do script reprova" estados_iguais "$E"
E="$TMP/quase"; cp -r "$Q" "$E"
sed -i 's/^\(| \[F01\].*| \)a fazer |$/\1quase pronta |/' "$E/docs/jogo/tarefas/README.md"
espera 2 "esteira: o estado fora da lista («quase pronta») sai 2" python3 "$RAIZ/scripts/esteira.py" --raiz "$E"
espera 0 "esteira: e diz a ficha e o texto" \
  bash -c "python3 '$RAIZ/scripts/esteira.py' --raiz '$E' 2>&1 >/dev/null | grep -q 'F01: «quase pronta»'"
E="$TMP/texto"; cp -r "$Q" "$E"
sed -i -e 's/^\(| \[F00\].*| \)feito |$/\1feito, sem a parte B |/' \
  -e 's/^\(| \[H01\].*| \)a fazer |$/\1espera o André (a parte A feita) |/' \
  -e 's/^\(| \[G02\].*| \)pronta |$/\1fazendo (Ana) |/' "$E/docs/jogo/tarefas/README.md"
espera 0 "esteira: o estado com texto depois se lê pelo começo" \
  bash -c "python3 '$RAIZ/scripts/esteira.py' --raiz '$E' > '$TMP/esteira.json'"
confere "esteira: «feito, sem…» é feito, «espera o André (…)» é ele, «fazendo (Ana)» é em voo de Ana" \
  "'F' in [p['secao'] for p in d['prontas_para_despachar']] and d['em_voo']['Ana']['fichas'] == ['G02'] and any(b['secao'] == 'H' and any('H01 (espera o André)' in m for m in b['motivos']) for b in d['bloqueadas'])"
E="$TMP/marcar"; cp -r "$Q" "$E"; cp "$E/docs/jogo/tarefas/README.md" "$TMP/quadro-antes.md"
espera 2 "costura --marcar: recusa «quase pronta»" bash "$RAIZ/scripts/costura.sh" --marcar F01 "quase pronta" --integracao "$E"
espera 2 "costura --marcar: recusa o nome antigo «fazendo», que só vale na leitura" bash "$RAIZ/scripts/costura.sh" --marcar F01 "fazendo (Ana)" --integracao "$E"
espera 0 "costura --marcar: recusado, o quadro não muda" cmp "$TMP/quadro-antes.md" "$E/docs/jogo/tarefas/README.md"
espera 2 "costura --marcar: a ficha que o quadro não tem sai 2" bash "$RAIZ/scripts/costura.sh" --marcar Z9 feito --integracao "$E"
espera 0 "costura --marcar: troca só a última coluna da linha da ficha" \
  bash -c "bash '$RAIZ/scripts/costura.sh' --marcar F01 'espera o André (a parte A)' --integracao '$E' \
    && [ \"\$(diff '$TMP/quadro-antes.md' '$E/docs/jogo/tarefas/README.md' | grep -c '^[<>]')\" = 2 ] \
    && grep -qx '| \[F01\](F01.md) | .* | espera o André (a parte A) |' '$E/docs/jogo/tarefas/README.md'"

echo
if [ "$FALHAS" -eq 0 ]; then
  echo "prova da esteira ok — $CASOS casos: a esteira lê o quadro e segura o que deve, a costura para no conflito e no vermelho"
  exit 0
fi
echo "prova da esteira: $FALHAS de $CASOS casos falharam"
exit 1
