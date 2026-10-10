# WU08 — O pacote ensina o que falta

**Sprint:** W · **Tamanho:** P · **Depende de:** [WU03](WU03-a-regra-do-udev-que-cobre-e-avisa.md) (o texto da
regra do udev é dela; esta não o reescreve)

## Por quê

O pacote é a primeira coisa que o jogador lê, e hoje ele ensina o caminho de uma máquina só. A entrada de menu do
Linux que vai na pasta e no `.tar.gz` não acha o jogo nem o ícone fora do AppImage. O LEIA-ME do Linux não diz para
desligar o Steam Input, que no Steam Deck e em todo jogo adicionado à mão vem ligado e tira os efeitos do DualSense.
O do Windows só ensina o Proton: nada para quem abre o `forja.exe` direto.

## Ler antes

- `scripts/exportar.sh` (`leia_me` e `desktop`) e `docs/VALIDAR.md:68-89`
- [WR04](WR04-o-dualsense-pela-steam.md) (o que o jogo faz quando o Steam Input toma o controle)

## O estado de hoje

- `scripts/exportar.sh:143-155`, a entrada de menu, sem caminho:
  ```
  Exec=forja.x86_64
  Icon=forja
  ```
  A especificação das entradas de menu procura o `Exec` no `PATH` e o ícone no tema, não na pasta do arquivo. Ela vai
  para o AppImage (`:178`, onde o `AppRun` resolve) e também para a pasta solta (`:226`), onde não resolve.
- `scripts/exportar.sh:104-111`: o LEIA-ME do Linux explica a regra do udev e para aí. O passo «desative o Steam Input
  para este jogo» existe só no ramo do Windows (`:122`), dentro de «Pelo Proton, na Steam» (`:114`).
- O LEIA-ME do Windows (o mesmo `:113-124`) não tem uma seção para o `forja.exe` aberto direto: o cabo para som,
  háptica e microfone; fechar programas que seguram o controle (os que remapeiam o DualSense ou o escondem); a Steam
  aberta segurando o controle; o aviso de app desconhecido na primeira abertura (o `.exe` não é assinado).
- O CI já instala o `desktop-file-utils` (`.github/workflows/forja.yml:206`).

## O alvo

O `forja.desktop` da pasta funciona onde for copiado, ou não vai na pasta; o LEIA-ME de cada sistema diz o que o
jogador precisa fazer para ter o DualSense inteiro. As telas do jogo não mudam.

## Passos

1. Na pasta do Linux, trocar o `forja.desktop` por um `instalar-atalho.sh` curto, sem sudo, que escreve
   `~/.local/share/applications/forja.desktop` com o caminho absoluto do `forja.x86_64` e do ícone. O AppImage fica
   com o `.desktop` de hoje.
2. O LEIA-ME do Linux ganha o passo do Steam Input (o mesmo texto do Windows, sem o Proton).
3. O LEIA-ME do Windows ganha a seção «Abrindo o forja.exe» com os quatro pontos acima, na voz do pacote.

## Armadilhas

- **Sem nome de programa de terceiros no texto do pacote**: descrever («programas que remapeiam o DualSense»), não
  nomear.
- **O texto do udev** é da WU03: não duplicar.

## Não fazer

- Não assinar nada nesta ficha: não há certificado (o campo do preset, `godot/export_presets.cfg:68`, fica como está).
- Não mexer no AppImage.

## Pronto quando

- O atalho criado pelo script abre o jogo com o ícone.
- Os dois LEIA-ME falam do Steam Input; o do Windows fala do `.exe` aberto direto.

## Provas

- **Na `prova_da_exportacao.sh`:** `desktop-file-validate` no `.desktop` que o script escreve (numa pasta
  temporária) e o `Exec` apontando para um executável que existe. Hoje o `.desktop` da pasta tem `Exec` sem caminho:
  reprova.
- **De texto:** o LEIA-ME do Linux contém «Steam Input»; o do Windows tem a seção do `.exe`. Hoje não.

## Para o André (local)

Descompactar o `.tar.gz` numa pasta qualquer, rodar o `instalar-atalho.sh`, abrir pelo menu do sistema.

## Ao terminar

Marcar WU08 como **feito** no [quadro](README.md), com o commit e o gasto. Commit sugerido:
`docs(pacote): o atalho do Linux funciona fora do AppImage, e os dois LEIA-ME falam do Steam Input`.

## O que foi feito (leva 1, a-entrega)

- **O atalho:** a pasta do Linux (e o `.tar.gz`) não leva mais o `forja.desktop` sem caminho. No lugar vai o
  `instalar-atalho.sh`, que não pede sudo e escreve `~/.local/share/applications/forja.desktop` (ou o do
  `XDG_DATA_HOME`). A entrada sai com:
  - o `Exec` absoluto e entre aspas, escapado como a especificação manda (a barra invertida, as aspas, a crase e o cifrão
    escapados, e o `%` dobrado);
  - o `Path` da pasta e o `Icon` absoluto.

  Os outros campos saem da mesma `desktop()` do AppImage, que não mudou. O `docs/DESENVOLVER.md` diz o que o
  pacote leva.
- **O LEIA-ME do Linux:**
  - ganha a linha do atalho;
  - ganha o passo do Steam Input, com o mesmo texto do Windows, sem o Proton;
  - o texto do udev é o da WU03, e ficou como estava.
- **O LEIA-ME do Windows:** ganha «Abrindo o forja.exe», com quatro passos:
  - o cabo: sem fio, o jogo recebe só os botões, e o som, a háptica, os gatilhos, a luz e o microfone pedem o cabo;
  - fechar os programas que remapeiam o DualSense ou o escondem, sem nome de terceiro;
  - a Steam aberta segurando o controle;
  - o aviso de fornecedor desconhecido na primeira abertura.

  O «Pelo Proton» continua igual.
- **As provas:** a `tests/prova_da_exportacao.sh` roda o `instalar-atalho.sh` numa casa de mentira duas vezes:
  - uma na pasta do pacote;
  - outra numa pasta com espaço, aspas, cifrão e porcento no nome.

  Nas duas, ela passa o `desktop-file-validate` no arquivo escrito, desfaz o `Exec` como a especificação manda e
  confere que ele aponta para o `forja.x86_64` da pasta e que o `Icon` existe. Ela também confere o texto: «Steam
  Input» nos dois LEIA-ME e a seção do `.exe` no do Windows. A conferência antiga (`^Exec=forja.x86_64`) saiu.
  - Rodada inteira: `scripts/exportar.sh linux` com o módulo do contêiner `manylinux_2_28`, depois
    `SO_LINUX=1 bash tests/prova_da_exportacao.sh`, que sai 0.
  - Mordida: sem o escape do `Exec`, o `desktop-file-validate` reprova a pasta esquisita (o `$` sem escape e o
    `%/` como código de campo). O texto de antes reprova as duas conferências de texto.
  - O LEIA-ME do Windows foi conferido pelo texto que a `leia_me windows` gera; o `.exe` não foi exportado
    nesta máquina. Sem o `.exe` exportado, a prova não confere o texto do Windows: quem confere é o CI.
  - Na conferência: sem o `desktop-file-validate` na máquina, a prova agora reprova e diz o pacote que falta
    (o `desktop-file-utils`), em vez de seguir só com o caminho conferido.
- **Fica para ela:** ler os dois LEIA-ME na voz do pacote, principalmente o passo 3 do Windows (a Steam aberta).
- **Fica para o André:** o passo da seção «Para o André»: descompactar o `.tar.gz`, rodar o
  `instalar-atalho.sh` e abrir pelo menu.
