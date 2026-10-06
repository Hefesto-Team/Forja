# G10 — A biblioteca Kenney

**Sprint:** G · **Tamanho:** G · **Depende de:** F00, G08 (a parte A e o `scripts/conferir_bonecos.py`)

## Por quê

O André vai comprar o Kenney All-in-1. Esta ficha põe no jogo **só** o que a
curadoria aprovou, um pacote por pasta, com um script que qualquer pessoa
roda de novo — e entrega os doze bonecos do Mini Characters.

## Ler antes

- [14 — os assets da Kenney](../14-os-assets-kenney.md) (a curadoria, como entra, recolorir)
- [11 — a arte e os personagens](../11-arte-e-personagens.md) (as regras e o checklist)
- [G08](G08-a-arte-bonecos-e-coerencia.md) (o conferidor de bonecos e `BONECOS`)

## O estado de hoje

- Os 30 `.glb` do Mini Dungeon estão soltos em `godot/assets/kenney/`, com
  `godot/assets/kenney/Textures/colormap.png` e `KENNEY-LICENSE.txt`.
- Quatro scripts montam o caminho à mão, com `"res://assets/kenney/%s.glb"`:
  - `godot/scripts/mundo/kit.gd:6` — `const CAMINHO := "res://assets/kenney/%s.glb"`, usado por `Kit.peca(pai, nome, pos, rot_y, escala)` (`kit.gd:11`);
  - `godot/scripts/mundo/salao.gd:11` — `const KIT := "res://assets/kenney/%s.glb"`;
  - `godot/scripts/player.gd:114` e `:147` — o boneco e a peça na mão;
  - `godot/scripts/salas/prova.gd:174` — o orc de treino.
- `godot/assets/LEIA-ME.md:10` e `LICENCAS-DE-TERCEIROS.md:14` e `:93`
  registram o Mini Dungeon.
- O `scripts/conferir_bonecos.py` (G08) confere os sete ossos e as animações
  de um `.glb`.

## O alvo

```
godot/assets/kenney/
  mini-dungeon/      GLB format → *.glb, Textures/colormap.png, License.txt
  mini-characters/   os 12 personagens
  mini-arena/        (quando uma ficha de minigame pedir)
  mini-market/
  castle-kit/
  tower-defense-kit/
```

- `Kit.peca(pai, "castle-kit/tower-base", ...)`: o pacote antes da barra;
  sem barra, vale `mini-dungeon` (as salas de hoje não mudam uma linha).
- `const ESCALA_DO_PACOTE := {"castle-kit": 1.4, "survival-kit": 1.4, "factory-kit": 0.5, "building-kit": 0.35, "pirate-kit": 0.4, "cube-pets": 0.4, "blaster-kit": 0.3, "modular-dungeon-kit": 0.25, "modular-cave-kit": 0.25, "modular-space-kit": 0.25}`
  em `kit.gd`: `Kit.peca` multiplica a escala pedida pelo fator do pacote
  (os outros, 1×). Os valores vêm das medidas do
  [14](../14-os-assets-kenney.md#a-escala-de-cada-kit) e se ajustam olhando
  a prancha ao lado de um boneco.
- `Kit.caminho(nome) -> String` numa função só, usada pelos quatro scripts.
- `scripts/importar_kenney.py`:

  ```
  python3 scripts/importar_kenney.py <zip ou pasta do All-in-1> <pacote> [<pacote>...]
  python3 scripts/importar_kenney.py --lista          # o que a curadoria aceita
  ```

  - `APROVADOS` = os da coluna "entra" do [14](../14-os-assets-kenney.md#a-curadoria)
    (os 39 kits com colormap, a série Mini, a interface e o áudio), com o
    nome da pasta no zip e o nome da pasta de destino em minúsculas com
    hífen (`castle-kit`, `graveyard-kit`, `mini-characters`…);
  - acha a pasta do pacote dentro do zip ou da pasta (os nomes do All-in-1
    têm a categoria na frente, como `3D assets/Mini Characters/`);
  - copia só `Models/GLB format/*.glb` e a pasta `Textures/` (ou onde o
    pacote os tiver — o script procura o `.glb` e a `Textures/` irmã) e o
    `License.txt`;
  - em pacote de personagem (a série Mini e os `character-*` do Graveyard
    Kit), roda `conferir_bonecos.py` em cada `.glb` de personagem e **não
    copia** o que reprova;
  - em pacote de áudio, converte `.ogg` para WAV 48 kHz mono em
    `godot/assets/sons/<pacote>/` (com `ffmpeg` se houver; se não houver, diz
    como instalar e para);
  - escreve (ou atualiza) a linha do pacote em `godot/assets/LEIA-ME.md` e em
    `LICENCAS-DE-TERCEIROS.md`, com o nome, a versão (do `License.txt`) e CC0;
  - recusa pacote fora de `APROVADOS`, com a frase "fora da curadoria: veja
    docs/jogo/14".

## Passos

1. **Mudar o Mini Dungeon de pasta:** `git mv` dos `.glb`, `Textures/` e
   `KENNEY-LICENSE.txt` para `godot/assets/kenney/mini-dungeon/`. Apagar os
   `.import` antigos (o Godot refaz) e rodar
   `"$GODOT" --headless --path godot --import --quit`.
2. **Um caminho só:** em `godot/scripts/mundo/kit.gd`, trocar
   `const CAMINHO` por `static func caminho(nome: String) -> String` (sem "/"
   → `"res://assets/kenney/mini-dungeon/%s.glb"`; com "/" →
   `"res://assets/kenney/%s.glb"`), e usar em `Kit.peca`. Em `salao.gd:11`,
   `player.gd:114` e `:147` e `prova.gd:174`, chamar `Kit.caminho(...)`.
3. `bash tests/prova_do_jogo.sh` tem de passar igual: nada visível mudou.
4. **Escrever `scripts/importar_kenney.py`** (Python 3, só a biblioteca
   padrão: `zipfile`, `shutil`, `pathlib`, `subprocess` para o `ffmpeg` e o
   conferidor), com uma prova própria `scripts/testes/prova_importar.py` que
   monta um zip de mentira com a estrutura do All-in-1 e confere: copia só
   GLB e Textures, recusa pacote fora da lista, não copia boneco que o
   conferidor reprova, escreve as duas linhas de licença.
5. **Com o zip do André:** `python3 scripts/importar_kenney.py <zip> mini-characters`.
   Registrar os 12 em `BONECOS` de `godot/scripts/player.gd` (a estrutura da
   G08), cada um com nome em português ("Ferreira", "Mestre", "Aprendiz"…) e
   um pio próprio (`Som.pio`).
6. **Os kits de cenário** entram quando a primeira ficha de minigame pedir
   (a tabela dos 45 no [14](../14-os-assets-kenney.md#os-kits-nos-45-minigames)
   diz qual); esta ficha importa só o Castle Kit, o Factory Kit e o
   Graveyard Kit (os três mais usados na tabela) e confere que uma peça de
   cada abre no Godot, na escala certa ao lado de um boneco.
7. **A parte B da G08** passa a ser "rodar esta ficha": atualizar a G08 para
   apontar para cá.
8. Atualizar `docs/jogo/13-arquitetura.md` (`Kit.caminho`, a pasta por
   pacote) e `docs/DESENVOLVER.md` (o comando do script).

## Armadilhas

- **O `colormap.png` com o mesmo nome** em todo pacote: nunca juntar duas
  pastas; a prova confere que cada `Textures/colormap.png` fica na pasta do
  seu pacote.
- **A textura sem compressão e com filtro nearest:** conferir o `.import` do
  `colormap.png` de cada pacote (o Godot pode importar com compressão VRAM);
  se preciso, um `.import` padrão escrito pelo script.
- **O zip do All-in-1 não entra no repositório** (e nem a pasta dele): o
  script lê de fora e o `.gitignore` não precisa mudar.
- **Early access fica fora** (não está em `APROVADOS`).
- **O `git mv` do Mini Dungeon muda caminho de arquivo que as provas e as
  fotos podem citar:** `grep -rn "assets/kenney" godot tests scripts docs`
  antes de commitar.
- O Mini Characters tem as mesmas 32 animações, mas **confira** com o
  conferidor: um boneco que reprova não entra, mesmo que pareça igual.

## Não fazer

- Não importar o pacote inteiro "para ver depois".
- Não usar Blocky Characters nem Animated Characters.
- Não editar o `colormap.png` original; recolorir é cópia (14).

## Pronto quando

O Mini Dungeon mora em `godot/assets/kenney/mini-dungeon/` e o jogo não mudou;
o script importa o Mini Characters e a construção do cavaleiro oferece pelo
menos doze bonecos; o Castle Kit e o Tower Defense Kit estão importados; as
licenças estão registradas; e a prova visual passa com os bonecos novos.

## Provas

- Na sessão: `python3 scripts/testes/prova_importar.py`,
  `bash tests/prova_do_jogo.sh`, e uma checagem nova em
  `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  _esperar(Kit.caminho("floor") == "res://assets/kenney/mini-dungeon/floor.glb", "kit: sem pacote, o mini-dungeon")
  _esperar(Kit.caminho("castle-kit/tower-base") == "res://assets/kenney/castle-kit/tower-base.glb", "kit: o pacote antes da barra")
  _esperar(ResourceLoader.exists(Kit.caminho("floor")), "kit: o mini-dungeon abre da pasta nova")
  ```

- Com o André, local: rodar o script com o zip de verdade, `bash tests/prova_visual.sh`,
  e olhar os doze bonecos na construção, com placa de vídeo (a aparência é
  dele).

## Para o André (local)

Baixar o All-in-1, rodar `python3 scripts/importar_kenney.py <zip> mini-characters castle-kit tower-defense-kit`,
abrir o jogo e escolher boneco. Anotar no diário qualquer boneco que pareça
de outro jogo.

## Ao terminar

Marcar G10 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `feat: a biblioteca Kenney — um pacote por pasta, o script de importação e os doze bonecos`.
