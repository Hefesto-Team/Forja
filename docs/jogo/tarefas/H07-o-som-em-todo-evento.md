# H07 — O som em todo evento

**Sprint:** H · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 3,5

## Por quê

O alto-falante do controle quase não toca, e há evento sem som; todo evento tem som na TV e algo no controle do dono.

## Ler antes

- [A agenda do alto-falante](../05-haptica-e-controle.md#a-agenda-do-alto-falante)
- [A háptica por material](../05-haptica-e-controle.md#a-háptica-por-material)
- [A música que reage](../04-ritmo-e-audio.md#a-música-que-reage)

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd:94`, `godot/scripts/salas/prova.gd:109`, `godot/scripts/main.gd:436` (`som_preparar`)
- `nativo/som/sintese.c`, `nativo/som/mixer.c`
- `godot/scripts/som.gd`, `godot/scripts/musica.gd`

## Passos

1. Abrir a placa de áudio de cada controle na entrada do lugar e mantê-la aberta.
2. O pio de cada boneco, e a agenda do alto-falante de 05.
3. A tabela de materiais hápticos no módulo, com a mesma onda no atuador e, mais baixa, no alto-falante.
4. As rampas de 15 a 30 ms no mixer.
5. A música que reage: filtro no erro, brilho no combo, abaixa 2 dB no perfeito.
6. Cada som mandado vai para o registro (`som_controle`).

## Pronto quando

Numa partida de cinco, todo acerto, erro, golpe e coleta tem som na TV e algo no controle do dono, e o registro mostra cada som mandado.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh` e `scripts/compilar.sh testes`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`; ouvir e sentir no cabo
