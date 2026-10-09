# G15 — A luz, o pós e o brilho com dono

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F09, G14

## Por quê

O jogo acende tudo no mesmo laranja e com a energia que cada arquivo quis.
A bíblia decidiu a luz de cada seção, o pós da fita e um dono para cada
brilho. Esta ficha leva os três ao jogo.

## Ler antes

- [01 O cinema](../arte/01-cinema.md#a-luz-das-cinco-tintas) (a luz das cinco
  tintas, o lado B, o pico, a fita gasta)
- [07 O brilho e os efeitos](../arte/07-vfx.md) (o dono, a tabela do brilho,
  o pós da fita)
- [12 Os portões](../arte/12-portoes.md#6-emissivo-com-dono) (portão 6)

## O estado de hoje

- O ambiente é montado em `main.gd:92` (`glow_intensity` 0,7, filmic), igual
  em toda seção.
- 17 materiais com `emission_enabled` em `godot/scripts/` (`main.gd`,
  `mundo/efeitos.gd`, `mundo/kit.gd`, `mundo/salao.gd` cinco vezes,
  `player.gd`, `salas/canto.gd`, `salas/impacto.gd`, `salas/sala_jogo.gd`,
  `salas/voz.gd`); 6 com energia acima de 1,0, como o fogo do salão a 3,0 em
  `Tema.LARANJA` (`salao.gd:227`).
- O estudo já tem o pós em `godot/estudos/direcao/shaders/pos_fita.gdshader`
  (`varredura`, `vinheta`, `grao`, `aberracao`, `rasgo`, `desbota`) e o
  néon e o contorno em `neon.gdshader` e `contorno.gdshader`.

## O alvo

- **A luz por seção:** uma função `Tema.luz_da_secao(secao, lado)` devolve a
  névoa, o preenchimento e a chave da tabela do 01; o lado B multiplica a
  chave por 0,85 e a névoa por 1,3. Cada sala pede a luz da sua seção.
- **O brilho com dono:** `Tema.neon(cor, energia, dono)`,
  `Tema.contorno(cor, largura, energia, dono)` e `Tema.emissivo(material,
  energia, dono)`. O dono é um lugar (teto 3,0), `"mundo"` (teto 1,2,
  `VIOLETA`) ou `"forja"` (teto 2,4, `TUNGSTENIO`). Acima do teto, a função
  registra o erro e corta no teto. Os 17 materiais passam por elas.
- **O pós da fita:** `pos_fita.gdshader` entra num `CanvasLayer` acima do 3D e
  abaixo do HUD, com os valores de repouso do 07; `rasgo` e `aberracao`
  respeitam `Opcoes.flashes`.
- **O desgaste:** `desbota` sobe com o número da faixa da noite, como no 01.
- **A cor de luz nomeada:** as cores de ambiente e de luz que o estudo
  escreve em hex (`#2a2738`, `#8a7cff`, `#b8b0ff` e as outras) viram linhas
  da tabela de luz em `tema.gd`.

## Passos

1. `Tema.luz_da_secao` e a tabela do 01; trocar o ambiente de `main.gd`.
2. As três funções de brilho; trocar os 17 materiais, um arquivo por commit.
3. O pós e o desgaste.
4. A prova visual nas cinco seções, lados A e B.

## Armadilhas

- O Compatibility multiplica o glow pelo fundo a ×0,45: a energia que parece
  certa no Forward+ fica fraca aqui. Medir na prova, não no editor.
- O pico da luz (+20 % em 1 batida) conta como piscada
  ([10](../arte/10-acessibilidade.md#o-piscar)): medir com
  `scripts/medir_clarao.gd`.

## Não fazer

- Não mexer em câmera nem em corte (é da G05 e do 01).
- Não pôr SSAO nem uma segunda luz com sombra.

## Pronto quando

Cada seção tem a luz da tabela do 01 nos dois lados; nenhum material
brilha fora das três funções; o portão 6 passa com a catraca em zero; o pós
está ligado e desliga o rasgo sem "Flashes".

## Provas

- `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.
- O portão 6 ([12](../arte/12-portoes.md#6-emissivo-com-dono)).
- A prancha: as fotos das cinco seções ao lado do `13_luz.jpg`
  ([PRODUÇÃO](../arte/PRODUCAO.md), item 4).

## Ao terminar

Marcar G15 como **feito** no [quadro](README.md). Commit sugerido:
`feat(luz): a luz de cada seção, o pós da fita e o brilho com dono`.
