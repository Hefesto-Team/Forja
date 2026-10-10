# G07b — O encarte da noite e o fim da fita

**Sprint:** G · **Tamanho:** M · **Depende de:** G07 (as falas, o fim filmado, a virada), G01 (o cassete do título,
`play_ms`), G02 (`ForjaPlayer.nome`), H04 (o kit do minigame), F09 (a prova visual)

## Por quê

A [G07](G07-a-narrativa-leve.md) entrou com as falas, o fim de cada faixa filmado (o vencedor a 50 mm, o inserto do
último a 85 mm com a cara emburrada) e a «VIRADA!» carimbada no placar, provados na prova do jogo. O fim da noite
ficou de fora: o encarte com cada faixa e quem venceu, na caneta, e o fim da fita com o contador parado. Ficaram de
fora também as partes que mexem no kit do minigame e no 13, que são de outra frente na leva 1.

## Ler antes

- [G07, o encarte da noite e o fim da fita](G07-a-narrativa-leve.md#o-encarte-da-noite-os-créditos) (as medidas, a
  ordem, o som e o controle de cada passo)
- [01, os créditos são o encarte](../arte/01-cinema.md#os-créditos-são-o-encarte)
- [O kit do minigame, no 13](../13-arquitetura.md#o-kit-do-minigame--h04)

## O estado de hoje

- O pódio diz «Outra partida» no ✕ (`placar.gd`, as dicas do pódio) e começa outra partida; não há
  `godot/scripts/ui/encarte_da_noite.gd`, nem estado `"fita"` no main, nem `_ir_para_os_creditos()`.
- `TelaTitulo` desenha o cassete dentro do `_draw` do título: não há `desenhar_cassete` para o fim da fita usar.
- `Musica.FAIXAS` não tem `"creditos"`; `fx_autostop` e `fx_caneta` não estão em `godot/assets/sons/`.
- O kit (`Minigame.julgar_toque`) mede o desvio (`Ritmo.desvio_ms`) mas não chama `SalaJogo.julgar` com ele: no jogo,
  «Cedo», «Tarde», «arrastando» e «correndo» só saem de quem passar `desvio_s`. Ninguém chama `falar(l, "ajudou")`
  (o Diapasão, `Itens.puxa_o_combo_da_equipe`).
- O 13 não diz `julgar(l, j, palavra, no_tempo_1, desvio_s)` nem tem a linha `fala` no registro v2.
- Faltam no `traducoes.gd`: «Fechar a fita», «Gravar outra noite», «Ejetar», «Lado B», «Empate», «Ninguém» e os
  meses (FEV, ABR, MAI, AGO, SET, OUT, DEZ).

## O que fazer

1. `TelaTitulo.desenhar_cassete(ci, giro, esquerda, direita, linha, recorte)`, estática, saindo do `_draw` do título
   sem mudar nenhum número.
2. `godot/scripts/ui/encarte_da_noite.gd` (`class_name EncarteDaNoite`, com o `.uid`), como na G07: o fade, o papel
   que anda a 210 px/s, uma faixa a cada 560 px, o «Lado B», a caneta, o cross-fade e o fim da fita (o contador, a
   data, as duas saídas).
3. O main: a dica do pódio vira «Fechar a fita»; ✕ no pódio chama `_ir_para_os_creditos()`; o estado `"fita"` lê
   `encarte.saida()` («gravar»: outra partida do mesmo tamanho, `play_ms` zerado; «ejetar»: o título).
   `--sair-no-fim` com o robô continua saindo no pódio.
4. O som: `fx_autostop.wav` e `fx_caneta.wav` em `godot/assets/sons/` (`compress/mode=0`), as linhas do mapa e
   `"creditos": [57, 90, 0]` em `Musica.FAIXAS`. O toque 0/0,45/60 em todos no auto-stop.
5. O kit: `julgar_toque` passa o desvio em segundos a `julgar` e chama `falar(l, "ajudou")` no acerto em que
   `Itens.puxa_o_combo_da_equipe(l, genero)`. E o 13 ganha a linha do `julgar` com o desvio e a linha `fala` no
   registro v2.
6. As traduções que faltam e, na prova visual, o plano do resultado, o inserto, o placar com «VIRADA!», o encarte e o
   fim da fita na prancha.

## Pronto quando

O ✕ no pódio leva ao encarte, que passa as faixas com quem venceu e o «Lado B», e ao fim da fita, com o contador
parado no tempo real e as duas saídas, que funcionam; no jogo, o treino diz «Cedo» e «Tarde» pelo toque de verdade.

## Provas

- `bash tests/prova_do_jogo.sh` com a `_prova_do_fim_da_noite()` da G07 (o encarte, o contador, a data, as saídas, o
  auto-stop de 0,45 em cada lugar ocupado, «Ejetar» de volta ao título).
- `bash tests/prova_visual.sh` com a prancha olhada.

## Armadilhas

- **O `.uid`** do `encarte_da_noite.gd`.
- **O pódio da prova:** a prova da partida aperta ◯ no pódio e volta ao salão; ela continua igual.
- **A virada no placar já entrou** (G07): a `_prova_da_virada()` cobre o carimbo; a prova do fim da noite começa
  depois dela.

## Não fazer

- Não mudar as falas, o fim filmado nem a virada: são da G07.
- Créditos de quem fez o jogo no fim da noite (a `TelaCreditos` fica como está).

## Ao terminar

Commit sugerido: `feat: o encarte da noite até o fim da fita`.
