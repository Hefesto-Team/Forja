# WT04 — As regras da casa no repositório

**Sprint:** W · **Tamanho:** P · **Depende de:** nada; a [WT05](WT05-um-lugar-so-para-os-estados.md) mexe no 12 e
no COMO-CONTRIBUIR também: uma depois da outra

## Por quê

A Forja tem três pessoas no mesmo repositório. As regras que mais evitaram estrago (a cura vai à origem e cobre todos
os chamadores; medir antes de mudar; decisão aberta se escreve «a validar por ela»; nunca escrever no controle de
quem está jogando, nem `sudo`, nem `git add -A`, nem `--no-verify`; commit por caminho, a cada passo que funciona)
moram só no molde da esteira, fora do repositório, numa pasta desta máquina. O André e a Amanda não as leem, e cada
execução da esteira as recebe coladas no começo, inteiras, em cada um dos três papéis. Uma regra que só existe numa
máquina é a regra que o repositório da casa proíbe.

## Ler antes

- [Como contribuir, «As regras da casa»](../../COMO-CONTRIBUIR.md#as-regras-da-casa)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `docs/COMO-CONTRIBUIR.md:17-42`, as regras de hoje: português, autor sem trailer, nada preso a uma máquina, o SDK
  da Sony, a voz das telas, o jogo não é teste, trabalho novo é ficha. Não estão lá:
  ```bash
  grep -rniE 'cura vai à origem|meça antes|a validar por ela|git add -A|--no-verify' docs README.md COMO-RODAR.md
  ```
  acha só citações soltas em fichas feitas (F00, F01, F04, F08, F09, F09b, H06, H07), nenhuma como regra.
- O repositório não tem arquivo de instruções na raiz para quem executa fichas, e a prova sem rastro proíbe os nomes
  de arquivo próprios de uma ferramenta (`tests/prova_sem_rastro.sh`).
- `docs/jogo/12-como-trabalhar.md:69-76`, «A economia de contexto», diz como ler, não o que nunca fazer.
- `docs/jogo/o-time/a-esteira.md` descreve a esteira e não lista as regras.

## O alvo

`docs/jogo/o-time/regras.md`, com no máximo 60 linhas: os princípios, o «nunca» e o jeito do commit, cada linha com o
defeito que a fez nascer quando houver. O COMO-CONTRIBUIR, o 12 e a a-esteira apontam para ele, sem repetir. O molde
da esteira passa a dizer «as regras: `docs/jogo/o-time/regras.md`, inteiro» em vez de colar o texto (isso é fora do
repositório e fica no relato, para quem cuida do molde).

## Arquivos que mudam

- `docs/jogo/o-time/regras.md` (novo)
- `docs/COMO-CONTRIBUIR.md`, `docs/jogo/12-como-trabalhar.md`, `docs/jogo/o-time/a-esteira.md` (um link cada)
- `docs/jogo/o-time/README.md` (a linha do arquivo novo)
- `tests/prova_da_esteira.sh` (a checagem)

## Passos

1. Escrever o `regras.md` em três partes: «Os princípios», «Nunca» e «O commit». O texto vem do que a casa já
   pratica (o COMO-CONTRIBUIR e o relato das levas), sem nome de máquina, de pasta pessoal nem de ferramenta.
2. No COMO-CONTRIBUIR, a seção «As regras da casa» ganha a linha «as regras de execução: `jogo/o-time/regras.md`», com link
   e não repete as do arquivo novo.
3. No 12, «O ciclo de uma ficha», passo 3: a sessão lê a ficha, os links e o `regras.md`.
4. Na `tests/prova_da_esteira.sh`: o `regras.md` existe, tem no máximo 60 linhas e o 12, o COMO-CONTRIBUIR e a
   a-esteira têm link para ele.

## Armadilhas

- **A prova sem rastro** varre o texto novo: nada de nome de ferramenta, de modelo nem de caminho de uma máquina.
  Rodar antes do commit.
- **A regra do controle** já está em dois lugares (o COMO-CONTRIBUIR e o «Modo bancada» do docs/jogo): o
  `regras.md` aponta, não copia uma terceira vez.
- **«A validar por ela»** fala da dona do projeto: escrever como regra de processo (a decisão aberta vai para o
  ESPERA-ELA), sem frase que pareça aprovação dada.

## Não fazer

- Não criar arquivo de instruções na raiz com nome de ferramenta.
- Não mudar regra nenhuma: só pôr por escrito as que já valem.

## Pronto quando

`bash tests/prova_da_esteira.sh` passa com as quatro checagens do passo 4 (hoje o arquivo não existe), e
`bash tests/prova_sem_rastro.sh` segue verde.

## Provas

- `bash tests/prova_da_esteira.sh`, `bash tests/prova_sem_rastro.sh`, `bash scripts/portoes/rodar.sh`.

## Para o André (local)

Ler o `regras.md` inteiro (menos de dois minutos) e marcar no relato a regra que ele não conhecia ou que não pratica.

## Ao terminar

Pôr a linha da WT04 no [quadro](README.md) como **feito**, com o commit, e dizer no relato que o molde da esteira
pode trocar o texto colado pelo link.

## O que foi feito (leva 1, as-regras)

- **Entrou:** `docs/jogo/o-time/regras.md` (49 linhas: «Os princípios», «Nunca» e «O commit»), com um link no
  COMO-CONTRIBUIR («As regras da casa»), no 12 (o passo 3 do ciclo), na a-esteira («Os limites») e no README do time.
  A regra do controle aponta para a a-esteira, sem terceira cópia.
- **Provas:** `bash tests/prova_da_esteira.sh` com as quatro checagens; sem o arquivo, a checagem do repositório
  reprova («falta o docs/jogo/o-time/regras.md»), e a prova morde a si mesma com o arquivo ausente, com 61 linhas e
  com cada um dos três links tirado (o 12, o COMO-CONTRIBUIR e a a-esteira; os dois últimos entraram na conferência). `bash tests/prova_sem_rastro.sh` e `bash scripts/portoes/rodar.sh` verdes.
- **Fica para quem cuida do molde da esteira:** trocar o texto das regras colado no começo de cada papel por
  «as regras: `docs/jogo/o-time/regras.md`, inteiro».
- **Fica para o André:** ler o `regras.md` e dizer a regra que ele não conhecia ou não pratica.
