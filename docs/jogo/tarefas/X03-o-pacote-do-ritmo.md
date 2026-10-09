# X03 — O pacote do relógio de ritmo

**Sprint:** X · **Tamanho:** M · **Depende de:** H01, H02, H03

## Por quê

O relógio que segue a música e julga o toque é o coração de qualquer jogo de ritmo, e hoje escreve no registro do Forja e liga a faixa pela `Musica` do Forja.

## Ler antes

- [15 — O relógio de ritmo](../15-os-modulos.md#3-o-relógio-de-ritmo-e-o-julgamento--forja_ritmo)
- [13 — O relógio de áudio e o julgamento](../13-arquitetura.md#o-relógio-de-áudio-e-o-julgamento--h01-h02-h03)

## O estado de hoje

- `godot/scripts/ritmo.gd` (autoload `Ritmo`) chama `Forja.evento` em `registrar_nota` (`:120`) e `registrar_toque`
  (`:248`), `Forja.pad`/`Forja.pad_do_lugar` para o desvio por controle, `Musica.tocar_do_zero` e `Musica.laco_s` em
  `tocar` (`:65`) e `Opcoes.tempo_ms` em `ler_das_opcoes` (`:46`).

## Arquivos que mudam

- `godot/addons/forja_ritmo/` (novo): `ritmo.gd` (autoload `ForjaRitmo`), o resto do pacote
- `godot/scripts/ritmo.gd` (sai), `godot/scripts/ritmo_do_forja.gd` (novo: o conector que liga os sinais ao registro,
  lê as `Opcoes` e entrega o tocador)
- toda chamada `Ritmo.` em `godot/scripts/**` e `godot/testes/**` (troca por script)
- `godot/project.godot` (o autoload troca de nome)

## Passos

1. `git mv` para o pacote; o autoload passa a ser registrado pelo `plugin.gd`.
2. `registrar_nota`/`registrar_toque` viram os sinais `nota_marcada` e `julgou`; o conector chama `Forja.evento` com os mesmos campos de hoje.
3. `tocar` recebe o `AudioStreamPlayer` e o `laco_s` prontos; o conector pede à `Musica`.
4. O desvio por controle e as opções vão para o conector.
5. A prova do pacote: um tocador com uma faixa de cliques sintetizada; a batida e o julgamento saem certos sem o Forja.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_ritmo` passa e o registro de uma partida tem as mesmas linhas `nota` e `toque` de antes.

## Provas

- `bash tests/prova_do_importavel.sh forja_ritmo`
- `bash tests/prova_do_jogo.sh` (`_prova_do_relogio`, `_prova_da_calibracao`, `_prova_das_janelas`)
- `bash tests/prova_do_som.sh`
