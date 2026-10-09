# O mapa do áudio

Todo som e toda música da Forja num lugar só. Cada linha tem um id, e é pelo id que a ficha pede o som: nenhuma ficha
toca um som que não está aqui. O dono do mapa é o diretor de som e háptica ([papéis](papeis.md#o-diretor-de-som-e-háptica)).

A tabela mora em `docs/jogo/audio/mapa.csv`, para os portões lerem. Esta página explica as colunas.

## As colunas

| coluna | o que é | exemplo |
| --- | --- | --- |
| `id` | o nome único, em minúsculas; o prefixo diz a família de arquivo (o [03](../arte/03-som.md#o-formato)) | `fx_vitoria_p2`, `jul_ressonancia_p1`, `mus_s01_j02` |
| `tipo` | `sfx`, `stinger`, `assinatura`, `ambiente`, `ui`, `musica` | `stinger` |
| `familia` | a família da [bíblia de som](../arte/03-som.md#as-famílias) | `fita`, `metal`, `voz` |
| `onde_toca` | `tv`, `controle` (o alto-falante do controle), `atuadores` (a háptica por áudio), juntos por `+` | `tv+controle` |
| `evento` | o que dispara | `o vencedor aparece no pódio` |
| `fichas` | as fichas que usam, separadas por espaço | `G04 F03` |
| `receita` | o script e os parâmetros que geram o arquivo; nos sons do módulo, a receita de síntese | `godot/estudos/direcao/som/gerar_sons.py --so fx_vitoria_p2 --lugar 2 --fita cheia` |
| `duracao_ms` | a duração alvo | `1000` |
| `pico_dbfs` | o pico máximo | `-1` |
| `haptica` | a vibração ou o gatilho que acompanha, se há | `pulso duplo, motor direito, 120 ms` |
| `arquivo` | o caminho no jogo, ou `(módulo)` para o som sintetizado em tempo real | `godot/assets/sons/fx_vitoria_p2.wav` |
| `estado` | `a fazer`, `gerado`, `conferido`, `no jogo` | `gerado` |

## Os sons

Gerados por síntese e tratamento por script, com o tratamento de fita da bíblia, ou gravações CC0 da Kenney convertidas
por script (a receita diz o arquivo de origem). Nenhum é gerado por modelo de IA. Os sons sintetizados em tempo real
(`sint_*` na TV, `mod_*` no controle) não têm arquivo: a receita aponta o nome e os parâmetros no código.

Um portão confere, para cada linha com arquivo e estado `gerado`, `conferido` ou `no jogo`, que o arquivo existe, que
a duração e o pico batem e que não há clique no começo nem no fim (`gerar_sons.py --conferir`). As linhas
`(módulo)` conferem pelo nome no código.

## A música

Uma faixa por minigame (`mus_<slot>`), mais as do título, do salão, da montagem do cavaleiro, do pódio e dos
créditos. Cada faixa é gerada uma por vez, seguindo a linha dela no mapa (o andamento, o tom, a família, o que a
bíblia de som pede para a seção) e o pipeline das faixas
([H05](../tarefas/H05-o-pipeline-das-faixas.md), [H09](../tarefas/H09-o-gerador-da-trilha.md)).

- A geração é mecânica: roda por script, só quando a placa de vídeo está livre, nunca junto com outra coisa pesada.
- Enquanto a faixa não existe, o minigame toca a trilha sintetizada da seção, e o jogo funciona inteiro sem música
  gerada.
- A conferência é por medida (andamento, volume, duração, o encaixe da batida no relógio do jogo); o ouvido é dela,
  no fim de cada seção.
