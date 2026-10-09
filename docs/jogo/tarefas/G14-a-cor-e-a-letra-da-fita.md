# G14 — A cor e a letra da Fita

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F09

## Por quê

O jogo ainda veste a paleta Drácula e as fontes do app Hefesto, e o boneco sai inteiro na cor do lugar. A Vitória viu
na montagem (09/10/2026): «tudo tá num neon de uma única cor que nada diferencia». Esta ficha troca os tokens e as
fontes de `tema.gd` pelos do [02](../arte/02-cor-e-letra.md), tira toda cor 2D escrita fora dele e para de tingir o
corpo do boneco: a cor do dono sai da roupa e fica no contorno, no aro e no acento.

## Ler antes

- [02 — a cor e a letra](../arte/02-cor-e-letra.md) (os tokens, «Do Drácula para a Fita», as quatro fontes, a escala)
- [04, a peça se distingue](../arte/04-o-cavaleiro.md#a-peça-se-distingue) (por que o corpo não se tinge)
- [12 — os portões](../arte/12-portoes.md) (o portão de arte)

## O estado de hoje

- `godot/scripts/tema.gd`: as cores do Drácula nas linhas 11 a 34 (`CASA`, `APP`, `PAINEL`, `ELEVADO`, `LINHA`,
  `TRILHO`, `SUTIL`, `SEL`, `FG`, `SUAVE`, `MUDO`, `COMMENT`, `ROXO`, `ROSA`, `VERDE`, `LARANJA`, `VERMELHO`,
  `CIANO`, `AMARELO`, `LED_ACESO`); os tamanhos `T_*` nas linhas 37 a 44 (`T_CORPO` 32); `RAIO_QUADRO` 18; as fontes
  `_SG` (Space Grotesk) e `_MONO` (JetBrains Mono) nas linhas 54 e 55, servidas por `Tema.fonte(peso)` e
  `Tema.mono(peso)` (142 chamadas em `godot/scripts/`). Os nomes antigos aparecem em 30 arquivos.
- `godot/scripts/forja.gd:73` `COR_DO_LUGAR` = `Color8(0, 72, 255)`, `(255, 24, 8)`, `(0, 255, 64)`,
  `(255, 8, 168)`; a lightbar recebe essas.
- `godot/scripts/player.gd:155` `_vestir()` troca o material de toda malha `body*` por um com
  `albedo_color = cor.lerp(Color.WHITE, 0.25)`: o corpo inteiro na cor do lugar, a cabeça fica. É a causa do «neon de
  uma cor só».
- `godot/project.godot:42` `theme/custom_font` = Space Grotesk; `:47` `default_clear_color` = `#11121a`.
- As fontes da bíblia já estão em `godot/assets/fontes/` (Bungee, VT323, Archivo Narrow, Permanent Marker), ao lado
  de `SpaceGrotesk-wght.ttf`, `JetBrainsMono-wght.ttf` e os dois `OFL-*.txt` delas.
- **O portão de arte** (`bash scripts/portoes/rodar.sh --so arte`, modo aviso) acha **193**: 140 cores escritas fora
  de `tema.gd`, 13 `Color.WHITE`, 3 `Color.BLACK`, 12 textos abaixo de 30 px (diagnostico 6, lobby 2, painel_bancada
  2, e outros), 5 de fonte, 20 cores do Drácula em `tema.gd`. Meça de novo antes de mudar.
- O estudo já tem os tokens e as fontes certos: `godot/estudos/direcao/fita.gd` (`FITA` a `ERRO_B`, `JOGADOR`,
  `SECAO`, `bungee()`, `vt()`, `archivo()`, `marcador()`).

## O alvo

- **Os tokens** em `tema.gd`, com os nomes e hex do 02: as superfícies (`FITA`, `CASCO`, `CASCO_ALTO`, `GRAFITE`,
  `JANELA`, `SOMBRA`), a etiqueta (`ETIQUETA`, `ETIQUETA_SOMBRA`, `TINTA`, `TINTA_SUAVE`, `MUDO`), o cenário
  (`VIOLETA`, `VIOLETA_FUNDO`, `TUNGSTENIO`, `OXIDO`, `OXIDO_BRILHO`), o erro (`ERRO_R`, `ERRO_B`),
  `const JOGADOR := [ciano, magenta, limão, âmbar]`, `const SECAO := [vermelhão, cobalto, petróleo, mostarda,
  ameixa]`, e as peles das raças `PELE_ORC #89aa77`, `PELE_LATAO #bda978`, `PELE_ESCORIA #a3958e`,
  `PELE_RAPOSA #cd8d6d`.
- `static func tinta_da_secao(numero: int) -> Color`: S1 e S9 → `SECAO[0]`; S2 e S6 → `[1]`; S3 e S7 → `[2]`; S4 e o
  pódio (0) → `[3]`; S5 e S8 → `[4]`.
- **Os nomes antigos somem.** Cada uso troca pela tabela
  [Do Drácula para a Fita](../arte/02-cor-e-letra.md#do-drácula-para-a-fita), sem decidir caso a caso. Onde a tabela
  diz «a cor do dono» e o código não tem dono (o título, o crédito), vale `ETIQUETA`.
- **As fontes:** `Tema.bungee()`, `Tema.vt()`, `Tema.archivo(peso)` (500, 600 ou 700), `Tema.marcador()`, como em
  `fita.gd`. `Tema.fonte(p)` vira `Tema.archivo(max(p, 500))`; `Tema.mono(p)` vira `Tema.vt()`. As duas antigas e
  `_SG`, `_MONO` somem. `project.godot` aponta `theme/custom_font` para `ArchivoNarrow-wght.ttf`.
- **A escala** do [02](../arte/02-cor-e-letra.md#a-escala-de-tamanhos): `T_DISPLAY` 112, `T_TITULO` 64, `T_AVISO`
  46, `T_CORPO` 34, `T_ROTULO` 30, `T_MONO` 30, `T_SELO` 30, `T_SUBTITULO` 44 (o «como jogar» do J-card); e os novos
  `T_VERBO` 160, `T_PONTOS` 64, `T_ETIQUETA` 56, `T_CARIMBO` 46, `T_PSHARP` 40, `T_NOME` 32. Os textos abaixo de 30 px
  sobem a 30; onde a linha deixa de caber (o diagnóstico da bancada), `Desenho.caber` corta com «…».
- **O jogador:** `forja.gd` `COR_DO_LUGAR` vira `Tema.JOGADOR` (a lightbar segue a mesma tabela, como manda o 02).
- **O corpo não se tinge:** `_vestir()` sai de `player.gd`, e a chamada dele também. As malhas ficam com o material do
  `.glb` (o `colormap.png`). A cor do dono fica no contorno e no aro (G15) e no acento da peça (G13). A
  recoloração pela faixa da parte (tecido, couro) é da G13.
- **Toda cor 2D fora de `tema.gd` vira token:** `draw_*`, `Label`, `modulate`, `Theme`, o `default_clear_color`. Uma
  linha é 3D, e fica para a G15, quando cita (sem diferença de caixa) `albedo`, `emission`, `light_`, `fog`,
  `ambient`, `background`, `material`, `neon(`, `fosco(`, `contorno(`, `Light3D`, `particula`, `mesh`, `Sprite3D`,
  `Label3D` ou `luz`. Por essa regra, hoje, 56 achados são 2D (desta ficha) e 99 são 3D.
- `scripts/portoes/arte.json`: os quatro `PELE_*` entram em `tokens`.

## Arquivos que mudam

- `godot/scripts/tema.gd`. **De todos:** G11 (as constantes da placa), G15 (os tokens de luz, se precisar)
- `godot/scripts/forja.gd`: `COR_DO_LUGAR`
- `godot/scripts/player.gd`: `_vestir` sai. **De todos:** G10 (o caminho), G13 (a montagem), G15 (o aro e o contorno)
- `godot/scripts/main.gd`, `godot/scripts/mundo/kit.gd`, `godot/scripts/mundo/salao.gd`,
  `godot/scripts/mundo/efeitos.gd`, `godot/scripts/salas/*.gd`: só as linhas 2D. **De todos:** G10, G15, G16
- `godot/scripts/ui/*.gd` (os 30 arquivos com nome antigo, menos os de cima). **De todos:** G11 (`desenho.gd`,
  `pausa.gd`), G12 (`painel_sala.gd`)
- `godot/scripts/opcoes.gd` e `godot/scripts/ui/tela_opcoes.gd`: só cor e fonte. **De todos:** G16
- `godot/project.godot`: `theme/custom_font`, `default_clear_color`
- `godot/assets/fontes/`: saem `SpaceGrotesk-wght.ttf`, `JetBrainsMono-wght.ttf`, os `.import` e
  `OFL-SpaceGrotesk.txt`, `OFL-JetBrainsMono.txt`
- `LICENCAS-DE-TERCEIROS.md`: a linha 13 e as seções «Space Grotesk» (129) e «JetBrains Mono» (227). **De todos:**
  G10, G11
- `godot/assets/LEIA-ME.md`: a linha 9. **De todos:** G10, G11
- `scripts/portoes/arte.json`: os `PELE_*`
- `godot/testes/prova_do_jogo.gd`. **De todos**

## Como se joga

Não se aplica: nenhuma regra muda. O que muda é cor, letra e tamanho.

## A cena

- **As telas:** fundo `FITA`, placas `CASCO`, texto `ETIQUETA` (o secundário em `MUDO`), sem roxo, rosa, verde nem
  ciano de interface. O foco de quem tem dono é a cor do dono; sem dono, `ETIQUETA`.
- **A letra:** Bungee no grito (P#, carimbo, vencedor), VT323 no que a máquina mede (pontos, tempo, rótulos de stat),
  Archivo Narrow na voz (500 no texto, 600 no nome e no rótulo, 700 no botão e no «Pronto»), Permanent Marker na
  etiqueta. Nenhum texto abaixo de 30 px.
- **O boneco:** com o `colormap.png` da Kenney, sem tom; a cabeça, o tronco e as pernas com as cores próprias da
  malha. O que marca o dono, depois desta ficha, é o contorno (G15) e o aro (hoje, emissão 1,4 na cor do lugar, em
  `player.gd:76`).
- **A prancha:** as fotos da prova visual ao lado de `docs/imagens/direcao/02_salao.jpg`, `04_cartao.jpg` e
  `07_titulo.jpg` (os quadros do estudo com a mesma tela).

## O som

Não se aplica: nenhum som muda.

## O controle

| evento | vibração | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- |
| o lugar se acende (entrar, trocar de lugar) | não muda | não muda | a lightbar vai para `Tema.JOGADOR[l]` (#29e6ff, #ff3ea5, #d4ff4a, #ee9a1e) pela `Forja.luz_do_lugar(l)` de hoje | não muda | não se usa |

Prova sem o controle na mão: `Forja.luz_do_lugar(l)` grava a cor pedida no registro do módulo simulado; a prova
compara com `Tema.JOGADOR[l]`.

## O cavaleiro

A peça não muda de stat. Como ela aparece: com a cor da malha, sem o tom do dono. As peles `PELE_*` ficam prontas em
`tema.gd` para a G13 vestir as raças do [04](../arte/04-o-cavaleiro.md#as-raças).

## As reações

Não se aplica: nenhuma reação muda (o adesivo de reação usa os tokens novos pela ficha das reações).

## A diversão

Não se aplica como momento: esta ficha não muda o que acontece na noite. O que ela garante para a montagem, e como se
confere:

- **Prancha:** a foto da montagem da prova visual, com os quatro lugares, antes e depois. Depois, nenhum corpo tem o
  tom do dono, e as três partes de cada boneco têm cores próprias. O jogador do time diz, sem ver o contorno, qual
  peça é de cima e qual é de baixo em cada um.
- **Robô:** a prova lê o `albedo_color` de toda superfície `body*` do boneco de cada lugar e confere que nenhuma é a
  cor do lugar.

## Pronto quando

`tema.gd` só tem os tokens e as quatro fontes do 02; `grep -rn 'Color("#\|Color8(' godot/scripts` só acha `tema.gd`
e linhas 3D; o portão de arte não acha mais nenhum achado 2D (os que sobram batem na regra 3D acima); `_vestir` não
existe; e as duas fontes do app saíram do jogo e das licenças.

## Provas

- `bash tests/prova_do_jogo.sh`, com estas checagens novas em `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  _esperar(Forja.COR_DO_LUGAR == Tema.JOGADOR, "tema: a cor do lugar é a do 02")
  _esperar(Tema.tinta_da_secao(6) == Tema.SECAO[1], "tema: S6 é cobalto")
  _esperar(not FileAccess.file_exists("res://assets/fontes/SpaceGrotesk-wght.ttf"), "tema: Space Grotesk saiu")
  for p in main.jogadores:
  	for mi in p.find_children("body*", "MeshInstance3D", true, false):
  		for s in mi.mesh.get_surface_count():
  			var m = mi.get_surface_override_material(s)
  			_esperar(m == null or (m as StandardMaterial3D).albedo_color != Forja.COR_DO_LUGAR[p.lugar], "boneco: o corpo sem o tom do dono")
  ```

- `bash scripts/portoes/rodar.sh --so arte`: a contagem cai de 193; cada achado que sobra é 3D pela regra acima (a
  G15 os zera). Um script de uma linha no commit confere: `rodar.sh --so arte | grep AVISO`, e cada linha citada
  bate na lista de palavras 3D.
- `bash tests/prova_visual.sh`: nenhum texto saindo da placa em 1,0× e 1,15×, em pt-BR e en (o corpo subiu de 32 a 34
  px).
- A prancha: as fotos da prova visual ao lado dos quadros 02, 04 e 07 do estudo, olhadas pelo jogador do time.

## Passos

1. Copiar os tokens e as funções de fonte de `fita.gd` para `tema.gd`, mais `tinta_da_secao` e os `PELE_*`.
2. Trocar os nomes antigos em `godot/scripts/` pela tabela do 02, um arquivo por commit quando o arquivo é grande
   (`main.gd`, `salao.gd`).
3. `Tema.fonte` e `Tema.mono` pelas quatro; a escala; os textos abaixo de 30 px.
4. `COR_DO_LUGAR`; `_vestir` sai.
5. As cores 2D restantes viram token; as 3D ficam como estão.
6. Apagar as duas fontes e as licenças; `project.godot`; `arte.json`.
7. A prova visual e a prancha.

## Armadilhas

- **O `SEL` vira `CASCO_ALTO` com borda na cor do dono:** a seleção sem dono usa a borda `ETIQUETA`.
- **O `VERDE` de «deu certo» não tem par:** o acerto é a cor de quem acertou ([11](../arte/11-o-que-nunca.md#a-imagem)).
- **Texto em `MUDO` sobre `CASCO_ALTO`** só a partir de 48 px.
- **Tirar `_vestir` muda a foto de toda sala:** a prova visual vai acusar diferença no boneco; é esperado, e a prancha
  nova vira a referência.
- **O Archivo Narrow é variável:** o peso vai por `FontVariation` (`wght`), como `Tema._variacao` faz hoje.

## Não fazer

- Não mudar o tamanho de nenhum layout além do que a escala pede.
- Não trocar luz 3D, emissivo, névoa nem partícula: é da G15.
- Não recolorir peça nem pôr acento: é da G13.
- Não virar o portão de arte para reprovar: é da V08.

## Ao terminar

Marcar G14 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(tema): a cor e a letra da Fita no jogo inteiro, e o boneco sem o tom do dono`.
