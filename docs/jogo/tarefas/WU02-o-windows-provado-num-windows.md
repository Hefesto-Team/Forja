# WU02 — O Windows provado num Windows

**Sprint:** W · **Tamanho:** M · **Depende de:** — (as fichas [WU04](WU04-a-lista-de-som-na-ordem-em-que-chegou.md),
[WU05](WU05-a-letra-minuscula-sem-o-locale.md) e [WU06](WU06-o-som-pelo-nome-nunca-vai-para-outro.md) usam o
`forja-testes.exe` que esta cria)

## Por quê

O `.exe` nunca rodou num Windows. A régua do Windows é o Wine com quatro controles de mentira, e por isso o código
que só existe no Windows (o WASAPI e o CfgMgr32 do som de cada controle) nunca rodou em prova nenhuma: o
`forja-testes` nem é compilado para Windows. Um erro de texto puro passou assim: o caminho HID de um DualSense no
rádio vira o ID de instância «HID», e o controle fica sem o seu ContainerId.

## Ler antes

- `docs/VALIDAR.md:68-89` e `docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md` (o Windows hoje é só o Proton)
- `tests/prova_da_exportacao.sh` (a Prova de Fogo do binário Linux e do `.exe` pelo Wine)

## O estado de hoje

- Os seis jobs de `.github/workflows/forja.yml` são `ubuntu-24.04` (`:24, :97, :121, :160, :260, :331`).
- `scripts/compilar.sh:128-132`: o alvo `windows` sai com `-DFORJA_TESTES=OFF`; só o alvo `testes` (`:134-135`, Linux)
  liga as provas nativas.
- `tests/prova_da_exportacao.sh` roda o `.exe` pelo Wine com `--simular=4`. Com controle simulado,
  `somc_plataforma_pad` nunca é chamada (`nativo/som/som_controle.c:228-229`):
  ```c
  if (tem[s] && !pad->simulado)
    somc_plataforma_pad(a, s, usb[s], sizeof(usb[s]), cont[s], sizeof(cont[s]));
  ```
- `nativo/som/som_controle_windows.c:113-127`, `instancia_do_caminho`, corta no **primeiro** `#{`:
  ```c
  const char *chave = SDL_strstr(p, "#{");
  if (chave)
    n = (size_t)(chave - p);
  ```
  Medido copiando a função à parte: o caminho de cabo
  `\\?\hid#vid_054c&pid_0ce6&mi_03#7&2a9d1f0&0&0000#{4d1e55b2-…}` dá `hid\vid_054c&pid_0ce6&mi_03\7&2a9d1f0&0&0000`
  (certo); o de rádio `\\?\HID#{00001124-0000-1000-8000-00805f9b34fb}_VID&0002054c_PID&0ce6#9&2b8e6f3&0&0000#{4d1e55b2-…}`
  dá `HID`, porque o primeiro `#{` é o do perfil HID, não o da classe de interface, que fica no fim.
- O único teste do caminho Windows é um ContainerId escrito à mão (`nativo/testes/prova_achar_som.c:126`).
- O pacote em si está são: a DLL da corrida 37935555661 só importa DLLs do sistema e só exporta
  `forja_iniciar_biblioteca`.

## O alvo

O código do Windows tem prova: a lógica de texto roda no `forja-testes.exe` (pelo Wine no job de exportação), e o
`.exe` exportado roda a Prova de Fogo num executor Windows de verdade, numa pasta com espaço e acento. O caminho do
rádio dá o ID de instância certo. Nada muda na tela.

## Passos

1. **A função pura.** A conversão do caminho HID em ID de instância vai para o núcleo (`nativo/nucleo/achar_som.c` e
   `.h`), procurando o **último** `#{`. `som_controle_windows.c` passa a chamá-la.
2. **As provas nativas cruzadas.** `compilar.sh` ganha o alvo `testes-windows`: mingw, `FORJA_EXTENSAO=OFF`,
   `FORJA_TESTES=ON`. A parte de sysfs da `prova_origem.c` (`mkdtemp`, `symlink`) fica atrás de
   `#if defined(__linux__)`. O `forja-testes.exe` roda no job `exportar`, pelo Wine que já está lá.
3. **O job Windows.** Um job em `windows-latest` baixa o artefato `forja-windows-x86_64` e roda
   `forja.exe --headless --fixed-fps 60 -- --simular=4 --robo --semente=7 --prova-de-fogo --sair-no-fim
   --relatorios="<pasta com espaço e acento>"`. Confere a matriz contra a do binário Linux (o mesmo molde do
   `prova_da_exportacao.sh`) e que o registro traz a linha «som: …» com o rótulo do WASAPI (num executor sem placa,
   «sem endpoints no WASAPI», um ramo que hoje nunca rodou).

## Armadilhas

- **O custo do executor.** Em repositório público o executor Windows não custa; conferir a visibilidade antes e
  anotar aqui.
- **Sem controle no executor**: o job prova a pasta, o módulo e o som do sistema, não o DualSense. O controle no
  Windows segue para a bancada (abaixo).
- **A DLL e o `.exe` do mesmo artefato**: não recompilar no executor Windows; provar o que vai para o jogador.

## Não fazer

- Não trocar o mingw pelo compilador do Windows: o pacote de hoje está são.
- Não mexer na lógica de escolha do som (é da [WU06](WU06-o-som-pelo-nome-nunca-vai-para-outro.md)).

## Pronto quando

- O caminho do rádio dá `HID\{00001124-0000-1000-8000-00805f9b34fb}_VID&0002054c_PID&0ce6\9&2b8e6f3&0&0000`.
- O `forja-testes.exe` roda no CI, e o job Windows passa com a pasta de espaço e acento.

## Provas

- **Nativa** (`prova_achar_som.c`): os dois caminhos acima, o de cabo e o de rádio. Hoje o de rádio dá `HID`:
  reprova.
- **CI:** o job Windows não existe hoje; fica verde depois, com o relatório da Prova de Fogo igual ao do Linux.

## Para o André (local)

Num Windows de verdade, com um DualSense no cabo: abrir o `forja.exe` do pacote, entrar no lobby, tocar a sala de som.
O relatório diz «pelo aparelho» para o alto-falante. Anotar o que só o Windows mostra (o controle como dispositivo de
som padrão, o microfone bloqueado pela privacidade, o endpoint em dois canais).

## Ao terminar

Marcar WU02 como **feito** no [quadro](README.md), com o commit e o gasto. Commits sugeridos:
`fix(som): o caminho HID do rádio vira o ID de instância certo` e `ci: o .exe roda num Windows e as provas nativas
pelo Wine`.
