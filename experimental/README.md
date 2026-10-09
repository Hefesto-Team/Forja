# experimental/ — a bancada dos experimentos

Cada experimento é uma pergunta que o jogo ainda não sabe responder com
certeza — sobre o alto-falante, os microfones, a háptica e o gatilho do
DualSense — medida no aparelho e **gravada inteira**: o que funcionou, o que
falhou e o que não deu para medir, com o porquê. Nada daqui decide veredito
das salas; é o caderno de bancada de quem valida o Hefesto.

A bancada roda dentro do jogo 3D, pelo mesmo módulo nativo das salas (o mesmo
som por controle, o mesmo simulador): a sala é
`godot/scripts/salas/bancada.gd`; a escuta crua do microfone, o report cru e
o resultado de cada medida estão em `nativo/godot/forja_bancada.cpp`; a
análise é `nativo/nucleo/analise.c`, lógica pura provada sem aparelho em
`nativo/testes/prova_experimentos.c`.

## Como rodar

```sh
./run-local.sh -- --experimento=laco          # Linux, com os controles na mesa
experimental/rodar.sh                          # os seis, um depois do outro
experimental/rodar.sh -- --simular=4 --robo    # a rodada de teste, sem aparelho
bash tests/prova_da_bancada.sh                 # a prova da bancada (o CI roda)
```

No Windows, ou no `.exe` pelo Proton, ponha `--experimento=laco` nas opções de
inicialização. Todos os controles conectados entram na mesa, cada um no seu
lugar, e o experimento entra no lugar do salão. No fim, ✕ repete e ○ fecha a
sessão (o `rodar.sh` passa ao próximo); Options pausa no meio.

Sem controle, `--simular=4 --robo` roda o experimento com controles de
mentira: prova que a bancada anda, e o que precisa de aparelho de verdade sai
"não medido", com o porquê; com o robô, a sessão fecha sozinha no fim. Os
defeitos de mentira (`--defeitos=`) valem na bancada também.

## Onde fica o resultado

Na linha do tempo da sessão, `relatorios/linha-do-tempo-<sessão>.jsonl`, como
eventos `"tipo": "experimento"` — um por controle e por medida, com
`"resultado"` igual a `medido`, `falhou` ou `nao_medido` e o texto do que se
viu — e no registro, `relatorios/registro-<sessão>.log`. Depois de uma rodada
na mesa, copie as linhas para [RESULTADOS.md](RESULTADOS.md), com a data, o
lugar e a origem de cada controle (nativo, Edge virtual, Xbox virtual). Nenhum
endereço de aparelho entra: o jogo nunca lê MAC, e o que ele grava já sai
mascarado.

## Os experimentos

### `laco` — o laço do alto-falante

**A pergunta:** quanto tempo o som leva do jogo ao alto-falante do controle e
de volta pelo microfone do mesmo controle? E o microfone ouve os atuadores?

**Como:** para cada controle, um de cada vez, o jogo limpa o microfone, toca
um clique curto no alto-falante e grava 0,8 s; o ataque do clique na gravação
(a primeira janela de 1 ms acima de seis vezes o fundo) dá a latência de ida e
volta. Cinco cliques, a mediana. Depois, três pulsos nos atuadores: o zumbido
deles chega ao microfone?

**Precisa de:** o alto-falante e o microfone do controle achados (no cabo, a
placa de quatro canais; no rádio, os nós do Hefesto), em silêncio na sala.

**Como ler:** a latência inclui o buffer de saída do sistema, o caminho no ar
e o buffer de entrada — é o que um jogo que ouve o próprio som veria. Não
ouvir o próprio clique, com o alto-falante tocando, é falha.

### `quatro-mics` — quatro microfones ao mesmo tempo

**A pergunta:** os quatro microfones abrem juntos, chega som de todos, e cada
um é o do controle certo?

**Como:** abre os microfones de todos; dois segundos de silêncio; depois cada
jogador fala, na sua vez, perto do próprio controle. Uma matriz de níveis
(microfone × quem fala) diz se cada microfone foi o mais alto com a voz do
próprio jogador, e com que margem; a contagem de quadros diz se o som chegou
o tempo todo de todos.

**Como ler:** um microfone que é mais alto com a voz de **outro** jogador está
trocado — é de outro controle. Menos de 90% dos quadros com som é falha
(banda do USB, o servidor de som, a ponte do rádio).

### `eco` — o eco do alto-falante no microfone

**A pergunta:** quanto do alto-falante chega ao microfone do próprio controle?

**Como:** para cada controle: grava o silêncio; toca um tom de 1 kHz no
alto-falante e grava; toca o mesmo tom com a rota no fone (o alto-falante
calado) e grava. Dá quantos dB acima do silêncio o microfone subiu em cada
caso.

**Como ler:** é o que um chat de voz no controle enfrenta. Pouca diferença
entre as duas rotas quer dizer que o cancelamento de eco do controle (o bit 2
do controle de áudio, que o jogo deixa ligado) está segurando o alto-falante.

### `gatilho-cru` — os bytes do gatilho

**A pergunta:** que bytes do report USB `0x01` mudam com o modo do gatilho
(Off, Feedback, Weapon, Vibration), e quais só com o aperto?

**Como:** só em DualSense no cabo, com o report cru. Quatro segundos em cada
modo, com a pessoa apertando o R2 devagar até o fundo e soltando; para cada
byte de 32 a 63, o jogo guarda o que ele valeu com o gatilho solto e com o
gatilho apertado, em cada modo.

**Como ler:** os bytes "do modo" são candidatos ao estado do efeito que o
controle devolve; os "do aperto", à posição do gatilho sob o efeito. É
exploração: o resultado diz os números dos bytes, e o que eles significam fica
para quem comparar rodadas.

### `haptica-nomeada` — a háptica pelo nó do Hefesto

**A pergunta:** a háptica chega pelo nó «Háptica do Controle N (DualSense
Wireless Controller)» — o caminho do rádio — dos dois lados?

**Como:** todos ao mesmo tempo, cada um no seu controle: quatro pulsos, dois
de cada lado em ordem sorteada; a pessoa diz o lado (L1 esquerda, R1 direita,
touchpad "não senti"). O resultado diz o nó usado e **como** ele foi achado
(pelo aparelho, pelo número, pelo nome).

**Como ler:** no cabo, o nó é a placa de quatro canais; no rádio, só existe
se o Hefesto o publicar. Três de quatro lados certos passa; "não senti" diz
que nada chegou.

### `haptico` — o háptico forte

**A pergunta:** cada sensação da tabela do jogo (`Forja.SENSACOES`) chega
inteira ao motor de cada controle? E o firmware de cada um, e a escala de
vibração das opções, ajudam a explicar um háptico fraco?

**Como:** um controle de cada vez, as nove sensações na ordem da tabela, 1,5 s
entre uma e outra. O nome da sensação não aparece na tela: quem sente não
sabe qual é. No simulador, a bancada mede sozinha o que chegou ao motor
(forte e fraco, com a escala do lugar) e não pergunta. No aparelho, pergunta
a cada pulso: **✕ senti · ○ não senti**; sem resposta em 2 s, "não medido".

**Como ler:** cada linha traz o nome, os valores pedidos, o que chegou, o
firmware (`0x0224`, o mesmo do evento `conexao`) e a escala. No aparelho, anote
no [RESULTADOS.md](RESULTADOS.md) o firmware e quais sensações não foram
sentidas: é com essas linhas, no cabo e no rádio, que se decide o resto das
suspeitas do [05](../docs/jogo/05-haptica-e-controle.md#a-medição).

### `forca` e o roteiro do rumble seco

**A pergunta:** o rumble «seco» (o pacote antigo, byte 0 `0x01`) se sente mais
forte que o «suave» que o SDL manda em firmware novo (byte 38 `0x04`)? É a
suspeita **c** do [05](../docs/jogo/05-haptica-e-controle.md#a-medição), e a
[F10](../docs/jogo/tarefas/F10-o-rumble-seco.md) decide o que fazer com a resposta.

**Como:** `experimental/rumble_seco.sh`, com **um** DualSense **no cabo**. O
roteiro sorteia pares na mesma força (25, 50, 75 e 100%) e duração (80, 250 e
400 ms): uma vibração suave, pelo jogo, e uma seca, pelo `bin/forja-send`, em
ordem sorteada. De olhos fechados, você diz qual sentiu mais forte (1, 2 ou
igual) e, no fim, qual prefere para golpe, acerto e explosão. O experimento
`forca` é só o lado do jogo: ele vibra os dois motores na força pedida e
obedece a um arquivo de comandos (`--comando=ARQUIVO`, uma linha por comando:
`LUGAR FORCA MS`, `parar LUGAR`, `fim`), respondendo no `ARQUIVO.ok` com o
firmware do controle. `rumble_seco.sh --ensaio` mostra o roteiro sem tocar em
nada. O `forja-send` recusa o rádio de propósito: esta medição é no cabo.

**Como ler:** o roteiro imprime o veredito pela regra da F10 (o seco vence se,
em dois terços dos pares de 75% e 100%, foi o mais forte **e** é o preferido
para golpe e explosão) e a linha pronta para a seção `rumble-seco` do
[RESULTADOS.md](RESULTADOS.md). Rode uma vez por controle (firmware antigo,
novo e Edge, se houver). O seco para pelo próprio `forja-send` (um pacote com
os motores em zero, sem os bits de rumble, como o SDL para o dele); se o motor
continuar vibrando depois do par, anote: é um achado para a parte B da F10.

## As regras

As mesmas do jogo: o `CONTRATO.md` (nada de socket do Hefesto, de MAC, de
relatório `0x31`), nenhum caminho da máquina no código nem no registro, e nada
do SDK da Sony.
