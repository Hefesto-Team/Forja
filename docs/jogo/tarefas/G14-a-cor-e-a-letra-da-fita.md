# G14 — A cor e a letra da Fita

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F09

## Por quê

O jogo ainda veste a paleta Drácula e as fontes do app Hefesto. A bíblia de
arte decidiu a Fita Magnética: esta ficha troca os tokens e as fontes de
`tema.gd` pelos da [02](../arte/02-cor-e-letra.md), e tira toda cor escrita
fora dele.

## Ler antes

- [02 A cor e a letra](../arte/02-cor-e-letra.md) (os tokens, a tabela "Do
  Drácula para a Fita", as quatro fontes, a escala)
- [12 Os portões](../arte/12-portoes.md) (portões 1, 2 e 4)

## O estado de hoje

- `godot/scripts/tema.gd`: as superfícies `CASA`, `APP`, `PAINEL`, `ELEVADO`,
  `LINHA`, `TRILHO`, `SUTIL`, `SEL`; o texto `FG`, `SUAVE`, `MUDO`,
  `COMMENT`; os acentos `ROXO`, `ROSA`, `VERDE`, `LARANJA`, `VERMELHO`,
  `CIANO`, `AMARELO`; as fontes `_SG` (Space Grotesk) e `_MONO` (JetBrains
  Mono) nas linhas 54 e 55; `Tema.t()` multiplica pelo `escala_texto`.
- 102 `Color("#`, 1 `Color8(` e 19 `Color(` com número fora de `tema.gd`
  (`forja.gd`, `main.gd`, `mundo/kit.gd`, `mundo/salao.gd`, `salas/*.gd`).
- O estudo já tem os tokens e as fontes certos em
  `godot/estudos/direcao/fita.gd` (`FITA` a `ERRO_B`, `JOGADOR`, `SECAO`,
  `BUNGEE`, `VT323`, `ARCHIVO`, `MARCADOR`).

## O alvo

- `tema.gd` passa a ter os tokens da 02, com os mesmos nomes e hex, mais
  `OXIDO`, `OXIDO_BRILHO`, `JANELA` e `SOMBRA`. As cores dos jogadores ficam
  em `Tema.JOGADOR[lugar]` e as das seções em `Tema.SECAO[secao]`.
- Os nomes antigos somem. Cada uso troca pela tabela "Do Drácula para a Fita"
  da 02, sem decidir caso a caso.
- As fontes: `Tema.bungee()`, `Tema.vt()`, `Tema.archivo(peso)`,
  `Tema.marcador()`, como em `fita.gd`. `Tema.fonte()` e `Tema.mono()` somem,
  e os dois `.ttf` do app saem de `godot/assets/fontes/` com as licenças.
- Os tamanhos `T_*` seguem a escala da 02 (o corpo vai de 32 a 34; nada
  abaixo de 30).
- Toda cor fora de `tema.gd` vira token. Cor de luz e de ambiente 3D que não
  é token espera a G15; até lá fica numa constante nomeada no próprio
  arquivo, contada pela catraca.

## Passos

1. Copiar os tokens e as funções de fonte de `fita.gd` para `tema.gd`.
2. Trocar os nomes antigos em `godot/scripts/` pela tabela da 02, um
   arquivo por commit quando o arquivo é grande (`main.gd`, `salao.gd`).
3. Trocar os `Color("#`, `Color8(` e `Color(` com número restantes.
4. Apagar `_SG`, `_MONO`, os `.ttf` e as licenças do app; atualizar
   `LICENCAS-DE-TERCEIROS.md`.
5. Rodar a prova visual e comparar as fotos com os quadros de
   `docs/imagens/direcao/`.

## Armadilhas

- O `SEL` vira `CASCO_ALTO` com borda na cor do dono: a seleção sem dono (o
  menu do título) usa a borda `ETIQUETA`.
- O `VERDE` de "deu certo" não tem par: o acerto é a cor de quem acertou
  ([11](../arte/11-o-que-nunca.md#a-imagem)).
- Texto em `MUDO` sobre `CASCO_ALTO` só a partir de 48 px.

## Não fazer

- Não mudar o tamanho de nenhum layout além do que a escala pede.
- Não trocar luz 3D nem emissivo (é da G15).

## Pronto quando

`tema.gd` só tem os tokens e as quatro fontes da 02; um `grep` por
`Color("#` e `Color8(` em `godot/scripts/` só acha `tema.gd`; os portões 1,
2 e 4 da 12 passam com a catraca em zero.

## Provas

- `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`.
- Os portões 1, 2 e 4 ([12](../arte/12-portoes.md)) com a catraca zerada.
- A prancha: as fotos da prova visual ao lado dos quadros 01, 04 e 07.

## Ao terminar

Marcar G14 como **feito** no [quadro](README.md). Commit sugerido:
`feat(tema): a cor e a letra da Fita Magnética no jogo inteiro`.
