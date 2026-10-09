# WS01 — O som da bíblia no jogo (a H11 que as fichas citam)

**Sprint:** W (no quadro, entra como H11) · **Tamanho:** G · **Depende de:** H04, H06, H07, H08 (o
`nota_no_falante`), G01 (o pio do modelo), V05 (o id minúsculo e o `Som` pelo mapa), WS02 (a música dona do
volume), WS03 (a placa que não fecha à toa: as duas mexem em `som_controle.c`)

## Por quê

Vinte e uma linhas de treze fichas (L1 a L5, M1 a M5, N1, N2, P1) dizem «a mixagem é da H11», «o `jul_*` da H11»,
«o `fx_tropeco_*` quando a H11 trocar a falha», e a bíblia de som e o `PRODUCAO.md` entregam a ela a entrada dos 77
sons no jogo. Só que a H11 não existe: o quadro vai de H01 a H10 e não há arquivo `H11-*`. Quem pega a L1 lê que o
Ambiente desce 6 dB no minigame e não acha quem faz; os 77 sons estão prontos em `godot/estudos/direcao/som/` e nenhum
toca. E a bíblia descreve um estado que já não é o do código: diz que tudo toca no Master, mas a H07 criou o barramento
`Musica` em código.

Esta ficha é a H11: leva ao jogo o que a bíblia decidiu (os barramentos, os abaixamentos, a nota no tom da faixa, os
julgamentos, o pio, o tropeço, os jingles e a agenda da entrada, a prioridade do alto-falante) e acerta os dois textos
que contam o estado errado.

## Ler antes

- [03 — O som](../arte/03-som.md): «A voz de cada cavaleiro», «O pio», «O carimbo de cada julgamento», «Os jingles»,
  «O que toca onde», «A mixagem» e «O casamento evento por evento».
- [H07 — O som em todo evento](H07-o-som-em-todo-evento.md) (o barramento `Musica` e o `_reagir` do kit).
- [H08 — Os acréscimos do kit](H08-os-acrescimos-do-kit.md) (o `nota_no_falante` e o `textura_no_acerto`).
- [O mapa do áudio](../o-time/o-mapa-do-audio.md) e `docs/jogo/audio/mapa.csv` (os ids e o estado de cada som).
- A WS02 (a música dona do volume, por camadas e por motivo): todo abaixamento desta ficha passa por ela.

## O estado de hoje

- **Ninguém é dono.** `ls docs/jogo/tarefas | grep H11` não acha nada; `grep -rn H11 docs/jogo/tarefas docs/jogo/arte`
  acha 21 linhas nas fichas (L1:767/776/779, L2:426/428, L3:382/384, L4:451, L5:469, M1:815, M2:534, M3:526,
  M4:525, M5:541, N1:921/1009/1010/1012, N2:468, P1:1148/1151), cinco na bíblia (`03-som.md:142`, `:277`, `:296`,
  `:343`, `:505`) e uma em `docs/jogo/arte/PRODUCAO.md:416` («A cópia para `godot/assets/sons/` e a troca no jogo
  são da H11»).
- **A bíblia conta um estado velho.** `docs/jogo/arte/03-som.md:343`: «Hoje tudo toca no Master: não existe
  `godot/default_bus_layout.tres`». O arquivo de fato não existe, mas o barramento da música existe desde a H07,
  criado em código (`godot/scripts/musica.gd:265-276`):

  ```gdscript
  func _criar_o_barramento() -> void:
  	_bus = AudioServer.get_bus_index(BUS)
  	if _bus < 0:
  		_bus = AudioServer.bus_count
  		AudioServer.add_bus(_bus)
  		AudioServer.set_bus_name(_bus, BUS)
  		AudioServer.set_bus_send(_bus, "Master")
  ```

  E a N1 atribui o barramento à H11 (`N1-o-canto.md:921`: «Sem o barramento "Musica" (H11), nada»).
- **Os efeitos não têm barramento.** `godot/scripts/som.gd:60-71` cria 16 tocadores 3D e 4 tocadores 2D sem `bus`:
  todos caem no Master. O jingle tem um tocador próprio, também no Master (`som.gd:209-211`).
- **Os 77 sons estão fora do jogo.** `ls godot/estudos/direcao/som/*.wav` dá 77 (`amb_salao`, `ass_p1..4`, os
  `car_*`, os `fx_*`, `jin_apito`, `jin_entrada_tique`, `jin_entrada_vai`, `jin_virada`, os 16 `jul_*`, os 24
  `pio_p{n}_*`, `reacao_pop` e os `ui_*`); `godot/assets/sons/` tem só as gravações CC0 de hoje.
- **O julgamento toca a nota velha.** `godot/scripts/minigames/minigame.gd:264-287` (`_reagir`): no erro,
  `Forja.som_falante(l, "nota_quebrada:%d" % l, 0.7)` e `Som.tocar("falha", pos, -6.0)`; no acerto,
  `Som.tocar("nota", pos, …, TOM_DO_LUGAR[l])` e, no perfeito, `Forja.som_falante(l, "nota:%d" % l, 0.8)`. A bíblia
  troca isso pelos `jul_<julgamento>_p<n>` na TV e no alto-falante e pelo `fx_tropeco_*` na TV.
- **O material toca no alto-falante.** `godot/scripts/forja.gd:906-914` (`tocar_material`) manda o material aos
  atuadores e também `som_falante(l, nome, 0.35 * forca)`; a tabela do casamento (`03-som.md`, «um material») diz
  que o material vai só aos atuadores. No perfeito, a `nota:%d` do mesmo quadro corta esse som de qualquer jeito.
- **O pio é o da H07.** `godot/scripts/main.gd:275`: `Forja.som_falante(l, "pio:%d" % jogadores[l].modelo_i, 0.8)`,
  o pio sintetizado de `nativo/som/sons_salas.c:51-56`. A bíblia pede `pio_p{n}_{intervalo}`, o intervalo vindo da
  cabeça escolhida.
- **O jingle procura no lugar errado para três deles.** `godot/scripts/som.gd:179`: `"JIN_APITO": ["sintese",
  "apito"]`; `jingle()` (`som.gd:195-215`) procura só `Musica.caminho(nome)`, que é `res://assets/ost/jingles/<nome>.ogg`
  (`musica.gd:193-194`), e cai na reserva. A bíblia (`03-som.md`, «Os jingles») diz que `jin_apito`, a entrada e a
  virada são WAV de `godot/assets/sons/`: um `jin_apito.wav` posto lá nunca tocaria.
- **A entrada fora da agenda da bíblia.** `minigame.gd:304-310` (`_contar_a_entrada`): `Som.jingle("JIN_ENTRADA")`
  nos tempos 0, 1 e 2 e `Som.tocar("confirma")` no 3. A bíblia pede o `jin_entrada_tique` nos tempos 2, 3 e 4 do
  compasso de contagem, o `jin_entrada_vai` no tempo 1 da faixa, e o `fx_entrada` começando 600 ms antes do tempo 1.
- **O alto-falante sem prioridade.** `nativo/som/som_controle.c:406-408` (`somc_falante`): todo som novo para o
  anterior e toca. A bíblia («O que toca onde») pede a ordem vitória e derrota, julgamento, segredo, pio, coleta,
  clique: o menor espera ou é descartado. Hoje, no lobby, quem entra e já mexe no ◀▶ para escolher o boneco corta o
  próprio pio com o clique (`main.gd:275` e `:902`).
- **O tom da faixa não existe.** Nenhum `pitch_scale` sai do tom da ficha; a nota do lugar é sempre de Dó.

## O alvo

- `godot/default_bus_layout.tres` com os seis barramentos da bíblia (Musica, Efeitos, Interface, Voz, Ambiente,
  Master), o limitador da Voz em −3 dBFS e o do Master em −1 dBFS. O `_criar_o_barramento` da Musica continua achando o
  barramento pelo nome (ele já confere `get_bus_index`) e só põe o passa-baixa se faltar.
- Todo tocador do `Som` toca no barramento da família do som (a coluna `familia` do mapa, numa tabela família →
  barramento escrita uma vez, no `som.gd`). O volume da TV segue no Master (`forja.gd:164`).
- Os abaixamentos da tabela «O que abaixa quando» pelos motivos da WS02: `Musica.abaixar("pausa", …)`,
  `("cartao", …)`, `("pista", …)`, `("microfone", …)`, e o Ambiente com a mesma regra (−6 dB no minigame, +3 dB no
  último terço). Nenhuma ficha escreve volume de barramento direto.
- O julgamento: `_reagir` toca `jul_<julgamento>_p<n>` na TV (no barramento Voz) e no alto-falante do dono (só se
  `nota_no_falante`), e o erro soma o `fx_tropeco_*` na TV. Onde a nota é instrumento (N3, O2, P3, o Relâmpago), o
  `mod_nota_p{n}` e o `mod_nota_quebrada_p{n}` ficam.
- A nota no tom da faixa: o semitom sai do tom da ficha (a tabela de `03-som.md`, «No tom da faixa»; sem tom, Dó) e
  vira `pitch_scale` na TV. No alto-falante, o mesmo arquivo registrado no módulo com a taxa multiplicada por
  `2^(s/12)` (o `som_registrar` reamostra para 48 kHz: é a velocidade da fita), com a chave `<id>@<s>`.
- O pio: `pio_p{n}_{intervalo}` na TV e no alto-falante de quem entrou, o intervalo pela cabeça
  (`04-o-cavaleiro.md`, «As peças»).
- Os jingles num lugar só por tipo: `jin_apito`, `jin_entrada_*` e `jin_virada` em `godot/assets/sons/<id>.wav`; os de
  música em `godot/assets/ost/jingles/<SLOT>.ogg`. `Som.jingle` procura o WAV primeiro para os três, depois o OGG,
  depois a reserva.
- A agenda da entrada pelo relógio de áudio, como a bíblia escreve.
- O alto-falante com prioridade: `somc_falante` sabe a categoria da voz que está tocando; a nova de categoria menor é
  descartada, a de categoria igual ou maior corta pela rampa de 20 ms. O material sai do alto-falante.

## Passos

1. O quadro e os textos: esta ficha entra como `docs/jogo/tarefas/H11-o-som-da-biblia-no-jogo.md`, com a linha no
   quadro (seção H). `03-som.md:343` passa a dizer o estado real (a Musica existe, criada pela H07; os outros cinco
   nascem aqui). `N1-o-canto.md:921` passa a «Sem o barramento "Musica" (H07), nada», e a função `abaixar_a_musica`
   da N1 passa a chamar `Musica.abaixar("pista", …)` da WS02 (a WS02 já pede isso; conferir).
2. Os arquivos: copiar os 77 de `godot/estudos/direcao/som/` para `godot/assets/sons/` por script (o
   `gerar_sons.py --conferir` antes), importar, e passar o `estado` de cada linha do mapa para `no jogo` quando a
   chamada existir. O id do arquivo é o do mapa (minúsculo, V05).
3. Os barramentos: o `default_bus_layout.tres`, a tabela família → barramento no `som.gd` e o `bus` em cada tocador.
   Rodar a prova do jogo: a música, os jingles e os efeitos continuam soando.
4. Os abaixamentos: a pausa, o cartão, o apito (corte seco, que já existe em `parar_seco`), o Ambiente no minigame e no
   último terço, cada um com o motivo dele na WS02.
5. O julgamento, o tropeço e o tom da faixa no `_reagir` do kit, lendo `nota_no_falante`.
6. O pio por cabeça no `main.gd:275` (e onde a G01 tiver o `PIO_DO_MODELO`).
7. Os jingles: o `jingle()` procura o WAV dos três; a agenda da entrada no `_contar_a_entrada`.
8. O alto-falante com prioridade: a categoria por parâmetro de `som_falante` (o padrão é a do clique, a menor), em
   `nativo/som/som_controle.c` e `nativo/godot/forja_som.cpp`; o `tocar_material` deixa de chamar `som_falante`.
9. Os `ui_*` dentro do minigame (`sala_jogo.gd:286`, `:315`, `:346`), no lugar do `tique` e do `confirma`.

## Armadilhas

- A prova de hoje confere «o clique tira o sino» (`godot/testes/prova_do_jogo.gd:174-182`). Com a prioridade, o sino
  de teste e o clique precisam de categoria: o teste do sino é da bancada (o maior), e a prova passa a conferir a
  regra nova (o clique não corta o sino; um julgamento corta o clique).
- O `som_registrar` guarda o som até o fim do processo (`nativo/godot/forja_som.cpp:36-39`): o tom da faixa por chave
  `<id>@<s>` multiplica os registros por até 12 tons. São arquivos curtos (os `jul_*` têm até 250 ms), mas conferir a
  memória com os quatro lugares e uma noite inteira.
- O `Musica._criar_o_barramento` hoje cria o barramento quando falta. Com o layout, ele existe desde o começo, e o
  efeito 0 tem de ser o passa-baixa: se o layout puser outro efeito antes, o `get_bus_effect(_bus, 0)` devolve o
  efeito errado.
- A V05 tira `RECEITAS` e `GRAVADOS` do código. Se ela já entrou, os ids novos são só linhas do mapa; se não, entram
  em `GRAVADOS` e a V05 os leva junto.
- A N1, a N2 e a P1 desligam o julgamento no alto-falante (`nota_no_falante` false): o `jul_*` também não vai.

## Não fazer

- Não escrever `AudioServer.set_bus_volume_db` fora da `Musica` (a WS02 é a dona).
- Não inventar som nem linha do mapa: o que faltar vai para o diretor de som.
- Não trocar os `ui_*` fora do minigame: são da G06, da G09 e da G11.

## Pronto quando

`grep -rn 'H11' docs/jogo` só acha citações a uma ficha que existe e está no quadro; os 77 sons tocam (o mapa diz
`no jogo` em cada linha com chamada); `grep -rn 'set_bus_volume_db' godot/scripts` só acha a `Musica` e o volume da
TV; um perfeito na prova toca `jul_ressonancia_p<n>` na TV e no controle do dono, e o clique não corta o pio.

## Provas

- `bash tests/prova_do_jogo.sh` (os barramentos existem com os nomes da bíblia; o perfeito toca o `jul_*` e abaixa a
  Musica 2 dB pela camada; o erro toca o tropeço; o pio de quem entra sobrevive ao clique; o `jingle("JIN_APITO")`
  toca o WAV quando ele existe).
- `cmake --build` e o `forja-testes` (a prioridade do alto-falante, quando o mixer ganhar prova pela WS05).
- `python3 scripts/portoes/som.py` (os ids novos casam com o mapa).

## Para o André (local)

Ouvir uma partida com os quatro controles: o julgamento soa no controle de cada um no tom da faixa, a música abaixa na
pausa e no cartão, e o limitador da Voz segura quatro perfeitos juntos sem estourar.

## Ao terminar

Marcar H11 como **feito** no [quadro](README.md), com o gasto, e tirar as frases «quando a H11…» das fichas que já
entraram.
