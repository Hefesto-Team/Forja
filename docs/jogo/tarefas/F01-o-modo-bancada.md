# F01 — O Modo bancada

**Sprint:** F · **Tamanho:** G · **Modelo:** Opus · **Estimativa:** US$ 3,5

## Por quê

O veredito, o quiz das salas às cegas, o diagnóstico e o livro da sessão são ferramenta de validação, não jogo; hoje estão na cara do jogador.

## Ler antes

- [O diagnóstico — o jogo parece um teste](../01-diagnostico.md#o-jogo-parece-um-teste)
- [Princípio 1](../02-principios.md#1-o-controle-é-mundo-não-prova)

## Arquivos que mudam

- `godot/scripts/forja.gd` (o argumento `--bancada`)
- `godot/scripts/main.gd` (o estado da sala, a pausa, o Create)
- `godot/scripts/ui/painel_sala.gd:356-415` (a tabela de veredito)
- `godot/scripts/salas/sala_jogo.gd` (`pergunta()`, os vereditos)
- `godot/scripts/ui/hud.gd:87`, `godot/scripts/ui/pausa.gd`
- `docs/DESENVOLVER.md` (o argumento novo)

## Passos

1. Criar a flag `Forja.bancada`, ligada por `--bancada` (e mantida pelos argumentos que já são de bancada: `--experimento`, `--prova-de-fogo`).
2. Sem a flag: a tela de fim da sala não desenha a tabela de veredito; `pergunta()` não é chamada; o Create não abre o diagnóstico; a pausa não mostra o livro.
3. Com a flag: tudo como hoje.
4. Os vereditos continuam sendo calculados e gravados no relatório e na linha do tempo nos dois modos.
5. As provas sem aparelho que dependem das perguntas (`godot/testes/prova_do_jogo.gd`) passam a rodar com `--bancada`.
6. Documentar `--bancada` em `docs/DESENVOLVER.md` e em `AGENTS.md`.

## Pronto quando

Uma partida de nove salas sem `--bancada` vai do título ao pódio sem uma pergunta sobre o controle e sem tabela de veredito, e o relatório da sessão sai igual ao de hoje.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`; jogar uma partida de 5 salas sem a flag
