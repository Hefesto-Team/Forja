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

## O que foi feito (leva 1, a-entrega)

- **A regra:** `udev/99-forja-dualsense.rules` virou `udev/70-forja-dualsense.rules`. São quatro linhas, cabo
  (`ATTRS{idVendor}`/`ATTRS{idProduct}`) e rádio com uhid (`KERNELS=="*054C:0CE6*"`, `"*054C:0DF2*"`), todas com
  `MODE="0660", TAG+="uaccess"` e sem `GROUP`. O número 70 vem do `uaccess`: a marca só vale se chegar antes do
  `73-seat-late.rules`, e com o 99 ela não valeria. O `udevadm verify` passa. A trava da máquina dela
  (`73-hefesto-ps5-controller.rules`, com `MODE:="0600"` e `TAG-="uaccess"`) roda depois da 70 e antes da
  `73-seat-late`, então segue vencendo. Isso foi lido na ordem dos arquivos; o `udevadm test` pede a regra
  instalada, e nada foi instalado nesta máquina.
- **O portão:** `scripts/portoes/udev.py` (base, reprova) reprova:
  - modo que dá escrita a «outros», ou `GROUP=`;
  - linha de hidraw sem `uaccess`;
  - falta da linha do cabo ou da do rádio e do uhid, do DualSense ou do Edge;
  - número de 73 para cima, ou nenhuma regra.

  Entrou no `rodar.sh`, no LEIA-ME dos portões e na `tests/prova_dos_portoes.sh`, com seis casos.
- **O instalar:**
  - `sistema` põe a regra em `/etc/udev/rules.d/` no mesmo sudo, mesmo quando nenhum pacote falta. Tira a
    `99-forja-dualsense.rules` antiga se ela estiver lá, recarrega o udev, reaplica no hidraw e anota o arquivo em
    `oficina/arquivos-do-sistema.txt`. Com `DESTDIR`, vai para a raiz falsa sem sudo e sem recarga;
  - `conferir` ganhou «O controle»: para cada hidraw com `HID_ID` de 054C:0CE6 ou 054C:0DF2, faz o teste
    `-r`/`-w` sem abrir o nó, e diz «falta a regra do udev (os efeitos do controle)»;
  - `desinstalar` tira o que está anotado.

  `FORJA_SYSFS` e `FORJA_DEV` trocam o `/sys` e o `/dev` que ele lê.
- **O módulo:** `origem_linux.c`, quando um controle da Sony chega por `/dev/input/event*`, sobe até quatro pais no
  sysfs atrás do `hidraw/hidrawN` irmão. Ele testa `access(R_OK|W_OK)` no nó (sem abrir), em `origem_raiz_dev()`, que
  é o `FORJA_DEV` ou o `/dev`. `OrigemFatos` e `Origem` ganham `hidraw_sem_permissao`. Com o campo ligado:
  - o registro diz «<controle>: sem permissão no hidraw: os efeitos não chegam (falta a regra do udev)»;
  - o JSON do relatório ganha `"causa_sem_efeitos"`, com a frase ou `null`;
  - o texto do relatório ganha a linha `efeitos       sem permissão no hidraw: os efeitos não chegam`.

  A tela não muda.
- **O texto do pacote:** o LEIA-ME do Linux diz o que o `COMO-RODAR.md` diz: sem a regra, os botões chegam, mas
  gatilhos, barra de luz, luzinhas e report cru não. Ele também diz que a regra vale só para quem está na
  máquina, e manda religar o controle. O nome novo está em `exportar.sh`, `COMO-RODAR.md`, `docs/DESENVOLVER.md`
  e `.github/SECURITY.md`.
- **As provas e as mordidas:**
  - `prova_origem.c`: um sysfs de mentira com o evdev 054c:0ce6, o hidraw irmão e um `/dev` de mentira. Com 0444,
    o campo liga; com 0666, sem o nó, ou com o `/dev` de verdade, não liga. Como root, o caso trancado é pulado;
  - `prova_relatorio.c`: a causa e o `null` no JSON, e a linha no texto;
  - `tests/prova_das_ferramentas.sh instalar`: 13 casos numa raiz falsa, com sudo, apt-get, dpkg e udevadm de
    mentira no PATH.

  Cada prova foi quebrada de propósito e reprovou:
  - o teste do `access` desligado dá 4 falhas nas provas nativas;
  - o `-w` tirado do `conferir` e a regra antiga deixada para trás dão 2 falhas no `instalar`;
  - a checagem do modo e a do rádio desligadas no portão dão 2 falhas na prova dos portões.
- **Fica para ela:**
  - na máquina dela, o `instalar.sh conferir` vai dizer que falta a regra para o DualSense físico. É a trava dela
    (0600, de propósito), e a regra do jogo não a vence;
  - validar o número 70 e a variável nova `FORJA_DEV`.
- **Fica para o André:** o passo da seção «Para o André». Num PC sem a Steam: primeiro o relatório com a causa,
  depois `scripts/instalar.sh sistema`, religar o controle e ver «efeitos sim» no cabo.
