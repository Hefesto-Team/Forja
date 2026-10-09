# WS03 — A placa do controle não fecha à toa

**Sprint:** W · **Tamanho:** M · **Depende de:** H07

## Por quê

O doc 05 promete que a placa de áudio de cada controle abre na entrada do lugar e fica aberta até ele sair. Hoje,
toda vez que alguém entra ou sai do lobby, que um cabo volta no meio de um minigame ou que uma sala de som abre e
fecha, o módulo fecha o som de **todos** os controles e abre tudo de novo: o pio de quem acabou de entrar é cortado
pela entrada do seguinte, e a háptica e o alto-falante dos outros três somem em seco quando o cabo de um volta.

A causa: preparar foi escrito como «encerrar tudo e abrir do zero», e o encerrar fecha as saídas no mesmo instante em
que manda o mixer à rampa, antes de a rampa tocar.

## Ler antes

- [05 — A háptica e o controle, «A agenda do alto-falante»](../05-haptica-e-controle.md#a-agenda-do-alto-falante)
  (linhas 128-130: a placa abre na entrada e fica aberta).
- `nativo/som/som_controle.h` (a `SaidaCtl` e a `SomJogador`).

## O estado de hoje

- `nativo/som/som_controle.c:299-301`, o começo do `somc_preparar`:

  ```c
  void somc_preparar(Forja *a) {
    somc_encerrar(a);
    zerar();
  ```

  e o `somc_encerrar` (`:282-292`) passa `fechar_saida` em todas as saídas, e o `fechar_saida` (`:68-76`) faz
  `SDL_DestroyAudioStream(s->fluxo)` e zera a saída. A placa virtual dos controles simulados também é zerada e
  recriada vazia.
- `nativo/godot/forja_som.cpp:105-111`, o `som_encerrar`: `somc_parar_tudo` em cada lugar e, na linha seguinte,
  `somc_encerrar`. O `parar_tudo` só põe a rampa de 20 ms como alvo (`nativo/som/mixer.c:77-82`); a saída é destruída
  antes de o mixer misturar uma amostra dela.
- Quem chama o `som_preparar`:
  - `godot/scripts/main.gd:237` (fim do `_sincronizar_jogadores`) e `:260-275` (`_abrir_o_som`): a cada entrada ou
    saída de lugar no lobby, e logo depois toca o pio de quem entrou (`:275`). O pio dura uns 0,18 s
    (`sint_pio`, `nativo/som/sintese.c:515-517`): se a segunda pessoa entra antes disso, o pio da primeira some;
  - `main.gd:253` (`_abrir_o_som(true)`): quando um controle que caiu volta, no meio de qualquer sala;
  - `godot/scripts/salas/sala_jogo.gd:114` e `:117` (entrar numa sala de som) e `:128` (sair dela);
  - `main.gd:474` (o pódio, só se a placa não está aberta) e as salas `bancada.gd:112/120` e `prova.gd:107`.
- A troca de saída pela pessoa (`somc_trocar`, `som_controle.c:318-352`) já sabe religar só um lugar sem
  fechar os outros: o comentário dela diz que as saídas sem uso fecham quando a sala sai.
- A prova de hoje (`godot/testes/prova_do_jogo.gd:159-169`) faz cada simulado entrar com 20 quadros de distância e
  mede o pio de quem entrou: com essa folga, o corte nunca aparece.

## O alvo

`somc_preparar` reconcilia em vez de recomeçar: refaz a lista e a escolha dos nós e, para cada lugar, mantém a saída
cujo dispositivo não mudou (com o mixer, as vozes e a voz do alto-falante dela). Só a saída que mudou ou que ficou sem
dono sai, e sai **adiada**: é marcada, o mixer vai a zero pela rampa, e o `somc_atualizar` a destrói quando o mixer
esvaziou. O `som_encerrar` (o fim do jogo) segue o mesmo caminho adiado, com um teto de espera para o fim do processo.

## Passos

1. Na `SaidaCtl`, a marca de «fechando» e o dispositivo do SDL que a abriu (o `SDL_AudioDeviceID`, não o índice da
   lista, que muda a cada `listar`).
2. `somc_preparar`: listar, escolher, e para cada saída aberta conferir se algum lugar ainda a usa pelo mesmo
   dispositivo; a que ninguém usa vai para «fechando» com `mixer_parar_tudo`. As placas virtuais dos simulados que
   seguem na mesa ficam. O `g_voz_falante` de quem manteve a saída fica.
3. O microfone: o fluxo de gravação só se refaz se o nó do microfone mudou.
4. `somc_atualizar`: destrói a saída em «fechando» quando o mixer não tem voz ativa (ou passou o teto, uns 100 ms).
5. `ForjaControles::som_encerrar`: marca todas e espera o mixer pelo mesmo caminho; no fim do processo, o teto vale.
6. A prova nova.

## Armadilhas

- `alimentar` (`som_controle.c:55-65`) roda no fio de áudio com o ponteiro da saída: destruir o fluxo primeiro e só
  depois liberar o mixer, como o `fechar_saida` já faz.
- O índice `no` da saída aponta para a lista de antes do `listar`; comparar pelo dispositivo, nunca pelo índice.
- Com o rádio (sem placa), nada abre: o caminho novo não pode passar a abrir o que hoje não abre.
- A rota do alto-falante (`pad_alto_falante`, `forja_som.cpp:97-102`) é mandada a cada `som_preparar`; mandar de novo
  é inofensivo, mas não deve cortar o som que está tocando.

## Não fazer

- Não mudar quem chama em `main.gd` e `sala_jogo.gd`: a cura é no módulo, e os chamadores continuam pedindo «prepare».
- Não tirar o `somc_parar_tudo` do fim do jogo: só deixar a rampa tocar antes de fechar.

## Pronto quando

Com `--simular`: `Forja.som_falante(0, "sino", 0.9)`, 2 quadros, `Forja.som_preparar(Forja.PAPEL_ALTO_FALANTE)`,
1 quadro, e `Forja.som_virtual(0).falante` passa de 0,1 (hoje dá 0, porque a placa virtual do lugar 0 foi destruída e
recriada vazia). E dois simulados entrando com 3 quadros de distância: o pio do primeiro ainda soa no controle dele
quando o segundo entra.

## Provas

- `bash tests/prova_do_jogo.sh`, com os dois casos acima.
- `bash tests/prova_de_poucos.sh` (o cabo que cai e volta).
- O `forja-testes` do nativo continua verde.

## Para o André (local)

Com dois DualSense no cabo: com um minigame rodando e o alto-falante tocando no controle 1, tirar e pôr o cabo do
controle 2. O controle 1 não pode engasgar nem perder a vibração.

## Ao terminar

Pôr a linha no [quadro](README.md) como **feito**, com o gasto.
