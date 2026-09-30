# L — S4 — O Impacto: os cinco minigames

**Sprint:** L · **Tamanho:** G (a seção, em cinco fichas) · **Modelo:** Sonnet · **Estimativa:** US$ 8,0 (a soma das cinco) · **Depende de:** H04, H08, F09

Esta ficha é o índice da seção. O trabalho está nas cinco fichas abaixo,
uma por sessão, e cada uma se basta: a sessão lê a ficha do minigame dela,
os documentos que ela manda ler e mais nada.

## A feature protagonista

**A vibração**, os dois motores, cada um com o seu lado: o forte é o da
esquerda, o fraco é o da direita. A mão sente o golpe antes do olho. As
sensações são pedidas pelo nome, sempre por `Forja.sentir(l, nome, ms)`
([F05](F05-o-haptico-forte.md)); nenhuma sala chama `Forja.vibrar`. A seção
usa as sensações da tabela e mais nada:

| sensação | motores | na seção |
| --- | --- | --- |
| `golpe_esq` | 1,0 · 0,0 | o lado esquerdo: o golpe, a toupeira quente, o lado seguro |
| `golpe_dir` | 0,0 · 1,0 | o lado direito |
| `golpe` | 1,0 · 0,6 | os dois lados ao mesmo tempo; o golpe recebido |
| `aviso` | 0,6 · 0,0 | o passo do titã longe; o pavio da bomba |
| `explosao` | 1,0 · 1,0 | a bomba, o aríete, a prensa que esmaga |
| `toque`, `acerto`, `perfeito`, `erro` | — | o kit e o coração da bomba |

A barra de luz é a coadjuvante que **vira vida pelo brilho**: sempre a cor
do lugar, nunca abaixo de 40% de brilho (o piso do [F04](F04-p1-e-o-led.md)
é 30%). O piscar do perfeito e o escurecer do erro são do kit (`_reagir`,
H08, no máximo 0,5 s); depois dele, o minigame põe de volta o brilho da
vida. A barra nunca vira bomba nem cor de equipe. As luzinhas de
jogador mostram sempre o número do jogador. O alto-falante do dono toca o
som do impacto (`Som.no_controle(l, "escudo")`, `"golpe"`), curto e pessoal.

## O cenário comum

A arena no escuro d'O Impacto de hoje, em `godot/scripts/minigames/s04/cenario_do_impacto.gd`
(`class_name CenarioDoImpacto`, estático). A [L1](L1-o-cerco.md) o cria; as
outras quatro o usam e não o copiam:

| função | o que monta |
| --- | --- |
| `CenarioDoImpacto.montar(sala, escuro := 1.0)` | `Kit.arena(sala, 5, 3)`; `sala.atmosfera(#6fa8ff, #3b6bff, false, 30, 22, -7,8, 0,1 × escuro)`; o enchimento frio `#6b6fb0` em (0, 8, 3), energia 0,45 × escuro; duas tochas `#ffb070` em (±10, 2,4, −5), energia 0,8 × escuro. `escuro` 0,35 é o terror d'A Prensa: a luz da casa escurece, não troca ([11](../11-arte-e-personagens.md#as-regras-de-coerência), regra 7) |
| `CenarioDoImpacto.sentinela(pai, pos, alvo, escala := 1.35)` | a `column` do kit virada para `alvo`, com o olho: uma caixa emissiva `#ff4a2a` — o modelo de monstro do 11 |
| `CenarioDoImpacto.lanterna(pai, pos, cor, n := 5)` e `acender_lanterna(mats, acesas)` | o poste de ferro com `n` brasas (caixas) na cor do lugar: a vida no mundo |
| `CenarioDoImpacto.luz_com_brilho(l, brilho)` | a barra de luz na cor do lugar, com o brilho pedido e o piso de 40% |

Cada minigame põe por cima o que é só dele (o vagão, a bomba, as toupeiras,
as prensas) e usa do kit a raia (`raia(l)`, `acender_raia(l, forca)`,
`posicionar(l)`), com as raias em x = −6, −2, 2, 6 e o boneco em
`Z_JOGADOR` (1,4). A câmera é `"fixa"` em (0, 6,4, 10,8) olhando para
(0, 1,0, −0,4), a d'O Impacto de hoje, salvo onde a ficha diz outra.

## A ordem

1. [L1](L1-o-cerco.md) primeiro: ela muda a sala de hoje para o kit e cria o
   cenário comum.
2. Depois, em qualquer ordem (a sugerida é esta): [L2](L2-fuga-do-tita.md),
   [L3](L3-curto-circuito.md), [L4](L4-martelos-termicos.md),
   [L5](L5-a-prensa.md). Cada uma acrescenta o seu slot ao catálogo.

## Os cinco

| ficha | minigame | gênero | verbo | a vibração diz | modelo | estimativa |
| --- | --- | --- | --- | --- | --- | --- |
| [L1](L1-o-cerco.md) | O Cerco (`S04_J16`) | sobrevivência | "Defenda!" | **de que lado** vem o golpe, um tempo antes | Sonnet | US$ 2,0 |
| [L2](L2-fuga-do-tita.md) | Fuga do Titã (`S04_J17`) | coop | "Corra!" | **de quem é a vez** de alimentar a caldeira, e quão perto o titã está | Sonnet | US$ 1,5 |
| [L3](L3-curto-circuito.md) | Curto-Circuito (`S04_J18`) | sabotagem | "Passe!" | **quanto falta** para a bomba na sua mão estourar (o coração acelera) | Sonnet | US$ 1,5 |
| [L4](L4-martelos-termicos.md) | Martelos Térmicos (`S04_J19`) | TcT | "Acerte o lado!" | **qual das duas toupeiras é a quente** (as duas parecem iguais) | Sonnet | US$ 1,5 |
| [L5](L5-a-prensa.md) | A Prensa (`S04_J20`) | sobrevivência / terror | "Esquive!" | **que a prensa vai descer em você**, e depois para que lado fugir | Sonnet | US$ 1,5 |

Cinco verbos com a mesma feature: defender, revezar, passar, atacar e
esquivar. A régua de cada um (as três perguntas de
[10](../10-a-regua-astro-bot.md#a-pergunta-de-aprovação)) está no cabeçalho
do script dele.

## O que o registro mede

A validação da vibração, por baixo, sem perguntar nada ao jogador:

- **O que foi mandado:** cada `sensacao` (nome, escala, ms, F05) e a `saida`
  de vibração correspondente (motor forte, motor fraco, duração, `seq`,
  `ok` = o SDL aceitou, F06). Isso o `Forja` grava sozinho.
- **O que o minigame acrescenta** (os tipos do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08),
  com `slot`): a cada pista mandada, a linha `pista`
  `{"n": <nota>, "evento": "mandou", "via": "rumble", "o_que": "esq" | "dir" | "ambos", "ok": <o sentir aceitou>}`;
  a cada resposta, o `toque` do kit (julgamento e desvio) e, quando o lado
  importa, a linha `entrada` `{"o": "resposta", "n": <nota>, "lado_pedido": ..., "lado_feito": ...}`;
  a cada aperto sem pista, a `entrada` `{"o": "fantasma", "golpe_de": <lugar que recebeu a pista mais perto>}`.
  O que o minigame fez no mundo (a luz do fantasma, o estouro) é a linha `jogo`.
- **O cruzamento da noite** ([08](../08-a-noite-de-6-horas.md)): pista com
  `ok` e resposta do lado certo no tempo é a vibração que chegou; pista com
  `ok` e resposta errada ou nenhuma, repetida num controle só, é o motor que
  não chegou; aperto no tempo da pista do vizinho é vibração que vazou para
  o controle errado — a prova do isolamento esquerda e direita.

## O que fica fora destas fichas

- **O sorteio entre os cinco** é da H08 (`Catalogo.sortear`): cada ficha só
  põe o seu slot no catálogo. Os quatro novos também se jogam por
  `--sala=S04_J17` (etc.).
- **A faixa gerada.** Enquanto `MUS_S04_J1x` não existe (H05), o slot toca a
  trilha sintetizada do Impacto (112 bpm). Tudo nas fichas está em batidas;
  nada supõe o bpm da tabela de [04](../04-ritmo-e-audio.md#as-45-faixas).

## Pronto quando

As cinco fichas estão **feito** no [quadro](README.md), com o commit de
cada uma, e o André jogou as cinco com gente.
