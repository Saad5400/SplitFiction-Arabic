#!/usr/bin/env node
// Build the Arabic Split.locres (and optionally the .pak) from translation/ar.json.
//
//   node tools/build.js                          -> build/Split.locres
//   node tools/build.js --pack --repak <repak.exe> [--base <old release .pak>]
//        -> build/Saad5400_SplitFiction_Arabic_999_P.pak
//
// The pak also carries the Arabic-capable font files. They are not stored in this repo;
// --base takes them from a previously released pak (downloaded automatically if omitted).
// repak: https://github.com/trumank/repak
const fs = require('fs'), path = require('path'), os = require('os'), cp = require('child_process');
const L = require('./locres.js');

const ROOT = path.join(__dirname, '..');
const args = process.argv.slice(2);
const opt = n => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : undefined; };
const PAK_NAME = 'Saad5400_SplitFiction_Arabic_999_P.pak';
const LOCRES_PATH = 'Split/Content/Localization/Split/en/Split.locres';

// Unreal renders text in widgets with a left-to-right base direction when the culture is English,
// which scrambles punctuation in Arabic lines. Wrapping every Arabic line in RLE..PDF makes it RTL.
const RLE = '‫', PDF = '‬';
function rtl(s) {
  return s.split('\n').map(line => {
    const m = line.match(/^((?:NO_)?CC: ?)?(.*)$/s); const pre = m[1] || ''; let body = m[2];
    const cr = body.endsWith('\r') ? '\r' : ''; if (cr) body = body.slice(0, -1);
    return /[؀-ۿ]/.test(body) ? pre + RLE + body + PDF + cr : line;
  }).join('\n');
}

const overrides = { 'UHazeGameSettings|LANG_en': 'العربية (تعريب Saad5400)' };
const tr = JSON.parse(fs.readFileSync(path.join(ROOT, 'translation', 'ar.json'), 'utf8'));
const entries = tr.map(e => ({ ns: e.ns, key: e.key, srcHash: e.hash, text: rtl(overrides[e.ns + '|' + e.key] ?? e.ar) }));

const outDir = path.join(ROOT, 'build');
fs.mkdirSync(outDir, { recursive: true });
const locresOut = path.join(outDir, 'Split.locres');
L.write(locresOut, entries);
const back = L.read(locresOut).entries;
if (back.length !== entries.length || back.some((b, i) => b.text !== entries[i].text)) throw new Error('round-trip check failed');
console.log(`Split.locres: ${entries.length} entries -> ${path.relative(ROOT, locresOut)}`);

if (args.includes('--pack')) {
  const repak = opt('--repak') || 'repak';
  const work = fs.mkdtempSync(path.join(os.tmpdir(), 'sfa-'));
  let base = opt('--base');
  if (!base) {
    base = path.join(work, 'base.pak');
    console.log('Downloading the latest released pak for the font files...');
    cp.execFileSync('curl', ['-fsSL', '-o', base, `https://github.com/Saad5400/SplitFiction-Arabic/releases/latest/download/${PAK_NAME}`], { stdio: 'inherit' });
  }
  const stage = path.join(work, PAK_NAME.replace(/\.pak$/, ''));
  cp.execFileSync(repak, ['unpack', '-o', stage, base], { stdio: 'inherit' });
  fs.copyFileSync(locresOut, path.join(stage, LOCRES_PATH));
  cp.execFileSync(repak, ['pack', '--version', 'V11', stage], { stdio: 'inherit' });
  const pakOut = path.join(outDir, PAK_NAME);
  fs.copyFileSync(stage + '.pak', pakOut);
  fs.rmSync(work, { recursive: true, force: true });
  console.log(`Pak: ${path.relative(ROOT, pakOut)}`);
}
