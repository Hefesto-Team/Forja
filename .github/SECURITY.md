# Política de segurança

Achou uma falha de segurança no Forja? Conte para nós em particular, para a correção sair antes de a falha ser conhecida por todo mundo.

## Como relatar

**Não abra uma issue pública** para uma vulnerabilidade. Há dois caminhos, e o primeiro é o melhor:

1. **Pelo próprio GitHub**, em privado: na página do repositório, aba **Security**, botão **Report a vulnerability** (Relatar uma vulnerabilidade). Só quem mantém o projeto vê o relato, e a conversa e a correção acontecem ali.
2. **Por e-mail**, se você não tem conta no GitHub: `andre.dsbf@gmail.com`, com o assunto `[Forja SEC] resumo curto`.

Ajuda muito o relato trazer o que acontece e o que alguém conseguiria fazer com isso, os passos para reproduzir, a versão do jogo (o nome do pacote que você baixou), o sistema (Linux ou Windows) e uma prova mínima do problema.

## O que acontece depois

1. Respondemos confirmando o recebimento em até 7 dias.
2. Em até 14 dias dizemos se o problema se confirmou e qual a gravidade.
3. A correção é feita em particular e sai numa versão nova, com o seu nome no aviso se você quiser.
4. Só então o aviso fica público, pela aba Security do repositório.

Não há programa de recompensa em dinheiro: o Forja é feito por pessoas, sem financiamento.

## Versões que recebem correção

Só a versão mais recente dos pacotes publicados na página de releases.

## O que conta como falha de segurança

- O jogo ou o módulo nativo executar código de fora, ou abrir arquivo fora da pasta do jogo, a partir de um dado que um jogador ou um arquivo de perfil controla.
- As regras do udev que vêm no pacote (`udev/70-forja-dualsense.rules`) darem acesso a mais do que o controle.
- Um pacote publicado que não bate com o código do repositório.

## O que não conta

- Falhas do Godot, do SDL, do Wine, do Proton, do kernel Linux ou de outras dependências: relate a quem mantém cada uma.
- Ataque que precisa de acesso físico ao computador além do controle, ou de outro programa já rodando como você.
- A privacidade do protocolo do controle, que é da Sony.

## Chave PGP

Não há. Se o relato precisar de canal cifrado, peça pelo primeiro contato e combinamos o jeito sem mandar o conteúdo antes.
