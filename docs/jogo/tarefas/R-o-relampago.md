# R — O Relâmpago

**Sprint:** R · **Slot:** RELAMPAGO · **Tamanho:** G · **Depende de:** H04 e H08 (o kit, `momento()`, `_joga_o_minigame`), F09 (`Forja.robo_temperamento` e `Forja.robo_acerta()`), H07, G03, G05 (a lente de 35 mm), G13 (o cavaleiro montado), G14 (os tokens de cor), G15 (a luz da seção e o brilho com dono), V05 (os sons pelo mapa), as seções I a Q prontas (os 45 no catálogo), Q4 e Q5 (as estações que se copiam), O2 (a pedra), P1 (o ouvido)

## Por quê

Um modo à parte, no estilo WarioWare: microjogos de 5 a 8 segundos tirados
dos 45, um atrás do outro, sem tela de carregamento, cada vez mais densos.
Cada carta mostra o objeto do minigame de origem e joga o verbo dele: o
aquecimento vira o trailer da noite (três vidas) e o desempate vira morte
súbita entre os empatados (uma vida).

## Ler antes

- [03 — O Relâmpago](../03-os-45-minigames.md#o-relâmpago) (a regra de origem)
- [O molde de minigame](molde-de-minigame.md) (a FICHA, os ganchos, o kit e a chave `microjogo`)
- [A diversão do R](../diversao/R-o-relampago.md) (o grito, a cena por carta, a sombra)

O resto (a bíblia de arte, o mapa do áudio, a régua da diversão, o RPG, as
estações da Q4 e da Q5) já está copiado nesta ficha, com os números.

## Arquivos que mudam

| arquivo | o quê | de todos? |
| --- | --- | --- |
| `godot/scripts/minigames/relampago.gd` e `.uid` | novo: o minigame inteiro («Os ganchos») | só desta |
| `godot/scripts/minigames/catalogo.gd` | `"RELAMPAGO"` em `MINIGAMES` (fora de `SECOES`); `"relampago": "RELAMPAGO"` em `NOMES_VELHOS` | **de todos**: acrescente as duas linhas, não reordene |
| `godot/scripts/minigames/minigame.gd` | `"momento"` em `TIPOS_DO_JOGO` e a função `momento()` (a da L1, copiada em «A diversão») | **de todos**: se a L1 ou outra ficha já pôs, não escreva de novo |
| `godot/scripts/partida.gd` | `static var relampago_desempate`, `var desempate`, `_acima`, `_criterio`, `empate_no_topo()`, `empatados_no_topo()` | só desta |
| `godot/scripts/ui/escolha_partida.gd` | `[0, "Relâmpago", "Uns 3 min"]` em `TAMANHOS`; `var tamanho := 2` (era 1: o padrão continua «5 salas»); o `_draw` com `n == 0` | só desta |
| `godot/scripts/musica.gd` | a linha `"MUS_RELAMPAGO": [60, 160, 2]` em `FAIXAS` (Dó, 160 bpm, energia 2): a faixa sintetizada até a gerada chegar | **de todos**: acrescente a linha, não reordene |
| `godot/scripts/main.gd` | `_comecar_a_partida(0, …)`, `_seguir_a_partida()`, `_ao_terminar_a_sala()` | **de todos**: só as linhas de «O aquecimento e o desempate» |
| `godot/scripts/traducoes.gd` | as chaves de «Traduções» | **de todos** |
| `godot/testes/prova_do_jogo.gd` | `_prova_do_relampago()`, `_prova_do_relampago_inteiro()`, a linha `"RELAMPAGO"` no `match` de `_prova_da_ficha` e a conta da partida | **de todos** |
| `godot/testes/captura_jogo.gd` | a entrada `"relampago"` em `momentos` | **de todos** |
| `docs/jogo/13-arquitetura.md` | `RELAMPAGO` no catálogo, `relampago_desempate` e `desempate` da `Partida`; a linha `momento` na tabela dos eventos (se ainda não existe) | **de todos** |

O `.uid` novo (`relampago.gd.uid`) sai do import:
`"$GODOT" --headless --path godot --import --quit`, e entra no commit.

**Com a S (a outra ficha do lote):** nenhum arquivo em comum. A S só lê a
linha `momento` que a R grava.

## Como se joga

### A ficha de dados

O Relâmpago é um `Minigame` como os outros (o kit dá o relógio, o
julgamento, o registro e o fechamento), fora das seções:

```gdscript
const FICHA := {
	"slot": "RELAMPAGO",
	"titulo": "O Relâmpago",
	"verbo": "Rápido!",
	"genero": "sobrevivencia",
	"icone": "botoes",
	"entradas": [Forja.CRUZ, Forja.L1, Forja.R1],
	"camera": "fixa",
	"faixa": "MUS_RELAMPAGO",
	"duracao": 0.0,
	"fim": "ultimo_em_pe",
	"sensacoes": ["acerto", "perfeito", "erro", "golpe", "golpe_esq", "golpe_dir", "explosao", "aviso"],
	"material": "metal",
	"microjogo": {"verbo": "Rápido!", "segundos": 6.0},
	"gesto": "attack-melee-right",
	"treino": false,
	"corpo": false,
}
```

`"corpo": false` diz que nenhum stat do cavaleiro age aqui (o gancho de stat
futuro lê esta chave e devolve o neutro).

### O baralho

No `iniciar_jogo()`, o Relâmpago lê a ficha de cada minigame do catálogo
**sem instanciar** o minigame:

```gdscript
for slot in Catalogo.MINIGAMES:
	if slot == "RELAMPAGO":
		continue
	var f: Dictionary = (Catalogo.MINIGAMES[slot] as Script).get_script_constant_map().get("FICHA", {})
	if f.has("microjogo") and f.has("icone"):
		_baralho.append({"slot": slot, "secao": slot.substr(0, 3), "titulo": f.titulo,
			"verbo": str(f.microjogo.verbo), "segundos": clampf(float(f.microjogo.segundos), 5.0, 8.0),
			"icone": str(f.icone), "mecanica": MECANICA_DO_ICONE.get(str(f.icone), BATER),
			"material": str(f.material)})
```

**A ordem:** as cartas de cada seção embaralhadas com o `rng` do kit; as
seções numa ordem embaralhada; e o baralho montado **uma de cada seção por
volta** (a 1ª carta de cada seção, depois a 2ª...), sem duas da mesma seção
em seguida. Três minutos passam pelas nove seções duas vezes.

### A mecânica de cada carta

Vem do `icone` da ficha (o recurso do controle que ela usa); o verbo na tela
é o do `microjogo` dela:

| `icone` | a mecânica (`MECANICA_DO_ICONE`) | o gesto | de onde se copia |
| --- | --- | --- | --- |
| `botoes` | `BATER` | ✕ em cada nota | a estação 1 da Q4 |
| `analogicos` | `MARCHAR` | o analógico esquerdo para a esquerda (notas pares) e para a direita (ímpares), além de ±0,7 | novo: cruzar o limite, como o R2 da Q1 |
| `gatilhos` | `APERTAR` | L2 (pares) e R2 (ímpares) cruzando 0,6 | o pulso da Q2 |
| `giroscopio`, `acelerometro` | `INCLINAR` | inclinar contra o lado mostrado | a estação 2 da Q4 |
| `touchpad` | `TRACAR` | deslizar para a seta | a estação 3 da Q4 |
| `vibracao` | `DEFENDER` | L1/R1 do lado que a mão sentiu (a pista **meia** batida antes) | a estação 4 da Q4 |
| `gatilho_adaptativo` | `PUXAR` | o R2 em `ARMA` (2, 6, 8) até o clique | a estação 1 da Q5 |
| `alto_falante` | `REPETIR` | o controle canta duas notas; repita no ✕ | a estação 2 da Q5 |
| `haptica` | `SENTIR` | ✕ na pedra, nada na neblina | a estação 3 da Q5 (a O2) |
| `microfone` | `SOPRAR` | um sopro de 2 batidas | a estação 4 da Q5 (a P1), com a nota longa |

Nas 45 fichas de hoje, o `icone` é um destes 11 (o `acelerometro` em 1). Se
uma ficha escrever o nome do glifo em vez da parte, vale o mesmo: `cross`,
`stick_l`, `l2`, `r2`, `rumble_esquerdo`, `rumble_direito`, `alto-falante` e
`mic` estão no `MECANICA_DO_ICONE` («Os ganchos»). Ícone desconhecido: `BATER`.

Todos jogam o mesmo microjogo **ao mesmo tempo** (é individual; não há
hoqueto aqui): cada lugar vivo tem as mesmas notas.

### O fluxo de um microjogo

A faixa é `MUS_RELAMPAGO`, 160 bpm (uma batida = 0,375 s). `ENTRADA := 4`
(se o kit tiver `BATIDA_DA_PRIMEIRA_NOTA`, use-a). Enquanto o OGG gerado e
conferido não existe, o `Musica.mapa("MUS_RELAMPAGO")` lê a linha de
`FAIXAS` que esta ficha acrescenta (`bpm_sintetizado(160)` dá 160 exato);
sem ela, o mapa cai em 120 bpm e silêncio, e o teto vira 242 s. A faixa
gerada (120 s) e a sintetizada tocam em laço (`musica.gd`, `_ogg`: todo
`MUS_` fora de `MUS_S` volta ao zero), e o `Ritmo` conta as voltas: o tempo
de música segue subindo até o teto.

Um microjogo começa na batida `m0` (o primeiro em `ENTRADA`):

| batidas | o que acontece |
| --- | --- |
| `m0` a `m0 + 1` | **o cartão:** o verbo gigante e o glifo do recurso; o objeto da carta aparece na raia de cada vivo; a luz vai à da seção da carta; na batida `m0 + 1`, a assinatura no controle («O controle») |
| `m0 + 2` a `m0 + 2 + W − 1` | **a janela:** as notas |
| `m0 + 2 + W` | **o resultado:** quem passou faz `emote-yes`, quem não passou `emote-no` e perde uma vida |

- **A janela:** `W = maxi(4, roundi(segundos * 160.0 / 60.0 * fator)) - 3`
  batidas, com `fator = maxf(0.6, 1.0 - 0.1 * nivel)`.
- **O nível** sobe **a cada cinco microjogos** (`nivel = _i / 5`): a janela
  encolhe e as notas se apertam: `ESPACO := [2.0, 1.5, 1.0, 1.0]` batidas
  entre notas pelo nível (o último vale dali em diante). Na subida, o cartão
  diz `"Mais rápido!"` antes do verbo.
- **As notas:** `max(2, floor((W - 1) / espaco))` notas, a primeira em
  `m0 + 3`, espaçadas por `espaco`. Três mecânicas são diferentes:
  - `REPETIR`: o canto nas duas primeiras batidas da janela, a resposta nas
    duas seguintes (duas notas; as batidas que sobram ficam vazias);
  - `SENTIR`: cada batida de nota tem pedra com 60% (o `rng`); as notas são
    só as de pedra;
  - `SOPRAR`: cada nota é um sopro de 2 batidas (0,75 s); as notas ficam a
    cada 3 batidas, `max(2, floor((W - 1) / 3.0))` notas; a nota passa com a
    voz acima de `VOZ_ACIMA` por 0,6 s ou mais dentro das 2 batidas. Sem
    microfone, a nota passa sozinha (a régua, lição 16).
- **O julgamento:** o do kit, `julgar_toque(l, t(bn), n)`; o erro de cada
  mecânica é o da estação de origem (o lado errado, a direção errada, o ✕ na
  neblina).
- **Passar:** o lugar passa o microjogo se acertou (sem erro) pelo menos
  `ceili(PASSA * notas)` notas, com `PASSA := 0.6`.
- **Todos falharam:** com **2 ou mais vivos**, se todos os vivos falharam o
  mesmo microjogo, ninguém perde vida e a sala grita («A diversão»). Com 1
  vivo, ele perde a vida normalmente.
- **As vidas:** `VIDAS := 3` no aquecimento, `1` no desempate. Sem vidas, o
  lugar vira sombra (abaixo) ou sai (`acabou[l] = true`) e o boneco senta
  (`sit`) na raia.
- **O próximo microjogo** começa na batida seguinte ao resultado: sem pausa,
  sem cortina, a música nunca para.

### A sombra

Só no aquecimento, uma volta por Relâmpago por lugar:

- Quem chega a 0 vidas vira **sombra** se, sem ele, ainda há **3 ou mais
  vivos** e `_volta_usada[l]` é falso. Com menos, ele sai e senta.
- A sombra continua jogando os microjogos: `_sombra[l] = true`, `_vidas[l]`
  fica 0, `acabou[l]` fica falso (a entrada segue lida). O boneco ganha
  `material_overlay` com `Tema.JANELA` a alpha 0,6; as três lâmpadas ficam
  apagadas.
- A sombra não conta em «todos falharam» nem perde nada ao falhar.
- **3 passes seguidos** de sombra devolvem 1 vida: `_vidas[l] = 1`,
  `_sombra[l] = false`, `_volta_usada[l] = true`, o overlay sai, a primeira
  lâmpada acende, e grava o momento `sombra_voltou`.
- Quando os vivos chegam a 2, **toda sombra senta**: `sit`,
  `acabou[l] = true`, `_saiu_em[l]` = a batida.
- **Nunca no desempate:** lá, uma vida é uma vida.

### O fim e o vencedor

- **Com dois ou mais:** quando sobra um vivo, ele vence, e o Relâmpago acaba
  no resultado daquele microjogo (todos `acabou`).
- **Com um:** até perder as vidas (ou o teto): o vencedor é ele; a tela diz
  quantos microjogos ele passou (`status`).
- **O teto:** `FIM_AQUECIMENTO := ENTRADA + 480` batidas (181,5 s), **nos dois
  modos**. Na batida do teto, o microjogo da vez é cortado e todos `acabou`.
  No desempate, quem decide é `colocacao[0]`.
- `vencedor()`: os vivos pelas vidas, depois pelos microjogos passados
  (`_passados[l]`), depois pelos pontos; depois os que saíram, do último a
  sair ao primeiro.

### O aquecimento e o desempate

Quem abre o Relâmpago diz o modo por **uma** variável estática da `Partida`
(que tem `class_name`): `static var relampago_desempate: Array = []`. Vazia
é o **aquecimento**; com lugares, é o **desempate** entre eles. O Relâmpago a
lê no `iniciar_jogo()` (copia para `_so` e esvazia a da `Partida`, para o
próximo não herdar).

- **O aquecimento:** na escolha da partida (`ui/escolha_partida.gd`), a linha
  «Salas» ganha a primeira opção `[0, "Relâmpago", "Uns 3 min"]` em
  `TAMANHOS`, e `var tamanho := 2` (era 1: com a linha nova no índice 0, o
  padrão continua «5 salas»); `confirmar()` com `n == 0` emite
  `escolheu(0, sorteada)`. No
  `_draw`, com `n == 0`, a lista da direita tem uma linha só, `1` e
  `Traducoes.traduzir("O Relâmpago")`, e não chama `Partida.roteiro`.
  `main._comecar_a_partida(0, ...)` faz `partida = null` (senão a volta do
  Relâmpago cairia no placar de uma partida velha),
  `Partida.relampago_desempate = []` e
  `_entrar_na_sala("RELAMPAGO", com_cortina)`. Também por `--sala=relampago`
  (o catálogo: `NOMES_VELHOS["relampago"] = "RELAMPAGO"`).
- **O desempate:** em `main._seguir_a_partida()`, quando `partida.acabou()`:
  se `partida.empate_no_topo()` e `partida.desempate < 0`,
  `Partida.relampago_desempate = partida.empatados_no_topo()` e
  `_entrar_na_sala("RELAMPAGO")`. No `iniciar_jogo()`, quem não está em `_so`
  sai de jogo (`jogando[l] = false`: assiste sentado). Na volta
  (`_ao_terminar_a_sala`, com `sala_id == "RELAMPAGO"` e a partida acabada):
  **não** registra na partida (a guarda vai antes do `_placar_da_sala`);
  `partida.desempate = (sala as SalaJogo).colocacao[0]` e vai ao pódio.
- **Na `Partida`** (`godot/scripts/partida.gd`):
  `static var relampago_desempate: Array = []`, `var desempate := -1`; em
  `_acima(a, b)`, logo depois da comparação de `total`:
  `if desempate >= 0 and (a == desempate or b == desempate): return a == desempate`;
  em `_criterio`, o mesmo lugar devolve `"o Relâmpago"`. As duas funções
  novas, `empate_no_topo()` (os dois primeiros do `podio` com o mesmo
  `total`) e `empatados_no_topo()` (os lugares com o `total` do primeiro).
  No 13 (a seção do kit): o `RELAMPAGO` no catálogo, e o
  `relampago_desempate` e o `desempate` da `Partida`.

### Com menos de quatro

- **3, 2:** nada muda (com 3, a sombra não nasce: sem quem saiu ficam 2).
  **1:** ver «O fim». **O desempate:** só os empatados jogam; os outros
  assistem sentados na raia.
- **O controle que cai:** o lugar sem controle **não perde vida** nos
  microjogos em que esteve fora (não passou, mas não falhou); volta no
  próximo cartão.

## A cena

### A câmera

A arena do cinema: lente de 35 mm (FOV vertical 37,8°, posto pela G05 no
`main.gd`; o R não muda o FOV), plongée de 50°, modo `fixa`.

- **De base:** `camera_pos = Vector3(0, 11.5, 9.0)`,
  `camera_olhar = Vector3(0, 0.8, 0.0)` (o centro visto a 14 m, 50° abaixo
  da horizontal: as quatro raias e as lâmpadas cabem).
- **A final:** quando os vivos passam a ser 2 (lugares `a` e `b`), a câmera
  fecha nos dois:
  `cx = (RAIAS[a] + RAIAS[b]) / 2`, `dist = clampf(absf(RAIAS[a] - RAIAS[b]) + 6.0, 9.0, 14.0)`,
  `camera_pos = Vector3(cx, 0.8 + 0.766 * dist, 0.643 * dist)`,
  `camera_olhar = Vector3(cx, 0.8, 0.0)`. A troca é um Tween de 2 batidas,
  `ENTRA_SAI` (`TRANS_SINE`, `EASE_IN_OUT`), nas duas propriedades. No
  desempate de dois, a final vale desde o começo, sem Tween.
- Nunca corta; nenhum tremor de ambiente, roll zero; o tremor é só o do
  exagero (abaixo).

### A luz

- **De base, a do salão:** a névoa `Tema.VIOLETA_FUNDO` (`#1d1638`) do main,
  o preenchimento `atmosfera(Tema.luz_da_secao(-1).preenchimento, Tema.VIOLETA, false, 30, 22.0, -7.8, 0.5)`
  (o `AMBIENTE_SALAO`, `#2a2738`, da G15)
  e uma chave `OmniLight3D` em `(0, 8, 3)`, `Tema.TUNGSTENIO`, energia 0,9,
  alcance 26.
- **A cada cartão:** o preenchimento (`_preenchimento.light_color`) e a cor
  da chave vão a `Tema.luz_da_secao(numero)` da seção da carta em 1 batida,
  `ENTRA_SAI` (um Tween em `_preenchimento.light_color` e outro em
  `_chave.light_color`). `numero = int(carta.secao.substr(1))`, de 1 a 9
  (`S03` dá 3; a assinatura da G15 é `luz_da_secao(numero: int, lado_b := false)`,
  sobre a `tinta_da_secao(numero)` da G14; o lado B não entra aqui). As chaves
  do dicionário: `preenchimento` e `chave` (cores). A névoa fica a do salão.
- **O pulso do cartão:** na batida `m0`, só a energia do `_preenchimento`
  sobe (`_energia_preenchimento + 1.2`) e volta em 0,9 s (`TRANS_QUAD`); a
  cor fica a do Tween da seção. Só com `Opcoes.flashes` (desligado, não
  pulsa). Não use o `pulso_de_luz` do `sala_jogo.gd`: ele troca a cor e, no
  fim, devolve a cor de antes, o que apaga a luz da seção que o Tween acabou
  de pôr. No máximo 3 piscadas por segundo: o cartão vem a cada 6 batidas
  ou mais (2,25 s), e nada mais pisca.

### As peças Kenney e o papel de cada uma

| peça | onde | papel |
| --- | --- | --- |
| `floor`, `floor-detail`, `wall`, `wall-half` | `Kit.arena(self, 5, 3)` | o chão e as paredes |
| os conjuntos por mecânica | montados todos no `montar()` e escondidos (`visible = false`); o cartão mostra o da vez | a bigorna de cada raia (`BATER`); a trilha de lajes (`MARCHAR`); a bateria da Q2 (`APERTAR`); a plataforma que inclina (`INCLINAR`); a runa da seta (`TRACAR`); a garra (`DEFENDER`); os alvos de 8 lados (`PUXAR`); nada além do boneco (`REPETIR`); a laje de pedra no escuro (`SENTIR`); o braseiro (`SOPRAR`) |
| o objeto da carta | um por raia viva, em `(RAIAS[l], 0, Z_JOGADOR - 1.3)`, escala `Kit.K`, do cartão ao resultado | diz «este é o minigame que vocês viram» sem texto |

**O objeto da carta** (`OBJETO_DA_CARTA`, slot → peça). Tudo em
`godot/assets/kenney/` (conferido: as 25 peças existem); o que não é peça é
do `Kit`:

| seção | J1 | J2 | J3 | J4 | J5 |
| --- | --- | --- | --- | --- | --- |
| S01 (J01–J05) | `Kit.bigorna` | `shield-rectangle` | `gate` | `pot` | o lingote: `Kit.caixa(pai, Vector3(0.6, 0.2, 0.3), pos + Vector3(0, 0.1, 0), Kit.material(Tema.OXIDO_BRILHO))` |
| S02 (J06–J10) | `wood-support` | `column` | `stones` | `wood-structure` | `shield-round` |
| S03 (J11–J15) | `table` | `rocks` | `wall-opening` | `key` | `chest` |
| S04 (J16–J20) | `wall` | `stairs` | `barrel` | `Kit.bigorna` | `trap` |
| S05 (J21–J25) | `banner` | `weapon-spear` | `potion` | `weapon-sword` | `rocks` |
| S06 (J26–J30) | o sino: `Kit.cilindro(pai, 0.45, 0.7, pos + Vector3(0, 0.35, 0), Kit.material(Tema.OXIDO_BRILHO), 0.25)` | `rocks` | `banner` | `chest` | `barrel` |
| S07 (J31–J35) | `floor-detail` | `stones` | `floor` | `wall-narrow` | `coin` |
| S08 (J36–J40) | `wall` | `pot` | `rocks` | `shield-round` | `banner` |
| S09 (J41–J45) | `column` | `chest` | `wall-narrow` | `barrel` | `stairs` |

No `montar()`, uma instância de cada peça distinta por raia fica escondida
em `_objetos[l][nome]` (nada se carrega no meio do jogo). Peça que não
existir (`ResourceLoader.exists(Kit.CAMINHO % nome)` falso) não aparece: a
carta mostra só o conjunto da mecânica.

**As lâmpadas de vida:** três por raia, `Kit.caixa(self, Vector3(0.3, 0.3, 0.3), Vector3(RAIAS[l] + (k - 1) * 0.45, 0.15, Z_JOGADOR + 0.9), mat)`,
`k` de 0 a 2. Acesa: `Tema.neon(Tema.JOGADOR[l], 1.8, l)`. Apagada:
`Kit.material(Tema.GRAFITE)`. Nenhum `#f1fa8c`, `#3b3345`, `Tema.CIANO` nem
`Tema.AMARELO` no código da R (a G14 tira o `AMARELO`; o pulso é só energia).

As peças entram por `Kit.peca(self, nome, pos)` (ou `Kit.peca(self, nome, pos, rot_y, escala)`;
a escala padrão é `Kit.K`).

**O cartão:** o verbo gigante é da R, não do painel (o painel só desenha o
`progresso()` pequeno, em `Tema.fonte(500)`). No `montar()`, um `CanvasLayer`
próprio com um `Label` `_verbo` e um `TextureRect` `_glifo`:

- o `_verbo`: `Traducoes.traduzir(carta.verbo)` (começa com maiúscula),
  fonte `Tema.bungee()`, tamanho `Tema.t(Tema.T_VERBO)` (160, «o verbo da
  entrada» do 02), cor `Tema.ETIQUETA`, sombra `Tema.FITA` deslocada 13 px
  para baixo e para a direita (round(0,08 × 160), a regra da G12), centrado
  na tela;
- o `_glifo`: `Desenho.glifo(str(Minigame.ICONE_DA_PARTE.get(carta.icone, carta.icone)))`
  (a tabela da H08: `botoes` dá `cross`), 128 px, logo abaixo do verbo;
- os dois visíveis da batida `m0` à `m0 + 2` (o começo da janela), depois
  escondidos;
- no nível novo, o `_verbo` diz `"Mais rápido!"` na batida `m0` e o verbo da
  carta na `m0 + 1`.

O `progresso()` continua a linha pequena do painel no alto
(`"Mais rápido! · Bata!"` no nível novo, só `"Bata!"` no resto).

### O que brilha e de quem é

| o que brilha | dono | energia |
| --- | --- | --- |
| o contorno do cavaleiro | o lugar | 2,4 (G08) |
| a lâmpada acesa | o lugar | 1,8 |
| as faíscas da vida perdida | o lugar | `Efeitos.faiscas(self, pos_da_lampada, Tema.JOGADOR[l], 12, 1.0)` |
| as faíscas da volta das lâmpadas | a forja | `Efeitos.faiscas(self, pos_da_lampada, Tema.TUNGSTENIO, 12, 1.0)` |
| a chave | a forja | `Tema.TUNGSTENIO` de base, a chave da seção no cartão |

No máximo 300 partículas vivas: as faíscas de um resultado somam no máximo
4 × 12 = 48 por vez.

### O exagero (a régua, «O exagero do impacto»)

```gdscript
const DEGRAUS := {
	"golpe": {"tremor_m": 0.02, "batidas": 1.0, "hit_stop": 2},
	"estrondo": {"tremor_m": 0.05, "batidas": 2.0, "hit_stop": 3},
}
const METROS_POR_TREMOR := 0.12  # o main treme a câmera 0,12 m por unidade de `tremor`
```

`sala.tremor = tremor_m / 0.12` (golpe: 0,17; estrondo: 0,42), zerado
depois de `batidas`. O hit-stop: `anim.speed_scale = 0` por 2 quadros
(33 ms, golpe) ou 3 quadros (50 ms, estrondo), só com `Opcoes.tremor`; o
relógio, o julgamento e a música nunca param.

## O som

Os ids do [mapa do áudio](../audio/mapa.csv). Todos já existem; nenhum som
novo.

| evento | na TV | no alto-falante do dono | id do mapa |
| --- | --- | --- | --- |
| o cartão | `Som.tocar("transicao")` | — | `transicao_0`, `transicao_1` |
| o nível novo | `Som.tocar("sobe")`, junto do cartão | — | `sobe_0..2` |
| passou | — | `Forja.som_falante(l, "coleta", 0.7)` | `mod_coleta` |
| perdeu a vida | — | `Forja.som_falante(l, "nota_quebrada:%d" % l)` | `mod_nota_quebrada_p1..p4` |
| todos falharam (o estouro) | `Som.tocar("golpe")` | — | `golpe_0..4` |
| os quatro no acorde | `Som.tocar("car_acorde")` | — | `car_acorde` |
| o toque certo | o kit, pelo material `"metal"` da FICHA | — | `mod_material_metal` |
| o fim | o kit: `jin_apito`, e `fx_vitoria_p{n}` ou `fx_derrota` no inserto | — | `jin_apito`, `fx_vitoria_p1..p4`, `fx_derrota` |
| a faixa | `MUS_RELAMPAGO`: 160 BPM, Dó menor | — | `mus_relampago` |

- **Sai o `vitoria_noite`:** é do coop, não do Relâmpago.
- **O alto-falante toca um som por vez:** a coleta e a nota quebrada saem no
  resultado, quando o julgamento do kit já tocou.

## O controle

Evento por evento. O piso é o da F05; o gatilho usa os modos de `forja.gd`
(`GATILHO_OFF` 0, `GATILHO_RESISTENCIA` 1, `GATILHO_ARMA` 2,
`GATILHO_VIBRACAO` 3; lado 0 = L2, 1 = R2).

| evento | quem sente | o que sai |
| --- | --- | --- |
| a assinatura do cartão, `APERTAR` e `PUXAR` (batida `m0 + 1`) | cada vivo | `Forja.gatilho(l, lado, Forja.GATILHO_VIBRACAO, 0, 2, 30)` nos dois lados por 60 ms, depois `Forja.gatilho(l, lado, Forja.GATILHO_OFF)` (o `PUXAR` põe o R2 em `ARMA` (2, 6, 8) na batida `m0 + 2`) |
| a assinatura, `REPETIR` | cada vivo | `Forja.som_falante(l, "clique", 0.5)` |
| a assinatura, `SOPRAR` | cada vivo | `Forja.led_mic(l, 2)` por 1 batida, depois `Forja.led_mic(l, 0)` |
| a assinatura, `SENTIR` | cada vivo | `Forja.textura(l, "pedra")` |
| a assinatura, as outras | — | nada: o cartão basta |
| a pista de `DEFENDER` (meia batida antes) | o dono da nota | com háptica estéreo (`Forja.som_tem(l, Forja.PAPEL_HAPTICA)`): `Forja.som_haptica(l, "tropeco", "", 1.0)` (esquerda) ou `Forja.som_haptica(l, "", "tropeco", 1.0)` (direita); sem ela: `Forja.sentir(l, "golpe_esq")` ou `Forja.sentir(l, "golpe_dir")` e `anotar("troca", l, {"de": "haptica", "para": "rumble", "motivo": "sem_placa"})` (os campos que o `anotar` da H08 aceita, `TROCAS`) |
| a pedra de `SENTIR` (meia batida antes) | o dono | a da O2, copiada |
| a nota julgada | o dono | o kit (`acerto`, `perfeito`, `erro`) |
| perdeu a vida | o dono | `Forja.sentir(l, "golpe")` |
| saiu (0 vidas, sem sombra) | o dono | `Forja.sentir(l, "explosao")` |
| os quatro no acorde | os quatro | `Forja.sentir(l, "acerto")` |
| o cartão de toda mecânica sem gatilho | cada vivo | `Forja.gatilhos_off(l)` |

- **Os papéis:** `papel_som = Forja.PAPEL_MICROFONE` (para `SOPRAR` achar o
  microfone); `usa_gatilho = true`. A háptica e o alto-falante tocam pela
  placa aberta (H07); o caminho de cada mecânica se decide **no cartão
  dela**, com a `troca`.
- **Rumble e háptica nunca juntos:** a pista de `DEFENDER` e a pedra de
  `SENTIR` saem meia batida antes (0,19 s); a 160 bpm, uma batida antes
  cairia no acerto da nota anterior.
- A barra de luz e as luzinhas de jogador ficam na cor e no número do lugar,
  sempre. Ninguém mexe nelas.

### O robô

O de cada mecânica é o da estação de origem, copiado (a Q4 para bater,
equilibrar, traçar e defender; a Q5 para puxar, repetir e sentir), mais
três pequenos, **sempre** com a primeira linha `if not Forja.robo: return`
e o temperamento por nota (`Forja.robo_acerta()` quando a nota muda, guardado
em `_robo_certo[l]`):

```gdscript
		MARCHAR:
			var lado := (-1.0 if n % 2 == 0 else 1.0) * (1.0 if _robo_certo[l] else -1.0)
			Forja.robo_eixo(l, Forja.LX, lado, 0.08)
			_robo_feito[l] = true
		APERTAR:
			var eixo := Forja.L2 if n % 2 == 0 else Forja.R2
			if not _robo_certo[l]:
				eixo = Forja.R2 if eixo == Forja.L2 else Forja.L2
			Forja.robo_eixo(l, eixo, 1.0, 0.08)
			_robo_feito[l] = true
		SOPRAR:
			Forja.robo_falar(l, 0.5, 0.75 if _robo_certo[l] else 0.3)
			_robo_feito[l] = true
```

(Dentro do mesmo `match` do robô da Q4, depois de
`if Ritmo.t_musica() < quando - _antecipa(...): return`.) A sombra joga com
o mesmo robô.

## O cavaleiro

O boneco na raia é **o cavaleiro montado da G13**, como a pessoa o deixou: a
roupa de cima e a de baixo diferenciadas (cada parte com o material e a
faixa de valor dela, o néon só no acento: o friso, a costura, a runa), e de
qualquer raça (humana, orc, autômato, golem, raposa) ou na cadeira de rodas.
Esta ficha não supõe corpo humano: usa só `jogador(l)` (o `ForjaPlayer`),
`gesto(nome, duracao)` e as animações `fall`, `sit`, `emote-yes` e
`emote-no`. Na cadeira de rodas, `fall` vira `wheelchair-back`, `sit` vira
`wheelchair-sit`, `emote-yes` vira `wheelchair-move-forward` e `emote-no` vira
`wheelchair-look-left`, com a mesma duração (as quatro estão no pacote dos
personagens). Quem troca é a R: todo gesto passa por `_gesto(l, nome, dur)`
(«Os ganchos»), que lê `jogador(l).get("na_cadeira")`; verdadeiro, usa o
nome da `NA_CADEIRA`; falso ou `null` (hoje, antes da G13), o nome de
pernas.

**Nenhum stat nem item age** (`docs/jogo/sistemas/regras.csv`,
`stats_no_relampago` = `nao`): a regra é igual para os quatro.

| stat ou item | o que muda no Relâmpago |
| --- | --- |
| Peso, Passo, Fôlego, Faro | nada (`"corpo": false` na FICHA) |
| o item (Martelo, Escudo, Fole, Lanterna, Diapasão, Âncora) | nada: no `montar()`, `_itens_antes = Itens.escolhido.duplicate()`, `Itens.escolhido = [Itens.NENHUM, Itens.NENHUM, Itens.NENHUM, Itens.NENHUM]` e `maos_livres(jogador(l))` de cada lugar; no `_exit_tree()`, `Itens.escolhido = _itens_antes` |
| o arquétipo «Relâmpago» | nada no modo; é só o nome |

## As reações

- **`car_acorde`** (os quatro na Ressonância no mesmo tempo 1): com 4 vivos,
  numa nota em batida `% 4 == 0`, os quatro com `PERFEITO` naquela nota. No
  máximo 1 por microjogo. O Relâmpago toca `Som.tocar("car_acorde")`, faz
  `Forja.sentir(l, "acerto")` nos quatro e grava o momento `acorde_maior`.
  O desenho do carimbo (Bungee 112, centro da tela, y = 300) é da ficha dos
  carimbos no jogo; até ela existir, só o som, a vibração e o momento.
- **`car_por_um_fio`, `car_em_chamas`, `car_virada`:** não se aplicam aqui
  (o vencedor é por vidas, não por pontos; o placar é da partida).
- **`car_emburrado`:** é do inserto do resultado (o kit), não do Relâmpago.
- **Adesivos:** só quem tem 0 vidas (sentado ou sombra) manda adesivo
  durante o jogo, e nunca no cartão (batidas `m0` e `m0 + 1`) nem na janela
  de `TRACAR` (o touchpad é o controle).
- Nenhum carimbo próprio de minigame.

## A diversão

**O grito: ninguém perde** (`todos_falharam`, degrau estrondo). Quando todos
os vivos (2 ou mais) falham o mesmo microjogo:

1. **No resultado:** as lâmpadas acesas de cada vivo estouram juntas
   (`Efeitos.faiscas` 12 por vivo na cor `Tema.JOGADOR[l]`, 48 no total com
   4), todas apagam; `Som.tocar("golpe")`; os bonecos fazem `fall` por 2
   batidas; tremor 0,42 por 2 batidas; hit-stop de 3 quadros (50 ms).
2. **Na batida seguinte** (o `m0` do próximo cartão): as lâmpadas reacendem
   como estavam, com faíscas `Tema.TUNGSTENIO` (12 por vivo); degrau golpe:
   tremor 0,17 por 1 batida, hit-stop de 2 quadros.
3. **O rastro:** `Efeitos.poeira(self, Vector3(RAIAS[l], 0.4, Z_JOGADOR), Vector3(1.0, 0.6, 1.0), Tema.ETIQUETA_SOMBRA, 16)`
   em cada vivo, por 2 s (depois `queue_free`); o boneco entra no cartão
   torto, `rotation.z = deg_to_rad(8.0)`, e volta a 0 em 2 batidas (`MOLA`:
   `TRANS_BACK`, `EASE_OUT`).
4. **O registro:** `momento("todos_falharam", -1, Vector3(0, 0, Z_JOGADOR), 1.0, {"nivel": nivel})`.

**Os outros momentos:** `acorde_maior` (em «As reações») e `sombra_voltou`
(`momento("sombra_voltou", l, jogador(l).position, 1.0, {"nivel": nivel})`).
Todo momento também entra em `var momentos: Array` (`{"nome", "t_musica", "nivel"}`),
que a prova lê.

**A função `momento`** (em `minigame.gd`, de todos; a mesma da L1). Se ainda
não existe, acrescente `"momento"` ao fim de `TIPOS_DO_JOGO` e, ao fim do
arquivo:

```gdscript
## Um momento de grito (docs/jogo/diversao/README.md, itens 4 e 8): a linha
## `momento` com o nome, o tempo de música e onde o objeto dele está na tela
## (x_tela e altura_tela, de 0 a 1). `l` é -1 quando o momento é de todos.
func momento(nome: String, l: int, pos: Vector3, altura_m: float, campos := {}) -> void:
	var c: Dictionary = campos.duplicate()
	c["nome"] = nome
	c["t_musica"] = snappedf(Ritmo.t_musica(), 0.001)
	var cam := get_viewport().get_camera_3d()
	var tam := get_viewport().get_visible_rect().size
	if cam and tam.y > 0.0:
		var base := cam.unproject_position(pos)
		var topo := cam.unproject_position(pos + Vector3.UP * altura_m)
		c["x_tela"] = snappedf(base.x / tam.x, 0.001)
		c["altura_tela"] = snappedf(absf(base.y - topo.y) / tam.y, 0.001)
	anotar("momento", l, c)
```

No 13, na tabela «Os eventos do jogo», depois da linha `estacao` (se ainda
não existe):
`| \`momento\` | o momento de grito do minigame: \`nome\`, \`t_musica\`, \`x_tela\` e \`altura_tela\` (0 a 1); \`lugar\` 0 quando é de todos (docs/jogo/diversao/README.md) |`.

**A curva** (em níveis; o nível sobe a cada 5 microjogos): nível 0 (uns
40 s), 2 batidas entre notas; níveis 1 e 2 (uns 70 s), a janela encolhe e o
cartão diz «Mais rápido!»; nível 3 em diante, uma nota por batida, e com 2
vivos a câmera da final.

**Como o jogador do time confere:**

| o quê | a mesa | pelo registro | pela prancha |
| --- | --- | --- | --- |
| o grito | fraca: os quatro `medio`, semente 7 | pelo menos 1 linha `momento` `todos_falharam` com `t_musica` < 180 e `nivel` ≥ 2 | `relampago_todos_sentados`: os quatro bonecos em `fall` no mesmo quadro |
| a primeira vida perdida | padrão: P1 `bom`, P2 `medio`, P3 `medio`, P4 `ruim` | a primeira vida perdida (o P4) antes de 30 s | — |
| a cena por carta | fraca | 10 microjogos de 6 seções ou mais | `relampago_cartao`: o objeto da carta nas raias |
| a final | fraca | — | `relampago_final`: a câmera nos dois vivos |

A mesa fraca roda já, pela prova da ficha (`SALA=RELAMPAGO bash tests/prova_do_jogo.sh`,
com `Forja.robo_temperamento = "medio"`). A mesa padrão espera o robô por
lugar (`--robo=bom,medio,medio,ruim`). **Se a mesa fraca não der o grito**,
o número a mexer é `PASSA` (0,6), e quem decide o valor novo é o diretor de
jogo.

## Pronto quando

Três minutos de Relâmpago passam por microjogos das nove seções sem tela de
carregamento e sem a música parar; cada carta mostra o objeto do minigame de
origem; o nível sobe a cada cinco; o aquecimento (3 vidas, com a sombra) e
o desempate (1 vida, só os empatados, o teto também) funcionam; uma partida
de 3 com empate no topo termina no Relâmpago e o pódio diz «o Relâmpago»
como critério; joga com 4, 3, 2 e 1 jogador e com o robô nos três
temperamentos; aguenta o cabo que cai; a mesa fraca grava pelo menos 1
`todos_falharam` antes de 180 s; a prova do jogo passa; e
`bash tests/prova_visual.sh` passa com as três pranchas olhadas.

## Provas

Na sessão: `bash tests/prova_do_jogo.sh`, `SALA=RELAMPAGO bash tests/prova_do_jogo.sh`
e `bash tests/prova_visual.sh`.

Em `godot/testes/prova_do_jogo.gd`:

1. **`_prova_do_relampago()`** (no percurso, só na rodada sem a bancada):
   abre a sala `"RELAMPAGO"` (o `_comeca_a_sala` confere `sala.id == id`, e o
   id é o slot; o `--sala=relampago` da linha de comando passa pelo
   `NOMES_VELHOS`), espera **dez microjogos** (pelo
   `_i`, com o relógio de parede, limite 120 s), confere que vieram de pelo
   menos seis seções diferentes e sem duas iguais em seguida, e que a música
   não parou (`Ritmo.t_musica()` sempre subindo); depois **desiste pela
   pausa** e confere a volta ao salão.

   ```gdscript
   func _prova_do_relampago() -> void:
   	var sala = await _comeca_a_sala("RELAMPAGO")
   	if sala == null:
   		return
   	var secoes: Array = []
   	var ultima := ""
   	var repetiu := false
   	var visto := -1
   	var t_antes := -1.0
   	var parou := false
   	var inicio := Time.get_ticks_usec()
   	while is_instance_valid(sala) and sala._i < 10 and sala.fase == "jogo" and Time.get_ticks_usec() - inicio < 120000000:
   		if sala._i != visto and not sala._carta.is_empty():
   			visto = sala._i
   			var s := str(sala._carta.secao)
   			repetiu = repetiu or s == ultima
   			ultima = s
   			if not s in secoes:
   				secoes.append(s)
   		var tm := Ritmo.t_musica()
   		parou = parou or tm < t_antes
   		t_antes = tm
   		await _quadros(1)
   	_esperar(secoes.size() >= 6, "relâmpago: dez microjogos de %d seções (%s)" % [secoes.size(), secoes])
   	_esperar(not repetiu, "relâmpago: nunca dois da mesma seção em seguida")
   	_esperar(not parou, "relâmpago: a música não voltou nem parou")
   	jogo._na_pausa("salao")
   	var q := 0
   	while (jogo.estado != "salao" or jogo._trocando) and q < 600:
   		await _quadros(2)
   		q += 2
   	_esperar(jogo.estado == "salao", "relâmpago: pela pausa, desiste e volta ao salão")
   ```

2. **`_prova_do_relampago_inteiro()`** (a mesa fraca; no `match` de
   `_prova_da_ficha`: `"RELAMPAGO", "relampago": await _prova_do_relampago_inteiro()`):

   ```gdscript
   ## O Relâmpago inteiro com os quatro `medio`: fecha com vencedor (o
   ## _joga_o_minigame confere), o último microjogo começa até o teto, e a
   ## sala grita pelo menos uma vez antes de 180 s, num nível 2 ou mais.
   func _prova_do_relampago_inteiro() -> void:
   	var antes := Forja.robo_temperamento
   	Forja.robo_temperamento = "medio"
   	var mg = await _joga_o_minigame("RELAMPAGO", 200.0)
   	Forja.robo_temperamento = antes
   	if mg == null:
   		return
   	var grito: Array = mg.momentos.filter(func(m): return m.nome == "todos_falharam" and float(m.t_musica) < 180.0 and int(m.nivel) >= 2)
   	_esperar(not grito.is_empty(), "relâmpago: a mesa fraca grita (%d momentos todos_falharam)" % grito.size())
   	_esperar(float(mg._m0) <= float(mg.FIM_AQUECIMENTO), "relâmpago: o último microjogo começou até o teto")
   ```

3. **`_prova_das_contas_da_partida()`** (a que já existe, pura): uma partida
   com dois lugares empatados no `total` tem `empate_no_topo()`; com
   `desempate` posto, o `podio` põe o desempatado em cima e o `_criterio`
   diz `"o Relâmpago"`.

**As pranchas** (`godot/testes/captura_jogo.gd`, em `momentos`; roda com
`SALAS=relampago`):

```gdscript
		"relampago": [
			["relampago_cartao", na_sala.call(func(sala) -> bool: return not sala._carta.is_empty() and Ritmo.batida() >= sala._m0 + 1.0)],
			["relampago_todos_sentados", na_sala.call(func(sala) -> bool: return sala._estouro_ate >= 0.0)],
			["relampago_final", na_sala.call(func(sala) -> bool: return sala._na_final)],
		],
```

O que o jogador olha: no `relampago_cartao`, o verbo legível e o objeto da
carta em cada raia; no `relampago_todos_sentados`, os quatro no chão e as
lâmpadas apagadas; no `relampago_final`, os dois vivos enchendo o quadro e
as lâmpadas acesas na cor de cada um. Se o robô não chegar a um dos
momentos, a foto sai no fim da sala, e a prancha mostra que faltou.

**Com o André (local):** `./run-local.sh -- --sala=relampago` (três rodadas
de aquecimento) e uma partida de 3 até empatar (`--partida=3`): o cartão
tem de ser lido em meio segundo; cada carta tem de lembrar o minigame de
origem pelo objeto; a aceleração tem de ser sentida; o estouro coletivo tem
de fazer a sala gritar duas vezes.

## Os ganchos

`godot/scripts/minigames/relampago.gd`, `extends Minigame`, sem `class_name`.

```gdscript
extends Minigame
## O Relâmpago (RELAMPAGO). Microjogos de 5 a 8 segundos tirados dos 45, um
## atrás do outro, sem pausa na música: o verbo de cada um é o do `microjogo`
## da ficha dele, a mecânica é a do recurso que ele usa (o `icone`) e o objeto
## na raia é o do minigame de origem. A cada cinco, mais denso. Três vidas no
## aquecimento (com a sombra); uma no desempate.
##
## A falha: perder a vida no resultado do microjogo. O vencedor: o último
## vivo. O alto-falante do dono: a coleta ao passar. O registro mede: cada
## microjogo (estacao, com o slot de origem), o desvio de cada recurso sob
## pressa e os momentos (todos_falharam, acorde_maior, sombra_voltou). O robô:
## o das estações da Q4 e da Q5. Com menos de quatro: nada muda; no
## desempate, só os empatados. A régua: o cartão é o verbo, o glifo e o
## objeto; nada pergunta nada.

const FICHA := { ... }   # a de «A ficha de dados»

enum { BATER, MARCHAR, APERTAR, INCLINAR, TRACAR, DEFENDER, PUXAR, REPETIR, SENTIR, SOPRAR }
const MECANICA_DO_ICONE := {
	"botoes": BATER, "analogicos": MARCHAR, "gatilhos": APERTAR, "giroscopio": INCLINAR,
	"acelerometro": INCLINAR, "touchpad": TRACAR, "vibracao": DEFENDER, "gatilho_adaptativo": PUXAR,
	"alto_falante": REPETIR, "haptica": SENTIR, "microfone": SOPRAR,
	# o nome do glifo, se a ficha o escrever no lugar da parte (Minigame.ICONE_DA_PARTE)
	"cross": BATER, "stick_l": MARCHAR, "l2": APERTAR, "r2": PUXAR, "rumble_esquerdo": DEFENDER,
	"rumble_direito": SENTIR, "alto-falante": REPETIR, "mic": SOPRAR,
}
## O gesto de pernas -> o da cadeira de rodas (o pacote dos personagens).
const NA_CADEIRA := {
	"fall": "wheelchair-back", "sit": "wheelchair-sit",
	"emote-yes": "wheelchair-move-forward", "emote-no": "wheelchair-look-left",
}
const OBJETO_DA_CARTA := { ... }  # a tabela de «A cena»; "bigorna", "lingote" e "sino" são do Kit
const ENTRADA := 4
const CARTAO := 2
const ESPACO := [2.0, 1.5, 1.0, 1.0]
const PASSA := 0.6
const FIM_AQUECIMENTO := ENTRADA + 480
const PONTOS := [0, 50, 75, 100]
const SOMBRA_VIVOS := 3          ## sem quem saiu, tantos vivos ou mais: vira sombra
const SOMBRA_PASSES := 3         ## passes seguidos de sombra que devolvem 1 vida
const DEGRAUS := { ... }          # «O exagero»
const METROS_POR_TREMOR := 0.12

var _desempate := false          ## o modo, lido da Partida no iniciar_jogo
var _so: Array = []               ## no desempate: quem joga

var _baralho: Array = []
var _i := -1                     ## o microjogo da vez
var _carta := {}
var _m0 := float(ENTRADA)
var _janela := 0
var _notas_da_vez: Array = []    ## as batidas das notas do microjogo
var _acertos := [0, 0, 0, 0]     ## no microjogo da vez
var _vidas := [3, 3, 3, 3]
var _passados := [0, 0, 0, 0]
var _saiu_em := [-1.0, -1.0, -1.0, -1.0]
var _esteve_fora := [false, false, false, false]
var _sombra := [false, false, false, false]
var _volta_usada := [false, false, false, false]
var _passes_de_sombra := [0, 0, 0, 0]
var _acorde_no_microjogo := false
var _estouro_ate := -1.0          ## a batida em que as lâmpadas reacendem (-1: nenhum estouro)
var _tremor_ate := -1.0
var _na_final := false
var _itens_antes: Array = []
var _lampadas := {}              ## lugar -> [3 MeshInstance3D]
var _pecas := {}                 ## mecânica -> Node3D (o conjunto)
var _objetos := {}               ## lugar -> {nome: Node3D}
var _chave: OmniLight3D
var _verbo: Label                ## o verbo gigante do cartão (Bungee 160), num CanvasLayer próprio
var _glifo: TextureRect          ## o glifo da parte do controle, abaixo do verbo
var momentos: Array = []         ## {nome, t_musica, nivel}: a prova lê
# ... e o que as estações copiadas pedem (_nota, _alvo, _n, o ouvido, a pedra, a seta, o lado, _robo_certo, _robo_feito)


func montar() -> void:
	papel_som = Forja.PAPEL_MICROFONE
	usa_gatilho = true
	camera_pos = Vector3(0, 11.5, 9.0)
	camera_olhar = Vector3(0, 0.8, 0.0)
	_itens_antes = Itens.escolhido.duplicate()
	Itens.escolhido = [Itens.NENHUM, Itens.NENHUM, Itens.NENHUM, Itens.NENHUM]
	for l in presentes():
		maos_livres(jogador(l))
	# Kit.arena(self, 5, 3); a luz do salão (atmosfera e _chave); as raias com as
	# lâmpadas; os dez conjuntos de peças e os objetos das cartas, escondidos


func _exit_tree() -> void:
	if not _itens_antes.is_empty():
		Itens.escolhido = _itens_antes


func iniciar_jogo() -> void:
	_montar_baralho()            # ver «O baralho»
	_so = Partida.relampago_desempate.duplicate()
	Partida.relampago_desempate = []
	_desempate = not _so.is_empty()
	for l in presentes():
		_vidas[l] = 1 if _desempate else 3
		if _desempate and not l in _so:
			jogando[l] = false   # assiste sentado
	if _desempate and _so.size() == 2:
		_por_na_final(_so[0], _so[1], false)
	_proximo_microjogo(float(ENTRADA))


func jogar(dt: float) -> void:
	var b := Ritmo.batida()
	_ouvir(dt)                   # a P1 (só casa com nota em SOPRAR)
	_pistas_da_mecanica(b)       # a assinatura, a garra (DEFENDER), a pedra (SENTIR), o canto (REPETIR), na hora
	for l in presentes():
		if acabou[l]:
			continue
		if not conectado(l):
			_esteve_fora[l] = true
			_nota[l] = -1
			continue
		_entrada(l)              # pelo gesto da mecânica; julgar_toque
		_prazo(l)                # a nota que passou
	_acorde(b)                   # car_acorde: 4 vivos, batida % 4 == 0, os quatro PERFEITO
	if b >= _m0 + CARTAO + _janela:
		_resultado(b)            # passou / perdeu vida, todos_falharam, a sombra, quem saiu, a final, o fim
		if not _acabou_tudo():
			_proximo_microjogo(_m0 + CARTAO + _janela + 1.0)
	if b >= FIM_AQUECIMENTO:     # o teto, nos dois modos
		for l in presentes():
			acabou[l] = true
	_reacender(b)                # o estouro que volta (a batida seguinte)
	if _tremor_ate >= 0.0 and b >= _tremor_ate:
		tremor = 0.0
		_tremor_ate = -1.0
	_mostrar(b)


func toque(l: int, j: int) -> void:
	marcar(l, PONTOS[j])
	_acertos[l] += 1


func falha(l: int) -> void:
	_gesto_de_erro(l)            # o da estação de origem, sem mais nada


func vencedor() -> Array:
	var vivos := presentes().filter(func(l): return _vidas[l] > 0)
	vivos.sort_custom(func(a, b):
		if _vidas[a] != _vidas[b]:
			return _vidas[a] > _vidas[b]
		if _passados[a] != _passados[b]:
			return _passados[a] > _passados[b]
		return pontos[a] > pontos[b])
	var fora := presentes().filter(func(l): return _vidas[l] <= 0)
	fora.sort_custom(func(a, b): return _saiu_em[a] > _saiu_em[b])
	return vivos + fora


func progresso() -> String:
	if _carta.is_empty():
		return ""
	var v := str(_carta.verbo)
	# os dois pedaços traduzidos aqui: a frase junta não é chave de Traducoes
	return (Traducoes.traduzir("Mais rápido!") + " · " + Traducoes.traduzir(v)) if _i > 0 and _i % 5 == 0 else v


## A final: a câmera fecha nos dois vivos (docs/jogo/arte/01-cinema.md, 35 mm, 50°).
func _por_na_final(a: int, b: int, com_tween := true) -> void:
	_na_final = true
	var cx := (RAIAS[a] + RAIAS[b]) / 2.0
	var dist := clampf(absf(RAIAS[a] - RAIAS[b]) + 6.0, 9.0, 14.0)
	var pos := Vector3(cx, 0.8 + 0.766 * dist, 0.643 * dist)
	var olhar := Vector3(cx, 0.8, 0.0)
	if not com_tween:
		camera_pos = pos
		camera_olhar = olhar
		return
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "camera_pos", pos, 2.0 * 60.0 / Ritmo.bpm)
	tw.tween_property(self, "camera_olhar", olhar, 2.0 * 60.0 / Ritmo.bpm)


## O exagero pelo degrau: o tremor por batidas e o hit-stop do boneco.
func _exagero(degrau: String, bonecos: Array) -> void:
	var d: Dictionary = DEGRAUS[degrau]
	tremor = maxf(tremor, float(d.tremor_m) / METROS_POR_TREMOR)
	_tremor_ate = Ritmo.batida() + float(d.batidas)
	if not Opcoes.tremor:
		return
	for p in bonecos:
		var anim: AnimationPlayer = p.get("anim")
		if anim:
			anim.speed_scale = 0.0
			get_tree().create_timer(int(d.hit_stop) / 60.0).timeout.connect(func(): anim.speed_scale = 1.0)


## Todo gesto do boneco passa aqui: na cadeira de rodas, o da cadeira.
func _gesto(l: int, nome: String, dur: float) -> void:
	var p = jogador(l)
	if p == null:
		return
	if p.get("na_cadeira") == true:
		nome = str(NA_CADEIRA.get(nome, nome))
	p.gesto(nome, dur)


func _momento(nome: String, l: int, pos: Vector3) -> void:
	var nivel := _i / 5
	momento(nome, l, pos, 1.0, {"nivel": nivel})
	momentos.append({"nome": nome, "t_musica": Ritmo.t_musica(), "nivel": nivel})
```

**`_proximo_microjogo(m0)`:** `_i += 1`; a carta
`_baralho[_i % _baralho.size()]`; `_m0 = m0`; o nível; `_janela`; as notas
(`_notas_da_vez`); os `_acertos` a zero, `_esteve_fora` a falso,
`_acorde_no_microjogo` a falso; o conjunto de peças da mecânica visível (os
outros não); o objeto da carta visível na raia de cada vivo e de cada sombra
(os outros escondidos); a luz da seção (Tween de 1 batida); o pulso (só a
energia, «A luz»), o `_verbo` e o `_glifo` («O cartão») e o `transicao` (e o
`sobe` no nível novo); o gatilho da mecânica (`ARMA` no R2
em `PUXAR` na batida `m0 + 2`, `gatilhos_off` no resto); o caminho da
mecânica (`_rumble[l]`, com a `troca`); a linha
`anotar("estacao", -1, {"estacao": str(_carta.slot), "mecanica": _carta.mecanica, "batida": m0})`;
e abre as notas de cada lugar vivo e de cada sombra uma batida antes de cada
uma (pelo `_distribuir` da Q4, sem hoqueto).

**`_resultado(b)`:** os vivos conectados o microjogo todo; passou =
`_acertos[l] >= ceili(PASSA * notas)`. Com 2 ou mais vivos e nenhum passou:
o estouro de «A diversão» (`_estouro_ate = b + 1.0`), ninguém perde. Senão,
cada vivo que falhou perde uma vida (a lâmpada apaga com as faíscas dele,
`Forja.sentir(l, "golpe")`, a nota quebrada, `_gesto(l, "fall", …)` por 2 batidas e o
`_exagero("golpe", [jogador(l)])`) e, em zero, vira sombra (pela regra de
«A sombra») ou sai (`acabou[l] = true`, `_saiu_em[l] = b`, `sit`,
`Forja.sentir(l, "explosao")`); quem passou, `_passados[l] += 1`,
`emote-yes` e a coleta. Cada sombra que passou soma
`_passes_de_sombra[l]`; que falhou, zera; em 3, volta. Depois: se os vivos
são 2 e `not _na_final`, toda sombra senta e `_por_na_final(a, b)`.

**`_acabou_tudo()`:** com dois ou mais no começo, sobra um ou nenhum vivo →
todos `acabou`; com um, ele sem vidas. **`status(l)`:** `"%d vidas" % _vidas[l]`
ou, sem vidas, `"%d passados" % _passados[l]`.

**O catálogo:** `"RELAMPAGO": preload("res://scripts/minigames/relampago.gd")`
em `MINIGAMES` (fora de `SECOES`), `"relampago": "RELAMPAGO"` em
`NOMES_VELHOS`. A prova do catálogo da H04 confere a FICHA dele como a dos
outros.

**Traduções** (o `progresso()` junta dois textos já traduzidos, então não há
frase com `%s`): `"O Relâmpago": "Lightning Round"`, `"Rápido!": "Quick!"`,
`"Mais rápido!": "Faster!"`, `"Relâmpago": "Lightning"`,
`"Uns 3 min": "About 3 min"`, `"%d passados": "%d cleared"`,
`"%d vidas": "%d lives"` (se ainda não existe) e `"o Relâmpago"` (o critério
do pódio): `"the Lightning Round"`.

## O que o registro mede

- `estacao` a cada microjogo, com o **slot de origem** (`S03_J12`...) e a
  mecânica: a noite vê o desvio de cada recurso sob pressa, no aquecimento
  (o começo da noite) e no desempate (o fim): é a régua do cansaço;
- `nota`/`toque` de cada nota, `pista`/`troca` das mecânicas que as têm;
- `momento` (`todos_falharam`, `acorde_maior`, `sombra_voltou`), que a S
  conta por minigame;
- o `minigame` `terminou` com o vencedor (o kit).

## Armadilhas

- **A carta não instancia o minigame.** `get_script_constant_map()` no
  `Script` do catálogo lê a `FICHA` sem criar o nó (criar 45 salas travaria
  o quadro e abriria a placa de som de cada uma).
- **O modo mora na `Partida`** (`Partida.relampago_desempate`), não no
  Relâmpago: minigame não tem `class_name`. O Relâmpago esvazia a variável ao
  ler, para o próximo não herdar.
- **O desempate não entra na partida:** `_placar_da_sala` não pode registrar
  o Relâmpago (a guarda: `sala_id == "RELAMPAGO"`).
- **O item volta:** sem o `_exit_tree()`, a partida seguinte começa com os
  quatro sem item.
- **A sombra não é vivo:** `_vidas[l] == 0` com `acabou[l] == false`. Toda
  conta de vivos usa `_vidas[l] > 0`, nunca `not acabou[l]`.
- **As mecânicas de gatilho:** `usa_gatilho = true`, e o gatilho volta a
  `OFF` no cartão de toda mecânica que não o usa.
- **A faixa em laço:** a faixa tem 120 s e o teto é 181,5 s; ela volta ao
  zero e o `Ritmo` conta a volta. Quem lê `Ritmo.t_musica()` (o teto, a
  prova) vê o tempo seguir subindo; não meça o fim pela posição do tocador.
- **Sem a linha em `FAIXAS`:** o `Musica.mapa("MUS_RELAMPAGO")` devolve
  120 bpm e silêncio, as 484 batidas viram 242 s e a prova de 200 s falha.
- **A cadeira depende da G13:** o `_gesto` lê a propriedade `na_cadeira`
  (bool) do `ForjaPlayer`. Se a G13 der outro nome, troque só no `_gesto`.
- **O verbo não é do painel:** `Tema.fonte(800)` não existe (a G14 aceita
  500 a 700); o verbo gigante é o `Label` em `Tema.bungee()` da R.

## Ao terminar

- No [quadro](README.md), a linha R: **feito**, com o commit.
- Commit sugerido (sem trailer):
  `feat: O Relâmpago — os 45 em microjogos com o objeto de cada um, o aquecimento com a sombra e o desempate`
