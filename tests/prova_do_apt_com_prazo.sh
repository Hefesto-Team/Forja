#!/usr/bin/env bash
# A prova do apt com prazo: nenhum job do CI espera o espelho do apt sem prazo.
#
# O defeito medido (07/10/2026, corrida 37697457630, primeira tentativa): o passo «Dependências» do job
# windows ficou 1889 s no `apt-get install`, baixando do espelho a ~120 kB/s, até ser cancelado à mão; o
# normal é de 8 a 43 s, e o mais lento que ainda terminou verde levou 288 s (corrida 37705393614, job linux,
# 83 kB/s). Sem `timeout-minutes`, o GitHub espera 360 min.
#
# Lê cada workflow de .github/workflows/ e, em todo job que chama o apt (`apt-get` ou `apt update|install`),
# reprova:
#   - o job sem `timeout-minutes`;
#   - o passo do apt sem `timeout-minutes`;
#   - a falta de um passo ANTERIOR ao primeiro apt que grave em /etc/apt/apt.conf.d/ o
#     `Acquire::Retries` e o `Acquire::http::Timeout` (vale para todo apt do job, inclusive o de um script).
# Linha de comentário e o `name:` do passo não contam como chamada do apt. A indentação é lida do arquivo, e
# o apt fora de um passo que a régua leia reprova.
#
# Depois da varredura, a prova MORDE a si mesma: tira de uma cópia do forja.yml cada pedaço do prazo e
# confere que a régua reprova, e monta workflows de mentira para a ordem e para o que deve passar.
#
# Não precisa de rede, de Godot nem de módulo compilado, e roda em um segundo.
# Uso: bash tests/prova_do_apt_com_prazo.sh             (varre e morde)
#      bash tests/prova_do_apt_com_prazo.sh --so-varrer  (sem as mordidas)
set -u
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

## conferir <workflow.yml>: uma linha por defeito na saída; rc 0 limpo, 1 com defeito.
## Na saída de erro, «apt-jobs N»: quantos jobs chamam o apt (a guarda contra a régua cega).
## A indentação não é fixa: a dos jobs, a das chaves do job, a do traço dos passos e a das chaves do passo
## são lidas do próprio arquivo (o YAML aceita `steps:` com o traço na mesma coluna da chave, ou recuado).
## Uma chamada do apt que não caia dentro de um passo lido reprova: a régua não passa o que não soube ler.
conferir() {
  awk -v ARQ="${1#"$RAIZ"/}" '
    function fecha_job(   s, conf, primeiro) {
      if (job == "" || (napt == 0 && nfora == 0)) { job = ""; return }
      apt_jobs++
      for (s = 1; s <= nfora; s++) {
        print ARQ ": job " job ": o apt (linha " fora_linha[s] ") fora de um passo que a régua leia"
        erros++
      }
      if (napt == 0) { job = ""; return }
      primeiro = apt_linha[1]
      if (!job_prazo) { print ARQ ": job " job ": chama o apt e não tem timeout-minutes"; erros++ }
      conf = 0
      for (s = 1; s <= nconf; s++) if (conf_linha[s] < primeiro) conf = 1
      if (!conf) {
        print ARQ ": job " job ": o apt (linha " primeiro ") sem um passo antes que grave Acquire::Retries e Acquire::http::Timeout em /etc/apt/apt.conf.d/"
        erros++
      }
      for (s = 1; s <= napt; s++)
        if (!apt_passo_prazo[s]) { print ARQ ": job " job ": o passo do apt (linha " apt_linha[s] ") não tem timeout-minutes"; erros++ }
      job = ""
    }
    function fecha_passo() {
      if (!em_passo) return
      if (p_conf && p_retries && p_timeout) conf_linha[++nconf] = p_inicio
      if (p_apt) { napt++; apt_linha[napt] = p_apt; apt_passo_prazo[napt] = p_prazo }
      em_passo = 0
    }
    function chama_apt(l) {
      return l ~ /(^|[^A-Za-z0-9_.\/-])apt-get[ \t]/ || \
             l ~ /(^|[^A-Za-z0-9_.\/-])apt[ \t]+(update|install|upgrade|full-upgrade|dist-upgrade)/
    }
    BEGIN { erros = 0; apt_jobs = 0; em_jobs = 0; job = ""; job_ind = -1 }
    /^[ \t]*$/ { next }
    /^jobs:[ \t]*(#.*)?$/ { em_jobs = 1; next }
    em_jobs && /^[^ \t#]/ { fecha_passo(); fecha_job(); em_jobs = 0 }
    !em_jobs { next }
    /^[ \t]*#/ { next }
    { match($0, /^ */); ind = RLENGTH }
    job_ind < 0 { job_ind = ind }
    ind <= job_ind {
      fecha_passo(); fecha_job()
      job = substr($0, ind + 1); sub(/:.*$/, "", job)
      job_prazo = 0; napt = 0; nconf = 0; nfora = 0; em_passo = 0; em_steps = 0; chave_ind = -1; traco_ind = -1
      next
    }
    job == "" { next }
    chave_ind < 0 { chave_ind = ind }
    # uma chave do job (runs-on, timeout-minutes, steps, needs…): fecha o passo em curso. O traço de um passo
    # pode estar na mesma coluna da chave `steps:`, e então não é chave do job.
    ind < chave_ind || (ind == chave_ind && !(em_steps && $0 ~ /^ *-([ \t]|$)/)) {
      fecha_passo()
      em_steps = ($0 ~ /^ *steps:[ \t]*(#.*)?$/)
      if ($0 ~ /^ *timeout-minutes:[ \t]*[0-9]/) job_prazo = 1
      if (chama_apt($0)) fora_linha[++nfora] = NR
      next
    }
    em_steps && traco_ind < 0 && $0 ~ /^ *-([ \t]|$)/ { traco_ind = ind }
    # o traço abre um passo; a chave do passo é o que vem depois do traço, ou a linha na coluna das chaves dele
    {
      chave = ""
      if (em_steps && ind == traco_ind && $0 ~ /^ *-([ \t]|$)/) {
        fecha_passo()
        em_passo = 1; p_inicio = NR; p_apt = 0; p_prazo = 0; p_conf = 0; p_retries = 0; p_timeout = 0
        chave = substr($0, ind + 2); match(chave, /^[ \t]*/); passo_ind = ind + 1 + RLENGTH
        chave = substr(chave, RLENGTH + 1)
      } else if (em_passo && ind == passo_ind) {
        chave = substr($0, ind + 1)
      }
    }
    !em_passo {
      if (chama_apt($0)) fora_linha[++nfora] = NR
      next
    }
    chave ~ /^timeout-minutes:[ \t]*[0-9]/ { p_prazo = 1 }
    chave ~ /^name:/ { next }
    {
      if (index($0, "/etc/apt/apt.conf.d/")) p_conf = 1
      if (index($0, "Acquire::Retries")) p_retries = 1
      if (index($0, "Acquire::http::Timeout")) p_timeout = 1
      if (!p_apt && chama_apt($0)) p_apt = NR
    }
    END {
      fecha_passo(); fecha_job()
      print "apt-jobs " apt_jobs > "/dev/stderr"
      exit (erros > 0)
    }
  ' "$1"
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/forja-apt-prazo-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
FALHAS=0

# ---- a varredura: os workflows da árvore ----
total_apt=0
for wf in "$RAIZ"/.github/workflows/*.yml; do
  [ -f "$wf" ] || continue
  if conferir "$wf" > "$TMP/real.txt" 2> "$TMP/conta.txt"; then
    :
  else
    echo "FAIL o apt sem prazo em ${wf#"$RAIZ"/}:"
    sed 's/^/     /' "$TMP/real.txt"
    FALHAS=$((FALHAS + 1))
  fi
  n="$(awk '/^apt-jobs /{print $2}' "$TMP/conta.txt")"
  total_apt=$((total_apt + ${n:-0}))
done
# régua que não acha apt nenhum não mede nada: se o apt saiu do CI, esta prova sai junto
if [ "$total_apt" -eq 0 ]; then
  echo "FAIL nenhum job com apt nos workflows: a régua ficou cega (o apt mudou de forma?)"
  FALHAS=$((FALHAS + 1))
elif [ "$FALHAS" -eq 0 ]; then
  echo "ok   os $total_apt jobs com apt gravam o prazo antes e têm timeout-minutes no job e no passo"
fi

[ "${1:-}" = "--so-varrer" ] && { [ "$FALHAS" -eq 0 ] && exit 0 || exit 1; }

# ---- as mordidas ----
REAL="$RAIZ/.github/workflows/forja.yml"

## tirar <job> <padrão ERE> <saída>: a cópia do forja.yml sem a primeira linha do job que casa o padrão.
tirar() {
  awk -v JOB="$1" -v PAD="$2" '
    /^  [A-Za-z0-9_-]+:[ \t]*$/ { j = $1; sub(/:$/, "", j) }
    !feito && j == JOB && $0 ~ PAD { feito = 1; next }
    { print }
  ' "$REAL" > "$3"
}

## morde <nome> <esperado: reprova|passa> <arquivo>
morde() {
  local nome="$1" esperado="$2" arquivo="$3" rc
  conferir "$arquivo" > "$TMP/m.txt" 2> /dev/null
  rc=$?
  if { [ "$esperado" = reprova ] && [ "$rc" -eq 1 ]; } || { [ "$esperado" = passa ] && [ "$rc" -eq 0 ]; }; then
    echo "ok   morde: $nome ($esperado)"
  else
    echo "FAIL morde: $nome (esperava $esperado, rc=$rc)"; sed 's/^/     /' "$TMP/m.txt"
    FALHAS=$((FALHAS + 1))
  fi
}

## morde_tirando <nome> <job> <padrão>: tira a linha da cópia, confere que mudou e que a régua reprova.
morde_tirando() {
  tirar "$2" "$3" "$TMP/w.yml"
  if cmp -s "$REAL" "$TMP/w.yml"; then
    echo "FAIL morde: $1 (a linha não existe no forja.yml: a mordida não tirou nada)"; FALHAS=$((FALHAS + 1)); return
  fi
  morde "$1" reprova "$TMP/w.yml"
}

morde_tirando "o job windows sem o Acquire::Retries"        windows  'Acquire::Retries'
morde_tirando "o job linux sem o Acquire::http::Timeout"    linux    'Acquire::http::Timeout'
morde_tirando "o job exportar sem gravar o apt.conf.d"      exportar '/etc/apt/apt[.]conf[.]d/'
morde_tirando "o job telas sem o timeout-minutes do job"    telas    '^    timeout-minutes:'
morde_tirando "o job windows sem o timeout-minutes do apt"  windows  '^        timeout-minutes:.*'

# o prazo gravado DEPOIS do apt não vale
cat > "$TMP/ordem.yml" <<'FIM'
jobs:
  j:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: Dependências
        timeout-minutes: 8
        run: sudo apt-get update
      - name: O prazo, tarde demais
        run: printf 'Acquire::Retries "3";\nAcquire::http::Timeout "30";\n' | sudo tee /etc/apt/apt.conf.d/80-prazo
FIM
morde "o prazo gravado depois do apt" reprova "$TMP/ordem.yml"

# um job novo com o apt cru, ao lado de um job em ordem, e a forma `apt install`
cat > "$TMP/novo.yml" <<'FIM'
jobs:
  certo:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: O prazo do apt
        run: printf 'Acquire::Retries "3";\nAcquire::http::Timeout "30";\n' | sudo tee /etc/apt/apt.conf.d/80-prazo
      - name: Dependências
        timeout-minutes: 8
        run: sudo apt-get install -y cmake
  novo:
    runs-on: ubuntu-24.04
    steps:
      - run: |
          sudo apt install -y ninja-build
FIM
morde "um job novo com o apt sem prazo" reprova "$TMP/novo.yml"

# o que passa: o job sem apt (sem prazo nenhum), o apt num comentário e no nome do passo, o workflow certo
cat > "$TMP/passa.yml" <<'FIM'
jobs:
  sem-apt:
    runs-on: ubuntu-24.04
    steps:
      # o apt-get update daqui saiu: o runner já tem tudo
      - name: Sem apt-get update, o apt já está pronto
        run: echo ok
  certo:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: O prazo do apt
        timeout-minutes: 1
        run: printf 'Acquire::Retries "3";\nAcquire::http::Timeout "30";\n' | sudo tee /etc/apt/apt.conf.d/80-prazo
      - name: Dependências
        timeout-minutes: 8
        run: |
          sudo apt-get update
          sudo apt-get install -y cmake
FIM
morde "o job sem apt, o apt no comentário e no nome, e o job certo" passa "$TMP/passa.yml"

# o traço dos passos na coluna da chave `steps:` (YAML válido): a régua lê a indentação do arquivo
cat > "$TMP/recuo.yml" <<'FIM'
jobs:
    cru:
        runs-on: ubuntu-24.04
        steps:
        - name: Dependências
          run: sudo apt-get install -y cmake
FIM
morde "o apt sem prazo com o traço na coluna de steps:" reprova "$TMP/recuo.yml"
cat > "$TMP/recuo-certo.yml" <<'FIM'
jobs:
    certo:
        runs-on: ubuntu-24.04
        steps:
        -   name: O prazo do apt
            run: printf 'Acquire::Retries "3";\nAcquire::http::Timeout "30";\n' | sudo tee /etc/apt/apt.conf.d/80-prazo
        -   name: Dependências
            run: |
              sudo apt-get update
              sudo apt-get install -y cmake
            timeout-minutes: 8
        timeout-minutes: 10
FIM
morde "o job certo com outra indentação e o prazo do job depois dos passos" passa "$TMP/recuo-certo.yml"
cat > "$TMP/recuo-prazo-fundo.yml" <<'FIM'
jobs:
    fundo:
        runs-on: ubuntu-24.04
        timeout-minutes: 10
        steps:
        -   name: O prazo do apt
            run: printf 'Acquire::Retries "3";\nAcquire::http::Timeout "30";\n' | sudo tee /etc/apt/apt.conf.d/80-prazo
        -   name: Dependências
            run: |
              sudo apt-get install -y cmake
              # timeout-minutes: 8 aqui é texto do script, não o prazo do passo
            with:
              timeout-minutes: 8
FIM
morde "o timeout-minutes fora da coluna das chaves do passo" reprova "$TMP/recuo-prazo-fundo.yml"
cat > "$TMP/fora.yml" <<'FIM'
jobs:
  fora:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    env:
      DEPENDENCIAS: sudo apt-get install -y cmake
    steps:
      - run: eval "$DEPENDENCIAS"
FIM
morde "o apt fora de um passo que a régua leia" reprova "$TMP/fora.yml"

if [ "$FALHAS" -eq 0 ]; then
  echo "prova do apt com prazo ok — todo apt do CI tem prazo, e a régua reprova cada pedaço tirado"
  exit 0
fi
exit 1
