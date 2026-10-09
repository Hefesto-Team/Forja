# WS06 — O mapa diz onde o som toca

**Sprint:** W · **Tamanho:** P · **Depende de:** V08

## Por quê

O mapa do áudio é a fonte que o time lê para saber o que existe e onde soa. Hoje ele erra nos dois sentidos: sons que
já tocam no controle aparecem como «só TV», sons que já estão no jogo aparecem como «a fazer», e o pio de quem entra
(o som que toda partida começa tocando) nem tem linha. Quem for trocar um desses sons pelo mapa (a direção de arte,
o André) mexe no lugar errado ou acha que falta fazer o que já está feito.

A causa: as colunas `onde_toca` e `estado` são escritas à mão e nenhum portão as confere. O portão de som
(`scripts/portoes/som.py`) só confere se o id tocado existe e se o arquivo bate com a duração e o pico.

## Ler antes

- `docs/jogo/o-time/o-mapa-do-audio.md:15` (o que `onde_toca` aceita: `tv`, `controle`, `atuadores`, juntos por `+`).
- [V08 — Os portões de arte e som reprovam](V08-os-portoes-de-arte-e-som-reprovam.md) (o `som.py` lendo o mapa como é
  escrito).

## O estado de hoje

- `onde_toca=tv` em sons que também tocam no alto-falante do controle:
  - `sino_0`..`sino_4` (`docs/jogo/audio/mapa.csv:51-55`): `Som.no_controle(l, "sino_viga", 0.6)` em
    `godot/scripts/salas/viga.gd:419`;
  - `pedra_0`..`pedra_4` (`mapa.csv:39-43`): `Som.no_controle(l, "pedra" if e.golpes >= 2 else "martelo", 0.7)` em
    `viga.gd:458` (o `martelo_*`, `mapa.csv:29-33`, já diz `tv+controle`);
  - `vitoria_noite_0` (`mapa.csv:70`): `Som.no_controle(l, "vitoria_noite", 0.8)` em `godot/scripts/main.gd:501`.
- `estado=a fazer` em sons que já tocam:
  - `mod_nota_p1`..`p4` e `mod_nota_quebrada_p1`..`p4` (`mapa.csv:100-107`): `Forja.som_falante(l, "nota:%d" % l, 0.8)`
    e `"nota_quebrada:%d"` em `godot/scripts/minigames/minigame.gd:279` e `:270`;
  - `mod_material_*`, as sete (`mapa.csv:120-126`): `Forja.tocar_material`, `godot/scripts/forja.gd:906-914`, chamado em
    `minigame.gd:276`.
- O `mod_coleta` (`mapa.csv:99`) diz «a fazer» e está **certo**: nenhuma chamada de `"coleta"` em `godot/scripts`.
- Falta a linha do pio no módulo: `Forja.som_falante(l, "pio:%d" % jogadores[l].modelo_i, 0.8)` (`main.gd:275`), 12
  pios em `nativo/som/sons_salas.c:51-56` (`sint_pio`, um por boneco) e o nome lido em `:91-93`. As 24 linhas `pio_p*`
  do mapa são as gravadas da direção, um por lugar e intervalo, `estado=gerado`, e nenhuma é o que toca hoje (a H07
  anotou a divergência, `H07-o-som-em-todo-evento.md:990-992`).
- `scripts/portoes/som.json`: as chamadas conferidas são `Som.tocar`, `Som.laco`, `Som.no_controle`, `Som.jingle`,
  `Forja.som_falante` e `Musica.tocar`; o `Forja.tocar_material` não entra, e nenhuma regra lê `onde_toca`.

## O alvo

- O mapa certo hoje: `tv+controle` nas onze linhas; `no jogo` nas quinze; a linha `mod_pio` (o pio do módulo, um por
  boneco, `sint_pio`, `(módulo)`, `no jogo`), com a nota de que os `pio_p*` gravados são a troca prevista.
- O portão confere as duas colunas: um id tocado por `Som.no_controle` ou `Forja.som_falante` exige `controle` no
  `onde_toca` da linha; um id tocado por `Forja.tocar_material` exige `atuadores`; uma linha com `estado` «a fazer» cujo
  id é tocado no código é aviso («já toca, o mapa diz a fazer»).

## Passos

1. Corrigir as 26 linhas e pôr a `mod_pio` no `mapa.csv`.
2. No `som.json`, a chamada `Forja.tocar_material` e, para cada chamada, o lugar que ela exige no `onde_toca`.
3. No `som.py`, as duas conferências, usando a leitura do id que a V08 deixar (o `"nota:%d"` vira `mod_nota_p*` pela
   mesma regra que ela escrever para o `mod_`).
4. Os dois casos novos em `tests/prova_dos_portoes.sh`, ao lado dos de som (`:168-180`).

## Armadilhas

- O material: o `onde_toca` fica `atuadores`, não `atuadores+controle`. Hoje o `tocar_material` também toca o
  alto-falante (`forja.gd:912`), mas a bíblia tira o material do alto-falante e quem tira a chamada é a WS01. O portão
  não pode exigir `controle` por causa do `som_falante(l, nome, …)` de dentro do `tocar_material`, porque o nome ali é
  dinâmico (`"material:" + material`) e já cai como chamada sem literal.
- O `Som.no_controle` toca o mesmo id na TV e no controle: exige `tv+controle`, não só `controle`.
- O `pedra` vem de um ternário: o portão já lê os dois lados (`prova_dos_portoes.sh:179-180`).

## Não fazer

- Não trocar o pio do módulo pelos gravados: é escolha de som, não de mapa.
- Não mexer nas colunas de duração e pico.

## Pronto quando

`python3 scripts/portoes/som.py --raiz . --modo reprova` passa com o mapa corrigido, e reprova numa árvore de rascunho
com o `sino_0` de volta a `tv` («toca no controle em viga.gd:419, o mapa diz tv»).

## Provas

- `bash tests/prova_dos_portoes.sh`, com os dois casos novos (o `onde_toca` que falta e o «a fazer» que já toca).

## Para o André (local)

Nada: é medida.

## Ao terminar

Pôr a linha no [quadro](README.md) como **feito**, com o gasto.
