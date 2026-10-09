# G09 — O teclado de tela para o nome

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F05 (`Forja.sentir`), F07, F08, F09, G13 (a tela de montagem, a linha Nome e o arquétipo)

## Por quê

O nome é o que faz a pessoa se apegar ao cavaleiro, e escrever o próprio nome é o primeiro prazer da noite: cada um
escreve no próprio controle, os quatro ao mesmo tempo, sem teclado de computador, e a montagem inteira cabe em 90 s.

## Ler antes

- [Sistemas, o nome](../sistemas/README.md#o-nome) (o tamanho, o filtro, a maiúscula, o único, o sorteado)
- [04, a tela de montagem](../arte/04-o-cavaleiro.md#a-tela-de-montagem) (a coluna de 432 px e as faixas em y)
- [06, os objetos](../arte/06-interface-e-texto.md#os-objetos) (a linha do teclado do nome, que esta ficha corrige)

## O estado de hoje

- O lobby de hoje (`godot/scripts/ui/tela_lobby.gd`, 113 linhas) não tem nome: o seletor tem só o boneco e o item.
  O nome sai de `NOMES` em `godot/scripts/partida.gd:26`.
- A G13 troca o lobby pela tela de montagem: quatro colunas de 432 px (x = 96 + 432·i), as cinco linhas (Cabeça,
  Superior, Inferior, Arma ou amuleto, Nome) em y 660 a 860 e os VUs em 870 a 1010. Na linha Nome, ◀ ▶ troca o
  nome sorteado. Esta ficha começa depois dela: meça de novo o arquivo e a função que a G13 deixou.
- O 06 pede teclas de 72×72 com vão de 8. Sete teclas dão 7·72 + 6·8 = 552 px, e a coluna tem 432. Não cabe: esta
  ficha decide 52×52 com vão de 6 (400 px) e corrige a linha do 06.

## Arquivos que mudam

- `godot/scripts/ui/teclado_do_nome.gd` (novo, `class_name TecladoDoNome`, com o `.uid` que o Godot gera)
- `godot/scripts/ui/tela_lobby.gd`: abrir, desenhar e fechar o teclado na coluna. **De todos:** a G02 e a G13
  também mudam este arquivo
- `godot/scripts/main.gd`: o `_quadro_lobby` (ou o que a G13 deixou no lugar) passa os botões ao teclado aberto.
  **De todos:** G13, G14, G15 e G16
- `godot/scripts/traducoes.gd`: as frases novas. **De todos:** G11, G12, G16
- `godot/scripts/som.gd`: tocar pelo id do mapa (passo 6). **De todos:** G11, G12, G16
- `docs/jogo/audio/mapa.csv`: as linhas `ui_tecla` e `ui_tique`. **De todos:** G11, G12, G16
- `godot/assets/sons/ui_tecla.wav` e `godot/assets/sons/ui_tique.wav` (cópias; o `ui_tique` também chega pela G11 e
  pela G16: quem chega primeiro copia, os outros usam)
- `docs/jogo/arte/06-interface-e-texto.md`: a linha «o teclado do nome» da tabela dos objetos
- `godot/testes/prova_do_jogo.gd`: as checagens de Provas. **De todos**

## Como se joga

Na linha Nome da coluna, «Botão R1 (Escrever)» abre o teclado. O teclado toma a faixa de y 660 a 1000 da coluna; as
cinco linhas e os VUs somem enquanto ele está aberto, e voltam quando ele fecha. Os quatro escrevem ao mesmo tempo,
cada um na sua coluna.

```
 Dona Brasa|                   o campo: 400×44, y 660
 A  B  C  D  E  F  G           a grade: 7 colunas × 5 linhas, a partir de y 716
 H  I  J  K  L  M  N
 O  P  Q  R  S  T  U
 V  W  X  Y  Z  Ç  _           _ é o espaço
 ´  ~  ^  ◯  [ Pronto  ]       ◯ apaga; Pronto ocupa as colunas 5 a 7
```

| botão | faz |
| --- | --- |
| direcional ou analógico esquerdo (além de 0,5) | anda o cursor uma tecla; segurando, repete depois de 0,40 s e a cada 0,15 s, em segundos de parede; nas bordas, para (não dá a volta) |
| Botão ✕ (Escolher) | põe a letra; na tecla de acento, acentua a última letra; no espaço, põe um espaço; em ◯, apaga; em Pronto, fecha o teclado e grava o nome |
| Botão ◯ (Apagar) | apaga a última letra; com o campo vazio, fecha o teclado e o nome volta ao de antes de abrir |
| Botão △ (Sortear) | põe no campo um nome sorteado (regra abaixo) e leva o cursor a Pronto |
| R1 | leva o cursor a Pronto |

As regras do nome (as do [RPG](../sistemas/README.md#o-nome), com o número):

- de 2 a 12 caracteres, contando o espaço; o mínimo de 2 conta só letras. A 13.ª tecla não entra e a tecla escolhida
  não faz som.
- o espaço só entre palavras: nunca no começo, nunca dois seguidos, e o do fim sai ao gravar.
- a maiúscula: a primeira letra de **cada palavra** sai maiúscula e as outras minúsculas («Dona Brasa»). A grade
  escreve em maiúscula; `formatar()` acerta a caixa no campo, a cada tecla.
- os acentos: ´ dá á é í ó ú; ~ dá ã õ; ^ dá â ê ô. Acento em letra que não aceita não faz nada e não faz som.
- o sorteado: entre os seis nomes do arquétipo que a coluna mostra (`godot/dados/nomes.csv`, a cópia que a G13 faz
  de `docs/jogo/sistemas/nomes.csv`), só os que ninguém da mesa usa; o Aríete e o Eco, e o arquétipo sem nenhum
  livre, sorteiam entre os 24. A semente é a do robô, para a prova repetir.
- o único na mesa: dois lugares não fecham com o mesmo nome (a comparação é depois de `formatar()`). Enquanto o
  nome do campo é igual ao de outro lugar, o Pronto fica apagado e o nome do campo alterna `ETIQUETA` e `MUDO` a
  cada batida (2 vezes por segundo a 120 BPM, abaixo das 3 do [10](../arte/10-acessibilidade.md#o-piscar)). Não há
  frase de erro.
- o nome não passa pela tabela de traduções e não tem lista de palavras proibidas.

Controle que cai com o teclado aberto: o campo e o cursor ficam guardados no lugar; quem volta continua de onde parou.

## A cena

Não há corte nem câmera nova: o teclado é 2D, na coluna da montagem da G13, sobre o cavaleiro que segue no idle.
A luz, a lente e o plano são os da montagem (G13). Nada brilha: o teclado não tem emissivo.

As medidas, com a coluna começando em `x0 = 96 + 432·lugar`:

| peça | posição e tamanho | superfície | letra |
| --- | --- | --- | --- |
| o campo | (x0 + 16, 660), 400×44, raio 6 | `CASCO_ALTO`, borda de 3 px na cor do dono (`Tema.JOGADOR[lugar]`) | o nome em Archivo Narrow 600 32, `ETIQUETA`, a 12 px da esquerda; a barra do cursor de texto, 3×32 px, `ETIQUETA`, parada (não pisca) |
| a grade | origem (x0 + 16, 716); teclas de 52×52, vão de 6; 7·52 + 6·6 = 400 px de largura e 5·52 + 4·6 = 284 de altura (termina em y 1000) | a tecla: `CASCO`, raio 6 | a letra em Archivo Narrow 600 36, `ETIQUETA`, centrada |
| a tecla sob o cursor | a mesma tecla | `CASCO_ALTO` com borda na cor do dono: 3 px; no quadro de cada batida vai a 5 px e volta a 3 px em 1 colcheia (250 ms a 120), `SAI` | a mesma |
| o espaço | a tecla da linha 4, coluna 7 | `CASCO` | uma barra de 24×4 px, `ETIQUETA`, a 14 px do pé da tecla |
| o ◯ | a tecla da linha 5, coluna 4 | `CASCO` | o glifo `circle` de 40 px em `ETIQUETA` |
| o Pronto | linha 5, colunas 5 a 7: 3·52 + 2·6 = 168×52 | valendo: a cor do dono, texto em `TINTA`; apagado: `CASCO`, texto em `MUDO` | «Pronto» em Archivo Narrow 700 34 |

Os pares de contraste são os do [02](../arte/02-cor-e-letra.md#os-pares-de-contraste-permitidos): `ETIQUETA` sobre
`CASCO` e `CASCO_ALTO`, `TINTA` sobre a cor do jogador, `MUDO` sobre `CASCO`. Com o texto grande (×1,15), a letra vai
a 41 px, o campo a 37 e o Pronto a 39: tudo cabe na tecla, e o tamanho das teclas não muda.

O cursor anda em 4 quadros, curva `SAI` (a curva do [05](../arte/05-movimento.md#as-curvas): `Tween.TRANS_CUBIC`, `Tween.EASE_OUT`). Com Movimento Reduzido (G16), o cursor pula sem os 4 quadros. A placa do
lugar (y 60 a 150) mostra o nome do campo enquanto se escreve.

## O som

| evento | id do [mapa](../audio/mapa.csv) | onde |
| --- | --- | --- |
| o cursor anda uma tecla | `ui_tique` (35 ms) | na TV a −12 dB e no alto-falante do dono |
| ✕ põe letra, acento, espaço ou apaga; ◯ apaga | `ui_tecla` (30 ms) na TV a −12 dB; `mod_clique` (o clique do módulo, `Forja.som_falante(l, "clique")`) no alto-falante do dono | a TV e o controle do dono |
| ✕ em Pronto valendo | `ui_confirma` (90 ms) | na TV a −12 dB e no alto-falante do dono |
| ◯ com o campo vazio (fecha) | `ui_volta` (90 ms) | na TV a −12 dB e no alto-falante do dono |
| a tecla que não entra (a 13.ª, o acento recusado, ✕ no Pronto apagado) | nenhum | |

A música é a faixa da construção, a 120 BPM; o teclado não a muda.

Os WAV estão em `godot/estudos/direcao/som/<id>.wav` e ainda não no jogo. O encanamento, igual nas fichas G09, G11,
G12 e G16: copiar cada `<id>.wav` usado para `godot/assets/sons/<id>.wav`; `Som.tocar(nome, ...)` e
`Som.no_controle(lugar, nome, ...)` tocam primeiro `res://assets/sons/<nome>.wav` quando ele existe, sem o tom
sorteado de ±5 % dos gravados; a linha do mapa ganha `arquivo` = `godot/assets/sons/<id>.wav` e `estado` = `no jogo`.
Se outra ficha já fez a mudança em `som.gd`, use-a sem mudar. A V05 depois troca as tabelas do `Som` pelo mapa.

## O controle

| evento | vibração | gatilho | luz | alto-falante | microfone |
| --- | --- | --- | --- | --- | --- |
| cada tecla que entra e cada passo do cursor | `Forja.sentir(l, "toque")` (0 / 0,45 / 60 ms), só no dono | não muda (o da montagem) | a lightbar segue na cor do lugar, as lâmpadas no padrão dele | o da tabela do som | não se usa |
| ✕ no Pronto apagado | `Forja.sentir(l, "toque")` | não muda | não muda | nenhum | não se usa |
| os outros três lugares | nada | nada | nada | nada | nada |

Prova sem o controle na mão: o robô aperta pelo controle simulado (`Forja.robo_apertar`), e a prova conta no registro
as linhas `{"tipo": "sensacao", "nome": "toque"}` do lugar (o `sentir` da F05 as grava).

## O cavaleiro

Nenhum stat muda o teclado. O nome vai para o cavaleiro: a placa do lugar (Archivo Narrow 600 32), a etiqueta
(Permanent Marker), o HUD e o pódio (Bungee), como no [04](../arte/04-o-cavaleiro.md#o-nome). O cavaleiro segue no
idle na batida enquanto se escreve. Trocar de arquétipo depois não troca o nome.

## As reações

Não se aplica: o teclado não dispara carimbo. O adesivo pelo touchpad continua valendo na montagem
([09](../arte/09-reacoes.md#quando-o-jogador-manda)); o touchpad não faz nada no teclado.

## A diversão

O momento é o primeiro nome escrito: a mesa ri do nome do outro antes da primeira faixa.

- **O `nome` do momento:** `nome_escrito`. Ao gravar um nome digitado (não o sorteado sem mudança), o jogo escreve
  `{"tipo": "momento", "slot": "montagem", "nome": "nome_escrito", "lugar": l, "t_musica": ...}`.
- **A janela:** do primeiro ✕ da montagem até a forja, no máximo 90 s
  ([sistemas](../sistemas/README.md#o-que-a-noite-de-seis-horas-mede)). Escrever um nome de 8 letras leva até 25 s
  no robô `medio`.
- **A mesa:** a padrão (P1 `bom`, P2 e P3 `medio`, P4 `ruim`), semente 7.
- **O rastro na prancha:** o nome escrito fica na placa e na etiqueta até o fim da noite; o quadro de 30 s da prancha
  mostra pelo menos dois campos com letras.
- O evento `cavaleiro` da forja ganha `"nome_escrito": true|false` e `"t_nome_ms"` (o tempo com o teclado aberto),
  para a noite medir quantos escrevem e quanto custa.

## Pronto quando

Os quatro escrevem ao mesmo tempo, com acento, cada um na sua coluna; «Dona Brasa» sai com as duas maiúsculas; dois
nomes iguais não fecham; △ sorteia do arquétipo; o nome aparece igual na placa, na etiqueta, no HUD e no resultado; e
a montagem do robô na mesa padrão fecha em 90 s ou menos.

## Provas

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
func _prova_do_teclado() -> void:
	var t := TecladoDoNome.new()
	_esperar(t.formatar("DONA BRASA") == "Dona Brasa", "teclado: maiúscula em cada palavra")
	_esperar(t.formatar("ÁGUA VIVA") == "Água Viva", "teclado: a maiúscula com acento")
	t.texto = "AGUA"
	t.cursor = Vector2i(0, 4)   # a tecla ´
	t.escolher()
	_esperar(t.formatar(t.texto) == "Aguá", "teclado: o agudo acentua a última letra")
	t.texto = "Z"
	t.cursor = Vector2i(1, 4)   # a tecla ~
	t.escolher()
	_esperar(t.texto == "Z", "teclado: til em letra que não aceita não faz nada")
	t.texto = "ABCDEF GHIJK"
	t.cursor = Vector2i(0, 0)
	t.escolher()
	_esperar(t.texto.length() == 12, "teclado: no máximo 12 caracteres")
	t.texto = ""
	t.cursor = Vector2i(6, 3)   # o espaço
	t.escolher()
	_esperar(t.texto == "", "teclado: o espaço não começa o nome")
	_esperar(TecladoDoNome.largura_da_grade() == 400.0, "teclado: a grade cabe na coluna de 432 px")
```

E mais:

- `bash tests/prova_do_jogo.sh`: o robô, no lugar 1, escreve «Dona Brasa» letra a letra pelo direcional simulado, com
  um erro que apaga com ◯ quando `Forja.robo_acerta()` é falso; nos lugares 2 a 4, aperta △ e ✕. A prova confere os
  quatro nomes no evento `cavaleiro`, um `momento` `nome_escrito` do lugar 1, as linhas `sensacao` «toque» só do
  lugar que apertou, e que dois lugares com o mesmo nome forçado não fecham.
- `bash tests/prova_visual.sh`: a prancha da montagem com os quatro teclados abertos, em 1,0× e 1,15×, em português e
  em inglês; a coleta de texto não acha letra fora da tecla nem nome fora da placa com «WWWWWWWWWWWW».
- `python3 scripts/check_texto_de_tela.py` e `bash scripts/portoes/rodar.sh`: as frases novas com maiúscula, os ids
  `ui_tecla`, `ui_tique`, `ui_confirma` e `ui_volta` no mapa, nenhuma cor fora do `Tema`.

## Passos

1. `godot/scripts/ui/teclado_do_nome.gd`: `var cursor := Vector2i(0, 0)`, `var texto := ""`,
   `const GRADE := [["A","B","C","D","E","F","G"], ["H","I","J","K","L","M","N"], ["O","P","Q","R","S","T","U"],
   ["V","W","X","Y","Z","Ç"," "], ["´","~","^","⌫","PRONTO","PRONTO","PRONTO"]]`,
   `const ACENTOS := {"´": {"A":"Á","E":"É","I":"Í","O":"Ó","U":"Ú"}, "~": {"A":"Ã","O":"Õ"}, "^": {"A":"Â","E":"Ê","O":"Ô"}}`
   (sobre a última letra em maiúscula), `func mover(d: Vector2i)`, `func escolher() -> String` (devolve `"pronto"`,
   `"tecla"` ou `""` quando nada entrou), `func apagar() -> bool` (false com o campo vazio),
   `static func formatar(t: String) -> String`, `static func largura_da_grade() -> float` e
   `func desenhar(ci: CanvasItem, x0: float, cor_do_dono: Color)`. O ⌫ da grade é a tecla que se desenha com o glifo
   `circle`; o texto «⌫» nunca vai para a tela.
2. Um teclado por lugar em `tela_lobby.gd` (`var teclados := [null, null, null, null]`), criado no R1 da linha Nome
   com o nome atual no campo; ✕ em Pronto grava `formatar(texto)` no cavaleiro do lugar (o lugar que a G13 usa para o
   nome) e fecha.
3. Em `main.gd`, com o teclado do lugar aberto, os botões do lugar vão para ele e não para a montagem.
4. O sorteio: ler `godot/dados/nomes.csv` uma vez; o arquétipo vem da G13.
5. O único: a cada quadro, o Pronto de cada lugar compara o campo com os nomes dos outros três.
6. O som: copiar os quatro WAV e pôr o encanamento do id em `som.gd` (O som); as quatro linhas do mapa.
7. O robô, pelo controle simulado (Provas).
8. As frases em `traducoes.gd`: «Pronto», «Botão R1 (Escrever)», «Botão ✕ (Escolher)», «Botão ◯ (Apagar)»,
   «Botão △ (Sortear)».
9. A linha do 06: «teclas de 52×52, vão de 6, `CASCO`, a tecla sob o cursor com borda do dono de 3 a 5 px, Archivo 600
   36» (a G09 decidiu: 72 não cabe na coluna).

## Armadilhas

- Quatro teclados ao mesmo tempo: o estado é por lugar, nunca global.
- A repetição do direcional segurado é em segundos de parede (`Time.get_ticks_msec()`), não em quadros: com
  `--fixed-fps 60` o robô andaria rápido demais.
- `"ÁGUA".to_lower()` precisa dar «água»: a prova confere.
- 12 «W» são o pior caso de largura na placa, na etiqueta e no pódio: a prova visual pega.

## Não fazer

- Não usar o teclado do sistema nem o do Steam.
- Não bloquear palavras.
- Não traduzir o nome.

## Para o André (local)

Quatro pessoas escrevendo o nome ao mesmo tempo: anotar no diário quanto tempo cada um levou, e se alguém procurou o
acento.

## Ao terminar

Marcar G09 como **feito** no [quadro](README.md), com o gasto. Commit sugerido:
`feat(montagem): cada um escreve o nome do seu cavaleiro no próprio controle`.

## O que foi feito (leva 1, o-cavaleiro)

**Feita no que o código já alcança.** O nome ainda não aparece na etiqueta 3D, no HUD nem no resultado: isso espera a G04 e a G13.

- **O teclado** (`scripts/ui/teclado_do_nome.gd`): grade de teclas de 52 x 52, vão de 6, borda de 3 a 5 px, Archivo 600 a 36; cada lugar escreve
  no próprio controle e os quatro teclados vivem ao mesmo tempo (`teclados[4]`, `nome_escrito[4]`, `t_nome_ms[4]` na `tela_lobby.gd`).
  Cruz escreve, círculo apaga (com o campo vazio fecha e devolve o nome de antes), R1 abre, triângulo sorteia, máximo de 12 letras, maiúscula
  em cada palavra, nome igual ao de outro lugar não fecha.
- **O cartão** (`cartao_jogador.gd`) e o texto (`desenho.gd`): `Desenho.nome`, `nome_que_cabe` e `largura_do_nome`, para o nome da pessoa
  nunca passar pelo tradutor e caber no cartão a 1,0x e a 1,15x. Em `traducoes.gd` entram «Escrever» e «Apagar».
- **O robô** escreve «DONA BRASA» com um erro e um círculo, e os lugares 1 a 3 apertam triângulo e cruz; espera 0,12 s entre apertos.
- **Os sons** `ui_tecla` e `ui_tique` (`compress/mode=0`) entram em `docs/jogo/audio/mapa.csv` como `no jogo`.
- **A linha do tempo** ganha o momento `nome_escrito` (e a regra «sem música, nenhuma linha tem `t_musica`» passa a admitir também o tipo
  `momento`, porque a ficha manda `t_musica` nele). Docs: `arte/06` (a linha do teclado corrigida) e `13-arquitetura.md` (acréscimos).
- **As provas** (`prova_do_jogo.gd`): `_prova_do_teclado` (as contas e as larguras de «W», «Wwwwwwwwwwww» e «Pronto» a 1,0x e a 1,15x),
  `_prova_do_teclado_na_mesa`, `_prova_do_nome_na_linha_do_tempo` e a checagem de que a montagem do robô fecha em até 90 s.
- **Medidas:** a montagem do robô ia de cerca de 2150 quadros (36 s) para cerca de 5030 (84 s) com 0,16 s por aperto. Texto de tela: 279
  frases, 69 padrões, 0 minúsculas (eram 277).
- **A mordida:** formatar sem a caixa, `MAXIMO` 99, nome repetido sempre falso e o toque indo para os quatro lugares reprovaram mais de 14
  checagens («maiúscula em cada palavra», «no máximo 12», «nome igual não fecha», «toque só ao P1», «robô escreveu Dona Brasa»); a cura voltou.

### Desvios e decisões (a validar por ela)

- O triângulo no teclado toca `ui_tecla`, o clique e o toque (a ficha não deu som a ele); R1 dentro do teclado soa como passo do cursor.
- A unicidade compara com os nomes já gravados dos outros lugares, não com o campo em edição de ninguém.
- Sem arquétipo (a G13 não chegou), o triângulo sorteia entre os 24 `NOMES` livres.
- Com o teclado aberto as dicas do rodapé descem à linha 1022 e a fileira normal ganhou «R1 Escrever».
- `t_nome_ms` é em milissegundos de parede: sob `--fixed-fps` não é tempo de jogo.
- Sem `Opcoes.movimento` (G16), o que precisar de «sem tremor» usa `Opcoes.tremor`.
- Observação: a prova «relógio sem faixa: andou X s em 0,8 s» falha de vez em quando conforme a carga da máquina; não é desta ficha.

### O que fica para a mão dela e do André

- Quatro pessoas escrevendo ao mesmo tempo, com os controles de verdade: acento, tempo de cada um, se 0,12 s entre apertos do robô reflete uma pessoa.
- A prancha de quatro teclados em 1,0x e 1,15x, em português e inglês, não foi automatizada na prova visual; a prova visual mostra o robô
  escrevendo na montagem e as larguras são medidas no `prova_do_jogo`.

### A conferência (leva 1, o-cavaleiro)

- **Corrigido:** o robô travava a montagem se dois lugares sorteassem o mesmo nome (o Pronto apagava e ele ficava esperando); agora sorteia
  de novo. A prova confere os quatro nomes do evento «cavaleiro», todos diferentes, e não só os dois primeiros.
- **A medida de agora:** o robô espera 0,12 s entre apertos e a montagem fecha entre 52 e 56 s de jogo (a medida de 84 s acima era com 0,16 s).
- **A prova falhava com a máquina carregada:** a repetição do direcional anda em ms de parede, e um aperto de dois quadros passou de 0,40 s;
  a seta repetiu, o «Ed» virou «Ec» e o resto do teclado caiu em cascata. A `tela_lobby.gd` ganhou `relogio_do_teclado` (o de parede, como a
  ficha manda), e a prova do teclado o troca pelo relógio do jogo. Com quem joga nada muda.
- **O «Pronto quando» não fecha inteiro:** o triângulo não sorteia do arquétipo (a G13), o nome não aparece na etiqueta, no HUD nem no resultado
  (a G04 e a G13), e a prancha dos quatro teclados em 1,0x e 1,15x, em português e inglês, não existe. A prova visual não mostra o teclado.
- **A validar por ela:** o Pronto apagado sob o cursor usa `CASCO_ALTO`, e a ficha diz `CASCO`.
