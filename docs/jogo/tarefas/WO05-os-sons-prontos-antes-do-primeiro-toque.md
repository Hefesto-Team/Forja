# WO05 — Os sons prontos antes do primeiro toque

**Sprint:** W · **Tamanho:** P · **Depende de:** [V05](V05-o-som-pelo-mapa.md) e
[WS01](WS01-o-som-da-biblia-no-jogo.md) mexem no `som.gd`: esta ficha vai depois delas, ou entra nelas como um passo

## Por quê

O `Som` monta cada efeito na primeira vez que ele toca: sintetiza o som pelo módulo e procura as gravações em disco,
no quadro em que alguém pediu o som. Medido na caixa: os 42 nomes pela primeira vez somam 57,7 ms, e o pior, «sino»,
leva 9,23 ms num quadro só, em jogo. Da segunda vez, 0,08 ms no total. Num PC mais lento, o primeiro sino de cada
partida é um quadro perdido no meio da música.

## Ler antes

- [WS — o mapa do som](../revisao/WS-mapa.md)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `godot/scripts/som.gd:75-94`, a carga preguiçosa:
  ```gdscript
  func stream(nome: String, laco := false) -> AudioStreamWAV:
  	var chave := nome + ("@laco" if laco else "")
  	if _streams.has(chave):
  		return _streams[chave]
  	...
  		var pcm: PackedByteArray = Forja.ctl.sintetizar_pcm16(r[0], r[1])
  ```
- `:98-107`, o `versoes`: até dez `ResourceLoader.exists` e `load()` na primeira chamada de cada gravação.
- `RECEITAS` em `:17` (os nomes sintetizados).

## O alvo

Todo som que o jogo pode tocar já está montado antes da primeira tela de jogo, atrás da carga que já existe. A API do
`Som` não muda.

## Arquivos que mudam

- `godot/scripts/som.gd` (o `aquecer`)
- `godot/scripts/main.gd` (uma chamada na carga, antes do título) ou o `_ready` do próprio `Som`, se o módulo já
  estiver pronto ali
- `godot/testes/prova_do_jogo.gd` (a medida)

## Passos

1. `Som.aquecer()`: percorre `RECEITAS` (com e sem laço, conforme o uso) e as gravações conhecidas, chamando
   `stream` e `versoes`.
2. Chamar uma vez, depois que o módulo abriu e antes do título aparecer. Sem módulo, o `stream` já devolve vazio:
   o `aquecer` não pode falhar.
3. A prova: depois do `aquecer`, cronometrar o primeiro `Som.tocar` de cada nome.

## Armadilhas

- **A ordem dos autoloads.** O `Som` não pode aquecer antes de o `Forja` abrir o módulo, ou guarda `null` no cache
  para sempre. Aqueça depois do `abrir`, ou não guarde o `null`.
- **O custo vai para a abertura do jogo** (uns 60 ms uma vez): medir que o título não demora mais que hoje a
  aparecer, ou espalhar a carga pelos primeiros quadros do título.

## Não fazer

- Não mudar os nomes, as receitas nem o volume dos sons.
- Não refazer o que a V05 e a WS01 entregam no `som.gd`.

## Pronto quando

O primeiro `Som.tocar` de cada nome custa menos de 1 ms na prova (hoje, até 9,23 ms).

## Provas

- `bash tests/prova_do_jogo.sh`, pela caixa da WE01 e pelo semáforo da máquina.

## Para o André (local)

Jogar uma partida do começo e ver que o primeiro sino e o primeiro acerto não travam a tela.

## Ao terminar

Pôr a linha da WO05 no [quadro](README.md) como **feito**, com o commit.
