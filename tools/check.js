#!/usr/bin/env node
// Check translation/ar.json against the game's own English text.
//   node tools/check.js <path to the game's en/Split.locres>
// Extract that file from your install with repak:
//   repak unpack -o english -i Split/Content/Localization/Split/en/Split.locres "<Game>/Split/Content/Paks/pakchunk0-Windows.pak"
// Reports: line-break / placeholder / CC-prefix mismatches, keys the game no longer has,
// changed English source lines (hash differs) and new untranslated lines.
const fs = require('fs'), path = require('path');
const L = require('./locres.js');
const enPath = process.argv[2];
if (!enPath) { console.error('usage: node tools/check.js <en/Split.locres>'); process.exit(2); }
const en = new Map(L.read(enPath).entries.map(e => [e.ns + '|' + e.key, e]));
const tr = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'translation', 'ar.json'), 'utf8'));
const cnt = (s, re) => (s.match(re) || []).length;
const ph = s => (s.match(/\{[^}]*\}/g) || []).sort().join(' ');
const cc = s => (s.match(/^(NO_)?CC: ?/gm) || []).map(t => t.trim()).join('|');
const problems = [], stale = [], gone = []; const seen = new Set();
for (const t of tr) {
  const id = t.ns + '|' + t.key; seen.add(id); const e = en.get(id);
  if (!e) { gone.push(id); continue; }
  if (e.srcHash !== t.hash) stale.push(`${id}\n    EN now: ${JSON.stringify(e.text)}`);
  if (cnt(e.text, /\n/g) !== cnt(t.ar, /\n/g)) problems.push(`${id}: line breaks ${cnt(e.text, /\n/g)} vs ${cnt(t.ar, /\n/g)}`);
  if (ph(e.text) !== ph(t.ar)) problems.push(`${id}: placeholders [${ph(e.text)}] vs [${ph(t.ar)}]`);
  if (cc(e.text) !== cc(t.ar)) problems.push(`${id}: CC:/NO_CC: prefixes differ`);
}
const missing = [...en.values()].filter(e => !seen.has(e.ns + '|' + e.key) && /[A-Za-z]{3,}/.test(e.text));
console.log(`format problems: ${problems.length}`); problems.slice(0, 50).forEach(p => console.log('  ' + p));
console.log(`English changed since translation: ${stale.length}`); stale.slice(0, 50).forEach(p => console.log('  ' + p));
console.log(`keys no longer in the game: ${gone.length}`);
console.log(`English lines with no translation: ${missing.length} (names, brands and dev strings are expected here)`);
missing.slice(0, 50).forEach(e => console.log(`  ${e.ns}|${e.key}: ${JSON.stringify(e.text.slice(0, 80))}`));
process.exit(problems.length ? 1 : 0);
