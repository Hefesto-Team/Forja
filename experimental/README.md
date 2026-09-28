# experimental/ — a bancada dos experimentos

> **Neste marco a bancada está parada.** Ela rodava dentro do app 2D, que saiu
> do branch ([ADR-007](../docs/adr/007-o-jogo-e-o-3d-em-godot.md)); volta no
> marco 5, pelo módulo nativo do jogo 3D. O que foi medido antes continua em
> [RESULTADOS.md](RESULTADOS.md).

Cada experimento é uma pergunta que o jogo ainda não sabe responder com
certeza — sobre o alto-falante, os microfones, a háptica e o gatilho do
DualSense — medida no aparelho e **gravada inteira**: o que funcionou, o que
falhou e o que não deu para medir, com o porquê. Nada daqui decide veredito
das salas; é o caderno de bancada de quem valida o Hefesto.

O código mora em `experimental/src/` e entra no mesmo binário do jogo (usa o
mesmo som por controle e o mesmo simulador): `experimentos.c` é a cena,
`analise.c` é a lógica pura, provada sem aparelho em
`demo/testes/prova_experimentos.c`.

## Como rodar

```sh
./run-local.sh -- --experimento laco          # Linux, com os controles na mesa
experimental/rodar.sh                          # os cinco, um depois do outro
```

No Windows, ou no `.exe` pelo Proton, ponha `--experimento laco` nas opções de
inicialização. Abre a mesa de sempre — cada jogador aperta ✕ — e o
experimento entra no lugar do salão. No fim, ✕ repete e ○ volta ao título;
Options para no meio.

Sem controle, `--simular 4 --robo` roda o experimento com controles de
mentira: prova que a bancada anda, e o que precisa de aparelho de verdade sai
"não medido". Os defeitos de mentira (`--defeito`) valem na bancada também.

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

## As regras

As mesmas do jogo: o `CONTRATO.md` (nada de socket do Hefesto, de MAC, de
relatório `0x31`), nenhum caminho da máquina no código nem no registro, e nada
do SDK da Sony.
