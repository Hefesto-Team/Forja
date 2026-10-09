# WU05 — A letra minúscula sem o locale

**Sprint:** W · **Tamanho:** P · **Depende de:** [WU02](WU02-o-windows-provado-num-windows.md) só para a prova pelo
Wine; a cura e a prova no Linux não esperam

## Por quê

O jogo acha os nós de som do controle pelo nome, em minúsculas. A conversão usa o `tolower` do C, que segue o
locale do processo. No Windows (e sob o Proton), o Godot liga o locale da máquina ao abrir, e a DLL da Forja usa o
mesmo `msvcrt.dll`: na página de código 1252, o primeiro byte do «á» em UTF-8 vira outro. A «Háptica do Controle N»
deixa de ser reconhecida como háptica numerada, vira um nó de saída genérico de quatro canais, e na passada pelo nome
a háptica de um jogador pode ir para o número de outro, e o mesmo nó passa a servir de alto-falante.

## Ler antes

- [O som chega ao controle](../../COMO-O-SOM-CHEGA-AO-CONTROLE.md) (os nós numerados)

## O estado de hoje

- `nativo/nucleo/achar_som.c:9-14`:
  ```c
  static void minusculo(const char *de, char *para, size_t tam) {
    size_t i = 0;
    for (; de && de[i] && i + 1 < tam; i++)
      para[i] = (char)tolower((unsigned char)de[i]);
  ```
  e `:110`, `isdigit((unsigned char)*p)`; a agulha `"háptica do controle"` em `:128`. A mesma conta está em
  `src/forja_alto_falante.c:27`.
- Godot 4.7.2 (godotengine/godot, MIT), `platform/windows/godot_windows.cpp:80`: `setlocale(LC_CTYPE, "");`.
- No pacote da corrida 37935555661 (`LC_ALL=C objdump -p`): o `forja.exe` importa `setlocale` de `msvcrt.dll`, e a
  `libforja.windows.x86_64.dll` importa `tolower` do mesmo `msvcrt.dll`. No `msvcrt` o locale vale para o processo.
- Na 1252, `0xC3` («Ã») vira `0xE3`: o «á» (`C3 A1`) vira `E3 A1`, e nem «háptica» nem «haptica» casam. Reproduzido à
  parte num locale de um byte (`pt_BR.ISO-8859-1` por `localedef` numa pasta do usuário): a busca falha; em
  `C.UTF-8`, acha. A prova roda só no Linux em UTF-8, onde o `tolower` não toca acima de 127.
- No 1252, o `isdigit` do `msvcrt` também conta ², ³ e ¹ como dígitos.

## O alvo

A minúscula e o dígito do achar som não dependem do locale: só A–Z baixam, só 0–9 são dígitos. Os nomes procurados e
a tela não mudam.

## Passos

1. Em `achar_som.c`: `minusculo` baixa só `'A'..'Z'` (`c + 32`), sem `<ctype.h>`; `achar_numero` usa
   `c >= '0' && c <= '9'`.
2. A mesma troca em `src/forja_alto_falante.c:27`, para a regra ter um dono só (ou a ferramenta passa a chamar a do
   núcleo).
3. `grep -n 'tolower\|toupper\|isdigit\|isalpha\|isspace' nativo src` e anotar aqui se outra busca de nome usa o
   locale.

## Armadilhas

- **Não converter os nomes para outra codificação**: o SDL entrega UTF-8 em todo sistema; basta não estragar os bytes.
- **O teste que cria o locale** precisa do `localedef` e de uma pasta temporária; sem o `localedef` na máquina, o
  caso é pulado com aviso, não reprovado.

## Não fazer

- Não trocar `setlocale` no módulo: o locale é do Godot.
- Não mudar as agulhas («háptica do controle», «alto-falante do controle»).

## Pronto quando

`achar_tipo("Háptica do Controle 1 (DualSense Wireless Controller)", false)` dá `NO_NUMERADO_HAPTICA` em qualquer
locale.

## Provas

- **Nativa** (`prova_achar_som.c`): cria um locale de um byte com `localedef` na pasta temporária, aponta `LOCPATH`,
  `setlocale(LC_CTYPE, "pt_BR.ISO-8859-1")` e espera `NO_NUMERADO_HAPTICA`. Hoje dá `NO_DUALSENSE_SAIDA`: reprova.
- **Pelo Wine**, com o `forja-testes.exe` da WU02: o mesmo caso com `setlocale(LC_CTYPE, "")`.

## Para o André (local)

Pelo Proton, com a ponte e os nós numerados: o relatório diz «háptica: Háptica do Controle N (pelo número)» para cada
lugar, cada um com o seu N.

## Ao terminar

Marcar WU05 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`fix(som): a busca do nó do controle não depende do locale da máquina`.
