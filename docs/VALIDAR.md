# Validar o Hefesto com quatro DualSense

O Forja existe para isto: quatro pessoas jogam, e o jogo anota, controle por
controle, o que pediu e o que chegou. É assim que o
[Hefesto](https://github.com/Hefesto-Team/hefesto-dualsense4unix) se prova —
jogando, com a mesa como oráculo. Este é o roteiro de uma rodada completa.

Duas rodadas: os quatro controles **no cabo**, depois os quatro **no rádio**;
no fim, os dois relatórios lado a lado. Anote a versão do Hefesto e use a
mesma semente nas duas (`--semente=7`).

### No cabo

1. Ligue os quatro DualSense no USB e abra o jogo (`./run-local.sh -- --semente=7`).
2. No título, ✕. No lobby, cada um aperta ✕, na ordem P1…P4. Confira em cada
   controle: a lightbar na cor do cartão e os LEDs de jogador no padrão do
   lugar; no cartão, "USB", `054c:0ce6` e "DualSense nativo".
3. Cada um aperta ✕ de novo (pronto). No salão, Create abre o diagnóstico:
   mexa em tudo em cada controle — no mapa dele, a peça apertada acende em
   rosa, o analógico anda, o dedo no touchpad aparece, o giroscópio mostra a
   taxa. ○ fecha.
4. Jogue as salas que medem: A Centelha (as runas: todos os botões, os dois
   analógicos até a borda, os dois gatilhos no meio e no fundo), A Viga
   (incline o controle para equilibrar, gire para mirar nos sinos, sacuda para
   quebrar a pedra) e O Molde (trace a letra no touchpad, abra e feche com dois
   dedos, clique quando o metal brilhar). No fim de cada uma, o veredito de
   cada um na tela, por feature, com o que foi medido.
5. Jogue as salas às cegas, que perguntam o que a tela não mostra: O Impacto
   (sinta de que lado veio o golpe e levante o escudo daquele lado; no fim da
   onda, diga a cor da luz do seu controle) e A Galeria (aperte R2 e diga que
   arma é pelo gatilho; depois, conte as luzinhas embaixo do touchpad).
6. Jogue as salas de som. No aviso de cada uma, confira embaixo do seu nome o
   dispositivo que o jogo achou para você e como achou (pelo aparelho, pelo
   número, pelo nome): △ toca o teste nele (o sino no alto-falante; um pulso
   na esquerda e outro na direita, na háptica; no microfone, fale e a barra
   sobe), ◀ ▶ troca. O Canto (o canto saiu do seu controle? e repita o
   ritmo), Os Caminhos (sinta o chão e o lado da pedra, sem olhar a tela) e
   A Voz (silêncio; chame o guardião na sua vez; fique mudo pelo botão do
   microfone; diga como está a luz dele).
7. Na bigorna do meio do salão, ✕ entra n'A Prova: noventa segundos de partida
   com tudo ligado, e no fim diga as luzinhas e a cor do seu controle sem olhar
   a tela. Na mesma bigorna, △ acende a **Prova de Fogo**: todas as salas, na
   ordem do percurso, sem voltar ao salão, e o livro no fim
   (`./run-local.sh -- --prova-de-fogo` começa direto nela).
8. Options → O livro da sessão mostra a tabela. Os arquivos estão em
   `relatorios/`: `relatorio-<sessão>.txt` para ler, `.json` e a linha do tempo
   para comparar.

### No rádio

1. Pareie os quatro DualSense pelo Bluetooth, com o Hefesto rodando.
2. Abra o jogo com a mesma semente e repita os passos do cabo.
3. O cartão diz a origem que o jogo vê: com o Hefesto na frente, "DualSense
   Edge virtual" (ou "Xbox virtual", conforme o modo dele). Um DualSense
   nativo no rádio, sem ninguém na frente, entra só com a entrada, e o cartão
   diz isso ([ADR-005](adr/005-o-radio-nativo-so-entrada.md)).

### Os dois relatórios

Ponha `relatorio-<cabo>.txt` e `relatorio-<rádio>.txt` lado a lado: cada
diferença é um trabalho para o Hefesto — a feature, o controle, o que foi
pedido e o que chegou.

<p align="center">
  <img src="imagens/livro.jpg" alt="O livro da sessão: feature por lugar, com o veredito de cada um" width="80%">
</p>

## Rodar o .exe pelo Proton

O `.exe` é o do pacote `forja-windows-x86_64` (o artefato do CI, ou
`scripts/exportar.sh windows`). Descompacte a pasta inteira: o `forja.pck` e a
`libforja.windows.x86_64.dll` ficam ao lado do `forja.exe`.

1. Na Steam: **Jogos → Adicionar um jogo não-Steam à minha biblioteca… →
   Procurar…**, com o filtro em todos os arquivos, e escolha o `forja.exe`.
2. **Propriedades → Compatibilidade → Forçar o uso de uma ferramenta de
   compatibilidade específica do Steam Play**, e escolha um Proton.
3. **Propriedades → Controle**: desative o Steam Input para este jogo (com ele
   ligado, o jogo recebe um controle Xbox e perde o resto do DualSense).
4. Os argumentos entram em **Propriedades → Geral → Opções de inicialização**,
   depois de um `--` (por exemplo, `-- --semente=7`). Os relatórios ficam em
   `relatorios/`, ao lado do `.exe`.

A cada push, o CI roda esse mesmo `.exe` pelo Wine do Ubuntu, a base do
Proton: o robô joga a Prova de Fogo inteira com quatro DualSense simulados, e
o relatório tem de sair igual ao do binário Linux. O som de cada controle sob
Proton depende da versão dele: [docs/COMO-O-SOM-CHEGA-AO-CONTROLE.md](COMO-O-SOM-CHEGA-AO-CONTROLE.md).

