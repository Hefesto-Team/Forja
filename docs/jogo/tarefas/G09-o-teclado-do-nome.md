# G09 — O teclado de tela para o nome

**Sprint:** G · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,0 · **Depende de:** F00, F07, F08, F09, G02

## Por quê

O nome é o que faz a pessoa se apegar ao cavaleiro. A G02 deixou o nome
sortear da lista da forja; esta ficha deixa cada um escrever o seu, no próprio
controle, sem teclado de computador e com os quatro escrevendo ao mesmo tempo.

## Ler antes

- [G02 — a construção do cavaleiro](G02-a-construcao-do-cavaleiro.md) (o passo NOME, `NOMES`, a tabela dos botões, o layout do cartão)
- [06 — a voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto)
- [A arquitetura — a paridade](../13-arquitetura.md#a-paridade-entre-a-prova-e-o-jogo--f08)

## O estado de hoje (depois da G02)

- O passo `NOME` da construção (`godot/scripts/ui/tela_lobby.gd`, reescrito
  pela G02): ◀▶ troca pelo nome seguinte/anterior de `NOMES` que ninguém
  usa; △ sorteia um nome livre; ✕ vai para FORJAR.
- `NOMES` tem 24 nomes da forja ("Brasa", "Faísca", "Cobalto"…).
- O nome vive em `ForjaPlayer.nome` e em `Opcoes.cavaleiro[l]["nome"]`, e
  aparece no cartão (cabeça do cartão, `Desenho.caber(…, 1 linha)`) e no HUD
  (G04).
- O robô passa pelos passos pelo controle simulado (`TelaLobby.robo(l, dt)`).

## O alvo

No passo `NOME`, o cartão do lugar mostra um teclado em grade. Os quatro
escrevem ao mesmo tempo, cada um no seu cartão.

```
┌──────────────────────────────┐
│  Brasa▏                       │   o nome, com o cursor
│  A B C D E F G                │
│  H I J K L M N                │   a grade: 7 colunas × 5 linhas
│  O P Q R S T U                │
│  V W X Y Z Ç ␣                │
│  ´ ~ ^ ⌫  Pronto              │   acento agudo, til, circunflexo, apagar, pronto
└──────────────────────────────┘
```

| botão | faz |
| --- | --- |
| direcional ou analógico esquerdo | move o cursor na grade (com repetição a cada 0,15 s segurando) |
| Botão ✕ (Escolher) | põe a letra; nas teclas de acento, acentua a última letra (a → á, à não entra); em "Pronto", vai para FORJAR |
| Botão ◯ (Apagar) | apaga a última letra; com o nome vazio, volta ao passo anterior |
| Botão △ (Sortear) | sorteia um nome livre de `NOMES` (o atalho da G02 continua) |
| R1 | pula direto para "Pronto" |

As regras do nome:

- de 2 a 12 letras; espaço só entre palavras (nunca no começo, nunca dois
  seguidos);
- **a primeira letra sai maiúscula e as outras minúsculas**, sozinhas (a
  regra de texto do [06](../06-telas-e-fluxo.md#a-voz-do-texto));
- dois lugares não podem ter o mesmo nome: "Pronto" fica apagado e o nome
  pisca em `Tema.LARANJA` por 0,5 s (sem frase de erro);
- acentos válidos: á é í ó ú, ã õ, â ê ô, e Ç na grade; o til só em a e o, o
  circunflexo só em a, e, o; acento em letra que não aceita não faz nada;
- o nome **não passa pela tabela de traduções** (é nome próprio).

## Passos

1. Em `godot/scripts/ui/tela_lobby.gd`, criar `class TecladoDoNome` (interna,
   ou `godot/scripts/ui/teclado_do_nome.gd` com `class_name TecladoDoNome` e
   o `.uid`), com: `var cursor := Vector2i(0, 0)`, `var texto := ""`,
   `const GRADE := [["A","B","C","D","E","F","G"], ["H","I","J","K","L","M","N"],
   ["O","P","Q","R","S","T","U"], ["V","W","X","Y","Z","Ç"," "],
   ["´","~","^","⌫","Pronto"]]`, `func mover(d: Vector2i)`,
   `func escolher() -> String` (devolve `"pronto"` quando é para seguir),
   `func apagar() -> bool` (false quando já estava vazio), e
   `func formatar(t: String) -> String` (primeira maiúscula, resto minúsculo,
   espaços limpos).
2. `const ACENTOS := {"´": {"a":"á","e":"é","i":"í","o":"ó","u":"ú"}, "~": {"a":"ã","o":"õ"}, "^": {"a":"â","e":"ê","o":"ô"}}`
   — a tecla de acento troca a última letra se `ultima.to_lower()` estiver no
   dicionário (a grade escreve em maiúscula; o `formatar` acerta a caixa
   depois).
3. Um `TecladoDoNome` por lugar (`var teclados := [TecladoDoNome.new(), ...]`),
   que começa com o nome atual do lugar (o sorteado pela G02).
4. No passo `NOME`, trocar a tabela da G02: o ◀▶/▲▼ move o cursor, ✕ chama
   `escolher()`, ◯ chama `apagar()` (e volta ao passo anterior quando devolve
   false), △ sorteia (e põe o sorteado no `texto`), R1 leva o cursor a
   "Pronto".
5. Desenhar o teclado no `_draw()` do cartão, na área da escolha (da base
   186 para baixo, a mesma da G02): teclas de 48×48 px com 8 px entre elas,
   letras em `Tema.fonte(600)` e `Tema.T_CORPO` (nunca abaixo de 30 px), a
   tecla do cursor com o anel de 4 px na cor do lugar (o foco do
   [estudo 03](../../estudos/03-o-sistema-visual-do-app-hefesto.md)), "Pronto"
   em `Tema.VERDE` quando o nome vale e apagado quando não. Se a grade não
   couber na largura do cartão em 1920×1080 e em 1,15×, diminuir o espaço
   entre teclas até 4 px, nunca a fonte.
6. Cada tecla escolhida: `Forja.sentir(l, "toque")` e o clique curto no
   alto-falante do dono (`Som.pio` não; o clique de interface da agenda de
   [05](../05-haptica-e-controle.md#a-agenda-do-alto-falante)).
7. Ao seguir para FORJAR: `jogadores[l].nome = formatar(texto)` e
   `Opcoes.cavaleiro[l]["nome"]`; o registro `cavaleiro` (G02) já leva o nome.
8. O robô, em `TelaLobby.robo(l, dt)`: no passo `NOME`, 70% das vezes aperta
   △ e depois R1 e ✕ (fica com o sorteado); 30% das vezes digita um nome de
   `NOMES` letra a letra, movendo o cursor pelo direcional simulado
   (`Forja.robo_apertar(l, Forja.DIREITA)`…) até a letra e apertando ✕, com
   um erro de propósito que ele apaga com ◯ quando `Forja.robo_acerta()` é
   falso. Só pelo controle simulado.
9. As frases novas da tela em `godot/scripts/traducoes.gd`: "Pronto",
   "Botão ✕ (Escolher)", "Botão ◯ (Apagar)", "Botão △ (Sortear)".

## Armadilhas

- Quatro teclados ao mesmo tempo: o estado é por lugar, nunca global.
- A repetição do direcional segurado precisa de relógio por lugar, não do
  quadro (o robô com `--fixed-fps 60` andaria rápido demais): use o
  `Forja.segura` e um temporizador em segundos de parede.
- O cartão do lugar vazio não mostra teclado.
- Controle que cai no meio do nome: o texto fica guardado; quem volta
  continua de onde parou.
- `formatar` com letras acentuadas: `"ÁGUA".to_lower()` precisa dar "água" —
  conferir num teste; o GDScript trata Unicode, mas confirme.
- O nome aparece no HUD (G04) e no resultado (F03): 12 letras largas ("WWWWWWWWWWWW")
  têm de caber; a coleta de texto da prova visual pega se não couber.

## Não fazer

- Não usar o teclado do sistema nem o do Steam.
- Não bloquear palavras: é um jogo entre amigos no sofá.
- Não traduzir o nome.

## Pronto quando

Os quatro escrevem nomes ao mesmo tempo, com acento, cada um no seu cartão;
dois nomes iguais não passam; o nome aparece igual no cartão, no HUD e no
resultado; e a prova visual passa com o robô digitando.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
func _prova_do_teclado() -> void:
	var t := TecladoDoNome.new()
	for letra in ["G", "R", "A", "F", "I", "T", "E"]:
		t.texto += letra
	_esperar(t.formatar(t.texto) == "Grafite", "teclado: primeira maiúscula, resto minúsculo")
	t.texto = "AGUA"
	t.cursor = Vector2i(0, 4)   # a tecla ´
	t.escolher()
	_esperar(t.formatar(t.texto) == "Aguá", "teclado: o agudo acentua a última letra")
	t.texto = "Z"
	t.cursor = Vector2i(1, 4)   # a tecla ~
	t.escolher()
	_esperar(t.texto == "Z", "teclado: til em letra que não aceita não faz nada")
	t.texto = "ABCDEFGHIJKL"
	t.cursor = Vector2i(0, 0)
	t.escolher()
	_esperar(t.texto.length() == 12, "teclado: no máximo 12 letras")
```

E `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh` (o robô
digitando nas quatro partidas).

## Para o André (local)

Quatro pessoas escrevendo o nome ao mesmo tempo: é rápido? Acha as letras?
O acento faz sentido? Anotar no diário quanto tempo levou.

## Ao terminar

Marcar G09 como **feito** no [quadro](README.md), com o gasto. Commit
sugerido: `feat: cada um escreve o nome do seu cavaleiro no próprio controle`.
