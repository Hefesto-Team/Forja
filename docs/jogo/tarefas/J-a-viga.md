# J — S2 — A Viga: os cinco minigames

**Sprint:** I–Q · **Tamanho:** G · **Modelo:** Opus + Sonnet · **Estimativa:** US$ 4,5

## Por quê

A seção de giroscópio e acelerômetro: a sala de hoje reescrita no kit, sem quiz nem veredito, e quatro minigames novos com verbos diferentes.

## Ler antes

- [As fichas dos minigames 6-10](../03-os-45-minigames.md#s2--a-viga--giroscópio-e-acelerômetro)
- [O molde de minigame](molde-de-minigame.md)
- [A régua](../10-a-regua-astro-bot.md#a-pergunta-de-aprovação)

## Arquivos que mudam

- `godot/scripts/salas/viga.gd` (a sala de hoje, reescrita no kit)
- `godot/minigames/S02_*.tres` (as cinco fichas de dados)
- um arquivo por minigame novo em `godot/scripts/minigames/s02/`
- `godot/scripts/partida.gd` (o sorteio)
- `godot/scripts/traducoes.gd`

## Passos

1. **Sessão 1 (Opus):** reescrever a sala de hoje no kit como o primeiro minigame da seção, e fazer o segundo.
2. **Sessão 2 (Sonnet):** o terceiro, o quarto e o quinto, pelo molde.
3. Cada minigame: o verbo, o repertório inteiro (vibração, barra de luz, alto-falante, gatilho), a falha física, o fim com vencedor, a faixa do slot (ou a sintetizada) e o que o registro mede.
4. Cada minigame tem o robô, para jogar com `--robo`.
5. As três perguntas da régua Astro Bot, respondidas na própria ficha de dados.
6. O sorteio da partida passa a incluir os cinco.

## Pronto quando

Os cinco jogam do aviso ao resultado com quatro, três, dois e um jogador e com o robô; a partida sorteada os inclui; e o André aprovou os cinco jogando.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`; jogar os cinco com gente
