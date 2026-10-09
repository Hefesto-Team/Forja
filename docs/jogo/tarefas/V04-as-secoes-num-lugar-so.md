# V04 — As seções num lugar só

**Sprint:** V · **Tamanho:** M · **Depende de:** H04, H08, F09

## Por quê

A lista das seções está escrita em sete constantes de quatro arquivos, cada uma com um pedaço (nome, ícone, faixa, ordem, portão): a
seção nova da I a Q precisa lembrar das sete, e o que esquece vira um portão sem música ou uma partida sem nome.

## Ler antes

- [H04 — O kit do minigame](H04-o-kit-do-minigame.md) (o `Catalogo` nasce lá)
- [H08 — Os acréscimos do kit](H08-os-acrescimos-do-kit.md#o-estado-de-hoje) (a partida passa a falar por apelido)
- [03 — Os 45 minigames](../03-os-45-minigames.md)

## O estado de hoje

- `godot/scripts/main.gd:13-24` `SALAS` (id → script) e `:27` `ORDEM_DO_FOGO` (a ordem do percurso).
- `godot/scripts/musica.gd:11-24` `FAIXAS` (id → tônica, bpm, energia) e `:31` `SALA_DA_SECAO` (S01..S09 → id).
- `godot/scripts/partida.gd:22-25` `NA_ORDEM` e `:26-28` `NOMES` («A Centelha», «A Viga»…).
- `godot/scripts/mundo/salao.gd:15-24` `PORTOES`: de novo o nome, a seção («Seção 1»), o ícone, a parede.
- Os nomes aparecem iguais em `partida.gd` e `salao.gd`; a ordem «centelha, viga, molde, impacto, galeria, canto,
  caminhos, voz, prova» aparece em `main.gd:27` e `musica.gd:31`.

## O alvo

`Catalogo.SECOES` (da H04) é o dono de cada seção: `id`, `nome`, `numero`, `icone`, `apelido`, `faixa_sintetizada`
(`[tônica, bpm, energia]`), `portao` (`{lado, t}`), `minigames`. Os outros leem:

- `main.gd` monta `ORDEM_DO_FOGO` a partir de `Catalogo.SECOES` (a ordem do número);
- `musica.gd` lê a faixa sintetizada e o `SALA_DA_SECAO` sai;
- `partida.gd` pede o nome a `Catalogo.nome(id)`;
- `salao.gd` monta os portões de `Catalogo.SECOES` (o `aberta` vira «tem minigame no catálogo»).

As entradas que não são seção (`salao`, `podio`, `bancada` em `FAIXAS`) ficam onde estão.

## Arquivos que mudam

- `godot/scripts/minigames/catalogo.gd` (de todos: as seções I a Q acrescentam minigames nele)
- `godot/scripts/main.gd`, `godot/scripts/musica.gd`, `godot/scripts/partida.gd`, `godot/scripts/mundo/salao.gd`
- `godot/testes/prova_do_jogo.gd` (ou `checagens/sistema_catalogo.gd`, se a V02 já entrou)

## Passos

1. Acrescentar os campos a `Catalogo.SECOES`, com os valores de hoje copiados dos quatro arquivos.
2. Trocar cada leitura, um arquivo por vez, rodando a prova do jogo entre um e outro.
3. Apagar as constantes que ficaram sem uso.
4. A prova confere: cada seção do catálogo tem nome, ícone, faixa e portão, e nenhum id de `FAIXAS` repete uma seção.

## Pronto quando

`git grep -n '"A Centelha"' godot/scripts` acha uma linha só, em `catalogo.gd`.

## Provas

- `bash tests/prova_do_jogo.sh`
- `bash tests/prova_de_poucos.sh`
- `bash tests/prova_visual.sh` (o salão com os portões no lugar; a prancha do salão olhada)
