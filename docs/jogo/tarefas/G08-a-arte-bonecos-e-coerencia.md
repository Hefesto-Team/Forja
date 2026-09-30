# G08 — A arte: bonecos e coerência

**Sprint:** G · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 3,5

## Por quê

Dois bonecos não criam apego, e algumas peças destoam do kit; a meta é doze bonecos e tudo no mesmo estilo.

## Ler antes

- [A arte e os personagens](../11-arte-e-personagens.md)

## Arquivos que mudam

- `godot/scripts/player.gd` (`MODELOS`, `NOME_DO_MODELO`, as peças presas a osso)
- `godot/assets/kenney/` e `godot/assets/LEIA-ME.md`
- `LICENCAS-DE-TERCEIROS.md`
- `godot/scripts/salas/voz.gd:107-164` (o guardião)
- `godot/scripts/salas/galeria.gd:141`, `centelha.gd:115`, `molde.gd:420`, as bordas de raia

## Passos

1. O André baixa os pacotes Kenney da mesma família; a sessão confere o esqueleto (sete ossos, mesmos nomes) e as animações de cada boneco antes de registrar.
2. Trocar cabeça e corpo entre modelos, e as peças de identidade (elmo, capa, ombreira, barba) presas a osso.
3. Registrar os bonecos com nome e pio próprio.
4. Refazer o guardião d'A Voz como cabeça de pedra em blocos com olhos emissivos, com a mesma animação.
5. Trocar esferas e toros lisos por peças de 8 lados; o ouro do Molde vira fosco.
6. Anotar a licença de cada asset novo.

## Pronto quando

A construção oferece pelo menos doze silhuetas diferentes, e as fotos de todas as salas passam no checklist de arte de 11.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** `tests/telas.sh` e olhar as fotos lado a lado
