# F07 — A voz nova do texto

**Sprint:** F · **Tamanho:** M · **Depende de:** F00, F02, F03

## Por quê

Botões e rótulos começam com minúscula ("começar", "pronto", "fechar"). A regra
agora é: todo texto de tela começa com maiúscula, e botão se escreve
"Botão ✕ (Iniciar)".

## Ler antes

- [06 — A voz do texto](../06-telas-e-fluxo.md#a-voz-do-texto)
- [13 — As convenções](../13-arquitetura.md#as-convenções) (todo texto passa por `Traducoes`; frase nova = entrada nova)

## O estado de hoje

**A tabela:** `godot/scripts/traducoes.gd`. `const EN := {` (`:14`) tem 233
pares português → inglês; **142 chaves** começam com minúscula (e os 142
valores em inglês também): `"começar"`, `"créditos"`, `"voltar"`, `"entrar"`,
`"pronto"`, `"sair"`, `"opções"`, `"simulado"`, `"humano"`, `"orc"`,
`"espada e escudo"`, `"sem controle"`, `"liberar o lugar"`, `"diagnóstico"`,
`"pausa"`, `"em breve"`, `"aguardando"`, `"trocar"`, `"testar"`… `const EN_PADROES := [`
(`:262`) tem 53 padrões, **18** começando com minúscula
(`"^treino · (.+)$"`, `"^canto (\\d+) de (\\d+)$"`, `"^a seguir: (.+)$"`,
`"^isso: era do P(\\d)$"`…). A conta sai com:

```bash
python3 - <<'EOF'
import re
s = open('godot/scripts/traducoes.gd', encoding='utf-8').read()
en = s[s.index('const EN := {'):s.index('const EN_PADROES')]
k = re.findall(r'^\s*"((?:[^"\\]|\\.)*)"\s*:', en, re.M)
print(len(k), sum(1 for x in k if x[:1].islower()))
EOF
```

**O botão:** `godot/scripts/ui/glifo.gd:106-113` desenha o glifo e a palavra:

```gdscript
static func dica(ci: CanvasItem, pos: Vector2, glifo: String, texto: String, tam: int, cor_glifo: Color, cor_texto: Color) -> float:
	tam = Tema.t(tam)
	texto = Desenho.t(texto)
	var lado := tam * 1.25
	desenhar(ci, glifo, Rect2(pos + Vector2(0, -lado * 0.82), Vector2(lado, lado)), cor_glifo)
	var f := Tema.fonte(600)
	ci.draw_string(f, pos + Vector2(lado + 10.0, 0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor_texto)
```

`largura_dica()` (`:98-103`) mede o mesmo. As fileiras são
`Desenho.dicas_a_direita()` e `dicas_a_esquerda()` (`ui/desenho.gd:178-192`).
Quem chama: `tela_titulo.gd:65-68`, `tela_lobby.gd:112-113`,
`cartao_jogador.gd:37`, `:60`, `:92-96`, `hud.gd:73-88`, `pausa.gd:65`,
`escolha_partida.gd:95`, `placar.gd:208-213`, `tela_creditos.gd:42`,
`tela_opcoes.gd:131`, `painel_sala.gd:110` (e o fim, que depois da F03 mora em
`ui/resultado.gd`), `painel_bancada.gd:61`, `diagnostico.gd:57` e `livro.gd:150`.

**"fechar"** (`diagnostico.gd:57`, `livro.gd:150`) não tem tradução.

**Os textos montados no código** que não são chave: por exemplo
`salas/sala_jogo.gd:390-399` (`status`: `"pronto"`, `"✕ quando pronto"`,
`"%d pontos"`, `"terminou · %d"`, `"treino ✓"`), `ui/painel_sala.gd:94`
(`"✓ pronto"`), `:100` (`"aguardando"`), `:428` (`"treino — não vale ponto"`),
as `partes` das dicas de cada sala (`"mira"`, `"atira"`, `"recarrega"`,
`"tropeçou!"`, `"esquerda"`…) e os `status()` das salas
(`galeria.gd:601` `"rodada %d de %d · %d ✓"`, `prova.gd:743`…).

**Do C, na tela do jogador:** `conexao_curta()`
(`nativo/godot/forja_controles.cpp:42-55`) devolve `"simulado"`,
`"declara USB"`, `"virtual"` — desenhados no HUD e no cartão; e
`tela_titulo.gd:49-52` casa `"simulado"` para contar. Os avisos
(`forja_avisar`) já começam com "P2…" ou "Esse…".

**A coleta** (F02): na rodada sem `--bancada`, a prova do jogo liga
`Desenho._coletar = "memoria"` e tem cada frase desenhada em
`Desenho._coletados`.

## O alvo

- **Toda frase de tela começa com maiúscula**, nas duas línguas; o resto da
  frase na escrita normal ("Começar", "Jogar no teclado", "Salas vencidas").
  Número no começo vale ("12 s", "3 cantos seus").
- **Botão:** `Glifo.dica` desenha "Botão", o glifo e a ação entre parênteses:
  "Botão ✕ (Iniciar)". Numa fileira, "Botão" só na primeira. As pílulas de
  dica dentro das salas (glifo + palavra, embaixo da raia) ficam sem "Botão",
  mas a palavra ganha maiúscula ("Mira", "Atira").
- **Um portão:** `scripts/check_texto_de_tela.py` lê `traducoes.gd` e reprova
  chave, valor ou padrão que comece com minúscula; roda no começo de
  `tests/prova_do_jogo.sh`.
- **A prova do jogo**, na rodada sem `--bancada`, reprova qualquer frase colhida
  na tela que comece com letra minúscula.

```gdscript
# glifo.gd (a assinatura nova; o último argumento é opcional)
static func largura_dica(glifo: String, texto: String, tam: int, com_botao := true) -> float
static func dica(ci: CanvasItem, pos: Vector2, glifo: String, texto: String, tam: int,
		cor_glifo: Color, cor_texto: Color, com_botao := true) -> float
```

## Passos

1. **O portão** `scripts/check_texto_de_tela.py` (novo, executável, sem
   dependência fora da biblioteca padrão):
   ```python
   #!/usr/bin/env python3
   """O portão do texto de tela (docs/jogo/06, a voz do texto): toda frase da
   tabela de traduções começa com maiúscula, em português e em inglês."""
   import pathlib, re, sys

   RAIZ = pathlib.Path(__file__).resolve().parent.parent
   src = (RAIZ / "godot/scripts/traducoes.gd").read_text(encoding="utf-8")
   en = src[src.index("const EN := {"):src.index("const EN_PADROES")]
   pad = src[src.index("const EN_PADROES"):]
   pares = re.findall(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"', en, re.M)
   padroes = re.findall(r'^\s*\["((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\]', pad, re.M)

   def minuscula(s: str) -> bool:
       for c in s:
           if c.isdigit() or c in "$(\\[":
               return False  # número, grupo ou referência: não se julga
           if c.isalpha():
               return not c.isupper()
       return False

   falhas = [f"{k!r} → {v!r}" for k, v in pares if minuscula(k) or minuscula(v)]
   falhas += [f"{p!r} → {v!r}" for p, v in padroes if minuscula(p.lstrip("^")) or minuscula(v)]
   for f in falhas:
       print("FAIL texto de tela com minúscula:", f)
   print(f"texto de tela: {len(pares)} frases e {len(padroes)} padrões, {len(falhas)} com minúscula")
   sys.exit(1 if falhas else 0)
   ```
   Rode agora: tem de reprovar (hoje, 163 frases ou padrões: é a lista a virar).
2. **O botão** em `ui/glifo.gd`: `dica()` e `largura_dica()` com
   `com_botao := true`. Com ele, desenha `Desenho.t("Botão")`, 10 px, o glifo,
   10 px e `"(%s)" % Desenho.t(texto)`; sem ele, o glifo, 10 px e `"(%s)"`. A
   largura soma o mesmo. Em `ui/desenho.gd:178-192`, `dicas_a_direita()` passa
   `com_botao = (i == 0)` (o laço anda de trás para a frente: a primeira da
   fileira é o índice 0) e `dicas_a_esquerda()` passa `true` só na primeira.
   Chave nova `"Botão": "Button"`.
3. **A tabela** (`traducoes.gd`): virar as 142 chaves e os 142 valores
   (`"começar": "start"` → `"Começar": "Start"`), e os 18 padrões com o valor
   (`["^treino · (.+)$", "practice · $1"]` → `["^Treino · (.+)$", "Practice · $1"]`).
   Em cada chave mudada, mudar **a frase no código** que a produz (procure a
   frase entre aspas em `godot/scripts/`). `"jogar no teclado (Enter)"` vira
   `"Jogar no teclado · Enter"` (os parênteses agora são do botão). Nova:
   `"Fechar": "Close"`.
4. **Os textos montados** em `godot/scripts/ui/*.gd` e `godot/scripts/salas/*.gd`:
   maiúscula no começo de cada frase de tela (`status`, `dica`, `progresso`,
   `com_poucos`, as frases dos painéis), e uma entrada em `traducoes.gd` (ou um
   padrão, com número no meio) para cada frase que ainda não tem.
5. **Do C:** `conexao_curta()` (`forja_controles.cpp:42-55`) →
   `"Simulado"`, `"Declara USB"`, `"Virtual"`; `tela_titulo.gd:52` casa
   `"Simulado"`; as chaves `"simulado"` e `"·  simulado"` da tabela viram
   `"Simulado"` e `"·  Simulado"`. `scripts/compilar.sh linux` (sem o jogo aberto).
6. **Ligar o portão** em `tests/prova_do_jogo.sh`, logo depois da guarda do
   Godot (`:18`): `python3 "$RAIZ/scripts/check_texto_de_tela.py" || exit 1`.
7. **A prova**: a checagem de "Provas".

## Armadilhas

- **Chave e código juntos.** A tradução acha a frase **exata**
  (`Traducoes.traduzir`, `traducoes.gd:320-336`): mudar a frase no código sem
  mudar a chave (ou o contrário) apaga o inglês daquela frase sem erro nenhum.
  Depois de virar, rode `FORJA_IDIOMA=en` nas fotos (com o André).
- **"Botão" alarga as dicas.** O cartão do lobby tem 384 px
  (`tela_lobby.gd:16`) e põe duas dicas lado a lado (`cartao_jogador.gd:95-96`):
  confira nas fotos; se não couber, a segunda sai sem "Botão" (`com_botao = false`).
  A placa do portão no HUD (`hud.gd:73-84`) já mede com `largura_dica`.
- **As pílulas** das salas (`painel_sala.gd:151-211`, as `partes` com `@glifo`)
  não passam pelo `Glifo.dica`: só a palavra muda de caixa.
- **O texto do núcleo** (o porquê de cada veredito, os textos dos
  experimentos) continua em português com minúscula, e só aparece no Modo
  bancada: fica fora desta ficha (e fora da checagem da prova, que roda na
  rodada sem `--bancada`).
- **Sigla fica em caixa alta** (USB, BT, L2, R2); nunca caixa alta decorativa.
  "✓ PRONTO" (`cartao_jogador.gd:91`) vira "✓ Pronto".
- **A F02 já tirou as frases metalinguísticas**; não traga nenhuma de volta ao
  reescrever.

## Não fazer

- Não traduzir nem reescrever o texto do C das vereditos e dos experimentos.
- Não redesenhar telas (G01, G04): só a caixa e o formato do botão.
- Não mudar o sentido de nenhuma frase (isso foi a F02).

## Pronto quando

O portão passa; a prova do jogo, na rodada sem `--bancada`, não acha nenhuma
frase de tela começando com minúscula; e toda dica de botão da tela é
"Botão ✕ (Ação)".

## Provas

Na sessão: `python3 scripts/check_texto_de_tela.py` e `bash tests/prova_do_jogo.sh`.

Em `godot/testes/prova_do_jogo.gd` (a coleta é a da F02), uma função chamada
no fim de `_ready()`:

```gdscript
## A primeira letra de uma frase de tela é maiúscula; número no começo vale.
static func _comeca_com_maiuscula(s: String) -> bool:
	for i in s.length():
		var c := s.substr(i, 1)
		if c >= "0" and c <= "9":
			return true
		if c.to_upper() != c.to_lower():  # é letra
			return c == c.to_upper()
	return true  # só símbolos


func _prova_das_maiusculas() -> void:
	if Forja.bancada:
		return  # o texto do núcleo (os vereditos) fica como está
	var achadas: Array = []
	for s in Desenho._coletados:
		if not _comeca_com_maiuscula(str(s)):
			achadas.append(s)
	_esperar(achadas.is_empty(), "jogo: toda frase de tela começa com maiúscula (%s)" % [achadas.slice(0, 12)])
	_esperar(Desenho._coletados.has("Botão"), "as dicas de botão dizem \"Botão\"")
```

## Para o André (local)

- `bash tests/telas.sh fotos <pasta>` e, com `FORJA_IDIOMA=en`, de novo:
  conferir o título, o lobby, uma sala, o resultado e o pódio nas duas línguas
  — nada começando com minúscula, as dicas como "Botão ✕ (Começar)", nada
  cortado nos cartões.
- `./run-local.sh -- --bancada --sala=galeria`: as perguntas e a tabela também
  com maiúscula (menos o porquê de cada veredito, que vem do núcleo).

## Ao terminar

- No [quadro](README.md), a linha da F07: estado **feito** (com o commit).
- Commit sugerido: `feat: a voz do texto — maiúscula em toda frase e "Botão ✕ (Iniciar)"`
