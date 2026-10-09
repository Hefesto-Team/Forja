# V06 — As provas que ninguém roda

**Sprint:** V · **Tamanho:** P · **Depende de:** —

## Por quê

Seis ferramentas têm prova própria (`--prova`) e o CI nunca a chama, e o baixador dos modelos de exportação não tem
prova nenhuma: quebram em silêncio e só se descobre no dia de gerar a trilha ou exportar.

## Ler antes

- [.github/workflows/forja.yml](../../../.github/workflows/forja.yml) (o passo «As ferramentas de bancada e as provas
  delas»)
- [scripts/modelos_de_exportacao.py](../../../scripts/modelos_de_exportacao.py)

## O estado de hoje

- `scripts/kenney.py --prova`, `scripts/mapa_de_batidas.py --prova` e `scripts/trilha_fichas.py --prova` passam
  (medido em 08/10/2026: `ok o catálogo lista 24011 arquivos`, `ok a faixa que escorrega é apontada…`,
  `ok MUS_S01_J01 é «O Martelo de Hefesto…»`), mas `grep -rn -- '--prova' tests .github` não acha nenhuma das três.
- `scripts/gerar_trilha.py --prova` (o fluxo com o motor de mentira) e `scripts/descrever_trilha.py --prova` (sem
  rede e sem placa) também passam e também ficam fora (medido em 08/10/2026: `ok o jingle não ganha mapa de batidas`,
  `ok o trilha_prompts.json voltou como estava`); nenhuma das duas deixa a árvore suja.
- `scripts/bancada_tui.py --prova` não roda fora da oficina: cai em `ModuleNotFoundError: No module named 'textual'`
  na linha 28, antes de chegar à prova. Fica fora da prova nova, com a razão escrita nela.
- `scripts/conferir_ost.py` já roda, pela `tests/prova_do_jogo.sh`; não entra.
- `kenney.py --prova` diz que «confere sem depender do pacote», e na máquina achou o pacote: falta saber se passa
  sem ele (no CI não há pacote).
- `scripts/modelos_de_exportacao.py` (90 linhas, `main` em `:66`) baixa os modelos e confere `nome=sha256`; nenhuma
  prova cobre a recusa de uma soma errada.

## Arquivos que mudam

- `tests/prova_das_ferramentas.sh` (nova): roda as cinco `--prova` e a prova do baixador
- `scripts/modelos_de_exportacao.py` (só se a URL `file://` não funcionar: aceitar caminho local)
- `.github/workflows/forja.yml` (um passo no job `linux` que roda a prova nova)

## Passos

1. Rodar `kenney.py --prova` com `HOME` apontando para uma pasta vazia; se depender do pacote, a prova pula a parte
   do pacote e diz `pulado: sem o pacote`.
2. A prova do baixador: um zip feito na hora numa pasta temporária, servido por `file://`, com a soma certa (passa)
   e com a soma trocada (sai diferente de 0 e não deixa arquivo).
3. O passo do CI.

## Pronto quando

`bash tests/prova_das_ferramentas.sh` sai 0, e sai 1 quando qualquer das seis falha (conferido trocando a soma
esperada na prova).

## Provas

- `bash tests/prova_das_ferramentas.sh`
- `bash scripts/ci-local.sh --rapido`

## O que foi feito (leva 1, a-varredura)

- Medido antes: `kenney.py --prova` com `FORJA_OFICINA` (é ela, não o `HOME`, que diz onde está o pacote)
  apontando para uma pasta vazia já passa e diz «sem o pacote baixado, a prova conferiu só as partes puras»: não
  depende do pacote, e ficou como está. O baixador dos modelos não abria `file://` («o servidor do pacote não aceita
  pedidos por pedaço»): o `HEAD` do `file://` não responde `Accept-Ranges`.
- `scripts/modelos_de_exportacao.py`: um caminho local (ou `file://`) abre o arquivo direto; a URL remota segue por
  pedaços, como antes.
- `tests/prova_das_ferramentas.sh` (nova): as cinco `--prova` (kenney, mapa_de_batidas, trilha_fichas,
  gerar_trilha, descrever_trilha) e o baixador com um pacote feito na hora: a soma certa passa e os dois modelos
  saem com o conteúdo do pacote; a soma trocada sai 1, diz as duas somas e não deixa arquivo. O
  `bancada_tui.py` fica fora, com a razão escrita no começo da prova. Com nomes na linha de comando, roda só
  aquelas (para triar).
- O CI: o passo «A prova das ferramentas» no job `linux`, logo depois do `make all`.
- A régua morde: trocar a soma esperada do caso certo dá «2 de 5 casos falharam» e sai 1; tirar a conferência da
  soma do baixador reprova a recusa, a razão e o «não deixa arquivo»; uma `--prova` que falha (o mapa de batidas
  forçado a falhar) sai 1.
- Rodado na máquina: `kenney`, `mapa_de_batidas` e `baixador` (7 casos verdes); as três da trilha não rodaram
  direto aqui, porque a leva deixou a geração de música fora deste trabalho. A rodada inteira aconteceu dentro do
  container do `bash scripts/ci-local.sh --rapido` (o passo novo do job `linux`): «prova das ferramentas ok — 10
  casos», em 9 s, sem placa e sem rede de modelo. O `--rapido` saiu com os três jobs verdes (windows, portoes,
  linux).
- Conferido: a prova inteira, num container da imagem do CI sem rede, dá 10 casos verdes e deixa a árvore limpa;
  cada uma das cinco `--prova` forçada a falhar faz a prova sair 1, e um baixador que grava antes de conferir a
  soma reprova o «não deixa arquivo». Fica sem prova o caminho remoto do baixador (o `PacoteRemoto`, por
  pedaços), que é o que a exportação usa: a prova cobre a conferência da soma, não o download.
