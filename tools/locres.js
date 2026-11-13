// UE .locres reader/writer. Exported for reuse; CLI: node locres.js dump <in.locres> <out.json>
const fs = require("fs"); const { ueTextKeyHash } = require("./cityhash.js");
const MAGIC = Buffer.from([0x0E,0x14,0x74,0x75,0x67,0x4A,0x03,0xFC,0x4A,0x15,0x90,0x9D,0xC3,0x37,0x7F,0x1B]);

function read(path) {
  const b = fs.readFileSync(path); let p = 0;
  const u8 = () => b[p++], u32 = () => { const v = b.readUInt32LE(p); p += 4; return v; }, i32 = () => { const v = b.readInt32LE(p); p += 4; return v; };
  const i64 = () => { const v = Number(b.readBigInt64LE(p)); p += 8; return v; };
  const fstr = () => { const n = i32(); if (!n) return ''; if (n > 0) { const s = b.toString('latin1', p, p + n - 1); p += n; return s; } const m = -n; const s = b.toString('utf16le', p, p + (m - 1) * 2); p += m * 2; return s; };
  let version = 0;
  if (b.subarray(0, 16).equals(MAGIC)) { p = 16; version = u8(); } else throw new Error('legacy locres unsupported');
  const strOff = i64();
  if (version >= 2) u32();
  const save = p; p = strOff;
  const strings = []; const ns = i32();
  for (let i = 0; i < ns; i++) { strings.push(fstr()); if (version >= 2) i32(); }
  p = save;
  const out = [];
  const nns = u32();
  for (let i = 0; i < nns; i++) {
    if (version >= 2) u32(); const namespace = fstr(); const nk = u32();
    for (let j = 0; j < nk; j++) { if (version >= 2) u32(); const key = fstr(); const srcHash = u32(); const idx = i32(); out.push({ ns: namespace, key, srcHash, text: strings[idx] }); }
  }
  return { version, entries: out };
}

// CityHash64 (UE uses for v2 hashes? No: UE uses FCrc::StrCrc32 for namespace/key hash). Implement StrCrc32.
const CRC = (() => { const t = new Uint32Array(256); for (let i = 0; i < 256; i++) { let c = i << 24; for (let k = 0; k < 8; k++) c = (c & 0x80000000) ? ((c << 1) ^ 0x04C11DB7) : (c << 1); t[i] = c >>> 0; } return t; })();
// FCrc::StrCrc32: processes each TCHAR as 4 bytes (little-endian), using CRCTablesSB8[0] (reflected 0xEDB88320 table)
const CRC_R = (() => { const t = new Uint32Array(256); for (let i = 0; i < 256; i++) { let c = i; for (let k = 0; k < 8; k++) c = (c & 1) ? ((c >>> 1) ^ 0xEDB88320) : (c >>> 1); t[i] = c >>> 0; } return t; })();
function strCrc32(s) {
  let crc = 0xFFFFFFFF;
  for (const ch of s) { let c = ch.codePointAt(0); // UE TCHAR on Windows is UTF-16; for BMP same
    for (let k = 0; k < 4; k++) { crc = (crc >>> 8) ^ CRC_R[(crc ^ c) & 0xFF]; c >>>= 8; } }
  return (~crc) >>> 0;
}

function fstrBuf(s) {
  if (s === '') { const b = Buffer.alloc(4); return b; }
  if (/^[\x00-\x7f]*$/.test(s)) { const b = Buffer.alloc(4 + s.length + 1); b.writeInt32LE(s.length + 1, 0); b.write(s, 4, 'latin1'); return b; }
  const u = Buffer.from(s + '\0', 'utf16le'); const b = Buffer.alloc(4); b.writeInt32LE(-(u.length / 2), 0); return Buffer.concat([b, u]);
}

function write(path, entries) { // entries: [{ns,key,srcHash,text}] ; writes version 3 format
  const nsMap = new Map(); const strIdx = new Map(); const strs = []; const refs = [];
  for (const e of entries) {
    if (!nsMap.has(e.ns)) nsMap.set(e.ns, []);
    let i = strIdx.get(e.text); if (i === undefined) { i = strs.length; strIdx.set(e.text, i); strs.push(e.text); refs.push(0); }
    refs[i]++; nsMap.get(e.ns).push([e.key, e.srcHash, i]);
  }
  const parts = []; const u32 = v => { const b = Buffer.alloc(4); b.writeUInt32LE(v >>> 0); return b; }; const i32 = v => { const b = Buffer.alloc(4); b.writeInt32LE(v); return b; };
  parts.push(MAGIC, Buffer.from([3]), Buffer.alloc(8), u32(entries.length), u32(nsMap.size));
  for (const [ns, keys] of nsMap) { parts.push(u32(ueTextKeyHash(ns)), fstrBuf(ns), u32(keys.length)); for (const [k, h, i] of keys) parts.push(u32(ueTextKeyHash(k)), fstrBuf(k), u32(h), i32(i)); }
  const body = Buffer.concat(parts); body.writeBigInt64LE(BigInt(body.length), 17);
  const sp = [i32(strs.length)]; strs.forEach((s, i) => sp.push(fstrBuf(s), i32(refs[i])));
  fs.writeFileSync(path, Buffer.concat([body, ...sp]));
}

module.exports = { read, write, strCrc32 };
if (require.main === module) {
  const [, , cmd, a, b] = process.argv;
  if (cmd === 'dump') { const r = read(a); fs.writeFileSync(b, JSON.stringify(r.entries, null, 0)); console.log(`v${r.version} ${r.entries.length} entries`); }
}
