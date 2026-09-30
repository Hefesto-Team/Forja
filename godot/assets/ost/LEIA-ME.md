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
