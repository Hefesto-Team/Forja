# Contribuindo

Obrigado por querer ajudar. Quem joga ajuda de três jeitos, do mais simples ao mais fundo:

1. **Contando como foi.** Um problema, uma sala que não funciona com o seu controle ou uma ideia: abra uma [issue](https://github.com/Hefesto-Team/Forja/issues/new/choose) pelo formulário que combina. Uma dúvida vai para as [Discussões](https://github.com/Hefesto-Team/Forja/discussions/categories/q-a), e quem conta a sua noite de jogo ajuda quem está chegando.
2. **Medindo.** Dizer o sistema, quantos controles e em qual sala o problema aparece já poupa uma ida e volta.
3. **Mexendo no código.** Por enquanto o projeto não revisa pull request de quem ainda não contribuiu: converse antes numa issue ou numa discussão, e combinamos o caminho. Quem passar a contribuir tem o pull request revisado a partir daí.

As issues que cabem a quem está chegando levam o rótulo [good first issue](https://github.com/Hefesto-Team/Forja/labels/good%20first%20issue).

As regras de quem mexe no jogo, os comandos e o que nunca entra estão em [docs/COMO-CONTRIBUIR.md](../docs/COMO-CONTRIBUIR.md): leia o [CONTRATO.md](../CONTRATO.md) antes de qualquer mudança.

## Como o trabalho anda

O `main` aceita só commit **assinado** (o selo «Verified» do GitHub), e quem muda o `main` por pull request precisa de uma revisão e do teste verde. As versões publicadas (as tags `v*`) não se apagam nem se reescrevem.

Para assinar commit com uma chave SSH, depois de pôr a chave pública na sua conta do GitHub como «Signing key», use o script `scripts/github/assinar-commits.sh` do repositório do [Hefesto](https://github.com/Hefesto-Team/hefesto-dualsense4unix): `--conferir` diz o que falta, e `--aplicar` grava a configuração no seu git.

## Antes de abrir o pull request

```bash
bash tests/prova_do_jogo.sh
bash tests/prova_sem_rastro.sh
```

Se a mudança toca uma sala ou o módulo nativo, rode também `scripts/gauntlet.sh` e `bash tests/prova_de_poucos.sh`.

## Dúvidas

Pergunte nas [Discussões](https://github.com/Hefesto-Team/Forja/discussions/categories/q-a).
