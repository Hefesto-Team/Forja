# ADR-008: a metodologia Astro Bot, e o repertório inteiro em toda sala

**Status:** aceito · **Data:** 2026-10-02 · **Amplia:** [a régua Astro Bot](../jogo/10-a-regua-astro-bot.md) e o [princípio 2](../jogo/02-principios.md#2-a-feature-protagoniza-o-repertório-acompanha)

## Contexto

O Forja já tinha a régua Astro Bot (24 lições) e o princípio da feature
protagonista. O que faltava era o **método**: como a Team Asobi chega àquelas
sensações, na ordem em que chega. Em 02/10/2026 a pesquisa de
[estudo 05](../estudos/05-o-dualsense-do-astro-bot.md) juntou o que a Sony e o
estúdio dela publicaram abertamente — entrevistas de Nicolas Doucet, a ementa
da palestra de Masayuki Yamada no GDC 2025, a Famitsu, a CEDEC, o PlayStation
Blog — mais o código aberto que descreve o aparelho (kernel Linux, SDL).

Nada do SDK da Sony entrou, nem entrará: ele é sob NDA
([AGENTS.md](../../AGENTS.md)). O que se replica aqui é **método publicado**,
não código fechado.

Duas coisas da pesquisa mudam o que fazíamos:

1. **O háptico da Asobi não é um motor ligando e desligando: é forma de onda.**
   Doucet: *"The haptic feedback is sound-based… these are sounds you cannot
   hear, but they resonate."* Quem programou o háptico do Astro Bot foi o mesmo
   engenheiro do controle do personagem, não um time separado no fim da
   produção.
2. **Nenhuma sensação entrou no Astro Bot sem uma demo isolada antes.** Foram
   cerca de 80 protótipos no Playroom, de uns quinze dias cada, um efeito por
   demo. A esponja só virou poder porque a demo já existia: *"If somebody came
   with a thing on paper without that prototype… Let's not do it."*

E uma coisa precisava ser dita com todas as letras, porque o princípio 2 era
lido ao contrário na prática: "feature protagonista" virou desculpa para uma
sala usar **só** aquela feature.

## Decisão

### 1. Nenhuma sala do Forja tem uma feature só

As nove seções continuam tendo um **verbo** protagonista — é o que dá nome e
identidade à seção. Mas o verbo não é uma cota: **toda sala, de qualquer
seção, usa o máximo de recursos do controle que ela consegue sustentar.** A
seção escolhe o verbo; o repertório inteiro acompanha, sempre.

O chão de cada minigame, conferido na ficha dele:

| recurso | o mínimo em **toda** sala |
| --- | --- |
| luzinhas de jogador | o número do jogador, do começo ao fim |
| barra de luz | a cor do jogador; pisca no acerto, escurece no erro |
| vibração | todo evento físico do cavaleiro de quem segura o controle |
| alto-falante do controle | o som pessoal: a entrada, o acerto, a coleta |
| gatilho | peso quando há o que segurar; `OFF` declarado quando não há |
| som na TV | o que todos precisam ouvir |
| registro | o que cada controle recebeu, para o Modo bancada |

Uma sala que não usa um deles **declara por que** na ficha. "Não deu tempo"
não é motivo; "a sala mede silêncio e o alto-falante sujaria a medida" é.

### 2. O método da Asobi é o nosso método, nesta ordem

1. **A sensação primeiro, na bancada.** Antes de virar minigame, o efeito
   nasce como experimento isolado em `experimental/`, rodado pelo
   [Modo bancada](../jogo/tarefas/F01-o-modo-bancada.md). Um efeito por
   experimento. É o equivalente das 80 demos.
2. **Ideia sem protótipo não entra.** Se a sensação só existe no texto da
   ficha, a ficha espera. Vale para minigame e para item.
3. **Quem faz o movimento faz o háptico.** A mesma sessão que escreve a
   mecânica escreve a vibração dela. Não existe "passe de háptica" depois.
4. **Poucos materiais, de contraste alto.** A tabela de materiais
   ([05](../jogo/05-haptica-e-controle.md#a-háptica-por-material)) é curta de
   propósito: metal, pedra, gelo, pano, água. A meta da Asobi — reconhecer a
   troca de textura **de olhos fechados** — é a nossa prova de aceitação.
5. **Prioridade e reserva.** As camadas competem e a mais importante vence; as
   outras ficam embaixo, em crossfade. A intensidade máxima é **guardada**
   para o pico do minigame: se tudo é forte, nada é forte.
6. **Ver, ouvir e sentir no mesmo quadro e no mesmo lugar.** O som do evento
   do jogador sai no alto-falante **do controle dele**, não na TV. Um evento
   só está pronto quando os três batem juntos.

### 3. O que isso **não** autoriza

- Não muda o [CONTRATO](../../CONTRATO.md). Gatilho segue só `OFF`,
  `FEEDBACK`, `WEAPON`, `VIBRATION`; nada de Bluetooth `0x31`; nada de MAC.
- Não vira metalinguagem: a sala continua sem perguntar nada sobre o controle
  ([F02](../jogo/tarefas/F02-sem-metalinguagem.md)).
- Não encosta no SDK da Sony.

### 4. Uma pergunta fica aberta, de propósito

O háptico por forma de onda do Astro Bot não cabe no relatório `0x02`: ele
anda pelos canais traseiros (RL/RR) da placa de áudio USB do próprio controle,
e ligar a vibração compatível do `0x02` **desliga** esse caminho (na SDL,
`ucEnableBits1 |= 0x02 // Disable audio haptics`; no kernel,
`DS_OUTPUT_VALID_FLAG0_HAPTICS_SELECT`). As duas coisas não convivem no mesmo
controle.

Enquanto o CONTRATO não ganhar uma linha para isso, o Forja fica na **vibração
compatível** — pancada grossa, não gota nem areia — e o resto do método vale
igual. Abrir ou não o caminho por áudio é uma decisão de produto que pede ADR
próprio, e esse ADR precisa responder a quatro coisas: casar placa e controle
pelo aparelho (nunca por MAC), proibir a vibração compatível nesse modo, dizer
o que acontece sem cabo, e o ajuste global de força.

## Consequências

- **O quadro muda de ordem de leitura.** Toda ficha de minigame (I a Q) passa
  a conferir a tabela do item 1 antes de ser dada como pronta.
- **A bancada vira pré-requisito, não sobra.** Um efeito novo começa em
  `experimental/`; a ficha do minigame cita o experimento que o provou.
- **O princípio 2 continua valendo, com a leitura corrigida**: a feature
  protagoniza o *verbo*, não o *repertório*.
- **A linha 4 da régua** ("uma fase, um recurso protagonista") lê-se agora
  como "uma fase, um verbo protagonista".
- **O registro ganha peso**: é ele que prova que os sete recursos saíram, já
  que a sala não pode perguntar ao jogador.
- **Todo número do DualSense nos nossos documentos é medida nossa, e diz
  isso.** A Sony recusa publicar latência, frequência de ressonância, resposta
  em frequência e curva de força do gatilho — quatro recusas registradas na
  entrevista do chefe de projeto de periféricos da SIE ([estudo 05, adendo
  §3](../estudos/05-o-dualsense-do-astro-bot.md)). Faixa que aparecer sem
  rótulo de origem sai do documento.
- **O teto de frequência do háptico tem fundamento publicado**: o aparelho é
  de banda larga e quem corta o agudo é um filtro em software, porque acima
  dele a vibração passa a ser *ouvida*. O critério é perceptual, não um número
  do fabricante — e é assim que a tabela de materiais o escreve.
- **Falta uma pré-escuta do háptico.** A Sony construiu um ambiente de autoria
  de forma de onda ao lado do motor de som; o nosso motor existe
  (`nativo/som/sintese.c`) e a ferramenta de desenhar e sentir antes de entrar
  no jogo, não. Vira ficha.
- **O estudo 05 é a fonte**, com as lacunas anotadas nele: o conteúdo pago da
  GDC Vault, a ferramenta interna da Asobi e a resposta em frequência medida
  do atuador continuam desconhecidos.
