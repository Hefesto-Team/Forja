# G02 — A construção do cavaleiro

**Sprint:** G · **Tamanho:** G · **Modelo:** Opus · **Estimativa:** US$ 4,0

## Por quê

Não há criação de personagem; a construção dá identidade, é o lobby e calibra o tempo de cada controle sem ninguém ver.

## Ler antes

- [A construção do cavaleiro](../06b-a-construcao-do-cavaleiro.md)
- [A calibração](../04-ritmo-e-audio.md#a-calibração-que-ninguém-vê)

## Arquivos que mudam

- `godot/scripts/ui/tela_lobby.gd`, `godot/scripts/ui/cartao_jogador.gd` (viram a tela nova)
- `godot/scripts/player.gd` (acabamento, peça, nome)
- `godot/scripts/main.gd:589-613`
- `godot/scripts/opcoes.gd` (guardar o cavaleiro e o desvio)

## Passos

1. Quatro bigornas lado a lado, uma por lugar, na cor do lugar.
2. Os passos: boneco, acabamento, peça, item, nome (sorteado da lista da forja ou teclado de tela).
3. As oito marteladas do fim forjam a armadura e medem o desvio de cada controle (a mediana); o desvio vai para as opções do lugar e para o registro (`calibracao`).
4. Quem volta na mesma noite pula a construção.
5. O seletor usa texto de 30 px ou mais, com ícone do item.

## Pronto quando

Quatro pessoas constroem os quatro cavaleiros em menos de dois minutos, e o registro mostra o desvio de cada controle.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** jogar a construção com quatro controles, dois no cabo e dois no rádio
