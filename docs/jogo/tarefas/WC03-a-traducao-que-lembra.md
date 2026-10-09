# WC03 — A tradução que lembra

**Sprint:** W · **Tamanho:** P · **Depende de:** V03 (que reparte a tabela e vai sozinha no `traducoes.gd`); vai
antes da X01, ou entra no `traducao.gd` do pacote se a X01 já tiver entrado

## Por quê

Com o jogo em inglês, toda frase que não está na tabela exata (o placar com número, «P2 · 14 pts», «3 salas», as
respostas das cegas) passa pelas 69 expressões do `EN_PADROES` de novo a cada desenho. A HUD, o placar e o lobby
redesenham a cada quadro: são alguns milissegundos por quadro gastos traduzindo a mesma frase que já foi traduzida no
quadro anterior. Em português o custo é zero; em inglês, ele come o quadro que o ritmo precisa (ver a
[WC01](WC01-o-toque-no-instante-do-aperto.md): quadro longo é toque escorregado).

## Ler antes

- [V03 — O texto de tela inteiro](V03-o-texto-de-tela-inteiro.md) (o motor e as tabelas em partes)
- [X01 — O pacote do texto de tela](X01-o-pacote-do-texto.md)

## O estado de hoje (medido em 09/10/2026)

- `godot/scripts/traducoes.gd:364-393`, o `traduzir`: a tabela exata, a forma com a inicial maiúscula e, sem
  achar, o laço por todos os padrões, com recursão em cada grupo. Nada fica guardado entre uma chamada e outra:

  ```gdscript
  for par in _padroes:
  	var r: RegEx = par[0]
  	var m := r.search(s)
  	if m:
  		...
  		saida = saida.replace("$%d" % g, traduzir(m.get_string(g)))
  ```

- O `Desenho.t` (`godot/scripts/ui/desenho.gd:73-87`) chama o `traduzir` em cada `texto` e `paragrafo`.
- A HUD (`godot/scripts/ui/hud.gd:34-38`), o placar (`godot/scripts/ui/placar.gd:86`) e o lobby
  (`godot/scripts/ui/tela_lobby.gd:44`) fazem `queue_redraw()` a cada quadro.
- O custo, medido pela auditoria com o Godot 4.7.2 sem janela, num rascunho fora da árvore: «Começar» (na tabela)
  0,5 µs; «3 salas» 71,5 µs; «1 247» 41,7 µs; «P2 · 14 pts» 42,5 µs; «Não — era do P3» 81,3 µs; uma frase sem
  entrada nenhuma, 42,6 µs.

## O alvo

Um dicionário de memória por idioma, frase → saída, consultado antes da tabela. Ele se esvazia quando o idioma
muda e quando passa de um teto de entradas. A saída de cada frase continua a mesma; muda só o custo da repetição.

## Arquivos que mudam

- `godot/scripts/traducoes.gd` (ou o `traducao.gd` do pacote, se a X01 já entrou)
- `godot/scripts/forja.gd` (só as duas linhas do idioma no `aplicar_opcoes`)
- `godot/testes/prova_do_jogo.gd` (a checagem das traduções; ou `checagens/sistema_traducoes.gd`, se a V02 já entrou)

## Passos

1. O teste antes: para toda chave do `EN` e para uma frase de exemplo de cada padrão, a saída de hoje (guardada
   numa lista no teste).
2. A memória no `traduzir`: olha antes de tudo; grava a saída no fim, inclusive a frase que volta igual (a que não
   casou com nada, que é a mais cara).
3. O idioma muda por `Forja.aplicar_opcoes` (`godot/scripts/forja.gd:167-169`): o `Traducoes` passa a ter um
   `definir_idioma(i)` que limpa a memória quando o idioma muda de fato (o `aplicar_opcoes` roda a cada opção
   mexida), e o `Forja` chama ele em vez de escrever no `idioma` direto.
4. O teto: com mais de 4096 frases, a memória se esvazia inteira (o placar com número muda toda hora e não pode
   crescer sem fim).
5. A medida: a segunda chamada de uma frase que só casa por padrão fica abaixo de 2 µs.

## Armadilhas

- A coleta das frases da prova (`Desenho._coletados`, com `FORJA_COLETAR_TEXTOS`) acontece no `Desenho.t`, antes do
  `traduzir`: a memória não pode ficar no caminho dela.
- A recursão dos grupos chama o `traduzir` de dentro do `traduzir`: o grupo também entra na memória, e isso está
  certo (é a mesma frase, a mesma saída).
- Quem escreve no `Traducoes.idioma` direto (o `FORJA_IDIOMA` em `forja.gd:169` e qualquer prova) deixa a memória
  velha: o `git grep -n 'Traducoes.idioma ='` tem de achar só o `definir_idioma`.
- Se a V03 mudar a junção das tabelas para a primeira chamada, a memória se esvazia junto com essa junção.

## Não fazer

- Não mudar a tabela nem os padrões: isso é da V03.
- Não guardar a frase já desenhada (a fonte, o tamanho): só o texto.

## Pronto quando

O teste das saídas passa igual antes e depois, a segunda chamada de «P2 · 14 pts» fica abaixo de 2 µs, e trocar o
idioma nas opções devolve o português na hora.

## Provas

- `bash tests/prova_do_jogo.sh` (a checagem nova das traduções; a `_prova_das_frases` e a `_prova_das_maiusculas`
  seguem verdes).
- `python3 scripts/check_texto_de_tela.py`.

## Para o André (local)

Jogar uma partida curta em inglês e olhar se o placar e o lobby continuam certos.

## Ao terminar

Marcar WC03 como **feito** no [quadro](README.md), com o gasto.
