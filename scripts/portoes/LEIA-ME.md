# Os portões por script

Os portões são as conferências que nenhuma pessoa precisa lembrar de fazer: rodam no CI (o job `portoes` de
`.github/workflows/forja.yml`) e antes de cada commit, numa chamada só.

```
bash scripts/portoes/rodar.sh                 # todos
bash scripts/portoes/rodar.sh --so base       # só a base (ou --so arte, --so som)
bash scripts/ci-local.sh --portoes            # o mesmo, mais a prova dos portões
bash scripts/ci-local.sh --job portoes        # o job do CI inteiro, no contêiner
```

O `rodar.sh` sai 0 quando nenhum portão em modo reprova achou nada, 1 quando algum achou, e 2 quando um portão não
conseguiu conferir (um arquivo que não se leu, um intervalo do git que não existe): o 2 nunca conta como verde.

## O que cada um pega

| portão | modo | pega | script |
| --- | --- | --- | --- |
| **texto de tela** | reprova | a frase da tabela de traduções que começa com minúscula | `scripts/check_texto_de_tela.py` |
| **sem rastro** | reprova | termo interno, campo de modelo em ficha, trailer de coautoria, `AGENTS.md` no repositório | `tests/prova_sem_rastro.sh --so-varrer` |
| **mensagens de commit** | reprova | seta, símbolo de botão, marca de conferido, emoji ou trailer na mensagem dos commits novos | `mensagens_de_commit.py` |
| **teste mudo** | reprova | o Godot aberto pelo `xvfb-run` (foto, prova visual, estudo) sem `--audio-driver Dummy` nem `--write-movie`: o som do teste sairia na TV | `teste_mudo.py` |
| **ficha pronta** | reprova | ficha «pronta» no quadro sem uma das partes de `docs/jogo/o-time/ficha-pronta.md`, com parte vazia, ou com o «Ler antes» fora de um a três links que existem | `ficha_pronta.py` |
| **arte** | aviso | cor escrita fora de `tema.gd` (`Color("#…")`, `Color8`, `Color(0.x, …)`, `Color.WHITE`), cor do tema que a bíblia não tem, fonte fora das quatro da bíblia (no código e na pasta), texto abaixo de 30 px, cor de jogador fora do jogador ou pedida por índice fixo | `arte.py` + `arte.json` |
| **som** | aviso | id tocado que o mapa do áudio não tem (ou tem com outra caixa), id numa variável que não se lê, arquivo do mapa que não existe, WAV com duração fora da do mapa, pico acima do mapa ou do teto, clique no começo ou no fim | `som.py` + `som.json` |

As mensagens de commit conferem só os commits novos: num pull request, desde `origin/<base>`; num push, desde o
`github.event.before`; fora do CI, desde onde o ramo saiu do `main`. O histórico antigo não se reescreve.

## As regras moram em arquivo de dados

Os números da arte (os tokens, as cores dos jogadores, as fontes, o tamanho mínimo, as chamadas que levam tamanho) e
os do som (as chamadas que tocam, as colunas do mapa, as tolerâncias de duração, pico e clique) estão em
`arte.json` e `som.json`, e cada um diz de que documento veio. Quando a bíblia de arte ou o mapa do áudio mudar,
muda o `.json`, não o script.

## Virar a arte e o som para reprovar

Os dois entram em modo aviso: mostram os achados e não param o CI, porque hoje o código inteiro está fora da
bíblia. Para virar, troque `"modo": "aviso"` por `"modo": "reprova"` em `arte.json` e `som.json`. Nada muda no
`rodar.sh` nem no CI. Quando virar é a ficha
[V08](../../docs/jogo/tarefas/V08-os-portoes-de-arte-e-som-reprovam.md): com os avisos zerados.

Para ver a régua valendo sem virar: `python3 scripts/portoes/arte.py --modo reprova`.

## A prova

`bash tests/prova_dos_portoes.sh` monta, numa pasta temporária, cada defeito que um portão pega e confere que ele
reprova (e que o certo passa, e que o modo aviso não reprova). Portão novo entra com o caso dele nessa prova.
