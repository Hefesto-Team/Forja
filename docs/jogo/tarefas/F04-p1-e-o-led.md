# F04 — O P1 da tela é o controle P1

**Sprint:** F · **Tamanho:** M · **Estimativa:** US$ 3,0

## Por quê

Na noite de teste o P1 da tela não era o controle com o LED de P1; a identidade tem que valer desde a conexão.

## Ler antes

- [A identidade P1..P4](../05-haptica-e-controle.md#a-identidade-p1p4)
- [O CONTRATO — identidade](../../../CONTRATO.md)

## Arquivos que mudam

- `nativo/nucleo/pads.c` (`conectou()` ~200-325, `pads_entrar()` 506-570, a regra de 537-540)
- `godot/scripts/forja.gd` (`entrar`, `LEDS_DO_LUGAR`)
- `godot/scripts/main.gd:589-613`
- `godot/scripts/salas/galeria.gd:201`, `godot/scripts/salas/prova.gd:227,264,557,574`, `impacto.gd:186`, `voz.gd:290`

## Passos

1. Na conexão, o controle recebe o primeiro lugar livre, o player index, as luzinhas e a cor do lugar.
2. O ✕ do lobby confirma o lugar; não escolhe.
3. Controle que volta com a mesma assinatura recupera o lugar; controle estranho não herda o lugar de quem caiu.
4. Segurar ◻ por um segundo na construção passa o lugar para o próximo livre.
5. Nenhuma sala usa as luzinhas de jogador como munição ou pergunta, nem a barra de luz como cor de equipe (a cor de equipe vai para o chão e a armadura).
6. Teste no simulador de controles: conectar na ordem 2, 1, 3 e conferir lugar, luzinhas e cor.

## Pronto quando

Ligando quatro controles em qualquer ordem, o número da tela é o das luzinhas de cada controle antes de qualquer botão, e continua sendo dentro de todas as salas.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh` e `scripts/compilar.sh testes`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`; ligar quatro DualSense em ordem trocada
