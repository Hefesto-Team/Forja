# O checklist do estudo 02, tela por tela

A conferência dos 31 itens do [estudo 02](estudos/02-manuais-de-ui-e-ux.md) no
jogo 3D, em 28/09/2026. **ok** quer dizer conferido nas fotos das telas
(`godot/testes/captura_jogo.gd`); **parcial**, que vale em parte e o que
falta está dito; **falta**, que não vale ainda. O item 31 pede aparelho e
TV: fica para o Sprint A (a rodada com quatro controles de verdade) e o E (o
Steam Deck).

| # | item | situação |
| --- | --- | --- |
| 1 | leitura a 30 px ou mais | parcial — o corpo tem 32 px, mas os selos (24) e os rótulos (28) ficam abaixo; a opção **Texto: grande** (×1,15) leva os dois a 28 e 32 |
| 2 | texto que some: 46 px, 40 caracteres, 2 linhas | parcial — os avisos do HUD têm 28 px e uma linha curta |
| 3 | contraste 4,5:1 (3:1 só em fonte grande) | ok — os tokens medidos no estudo 03 |
| 4 | nada de Comment, Red, Purple ou Pink como texto sobre #44475A | ok — o trilho (#44475A) nunca leva texto |
| 5 | texto e focáveis em x 96–1824, y 60–1020 | ok — `Tema.MARGEM_X` 96 e `MARGEM_Y` 60 |
| 6 | focáveis de 64 px ou mais | ok — as linhas da pausa (68), da partida (104) e das opções (66) |
| 7 | foco visível: contorno de 4 px e preenchimento | ok — a pausa, a partida e as opções: borda roxa de 4 px e o fundo #403b55 |
| 8 | diálogo abre no primeiro botão, com o fundo escurecido | ok — a pausa abre em "Continuar"; todo menu escurece o fundo |
| 9 | listas dão a volta | ok — `wrapi` em todas |
| 10 | tudo pelo d-pad | ok — e o analógico faz o mesmo |
| 11 | ✕ confirma, ○ volta | ok — em todas as telas |
| 12 | glifos PlayStation no tamanho mínimo | ok — os glifos do app Hefesto |
| 13 | jogador por cor, "P1–P4" e assento fixo | ok |
| 14 | ordem P1→P4 igual em todas as telas | ok — o placar e o pódio ordenam por colocação, e dizem o lugar em cada linha |
| 15 | cor da tela igual à da light bar; número igual ao das lâmpadas | ok — `Forja.COR_DO_LUGAR` e `LEDS_DO_LUGAR`, os mesmos do módulo |
| 16 | captura passada por protanopia, deuteranopia e tritanopia | ok — `scripts/daltonismo.gd` faz a prancha das quatro versões; ele achou o "P2" vermelho quase sumindo no painel sob protanopia, e a cor do lugar agora é clareada até ter 3:1 nas quatro visões (`Tema.tom_para_a_borda`) |
| 17 | veredito com ícone, palavra e cor; não medido com forma própria | ok — "✓ PASSOU", "✗ FALHOU", "— NÃO MEDIDO" |
| 18 | aviso: objetivo numa frase e até 3 ícones | ok — o verbo numa linha e os glifos (A Galeria tem 4 features: um além) |
| 19 | aviso com treino que não conta pontos | ok — toda sala começa em treino (três acertos de cada um, ou 15 s, sem ponto); Os Caminhos têm o treino deles |
| 20 | aviso sem relógio, mostrando quem falta | ok — "aguardando" / "✓ pronto" por lugar |
| 21 | aviso pulável a partir da segunda vez | ok — ✕ sai do aviso a qualquer momento depois de meio segundo |
| 22 | fim avança só por botão | ok — ✕ (o robô das provas avança sozinho) |
| 23 | nada de segurar, dois botões juntos ou apertos repetidos para confirmar | ok — a confirmação é sempre um ✕ |
| 24 | feature que exige segurar tem "pular" | ok — nenhuma exige |
| 25 | retorno visual no quadro seguinte | ok — o toque do gesto, o tique e a borda mudam no mesmo quadro |
| 26 | microinterações de 100 a 200 ms; troca de cena até 400 ms | ok — a cortina fecha em 150 ms e abre em 220 |
| 27 | evento crítico com som e visual | ok — o golpe, o tiro, o susto e o veredito |
| 28 | desligar tremor, fundo animado e gatilho | parcial — tremor e gatilho nas opções; o giro da câmera no título ainda não desliga |
| 29 | flashes: até 3 por segundo, menos de 20% da tela | parcial — o único clarão (o susto d'A Voz) é um por sala, e **Flashes: desligados** o reduz a um brilho |
| 30 | livro e diagnóstico: 80 caracteres por linha, entrelinha 1,5 | falta conferir |
| 31 | TV de 40" a 3 m e a tela do Deck | falta — pede aparelho (sprints A e E) |
