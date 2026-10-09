# F10 — O rumble seco

**Sprint:** F · **Tamanho:** G · **Depende de:** F05 (a medição do háptico), F06 (o registro)

## Por quê

A F05 achou sete suspeitas para o háptico fraco. Uma delas (a **c**) é que o
SDL, em firmware novo, manda o rumble no modo "suave" (a emulação melhorada,
bit `0x04` do byte 38), que se sente mais fraco que o modo antigo, "seco"
(bit `0x01` do byte 0). Esta ficha mede os dois às cegas e, **só se o seco
vencer**, emenda o contrato e põe o modo seco no jogo como opção de cada
lugar.

## Ler antes

- [05 — por que o háptico está fraco](../05-haptica-e-controle.md#por-que-o-háptico-está-fraco) e [a força máxima que é legítima](../05-haptica-e-controle.md#a-força-máxima-que-é-legítima)
- [F05](F05-o-haptico-forte.md) (o experimento `haptico` e as anotações em `experimental/RESULTADOS.md`)
- [CONTRATO](../../../CONTRATO.md)

## O estado de hoje

- **O jogo vibra pelo SDL:** `pad_rumble` em `nativo/nucleo/pads.c:622`
  chama `SDL_RumbleGamepad(p->gp, baixo, alto, dur)` (`:634`). O SDL escolhe o
  modo: firmware ≥ 2.24 (ou Edge) → o suave (byte 38 `0x04`), em escala
  cheia; firmware antigo → o seco (byte 0 `0x01`) **dividido por dois**; nos
  dois, liga `0x02` ("desligar a háptica por áudio") enquanto o motor vibra
  (lido em `SDL_hidapi_ps5.c` do SDL 3.4.14).
- **O jogo nunca liga os bits de vibração no próprio pacote**, e isso é regra
  escrita em três lugares:
  - `include/forja_dualsense.h:126` — "FORJA_FX_RUMBLE / FORJA_FX_HAPTICS_SELECT:
    a vibração é do SDL";
  - `include/forja_dualsense.h:156` —
    `#define FORJA_BITS1_PROIBIDOS (FORJA_FX_RUMBLE | FORJA_FX_HAPTICS_SELECT)`,
    que `forja_fx_da_sombra` apaga de todo pacote (`src/forja_dualsense.c:156`);
  - `nativo/testes/prova_efeitos.c:68` — a prova "HAPTICS_SELECT e rumble
    nunca saem do payload (a háptica por áudio vive)".
- **A ferramenta de bancada já manda o seco:** `forja-send` (cabo, USB `0x02`)
  monta o pacote com `fx->enable1 |= FORJA_FX_RUMBLE | FORJA_FX_HAPTICS_SELECT`
  (`src/forja_dualsense.c:104`). É ela que mede o seco sem mudar o jogo.
- A F05 registra o firmware de cada controle na conexão e o
  `rumble_escala_cheia` (se o SDL manda sem o corte pela metade).

## O alvo

### Parte A — a medição (sempre)

Um roteiro de bancada, **sem mudar o jogo**: o André segura um controle no
cabo, de olhos fechados, e sente pares de vibração — uma pelo jogo (suave,
pelo SDL) e outra pelo `forja-send` (seco) — na mesma força, em ordem
sorteada, e diz qual sentiu mais forte e qual prefere para "golpe", "acerto"
e "explosão".

- `experimental/rumble_seco.sh`: para cada força (25%, 50%, 75%, 100%) e
  cada duração (80, 250, 400 ms), sorteia a ordem, toca o suave pelo jogo
  (`./run-local.sh -- --experimento=haptico` já toca por sensação; ou um
  modo novo do experimento que toca por força) e o seco pelo
  `bin/forja-send`, e pergunta no terminal "1 ou 2?". Grava em
  `experimental/RESULTADOS.md` com o firmware do controle.
- Três controles, se houver: um com firmware antigo, um novo, e o Edge.

### Parte B — só se o seco vencer

Vence se, em pelo menos dois terços dos pares de força 75% e 100%, o André
sente o seco mais forte **e** prefere o seco para "golpe" e "explosão".

1. **A emenda ao CONTRATO**, com este texto, na seção "O que o jogo recusa"
   (ou uma seção nova "O rumble seco"):

   > O jogo pode ligar `FORJA_FX_RUMBLE` e `FORJA_FX_HAPTICS_SELECT` no
   > próprio pacote de 47 bytes, **só** para o rumble seco de um lugar que o
   > escolheu nas opções, **só** pelo `SDL_SendGamepadEffect` (USB `0x02` no
   > cabo; no rádio, quem traduz é quem estiver na frente do hidraw), e
   > nunca ao mesmo tempo que a háptica por áudio daquele lugar. Ao parar, o
   > pacote volta sem os dois bits, e a háptica por áudio volta a viver.
   > Medido em `experimental/RESULTADOS.md` (data).

2. `include/forja_dualsense.h`: o comentário da linha 126 passa a citar a
   emenda; `FORJA_BITS1_PROIBIDOS` continua proibindo os dois bits **na
   sombra**; uma função nova é o único caminho:

   ```c
   /* O rumble seco (emenda de <data> ao CONTRATO): o único pacote que liga
    * FORJA_FX_RUMBLE e FORJA_FX_HAPTICS_SELECT. motor 0..255, sem corte. */
   void forja_fx_rumble_seco(ForjaDs5Effect *fx, ForjaSombra *s, uint8_t esq, uint8_t dir);
   ```

   Com `esq == 0 && dir == 0`, ela manda o pacote **sem** os dois bits (a
   háptica por áudio volta).
3. `nativo/nucleo/pads.c`: `Pad.rumble_seco` (bool, das opções do lugar);
   `pad_rumble` desvia: com `rumble_seco`, **não** chama `SDL_RumbleGamepad`
   (senão o reenvio de 2 s do SDL sobrescreve), monta o pacote pela função
   nova e manda por `enviar()`; o prazo (`rumble_ate_ms`) para o motor pelo
   mesmo caminho. O evento `saida` ganha `"modo": "seco"` ou `"suave"`.
4. `nativo/testes/prova_efeitos.c:68`: a prova continua valendo para a
   sombra; uma prova nova confere que só `forja_fx_rumble_seco` liga os dois
   bits, que o motor vai sem corte, e que o pacote de parar sai sem eles.
5. `godot/scripts/opcoes.gd` e `godot/scripts/ui/tela_opcoes.gd`: a opção do
   lugar "Vibração: Suave / Seca" (padrão: o que a medição mostrou melhor),
   gravada em `Opcoes`, passada ao módulo (`ctl.rumble_seco(l, sim)`).
6. **Háptica por áudio e rumble seco no mesmo lugar:** o jogo nunca toca os
   dois juntos (a regra da F05 já vale); com o seco, a sensação que ia pela
   háptica por áudio naquele instante vai pelo rumble.
7. `docs/jogo/05-haptica-e-controle.md`: a suspeita (c) fechada, com o
   resultado; a "decisão de contrato em aberto" vira a emenda.

### Parte B' — se o seco perder

A ficha fecha só com a Parte A: o resultado em
`experimental/RESULTADOS.md`, a suspeita (c) fechada em 05 com "o suave
basta", e nenhuma linha de código muda.

## Passos

1. Ler as anotações da F05 em `experimental/RESULTADOS.md`.
2. Escrever `experimental/rumble_seco.sh` (Parte A) e combinar com o André a
   rodada. **A sessão para aqui** e espera o resultado dele — não segue para
   a Parte B sem o resultado escrito.
3. Com o resultado: Parte B (passos 1 a 7 do alvo) ou Parte B'.
4. `scripts/compilar.sh testes` e `scripts/compilar.sh linux` (sem o jogo
   aberto), `bash tests/prova_do_jogo.sh`, `bash tests/prova_da_bancada.sh`.

## Armadilhas

- **Nunca rodar a Parte B sem a emenda escrita no CONTRATO no mesmo
  commit.** O COMO-CONTRIBUIR manda: patch que quebra o contrato está errado.
- **O SDL reenvia o rumble a cada 2 s:** com o seco, o lugar não pode ter
  nenhum `SDL_RumbleGamepad` em curso, nem de zero (um zero do SDL também
  manda pacote).
- **O kernel no Linux** (`hid-playstation`) pode mandar pacote com motor
  zero por cima (suspeita **d** da F05): medir a Parte A com o que a F05
  descobriu sobre isso.
- **O rádio:** o seco no rádio depende da ponte traduzir o byte 0; o
  registro diz o modo, e a noite de seis horas cruza (08).
- **O Edge e o firmware antigo** se comportam diferente no SDL; a medição
  anota o firmware de cada controle.
- `forja-send` recusa controle no rádio (de propósito): a Parte A é no cabo.

## Não fazer

- Não mandar `0x31` nem traduzir para o rádio.
- Não mexer na sombra (`forja_fx_da_sombra`): ela continua apagando os dois
  bits de todo pacote que não é o rumble seco.
- Não tornar o seco o único modo: é opção do lugar.

## Pronto quando

A Parte A está anotada em `experimental/RESULTADOS.md` com o firmware de cada
controle; e **ou** a Parte B está feita, com a emenda no CONTRATO, a função
nova, as provas e a opção do lugar, **ou** a Parte B' fechou a suspeita (c)
sem código.

## Provas

- Na sessão: `scripts/compilar.sh testes` (a prova nova do pacote seco),
  `bash tests/prova_do_jogo.sh`, `bash tests/prova_da_bancada.sh`, e em
  `godot/testes/prova_do_jogo.gd`, com a opção ligada num lugar simulado:

  ```gdscript
  Opcoes.rumble_seco[0] = true
  Forja.sentir(0, "golpe")
  var linhas := _linha_do_tempo().filter(func(d): return d.get("tipo") == "saida" and d.get("o") == "vibracao" and int(d.get("lugar", -1)) == 0)
  _esperar(not linhas.is_empty() and str(linhas[-1].get("modo", "")) == "seco", "rumble seco: o registro diz o modo")
  ```

- Com o André, local: a Parte A inteira, e depois uma partida de cinco com
  a opção seca num lugar e suave noutro.

## Para o André (local)

A Parte A é você de olhos fechados, um controle no cabo, dizendo "1 ou 2" em
cada par. Uns 10 minutos por controle. Depois, se o seco vencer, jogar uma
partida com os dois modos e dizer qual prefere.

## Ao terminar

Marcar F10 como **feito** no [quadro](README.md), com o gasto e o resultado
(seco ou suave). Commit sugerido: com Parte B,
`feat: o rumble seco como opção do lugar, com a emenda ao contrato e a medição`;
só com Parte A, `docs: a medição do rumble seco — o suave basta`.

## O que foi feito (leva 1, o-controle)

Só a **parte A**, o código e a régua; a rodada às cegas é do André, e a ficha **para aqui** (o que
ela mesma manda: não segue para a parte B sem o resultado escrito).

- **O roteiro** `experimental/rumble_seco.sh`: um controle no cabo; 12 pares (25, 50, 75 e 100% de
  força × 80, 250 e 400 ms), cada um com a ordem suave/seco sorteada (`--semente` repete o sorteio,
  `--rodadas` repete os pares); o suave vem do jogo, o seco do `bin/forja-send`; a pergunta é
  «qual sentiu mais forte: 1, 2 ou igual», e no fim a preferência para golpe, acerto e explosão. Imprime
  o veredito pela regra da ficha (o seco vence se foi o mais forte em dois terços dos pares de 75% e
  100% **e** é o preferido para golpe e explosão) e a linha pronta para a seção `rumble-seco` do
  `experimental/RESULTADOS.md`, com o firmware que o jogo leu do controle. `--ensaio` mostra o roteiro
  sem abrir o jogo nem tocar no controle.
- **O lado do jogo**: o experimento `forca` na bancada (`godot/scripts/salas/bancada.gd`) vibra os dois
  motores numa força só, pelo caminho do SDL, e obedece a um arquivo de comandos (`--comando=ARQUIVO`:
  `LUGAR FORCA MS`, `parar LUGAR`, `fim`), respondendo no `ARQUIVO.ok` com o firmware. Para isso o
  `forja.gd` ganhou `Forja.sentir_forca` (uma exceção declarada à tabela de sensações, só da bancada)
  e `Forja.argumento`. Fica de fora do `rodar.sh` padrão (precisa do `--comando`).
- **A régua**: `tests/prova_da_bancada.sh` roda o `forca` com um arquivo de cinco comandos (3 medidos,
  `parar`, `fim`; o jogo responde cinco linhas) e com `--defeitos=vibra-vizinho` (3 falham). Nenhum
  aparelho é tocado.

**Provas:** `bash tests/prova_da_bancada.sh` verde (`forca` 3 de 3 medidos; `vibra-vizinho` 3 de 3
falham); `bash tests/prova_do_jogo.sh` verde, que ainda confere que só o `forja.gd` chama `Forja.vibrar`.

**Para o André (local):** `make bin/forja-send`, um DualSense no cabo e `experimental/rumble_seco.sh`
(uns 10 minutos por controle; um de firmware antigo, um novo e o Edge, se houver). Colar a linha que
o roteiro imprime em `experimental/RESULTADOS.md` e avisar: se o seco vencer, vem a parte B.

**Para a parte B (achados de leitura, não de execução):**
- `forja_ds5_pack` (`src/forja_dualsense.c`) só liga `FORJA_FX_RUMBLE` quando um motor é diferente de
  zero. Um pacote «de parar» sem esses bits não manda o motor parar no aparelho: a função nova
  `forja_fx_rumble_seco` precisa mandar **um** pacote com o bit ligado e os dois motores em zero
  antes de voltar ao pacote sem os bits (a ficha diz «sem os dois bits», o que deixaria o motor
  ligado). O roteiro de hoje para o seco com `parar` pelo SDL; se o motor continuar vibrando depois de
  um par, é este o sintoma.
- O `forja-send` manda um pacote só e não para: o roteiro manda o parar pelo jogo (`SDL_RumbleGamepad`
  em zero). Anotar no resultado se o motor parou sozinho.
