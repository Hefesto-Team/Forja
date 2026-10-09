# G14b — As cores de luz que sobraram

**Sprint:** G · **Tamanho:** P · **Depende de:** G14, G15

## Por quê

A G14 tirou toda cor 2D escrita fora do tema, mas deixou cores que são luz (a lightbar das perguntas, a chama, a luz
das equipes) e a cor do cenário 3D, porque não há token de luz no [02](../arte/02-cor-e-letra.md) e a luz é da G15.
Sobram cerca de 29 linhas que a regra de palavras 3D do portão de arte não cobre.

## O estado de hoje

- Luz do controle nas perguntas: `CORES` em `salas/impacto.gd:32` e `salas/prova.gd:55` (âmbar, ciano, violeta, branco),
  `NEUTRO` em `impacto.gd:39`, a chama `Color(1, 0, 0)` em `impacto.gd:512` e `prova.gd:258`, `LUZ_EQUIPE` em `prova.gd:63`.
- Cenário e luz de sala: `atmosfera(Color(...))` em `caminhos`, `canto`, `centelha`, `galeria`, `impacto`, `molde`,
  `prova`, `viga`, `voz`; `sino` em `canto`; `Kit.chapado` em `viga:238`; `cor_metal` em `molde:342`; `faiscas` e
  `_tingir` em `prova`.
- **Conflito:** as cores das perguntas «ciano» e «âmbar» agora são as mesmas dos lugares P1 (ciano) e P4 (âmbar). O
  comentário diz «longe das cores dos lugares», e o `COR_PARECIDA` e a pergunta «Brasa ou Maré» dependem disso.

## O que fazer

- Decidir o token de luz (ou usar os da G15) e trocar estas linhas.
- Pôr as cores das perguntas fora das quatro cores de lugar, ou mudar a pergunta para não depender da cor.

## Pronto quando

- O portão de arte não acusa mais cor nessas linhas.
- Nenhuma cor de pergunta é igual à de um lugar, e há prova que confere.
