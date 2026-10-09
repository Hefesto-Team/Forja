# X07 — O pacote do kit de minigame

**Sprint:** X · **Tamanho:** G · **Depende de:** X03, X04, X06, H04, H08, a seção I feita

## Por quê

O kit é o que deixa escrever um minigame de festa em uma tarde; hoje ele só existe dentro do Forja, com 55 chamadas ao autoload do jogo.

## Ler antes

- [15 — O kit de minigame](../15-os-modulos.md#7-o-kit-de-minigame--forja_minigame)
- [13 — O kit do minigame](../13-arquitetura.md#o-kit-do-minigame--h04)
- [H08 — Os acréscimos do kit](H08-os-acrescimos-do-kit.md)

## O estado de hoje

- `godot/scripts/salas/sala.gd` (`Sala`, `signal terminou`), `godot/scripts/salas/sala_jogo.gd` (`SalaJogo`: 55
  chamadas a `Forja.`, mais `Som`, `Musica`, `Kit`, `Efeitos`, `TelaResultado`).
- Depois da H04 e da H08: `godot/scripts/minigames/minigame.gd` (`Minigame`) e `catalogo.gd` (`Catalogo`, com as
  seções em constante).

## Arquivos que mudam

- `godot/addons/forja_minigame/` (novo): `sala.gd` (`ForjaSala`), `sala_jogo.gd` (`ForjaSalaJogo`), `minigame.gd`
  (`ForjaMinigame`), `catalogo.gd` (`ForjaCatalogo`)
- `godot/scripts/minigames_do_forja.gd` (novo: o conector que atende `pediu_som`, `pediu_faixa`, `resultado` e entrega
  o montador das raias com o `Kit`)
- todos os minigames em `godot/scripts/minigames/` (o `extends`, por script)

## Passos

1. Mover as quatro classes com `git mv`, com o prefixo.
2. As chamadas ao `Forja` passam para `ForjaControle`; o som, a música e a tela de resultado viram sinais atendidos pelo conector.
3. O `Catalogo` ganha `registrar(id, script)`; o Forja registra os dele no conector.
4. A prova do pacote: um minigame de mentira com a FICHA mínima entra, joga com o robô e termina com vencedor, sem o Forja.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_minigame` passa com os quatro pacotes de que ele depende, e a prova do jogo passa igual.

## Provas

- `bash tests/prova_do_importavel.sh forja_minigame`
- `bash tests/prova_do_jogo.sh` e `bash tests/prova_de_poucos.sh`
- `bash tests/prova_visual.sh`
