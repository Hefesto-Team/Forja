// O mapa do controle para o jogo: o SVG do DualSense desenhado para o Hefesto
// (godot/assets/svg/dualsense.svg, o mesmo `ds_limpo.svg` do app) vira camadas
// PNG que o jogo empilha e acende por peça — o botão apertado, o analógico
// andando, o motor vibrando, a barra de luz na cor que o jogo mandou.
//
// Por que PNG e não o SVG direto: o desenho pinta as zonas com CSS (variáveis,
// seletor de atributo, :is/:not) e contorno por filtro, e o rasterizador de
// SVG do Godot (ThorVG) não lê nada disso. O Chromium lê igual ao app, então as
// camadas saem exatamente como o desenho.
//
//   npm install playwright   (uma vez; ou NODE_PATH para um playwright que já exista)
//   node scripts/mapa_do_controle.js
//
// E o logo do Hefesto (godot/assets/svg/hefesto-logo.svg) em godot/assets/hefesto-logo.png,
// e os glifos de feature do app (godot/assets/svg/glifos) em godot/assets/glifos/.
//
// Escreve godot/assets/mapa/: base.png e corpo.png (o desenho inteiro), os
// miolos dos analógicos, uma máscara branca por peça (<id>.png) e uma por glifo
// (glifo-<id>.png) — cada uma recortada na caixa da peça, para não serem 50
// texturas do tamanho do desenho — e pecas.json: onde cada camada senta no
// desenho (px) e as caixas das peças no viewBox (de pecas-do-dualsense.csv).
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const RAIZ = path.resolve(__dirname, '..');
const SVG = path.join(RAIZ, 'godot/assets/svg/dualsense.svg');
const CSV = path.join(RAIZ, 'godot/assets/svg/pecas-do-dualsense.csv');
const SAIDA = path.join(RAIZ, 'godot/assets/mapa');
const LOGO = path.join(RAIZ, 'godot/assets/svg/hefesto-logo.svg');
const LOGO_PNG = path.join(RAIZ, 'godot/assets/hefesto-logo.png');
const GLIFOS_SVG = path.join(RAIZ, 'godot/assets/svg/glifos');
const GLIFOS_PNG = path.join(RAIZ, 'godot/assets/glifos');

// A base neutra: só tokens da paleta do Hefesto. A casca sai numa camada
// própria, que o jogo pinta na cor de luz do jogador (a borda diz QUAL).
const NEUTRO = {
  painel: '#9a9eb8',
  touch: '#53576f',
  gatilhos: '#9a9eb8',
  dpad: '#9a9eb8',
  analogicos: '#9a9eb8',
  botoes_face: '#9a9eb8',
  simbolos: '#c8ccda',
};
const GLIFOS_COR = '#c8ccda';
const MIOLO_COR = '#44475a';
// as cinco lâmpadas apagadas: o soquete aparece, mas não acende
const LAMPADA_APAGADA = '#44475a';

const MASCARAS = [
  'triangle', 'circle', 'square', 'cross',
  'dpad_up', 'dpad_right', 'dpad_down', 'dpad_left',
  'l1', 'r1', 'l2', 'r2', 'share', 'options', 'ps', 'mic', 'touchpad',
  'stick_l', 'stick_r', 'lightbar', 'alto-falante',
  'led-jogador-1', 'led-jogador-2', 'led-jogador-3', 'led-jogador-4', 'led-jogador-5',
  'feat-rumble-esquerdo', 'feat-rumble-direito',
];
const GLIFOS = [
  'triangle', 'circle', 'square', 'cross',
  'dpad_up', 'dpad_right', 'dpad_down', 'dpad_left',
  'l1', 'r1', 'l2', 'r2', 'stick_l', 'stick_r', 'share', 'options', 'ps', 'mic',
];

const FORMAS = ':is(path,rect,circle,ellipse,polygon,polyline,line)';

function regrasNeutras() {
  let css = 'svg{';
  for (const [z, c] of Object.entries(NEUTRO)) css += `--z-${z}:${c};`;
  css += '}';
  for (const z of Object.keys(NEUTRO)) {
    if (z === 'simbolos') continue;
    css += `svg .z-${z} ${FORMAS}:not([fill="none"]){fill:var(--z-${z}) !important}`;
  }
  css += `svg .z-simbolos{color:var(--z-simbolos) !important}`;
  css += `#grupo-glifos{color:${GLIFOS_COR}}`;
  css += `#led-jogador rect{fill:${LAMPADA_APAGADA} !important}`;
  return css;
}

const SEM_FILTRO = '*{filter:none !important}';
const ESCONDE_OCULTAS = '.oculta{display:none !important}';

// Só a peça, em branco: o jogo tinge. Tudo o mais fica invisível (visibility
// herda, e a peça a desfaz); o que era `.oculta` volta a aparecer quando é ela.
function soPeca(seletor) {
  return (
    SEM_FILTRO +
    'svg *{visibility:hidden !important}' +
    `${seletor},${seletor} *{visibility:visible !important;display:inline !important;opacity:1 !important}` +
    `${seletor} ${FORMAS}:not([fill="none"]),${seletor}${FORMAS}:not([fill="none"]){fill:#fff !important}` +
    `${seletor} [stroke]:not([stroke="none"]),${seletor}[stroke]:not([stroke="none"]){stroke:#fff !important}` +
    `${seletor}{color:#fff !important}${seletor} *{color:#fff !important}`
  );
}

function lerCsv() {
  const linhas = fs.readFileSync(CSV, 'utf8').split('\n').filter((l) => l && !l.startsWith('#'));
  const campos = (l) => {
    const out = [];
    let cur = '';
    let aspas = false;
    for (const ch of l) {
      if (ch === '"') aspas = !aspas;
      else if (ch === ',' && !aspas) {
        out.push(cur);
        cur = '';
      } else cur += ch;
    }
    out.push(cur);
    return out;
  };
  const cab = campos(linhas[0]);
  const pecas = {};
  for (const l of linhas.slice(1)) {
    const v = campos(l);
    const r = Object.fromEntries(cab.map((c, i) => [c, v[i]]));
    const num = (x) => (x === undefined || x === '-' || x === '' ? null : Number(x));
    pecas[r.id] = {
      nome: r.nome,
      tipo: r.tipo,
      regiao: r.regiao,
      glifo: r.glifo === '-' ? null : r.glifo,
      no_svg: r.no_svg,
      caixa: [num(r.x1), num(r.y1), num(r.x2), num(r.y2)],
      angulo: num(r.angulo) || 0,
      zona: r.zona,
    };
  }
  return pecas;
}

(async () => {
  fs.mkdirSync(SAIDA, { recursive: true });
  const svg = fs.readFileSync(SVG, 'utf8');
  const caixa = svg.match(/viewBox="([^"]+)"/)[1].split(/\s+/).map(Number);
  const navegador = await chromium.launch({ args: ['--no-sandbox'] });
  const pagina = await navegador.newPage({ viewport: { width: 1160, height: 800 } });
  // o .oculta volta ao display quando é a peça; o `display:inline` da regra
  // da peça cuida disso, e o getBoundingClientRect precisa dele ligado
  await pagina.setContent(
    `<html><body style="margin:0;background:transparent">${svg}<style id="camada"></style></body></html>`
  );
  await pagina.evaluate(() => document.querySelector('svg').removeAttribute('data-colorway'));
  const camadas = {};
  // `recorte`: o seletor cuja caixa na tela limita a foto (null: o desenho todo)
  const foto = async (nome, css, recorte = null) => {
    await pagina.evaluate((c) => (document.getElementById('camada').textContent = c), css);
    let caixa = { x: 0, y: 0, width: 1160, height: 800 };
    if (recorte) {
      const r = await pagina.evaluate((sel) => {
        const els = document.querySelectorAll(sel);
        let x1 = 1e9, y1 = 1e9, x2 = -1e9, y2 = -1e9;
        for (const e of els) {
          const b = e.getBoundingClientRect();
          if (b.width === 0 && b.height === 0) continue;
          x1 = Math.min(x1, b.left); y1 = Math.min(y1, b.top);
          x2 = Math.max(x2, b.right); y2 = Math.max(y2, b.bottom);
        }
        return [x1, y1, x2, y2];
      }, recorte);
      const x = Math.max(0, Math.floor(r[0]) - 3);
      const y = Math.max(0, Math.floor(r[1]) - 3);
      caixa = {
        x, y,
        width: Math.min(1160, Math.ceil(r[2]) + 3) - x,
        height: Math.min(800, Math.ceil(r[3]) + 3) - y,
      };
    }
    await pagina.screenshot({ path: path.join(SAIDA, nome), omitBackground: true, clip: caixa });
    camadas[nome.replace(/\.png$/, '')] = [caixa.x, caixa.y, caixa.width, caixa.height];
  };

  const neutro = regrasNeutras();
  // a base: sem a casca (é do jogador) e sem os miolos dos analógicos (andam)
  await foto('base.png', SEM_FILTRO + ESCONDE_OCULTAS + neutro + '#corpo,#stick_l .miolo,#stick_r .miolo{visibility:hidden !important}');
  await foto('corpo.png', soPeca('#corpo'));
  const miolo = (lado) =>
    SEM_FILTRO + neutro +
    'svg *{visibility:hidden !important}' +
    `#stick_${lado} .miolo,#stick_${lado} .miolo *,#glifo-stick_${lado},#glifo-stick_${lado} *{visibility:visible !important}` +
    `#stick_${lado} .miolo ${FORMAS}{fill:${MIOLO_COR} !important}`;
  await foto('miolo_l.png', miolo('l'), '#stick_l .miolo, #glifo-stick_l');
  await foto('miolo_r.png', miolo('r'), '#stick_r .miolo, #glifo-stick_r');
  for (const id of MASCARAS) await foto(`${id}.png`, soPeca(`#${id}`), `#${id}`);
  for (const id of GLIFOS) await foto(`glifo-${id}.png`, soPeca(`#glifo-${id}`), `#glifo-${id}`);

  // o logo do Hefesto (com os filtros de contorno, que o ThorVG não lê)
  const logo = await navegador.newPage({ viewport: { width: 512, height: 512 } });
  await logo.setContent(`<html><body style="margin:0;background:transparent">${fs.readFileSync(LOGO, 'utf8')}</body></html>`);
  await logo.locator('svg').screenshot({ path: LOGO_PNG, omitBackground: true });

  // os glifos de feature do app (assets/glyphs), em branco a 128 px: o jogo tinge
  fs.mkdirSync(GLIFOS_PNG, { recursive: true });
  const glifo = await navegador.newPage({ viewport: { width: 128, height: 128 } });
  for (const arq of fs.readdirSync(GLIFOS_SVG).filter((f) => f.endsWith('.svg')).sort()) {
    const svgGlifo = fs.readFileSync(path.join(GLIFOS_SVG, arq), 'utf8')
      .replace(/<\?xml[^>]*>/, '')
      .replace(/width="32" height="32"/, 'width="128" height="128"');
    await glifo.setContent(
      `<html><body style="margin:0;background:transparent">${svgGlifo}` +
      '<style>svg *{stroke:#fff !important}svg [fill]:not([fill="none"]){fill:#fff !important}</style></body></html>'
    );
    await glifo.locator('svg').screenshot({ path: path.join(GLIFOS_PNG, arq.replace('.svg', '.png')), omitBackground: true });
  }
  await navegador.close();

  const json = {
    fonte: 'godot/assets/svg/dualsense.svg e pecas-do-dualsense.csv (Hefesto, MIT)',
    viewbox: caixa,
    largura: 1160,
    altura: 800,
    camadas,
    pecas: lerCsv(),
  };
  fs.writeFileSync(path.join(SAIDA, 'pecas.json'), JSON.stringify(json, null, 1) + '\n');
  console.log(`mapa do controle: ${MASCARAS.length + GLIFOS.length + 4} camadas em ${path.relative(RAIZ, SAIDA)}/`);
})();
