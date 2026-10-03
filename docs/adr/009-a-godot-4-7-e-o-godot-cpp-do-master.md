# ADR-009: a Forja roda na Godot 4.7, e o módulo compila contra o master da godot-cpp

**Status:** aceito · **Data:** 2026-10-02 · **Mexe em:** [ADR-007](007-o-jogo-e-o-3d-em-godot.md)

## Contexto

A Forja estava fixada na **Godot 4.4.1**: o `run-local.sh` baixa esse binário
para `tools/`, as provas rodam nele, a exportação usa os modelos dele, e
dezesseis arquivos do repositório escrevem `4.4.1-stable` com todas as letras.

A Godot 4.7.2 saiu em 18/08/2026 e é a que está instalada na máquina. Ficar
três versões menores atrás tem custo: o editor que ela abre não é o que o jogo
roda, a conversão do projeto acontece sem querer (um `project.godot` convertido
para 4.7 travou a cena do metrônomo no binário 4.4.1, em 02/10), e cada correção
de bug da engine demora a chegar.

**A pedra no caminho:** o módulo nativo (`nativo/godot/`) é uma GDExtension
compilada com a **godot-cpp**, e a godot-cpp **não tem versão 4.7**. A última
com tag é a `godot-4.5-stable`; depois dela só existe o ramo `master`.

Medido em 02/10/2026, antes de decidir: o `libforja.linux.x86_64.so`
compilado contra a godot-cpp 4.4 **carrega sem erro** na Godot 4.7.2 (o
`--import` passa por "Verificando GDExtensions" e registra as classes). Ou
seja, a compatibilidade de GDExtension segura — mas segurar não é o mesmo que
ser suportado.

Os caminhos eram três:

1. **Ficar na 4.4.1.** Sem risco e sem ganho; o problema volta a cada versão.
2. **Compilar contra a godot-cpp 4.5** e torcer para a extensão continuar
   válida na 4.7. É a compatibilidade "para a frente" do GDExtension: funciona
   na prática, e não é contrato.
3. **Compilar contra o `master` da godot-cpp**, que é onde a 4.7 vive.

## Decisão

**A Forja roda na Godot 4.7.2, e o módulo compila contra o `master` da
godot-cpp — num commit fixo.**

O repositório tem uma regra antiga, do `scripts/compilar.sh`: *"reproduzível
quer dizer que o SDL3 entra por versão E por sha256, e o godot-cpp por tag E
por commit"*. O `master` é um alvo que anda; a nossa compilação não pode andar
junto. Então:

- `GODOT_CPP_TAG="master"` e `GODOT_CPP_COMMIT` com o commit inteiro;
- o `preparar_godot_cpp` deixa de clonar o topo do ramo e passa a **buscar o
  commit**, direto (`git fetch --depth 1 origin <commit>`), e recusa qualquer
  outro;
- a pasta do cache leva o commit no nome, não a tag: duas sessões com commits
  diferentes não se atropelam.

**Subir de commit é decisão, não acaso.** Um commit só, com o motivo, e as
provas verdes antes do push. É o mesmo rito que o SDL3 já tem.

## Consequências

- **A godot-cpp deixa de ter versão estável por trás.** Um commit do `master`
  pode quebrar a compilação do módulo. Quando quebrar, a saída é voltar o
  commit — ele está fixado, então voltar é uma linha.
- **Quando sair a `godot-4.7-stable` da godot-cpp, voltamos para a tag.** Este
  ADR não casa a Forja com o `master`: casa com a 4.7, e o `master` é o único
  jeito de chegar nela hoje. A volta para tag é um commit e uma nota aqui.
- **O binário da engine passa a ser o 4.7.2** em `tools/`, nas provas, na
  exportação e no `run-local.sh`. O `project.godot` diz `"4.7"`.
- **Os modelos de exportação são os da 4.7.2.** O `.exe` pelo Proton continua
  sendo o que a mesa valida.
- **O estudo em `estudo/godot-4.7` cumpriu o papel** e pode sair: a conversão
  que ele trazia vira esta migração, feita por inteiro em vez de só no
  `project.godot`.
- **A CI muda junto** (`.github/workflows/forja.yml`): é lá que a quebra do
  `master` aparece primeiro, e é por isso que ela não pode ficar para depois.

## O que esta decisão **não** muda

- O [CONTRATO](../../CONTRATO.md) inteiro: o jogo continua falando o relatório
  USB `0x02`, player index 0..3, os quatro modos de gatilho.
- O SDL3, que segue fixado por versão e sha256 (3.4.14).
- O ADR-007: o jogo continua sendo o 3D em Godot com o SDL3 dentro dele. Só a
  versão da engine e a origem da godot-cpp mudam.
