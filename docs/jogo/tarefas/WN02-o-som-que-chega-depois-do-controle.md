# WN02 — O som que chega depois do controle

**Sprint:** W · **Tamanho:** M · **Depende de:** H07 (a placa aberta na entrada e o `_caiu`, feita)

## Por quê

Quando um controle cai e volta, a placa de som se refaz no quadro em que o jogo vê o controle voltar, com a lista
de dispositivos de som daquele instante. Mas o controle e a placa dele chegam por dois caminhos diferentes do
sistema: o controle pela entrada, a placa pelo servidor de som, cada um no seu tempo. Se a placa chega depois, o
jogador volta sem alto-falante, sem háptica por áudio e sem microfone, e nada no jogo relê a lista até outra mudança
de controles ou outra sala de som. Nas seções N e P (o canto, a voz) isso é um jogador que não joga.

## Ler antes

- [H07 — O som em todo evento](H07-o-som-em-todo-evento.md) (a placa aberta na entrada, o `_caiu`, e a armadilha
  «não refazer a cada `pads_mudaram`, corta o pio»)
- [ADR 006 — O som se acha como um jogo acha](../../adr/006-o-som-se-acha-como-um-jogo-acha.md)
- [O som chega ao controle](../../COMO-O-SOM-CHEGA-AO-CONTROLE.md)

## O estado de hoje

A volta refaz a placa pelo sinal dos controles, `godot/scripts/main.gd:242-253`:

```gdscript
func _ao_mudar_os_controles() -> void:
	...
		elif _caiu.has(l):
			_caiu.erase(l)
			voltou = true
	if voltou:
		_abrir_o_som(true)
```

e `_abrir_o_som` chama `Forja.som_preparar(papel)` (`godot/scripts/main.gd:272`). No módulo, `somc_preparar`
(`nativo/som/som_controle.c:299-307`) encerra tudo, lê a lista **uma vez** e escolhe:

```c
void somc_preparar(Forja *a) {
  somc_encerrar(a);
  zerar();
  abrir_audio();
  listar();
  escolher(a);
```

`listar` (`nativo/som/som_controle.c:141-172`) pede `SDL_GetAudioPlaybackDevices` e `SDL_GetAudioRecordingDevices`
naquele instante. Nenhum código do módulo escuta a chegada de um dispositivo de som: o laço de eventos,
`nativo/nucleo/forja.c:219-221`, só repassa a `pads_evento`, que só trata os eventos de controle:

```c
  while (SDL_PollEvent(&e))
    pads_evento(f, &e);
```

(`grep -rn 'AUDIO_DEVICE_ADDED\|AUDIO_DEVICE_REMOVED' nativo` não acha nada.) Se o nó do controle ainda não está na
lista, a primeira passada de `escolher` (`nativo/som/som_controle.c:218-269`, pelo aparelho) não acha o `usb_pai`
dele, as outras não têm nó sobrando, e o lugar fica com `no[PAPEL_ALTO_FALANTE] = -1`. Depois disso, a placa só se
refaz numa sala de som (`godot/scripts/salas/sala_jogo.gd:114` e `:128`) ou noutra volta.

A prova que confere a volta (`godot/testes/prova_do_jogo.gd:495`, «kit: o P3 voltou com o alto-falante») passa
porque o controle simulado ganha na hora a placa virtual de `abrir_virtual` (`nativo/som/som_controle.c:189-197`):
ela nunca exercita a ordem dos dois caminhos.

**O que não foi medido:** a ordem real na máquina dela, com o controle na mão. É leitura de código; o passo 1 mede.

## O alvo

O módulo ouve a lista de som mudar. Quando um nó novo chega e um lugar ocupado, de controle de verdade, está sem nó
num papel que esse nó serve, só esse lugar é reescolhido e ganha a saída nova; quem já tocava não é cortado. A
decisão (que lugar fica com o nó novo) é uma função pura do núcleo, provada na prova nativa.

## Passos

1. **Medir primeiro.** O registro ganha uma linha quando a lista de som muda («som: chegou <nome>», «som: saiu
   <nome>»), com o tempo. Na bancada, tirar e pôr o cabo do P3 e ler a distância entre «P3 voltou ao lugar» e
   «som: chegou …». Anotar o número aqui.
2. **O evento.** Em `nativo/nucleo/forja.c`, o laço repassa `SDL_EVENT_AUDIO_DEVICE_ADDED` e
   `SDL_EVENT_AUDIO_DEVICE_REMOVED` a um `somc_evento` novo (`nativo/som/som_controle.h`). Antes do primeiro
   `som_preparar` (`g_preparado` falso) ele não faz nada.
3. **A função pura.** Em `nativo/nucleo/achar_som.c` (e `.h`), uma reescolha que recebe a lista nova, o que cada
   lugar já tem (pelo nome do nó, não pelo índice) e o aparelho de cada lugar, e devolve só os lugares que ganham nó.
   Ela reusa `achar_para` e as mesmas três passadas de `escolher`, e não tira nó de quem já tem.
4. **Aplicar só no lugar.** `somc_evento` relista, chama a função e liga as saídas só dos lugares que ganharam nó;
   o registro diz «P3 · som: alto-falante <nome> (pelo aparelho, chegou depois)». O pio não toca de novo: quem volta
   não é quem entrou.
5. Juntar os eventos: vários nós chegam de uma vez (alto-falante, háptica, microfone); relistar uma vez por quadro,
   não uma por evento.

## Armadilhas

- **Relistar muda os índices.** `g_sc.nos` é reconstruída a cada `listar`, e as saídas abertas guardam o índice do
  nó (`SaidaCtl.no`, comparado em `abrir_no`, `nativo/som/som_controle.c:95-99`). Depois de relistar, remapear as
  saídas pelo `SDL_AudioDeviceID` (ou pelo nome), senão um lugar passa a tocar no controle de outro.
- **Não refazer a placa inteira.** Chamar `somc_preparar` no evento corta o pio e o som de todos (a armadilha medida
  da H07). A cura liga só o lugar que falta.
- **`listar` no Linux roda o `pactl`** (via `somc_plataforma_nos`) para achar o aparelho de cada nó: é um processo
  por chamada. Uma vez por quadro com evento, no máximo.
- **O nó de quem não está na mesa** não vai para ninguém (`nativo/som/som_controle.c:236-244`): a reescolha mantém
  essa regra.
- **Os arquivos da WS01 e da WS03.** As duas também mexem em `nativo/som/som_controle.c`: não voar junto com elas,
  ou voar no mesmo conjunto.
- **O simulado** tem placa virtual e não recebe evento de som: a prova do jogo não mede isto; a prova é a nativa e a
  bancada.

## Não fazer

- Não tirar o `_abrir_o_som(true)` da volta em `main.gd` nem trocar o `_caiu`: a volta pode chegar com o nó já
  presente, e aí ela basta.
- Não refazer a placa por tempo (a cada N segundos).
- Não mexer na escolha de quem já tem nó, nem na roda de troca do aviso (`somc_trocar`).

## Pronto quando

- Com o nó chegando depois do controle, o lugar ganha alto-falante, háptica e microfone sem outra mudança de
  controles, e os outros lugares não perdem nada.
- O registro mostra quando a lista mudou e quem ganhou o nó.

## Provas

- **Nativa** (`nativo/testes/prova_achar_som.c`): a lista sem o DualSense do lugar 2 (os lugares 1, 3 e 4 com os
  seus); a mesma lista com o nó do lugar 2 acrescentado no meio (os índices dos outros mudam). A reescolha dá o nó
  novo ao lugar 2 e mantém o nó dos outros pelo nome. Um nó novo de um controle fora da mesa não vai para ninguém.
  A mordida: tirar a regra «não tira de quem já tem» e ver a prova reprovar.
- `bash tests/prova_do_jogo.sh` segue verde (pelo semáforo, com a máquina livre).

## Para o André (local)

Com dois DualSense no cabo, numa sala de som e numa sala comum: tirar o cabo do P2, esperar o aviso, pôr de volta.
O P2 ouve a próxima nota no próprio controle, e no registro aparece «som: chegou …» e o alto-falante do P2 com o
nome do nó. Repetir umas cinco vezes: a ordem dos dois caminhos varia.

## Ao terminar

Marcar WN02 como **feito** no [quadro](README.md), com o número medido no passo 1, o commit e o gasto. Commit
sugerido: `fix(som): o lugar que volta ganha a placa quando ela chega, sem refazer a dos outros`.
