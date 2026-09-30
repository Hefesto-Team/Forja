# F07 — A voz nova do texto

**Sprint:** F · **Tamanho:** M · **Estimativa:** US$ 2,5

## Por quê

Botões e rótulos começam com minúscula; a regra agora é toda frase de tela com maiúscula e botão como "Botão ✕ (Iniciar)".

## Ler antes

- [A voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto)

## Arquivos que mudam

- `godot/scripts/traducoes.gd` (as 233 frases e os padrões)
- os textos montados com `%` em `godot/scripts/ui/*.gd` e `godot/scripts/salas/*.gd`
- `godot/scripts/ui/diagnostico.gd:57`, `godot/scripts/ui/livro.gd:150` ("fechar")
- `scripts/check_texto_de_tela.py` (novo)
- `tests/prova_do_jogo.sh` (chamar o portão)

## Passos

1. Escrever o portão `scripts/check_texto_de_tela.py`: lê as chaves de `traducoes.gd` e reprova frase que comece com minúscula.
2. Virar as 143 frases e os padrões; a tradução em inglês segue a mesma regra.
3. As dicas de botão passam a "Botão ✕ (Iniciar)"; em fileira, "Botão" só na primeira.
4. "fechar" ganha tradução.
5. Ligar o portão na prova do jogo.

## Pronto quando

O portão passa, e as fotos do título, do lobby, do fim de sala e do pódio não mostram texto começando com minúscula.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `tests/telas.sh` nas duas línguas
