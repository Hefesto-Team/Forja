# WS — O mapa do som e da música

O som da Forja sai de três lugares: a TV (o Godot), o alto-falante de cada controle e os atuadores dele (a háptica
por áudio, o módulo). A música sai só na TV. A regra de cada som está na bíblia
([03 — O som](../arte/03-som.md)), e a lista do que existe, no [mapa do áudio](../audio/mapa.csv).

## Onde mora cada coisa

| Parte | Arquivo | O que faz |
| --- | --- | --- |
| Os sons da TV | `godot/scripts/som.gd` | `RECEITAS` (`:17`, os sintetizados) e `GRAVADOS` (`:42`, os WAV de `assets/sons`, com variações); 16 tocadores 3D e 4 tocadores 2D, todos no barramento mestre; `tocar` (`:112`), `laco` (`:141`), `no_controle` (`:156`, o mesmo som na TV e no alto-falante do lugar) e `jingle` (`:195`) |
| A música | `godot/scripts/musica.gd` | `FAIXAS` (`:11`, a trilha sintetizada de cada sala e seção) e `SALA_DA_SECAO` (`:31`); `tocar` com cruzamento de 0,8 s (`:76`); `tocar_do_zero` para o minigame (`:104`) e o `mapa` de batidas (`:130`); `TELAS` e as faixas geradas (`:176-243`, a H05); o barramento `Musica` e o `reagir` (`:256-303`, a H07) |
| O invólucro do módulo | `godot/scripts/forja.gd:834-961` | `som_preparar`, `som_falante`, `som_haptica`, `tocar_material`, `som_pronto` |
| A ponte nativa | `nativo/godot/forja_som.cpp` | os métodos de som do `ForjaControles`; `som_encerrar` (`:105-111`) |
| A placa de cada controle | `nativo/som/som_controle.c` | listar e escolher os nós de áudio, abrir uma saída por lugar, o fio que alimenta (`:55-65`), `somc_preparar` (`:299`), `somc_falante`, `somc_trocar` (`:318-352`) |
| O mixer | `nativo/som/mixer.c` | 48 vozes por saída (`MIX_MAX_VOZES`), roubo de voz (`:32-48`), limitador; o fim pela rampa de 20 ms (`nativo/som/rampa.c`) |
| Os sons do módulo | `nativo/som/sons_salas.c`, `nativo/som/sintese.c` | os nomes que o alto-falante e os atuadores tocam (`nota:k`, `pio:k`, `material:*`) e a síntese de tudo, a trilha inclusive (`sint_trilha`) |

## As provas

- `bash tests/prova_do_jogo.sh` (`godot/testes/prova_do_jogo.gd`): o pio de quem entra (`:159-169`), as faixas
  (`_prova_das_faixas`, `:1097-1121`), a música que reage (`:1548-1561`).
- `forja-testes` (`nativo/testes/prova_som.c`): só a rampa; o mixer e a placa não têm prova (WS05).
- `scripts/portoes/som.py`: os ids tocados existem no mapa e os WAV batem com ele; em aviso até a V08.

## As fichas que já cuidam da área

V04 (a faixa sintetizada no catálogo), V05 (o mapa do áudio), V07, V08 (os portões reprovam), P1 (A Voz e a reserva
`"sopro"`), N1 (O Canto e o abaixamento da pista), H05 (as faixas geradas), H07 (o som em todo evento).

## As fichas desta leva

| Ficha | O que conserta | Gravidade | Tamanho |
| --- | --- | --- | --- |
| [WS01](../tarefas/WS01-o-som-da-biblia-no-jogo.md) | a bíblia de som no jogo (a H11 que as fichas citam) | alta | G |
| [WS02](../tarefas/WS02-a-musica-dona-do-volume.md) | o volume da música com dono: camadas somadas, `abaixar`/`soltar` | média | M |
| [WS03](../tarefas/WS03-a-placa-do-controle-nao-fecha-a-toa.md) | a placa do controle reconcilia em vez de fechar tudo | média | M |
| [WS04](../tarefas/WS04-a-reserva-de-toda-secao.md) | a reserva sintetizada da S06 e da S08 | média | P |
| [WS05](../tarefas/WS05-o-mixer-rouba-pela-rampa.md) | o roubo de voz pela rampa, e a prova do mixer | baixa | P |
| [WS06](../tarefas/WS06-o-mapa-diz-onde-o-som-toca.md) | o `onde_toca` e o `estado` do mapa, conferidos pelo portão | baixa | P |
| [WS07](../tarefas/WS07-a-reserva-pronta-antes-do-jogo.md) | a trilha da seção sintetizada antes do apito | baixa | P |

A ordem que funciona: WS05 a qualquer hora (só o nativo); WS04 e WS07 uma depois da outra (as duas na `musica.gd`);
WS02 e WS03 antes da WS01, que usa as duas; WS06 depois da V08.
