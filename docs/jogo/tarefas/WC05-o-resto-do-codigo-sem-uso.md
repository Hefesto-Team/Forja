# WC05 — O resto do código sem uso do núcleo

**Sprint:** W · **Tamanho:** P · **Depende de:** G14 (a parte do `tema.gd`: a G14 reescreve o tema); vai antes da
X04 (a parte do `forja.gd`). Completa a [V07](V07-o-codigo-sem-uso.md), que fica com o alto-falante e o
`quem_apertou`.

## Por quê

A tela passou a desenhar tudo pelo `Desenho`, o relatório e o som mudaram de dono, e as camadas antigas ficaram. A
V07 listou parte delas. O resto engana quem lê (um `Theme` com onze variantes que nenhum nó usa, um `hp` que ninguém
lê) e vai de carona para os pacotes da X: a X04 copia as seções do `forja.gd` para o `ForjaControle`, e envelope sem
chamada vira API pública de um pacote. E a G14, que repinta o tema, gastaria trabalho alinhando o `Theme` morto.

## Ler antes

- [V07 — O código sem uso](V07-o-codigo-sem-uso.md) (a mesma régua: o que só tem a própria definição sai)
- [X04 — O pacote do DualSense](X04-o-pacote-do-dualsense.md) e [G14 — A cor e a letra da Fita](G14-a-cor-e-a-letra-da-fita.md)

## O estado de hoje (medido em 09/10/2026, `git grep -nw <nome> -- godot tests scripts`)

- Seis envelopes do `godot/scripts/forja.gd` sem chamada nenhuma (o `git grep` acha só a definição):
  - `:651` `controle_do_relatorio(l)`
  - `:679` `registro_recente(n)`
  - `:750` `med_estado(l)`
  - `:784` `carga_estado(l)`
  - `:851` `som_encerrar()` (a [H07](H07-o-som-em-todo-evento.md) tirou as chamadas de propósito: devolvê-lo ao
    pódio reprovou «○ no pódio, a placa continua aberta»)
  - `:874` `som_plataforma()`
- `godot/scripts/player.gd:42-43`: `var hp := 100.0` não tem leitor; `var cooldown := 0.0` só é descontado
  (`:212-213`) e nunca recebe valor.
- `godot/scripts/tema.gd:91` `tema()`, com o `_variante` (`:117`), o `quadro` (`:125`) e o `rotulo` (`:184`): o
  único consumidor é `godot/scripts/main.gd:114`, `ui.theme = Tema.tema()`, e não há `Label`, `Panel` nem outro
  `Control` com texto debaixo da `ui` (toda letra sai pelo `Desenho`, com a fonte passada na mão). O `rotulo` não tem
  chamada; o `quadro` só é usado pelo `tema()`. O `escala_texto` das opções nem chega até essas variantes.
- `godot/scripts/main.gd:849`: `get_tree().paused = false` no fim do `_abrir_overlay`, e nada no jogo põe a árvore em
  pausa (a pausa é do `Ritmo` e de cada sala).

O `soltou` do `forja.gd` também não tem chamada hoje, mas fica: a M4, a K2 e a K4 vão usar.

## O alvo

O `git grep -w` de cada nome acima não acha nada em `godot/`, e o jogo desenha e soa igual.

## Arquivos que mudam

- `godot/scripts/forja.gd` (só as seis funções)
- `godot/scripts/player.gd` (as duas variáveis e o desconto do `cooldown`)
- `godot/scripts/tema.gd` (o `tema()`, o `_variante`, o `quadro`, o `rotulo` e o `_tema`)
- `godot/scripts/main.gd` (as linhas `:114` e `:849`)

## Passos

1. Depois da G14, `git grep -nw` de cada nome em `godot/`, `tests/` e `scripts/`. O que ganhou chamada fica, e a
   ficha diz qual e onde.
2. Apagar os seis envelopes. Os métodos do módulo por trás deles ficam (a X04 decide o que o pacote expõe).
3. Apagar o `hp`, o `cooldown` e o desconto.
4. Apagar o `Theme` e a linha que o atribui à `ui`.
5. Apagar o `paused = false`.

## Armadilhas

- O `project.godot` tem o próprio `gui/theme/custom_font` (`:42`), que a G14 e a V08 trocam: esse fica. É ele, e
  não o `Tema.tema()`, que vale para algum `Control` que nasça sem fonte.
- Se a G04 ou a G11 trouxerem `Control` com texto (o `Visor` da G04 é `extends Control`), conferir antes se elas
  contam com o `Theme`: se contarem, o `Theme` fica e a ficha diz por quê.
- O `med_estado` e o `carga_estado` podem ser o que a bancada ou o diagnóstico querem mostrar amanhã: se alguma ficha
  em voo os cita, ficam.

## Não fazer

- Não mexer no alto-falante nem no `quem_apertou`: são da V07.
- Não apagar método do módulo nativo aqui.

## Pronto quando

O `git grep -nw` de cada nome da lista acha só o que tem chamada, e as provas passam iguais.

## Provas

- `bash tests/prova_do_jogo.sh` e `bash tests/prova_de_poucos.sh`.
- `bash tests/prova_visual.sh` pelo semáforo (o `Theme` saiu: as telas iguais).

## Para o André (local)

Nada.

## Ao terminar

Marcar WC05 como **feito** no [quadro](README.md), com o gasto.
