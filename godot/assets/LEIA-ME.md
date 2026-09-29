# De onde vem cada coisa desta pasta

| pasta | o que é | origem | licença |
|---|---|---|---|
| `svg/dualsense.svg`, `svg/pecas-do-dualsense.csv` | o desenho do DualSense e a fonte da verdade das peças | app Hefesto (`ds_limpo.svg`, `docs/data/pecas-do-dualsense.csv`) | MIT, aviso abaixo |
| `mapa/` | as camadas do mapa do controle (uma por peça) e `pecas.json` | geradas do `svg/` por `scripts/mapa_do_controle.js` | MIT, aviso abaixo |
| `svg/glifos/`, `svg/hefesto-logo.svg` | os glifos dos botões e das features e o logo | app Hefesto (`assets/glyphs/`, `assets/hefesto-logo.svg`), sem mudança | MIT, aviso abaixo |
| `glifos/`, `hefesto-logo.png` | as mesmas figuras em PNG (máscara branca, para tingir) | geradas do `svg/` por `scripts/mapa_do_controle.js` | MIT, aviso abaixo |
| `fontes/` | Space Grotesk e JetBrains Mono, os arquivos variáveis que o app Hefesto usa | google/fonts, commit `7ff85c87f93ea6cca5f41c69f2e4edcb90240f26` (sha256 `acad6de1…f72` e `48715a42…eda`, os mesmos que o Hefesto fixa) | SIL OFL 1.1, textos ao lado |
| `kenney/` | modelos Mini Dungeon | Kenney (www.kenney.nl) | CC0, `kenney/KENNEY-LICENSE.txt` |
| `sons/` | os efeitos gravados (martelo, golpe, escudo, tiro, sino, passos, interface, jingles), em WAV 48 kHz mono | Kenney: Impact Sounds, Interface Sounds, RPG Audio, Digital Audio e Music Jingles (www.kenney.nl), convertidos de OGG | CC0, `sons/KENNEY-LICENSE.txt` |

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
