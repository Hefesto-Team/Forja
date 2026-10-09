# WS04 — A reserva de toda seção

**Sprint:** W · **Tamanho:** P · **Depende de:** H05

## Por quê

A bíblia de som promete que o jogo funciona inteiro sem nenhuma faixa gerada: enquanto a faixa não existe, o
minigame toca a trilha sintetizada da seção. Duas seções não têm essa reserva. O Canto (S06) e A Voz (S08) apontam
para as entradas de silêncio das salas antigas, e os dez minigames delas tocariam calados, com o relógio de ritmo
andando a 120 bpm do relógio do sistema em vez do andamento da faixa. A P1 já corrige a S08 dentro dela; a N1 diz
«até ela existir, a reserva `sint_trilha` da H05» (`N1-o-canto.md:1003`) e não corrige nada.

A causa: a entrada `"canto"` (e a `"voz"`) de `FAIXAS` serve a duas coisas, o silêncio da sala antiga e a reserva da
seção, e o silêncio vazou para os minigames.

## Ler antes

- [03 — O som, «A música: o que cada seção pede»](../arte/03-som.md#a-música-o-que-cada-seção-pede): «a sala O Canto
  toca sem música», «a sala A Voz toca sem música»; os minigames da seção têm música.
- [H05 — O pipeline das faixas](H05-o-pipeline-das-faixas.md).
- `docs/jogo/tarefas/P1-a-voz.md:143-147` (a reserva `"sopro"` da S08).

## O estado de hoje

- `godot/scripts/musica.gd:11-24`:

  ```gdscript
  const FAIXAS := {
  	…
  	"bancada": [],
  	"voz": [],
  	"canto": [],
  }
  ```

  e `:31`, `SALA_DA_SECAO := ["", "centelha", "viga", "molde", "impacto", "galeria", "canto", "caminhos", "voz",
  "prova"]`.
- `musica.gd:104-124` (`tocar_do_zero`): sem `.ogg` e com a entrada vazia, `s` fica `null` e a música cala.
  `musica.gd:130-137` (`mapa`): sem faixa, `{"bpm": 120.0, "primeiro_tempo": 0.0, "sintetizada": false}`.
- Quem usa: `godot/scripts/minigames/minigame.gd:89-92` (o `comecar` de todo minigame lê `Musica.mapa(faixa)` e chama
  `Ritmo.tocar`, que chama `Musica.tocar_do_zero`, `godot/scripts/ritmo.gd:75`).
- Os slots das duas seções no mapa do áudio têm andamento e tom (`docs/jogo/audio/mapa.csv`, `mus_s06_j26`: «O Canto,
  110 BPM, Dó menor»; `mus_s08_j36`: «A Voz, 105 BPM, Ré menor»).
- Hoje nenhum minigame da S06 nem da S08 está no catálogo: o defeito aparece no dia em que a N1 entrar.
- A prova `_prova_das_faixas` (`godot/testes/prova_do_jogo.gd:1097-1121`) confere a reserva só de `MUS_S01_J01` e
  `MUS_S02_J06`.

## O alvo

Toda seção tem reserva própria, e o silêncio das salas antigas é outra entrada:

- `FAIXAS["capela"] = [60, 110, 1]` (Dó, 110 bpm, a faixa da N1) e `FAIXAS["sopro"] = [62, 105, 1]` (a da P1, com o
  mesmo nome que a P1, a P3 e a P5 já usam);
- `SALA_DA_SECAO[6] = "capela"` e `SALA_DA_SECAO[8] = "sopro"`;
- `"canto": []` e `"voz": []` ficam (são o silêncio das salas antigas e o `calar()`).

## Passos

1. As duas entradas e as duas trocas em `musica.gd`.
2. A `_prova_das_faixas` passa a conferir um slot de cada seção (`MUS_S01_J01`, `MUS_S02_J06`, …, `MUS_S09_J41`): sem
   a faixa na pasta, `Musica.mapa(slot).sintetizada == Forja.modulo` e, com o módulo, o `bpm` diferente dos 120 do
   relógio.
3. Na P1, o parágrafo «A faixa de reserva da seção» (`P1-a-voz.md:143-147`) passa a dizer que a reserva `"sopro"` já
   existe (esta ficha), e a linha da tabela de arquivos (`P1-a-voz.md:31`) perde «a faixa de reserva `"sopro"` e
   `SALA_DA_SECAO[8]`». Na N1, uma linha perto da `:1003` diz que a reserva da seção é a `"capela"`.

## Armadilhas

- A V04 leva a faixa sintetizada de cada seção para o `Catalogo.SECOES` (`faixa_sintetizada`). Se a V04 entrar
  depois, ela copia os valores novos; se entrar antes, as duas entradas vão direto para o catálogo, e o
  `SALA_DA_SECAO` já não existe. Em qualquer ordem, nenhuma seção pode apontar para uma entrada vazia.
- O semente da trilha é `hash(id)` (`musica.gd:59`): trocar o nome da entrada troca a trilha, e é o que se quer.
- A sala O Canto antiga (`godot/scripts/salas/canto.gd`) continua em silêncio: ela toca `Musica.tocar("canto")` pelo
  id da sala, não pelo slot.

## Não fazer

- Não preencher `"canto"` nem `"voz"`: a sala antiga e o `calar()` precisam do silêncio.
- Não mexer na escuta da P1 nem na pista da N1 (WS02).

## Pronto quando

A `_prova_das_faixas` passa para as nove seções, e `Musica.mapa("MUS_S06_J26").bpm` dá o andamento sintetizado de
110 (hoje dá 120 do relógio).

## Provas

- `bash tests/prova_do_jogo.sh`.

## Para o André (local)

Nada: é medida.

## Ao terminar

Pôr a linha no [quadro](README.md) como **feito**, com o gasto.
