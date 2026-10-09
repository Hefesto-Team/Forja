# V08 — Os portões de arte e som reprovam

**Sprint:** V · **Tamanho:** M · **Depende de:** a bíblia de arte aprovada (o ESPERA-ELA), a G14 da direção de arte
(o tema com os tokens e as quatro fontes), V05, e o `docs/jogo/audio/mapa.csv` com os arquivos

## Por quê

Os portões de arte e de som entram em modo aviso, porque hoje o código inteiro está fora da bíblia: enquanto avisam,
ninguém é parado. Esta ficha zera os avisos e vira a chave para reprovar.

## Ler antes

- [scripts/portoes/LEIA-ME.md](../../../scripts/portoes/LEIA-ME.md) (o que cada portão pega e como virar)
- [A ficha pronta](../o-time/ficha-pronta.md) (o item 2 do que o revisor reprova)
- [O mapa do áudio](../o-time/o-mapa-do-audio.md)

## O estado de hoje

Medido em 08/10/2026 com `bash scripts/portoes/rodar.sh` (arte: 193 avisos em 46 arquivos; som: 3 avisos):

- **Cor fora de token:** 140 cores escritas fora de `godot/scripts/tema.gd` (`Color("#…")`, `Color8`, `Color(0.x, …)`;
  os maiores: `salas/voz.gd` 21, `salas/impacto.gd` 19, `salas/molde.gd` 16, `salas/prova.gd` 15, `salas/viga.gd`,
  `salas/canto.gd` e `salas/caminhos.gd` 12 cada), mais 16 `Color.WHITE`/`Color.BLACK` (os primeiros em
  `mundo/efeitos.gd`). O próprio `tema.gd` tem 20 cores que não estão na paleta da bíblia (a partir da linha 11).
- **Fonte fora da bíblia:** `godot/project.godot:42` pede `SpaceGrotesk` em `gui/theme/custom_font`; o `tema.gd:54-55`
  carrega Space Grotesk e JetBrains Mono, e as duas estão em `godot/assets/fontes/`.
- **Texto abaixo de 30 px:** 12 chamadas, `godot/scripts/ui/diagnostico.gd` 8 (20 e 22 px),
  `godot/scripts/ui/painel_bancada.gd:57` (o selo em 20) e `:58` (o parágrafo em 22),
  `godot/scripts/ui/tela_lobby.gd:108` (26) e `:111` (24).
- **Cor de jogador fora do jogador:** nenhum acesso por índice literal hoje; o portão segue olhando.
- **Som:** o `docs/jogo/audio/mapa.csv` não existe, então 36 ids tocados ficam sem conferência (a V05 cria o mapa);
  `godot/scripts/salas/canto.gd:297` e `:299` tocam um id que mora numa variável e o portão não lê.
- **O mapa da direção de arte, medido antes de entrar** (o `docs/jogo/audio/mapa.csv` da árvore da direção, 258 linhas,
  posto numa raiz de rascunho em 08/10/2026): `som.py` dá 164 avisos, e a maior parte é o portão que não lê o mapa
  como ele é escrito, não defeito do som:
  - 37 linhas com `arquivo` = `(módulo)` (o som que o módulo sintetiza no controle) saem como «o arquivo não existe»;
  - os 36 ids tocados não casam com nenhuma linha: o mapa escreve a gravação como `<gravação>_<n>` (as versões que
    `Som.versoes` carrega, `godot/scripts/som.gd:96-101`), a síntese da TV como `sint_<id>` e a do controle como
    `mod_<id>`, e o nome tocado passa por `GRAVADOS` (`som.gd:39`) antes de virar gravação (`sucesso` toca
    `vitoria_sala`);
  - 36 arquivos passam do teto de −1 dBFS de `som.json`, e a bíblia (`docs/jogo/arte/03-som.md`) deixa o pico da
    Kenney medido no próprio mapa (a coluna `pico_dbfs` chega a −0,9);
  - 53 estalam pela régua de `som.json` (0,25 ms, 5 % do fundo); a bíblia pede outra régua, a primeira e a última
    amostra abaixo de 0,001 (`03-som.md:384`).
- **Os portões de arte da direção:** `docs/jogo/arte/12-portoes.md` (na árvore da direção) pede oito portões e uma
  «catraca» (o número de defeitos não sobe) no lugar do modo aviso; `arte.py` tem quatro (cor, fonte, tamanho, cor
  de jogador) e não tem contraste, emissivo com dono, na batida nem emoji na tela.

## Arquivos que mudam

- os arquivos que o portão apontar (a lista sai do `rodar.sh`, não desta ficha)
- `scripts/portoes/arte.json` e `scripts/portoes/som.json` (`"modo": "reprova"`)
- `scripts/portoes/som.py` e `scripts/portoes/arte.py` (o mapa lido como é escrito; os portões do `12-portoes.md`)
- `tests/prova_dos_portoes.sh` (um caso por forma de id e por portão novo)
- `.github/workflows/forja.yml` (o comentário do passo dos portões diz que estão valendo)

## Passos

1. `bash scripts/portoes/rodar.sh > /tmp/portoes.log` e separar os avisos por arquivo.
2. Cor: trocar cada literal pelo token da bíblia mais perto pelo papel (não pelo tom); o que não tem papel na bíblia
   vai para o diretor de arte, não vira token novo por conta própria.
3. Fonte e tamanho: o tema da G14 já resolve o grosso; o lobby e o painel sobem para 30.
4. Som: primeiro o portão lê o mapa como ele é: pula o `(módulo)`, casa o id tocado com as linhas pela tabela
   `GRAVADOS` e pelas formas `<gravação>_<n>`, `sint_<id>` e `mod_<id>` (cada forma com um caso na prova), e a
   régua do pico e do estalo passa a ser a da bíblia, escrita em `som.json`. Depois, os arquivos que o portão
   reprova voltam para o diretor de som com a medida.
5. Arte: acertar `arte.py` com o `12-portoes.md` da direção (os quatro portões que faltam, e a catraca no lugar do
   aviso, se o arquiteto escolher a catraca), com um caso na prova para cada portão novo.
6. Com zero aviso, `"modo": "reprova"` nos dois `.json`, e o CI vermelho prova que vale (um `Color("#123456")`
   numa sala, num commit de teste que não sobe).

## Pronto quando

`bash scripts/portoes/rodar.sh` diz `arte: 0 avisos` e `som: 0 avisos` com os dois em modo reprova.

## Provas

- `bash scripts/portoes/rodar.sh`
- `bash tests/prova_dos_portoes.sh`
- `bash tests/prova_visual.sh` (as cores trocadas; as pranchas olhadas)
