# F03 — Todo minigame fecha

**Sprint:** F · **Tamanho:** M · **Modelo:** Opus · **Estimativa:** US$ 3,0

## Por quê

Tem sala que acaba num relógio parado ou numa tela sem vencedor; todo fim precisa de apito, resultado e volta.

## Ler antes

- [Princípio 7](../02-principios.md#7-todo-minigame-fecha)
- [As telas](../06-telas-e-fluxo.md#as-telas)

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd` (`terminar`, `_quadro_fim`, linhas 216-246 e 426-427)
- `godot/scripts/ui/painel_sala.gd`
- `godot/scripts/salas/bancada.gd`
- `godot/scripts/main.gd` (`_ao_terminar_a_sala`)

## Passos

1. A tela de fim ganha a colocação dos quatro e o vencedor em destaque, dentro e fora de partida.
2. Sequência fixa: apito (a música para), resultado, volta; avança sozinha em seis segundos, e Botão ✕ (Continuar) pula.
3. O relógio não volta a encher depois do treino: o treino tem o seu próprio relógio.
4. O aviso começa sozinho em oito segundos, ou antes se todos apertarem; lugar vazio não segura.
5. A bancada emite `terminou` quando o último experimento acaba.
6. Um teste sem janela confere que toda sala emite `terminou` e mostra um vencedor com `--robo`.

## Pronto quando

Com `--simular=4 --robo --prova-de-fogo`, as nove salas terminam sozinhas, cada uma com um vencedor na tela, e o relógio nunca sobe.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`
