# WF02 — A luz do controle obedece aos Flashes

**Sprint:** W · **Tamanho:** P · **Depende de:** [G15](G15-a-luz-o-pos-e-o-brilho-com-dono.md) (em voo: mexe na
`impacto.gd` e na `prova.gd`; esta ficha vai depois da costura dela)

## Por quê

A opção «Flashes» desligada promete que nada pisca. A tela obedece (a G15 e a G16 cuidam dela), mas a luz do
controle não: na Impacto, o golpe põe a barra em vermelho puro e alterna com o escuro, dois clarões em uns 0,34 s; na
Prova, o tiro recebido acende vermelho puro por 0,16 s, e quem está com uma vida pulsa a luz duas vezes por segundo.
Nenhum dos dois lê a opção. A bíblia conta a luz do controle no limite de três piscadas por segundo e manda que, sem
flashes, a cor do lugar fique parada. Quem desligou os flashes por sensibilidade à luz recebe o pisca na mão, a um
palmo do rosto.

## Ler antes

- [10 — Acessibilidade, «O piscar»](../arte/10-acessibilidade.md) (as linhas 98-118)
- [G15](G15-a-luz-o-pos-e-o-brilho-com-dono.md) (o que ela já muda nesses arquivos)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `godot/scripts/salas/impacto.gd:368-379`, o pisca do golpe (o `e.pisca = 0.34` sai de `:267`):
  ```gdscript
  var vermelho: bool = e.pisca > 0.22 or (e.pisca > 0.0 and e.pisca < 0.12)
  if e.pisca <= 0.0:
  	_luz_da_vida(l)
  elif vermelho != e.vermelho:
  	_luz(l, Color(1, 0, 0) if vermelho else Color(0.16, 0, 0))
  ```
- `godot/scripts/salas/prova.gd:241-265`, a luz do lugar: o vermelho do golpe (`e.luz_pisca`, posto a 0,16 em
  `:347`) e o pulso de quem está por um fio:
  ```gdscript
  elif int(e.vida) <= 1:
  	var fase_p := int(float(e.pulso_t) * 4.0) % 2
  	estado = 20 + fase_p
  	k = 0.6 if fase_p == 1 else 0.35
  ```
- Quem já lê a opção: `godot/scripts/salas/voz.gd:304` e `godot/scripts/salas/sala_jogo.gd:200`. A opção mora em
  `godot/scripts/opcoes.gd:42`.
- O precedente nas fichas prontas: a [L2](L2-fuga-do-tita.md) (linha 440) pulsa a luz 2,4 vezes por segundo e, sem
  flashes, a deixa parada em 0,7.

## O alvo

Com «Flashes» desligado, a luz do controle não alterna: o golpe da Impacto e o da Prova acendem um vermelho escuro
fixo pelo mesmo tempo do pisca de hoje e voltam à cor da vida; o pulso de quem está por um fio fica parado no meio
(0,5). Com a opção ligada, nada muda. Nenhum texto muda.

## Arquivos que mudam

- `godot/scripts/salas/impacto.gd`, `godot/scripts/salas/prova.gd`
- `godot/testes/prova_do_jogo.gd` (a contagem)

## Passos

1. Na `impacto.gd`, no `jogar`: sem `Opcoes.flashes`, o pisca escreve uma vez o vermelho escuro (`Color(0.5, 0, 0)`)
   no começo do golpe e a cor da vida no fim, sem a alternância.
2. Na `prova.gd`, no `_atualizar_luz`: sem `Opcoes.flashes`, o golpe usa o mesmo vermelho escuro, e o pulso fica em
   `k = 0.5`, um estado só.
3. A prova: com `Opcoes.flashes = false`, contar as trocas de cor da luz do controle simulado
   (`Forja.estado_saida(l).luz`) durante um golpe da Impacto e no pulso da Prova.

## Armadilhas

- **O texto da Impacto** diz «a luz do controle pisca vermelho no golpe» (`impacto.gd:63`). Esta ficha não muda o
  texto: com flashes, ele segue verdadeiro.
- **A regra «nada pisca em vermelho saturado»** da bíblia vale também com flashes ligados, e o golpe da Impacto pisca
  vermelho puro. Isso é **decisão aberta, a validar por ela**: mudar a cor do golpe com flashes ligados muda o jogo e
  o texto. Esta ficha só cuida da opção desligada.
- **A G15 está em voo nesses arquivos:** começar da integração depois da costura dela.

## Não fazer

- Não mexer na háptica do golpe: o golpe se sente na mão como hoje.
- Não mudar a cor do lugar nem a da vida.

## Pronto quando

Na prova do jogo, com `Opcoes.flashes = false`, a luz do controle troca de cor no máximo uma vez durante o golpe da
Impacto e não alterna no pulso da Prova (hoje, três trocas no golpe e duas por segundo no pulso). Com a opção ligada,
a contagem é a de hoje.

## Provas

- `bash tests/prova_do_jogo.sh`, pela caixa e pelo semáforo da máquina.

## Para o André (local)

Com um DualSense, desligar «Flashes» nas Opções, jogar a Impacto e a Prova e olhar a barra de luz: ela muda de cor no
golpe e não pisca.

## Ao terminar

Pôr a linha da WF02 no [quadro](README.md) como **feito**, com o commit, e levar a decisão do vermelho saturado para
o ESPERA-ELA.
