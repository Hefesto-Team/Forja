# 04 O cavaleiro montável

Cada pessoa monta o seu cavaleiro: cabeça, tronco superior, tronco inferior
e uma arma ou um amuleto, e dá o nome a ele. A sensação que a tela tem que
dar é de posse: "este é meu, eu montei, e a minha build é boa".

Os stats desta página são **proposta**. Os números servem para a G13 começar
e para a noite de seis horas medir; nenhum deles é lei até ela dizer.

## O que a pessoa sente

1. **Já tem um cavaleiro quando chega.** O lugar nasce com um pré-montado
   sorteado e válido. Com ✕ ✕ já se joga.
2. **Cada troca muda alguma coisa que se vê.** A peça troca no boneco, o VU
   do stat sobe ou desce, o arquétipo na etiqueta pode mudar.
3. **Uma escolha impede outra.** Não dá para ter tudo. A build é uma decisão.
4. **Ninguém na mesa tem um igual.** Nem o mesmo corpo, nem o mesmo item, nem
   o mesmo nome.
5. **O nome é dela.** Escrito na caneta, na etiqueta, e dito no pódio.

## As peças

O corpo vem do Kenney Mini Characters: 12 personagens (female-a a f, male-a
a f), todos com o mesmo esqueleto de 7 ossos (root, leg-left, leg-right,
torso, arm-left, arm-right, head) e as mesmas 32 animações.

### O corte

Cada glb tem duas malhas com pele: `head-mesh` e `body-mesh`. Na `body-mesh`,
**nenhum triângulo é misto**: cada um pertence a um osso só (conferido
triângulo a triângulo). O corte é limpo:

| parte | de onde vem | triângulos (female-b) |
| --- | --- | --- |
| cabeça | a `head-mesh` inteira | de 288 a 340, conforme o personagem |
| tronco superior | os triângulos da `body-mesh` dos ossos torso, arm-left e arm-right | 50 + 72 + 72 |
| tronco inferior | os triângulos da `body-mesh` dos ossos leg-left e leg-right | 104 + 104 |

O corte se faz uma vez, por script, e gera três malhas por personagem. Como o
esqueleto é o mesmo, qualquer cabeça encaixa em qualquer superior e em
qualquer inferior, e as 32 animações servem para todas. São 12³ = 1728
corpos.

### O perfil de cada peça

Cada peça dá 3 pontos de stat, num de seis perfis. Cada perfil aparece duas
vezes em cada parte. A peça de um personagem nunca tem o mesmo perfil das
outras duas dele, então o personagem "original" da Kenney é sempre
equilibrado.

| perfil | dá |
| --- | --- |
| Bigorna | Peso +2, Fôlego +1 |
| Mola | Passo +2, Faro +1 |
| Brasa | Fôlego +2, Peso +1 |
| Lume | Faro +2, Passo +1 |
| Malha | Peso +1, Passo +1, Fôlego +1 |
| Prumo | Faro +1, Fôlego +1, Passo +1 |

| personagem | cabeça (perfil, pio) | superior | inferior |
| --- | --- | --- | --- |
| female-a | Bigorna, a segunda | Brasa | Malha |
| female-b | Mola, a terça | Lume | Prumo |
| female-c | Brasa, a quarta | Malha | Bigorna |
| female-d | Lume, a quinta | Prumo | Mola |
| female-e | Malha, a quinta de baixo | Bigorna | Brasa |
| female-f | Prumo, a oitava | Mola | Lume |
| male-a | Bigorna, a segunda | Brasa | Malha |
| male-b | Mola, a terça | Lume | Prumo |
| male-c | Brasa, a quarta | Malha | Bigorna |
| male-d | Lume, a quinta | Prumo | Mola |
| male-e | Malha, a quinta de baixo | Bigorna | Brasa |
| male-f | Prumo, a oitava | Mola | Lume |

O pio de cada cabeça está em [03 O som](03-som.md#o-pio). O nome que a
pessoa lê em cada peça (até 14 caracteres, dizendo o que se vê: "Coque
alto", "Jaqueta curta") a G13 escreve olhando o modelo.

### A cadeira de rodas

O pacote traz quatro cadeiras (`wheelchair`, `wheelchair-deluxe`,
`wheelchair-power`, `wheelchair-power-deluxe`) e as animações
`wheelchair-sit`, `-look-left`, `-look-right`, `-move-forward`, `-back`,
`-left` e `-right`. No tronco inferior, ▲ e ▼ ficam na parte e um toque em
R1 alterna "Pernas" e as quatro cadeiras. A cadeira **não muda stat
nenhum**: o perfil é o da peça inferior escolhida. Em minigame de corrida, a
cadeira anda na mesma velocidade que as pernas com o mesmo Passo.

Os acessórios do mesmo pacote (`aid-glasses`, `aid-sunglasses`,
`aid_hearing`, `aid-cane`) entram como acabamento da coleção, sem stat.

## Os stats

Quatro, de 1 a 5. Nenhum mexe na janela de julgamento nem na pontuação: eles
mudam o corpo, não o ouvido. Quem joga bem no tempo ganha com qualquer
cavaleiro.

| stat | o que muda | a conta (proposta) |
| --- | --- | --- |
| **Peso** | a massa na física: empurrão, sabotagem, coice | massa ×(0,8 + 0,1·Peso) |
| **Passo** | a velocidade de andar e de correr | velocidade ×(0,9 + 0,05·(Passo − 1)) |
| **Fôlego** | o tempo para levantar depois de cair ou ser atordoado | 1,2 s − 0,15 s·(Fôlego − 1) |
| **Faro** | a antecedência da pista (vibração, bipe, textura) | 20 ms·(Faro − 1), de 0 a 80 ms |

A conta: cada stat começa em 1, e as três peças somam 9 pontos. Nenhum stat
passa de 5; o ponto que passaria se perde, e o VU mostra o ponto perdido
piscando uma vez em `GRAFITE`. Montar mal é possível, e se vê.

### A regra que impede

**Peso + Passo ≤ 7.** Quem é pesado não é rápido. A peça que faria a soma
passar de 7 aparece na lista com a borda em `GRAFITE` e um traço de caneta
por cima, e ◀▶ pula ela. A soma usa os stats já com o teto de 5. Ela passa
de 7 quando as três peças são de Bigorna, Mola ou Malha e misturam o pesado
com o rápido: 152 dos 1728 corpos (conferido por script). Sobram 1576.

Dos 1576 corpos válidos, cada item cabe em: Escudo 1360, Diapasão 1328, Fole
1248, Lanterna 1056, Martelo 928, Âncora 472. A Âncora é a mais difícil de
alcançar, e por isso é a mais forte no doc 06b.

## A arma ou o amuleto

Seis itens, os mesmos do doc 06b: três armas e três amuletos. Cada um pede
um stat mínimo. É aqui que uma escolha de corpo abre ou fecha um item.

| item | tipo | onde fica | pede | o modelo |
| --- | --- | --- | --- | --- |
| Martelo | arma | mão direita | Peso ≥ 3 | `tool-hammer` (Survival Kit) |
| Escudo | arma | braço esquerdo | Peso ≥ 2 | `shield-round` (Mini Dungeon) |
| Âncora | arma | mão direita | Peso ≥ 4 | por código (ArrayMesh) |
| Fole | amuleto | peito | Fôlego ≥ 3 | por código |
| Lanterna | amuleto | peito | Faro ≥ 3 | por código |
| Diapasão | amuleto | peito | Faro ≥ 2 e Fôlego ≥ 2 | por código |

Armas pedem Peso; amuletos pedem Fôlego e Faro. O corpo pesado empunha, o
corpo leve carrega. Todo corpo tem pelo menos um item possível: com Peso 1,
as três peças são de Mola, Lume ou Prumo, e o Faro chega a 4 (a Lanterna).

O efeito de cada item é o do doc
[06b](../06b-a-construcao-do-cavaleiro.md#o-item-tem-mecânica). Os amuletos
são medalhões de 12 cm presos no peito, desenhados por código no mesmo estilo
da bigorna (metal fosco `metallic` ≤ 0,2, o emblema em relevo), com o
contorno na cor do dono.

### A liga

Quando o corpo supera o pedido do item em 2 ou mais (Peso 5 com o Martelo,
que pede 3), a peça está **em liga** com o corpo: o efeito sobe um nível e,
ao entrar na liga, o acorde do lugar toca no controle. É o prêmio de quem
montou pensando. Os níveis de cada item estão no doc 06b.

"Liga" é a palavra porque "Afinado" já é o julgamento ótimo (doc 07).

### O arquétipo

Os dois stats mais altos dão o nome do tipo do cavaleiro, escrito na etiqueta
em Permanent Marker. No empate, vale a ordem Peso, Passo, Fôlego, Faro.

| os dois mais altos | arquétipo |
| --- | --- |
| Peso e Passo | Aríete |
| Peso e Fôlego | Muralha |
| Peso e Faro | Torre |
| Passo e Fôlego | Corrente |
| Passo e Faro | Relâmpago |
| Fôlego e Faro | Eco |

## Entre jogadores

Na mesa, ninguém repete:

- **o item é único por mesa.** Quem pegou o Martelo primeiro fica com ele. Na
  lista dos outros, o Martelo aparece com o P# e a sublinha na cor de quem
  pegou, e ◀▶ pula ele;
- **o corpo é único.** Duas pessoas não montam as mesmas três peças;
- **o nome é único.**

A leitura de "um impedindo o outro de escolher" é esta (a escolha de um
fecha a do outro). A regra de dentro da build (Peso + Passo) também impede.
**Falta ela confirmar** se quer as duas, ou só uma.

## O pré-montado

Todo lugar nasce montado. O sorteio usa a semente
`Forja.semente * 31 + lugar` e escolhe, nesta ordem:

1. as três peças, entre as que passam na regra de Peso + Passo e não repetem
   o corpo de ninguém;
2. o item, entre os que o corpo pode e ninguém pegou;
3. o nome, entre os 24 de `NOMES` que ninguém usa.

Se o item ficar sem opção, o sorteio refaz as peças. O pré-montado é sempre
válido.

## A tela de montagem

O plano é o de [01 O cinema](01-cinema.md#o-plano-de-cada-momento): 50 mm,
frontal, à altura do peito, os quatro lugares lado a lado. A música é a da
construção, a 120 BPM, e toda troca cai na batida.

### Uma coluna

Cada lugar tem uma coluna de 432 px dentro da área segura (x = 96 + 432·i).

| y (px) | o que tem |
| --- | --- |
| 60 a 150 | a placa do lugar: P# em Bungee 40, as lâmpadas, o nome do cavaleiro em Archivo Narrow 600 de 32 px |
| 160 a 600 | o cavaleiro em 3D, de frente, no idle na batida; contra-luz na cor do lugar, chave violeta até forjar |
| 610 a 650 | a etiqueta do arquétipo, em Permanent Marker de 30 px, em `TINTA` |
| 660 a 860 | as cinco linhas: Cabeça, Superior, Inferior, Arma ou amuleto, Nome |
| 870 a 1010 | os quatro VUs: Peso, Passo, Fôlego, Faro |

Cada linha tem 40 px: o rótulo em Archivo Narrow 600 de 30 px, e
`◀ nome da peça ▶`. A linha escolhida fica em `CASCO_ALTO` com borda de 3 px
na cor do lugar. A linha travada tem um cadeado desenhado ao lado.

Cada VU tem 5 segmentos na cor do lugar, apagados em `GRAFITE`, e o rótulo
em VT323 de 30 px. Enquanto a pessoa passa por uma peça, os segmentos que
ela mudaria piscam em `ETIQUETA` na batida, antes de confirmar.

### Os botões

| botão | faz |
| --- | --- |
| ▲ ▼ | escolhe a linha |
| ◀ ▶ | troca a peça (ou o nome) |
| R1 | no tronco inferior: Pernas ou cadeira |
| △ | sorteia tudo o que não está travado |
| □ (toque) | trava ou destrava a linha |
| □ (segurar 1 s) | troca de lugar (doc 05) |
| ✕ | forja: as 8 marteladas |
| ○ | volta (desfaz a forja; da primeira linha, sai do lugar) |

As dicas na tela seguem a voz do texto: "Botão △ (Sortear)", "Botão ✕
(Forjar)".

### A forja

O ✕ começa as 8 marteladas a 120 BPM. Elas calibram o controle (doc 04) e,
na tela, forjam o cavaleiro parte por parte:

| martelada | o que acende em tungstênio |
| --- | --- |
| 1 e 2 | a cabeça |
| 3 e 4 | o tronco superior |
| 5 e 6 | o tronco inferior |
| 7 | a arma ou o amuleto |
| 8 | o nome, escrito na caneta na etiqueta (`fx_caneta`) |

Na oitava, a chave da coluna passa de violeta a tungstênio em 1 compasso, e
o pio do cavaleiro sai do controle. Quando todos estão prontos, o corte vai
para o plano dos prontos (85 mm, baixo, travelling pelos quatro).

## O nome

Os 24 de `NOMES` (G02) com ◀▶, ou o teclado de tela (G09) com ✕ na linha
Nome. Até 12 caracteres. O nome vai na etiqueta em Permanent Marker, no HUD
em Archivo Narrow, e no pódio em Bungee.

## O acabamento e a coleção

O acabamento (fosco, polido, riscado, dourado) sai da montagem: são cinco
linhas e bastam. Ele vira desbloqueio da coleção (G06), escolhido no salão,
junto com os acessórios (óculos, aparelho auditivo, bengala). Nenhum muda
stat.

## O que muda nos outros documentos

- O doc [06b](../06b-a-construcao-do-cavaleiro.md) foi reescrito com esta
  montagem.
- A G02 e a G03 ganham uma nota no topo: a G13 muda os passos e os itens.
- O doc [11](../11-arte-e-personagens.md#os-personagens) ganha uma linha que
  aponta para cá.
