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

- **De onde vêm:** as faixas são geradas no Suno, no plano Premier, e
  baixadas enquanto a assinatura está ativa. É o download feito com a
  assinatura que dá o direito de uso, e esse direito continua depois de
  cancelar.
- **A licença:** é a licença de uso do Suno, **não é CC0** como o resto dos
  assets. As faixas servem ao Forja e não se reaproveitam fora dele. Música
  feita só por IA não tem direito autoral: ninguém é dono dela, nem o Forja.
- **O comprovante** (o e-mail ou a fatura do mês da assinatura) fica com o
  André, fora do repositório.
- **A origem não aparece no jogo:** nem nos créditos, nem na tela. Ela fica
  só aqui e em
  [LICENCAS-DE-TERCEIROS.md](../../../LICENCAS-DE-TERCEIROS.md).

## Como gerar

O prompt segue o estilo dos da tabela
([as quatro novas](../../../docs/jogo/04-ritmo-e-audio.md#as-quatro-novas)):
em inglês, o gênero primeiro, os marcadores de estrutura entre colchetes.
Toda faixa leva:

- `instrumental` no começo e `no vocals` no fim (a Voz e o Canto precisam
  do espaço para a voz de quem joga);
- o BPM e o tom da tabela, escritos (`122 BPM, F minor`);
- `steady tempo, strict grid`: o andamento não pode escorregar (o mapa de
  batidas aponta a faixa cujo tempo se afasta mais de 10 ms da grade do
  começo);
- `hard start on the downbeat, no fade-in`, e no fim `ends with a hard stop,
  no fade-out`;
- nos minigames, **pelo menos 2 minutos** de faixa (o jogo usa 90 s, mais a
  entrada e folga; o `conferir_ost.py` exige 120 s).

O molde:

```
instrumental, <gênero da seção>, 122 BPM, F minor, steady tempo, strict grid.
<o clima da tabela, em inglês>. [Intro] 4 bars, hard start on the downbeat.
[Verse] ... [Drop] ... [Outro] ends with a hard stop, no fade-out. No vocals.
```

**O fluxo, para não gastar download:**

1. Uma seção inteira primeiro (as 5 faixas da S01), com o mesmo gênero e o
   mesmo timbre de base, para a seção ter uma cara só.
2. Ouvir no site e escolher. Baixar **só a aprovada**, sempre em **WAV**
   (nunca converter a partir do MP3). O Premier dá 60 downloads no mês, e as
   faixas são umas 60: a 45, as 6 das telas e os 8 jingles.
3. Converter, gerar o mapa e conferir com o metrônomo (a
   [ficha H05](../../../docs/jogo/tarefas/H05-o-pipeline-das-faixas.md#para-o-andré-local)
   tem os comandos). Se a S01 passar, o molde está certo e o resto segue
   igual.
