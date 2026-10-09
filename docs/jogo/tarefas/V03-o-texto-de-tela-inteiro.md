# V03 — O texto de tela inteiro, e a tabela em partes

**Sprint:** V · **Tamanho:** G · **Depende de:** F07, F08

## Por quê

O portão do texto de tela só lê a tabela de traduções: uma frase desenhada que nunca entrou nela sai em português na
tela em inglês, e passa verde. E a tabela é um arquivo só que 31 fichas editam.

## Ler antes

- [06 — A voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto)
- [F07 — A voz nova do texto](F07-a-voz-do-texto.md) (o portão de hoje)
- [13 — As convenções](../13-arquitetura.md#as-convenções)

## O estado de hoje

- `scripts/check_texto_de_tela.py` (30 linhas) lê `const EN` e `const EN_PADROES` de `godot/scripts/traducoes.gd`
  e confere maiúscula e chave repetida. Não olha as chamadas de desenho.
- Medido em 08/10/2026 (literal dentro de `Desenho.texto/selo/paragrafo` ou `Glifo.dica`, sem entrada exata nem
  padrão que case), tirando ids de glifo (`cruz`, `triangulo`, `conexao_curta`) e a marca (`Hefesto`, `Tech Demo`):
  - `godot/scripts/ui/diagnostico.gd:52` «AO VIVO», `:53` «O que cada controle manda ao jogo, e o que o jogo manda
    a ele.», `:118` «Entrada», `:153` «Saída»;
  - `godot/scripts/ui/livro.gd:120` «Não medido.», `:127` «Quem mede é %s.», `:162` «✓ passou», `:164` «✗ falhou»,
    `:168` «não medido» (minúscula);
  - `godot/scripts/ui/painel_bancada.gd:33` «experimental/ · a bancada dos experimentos» e `:56` «todos» (as duas
    com minúscula, contra a F07).
- `godot/scripts/traducoes.gd` tem 387 linhas; `grep -l traducoes.gd docs/jogo/tarefas/*.md | wc -l` dá 31.

## O alvo

- `traducoes.gd` guarda só o motor (`traduzir`, os padrões compilados) e junta as tabelas de
  `godot/scripts/textos/<area>.gd` (`titulo`, `lobby`, `opcoes`, `hud`, `bancada`, `salas`, uma por minigame quando
  a H04 criar o slot): cada uma com `const EN := {}` e `const EN_PADROES := []`. A ordem de junção é alfabética e
  uma chave repetida entre duas tabelas é erro do portão.
- O portão lê todas as tabelas e, além disso, varre `godot/scripts/**/*.gd` atrás de literal desenhado sem entrada.
  As exceções (ids de glifo, a marca) ficam numa lista em `scripts/portoes/texto_de_tela.json`, com o motivo de cada
  uma.

## Arquivos que mudam

- `godot/scripts/traducoes.gd` (de todos: esta ficha vai sozinha, depois da F08)
- `godot/scripts/textos/*.gd` (novos, com `.uid`)
- `godot/scripts/ui/diagnostico.gd`, `godot/scripts/ui/livro.gd`, `godot/scripts/ui/painel_bancada.gd` (maiúscula)
- `scripts/check_texto_de_tela.py`, `scripts/portoes/texto_de_tela.json` (novo)
- `tests/prova_dos_portoes.sh` (o caso ruim novo: literal desenhado sem entrada)

## Passos

1. Dividir `const EN` pelos comentários de área que já existem nele (`# o título, os créditos, o lobby` e os
   seguintes), sem mudar uma frase.
2. `Traducoes` junta as tabelas na primeira chamada de `traduzir`.
3. Dar entrada em inglês às onze frases medidas e subir a primeira letra das três com minúscula.
4. O portão ganha a varredura das chamadas de desenho e a lista de exceções.
5. A prova dos portões ganha o caso: uma pasta temporária com uma sala que desenha «Sem entrada» faz o portão sair 1.

## Pronto quando

`python3 scripts/check_texto_de_tela.py` diz `0 sem entrada` e sai 0, e a cópia com a frase ruim sai 1.

## Provas

- `python3 scripts/check_texto_de_tela.py`
- `bash tests/prova_dos_portoes.sh`
- `bash tests/prova_do_jogo.sh` (a `_prova_das_frases` e a `_prova_das_maiusculas` seguem verdes)
