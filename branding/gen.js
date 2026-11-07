// Brand asset generator for "الوقار" — renders SVG sources to PNG with resvg.
const { Resvg } = require('@resvg/resvg-js');
const fs = require('fs');
const path = require('path');

const PROJECT = process.argv[2];
const OUT = path.join(PROJECT, 'assets', 'brand');
const SRC = path.join(PROJECT, 'branding', 'svg');
const IMG = path.join(PROJECT, 'assets', 'images');
fs.mkdirSync(OUT, { recursive: true });
fs.mkdirSync(SRC, { recursive: true });
fs.mkdirSync(IMG, { recursive: true });
const FONTS = ['Amiri-Bold.ttf', 'Amiri-Regular.ttf', 'Tajawal-Bold.ttf', 'Tajawal-Medium.ttf']
  .map((f) => path.join(PROJECT, 'assets', 'fonts', f));

const C = {
  emerald: '#0E4D3C',
  emeraldDeep: '#08362A',
  emeraldLight: '#1F7A5E',
  gold: '#C9A24B',
  goldLight: '#E6C878',
  ivory: '#FAF6EC',
  ink: '#16211D',
};

function starPoints(cx, cy, R) {
  const r = R * 0.7654;
  const pts = [];
  for (let i = 0; i < 16; i++) {
    const ang = (Math.PI / 8) * i - Math.PI / 2;
    const rad = i % 2 === 0 ? R : r;
    pts.push(`${(cx + rad * Math.cos(ang)).toFixed(2)},${(cy + rad * Math.sin(ang)).toFixed(2)}`);
  }
  return pts.join(' ');
}

// The mark, drawn in a 512x512 box. variant: 'color' | 'mono' | 'onDark'
function mark({ star = C.gold, starFill = C.emerald, page = C.ivory, lines = C.emerald, flame = C.gold, mono = false } = {}) {
  const pageLines = [0, 1, 2, 3].map((i) => {
    const y = 250 + i * 18;
    return `<path d="M170 ${y + 2} C 200 ${y - 4}, 228 ${y - 2}, 244 ${y + 6}" stroke="${lines}" stroke-opacity="${mono ? 0 : 0.35}" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="M342 ${y + 2} C 312 ${y - 4}, 284 ${y - 2}, 268 ${y + 6}" stroke="${lines}" stroke-opacity="${mono ? 0 : 0.35}" stroke-width="5" fill="none" stroke-linecap="round"/>`;
  }).join('\n');
  return `
<polygon points="${starPoints(256, 256, 236)}" fill="${starFill}" stroke="${star}" stroke-width="14" stroke-linejoin="round"/>
<polygon points="${starPoints(256, 256, 206)}" fill="none" stroke="${star}" stroke-opacity="0.45" stroke-width="4" stroke-linejoin="round"/>
<path d="M256 352 C 222 328, 182 322, 146 330 L 146 232 C 182 224, 222 230, 256 256 Z" fill="${page}"/>
<path d="M256 352 C 290 328, 330 322, 366 330 L 366 232 C 330 224, 290 230, 256 256 Z" fill="${page}"/>
<path d="M256 256 L 256 352" stroke="${star}" stroke-width="6" stroke-linecap="round"/>
${pageLines}
<path d="M256 118 C 276 148, 288 170, 256 210 C 224 170, 236 148, 256 118 Z" fill="${flame}"/>
<path d="M256 150 L256 192" stroke="${mono ? "none" : starFill}" stroke-width="6" stroke-linecap="round"/>`;
}

const defs = `<defs>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="${C.emeraldLight}"/><stop offset="1" stop-color="${C.emeraldDeep}"/>
</linearGradient>
<pattern id="geo" width="64" height="64" patternUnits="userSpaceOnUse">
  <polygon points="${starPoints(32, 32, 22)}" fill="none" stroke="${C.gold}" stroke-opacity="0.10" stroke-width="1.5"/>
</pattern>
</defs>`;

function svg(w, h, body, extraDefs = '') {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${defs}${extraDefs}${body}</svg>`;
}

const files = {
  // Full-bleed launcher icon (iOS + legacy Android)
  'app_icon.svg': svg(1024, 1024, `<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#geo)"/>
<g transform="translate(152 152) scale(1.40625)">${mark({ starFill: C.emeraldDeep })}</g>`),
  // Adaptive icon foreground: mark within the 66% safe zone
  'adaptive_foreground.svg': svg(1024, 1024, `<g transform="translate(272 272) scale(0.9375)">${mark({ starFill: C.emeraldDeep })}</g>`),
  'adaptive_background.svg': svg(1024, 1024, `<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#geo)"/>`),
  // Android 13 themed (monochrome) icon & notification icon
  'adaptive_monochrome.svg': svg(1024, 1024, `<g transform="translate(272 272) scale(0.9375)">${mark({ star: '#fff', starFill: 'none', page: '#fff', lines: '#fff', flame: '#fff', mono: true })}</g>`),
  'notification_icon.svg': svg(96, 96, `<g transform="scale(0.1875)">${mark({ star: '#fff', starFill: 'none', page: '#fff', lines: '#fff', flame: '#fff', mono: true })}</g>`),
  // Icon-only mark (transparent)
  'logo_mark.svg': svg(512, 512, mark()),
  'logo_mark_on_dark.svg': svg(512, 512, mark({ starFill: C.emeraldDeep, page: C.ivory })),
  // Splash mark: larger, sits on emerald background
  'splash_logo.svg': svg(768, 768, `<g transform="translate(128 128)">${mark({ starFill: C.emeraldDeep })}</g>`),
  // Primary horizontal logo, light background
  'logo_primary_light.svg': svg(1400, 520, `<rect width="1400" height="520" rx="48" fill="${C.ivory}"/>
<g transform="translate(900 40) scale(0.86)">${mark()}</g>
<text x="860" y="285" text-anchor="end" font-family="Amiri" font-weight="700" font-size="230" fill="${C.emerald}" direction="rtl">الوقار</text>
<text x="860" y="440" text-anchor="end" font-family="Tajawal" font-weight="500" font-size="60" fill="${C.gold}" direction="rtl">وقارُ الحفظ وإتقانُ التسميع</text>`),
  // Primary horizontal logo, dark background
  'logo_primary_dark.svg': svg(1400, 520, `<rect width="1400" height="520" rx="48" fill="${C.emeraldDeep}"/><rect width="1400" height="520" rx="48" fill="url(#geo)"/>
<g transform="translate(900 40) scale(0.86)">${mark({ starFill: C.emerald })}</g>
<text x="860" y="285" text-anchor="end" font-family="Amiri" font-weight="700" font-size="230" fill="${C.ivory}" direction="rtl">الوقار</text>
<text x="860" y="440" text-anchor="end" font-family="Tajawal" font-weight="500" font-size="60" fill="${C.goldLight}" direction="rtl">وقارُ الحفظ وإتقانُ التسميع</text>`),
  // Stacked logo (transparent) used in-app on light surfaces
  'logo_stacked.svg': svg(800, 900, `<g transform="translate(144 40)">${mark()}</g>
<text x="400" y="740" text-anchor="middle" font-family="Amiri" font-weight="700" font-size="200" fill="${C.emerald}" direction="rtl">الوقار</text>
<text x="400" y="860" text-anchor="middle" font-family="Tajawal" font-weight="500" font-size="54" fill="${C.gold}" direction="rtl">وقارُ الحفظ وإتقانُ التسميع</text>`),
};

// Onboarding illustrations (800x640, transparent background)
function card(x, y, w, h, fill, extra = '') {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="22" fill="${fill}" ${extra}/>`;
}
files['onboarding_1.svg'] = svg(800, 640, `
<circle cx="400" cy="320" r="270" fill="${C.emerald}" fill-opacity="0.08"/>
<circle cx="400" cy="320" r="200" fill="${C.emerald}" fill-opacity="0.08"/>
<g transform="translate(220 120) scale(0.70)">${mark()}</g>
${[0, 1, 2, 3, 4, 5, 6, 7].map((i) => { const a = (Math.PI / 4) * i; return `<circle cx="${400 + 255 * Math.cos(a)}" cy="${320 + 255 * Math.sin(a)}" r="10" fill="${C.gold}" fill-opacity="0.7"/>`; }).join('')}
${card(90, 470, 190, 90, '#fff', `stroke="${C.gold}" stroke-opacity="0.5" stroke-width="3"`)}
<rect x="112" y="495" width="110" height="14" rx="7" fill="${C.emerald}" fill-opacity="0.8"/><rect x="112" y="522" width="70" height="12" rx="6" fill="${C.gold}"/>
${card(520, 80, 190, 90, '#fff', `stroke="${C.gold}" stroke-opacity="0.5" stroke-width="3"`)}
<rect x="542" y="105" width="130" height="14" rx="7" fill="${C.emerald}" fill-opacity="0.8"/><rect x="542" y="132" width="90" height="12" rx="6" fill="${C.gold}"/>`);

files['onboarding_2.svg'] = svg(800, 640, `
<circle cx="400" cy="320" r="270" fill="${C.emerald}" fill-opacity="0.07"/>
${card(170, 90, 460, 470, '#fff', `stroke="${C.emerald}" stroke-opacity="0.15" stroke-width="3"`)}
${[0, 1, 2].map((i) => {
  const y = 130 + i * 140;
  const colors = [C.emerald, C.gold, C.emeraldLight];
  return `<circle cx="572" cy="${y + 45}" r="34" fill="${colors[i]}" fill-opacity="0.9"/>
<rect x="320" y="${y + 22}" width="210" height="16" rx="8" fill="${C.ink}" fill-opacity="0.75"/>
<rect x="390" y="${y + 52}" width="140" height="12" rx="6" fill="${C.ink}" fill-opacity="0.3"/>
<rect x="206" y="${y + 24}" width="84" height="42" rx="21" fill="${C.gold}" fill-opacity="${i === 0 ? 1 : 0.35}"/>
<text x="248" y="${y + 54}" text-anchor="middle" font-family="Tajawal" font-weight="700" font-size="26" fill="${i === 0 ? '#fff' : C.ink}">${['+60', '+40', '+25'][i]}</text>`;
}).join('')}
<g transform="translate(600 430)"><circle r="70" fill="${C.gold}"/><path d="M-30 2 L-8 26 L34 -22" stroke="#fff" stroke-width="16" fill="none" stroke-linecap="round" stroke-linejoin="round"/></g>`);

files['onboarding_3.svg'] = svg(800, 640, `
<circle cx="400" cy="320" r="270" fill="${C.emerald}" fill-opacity="0.07"/>
<rect x="320" y="300" width="160" height="240" rx="14" fill="${C.emerald}"/>
<rect x="150" y="370" width="160" height="170" rx="14" fill="${C.emeraldLight}"/>
<rect x="490" y="420" width="160" height="120" rx="14" fill="${C.emerald}" fill-opacity="0.55"/>
<text x="400" y="440" text-anchor="middle" font-family="Tajawal" font-weight="700" font-size="90" fill="${C.goldLight}">١</text>
<text x="230" y="480" text-anchor="middle" font-family="Tajawal" font-weight="700" font-size="70" fill="${C.ivory}">٢</text>
<text x="570" y="505" text-anchor="middle" font-family="Tajawal" font-weight="700" font-size="60" fill="${C.ivory}">٣</text>
<g transform="translate(400 210)">
  <path d="M-80 -40 L-40 10 L0 -60 L40 10 L80 -40 L66 60 L-66 60 Z" fill="${C.gold}" stroke="${C.goldLight}" stroke-width="6" stroke-linejoin="round"/>
  <circle cx="0" cy="-66" r="12" fill="${C.goldLight}"/><circle cx="-84" cy="-46" r="10" fill="${C.goldLight}"/><circle cx="84" cy="-46" r="10" fill="${C.goldLight}"/>
</g>
<polyline points="110,250 170,200 220,225 280,150" fill="none" stroke="${C.gold}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
<polyline points="520,170 580,190 630,120 690,140" fill="none" stroke="${C.emeraldLight}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>`);

const sizes = {
  'app_icon.svg': [OUT, 1024],
  'adaptive_foreground.svg': [OUT, 1024],
  'adaptive_background.svg': [OUT, 1024],
  'adaptive_monochrome.svg': [OUT, 1024],
  'notification_icon.svg': [OUT, 96],
  'logo_mark.svg': [OUT, 1024],
  'logo_mark_on_dark.svg': [OUT, 1024],
  'splash_logo.svg': [OUT, 768],
  'logo_primary_light.svg': [OUT, 1400],
  'logo_primary_dark.svg': [OUT, 1400],
  'logo_stacked.svg': [OUT, 800],
  'onboarding_1.svg': [IMG, 1200],
  'onboarding_2.svg': [IMG, 1200],
  'onboarding_3.svg': [IMG, 1200],
};

for (const [name, content] of Object.entries(files)) {
  fs.writeFileSync(path.join(SRC, name), content);
  const [dir, width] = sizes[name];
  const r = new Resvg(content, {
    fitTo: { mode: 'width', value: width },
    font: { fontFiles: FONTS, loadSystemFonts: false, defaultFontFamily: 'Tajawal' },
  });
  fs.writeFileSync(path.join(dir, name.replace('.svg', '.png')), r.render().asPng());
  console.log('rendered', name);
}
