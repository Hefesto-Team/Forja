# Y03 — O repositório nasce vivo: a chamada do `aplicar.py` na Forja

**Sprint:** Y · **Tamanho:** P · **Estimativa:** 1 sessão curta, na janela da reescrita ·
**Depende de:** [Y02](Y02-a-historia-sem-rastro.md) (o repositório recriado). Do lado do Hefesto: a sprint
`O-REPOSITORIO-NASCE-VIVO-01` (o `scripts/github/aplicar.py` e o esquema do `repositorio.yml` moram lá).

Veio do plano do Hefesto em 13/10/2026 e leva só a **parte da Forja** da sprint `O-REPOSITORIO-NASCE-VIVO-01`. O lado do
Hefesto (a organização, o projeto «Roteiro», as Pages, a Wiki, o perfil, as imagens de container, o `ci.yml`) é dele.
Esta ficha nasceu **feita**: o `repositorio.yml` estava no `main` e o GitHub já o seguia; a conferência de 30/10/2026
está em «O que foi feito».

## Por quê

O que alguém configura à mão na interface some com o repositório apagado e não se reproduz no recriado. A cura é o
GitHub como código: `.github/repositorio.yml` declara tudo, o `aplicar.py` aplica pelo `gh api`, idempotente, e o
`--conferir` diz a diferença sem mudar nada. A Forja declara o que cabe nela (o jogo): issues de bug com a saída da
bancada, Discussions, as releases do jogo como anexos; sem Pages até o trailer, sem Wiki, sem ambientes nem Packages.

## Ler antes

- `.github/repositorio.yml` e o cabeçalho dele.
- [Y02](Y02-a-historia-sem-rastro.md): a reescrita e o push.
- [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md) e `.github/SECURITY.md`.

## O que foi feito

No `main`: o `repositorio.yml` com o check obrigatório da prova do jogo e a política de segurança (`e1351ef`); o
histórico linear na porta, que deixa passar quem mantém, porque a história do `main` já tem um merge (`f3b125f`); o
`repositorio.yml` completo com os modelos de issue e de discussão, o `CODEOWNERS`, o rotulador, o fluxo de rótulos, o
`CONTRIBUTING`, o modelo de PR e o `CODE_OF_CONDUCT.md` na raiz (`0e1b154`); o botão Sponsor ligado ao Patreon que o
`FUNDING.yml` lista (`194f342`). A pasta `.github/` tem `CODEOWNERS`, `CONTRIBUTING.md`, `DISCUSSION_TEMPLATE/`,
`FUNDING.yml`, `ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md`, `labeler.yml`, `repositorio.yml`, `SECURITY.md` e os
fluxos `forja.yml` e `rotulos.yml`.

Os três rulesets estão ativos no GitHub: a história não se reescreve e vem assinada, as versões
publicadas não se apagam nem se movem, e o que entra no `main` passa pela prova e pela revisão.

### Medido em 30/10/2026

| o que | medida |
| --- | --- |
| `aplicar.py --repo Hefesto-Team/Forja --arquivo .github/repositorio.yml --conferir` | «sem diferença» |
| `gh api repos/Hefesto-Team/Forja/rulesets` | três rulesets, todos `active` |
| visibilidade e funções | público, Discussions ligadas, Wiki desligada |

## Pronto quando

O `--conferir` sai sem diferença: medido acima. A segunda aplicação idempotente não foi repetida em 30/10, porque o
`--aplicar` escreve no GitHub; o `--conferir` sem diferença é a mesma garantia.

## Não fazer

- Não aplicar com uma conta que não seja a da casa (o `aplicar.py` recusa de propósito).
- Não configurar nada à mão na interface sem dizer no `repositorio.yml`: a próxima conferência acusa a diferença.
- Não ligar Wiki, Pages com site, ambientes nem Packages na Forja antes da hora.
- Não pôr nome de rede, endereço de máquina ou dado pessoal em nenhum arquivo do `.github/`.

## Para o André (local)

- O `FUNDING.yml` lista o Patreon; decidir se as doações vão também para a organização.
- Conferir de vez em quando com o `--conferir`, porque o que se muda à mão na interface só aparece nele.
