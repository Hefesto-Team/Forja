# De onde vem cada coisa desta pasta

| pasta | o que é | origem | licença |
|---|---|---|---|
| `svg/dualsense.svg`, `svg/pecas-do-dualsense.csv` | o desenho do DualSense e a fonte da verdade das peças | app Hefesto (`ds_limpo.svg`, `docs/data/pecas-do-dualsense.csv`) | MIT, aviso abaixo |
| `mapa/` | as camadas do mapa do controle (uma por peça) e `pecas.json` | geradas do `svg/` por `scripts/mapa_do_controle.js` | MIT, aviso abaixo |
| `svg/glifos/`, `svg/hefesto-logo.svg` | os glifos dos botões e das features e o logo | app Hefesto (`assets/glyphs/`, `assets/hefesto-logo.svg`), sem mudança | MIT, aviso abaixo |
| `glifos/`, `hefesto-logo.png` | as mesmas figuras em PNG (máscara branca, para tingir) | geradas do `svg/` por `scripts/mapa_do_controle.js` | MIT, aviso abaixo |
| `fontes/` | Bungee, VT323, Archivo Narrow e Permanent Marker, as quatro letras da bíblia de arte (`docs/jogo/arte/02-cor-e-letra.md`) | google/fonts | SIL OFL 1.1 (Permanent Marker: Apache 2.0), textos ao lado |
| `ost/` | a trilha: as 45 faixas, as telas e os jingles, em OGG Vorbis 48 kHz estéreo, e os mapas de batidas (`.batidas.json`) | geradas na própria máquina com o ACE-Step 1.5 (modelo aberto, licença MIT), pelo `scripts/gerar_trilha.py` — ver `ost/LEIA-ME.md` | sem autor pela lei; seguem com a licença do repositório |
| `sons/` | os efeitos gravados (martelo, golpe, escudo, tiro, sino, passos, interface, jingles), em WAV 48 kHz mono | Kenney: Impact Sounds, Interface Sounds, RPG Audio, Digital Audio e Music Jingles (www.kenney.nl), convertidos de OGG | CC0, `sons/KENNEY-LICENSE.txt` |
| `kenney/mini-characters/` | Mini Characters (personagem), 12 modelos | Kenney (www.kenney.nl), Mini Characters 1.0 | CC0, `kenney/mini-characters/License.txt` |
| `kenney/cube-pets/` | Cube Pets (peca), 1 modelo | Kenney (www.kenney.nl), Cube Pets 2.0 | CC0, `kenney/cube-pets/License.txt` |
| `kenney/graveyard-kit/` | Graveyard Kit (cenario), 90 modelos | Kenney (www.kenney.nl), Graveyard Kit 5.0 | CC0, `kenney/graveyard-kit/License.txt` |
| `kenney/castle-kit/` | Castle Kit (cenario), 76 modelos | Kenney (www.kenney.nl), Castle Kit 2.0 | CC0, `kenney/castle-kit/License.txt` |
| `kenney/factory-kit/` | Factory Kit (cenario), 143 modelos | Kenney (www.kenney.nl), Factory Kit 3.0 | CC0, `kenney/factory-kit/License.txt` |
| `kenney/mini-dungeon/` | Mini Dungeon (cenario), 28 modelos | Kenney (www.kenney.nl), Mini Dungeon 2.0 | CC0, `kenney/mini-dungeon/License.txt` |
| `kenney/mini-dungeon-personagens/` | Mini Dungeon (personagem), 2 modelos | Kenney (www.kenney.nl), Mini Dungeon 2.0 | CC0, `kenney/mini-dungeon-personagens/License.txt` |

Nenhum destes arquivos vem do SDK da Sony.

## Aviso MIT do desenho do controle

```
MIT License

Copyright (c) 2026 Hefesto Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
