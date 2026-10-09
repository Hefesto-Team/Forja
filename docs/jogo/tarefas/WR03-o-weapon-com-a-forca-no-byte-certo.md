# WR03 — O Weapon com a força no byte certo

**Sprint:** W · **Tamanho:** P · **Depende de:** —

## Por quê

Todo gatilho Weapon sai na força mínima. O empacotador põe a força no byte errado: o firmware lê zero no lugar dela,
que é a força 1 de 8. A pistola da Galeria (a medição às cegas da arma), a Prova, a Bancada, o martelo da I1 e a
trava da M5 sentem o mesmo clique fraco, qualquer que seja o número pedido. E a opção «gatilho fraco» das opções, que
corta a força do Weapon pela metade (`godot/scripts/opcoes.gd:117-118`), não muda nada no controle. A pesquisa marca
o Weapon como «usa · nada falta» (`docs/jogo/pesquisa/dualsense.md:25`).

## Ler antes

- `docs/jogo/pesquisa/dualsense.md` (o mapa em uma tabela e a fonte da embalagem por zona)
- [M1 — A galeria](M1-a-galeria.md), [I1 — O martelo de Hefesto](I1-o-martelo-de-hefesto.md) e
  [M5 — A catapulta](M5-a-catapulta.md) (quem conta com a força do Weapon)

## O estado de hoje

`src/forja_dualsense.c:49-73`, o Weapon escrito com o molde do Feedback (3 bits por zona, deslocados 3 × zona):

```c
    uint16_t active = (uint16_t)((1u << start) | (1u << end));
    uint32_t forces = (uint32_t)force3(str) << (3 * end);
    pack_zones(out, FORJA_HID_TRIGGER_WEAPON, active, forces, 0);
```

Compilado à parte e impresso (09/10/2026):

```
weapon(3,6,força 8): 25 48 00 00 00 1c 00 00 00 00 00
weapon(2,6,força 8): 25 44 00 00 00 1c 00 00 00 00 00
```

O byte 3 fica sempre em `00`; a força vai parar no byte 5.

As duas referências põem força − 1 direto no byte 3, um campo só, e zeram o resto:

- o gerador de efeitos de John «Nielk1» Klein (gist `6d54cc2c00d2201ccb8c2720ad7538db`, MIT, a mesma fonte que o
  comentário de `src/forja_dualsense.c:3` cita): Weapon(3,6,8) = `25 48 00 07 00 00 00 00 00 00 00`;
- boykopovar/AnyPS5 (GPL-2.0, só leitura), `core/libs/prx/libScePad/src/PadState.cpp:207-215`: as zonas nos bytes
  1-2 e `effect[3] = força − 1`.

Quem pede o Weapon: `godot/scripts/salas/galeria.gd:190`, `salas/prova.gd:235`, `salas/bancada.gd:42` (todos
`2, 6, 8`). As provas só conferem o byte do modo: `nativo/testes/prova_efeitos.c:21-26` («Weapon 0x25 no
common[10]») e `src/forja_selftest.c:60-62`.

## O alvo

`forja_trigger_pack` de Weapon dá exatamente a embalagem oficial: zonas de início e fim nos bytes 1-2, força − 1 no
byte 3, bytes 4 a 10 em zero. Feedback e Vibration já batem com as referências e não mudam. A API do GDScript e a
tela não mudam.

## Passos

1. Escrever a prova primeiro (abaixo) e vê-la reprovar.
2. No `case FORJA_TRIGGER_WEAPON`: `out[0] = FORJA_HID_TRIGGER_WEAPON`, `out[1]` e `out[2]` com as zonas,
   `out[3] = force3(str)`, sem `pack_zones` e sem deslocar.
3. Conferir que a Galeria e a M1 não calibraram nada às cegas em cima da força errada (`nativo/nucleo/cegas.c:212`):
   se houver número de referência medido com o Weapon fraco, anotar para remedir na bancada.

## Armadilhas

- **Os limites ficam.** Início de 2 a 7, fim maior que o início e até 8, força de 1 a 8 (já estão em `:52-66`).
- **Comparar o bloco inteiro**, não só um byte: o defeito de hoje é um byte certo no lugar errado.
- **O Nielk1 é MIT** (pode entrar com o aviso, `dualsense.md:97`); o AnyPS5 é GPL: dele, só a leitura.

## Não fazer

- Não mexer no Feedback nem no Vibration.
- Não ligar os modos da emenda (Slope, Multiple Position): é decisão dela (`dualsense.md:509`).

## Pronto quando

- Weapon(3,6,8) sai `25 48 00 07 00 00 00 00 00 00 00`; Weapon(3,6,1) sai com o byte 3 em `00`.
- Na mão, a força 8 dá o clique duro, e a força 1 é nitidamente mais fraca.

## Provas

- **Nativa** (`nativo/testes/prova_efeitos.c`, ou uma irmã): o bloco inteiro de Weapon(3,6,8), Weapon(2,6,8) e
  Weapon(3,6,1) contra os bytes acima. Hoje a primeira sai `25 48 00 00 00 1c …`: reprova.
- `make test` (o `bin/forja-selftest`, de `src/forja_selftest.c:60-62`) ganha a mesma conferência do byte 3.

## Para o André (local)

Na Bancada, o modo Weapon com a força 8 e depois com a opção «gatilho fraco»: o primeiro trava e estala, o segundo
é visivelmente mais leve. Na Galeria, a pistola tem parede e clique.

## Ao terminar

Marcar WR03 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(gatilho): a força do Weapon vai no byte 3, como na embalagem oficial`.
