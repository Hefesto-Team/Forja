# WT05 — Um lugar só para os estados da ficha

**Sprint:** W · **Tamanho:** M · **Depende de:** [WT04](WT04-as-regras-da-casa-no-repositorio.md) (mexe no 12 e no
COMO-CONTRIBUIR também); não voar com a esteira despachando (o `scripts/esteira.py` lê o quadro a cada volta)

## Por quê

O estado de uma ficha está escrito de quatro jeitos. O 12 manda marcar **fazendo** e **feito**; o quadro diz que há
três estados; a a-esteira tem sete; o `scripts/esteira.py` aceita oito; e o quadro já tem uma linha em
«espera o André», que não está em lista nenhuma. Quem pega uma ficha segue o 12 e escreve **fazendo**, a esteira lê
e pode pular ou repetir. E o mapa dos documentos promete o gasto de cada ficha no quadro, que não tem gasto, e o
quadro manda ler «a faixa» no 12, que não fala de faixa.

## Ler antes

- [A esteira, «Os estados de uma ficha»](../o-time/a-esteira.md#os-estados-de-uma-ficha)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `docs/jogo/12-como-trabalhar.md:24` («marcar **fazendo**») e `:30` («marcar a ficha **feito**»).
- `docs/jogo/tarefas/README.md:8-9`:
  ```markdown
  Estados: **a fazer**, **fazendo** (com o nome de quem pegou), **feito**
  ```
- `docs/jogo/o-time/a-esteira.md:7-21`: `a fazer → enriquecida → pronta → em voo → conferida → jogada → feito`.
- `scripts/esteira.py:65`:
  ```python
  ESTADOS = ["a fazer", "enriquecida", "pronta", "em voo", "fazendo", "conferida", "jogada", "feito"]
  ```
- `docs/jogo/tarefas/README.md:29`, a F10: «espera o André (a parte A feita: …)».
- `docs/jogo/README.md:35`: «com o estado e o gasto de cada uma»; `docs/jogo/tarefas/README.md:202`: «a faixa está em
  [Como trabalhar](../12-como-trabalhar.md#o-orçamento)», e a seção «O orçamento» (`12:88-92`) não tem faixa.
- `scripts/costura.sh:15` marca «feito» depois da costura; não há comando para marcar outro estado.

## O alvo

A a-esteira é a única dona da lista de estados (com **espera o André** entrando nela, como estado de quem depende da
mão dele). O 12, o quadro e o COMO-CONTRIBUIR apontam para ela. O `esteira.py` lê o estado da linha e sai 2, com a
linha, diante de um estado que não está na lista. `scripts/costura.sh --marcar <ficha> <estado>` muda a linha do
quadro, recusando estado desconhecido. O mapa e o quadro não prometem o que não existe.

## Arquivos que mudam

- `docs/jogo/o-time/a-esteira.md` (a lista, com o estado novo)
- `docs/jogo/12-como-trabalhar.md`, `docs/jogo/tarefas/README.md`, `docs/COMO-CONTRIBUIR.md` (o link no lugar da lista)
- `docs/jogo/README.md` (a linha 35)
- `scripts/esteira.py`, `scripts/costura.sh`
- `tests/prova_da_esteira.sh` (as mordidas)

## Passos

1. Na a-esteira, a lista ganha **espera o André**, e uma frase diz que quem trabalha à mão marca **em voo** com o
   nome (o que hoje se chama **fazendo**).
2. O 12 (passos 1 e 5), o cabeçalho do quadro e o COMO-CONTRIBUIR trocam a lista própria por um link para a
   a-esteira. «fazendo» segue aceito na leitura como sinônimo de «em voo», para não quebrar linha antiga.
3. O `esteira.py`: a lista sai da a-esteira (ou fica no script com uma prova que compara as duas); estado
   desconhecido sai 2 com a ficha e o texto.
4. `costura.sh --marcar <ficha> <estado>`: troca a última coluna da linha da ficha no quadro.
5. O mapa (`docs/jogo/README.md:35`) diz «com o estado de cada uma»; a linha 202 do quadro aponta para onde o
   gasto da leva está de fato, ou sai.
6. As mordidas: um quadro de mentira com «quase pronta» faz o `esteira.py` sair 2; a lista da a-esteira e a do
   script são iguais; o `--marcar` recusa «quase pronta».

## Armadilhas

- **A esteira em voo** lê o quadro: costurar esta ficha com a esteira parada.
- **Estado com texto depois** («feito, sem a parte B», «espera o André (a parte A feita…)»): o `estado_de` de hoje
  já separa o começo; manter esse jeito e testar os dois casos.
- **A WT04** também mexe no 12 e no COMO-CONTRIBUIR: uma depois da outra.

## Não fazer

- Não mudar o estado de nenhuma ficha do quadro.
- Não inventar o gasto por ficha: se a medida não existe, o mapa não a promete.

## Pronto quando

`bash tests/prova_da_esteira.sh` passa com as mordidas do passo 6 (hoje um estado desconhecido passa calado), e
`grep -n 'fazendo' docs/jogo/12-como-trabalhar.md docs/jogo/tarefas/README.md` só acha o link ou o sinônimo.

## Provas

- `bash tests/prova_da_esteira.sh`, `bash scripts/portoes/rodar.sh`.

## Para o André (local)

Rodar `bash scripts/costura.sh --marcar F10 "espera o André"` numa árvore à parte e conferir que só a linha da F10
mudou.

## Ao terminar

Pôr a linha da WT05 no [quadro](README.md) como **feito**, com o commit (pelo `--marcar`).

## O que foi feito (leva 1, as-regras)

- **A lista mora na a-esteira**, «Os estados de uma ficha», com **espera o André** (o que dava para fazer sem ele está
  feito; o texto depois diz o quê) e a frase de que quem trabalha à mão marca **em voo** com o nome; **fazendo** segue
  aceito na leitura como sinônimo. O 12 (passos 1 e 5), o cabeçalho do quadro e o COMO-CONTRIBUIR apontam para ela;
  `grep -n 'fazendo' docs/jogo/12-como-trabalhar.md docs/jogo/tarefas/README.md` não acha nada.
- **O `scripts/esteira.py`:** a `ESTADOS` ficou no script (`a fazer` a `feito`, mais `espera o André`; o `fazendo`
  passou para `SINONIMOS`), e a prova compara as duas listas. Estado fora da lista sai 2 com a ficha e o texto; o
  estado com texto depois segue pelo começo, agora com a palavra inteira («prontamente» não é «pronta»). Sobre o
  quadro de hoje, a saída só muda na F10, que passa a ler «espera o André» em vez da célula inteira.
- **`bash scripts/costura.sh --marcar <ficha> <estado> [--integracao DIR]`** chama o `esteira.py --marcar`, que troca
  a última coluna da linha e recusa, sem mudar nada, o estado fora da lista, o que tem `|`, e a ficha que o quadro não
  tem (ou tem duas vezes).
- **O mapa e a soma:** o `docs/jogo/README.md` diz «com o estado de cada uma»; a «A soma» do quadro, que mandava ler
  uma faixa que o 12 não tem, aponta para onde o gasto existe: a esteira o registra no ANDAMENTO de quem coordena, por
  seção (a validar por ela: o gasto por ficha não existe e não foi inventado).
- **Provas:** `bash tests/prova_da_esteira.sh`, 44 casos, dez novos. Com o `esteira.py` e o `costura.sh` de antes,
  cinco reprovam (as listas, «quase pronta» que sai 2 e diz a ficha, o estado com texto depois, a troca de uma linha
  só); com o `--marcar` sem a recusa, os dois da recusa; com o estado lido inteiro, sem o começo, o estado com texto
  depois. A ficha que o quadro não tem sai 2 também no script de antes (que não conhece o `--marcar`).
- **Não mudou** o estado de nenhuma ficha. A costura desta ficha pede a esteira parada (ela lê o quadro a cada volta).
- **Para o André:** numa árvore à parte, `bash scripts/costura.sh --marcar F10 "espera o André"` e `git diff`: só a
  linha da F10 muda (e perde o texto entre parênteses, que o `--marcar` troca pelo que se passou).
