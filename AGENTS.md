# FORJA — lei do repo

Leia [CONTRATO.md](CONTRATO.md) antes de qualquer patch. Se o patch quebra uma linha de lá, o patch está errado.

- Jogo de 4 jogadores **local**. Sem online.
- DualSense como a Sony e a Steam documentam: USB relatório `0x02`.
- Gatilho só: Off, Feedback, Weapon, Vibration.
- Proibido: socket Hefesto, uniq/MAC, relatório Bluetooth `0x31`, CRC `0xA2`, DSX.
- `forja-send` recusa DualSense no rádio.
- Player index 0..3, nunca endereço físico.
- Rodar local: `./run-local.sh`.

## As regras da casa

- Português do Brasil, com acento, em tudo: código, telas, documentação e commits (`feat:`, `fix:`, `docs:`).
- Nenhuma assinatura de ferramenta em commit, código ou documentação: commit sem trailer (nada de `Co-Authored-By`).
- Nada que dependa da máquina de alguém: nenhum caminho fixo e nenhum endereço de aparelho no código, no registro ou no relatório. Endereço que aparecer sai com os octetos 4 e 5 zerados.
- O SDK oficial da Sony é sob NDA: não se usa, não se procura, não se reproduz.
- A voz das telas é a do app Hefesto ([estudo 03](docs/estudos/03-o-sistema-visual-do-app-hefesto.md)): maiúscula só na primeira letra da frase; nunca na tela: "mesa", "uinput", "hidraw", "MAC".
- Trabalho novo começa por um item do backlog do [SPRINTS.md](SPRINTS.md) (*O que falta para um jogo completo*).

## Os comandos

- Jogar do código: `./run-local.sh`; os argumentos do jogo vêm depois de `--` (`--simular=4 --robo`, `--sala=ID`, `--prova-de-fogo`, `--partida=5 --sorteada`, `--semente=N`, `--experimento=ID`).
- O módulo nativo: `scripts/compilar.sh linux|windows|testes`. Não recompile com um Godot rodando o jogo: ele segura o `.so`.
- Antes de todo push: `bash tests/prova_do_jogo.sh`. Mexeu numa sala ou no módulo: `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` também (uns 10 minutos e 1 minuto). A bancada: `bash tests/prova_da_bancada.sh`.
- A exportação: `scripts/exportar.sh tudo && bash tests/prova_da_exportacao.sh` (o `.exe` roda pelo Wine).
- As fotos das telas: `godot/testes/captura_jogo.gd` (o cabeçalho diz como), sempre com `--fixed-fps 60`.
