# H10 — A bancada da trilha

**Sprint:** H · **Tamanho:** M · **Estimativa:** US$ 3,0 · **Depende de:** H05 (o `mapa_de_batidas.py`), H09 (o `gerar_trilha.py`)

## Onde a trilha está (03/10/2026)

Aferido no disco, não de cabeça. A ordem de trabalho é esta, de cima para
baixo: nada se gera sem descrição, nada se escolhe sem candidata.

| etapa | onde está | como se mede |
| --- | --- | --- |
| descrever as 55 | **5 de 55** | `scripts/trilha_prompts.json`, as que têm `titulo` e `prompt` |
| gerar as candidatas | **4 slots** (`MUS_S01_J01` a `J03`, `JIN_RECORDE`) | `oficina/trilha/<slot>/*.wav` |
| escolher e aprovar | **0 de 55** | `godot/assets/ost/**/*.ogg` |

**A decisão de 03/10:** descrever e gerar **as 55 primeiro**, e só depois
sentar para escolher. O ouvido cansa; a máquina não.

**O próximo passo**, nesta ordem, com a tela aberta (`./run.sh` → A trilha):

1. **As palavras** — o Ollama escreve os 50 títulos e descrições que faltam.
   Ele recusa título repetido entre os 55, então quanto mais escrito, mais
   devagar fica o fim da fila. Uns 20 minutos.
2. **O servidor** — `./run.sh servidor` noutra janela, e deixe lá. O modelo
   de texto tem de estar descarregado antes: os dois não cabem nos 8 GB.
3. **A geração** — medido: uma faixa de 150 s sai em 14 s, quatro candidatas
   por slot. As 55 dão cerca de **50 minutos** de placa.
4. **A escolha** — aí sim, de ouvido, pela tela.

O gasto de placa é todo em (1) e (3), e nunca nos dois ao mesmo tempo.

## Por quê

A H09 entregou o gerador, e ele funciona por linha de comando. Mas a trilha
são 55 slots, cada um com quatro candidatas de dois minutos e meio: gerar
tudo é uma noite de máquina, e escolher é uma noite de ouvido. Três coisas
faltavam:

1. **As faixas não tinham nome nem descrição.** Na hora de escolher entre
   quatro candidatas de `MUS_S07_J33`, ninguém lembra que faixa é essa. Um
   modelo de texto local lê a ficha do minigame nos documentos do jogo e
   escreve o título e a descrição de cada faixa, em português.
2. **Dois modelos não cabem na placa.** O de texto e o ACE-Step juntos
   estouram os 8 GB. Quem conduz tem de garantir que só um esteja carregado
   de cada vez, e devolver a memória ao sair.
3. **A linha de comando não deixa mudar de ideia no meio.** Escutando uma
   candidata, dá vontade de pedir mais quatro, de refazer a descrição, de
   caprichar mais. Isso é botão, não argumento.

## Ler antes

- [H09](H09-o-gerador-da-trilha.md) (o motor, a pasta de trabalho, a página de escuta)
- [O LEIA-ME da trilha](../../../godot/assets/ost/LEIA-ME.md)
- [As 45 faixas](../04-ritmo-e-audio.md#as-45-faixas)
- [ADR-008](../../adr/008-a-metodologia-astro-bot.md) (a regra de que o som do jogador é parte da música)

## A regra Rhythm Heaven

Decisão de 02/10/2026: boa parte do FORJA é dinâmica de som — como no
*Rhythm Heaven* da Nintendo, **o que o jogador faz é uma nota do arranjo**.
Quatro pessoas tocam por cima da faixa ao mesmo tempo, cada uma com o som
dela saindo do alto-falante do próprio controle. Então a faixa gerada tem de
deixar lugar:

- **um buraco rítmico** nos contratempos, onde a martelada entra;
- **um buraco de frequência** de uns 800 Hz a 4 kHz, onde moram as
  marteladas, os cliques e os sinos — o peso vai para o grave;
- **sem modulação**: a faixa fica no tom pedido do começo ao fim, para o som
  do jogador soar afinado com ela.

Isso está no `sufixo` de `scripts/trilha_prompts.json` (vai no fim de todo
prompt) e no texto de sistema de `scripts/descrever_trilha.py`. E o
`.batidas.json` passa a levar `tom` e `titulo`, porque quem sintetiza a
martelada precisa saber em que tom afinar.

## O alvo

Quatro arquivos novos em `scripts/`, e um ambiente que se instala e se
desinstala inteiro.

**`scripts/trilha_fichas.py`** — a ficha de cada faixa, lida dos documentos
do jogo (não de uma cópia): a seção, o recurso que a seção protagoniza, o
minigame, o verbo da tela, como se joga, como se falha, como termina; para
as telas, onde tocam; para os jingles, o momento. `--prova` confere que os
55 slots acharam ficha e que `MUS_S01_J01` é O Martelo de Hefesto.

**`scripts/descrever_trilha.py`** — o título e a descrição, por um modelo de
texto local (Ollama, `qwen3:8b` por padrão):

- grava **slot a slot** no `trilha_prompts.json`: parar no meio não perde nada;
- confere a resposta e manda refazer até três vezes — o título tem de ter de
  duas a cinco palavras, a descrição mais de vinte, e o `prompt` tem de vir
  **em inglês** e **sem BPM** (o BPM vai como parâmetro do motor);
- **devolve a placa no fim**, sempre (`keep_alive: 0` e o processo encerrado),
  mesmo se der erro: é isso que deixa a memória livre para o ACE-Step;
- `--prova` roda sem rede e sem placa, e devolve o `trilha_prompts.json`
  exatamente como estava.

**`scripts/trilha_tui.py`** — a tela do terminal, em Textual: os 55 slots à
esquerda com o estado de cada um; à direita a ficha, o título, a descrição, o
prompt e as candidatas com o andamento; embaixo a memória da placa e os
botões — Descrever, Gerar, Mais esforço, Refazer, Escolher, Ouvir, Soltar a
placa. O esforço tem quatro degraus (leve, normal, caprichado, teimoso), que
mudam juntos o número de candidatas, os passos do ACE-Step e o quanto o
modelo de texto arrisca. **Antes de gerar som, a tela descarrega o modelo de
texto**, sem perguntar. Ao sair, solta os dois e diz quanta memória voltou.

**`scripts/trilha_ambiente.sh`** — `instalar`, `modelo`, `tela`, `estado`,
`soltar`, `desinstalar`. O Ollama entra como arquivo em `oficina/ollama/`,
não como serviço do sistema: **nada pede senha**. Os pesos vão para
`oficina/modelos/`, e o `desinstalar` leva tudo embora.

**`scripts/requisitos-trilha.txt`** — só o Textual. O gerador e o descritor
continuam com a biblioteca padrão: é o que deixa as provas passarem em
qualquer máquina.

## Armadilhas

- **A API do ACE-Step muda de versão.** Na instalada (02/10/2026) as rotas
  `/release_task`, `/query_result` e `/v1/audio` existem como a H09 descreveu;
  se mudarem, só o `MotorAceStep` muda.
- **O modelo de texto responde em português quando não devia.** O `prompt`
  do ACE-Step tem de ser inglês; o `conferir()` pega e manda refazer.
- **O `qwen3` pensa antes de responder** (`<think>…</think>`): o `_ler()`
  tira isso antes do JSON.
- **Nunca os dois modelos juntos.** Em 8 GB não cabe. Quem gera som primeiro
  solta o texto.
- **A pasta de trabalho é `oficina/trilha/`**, dentro do projeto e fora do
  git. 55 slots × 4 candidatas dão uns 6 GB.
- **Não commitar** WAV, MP3, pesos de modelo nem nada de `oficina/`.

## Não fazer

- Não pôr o MP3 dentro de `godot/assets/ost/`: o jogo nunca toca MP3 (o
  LEIA-ME da trilha). A cópia em MP3 é só para ouvir fora do jogo, e mora em
  `oficina/trilha/mp3/`.
- Não virar `"conferido": true` pela tela: isso é do ouvido, com o metrônomo
  da H01.
- Não instalar nada com `sudo` neste caminho.

## Pronto quando

`scripts/trilha_ambiente.sh instalar` deixa a máquina pronta sem pedir senha;
a tela abre, lista os 55 slots, descreve uma seção, gera as candidatas dela,
deixa escolher ouvindo, e ao sair diz quanta memória da placa voltou.

## Provas

Na sessão, as quatro, todas sem rede e sem placa:

```bash
python3 scripts/trilha_fichas.py --prova
python3 scripts/descrever_trilha.py --prova
python3 scripts/gerar_trilha.py --prova
FORJA_TRILHA_PROVA=1 oficina/trilha-venv/bin/python scripts/trilha_tui.py
```

## Ao terminar

Marcar H10 como **feito** no [quadro](README.md). Commit sugerido:
`feat: a bancada da trilha — título, descrição e a tela do terminal`
