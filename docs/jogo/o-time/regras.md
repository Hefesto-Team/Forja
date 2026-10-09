# As regras de execução

Quem pega uma ficha lê a ficha, os links do «Ler antes» dela e este arquivo, inteiro. São as regras que a casa já
pratica, postas num lugar só; a lei do repositório segue no [COMO-CONTRIBUIR](../../COMO-CONTRIBUIR.md#as-regras-da-casa)
e o contrato do controle no [CONTRATO](../../../CONTRATO.md).

## Os princípios

- **A cura vai à origem e cobre todos os chamadores.** Consertar só onde o defeito apareceu deixa o vizinho com o
  mesmo defeito; a gambiarra nunca é o padrão.
- **Medir antes de mudar.** A ficha diz o estado de hoje com o número; quem a faz mede de novo antes de curar, e a
  ficha cujo defeito já sumiu diz isso com a medida e não muda nada.
- **A régua morde.** Toda prova nova reprova com o defeito dentro: arrancar a cura, ver reprovar, devolver. Régua que
  passa com o defeito não mede nada.
- **Um a quatro jogadores, cabo e rádio.** O que vale para o P1 no cabo vale para os quatro no rádio, ou a ficha diz
  por que não.
- **Exatamente o pedido.** Sem refatorar o vizinho e sem frente nova; o que se viu no caminho vira ficha nova no
  [quadro](../tarefas/README.md), não escopo da ficha de agora.
- **A ficha que cresceu demais vira duas:** faz-se o núcleo que o «Pronto quando» pede e escreve-se a segunda.
- **A decisão aberta não se toma calada.** Decide-se pelo que custa menos a quem joga e, na dúvida, pelo mais
  reversível; escreve-se no relato como «a validar por ela», e a linha vai para o [ESPERA-ELA](ESPERA-ELA.md).
  Nenhuma frase diz que uma decisão foi aprovada sem a fonte escrita.
- **O texto de tela** segue a voz das telas e os portões de `scripts/portoes/` (cor só por token do tema, as fontes
  da bíblia, som só pelo id do [mapa do áudio](o-mapa-do-audio.md)): o portão diz o que reprova.
- **O que só a mão prova** (a vibração, o som no controle, a graça) vira código, régua e uma linha para quem joga:
  o gesto, o que deve acontecer e onde olhar.

## Nunca

- **Escrever no controle de quem está jogando**, nem no servidor de som da máquina: as provas rodam na caixa, com
  o simulador ([a esteira, «Os limites»](a-esteira.md#os-limites)).
- **Abrir janela na tela de quem usa a máquina:** o Godot só com `--headless` ou dentro de `xvfb-run`.
- **`sudo`, `apt` ou `pip` global:** o que o projeto precisa mora dentro dele ([F00](../tarefas/F00-o-ambiente-da-sessao.md)).
- **`git add -A`**: o commit leva só os caminhos que a ficha mudou, e nada que outra pessoa deixou na árvore.
- **`--no-verify`**: o gancho que reprovou está certo até prova em contrário.
- **`push`, `merge`, `rebase` ou `reset --hard` no lugar de outra pessoa:** a integração e o `main` são de quem
  coordena; a costura é o `scripts/costura.sh`.
- **Matar processo pelo nome:** só pelo número, conferido antes.
- **Nome de ferramenta, de modelo ou trailer** em arquivo versionado ou em commit (`bash tests/prova_sem_rastro.sh`).
- **Caminho de uma máquina** no código, nos documentos ou no registro.

## O commit

- **A cada passo que funciona**, não um no fim do dia.
- **Por caminho:** `git add <arquivos>`, conferido com `git status` antes.
- **Em português, com acento:** `tipo(escopo): descrição`, dizendo o que mudou e por quê.
- **Sem trailer, sem assinatura e sem símbolo de botão ou de seta:** escreve-se «cruz», «círculo», «direita».
- **Antes do commit,** `bash scripts/portoes/rodar.sh`; antes do grande, `bash tests/prova_sem_rastro.sh`; antes
  do push, `bash tests/prova_do_jogo.sh` verde.
