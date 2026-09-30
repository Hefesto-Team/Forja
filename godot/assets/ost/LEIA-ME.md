# A trilha do Forja

As músicas do jogo, dentro do repositório. A tabela das 45 faixas (BPM, tom,
clima e o minigame de cada uma) está em
[docs/jogo/04-ritmo-e-audio.md](../../../docs/jogo/04-ritmo-e-audio.md#as-45-faixas).

## Onde vai cada arquivo

| pasta | o quê | nome |
| --- | --- | --- |
| `S01/` … `S09/` | as faixas dos cinco minigames de cada seção | `MUS_Sxx_Jyy.ogg`, com o mapa `MUS_Sxx_Jyy.batidas.json` ao lado |
| `telas/` | título, construção, salão, pódio, créditos, Relâmpago | `MUS_TELA_TITULO.ogg`, `MUS_TELA_CONSTRUCAO.ogg`, `MUS_TELA_SALAO.ogg`, `MUS_TELA_PODIO.ogg`, `MUS_TELA_CREDITOS.ogg`, `MUS_RELAMPAGO.ogg` |
| `jingles/` | os fins, a contagem, a virada | `JIN_APITO.ogg`, `JIN_VITORIA.ogg`, `JIN_COOP_VITORIA.ogg`, `JIN_DERROTA.ogg`, `JIN_EMPATE.ogg`, `JIN_RECORDE.ogg`, `JIN_ENTRADA.ogg`, `JIN_VIRADA.ogg` |

Exemplo: a faixa d'O Martelo de Hefesto é `S01/MUS_S01_J01.ogg`.

## O formato

- **OGG Vorbis, 48 kHz, estéreo.** Nunca MP3: o silêncio que o MP3 põe no
  começo e no fim quebra o laço e o tempo.
- O mapa de batidas (`.batidas.json`) diz o BPM, o instante do primeiro tempo,
  os compassos e as seções. Faixa gerada por IA pode escorregar o andamento:
  o mapa é conferido de ouvido antes de a faixa entrar (a ficha H05 explica).
- Sem faixa na pasta, o jogo toca a trilha sintetizada de hoje: dá para
  jogar antes de todas as músicas existirem.

## Antes de commitar

Cada versão de uma música fica **para sempre** no histórico do git. Por isso:
só entra faixa aprovada, ouvida no jogo; rascunho e geração descartada ficam
fora do repositório.

## A origem e o uso

- **De onde vêm:** as faixas são geradas na máquina do André com o
  **ACE-Step 1.5**, um modelo de música aberto (licença MIT), a partir dos
  prompts de `scripts/trilha_prompts.json` (tirados da tabela do
  [04](../../../docs/jogo/04-ritmo-e-audio.md#as-45-faixas)). O script é o
  `scripts/gerar_trilha.py`
  ([ficha H09](../../../docs/jogo/tarefas/H09-o-gerador-da-trilha.md)).
  Não há serviço pago, assinatura nem termo de uso de empresa no meio.
- **O direito:** música feita por IA não tem autor pela lei (no Brasil e nos
  EUA, só pessoa é autora), então ninguém é dono dela: nem o Forja, nem o
  ACE-Step. As faixas seguem com o jogo e com a licença do repositório; o
  que é nosso de verdade é a escolha, os prompts e o jogo em volta.
- **Cada faixa diz de onde veio:** o `.batidas.json` leva `"motor"`
  (`"ace-step-1.5"`). Se alguma faixa um dia vier de outro motor, o nome dele
  vai ali e a licença dele entra em
  [LICENCAS-DE-TERCEIROS.md](../../../LICENCAS-DE-TERCEIROS.md).
- **A origem não aparece no jogo:** nem nos créditos, nem na tela.

## Como gerar

Com o servidor do ACE-Step rodando no desktop (a H09 diz como instalar):

```bash
python3 scripts/gerar_trilha.py gerar S01                 # 4 candidatas de cada faixa da seção
python3 scripts/gerar_trilha.py ouvir                     # a página para escutar e escolher
python3 scripts/gerar_trilha.py escolher MUS_S01_J01 2    # a escolhida vira a faixa do jogo
```

- O BPM, o tom e a duração vão como parâmetro do motor; o prompt, só com o
  estilo. Todo prompt termina com o `sufixo` do JSON: tempo firme, começo
  seco, fim seco.
- A candidata cujo andamento escorrega mais de 10 ms da grade do começo sai
  riscada na página.
- **Uma seção por vez**, a S01 primeiro: se as cinco soam como uma seção só
  e o metrônomo concorda, o resto segue igual. Prompt que não serviu se
  ajusta no `trilha_prompts.json`, no mesmo commit da faixa.
- Nos minigames, a faixa tem pelo menos 2 minutos (o `conferir_ost.py` exige
  120 s); o JSON já pede 150.
