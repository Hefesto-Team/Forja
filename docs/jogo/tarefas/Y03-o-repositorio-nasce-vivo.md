# Y03 — O repositório nasce vivo: a chamada do `aplicar.py` na Forja

**Sprint:** Y · **Tamanho:** P · **Estimativa:** 1 sessão curta, na janela da reescrita ·
**Depende de:** [Y02](Y02-a-historia-sem-rastro.md) (o repositório recriado). Do lado do Hefesto: a sprint
`O-REPOSITORIO-NASCE-VIVO-01` (o `scripts/github/aplicar.py` e o esquema do `repositorio.yml` moram lá).

Veio do plano do Hefesto em 13/10/2026. Esta ficha leva só a **parte da Forja** da sprint `O-REPOSITORIO-NASCE-VIVO-01`. O
lado do Hefesto (a organização, o projeto «Roteiro», as Pages, a Wiki, o perfil `Hefesto-Team/.github`, as imagens de
container, o `ci.yml`) é dele e fica como dependência externa.

## Por quê

Decisão de 05/10/2026, ao apagar os dois repositórios e recriá-los com a história reescrita: *«na real tinhamos que ter
automatizado esses outros aspectos do github né? Pq tá muito feio como tá sem usarmos nada»*, e depois, com a página de issues
de outro projeto aberta: *«milestone, labels. projects. packages, people, views e wiki, actions, e afins. é mais nesse sentido
de ficar completinho assim. usando todas as features do github entende?»*. O que alguém configura à mão na interface some
com o repositório apagado e não se reproduz no recriado. A cura é o GitHub como código: `.github/repositorio.yml` declara
tudo, o `aplicar.py` aplica pelo `gh api`, idempotente, e o `--conferir` diz a diferença sem mudar nada.

A Forja nasce com o que cabe nela (o jogo): issues de bug com a saída da bancada, Discussions, Pages com o trailer quando
houver, as releases do jogo como anexos.

## Ler antes

- `.github/repositorio.yml` (já na árvore) e o cabeçalho dele, que diz como o `aplicar.py` o lê.
- [Y02](Y02-a-historia-sem-rastro.md): a janela da reescrita, o push e a ordem.
- [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md) e `SECURITY.md`/`.github/SECURITY.md`.

## O estado de hoje

### O que já está na Forja (costurado em `b61bfcf`, 06/10/2026, `voo/forja-nasce-vivo`; e no conjunto `voo/forja-github`)

- **O mínimo (`b61bfcf`):** o `repositorio.yml` da Forja (ruleset só no `main`; o check obrigatório é o job «Linux — módulo,
  provas e a prova do jogo») e o `SECURITY.md`. O `aplicar.py` do Hefesto é idempotente, tem `--conferir` (sai 1 se faria
  algo, 2 se não mediu), `--aplicar`, `--repo`, `--arquivo`, `--so`/`--sem` por grupo e `--detalhe`; a escrita recusa conta que
  não seja a da casa e dono de fora; **o mesmo script serve a Forja**.
- **O conjunto github-completo** (o `voo/forja-github`): o mesmo desenho, com o que cabe nela, **sem Pages até o trailer, sem
  Wiki, sem ambientes nem Packages**, e o `CODE_OF_CONDUCT.md` na raiz. A pasta `.github/` da Forja hoje tem `CODEOWNERS`,
  `CONTRIBUTING.md`, `DISCUSSION_TEMPLATE/`, `FUNDING.yml`, `ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md`, `labeler.yml`,
  `repositorio.yml`, `SECURITY.md` e os fluxos `forja.yml` e `rotulos.yml`.
- **O que o `repositorio.yml` do Hefesto declara** (a Forja usa o esquema com o recorte dela; descrito aqui para quem for
  conferir): o About; as funções (Issues, Discussions, Projects, Sponsor ligados quando couber; Wiki e Pages conforme o
  repositório); a segurança (relato privado, alertas do Dependabot, varredura de segredo e proteção de push; **o Dependabot
  só no alerta**, `atualizacoes_de_seguranca: false`); a mesclagem sem commit de merge pelo botão; os rótulos (os nove do GitHub
  em português mais área, transporte, distro e prioridade); marcos sem data até quem mantém dar; a equipe `mantenedores`;
  permissões do fluxo do Actions só de leitura (PR de fora espera aprovação); a varredura de código (Python e Actions); o
  grafo de dependências; o perfil da comunidade em 100%; e **dois rulesets**: «a história» (sem apagar, sem push forçado,
  **assinatura de commit exigida**, sem exceção, porque uma exceção de administrador a anularia) e «a porta» (histórico
  linear, uma revisão depois do último push, os checks obrigatórios; os administradores passam). As tags `v*` não se apagam
  nem se movem.
- **O que o Hefesto deixou de fora, medido** (vale para a Forja também onde cabe): LFS (o maior arquivo versionado do Hefesto
  tem 2,3 MB; medir o da Forja antes de repetir a decisão), merge queue, Codespaces, autolinks e a imagem de prévia social (a
  API não tem endpoint). Releases imutáveis desligadas porque o fluxo de release apaga e recria a versão.

### O que sobra (a janela)

O passo da janela do Hefesto que aplica o arquivo chama `aplicar.py --aplicar` **sem `--repo`** (obrigatório) e, na Forja,
**sem `--arquivo <Forja>/.github/repositorio.yml`**; a costura acerta a chamada. Com o histórico linear na porta, o `--aplicar`
inteiro antes do primeiro push deixa de ser risco; o `--sem rulesets` fica de reserva.

Posse da sprint do Hefesto neste lado: `.github/` da Forja, `SECURITY.md` e `CODE_OF_CONDUCT.md` da Forja.

## O alvo

Depois do push da história reescrita ([Y02](Y02-a-historia-sem-rastro.md)), a Forja recriada tem tudo o que o
`.github/repositorio.yml` declara, e o `--conferir` não acusa diferença:

```
python3 <Hefesto>/scripts/github/aplicar.py --repo Hefesto-Team/Forja \
    --arquivo <Forja>/.github/repositorio.yml --conferir
python3 <Hefesto>/scripts/github/aplicar.py --repo Hefesto-Team/Forja \
    --arquivo <Forja>/.github/repositorio.yml --aplicar
```

## Passos

1. Conferir (`--conferir`) o `repositorio.yml` da Forja contra o repositório recriado, antes de aplicar; ler a diferença.
2. Aplicar (`--aplicar`) com `--repo Hefesto-Team/Forja --arquivo <Forja>/.github/repositorio.yml`. O que o GitHub só deixa
   medir (categorias das Discussions, grafo, saúde da comunidade, edição de uma vista) sai como «à mão», nunca como feito:
   fazer à mão e conferir.
3. Rodar o `--conferir` de novo (sem diferença) e o `--aplicar` uma segunda vez (não muda nada).
4. A assinatura de commit: a regra EXIGE assinatura nos dois rulesets da história. O `main` da Forja recriado precisa nascer
   com commits que o GitHub aceite; **se o GitHub conferir a assinatura de todo commit que um push acrescenta ao ramo
   (inclusive os que já existem), o primeiro push com a regra ligada é recusado**: aplicar a regra de assinatura depois do
   primeiro push, ou medir antes num repositório de ensaio (`Hefesto-Team/ensaio-da-janela`). Não medido ainda: só se mede
   com escrita no GitHub.
5. Verificar por fora, sem login: a página mostra Issues com os formulários, Discussions, o botão Sponsor e o About certo; uma
   issue de teste sem a saída pedida ganha o rótulo e o comentário.

## Armadilhas

- **O repositório recriado nasce no ramo padrão certo?** O `repositorio.yml` declara `ramo_padrao: main` e o `--aplicar` volta
  a ele; o ramo tem de existir no remoto antes.
- **Ligar as Pages cria o ambiente `github-pages`** com a regra do ramo padrão; a Forja não liga Pages até o trailer. Quando
  ligar, declarar o ambiente com o ramo certo (o `aplicar.py` tira a regra que o arquivo não lista).
- **O `--aplicar` mede cada grupo de novo logo antes de aplicar** (ordem de `GRUPOS`); a primeira rodada que deixa sobra é
  defeito do aplicador, não da Forja: avisar o Hefesto.
- **Dependabot: o PR de segurança do robô não se mescla, nem pela exceção**: qualquer jeito de mesclar põe o robô como autor
  na história e a deixa vermelha; quem mantém refaz a atualização num commit seu.
- **A organização e o projeto «Roteiro»** (os tipos de issue e o quadro) moram no arquivo do Hefesto, que liga o quadro a este
  repositório; a Forja não os declara.

## Não fazer

- Não aplicar com uma conta que não seja a da casa (o `aplicar.py` recusa de propósito).
- Não configurar nada à mão na interface sem dizer no `repositorio.yml`: a próxima conferência acusa a diferença.
- Não ligar Wiki, Pages com site, ambientes nem Packages na Forja antes da hora (o recorte dela é o jogo).
- Não pôr nome de rede, endereço de máquina ou dado pessoal em nenhum arquivo do `.github/`.

## Pronto quando

`aplicar.py --repo Hefesto-Team/Forja --arquivo <Forja>/.github/repositorio.yml --conferir` sai 0 sem diferença depois da
aplicação, e uma segunda `--aplicar` não muda nada.

## Provas

- O `--conferir` sem diferença e a segunda aplicação idempotente (acima).
- Por fora, sem login (passo 5).
- A régua do Hefesto `test_o_repositorio_diz_o_que_o_github_tem.py` (140 testes, com o `gh` de mentira) é de lá; a da Forja é
  a conferência real.

## Para o André (local)

- Decidir **quem recebe as doações** (a organização, ou as duas pessoas e o André) para o `FUNDING.yml`; o botão Sponsor está
  ligado com o que já existia.
- Decidir se o repositório recriado nasce **público** (libera Wiki, Pages, CodeQL e Actions sem cota) ou privado até o
  lançamento; as datas dos marcos.

## Ao terminar

Pôr a linha da Y03 no [quadro](README.md) como **feito**, com o commit; avisar o Hefesto para fechar a parte dele.
