# G07 — A narrativa leve

**Sprint:** G · **Tamanho:** P · **Modelo:** Sonnet · **Estimativa:** US$ 1,5

## Por quê

O ritmo precisa de um porquê no mundo, sem texto longo: falas curtas e o vocabulário do visor.

## Ler antes

- [A narrativa e a voz](../07-narrativa-e-voz.md)

## Arquivos que mudam

- `godot/scripts/salas/sala_jogo.gd` (os gatilhos das falas)
- `godot/scripts/ui/painel_sala.gd` (o julgamento acima do boneco)
- `godot/scripts/traducoes.gd`

## Passos

1. As falas da tabela de 07, com o limite de uma a cada 20 s por jogador.
2. O julgamento no visor: "Ressonância!", "Afinado", "Quase"; o erro sem palavra.
3. Tudo pela tabela de traduções, com maiúscula.

## Pronto quando

Numa partida de cinco, as falas aparecem, nunca duas ao mesmo tempo, e o julgamento usa só o vocabulário do visor.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** jogar uma partida de cinco
