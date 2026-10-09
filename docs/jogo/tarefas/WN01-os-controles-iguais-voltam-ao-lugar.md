# WN01 — Os controles iguais voltam cada um ao seu lugar

**Sprint:** W · **Tamanho:** M · **Depende de:** F04 (a reserva e a volta, feita)

## Por quê

Quatro DualSense no cabo têm a mesma assinatura, e a volta pela assinatura só devolve o lugar quando há um candidato
só. Se dois controles caem juntos (um hub que pisca, um cabo que puxa o outro, a mesa que esbarra), nenhum dos dois
volta ao lugar no meio da partida: os dois lugares ficam «sem controle», e o controle que volta pega um lugar livre
ou espera com as luzinhas apagadas. E no lobby é pior: o primeiro que aperta ✕ herda o primeiro lugar caído, com a
cor, os pontos e o cavaleiro de outra pessoa. A regra do [05](../05-haptica-e-controle.md#a-identidade-p1p4) diz
«quem caiu reencontra o lugar; um controle estranho não herda o lugar de ninguém», e com controles iguais as duas
metades falham.

## Ler antes

- [05 — A identidade P1..P4](../05-haptica-e-controle.md#a-identidade-p1p4) (a regra da volta)
- [09 — Fora do escopo](../09-fora-do-escopo.md) (identificar por MAC ou `uniq`: vedado) e o `CONTRATO.md:62`
  (o jogador é o lugar 0..3, nunca o MAC nem a ordem do `hidraw`)
- [F04 — O P1 da tela é o controle P1](F04-p1-e-o-led.md) (onde a reserva e a volta nasceram)

## O estado de hoje

A assinatura é o modelo, o tipo de origem e o nome, `nativo/nucleo/pads.c:162-164`:

```c
static void assinatura(const Pad *p, char *out, size_t tam) {
  snprintf(out, tam, "%s|%d|%s", p->vidpid, (int)p->origem.tipo, p->nome);
}
```

No cabo, o SDL dá a todo DualSense o mesmo nome («DualSense Wireless Controller»), o mesmo `054c:0ce6` e a mesma
origem: as quatro assinaturas são a mesma cadeia.

Na conexão, o lugar só volta com um candidato, `nativo/nucleo/pads.c:373-400`:

```c
  /* A volta: um slot desconectado com a mesma assinatura, e só um, retoma. */
  ...
  if (candidatos == 1) {
  ...
  if (p->slot < 0)
    reservar(a, livre);
```

Com dois lugares caídos de assinatura igual, `candidatos` vale 2: nenhum volta, e o controle vai para a reserva de um
lugar livre (ou para o player index -1, se a mesa está cheia). Fora do lobby não há outro caminho de volta:
`Forja.entrar` só é chamado em `godot/scripts/main.gd:202` (o `_todos_entram` dos argumentos de prova) e
`:670` (o ✕ do lobby).

No lobby, `nativo/nucleo/pads.c:615-620` dá o **primeiro** lugar caído de assinatura igual, sem contar candidatos:

```c
  /* primeiro, um lugar de quem caiu com a mesma assinatura */
  for (int s = 0; s < MAX_JOGADORES && alvo < 0; s++)
    if (a->pads.slot[s].ocupado && a->pads.slot[s].pad < 0 && strcmp(a->pads.slot[s].assinatura, sig) == 0)
      alvo = s;
```

O controle já guarda um dado que distingue um aparelho do outro e não é MAC: `p->usb_pai`, o caminho do
`usb_device` no sysfs, que termina na porta física (`…/usb3/3-2/3-2.1`), copiado em `nativo/nucleo/pads.c:322`. O som
do controle já casa pelo aparelho com ele (`nativo/som/som_controle_linux.c:76-83`). A volta não o usa, e o `Slot`
não o guarda (`nativo/nucleo/pads.h:95-103`).

Nenhuma prova vê isto: o simulador dá nomes diferentes aos quatro (`nativo/nucleo/simulador.c:210-211`, «DualSense
simulado 1..4»), a `godot/testes/prova_de_poucos.gd:141` tira só o cabo do P2 e a `godot/testes/prova_do_jogo.gd:495`
só confere a volta do P3. E a regra mora dentro de `conectou` e de `pads_entrar`, que falam com o SDL: a prova nativa
(`nativo/testes/forja-testes`, ligada só ao `forja_nucleo` em `nativo/CMakeLists.txt:90`) não a alcança.

## O alvo

A escolha do lugar de quem volta é uma função pura do núcleo, sem SDL, provada na prova nativa. Ela recebe os lugares
caídos (a assinatura e a porta de cada um) e o controle que chegou (a assinatura e a porta), e devolve o lugar ou -1.
A conexão e o ✕ do lobby chamam a mesma função. A porta física desempata quando há mais de um candidato; sem porta
que case, nada se devolve no escuro.

## Passos

1. **A porta no lugar.** O `Slot` ganha, ao lado da `assinatura`, a `porta`: o trecho final do `usb_pai` (o nome do
   `usb_device`, como `3-2.1`), gravada em `pads_entrar` junto com a assinatura. Vazia no rádio, no Windows e onde o
   sysfs não diz.
2. **A função pura.** Em `nativo/nucleo/volta.c` (com `volta.h`), uma função como
   `int volta_escolher(const VoltaLugar *caidos, int n, const char *assinatura, const char *porta)`: dos lugares
   caídos de assinatura igual, se um só, ele; se mais de um, o de porta igual (e só se for um); senão, -1. Entra no
   `forja_nucleo` (`nativo/CMakeLists.txt:51-68`).
3. **A conexão usa a função** (`nativo/nucleo/pads.c:373-400`). O registro diz por que voltou («pela assinatura» ou
   «pela porta 3-2.1») e, quando há empate sem porta, diz que o lugar espera o ✕ no lobby.
4. **O lobby usa a mesma função** (`nativo/nucleo/pads.c:615-620`), no lugar do «primeiro caído». Sem candidato
   único, o controle segue para a reserva ou o lugar livre, como hoje, e nunca herda o lugar de quem caiu.
5. **O simulador fala como o aparelho.** Um modo em que os quatro têm o mesmo nome e cada um uma porta falsa (por
   exemplo um nome novo na lista do `--defeitos`, `nomes-iguais`, em `nativo/nucleo/simulador.c` e `simulador.h`),
   e a conexão do simulado copia essa porta para o `usb_pai`.
6. **A prova do jogo.** Na `godot/testes/prova_de_poucos.gd`, com `CABO=2` e o modo do passo 5: os cabos do P2 e do
   P3 saem no mesmo quadro e voltam em ordem trocada (o P3 primeiro); cada um volta ao seu lugar. Uma linha nova em
   `tests/prova_de_poucos.sh`.
7. Atualizar a regra no [05](../05-haptica-e-controle.md#a-identidade-p1p4): «a mesma assinatura e, entre controles
   iguais, a mesma porta».

## Armadilhas

- **A porta não é o aparelho.** Quem tira o cabo e põe noutra porta não é reconhecido pela porta. Com um candidato
  só, a regra de hoje vale e ele volta; com dois, espera o ✕ no lobby. É o preço de não usar o MAC, e o aviso tem de
  dizer isso numa frase do mundo, sem palavra de aparelho (o «Nunca na tela» do
  [06](../06-telas-e-fluxo.md)).
- **O caminho inteiro do `usb_pai` muda de comprimento** (512 bytes): guardar só o nome final no `Slot`, não o caminho.
- **O rádio e a ponte.** No Bluetooth o `usb_pai` é vazio e o jogo é só de entrada; pela ponte, os controles chegam
  com nomes distintos («… (P{N})»), e a assinatura já os separa. Os dois casos seguem a regra de hoje: não quebrar.
- **O espelho** (`nativo/nucleo/pads.c:593-612`) roda antes da volta no lobby e não muda.
- **Os arquivos da WC01.** A WC01 (o toque no instante do aperto) também mexe em `pads.c`, `pads.h`, `simulador.c` e
  `simulador.h`: as duas não voam juntas, ou voam no mesmo conjunto.
- **O simulado não abre o sysfs** (`nativo/nucleo/pads.c:308-309`): a porta falsa entra pelo simulador, não pelo
  `origem_fatos_linux`.

## Não fazer

- Não usar MAC, `uniq`, número de série nem a ordem do `hidraw` para identificar o jogador.
- Não devolver um lugar quando a escolha é incerta: um controle que espera é melhor que um P1 trocado.
- Não mexer no `main.gd` nem no lobby do GDScript: a cura é no módulo.
- Não tocar na `godot/testes/prova_do_jogo.gd` (a V02 a reparte).

## Pronto quando

- A função pura devolve o lugar certo nos quatro casos da prova nativa (abaixo), e `pads.c` não tem mais regra de
  volta própria.
- Com o modo de nomes iguais, a prova de poucos tira dois cabos juntos e cada um volta ao seu lugar, na conexão
  (sem ✕).
- No lobby, o controle de outra porta não herda o lugar de quem caiu.

## Provas

- **Nativa** (`nativo/testes/prova_volta.c`, registrada em `nativo/testes/provas.c` e no `nativo/CMakeLists.txt:78-88`):
  quatro lugares com a mesma assinatura e portas `3-1`, `3-2`, `3-3`, `3-4`; os lugares 1 e 3 caídos; o controle da
  porta `3-3` volta → 3 (hoje a regra embutida dá -1, `candidatos == 2`); o da porta `3-1` → 1; o de uma porta
  desconhecida → -1; com um caído só, qualquer porta → ele. A mordida: trocar o desempate por «o primeiro» e ver a
  prova reprovar.
- **Do jogo:** `CABO=2` na `bash tests/prova_de_poucos.sh`; hoje reprova em «o P2 voltou ao lugar», depois da cura
  passa. E a `bash tests/prova_do_jogo.sh` segue verde (pelo semáforo, com a máquina livre).

## Para o André (local)

Com quatro DualSense no cabo e um hub: na partida, tirar o hub da tomada (os quatro caem juntos) e pôr de volta.
Cada controle volta com a sua cor e o seu número, sem apertar nada. Depois, no lobby, tirar o P2 e pôr o cabo dele
noutra porta: ele espera, e o aviso diz o que fazer.

## Ao terminar

Marcar WN01 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(controle): os controles iguais voltam cada um ao seu lugar, pela porta`.
