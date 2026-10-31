# V10 — O devlog com antes e depois

**Sprint:** V · **Tamanho:** M · **Estimativa:** 2 h de agente · **Depende de:** —

## Por quê

Toda entrega que muda o que se vê precisa deixar registro: um texto curto do que mudou e as fotos de antes e depois,
tiradas pelo próprio jogo. Hoje as fotos ficam espalhadas em `/tmp` e somem. O devlog é o controle narrativo do
projeto, para os três devs, e se abre com um comando só.

## Ler antes

- [DESENVOLVER: a prova visual](../../DESENVOLVER.md#a-prova-visual) e [as fotos e o trailer](../../DESENVOLVER.md#as-fotos-e-o-trailer)
- `tests/telas.sh` (o jeito de fotografar pela tela de mentira) e `godot/testes/captura_jogo.gd` (os roteiros)
- `scripts/portoes/LEIA-ME.md` (como um portão entra no `rodar.sh`)

## O estado de hoje

- `tests/telas.sh fotos <pasta>` fotografa por xvfb com `--simular=4 --semente=7`, roteiros de
  `godot/testes/captura_jogo.gd:25` (`salas`, `bancada`, `partida`, `extras`, `cavaleiro`, `trailer`) e as salas de
  `captura_jogo.gd:122-175`.
- Nada guarda a foto de antes: quem quer comparar monta uma worktree na base à mão.
- O módulo nativo da worktree tem que casar com a fonte (`tests/caixa.sh:98`, `caixa_fonte`); numa base antiga é
  preciso `scripts/compilar.sh linux`.
- Os agentes rodam provas pesadas ao mesmo tempo; a fila de hoje é um script fora do repositório.

## O alvo

1. **`scripts/vez.sh <cmd...>`**: semáforo de máquina com `VEZ_N` vagas (padrão 4), por `flock` em
   `${XDG_RUNTIME_DIR:-/tmp}/forja-vez/<n>.lock`. Toda execução pesada do Godot dos scripts abaixo passa por ele.
2. **`scripts/devlog/entrada.sh <slug> "<título>" [--base REF] [--topo REF]`**: cria
   `docs/devlog/AAAA-MM-DD-<slug>/entrada.md` com cabeçalho `titulo`, `data`, `ramo`, `base` (padrão:
   `git merge-base main HEAD`), `topo` (padrão: `HEAD`), `fichas` (as fichas citadas nos commits) e o corpo com um
   resumo de no máximo 8 linhas, que quem entrega escreve. Imprime o caminho.
3. **`scripts/devlog/fotos.sh <pasta-da-entrada> [--roteiros a,b,c]`**: lê `base` e `topo` do cabeçalho; monta as
   duas árvores destacadas em `.cache/devlog/arvores/<sha>` (reaproveita se existir), garante o módulo nativo de
   cada uma (copia o da árvore atual quando a soma da fonte casa; senão `scripts/compilar.sh linux` com os caches
   do `.cache` da raiz), importa e fotografa as duas com os MESMOS roteiros, semente e resolução de
   `tests/telas.sh`, pelo `scripts/vez.sh`. Os roteiros padrão são os que tocam os arquivos mudados entre base e
   topo (sala mudada → a sala; `ui/`, `main.gd`, `mundo/` → `salas` e `partida`; montagem → `cavaleiro`); sem
   palpite, todos. Guarda em `antes/` e `depois/` da entrada, mesmo nome dos dois lados, em JPEG de no máximo
   1280 px de largura, qualidade 78, sem metadados. Par em que `compare -metric RMSE` normalizado dá menos de
   0,01 é igual: sai dos dois lados. Tela que só existe de um lado fica só daquele lado.
4. **`devlog.sh`** (raiz): monta `.cache/devlog/index.html` com todas as entradas, a mais nova em cima: título,
   data, ramo, fichas, o resumo e os pares lado a lado (antes | depois), clique amplia. As fontes vêm de
   `godot/assets/fontes/` (Bungee no título, Permanent Marker na etiqueta, VT323 no OSD, Archivo Narrow no texto),
   copiadas para `.cache/devlog/fontes/`; as cores, de `godot/scripts/tema.gd` (`FITA`, `CASCO`, `ETIQUETA`,
   `TINTA`, `VIOLETA`, `MUDO` e as listras `#c8432f`/`#c79a2a`): cada entrada é uma etiqueta de cassete. Sem rede.
   Abre com `xdg-open`; `--sem-abrir` só imprime o caminho (é o que agente usa). `--entrada <pasta>` monta só uma.
5. **O cobrador** `scripts/devlog/cobrar.sh`: sai 0 quando o ramo atual não muda arquivo visual desde a base, ou
   quando existe entrada com `topo` igual ao `HEAD` (ou ancestral dele só com commits não visuais depois) e com pelo
   menos um par ou uma foto de depois. Senão, sai 2 e diz, numa linha cada, os dois comandos que faltam. Arquivo
   visual: `godot/**` menos `godot/testes/**`, `*.import` e `*.uid`.
6. **O gancho do agente**: o modelo `scripts/devlog/gancho.json` (`Stop` e `SubagentStop` chamando o cobrador) e o
   `scripts/devlog/ligar_gancho.py`, que o funde na configuração do agente da árvore. O cobrador lê o JSON da entrada
   padrão; com `stop_hook_active: true` sai 0 (sem laço). Fora de um repositório git, ou no ramo `main`, sai 0. O
   repositório não versiona a pasta de configuração do agente (o portão sem rastro reprova o arquivo e o nome):
   versiona-se o modelo, e cada árvore liga o seu.
7. **O portão** `scripts/portoes/devlog.py`, no grupo `base` do `rodar.sh`, modo reprova: toda entrada tem o
   cabeçalho inteiro e o resumo de até 8 linhas; toda foto é JPEG de até 1280 px; a entrada pesa até 6 MB; todo par
   tem o mesmo nome dos dois lados.
8. **A primeira entrada**: `docs/devlog/2026-10-30-a-apresentacao/`, base `55682df`, topo `018dca4`, título
   «A apresentação», com as fotos que o `fotos.sh` tirar e o resumo das sete áreas do dia (capa, cavaleiro, salão e
   fluxo, Centelha e Viga, Molde/Impacto/Galeria, Canto/Caminhos, Cega/Voz/Prova).
9. **O texto**: `docs/DESENVOLVER.md` ganha a seção «O devlog» (os três comandos e quando usar);
   `docs/jogo/o-time/a-esteira.md` diz que a entrega que muda o que se vê fecha com a entrada do devlog;
   `docs/o-porque-dos-modulos.md` ganha o porquê do JPEG e do corte dos pares iguais (o peso do repositório).

## Armadilhas

- A árvore de antes pode ser de antes da reescrita do histórico: o `base` é sempre um SHA que existe.
- Duas provas no mesmo `user://` brigam: cada execução do `fotos.sh` usa o `XDG_DATA_HOME` próprio, como
  `scripts/exportar.sh:41`.
- Nunca abrir janela do Godot na tela: só xvfb.
- O hook não pode travar o fim de quem não mexeu no visual nem de quem está no `main`.

## Não fazer

- Não commitar PNG, nem foto acima de 1280 px.
- Não mudar `tests/telas.sh` além de extrair o que o `fotos.sh` reaproveita.

## Pronto quando

`./devlog.sh` abre uma página com a entrada «A apresentação» e os pares antes/depois do dia, e um agente que muda uma
sala não consegue encerrar sem a entrada dela.

## Provas

- `bash tests/prova_do_devlog.sh`: entrada falsa com duas fotos pequenas; `devlog.sh --sem-abrir` gera o HTML com a
  entrada e o par; par igual sai; o cobrador dá 2 sem entrada, 0 com entrada, 0 com `stop_hook_active`, 0 no `main`;
  o portão reprova foto PNG, foto larga, resumo longo e par sem irmão. Entra na lista do `prova_das_ferramentas` ou
  onde o `LEIA-ME` dos portões manda.
- `bash scripts/portoes/rodar.sh` verde.

## Ao terminar

Linha da V10 no quadro como **feito**, e o devlog desta própria ficha não é exigido (não muda o visual).
