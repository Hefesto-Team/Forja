# WJ02 — Os símbolos que a fonte do jogo não tem

**Sprint:** W · **Tamanho:** M · **Depende de:** G14 (as fontes da Fita no tema), F09 (a coleta dos retângulos)

## Por quê

A primeira frase do jogo, «Aperte ✕ no seu controle para entrar.», usa um caractere que nenhuma fonte da Forja
tem. O Godot o busca na fonte que a máquina tiver: numa sai uma cruz de outro desenho, noutra uma caixinha, e a
largura medida para encaixar o texto muda de um PC para outro. O mesmo vale para «✕ Quando pronto», o «□» e o «△»
da placa d'A Prova e as setas. A bíblia manda desenhar o botão com o glifo do controle; o texto ainda o escreve como
letra.

## Ler antes

- [06 — a interface e o texto](../arte/06-interface-e-texto.md) («Os botões se escrevem "Botão ✕ (Ação)" e se
  desenham com os glifos», `:183-187`)
- [12 — os portões](../arte/12-portoes.md) (o portão 8, `:148-155`: ✕ ◯ △ □ ◀ ▶ ▲ ▼ passam no texto)
- [V08 — os portões de arte e som reprovam](V08-os-portoes-de-arte-e-som-reprovam.md) (o portão 8 tira o que é
  emoji)
- [G14 — a cor e a letra da Fita](G14-a-cor-e-a-letra-da-fita.md)

## O estado de hoje

Medido em 09/10/2026 com `fc-query` no conjunto de caracteres de cada fonte de `godot/assets/fontes/`:

| caractere | SpaceGrotesk | JetBrainsMono | ArchivoNarrow | Bungee | VT323 | PermanentMarker |
| --- | --- | --- | --- | --- | --- | --- |
| ✕ U+2715 | não | sim | não | não | não | não |
| ◯ U+25EF, □ U+25A1 | não | sim | não | não | não | não |
| △ U+25B3, ◀ ▶ | não | sim | não | sim | não | não |
| ✓ U+2713, ✗ U+2717 | não | não | não | não | não | não |
| ⚡ U+26A1 | não | sim | não | não | não | não |
| ♪ ♫ | não | não | não | não | não | não |

- Os seis `.import` de `godot/assets/fontes/` trazem, na linha 22, `allow_system_fallback=true`, e `fallbacks=[]`
  logo abaixo: o que falta vem da máquina.
- `godot/scripts/tema.gd:69-87`: `fonte()` e `mono()` são `FontVariation` sobre a fonte, sem fallback declarado.
- Os símbolos de botão que o portão 8 deixa passar, desenhados como letra:
  `godot/scripts/ui/tela_lobby.gd:64` («Aperte ✕ no seu controle para entrar.»),
  `godot/scripts/salas/sala_jogo.gd:471` («✕ Quando pronto», o status do aviso),
  `godot/scripts/main.gd:768` («Seção 9 · □ a partida · △ a Prova de Fogo», a placa do salão).
- Os que o portão 8 reprova (são da V08): ✓ em `godot/scripts/ui/painel_sala.gd:74`,
  `godot/scripts/ui/cartao_jogador.gd:78`, `godot/scripts/salas/sala_jogo.gd:477` e nos status das salas antigas
  (`caminhos.gd:472-473`, `impacto.gd:526`, `galeria.gd:624`, `canto.gd:525`, `voz.gd:565-570`); ✓ e ✗ em
  `godot/scripts/ui/resultado.gd:197` e `godot/scripts/ui/livro.gd:131`, `:162`, `:164`; ⚡ em
  `godot/scripts/ui/desenho.gd:223`; ♪ ♫ num `Label3D` em `godot/scripts/salas/canto.gd:302`.
- Nas árvores em voo (a da Fita e a do cavaleiro) os mesmos textos seguem; na da Fita, já com `Tema.archivo`: a
  troca de fonte da G14 não traz nenhum destes caracteres.
- A prova visual mede a letra, a margem, o contraste e a colisão do que `Desenho.anotar` guarda; não confere se o
  caractere existe na fonte com que foi desenhado.

## O alvo

Nenhum caractere desenhado depende da fonte da máquina:

- `Desenho.texto` e `Desenho.selo` (o caminho único do texto) desenham os símbolos de botão que o portão 8 deixa
  passar (✕ ◯ △ □ ◀ ▶ ▲ ▼) com `Glifo.desenhar` (`cruz`, `circulo`, `triangulo`, `quadrado`, `esquerda`, `direita`,
  `cima`, `baixo`), num quadrado da altura da letra, no meio da frase já traduzida. `Desenho.largura` e
  `Desenho.caber` contam a mesma largura, e `Desenho.anotar` guarda o retângulo com ela.
- Os seis `.import` com `allow_system_fallback=false`.
- Uma régua nova da prova visual, «fora da fonte»: `Desenho.anotar` confere cada caractere da frase com
  `Font.has_char` (a fonte e os fallbacks declarados) e guarda o que falta; `checagens_visuais.gd` reprova com a frase
  e o caractere.

## Arquivos que mudam

- `godot/scripts/ui/desenho.gd` (`texto`, `selo`, `largura`, `caber`, `anotar`)
- `godot/assets/fontes/*.ttf.import` (seis)
- `godot/testes/checagens_visuais.gd`, `godot/testes/prova_visual.gd` (a régua e o caso dela)
- só se a V08 ainda não tirou os cinco de fora da lista (ver Armadilhas): `godot/scripts/ui/painel_sala.gd`,
  `godot/scripts/ui/cartao_jogador.gd`, `godot/scripts/ui/resultado.gd`, `godot/scripts/ui/livro.gd`,
  `godot/scripts/salas/sala_jogo.gd`, `godot/scripts/salas/{caminhos,impacto,galeria,canto,voz}.gd`,
  `godot/scripts/traducoes.gd`

## Passos

1. A régua primeiro: `has_char` no `anotar` e a checagem «fora da fonte». Rodar a prova visual e guardar a lista do
   que reprova (deve bater com «O estado de hoje»).
2. Os símbolos de botão por glifo em `Desenho.texto` e `Desenho.selo`, com a largura igual em `largura`, `caber` e
   `anotar`. A frase traduzida é a que se corta: «Press ✕ on your controller to join.» ganha o mesmo glifo.
3. `allow_system_fallback=false` nos seis `.import`, com o import refeito (`godot --headless --import`) para o
   recurso importado valer.
4. Rodar a prova visual e ver a régua zerar.

## Armadilhas

- **Os cinco de fora da lista** (✓ ✗ ⚡ ♪ ♫) são do portão 8 da V08. Com o fallback do sistema desligado, eles viram
  caixinha: se a V08 ainda não os tirou, esta ficha os troca (palavra ou glifo, pela bíblia; nunca outro símbolo) e
  a V08 acha zero. Não desligar o fallback antes de a régua zerar.
- `Desenho.paragrafo` não ganha glifo no meio da linha: a quebra é do Godot. Se a régua achar símbolo num
  parágrafo, a frase muda.
- A tela de hoje e a das árvores em voo leem `Tema.fonte`/`Tema.archivo`: o glifo pega a cor do texto, não a do
  jogador (06: o glifo só ganha a cor do dono na dica presa ao cavaleiro).
- `has_char` de uma `FontVariation`: conferir na primeira medida que ela olha a fonte de base e os fallbacks
  declarados, e não a fonte da máquina; se olhar a da máquina, a régua confere na `FontFile` de base.
- O `Label3D` (o ♪ do Canto) não passa por `Desenho`: a régua da prova visual não o vê. O portão 8 o pega no texto
  do script.

## Não fazer

- Não embutir uma fonte de símbolos fora da bíblia para resolver: a fonte nova é decisão da direção de arte (o
  portão 2 reprova fonte fora da lista).
- Não trocar o «✕» do texto pela palavra «cruz»: a voz do texto escreve o símbolo; o desenho é que muda.
- Não mexer nas frases da tabela de traduções além dos cinco da V08.

## Pronto quando

A régua «fora da fonte» passa nas quatro partidas da prova visual, os seis `.import` estão sem fallback do sistema,
e o «✕» do lobby sai como o glifo `cruz`, igual em português e em inglês.

## Provas

- Na sessão: `PASSADAS=fixa bash tests/prova_visual.sh pasta/` verde, com um caso puro da régua (uma frase com
  «✓» numa fonte sem ele reprova; «Aperte ✕» desenhada por `Desenho.texto` passa).
- `bash tests/prova_do_jogo.sh` (as frases e as maiúsculas seguem verdes) e `bash scripts/portoes/rodar.sh`.
- `grep -c 'allow_system_fallback=true' godot/assets/fontes/*.import` dá 0 em todos.

## Para o André (local)

Abrir o lobby na máquina dele, em português e em inglês: o «✕» da primeira frase é o mesmo glifo das dicas de botão,
alinhado na linha, e o texto não muda de largura. Olhar a placa d'A Prova no salão (□ e △).

## Ao terminar

Marcar WJ02 como **feito** no [quadro](README.md), com o commit e o gasto; se trocou os cinco da V08, dizer na V08
que o portão 8 já acha zero.
