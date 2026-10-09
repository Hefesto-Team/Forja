# WT01 — O «Ler antes» pela âncora

**Sprint:** W · **Tamanho:** M · **Depende de:** nada (mexe nas fichas I a Q: não voar junto com um conjunto de
minigame em voo; trocar só os links, nunca o corpo)

## Por quê

A regra das fichas é «ler a ficha e os links do Ler antes, e só eles». Mas o link aponta para o arquivo inteiro: a
ficha I2 manda ler a [H04](H04-o-kit-do-minigame.md), uma ficha já feita de 43.695 caracteres, quando o que importa
dela está numa seção do [13](../13-arquitetura.md#o-kit-do-minigame--h04). A mediana do que uma ficha manda ler antes
é de 78 mil caracteres; com o link pela âncora, cai para uns 37 mil. É metade da leitura de cada pessoa (e de cada
execução) que pega uma ficha, e a ficha feita ainda ensina código velho: a «O estado de hoje» da H04 cita a
`const SALAS` em `main.gd:13-24`, que hoje é a `ORDEM_DO_FOGO`.

## Ler antes

- [A ficha pronta](../o-time/ficha-pronta.md) (o que o portão confere no «Ler antes»)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `docs/jogo/tarefas/I2-marcha-dos-escudeiros.md:13`:
  ```markdown
  - [H04 — O kit do minigame](H04-o-kit-do-minigame.md) (o `minigame.gd` e o minigame de prova, o exemplo pequeno)
  ```
  O mesmo link de I2 a I5; de J2 a J5, para a [H08](H08-os-acrescimos-do-kit.md) (77.631 caracteres).
- As seções que dizem o mesmo, no 13: `### O kit do minigame — H04` (`docs/jogo/13-arquitetura.md:279`) e
  `## As decisões comuns dos minigames — H08` (`:639`).
- 90 links do «Ler antes» sem âncora, em todo o quadro.
- `scripts/portoes/ficha_pronta.py:91-101` confere só que o «Ler antes» tem de um a três links e que o arquivo
  existe; não olha a âncora nem o tamanho nem se o alvo é uma ficha feita.
- Não há como imprimir só a seção de um link: quem lê abre o arquivo inteiro.

## O alvo

`python3 scripts/ler_antes.py <ficha>` imprime, para cada link do «Ler antes», só a seção da âncora (do título até o
próximo título do mesmo nível ou maior), ou o arquivo inteiro quando é pequeno e sem âncora. O portão da ficha pronta
reprova o link sem âncora para arquivo de mais de 20 KB e o link para uma ficha marcada **feito** no quadro. As fichas
I a Q apontam para a seção, não para a ficha feita.

## Arquivos que mudam

- `scripts/ler_antes.py` (novo)
- `scripts/portoes/ficha_pronta.py`
- `tests/prova_dos_portoes.sh` (as mordidas)
- as fichas `docs/jogo/tarefas/I2-*.md` a `Q5-*.md`, só a seção «Ler antes»
- `docs/jogo/o-time/ficha-pronta.md` (a regra nova, uma linha)

## Passos

1. O `scripts/ler_antes.py`: acha a seção «Ler antes» da ficha, resolve cada link relativo à pasta dela, converte a
   âncora para o título do jeito do GitHub (minúsculas, sem pontuação, espaço vira hífen, o travessão some e sobram
   dois hífens) e imprime a seção com o cabeçalho «== caminho#âncora (N caracteres) ==». Âncora que não casa: sai 1
   com o nome do link.
2. No `ficha_pronta.py`: link sem âncora para arquivo de mais de 20 KB, link para ficha **feito** no quadro e âncora
   que não existe viram achado da ficha pronta.
3. Trocar os links: I2 a I5 para `../13-arquitetura.md#o-kit-do-minigame--h04`; J2 a J5 para
   `../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08`; K a Q para a seção do cenário da ficha n.º 1 da
   própria seção (por exemplo, `K1-o-molde.md#a-cena`), não para a ficha inteira.
4. As mordidas na prova dos portões: uma ficha de mentira com link sem âncora para um arquivo de 30 KB reprova; com a
   âncora, passa; com âncora errada, reprova.
5. Medir de novo a mediana com o `ler_antes.py` sobre as fichas I a Q e escrever o número na linha do quadro.

## Armadilhas

- **A âncora com acento.** O GitHub mantém as letras acentuadas na âncora (`as-decisões-comuns…`): o script e o
  portão usam a mesma função, e a prova testa um título com acento e um com travessão.
- **Link para código** (`godot/scripts/salas/molde.gd`, na K1) não tem âncora: o limite de 20 KB vale igual, e o
  script imprime o arquivo inteiro quando é pequeno.
- **Ficha em voo**: trocar o «Ler antes» de uma ficha que um conjunto está fazendo agora gera conflito na costura.
  Conferir o quadro e pular as fichas **em voo**; elas entram depois.

## Não fazer

- Não reescrever o corpo de nenhuma ficha nem consertar a «O estado de hoje» da H04: ela é feita, fica como registro.
- Não aumentar o limite de três links.

## Pronto quando

`bash scripts/portoes/rodar.sh` não acha link sem âncora para arquivo grande nas fichas I a Q (hoje acharia 90 em
todo o quadro), e `python3 scripts/ler_antes.py docs/jogo/tarefas/I2-marcha-dos-escudeiros.md` imprime menos da
metade dos caracteres de hoje.

## Provas

- `bash tests/prova_dos_portoes.sh` (as mordidas).
- `bash scripts/portoes/rodar.sh`.

## Para o André (local)

Rodar `python3 scripts/ler_antes.py docs/jogo/tarefas/J3-*.md` e conferir que a saída é o que ele leria para fazer a
ficha, e nada da H08 que não importa.

## Ao terminar

Pôr a linha da WT01 no [quadro](README.md) como **feito**, com o commit e a mediana nova, e dizer no
[12](../12-como-trabalhar.md) que o «Ler antes» se lê pelo `scripts/ler_antes.py`.
