# F02 — Nenhuma frase metalinguística

**Sprint:** F · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,0

## Por quê

O jogo manda "olhe o controle" e pergunta se o som saiu do controle; o jogador deve ler só verbos do mundo.

## Ler antes

- [Regras de ouro](../README.md#as-regras-de-ouro)
- [A voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto)

## Arquivos que mudam

- `godot/scripts/salas/voz.gd:59,617`
- `godot/scripts/salas/prova.gd:802`
- o aviso de cada sala em `godot/scripts/salas/sala_jogo.gd` (a lista de features)
- `godot/scripts/mundo/salao.gd:16-23` (o subtítulo dos portões)
- `godot/scripts/ui/tela_titulo.gd:39-40,71`
- `godot/scripts/ui/cartao_jogador.gd:71-87`
- `godot/scripts/traducoes.gd`

## Passos

1. Listar toda frase de tela que nomeia recurso do controle, pede para olhar o controle ou fala de relatório, módulo, VID:PID.
2. Trocar cada uma pelo verbo do mundo da sala (a `acao` d'A Voz vira algo como "Acorde o guardião").
3. O aviso da sala mostra o verbo e o ícone da parte do controle, não a lista de features.
4. O portão do salão mostra o nome da seção.
5. O rodapé do título e o cartão do lobby perdem "relatórios", "módulo nativo" e VID:PID (vão para o registro).
6. Atualizar `traducoes.gd` para cada frase nova.

## Pronto quando

Uma busca por "olhe", "controle", "relatório", "vibração", "giroscópio" e "háptica" nas frases de tela (fora do Modo bancada) não acha nada.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** jogar o título, o lobby e duas salas
