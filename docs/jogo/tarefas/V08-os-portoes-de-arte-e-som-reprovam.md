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

Medido em 08/10/2026 com `bash scripts/portoes/rodar.sh`:

- **Cor fora de token:** 102 `Color("#…")` fora de `godot/scripts/tema.gd` (os maiores: `salas/voz.gd` 19,
  `salas/molde.gd` 13, `salas/canto.gd` 12, `salas/viga.gd` 10, `mundo/salao.gd` 9), mais o `light_color` de
  `godot/scenes/main.tscn:16` e o `default_clear_color` de `godot/project.godot`. O próprio `tema.gd` tem cores que
  não estão na paleta da bíblia.
- **Fonte fora da bíblia:** `godot/project.godot` pede `SpaceGrotesk` em `gui/theme/custom_font`; o `tema.gd`
  carrega Space Grotesk e JetBrains Mono.
- **Texto abaixo de 30 px:** `godot/scripts/ui/tela_lobby.gd:108` (26) e `:111` (24),
  `godot/scripts/ui/painel_bancada.gd:57` (o selo em 20).
- **Cor de jogador fora do jogador:** o que o portão listar (acesso a `Tema.JOGADOR[...]` com índice literal).
- **Som:** ids tocados fora do mapa (a V05 zera) e os arquivos sem duração, pico ou com clique.

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
