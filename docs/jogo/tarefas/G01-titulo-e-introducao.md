# G01 — O título e a introdução

**Sprint:** G · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5

## Por quê

O jogo começa num título pobre e cai direto no lobby; precisa de um começo que apresente o mundo.

## Ler antes

- [As telas](../06-telas-e-fluxo.md#as-telas)
- [O mundo](../07-narrativa-e-voz.md#o-mundo)

## Arquivos que mudam

- `godot/scripts/ui/tela_titulo.gd`
- `godot/scripts/main.gd` (o estado `titulo` e um estado `intro`)
- `godot/scripts/musica.gd` (a faixa do título)

## Passos

1. O título mostra o logo e a forja acendendo no ritmo da faixa, e "Botão ✕ (Começar)".
2. Na primeira vez da noite, a introdução: 20 a 30 segundos sem texto — a Dissonância apagando a forja, quatro armaduras vazias acendendo; qualquer botão pula.
3. Cada controle que aperta um botão no título solta o pio do cavaleiro no próprio alto-falante.
4. Sem controle, a tela diz só "Nenhum controle encontrado" e oferece "Botão Enter (Jogar no teclado)".

## Pronto quando

Alguém que nunca viu o jogo liga, vê a introdução, e chega à construção do cavaleiro sem ler uma frase além do título.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** as fotos do título e da introdução
