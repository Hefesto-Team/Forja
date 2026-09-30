# G08 — A arte: bonecos e coerência

**Sprint:** G · **Tamanho:** G · **Modelo:** Sonnet · **Estimativa:** US$ 3,5 · **Depende de:** F00, G01, G02 · **Parte B depende de:** os pacotes Kenney que o André baixa e commita

## Por quê

Dois bonecos não criam apego, e algumas peças destoam do kit (o guardião
d'A Voz, os toros lisos, o ouro que reflete). A meta: pelo menos doze
silhuetas na construção, e tudo no mesmo estilo fosco e em blocos — com uma
conferência automática para o que se confere sem olho.

## Ler antes

- [As regras de coerência](../11-arte-e-personagens.md#as-regras-de-coerência) e [o checklist](../11-arte-e-personagens.md#o-checklist-de-aprovação)
- [O que destoa hoje](../11-arte-e-personagens.md#o-que-destoa-hoje)
- [Os personagens](../11-arte-e-personagens.md#os-personagens) (as fontes a, b e c)

## O estado de hoje

- `godot/scripts/player.gd`: `MODELOS := ["character-human", "character-orc"]`,
  `NOME_DO_MODELO := ["Humano", "Orc"]`, `PIO_DO_MODELO` (G01) alinhado com
  `MODELOS`; `modelo_i` indexa `MODELOS`; `visual()` carrega
  `"res://assets/kenney/%s.glb" % MODELOS[modelo_i]`; as peças da G02
  (`PECAS := ["Nenhuma", "Elmo", "Capa", "Ombreira"]`) presas em
  `BoneAttachment3D` chamados `"Peca"`. `Som.pio(l, boneco)` (G01) lê
  `ForjaPlayer.PIO_DO_MODELO`.
- Os dois `.glb` (medido com o JSON do glTF): sete ossos `root`,
  `leg-left`, `leg-right`, `torso`, `arm-left`, `arm-right`, `head`
  (`root` → pernas e `torso`; `torso` → braços e `head`); 32 animações;
  malhas `body-mesh` e `head-mesh`; 465 e 374 triângulos; altura 0,755 com a
  origem nos pés; um material `colormap` com `metallicFactor` 0; a textura
  por `uri` `Textures/colormap.png`, **relativa ao `.glb`**.
- `godot/assets/kenney/` tem o Mini Dungeon inteiro na raiz (e o
  `Textures/colormap.png` dele). Um pacote Kenney novo traz o **seu**
  `Textures/colormap.png`: se cair na mesma pasta, sobrescreve o nosso.
- `godot/scripts/salas/voz.gd:107-164`, `_montar_guardiao()`: rosto
  `Kit.esfera` escalado `(1.55, 1.95, 0.55)` em bronze `metallic = 0.6`,
  olhos esféricos emissivos; devolve
  `{"pivo", "mat_olho", "palpebras", "boca", "dentes", "brilho", "fundo"}`.
  A animação (`voz.gd:495-506`) usa `mat_olho.emission_energy_multiplier`,
  `palpebras` (`scale.y` e `position.y = 0.28 + 0.2 * olhos`),
  `boca.scale.y = 0.12 + 0.75 * grito`, `brilho.light_energy` e
  `pivo.position`.
- `godot/scripts/mundo/kit.gd`: `cilindro` com `radial_segments = 20`
  (78), `esfera` com 20 × 10 (92-93).
- Toros lisos (`TorusMesh`, `rings` 32 a 48): `player.gd:75` (o aro),
  `caminhos.gd:147`, `canto.gd:138, 187, 224`, `centelha.gd:127`,
  `galeria.gd:122`, `impacto.gd:114`, `molde.gd:165`, `viga.gd:219`,
  `voz.gd:172`, `mundo/efeitos.gd:86`. Esferas lisas: `centelha.gd:139`
  (`SphereMesh`), `salao.gd:223` (a chama da tocha). CSG redondos:
  `salao.gd:261-264` (tablado, 32 lados), `268-272` (borda, 48), `297-301`
  (chifre, 16), `368-371` e `378-382` (pedestal e aro, 32 e 40),
  `kit.gd:158-162` (chifre, 16).
- `metallic` acima de 0,2: `caminhos.gd:116` (0,8), `canto.gd:128` (0,75),
  `molde.gd:423` (0,7, o ouro), `prova.gd:124` (0,8), `viga.gd:70` (0,8),
  `voz.gd:115` (0,6).
- `LICENCAS-DE-TERCEIROS.md:14` e `godot/assets/LEIA-ME.md` citam só o Mini
  Dungeon e os sons.

## O alvo

### Parte A — sem pacote novo (a sessão faz tudo)

**1. O conferidor de bonecos** (`scripts/conferir_bonecos.py`, novo; Python
3 sem dependência):

```python
#!/usr/bin/env python3
"""Confere um boneco .glb antes de ele entrar no Forja (docs/jogo/11, "os personagens").

    python3 scripts/conferir_bonecos.py                 os character-*.glb de godot/assets/kenney
    python3 scripts/conferir_bonecos.py <arquivo|pasta>...
    python3 scripts/conferir_bonecos.py --teste         a prova da mordida

Uma linha por arquivo: PASSOU ou FALHOU e o porquê. Sai com 1 se algum falhou.
"""
import json
import pathlib
import struct
import sys

OSSOS = ["root", "leg-left", "leg-right", "torso", "arm-left", "arm-right", "head"]
PAI = {"leg-left": "root", "leg-right": "root", "torso": "root",
       "arm-left": "torso", "arm-right": "torso", "head": "torso"}
ANIMACOES = ["idle", "walk", "sprint", "jump", "fall", "die", "emote-yes", "emote-no",
             "attack-melee-right", "holding-right", "static", "interact-right"]
TRIANGULOS = 1500
ALTURA = 0.755  # a do boneco do kit, em unidades do modelo
RAIZ = pathlib.Path(__file__).resolve().parent.parent


def ler(caminho):
    b = pathlib.Path(caminho).read_bytes()
    if b[:4] != b"glTF":
        raise ValueError("não é glTF binário")
    n = struct.unpack("<I", b[12:16])[0]
    return json.loads(b[20:20 + n])


def conferir(j, pasta):
    falhas = []
    nos = j.get("nodes", [])
    nome = lambda i: nos[i].get("name", "")
    if not j.get("skins"):
        falhas.append("sem esqueleto")
    for s in j.get("skins", []):
        juntas = [nome(i) for i in s["joints"]]
        if sorted(juntas) != sorted(OSSOS):
            falhas.append(f"ossos {juntas}")
    pai = {}
    for n in nos:
        for c in n.get("children", []):
            pai[nome(c)] = n.get("name", "")
    for osso, p in PAI.items():
        if pai.get(osso) != p:
            falhas.append(f"{osso} pendurado em {pai.get(osso)!r}, não em {p!r}")
    anims = {a.get("name", "") for a in j.get("animations", [])}
    faltam = [a for a in ANIMACOES if a not in anims]
    if faltam:
        falhas.append(f"faltam as animações {faltam}")
    malhas = [n.get("name", "") for n in nos if "mesh" in n]
    if not any(m.startswith("body") for m in malhas):
        falhas.append(f"nenhuma malha body* {malhas}")
    if not any(m.startswith("head") for m in malhas):
        falhas.append(f"nenhuma malha head* separada {malhas}")
    tri, alto, baixo = 0, -1e9, 1e9
    for m in j.get("meshes", []):
        for p in m["primitives"]:
            pos = j["accessors"][p["attributes"]["POSITION"]]
            alto, baixo = max(alto, pos["max"][1]), min(baixo, pos["min"][1])
            conta = j["accessors"][p["indices"]]["count"] if "indices" in p else pos["count"]
            tri += conta // 3
    if tri > TRIANGULOS:
        falhas.append(f"{tri} triângulos (máximo {TRIANGULOS})")
    if abs(alto - ALTURA) > ALTURA * 0.15:
        falhas.append(f"altura {alto:.3f} (a do kit é {ALTURA})")
    if abs(baixo) > 0.03:
        falhas.append(f"a origem não está nos pés (o mais baixo em {baixo:.3f})")
    for mat in j.get("materials", []):
        metal = mat.get("pbrMetallicRoughness", {}).get("metallicFactor", 1.0)
        if metal > 0.2:
            falhas.append(f"material {mat.get('name')!r} com metallic {metal} (máximo 0,2)")
    for img in j.get("images", []):
        if "uri" in img and not (pasta / img["uri"]).exists():
            falhas.append(f"a textura {img['uri']} não está ao lado do .glb")
    return falhas, tri, len(anims)


def arquivos(args):
    alvos = [pathlib.Path(a) for a in args] or [RAIZ / "godot/assets/kenney"]
    for a in alvos:
        yield from (sorted(a.rglob("character-*.glb")) if a.is_dir() else [a])


def teste():
    j = ler(RAIZ / "godot/assets/kenney/character-human.glb")
    pasta = RAIZ / "godot/assets/kenney"
    bom, _, _ = conferir(j, pasta)
    for n in j["nodes"]:
        if n.get("name") == "head":
            n["name"] = "cabeca"
    j["animations"] = [a for a in j["animations"] if a.get("name") != "idle"]
    ruim, _, _ = conferir(j, pasta)
    ok = not bom and any("ossos" in f for f in ruim) and any("idle" in f for f in ruim)
    print("PASSOU  a mordida: o humano passa; sem 'head' e sem 'idle', falha" if ok else f"FALHOU  a mordida: {bom} / {ruim}")
    return 0 if ok else 1


def main():
    if sys.argv[1:] == ["--teste"]:
        return teste()
    rc = 0
    for f in arquivos(sys.argv[1:]):
        falhas, tri, n = conferir(ler(f), f.parent)
        rel = f.resolve().relative_to(RAIZ) if f.resolve().is_relative_to(RAIZ) else f.name
        if falhas:
            rc = 1
            print(f"FALHOU  {rel}: " + "; ".join(falhas))
        else:
            print(f"PASSOU  {rel} ({tri} triângulos, {n} animações)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
```

(Nenhum caminho absoluto na saída: só o relativo ao repositório — a regra
do AGENTS.)

**2. Os bonecos por corpo e cabeça** (`godot/scripts/player.gd`). Cabeça e
corpo são malhas separadas no mesmo esqueleto: cada cabeça combina com cada
corpo.

```gdscript
## Os bonecos da construção (11): o corpo de um modelo com a cabeça de outro
## (o mesmo esqueleto de sete ossos), cada um com nome e pio (05). `corpo` e
## `cabeca` indexam MODELOS. `modelo_i` passa a indexar BONECOS.
const BONECOS := [
	{"nome": "Humano", "corpo": 0, "cabeca": 0,
		"pio": ["acorde", {"freqs": [880.0, 1318.5], "espaco": 0.05, "dur_nota": 0.14}]},
	{"nome": "Orc", "corpo": 1, "cabeca": 1,
		"pio": ["acorde", {"freqs": [392.0, 293.66], "espaco": 0.07, "dur_nota": 0.18}]},
	{"nome": "Meio-orc", "corpo": 0, "cabeca": 1,
		"pio": ["acorde", {"freqs": [523.25, 392.0], "espaco": 0.06, "dur_nota": 0.15}]},
	{"nome": "Orc de rosto liso", "corpo": 1, "cabeca": 0,
		"pio": ["acorde", {"freqs": [659.25, 987.77], "espaco": 0.05, "dur_nota": 0.16}]},
]
static func nome_do_boneco(i: int) -> String   # BONECOS[wrapi(i, 0, BONECOS.size())].nome
```

`visual(m, item)`: `modelo_i = wrapi(m, 0, BONECOS.size())`; carrega
`MODELOS[BONECOS[modelo_i].corpo]`; se `cabeca != corpo`, troca a malha da
cabeça:

```gdscript
func _trocar_cabeca(de_modelo: int) -> void:
	var fonte: Node3D = load("res://assets/kenney/%s.glb" % MODELOS[de_modelo]).instantiate()
	var nova: MeshInstance3D = fonte.find_child("head-mesh", true, false)
	var cabeca: MeshInstance3D = modelo.find_child("head-mesh", true, false)
	if nova and cabeca:
		cabeca.mesh = nova.mesh
		cabeca.skin = nova.skin
	fonte.free()
```

`trocou_modelo` passa a comparar o boneco (não o arquivo). Saem
`NOME_DO_MODELO` e `PIO_DO_MODELO`: `grep -rn "NOME_DO_MODELO\|PIO_DO_MODELO" godot/`
e trocar por `ForjaPlayer.nome_do_boneco(i)` e `BONECOS[i].pio`
(`Som.pio` inclusive). `VISUAL_DO_LUGAR` continua `[[0, 1], [1, 2], [0, 3], [1, 4]]`
(os dois primeiros bonecos). As traduções `"Meio-orc": "Half-orc"` e
`"Orc de rosto liso": "Smooth-faced orc"`.

**3. As peças novas** (`PECAS` e `_prender_peca()`, no mesmo padrão da G02:
caixas no espaço do osso, material fosco):

| peça | osso | caixas |
| --- | --- | --- |
| Elmo com chifres | `head` | o Elmo da G02 + dois chifres `(0.05, 0.16, 0.05)` em `(±0.22, 0.46, 0)` com `rotation.z = ±0.5`, de `Kit.material(Color("#e9e7f2"), 0.0, 0.7)` |
| Barba | `head` | `(0.30, 0.14, 0.06)` em `(0, 0.06, 0.20)` e `(0.18, 0.08, 0.05)` em `(0, -0.03, 0.20)`, de `Kit.material(Color("#6b4a32"), 0.0, 0.95)` |
| Máscara | `head` | `(0.42, 0.12, 0.04)` em `(0, 0.20, 0.21)`, de `Kit.material(Color("#2a2433"), 0.0, 0.8)` |
| Capuz | `head` | topo `(0.50, 0.10, 0.46)` em `(0, 0.43, 0)`; costas `(0.50, 0.36, 0.06)` em `(0, 0.22, -0.18)`; lados `(0.05, 0.34, 0.40)` em `(±0.25, 0.24, 0)`; pano `Kit.material(cor.darkened(0.35), 0.0, 0.9)` |

`PECAS := ["Nenhuma", "Elmo", "Capa", "Ombreira", "Elmo com chifres", "Barba", "Máscara", "Capuz"]`,
com o inglês `"Horned helmet"`, `"Beard"`, `"Mask"`, `"Hood"`. Silhuetas:
4 bonecos × 8 peças = 32.

**4. O guardião d'A Voz em blocos** (`_montar_guardiao()`, as mesmas chaves
no dicionário; a animação de `voz.gd:495-506` continua, com uma troca:
`boca.scale = Vector3(1, 0.12 + 0.75 * snappedf(grito, 0.25), 1)` — a boca
abre em degraus). Pedra `Kit.material(Color("#5e5870"), 0.0, 0.95)`, escura
`Kit.material(Color("#2a2433"), 0.0, 0.9)`, tudo filho de `pivo` (escala
0,86, como hoje):

| parte | como |
| --- | --- |
| a cabeça | testa `Kit.caixa(pivo, Vector3(2.6, 0.9, 1.0), Vector3(0, 0.95, 0), pedra)`; face `(2.9, 1.0, 1.1)` em `(0, 0.1, 0)`; queixo `(2.2, 0.8, 1.0)` em `(0, -0.8, 0)` |
| o corpo de pedra | `Kit.peca(pivo, "wall", Vector3(0, -1.2, -0.6), 0.0, 1.6)`; orelhas `Kit.peca(pivo, "column", Vector3(±1.6, -1.1, -0.2), 0.0, 0.9)` |
| as sobrancelhas | as duas caixas de hoje, em pedra escura |
| o nariz | `(0.35, 0.7, 0.35)` em `(0, 0.05, 0.62)`, pedra |
| os olhos | `Kit.caixa(pivo, Vector3(0.34, 0.22, 0.12), Vector3(±0.55, 0.3, 0.56), mat_olho)` (o `mat_olho` de hoje, emissivo) |
| as pálpebras | `(0.5, 0.44, 0.12)` em `(±0.55, 0.28, 0.62)`, pedra |
| a boca | `boca.position = Vector3(0, -0.78, 0.56)`; o fundo `(1.1, 1.0, 0.1)` escuro; os dentes como hoje, em `Kit.material(Color("#e8dcc8"), 0.0, 0.8)` |
| a luz | `brilho` e `foco` como hoje |

Sem esfera, sem bronze, `metallic` 0.

**5. A coerência em todo lugar:**

- `godot/scripts/mundo/kit.gd`: `cilindro` com `radial_segments = 8`;
  `esfera` com `radial_segments = 8`, `rings = 4`; uma função nova
  ```gdscript
  ## Uma borda redonda de 8 lados (a borda da raia, o aro): o toro facetado.
  static func anel(pai: Node, raio_dentro: float, raio_fora: float, pos: Vector3, mat: Material) -> MeshInstance3D
  ```
  (`TorusMesh` com `rings = 8`, `ring_segments = 6`, `material_override = mat`);
  o chifre da bigorna com `sides = 8`.
- Cada `TorusMesh` da lista do estado de hoje: `rings = 8` e
  `ring_segments = 6` (ou trocar o bloco por `Kit.anel`). Continua emissivo
  onde é borda (tem trabalho).
- `centelha.gd:139` e `salao.gd:223`: `radial_segments = 8`, `rings = 4`.
- Os CSG da lista: `sides = 8`.
- Os seis `metallic`: `0.2` no máximo; o ouro do Molde (`molde.gd:420-424`)
  vira `Kit.material(Color("#e8b44c"), 1.6 if forte else 0.0, 0.85)` com
  `metallic = 0.1` (fosco; brilha só o forte, que é acerto).

**6. As licenças:** nada novo na Parte A (só peças do kit e caixas).

### Parte B — com os pacotes do André

1. O André baixa em [kenney.nl](https://kenney.nl) os pacotes CC0 da mesma
   linha "mini" com personagens e **copia cada pacote para uma pasta
   própria** em `godot/assets/kenney/<pacote>/` (os `.glb` e a pasta
   `Textures/` do pacote, junto do `License.txt`), roda
   `python3 scripts/conferir_bonecos.py godot/assets/kenney/<pacote>` e
   commita **só os que passaram**, com a linha de saída do conferidor na
   mensagem de commit.
2. A sessão, para cada `.glb` que passou:
   `MODELOS.append("<pacote>/character-x")`; um boneco novo em `BONECOS`
   (`"corpo"` e `"cabeca"` o índice novo, um nome em português, um pio
   `["acorde", {...}]` com duas notas que ninguém usa); a tradução do nome.
3. `"$GODOT" --headless --path godot --import --quit` para nascerem os
   `.import`; commitar os `.import`.
4. `LICENCAS-DE-TERCEIROS.md`: uma linha na tabela (`| <pacote> | Kenney
   (www.kenney.nl) | CC0 1.0 |`) e o texto da licença do pacote numa seção
   como a do Mini Dungeon; `godot/assets/LEIA-ME.md`: uma linha na tabela
   (`kenney/<pacote>/`, "personagens", Kenney, CC0).
5. Os bonecos do André (fonte c de 11) entram pelo mesmo caminho: o
   conferidor passa, a pasta `godot/assets/personagens/<autor>/`, a licença
   do autor anotada nos dois arquivos.

Sem pacote no repositório, a sessão faz só a Parte A e deixa no quadro
"G08 — Parte B espera os pacotes".

## Passos

Rodar `bash tests/prova_do_jogo.sh` depois dos passos 2, 4 e 6.

1. **`scripts/conferir_bonecos.py`** (novo) e
   `python3 scripts/conferir_bonecos.py && python3 scripts/conferir_bonecos.py --teste`
   (os dois bonecos de hoje passam; a mordida passa).
2. **`godot/scripts/player.gd`:** `BONECOS`, `nome_do_boneco()`,
   `_trocar_cabeca()`; sair `NOME_DO_MODELO` e `PIO_DO_MODELO`, trocando os
   usos (`main.gd`, `som.gd`, `tela_lobby.gd`, `cartao_jogador.gd`).
3. **`godot/scripts/player.gd`:** as quatro peças novas.
4. **`godot/scripts/salas/voz.gd`:** o guardião em blocos e a boca em
   degraus.
5. **`godot/scripts/mundo/kit.gd`, as salas, o salão, `efeitos.gd`,
   `player.gd`:** facetas e `metallic` (item 5 do alvo).
6. **`godot/scripts/traducoes.gd`:** os nomes e as peças.
7. **`tests/prova_do_jogo.sh`:** antes do Godot, a linha
   `python3 "$RAIZ/scripts/conferir_bonecos.py" > "$TMP/bonecos.log" && python3 "$RAIZ/scripts/conferir_bonecos.py" --teste >> "$TMP/bonecos.log" || { cat "$TMP/bonecos.log"; echo "FAIL os bonecos"; exit 1; }`.
8. **A prova do jogo** (ver Provas). **A Parte B**, se os pacotes estão
   no repositório.

## Armadilhas

- **Nenhum `.gd` novo** (o conferidor é Python); se criar um, o `.uid`.
- **A textura do pacote novo:** nunca na raiz de `godot/assets/kenney/`;
  cada pacote na sua pasta, senão o `Textures/colormap.png` do Mini Dungeon
  é sobrescrito e tudo muda de cor.
- **Animação por nome:** um boneco sem `idle`, `walk`, `emote-yes`… quebra
  as salas; o conferidor exige a lista de 11 mais `static` (a introdução) e
  `interact-right` (a construção).
- **`modelo_i` mudou de sentido** (agora indexa `BONECOS`): confira cada
  `modelo_i` que o `grep` achar; o cavaleiro guardado em `Opcoes.cavaleiro`
  (G02) usa o índice do boneco — os dois primeiros são os mesmos de antes.
- **As peças do guardião mexem na animação:** `palpebras` e `boca` precisam
  ser os mesmos tipos (`Node3D` com escala); `position.y` das pálpebras
  começa em 0,28, como a animação espera.
- **Nada de caminho absoluto** na saída do conferidor nem no commit.
- **A luz da casa não muda:** a Parte A só troca geometria e `metallic`;
  tocha, lilás e névoa ficam.
- **O robô:** nada aqui.

## Não fazer

- Não baixar pacote da internet na sessão: quem baixa e confere a licença é
  o André.
- Não trocar a lava da Viga (fica, 11).
- Não pôr brilho novo fora de olho, runa, borda, néon e acerto.
- Não usar o SDK da Sony nem modelo de fora do Kenney sem licença anotada.
- Não criar animação nova.

## Pronto quando

A construção oferece pelo menos doze silhuetas diferentes (bonecos × peças);
o conferidor passa os bonecos registrados e morde um boneco quebrado; a
prova do jogo não acha, em nenhuma sala, curva lisa nem `metallic` acima de
0,2; o guardião d'A Voz é de pedra em blocos, com a mesma animação; e as
fotos de todas as salas passam no checklist de 11.

## Provas

**Na sessão:** `bash tests/prova_do_jogo.sh` (com a linha do conferidor do
passo 7).

Em `godot/testes/prova_do_jogo.gd`:

```gdscript
## O checklist de arte que se confere sem olho (11): nada liso, nada metálico.
func _confere_a_arte(raiz: Node, onde: String) -> void:
	var lisas: Array = []
	var metalicos: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var m := mi.mesh
		if (m is SphereMesh and (m as SphereMesh).radial_segments > 8) \
				or (m is TorusMesh and (m as TorusMesh).rings > 8) \
				or (m is CylinderMesh and (m as CylinderMesh).radial_segments > 8):
			lisas.append(str(raiz.get_path_to(mi)))
		var mat := mi.material_override
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).metallic > 0.2:
			metalicos.append(str(raiz.get_path_to(mi)))
	for n in raiz.find_children("*", "CSGCylinder3D", true, false):
		if (n as CSGCylinder3D).sides > 8:
			lisas.append(str(raiz.get_path_to(n)))
	for n in raiz.find_children("*", "CSGTorus3D", true, false):
		if (n as CSGTorus3D).sides > 8:
			lisas.append(str(raiz.get_path_to(n)))
	_esperar(lisas.is_empty(), "%s: nenhuma curva lisa %s" % [onde, lisas])
	_esperar(metalicos.is_empty(), "%s: nada metálico acima de 0,2 %s" % [onde, metalicos])
```

Chamadas: em `_comeca_a_sala(id)`, logo depois de
`_esperar(sala is SalaJogo and sala.id == id, …)`:
`_confere_a_arte(sala, id)`; e uma vez no salão, depois da construção:
`_confere_a_arte(jogo.salao, "o salão")` e
`_confere_a_arte(jogo.jogadores[0], "o boneco")`.

E uma função nova, chamada no `_ready()` depois de `_prova_do_percurso()`:

```gdscript
## Os bonecos: cada um carrega com os sete ossos e as animações, a cabeça
## trocada é a do outro modelo, e há silhuetas de sobra.
func _prova_dos_bonecos() -> void:
	var p: ForjaPlayer = jogo.jogadores[3]
	var antes: Dictionary = p.cavaleiro()
	_esperar(ForjaPlayer.BONECOS.size() * ForjaPlayer.PECAS.size() >= 12,
		"pelo menos doze silhuetas (%d)" % (ForjaPlayer.BONECOS.size() * ForjaPlayer.PECAS.size()))
	for i in ForjaPlayer.BONECOS.size():
		p.visual(i, 0)
		var esq: Skeleton3D = p.modelo.find_child("Skeleton3D", true, false)
		var ossos := []
		for k in esq.get_bone_count():
			ossos.append(esq.get_bone_name(k))
		ossos.sort()
		_esperar(ossos == ["arm-left", "arm-right", "head", "leg-left", "leg-right", "root", "torso"],
			"%s: os sete ossos" % ForjaPlayer.nome_do_boneco(i))
		var faltam := []
		for a in ["idle", "walk", "sprint", "jump", "fall", "die", "emote-yes", "emote-no", "attack-melee-right", "holding-right", "static", "interact-right"]:
			if not p.anim.has_animation(a):
				faltam.append(a)
		_esperar(faltam.is_empty(), "%s: as animações %s" % [ForjaPlayer.nome_do_boneco(i), faltam])
		var b: Dictionary = ForjaPlayer.BONECOS[i]
		if int(b.cabeca) != int(b.corpo):
			var outro: Node3D = load("res://assets/kenney/%s.glb" % ForjaPlayer.MODELOS[int(b.cabeca)]).instantiate()
			var esperada: Mesh = (outro.find_child("head-mesh", true, false) as MeshInstance3D).mesh
			outro.free()
			_esperar((p.modelo.find_child("head-mesh", true, false) as MeshInstance3D).mesh == esperada,
				"%s: a cabeça é a do outro modelo" % ForjaPlayer.nome_do_boneco(i))
	for k in ForjaPlayer.PECAS.size():
		p.vestir({"boneco": 0, "peca": k})
		var presas := p.modelo.find_children("Peca*", "BoneAttachment3D", true, false)
		_esperar((k == 0) == presas.is_empty(), "a peça %s %s" % [ForjaPlayer.PECAS[k], "não prende nada" if k == 0 else "prende no osso"])
	p.vestir(antes)
```

E n'A Voz (onde a prova já joga a sala), depois de abrir:
`_esperar(sala.g.pivo.find_children("*", "MeshInstance3D", true, false).all(func(m): return not (m.mesh is SphereMesh)), "o guardião d'A Voz não tem esfera")`.

## Para o André (local)

1. `bash tests/telas.sh fotos /tmp/fotos-g08` e olhar lado a lado com as de
   antes: A Voz (o guardião de pedra), a Galeria (alvos de 8 lados), O Molde
   (ouro fosco), as bordas das raias; passar cada foto no
   [checklist](../11-arte-e-personagens.md#o-checklist-de-aprovação).
2. Na construção, passar pelos quatro bonecos e as oito peças: cada pio é
   diferente, nenhuma peça atravessa a cabeça.
3. **Parte B:** baixar os pacotes, `python3 scripts/conferir_bonecos.py
   godot/assets/kenney/<pacote>`, commitar só o que passou (com a saída do
   conferidor na mensagem) e abrir uma sessão nova com esta ficha para
   registrar.

## Ao terminar

No [quadro](README.md), G08 **feito** (ou "Parte A feita — a B espera os
pacotes") com o commit e o gasto. Commit sugerido (sem trailer):

```
feat: doze silhuetas de bonecos, o guardião d'A Voz em blocos e o conferidor de bonecos
```
