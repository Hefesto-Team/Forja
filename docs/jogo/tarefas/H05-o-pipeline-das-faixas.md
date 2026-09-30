# H05 — O pipeline das faixas

**Sprint:** H · **Tamanho:** M · **Modelo:** Sonnet · **Estimativa:** US$ 2,5

## Por quê

As 45 faixas precisam entrar com nome, mapa de batidas e sem pesar o repositório.

## Ler antes

- [As 45 faixas](../04-ritmo-e-audio.md#as-45-faixas)
- [Os arquivos no repositório](../04-ritmo-e-audio.md#os-arquivos-no-repositório)

## Arquivos que mudam

- `godot/scripts/musica.gd`
- `scripts/exportar.sh` (o pacote de música)
- um `scripts/mapa_de_batidas.py` novo

## Passos

1. Decidir e aplicar: pacote de música no release, conferido por sha256, ou Git LFS.
2. `scripts/mapa_de_batidas.py` gera o rascunho do mapa (BPM, primeiro tempo, compassos) para o André conferir.
3. `Musica.tocar(slot)` toca `MUS_Sxx_Jyy.ogg` com o mapa; a faixa sintetizada de hoje fica como reserva quando o arquivo não existe.
4. As faixas das telas e a do Relâmpago nos seus slots.

## Pronto quando

Com três faixas de exemplo no lugar, cada uma toca no seu minigame com o mapa, e sem elas o jogo toca a trilha sintetizada.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh`
- **Com o André, local:** conferir o mapa de batidas das faixas que já estão prontas
