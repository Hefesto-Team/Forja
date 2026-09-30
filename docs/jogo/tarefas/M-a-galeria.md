# M — S5 — A Galeria: os cinco minigames

**Sprint:** M · **Tamanho:** G (a seção, em cinco fichas) · **Estimativa:** US$ 8,0 (a soma das cinco) · **Depende de:** H04, H08, F09

Esta ficha é o índice da seção. O trabalho está nas cinco fichas abaixo,
uma por sessão, e cada uma se basta.

## A feature protagonista

**O gatilho adaptativo do R2**, nos quatro modos oficiais e em nenhum outro
([CONTRATO](../../../CONTRATO.md)): `Forja.gatilho(l, 1, modo, a, b, c)`.

| modo | `Forja.` | os parâmetros (`include/forja_dualsense.h`) | na seção |
| --- | --- | --- | --- |
| Off | `GATILHO_OFF` | — | a arma vazia: o "clique seco" |
| Feedback | `GATILHO_RESISTENCIA` | `a` a posição onde a resistência começa (0–9), `b` a força (1–8) | o arco, a fita da espada, a corda da catapulta, a arma travada |
| Weapon | `GATILHO_ARMA` | `a` o começo da parede (2–7), `b` o fim, `c` a força (1–8) | a pistola, a trava da catapulta |
| Vibration | `GATILHO_VIBRACAO` | `a` a posição (0–9), `b` a amplitude (1–8), `c` a frequência em Hz (1–255) | a metralhadora de feitiços |

**Só o R2** é do minigame; o L2 é do item ([G03](G03-o-item-com-mecanica.md)).
Nenhuma ficha chama `Forja.gatilhos_off` depois do `montar`. As opções do
lugar valem por baixo (`Opcoes.ajustar_gatilho`: fraco é metade da força,
desligado é Off) — e o minigame continua jogável com o gatilho desligado:
o curso do R2 é o mesmo, só falta o peso (a saída silenciosa de
[10](../10-a-regua-astro-bot.md), lição 16).

Os coadjuvantes: vibração de recuo (o `acerto` do kit), o som do disparo no
alto-falante do dono (`Som.no_controle(l, "tiro")`), a barra de luz na cor
do lugar, que o kit pisca branco no perfeito e escurece no erro (`_reagir`,
H08; nenhuma ficha a pisca à mão). **As luzinhas de
jogador mostram sempre o número do jogador:** a munição, a bomba e a equipe
ficam no mundo (o tambor na mesa, o monte de pedras, o chão e a armadura
da equipe) e no peso do gatilho, nunca nas luzinhas nem na barra de luz. Só o Modo bancada mexe
nas luzinhas, na pergunta que mede o `leds_jogador` (M1).

## O cenário comum

O estande synthwave d'A Galeria de hoje, em `godot/scripts/minigames/s05/cenario_da_galeria.gd`
(`class_name CenarioDaGaleria`, estático). A [M1](M1-a-galeria.md) o cria
(movendo para ele o que hoje está em `godot/scripts/salas/galeria.gd`); as
outras quatro o usam:

| função / constante | o que é |
| --- | --- |
| `montar(sala)` | `Kit.arena(sala, 5, 3)`; `sala.atmosfera(Color("#c28bff"), Tema.CIANO, false, 50)`; `sala.luzes([(-9, 2,6, −5), (9, 2,6, −5), (0, 3,0, 5)])` |
| `faixa(sala, l)` | a faixa no chão na cor do lugar, do boneco até o muro dos alvos (`galeria.gd:93-94`) |
| `alvo(pai) -> Node3D` | o alvo de três discos de 8 lados (branco, vermelho, branco), de frente para o jogador |
| `arma(pai, qual) -> Node3D` e `arma_na_mao(p, qual) -> Node3D` | as armas em blocos (`galeria.gd:152-181` e `:545-559`): `PISTOLA`, `METRALHADORA`, `ARCO` |
| `no_muro(l, m: Vector2) -> Vector3` | o ponto do muro dos alvos para a mira de 0 a 1 (`galeria.gd:399-400`) |
| `rastro(sala, de, ate)` | o risco do tiro (`galeria.gd:404-421`) |
| `Z_ALVOS` −6,4, `MIRA_LARG` 2,8, `MIRA_Y0` 0,8, `MIRA_Y1` 2,7 | o muro |
| `R2_CLIQUE` 0,62, `R2_APERTA` 0,5, `R2_SOLTA` 0,2 | o curso do R2: o clique da Weapon, o apertar e o soltar |
| `EQUIPE := [Color("#e8a33c"), Color("#2fb3b3")]` | as equipes do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08): **A Brasa** (âmbar) e **A Maré** (turquesa), longe das cores dos lugares; no chão e na armadura, nunca na barra de luz. Com 3 jogadores, **o Aprendiz** completa a equipe (a regra de [Q](Q-a-prova.md#o-cenário-comum)) |

A câmera é `"fixa"` em (0, 7,5, 11,0) olhando para (0, 0,2, −2,2), a d'A
Galeria de hoje; as raias em x = −6, −2, 2, 6, o boneco em `Z_JOGADOR`
(1,4), de costas para a câmera (`rotation.y = PI`), `preso = true`.

**O robô da seção** segura o R2 chamando `Forja.robo_eixo(l, Forja.R2, v, 0.06)`
a cada quadro enquanto quer segurar, e sente o modo que chegou ao dedo pelo
primeiro byte do efeito (`Forja.percepcao(l)["gatilho_dir"]`: `0x05` Off,
`0x21` Feedback, `0x25` Weapon, `0x26` Vibration).

## A ordem

1. [M1](M1-a-galeria.md) primeiro: muda a sala para o kit e cria o cenário comum.
2. Depois, em qualquer ordem (a sugerida): [M2](M2-arco-de-neon.md),
   [M3](M3-metralhadora-de-feiticos.md), [M4](M4-espada-de-fita.md),
   [M5](M5-a-catapulta.md).

## Os cinco

| ficha | minigame | gênero | verbo | o gatilho é | estimativa |
| --- | --- | --- | --- | --- | --- |
| [M1](M1-a-galeria.md) | A Galeria (`S05_J21`) | TcT | "Atire!" | **Weapon:** o clique no ponto certo do curso, no tempo; vazio, Off | US$ 2,0 |
| [M2](M2-arco-de-neon.md) | Arco de Néon (`S05_J22`) | TcT | "Puxe e solte!" | **Feedback** que endurece durante a nota longa; soltar no fim dela | US$ 1,5 |
| [M3](M3-metralhadora-de-feiticos.md) | Metralhadora de Feitiços (`S05_J23`) | coop | "Segure a rajada!" | **Vibration** em semicolcheias no dedo; segurar só a sua batida | US$ 1,5 |
| [M4](M4-espada-de-fita.md) | Espada de Fita (`S05_J24`) | 2v2 | "Solte no pico!" | **Feedback** que pesa um degrau por batida: o peso é o relógio; soltar no pico | US$ 1,5 |
| [M5](M5-a-catapulta.md) | A Catapulta (`S05_J25`) | 2v2 | "Carregue e lance!" | **Feedback** (a corda) num e **Weapon** (a trava) no outro: a dupla passa a pedra de um dedo para o outro | US$ 1,5 |

Cinco verbos com a mesma feature: atirar, sustentar e soltar, segurar só a
sua parte, soltar no ponto do peso, e revezar a carga em dupla.

## O que o registro mede

- **O que foi mandado:** cada `saida` de gatilho (`lado`, `modo`, `params` = `[a, b, c]`,
  `seq`, `ok`), gravada pelo `Forja` (F06).
- **O que o minigame acrescenta** (os tipos do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08),
  com `slot`): a cada aperto ou soltura julgados, a linha `entrada` (o que o
  dedo fez) `{"o": "disparo", "n": <nota>, "modo": "arma" | "resistencia" | "vibracao" | "off", "curso": <o R2 no quadro em que cruzou o limiar>, "curso_max": <o maior R2 desde o aperto>}`;
  e o `toque` do kit (julgamento, desvio). O que o minigame fez no mundo (a
  arma que superaqueceu, o corte, o lançamento) é a linha `jogo`.
- **O cruzamento da noite:** o curso do disparo na Weapon mostra o clique no
  ponto certo (o disparo sai logo depois de 0,62 quando a parede existe); a
  soltura no tempo com a resistência mandada e `ok` é o peso que chegou; o
  mesmo jogador soltando sempre cedo só num controle é o Feedback que não
  chegou (sem peso, a mão não conta o tempo).
- **O Modo bancada** (só na M1) mede ainda os quatro vereditos de hoje
  (`gatilho_resistencia`, `gatilho_arma`, `gatilho_vibracao`, `leds_jogador`)
  com a identificação da arma no baú e a contagem das luzinhas.

## O que fica fora destas fichas

- **O sorteio entre os cinco** é da H08 (`Catalogo.sortear`): cada ficha só
  põe o seu slot no catálogo. Os novos também se jogam por `--sala=S05_J22`
  (etc.).
- **A faixa gerada:** enquanto `MUS_S05_J2x` não existe (H05), toca a
  trilha sintetizada d'A Galeria (104 bpm). Tudo está em batidas.

## Pronto quando

As cinco fichas estão **feito** no [quadro](README.md), com o commit de
cada uma, e o André jogou as cinco com gente — as mãos descansam entre elas
(a noite sorteada alterna gatilho pesado com minigame leve, lição 15 de
[10](../10-a-regua-astro-bot.md)).
