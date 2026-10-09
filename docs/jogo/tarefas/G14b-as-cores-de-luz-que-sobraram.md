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

## O que foi feito (leva 1, as-telas)

- **A medida antes:** o portão de arte acusava 38 cores; 35 nas salas desta ficha (e n'A Centelha, hoje
  `minigames/s01/martelo_de_hefesto.gd`), 3 em `itens.gd`. A pergunta «ciano» ficava a ΔE OKLab 0,06 do P1 e a
  «âmbar» a 0,028 do P4.
- **O token de luz:** `tema.gd` ganhou a seção «a luz que não é de lugar» (`PERGUNTA`, `LANTERNA_NEUTRA`, `ALARME`,
  `EQUIPE`, `AR` por sala, `BRONZE`, `BRONZE_CLARO`, `METAL_*`, `OURO`, `FAISCA`, `RACHA`, `BONECO_DE_TREINO`), com
  a mesma tabela no [02](../arte/02-cor-e-letra.md#a-luz-que-não-é-de-lugar) e no `scripts/portoes/arte.json`. As
  cores do cenário guardam o valor de antes; só muda o que a ficha pediu.
- **A pergunta:** verde `#00c853`, azul `#1f3dff`, violeta `#ab45ff`, branco (a ordem dos botões não muda). O ΔE
  mais perto de um lugar é 0,206. `COR_PARECIDA` d'A Prova passa a `[-1, 1]`: nenhuma lembra a Brasa, o azul lembra
  a Maré. O vermelho do golpe e o do susto d'A Voz são o mesmo `ALARME` (o da Voz era `#ff140a`).
- **A prova:** `_prova_das_cores_da_pergunta()` em `prova_do_jogo.gd` confere ΔE ≥ 0,15 de cada cor de pergunta até
  os quatro lugares e que `COR_PARECIDA` é a única cor perto da luz da equipe. Mordeu com o âmbar de volta.
- **Depois:** o portão de arte acusa só as 3 linhas de `itens.gd` (fora desta ficha).
- **Para a mão dela ou do André:** com um DualSense, O Impacto e A Prova: a luz da pergunta (verde, azul) não se
  confunde com a luz do lugar.
