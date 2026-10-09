# G10 — A biblioteca Kenney

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, F09, G08 (a parte A e o `scripts/conferir_bonecos.py`)

## Por quê

O jogo tem 30 peças do Mini Dungeon soltas numa pasta e quatro lugares que montam o caminho à mão. A montagem da
G13 precisa dos 12 humanos do Mini Characters, do orc e da cauda da raposa (as raças do
[04](../arte/04-o-cavaleiro.md#as-raças), pedido da Vitória em 09/10/2026), e os minigames precisam dos kits de
cenário. Esta ficha põe tudo isso no jogo, um pacote por pasta, por um script que qualquer um roda de novo.

## Ler antes

- [14 — os assets da Kenney](../14-os-assets-kenney.md) (a curadoria, a escala de cada kit, como entra)
- [04, as raças](../arte/04-o-cavaleiro.md#as-raças) (de onde vem cada malha; o que ficou de fora)
- [G08](G08-a-arte-bonecos-e-coerencia.md) (o conferidor de bonecos)

## O estado de hoje

- O All-in-1 já está na máquina, fora do git: `oficina/kenney/3.7.0/` (e a 3.4.0). `scripts/kenney.py` acha qualquer
  pacote pelo catálogo `assets.json` (`python3 scripts/kenney.py onde "Graveyard Kit"`). A versão antiga desta ficha
  dizia «o André compra o pacote»: não precisa.
- Os 30 `.glb` do Mini Dungeon estão soltos em `godot/assets/kenney/`, com `Textures/colormap.png` e
  `KENNEY-LICENSE.txt`. Quatro lugares montam o caminho à mão (`"res://assets/kenney/%s.glb"`):
  `godot/scripts/mundo/kit.gd:6` (`CAMINHO`, lido em `Kit.peca`, linha 13), `godot/scripts/mundo/salao.gd:11`
  (`KIT`, linha 60), `godot/scripts/player.gd:114` (o boneco, por `MODELOS`, linha 14:
  `["character-human", "character-orc"]`) e `:147` (o item), e `godot/scripts/salas/prova.gd:175`, que carrega
  `"res://assets/kenney/character-orc.glb"` escrito por inteiro. Meça de novo antes de mudar.
- **Os personagens, medidos nos `.glb` da 3.7.0** (nós, pele e animações):

| pacote | arquivo | esqueleto | animações | papel no jogo |
| --- | --- | --- | --- | --- |
| Mini Characters | `character-female-a` a `f`, `character-male-a` a `f` | pele, 7 ossos (`root`, `leg-left`, `leg-right`, `torso`, `arm-left`, `arm-right`, `head`) | 32 | as 36 peças humanas da montagem (a G13 corta) |
| Mini Dungeon | `character-orc` | pele, os 7 | 32 | a raça Orc (corte limpo: 176, 144 e 54 triângulos) |
| Mini Dungeon | `character-human` | pele, os 7 | 32 | o boneco de hoje |
| Cube Pets | `animal-fox` | rígido | 8 | só o nó `tail`: a cauda da raposa ferreira |
| Graveyard Kit | `character-skeleton`, `-ghost` (e `-zombie`, `-vampire`, `-keeper`) | rígido, uma malha por parte, sem pele | 32 | monstros: o guardião do minigame 38 e o fantasma do 32. **Não são raça** ([04](../arte/04-o-cavaleiro.md#o-que-se-pesquisou-e-ficou-de-fora)) |
| Mini Arena | `character-soldier` | pele, os 7 | **25** (as 12 que o conferidor pede estão lá) | fora pela curadoria, não pelo conferidor |
| Platformer Kit | `character-oobi` e mais 4 | pele, **6** ossos, sem `head` | **25** | fora |

  O [14](../14-os-assets-kenney.md#a-curadoria) diz que os do Graveyard têm «o mesmo esqueleto»: têm as mesmas
  partes e as mesmas 32 animações, mas não têm pele. O conferidor da G08 (`scripts/conferir_bonecos.py`, a parte A1
  dela) aceita os dois tipos, com pele e rígido, e confere os 7 ossos, as 12 animações da lista `ANIMACOES` dele
  (`idle`, `walk`, `sprint`, `jump`, `fall`, `die`, `emote-yes`, `emote-no`, `attack-melee-right`, `holding-right`,
  `static`, `interact-right`), até 1500 triângulos, `metallic` até 0,2 e a textura ao lado do `.glb`. Uma linha por
  arquivo, PASSOU ou FALHOU; sai com 1 se algum falhou. Os do Graveyard passam como `rígido`. O Mini Arena passaria
  também: ele fica fora porque não está na tabela `APROVADOS` abaixo (o 14 o tira da linha dos compatíveis).

## O alvo

```
godot/assets/kenney/
  mini-dungeon/              os 28 .glb de cenário, Textures/colormap.png, License.txt
  mini-dungeon-personagens/  character-orc.glb e character-human.glb, a Textures/ e a License.txt
  mini-characters/           os 12 personagens
  cube-pets/                 só animal-fox.glb
  graveyard-kit/             as peças de cenário e os 5 personagens
  castle-kit/
  factory-kit/
```

- O orc e o humano ficam numa pasta à parte, como no estudo (`godot/estudos/direcao/kenney/mini-dungeon-personagens/`):
  o papel é por pasta, e o papel deles é `personagem`, o do resto do Mini Dungeon é `cenario`.
- `Kit.caminho(nome) -> String` numa função só: sem barra, `res://assets/kenney/mini-dungeon/<nome>.glb`; com
  barra, `res://assets/kenney/<pasta>/<peça>.glb`. Os quatro lugares de hoje chamam `Kit.caminho`. O `player.gd:114`
  passa a pedir `Kit.caminho("mini-dungeon-personagens/" + MODELOS[modelo_i])`; o `prova.gd:175`,
  `Kit.caminho("mini-dungeon-personagens/character-orc")`.
- `const ESCALA_DO_PACOTE := {"castle-kit": 1.4, "survival-kit": 1.4, "factory-kit": 0.5, "building-kit": 0.35,
  "pirate-kit": 0.4, "cube-pets": 0.4, "blaster-kit": 0.3, "modular-dungeon-kit": 0.25, "modular-cave-kit": 0.25,
  "modular-space-kit": 0.25}` em `kit.gd`; `Kit.peca` multiplica a escala pedida pelo fator da pasta (as outras,
  1×). Os números são os da [escala de cada kit](../14-os-assets-kenney.md#a-escala-de-cada-kit); onde o 14 dá uma
  faixa, vale o número acima. A cauda da raposa não passa por `Kit.peca`: a G13 a escala a 0,33.
- `scripts/importar_kenney.py`:

  ```
  python3 scripts/importar_kenney.py <pasta> [<pasta>...]       do All-in-1 em oficina/kenney/ (a versão mais nova)
  python3 scripts/importar_kenney.py --de <zip ou pasta> <pasta>  de outro lugar
  python3 scripts/importar_kenney.py --lista                      o que a curadoria aceita
  ```

  - acha o pacote com `pasta_do_pacote()` e o catálogo de `scripts/kenney.py` (importa o módulo, não copia o código);
  - `APROVADOS`: um dicionário pasta de destino → (nome no catálogo, papel, filtro). Hoje:

    | pasta | pacote | papel | filtro |
    | --- | --- | --- | --- |
    | `mini-dungeon` | Mini Dungeon | `cenario` | tudo menos `character-*` |
    | `mini-dungeon-personagens` | Mini Dungeon | `personagem` | `character-orc`, `character-human` |
    | `mini-characters` | Mini Characters | `personagem` | `character-*` |
    | `cube-pets` | Cube Pets | `peca` | `animal-fox` |
    | `graveyard-kit` | Graveyard Kit | `cenario` | tudo |
    | `castle-kit` | Castle Kit | `cenario` | tudo |
    | `factory-kit` | Factory Kit | `cenario` | tudo |

    Os outros kits 3D da coluna «entra» da [curadoria](../14-os-assets-kenney.md#a-curadoria) entram na tabela com
    papel `cenario` quando um minigame pedir. Pasta fora da tabela: recusa com «fora da curadoria: veja
    docs/jogo/14». Interface e áudio não passam por aqui: a interface é da G11, o som entra pelo mapa do áudio;
  - copia só os `Models/GLB format/*.glb` do filtro, a `Textures/` irmã e o `License.txt`;
  - em cada `character-*.glb` que o filtro pega (em qualquer pasta, o Graveyard também), roda
    `python3 scripts/conferir_bonecos.py <arquivo>` antes de copiar. O que sai com 1 não é copiado, e o script repete
    a linha FALHOU do conferidor;
  - escreve (ou atualiza) a linha da pasta em `godot/assets/LEIA-ME.md` e em `LICENCAS-DE-TERCEIROS.md`: o pacote, a
    versão (o número entre parênteses da linha do nome no `License.txt`: «Mini Characters (1.0)» dá 1.0) e CC0.

## Arquivos que mudam

- `godot/assets/kenney/` (o Mini Dungeon muda de pasta; as seis pastas novas)
- `godot/scripts/mundo/kit.gd`: `Kit.caminho`, `ESCALA_DO_PACOTE`. **De todos:** G14 e G15 (a cor e o emissivo das peças)
- `godot/scripts/mundo/salao.gd`, `godot/scripts/salas/prova.gd`: só a linha do caminho. **De todos:** G14, G15
- `godot/scripts/player.gd`: só as duas linhas do caminho. **De todos:** G13, G14
- `scripts/importar_kenney.py` e `scripts/testes/prova_importar.py` (novos)
- `godot/assets/LEIA-ME.md` e `LICENCAS-DE-TERCEIROS.md`. **De todos:** G11, G14
- `godot/testes/prancha_dos_corpos.gd` (novo), `docs/imagens/kenney/corpos.jpg` e `corpos_silhueta.jpg`
- `godot/testes/prova_do_jogo.gd`. **De todos**
- `docs/jogo/14-os-assets-kenney.md`: a frase «mesmo esqueleto» do Graveyard vira «as mesmas partes e as mesmas 32
  animações, sem pele; são monstros»; o Mini Arena sai da linha dos compatíveis (25 animações); o Cube Pets ganha a
  linha da cauda
- `docs/jogo/13-arquitetura.md` e `docs/DESENVOLVER.md`: `Kit.caminho`, a pasta por pacote, o comando do script

## Como se joga

Não se aplica: esta ficha não muda nenhuma regra. Ela dá à montagem (G13) as malhas e aos minigames as peças.

## A cena

Nenhuma tela do jogo muda de cara: a prova é que a prova visual de hoje sai igual depois da mudança de pasta.

A prancha dos corpos, `godot/testes/prancha_dos_corpos.gd`, roda com xvfb e `--audio-driver Dummy` e grava
`docs/imagens/kenney/corpos.jpg` em 1920×1080, qualidade 90:

- uma grade de 6 colunas por 3 linhas, células de 320×360: os 12 do Mini Characters, o orc, o humano, a cauda da
  raposa sozinha e o esqueleto, o fantasma e o zumbi do Graveyard (marcados «monstro»), um por célula, com o nome do
  arquivo embaixo em VT323 30, `ETIQUETA` sobre `CASCO`;
- a câmera: 50 mm (FOV 2·atan(12/50) = 27,0°), de frente, a 2,2 m, na altura de 0,45 m; o quadro de 0,5 s do `idle`
  (a cauda, parada);
- a luz do salão do [01](../arte/01-cinema.md#a-luz-das-cinco-tintas): névoa `VIOLETA_FUNDO`, chave `TUNGSTENIO`;
  nada brilha (sem emissivo, sem contorno), cada malha com o `colormap.png` original;
- a mesma grade em silhueta, `corpos_silhueta.jpg`: cada malha chapada em `FITA` sobre `ETIQUETA`.

## O som

Não se aplica: nenhum som. Os sons dos pacotes de áudio da Kenney entram pelo [mapa do áudio](../audio/mapa.csv),
não por este script.

## O controle

Não se aplica: nada nesta ficha fala com o controle.

## O cavaleiro

- **As raças** são as do [04](../arte/04-o-cavaleiro.md#as-raças): Humana, Orc, Autômato de latão, Golem de escória
  e Raposa ferreira. Esta ficha entrega duas malhas: o `character-orc.glb` (a cabeça do Orc) e o `animal-fox.glb` (a
  cauda da Raposa). O Autômato, o Golem e a cabeça da Raposa são feitos por código na G13.
- **As 24 peças humanas** de superior e inferior e as 12 cabeças vêm dos 12 do Mini Characters; a G13 as corta pelo
  osso em `godot/assets/kenney/mini-characters/pecas/`.
- **Os stats:** nenhum. A raça é só aparência ([sistemas](../sistemas/README.md#o-que-não-tem-stat)); as 36 linhas
  de `docs/jogo/sistemas/pecas.csv` continuam as das peças humanas.
- **A cor:** as malhas entram com o `colormap.png` original. A cor de cada parte pela faixa do
  [02](../arte/02-cor-e-letra.md#o-cavaleiro-a-cor-da-peça-e-o-néon-do-dono) é da G13 e da G14.

## As reações

Não se aplica: nenhuma reação nasce aqui.

## A diversão

Não se aplica como momento: esta ficha não muda nada na noite. O momento da escolha da peça e da raça é da G13. O
que esta ficha garante para ele, e como se confere:

- **Prancha:** em `corpos_silhueta.jpg`, o orc e os 12 humanos se separam pela cabeça (a do orc vai de y 0,34 a
  0,78; a humana, de 0,34 a 0,67), e os três monstros se leem como monstros. O jogador do time acerta, sem ver a cor,
  qual célula é o orc e quais são monstros.
- **Robô:** `prova_importar.py` confere que os 12 do Mini Characters e o orc passaram no conferidor.

## Pronto quando

O Mini Dungeon mora em `godot/assets/kenney/mini-dungeon/` (o orc e o humano em `mini-dungeon-personagens/`) e a
prova visual sai igual; o script importa `mini-characters cube-pets graveyard-kit castle-kit factory-kit` do All-in-1
em `oficina/kenney/`; os 12 humanos e o orc passam no conferidor; as licenças estão registradas; e a prancha existe
nas duas versões.

## Provas

- `python3 scripts/testes/prova_importar.py`: monta um zip de mentira com a estrutura do All-in-1 (um personagem de
  pele que passa, um de 6 ossos e um sem `emote-yes` que reprovam, um kit de cenário com 3 peças, um pacote 2D) e
  confere: copia só os GLB do filtro, a `Textures/` e o `License.txt`; recusa a pasta fora da tabela; não copia os dois
  que reprovam (o de 6 ossos, sem `head`, e um de pele com os 7 ossos e sem a animação `emote-yes`); escreve as
  duas linhas de licença; cada `Textures/colormap.png` fica na pasta do seu pacote. O que passa é uma cópia do
  `character-male-a.glb` do All-in-1; os dois que reprovam são ele com o JSON do glTF editado pela prova (o nó `head`
  renomeado; a animação `emote-yes` renomeada). Sem o All-in-1 na máquina, a prova diz «sem o All-in-1» e sai com 0.
- `bash tests/prova_do_jogo.sh`, com estas checagens novas em `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  _esperar(Kit.caminho("floor") == "res://assets/kenney/mini-dungeon/floor.glb", "kit: sem pasta, o mini-dungeon")
  _esperar(Kit.caminho("castle-kit/tower-base") == "res://assets/kenney/castle-kit/tower-base.glb", "kit: a pasta antes da barra")
  _esperar(ResourceLoader.exists(Kit.caminho("floor")), "kit: o mini-dungeon abre da pasta nova")
  _esperar(ResourceLoader.exists(Kit.caminho("mini-dungeon-personagens/character-orc")), "kit: o orc abre")
  _esperar(ResourceLoader.exists(Kit.caminho("cube-pets/animal-fox")), "kit: a raposa abre")
  ```

- `bash tests/prova_visual.sh`: as pranchas de antes e depois da mudança de pasta, iguais.
- As pranchas `docs/imagens/kenney/corpos.jpg` e `corpos_silhueta.jpg`, olhadas pelo jogador do time.

## Passos

1. **O Mini Dungeon muda de pasta:** `git mv` dos `.glb` de cenário, `Textures/` e `KENNEY-LICENSE.txt` (vira
   `License.txt`) para `godot/assets/kenney/mini-dungeon/`; o orc e o humano, com uma cópia da `Textures/` e da
   licença, para `mini-dungeon-personagens/`. Apagar os `.import` antigos e rodar
   `"$GODOT" --headless --path godot --import --quit`.
2. **Um caminho só:** `Kit.caminho` em `kit.gd`, e os quatro lugares chamando-o. `bash tests/prova_do_jogo.sh` passa
   igual.
3. **`scripts/importar_kenney.py`** (Python 3, só a biblioteca padrão), e a prova dele.
4. **Importar:** `python3 scripts/importar_kenney.py mini-characters cube-pets graveyard-kit castle-kit factory-kit`.
5. **A prancha dos corpos.**
6. **A escala:** uma peça de cada kit ao lado de um boneco, na prancha; se a porta do Castle Kit a 1,4× ficar abaixo
   da cabeça do boneco, o fator sobe a 1,5 (o teto da faixa do 14), e o número vai para o 14.
7. **Os documentos:** o 14, o 13 e o `DESENVOLVER.md`; a parte B da G08 passa a apontar para cá.

## Armadilhas

- **O `colormap.png` com o mesmo nome** em todo pacote: nunca juntar duas pastas.
- **A textura de paleta** entra sem compressão e com filtro nearest: o script escreve o `.import` do `colormap.png`
  de cada pasta com `compress/mode=0`, e o jogo usa `filter_nearest`.
- **O `git mv` muda caminhos** que as provas e as fotos citam: `git grep -n "assets/kenney"` antes de commitar.
- **Os monstros do Graveyard não têm `Skeleton3D`:** o `AnimationPlayer` deles anima os nós. Não tente pôr pele
  neles, nem usá-los como peça de montagem.

## Não fazer

- Não importar pacote inteiro «para ver depois».
- Não usar Blocky Characters nem Animated Characters.
- Não editar o `colormap.png` original nem recolorir aqui.
- Não escrever stat.

## Para o André (local)

Rodar `python3 scripts/importar_kenney.py --lista` e abrir a prancha dos corpos. Anotar no diário qualquer malha que
pareça de outro jogo.

## Ao terminar

Marcar G10 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(kenney): um pacote por pasta, o script de importação, o orc e a cauda da raposa`.

## O que foi feito (leva 1, o-cavaleiro)

**Feita**, com um desvio: o `character-ghost` do Graveyard não entrou (abaixo).

- **A pasta por pacote:** o Mini Dungeon mora em `godot/assets/kenney/mini-dungeon/` (28 peças de cenário, `Textures/`, `License.txt`) e o orc e o
  humano em `mini-dungeon-personagens/` (com a `Textures/` e a licença deles); os `.import` antigos saíram e o `colormap.png` de cada pasta
  tem `compress/mode=0`. Entraram pelo script: `mini-characters` (12), `cube-pets` (`animal-fox`), `graveyard-kit` (90 peças, 4 personagens),
  `castle-kit` (76) e `factory-kit` (143). O `survival-kit/` não foi tocado.
- **Um caminho só** (`kit.gd`): `Kit.caminho(nome)`, `PACOTE_PADRAO`, `ESCALA_DO_PACOTE` (os números da ficha) e `Kit.escala_do_pacote(nome)`; `Kit.peca`
  multiplica. `salao.gd` (a constante `KIT` saiu), `player.gd` (o boneco) e `salas/prova.gd` (o orc) chamam `Kit.caminho`. As duas malhas de item
  do `player.gd` (`MALHA_DO_ITEM`) são `const` e seguem escritas por inteiro, já na pasta nova.
- **O script** `scripts/importar_kenney.py` (só a biblioteca padrão; `--lista`, `--de`, recusa fora da curadoria, o conferidor de bonecos antes de
  copiar, a linha de cada pasta em `godot/assets/LEIA-ME.md` e `LICENCAS-DE-TERCEIROS.md`) e `scripts/testes/prova_importar.py`.
- **A prancha** `godot/testes/prancha_dos_corpos.gd` grava `docs/imagens/kenney/corpos.jpg` e `corpos_silhueta.jpg` (1920×1080, 6×3 células).
- **A escala:** a porta do Castle Kit (0,61 m) fica em 1,71 m com o `K = 2,0`, contra o boneco de 1,52 m; o fator ficou em 1,4.
- **Os documentos:** 14 (o Graveyard «sem pele; são monstros», o Mini Arena fora, a cauda da raposa, o script), 13, 11 e `DESENVOLVER.md`; a B1 da G08
  aponta o comando de verdade.
- **As provas:** `_prova_do_kit()` no `prova_do_jogo.gd` (o caminho, a escala por pasta, o orc, a raposa, os 12, o esqueleto, nada solto na raiz); a mordida (sem pasta padrão, sem a multiplicação, uma peça solta) reprovou 4 checagens e as curas voltaram.

### Desvios e decisões (a validar por ela)

- **O fantasma não passa no conferidor.** A ficha dizia que os cinco do Graveyard passam como rígido; o `character-ghost` não tem as pernas nem a
  cabeça separada (faltam `leg-left`, `leg-right`, `head`), e o script o recusa como manda a ficha. Entram o esqueleto, o zumbi, o vampiro e o coveiro. O minigame 32 decide o que
  fazer com o fantasma (aceitar sem conferidor, ou outro monstro).
- A prancha mostra o vampiro no lugar do fantasma; a cauda aparece a 0,33× (a escala da G13).
- O `colormap.png` com `compress/mode=0` (antes `2`, VRAM) deixa a paleta sem perda. A prova visual de antes e depois (partida fixa de 5 salas) reprova o mesmo tipo de defeito de texto da F09b (30 antes, 28 depois, nenhum novo, nenhum de peça ou textura); não comparei pixel a pixel.
- `VIOLETA_FUNDO` ainda não é token do `Tema`: a prancha o declara como constante local.

### O que fica para a mão dela e do André

- Abrir `docs/imagens/kenney/corpos.jpg` e `corpos_silhueta.jpg`: o orc se separa dos 12 pela cabeça, e os monstros se leem como monstros.
- Anotar no diário qualquer malha que pareça de outro jogo.

### A conferência (leva 1, o-cavaleiro)

- **Corrigido:** o pacote de um modelo só (o Cube Pets) dizia «1 modelos» no `LEIA-ME.md`; o script escreve o singular.
- **Visto:** numa árvore já aberta antes da mudança, o Godot avisa «invalid UID» do `colormap.png` ao ler as peças (a importação velha guardou outro
  id). Num checkout limpo, importado do zero, as peças do Mini Dungeon, o orc, a porta do Castle Kit e a raposa carregam sem aviso.
- Ficam como estão: `MALHA_DO_ITEM` não passa por `Kit.caminho` (é `const`), e o fator do Castle Kit em 1,4 é para ela ver na prancha.
