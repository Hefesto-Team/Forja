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

## Arquivos que mudam

- os arquivos que o portão apontar (a lista sai do `rodar.sh`, não desta ficha)
- `scripts/portoes/arte.json` e `scripts/portoes/som.json` (`"modo": "reprova"`)
- `.github/workflows/forja.yml` (o comentário do passo dos portões diz que estão valendo)

## Passos

1. `bash scripts/portoes/rodar.sh > /tmp/portoes.log` e separar os avisos por arquivo.
2. Cor: trocar cada literal pelo token da bíblia mais perto pelo papel (não pelo tom); o que não tem papel na bíblia
   vai para o diretor de arte, não vira token novo por conta própria.
3. Fonte e tamanho: o tema da G14 já resolve o grosso; o lobby e o painel sobem para 30.
4. Som: os arquivos que o portão reprova voltam para o diretor de som com a medida.
5. Com zero aviso, `"modo": "reprova"` nos dois `.json`, e o CI vermelho prova que vale (um `Color("#123456")`
   numa sala, num commit de teste que não sobe).

## Pronto quando

`bash scripts/portoes/rodar.sh` diz `arte: 0 avisos` e `som: 0 avisos` com os dois em modo reprova.

## Provas

- `bash scripts/portoes/rodar.sh`
- `bash tests/prova_dos_portoes.sh`
- `bash tests/prova_visual.sh` (as cores trocadas; as pranchas olhadas)
