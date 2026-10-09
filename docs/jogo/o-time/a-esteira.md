# A esteira

O motor que move as fichas sem ninguém empurrar. É um despachante feito pelo arquiteto e DevOps, que roda na
máquina de quem coordena, lê o [quadro](../tarefas/README.md) e despacha o próximo trabalho. A configuração dele
é de cada máquina e fica fora do repositório; o que ele segue é este documento.

## Os estados de uma ficha

```
a fazer → enriquecida → pronta → em voo → conferida → jogada → feito
```

- **a fazer:** escrita antes da direção.
- **enriquecida:** o roteirista reescreveu no molde de [A ficha pronta](ficha-pronta.md).
- **pronta:** o revisor aprovou.
- **em voo:** a execução pegou (com o nome do conjunto).
- **conferida:** o conferente corrigiu e as provas passaram na worktree.
- **jogada:** o jogador do time jogou e a diversão aconteceu.
- **feito:** costurada na integração, com o commit.

As bases (F, H, DevOps, direção, pesquisa, RPG) vão de **a fazer** direto para **em voo**: são fundação e não esperam
enriquecimento.

## O que a esteira faz a cada volta

Os passos 1 a 3 são o `scripts/esteira.py` (diz em JSON o que sai, o que está em voo, o que espera ela e o que segura
cada seção); o passo 5 é o `scripts/costura.sh` (cherry-pick na integração, os portões de `scripts/portoes/` e as
provas, parando no conflito e no primeiro vermelho). A prova dos dois é o `tests/prova_da_esteira.sh`.

1. Lê o quadro e o [ESPERA-ELA](ESPERA-ELA.md).
2. Acha as seções em que todas as fichas estão **prontas** e todas as dependências estão **feito**.
3. Monta o conjunto da seção: uma worktree, as fichas na ordem, e confere que nenhum outro conjunto em voo mexe nos
   mesmos arquivos.
4. Despacha: implementador, conferente, jogador.
5. Quando volta: a costura por script, os portões, as provas, o quadro, o push com tudo verde.
6. Avisa no celular dela: a seção está pronta para jogar.
7. Volta ao passo 1.

## Os limites

- **Conjuntos juntos:** até quatro, com arquivos disjuntos. O semáforo da máquina
  (`vez-do-pytest.sh`) segue valendo: as provas fazem fila.
- **A placa de vídeo:** a música só gera quando a placa está livre, nunca junto com a prova visual.
- **Nada na tela dela:** Godot só por `--headless` ou `xvfb-run`.
- **O controle real:** nunca. As provas rodam na caixa (`bwrap`) com o simulador.
- **O commit:** em português, sem trailer e sem símbolos na mensagem.
- **As regras:** cada papel recebe o [regras.md](regras.md), inteiro, pelo link, não colado.

## Quando a esteira para

- Uma prova falha duas vezes seguidas na mesma ficha: a ficha volta para **enriquecida**, com o motivo, e a esteira
  segue com outra seção.
- Uma decisão que só ela toma: a linha vai para o [ESPERA-ELA](ESPERA-ELA.md), com o aviso no celular, e a esteira
  segue com o que não depende dela.
- A cota da semana: a cada seção fechada, a esteira registra o gasto no ANDAMENTO; quem coordena pergunta a ela a % e
  ajusta o ritmo.
