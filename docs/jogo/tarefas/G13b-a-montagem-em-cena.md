# G13b — A montagem em cena

**Sprint:** G · **Tamanho:** G · **Estimativa:** dois dias · **Depende de:** G13 (as peças, `Montar`, `Cavaleiro`, o
encaixe na semicolcheia, a forja parte por parte), G04 (`Visor`, `Desenho.vu`), G11 (`Desenho.placa`, `lampadas`,
`dica`), G16 (`Opcoes.reduzido()`, `Opcoes.parada`) · **Usado por:** G05 (a lente da montagem), G06 (o forjado), G08
parte B (as raças no esqueleto montado)

## Por quê

A G13 entregou o miolo: os 12 do Mini Characters cortados em 36 peças, o cavaleiro de três personagens no esqueleto
de 7 ossos, os stats lidos dos CSV do designer de sistemas, o pré-montado, as cinco linhas da coluna, o encaixe na
semicolcheia com o som no tom da parte, o pulso de metal, as faíscas e a pose, e a forja que acende parte por parte.
O que ficou de fora é a cena em volta e o que a ficha pedia além do miolo: a câmera frontal de 50 mm, os anéis e as
luzes de cada coluna, o plano dos prontos, o giro e a volta de 360°, o sorteio em roleta, a trava, os emblemas, as
chaves, a fita das 12, as marcas do item no VU e os sublinhados da build boa. Sem isso, a tela não bate com
`docs/imagens/direcao/10_montagem.jpg`.

## Ler antes

- [G13](G13-o-cavaleiro-montavel.md): todos os números desta ficha foram copiados de lá. As seções «A cena», «O som»,
  «O controle», «A diversão», «O alvo» e «O robô».
- [G13, «O que foi feito»](G13-o-cavaleiro-montavel.md#o-que-foi-feito-leva-1-as-telas): o que já existe e as
  escolhas a validar.
- [05 — as curvas](../arte/05-movimento.md) e [06 — os objetos](../arte/06-interface-e-texto.md).

## O estado de hoje

- `godot/scripts/main.gd`, `_pose_da_camera`, ramo `"lobby"`: ainda a câmera em perspectiva da G02, de cima; não há
  `_lente_da_montagem`.
- `godot/scripts/mundo/salao.gd`: os cavaleiros do lobby ficam em `pedestais`; não há `montagem`, `montagem_no`, os
  anéis, as lâmpadas nem as duas luzes por coluna.
- `godot/scripts/ui/tela_lobby.gd`: o △ sorteia um corpo válido e um item ao alcance de uma vez, sem a roleta de 6
  trocas; não há `travada` nem o □; a pose não gira a plataforma; a peça velha não afunda e a nova não cai.
- `godot/scripts/ui/cartao_jogador.gd`: a placa da G02, sem as lâmpadas nem as duas chaves; a etiqueta sem o virar e
  sem os sublinhados; as linhas sem os emblemas, sem o cadeado e sem a fita das 12; os VUs sem as marcas do item e sem
  a prévia; os 8 quadrados das marteladas saíram, «Forjado» ainda não entrou. Os VUs estão em duas colunas de duas
  linhas (852 a 924), porque quatro linhas de 26 px encavalavam o texto de 30 px; a foto tem quatro linhas, e voltar a
  elas pede descer as dicas ou subir as linhas, com a régua da prova visual nas duas escalas.
- `godot/scripts/ui/glifo.gd`: sem `emb_bigorna`, `emb_mola`, `emb_brasa`, `emb_lume`.
- `godot/scripts/player.gd`: `cadeira` existe como campo, vazio; não há cadeira de rodas nem raça no cavaleiro
  montado (não há `glb` de cadeira em `godot/assets/kenney/mini-characters/`).
- Os sons `ui_sorteio`, `ui_trava` e `ass_p1` a `ass_p4` não estão em `godot/assets/sons/`.
- `tests/prova_visual.sh` não tem a sequência do encaixe (0, 125, 190, 375, 500, 1000 ms) nem o roteiro de captura
  `montagem_encaixe`; `res://estudos/direcao/medir_pecas.gd` não roda sobre as peças do jogo.

## O alvo

Os números estão na G13, nas seções citadas:

| o quê | seção da G13 |
| --- | --- |
| a câmera FRUSTUM de 50 mm e `_lente_da_montagem` | «A câmera» |
| `salao.montagem`, os anéis, as lâmpadas, as bigornas em `montagem_no` | «Onde ficam os cavaleiros» |
| a chave de tungstênio e o contra-luz | «A luz de cada coluna» |
| o travelling de 85 mm com os nomes e `ass_p{k+1}` | «O plano dos prontos» |
| a seta que cresce, a peça velha que afunda, a nova que cai em `MOLA` | «O encaixe», a tabela |
| o giro de 25° e a volta de 360° na oitava, a chave de 3,2 a 5,5 | «A pose de cada linha», «A forja, parte por parte» |
| o △ em roleta de 6 trocas e `ui_sorteio`; o □ e `ui_trava`; `MAX_TRAVAS` | «O encaixe», «O som», «O controle» |
| a placa, as chaves, a etiqueta que vira, os sublinhados, os emblemas, o cadeado, a fita das 12, as marcas do item, a prévia, «Forjado», as dicas | «A coluna» |
| os quatro emblemas | «Os emblemas» |
| o carimbo do nome, a parada de 2 quadros, o idle do forjado | «A forja, parte por parte», «O idle e o forjado» |
| o movimento reduzido | «Com o movimento reduzido» |
| a cadeira (`wheelchair-*`) e a raça na cabeça | «A pose de cada linha», «A coluna» (o rótulo) |

## Passos

1. Os sons: `ui_sorteio`, `ui_trava`, `ass_p1` a `ass_p4` pelo encanamento da G13 («O som»), sem a GPU.
2. A câmera, os anéis e as luzes; sair do lobby sempre volta a câmera em perspectiva.
3. O encaixe completo (a seta, a peça velha, a nova, o giro) e o movimento reduzido.
4. A roleta do △, a trava do □, o robô que pula as linhas travadas.
5. A coluna inteira e os emblemas; a fita das 12.
6. A oitava (o 360°, o carimbo do nome, «Forjado», a parada) e o plano dos prontos.
7. A cadeira e a raça, se a G08 parte B já estiver no quadro.
8. A prova visual: a prancha da montagem, a sequência do encaixe e a medida das peças.

## Armadilhas

- **O FRUSTUM fica preso:** sair do lobby sem `_lente_da_montagem(false)` deixa o salão torto.
- **A malha velha e a nova no mesmo quadro:** `trocar_peca` troca a malha; para a velha afundar e a nova cair, a velha
  precisa de uma cópia que some, não da mesma `MeshInstance3D`.
- **A prova da G13** já confere a malha `"head"` trocando no quadro da semicolcheia; o atraso da queda não pode mudar
  esse quadro.
- **Nada abaixo de 30 px**, nada sem `Traducoes`; as chaves não têm palavra porque 30 px não cabem na placa.

## Não fazer

- Mudar número de stat, de gancho ou de critério (os CSV do designer de sistemas).
- As raças, a pintura e o shader (G08). O teclado do nome (G09).
- Refazer o que a G13 já entregou: o corte, `Montar`, `Cavaleiro`, as cinco linhas.

## Pronto quando

A montagem bate com `10_montagem.jpg` e a sequência do encaixe com `20_encaixe.jpg`; o △ gira a roleta e o □ trava; a
oitava dá a volta e carimba o nome; o plano dos prontos passa pelos quatro; o movimento reduzido troca o giro e a
queda por 4 quadros de opacidade.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`, com blocos novos: a lente volta à perspectiva ao sair do lobby, o △
  faz 6 trocas, a linha travada não troca no △, o plano dos prontos dura 8 s.
- `bash tests/prova_visual.sh`: a prancha da montagem e a sequência do encaixe, sem reprovação nova de texto.
- A medida das peças: `res://estudos/direcao/medir_pecas.gd`, a diferença no diário.

## Para o André (local)

1. `bash tests/prova_visual.sh` sem `--fixed-fps`: as pranchas da montagem e do encaixe ao lado das duas fotos.
2. Quatro DualSense: a roleta de 10 trocas em 10 s, o △ e o □; o `ui_peca` e o pulso saem do controle certo.
3. Uma pessoa que nunca viu monta o primeiro cavaleiro: o tempo até o ✕ e a frase dela, no diário.

## Ao terminar

No [quadro](README.md), G13b **feito** com o commit. Commit sugerido (sem trailer):

```
feat(montagem): a câmera da montagem, as luzes de cada coluna, a roleta, a trava e o plano dos prontos
```
