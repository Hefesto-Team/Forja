# N — S6 — O Canto: os cinco minigames

**Sprint:** N · **Tamanho:** G (a seção, em cinco fichas) · **Estimativa:** US$ 8,0 (a soma das cinco) · **Depende de:** H04, H08, F09, H07

Esta ficha é o índice da seção. O trabalho está nas cinco fichas abaixo,
uma por sessão, e cada uma se basta.

## A feature protagonista

**O alto-falante de cada controle**, que canta diferente em cada mão.
Sempre sons curtos e pessoais, nunca música nem ambiente contínuo, nunca
dois ao mesmo tempo no mesmo controle
([05](../05-haptica-e-controle.md#a-agenda-do-alto-falante), lição 17 de
[10](../10-a-regua-astro-bot.md)). A seção usa os sons que o módulo já tem
(`nativo/som/sons_salas.c` e os da H07), todos de 20 a 500 ms:

| som (`Forja.som_falante`) | o que é | na seção |
| --- | --- | --- |
| `"nota"` | bigorna 784 Hz | a nota grave da frase (✕), o eco da esquerda, o meio da senha (○) |
| `"nota_alta"` | bigorna 1175 Hz | a nota aguda (○), o eco da direita, o agudo da senha (△), o bipe falso |
| `"nota:<lugar>"` | a nota do lugar: dó, ré, fá, sol (H07) | a voz de cada um no coral; o grave da senha (✕, `"nota:0"`) |
| `"pronto"` | bigorna 1568 Hz, 0,5 s | o bipe do fio certo |
| `"clique"` | um estalo de 20 ms | o bipe do fio errado |
| `"coleta"` | o tilintar (H07) | a coleta |

A regra que vale para os cinco: **a pista está só no alto-falante.** A tela
mostra **quando** (o sino do jogador balança na vez dele), nunca **o quê**
(a altura, o lado, o fio). A barra de luz pulsa com a nota **da resposta**,
nunca com a da chamada — senão a luz entregaria o que o ouvido tem de achar.

Os coadjuvantes: a vibração no tempo forte (`Forja.sentir(l, "toque")` no
começo de cada compasso, em todos), a barra de luz que pulsa com a própria
nota (60% por 0,12 s e volta à cor do lugar), a háptica suave do material
no acerto (o kit, no cabo) e o gatilho solto (nada a segurar).

**A saída silenciosa** ([10](../10-a-regua-astro-bot.md), lição 16): se o
controle não tem alto-falante achado (`Forja.som_tem(l, Forja.PAPEL_ALTO_FALANTE)`
falso), a chamada dele toca na TV, baixa, na raia dele, e o registro anota
— o jogo segue, mais difícil (todo mundo ouve).

## O cenário comum

A capela d'O Canto de hoje, em `godot/scripts/minigames/s06/cenario_do_canto.gd`
(`class_name CenarioDoCanto`, estático). A [N1](N1-o-canto.md) o cria
(movendo para ele o que hoje está em `godot/scripts/salas/canto.gd`); as
outras quatro o usam:

| função / constante | o que é |
| --- | --- |
| `montar(sala, escuro := 1.0) -> Dictionary` | `Kit.arena(sala, 5, 3)`; `sala.atmosfera(Color("#b88cff"), Tema.ROXO, false, 36, 22, −7,8, 0,2 × escuro)`; o enchimento `#8a80c8` (0,55 × escuro) em (0, 8, 4); duas tochas `#ffb070` em (±9,5, 2,6, −4,5) (1,1 × escuro); o pórtico de madeira e o **sino grande** em `SINO_TV`. Devolve o sino grande. `escuro` 0,4 é o terror do Eco do Abismo |
| `sino(pai, pos, escala, cor) -> Dictionary` | o sino de hoje (`canto.gd:105-152`) com **8 lados** (não 28), `metallic` 0,15 (não 0,75) e o badalo em caixa: `{pivo, mat, badalo}` |
| `balancar(s, forca)` | o sino balança pela batida: `s.pivo.rotation.z = sin(TAU * Ritmo.batida()) * 0.3 * forca` |
| `tempo_forte()` | o sino grande no começo de cada compasso, na TV, baixo (`Som.tocar("sino", SINO_TV, -16.0)`): o compasso se ouve mesmo sem faixa |
| `falante(sala, l, som, ganho := 0.9) -> bool` | o som no alto-falante do lugar; sem alto-falante, na TV na raia dele (`NA_TV`), a −10 dB. Devolve se foi no controle |
| `luz_da_nota(l, forca)` | a barra de luz na cor do lugar com o brilho `forca` (0,6 no pulso; nunca abaixo de 0,3) |

A câmera é `"fixa"` em (0, 5,6, 11,2) olhando para (0, 1,6, −1,0), a d'O
Canto de hoje, salvo onde a ficha diz outra; as raias em x = −6, −2, 2, 6, o
boneco em `Z_JOGADOR`, de frente para a câmera, `preso = true`, com o sino
pequeno dele ao lado (`Vector3(RAIAS[l] + 0.6, 1.8, Z_JOGADOR - 0.35)`,
escala 0,34, num suporte de madeira).

**O compasso sem faixa.** A trilha sintetizada d'O Canto é silêncio
(`Musica.FAIXAS["canto"]` é vazio): até a H05 trazer `MUS_S06_J2x`, o
`Ritmo` anda pelo relógio do sistema a 120 bpm, e o `tempo_forte()` é o
que dá o compasso na sala. Com a faixa, ele continua, baixo, como sino da capela.

**O robô da seção** ouve o alto-falante do controle simulado dele
(`Forja.som_virtual(l)["falante"]`, o nível de 0 a 1) e acha o ataque de
cada nota pela lógica de hoje (`canto.gd:565-573`: o nível subindo mais de
0,10 acima do vale deixado pela anterior), com o "desde" medido em tempo de
música. No ataque, o `Forja.som_virtual(l)` dá também o nome do último som
(H08): o robô **só responde o que ouviu chegar** (se o som não chegou, ele
não responde — a prova do caminho), e responde a altura, o lado ou o bipe
**que ouviu**, nunca o da partitura.

## A ordem

1. [N1](N1-o-canto.md) primeiro: muda a sala para o kit e cria o cenário comum.
2. Depois, em qualquer ordem (a sugerida): [N2](N2-eco-do-abismo.md),
   [N3](N3-coral-dos-quatro.md), [N4](N4-codigo-do-dragao.md),
   [N5](N5-corta-fio.md).

## Os cinco

| ficha | minigame | gênero | verbo | o alto-falante diz | estimativa |
| --- | --- | --- | --- | --- | --- |
| [N1](N1-o-canto.md) | O Canto (`S06_J26`) | TcT | "Repita!" | **a frase** (grave e aguda) que você repete no compasso seguinte | US$ 2,0 |
| [N2](N2-eco-do-abismo.md) | Eco do Abismo (`S06_J27`) | corrida / terror | "Responda o eco!" | **o lado** do degrau firme, uma batida antes | US$ 1,5 |
| [N3](N3-coral-dos-quatro.md) | Coral dos Quatro (`S06_J28`) | coop | "Cante a sua!" | **quando** é a sua vez no acorde (a ordem se embaralha) | US$ 1,5 |
| [N4](N4-codigo-do-dragao.md) | Código do Dragão (`S06_J29`) | TcT | "Decore!" | **a senha** secreta, de três a doze notas | US$ 1,5 |
| [N5](N5-corta-fio.md) | Corta-Fio (`S06_J30`) | sabotagem | "Corte!" | **qual bipe** é o do fio certo (e o falso que um rival mandou) | US$ 1,5 |

Cinco verbos com a mesma feature: repetir, seguir, achar a sua vez,
decorar e desconfiar.

## O que o registro mede

- **O que foi mandado:** cada `som_controle` (H07): `seq`, `papel`
  (`alto_falante`), `som`, `ganho`, `placa` — gravado pelo módulo.
- **O que o minigame acrescenta** (os tipos do [13](../13-arquitetura.md#as-decisões-comuns-dos-minigames--h08),
  com `slot`): a cada som que é pista, a linha `pista`
  `{"n": <a nota da resposta que depende dele>, "evento": "mandou", "canal": "alto_falante" | "tv", "o_que": <o som>, "no_controle": <foi ao alto-falante ou à TV>}`;
  a resposta é o `toque` do kit com o mesmo `n`, e o que o jogador fez além
  dele (a pisada, a sabotagem) é a linha `entrada`. O que o minigame fez no
  mundo (o acorde, a armadilha) é a linha `jogo`.
- **O cruzamento da noite:** chamada com `placa` e resposta certa é o som
  que chegou à mão certa; chamada com `placa` e resposta errada ou nenhuma,
  repetida num controle só, é o alto-falante que não tocou (ou tocou em
  outro controle). Chamada na TV (`no_controle` falso) sai da conta.
- **O Modo bancada** (só na N1) mede ainda o veredito `alto_falante` de hoje
  com a pergunta "o canto saiu do seu controle?".


## O que fica fora destas fichas

- **O sorteio entre os cinco** é da H08 (`Catalogo.sortear`), e
  `Partida.NA_ORDEM` inclui o Canto: cada ficha só põe o seu slot no
  catálogo. Os novos também se jogam por `--sala=S06_J27` (etc.).
- **As faixas:** `MUS_S06_J2x` (H05). Tudo está em batidas.

## Pronto quando

As cinco fichas estão **feito** no [quadro](README.md), com o commit de
cada uma, e o André jogou as cinco com gente, com os quatro controles — dois
no cabo e dois no rádio (no rádio, o alto-falante depende da ponte; o que
não chegar aparece no registro).
