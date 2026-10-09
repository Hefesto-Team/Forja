# X01 — O pacote do texto de tela

**Sprint:** X · **Tamanho:** M · **Depende de:** V03

## Por quê

O desenho de texto e a tradução são o que todo outro pacote usa, e hoje leem o `Tema` do Forja direto: nenhum pacote sai antes deste.

## Ler antes

- [15 — O texto de tela](../15-os-modulos.md#1-o-texto-de-tela--forja_texto)
- [V03 — O texto de tela inteiro](V03-o-texto-de-tela-inteiro.md)

## O estado de hoje

- `godot/scripts/ui/desenho.gd` (`Desenho`) lê `Tema.RAIO_QUADRO`, `Tema.T_SELO`, `Tema.T_ROTULO` e `Tema.fonte()`
  (por exemplo nos padrões de `moldura` `:41` e `selo` `:136`); `godot/scripts/ui/glifo.gd` (`Glifo`) idem.
- `godot/scripts/traducoes.gd` tem o motor (`traduzir`, `:358`) e a tabela juntos (a V03 separa a tabela por área).

## Arquivos que mudam

- `godot/addons/forja_texto/` (novo): `plugin.cfg`, `plugin.gd`, `desenho.gd` (`ForjaDesenho`), `glifo.gd` (`ForjaGlifo`),
  `traducao.gd` (`ForjaTraducao`), `estilo.gd` (`ForjaEstilo`), `LEIA-ME.md`, `LICENSE`, `testes/prova.gd`
- `godot/scripts/ui/desenho.gd`, `godot/scripts/ui/glifo.gd`, `godot/scripts/traducoes.gd` (saem, ou ficam como ponte de uma linha até a última
  chamada mudar; a ficha decide pelo `git grep`: zero chamada antiga, sai)
- toda chamada `Desenho.`/`Glifo.`/`Traducoes.` em `godot/scripts/**` (troca por script, `sed`, num commit só)
- `godot/project.godot` (o plugin ligado)
- `tests/prova_do_importavel.sh` e `scripts/empacotar_addon.sh` (novos: nascem nesta ficha e servem a todas da X)

## Passos

1. Criar o pacote e mover os três arquivos com `git mv` (a história segue).
2. Trocar as leituras de `Tema.*` por `ForjaDesenho.estilo.*`; o `main` monta o `ForjaEstilo` a partir do `Tema` no `_ready`.
3. Renomear as chamadas no jogo por script (`git grep -l 'Desenho\.' godot/scripts | xargs sed -i ...`).
4. Escrever `tests/prova_do_importavel.sh <nome>` (projeto vazio em pasta temporária, só o pacote, `--headless` com `testes/prova.gd`).
5. Escrever `scripts/empacotar_addon.sh <nome>`.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_texto` passa num projeto que não tem nada do Forja, e a prova do jogo passa igual.

## Provas

- `bash tests/prova_do_importavel.sh forja_texto`
- `bash tests/prova_do_jogo.sh`
- `bash tests/prova_visual.sh` (as telas iguais; as pranchas olhadas)
