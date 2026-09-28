# Manuais de UI e UX para a TV

Estudo de 27/09/2026 sobre os manuais públicos de interface para jogos na TV
e de acessibilidade (Xbox, Android TV, tvOS, Fire TV, Steam Deck, WCAG, Game
Accessibility Guidelines, AbleGamers) e a pesquisa de UX de jogos. Foi feito
para o app 2D, que saiu do branch ([ADR-007](../adr/007-o-jogo-e-o-3d-em-godot.md));
as referências a `demo/src/ui/` são dele. O jogo 3D herdou os números: o
`Tema` e o `Desenho` do Godot seguem esta régua.

## 1. Princípios

### TV / 10 pés

**1. Não use fonte abaixo de 30 px em texto que precisa ser lido, na tela lógica de 1920×1080.**
- **Números:** a XAG 101 pede corpo de 26 px ou mais em console a 1080p, escalável até 200%. O corpo vai do topo da ascendente ao pé da descendente. Outras referências a 1080p:
  - Fire TV: corpo de texto de 28 px ou mais.
  - tvOS: padrão 29 e mínimo 23 (1 pt = 1 px a 1080p).
  - Xbox/UWP: texto principal de 30 px ou mais, secundário de 24 px ou mais.
- **Medição (fontTools):** Space Grotesk e Atkinson têm corpo de 0,90 em, e JetBrains Mono de 0,91 em. Por isso 26 px de corpo pedem fonte de 29 px ou mais.
- **Texto que some sozinho** (avisos rápidos, chamadas no JOGO): 46 px ou mais, até 40 caracteres por linha e até 2 linhas.
- **Por quê:** num TV de 40" a 3 m, 26 px de corpo medem só 12 mm. Texto ilegível exclui a pessoa antes de o jogo começar.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101 · https://developer.amazon.com/docs/fire-tv/design-and-user-experience-guidelines.html · https://developer.apple.com/design/human-interface-guidelines/typography · https://gameaccessibilityguidelines.com/if-any-subtitles-captions-are-used-present-them-in-a-clear-easy-to-read-way/
- **Onde:** em todas as telas. No app 2D (`demo/src/ui/texto.h`):
  - F_MINI 18 dá corpo de cerca de 16 px e reprova. Na tela do Deck (×0,667) a maiúscula cai para uns 8 px, abaixo dos 9 px que a Valve exige.
  - F_PEQUENA 22 dá cerca de 20 px e reprova.
  - F_TEXTO 28 dá cerca de 25 px, no limite.
  - Escala sugerida: 30 / 36 / 48 / 64 / 96+.

**2. Mantenha texto e itens focáveis a pelo menos 96 px das laterais e 60 px do topo e da base.**
- **Números:** a regra comum é deixar livres 5% em cada borda:
  - Android TV e UWP: 48×27 dp, ou seja, 96×54 px.
  - tvOS: 80 px nas laterais e 60 px no topo e na base.
  - Área útil resultante: x de 96 a 1824, y de 60 a 1020. O fundo pode ir até a borda.
- **Por quê:** o overscan da TV corta as bordas.
- **Fontes:** https://developer.android.com/design/ui/tv/guides/styles/layouts · https://developer.apple.com/design/human-interface-guidelines/layout
- **Onde:** selos de jogador nos cantos, placar do FIM, rodapé com os glifos.

**3. Use a densidade de informação de um celular e caminhos curtos.**
- **Números:**
  - Item focável com 64 px de altura ou mais (32 epx a 200%).
  - Botão no tvOS: 66 px (mínimo 56).
  - Grades: 40 px entre colunas e 100 px entre linhas.
  - No máximo 6 toques para ir de uma borda à outra.
- **Por quê:** navegar com controle é mais lento que com mouse.
- **Fontes:** https://learn.microsoft.com/en-us/windows/apps/design/devices/designing-for-tv · https://developer.apple.com/design/human-interface-guidelines/designing-for-games
- **Onde:** portas do salão, pausa, índice do livro, diagnóstico.

**4. Mostre sempre um único foco, marcado por dois sinais ou mais.**
- **Números:**
  - A WCAG 2.4.13 pede indicador com área de pelo menos um contorno de 2 px e contraste de 3:1 entre o estado com foco e sem foco. Para a TV, isso dá 4 px ou mais (2 px × escala de 200%).
  - Some preenchimento e escala de 1,025 a 1,1× (Android TV).
  - Foco inicial na ação principal.
  - Um diálogo prende o foco no primeiro botão.
  - Lista linear dá a volta do último item para o primeiro.
  - Nunca abra um popup só com texto, sem nada focável.
- **Por quê:** um brilho sutil some para quem joga longe da tela ou tem baixa visão.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113 · https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112 · https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html · https://developer.android.com/design/ui/tv/guides/styles/focus-system
- **Onde:** salão, pausa, livro, diagnóstico.

**5. Mostre os glifos do DualSense e mantenha ✕ para confirmar e ○ para voltar.**
- **Números:**
  - O PS5 unificou ✕ como confirmar em todas as regiões.
  - L1/R1 trocam de seção.
  - O símbolo dentro do glifo também respeita o tamanho mínimo.
  - Se ○ volta, não desenhe um botão "Voltar".
  - O glifo tem de corresponder à entrada em uso (critério do Deck Verified).
- **Por quê:** o jogador reconhece o símbolo sem procurar o botão.
- **Fontes:** https://www.gamespot.com/articles/sony-makes-a-big-ps5-change-in-japan-swapping-the-circle-and-x-buttons-functions/1100-6482928/ · https://developer.apple.com/design/human-interface-guidelines/game-controls · https://partner.steamgames.com/doc/steamhardware/compat
- **Onde:** rodapés de todas as telas; "✕ pronto" no AVISO.

### Acessibilidade

**6. Meça o contraste de cada par de cores do Drácula antes de usar.**
- **Números (XAG 102):**
  - Texto normal: 4,5:1 ou mais.
  - Texto grande (corpo de 52 px, fonte de 58 px ou mais) e texto inativo: 3:1.
  - Modo de alto contraste: 7:1.
- **Medição sobre o fundo #282A36:**

| Cor | Contraste |
|---|---|
| Foreground | 13,4 |
| Green | 10,4 |
| Cyan | 10,3 |
| Orange | 8,4 |
| Pink | 6,0 |
| Purple | 5,9 |
| Red | 4,53 (no limite) |
| Comment #6272A4 | 3,03 (só texto grande ou inativo) |

  - Sobre #44475A: Pink 3,8, Purple 3,8, Red 2,9 e Comment 1,9. Todos reprovam como texto normal.
- **Por quê:** reflexo e distância derrubam a nitidez.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102 · https://draculatheme.com/spec
- **Onde:** texto secundário do livro e do diagnóstico, texto sobre cartão focado, "FALHOU".

**7. Nunca deixe a cor sozinha identificar o jogador ou o veredito.**
- **Números:** 8 a 10% dos homens confundem vermelho e verde.
- **Simulação** (daltonismo pelo método de Machado 2009, distância de cor ΔE2000):
  - As cores do app 2D (`demo/src/ui/tema.c`) davam cerca de 7 entre azul e rosa na protanopia, e cerca de 12 entre vermelho e verde na deuteranopia.
  - A quadra do Drácula cyan/red/green/pink mantém a ordem do PlayStation (azul, vermelho, verde, rosa). Ela sobe a protanopia para cerca de 20, mas cai para cerca de 7 na tritanopia.
  - A quadra mais robusta da paleta é cyan/red/yellow/purple, com pior caso de cerca de 15 em todos os tipos.
  - Os tons de jogador coincidem com os de PASSOU/FALHOU.
- **Por quê:** quem é quem e o resultado de cada feature são informação crítica.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103 · https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/ · https://manuals.playstation.net/document/pdf/CUH-2218A-5.5_1.pdf
- **Onde:**
  - Jogador: cor mais "P1–P4" mais assento fixo.
  - Cor na tela igual à da light bar; número igual ao do indicador de jogador.
  - Veredito: ícone mais palavra mais cor. NÃO MEDIDO ganha forma própria, não só cinza.

**8. Deixe cada pessoa ler no próprio ritmo.**
- **Números:**
  - 14% dos adultos leem abaixo do nível de 11 anos, e alguns levam 3 vezes mais tempo para ler.
  - Todo limite de tempo deve poder ser desligado, ajustado até 10 vezes, ou avisado com pelo menos 20 s para estender.
  - O Jackbox tem "No Timer Mode" e "Skip Tutorial".
- **Por quê:** texto que some antes da leitura exclui.
- **Fontes:** https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/ · https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html · https://www.jackboxgames.com/blog/streaming-moderation-accessibility-features-jackbox-party-pack-eight
- **Onde:**
  - AVISO sem relógio.
  - FIM avança com ✕.
  - O cronômetro do JOGO é essencial e fica.

**9. Troque "segurar" e "martelar" por toque simples, e confirme ações destrutivas sem exigir segurar.**
- **Números:**
  - Evite segurar por 2 a 3 s ou mais, dois botões ao mesmo tempo e apertos repetidos.
  - Toque longo abaixo de 3 s só como alternativa.
  - Menus navegáveis só com o D-pad.
- **Por quê:** "para muitos é preferência; para jogadores com deficiência é vital".
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107 · https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/115 · https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/
- **Onde:** sair da sala e da pausa. Se a feature testada exige segurar, ofereça "pular" com resultado NÃO MEDIDO, não FALHOU.

**10. Limite flashes e movimento.**
- **Números (XAG 118 e 117):**
  - No máximo 3 flashes por segundo, em menos de cerca de 20% da tela.
  - Vermelho saturado (R/(R+G+B) de 0,8 ou mais) tem limite mais rígido.
  - Listras de alto contraste em mais de 20% da tela reprovam.
  - Ofereça opção para desligar tremor e fundo animado.
  - Faixa de cor segura para TV: 16–235.
- **Por quê:** evita crises fotossensíveis, enxaqueca e enjoo.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118 · https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117
- **Onde:** celebração do veredito, partículas, transições.

**11. Dê todo retorno crítico por dois canais; vibração nunca sozinha.**
- **Números:**
  - Visual e som sempre; vibração como terceiro canal.
  - O PS5 já tem ajuste de intensidade da vibração e do efeito do gatilho.
- **Por quê:** há quem jogue sem som ou sem vibração.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103 · https://www.playstation.com/en-us/accessibility/
- **Onde:** "pronto", ponto marcado, erro. Ofereça gatilho em Off por jogador.

### UX de jogos

**12. No AVISO, ensine até 3 coisas, comece pelo porquê e deixe praticar.**
- **Números:**
  - Celia Hodent: 3 itens ao mesmo tempo é o máximo enquanto se aprende; foque no porquê.
  - Jack Principles: uma tarefa por vez, o jogador sempre sabe o que fazer e sabe que o jogo está esperando por ele.
  - Super Mario Party: o treino acontece na própria tela de regras e todos confirmam que estão prontos.
  - Overcooked: ícones no lugar de palavras.
- **Por quê:** a atenção é limitada.
- **Fontes:** https://celiahodent.com/gamers-brain-ux-onboarding/ · https://archive.org/details/the-jack-principles · https://www.mariowiki.com/Super_Mario_Party · https://www.gamedeveloper.com/design/game-design-deep-dive-building-truly-cooperative-play-in-i-overcooked-i-
- **Onde:** uma frase de objetivo, até 3 ícones, treino sem pontos e "aguardando P3".

**13. Mostre sempre status e placar, com os jogadores na mesma ordem em todas as telas.**
- **Números:**
  - Componentes repetidos ficam na mesma ordem relativa (XAG 112).
  - Heurísticas de Desurvire e Federoff: status sempre visível, retorno imediato, interface consistente e poucas camadas de menu.
  - Rayman Legends: o jogador entra e sai a qualquer momento.
- **Por quê:** o jogador precisa saber onde está e o que aconteceu sem procurar.
- **Fontes:** https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112 · https://www.valuesatplay.org/wp-content/uploads/2007/09/desurvireplayabilityheurist.pdf · https://scispace.com/pdf/heuristics-and-usability-guidelines-for-the-creation-and-422izflgva.pdf · https://store.steampowered.com/app/242550/Rayman_Legends/
- **Onde:** P1→P4 da esquerda para a direita na mesa, no FIM e nas colunas do livro.

**14. Escolha a camada de interface conforme a informação.**
- **Números:** a interface se divide por dois eixos: está no espaço do jogo? pertence à ficção? Amplifique as ações disponíveis, suprima as indisponíveis e deixe as instruções abertas no tutorial.
- **Por quê:** informação na camada errada polui a cena ou fica escondida.
- **Fonte:** https://publications.lib.chalmers.se/records/fulltext/111921.pdf
- **Onde:** no salão, rótulo junto à porta e porta fechada com cadeado. No AVISO e no FIM, camada por cima do jogo com fundo escurecido.

**15. Deixe pular o que se repete e interromper animações.**
- **Números:** heurística nº 5 de Pinelle e o Apple HIG: não faça o jogador esperar uma animação terminar.
- **Por quê:** o que se repete a cada sala vira espera.
- **Fontes:** https://dl.acm.org/doi/10.1145/1357054.1357282 · https://developer.apple.com/design/human-interface-guidelines/motion
- **Onde:** AVISO a partir da segunda vez, animação do FIM.

### Retorno e animação

**16. Responda em até 100 ms e anime curto.**
- **Números:**
  - 0,1 s parece instantâneo; 1 s ainda mantém o fluxo.
  - Em jogos exigentes, a latência começa a atrapalhar por volta de 50 ms.
  - Material Design: microinterações de 100 a 200 ms; transições de 300 ms (entrada 225 ms, saída 195 ms); telas grandes cerca de 30% mais longas. Acima de 400 ms parece lento.
  - Curvas do Material 3: entrada (0.05, 0.7, 0.1, 1), saída (0.3, 0, 0.8, 0.15).
  - Palestra "Juice it or lose it": exagere e depois reduza.
- **Por quê:** o retorno confirma a ação; animação longa vira espera.
- **Fontes:** https://www.nngroup.com/articles/response-times-3-important-limits/ · https://www.ntnu.no/ojs/index.php/nikt/article/view/5252 · https://m1.material.io/motion/duration-easing.html · https://api.flutter.dev/flutter/material/Durations-class.html · https://www.gdcvault.com/play/1016487/juice-it-or-lose
- **Onde:** foco de 150 a 200 ms, troca de cena de 300 a 400 ms. A curva `sai_rapido` do app 2D já servia para entradas.

## 2. Checklist

1. Nenhuma fonte de leitura abaixo de 30 px; corpo medido de 26 px ou mais num print em 1080p.
2. Texto que some sozinho: 46 px ou mais, até 40 caracteres, até 2 linhas.
3. Contraste 3:1 só em fonte de 58 px ou mais ou em texto inativo; o resto 4,5:1 ou mais.
4. Nada de Comment, Red, Purple ou Pink como texto normal sobre #44475A.
5. Texto e focáveis dentro de x 96–1824 e y 60–1020.
6. Focáveis com 64 px ou mais; no máximo 6 toques de borda a borda.
7. Sempre um foco visível: contorno de 4 px ou mais, mais preenchimento ou escala.
8. Diálogo abre com foco no primeiro botão e fundo escurecido.
9. Listas lineares dão a volta.
10. Tudo navegável só com o D-pad.
11. ✕ confirma e ○ volta em todas as telas; L1/R1 trocam de página.
12. Glifos PlayStation com símbolo interno no tamanho mínimo ou maior.
13. Jogador identificado por cor, "P1–P4" e assento fixo.
14. Ordem P1→P4 igual em todas as telas.
15. Cor na tela igual à da light bar; número igual ao do indicador de jogador.
16. Captura passada por simulador de protanopia, deuteranopia e tritanopia.
17. Veredito com ícone, palavra e cor; NÃO MEDIDO com forma própria.
18. AVISO: objetivo em uma frase e até 3 ícones.
19. AVISO com treino que não conta pontos.
20. AVISO sem relógio, mostrando quem falta.
21. AVISO pulável a partir da segunda vez.
22. FIM avança só por botão; animação cancelável.
23. Nenhuma confirmação por segurar, por dois botões juntos ou por apertos repetidos.
24. Feature que exige segurar tem "pular", com resultado NÃO MEDIDO.
25. Retorno visual já no frame seguinte ao aperto.
26. Microinterações de 100 a 200 ms; trocas de cena de até 400 ms.
27. Todo evento crítico com som e visual.
28. Opções para desligar tremor e fundo animado, e gatilho em Off.
29. Flashes: no máximo 3 por segundo, em menos de 20% da tela.
30. Livro e diagnóstico: até 80 caracteres por linha, alinhado à esquerda, entrelinha de 1,5.
31. Testado num TV de 40" a 3 m e na tela do Deck.

## 3. Fontes

- https://learn.microsoft.com/en-us/windows/apps/design/devices/designing-for-tv — Xbox/TV: tamanhos em epx, 6 toques, área segura, cores 16–235.
- https://learn.microsoft.com/en-us/windows/apps/design/input/gamepad-and-remote-interactions — foco, armadilhas de foco, B para voltar.
- https://partner.steamgames.com/doc/steamhardware/compat — Deck Verified: 9/12 px, glifos da entrada ativa.
- https://developer.amazon.com/docs/fire-tv/design-and-user-experience-guidelines.html — 28 px, 5% de borda.
- https://developer.android.com/design/ui/tv/guides/styles/layouts — overscan de 48×27 dp.
- https://developer.android.com/design/ui/tv/guides/styles/focus-system — escala do foco.
- https://developer.apple.com/design/human-interface-guidelines/designing-for-games — tamanhos de texto e botão; ensinar jogando.
- https://developer.apple.com/design/human-interface-guidelines/typography — tvOS 29/23 pt.
- https://developer.apple.com/design/human-interface-guidelines/layout — tvOS 60/80 pt.
- https://developer.apple.com/design/human-interface-guidelines/game-controls — glifos e mapeamento de botões.
- https://developer.apple.com/design/human-interface-guidelines/motion — animação breve e cancelável.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101 — tamanho e espaçamento de texto.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102 — contraste.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103 — múltiplos canais de sinal.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/104 — legendas.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107 — entrada.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112 — navegação.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113 — foco.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/115 — ações destrutivas.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117 — movimento.
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118 — fotossensibilidade.
- https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/ — 28 px.
- https://gameaccessibilityguidelines.com/if-any-subtitles-captions-are-used-present-them-in-a-clear-easy-to-read-way/ — 46 px.
- https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-colour-alone/ — cor não pode ser o único sinal.
- https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/ — ritmo próprio de leitura.
- https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/ — alternativas a segurar.
- https://gameaccessibilityguidelines.com/full-list/ — lista completa, níveis básico e intermediário.
- https://accessible.games/wp-content/uploads/2018/11/AbleGamers_Includification.pdf — Includification, níveis 1 a 3.
- https://accessible.games/accessible-player-experiences/access-patterns/ — padrões de acesso (APX).
- https://www.playstation.com/en-us/accessibility/ — acessibilidade do PS5.
- https://www.playstation.com/en-us/support/hardware/adjust-general-controller-settings/ — ajustes do controle no PS5.
- https://www.playstation.com/content/dam/global_pdc/en/corporate/support/manuals/accessories/ps5-accessories/dualsense-wireless-controller-cfi-zct1w/CFI-ZCT1W_Wireless_Controller_Instruction_Man_EN_MEA.pdf — manual do DualSense: indicador de jogador.
- https://manuals.playstation.net/document/pdf/CUH-2218A-5.5_1.pdf — PS4: azul, vermelho, verde, rosa por ordem de conexão.
- https://www.gamespot.com/articles/sony-makes-a-big-ps5-change-in-japan-swapping-the-circle-and-x-buttons-functions/1100-6482928/ — ✕ confirma em todas as regiões.
- https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html — foco: 2 px, 3:1.
- https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html — limites de tempo: 10×, 20 s.
- https://draculatheme.com/spec — paleta oficial do Drácula.
- https://celiahodent.com/video-game-ux-psychology/ — percepção, atenção e memória.
- https://celiahodent.com/gamers-brain-ux-onboarding/ — onboarding.
- https://ixdf.org/literature/article/the-game-ux-twist-usability-principles-for-games — os 7 pilares de Hodent.
- https://www.valuesatplay.org/wp-content/uploads/2007/09/desurvireplayabilityheurist.pdf — heurísticas HEP de Desurvire.
- https://scispace.com/pdf/heuristics-and-usability-guidelines-for-the-creation-and-422izflgva.pdf — heurísticas de Federoff.
- https://dl.acm.org/doi/10.1145/1357054.1357282 — as 10 heurísticas de Pinelle.
- https://publications.lib.chalmers.se/records/fulltext/111921.pdf — "Beyond the HUD" (Fagerholt & Lorentzon).
- https://archive.org/details/the-jack-principles — Jack Principles.
- https://www.mariowiki.com/Super_Mario_Party — treino na tela de regras.
- https://www.gamedeveloper.com/design/game-design-deep-dive-building-truly-cooperative-play-in-i-overcooked-i- — Overcooked.
- https://www.jackboxgames.com/blog/streaming-moderation-accessibility-features-jackbox-party-pack-eight — Jackbox sem timer.
- https://store.steampowered.com/app/242550/Rayman_Legends/ — entrar e sair a qualquer momento.
- https://www.nngroup.com/articles/response-times-3-important-limits/ — 0,1/1/10 s.
- https://www.ntnu.no/ojs/index.php/nikt/article/view/5252 — latência em jogos, cerca de 50 ms.
- https://m1.material.io/motion/duration-easing.html — durações do Material Design.
- https://api.flutter.dev/flutter/material/Durations-class.html — tokens de duração do Material 3.
- https://api.flutter.dev/flutter/material/Easing-class.html — curvas do Material 3.
- https://www.gdcvault.com/play/1016487/juice-it-or-lose — "Juice it or lose it".
- https://archive.org/details/the-art-of-screenshake — "The Art of Screenshake".