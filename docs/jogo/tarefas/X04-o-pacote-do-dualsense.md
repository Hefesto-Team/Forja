# X04 — O pacote do DualSense

**Sprint:** X · **Tamanho:** G · **Depende de:** F04, F05, F06, F10, X01

## Por quê

Quatro DualSense com háptica, gatilho, luz, alto-falante e microfone, num jogo de Godot, é o que mais vale fora do Forja, e hoje está preso a um autoload de 923 linhas que também é o diagnóstico do jogo.

## Ler antes

- [15 — O controle e a háptica do DualSense](../15-os-modulos.md#4-o-controle-e-a-háptica-do-dualsense--forja_dualsense)
- [13 — As sensações](../13-arquitetura.md#as-sensações--f05)

## O estado de hoje

- `godot/scripts/forja.gd` (923 linhas) junta o teclado (`:229`), os lugares (`:293`), a entrada (`:353`), as saídas
  (`:449`), o relatório (`:514`), as medidas (`:587`), A Prova (`:658`), as cegas (`:692`), o som de cada controle
  (`:731`), a bancada (`:823`) e o robô (`:877`); `aplicar_opcoes` (`:131`) lê `Opcoes`, `Tema` e `Traducoes`.
- O nativo: `godot/forja.gdextension` (entrada `forja_iniciar_biblioteca`, libs em `res://bin/`), `ForjaControles`
  com 123 métodos (`nativo/godot/forja_controles.cpp:593`); compilado por `scripts/compilar.sh`.

## Arquivos que mudam

- `godot/addons/forja_dualsense/` (novo): `forja_dualsense.gdextension`, `bin/` (as libs), `controle.gd` (autoload
  `ForjaControle`), o resto do pacote
- `godot/forja.gdextension` (sai), `godot/bin/` (as libs mudam de pasta)
- `godot/scripts/forja.gd` (fica com o relatório, as medidas, A Prova, as cegas, a bancada e os argumentos, chamando o
  `ForjaControle`)
- `godot/scripts/som.gd`, `godot/scripts/musica.gd` (o `ctl.sintetizar_pcm16` e o `ctl.som_registrar`)
- `scripts/compilar.sh`, `scripts/exportar.sh`, `.github/workflows/forja.yml` (o caminho das libs e dos artefatos)
- `godot/project.godot`, `.gitignore` (o `bin/` novo)

## Passos

1. Mover o `.gdextension` e as libs para o pacote, ajustar `compilar.sh`, `exportar.sh` e o CI; a prova de fogo exportada passa antes de seguir.
2. Escrever `controle.gd` com as seções lugares, entrada, saídas e som de cada controle, copiadas de `forja.gd`; `Forja` passa a delegar.
3. As chamadas `Forja.apertou/eixo/vibrar/...` no jogo trocam para `ForjaControle.` por script, uma seção por commit.
4. `aplicar_opcoes` vira o jogo entregando `cores` e a escala da vibração.
5. A prova do pacote: quatro controles simulados, um aperto e uma vibração pedida aparecem no estado da saída, sem o Forja.

## Não fazer

- Mudar comportamento: extrair é mudar de lugar e cortar dependência. O que parecer errado vira ficha.
- Deixar o pacote chamar `Forja`, `Tema`, `Som` ou `Musica`: o que o pacote precisa do jogo entra por variável,
  sinal ou `Callable`.

## Pronto quando

`bash tests/prova_do_importavel.sh forja_dualsense` passa, `forja.gd` tem menos de 500 linhas, e a prova da exportação passa no binário Linux e no .exe.

## Provas

- `bash tests/prova_do_importavel.sh forja_dualsense`
- `bash tests/prova_do_jogo.sh` e `bash tests/prova_de_poucos.sh`
- `bash tests/prova_da_exportacao.sh` (pelo semáforo)
