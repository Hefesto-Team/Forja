# WF03 — O volume do fone no controle

**Sprint:** W · **Tamanho:** P · **Depende de:** H07 (feita: a placa aberta na entrada do lugar); mexe em
`nativo/som/som_controle.c`, como a WS03, a WU04 e a WO03: não voar junto com elas

## Por quê

Com um fone no jack do controle, o módulo já troca a rota do som para o fone, sozinho, a cada quadro, e manda o som
do lugar para as duas orelhas. Só que ele nunca escreve o volume do fone (o byte 4 do relatório de saída): o volume
fica o que o controle trouxe de fábrica ou o que outro programa deixou, que pode ser alto demais para a orelha ou
zero. E os documentos dizem que nada disso existe: a pesquisa diz que «nenhuma sala usa» e que falta uma ficha, e o
05 diz que «hoje o som no controle só existe dentro das salas de som». A lacuna 16 das etapas lista o fone como
pendência sem ficha; esta é a ficha.

## Ler antes

- [A pesquisa do DualSense, «5. O fone no controle»](../pesquisa/dualsense.md) (as linhas 156-172)
- [05 — Háptica e controle](../05-haptica-e-controle.md) («A agenda do alto-falante»)

## O estado de hoje (medido em 09/10/2026, `85f24c3`)

- `nativo/som/som_controle.c:416-435`, o `acompanhar_fone` (chamado a cada quadro pelo `somc_atualizar`, `:527`),
  lendo o bit 0 do byte 53 (`nativo/nucleo/pads.c:541`):
  ```c
  pad_alto_falante(a, p, FORJA_VOL_FALANTE_PADRAO, fone ? FORJA_ROTA_FONE : FORJA_ROTA_FALANTE, FORJA_PREAMP_PADRAO);
  ```
- `src/forja_dualsense.c:198-203`, o bloco que vai ao controle:
  ```c
  s->vol_alto_falante = volume;
  s->audio = (uint8_t)(FORJA_AUDIO_BASE | ((rota & 0x03) << 4));
  s->audio2 = (uint8_t)(preamp & 0x07);
  forja_fx_da_sombra(fx, s, FORJA_FX_SPEAKER_VOL | FORJA_FX_AUDIO_CONTROL, FORJA_FX_PREAMP);
  ```
  O `FORJA_FX_HEADPHONE_VOL` (`include/forja_dualsense.h:31`) nunca é aceso por esse caminho, e o `vol_fone` da
  sombra (`:138`) nunca é escrito (`grep -rn vol_fone src nativo include` acha só a declaração e a cópia de
  `src/forja_dualsense.c:160`).
- A opção «Volume do controle» chega ao som pelo ganho do mixer (`godot/scripts/forja.gd:887`), e por isso vale no
  fone também: o que falta é só o volume do aparelho.
- A prova de hoje, `nativo/testes/prova_efeitos.c:56-61`, confere só a rota do alto-falante.
- Os documentos: `docs/jogo/pesquisa/dualsense.md:33`, `:164` e `:166`, e a linha da tabela de pendências (`:512`);
  `docs/jogo/05-haptica-e-controle.md:128-130`.

## O alvo

Com a rota do fone, o bloco acende o volume do fone e escreve `0x50` (o valor que a pesquisa já anotou, `:166`). Com
a rota do alto-falante, nada muda. Os documentos dizem o que está ligado: a rota troca sozinha, e o volume do fone é
fixo. Nenhuma tela muda.

## Arquivos que mudam

- `src/forja_dualsense.c` e `include/forja_dualsense.h` (a constante `FORJA_VOL_FONE_PADRAO` e o bit)
- `nativo/testes/prova_efeitos.c` (o caso da rota do fone)
- `docs/jogo/pesquisa/dualsense.md`, `docs/jogo/05-haptica-e-controle.md`

## Passos

1. `FORJA_VOL_FONE_PADRAO 0x50` ao lado do `FORJA_VOL_FALANTE_PADRAO`.
2. No `forja_fx_alto_falante`: quando a rota é `FORJA_ROTA_FONE` (ou `FORJA_ROTA_FONE_E_FALANTE`), escrever
   `s->vol_fone = FORJA_VOL_FONE_PADRAO` e acender `FORJA_FX_HEADPHONE_VOL` junto dos outros dois bits.
3. O caso de prova: a rota do fone acende o bit e põe `0x50` no byte 4; a rota do alto-falante não acende o bit
   (como hoje).
4. Corrigir a pesquisa (as linhas 33, 164, 166 e a pendência da 512, que vira «feito, com o volume fixo») e o 05
   (a frase das linhas 128-130 sai: a H07 já abre a placa na entrada).

## Armadilhas

- **O byte do bloco.** O volume do fone é o byte 4 do relatório de saída (o `headphone_vol` do
  `ForjaDs5Effect`); a prova lê pelo campo, não por um índice solto, para não errar por um.
- **O volume da Sony vai de 0 a 0x7F** no fone; o `0x50` é o de referência da pesquisa. Ouvir com ela antes de
  fechar: se ficar alto, baixar e registrar o porquê.
- **O núcleo do Linux** também escreve volume e pré-amp quando o fone sai (`forja_som.cpp:95-102`, o comentário):
  esta ficha não muda o caminho do alto-falante.

## Não fazer

- Não abrir uma opção nova de volume do fone: a interface fica como está.
- Não mexer na rota nem no `acompanhar_fone`.

## Pronto quando

`scripts/compilar.sh testes` passa com o caso novo (hoje, a rota do fone não acende o bit), e
`grep -n 'nenhuma sala usa\|só existe dentro das salas de som' docs/jogo/pesquisa/dualsense.md
docs/jogo/05-haptica-e-controle.md` não acha nada.

## Provas

- `scripts/compilar.sh testes` e `scripts/compilar.sh linux`.
- `bash scripts/portoes/rodar.sh` (os documentos).

## Para o André (local)

Com um DualSense no cabo e um fone no jack: entrar no lobby, ouvir o pio no fone, num volume confortável; tirar o fone
e ouvir o pio seguinte no alto-falante.

## Ao terminar

Pôr a linha da WF03 no [quadro](README.md) como **feito**, com o commit.
