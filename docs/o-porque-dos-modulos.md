# O porquê dos módulos

O que o código não diz e custaria caro redescobrir: a medida, a armadilha que já mordeu, a alternativa recusada.
Nasceu do [ADR-010](adr/010-o-codigo-nao-tem-comentario.md): o código não tem comentário, e o porquê que vale guardar mora aqui.

Cada seção é uma pasta ou um arquivo; o ponto é o símbolo, nunca a linha. O que já está em `docs/` só é apontado.

## experimental/

- `rumble_seco.sh`: com o SDL já em zero, `SDL_RumbleGamepad(0, 0)` não manda pacote (`SDL_joystick.c`, «Just update the expiration»), e o motor seguiria vibrando.
- Por isso o seco só para pelo `forja-send`, com os motores em zero e sem os bits de rumble.
- O protocolo do arquivo de comandos (`LUGAR FORCA MS`, `parar LUGAR`, `fim`, a resposta em `ARQUIVO.ok`) está em [experimental/README.md](../experimental/README.md).

## estudos/direcao

- `fita.gd`: o teto do croma é 0,098, porque em 0,100 exato o arredondamento do PNG de 8 bits dá 0,101.
- `fita.gd`: a recoloração anda em linha reta no plano a/b do OKLab e nunca gira o matiz; girar leva o laranja ao magenta, que é de um jogador.
- `fita.gd`, `pintura.gd`: a pele no UV é x 336–511, y 380–511, medida nos 12 Mini Characters.
- `fita.gd`: o limão de P3 é mais amarelo para se separar do ciano na tritanopia; o âmbar de P4, mais fundo para se separar do limão na deuteranopia.
- `racas.gd`: as cabeças feitas por código vão ×1,30; as medidas do [doc 04](jogo/arte/04-o-cavaleiro.md) saíram 30% menores que a cabeça humana (0,45 de largura) e a raça sumia na tela.
- `racas.gd`: as peças são indexadas e levam tangentes, porque o `_juntar` funde num índice só e a peça sem índice ficaria de fora.
- `racas.gd`: gerar normais alisava as quinas e borrava o chanfro; cada caixa guarda as próprias normais planas.
- `montar.gd`: o eixo do osso dos Mini Characters não corre ao longo do braço; o pulso sai da malha, não do osso.
- `cortar.gd`: nenhum triângulo da malha do corpo é misto, então o corte não abre buraco.
- `hud.gd`: o glifo tem de ser descomprimido; comprimido, ele sai quadrado no renderizador de software.
- `medir_contatos.gd`: a pose sai das trilhas da animação, não do mixer, porque o mixer não aplica nada fora do laço de quadros.
- `mundo.gd`: o neon não projeta sombra; com sombra, o anel de runas desenha um octógono escuro no chão.
- `mundo.gd`: com o glow ligado, o fundo do renderizador Compatibility sai ~3,5× mais claro e mais azul (#0d0a16 virou #2e1f5b); o fator 0,45 devolve. A cor está em [arte/02](jogo/arte/02-cor-e-letra.md).
- `10_montagem`, `17_forja`: a luz principal é sempre tungstênio e a contraluz é baixa: violeta ou branco frio tingiam o corpo e a peça de rosa.
- `11_pecas`: a peça de baixo se desenha a 1,8×; a ~42 px a calça não se lia.
- `teste_64.gdshader`: um cinza sRGB com o mesmo L do OKLab é L³ no linear.
- `gerar_sons.py`: o pulso estreito tem média DC que precisa sair, ou vira um baque grave.
- `gerar_sons.py`: o laço cruza os últimos 0,5 s com o começo.

## godot/shaders

- `contorno.gdshader`: o casco cresce pela normal suavizada guardada em `TANGENT`. Os blocos Kenney têm normal partida por face, e o casco abriria nas quinas.
- `contorno.gdshader`, `neon.gdshader`: o canal mais forte é limitado a 1; sem isso o tonemap faz do âmbar e do limão o mesmo amarelo.

## godot/scripts/alto_falante_do_controle.gd

- O `AudioServer` do Godot lista os nós pelo nome interno; o alto-falante de um controle no rádio não tem a palavra da Sony ali, só na descrição.
- `procurar_em_fundo`: o `pactl` custa milissegundos, então a pergunta roda num fio de trabalho.
- `ler_a_lista`: a saída tem de ser lida de volta. O servidor pode recusar, e o Godot cai calado no "Default".
- Nunca pelo MAC, socket ou hidraw ([CONTRATO.md](../CONTRATO.md)).

## godot/scripts/forja.gd

- `_robo_rng_mao`: o tremor da mão do robô tem gerador próprio, para não mudar o sorteio dos toques (a mesma semente dá o mesmo jogo com ou sem `--fixed-fps`).
- O robô agenda pelo id, não pelo nó: um nó liberado antes do timer chega como `null`.
- `sentir_forca` fica fora da tabela de sensações e pula a escala das opções, para que o par às cegas compare força igual dos dois lados.

## godot/scripts/main.gd

- `_ao_mudar_os_controles`: um controle que cai e volta pode voltar noutro nó de áudio, então a placa de som se refaz.
- Refazer a placa na nova busca do título cortaria o piado de quem acabou de entrar.
- A câmera guarda a largura em telas 16:10 (o Steam Deck).
- `_trocar`: a troca de cena cabe em 400 ms, pelo [estudo 02](estudos/02-manuais-de-ui-e-ux.md) (item 26).
- `_registrar_na_colecao`: a coleção fala pelo apelido do portão; o slot (`S01_J01`) não acende portão.

## godot/scripts/minigames/minigame.gd

- O minigame não escreve `_init`; se escrever, o `super()` vem primeiro, porque a `ficha` é lida ali.
- Os eventos `minigame` e `desempenho` têm um dono só: a `SalaJogo`.
- O kit não declara `colocacao()`.

## godot/scripts/musica.gd

- O BPM real deriva do pedido: o módulo trunca o tempo para um número inteiro de amostras (`SINT_TAXA`).

## godot/scripts/opcoes.gd

- As opções se guardam por máquina, nunca por aparelho.
- `noite()` é a data de seis horas atrás: a noite que passa da meia-noite continua a mesma.
- Um arquivo antigo que só guardava o tremor leva o "desligado" a Reduzido.
- Recurso desligado nas opções dá "não medido", nunca "falhou".
- `ajustar_gatilho`: o gatilho fraco corta a força pela metade, no campo b para Feedback e Vibration, no campo c para Weapon.

## godot/scripts/player.gd

- As superfícies voltam ao material do kit antes do `queue_free`. Um material duplicado com `next_pass` morrendo na fila de exclusão faz o servidor de render dizer «Parameter material is null» no quadro em que outro boneco nasce.
- O AABB sai só das transformações locais, porque o boneco pode ainda não estar na árvore.

## godot/scripts/pos_fita.gd

- No máximo 3 rasgos por segundo, e nenhum sem os Flashes ligados.

## godot/scripts/ritmo.gd

- A latência de saída se lê uma vez por faixa: a leitura é cara.
- `process_priority`: o Forja é -101, o módulo -100, o Ritmo -90 (depois dos dois), as salas 0.
- `_ms`: os ms guardam uma casa, para tirar o ruído do float e do `Vector2` de 32 bits.
- O relógio de áudio em si está em [docs/jogo/04](jogo/04-ritmo-e-audio.md#o-relógio-de-áudio).

## godot/scripts/partida.gd

- O sorteio é Fisher–Yates com o gerador da semente: o mesmo sorteio em toda máquina.
- A regra da colocação e do desempate está em [SALAS.md](SALAS.md#a-partida--o-placar-e-o-pódio).

## godot/scripts/salas/

- `caminhos.gd`: 0,2 s de silêncio fecha um toque, porque a água tem 0,1 s de buraco entre as duas ondas; a cauda do metal (0,55 s) cabe entre dois passos.
- `galeria.gd`, `_arma_sentida`: a arma se reconhece pelo primeiro byte do efeito do R2.
- `impacto.gd`: a lightbar é uma cor só, então o lado vem do motor.
- `prova.gd`: com o cabo fora, a saída não chega a controle nenhum, e isso não é o SDL recusando.
- `prova.gd`: o microfone fica de fora, porque numa sala todo mundo ouve todo mundo.
- `voz.gd`: sem a bancada, o chamado e o mudo acontecem uma vez por pessoa, nunca em três toques de treino; senão caem no treino e a sala acaba sempre 0 a 0.
- `voz.gd`: o mudo é o `MISC1` do SDL ([COMO-O-SOM-CHEGA-AO-CONTROLE.md](COMO-O-SOM-CHEGA-AO-CONTROLE.md)).
- `sala.gd`: um tremor novo só substitui o vivo se a amplitude dele for ≥ o `abalo` de agora.

## godot/scripts/som.gd

- Os sons que as salas medem ficam sintetizados: a assinatura deles é a régua.
- `no_controle`: nas provas às cegas, o som no controle só depois da resposta.
- `laco`: o som em laço é uma cópia, para que um `tocar` do mesmo id não herde o laço.

## godot/scripts/tema.gd

- `CHAVE_SECAO` é constante, não conta: `TUNGSTENIO.lerp(tinta, 0.2)` dá #f4bb90 onde a tabela pede #ffc99c.
- `JOGADOR`: a lightbar usa esta mesma tabela, a `LUZ_DO_LUGAR` de `nativo/nucleo/pads.c`. As duas andam juntas.

## godot/scripts/traducoes.gd

- `traduzir`: a tabela se escreve com maiúscula; a frase no meio de outra se acha pela forma com maiúscula e volta com a inicial minúscula.

## godot/scripts/ui/

- `desenho.gd`: os desenhos se contam pelo sinal `draw` do nó, não pelo número do quadro. Sem `--fixed-fps`, um nó desenha mais de uma vez por quadro (uma por passo de física).
- `desenho.gd`, `anotar`: o retângulo é a caixa da tinta (0,78 acima da linha de base, 0,22 abaixo), não a da linha.
- `desenho.gd`, `anotar`: guarda o texto já traduzido; cortado em português, a tradução não o acharia.
- `teclado_do_nome.gd`, `tela_lobby.gd`: a repetição de tecla conta segundos de parede, porque com `--fixed-fps` o robô correria. A prova troca para o tempo do jogo, para que um aperto de 2 quadros sob carga não repita.
- `tela_opcoes.gd`: o tique do metrônomo usa o relógio do sistema (o Ritmo está parado ali), e a batida achada tarde passa calada.
- `tela_virar.gd`: o texto que gira não tem retângulo certo, então a régua mede o quadro parado.

## godot/testes

- `prova_de_poucos.gd`: o ✕ do aviso só vem depois da entrada do kit (1,6 s e até dois compassos), então a conta dos 120 quadros começa no aviso.
- `prova_de_poucos.gd`: todo player para antes do `quit`, senão «resources still in use at exit». O `stop` só marca o fim: espera o mixer e o próximo quadro.
- `prova_do_jogo.gd`: todo som de `assets/sons` é PCM16 (`compress/mode=0`). O alto-falante do controle lê o `data` como PCM16, e o comprimido sai ruído.
- `prova_do_jogo.gd`: na sessão acelerada, o `t` em float do `forja.h` passa de 0,5 s de erro depois de 1465 s; daí a folga de 0,5%.
- `prova_do_jogo.gd`: o primeiro quadro leva de 0,3 a 10 s de parede.
- `prova_do_jogo.gd`: a cor passa por 8 bits, então a conferência dá um degrau de folga.
- `prova_visual.gd`, `prancha_da_luz.gd`: precisam de Xvfb, porque o `--headless` não devolve imagem. A aparência não se aprova no renderizador de software.
- As fotos (`captura_jogo.gd`) estão em [DESENVOLVER.md](DESENVOLVER.md#as-fotos-e-o-trailer).

## include/

- `forja_alto_falante.h`: dois jeitos de achar o alto-falante, pelo aparelho e pelo nome. O porquê de cada um está em [COMO-O-SOM-CHEGA-AO-CONTROLE.md](COMO-O-SOM-CHEGA-AO-CONTROLE.md#como-a-tech-demo-acha-o-som-de-cada-jogador).
- `forja_alto_falante.h`: na placa de 4 canais do DualSense, só o canal 1 (FR) chega ao alto-falante; o 0 é o fone esquerdo, o 2 e o 3 os atuadores. Medido de ouvido em 16/08/2026.
- `forja_alto_falante.h`: o tom de teste é zero nos outros canais, para que «ouvi ALI» aponte um canal só.
- `forja_dualsense.h`: os modos oficiais do gatilho são Off 0x05, Feedback 0x21, Weapon 0x25, Vibration 0x26. Os restos 0x01, 0x02 e 0x06 não se mandam.
- `forja_dualsense.h`, a sombra: o relatório é atômico e os 47 bytes viajam em toda escrita. O firmware obedece aos bytes dos motores mesmo com os bits de vibração desligados (não há valor neutro para `common[2]` e `common[3]`). Um gatilho com motores zerados calaria a vibração em curso, então quem escreve guarda o último valor de cada campo.
- `forja_dualsense.h`, a sombra: nunca liga `RUMBLE` (é do SDL), `HAPTICS_SELECT` (mata a háptica por áudio), `POWER_SAVE` (o mudo do microfone é do botão e do driver), nem o `valid_flag2` do byte 38 (a lightbar é do `SDL_SetGamepadLED`).
- `forja_dualsense.h`: a base do microfone em `common[7]` é bit0 (microfone interno; zerado, mata a captação), bit2 (cancelamento de eco) e bit3 (de ruído). Medido no Hefesto.
- `forja_dualsense.h`: o volume do alto-falante segue a faixa do driver da Sony, 0x3d..0x64, com o pré-amp na borda do `HP_DETECT`.
- `forja_dualsense.h`: os padrões do LED de jogador são palíndromos.
- `forja_mesa.h`: uma ordem de hidraw só para todo binário, para que «jogador N» seja o mesmo controle no `forja-send`, no `forja-speak` e no `forja-read`.
- `forja_movimento.h`: no corpo do 0x01 (o `buf[1..]`), o giro está em `corpo[15..20]` e o acelerômetro em `corpo[21..26]`, int16 LE, como o `dualsense_input_report` do hid-playstation. Cru, sem calibração: parado, ~1 g num eixo.
- `forja_movimento.h`: o 0x31 tem outros offsets; lido como 0x01, publicaria lixo.

## src/

- `forja_mesa.c`, `forja_usb_do_pad`: subir até o `usb_device` é o mesmo pai de onde o Wine tira o ContainerId (`get_container_id` no winepulse.drv).
- `forja_mesa.c`, `forja_usb_do_pad`: o controle no rádio não sobe, porque chegaria ao adaptador Bluetooth, que também é um `usb_device`.
- `forja_read.c`: um relatório por `read()`. De um 0x31 só chegam os primeiros 64 bytes, e o id basta para recusar.
- `forja_alto_falante.c`, `forja_nos_de_som`: sem o `sysfs.path`, o Wine zera o ContainerId e nada casa.
- `forja_alto_falante.c`, `forja_tom`: rampa de 10 ms nas duas pontas. O nó SUSPENSO come o começo, e o corte seco estala.
- `forja_dualsense.c`: o empacotamento das 10 zonas é o oficial da Sony e do Nielk1.
- `forja_dualsense.c`, `forja_fx_led_mic`: a faixa é 0..3 e o firmware valida; o 4 já apaga.
- `forja_speak.c`: é um binário, e não o motor, porque o `AudioServer` do Godot tem um aparelho só por processo.

## nativo/nucleo

- `forja.c`, `preparar_relatorio`: sem o `SDL_HINT_JOYSTICK_ENHANCED_REPORTS`, o DualSense nativo no rádio entra só com a entrada básica.
- `forja.c`, `forja_abrir`: sem o `SDL_HINT_NO_SIGNAL_HANDLERS`, o SDL troca o Ctrl+C e o SIGTERM por um evento de saída que ninguém lê, e o jogo não fecha pelo terminal.
- `forja.h`, `so_virtuais`: marca a sessão que nasceu com `--simular`. O `forja_simular` do meio da sessão (quem escolheu o teclado) não a liga, e o controle ligado depois ainda entra.
- `forja.c`, `forja_quadro`: os apertos do quadro anterior se zeram antes de bombear, para que cada borda dure exatamente um quadro.
- `pads.c`, `JANELA_ESPELHO_NS`: apertos de dois controles a menos de 60 ms são o mesmo dedo visto por dois caminhos (um espelho).
- `pads.c`: controle simulado nunca é espelho; no modo acelerado, os apertos do robô ficam a milissegundos.
- `pads.c`, `pads_entrar`: um controle estranho nunca herda o lugar de quem caiu; esse lugar só volta pela assinatura.
- `pads.c`, `pad_rumble`: a duração do rumble do simulado corre no tempo do jogo. Um golpe de 260 ms de parede caberia entre dois quadros de um corredor lento, e o SDL não recebe prazo.
- `pads.c`, `conectou`: a sessão com `--simular` não abre o controle de verdade, porque abrir o acende.
- `pads.c`, `abrir_cru`: só o DualSense que se declara USB tem o relatório 0x01 de 64 bytes.
- `linha_tempo.c`: as chaves da cabeça vencem, porque um JSON com chave repetida quebra os leitores estritos.
- `mascara.c`: os octetos 4 e 5 se zeram.
- `mascara.c`, `tenta_corrido`: 12 dígitos hex só são MAC com uma letra a-f; uma data de 12 dígitos não é MAC.
- `mascara.c`: os MAC chegam pelos nomes de nó do BlueZ, pelo iSerial e pelo serial do SDL (relatório 0x09).
- `origem.c`: o BlueZ ≥ 5.73 publica o controle do rádio por uhid, com bus 0005. Ele é físico: a pasta sozinha não prova nada.
- `origem_linux.c`, `caminho_real`: o `realpath` num buffer menor que `PATH_MAX` aborta com `_FORTIFY_SOURCE`.
- `origem_linux.c`: o `HID_UNIQ` nunca se lê.
- `postura.c`: o passo de tempo é o relógio do controle (`sensor_timestamp`), não o do host.
- `postura.c`, `BURACO`: um buraco maior que 50 ms (pausa, reconexão) não vira giro.
- `postura.c`: o sinal do giro se valida contra a gravidade; um eixo invertido por um intermediário aparece aí.
- `medidas.c`, `GIRO_EIXO_MIN`: o ruído do giro parado é ~0,02 rad/s.
- `medidas.h`, `MedMic`: a escala do microfone é 0 = -54 dB, 1 = 0 dB; a voz tem de subir 0,25 (13,5 dB) acima do silêncio.
- `medidas.c`, `med_mic_veredito`: microfone sem nem o nível do ambiente está mudo no sistema; não é defeito do controle.
- `medidas.c`: o touchpad é cerca de duas vezes mais largo que alto.
- `taxa.h`: o SDL declara a taxa do giro por tabela (250 Hz no cabo, 1000 Hz no rádio e no Edge). Medido: cabo 250,0 Hz exatos, rádio em rajadas e nunca 1000; o Edge declara 1000 e entrega 250.
- `texto_buf.c`, `tb_json_num`: o `printf` segue o locale, e o JSON quer ponto.
- `simulador.c`, `anexar`: o callback se arma antes do attach, porque o SDL dá o índice de jogador na chegada.
- `simulador.c`, `simulador_fala`: sala quieta não é silêncio absoluto (`SIM_PISO_DA_SALA`); silêncio absoluto é o mudo do sistema.
- `simulador.c`: os defeitos valem só dentro das salas.
- `simulador.c`, `simulador_atualizar`: duas ações no mesmo botão ou eixo, vale a mais nova.
- `achar_som.c`, `achar_para`: o alto-falante é o canal 1 (FR), os atuadores o 2 e o 3.
- `achar_som.c`, `achar_casar`: o k-ésimo nome repetido casa com o k-ésimo.
- `achar_som.c`, `achar_para`: três passadas, e a do aparelho vem primeiro para todos, para que ninguém leve pelo nome o que é de outro pelo aparelho.

## nativo/godot

- `forja_som.cpp`, `som_preparar`: o alto-falante no cabo só toca com a rota (o canal R no interno), o volume e o pré-amp, o mesmo que o hid-playstation escreve quando o fone sai.
- `forja_medidas.cpp`, `MedidaLugar`: o controle que cai e volta é outro `Pad`, com as contagens do zero; o que o antigo contou fica guardado, e as bases passam ao novo.

## nativo/som

- `som_controle.c`, `abrir_audio`: o som do SDL abre na primeira sala de som, não no começo, porque o CI não tem servidor.
- `som_controle.c`, `somc_falante`: um som por alto-falante de cada vez ([docs/jogo/05](jogo/05-haptica-e-controle.md)).
- `som_controle.c`, `acompanhar_fone`: o plugue do fone troca a rota.
- `som_controle.c`, `somc_trocar`: religa só um lugar sem fechar os outros; as saídas sem uso fecham quando a sala sai.
- `som_controle.c`, `escolher`: o nó que, pelo aparelho, é de um controle fora da mesa não vai a ninguém pelo nome.
- `som_controle_linux.c`: `LC_ALL=C pactl`, porque o pactl traduz e um leitor cego responderia «não há».
- `som_controle_windows.c`: o ContainerId do HID pelo CfgMgr32 e o do endpoint pelo WASAPI, o caminho dos jogos que casam pelo container (ValveSoftware/Proton#5900: Ghostwire, Deathloop).
- `som_controle_windows.c`: sob Proton, os dois vêm do mesmo pai USB (wine!359 e wine!7238), por isso o caminho funciona no cabo.
- `som_controle_windows.c`: com o winepipewire no lugar do winepulse, o container pode não vir (proton-cachyos#296); sobra o caminho pelo nome.
- `som_controle_windows.c`: a ordem dos includes importa, porque o `mmdeviceapi` traz o `PROPERTYKEY` que os outros usam.
- `som_controle_windows.c`, `somc_plataforma_nos`: supõe que a lista do SDL e a do WASAPI andam na mesma ordem.
- `sons_salas.c`: o buffer da síntese é do `malloc` da libc e o mixer libera com `SDL_free`, por isso ele é copiado.
- `mixer.c`, `mixer_tocar`: sem voz livre, rouba a que está mais perto de acabar.

## scripts/compilar.sh, exportar.sh, engine.sh

- `compilar.sh`: o godot-cpp não tem tag 4.7, então vai o `master` fixo num commit (`GODOT_CPP_COMMIT`, [ADR-009](adr/009-a-godot-4-7-e-o-godot-cpp-do-master.md)).
- `compilar.sh`: `-ffile-prefix-map`, para que nenhum caminho da máquina entre no binário.
- `compilar.sh`, `compilar_sdl`: o SDL sai PIC, porque entra num `.so`.
- `compilar.sh`, `SDL_VERSAO`: o 3.4.14 é a série do runtime da Steam.
- `exportar.sh`, `garantir_modelos`: os modelos se acham em `$XDG_DATA_HOME/godot/export_templates`, por isso o cache serve.
- `exportar.sh`: o `.tar.gz` guarda o bit de execução.
- `modelos_de_exportacao.py`: o link do GitHub redireciona a uma URL assinada que expira em minutos, então cada pedido com Range recomeça do link original.
- `engine.sh`: versão nova pede o `FORJA_GODOT_SHA512` junto.

## scripts/ace_step.sh e a trilha

- `ace_step.sh`: o `HF_HOME` fica dentro do projeto, para que o `desinstalar` leve tudo.
- `ace_step.sh`: a RTX 4060 é «tier3» no `gpu_config` do ACE-Step (offload e INT8). Sem o offload, CUDA OOM em 6,84 GiB.
- `ace_step.sh`: o modelo de texto do ACE-Step se desliga pelo `.env` dele, porque ele e o Ollama não cabem juntos; isso solta ~2 GB.
- `ace_step.sh`: `ACESTEP_VAE_ON_CPU=1` cabe, mas é lento: um jingle de 10 s passou de 30 min.
- `gerar_trilha.py`, `gerar`: o servidor limita o lote no tier3, então o script repete com semente nova até ter n.
- `gerar_trilha.py`: sem semente a faixa não se refaz.
- `descrever_trilha.py`: o ACE-Step só entende inglês; «neon» passa como português.
- `mapa_de_batidas.py`: o escorregão é real (tocou a 122,3 pedindo 122: ~150 ms por minuto).
- `trilha_fila.sh`: serviço de usuário por `systemd-run`, para que fechar o terminal não pare a fila.
- `trilha_fila.sh`: `OOMScoreAdjust` alto, para que morra a fila e não a tela.
- `trilha_fila.sh`, `esperar_a_vez`: espera enquanto há jogo aberto (a Steam ou uma janela do Forja de verdade). O Xvfb usa o :99 para cima.
- `trilha_fila.sh`: a faixa interrompida volta à fila.
- `run.sh`, `ao_sair`: a placa se solta ao sair da bancada; soltar a cada ferramenta derrubaria o servidor no meio do uso.

## scripts/ci-local.sh

- É o motor do `ci-local.sh` do Hefesto, copiado em 06/10/2026; cada repositório carrega o seu. Difere a `TABELA` e a imagem (`BASE`, a `catthehacker` pura, sem o Dockerfile do Hefesto).
- `TABELA`: todo job é `ROLA` ou `FORA-DE-CASA` com o motivo medido; o que não bate com o `forja.yml` sai 2.
- Não rodado não é verde: o job que não rodou sai 2, nunca 0.
- Roda a árvore do índice (`git checkout-index`), não a de trabalho.
- `so_a_rede_reprovou`: o filtro de rede só conta a saída do passo. Uma versão que casava uma frase solta deixou passar dois vermelhos de verdade como «rede caída».
- `DOCKER_CAIDO`: o `context deadline exceeded` do docker ao limpar o container não é culpa do job.
- `chamar_act`: o cache de ações se copia por chamada; dividido, dá «Unable to reset … EOF».
- `chamar_act`: uma perna da matriz por chamada, senão o act dá às duas a mesma imagem.
- `tirar_ref`: um checkout com `ref:` faz checkout de verdade (clonou o `master` do actions/checkout); a cópia troca por `lfs: false`.
- Uma porta por job (`--artifact-server-port`).
- `tirar_needs`: o `needs` compartilhado faz nomes de container em conflito.
- O ponteiro `.git` tem de existir no mesmo caminho dentro do container.
- Os marcadores do act se escrevem em bytes, por causa do portão de glifos.
- A costura que chama o `ci-local` está em [a-esteira.md](jogo/o-time/a-esteira.md#o-que-a-esteira-faz-a-cada-volta).

## tests/

- `prova_da_exportacao.sh`: o Wine 9.0 do Ubuntu 24.04 não serve. O `virtual-protect.patch` do Debian faz o `VirtualProtect` do kernelbase ler `*old_prot` sem conferir nulo, o Godot 4.6+ passa nulo no construtor do `OS_Windows`, e o `.exe` morre com 5. O CI usa o GE-Proton ([VALIDAR.md](VALIDAR.md)).
- `prova_do_apt_com_prazo.sh`: o apt ficou 1889 s preso a ~120 kB/s (07/10/2026); o normal é 8–43 s, e o verde mais lento foi 288 s. Sem `timeout-minutes`, o GitHub espera 360 min.
- `caixa.sh`: o `--headless` cala a TV, não o módulo; a prova muda passa pelo `bwrap`.
- `caixa.sh`, `caixa_julgar`: linha de WARNING não reprova a prova.
- `prova_visual.sh`: o X11 é forçado; com a sessão Wayland no ambiente, a janela não vai para a tela.
- `prova_do_som.sh`: o «jogador N» é a ordem do diretório, não a de criação.
- `prova_de_poucos.sh`: roda com `--acelerado`. Os prazos são em quadros e o kit acaba pelo `Ritmo`; no relógio de parede, com `--fixed-fps`, a Centelha não chega aos 90 s em 20000 quadros.
