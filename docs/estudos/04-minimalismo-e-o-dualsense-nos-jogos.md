# Minimalismo e o DualSense nos jogos comerciais

Estudo de 27/09/2026: as regras de uma interface enxuta, como os jogos
comerciais mostram (e escondem) cada recurso do DualSense, e os tokens
sugeridos para a tela do jogo. Foi feito para o app 2D, que saiu do branch
([ADR-007](../adr/007-o-jogo-e-o-3d-em-godot.md)); a tabela da seção 2 é a
base do desenho das salas do jogo 3D ([SALAS.md](../SALAS.md)).

Números marcados "(proposta)" são sugestão do estudo. Os demais vêm da fonte citada ou de medição: nos arquivos TTF do Google Fonts, no contraste WCAG da paleta e numa simulação de daltonismo pelo método de Machado (2009). No dia do estudo, o app 2D usava Atkinson Hyperlegible, Cinzel e uma paleta de bronze (`demo/src/ui/tema.c`); as cores de jogador já seguiam azul, vermelho, verde e rosa.

## 1. Regras de estilo minimalista

**1. Corte até sobrar só o que decide o próximo segundo.** Ponha a informação crítica onde o olho já está, junto do avatar ou do alvo; o resto vai para a periferia; não tenha tela de título. Números: 1 indicador por jogador, colado nele, e no máximo 2 itens na periferia (tempo, placar) (proposta). Fontes: [Returnal UX](https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/) ("remove all possible distractions"; o crítico fica "in and near the reticle") e [Thumper](https://caneandrinse.com/thumper-interview/) (arte subtrativa: tirar toda informação visual que não é essencial). Onde: jogo, salão.

**2. Meça no próprio objeto, não numa barra.** Journey mostra a carga do voo nas runas do cachecol e não mostra nenhuma palavra fora do título e dos créditos. RE Village deixa a vida fora do HUD e só avisa no estado crítico, com distorção, borda vermelha e um lembrete. Aqui: desenhe a pressão do gatilho, o nível do sopro e a inclinação no cartão do próprio jogador; efeito de tela cheia só no estado crítico. Fontes: [Journey](https://en.wikipedia.org/wiki/Journey_(2012_video_game)), [RE Village](https://www.gamepressure.com/resident-evil-village/wounds-how-to-heal/z5e664). Onde: jogo.

**3. Ensine com um verbo e deixe testar antes de valer.** O aviso da sala tem três partes:
- um verbo de 1 ou 2 palavras em caixa alta, como no WarioWare;
- o DualSense desenhado com só a parte usada acesa (o Returnal mostra "onde no controle" fica cada ação);
- treino livre até os 4 marcarem "pronto", como no Mario Party.

No máximo 3 coisas novas por sala, porque texto longo não é lido. Fontes: [WarioWare](https://en.wikipedia.org/wiki/WarioWare), [Mario Party](https://www.imore.com/super-mario-party-beginners-guide), [Hodent GDC16](https://celiahodent.com/gamers-brain-ux-onboarding/). Onde: aviso da sala.

**4. Use Space Grotesk para texto e JetBrains Mono para números, e nada abaixo de 32 px.**
- Os dígitos da Space Grotesk têm largura variável (de 418 a 641 unidades por mil), então um cronômetro nela "treme". Na JetBrains Mono todos os dígitos medem 600.
- A XAG pede 26 px de corpo (do topo do "h" ao pé do "g") na TV. Na Space Grotesk o corpo é 0,90 do tamanho da fonte, logo o mínimo é fonte de 28,9 px. O GAG pede 28 px.
- Faça a hierarquia por peso e cor antes de mudar o tamanho. Caixa alta só em rótulos de 1 ou 2 palavras.
- Fora do relatório, nenhum bloco passa de 2 linhas. No relatório: entrelinha de pelo menos 1,5 e no máximo 80 caracteres por linha. A 40 px a fonte dá cerca de 18,8 px por caractere, então a largura máxima é 1.120 px.

Fontes: [XAG 101](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101), [GAG](https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/), [Refactoring UI](https://medium.com/refactoring-ui/7-practical-tips-for-cheating-at-design-40c736799886). Onde: todas.

**5. Use grade de 8 px dentro da margem segura de 5%.** O Android TV desenha em 960×540 dp; a 1080p, 1 dp = 2 px. Isso dá margem segura de 96 × 54 px, 12 colunas de 104 px com calha de 40 px e 4 cartões de 392 px. Versão fechada na grade de 8: margem de 120 + 4 cartões de 384 + 3 calhas de 48 = 1920. Fontes: [Android TV](https://developer.android.com/design/ui/tv/guides/styles/layouts), [grade de 8 pt](https://spec.fm/specifics/8-pt-grid). Onde: mesa/lobby, vereditos.

**6. Eleve por tom, não por sombra.** No Material 3, a elevação é uma camada tonal da cor primária, com degraus de 5, 8, 11, 12 e 14%. Sombra só quando uma superfície cobre outra. Com roxo sobre #282a36: 5% dá #2f2f40, 8% dá #343246 e 12% dá #3a374d. Fontes: [Android M3](https://developer.android.com/develop/ui/compose/designsystems/material3), [tabela no Flutter](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/material/elevation_overlay.dart). Onde: todas.

**7. Uma cor por função, e nunca só a cor.**
- Inside é quase monocromático e colore só o menino e partes do cenário. Mini Metro soma cor e forma sobre fundo neutro. Hades usa a cor da moldura só para a raridade.
- Cada jogador tem cor, número de 1 a 4 (o mesmo dos LEDs de jogador do controle) e um lugar fixo na tela.
- Na simulação de daltonismo, a distância de cor (ΔE) entre ciano e rosa cai para 18 em deuteranopia, e entre ciano e verde para 15 em tritanopia. A cor sozinha não separa os jogadores.
- O veredito é ícone mais palavra; a cor vai só no ícone.

Fontes: [Inside](https://en.wikipedia.org/wiki/Inside_(video_game)), [Mini Metro](https://www.gamedeveloper.com/audio/-i-mini-motorways-i-and-the-delicate-art-of-marrying-complexity-and-minimalism), [Hades](https://www.dbltap.com/posts/hades-boon-rarity-guide-to-standard-and-special-boons-01ek30qqebzt), [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103). Onde: mesa, jogo, vereditos.

**8. Meça o contraste.** A XAG pede texto com pelo menos 4,5:1; texto de 52 px ou mais e texto inativo com 3:1; modo de alto contraste com 7:1. O que se mediu na paleta:
- #6272a4 dá 3,0:1 no painel: serve para borda ou texto de 52 px ou mais, nunca para legenda.
- Texto secundário: #f8f8f2 a 60% (5,8:1). Desabilitado: a 38% (3,2:1), junto com um cadeado ou uma palavra.
- #ff5555 dá 4,5:1 no painel, mas só 2,9:1 sobre #44475a.
- Em botão com fundo de acento, use texto #21222c (pelo menos 5:1). Branco sobre roxo dá só 2,3:1.

Fonte: [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102). Onde: todas.

**9. Um foco por tela, grosso, e poucas bordas.** O foco é um anel roxo de 4 px com 4 px de folga, mais escala de 1,05 em cartão ou 1,1 em botão; o Android TV usa 1,025, 1,05 ou 1,1 conforme o tamanho. A WCAG pede pelo menos 2 px e 3:1 entre focado e não focado; roxo no painel dá 5,9:1. No resto, separe por espaço e tom: borda de 2 px só em cartão interativo (#6272a4, 3,4:1 contra #21222c); divisor decorativo em #44475a. Fontes: [foco na TV](https://developer.android.com/design/ui/tv/guides/styles/focus-system), [WCAG 2.4.13](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html), [Refactoring UI](https://medium.com/refactoring-ui/7-practical-tips-for-cheating-at-design-40c736799886). Onde: mesa, salão, relatório.

**10. Juice: um evento, três canais, no mesmo quadro, e com freio.**
- Som, háptica e visual disparam juntos. O Tetris Effect encaixa no compasso o som de cada rotação; o Returnal fecha a carga do tiro alternativo com som e pulso háptico. A háptica nunca é o único canal.
- O peso vem de uma pausa curta no impacto e de um tremor. A Vlambeer usa cerca de 20 ms de pausa. O Smash Ultimate calcula a pausa em (dano × 0,65 + 6) quadros, com teto de 30 quadros (500 ms); Sakurai diz que ela cresce com o golpe, mas sempre com teto. O tremor é proporcional ao "trauma" ao quadrado, com ruído suave (Eiserloh).
- Freio: resposta ao botão no quadro seguinte (0,1 s é o limite do "instantâneo"); no máximo 3 flashes por segundo, cobrindo menos de 20% da tela; tremor desligável. Juice não conserta design fraco.

Fontes: [Tetris Effect](https://www.nicholassinger.com/blog/tetriseffect), [Vlambeer](https://www.youtube.com/watch?v=AJdEqssNZ-U), [SmashWiki](https://www.ssbwiki.com/Hitlag), [Sakurai](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/), [Eiserloh](https://archive.org/details/GDC2016Eiserloh), [Nielsen](https://www.nngroup.com/articles/response-times-3-important-limits/), [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118), [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117), [Folmer Kelly](https://www.gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it-). Onde: jogo, vereditos.

**11. Conforto se escolhe na mesa.** Ofereça gatilho Desligado/Fraco/Forte e vibração de 0 a 100%, por jogador. O GT7 dá Off/Weak/Strong para cada gatilho, também no menu rápido, e a XAG 110 pede poder desligar e dosar a háptica. A resistência por arma cansou os dedos em cerca de 1 hora de CoD. O Astro foi criticado por não ter essas opções, mas passa sozinho pela parte do sopro quando o microfone está mudo: faça o mesmo nas salas de microfone e de mudo. Fontes: [GT7](https://racinggames.gg/article/how-to-change-dualsense-trigger-strength-in-gran-turismo-7), [XAG 110](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/110), [Kotaku](https://kotaku.com/my-hands-don-t-like-ps5-call-of-duty-s-adaptive-trigger-1845670412), [Can I Play That](https://caniplaythat.com/2020/12/07/astros-playroom-can-i-play-that-mobility-review/), [microfone mudo](https://seekingtech.com/how-to-fix-unresponsive-microphone-input-in-astros-playroom/). Onde: mesa/lobby, salas de microfone e mudo.

## 2. Feature do DualSense → como os jogos comerciais mostram

| Feature | Jogo(s) | O que aparece na tela | O que fica só na mão ou no ouvido | Fonte |
|---|---|---|---|---|
| Gatilho "arma" (ponto de quebra) | Returnal; Ratchet & Clank: Rift Apart; Deathloop | Returnal: sinal visual e sonoro de tiro alternativo pronto. Ratchet: sai 1 ou 2 canos. Deathloop: Colt soca a arma emperrada | O clique no meio do curso. Em Deathloop o gatilho trava na metade antes da animação | [Returnal](https://blog.playstation.com/2021/05/13/how-housemarque-created-returnals-immersive-dualsense-controller-effects/), [Ratchet](https://www.thegamer.com/ratchet-clank-rift-apart-all-confirmed-guns/), [Deathloop](https://blog.playstation.com/2020/11/23/immerse-yourself-in-deathloop-on-ps5-with-the-dualsense-controller/) |
| Gatilho "resistência" | Astro's Playroom; Ghostwire: Tokyo; Kena; CoD Cold War | Astro: guia do controle na abertura. Nos outros, só o efeito em cena | Mola que aperta; apoio frágil que pede puxada leve; foguete com força proporcional à pressão. Ghostwire: fogo e vento distinguíveis "sem olhar". CoD: pressão diferente por arma | [Astro](https://blog.playstation.com/2020/11/11/unleash-the-power-of-the-dualsense-wireless-controller-with-astros-playroom/), [Ghostwire](https://blog.playstation.com/2021/09/09/face-the-unknown-in-new-ghostwire-tokyo-trailer/), [Kena](https://blog.playstation.com/2021/05/13/devs-reveal-their-upcoming-dualsense-wireless-controller-implementations/), [Kotaku](https://kotaku.com/my-hands-don-t-like-ps5-call-of-duty-s-adaptive-trigger-1845670412) |
| Gatilho "vibração" | Gran Turismo 7 | Menu de força Off/Weak/Strong por gatilho | O freio ABS pulsa no gatilho: o dedo lê a aderência | [GTPlanet](https://www.gtplanet.net/gt7-dualsense-feel-abs-20200821/) |
| Háptica de terreno e clima | Astro; Returnal; Deathloop; GT7 | Nada além do próprio cenário | Plástico, metal, areia, água; gotas de chuva geradas em tempo real; telhado áspero contra neve abafada; lombadas e trocas de marcha | [VGC](https://www.videogameschronicle.com/news/ps5-developers-reveal-how-their-games-use-dualsenses-adaptive-triggers-and-haptic-feedback/), [Returnal](https://blog.playstation.com/2021/05/13/how-housemarque-created-returnals-immersive-dualsense-controller-effects/), [Deathloop](https://blog.playstation.com/2020/11/23/immerse-yourself-in-deathloop-on-ps5-with-the-dualsense-controller/) |
| Háptica como aviso ou direção | Spider-Man: Miles Morales; Returnal | Returnal soma ícones e áudio | O lado de onde vem o golpe; o Venom Punch cruza da esquerda para a direita; item maligno pulsa como batimento cardíaco | [VGC](https://www.videogameschronicle.com/news/ps5-developers-reveal-how-their-games-use-dualsenses-adaptive-triggers-and-haptic-feedback/), [Returnal UX](https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/) |
| Alto-falante do controle | Deathloop; Ghostwire; Astro | Nada | Provocações da Julianna "no rádio", clique seco sem munição, balas passando; vozes do além; areia chacoalhando dentro do controle | [Deathloop](https://blog.playstation.com/2020/11/23/immerse-yourself-in-deathloop-on-ps5-with-the-dualsense-controller/), [Ghostwire](https://blog.playstation.com/2021/09/09/face-the-unknown-in-new-ghostwire-tokyo-trailer/), [TheGamer](https://www.thegamer.com/astros-playroom-cooling-springs-ps5-gameplay-and-dualsense-impressions/) |
| Lightbar como estado | RE Village; Life is Strange: True Colors; Subnautica: Below Zero | RE Village: vida só no inventário; no estado crítico, distorção, borda vermelha e lembrete | Vida de verde a amarelo/laranja a vermelho; cor da emoção; pisca mais rápido perto do recurso | [BGR](https://www.bgr.com/2191746/what-playstation-5-controller-colors-mean/), [gamepressure](https://www.gamepressure.com/resident-evil-village/wounds-how-to-heal/z5e664), [PS Blog](https://blog.playstation.com/2021/05/13/devs-reveal-their-upcoming-dualsense-wireless-controller-implementations/) |
| LEDs de jogador | PS5 | Número do jogador | De 1 a 4 luzes indicam a vaga; no DualSense o número vem dos LEDs, não da cor | [PS suporte](https://www.playstation.com/en-us/support/hardware/dualsense-controller-support/), [Wikipedia](https://en.wikipedia.org/wiki/DualShock) |
| Microfone e mudo | Astro (Cooling Springs); PS5 | Dica curta pedindo para soprar | O sopro gira a hélice. Com o microfone mudo (LED laranja), o jogo passa a seção sozinho | [TheGamer](https://www.thegamer.com/astros-playroom-cooling-springs-ps5-gameplay-and-dualsense-impressions/), [seekingtech](https://seekingtech.com/how-to-fix-unresponsive-microphone-input-in-astros-playroom/) |
| Touchpad e movimento | Astro | O boneco repete o gesto: bola rolando, zíper, cabeça que tomba ao inclinar | Deslizar e inclinar | [TheGamer](https://www.thegamer.com/astros-playroom-cooling-springs-ps5-gameplay-and-dualsense-impressions/) |
| Háptica por áudio (atuadores) | Astro Bot; GT7; Returnal | Nada | Doucet: "a háptica é baseada em som"; o alto-falante é o que se ouve, a vibração é o que se sente. Yamauchi: som e tato "contínuos, integrados" | [onemoregame](https://onemoregame.ph/2024/09/astro-bot-director-nicolas-doucet-interview/), [GTPlanet](https://www.gtplanet.net/gt7-dualsense-feel-abs-20200821/) |

O padrão comum: a tela ensina uma vez (guia, dica curta, gesto do personagem) e confirma o resultado. Textura, peso e direção ficam na mão. O que decide a partida sempre tem um segundo canal ([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103), [GAG](https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-sounds-alone/)). Em jogo de festa local, o 1-2-Switch mostra um vídeo tutorial e depois faz os jogadores olharem um para o outro, não para a tela ([Wikipedia](https://en.wikipedia.org/wiki/1-2-Switch)).

## 3. Tokens sugeridos (SDL, 1920×1080)

Tipografia: os tamanhos são em px; no SDL_ttf a 72 dpi, pt = px.

```
papel       fonte            tam/entrelinha  peso  uso
display     Space Grotesk    160/160         700   verbo do aviso, veredito final (caixa alta)
título      Space Grotesk     80/88          700   título de tela
subtítulo   Space Grotesk     56/64          500   nome da sala, nome no cartão
corpo       Space Grotesk     40/56          400   instrução (≤ 2 linhas); 40/64 no relatório
legenda     Space Grotesk     32/40          500   rótulo, dica de botão (piso)
número XL   JetBrains Mono   200             700   contagem 3-2-1
número L    JetBrains Mono    96             700   cronômetro
número M    JetBrains Mono    56             700   pontos no cartão
número S    JetBrains Mono    32             400   tabelas do relatório
```

- **Espaçamento:** 4, 8, 16, 24, 32, 48, 64, 96, 128. Margem segura de 96 px nas laterais e 56 px em cima e embaixo. Cartão: padding de 32; 16 entre itens, 48 entre blocos, 64 entre seções; calha de 40 a 48.
- **Raio** (escala do M3 multiplicada por 2): 8 em selo ou chip, 16 em botão ou campo, 24 em cartão, 32 em painel ou modal; pílula = metade da altura. Raio interno = raio externo menos o padding (proposta).
- **Traço:** borda de 2 px; foco de 4 px com 4 px de folga. Ícones em grade de 48 px com traço de 4 px, pontas e junções redondas e pelo menos 4 px entre traços (a regra do Lucide, 24 px com traço 2, dobrada).
- **Superfícies:** tela #21222c; painel #282a36; elevado #2f2f40; foco #343246; selecionado #3a374d; divisor #44475a. No modal, um véu #21222c a 80% (proposta), que é a única sombra do jogo.
- **Texto:** primário #f8f8f2; secundário a 60%; desabilitado a 38%; sobre acento, #21222c.
- **Estados** (camadas do Material 3): 10% em foco e pressionado; desabilitado com contêiner a 12% e conteúdo a 38%.
- **Movimento:** 100 ms para pressão de botão, 150 ms para foco, 250 ms para elemento entrando, 300 ms para cartão ou painel, 450 ms para troca de tela, 600 a 1.000 ms para o placar contando. Curvas: entrar (0,05; 0,7; 0,1; 1); sair (0,3; 0; 0,8; 0,15); padrão (0,2; 0; 0; 1).
- **Juice:**
  - pausa no impacto de 2 a 6 quadros (33 a 100 ms); de 9 a 15 quadros (150 a 250 ms) no lance decisivo; teto de 30 quadros;
  - flash de 1 a 3 quadros, cobrindo menos de 20% da tela, no máximo 3 por segundo;
  - tremor: trauma +0,2 num acerto e +0,5 num grande, decaindo 1,5 por segundo; deslocamento de 24 px × trauma² e rotação de 1° × trauma² (proposta);
  - partículas: de 12 a 24 por evento, com vida de 400 a 800 ms (proposta).

Uso das cores, coerente com a spec Drácula (erro = vermelho, inserido = verde, alterado = laranja, título = roxo, link = ciano):
- **Roxo #bd93f9:** foco, seleção, marca, botão primário e tinta de elevação. Nunca cor de jogador.
- **Ciano #8be9fd:** P1. No relatório, onde não há jogadores, marca valor medido.
- **Vermelho #ff5555:** P2. Falha ou perigo só com ícone e palavra. Nunca flash de tela cheia, nunca texto sobre #44475a.
- **Verde #50fa7b:** P3. "OK" só com ícone e palavra.
- **Rosa #ff79c6:** P4.
- **Laranja #ffb86c:** "ao vivo" (sensor lendo, microfone ouvindo, gatilho armado), com pulso de 1 Hz (proposta).
- **Amarelo #f1fa8c:** atenção: tempo de 10 s ou menos, recorde, controle desconectado.
- **#6272a4:** borda interativa, trilho de barra, texto de 52 px ou mais.

Se o número e o lugar do jogador não puderem ficar sempre visíveis, troque as cores de jogador para ciano, vermelho, amarelo e roxo. Essa combinação tem distância de cor mínima de 29 a 41 nos três tipos de daltonismo. Nesse caso, o foco passa a ser um anel #f8f8f2.

## 4. Fontes

- https://blog.playstation.com/2021/05/11/unpacking-returnals-ux-design-gameplay-first-ui-retro-futuristic-tech-and-accessibility/ — UX do Returnal
- https://blog.playstation.com/2021/05/13/how-housemarque-created-returnals-immersive-dualsense-controller-effects/ — gatilho e háptica do Returnal
- https://blog.playstation.com/2021/05/13/devs-reveal-their-upcoming-dualsense-wireless-controller-implementations/ — Kena, Life is Strange, Subnautica
- https://blog.playstation.com/2020/11/11/unleash-the-power-of-the-dualsense-wireless-controller-with-astros-playroom/ — roupas do Astro
- https://blog.playstation.com/2020/11/23/immerse-yourself-in-deathloop-on-ps5-with-the-dualsense-controller/ — Deathloop
- https://blog.playstation.com/2021/09/09/face-the-unknown-in-new-ghostwire-tokyo-trailer/ — Ghostwire
- https://www.videogameschronicle.com/news/ps5-developers-reveal-how-their-games-use-dualsenses-adaptive-triggers-and-haptic-feedback/ — Spider-Man: Miles Morales, Astro
- https://www.thegamer.com/astros-playroom-cooling-springs-ps5-gameplay-and-dualsense-impressions/ — sopro, areia, touchpad
- https://seekingtech.com/how-to-fix-unresponsive-microphone-input-in-astros-playroom/ — microfone mudo pula a seção
- https://caniplaythat.com/2020/12/07/astros-playroom-can-i-play-that-mobility-review/ — guia do controle, falta de opções
- https://onemoregame.ph/2024/09/astro-bot-director-nicolas-doucet-interview/ — háptica baseada em som
- https://www.thegamer.com/ratchet-clank-rift-apart-all-confirmed-guns/ — Enforcer
- https://www.gtplanet.net/gt7-dualsense-feel-abs-20200821/ — Yamauchi e o ABS
- https://racinggames.gg/article/how-to-change-dualsense-trigger-strength-in-gran-turismo-7 — força dos gatilhos no GT7
- https://kotaku.com/my-hands-don-t-like-ps5-call-of-duty-s-adaptive-trigger-1845670412 — fadiga no CoD
- https://www.bgr.com/2191746/what-playstation-5-controller-colors-mean/ — lightbar como vida
- https://www.gamepressure.com/resident-evil-village/wounds-how-to-heal/z5e664 — vida fora do HUD
- https://www.playstation.com/en-us/support/hardware/dualsense-controller-support/ — mudo laranja, luzes de jogador
- https://en.wikipedia.org/wiki/DualShock — número por LEDs
- https://en.wikipedia.org/wiki/Journey_(2012_video_game) — sem palavras, cachecol
- https://caneandrinse.com/thumper-interview/ — arte subtrativa
- https://en.wikipedia.org/wiki/Inside_(video_game) — cor mínima
- https://www.gamedeveloper.com/audio/-i-mini-motorways-i-and-the-delicate-art-of-marrying-complexity-and-minimalism — cor e forma
- https://www.dbltap.com/posts/hades-boon-rarity-guide-to-standard-and-special-boons-01ek30qqebzt — cores de raridade no Hades
- https://en.wikipedia.org/wiki/WarioWare — instrução de um verbo
- https://en.wikipedia.org/wiki/1-2-Switch — olhar o outro jogador
- https://www.imore.com/super-mario-party-beginners-guide — instrução e prática
- https://celiahodent.com/gamers-brain-ux-onboarding/ — aprender fazendo
- https://www.nicholassinger.com/blog/tetriseffect — sincronia entre sentidos
- https://medium.com/refactoring-ui/7-practical-tips-for-cheating-at-design-40c736799886 — hierarquia, menos bordas
- https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101 — texto (XAG 101)
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102 — contraste (XAG 102)
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103 — canais redundantes (XAG 103)
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/110 — háptica (XAG 110)
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117 — movimento (XAG 117)
- https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118 — fotossensibilidade (XAG 118)
- https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/ — 28 px
- https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-sounds-alone/ — informação não só no som
- https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html — foco
- https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html — 3 flashes por segundo
- https://developer.android.com/design/ui/tv/guides/styles/layouts — grade de TV
- https://developer.android.com/design/ui/tv/guides/styles/focus-system — foco na TV
- https://developer.android.com/develop/ui/compose/designsystems/material3 — elevação tonal
- https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/material/elevation_overlay.dart — degraus 5/8/11/12/14%
- https://codelabs.developers.google.com/codelabs/design-material-darktheme — opacidades 87/60/38%
- https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md — durações e curvas
- https://github.com/material-components/material-components-android/blob/master/docs/theming/Shape.md — raios
- https://m3.material.io/foundations/interaction/states/state-layers e https://github.com/kanso-labs/kanso-ui/issues/588 — camadas de estado (os valores conferidos pela issue)
- https://lucide.dev/contribute/icon-design-guide — traço de ícone
- https://spec.fm/specifics/8-pt-grid — grade de 8 pt
- https://spec.draculatheme.com/ — papéis das cores Drácula
- https://www.nngroup.com/articles/response-times-3-important-limits/ — tempos de resposta
- https://www.youtube.com/watch?v=AJdEqssNZ-U — Vlambeer, screenshake
- https://archive.org/details/GDC2016Eiserloh — trauma e tremor
- https://www.ssbwiki.com/Hitlag — fórmula da pausa no Smash
- https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ — Sakurai sobre a pausa no impacto
- https://www.gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it- — contra o excesso de juice
- https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html — simulação de daltonismo (Machado 2009)

Só material público: nada do SDK da Sony nem de documento sob NDA.