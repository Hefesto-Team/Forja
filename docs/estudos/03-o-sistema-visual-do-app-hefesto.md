# O sistema visual do app Hefesto

Estudo de 27/09/2026, lido do clone do Hefesto (só leitura): o `:root` de
`interface/topo.html`, as páginas, os mockups, o glossário da língua da casa,
os glifos e o logo. É a origem da cara do jogo — a paleta, Space Grotesk e
JetBrains Mono, os glifos, o mapa do controle, a borda na cor do lugar e a voz
das telas. A seção 7 foi escrita para o app 2D em SDL, que saiu do branch
([ADR-007](../adr/007-o-jogo-e-o-3d-em-godot.md)); no jogo 3D, a mesma
tradução mora no `Tema` e no `Desenho` do Godot.

## 1. Tokens de cor
Fonte: o `:root` de `interface/topo.html`. Os contrastes são medidos contra `--panel`.

| token | hex | papel |
|---|---|---|
| casa | `#11121a` | atrás da janela (`body`) |
| `--app-bg` | `#21222c` | fundo da janela e do rodapé; tudo o que fica "afundado": chip, botão de escolha, campo, moldura interna |
| `--panel` | `#282a36` | quadro ou cartão que flutua; base das medições |
| `--elevated` | `#2b2d3a` | balão da dica |
| `--linha` | `#53576f` | **a** borda estrutural, e a única: janela, quadro, chip, botão, tira de abas, rodapé, "?" (2,01:1) |
| `--border-forte` | `#44475a` | trilho de medidor e de slider, moldura interna, controle desconectado |
| `--border-sutil` | `#343746` | divisória interna; borda do inerte e do apagado (1,21:1) |
| `--sel-bg` | roxo a 16 % (`#403b55` sobre panel, `#3a344d` sobre app-bg) | interior do item escolhido |

**Níveis de texto:**
- `--fg #f8f8f2` (13,4:1): texto principal, valores, item escolhido.
- `--texto-suave #c8ccda` (8,9:1): dica, rótulo da fita, botão neutro, log.
- `--texto-mudo #9a9eb8` (5,4:1): item não escolhido, aba inativa, estado.
- `--comment #8896c4` (4,9:1): texto terciário ("Perfil ativo", fita inerte, separador `•`, contorno do Exportar).
- O rótulo de campo é verde (`--rot-campo`), o título de quadro é roxo e o lugar vazio usa `--linha`.

**Acentos (cada cor tem um trabalho só):**
- **Roxo `#bd93f9`:** seleção (borda roxa + `--sel-bg`), título de quadro, Salvar Perfil, preenchimento de slider e de bateria, anel de foco. Nunca aparece chapado em área grande.
- **Rosa `#ff79c6`:** a marca, o sublinhado da aba ativa e o nome do perfil ativo. Na tela viva, também o que o controle está fazendo agora: botão apertado, ponto do analógico, curso de L2/R2. Rosa não é seleção.
- **Verde `#50fa7b`:** confirma ou está ligado. Aplicar (cheio), rótulo de campo, selos OK/ATIVO, "1 USB · 1 BT", bateria %, pino ligado, piscada "deu certo", eixo positivo.
- **Laranja `#ffb86c`:** atenção. Importar, caixa tracejada de pendente, selo AJUSTAR, piscada "recusou", motor vibrando.
- **Vermelho `#ff5555`:** destrói. Remover, Parar o serviço, Restaurar de fábrica, eixo negativo. Só dá 4,5:1, por isso fica restrito a texto e traço.
- **Ciano `#8be9fd`:** informa. Valores, link pontilhado, toque no touchpad, onda do microfone, foco do "?".
- **Amarelo `#f1fa8c`:** só no logo.

**Quem não usa o quê:**
- `--linha` nunca pinta uma borda que carrega informação (plástico, estado `.on`, aba ativa, foco).
- `--border-*` nunca vira texto nem separador.
- Não se usa `opacity` para apagar texto, porque isso esconde o texto da régua de contraste. A única exceção é o estado "em voo".
- Nenhum hex fora dos tokens.
- Contraste mínimo: texto ≥ 4,5:1 contra o fundo real, traço de controle ≥ 3:1. Texto sobre acento cheio é sempre `#21222c`.

**Cores de plástico:**
- `--cosmic-red #ae335a`, `--nova-pink #e35b8c`, `--starlight-blue #7eb8d4`, `--galactic-purple #74588e`, `--midnight-black #606062`.
- Saem de `docs/data/cores-do-dualsense.csv` (28 modelos) e passam por `tom_para_a_borda`: se a cor ficar abaixo de 2,2:1 contra `#282a36`, ela é misturada com branco em passos de 5 % (por exemplo `#A51C48` vira `#ae335a`), sem aumentar a saturação.
- Viram uma borda de 2 px em **todo** lugar que mostra um controle: chip da fita, cartão da aba Jogar, card da aba Controles, contorno do DualSense desenhado. Também aparecem no anel do analógico, no anel "dono" dos botões de jogador e na faixa esquerda da linha da aba Perfis.
- A borda diz **qual** controle é; o interior diz o estado (lilás quando escolhido).
- Fita inerte e lugar vazio perdem a cor do plástico.
- Plástico não é lightbar.

## 2. Tipografia
- **Famílias:** Space Grotesk 400/600 na interface (700 só na marca, 500 no nome do cartão). JetBrains Mono 400/500 para dados (600 nos selos).
- **Tamanhos realmente usados** (px, contados no CSS publicado):
  - 9,5–10,5: selos, valores mono, "Perfil ativo"
  - 11–11,5: dica, texto de cartão
  - 12: chip, rótulo de campo (600)
  - 12,5: botão, segmentado, rodapé (600)
  - 13: aba
  - 13,5: título de quadro (600)
  - 14: marca (700)
  - 26: só o "L3/R3" dentro do analógico
  - Os mais frequentes são 12, depois 11, 11,5 e 12,5.
- **Quando usar mono:** dado lido do controle ou valor que se compara ou copia (`95%`, `200 / 255`, `+143.2`, `#7EB8D4`), log e selos.
- **Caixa:**
  - Inicial maiúscula só na primeira letra da frase ("a maiúscula a regra é sobre a primeira letra", 30/08).
  - `text-transform` é proibido; o portão `check_a_maiuscula_decorativa.py` reprova.
  - Caixa alta só em sigla (USB, BT, L2) e no texto dos selos.
  - O versalete espaçado dos canvases de julho não entrou no produto.
  - Espaçamento de letras: −0,01em, só na marca.
- **Escala +3 px:** é do tema GTK antigo (`app/theme.py`, `ESCALA_PADRAO = 3`). Ela soma 3 px a todo `font-size`, com os degraus Compacto 0, Normal +3 e Grande +6 (teto 8, piso 11, então nada fica abaixo de 14 px na tela). A interface HTML atual não aplica zoom nenhum. O número serve como medida do que a mantenedora lê de perto.
- **Arquivos de fonte:** não há nenhum no clone. `assets/fonts` não existe, e o NOTICE confirma. `scripts/install_fonts.sh` instala pelo pacote da distro ou baixa de `google/fonts@7ff85c87…` conferindo SHA-256 (os hashes batem). Licença OFL 1.1, sem nome reservado.

## 3. Componentes (medidas do desktop, em px)
- **Janela:** raio 10, borda 1 `--linha`, sombra `0 18 50 rgba(0,0,0,.45)`. Largura até 1600; altura `clamp(777, 100dvh−32, 855)`, a mesma nas dez abas.
- **Quadro:** raio 9, borda 1 `--linha`, fundo panel, preenchimento e vão de 14. Título 13,5/600 roxo, seguido de "?". O quadro não estica para preencher a janela.
- **Alturas fixas:** botão de escolha 36, botão de ação 34, coluna de rótulo 92.
- **Rodapé:** preenchimento 6/18, borda superior 1 `--linha`. Os botões ficam à direita, com altura 34, raio 7 e texto 12,5/600:
  - **Aplicar:** verde cheio, texto `#21222c`.
  - **Salvar Perfil:** contorno e texto roxos.
  - **Importar:** contorno e texto laranja.
  - **Exportar:** contorno `--comment`, texto mudo.
  - Não há frase no rodapé.
- **Botão contornado (`.btn`):** altura 34, raio 7, borda `--linha`, fundo transparente, texto suave. A cor do papel fica **na palavra** (verde liga, vermelho desliga, roxo guarda) e só vai para o contorno no hover.
- **Segmentado, degrau e o par Ligado/Desligado:** altura 36, raio 7, borda `--linha`, fundo app-bg, texto mudo.
  - Hover: borda `--comment`.
  - Escolhido: borda roxa, interior `--sel-bg`, texto `--fg` 600.
  - O pino de "ligado" é verde e tem brilho.
- **Estados:**
  - **Apagado:** borda sutil, texto mudo, e um "?" ao lado com o motivo.
  - **Em voo:** opacidade .6, com rótulo em gerúndio opcional ("Atualizando…").
  - **Deu certo / recusou:** borda + `outline` de 1 px, verde ou laranja, por 1500 ms. Nenhuma palavra entra na tela e nada muda de lugar.
  - **Pendente:** caixa tracejada laranja, fundo laranja a 7 %.
- **Abas:** texto 13, cor muda. A aba ativa fica `--fg` 600 com sublinhado **rosa** de 2 px.
- **Chip da fita:** altura fixa de 30, raio 6. Borda 1 `--linha`; quando o chip é um controle, a borda passa a 2 px na cor do plástico. Escolhido: interior `--sel-bg`, e a borda do plástico continua.
- **Cartão de jogador:**
  - Raio 7, borda 2 na cor do plástico, fundo app-bg.
  - Texto: "Sony • Player 1 / Cosmic Red • USB / 100%", com a bateria em verde mono.
  - Quando é o alvo: interior `--sel-bg`.
  - Lugar vazio: borda sutil e travessão, sem desenho do controle.
- **Selos:**
  - `.selo`: mono 10,5/600, raio 4, fundo cheio com texto `#21222c`. Verde para "✓ OK" e "✓ LIGADO", laranja para "AJUSTAR", `--comment` para "i NOTA".
  - `.selo-ativo`: 9,5; "ATIVO" em verde, desligado em `#44475a`.
  - `[ OK ]`/`[INFO]`/`[FAIL]` (mono verde/ciano/vermelho) é o formato de log da paleta e da aba Sistema antiga. No produto atual ele virou selo cheio.
- **Chaves:**
  - Ligada: pílula com borda e texto verdes, fundo verde a 9 % e pino com brilho.
  - Interruptor: trilho 28×15, bolinha de 9. Ligado: interior `--sel-bg`, borda e bolinha roxas.
- **Medidores:**
  - Bateria: trilho de 6 em `#44475a`, preenchimento roxo, número mono.
  - Gatilho: trilho de 8, preenchimento rosa, "200 / 255" acima.
  - Eixo: sai do centro; positivo verde, negativo vermelho.
  - Onda segmentada: 14 barras de 18 px, vão 2, em ciano.
  - Slider: trilho de 5, preenchimento roxo, puxador de 12.
  - LEDs de jogador: cinco quadrados de 6 px no padrão 1|vão|3|vão|1; aceso `#e8ecf5` com brilho.
- **Cabeçalho:** uma linha só (a faixa própria saiu em 10/09).
  - À esquerda: logo de 44 px e o nome em duas linhas, 14/700: "Hefesto" em **rosa** e "DualSense**4**Unix" em `--fg`, com o "4" **verde**.
  - Depois: "Selecionar:" e os chips.
  - À direita: "● 1 USB · 1 BT" em verde e "Perfil ativo" com o nome em rosa.
- **"?":** círculo de 17 com borda `--linha`; fica ciano no foco. O balão tem 330 de largura, fundo elevated e texto 11,5 suave. Abre também com foco, não só com o ponteiro.
- **Glifos (`assets/glyphs`, 27 pares):**
  - Grade de 32, traço 2, pontas redondas, só contorno (setas e PS são cheios).
  - No arquivo: `#f8f8f2` no normal, roxo no `_active`.
  - Na página viram `currentColor`, com 24 a 38 px: suave em repouso, cor do plástico quando pertencem ao controle, rosa com brilho quando apertados.

## 4. O logo
- **Composição** (`assets/hefesto-logo.svg`, 200×200, sem fundo):
  - **Anel aberto:** raio ≈94, traço 6, pontas redondas, cerca de 326°. A abertura fica no alto à direita, entre duas bolinhas de raio 5: ciano `#8be9fd` às 12 h e rosa `#ff79c6` perto de 1 h. O degradê vai do rosa (alto à esquerda) ao roxo e depois ao ciano (baixo à direita).
  - **Chama:** dupla, roxo→rosa por fora e laranja→amarelo por dentro, com o grupo inteiro a 19 % de opacidade.
  - **Bigorna:** tampo `#f8f8f2` com o chifre para a direita, cintura `#bd93f9`, base `#6272a4`.
  - **Martelo:** cabo `#ffb86c`, cabeça `#909090`, na diagonal.
  - É a direção "2a Síntese" do canvas de logos, redesenhada por ela.
- **No cabeçalho:** 44 px, sem disco de fundo.
- **Armadilha:** o anel e o martelo são girados com `transform-origin` de CSS, que o librsvg ignora. A geometria já resolvida está em `logo_hefesto_rascunho.h`, conferida lado a lado com o original no Chrome.
- **Licença:** o repositório é MIT ("Hefesto Contributors"); só `assets/dkms` é GPL. O NOTICE diz que os glifos são "desenho próprio do projeto", e o logo não tem ressalva nenhuma. O Forja também é MIT, então nada impede o reuso. A única obrigação é levar o aviso MIT junto se copiar o desenho.
- **Ressalvas:**
  - `ps.svg` é o logotipo PlayStation: a MIT cobre o desenho, não a marca da Sony.
  - Os nomes das cores ("Cosmic Red" etc.) são da Sony.
  - A decisão de 29/08 fala em "GPL3", mas nada foi relicenciado.

## 5. A voz
- **Regras do glossário:** cada palavra tem um significado só. A coluna "na tela" do glossário manda no texto de tela. A frase vem do dono do assunto (`app/actions/*`) e não inventa termo.
- **Palavras preferidas:** controle; P1…P4 (o número é o lugar do jogador, não o aparelho); USB/BT; os controles, todos; serviço; barra de luz, LEDs de jogador; gatilho, efeito, motor forte/fraco; Ligado/Desligado; "apagado" no sentido de "não dá para mexer agora".
- **Banidas no texto de tela:**
  - Palavras: `env`, `vdf`, `uinput`, `hidraw`, `MAC`, `uniq`, `wrapper_used`, `dedup`, "mesa", "janela do aplicativo", "linha de comando", `reconciliad…`, `compactada`.
  - Trechos: "derrubam o controle", "resultado é ZERO", "gatilhos ficam duros", "foram renumerados".
  - Qualquer frase que mande procurar um botão ou uma janela que não existe.
  - Qualquer alarme sem medição.
- **Tom:** curto e concreto. Diz o estado medido e nunca prevê consequência.
- **Pessoa verbal:** fala com "você" e usa imperativo nas ordens ("Mova o adaptador Bluetooth para a Entrada 9"). O produto fala de si em 3ª pessoa ("o Hefesto navega o computador").
- **O que fica na tela:** só título, rótulo e estado. Toda explicação vai para o "?".
- **Erro e sucesso:**
  - Sucesso: piscada verde, sem palavra.
  - Recusa: piscada laranja; a frase vai para o registro ("[gesto falhou] …"), não para a tela. Vale desde 13/09; o glossário ainda cita recados que já caíram.
  - Quando metade do gesto deu certo, a frase diz as duas metades.
  - A coluna Atenção mostra até 3 avisos + "+N", e só o que pede ação.
  - Lugar vazio mostra travessão, nunca dado inventado.
- **No app 2D, contra essa regra (no dia do estudo; o jogo 3D já segue a voz):**
  - "ninguém na mesa" (`salas/sala_base.c:508`), "voltou à mesa" (`nucleo/pads.c:313`), "Ninguém na mesa…" (`cenas/hub.c:485`).
  - "uinput" em `nucleo/origem.c:34-40`, que chega à tela por `cenas/diagnostico.c:151`.

## 6. Decisões da mantenedora
- **26/08:** a borda grossa é sempre a cor do plástico; escolher pinta só o interior, de lilás ("Deixa lilás. Confundi").
- **26/08:** as bordas aparecem "como se fossem personagem de jogo"; quem aperta o botão é quem recebe o ajuste.
- **26/08:** só título, rótulo e estado ficam na tela; o resto vira dica.
- **26/08:** dois controles nunca ficam com a mesma cor.
- **27/08:** o rótulo de um controle é "P1 • Cosmic Red • USB" ("tira o Sony").
- **27/08:** a janela tem uma altura só, e o quadro não estica.
- **30/08:** `--comment` passou de `#6272a4` para `#8896c4` e `--texto-mudo` de `#8b8fa8` para `#9a9eb8`. Mudou só a luminância, com piso de 4,5:1.
- **30/08:** rótulos de campo em verde ("deixa verde os nomes"); título do quadro continua roxo.
- **30/08:** maiúscula só na primeira letra da frase.
- **31/08:** uma borda estrutural só, `#53576f` ("menos perceptíveis mas presentes e modernas").
- **31/08:** no botão secundário a cor vai na palavra, não no contorno.
- **31/08:** nenhum alarme sem medição.
- **04/09:** lugar vazio não desenha controle; botão ocupado mostra que está trabalhando.
- **05/09:** o campo pisca verde por cerca de 1,5 s, sem mover nada e sem palavra nova.
- **06/09:** a palavra "mesa" sai da tela.
- **08/09:** a janela estica, com teto de 1600.
- **10/09:** a faixa de cabeçalho saiu.
- **11/09:** nenhuma caixa alta decorativa.
- **13/09:** a recusa pisca e não fala.
- **21/09:** "USB e BT é muito bom"; logo de 44 px.
- **24/09:** "Reconectar" não mostra frase; o número novo aparece no próprio cartão.

## 7. Tradução para o jogo (o app 2D em SDL, tela lógica 1920×1080)
- **Fator ×2** em comprimento, raio, traço e fonte.
  - A conta: 12,5 px vistos a 60 cm num monitor de 24" ocupam ≈0,33°. Numa TV de 55" a 2,5–3 m, o mesmo ângulo pede de 23 a 27 px.
  - O fator bate com os +3 px que a mantenedora pediu e com o `F_TEXTO` 28 que o Forja já usa.
  - Pisos: texto ≥ 24 px, selo ≥ 22 px, traço ≥ 2 px.
- **Cores:** `SDL_Color` com os mesmos hex; `--sel-bg` é o roxo com alfa 41.
  - Tarjas do letterbox em `#11121a`; fundo da tela em `#21222c`.
  - Quadro: `ds_ret_arred(r=18, #282a36)` + `ds_contorno_arred(r=18, esp=2, #53576f)`, preenchimento 28, título 28/600 roxo.
- **Componentes:**
  - Botão: altura 68, raio 14. Segmentado: altura 72.
  - Chip: altura 60, raio 12. Cartão: raio 14, borda de identidade de 4 px.
  - Aba: texto 26 com sublinhado rosa de 4. Selo: mono 22/600, raio 8.
  - Glifo: 48 px com traço 3, desenhado com `ds_polilinha`; brilhos com `ds_brilho`.
  - O resto segue os números da seção 3 multiplicados por 2.
- **Hover vira foco.** Cada controle tem seu próprio anel de foco: 4 px, afastado 4 px, na cor do jogador que está navegando. O roxo fica reservado para o item escolhido. O "?" abre quando recebe foco.
- **Identidade do jogador:**
  - O Forja não tem como ler a cor do plástico: isso exige o feature report 0x80/0x81, que não está no CONTRATO.
  - Por isso a borda de identidade usa a cor de lightbar de cada jogador, passada por `tom_para_a_borda` (`#0000ff` vira `#4040ff`).
  - Colisões com os acentos: verde (P3) com a piscada "deu certo", vermelho (P2) com "perigo", rosa (P4) com a marca. Solução: a piscada vai num anel externo, e o veredito sempre leva selo com palavra.
- **Piscada e em voo:** anel extra de 2 px por 1500 ms; "em voo" é alfa .6.
- **Fontes:** o `stb_truetype` ignora os eixos de fonte variável (`gvar`), e as fontes do repositório são variáveis. Sem correção, o Space Grotesk sairia sempre no peso 300. É preciso colocar no Forja arquivos estáticos 400/600/700, junto com o texto da OFL. Elas substituem a Atkinson Hyperlegible, que foi escolhida para baixa visão; os pisos acima compensam.
- **Logo:** 88 px no cabeçalho. Anel com `ds_arco` em fatias, interpolando a cor; bolinhas com `ds_circulo`; bigorna e martelo com `ds_poligono`; chama desenhada a 19 %.
- **Título do jogo:** "Hefesto" em rosa + "Tech Demo" em `--fg`, peso 700. Sem versal e sem inventar um "4" verde.
- **Não copiar:** a coluna "ID da peça" (`AA:BB:…`) da aba Perfis. O contrato do Forja identifica por player index, nunca por endereço.
