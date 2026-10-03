# O DualSense de Astro Bot: a lógica da Team Asobi e o que dá para fazer no FORJA

Síntese de três relatórios de pesquisa (02/10/2026). As fontes são todas públicas: entrevistas, a ementa da GDC Vault, código aberto (kernel Linux, SDL, GDExtension MIT, gist MIT) e a API pública da Apple. Nenhum material da Sony sob NDA foi usado.

**[F]** marca fato com fonte. **[I]** marca inferência. Na seção 3, as decisões sobre o FORJA foram conferidas linha a linha contra o `CONTRATO.md` atual.

---

## 1. A lógica da Team Asobi em 5 princípios

**1. O háptico é som e entra no primeiro dia.**
- **[F]** Doucet: *"The haptic feedback is sound-based… the sounds that come from the vibration, these are sounds you cannot hear, but they resonate."* https://onemoregame.ph/2024/09/astro-bot-director-nicolas-doucet-interview/
- **[F]** Como o háptico é feito de forma de onda, os designers de áudio entram junto com o gameplay central, não depois que há imagem na tela. https://www.digitaltrends.com/gaming/playstation-5-dualsense-changes-development/
- **[F]** No Astro Bot, quem fazia o háptico era o mesmo engenheiro do controle do personagem, Masayuki Yamada, programador-chefe de gameplay. https://onemoregame.ph/2024/09/astro-bot-director-nicolas-doucet-interview/ e https://gdcvault.com/play/1035347/Feel-the-World-The-DualSense
- **[F]** Um núcleo de 3 a 4 pessoas, o "DualSense 2.0", cuidava só do controle. A fonte é um relato de segunda mão. https://www.gfinityesports.com/article/astro-bot-developer-created-a-team-just-for-dualsense-features

**2. Cada sensação é provada numa demo isolada antes de virar mecânica.**
- **[F]** Fizeram cerca de 80 demos técnicas no Playroom, cada uma de uns 15 dias, cada uma sobre um efeito só (grama, arco, arma). https://geekculture.co/geek-interview-unveiling-the-secrets-of-astros-playroom-playstation-5-with-japan-studios-nicolas-doucet/ e https://www.gamespark.jp/article/2020/10/06/102751.html
- **[F]** A esponja do Astro Bot só entrou no jogo porque a demo já existia: *"If somebody came with a thing on paper without that prototype… Let's not do it."* https://www.techradar.com/gaming/consoles-pc/team-asobi-says-astro-bot-will-push-the-dualsense-controller-to-a-new-level
- **[F]** Há dois caminhos para um poder: do gênero para o controle (Bulldog Booster, luvas de sapo) ou do controle para o gênero (esponja). https://mp1st.com/news/astro-bot-power-ups-were-inspired-by-dualsense-functionality

**3. Poucos materiais, escolhidos para contrastar.**
- **[F]** 「コントラストがとても大事」: plástico, metal, gelo e neve precisam se distinguir. https://www.famitsu.com/news/202010/06206964.html
- **[F]** A meta era perceber a troca de textura **de olhos fechados**, só pelo controle. https://www.gamespark.jp/article/2020/10/06/102751.html
- **[F]** O clima e as superfícies do Playroom foram escolhidos pelo que ficava melhor no háptico. https://www.digitaltrends.com/gaming/playstation-5-dualsense-changes-development/
- **[F]** No Astro Bot, cada objeto físico dispara o seu evento conforme o material: folha, cubo de gelo, ouro, pena. https://www.techradar.com/gaming/astro-bot-nicolas-doucet-interview

**4. Prioridade, picos e reserva de intensidade.**
- **[F]** As camadas competem e o efeito mais importante para o jogo vence (a pisada do inimigo grande). As outras ficam embaixo, em crossfade. https://www.cgmagonline.com/interviews/the-team-behind-the-astros-playroom
- **[F]** A forma de onda permite *"really pinpoint spikes"*, sem a subida e a descida de um motor. Na chuva, cada gota é um pico. https://www.digitaltrends.com/gaming/playstation-5-dualsense-changes-development/
- **[F]** O Returnal (Housemarque) segue o mesmo princípio: o dia a dia fica numa base média e o máximo é guardado para os momentos fortes. https://blog.playstation.com/2021/05/13/how-housemarque-created-returnals-immersive-dualsense-controller-effects/

**5. Ver, ouvir e sentir no mesmo lugar e no mesmo instante, sem atrapalhar o controle básico.**
- **[F]** *"…having the sound and what you feel coming from the same location adds something."* Por isso o alto-falante do controle é tão usado. https://www.digitaltrends.com/gaming/playstation-5-dualsense-changes-development/
- **[F]** O gatilho é para *"more specific moments"*; o háptico está *"just everywhere"*. https://www.cgmagonline.com/interviews/the-team-behind-the-astros-playroom
- **[F]** O touchpad perdeu espaço no Astro Bot porque tira o dedo do pulo. O giroscópio ficou. https://press-start.com.au/features/2024/06/20/we-spoke-to-playstations-team-asobi-about-how-astro-bot-builds-on-astros-playroom

---

## 2. O pipeline técnico e o equivalente aberto no PC

### O que é público sobre a Asobi

- **[F]** A ementa da palestra da GDC 2025 de Yamada fala em "como dados do jogo são extraídos e transformados em feedback", com ferramentas e fluxos próprios. Ela mostra o gameplay ao lado das formas de onda usadas. https://gdcvault.com/play/1035347/Feel-the-World-The-DualSense
- **[F]** O som do alto-falante e a vibração **não usam a mesma onda**. https://www.digitaltrends.com/gaming/playstation-5-dualsense-changes-development/
- **[F]** O jogo teve uma palestra separada sobre física, que está ligada ao háptico por objeto. https://schedule.gdconf.com/session/advanced-physics-in-astro-bot/910487
- **[I]** O padrão provável: parâmetros do jogo (velocidade, material, tipo de impacto) escolhem e modulam amostras ou síntese em tempo real, em vez de tocar clipes fixos.

### Como outros estúdios fazem a autoria

- **[F]** O Spider-Man 2 (Insomniac) autora o háptico como áudio, no Wwise. O nome "Seismix" para o sintetizador veio só do resumo do buscador e não foi conferido. https://gdcvault.com/play/1034485/Audio-Summit-Haptic-Design-and
- **[F]** No Wwise Motion, um Audio Bus vira motion bus, e o DualSense aparece como saída "(Haptics)". https://blog.audiokinetic.com/keeping-it-steady-with-motion-source/ (só pelo resumo da busca)
- **[F]** O FMOD tem o plugin `fmod_haptics`. https://www.fmod.com/docs/2.03/unreal/plugins.html (só pelo resumo da busca)
- **[F]** Na CEDEC 2020, a Sony R&D mostrou uma rede neural que gera vibração a partir do efeito sonoro. https://wccftech.com/ps5s-dualsense-haptics-can-be-created-almost-automatically-via-a-games-sound/amp/

### O transporte: dois caminhos diferentes no cabo USB

**1. Relatório HID `0x02`.** É o caminho que o CONTRATO já cobre.
- **[F]** Carrega os efeitos de gatilho, o LED, o volume do alto-falante e a **vibração compatível**.
- **[F]** A vibração compatível são dois bytes, `motor_left` e `motor_right`, que emulam o motor antigo nos atuadores. https://github.com/torvalds/linux/blob/master/drivers/hid/hid-playstation.c e https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_ps5.c
- **[I]** Dá pancadas grossas, não gotas nem areia.

**2. A placa de áudio USB do controle, com 4 canais (FL, FR, RL, RR).** É o háptico "de verdade", por forma de onda.
- **[F]** RL e RR são os atuadores esquerdo e direito. https://gitlab.com/TYcommand/Gamepads/-/issues/11 , https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2486 e https://github.com/ga2mer/sc2ds
- **[F]** O alto-falante toca o canal FR (o kernel roteia "R channel to SP"). https://raw.githubusercontent.com/torvalds/linux/master/drivers/hid/hid-playstation.c
- **[F]** Existe uma GDExtension aberta para o Godot, a `godot-audio-haptics` (MIT). Ela leva um bus estéreo para RL/RR com miniaudio e acha o aparelho pelo nome "DualSense". Hoje pega só o **primeiro** controle. https://github.com/timoschwarzer/godot-audio-haptics
- **[F]** Formato: 48 kHz em float. Confirmado só por uma biblioteca de terceiros, não pelo descritor USB. https://www.nuget.org/packages/Wujek_Dualsense_API

### A armadilha entre os dois caminhos

- **[F]** Ligar a vibração compatível no `0x02` desliga o háptico por áudio:
  - na SDL, `ucEnableBits1 |= 0x02 // Disable audio haptics`, e no firmware 2.24 ou mais novo, `ucEnableBits3 |= 0x04`;
  - no kernel, `DS_OUTPUT_VALID_FLAG0_HAPTICS_SELECT` quer dizer "classic rumble style".
  - Fontes: os mesmos arquivos da SDL e do kernel citados acima.
- **[F]** Desde 11/2020, o Steam Input deixa passar o háptico por áudio com o rumble ligado. https://www.gamingonlinux.com/2020/11/valve-expand-steam-input-to-support-more-of-the-ps5-dualsense-controller
- **[F]** O háptico por áudio só existe no cabo. O caminho Bluetooth (relatório `0x32`, CRC `0xA2`) é **proibido** pelo AGENTS.md e não serve. https://drqp.readthedocs.io/en/latest/Dev/saxense-feasibility.html

### Frequência e vocabulário de autoria

- **[F]** O pico de sensibilidade tátil (corpúsculos de Pacini) fica perto de 250 Hz, numa faixa de 65 a 400 Hz. https://pmc.ncbi.nlm.nih.gov/articles/PMC6577777
- **[F]** O vocabulário aberto de referência é o AHAP da Apple: *Transient* contra *Continuous*, *Intensity* e *Sharpness*, curvas e camadas. https://developer.apple.com/documentation/corehaptics/representing-haptic-patterns-in-ahap-files.md
- **[I]** Faixas de partida, sem medição pública do atuador. Validar no Modo bancada:
  - "baque": 40 a 60 Hz;
  - "clique": 150 a 250 Hz;
  - acima de uns 500 Hz o atuador passa a soar, então convém um passa-baixa. A atribuição desse limite à Famitsu não foi conferida.

### Sincronia no Godot

- **[F]** O Godot vem com `audio/driver/output_latency` em 15 ms e `mix_rate` em 44100. https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/ProjectSettings.xml
- **[F]** No PipeWire, `PIPEWIRE_LATENCY` limita a latência por stream. https://docs.pipewire.org/page_man_pipewire_1.html
- **[I]** O háptico deve sair do mesmo mixer e do mesmo relógio do áudio do jogo, disparado no mesmo quadro do evento visual. O `0x02` do gatilho também é reenviado nesse quadro.

---

## 3. Momento do Astro Bot → recurso → como fazer no FORJA

Pontos do CONTRATO que pesam nesta tabela:
- os modos de gatilho são só `OFF`, `FEEDBACK`, `WEAPON` e `VIBRATION`, com "Arco usa `FEEDBACK`";
- `SlopeFeedback` é proibido pelo nome;
- a vibração L/R e o som no alto-falante pelo endpoint de áudio do pad são permitidos;
- **o PCM nos canais traseiros dos atuadores não aparece no CONTRATO.**

Toda a coluna "No FORJA" é **[I]**.

| Momento (fonte) | Recurso do controle | No FORJA |
|---|---|---|
| Mola do sapo, pulo carregado ([Wikipedia](https://en.wikipedia.org/wiki/Astro%27s_Playroom), [Shacknews](https://www.shacknews.com/article/121150/astros-playroom-cooling-springs-hands-on-impressions-making-sense-of-the-dualsense)) | Gatilho com resistência crescente e giroscópio | **Dentro.** `FEEDBACK` com a força subindo por reenvio a cada quadro (não `SlopeFeedback`). Ao soltar, `OFF` e o salto. O giro é entrada e já está no CONTRATO. |
| Esponja: pesada, depois leve ([TechRadar](https://www.techradar.com/gaming/consoles-pc/team-asobi-says-astro-bot-will-push-the-dualsense-controller-to-a-new-level)) | Gatilho com força caindo no tempo | **Dentro.** `FEEDBACK` 8→7→…→1→`OFF`, reenviado quando a água sai. |
| Agarrar bloco e escalar com o macaco ([Famitsu](https://www.famitsu.com/news/202010/06206964.html), [PS Blog](https://blog.playstation.com/?p=343436)) | Resistência e uma agarra que cede | **Dentro.** `FEEDBACK` leve. O jogo lê a posição analógica do gatilho e, passado o limite, manda `OFF` e solta. |
| Arco e corda ([CGM](https://www.cgmagonline.com/interviews/the-team-behind-the-astros-playroom)) | Tensão no gatilho | **Dentro, com `FEEDBACK`**, porque o CONTRATO diz "Arco usa `FEEDBACK`". Um relatório sugeriu `WEAPON` (parede e clique); isso muda o CONTRATO e fica para a ficha decidir. |
| Socos das luvas de sapo ([Gfinity](https://www.gfinityesports.com/article/astro-bot-every-ability-ranked-by-dualsense-haptics)) | Tensão elástica e estalo | **Dentro.** `FEEDBACK` leve para a tensão, ou `WEAPON` com o fim baixo para o estalo. |
| Jetpack ou foguete, um propulsor por gatilho ([CGM](https://www.cgmagonline.com/news/astros-playroom-dualsense/)) | Gatilho proporcional e chacoalho | **Em parte.** O jato vem da leitura analógica, e o ronco de `VIBRATION` com a amplitude ajustada pelo jogo. É um modo por vez: não dá resistência e ronco juntos. |
| Bulldog Booster, o chacoalho contra o dedo ([PS Blog](https://blog.playstation.com/2024/05/30/astro-bot-arrives-on-ps5-september-6/)) | Gatilho vibrando | **Dentro, aproximado.** `VIBRATION` de 20 a 40 Hz, amplitude de 4 a 8, reenviado no quadro da animação. A forma da onda é a do firmware. |
| O latido do Bulldog pelo controle ([ASCII](https://ascii.jp/elem/000/004/205/4205211/3/)) | Alto-falante | **Dentro.** Endpoint de áudio do pad pelo `ContainerId` ou pelo nome (`forja-speak`). |
| Galope ou máquina (modos de firmware) | Gatilho | **Só aproximado.** O jogo alterna `VIBRATION` e `FEEDBACK` no tempo. `Galloping` e `Machine` são proibidos. |
| Pisadas e impactos grossos | Vibração | **Dentro, grosso.** A vibração L/R compatível com pulsos de poucos quadros e contraste de intensidade, sem riqueza de frequência. |
| Chuva gota a gota no guarda-chuva ([Digital Trends](https://www.digitaltrends.com/gaming/playstation-5-dualsense-changes-development/)) | Atuadores por forma de onda | **Fora das regras hoje.** Exige PCM nos canais RL/RR da placa USB, e o CONTRATO não tem essa linha. |
| Texturas do chão (areia, gelo, metal) ([Game*Spark](https://www.gamespark.jp/article/2020/10/06/102751.html)) | Atuadores por forma de onda | **Fora das regras hoje.** Mesmo motivo. Com a vibração compatível sai só um "zumbido diferente" por material. |
| Parede com passagem secreta ([Game Developer](https://www.gamedeveloper.com/design/astro-bot-s-next-solo-title-takes-him-from-tech-demo-mascot-to-lead-material)) | Textura fina na mão | **Fora das regras hoje.** Mesmo motivo. |
| Folhas, gelo, ouro e penas por objeto ([TechRadar](https://www.techradar.com/gaming/astro-bot-nicolas-doucet-interview)) | Física e háptico por material | **A lógica cabe**: tabela de material para assinatura, disparada pelo evento de colisão. **A riqueza fica fora** enquanto só houver vibração compatível. |
| Tempestade de areia, vento ([Famitsu](https://www.famitsu.com/news/202010/06206964.html)) | Atuadores e alto-falante | **Metade dentro.** O vento sai pelo alto-falante. O tato fino fica fora. |
| Soprar o cata-vento ([Shacknews](https://www.shacknews.com/article/121150/astros-playroom-cooling-springs-hands-on-impressions-making-sense-of-the-dualsense)) | Microfone | **Dentro, mas difícil com 4 jogadores.** O CONTRATO só dá "o microfone padrão do sistema", então é um microfone para a sala, não um por jogador. |
| Inclinar e os robôs rolam ([PS Blog](https://blog.playstation.com/2024/06/12/astro-bot-hands-on-report/)) | Giroscópio | **Dentro.** É entrada. |
| Fechar o zíper do traje ([Can I Play That](https://caniplaythat.com/?p=10735)) | Touchpad | **Dentro.** Usar pouco: a Asobi recuou no touchpad. |

**[I] Conflito a decidir antes de abrir o háptico por áudio.** Se o FORJA ligar a vibração L/R compatível no `0x02`, os bits `COMPATIBLE_VIBRATION`/`HAPTICS_SELECT` desligam o háptico por áudio. As duas coisas não podem conviver no mesmo controle.

---

## 4. As 5 primeiras coisas a fazer no FORJA, em ordem

1. Uma ficha de bancada, "gatilho dinâmico": `FEEDBACK` em rampa por reenvio, `FEEDBACK` caindo (esponja) e `OFF` por limiar de leitura analógica. Cada um isolado no Modo bancada, com o resultado no registro.
2. Um barramento de vibração por player index 0..3, com prioridade, crossfade e reserva de intensidade (base média, pico guardado). Tudo sobre a vibração L/R que o CONTRATO já permite.
3. Uma tabela de material para assinatura (ataque, duração, intensidade e lado L/R), com poucos materiais de contraste alto, disparada por evento de colisão no mesmo quadro do som e da animação.
4. O som do evento no alto-falante do pad certo (endpoint pelo `ContainerId`), sincronizado com o gatilho. É a regra do "ver, ouvir e sentir no mesmo lugar".
5. Uma ficha de decisão de produto: o CONTRATO ganha ou não uma linha para o PCM nos canais traseiros da placa de áudio do pad? Se ganhar, ela precisa cobrir quatro coisas:
   - casar placa e controle por aparelho, nunca por MAC, porque a `godot-audio-haptics` só pega o primeiro;
   - proibir a vibração compatível nesse modo;
   - definir o que acontece sem cabo: o háptico não toca e a falha vai para o registro;
   - definir o ajuste global de força (Forte, Médio, Fraco, Desligado, como no PS5).

---

## 5. Lacunas: o que não se achou em fonte pública

- O conteúdo da palestra de Yamada (GDC 2025): as ferramentas, as formas de onda e o fluxo de dados. O vídeo está na GDC Vault, que é paga, e só a ementa foi lida. O mesmo vale para a palestra do Spider-Man 2 (GDC 2024).
- O nome da ferramenta interna da Asobi, o middleware dela (Wwise, FMOD ou outro) e o formato dos arquivos de háptico.
- A resposta em frequência medida do atuador do DualSense. As faixas de Hz da seção 2 são inferência pela fisiologia.
- Os 48 kHz e a ordem dos canais do áudio USB: só confirmados por código de terceiros, não pelo descritor lido de um controle. Para conferir no cabo: `cat /proc/asound/cardN/stream0`.
- A frase "cerca de 12 superfícies-chave", atribuída à Newshub/Stuff: não verificada.
- O nome "Seismix", o limite de ~500 Hz atribuído à Famitsu e várias páginas que deram 403, 504 ou não resolveram (Digital Trends em parte, Gamespot, VGC, TechRadar review, Actronika, Audiokinetic). O que vem delas saiu do resumo do buscador, sem conferência direta.
- O relato do núcleo "DualSense 2.0" é de segunda mão (Gfinity sobre um vídeo de Julien Chièze). O vídeo original não foi visto.

---

# Adendo — o que a própria Sony publicou (02/10/2026)

Uma segunda varredura, só em fonte **da Sony e de publicação acadêmica**,
corrige três pontos do relatório acima. Nada do SDK: ele é sob NDA, e não foi
procurado nem lido.

## 1. O método "som vira háptico" é publicado pela Sony, não é só prática de estúdio

Na brochura **Sony's Technology 2020** (Sony Corporation, Corporate
Communications, julho/2020, "Haptics — Taking on New Challenges with
Haptics", pp. 26–27), Yukari Konishi, do Global R&D Tokyo Division da Sony
Interactive Entertainment, descreve a ferramenta interna:

> *"we have created a **haptic vibration waveform design environment** that
> anyone can use easily"* … *"we have not only developed a tool that allows
> game creators to design an impactful, natural and comfortable vibration
> waveform in fewer steps, but also created a method of **almost automatically
> generating vibration patterns from a game's sound effects**."*

O PDF original responde 403; cópia legível:
<http://web.archive.org/web/20201125202546/https://www.sony.net/SonyInfo/technology/activities/Tech2020/pdf/Sonys_Technology_2020_E.pdf>

A página **Sony's Haptics Technology** do R&D Center (hoje 404; cópia em
<http://web.archive.org/web/20250918021425/https://www.sony.co.jp/en/technology/haptics/>)
diz o porquê: *"**Focusing on the fact that sound and vibration are similar in
nature**, the R&D Center advanced its research through the use of Sony's audio
technology."*

**Para o Forja:** a ferramenta de autoria é parte do método, não acessório. O
`nativo/som/sintese.c` é o nosso análogo; o que falta ao lado dele é a
**pré-escuta**, para a onda ser desenhada e sentida antes de entrar no jogo.

## 2. Como o atuador funciona, por quem o projetou — em publicação de terceiro

**IPSJ 情報処理 Vol.62 No.7 (2021)**, artigo de Zenji Nishikawa (jornalista)
entrevistando **Takeshi Igarashi**, chefe do departamento de projeto de
periféricos da SIE. Acesso aberto:
<https://ipsj.ixsq.nii.ac.jp/record/211668/files/IPSJ-O-MGN620705.pdf>

- **Motor linear de vibração ântero-posterior** — "na prática, uma bobina de
  voz" —, não o motor rotativo do DS3/DS4. Banda muito mais larga, do grave ao
  agudo, **num elemento só**.
- **O teto de frequência é um filtro em software**, não limite do aparelho:
  acima dele a vibração *passa a ser ouvida como som*. O limite "é tecnicamente
  possível remover".
- **Uma única frequência de ressonância** — o valor é 非公開 (não divulgado).
- O dado mais simples de mandar é *"uma forma de onda como dados de áudio PCM"*.
- Dois elementos iguais, um por punho, para **vibração em estéreo**; o curso é
  simétrico, **mas o acionamento assimétrico é possível**.
- **O gatilho**: um parafuso sem-fim no eixo do motor move um braço com
  engrenagem helicoidal que encosta no gatilho. A força **máxima** é a tensão
  do motor pela redução; a **mínima** é a mola mais a **carga mecânica do
  engrenamento** — ou seja, o piso de resistência é físico, não escolha de
  software.

Bate com as patentes públicas ([US 11.806.614 B2](https://patents.google.com/patent/US11806614B2/en),
[JP 7.778.862 B2](https://patents.google.com/patent/JP7778862B2/en)).

## 3. A Sony recusa publicar os números — e isso é uma regra para o repositório

O mesmo artigo registra **quatro** recusas: latência e resposta, frequência de
ressonância, a curva de resposta em frequência DS4 × DualSense, e a curva de
força do gatilho — todas 非公開.

**Portanto: toda faixa numérica do DualSense em documento do Forja não vem de
fonte aberta da Sony.** Vem de medição nossa, de teardown ou de engenharia
reversa, e tem de estar rotulada assim — inclusive os 60 a 180 Hz da tabela de
materiais do [05](../jogo/05-haptica-e-controle.md).

Os números que a Sony **publicou** são de outros aparelhos, e servem de
fundamento citável:

| grandeza | valor | fonte |
| --- | --- | --- |
| atuador bobina+massa+mola | 35,0 × 5,0 × 7,5 mm, 5,2 g | Traxion, Jun Rekimoto (Sony CSL), UIST '13, [10.1145/2501988.2502044](https://doi.org/10.1145/2501988.2502044) |
| extinção da vibração | menos de 50 ms | idem |
| ciclo assimétrico (força virtual) | 2 ms ligado / 8 ms desligado | idem |
| ciclo simétrico (vibração normal) | 5 ms / 5 ms | idem |
| rigidez reproduzida | 0,544 a 5,304 N/mm | Yoshida et al., R&D Center Sony, IEEE World Haptics 2021, [10.1109/whc49131.2021.9517139](https://doi.org/10.1109/whc49131.2021.9517139) |

O Traxion é a ponte certa para qualquer efeito direcional do Forja: é paper da
Sony, aberto, com milissegundos concretos, e a IPSJ confirma que o DualSense
aceita acionamento assimétrico no mesmo eixo.

## 4. O vocabulário da Sony, para as telas e os documentos

*wide-frequency* (広帯域) · *wide dynamic range* · *vibration waveform* (振動波形) ·
*vibration pattern* · *haptic super-resolution* (触覚超解像) · "controle
independente de amplitude e frequência" · 振動覚・圧覚・力覚・温冷覚 (vibratória,
pressão, força, térmica) · **抵抗力覚** — *sensação de força resistiva*, que é o
termo técnico do que o gatilho faz · *trigger effect*.

## 5. O que continua sem fonte

A SIE publica háptico em SIGGRAPH Emerging Technologies, UIST e CHI, mas
**nunca sobre o DualSense**: ele só existe em entrevista e em palestra de
estúdio. Não há paper da Sony sobre *áudio para háptico* — o método com rede
neural existe só como depoimento na brochura. A biblioteca da AES estava fora
do ar (503) e não pôde ser varrida.
