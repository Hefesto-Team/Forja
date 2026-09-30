# H09 — O gerador da trilha

**Sprint:** H · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5 · **Depende de:** F00, H05 (o `mapa_de_batidas.py` e o `Musica.caminho`)

## Por quê

A trilha inteira (45 faixas, 6 telas e 4 jingles) sai de um script, na
máquina do André, com um modelo aberto: o **ACE-Step 1.5** (licença MIT).
Sem assinatura, sem limite de download, sem termo de serviço de empresa, e
com o BPM e o tom **como parâmetro** do motor, não como pedido no texto. O
script gera algumas candidatas por faixa, descarta a que escorrega o
andamento e deixa o André só ouvir e escolher. Decisão do André (30/09): a
geração roda no desktop dele (RTX 4060, 8 GB de vídeo, Pop!_OS 24.04), nunca
na nuvem e nunca no notebook.

## Ler antes

- [O LEIA-ME da trilha](../../../godot/assets/ost/LEIA-ME.md) (os nomes, o formato, a origem e o uso)
- [As 45 faixas](../04-ritmo-e-audio.md#as-45-faixas) e [as telas e os jingles](../04-ritmo-e-audio.md#as-telas-e-os-jingles)
- [H05](H05-o-pipeline-das-faixas.md): "O alvo" (o mapa de batidas) e "Para o André"

## O estado de hoje

- **Os prompts já estão prontos** em `scripts/trilha_prompts.json`, tirados
  da pesquisa de áudio e da tabela do 04: `faixas` tem 55 slots
  (`MUS_S01_J01` … `MUS_S09_J45`, os seis `MUS_TELA_*`/`MUS_RELAMPAGO`, e
  `JIN_VITORIA`, `JIN_DERROTA`, `JIN_EMPATE`, `JIN_RECORDE`). Cada um tem
  `bpm`, `tom` (em inglês: `"F minor"`), `duracao_s` (150 nos minigames e nas
  telas, 180 nos créditos, 120 no Relâmpago, 10 nos jingles), `prompt`, e,
  nos jingles, `corte_s`. `sufixo` é o texto que vai no fim de todo prompt.
  Os outros quatro jingles (`JIN_APITO`, `JIN_COOP_VITORIA`, `JIN_ENTRADA`,
  `JIN_VIRADA`) **não** são desta ficha: saem da H06.
- `scripts/mapa_de_batidas.py` (H05): `ler_wav(caminho) -> (amostras, taxa)`
  (WAV de 16 bits), `ler_com_ffmpeg(caminho)`, `mapear(amostras, taxa, bpm)`
  → `{"bpm", "primeiro_tempo_s", "compassos", "escorrega_ms"}`,
  `escrever(slot, mapa, saida)` (o `.batidas.json`, com `"conferido": false`),
  `cliques(bpm, primeiro_s, segundos)` (uma faixa de mentira) e
  `ESCORREGA_MS = 10.0`.
- O ACE-Step 1.5 (<https://github.com/ace-step/ACE-Step-1.5>) tem um servidor
  local de API (`python -m acestep.api_server`, porta padrão 8001, confira no
  `--help` da versão instalada):
  - `POST /release_task` → `{"task_id": ...}`;
  - `POST /query_result` com o `task_id` → `status` 0 (na fila), 1 (pronto),
    2 (falhou), e em `result` o `file` (o caminho para `GET /v1/audio`) e o
    `seed_value`;
  - os campos do pedido: `caption` (ou `prompt`), `lyrics`, `bpm`,
    `key_scale`, `time_signature`, `audio_duration`, `inference_steps`,
    `seed`, `batch_size` (até 8), `audio_format` (`"wav"`).
  Instrumental: `lyrics` = `"[Instrumental]"`. **Os nomes exatos se conferem
  na versão instalada** (o servidor é FastAPI: `http://127.0.0.1:8001/docs`);
  se algum mudou, só o `MotorAceStep` muda.
- A nuvem não tem placa de vídeo, nem o ACE-Step, nem `ffmpeg`: **a sessão
  prova tudo com um motor de mentira**; o motor de verdade é do André.

## O alvo

`scripts/gerar_trilha.py`, Python 3, só a biblioteca padrão (`urllib`,
`json`, `wave`, `subprocess`, `pathlib`, `argparse`, `html`):

```
python3 scripts/gerar_trilha.py gerar S01               # as 5 faixas da seção, 4 candidatas cada
python3 scripts/gerar_trilha.py gerar MUS_TELA_TITULO -n 6
python3 scripts/gerar_trilha.py gerar tudo              # os 55 slots
python3 scripts/gerar_trilha.py ouvir                   # abre a página de escuta
python3 scripts/gerar_trilha.py escolher MUS_S01_J01 2  # a candidata 2 vira a faixa do jogo
python3 scripts/gerar_trilha.py --prova                 # o fluxo inteiro, com o motor de mentira
```

- **A pasta de trabalho** fica fora do git:
  `$XDG_CACHE_HOME/forja-trilha/` (ou `~/.cache/forja-trilha/`), com
  `<slot>/<n>.wav`, `<slot>/<n>.batidas.json` e `<slot>/<n>.json` (o prompt,
  o motor, a semente, a data). Nenhum caminho fixo no código: `Path.home()`.
- **O motor** é uma classe com um método, `gerar(slot, faixa, n) -> [caminhos .wav]`:
  - `MotorAceStep(url)`: `--url` (padrão `http://127.0.0.1:8001`); o
    caption é `faixa["prompt"] + " " + sufixo`; `bpm`, `key_scale`
    (`"F minor"` → `"F Minor"`), `time_signature` `"4"`, `audio_duration` =
    `duracao_s`, `batch_size` = `n`, `audio_format` `"wav"`, `lyrics`
    `"[Instrumental]"`, semente aleatória (e guardada). Consulta o
    `/query_result` a cada 2 s, com `timeout=30` em todo pedido, e desiste
    em 10 minutos por slot com uma frase clara.
  - `MotorFalso()`: devolve WAVs de cliques no BPM do slot (o `cliques()` da
    H05), a candidata 1 certa e a 2 escorregando (tocada a `bpm * 1.003`).
    É o que a prova usa.
  - (A API do Lyria fica de fora. Se um dia o ACE-Step não servir, uma ficha
    nova acrescenta `MotorLyria` com a chave em variável de ambiente.)
- **Depois de gerar cada candidata:**
  1. Se não é WAV de 16 bits a 48 kHz, converte com
     `ffmpeg -ar 48000 -sample_fmt s16` (sem `ffmpeg`, diz
     `sudo apt install ffmpeg` e para).
  2. Roda o `mapear()` com o BPM do slot, grava o `.batidas.json` e acrescenta
     `"motor": "ace-step-1.5"`.
  3. Marca a candidata como **escorrega** se algum `escorrega_ms` passa de
     `ESCORREGA_MS`. Ela fica na pasta, mas a página a mostra riscada.
- **Os jingles:** depois de gerar, corta em `corte_s` arredondado para o fim
  do compasso (`4 * 60 / bpm`), com uma rampa de 5 ms no fim para não
  estalar, e **não** gera mapa (o jingle não tem batida a seguir).
- **`ouvir`:** escreve `index.html` na pasta de trabalho, uma seção por slot
  e um `<audio controls>` por candidata, com o prompt, a semente, o
  primeiro tempo e o pior `escorrega_ms`, e o comando
  `escolher <slot> <n>` pronto para copiar. Abre com `xdg-open`.
- **`escolher SLOT N`:** converte a candidata para OGG Vorbis 48 kHz estéreo
  (`ffmpeg -c:a libvorbis -q:a 6`) no caminho que o `Musica.caminho(slot)` da
  H05 espera (`godot/assets/ost/S01/MUS_S01_J01.ogg`, `telas/`, `jingles/`) e
  copia o `.batidas.json` ao lado (menos nos jingles). O `"conferido"`
  continua `false`: só o André o vira, depois do metrônomo da H05.
- **`--prova`**, sem rede e sem placa de vídeo, confere:
  1. lê os 55 slots do JSON, e todo slot tem `bpm`, `tom`, `duracao_s` e
     `prompt`;
  2. o `MotorFalso` gera duas candidatas de `MUS_S01_J01`: a 1 passa e a 2 é
     apontada como escorrega;
  3. a página tem as duas, com a 2 riscada;
  4. o `escolher` põe a faixa e o mapa no caminho certo, numa cópia
     temporária da pasta `ost/`, nunca na de verdade; sem `ffmpeg`, a prova
     confere só o caminho e o mapa;
  5. o jingle de mentira é cortado no compasso.

## Passos

1. Ler `scripts/trilha_prompts.json` e o `scripts/mapa_de_batidas.py`
   (importado: `sys.path.insert(0, str(Path(__file__).parent))`).
2. Escrever `scripts/gerar_trilha.py` com os dois motores, `gerar`, `ouvir`,
   `escolher` e `--prova`, como em "O alvo".
3. `python3 scripts/gerar_trilha.py --prova` verde na sessão.
4. No `godot/assets/ost/LEIA-ME.md`, seção "Como gerar": trocar o bloco
   "O fluxo" pelos comandos acima, sem mexer em "A origem e o uso".
5. Em `docs/DESENVOLVER.md`, uma seção curta "A trilha", com a instalação do
   ACE-Step (abaixo) e os quatro comandos.
6. `bash tests/prova_do_jogo.sh` continua verde (nada do jogo mudou).

## Armadilhas

- **O modelo XL do ACE-Step não cabe** nos 8 GB da 4060 (pede 12 GB ou mais).
  Use o turbo ou o base; o script não escolhe modelo, quem escolhe é o
  servidor.
- **A faixa de IA pode começar com silêncio ou ruído:** o `mapear()` acha o
  primeiro tempo nos primeiros 8 s. Se a candidata começa depois, ela sai
  riscada; não se corta o começo à mão.
- **Não sobrescrever** uma faixa que já está em `godot/assets/ost/`: o
  `escolher` pergunta antes (ou pede `--forcar`).
- **A pasta de trabalho cresce:** 55 slots × 4 candidatas × 150 s de WAV dá
  uns 6 GB. O `gerar` avisa o tamanho no fim.
- **A semente vai no `.json` da candidata:** assim uma faixa boa pode ser
  refeita com outro tamanho.

## Não fazer

- Não commitar nada da pasta de trabalho, nem WAV no repositório.
- Não pôr chave, endereço ou caminho de máquina no código.
- Não virar `"conferido": true` pelo script.

## Pronto quando

`python3 scripts/gerar_trilha.py --prova` passa na sessão, e o André gera a
S01 na máquina dele, ouve na página, escolhe as cinco e elas tocam no jogo
com o mapa conferido pelo metrônomo da H05.

## Provas

- Na sessão: `python3 scripts/gerar_trilha.py --prova` e
  `bash tests/prova_do_jogo.sh`.
- Com o André, local: a S01 inteira (abaixo).

## Para o André (local)

Uma vez, no desktop:

```bash
sudo apt install ffmpeg
git clone https://github.com/ace-step/ACE-Step-1.5 ~/ace-step
cd ~/ace-step            # siga o INSTALL do projeto (ele usa ambiente virtual próprio)
python -m acestep.api_server        # deixe rodando num terminal
```

Depois, noutro terminal, na pasta do Forja:

```bash
python3 scripts/gerar_trilha.py gerar S01
python3 scripts/gerar_trilha.py ouvir          # escute, escolha
python3 scripts/gerar_trilha.py escolher MUS_S01_J01 2    # e as outras quatro
# o mapa de cada uma, pelo metrônomo da H05 ("Para o André" dela), e então:
bash tests/prova_do_jogo.sh
./run-local.sh -- --sala=centelha
```

Diga: quantas das 20 candidatas saíram riscadas, quanto tempo levou cada
faixa na 4060, e se a S01 soa como uma seção só. Se o timbre variar demais
entre as cinco, anote qual e a próxima sessão mexe no prompt dela no
`trilha_prompts.json`.

## Ao terminar

Marcar H09 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `feat: o gerador da trilha, com o ACE-Step e a página de escuta`.
