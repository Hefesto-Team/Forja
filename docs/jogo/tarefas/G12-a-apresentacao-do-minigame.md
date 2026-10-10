# G12 — A apresentação do minigame

**Sprint:** G · **Tamanho:** M · **Depende de:** H01 (o relógio da música), H04 (o kit, `Catalogo.SECOES`), H06
(o `JIN_ENTRADA`), F05 (`Forja.sentir`), F07 (a voz), F09 (a prova visual), G11 (`Desenho.jcard`, `dica`, `chip`),
G14 (`Tema.tinta_da_secao`, as fontes), G15 (`PosFita.rasgo_curto`)

## Por quê

Entre um minigame e outro, quem joga precisa saber em três segundos o nome do jogo e o que fazer com as mãos: o verbo
gigante que entra com estrondo (WarioWare) e o cartão de instruções com o «pronto» de cada um (Mario Party). Pedido
dela em 08/10/2026. Na Forja, a entrada é a cortina diagonal da fita e o cartão é o J-card do
[06](../arte/06-interface-e-texto.md#o-j-card).

## Ler antes

- [06, a cortina diagonal](../arte/06-interface-e-texto.md#a-cortina-diagonal) (a forma, o tempo, o rasgo)
- [06, o J-card](../arte/06-interface-e-texto.md#o-j-card) (as partes e as medidas)
- [O kit do minigame, no 13](../13-arquitetura.md#o-kit-do-minigame--h04) (a `FICHA`, `CHAVES`, o aviso no kit)

## O estado de hoje

- O aviso mora em `godot/scripts/salas/sala_jogo.gd`: `fase := "aviso"` (linha 15), `AVISO_MAX := 8.0` (23),
  `_quadro_aviso()` (244): cada ✕ marca pronto com `Forja.vibrar(l, 0.0, 0.3, 60)` e `Som.tocar("tique")`; começa
  com todos prontos ou em `AVISO_MAX`, nunca antes de 0,9 s. `comecar()` (300) toca `"confirma"`. O boneco de quem
  não está pronto repete `gesto_do_aviso` a cada 1,6 s.
- O desenho é `_aviso()` em `godot/scripts/ui/painel_sala.gd:32`: um véu `Tema.CASA` a 25 % e um quadro de 1120 px
  com título, verbo e ícone. Aparece de uma vez, sem transição, e não diz como se joga.
- O treino (`com_treino`, `TREINO_ACERTOS` 3) roda depois de `comecar()`, já na fase `jogo`, com `treinando`.
- O kit da H04 (`godot/scripts/minigames/minigame.gd`) lê a `FICHA` por `CHAVES` (linha 104 da ficha H04): `slot`,
  `titulo`, `verbo`, `genero`, `icone`, `gesto`, `treino`…
- A F03, a H04 e a G11 mexem neste trecho antes desta ficha: meça de novo na hora de começar.

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd`: a fase `entrada` antes do `aviso`; o J-card no lugar do aviso de hoje. **De
  todos:** G15 (a luz da sala), G16 (o tremor e o virar)
- `godot/scripts/ui/painel_sala.gd`: `_entrada()` e `_jcard()` no lugar de `_aviso()`
- `godot/scripts/minigames/minigame.gd` e `godot/scripts/minigames/catalogo.gd`: a chave `como_jogar`
- `godot/scripts/partida.gd`: `lado() -> String`. **De todos:** G16 (usa)
- `godot/scripts/som.gd`: o encanamento do mapa (se ainda não entrou). **De todos:** G09, G11, G16
- `docs/jogo/audio/mapa.csv`: `fx_entrada`, `jin_entrada_tique`, `jin_entrada_vai`. **De todos:** G09, G11, G16
- `godot/assets/sons/fx_entrada.wav`, `jin_entrada_tique.wav`, `jin_entrada_vai.wav` (cópias)
- `godot/scripts/traducoes.gd`: os gêneros, «Como jogar», «Treino · não vale ponto», «Começa em %d», «Pronto»,
  «Treinando». **De todos:** G09, G11, G16
- `docs/jogo/tarefas/molde-de-minigame.md`: a chave `como_jogar` na tabela
- `docs/jogo/06-telas-e-fluxo.md`: a linha «aviso do minigame»
- `godot/testes/prova_do_jogo.gd` e a prova da H04 (`fase == "aviso"` vira `fase in ["entrada", "aviso"]`). **De todos**
- `godot/testes/prancha_da_entrada.gd` (novo) e `docs/imagens/jogo/entrada.jpg`

## Como se joga

1. **A entrada** (fase `entrada`, nenhum botão pula): a sala já está na tela; a cortina cobre a esquerda, o verbo
   carimba no tempo 1 e a cortina sai. Dura 900 ms mais a espera do tempo 1 seguinte, no máximo 1 compasso.
2. **O J-card** (fase `aviso`, como hoje): ✕ marca pronto; começa com todos prontos ou em `AVISO_MAX` (8 s). Os 0,9 s
   mínimos de hoje passam a contar do J-card parado.
3. **O treino** (como hoje): o J-card fica, com a linha do treino, até cada um somar `TREINO_ACERTOS`; então sai, e o
   apito cai no tempo 1 seguinte. Sem treino, sai em `comecar()`.

A `FICHA` ganha **`como_jogar`**: uma lista de 1 a 3 pares `[glifo, frase]`, com o glifo de
`godot/assets/glifos/` e a frase no infinitivo, do mundo («Martelar», «Inclinar para equilibrar», «Soprar o fole»),
até 28 caracteres. Minigame sem a chave, com 0 ou mais de 3 itens, com glifo que não existe ou frase acima de 28
reprova em `Minigame.validar` (o `push_error` da H04). O minigame de prova e o `S01_J01` a preenchem aqui; os 45 a
preenchem nas fichas I a Q.

## A cena

**A entrada** (a cortina do [06](../arte/06-interface-e-texto.md#a-cortina-diagonal); prancha
`docs/imagens/direcao/18_cortina.jpg`), num `Control` de tela cheia acima do HUD:

- **O tempo:** `T` é o próximo tempo 1 de compasso do relógio da música (H01, `Ritmo.t_da_batida`) que esteja a pelo
  menos 1,6 s de `entrar()`; sem música no relógio, `T` = `entrar()` + 1,6 s. A cortina começa em `T − 0,6 s`.
- **A seção da sala:** `n = int(FICHA.slot.substr(1, 2))` («S01_J01» dá 1). O minigame de prova (`T00_J00`) dá
  n = 0: tinta `Tema.tinta_da_secao(0)`, lombada «T0 · …» e sem a linha da seção no J-card.
- **As curvas** (as do [05](../arte/05-movimento.md#as-curvas)): `ENTRA` = `Tween.TRANS_CUBIC`, `EASE_IN`; `SAI` =
  `TRANS_CUBIC`, `EASE_OUT`; `MOLA` = `TRANS_BACK`, `EASE_OUT`.
- **A forma:** o polígono (0, 0), (1240, 0), (930, 1080), (0, 1080), chapado na `Tema.tinta_da_secao(n)` da seção da
  sala; a trama: uma linha de 2 px a cada 6 px, na tinta a ×0,88 de luz; a borda: uma tira `FITA` de 26 px e, 22 px
  depois, o fio `ETIQUETA` de 4 px.
- **0 a 600 ms:** a borda varre de x −330 a 1240, `ENTRA`; `PosFita.ajustar("rasgo", …)` de 0 a 0,35.
- **600 ms (= `T`):** o verbo carimba, em Bungee, centrado em (905, 560), girado −0,045 rad (−2,6°); escala de 1,35 a
  1,0 em 80 ms, `MOLA`; a tela treme 8 px por 4 quadros (com Movimento Inteiro, `not Opcoes.reduzido()` da G16; no Reduzido, nenhum); `PosFita.rasgo_curto()`.
- **600 a 900 ms:** o verbo segura com dois ecos atrás (escala 1,07 e 1,14; opacidade 0,16 e 0,08).
- **Depois de 900 ms:** no tempo 1 seguinte, a cortina sai pela direita em 1 batida, `ENTRA`, e o J-card entra.
- **O tamanho do verbo:** Bungee 252 se a largura couber em 1100 px; senão, o maior tamanho inteiro de 252 para baixo
  que caiba, até 160. Nem a 160 cabe: reprova em `Minigame.validar` («verbo longo demais»).
- **As letras sobre a tinta:** o verbo em `ETIQUETA` com a chapa em `FITA` deslocada round(0,08 × tamanho) px para
  baixo e para a direita (20 px a 252); a linha «LADO A · FAIXA 01 · 120 BPM» em VT323 56 em (110, 120); o título
  em Permanent Marker 72 em (104, 186). As duas linhas pequenas vão em `ETIQUETA` sobre vermelhão, cobalto e ameixa,
  e em `TINTA` sobre mostarda e petróleo (os pares do [02](../arte/02-cor-e-letra.md#os-pares-de-contraste-permitidos),
  todos a 48 px ou mais).

**O J-card** (as medidas do [06](../arte/06-interface-e-texto.md#o-j-card)): `Desenho.jcard` de 1064×830 em (760, 90),
entra da direita (x de +1100 a 0) em 1 batida, `SAI`; inclinação parada de 0,5°. Dentro, de cima para baixo:

| parte | o que tem |
| --- | --- |
| a lombada | «S1 · O MARTELO DE HEFESTO · LADO A» («S» + `str(int(Catalogo.SECOES[n - 1].id.substr(1)))`, o título em caixa alta, `partida.lado()`) |
| a seção | o `nome` de `Catalogo.SECOES[n - 1]` em caixa alta, VT323 40, `TINTA_SUAVE` |
| o título | Permanent Marker 74, `TINTA`; acima de 22 caracteres, 60 px |
| o gênero | caixa de 330×54 com borda de 3 px na tinta da seção; a frase em Archivo Narrow 700 34, `TINTA`: tct «Todos contra todos», 2v2 «Dupla contra dupla», coop «Todos juntos», corrida «Corrida», sobrevivencia «Sobrevivência», terror «Terror», sabotagem «Sabotagem» |
| a faixa | «LADO A» em VT323 40 e o número (`partida.passo + 1`, dois dígitos) em VT323 64 |
| como jogar | o rótulo «Como jogar» em VT323 40; cada par em uma linha: o glifo de 64 px em `TINTA` e a frase em Archivo Narrow 600 44; linha `ETIQUETA_SOMBRA` de 2 px entre elas |
| o treino | com treino: «Treino · não vale ponto» em VT323 40; sempre: «Começa em N» em Archivo Narrow 600 34, N = ceil(`AVISO_MAX` − `t_fase`) |
| os chips | `Desenho.chip` 2×2, 400×64, vão de 16, um por lugar ocupado: pronto ou treinando |

- A arena fica à mostra à esquerda: sem véu. O boneco de quem não está pronto repete o `gesto` (como hoje).
- **Sai** para a direita em 1 colcheia, `ENTRA`, quando o treino acaba (ou em `comecar()`, sem treino).

`partida.lado()`: «A» enquanto `passo < ceil(salas.size() / 2.0)`, «B» depois. Fora de uma partida (sala avulsa),
«A» e faixa 01.

## O som

O encanamento, igual nas fichas G09, G11, G12 e G16: copiar cada `<id>.wav` usado de `godot/estudos/direcao/som/`
para `godot/assets/sons/<id>.wav`; `Som.tocar(nome, ...)` e `Som.no_controle(lugar, nome, ...)` tocam primeiro
`res://assets/sons/<nome>.wav` quando ele existe, sem o tom sorteado de ±5 % dos gravados; a linha do mapa ganha
`arquivo` = `godot/assets/sons/<id>.wav` e `estado` = `no jogo`. Se outra ficha já fez a mudança em `som.gd`, use-a
sem mudar. A V05 depois troca as tabelas do `Som` pelo mapa.

| evento | id do [mapa](../audio/mapa.csv) | quando | onde |
| --- | --- | --- | --- |
| a contagem | `jin_entrada_tique` (120 ms) | `T` − 3, − 2 e − 1 batida (os tempos 2, 3 e 4 do compasso antes) | TV a −9 dB |
| a cortina | `fx_entrada` (900 ms; o impacto cravado em 600 ± 5 ms) | `T` − 0,6 s | TV a −6 dB |
| o vai | `jin_entrada_vai` (400 ms) | `T`, junto do impacto | TV a −6 dB e `Som.no_controle` de cada lugar ocupado |
| ✕ pronto | `ui_confirma` | no quadro do botão | `Som.ui(l, "ui_confirma")` (G11) |
| o começo | o apito de hoje (`"confirma"` em `comecar()`) passa a `ui_confirma` | no tempo 1 depois do J-card sair | TV a −12 dB |

A faixa do minigame começa em `T` (o vai é o tempo 1 dela); até `T`, segue a música da tela anterior.

## O controle

| evento | vibração | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- |
| a contagem | `Forja.sentir(l, "toque")` em todos, em cada tique | `Forja.gatilhos_off(l)` em todos, em `T` − 3 batidas | não muda | nada | não se usa |
| o impacto, em `T` | `Forja.sentir(l, "golpe")` (1,0 / 0,6 / 250 ms) em todos | Off | a lightbar pisca `ETIQUETA` por 2 quadros e volta à cor do lugar (com Flashes ligado) | `jin_entrada_vai` | não se usa |
| ✕ pronto | `Forja.sentir(l, "toque")` só nele (no lugar do `Forja.vibrar` de hoje) | Off | não muda | `ui_confirma` | não se usa |
| o J-card sai | nada | a sala aplica o gatilho dela em `comecar()` (como hoje) | não muda | nada | não se usa |

Prova sem o controle na mão: o robô aperta pelo controle simulado; a prova conta no registro, por lugar, 3 linhas
`{"tipo": "sensacao", "nome": "toque"}` e 1 `"golpe"` na entrada, mais 1 `"toque"` no pronto. No quadro do impacto,
com `Opcoes.flashes` ligado, `Forja.estado_saida(l).luz` é `Tema.ETIQUETA` em cada lugar ocupado.

## O cavaleiro

O boneco de quem não está pronto repete o `gesto` da `FICHA` a cada 1,6 s (como hoje), à esquerda do J-card. Nenhum
stat muda a apresentação.

## As reações

Não se aplica: a entrada e o J-card não disparam reação; as do [09](../arte/09-reacoes.md#quando-o-jogador-manda) seguem
valendo durante o J-card, pela ficha das reações.

## A diversão

- **O `nome` do momento:** `verbo_carimbado`. No impacto, o jogo escreve
  `{"tipo": "momento", "slot": <o slot>, "nome": "verbo_carimbado", "lugar": -1, "t_musica": ...}`.
- **A janela:** do começo da cortina ao impacto, 0,6 s; a entrada inteira, até 0,9 s mais 1 compasso (2,9 s a 120);
  o grupo grita o verbo junto do impacto. O robô confere que `t_musica` do momento cai a até 20 ms de um tempo 1.
- **A mesa:** a padrão (P1 `bom`, P2 e P3 `medio`, P4 `ruim`), semente 7.
- **O rastro na prancha:** a prancha da noite (480×270 a cada 2 s, 6 colunas) mostra, em cada sala, pelo menos um
  quadro com o J-card; a prancha da entrada guarda o impacto.

## Pronto quando

Todo minigame do kit entra pela cortina na tinta da seção, carimba o verbo no tempo 1 e mostra o J-card com o título,
o gênero, o Como jogar da `FICHA`, o treino e os chips; minigame sem `como_jogar` ou com verbo que não cabe a 160
reprova; e a prova visual passa em todas as escalas e línguas, de 1 a 4 jogadores.

## Provas

- `bash tests/prova_do_jogo.sh`, com estas checagens novas em `godot/testes/prova_do_jogo.gd`:

  As checagens entram em `_prova_do_kit()` (o código está na [H04](H04-o-kit-do-minigame.md#provas)), logo depois de
  `jogo._entrar_na_sala(mg.id, false, mg)` e dos 2 quadros: `mg` é o minigame de prova (`T00_J00`) aberto. O
  momento se espera pelo relógio de parede, até 5 s, como a fase `jogo`. O `_esperar(... mg.fase == "aviso" ...)`
  de hoje passa a esperar o fim da entrada.

  ```gdscript
  _esperar(mg.fase == "entrada", "entrada: a sala abre pela cortina")
  # o impacto no tempo 1
  var m := _ultimo_registro("momento", "verbo_carimbado")
  var n: float = (float(m.get("t_musica", 0.0)) - Ritmo.primeiro_tempo) * Ritmo.bpm / 60.0
  _esperar(not m.is_empty() and absf(n - 4.0 * roundf(n / 4.0)) * 60.0 / Ritmo.bpm < 0.020, "entrada: o verbo no tempo 1")
  _esperar(_contar_registro("sensacao", 0, "golpe") == 1, "entrada: um golpe por lugar")
  # o tamanho do verbo
  _esperar(PainelSala.tamanho_do_verbo("Martele!") == 252, "entrada: verbo curto a 252")
  _esperar(PainelSala.tamanho_do_verbo("Inclinem juntos!") in range(160, 252), "entrada: verbo longo encolhe")
  # a chave nova
  var f := mg.FICHA.duplicate(); f.erase("como_jogar")
  _esperar(not Minigame.validar(f), "kit: sem como_jogar reprova")
  var partida_de_teste := Partida.nova(3, false, 7, [])
  _esperar(partida_de_teste.lado() == "A", "partida: o lado A no começo")
  partida_de_teste.passo = 2
  _esperar(partida_de_teste.lado() == "B", "partida: o lado B na segunda metade")
  ```

  Os dois leitores do registro, sobre `_linha_do_tempo()` (`prova_do_jogo.gd:884`). Quem chega primeiro, G11 ou
  G12, os escreve; a outra usa:

  ```gdscript
  func _contar_registro(tipo: String, lugar: int, nome: String) -> int:
  	var n := 0
  	for e in _linha_do_tempo():
  		if e.get("tipo", "") == tipo and e.get("nome", "") == nome and int(e.get("jogador", 0)) == lugar + 1:
  			n += 1
  	return n

  func _ultimo_registro(tipo: String, nome: String) -> Dictionary:
  	var ultimo := {}
  	for e in _linha_do_tempo():
  		if e.get("tipo", "") == tipo and e.get("nome", "") == nome:
  			ultimo = e
  	return ultimo
  ```
- `godot/testes/prancha_da_entrada.gd` (xvfb, `--audio-driver Dummy`): grava `docs/imagens/jogo/entrada.jpg`,
  1920×1620, seis quadros de 960×540 com os instantes 0, 300, 600, 680 e 900 ms e o J-card parado, com o instante
  escrito embaixo em VT323 30, como o `18_cortina.jpg`. O jogador do time a põe ao lado do `18_cortina.jpg`.
- `bash tests/prova_visual.sh`: o J-card sem colisão de texto em 1,0× e 1,15×, em pt-BR e en, com 1, 2, 3 e 4
  jogadores.
- `python3 scripts/check_texto_de_tela.py`: as frases novas passam.

## Passos

1. Medir o aviso de hoje: o que se desenha, em que fase, quanto dura.
2. A chave `como_jogar` no molde, no `minigame.gd` (validar) e no catálogo; preencher a do minigame de prova
   (`[["cross", "Bater no tempo"]]`) e a do `S01_J01`.
3. `partida.lado()`.
4. A fase `entrada` em `sala_jogo.gd` e o `_entrada()` em `painel_sala.gd`, com os sons e o controle.
5. O J-card em `_jcard()`, os chips e o treino; `_aviso()` sai.
6. As traduções, pela voz da F07; a prancha da entrada; as provas.

## Armadilhas

- **A prova da H04** espera `fase == "aviso"` logo depois de abrir: passa a esperar `entrada` ou `aviso`.
- **O `fx_entrada` tem o impacto cravado em 600 ms:** o 900 não escala com o BPM; o que espera o tempo 1 é o começo da
  cortina.
- **Vermelhão sobre a etiqueta** só passa a 48 px: o gênero vai em `TINTA`, a tinta fica na borda.
- **Texto de tela sem metalinguagem:** «Martelar», nunca «aperte para provar o gatilho».
- **O robô aperta ✕ a 1,4 s + 0,2 s por lugar de `t_fase`:** com a entrada antes, `t_fase` zera ao entrar no `aviso`.

## Não fazer

- Não pôr a apresentação em cada minigame: é do kit.
- Não criar botão de pular: a entrada é curta e o J-card começa sozinho.
- Não usar `fx_rebobinar` nem `fx_caneta` aqui: nenhum «repetir a faixa» existe hoje, e a troca de etiqueta é do HUD.

## Ao terminar

Marcar G12 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(kit): a cortina da fita com o verbo no tempo 1 e o J-card com o como jogar`.

## O que foi feito (leva 1, as-telas)

- **A entrada do kit:** todo minigame do kit (`com_entrada`) abre pela cortina diagonal na tinta da seção. O verbo
  carimba no tempo 1 do relógio da música (`_t_impacto`), com a contagem nos três tempos antes (`jin_entrada_tique`,
  um toque em cada controle), o impacto com `fx_entrada`, um golpe em cada controle e a lightbar dos quatro piscando
  em papel; 900 ms depois, no tempo 1 seguinte, a cortina sai e o J-card entra com o título, o gênero, o Como jogar
  da `FICHA`, o treino e os chips («Aguardando», «Treinando», «Pronto»). As salas antigas seguem com o aviso de antes.
- **O kit valida:** `Minigame.validar` reprova a `FICHA` sem `como_jogar`, com frase que não cabe no J-card, com glifo
  que não existe ou com verbo que não cabe na cortina a 160 (`PainelSala.tamanho_do_verbo`). `Partida.lado()` diz
  «A» ou «B». O ✕ do pronto toca `ui_confirma` e dá um toque.
- **O som:** `fx_entrada`, `jin_entrada_tique` e `jin_entrada_vai` em `godot/assets/sons/` (`compress/mode=0`), com
  o mapa em «no jogo».
- **Medida antes:** o aviso aparecia de uma vez, sem transição, e não dizia como se joga. **Depois:** a prova mede a
  cortina, o verbo no tempo 1 (o desvio em ms), um toque por tique e um golpe no impacto por lugar, a lightbar em
  papel, o J-card parado no aviso e o lado A e B. Achado na medida: o verbo em Bungee só fica a 252 quando é bem
  curto («Martele!» já sai a 204), e passando de uns 8 caracteres não cabe nem a 160: «Inclinem juntos!», «Soprem o
  fole!» e «Equilibrem!» reprovam. Por isso a prova usa casos reais e não os exemplos da ficha.
- **As provas:** as checagens da entrada e do kit em `prova_do_jogo.gd`; os portões passam.
  Na prova do jogo (as duas passadas, rodada junto com a G07), toda checagem desta ficha passa; o que reprova na
  rodada são as checagens do robô do kit, que reprovam igual na base de outras frentes com a máquina carregada.
- **A faixa no tempo 1 e a prancha da entrada** (a faixa que começa no impacto, o apito depois do J-card, a
  `prancha_da_entrada.gd` e a matriz da prova visual) ficaram na
  [G12b](G12b-a-faixa-no-tempo-1-e-a-prancha-da-entrada.md).
- **A mordida:** a cópia com as curas tiradas (o golpe e a luz do impacto, o toque de cada tique, a checagem do
  tamanho do verbo e a do glifo no `validar`) está montada; o semáforo das provas ficou ocupado a sessão inteira e ela
  não rodou. Falta rodar e ver reprovar «um toque por tique e um golpe no impacto», a lightbar em papel e «verbo que
  não cabe na cortina reprova».
