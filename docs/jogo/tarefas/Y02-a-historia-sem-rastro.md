# Y02 — A história sem rastro: os ramos, a reescrita e o chamado

**Sprint:** Y · **Tamanho:** M · **Estimativa:** 1 sessão de quem coordena, na janela da reescrita do Hefesto ·
**Depende de:** nada no quadro. Do lado do Hefesto: as sprints `A-FORJA-SEM-RASTRO-01` (os itens 1 a 4) e
`A-HISTORIA-REESCRITA-UMA-VEZ-SO-01` (a janela, passo 2).

Veio do plano do Hefesto em 13/10/2026. Cobre os itens 5 e 6 da sprint `A-FORJA-SEM-RASTRO-01`; os itens 1 a 4 já
estavam no `main`. Esta ficha nasceu **feita**: a janela rodou em 07/10/2026, antes de a ficha chegar ao quadro, e a
conferência de 30/10/2026 está em «O que foi feito».

## Por quê

A Forja (`Hefesto-Team/Forja`) é **pública**, e nada do que ela publica pode denunciar uso de IA. A ponta (o presente)
já tinha saído limpa; a **história** ainda carregava o que a ponta tirou. A reescrita tira do passado o que a ponta já
tirou do presente, e a árvore da ponta não muda um byte nela.

## Ler antes

- [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md): a lei do repo.
- `tests/prova_sem_rastro.sh`: a régua que reprova o rastro.
- [Y03](Y03-o-repositorio-nasce-vivo.md): a aplicação do GitHub como código, depois do push.

## O defeito medido (05/10/2026)

1. 22 dos 67 commits do `main` publicado tinham autor e committer de uma conta de ferramenta (todos de 30/09). Por isso
   a lista de colaboradores trazia essa conta como terceira.
2. Três ramos no GitHub com nome de ferramenta (dois com o nome dela como prefixo e um `ccr-`, de sessões remotas). O
   fluxo `FORJA` rodou neles, então o nome aparecia também na aba Actions.
3. O arquivo da lei do repo tinha o nome de convenção das ferramentas de IA e era versionado.
4. A documentação versionada nomeava a ferramenta e os modelos (o doc 12 e 74 das 90 fichas traziam o «modelo
   sugerido»).
5. O «Opus» do som é o codec (`docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md`, «o microfone chega como Opus a 48 kHz»). Não é
   rastro e não sai; a régua distingue.

## O que foi feito

**Itens 1 a 4, no `main`:** `docs/COMO-CONTRIBUIR.md` (`9bba2ec`) leva as regras para quem contribui e o arquivo das
ferramentas saiu do índice, trancado no `.gitignore`; as fichas e o quadro perderam o campo de modelo (`b00eae8`); o
doc 12 e a F00 falam de pessoas e sessões (`cd1fc54`); os links da lei apontam para o COMO-CONTRIBUIR (`a73fb0d`). A
régua `tests/prova_sem_rastro.sh` nasceu em `c340512`, ficou à prova de vazar o termo em `e35ae1f`, e a prova do jogo e o
CI a chamam desde `5b6cd7f`. Um commit da leva original, o que só tirava o arquivo das ferramentas do índice, ficou
vazio na reescrita e saiu.

**Item 5, a reescrita (07/10/2026):** `git filter-repo` com o `mailmap`, o callback de mensagem e o `--replace-text` dos
termos, com a exceção do codec. O mapa dos hashes antigos para os novos fica fora do repositório, em
`_reescrita-historia-sem-rastro/forja/uniao.git/filter-repo/commit-map` ao lado do clone; as citações de commit nas
fichas seguem esse mapa (`49c9dd2`), e os hashes desta ficha e da Y03 também.

**Item 6, o chamado:** a lista de colaboradores devolve hoje só duas contas, a da Vitória e a do André.

### Medido em 30/10/2026

| o que | medida |
| --- | --- |
| autores e committers do `main` | dois e-mails, nenhum do domínio da ferramenta |
| trailer de coautoria nas mensagens do `main` | 0 |
| `git ls-remote origin` | `main`, `integra/forja`, `medida/forja-exe-4-7` e os `voo/*`; nenhum ramo com prefixo de ferramenta nem `ccr-`; nenhum `refs/pull` nem `refs/replace` |
| `gh api repos/Hefesto-Team/Forja/contributors` | as duas contas das pessoas, nenhuma de ferramenta |
| `bash tests/prova_sem_rastro.sh` | verde, com as mordidas, e o codec do som passa |

As ligações para o arquivo antigo que sobraram da leva (`docs/DESENVOLVER.md`, `docs/README.md`, a ADR 008, o estudo 05,
a arquitetura e o `README.en.md`) e os nomes de modelo do `scripts/ace_step.sh` foram acertados: a régua passa sem
exceção.

## Provas

- `bash tests/prova_sem_rastro.sh` verde, e ela **morde**: o campo de sugestão de modelo numa ficha reprova; o codec do
  som a 48 kHz passa.
- As quatro medidas da tabela.
