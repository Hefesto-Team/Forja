# G11 — A interface com o UI Pack e os prompts

**Sprint:** G · **Tamanho:** M · **Depende de:** F00, F07, F09, G04, G10

## Por quê

As telas de hoje são desenhadas à mão (molduras de canto redondo, selos,
dicas). O UI Pack da Kenney dá painéis, molduras e botões com acabamento de
jogo, no mesmo traço do resto dos assets. Esta ficha os põe nas telas **nas
cores do jogo**, e completa os ícones de botão que faltam com os do Input
Prompts — e deixa o André decidir, olhando, se ficou melhor.

## Ler antes

- [14 — os assets da Kenney](../14-os-assets-kenney.md) (a interface, os ícones de botão)
- [06 — as telas e o fluxo](../06-telas-e-fluxo.md)
- [O estudo 03 — o sistema visual](../../estudos/03-o-sistema-visual-do-app-hefesto.md) (os tokens)

## O estado de hoje

- Tudo é desenhado em `_draw()` com as funções de `godot/scripts/ui/desenho.gd`:
  `Desenho.moldura(ci, r, fundo, borda, largura := 2, raio := Tema.RAIO_QUADRO)`
  (`desenho.gd:41`), `Desenho.selo` (`:128`), `Desenho.dicas_a_direita` e
  `dicas_a_esquerda` (`:178`, `:188`), `Desenho.glifo(nome)` (`:24`), que
  carrega `res://assets/glifos/<nome>.png`.
- Os tokens de `godot/scripts/tema.gd`: `CASA #11121a`, `APP #21222c`,
  `PAINEL #282a36`, `ELEVADO #2b2d3a`, `LINHA #53576f`, `ROXO #bd93f9` (foco),
  `ROSA #ff79c6`, `VERDE #50fa7b`, `LARANJA #ffb86c`, `VERMELHO #ff5555`,
  `CIANO #8be9fd`; `RAIO_QUADRO 18`, `RAIO_CARTAO 14`, `BORDA 2`;
  `MARGEM_X 96`, `MARGEM_Y 60`.
- Os glifos de `godot/assets/glifos/` (do app Hefesto, MIT) já cobrem os
  botões, o direcional, L1/L2/R1/R2, os analógicos, share/options, o
  touchpad, o giroscópio, o acelerômetro, os dois motores, a barra de luz, o
  LED de jogador, o microfone, o alto-falante e a bateria.

## O alvo

- **As molduras do UI Pack** entram como **`StyleBoxTexture`** (nove
  fatias), desenhadas por `Desenho.moldura` quando o estilo pede:

  ```gdscript
  # tema.gd
  const ESTILO := "kenney"   # "kenney" ou "liso" (o de hoje); o André escolhe olhando
  # desenho.gd
  static func moldura(ci: CanvasItem, r: Rect2, fundo: Color, borda: Color, largura := 2, raio := Tema.RAIO_QUADRO) -> void:
  	if Tema.ESTILO == "kenney" and _caixa_kenney != null:
  		_caixa_kenney.modulate_color = fundo      # a textura é cinza: o jogo dá a cor
  		_caixa_kenney.draw(ci.get_canvas_item(), r)
  		# a borda continua desenhada por cima, com `borda`, para o foco e a cor do lugar
  	else:
  		# o desenho de hoje
  ```

- **Só as versões cinza** do UI Pack (as que existem em vetor e em cinza),
  tingidas pelo `modulate` com as cores do `Tema`: a paleta do jogo continua
  mandando.
- **Onde entra:** o cartão da construção (G02), o cartão do HUD (G04), a tela
  de resultado (F03), o placar, a pausa e as opções. O título continua como
  está.
- **Os ícones que faltam** do Input Prompts (vetor, "Default"): o botão PS,
  o mudo (o botão, não o microfone), os toques do touchpad (um dedo, dois
  dedos, deslizar) — exportados para PNG no mesmo tamanho dos glifos de hoje,
  em branco sobre transparente (o jogo tinge), com nomes em português em
  `godot/assets/glifos/` (`botao_ps.png`, `mudo.png`, `touchpad_dois_dedos.png`…).

## Passos

1. Com o zip do André, importar os pacotes pela G10:
   `python3 scripts/importar_kenney.py <zip> ui-pack ui-pack-sci-fi input-prompts`
   (acrescentar os três em `APROVADOS` do script, só as pastas de vetor e
   cinza, e só o SVG/PNG "Default" do Input Prompts). Destino:
   `godot/assets/kenney/ui-pack/`, `ui-pack-sci-fi/`, `input-prompts/`.
2. Escolher **uma** moldura de painel e **uma** de botão do UI Pack (cinza,
   canto arredondado perto de 14–18 px na tela de 1920×1080) e montar os
   `StyleBoxTexture` em `godot/scripts/ui/desenho.gd` (margens das nove
   fatias medidas na imagem).
3. `Tema.ESTILO` e o desvio em `Desenho.moldura` (o alvo acima). A borda de
   foco (4 px na cor do lugar ou `ROXO`) continua desenhada por cima.
4. Exportar os ícones que faltam (passo do alvo) e registrá-los em
   `Desenho.glifo` (já carrega por nome).
5. Rodar a prova visual **duas vezes**, com `ESTILO = "kenney"` e com
   `"liso"`, e anexar as duas pranchas à ficha para o André escolher.
6. Registrar os pacotes em `godot/assets/LEIA-ME.md` e
   `LICENCAS-DE-TERCEIROS.md` (o script da G10 faz).

## Armadilhas

- **Texto por cima da moldura:** as molduras do UI Pack têm borda mais grossa
  que a de hoje; a área útil encolhe. A coleta de texto da prova visual pega
  texto saindo da moldura.
- **Contraste:** o texto `FG` sobre o painel tingido tem de manter 4,5:1
  (o estudo 03); conferir com o `scripts/daltonismo.gd` e a medida de
  contraste que já existe.
- **Nada de cor do pacote:** se aparecer o azul ou o laranja do UI Pack na
  tela, a textura não é a cinza.
- **Os ícones da Sony:** só o desenho do botão; nada de logo da PlayStation.
- O `.import` das texturas de interface: sem compressão, filtro linear (é
  vetor exportado, não pixel-art).

## Não fazer

- Não trocar as fontes (Space Grotesk e JetBrains Mono ficam).
- Não usar as versões pixel ou 1-bit.
- Não apagar o estilo "liso": ele é a comparação e o plano B.

## Pronto quando

As telas da lista usam as molduras do UI Pack nas cores do `Tema`, os
ícones que faltavam existem, a prova visual passa nos dois estilos, e o André
escolheu o estilo olhando as duas pranchas (e o `Tema.ESTILO` fica o que ele
escolheu).

## Provas

- Na sessão: `bash tests/prova_do_jogo.sh` e `bash tests/prova_visual.sh`
  (nos dois estilos), e em `godot/testes/prova_do_jogo.gd`:

  ```gdscript
  for nome in ["botao_ps", "mudo", "touchpad_dois_dedos"]:
  	_esperar(Desenho.glifo(nome) != null, "glifo novo: %s" % nome)
  ```

- Com o André, local: a prova visual na placa de vídeo, as duas pranchas lado
  a lado.

## Para o André (local)

Olhar as duas pranchas ("kenney" e "liso") e escolher. Anotar no diário o
que ficou esquisito em cada uma.

## Ao terminar

Marcar G11 como **feito** no [quadro](README.md), com o gasto e o estilo
escolhido. Commit sugerido:
`feat: as molduras do UI Pack nas cores do jogo, e os ícones de botão que faltavam`.
