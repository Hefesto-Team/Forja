# F00 — O ambiente da sessão

**Sprint:** F · **Tamanho:** P · **Estimativa:** US$ 1,5

## Por quê

Uma sessão nova na nuvem começa sem os pacotes de sistema, sem o módulo
nativo e sem o Godot. Sem eles, a prova rápida reprova tudo ("o módulo nativo
carregou: FAIL"), e nenhuma outra ficha consegue provar o que fez.

## Ler antes

- [A arquitetura — o ambiente de uma sessão](../13-arquitetura.md#o-ambiente-de-uma-sessão)
- [DESENVOLVER — compilar](../../DESENVOLVER.md)

## O estado de hoje

Medido numa sessão da nuvem em 30/09/2026:

| passo | resultado |
| --- | --- |
| `scripts/compilar.sh linux` sem os pacotes | falha em 17 s: `Couldn't find dependency package for XCURSOR` (e sem ALSA) |
| `apt-get install` da lista de `docs/DESENVOLVER.md:21-25` | 13 s |
| baixar e descompactar o Godot 4.4.1 em `tools/` | 2 s |
| `scripts/compilar.sh linux` com os pacotes | 67 s na primeira vez (baixa o SDL e o godot-cpp e compila tudo); depois, cache em `.cache/` |
| `bash tests/prova_do_jogo.sh` | 106 s, verde ("prova do jogo ok") |

`tools/`, `bin/` e `.cache/` já estão no `.gitignore`.

## O alvo

Um gancho de início de sessão na nuvem que deixa a sessão
pronta sozinha: pacotes, módulo, Godot. Depois dele, a primeira coisa que
qualquer ficha faz é `bash tests/prova_do_jogo.sh`, e ela passa.

## Passos

1. Registrar o gancho de início de sessão na configuração da própria sessão
   na nuvem, **fora do repositório**: ele só chama
   `scripts/preparar_sessao.sh`, que é o que se versiona.
2. Escrever `scripts/preparar_sessao.sh`:
   - sai logo se não está na nuvem (sem a variável de ambiente que só a
     sessão na nuvem define) — na máquina do André não faz nada;
   - `apt-get install -y -qq` com a lista de `docs/DESENVOLVER.md:21-25` mais
     `bubblewrap` e `xvfb` (a prova visual da F09 roda com janela), só se
     faltar algum (`dpkg -s`);
   - baixa o Godot 4.4.1 para `tools/` se não existir (a mesma URL de
     `run-local.sh`);
   - `scripts/compilar.sh linux` se `godot/bin/libforja.linux.x86_64.so` não
     existir;
   - imprime uma linha só no fim: "Ambiente pronto: módulo, Godot, pacotes."
3. Acrescentar em `docs/DESENVOLVER.md` uma seção curta "Na nuvem", e em
   `docs/jogo/13-arquitetura.md` trocar os passos manuais por "o gancho
   F00 prepara".

## Armadilhas

- Nunca rodar `./run-local.sh` na nuvem: ele abre a janela do jogo no fim.
- O gancho precisa ser idempotente e rápido quando já está tudo pronto.
- Não pôr caminho fixo da máquina no script (regra do [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md)).
- Rede: se o download falhar, o script avisa e sai com erro claro, sem
  deixar meio arquivo em `tools/`.

## Não fazer

- Não mexer no `compilar.sh` nem nas versões fixadas (SDL 3.4.14, godot-cpp
  4.4).
- Não instalar o `mingw-w64` (Windows fica na máquina do André).

## Pronto quando

Numa sessão nova, sem nenhum comando manual, `bash tests/prova_do_jogo.sh`
termina com "prova do jogo ok".

## Provas

- Na sessão: abrir uma sessão nova depois do commit e rodar
  `bash tests/prova_do_jogo.sh`.
- Com o André, local: `./run-local.sh` continua abrindo o jogo como antes (o
  gancho não roda fora da nuvem).

## Para o André (local)

Nada além de conferir que `./run-local.sh` não mudou.

## Ao terminar

Marcar F00 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `feat: a sessão da nuvem se prepara sozinha — pacotes, módulo e Godot`.
