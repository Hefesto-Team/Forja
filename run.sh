#!/usr/bin/env bash
# A bancada da Forja: uma porta de entrada para as ferramentas de oficina.
#
#   ./run.sh              abre o menu
#   ./run.sh trilha       vai direto para a bancada da trilha
#   ./run.sh soltar       devolve a memória da placa e sai
#
# A mesma porta serve para quem lê um menu e para quem escreve um comando: o
# menu é a lista de verbos, e todo verbo funciona sozinho na linha de comando.
# Nenhuma opção de traço: o que o comando precisa saber, ele pergunta.
#
# **Ao sair, a placa é devolvida.** Sempre, inclusive com Ctrl+C.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$RAIZ"

# ---------------------------------------------------------------- as cores --
# Só o que um terminal simples entende, e nada sem a palavra junto: a cor
# nunca é a única informação (docs/estudos/02, o checklist da TV).
if [[ -t 1 ]]; then
  N=$'\e[0m'; B=$'\e[1m'; ROSA=$'\e[38;5;211m'; CIANO=$'\e[38;5;117m'
  CINZA=$'\e[38;5;245m'; VERDE=$'\e[38;5;114m'; AMARELO=$'\e[38;5;222m'
else
  N=""; B=""; ROSA=""; CIANO=""; CINZA=""; VERDE=""; AMARELO=""
fi

# ---------------------------------------------------------------- o kit --
# Uma linha por ferramenta: verbo | o que faz | a função que roda.
# Para acrescentar uma ferramenta nova, acrescente uma linha. Mais nada.
KIT=(
  "trilha|A bancada da trilha: gerar, ouvir e escolher as músicas|f_trilha"
  "servidor|O servidor de música (deixe aberto noutra janela)|f_servidor"
  "palavras|Escrever o título e a descrição das faixas|f_palavras"
  "escutar|Abrir a página das candidatas já geradas|f_escutar"
  "jogo|Abrir o jogo|f_jogo"
  "metronomo|Ouvir se o relógio de áudio está preso na batida|f_metronomo"
  "provas|Rodar as provas do jogo|f_provas"
  "kenney|Procurar no pacote da Kenney (modelos, sons, ícones)|f_kenney"
  "onde|Onde mora cada coisa no repositório|f_onde"
  "instalar|Preparar esta máquina (pacotes, módulo, engine, trilha)|f_instalar"
  "estado|O que está instalado e quanto sobra na placa|f_estado"
  "soltar|Devolver a memória da placa agora|f_soltar"
)

# ---------------------------------------------------------------- a saída --

soltar_a_placa() {
  [[ -x "$RAIZ/scripts/trilha_ambiente.sh" ]] || return 0
  bash "$RAIZ/scripts/trilha_ambiente.sh" soltar 2>/dev/null | sed "s/^/${CINZA}  /;s/$/${N}/"
}

ao_sair() {
  local codigo=$?
  echo
  echo "${CINZA}Devolvendo a memória da placa…${N}"
  soltar_a_placa
  echo "${CINZA}Até a próxima.${N}"
  exit $codigo
}
trap ao_sair EXIT INT TERM

# ---------------------------------------------------------------- perguntar --

## Uma pergunta com resposta pronta: Enter aceita o que está entre colchetes.
perguntar() {
  local pergunta="$1" padrao="$2" resposta
  read -r -p "${B}${pergunta}${N} ${CINZA}[${padrao}]${N} " resposta
  printf '%s' "${resposta:-$padrao}"
}

## Uma escolha numerada. Imprime o que foi escolhido.
escolher_entre() {
  local titulo="$1"; shift
  local -a itens=("$@")
  echo
  echo "${B}${titulo}${N}"
  local i=1
  for item in "${itens[@]}"; do
    printf '  %s%2d%s  %s\n' "$CIANO" "$i" "$N" "${item%%|*}"
    i=$((i + 1))
  done
  echo
  local n
  read -r -p "${B}Número${N} ${CINZA}[1]${N} " n
  n="${n:-1}"
  [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#itens[@]} )) || { aviso "Não existe esse número."; return 1; }
  printf '%s' "${itens[$((n - 1))]}"
}

aviso() { echo "${AMARELO}$*${N}"; }
feito() { echo "${VERDE}$*${N}"; }

## Espera a pessoa ler antes de voltar ao menu.
pausa() {
  echo
  read -r -p "${CINZA}Enter para voltar ao menu${N} " _
}

# ---------------------------------------------------------------- as ferramentas --

f_servidor() {
  echo "${CINZA}O servidor de música fica preso nesta janela. Ctrl+C para parar.${N}"
  bash scripts/ace_step.sh servir
}

f_trilha() {
  if [[ ! -x fontes/trilha-venv/bin/python ]]; then
    aviso "A bancada ainda não está instalada."
    local r; r="$(perguntar "Instalar agora? (são uns 15 GB)" "não")"
    [[ "$r" == "sim" || "$r" == "s" ]] || return 0
    bash scripts/trilha_ambiente.sh instalar && bash scripts/trilha_ambiente.sh modelo
  fi
  bash scripts/trilha_ambiente.sh tela
}

f_palavras() {
  local alvo
  alvo="$(escolher_entre "Escrever o título e a descrição de quais faixas?" \
    "Só as que ainda não têm|tudo" \
    "Uma seção inteira (as cinco faixas de um bloco)|secao" \
    "Uma faixa só|uma")" || return 1
  case "${alvo##*|}" in
    tudo) python3 scripts/descrever_trilha.py tudo ;;
    secao) local s; s="$(perguntar "Qual seção, de S01 a S09?" "S01")"
           python3 scripts/descrever_trilha.py "$s" ;;
    uma)  local f; f="$(perguntar "Qual faixa?" "MUS_S01_J01")"
          python3 scripts/descrever_trilha.py "$f" ;;
  esac
}

f_escutar() {
  local pagina="${FORJA_TRILHA:-$RAIZ/fontes/trilha}/index.html"
  python3 - <<'PY'
import sys; sys.path.insert(0, "scripts")
import gerar_trilha as g
print(g.pagina(g.pasta_de_trabalho()))
PY
  if [[ -f "$pagina" ]]; then
    feito "A página está em $pagina"
    local r; r="$(perguntar "Abrir no navegador?" "sim")"
    [[ "$r" == "sim" || "$r" == "s" ]] && { xdg-open "$pagina" >/dev/null 2>&1 & }
  fi
}

f_jogo() { ./run-local.sh; }

f_metronomo() {
  local godot; godot="$(ls tools/Godot_v*_linux.x86_64 2>/dev/null | tail -1)"
  [[ -x "$godot" ]] || { aviso "Rode «Abrir o jogo» uma vez: é ele quem baixa a engine."; return 1; }
  local slot; slot="$(perguntar "Qual faixa quer conferir?" "MUS_S01_J01")"
  echo "${CINZA}Três minutos. O tique tem de cair na batida do começo ao fim.${N}"
  SLOT="$slot" "$godot" --path godot res://testes/metronomo.tscn
}

f_provas() { bash tests/prova_do_jogo.sh; }

f_kenney() {
  local o
  o="$(escolher_entre "O que você quer no pacote da Kenney?" \
    "Procurar por uma palavra (em português ou inglês)|buscar" \
    "Ver as categorias e quanto tem em cada uma|categorias" \
    "Listar os pacotes de uma categoria|pacotes" \
    "Ver o que tem dentro de um pacote|ver")" || return 1
  case "${o##*|}" in
    buscar)     local q; q="$(perguntar "Procurar por" "martelo")"
                python3 scripts/kenney.py buscar "$q" ;;
    categorias) python3 scripts/kenney.py ;;
    pacotes)    local c; c="$(perguntar "Qual categoria (3D, 2D, Audio, Icons, UI, Other)" "3D")"
                python3 scripts/kenney.py pacotes "$c" ;;
    ver)        local n; n="$(perguntar "Nome do pacote" "Castle Kit")"
                python3 scripts/kenney.py ver "$n"
                local caminho; caminho="$(python3 scripts/kenney.py onde "$n" 2>/dev/null)"
                if [[ -d "$caminho" ]]; then
                  local r; r="$(perguntar "Abrir a pasta?" "sim")"
                  [[ "$r" == "sim" || "$r" == "s" ]] && { xdg-open "$caminho" >/dev/null 2>&1 & }
                fi ;;
  esac
}

## Onde mora cada coisa. Com as contas de verdade, não com uma lista decorada:
## se a pasta cresceu, o número cresce junto.
f_onde() {
  local ost="$RAIZ/godot/assets/ost" trab="${FORJA_TRILHA:-$RAIZ/fontes/trilha}"
  conta() { find "$1" -type f ${2:+-name "$2"} 2>/dev/null | wc -l; }
  peso() { du -sh "$1" 2>/dev/null | cut -f1; }

  echo "${B}Duas pastas, e a diferença é toda a confusão:${N}"
  echo "  ${CIANO}godot/assets/${N}  o que está ${B}no jogo${N} — vai para o git"
  echo "  ${CIANO}fontes/${N}        o material ${B}bruto${N} e os rascunhos — fora do git"
  echo

  echo "${B}No jogo (godot/assets/)${N}"
  printf '  %-26s %s\n' "kenney/      modelos 3D" "$(conta "$RAIZ/godot/assets/kenney" '*.glb') peças"
  printf '  %-26s %s\n' "sons/        efeitos"    "$(conta "$RAIZ/godot/assets/sons" '*.wav') arquivos"
  printf '  %-26s %s\n' "ost/         a trilha"   "$(conta "$ost" '*.ogg') faixas aprovadas"
  printf '  %-26s %s\n' "svg/ glifos/ mapa/"      "o desenho do controle e os ícones"
  printf '  %-26s %s\n' "fontes/      tipografia" "Space Grotesk e JetBrains Mono"
  printf '  %-26s %s\n' "forja-logo.svg"          "o logo d'A Forja"
  echo

  echo "${B}Bruto (fontes/, fora do git)${N}"
  printf '  %-26s %s\n' "trilha/      candidatas" "$(conta "$trab" '*.wav') esperando escolha · $(peso "$trab")"
  printf '  %-26s %s\n' "trilha/mp3/  para ouvir" "$(conta "$trab/mp3" '*.mp3') cópias fora do jogo"
  printf '  %-26s %s\n' "kenney/      o pacote"   "$(peso "$RAIZ/fontes/kenney") comprado"
  printf '  %-26s %s\n' "modelos/     IA"         "$(peso "$RAIZ/fontes/modelos")"
  echo

  echo "${B}O resto${N}"
  printf '  %-26s %s\n' "godot/"   "o jogo: cenas, scripts, salas"
  printf '  %-26s %s\n' "nativo/"  "o módulo em C que fala com os controles"
  printf '  %-26s %s\n' "docs/"    "a documentação — comece por docs/README.md"
  printf '  %-26s %s\n' "tests/"   "as provas"
  echo

  local faixas; faixas="$(conta "$ost" '*.ogg')"
  local cand; cand="$(conta "$trab" '*.wav')"
  if [[ "$faixas" == "0" && "$cand" != "0" ]]; then
    echo "${AMARELO}Nenhuma faixa entrou no jogo ainda.${N} As $cand candidatas estão em fontes/trilha/"
    echo "esperando você escolher — é a opção «A bancada da trilha» deste menu."
  fi
}

f_instalar() {
  bash scripts/instalar.sh conferir
  echo
  local r; r="$(perguntar "Instalar o que falta?" "sim")"
  [[ "$r" == "sim" || "$r" == "s" ]] || return 0
  local parte
  parte="$(escolher_entre "O que instalar?" \
    "Tudo (pacotes do sistema, jogo e trilha)|tudo" \
    "Só o jogo (pacotes e módulo; sem a geração de música)|jogo" \
    "Só a trilha (a geração de música)|trilha")" || return 1
  case "${parte##*|}" in
    tudo)   bash scripts/instalar.sh tudo ;;
    jogo)   bash scripts/instalar.sh sistema && bash scripts/instalar.sh modulo ;;
    trilha) bash scripts/instalar.sh trilha ;;
  esac
}

f_estado() { bash scripts/instalar.sh conferir; }

f_soltar() { soltar_a_placa; feito "Pronto."; }

# ---------------------------------------------------------------- o menu --

cabecalho() {
  echo
  echo "  ${ROSA}${B}A FORJA${N} ${CINZA}— a bancada${N}"
  local m
  m="$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | head -1)"
  [[ -n "$m" ]] && echo "  ${CINZA}placa: ${m}${N}"
  echo
}

menu() {
  while true; do
    cabecalho
    local i=1
    for linha in "${KIT[@]}"; do
      IFS='|' read -r _verbo texto _ <<< "$linha"
      printf '  %s%2d%s  %s\n' "$CIANO" "$i" "$N" "$texto"
      i=$((i + 1))
    done
    printf '  %s%2s%s  %s\n' "$CIANO" "0" "$N" "Sair (devolve a memória da placa)"
    echo
    local n
    read -r -p "  ${B}Número${N} " n || break
    [[ "$n" == "0" || -z "$n" ]] && break
    if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#KIT[@]} )); then
      IFS='|' read -r _ _ funcao <<< "${KIT[$((n - 1))]}"
      echo
      "$funcao"
      pausa
    else
      aviso "  Escolha um número da lista."
      sleep 1
    fi
  done
}

# ---------------------------------------------------------------- a entrada --

verbo="${1:-}"
if [[ -z "$verbo" ]]; then
  menu
  exit 0
fi
for linha in "${KIT[@]}"; do
  IFS='|' read -r v _ funcao <<< "$linha"
  if [[ "$v" == "$verbo" ]]; then
    "$funcao"
    exit $?
  fi
done

echo "Não conheço «$verbo». Os verbos:"
for linha in "${KIT[@]}"; do
  IFS='|' read -r v texto _ <<< "$linha"
  printf '  %-10s %s\n' "$v" "$texto"
done
exit 1
