# WU03 — A regra do udev que cobre todo DualSense, e a falta dita

**Sprint:** W · **Tamanho:** M · **Depende de:** — (a resposta para quem compra sem sudo segue na lacuna 3 da
ETAPAS; esta ficha não a resolve, só deixa a regra certa e a falta medida)

## Por quê

No Linux, sem acesso ao hidraw, o SDL desiste do driver do DualSense em silêncio e o controle fica com o driver
genérico, que não tem luz nem efeito: some gatilho, barra de luz, luzinhas, luz do mudo e o relatório cru. O registro
só diz «efeitos não», sem causa. Quem tem a Steam ganha o acesso pelas regras dela; quem não tem, não.

E a regra que o repositório entrega abre demais e cobre de menos: `MODE="0666"` deixa qualquer conta da máquina
escrever no controle; casa só pelo pai USB, então não pega o rádio nem o Edge virtual; usa um grupo (`plugdev`) que
Fedora e Arch não têm. Nenhum script a instala nem a confere, e o LEIA-ME do pacote diz que ela serve só para «o
report cru do jack do fone».

## Ler antes

- ETAPAS, «O sudo no Linux» e a lacuna 3
- `COMO-RODAR.md:56-69` (o texto certo: sem a regra caem gatilho, luz, LEDs e o cru)
- `docs/jogo/06-telas-e-fluxo.md:80` (a palavra hidraw fica fora da tela)

## O estado de hoje

- `udev/99-forja-dualsense.rules:3-4`:
  ```
  KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666", GROUP="plugdev"
  KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0666", GROUP="plugdev"
  ```
- As regras de sistema desta máquina usam `MODE="0660", TAG+="uaccess"` e casam o rádio por `KERNELS`
  (`/usr/lib/udev/rules.d/60-steam-input.rules:35` e `:38`, `/lib/udev/rules.d/71-sony-controllers.rules:22-27`).
  A da Steam não cobre o Edge (`0df2`). O `udevadm info -a /dev/hidraw2` (o Edge virtual por uhid) não tem
  `ATTRS{idVendor}` na cadeia, só `KERNELS=="0003:054C:0DF2.…"`.
- No SDL 3.4.14 (`src/joystick/hidapi/SDL_hidapijoystick.c:509-515`), o hidraw que não abre só vira um `LogDebug`; o
  driver genérico (`src/joystick/linux/SDL_sysjoystick.c:1637` e `:1690-1698`) só declara rumble.
- `nativo/nucleo/pads.c:329` (`cap_efeitos` falso) e `:248-251` («report cru indisponível»); nada no módulo testa a
  permissão do hidraw.
- `scripts/instalar.sh`: `sistema` e `conferir` não tocam no udev; o `grep 99-forja scripts` só acha a cópia para o
  pacote (`scripts/exportar.sh:107-111`), com o texto do «jack do fone».

## O alvo

A regra do repositório segue o padrão das do sistema (só quem está sentado na máquina, cabo, rádio e uhid, DualSense
e Edge). O `instalar.sh sistema` a instala no mesmo sudo, e o `conferir` diz quando falta. O módulo sabe dizer «sem
permissão no hidraw: os efeitos não chegam» no registro e no relatório. A tela não muda: o cartão segue com o
«efeitos não» de hoje.

## Passos

1. **A regra.** Para `0CE6` e `0DF2`: uma linha por `ATTRS{idVendor}`/`ATTRS{idProduct}` (cabo) e uma por
   `KERNELS=="*054C:0CE6*"` / `"*054C:0DF2*"` (rádio e uhid), todas com `MODE="0660", TAG+="uaccess"`, sem `GROUP`.
   É sintaxe do udev, escrita do zero.
2. **O instalar.** `instalar.sh sistema` copia a regra para `/etc/udev/rules.d/`, recarrega e registra para o
   `desinstalar`. `instalar.sh conferir`, para cada `/sys/class/hidraw/*/device/uevent` com `HID_ID` de `054C:0CE6`
   ou `054C:0DF2`, testa `[[ -r /dev/hidrawN && -w /dev/hidrawN ]]` sem abrir o nó e diz «falta: a regra do udev
   (os efeitos do controle)».
3. **O módulo.** Em `nativo/nucleo/origem_linux.c`: quando um controle da Sony chega ao SDL por `/dev/input/event*`,
   achar o hidraw irmão no mesmo pai do sysfs e testar `access(W_OK)`. `OrigemFatos` ganha `hidraw_sem_permissao`;
   o registro e o relatório dizem a causa.
4. **O texto do pacote.** O LEIA-ME do Linux (`exportar.sh:107-111`) passa a dizer o que o `COMO-RODAR.md` diz.

## Armadilhas

- **A máquina dela tranca o hidraw do DualSense físico de propósito** (`73-hefesto-ps5-controller.rules`,
  `MODE:="0600"`, `TAG-="uaccess"`). A regra nova não pode vencer essa: o `:=` dela já ganha; conferir com
  `udevadm test` que continua trancado.
- **O `access()` não abre o nó**: a regra das provas (não escrever em `/dev/hidraw*`) segue valendo.
- **Na caixa das provas** `/sys/class/hidraw` está vazio: a prova usa o sysfs de mentira (`origem_raiz_sysfs()`).

## Não fazer

- Não instalar a regra de dentro do jogo nem pedir sudo ao jogador.
- Não pôr «hidraw» na tela.
- Não mexer na regra do touchpad (ESPERA-ELA).

## Pronto quando

- A regra não tem `0666` e cobre cabo, rádio e uhid do DualSense e do Edge.
- `conferir` acusa a falta; `sistema` instala; `desinstalar` tira.
- Sem permissão, o relatório diz a causa.

## Provas

- **De texto** (no portão dos scripts): a regra tem as duas linhas `KERNELS`, `TAG+="uaccess"` e nenhum `0666`. Hoje
  reprova.
- **Nativa** (`prova_origem.c`): um sysfs de mentira com um evdev `054c:0ce6` e o hidraw irmão apontando para um nó
  sem escrita espera `hidraw_sem_permissao`. Hoje o campo não existe.
- **De script:** o `conferir` contra um `/sys` de mentira (o molde de `forja_selftest_som.c:197-201`) imprime a falta.

## Para o André (local)

Num PC sem o pacote da Steam e sem a regra: o relatório diz a causa. Depois de `scripts/instalar.sh sistema` e de
religar o controle: «efeitos sim» no cabo.

## Ao terminar

Marcar WU03 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(udev): a regra cobre cabo, rádio e uhid só para quem está na máquina, e a falta é dita`.
