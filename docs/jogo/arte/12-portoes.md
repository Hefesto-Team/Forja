# 12 Os portões

As regras de arte que um script confere sozinho. Cada portão diz o que lê, o
que reprova e o limite. Quem escreve o script é o arquiteto e DevOps
([papéis](../o-time/papeis.md#o-arquiteto-e-devops)); este arquivo é a
especificação.

## Como todo portão funciona

- **Roda no CI e no `scripts/ci-local.sh`**, antes de todo push, e sai com
  código 1 quando reprova.
- **Diz o arquivo e a linha** de cada defeito, e a regra desta página que ele
  quebrou (o número do portão).
- **Morde a si mesmo:** como a `tests/prova_sem_rastro.sh`, cada portão monta
  um caso de mentira com o defeito que diz pegar e confere que reprova. Portão
  que passa com o defeito dentro não mede nada.
- **A catraca:** onde o jogo de hoje ainda tem o defeito (a paleta Drácula, as
  fontes do app), o portão grava a contagem de hoje e reprova só se ela
  **subir**. Quando a ficha que limpa o defeito entra, a catraca vai a zero e
  o portão passa a bloquear tudo. O arquivo da catraca fica onde o arquiteto
  decidir (proposta: `tests/portoes/catraca_arte.json`).
- **Os tokens** vêm de `godot/scripts/tema.gd` depois da G14. Até lá, a fonte
  da verdade é `godot/estudos/direcao/fita.gd`.
- **Fora do alcance:** `godot/estudos/` (os quadros fixam um jogador de
  propósito), `oficina/`, `.godot/`, os `.import`.

## Os portões

| # | portão | modo hoje | a contagem de hoje |
| --- | --- | --- | --- |
| 1 | cor só por token | catraca | 102 `Color("#`, 1 `Color8(`, 19 `Color(` com número, fora de `tema.gd` |
| 2 | só as quatro fontes | catraca | 2 (Space Grotesk e JetBrains Mono em `tema.gd`) |
| 3 | cor de jogador só no jogador | catraca | a medir na primeira rodada |
| 4 | texto mínimo | bloqueia | 0 |
| 5 | contraste | bloqueia | 0 |
| 6 | emissivo com dono | catraca | 17 materiais com `emission_enabled`, 6 com energia acima de 1,0 |
| 7 | na batida | aviso até a F06 | depende do registro v2 |
| 8 | sem emoji na tela | bloqueia | 0 |

As contagens foram medidas em 08/10/2026 com `grep` em `godot/scripts/`.

### 1 Cor só por token

**Lê:** todo `.gd`, `.tscn`, `.tres` e `.svg` dentro de `godot/`, menos
`tema.gd` e `fita.gd`.

**Reprova:**

- `Color("#...")`, `Color8(...)`, `Color(r, g, b)` ou `Color(r, g, b, a)` com
  número em `.gd`;
- em `.tscn` e `.tres`, um `Color(r, g, b, a)` cujo r, g, b não é um token
  (tolerância de 1/255 por canal);
- em `.svg`, um `fill` ou `stroke` cujo hex não é um token.

**Passa:**

- `Tema.NOME`, `Tema.JOGADOR[lugar]`, `Tema.SECAO[secao]`;
- `Color(Tema.NOME, a)`: um token com opacidade;
- `Tema.NOME.darkened(k)` e `.lightened(k)` com k até 0,15 (a trama da
  cortina usa 0,12);
- `Color.WHITE` e `Color(1, 1, 1, a)` como `modulate` de textura;
- `Color(0, 0, 0, 0)`, o transparente.

### 2 Só as quatro fontes

**Lê:** todo `.gd`, `.tscn` e `.tres` em `godot/`, e a pasta
`godot/assets/fontes/`.

**Reprova:** uma referência a `.ttf`, `.otf`, `.woff` ou `.woff2` que não é
`Bungee-Regular.ttf`, `VT323-Regular.ttf`, `ArchivoNarrow-wght.ttf` ou
`PermanentMarker-Regular.ttf`; um `SystemFont`; depois da G14, um arquivo de
fonte na pasta que não é um dos quatro.

### 3 Cor de jogador só no jogador

**Lê:** os `.gd` de `godot/scripts/`, e as fotos da prova visual (F09) das
telas sem jogador: o título antes de qualquer controle entrar, a pausa e o
fim da fita.

**Reprova:**

- `JOGADOR[0]` a `JOGADOR[3]` (ou `COR_DO_LUGAR[n]`) com índice escrito em
  número, fora de `tema.gd`: a cor de um jogador vem sempre de uma variável de
  lugar;
- o hex de uma cor de jogador em qualquer arquivo fora de `tema.gd` (o
  portão 1 já pega, este diz o motivo);
- nas fotos das telas sem jogador, mais de 0,05 % dos pixels a menos de 0,06
  de ΔE OKLab de uma cor de jogador e com croma acima de 0,08.

### 4 Texto mínimo

**Lê:** os `.gd`, `.tscn` e `.tres` de `godot/`.

**Reprova:** um tamanho de letra abaixo de 30, escrito como número em
`Tema.t(n)`, `font_size = n`, `add_theme_font_size_override(..., n)`,
`theme_override_font_sizes/font_size = n`, nos `T_*` de `tema.gd`, ou no
argumento de tamanho de `draw_string` e `draw_multiline_string`. O
`Label3D.font_size` conta pelo tamanho na tela, não pelo número: fica fora
deste portão e entra na prancha.

### 5 Contraste

**Lê:** [dados/contraste.csv](dados/contraste.csv) e os tokens.

**Reprova:**

- um par da tabela com `uso` = texto cuja razão WCAG 2.1, recalculada dos
  tokens, fica abaixo de 4,5 (tamanho mínimo abaixo de 48 px) ou de 3,0 (48
  px ou mais, e símbolo);
- uma razão gravada na tabela que difere da recalculada em mais de 0,05: a
  tabela envelheceu e o 02 precisa ser refeito;
- um par de cores de jogador com ΔE OKLab abaixo de 0,12 em qualquer das
  quatro visões (normal, protanopia, deuteranopia, tritanopia, matrizes de
  Machado 2009), como no [10](10-acessibilidade.md#o-daltonismo-a-cor-nunca-sozinha).

### 6 Emissivo com dono

**Lê:** os `.gd`, `.tscn` e `.tres` de `godot/`.

**A forma no jogo:** todo material que brilha nasce de três funções de
`tema.gd`, e cada uma pede o dono: `Tema.neon(cor, energia, dono)`,
`Tema.contorno(cor, largura, energia, dono)` e `Tema.emissivo(material,
energia, dono)`. O dono é um lugar (0 a 3), `"mundo"` ou `"forja"`. A função
recusa a energia acima do teto do dono ([07](07-vfx.md#o-que-conta-como-brilho)).

**Reprova:**

- `emission_enabled`, `emission_energy_multiplier` ou `emission =` escritos
  fora de `tema.gd`;
- uma chamada a `Tema.neon`, `Tema.contorno` ou `Tema.emissivo` sem o
  argumento do dono;
- uma energia escrita em número acima do teto do dono escrito em texto
  (`"mundo"` acima de 1,2, `"forja"` acima de 2,4, um lugar acima de 3,0);
- um `ShaderMaterial` com o shader `neon` ou `contorno` montado à mão.

### 7 Na batida

**Lê:** o registro da sessão (F06, o registro v2) de uma partida pelo robô,
na prova do jogo. Os eventos `contato`, `corte`, `carimbo` e `transicao`, com o
instante pelo relógio de áudio e o BPM da faixa.

**Reprova:** um evento a mais de 16,7 ms (1 quadro) da subdivisão da grade
que ele declara (tempo, colcheia, semicolcheia), em mais de 1 % dos eventos da
partida; ou um único `corte` fora do tempo 1 por mais de 16,7 ms.

Até o registro v2 existir, o portão só avisa.

### 8 Sem emoji na tela

**Lê:** `godot/scripts/traducoes.gd` e toda string literal dos `.gd` de
`godot/scripts/`.

**Reprova:** um caractere nas faixas U+1F000 a U+1FAFF ou U+2600 a U+27BF, e o
seletor de variação U+FE0F. **Passam** os símbolos de botão que a voz do texto
usa: ✕ (U+2715), ◯ (U+25EF), △ (U+25B3), □ (U+25A1) e as setas ◀ ▶ ▲ ▼.

## O que fica com outra cabeça

- **O formato do som** (48 kHz, mono, pico, rampas, teto de duração por
  prefixo): a regra é do [03 O som](03-som.md#o-formato) e do diretor de som;
  o script é `gerar_sons.py --conferir`.
- **A maiúscula no texto de tela**: já existe, `scripts/check_texto_de_tela.py`
  ([06 Telas](../06-telas-e-fluxo.md#a-voz-do-texto)).
- **O clarão** (20 % da tela, 3 por segundo): a medida é
  `scripts/medir_clarao.gd`; vira portão quando a prova visual (F09) fotografar
  os quadros de pico. Até lá, entra na prancha.
