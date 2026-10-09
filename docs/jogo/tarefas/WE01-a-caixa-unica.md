# WE01 — A caixa única das provas

**Sprint:** W · **Tamanho:** M · **Depende de:** —

## Por quê

Toda prova que abre o Godot com `--simular` tem de rodar sem enxergar o DualSense ligado na máquina: se enxerga, o
controle de verdade ganha um lugar, e a prova toca o alto-falante, a háptica e os gatilhos dele (a própria
`tests/prova_da_bancada.sh:17-18` avisa). Hoje cada prova monta a própria caixa, as cópias divergiram, e em quase
todas a caixa é opcional: sem o `bwrap`, a prova roda solta e não diz nada. O `scripts/gauntlet.sh`, o
`tests/telas.sh fotos` e o `scripts/trailer.sh` nem caixa têm. O `--headless` não protege: ele cala a TV, não o
módulo.

## Ler antes

- [A esteira](../o-time/a-esteira.md) («O controle real: nunca. As provas rodam na caixa (`bwrap`) com o
  simulador.»)
- [tests/prova_visual.sh](../../../tests/prova_visual.sh) (a única que recusa rodar sem a caixa: é o molde)
- [scripts/portoes/teste_mudo.py](../../../scripts/portoes/teste_mudo.py) (o portão irmão, que só olha o som)
- [nativo/nucleo/pads.c](../../../nativo/nucleo/pads.c) (o `conectou`)

## O estado de hoje

Contagem por arquivo (o `FORJA_SYSFS` vazio, o `pactl` de mentira, o `bwrap`), medida em 09/10/2026:

| arquivo | sysfs | pactl | bwrap | a caixa |
| --- | --- | --- | --- | --- |
| `tests/prova_do_jogo.sh` | 2 | 4 | 3 | opcional |
| `tests/prova_da_bancada.sh` | 1 | 3 | 2 | opcional |
| `tests/prova_de_poucos.sh` | 2 | 0 | 2 | opcional |
| `tests/prova_da_exportacao.sh` | 0 | 0 | 2 | opcional |
| `tests/prova_visual.sh` | 1 | 3 | 3 | obrigatória |
| `tests/telas.sh` | 0 | 0 | 0 | nenhuma |
| `scripts/gauntlet.sh` | 0 | 0 | 0 | nenhuma |
| `scripts/trailer.sh` | 0 | 0 | 0 | nenhuma |

- A caixa opcional é a mesma em quatro arquivos, por exemplo `tests/prova_do_jogo.sh:47-51`:

  ```bash
  CAIXA=()
  if command -v bwrap > /dev/null; then
    CAIXA=(bwrap --dev-bind / / --dev /dev --tmpfs /run/udev --tmpfs /sys/class/input
           --tmpfs /sys/class/hidraw)
  fi
  ```

  Sem o `bwrap` no PATH, `"${CAIXA[@]}" "$GODOT"` vira o Godot solto.
- `scripts/gauntlet.sh:36` roda a prova inteira 21 vezes sem caixa, com o `pactl` e o sysfs de verdade:
  `timeout 600 "$GODOT" --headless --fixed-fps 60 --path "$RAIZ/godot" res://testes/prova_do_jogo.tscn -- --simular=4 --robo ...`.
- `tests/telas.sh:30-32` (o `fotos`) e `scripts/trailer.sh:19-21` rodam o jogo com `--simular=4` pelo `xvfb-run`, sem
  caixa.
- `tests/prova_visual.sh:63-64` é a única que recusa: `command -v bwrap > /dev/null || { echo "sem bwrap: ..."; exit 2; }`.
- Os `pactl` de mentira divergiram: o da prova do jogo lê `$SERVIDOR_DE_MENTIRA` em `list sinks`; o da bancada só sai
  0; a de poucos e a da exportação não têm nenhum.
- No módulo, o `SDL_Init(SDL_INIT_GAMEPAD | SDL_INIT_EVENTS)` (`nativo/nucleo/forja.c:173`) roda com `--simular`
  também, e o `conectou` (`nativo/nucleo/pads.c:254-281`) abre todo `GAMEPAD_ADDED`. O controle de verdade só ganha
  `p->simulado = false` (`:281`) e entra no jogo como qualquer outro.
- `scripts/portoes/teste_mudo.py` confere só o `--audio-driver Dummy` nas chamadas pelo `xvfb-run`; nada confere a
  caixa.
- No CI não há `bwrap` (o `forja.yml` não instala), e o runner não tem controle: lá a prova roda solta, e está certo.

## O alvo

Um lugar só monta a caixa, e a regra vale até para quem chama o Godot à mão:

- `tests/caixa.sh`, para `source`: monta a pasta com o `pactl` e o `pw-cat` de mentira (o `pactl list sinks` imprime
  `$SERVIDOR_DE_MENTIRA` quando ele existe, e nada quando não), põe a pasta na frente do PATH, aponta o
  `FORJA_SYSFS` para uma pasta vazia e define `caixa <comando...>`, que roda o comando no `bwrap` com o `/dev` novo
  e o `/run/udev`, o `/sys/class/input` e o `/sys/class/hidraw` vazios. Sem o `bwrap`: com a variável `CI`
  definida, roda direto; sem ela, sai 2 dizendo que a prova não roda fora da caixa.
- Toda prova de `tests/`, o `scripts/gauntlet.sh`, o `tests/telas.sh fotos` e o `scripts/trailer.sh` chamam o
  Godot por `caixa`.
- Um portão novo, irmão do teste mudo, reprova a chamada do Godot em `tests/` e `scripts/` que rode cena ou jogo fora
  do `caixa`.
- No módulo, a sessão aberta com `--simular` só aceita controle virtual.

## Passos

1. Escrever `tests/caixa.sh` juntando o que hoje está em `tests/prova_do_jogo.sh:21-51` e
   `tests/prova_visual.sh:50-64`. A guarda «o `pactl` é o de mentira» vai junto.
2. Trocar, em cada arquivo da tabela, o bloco próprio por `source "$RAIZ/tests/caixa.sh"` e o
   `"${CAIXA[@]}" "$GODOT"` (ou o `"$GODOT"` solto) por `caixa "$GODOT"`. A prova do jogo continua dizendo o
   `SERVIDOR_DE_MENTIRA` de cada rodada.
3. `scripts/portoes/caixa.py`: para cada `.sh` de `tests/` e `scripts/`, junta as continuações como o
   `teste_mudo.py` faz e reprova a linha que chama o Godot com cena, `--simular`, `--robo` ou `res://` sem `caixa`
   antes. Ficam de fora o `--import`, o `--export-*` e o `-s <script>.gd` (não abrem o módulo), e o próprio
   `tests/caixa.sh`. Modo reprova; uma linha no `scripts/portoes/rodar.sh` e no `LEIA-ME.md` dos portões.
4. Os casos do portão em `tests/prova_dos_portoes.sh`: a chamada solta reprova, a pela caixa passa, o `--import`
   passa.
5. No módulo: o `forja_abrir` guarda numa marca própria (`so_virtuais`) que a sessão nasceu com `--simular`, e o
   `conectou` fecha o gamepad que não é virtual quando a marca está ligada, com uma linha no registro. A decisão
   mora numa função pura da parte sem SDL (ao lado do `origem_classificar`), com um caso em
   `nativo/testes/prova_origem.c`.

## Armadilhas

- O `forja_simular` (`nativo/nucleo/forja.c:227`) muda o `f->simular` no meio da sessão quando alguém escolhe jogar
  no teclado. A marca nova não pode seguir o `f->simular`: quem começou sem `--simular` e liga um controle depois
  de entrar no teclado tem de ser aceito.
- O `bwrap` com `--dev-bind / /` deixa o soquete do servidor de som visível. Hoje isso não pesa (o controle simulado
  usa a placa virtual, `nativo/som/som_controle.c:189-191`), mas é o `pactl` de mentira que impede o jogo de achar o
  alto-falante do controle de verdade pelo nome. Ele vai para toda prova, inclusive a da exportação.
- O `ci-local` roda o YAML num contêiner que define `CI`. Lá dentro não há controle nem `bwrap`, e a regra libera.
  Não use outra variável para isso.
- O `experimental/rodar.sh` é a bancada com os controles da mesa: fica fora do portão (ele mora fora de `tests/` e
  `scripts/`).

## Não fazer

- Não liberar a falta do `bwrap` por uma variável de escape fora do CI.
- Não mudar o que cada prova confere: esta ficha muda só como o Godot é chamado.
- Não rodar, para testar, nenhuma prova fora da caixa nesta máquina: o DualSense da dona está ligado nela.

## Pronto quando

`git grep -n 'CAIXA=(' tests scripts` não acha nada, `bash scripts/portoes/rodar.sh` passa com o portão novo e,
com um PATH sem o `bwrap` e sem `CI`, toda prova que abre o Godot sai com 2 antes de abrir.

## Provas

- Antes da cura, o portão novo reprova `scripts/gauntlet.sh:36`, `tests/telas.sh:30` e `scripts/trailer.sh:19`;
  depois, passa.
- `env -u CI PATH=<uma pasta com tudo menos o bwrap> bash tests/prova_do_jogo.sh; echo $?` dá 2.
- `bash tests/prova_dos_portoes.sh` e `bash tests/prova_do_jogo.sh` verdes.
- `nativo/testes/prova_origem.c`: com `so_virtuais`, o controle de verdade é recusado e o virtual entra; sem a marca,
  os dois entram.

## Para o André (local)

Com o DualSense dele ligado: `./run-local.sh -- --simular=4` mostra só os quatro simulados (o de verdade não pega
lugar e o registro diz que foi recusado); `./run-local.sh` sem argumento e «jogar no teclado» seguem aceitando o
controle ligado depois.

## Ao terminar

Pôr a linha da WE01 no [quadro](README.md) como **feito**, com o commit, e citar o portão novo em
`scripts/portoes/LEIA-ME.md`.
