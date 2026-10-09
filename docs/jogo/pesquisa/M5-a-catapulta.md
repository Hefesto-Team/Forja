# M5 — A Catapulta: a pesquisa do DualSense

Ficha: [M5](../tarefas/M5-a-catapulta.md). Seção: [M — A Galeria](../tarefas/M-a-galeria.md).
Catálogo: [dualsense.md](dualsense.md). Data: 08/10/2026.

## O recurso

- **Duas mãos, dois papéis.** O **puxador** tem o R2 em `Feedback`, a corda subindo a cada meia batida. O
  **travador** tem o R2 em `Weapon`, o estalo no contratempo.
- **Troca de papel a cada 8 compassos.**
- Pontos e dano por nota (`DANO` 0 a 3); a pedra no próprio muro vale 4 (`PROPRIO_MURO`). Sozinho, o contrapeso trava
  sozinho e vale ÓTIMO.
- Sala da prova: `S05_J25`.

## O que se sabe fora

| jogo ou projeto | o que faz | fonte |
| --- | --- | --- |
| Astro's Playroom (2020) | a mola guarda a força e solta; a pegada do macaco solta com força demais | Wikipedia, `Astro's_Playroom`; catálogo |
| Kena: Bridge of Spirits (2021) | o arco aperta até o fundo | GamingBolt; PlayStation LifeStyle |
| Deathloop (2021) | a arma trava e destrava no gatilho | KitGuru |
| Returnal (2021) | dois estágios no mesmo gatilho: meio curso e curso inteiro | Android Central; GamingTrend |
| Keep Talking and Nobody Explodes (Steel Crate, 2015) | dois papéis com informação diferente que só funcionam juntos | GDC Vault 1023113, «Designing Asymmetric Gameplay» |

## O risco no Linux

1. **A troca de papel muda o modo do gatilho** (0x21 ↔ 0x25) nos dois controles ao mesmo tempo; no cabo, um relatório
   por controle, a 4 ms. Sem risco medido.
2. **A corda a cada meia batida** são até 16 relatórios por compasso a 155 bpm (meia batida = 0,19 s). Folgado no
   cabo.
3. **O Steam Input** e o **Edge**, como no resto da seção.
4. **A força** só se prova no registro até os 11 bytes do gatilho saírem na `percepcao`.

## As propostas

### 1. A trava se sente no puxador (para a dupla)

- **O puxador:** quando o travador estala no contratempo, o puxador sente `toque` 30 ms (`fraco` 0,3). A pedra está
  presa; ele pode soltar. Cada um sente o outro sem olhar.
- **O travador:** quando a corda chega ao alto, ele sente o mesmo `toque` no `forte`. Dois sinais, um em cada motor.
- **Como se prova sem o controle:** `--simular=4 --robo=bom --semente=7 --sala=S05_J25`. O registro tem a
  `sensacao` no parceiro a menos de 20 ms do `toque` do outro. **A que morde:** `--defeitos=vibra-vizinho` manda o
  aviso a quem não é da dupla.

### 2. O respiro antes da troca (para quem troca)

- **Os dois:** na última batida antes da troca, os dois R2 vão a **Off** por 1 batida; depois o modo novo entra. O
  vazio no dedo avisa "agora você é o outro". A troca vira um gesto, não um susto.
- **Como se prova:** a sequência de `percepcao(l)["gatilho_dir"]` em cada lugar da dupla é 0x21 → 0x05 → 0x25 (ou o
  contrário), com o 0x05 durando uma batida, a cada 8 compassos. Com `--defeitos=gatilho-mudo`, a sequência some.

### 3. A pedra pesa o que se puxou (para o puxador)

- **O puxador:** a força final da corda é o dano somado na puxada: força = 2 + 2 × dano, até 8. Quem puxou no tempo
  sente a pedra pesada; quem errou sente frouxo.
- **Os outros:** veem o tamanho da pedra (arte).
- **Como se prova:** **só com os 11 bytes do gatilho.** Até lá, o registro grava a força mandada e o dano, e a prova
  confere `força = min(8, 2 + 2 × dano)`.

## O que preciso de outras cabeças

- **Arquiteto:** os 11 bytes do gatilho na `percepcao` (proposta 3).
- **Diretor de jogo:** o respiro de 1 batida (proposta 2) tira uma nota a cada 8 compassos; é dele.
