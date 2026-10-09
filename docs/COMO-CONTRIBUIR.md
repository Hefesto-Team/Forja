# Como contribuir com o Forja

A lei do repositório, para quem vai mexer: as regras, os comandos e o que
nunca entra. Leia o [CONTRATO.md](../CONTRATO.md) antes de qualquer patch:
se o patch quebra uma linha de lá, o patch está errado.

## O que o jogo é, e o que ele nunca faz

- Jogo de quatro jogadores **local**. Sem online.
- O DualSense, como a Sony e a Steam documentam: USB, relatório `0x02`.
- Gatilho só nos quatro modos: Off, Feedback, Weapon e Vibration.
- Proibido: o socket do Hefesto, `uniq` e MAC, o relatório Bluetooth `0x31`, o
  CRC `0xA2` e o DSX.
- `forja-send` recusa DualSense no rádio.
- O jogador é o índice 0 a 3, nunca o endereço físico do aparelho.

## As regras da casa

Cada uma nasceu de um defeito real.

- **Português do Brasil, com acento, em tudo:** código, telas, documentação e
  commits (`feat:`, `fix:`, `docs:`).
- **O autor do commit é quem o escreveu, e só.** A mensagem diz o que mudou e
  por quê, sem trailer de coautoria e sem assinatura. A prova que guarda isto
  é `bash tests/prova_sem_rastro.sh`: ela roda a cada push e se prova
  sozinha, com defeitos de mentira que ela tem de reprovar.
- **Nada que dependa da máquina de alguém:** nenhum caminho fixo e nenhum
  endereço de aparelho no código, no registro ou no relatório. Endereço que
  aparecer sai com os octetos 4 e 5 zerados.
- **O SDK oficial da Sony é sob NDA:** não se usa, não se procura, não se
  reproduz.
- **A voz das telas** é a do app Hefesto
  ([estudo 03](estudos/03-o-sistema-visual-do-app-hefesto.md)), com a regra de
  30/09 ([docs/jogo/06](jogo/06-telas-e-fluxo.md#a-voz-do-texto)): todo texto de
  tela começa com maiúscula, e botão se escreve "Botão ✕ (Iniciar)". Nunca na
  tela: "mesa", "uinput", "hidraw", "MAC".
- **O jogo não é teste:** nenhuma pergunta sobre o controle, nenhum veredito,
  nenhum "olhe o LED" na tela do jogador. A validação vai para o registro e
  para o Modo bancada ([docs/jogo](jogo/README.md#as-regras-de-ouro)).
- **Trabalho novo é uma ficha do [quadro](jogo/tarefas/README.md):** uma sessão
  por ficha, lendo só a ficha e o que ela cita, e o estado dela no quadro
  atualizado no mesmo commit ([os estados](jogo/o-time/a-esteira.md#os-estados-de-uma-ficha),
  [como trabalhar](jogo/12-como-trabalhar.md)). O mapa das sprints está
  no [SPRINTS.md](../SPRINTS.md).
- Os documentos têm um mapa: [docs/README.md](README.md). Compilar, exportar e
  provar: [docs/DESENVOLVER.md](DESENVOLVER.md).
- As regras de execução: [jogo/o-time/regras.md](jogo/o-time/regras.md).

## Os comandos

- **Jogar do código:** `./run-local.sh`; os argumentos do jogo vêm depois de
  `--` (`--simular=4 --robo`, `--sala=ID`, `--prova-de-fogo`,
  `--partida=5 --sorteada`, `--semente=N`, `--experimento=ID`, `--bancada`:
  as perguntas, o veredito, o diagnóstico e o livro; sem ele, o jogo é só o jogo).
- **O módulo nativo:** `scripts/compilar.sh linux|windows|testes`. Não
  recompile com um Godot rodando o jogo: ele segura o `.so`.
- **Antes de todo push:** `bash tests/prova_do_jogo.sh`. Mexeu numa sala ou no
  módulo: `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh` também (uns
  10 minutos e 1 minuto). A bancada: `bash tests/prova_da_bancada.sh`.
- **A exportação:** `scripts/exportar.sh tudo && bash tests/prova_da_exportacao.sh`
  (o `.exe` roda pelo Wine).
- **A prova visual:** `bash tests/prova_visual.sh <pasta>` (quatro partidas do
  título ao pódio, a prancha de cada uma e as checagens de todos os quadros);
  `PASSADAS=fixa` na sessão; na máquina com placa de vídeo, `NA_TELA=1` (a
  janela abre na tela) e as duas passadas.
  Ficha de tela, arte, câmera, HUD ou minigame só fecha com a prancha olhada.
- **As fotos das telas** (de divulgação): `godot/testes/captura_jogo.gd` (o cabeçalho diz como),
  sempre com `--fixed-fps 60`.
