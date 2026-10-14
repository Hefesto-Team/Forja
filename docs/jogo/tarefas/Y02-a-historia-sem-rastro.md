# Y02 — A história sem rastro: os ramos, a reescrita e o chamado

**Sprint:** Y · **Tamanho:** M · **Estimativa:** 1 sessão de quem coordena, na janela da reescrita do Hefesto ·
**Depende de:** nada no quadro. Do lado do Hefesto: as sprints `A-FORJA-SEM-RASTRO-01` (os itens 1 a 4, feitos aqui em
06/10/2026) e `A-HISTORIA-REESCRITA-UMA-VEZ-SO-01` (a janela, passo 2).

Veio do plano do Hefesto em 13/10/2026. Esta ficha leva só o que **falta** da sprint `A-FORJA-SEM-RASTRO-01`: os itens 5 e
6. Os itens 1 a 4 estão feitos e registrados abaixo.

## Por quê

A Forja (`Hefesto-Team/Forja`) é **pública**, e a regra do André vale para ela como vale para o Hefesto: nada do que ela
publica pode denunciar uso de IA. A ordem de 05/10/2026: abrir a leva «a casa limpa», a limpeza completa do CI e do GitHub
dos dois repositórios, com o aval do André. A ponta (o presente) já saiu limpa; a **história** ainda carrega o que a ponta
tirou. A reescrita tira do passado o que a ponta já tirou do presente, e a árvore da ponta não muda um byte nela.

## Ler antes

- [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md): a lei do repo, que substituiu o arquivo das ferramentas.
- `tests/prova_sem_rastro.sh`: a régua que reprova o rastro (a que esta ficha usa para provar).
- [Y03](Y03-o-repositorio-nasce-vivo.md): a aplicação do GitHub como código roda na mesma janela, depois do push.

## O estado de hoje

### O defeito medido (05/10/2026)

1. **22 dos 67 commits do `main` publicado tinham autor e committer de uma conta de ferramenta** (todos de 30/09: as
   fichas, a trilha, a arte dos bonecos). Por isso a página do repositório lista essa conta entre os colaboradores
   (`gh api repos/Hefesto-Team/Forja/contributors` devolvia três: as duas pessoas e a conta da ferramenta). O Hefesto tem o
   mesmo defeito por outro caminho (os trailers em `refs/pull/117` e `118`).
2. **Três ramos no GitHub com nome de ferramenta**: dois com o nome dela como prefixo (`<ferramenta>/hefesto-tech-demo-game-o95gvu` e
   `<ferramenta>/lucid-brown-l4a7lh`) e `ccr-4da2efb0-ugcpb2` (sessões remotas). O workflow `FORJA` rodou neles (execução 36785780742, 30/09), então o nome
   aparece também na aba Actions.
3. **O arquivo da lei do repo tinha o nome de convenção das ferramentas de IA e era versionado.**
4. **A documentação versionada nomeava a ferramenta e os modelos**: o doc 12 e **74 das 90 fichas** traziam o «modelo
   sugerido». Contagem nos arquivos versionados: 204 menções a um modelo de nome de poeta, 44 a um de nome de música (dos quais os do
   áudio são o codec e ficam) e 7 ao nome da ferramenta.
5. **O «Opus» do som é o codec** (`docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md`, «o microfone chega como Opus a 48 kHz»;
   `SPRINTS.md:268`). Não é rastro e não sai; a régua distingue.

### O que está feito (itens 1 a 4; 05 e 06/10/2026, Forja, `integra/1-6` = `fed5964`, 8 commits sobre `ed786e4`)

A ponta na worktree `voo/forja-sem-rastro` (de `ed786e4`): cinco commits, `1aebac9` (a régua), `4bb2b8d` (as fichas e o
quadro), `6072c31` (o COMO-CONTRIBUIR, o `.gitignore`, o README, o SPRINTS, o doc 12), `7334e64` (a prova do jogo e o
`forja.yml` chamam a régua) e `953f1bd` (o arquivo das ferramentas sai do índice); e dois da conferência, `f79fdf0` (a
régua) e `4c9a2a8` (os textos). Prova sem rastro e prova do jogo verdes.

- **1.** `docs/COMO-CONTRIBUIR.md` leva as regras, os comandos e o que nunca entra, escrito para quem contribui; o arquivo das
  ferramentas saiu do índice (`git rm --cached`), continua no disco com o mesmo md5, e o `.gitignore` o tranca. O README e o
  SPRINTS apontam para o COMO-CONTRIBUIR; as fichas que citavam o arquivo antigo citam o COMO-CONTRIBUIR.
- **2.** `docs/jogo/12-como-trabalhar.md` fala de pessoas e sessões: saíram o nome da ferramenta, a tabela «Qual modelo» e os
  preços por modelo (a tabela de estimativa por sprint ficou). O conteúdo que saiu está no arquivo de casa de quem coordena
  (`~/.local/state/hefesto-casa/forja/modelos-por-ficha.md`, fora do git: as duas tabelas e o modelo de cada uma das 78
  fichas do quadro e dos 88 cabeçalhos). A tabela de modelos é decisão de custo dela e mudou de lugar, não de conteúdo.
- **3.** O campo «Modelo» saiu do cabeçalho de 88 arquivos de ficha e de seção (o enunciado dizia 74; a medida é 88 de 90
  arquivos, só o quadro e o molde não o tinham), da coluna «modelo» do quadro e das tabelas das seções I a Q, e das
  linhas-molde de «Ao terminar». **O gerador do quadro não existe nesta árvore**: o quadro é escrito à mão (nenhum script lê
  os cabeçalhos das fichas; `scripts/trilha_fichas.py` lê os documentos 03 e 04). A escolha do modelo lê o arquivo de casa.
- **4.** `tests/prova_sem_rastro.sh`: lê o que o git versiona e os arquivos novos ainda sem `git add`; reprova os nomes da
  ferramenta, da empresa e dos modelos, o nome de modelo com versão ou na tabela de modelos, o campo de sugestão de modelo, o cabeçalho
  de modelo, a coluna «modelo», o trailer de coautoria, o arquivo das ferramentas (e o irmão) versionado em qualquer pasta
  e um `.gitignore` sem a tranca. O «Opus» do som passa (o conferidor de faixas e `SPRINTS.md:268` ficam como estavam). Na
  conferência: a lista de termos vem codificada e a saída leva só arquivo e linha (no CI a saída é pública); o nome do
  arquivo também é lido; as mordidas escrevem os termos por outro caminho (octal), de modo que uma lista corrompida reprova.
  24 mordidas internas; quatro da própria régua (lista corrompida, saída crua, sem o nome de arquivo, sem a versão)
  reprovam. A `prova_do_jogo.sh` a chama (pula, dizendo, se não há git) e o `forja.yml` a roda logo depois do checkout.
- **Decisão pelo padrão do André, a validar:** a F00 mandava criar a configuração de sessão dentro do repositório; a lei nova
  tranca essa pasta, então a ficha passou a dizer que o gancho de início de sessão mora na configuração da sessão na
  nuvem, fora do repositório, e só chama o `scripts/preparar_sessao.sh` (que é versionado).
- **O `.gitignore` versionado nomeava a ferramenta** (as linhas do irmão do arquivo antigo e da pasta de configuração), e a
  régua da autoria do Hefesto (`check_autoria.py arvore`) saía vermelha nelas. As duas linhas saíram; a tranca delas mora no
  ignore global das máquinas de quem coordena. O `.gitignore` tranca só o arquivo antigo, e a régua deixou de isentar linha
  do `.gitignore`.
- **O gancho global de commit** tira espaço do fim de linha: `H07-o-som-em-todo-evento.md` perdeu 21 espaços de linhas de
  contexto de um patch embutido (a linha em branco no lugar de « »); o `git apply` aceita as duas formas.
- **Fora da posse, ficaram para a costura** (ligações para o arquivo antigo que agora não existe no git): `docs/DESENVOLVER.md:5`,
  `docs/README.md:51`, `docs/adr/008-a-metodologia-astro-bot.md:16`, `docs/estudos/05-o-dualsense-do-astro-bot.md:76` (só cita
  o nome) e `docs/jogo/13-arquitetura.md:64`; e `README.en.md` (a tabela da linha 85 não tem a linha do COMO-CONTRIBUIR).
  Conferir se já foram acertadas; se não, entram nesta ficha.
- Fica de fora da posse: `scripts/ace_step.sh:65,71,76` (o modelo de linguagem do gerador de música) ainda reprova na régua da
  autoria do Hefesto. Acertar na costura, com o nome do modelo de música dito sem o termo.

## O alvo

Os itens 5 e 6 da sprint, a história e o chamado:

**Item 5 — na janela da reescrita** (passo 2 da `A-HISTORIA-REESCRITA-UMA-VEZ-SO-01` do Hefesto, no mesmo dia e na mesma
corrida de quem coordena, num clone próprio da Forja): `git filter-repo` com o `mailmap` que troca a identidade da conta de
ferramenta pela identidade de quem pediu os commits (autor e committer: os 22 commits foram feitos a pedido dela e são
dela), o callback de mensagem da sprint do Hefesto e o `--replace-text` das linhas do item 4 nos blobs antigos (com a
exceção do codec). Os três ramos do defeito 2 saem do GitHub (`git push origin --delete`, depois do backup); o `main` sobe
com `--force-with-lease`. As cinco armadilhas medidas do `filter-repo` (`refs/replace`, `refs/pull`, a tradução de hash
curto, `--mirror`) valem igual.

**Item 6 — o chamado ao suporte é um só para os dois repositórios.** O André abre, como dono da organização: a lista de
colaboradores e os gráficos de Insights são cache do GitHub, e o pedido cobre `hefesto-dualsense4unix` e `Forja` no mesmo
texto.

## Passos

1. Esperar a janela do Hefesto (o dono é o `A-HISTORIA-REESCRITA-UMA-VEZ-SO-01`, lá). Antes, conferir que a ponta segue
   limpa: `bash tests/prova_sem_rastro.sh` verde.
2. Clone próprio da Forja (nunca a árvore de trabalho). Backup completo dos três ramos e das referências antes de apagar.
3. `git filter-repo` com o `mailmap`, o callback de mensagem e o `--replace-text` (exceção do codec).
4. Apagar os três ramos no remoto; subir o `main` com `--force-with-lease`.
5. Provar (abaixo). Depois, o chamado, escrito para os dois repositórios de uma vez (o texto é de quem coordena).
6. Depois da reescrita, aplicar o GitHub como código ([Y03](Y03-o-repositorio-nasce-vivo.md)) no repositório recriado.

## Armadilhas

- **A árvore não pode mudar.** `git rev-parse HEAD^{tree}` igual antes e depois; se mudou, o `--replace-text` pegou mais do
  que devia (o codec «Opus» é o caso).
- **Hash curto citado em texto** (nas fichas e no SPRINTS) quebra com a reescrita: o `filter-repo` traduz o completo, o curto
  precisa do passo próprio.
- **`refs/pull` e `refs/replace` seguem no remoto** depois do push; o `--mirror` leva o que não devia. Siga as cinco
  armadilhas medidas na sprint da janela.
- **Os ramos de ferramenta apagam depois do backup**, nunca antes.
- **O workflow `FORJA` rodou nesses ramos** (execução 36785780742): a aba Actions guarda o nome até o chamado.

## Não fazer

- Não reescrever a história da Forja fora da janela do Hefesto: as duas sobem juntas e o chamado é um só.
- Não tocar em `src/`, `godot/` nem `nativo/`: a ponta não muda um byte.
- Não abrir o chamado antes do push.

## Pronto quando

`git log origin/main --format='%ae%n%ce'` sem nenhum e-mail do domínio da ferramenta (a contagem é 0); `git ls-remote origin` sem ramo com o prefixo da ferramenta nem `ccr-`; a
árvore da ponta byte a byte igual antes e depois (`git rev-parse HEAD^{tree}`); depois do chamado, `contributors` devolve só
as duas pessoas e o André.

## Provas

- A régua do item 4 vermelha antes e verde depois, e **morde**: devolver o campo de sugestão de modelo numa ficha reprova; o codec do som a 48 kHz passa. (Já provada nos itens 1 a 4; refazer depois da reescrita.)
- `bash tests/prova_do_jogo.sh` verde antes e depois: nada do jogo mexeu.
- As três medidas de «Pronto quando».

## Para o André (local)

- Abrir o chamado ao suporte (você é o dono da organização), um só para os dois repositórios.
- Confirmar a decisão «a validar» da F00 (a configuração de sessão na nuvem, fora do repositório).

## Ao terminar

Pôr a linha da Y02 no [quadro](README.md) como **feito**, com o commit da última medida.
