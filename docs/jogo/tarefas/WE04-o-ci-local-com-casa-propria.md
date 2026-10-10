# WE04 — O CI local com casa própria

**Sprint:** W · **Tamanho:** M · **Depende de:** —

## Por quê

O `scripts/ci-local.sh` veio do Hefesto com a casa dele: o `act`, os logs, os artefatos e o recibo moram em
`~/.local/state/hefesto-casa`. A Forja tem três devs, e na máquina do André ou da Amanda não há `act` nenhum: o
`ci-local` sai 2 e a `costura.sh --pesadas` diz «VERMELHO» sem ter rodado nada. Na máquina dela, o recibo da Forja
pisa no do Hefesto.

## Ler antes

- [scripts/ci-local.sh](../../../scripts/ci-local.sh) (o cabeçalho e a parte do `act`)
- [scripts/costura.sh](../../../scripts/costura.sh) (o `roda` e o `--pesadas`)

## O estado de hoje

- `scripts/ci-local.sh:63`: `CASA="${HEFESTO_CASA:-$HOME/.local/state/hefesto-casa}"`.
- `scripts/ci-local.sh:218-221` procura o `act` em `$CASA/bin/act` e no PATH; sem ele, sai 2 («não há act»). O
  cabeçalho (`:28`) diz que ele é «baixado da release oficial, com o sha256 conferido», mas nenhum script da Forja o
  baixa (`git grep -n 'bin/act'` só acha o próprio `ci-local`). Hoje ele existe só em
  `~/.local/state/hefesto-casa/bin/act`, e o `which act` não acha nada.
- O recibo vai para `$CASA/ci-local/ultimo-$modo.txt` (`:507-510`), o mesmo caminho do `ci-local` do Hefesto
  (`hefesto-dualsense4unix/scripts/ci-local.sh:50` e `:488`). Medido em 09/10/2026: o `ultimo-rapido.txt` de lá
  diz `c2ff3ccd2695`, um commit da Forja.
- As imagens se chamam `hefesto-ci-local` (`:227`, `:244`). O `EM-TAG` lê `$ARV/pyproject.toml` (`:398`), que a Forja
  não tem. Hoje nenhuma linha da tabela é `EM-TAG`, então esse trecho não roda.
- `scripts/costura.sh:102-111`: o `roda` trata qualquer saída diferente de zero como «costura: VERMELHO» e sai 1. Com
  `--pesadas`, o `ci-local.sh --rapido` que sai 2 (não rodou) vira vermelho.

## O alvo

O `ci-local` funciona em qualquer máquina da Forja sem o Hefesto: a casa é da Forja, o `act` é baixado e conferido
pelo próprio script, o recibo diz de que repositório é, e «não rodou» nunca se confunde com vermelho.

## Passos

1. `CASA="${FORJA_CASA:-$HOME/.local/state/forja-casa}"`, e o recibo passa a ter o nome do repositório na linha.
2. O `act`: versão fixa e sha256 no script (o mesmo molde do SDL em `scripts/compilar.sh:50-57`). Quando não há
   `act` em `$CASA/bin` nem no PATH, o script baixa da release oficial para `$CASA/bin/act`, confere a soma e só
   então segue. Soma que não bate apaga o arquivo e sai 2.
3. As imagens viram `forja-ci-local`. O trecho do `EM-TAG` sai, junto com a linha da regra no comentário da tabela
   (`:39` e `:106`). Se um dia a Forja tiver workflow em tag, ele volta lendo a versão de onde a Forja a guarda.
4. Na `costura.sh`, o passo das pesadas distingue o 2: «costura: as pesadas não rodaram (o ci-local saiu 2)», com um
   rc próprio (4), escrito no cabeçalho junto dos outros.
5. Os casos na `tests/prova_da_esteira.sh`: a costura com um `ci-local` de mentira que sai 2 diz «não rodaram» e sai
   4; com um que sai 1, diz «VERMELHO» e sai 1.

## Armadilhas

- O `ci-local` do Hefesto continua lendo `HEFESTO_CASA`. Não mexer nele nem no que está em
  `~/.local/state/hefesto-casa`.
- O cabeçalho do `ci-local` diz que ele é «o mesmo motor» do Hefesto. Escrever ali o que agora difere (a casa, o
  `act` baixado, as imagens), para quem copiar de volta não desfazer.
- O download do `act` precisa de rede: sem rede, o rc é 2 (não rodou), nunca 1.

## Não fazer

- Não instalar o `act` no sistema nem pedir senha de administrador: ele mora na casa da Forja.
- Não mudar a `TABELA` nem o que cada job roda.

## Pronto quando

Com `HOME` numa pasta vazia, `bash scripts/ci-local.sh --listar` passa e `bash scripts/ci-local.sh --rapido` baixa e
confere o `act` em vez de sair com «não há act»; o recibo nasce em `forja-casa`, e o `ultimo-rapido.txt` do Hefesto
fica como estava.

## Provas

- `HOME=$(mktemp -d) bash scripts/ci-local.sh --listar`.
- `sha256sum ~/.local/state/hefesto-casa/ci-local/ultimo-rapido.txt` antes e depois de um `ci-local.sh --rapido` da
  Forja: igual.
- Uma soma do `act` trocada de propósito: o script apaga o arquivo e sai 2.
- `bash tests/prova_da_esteira.sh`.

## Para o André (local)

Rodar `bash scripts/ci-local.sh --rapido` na máquina dele, sem nada do Hefesto: o `act` baixa sozinho e os jobs
rápidos rodam.

## Ao terminar

Pôr a linha da WE04 no [quadro](README.md) como **feito**, com o commit, e trocar em
[A esteira](../o-time/a-esteira.md) o caminho do recibo, se ele aparecer lá.

## O que foi feito (leva 1, a-entrega)

- A casa: `CASA="${FORJA_CASA:-$HOME/.local/state/forja-casa}"`. O recibo `ultimo-<modo>.txt` nasce em
  `forja-casa/ci-local/` e diz o repositório na linha: `data|repositório|commit|resumo` (o repositório é o nome do
  `origin`, ou o da pasta do repositório sem ele). A `hefesto-casa` e o `HEFESTO_CASA` não são mais lidos pelo
  `ci-local` da Forja; o do Hefesto segue com os dele, intocado.
- O `act`: `ACT_VER=0.2.89` e o sha256 do `act_Linux_x86_64.tar.gz` (conferido contra o `checksums.txt` da release; o
  binário de dentro é o mesmo `6be37b10…` que a máquina já tinha) fixos no script, com `FORJA_ACT_VER` e
  `FORJA_ACT_SHA256` para quem sobe de versão. Sem `act` em `$CASA/bin` nem no PATH, o script baixa, confere a soma
  do pacote e só então instala em `$CASA/bin/act`; sem rede, ou com a soma que não bate (o pacote é apagado), sai 2.
- As imagens montadas viram `forja-ci-local`; o `EM-TAG` saiu inteiro (a regra, a conferência, o JSON da tag e o
  `pyproject.toml`). O cabeçalho diz o que difere do motor do Hefesto.
- A `costura.sh --pesadas`: o `ci-local` que sai 2 vira «costura: as pesadas não rodaram (o ci-local saiu 2)», rc 4,
  escrito no cabeçalho; o que sai 1 segue «VERMELHO», rc 1.
- As provas, na `tests/prova_da_esteira.sh` (59 casos, verde): a costura com um `ci-local` de mentira que sai 2 (rc 4,
  sem «VERMELHO») e que sai 1 (rc 1, «VERMELHO»); o `ci-local` com o HOME vazio, um `curl` de mentira e um `docker`
  que não responde: `--listar` passa, sem rede sai 2 e diz que o act não baixou, com a soma trocada sai 2 e não deixa
  arquivo, com a soma certa instala o act na `forja-casa` e para no docker. Morde: a costura antiga reprova 2 casos, o
  `ci-local` antigo reprova 3.
- Medido com a rede de verdade, num HOME vazio e um docker de mentira: o `--listar` passa, e o `--rapido` baixa o
  0.2.89, confere e para em «o docker não responde» (rc 2).
- Para o André: rodar `bash scripts/ci-local.sh --rapido` na máquina dele, sem nada do Hefesto: o `act` baixa
  sozinho para `~/.local/state/forja-casa/bin/act` e os jobs rápidos rodam.
