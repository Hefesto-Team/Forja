# F05 — O háptico forte

**Sprint:** F · **Tamanho:** G · **Estimativa:** US$ 3,5

## Por quê

O háptico ficou ultra fraco; primeiro se mede cada uma das sete suspeitas, depois se aplica o piso de força.

## Ler antes

- [Por que o háptico está fraco](../05-haptica-e-controle.md#por-que-o-háptico-está-fraco)
- [O piso de força](../05-haptica-e-controle.md#o-piso-de-força)

## Arquivos que mudam

- `godot/scripts/forja.gd` (`vibrar`, a tabela de eventos nova)
- `godot/scripts/opcoes.gd` (a escala)
- `nativo/nucleo/pads.c` (`pad_rumble`, o firmware na conexão)
- as chamadas de `Forja.vibrar` em `godot/scripts/main.gd` e `godot/scripts/salas/*.gd`
- `experimental/` (um experimento para as suspeitas b, c e d)

## Passos

1. Registrar na conexão a versão do firmware de cada controle.
2. Um experimento da bancada toca o mesmo rumble nos dois modos (suave e seco) e em várias forças, para o André sentir às cegas e anotar.
3. Conferir que nenhum código chama `Input.start_joy_vibration`.
4. Criar a tabela de eventos (`toque`, `acerto`, `perfeito`, `erro`, `golpe`, `explosao`, `aviso`) com o piso de 05, e trocar toda chamada de número por evento.
5. Nunca rumble e háptica por áudio no mesmo instante no mesmo controle.
6. Registrar a escala de vibração de cada lugar no início da sessão.
7. Com a medição do André na mão, levar a decisão do rumble seco (emenda ao CONTRATO ou não) e anotar o resultado em 05.

## Pronto quando

Toda vibração do jogo passa pela tabela de eventos, nenhuma fica abaixo do piso, e o André confirma às cegas que sente cada evento no cabo.

## Provas

- **Na sessão:** `bash tests/prova_do_jogo.sh` e `bash tests/prova_da_bancada.sh`
- **Com o André, local:** `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`; o experimento do háptico com um DualSense no cabo e um no rádio
